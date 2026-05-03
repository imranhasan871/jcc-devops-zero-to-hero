# Class 28 — Network Policies: Zero-Trust Networking

## Objective
Without NetworkPolicies every pod in a Kubernetes cluster can open a TCP connection to every
other pod, in any namespace, on any port. A single compromised container — a misconfigured
nginx, a vulnerable npm dependency with an RCE CVE — can reach your database directly.
NetworkPolicies implement zero-trust networking at the pod level: deny everything by default,
then allow only the exact communication paths your architecture requires.

## Why This Matters in Production
The 2019 Capital One breach was partially enabled by an SSRF vulnerability in a WAF that could
reach the AWS metadata endpoint with no network restrictions. In Kubernetes terms: a pod with
no NetworkPolicy can reach every other pod and every cloud metadata API without restriction.
Zero-trust network segmentation is now an explicit requirement in PCI-DSS 4.0, SOC2 Type II,
and HIPAA audits. Cilium and Calico — the two dominant CNI plugins — both enforce
NetworkPolicies. Without a CNI that implements the enforcement, the objects exist but have no
effect. This silent non-enforcement is one of the most dangerous Kubernetes misconfigurations.

## What You'll Learn
- Why NetworkPolicies require a supporting CNI plugin (Calico, Cilium, Weave — not kubenet)
- How ingress and egress rules are structured and combined
- The critical difference between podSelector and namespaceSelector
- Why default-deny-all is the correct starting point rather than the finishing point
- How to debug blocked traffic using `kubectl exec` and `curl`/`nc`
- How to allow cross-namespace traffic (Prometheus scraping, Ingress controller forwarding)

## What Changed in This Class
- `k8s/network-policies/default-deny-all.yaml` — denies all ingress and egress for every pod in jcc-production
- `k8s/network-policies/allow-frontend-to-backend.yaml` — opens port 3001 from frontend pods only
- `k8s/network-policies/allow-backend-to-db.yaml` — opens port 5432 from backend pods only
- `k8s/network-policies/allow-prometheus-scrape.yaml` — allows monitoring namespace to scrape /metrics
- `k8s/network-policies/allow-ingress-to-frontend.yaml` — allows ingress-nginx namespace to reach frontend
- `Makefile` — added netpol-apply and netpol-verify targets

## Concept Deep Dive

**CNI requirement** — NetworkPolicy objects are plain Kubernetes API resources. They store
your intent but do nothing by themselves. Enforcement is done by the CNI plugin running on
every node. If your cluster uses the default kubenet CNI (common on older setups) or flannel,
NetworkPolicy objects are silently ignored — no error, no warning, no enforcement. Always
verify: apply a deny policy and test that a connection that should be blocked actually times
out. On minikube: `minikube start --cni=calico`. On EKS: use the AWS VPC CNI with Calico, or
deploy Cilium as a replacement CNI.

**podSelector vs namespaceSelector** — A podSelector matches pods by label within the same
namespace as the NetworkPolicy. A namespaceSelector matches all pods in namespaces bearing
that label. When both appear in the same `from` list entry they are ANDed: the source must be
a pod matching the podSelector AND in a namespace matching the namespaceSelector. When they
appear as separate list entries they are ORed: any pod matching either condition is allowed.
Getting this wrong is silent and can result in over-permissive rules that never get caught.

**Default-deny-all as starting point** — The instinct is to start open and add restrictions
later. This is backwards for security: you will always miss something. Start with
default-deny-all, then add explicit allow rules for each path you have intentionally designed.
This forces you to think about every communication dependency before it can receive traffic.
It also makes your network topology self-documenting: the allow policies are a
machine-enforced, version-controlled architecture diagram of your actual traffic flows.

## Hands-On Exercise
1. Verify Calico is running: `kubectl get pods -n kube-system | grep calico`
   (For minikube: `minikube start --cni=calico` first)
2. Apply default-deny first: `kubectl apply -f k8s/network-policies/default-deny-all.yaml`
3. Verify everything is blocked:
   `kubectl exec -it <backend-pod> -n jcc-production -- curl --max-time 3 http://database-service:5432`
   Expected: connection refused or timeout
4. Apply all allow policies: `make netpol-apply`
5. Verify backend can reach DB again with the same curl command
6. List all policies: `kubectl get networkpolicies -n jcc-production`
7. Run `make netpol-verify`

## Common Mistakes
1. **Applying NetworkPolicies on a cluster without an enforcing CNI** — The policies appear
   to succeed (`kubectl apply` exits 0) but no traffic is blocked. Always test enforcement
   explicitly: apply a deny policy and prove a connection that should fail actually fails.
2. **Only specifying `policyTypes: [Ingress]`** — This leaves egress unrestricted. A
   compromised pod can still exfiltrate data outbound, reach cloud metadata endpoints, or
   call external C2 servers. The default-deny-all in this class explicitly blocks both
   Ingress and Egress — always name both types when you mean to restrict both.
3. **AND vs OR confusion in `from` lists** — Two selectors in one `from` entry are ANDed.
   Two separate entries are ORed. `from: [{namespaceSelector: X, podSelector: Y}]` means
   pods matching Y in namespaces matching X. `from: [{namespaceSelector: X}, {podSelector: Y}]`
   means pods in namespaces matching X OR pods matching Y anywhere. The first form is almost
   always what you want for cross-namespace allow rules.

## Next Class Preview
Class 29 covers Pod Disruption Budgets and Priority Classes — preventing surprise outages
during planned node maintenance and ensuring critical workloads survive resource pressure.
