# Class 05 — npm Scripts & Makefile

## Objective
As a project grows, the number of commands a developer needs to remember grows with it.
"How do I start the dev server? How do I run the linter? How do I clean up?" Without a
standard interface, each developer remembers different things and onboarding takes longer
than it should. This class establishes two complementary tools: `npm scripts` for
Node.js-native tasks, and a `Makefile` as a universal command façade that works regardless
of the underlying language or toolchain.

## What You'll Learn
- How npm scripts work and why they are preferred over global tools for project tasks
- The role of `nodemon` for development: automatic server restart on file changes
- The basics of `eslint` for code quality enforcement
- What a `Makefile` is and why it is still widely used in modern DevOps toolchains
- How to write a self-documenting `Makefile` with a `help` target

## What Changed in This Class
- Updated `package.json` — added `start`, `dev`, `lint`, `test` scripts; added `devDependencies`
- Added `.eslintrc.json` — ESLint configuration: no-var, prefer-const, strict equality, single quotes
- Added `Makefile` — targets: `install`, `dev`, `start`, `lint`, `test`, `clean`, `help`

## Hands-On Exercise
1. Run `make help` to see all available targets.
2. Run `make install` to install dependencies (including new devDependencies).
3. Run `make dev` to start the server with nodemon. Edit `server.js` — change the console
   log message and save. Notice nodemon automatically restarts the server.
4. Run `make lint` to check for code quality issues.
5. Intentionally introduce a lint error: add `var x = 1` to `server.js`, run `make lint`,
   observe the error, then remove it.
6. Run `make test` — it passes with no tests yet (`--passWithNoTests` flag).
7. Run `make clean` to delete `node_modules/`, then `make install` to restore.
8. Compare: `npm run dev` vs `make dev`. Both do the same thing — `make` is just a
   language-agnostic wrapper that future team members (Python, Go, etc.) can also use.

## Key Concepts

**npm scripts**: The `"scripts"` section of `package.json` defines short aliases that run
via `npm run <name>`. They automatically add `node_modules/.bin` to the PATH, so locally
installed tools (like `eslint`, `nodemon`, `jest`) can be called by name without a full
path or global install. This means every developer gets the exact same version of every
tool, controlled by `package.json`.

**nodemon**: A development-only process monitor that watches your files for changes and
automatically restarts the Node.js process. Without it, you must `Ctrl+C` and re-run
`node server.js` after every code change. Nodemon is listed under `devDependencies` because
it is never needed in production — in production the process is managed by Docker or a
process manager.

**Makefile**: Originally designed for C build systems, `make` is now used across almost
every language ecosystem as a task runner. Its advantages are universal: no runtime
required, tab-indented recipes are explicit, `.PHONY` targets prevent confusion with
same-named files, and the convention is so well understood that any DevOps engineer can
read a Makefile without explanation. Many CI/CD systems call `make test` and `make build`
as their primary entry points.

## Next Class Preview
We write our first `Dockerfile`, containerising the application so it can run identically
on any machine with Docker installed.
