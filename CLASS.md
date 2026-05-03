# Class 16 — Deploy to Kubernetes (and Fix What's Broken)

## The Scenario
You've just joined the JCC platform team. Your first task: get the backend
running on the staging Kubernetes cluster. A previous engineer left a
`k8s/backend/deployment.yaml` in the repo. You apply it. Every pod enters
`CrashLoopBackOff` or `ImagePullBackOff` within seconds. Your lead says:
"Figure out what's wrong — I'm in meetings all day." There are no Slack threads
to search. You have `kubectl` and nothing else.

## The Problem
The `deployment.yaml` has three bugs. The cluster will tell you exactly what
they are — if you know where to look. Your job is to find all three, fix them,
and deliver a healthy 2-replica deployment with a ClusterIP Service.

## Your Mission
1. Apply the existing broken manifests and observe the failure.
2. Use only `kubectl describe pod` and `kubectl logs` to identify each bug.
   For every bug, record: the exact command you ran, the error message returned,
   and what you changed to fix it.
3. Produce a working `k8s/backend/deployment.yaml` (2 replicas, image
   `jcc-backend:latest`, container port 3000).
4. Produce a working `k8s/backend/service.yaml` (ClusterIP, port 3000,
   correct `selector` targeting your deployment's pods).
5. Both pods must reach `Running 1/1` and pass readiness checks.

## What You Need to Know First
- `kubectl describe pod <name> -n <ns>` — shows events, image pull errors,
  probe failures, exit codes.
- `kubectl logs <pod> -n <ns>` — shows stdout/stderr from the container.
- A pod in `ImagePullBackOff` cannot pull its image; check the image name and
  tag first.
- A pod in `CrashLoopBackOff` starts but exits non-zero; the logs contain the
  reason.
- Container port in the manifest is documentation — but if the Service targets
  the wrong port, health probes and traffic both fail.
- An app that crashes because an env var is missing will say so in its logs.

## Constraints
- Use `kubectl describe pod` and `kubectl logs` only — no external debugging
  tools, no editing YAML by guessing.
- You must document all three bugs in a comment block at the top of your final
  `deployment.yaml` using this format:
  ```
  # Bug 1: <command that revealed it> → <error text> → <fix applied>
  # Bug 2: ...
  # Bug 3: ...
  ```
- The `selector` in `service.yaml` must match the `labels` on the pod template
  exactly — verify with `kubectl get endpoints -n jcc-production`.
- Do not use `imagePullPolicy: Never` as a workaround; the image tag must be
  correct.

## Verification
```bash
kubectl get pods -n jcc-production
# Expected: two pods, STATUS=Running, READY=1/1

kubectl get service -n jcc-production
# Expected: backend-service, TYPE=ClusterIP, PORT(S)=3000/TCP

kubectl get endpoints backend-service -n jcc-production
# Expected: two IP:3000 entries (one per pod)

kubectl port-forward svc/backend-service 3000:3000 -n jcc-production &
sleep 2
curl -s localhost:3000/health
# Expected: {"status":"ok"}
```

## Stretch Challenge
Without editing any YAML file and without deleting the Deployment, change the
replica count from 2 to 4 using a single `kubectl` command. Verify all four
pods reach `Running`. Then scale back to 2. Identify two real-world scenarios
where this imperative scale command is appropriate in production and two where
it would be a bad idea.

## Instructor Notes
**Why this matters.** The three-bug gauntlet — `ImagePullBackOff`, wrong port,
missing env var — covers roughly 80% of production Kubernetes incidents.
Students who reach for YAML edits before reading `kubectl describe` will waste
hours on-call. Muscle memory: observe first, fix second.

**Common wrong approach.** Setting `imagePullPolicy: Never` to skip the pull.
It masks the real skill. The tag must be correct.

**Port mismatch subtlety.** Container port is informational in Kubernetes —
the bug shows up in readiness probe failures and Service endpoints, not as a
pod-level error. Students must connect `kubectl describe` events to the probe.

**Next class link.** A missing env var crashing the app is the controlled
version of the credentials-in-YAML problem covered in class 17.
