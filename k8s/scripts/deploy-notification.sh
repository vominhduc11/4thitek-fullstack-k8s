#!/bin/bash

# Deploy Notification Service to Kubernetes
echo "🚀 Deploying Notification Service..."

# Apply configurations
echo "📝 Applying Secret and ConfigMap..."
kubectl apply -f ../backend/notification-service/notification-secret.yaml

echo "🚢 Deploying Notification Service..."
kubectl apply -f ../backend/notification-service/notification-deployment.yaml

echo "🌐 Creating Service..."
kubectl apply -f ../backend/notification-service/notification-service.yaml

echo "📈 Setting up HPA..."
kubectl apply -f ../backend/notification-service/notification-hpa.yaml

echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/notification-service

echo "✅ Notification Service deployed successfully!"

# Show status
echo "📊 Current status:"
kubectl get pods -l app=notification-service
kubectl get svc notification-service
kubectl get hpa notification-service-hpa

echo "🔗 Service is available at: notification-service:8084"
echo "📧 Email API endpoint: http://notification-service:8084/api/email/send"