# Class 14 — The Image Must Land Somewhere

## The Scenario
CI builds a Docker image on every push. The image is tagged with the commit SHA,
scanned for CVEs, and proves it works. Then the GitHub Actions runner shuts down
and the image is gone. The staging server has no way to pull it. The ops team
lead sends a message at 9am: "The image exists for 6 minutes and then
disappears. What is the point?" Every deployment still requires a developer to
run `docker save | gzip | ssh` to transfer a tarball by hand. That is not CD.

## The Problem
Images built in CI are ephemeral — they live only for the duration of the
Actions run. There is no registry. There is no pull URL. There is no history of
what was deployed. The ops team cannot deploy without a developer's manual
involvement.

## Your Mission
1. Push the Docker image to GitHub Container Registry (`ghcr.io`) on every
   merge to `main`. The image must be tagged with both the commit SHA and
   `latest`.
2. Feature branches must NOT push to the registry — the push step must be
   gated on `github.ref == 'refs/heads/main'`.
3. Authentication must use the automatic `GITHUB_TOKEN` — no personal access
   tokens, no stored credentials.
4. After a successful push, the job must log the full pull URL so the ops team
   can copy it without navigating GitHub.
5. Pull the pushed image on your local machine and verify the app starts and
   responds to `GET /health`.

## What You Need to Know First
- `ghcr.io` image naming convention:
  `ghcr.io/<github-username>/<repo-name>/<image-name>:<tag>`
- `docker login ghcr.io` using `GITHUB_TOKEN` as the password
- GitHub Actions `if:` conditionals on steps — `github.ref` context
- `packages: write` permission in the workflow's `permissions:` block
- The difference between `docker tag` and building with `--tag` directly

## Constraints
- The push step must use an `if:` condition. Pushing from a feature branch is
  a hard failure — the job must skip the push, not fail.
- The workflow must have an explicit `permissions:` block granting
  `packages: write` and `contents: read`. Do not use `permissions: write-all`.
- The job must print the full image URL after push:
  `echo "Image pushed: ghcr.io/..."`. The ops team reads job logs, not source
  code.
- You must pull and run the image locally after the first successful push to
  `main`. Record the `docker run` output in your notes.

## Verification
```bash
# After merging to main on GitHub and the pipeline completes:
docker pull ghcr.io/<your-username>/jcc-devops-zero-to-hero/jcc-app:latest
docker run -d -p 3000:3000 ghcr.io/<your-username>/jcc-devops-zero-to-hero/jcc-app:latest
curl localhost:3000/health
# Must return: {"status":"ok"} or similar

# Verify the SHA-tagged image also exists:
docker pull ghcr.io/<your-username>/jcc-devops-zero-to-hero/jcc-app:<commit-sha>

# Verify the package is publicly visible:
# https://github.com/<your-username>/jcc-devops-zero-to-hero/pkgs/container/jcc-app

# Verify a feature branch push does NOT create a new package version:
# Push a commit to a non-main branch.
# The pipeline must show the push step as "skipped".
```

## Stretch Challenge
Write a second job `deploy-staging` that runs after `push-image` and is also
gated to `main` only. The job should SSH into a staging server and run:
`docker pull`, `docker stop jcc-app || true`, `docker run -d --name jcc-app`.
Use `appleboy/ssh-action` for the SSH step. Even if you do not have a staging
server, write the complete job YAML and document exactly which GitHub repository
secrets it would require and how those secrets would be created.

## Instructor Notes
`GITHUB_TOKEN` for registry auth is the correct pattern for any team using
GitHub. It requires zero secret management — the token is automatically
available in every workflow run with the right scope. Using a PAT instead means
rotating credentials, managing expiry, and storing a secret with broader
permissions than needed.

The dual-tag strategy (`latest` and `<sha>`) serves two different consumers.
`latest` is for "give me whatever is current" — staging automation, local dev
pulls. The SHA tag is for "give me exactly this version" — rollback, audit
trails, incident response.

Wrong approach to avoid: pushing on every branch. Every image pushed is stored
in the registry and incurs storage cost and attack surface. Only images that
have passed full CI on `main` should reach the registry. Feature branch images
are hypothetical — they represent code that has not been approved for any
environment.
