# ──────────────────────────────────────────────────────────────────────────────
# Dockerfile — Multi-stage build
#
# Stage 1 (builder): Install ALL dependencies (including devDependencies) and
#                    run any build steps (transpilation, bundling, etc.).
#
# Stage 2 (production): Start fresh from the same base image. Copy only the
#                       production artefacts from the builder stage. Install
#                       only production dependencies. Run as a non-root user.
#
# Why multi-stage?
#   - The final image contains ZERO build tools, test frameworks, or devDeps.
#   - Smaller image = faster pulls, less attack surface, lower storage cost.
#   - Non-root user = exploiting the app process cannot easily escalate to root.
# ──────────────────────────────────────────────────────────────────────────────

# ── Stage 1: builder ──────────────────────────────────────────────────────────
# This stage exists only during the build. Its layers are discarded afterwards
# and never appear in the final image.
FROM node:20-alpine AS builder

WORKDIR /app

# Copy manifests and install ALL dependencies (including dev) so we could run
# linting, tests, or a build step here if needed.
COPY package*.json ./
RUN npm install

# Copy the full source code into the builder stage.
COPY . .

# If this were a TypeScript project or a frontend with a bundler, you would run
# the build step here, e.g.: RUN npm run build


# ── Stage 2: production ───────────────────────────────────────────────────────
# We start completely fresh. Docker discards everything from the builder stage
# except what we explicitly COPY --from=builder.
FROM node:20-alpine AS production

WORKDIR /app

# Copy ONLY the dependency manifests and install production deps only.
# This is a separate npm install from the builder stage — no devDependencies.
COPY package*.json ./
RUN npm install --omit=dev

# Copy application source from the builder stage (not from your local machine).
# In a compiled project, you would copy the build output directory instead.
COPY --from=builder /app/public ./public
COPY --from=builder /app/server.js ./server.js
COPY --from=builder /app/config.js ./config.js

# ── Security: non-root user ───────────────────────────────────────────────────
# The node:20-alpine image ships with a built-in "node" user (UID 1000).
# By switching to it we ensure the Node.js process cannot write to system
# directories, cannot install packages, and cannot modify the image filesystem.
# If an attacker exploits a vulnerability in the app, their blast radius is
# limited to what UID 1000 can do — which is almost nothing.
USER node

EXPOSE 3000

CMD ["node", "server.js"]
