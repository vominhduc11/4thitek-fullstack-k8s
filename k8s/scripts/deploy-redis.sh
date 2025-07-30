#!/bin/bash

# Deploy Redis script
echo "🚀 Deploying Redis on Kubernetes..."

# Deploy Redis
echo "🔴 Deploying Redis..."
kubectl apply -f ../cache/redis/redis-pv-pvc.yaml
kubectl apply -f ../cache/redis/redis-configmap.yaml
kubectl apply -f ../cache/redis/redis-deployment.yaml
kubectl apply -f ../cache/redis/redis-service.yaml

# Wait for Redis to be ready
echo "⏳ Waiting for Redis to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/redis

echo "✅ Redis deployment completed!"
echo ""
echo "📋 Service Information:"
echo "  Redis Internal: redis-service:6379 (within cluster)"
echo "  Redis External: localhost:30379 (from outside cluster)"
echo ""
echo "🔍 Check deployment status:"
echo "  kubectl get pods -l app=redis"
echo "  kubectl get services -l app=redis"
echo ""
echo "🧪 Test Redis connection:"
echo "  kubectl exec -it deployment/redis -- redis-cli ping"