# Cloud Vault

Secure Cloud-Native Infrastructure with MinIO S3, RBAC and Kubernetes.

## Tech Stack

- **App**: Java 17 + Spring Boot + Spring Security
- **Storage**: MinIO (S3-compatible)
- **Database**: DynamoDB Local + H2
- **Container**: Docker
- **Orchestration**: Kubernetes (Minikube)
- **IaC**: Terraform
- **Monitoring**: Prometheus + Grafana

## Requirements

Install these before running:

| Tool | Install |
|------|---------|
| Docker | https://docs.docker.com/engine/install |
| Minikube | https://minikube.sigs.k8s.io/docs/start |
| kubectl | https://kubernetes.io/docs/tasks/tools |
| Terraform | https://developer.hashicorp.com/terraform/install |
| Java 17 | `sudo apt install openjdk-17-jdk` |
| Maven | `sudo apt install maven` |

## Quick Start

```bash
git clone https://github.com/am4n1s/cloud-vault.git
cd cloud-vault
chmod +x scripts/deploy.sh scripts/cleanup.sh
./scripts/deploy.sh
```

## Architecture
```
Kubernetes (Minikube)
├── cloud-vault (Spring Boot, 2 replicas)
│   ├── ROLE_VIEWER  → GET /api/files
│   ├── ROLE_EDITOR  → GET + POST /api/files/upload
│   └── ROLE_ADMIN   → full access
├── MinIO (S3 storage)
├── DynamoDB Local
├── Prometheus (metrics)
└── Grafana (dashboards)
```
## API Endpoints

| Method | Endpoint | Role Required |
|--------|----------|---------------|
| GET | /api/files | VIEWER, EDITOR, ADMIN |
| POST | /api/files/upload | EDITOR, ADMIN |
| DELETE | /api/files/{key} | ADMIN |
| GET | /api/files/admin/secret | ADMIN |
| GET | /actuator/prometheus | public |

## Security

- Basic Auth with BCrypt password encoding
- Role-Based Access Control via @PreAuthorize
- Non-root Docker user
- K8s Secrets for credentials (no hardcoding)
- K8s NetworkPolicy (only app can access MinIO)
- ServiceAccount with least privilege

## Test Credentials

| User | Password | Role |
|------|----------|------|
| viewer | viewer123 | ROLE_VIEWER |
| editor | editor123 | ROLE_EDITOR |
| admin | admin123 | ROLE_ADMIN |

## Monitoring

- Prometheus: `http://MINIKUBE_IP:30090`
- Grafana: `http://MINIKUBE_IP:30030` (admin/admin123)
- Dashboard: **Cloud Vault Metrics** (auto-provisioned)

Metrics include:
- Authorization failures (403 errors)
- Total HTTP requests by endpoint
- JVM memory usage

## Cleanup

```bash
./scripts/cleanup.sh
```
