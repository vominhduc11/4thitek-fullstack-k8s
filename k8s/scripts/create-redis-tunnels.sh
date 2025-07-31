#!/bin/bash

# Create Redis Access Tunnels
echo "🔴 Creating Redis Access Tunnels..."
echo "===================================="

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl first."
    exit 1
fi

# Function to create tunnel
create_tunnel() {
    local service_name=$1
    local local_port=$2
    local remote_port=$3
    local description=$4
    
    echo "🔗 Creating tunnel: $description"
    echo "   Local: http://localhost:$local_port"
    echo "   Service: $service_name:$remote_port"
    
    # Kill existing tunnel if any
    pkill -f "port-forward.*$service_name" 2>/dev/null || true
    
    # Create tunnel in background
    kubectl port-forward svc/$service_name $local_port:$remote_port &
    local pid=$!
    
    echo "   PID: $pid"
    echo "   Status: Starting..."
    sleep 2
    
    # Check if tunnel is working
    if ps -p $pid > /dev/null; then
        echo "   ✅ Tunnel active"
        return 0
    else
        echo "   ❌ Tunnel failed"
        return 1
    fi
}

echo ""
echo "📊 Current Service Status:"
kubectl get svc | grep redis

echo ""
echo "🚀 Creating Port-Forward Tunnels..."
echo ""

# Array of services to tunnel
tunnels_created=0

# Redis main service
if create_tunnel "redis-service" "6379" "6379" "Redis Server"; then
    ((tunnels_created++))
fi

echo ""

# Redis Commander (if pod is running)
if kubectl get pod -l app=redis-commander --field-selector=status.phase=Running -o name &>/dev/null; then
    if create_tunnel "redis-commander-service" "8081" "8081" "Redis Commander"; then
        ((tunnels_created++))
    fi
else
    echo "⚠️  Redis Commander pod not running - skipping tunnel"
fi

echo ""

# Redis Insight (if pod is running)
if kubectl get pod -l app=redis-insight --field-selector=status.phase=Running -o name &>/dev/null; then
    if create_tunnel "redis-insight-service" "8001" "8001" "RedisInsight"; then
        ((tunnels_created++))
    fi
else
    echo "⚠️  RedisInsight pod not running - skipping tunnel"
fi

echo ""

# Redis Web Simple (if pod is running)
if kubectl get pod -l app=redis-web-simple --field-selector=status.phase=Running -o name &>/dev/null; then
    if create_tunnel "redis-web-simple-service" "8080" "80" "Redis Web Portal"; then
        ((tunnels_created++))
    fi
else
    echo "⚠️  Redis Web Portal pod not running - skipping tunnel"
fi

echo ""
echo "📋 Summary:"
echo "==========="
echo "Tunnels created: $tunnels_created"

if [ $tunnels_created -gt 0 ]; then
    echo ""
    echo "🌐 Access URLs:"
    echo "  Redis Server:     localhost:6379 (use Redis CLI)"
    echo "  Redis Commander: http://localhost:8081"
    echo "    🔐 Username: admin"
    echo "    🔐 Password: admin123"
    echo "  RedisInsight:    http://localhost:8001"
    echo "  Redis Web Portal: http://localhost:8080"
    echo ""
    echo "🔧 Test Redis Connection (with authentication):"
    echo "  redis-cli -h localhost -p 6379 -a Redis-Secure-2024! ping"
    echo "  redis-cli -h localhost -p 6379 -a Redis-Secure-2024! info"
    echo ""
    echo "ℹ️  Note: Redis now requires authentication with password: Redis-Secure-2024!"
    echo ""
    echo "🛑 To stop all tunnels:"
    echo "  pkill -f 'kubectl port-forward'"
    echo ""
    echo "💡 Tunnels will run in background. Check with:"
    echo "  ps aux | grep port-forward"
else
    echo ""
    echo "❌ No tunnels could be created."
    echo "   This is likely due to cluster connectivity issues."
    echo ""
    echo "🔍 Troubleshooting:"
    echo "  kubectl get nodes"
    echo "  kubectl get pods | grep redis"
    echo "  kubectl describe pod <redis-pod-name>"
fi

echo ""
echo "📊 Current Cluster Status:"
kubectl get nodes --no-headers | awk '{print "  " $1 ": " $2}'