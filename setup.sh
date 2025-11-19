#!/bin/bash
set -e

echo "=========================================="
echo "Coffee Queue DevOps Environment Setup"
echo "=========================================="

# Update system
echo "Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

# Install required packages
echo "Installing required packages..."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common

# Install Docker
echo "Installing Docker..."
if ! command -v docker &> /dev/null; then
    # Add Docker's official GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Add the repository to Apt sources
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker Engine
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    echo "Docker installed successfully!"
else
    echo "Docker is already installed"
fi

# Install kubectl
echo "Installing kubectl..."
if ! command -v kubectl &> /dev/null; then
    # Download the latest release
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    
    # Install kubectl
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    
    echo "kubectl installed successfully!"
else
    echo "kubectl is already installed"
fi

# Install Minikube
echo "Installing Minikube..."
if ! command -v minikube &> /dev/null; then
    # Download and install Minikube
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
    
    echo "Minikube installed successfully!"
else
    echo "Minikube is already installed"
fi

# Install Kind (alternative to Minikube)
echo "Installing Kind..."
if ! command -v kind &> /dev/null; then
    # Download and install Kind
    [ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
    
    echo "Kind installed successfully!"
else
    echo "Kind is already installed"
fi

# Install Maven (if not already installed)
echo "Installing Maven..."
if ! command -v mvn &> /dev/null; then
    sudo apt-get install -y maven
    echo "Maven installed successfully!"
else
    echo "Maven is already installed"
fi

# Install Java 21 (if not already installed)
echo "Installing Java 21..."
if ! java -version 2>&1 | grep -q "21"; then
    sudo apt-get install -y openjdk-21-jdk
    echo "Java 21 installed successfully!"
else
    echo "Java 21 is already installed"
fi

# Verify installations
echo ""
echo "=========================================="
echo "Verifying installations..."
echo "=========================================="

echo "Docker version:"
docker --version

echo "Docker Compose version:"
docker compose version

echo "kubectl version:"
kubectl version --client

echo "Minikube version:"
minikube version

echo "Kind version:"
kind version

echo "Maven version:"
mvn --version

echo "Java version:"
java -version

echo ""
echo "=========================================="
echo "Setup completed successfully!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Log out and log back in (or run 'newgrp docker') to use Docker without sudo"
echo "2. Start Minikube: minikube start"
echo "3. Or start Kind cluster: kind create cluster --name coffee-queue"
echo "4. Clone the coffee-queue repository and run: docker compose up"
echo ""
