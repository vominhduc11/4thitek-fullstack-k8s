#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Deploy script for fe_main
echo "🚀 Deploying fe_main to Kubernetes..."

# Build Docker image
echo "📦 Building Docker image..."
docker build -t fe-main:latest "$SCRIPT_DIR/../../fe/main"

# Load image to minikube
echo "📥 Loading image to minikube..."
minikube image load fe-main:latest

# Apply Kubernetes manifests
echo "⚙️  Applying Kubernetes manifests..."
kubectl apply -f "$K8S_DIR/frontend/main/fe-main-deployment.yaml"
kubectl apply -f "$K8S_DIR/frontend/main/fe-main-service.yaml"
kubectl apply -f "$K8S_DIR/frontend/main/fe-main-hpa.yaml"

# Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready..."
kubectl rollout status deployment/fe-main

# Show deployment status
echo "✅ Deployment completed!"
echo ""
echo "📊 Current status:"
kubectl get pods -l app=fe-main
kubectl get services fe-main-service
kubectl get ingress fe-main-ingress
kubectl get hpa fe-main-hpa

echo ""
echo "🌐 Application should be available at: http://main.4thitek.com"
echo "🔗 Port-forward for local access: kubectl port-forward service/fe-main-service 4000:3000"