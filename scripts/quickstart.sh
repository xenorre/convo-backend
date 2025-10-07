#!/bin/bash

# ConvoChat Backend Quick Start Script
# Simple, MacOS-compatible version for immediate use

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    print_error "package.json not found. Please run this script from the backend directory."
    exit 1
fi

print_header "ConvoChat Backend Quick Start"

# Check Node.js
if ! command -v node >/dev/null 2>&1; then
    print_error "Node.js not found. Please install Node.js 18 or higher."
    exit 1
fi

NODE_VERSION=$(node --version)
print_success "Node.js found: $NODE_VERSION"

# Create .env if it doesn't exist
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

# Install dependencies
print_info "Installing dependencies..."
if [ -f "package-lock.json" ]; then
    npm ci
else
    npm install
fi
print_success "Dependencies installed"

# Create necessary directories
mkdir -p logs uploads temp
print_success "Created necessary directories"

# Ask user what they want to do
echo ""
print_info "What would you like to do?"
echo "1) Start development server"
echo "2) Run tests"
echo "3) Build for production" 
echo "4) Exit"
echo ""

read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        print_header "Starting Development Server"
        print_info "Starting backend in development mode..."
        npm run dev
        ;;
    2)
        print_header "Running Tests"
        if npm run | grep -q "test"; then
            npm test
        else
            print_warning "No test script found in package.json"
        fi
        ;;
    3)
        print_header "Building for Production"
        if npm run | grep -q "build"; then
            npm run build
            print_success "Build completed"
        else
            print_warning "No build script found in package.json"
        fi
        ;;
    4)
        print_info "Goodbye!"
        exit 0
        ;;
    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

print_success "Quick start completed! 🚀"