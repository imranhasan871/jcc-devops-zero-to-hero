# Security Checklist

## CI Pipeline
- [ ] Trivy scans container image on every PR — CRITICAL CVEs block merge
- [ ] Trivy filesystem scan runs on Dockerfile and configs (informational)
- [ ] SARIF results uploaded to GitHub Security tab for audit trail
- [ ] Images pushed only from main branch, tagged with Git SHA

## Cluster Admission (OPA Gatekeeper)
- [ ] All containers must declare CPU and memory limits
- [ ] No privileged containers permitted in jcc-dev or jcc-production
- [ ] All images must originate from ghcr.io/imranhasan871
- [ ] Constraints tested with a deliberately bad pod manifest

## Runtime (Class 37)
- [ ] Containers run as non-root (runAsUser: 1000)
- [ ] Read-only root filesystem enforced
- [ ] All Linux capabilities dropped
- [ ] Falco alerts configured for shell-in-container and sensitive file reads

## Secrets (Class 38)
- [ ] No secrets in Git (base64 or plaintext)
- [ ] All secrets managed by Vault
- [ ] Secret rotation requires zero pod restarts
