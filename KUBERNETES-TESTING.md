# Kubernetes Testing Guide

This guide covers multiple ways to test the Kubernetes deployment locally.

## Prerequisites

- Docker Desktop with Kubernetes enabled, OR
- Minikube, OR
- Kind (Kubernetes in Docker)

---

## Option 1: Docker Desktop Kubernetes (Easiest)

### Enable Kubernetes in Docker Desktop

1. Open Docker Desktop
2. Go to **Settings** → **Kubernetes**
3. Check **Enable Kubernetes**
4. Click **Apply & Restart**
5. Wait for Kubernetes to start (green indicator)

### Verify Kubernetes is Running

```bash
kubectl cluster-info
kubectl get nodes
```

### Deploy the Application

```bash
# Run the test deployment script
./test-k8s-deployment.sh
```

---

## Option 2: Minikube

### Install Minikube (macOS)

```bash
# Using Homebrew
brew install minikube

# Or download directly
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-arm64
sudo install minikube-darwin-arm64 /usr/local/bin/minikube
```

### Start Minikube

```bash
# Start with Docker driver
minikube start --driver=docker

# Verify
minikube status
kubectl get nodes
```

### Deploy the Application

```bash
# Build and load images into Minikube
minikube image load stratalyzedevops-app:latest
minikube image load coffee-queue-postgres:15-alpine

# Run the test deployment script
./test-k8s-deployment.sh

# Access the service
minikube service coffee-queue-service -n coffee-queue
```

### Stop Minikube

```bash
minikube stop
minikube delete  # To completely remove
```

---

## Option 3: Kind (Kubernetes in Docker)

### Install Kind (macOS)

```bash
# Using Homebrew
brew install kind

# Or download binary
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-darwin-arm64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

### Create a Kind Cluster

```bash
kind create cluster --name coffee-queue-cluster

# Verify
kubectl cluster-info --context kind-coffee-queue-cluster
kubectl get nodes
```

### Load Images into Kind

```bash
# Build images first (if not already built)
docker compose build

# Load images into Kind cluster
kind load docker-image stratalyzedevops-app:latest --name coffee-queue-cluster
kind load docker-image coffee-queue-postgres:15-alpine --name coffee-queue-cluster
```

### Deploy the Application

```bash
./test-k8s-deployment.sh
```

### Delete Kind Cluster

```bash
kind delete cluster --name coffee-queue-cluster
```

---

## Testing Steps (All Options)

### 1. Deploy All Resources

```bash
# Create namespace
kubectl create namespace coffee-queue

# Deploy PostgreSQL
kubectl apply -f k8s/postgres/ -n coffee-queue

# Wait for PostgreSQL to be ready
kubectl wait --for=condition=ready pod -l app=postgres -n coffee-queue --timeout=120s

# Deploy Application
kubectl apply -f k8s/app/ -n coffee-queue

# Wait for app to be ready
kubectl wait --for=condition=ready pod -l app=coffee-queue -n coffee-queue --timeout=120s
```

### 2. Verify Deployments

```bash
# Check all resources
kubectl get all -n coffee-queue

# Check pods status
kubectl get pods -n coffee-queue

# Check logs
kubectl logs -l app=coffee-queue -n coffee-queue --tail=50
kubectl logs -l app=postgres -n coffee-queue --tail=50

# Describe pods for troubleshooting
kubectl describe pod -l app=coffee-queue -n coffee-queue
```

### 3. Test the Application

```bash
# Port forward to access the service locally
kubectl port-forward service/coffee-queue-service 8080:8080 -n coffee-queue &

# Test health endpoint
curl http://localhost:8080/health

# Create an order
curl -X POST "http://localhost:8080/order?name=KubernetesTest"

# Check order counts
curl http://localhost:8080/numberOfCoffees

# Stop port forwarding
pkill -f "port-forward"
```

### 4. Test Horizontal Pod Autoscaler (HPA)

```bash
# Check HPA status
kubectl get hpa -n coffee-queue

# Watch HPA in action
kubectl get hpa -n coffee-queue --watch

# Generate load (in a separate terminal)
for i in {1..100}; do
  curl -X POST "http://localhost:8080/order?name=LoadTest-$i" &
done

# Watch pods scale up
kubectl get pods -n coffee-queue --watch
```

### 5. Test Rolling Updates

```bash
# Update the image (simulate a new version)
kubectl set image deployment/coffee-queue-app coffee-queue-app=stratalyzedevops-app:latest -n coffee-queue

# Watch the rollout
kubectl rollout status deployment/coffee-queue-app -n coffee-queue

# Check rollout history
kubectl rollout history deployment/coffee-queue-app -n coffee-queue

# Rollback if needed
kubectl rollout undo deployment/coffee-queue-app -n coffee-queue
```

### 6. Test Database Persistence

```bash
# Create some orders
curl -X POST "http://localhost:8080/order?name=PersistenceTest1"
curl -X POST "http://localhost:8080/order?name=PersistenceTest2"

# Delete the app pod (database should persist)
kubectl delete pod -l app=coffee-queue -n coffee-queue

# Wait for new pod to start
kubectl wait --for=condition=ready pod -l app=coffee-queue -n coffee-queue --timeout=120s

# Port forward again
kubectl port-forward service/coffee-queue-service 8080:8080 -n coffee-queue &

# Verify orders still exist
curl http://localhost:8080/numberOfCoffees

# Stop port forwarding
pkill -f "port-forward"
```

### 7. Check Resource Usage

```bash
# View resource usage
kubectl top nodes
kubectl top pods -n coffee-queue

# Check resource limits
kubectl describe deployment coffee-queue-app -n coffee-queue | grep -A 5 "Limits"
```

---

## Troubleshooting

### Pods Not Starting

```bash
# Check pod events
kubectl describe pod <pod-name> -n coffee-queue

# Check logs
kubectl logs <pod-name> -n coffee-queue

# Check previous logs (if pod crashed)
kubectl logs <pod-name> -n coffee-queue --previous
```

### ImagePullBackOff Error

```bash
# For Minikube: Load images
minikube image load stratalyzedevops-app:latest
minikube image load coffee-queue-postgres:15-alpine

# For Kind: Load images
kind load docker-image stratalyzedevops-app:latest --name coffee-queue-cluster
kind load docker-image coffee-queue-postgres:15-alpine --name coffee-queue-cluster

# For Docker Desktop: Build images locally
docker compose build
```

### Database Connection Issues

```bash
# Check PostgreSQL pod
kubectl get pod -l app=postgres -n coffee-queue
kubectl logs -l app=postgres -n coffee-queue

# Check secrets
kubectl get secret postgres-secret -n coffee-queue -o yaml
kubectl get secret app-secret -n coffee-queue -o yaml

# Test database connection from app pod
kubectl exec -it <app-pod-name> -n coffee-queue -- sh
# Inside pod:
# apk add postgresql-client
# psql -h postgres-service -U postgres -d coffeequeue
```

### Service Not Accessible

```bash
# Check service endpoints
kubectl get endpoints -n coffee-queue

# Check service details
kubectl describe service coffee-queue-service -n coffee-queue

# Use port-forward instead of service
kubectl port-forward service/coffee-queue-service 8080:8080 -n coffee-queue
```

---

## Cleanup

```bash
# Delete all resources in namespace
kubectl delete namespace coffee-queue

# Or delete resources individually
kubectl delete -f k8s/app/ -n coffee-queue
kubectl delete -f k8s/postgres/ -n coffee-queue
kubectl delete namespace coffee-queue
```

---

## Quick Reference Commands

```bash
# View all resources
kubectl get all -n coffee-queue

# Watch pods
kubectl get pods -n coffee-queue --watch

# Stream logs
kubectl logs -f -l app=coffee-queue -n coffee-queue

# Execute command in pod
kubectl exec -it <pod-name> -n coffee-queue -- sh

# Port forward
kubectl port-forward service/coffee-queue-service 8080:8080 -n coffee-queue

# Scale manually
kubectl scale deployment coffee-queue-app --replicas=3 -n coffee-queue

# Restart deployment
kubectl rollout restart deployment/coffee-queue-app -n coffee-queue
```

---

## CI/CD Integration

For GitHub Actions (already configured in `.github/workflows/deploy-dev.yml` and `deploy-prod.yml`):

1. Set up GitHub Secrets:
   - `KUBE_CONFIG_DEV` - Base64 encoded kubeconfig for dev cluster
   - `KUBE_CONFIG_PROD` - Base64 encoded kubeconfig for prod cluster
   - `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`

2. Push changes to trigger deployment:
   ```bash
   git add .
   git commit -m "Deploy to Kubernetes"
   git push origin develop  # For dev deployment
   git push origin main      # For prod deployment (needs deploy-app label)
   ```

---

## Performance Testing

```bash
# Install Apache Bench (macOS)
brew install httpd

# Run load test
ab -n 1000 -c 10 http://localhost:8080/health

# Or use hey
brew install hey
hey -n 1000 -c 10 http://localhost:8080/health
```
