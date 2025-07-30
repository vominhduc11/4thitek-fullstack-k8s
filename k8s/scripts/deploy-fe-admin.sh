#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Deploy script for fe_admin
echo "🚀 Deploying fe_admin to Kubernetes..."

# Build Docker image
echo "📦 Building Docker image..."
docker build -t fe-admin:latest "$SCRIPT_DIR/../../fe/admin"

# Load image to minikube
echo "📥 Loading image to minikube..."
minikube image load fe-admin:latest

# Apply Kubernetes manifests
echo "⚙️  Applying Kubernetes manifests..."
kubectl apply -f "$K8S_DIR/frontend/admin/fe-admin-deployment.yaml"
kubectl apply -f "$K8S_DIR/frontend/admin/fe-admin-service.yaml"
kubectl apply -f "$K8S_DIR/frontend/admin/fe-admin-hpa.yaml"

# Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready..."
kubectl rollout status deployment/fe-admin

# Show deployment status
echo "✅ Deployment completed!"
echo ""
echo "📊 Current status:"
kubectl get pods -l app=fe-admin
kubectl get services fe-admin-service
kubectl get ingress fe-admin-ingress
kubectl get hpa fe-admin-hpa

echo ""
echo "🌐 Application should be available at: http://admin.4thitek.com"
echo "🔗 Port-forward for local access: kubectl port-forward service/fe-admin-service 5000:80"