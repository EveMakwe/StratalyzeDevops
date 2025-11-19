#!/bin/bash
set -e

echo "=========================================="
echo "Coffee Queue Cleanup Script"
echo "=========================================="

CLUSTER_NAME=${CLUSTER_NAME:-"coffee-queue-cluster"}
CLEANUP_CLUSTER=${CLEANUP_CLUSTER:-"false"}

# Function to ask for confirmation
confirm() {
    read -p "$1 (y/N): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

echo "This script will clean up Coffee Queue resources."
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "kubectl is not installed"
    exit 1
fi

# Check if we're connected to a cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "Not connected to a Kubernetes cluster"
    exit 1
fi

echo "Current cluster: $(kubectl config current-context)"
echo ""

if confirm "Remove Coffee Queue application from Kubernetes?"; then
    echo "Removing Coffee Queue application..."
    
    # Remove application resources
    if kubectl get namespace coffee-queue &> /dev/null; then
        echo "Removing application deployments..."
        kubectl delete -f k8s/app/ --ignore-not-found=true
        
        echo "Removing PostgreSQL..."
        kubectl delete -f k8s/postgres/ --ignore-not-found=true
        
        echo "Removing namespace..."
        kubectl delete -f k8s/namespace.yaml --ignore-not-found=true
        
        echo "Kubernetes resources removed"
    else
        echo "Coffee Queue namespace not found"
    fi
fi

# Docker cleanup
if confirm "Remove Docker images and containers?"; then
    echo "Cleaning up Docker resources..."
    
    # Stop and remove containers
    if docker ps -a --format "table {{.Names}}" | grep -q coffee-queue; then
        docker stop $(docker ps -a -q --filter "name=coffee-queue") 2>/dev/null || true
        docker rm $(docker ps -a -q --filter "name=coffee-queue") 2>/dev/null || true
    fi
    
    # Remove images
    if docker images --format "table {{.Repository}}" | grep -q coffee-queue; then
        docker rmi $(docker images -q coffee-queue) 2>/dev/null || true
    fi
    
    # Clean up docker compose volumes
    if [ -f docker-compose.yml ]; then
        docker compose down -v 2>/dev/null || true
    fi
    
    echo "Docker resources cleaned up"
fi

# Kind cluster cleanup
if command -v kind &> /dev/null; then
    if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
        if [ "$CLEANUP_CLUSTER" = "true" ] || confirm "Delete Kind cluster '${CLUSTER_NAME}'?"; then
            echo "Deleting Kind cluster..."
            kind delete cluster --name ${CLUSTER_NAME}
            echo "Kind cluster deleted"
        fi
    fi
fi

echo ""
echo "=========================================="
echo "Cleanup completed!"
echo "=========================================="
echo ""
echo "To redeploy:"
echo "./quick-start.sh"
echo ""
echo "To deploy with docker-compose:"
echo "docker compose up -d"
