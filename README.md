# ReductrAI Docker Distribution

Official Docker images and deployment configurations for ReductrAI - AI SRE Proxy that provides full observability at 10% of the cost.

## Installation

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

### Option 3: Single Container (Proxy Only)

```bash
# Create configuration
cat > .env << 'EOF'
REDUCTRAI_LICENSE_KEY=RF-DEMO-2025
DATADOG_API_KEY=your_datadog_key_here
EOF

# Run proxy (image auto-pulls from Docker Hub)
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

## For Maintainers: Publishing Images

Two scripts are available for building and publishing Docker images:

### Build Images Locally
```bash
./build-images.sh          # Build all images (proxy, dashboard, ai-query)
./build-images.sh v1.0.0   # Build with specific version tag
```

This builds images for local testing without publishing to Docker Hub.

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
- Builds all three images
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