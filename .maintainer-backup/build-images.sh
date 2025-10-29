#!/bin/bash
set -e

# ReductrAI Docker Image Build Script
# This script builds all ReductrAI Docker images from source
# Note: Dashboard is deprecated as of 2025-10-26 (AI-first architecture)

echo "🏗️  Building ReductrAI Docker Images"
echo "===================================="

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: Must run from reductrai-docker directory"
    exit 1
fi

# Check if source directories exist
PROXY_DIR="../reductrai-proxy"
AI_QUERY_DIR="../reductrai-ai-query"

if [ ! -d "$PROXY_DIR" ]; then
    echo "❌ Error: $PROXY_DIR not found"
    echo "   Please clone all repositories in the same parent directory:"
    echo "   - reductrai-proxy"
    echo "   - reductrai-ai-query"
    echo "   - reductrai-docker (this repo)"
    exit 1
fi

if [ ! -d "$AI_QUERY_DIR" ]; then
    echo "❌ Error: $AI_QUERY_DIR not found"
    exit 1
fi

# Version tag (default to 'latest', or use first argument)
VERSION="${1:-latest}"

echo ""
echo "📦 Building version: $VERSION"
echo ""

# Build proxy image
echo "🔨 Building reductrai/proxy:$VERSION..."
docker build \
    -t "reductrai/proxy:$VERSION" \
    -t "reductrai/proxy:latest" \
    -f "dockerfiles/Dockerfile.proxy" \
    .

echo "✅ reductrai/proxy:$VERSION built successfully"
echo ""

# Build AI query image
echo "🔨 Building reductrai/ai-query:$VERSION..."
docker build \
    -t "reductrai/ai-query:$VERSION" \
    -t "reductrai/ai-query:latest" \
    -f "dockerfiles/Dockerfile.ai-query" \
    "$AI_QUERY_DIR"

echo "✅ reductrai/ai-query:$VERSION built successfully"
echo ""

# Build all-in-one image (Proxy + Dashboard + AI Query + Ollama)
echo "🔨 Building reductrai/reductrai:$VERSION (all-in-one)..."
docker build \
    -t "reductrai/reductrai:$VERSION" \
    -t "reductrai/reductrai:latest" \
    -f "dockerfiles/Dockerfile.all-in-one" \
    .

echo "✅ reductrai/reductrai:$VERSION built successfully"
echo ""

# Show built images
echo "📋 Built images:"
docker images | grep -E "^reductrai/(proxy|ai-query|reductrai)" | head -10

echo ""
echo "✨ All images built successfully!"
echo ""
echo "Next steps:"
echo "  1. Configure .env file:"
echo "     cp .env.example .env"
echo "     nano .env"
echo ""
echo "  2. Start services (proxy only):"
echo "     docker-compose up -d"
echo ""
echo "  3. Or start with AI services:"
echo "     docker-compose --profile ai up -d"
echo ""
echo "  4. Check health:"
echo "     curl http://localhost:8080/health"
echo ""
echo "Note: Dashboard is deprecated. Use /metrics endpoint with Prometheus/Grafana"
echo "      or AI Query service for natural language analysis."
