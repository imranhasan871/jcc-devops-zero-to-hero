'use strict';

const express = require('express');
const path = require('path');
const { Pool } = require('pg');
const config = require('./config');

// --- Prometheus metrics (simple text format, no extra library needed) ---
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

// Prometheus text-format metrics endpoint
app.get('/metrics', (req, res) => {
  const uptime = process.uptime();
  const heap = process.memoryUsage().heapUsed;
  let body = `# HELP jcc_requests_total Total HTTP requests received\n`;
  body += `# TYPE jcc_requests_total counter\n`;
  body += `jcc_requests_total ${requestCount}\n\n`;
  body += `# HELP jcc_uptime_seconds Server uptime in seconds\n`;
  body += `# TYPE jcc_uptime_seconds gauge\n`;
  body += `jcc_uptime_seconds ${uptime.toFixed(2)}\n\n`;
  body += `# HELP jcc_heap_bytes Node.js heap memory used\n`;
  body += `# TYPE jcc_heap_bytes gauge\n`;
  body += `jcc_heap_bytes ${heap}\n\n`;
  Object.entries(requestsByRoute).forEach(([route, count]) => {
    body += `jcc_requests_by_route{route="${route}"} ${count}\n`;
  });
  res.set('Content-Type', 'text/plain; version=0.0.4').send(body);
});

// PostgreSQL connection pool
const pool = new Pool({
  host:     process.env.DB_HOST     || 'localhost',
  port:     parseInt(process.env.DB_PORT || '5432', 10),
  database: process.env.DB_NAME     || 'jcc',
  user:     process.env.DB_USER     || 'jcc_user',
  password: process.env.DB_PASSWORD || 'secret',
});

// Health check
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok', db: 'connected', timestamp: new Date().toISOString() });
  } catch (err) {
    res.status(503).json({ status: 'error', db: 'disconnected', error: err.message });
  }
});

// Programs
app.get('/api/programs', async (req, res) => {
  try {
    const { rows } = await pool.query('SELECT * FROM programs ORDER BY id');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Applicants
app.get('/api/applicants', async (req, res) => {
  try {
    const { rows } = await pool.query(
      'SELECT a.*, p.name AS program_name FROM applicants a LEFT JOIN programs p ON a.program_id = p.id ORDER BY a.id'
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/applicants', async (req, res) => {
  const { name, email, program_id } = req.body;
  if (!name || !email) {
    return res.status(400).json({ error: 'name and email are required' });
  }
  try {
    const { rows } = await pool.query(
      'INSERT INTO applicants (name, email, program_id) VALUES ($1, $2, $3) RETURNING *',
      [name, email, program_id || null]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ error: 'Email already registered' });
    }
    res.status(500).json({ error: err.message });
  }
});

// Events
app.get('/api/events', async (req, res) => {
  try {
    const { rows } = await pool.query('SELECT * FROM events ORDER BY event_date');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const PORT = config.port || 3000;
app.listen(PORT, () => {
  console.log(`JCC server running on port ${PORT}`);
});

module.exports = app;
