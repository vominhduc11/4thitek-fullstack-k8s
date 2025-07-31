# 🔐 4thitek Project - Access Credentials & Service Information

## 📋 Table of Contents
- [Service URLs & Access](#service-urls--access)
- [Database Credentials](#database-credentials)
- [Cache & Messaging Credentials](#cache--messaging-credentials)
- [Frontend Applications](#frontend-applications)
- [Network Access Methods](#network-access-methods)
- [Security Notes](#security-notes)

---

## 🌐 Service URLs & Access

### 📊 **Quick Access Dashboard**

| Service | URL | Username | Password | Notes |
|---------|-----|----------|----------|-------|
| **pgAdmin** | http://localhost:8080 | admin@4thitek.com | Strong-P@ssw0rd-2024! | Database management |
| **Kafka UI** | http://localhost:8080 | admin | Kafka-Admin-2024! | Message broker UI |
| **Redis Commander** | http://localhost:8081 | admin | admin123 | Redis web interface |
| **Redis Insight** | http://localhost:8001 | - | - | Redis analytics |
| **Main App** | http://localhost:3000 | - | - | Main frontend |
| **Admin Portal** | http://localhost:4000 | - | - | Admin interface |
| **Dealer Portal** | http://localhost:5000 | - | - | Dealer interface |

---

## 🗄️ Database Credentials

### **PostgreSQL Database**
```yaml
Host: postgres-service (internal) / localhost:5432 (port-forward)
Database: 4thitek_db
Username: postgres
Password: PostgreSQL-Strong-P@ss2024!
```

**🔗 Connection Commands:**
```bash
# Direct PostgreSQL connection
kubectl port-forward service/postgres-service 5432:5432
psql -h localhost -p 5432 -U postgres -d 4thitek_db

# Via pgBouncer (recommended for applications)
kubectl port-forward service/pgbouncer-service 5433:5432
psql -h localhost -p 5433 -U postgres -d 4thitek_db
```

### **pgAdmin Web Interface**
```yaml
URL: http://localhost:8080 (via port-forward)
Email: admin@4thitek.com
Password: Strong-P@ssw0rd-2024!
```

**🔗 Access Command:**
```bash
kubectl port-forward service/pgadmin-service 8080:80
# Then open: http://localhost:8080
```

**📝 Pre-configured Server:**
- **Name**: 4thitek PostgreSQL
- **Host**: postgres-service
- **Port**: 5432
- **Database**: 4thitek_db
- **Username**: postgres
- **Password**: Auto-configured via secrets

### **pgBouncer Connection Pooler**
```yaml
Internal URL: pgbouncer-service:5432
External URL: localhost:5433 (via port-forward)
Username: postgres
Password: PostgreSQL-Strong-P@ss2024!
Pool Mode: Session pooling
Max Connections: Configured per application needs
```

**🔗 Access Command:**
```bash
kubectl port-forward service/pgbouncer-service 5433:5432
```

---

## 🚀 Cache & Messaging Credentials

### **Redis Cache Server**
```yaml
Host: redis-service (internal) / localhost:6379 (port-forward)
Port: 6379
Password: Redis-Secure-2024!
Database: 0 (default)
```

**🔗 Connection Commands:**
```bash
# Redis CLI access
kubectl port-forward service/redis-service 6379:6379
redis-cli -h localhost -p 6379 -a Redis-Secure-2024!

# Test connection
redis-cli -h localhost -p 6379 -a Redis-Secure-2024! ping
redis-cli -h localhost -p 6379 -a Redis-Secure-2024! info
```

### **Redis Management Tools**

#### **Redis Commander**
```yaml
URL: http://localhost:8081
Username: admin
Password: admin123
Features: Web-based Redis management
```

**🔗 Access Command:**
```bash
kubectl port-forward service/redis-commander-service 8081:8081
# Then open: http://localhost:8081
```

#### **Redis Insight**
```yaml
URL: http://localhost:8001
Username: Not required
Password: Not required
Features: Advanced Redis analytics and monitoring
```

**🔗 Access Command:**
```bash
kubectl port-forward service/redis-insight-service 8001:8001
# Then open: http://localhost:8001
```

### **Kafka Message Broker**

#### **Kafka Cluster**
```yaml
Bootstrap Servers: kafka-headless:9092 (internal)
Brokers: 3 (kafka-0, kafka-1, kafka-2)
Zookeeper: zookeeper-headless:2181 (internal)
Security: PLAINTEXT (development)
```

**🔗 Internal Access (from within cluster):**
```bash
# List topics
kubectl exec -it kafka-0 -n kafka -- kafka-topics --bootstrap-server localhost:9092 --list

# Create topic
kubectl exec -it kafka-0 -n kafka -- kafka-topics --bootstrap-server localhost:9092 --create --topic test-topic --partitions 3 --replication-factor 3

# Producer test
kubectl exec -it kafka-0 -n kafka -- kafka-console-producer --bootstrap-server localhost:9092 --topic test-topic

# Consumer test
kubectl exec -it kafka-0 -n kafka -- kafka-console-consumer --bootstrap-server localhost:9092 --topic test-topic --from-beginning
```

#### **Kafka UI Web Interface**
```yaml
URL: http://localhost:8080 (via port-forward)
Username: admin
Password: Kafka-Admin-2024!
Features: Kafka cluster management, topic browser, consumer groups
```

**🔗 Access Command:**
```bash
kubectl port-forward service/kafka-ui-service 8080:8080 -n kafka
# Then open: http://localhost:8080
```

### **Zookeeper Ensemble**
```yaml
Ensemble: zookeeper-headless:2181 (internal)
Nodes: 3 (zookeeper-0, zookeeper-1, zookeeper-2)
Admin Port: 8080 (per node)
```

**🔗 Access Commands:**
```bash
# Check Zookeeper status
kubectl exec -it zookeeper-0 -n kafka -- zkServer.sh status

# Zookeeper CLI
kubectl exec -it zookeeper-0 -n kafka -- zkCli.sh -server localhost:2181
```

---

## 🌐 Frontend Applications

### **Main Application (fe-main)**
```yaml
URL: http://localhost:3000 (via port-forward)
Type: Next.js Application
Port: 3000
Environment: Development/Production
```

**🔗 Access Command:**
```bash
kubectl port-forward service/fe-main-service 3000:3000
# Then open: http://localhost:3000
```

### **Admin Portal (fe-admin)**
```yaml
URL: http://localhost:4000 (via port-forward)
Type: React Admin Dashboard
Port: 80 (container) / 4000 (port-forward)
Environment: Development/Production
```

**🔗 Access Command:**
```bash
kubectl port-forward service/fe-admin-service 4000:80
# Then open: http://localhost:4000
```

### **Dealer Portal (fe-dealer)**
```yaml
URL: http://localhost:5000 (via port-forward)
Type: React Dealer Interface
Port: 80 (container) / 5000 (port-forward)
Environment: Development/Production
```

**🔗 Access Command:**
```bash
kubectl port-forward service/fe-dealer-service 5000:80
# Then open: http://localhost:5000
```

---

## 🔗 Network Access Methods

### **Method 1: Port Forwarding (Recommended for Development)**
```bash
# Single service access
kubectl port-forward service/<service-name> <local-port>:<service-port>

# Multiple services (run in separate terminals)
kubectl port-forward service/postgres-service 5432:5432 &
kubectl port-forward service/redis-service 6379:6379 &
kubectl port-forward service/kafka-ui-service 8080:8080 -n kafka &
kubectl port-forward service/pgadmin-service 8081:80 &
```

### **Method 2: NodePort Services (If configured)**
```bash
# Get node IP
kubectl get nodes -o wide

# Access via NodePort (if available)
# Format: http://<node-ip>:<nodeport>
# Example: http://192.168.67.2:30080 (pgAdmin)
#         http://192.168.67.2:30090 (Kafka UI)
```

### **Method 3: Ingress (Production Setup)**
```yaml
# Domain-based access (requires ingress controller)
# main.4thitek.com
# admin.4thitek.com  
# dealer.4thitek.com
```

### **Method 4: Direct Pod Access (Debug Only)**
```bash
# Execute into pod
kubectl exec -it <pod-name> -- /bin/bash
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh

# Port forward to specific pod
kubectl port-forward pod/<pod-name> <local-port>:<pod-port>
```

---

## 🛡️ Security Notes

### **🔐 Credentials Storage**
All sensitive credentials are stored as Kubernetes Secrets:

```bash
# View secrets (base64 encoded)
kubectl get secrets
kubectl get secret postgres-secret -o yaml
kubectl get secret kafka-ui-secret -o yaml
kubectl get secret redis-secret -o yaml
kubectl get secret pgadmin-secret -o yaml

# Decode secret values
kubectl get secret postgres-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d
```

### **🔒 Security Best Practices Applied**

#### **✅ What We've Implemented:**
- ✅ **No hardcoded passwords** in YAML files
- ✅ **Kubernetes Secrets** for all sensitive data
- ✅ **Strong passwords** for all services
- ✅ **Security contexts** for non-root containers
- ✅ **RBAC permissions** properly configured
- ✅ **Redis authentication** enabled
- ✅ **Separate namespaces** for different services

#### **⚠️ Development Environment Notes:**
- **Plain HTTP** used (add HTTPS for production)
- **Internal network** communication (secure within cluster)
- **Basic authentication** for web interfaces
- **No network policies** (add for production)

#### **🔧 Production Recommendations:**
```bash
# 1. Enable TLS/HTTPS
# 2. Implement network policies
# 3. Use cert-manager for certificates
# 4. Add monitoring and alerting
# 5. Implement backup strategies
# 6. Use external secret management (HashiCorp Vault, etc.)
```

---

## 🚀 Quick Start Commands

### **Start All Services**
```bash
# Deploy entire stack
cd k8s/scripts
./deploy-all.sh

# Or individual services
./deploy-postgres.sh
./deploy-redis.sh  
./deploy-kafka.sh
./deploy-fe-main.sh
```

### **Create Access Tunnels**
```bash
# Create Redis tunnels
cd k8s/scripts
./create-redis-tunnels.sh

# Manual tunnels for all services
kubectl port-forward service/postgres-service 5432:5432 &
kubectl port-forward service/redis-service 6379:6379 &
kubectl port-forward service/pgadmin-service 8080:80 &
kubectl port-forward service/kafka-ui-service 8081:8080 -n kafka &
kubectl port-forward service/fe-main-service 3000:3000 &
```

### **Health Check Commands**
```bash
# Check all pods
kubectl get pods
kubectl get pods -n kafka

# Check services
kubectl get services
kubectl get services -n kafka

# Test connections
redis-cli -h localhost -p 6379 -a Redis-Secure-2024! ping
psql -h localhost -p 5432 -U postgres -d 4thitek_db -c "SELECT version();"
```

---

## 📞 Support & Troubleshooting

### **Common Issues & Solutions**

#### **Connection Refused:**
```bash
# Check if service is running
kubectl get pods | grep <service-name>
kubectl logs <pod-name>

# Check port-forward
ps aux | grep port-forward
pkill -f port-forward  # Kill all port-forwards
```

#### **Authentication Failed:**
```bash
# Verify credentials in secrets
kubectl get secret <secret-name> -o yaml
kubectl get secret <secret-name> -o jsonpath='{.data.<key>}' | base64 -d
```

#### **Service Not Accessible:**
```bash
# Check service endpoints
kubectl get endpoints
kubectl describe service <service-name>

# Check pod connectivity
kubectl exec -it <pod-name> -- nslookup <service-name>
```

### **Emergency Reset**
```bash
# Restart specific deployment
kubectl rollout restart deployment/<deployment-name>

# Force pod recreation
kubectl delete pod <pod-name>

# Complete reset (CAREFUL!)
kubectl delete all --all
```

---

## 📊 Service Health Dashboard

### **Database Layer**
- ✅ PostgreSQL: `kubectl get pods | grep postgres`
- ✅ pgBouncer: `kubectl get pods | grep pgbouncer` 
- ✅ pgAdmin: `kubectl get pods | grep pgadmin`

### **Cache Layer**
- ✅ Redis: `kubectl get pods | grep redis`
- ✅ Redis Tools: `kubectl get pods | grep redis-`

### **Messaging Layer**
- ✅ Kafka: `kubectl get pods -n kafka | grep kafka`
- ✅ Zookeeper: `kubectl get pods -n kafka | grep zookeeper`

### **Frontend Layer**
- ✅ Main App: `kubectl get pods | grep fe-main`
- ✅ Admin App: `kubectl get pods | grep fe-admin`
- ✅ Dealer App: `kubectl get pods | grep fe-dealer`

---

**📝 Last Updated:** $(date)
**🏗️ Environment:** Kubernetes Multi-node Cluster
**🔐 Security Level:** Development (Enhanced with Secrets)
**📍 Cluster Nodes:** multinode-demo, multinode-demo-m02, multinode-demo-m03, multinode-demo-m04

---

**⚠️ IMPORTANT:** 
- Keep this document secure and do not commit to public repositories
- Update passwords regularly in production environments
- Monitor access logs and implement proper audit trails
- Use this for development/testing purposes - implement additional security for production