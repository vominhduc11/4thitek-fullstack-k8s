#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Deploy script for pgAdmin
echo "🚀 Deploying pgAdmin to Kubernetes..."

# Apply Kubernetes manifests in order
echo "⚙️  Applying Kubernetes manifests..."

# Create Secrets first
echo "🔐 Creating Secrets..."
kubectl apply -f "$K8S_DIR/database/pgadmin/pgadmin-secret.yaml"
kubectl apply -f "$K8S_DIR/database/pgadmin/pgadmin-pgpass-secret.yaml"

# Create ConfigMap
echo "📝 Creating ConfigMap..."
kubectl apply -f "$K8S_DIR/database/pgadmin/pgadmin-config.yaml"

# Create Deployment
echo "🚀 Creating pgAdmin deployment..."
kubectl apply -f "$K8S_DIR/database/pgadmin/pgadmin-deployment.yaml"

# Create Service
echo "🌐 Creating pgAdmin service..."
kubectl apply -f "$K8S_DIR/database/pgadmin/pgadmin-service.yaml"

# Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready..."
kubectl rollout status deployment/pgadmin

# Show deployment status
echo "✅ Deployment completed!"
echo ""
echo "📊 Current status:"
kubectl get pods -l app=pgadmin
kubectl get services pgadmin-service

echo ""
echo "📋 pgAdmin connection info:"
echo "   URL: http://localhost:30080"
echo "   📧 Email: admin@4thitek.com"
echo "   🔐 Password: Stored in pgadmin-secret (Strong-P@ssw0rd-2024!)"
echo ""
echo "🔗 Port-forward for custom port:"
echo "   kubectl port-forward service/pgadmin-service 8080:80"
echo ""
echo "🔧 PostgreSQL auto-connect server (pre-configured):"
echo "   Name: 4thitek PostgreSQL"
echo "   Host: postgres-service"
echo "   Port: 5432"
echo "   Database: 4thitek_db"
echo "   Username: postgres"
echo "   🔐 Password: Stored in secrets (PostgreSQL-Strong-P@ss2024!)"
echo ""
echo "ℹ️  Note: Credentials are now stored in Kubernetes Secrets for security"