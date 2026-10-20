# 李建鹏的运维实战笔记 (Linux & K8s)

## 👋 关于我
- 4年+ Linux 系统运维经验，专注云原生与 AIOps 方向。
- 熟悉 Kubernetes、ArgoCD、Prometheus、Docker。

## 🛠 技术栈
- **容器与编排**：Kubernetes (v1.28)、Containerd、ArgoCD、Docker
- **监控与日志**：Prometheus、Grafana、node_exporter、cAdvisor
- **系统与网络**：CentOS 7/Ubuntu、Bash、Nginx、TCP/IP
- **数据库与中间件**：PostgreSQL、MySQL、Oracle、Tomcat、ActiveMQ

## 📂 计划更新的目录
- [ ] **k8s-cluster-deploy**：从零搭建 K8s 集群及避坑指南（CRI/CNI问题）
- [ ] **monitoring-stack**：解决 cAdvisor 401 认证的监控搭建记录
- [ ] **ops-scripts**：日常自动化运维脚本（如：批量端口扫描）
- [ ] **etcd-backup**：etcd 备份与灾备恢复标准 SOP
💡 实战踩坑记录：
宿主机无 etcdctl 怎么备份？ 因为是 kubeadm 最小化安装的 K8s，宿主机并没有 etcdctl 环境。我采用了 kubectl exec 直接进入 etcd 容器执行 snapshot save。

容器无 tar 命令怎么拷贝？ 官方 etcd 镜像极其精简，没有 tar 命令，导致 kubectl cp 失败。我巧妙地利用了 K8s 默认挂载的 /var/lib/etcd 目录，让容器直接把快照生成到这个映射目录里，宿主机就能直接拿到了。

弊端
## ⚠️ 方案局限性与生产环境优化建议

虽然上述脚本成功绕过了最小化环境的各种限制，但在真正的企业级生产环境中，该方案仍存在以下局限性，并附带了未来的优化方向：

### 1. 强依赖 K8s 运行状态（最致命）
- **局限**：当前方案依赖 `kubectl exec` 和 K8s API 进入容器执行备份。如果 Master 节点宕机、`kube-apiserver` 崩溃或 `kubelet` 异常，`kubectl` 命令将失效，导致无法执行备份。
- **优化**：在生产环境中，应将 `etcdctl` 二进制文件直接下发到宿主机 `/usr/local/bin/` 目录，备份脚本直接调用本地二进制，完全脱离 K8s 环境依赖。

### 2. 存在单点故障风险
- **局限**：备份文件仅存储在 Master 节点的本地 `/backup/etcd/` 目录下。如果节点发生硬件故障（如磁盘损坏）或系统崩溃，备份文件将与主节点一同丢失，无法实现灾备。
- **优化**：在备份脚本末尾增加 `scp` 或 `rsync` 命令，将快照文件推送到独立的备份服务器或对象存储（如阿里云 OSS / 兼容 S3 的存储），实现异地容灾。

### 3. 容器内的临时文件残留
- **局限**：脚本通过挂载目录将快照移至宿主机，但容器内部 `/var/lib/etcd/` 目录下生成的原文件依然存在。长期不重启 etcd Pod 可能会占用容器临时空间。
- **优化**：在脚本拷贝文件后，追加一条 `kubectl exec` 命令，删除容器内的源文件：`kubectl -n kube-system exec $ETCD_POD -- rm -f /var/lib/etcd/${SNAPSHOT_NAME}`。

### 4. 备份期间对 etcd 的性能损耗
- **局限**：`etcdctl snapshot save` 会短暂锁定 etcd 的读操作，并消耗磁盘 I/O。
- **优化**：定时任务必须严格安排在业务低峰期（如凌晨 2:00），避免在业务高峰期执行备份，防止引发业务响应延迟。
