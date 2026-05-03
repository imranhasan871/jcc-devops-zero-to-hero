# Class 21 — Zero-Downtime Deployments and Rollback Under Pressure

## The Scenario

It is 14:07 on a Friday. Marketing just announced a product launch for 16:00.
You need to deploy the new version of the JCC backend before the demo goes live.
Last month, the same deployment pattern (`kubectl set image` with the default
`Recreate` strategy) killed every pod simultaneously — 30 seconds of downtime
in front of 800 live viewers. Last week a bad image tag took production down for
two hours before someone found the right `kubectl` command to roll back manually.
Your manager is watching. The clock is running.

## The Problem

The current deployment has no rollout strategy defined, which means Kubernetes
uses `Recreate` by default: all old pods die before any new pod starts. There is
no rollback automation. If the new image is broken, someone must manually find
the right revision number and run the correct command — under pressure, at 2am,
after being paged out of bed. Additionally, traffic spikes during launches mean
the two static replicas are never enough, but nobody wants to manually scale
every time.

## Your Mission

- Configure the `backend` Deployment with a `RollingUpdate` strategy so that
  `maxUnavailable: 0` and `maxSurge: 1` at all times.
- Deploy a deliberately broken image (`jcc-app:doesnotexist`) and prove that
  the rolling update stalls while the old pods continue serving traffic — zero
  requests may fail during the stalled rollout.
- Roll back the stalled deployment using a single command without manually
  deleting any pods.
- Configure a `HorizontalPodAutoscaler` for the backend that maintains a minimum
  of 2 replicas and scales up to 5 when average CPU exceeds 70%.
- The rollout history must show at least two revisions after the exercise.

## What You Need to Know First

- The difference between `Recreate` and `RollingUpdate` deployment strategies
  and what each guarantees.
- What `maxUnavailable` and `maxSurge` mean in terms of live pod counts during a
  rollout.
- How Kubernetes decides a pod is "ready" (readiness probes) and how that gates
  the rolling update progression.
- The `kubectl rollout` subcommands: `status`, `history`, `undo`, `pause`,
  `resume`.
- What a `HorizontalPodAutoscaler` requires from the cluster (metrics-server
  must be running).

## Constraints

- You may NOT use `kubectl delete pod` or any manual pod deletion to trigger or
  resolve a rollout state — the strategy and rollback command must do the work.
- While deploying the broken image, you must run the following health-check loop
  in a separate terminal for the duration of the test. Zero output lines may be
  missing (every `sleep 1` interval must produce a response):
  ```
  while true; do curl -sf http://jcc.local/health | grep ok; sleep 1; done
  ```
- The `HorizontalPodAutoscaler` must be defined in a YAML manifest and applied
  with `kubectl apply` — not created with `kubectl autoscale`.
- Credentials, kubeconfig paths, and namespace names must not be hardcoded in
  any shared file — use environment variables or Kubernetes Secrets.

## Verification

```bash
# 1. Confirm the rollout strategy is set correctly
kubectl get deployment backend -n jcc-production -o jsonpath=\
  '{.spec.strategy.type} maxUnavailable={.spec.strategy.rollingUpdate.maxUnavailable} maxSurge={.spec.strategy.rollingUpdate.maxSurge}'
# Expected output: RollingUpdate maxUnavailable=0 maxSurge=1

# 2. Deploy a working image — must complete cleanly
kubectl set image deployment/backend backend=jcc-app:good -n jcc-production
kubectl rollout status deployment/backend -n jcc-production
# Expected: successfully rolled out

# 3. Deploy a broken image — must stall, NOT terminate old pods
kubectl set image deployment/backend backend=jcc-app:doesnotexist -n jcc-production
kubectl rollout status deployment/backend -n jcc-production --timeout=60s || true
kubectl get pods -n jcc-production
# Expected: old pods still Running, new pod stuck in ImagePullBackOff or Pending

# 4. Roll back in one command
kubectl rollout undo deployment/backend -n jcc-production
kubectl rollout status deployment/backend -n jcc-production
# Expected: successfully rolled out

# 5. Confirm history shows at least two revisions
kubectl rollout history deployment/backend -n jcc-production
# Expected: REVISION column shows 1, 2, 3 (or more)

# 6. Confirm HPA is active
kubectl get hpa backend-hpa -n jcc-production
# Expected: MINPODS=2 MAXPODS=5 TARGET=70%
```

## Stretch Challenge

Configure a `PodDisruptionBudget` (PDB) that guarantees at least one backend
pod is always available during voluntary disruptions such as node maintenance.
Then simulate a node drain:

```bash
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
```

Show that the PDB blocks the drain from evicting the last running pod.
Explain in a comment in the PDB manifest: what is the difference between
`minAvailable` and `maxUnavailable` in a PDB, and why the distinction matters
when you have exactly two replicas.

## Instructor Notes

Students frequently set `maxUnavailable: 1` thinking it is "safe" — walk them
through the math: with 2 replicas and `maxUnavailable: 1`, Kubernetes is allowed
to kill one pod before the new one is healthy. That is exactly one pod serving
traffic during the rollout window. For user-facing services with no redundancy at
the load balancer layer, that is effectively downtime under load. The only
guarantee of zero downtime at the pod level is `maxUnavailable: 0`.

The HPA exercise often fails silently because `metrics-server` is not installed.
If `kubectl get hpa` shows `<unknown>` for CPU, that is the diagnosis.
On minikube: `minikube addons enable metrics-server`.

The PDB stretch is deliberately paired with the rolling update lesson because
students often configure PDBs and RollingUpdate strategies independently without
understanding that they interact: a PDB can prevent a rollout from progressing if
it would violate the budget. This is a common production incident cause.
