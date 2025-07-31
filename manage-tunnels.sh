#!/bin/bash

# 4thitek Platform Tunnel Management Script

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_menu() {
    clear
    echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         4THITEK TUNNEL MANAGER                ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Select an option:"
    echo ""
    echo "1) Start all tunnels"
    echo "2) Start database tunnels only"
    echo "3) Start cache tunnels only"
    echo "4) Start frontend tunnels only"
    echo "5) Show tunnel status"
    echo "6) Test connectivity"
    echo "7) Stop all tunnels"
    echo "8) Show access URLs"
    echo "9) Exit"
    echo ""
    echo -n "Enter your choice [1-9]: "
}

start_all_tunnels() {
    echo -e "${BLUE}Starting all tunnels...${NC}"
    ./create-all-tunnels.sh
}

start_database_tunnels() {
    echo -e "${BLUE}Starting database tunnels...${NC}"
    pkill -f "kubectl port-forward.*postgres" 2>/dev/null
    pkill -f "kubectl port-forward.*pgadmin" 2>/dev/null
    pkill -f "kubectl port-forward.*pgbouncer" 2>/dev/null
    
    kubectl port-forward service/postgres-service 5432:5432 &
    kubectl port-forward service/pgbouncer-service 5433:5432 &
    kubectl port-forward service/pgadmin-service 8080:80 &
    
    echo -e "${GREEN}Database tunnels started:${NC}"
    echo "  📊 pgAdmin: http://localhost:8080"
    echo "  🐘 PostgreSQL: localhost:5432"
    echo "  🔄 pgBouncer: localhost:5433"
}

start_cache_tunnels() {
    echo -e "${BLUE}Starting cache tunnels...${NC}"
    pkill -f "kubectl port-forward.*redis" 2>/dev/null
    
    kubectl port-forward service/redis-service 6379:6379 &
    kubectl port-forward service/redis-commander-service 8081:8081 &
    kubectl port-forward service/redis-insight-service 8001:8001 &
    
    echo -e "${GREEN}Cache tunnels started:${NC}"
    echo "  🚀 Redis Commander: http://localhost:8081"
    echo "  📈 Redis Insight: http://localhost:8001"
    echo "  📡 Redis Server: localhost:6379"
}

start_frontend_tunnels() {
    echo -e "${BLUE}Starting frontend tunnels...${NC}"
    pkill -f "kubectl port-forward.*fe-" 2>/dev/null
    
    kubectl port-forward service/fe-main-service 3000:3000 &
    kubectl port-forward service/fe-admin-service 4000:80 &
    kubectl port-forward service/fe-dealer-service 5000:80 &
    
    echo -e "${GREEN}Frontend tunnels started:${NC}"
    echo "  🌟 Main App: http://localhost:3000"
    echo "  👨‍💼 Admin Portal: http://localhost:4000"
    echo "  🏪 Dealer Portal: http://localhost:5000"
}

show_tunnel_status() {
    echo -e "${BLUE}Active tunnel status:${NC}"
    echo ""
    
    local tunnels=$(ps aux | grep "kubectl port-forward" | grep -v grep)
    
    if [ -z "$tunnels" ]; then
        echo -e "${YELLOW}No active tunnels found${NC}"
    else
        echo "$tunnels" | while read line; do
            local service=$(echo "$line" | grep -o "service/[^ ]*" | head -1)
            local port=$(echo "$line" | grep -o "[0-9]*:[0-9]*" | head -1)
            if [ ! -z "$service" ] && [ ! -z "$port" ]; then
                echo -e "  ${GREEN}✅${NC} $service → localhost:${port%%:*}"
            fi
        done
    fi
}

test_connectivity() {
    echo -e "${BLUE}Testing service connectivity...${NC}"
    echo ""
    
    # Test web services
    local services=(
        "http://localhost:8080|pgAdmin"
        "http://localhost:8081|Redis Commander"
        "http://localhost:8082|Kafka UI"
        "http://localhost:3000|Main App"
        "http://localhost:4000|Admin Portal"
        "http://localhost:5000|Dealer Portal"
    )
    
    for service_info in "${services[@]}"; do
        local url=$(echo "$service_info" | cut -d'|' -f1)
        local name=$(echo "$service_info" | cut -d'|' -f2)
        
        if curl -s --connect-timeout 3 "$url" > /dev/null 2>&1; then
            echo -e "  ${GREEN}✅${NC} $name is accessible"
        else
            echo -e "  ${RED}❌${NC} $name is not responding"
        fi
    done
}

stop_all_tunnels() {
    echo -e "${BLUE}Stopping all tunnels...${NC}"
    pkill -f "kubectl port-forward" 2>/dev/null || true
    echo -e "${GREEN}All tunnels stopped${NC}"
}

show_access_urls() {
    echo -e "${BLUE}Service Access URLs:${NC}"
    echo ""
    echo -e "${YELLOW}Database Services:${NC}"
    echo "  📊 pgAdmin:         http://localhost:8080"
    echo "  🐘 PostgreSQL:      localhost:5432"
    echo "  🔄 pgBouncer:       localhost:5433"
    echo ""
    echo -e "${YELLOW}Cache Services:${NC}"
    echo "  🚀 Redis Commander: http://localhost:8081"
    echo "  📈 Redis Insight:   http://localhost:8001"
    echo "  📡 Redis Server:    localhost:6379"
    echo ""
    echo -e "${YELLOW}Messaging:${NC}"
    echo "  📨 Kafka UI:        http://localhost:8082"
    echo ""
    echo -e "${YELLOW}Frontend Apps:${NC}"
    echo "  🌟 Main App:        http://localhost:3000"
    echo "  👨‍💼 Admin Portal:    http://localhost:4000"
    echo "  🏪 Dealer Portal:   http://localhost:5000"
    echo ""
    echo -e "${YELLOW}Credentials are available in: ACCESS_CREDENTIALS.md${NC}"
}

# Main loop
while true; do
    show_menu
    read choice
    
    case $choice in
        1) start_all_tunnels ;;
        2) start_database_tunnels ;;
        3) start_cache_tunnels ;;
        4) start_frontend_tunnels ;;
        5) show_tunnel_status ;;
        6) test_connectivity ;;
        7) stop_all_tunnels ;;
        8) show_access_urls ;;
        9) echo "Goodbye!"; exit 0 ;;
        *) echo -e "${RED}Invalid option. Please try again.${NC}" ;;
    esac
    
    echo ""
    echo "Press Enter to continue..."
    read
done