# ──────────────────────────────────────────────────────────────────────────────
# Dockerfile — Optimised layer caching
#
# Key insight: Docker caches each layer. If a layer's inputs haven't changed,
# Docker reuses the cached layer instead of re-running the instruction.
#
# WRONG order (slow):              RIGHT order (fast, this file):
#   COPY . .                         COPY package*.json ./
#   RUN npm install                  RUN npm install
#                                    COPY . .
#
# With the wrong order, any change to ANY source file (even a typo in a comment)
# invalidates the COPY layer, which invalidates the RUN npm install layer, which
# means npm install runs from scratch on every build. With the right order, npm
# install is only re-run when package.json or package-lock.json actually changes.
# ──────────────────────────────────────────────────────────────────────────────

FROM node:20-alpine

WORKDIR /app

# STEP 1: Copy only the dependency manifest files first.
# These files change infrequently. As long as they haven't changed,
# Docker reuses the cached result of the npm install step below.
COPY package*.json ./

# STEP 2: Install dependencies.
# This layer is cached and reused on the next build IF package*.json hasn't changed.
# Typical npm install: 30-60 seconds. With caching: ~0 seconds.
RUN npm install --omit=dev

# STEP 3: Copy the rest of the source code.
# This layer changes on every code edit — but that's fine because it doesn't
# trigger a re-install of npm packages. Docker rebuilds only from this point.
COPY . .

EXPOSE 3000

CMD ["node", "server.js"]
