#!/bin/bash
set -e

# ReductrAI Docker Image Build Script
# This script builds all ReductrAI Docker images from source

echo "🏗️  Building ReductrAI Docker Images"
echo "===================================="

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: Must run from reductrai-docker directory"
    exit 1
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
echo "📦 Building version: $VERSION"
echo ""

# Build proxy image
echo "🔨 Building reductrai/proxy:$VERSION..."
docker build \
    -t "reductrai/proxy:$VERSION" \
    -t "reductrai/proxy:latest" \
    -f "$PROXY_DIR/Dockerfile.prod" \
    "$PROXY_DIR"

echo "✅ reductrai/proxy:$VERSION built successfully"
echo ""

# Build dashboard image
echo "🔨 Building reductrai/dashboard:$VERSION..."
docker build \
    -t "reductrai/dashboard:$VERSION" \
    -t "reductrai/dashboard:latest" \
    -f "$DASHBOARD_DIR/Dockerfile" \
    "$DASHBOARD_DIR"

echo "✅ reductrai/dashboard:$VERSION built successfully"
echo ""

# Build AI query image
echo "🔨 Building reductrai/ai-query:$VERSION..."
docker build \
    -t "reductrai/ai-query:$VERSION" \
    -t "reductrai/ai-query:latest" \
    -f "$AI_QUERY_DIR/Dockerfile" \
    "$AI_QUERY_DIR"

echo "✅ reductrai/ai-query:$VERSION built successfully"
echo ""

# Build Ollama image
echo "🔨 Building reductrai/ollama:$VERSION..."
docker build \
    -t "reductrai/ollama:$VERSION" \
    -t "reductrai/ollama:latest" \
    -f "$OLLAMA_DIR/Dockerfile" \
    "$OLLAMA_DIR"

echo "✅ reductrai/ollama:$VERSION built successfully"
echo ""

# Show built images
echo "📋 Built images:"
docker images | grep -E "^reductrai/(proxy|dashboard|ai-query|ollama)" | head -8

echo ""
echo "✨ All images built successfully!"
echo ""
echo "Next steps:"
echo "  1. Configure .env file:"
echo "     cp .env.example .env"
echo "     nano .env"
echo ""
echo "  2. Start services:"
echo "     docker-compose up -d"
echo ""
echo "  3. Check health:"
echo "     curl http://localhost:8080/health"
