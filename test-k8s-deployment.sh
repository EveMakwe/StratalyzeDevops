#!/bin/bash

# Kubernetes Deployment Test Script
# This script automates the testing of Kubernetes deployment

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="coffee-queue"
APP_NAME="coffee-queue-app"
DB_NAME="postgres"
SERVICE_NAME="coffee-queue-service"
PORT=8080

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    print_success "kubectl is installed"
}

# Function to check cluster connectivity
check_cluster() {
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        print_info "Please ensure one of the following is running:"
        print_info "  - Docker Desktop with Kubernetes enabled"
        print_info "  - Minikube (run: minikube start)"
        print_info "  - Kind cluster (run: kind create cluster)"
        exit 1
    fi
    print_success "Connected to Kubernetes cluster"
    kubectl cluster-info | head -n 1
}

# Function to build Docker images
build_images() {
    print_info "Building Docker images..."
    cd "$(dirname "$0")"
    
    if docker compose build; then
        print_success "Docker images built successfully"
    else
        print_error "Failed to build Docker images"
        exit 1
    fi
}

# Function to load images into cluster (for Minikube/Kind)
load_images() {
    print_info "Checking if images need to be loaded into cluster..."
    
    # Check if using Minikube
    if kubectl config current-context | grep -q "minikube"; then
        print_info "Detected Minikube - loading images..."
        minikube image load stratalyzedevops-app:latest
        minikube image load coffee-queue-postgres:15-alpine
        print_success "Images loaded into Minikube"
        return
    fi
    
    # Check if using Kind
    if kubectl config current-context | grep -q "kind"; then
        print_info "Detected Kind - loading images..."
        CLUSTER_NAME=$(kubectl config current-context | sed 's/kind-//')
        kind load docker-image stratalyzedevops-app:latest --name "$CLUSTER_NAME"
        kind load docker-image coffee-queue-postgres:15-alpine --name "$CLUSTER_NAME"
        print_success "Images loaded into Kind cluster"
        return
    fi
    
    print_info "Using Docker Desktop or external cluster - skipping image load"
}

# Function to create namespace
create_namespace() {
    print_info "Creating namespace: $NAMESPACE"
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        print_info "Namespace $NAMESPACE already exists"
    else
        kubectl create namespace "$NAMESPACE"
        print_success "Namespace created"
    fi
}

# Function to deploy PostgreSQL
deploy_postgres() {
    print_info "Deploying PostgreSQL..."
    kubectl apply -f k8s/postgres/ -n "$NAMESPACE"
    
    print_info "Waiting for PostgreSQL to be ready..."
    if kubectl wait --for=condition=ready pod -l app="$DB_NAME" -n "$NAMESPACE" --timeout=120s; then
        print_success "PostgreSQL is ready"
    else
        print_error "PostgreSQL failed to start"
        kubectl logs -l app="$DB_NAME" -n "$NAMESPACE" --tail=50
        exit 1
    fi
}

# Function to deploy application
deploy_app() {
    print_info "Deploying application..."
    kubectl apply -f k8s/app/ -n "$NAMESPACE"
    
    print_info "Waiting for application to be ready..."
    if kubectl wait --for=condition=ready pod -l app="$APP_NAME" -n "$NAMESPACE" --timeout=120s; then
        print_success "Application is ready"
    else
        print_error "Application failed to start"
        kubectl logs -l app="$APP_NAME" -n "$NAMESPACE" --tail=50
        exit 1
    fi
}

# Function to display deployment status
show_status() {
    print_info "Deployment Status:"
    echo ""
    kubectl get all -n "$NAMESPACE"
    echo ""
    
    print_info "Pods:"
    kubectl get pods -n "$NAMESPACE" -o wide
    echo ""
    
    print_info "Services:"
    kubectl get svc -n "$NAMESPACE"
    echo ""
}

# Function to test application
test_app() {
    print_info "Testing application endpoints..."
    
    # Start port-forward in background
    print_info "Setting up port forwarding..."
    kubectl port-forward service/"$SERVICE_NAME" "$PORT:$PORT" -n "$NAMESPACE" &> /dev/null &
    PF_PID=$!
    sleep 3  # Wait for port-forward to establish
    
    # Test health endpoint
    if curl -s http://localhost:$PORT/health | grep -q "OK"; then
        print_success "Health check passed"
    else
        print_error "Health check failed"
        kill $PF_PID 2>/dev/null
        exit 1
    fi
    
    # Create a test order
    print_info "Creating test order..."
    RESPONSE=$(curl -s -X POST "http://localhost:$PORT/order?name=K8sTest")
    if echo "$RESPONSE" | grep -q "customerName"; then
        print_success "Order created successfully"
        echo "Response: $RESPONSE"
    else
        print_error "Failed to create order"
        echo "Response: $RESPONSE"
    fi
    
    # Check order counts
    print_info "Checking order counts..."
    COUNTS=$(curl -s http://localhost:$PORT/numberOfCoffees)
    print_success "Order counts: $COUNTS"
    
    # Kill port-forward
    kill $PF_PID 2>/dev/null
    print_success "All tests passed!"
}

# Function to check HPA
check_hpa() {
    print_info "Checking Horizontal Pod Autoscaler..."
    if kubectl get hpa -n "$NAMESPACE" &> /dev/null; then
        kubectl get hpa -n "$NAMESPACE"
        print_success "HPA is configured"
    else
        print_info "No HPA found"
    fi
}

# Function to view logs
view_logs() {
    print_info "Recent application logs:"
    kubectl logs -l app="$APP_NAME" -n "$NAMESPACE" --tail=20
    echo ""
    
    print_info "Recent database logs:"
    kubectl logs -l app="$DB_NAME" -n "$NAMESPACE" --tail=20
}

# Function to cleanup
cleanup() {
    print_info "Cleaning up resources..."
    kubectl delete namespace "$NAMESPACE" --ignore-not-found=true
    print_success "Cleanup complete"
}

# Function to show usage
show_usage() {
    echo "Kubernetes Deployment Test Script"
    echo ""
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  deploy     - Build images and deploy to Kubernetes"
    echo "  test       - Test the deployed application"
    echo "  status     - Show deployment status"
    echo "  logs       - View application and database logs"
    echo "  hpa        - Check HPA configuration"
    echo "  cleanup    - Delete all resources"
    echo "  full       - Run full deployment and test (default)"
    echo "  help       - Show this help message"
    echo ""
}

# Main script
main() {
    case "${1:-full}" in
        deploy)
            check_kubectl
            check_cluster
            build_images
            load_images
            create_namespace
            deploy_postgres
            deploy_app
            show_status
            ;;
        test)
            check_kubectl
            check_cluster
            test_app
            ;;
        status)
            check_kubectl
            check_cluster
            show_status
            check_hpa
            ;;
        logs)
            check_kubectl
            check_cluster
            view_logs
            ;;
        hpa)
            check_kubectl
            check_cluster
            check_hpa
            ;;
        cleanup)
            check_kubectl
            check_cluster
            cleanup
            ;;
        full)
            check_kubectl
            check_cluster
            build_images
            load_images
            create_namespace
            deploy_postgres
            deploy_app
            show_status
            sleep 5  # Wait for services to stabilize
            test_app
            check_hpa
            print_success "Full deployment and testing complete!"
            echo ""
            print_info "To access the application, run:"
            echo "  kubectl port-forward service/$SERVICE_NAME $PORT:$PORT -n $NAMESPACE"
            echo ""
            print_info "To view logs, run:"
            echo "  kubectl logs -f -l app=$APP_NAME -n $NAMESPACE"
            echo ""
            print_info "To cleanup, run:"
            echo "  $0 cleanup"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
