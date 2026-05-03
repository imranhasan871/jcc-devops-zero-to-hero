# Class 10 — Database Initialisation & Schema Management

## The Scenario
The app now uses PostgreSQL instead of in-memory storage. The first time a new
developer runs `docker compose up`, the app crashes immediately: `relation
"applicants" does not exist`. The database container starts and is healthy, but
it has no schema. Developers have been manually running SQL against the
container to set it up. One developer ran `DROP TABLE applicants` by mistake.
Another has a schema that does not match production. There is no single source
of truth. The team lead has had enough: the schema must apply itself, zero
manual steps, from a cold start.

## The Problem
There is no automated schema initialisation. The database starts empty every
time. Four API endpoints (`/health`, `/api/programs`, `/api/applicants` GET,
`/api/applicants` POST) are all broken after a fresh `docker compose up`
because the tables do not exist. The schema lives in developers' heads and in
ad-hoc SQL files that have diverged from one another. There are no constraints
on the data — duplicate emails, null names, and invalid stage values have all
appeared in the database.

## Your Mission
- A cold `docker compose up` (after `docker compose down -v`) must result in
  a fully working stack with no manual steps.
- `curl localhost:3000/api/programs` must return seed data within 10 seconds
  of the stack coming up.
- `POST /api/applicants` with valid JSON must return `201 Created` with the
  created record.
- The `applicants` table must enforce: `name` NOT NULL, `email` UNIQUE,
  `stage` constrained to a fixed set of valid values.
- Posting a duplicate email must return `409 Conflict`, not `500
  Internal Server Error`.
- The schema must live in `database/init.sql` and must be the only place
  the schema is defined.

## What You Need to Know First
- **PostgreSQL init directory**: The official `postgres` Docker image
  automatically executes `.sql` and `.sh` files found in
  `/docker-entrypoint-initdb.d/` the first time the database starts on a
  fresh volume. Files run in alphabetical order.
- **Bind mount in Compose**: A volume entry of the form
  `./database/init.sql:/docker-entrypoint-initdb.d/init.sql` maps a host
  file into the container at that path without copying it into the image.
- **SQL constraints**: `NOT NULL` rejects rows with a missing column value.
  `UNIQUE` rejects duplicate values. `CHECK` rejects rows that fail a
  boolean expression — useful for enforcing an enum-like set of values.
- **Idempotent schema**: `CREATE TABLE IF NOT EXISTS` and
  `INSERT ... ON CONFLICT DO NOTHING` allow a script to be re-run safely
  without failing if the objects already exist.
- **PostgreSQL error codes**: When a `UNIQUE` constraint is violated,
  Postgres returns error code `23505`. The `pg` Node.js client exposes this
  as `err.code`. Checking for it lets the server return `409` rather than
  a generic `500`.
- **Volume lifecycle**: `init.sql` only runs on a fresh volume. If you
  change the schema and want it to apply, you must run
  `docker compose down -v` to destroy the volume and let it re-initialise.

## Constraints
- You may NOT use a migration library (no Flyway, no Knex migrate, no
  Sequelize). The schema must be plain SQL in `database/init.sql`.
- The `init.sql` file must be version-controlled. It is the single source
  of truth for the schema.
- The server must catch the unique-constraint error and return `409`, not
  propagate it as a `500`.
- You must document (as a comment at the top of `init.sql`) how to apply
  schema changes without losing existing data. This is the limitation you
  are accepting by not using a migration tool.

## Verification
```bash
# Start from a completely clean state — no volumes
docker compose down -v

# Bring the stack up
docker compose up -d
sleep 5

# Seed data check
curl localhost:3000/api/programs
# Must return a JSON array with at least one program

# Create an applicant
curl -s -o /dev/null -w "%{http_code}" -X POST localhost:3000/api/applicants \
  -H "Content-Type: application/json" \
  -d '{"name":"Jane","email":"jane@jcc.com","program_id":1}'
# Must output: 201

# Read it back
curl localhost:3000/api/applicants
# Must include Jane

# Duplicate email — must return 409
curl -s -o /dev/null -w "%{http_code}" -X POST localhost:3000/api/applicants \
  -H "Content-Type: application/json" \
  -d '{"name":"Jane Again","email":"jane@jcc.com","program_id":1}'
# Must output: 409

# Confirm data is gone after volume wipe (expected behaviour — explain why)
docker compose down -v && docker compose up -d
sleep 5
curl localhost:3000/api/applicants
# Must return empty array — Jane is gone, explain this in your submission
```

## Stretch Challenge
What happens when two API requests arrive at exactly the same moment, both
trying to insert the same email address? Write a script (or use a tool like
`curl` in parallel with `&`) that sends two simultaneous POST requests with
identical email addresses. Document exactly what both responses are right now.
Then verify the server handles it correctly — both concurrent requests should
return deterministic responses: one `201`, one `409`. If they do not, fix the
error handling. Then explain: if the `UNIQUE` constraint did not exist on the
database, would the application-level check alone be sufficient? Why or why not?

## Instructor Notes
The `init.sql` approach is the right starting point because it is simple,
transparent, and requires no additional tooling. Its limitation — that it only
runs on a fresh volume — is a real trade-off worth discussing explicitly. The
instruction to document that limitation as a comment forces students to
confront it rather than glossing over it. The `409` vs `500` distinction is
important: a `500` leaks internal error details to the client and is always
wrong for a constraint violation that the server could have anticipated. The
stretch challenge about concurrent inserts teaches a fundamental database
concept — that application-level uniqueness checks are not race-condition-safe
without a database-level constraint — which cannot be learned any other way
than by writing the test and seeing it fail.
