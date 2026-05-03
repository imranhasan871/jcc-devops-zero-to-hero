# Secrets Management in Kubernetes

## The Core Problem

Kubernetes Secrets are base64-encoded, not encrypted. Any cluster user with `kubectl get secret`
access can decode them in one second:

```bash
kubectl get secret jcc-db-secret -n jcc-production \
  -o jsonpath='{.data.db-password}' | base64 -d
```

Base64 is an encoding scheme, not a security mechanism. Storing credentials in a Kubernetes
Secret YAML file and committing it to Git means your credentials are effectively plaintext in
version control history — permanently, even after rotation.

## The 5 Patterns (ordered by operational complexity)

### 1. Sealed Secrets (Bitnami)
Encrypt the Secret client-side using the cluster's public key. The encrypted SealedSecret YAML
is safe to commit to Git. Only the cluster's Sealed Secrets controller can decrypt it.
- **Tool**: `kubeseal` CLI + `sealed-secrets-controller` in cluster
- **Best for**: small teams, GitOps workflows, no cloud provider dependency
- **Risk**: if you lose the controller's private key, you permanently lose access to all sealed
  secrets. Back up the key.

### 2. External Secrets Operator (ESO)
Store real secrets in AWS SSM / Secrets Manager / GCP Secret Manager / Vault. ESO reads them
and creates native Kubernetes Secrets automatically. Rotation in the backend is picked up
within the configured `refreshInterval` with no manual intervention.
- **Best for**: cloud-native teams, secrets rotation requirements, compliance audits
- **This is what class-30 implements** (using a fake provider for local demo)

### 3. HashiCorp Vault Agent Injector
Vault Agent runs as a sidecar container and injects secrets as files or environment variables
into the application pod at startup. Secrets are never stored in etcd.
- **Best for**: multi-cloud, complex dynamic secrets (short-lived database credentials),
  advanced RBAC requirements
- **Overhead**: requires running and maintaining a Vault cluster

### 4. CSI Secrets Store Driver
Mount secrets directly from a cloud provider (AWS, Azure, GCP) or Vault as a volume into the
pod. No Kubernetes Secret object is ever created — secrets live only in the pod's memory.
- **Best for**: environments where secrets must never be written to etcd
- **Limitation**: requires the CSI driver daemonset, secrets only available as file mounts

### 5. Cloud-Native (IRSA / Workload Identity)
For AWS: IAM Roles for Service Accounts (IRSA). The pod's ServiceAccount is annotated with an
IAM role ARN. The AWS SDK automatically obtains short-lived credentials via the OIDC token
without any secrets stored anywhere in Kubernetes.
- **Best for**: AWS-native applications using the AWS SDK
- **The gold standard**: no secrets in the cluster at all

## Rules That Are Not Optional

- Never commit real passwords, API keys, or certificates to Git (including private repos)
- Never use base64 encoding and describe the result as "encrypted"
- Never store secrets in ConfigMaps — they have no access control separation from config
- Never put secret values in Helm values files that are committed to source control
- Never log all environment variables at application startup (they frequently contain secrets)

## Rotation Policy

- Database passwords: every 90 days minimum (PCI-DSS 4.0 requirement)
- API keys: immediately upon suspected compromise; otherwise every 180 days
- TLS certificates: use cert-manager with Let's Encrypt for automatic renewal
- ESO refreshInterval: set to match or slightly exceed your rotation frequency
