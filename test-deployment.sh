#!/bin/bash
set -e

echo "=========================================="
echo "Coffee Queue Deployment Test Script"
echo "=========================================="

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed"
    exit 1
fi

# Check if we're connected to a cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: Not connected to a Kubernetes cluster"
    echo "Please ensure your cluster is running and kubectl is configured"
    exit 1
fi

# Check if the namespace exists
if ! kubectl get namespace coffee-queue &> /dev/null; then
    echo "Creating namespace coffee-queue..."
    kubectl apply -f k8s/namespace.yaml
fi

echo "Deploying PostgreSQL..."
kubectl apply -f k8s/postgres/

echo "Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n coffee-queue

echo "Deploying Coffee Queue application..."
kubectl apply -f k8s/app/

echo "Waiting for application to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/coffee-queue-app -n coffee-queue

echo "Checking pod status..."
kubectl get pods -n coffee-queue

echo "Checking services..."
kubectl get services -n coffee-queue

echo "Checking HPA status..."
kubectl get hpa -n coffee-queue

echo ""
echo "=========================================="
echo "Testing the application endpoints..."
echo "=========================================="

# Port forward in the background for testing
echo "Setting up port forwarding..."
kubectl port-forward service/coffee-queue-service 8080:8080 -n coffee-queue &
PORT_FORWARD_PID=$!

# Wait for port forward to be ready
sleep 10

# Function to cleanup
cleanup() {
    echo "Cleaning up port forward..."
    kill $PORT_FORWARD_PID 2>/dev/null || true
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Test health endpoint
echo "Testing health endpoint..."
if curl -f -s http://localhost:8080/health > /dev/null; then
    echo "[PASS] Health check passed"
else
    echo "[FAIL] Health check failed"
    exit 1
fi

# Test order creation
echo "Testing order creation..."
ORDER_RESPONSE=$(curl -f -s -X POST "http://localhost:8080/order?name=TestUser" | jq -r '.id // empty')
if [ -n "$ORDER_RESPONSE" ]; then
    echo "[PASS] Order creation passed (Order ID: $ORDER_RESPONSE)"
else
    echo "[FAIL] Order creation failed"
    exit 1
fi

# Test order status
echo "Testing order status retrieval..."
if curl -f -s "http://localhost:8080/status?name=TestUser" | jq '.' > /dev/null; then
    echo "[PASS] Order status retrieval passed"
else
    echo "[FAIL] Order status retrieval failed"
    exit 1
fi

# Test statistics endpoint
echo "Testing statistics endpoint..."
if curl -f -s http://localhost:8080/numberOfCoffees | jq '.' > /dev/null; then
    echo "[PASS] Statistics endpoint passed"
else
    echo "[FAIL] Statistics endpoint failed"
    exit 1
fi

echo ""
echo "=========================================="
echo "All tests passed successfully!"
echo "=========================================="
echo ""
echo "Useful commands:"
echo "kubectl get pods -n coffee-queue"
echo "kubectl logs -f deployment/coffee-queue-app -n coffee-queue"
echo "kubectl port-forward service/coffee-queue-service 8080:8080 -n coffee-queue"
