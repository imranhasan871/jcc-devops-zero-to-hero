# Class 08 — Multi-Stage Docker Build

## Objective
A single-stage Dockerfile does the job, but the resulting image carries unnecessary weight:
devDependencies, build tools, test frameworks, and potentially sensitive build-time files.
Multi-stage builds are Docker's answer to this. We define multiple `FROM` instructions in
a single Dockerfile; each stage can use a different base image and can selectively copy
artefacts from previous stages. The final image contains only what is needed to run the
app — nothing more. We also introduce running the process as a non-root user, a security
best practice that takes one line and meaningfully shrinks the blast radius of any exploit.

## What You'll Learn
- How multi-stage builds work and why they matter for production images
- The `COPY --from=<stage>` syntax for selectively copying build artefacts
- How to measure Docker image size and understand where bytes come from
- The principle of least privilege applied to containers (non-root USER)
- How to name stages with `AS` and reference them by name

## What Changed in This Class
- Updated `Dockerfile` — two named stages: `builder` (all deps, full source) and
  `production` (prod deps only, selective COPY from builder, `USER node`)

## Hands-On Exercise
1. Build the multi-stage image: `docker build -t jcc-platform:class-08 .`
2. Compare image sizes:
   ```
   docker images | grep jcc-platform
   ```
   The class-08 image should be noticeably smaller than class-06/07 (no devDependencies).
3. Run the production image: `docker run -p 3000:3000 jcc-platform:class-08`
   The app works exactly the same from the browser's perspective.
4. Verify the non-root user: `docker run --rm jcc-platform:class-08 whoami`
   Output should be `node`, not `root`.
5. Try to install something as the node user:
   `docker run --rm jcc-platform:class-08 npm install -g cowsay`
   It should fail with a permission error — exactly what we want.
6. Inspect what's in the final image:
   `docker run --rm jcc-platform:class-08 ls /app`
   You should see only `public/`, `server.js`, `config.js`, `package.json`,
   `package-lock.json`, and `node_modules/` — nothing else.
7. Confirm no devDependencies: `docker run --rm jcc-platform:class-08 ls node_modules | grep nodemon`
   Should return empty — nodemon is not present.

## Key Concepts

**Multi-stage builds**: A single Dockerfile can contain multiple `FROM` instructions. Each
one starts a new stage with a clean filesystem. Stages can be named with `AS <name>`. You
copy files between stages with `COPY --from=<stage-name> <src> <dst>`. Only the last stage
is written into the final image; all previous stages are discarded after the build. This
pattern is essential for compiled languages (Go, Rust, TypeScript) where you need a full
compiler toolchain at build time but only a tiny runtime at deploy time. For Node.js, the
benefit is eliminating devDependencies and any intermediate build files.

**Image size and attack surface**: Every megabyte in a Docker image is a megabyte that
must be pulled from a registry, stored on every node in your cluster, and scanned by
security tools. More importantly, every installed package is a potential vulnerability.
A smaller image has fewer packages, fewer CVEs, and a simpler security audit. Multi-stage
builds are the single most effective technique for shrinking production images without
changing any application code.

**Non-root USER**: By default, processes inside a Docker container run as `root` (UID 0).
Root inside a container is not the same as root on the host (thanks to Linux namespaces),
but it is still far more permissive than necessary. The `node:20-alpine` image ships with
a built-in `node` user (UID 1000). Adding `USER node` before `CMD` means the Node.js
process runs with no ability to modify system files, install packages globally, or bind
to privileged ports (< 1024). Port 3000 is above the privileged threshold so this
restriction does not affect us. This is the principle of least privilege applied to
containers: grant only the permissions actually required, nothing more.

## Next Class Preview
Coming up: we add Docker Compose to orchestrate the application alongside a PostgreSQL
database, replacing our in-memory store with real persistent storage.
