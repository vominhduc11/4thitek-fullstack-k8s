#!/bin/bash

# Deploy Redis Web Interfaces script
echo "🔴 Deploying Redis Web Interfaces..."

# Check if Redis is running
echo "🔍 Checking Redis deployment..."
if ! kubectl get deployment redis >/dev/null 2>&1; then
    echo "❌ Redis is not deployed. Please deploy Redis first:"
    echo "   ./deploy-redis.sh"
    exit 1
fi

echo "✅ Redis found!"

echo ""
echo "📋 Available Redis Web Interfaces:"
echo "1. RedisInsight (Official, Feature-rich)"
echo "2. Redis Commander (Lightweight, Simple)" 
echo "3. phpRedisAdmin (PHP-based)"
echo "4. Deploy All"

read -p "Choose option (1-4): " choice

case $choice in
    1)
        echo "🚀 Deploying RedisInsight..."
        kubectl apply -f ../cache/redis/redis-insight.yaml
        PORT=30081
        INTERFACE="RedisInsight"
        ;;
    2)
        echo "🚀 Deploying Redis Commander..."
        kubectl apply -f ../cache/redis/redis-commander.yaml
        PORT=30082
        INTERFACE="Redis Commander"
        ;;
    3)
        echo "🚀 Deploying phpRedisAdmin..."
        kubectl apply -f ../cache/redis/phpredisadmin.yaml
        PORT=30083
        INTERFACE="phpRedisAdmin"
        ;;
    4)
        echo "🚀 Deploying all Redis interfaces..."
        kubectl apply -f ../cache/redis/redis-insight.yaml
        kubectl apply -f ../cache/redis/redis-commander.yaml
        kubectl apply -f ../cache/redis/phpredisadmin.yaml
        echo ""
        echo "✅ All Redis interfaces deployed!"
        echo ""
        echo "🌐 Access URLs:"
        echo "  RedisInsight:     http://localhost:30081"
        echo "  Redis Commander: http://localhost:30082 (admin/admin123)"
        echo "  phpRedisAdmin:   http://localhost:30083"
        echo ""
        echo "🔍 Check status:"
        echo "  kubectl get pods | grep redis"
        exit 0
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

# Wait for deployment
echo "⏳ Waiting for $INTERFACE to be ready..."
sleep 30

# Check status
echo "📊 Deployment Status:"
kubectl get pods | grep redis

echo ""
echo "✅ $INTERFACE deployment completed!"
echo ""
echo "🌐 Access Information:"
echo "  URL: http://localhost:$PORT"
if [ "$choice" = "2" ]; then
    echo "  Username: admin"
    echo "  Password: admin123"
fi
echo ""
echo "🔧 Redis Connection Details:"
echo "  Host: redis-service"
echo "  Port: 6379"
echo "  (These will be auto-configured in the web interface)"
echo ""
echo "🔍 Monitor deployment:"
echo "  kubectl get pods | grep redis"
echo "  kubectl logs deployment/$INTERFACE"
echo ""
echo "🗑️  To remove:"
echo "  kubectl delete -f ../cache/redis/$(echo $INTERFACE | tr '[:upper:]' '[:lower:]' | tr ' ' '-').yaml"