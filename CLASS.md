# Class 16 — K8s Deployment + Service

## Objective
Deploy the JCC backend to a local Kubernetes cluster using a Deployment and a
Service. Understand how K8s ensures replicas stay healthy, and how a Service
provides a stable network address for a dynamic set of pods.

## What You'll Learn
- How to write a Kubernetes `Deployment` manifest
- What `replicas`, `selector`, and `template` mean
- How readiness and liveness probes protect your application
- What a `ClusterIP` Service does and how it selects pods
- How resource requests and limits protect the cluster

## What Changed in This Class
- Added `k8s/backend/deployment.yaml` — 2-replica deployment with health probes and resource limits
- Added `k8s/backend/service.yaml` — ClusterIP Service on port 3000
- Updated `Makefile` with `k8s-apply`, `k8s-status`, and `k8s-logs` targets

## Hands-On Exercise
1. Build the image locally: `make docker-build && docker tag jcc-app jcc-backend:latest`
2. If using minikube: `minikube image load jcc-backend:latest`
3. Apply resources: `make k8s-apply`
4. Watch pods start: `kubectl get pods -n jcc-production -w`
5. Check status: `make k8s-status`
6. Forward a port to test: `kubectl port-forward svc/jcc-backend 3000:3000 -n jcc-production`
7. Visit `http://localhost:3000/health` — traffic is load-balanced across both pods
8. Delete a pod manually: `kubectl delete pod <name> -n jcc-production` — watch K8s recreate it

## Key Concepts

**Deployment vs Pod**
You almost never create a Pod directly in Kubernetes. A raw Pod has no self-
healing: if it crashes or the node it runs on fails, the pod is gone. A
Deployment wraps pods in a `ReplicaSet` that constantly reconciles the actual
count of running pods against the `replicas:` field. Delete a pod and the
Deployment immediately schedules a replacement.

**Readiness vs Liveness Probes**
Both probes call `GET /health` on port 3000, but they serve different purposes:
- **Liveness probe**: "Is this pod alive?" If it fails, K8s *restarts* the
  container. Use it to detect deadlocks or hung processes.
- **Readiness probe**: "Is this pod ready to receive traffic?" If it fails,
  K8s *removes the pod from the Service's load balancer* but does not restart
  it. Use it during startup (before the app finishes connecting to the database)
  and during overload.

**ClusterIP Service**
A `ClusterIP` Service gets a stable virtual IP address inside the cluster.
All pods with the label `app: jcc-backend` are registered as endpoints.
Kubernetes routes requests to healthy, ready endpoints automatically. Because
pods are ephemeral (they get new IPs on restart), the Service's stable IP is
essential — consumers always use the Service address, never pod IPs directly.

## Next Class Preview
In Class 17 we inject configuration into our pods properly using a ConfigMap
(for non-sensitive values) and a Secret (for passwords). We also update the
Deployment to load these resources, and discuss why you should never commit
real secrets to git.
