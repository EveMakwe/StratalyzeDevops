#!/bin/bash

# Simple Docker Desktop K8s Test
# Enable Kubernetes in Docker Desktop first!

echo "🔍 Checking Kubernetes..."

if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Kubernetes is not running"
    echo ""
    echo "Please enable Kubernetes in Docker Desktop:"
    echo "  1. Open Docker Desktop"
    echo "  2. Go to Settings → Kubernetes"
    echo "  3. Enable Kubernetes"
    echo "  4. Wait for it to start (green indicator)"
    echo ""
    exit 1
fi

echo "✅ Kubernetes is running!"
echo ""

# Build images
echo "📦 Building Docker images..."
docker compose build --quiet

echo "✅ Images built"
echo ""

# Deploy
echo "🚀 Deploying to Kubernetes..."

# Create namespace
kubectl create namespace coffee-queue 2>/dev/null || echo "  Namespace already exists"

# Deploy PostgreSQL
echo "  📊 Deploying PostgreSQL..."
kubectl apply -f k8s/postgres/ -n coffee-queue > /dev/null

# Wait for PostgreSQL
echo "  ⏳ Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n coffee-queue --timeout=60s > /dev/null

echo "  ✅ PostgreSQL is ready"

# Deploy Application
echo "  🎯 Deploying Coffee Queue App..."
kubectl apply -f k8s/app/ -n coffee-queue > /dev/null

# Wait for Application
echo "  ⏳ Waiting for application to be ready..."
kubectl wait --for=condition=ready pod -l app=coffee-queue-app -n coffee-queue --timeout=60s > /dev/null

echo "  ✅ Application is ready"
echo ""

# Show status
echo "📊 Deployment Status:"
kubectl get pods -n coffee-queue

echo ""
echo "🎉 Deployment complete!"
echo ""
echo "📍 To access the application:"
echo "   kubectl port-forward service/coffee-queue-service 8080:8080 -n coffee-queue"
echo ""
echo "   Then visit: http://localhost:8080/health"
echo ""
echo "🧹 To cleanup:"
echo "   kubectl delete namespace coffee-queue"
