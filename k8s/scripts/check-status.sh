#!/bin/bash

# Status check script for all 4thitek deployments
echo "📊 4thitek Kubernetes Cluster Status"
echo "================================================="

# Function to check deployment status
check_deployment() {
    local app_name=$1
    local service_name=$2
    
    echo ""
    echo "🔍 Checking $app_name..."
    echo "----------------------------------------"
    
    # Check if deployment exists
    if kubectl get deployment $app_name >/dev/null 2>&1; then
        # Get deployment status
        local ready=$(kubectl get deployment $app_name -o jsonpath='{.status.readyReplicas}')
        local desired=$(kubectl get deployment $app_name -o jsonpath='{.spec.replicas}')
        
        if [ "$ready" = "$desired" ] && [ ! -z "$ready" ]; then
            echo "✅ Deployment: $app_name ($ready/$desired ready)"
        else
            echo "❌ Deployment: $app_name ($ready/$desired ready)"
        fi
        
        # Show pods
        kubectl get pods -l app=$app_name --no-headers | while read line; do
            echo "   📦 $line"
        done
        
        # Check service
        if kubectl get service $service_name >/dev/null 2>&1; then
            echo "✅ Service: $service_name"
            kubectl get service $service_name --no-headers | while read line; do
                echo "   🌐 $line"
            done
        else
            echo "❌ Service: $service_name (not found)"
        fi
        
    else
        echo "❌ Deployment: $app_name (not found)"
        echo "❌ Service: $service_name (deployment missing)"
    fi
}

# Check minikube status
echo "🖥️  Minikube Status:"
echo "----------------------------------------"
minikube status

echo ""
echo "🎯 Kubernetes Context:"
echo "----------------------------------------"
kubectl config current-context
kubectl get nodes

# Check all applications
check_deployment "postgres" "postgres-service"
check_deployment "pgbouncer" "pgbouncer-service"
check_deployment "pgadmin" "pgadmin-service"
check_deployment "redis" "redis-service"
check_deployment "fe-main" "fe-main-service"
check_deployment "fe-admin" "fe-admin-service"
check_deployment "fe-dealer" "fe-dealer-service"

# Check Kafka namespace applications
echo ""
echo "☕ Kafka Namespace Status:"
echo "----------------------------------------"
kubectl get pods -n kafka 2>/dev/null || echo "❌ Kafka namespace not found"
kubectl get services -n kafka 2>/dev/null || echo "❌ No services in kafka namespace"

# Check persistent volumes
echo ""
echo "💾 Storage Status:"
echo "----------------------------------------"
echo "📋 Persistent Volumes:"
kubectl get pv

echo ""
echo "📋 Persistent Volume Claims:"
kubectl get pvc
echo ""
echo "📋 Kafka Namespace PVCs:"
kubectl get pvc -n kafka 2>/dev/null || echo "   No PVCs in kafka namespace"

# Check HPA status
echo ""
echo "📈 Auto-scaling Status:"
echo "----------------------------------------"
kubectl get hpa
echo ""
echo "📊 PgBouncer HPA Details:"
kubectl get hpa pgbouncer-hpa -o wide 2>/dev/null || echo "   No PgBouncer HPA found"

# Check ingress
echo ""
echo "🌐 Ingress Status:"
echo "----------------------------------------"
kubectl get ingress

# Resource usage summary
echo ""
echo "📊 Resource Usage Summary:"
echo "----------------------------------------"
echo "📋 All Pods:"
kubectl get pods -o wide

echo ""
echo "🔗 Quick Access URLs:"
echo "----------------------------------------"
echo "   📊 pgAdmin:    http://localhost:30080"
echo "   ☕ Kafka:      localhost:30093 (external)"
echo "   🔴 Redis:      localhost:30379 (external)"
echo "   🌐 Main App:   http://main.4thitek.com"
echo "   ⚙️  Admin App:  http://admin.4thitek.com"
echo "   🛒 Dealer App: http://dealer.4thitek.com"

echo ""
echo "🔧 Port-forward Commands:"
echo "----------------------------------------"
echo "   kubectl port-forward service/postgres-service 5432:5432"
echo "   kubectl port-forward service/pgbouncer-service 5432:5432"
echo "   kubectl port-forward service/pgadmin-service 8080:80"
echo "   kubectl port-forward service/kafka-service 9092:9092 -n kafka"
echo "   kubectl port-forward service/zookeeper-service 2181:2181 -n kafka"
echo "   kubectl port-forward service/redis-service 6379:6379"
echo "   kubectl port-forward service/fe-main-service 4000:3000"
echo "   kubectl port-forward service/fe-admin-service 5000:80"
echo "   kubectl port-forward service/fe-dealer-service 6000:80"

echo ""
echo "✅ Status check completed!"