#!/bin/bash
# ReductrAI Standalone Package Builder
# Creates a distributable standalone package with all services

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
VERSION=${VERSION:-"1.0.0"}
PACKAGE_NAME="reductrai-standalone-v${VERSION}"
BUILD_DIR="./build/${PACKAGE_NAME}"
DIST_DIR="./dist"

# Source directories (relative to monorepo root)
MONOREPO_ROOT="../"
PROXY_DIR="${MONOREPO_ROOT}reductrai-proxy"
DASHBOARD_DIR="${MONOREPO_ROOT}reductrai-dashboard"
AI_QUERY_DIR="${MONOREPO_ROOT}reductrai-ai-query"
CORE_DIR="${MONOREPO_ROOT}reductrai-core"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}ReductrAI Standalone Package Builder${NC}"
echo -e "${GREEN}Version: ${VERSION}${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Clean previous build
echo -e "${YELLOW}🧹 Cleaning previous build...${NC}"
rm -rf ./build
rm -rf "${DIST_DIR}/${PACKAGE_NAME}.tar.gz"
mkdir -p "${BUILD_DIR}"
mkdir -p "${DIST_DIR}"

# Build Proxy Service
echo -e "${YELLOW}📦 Building proxy service...${NC}"
if [ -d "$PROXY_DIR" ]; then
    cd "$PROXY_DIR"
    npm run build || { echo -e "${RED}❌ Proxy build failed${NC}"; exit 1; }
    cd - > /dev/null

    # Copy proxy files
    mkdir -p "${BUILD_DIR}/proxy"
    cp -r "${PROXY_DIR}/dist" "${BUILD_DIR}/proxy/"
    cp -r "${PROXY_DIR}/apps" "${BUILD_DIR}/proxy/"
    cp -r "${PROXY_DIR}/node_modules" "${BUILD_DIR}/proxy/"
    cp "${PROXY_DIR}/package.json" "${BUILD_DIR}/proxy/"
    cp "${PROXY_DIR}/tsconfig.json" "${BUILD_DIR}/proxy/" 2>/dev/null || true
    echo -e "${GREEN}✅ Proxy service built${NC}"
else
    echo -e "${RED}❌ Proxy directory not found: ${PROXY_DIR}${NC}"
    exit 1
fi

# Build Dashboard
echo -e "${YELLOW}📦 Building dashboard...${NC}"
if [ -d "$DASHBOARD_DIR" ]; then
    cd "$DASHBOARD_DIR"
    npm run build || { echo -e "${RED}❌ Dashboard build failed${NC}"; exit 1; }
    cd - > /dev/null

    # Copy dashboard files
    mkdir -p "${BUILD_DIR}/dashboard"
    cp -r "${DASHBOARD_DIR}/dist" "${BUILD_DIR}/dashboard/"
    echo -e "${GREEN}✅ Dashboard built${NC}"
else
    echo -e "${RED}❌ Dashboard directory not found: ${DASHBOARD_DIR}${NC}"
    exit 1
fi

# Build AI Query Service
echo -e "${YELLOW}📦 Building AI query service...${NC}"
if [ -d "$AI_QUERY_DIR" ]; then
    cd "$AI_QUERY_DIR"
    npm run build || { echo -e "${RED}❌ AI Query build failed${NC}"; exit 1; }
    cd - > /dev/null

    # Copy ai-query files
    mkdir -p "${BUILD_DIR}/ai-query"
    cp -r "${AI_QUERY_DIR}/dist" "${BUILD_DIR}/ai-query/"
    cp -r "${AI_QUERY_DIR}/node_modules" "${BUILD_DIR}/ai-query/"
    cp "${AI_QUERY_DIR}/package.json" "${BUILD_DIR}/ai-query/"
    echo -e "${GREEN}✅ AI Query service built${NC}"
else
    echo -e "${YELLOW}⚠️  AI Query directory not found (optional): ${AI_QUERY_DIR}${NC}"
fi

# Create bin directory with start/stop scripts
echo -e "${YELLOW}📝 Creating management scripts...${NC}"
mkdir -p "${BUILD_DIR}/bin"

# Create start-all script
cat > "${BUILD_DIR}/bin/start.sh" <<'EOF'
#!/bin/bash
# Start all ReductrAI services

set -e

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Starting ReductrAI services...${NC}"

# Create data and logs directories
mkdir -p data/compression-logs
mkdir -p logs

# Start proxy
echo -e "${GREEN}Starting proxy on port 8080...${NC}"
cd proxy
NODE_ENV=production npx tsx apps/proxy/src/index.ts > ../logs/proxy.log 2>&1 &
echo $! > ../logs/proxy.pid
cd ..

# Wait for proxy to start
sleep 3

# Start dashboard (nginx or http-server)
if command -v http-server &> /dev/null; then
    echo -e "${GREEN}Starting dashboard on port 5173...${NC}"
    http-server dashboard/dist -p 5173 > logs/dashboard.log 2>&1 &
    echo $! > logs/dashboard.pid
elif command -v python3 &> /dev/null; then
    echo -e "${GREEN}Starting dashboard on port 5173 (Python)...${NC}"
    cd dashboard/dist
    python3 -m http.server 5173 > ../../logs/dashboard.log 2>&1 &
    echo $! > ../../logs/dashboard.pid
    cd ../..
else
    echo -e "⚠️  No HTTP server found. Install http-server: npm install -g http-server"
fi

# Start AI Query (optional)
if [ -d "ai-query" ]; then
    echo -e "${GREEN}Starting AI Query on port 8081...${NC}"
    cd ai-query
    node dist/server.js > ../logs/ai-query.log 2>&1 &
    echo $! > ../logs/ai-query.pid
    cd ..
fi

# Start Ollama (if installed)
if command -v ollama &> /dev/null; then
    echo -e "${GREEN}Starting Ollama on port 11434...${NC}"
    ollama serve > logs/ollama.log 2>&1 &
    echo $! > logs/ollama.pid
fi

echo -e "${GREEN}✅ All services started!${NC}"
echo ""
echo "Services:"
echo "  - Proxy:     http://localhost:8080"
echo "  - Dashboard: http://localhost:5173"
echo "  - AI Query:  http://localhost:8081"
echo "  - Ollama:    http://localhost:11434"
echo ""
echo "Logs: ./logs/"
echo "Stop: ./bin/stop.sh"
EOF

# Create stop-all script
cat > "${BUILD_DIR}/bin/stop.sh" <<'EOF'
#!/bin/bash
# Stop all ReductrAI services

# Colors
RED='\033[0;31m'
NC='\033[0m'

echo -e "${RED}Stopping ReductrAI services...${NC}"

# Stop services using PID files
for pidfile in logs/*.pid; do
    if [ -f "$pidfile" ]; then
        pid=$(cat "$pidfile")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            echo -e "${RED}Stopped $(basename $pidfile .pid)${NC}"
        fi
        rm "$pidfile"
    fi
done

echo -e "${RED}✅ All services stopped${NC}"
EOF

# Create proxy-only script
cat > "${BUILD_DIR}/bin/proxy.sh" <<'EOF'
#!/bin/bash
# Start only the proxy service

set -e

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

mkdir -p data/compression-logs
mkdir -p logs

echo "Starting ReductrAI Proxy on port 8080..."
cd proxy
NODE_ENV=production npx tsx apps/proxy/src/index.ts
EOF

# Create dashboard-only script
cat > "${BUILD_DIR}/bin/dashboard.sh" <<'EOF'
#!/bin/bash
# Start only the dashboard

set -e

echo "Starting ReductrAI Dashboard on port 5173..."

if command -v http-server &> /dev/null; then
    http-server dashboard/dist -p 5173
elif command -v python3 &> /dev/null; then
    cd dashboard/dist
    python3 -m http.server 5173
else
    echo "❌ No HTTP server found. Install http-server: npm install -g http-server"
    exit 1
fi
EOF

# Create ai-query-only script
cat > "${BUILD_DIR}/bin/ai-query.sh" <<'EOF'
#!/bin/bash
# Start only the AI Query service

set -e

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

mkdir -p logs

if [ ! -d "ai-query" ]; then
    echo "❌ AI Query service not included in this package"
    exit 1
fi

echo "Starting ReductrAI AI Query on port 8081..."
cd ai-query
node dist/server.js
EOF

# Make scripts executable
chmod +x "${BUILD_DIR}/bin/"*.sh

# Create config directory
echo -e "${YELLOW}📝 Creating configuration files...${NC}"
mkdir -p "${BUILD_DIR}/config"

# Create .env.example
cat > "${BUILD_DIR}/config/.env.example" <<'EOF'
# ReductrAI Configuration

# License (Required)
REDUCTRAI_LICENSE_KEY=RF-DEMO-2025

# Proxy Configuration
REDUCTRAI_PORT=8080
REDUCTRAI_HOST=0.0.0.0
REDUCTRAI_COMPRESSION=true
REDUCTRAI_COMPRESSION_LEVEL=heavy  # light|medium|heavy

# Proxy Mode
PROXY_MODE=sample  # forward-all|sample|query-only
SAMPLE_RATE=0.1    # 0.1 = 10% forwarded, 90% cost savings

# Datadog Integration (Optional)
DATADOG_API_KEY=
DATADOG_ENDPOINT=https://api.datadoghq.com

# New Relic Integration (Optional)
NEW_RELIC_API_KEY=

# Prometheus Integration (Optional)
PROMETHEUS_ENDPOINT=http://prometheus:9090

# OTLP Integration (Optional)
OTLP_ENDPOINT=http://jaeger:4318

# Forward Destination
FORWARD_TO=https://api.datadoghq.com

# AI Query Configuration (Optional)
LOCAL_LLM_ENDPOINT=http://localhost:8081
OLLAMA_HOST=http://localhost:11434
AI_MODEL=mistral
AI_QUERY_PORT=8081

# Storage Configuration
STORAGE_BACKEND=local  # local|s3|gcs|azure|redis|postgresql
STORAGE_PATH=/app/data/compression-logs

# S3 Configuration (if STORAGE_BACKEND=s3)
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
S3_BUCKET=

# GCS Configuration (if STORAGE_BACKEND=gcs)
GCP_PROJECT_ID=
GCS_BUCKET=
GCS_KEYFILE=/path/to/keyfile.json

# Azure Configuration (if STORAGE_BACKEND=azure)
AZURE_STORAGE_ACCOUNT=
AZURE_STORAGE_KEY=
AZURE_CONTAINER=

# Redis Configuration (if STORAGE_BACKEND=redis)
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0

# PostgreSQL Configuration (if STORAGE_BACKEND=postgresql)
PG_HOST=localhost
PG_PORT=5432
PG_DATABASE=reductrai
PG_USER=postgres
PG_PASSWORD=
EOF

# Create README for package
cat > "${BUILD_DIR}/README.md" <<'EOF'
# ReductrAI Standalone Package

This is a standalone distribution of ReductrAI - the AI SRE Proxy that provides full observability at 10% of the cost.

## Quick Start

1. **Configure environment variables:**
   ```bash
   cp config/.env.example .env
   nano .env  # Add your license key and configuration
   ```

2. **Start all services:**
   ```bash
   ./bin/start.sh
   ```

3. **Verify services are running:**
   ```bash
   curl http://localhost:8080/health    # Proxy
   curl http://localhost:5173           # Dashboard
   curl http://localhost:8081/health    # AI Query
   ```

4. **Stop services:**
   ```bash
   ./bin/stop.sh
   ```

## Requirements

- Node.js 20.x or higher
- npm 10.x or higher
- Ollama (optional, for AI queries)

## Individual Services

Start individual services:

```bash
./bin/proxy.sh        # Proxy only (port 8080)
./bin/dashboard.sh    # Dashboard only (port 5173)
./bin/ai-query.sh     # AI Query only (port 8081)
```

## Directory Structure

```
reductrai-standalone/
├── bin/                    # Start/stop scripts
│   ├── start.sh           # Start all services
│   ├── stop.sh            # Stop all services
│   ├── proxy.sh           # Proxy only
│   ├── dashboard.sh       # Dashboard only
│   └── ai-query.sh        # AI Query only
├── proxy/                 # Proxy service
├── dashboard/             # Dashboard UI
├── ai-query/              # AI Query service
├── config/                # Configuration
│   └── .env.example       # Environment template
├── data/                  # Data storage
├── logs/                  # Service logs
└── README.md              # This file
```

## Configuration

Edit `.env` file to configure:

- **License key** (required)
- **Backend integrations** (Datadog, New Relic, Prometheus, OTLP)
- **Compression settings** (level, mode, sample rate)
- **Storage backend** (local, S3, GCS, Azure, Redis, PostgreSQL)
- **AI model** (Mistral, Llama2)

## Storage Options

### Local Storage (Default)
```bash
STORAGE_BACKEND=local
STORAGE_PATH=/app/data/compression-logs
```

### Amazon S3
```bash
STORAGE_BACKEND=s3
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
S3_BUCKET=your-bucket
```

### Google Cloud Storage
```bash
STORAGE_BACKEND=gcs
GCP_PROJECT_ID=your-project
GCS_BUCKET=your-bucket
GCS_KEYFILE=/path/to/keyfile.json
```

### Azure Blob Storage
```bash
STORAGE_BACKEND=azure
AZURE_STORAGE_ACCOUNT=your_account
AZURE_STORAGE_KEY=your_key
AZURE_CONTAINER=your-container
```

### Redis
```bash
STORAGE_BACKEND=redis
REDIS_HOST=localhost
REDIS_PORT=6379
```

### PostgreSQL
```bash
STORAGE_BACKEND=postgresql
PG_HOST=localhost
PG_PORT=5432
PG_DATABASE=reductrai
PG_USER=postgres
PG_PASSWORD=your_password
```

## Monitoring

View logs:
```bash
tail -f logs/proxy.log
tail -f logs/dashboard.log
tail -f logs/ai-query.log
```

Check proxy statistics:
```bash
curl http://localhost:8080/metrics | jq
```

## Troubleshooting

### Proxy won't start
- Check logs: `cat logs/proxy.log`
- Verify license key in `.env`
- Ensure port 8080 is not in use: `lsof -i :8080`

### Dashboard won't start
- Install http-server: `npm install -g http-server`
- Or use Python: `python3 -m http.server 5173`

### AI Query won't start
- Install Ollama: https://ollama.ai
- Pull model: `ollama pull mistral`
- Start Ollama: `ollama serve`

## Support

- Documentation: https://docs.reductrai.com
- GitHub: https://github.com/reductrai/reductrai
- Email: support@reductrai.com
- Enterprise: enterprise@reductrai.com

## License

This software requires a valid ReductrAI license key.
Demo license: RF-DEMO-2025 (for testing only)

---

**Version:** 1.0.0
**Built:** $(date)
EOF

# Create data and logs directories
mkdir -p "${BUILD_DIR}/data/compression-logs"
mkdir -p "${BUILD_DIR}/logs"

# Create package tarball
echo -e "${YELLOW}📦 Creating tarball...${NC}"
cd ./build
tar -czf "../${DIST_DIR}/${PACKAGE_NAME}.tar.gz" "${PACKAGE_NAME}"
cd ..

# Calculate size
SIZE=$(du -h "${DIST_DIR}/${PACKAGE_NAME}.tar.gz" | cut -f1)

# Success message
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Package created successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "📦 Package: ${DIST_DIR}/${PACKAGE_NAME}.tar.gz"
echo -e "📊 Size: ${SIZE}"
echo ""
echo -e "To install:"
echo -e "  tar -xzf ${PACKAGE_NAME}.tar.gz"
echo -e "  cd ${PACKAGE_NAME}"
echo -e "  cp config/.env.example .env"
echo -e "  nano .env  # Configure license key"
echo -e "  ./bin/start.sh"
echo ""
echo -e "${GREEN}Package ready for distribution!${NC}"
