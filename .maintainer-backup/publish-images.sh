#!/bin/bash
set -e

# ReductrAI Docker Image Build and Publish Script
# This script builds all ReductrAI Docker images and publishes them to Docker Hub

echo "🚀 ReductrAI Docker Image Build & Publish"
echo "=========================================="

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: Must run from reductrai-docker directory"
    exit 1
fi

# Check Docker Hub login
echo "🔐 Checking Docker Hub authentication..."
if ! docker info 2>&1 | grep -q "Username"; then
    echo "⚠️  Warning: You may not be logged into Docker Hub"
    echo "   Please run: docker login"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Aborted. Please login first: docker login"
        exit 1
    fi
fi

# Check if source directories exist
PROXY_DIR="../reductrai-proxy"
DASHBOARD_DIR="../reductrai-dashboard"
AI_QUERY_DIR="../reductrai-ai-query"
OLLAMA_DIR="../reductrai-ollama"

if [ ! -d "$PROXY_DIR" ]; then
    echo "❌ Error: $PROXY_DIR not found"
    echo "   Please clone all repositories in the same parent directory:"
    echo "   - reductrai-proxy"
    echo "   - reductrai-dashboard"
    echo "   - reductrai-ai-query"
    echo "   - reductrai-ollama"
    echo "   - reductrai-docker (this repo)"
    exit 1
fi

if [ ! -d "$DASHBOARD_DIR" ]; then
    echo "❌ Error: $DASHBOARD_DIR not found"
    exit 1
fi

if [ ! -d "$AI_QUERY_DIR" ]; then
    echo "❌ Error: $AI_QUERY_DIR not found"
    exit 1
fi

if [ ! -d "$OLLAMA_DIR" ]; then
    echo "❌ Error: $OLLAMA_DIR not found"
    exit 1
fi

# Version tag (default to 'latest', or use first argument)
VERSION="${1:-latest}"

echo ""
echo "📦 Building and publishing version: $VERSION"
echo "   This will create and push:"
echo "   - reductrai/proxy:$VERSION"
echo "   - reductrai/dashboard:$VERSION"
echo "   - reductrai/ai-query:$VERSION"
echo "   - reductrai/ollama:$VERSION"
echo ""

# Confirm before proceeding
read -p "Continue with build and publish? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Aborted by user"
    exit 1
fi

echo ""
echo "================================================"
echo "1/3 Building and Publishing Proxy Image"
echo "================================================"

echo "🔨 Building reductrai/proxy:$VERSION..."
docker build \
    -t "reductrai/proxy:$VERSION" \
    -t "reductrai/proxy:latest" \
    -f "dockerfiles/Dockerfile.proxy" \
    .

echo "✅ Build complete"
echo ""
echo "📤 Pushing reductrai/proxy:$VERSION to Docker Hub..."
docker push "reductrai/proxy:$VERSION"

if [ "$VERSION" != "latest" ]; then
    echo "📤 Pushing reductrai/proxy:latest to Docker Hub..."
    docker push "reductrai/proxy:latest"
fi

echo "✅ Proxy image published successfully"
echo ""

echo "================================================"
echo "2/3 Building and Publishing Dashboard Image"
echo "================================================"

echo "🔨 Building reductrai/dashboard:$VERSION..."
docker build \
    -t "reductrai/dashboard:$VERSION" \
    -t "reductrai/dashboard:latest" \
    -f "dockerfiles/Dockerfile.dashboard" \
    "$DASHBOARD_DIR"

echo "✅ Build complete"
echo ""
echo "📤 Pushing reductrai/dashboard:$VERSION to Docker Hub..."
docker push "reductrai/dashboard:$VERSION"

if [ "$VERSION" != "latest" ]; then
    echo "📤 Pushing reductrai/dashboard:latest to Docker Hub..."
    docker push "reductrai/dashboard:latest"
fi

echo "✅ Dashboard image published successfully"
echo ""

echo "================================================"
echo "3/4 Building and Publishing AI Query Image"
echo "================================================"

echo "🔨 Building reductrai/ai-query:$VERSION..."
docker build \
    -t "reductrai/ai-query:$VERSION" \
    -t "reductrai/ai-query:latest" \
    -f "dockerfiles/Dockerfile.ai-query" \
    "$AI_QUERY_DIR"

echo "✅ Build complete"
echo ""
echo "📤 Pushing reductrai/ai-query:$VERSION to Docker Hub..."
docker push "reductrai/ai-query:$VERSION"

if [ "$VERSION" != "latest" ]; then
    echo "📤 Pushing reductrai/ai-query:latest to Docker Hub..."
    docker push "reductrai/ai-query:latest"
fi

echo "✅ AI Query image published successfully"
echo ""

echo "================================================"
echo "4/4 Building and Publishing All-in-One Image"
echo "================================================"

echo "🔨 Building reductrai/reductrai:$VERSION (all-in-one)..."
docker build \
    -t "reductrai/reductrai:$VERSION" \
    -t "reductrai/reductrai:latest" \
    -f "dockerfiles/Dockerfile.all-in-one" \
    .

echo "✅ Build complete"
echo ""
echo "📤 Pushing reductrai/reductrai:$VERSION to Docker Hub..."
docker push "reductrai/reductrai:$VERSION"

if [ "$VERSION" != "latest" ]; then
    echo "📤 Pushing reductrai/reductrai:latest to Docker Hub..."
    docker push "reductrai/reductrai:latest"
fi

echo "✅ All-in-one image published successfully"
echo ""

# Show published images
echo "================================================"
echo "✨ All Images Published Successfully!"
echo "================================================"
echo ""
echo "📋 Published images on Docker Hub:"
echo "   - reductrai/proxy:$VERSION"
echo "   - reductrai/dashboard:$VERSION"
echo "   - reductrai/ai-query:$VERSION"
echo "   - reductrai/reductrai:$VERSION (all-in-one)"

if [ "$VERSION" != "latest" ]; then
    echo "   - reductrai/proxy:latest"
    echo "   - reductrai/dashboard:latest"
    echo "   - reductrai/ai-query:latest"
    echo "   - reductrai/reductrai:latest (all-in-one)"
fi

echo ""
echo "📋 Local images:"
docker images | grep -E "^reductrai/(proxy|dashboard|ai-query|reductrai)" | head -10

echo ""
echo "================================================"
echo "✅ PUBLISH COMPLETE"
echo "================================================"
echo ""
echo "Users can now run:"
echo "  docker-compose pull"
echo "  docker-compose up -d"
echo ""
echo "Or specify version:"
echo "  REDUCTRAI_VERSION=$VERSION docker-compose up -d"
echo ""
