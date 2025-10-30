# Mock Monitoring Receiver

A lightweight Express.js server that captures forwarded monitoring data from ReductrAI proxy for testing and verification purposes.

## Why Use This?

When your Datadog/New Relic/Prometheus trial expires, you can't see their dashboards - but you can still verify forwarding works by capturing the data yourself.

## Two Versions Available

### 1. Universal Mock Receiver (Recommended)

**Supports ALL major monitoring services** - mirrors the proxy's 95% universal support:

```bash
npm run mock-receiver-universal
```

**Supported services:**
- **Datadog** (metrics, traces, logs, events)
- **New Relic** (metrics, events, logs, traces)
- **Dynatrace** (metrics v2, custom devices, logs)
- **Splunk HEC** (events, raw, collector)
- **AWS CloudWatch** (metrics, logs)
- **Prometheus** (remote write, Grafana Cloud)
- **OTLP** (metrics, traces, logs)
- **Honeycomb** (events, batch)
- **Elastic APM** (events, bulk)
- **Grafana Loki** (logs)
- **InfluxDB** (v1, v2)
- **StatsD**
- **AppDynamics** (analytics events)
- **Generic catch-all** (`/api/*`)

### 2. Basic Mock Receiver

Simple version with Datadog and Prometheus support only:

```bash
npm run mock-receiver
```

## Quick Start

```bash
# Install dependencies (first time only)
npm install

# Start universal mock receiver (recommended)
npm run mock-receiver-universal
```

The server starts on **port 8888** and captures all forwarded monitoring data.

## Configure ReductrAI Proxy

Point your proxy to the mock receiver:

```bash
# In .env file
FORWARD_TO=http://localhost:8888
```

Or with Docker:
```bash
docker run -e FORWARD_TO=http://host.docker.internal:8888 reductrai/proxy
```

## What It Captures

The universal mock receiver captures data from all major monitoring services:

### Datadog
```bash
POST /api/v1/series   # Metrics
POST /v0.4/traces     # Traces
POST /api/v2/logs     # Logs
POST /api/v1/events   # Events
```

Example output:
```
✅ DATADOG METRICS
  Metrics count: 3
  Sample: api.request.duration
```

### New Relic
```bash
POST /metric/v1/data                  # Metrics
POST /v1/accounts/:accountId/events   # Events
POST /log/v1                          # Logs
POST /trace/v1                        # Traces
```

Example output:
```
✅ NEW-RELIC METRICS
  Timestamp: 2025-10-30T21:07:26.438Z
  Payload size: 77 bytes
```

### Dynatrace
```bash
POST /api/v2/metrics/ingest                       # Metrics
POST /api/v1/entity/infrastructure/custom/*       # Custom devices
POST /api/v2/logs/ingest                          # Logs
```

Example output:
```
✅ DYNATRACE METRICS V2
  Timestamp: 2025-10-30T21:07:26.438Z
  Payload size: 145 bytes
```

### Splunk HEC
```bash
POST /services/collector/event   # Events
POST /services/collector         # General
POST /services/collector/raw     # Raw data
```

Example output:
```
✅ SPLUNK EVENTS
  Timestamp: 2025-10-30T21:27:06.059Z
  Payload size: 42 bytes
```

### OTLP (OpenTelemetry)
```bash
POST /v1/metrics   # Metrics
POST /v1/traces    # Traces
POST /v1/logs      # Logs
```

Example output:
```
✅ OTLP METRICS
  Timestamp: 2025-10-30T21:27:40.619Z
  Payload size: 116 bytes
```

### Prometheus
```bash
POST /api/v1/write       # Remote write
POST /api/prom/push      # Grafana Cloud
```

Example output:
```
✅ PROMETHEUS REMOTE WRITE
  Payload size: 2048 bytes
```

### Other Services

The universal receiver also supports:
- **CloudWatch** (metrics, logs via `x-amz-target` header)
- **Honeycomb** (events `/1/events/:dataset`, batch `/1/batch/:dataset`)
- **Elastic APM** (events `/intake/v2/events`, bulk `/_bulk`)
- **Grafana Loki** (logs `/loki/api/v1/push`)
- **InfluxDB** (v1 `/write`, v2 `/api/v2/write`)
- **StatsD** (`/statsd`)
- **AppDynamics** (analytics events `/api/analyticsevents/v1/*`)
- **Generic APIs** (catch-all `/api/*`)

## View Statistics

```bash
# Get aggregated stats
curl http://localhost:8888/stats | jq
```

Response:
```json
{
  "totalReceived": 47,
  "byService": {
    "datadog-metrics": 25,
    "new-relic": 8,
    "splunk": 6,
    "otlp": 4,
    "prometheus": 2,
    "dynatrace": 2
  },
  "recent": [
    {
      "timestamp": "2025-10-30T21:07:09.762Z",
      "service": "datadog",
      "type": "metrics",
      "count": 1
    },
    {
      "timestamp": "2025-10-30T21:07:26.438Z",
      "service": "new-relic",
      "endpoint": "METRICS",
      "size": 77
    },
    {
      "timestamp": "2025-10-30T21:27:06.059Z",
      "service": "splunk",
      "endpoint": "EVENTS",
      "size": 42
    },
    {
      "timestamp": "2025-10-30T21:27:40.619Z",
      "service": "otlp",
      "endpoint": "METRICS",
      "size": 116
    }
  ],
  "supported": [
    "Datadog (metrics, traces, logs, events)",
    "New Relic (metrics, events, logs, traces)",
    "Dynatrace (metrics v2, custom devices, logs)",
    "Splunk HEC (events, raw, collector)",
    "AWS CloudWatch (metrics, logs)",
    "Prometheus (remote write)",
    "OTLP (metrics, traces, logs)",
    "Honeycomb (events, batch)",
    "Elastic APM (events, bulk)",
    "Grafana Loki (logs)",
    "InfluxDB (v1, v2)",
    "StatsD",
    "AppDynamics (analytics events)",
    "Generic (catch-all /api/*)"
  ]
}
```

## Testing Scenarios

### Test 1: Verify Datadog Forwarding

```bash
# Start mock receiver
npm run mock-receiver

# Send test metric
curl -X POST http://localhost:8888/api/v1/series \
  -H "Content-Type: application/json" \
  -H "DD-API-KEY: test" \
  -d '{
    "series": [{
      "metric": "test.metric",
      "points": [['"$(date +%s)"', 100]],
      "tags": ["env:test"]
    }]
  }'

# Check stats
curl http://localhost:8888/stats
```

### Test 2: Verify Proxy Forwarding

```bash
# Configure proxy to forward to mock
export FORWARD_TO=http://localhost:8888

# Send data to proxy
curl -X POST http://localhost:8080/api/v1/series \
  -H "Content-Type: application/json" \
  -d '{"series":[{"metric":"proxy.test","points":[['"$(date +%s)"',50]]}]}'

# Mock receiver shows captured data
```

### Test 3: Load Testing

```bash
# Send 100 metrics
for i in {1..100}; do
  curl -s -X POST http://localhost:8888/api/v1/series \
    -H "Content-Type: application/json" \
    -d '{"series":[{"metric":"load.test","points":[['"$(date +%s)"','"$i"']]}]}'
done

# Check stats
curl http://localhost:8888/stats
# Should show totalReceived: 100
```

## Implementation Details

- **Port**: 8888 (configurable via `PORT` env var)
- **Storage**: In-memory array (resets on restart)
- **Payload Limit**: 50MB (handles large batches)
- **Response Codes**:
  - 202 (Accepted) for Datadog endpoints
  - 204 (No Content) for Prometheus

## Use Cases

1. **Trial Expired**: Verify forwarding without dashboard access
2. **Debugging**: See exact payloads being sent
3. **Testing**: Validate integration before production
4. **Development**: Local testing without external dependencies
5. **Compliance**: Audit what data is being forwarded

## Comparison vs Real Services

| Feature | Mock Receiver | Datadog/New Relic |
|---------|--------------|-------------------|
| **Cost** | Free | $15-$36/host/month |
| **Dashboard** | No (shows raw data) | Yes |
| **Verification** | ✅ Instant | ❌ Requires subscription |
| **Debugging** | ✅ Full payload visibility | ❌ Limited |
| **Offline** | ✅ Works offline | ❌ Requires internet |

## Limitations

- No data persistence (in-memory only)
- No visualization (use Grafana for that)
- No querying (use `/stats` endpoint for aggregates)
- Single instance (no clustering)

For production monitoring, use the real services. For testing/verification, this is perfect.

## See Also

- `TESTING.md` - Complete verification guide
- `docker-compose.self-hosted.yml` - Free local monitoring stack (Prometheus + Grafana)
- `prometheus.yml` - Prometheus configuration
