#!/bin/bash

echo "Applying DolphinScheduler YAML files..."

echo "1. Applying namespace..."
kubectl apply -f uat-namespace.yaml

echo "2. Applying serviceaccount..."
kubectl apply -f uat-serviceaccount.yaml

echo "3. Applying secret..."
kubectl apply -f uat-secret.yaml

echo "4. Applying configmaps..."
kubectl apply -f uat-configmaps.yaml

echo "5. Applying PVCs..."
kubectl apply -f uat-pvc.yaml

echo "6. Applying services..."
kubectl apply -f uat-services.yaml

echo "7. Applying zookeeper..."
kubectl apply -f uat-cluster-zookeeper.yaml

echo "8. Applying master..."
kubectl apply -f uat-cluster-master.yaml

echo "9. Applying worker..."
kubectl apply -f uat-cluster-worker.yaml

echo "10. Applying api..."
kubectl apply -f uat-cluster-api.yaml

echo "11. Applying alert..."
kubectl apply -f uat-cluster-alert.yaml

echo "Done! Checking pod status..."
kubectl get pods -n bnctl-dolphinscheduler-prod-ns

