# Class 06 — First Dockerfile

## Objective
A Dockerfile is a recipe for building a container image — a portable, self-contained
snapshot of your application and everything it needs to run. Once built, the image runs
identically on your laptop, a teammate's Windows machine, a CI server, and a production
cloud instance. This class introduces the five core Dockerfile instructions and produces
a working image for the JCC platform.

## What You'll Learn
- What a Docker image is and how it relates to a container
- The five essential Dockerfile instructions: `FROM`, `WORKDIR`, `COPY`, `RUN`, `CMD`
- The difference between build time and runtime in Docker
- How to build an image and run a container locally
- Why Alpine Linux is a popular base image choice

## What Changed in This Class
- Added `Dockerfile` — single-stage build: FROM node:20-alpine, COPY all files,
  RUN npm install (prod only), EXPOSE 3000, CMD node server.js

## Hands-On Exercise
1. Build the image: `docker build -t jcc-platform:class-06 .`
   Watch the output — each instruction is a separate step.
2. List your local images: `docker images | grep jcc-platform`
3. Run a container: `docker run -p 3000:3000 jcc-platform:class-06`
4. Open `http://localhost:3000` in your browser. The app works exactly as before.
5. In another terminal, check running containers: `docker ps`
6. Stop the container: `docker stop <container-id>` (use the ID from `docker ps`).
7. Run it with an overridden port: `docker run -p 4000:3000 -e PORT=3000 jcc-platform:class-06`
   Access it on `http://localhost:4000`.
8. Inspect the layers: `docker history jcc-platform:class-06`
   Notice how each instruction produced a layer of different sizes.

## Dockerfile Instructions Explained

**FROM node:20-alpine**: Every Dockerfile must start with FROM. It names the base image
to build upon. `node:20-alpine` gives us a Linux environment with Node.js 20 pre-installed,
built on Alpine — a security-focused, minimal Linux distribution that results in images
roughly 5× smaller than the default Debian-based node image. Always pin to a major version
tag (not `latest`) so builds are reproducible.

**WORKDIR /app**: Sets the current directory for all following instructions. Think of it
as `mkdir /app && cd /app`. Using a dedicated directory (conventionally `/app`) keeps
your application files separate from system files in the image.

**COPY . .**: Copies everything from your local project directory (the "build context")
into the container's working directory. The first `.` is "everything here on my machine",
the second `.` is "into the current WORKDIR in the image".

**RUN npm install --omit=dev**: Executes a shell command inside the image during the build.
`--omit=dev` skips devDependencies so `nodemon`, `eslint`, and `jest` are not included —
they are only needed during development, not at runtime. Every `RUN` creates a new
immutable layer in the image.

**EXPOSE 3000**: Declares that the container listens on port 3000. This is documentation
for humans and orchestration tools — it does not open any ports by itself. You still pass
`-p 3000:3000` to `docker run` to map the container port to your host.

**CMD ["node", "server.js"]**: The default command that runs when the container starts.
Using the JSON array form (exec form) avoids wrapping the process in `/bin/sh -c`, which
means Docker's `SIGTERM` signal for graceful shutdown reaches Node.js directly instead
of being swallowed by the shell.

## Next Class Preview
We add `.dockerignore` to speed up builds and learn why the order of `COPY` and `RUN`
instructions dramatically affects how often Docker can reuse its cached layers.
