# Class 36 — Security: Trivy in CI + OPA Gatekeeper

## The Scenario
A third-party security audit found: (1) the CI pipeline was shipping container images
with 12 CRITICAL CVEs — known vulnerabilities with public exploits; (2) any developer
could deploy a privileged container that could escape to the host node; (3) an image
from an unknown public registry was found running in production with no record of how
it got there. The audit report went to the board.

## The Problem
There were no automated gates. Vulnerabilities shipped because nobody checked. Privileged
containers deployed because the API server accepted them. Foreign images ran in production
because nothing validated provenance at admission time. Security was entirely dependent
on individual developer awareness — which does not scale and does not survive attrition.

## Your Mission
- Add a `security-scan` CI job using `aquasecurity/trivy-action` that scans the built image.
- The job must fail (block PR merge) if any CRITICAL CVE is found.
- SARIF results must upload to the GitHub Security tab so findings are always visible.
- Install OPA Gatekeeper in the cluster.
- Apply the resource limits constraint — verify a pod with no limits is rejected.
- Apply the disallow-privileged constraint — verify a privileged pod is rejected.
- Apply the allowed-registries constraint — verify a `docker.io` image is rejected.

## Constraints
- The Trivy job must run after the image is built, not before.
- Gatekeeper constraints must use `enforcementAction: deny` — not `warn` or `dryrun`.
- All three ConstraintTemplates must be applied before the Constraint resources — order matters.

## Verification
```bash
# Test resource limits rejection
kubectl run bad-pod --image=ghcr.io/imranhasan871/jcc-devops-zero-to-hero/jcc-app:dev \
  -n jcc-dev --restart=Never
# Expected: Error: ... must set resources.limits.cpu

# Test privileged rejection
kubectl apply -f - <<EOY
apiVersion: v1
kind: Pod
metadata: {name: priv-test, namespace: jcc-dev}
spec:
  containers:
  - name: c
    image: ghcr.io/imranhasan871/jcc-devops-zero-to-hero/jcc-app:dev
    securityContext: {privileged: true}
EOY
# Expected: Error: must not run as privileged
```

## Stretch Challenge
Configure Trivy to scan the Kubernetes cluster itself for misconfigurations:
`trivy k8s --report summary cluster` and pipe the output into a GitHub Actions summary.

## Instructor Notes
Security gates fail open by default in most teams — the developer merges without thinking
about CVEs because nothing stops them. The moment CI blocks a merge with a CRITICAL
finding, the culture shifts. Gatekeeper survives personnel turnover: the policy is code,
it is in Git, and it cannot be bypassed by forgetting.
