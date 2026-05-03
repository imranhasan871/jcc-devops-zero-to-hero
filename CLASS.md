# Class 04 — Environment Configuration

## Objective
Hard-coding values like port numbers and database URLs inside source files is one of the
most common mistakes in early-stage projects. The moment you want to run the same code in
development, staging, and production — with different databases, different ports, different
log levels — you need a disciplined way to inject those values from outside the code. This
class introduces the environment variable pattern, the `.env.example` convention, and a
centralised `config.js` module.

## What You'll Learn
- What environment variables are and why they exist
- The `.env` / `.env.example` convention (what to commit vs. what to keep secret)
- How to centralise all configuration in one module
- How `dotenv` loads a `.env` file into `process.env` at startup
- The 12-Factor App principle #3: "Store config in the environment"

## What Changed in This Class
- Added `.env.example` — documents every variable the app supports; safe to commit
- Added `config.js` — reads `process.env`, applies defaults, exports a plain object
- Updated `server.js` — imports `config` instead of reading `process.env.PORT` directly
- Updated `package.json` — added `dotenv` as a dependency
- `.env` is listed in `.gitignore` — it is never committed

## Hands-On Exercise
1. Copy the example file: `cp .env.example .env`
2. Edit `.env`, change `PORT=3000` to `PORT=4000`.
3. Update `server.js` to load dotenv at the very top:
   ```js
   require('dotenv').config();
   const config = require('./config');
   ```
4. Run `npm install && npm start`. Confirm the server starts on port 4000.
5. Now start the server without the `.env` file: `mv .env .env.bak && npm start`.
   The server falls back to the default port 3000. Restore with `mv .env.bak .env`.
6. Set a variable inline without `.env`: `PORT=5000 npm start`. This overrides `.env`.
   (Environment variables set in the shell take precedence over `.env` file values.)
7. Hit `/health` and confirm `"env": "development"` appears in the response.

## Key Concepts

**Environment variables**: Key-value pairs injected into a process by the operating system
or the shell. In Node.js they are accessible via `process.env.VARIABLE_NAME`. They are the
standard mechanism for passing secrets and environment-specific settings without touching
source code. This is how Docker, Kubernetes, CI/CD pipelines, and cloud platforms
(Heroku, Railway, AWS ECS) all pass configuration to running containers.

**`.env.example` vs `.env`**: `.env.example` is a template that lives in the repository —
it documents every variable the app expects, with safe placeholder values. The actual `.env`
file contains real values (possibly secrets) and is listed in `.gitignore` so it is never
committed. Every developer copies `.env.example` to `.env` and fills in their local values.
This pattern prevents secrets from leaking into git history while ensuring no variable is
ever undiscovered.

**Centralised `config.js`**: Instead of calling `process.env.X` scattered throughout the
codebase, a single module reads all variables and exports a plain object. This means type
coercion (e.g., `parseInt`) and default values are applied in one place, and you can see
all configuration at a glance without grepping the entire codebase.

## Next Class Preview
We add npm scripts for common developer tasks and a `Makefile` so the project can be
operated with short, memorable commands regardless of the underlying tool.
