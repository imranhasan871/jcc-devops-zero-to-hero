# Class 14 — Push Docker Image to Registry

## Objective
After a successful build, publish the Docker image to the GitHub Container
Registry (GHCR) so it can be pulled and deployed by any authorized system.
Understand how secrets work in CI and why image pushes should only happen
from the main branch.

## What You'll Learn
- What a container registry is and why you need one
- How to authenticate to GHCR using `GITHUB_TOKEN`
- How to conditionally run steps only on the `main` branch
- How to tag an image with both a commit SHA and `:latest`
- What the `permissions:` block in a workflow job does

## What Changed in This Class
- Updated `build-image` job in `ci.yml` to log in and push to `ghcr.io` on `main`
- Push step is guarded by `if: github.ref == 'refs/heads/main'` — branches only build, never push
- Image is tagged with both `${{ github.sha }}` (immutable) and `latest` (mutable pointer)
- Added `permissions: packages: write` so the workflow can push to GHCR
- Added `.github/workflows/README.md` documenting the two secrets

## Hands-On Exercise
1. Merge this branch into `main` (or push directly to `main` in your fork)
2. Watch the Actions run — `build-image` should now include "Log in" and "Push" steps
3. Go to your GitHub profile → **Packages** — you should see `jcc-app` listed
4. On a feature branch, push a commit — confirm the Push step is *skipped*
5. Pull the image locally: `docker pull ghcr.io/<your-org>/<repo>/jcc-app:latest`

## Key Concepts

**Container Registries**
A registry is a storage and distribution system for Docker images — think of
it as npm but for containers. GHCR (GitHub Container Registry) is tightly
integrated with GitHub: authentication reuses `GITHUB_TOKEN`, and packages
are linked directly to the repository. Alternatives include Docker Hub,
Amazon ECR, and Google Artifact Registry.

**`GITHUB_TOKEN` — The Automatic Secret**
Every workflow run is automatically injected with a short-lived `GITHUB_TOKEN`.
You do not create it — GitHub creates it for you. By default it has read
permissions; we grant `packages: write` in the `permissions:` block so the
job can push images to GHCR. The token expires when the workflow run ends,
making it safer than a long-lived personal access token.

**Branch Guards on Push**
`if: github.ref == 'refs/heads/main'` ensures images are only pushed when
code has been reviewed and merged. Feature branches build the image (proving
the Dockerfile works) but do not pollute the registry with every experimental
commit. This pattern — build everywhere, push only from main — is a widely
adopted best practice.

## Next Class Preview
In Class 15 we leave CI/CD behind and enter the world of Kubernetes. We start
with concepts and a single namespace resource — learning the vocabulary before
we write any deployments.
