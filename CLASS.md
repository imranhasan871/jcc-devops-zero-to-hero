# Class 19 — Stop Running kubectl port-forward in a Screen Session

## The Scenario
The QA team has been testing the JCC app for two weeks using a URL the ops
team provides every morning: `http://localhost:PORT`. To get that URL, an ops
engineer runs `kubectl port-forward` inside a `screen` session on a shared
bastion host. It has broken four times: once when the bastion rebooted, once
when the pod restarted (the port-forward dies with the pod), and twice when
no one noticed the screen session had exited. The QA team lead has escalated:
"We cannot test reliably. Give us a stable URL." External traffic has no
production-grade entry point into the cluster.

## The Problem
`kubectl port-forward` is a development tool. It forwards to a specific pod —
not the Service — and dies when the pod dies. The cluster has no mechanism to
accept and route external HTTP traffic to the correct backend or frontend
service.

## Your Mission
1. Enable the Nginx Ingress Controller in your minikube cluster.
2. Write a `k8s/ingress/ingress.yaml` resource that routes:
   - `jcc.local/api/*` → `backend-service` port 3000
   - `jcc.local/*` (all other paths) → `frontend-service` port 80
3. Verify that `curl -H "Host: jcc.local" http://$(minikube ip)/api/programs`
   returns the programs JSON array with zero `kubectl port-forward` processes
   running.
4. Add a comparison table to your `k8s/ingress/README.md` covering NodePort,
   LoadBalancer, and Ingress: what each is, when to use it, and its production
   cost/limitation.
5. The path rewrite annotation must be correct: `/api/programs` must arrive at
   the backend as `/api/programs`, not as `/programs`.

## What You Need to Know First
- An Ingress resource is not functional without an Ingress Controller — the
  resource is just configuration; the controller is the running proxy.
- `minikube addons enable ingress` installs the Nginx Ingress Controller.
- `nginx.ingress.kubernetes.io/rewrite-target` controls path rewriting. Using
  `/$1` with a capture group in the path regex will strip the prefix. Not using
  it leaves the path intact — know the difference.
- The Ingress `host` field is matched against the HTTP `Host` header, not the
  IP address.
- `kubectl get ingress -n jcc-production` shows the assigned address. An empty
  address means the controller has not processed the resource yet.

## Constraints
- No `kubectl port-forward` may be running during your verification step.
  Prove this with `ps aux | grep port-forward | grep -v grep` returning empty.
- Before writing any YAML, produce the comparison table (NodePort vs
  LoadBalancer vs Ingress). It must include: mechanism, when to use, production
  cost, and one limitation of each. Put it in `k8s/ingress/README.md`.
- The Ingress annotation for path rewriting must be explained with a comment
  in the YAML: state what happens to the path with and without the annotation.
- Both routes (`/api/*` and `/*`) must be verified independently with `curl`.

## Verification
```bash
# No port-forward running
ps aux | grep port-forward | grep -v grep
# Expected: no output

minikube addons enable ingress
kubectl apply -f k8s/ingress/

# Wait for address assignment (up to 90 seconds)
kubectl get ingress -n jcc-production -w

curl -H "Host: jcc.local" http://$(minikube ip)/api/programs
# Expected: JSON array (not 404, not 503)

curl -H "Host: jcc.local" http://$(minikube ip)/health
# Expected: {"status":"ok"}

curl -H "Host: jcc.local" http://$(minikube ip)/api/programs -v 2>&1 | grep "< HTTP"
# Expected: HTTP/1.1 200
```

## Stretch Challenge
The Ingress has no TLS. Without applying it to the cluster, write the complete
`cert-manager` `Certificate` resource and the updated Ingress `tls:` section
that would add HTTPS to `jcc.local` using a self-signed `ClusterIssuer`. Add
accurate comments explaining what cert-manager does automatically (certificate
renewal, Secret creation) and what you would need to change to use Let's
Encrypt instead of a self-signed issuer.

## Instructor Notes
**Why this matters.** `kubectl port-forward` in production is a red flag in
any architecture review. The path-rewrite subtlety — stripping vs preserving
the prefix — is a real source of production 404s. Getting it wrong here makes
it unforgettable.

**Common wrong approach.** NodePort and calling it done. NodePort has no
host-based or path routing, and in cloud environments means a separate load
balancer per Service. The comparison table forces students to articulate why
Ingress exists before writing YAML.

**Rewrite annotation.** `nginx.ingress.kubernetes.io/rewrite-target: /$1`
with `path: /api(/|$)(.*)` strips the `/api` prefix. Without the capture
group, the full path reaches the backend. Both work — the backend must expect
whichever format you choose.
