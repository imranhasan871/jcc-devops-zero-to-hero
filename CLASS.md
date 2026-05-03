# Class 11 — GitHub Actions: First CI Workflow

## Objective
Set up Continuous Integration (CI) so that every push to the repository
automatically runs the linter and test suite. Broken code is caught before it
ever reaches a teammate's machine.

## What You'll Learn
- What Continuous Integration is and why it matters
- How GitHub Actions workflows are structured
- What triggers (`on:`) control when a workflow runs
- How jobs, steps, and actions compose a pipeline
- The difference between `npm install` and `npm ci`

## What Changed in This Class
- Added `.github/workflows/ci.yml` with a `lint-and-test` job
- Workflow triggers on every push to any branch and on PRs targeting `main`
- Job runs on `ubuntu-latest` with Node.js 20
- Steps: checkout → install → lint → test

## Hands-On Exercise
1. Push this branch to GitHub: `git push -u origin class-11`
2. Navigate to your repo on GitHub → **Actions** tab
3. Watch the `CI` workflow run in real time
4. Intentionally break a lint rule in `server.js`, push again, and see it fail
5. Fix the lint error, push once more — confirm the workflow goes green
6. Open a pull request from `class-11` into `main` and observe CI runs on the PR

## Key Concepts

**What is Continuous Integration?**
CI is the practice of merging code changes into a shared branch frequently and
verifying each merge automatically. The goal is to detect integration problems
early, when they are cheap to fix. Without CI, bugs accumulate silently until
a manual deploy — at which point untangling multiple changes is painful.

**Workflow File Anatomy**
A GitHub Actions workflow is a YAML file inside `.github/workflows/`. The top-
level keys are:
- `name` — displayed in the GitHub UI
- `on` — the events that trigger the workflow (push, pull_request, schedule, etc.)
- `jobs` — one or more independent (or dependent) units of work, each running
  on a fresh virtual machine
- `steps` — sequential commands or reusable actions within a job

**`npm ci` vs `npm install`**
`npm ci` (short for "clean install") deletes `node_modules` and installs
*exactly* what is in `package-lock.json`. It fails if the lockfile is out of
sync. This makes CI builds reproducible — you are always testing against the
same dependency versions that were committed, not a potentially different
resolution.

## Next Class Preview
In Class 12 we write real automated tests using Jest and Supertest, and update
the workflow to collect and upload a code-coverage report as a CI artifact.
