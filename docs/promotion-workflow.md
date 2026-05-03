# Environment Promotion Workflow

## The Core Rule
Every promotion is a Git commit. No GUI clicks, no manual kubectl, no Jenkins
parameter entry. The Git history is the deployment history.

## Step-by-Step: Dev to Production

### 1. Feature development
```bash
git checkout -b feature/my-change
# make changes, push, open PR to main
```

### 2. PR merges to main — CI builds the image
GitHub Actions pushes:
- `ghcr.io/imranhasan871/jcc-devops-zero-to-hero/jcc-app:dev`
- `ghcr.io/imranhasan871/jcc-devops-zero-to-hero/jcc-app:sha-<GITHUB_SHA>`

ArgoCD detects the new `:dev` tag and auto-syncs jcc-dev within 3 minutes.

### 3. Verify on dev
```bash
argocd app get jcc-dev
kubectl get pods -n jcc-dev
curl http://jcc-dev.local/health
```

### 4. Promote to production — open a PR
```bash
git checkout -b promote/sha-a1b2c3d4
# Edit gitops/environments/production/kustomization.yaml
# Change: newTag: sha-<old>  to  newTag: sha-<new>
git add gitops/environments/production/kustomization.yaml
git commit -m "promote: jcc-app sha-a1b2c3d4 to production"
git push origin promote/sha-a1b2c3d4
# Open PR — reviewer sees exactly one line changed
```

### 5. Merge triggers ArgoCD OutOfSync
ArgoCD shows jcc-production OutOfSync (syncPolicy is manual).
The UI displays the diff between current cluster state and new Git state.

### 6. Manual sync in ArgoCD
```bash
argocd app sync jcc-production
```

### 7. Verify production
```bash
kubectl rollout status deployment/backend -n jcc-production
```

## Why This Matters
- The wrong image can never be deployed by a typo in a Jenkins text box.
- Every production change has a PR, a reviewer, and a permanent Git record.
- Rolling back is `git revert` + ArgoCD sync — identical process, instant audit trail.
