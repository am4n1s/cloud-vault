#!/bin/bash
set -e

echo "=== Cloud Vault Deploy Script ==="

# 1. Сборка Docker образа
echo "[1/6] Building Docker image..."
cd "$(dirname "$0")/../app"
docker build -t cloud-vault:latest .
cd ..

# 2. Запуск Minikube
echo "[2/6] Starting Minikube..."
minikube start
minikube image load cloud-vault:latest

# 3. Запуск DynamoDB Local (для Terraform)
echo "[3/6] Starting DynamoDB Local..."
docker rm -f dynamodb-local 2>/dev/null || true
docker run -d \
  --name dynamodb-local \
  -p 8000:8000 \
  amazon/dynamodb-local \
  -jar DynamoDBLocal.jar -inMemory -sharedDb
sleep 3

# 4. Terraform
echo "[4/6] Running Terraform..."
cd terraform
terraform init -input=false
terraform apply -auto-approve
cd ..

# 5. Kubernetes манифесты
echo "[5/6] Applying Kubernetes manifests..."
kubectl apply -f k8s/app/namespace.yaml
kubectl apply -f k8s/app/secret.yaml
kubectl apply -f k8s/app/configmap.yaml
kubectl apply -f k8s/app/serviceaccount.yaml
kubectl apply -f k8s/minio/minio.yaml
kubectl apply -f k8s/dynamodb/dynamodb.yaml
kubectl apply -f k8s/app/deployment.yaml
kubectl apply -f k8s/app/service.yaml
kubectl apply -f k8s/network/networkpolicy.yaml

# 6. Ждём поды и создаём bucket
echo "[6/6] Waiting for pods..."
kubectl wait --for=condition=ready pod \
  -l app=minio \
  -n cloud-vault \
  --timeout=120s

kubectl wait --for=condition=ready pod \
  -l app=cloud-vault \
  -n cloud-vault \
  --timeout=120s

echo "Creating MinIO bucket..."
kubectl run minio-client --rm -it \
  --image=minio/mc \
  --restart=Never \
  -n cloud-vault \
  --command -- /bin/sh -c \
  "mc alias set local http://minio-service:9000 minioadmin minioadmin && mc mb --ignore-existing local/cloud-vault-bucket"

# Итог
MINIKUBE_IP=$(minikube ip)
echo ""
echo "=== Deploy Complete ==="
echo "App URL:       http://$MINIKUBE_IP:30080"
echo "MinIO Console: http://$MINIKUBE_IP:30901"
echo ""
echo "Test credentials:"
echo "  viewer:viewer123"
echo "  editor:editor123"
echo "  admin:admin123"
echo ""
echo "Test commands:"
echo "  curl -u viewer:viewer123 http://$MINIKUBE_IP:30080/api/files"
echo "  curl -u admin:admin123 http://$MINIKUBE_IP:30080/api/files/admin/secret"

# Мониторинг
echo "[7/7] Deploying Prometheus and Grafana..."
kubectl apply -f k8s/monitoring/prometheus-config.yaml
kubectl apply -f k8s/monitoring/grafana-provisioning.yaml
kubectl apply -f k8s/monitoring/prometheus.yaml
kubectl apply -f k8s/monitoring/grafana.yaml

MINIKUBE_IP=$(minikube ip)
echo ""
echo "Prometheus: http://$MINIKUBE_IP:30090"
echo "Grafana:    http://$MINIKUBE_IP:30030  (admin/admin123)"
