# Class 30 — Helm Secrets + External Secrets Operator

## Objective
Kubernetes Secrets are not secret — they are base64-encoded YAML objects stored in etcd.
Any cluster user with read access can decode them instantly, and any developer who commits a
Secrets YAML file to Git has effectively made that credential permanent. This class establishes
a proper secrets management pipeline using External Secrets Operator to sync real credentials
from a dedicated secret store into Kubernetes Secrets automatically and continuously.

## Why This Matters in Production
In 2021 researchers scanning public GitHub repositories found over 100,000 credentials
committed as base64-encoded Kubernetes Secret manifests. Once a secret enters Git history,
rotation does not help — the old value exists in every clone of the repository forever.
The standard that SOC2, PCI-DSS, and ISO 27001 auditors look for: secrets must reside in a
dedicated secrets manager with access logging, audit trails, rotation support, and encryption
at rest. ESO bridges that world with Kubernetes, creating native Secrets automatically from
a source of truth that is never committed to Git.

## What You'll Learn
- Exactly why base64 is encoding and not encryption, and the practical attack implication
- The 5 patterns for Kubernetes secrets management and the tradeoffs of each
- How External Secrets Operator separates WHERE secrets live from WHAT the app needs
- How to structure Helm values files so no secret value ever appears in source control
- How ESO's `refreshInterval` enables zero-touch automatic secret rotation
- Why `creationPolicy: Owner` matters for secret lifecycle management during teardown

## What Changed in This Class
- `k8s/external-secrets/secret-store.yaml` — SecretStore declaring the backend (fake provider for demo)
- `k8s/external-secrets/external-secret.yaml` — ExternalSecret syncing DB credentials into a native K8s Secret
- `helm/jcc-chart/values-production.yaml` — production Helm overrides with no secret values, only references
- `helm/jcc-chart/values-dev.yaml` — dev overrides with reduced resources
- `docs/secrets-management.md` — reference guide covering all 5 secrets patterns
- `Makefile` — added secrets-validate target

## Concept Deep Dive

**Base64 vs encryption** — base64 is a reversible encoding scheme that requires no key. It
exists to make binary data safe for transport in text protocols (email, HTTP headers). It
provides zero confidentiality. `echo "dGVzdA==" | base64 -d` outputs `test` on any machine
in milliseconds with no key or password needed. The confusion arises because `kubectl get
secret` displays base64 strings instead of plaintext, which superficially resembles
obfuscation. It is not. etcd can be configured with encryption at rest (AES-CBC, AES-GCM)
which protects the data files on disk — but that is a cluster-level concern entirely separate
from the Secret object's encoding, and it does nothing to prevent API-level reads.

**SecretStore vs ExternalSecret separation** — ESO separates the WHERE (SecretStore: which
cloud account, which IAM role, which path prefix) from the WHAT (ExternalSecret: which
specific keys, what to name them in Kubernetes). Platform teams own SecretStore objects — they
configure authentication to AWS, Vault, or GCP. Application teams own ExternalSecret objects
— they declare which keys their app needs without ever seeing the credentials to the secrets
backend itself. This is clean separation of concerns and maps well to team-level RBAC on the
ExternalSecret CRD.

**Rotation and refreshInterval** — With `refreshInterval: 1h`, ESO re-reads the secret from
the backend every hour. Rotate a database password in AWS Secrets Manager and the Kubernetes
Secret is updated within the hour automatically — no CI pipeline, no manual kubectl, no
incident. For zero-downtime rotation: update the credential in the backend while the old one
still works, wait for ESO refresh, then invalidate the old credential. Applications that load
secrets at startup (rather than on every request) also need a pod restart after the K8s Secret
updates — consider using a secret reloader sidecar or a rolling restart in your rotation runbook.

## Hands-On Exercise
1. Install ESO: `helm repo add external-secrets https://charts.external-secrets.io && helm install external-secrets external-secrets/external-secrets -n external-secrets --create-namespace`
2. Apply the SecretStore: `kubectl apply -f k8s/external-secrets/secret-store.yaml`
3. Apply the ExternalSecret: `kubectl apply -f k8s/external-secrets/external-secret.yaml`
4. Watch ESO sync: `kubectl get externalsecret -n jcc-production -w`
   Expected: STATUS transitions from InProgress to Ready
5. Verify the K8s Secret was created: `kubectl get secret jcc-db-secret -n jcc-production`
6. Decode a value to confirm: `kubectl get secret jcc-db-secret -n jcc-production -o jsonpath='{.data.db-password}' | base64 -d`
7. Check status: `make secrets-validate`

## Common Mistakes
1. **Putting image pull secrets or TLS certificates in values files** — Any file under the
   Helm chart directory is a candidate for accidental Git commits. Even with a `.gitignore`
   entry, values files get staged by overeager `git add .`. Use ESO or CI `--set` injection
   for all credential material, treating values files as purely structural configuration.
2. **Setting refreshInterval too low** — A 1-minute refresh interval on a SecretStore calling
   AWS Secrets Manager means thousands of API calls per day across a fleet. At scale this
   exhausts API rate limits and generates meaningful cost. Use 1h for stable secrets; reduce
   only for credentials being actively rotated on a tight schedule.
3. **Not accounting for `creationPolicy: Owner` during teardown** — Deleting an ExternalSecret
   object immediately deletes the K8s Secret it owns. Any Deployment referencing that secret
   will fail to create new pods (missing secret mount). This is correct lifecycle behavior —
   be aware of it when tearing down namespaces and sequence the deletion: Deployments first,
   then ExternalSecrets.

## Next Class Preview
Class 31 moves up the stack to Terraform — provisioning the actual cloud infrastructure
(VPC, RDS, security groups) as version-controlled code rather than console clicks.
