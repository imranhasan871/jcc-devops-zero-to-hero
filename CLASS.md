# Class 22 — Jenkins: Setup + First Jenkinsfile

## Objective
Install Jenkins locally using Docker and create a Declarative Pipeline that
runs lint and tests on every commit — the same workflow as our GitHub Actions
CI but running on self-hosted infrastructure.

## What You'll Learn
- How Jenkins differs from GitHub Actions and when to choose each
- What a Declarative Pipeline is and how its stages/steps/post blocks work
- How to connect Jenkins to a Git repository
- How to run Jenkins with Docker access for later Docker build stages

## What Changed in This Class
- Replaced `Jenkinsfile` with a clean Declarative Pipeline: Checkout → Install → Lint → Test
- Added `jenkins/README.md` with step-by-step local Jenkins setup instructions

## Hands-On Exercise
1. Start Jenkins: follow `jenkins/README.md` to run the Docker command
2. Complete first-time setup and install the recommended plugins
3. Install the Docker Pipeline plugin from the plugin manager
4. Create a new Pipeline job pointing to this repository
5. Trigger your first build and explore the Stage View
6. Break a lint rule intentionally — watch the Lint stage go red
7. Fix it and rebuild — watch all stages go green

## Key Concepts

**Jenkins vs GitHub Actions** — GitHub Actions is a cloud service: you push
code, GitHub spins up a fresh virtual machine, runs your workflow, and tears it
down. It is fast to set up and has zero infrastructure to manage, but you are
limited by GitHub's runner capacity and you pay per minute beyond the free tier.
Jenkins is self-hosted: you manage the server, the agents, the plugins, and the
disk space. This gives you full control — custom hardware, air-gapped
environments, no minute limits — but also full responsibility.

**Declarative Pipeline** — Jenkins supports two pipeline syntaxes. Scripted
Pipelines use Groovy directly. Declarative Pipelines use a structured DSL with
`pipeline {}`, `stages {}`, `stage {}`, `steps {}`, and `post {}` blocks. The
Declarative syntax is easier to read, validates earlier, and is the recommended
approach for new pipelines. The `post` block runs cleanup or notifications
regardless of whether the build passed or failed.

**`npm ci` vs `npm install`** — In CI environments always use `npm ci`. It
reads `package-lock.json` exactly, fails if the lock file is missing or
inconsistent with `package.json`, and never updates the lock file. This
guarantees reproducible builds across every agent and every branch.

## Next Class Preview
Class 23 extends the Jenkinsfile to build Docker images, push them to a
registry with credentials, and run a security scan stub — making Jenkins a
full CI system comparable to the GitHub Actions workflow we built in class 15.
