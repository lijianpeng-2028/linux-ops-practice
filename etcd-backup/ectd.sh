#!/bin/bash
# =========================================================
# etcd 自动备份脚本 (终极完美版)
# 特点：利用宿主机挂载目录直接落地，避开容器无 tar 命令的坑
# =========================================================

BACKUP_DIR="/backup/etcd"
DATE=$(date +%Y%m%d_%H%M%S)
SNAPSHOT_NAME="etcd-snapshot-${DATE}.db"
SNAPSHOT_FILE="${BACKUP_DIR}/${SNAPSHOT_NAME}"

# 1. 获取 etcd Pod
ETCD_POD=$(kubectl -n kube-system get pods -l component=etcd -o jsonpath='{.items[0].metadata.name}')
if [ -z "$ETCD_POD" ]; then
    echo "❌ 未找到 etcd Pod！"
    exit 1
fi

echo "============================="
echo "开始备份 etcd 数据 (目标: $ETCD_POD)..."

mkdir -p ${BACKUP_DIR}

# 2. 直接在 etcd 容器内存放快照（存到容器的 /var/lib/etcd/，这个目录通常映射到宿主机）
echo "正在生成快照..."
kubectl -n kube-system exec $ETCD_POD -- sh -c "ETCDCTL_API=3 etcdctl snapshot save /var/lib/etcd/${SNAPSHOT_NAME} \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key"

if [ $? -ne 0 ]; then
    echo "❌ 容器内快照生成失败！"
    exit 1
fi

# 3. 直接从宿主机层面把文件移动或复制到备份目录
# 因为 /var/lib/etcd 通常是宿主机的映射目录，生成的快照其实已经存在于宿主机上了
if [ -f "/var/lib/etcd/${SNAPSHOT_NAME}" ]; then
    mv "/var/lib/etcd/${SNAPSHOT_NAME}" "${SNAPSHOT_FILE}"
    echo "✅ 备份成功: ${SNAPSHOT_FILE}"
else
    echo "❌ 找不到生成的快照文件，请检查 etcd 的挂载路径。"
    exit 1
fi

# 4. 清理 7 天前的旧备份
find ${BACKUP_DIR} -name "etcd-snapshot-*.db" -mtime +7 -exec rm -f {} \;
echo "✅ 清理 7 天前的旧备份完成。"
