#!/bin/bash

# Check Kafka Auto-Scaling Status
echo "📊 Kafka Auto-Scaling Status Check"
echo "=================================="

# Check if Kafka namespace exists
if ! kubectl get namespace kafka >/dev/null 2>&1; then
    echo "❌ Kafka namespace not found. Deploy Kafka first."
    exit 1
fi

echo ""
echo "🔢 Kafka Cluster Status:"
echo "========================"

# Check StatefulSets
echo "📦 StatefulSets:"
kubectl get statefulset -n kafka -o wide

echo ""
echo "🚀 Pods Status:"
kubectl get pods -n kafka -o wide

echo ""
echo "📈 Auto-Scaling Status:"
echo "======================="

# Check HPA
if kubectl get hpa kafka-hpa-basic -n kafka >/dev/null 2>&1; then
    echo "✅ HPA is active:"
    kubectl get hpa kafka-hpa-basic -n kafka
    echo ""
    echo "📊 HPA Details:"
    kubectl describe hpa kafka-hpa-basic -n kafka | grep -A 10 -B 5 "Targets\|Events"
else
    echo "❌ HPA not found"
fi

echo ""
echo "💾 Storage Status:"
echo "=================="

# Check PVs
echo "📂 Persistent Volumes:"
kubectl get pv | grep -E "(kafka|zookeeper)" | sort

echo ""
echo "📁 Persistent Volume Claims:"
kubectl get pvc -n kafka | sort

echo ""
echo "🖥️  Services:"
echo "============="
kubectl get svc -n kafka

echo ""
echo "⚡ Resource Usage:"
echo "================="

# Check resource usage
if kubectl top pods -n kafka >/dev/null 2>&1; then
    echo "📊 Current Resource Usage:"
    kubectl top pods -n kafka
else
    echo "⚠️  Metrics not available (metrics-server might not be installed)"
fi

echo ""
echo "🔧 Scaling Commands:"
echo "==================="
echo "Manual scale up:   kubectl scale statefulset kafka --replicas=4 -n kafka"
echo "Manual scale down: kubectl scale statefulset kafka --replicas=3 -n kafka"
echo "Watch scaling:     kubectl get pods -n kafka -w"
echo "Check HPA:         kubectl get hpa -n kafka -w"

echo ""
echo "🌐 Access Information:"
echo "======================"
echo "Kafka UI:     http://localhost:30090 (admin/admin123)"
echo "Internal:     kafka-headless:9092 (from within cluster)"
echo "Zookeeper:    zookeeper-headless:2181 (from within cluster)"

echo ""
echo "✅ Status check completed!"