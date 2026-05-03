# Class 02 — The Demo Worked, Now Make It Real

## The Scenario

The board demo went well. The director got her funding. Now two staff members at different
desks need to log in and see the same applicant list at the same time. One of them submits
an application on their machine — the other must see it appear within seconds, not hours.
A single HTML file with `localStorage` cannot do this: every machine has its own isolated
storage. There is also a new requirement from the funder: a written test proving the API
works correctly before each release.

## The Problem

The `index.html` / `localStorage` architecture is a dead end for a multi-user system.
There is no central store, no shared state, and no way to write automated tests against
browser storage. Here is the evidence:

- Staff member A submits applicant "Jordan Lee" on their MacBook.
- Staff member B opens the same `index.html` on their Windows laptop and sees zero
  applicants.
- Neither can prove the application logic is correct without manually clicking through
  every edge case.

You need a server that holds all applicant data in one place and speaks HTTP so any browser
can reach it.

## Your Mission

- Create `server.js` — an Express HTTP server that starts with `node server.js` after
  `npm install`. No additional environment setup required.
- The server must expose these exact four endpoints (details in `README.md`):
  - `GET /health` — returns `{"status":"ok","uptime":<seconds>}`
  - `GET /api/programs` — returns the array of three programmes
  - `GET /api/applicants` — returns all submitted applicants
  - `POST /api/applicants` — accepts `{"name","email","programId"}`, stores the
    applicant in memory, returns the created record with a generated `id`
- `index.html` must be updated to use `fetch()` instead of `localStorage`. All reads and
  writes go to the server. The UI behaviour must be identical to Class 01 from the user's
  perspective.
- The command `npm test` must run a test suite that makes real HTTP requests to the live
  server and asserts the response shape and status codes for all four endpoints. Tests must
  pass with exit code 0.
- ESLint must pass with zero errors across all `.js` files (`npm run lint`).

## What You Need to Know First

- **Express.js** — a minimal Node.js web framework. `express()` creates an app;
  `app.get('/path', handler)` registers a route; `app.listen(port)` starts the server.
- **Middleware** — `express.json()` parses incoming JSON request bodies so `req.body` is
  populated. `express.static('public')` serves files in a directory as static assets.
- **`req` and `res`** — the request and response objects passed to every route handler.
  `req.body` holds parsed JSON; `res.json({...})` sends a JSON response;
  `res.status(201).json({...})` sets the status code before sending.
- **HTTP status codes** — `200 OK` (default), `201 Created` (new resource), `400 Bad
  Request` (invalid input), `404 Not Found`.
- **`fetch()` API** — the browser function for making HTTP requests. Returns a Promise.
  `fetch('/api/applicants')` is a GET; a POST requires `{method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({...})}`.
- **In-memory storage** — a plain JavaScript array declared at module scope persists for
  the lifetime of the Node.js process. It is wiped when the server restarts.

## Constraints

- Write the Express route handlers yourself — do not copy from documentation or tutorials.
  The examiner will ask you to explain every line during review.
- ESLint must pass with zero errors. The `.eslintrc.json` in the repo defines the rules.
  Run `npm run lint` before committing.
- The `POST /api/applicants` endpoint must return `400` with a JSON body containing a
  `"error"` key if `name` or `email` is missing from the request body. There must be a
  separate test asserting this behaviour for each missing field.
- Do not install any packages not listed in the provided `package.json`. You must
  understand every dependency you use.

## Verification

```bash
# Install and start the server in one terminal
npm install
node server.js &
SERVER_PID=$!

# Health check
curl -s http://localhost:3000/health
# must output: {"status":"ok","uptime":<number>}

# Submit an applicant
curl -s -X POST http://localhost:3000/api/applicants \
  -H "Content-Type: application/json" \
  -d '{"name":"Jordan Lee","email":"jordan@example.com","programId":1}'
# must output JSON with an "id" field

# Retrieve all applicants
curl -s http://localhost:3000/api/applicants
# must include Jordan Lee

# Validation: missing name
curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:3000/api/applicants \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","programId":1}'
# must output: 400

# Run the test suite
npm test   # must exit 0 with all tests passing

# Clean up
kill $SERVER_PID
```

## Stretch Challenge

The `POST /api/applicants` endpoint currently accepts any string as `email`. Add server-side
email format validation (without any validation library — write a regex yourself). Return
`400` with `{"error":"invalid email format"}` for malformed emails. Write tests for at least
three invalid email formats and two valid ones.

## Instructor Notes

The shift from `localStorage` to an HTTP server is the single most important conceptual
leap in the course. Students who struggle here are usually confused about the network
boundary: the browser's JavaScript and the server's JavaScript are two completely separate
processes communicating over HTTP.

**Common wrong approaches:**

- Importing server code into the browser or vice versa — there is a hard boundary; the
  browser cannot `require()` Node modules and the server has no `localStorage`.
- Forgetting `express.json()` middleware — `req.body` is `undefined` and the bug is
  confusing because no error is thrown; data just silently disappears.
- Starting the server inside the test file with `app.listen()` but never closing it —
  tests hang indefinitely waiting for the process to exit.

**The ESLint constraint** is deliberate. Students who paste code from Stack Overflow or
documentation often introduce inconsistent style. ESLint failing is a forcing function:
you must read and understand the code you commit, not just hope it works.

**Why in-memory for now?** The database comes later. In-memory keeps the operational
complexity to zero while the API contract is established. The next time data loss hurts
(server restart wipes everything), students are emotionally ready for persistence.
