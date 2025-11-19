# Coffee Queue DevOps Assessment

A complete DevOps pipeline implementation for a Spring Boot coffee ordering application with PostgreSQL backend, featuring containerization, Kubernetes orchestration, and CI/CD automation.

## Documentation

- [Scripts Guide](docs/SCRIPTS.md) - Complete guide to all management scripts
- [Commands Reference](docs/COMMANDS.md) - Detailed command reference

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         GitHub Repository                           │
│                                                                     │
│  ┌────────────┐    ┌────────────┐    ┌────────────────────────┐  │
│  │   main     │    │  develop   │    │  feature branches      │  │
│  │ (prod)     │    │  (dev)     │    │  (CI only)             │  │
│  └─────┬──────┘    └─────┬──────┘    └───────────┬────────────┘  │
└────────┼─────────────────┼────────────────────────┼───────────────┘
         │                 │                        │
         │                 │                        │
    ┌────▼─────────────────▼────────────────────────▼─────┐
    │         GitHub Actions CI/CD Pipeline               │
    │  ┌────────────┐  ┌──────────────┐  ┌─────────────┐ │
    │  │   Build    │─▶│  Test        │─▶│ Push Image  │ │
    │  │   (Maven)  │  │  (JUnit)     │  │  (GHCR)     │ │
    │  └────────────┘  └──────────────┘  └──────┬──────┘ │
    └───────────────────────────────────────────┼─────────┘
                                                 │
                   ┌─────────────────────────────┼─────────────────┐
                   │                             │                 │
         ┌─────────▼──────────┐       ┌──────────▼─────────┐      │
         │  Development Env   │       │  Production Env    │      │
         │  Namespace: -dev   │       │  Namespace: -prod  │      │
         │  Replicas: 1       │       │  Replicas: 2       │      │
         │  HPA: Disabled     │       │  HPA: Enabled      │      │
         └─────────┬──────────┘       └──────────┬─────────┘      │
                   │                             │                 │
         ┌─────────▼──────────┐       ┌──────────▼─────────┐      │
         │  Coffee Queue App  │       │  Coffee Queue App  │      │
         │  + PostgreSQL      │       │  + PostgreSQL      │      │
         └────────────────────┘       └────────────────────┘      │
```

### Environment Comparison

| Aspect | Development | Production |
|--------|-------------|------------|
| Namespace | `coffee-queue-dev` | `coffee-queue-prod` |
| Replicas | 1 | 2 |
| HPA | Disabled | Enabled (2-10 replicas) |
| Deployment Trigger | Push to `develop` | Push to `main` or manual |
| Rollback | Manual | Automatic on failure |
| Approval Required | No | Optional (manual trigger) |

## Tools & Versions Used

| Tool | Version | Purpose |
|------|---------|---------|
| Java | 21 | Runtime for Spring Boot application |
| Spring Boot | 3.5.7 | Application framework |
| Maven | 3.x | Build tool |
| PostgreSQL | 15 | Database |
| Docker | 24.x+ | Containerization |
| Kubernetes | 1.28+ | Container orchestration |
| Kind/Minikube | Latest | Local Kubernetes clusters |
| GitHub Actions | - | CI/CD pipeline |
| kubectl | 1.28+ | Kubernetes CLI |

## Quick Start

### Prerequisites

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd StratalyzeDevops
   ```

2. **Setup environment (Ubuntu):**
   ```bash
   chmod +x scripts/setup.sh
   scripts/setup.sh
   # Log out and log back in for Docker group permissions
   ```

### Local Development with Docker Compose

1. **Start the application stack:**
   ```bash
   docker compose up -d
   ```

2. **Verify the application:**
   ```bash
   # Check health
   curl http://localhost:8080/health
   
   # Create an order
   curl -X POST "http://localhost:8080/order?name=John"
   
   # Check order status
   curl "http://localhost:8080/status?name=John"
   
   # View coffee statistics
   curl http://localhost:8080/numberOfCoffees
   ```

3. **Stop the stack:**
   ```bash
   docker compose down
   ```

### Kubernetes Deployment

#### Quick Start (Automated)

**Using the automated script:**

1. **Setup Kubernetes (if not already running):**
   ```bash
   ./setup-k8s.sh
   ```
   Choose from:
   - Docker Desktop Kubernetes (easiest)
   - Minikube
   - Kind

2. **Deploy and test:**
   ```bash
   # Full deployment with testing
   ./test-k8s-deployment.sh full
   
   # Or step by step:
   ./test-k8s-deployment.sh deploy   # Build and deploy
   ./test-k8s-deployment.sh test     # Test endpoints
   ./test-k8s-deployment.sh status   # View status
   ./test-k8s-deployment.sh logs     # View logs
   ./test-k8s-deployment.sh cleanup  # Remove all resources
   ```

#### Manual Deployment

**Option 1: Docker Desktop Kubernetes (Recommended)**

1. **Enable Kubernetes:**
   - Open Docker Desktop → Settings → Kubernetes
   - Check "Enable Kubernetes"
   - Click "Apply & Restart"

2. **Build images:**
   ```bash
   docker compose build
   ```

3. **Deploy to Kubernetes:**
   ```bash
   # Create namespace
   kubectl create namespace coffee-queue
   
   # Deploy PostgreSQL
   kubectl apply -f k8s/postgres/ -n coffee-queue
   
   # Wait for database to be ready
   kubectl wait --for=condition=ready pod -l app=postgres -n coffee-queue --timeout=120s
   
   # Deploy application
   kubectl apply -f k8s/app/ -n coffee-queue
   
   # Wait for app to be ready
   kubectl wait --for=condition=ready pod -l app=coffee-queue-app -n coffee-queue --timeout=120s
   ```

4. **Access the application:**
   ```bash
   # Port forward to access the service
   kubectl port-forward service/coffee-queue-service 8080:8080 -n coffee-queue
   
   # In another terminal, test the application
   curl http://localhost:8080/health
   curl -X POST "http://localhost:8080/order?name=K8sUser"
   curl http://localhost:8080/numberOfCoffees
   ```

**Option 2: Minikube**

1. **Start Minikube:**
   ```bash
   minikube start --driver=docker
   ```

2. **Build and load images:**
   ```bash
   docker compose build
   minikube image load stratalyzedevops-app:latest
   minikube image load coffee-queue-postgres:15-alpine
   ```

3. **Deploy (same as Option 1 step 3)**

4. **Access via Minikube service:**
   ```bash
   minikube service coffee-queue-service -n coffee-queue
   ```

**Option 3: Kind (Kubernetes in Docker)**

1. **Create cluster:**
   ```bash
   kind create cluster --name coffee-queue-cluster
   ```

2. **Build and load images:**
   ```bash
   docker compose build
   kind load docker-image stratalyzedevops-app:latest --name coffee-queue-cluster
   kind load docker-image coffee-queue-postgres:15-alpine --name coffee-queue-cluster
   ```

3. **Deploy (same as Option 1 step 3)**

#### Monitor the Deployment

```bash
# Check pod status
   kubectl get pods -n coffee-queue
   
   # Check HPA status
   kubectl get hpa -n coffee-queue
   
   # View logs
   kubectl logs -f deployment/coffee-queue-app -n coffee-queue
   ```

#### Option 2: Using Minikube

1. **Start Minikube:**
   ```bash
   minikube start
   ```

2. **Enable metrics server for HPA:**
   ```bash
   minikube addons enable metrics-server
   ```

3. **Build and use image in Minikube:**
   ```bash
   # Set Docker environment to Minikube
   eval $(minikube docker-env)
   
   # Build the image
   docker build -t coffee-queue:latest ./coffeequeue
   ```

4. **Deploy and access (same as Kind steps 3-5)**

## Git Setup & GitHub Configuration

### Initialize Repository

```bash
git init
git add .
git commit -m "Initial commit: Complete DevOps setup with Docker, K8s, and CI/CD"
git remote add origin <your-repo-url>
git push -u origin main
```

### Create Branches

```bash

git checkout -b develop
git push -u origin develop


git checkout develop
git checkout -b feature/example-feature
git push -u origin feature/example-feature
```

### GitHub Container Registry Setup

1. **Create Personal Access Token (PAT):**
   - Navigate to GitHub Settings > Developer Settings > Personal Access Tokens > Tokens (classic)
   - Click "Generate new token (classic)"
   - Select scopes: `write:packages`, `read:packages`, `repo`
   - Generate and copy the token

2. **Add Repository Secret:**
   - Go to your repository Settings > Secrets and Variables > Actions
   - Click "New repository secret"
   - Name: `GHCR_TOKEN`
   - Value: Your PAT from step 1
   - Click "Add secret"

### GitHub Secrets Setup

For secure deployment, configure these GitHub repository secrets:

1. **Navigate to Repository Settings:**
   - Go to your GitHub repository
   - Click **Settings** > **Secrets and variables** > **Actions**

2. **Add Required Secrets:**

| Secret Name | Purpose | Example Value |
|-------------|---------|---------------|
| `POSTGRES_DB` | Database name | `coffeequeue` |
| `POSTGRES_USER` | Database username | `postgres` |
| `POSTGRES_PASSWORD` | Database password | `your-secure-password` |

3. **Click "New repository secret" for each:**
   - **Name**: Use exact secret names from table above
   - **Value**: Your secure values (don't use examples in production)

**Security Benefits:**
- ✅ No secrets committed to repository  
- ✅ Encrypted at rest in GitHub
- ✅ Only accessible during workflow execution
- ✅ Can be rotated independently

**Local Development:**
```bash

cp .env.example .env


POSTGRES_DB=coffeequeue
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your-local-password

# Run with environment file
docker-compose --env-file .env up
```

### Branch Protection Rules

**Main Branch Protection:**
- Go to Settings > Branches > Add rule
- Branch name pattern: `main`
- Enable: Require pull request reviews before merging (1 approval)
- Enable: Require status checks to pass before merging
  - Select: `test` and `build-and-push` checks
- Enable: Require conversation resolution before merging
- Disable: Allow force pushes

**Develop Branch Protection:**
- Branch name pattern: `develop`
- Enable: Require status checks to pass before merging
  - Select: `test` check
- Disable: Allow force pushes

### Workflow Triggers

The three workflows are triggered as follows:

| Workflow | Trigger | Label Required | Environment |
|----------|---------|----------------|-------------|
| CI - Build and Test | Push/Pull Request to any branch | No | All |
| Deploy to Development | Push to `develop` or Manual | No | development |
| Deploy to Production | PR to `main` with label or Manual | `deploy-app` | production |

**How to Deploy:**

1. **Create a Pull Request** to `develop` (for dev) or `main` (for prod)
2. **Add the deployment label:** `deploy-app`
3. **Workflow runs automatically** based on target branch
4. **Review and merge** after successful deployment

**Manual Production Deployment:**
- Go to Actions → Deploy to Production → Run workflow
- Type "deploy" to confirm

## CI/CD Pipeline

### Branching Strategy

The project follows a structured branching strategy:

- **main**: Production-ready code. Deployments to production.
- **develop**: Integration branch for features. Deployments to development.
- **feature/**: Feature branches created from develop.

### Workflow Overview

The project includes three GitHub Actions workflows:

1. **CI - Build and Test** (`.github/workflows/ci-cd.yml`)
   - Runs on: Push/PR to main, develop, or feature branches
   - Actions: Build, test, and push Docker images
   - No label required

2. **Deploy to Development** (`.github/workflows/deploy-dev.yml`)
   - Runs on: PR to `develop` branch with `deploy-app` label
   - Environment: Development namespace with 1 replica
   - Requires: `deploy-app` label on PR
   - Auto-triggers when label is added

3. **Deploy to Production** (`.github/workflows/deploy-prod.yml`)
   - Runs on: PR to `main` branch with `deploy-app` label or manual trigger
   - Environment: Production namespace with 2 replicas + HPA
   - Requires: `deploy-app` label on PR or manual confirmation
   - Features: Automated rollback on failure

### Pipeline Stages

**CI Pipeline (All Branches):**
1. **Test Stage:**
   - Sets up Java 21 environment
   - Caches Maven dependencies
   - Runs unit tests
   - Builds the application
   - Uploads artifacts

2. **Build & Push Stage (main/develop only):**
   - Sets up Docker Buildx
   - Builds Docker images with environment-specific tags
   - Pushes to GitHub Container Registry
   - Labels: `environment`, `version`, `commit SHA`

**Development Deployment:**
1. Creates/updates development namespace
2. Deploys PostgreSQL
3. Deploys application (1 replica)
4. Runs smoke tests
5. Displays access instructions

**Production Deployment:**
1. Validates deployment confirmation (if manual)
2. Creates/updates production namespace
3. Deploys PostgreSQL with persistent storage
4. Deploys application (2 replicas)
5. Configures HPA for auto-scaling
6. Runs comprehensive smoke tests
7. Monitors HPA metrics
8. Automatic rollback on failure
9. Creates deployment summary

### Triggering the Pipeline

- **Automatic:** Push to `main` or `develop` branches, or create PRs to `main`
- **Manual:** Use GitHub Actions UI to trigger workflow manually

## API Endpoints

| Method | Endpoint | Description | Example |
|--------|----------|-------------|---------|
| GET | `/health` | Health check | `curl http://localhost:8080/health` |
| POST | `/order?name={name}` | Create coffee order | `curl -X POST "http://localhost:8080/order?name=John"` |
| GET | `/status?name={name}` | Get orders by name | `curl "http://localhost:8080/status?name=John"` |
| GET | `/numberOfCoffees` | Get order statistics | `curl http://localhost:8080/numberOfCoffees` |

## Monitoring & Health Checks

### Application Health Checks

- **Liveness Probe:** `/health` endpoint checked every 10s after 60s initial delay
- **Readiness Probe:** `/health` endpoint checked every 5s after 30s initial delay

### Database Health Checks

- **Liveness Probe:** `pg_isready` command every 10s after 30s initial delay
- **Readiness Probe:** `pg_isready` command every 5s after 5s initial delay

### Horizontal Pod Autoscaling

- **CPU Target:** 70% utilization
- **Memory Target:** 80% utilization
- **Min Replicas:** 2
- **Max Replicas:** 10
- **Scale-up:** 100% increase every 60s
- **Scale-down:** 50% decrease every 60s (5min stabilization)

### Monitoring Commands

```bash

kubectl get pods -n coffee-queue -w


kubectl get hpa -n coffee-queue
kubectl describe hpa coffee-queue-hpa -n coffee-queue


kubectl top pods -n coffee-queue
kubectl top nodes


kubectl logs -f deployment/coffee-queue-app -n coffee-queue
kubectl logs -f deployment/postgres -n coffee-queue
```

## Security Considerations

### Implemented

- **Container Security:**
  - Non-root user in application container
  - Minimal base images (Alpine/Slim)
  - Health checks for early problem detection

- **Kubernetes Security:**
  - Secrets for database credentials
  - Namespace isolation
  - Resource limits and requests
  - Proper service account configuration

- **Network Security:**
  - ClusterIP services for internal communication
  - No direct external access to database

### For Production (Not Implemented)

- **Image Security:**
  - Container image vulnerability scanning
  - Image signing and verification
  - Private container registry

- **Kubernetes Security:**
  - Pod Security Standards/Policies
  - Network Policies for traffic segmentation
  - RBAC (Role-Based Access Control)
  - Secrets encryption at rest
  - Service mesh for mTLS

- **Runtime Security:**
  - Admission controllers
  - Runtime security monitoring
  - Compliance scanning

## Design Decisions & Trade-offs

### Key Design Decisions

1. **Kind over Minikube:** Kind provides better CI/CD integration and is more lightweight
2. **GitHub Container Registry:** Integrated with GitHub Actions, no additional service needed
3. **PostgreSQL 15:** Stable, well-supported version with good performance
4. **Multi-stage Docker build:** Smaller final image, separation of build and runtime dependencies
5. **Init containers:** Ensure database readiness before application startup

### Trade-offs Made

| Decision | Pros | Cons | Rationale |
|----------|------|------|-----------|
| Single namespace | Simplicity | Less isolation | Appropriate for demo environment |
| ClusterIP services | Security | Requires port-forwarding | Good for internal services |
| imagePullPolicy: Never | Fast local dev | Not production-ready | Suitable for Kind-based CI |
| Embedded database init | Automatic setup | Less flexibility | Good for demo/development |

### Areas for Improvement

#### Short-term (Next Sprint)
- [ ] Add Ingress controller for proper external access
- [ ] Implement proper secret management (HashiCorp Vault, etc.)
- [ ] Add database migration versioning (Flyway/Liquibase)
- [ ] Implement graceful shutdown handling

#### Medium-term (Next Quarter)
- [ ] **Observability Stack:**
  - Prometheus for metrics collection
  - Grafana for dashboards
  - Jaeger for distributed tracing
  - ELK/EFK stack for log aggregation

- [ ] **Advanced CI/CD:**
  - Automated rollback on deployment failure
  - Blue-green deployment strategy
  - Canary deployments with traffic splitting
  - Integration testing in pipeline

- [ ] **Production Readiness:**
  - Multi-environment support (dev/staging/prod)
  - Infrastructure as Code (Terraform/Pulumi)
  - Backup and disaster recovery
  - Performance testing integration

#### Long-term (Next Year)
- [ ] **Advanced Kubernetes Features:**
  - Service mesh integration (Istio/Linkerd)
  - GitOps with ArgoCD/Flux
  - Policy as Code (OPA/Gatekeeper)
  - Cost optimization and resource management

- [ ] **Enterprise Features:**
  - Multi-region deployment
  - Advanced security scanning
  - Compliance automation
  - Chaos engineering integration

## Troubleshooting

### Common Issues

1. **Docker permission denied:**
   ```bash
   sudo usermod -aG docker $USER
   # Log out and log back in
   ```

2. **Kind cluster not found:**
   ```bash
   kind create cluster --name coffee-queue-cluster
   kubectl cluster-info --context kind-coffee-queue-cluster
   ```

3. **Pods stuck in pending:**
   ```bash
   kubectl describe pods -n coffee-queue
   # Check for resource constraints or storage issues
   ```

4. **Database connection issues:**
   ```bash
   kubectl logs deployment/postgres -n coffee-queue
   kubectl port-forward service/postgres-service 5432:5432 -n coffee-queue
   ```

5. **HPA not scaling:**
   ```bash
   kubectl get hpa -n coffee-queue
   kubectl describe hpa coffee-queue-hpa -n coffee-queue
   # Ensure metrics-server is running
   ```

### Useful Commands

```bash

docker compose down -v
kind delete cluster --name coffee-queue-cluster


kubectl get all -n coffee-queue

kubectl exec -it deployment/coffee-queue-app -n coffee-queue -- /bin/sh
kubectl exec -it deployment/postgres -n coffee-queue -- psql -U postgres -d coffeequeue


kubectl run -i --tty --rm debug --image=busybox --restart=Never -- sh
```

## Screenshots & Logs

To generate screenshots and logs for submission:

```bash

docker compose up -d

kubectl apply -f k8s/
kubectl get pods -n coffee-queue

curl -X POST "http://localhost:8080/order?name=Demo" | jq
curl "http://localhost:8080/status?name=Demo" | jq


kubectl get hpa -n coffee-queue

```
