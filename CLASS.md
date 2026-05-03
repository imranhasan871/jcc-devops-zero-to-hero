# Class 10 — Docker Compose with PostgreSQL + Health Checks

## Objective
Replace the in-memory data store with a real PostgreSQL database running as a
second Docker Compose service. Understand how containers communicate, how health
checks prevent race conditions, and how to persist data across restarts.

## What You'll Learn
- How to add a database service to `docker-compose.yml`
- What Docker health checks are and why they matter
- How `depends_on` with `condition: service_healthy` works
- How named volumes persist data beyond container restarts
- How to auto-initialize a database with a SQL script
- How to use the `pg` Node.js client with a connection pool

## What Changed in This Class
- Updated `docker-compose.yml` with a `db` service using `postgres:16-alpine`
- Added healthcheck on `db` using `pg_isready`
- `app` now waits for `db` to be healthy before starting (`depends_on` condition)
- Added `database/init.sql` — runs automatically on first PostgreSQL container start
- Updated `server.js` to use `pg.Pool` for all data operations
- Added `pg` to `package.json` dependencies

## Hands-On Exercise
1. Run `make docker-down` to remove any existing containers
2. Copy `.env.example` to `.env`, set `POSTGRES_PASSWORD=mysecret`
3. Run `make docker-up` — watch the logs: `app` waits until `db` passes health checks
4. Visit `http://localhost:3000/health` — confirm `"db": "connected"`
5. Visit `http://localhost:3000/api/programs` — see seeded data from `init.sql`
6. POST to `/api/applicants` with `{"name":"Alice","email":"alice@test.com","program_id":1}`
7. Run `make docker-down && make docker-up` — confirm Alice is still there (volume persistence)

## Key Concepts

**Health Checks vs `depends_on` (simple)**
Without a health check condition, `depends_on` only waits for the container
process to *start* — not for PostgreSQL to be *ready to accept connections*.
The `pg_isready` command verifies the database is actually accepting queries.
Without this, your app often crashes on startup because it connects before
Postgres finishes initializing.

**Named Volumes**
`db_data:/var/lib/postgresql/data` maps a Docker-managed volume to the
directory where Postgres stores its files. Unlike bind mounts, named volumes
survive `docker compose down` (but are removed by `docker compose down -v`).
This is the correct way to persist database data in local development.

**Connection Pools**
`pg.Pool` maintains a pool of reusable TCP connections to PostgreSQL. Creating
a new connection is expensive (TLS handshake, auth). A pool of 10 connections
can serve hundreds of concurrent requests without the overhead of reconnecting
for each query.

## Next Class Preview
In Class 11 we introduce GitHub Actions. We'll create our first CI workflow
that automatically runs linting and tests on every push and pull request —
so broken code can never silently land in the repository.
