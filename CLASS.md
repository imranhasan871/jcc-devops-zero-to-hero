# Class 05 — Four Developers, Four Ways to Run the Same App

## The Scenario

The team has grown to four developers. You open Slack on Monday morning to a thread that
has been running all weekend:

> **Dev A:** "I just run `node server.js`"
> **Dev B:** "I use `npm start`, that's what package.json says"
> **Dev C:** "I run `nodemon server.js --watch src/` so it auto-reloads"
> **Dev D:** "I installed nodemon globally last year so I just type `nodemon`"

A bug is reported on staging. Nobody can reproduce it locally because nobody is running
the same thing. Dev D's machine has nodemon `2.0.6`; Dev C's has `3.1.0`. Dev B's
`npm start` does not watch for file changes so she has been restarting manually and
missing errors in the restart logs. The onboarding doc says "run the app" without
specifying how. Three of the four developers had to ask someone on Slack before they
could start working on their first day.

## The Problem

There is no single source of truth for developer workflows. Every task — install, start,
develop with hot-reload, lint, test, clean — has multiple competing invocations. New
developers either guess or interrupt a senior. When a CI system needs to run lint before
merging a PR, there is no reliable command to call. The team cannot agree on lint rules,
so code review devolves into style arguments rather than logic review.

## Your Mission

- Create a `Makefile` at the project root. It must be the single authoritative interface
  for all developer tasks. Every common workflow must be reachable via `make <target>`.
- The `Makefile` must implement these targets: `install`, `start`, `dev`, `lint`, `test`,
  `clean`, and `help`. Every target must have a one-line comment (`##`) so `make help`
  can display it automatically.
- `make help` must print all available targets and their descriptions without requiring
  any external tool. The output must be readable by a developer who has never seen the
  project before.
- `make dev` must start the server with automatic file-watching and restart. `nodemon`
  must be a project-local `devDependency` — not a global install. `make dev` must work
  identically on any machine immediately after `make install`, with no manual global
  installation step.
- Configure ESLint (`.eslintrc.json`) to enforce: `no-var` (use `const`/`let`), `prefer-const`,
  `no-console` at the `warn` level, and `eqeqeq` (strict equality only). `make lint`
  must exit with code `1` if ESLint finds any violations. It must exit `0` on clean code.
- `npm test` (and therefore `make test`) must exit `0` even though there are no test files
  yet. The test runner must be configured with `--passWithNoTests` or equivalent.

## What You Need to Know First

- **`Makefile` syntax** — a `Makefile` consists of targets, dependencies, and recipes.
  Each recipe line must be indented with a real tab character (not spaces — make will fail
  with a cryptic error). `.PHONY` declares targets that are not files.
- **`make help` pattern** — the common approach is to add `##` comments after each target
  definition, then use `grep` and `awk` in the `help` recipe to extract and format them
  automatically. Example: `grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | awk ...`
- **`npm scripts` and PATH** — the `"scripts"` section of `package.json` adds
  `node_modules/.bin` to `PATH` automatically. This means a locally-installed `nodemon`
  (under `node_modules/.bin/nodemon`) can be referenced by name in an npm script without
  a full path. A `Makefile` target can call `npm run dev` to leverage this behaviour.
- **ESLint configuration** — `.eslintrc.json` accepts a `"rules"` object. Each rule value
  is either `"off"`, `"warn"`, or `"error"` (or `0`, `1`, `2`). Rules set to `"error"`
  cause ESLint to exit non-zero. Rules set to `"warn"` print warnings but exit `0`.
- **`devDependencies`** — packages in `devDependencies` are installed by `npm install` but
  are excluded when `npm install --omit=dev` is run (which is what production Docker builds
  do). Tools like `nodemon` and `eslint` belong here — they are never needed on the server.

## Constraints

- `make dev` must auto-restart on file changes WITHOUT requiring global nodemon. Running
  `make dev` on a machine where nodemon is not globally installed (after `make install`)
  must work. The examiner will test this by unsetting `PATH` entries for global npm bins.
- `make lint` must exit non-zero when there is a lint violation. The examiner will
  introduce a `var` statement into `server.js` and run `make lint` — it must fail.
- All tab characters in the `Makefile` must be real tab characters (`\t`), not sequences
  of spaces. The examiner will run `cat -A Makefile | grep '^\^I'` to verify.
- Do not add a `.npmrc` or modify any global npm configuration. The solution must work
  in a clean npm environment.

## Verification

```bash
# make help must print all targets
make help
# must list: install, start, dev, lint, test, clean (at minimum)

# make install must run npm install
make install
# must exit 0 and create node_modules/

# lint must pass on clean code
make lint
# must exit 0
echo "lint exit code: $?"

# lint must fail when code is dirty
echo "var x = 1" >> server.js
make lint
echo "lint exit code: $?"   # must output: lint exit code: 1
git checkout server.js       # restore

# test must pass with no test files
make test
echo "test exit code: $?"   # must output: test exit code: 0

# Verify Makefile uses real tabs (not spaces)
cat -A Makefile | grep recipe_line_example   # look for ^I (tab) not spaces

# make dev must start without global nodemon
# (run this in a shell where which nodemon returns nothing)
make dev &
sleep 2
curl -s http://localhost:3000/health | grep '"status":"ok"'
kill %1
```

## Stretch Challenge

Add a `make check` target that runs all three of the following in sequence and exits `0`
only if all three pass:

1. `make lint` — ESLint must find zero violations.
2. `make test` — all tests must pass.
3. A grep check that asserts `server.js` contains no `console.log` statements (use
   `grep -n "console\.log" server.js` — if it returns any output, `make check` must fail).

`make check` is what the CI pipeline will call on every pull request. If any step fails,
the build fails.

## Instructor Notes

The Makefile is the contract between the developer and the project. It answers the
question every new team member asks on day one: "How do I run this thing?" Having a
`make help` that lists every operation means that question can be answered by the project
itself.

**Why Makefile and not `package.json` scripts?** npm scripts work perfectly for Node.js
projects. The Makefile layer adds value when:
- Other engineers (Go, Python, infrastructure) need to operate the project without knowing
  npm's conventions.
- CI/CD systems can call `make test` regardless of the underlying language.
- Teams add non-Node tooling (Docker, Terraform, database migrations) that does not
  belong in `package.json`.

**Common wrong approaches:**

- Installing nodemon globally in the Makefile with `npm install -g nodemon` — this mutates
  the developer's system, creates version inconsistencies, and requires elevated permissions
  in CI containers.
- Using spaces instead of tabs in the Makefile — make will fail with `*** missing separator`
  and beginners spend an hour debugging what looks like correct syntax.
- Setting ESLint rules to `"warn"` when they should be `"error"` — `make lint` exits `0`
  even with violations, making the lint check useless in CI.

**What this sets up for later:** Every subsequent class adds a target to this Makefile.
`make docker-build`, `make docker-run`, `make k8s-deploy`. By the final class, `make help`
is the complete operations manual for the entire platform. Students who skip this class
find that later classes assume `make` exists and works.
