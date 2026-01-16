#!/bin/bash

# Script để apply các file YAML lên môi trường UAT
# Sử dụng: ./apply-uat.sh [clean|update]

NAMESPACE="bnctl-dolphinscheduler-uat-ns"
MODE=${1:-update}

echo "=========================================="
echo "DolphinScheduler UAT Deployment Script"
echo "Mode: $MODE"
echo "=========================================="

if [ "$MODE" == "clean" ]; then
    echo ""
    echo "⚠️  WARNING: Clean mode sẽ XÓA TẤT CẢ resources!"
    echo "⚠️  Dữ liệu trong PVCs sẽ bị mất!"
    echo ""
    read -p "Bạn có chắc chắn muốn tiếp tục? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo "Đã hủy."
        exit 1
    fi
    
    echo ""
    echo "Đang xóa các resources..."
    
    # Xóa Deployments và StatefulSets
    kubectl delete deployment cluster-api cluster-alert -n $NAMESPACE --ignore-not-found=true
    kubectl delete statefulset cluster-master cluster-worker cluster-zookeeper -n $NAMESPACE --ignore-not-found=true
    
    # Xóa Services (sẽ được tạo lại từ YAML nếu có)
    # kubectl delete service cluster-api cluster-alert cluster-master-headless cluster-worker-headless cluster-zookeeper cluster-zookeeper-headless -n $NAMESPACE --ignore-not-found=true
    
    # Xóa ConfigMaps
    kubectl delete configmap cluster-common cluster-configs -n $NAMESPACE --ignore-not-found=true
    
    # Xóa Secret (cẩn thận - sẽ tạo lại từ file)
    kubectl delete secret cluster-externaldb -n $NAMESPACE --ignore-not-found=true
    
    echo "Đã xóa các resources."
    echo ""
    sleep 3
fi

echo "Đang apply các file YAML..."
echo ""

# Thứ tự apply quan trọng:
# 1. ServiceAccount trước (các pods cần nó)
echo "[1/10] Applying dev-serviceaccount.yaml..."
kubectl apply -f dev-serviceaccount.yaml
if [ $? -ne 0 ]; then
    echo "❌ Lỗi khi apply serviceaccount!"
    exit 1
fi
sleep 1

# 2. Secret (các pods cần nó)
echo "[2/10] Applying dev-secret.yaml..."
kubectl apply -f dev-secret.yaml
if [ $? -ne 0 ]; then
    echo "❌ Lỗi khi apply secret!"
    exit 1
fi
sleep 1

# 3. ConfigMaps
echo "[3/10] Applying dev-cm.yaml..."
kubectl apply -f dev-cm.yaml
if [ $? -ne 0 ]; then
    echo "❌ Lỗi khi apply configmaps!"
    exit 1
fi
sleep 1

# 4. PVCs (cần trước khi tạo pods)
echo "[4/10] Applying dev-pvc.yaml..."
kubectl apply -f dev-pvc.yaml
if [ $? -ne 0 ]; then
    echo "❌ Lỗi khi apply PVCs!"
    exit 1
fi
sleep 2

# 5. Services (cần cho service discovery)
echo "[5/10] Applying dev-services.yaml..."
kubectl apply -f dev-services.yaml
if [ $? -ne 0 ]; then
    echo "❌ Lỗi khi apply services!"
    exit 1
fi
sleep 2

# 6. Zookeeper (cần cho registry)
echo "[6/10] Applying dev-cluster-zookeeper.yaml..."
kubectl apply -f dev-cluster-zookeeper.yaml
if [ $? -ne 0 ]; then
    echo "❌ Lỗi khi apply zookeeper!"
    exit 1
fi
sleep 5

# 7. Master
echo "[7/10] Applying dev-cluster-master.yaml..."
kubectl apply -f dev-cluster-master.yaml
if [ $? -ne 0 ]; then
    echo "❌ Lỗi khi apply master!"
    exit 1
fi
sleep 2

# 8. Worker
echo "[8/10] Applying dev-cluster-worker.yaml..."
kubectl apply -f dev-cluster-worker.yaml
if [ $? -ne 0 ]; then
    echo "❌ Lỗi khi apply worker!"
    exit 1
fi
sleep 2

# 9. API
echo "[9/10] Applying dev-cluster-api.yaml..."
kubectl apply -f dev-cluster-api.yaml
if [ $? -ne 0 ]; then
    echo "❌ Lỗi khi apply api!"
    exit 1
fi
sleep 2

# 10. Alert
echo "[10/10] Applying dev-cluster-alert.yaml..."
kubectl apply -f dev-cluster-alert.yaml
if [ $? -ne 0 ]; then
    echo "❌ Lỗi khi apply alert!"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ Đã apply tất cả các file thành công!"
echo "=========================================="
echo ""
echo "Đang kiểm tra trạng thái pods..."
kubectl get pods -n $NAMESPACE -w

