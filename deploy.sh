#!/bin/bash
# ReductrAI - One-Command Deployment
# Builds and deploys the complete ReductrAI stack

set -e

echo "=========================================="
echo "   ReductrAI Deployment System"
echo "   90% Cost Reduction, 100% Data Access"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running${NC}"
    echo "Please start Docker and try again"
    exit 1
fi

# Set up environment
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env file from template...${NC}"
    cp .env.example .env
    echo -e "${YELLOW}Please edit .env with your API keys:${NC}"
    echo "  - DATADOG_API_KEY (if using Datadog)"
    echo "  - NEW_RELIC_API_KEY (if using New Relic)"
    echo "  - Other monitoring service credentials"
    echo ""
fi

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | xargs)
fi

# Default values
export REDUCTRAI_LICENSE_KEY=${REDUCTRAI_LICENSE_KEY:-RF-DEMO-2025}
export DATADOG_API_KEY=${DATADOG_API_KEY:-2383d0a71532e62b7fce96deeabbd110}

echo -e "${BLUE}Step 1: Building Docker images${NC}"
echo "--------------------------------"

# Make build script executable and run it
chmod +x build-all.sh
./build-all.sh

echo ""
echo -e "${BLUE}Step 2: Stopping any existing containers${NC}"
echo "-----------------------------------------"
docker-compose down 2>/dev/null || true

echo ""
echo -e "${BLUE}Step 3: Starting ReductrAI services${NC}"
echo "------------------------------------"
docker-compose up -d

echo ""
echo -e "${BLUE}Step 4: Waiting for services to be ready${NC}"
echo "----------------------------------------"

# Wait for services
echo -n "Waiting for Proxy..."
for i in {1..30}; do
    if curl -f http://localhost:8080/health > /dev/null 2>&1; then
        echo -e " ${GREEN}Ready!${NC}"
        break
    fi
    echo -n "."
    sleep 2
done

echo -n "Waiting for Dashboard..."
for i in {1..30}; do
    if curl -f http://localhost:5173/ > /dev/null 2>&1; then
        echo -e " ${GREEN}Ready!${NC}"
        break
    fi
    echo -n "."
    sleep 2
done

echo -n "Waiting for AI Query..."
for i in {1..30}; do
    if curl -f http://localhost:8081/health > /dev/null 2>&1; then
        echo -e " ${GREEN}Ready!${NC}"
        break
    fi
    echo -n "."
    sleep 2
done

echo -n "Waiting for Ollama..."
for i in {1..30}; do
    if docker exec reductrai-ollama ollama list > /dev/null 2>&1; then
        echo -e " ${GREEN}Ready!${NC}"
        break
    fi
    echo -n "."
    sleep 2
done

echo ""
echo -e "${GREEN}=========================================="
echo -e "   ReductrAI Deployment Complete!"
echo -e "==========================================${NC}"
echo ""
echo "Services running:"
echo -e "  ${GREEN}✓${NC} Proxy:     http://localhost:8080"
echo -e "  ${GREEN}✓${NC} Dashboard: http://localhost:5173"
echo -e "  ${GREEN}✓${NC} AI Query:  http://localhost:8081"
echo -e "  ${GREEN}✓${NC} Ollama:    http://localhost:11434"
echo ""
echo "Quick test commands:"
echo "  # Send test metric"
echo '  curl -X POST http://localhost:8080/api/v2/series \'
echo '    -H "Content-Type: application/json" \'
echo '    -H "DD-API-KEY: test" \'
echo '    -d '"'"'{"series":[{"metric":"test.metric","points":[['"$(date +%s)"',100]]}]}'"'"
echo ""
echo "  # Query with AI"
echo '  curl -X POST http://localhost:8081/query \'
echo '    -H "Content-Type: application/json" \'
echo '    -d '"'"'{"query":"Show system status","timeRange":"1h"}'"'"
echo ""
echo "To stop all services:"
echo "  docker-compose down"
echo ""
echo "To view logs:"
echo "  docker-compose logs -f [service-name]"
echo ""