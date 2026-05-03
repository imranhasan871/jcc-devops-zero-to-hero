# Class 09 — Docker Compose: Multi-Container App

## Objective
Learn how Docker Compose lets you define and run multi-container applications
with a single configuration file, replacing long `docker run` commands with a
declarative YAML specification.

## What You'll Learn
- What Docker Compose is and why it exists
- How to write a `docker-compose.yml` file
- How to use `env_file` to inject environment variables
- How Docker networking works between containers
- Useful `docker compose` CLI commands

## What Changed in This Class
- Added `docker-compose.yml` with an `app` service that builds from our Dockerfile
- Service exposes port 3000 and loads environment variables from `.env`
- Added a named bridge network `jcc-net` for future container communication
- Updated `Makefile` with `docker-up`, `docker-down`, and `docker-logs` targets

## Hands-On Exercise
1. Copy `.env.example` to `.env` and set `NODE_ENV=development`
2. Run `make docker-up` to build and start the container in detached mode
3. Visit `http://localhost:3000/health` — you should see the health response
4. Run `make docker-logs` to tail the application logs
5. Run `make docker-down` to stop and remove the containers

## Key Concepts

**Docker Compose vs `docker run`**
`docker run` is an imperative command — you type flags each time. Docker Compose
is declarative: you describe the desired state in YAML and Compose makes it so.
This means your entire local dev stack lives in version control alongside the code.

**Networks in Docker Compose**
By default Compose creates a network for your project. We define `jcc-net`
explicitly so we can later add more services (like a database) that need to
communicate. Containers on the same network can reach each other by service name
(e.g., `app` can connect to `db` on hostname `db`).

**`env_file` vs `environment`**
Using `env_file: .env` keeps secrets out of `docker-compose.yml`. The `.env`
file is gitignored while `.env.example` is committed. The `environment:` key
in Compose is for non-secret defaults that can be safely committed.

## Next Class Preview
In Class 10 we add a real PostgreSQL database as a second service. We'll learn
about health checks, service dependencies, named volumes for data persistence,
and how to initialize the database schema automatically on first run.
