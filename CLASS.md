# Class 27 — RBAC: Role-Based Access Control

## Objective
By default every pod in Kubernetes runs as the `default` ServiceAccount, which in many cluster
configurations can list, read, or even modify resources across namespaces. RBAC lets you define
exactly what each identity (user, ServiceAccount, CI system) is allowed to do — and deny
everything else. Properly scoped RBAC is the first thing a security auditor checks and the
last thing most teams configure.

## Why This Matters in Production
The 2022 Tesla Kubernetes cluster breach and dozens of crypto-mining attacks exploited the same
vulnerability: a compromised pod with an over-permissioned ServiceAccount. Once an attacker
has code execution inside a pod, they query the Kubernetes API using the mounted token at
`/var/run/secrets/kubernetes.io/serviceaccount/token`. If that token has cluster-admin rights
— a shockingly common misconfiguration shipped in many tutorials — they own the cluster in
minutes. Properly scoped RBAC means a compromised backend pod can read its own ConfigMap and
nothing else. The blast radius of any single pod compromise shrinks to near zero.

## What You'll Learn
- The four RBAC primitives: Subject, Role, ClusterRole, RoleBinding, ClusterRoleBinding
- The difference between Role (namespaced) and ClusterRole (cluster-wide)
- How ServiceAccounts replace human users for workload identity
- How to verify permissions with `kubectl auth can-i` before and after applying policies
- How to audit existing permissions across a namespace
- Common RBAC attack vectors and the misconfiguration patterns that enable them

## What Changed in This Class
- `k8s/rbac/serviceaccount.yaml` — creates the `jcc-backend` identity in jcc-production namespace
- `k8s/rbac/role.yaml` — Role granting read-only access to pods and configmaps only
- `k8s/rbac/rolebinding.yaml` — binds the role to the jcc-backend ServiceAccount
- `k8s/rbac/cicd-role.yaml` — ClusterRole for Jenkins: deploy and watch, nothing more
- `k8s/rbac/cicd-rolebinding.yaml` — binds the CI role to the jenkins ServiceAccount
- `k8s/backend/deployment.yaml` — added `serviceAccountName: jcc-backend`
- `Makefile` — added rbac-apply and rbac-verify targets

## Concept Deep Dive

**Subject / Role / RoleBinding triangle** — Every RBAC policy is three objects. The Subject
is who (a User, Group, or ServiceAccount). The Role defines what actions on what resources are
permitted — nothing is allowed by default. The RoleBinding connects them. You can reuse Roles
across multiple bindings, which is the correct pattern: define roles by job function
(read-only-observer, deployment-operator) and bind them to multiple subjects rather than
creating bespoke roles per team. This makes auditing tractable.

**Role vs ClusterRole scope** — A Role only grants permissions within its own namespace. A
ClusterRole grants permissions cluster-wide, OR can be bound to a specific namespace via a
namespaced RoleBinding (not ClusterRoleBinding). This is a useful pattern: define a ClusterRole
for "read pods" once, then bind it per-namespace via multiple RoleBindings, rather than
duplicating identical Role objects in every namespace. Use ClusterRoleBinding sparingly — it
is cluster-wide and permanent, and it is how most privilege escalations are achieved.

**Principle of least privilege in practice** — Start with no permissions and add only what the
workload demonstrably uses. To discover what an app actually needs: run it, enable API audit
logging, and grep for 403 Forbidden responses. Grant exactly those API groups, resources, and
verbs. Never copy-paste cluster-admin for convenience — it is effectively permanent (tokens
are long-lived) and the breadth of access will surface in every future audit as a finding.

## Hands-On Exercise
1. Apply all RBAC resources: `make rbac-apply`
2. Test allowed actions:
   `kubectl auth can-i get configmaps --as=system:serviceaccount:jcc-production:jcc-backend -n jcc-production`
   Expected output: `yes`
3. Test denied actions:
   `kubectl auth can-i delete pods --as=system:serviceaccount:jcc-production:jcc-backend -n jcc-production`
   Expected output: `no`
4. List all roles in the namespace: `kubectl get roles,rolebindings -n jcc-production`
5. Describe the role to see its rules: `kubectl describe role jcc-backend-role -n jcc-production`
6. Run the full verification suite: `make rbac-verify`

## Common Mistakes
1. **Using `cluster-admin` for CI systems** — Jenkins or GitHub Actions needs to update
   Deployments and read Pod status. cluster-admin additionally lets it delete namespaces, read
   all Secrets cluster-wide, and modify RBAC itself. Create a scoped ClusterRole covering only
   what CI actually does, and re-audit it quarterly as pipelines evolve.
2. **Forgetting `automountServiceAccountToken: false` on pods with no API access** — Every pod
   gets a mounted ServiceAccount token by default, even if the application never calls the
   Kubernetes API. An attacker with shell in that pod gets the token for free. Set
   `automountServiceAccountToken: false` on the ServiceAccount for any workload that has no
   legitimate reason to talk to Kubernetes APIs.
3. **Binding to `system:authenticated`** — This grants permissions to every authenticated
   entity in the cluster, including all ServiceAccounts everywhere. Students do this to
   "make it work quickly" when troubleshooting permissions. It is silent, broad, and never
   gets cleaned up. Always specify exact subjects by name.

## Next Class Preview
Class 28 adds NetworkPolicies — because RBAC controls the Kubernetes API, but without network
policies every pod can still open a TCP connection directly to every other pod.
