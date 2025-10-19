# Building ReductrAI Docker Images

This document explains how to build Docker images for ReductrAI services.

## Prerequisites

The `docker-compose.yml` in this repository references pre-built images from Docker Hub:
- `reductrai/proxy:latest`
- `reductrai/dashboard:latest`
- `reductrai/ai-query:latest`

These images must be either:
1. **Published to Docker Hub** (for production distribution)
2. **Built locally** (for development/testing)

## Option 1: Pull Published Images (Recommended for Users)

```bash
# Pull all images
docker-compose pull

# Start services
docker-compose up -d
```

**Note:** Images are not yet published to Docker Hub. This will work once images are published.

## Option 2: Build Images Locally (For Development)

If you have access to the source repositories, you can build images locally.

### Directory Structure Required

```
/path/to/reductrai/
├── reductrai-proxy/
├── reductrai-dashboard/
├── reductrai-ai-query/
└── reductrai-docker/  (this repo)
```

### Build Script

Use the provided `build-images.sh` script to build all images:

```bash
# From the reductrai-docker directory
./build-images.sh

# Or manually build each image:

# Build proxy image
cd ../reductrai-proxy
docker build -t reductrai/proxy:latest -f Dockerfile.prod .

# Build dashboard image
cd ../reductrai-dashboard
docker build -t reductrai/dashboard:latest -f Dockerfile .

# Build AI query image
cd ../reductrai-ai-query
docker build -t reductrai/ai-query:latest -f Dockerfile .
```

### Verify Images

```bash
docker images | grep reductrai
```

You should see:
```
reductrai/proxy       latest   ...   ... ago   ...MB
reductrai/dashboard   latest   ...   ... ago   ...MB
reductrai/ai-query    latest   ...   ... ago   ...MB
```

## Option 3: Publish to Docker Hub (For Maintainers)

### Prerequisites

1. Docker Hub account
2. Login to Docker Hub:
   ```bash
   docker login
   ```

### Build and Push

```bash
# Set version
export VERSION=1.0.0

# Build all images with version tag
docker build -t reductrai/proxy:$VERSION -t reductrai/proxy:latest \
  -f ../reductrai-proxy/Dockerfile.prod ../reductrai-proxy

docker build -t reductrai/dashboard:$VERSION -t reductrai/dashboard:latest \
  -f ../reductrai-dashboard/Dockerfile ../reductrai-dashboard

docker build -t reductrai/ai-query:$VERSION -t reductrai/ai-query:latest \
  -f ../reductrai-ai-query/Dockerfile ../reductrai-ai-query

# Push to Docker Hub
docker push reductrai/proxy:$VERSION
docker push reductrai/proxy:latest

docker push reductrai/dashboard:$VERSION
docker push reductrai/dashboard:latest

docker push reductrai/ai-query:$VERSION
docker push reductrai/ai-query:latest
```

## Using Specific Versions

You can specify a version using the `REDUCTRAI_VERSION` environment variable:

```bash
# Use specific version
export REDUCTRAI_VERSION=1.0.0
docker-compose up -d

# Or in .env file
echo "REDUCTRAI_VERSION=1.0.0" >> .env
docker-compose up -d
```

## Troubleshooting

### Error: "image not found"

If you see:
```
ERROR: pull access denied for reductrai/proxy, repository does not exist
```

This means:
1. Images haven't been published to Docker Hub yet, OR
2. You need to build them locally (see Option 2 above)

### Error: "build context not found"

If building locally fails with:
```
ERROR: Cannot locate specified Dockerfile: ../reductrai-proxy/Dockerfile.prod
```

This means the source repositories aren't in the expected location. Ensure you have:
```
/path/to/
├── reductrai-proxy/
├── reductrai-dashboard/
├── reductrai-ai-query/
└── reductrai-docker/
```

## Next Steps

Once images are built or pulled:
1. Configure `.env` file (see `.env.example`)
2. Start services: `docker-compose up -d`
3. Verify: `curl http://localhost:8080/health`
