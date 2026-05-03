# Class 13 — Docker Build in CI Pipeline

## Objective
Add a second CI job that builds the Docker image on every successful test run.
This ensures that a broken Dockerfile is caught in CI rather than discovered
by an engineer trying to deploy at 2 AM.

## What You'll Learn
- How to chain CI jobs with `needs:`
- What Docker Buildx is and why we use it
- How to tag an image with the Git commit SHA for traceability
- Why building the image in CI is a form of testing
- The concept of "shift left" — catching problems earlier in the pipeline

## What Changed in This Class
- Updated `.github/workflows/ci.yml` to add a `build-image` job
- `build-image` runs only after `lint-and-test` succeeds (`needs: lint-and-test`)
- Uses `docker/setup-buildx-action` for efficient multi-platform builds
- Tags the image with `${{ github.sha }}` — the full 40-character commit hash

## Hands-On Exercise
1. Push this branch — watch two jobs appear in the GitHub Actions UI
2. Click `build-image` and expand the "Build Docker image" step to see build output
3. Introduce a deliberate syntax error in `Dockerfile` (e.g., misspell `FROM`)
4. Push and confirm `build-image` fails
5. Revert the error, push again — observe `lint-and-test` must pass first before `build-image` runs
6. Notice that `build-image` is skipped entirely when `lint-and-test` fails

## Key Concepts

**Job Dependencies with `needs:`**
By default, all jobs in a workflow run in parallel. Adding `needs: lint-and-test`
creates a dependency: `build-image` only starts if `lint-and-test` completes
successfully. This is efficient — no point spending 3 minutes building an image
if the tests already tell you the code is broken.

**Why Build the Image in CI?**
The Dockerfile is code. Like any code, it can have bugs:
- A `COPY` path that doesn't match the actual file layout
- A base image that no longer exists
- An `npm ci` that fails because `package-lock.json` is out of sync
Building in CI means every PR proves the image can be constructed. Without this,
Dockerfile bugs are typically discovered only at deploy time.

**Tagging with `github.sha`**
`${{ github.sha }}` is the full Git commit hash (e.g., `a3f8c2d...`). Using it
as an image tag creates a direct, unambiguous link between a running container
and the exact line of code it was built from. This is far better than `:latest`,
which is mutable and tells you nothing about what code is inside.

## Next Class Preview
In Class 14 we push the built image to the GitHub Container Registry (GHCR).
The image becomes an artifact that can be pulled and deployed by any system —
staging servers, Kubernetes clusters, or teammates' machines.
