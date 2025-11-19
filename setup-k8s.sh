#!/bin/bash

# Quick Kubernetes Setup Script for macOS
# This script helps you set up Kubernetes for local testing

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

print_step() {
    echo -e "${BLUE}→ $1${NC}"
}

# Check if Docker Desktop is running
check_docker() {
    if ! docker info &> /dev/null; then
        print_error "Docker is not running"
        print_info "Please start Docker Desktop first"
        exit 1
    fi
    print_success "Docker is running"
}

# Setup options
show_menu() {
    print_header "Kubernetes Setup for Coffee Queue Project"
    
    echo "Choose your Kubernetes setup option:"
    echo ""
    echo "  1) Docker Desktop Kubernetes (Recommended - Easiest)"
    echo "  2) Minikube (Good for testing)"
    echo "  3) Kind (Kubernetes in Docker)"
    echo "  4) Skip setup (cluster already configured)"
    echo ""
    read -p "Enter your choice [1-4]: " choice
    echo ""
}

# Setup Docker Desktop Kubernetes
setup_docker_desktop() {
    print_header "Docker Desktop Kubernetes Setup"
    
    print_info "To enable Kubernetes in Docker Desktop:"
    echo ""
    echo "  1. Open Docker Desktop"
    echo "  2. Click the gear icon (Settings)"
    echo "  3. Go to 'Kubernetes' section"
    echo "  4. Check 'Enable Kubernetes'"
    echo "  5. Click 'Apply & Restart'"
    echo "  6. Wait for Kubernetes status to show green"
    echo ""
    
    read -p "Press Enter once Kubernetes is enabled in Docker Desktop..."
    
    print_info "Verifying Kubernetes setup..."
    sleep 3
    
    if kubectl cluster-info &> /dev/null; then
        print_success "Kubernetes is running!"
        kubectl cluster-info
        return 0
    else
        print_error "Cannot connect to Kubernetes"
        print_info "Please ensure Kubernetes is enabled in Docker Desktop"
        return 1
    fi
}

# Setup Minikube
setup_minikube() {
    print_header "Minikube Setup"
    
    # Check if minikube is installed
    if ! command -v minikube &> /dev/null; then
        print_info "Minikube is not installed. Installing..."
        
        if command -v brew &> /dev/null; then
            brew install minikube
            print_success "Minikube installed via Homebrew"
        else
            print_info "Downloading Minikube..."
            curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-arm64
            sudo install minikube-darwin-arm64 /usr/local/bin/minikube
            rm minikube-darwin-arm64
            print_success "Minikube installed"
        fi
    else
        print_success "Minikube is already installed"
    fi
    
    # Start minikube
    print_info "Starting Minikube cluster..."
    if minikube start --driver=docker; then
        print_success "Minikube started successfully"
        minikube status
        kubectl cluster-info
        return 0
    else
        print_error "Failed to start Minikube"
        return 1
    fi
}

# Setup Kind
setup_kind() {
    print_header "Kind Setup"
    
    # Check if kind is installed
    if ! command -v kind &> /dev/null; then
        print_info "Kind is not installed. Installing..."
        
        if command -v brew &> /dev/null; then
            brew install kind
            print_success "Kind installed via Homebrew"
        else
            print_info "Downloading Kind..."
            curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-darwin-arm64
            chmod +x ./kind
            sudo mv ./kind /usr/local/bin/kind
            print_success "Kind installed"
        fi
    else
        print_success "Kind is already installed"
    fi
    
    # Create cluster
    print_info "Creating Kind cluster..."
    if kind create cluster --name coffee-queue-cluster; then
        print_success "Kind cluster created successfully"
        kubectl cluster-info --context kind-coffee-queue-cluster
        return 0
    else
        print_error "Failed to create Kind cluster"
        return 1
    fi
}

# Test the setup
test_setup() {
    print_header "Testing Kubernetes Setup"
    
    print_step "Checking kubectl..."
    if kubectl version --client &> /dev/null; then
        print_success "kubectl is working"
    else
        print_error "kubectl is not working properly"
        return 1
    fi
    
    print_step "Checking cluster connection..."
    if kubectl cluster-info &> /dev/null; then
        print_success "Connected to cluster"
        kubectl get nodes
    else
        print_error "Cannot connect to cluster"
        return 1
    fi
    
    print_step "Checking cluster version..."
    kubectl version --client 2>/dev/null || kubectl version --client --output=yaml 2>/dev/null | head -n 5
    
    print_success "Kubernetes is ready for deployment!"
}

# Show next steps
show_next_steps() {
    print_header "Next Steps"
    
    echo "Your Kubernetes cluster is ready! Here's what you can do now:"
    echo ""
    echo "1. Deploy the Coffee Queue application:"
    echo "   ${GREEN}./test-k8s-deployment.sh${NC}"
    echo ""
    echo "2. Or deploy manually:"
    echo "   ${GREEN}kubectl create namespace coffee-queue${NC}"
    echo "   ${GREEN}kubectl apply -f k8s/postgres/ -n coffee-queue${NC}"
    echo "   ${GREEN}kubectl apply -f k8s/app/ -n coffee-queue${NC}"
    echo ""
    echo "3. Check deployment status:"
    echo "   ${GREEN}kubectl get all -n coffee-queue${NC}"
    echo ""
    echo "4. Access the application:"
    echo "   ${GREEN}kubectl port-forward service/coffee-queue-service 8080:8080 -n coffee-queue${NC}"
    echo "   Then visit: ${GREEN}http://localhost:8080/health${NC}"
    echo ""
    echo "5. View logs:"
    echo "   ${GREEN}kubectl logs -f -l app=coffee-queue-app -n coffee-queue${NC}"
    echo ""
    echo "For more details, see: ${YELLOW}KUBERNETES-TESTING.md${NC}"
    echo ""
}

# Main function
main() {
    check_docker
    
    show_menu
    
    case $choice in
        1)
            if setup_docker_desktop; then
                test_setup
                show_next_steps
            fi
            ;;
        2)
            if setup_minikube; then
                test_setup
                show_next_steps
            fi
            ;;
        3)
            if setup_kind; then
                test_setup
                show_next_steps
            fi
            ;;
        4)
            print_info "Skipping setup..."
            if test_setup; then
                show_next_steps
            else
                print_error "Cluster is not properly configured"
                exit 1
            fi
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
}

# Run main
main
