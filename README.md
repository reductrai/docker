# ReductrAI Docker Distribution

Official Docker images and deployment configurations for ReductrAI - AI SRE Proxy that provides full observability at 10% of the cost.

**For comprehensive deployment documentation covering all options (All-in-One, Docker Compose, Standalone, Kubernetes), see [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md)**

## Quick Start

### Option 1: One-Line Installer (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/reductrai/docker/main/install.sh | bash
```

The installer will:
- Download docker-compose.yml and .env.example
- Prompt for your API keys (Datadog, New Relic, etc.)
- Create .env configuration
- Pull Docker images from Docker Hub
- Start all services
- Verify health

### Option 2: Manual Setup

```bash
# Download configuration files
curl -O https://raw.githubusercontent.com/reductrai/docker/main/docker-compose.yml
curl -O https://raw.githubusercontent.com/reductrai/docker/main/.env.example

# Configure environment
cp .env.example .env
nano .env  # Add your API keys

# Start services (images auto-pull from Docker Hub)
docker-compose up -d

# Verify
curl http://localhost:8080/health
```

### Option 3: All-in-One Container (Recommended for Getting Started)

Single container with ALL services (Proxy + Dashboard + AI Query + Ollama):

```bash
# Basic setup - just proxy and dashboard
docker run -d \
  --name reductrai \
  -p 8080:8080 \
  -p 5173:5173 \
  -e REDUCTRAI_LICENSE_KEY=RF-DEMO-2025 \
  -e DATADOG_API_KEY=your_datadog_key_here \
  -v reductrai-data:/app/data \
  reductrai/reductrai:latest

# With AI features and tiered storage
docker run -d \
  --name reductrai \
  -p 8080:8080 \
  -p 5173:5173 \
  -p 8081:8081 \
  -p 11434:11434 \
  -e REDUCTRAI_LICENSE_KEY=RF-DEMO-2025 \
  -e DATADOG_API_KEY=your_datadog_key_here \
  -e STORAGE_COLD_TYPE=s3 \
  -e S3_BUCKET=my-reductrai-bucket \
  -e S3_REGION=us-east-1 \
  -e S3_ACCESS_KEY=your_key \
  -e S3_SECRET_KEY=your_secret \
  -v reductrai-data:/app/data \
  reductrai/reductrai:latest

# Verify all services
curl http://localhost:8080/health  # Proxy
curl http://localhost:5173/        # Dashboard
curl http://localhost:8081/health  # AI Query
curl http://localhost:11434/api/tags # Ollama
```

### Option 4: Single Service (Proxy Only)

```bash
# Create configuration
cat > .env << 'EOF'
REDUCTRAI_LICENSE_KEY=RF-DEMO-2025
DATADOG_API_KEY=your_datadog_key_here
EOF

# Run proxy only (image auto-pulls from Docker Hub)
docker run -d \
  --name reductrai-proxy \
  -p 8080:8080 \
  --env-file .env \
  reductrai/proxy:latest

# Verify
curl http://localhost:8080/health
```

## Quick Start

After installation:

```bash
# 1. Verify services are running
docker ps

# 2. Check health
curl http://localhost:8080/health

# 3. Point your apps to ReductrAI instead of Datadog
#    BEFORE: DD_AGENT_HOST=api.datadoghq.com
#    AFTER:  DD_AGENT_HOST=localhost:8080

# 4. Access services
# Dashboard: http://localhost:5173
# Proxy API: http://localhost:8080
# AI Query:  http://localhost:8081
# Health:    http://localhost:8080/health
```

## How ReductrAI Saves You Money

**The Problem:** Datadog/NewRelic/etc charge based on data volume. More metrics = higher bills.

**The ReductrAI Solution:**

```
BEFORE ReductrAI:
Your Apps → Datadog
           (100% of data, $10,000/month)

AFTER ReductrAI:
Your Apps → ReductrAI Proxy → ┌─ Local Storage (100%, compressed, AI-queryable)
                               └─ Datadog (10% sampled, $1,000/month)
```

**What You Get:**
- ✅ Same Datadog dashboards (10% sample is statistically valid)
- ✅ 100% of data stored locally (compressed, fast queries)
- ✅ AI-powered natural language queries on ALL data
- ✅ 90% cost reduction on your monitoring bill

**How Tiered Storage Works:**
- 🔥 Hot (7 days): Full-resolution, instant queries
- 🌡️ Warm (30 days): 5-min aggregation, fast queries
- ❄️ Cold (365 days): 1-hr aggregation, cheap S3/GCS/Azure storage

## What Gets Deployed

This docker-compose configuration deploys a **complete ReductrAI stack**:

- **reductrai-proxy** (port 8080) - Universal monitoring proxy
  - Handles ALL observability data types:
    - **Metrics** → 88.6-91.1% compression (TimeSeriesAggregator)
    - **Logs** → 97.7-99.4% compression (ContextualDictionaryCompressor)
    - **Traces** → 99.3-99.7% compression (SpanPatternCompressor)
    - **Events** → 97.6-99.5% compression (SemanticCompressor)
  - Auto-detects ALL formats: Datadog, Prometheus, OTLP, StatsD, CloudWatch, Splunk, Loki, etc.
  - Stores 100% of data locally (compressed)
  - Forwards 10% sample to your monitoring service

- **reductrai-dashboard** (port 5173) - Real-time web UI
  - Live compression statistics
  - Pattern detection visualization
  - Data type breakdown

- **reductrai-ai-query** (port 8081) - AI-powered query service
  - Natural language queries against 100% of data
  - Correlation detection
  - Anomaly analysis

- **reductrai-ollama** (port 11434) - Local LLM service
  - Runs Mistral model for AI queries
  - No data sent to external APIs

## Universal Deployment

This is a **universal deployment** that works with:
- **ANY monitoring tool**:
  - ✅ Datadog
  - ✅ New Relic
  - ✅ Dynatrace
  - ✅ Prometheus / Grafana
  - ✅ Splunk
  - ✅ AppDynamics
  - ✅ Elastic APM
  - ✅ Honeycomb
  - ✅ Any tool with HTTP/JSON APIs
- **ANY data source**: Applications, servers, containers, Kubernetes, cloud services
- **ANY language or framework**: Node.js, Python, Java, Go, .NET, Ruby, PHP, etc.
- **ALL observability signals**: Metrics, Logs, Traces, Events

### Examples of What It Handles

**Metrics:**
- Datadog StatsD/DogStatsD metrics
- Prometheus metrics (OpenMetrics format)
- CloudWatch metrics
- Custom JSON metrics

**Logs:**
- Splunk HEC logs
- Grafana Loki logs
- CloudWatch Logs
- Datadog Logs API
- Custom structured/unstructured logs

**Traces:**
- OpenTelemetry (OTLP) traces
- Datadog APM traces
- Jaeger traces
- Zipkin traces

**Events:**
- Datadog Events API
- CloudWatch Events
- Custom application events

Just point your applications to `http://localhost:8080` instead of your monitoring service, and ReductrAI handles the rest.

### How It Works With Different Tools

**The proxy is completely transparent** - it sits between your application and your monitoring service:

```
Your App → ReductrAI Proxy (localhost:8080) → Your Monitoring Tool
            ↓
         Local Storage
         (100% of data, compressed)
```

**Configuration examples:**

```bash
# Instead of sending to Datadog directly:
# DD_AGENT_HOST=api.datadoghq.com
# Change to:
DD_AGENT_HOST=localhost:8080

# Instead of Prometheus remote write to Grafana Cloud:
# remote_write: url: https://prometheus-us-central1.grafana.net/api/prom/push
# Change to:
remote_write: url: http://localhost:8080/api/prom/push

# Instead of New Relic endpoint:
# OTEL_EXPORTER_OTLP_ENDPOINT=https://otlp.nr-data.net
# Change to:
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:8080

# Instead of Dynatrace:
# DT_ENDPOINT=https://abc123.live.dynatrace.com/api/v2
# Change to:
DT_ENDPOINT=http://localhost:8080/api/v2

# Instead of Splunk HEC:
# SPLUNK_HEC_URL=https://http-inputs-acme.splunkcloud.com
# Change to:
SPLUNK_HEC_URL=http://localhost:8080
```

**The proxy automatically:**
1. Detects the format (Datadog, Prometheus, OTLP, etc.)
2. Compresses and stores 100% locally
3. Forwards 10% sample to your actual monitoring service
4. Makes 100% queryable via AI

## Testing Your Deployment

Send test data to verify everything works:

```bash
# Simple health check
curl http://localhost:8080/health

# Send sample Datadog metric
curl -X POST http://localhost:8080/api/v2/series \
  -H "Content-Type: application/json" \
  -H "DD-API-KEY: test" \
  -d '{"series":[{"metric":"test.metric","points":[['"$(date +%s)"',123]],"type":0}]}'

# Check compression stats
curl http://localhost:8080/metrics | jq '.compressionLog | length'

# View in dashboard
open http://localhost:5173
```

## Configuration

See [docker-compose.yml](./docker-compose.yml) for full configuration options.
> ℹ️ Runtime configuration (images, environment variables, ports, volumes) now lives in
> [`../deploy/config/services/docker-compose.services.yml`](../deploy/config/services/docker-compose.services.yml).
> The root `docker-compose.yml` simply extends those canonical definitions so Docker, Helm, and
> standalone installers stay in sync.

## Optional Service Profiles
### Smoke Test

A helper script exercises the proxy-only, UI, AI, and combined stacks. Run it from the repo root (docker and curl required):

```bash
./reductrai-docker/scripts/smoke-test.sh
```

The script brings up each profile combination, checks service health endpoints, then tears everything down.


By default `docker compose up` will start only the core proxy service. Enable additional components
on demand with Compose profiles:

```bash
# Proxy + dashboard UI
docker compose --profile ui up -d

# Proxy + AI query stack (Ollama + AI API)
docker compose --profile ai up -d

# Full stack (proxy, dashboard, AI)
docker compose --profile ui --profile ai up -d

# Stop/remove everything
docker compose down
```

The `ui` profile activates the dashboard container, while the `ai` profile enables both the Ollama
LLM runtime and the AI query service. Profiles can be combined as needed without editing the compose
file.

## Repository Structure

This repository is the **single source of truth** for all ReductrAI Docker deployments:

```
reductrai-docker/
├── README.md                    # You are here
├── docker-compose.yml           # Multi-service orchestration
├── .env.example                 # Environment variable template
├── install.sh                   # One-line installer
│
├── dockerfiles/                 # All Dockerfiles
│   ├── Dockerfile.proxy         # Proxy service
│   ├── Dockerfile.dashboard     # Dashboard UI
│   ├── Dockerfile.ai-query      # AI Query service
│   └── Dockerfile.all-in-one    # All services in one container
│
├── build-images.sh              # Build all images locally
├── publish-images.sh            # Publish to Docker Hub
│
├── docs/
│   ├── STORAGE.md               # Tiered storage configuration
│   ├── SECURITY.md              # Security hardening guide
│   ├── HIGH-AVAILABILITY.md     # HA deployment strategies
│   └── BUILD.md                 # Build & publish instructions
│
└── examples/                    # Example configurations
    └── (coming soon)
```

## For Maintainers: Publishing Images

Two scripts are available for building and publishing Docker images:

### Build Images Locally
```bash
./build-images.sh          # Build all images (proxy, dashboard, ai-query, all-in-one)
./build-images.sh v1.0.0   # Build with specific version tag
```

This builds images for local testing without publishing to Docker Hub.

Builds:
- `reductrai/proxy:latest` - Proxy service only
- `reductrai/dashboard:latest` - Dashboard UI only
- `reductrai/ai-query:latest` - AI Query service only
- `reductrai/reductrai:latest` - All-in-one image (recommended for getting started)

### Build and Publish to Docker Hub
```bash
# Login first
docker login

# Build and publish
./publish-images.sh          # Publish as 'latest'
./publish-images.sh v1.0.0   # Publish as specific version + latest
```

This script:
- Verifies Docker Hub authentication
- Builds all four images from `dockerfiles/` directory
- Pushes to `reductrai/*` organization on Docker Hub
- Tags both with version and 'latest'

See [BUILD.md](./BUILD.md) for detailed instructions.

## Documentation

- **[Storage Configuration Guide](./STORAGE.md)** - Complete guide to storage backends, tiered storage, and cost optimization
- **[Security Hardening Guide](./SECURITY.md)** - Production security best practices
- **[High Availability Guide](./HIGH-AVAILABILITY.md)** - HA deployment and scaling strategies
- **[Build & Publish Guide](./BUILD.md)** - How to build and publish Docker images
- [Configuration Reference](./.env.example) - All available environment variables
- [Docker Compose Reference](./docker-compose.yml) - Service orchestration

## Support

- Documentation: https://docs.reductrai.com
- Support: support@reductrai.com
- License: https://reductrai.com/pricing
