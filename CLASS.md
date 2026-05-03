# Class 17 — Kill the Hardcoded Credentials

## The Scenario
The security team's automated scanner flagged `k8s/backend/deployment.yaml`
at 9am this morning. The database password is committed in plaintext to the
repository. It has been there for two weeks. The finding is classified P1:
"Secret material in version control — remediate within 24 hours." Meanwhile,
the ops team maintains two copies of the deployment manifest — one for dev, one
for production — that differ only in four environment variable values. Any
change to either environment requires editing both files manually. Last week
they diverged. Prod broke.

## The Problem
All configuration is hardcoded in `deployment.yaml`. Sensitive values live in
Git. Non-sensitive values are duplicated across environments. There is no clean
separation between what changes per environment and what is actually secret.

## Your Mission
1. Create a `ConfigMap` named `jcc-config` in namespace `jcc-production`
   containing exactly five non-sensitive keys: `NODE_ENV`, `DB_HOST`, `DB_PORT`,
   `DB_NAME`, `PORT`.
2. Create a `Secret` named `jcc-db-secret` in namespace `jcc-production`
   containing exactly two keys: `DB_PASSWORD` and `DB_USER`. The values in
   `k8s/backend/secret.yaml` committed to this repo must be placeholder text
   only — never real credentials.
3. Update `deployment.yaml` so that every environment variable is sourced from
   either the ConfigMap or the Secret. Zero literal `value:` entries allowed
   for any of the seven keys above.
4. The deployment must continue to run — both pods `Running 1/1` after applying
   the updated manifests.
5. Add a comment in `deployment.yaml` explaining why the ConfigMap must be
   applied before the Deployment (and what happens at runtime if it is not).

## What You Need to Know First
- `envFrom` + `configMapRef` injects all keys from a ConfigMap as env vars.
- `valueFrom.secretKeyRef` injects a single key from a Secret.
- Kubernetes Secrets are base64-encoded, not encrypted at rest (unless your
  cluster has envelope encryption enabled).
- `kubectl create configmap` and `kubectl create secret generic` can generate
  manifests with `--dry-run=client -o yaml` for review before applying.
- Apply order: ConfigMaps and Secrets must exist before Pods that reference
  them; the Pod will fail to start with `CreateContainerConfigError` otherwise.

## Constraints
- After your change, this command must return no output:
  ```bash
  grep -rE "changeme|password123|secret[[:space:]]*:" k8s/backend/deployment.yaml
  ```
- `secret.yaml` must be committed with placeholder values (e.g., `PLACEHOLDER`
  or `changeme`) — document in a comment that real values are applied via CI
  from a secrets manager, never committed.
- You must answer in CLASS.md (below the Instructor Notes) the following
  question: if an attacker already has `kubectl get secrets` RBAC access to the
  namespace, does a Kubernetes Secret protect the data? What should you use
  instead in a production cluster handling PII?

## Verification
```bash
kubectl get configmap jcc-config -n jcc-production -o yaml
# Must show all 5 keys: NODE_ENV, DB_HOST, DB_PORT, DB_NAME, PORT

kubectl get secret jcc-db-secret -n jcc-production -o jsonpath='{.data.DB_PASSWORD}' | base64 -d
# Must NOT print a real password (must print the placeholder)

kubectl exec -n jcc-production deploy/backend -- env | grep DB_HOST
# Must print the value sourced from the ConfigMap

kubectl get pods -n jcc-production
# Must show both pods Running 1/1
```

## Stretch Challenge
Kubernetes Secrets are base64-encoded, not encrypted. Prove it without using
any external tools: retrieve the Secret with `kubectl get secret jcc-db-secret
-n jcc-production -o yaml`, take the base64 value of `DB_PASSWORD`, and decode
it using only `kubectl` and standard shell utilities. Write one paragraph
explaining what Sealed Secrets (Bitnami) or HashiCorp Vault Agent Injector
solves that Kubernetes Secrets do not.

## Instructor Notes
**Why this matters.** Credentials in Git is among the top three causes of
cloud breaches — once committed, the value is in the reflog, every clone, and
CI logs. Base64 in a Kubernetes Secret is not encryption; it requires RBAC,
audit logging, and encryption-at-rest to mean anything. This class establishes
the correct separation of concerns; Vault/Sealed Secrets come later.

**Common wrong approach.** Using `envFrom` for the Secret too. Principle of
least privilege: inject exactly the keys the app needs via `secretKeyRef`.

**Apply order.** Students who apply Deployment before ConfigMap hit
`CreateContainerConfigError`. Intentional — Kubernetes resolves references at
scheduling time, not apply time. Make them see the error before explaining it.
