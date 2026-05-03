# Class 12 — Automated Tests + Coverage

## Objective
Write a real test suite for the Express API using Jest and Supertest, measure
how much of the code the tests exercise (coverage), and automatically publish
the coverage report as a CI artifact on every run.

## What You'll Learn
- How to test an Express app without a real database using mocks
- What Jest mocks are and how `jest.mock()` works
- How Supertest makes HTTP requests against your app in-process
- What code coverage means and how to interpret the report
- How GitHub Actions artifacts preserve test output

## What Changed in This Class
- Added `tests/server.test.js` with 5 test cases covering `/health`, `/api/programs`, and `POST /api/applicants`
- Added `jest.config.js` to configure test environment and coverage collection
- Updated `package.json` test script to `jest --coverage`
- Added `jest` and `supertest` as dev dependencies
- Updated `.github/workflows/ci.yml` to upload the `coverage/` folder as an artifact

## Hands-On Exercise
1. Run `npm install` to install the new dev dependencies
2. Run `npm test` locally — all 5 tests should pass
3. Open `coverage/lcov-report/index.html` in a browser to see line-by-line coverage
4. Push to GitHub and open the Actions run — download the `coverage-report` artifact
5. Add a new test for `GET /api/events` following the same pattern
6. Deliberately delete a test assertion and see coverage drop

## Key Concepts

**Mocking with Jest**
Our app uses a real PostgreSQL pool. In tests we do not want a live database —
it would make tests slow, fragile, and hard to run in CI. `jest.mock('pg')`
intercepts `require('pg')` and replaces it with a fake implementation. We then
control what `.query()` returns for each test case using `mockResolvedValueOnce`
and `mockRejectedValueOnce`.

**Supertest**
Supertest wraps your Express `app` object and lets you make HTTP requests
against it programmatically — no need to bind to a port or start a server.
`request(app).get('/health')` fires a real HTTP request through Express's full
middleware stack and returns the response for your assertions.

**Code Coverage**
Coverage measures which lines, branches, and functions were executed during
tests. 100% coverage does not mean zero bugs, but low coverage (below ~70%)
often means large parts of the code have never been tested at all. The HTML
report highlights untested lines in red — a useful guide for what to test next.

## Next Class Preview
In Class 13 we teach CI to build the Docker image. Every push will verify that
the Dockerfile itself is valid and that the production image can be assembled
successfully — catching container build failures before they hit production.
