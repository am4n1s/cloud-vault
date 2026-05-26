# Cloud Vault

Secure Cloud-Native Infrastructure with MinIO, RBAC and Kubernetes.

## Requirements

- Docker
- Minikube
- kubectl
- Terraform
- Java 17+
- Maven

## Quick Start

```bash
git clone https://github.com/am4n1s/cloud-vault.git
cd cloud-vault
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

## Architecture
```
Kubernetes (Minikube)
├── cloud-vault (Spring Boot, 2 replicas)
│   ├── ROLE_VIEWER  → GET /api/files
│   ├── ROLE_EDITOR  → GET + POST /api/files/upload
│   └── ROLE_ADMIN   → full access + /api/files/admin/secret
├── MinIO (S3-compatible storage)
└── DynamoDB Local
```
## API Endpoints

| Method | Endpoint | Role |
|--------|----------|------|
| GET | /api/files | VIEWER, EDITOR, ADMIN |
| POST | /api/files/upload | EDITOR, ADMIN |
| DELETE | /api/files/{key} | ADMIN |
| GET | /api/files/admin/secret | ADMIN |

## Test Credentials

| User | Password | Role |
|------|----------|------|
| viewer | viewer123 | ROLE_VIEWER |
| editor | editor123 | ROLE_EDITOR |
| admin | admin123 | ROLE_ADMIN |

## Cleanup

```bash
./scripts/cleanup.sh
```
