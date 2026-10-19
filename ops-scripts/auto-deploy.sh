#!/bin/bash
# ==========================================
# 自动化端口连通性测试脚本
# 作者：李建鹏
# ==========================================

TARGET_IP="192.168.126.105"
PORTS=(8080 3306 6379 5432 9090)

echo "开始测试目标 IP: ${TARGET_IP} 的端口连通性..."

for PORT in "${PORTS[@]}"; do
    timeout 2 bash -c "echo >/dev/tcp/${TARGET_IP}/${PORT}" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "[✅ 通] ${TARGET_IP}:${PORT}"
    else
        echo "[❌ 不通] ${TARGET_IP}:${PORT}"
    fi
done
echo "测试完成！"
