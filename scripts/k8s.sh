#!/bin/bash

# Coffee Queue Kubernetes Tool
# Manage Kubernetes operations

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

NAMESPACE=${K8S_NAMESPACE:-coffee-queue}

echo_blue() { echo -e "${BLUE}$1${NC}"; }
echo_green() { echo -e "${GREEN}$1${NC}"; }
echo_red() { echo -e "${RED}$1${NC}"; }
echo_yellow() { echo -e "${YELLOW}$1${NC}"; }

show_help() {
    cat <<EOF
Coffee Queue Kubernetes Tool - K8s Manager

USAGE:
    ./k8s.sh <command>

COMMANDS:
    setup       Setup Kubernetes environment (Docker Desktop/Minikube/Kind)
    deploy      Deploy application to Kubernetes
    test        Test the deployed application
    status      Show deployment status (pods, services, HPA)
    logs        View application logs
    monitor     Monitor pods and HPA (live updating)
    scale       Scale application replicas
    port        Port-forward to access service
    clean       Delete all Kubernetes resources
    help        Show this help message

ENVIRONMENT:
    K8S_NAMESPACE    Kubernetes namespace (default: coffee-queue)

EOF
}

# Check kubectl
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo_red "kubectl is not installed!"
        echo "Run './setup.sh' to install kubectl"
        exit 1
    fi
}

# Check cluster
check_cluster() {
    if ! kubectl cluster-info &> /dev/null; then
        echo_red "Cannot connect to Kubernetes cluster!"
        echo "Run './k8s.sh setup' to configure a cluster"
        exit 1
    fi
}

# Setup Kubernetes
cmd_setup() {
    echo_blue "Setting up Kubernetes environment..."
    echo ""
    echo "Choose your Kubernetes platform:"
    echo "1) Docker Desktop (recommended for Mac/Windows)"
    echo "2) Minikube (cross-platform)"
    echo "3) Kind (lightweight, Docker-based)"
    echo ""
    read -p "Enter choice (1-3): " choice
    
    case $choice in
        1)
            echo_blue "Starting Docker Desktop Kubernetes..."
            echo "Please enable Kubernetes in Docker Desktop settings:"
            echo "  Docker Desktop > Settings > Kubernetes > Enable Kubernetes"
            ;;
        2)
            echo_blue "Starting Minikube..."
            if ! command -v minikube &> /dev/null; then
                echo_red "Minikube is not installed. Run './setup.sh' first"
                exit 1
            fi
            minikube start --driver=docker
            echo_green "Minikube started successfully!"
            ;;
        3)
            echo_blue "Starting Kind cluster..."
            if ! command -v kind &> /dev/null; then
                echo_red "Kind is not installed. Run './setup.sh' first"
                exit 1
            fi
            kind create cluster --name coffee-queue
            echo_green "Kind cluster created successfully!"
            ;;
        *)
            echo_red "Invalid choice"
            exit 1
            ;;
    esac
    
    echo ""
    echo_green "Kubernetes setup completed!"
    echo "Run './k8s.sh deploy' to deploy the application"
}

# Deploy application
cmd_deploy() {
    echo_blue "Deploying Coffee Queue to Kubernetes..."
    
    # Build image
    echo "Building Docker image..."
    docker compose build
    
    # Load image based on cluster type
    if kubectl config current-context | grep -q "minikube"; then
        echo "Loading image to Minikube..."
        minikube image load stratalyzedevops-app:latest
    elif kubectl config current-context | grep -q "kind"; then
        echo "Loading image to Kind..."
        kind load docker-image stratalyzedevops-app:latest --name coffee-queue
    fi
    
    # Create namespace
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    
    # Apply Kubernetes manifests
    echo "Applying Kubernetes manifests..."
    kubectl apply -f k8s/namespace.yaml
    kubectl apply -f k8s/postgres/ -n $NAMESPACE
    kubectl apply -f k8s/app/ -n $NAMESPACE
    
    echo ""
    echo_green "Deployment completed!"
    echo "Run './k8s.sh status' to check deployment status"
    echo "Run './k8s.sh port' to access the application"
}

# Test deployment
cmd_test() {
    echo_blue "Testing Coffee Queue deployment..."
    
    # Wait for pods
    echo "Waiting for pods to be ready..."
    kubectl wait --for=condition=ready pod -l app=coffee-queue -n $NAMESPACE --timeout=120s
    
    # Port forward in background
    echo "Setting up port forwarding..."
    kubectl port-forward -n $NAMESPACE svc/coffee-queue-service 8080:8080 &
    PF_PID=$!
    sleep 3
    
    # Run tests
    echo "Running tests..."
    
    # Test health
    if curl -sf http://localhost:8080/health > /dev/null; then
        echo_green "Health check: PASSED"
    else
        echo_red "Health check: FAILED"
        kill $PF_PID 2>/dev/null
        exit 1
    fi
    
    # Test create order
    if curl -sf -X POST http://localhost:8080/api/orders \
        -H "Content-Type: application/json" \
        -d '{"customerName":"K8sTest","coffeeType":"Latte"}' > /dev/null; then
        echo_green "Create order: PASSED"
    else
        echo_red "Create order: FAILED"
        kill $PF_PID 2>/dev/null
        exit 1
    fi
    
    # Test get orders
    if curl -sf http://localhost:8080/api/orders > /dev/null; then
        echo_green "Get orders: PASSED"
    else
        echo_red "Get orders: FAILED"
        kill $PF_PID 2>/dev/null
        exit 1
    fi
    
    # Cleanup
    kill $PF_PID 2>/dev/null
    
    echo ""
    echo_green "All tests passed!"
}

# Show status
cmd_status() {
    echo_blue "Deployment Status for namespace: $NAMESPACE"
    echo ""
    
    echo "Pods:"
    kubectl get pods -n $NAMESPACE -o wide
    echo ""
    
    echo "Services:"
    kubectl get svc -n $NAMESPACE
    echo ""
    
    echo "Deployments:"
    kubectl get deployments -n $NAMESPACE
    echo ""
    
    echo "HPA (if configured):"
    kubectl get hpa -n $NAMESPACE 2>/dev/null || echo "No HPA configured"
    echo ""
    
    echo "Recent Events:"
    kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -10
}

# View logs
cmd_logs() {
    echo_blue "Showing application logs (Ctrl+C to exit)..."
    kubectl logs -f -n $NAMESPACE -l app=coffee-queue --tail=100
}

# Monitor resources
cmd_monitor() {
    echo_blue "Monitoring Coffee Queue (Ctrl+C to exit)..."
    watch -n 2 "kubectl top pods -n $NAMESPACE 2>/dev/null; echo ''; kubectl get hpa -n $NAMESPACE 2>/dev/null"
}

# Scale application
cmd_scale() {
    read -p "Enter number of replicas: " replicas
    echo_blue "Scaling application to $replicas replicas..."
    kubectl scale deployment coffee-queue -n $NAMESPACE --replicas=$replicas
    echo_green "Scaling initiated!"
    echo "Run './k8s.sh status' to check progress"
}

# Port forward
cmd_port() {
    echo_blue "Port forwarding Coffee Queue service..."
    echo "Application will be available at: http://localhost:8080"
    echo "Press Ctrl+C to stop"
    echo ""
    kubectl port-forward -n $NAMESPACE svc/coffee-queue-service 8080:8080
}

# Clean up
cmd_clean() {
    echo_yellow "This will delete all resources in namespace: $NAMESPACE"
    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo_blue "Cleaning up..."
        kubectl delete namespace $NAMESPACE --ignore-not-found
        echo_green "Cleanup completed!"
    else
        echo "Cleanup cancelled"
    fi
}

# Main
main() {
    check_kubectl
    
    case "${1:-help}" in
        setup)
            cmd_setup
            ;;
        deploy)
            check_cluster
            cmd_deploy
            ;;
        test)
            check_cluster
            cmd_test
            ;;
        status)
            check_cluster
            cmd_status
            ;;
        logs)
            check_cluster
            cmd_logs
            ;;
        monitor)
            check_cluster
            cmd_monitor
            ;;
        scale)
            check_cluster
            cmd_scale
            ;;
        port|port-forward)
            check_cluster
            cmd_port
            ;;
        clean|cleanup)
            check_cluster
            cmd_clean
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo_red "Unknown command: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"

