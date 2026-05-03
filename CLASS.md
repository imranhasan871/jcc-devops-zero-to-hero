# Class 06 — First Dockerfile

## The Scenario
The ops team at JCC has refused to deploy the platform. Their exact words in
Slack: "It works on Sarah's MacBook, crashes on Tom's Linux box, and the
staging server doesn't even have the right Node version. We're not touching
it until it ships as a container." The CTO has given you 48 hours to produce
a Docker image that runs identically everywhere. The client demo is in three
days.

## The Problem
The JCC Express application has no Dockerfile. Every deployment is a manual,
environment-specific process that depends on the host having the correct
version of Node, the correct system libraries, and the correct environment
variables pre-configured. There is no reproducible way to run this application
on a machine other than the developer's own laptop.

## Your Mission
- The command `docker build -t jcc-app .` must complete without errors.
- The command `docker run -p 3000:3000 jcc-app` must start the Express
  server and keep it running.
- `curl http://localhost:3000/health` must return `{"status":"ok"}`.
- The host machine must have no Node.js installed for this to still work.
  Docker itself is the only required dependency.
- The image must use `node:20-alpine` as its base. No other base is
  acceptable.
- Every instruction in the Dockerfile must have a comment explaining not
  what it does syntactically, but what production problem it solves — why
  a team would care if that line were missing.

## What You Need to Know First
- **Docker image**: A portable, read-only snapshot of a filesystem and its
  runtime configuration. Built once, runs anywhere Docker is installed.
- **Dockerfile**: A plain-text recipe that describes how to assemble an
  image, one instruction at a time.
- **FROM**: Declares the base image — the starting filesystem your image is
  built on top of.
- **WORKDIR**: Sets the working directory for subsequent instructions and
  for the process that runs at container start.
- **COPY**: Copies files from the host machine (build context) into the
  image filesystem.
- **RUN**: Executes a shell command during the build and commits the result
  as a new image layer.
- **CMD**: The default command that runs when a container starts. Not
  executed at build time.
- **Alpine Linux**: A minimal Linux distribution (~5 MB). Used as a base to
  keep images small and reduce the number of pre-installed packages that
  could carry vulnerabilities.

## Constraints
- You may NOT look up a Dockerfile tutorial or copy one from the internet
  during this exercise. Write it from the concepts above.
- The base image must be `node:20-alpine`. No Debian, no Ubuntu, no
  `node:latest`.
- `node_modules` from the host must NOT be copied into the image. The image
  must install its own dependencies during the build.
- Every Dockerfile instruction must carry a comment that explains the
  production reason for its existence — not the syntax.

## Verification
```bash
# Step 1 — build
docker build -t jcc-app .

# Step 2 — run in background
docker run -d -p 3000:3000 --name jcc-test jcc-app

# Step 3 — health check
curl http://localhost:3000/health
# Expected: {"status":"ok"}

# Step 4 — check image size (must be under 300 MB)
docker images jcc-app --format "{{.Size}}"

# Step 5 — clean up
docker stop jcc-test && docker rm jcc-test
```

## Stretch Challenge
Run `docker exec <container-id> whoami` while the container is running. You
will see `root`. Research why running a production process as root inside a
container is a security problem even with Linux namespaces in place. Find the
one-line Dockerfile change that makes the process run as a non-root user, and
apply it. Verify with `whoami` again. Document one real CVE or incident report
where a root container process was the contributing factor.

## Instructor Notes
The first Dockerfile students write almost always makes two mistakes: they copy
`node_modules` from the host (which breaks on architecture differences between
macOS and Linux), and they run as root without realising it. The comment
requirement is deliberate — it forces students to understand each instruction
rather than cargo-culting a template. Expect pushback on the "no tutorial"
constraint; hold the line. The stretch challenge plants the seed for Class 08
without giving away the multi-stage pattern. The root-user problem is one of
the most common findings in container security audits; students who discover it
themselves remember it.
