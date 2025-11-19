# Quick Command Reference

## Environment Setup

### First-Time Setup (Ubuntu)
```bash
chmod +x setup.sh
./setup.sh
```

### GitHub Repository Setup
```bash
# Initialize repository
git init
git add .
git commit -m "Initial commit: Complete DevOps setup"
git remote add origin <your-repo-url>
git push -u origin main

# Create develop branch
git checkout -b develop
git push -u origin develop
```

## Docker Commands

### Build Image
```bash
cd coffeequeue
docker build -t coffee-queue:latest .
```

### Run with Docker Compose
```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

### Manual Docker Run
```bash
# Run PostgreSQL
docker run -d --name postgres \
  -e POSTGRES_DB=coffeequeue \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=admin123 \
  -p 5432:5432 \
  postgres:15-alpine

# Run application
docker run -d --name coffee-queue \
  -e DATABASE_URL=jdbc:postgresql://postgres:5432/coffeequeue \
  -e DATABASE_USERNAME=admin \
  -e DATABASE_PASSWORD=admin123 \
  -p 8080:8080 \
  --link postgres \
  coffee-queue:latest
```

## Kubernetes Commands

### Cluster Management

#### Kind
```bash
# Create cluster
kind create cluster --name coffee-queue-cluster

# Delete cluster
kind delete cluster --name coffee-queue-cluster

# List clusters
kind get clusters

# Load image into cluster
kind load docker-image coffee-queue:latest --name coffee-queue-cluster
```

#### Minikube
```bash
# Start cluster
minikube start

# Stop cluster
minikube stop

# Delete cluster
minikube delete

# Enable metrics server (required for HPA)
minikube addons enable metrics-server

# Use Minikube's Docker daemon
eval $(minikube docker-env)
```

### Deployment

#### Deploy Everything
```bash
# Quick start (automated)
./quick-start.sh

# Manual deployment
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/postgres/
kubectl apply -f k8s/app/
```

#### Deploy by Environment
```bash
# Development
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/postgres/
kubectl apply -f k8s/app/deployment.yaml
kubectl apply -f k8s/app/service.yaml
kubectl apply -f k8s/app/secret.yaml

# Production (includes HPA)
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/postgres/
kubectl apply -f k8s/app/
```

### Monitoring

#### Pod Management
```bash
# List all pods
kubectl get pods -n coffee-queue

# Watch pod status
kubectl get pods -n coffee-queue -w

# Describe pod
kubectl describe pod <pod-name> -n coffee-queue

# Get pod logs
kubectl logs <pod-name> -n coffee-queue

# Follow logs
kubectl logs -f <pod-name> -n coffee-queue

# Logs from all app pods
kubectl logs -f deployment/coffee-queue-app -n coffee-queue

# Previous pod logs (if crashed)
kubectl logs <pod-name> -n coffee-queue --previous
```

#### Deployment Status
```bash
# List deployments
kubectl get deployments -n coffee-queue

# Deployment details
kubectl describe deployment coffee-queue-app -n coffee-queue

# Rollout status
kubectl rollout status deployment/coffee-queue-app -n coffee-queue

# Rollout history
kubectl rollout history deployment/coffee-queue-app -n coffee-queue

# Rollback to previous version
kubectl rollout undo deployment/coffee-queue-app -n coffee-queue

# Rollback to specific revision
kubectl rollout undo deployment/coffee-queue-app --to-revision=2 -n coffee-queue
```

#### Services
```bash
# List services
kubectl get services -n coffee-queue

# Service details
kubectl describe service coffee-queue-service -n coffee-queue

# Port forward to local
kubectl port-forward service/coffee-queue-service 8080:8080 -n coffee-queue
```

#### HPA (Horizontal Pod Autoscaler)
```bash
# Get HPA status
kubectl get hpa -n coffee-queue

# Detailed HPA info
kubectl describe hpa coffee-queue-hpa -n coffee-queue

# Watch HPA in real-time
kubectl get hpa -n coffee-queue -w
```

#### Resource Usage
```bash
# Pod resource usage
kubectl top pods -n coffee-queue

# Node resource usage
kubectl top nodes

# Detailed resource info
kubectl describe nodes
```

#### ConfigMaps and Secrets
```bash
# List ConfigMaps
kubectl get configmaps -n coffee-queue

# View ConfigMap content
kubectl describe configmap postgres-init-script -n coffee-queue

# List Secrets
kubectl get secrets -n coffee-queue

# View Secret (base64 encoded)
kubectl get secret postgres-secret -n coffee-queue -o yaml
```

### Debugging

#### Execute Commands in Pod
```bash
# Get shell in pod
kubectl exec -it <pod-name> -n coffee-queue -- /bin/bash

# Run single command
kubectl exec <pod-name> -n coffee-queue -- curl http://localhost:8080/health
```

#### Database Access
```bash
# Connect to PostgreSQL
kubectl exec -it <postgres-pod-name> -n coffee-queue -- psql -U admin -d coffeequeue

# Check database from application pod
kubectl exec -it <app-pod-name> -n coffee-queue -- curl http://postgres:5432
```

#### Events
```bash
# All namespace events
kubectl get events -n coffee-queue

# Sorted by time
kubectl get events -n coffee-queue --sort-by='.lastTimestamp'

# Watch events
kubectl get events -n coffee-queue -w
```

### Cleanup

#### Remove Deployments
```bash
# Delete all resources in namespace
kubectl delete namespace coffee-queue

# Delete specific resources
kubectl delete -f k8s/app/
kubectl delete -f k8s/postgres/
kubectl delete -f k8s/namespace.yaml
```

#### Complete Cleanup
```bash
# Automated cleanup
./cleanup.sh

# Manual cleanup
kubectl delete namespace coffee-queue
kind delete cluster --name coffee-queue-cluster
docker rmi coffee-queue:latest
```

## Application API Commands

### Health Check
```bash
curl http://localhost:8080/health
```

### Create Coffee Order
```bash
# Single order
curl -X POST "http://localhost:8080/order?name=John"

# Multiple orders
curl -X POST "http://localhost:8080/order?name=Alice"
curl -X POST "http://localhost:8080/order?name=Bob"
curl -X POST "http://localhost:8080/order?name=Charlie"
```

### Check Order Status
```bash
curl "http://localhost:8080/status?name=John"
```

### Get Order Statistics
```bash
curl http://localhost:8080/numberOfCoffees
```

### Load Testing
```bash
# Generate load for HPA testing
for i in {1..100}; do
  curl -X POST "http://localhost:8080/order?name=User$i" &
done

# Check scaling
kubectl get hpa -n coffee-queue -w
```

## Maven Commands

### Build Application
```bash
cd coffeequeue

# Clean and package
mvn clean package

# Run tests only
mvn test

# Skip tests
mvn package -DskipTests

# Run locally
mvn spring-boot:run
```

## Git Workflow Commands

### Feature Development
```bash
# Create feature branch
git checkout develop
git pull origin develop
git checkout -b feature/new-feature

# Make changes and commit
git add .
git commit -m "Add new feature"

# Push feature branch
git push -u origin feature/new-feature

# Create PR to develop (via GitHub UI)
```

### Release to Production
```bash
# Merge develop to main (after PR approval)
git checkout main
git pull origin main
git merge develop
git push origin main

# Tag release
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

## GitHub Actions

### Workflow Management
```bash
# Trigger manual workflow (via GitHub CLI)
gh workflow run deploy-prod.yml

# View workflow runs
gh run list

# View specific run logs
gh run view <run-id>

# Cancel workflow run
gh run cancel <run-id>
```

### Check Workflow Status
```bash
# Via GitHub UI
Go to: Actions tab in repository

# Via API
curl -H "Authorization: token <GITHUB_TOKEN>" \
  https://api.github.com/repos/<owner>/<repo>/actions/runs
```

## Monitoring Script

### Start Monitoring Dashboard
```bash
# Automated monitoring
./monitor.sh

# Manual watch commands
watch -n 2 kubectl get pods -n coffee-queue
watch -n 2 kubectl get hpa -n coffee-queue
watch -n 2 kubectl top pods -n coffee-queue
```

## Testing Script

### Run Deployment Tests
```bash
# Automated testing
./test-deployment.sh coffee-queue

# With specific namespace
./test-deployment.sh coffee-queue-prod
./test-deployment.sh coffee-queue-dev
```

## Troubleshooting Commands

### Pod Not Starting
```bash
# Check pod status
kubectl describe pod <pod-name> -n coffee-queue

# Check events
kubectl get events -n coffee-queue --field-selector involvedObject.name=<pod-name>

# Check logs
kubectl logs <pod-name> -n coffee-queue
kubectl logs <pod-name> -n coffee-queue --previous
```

### Image Pull Issues
```bash
# Check image pull secrets
kubectl get secrets -n coffee-queue

# Check node's ability to pull
kubectl describe node <node-name>

# Manually pull image (for debugging)
docker pull ghcr.io/<username>/coffee-queue:latest
```

### Database Connection Issues
```bash
# Test PostgreSQL connectivity
kubectl exec -it <app-pod-name> -n coffee-queue -- \
  curl -v telnet://postgres:5432

# Check PostgreSQL logs
kubectl logs -f <postgres-pod-name> -n coffee-queue

# Verify secrets
kubectl get secret postgres-secret -n coffee-queue -o jsonpath='{.data.password}' | base64 -d
```

### HPA Not Scaling
```bash
# Check metrics server
kubectl get apiservice v1beta1.metrics.k8s.io -o yaml

# Install metrics server (if missing)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# For Minikube
minikube addons enable metrics-server

# Verify metrics
kubectl top pods -n coffee-queue
```

### Service Not Accessible
```bash
# Check service endpoints
kubectl get endpoints -n coffee-queue

# Check service details
kubectl describe service coffee-queue-service -n coffee-queue

# Test internal connectivity
kubectl run test-pod --rm -i --tty --image=curlimages/curl -- sh
curl http://coffee-queue-service.coffee-queue.svc.cluster.local:8080/health
```

## Performance Testing

### Generate Load
```bash
# Using Apache Bench
ab -n 1000 -c 10 http://localhost:8080/health

# Using curl in loop
for i in {1..1000}; do
  curl -X POST "http://localhost:8080/order?name=LoadTest$i" &
  if [ $((i % 50)) -eq 0 ]; then wait; fi
done

# Monitor during load
kubectl get hpa -n coffee-queue -w
kubectl top pods -n coffee-queue
```

## Backup and Restore

### Database Backup
```bash
# Backup database
kubectl exec <postgres-pod-name> -n coffee-queue -- \
  pg_dump -U admin coffeequeue > backup.sql

# Restore database
cat backup.sql | kubectl exec -i <postgres-pod-name> -n coffee-queue -- \
  psql -U admin coffeequeue
```

### Configuration Backup
```bash
# Export all resources
kubectl get all -n coffee-queue -o yaml > backup-all.yaml

# Export specific resources
kubectl get deployment coffee-queue-app -n coffee-queue -o yaml > backup-app.yaml
```

## Useful Aliases

Add these to your `~/.bashrc` or `~/.zshrc`:

```bash
# Kubernetes aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgd='kubectl get deployments'
alias kgs='kubectl get services'
alias kd='kubectl describe'
alias kl='kubectl logs -f'
alias kex='kubectl exec -it'
alias ka='kubectl apply -f'
alias kdel='kubectl delete'

# Namespace specific
alias kcq='kubectl -n coffee-queue'
alias kgpcq='kubectl get pods -n coffee-queue'
alias klcq='kubectl logs -f -n coffee-queue'

# Docker aliases
alias d='docker'
alias dc='docker-compose'
alias dcu='docker-compose up -d'
alias dcd='docker-compose down'
alias dcl='docker-compose logs -f'

# Coffee Queue specific
alias cq-start='./quick-start.sh'
alias cq-test='./test-deployment.sh coffee-queue'
alias cq-monitor='./monitor.sh'
alias cq-clean='./cleanup.sh'
```

## Environment Variables

### Required for GitHub Actions
```bash
GHCR_TOKEN=<your-github-personal-access-token>
```

### Required for Application
```bash
DATABASE_URL=jdbc:postgresql://localhost:5432/coffeequeue
DATABASE_USERNAME=admin
DATABASE_PASSWORD=admin123
```

### Optional Configuration
```bash
SPRING_PROFILES_ACTIVE=prod
SERVER_PORT=8080
LOGGING_LEVEL_ROOT=INFO
```

## Common Error Solutions

### "ImagePullBackOff"
```bash
# Solution 1: Check image name
kubectl describe pod <pod-name> -n coffee-queue

# Solution 2: Load image into Kind
kind load docker-image coffee-queue:latest --name coffee-queue-cluster

# Solution 3: Check registry authentication
kubectl get secret -n coffee-queue
```

### "CrashLoopBackOff"
```bash
# Check logs
kubectl logs <pod-name> -n coffee-queue
kubectl logs <pod-name> -n coffee-queue --previous

# Check environment variables
kubectl exec <pod-name> -n coffee-queue -- env
```

### "Pending" Pod Status
```bash
# Check events
kubectl describe pod <pod-name> -n coffee-queue

# Check node resources
kubectl top nodes
kubectl describe nodes

# Check PVC status (for database)
kubectl get pvc -n coffee-queue
```
