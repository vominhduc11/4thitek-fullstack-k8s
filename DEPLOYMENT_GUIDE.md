# 🚀 Deployment Guide - 4thitek Kubernetes Platform

## 📋 Table of Contents
- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
- [Deployment Methods](#deployment-methods)
- [Step-by-Step Deployment](#step-by-step-deployment)
- [Post-Deployment Verification](#post-deployment-verification)
- [Production Deployment](#production-deployment)
- [Scaling Configuration](#scaling-configuration)
- [Maintenance Procedures](#maintenance-procedures)

---

## ✅ Prerequisites

### **System Requirements**
- **Kubernetes Cluster**: v1.30+ (tested on v1.33.1)
- **kubectl**: Configured and connected to your cluster
- **Docker**: For building custom frontend images
- **Minimum Resources**: 8GB RAM, 4 CPU cores across cluster
- **Storage**: 50GB+ available for persistent volumes

### **Cluster Requirements**
- **Nodes**: Minimum 1 node (recommended: 3+ nodes)
- **Node Labels**: For optimal pod distribution
- **Storage Class**: Default or configured storage class
- **Network**: CNI plugin configured (Flannel, Calico, etc.)
- **DNS**: CoreDNS or equivalent

### **Tools & Access**
```bash
# Verify prerequisites
kubectl version --client
kubectl cluster-info
docker --version
git --version

# Check cluster access
kubectl get nodes
kubectl get storageclass
```

---

## 🏗️ Environment Setup

### **Development Environment (Minikube)**
```bash
# Start minikube with multiple nodes
minikube start --nodes 4 --cpus 2 --memory 4g --disk-size 20g

# Enable required addons
minikube addons enable metrics-server
minikube addons enable ingress
minikube addons enable storage-provisioner

# Verify cluster
kubectl get nodes
minikube status
```

### **Production Environment**
```bash
# Verify production cluster
kubectl get nodes -o wide
kubectl get storageclass
kubectl top nodes

# Check resource availability
kubectl describe nodes | grep -A 5 "Allocated resources"
```

### **Local Development Setup**
```bash
# Clone repository
git clone <repository-url>
cd 4thitek

# Set up development tools
export KUBECONFIG=~/.kube/config
export PATH=$PATH:./k8s/scripts

# Make scripts executable
chmod +x k8s/scripts/*.sh
```

---

## 🎯 Deployment Methods

### **Method 1: Automated Deployment (Recommended)**
```bash
# One-command deployment
cd k8s/scripts
./deploy-all.sh
```

### **Method 2: Service-by-Service Deployment**
```bash
# Deploy in dependency order
./deploy-postgres.sh      # Database first
./deploy-redis.sh         # Cache layer
./deploy-kafka.sh         # Message broker
./deploy-fe-main.sh       # Frontend applications
./deploy-fe-admin.sh
./deploy-fe-dealer.sh
```

### **Method 3: Manual YAML Deployment**
```bash
# Apply manifests manually
kubectl apply -f k8s/database/
kubectl apply -f k8s/cache/
kubectl apply -f k8s/messaging/
kubectl apply -f k8s/frontend/
```

---

## 📝 Step-by-Step Deployment

### **Step 1: Prepare Cluster**
```bash
# Apply RBAC permissions (required)
kubectl apply -f k8s/rbac-fix.yaml

# Verify RBAC
kubectl auth can-i create pods
kubectl auth can-i create services
```

### **Step 2: Deploy Database Layer**
```bash
# PostgreSQL with high availability
echo "🗄️ Deploying Database Layer..."

# Create secrets first
kubectl apply -f k8s/database/postgres/postgres-secret.yaml

# Deploy PostgreSQL
kubectl apply -f k8s/database/postgres/postgres-configmap.yaml
kubectl apply -f k8s/database/postgres/postgres-pv-pvc.yaml
kubectl apply -f k8s/database/postgres/postgres-deployment.yaml
kubectl apply -f k8s/database/postgres/postgres-service.yaml

# Wait for PostgreSQL to be ready
kubectl wait --for=condition=ready pod -l app=postgres --timeout=300s

# Deploy pgBouncer (connection pooling)
kubectl apply -f k8s/database/pgbouncer/pgbouncer-secret.yaml
kubectl apply -f k8s/database/pgbouncer/pgbouncer-configmap.yaml
kubectl apply -f k8s/database/pgbouncer/pgbouncer-deployment.yaml
kubectl apply -f k8s/database/pgbouncer/pgbouncer-service.yaml
kubectl apply -f k8s/database/pgbouncer/pgbouncer-hpa.yaml

# Deploy pgAdmin (database management)
kubectl apply -f k8s/database/pgadmin/pgadmin-secret.yaml
kubectl apply -f k8s/database/pgadmin/pgadmin-pgpass-secret.yaml
kubectl apply -f k8s/database/pgadmin/pgadmin-config.yaml
kubectl apply -f k8s/database/pgadmin/pgadmin-deployment.yaml
kubectl apply -f k8s/database/pgadmin/pgadmin-service.yaml

# Verify database layer
kubectl get pods | grep -E "(postgres|pgbouncer|pgadmin)"
echo "✅ Database layer deployed"
```

### **Step 3: Deploy Cache Layer**
```bash
echo "🚀 Deploying Cache Layer..."

# Deploy Redis
kubectl apply -f k8s/cache/redis/redis-secret.yaml
kubectl apply -f k8s/cache/redis/redis-configmap.yaml
kubectl apply -f k8s/cache/redis/redis-pv-pvc.yaml
kubectl apply -f k8s/cache/redis/redis-deployment.yaml
kubectl apply -f k8s/cache/redis/redis-service.yaml

# Wait for Redis to be ready
kubectl wait --for=condition=ready pod -l app=redis --timeout=300s

# Deploy Redis management tools
kubectl apply -f k8s/cache/redis/redis-insight.yaml
kubectl apply -f k8s/cache/redis/redis-commander.yaml
kubectl apply -f k8s/cache/redis/phpredisadmin.yaml
kubectl apply -f k8s/cache/redis/redis-web-simple.yaml

# Verify cache layer
kubectl get pods | grep redis
echo "✅ Cache layer deployed"
```

### **Step 4: Deploy Messaging Layer**
```bash
echo "📨 Deploying Messaging Layer..."

# Create Kafka namespace
kubectl apply -f k8s/messaging/namespace.yaml

# Deploy storage class
kubectl apply -f k8s/messaging/kafka/local-storage-class.yaml

# Deploy Zookeeper ensemble (3 nodes)
kubectl apply -f k8s/messaging/zookeeper/zookeeper-pvs-statefulset.yaml
kubectl apply -f k8s/messaging/zookeeper/zookeeper-headless-service.yaml
kubectl apply -f k8s/messaging/zookeeper/zookeeper-simple-statefulset.yaml

# Wait for Zookeeper ensemble
echo "⏳ Waiting for Zookeeper ensemble..."
kubectl wait --for=condition=ready pod/zookeeper-0 -n kafka --timeout=600s
kubectl wait --for=condition=ready pod/zookeeper-1 -n kafka --timeout=600s
kubectl wait --for=condition=ready pod/zookeeper-2 -n kafka --timeout=600s

# Deploy Kafka cluster (3 brokers)
kubectl apply -f k8s/messaging/kafka/kafka-pvs-statefulset.yaml
kubectl apply -f k8s/messaging/kafka/kafka-additional-pvs.yaml
kubectl apply -f k8s/messaging/kafka/kafka-headless-service.yaml
kubectl apply -f k8s/messaging/kafka/kafka-statefulset.yaml

# Wait for Kafka cluster
echo "⏳ Waiting for Kafka cluster..."
kubectl wait --for=condition=ready pod/kafka-0 -n kafka --timeout=600s
kubectl wait --for=condition=ready pod/kafka-1 -n kafka --timeout=600s
kubectl wait --for=condition=ready pod/kafka-2 -n kafka --timeout=600s

# Deploy Kafka UI
kubectl apply -f k8s/messaging/kafka/kafka-ui-secret.yaml
kubectl apply -f k8s/messaging/kafka/kafka-ui-configmap.yaml
kubectl apply -f k8s/messaging/kafka/kafka-ui-deployment.yaml
kubectl apply -f k8s/messaging/kafka/kafka-ui-service.yaml

# Deploy auto-scaling
kubectl apply -f k8s/messaging/kafka/kafka-hpa.yaml

# Verify messaging layer
kubectl get pods -n kafka
echo "✅ Messaging layer deployed"
```

### **Step 5: Deploy Frontend Layer**
```bash
echo "🌐 Deploying Frontend Layer..."

# Build frontend images (if needed)
echo "📦 Building frontend images..."
cd fe/main && docker build -t fe-main:v1.0.0 . && cd ../..
cd fe/admin && docker build -t fe-admin:v1.0.0 . && cd ../..
cd fe/dealer && docker build -t fe-dealer:v1.0.0 . && cd ../..

# Load images to minikube (development)
if command -v minikube &> /dev/null; then
    minikube image load fe-main:v1.0.0
    minikube image load fe-admin:v1.0.0
    minikube image load fe-dealer:v1.0.0
fi

# Deploy main application
kubectl apply -f k8s/frontend/main/fe-main-deployment.yaml
kubectl apply -f k8s/frontend/main/fe-main-service.yaml
kubectl apply -f k8s/frontend/main/fe-main-hpa.yaml

# Deploy admin portal
kubectl apply -f k8s/frontend/admin/fe-admin-deployment.yaml
kubectl apply -f k8s/frontend/admin/fe-admin-service.yaml
kubectl apply -f k8s/frontend/admin/fe-admin-hpa.yaml

# Deploy dealer portal
kubectl apply -f k8s/frontend/dealer/fe-dealer-deployment.yaml
kubectl apply -f k8s/frontend/dealer/fe-dealer-service.yaml
kubectl apply -f k8s/frontend/dealer/fe-dealer-hpa.yaml

# Wait for frontend deployments
kubectl wait --for=condition=available deployment/fe-main --timeout=300s
kubectl wait --for=condition=available deployment/fe-admin --timeout=300s
kubectl wait --for=condition=available deployment/fe-dealer --timeout=300s

# Verify frontend layer
kubectl get pods | grep fe-
echo "✅ Frontend layer deployed"
```

### **Step 6: Final Verification**
```bash
echo "🔍 Final deployment verification..."

# Check all pods
kubectl get pods
kubectl get pods -n kafka

# Check services
kubectl get services
kubectl get services -n kafka

# Check HPAs
kubectl get hpa
kubectl get hpa -n kafka

# Check resource usage
kubectl top nodes
kubectl top pods

echo "🎉 Deployment completed successfully!"
```

---

## ✅ Post-Deployment Verification

### **Health Checks**
```bash
# Comprehensive health check script
#!/bin/bash
echo "🩺 Running health checks..."

# Database layer
echo "Database Layer:"
kubectl get pods | grep -E "(postgres|pgbouncer|pgadmin)" | grep Running
kubectl exec -it deployment/postgres -- pg_isready -U postgres

# Cache layer
echo "Cache Layer:"
kubectl get pods | grep redis | grep Running
kubectl exec -it deployment/redis -- redis-cli -a Redis-Secure-2024! ping

# Messaging layer
echo "Messaging Layer:"
kubectl get pods -n kafka | grep Running
kubectl exec -it kafka-0 -n kafka -- kafka-topics --bootstrap-server localhost:9092 --list

# Frontend layer
echo "Frontend Layer:"
kubectl get pods | grep fe- | grep Running

echo "✅ Health checks completed"
```

### **Connectivity Tests**
```bash
# Test service connectivity
kubectl run test-connectivity --image=busybox --restart=Never -- sleep 3600

# Test database connectivity
kubectl exec -it test-connectivity -- nslookup postgres-service
kubectl exec -it test-connectivity -- nc -zv postgres-service 5432

# Test Redis connectivity
kubectl exec -it test-connectivity -- nslookup redis-service
kubectl exec -it test-connectivity -- nc -zv redis-service 6379

# Test Kafka connectivity
kubectl exec -it test-connectivity -- nslookup kafka-headless.kafka.svc.cluster.local

# Cleanup
kubectl delete pod test-connectivity
```

### **Access Verification**
```bash
# Create access tunnels for testing
kubectl port-forward service/pgadmin-service 8080:80 &
kubectl port-forward service/kafka-ui-service 8081:8080 -n kafka &
kubectl port-forward service/fe-main-service 3000:3000 &

echo "🌐 Test URLs:"
echo "pgAdmin: http://localhost:8080"
echo "Kafka UI: http://localhost:8081"
echo "Main App: http://localhost:3000"

# Kill port-forwards after testing
# pkill -f "kubectl port-forward"
```

---

## 🌟 Production Deployment

### **Production Checklist**
```bash
# Pre-deployment checklist
echo "📋 Production deployment checklist:"
echo "[ ] Cluster resources verified (CPU, Memory, Storage)"
echo "[ ] Backup procedures tested"
echo "[ ] Monitoring configured"
echo "[ ] SSL/TLS certificates ready"
echo "[ ] DNS records configured"
echo "[ ] Load balancers configured"
echo "[ ] Security scanning completed"
echo "[ ] Performance testing completed"
```

### **Production Configuration Changes**
```bash
# Update resource requests and limits for production
kubectl patch deployment postgres -p '{"spec":{"template":{"spec":{"containers":[{"name":"postgres","resources":{"requests":{"memory":"1Gi","cpu":"500m"},"limits":{"memory":"2Gi","cpu":"1"}}}]}}}}'

kubectl patch deployment redis -p '{"spec":{"template":{"spec":{"containers":[{"name":"redis","resources":{"requests":{"memory":"512Mi","cpu":"250m"},"limits":{"memory":"1Gi","cpu":"500m"}}}]}}}}'

# Update replica counts for production
kubectl scale deployment fe-main --replicas=3
kubectl scale deployment fe-admin --replicas=2
kubectl scale deployment fe-dealer --replicas=2
kubectl scale deployment pgbouncer --replicas=3

# Update HPA for production loads
kubectl patch hpa fe-main-hpa -p '{"spec":{"maxReplicas":10,"targetCPUUtilizationPercentage":70}}'
```

### **SSL/TLS Configuration**
```bash
# Install cert-manager (for automatic SSL)
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Configure ingress with TLS
kubectl apply -f k8s/ingress/production-ingress.yaml
```

### **Monitoring Setup**
```bash
# Deploy monitoring stack (example with Prometheus)
kubectl create namespace monitoring
kubectl apply -f k8s/monitoring/prometheus/
kubectl apply -f k8s/monitoring/grafana/

# Configure alerts
kubectl apply -f k8s/monitoring/alerts/
```

---

## ⚖️ Scaling Configuration

### **Horizontal Pod Autoscaling (HPA)**
```bash
# Configure HPA for different workloads
# Frontend applications
kubectl autoscale deployment fe-main --cpu-percent=70 --min=2 --max=10
kubectl autoscale deployment fe-admin --cpu-percent=70 --min=1 --max=5
kubectl autoscale deployment fe-dealer --cpu-percent=70 --min=1 --max=5

# Database connection pooling
kubectl autoscale deployment pgbouncer --cpu-percent=80 --min=2 --max=5

# Kafka brokers (manual scaling recommended)
# kubectl scale statefulset kafka --replicas=5 -n kafka
```

### **Vertical Pod Autoscaling (VPA)**
```bash
# Install VPA (if needed)
git clone https://github.com/kubernetes/autoscaler.git
cd autoscaler/vertical-pod-autoscaler/
./hack/vpa-up.sh

# Configure VPA for database
kubectl apply -f - <<EOF
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: postgres-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: postgres
  updatePolicy:
    updateMode: "Auto"
EOF
```

### **Cluster Autoscaling**
```bash
# For cloud providers, configure cluster autoscaler
# Example for AWS EKS:
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml

# Configure cluster autoscaler
kubectl patch deployment cluster-autoscaler -n kube-system -p '{"spec":{"template":{"metadata":{"annotations":{"cluster-autoscaler.kubernetes.io/safe-to-evict":"false"}}}}}'
```

---

## 🔧 Maintenance Procedures

### **Regular Maintenance Tasks**

#### **Daily Checks**
```bash
#!/bin/bash
# daily-check.sh
echo "📅 Daily maintenance check - $(date)"

# Check cluster health
kubectl get nodes
kubectl get pods --all-namespaces | grep -v Running

# Check resource usage
kubectl top nodes
kubectl top pods | head -10

# Check recent events
kubectl get events --sort-by=.metadata.creationTimestamp | tail -20

# Check backups (customize based on your backup solution)
# ./check-backups.sh
```

#### **Weekly Maintenance**
```bash
#!/bin/bash
# weekly-maintenance.sh
echo "📅 Weekly maintenance - $(date)"

# Update deployments (rolling update)
kubectl rollout restart deployment/fe-main
kubectl rollout restart deployment/fe-admin
kubectl rollout restart deployment/fe-dealer

# Clean up unused images (minikube)
if command -v minikube &> /dev/null; then
    minikube image rm --all
fi

# Check and clean up completed pods
kubectl delete pods --field-selector=status.phase=Succeeded --all-namespaces

# Review resource quotas and limits
kubectl describe resourcequota --all-namespaces
```

### **Backup Procedures**
```bash
#!/bin/bash
# backup.sh
BACKUP_DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="backups/$BACKUP_DATE"
mkdir -p $BACKUP_DIR

echo "💾 Creating backups - $BACKUP_DATE"

# Database backup
kubectl exec -it deployment/postgres -- pg_dump -U postgres 4thitek_db > $BACKUP_DIR/database-backup.sql

# Redis backup (if persistence enabled)
kubectl exec -it deployment/redis -- redis-cli -a Redis-Secure-2024! BGSAVE
kubectl exec -it deployment/redis -- cat /data/dump.rdb > $BACKUP_DIR/redis-backup.rdb

# Configuration backup
kubectl get all -o yaml > $BACKUP_DIR/cluster-config.yaml
kubectl get secrets -o yaml > $BACKUP_DIR/secrets-backup.yaml
kubectl get configmaps -o yaml > $BACKUP_DIR/configmaps-backup.yaml

# Kafka topic backup (if needed)
# kubectl exec -it kafka-0 -n kafka -- kafka-topics --bootstrap-server localhost:9092 --list > $BACKUP_DIR/kafka-topics.txt

echo "✅ Backup completed in $BACKUP_DIR"
```

### **Update Procedures**
```bash
#!/bin/bash
# update-application.sh
APP_NAME=$1
NEW_VERSION=$2

if [ -z "$APP_NAME" ] || [ -z "$NEW_VERSION" ]; then
    echo "Usage: $0 <app-name> <new-version>"
    echo "Example: $0 fe-main v2.0.0"
    exit 1
fi

echo "🔄 Updating $APP_NAME to $NEW_VERSION"

# Build new image
cd fe/$APP_NAME
docker build -t $APP_NAME:$NEW_VERSION .

# Load to minikube (development)
if command -v minikube &> /dev/null; then
    minikube image load $APP_NAME:$NEW_VERSION
fi

# Update deployment
kubectl set image deployment/$APP_NAME $APP_NAME=$APP_NAME:$NEW_VERSION

# Monitor rollout
kubectl rollout status deployment/$APP_NAME

# Verify update
kubectl get pods -l app=$APP_NAME

echo "✅ Update completed"
```

---

## 📊 Monitoring & Alerts

### **Basic Monitoring Setup**
```bash
# Monitor cluster resources
watch kubectl top nodes
watch kubectl top pods

# Monitor specific services
watch kubectl get pods | grep -E "(postgres|redis|kafka)"

# Monitor scaling
watch kubectl get hpa
```

### **Log Aggregation**
```bash
# Collect logs from all services
kubectl logs -f deployment/postgres > logs/postgres.log &
kubectl logs -f deployment/redis > logs/redis.log &
kubectl logs -f deployment/fe-main > logs/fe-main.log &
kubectl logs -f kafka-0 -n kafka > logs/kafka.log &

# Centralized logging with stern (if installed)
# stern . --all-namespaces
```

---

## 🆘 Rollback Procedures

### **Application Rollback**
```bash
#!/bin/bash
# rollback.sh
APP_NAME=$1
REVISION=$2

echo "⏪ Rolling back $APP_NAME"

# Check rollout history
kubectl rollout history deployment/$APP_NAME

# Rollback to previous version
if [ -z "$REVISION" ]; then
    kubectl rollout undo deployment/$APP_NAME
else
    kubectl rollout undo deployment/$APP_NAME --to-revision=$REVISION
fi

# Monitor rollback
kubectl rollout status deployment/$APP_NAME

echo "✅ Rollback completed"
```

### **Complete System Rollback**
```bash
#!/bin/bash
# emergency-rollback.sh
echo "🚨 EMERGENCY ROLLBACK - This will rollback all deployments"
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" = "yes" ]; then
    # Rollback all deployments
    kubectl rollout undo deployment/fe-main
    kubectl rollout undo deployment/fe-admin
    kubectl rollout undo deployment/fe-dealer
    kubectl rollout undo deployment/postgres
    kubectl rollout undo deployment/redis
    kubectl rollout undo deployment/kafka-ui -n kafka
    
    echo "✅ Emergency rollback completed"
else
    echo "❌ Rollback cancelled"
fi
```

---

**🎯 Deployment completed! Your 4thitek platform is now running on Kubernetes.**

**📚 Next Steps:**
- Review [ACCESS_CREDENTIALS.md](./ACCESS_CREDENTIALS.md) for login information
- Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) if you encounter issues
- Set up monitoring and alerting for production use