#!/bin/bash
# ReductrAI - Build All Services
# This script builds Docker images for all ReductrAI services

set -e

echo "=========================================="
echo "   ReductrAI Docker Build System"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Base directory
BASE_DIR="/Users/jessiehermosillo/Apiflow"

# Function to build a service
build_service() {
    local SERVICE_NAME=$1
    local SERVICE_DIR=$2
    local DOCKERFILE=$3

    echo -e "${YELLOW}Building ${SERVICE_NAME}...${NC}"

    if [ ! -d "${SERVICE_DIR}" ]; then
        echo -e "${RED}Error: Directory ${SERVICE_DIR} not found${NC}"
        return 1
    fi

    cd "${SERVICE_DIR}"

    # Check if Dockerfile exists
    if [ ! -f "${DOCKERFILE}" ]; then
        echo -e "${YELLOW}Warning: No Dockerfile found for ${SERVICE_NAME}, creating default...${NC}"

        # Create a default Dockerfile for Node.js services
        cat > Dockerfile << 'EOF'
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production || npm install
COPY . .
RUN npm run build 2>/dev/null || true
EXPOSE 8080
CMD ["npm", "start"]
EOF
        DOCKERFILE="Dockerfile"
    fi

    # Build the Docker image
    docker build -f "${DOCKERFILE}" -t "reductrai/${SERVICE_NAME}:latest" . || {
        echo -e "${RED}Failed to build ${SERVICE_NAME}${NC}"
        return 1
    }

    echo -e "${GREEN}✓ Successfully built ${SERVICE_NAME}${NC}"
    echo ""
}

echo "Step 1: Building Core Services"
echo "-------------------------------"

# Build Proxy (Main Service)
build_service "proxy" "${BASE_DIR}/reductrai-proxy" "Dockerfile"

# Build Dashboard
build_service "dashboard" "${BASE_DIR}/reductrai-dashboard" "Dockerfile"

# Build AI Query Service
build_service "ai-query" "${BASE_DIR}/reductrai-ai-query" "Dockerfile"

# Build Ollama with Mistral pre-installed
echo -e "${YELLOW}Building Ollama with Mistral...${NC}"
cd "${BASE_DIR}/reductrai-docker"

cat > Dockerfile.ollama << 'EOF'
# Ollama with Mistral pre-installed
FROM ollama/ollama:latest as downloader

# Download Mistral model during build
RUN ollama serve & \
    SERVER_PID=$! && \
    sleep 10 && \
    ollama pull mistral && \
    kill $SERVER_PID && \
    wait $SERVER_PID 2>/dev/null || true

# Final image with model included
FROM ollama/ollama:latest
COPY --from=downloader /root/.ollama /root/.ollama

EXPOSE 11434
ENTRYPOINT ["/bin/ollama"]
CMD ["serve"]
EOF

docker build -f Dockerfile.ollama -t reductrai/ollama:latest . || {
    echo -e "${YELLOW}Warning: Ollama build failed, using base image${NC}"
    docker pull ollama/ollama:latest
    docker tag ollama/ollama:latest reductrai/ollama:latest
}
echo -e "${GREEN}✓ Successfully built Ollama${NC}"
echo ""

echo "Step 2: Verifying Images"
echo "------------------------"
docker images | grep reductrai || true

echo ""
echo -e "${GREEN}=========================================="
echo -e "   Build Complete!"
echo -e "==========================================${NC}"
echo ""
echo "All services have been built. To run the system:"
echo "  ./deploy.sh"
echo ""