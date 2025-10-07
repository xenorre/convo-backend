# ConvoChat Backend Scripts

This directory contains various scripts to help with development, testing, and deployment of the ConvoChat backend.

## Scripts Overview

### 🚀 Development Scripts

#### `dev.sh`
Development environment setup and startup script.

**Usage:**
```bash
# Start backend in development mode
./scripts/dev.sh

# Start with Docker
./scripts/dev.sh --docker

# Start full stack (backend + frontend)
./scripts/dev.sh --with-frontend

# Start full stack with Docker
./scripts/dev.sh --docker --with-frontend

# Skip dependency installation
./scripts/dev.sh --skip-deps
```

**Features:**
- Automatic dependency installation
- Environment setup (.env creation from .env.example)
- Docker and non-Docker modes
- Full stack development support
- Colorized output and error handling

---

### 🧪 Testing Scripts

#### `test.sh`
Comprehensive testing and quality assurance script.

**Usage:**
```bash
# Run all tests and checks
./scripts/test.sh

# Run only unit tests with coverage
./scripts/test.sh --unit --coverage

# Run only linting and type checking
./scripts/test.sh --lint --type-check

# Run tests in watch mode
./scripts/test.sh --watch

# Verbose output
./scripts/test.sh --verbose
```

**Test Suites:**
- **Unit Tests**: Jest/Mocha tests for individual functions
- **Integration Tests**: API endpoint and database tests
- **Linting**: ESLint code quality checks
- **Type Checking**: TypeScript type validation
- **Security Scan**: npm audit and security linting
- **Coverage**: Code coverage analysis with threshold checking

---

### 🚢 Deployment Scripts

#### `deploy.sh`
Production deployment script with Docker support.

**Usage:**
```bash
# Build and test for production
./scripts/deploy.sh

# Deploy to staging with registry push
./scripts/deploy.sh --env staging --push

# Deploy with custom registry and tag
./scripts/deploy.sh --tag v1.2.3 --push --registry my.registry.com

# Quick deployment (not recommended for production)
./scripts/deploy.sh --no-build --skip-tests
```

**Features:**
- Docker image building and tagging
- Automated testing before deployment
- Database backup creation
- Image registry pushing
- Local deployment with health checks
- Version tagging with Git integration
- Cleanup of old Docker images

**Options:**
- `--env ENV`: Environment to deploy to (default: production)
- `--no-build`: Skip Docker image building
- `--push`: Push image to registry
- `--skip-tests`: Skip running tests
- `--skip-backup`: Skip database backup
- `--registry REGISTRY`: Docker registry URL
- `--image NAME`: Docker image name
- `--tag VERSION`: Version tag for the image

---

## Docker Compose Files

### `docker-compose.fullstack.yml`
Full stack development environment with both backend and frontend services.

**Services:**
- **backend**: Node.js backend with hot reload
- **frontend**: React frontend (assumes ../convo-frontend exists)
- **mongodb**: MongoDB database with replica set
- **redis**: Redis for sessions and caching
- **mongo-express**: MongoDB admin UI (port 8081)
- **redis-commander**: Redis admin UI (port 8082)
- **nginx**: Reverse proxy (optional, use `--profile with-nginx`)

**Usage:**
```bash
# Start full stack
docker-compose -f docker-compose.fullstack.yml up -d

# Start with nginx proxy
docker-compose -f docker-compose.fullstack.yml --profile with-nginx up -d

# View logs
docker-compose -f docker-compose.fullstack.yml logs -f

# Stop services
docker-compose -f docker-compose.fullstack.yml down
```

### `docker-compose.production.yml`
Production-optimized environment with monitoring and security.

**Services:**
- **backend**: Production Node.js backend (replicated)
- **mongodb**: MongoDB with authentication and configuration
- **redis**: Redis with password protection
- **nginx**: Reverse proxy with SSL and caching
- **log-aggregator**: Fluent Bit log collection (optional)
- **prometheus**: Metrics collection (optional)
- **grafana**: Monitoring dashboard (optional)
- **backup**: Automated database backups (optional)

**Usage:**
```bash
# Start core services
docker-compose -f docker-compose.production.yml up -d

# Start with monitoring
docker-compose -f docker-compose.production.yml --profile with-monitoring up -d

# Start with logging
docker-compose -f docker-compose.production.yml --profile with-logging up -d

# Start with backups
docker-compose -f docker-compose.production.yml --profile with-backups up -d

# Start everything
docker-compose -f docker-compose.production.yml --profile with-monitoring --profile with-logging --profile with-backups up -d
```

---

## Quick Start

1. **Development Setup:**
   ```bash
   ./scripts/dev.sh --with-frontend
   ```

2. **Run Tests:**
   ```bash
   ./scripts/test.sh
   ```

3. **Deploy to Production:**
   ```bash
   ./scripts/deploy.sh --push --registry your-registry.com
   ```

## Environment Variables

Create a `.env` file for each environment:
- `.env` - Development
- `.env.staging` - Staging
- `.env.production` - Production

See `.env.example` for all available configuration options.

## Monitoring and Admin UIs

When running with Docker Compose:

- **Backend API**: http://localhost:3000
- **Frontend** (if included): http://localhost:3001
- **MongoDB Admin**: http://localhost:8081 (admin/admin)
- **Redis Admin**: http://localhost:8082 (admin/admin)
- **Prometheus**: http://localhost:9090 (monitoring profile)
- **Grafana**: http://localhost:3001 (monitoring profile)

## Backup and Recovery

The deployment script automatically creates database backups before deployment. Manual backups can be created using:

```bash
# MongoDB backup
mongodump --uri="$MONGODB_URI" --gzip --archive="backup-$(date +%Y%m%d).gz"

# Redis backup
redis-cli --rdb backup-redis-$(date +%Y%m%d).rdb
```

## Troubleshooting

### Common Issues

1. **Port conflicts**: Adjust ports in docker-compose files
2. **Permission errors**: Ensure scripts are executable (`chmod +x scripts/*.sh`)
3. **Docker issues**: Check Docker daemon is running
4. **Environment variables**: Verify .env files exist and are properly formatted

### Debug Commands

```bash
# Check container status
docker-compose ps

# View logs
docker-compose logs -f [service-name]

# Execute commands in containers
docker-compose exec backend bash
docker-compose exec mongodb mongo

# Check resource usage
docker stats
```

## Contributing

When adding new scripts:

1. Follow the existing naming convention
2. Include proper error handling and colorized output
3. Add comprehensive help text (`--help` option)
4. Update this README with usage examples
5. Make scripts executable (`chmod +x`)

For more detailed information, see the main project README.md.