#!/bin/bash

# Quick tunnel setup for 4thitek platform
# Simple version without extensive error checking

echo "🚀 Starting 4thitek platform tunnels..."

# Kill existing tunnels
pkill -f "kubectl port-forward" 2>/dev/null
sleep 2

# Start all tunnels in background
kubectl port-forward service/postgres-service 5432:5432 &
kubectl port-forward service/pgbouncer-service 5433:5432 &  
kubectl port-forward service/pgadmin-service 8080:80 &
kubectl port-forward service/redis-service 6379:6379 &
kubectl port-forward service/redis-commander-service 8081:8081 &
kubectl port-forward service/redis-insight-service 8001:8001 &
kubectl port-forward service/kafka-ui-service 8082:8080 -n kafka &
kubectl port-forward service/fe-main-service 3000:3000 &
kubectl port-forward service/fe-admin-service 4000:80 &
kubectl port-forward service/fe-dealer-service 5000:80 &

# Wait for tunnels to establish
sleep 3

echo ""
echo "✅ Tunnels started! Access your services:"
echo ""
echo "🗄️  Database Services:"
echo "   📊 pgAdmin:        http://localhost:8080"
echo "   🐘 PostgreSQL:     localhost:5432"
echo "   🔄 pgBouncer:      localhost:5433"
echo ""
echo "🚀 Cache Services:"
echo "   📈 Redis Commander: http://localhost:8081"
echo "   🔧 Redis Insight:   http://localhost:8001"
echo "   📡 Redis Server:    localhost:6379"
echo ""
echo "📨 Messaging:"
echo "   🎛️  Kafka UI:       http://localhost:8082"
echo ""
echo "🌐 Frontend Apps:"
echo "   🌟 Main App:       http://localhost:3000"
echo "   👨‍💼 Admin Portal:   http://localhost:4000"
echo "   🏪 Dealer Portal:  http://localhost:5000"
echo ""
echo "🔑 Credentials are in ACCESS_CREDENTIALS.md"
echo "🛑 To stop all tunnels: pkill -f 'kubectl port-forward'"