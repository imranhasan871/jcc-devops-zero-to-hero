# Class 20 — 2am Alert: Pods Running, App Returning 503

## The Scenario
2:07am PagerDuty: "HTTP error rate > 20%." Every pod is `Running 1/1`. Nothing
is crashing. But every request returns `503`. Timeline: deployment rolled out
at 1:52am. Pods were marked `Ready` within 5 seconds. The backend needs 15–20
seconds to warm up its database connection pool. Kubernetes sent traffic
immediately. Every request during warmup hit an app that was alive but not ready.

Three days later: the app stopped responding at 4pm but no pod restarted. A
memory leak caused the process to spin — HTTP stopped accepting connections, but
the process was still running. Kubernetes routed traffic to it for 28 minutes.

## The Problem
There are two distinct failure modes. The first: pods receive traffic before
they are genuinely ready (startup gap). The second: pods become unresponsive
without crashing and are never removed from the load balancer (liveness gap).
Kubernetes has purpose-built probes for both. They are not configured.

## Your Mission
1. Add a `startupProbe` giving the app ≥ 60 seconds to finish startup before
   liveness or readiness probes begin.
2. Add a `readinessProbe` that pulls the pod from the Service endpoint list on
   failure — without restarting it.
3. Add a `livenessProbe` that restarts the pod only after it has been
   unresponsive for > 2 minutes (no flapping on transient slowness).
4. Every threshold value (`failureThreshold`, `periodSeconds`,
   `initialDelaySeconds`) must have an inline YAML comment stating why.
5. Add a section below Instructor Notes explaining why liveness and readiness
   must NOT share identical thresholds — use the 2am scenario as your example.

## What You Need to Know First
- `startupProbe`: runs first; disables liveness and readiness until it succeeds.
  Use `failureThreshold * periodSeconds` to set the max startup budget.
- `readinessProbe`: if it fails, the pod is removed from Service endpoints —
  traffic stops, but the pod is NOT restarted. Use for warmup and transient
  degradation.
- `livenessProbe`: if it fails beyond `failureThreshold`, the pod is killed and
  restarted. Use only for true unresponsiveness, not for slowness.
- Setting liveness and readiness identically means: any momentary slowness
  restarts the pod instead of just pulling it from the load balancer —
  amplifying load during degraded states (restart storms).
- `kubectl describe pod` → `Events` section shows probe failure events and
  the `Killing` event before a restart.

## Constraints
- Liveness `failureThreshold * periodSeconds` must be ≥ 120 seconds (matches
  the 2-minute SLA in the scenario).
- Readiness must use a lower threshold than liveness — it must pull traffic
  faster than it kills the pod.
- You may NOT set `livenessProbe` and `readinessProbe` to identical parameters.
  CI will catch this: `diff <(yq .livenessProbe ...) <(yq .readinessProbe ...)`
  must show differences.
- The startup probe budget must be ≥ 60 seconds total (to cover the 20-second
  worst-case warmup with margin).

## Verification
```bash
# Apply updated deployment
kubectl apply -f k8s/backend/deployment.yaml -n jcc-production

# Watch the pod lifecycle — it must stay NotReady during warmup, then flip Ready
kubectl get pods -n jcc-production -w
# Expected: pod starts, stays 0/1 for the warmup window, then becomes 1/1

# Simulate an unresponsive process (pause PID 1 inside the container)
POD=$(kubectl get pod -n jcc-production -l app=backend -o name | head -1)
kubectl exec -n jcc-production "$POD" -- kill -STOP 1

# Watch for liveness failures and restart event (may take up to 2 minutes)
kubectl describe pod -n jcc-production "${POD#pod/}" | grep -A8 "Liveness"
# Expected: probe failure events, then a Killing/Restarting event

kubectl get pod -n jcc-production "${POD#pod/}"
# Expected: RESTARTS count has incremented
```

## Stretch Challenge
Read the Kubernetes documentation on `terminationGracePeriodSeconds` and the
`preStop` lifecycle hook. Answer: when Kubernetes sends `SIGTERM` to a pod
being terminated (e.g., during a rolling update), what happens to in-flight
HTTP requests that are mid-response? Write a `preStop` hook for the backend
container that adds a 10-second delay before shutdown, and explain in a comment
why this allows the load balancer to drain connections before the process exits.
Set `terminationGracePeriodSeconds` appropriately so it does not conflict with
the hook delay.

## Instructor Notes
**Both incidents are probe misconfiguration, not app bugs.** The app behaved
correctly — it needed warmup time and genuinely stopped responding. Probe
parameters must be tuned to the application's known startup and failure
characteristics; they are not boilerplate.

**Liveness/readiness conflation.** The most common probe mistake in production.
Identical thresholds mean any transient slowness triggers a restart — under
load this creates a restart storm. Readiness should be aggressive (pull
traffic fast); liveness conservative (kill only when there is no recovery).

**Why a startup probe.** Without it, a liveness probe active at t=0 kills the
pod before initialization completes. A large `initialDelaySeconds` on liveness
is the wrong fix — it delays detection of a stuck startup. The startup probe
gates all other probes behind a bounded budget.
