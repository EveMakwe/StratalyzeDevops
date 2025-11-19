#!/bin/bash

echo "=========================================="
echo "Coffee Queue Monitoring Dashboard"
echo "=========================================="

# Function to display colored output
print_status() {
    if [ "$2" = "true" ]; then
        echo "[PASS] $1"
    else
        echo "[FAIL] $1"
    fi
}

# Check cluster connectivity
echo "Checking cluster connectivity..."
if kubectl cluster-info &> /dev/null; then
    print_status "Connected to Kubernetes cluster" true
    CLUSTER_NAME=$(kubectl config current-context)
    echo "   Cluster: $CLUSTER_NAME"
else
    print_status "Not connected to Kubernetes cluster" false
    echo "Please ensure your cluster is running and kubectl is configured"
    exit 1
fi

echo ""
echo "=========================================="
echo "Namespace Status"
echo "=========================================="

if kubectl get namespace coffee-queue &> /dev/null; then
    print_status "Namespace 'coffee-queue' exists" true
else
    print_status "Namespace 'coffee-queue' not found" false
    echo "Run './quick-start.sh' to deploy the application"
    exit 1
fi

echo ""
echo "=========================================="
echo "Pod Status"
echo "=========================================="

kubectl get pods -n coffee-queue -o wide

echo ""
echo "=========================================="
echo "Service Status"
echo "=========================================="

kubectl get services -n coffee-queue

echo ""
echo "=========================================="
echo "Deployment Status"
echo "=========================================="

kubectl get deployments -n coffee-queue

echo ""
echo "=========================================="
echo "HPA Status"
echo "=========================================="

if kubectl get hpa -n coffee-queue &> /dev/null; then
    kubectl get hpa -n coffee-queue
    echo ""
    kubectl describe hpa coffee-queue-hpa -n coffee-queue | grep -E "(Metrics|Current|Target)"
else
    echo "HPA not found or metrics server not available"
fi

echo ""
echo "=========================================="
echo "Resource Usage"
echo "=========================================="

if kubectl top pods -n coffee-queue &> /dev/null; then
    kubectl top pods -n coffee-queue
else
    echo "Metrics server not available - cannot show resource usage"
fi

echo ""
echo "=========================================="
echo "Recent Events"
echo "=========================================="

kubectl get events -n coffee-queue --sort-by='.lastTimestamp' | tail -10

echo ""
echo "=========================================="
echo "Application Health Check"
echo "=========================================="

# Check if service is accessible
if kubectl get service coffee-queue-service -n coffee-queue &> /dev/null; then
    # Try to port forward and test
    kubectl port-forward service/coffee-queue-service 8081:8080 -n coffee-queue &> /dev/null &
    PORT_FORWARD_PID=$!
    
    # Wait a bit for port forward
    sleep 3
    
    # Test health endpoint
    if curl -f -s http://localhost:8081/health &> /dev/null; then
        print_status "Application health check passed" true
    else
        print_status "Application health check failed" false
    fi
    
    # Cleanup
    kill $PORT_FORWARD_PID 2>/dev/null || true
else
    print_status "Application service not found" false
fi

echo ""
echo "=========================================="
echo "Useful Commands"
echo "=========================================="
echo "View logs:"
echo "kubectl logs -f deployment/coffee-queue-app -n coffee-queue"
echo "kubectl logs -f deployment/postgres -n coffee-queue"
echo ""
echo "Access application:"
echo "kubectl port-forward service/coffee-queue-service 8080:8080 -n coffee-queue"
echo ""
echo "Scale application:"
echo "kubectl scale deployment coffee-queue-app --replicas=3 -n coffee-queue"
echo ""
echo "Update application:"
echo "kubectl set image deployment/coffee-queue-app coffee-queue-app=coffee-queue:new-tag -n coffee-queue"
echo ""
echo "Debug pod:"
echo "kubectl exec -it deployment/coffee-queue-app -n coffee-queue -- /bin/sh"
