#!/bin/bash
set -e

# ReductrAI Docker Installation Script
# This script downloads and sets up ReductrAI with all services

echo "==========================================="
echo "  ReductrAI Installation"
echo "==========================================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker is not installed"
    echo "   Please install Docker first: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Error: Docker Compose is not installed"
    echo "   Please install Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

# Create installation directory
INSTALL_DIR="${1:-./reductrai}"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo "📦 Installing to: $(pwd)"
echo ""

# Download docker-compose.yml
echo "📥 Downloading docker-compose.yml..."
curl -fsSL https://raw.githubusercontent.com/reductrai/docker/main/docker-compose.yml -o docker-compose.yml

# Download .env.example
echo "📥 Downloading .env.example..."
curl -fsSL https://raw.githubusercontent.com/reductrai/docker/main/.env.example -o .env.example

echo "✅ Files downloaded"
echo ""

# Check if .env already exists
if [ -f .env ]; then
    echo "⚠️  .env file already exists, skipping configuration"
else
    echo "🔧 Configuration Setup"
    echo "======================"
    echo ""

    # Prompt for license key
    read -p "Enter your ReductrAI License Key (or press Enter for trial 'RF-DEMO-2025'): " LICENSE_KEY
    LICENSE_KEY="${LICENSE_KEY:-RF-DEMO-2025}"

    # Prompt for monitoring service
    echo ""
    echo "Which monitoring service are you using?"
    echo "  1) Datadog"
    echo "  2) New Relic"
    echo "  3) Prometheus"
    echo "  4) Other (I'll configure manually)"
    read -p "Select (1-4): " SERVICE_CHOICE

    DATADOG_API_KEY=""
    NEW_RELIC_API_KEY=""
    PROMETHEUS_ENDPOINT=""

    case $SERVICE_CHOICE in
        1)
            read -p "Enter your Datadog API Key: " DATADOG_API_KEY
            ;;
        2)
            read -p "Enter your New Relic API Key: " NEW_RELIC_API_KEY
            ;;
        3)
            read -p "Enter your Prometheus endpoint (e.g., http://prometheus:9090): " PROMETHEUS_ENDPOINT
            ;;
        4)
            echo "You can configure your monitoring service later in the .env file"
            ;;
        *)
            echo "Invalid choice, you can configure later in .env"
            ;;
    esac

    # Create .env file
    cat > .env << EOF
# ================================================================================
# REDUCTRAI LICENSE (REQUIRED)
# ================================================================================
REDUCTRAI_LICENSE_KEY=${LICENSE_KEY}

# ================================================================================
# BACKEND MONITORING SERVICE (REQUIRED FOR PRODUCTION)
# ================================================================================
# Datadog
DATADOG_API_KEY=${DATADOG_API_KEY}
DATADOG_ENDPOINT=https://api.datadoghq.com

# New Relic
NEW_RELIC_API_KEY=${NEW_RELIC_API_KEY}

# Prometheus
PROMETHEUS_ENDPOINT=${PROMETHEUS_ENDPOINT}

# ================================================================================
# PROXY CONFIGURATION
# ================================================================================
NODE_ENV=production
REDUCTRAI_COMPRESSION=true
REDUCTRAI_COMPRESSION_LEVEL=heavy
PROXY_MODE=sample
SAMPLE_RATE=0.1

# ================================================================================
# TIERED STORAGE
# ================================================================================
STORAGE_HOT_ENABLED=true
STORAGE_HOT_RETENTION_DAYS=7
STORAGE_WARM_ENABLED=true
STORAGE_WARM_RETENTION_DAYS=30
STORAGE_COLD_ENABLED=true
STORAGE_COLD_RETENTION_DAYS=365
STORAGE_COLD_TYPE=local
EOF

    echo ""
    echo "✅ Configuration saved to .env"
fi

echo ""
echo "🚀 Starting ReductrAI services..."
echo ""

# Pull images
docker-compose pull

# Start services
docker-compose up -d

echo ""
echo "⏳ Waiting for services to be healthy (30 seconds)..."
sleep 30

# Check health
if curl -sf http://localhost:8080/health > /dev/null; then
    echo ""
    echo "==========================================="
    echo "  ✅ ReductrAI Installation Complete!"
    echo "==========================================="
    echo ""
    echo "📊 Services running:"
    echo "   • Proxy:     http://localhost:8080"
    echo "   • Metrics:   http://localhost:8080/metrics"
    echo "   • Health:    http://localhost:8080/health"
    echo ""
    echo "🔧 Next steps:"
    echo "   1. Point your applications to http://localhost:8080"
    echo "   2. View metrics at http://localhost:8080/metrics"
    echo "   3. Check health: curl http://localhost:8080/health"
    echo "   4. Optional: Enable AI services with: docker-compose --profile ai up -d"
    echo ""
    echo "📊 Monitoring:"
    echo "   • Dashboard is deprecated - Use /metrics endpoint with Prometheus/Grafana"
    echo "   • For natural language queries, enable AI services (see step 4 above)"
    echo ""
    echo "📚 Documentation:"
    echo "   • Storage Guide: https://github.com/reductrai/docker/blob/main/STORAGE.md"
    echo "   • Security Guide: https://github.com/reductrai/docker/blob/main/SECURITY.md"
    echo "   • HA Guide: https://github.com/reductrai/docker/blob/main/HIGH-AVAILABILITY.md"
    echo ""
    echo "💡 Need help? support@reductrai.com"
    echo ""
else
    echo ""
    echo "⚠️  Services started but health check failed"
    echo "   Check logs: docker-compose logs"
    echo "   Try: curl http://localhost:8080/health"
    echo ""
fi
