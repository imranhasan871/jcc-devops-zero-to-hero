# CI/CD Workflows

## Workflows

### `ci.yml` — Continuous Integration + Image Push

Triggered on every push and on pull requests targeting `main`.

**Jobs:**
1. `lint-and-test` — runs ESLint and Jest with coverage
2. `build-image` — builds the Docker image (always) and pushes to GHCR (main only)

## Secrets Required

| Secret | Source | Purpose |
|--------|--------|---------|
| `GITHUB_TOKEN` | **Automatic** — GitHub injects this into every workflow run. You do not need to create it. | Authenticates `docker login` to GitHub Container Registry (ghcr.io) and allows uploading artifacts. |
| `REGISTRY_PASSWORD` | **Optional** — only needed if you push to a registry *other than* GHCR (e.g., Docker Hub). Create it under *Settings → Secrets and variables → Actions → New repository secret*. | Password / access token for an external container registry. |

## How to Use the Published Image

After a successful push to `main`, pull the image:

```bash
docker pull ghcr.io/<owner>/<repo>/jcc-app:latest
# or a specific commit:
docker pull ghcr.io/<owner>/<repo>/jcc-app:<git-sha>
```

## Making the Package Public

By default GHCR packages are private. To make them public:
1. Go to your GitHub profile → **Packages**
2. Find `jcc-app` → **Package settings**
3. Change visibility to **Public**
