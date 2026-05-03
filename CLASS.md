# Class 18 — K8s PersistentVolumeClaim + Database StatefulSet

## Objective
Replace the ephemeral database Deployment with a proper StatefulSet backed by a
PersistentVolumeClaim so that PostgreSQL data survives pod restarts and
rescheduling.

## What You'll Learn
- Why databases must use StatefulSets instead of Deployments
- What PersistentVolumes (PV) and PersistentVolumeClaims (PVC) are and how they differ
- How headless Services give StatefulSet pods stable, predictable DNS names
- How Kubernetes storage classes work and when to specify one

## What Changed in This Class
- Added `k8s/database/pvc.yaml` — a 5 Gi ReadWriteOnce claim for Postgres data
- Added `k8s/database/statefulset.yaml` — replaces the Deployment with a StatefulSet using `postgres:16-alpine`
- Added `k8s/database/service.yaml` — a headless Service for stable DNS plus a regular ClusterIP for app traffic

## Hands-On Exercise
1. Apply the secret first: `kubectl apply -f k8s/ingress/ingress.yaml` (contains the secret)
2. Apply the PVC: `kubectl apply -f k8s/database/pvc.yaml`
3. Apply the StatefulSet and services: `kubectl apply -f k8s/database/`
4. Watch the pod come up: `kubectl get pods -n jcc -w`
5. Verify the PVC is bound: `kubectl get pvc -n jcc`
6. Connect to the pod: `kubectl exec -it postgres-0 -n jcc -- psql -U jcc_user -d jcc_db`
7. Delete the pod and watch it recreate with the same data: `kubectl delete pod postgres-0 -n jcc`

## Key Concepts

**Deployments vs StatefulSets** — A Deployment treats all pods as identical and
interchangeable. When a pod is replaced it gets a new name, a new IP, and
(without a PVC) a fresh empty disk. A StatefulSet gives each pod a stable
identity (`postgres-0`, `postgres-1`) and binds it to its own PVC. This means
pod-0 always reconnects to the same volume even after a node failure.

**PersistentVolumeClaim (PVC) and PersistentVolume (PV)** — A PV is the actual
storage resource (could be an AWS EBS disk, a GCE disk, an NFS share, or a
local path). A PVC is a request for storage: "give me 5 Gi of ReadWriteOnce
storage." Kubernetes matches the claim to a volume. `ReadWriteOnce` means only
one node can mount it at a time — suitable for a single Postgres pod.

**Headless Services** — Setting `clusterIP: None` tells Kubernetes not to
allocate a virtual IP. Instead, DNS queries return the actual pod IPs directly.
For StatefulSets this is how pods get stable, addressable DNS names like
`postgres-0.postgres-headless.jcc.svc.cluster.local`.

## Next Class Preview
Class 19 introduces Kubernetes Ingress — a single entry point that routes
external HTTP traffic to the correct backend or frontend service based on the
URL path, replacing the need for individual NodePort services.
