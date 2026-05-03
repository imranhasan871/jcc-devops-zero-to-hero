# ──────────────────────────────────────────────────────────────────────────────
# Dockerfile — Single-stage build
# This is the simplest possible Dockerfile: one stage, copy everything, install.
# (We will improve layer caching in class-07 and add multi-stage in class-08.)
# ──────────────────────────────────────────────────────────────────────────────

# FROM: The base image. We use the official Node.js image on Alpine Linux.
# Alpine is a minimal Linux distribution (~5 MB), making our image much smaller
# than the default Debian-based node image (~900 MB vs ~170 MB).
# The tag "20-alpine" pins us to Node.js major version 20 on Alpine.
FROM node:20-alpine

# WORKDIR: Sets the working directory inside the container for all subsequent
# instructions (COPY, RUN, CMD). If the directory does not exist Docker creates it.
# Using /app is a common convention.
WORKDIR /app

# COPY: Copies files from the build context (your local machine) into the image.
# The first argument is the source (on your machine), the second is the destination
# (inside the image). "." copies everything in the current directory into /app.
COPY . .

# RUN: Executes a shell command during the image build. Each RUN instruction creates
# a new layer in the image. Here we install only production dependencies.
# --omit=dev skips devDependencies (nodemon, eslint, jest) to keep the image lean.
RUN npm install --omit=dev

# EXPOSE: Documents which port the container listens on at runtime.
# This is metadata only — it does NOT actually publish the port. You still need
# -p 3000:3000 when running docker run to map it to your host.
EXPOSE 3000

# CMD: The default command to run when the container starts.
# Use the JSON array ("exec") form to avoid wrapping the process in a shell.
# This ensures signals (like SIGTERM from docker stop) reach the Node.js process directly.
CMD ["node", "server.js"]
