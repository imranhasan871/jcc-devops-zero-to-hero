'use strict';

const express = require('express');
const path    = require('path');
const config  = require('./config');   // <── uses centralised config

const app = express();

// ── Middleware ────────────────────────────────────────────────────────────────
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// ── In-memory store ───────────────────────────────────────────────────────────
const programs = [
  { id: 1, name: 'Fashion Modeling',     duration: '6 months', seats: 20 },
  { id: 2, name: 'Commercial Acting',    duration: '4 months', seats: 15 },
  { id: 3, name: 'Personal Development', duration: '3 months', seats: 30 },
  { id: 4, name: 'Runway & Posing',      duration: '5 months', seats: 12 },
];

let applicants = [];
let nextId = 1;

// ── Routes ────────────────────────────────────────────────────────────────────
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    env: config.nodeEnv,
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
  });
});

app.get('/api/programs', (req, res) => {
  res.json(programs);
});

app.get('/api/applicants', (req, res) => {
  res.json(applicants);
});

app.post('/api/applicants', (req, res) => {
  const { name, email, programId } = req.body;

  if (!name || !email || !programId) {
    return res.status(400).json({ error: 'name, email, and programId are required' });
  }

  const program = programs.find(p => p.id === Number(programId));
  if (!program) {
    return res.status(400).json({ error: `Program ${programId} not found` });
  }

  const applicant = {
    id: nextId++,
    name: name.trim(),
    email: email.trim().toLowerCase(),
    programId: Number(programId),
    programName: program.name,
    appliedAt: new Date().toISOString(),
  };

  applicants.push(applicant);
  res.status(201).json(applicant);
});

// ── Start ─────────────────────────────────────────────────────────────────────
app.listen(config.port, () => {
  console.log(`JCC server [${config.nodeEnv}] listening on http://localhost:${config.port}`);
});
