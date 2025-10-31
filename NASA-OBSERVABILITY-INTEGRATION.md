# NASA Observability Integration Guide

Complete guide for integrating NASA telemetry data with ALL monitoring backends and querying with AI.

## Overview

The NASA telemetry generator produces realistic spacecraft observability data representing missions like:
- **International Space Station (ISS)** - 10,000 metrics/sec
- **Mars 2020 Perseverance Rover** - 5,000 metrics/sec
- **James Webb Space Telescope (JWST)** - 8,000 metrics/sec
- **Voyager 1** - 160 metrics/sec

### Data Types Generated

The generator produces **COMPLETE observability data**:

#### 1. Metrics (70% of data)
- **Power systems**: Solar array voltage, battery levels, consumption
- **Thermal**: Component temperatures, cooling system status
- **Life support** (ISS): Cabin pressure, O2/CO2 levels, humidity
- **Navigation**: Position, velocity, attitude control
- **Communication**: Signal strength, data rates, latency
- **Instruments**: RTG power, sensor readings, camera status

#### 2. Distributed Traces (8% of data)
- **Operations**: Docking sequences, EVA activities, sample collection
- **Experiments**: Microgravity tests, spectroscopy, image capture
- **System activities**: Calibration, data downlink, orbit adjustments
- **Error traces**: 2% failure rate with detailed error context
- **Duration metrics**: Operation timing (1-6 second typical operations)

#### 3. Logs (20% of data)
- **INFO logs**: Nominal operations, health checks, telemetry updates
- **WARNING logs**: Temperature thresholds, power fluctuations, anomalies
- **ERROR logs**: Sensor malfunctions, shutdowns, threshold breaches, failures
- **Structured attributes**: Mission, spacecraft, subsystem, environment

#### 4. Events (2% of data)
- **Milestones**: Mission achievements, discoveries, records
- **Alerts**: Anomaly detection, dust storms, temperature spikes
- **Operations**: Docking, EVA start/stop, data downlinks
- **Priority levels**: Low, normal, high with appropriate alerting

## Architecture: Data Flow

```
┌─────────────────────┐
│  NASA Telemetry     │
│  Generator          │  Generates 4 data types
│  (Port: N/A)        │  Metrics, Traces, Logs, Events
└──────────┬──────────┘
           │
           │ HTTP POST (Datadog format)
           │ /api/v1/series (metrics)
           │ /v0.4/traces (traces)
           │ /api/v2/logs (logs)
           │ /api/v1/events (events)
           ▼
┌─────────────────────┐
│  ReductrAI Proxy    │  Universal monitoring proxy
│  (Port: 8080)       │  ├─ Detects format (Datadog, Prometheus, etc.)
└──────────┬──────────┘  ├─ Compresses 100% of data (89% ratio)
           │              ├─ Stores locally for AI queries
           │              └─ Forwards 10% sample to backend
           │
           ├──────────────────┬───────────────────┬──────────────┐
           │                  │                   │              │
           ▼                  ▼                   ▼              ▼
  ┌───────────────┐  ┌───────────────┐  ┌──────────────┐  ┌─────────┐
  │   Datadog     │  │  Prometheus   │  │  New Relic   │  │  OTLP   │
  │               │  │  + Grafana    │  │              │  │ Jaeger  │
  └───────────────┘  └───────────────┘  └──────────────┘  └─────────┘

  └──────────────────── OR 20+ other backends ────────────────────────┘
      Azure, GCP, AWS CloudWatch, Splunk, Dynatrace, Honeycomb,
      Elastic, InfluxDB, SignalFx, Lightstep, and more...

           │
           │ Compressed data available for queries
           ▼
┌─────────────────────┐
│  AI Query Service   │  Natural language analysis
│  (Port: 8081)       │  "Show me ISS errors in the last hour"
└─────────────────────┘  "What caused the thermal spike on JWST?"
                         "Compare Perseverance and ISS latency"
```

## Quick Start: End-to-End Test

### 1. Start Mock Receiver (Captures ALL formats)

```bash
cd reductrai-docker
npm run mock-receiver-universal
```

The mock receiver supports 20+ monitoring services and captures forwarded data.

### 2. Start ReductrAI Proxy (Routes to any backend)

```bash
cd reductrai-proxy

# Option A: Forward to mock receiver (testing)
REDUCTRAI_LICENSE_KEY=RF-DEMO-2025 \
FORWARD_TO=http://localhost:8888 \
PORT=8080 \
npm run proxy

# Option B: Forward to Datadog (production)
REDUCTRAI_LICENSE_KEY=RF-DEMO-2025 \
DATADOG_API_KEY=your_key \
FORWARD_TO=https://api.datadoghq.com \
PORT=8080 \
npm run proxy

# Option C: Forward to Prometheus (open source)
REDUCTRAI_LICENSE_KEY=RF-DEMO-2025 \
FORWARD_TO=http://prometheus:9090 \
PORT=8080 \
npm run proxy
```

### 3. Start NASA Telemetry Generator

```bash
cd reductrai-validation
./start-nasa-continuous.sh
```

**What happens:**
- Generates 16,800+ data points per second
- Sends to proxy on port 8080
- Proxy compresses 100% locally (89% ratio)
- Forwards 10% sample to configured backend
- All data queryable via AI service

### 4. Verify Data Flow

```bash
# Check mock receiver captured data
curl http://localhost:8888/stats | jq

# Check proxy metrics
curl http://localhost:8080/metrics

# Check proxy health
curl http://localhost:8080/health
```

## Configuration: All Monitoring Backends

The proxy auto-detects formats. Just point `FORWARD_TO` to your backend.

### Cloud Platforms

#### Datadog
```bash
FORWARD_TO=https://api.datadoghq.com
DATADOG_API_KEY=your_api_key
DATADOG_SITE=datadoghq.com  # or datadoghq.eu
```

NASA data appears in Datadog as:
- **Metrics**: Dashboard → nasa.iss.*, nasa.perseverance.*, nasa.jwst.*, nasa.voyager1.*
- **Traces**: APM → Services: nasa-iss, nasa-perseverance, nasa-jwst, nasa-voyager1
- **Logs**: Logs Explorer → source:life_support, source:power, source:thermal, etc.
- **Events**: Events → mission:ISS, mission:Perseverance, etc.

#### New Relic
```bash
FORWARD_TO=https://metric-api.newrelic.com
NEW_RELIC_API_KEY=your_license_key
NEW_RELIC_ACCOUNT_ID=your_account_id
```

NASA data in New Relic:
- **Metrics**: Query → `SELECT * FROM Metric WHERE mission = 'ISS'`
- **Traces**: Distributed Tracing → Filter by service.name = 'nasa-iss'
- **Logs**: Logs → `mission:ISS AND level:ERROR`

#### AWS CloudWatch
```bash
FORWARD_TO=https://monitoring.amazonaws.com
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
AWS_REGION=us-east-1
```

#### Azure Monitor
```bash
FORWARD_TO=https://dc.services.visualstudio.com
AZURE_INSTRUMENTATION_KEY=your_key

# Or Log Analytics
FORWARD_TO=https://your-workspace.ods.opinsights.azure.com
AZURE_WORKSPACE_ID=your_workspace_id
AZURE_WORKSPACE_KEY=your_key
```

#### Google Cloud Monitoring
```bash
FORWARD_TO=https://monitoring.googleapis.com
GCP_PROJECT_ID=your_project
GOOGLE_APPLICATION_CREDENTIALS=/path/to/credentials.json
```

### APM Vendors

#### Dynatrace
```bash
FORWARD_TO=https://your-env.live.dynatrace.com
DYNATRACE_API_TOKEN=your_token
```

#### Splunk
```bash
FORWARD_TO=https://your-instance.splunkcloud.com:8088
SPLUNK_HEC_TOKEN=your_token
```

#### AppDynamics
```bash
FORWARD_TO=https://your-account.saas.appdynamics.com
APPDYNAMICS_API_KEY=your_key
APPDYNAMICS_ACCOUNT_NAME=your_account
```

### Open Source

#### Prometheus + Grafana
```bash
FORWARD_TO=http://prometheus:9090
```

Then query in Grafana:
```promql
# ISS power metrics
nasa_iss_power_solar_array_voltage

# Error rate across all missions
rate(nasa_traces_error_total[5m])

# Mars rover temperature
nasa_perseverance_thermal_rtg_temperature
```

#### OTLP (OpenTelemetry)
```bash
FORWARD_TO=http://otel-collector:4318
OTLP_PROTOCOL=http  # or grpc on :4317
```

Works with: Jaeger, Zipkin, Honeycomb, Lightstep, any OTLP backend

#### Grafana Loki (Logs)
```bash
FORWARD_TO=http://loki:3100
```

#### InfluxDB
```bash
# v2
FORWARD_TO=http://influxdb:8086
INFLUXDB_TOKEN=your_token
INFLUXDB_ORG=your_org
INFLUXDB_BUCKET=nasa_telemetry

# v1
FORWARD_TO=http://influxdb:8086
INFLUXDB_DATABASE=nasa_telemetry
```

#### Elastic Stack (ELK)
```bash
FORWARD_TO=http://elasticsearch:9200
ELASTIC_APM_SERVER_URL=http://apm-server:8200
ELASTIC_API_KEY=your_key
```

### Observability Platforms

#### Honeycomb
```bash
FORWARD_TO=https://api.honeycomb.io
HONEYCOMB_API_KEY=your_key
HONEYCOMB_DATASET=nasa-telemetry
```

#### SignalFx
```bash
FORWARD_TO=https://ingest.signalfx.com
SIGNALFX_ACCESS_TOKEN=your_token
```

#### Lightstep
```bash
FORWARD_TO=https://ingest.lightstep.com
LIGHTSTEP_ACCESS_TOKEN=your_token
```

#### Sumo Logic
```bash
FORWARD_TO=https://collectors.sumologic.com
SUMO_LOGIC_HTTP_SOURCE_URL=your_url
```

## AI Query Integration

### Start AI Query Service

```bash
# With Docker Compose
cd reductrai-docker
docker-compose up -d ai-query ollama

# Or standalone
cd reductrai-ai-query
npm run dev
```

### Query NASA Data with Natural Language

The AI Query service can analyze compressed NASA data using natural language:

```bash
# Example 1: Error analysis
curl -X POST http://localhost:8081/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Show me all ISS errors in the last hour with their root cause"
  }'

# Example 2: Performance comparison
curl -X POST http://localhost:8081/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Compare average latency between Perseverance and ISS operations"
  }'

# Example 3: Anomaly detection
curl -X POST http://localhost:8081/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What caused the JWST thermal spike at 14:23 UTC?"
  }'

# Example 4: Trend analysis
curl -X POST http://localhost:8081/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Show power consumption trends for Voyager 1 over the last 24 hours"
  }'

# Example 5: Correlation
curl -X POST http://localhost:8081/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Correlate ISS life support warnings with cabin pressure metrics"
  }'
```

### AI Query Web UI

Open http://localhost:8081 in your browser for interactive queries:
- Natural language input
- AI-generated visualizations
- Drill-down into compressed data
- Export results as JSON/CSV

### AI Query Capabilities

**What AI can do with NASA data:**
1. **Root cause analysis**: "Why did the RTG temperature spike?"
2. **Anomaly detection**: "Find unusual patterns in ISS telemetry"
3. **Correlation**: "Link thermal warnings to power fluctuations"
4. **Trend analysis**: "Show solar panel efficiency over 7 days"
5. **Comparison**: "Compare error rates across all missions"
6. **Prediction**: "Predict next maintenance window for Perseverance"
7. **Summarization**: "Summarize critical events from last week"

## Enhanced NASA Data: Adding More Realism

The generator already includes comprehensive data, but you can enhance it further:

### Current Data Coverage

**Already includes:**
- ✅ Error logs (2% error rate in traces)
- ✅ Latency metrics (operation duration 1-6 seconds)
- ✅ Warning logs (temperature, power fluctuations)
- ✅ Critical events (high priority alerts)
- ✅ Multi-level logging (INFO, WARNING, ERROR)
- ✅ Distributed tracing with parent-child spans
- ✅ Performance metrics (CPU, memory per operation)

### Adding More Data Types

Edit `/Users/jessiehermosillo/Apiflow/reductrai-validation/nasa-telemetry-generator.js` to add:

#### 1. Network Latency Metrics
```javascript
// Add to generateISSMetrics() or other mission methods
metrics.network_latency_ms = 250 + Math.random() * 100;
metrics.packet_loss_percent = Math.random() * 2;
metrics.bandwidth_mbps = 300 - Math.random() * 50;
```

#### 2. Database Query Metrics
```javascript
// Add to generateTrace()
metrics: {
  ...existing metrics,
  db_query_time_ms: 10 + Math.random() * 90,
  cache_hit_rate: 0.85 + Math.random() * 0.15,
  connection_pool_size: 10 + Math.floor(Math.random() * 20)
}
```

#### 3. Error Rate Metrics
```javascript
// In sendBatch(), add error rate calculation
const errorRate = this.tracesCount > 0 ?
  (errors / this.tracesCount * 100).toFixed(2) : 0;

// Send as separate metric
{
  metric: 'nasa.error_rate',
  points: [[timestamp, errorRate]],
  tags: [`mission:${mission}`]
}
```

#### 4. Custom Business Metrics
```javascript
// Add mission-specific KPIs
metrics.samples_collected_total = Math.floor(Math.random() * 50); // Perseverance
metrics.experiments_completed = Math.floor(Math.random() * 20);    // ISS
metrics.images_captured = Math.floor(Math.random() * 100);         // JWST
```

## Production Deployment

### Docker Compose (Recommended)

Create `docker-compose.nasa.yml`:

```yaml
version: '3.8'

services:
  # ReductrAI Proxy
  reductrai-proxy:
    image: reductrai/proxy:latest
    ports:
      - "8080:8080"
    environment:
      - REDUCTRAI_LICENSE_KEY=${LICENSE_KEY}
      - FORWARD_TO=${MONITORING_BACKEND}  # Configure your backend
      - DATADOG_API_KEY=${DATADOG_API_KEY}  # If using Datadog
    volumes:
      - ./data:/app/data  # Compressed data storage

  # AI Query Service
  reductrai-ai-query:
    image: reductrai/ai-query:latest
    ports:
      - "8081:8081"
    environment:
      - OLLAMA_HOST=http://ollama:11434
    depends_on:
      - ollama

  # Ollama LLM
  reductrai-ollama:
    image: reductrai/ollama:latest
    ports:
      - "11434:11434"
    volumes:
      - ./ollama:/root/.ollama

  # NASA Telemetry Generator
  nasa-telemetry:
    build:
      context: ../reductrai-validation
      dockerfile: Dockerfile.nasa
    environment:
      - PROXY_URL=http://reductrai-proxy:8080
      - DURATION=3600  # 1 hour continuous
      - BATCH_SIZE=500
      - INTERVAL_MS=100
    depends_on:
      - reductrai-proxy
```

Start:
```bash
LICENSE_KEY=your_key \
MONITORING_BACKEND=https://api.datadoghq.com \
DATADOG_API_KEY=your_key \
docker-compose -f docker-compose.nasa.yml up -d
```

### Kubernetes (Production Scale)

Use the Helm chart with NASA-specific values:

```bash
cd reductrai-helm

helm install reductrai ./charts/reductrai \
  --set licenseKey=YOUR_LICENSE_KEY \
  --set backends.datadog.enabled=true \
  --set backends.datadog.apiKey=YOUR_DATADOG_API_KEY \
  --set proxy.replicas=3 \
  --set proxy.autoscaling.enabled=true \
  --set proxy.autoscaling.maxReplicas=10
```

## Verification & Testing

### 1. Verify Proxy is Receiving Data

```bash
# Check metrics endpoint
curl http://localhost:8080/metrics | grep nasa

# Should show:
# reductrai_metrics_received_total{format="datadog"} 1500000
# reductrai_compression_ratio 0.89
# reductrai_forward_success_total 150000  # 10% of total
```

### 2. Verify Backend is Receiving Data

```bash
# Check mock receiver
curl http://localhost:8888/stats | jq '.byService'

# Should show:
# {
#   "datadog-metrics": 105000,
#   "datadog-traces": 12000,
#   "datadog-logs": 30000,
#   "datadog-events": 3000
# }
```

### 3. Query with AI

```bash
# Test AI query
curl -X POST http://localhost:8081/query \
  -H "Content-Type: application/json" \
  -d '{"query": "How many errors occurred in the last 5 minutes?"}'

# Should return analysis with:
# - Total error count
# - Breakdown by mission
# - Top error types
# - Time series visualization
```

### 4. Verify Compression

```bash
# Check compression logs (if enabled)
ls -lh reductrai-proxy/data/

# Should show:
# Original: ~10GB
# Compressed: ~1.1GB (89% compression)
```

## Cost Savings Calculator

### Without ReductrAI (Traditional Monitoring)

**Datadog pricing example:**
- 1.5M data points/minute × 60 minutes × 24 hours = 2.16B points/day
- At $0.10 per 100 custom metrics = **$216,000/day**
- Monthly: **$6,480,000**

### With ReductrAI (Intelligent Sampling)

**ReductrAI pricing:**
- 10% forwarded to Datadog = 216M points/day
- At $0.10 per 100 custom metrics = **$21,600/day**
- Monthly: **$648,000**
- **Savings: $5,832,000/month (90%)**

**AND you get:**
- ✅ 100% of data stored locally (compressed)
- ✅ AI-powered queries on complete dataset
- ✅ Better observability than traditional approach
- ✅ No data loss from sampling
- ✅ Instant query without backend costs

## Troubleshooting

### Issue: No data appearing in backend

**Check:**
1. Proxy logs: `docker logs reductrai-proxy`
2. Network connectivity: `curl http://localhost:8080/health`
3. Backend API key: Verify `DATADOG_API_KEY` or equivalent
4. Proxy forwarding: Check `FORWARD_TO` environment variable

### Issue: AI queries return no results

**Check:**
1. AI Query service running: `curl http://localhost:8081/health`
2. Ollama running: `curl http://localhost:11434/api/tags`
3. Data ingestion: Proxy must store compressed data locally
4. Enable storage: Set `STORAGE_ENABLED=true` in proxy config

### Issue: Mock receiver not capturing data

**Check:**
1. Port 8888 available: `lsof -i :8888`
2. Proxy configured correctly: `FORWARD_TO=http://localhost:8888`
3. Mock receiver logs: Check console output for captured payloads

## Next Steps

1. **Production deployment**: Use Docker Compose or Kubernetes
2. **Backend integration**: Configure your monitoring service
3. **Dashboard creation**: Import NASA dashboards (see reductrai-datadog-perf-testing/)
4. **AI training**: Fine-tune queries for your specific use cases
5. **Alerting**: Set up alerts based on NASA metrics and events

## See Also

- `README-MOCK-RECEIVER.md` - Mock receiver documentation
- `TESTING.md` - Complete verification guide
- `../reductrai-validation/NASA-TELEMETRY-TESTING.md` - NASA test details
- `../reductrai-datadog-perf-testing/CASE-STUDY-NASA-TELEMETRY.md` - Performance case study
- `docker-compose.self-hosted.yml` - Free local monitoring stack
