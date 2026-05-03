# Class 24 — Jenkins + Kubernetes: Full CD Pipeline with Environment Promotion

## Objective
Complete the Jenkins CD pipeline by adding Kubernetes deployment stages for
both dev and production environments, with a manual approval gate before any
production release.

## What You'll Learn
- How to structure a multi-environment deployment pipeline
- How to use Jenkins `input` step for manual approval gates
- How to use Kubernetes namespaces to isolate environments
- Why human approval before production is a best practice, not a bottleneck

## What Changed in This Class
- Updated `Jenkinsfile` — added KUBECONFIG credential, "Deploy to Dev", "Approve Production Deploy" (input gate), and "Deploy to Production" stages
- Added `k8s/namespaces/dev.yaml` — jcc-dev namespace with ResourceQuota
- Added `k8s/namespaces/production.yaml` — jcc-production namespace with stricter ResourceQuota and LimitRange

## Hands-On Exercise
1. Create the namespaces: `kubectl apply -f k8s/namespaces/`
2. Add your kubeconfig to Jenkins credentials as a Secret File with ID `kubeconfig`
3. Trigger a build on main — watch it deploy to dev automatically
4. Check the dev deployment: `kubectl get pods -n jcc-dev`
5. In Jenkins, find the "Approve Production Deploy" step and click Proceed
6. Watch the production deployment complete
7. Verify: `kubectl get pods -n jcc-production`
8. Test rollback: trigger another build with a bad image tag, let it fail in dev, and observe that production is untouched

## Key Concepts

**Environment Promotion** — The industry standard pattern is: build once, deploy
many times. The same Docker image built in CI is deployed to dev, then staging,
then production. Each promotion is a gate: automated tests must pass in dev
before staging, and a human must approve before production. You never build a
new image for each environment — that would introduce drift and defeat the
purpose of testing.

**Manual Approval Gates** — The Jenkins `input` step pauses the pipeline and
sends a notification. A named list of users (the `submitter` field) can approve
or reject. This creates an audit trail: who approved, when, and for which build
number. This is not bureaucracy — it is accountability. One bad Saturday-night
deploy with no approval gate is enough to appreciate why this exists.

**Kubernetes Namespaces as Environment Isolation** — Namespaces are lightweight
Kubernetes partitions. Resources in `jcc-dev` are completely isolated from
`jcc-production` — different ConfigMaps, different Secrets, different resource
quotas. A developer can break the dev namespace completely without affecting
production. ResourceQuotas prevent a runaway dev workload from consuming
cluster resources needed by production.

## Next Class Preview
Class 25 — the final class — adds full observability with Prometheus and Grafana.
We will instrument the backend to expose metrics, set up a monitoring stack
with Docker Compose, and build a Grafana dashboard. You will have built a
complete DevOps pipeline from git commit to production monitoring.
