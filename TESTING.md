# ReductrAI Forwarding Verification Guide

This guide shows you how to verify monitoring data forwarding works **without** requiring paid subscriptions to Datadog, New Relic, etc.

## Why This Matters

When your Datadog/New Relic trial expires, you can't see dashboards - but forwarding still works! This guide provides three ways to verify forwarding without dashboard access.

---

## Method 1: HTTP Status Code Verification (Instant)

**The simplest method** - Check proxy logs for HTTP response codes.

### What to Look For

```bash
# View proxy logs
docker logs reductrai-proxy

# Look for these success indicators:
✅ [Forward] status 202         # Datadog accepted the data
✅ [Forward] status 204         # Prometheus accepted the data
✅ [Forward] status 200         # Generic success

# If you see these, forwarding works!
[Forward] Completed: 1 succeeded, 0 failed
```

### Why This Works

- **HTTP 202 (Accepted)**: Datadog's API acknowledges receipt
- **HTTP 204 (No Content)**: Prometheus confirms write success
- **HTTP 200 (OK)**: Standard success response

If the monitoring service accepts your data (2xx status), **forwarding is working** - even if you can't access their dashboard.

---

## Method 2: Mock Receiver (Complete Visibility)

**See exactly what data is being forwarded** using the mock receiver.

### Step 1: Start Mock Receiver

```bash
cd /Users/jessiehermosillo/Apiflow/reductrai-docker
npm install  # First time only
npm run mock-receiver
```

You should see:
```
╔═══════════════════════════════════════════════════╗
║  Mock Monitoring Receiver Running on :8888      ║
║  Captures ALL forwarded monitoring data           ║
╚═══════════════════════════════════════════════════╝
```

### Step 2: Configure Proxy to Forward to Mock

Edit `.env` file:
```bash
# Change this:
FORWARD_TO=https://api.datadoghq.com

# To this:
FORWARD_TO=http://localhost:8888
```

Restart proxy:
```bash
docker-compose restart proxy
```

### Step 3: Send Test Data

```bash
# Send a test metric
curl -X POST http://localhost:8080/api/v1/series \
  -H "Content-Type: application/json" \
  -H "DD-API-KEY: test" \
  -d '{
    "series": [{
      "metric": "test.endpoint.bytes",
      "points": [['"$(date +%s)"', 1024]],
      "tags": ["env:test"]
    }]
  }'
```

### Step 4: View Captured Data

Watch the mock receiver console - you'll see:
```
✅ DATADOG METRICS RECEIVED
  Payload size: 156 bytes
  Metrics count: 1
  Sample metric: test.endpoint.bytes
```

Check aggregated stats:
```bash
curl http://localhost:8888/stats | jq
```

Output:
```json
{
  "totalReceived": 1,
  "byType": {
    "datadog-metrics": 1
  },
  "recent": [
    {
      "timestamp": "2025-10-30T15:50:55.417Z",
      "type": "datadog-metrics",
      "count": 1
    }
  ]
}
```

---

## Method 3: Free Local Monitoring Stack

**Run your own Prometheus + Grafana + Jaeger** - completely free and local.

### Step 1: Start Free Monitoring Stack

```bash
cd /Users/jessiehermosillo/Apiflow/reductrai-docker
docker-compose -f docker-compose.self-hosted.yml up -d
```

This starts:
- **Prometheus** (metrics) → http://localhost:9090
- **Grafana** (visualization) → http://localhost:3000
- **Jaeger** (traces) → http://localhost:16686

### Step 2: Configure Proxy to Forward to Prometheus

Edit `.env` file:
```bash
# For Prometheus metrics
FORWARD_TO=http://prometheus:9090/api/v1/write

# Or for OTLP traces to Jaeger
FORWARD_TO=http://jaeger:4318/v1/traces
```

Restart:
```bash
docker-compose restart proxy
```

### Step 3: View Data in Grafana

1. Open http://localhost:3000 (admin/admin)
2. Add Prometheus data source: http://prometheus:9090
3. Create dashboard or run queries

### Step 4: Send Test Metrics

```bash
# Send Prometheus metrics
curl -X POST http://localhost:8080/api/v1/write \
  -H "Content-Type: application/x-protobuf" \
  --data-binary @test-metrics.bin
```

---

## Quick Comparison

| Method | Speed | Visibility | Best For |
|--------|-------|------------|----------|
| **HTTP Status** | Instant | Basic (success/fail) | Quick verification |
| **Mock Receiver** | Fast | Complete (see all data) | Debugging, inspection |
| **Local Stack** | Slow (setup) | Full (real monitoring) | Production-like testing |

---

## Common Scenarios

### Scenario 1: "My Datadog trial expired"

**Solution**: Use Method 1 (HTTP Status Codes)
- Check logs for `status 202` = data forwarded successfully
- You don't need dashboard access to verify forwarding

### Scenario 2: "I want to see what data is being sent"

**Solution**: Use Method 2 (Mock Receiver)
- Captures exact payloads
- Shows payload size, metric counts, sample data
- Perfect for debugging

### Scenario 3: "I want to test with real monitoring tools"

**Solution**: Use Method 3 (Local Stack)
- Real Prometheus + Grafana
- Real Jaeger for traces
- 100% free, runs locally

---

## Supported Formats

The mock receiver captures:

- **Datadog Metrics**: `POST /api/v1/series`
- **Datadog Traces**: `POST /v0.4/traces`
- **Datadog Logs**: `POST /api/v2/logs`
- **Prometheus**: `POST /api/v1/write`

All formats return appropriate success codes.

---

## Troubleshooting

### Mock receiver not seeing data?

Check proxy logs:
```bash
docker logs reductrai-proxy | grep Forward
```

Look for:
- ✅ `[Forward] Forwarding to: http://localhost:8888` (correct target)
- ❌ `[Forward] Error: ECONNREFUSED` (mock not running)

### Proxy not forwarding?

Check configuration:
```bash
docker exec reductrai-proxy env | grep FORWARD
```

Should show:
```
FORWARD_TO=http://localhost:8888
SAMPLE_RATE=0.1
PROXY_MODE=sample
```

---

## Verification Checklist

Before claiming "forwarding doesn't work", verify:

- [ ] Proxy is running: `docker ps | grep proxy`
- [ ] FORWARD_TO is configured: `docker exec reductrai-proxy env | grep FORWARD`
- [ ] SAMPLE_RATE > 0: `docker exec reductrai-proxy env | grep SAMPLE_RATE`
- [ ] Logs show forwarding attempts: `docker logs reductrai-proxy | grep Forward`
- [ ] Status codes are 2xx: Look for `status 202` or `status 204`

If all checked, **forwarding works** - the issue is dashboard access, not data transmission.

---

## Summary

You **do not need** paid monitoring subscriptions to verify forwarding works:

1. **HTTP 202/204 status codes** = Data accepted
2. **Mock receiver** = See exact payloads
3. **Local Prometheus/Grafana** = Full monitoring stack

All three methods prove forwarding works without Datadog dashboard access.
