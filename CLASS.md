# Class 20 — Health Checks: Liveness + Readiness Probes

## Objective
Configure Kubernetes health probes on the backend Deployment so the cluster
can detect unhealthy pods, route traffic only to ready pods, and automatically
restart broken containers without manual intervention.

## What You'll Learn
- The difference between liveness, readiness, and startup probes
- How probe failures affect pod lifecycle and traffic routing
- How to tune probe timing to avoid false positives
- Why probes are essential for zero-downtime deployments

## What Changed in This Class
- Updated `k8s/backend/deployment.yaml` with explicit readiness, liveness, and startup probes with documented parameters
- Added resource requests and limits to the backend container

## Hands-On Exercise
1. Apply the updated deployment: `kubectl apply -f k8s/backend/deployment.yaml`
2. Watch pods roll over: `kubectl rollout status deployment/backend -n jcc`
3. Describe a pod to see probe config: `kubectl describe pod -l tier=backend -n jcc | grep -A 10 Liveness`
4. Simulate a failing health check by temporarily changing `/health` to `/bad` in the deployment and applying it
5. Watch Kubernetes restart the pod: `kubectl get pods -n jcc -w`
6. Check restart count: `kubectl get pods -n jcc` — look at the RESTARTS column
7. Fix the path and redeploy to restore health

## Key Concepts

**Readiness Probe** — Answers the question: "Is this pod ready to serve
traffic?" When a readiness probe fails, Kubernetes removes the pod from the
Service's Endpoints list. Requests stop being routed to it, but the pod keeps
running. This is perfect for handling warm-up time, database reconnection, or
temporary overload. Once the probe passes again, the pod is added back
automatically.

**Liveness Probe** — Answers the question: "Is this pod still alive and
functioning?" When a liveness probe fails `failureThreshold` times in a row,
Kubernetes kills and restarts the container. Use this to escape deadlocks or
memory corruption that the app cannot recover from on its own. Be careful: a
liveness probe that is too aggressive (too short `initialDelaySeconds`) will
cause restart loops on startup, which is worse than no probe.

**Startup Probe** — A one-time probe that runs only at startup. While it is
active, liveness and readiness checks are suspended. This is ideal for
applications that take a long time to initialize (e.g., loading a large model
or running database migrations). Set `failureThreshold * periodSeconds` to the
maximum acceptable startup time.

## Next Class Preview
Class 21 introduces Rolling Updates and Horizontal Pod Autoscaling — how to
deploy new versions with zero downtime and automatically scale your pods up and
down based on CPU load.
