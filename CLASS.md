# Class 35 — GitOps: Kustomize Multi-Environment Promotion

## The Scenario
Promoting from dev to production requires logging into Jenkins, finding the right job,
entering the image tag manually, and hoping the correct person approves. Last month
the wrong tag was entered — an older image went to production. Nobody noticed for
6 hours because no diff was shown, no change was recorded, and the process was
completely undocumented.

## The Problem
Promotion is a verbal process. A developer says "deploy sha-abc123 to production" in
Slack. Someone logs into Jenkins and types it. There is no record of what changed, no
review step, no way to see the diff between what is running and what is about to run.
Rollback means typing a different SHA into the same box.

## Your Mission
- Build Kustomize overlays for `dev` and `production` that extend the shared base.
- Dev overlay: namespace `jcc-dev`, replicas 1, image tag `:dev`.
- Production overlay: namespace `jcc-production`, replicas 3, image tag pinned to a SHA.
- Validate locally: `kubectl kustomize gitops/environments/dev | grep image`.
- Simulate a promotion: update the production image tag, commit, open a PR — the diff must show exactly one changed line.
- ArgoCD must show `jcc-production` OutOfSync after the merge, and display the image tag diff before you sync.

## Constraints
- No environment-specific YAML may duplicate any field already set in the base.
- The production image tag must be a SHA digest — never `:latest` in production.
- Promotion must be a PR; direct pushes to main are not acceptable.

## Verification
```bash
# Render dev overlay — confirm namespace, replicas, and image tag
kubectl kustomize gitops/environments/dev | grep -E "namespace:|replicas:|image:"

# Render production overlay — confirm 3 replicas and SHA tag
kubectl kustomize gitops/environments/production | grep -E "namespace:|replicas:|image:"
```

## Stretch Challenge
Write a GitHub Actions workflow that automatically opens the promotion PR when CI
pushes a new image SHA to GHCR — no human needs to touch a text editor to promote.

## Instructor Notes
Kustomize overlays solve the copy-paste problem that kills most multi-environment
setups. The moment students see a one-line PR as a production deployment, the idea
of typing image tags into Jenkins forms becomes unthinkable. The promotion workflow
document is the artifact that keeps working after the course ends.
