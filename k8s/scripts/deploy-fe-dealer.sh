#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Deploy script for fe_dealer
echo "🚀 Deploying fe_dealer to Kubernetes..."

# Build Docker image
echo "📦 Building Docker image..."
docker build -t fe-dealer:latest "$SCRIPT_DIR/../../fe/dealer"

# Load image to minikube
echo "📥 Loading image to minikube..."
minikube image load fe-dealer:latest

# Apply Kubernetes manifests
echo "⚙️  Applying Kubernetes manifests..."
kubectl apply -f "$K8S_DIR/frontend/dealer/fe-dealer-deployment.yaml"
kubectl apply -f "$K8S_DIR/frontend/dealer/fe-dealer-service.yaml"
kubectl apply -f "$K8S_DIR/frontend/dealer/fe-dealer-hpa.yaml"

# Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready..."
kubectl rollout status deployment/fe-dealer

# Show deployment status
echo "✅ Deployment completed!"
echo ""
echo "📊 Current status:"
kubectl get pods -l app=fe-dealer
kubectl get services fe-dealer-service
kubectl get ingress fe-dealer-ingress
kubectl get hpa fe-dealer-hpa

echo ""
echo "🌐 Application should be available at: http://dealer.4thitek.com"
echo "🔗 Port-forward for local access: kubectl port-forward service/fe-dealer-service 6000:80"