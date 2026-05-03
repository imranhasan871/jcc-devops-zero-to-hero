'use strict';

const request = require('supertest');

// Mock the pg module before requiring the app
jest.mock('pg', () => {
  const mockPool = {
    query: jest.fn(),
  };
  return { Pool: jest.fn(() => mockPool) };
});

const { Pool } = require('pg');
const mockPool = new Pool();

// Load app after mocking
const app = require('../server');

describe('GET /health', () => {
  it('returns 200 with status ok when db is connected', async () => {
    mockPool.query.mockResolvedValueOnce({ rows: [{ '?column?': 1 }] });
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('ok');
    expect(res.body.db).toBe('connected');
  });

  it('returns 503 when db is unavailable', async () => {
    mockPool.query.mockRejectedValueOnce(new Error('Connection refused'));
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(503);
    expect(res.body.status).toBe('error');
  });
});

describe('GET /api/programs', () => {
  it('returns an array of programs', async () => {
    const programs = [
      { id: 1, name: 'Full-Stack Web Development', duration: '6 months' },
      { id: 2, name: 'DevOps & Cloud Engineering', duration: '4 months' },
    ];
    mockPool.query.mockResolvedValueOnce({ rows: programs });
    const res = await request(app).get('/api/programs');
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body).toHaveLength(2);
    expect(res.body[0].name).toBe('Full-Stack Web Development');
  });
});

describe('POST /api/applicants', () => {
  it('creates an applicant and returns 201', async () => {
    const newApplicant = {
      id: 1,
      name: 'Alice',
      email: 'alice@test.com',
      program_id: 1,
      status: 'pending',
    };
    mockPool.query.mockResolvedValueOnce({ rows: [newApplicant] });
    const res = await request(app)
      .post('/api/applicants')
      .send({ name: 'Alice', email: 'alice@test.com', program_id: 1 });
    expect(res.statusCode).toBe(201);
    expect(res.body.email).toBe('alice@test.com');
  });

  it('returns 400 when name is missing', async () => {
    const res = await request(app)
      .post('/api/applicants')
      .send({ email: 'noname@test.com' });
    expect(res.statusCode).toBe(400);
  });

  it('returns 409 when email is already registered', async () => {
    const err = new Error('duplicate key');
    err.code = '23505';
    mockPool.query.mockRejectedValueOnce(err);
    const res = await request(app)
      .post('/api/applicants')
      .send({ name: 'Bob', email: 'duplicate@test.com' });
    expect(res.statusCode).toBe(409);
  });
});
