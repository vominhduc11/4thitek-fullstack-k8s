# Kubernetes Commands Reference - 4thitek Project

## 📋 Table of Contents
- [Quick Start](#quick-start)
- [Deployment Commands](#deployment-commands)
- [Status Checking](#status-checking)
- [Service Access](#service-access)
- [Troubleshooting](#troubleshooting)
- [Scaling & Management](#scaling--management)
- [Security & Secrets](#security--secrets)
- [Cleanup Commands](#cleanup-commands)

---

## 🚀 Quick Start

### Deploy All Services
```bash
# Deploy entire stack
cd k8s/scripts
./deploy-all.sh

# Or deploy individual services
./deploy-postgres.sh
./deploy-pgbouncer.sh
./deploy-pgadmin.sh
./deploy-kafka.sh
./deploy-redis.sh
./deploy-fe-main.sh
./deploy-fe-admin.sh
./deploy-fe-dealer.sh
```

### Essential RBAC Setup
```bash
# Apply RBAC permissions (run once)
kubectl apply -f k8s/rbac-fix.yaml
```

---

## 📦 Deployment Commands

### Database Services
```bash
# PostgreSQL
kubectl apply -f k8s/database/postgres/postgres-secret.yaml
kubectl apply -f k8s/database/postgres/postgres-configmap.yaml
kubectl apply -f k8s/database/postgres/postgres-pv-pvc.yaml
kubectl apply -f k8s/database/postgres/postgres-deployment.yaml
kubectl apply -f k8s/database/postgres/postgres-service.yaml

# PgBouncer
kubectl apply -f k8s/database/pgbouncer/pgbouncer-secret.yaml
kubectl apply -f k8s/database/pgbouncer/pgbouncer-configmap.yaml
kubectl apply -f k8s/database/pgbouncer/pgbouncer-deployment.yaml
kubectl apply -f k8s/database/pgbouncer/pgbouncer-service.yaml
kubectl apply -f k8s/database/pgbouncer/pgbouncer-hpa.yaml

# pgAdmin
kubectl apply -f k8s/database/pgadmin/pgadmin-secret.yaml
kubectl apply -f k8s/database/pgadmin/pgadmin-pgpass-secret.yaml
kubectl apply -f k8s/database/pgadmin/pgadmin-config.yaml
kubectl apply -f k8s/database/pgadmin/pgadmin-deployment.yaml
kubectl apply -f k8s/database/pgadmin/pgadmin-service.yaml
```

### Cache Services (Redis)
```bash
# Redis Core
kubectl apply -f k8s/cache/redis/redis-secret.yaml
kubectl apply -f k8s/cache/redis/redis-configmap.yaml
kubectl apply -f k8s/cache/redis/redis-pv-pvc.yaml
kubectl apply -f k8s/cache/redis/redis-deployment.yaml
kubectl apply -f k8s/cache/redis/redis-service.yaml

# Redis Management Tools
kubectl apply -f k8s/cache/redis/redis-insight.yaml
kubectl apply -f k8s/cache/redis/redis-commander.yaml
kubectl apply -f k8s/cache/redis/phpredisadmin.yaml
kubectl apply -f k8s/cache/redis/redis-web-simple.yaml
```

### Messaging Services (Kafka)
```bash
# Create Kafka namespace
kubectl apply -f k8s/messaging/namespace.yaml

# Storage
kubectl apply -f k8s/messaging/kafka/local-storage-class.yaml

# Zookeeper
kubectl apply -f k8s/messaging/zookeeper/zookeeper-pvs-statefulset.yaml
kubectl apply -f k8s/messaging/zookeeper/zookeeper-headless-service.yaml
kubectl apply -f k8s/messaging/zookeeper/zookeeper-simple-statefulset.yaml

# Kafka
kubectl apply -f k8s/messaging/kafka/kafka-pvs-statefulset.yaml
kubectl apply -f k8s/messaging/kafka/kafka-additional-pvs.yaml
kubectl apply -f k8s/messaging/kafka/kafka-headless-service.yaml
kubectl apply -f k8s/messaging/kafka/kafka-statefulset.yaml
kubectl apply -f k8s/messaging/kafka/kafka-hpa.yaml

# Kafka UI
kubectl apply -f k8s/messaging/kafka/kafka-ui-secret.yaml
kubectl apply -f k8s/messaging/kafka/kafka-ui-configmap.yaml
kubectl apply -f k8s/messaging/kafka/kafka-ui-deployment.yaml
kubectl apply -f k8s/messaging/kafka/kafka-ui-service.yaml
```

### Frontend Services
```bash
# Main App
kubectl apply -f k8s/frontend/main/fe-main-deployment.yaml
kubectl apply -f k8s/frontend/main/fe-main-service.yaml
kubectl apply -f k8s/frontend/main/fe-main-hpa.yaml

# Admin App
kubectl apply -f k8s/frontend/admin/fe-admin-deployment.yaml
kubectl apply -f k8s/frontend/admin/fe-admin-service.yaml
kubectl apply -f k8s/frontend/admin/fe-admin-hpa.yaml

# Dealer App
kubectl apply -f k8s/frontend/dealer/fe-dealer-deployment.yaml
kubectl apply -f k8s/frontend/dealer/fe-dealer-service.yaml
kubectl apply -f k8s/frontend/dealer/fe-dealer-hpa.yaml
```

---

## 📊 Status Checking

### Basic Status Commands
```bash
# Check all pods in default namespace
kubectl get pods

# Check all pods across all namespaces
kubectl get pods --all-namespaces

# Check Kafka namespace specifically
kubectl get pods -n kafka

# Check services
kubectl get services
kubectl get services -n kafka

# Check deployments
kubectl get deployments
kubectl get deployments -n kafka

# Check persistent volumes
kubectl get pv
kubectl get pvc
kubectl get pvc -n kafka
```

### Detailed Status
```bash
# Check specific pod details
kubectl describe pod <pod-name>
kubectl describe pod <pod-name> -n kafka

# Check logs
kubectl logs <pod-name>
kubectl logs <pod-name> -n kafka
kubectl logs -f <pod-name>  # Follow logs

# Check resource usage (requires metrics-server)
kubectl top pods
kubectl top pods -n kafka
kubectl top nodes
```

### Health Checks
```bash
# Check deployment rollout status
kubectl rollout status deployment/postgres
kubectl rollout status deployment/kafka-ui -n kafka

# Check HPA status
kubectl get hpa
kubectl get hpa -n kafka

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
```

---

## 🌐 Service Access

### Database Access
```bash
# PostgreSQL direct connection
kubectl port-forward service/postgres-service 5432:5432

# PgBouncer connection
kubectl port-forward service/pgbouncer-service 5433:5432

# pgAdmin web interface
kubectl port-forward service/pgadmin-service 8080:80
# Access: http://localhost:8080
# Email: admin@4thitek.com
# Password: Check pgadmin-secret
```

### Redis Access
```bash
# Redis direct connection
kubectl port-forward service/redis-service 6379:6379

# Redis Commander (Web UI)
kubectl port-forward service/redis-commander-service 8081:8081
# Access: http://localhost:8081
# Username: admin, Password: admin123

# Redis Insight
kubectl port-forward service/redis-insight-service 8001:8001
# Access: http://localhost:8001

# Test Redis connection
kubectl exec -it deployment/redis -- redis-cli -a Redis-Secure-2024! ping
```

### Kafka Access
```bash
# Kafka UI
kubectl port-forward service/kafka-ui-service 8080:8080 -n kafka
# Access: http://localhost:8080
# Username: admin, Password: Check kafka-ui-secret

# Kafka brokers (internal access)
# kafka-headless:9092 (from within cluster)

# Zookeeper
# zookeeper-headless:2181 (from within cluster)

# Test Kafka connection
kubectl exec -it kafka-0 -n kafka -- kafka-topics --bootstrap-server localhost:9092 --list
```

### Frontend Access
```bash
# Main App
kubectl port-forward service/fe-main-service 3000:3000
# Access: http://localhost:3000

# Admin App
kubectl port-forward service/fe-admin-service 4000:80
# Access: http://localhost:4000

# Dealer App
kubectl port-forward service/fe-dealer-service 5000:80
# Access: http://localhost:5000
```

### NodePort Access (if available)
```bash
# pgAdmin: http://<node-ip>:30080
# Kafka UI: http://<node-ip>:30090
# Redis External: <node-ip>:30379

# Get node IP
kubectl get nodes -o wide
```

---

## 🔧 Troubleshooting

### Pod Issues
```bash
# Check pod status and events
kubectl describe pod <pod-name>
kubectl get events --field-selector involvedObject.name=<pod-name>

# Check logs
kubectl logs <pod-name>
kubectl logs <pod-name> --previous  # Previous container logs

# Debug pod
kubectl exec -it <pod-name> -- /bin/sh
kubectl exec -it <pod-name> -- /bin/bash
```

### Image Issues
```bash
# Check image pull issues
kubectl describe pod <pod-name> | grep -A 10 "Events:"

# For minikube - load local images
docker build -t <image-name>:<tag> .
minikube image load <image-name>:<tag>

# Check images in minikube
minikube image ls
```

### Service Issues
```bash
# Check service endpoints
kubectl get endpoints
kubectl describe service <service-name>

# Test service connectivity
kubectl run test-pod --image=busybox --restart=Never -- sleep 3600
kubectl exec -it test-pod -- nslookup <service-name>
kubectl exec -it test-pod -- wget -qO- <service-name>:<port>
kubectl delete pod test-pod
```

### Storage Issues
```bash
# Check PV/PVC status
kubectl get pv
kubectl get pvc
kubectl describe pv <pv-name>
kubectl describe pvc <pvc-name>

# Check storage classes
kubectl get storageclass
```

---

## ⚖️ Scaling & Management

### Manual Scaling
```bash
# Scale deployments
kubectl scale deployment postgres --replicas=2
kubectl scale deployment fe-main --replicas=3
kubectl scale statefulset kafka --replicas=4 -n kafka

# Scale down
kubectl scale deployment fe-admin --replicas=1
```

### Auto-scaling (HPA)
```bash
# Check HPA status
kubectl get hpa
kubectl describe hpa <hpa-name>

# Update HPA
kubectl patch hpa fe-main-hpa -p '{"spec":{"maxReplicas":5}}'
```

### Rolling Updates
```bash
# Update image
kubectl set image deployment/fe-main container-name=new-image:tag

# Check rollout status
kubectl rollout status deployment/fe-main

# Rollback
kubectl rollout undo deployment/fe-main
kubectl rollout history deployment/fe-main
```

---

## 🔐 Security & Secrets

### View Secrets
```bash
# List secrets
kubectl get secrets

# View secret details (base64 encoded)
kubectl get secret postgres-secret -o yaml

# Decode secret values
kubectl get secret postgres-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d
```

### Create/Update Secrets
```bash
# Create secret from literal
kubectl create secret generic my-secret --from-literal=key1=value1

# Create secret from file
kubectl create secret generic my-secret --from-file=path/to/file

# Update secret
kubectl patch secret my-secret -p '{"data":{"key1":"<base64-encoded-value>"}}'
```

### Service Accounts & RBAC
```bash
# Check service accounts
kubectl get serviceaccounts

# Check RBAC
kubectl get roles
kubectl get rolebindings
kubectl get clusterroles
kubectl get clusterrolebindings

# Check permissions
kubectl auth can-i create pods
kubectl auth can-i create pods --as=system:serviceaccount:default:default
```

---

## 📋 Monitoring & Logs

### Centralized Logging
```bash
# View logs from multiple pods
kubectl logs -l app=fe-main
kubectl logs -l app=kafka -n kafka

# Follow logs
kubectl logs -f deployment/postgres
kubectl logs -f -l app=kafka -n kafka --max-log-requests=10
```

### Resource Monitoring
```bash
# Node resources
kubectl top nodes

# Pod resources
kubectl top pods
kubectl top pods -n kafka

# Describe resource usage
kubectl describe node <node-name>
```

---

## 🧹 Cleanup Commands

### Delete Specific Resources
```bash
# Delete pods (will be recreated by deployment)
kubectl delete pod <pod-name>
kubectl delete pods -l app=fe-main

# Delete deployments
kubectl delete deployment <deployment-name>
kubectl delete deployment -l app=kafka -n kafka

# Delete services
kubectl delete service <service-name>
kubectl delete services --all

# Delete secrets
kubectl delete secret <secret-name>
```

### Cleanup by Category
```bash
# Clean up frontend
kubectl delete deployments,services,hpa -l tier=frontend

# Clean up database
kubectl delete deployments,services,secrets -l tier=database

# Clean up Kafka namespace
kubectl delete namespace kafka
```

### Complete Cleanup
```bash
# Delete all resources in default namespace (CAREFUL!)
kubectl delete all --all

# Delete all PVCs
kubectl delete pvc --all

# Delete all secrets (except system ones)
kubectl delete secrets --all --dry-run=client  # Test first
kubectl delete secrets --all

# Reset cluster (for minikube)
minikube delete
minikube start
```

---

## 🛠️ Useful Aliases

Add these to your shell profile for convenience:

```bash
# Add to ~/.bashrc or ~/.zshrc
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services' 
alias kgd='kubectl get deployments'
alias kga='kubectl get all'
alias kgpa='kubectl get pods --all-namespaces'
alias kdp='kubectl describe pod'
alias kl='kubectl logs'
alias klf='kubectl logs -f'
alias kex='kubectl exec -it'
alias kaf='kubectl apply -f'
alias kdf='kubectl delete -f'

# Kafka specific
alias kgpk='kubectl get pods -n kafka'
alias klk='kubectl logs -n kafka'
alias kexk='kubectl exec -it -n kafka'
```

---

## 📞 Quick Reference

### Important Service Credentials

**PostgreSQL:**
- Username: `postgres`
- Password: Check `postgres-secret` (PostgreSQL-Strong-P@ss2024!)

**pgAdmin:**
- Email: `admin@4thitek.com`
- Password: Check `pgadmin-secret` (Strong-P@ssw0rd-2024!)

**Redis:**
- Password: `Redis-Secure-2024!`

**Kafka UI:**
- Username: `admin`
- Password: Check `kafka-ui-secret` (Kafka-Admin-2024!)

**Redis Commander:**
- Username: `admin`
- Password: `admin123`

### Default Ports
- PostgreSQL: 5432
- PgBouncer: 5432 (mapped to 6432 in container)
- pgAdmin: 80
- Redis: 6379
- Kafka: 9092
- Zookeeper: 2181
- Frontend apps: 80 or 3000

### Namespaces
- `default`: Database, Cache, Frontend services
- `kafka`: Kafka and Zookeeper services
- `kube-system`: Kubernetes system components

---

## 🆘 Emergency Commands

### Quick Health Check
```bash
# Check if core services are running
kubectl get pods | grep -E "(postgres|redis|fe-)" | grep Running
kubectl get pods -n kafka | grep Running

# Check if services are accessible
kubectl get services
kubectl get endpoints
```

### Emergency Restart
```bash
# Restart specific deployment
kubectl rollout restart deployment/postgres
kubectl rollout restart deployment/kafka-ui -n kafka

# Force pod recreation
kubectl delete pod <pod-name>
```

### Backup Commands
```bash
# Backup PostgreSQL
kubectl exec -it deployment/postgres -- pg_dump -U postgres 4thitek_db > backup.sql

# Backup Redis (if persistence enabled)
kubectl exec -it deployment/redis -- redis-cli -a Redis-Secure-2024! BGSAVE
```

---

**📝 Note:** Always test commands in a development environment before applying to production!

**🔐 Security:** Never commit secrets or sensitive data to version control. Use Kubernetes secrets and proper RBAC!

**📊 Monitoring:** Set up proper monitoring and alerting for production deployments!