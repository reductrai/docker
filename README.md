# ReductrAI Docker Distribution

Official Docker images and deployment configurations for ReductrAI - AI SRE Proxy that provides full observability at 10% of the cost.

## Quick Start

```bash
# 1. Configure environment
cp .env.example .env
# Edit .env with your license key (use RF-DEMO-2025 for trial)

# 2. Start all services
docker-compose up -d --build

# 3. Wait for services to be healthy (30-60 seconds)
docker ps

# 4. Access services
# Dashboard: http://localhost:5173
# Proxy API: http://localhost:8080
# AI Query:  http://localhost:8081
# Health:    http://localhost:8080/health
```

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

## Documentation

- **[Storage Configuration Guide](./STORAGE.md)** - Complete guide to storage backends, tiered storage, and cost optimization
- [Configuration Reference](./.env.example) - All available environment variables
- [Docker Compose Reference](./docker-compose.yml) - Service orchestration

## Support

- Documentation: https://docs.reductrai.com
- Support: support@reductrai.com
- License: https://reductrai.com/pricing