# Class 17 — K8s ConfigMap + Secret

## Objective
Separate configuration from code by using Kubernetes ConfigMaps for non-sensitive
settings and Secrets for credentials. Update the Deployment to consume both.
Understand why base64 is not encryption and how to manage secrets safely in
real production environments.

## What You'll Learn
- What a ConfigMap is and when to use it
- What a Kubernetes Secret is and how it differs from a ConfigMap
- How `envFrom: configMapRef` injects all keys as environment variables
- How `valueFrom: secretKeyRef` injects individual secret values
- Why base64 encoding is NOT security and what to use instead in production

## What Changed in This Class
- Added `k8s/config/configmap.yaml` — stores `NODE_ENV`, `DB_HOST`, `DB_PORT`, `DB_NAME`
- Added `k8s/config/secret.yaml` — stores `DB_USER` and `DB_PASSWORD` as base64 (placeholder values only)
- Updated `k8s/backend/deployment.yaml` to use `envFrom: configMapRef` for the ConfigMap and `secretKeyRef` for individual secret values
- Updated `Makefile` `k8s-apply` to apply config resources before backend resources
- Updated `k8s-status` to show configmaps and secrets alongside pods

## Hands-On Exercise
1. Apply all resources: `make k8s-apply`
2. Verify the ConfigMap: `kubectl describe configmap jcc-config -n jcc-production`
3. View the Secret (base64 encoded): `kubectl get secret jcc-secrets -n jcc-production -o yaml`
4. Decode a value: `kubectl get secret jcc-secrets -n jcc-production -o jsonpath='{.data.DB_USER}' | base64 --decode`
5. Port-forward and verify env vars reached the pod: `kubectl exec -it <pod-name> -n jcc-production -- env | grep DB`
6. Update a ConfigMap value and roll out: `kubectl rollout restart deployment/jcc-backend -n jcc-production`

## Key Concepts

**ConfigMap — Externalise Non-Secret Config**
A ConfigMap decouples configuration from container images. Instead of baking
`NODE_ENV=production` into the Dockerfile or hard-coding it in the Deployment
YAML, it lives in its own resource. You can update a ConfigMap without rebuilding
the image. `envFrom: configMapRef` is the most convenient form: every key in
the ConfigMap becomes an environment variable in the container.

**Kubernetes Secrets — What They Are (and Aren't)**
A Kubernetes Secret stores sensitive data separately from ConfigMaps and
provides basic access control: you can grant a pod access to a specific Secret
without exposing it to all workloads in the namespace. However, Secret values
are only *base64-encoded*, not encrypted. Base64 is a text encoding — not a
security measure. Anyone who can read the Secret object (or the etcd database
backing the cluster) can trivially decode the values.

**WARNING: Never Commit Real Secrets to Git**
The `secret.yaml` in this repository contains placeholder values only. In a
real project, committing actual passwords or API keys to git — even base64-
encoded — is a critical security vulnerability. Git history is permanent; even
if you delete the file later, the secret is still in every clone.

For production use one of these approaches:
- **Sealed Secrets**: encrypt secrets with a cluster public key; only the
  cluster can decrypt them. The encrypted file is safe to commit.
- **External Secrets Operator**: sync secrets from AWS Secrets Manager, GCP
  Secret Manager, or HashiCorp Vault into Kubernetes Secrets at runtime.
- **HashiCorp Vault**: a dedicated secrets management platform with audit
  logging, dynamic credentials, and fine-grained access policies.

## Course Complete
Congratulations — you have completed the JCC DevOps curriculum. You started
with a plain Node.js app and progressively added: containerisation with Docker,
local orchestration with Docker Compose, a PostgreSQL database with health
checks, a full CI/CD pipeline with GitHub Actions, automated testing with
coverage reporting, image publishing to a container registry, and production-
ready Kubernetes manifests with proper configuration management. These are the
foundational skills used by DevOps engineers at every level.
