# Class 02 — Node.js + Express Server

## Objective
We replace `localStorage` with a real HTTP server. Data now lives in one place — the server's
memory — and any browser that can reach `http://localhost:3000` sees the same applicant list.
This is the foundational shift from a local toy to something that can eventually be deployed,
shared, and scaled.

## What You'll Learn
- How to bootstrap a Node.js project with `package.json`
- How Express handles routing, middleware, and JSON responses
- The purpose of a `/health` endpoint and why it matters for operations
- How the browser's `fetch` API replaces `localStorage` for data persistence
- Why in-memory storage is still not enough (and what comes next)

## What Changed in This Class
- Added `package.json` — project manifest, declares `express` as a dependency
- Added `server.js` — Express app with `/api/programs`, `/api/applicants` (GET + POST), `/health`
- Updated `index.html` — removed all `localStorage` logic; now calls the API with `fetch()`

## Hands-On Exercise
1. Install dependencies: `npm install` (this creates `node_modules/`).
2. Start the server: `npm start`.
3. Open `http://localhost:3000` in your browser. The app looks identical to class-01.
4. Submit an application. Open a **second browser window** — the applicant appears there too.
5. Test the API directly in your terminal:
   ```
   curl http://localhost:3000/health
   curl http://localhost:3000/api/programs
   curl -X POST http://localhost:3000/api/applicants \
        -H "Content-Type: application/json" \
        -d '{"name":"Test User","email":"t@t.com","programId":1}'
   curl http://localhost:3000/api/applicants
   ```
6. Kill the server (`Ctrl+C`) and restart it. Notice: **all applicants are gone**.
7. This is the next problem we need to solve (persistence → database, later classes).

## Key Concepts

**Express middleware**: Functions that run before your route handlers. `express.json()` parses
incoming request bodies with `Content-Type: application/json` so `req.body` is populated.
`express.static()` serves files from a directory, turning our Express app into both an API
server and a static file host.

**HTTP status codes**: We return `201 Created` on successful POST (not just `200 OK`) and
`400 Bad Request` with an error message when validation fails. Using correct status codes
makes your API predictable for clients and monitoring tools alike.

**Health endpoint**: `/health` returns server uptime and a timestamp. This single endpoint
will later be used by Docker, Kubernetes, and load balancers to decide whether the server
is ready to receive traffic. Building it in now costs nothing and pays dividends every
class from here on.

## Next Class Preview
We reorganize the project layout, add a `.gitignore` to stop tracking `node_modules`, and
write a `README.md` — the foundations of good Git hygiene.
