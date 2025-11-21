# Coffee Queue DevOps

A Spring Boot coffee ordering service with PostgreSQL. Containerized with Docker. Deployable to Kubernetes.

## Contents
1. Architecture
2. Local Development (Docker Compose)
3. Kubernetes Deployment
4. CI/CD
5. Secrets
6. Scripts
7. API
8. Troubleshooting
9. Improvements

## 1. Architecture
- Spring Boot (Java 21)
- PostgreSQL 15
- Multi-stage Docker build
- Kubernetes manifests in k8s/ (single namespace: coffee-queue)
- GitHub Actions workflows

## 2. Local Development (Docker Compose)
```bash
git clone <repo-url>
cd StratalyzeDevops

docker compose up -d
curl http://localhost:8080/health
curl -X POST "http://localhost:8080/order?name=LocalUser"
curl http://localhost:8080/numberOfCoffees

docker compose down
```
Rebuild:
```bash
docker compose build --no-cache
```

## 3. Kubernetes Deployment
Cluster required (Docker Desktop / Kind / Minikube).
```bash
kubectl create namespace coffee-queue
kubectl apply -f k8s/postgres/
kubectl apply -f k8s/app/
kubectl get pods -n coffee-queue
kubectl port-forward service/coffee-queue-service 8080:8080 -n coffee-queue
```
HPA (k8s/app/hpa.yaml) active only if metrics-server is installed.

## 4. CI/CD
| Workflow | File | Trigger |
|----------|------|---------|
| Build & Test | .github/workflows/ci-cd.yml | Push / PR (develop, feature) |
| Security Scan | .github/workflows/security-scan.yml | Schedule / manual |
| Deploy Dev | .github/workflows/deploy-dev.yml | PR label deploy-app / manual (namespace: coffee-queue) |
| Deploy Prod | .github/workflows/deploy-prod.yml | PR label deploy-app / manual (namespace: coffee-queue) |

CodeQL removed. SARIF uploads removed.

## 5. Secrets
Never commit real secrets.
GitHub Secrets needed:
| Name | Purpose |
|------|---------|
| POSTGRES_DB | DB name |
| POSTGRES_USER | DB user |
| POSTGRES_PASSWORD | DB password |

Local .env example:
```env
POSTGRES_DB=coffeequeue
POSTGRES_USER=postgres
POSTGRES_PASSWORD=dev-password
```
Use:
```bash
docker compose --env-file .env up -d
```
Kubernetes secret:
```bash
kubectl create secret generic postgres-secret \
  --from-literal=POSTGRES_DB=$POSTGRES_DB \
  --from-literal=POSTGRES_USER=$POSTGRES_USER \
  --from-literal=POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
  -n coffee-queue --dry-run=client -o yaml | kubectl apply -f -
```

## 6. Scripts
| Script | Purpose |
|--------|---------|
| scripts/setup.sh | Environment setup (Ubuntu) |
| scripts/dev.sh | Docker Compose operations |
| scripts/k8s.sh | Kubernetes operations |

## 7. API
| Method | Path | Description |
|--------|------|-------------|
| GET | /health | Health check |
| POST | /order?name=NAME | Create order |
| GET | /status?name=NAME | List orders for customer |
| GET | /numberOfCoffees | Aggregated order counts |

## 8. Troubleshooting
| Issue | Action |
|-------|--------|
| Permission denied (Docker) | Add user to docker group, re-login |
| ImagePullBackOff | Ensure image built & accessible / correct tag |
| App not ready | kubectl logs -f deployment/coffee-queue-app -n coffee-queue |
| DB errors | kubectl logs -l app=postgres -n coffee-queue |
| HPA no scale | metrics-server required |
| Missing secret | kubectl get secrets -n coffee-queue |

## 9. Improvements
- Ingress + TLS
- External secret manager
- DB migrations (Flyway/Liquibase)
- Observability stack
- Namespace per environment
- GitOps (ArgoCD / Flux)


