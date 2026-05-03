# Class 21 — Rolling Updates + Rollback + Horizontal Pod Autoscaling

## Objective
Configure the backend Deployment for zero-downtime rolling updates, add an
HPA to automatically scale pods based on load, and learn how to roll back a
bad deployment in seconds.

## What You'll Learn
- How the RollingUpdate strategy works step by step
- What maxUnavailable and maxSurge control
- How the HorizontalPodAutoscaler reacts to CPU metrics
- How to use kubectl rollout to deploy, monitor, and undo releases

## What Changed in This Class
- Updated `k8s/backend/deployment.yaml` — added explicit `RollingUpdate` strategy with `maxUnavailable: 0` and `maxSurge: 1`
- Added `k8s/backend/hpa.yaml` — HPA scaling between 2 and 5 replicas at 70% CPU
- Added Makefile targets: `k8s-rollout-status`, `k8s-rollback`, `k8s-rollout-history`, `k8s-scale`, `k8s-hpa-status`

## Hands-On Exercise
1. Apply everything: `kubectl apply -f k8s/backend/`
2. Watch a rollout in real time — change the image tag and apply: `kubectl set image deployment/backend backend=jcc-backend:v2 -n jcc`
3. Watch it roll: `make k8s-rollout-status`
4. Check rollout history: `make k8s-rollout-history`
5. Simulate a bad deploy with a nonexistent image: `kubectl set image deployment/backend backend=jcc-backend:broken -n jcc`
6. See it stall: `make k8s-rollout-status` (it will time out)
7. Roll back: `make k8s-rollback`
8. Watch the HPA: `make k8s-hpa-status` — install metrics-server first if needed: `minikube addons enable metrics-server`

## Key Concepts

**Zero-Downtime Rolling Updates** — With `maxUnavailable: 0`, Kubernetes never
removes an old pod until a new one is fully Ready (readiness probe passing). The
sequence is: scale up to `desired + maxSurge` pods → wait for new pods to pass
readiness → remove old pods one by one. Users always have at least `desired`
healthy pods serving traffic throughout.

**Rollback** — Every `kubectl apply` or `kubectl set image` creates a new
ReplicaSet and records a revision. `kubectl rollout undo` atomically switches
back to the previous ReplicaSet. You can also rollback to a specific revision:
`kubectl rollout undo deployment/backend --to-revision=2`. Kubernetes keeps a
history of revisions (default 10).

**HorizontalPodAutoscaler** — The HPA controller queries the Metrics Server
every 15 seconds. If average CPU across all pods exceeds 70%, it calculates how
many pods are needed: `desiredReplicas = ceil(currentReplicas * currentCPU / 70)`.
The stabilization window prevents flapping — the HPA waits 5 minutes before
scaling down to avoid thrashing during bursty traffic.

## Next Class Preview
Class 22 introduces Jenkins — a self-hosted CI/CD server. We will set it up
with Docker and write our first declarative pipeline that mirrors what GitHub
Actions does, but runs entirely on your own infrastructure.
