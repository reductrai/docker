# ReductrAI Docker Image Strategy

## Overview
This document explains our Docker image management strategy for local development vs production deployment.

## Docker Images

### Production Images (Customer/Live)
- **`reductrai/proxy:latest`** - Latest stable production build with all fixes
- **`reductrai/proxy:v1.0.1`** - Versioned release (includes AI Query sampling fix)
- **`reductrai/ai-query:latest`** - Latest AI query service
- **`reductrai/ollama:latest`** - Ollama LLM integration

**IMPORTANT**: Production images include the critical AI Query sampling fix (1% sampling rate) to prevent CPU saturation under high load.

### Local Development Images
- **`reductrai/proxy:local`** - Built from local source for development
- **`reductrai/ai-query:local`** - Built from local AI query source

## Docker Compose Files

### 1. `docker-compose.yml` (Default)
- **Purpose**: Main configuration file
- **Uses**: Production images by default
- **Location**: `/reductrai-docker/docker-compose.yml`
- **Usage**: `docker-compose up`

### 2. `docker-compose.production.yml`
- **Purpose**: Production deployment with resource limits and logging
- **Uses**: Official registry images (`latest` or versioned)
- **Location**: `/reductrai-docker/docker-compose.production.yml`
- **Features**:
  - Resource limits and reservations
  - Log rotation
  - Health checks
  - Cloud storage support (S3, GCS, Azure)
- **Usage**: `docker-compose -f docker-compose.production.yml up`

### 3. `docker-compose.local.yml`
- **Purpose**: Local development with source mounting
- **Uses**: Locally built images with live code reload
- **Location**: `/reductrai-docker/docker-compose.local.yml`
- **Features**:
  - Source code mounting for hot reload
  - Local observability stack (Prometheus, Grafana, Jaeger)
  - Debug logging
- **Usage**: `docker-compose -f docker-compose.local.yml up`

### 4. `docker-compose.services.yml` (Shared)
- **Purpose**: Service definitions used by other compose files
- **Location**: `/deploy/config/services/docker-compose.services.yml`
- **Note**: Used via `extends` in main docker-compose.yml

## Environment Variables

### Critical Settings
```bash
# AI Query sampling - MUST be set to prevent CPU saturation
AI_QUERY_SAMPLE_RATE=0.01  # Only send 1% of data to AI Query

# Proxy sampling for monitoring backends
SAMPLE_RATE=0.1  # Forward 10% to Datadog/NewRelic/etc

# Compression settings
REDUCTRAI_COMPRESSION=true
REDUCTRAI_COMPRESSION_LEVEL=heavy
```

## Building Images

### Production Build
```bash
# Build and tag production image
cd /reductrai-proxy
docker build -t reductrai/proxy:latest -t reductrai/proxy:v1.0.1 .

# Push to registry (if you have a registry)
docker push reductrai/proxy:latest
docker push reductrai/proxy:v1.0.1
```

### Local Development Build
```bash
# Build local development image
cd /reductrai-proxy
docker build -t reductrai/proxy:local .
```

## Deployment Commands

### Production Deployment
```bash
# Use production compose file
docker-compose -f docker-compose.production.yml up -d

# Or use default (which now points to production images)
docker-compose up -d
```

### Local Development
```bash
# Use local compose file with source mounting
docker-compose -f docker-compose.local.yml up

# For building and running
docker-compose -f docker-compose.local.yml up --build
```

## Version Management

1. **Latest Tag**: Always points to the most recent stable build
2. **Version Tags**: Semantic versioning (v1.0.0, v1.0.1, etc)
3. **Local Tag**: Used for development, never pushed to registry

## Key Fixes in v1.0.1
- **AI Query Sampling**: Prevents CPU saturation by only sending 1% of data to AI Query
- **Async Processing**: Improved async handling in AI Query service
- **Performance**: Optimized for high-volume telemetry (16,000+ points/sec)

## Cleanup Old Images
```bash
# Remove unused images
docker image prune -a

# Remove specific old versions
docker rmi reductrai/proxy:local-sampling  # Old test image

# Clean up everything (careful!)
docker system prune -a --volumes
```

## Troubleshooting

### High CPU Usage
- Check `AI_QUERY_SAMPLE_RATE` is set to 0.01 or lower
- Verify using latest image with sampling fix
- Monitor with: `docker stats`

### Image Not Updating
- Pull latest: `docker-compose pull`
- Rebuild: `docker-compose up --build`
- Check image ID: `docker images | grep reductrai`

### Switching Between Local and Production
```bash
# Stop current deployment
docker-compose down

# Switch to local development
docker-compose -f docker-compose.local.yml up

# Switch back to production
docker-compose -f docker-compose.production.yml up
```