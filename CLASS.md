# Class 08 — Multi-Stage Docker Build

## The Scenario
Automated security scanning ran overnight on the JCC image that shipped to
staging. The report landed in your inbox at 07:00: 47 vulnerabilities, 6
classified CRITICAL. The CVEs trace back to development tools and test
frameworks that were accidentally included in the production image. The ops
team has a non-negotiable policy: production images must be under 120 MB and
must carry zero CRITICAL CVEs. The image is currently 680 MB. The client goes
live in four days.

## The Problem
The existing single-stage Dockerfile installs every dependency — including
`nodemon`, `jest`, `eslint`, and their entire transitive trees — into the
final production image. None of those packages run in production. They exist
only to serve the development and test workflow. The image is nearly six times
larger than it needs to be, and every dev tool installed is a potential
exploit surface.

## Your Mission
- The production image produced by `docker build -t jcc-app:prod .` must be
  under 120 MB.
- `docker run --rm jcc-app:prod whoami` must NOT output `root`.
- The application must still serve all endpoints correctly: `/health`,
  `/api/programs`, and `/api/applicants`.
- The `node_modules` directory in the production image must contain zero
  devDependencies. Verify this by checking that `nodemon` is absent.
- The same Dockerfile must produce both a build stage (unlimited size, all
  tools) and the final production stage (lean, runtime-only).

## What You Need to Know First
- **Multi-stage build**: A Dockerfile with more than one `FROM` instruction.
  Each `FROM` starts a new stage with a clean filesystem. Only the last stage
  is written into the final image.
- **`AS <name>`**: Gives a build stage a name so it can be referenced later.
- **`COPY --from=<stage>`**: Copies files from a named or numbered build
  stage into the current stage. This is how artefacts move from the build
  environment to the production environment.
- **devDependencies vs dependencies**: `npm install --omit=dev` installs only
  `dependencies` in `package.json`, skipping `devDependencies`. Running this
  in the production stage is what removes test and tooling packages.
- **Principle of least privilege**: Grant a process only the permissions it
  actually needs. For a web server on port 3000, that means running as a
  non-root user with no ability to modify system files.
- **UID 1000**: The `node:20-alpine` image ships with a built-in user named
  `node` at UID 1000. `USER node` in a Dockerfile switches to that user for
  all subsequent instructions and for the container process.

## Constraints
- The solution must be a single Dockerfile with at least two named stages.
  You may NOT create two separate Dockerfiles.
- devDependencies must not appear in the production stage. You may NOT
  achieve this by deleting `devDependencies` from `package.json`.
- The production image must run as a non-root user. You may NOT use
  `USER root` anywhere in the production stage.
- You must verify both the image size and the running user with the exact
  commands in the Verification section before considering the task complete.

## Verification
```bash
# Build the production image
docker build -t jcc-app:prod .

# Size check — must be under 120 MB
docker images jcc-app:prod --format "{{.Size}}"

# User check — must NOT be "root"
docker run --rm jcc-app:prod whoami

# devDependency check — nodemon must be absent
docker run --rm jcc-app:prod ls /app/node_modules | grep nodemon
# Expected: empty output (no match)

# Application check
docker run -d -p 3000:3000 --name jcc-prod-test jcc-app:prod
curl localhost:3000/health
curl localhost:3000/api/programs
docker stop jcc-prod-test && docker rm jcc-prod-test
```

## Stretch Challenge
Install `trivy` (a container vulnerability scanner) or use `docker scout cves`
if Scout is available. Run a scan against `jcc-app:prod`. List every CRITICAL
and HIGH CVE in the output. For each one, identify which package carries it,
whether updating that package or choosing a different base image tag would
resolve it, and whether it is exploitable in this application's threat model.
Pick one CVE and resolve it. Re-run the scan to confirm it is gone.

## Instructor Notes
Multi-stage builds are not an advanced technique — they are the baseline
expectation for any production container. The 680 MB / 47 CVE numbers are
realistic for a Node project that naively copies everything into one stage.
The stretch challenge with Trivy introduces the security scanning workflow
that appears in Class 36; seeing it here, informally, means students arrive
at that class with context rather than starting cold. The most common wrong
approach is trying to `RUN npm prune --production` in a single-stage build
after the fact — this is fragile and does not remove binaries installed by
dev tools. The correct solution is a clean production stage that never
installs devDependencies in the first place.
