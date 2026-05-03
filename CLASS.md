# Class 19 — K8s Ingress + Full Routing

## Objective
Expose the entire JCC application through a single external entry point using
a Kubernetes Ingress resource, routing traffic to the correct service based on
the URL path.

## What You'll Learn
- The difference between NodePort, LoadBalancer, and Ingress
- How the NGINX Ingress Controller processes Ingress rules
- Path-based routing with regex rewriting
- How to set up local DNS for minikube development

## What Changed in This Class
- Updated `k8s/ingress/ingress.yaml` — routes `jcc.local/api/*` to the backend and `/` to the frontend
- Added `k8s/ingress/ingress-controller.yaml` — instructions for installing the NGINX ingress controller
- Updated `Makefile` with `k8s-ingress-enable`, `k8s-ingress-apply`, and `k8s-ingress-status` targets

## Hands-On Exercise
1. Enable the ingress addon: `make k8s-ingress-enable`
2. Get the minikube IP: `minikube ip`
3. Add `<minikube-ip>  jcc.local` to `/etc/hosts`
4. Apply the ingress rule: `make k8s-ingress-apply`
5. Check the ingress: `make k8s-ingress-status`
6. Open `http://jcc.local` in your browser — you should see the frontend
7. Test the API: `curl http://jcc.local/api/applicants`

## Key Concepts

**NodePort vs LoadBalancer vs Ingress** — NodePort exposes a service on a static
port on every node (e.g., `30080`). It works but gives every service its own
port, which is unmanageable. LoadBalancer provisions a cloud load balancer per
service — expensive when you have many services. Ingress is a single L7 (HTTP)
load balancer that routes to many services based on hostname and path. One
external IP, many services.

**NGINX Ingress Controller** — Kubernetes itself only defines the Ingress API.
The actual routing is done by an Ingress Controller — a pod running NGINX that
watches for Ingress resources and dynamically updates its configuration. When
you apply `ingress.yaml`, the controller reads it and generates an NGINX config
that proxies the right paths to the right ClusterIP services.

**Path Rewriting** — The annotation `rewrite-target: /$2` strips the `/api`
prefix before forwarding to the backend. Without this, the backend would
receive requests as `/api/applicants` instead of `/applicants`. The `$2` capture
group in the regex `(/api)(/|$)(.*)` captures everything after `/api`.

## Next Class Preview
Class 20 dives into Liveness and Readiness probes — the Kubernetes mechanism
that determines whether your pod is healthy and ready to accept traffic,
enabling true zero-downtime deployments.
