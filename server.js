'use strict';

// ---------------------------------------------------------------------------
// OpenTelemetry SDK — must initialise BEFORE any other require() calls.
// class-40: traces every HTTP request and DB query automatically.
// ---------------------------------------------------------------------------
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');
const { Resource } = require('@opentelemetry/resources');
const { SEMRESATTRS_SERVICE_NAME, SEMRESATTRS_SERVICE_VERSION } = require('@opentelemetry/semantic-conventions');
const { trace } = require('@opentelemetry/api');

const sdk = new NodeSDK({
  resource: new Resource({
    [SEMRESATTRS_SERVICE_NAME]: 'jcc-backend',
    [SEMRESATTRS_SERVICE_VERSION]: process.env.APP_VERSION || '1.0.0',
  }),
  traceExporter: new OTLPTraceExporter({
    url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4318/v1/traces',
  }),
  instrumentations: [
    getNodeAutoInstrumentations({
      '@opentelemetry/instrumentation-express': { enabled: true },
      '@opentelemetry/instrumentation-pg':      { enabled: true },
      '@opentelemetry/instrumentation-http':    { enabled: true },
    }),
  ],
});

sdk.start();
process.on('SIGTERM', () => sdk.shutdown());

const express = require('express');
const path = require('path');
const { Pool } = require('pg');
const crypto = require('crypto');
const config = require('./config');

// Structured JSON logger — includes traceId so Loki log lines link to Tempo traces
function log(level, msg, extra = {}) {
  const activeSpan = trace.getActiveSpan();
  const spanContext = activeSpan ? activeSpan.spanContext() : null;
  const traceId = spanContext ? spanContext.traceId : undefined;
  const spanId  = spanContext ? spanContext.spanId  : undefined;
  process.stdout.write(JSON.stringify({
    level,
    msg,
    timestamp: new Date().toISOString(),
    ...(traceId ? { traceId, spanId } : {}),
    ...extra,
  }) + '\n');
}

let requestCount = 0;
const requestsByRoute = {};
function metricsMiddleware(req, res, next) {
  res.on('finish', () => {
    requestCount++;
    const key = `${req.method}_${req.route ? req.route.path : req.path}`;
    requestsByRoute[key] = (requestsByRoute[key] || 0) + 1;
  });
  next();
}

const app = express();
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));
app.use(metricsMiddleware);

app.use((req, res, next) => {
  req.requestId = crypto.randomUUID();
  res.setHeader('X-Request-Id', req.requestId);
  const start = Date.now();
  log('info', 'request received', { requestId: req.requestId, method: req.method, path: req.path });
  res.on('finish', () => {
    log('info', 'request completed', {
      requestId: req.requestId,
      method: req.method,
      path: req.path,
      status: res.statusCode,
      duration: Date.now() - start,
    });
  });
  next();
});

app.get('/metrics', (req, res) => {
  const uptime = process.uptime();
  const heap = process.memoryUsage().heapUsed;
  let body = `# HELP jcc_requests_total Total HTTP requests received\n`;
  body += `# TYPE jcc_requests_total counter\njcc_requests_total ${requestCount}\n\n`;
  body += `# HELP jcc_uptime_seconds Server uptime in seconds\n`;
  body += `# TYPE jcc_uptime_seconds gauge\njcc_uptime_seconds ${uptime.toFixed(2)}\n\n`;
  body += `# HELP jcc_heap_bytes Node.js heap memory used\n`;
  body += `# TYPE jcc_heap_bytes gauge\njcc_heap_bytes ${heap}\n\n`;
  Object.entries(requestsByRoute).forEach(([route, count]) => {
    body += `jcc_requests_by_route{route="${route}"} ${count}\n`;
  });
  res.set('Content-Type', 'text/plain; version=0.0.4').send(body);
});

const pool = new Pool({
  host:     process.env.DB_HOST     || 'localhost',
  port:     parseInt(process.env.DB_PORT || '5432', 10),
  database: process.env.DB_NAME     || 'jcc',
  user:     process.env.DB_USER     || 'jcc_user',
  password: process.env.DB_PASSWORD || 'secret',
});

app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    log('info', 'health check ok', { requestId: req.requestId });
    res.json({ status: 'ok', db: 'connected', timestamp: new Date().toISOString() });
  } catch (err) {
    log('error', 'health check failed', { requestId: req.requestId, error: err.message });
    res.status(503).json({ status: 'error', db: 'disconnected', error: err.message });
  }
});

app.get('/api/programs', async (req, res) => {
  try {
    const { rows } = await pool.query('SELECT * FROM programs ORDER BY id');
    log('info', 'programs fetched', { requestId: req.requestId, count: rows.length });
    res.json(rows);
  } catch (err) {
    log('error', 'programs fetch failed', { requestId: req.requestId, error: err.message });
    res.status(500).json({ error: err.message });
  }
});

// GET /api/applicants — the slow endpoint. Trace waterfall shows exactly where time goes.
app.get('/api/applicants', async (req, res) => {
  log('info', 'applicants query starting', { requestId: req.requestId });
  try {
    const { rows } = await pool.query(
      'SELECT a.*, p.name AS program_name FROM applicants a LEFT JOIN programs p ON a.program_id = p.id ORDER BY a.id'
    );
    log('info', 'applicants fetched', { requestId: req.requestId, count: rows.length });
    res.json(rows);
  } catch (err) {
    log('error', 'applicants fetch failed', { requestId: req.requestId, error: err.message });
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/applicants', async (req, res) => {
  const { name, email, program_id } = req.body;
  if (!name || !email) {
    log('warn', 'applicant create rejected', { requestId: req.requestId });
    return res.status(400).json({ error: 'name and email are required' });
  }
  try {
    const { rows } = await pool.query(
      'INSERT INTO applicants (name, email, program_id) VALUES ($1, $2, $3) RETURNING *',
      [name, email, program_id || null]
    );
    log('info', 'applicant created', { requestId: req.requestId, id: rows[0].id });
    res.status(201).json(rows[0]);
  } catch (err) {
    if (err.code === '23505') {
      log('warn', 'applicant create conflict', { requestId: req.requestId });
      return res.status(409).json({ error: 'Email already registered' });
    }
    log('error', 'applicant create failed', { requestId: req.requestId, error: err.message });
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/events', async (req, res) => {
  try {
    const { rows } = await pool.query('SELECT * FROM events ORDER BY event_date');
    log('info', 'events fetched', { requestId: req.requestId, count: rows.length });
    res.json(rows);
  } catch (err) {
    log('error', 'events fetch failed', { requestId: req.requestId, error: err.message });
    res.status(500).json({ error: err.message });
  }
});

const PORT = config.port || 3000;
app.listen(PORT, () => {
  log('info', 'JCC server started', { port: PORT });
});

module.exports = app;
