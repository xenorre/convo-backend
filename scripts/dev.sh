#!/bin/bash

# ConvoChat Backend Development Script
set -eu

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
USE_DOCKER=false
INCLUDE_FRONTEND=false
SKIP_DEPS=false

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

show_usage() {
    cat << EOF
ConvoChat Backend Development Script

Usage: $0 [OPTIONS]

Options:
    --docker            Use Docker for development
    --with-frontend     Also start frontend in development mode
    --skip-deps         Skip dependency installation
    --help              Show this help message

Examples:
    $0                      # Start backend in development mode
    $0 --docker             # Start with Docker
    $0 --with-frontend      # Start full stack development
    $0 --docker --with-frontend  # Full stack with Docker

EOF
}

check_requirements() {
    print_header "Checking Requirements"
    
    # Check Node.js
    if command -v node >/dev/null 2>&1; then
        NODE_VERSION=$(node --version)
        print_success "Node.js found: $NODE_VERSION"
    else
        print_error "Node.js not found. Please install Node.js 18 or higher."
        exit 1
    fi
    
    # Check npm
    if command -v npm >/dev/null 2>&1; then
        NPM_VERSION=$(npm --version)
        print_success "npm found: $NPM_VERSION"
    else
        print_error "npm not found."
        exit 1
    fi
    
    if [ "$USE_DOCKER" = true ]; then
        # Check Docker
        if command -v docker >/dev/null 2>&1; then
            DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
            print_success "Docker found: $DOCKER_VERSION"
        else
            print_error "Docker not found but --docker flag was used."
            exit 1
        fi
        
        # Check Docker Compose
        if command -v docker-compose >/dev/null 2>&1; then
            print_success "Docker Compose found"
        else
            print_error "Docker Compose not found."
            exit 1
        fi
    fi
}

setup_environment() {
    print_header "Setting Up Environment"
    
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            cp .env.example .env
            print_success "Created .env from .env.example"
            print_warning "Please review and update .env with your configuration"
        else
            print_warning ".env.example not found. You may need to create .env manually."
        fi
    else
        print_info ".env already exists"
    fi
    
    # Create necessary directories
    mkdir -p logs uploads temp
    print_success "Created necessary directories"
}

install_dependencies() {
    if [ "$SKIP_DEPS" = true ]; then
        print_info "Skipping dependency installation"
        return
    fi
    
    print_header "Installing Dependencies"
    
    if [ -f "package-lock.json" ]; then
        npm ci
        print_success "Dependencies installed with npm ci"
    else
        npm install
        print_success "Dependencies installed with npm install"
    fi
}

start_services() {
    print_header "Starting Services"
    
    if [ "$USE_DOCKER" = true ]; then
        print_info "Starting services with Docker..."
        
        if [ "$INCLUDE_FRONTEND" = true ]; then
            # Start full stack
            print_info "Starting full stack (backend + frontend + database)..."
            docker-compose -f docker-compose.yml up -d
            
            # Also start frontend if available
            if [ -d "../convo-frontend" ]; then
                print_info "Starting frontend in development mode..."
                cd ../convo-frontend
                docker-compose -f docker-compose.dev.yml up -d
                cd ../convo-backend
            fi
        else
            # Just backend and database
            docker-compose up -d
        fi
        
        print_success "Docker services started"
        print_info "Backend: http://localhost:3000"
        print_info "MongoDB: localhost:27017"
        print_info "Redis: localhost:6379"
        
        if [ "$INCLUDE_FRONTEND" = true ]; then
            print_info "Frontend: http://localhost:3000 (if available)"
        fi
        
    else
        print_info "Starting backend in development mode..."
        
        if [ "$INCLUDE_FRONTEND" = true ]; then
            print_warning "Frontend development requires Docker or separate terminal"
            print_info "You may want to run: npm run dev in ../convo-frontend"
        fi
        
        npm run dev
    fi
}

main() {
    print_header "ConvoChat Backend Development"
    
    # Parse command line arguments
    while [ $# -gt 0 ]; do
        case $1 in
            --docker)
                USE_DOCKER=true
                shift
                ;;
            --with-frontend)
                INCLUDE_FRONTEND=true
                shift
                ;;
            --skip-deps)
                SKIP_DEPS=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    check_requirements
    setup_environment
    install_dependencies
    start_services
    
    print_header "Development Server Ready!"
    print_success "ConvoChat Backend is running"
    
    if [ "$USE_DOCKER" = true ]; then
        echo -e "\n${GREEN}Docker Commands:${NC}"
        echo -e "  • View logs: ${BLUE}docker-compose logs -f${NC}"
        echo -e "  • Stop services: ${BLUE}docker-compose down${NC}"
        echo -e "  • Restart: ${BLUE}docker-compose restart${NC}"
    fi
    
    echo -e "\n${GREEN}Available endpoints:${NC}"
    echo -e "  • Health check: ${BLUE}curl http://localhost:3000/healthz${NC}"
    echo -e "  • API docs: ${BLUE}http://localhost:3000${NC}"
    
    echo -e "\n${GREEN}Happy coding! 🚀${NC}\n"
}

# Check if running directly (not sourced)
if [ "${0##*/}" = "dev.sh" ]; then
    main "$@"
fi
