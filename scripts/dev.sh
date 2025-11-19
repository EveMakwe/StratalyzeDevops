#!/bin/bash

# Coffee Queue Development Tool
# Manage Docker Compose operations

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo_blue() { echo -e "${BLUE}$1${NC}"; }
echo_green() { echo -e "${GREEN}$1${NC}"; }
echo_red() { echo -e "${RED}$1${NC}"; }
echo_yellow() { echo -e "${YELLOW}$1${NC}"; }

show_help() {
    cat <<EOF
Coffee Queue Development Tool - Docker Compose Manager

USAGE:
    ./dev.sh <command>

COMMANDS:
    start       Start the application stack
    stop        Stop the application
    restart     Restart the application
    logs        View application logs (follow mode)
    test        Run tests and verify endpoints
    build       Build Docker images
    status      Show running containers
    monitor     Monitor resource usage (live updating)
    shell       Open shell in application container
    db          Open PostgreSQL shell
    clean       Clean up containers, volumes, and images
    help        Show this help message

EOF
}

# Check Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo_red "Docker is not installed!"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        echo_red "Docker daemon is not running!"
        exit 1
    fi
}

# Start application
cmd_start() {
    echo_blue "Starting Coffee Queue application..."
    docker compose up -d
    echo_green "Application started successfully!"
    echo ""
    echo "Access the application at: http://localhost:8080"
    echo "Database: localhost:5432 (user: coffee, db: coffeequeue)"
    echo ""
    echo "Run './dev.sh test' to verify endpoints"
    echo "Run './dev.sh logs' to view logs"
}

# Stop application
cmd_stop() {
    echo_blue "Stopping Coffee Queue application..."
    docker compose down
    echo_green "Application stopped successfully!"
}

# Restart application
cmd_restart() {
    echo_blue "Restarting Coffee Queue application..."
    docker compose restart
    echo_green "Application restarted successfully!"
}

# View logs
cmd_logs() {
    echo_blue "Showing application logs (Ctrl+C to exit)..."
    docker compose logs -f
}

# Run tests
cmd_test() {
    echo_blue "Testing Coffee Queue application..."
    
    # Wait for app to be ready
    echo "Waiting for application to be ready..."
    sleep 5
    
    # Test health endpoint
    echo "Testing health endpoint..."
    if curl -sf http://localhost:8080/health > /dev/null; then
        echo_green "✓ Health check: PASSED"
    else
        echo_red "✗ Health check: FAILED"
        exit 1
    fi
    
    # Test create order
    echo "Testing create order..."
    if curl -sf -X POST "http://localhost:8080/order?name=TestUser" > /dev/null; then
        echo_green "✓ Create order: PASSED"
    else
        echo_red "✗ Create order: FAILED"
        exit 1
    fi
    
    # Test get statistics
    echo "Testing coffee statistics..."
    if curl -sf http://localhost:8080/numberOfCoffees > /dev/null; then
        echo_green "✓ Get statistics: PASSED"
    else
        echo_red "✗ Get statistics: FAILED"
        exit 1
    fi
    
    # Test get order status
    echo "Testing order status..."
    if curl -sf "http://localhost:8080/status?name=TestUser" > /dev/null; then
        echo_green "✓ Get order status: PASSED"
    else
        echo_red "✗ Get order status: FAILED"
        exit 1
    fi
    
    echo ""
    echo_green "All tests passed!"
    echo ""
    echo "Try these endpoints:"
    echo "  curl http://localhost:8080/health"
    echo "  curl -X POST 'http://localhost:8080/order?name=YourName'"
    echo "  curl 'http://localhost:8080/status?name=YourName'"
    echo "  curl http://localhost:8080/numberOfCoffees"
}

# Build images
cmd_build() {
    echo_blue "Building Docker images..."
    docker compose build
    echo_green "Build completed successfully!"
}

# Show status
cmd_status() {
    echo_blue "Container Status:"
    docker compose ps
    echo ""
    echo_blue "Resource Usage:"
    docker stats --no-stream $(docker compose ps -q 2>/dev/null) 2>/dev/null || echo "No containers running"
}

# Open shell
cmd_shell() {
    echo_blue "Opening shell in application container..."
    docker compose exec app sh || echo_red "Application container is not running. Start it with './dev.sh start'"
}

# Open database shell
cmd_db() {
    echo_blue "Opening PostgreSQL shell..."
    docker compose exec postgres psql -U coffee -d coffeequeue || echo_red "Database container is not running. Start it with './dev.sh start'"
}

# Monitor resources
cmd_monitor() {
    echo_blue "Monitoring Coffee Queue resources (Ctrl+C to exit)..."
    echo "Refreshing every 2 seconds..."
    echo ""
    while true; do
        clear
        echo -e "${BLUE}=== Coffee Queue Resource Monitor ===${NC}"
        echo ""
        docker compose ps
        echo ""
        echo -e "${BLUE}=== Container Resource Usage ===${NC}"
        docker stats --no-stream $(docker compose ps -q 2>/dev/null) 2>/dev/null || echo "No containers running"
        echo ""
        echo -e "${YELLOW}Press Ctrl+C to exit${NC}"
        sleep 2
    done
}

# Clean up
cmd_clean() {
    echo_yellow "This will remove all containers, volumes, and images!"
    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo_blue "Cleaning up..."
        docker compose down -v
        docker compose down --rmi all --remove-orphans
        rm -rf coffeequeue/target
        echo_green "Cleanup completed!"
    else
        echo "Cleanup cancelled"
    fi
}

# Main
main() {
    check_docker
    
    case "${1:-help}" in
        start)
            cmd_start
            ;;
        stop)
            cmd_stop
            ;;
        restart)
            cmd_restart
            ;;
        logs)
            cmd_logs
            ;;
        test)
            cmd_test
            ;;
        build)
            cmd_build
            ;;
        status)
            cmd_status
            ;;
        monitor)
            cmd_monitor
            ;;
        shell)
            cmd_shell
            ;;
        db)
            cmd_db
            ;;
        clean)
            cmd_clean
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo_red "Unknown command: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"
