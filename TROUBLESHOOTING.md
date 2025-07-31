# 🔧 Troubleshooting Guide - 4thitek Kubernetes Platform

## 📋 Table of Contents
- [Quick Diagnostics](#quick-diagnostics)
- [Pod Issues](#pod-issues)
- [Service Connectivity](#service-connectivity)
- [Database Problems](#database-problems)
- [Cache & Messaging Issues](#cache--messaging-issues)
- [Frontend Application Issues](#frontend-application-issues)
- [Resource & Performance Issues](#resource--performance-issues)
- [Security & Access Issues](#security--access-issues)
- [Networking Problems](#networking-problems)
- [Emergency Procedures](#emergency-procedures)

---

## 🩺 Quick Diagnostics

### **Cluster Health Check**
```bash
# Overall cluster status
kubectl cluster-info
kubectl get nodes
kubectl get pods --all-namespaces | grep -v Running

# Check for failed pods
kubectl get pods --field-selector=status.phase=Failed --all-namespaces
kubectl get pods --field-selector=status.phase=Pending --all-namespaces

# Recent events
kubectl get events --sort-by=.metadata.creationTimestamp --all-namespaces
```

### **Service Status Overview**
```bash
# Database layer
kubectl get pods | grep -E "(postgres|pgbouncer|pgadmin)"

# Cache & Messaging layer
kubectl get pods | grep redis
kubectl get pods -n kafka | grep -E "(kafka|zookeeper)"

# Frontend layer
kubectl get pods | grep -E "(fe-main|fe-admin|fe-dealer)"

# Check services
kubectl get services
kubectl get services -n kafka
```

---

## 🚫 Pod Issues

### **Pods Not Starting (Pending State)**

#### **Symptoms:**
- Pod stuck in `Pending` state
- Events show scheduling failures

#### **Diagnosis:**
```bash
kubectl describe pod <pod-name>
kubectl get events --field-selector involvedObject.name=<pod-name>
```

#### **Common Causes & Solutions:**

##### **1. Resource Constraints**
```bash
# Check node resources
kubectl top nodes
kubectl describe nodes

# Solution: Scale down other pods or add nodes
kubectl scale deployment <deployment-name> --replicas=1
```

##### **2. Node Selector Issues**
```bash
# Check if target node exists
kubectl get nodes --show-labels
kubectl describe pod <pod-name> | grep "Node-Selectors"

# Solution: Fix or remove node selector
kubectl patch deployment <deployment-name> -p '{"spec":{"template":{"spec":{"nodeSelector":null}}}}'
```

##### **3. Persistent Volume Issues**
```bash
# Check PVC status
kubectl get pvc
kubectl describe pvc <pvc-name>

# Solution: Check storage class and available storage
kubectl get storageclass
```

### **Pod Crashes (CrashLoopBackOff)**

#### **Symptoms:**
- Pod shows `CrashLoopBackOff` status
- High restart count

#### **Diagnosis:**
```bash
kubectl logs <pod-name>
kubectl logs <pod-name> --previous
kubectl describe pod <pod-name>
```

#### **Common Causes & Solutions:**

##### **1. Application Configuration Issues**
```bash
# Check environment variables
kubectl describe pod <pod-name> | grep -A 20 "Environment"

# Check secrets and configmaps
kubectl get secret <secret-name> -o yaml
kubectl get configmap <configmap-name> -o yaml
```

##### **2. Health Check Failures**
```bash
# Check readiness/liveness probes
kubectl describe pod <pod-name> | grep -A 10 "Liveness\|Readiness"

# Solution: Adjust probe settings
kubectl patch deployment <deployment-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container-name>","livenessProbe":{"initialDelaySeconds":60}}]}}}}'
```

##### **3. Permission Issues**
```bash
# Check security context
kubectl describe pod <pod-name> | grep -A 10 "Security Context"

# Solution: Fix user/group permissions
kubectl patch deployment <deployment-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container-name>","securityContext":{"runAsUser":1000}}]}}}}'
```

### **Image Pull Errors**

#### **Symptoms:**
- `ErrImagePull` or `ImagePullBackOff` status
- Cannot pull container image

#### **Diagnosis:**
```bash
kubectl describe pod <pod-name>
kubectl get events | grep <pod-name>
```

#### **Solutions:**

##### **For Custom Images (fe-main, fe-admin, fe-dealer):**
```bash
# Build and load image to minikube
docker build -t <image-name>:<tag> .
minikube image load <image-name>:<tag>

# Or change pull policy
kubectl patch deployment <deployment-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container-name>","imagePullPolicy":"IfNotPresent"}]}}}}'
```

##### **For Public Images:**
```bash
# Check image name and tag
docker pull <image-name>:<tag>

# Update deployment with correct image
kubectl set image deployment/<deployment-name> <container-name>=<correct-image>:<tag>
```

---

## 🌐 Service Connectivity

### **Cannot Connect to Services**

#### **Symptoms:**
- Connection refused errors
- Timeouts when accessing services
- Port-forward fails

#### **Diagnosis:**
```bash
# Check service status
kubectl get services
kubectl describe service <service-name>
kubectl get endpoints <service-name>

# Check if pods are ready
kubectl get pods -l app=<app-label>
```

#### **Solutions:**

##### **1. Service Selector Mismatch**
```bash
# Check service selector vs pod labels
kubectl describe service <service-name> | grep Selector
kubectl describe pod <pod-name> | grep Labels

# Fix selector if needed
kubectl patch service <service-name> -p '{"spec":{"selector":{"app":"<correct-label>"}}}'
```

##### **2. Port Configuration Issues**
```bash
# Check service ports vs container ports
kubectl describe service <service-name> | grep Port
kubectl describe pod <pod-name> | grep Port

# Update service port
kubectl patch service <service-name> -p '{"spec":{"ports":[{"port":80,"targetPort":8080}]}}'
```

##### **3. Pod Not Ready**
```bash
# Check pod readiness
kubectl get pods -l app=<app-label>
kubectl describe pod <pod-name>

# Check readiness probe
kubectl logs <pod-name>
```

### **DNS Resolution Issues**

#### **Symptoms:**
- Cannot resolve service names
- `nslookup` fails from within pods

#### **Diagnosis:**
```bash
# Test DNS from a pod
kubectl run test-dns --image=busybox --restart=Never -- sleep 3600
kubectl exec -it test-dns -- nslookup kubernetes.default
kubectl exec -it test-dns -- nslookup <service-name>
kubectl delete pod test-dns
```

#### **Solutions:**
```bash
# Check CoreDNS
kubectl get pods -n kube-system | grep coredns
kubectl logs -n kube-system deployment/coredns

# Restart CoreDNS if needed
kubectl rollout restart -n kube-system deployment/coredns
```

---

## 🗄️ Database Problems

### **PostgreSQL Connection Issues**

#### **Symptoms:**
- Applications cannot connect to database
- Connection timeouts or refused connections

#### **Diagnosis:**
```bash
# Check PostgreSQL pod
kubectl get pods | grep postgres
kubectl logs postgres-<pod-suffix>

# Test connection
kubectl port-forward service/postgres-service 5432:5432 &
psql -h localhost -p 5432 -U postgres -d 4thitek_db
```

#### **Solutions:**

##### **1. PostgreSQL Not Ready**
```bash
# Check pod status and logs
kubectl describe pod postgres-<pod-suffix>
kubectl logs postgres-<pod-suffix>

# Check data directory permissions
kubectl exec -it postgres-<pod-suffix> -- ls -la /var/lib/postgresql/data
```

##### **2. Incorrect Credentials**
```bash
# Check secret values
kubectl get secret postgres-secret -o yaml
kubectl get secret postgres-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d

# Update secret if needed
kubectl patch secret postgres-secret -p '{"data":{"POSTGRES_PASSWORD":"<base64-encoded-password>"}}'
```

##### **3. pgBouncer Issues**
```bash
# Check pgBouncer logs
kubectl logs deployment/pgbouncer

# Test direct PostgreSQL connection (bypass pgBouncer)
kubectl port-forward service/postgres-service 5433:5432
psql -h localhost -p 5433 -U postgres -d 4thitek_db
```

### **pgAdmin Access Issues**

#### **Symptoms:**
- Cannot access pgAdmin web interface
- Login failures

#### **Diagnosis:**
```bash
# Check pgAdmin pod
kubectl get pods | grep pgadmin
kubectl logs pgadmin-<pod-suffix>

# Test port-forward
kubectl port-forward service/pgadmin-service 8080:80
curl http://localhost:8080
```

#### **Solutions:**

##### **1. pgAdmin Service Issues**
```bash
# Check service configuration
kubectl describe service pgadmin-service

# Restart pgAdmin
kubectl rollout restart deployment/pgadmin
```

##### **2. Credentials Issues**
```bash
# Check pgAdmin secret
kubectl get secret pgadmin-secret -o yaml
kubectl get secret pgadmin-secret -o jsonpath='{.data.PGADMIN_DEFAULT_EMAIL}' | base64 -d
kubectl get secret pgadmin-secret -o jsonpath='{.data.PGADMIN_DEFAULT_PASSWORD}' | base64 -d
```

---

## 🚀 Cache & Messaging Issues

### **Redis Connection Problems**

#### **Symptoms:**
- Applications cannot connect to Redis
- Redis CLI connection failures

#### **Diagnosis:**
```bash
# Check Redis pod
kubectl get pods | grep redis
kubectl logs redis-<pod-suffix>

# Test Redis connection
kubectl port-forward service/redis-service 6379:6379 &
redis-cli -h localhost -p 6379 -a Redis-Secure-2024! ping
```

#### **Solutions:**

##### **1. Redis Authentication Issues**
```bash
# Check Redis config
kubectl describe configmap redis-config

# Test without authentication (if auth disabled)
redis-cli -h localhost -p 6379 ping

# Update Redis password
kubectl get secret redis-secret -o jsonpath='{.data.redis-password}' | base64 -d
```

##### **2. Redis Data Directory Issues**
```bash
# Check Redis data permissions
kubectl exec -it redis-<pod-suffix> -- ls -la /data

# Check persistent volume
kubectl get pvc redis-data-pvc
kubectl describe pvc redis-data-pvc
```

### **Kafka Cluster Issues**

#### **Symptoms:**
- Kafka brokers not starting
- Cannot produce/consume messages
- Kafka UI not accessible

#### **Diagnosis:**
```bash
# Check all Kafka components
kubectl get pods -n kafka
kubectl logs kafka-0 -n kafka
kubectl logs zookeeper-0 -n kafka

# Test Kafka functionality
kubectl exec -it kafka-0 -n kafka -- kafka-topics --bootstrap-server localhost:9092 --list
```

#### **Solutions:**

##### **1. Zookeeper Issues**
```bash
# Check Zookeeper status
kubectl exec -it zookeeper-0 -n kafka -- zkServer.sh status

# Check Zookeeper logs
kubectl logs zookeeper-0 -n kafka

# Restart Zookeeper ensemble
kubectl delete pods zookeeper-0 zookeeper-1 zookeeper-2 -n kafka
```

##### **2. Kafka Broker Issues**
```bash
# Check Kafka broker logs
kubectl logs kafka-0 -n kafka
kubectl logs kafka-1 -n kafka
kubectl logs kafka-2 -n kafka

# Check broker configuration
kubectl describe pod kafka-0 -n kafka

# Restart Kafka brokers (one by one)
kubectl delete pod kafka-0 -n kafka
# Wait for kafka-0 to be ready, then continue with kafka-1, kafka-2
```

##### **3. Kafka UI Access Issues**
```bash
# Check Kafka UI pod
kubectl get pods -n kafka | grep kafka-ui
kubectl logs kafka-ui-<pod-suffix> -n kafka

# Test Kafka UI access
kubectl port-forward service/kafka-ui-service 8080:8080 -n kafka
curl http://localhost:8080
```

---

## 🌐 Frontend Application Issues

### **Frontend Apps Not Loading**

#### **Symptoms:**
- Blank pages or 404 errors
- Build failures
- Slow loading times

#### **Diagnosis:**
```bash
# Check frontend pods
kubectl get pods | grep -E "(fe-main|fe-admin|fe-dealer)"
kubectl logs fe-main-<pod-suffix>

# Test direct pod access
kubectl port-forward pod/fe-main-<pod-suffix> 3000:3000
```

#### **Solutions:**

##### **1. Build Issues**
```bash
# Rebuild frontend images
cd fe/main
docker build -t fe-main:latest .
minikube image load fe-main:latest

# Force deployment update
kubectl rollout restart deployment/fe-main
```

##### **2. Configuration Issues**
```bash
# Check environment variables
kubectl describe deployment fe-main | grep -A 10 Environment

# Check if backend services are accessible
kubectl exec -it fe-main-<pod-suffix> -- nslookup postgres-service
```

##### **3. Resource Constraints**
```bash
# Check resource usage
kubectl top pods | grep fe-main

# Increase resource limits
kubectl patch deployment fe-main -p '{"spec":{"template":{"spec":{"containers":[{"name":"fe-main","resources":{"limits":{"memory":"512Mi","cpu":"500m"}}}]}}}}'
```

---

## 📊 Resource & Performance Issues

### **High Resource Usage**

#### **Symptoms:**
- Pods being killed (OOMKilled)
- Slow response times
- Node resource exhaustion

#### **Diagnosis:**
```bash
# Check resource usage
kubectl top nodes
kubectl top pods
kubectl top pods -n kafka

# Check resource limits
kubectl describe pod <pod-name> | grep -A 10 "Limits\|Requests"
```

#### **Solutions:**

##### **1. Memory Issues**
```bash
# Increase memory limits
kubectl patch deployment <deployment-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container-name>","resources":{"limits":{"memory":"1Gi"}}}]}}}}'

# Check for memory leaks in application logs
kubectl logs <pod-name> | grep -i "memory\|oom"
```

##### **2. CPU Issues**
```bash
# Increase CPU limits
kubectl patch deployment <deployment-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container-name>","resources":{"limits":{"cpu":"1000m"}}}]}}}}'

# Check CPU-intensive processes
kubectl exec -it <pod-name> -- top
```

### **Autoscaling Issues**

#### **Symptoms:**
- HPA not scaling pods
- Scaling too aggressive or too slow

#### **Diagnosis:**
```bash
# Check HPA status
kubectl get hpa
kubectl describe hpa <hpa-name>

# Check metrics
kubectl top pods
```

#### **Solutions:**
```bash
# Adjust HPA thresholds
kubectl patch hpa <hpa-name> -p '{"spec":{"targetCPUUtilizationPercentage":70}}'

# Check metrics server
kubectl get pods -n kube-system | grep metrics-server
kubectl logs -n kube-system deployment/metrics-server
```

---

## 🔐 Security & Access Issues

### **Authentication Failures**

#### **Symptoms:**
- Login failures to web interfaces
- Database connection refused

#### **Diagnosis:**
```bash
# Check all secrets
kubectl get secrets
kubectl describe secret <secret-name>

# Decode secret values
kubectl get secret <secret-name> -o jsonpath='{.data.<key>}' | base64 -d
```

#### **Solutions:**
```bash
# Update secret values
kubectl patch secret <secret-name> -p '{"data":{"<key>":"<base64-encoded-value>"}}'

# Restart deployments to pick up new secrets
kubectl rollout restart deployment/<deployment-name>
```

### **RBAC Permission Issues**

#### **Symptoms:**
- Forbidden errors
- Cannot perform certain operations

#### **Diagnosis:**
```bash
# Check current permissions
kubectl auth can-i <verb> <resource>
kubectl auth can-i create pods

# Check RBAC configuration
kubectl get roles,rolebindings,clusterroles,clusterrolebindings
```

#### **Solutions:**
```bash
# Apply RBAC fix
kubectl apply -f k8s/rbac-fix.yaml

# Check service account permissions
kubectl describe serviceaccount default
```

---

## 🌍 Networking Problems

### **Inter-Pod Communication Issues**

#### **Symptoms:**
- Services cannot communicate with each other
- Database connections from apps fail

#### **Diagnosis:**
```bash
# Test pod-to-pod connectivity
kubectl run test-net --image=busybox --restart=Never -- sleep 3600
kubectl exec -it test-net -- ping <pod-ip>
kubectl exec -it test-net -- nslookup <service-name>
kubectl delete pod test-net
```

#### **Solutions:**
```bash
# Check network policies (if any)
kubectl get networkpolicies

# Check CNI plugin
kubectl get pods -n kube-system | grep -E "(flannel|calico|weave)"

# Restart networking components
kubectl rollout restart -n kube-system daemonset/kindnet
```

### **Port-Forward Issues**

#### **Symptoms:**
- Port-forward commands fail
- Local access not working

#### **Solutions:**
```bash
# Kill existing port-forwards
pkill -f "kubectl port-forward"

# Use different local ports
kubectl port-forward service/<service-name> 8081:80

# Check if service exists and has endpoints
kubectl get service <service-name>
kubectl get endpoints <service-name>
```

---

## 🆘 Emergency Procedures

### **Complete System Recovery**

#### **When Everything is Broken:**
```bash
# 1. Check cluster connectivity
kubectl cluster-info

# 2. Emergency pod restart
kubectl rollout restart deployment/postgres
kubectl rollout restart deployment/redis
kubectl rollout restart deployment/kafka-ui -n kafka

# 3. Force pod recreation if needed
kubectl delete pods --all --grace-period=0 --force
kubectl delete pods --all -n kafka --grace-period=0 --force

# 4. Redeploy everything (LAST RESORT)
cd k8s/scripts
./cleanup.sh  # If exists
./deploy-all.sh
```

### **Data Recovery Procedures**

#### **Database Recovery:**
```bash
# 1. Check if data is intact
kubectl exec -it postgres-<pod-suffix> -- ls -la /var/lib/postgresql/data

# 2. Create backup before any recovery
kubectl exec -it postgres-<pod-suffix> -- pg_dump -U postgres 4thitek_db > emergency-backup.sql

# 3. Restore from backup if needed
kubectl exec -i postgres-<pod-suffix> -- psql -U postgres -d 4thitek_db < backup.sql
```

#### **Redis Recovery:**
```bash
# Check Redis data
kubectl exec -it redis-<pod-suffix> -- redis-cli -a Redis-Secure-2024! info persistence

# Create backup
kubectl exec -it redis-<pod-suffix> -- redis-cli -a Redis-Secure-2024! BGSAVE
```

### **Rollback Procedures**

#### **Application Rollback:**
```bash
# Check rollout history
kubectl rollout history deployment/<deployment-name>

# Rollback to previous version
kubectl rollout undo deployment/<deployment-name>

# Rollback to specific revision
kubectl rollout undo deployment/<deployment-name> --to-revision=2
```

---

## 📞 Getting Help

### **Escalation Steps**
1. **Check this troubleshooting guide**
2. **Search logs** for specific error messages
3. **Check Kubernetes documentation**
4. **Contact system administrator**
5. **Escalate to development team**

### **Information to Gather**
When reporting issues, include:
```bash
# System information
kubectl version
kubectl cluster-info

# Resource status
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get services --all-namespaces

# Recent events
kubectl get events --sort-by=.metadata.creationTimestamp

# Specific pod information
kubectl describe pod <problematic-pod>
kubectl logs <problematic-pod>
kubectl logs <problematic-pod> --previous
```

### **Log Collection Script**
```bash
#!/bin/bash
# collect-logs.sh
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_DIR="k8s-logs-$TIMESTAMP"
mkdir -p $LOG_DIR

# Collect cluster info
kubectl cluster-info > $LOG_DIR/cluster-info.txt
kubectl get nodes -o wide > $LOG_DIR/nodes.txt
kubectl get pods --all-namespaces -o wide > $LOG_DIR/pods.txt
kubectl get services --all-namespaces > $LOG_DIR/services.txt
kubectl get events --all-namespaces --sort-by=.metadata.creationTimestamp > $LOG_DIR/events.txt

# Collect application logs
kubectl logs deployment/postgres > $LOG_DIR/postgres.log
kubectl logs deployment/redis > $LOG_DIR/redis.log
kubectl logs deployment/kafka-ui -n kafka > $LOG_DIR/kafka-ui.log

echo "Logs collected in $LOG_DIR/"
```

---

**🔧 Remember:** Most issues can be resolved by checking logs, verifying configurations, and ensuring all dependencies are running properly.

**🆘 Emergency Contact:** If critical systems are down, follow the emergency procedures and contact the on-call team immediately.