# Mock Monitoring Receiver

A lightweight Express.js server that captures forwarded monitoring data from ReductrAI proxy for testing and verification purposes.

## Why Use This?

When your Datadog/New Relic/Prometheus trial expires, you can't see their dashboards - but you can still verify forwarding works by capturing the data yourself.

## Quick Start

```bash
# Install dependencies (first time only)
npm install

# Start mock receiver
npm run mock-receiver
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

### Datadog Metrics
```bash
POST /api/v1/series
```

Example output:
```
✅ DATADOG METRICS RECEIVED
  Payload size: 156 bytes
  Metrics count: 3
  Sample metric: api.request.duration
```

### Datadog Traces
```bash
POST /v0.4/traces
```

Example output:
```
✅ DATADOG TRACES RECEIVED
  Traces count: 5
```

### Datadog Logs
```bash
POST /api/v2/logs
```

Example output:
```
✅ DATADOG LOGS RECEIVED
  Logs count: 12
```

### Prometheus Metrics
```bash
POST /api/v1/write
```

Example output:
```
✅ PROMETHEUS METRICS RECEIVED
  Payload size: 2048 bytes
```

## View Statistics

```bash
# Get aggregated stats
curl http://localhost:8888/stats | jq
```

Response:
```json
{
  "totalReceived": 42,
  "byType": {
    "datadog-metrics": 25,
    "datadog-traces": 10,
    "datadog-logs": 5,
    "prometheus": 2
  },
  "recent": [
    {
      "timestamp": "2025-10-30T15:50:55.417Z",
      "type": "datadog-metrics",
      "count": 3
    }
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
