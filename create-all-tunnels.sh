#!/bin/bash

# 4thitek Platform - Complete Tunnel Access Script
# This script creates port-forward tunnels for all essential services

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}$1${NC}"
}

# Function to check if a service exists
check_service() {
    local service_name=$1
    local namespace=${2:-default}
    
    if [ "$namespace" != "default" ]; then
        kubectl get service "$service_name" -n "$namespace" &>/dev/null
    else
        kubectl get service "$service_name" &>/dev/null
    fi
    return $?
}

# Function to check if a port is available
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 1  # Port is in use
    else
        return 0  # Port is available
    fi
}

# Function to start a tunnel
start_tunnel() {
    local service_name=$1
    local local_port=$2
    local service_port=$3
    local namespace=${4:-default}
    local description=$5
    
    print_status "Starting tunnel for $description..."
    
    # Check if service exists
    if ! check_service "$service_name" "$namespace"; then
        print_error "Service $service_name not found in namespace $namespace"
        return 1
    fi
    
    # Check if port is available
    if ! check_port "$local_port"; then
        print_warning "Port $local_port is already in use, trying to kill existing process..."
        pkill -f "kubectl port-forward.*$local_port" 2>/dev/null
        sleep 1
        
        if ! check_port "$local_port"; then
            print_error "Could not free port $local_port"
            return 1
        fi
    fi
    
    # Start the tunnel
    if [ "$namespace" != "default" ]; then
        kubectl port-forward service/"$service_name" "$local_port:$service_port" -n "$namespace" &>/dev/null &
    else
        kubectl port-forward service/"$service_name" "$local_port:$service_port" &>/dev/null &
    fi
    
    local tunnel_pid=$!
    
    # Wait a moment and check if tunnel started successfully
    sleep 2
    if kill -0 "$tunnel_pid" 2>/dev/null; then
        print_success "$description tunnel started on port $local_port"
        return 0
    else
        print_error "Failed to start tunnel for $description"
        return 1
    fi
}

# Function to display header
show_header() {
    clear
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                     🚀 4THITEK PLATFORM TUNNEL MANAGER                      ║${NC}"
    echo -e "${CYAN}║                         Complete Service Access Setup                        ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Function to cleanup existing tunnels
cleanup_tunnels() {
    print_header "🧹 Cleaning up existing tunnels..."
    
    # Find and kill existing kubectl port-forward processes
    local existing_tunnels=$(ps aux | grep "kubectl port-forward" | grep -v grep | wc -l)
    
    if [ "$existing_tunnels" -gt 0 ]; then
        print_status "Found $existing_tunnels existing tunnel(s), cleaning up..."
        pkill -f "kubectl port-forward" 2>/dev/null
        sleep 3
        print_success "Existing tunnels cleaned up"
    else
        print_status "No existing tunnels found"
    fi
    echo ""
}

# Function to verify cluster connectivity
verify_cluster() {
    print_header "🔍 Verifying cluster connectivity..."
    
    if ! kubectl cluster-info &>/dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        print_error "Please ensure kubectl is configured and cluster is accessible"
        exit 1
    fi
    
    print_success "Cluster connectivity verified"
    echo ""
}

# Function to start all tunnels
start_all_tunnels() {
    print_header "🌐 Starting all service tunnels..."
    echo ""
    
    local success_count=0
    local total_count=0
    
    # Database Services
    print_header "🗄️  Database Services"
    
    ((total_count++))
    if start_tunnel "postgres-service" "5432" "5432" "default" "PostgreSQL Database"; then
        ((success_count++))
    fi
    
    ((total_count++))
    if start_tunnel "pgbouncer-service" "5433" "5432" "default" "pgBouncer Connection Pool"; then
        ((success_count++))
    fi
    
    ((total_count++))
    if start_tunnel "pgadmin-service" "8080" "80" "default" "pgAdmin Web UI"; then
        ((success_count++))
    fi
    
    echo ""
    
    # Cache Services
    print_header "🚀 Cache Services"
    
    ((total_count++))
    if start_tunnel "redis-service" "6379" "6379" "default" "Redis Server"; then
        ((success_count++))
    fi
    
    ((total_count++))
    if start_tunnel "redis-commander-service" "8081" "8081" "default" "Redis Commander"; then
        ((success_count++))
    fi
    
    ((total_count++))
    if start_tunnel "redis-insight-service" "8001" "8001" "default" "Redis Insight"; then
        ((success_count++))
    fi
    
    ((total_count++))
    if start_tunnel "redis-web-simple-service" "8002" "80" "default" "Redis Web Simple"; then
        ((success_count++))
    fi
    
    echo ""
    
    # Messaging Services
    print_header "📨 Messaging Services"
    
    ((total_count++))
    if start_tunnel "kafka-ui-service" "8082" "8080" "kafka" "Kafka UI"; then
        ((success_count++))
    fi
    
    echo ""
    
    # Frontend Applications
    print_header "🌐 Frontend Applications"
    
    ((total_count++))
    if start_tunnel "fe-main-service" "3000" "3000" "default" "Main Application"; then
        ((success_count++))
    fi
    
    ((total_count++))
    if start_tunnel "fe-admin-service" "4000" "80" "default" "Admin Portal"; then
        ((success_count++))
    fi
    
    ((total_count++))
    if start_tunnel "fe-dealer-service" "5000" "80" "default" "Dealer Portal"; then
        ((success_count++))
    fi
    
    echo ""
    print_status "Started $success_count out of $total_count tunnels"
    
    return $((total_count - success_count))
}

# Function to display access information
show_access_info() {
    echo ""
    print_header "🌐 Service Access Information"
    echo ""
    echo -e "${WHITE}┌─────────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│                           DATABASE SERVICES                                │${NC}"
    echo -e "${WHITE}├─────────────────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${WHITE}│${NC} 📊 pgAdmin:           ${CYAN}http://localhost:8080${NC}"
    echo -e "${WHITE}│${NC}    Email:             ${YELLOW}admin@4thitek.com${NC}"
    echo -e "${WHITE}│${NC}    Password:          ${YELLOW}Strong-P@ssw0rd-2024!${NC}"
    echo -e "${WHITE}│${NC}"
    echo -e "${WHITE}│${NC} 🐘 PostgreSQL:        ${CYAN}localhost:5432${NC}"
    echo -e "${WHITE}│${NC}    Database:          ${YELLOW}4thitek_db${NC}"
    echo -e "${WHITE}│${NC}    Username:          ${YELLOW}postgres${NC}"
    echo -e "${WHITE}│${NC}    Password:          ${YELLOW}PostgreSQL-Strong-P@ss2024!${NC}"
    echo -e "${WHITE}│${NC}"
    echo -e "${WHITE}│${NC} 🔄 pgBouncer:         ${CYAN}localhost:5433${NC}"
    echo -e "${WHITE}│${NC}    (Connection Pool - same credentials as PostgreSQL)"
    echo -e "${WHITE}├─────────────────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${WHITE}│                            CACHE SERVICES                                  │${NC}"
    echo -e "${WHITE}├─────────────────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${WHITE}│${NC} 🚀 Redis Commander:   ${CYAN}http://localhost:8081${NC}"
    echo -e "${WHITE}│${NC}    Username:          ${YELLOW}admin${NC}"
    echo -e "${WHITE}│${NC}    Password:          ${YELLOW}admin123${NC}"
    echo -e "${WHITE}│${NC}"
    echo -e "${WHITE}│${NC} 📈 Redis Insight:     ${CYAN}http://localhost:8001${NC}"
    echo -e "${WHITE}│${NC}    (No authentication required)"
    echo -e "${WHITE}│${NC}"
    echo -e "${WHITE}│${NC} 🔧 Redis Web Simple:  ${CYAN}http://localhost:8002${NC}"
    echo -e "${WHITE}│${NC}    (No authentication required)"
    echo -e "${WHITE}│${NC}"
    echo -e "${WHITE}│${NC} 📡 Redis Server:      ${CYAN}localhost:6379${NC}"
    echo -e "${WHITE}│${NC}    Password:          ${YELLOW}Redis-Secure-2024!${NC}"
    echo -e "${WHITE}├─────────────────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${WHITE}│                          MESSAGING SERVICES                                │${NC}"
    echo -e "${WHITE}├─────────────────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${WHITE}│${NC} 📨 Kafka UI:          ${CYAN}http://localhost:8082${NC}"
    echo -e "${WHITE}│${NC}    Username:          ${YELLOW}admin${NC}"
    echo -e "${WHITE}│${NC}    Password:          ${YELLOW}Kafka-Admin-2024!${NC}"
    echo -e "${WHITE}├─────────────────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${WHITE}│                        FRONTEND APPLICATIONS                               │${NC}"
    echo -e "${WHITE}├─────────────────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${WHITE}│${NC} 🌟 Main Application:  ${CYAN}http://localhost:3000${NC}"
    echo -e "${WHITE}│${NC}    (Next.js Customer App)"
    echo -e "${WHITE}│${NC}"
    echo -e "${WHITE}│${NC} 👨‍💼 Admin Portal:      ${CYAN}http://localhost:4000${NC}"
    echo -e "${WHITE}│${NC}    (React Admin Dashboard)"
    echo -e "${WHITE}│${NC}"
    echo -e "${WHITE}│${NC} 🏪 Dealer Portal:     ${CYAN}http://localhost:5000${NC}"
    echo -e "${WHITE}│${NC}    (React Dealer Interface)"
    echo -e "${WHITE}└─────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# Function to show connection commands
show_connection_commands() {
    print_header "🔌 Quick Connection Commands"
    echo ""
    echo -e "${WHITE}Database Connections:${NC}"
    echo -e "${CYAN}  psql -h localhost -p 5432 -U postgres -d 4thitek_db${NC}  # Direct PostgreSQL"
    echo -e "${CYAN}  psql -h localhost -p 5433 -U postgres -d 4thitek_db${NC}  # Via pgBouncer"
    echo ""
    echo -e "${WHITE}Redis Connection:${NC}"
    echo -e "${CYAN}  redis-cli -h localhost -p 6379 -a Redis-Secure-2024!${NC}  # Redis CLI"
    echo ""
    echo -e "${WHITE}Health Checks:${NC}"
    echo -e "${CYAN}  curl http://localhost:8080${NC}  # pgAdmin"
    echo -e "${CYAN}  curl http://localhost:8081${NC}  # Redis Commander"
    echo -e "${CYAN}  curl http://localhost:8082${NC}  # Kafka UI"
    echo -e "${CYAN}  curl http://localhost:3000${NC}  # Main App"
    echo ""
}

# Function to show tunnel status
show_tunnel_status() {
    print_header "📊 Active Tunnel Status"
    echo ""
    
    local tunnels=$(ps aux | grep "kubectl port-forward" | grep -v grep)
    
    if [ -z "$tunnels" ]; then
        print_warning "No active tunnels found"
    else
        echo -e "${WHITE}Active Tunnels:${NC}"
        echo "$tunnels" | while read line; do
            local service=$(echo "$line" | grep -o "service/[^ ]*" | head -1)
            local port=$(echo "$line" | grep -o "[0-9]*:[0-9]*" | head -1)
            if [ ! -z "$service" ] && [ ! -z "$port" ]; then
                echo -e "  ${GREEN}✅${NC} $service → localhost:${port%%:*}"
            fi
        done
    fi
    echo ""
}

# Function to show management commands
show_management_commands() {
    print_header "🛠️  Tunnel Management Commands"
    echo ""
    echo -e "${WHITE}Stop all tunnels:${NC}"
    echo -e "${CYAN}  pkill -f 'kubectl port-forward'${NC}"
    echo ""
    echo -e "${WHITE}Check tunnel status:${NC}"
    echo -e "${CYAN}  ps aux | grep 'kubectl port-forward' | grep -v grep${NC}"
    echo ""
    echo -e "${WHITE}Restart this script:${NC}"
    echo -e "${CYAN}  ./create-all-tunnels.sh${NC}"
    echo ""
    echo -e "${WHITE}View logs for specific service:${NC}"
    echo -e "${CYAN}  kubectl logs -f deployment/<service-name>${NC}"
    echo ""
}

# Function to test service connectivity
test_connectivity() {
    print_header "🔍 Testing Service Connectivity"
    echo ""
    
    # Test web services
    local web_services=(
        "http://localhost:8080|pgAdmin"
        "http://localhost:8081|Redis Commander"
        "http://localhost:8001|Redis Insight"
        "http://localhost:8002|Redis Web Simple"
        "http://localhost:8082|Kafka UI"
        "http://localhost:3000|Main App"
        "http://localhost:4000|Admin Portal"
        "http://localhost:5000|Dealer Portal"
    )
    
    for service_info in "${web_services[@]}"; do
        local url=$(echo "$service_info" | cut -d'|' -f1)
        local name=$(echo "$service_info" | cut -d'|' -f2)
        
        if curl -s --connect-timeout 5 "$url" > /dev/null 2>&1; then
            print_success "$name is accessible"
        else
            print_warning "$name is not responding (may be starting up)"
        fi
    done
    
    echo ""
    
    # Test database connectivity
    print_status "Testing database connectivity..."
    if command -v pg_isready &> /dev/null; then
        if pg_isready -h localhost -p 5432 -U postgres &> /dev/null; then
            print_success "PostgreSQL is ready"
        else
            print_warning "PostgreSQL is not ready (may be starting up)"
        fi
    else
        print_warning "pg_isready not found, install postgresql-client to test database"
    fi
    
    # Test Redis connectivity
    print_status "Testing Redis connectivity..."
    if command -v redis-cli &> /dev/null; then
        if redis-cli -h localhost -p 6379 -a Redis-Secure-2024! ping &> /dev/null; then
            print_success "Redis is ready"
        else
            print_warning "Redis is not ready (may be starting up)"
        fi
    else
        print_warning "redis-cli not found, install redis-tools to test Redis"
    fi
    
    echo ""
}

# Main execution
main() {
    show_header
    
    # Check if script is being run with specific options
    case "${1:-}" in
        --status)
            show_tunnel_status
            exit 0
            ;;
        --test)
            test_connectivity
            exit 0
            ;;
        --stop)
            print_status "Stopping all tunnels..."
            pkill -f "kubectl port-forward" 2>/dev/null || true
            print_success "All tunnels stopped"
            exit 0
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --status    Show current tunnel status"
            echo "  --test      Test service connectivity"
            echo "  --stop      Stop all tunnels"
            echo "  --help      Show this help message"
            echo ""
            echo "Run without options to start all tunnels"
            exit 0
            ;;
    esac
    
    verify_cluster
    cleanup_tunnels
    
    # Start all tunnels
    if start_all_tunnels; then
        if [ $? -eq 0 ]; then
            print_success "All tunnels started successfully!"
        else
            print_warning "Some tunnels failed to start, but continuing..."
        fi
    fi
    
    # Wait a moment for tunnels to stabilize
    print_status "Waiting for tunnels to stabilize..."
    sleep 3
    
    # Show access information
    show_access_info
    show_connection_commands
    show_tunnel_status
    show_management_commands
    
    # Optional connectivity test
    echo -e "${YELLOW}Would you like to test connectivity to all services? (y/n): ${NC}"
    read -r -t 10 response || response="n"
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        test_connectivity
    fi
    
    print_success "Setup complete! All tunnels are running in the background."
    print_status "Press Ctrl+C to stop this script (tunnels will continue running)"
    print_status "Use 'pkill -f kubectl port-forward' to stop all tunnels"
    
    # Keep script running to show that tunnels are active
    echo ""
    print_header "🔄 Monitoring tunnels... (Press Ctrl+C to exit monitor)"
    
    trap 'echo -e "\n${YELLOW}Exiting monitor... Tunnels will continue running in background${NC}"; exit 0' INT
    
    while true; do
        sleep 30
        local tunnel_count=$(ps aux | grep "kubectl port-forward" | grep -v grep | wc -l)
        echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $tunnel_count tunnels active"
    done
}

# Execute main function
main "$@"