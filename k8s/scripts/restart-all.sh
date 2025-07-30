#!/bin/bash

# Restart script for all 4thitek deployments
echo "🔄 Restarting all 4thitek deployments..."
echo "================================================="

# Function to restart deployment safely
restart_deployment() {
    local deployment_name=$1
    
    if kubectl get deployment $deployment_name >/dev/null 2>&1; then
        echo "🔄 Restarting deployment: $deployment_name"
        kubectl rollout restart deployment/$deployment_name
        
        echo "⏳ Waiting for $deployment_name to be ready..."
        kubectl rollout status deployment/$deployment_name
        
        echo "✅ $deployment_name restarted successfully"
    else
        echo "❌ Deployment $deployment_name not found (skipping)"
    fi
    echo "----------------------------------------"
}

# Array of deployments to restart
DEPLOYMENTS=("postgres" "pgbouncer" "pgadmin" "fe-main" "fe-admin" "fe-dealer")

# Track restart results
SUCCESSFUL_RESTARTS=()
FAILED_RESTARTS=()

# Restart each deployment
for deployment in "${DEPLOYMENTS[@]}"; do
    echo ""
    echo "🔄 Processing $deployment..."
    
    if restart_deployment "$deployment"; then
        SUCCESSFUL_RESTARTS+=("$deployment")
    else
        echo "❌ Failed to restart $deployment"
        FAILED_RESTARTS+=("$deployment")
    fi
done

echo ""
echo "📊 RESTART SUMMARY"
echo "================================================="

if [ ${#SUCCESSFUL_RESTARTS[@]} -gt 0 ]; then
    echo "✅ Successfully restarted (${#SUCCESSFUL_RESTARTS[@]}):"
    for deployment in "${SUCCESSFUL_RESTARTS[@]}"; do
        echo "   - $deployment"
    done
fi

if [ ${#FAILED_RESTARTS[@]} -gt 0 ]; then
    echo ""
    echo "❌ Failed restarts (${#FAILED_RESTARTS[@]}):"
    for deployment in "${FAILED_RESTARTS[@]}"; do
        echo "   - $deployment"
    done
    echo ""
    echo "⚠️  Please check the failed deployments and restart them individually."
fi

echo ""
echo "📋 Current pod status:"
echo "----------------------------------------"
kubectl get pods

echo ""
echo "🔍 Check detailed status:"
echo "   bash check-status.sh"

echo ""
if [ ${#FAILED_RESTARTS[@]} -eq 0 ]; then
    echo "🎉 All deployments restarted successfully!"
    exit 0
else
    echo "⚠️  Some deployments failed to restart. Check logs above."
    exit 1
fi