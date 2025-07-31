# 🌐 4thitek Platform - Service Tunnel Access Guide

## 📋 Table of Contents
- [Quick Access Commands](#quick-access-commands)
- [Database Services](#database-services)
- [Cache Services](#cache-services)
- [Messaging Services](#messaging-services)
- [Frontend Applications](#frontend-applications)
- [Automated Tunnel Scripts](#automated-tunnel-scripts)
- [Monitoring & Management](#monitoring--management)
- [Troubleshooting](#troubleshooting)

---

## 🚀 Quick Access Commands

### **Single Command - All Essential Services**
```bash
# Run all tunnels in background (recommended)
kubectl port-forward service/postgres-service 5432:5432 &
kubectl port-forward service/pgadmin-service 8080:80 &
kubectl port-forward service/redis-service 6379:6379 &
kubectl port-forward service/redis-commander-service 8081:8081 &
kubectl port-forward service/kafka-ui-service 8082:8080 -n kafka &
kubectl port-forward service/fe-main-service 3000:3000 &
kubectl port-forward service/fe-admin-service 4000:80 &
kubectl port-forward service/fe-dealer-service 5000:80 &

echo "🌐 All tunnels started! Access URLs:"
echo "📊 pgAdmin: http://localhost:8080"
echo "🚀 Redis Commander: http://localhost:8081"
echo "📨 Kafka UI: http://localhost:8082"
echo "🌟 Main App: http://localhost:3000"
echo "👨‍💼 Admin Portal: http://localhost:4000"
echo "🏪 Dealer Portal: http://localhost:5000"
```

---

## 🗄️ Database Services

### **PostgreSQL Database**
```bash
# Direct PostgreSQL access
kubectl port-forward service/postgres-service 5432:5432

# Connection command
psql -h localhost -p 5432 -U postgres -d 4thitek_db
# Password: PostgreSQL-Strong-P@ss2024!
```

### **pgBouncer Connection Pooler**
```bash
# pgBouncer access (recommended for applications)
kubectl port-forward service/pgbouncer-service 5433:5432

# Connection command
psql -h localhost -p 5433 -U postgres -d 4thitek_db
# Password: PostgreSQL-Strong-P@ss2024!
```

### **pgAdmin Database Management**
```bash
# pgAdmin web interface
kubectl port-forward service/pgadmin-service 8080:80

# Access: http://localhost:8080
# Email: admin@4thitek.com
# Password: Strong-P@ssw0rd-2024!
```

---

## 🚀 Cache Services

### **Redis Cache Server**
```bash
# Redis server access
kubectl port-forward service/redis-service 6379:6379

# Redis CLI connection
redis-cli -h localhost -p 6379 -a Redis-Secure-2024!

# Test connection
redis-cli -h localhost -p 6379 -a Redis-Secure-2024! ping
```

### **Redis Commander (Web Interface)**
```bash
# Redis Commander web interface
kubectl port-forward service/redis-commander-service 8081:8081

# Access: http://localhost:8081
# Username: admin
# Password: admin123
```

### **Redis Insight (Analytics)**
```bash
# Redis Insight analytics interface
kubectl port-forward service/redis-insight-service 8001:8001

# Access: http://localhost:8001
# No authentication required
```

### **Redis Web Simple**
```bash
# Simple Redis web interface
kubectl port-forward service/redis-web-simple-service 8002:80

# Access: http://localhost:8002
# No authentication required
```

---

## 📨 Messaging Services

### **Kafka UI (Management Interface)**
```bash
# Kafka UI web interface
kubectl port-forward service/kafka-ui-service 8082:8080 -n kafka

# Access: http://localhost:8082
# Username: admin
# Password: Kafka-Admin-2024!
```

### **Direct Kafka Access (Advanced)**
```bash
# Access Kafka broker directly (for development)
kubectl port-forward service/kafka-headless 9092:9092 -n kafka

# List topics
kubectl exec -it kafka-0 -n kafka -- kafka-topics --bootstrap-server localhost:9092 --list

# Create topic
kubectl exec -it kafka-0 -n kafka -- kafka-topics --bootstrap-server localhost:9092 --create --topic test-topic --partitions 3 --replication-factor 3
```

### **Zookeeper Access (Advanced)**
```bash
# Access Zookeeper directly (for development)
kubectl port-forward service/zookeeper-headless 2181:2181 -n kafka

# Zookeeper CLI
kubectl exec -it zookeeper-0 -n kafka -- zkCli.sh -server localhost:2181
```

---

## 🌐 Frontend Applications

### **Main Application (fe-main)**
```bash
# Main customer-facing application
kubectl port-forward service/fe-main-service 3000:3000

# Access: http://localhost:3000
# Next.js application
```

### **Admin Portal (fe-admin)**
```bash
# Administrative dashboard
kubectl port-forward service/fe-admin-service 4000:80

# Access: http://localhost:4000
# React admin interface
```

### **Dealer Portal (fe-dealer)**
```bash
# Dealer management interface
kubectl port-forward service/fe-dealer-service 5000:80

# Access: http://localhost:5000
# React dealer portal
```

---

## 🤖 Automated Tunnel Scripts

### **Create All Tunnels Script**
```bash
#!/bin/bash
# File: create-all-tunnels.sh

echo "🚀 Starting all service tunnels for 4thitek platform..."

# Kill existing port-forwards
echo "🧹 Cleaning up existing tunnels..."
pkill -f "kubectl port-forward" 2>/dev/null

# Wait a moment for cleanup
sleep 2

# Database services
echo "🗄️ Starting database tunnels..."
kubectl port-forward service/postgres-service 5432:5432 &
kubectl port-forward service/pgbouncer-service 5433:5432 &
kubectl port-forward service/pgadmin-service 8080:80 &

# Cache services
echo "🚀 Starting cache tunnels..."
kubectl port-forward service/redis-service 6379:6379 &
kubectl port-forward service/redis-commander-service 8081:8081 &
kubectl port-forward service/redis-insight-service 8001:8001 &
kubectl port-forward service/redis-web-simple-service 8002:80 &

# Messaging services
echo "📨 Starting messaging tunnels..."
kubectl port-forward service/kafka-ui-service 8082:8080 -n kafka &

# Frontend applications
echo "🌐 Starting frontend tunnels..."
kubectl port-forward service/fe-main-service 3000:3000 &
kubectl port-forward service/fe-admin-service 4000:80 &
kubectl port-forward service/fe-dealer-service 5000:80 &

# Wait for tunnels to establish
sleep 3

echo ""
echo "✅ All tunnels started successfully!"
echo ""
echo "🌐 Access URLs:"
echo "┌─────────────────────────────────────────────────────────┐"
echo "│                    DATABASE SERVICES                    │"
echo "├─────────────────────────────────────────────────────────┤"
echo "│ 📊 pgAdmin:          http://localhost:8080             │"
echo "│ 🐘 PostgreSQL:       localhost:5432                    │"
echo "│ 🔄 pgBouncer:        localhost:5433                    │"
echo "├─────────────────────────────────────────────────────────┤"
echo "│                     CACHE SERVICES                      │"
echo "├─────────────────────────────────────────────────────────┤"
echo "│ 🚀 Redis Commander:  http://localhost:8081             │"
echo "│ 📈 Redis Insight:    http://localhost:8001             │"
echo "│ 🔧 Redis Simple:     http://localhost:8002             │"
echo "│ 📡 Redis Server:     localhost:6379                    │"
echo "├─────────────────────────────────────────────────────────┤"
echo "│                   MESSAGING SERVICES                    │"
echo "├─────────────────────────────────────────────────────────┤"
echo "│ 📨 Kafka UI:         http://localhost:8082             │"
echo "├─────────────────────────────────────────────────────────┤"
echo "│                  FRONTEND APPLICATIONS                  │"
echo "├─────────────────────────────────────────────────────────┤"
echo "│ 🌟 Main App:         http://localhost:3000             │"
echo "│ 👨‍💼 Admin Portal:     http://localhost:4000             │"
echo "│ 🏪 Dealer Portal:     http://localhost:5000             │"
echo "└─────────────────────────────────────────────────────────┘"
echo ""
echo "🔐 Credentials available in: ACCESS_CREDENTIALS.md"
echo "🆘 Troubleshooting guide: TROUBLESHOOTING.md"
echo ""
echo "⚠️  To stop all tunnels: pkill -f 'kubectl port-forward'"
```

### **Database Only Tunnels**
```bash
#!/bin/bash
# File: create-database-tunnels.sh

echo "🗄️ Starting database service tunnels..."
pkill -f "kubectl port-forward.*postgres" 2>/dev/null
pkill -f "kubectl port-forward.*pgadmin" 2>/dev/null
pkill -f "kubectl port-forward.*pgbouncer" 2>/dev/null

kubectl port-forward service/postgres-service 5432:5432 &
kubectl port-forward service/pgbouncer-service 5433:5432 &
kubectl port-forward service/pgadmin-service 8080:80 &

echo "✅ Database tunnels started:"
echo "  📊 pgAdmin: http://localhost:8080"
echo "  🐘 PostgreSQL: localhost:5432"
echo "  🔄 pgBouncer: localhost:5433"
```

### **Cache Only Tunnels**
```bash
#!/bin/bash
# File: create-cache-tunnels.sh

echo "🚀 Starting cache service tunnels..."
pkill -f "kubectl port-forward.*redis" 2>/dev/null

kubectl port-forward service/redis-service 6379:6379 &
kubectl port-forward service/redis-commander-service 8081:8081 &
kubectl port-forward service/redis-insight-service 8001:8001 &
kubectl port-forward service/redis-web-simple-service 8002:80 &

echo "✅ Cache tunnels started:"
echo "  🚀 Redis Commander: http://localhost:8081"
echo "  📈 Redis Insight: http://localhost:8001"
echo "  🔧 Redis Simple: http://localhost:8002"
echo "  📡 Redis Server: localhost:6379"
```

### **Frontend Only Tunnels**
```bash
#!/bin/bash
# File: create-frontend-tunnels.sh

echo "🌐 Starting frontend application tunnels..."
pkill -f "kubectl port-forward.*fe-" 2>/dev/null

kubectl port-forward service/fe-main-service 3000:3000 &
kubectl port-forward service/fe-admin-service 4000:80 &
kubectl port-forward service/fe-dealer-service 5000:80 &

echo "✅ Frontend tunnels started:"
echo "  🌟 Main App: http://localhost:3000"
echo "  👨‍💼 Admin Portal: http://localhost:4000"
echo "  🏪 Dealer Portal: http://localhost:5000"
```

---

## 📊 Monitoring & Management

### **Health Check with Tunnels**
```bash
#!/bin/bash
# File: health-check-tunnels.sh

echo "🩺 Health checking all services via tunnels..."

# Test database
echo "Testing PostgreSQL..."
if pg_isready -h localhost -p 5432 -U postgres; then
    echo "✅ PostgreSQL: OK"
else
    echo "❌ PostgreSQL: FAILED"
fi

# Test Redis
echo "Testing Redis..."
if redis-cli -h localhost -p 6379 -a Redis-Secure-2024! ping | grep -q PONG; then
    echo "✅ Redis: OK"
else
    echo "❌ Redis: FAILED"
fi

# Test web interfaces
echo "Testing web interfaces..."
if curl -s http://localhost:8080 > /dev/null; then
    echo "✅ pgAdmin: OK"
else
    echo "❌ pgAdmin: FAILED"
fi

if curl -s http://localhost:8081 > /dev/null; then
    echo "✅ Redis Commander: OK"
else
    echo "❌ Redis Commander: FAILED"
fi

if curl -s http://localhost:8082 > /dev/null; then
    echo "✅ Kafka UI: OK"
else
    echo "❌ Kafka UI: FAILED"
fi

if curl -s http://localhost:3000 > /dev/null; then
    echo "✅ Main App: OK"
else
    echo "❌ Main App: FAILED"
fi

echo "🏁 Health check completed!"
```

### **Tunnel Status Check**
```bash
#!/bin/bash
# File: check-tunnel-status.sh

echo "🔍 Checking active tunnel status..."
echo ""

TUNNELS=$(ps aux | grep "kubectl port-forward" | grep -v grep)

if [ -z "$TUNNELS" ]; then
    echo "❌ No active tunnels found"
    echo "💡 Run ./create-all-tunnels.sh to start tunnels"
else
    echo "✅ Active tunnels:"
    echo "$TUNNELS" | while read line; do
        SERVICE=$(echo "$line" | grep -o "service/[^ ]*" | head -1)
        PORT=$(echo "$line" | grep -o "[0-9]*:[0-9]*" | head -1)
        echo "  🌐 $SERVICE → localhost:${PORT%%:*}"
    done
fi

echo ""
echo "🌐 Test access:"
echo "  curl http://localhost:8080  # pgAdmin"
echo "  curl http://localhost:8081  # Redis Commander"
echo "  curl http://localhost:8082  # Kafka UI"
echo "  curl http://localhost:3000  # Main App"
```

---

## 🆘 Troubleshooting

### **Common Issues & Solutions**

#### **Port Already in Use**
```bash
# Find process using port
lsof -i :8080

# Kill specific port-forward
pkill -f "kubectl port-forward.*8080"

# Kill all port-forwards
pkill -f "kubectl port-forward"
```

#### **Connection Refused**
```bash
# Check if service exists
kubectl get services
kubectl get services -n kafka

# Check if pods are running
kubectl get pods | grep <service-name>

# Restart port-forward
pkill -f "kubectl port-forward.*<service-name>"
kubectl port-forward service/<service-name> <local-port>:<service-port>
```

#### **Authentication Failed**
```bash
# Check credentials in secrets
kubectl get secret <secret-name> -o yaml
kubectl get secret <secret-name> -o jsonpath='{.data.<key>}' | base64 -d

# Verify service is ready
kubectl describe service <service-name>
kubectl logs <pod-name>
```

### **Cleanup Commands**
```bash
# Stop all tunnels
pkill -f "kubectl port-forward"

# Verify all stopped
ps aux | grep "kubectl port-forward" | grep -v grep

# Restart specific service tunnel
kubectl port-forward service/<service-name> <local-port>:<service-port> &
```

---

## 🚀 Quick Start Guide

### **1. Make Scripts Executable**
```bash
chmod +x create-all-tunnels.sh
chmod +x create-database-tunnels.sh
chmod +x create-cache-tunnels.sh
chmod +x create-frontend-tunnels.sh
chmod +x health-check-tunnels.sh
chmod +x check-tunnel-status.sh
```

### **2. Start All Tunnels**
```bash
./create-all-tunnels.sh
```

### **3. Verify Everything Works**
```bash
./health-check-tunnels.sh
```

### **4. Access Services**
- **pgAdmin**: http://localhost:8080 (admin@4thitek.com / Strong-P@ssw0rd-2024!)
- **Redis Commander**: http://localhost:8081 (admin / admin123)
- **Kafka UI**: http://localhost:8082 (admin / Kafka-Admin-2024!)
- **Main App**: http://localhost:3000
- **Admin Portal**: http://localhost:4000
- **Dealer Portal**: http://localhost:5000

---

## 📞 Support

### **Getting Help**
- 📚 Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for detailed solutions
- 🔐 See [ACCESS_CREDENTIALS.md](./ACCESS_CREDENTIALS.md) for login information
- 📋 Review [KUBERNETES_COMMANDS.md](./KUBERNETES_COMMANDS.md) for kubectl reference

### **Emergency Reset**
```bash
# Complete tunnel reset
pkill -f "kubectl port-forward"
./create-all-tunnels.sh
./health-check-tunnels.sh
```

---

**🌐 Ready to access your services! All tunnels provide secure localhost access to your 4thitek platform.**

**📝 Save this file for quick reference and share with your team for consistent access patterns.**

**🔐 Remember: Keep your credentials secure and never share them in public repositories.**