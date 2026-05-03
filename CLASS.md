# Class 07 — .dockerignore & Layer Caching

## The Scenario
The JCC team has adopted Docker and builds the image 20 times a day in CI.
Each build takes four minutes. The CI bill hit $800 last month. The senior
engineer looked at the build logs and found that `npm install` re-runs from
scratch on every single build — even when only a one-line comment changed in
`server.js`. She has escalated: fix the build pipeline or she is rolling back
to manual deploys. The fix must bring code-only builds under 30 seconds.

## The Problem
Two things are broken. First, the Dockerfile copies all source files before
running `npm install`, which means any code change invalidates the install
layer and forces a full re-download of every package. Second, there is no
`.dockerignore` file, so Docker uploads the entire project directory —
including `node_modules/` — to the daemon on every build. That context
transfer alone accounts for 90 seconds of each build.

## Your Mission
- A build where only `server.js` changes (not `package.json`) must show
  `CACHED` for the `npm install` step in the build output.
- The second of two consecutive builds (code change only) must complete in
  under 30 seconds on a warm machine.
- The Docker build context reported in the build output must be under 2 MB.
- The running container must still serve `curl localhost:3000/health`
  correctly — the optimisation must not break the application.
- You must paste the build output from both builds (cold and warm) as
  comments at the top of `.dockerignore`, showing the `CACHED` line and
  both elapsed times.

## What You Need to Know First
- **Build context**: The set of files Docker sends to the daemon before
  executing any instruction. Determined by the directory you pass to
  `docker build`. Large contexts slow down every build regardless of
  caching.
- **`.dockerignore`**: A file listing patterns to exclude from the build
  context. Same syntax as `.gitignore`.
- **Image layer**: Each filesystem-modifying instruction (`COPY`, `RUN`,
  `ADD`) produces an immutable layer. Layers are content-addressed and
  cached by Docker on the build machine.
- **Cache invalidation**: If a layer's instruction text or its input files
  change, Docker discards that layer and all layers below it in the
  Dockerfile. They cannot be reused even if their own content is unchanged.
- **Canonical npm-install pattern**: Copy only `package.json` and
  `package-lock.json` first. Run `npm install`. Then copy the rest of the
  source. This way `npm install` is only invalidated when the dependency
  manifest actually changes.

## Constraints
- You may NOT restructure the application code to make this work — only
  the Dockerfile and `.dockerignore` are in scope.
- You must prove the cache is working. The build output showing `CACHED`
  must be captured and committed as a comment.
- `node_modules/`, `.git/`, and `.env` must all be excluded from the build
  context.
- The final image must behave identically to the class-06 image from the
  outside — same port, same health endpoint, same response.

## Verification
```bash
# Build 1 — cold cache, note the elapsed time
time docker build -t jcc-app .

# Make a code-only change
echo "// cache test $(date)" >> server.js

# Build 2 — must be significantly faster; npm install must show CACHED
time docker build -t jcc-app .
# Look for a line like: => CACHED [3/5] RUN npm install ...

# Verify the build context size
docker build --no-cache --progress=plain -t jcc-app . 2>&1 | grep -i "transferring context"
# Expected: under 2MB

# Confirm the app still works
docker run -d -p 3000:3000 --name jcc-cache-test jcc-app
curl localhost:3000/health
docker stop jcc-cache-test && docker rm jcc-cache-test
```

## Stretch Challenge
Install `dive` (a Docker image layer inspection tool — find it on GitHub).
Build the class-06 Dockerfile (without cache optimisation) and the class-07
Dockerfile. Run `dive` on both images. For each image, document: the number
of layers, the size of the largest layer, and exactly what files it contains.
Explain in writing which layer is the culprit for most of the wasted space,
and whether fixing the layer order changes the final image size or only the
cache hit rate.

## Instructor Notes
The "$800/month" framing is accurate for a five-person team on a mid-tier CI
provider building a modest Node app 20 times per day. Students need to
understand that Dockerfile instruction order is not stylistic — it has direct
cost implications. The most common mistake is believing that a `.dockerignore`
alone will fix the cache problem. It will not; it only fixes the context
transfer time. The canonical COPY-lockfile / RUN-install / COPY-source pattern
must become muscle memory. The stretch challenge with `dive` introduces layer
analysis without it being required for the main mission, and previews the
multi-stage work in Class 08.
