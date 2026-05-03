# Class 07 — .dockerignore & Layer Caching

## Objective
A working Dockerfile is not the same as an efficient one. In this class we make two
targeted improvements: a `.dockerignore` file to exclude irrelevant files from the build
context, and a reordering of Dockerfile instructions to exploit Docker's layer caching
mechanism. The result is a build that goes from potentially 60+ seconds down to under
2 seconds for the common case of "I only changed one line of JavaScript."

## What You'll Learn
- What the Docker build context is and why its size matters
- How `.dockerignore` works (and how it mirrors `.gitignore`)
- How Docker's layer caching works: what invalidates a cache hit
- Why instruction order in a Dockerfile is a performance and correctness concern
- The canonical pattern for caching `npm install` in a Dockerfile

## What Changed in This Class
- Added `.dockerignore` — excludes `node_modules/`, `.env`, `.git`, docs, editor noise
- Updated `Dockerfile` — split `COPY . .` into two steps: copy `package*.json` first,
  run `npm install`, then copy the rest of the source code

## Hands-On Exercise
1. Build the image once: `docker build -t jcc-platform:class-07 .`
   Note how long `npm install` takes.
2. Edit `public/index.html` — change the page title slightly. Save.
3. Build again: `docker build -t jcc-platform:class-07 .`
   Observe the output: steps 1-3 (FROM, WORKDIR, COPY package*.json) show "CACHED".
   The `npm install` step also shows "CACHED". Only the final `COPY . .` runs fresh.
4. Now edit `package.json` — add a space somewhere. Save.
5. Build again. This time `npm install` re-runs because `package*.json` changed.
6. Without `.dockerignore`, check what happens: temporarily rename it, then
   `docker build -t jcc-platform:no-ignore .` and watch the "Sending build context" line.
   With `.dockerignore` the context is a few KB; without it, it includes all of
   `node_modules/` (potentially 50+ MB sent to the Docker daemon every single build).

## Key Concepts

**Docker build context**: When you run `docker build .`, Docker sends all files in `.`
(the build context) to the Docker daemon before executing any instruction. If `node_modules/`
is not in `.dockerignore`, those hundreds of megabytes are uploaded on every single build —
even though `RUN npm install` immediately creates its own copy inside the image. The
`.dockerignore` file tells Docker which files to exclude from the context transfer,
making the initial step nearly instant.

**Layer caching and invalidation**: A Docker image is a stack of read-only layers. Each
instruction that modifies the filesystem (`COPY`, `RUN`, `ADD`) creates one layer. When
you rebuild, Docker compares each instruction against its cache. If the instruction text
AND all its inputs are identical to a previous build, Docker reuses the cached layer and
skips execution. The moment a layer is invalidated (its inputs changed), all layers below
it are also invalidated — they cannot be reused because their starting point has changed.
This is why the COPY/RUN order matters so much: `COPY . .` is invalidated on every source
change, so any `RUN npm install` after it can never be cached.

**package*.json glob**: Using `COPY package*.json ./` copies both `package.json` and
`package-lock.json` (if present) in a single instruction. `package-lock.json` is critical
because it pins the exact version of every transitive dependency — copying only
`package.json` would allow minor version drift between builds.

## Next Class Preview
We upgrade to a multi-stage Dockerfile that produces a smaller, more secure production
image by separating the build environment from the runtime environment.
