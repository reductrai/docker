/**
 * Universal Mock Monitoring Service Receiver
 * Captures ALL monitoring formats supported by ReductrAI proxy (20+ services)
 *
 * Supports: Datadog, New Relic, Dynatrace, Splunk, AWS CloudWatch, Azure Monitor,
 * Google Cloud, Prometheus, OTLP, Honeycomb, Elastic APM, Grafana Loki, InfluxDB,
 * StatsD, AppDynamics, Sumo Logic, LogDNA/Mezmo, SignalFx, Lightstep, + Generic APIs
 */

const express = require('express');
const app = express();

app.use(express.json({ limit: '50mb' }));
app.use(express.raw({ limit: '50mb', type: '*/*' }));
app.use(express.text({ limit: '50mb', type: 'text/*' }));

let receivedPayloads = [];

// Helper function to log and track
function logPayload(service, endpoint, data) {
  console.log(`\n✅ ${service.toUpperCase()} ${endpoint}`);
  console.log(`  Timestamp: ${new Date().toISOString()}`);
  console.log(`  Payload size: ${JSON.stringify(data).length} bytes`);

  receivedPayloads.push({
    timestamp: new Date().toISOString(),
    service,
    endpoint,
    size: JSON.stringify(data).length
  });
}

// ============================================================================
// DATADOG
// ============================================================================

app.post('/api/v1/series', (req, res) => {
  const count = req.body.series?.length || 0;
  console.log(`\n✅ DATADOG METRICS`);
  console.log(`  Metrics count: ${count}`);
  console.log(`  Sample: ${req.body.series?.[0]?.metric || 'N/A'}`);

  receivedPayloads.push({
    timestamp: new Date().toISOString(),
    service: 'datadog',
    type: 'metrics',
    count
  });

  res.status(202).json({ status: 'ok' });
});

app.post('/v0.4/traces', (req, res) => {
  logPayload('datadog', 'TRACES', req.body);
  res.status(202).json({ status: 'ok' });
});

app.post('/api/v2/logs', (req, res) => {
  logPayload('datadog', 'LOGS', req.body);
  res.status(202).json({ status: 'ok' });
});

app.post('/api/v1/events', (req, res) => {
  logPayload('datadog', 'EVENTS', req.body);
  res.status(202).json({ status: 'ok' });
});

// ============================================================================
// NEW RELIC
// ============================================================================

app.post('/metric/v1/data', (req, res) => {
  logPayload('new-relic', 'METRICS', req.body);
  res.status(202).json({ requestId: Date.now().toString() });
});

app.post('/v1/accounts/:accountId/events', (req, res) => {
  logPayload('new-relic', 'EVENTS', req.body);
  res.status(200).json({ success: true });
});

app.post('/log/v1', (req, res) => {
  logPayload('new-relic', 'LOGS', req.body);
  res.status(202).json({});
});

app.post('/trace/v1', (req, res) => {
  logPayload('new-relic', 'TRACES', req.body);
  res.status(202).json({});
});

// ============================================================================
// DYNATRACE
// ============================================================================

app.post('/api/v2/metrics/ingest', (req, res) => {
  logPayload('dynatrace', 'METRICS V2', req.body);
  res.status(202).json({ linesOk: 1, linesInvalid: 0 });
});

app.post('/api/v1/entity/infrastructure/custom/*', (req, res) => {
  logPayload('dynatrace', 'CUSTOM DEVICE', req.body);
  res.status(200).json({});
});

app.post('/api/v2/logs/ingest', (req, res) => {
  logPayload('dynatrace', 'LOGS', req.body);
  res.status(204).send();
});

// ============================================================================
// SPLUNK HEC
// ============================================================================

app.post('/services/collector/event', (req, res) => {
  logPayload('splunk', 'EVENTS', req.body);
  res.status(200).json({ text: 'Success', code: 0 });
});

app.post('/services/collector', (req, res) => {
  logPayload('splunk', 'COLLECTOR', req.body);
  res.status(200).json({ text: 'Success', code: 0 });
});

app.post('/services/collector/raw', (req, res) => {
  logPayload('splunk', 'RAW', req.body);
  res.status(200).json({ text: 'Success', code: 0 });
});

// ============================================================================
// AWS CLOUDWATCH
// ============================================================================

app.post('/', (req, res) => {
  const action = req.headers['x-amz-target'];

  if (action?.includes('PutMetricData')) {
    logPayload('cloudwatch', 'METRICS', req.body);
    res.status(200).send('<?xml version="1.0"?><PutMetricDataResponse></PutMetricDataResponse>');
  } else if (action?.includes('PutLogEvents')) {
    logPayload('cloudwatch', 'LOGS', req.body);
    res.status(200).json({ nextSequenceToken: Date.now().toString() });
  } else {
    res.status(200).send('OK');
  }
});

// ============================================================================
// PROMETHEUS
// ============================================================================

app.post('/api/v1/write', (req, res) => {
  console.log(`\n✅ PROMETHEUS REMOTE WRITE`);
  console.log(`  Payload size: ${req.body.length} bytes`);

  receivedPayloads.push({
    timestamp: new Date().toISOString(),
    service: 'prometheus',
    type: 'metrics',
    size: req.body.length
  });

  res.status(204).send();
});

app.post('/api/prom/push', (req, res) => {
  logPayload('prometheus', 'PUSH (Grafana Cloud)', req.body);
  res.status(204).send();
});

// ============================================================================
// OTLP (OpenTelemetry)
// ============================================================================

app.post('/v1/metrics', (req, res) => {
  logPayload('otlp', 'METRICS', req.body);
  res.status(200).json({});
});

app.post('/v1/traces', (req, res) => {
  logPayload('otlp', 'TRACES', req.body);
  res.status(200).json({});
});

app.post('/v1/logs', (req, res) => {
  logPayload('otlp', 'LOGS', req.body);
  res.status(200).json({});
});

// ============================================================================
// HONEYCOMB
// ============================================================================

app.post('/1/events/:dataset', (req, res) => {
  logPayload('honeycomb', `EVENTS (${req.params.dataset})`, req.body);
  res.status(200).json({ status: 'ok' });
});

app.post('/1/batch/:dataset', (req, res) => {
  logPayload('honeycomb', `BATCH (${req.params.dataset})`, req.body);
  res.status(200).json({});
});

// ============================================================================
// ELASTIC APM
// ============================================================================

app.post('/intake/v2/events', (req, res) => {
  logPayload('elastic', 'APM EVENTS', req.body);
  res.status(202).json({ accepted: 1 });
});

app.post('/_bulk', (req, res) => {
  logPayload('elastic', 'BULK', req.body);
  res.status(200).json({ errors: false, items: [] });
});

// ============================================================================
// GRAFANA LOKI
// ============================================================================

app.post('/loki/api/v1/push', (req, res) => {
  logPayload('grafana-loki', 'LOGS', req.body);
  res.status(204).send();
});

app.post('/api/prom/push', (req, res) => {
  logPayload('grafana-loki', 'PROMETHEUS PUSH', req.body);
  res.status(204).send();
});

// ============================================================================
// INFLUXDB
// ============================================================================

app.post('/api/v2/write', (req, res) => {
  logPayload('influxdb', 'WRITE V2', req.body);
  res.status(204).send();
});

app.post('/write', (req, res) => {
  logPayload('influxdb', 'WRITE V1', req.body);
  res.status(204).send();
});

// ============================================================================
// STATSD (UDP not supported, but HTTP can simulate)
// ============================================================================

app.post('/statsd', (req, res) => {
  logPayload('statsd', 'METRICS', req.body);
  res.status(200).send('OK');
});

// ============================================================================
// APPDYNAMICS
// ============================================================================

app.post('/api/analyticsevents/v1/*', (req, res) => {
  logPayload('appdynamics', 'ANALYTICS EVENTS', req.body);
  res.status(200).json({ success: true });
});

// ============================================================================
// AZURE MONITOR / APPLICATION INSIGHTS
// ============================================================================

app.post('/v2.1/track', (req, res) => {
  logPayload('azure-appinsights', 'TELEMETRY V2.1', req.body);
  res.status(200).json({ itemsReceived: 1, itemsAccepted: 1, errors: [] });
});

app.post('/v2/track', (req, res) => {
  logPayload('azure-appinsights', 'TELEMETRY V2', req.body);
  res.status(200).json({ itemsReceived: 1, itemsAccepted: 1, errors: [] });
});

app.post('/api/logs', (req, res) => {
  logPayload('azure-loganalytics', 'LOGS', req.body);
  res.status(200).json({ status: 'ok' });
});

// ============================================================================
// GOOGLE CLOUD MONITORING (STACKDRIVER)
// ============================================================================

app.post('/v3/projects/:projectId/timeSeries', (req, res) => {
  logPayload('gcp-monitoring', `METRICS (${req.params.projectId})`, req.body);
  res.status(200).json({});
});

app.post('/v2/entries:write', (req, res) => {
  logPayload('gcp-logging', 'LOGS', req.body);
  res.status(200).json({});
});

app.post('/v1/projects/:projectId/traces', (req, res) => {
  logPayload('gcp-trace', `TRACES (${req.params.projectId})`, req.body);
  res.status(200).json({});
});

// ============================================================================
// SUMO LOGIC
// ============================================================================

app.post('/receiver/v1/http/*', (req, res) => {
  logPayload('sumologic', 'HTTP SOURCE', req.body);
  res.status(200).json({ status: 'ok' });
});

app.post('/api/v1/collector/*', (req, res) => {
  logPayload('sumologic', 'COLLECTOR', req.body);
  res.status(200).json({ status: 'ok' });
});

// ============================================================================
// LOGDNA / MEZMO
// ============================================================================

app.post('/logs/ingest', (req, res) => {
  logPayload('logdna', 'INGEST', req.body);
  res.status(200).json({ status: 'ok' });
});

app.post('/v1/ingest', (req, res) => {
  logPayload('mezmo', 'INGEST V1', req.body);
  res.status(200).json({ status: 'ok' });
});

// ============================================================================
// SIGNALFX
// ============================================================================

app.post('/v2/datapoint', (req, res) => {
  logPayload('signalfx', 'DATAPOINT', req.body);
  res.status(200).json({ code: 'OK' });
});

app.post('/v2/event', (req, res) => {
  logPayload('signalfx', 'EVENT', req.body);
  res.status(200).json({ code: 'OK' });
});

// ============================================================================
// LIGHTSTEP
// ============================================================================

app.post('/api/v2/reports', (req, res) => {
  logPayload('lightstep', 'REPORTS', req.body);
  res.status(200).json({});
});

app.post('/traces', (req, res) => {
  logPayload('lightstep', 'TRACES', req.body);
  res.status(200).json({});
});

// ============================================================================
// GENERIC / CATCH-ALL
// ============================================================================

app.post('/api/*', (req, res) => {
  logPayload('generic', req.path, req.body);
  res.status(200).json({ status: 'ok' });
});

// ============================================================================
// STATS ENDPOINT
// ============================================================================

app.get('/stats', (req, res) => {
  const byService = receivedPayloads.reduce((acc, p) => {
    const key = `${p.service}${p.type ? '-' + p.type : ''}`;
    acc[key] = (acc[key] || 0) + 1;
    return acc;
  }, {});

  res.json({
    totalReceived: receivedPayloads.length,
    byService,
    recent: receivedPayloads.slice(-20),
    supported: [
      'Datadog (metrics, traces, logs, events)',
      'New Relic (metrics, events, logs, traces)',
      'Dynatrace (metrics v2, custom devices, logs)',
      'Splunk HEC (events, raw, collector)',
      'AWS CloudWatch (metrics, logs)',
      'Azure Monitor (Application Insights, Log Analytics)',
      'Google Cloud Monitoring (metrics, logs, traces)',
      'Prometheus (remote write)',
      'OTLP (metrics, traces, logs)',
      'Honeycomb (events, batch)',
      'Elastic APM (events, bulk)',
      'Grafana Loki (logs)',
      'InfluxDB (v1, v2)',
      'StatsD',
      'AppDynamics (analytics events)',
      'Sumo Logic (HTTP source, collector)',
      'LogDNA/Mezmo (logs ingest)',
      'SignalFx (datapoints, events)',
      'Lightstep (reports, traces)',
      'Generic (catch-all /api/*)'
    ]
  });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    uptime: process.uptime(),
    totalPayloads: receivedPayloads.length
  });
});

// ============================================================================
// START SERVER
// ============================================================================

const PORT = process.env.PORT || 8888;
app.listen(PORT, () => {
  console.log(`
╔═══════════════════════════════════════════════════════════╗
║  Universal Mock Monitoring Receiver                       ║
║  Port: ${PORT}                                                  ║
╚═══════════════════════════════════════════════════════════╝

✅ Supports 20+ monitoring services (matches proxy's universal support):
   • Datadog          • New Relic        • Dynatrace
   • Splunk           • AWS CloudWatch   • Azure Monitor
   • Google Cloud     • Prometheus       • OTLP
   • Honeycomb        • Elastic APM      • Grafana Loki
   • InfluxDB         • StatsD           • AppDynamics
   • Sumo Logic       • LogDNA/Mezmo     • SignalFx
   • Lightstep        • Generic APIs

📊 View captured data:
   curl http://localhost:${PORT}/stats

🔍 Health check:
   curl http://localhost:${PORT}/health

💡 Forward to this mock:
   FORWARD_TO=http://localhost:${PORT}
  `);
});
