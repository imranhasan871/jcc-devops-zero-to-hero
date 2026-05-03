-- JCC Platform Database Schema
-- This file is run automatically by PostgreSQL on first container start.

CREATE TABLE IF NOT EXISTS programs (
  id        SERIAL PRIMARY KEY,
  name      VARCHAR(120) NOT NULL,
  duration  VARCHAR(60),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS applicants (
  id         SERIAL PRIMARY KEY,
  name       VARCHAR(120) NOT NULL,
  email      VARCHAR(200) UNIQUE NOT NULL,
  program_id INTEGER REFERENCES programs(id),
  status     VARCHAR(30) DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS events (
  id          SERIAL PRIMARY KEY,
  title       VARCHAR(200) NOT NULL,
  description TEXT,
  event_date  DATE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Seed data
INSERT INTO programs (name, duration) VALUES
  ('Full-Stack Web Development', '6 months'),
  ('DevOps & Cloud Engineering', '4 months'),
  ('Data Science Fundamentals', '5 months')
ON CONFLICT DO NOTHING;

INSERT INTO events (title, description, event_date) VALUES
  ('Open House', 'Tour the campus and meet instructors', '2026-06-15'),
  ('Hackathon', '24-hour team coding challenge', '2026-07-20')
ON CONFLICT DO NOTHING;
