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
