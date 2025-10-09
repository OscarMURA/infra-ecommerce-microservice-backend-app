# Docker Configuration Documentation

This directory contains Docker-related files for containerizing and running the ecommerce microservice backend application.

## Files

- **Dockerfile**: Multi-stage production Dockerfile
- **docker-compose.yml**: Local development environment setup
- **nginx.conf**: Nginx reverse proxy configuration

## Dockerfile

### Multi-Stage Build

The Dockerfile uses a multi-stage build approach for optimized image size and security.

**Stage 1: Builder**
- Base: `node:18-alpine`
- Installs production dependencies
- Copies application code
- Builds the application (if needed)

**Stage 2: Production**
- Base: `node:18-alpine`
- Creates non-root user for security
- Copies only necessary files from builder
- Runs as non-root user
- Includes health check

### Building the Image

```bash
# Build image
docker build -t ecommerce-backend:latest -f docker/Dockerfile .

# Build with specific tag
docker build -t ecommerce-backend:v1.0.0 -f docker/Dockerfile .

# Build with build args
docker build \
  --build-arg NODE_VERSION=18 \
  -t ecommerce-backend:latest \
  -f docker/Dockerfile .
```

### Running the Container

```bash
# Run container
docker run -d \
  --name ecommerce-backend \
  -p 3000:3000 \
  -e NODE_ENV=production \
  -e DB_HOST=postgres \
  ecommerce-backend:latest

# Run with environment file
docker run -d \
  --name ecommerce-backend \
  -p 3000:3000 \
  --env-file .env \
  ecommerce-backend:latest
```

### Health Check

The Dockerfile includes a health check that runs every 30 seconds:

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD node healthcheck.js || exit 1
```

**Check container health:**
```bash
docker inspect --format='{{.State.Health.Status}}' ecommerce-backend
```

## Docker Compose

### Local Development Setup

The `docker-compose.yml` provides a complete local development environment with:

- **PostgreSQL**: Database service
- **Redis**: Caching service
- **Backend**: Application service
- **Nginx**: Reverse proxy

### Services

#### PostgreSQL
- Port: 5432
- Database: ecommerce_dev
- Persistent volume: `postgres_data`

#### Redis
- Port: 6379
- Persistent volume: `redis_data`

#### Backend Application
- Port: 3000
- Auto-reload on code changes (volume mounted)
- Depends on postgres and redis

#### Nginx
- Port: 80 (HTTP)
- Port: 443 (HTTPS)
- Reverse proxy to backend

### Usage

```bash
# Start all services
cd docker
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# Rebuild services
docker-compose up -d --build
```

### Environment Variables

Create a `.env` file in the docker directory:

```env
# Database
DB_HOST=postgres
DB_PORT=5432
DB_NAME=ecommerce_dev
DB_USER=dev_user
DB_PASSWORD=dev_password

# Redis
REDIS_HOST=redis
REDIS_PORT=6379

# Application
NODE_ENV=development
APP_PORT=3000
LOG_LEVEL=debug
```

### Accessing Services

```bash
# Application
curl http://localhost/health

# Direct backend access
curl http://localhost:3000/health

# PostgreSQL
psql -h localhost -U dev_user -d ecommerce_dev

# Redis
redis-cli -h localhost
```

## Nginx Configuration

### Reverse Proxy Setup

The `nginx.conf` configures Nginx as a reverse proxy:

**Features:**
- Load balancing to backend service
- Proxy headers for real IP tracking
- Health check endpoint
- Access log disabled for /health

### Configuration Details

```nginx
upstream backend {
    server backend:3000;
}

server {
    listen 80;
    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Custom Configuration

To add custom Nginx configuration:

1. Edit `docker/nginx.conf`
2. Rebuild services: `docker-compose up -d --build nginx`

### SSL/TLS Support

For HTTPS support, update nginx.conf:

```nginx
server {
    listen 443 ssl;
    ssl_certificate /etc/nginx/certs/cert.pem;
    ssl_certificate_key /etc/nginx/certs/key.pem;
    # ... rest of configuration
}
```

## Best Practices

### 1. Image Size Optimization
- Use Alpine-based images
- Multi-stage builds
- Remove unnecessary files
- Minimize layers

### 2. Security
- Run as non-root user
- Scan images for vulnerabilities
- Use specific version tags
- Keep base images updated

```bash
# Scan image for vulnerabilities
docker scan ecommerce-backend:latest

# Check image history
docker history ecommerce-backend:latest
```

### 3. Logging
- Log to stdout/stderr
- Use structured logging (JSON)
- Configure log drivers

```bash
# View logs
docker logs ecommerce-backend

# Follow logs
docker logs -f ecommerce-backend

# Tail last 100 lines
docker logs --tail 100 ecommerce-backend
```

### 4. Resource Limits

```bash
# Run with resource limits
docker run -d \
  --name ecommerce-backend \
  --memory="512m" \
  --cpus="0.5" \
  ecommerce-backend:latest
```

### 5. Data Persistence

```bash
# Create named volumes
docker volume create postgres_data
docker volume create redis_data

# List volumes
docker volume ls

# Inspect volume
docker volume inspect postgres_data

# Backup volume
docker run --rm -v postgres_data:/data -v $(pwd):/backup alpine tar czf /backup/postgres-backup.tar.gz /data
```

## Development Workflow

### 1. Code Changes
- Edit code locally
- Changes reflected immediately (volume mount)
- No rebuild needed

### 2. Dependency Changes
```bash
# Rebuild after package.json changes
docker-compose up -d --build backend
```

### 3. Database Migrations
```bash
# Run migrations
docker-compose exec backend npm run migrate

# Seed database
docker-compose exec backend npm run seed
```

### 4. Testing
```bash
# Run tests
docker-compose exec backend npm test

# Run with coverage
docker-compose exec backend npm run test:coverage
```

## Troubleshooting

### Container Won't Start
```bash
# Check logs
docker logs ecommerce-backend

# Check container status
docker ps -a

# Inspect container
docker inspect ecommerce-backend
```

### Port Already in Use
```bash
# Find process using port
lsof -i :3000

# Kill process
kill -9 <PID>

# Or use different port
docker run -p 3001:3000 ecommerce-backend:latest
```

### Volume Permissions
```bash
# Fix volume permissions
docker-compose exec backend chown -R node:node /app
```

### Network Issues
```bash
# List networks
docker network ls

# Inspect network
docker network inspect docker_ecommerce-network

# Connect container to network
docker network connect docker_ecommerce-network ecommerce-backend
```

### Database Connection Failed
```bash
# Check if postgres is ready
docker-compose exec postgres pg_isready

# Check connection from backend
docker-compose exec backend ping postgres

# View postgres logs
docker-compose logs postgres
```

## Production Considerations

### 1. Image Registry
```bash
# Tag for registry
docker tag ecommerce-backend:latest registry.example.com/ecommerce-backend:latest

# Push to registry
docker push registry.example.com/ecommerce-backend:latest

# Pull from registry
docker pull registry.example.com/ecommerce-backend:latest
```

### 2. Environment-Specific Builds
```bash
# Build for production
docker build \
  -f docker/Dockerfile \
  --target production \
  -t ecommerce-backend:prod .

# Build for staging
docker build \
  -f docker/Dockerfile \
  --build-arg NODE_ENV=staging \
  -t ecommerce-backend:stage .
```

### 3. Health Checks in Production
- Implement comprehensive health endpoints
- Check database connectivity
- Check external service dependencies
- Monitor health check failures

### 4. Monitoring
```bash
# Container stats
docker stats ecommerce-backend

# Container resource usage
docker container top ecommerce-backend
```

## Maintenance

### Clean Up
```bash
# Remove unused containers
docker container prune

# Remove unused images
docker image prune

# Remove unused volumes
docker volume prune

# Remove everything unused
docker system prune -a
```

### Image Updates
```bash
# Pull latest base image
docker pull node:18-alpine

# Rebuild with new base
docker-compose build --no-cache --pull
```

### Backup and Restore
```bash
# Backup database
docker-compose exec postgres pg_dump -U dev_user ecommerce_dev > backup.sql

# Restore database
docker-compose exec -T postgres psql -U dev_user ecommerce_dev < backup.sql
```

## References

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)
- [Docker Security](https://docs.docker.com/engine/security/)
