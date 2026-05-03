# Class 18 — Your Database Just Lost All Its Data

## The Scenario
It is 3pm on a Thursday. A junior developer runs `kubectl delete pod db-7f9c2`
to force a restart after a slow query. The pod comes back in 45 seconds.
But every API call that touches the database now returns 500. The database is
empty. Three weeks of QA data is gone. Post-mortem finding: the database was
running as a Deployment, storing data in the container's ephemeral filesystem.
When the pod was deleted, the filesystem was deleted with it. There was no
PersistentVolume. There were no backups.

## The Problem
A database that loses all data when its pod restarts is not a database — it is
a stateful process pretending to be stateless. The root cause: using a
`Deployment` for a workload that requires stable, persistent, named storage.

## Your Mission
1. Remove (or replace) the database `Deployment` with a `StatefulSet` named
   `database` in namespace `jcc-production`.
2. The StatefulSet must declare a `volumeClaimTemplate` that provisions a
   `PersistentVolumeClaim` with `ReadWriteOnce` access mode and at least 1Gi
   of storage.
3. Mount the volume at the database data directory (e.g. `/var/lib/postgresql/data`
   for Postgres).
4. Prove persistence: insert a test record, delete pod `database-0`, wait for
   it to return to `Running`, and verify the record is still there.
5. Add a `headless Service` (`clusterIP: None`) named `database` so that the
   StatefulSet pods get stable DNS names (`database-0.database.jcc-production`).

## What You Need to Know First
- A StatefulSet gives each pod a stable ordinal name (`database-0`, `database-1`).
- `volumeClaimTemplate` causes each pod to get its own PVC — the PVC is NOT
  deleted when the pod is deleted.
- `ReadWriteOnce` means the volume can be mounted read-write by exactly one
  node at a time — this limits Postgres to a single writable replica unless you
  use operator-managed replication.
- A headless Service (`clusterIP: None`) enables DNS-based pod discovery;
  without it, pods get random IP-based DNS only.
- `kubectl delete pod` deletes the pod object — the PVC remains. `kubectl
  delete pvc` deletes the storage claim — and may destroy data depending on
  the reclaim policy.

## Constraints
- You may not use `hostPath` volumes — they are node-local and non-portable.
- The `volumeClaimTemplate` must be inline in the StatefulSet manifest, not a
  standalone PVC resource. Explain in a comment why: standalone PVCs are not
  managed by the StatefulSet lifecycle.
- Add a comment block in your StatefulSet manifest explaining:
  (a) why a StatefulSet is required for a database rather than a Deployment,
  (b) what `ReadWriteOnce` means for multi-replica databases, and
  (c) what happens if you `kubectl delete pvc` the data volume.

## Verification
```bash
# Insert a record before deleting the pod
kubectl exec -n jcc-production statefulset/database -- \
  psql -U jcc_user -d jcc_db -c "INSERT INTO programs(name) VALUES('test-persistence');"

# Delete the pod (NOT the StatefulSet, NOT the PVC)
kubectl delete pod -n jcc-production database-0

# Wait for the StatefulSet controller to restart it
kubectl wait --for=condition=Ready pod/database-0 -n jcc-production --timeout=60s

# Verify the record survived the pod deletion
kubectl exec -n jcc-production statefulset/database -- \
  psql -U jcc_user -d jcc_db -c "SELECT name FROM programs WHERE name='test-persistence';"
# Expected: 1 row returned

# Verify the PVC was retained
kubectl get pvc -n jcc-production
# Expected: PVC in Bound state
```

## Stretch Challenge
What is the difference between `kubectl delete pod database-0` and
`kubectl delete pvc <claim-name>`? Try deleting the PVC while the pod is
running — what does Kubernetes do? What does the `Retain` reclaim policy on a
PersistentVolume do, and in what disaster-recovery scenario would you use it
instead of `Delete`?

## Instructor Notes
**Why this scenario.** Ephemeral database pods are a recurring mistake from
engineers new to Kubernetes. "Your data is gone" lands harder than any
diagram. The StatefulSet concept sticks because the failure is visceral.

**Common wrong approach.** Deployment + standalone PVC via `volumes` +
`volumeMounts`. Works for one pod — fails at 2 replicas: both pods try to
mount the same `ReadWriteOnce` volume; one stays `Pending`. `volumeClaimTemplate`
gives each pod its own PVC and is the correct pattern.

**ReadWriteOnce opens the right question.** "Why can't I run two Postgres
replicas?" is the entry point to streaming replication, primary/replica
topology, and `ReadWriteMany` — topics for a later class.
