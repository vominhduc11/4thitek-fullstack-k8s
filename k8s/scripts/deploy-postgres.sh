#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Deploy script for PostgreSQL
echo "🚀 Deploying PostgreSQL to Kubernetes..."

# Apply Kubernetes manifests in order
echo "⚙️  Applying Kubernetes manifests..."

# Create ConfigMap
echo "📝 Creating ConfigMap..."
kubectl apply -f "$K8S_DIR/database/postgres/postgres-configmap.yaml"

# Create PersistentVolume and PersistentVolumeClaim
echo "💾 Creating storage resources..."
kubectl apply -f "$K8S_DIR/database/postgres/postgres-pv-pvc.yaml"

# Wait a moment for PVC to be bound
echo "⏳ Waiting for PVC to be bound..."
sleep 5

# Create Deployment
echo "🚀 Creating PostgreSQL deployment..."
kubectl apply -f "$K8S_DIR/database/postgres/postgres-deployment.yaml"

# Create Service
echo "🌐 Creating PostgreSQL service..."
kubectl apply -f "$K8S_DIR/database/postgres/postgres-service.yaml"

# Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready..."
kubectl rollout status deployment/postgres

# Show deployment status
echo "✅ Deployment completed!"
echo ""
echo "📊 Current status:"
kubectl get pods -l app=postgres
kubectl get services postgres-service
kubectl get pvc postgres-pvc
kubectl get pv postgres-pv

echo ""
echo "📋 Database connection info:"
echo "   Host: postgres-service"
echo "   Port: 5432"
echo "   Database: 4thitek_db"
echo "   Username: postgres"
echo "   Password: postgres123"
echo ""
echo "🔗 Port-forward for external access:"
echo "   kubectl port-forward service/postgres-service 5432:5432"
echo ""
echo "🔧 Connect using psql:"
echo "   kubectl exec -it deployment/postgres -- psql -U postgres -d 4thitek_db"