# Class 34 — GitOps: ArgoCD — Git IS the Source of Truth

## The Scenario
Jenkins deploys to Kubernetes but a developer ran `kubectl edit deployment backend`
directly in production — changed replica count and a memory limit. Jenkins does not
know. The desired state in Git and the actual state in the cluster have silently
diverged. The next Jenkins deploy overwrites the change without warning. Half the team
uses kubectl, half uses Jenkins, and nobody knows what is actually running.

## The Problem
There is no single source of truth. Cluster state is mutated by at least three
mechanisms: Jenkins pipelines, direct kubectl commands, and Helm installs done by hand.
Git shows one thing. The cluster runs another. Auditing who changed what is impossible
because kubectl changes leave no Git trail.

## Your Mission
- Install ArgoCD into the cluster and access the UI via port-forward.
- Apply the `jcc` AppProject to restrict sources and destinations.
- Apply `argocd-app-dev.yaml` — verify it shows "Synced" and "Healthy".
- Manually change the backend replica count with `kubectl edit` in jcc-dev.
- ArgoCD must detect the change and display "OutOfSync" within 3 minutes (default poll).
- Trigger a sync from the UI or CLI — verify the replica count returns to what Git says.
- Apply `argocd-app-production.yaml` — confirm syncPolicy is manual (no auto-sync).

## Constraints
- The production Application must never auto-sync — every production change is a deliberate human action.
- ArgoCD must be installed in the `argocd` namespace, isolated from application namespaces.
- All ArgoCD Application and AppProject manifests must live in Git, not be created via the UI.

## Verification
```bash
argocd app get jcc-dev
# Expected: Sync Status: Synced, Health Status: Healthy

kubectl scale deployment/backend --replicas=5 -n jcc-dev
# Wait up to 3 minutes, then:
argocd app get jcc-dev | grep "Sync Status"
# Expected: Sync Status: OutOfSync

argocd app sync jcc-dev
kubectl get deployment backend -n jcc-dev -o jsonpath='{.spec.replicas}'
# Expected: 2 (whatever Git says)
```

## Stretch Challenge
Configure ArgoCD notifications to post a Slack message whenever jcc-production drifts
to OutOfSync — before anyone has touched the cluster manually.

## Instructor Notes
ArgoCD's self-healing loop exposes the most important truth in modern infrastructure:
if a change is not in Git, it does not exist — it will be overwritten. The drift
detection exercise makes this visceral. Students who feel the OutOfSync alert fire are
students who stop using `kubectl edit` in production forever.
