#!/bin/bash

# Deploy PgBouncer for PostgreSQL connection pooling
# Usage: ./deploy-pgbouncer.sh

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🚀 Deploying PgBouncer..."

# Create namespace if it doesn't exist
kubectl create namespace default --dry-run=client -o yaml | kubectl apply -f -

# Apply ConfigMap and Secret
echo "📝 Applying PgBouncer configuration..."
kubectl apply -f "$K8S_DIR/database/pgbouncer/pgbouncer-configmap.yaml"
kubectl apply -f "$K8S_DIR/database/pgbouncer/pgbouncer-secret.yaml"

# Apply Deployment
echo "🔄 Deploying PgBouncer pods..."
kubectl apply -f "$K8S_DIR/database/pgbouncer/pgbouncer-deployment.yaml"

# Apply Service
echo "🌐 Creating PgBouncer service..."
kubectl apply -f "$K8S_DIR/database/pgbouncer/pgbouncer-service.yaml"

# Apply HPA
echo "📈 Creating PgBouncer HPA..."
kubectl apply -f "$K8S_DIR/database/pgbouncer/pgbouncer-hpa.yaml"

# Wait for deployment to be ready
echo "⏳ Waiting for PgBouncer to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/pgbouncer

# Show status
echo "📊 PgBouncer deployment status:"
kubectl get pods -l app=pgbouncer
kubectl get svc pgbouncer-service
kubectl get hpa pgbouncer-hpa

echo "✅ PgBouncer deployed successfully!"
echo ""
echo "🔗 Connection details:"
echo "  Service: pgbouncer-service.default.svc.cluster.local:5432"
echo "  Internal: pgbouncer-service:5432"
echo ""
echo "📝 To connect to PgBouncer admin:"
echo "  kubectl port-forward svc/pgbouncer-service 5432:5432"
echo "  psql -h localhost -p 5432 -U postgres pgbouncer"
echo ""
echo "🔍 To check PgBouncer logs:"
echo "  kubectl logs -l app=pgbouncer -f"
echo ""
echo "📈 To monitor HPA scaling:"
echo "  kubectl get hpa pgbouncer-hpa -w"
echo "  kubectl describe hpa pgbouncer-hpa"