# 🚀 4thitek - Kubernetes Microservices Platform

[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.33.1-blue.svg)](https://kubernetes.io/)
[![Docker](https://img.shields.io/badge/Docker-28.1.1-blue.svg)](https://docker.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue.svg)](https://postgresql.org/)
[![Redis](https://img.shields.io/badge/Redis-7.2-red.svg)](https://redis.io/)
[![Kafka](https://img.shields.io/badge/Apache%20Kafka-7.4.0-orange.svg)](https://kafka.apache.org/)

A comprehensive microservices platform built on Kubernetes with modern web applications, database management, caching, and message streaming capabilities.

## 📋 Table of Contents
- [Architecture Overview](#architecture-overview)
- [Quick Start](#quick-start)
- [Services](#services)
- [Documentation](#documentation)
- [Development](#development)
- [Production Deployment](#production-deployment)
- [Monitoring & Maintenance](#monitoring--maintenance)
- [Contributing](#contributing)

---

## 🏗️ Architecture Overview

### **Multi-Tier Architecture**
```
┌─────────────────────────────────────────────────────────────┐
│                    CLIENT LAYER                              │
├─────────────────────────────────────────────────────────────┤
│  Frontend Layer (multinode-demo)                           │
│  ├── fe-main (Next.js)     ├── fe-admin (React)           │
│  └── fe-dealer (React)                                     │
├─────────────────────────────────────────────────────────────┤
│  Database Layer (multinode-demo-m02)                       │
│  ├── PostgreSQL 15         ├── pgBouncer (Connection Pool) │
│  └── pgAdmin (Web UI)                                      │
├─────────────────────────────────────────────────────────────┤
│  Cache & Messaging Layer (multinode-demo-m04)              │
│  ├── Redis 7.2            ├── Apache Kafka 7.4.0          │
│  ├── Zookeeper 7.4.0      └── Management UIs               │
└─────────────────────────────────────────────────────────────┘
```

### **Technology Stack**
- **Container Orchestration**: Kubernetes 1.33.1
- **Frontend**: Next.js, React with TypeScript
- **Database**: PostgreSQL 15 with pgBouncer connection pooling
- **Cache**: Redis 7.2 with Redis Insight analytics
- **Message Broker**: Apache Kafka 7.4.0 with Zookeeper
- **Monitoring**: Metrics Server, HPA (Horizontal Pod Autoscaler)
- **Security**: Kubernetes Secrets, RBAC, Security Contexts

---

## 🚀 Quick Start

### **Prerequisites**
- Kubernetes cluster (minikube, kind, or cloud provider)
- kubectl configured and connected
- Docker for building custom images
- Git for version control

### **1. Clone Repository**
```bash
git clone <repository-url>
cd 4thitek
```

### **2. Deploy Infrastructure**
```bash
# Deploy all services at once
cd k8s/scripts
./deploy-all.sh

# Or deploy individually
./deploy-postgres.sh      # Database layer
./deploy-redis.sh         # Cache layer  
./deploy-kafka.sh         # Message broker
./deploy-fe-main.sh       # Frontend applications
./deploy-fe-admin.sh
./deploy-fe-dealer.sh
```

### **3. Verify Deployment**
```bash
# Check all pods are running
kubectl get pods
kubectl get pods -n kafka

# Check services
kubectl get services
kubectl get services -n kafka
```

### **4. Access Applications**
```bash
# Create access tunnels
kubectl port-forward service/fe-main-service 3000:3000 &
kubectl port-forward service/pgadmin-service 8080:80 &
kubectl port-forward service/kafka-ui-service 8081:8080 -n kafka &

# Access URLs
# Main App: http://localhost:3000
# pgAdmin: http://localhost:8080
# Kafka UI: http://localhost:8081
```

---

## 🎯 Services

### **Frontend Applications**
| Service | Description | Port | Technology |
|---------|-------------|------|------------|
| **fe-main** | Main customer-facing application | 3000 | Next.js |
| **fe-admin** | Administrative dashboard | 4000 | React + TypeScript |
| **fe-dealer** | Dealer management portal | 5000 | React + TypeScript |

### **Database Services**
| Service | Description | Port | Technology |
|---------|-------------|------|------------|
| **postgres** | Primary database server | 5432 | PostgreSQL 15 |
| **pgbouncer** | Connection pooling | 5432 | pgBouncer |
| **pgadmin** | Database administration | 8080 | pgAdmin 4 |

### **Cache & Messaging**
| Service | Description | Port | Technology |
|---------|-------------|------|------------|
| **redis** | In-memory cache | 6379 | Redis 7.2 |
| **kafka** | Message streaming | 9092 | Apache Kafka |
| **zookeeper** | Kafka coordination | 2181 | Apache Zookeeper |
| **kafka-ui** | Kafka management UI | 8080 | Kafka UI |

---

## 📚 Documentation

### **Essential Guides**
- 📋 **[KUBERNETES_COMMANDS.md](./KUBERNETES_COMMANDS.md)** - Complete kubectl reference
- 🔐 **[ACCESS_CREDENTIALS.md](./ACCESS_CREDENTIALS.md)** - Login credentials & URLs
- 🏗️ **[ARCHITECTURE.md](./ARCHITECTURE.md)** - System architecture details
- 🚀 **[DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)** - Step-by-step deployment
- 🔧 **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)** - Common issues & solutions

### **Configuration Files**
```
k8s/
├── frontend/           # Frontend application deployments
├── database/          # PostgreSQL, pgBouncer, pgAdmin
├── cache/            # Redis and management tools
├── messaging/        # Kafka and Zookeeper
├── scripts/          # Deployment automation scripts
└── rbac-fix.yaml     # RBAC permissions
```

---

## 💻 Development

### **Local Development Setup**
```bash
# 1. Start minikube cluster
minikube start --nodes 4 --cpus 2 --memory 4g

# 2. Enable required addons
minikube addons enable metrics-server
minikube addons enable ingress

# 3. Build and load custom images
cd fe/main && docker build -t fe-main:latest .
minikube image load fe-main:latest

# 4. Deploy services
cd k8s/scripts && ./deploy-all.sh
```

### **Development Workflow**
1. **Code Changes**: Modify application code
2. **Build Image**: `docker build -t <image>:<tag> .`
3. **Load to Cluster**: `minikube image load <image>:<tag>`
4. **Update Deployment**: `kubectl set image deployment/<name> container=<image>:<tag>`
5. **Verify**: `kubectl rollout status deployment/<name>`

### **Database Migrations**
```bash
# Connect to PostgreSQL
kubectl port-forward service/postgres-service 5432:5432
psql -h localhost -p 5432 -U postgres -d 4thitek_db

# Run migrations
# Add your migration commands here
```

---

## 🌟 Production Deployment

### **Pre-Production Checklist**
- [ ] Update all passwords in secrets
- [ ] Configure TLS/HTTPS certificates
- [ ] Set up monitoring and alerting
- [ ] Configure backup strategies
- [ ] Implement network policies
- [ ] Set resource limits and requests
- [ ] Configure ingress controllers
- [ ] Set up logging aggregation

### **Production Configuration**
```bash
# 1. Create production namespace
kubectl create namespace production

# 2. Deploy with production configs
kubectl apply -f k8s/ -n production

# 3. Configure ingress
kubectl apply -f k8s/ingress/ -n production

# 4. Set up monitoring
kubectl apply -f k8s/monitoring/ -n production
```

### **Scaling Configuration**
```bash
# Horizontal Pod Autoscaling (HPA) is configured for:
# - Frontend applications (2-5 replicas)
# - pgBouncer (2-5 replicas)  
# - Kafka brokers (3-6 replicas)

# Manual scaling
kubectl scale deployment fe-main --replicas=5
kubectl scale statefulset kafka --replicas=5 -n kafka
```

---

## 📊 Monitoring & Maintenance

### **Health Checks**
```bash
# Overall cluster health
kubectl get nodes
kubectl get pods --all-namespaces

# Service-specific health
kubectl get pods | grep postgres
kubectl get pods -n kafka | grep kafka
kubectl get hpa  # Check autoscaling
```

### **Resource Monitoring**
```bash
# Node resource usage
kubectl top nodes

# Pod resource usage  
kubectl top pods
kubectl top pods -n kafka

# Check resource limits
kubectl describe node <node-name>
```

### **Log Monitoring**
```bash
# Application logs
kubectl logs -f deployment/fe-main
kubectl logs -f deployment/postgres
kubectl logs -f kafka-0 -n kafka

# System logs
kubectl logs -f -n kube-system deployment/coredns
```

### **Backup Procedures**
```bash
# Database backup
kubectl exec -it deployment/postgres -- pg_dump -U postgres 4thitek_db > backup-$(date +%Y%m%d).sql

# Redis backup (if persistence enabled)
kubectl exec -it deployment/redis -- redis-cli -a Redis-Secure-2024! BGSAVE

# Configuration backup
kubectl get all -o yaml > cluster-backup-$(date +%Y%m%d).yaml
```

---

## 🔧 Common Operations

### **Update Applications**
```bash
# Rolling update
kubectl set image deployment/fe-main fe-main=fe-main:v2.0.0
kubectl rollout status deployment/fe-main

# Rollback if needed
kubectl rollout undo deployment/fe-main
```

### **Database Operations**
```bash
# Connect to database
kubectl port-forward service/postgres-service 5432:5432
psql -h localhost -p 5432 -U postgres -d 4thitek_db

# Restart database (if needed)
kubectl rollout restart deployment/postgres
```

### **Cache Operations**
```bash
# Connect to Redis
kubectl port-forward service/redis-service 6379:6379
redis-cli -h localhost -p 6379 -a Redis-Secure-2024!

# Clear cache
redis-cli -h localhost -p 6379 -a Redis-Secure-2024! FLUSHDB
```

---

## 🆘 Troubleshooting

### **Common Issues**

#### **Pods Not Starting**
```bash
# Check pod status and events
kubectl describe pod <pod-name>
kubectl get events --sort-by=.metadata.creationTimestamp

# Check logs
kubectl logs <pod-name>
kubectl logs <pod-name> --previous
```

#### **Service Connection Issues**
```bash
# Check service endpoints
kubectl get endpoints
kubectl describe service <service-name>

# Test internal connectivity
kubectl run test-pod --image=busybox --restart=Never -- sleep 3600
kubectl exec -it test-pod -- nslookup <service-name>
```

#### **Resource Issues**
```bash
# Check resource usage
kubectl top nodes
kubectl top pods

# Check resource quotas
kubectl describe resourcequota
kubectl describe limitrange
```

For detailed troubleshooting, see **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)**

---

## 🤝 Contributing

### **Development Guidelines**
1. Follow Kubernetes best practices
2. Use semantic versioning for images
3. Include proper resource limits
4. Add health checks and readiness probes
5. Document configuration changes
6. Test in development environment first

### **Submitting Changes**
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request
6. Update documentation

---

## 📞 Support

### **Getting Help**
- 📚 Check documentation files in `/docs`
- 🔍 Search existing issues
- 💬 Contact the development team
- 📧 Email: support@4thitek.com

### **Reporting Issues**
1. Check troubleshooting guide first
2. Gather relevant logs and system info
3. Create detailed issue report
4. Include steps to reproduce

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 🏷️ Version Information

**Current Version**: v1.0.0
**Kubernetes**: v1.33.1
**Last Updated**: $(date)
**Maintainer**: 4thitek Development Team

---

## 🎯 Roadmap

### **Planned Features**
- [ ] Microservices mesh with Istio
- [ ] Advanced monitoring with Prometheus/Grafana
- [ ] CI/CD pipeline integration
- [ ] Multi-region deployment
- [ ] Advanced security hardening
- [ ] Performance optimization
- [ ] Cost optimization tools

### **Current Status**
- ✅ Core infrastructure deployed
- ✅ Security hardening completed
- ✅ Basic monitoring implemented
- ✅ Documentation completed
- 🔄 Production optimization in progress
- 🔄 Advanced features planning

---

**🚀 Ready to deploy? Start with the [Quick Start](#quick-start) guide!**

**📚 Need help? Check our comprehensive [documentation](#documentation)!**

**🔐 Want access credentials? See [ACCESS_CREDENTIALS.md](./ACCESS_CREDENTIALS.md)!**