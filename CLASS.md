# Class 13 — Immutable Images or It Didn't Happen

## The Scenario
The team deploys by SSH-ing into the server, running `git pull`, and restarting
the process. Two weeks ago a developer deployed on a Friday afternoon. The
Node.js version on the server was 16. Local development used Node 20. A native
module behaved differently and the app was down for 45 minutes while the team
figured out why `npm ci` had silently installed a different binary. The ops team
has issued a mandate: every deployment must produce an immutable, versioned
artifact that was built and tested in CI — not on someone's laptop, not on the
production server.

## The Problem
The CI pipeline validates code but produces nothing. There is no Docker image,
no artifact, no record of what was deployed. "Rollback" means SSH-ing in and
running `git checkout <sha>` by hand, hoping the Node version still matches.
There is no way to know whether what is running in production corresponds to any
particular commit.

## Your Mission
1. Extend the existing CI workflow with a `build-image` job that runs only after
   `lint-and-test` passes — never in parallel, never if lint or tests fail.
2. The job must build the Docker image using a multi-stage Dockerfile that
   produces a minimal production image (no dev dependencies, no build tools in
   the final stage).
3. Tag the image with the full Git commit SHA — not `latest`, not a branch name.
   The tag must be deterministic and unique per commit.
4. Run `trivy image` against the built image and fail the job if any
   `CRITICAL` severity CVEs are found.
5. The image must be built but not pushed to any registry yet — that is the next
   class.

## What You Need to Know First
- GitHub Actions `needs:` keyword — how job dependency ordering works
- Docker multi-stage builds: `FROM node:20-alpine AS builder`, `FROM
  node:20-alpine`, `COPY --from=builder`
- `docker build --cache-from` and `--cache-to` with GitHub Actions cache
- `trivy image --exit-code 1 --severity CRITICAL` — what exit code 1 does in a
  CI step
- `${{ github.sha }}` — the Actions context variable for the commit hash

## Constraints
- The `build-image` job must declare `needs: lint-and-test`. If you push a
  branch with a lint error, the Actions tab must show `lint-and-test` failed and
  `build-image` skipped — not failed, skipped.
- Docker layer caching must use `--cache-from type=gha` and `--cache-to
  type=gha,mode=max`. A rebuild with no code changes must complete in under
  60 seconds.
- The multi-stage Dockerfile must result in a final image under 200 MB. If it
  exceeds this, revisit what you're copying into the final stage.
- You may not push to Docker Hub or any external registry in this class.

## Verification
```bash
# Push a commit to your branch.
# In the Actions tab, verify the workflow shows two jobs in sequence:
#   lint-and-test → build-image
# The build-image job logs must include a line showing the image size, e.g.:
#   => => writing image sha256:abc123...  0.1s
#   Size: 148 MB

# To verify the needs: dependency works:
# Introduce a lint error, push.
# lint-and-test must show ✗
# build-image must show "skipped" — not ✗, not ✓

# To verify Trivy works:
# The Trivy step must appear in the build-image job logs.
# If no CRITICAL CVEs exist, the step passes.
# The step must show the image name with the commit SHA tag.
```

## Stretch Challenge
Add a smoke test step after the image is built: start the container, wait for
the app to be ready, hit `GET /health`, then stop the container. The step must
fail if the health check returns anything other than `200`. Write the step
without using any marketplace actions. Document one class of bug that this smoke
test catches which unit tests cannot.

## Instructor Notes
The SHA tag is the key architectural decision. `latest` is a lie — it tells you
nothing about what version is actually running. Every image must have a
unique, traceable tag that maps to a specific commit. This is what makes
rollback possible: `docker run ghcr.io/org/app:abc1234` always runs the same
code regardless of when you run it.

Multi-stage builds are not optional polish. A single-stage Node image that
includes `devDependencies` ships Jest, ESLint, and all test tooling to
production. That is dead weight at minimum and a security surface at worst.

Wrong approach to avoid: building the image locally and pushing it from a
developer machine. The entire point is that CI builds the image in a controlled,
reproducible environment. An image built on a developer's Apple Silicon Mac may
not run on an AMD64 production server — `--platform linux/amd64` is one reason
to always build in CI.
