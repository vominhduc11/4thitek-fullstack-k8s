#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🚀 Starting deployment of all applications..."
echo "================================================="

# Array of deployment scripts
DEPLOYMENT_SCRIPTS=(
    "deploy-postgres.sh"
    "deploy-pgbouncer.sh"
    "deploy-pgadmin.sh"
    "deploy-kafka.sh"
    "deploy-redis.sh"
    "deploy-fe-main.sh"
    "deploy-fe-admin.sh" 
    "deploy-fe-dealer.sh"
)

# Track deployment results
SUCCESSFUL_DEPLOYMENTS=()
FAILED_DEPLOYMENTS=()

# Deploy each application
for script in "${DEPLOYMENT_SCRIPTS[@]}"; do
    echo ""
    echo "🔄 Running $script..."
    echo "----------------------------------------"
    
    if bash "$SCRIPT_DIR/$script"; then
        echo "✅ $script completed successfully"
        SUCCESSFUL_DEPLOYMENTS+=("$script")
    else
        echo "❌ $script failed"
        FAILED_DEPLOYMENTS+=("$script")
    fi
    
    echo "----------------------------------------"
done

echo ""
echo "📊 DEPLOYMENT SUMMARY"
echo "================================================="

if [ ${#SUCCESSFUL_DEPLOYMENTS[@]} -gt 0 ]; then
    echo "✅ Successful deployments (${#SUCCESSFUL_DEPLOYMENTS[@]}):"
    for deployment in "${SUCCESSFUL_DEPLOYMENTS[@]}"; do
        echo "   - $deployment"
    done
fi

if [ ${#FAILED_DEPLOYMENTS[@]} -gt 0 ]; then
    echo ""
    echo "❌ Failed deployments (${#FAILED_DEPLOYMENTS[@]}):"
    for deployment in "${FAILED_DEPLOYMENTS[@]}"; do
        echo "   - $deployment"
    done
    echo ""
    echo "⚠️  Please check the failed deployments above and re-run them individually."
    exit 1
else
    echo ""
    echo "🎉 All applications deployed successfully!"
fi

echo ""
echo "🌐 Direct IP Access (minikube IP: 192.168.49.2):"
echo "   - pgAdmin: http://192.168.49.2:30080 (admin@example.com / admin123)"
echo "   - Kafka UI: http://192.168.49.2:30090 (admin / admin123)"
echo "   - Kafka External: 192.168.49.2:30093"
echo "   - Redis External: 192.168.49.2:30379"
echo ""
echo "🔗 Frontend Apps (via Ingress - need minikube tunnel):"
echo "   - Main:    http://192.168.49.2/ (default route)"
echo "   - Admin:   http://192.168.49.2/ (need path routing or use port-forward)"
echo "   - Dealer:  http://192.168.49.2/ (need path routing or use port-forward)"
echo ""
echo "📝 Alternative: Use domains with hosts file:"
echo "   Add to C:\\Windows\\System32\\drivers\\etc\\hosts:"
echo "   192.168.49.2 main.4thitek.com admin.4thitek.com dealer.4thitek.com"
echo ""
echo "🔗 Port-forward commands for local access:"
echo "   - PostgreSQL: kubectl port-forward service/postgres-service 5432:5432"
echo "   - PgBouncer:  kubectl port-forward service/pgbouncer-service 5432:5432"
echo "   - pgAdmin:    kubectl port-forward service/pgadmin-service 8080:80"
echo "   - Kafka:      kubectl port-forward service/kafka-service 9092:9092 -n kafka"
echo "   - Zookeeper:  kubectl port-forward service/zookeeper-service 2181:2181 -n kafka"
echo "   - Redis:      kubectl port-forward service/redis-service 6379:6379"
echo "   - Main:       kubectl port-forward service/fe-main-service 4000:3000"
echo "   - Admin:      kubectl port-forward service/fe-admin-service 5000:80"
echo "   - Dealer:     kubectl port-forward service/fe-dealer-service 6000:80"