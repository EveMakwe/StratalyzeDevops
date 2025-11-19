#!/bin/bash
set -e

echo "=========================================="
echo "Coffee Queue Quick Start"
echo "=========================================="

CLUSTER_NAME=${CLUSTER_NAME:-"coffee-queue-cluster"}
USE_KIND=${USE_KIND:-"true"}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check dependencies
echo "Checking dependencies..."
if ! command_exists docker; then
    echo "Error: Docker is not installed or not running"
    echo "Please install Docker and ensure it's running"
    exit 1
fi

if ! command_exists kubectl; then
    echo "Error: kubectl is not installed"
    echo "Please install kubectl"
    exit 1
fi

if [ "$USE_KIND" = "true" ]; then
    if ! command_exists kind; then
        echo "Error: Kind is not installed"
        echo "Please install Kind or set USE_KIND=false to use an existing cluster"
        exit 1
    fi
    
    # Check if cluster exists
    if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
        echo "Creating Kind cluster: ${CLUSTER_NAME}"
        kind create cluster --name ${CLUSTER_NAME}
    else
        echo "Using existing Kind cluster: ${CLUSTER_NAME}"
    fi
    
    # Switch context to Kind cluster
    kubectl cluster-info --context kind-${CLUSTER_NAME}
    kubectl config use-context kind-${CLUSTER_NAME}
else
    echo "Using existing Kubernetes cluster"
fi

# Build Docker image
echo "Building Coffee Queue Docker image..."
docker build -t coffee-queue:latest ./coffeequeue

if [ "$USE_KIND" = "true" ]; then
    # Load image to Kind cluster
    echo "Loading image to Kind cluster..."
    kind load docker-image coffee-queue:latest --name ${CLUSTER_NAME}
fi

# Deploy to Kubernetes
echo "Deploying to Kubernetes..."
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/postgres/
kubectl apply -f k8s/app/

echo "Waiting for deployments to be ready..."
echo "This may take a few minutes..."

# Wait for PostgreSQL
echo "Waiting for PostgreSQL..."
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n coffee-queue

# Wait for application
echo "Waiting for Coffee Queue app..."
kubectl wait --for=condition=available --timeout=300s deployment/coffee-queue-app -n coffee-queue

echo ""
echo "=========================================="
echo "Deployment completed successfully!"
echo "=========================================="
echo ""
echo "Current status:"
kubectl get all -n coffee-queue

echo ""
echo "To access the application:"
echo "kubectl port-forward service/coffee-queue-service 8080:8080 -n coffee-queue"
echo ""
echo "Test endpoints:"
echo "curl http://localhost:8080/health"
echo "curl -X POST 'http://localhost:8080/order?name=YourName'"
echo "curl 'http://localhost:8080/status?name=YourName'"
echo "curl http://localhost:8080/numberOfCoffees"
echo ""
echo "To run the test suite:"
echo "./test-deployment.sh"
