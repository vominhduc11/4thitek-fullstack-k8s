#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Deploy Kafka with Auto-Scaling script
echo "🚀 Deploying Kafka Cluster with Auto-Scaling on Kubernetes..."

# Create namespace
echo "📦 Creating Kafka namespace..."
kubectl apply -f "$K8S_DIR/messaging/namespace.yaml"

# Deploy storage class
echo "💾 Setting up storage class..."
kubectl apply -f "$K8S_DIR/messaging/kafka/local-storage-class.yaml"

# Deploy Zookeeper 3-node ensemble
echo "🐘 Deploying 3-node Zookeeper ensemble..."
kubectl apply -f "$K8S_DIR/messaging/zookeeper/zookeeper-pvs-statefulset.yaml"
kubectl apply -f "$K8S_DIR/messaging/zookeeper/zookeeper-headless-service.yaml"
kubectl apply -f "$K8S_DIR/messaging/zookeeper/zookeeper-simple-statefulset.yaml"

# Wait for Zookeeper ensemble to be ready
echo "⏳ Waiting for Zookeeper ensemble to be ready..."
kubectl wait --for=condition=ready --timeout=600s pod/zookeeper-0 -n kafka
kubectl wait --for=condition=ready --timeout=600s pod/zookeeper-1 -n kafka
kubectl wait --for=condition=ready --timeout=600s pod/zookeeper-2 -n kafka

# Deploy Kafka 3-broker cluster
echo "☕ Deploying 3-broker Kafka cluster..."
kubectl apply -f "$K8S_DIR/messaging/kafka/kafka-pvs-statefulset.yaml"
kubectl apply -f "$K8S_DIR/messaging/kafka/kafka-additional-pvs.yaml"
kubectl apply -f "$K8S_DIR/messaging/kafka/kafka-headless-service.yaml"
kubectl apply -f "$K8S_DIR/messaging/kafka/kafka-statefulset.yaml"

# Wait for Kafka cluster to be ready
echo "⏳ Waiting for Kafka cluster to be ready..."
kubectl wait --for=condition=ready --timeout=600s pod/kafka-0 -n kafka
kubectl wait --for=condition=ready --timeout=600s pod/kafka-1 -n kafka
kubectl wait --for=condition=ready --timeout=600s pod/kafka-2 -n kafka

# Deploy Auto-Scaling (HPA)
echo "📈 Setting up Auto-Scaling..."
kubectl apply -f "$K8S_DIR/messaging/kafka/kafka-hpa.yaml"

# Deploy Kafka UI
echo "🖥️  Deploying Kafka UI..."
kubectl apply -f "$K8S_DIR/messaging/kafka/kafka-ui-secret.yaml"
kubectl apply -f "$K8S_DIR/messaging/kafka/kafka-ui-configmap.yaml"
kubectl apply -f "$K8S_DIR/messaging/kafka/kafka-ui-deployment.yaml"
kubectl apply -f "$K8S_DIR/messaging/kafka/kafka-ui-service.yaml"

# Wait for Kafka UI to be ready
echo "⏳ Waiting for Kafka UI to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/kafka-ui -n kafka

echo "✅ Kafka cluster deployment completed!"
echo ""
echo "📋 Cluster Information:"
echo "  🔢 Kafka Brokers: 3 (kafka-0, kafka-1, kafka-2)"
echo "  🔢 Zookeeper Nodes: 3 (zookeeper-0, zookeeper-1, zookeeper-2)"
echo "  📈 Auto-Scaling: 3-6 brokers (CPU threshold: 5%)"
echo "  💾 Storage: 20GB per Kafka broker, 10GB+5GB per Zookeeper node"
echo ""
echo "🌐 Service Access:"
echo "  Kafka Internal: kafka-headless:9092 (within cluster)"
echo "  Zookeeper Internal: zookeeper-headless:2181 (within cluster)"
echo "  Kafka UI: http://localhost:30090"
echo "    🔐 Username: admin"
echo "    🔐 Password: Stored in kafka-ui-secret (Kafka-Admin-2024!)"
echo ""
echo "ℹ️  Note: Kafka UI credentials are now stored in Kubernetes Secret for security"
echo ""
echo "🔍 Monitor deployment:"
echo "  kubectl get pods -n kafka"
echo "  kubectl get statefulset -n kafka"
echo "  kubectl get hpa -n kafka"
echo "  kubectl top pods -n kafka"
echo ""
echo "⚡ Scale manually (if needed):"
echo "  kubectl scale statefulset kafka --replicas=N -n kafka"