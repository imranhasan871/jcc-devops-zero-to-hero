# Class 12 — Tests That Actually Catch Bugs

## The Scenario
CI is green. The pipeline runs on every push. And yet a bug slipped through two
weeks ago that corrupted 47 applicant records. Investigation reveals the test
suite has 12% coverage. `GET /api/programs` is tested. `POST /api/applicants`
— the endpoint that writes data — has zero tests. A developer changed the
required field validation and nobody noticed because there was nothing to notice.
The coverage number was never tracked. Today that changes.

## The Problem
The test suite does not cover the most critical paths in `server.js`. Coverage
is at 12%. There is no coverage threshold enforced — the CI pipeline accepts any
coverage number, including zero. Bugs in request validation and error handling
are invisible to automated checks.

## Your Mission
1. Write a Jest + Supertest test suite covering every API endpoint with both a
   happy-path case and at least one error case per endpoint.
2. Coverage must reach 80%+ on statements and 70%+ on branches for `server.js`.
3. The CI pipeline must fail — exit code 1 — if coverage drops below these
   thresholds. The threshold must be enforced in the Jest config, not in a
   custom script.
4. The full test suite must complete in under 10 seconds.
5. The database layer must be mocked — tests must never connect to a real
   PostgreSQL instance.

## What You Need to Know First
- Supertest: how to wrap an Express app without calling `app.listen()`
- Jest `--coverage` flag and the `coverageThreshold` config option in
  `package.json` or `jest.config.js`
- The difference between a unit test mock and an integration test
- How to mock a module with `jest.mock()` so tests don't need a live database
- HTTP status codes: 200, 201, 400, 404, 409 — when each is appropriate

## Constraints
- Tests must not connect to PostgreSQL. Use `jest.mock()` or an in-memory
  substitute. The mock must enforce the unique-email constraint realistically —
  posting the same email twice must return `409`, not `201`.
- Coverage thresholds must be in the Jest configuration, not a shell `if`
  statement. The `npm test` command must exit 1 automatically when coverage
  is below threshold.
- Do not install any new test frameworks. Use Jest and Supertest only.
- Each test file must be independent — tests must not share state between
  describe blocks.

## Verification
```bash
# Full suite must pass with coverage above threshold
npm test
# Expected output lines:
#   Statements : 80%+
#   Branches   : 70%+
#   Tests      : 8 passed, 8 total
#   exit code  : 0

# Deliberately break coverage — delete one test block, run again
# Expected: exit code 1 with "Jest: 'statements' coverage threshold ... not met"

# Required test cases (you write these — not given to you):
# GET  /health                        → 200
# GET  /api/programs                  → 200, array with ≥3 items
# GET  /api/applicants                → 200, array
# POST /api/applicants  valid body    → 201, returns created applicant
# POST /api/applicants  missing name  → 400, specific error message
# POST /api/applicants  missing email → 400, specific error message
# POST /api/applicants  duplicate email → 409
# GET  /nonexistent                   → 404
```

## Stretch Challenge
Use your test suite to find a real bug: change `POST /api/applicants` validation
to accidentally accept an empty-string name (`name: ""`). Your tests should
catch this regression. Fix both the validation logic and update the test that
exposes it. Document what the root cause was and why the test caught it when
code review did not.

## Instructor Notes
The threshold in Jest config is the critical detail. Many developers run
`--coverage` and look at the report but never enforce the number. Without
`coverageThreshold`, 12% coverage still produces a green CI run. The pipeline
must fail automatically — that is what makes the threshold real.

The database mock must be realistic. A mock that always returns success for
duplicate emails teaches students that the constraint doesn't matter. The mock
must replicate at minimum: find-by-email before insert, throw on duplicate.

Wrong approach to avoid: mocking at the HTTP layer (intercepting `fetch` or
`axios`). The correct mock target is the database module that `server.js`
imports. The test sends a real HTTP request to the Express app; only the
database call is mocked. This tests actual request parsing, validation logic,
and response formatting — everything except the database wire.
