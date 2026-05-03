# Class 04 — Production Crash: Configuration Is Missing

## The Scenario

You pushed the latest code to the shared staging server at 4 PM on a Friday. Deployments
to staging are automated — the server pulls the latest commit and runs `node server.js`.
Two minutes later the on-call alert fires: the server crashed on startup. The error in the
logs reads:

```
TypeError: Cannot read properties of undefined (reading 'port')
    at Object.<anonymous> (/app/server.js:12:35)
```

You pull up `server.js` and find this near the top:

```js
const port    = process.env.PORT;           // undefined on staging
const dbUrl   = "postgres://localhost/jcc"; // wrong: staging uses a different host
const apiKey  = "dev-key-abc123";           // hardcoded: wrong in every environment
```

The local developer who wrote this never had to configure anything — it worked on their
machine. Staging has different values for all three. Production will have yet another set.
The code must be edited to change environments, which means untested code goes to
production every time a config value changes.

## The Problem

Environment-specific values are embedded in source code. The consequences:

1. The staging server crashed immediately with an unhelpful error.
2. To fix it, someone must edit `server.js`, commit, and redeploy — deploying code changes
   just to change a config value.
3. Secrets (API keys, database passwords) live in Git history forever.
4. There is no record of which variables a fresh environment needs to set to run the app.

## Your Mission

- Create `config.js` at the project root. This module must read every environment-specific
  value from `process.env` and export a plain configuration object. No environment-specific
  value may remain in `server.js` — every reference to `process.env.X` moves to `config.js`.
- In `NODE_ENV=development` mode, `config.js` must apply safe defaults for every variable
  so the server starts without any additional setup (`node server.js` must work on a fresh
  clone after `npm install`).
- In `NODE_ENV=production` mode, `config.js` must throw an error and exit the process if
  any required variable is missing. The error message must name the exact missing variable:
  `Missing required environment variable: DB_URL`. No generic "config error" messages.
- Create `.env.example` documenting every environment variable the application reads, with
  placeholder values. This file must be committed to the repository.
- Update `server.js` to `require('./config')` and use the exported object. `server.js`
  must contain zero direct calls to `process.env` after the refactor.
- The `/health` endpoint must include the current `NODE_ENV` value in its response so
  operators can verify which mode is running.

## What You Need to Know First

- **`process.env`** — a Node.js global object containing all environment variables
  inherited from the shell. Values are always strings (or `undefined` if not set).
  Numbers must be parsed: `parseInt(process.env.PORT, 10)`.
- **Default values with `||`** — `process.env.PORT || 3000` evaluates to `3000` when
  `PORT` is not set. Be careful: `|| 0` evaluates to `0` even if you want `undefined`
  falsy to trigger the default.
- **`NODE_ENV`** — a convention (not a Node.js built-in) for indicating the runtime
  environment. Values are typically `development`, `test`, or `production`. Many libraries
  (Express, logging tools) change their behaviour based on this value.
- **Fail-fast principle** — a system that crashes immediately with a clear error when
  misconfigured is easier to operate than one that starts up and silently misbehaves.
  Fail-fast errors are caught at deployment time; silent errors are caught in production
  by users.
- **`process.exit(1)`** — terminates the Node.js process with a non-zero exit code,
  signalling to the OS and to the supervisor process (Docker, systemd, Kubernetes) that
  the process failed.

## Constraints

- `config.js` must implement the production validation logic manually. You may not use any
  configuration library — no `dotenv-safe`, no `convict`, no `joi`, no `zod`. The
  validation must be plain JavaScript.
- After the refactor, running `grep -r "process\.env" server.js` must return no output.
  All `process.env` accesses live in `config.js` only.
- The exact error message format when a required variable is missing in production must be:
  `Missing required environment variable: <VARIABLE_NAME>`. The examiner will test this
  with several different missing variables.

## Verification

```bash
# Production mode with missing variable must crash with clear message
NODE_ENV=production node server.js 2>&1 | head -5
# must print a line containing "Missing required environment variable:"
# must exit non-zero:
NODE_ENV=production node server.js; echo "exit code: $?"
# must output: exit code: 1

# Development mode must start with no extra setup
NODE_ENV=development node server.js &
sleep 1
curl -s http://localhost:3000/health
# must include "env":"development" in the response
kill %1

# server.js must not contain any direct process.env references
grep "process\.env" server.js
# must return: (nothing)

# .env.example must exist and be committed
git show HEAD:.env.example
# must succeed and display the file contents
```

## Stretch Challenge

Extend `config.js` so that when the server starts (in any mode), it prints a configuration
summary to `stdout` — listing every key and value — but redacts any variable whose name
contains `PASSWORD`, `SECRET`, or `KEY`. Redacted values must appear as `****`.
Example output at startup:

```
Config loaded:
  NODE_ENV       = development
  PORT           = 3000
  DB_URL         = postgres://localhost/jcc
  DB_PASSWORD    = ****
  STRIPE_API_KEY = ****
```

## Instructor Notes

The failure mode in this class is extremely common in real teams: configuration worked on
the developer's machine because the values were hardcoded to match their local environment.
The pain of a staging crash on a Friday afternoon is intentional — that urgency makes the
config pattern memorable.

**Fail-fast vs silent misconfiguration:** A server that starts without `DB_URL` set but
then fails on the first database query is much harder to debug than one that refuses to
start at all. Fail-fast gives you one clear error at a known point in time (startup)
instead of mysterious errors at unpredictable points during operation.

**Common wrong approaches:**

- Using `dotenv` and loading it in `server.js` instead of centralising in `config.js` —
  the `.env` file is not available on the server; environment variables are injected by
  the platform (Docker, Kubernetes, CI/CD).
- Checking `if (!process.env.X)` inline throughout the codebase — creates duplicated
  validation logic and makes it impossible to see all required variables in one place.
- Using a config library instead of implementing validation manually — students who use
  `dotenv-safe` never learn what it actually does; when it fails in production they have
  no mental model for debugging it.

**What this sets up for later:** In the Docker and Kubernetes classes, environment variables
are injected via `docker run -e` flags and Kubernetes `Secret` objects. The `config.js`
module written here requires zero changes — only the source of the environment variables
changes, not how the application reads them.
