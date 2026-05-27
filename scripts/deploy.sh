#!/bin/bash
set -e

echo "=================================="
echo "   Cloud Vault - Deploy Script    "
echo "=================================="

# Проверка зависимостей
echo "[0/8] Checking dependencies..."
for cmd in docker minikube kubectl terraform java mvn; do
  if ! command -v $cmd &> /dev/null; then
    echo "ERROR: $cmd is not installed"
    exit 1
  fi
done
echo "All dependencies OK"

# 1. Сборка jar
echo ""
echo "[1/8] Building jar..."
cd "$(dirname "$0")/../app"
./mvnw clean package -DskipTests -q
cd ..

# 2. Запуск Minikube
echo ""
echo "[2/8] Starting Minikube..."
minikube start

# 3. Сборка образа внутри minikube
echo ""
echo "[3/8] Building Docker image inside Minikube..."
eval $(minikube docker-env)
cd app
docker build -t cloud-vault:latest .
cd ..
eval $(minikube docker-env -u)
echo "Image built successfully inside Minikube"

# 4. Запуск MinIO и DynamoDB локально для Terraform
echo ""
echo "[4/8] Starting MinIO and DynamoDB Local..."
docker rm -f dynamodb-local minio 2>/dev/null || true

docker run -d \
  --name minio \
  -p 9000:9000 \
  -p 9001:9001 \
  -e MINIO_ROOT_USER=minioadmin \
  -e MINIO_ROOT_PASSWORD=minioadmin \
  minio/minio server /data --console-address ":9001"

docker run -d \
  --name dynamodb-local \
  -p 8000:8000 \
  amazon/dynamodb-local \
  -jar DynamoDBLocal.jar -inMemory -sharedDb

echo "Waiting for MinIO to be ready..."
sleep 8

# 5. Terraform
echo ""
echo "[5/8] Running Terraform..."
cd terraform
terraform init -input=false -upgrade
terraform apply -auto-approve
cd ..
echo "Terraform done"

# 6. Kubernetes манифесты
echo ""
echo "[6/8] Applying Kubernetes manifests..."
kubectl apply -f k8s/app/namespace.yaml
kubectl apply -f k8s/app/secret.yaml
kubectl apply -f k8s/app/configmap.yaml
kubectl apply -f k8s/app/serviceaccount.yaml
kubectl apply -f k8s/minio/minio.yaml
kubectl apply -f k8s/dynamodb/dynamodb.yaml
kubectl apply -f k8s/app/deployment.yaml
kubectl apply -f k8s/app/service.yaml
kubectl apply -f k8s/network/networkpolicy.yaml
echo "Kubernetes manifests applied"

# 7. Мониторинг
echo ""
echo "[7/8] Deploying monitoring stack..."
kubectl apply -f k8s/monitoring/prometheus-config.yaml
kubectl apply -f k8s/monitoring/grafana-provisioning.yaml
kubectl apply -f k8s/monitoring/prometheus.yaml
kubectl apply -f k8s/monitoring/grafana.yaml
echo "Monitoring deployed"

# 8. Ждём поды и создаём bucket
echo ""
echo "[8/8] Waiting for all pods to be ready..."
echo "Waiting for MinIO..."
kubectl wait --for=condition=ready pod \
  -l app=minio \
  -n cloud-vault \
  --timeout=900s

echo "Waiting for DynamoDB..."
kubectl wait --for=condition=ready pod \
  -l app=dynamodb-local \
  -n cloud-vault \
  --timeout=900s

echo "Waiting for cloud-vault app..."
kubectl wait --for=condition=ready pod \
  -l app=cloud-vault \
  -n cloud-vault \
  --timeout=900s

echo "Waiting for Prometheus..."
kubectl wait --for=condition=ready pod \
  -l app=prometheus \
  -n cloud-vault \
  --timeout=900s

echo "Waiting for Grafana..."
kubectl wait --for=condition=ready pod \
  -l app=grafana \
  -n cloud-vault \
  --timeout=900s

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
echo "=================================="
echo "      Deploy Complete!            "
echo "=================================="
echo ""
echo "URLs:"
echo "  App:        http://$MINIKUBE_IP:30080/login"
echo "  MinIO:      http://$MINIKUBE_IP:30901"
echo "  Prometheus: http://$MINIKUBE_IP:30090"
echo "  Grafana:    http://$MINIKUBE_IP:30030"
echo ""
echo "Credentials:"
echo "  viewer  / viewer123  (read only)"
echo "  editor  / editor123  (read + upload)"
echo "  admin   / admin123   (full access)"
echo ""
echo "Grafana login: admin / admin123"
