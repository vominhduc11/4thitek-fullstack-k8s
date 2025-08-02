# 🚀 Hướng Dẫn Deploy Dự Án 4thitek Lên Google Cloud Kubernetes

## 📋 Mục Lục
- [Yêu Cầu Hệ Thống](#yêu-cầu-hệ-thống)
- [Thiết Lập Google Cloud](#thiết-lập-google-cloud)
- [Tạo GKE Cluster](#tạo-gke-cluster)
- [Chuẩn Bị Môi Trường](#chuẩn-bị-môi-trường)
- [Build và Push Docker Images](#build-và-push-docker-images)
- [Deploy Từng Bước](#deploy-từng-bước)
- [Cấu Hình Domain và SSL](#cấu-hình-domain-và-ssl)
- [Monitoring và Logging](#monitoring-và-logging)
- [Backup và Maintenance](#backup-và-maintenance)

---

## ✅ Yêu Cầu Hệ Thống

### **Công Cụ Cần Thiết**
```bash
# Cài đặt Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Cài đặt kubectl
gcloud components install kubectl

# Xác minh cài đặt
gcloud version
kubectl version --client
docker --version
```

### **Tài Khoản Google Cloud**
- Tài khoản Google Cloud có billing enabled
- Quyền tạo GKE clusters và manage resources
- Budget alerts được thiết lập (recommended)

---

## 🏗️ Thiết Lập Google Cloud

### **Bước 1: Tạo Project và Enable APIs**
```bash
# Đăng nhập Google Cloud
gcloud auth login

# Tạo project mới
export PROJECT_ID="4thitek-k8s-$(date +%s)"
gcloud projects create $PROJECT_ID
gcloud config set project $PROJECT_ID

# Link billing account (thay YOUR_BILLING_ACCOUNT_ID)
gcloud billing projects link $PROJECT_ID --billing-account=YOUR_BILLING_ACCOUNT_ID

# Enable required APIs
gcloud services enable container.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable cloudsql.googleapis.com
gcloud services enable redis.googleapis.com
gcloud services enable monitoring.googleapis.com
gcloud services enable logging.googleapis.com
```

### **Bước 2: Thiết Lập Default Region**
```bash
# Chọn region gần Việt Nam
export REGION="asia-southeast1"
export ZONE="asia-southeast1-a"

gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE
```

---

## 🎯 Tạo GKE Cluster

### **Development Cluster (Chi phí thấp)**
```bash
# Tạo cluster development
gcloud container clusters create 4thitek-dev \
    --region=$REGION \
    --node-locations=$ZONE \
    --num-nodes=3 \
    --machine-type=e2-standard-2 \
    --disk-size=20GB \
    --disk-type=pd-standard \
    --enable-autoscaling \
    --min-nodes=1 \
    --max-nodes=5 \
    --enable-autorepair \
    --enable-autoupgrade \
    --preemptible
```

### **Production Cluster (Hiệu năng cao)**
```bash
# Tạo cluster production
gcloud container clusters create 4thitek-prod \
    --region=$REGION \
    --num-nodes=3 \
    --machine-type=e2-standard-4 \
    --disk-size=50GB \
    --disk-type=pd-ssd \
    --enable-autoscaling \
    --min-nodes=3 \
    --max-nodes=10 \
    --enable-autorepair \
    --enable-autoupgrade \
    --enable-network-policy \
    --enable-ip-alias \
    --maintenance-window-start="2024-01-01T02:00:00Z" \
    --maintenance-window-end="2024-01-01T06:00:00Z" \
    --maintenance-window-recurrence="FREQ=WEEKLY;BYDAY=SU"
```

### **Kết Nối Cluster**
```bash
# Lấy credentials cho cluster
gcloud container clusters get-credentials 4thitek-dev --region=$REGION

# Xác minh kết nối
kubectl cluster-info
kubectl get nodes
```

---

## 🔧 Chuẩn Bị Môi Trường

### **Bước 1: Clone Repository**
```bash
# Clone project
git clone https://github.com/your-repo/4thitek.git
cd 4thitek

# Tạo namespace
kubectl create namespace 4thitek-prod
kubectl config set-context --current --namespace=4thitek-prod
```

### **Bước 2: Tạo Google Cloud Resources**
```bash
# Tạo Cloud SQL PostgreSQL instance
gcloud sql instances create 4thitek-postgres \
    --database-version=POSTGRES_15 \
    --cpu=2 \
    --memory=4GB \
    --storage-size=20GB \
    --storage-type=SSD \
    --region=$REGION \
    --backup-start-time=02:00 \
    --enable-bin-log \
    --maintenance-window-day=SUN \
    --maintenance-window-hour=3

# Tạo database
gcloud sql databases create 4thitek_db --instance=4thitek-postgres

# Tạo user
gcloud sql users create 4thitek_user --instance=4thitek-postgres --password=SECURE_PASSWORD_HERE

# Tạo Redis instance
gcloud redis instances create 4thitek-redis \
    --size=1 \
    --region=$REGION \
    --redis-version=redis_7_0
```

### **Bước 3: Tạo Kubernetes Secrets**
```bash
# Database secrets
kubectl create secret generic postgres-secret \
    --from-literal=POSTGRES_DB=4thitek_db \
    --from-literal=POSTGRES_USER=4thitek_user \
    --from-literal=POSTGRES_PASSWORD=SECURE_PASSWORD_HERE \
    --from-literal=POSTGRES_HOST=CLOUD_SQL_IP

# Redis secrets
kubectl create secret generic redis-secret \
    --from-literal=REDIS_HOST=REDIS_IP \
    --from-literal=REDIS_PORT=6379 \
    --from-literal=REDIS_PASSWORD=REDIS_AUTH_STRING

# Application secrets
kubectl create secret generic app-secrets \
    --from-literal=JWT_SECRET=your-jwt-secret \
    --from-literal=API_KEY=your-api-key
```

---

## 📦 Build và Push Docker Images

### **Bước 1: Configure Docker Registry**
```bash
# Configure Docker để sử dụng gcloud credentials
gcloud auth configure-docker

# Hoặc sử dụng Artifact Registry (recommended)
gcloud artifacts repositories create 4thitek-repo \
    --repository-format=docker \
    --location=$REGION

gcloud auth configure-docker $REGION-docker.pkg.dev
```

### **Bước 2: Build và Push Images**
```bash
#!/bin/bash
# build-and-push.sh

export PROJECT_ID=$(gcloud config get-value project)
export REGISTRY="$REGION-docker.pkg.dev/$PROJECT_ID/4thitek-repo"

# Build và push fe-main
echo "🏗️ Building fe-main..."
cd fe/main
docker build -t $REGISTRY/fe-main:v1.0.0 .
docker push $REGISTRY/fe-main:v1.0.0
cd ../..

# Build và push fe-admin
echo "🏗️ Building fe-admin..."
cd fe/admin
docker build -t $REGISTRY/fe-admin:v1.0.0 .
docker push $REGISTRY/fe-admin:v1.0.0
cd ../..

# Build và push fe-dealer
echo "🏗️ Building fe-dealer..."
cd fe/dealer
docker build -t $REGISTRY/fe-dealer:v1.0.0 .
docker push $REGISTRY/fe-dealer:v1.0.0
cd ../..

echo "✅ All images pushed successfully!"
```

### **Bước 3: Update Kubernetes Manifests**
```bash
# Update image paths trong deployment files
export PROJECT_ID=$(gcloud config get-value project)
export REGISTRY="$REGION-docker.pkg.dev/$PROJECT_ID/4thitek-repo"

# Thay thế image paths
sed -i "s|fe-main:v1.0.0|$REGISTRY/fe-main:v1.0.0|g" k8s/frontend/main/fe-main-deployment.yaml
sed -i "s|fe-admin:v1.0.0|$REGISTRY/fe-admin:v1.0.0|g" k8s/frontend/admin/fe-admin-deployment.yaml
sed -i "s|fe-dealer:v1.0.0|$REGISTRY/fe-dealer:v1.0.0|g" k8s/frontend/dealer/fe-dealer-deployment.yaml
```

---

## 🚀 Deploy Từng Bước

### **Bước 1: Deploy Storage Classes**
```bash
# Tạo storage class cho SSD
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-ssd
  replication-type: regional-pd
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
EOF
```

### **Bước 2: Deploy Database Layer (Cloud SQL Proxy)**
```bash
# Tạo service account cho Cloud SQL Proxy
gcloud iam service-accounts create cloudsql-proxy

# Grant quyền
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:cloudsql-proxy@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/cloudsql.client"

# Tạo key
gcloud iam service-accounts keys create key.json \
    --iam-account=cloudsql-proxy@$PROJECT_ID.iam.gserviceaccount.com

# Tạo secret
kubectl create secret generic cloudsql-instance-credentials \
    --from-file=service_account.json=key.json

# Deploy Cloud SQL Proxy
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloudsql-proxy
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cloudsql-proxy
  template:
    metadata:
      labels:
        app: cloudsql-proxy
    spec:
      containers:
      - name: cloudsql-proxy
        image: gcr.io/cloudsql-docker/gce-proxy:1.33.2
        command:
        - "/cloud_sql_proxy"
        - "-instances=$PROJECT_ID:$REGION:4thitek-postgres=tcp:0.0.0.0:5432"
        - "-credential_file=/secrets/cloudsql/service_account.json"
        securityContext:
          runAsNonRoot: true
        volumeMounts:
        - name: cloudsql-instance-credentials
          mountPath: /secrets/cloudsql
          readOnly: true
        ports:
        - containerPort: 5432
      volumes:
      - name: cloudsql-instance-credentials
        secret:
          secretName: cloudsql-instance-credentials
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
spec:
  selector:
    app: cloudsql-proxy
  ports:
  - port: 5432
    targetPort: 5432
EOF
```

### **Bước 3: Deploy Redis Connection**
```bash
# Lấy Redis IP
export REDIS_IP=$(gcloud redis instances describe 4thitek-redis --region=$REGION --format="value(host)")

# Deploy Redis connection service
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: redis-service
spec:
  type: ExternalName
  externalName: $REDIS_IP
  ports:
  - port: 6379
    targetPort: 6379
EOF
```

### **Bước 4: Deploy Frontend Applications**
```bash
# Deploy fe-main
kubectl apply -f k8s/frontend/main/

# Deploy fe-admin  
kubectl apply -f k8s/frontend/admin/

# Deploy fe-dealer
kubectl apply -f k8s/frontend/dealer/

# Kiểm tra deployment
kubectl get deployments
kubectl get pods
```

### **Bước 5: Deploy Load Balancer và Ingress**
```bash
# Tạo external IP
gcloud compute addresses create 4thitek-ip --region=$REGION

# Lấy IP address
export EXTERNAL_IP=$(gcloud compute addresses describe 4thitek-ip --region=$REGION --format="value(address)")

# Deploy Ingress
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: 4thitek-ingress
  annotations:
    kubernetes.io/ingress.class: "gce"
    kubernetes.io/ingress.global-static-ip-name: "4thitek-ip"
    ingress.gcp.kubernetes.io/managed-certificates: "4thitek-ssl-cert"
spec:
  rules:
  - host: app.4thitek.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: fe-main-service
            port:
              number: 3000
  - host: admin.4thitek.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: fe-admin-service
            port:
              number: 3000
  - host: dealer.4thitek.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: fe-dealer-service
            port:
              number: 3000
EOF

echo "🌐 External IP: $EXTERNAL_IP"
echo "📝 Configure your DNS to point to this IP"
```

---

## 🔒 Cấu Hình Domain và SSL

### **Bước 1: Managed SSL Certificate**
```bash
# Tạo managed SSL certificate
kubectl apply -f - <<EOF
apiVersion: networking.gke.io/v1
kind: ManagedCertificate
metadata:
  name: 4thitek-ssl-cert
spec:
  domains:
    - app.4thitek.com
    - admin.4thitek.com
    - dealer.4thitek.com
EOF
```

### **Bước 2: Cấu Hình DNS**
```bash
echo "📋 DNS Configuration Required:"
echo "Record Type: A"
echo "Host: app.4thitek.com -> $EXTERNAL_IP"
echo "Host: admin.4thitek.com -> $EXTERNAL_IP"  
echo "Host: dealer.4thitek.com -> $EXTERNAL_IP"
echo ""
echo "⏳ SSL certificates sẽ được tự động provision sau khi DNS được cấu hình"
```

### **Bước 3: Kiểm Tra SSL Status**
```bash
# Kiểm tra certificate status
kubectl describe managedcertificate 4thitek-ssl-cert

# Kiểm tra ingress
kubectl describe ingress 4thitek-ingress
```

---

## 📊 Monitoring và Logging

### **Bước 1: Enable GKE Monitoring**
```bash
# Enable monitoring cho cluster
gcloud container clusters update 4thitek-dev \
    --region=$REGION \
    --enable-cloud-logging \
    --enable-cloud-monitoring
```

### **Bước 2: Deploy Custom Monitoring**
```bash
# Deploy Prometheus và Grafana (optional)
kubectl create namespace monitoring

# Add Prometheus Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus stack
helm install prometheus-stack prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
    --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false
```

### **Bước 3: Thiết Lập Alerts**
```bash
# Tạo alerting rules
kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: 4thitek-alerts
  namespace: monitoring
spec:
  groups:
  - name: 4thitek.rules
    rules:
    - alert: HighCPUUsage
      expr: cpu_usage_rate > 0.8
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High CPU usage detected"
    - alert: PodCrashLooping
      expr: rate(kube_pod_container_status_restarts_total[5m]) > 0
      for: 2m
      labels:
        severity: critical
      annotations:
        summary: "Pod is crash looping"
EOF
```

---

## 💾 Backup và Maintenance

### **Bước 1: Automated Backups**
```bash
# Cloud SQL backup (đã enable tự động)
gcloud sql operations list --instance=4thitek-postgres

# Create manual backup
gcloud sql backups create --instance=4thitek-postgres

# Kubernetes configs backup
kubectl get all -o yaml > backups/k8s-config-$(date +%Y%m%d).yaml
```

### **Bước 2: Thiết Lập Cron Jobs**
```bash
# Deploy backup cronjob
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-job
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: google/cloud-sdk:alpine
            command:
            - /bin/sh
            - -c
            - |
              gcloud auth activate-service-account --key-file=/var/secrets/google/service_account.json
              kubectl get all -o yaml > /backup/k8s-backup-$(date +%Y%m%d).yaml
              gsutil cp /backup/* gs://4thitek-backups/
            volumeMounts:
            - name: google-cloud-key
              mountPath: /var/secrets/google
              readOnly: true
          volumes:
          - name: google-cloud-key
            secret:
              secretName: backup-key
          restartPolicy: OnFailure
EOF
```

### **Bước 3: Update Procedures**
```bash
#!/bin/bash
# update-deployment.sh

APP_NAME=$1
NEW_VERSION=$2

if [ -z "$APP_NAME" ] || [ -z "$NEW_VERSION" ]; then
    echo "Usage: $0 <app-name> <new-version>"
    exit 1
fi

echo "🔄 Updating $APP_NAME to $NEW_VERSION"

# Build new image
cd fe/$APP_NAME
docker build -t $REGISTRY/$APP_NAME:$NEW_VERSION .
docker push $REGISTRY/$APP_NAME:$NEW_VERSION
cd ../..

# Rolling update
kubectl set image deployment/$APP_NAME $APP_NAME=$REGISTRY/$APP_NAME:$NEW_VERSION

# Monitor rollout
kubectl rollout status deployment/$APP_NAME

echo "✅ Update completed"
```

---

## 📈 Scaling và Optimization

### **Bước 1: Horizontal Pod Autoscaling**
```bash
# Enable metrics server (đã có sẵn trong GKE)
kubectl apply -f - <<EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: fe-main-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: fe-main
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
EOF
```

### **Bước 2: Cluster Autoscaling**
```bash
# Enable cluster autoscaler
gcloud container clusters update 4thitek-dev \
    --region=$REGION \
    --enable-autoscaling \
    --min-nodes=3 \
    --max-nodes=20
```

---

## 🔍 Troubleshooting

### **Common Issues và Solutions**

```bash
# 1. Check pod status
kubectl get pods -o wide
kubectl describe pod <pod-name>

# 2. Check logs
kubectl logs <pod-name> -c <container-name>

# 3. Check services
kubectl get services
kubectl describe service <service-name>

# 4. Check ingress
kubectl get ingress
kubectl describe ingress 4thitek-ingress

# 5. Check SSL certificates
kubectl describe managedcertificate 4thitek-ssl-cert

# 6. Check cluster health
kubectl get nodes
kubectl top nodes
kubectl top pods
```

### **Cost Optimization**
```bash
# Check current costs
gcloud billing budgets list

# Use preemptible nodes for non-critical workloads
gcloud container node-pools create preemptible-pool \
    --cluster=4thitek-dev \
    --region=$REGION \
    --machine-type=e2-standard-2 \
    --preemptible \
    --num-nodes=2

# Scale down during off-hours
kubectl scale deployment fe-main --replicas=1
kubectl scale deployment fe-admin --replicas=1
kubectl scale deployment fe-dealer --replicas=1
```

---

## ✅ Final Checklist

```bash
# Deployment verification script
#!/bin/bash
echo "🔍 Final deployment verification..."

# Check all pods are running
echo "1. Checking pods..."
kubectl get pods | grep -v Running && echo "❌ Some pods not running" || echo "✅ All pods running"

# Check services
echo "2. Checking services..."
kubectl get services

# Check ingress
echo "3. Checking ingress..."
kubectl get ingress

# Check external access
echo "4. Testing external access..."
curl -I https://app.4thitek.com

# Check SSL
echo "5. Checking SSL certificates..."
kubectl describe managedcertificate 4thitek-ssl-cert | grep Status

# Check autoscaling
echo "6. Checking autoscaling..."
kubectl get hpa

echo "🎉 Deployment verification completed!"
```

---

**🎯 Chúc mừng! Dự án 4thitek đã được deploy thành công lên Google Cloud Kubernetes Engine.**

**📚 Next Steps:**
- Monitor application performance qua Google Cloud Console
- Thiết lập alerting rules cho production
- Tối ưu chi phí bằng cách sử dụng preemptible nodes
- Implement CI/CD pipeline với Cloud Build
- Backup và disaster recovery procedures

**💰 Cost Estimate:**
- Development cluster: ~$100-200/month
- Production cluster: ~$300-500/month  
- Cloud SQL + Redis: ~$50-100/month
- Total: ~$150-800/month tùy theo usage

**🔧 Maintenance:**
- Weekly: Update dependencies và security patches  
- Monthly: Review và optimize resource usage
- Quarterly: Update Kubernetes version