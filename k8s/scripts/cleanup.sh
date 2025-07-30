#!/bin/bash

# Cleanup script for all 4thitek deployments
echo "🧹 Cleaning up all 4thitek deployments..."
echo "================================================="

# Function to delete resources safely
delete_resource() {
    local resource_type=$1
    local resource_name=$2
    
    if kubectl get $resource_type $resource_name >/dev/null 2>&1; then
        echo "🗑️  Deleting $resource_type: $resource_name"
        kubectl delete $resource_type $resource_name
    else
        echo "ℹ️  $resource_type $resource_name not found (already deleted)"
    fi
}

# Array of resources to clean up
echo "🔍 Cleaning up frontend applications..."

# Frontend deployments
FRONTEND_APPS=("fe-main" "fe-admin" "fe-dealer")

for app in "${FRONTEND_APPS[@]}"; do
    echo ""
    echo "📱 Cleaning up $app..."
    delete_resource "deployment" "$app"
    delete_resource "service" "$app-service"
    delete_resource "hpa" "$app-hpa"
    delete_resource "ingress" "$app-ingress"
done

echo ""
echo "🗄️  Cleaning up database components..."

# Database components
delete_resource "deployment" "postgres"
delete_resource "service" "postgres-service"
delete_resource "service" "postgres-nodeport"
delete_resource "pvc" "postgres-pvc"
delete_resource "pv" "postgres-pv"
delete_resource "configmap" "postgres-config"

echo ""
echo "🔀 Cleaning up PgBouncer..."

# PgBouncer components
delete_resource "deployment" "pgbouncer"
delete_resource "service" "pgbouncer-service"
delete_resource "service" "pgbouncer-headless"
delete_resource "configmap" "pgbouncer-config"
delete_resource "secret" "pgbouncer-secret"
delete_resource "poddisruptionbudget" "pgbouncer-pdb"
delete_resource "hpa" "pgbouncer-hpa"

echo ""
echo "🖥️  Cleaning up pgAdmin..."

# pgAdmin components
delete_resource "deployment" "pgadmin"
delete_resource "service" "pgadmin-service"
delete_resource "configmap" "pgadmin-config"

echo ""
echo "☕ Cleaning up Kafka Cluster with Auto-Scaling..."

# Auto-scaling components (in kafka namespace)
echo "📈 Cleaning up Auto-Scaling..."
delete_resource "hpa" "kafka-hpa-basic -n kafka"

# Kafka StatefulSet and services (in kafka namespace)
echo "☕ Cleaning up Kafka 3-broker cluster..."
delete_resource "statefulset" "kafka -n kafka"
delete_resource "service" "kafka-headless -n kafka"

# Kafka PVCs and PVs
echo "💾 Cleaning up Kafka storage..."
for i in {0..5}; do
    delete_resource "pvc" "kafka-data-kafka-$i -n kafka"
    delete_resource "pv" "kafka-data-pv-$i"
done

# Zookeeper StatefulSet and services (in kafka namespace)  
echo "🐘 Cleaning up Zookeeper 3-node ensemble..."
delete_resource "statefulset" "zookeeper -n kafka"
delete_resource "service" "zookeeper-headless -n kafka"

# Zookeeper PVCs and PVs
echo "💾 Cleaning up Zookeeper storage..."
for i in {0..2}; do
    delete_resource "pvc" "zookeeper-data-zookeeper-$i -n kafka"
    delete_resource "pvc" "zookeeper-logs-zookeeper-$i -n kafka"
    delete_resource "pv" "zookeeper-data-pv-$i"
    delete_resource "pv" "zookeeper-logs-pv-$i"
done

# Legacy Zookeeper PVs (if any)
delete_resource "pvc" "zookeeper-data-pvc -n kafka"
delete_resource "pvc" "zookeeper-logs-pvc -n kafka"
delete_resource "pv" "zookeeper-data-pv"
delete_resource "pv" "zookeeper-logs-pv"

# Kafka UI components (in kafka namespace)
echo "🖥️  Cleaning up Kafka UI..."
delete_resource "deployment" "kafka-ui -n kafka"
delete_resource "service" "kafka-ui-service -n kafka"
delete_resource "service" "kafka-ui-external-service -n kafka"
delete_resource "configmap" "kafka-ui-config -n kafka"

# Storage class
delete_resource "storageclass" "local-storage"

# Kafka namespace
delete_resource "namespace" "kafka"

echo ""
echo "🔴 Cleaning up Redis and Redis Web Interfaces..."

# Redis components
delete_resource "deployment" "redis"
delete_resource "service" "redis-service"
delete_resource "service" "redis-external-service"
delete_resource "pvc" "redis-data-pvc"
delete_resource "pv" "redis-data-pv"
delete_resource "configmap" "redis-config"

# Redis Web Interfaces
echo "🖥️  Cleaning up Redis web interfaces..."
delete_resource "deployment" "redis-insight"
delete_resource "service" "redis-insight-service"
delete_resource "service" "redis-insight-external"

delete_resource "deployment" "redis-commander"
delete_resource "service" "redis-commander-service"
delete_resource "service" "redis-commander-external"

delete_resource "deployment" "phpredisadmin"
delete_resource "service" "phpredisadmin-service"
delete_resource "service" "phpredisadmin-external"
delete_resource "configmap" "phpredisadmin-config"

echo ""
echo "🔍 Checking for remaining resources..."

# Check for any remaining pods
echo "📋 Remaining pods:"
kubectl get pods

echo ""
echo "📋 Remaining services:"
kubectl get services

echo ""
echo "📋 Remaining deployments:"
kubectl get deployments

# Warning about persistent data
echo ""
echo "⚠️  IMPORTANT NOTES:"
echo "   - Persistent data in /mnt/data/postgres (minikube VM) is preserved"
echo "   - Local data in postgres-data directory is preserved"
echo "   - Kafka broker data in /data/kafka-[0-5]/data (minikube VM) is preserved"
echo "   - Zookeeper ensemble data in /data/zookeeper-[0-2]/* (minikube VM) is preserved"
echo "   - Redis data in /data/redis/data (minikube VM) is preserved"
echo "   - Auto-scaling configuration is removed"
echo "   - Docker images are still available in minikube"
echo "   - ConfigMaps and Secrets are deleted"
echo ""
echo "🔄 To completely clean minikube cluster:"
echo "   minikube delete && minikube start"
echo ""
echo "📊 To clean up metrics-server (if installed):"
echo "   kubectl delete deployment metrics-server -n kube-system"
echo "   kubectl delete apiservice v1beta1.metrics.k8s.io"
echo ""
echo "✅ Cleanup completed!"