#!/bin/bash
echo "=================================="
echo "   Cloud Vault - Cleanup Script   "
echo "=================================="

echo "Deleting Kubernetes namespace..."
kubectl delete namespace cloud-vault --ignore-not-found

echo "Stopping Docker containers..."
docker rm -f dynamodb-local minio cloud-vault-test 2>/dev/null || true

echo "Stopping Minikube..."
minikube stop

echo "Done! To restart run: ./scripts/deploy.sh"
