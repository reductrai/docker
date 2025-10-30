/**
 * Mock Monitoring Service Receiver
 * Captures and validates payloads from ReductrAI proxy
 */

const express = require('express');
const app = express();

app.use(express.json({ limit: '50mb' }));
app.use(express.raw({ limit: '50mb', type: '*/*' }));

let receivedPayloads = [];

// Datadog metrics endpoint
app.post('/api/v1/series', (req, res) => {
  console.log('\n✅ DATADOG METRICS RECEIVED');
  console.log(`  Payload size: ${JSON.stringify(req.body).length} bytes`);
  console.log(`  Metrics count: ${req.body.series?.length || 0}`);
  console.log(`  Sample metric: ${req.body.series?.[0]?.metric || 'N/A'}`);

  receivedPayloads.push({
    timestamp: new Date().toISOString(),
    type: 'datadog-metrics',
    count: req.body.series?.length || 0
  });

  res.status(202).json({ status: 'ok' });
});

// Datadog traces endpoint
app.post('/v0.4/traces', (req, res) => {
  console.log('\n✅ DATADOG TRACES RECEIVED');
  console.log(`  Traces count: ${Array.isArray(req.body) ? req.body.length : 0}`);

  receivedPayloads.push({
    timestamp: new Date().toISOString(),
    type: 'datadog-traces',
    count: Array.isArray(req.body) ? req.body.length : 0
  });

  res.status(202).json({ status: 'ok' });
});

// Datadog logs endpoint
app.post('/api/v2/logs', (req, res) => {
  console.log('\n✅ DATADOG LOGS RECEIVED');
  console.log(`  Logs count: ${Array.isArray(req.body) ? req.body.length : 0}`);

  receivedPayloads.push({
    timestamp: new Date().toISOString(),
    type: 'datadog-logs',
    count: Array.isArray(req.body) ? req.body.length : 0
  });

  res.status(202).json({ status: 'ok' });
});

// Prometheus remote write
app.post('/api/v1/write', (req, res) => {
  console.log('\n✅ PROMETHEUS METRICS RECEIVED');
  console.log(`  Payload size: ${req.body.length} bytes`);

  receivedPayloads.push({
    timestamp: new Date().toISOString(),
    type: 'prometheus',
    size: req.body.length
  });

  res.status(204).send();
});

// Stats endpoint
app.get('/stats', (req, res) => {
  res.json({
    totalReceived: receivedPayloads.length,
    byType: receivedPayloads.reduce((acc, p) => {
      acc[p.type] = (acc[p.type] || 0) + 1;
      return acc;
    }, {}),
    recent: receivedPayloads.slice(-10)
  });
});

const PORT = 8888;
app.listen(PORT, () => {
  console.log(`
╔═══════════════════════════════════════════════════╗
║  Mock Monitoring Receiver Running on :${PORT}      ║
║  Captures ALL forwarded monitoring data           ║
╚═══════════════════════════════════════════════════╝

Test with:
  curl http://localhost:8888/stats

Forward to this mock:
  FORWARD_TO=http://localhost:8888
  `);
});
