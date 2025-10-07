#!/bin/bash

# ConvoChat Backend Production Deployment Script
set -eu

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="production"
BUILD_IMAGE=true
PUSH_IMAGE=false
RUN_TESTS=true
SKIP_BACKUP=false
DOCKER_REGISTRY=""
IMAGE_NAME="convochat-backend"
VERSION_TAG=""

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
ConvoChat Backend Production Deployment Script

Usage: $0 [OPTIONS]

Options:
    --env ENV              Environment to deploy to (default: production)
    --no-build            Skip Docker image building
    --push                Push image to registry
    --skip-tests          Skip running tests
    --skip-backup         Skip database backup
    --registry REGISTRY   Docker registry URL
    --image NAME          Docker image name (default: convochat-backend)
    --tag VERSION         Version tag for the image
    --help                Show this help message

Examples:
    $0                                    # Build and test for production
    $0 --env staging --push               # Deploy to staging with registry push
    $0 --tag v1.2.3 --push --registry my.registry.com
    $0 --no-build --skip-tests            # Quick deployment (not recommended)

EOF
}

check_requirements() {
    print_header "Checking Requirements"
    
    # Check Docker
    if command -v docker >/dev/null 2>&1; then
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
        print_success "Docker found: $DOCKER_VERSION"
    else
        print_error "Docker not found. Please install Docker."
        exit 1
    fi
    
    # Check if we can connect to Docker daemon
    if ! docker info >/dev/null 2>&1; then
        print_error "Cannot connect to Docker daemon. Is it running?"
        exit 1
    fi
    
    # Check for required files
    if [ ! -f "package.json" ]; then
        print_error "package.json not found. Are you in the backend directory?"
        exit 1
    fi
    
    if [ ! -f "Dockerfile" ]; then
        print_error "Dockerfile not found."
        exit 1
    fi
    
    # Check environment file for production
    ENV_FILE=".env.${ENVIRONMENT}"
    if [ ! -f "$ENV_FILE" ] && [ "$ENVIRONMENT" != "production" ]; then
        print_warning "Environment file $ENV_FILE not found. Using .env"
        ENV_FILE=".env"
    fi
    
    if [ ! -f ".env" ] && [ ! -f "$ENV_FILE" ]; then
        print_error "No environment file found. Create .env or $ENV_FILE"
        exit 1
    fi
    
    print_success "All requirements met"
}

generate_version_tag() {
    if [ -z "$VERSION_TAG" ]; then
        # Generate version from git if available
        if git rev-parse --git-dir > /dev/null 2>&1; then
            GIT_COMMIT=$(git rev-parse --short HEAD)
            GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
            TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
            
            if [ "$GIT_BRANCH" = "main" ] || [ "$GIT_BRANCH" = "master" ]; then
                VERSION_TAG="v${TIMESTAMP}-${GIT_COMMIT}"
            else
                VERSION_TAG="${GIT_BRANCH}-${TIMESTAMP}-${GIT_COMMIT}"
            fi
        else
            VERSION_TAG="manual-$(date +"%Y%m%d-%H%M%S")"
        fi
    fi
    
    print_info "Using version tag: $VERSION_TAG"
}

run_tests() {
    if [ "$RUN_TESTS" = false ]; then
        print_info "Skipping tests"
        return
    fi
    
    print_header "Running Tests"
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        print_info "Installing dependencies..."
        npm ci --production=false
    fi
    
    # Run linting
    print_info "Running linter..."
    npm run lint
    
    # Run type checking
    if npm run | grep -q "type-check"; then
        print_info "Running type check..."
        npm run type-check
    fi
    
    # Run tests
    if npm run | grep -q "test"; then
        print_info "Running tests..."
        npm test
    else
        print_warning "No test script found in package.json"
    fi
    
    print_success "All tests passed"
}

backup_database() {
    if [ "$SKIP_BACKUP" = true ]; then
        print_info "Skipping database backup"
        return
    fi
    
    print_header "Creating Database Backup"
    
    # Load environment variables to get database info
    ENV_FILE=".env.${ENVIRONMENT}"
    if [ ! -f "$ENV_FILE" ]; then
        ENV_FILE=".env"
    fi
    
    if [ -f "$ENV_FILE" ]; then
        export $(grep -v '^#' "$ENV_FILE" | xargs)
    fi
    
    # Create backup directory
    BACKUP_DIR="backups/$(date +%Y%m%d)"
    mkdir -p "$BACKUP_DIR"
    
    # MongoDB backup
    if [ -n "${MONGODB_URI:-}" ]; then
        print_info "Creating MongoDB backup..."
        BACKUP_FILE="${BACKUP_DIR}/mongodb-backup-$(date +%H%M%S).gz"
        
        # Extract database name from URI
        DB_NAME=$(echo "$MONGODB_URI" | sed 's/.*\/\([^?]*\).*/\1/')
        
        if command -v mongodump >/dev/null 2>&1; then
            mongodump --uri="$MONGODB_URI" --gzip --archive="$BACKUP_FILE"
            print_success "MongoDB backup created: $BACKUP_FILE"
        else
            print_warning "mongodump not found. Skipping MongoDB backup."
        fi
    fi
    
    # Keep only last 7 days of backups
    find backups -type d -mtime +7 -exec rm -rf {} + 2>/dev/null || true
    
    print_success "Database backup completed"
}

build_image() {
    if [ "$BUILD_IMAGE" = false ]; then
        print_info "Skipping Docker image build"
        return
    fi
    
    print_header "Building Docker Image"
    
    # Full image name with registry and tag
    FULL_IMAGE_NAME="$IMAGE_NAME:$VERSION_TAG"
    if [ -n "$DOCKER_REGISTRY" ]; then
        FULL_IMAGE_NAME="$DOCKER_REGISTRY/$FULL_IMAGE_NAME"
    fi
    
    print_info "Building image: $FULL_IMAGE_NAME"
    
    # Build the image
    docker build \
        --build-arg NODE_ENV="$ENVIRONMENT" \
        --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
        --build-arg VERSION="$VERSION_TAG" \
        --tag "$FULL_IMAGE_NAME" \
        --tag "$IMAGE_NAME:latest" \
        .
    
    print_success "Docker image built successfully"
    
    # Show image info
    docker images "$IMAGE_NAME" --format "table {{.Repository}}:{{.Tag}}\t{{.CreatedAt}}\t{{.Size}}"
}

push_image() {
    if [ "$PUSH_IMAGE" = false ]; then
        print_info "Skipping Docker image push"
        return
    fi
    
    if [ -z "$DOCKER_REGISTRY" ]; then
        print_error "Docker registry not specified. Use --registry option."
        exit 1
    fi
    
    print_header "Pushing Docker Image"
    
    FULL_IMAGE_NAME="$DOCKER_REGISTRY/$IMAGE_NAME:$VERSION_TAG"
    LATEST_IMAGE_NAME="$DOCKER_REGISTRY/$IMAGE_NAME:latest"
    
    print_info "Pushing $FULL_IMAGE_NAME..."
    docker push "$FULL_IMAGE_NAME"
    
    print_info "Pushing $LATEST_IMAGE_NAME..."
    docker tag "$IMAGE_NAME:latest" "$LATEST_IMAGE_NAME"
    docker push "$LATEST_IMAGE_NAME"
    
    print_success "Docker images pushed successfully"
}

deploy_local() {
    print_header "Deploying Locally"
    
    # Stop existing containers
    print_info "Stopping existing containers..."
    docker-compose -f "docker-compose.${ENVIRONMENT}.yml" down 2>/dev/null || true
    
    # Start new deployment
    print_info "Starting new deployment..."
    docker-compose -f "docker-compose.${ENVIRONMENT}.yml" up -d
    
    # Wait for services to be ready
    print_info "Waiting for services to be ready..."
    sleep 10
    
    # Health check
    if curl -f http://localhost:3000/healthz >/dev/null 2>&1; then
        print_success "Deployment successful - health check passed"
    else
        print_error "Deployment may have issues - health check failed"
        docker-compose -f "docker-compose.${ENVIRONMENT}.yml" logs --tail=20
    fi
}

cleanup_old_images() {
    print_header "Cleaning Up Old Images"
    
    # Remove dangling images
    docker image prune -f >/dev/null 2>&1 || true
    
    # Keep only last 5 versions of our image
    OLD_IMAGES=$(docker images "$IMAGE_NAME" --format "{{.ID}} {{.CreatedAt}}" | sort -k2 -r | tail -n +6 | awk '{print $1}')
    
    if [ -n "$OLD_IMAGES" ]; then
        echo "$OLD_IMAGES" | xargs docker rmi -f >/dev/null 2>&1 || true
        print_success "Cleaned up old images"
    else
        print_info "No old images to clean up"
    fi
}

generate_deployment_summary() {
    print_header "Deployment Summary"
    
    echo -e "${GREEN}Environment:${NC} $ENVIRONMENT"
    echo -e "${GREEN}Version:${NC} $VERSION_TAG"
    echo -e "${GREEN}Image:${NC} $IMAGE_NAME:$VERSION_TAG"
    
    if [ -n "$DOCKER_REGISTRY" ]; then
        echo -e "${GREEN}Registry:${NC} $DOCKER_REGISTRY"
    fi
    
    echo -e "${GREEN}Timestamp:${NC} $(date)"
    
    if git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${GREEN}Git Commit:${NC} $(git rev-parse HEAD)"
        echo -e "${GREEN}Git Branch:${NC} $(git rev-parse --abbrev-ref HEAD)"
    fi
    
    echo ""
    print_success "Deployment completed successfully! 🎉"
    
    echo -e "\n${BLUE}Next steps:${NC}"
    echo -e "  • Monitor logs: ${YELLOW}docker-compose logs -f${NC}"
    echo -e "  • Check health: ${YELLOW}curl http://localhost:3000/healthz${NC}"
    echo -e "  • View metrics: ${YELLOW}docker stats${NC}"
}

main() {
    print_header "ConvoChat Backend Deployment"
    
    # Parse command line arguments
    while [ $# -gt 0 ]; do
        case $1 in
            --env)
                ENVIRONMENT="$2"
                shift 2
                ;;
            --no-build)
                BUILD_IMAGE=false
                shift
                ;;
            --push)
                PUSH_IMAGE=true
                shift
                ;;
            --skip-tests)
                RUN_TESTS=false
                shift
                ;;
            --skip-backup)
                SKIP_BACKUP=true
                shift
                ;;
            --registry)
                DOCKER_REGISTRY="$2"
                shift 2
                ;;
            --image)
                IMAGE_NAME="$2"
                shift 2
                ;;
            --tag)
                VERSION_TAG="$2"
                shift 2
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
    generate_version_tag
    run_tests
    backup_database
    build_image
    push_image
    
    # Only deploy locally if not pushing to registry
    if [ "$PUSH_IMAGE" = false ]; then
        deploy_local
    fi
    
    cleanup_old_images
    generate_deployment_summary
}

# Check if running directly (not sourced)
if [ "${0##*/}" = "deploy.sh" ]; then
    main "$@"
fi
