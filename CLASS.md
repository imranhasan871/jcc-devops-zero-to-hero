# Class 29 — Pod Disruption Budgets + Priority Classes

## Objective
RBAC and NetworkPolicies protect you from attackers. PodDisruptionBudgets and PriorityClasses
protect you from yourself — specifically from cluster operations (node drains, Kubernetes
version upgrades, node pool replacements) and resource contention silently taking down
production. These two primitives are the difference between a controlled maintenance window
and a 3am incident page.

## Why This Matters in Production
The most common Kubernetes-related outage story: an engineer runs `kubectl drain node-3` to
replace the underlying EC2 instance. Kubernetes obediently evicts all pods on that node. If
both backend replicas happened to be scheduled on node-3, the app goes completely down for the
30–90 seconds it takes the replacement pods to start. With a PodDisruptionBudget set to
`minAvailable: 1`, the drain blocks after evicting the first pod, outputs
"Cannot evict pod as it would violate the pod's disruption budget," and waits for a
replacement pod to reach Ready state on another node before evicting the second. Zero
downtime. Same drain operation, completely different outcome.

## What You'll Learn
- The difference between voluntary and involuntary disruptions
- How node drain negotiates with PodDisruptionBudgets step by step
- How PriorityClass affects scheduling and eviction when cluster resources are exhausted
- How ResourceQuota prevents one namespace from starving others in a shared cluster
- The traps: minAvailable == replicas, and ResourceQuota requiring explicit resource requests

## What Changed in This Class
- `k8s/reliability/pdb-backend.yaml` — PDB ensuring at least 1 backend pod survives any voluntary drain
- `k8s/reliability/pdb-database.yaml` — PDB protecting the PostgreSQL pod from concurrent eviction
- `k8s/reliability/priority-classes.yaml` — jcc-critical (1000) and jcc-standard (100) PriorityClasses
- `k8s/reliability/resource-quota.yaml` — hard namespace-level limits on pods, CPU, memory, and PVCs
- `k8s/backend/deployment.yaml` — added `priorityClassName: jcc-critical`
- `Makefile` — added reliability-apply and reliability-status targets

## Concept Deep Dive

**Voluntary vs Involuntary disruptions** — A voluntary disruption is one a human or controller
initiates: `kubectl drain`, a managed node group rolling update, a Cluster Autoscaler
scale-down, a Deployment rollout, a manual pod delete. Kubernetes honours PodDisruptionBudgets
for voluntary disruptions — it will delay the operation until the budget permits. An
involuntary disruption is hardware failure, OOM kill, or node crash — Kubernetes cannot
negotiate these, so PDBs do not apply. For involuntary protection you need replicas spread
across availability zones using pod anti-affinity rules and topology spread constraints.

**PriorityClass under resource pressure** — When a new pod cannot be scheduled because the
cluster has insufficient free resources, the Kubernetes scheduler looks for running pods it can
preempt (evict) to make room. Pods with PriorityClass value 1000 will displace pods with value
100. This mechanism ensures your production backend always gets scheduled even when a developer
has left a 50-replica load-testing job running. Without PriorityClasses all pods compete
equally — first-come, first-served — which works fine until it doesn't.

**ResourceQuota as a safety net** — ResourceQuota adds hard ceilings on the entire namespace.
A `kubectl scale deployment backend --replicas=1000` is rejected when the `pods: 20` quota is
hit. A deployment that sets `limits.memory: 32Gi` per pod is rejected against the namespace
memory quota. This is correct: the quota is the last line of defence against misconfigurations
that would exhaust shared cluster capacity. It requires that every pod in the namespace has
explicit resource requests and limits — which is itself a healthy forcing function.

## Hands-On Exercise
1. Apply reliability resources: `make reliability-apply`
2. Check PDB status: `kubectl get pdb -n jcc-production`
   Expected: `ALLOWED DISRUPTIONS: 1` for the backend PDB (with 2 replicas)
3. Simulate controlled drain: `kubectl drain <node> --ignore-daemonsets --delete-emptydir-data`
   Observe: it evicts pod 1, waits for replacement, then evicts pod 2
4. Check quota usage: `kubectl describe resourcequota jcc-production-quota -n jcc-production`
5. Try to exceed quota: `kubectl scale deployment backend --replicas=25 -n jcc-production`
   Expected: `Error from server (Forbidden): exceeded quota`
6. Check priority classes: `kubectl get priorityclasses`

## Common Mistakes
1. **Setting `minAvailable` equal to `replicaCount`** — If `minAvailable: 2` and you have
   2 replicas, zero pods can ever be voluntarily evicted. Node drains block indefinitely with
   no progress. Set minAvailable to `replicas - 1`, or use `maxUnavailable: 1` instead.
   Always leave room for at least one voluntary disruption.
2. **Applying PDBs to single-replica Deployments** — A PDB with `minAvailable: 1` on a
   Deployment with `replicas: 1` means no pods can ever be evicted voluntarily. Maintenance
   operations block forever. Scale to at least 2 replicas before adding a PDB, or accept that
   single-replica workloads will have maintenance downtime.
3. **Applying ResourceQuota without setting resource requests on existing pods** — Once a
   quota with CPU/memory limits is applied, any pod without explicit `resources.requests` is
   rejected by the admission controller. If you have existing pods without requests defined,
   apply the quota and then update all Deployments — in that order — or the Deployments will
   fail to create new pods during the next rollout.

## Next Class Preview
Class 30 addresses Kubernetes Secrets directly: base64 is not encryption, and this class
establishes a proper secrets management pipeline using External Secrets Operator.
