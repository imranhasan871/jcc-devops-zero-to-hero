# Class 09 — Docker Compose: Multi-Container Stack

## The Scenario
The JCC app now runs in Docker. The PostgreSQL database still runs directly on
the developer's laptop at port 5432. When the intern cloned the repo yesterday,
she spent two hours debugging before realising the `.env` file had the wrong
database host, the port was already in use by a local Postgres instance, and
the app crashed on startup because it connected to the database before it was
ready. The team lead has declared: every developer must go from `git clone` to
a fully running stack with exactly two commands. No exceptions.

## The Problem
There is no `docker-compose.yml`. The app container and the database are not
co-ordinated. The startup order is undefined — the app frequently starts before
the database is ready and crashes with `ECONNREFUSED`. Environment variables
are scattered across a local `.env` that is not templated for new developers.
There is no single command to start or stop the entire stack.

## Your Mission
- `docker compose up` (after `git clone`) must start both the app and the
  database with no other setup steps required.
- The app service must NOT start until the database is confirmed healthy —
  not just running, but ready to accept connections.
- `docker compose ps` after startup must show the database service with
  status `healthy` and the app service as `running`.
- `curl localhost:3000/health` must succeed after `docker compose up -d`.
- Every value that differs between environments (database host, port,
  password, database name) must be an environment variable in the Compose
  file, not a hard-coded string.
- An `.env.example` must exist at the repo root documenting every variable
  the stack needs.

## What You Need to Know First
- **Docker Compose**: A tool for defining and running multi-container
  applications. A single YAML file declares all services, their
  configuration, and how they relate to each other.
- **`depends_on` with `condition: service_healthy`**: Delays a service's
  startup until another service passes its health check. Simple `depends_on`
  (without a condition) only waits for the container to start — not for the
  process inside it to be ready.
- **Health check**: A command Docker runs inside a container on a schedule.
  A container is `healthy` when the command exits 0, `unhealthy` when it
  exits non-zero.
- **`pg_isready`**: A PostgreSQL utility that exits 0 when the database is
  accepting connections. The canonical health check command for a Postgres
  container.
- **Service networking**: Containers in the same Compose project can reach
  each other by service name as a hostname. The app container connects to
  `db:5432`, not `localhost:5432`.
- **Named volume**: A Docker-managed storage volume that persists beyond
  container restarts. Unlike a bind mount, it is not tied to a path on the
  host machine.

## Constraints
- You may NOT use `depends_on` with only a service name. You must use
  `condition: service_healthy`.
- The database health check must use `pg_isready`. No other health check
  command is acceptable.
- Hard-coded passwords must not appear in `docker-compose.yml`. They must
  come from environment variables.
- Must work on both macOS and Linux without modification.

## Verification
```bash
# Start from a clean state
docker compose down -v

# Bring the stack up
docker compose up -d

# Confirm startup order — db must be healthy before app is running
docker compose ps
# Expected: db shows "healthy", app shows "running"

# Confirm the app is reachable
curl localhost:3000/health
# Expected: {"status":"ok"} or similar

# Confirm app startup logged correctly
docker compose logs app | grep -i "running\|listen\|start"

# Tear down
docker compose down
```

## Stretch Challenge
The current setup loses all database data when you run `docker compose down -v`.
Confirm this is true, then investigate: what is the difference between
`docker compose down` and `docker compose down -v`? Configure the Compose file
so that data persists across a plain `docker compose down` but is wiped by
`docker compose down -v`. Then simulate a database crash mid-operation:
`docker compose stop db`. Hit the app with `curl localhost:3000/api/programs`.
Document exactly what the app returns. Is that the correct behaviour? What
should a production app return when its database is unreachable, and where in
the code would you handle it?

## Instructor Notes
The `condition: service_healthy` requirement is critical and non-negotiable.
Race conditions between app and database startup are among the most common
sources of "works locally, broken in CI" failures. Students who use simple
`depends_on` will occasionally see it work by accident — because their machine
is fast enough — and will not understand why it breaks in CI. The two-command
onboarding requirement (`git clone` + `docker compose up`) is a real
engineering standard at many companies. The stretch challenge about the
database crash introduces graceful degradation, which is a topic unto itself
but worth planting here. Students often discover that their app returns a 500
with a stack trace — which leaks internal details to the client and is always
the wrong answer in production.
