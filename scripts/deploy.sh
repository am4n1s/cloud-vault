set -e

echo "=================================="
echo "   Cloud Vault - Deploy Script    "
echo "=================================="

# Check dependencies
echo "[0/7] Checking dependencies..."
for cmd in docker minikube kubectl terraform java mvn; do
  if ! command -v $cmd &> /dev/null; then
    echo "ERROR: $cmd is not installed"
    exit 1
  fi
done
echo "All dependencies OK"

# 1. Build Docker image
echo ""
echo "[1/7] Building Docker image..."
cd "$(dirname "$0")/../app"
./mvnw clean package -DskipTests -q
docker build -t cloud-vault:latest .
cd ..

# 2. Start Minikube
echo ""
echo "[2/7] Starting Minikube..."
minikube start
minikube image load cloud-vault:latest
echo "Minikube started"

# 3. DynamoDB Local for Terraform
echo ""
echo "[3/7] Starting DynamoDB Local..."
docker rm -f dynamodb-local 2>/dev/null || true
docker run -d \
  --name dynamodb-local \
  -p 8000:8000 \
  amazon/dynamodb-local \
  -jar DynamoDBLocal.jar -inMemory -sharedDb
sleep 3
echo "DynamoDB Local started"

# 4. Terraform
echo ""
echo "[4/7] Running Terraform..."
cd terraform
terraform init -input=false -upgrade
terraform apply -auto-approve
cd ..
echo "Terraform done"

# 5. Kubernetes manifests
echo ""
echo "[5/7] Applying Kubernetes manifests..."
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

# 6. Monitoring
echo ""
echo "[6/7] Deploying monitoring stack..."
kubectl apply -f k8s/monitoring/prometheus-config.yaml
kubectl apply -f k8s/monitoring/grafana-provisioning.yaml
kubectl apply -f k8s/monitoring/prometheus.yaml
kubectl apply -f k8s/monitoring/grafana.yaml
echo "Monitoring deployed"

# 7. Wait for pods
echo ""
echo "[7/7] Waiting for all pods to be ready..."
kubectl wait --for=condition=ready pod \
  -l app=minio \
  -n cloud-vault \
  --timeout=120s

kubectl wait --for=condition=ready pod \
  -l app=cloud-vault \
  -n cloud-vault \
  --timeout=120s

kubectl wait --for=condition=ready pod \
  -l app=prometheus \
  -n cloud-vault \
  --timeout=120s

kubectl wait --for=condition=ready pod \
  -l app=grafana \
  -n cloud-vault \
  --timeout=120s

# Create MinIO bucket
echo ""
echo "Creating MinIO bucket..."
kubectl run minio-client --rm -it \
  --image=minio/mc \
  --restart=Never \
  -n cloud-vault \
  --command -- /bin/sh -c \
  "mc alias set local http://minio-service:9000 minioadmin minioadmin && mc mb --ignore-existing local/cloud-vault-bucket"

# Result
MINIKUBE_IP=$(minikube ip)
echo ""
echo "=================================="
echo "      Deploy Complete!            "
echo "=================================="
echo ""
echo "URLs:"
echo "  App:       http://$MINIKUBE_IP:30080"
echo "  MinIO:     http://$MINIKUBE_IP:30901"
echo "  Prometheus:http://$MINIKUBE_IP:30090"
echo "  Grafana:   http://$MINIKUBE_IP:30030"
echo ""
echo "Credentials:"
echo "  viewer  / viewer123  (read only)"
echo "  editor  / editor123  (read + upload)"
echo "  admin   / admin123   (full access)"
echo ""
echo "Grafana login: admin / admin123"
echo ""
echo "Test RBAC:"
echo "  curl -u viewer:viewer123 http://$MINIKUBE_IP:30080/api/files"
echo "  curl -u admin:admin123 http://$MINIKUBE_IP:30080/api/files/admin/secret"
echo "  curl -u viewer:viewer123 http://$MINIKUBE_IP:30080/api/files/admin/secret"
chmod +x ~/cloud-vault/scripts/deploy.sh
