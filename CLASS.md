# Class 23 — Jenkins: Full CI Pipeline (Test + Docker Build + Push)

## Objective
Extend the Jenkins pipeline to build Docker images for all three services,
run a security scan stub, and push images to a registry — but only when
building the main branch.

## What You'll Learn
- How to use Jenkins environment variables and BUILD_NUMBER for image tags
- How to run parallel stages to speed up Docker builds
- How the Jenkins Credentials Binding plugin keeps secrets out of logs
- Why you should only push images from protected branches

## What Changed in This Class
- Updated `Jenkinsfile` with `environment` block (REGISTRY, IMAGE_TAG), parallel Docker build stages, security scan stub, and conditional push stage

## Hands-On Exercise
1. Create a registry credential in Jenkins: Manage Jenkins → Credentials → (global) → Add Credentials (Username with password, ID: registry-credentials)
2. Trigger a build on a feature branch — the Push stage should be skipped
3. Merge to main and trigger again — the Push stage should run
4. View the "Stage View" in Jenkins to see the parallel build timings
5. Intentionally fail one parallel stage — observe which other stages are affected
6. Add a real Trivy scan by uncommenting the stub and running it against the backend image

## Key Concepts

**Jenkins Credentials Store** — Never hardcode secrets in a Jenkinsfile. The
Credentials Binding plugin injects secrets as environment variables for the
duration of a `withCredentials {}` block, then scrubs them from memory. Jenkins
also masks the secret values in the console log, replacing them with `****`.
Store registry credentials, kubeconfig files, SSH keys, and API tokens here.

**Parallel Stages** — Wrapping multiple `stage {}` blocks inside a `parallel {}`
block runs them simultaneously on the same agent. Building three Docker images
in parallel rather than in sequence reduces total build time roughly 3x. If any
parallel stage fails, Jenkins marks the parallel block as failed but lets other
parallel stages finish unless you set `failFast: true`.

**Conditional Execution with `when`** — The `when { branch 'main' }` directive
means the stage only runs when Jenkins is building the `main` branch. This
prevents feature branches from pushing untested images to production registries.
You can combine conditions: `when { branch 'main'; not { changeRequest() } }`.

## Next Class Preview
Class 24 closes the loop by adding Kubernetes deployment stages to Jenkins —
deploy to a dev namespace automatically and to production only after a manual
approval gate, completing a full GitOps-style CD pipeline.
