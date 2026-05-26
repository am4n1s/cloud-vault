#!/bin/bash
echo "=== Cleaning up Cloud Vault ==="

kubectl delete namespace cloud-vault --ignore-not-found
docker rm -f dynamodb-local minio 2>/dev/null || true
minikube stop

echo "Done!"
