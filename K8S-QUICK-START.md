# Kubernetes Testing - Quick Reference

## Prerequisites

- Docker Desktop installed and running
- kubectl installed (comes with Docker Desktop)

## Three Ways to Test

### 1. 🚀 Automated (Easiest)

```bash
# One command to setup, deploy, and test
./setup-k8s.sh           # Setup Kubernetes (one-time)
./test-k8s-deployment.sh # Deploy and test
```

### 2. 🔧 Manual (Step-by-step)

```bash
# Enable Kubernetes in Docker Desktop first
# Then run:
kubectl create namespace coffee-queue
kubectl apply -f k8s/postgres/ -n coffee-queue
kubectl apply -f k8s/app/ -n coffee-queue
kubectl port-forward service/coffee-queue-service 8080:8080 -n coffee-queue
```

### 3. 📝 Using Scripts

```bash
./test-k8s-deployment.sh deploy   # Deploy only
./test-k8s-deployment.sh test     # Test endpoints
./test-k8s-deployment.sh status   # View status
./test-k8s-deployment.sh logs     # View logs
./test-k8s-deployment.sh cleanup  # Remove everything
```

## Enable Docker Desktop Kubernetes

1. Open Docker Desktop
2. Click Settings (gear icon)
3. Go to "Kubernetes" tab
4. Check "Enable Kubernetes"
5. Click "Apply & Restart"
6. Wait for green indicator

## Quick Test Commands

```bash
# Check cluster is running
kubectl cluster-info

# View all resources
kubectl get all -n coffee-queue

# Watch pods
kubectl get pods -n coffee-queue --watch

# View logs
kubectl logs -f -l app=coffee-queue-app -n coffee-queue

# Test health endpoint
curl http://localhost:8080/health

# Create an order
curl -X POST "http://localhost:8080/order?name=TestUser"

# Check statistics
curl http://localhost:8080/numberOfCoffees
```

## Troubleshooting

### Problem: "current-context is not set"
**Solution:** Enable Kubernetes in Docker Desktop (see above)

### Problem: "ImagePullBackOff"
**Solution:** 
```bash
docker compose build  # Build images locally
```

### Problem: Pods not starting
**Solution:**
```bash
kubectl describe pod <pod-name> -n coffee-queue
kubectl logs <pod-name> -n coffee-queue
```

### Problem: Database connection failed
**Solution:**
```bash
# Check PostgreSQL is running
kubectl get pods -l app=postgres -n coffee-queue

# Check logs
kubectl logs -l app=postgres -n coffee-queue
```

## Cleanup

```bash
# Remove all resources
kubectl delete namespace coffee-queue

# Or use the script
./test-k8s-deployment.sh cleanup
```

## Advanced Testing

### Test Horizontal Pod Autoscaler (HPA)

```bash
# Check HPA status
kubectl get hpa -n coffee-queue

# Generate load
for i in {1..100}; do
  curl -X POST "http://localhost:8080/order?name=LoadTest-$i" &
done

# Watch pods scale
kubectl get pods -n coffee-queue --watch
```

### Test Rolling Updates

```bash
# Update the deployment
kubectl set image deployment/coffee-queue-app coffee-queue-app=stratalyzedevops-app:latest -n coffee-queue

# Watch the rollout
kubectl rollout status deployment/coffee-queue-app -n coffee-queue

# Rollback if needed
kubectl rollout undo deployment/coffee-queue-app -n coffee-queue
```

### Test Persistence

```bash
# Create orders
curl -X POST "http://localhost:8080/order?name=Test1"
curl -X POST "http://localhost:8080/order?name=Test2"

# Delete app pod
kubectl delete pod -l app=coffee-queue-app -n coffee-queue

# Wait for new pod
kubectl wait --for=condition=ready pod -l app=coffee-queue-app -n coffee-queue --timeout=120s

# Port forward again
kubectl port-forward service/coffee-queue-service 8080:8080 -n coffee-queue &

# Verify data persisted
curl http://localhost:8080/numberOfCoffees
```

## Full Documentation

For complete details, see:
- `KUBERNETES-TESTING.md` - Comprehensive testing guide
- `README.md` - Full project documentation
- `TESTING-GUIDE.md` - General testing guide

## Common kubectl Commands

```bash
# Get all resources in namespace
kubectl get all -n coffee-queue

# Describe a resource
kubectl describe pod <pod-name> -n coffee-queue
kubectl describe deployment coffee-queue-app -n coffee-queue
kubectl describe service coffee-queue-service -n coffee-queue

# View logs
kubectl logs <pod-name> -n coffee-queue
kubectl logs -f -l app=coffee-queue-app -n coffee-queue  # Follow logs

# Execute command in pod
kubectl exec -it <pod-name> -n coffee-queue -- sh

# Scale deployment
kubectl scale deployment coffee-queue-app --replicas=3 -n coffee-queue

# Port forward
kubectl port-forward service/coffee-queue-service 8080:8080 -n coffee-queue

# Top (resource usage)
kubectl top nodes
kubectl top pods -n coffee-queue

# Edit resource
kubectl edit deployment coffee-queue-app -n coffee-queue

# Restart deployment
kubectl rollout restart deployment/coffee-queue-app -n coffee-queue
```
