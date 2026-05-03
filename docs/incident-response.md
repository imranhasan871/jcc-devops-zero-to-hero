# Incident Response Playbook — JCC Platform

## Severity Levels
- P1 CRITICAL: production down, data breach in progress, active attacker
- P2 HIGH: degraded production, Falco security alert fired
- P3 MEDIUM: non-production affected, elevated error rate

## Step 1: Detect
```bash
kubectl logs -n falco -l app=falco --tail=50
kubectl get events -n jcc-production --sort-by='.lastTimestamp' | tail -20
```

## Step 2: Isolate
```bash
# Block all egress from the compromised pod
kubectl label pod <pod-name> -n jcc-production quarantine=true

# Stop new traffic reaching it
kubectl scale deployment/backend --replicas=0 -n jcc-production
```

## Step 3: Capture Evidence
```bash
# Capture logs FIRST — before anything is destroyed
kubectl logs <pod-name> -n jcc-production > /tmp/incident-$(date +%s).log

# Inspect process list and filesystem (triggers a Falco alert — that is expected)
kubectl exec -it <pod-name> -n jcc-production -- ps aux
kubectl exec -it <pod-name> -n jcc-production -- ls -la /tmp
```

## Step 4: Investigate
```bash
# What image is running vs what Git says
kubectl get pod <pod-name> -n jcc-production -o jsonpath='{.spec.containers[*].image}'

# Recent deployments
kubectl rollout history deployment/backend -n jcc-production
```

## Step 5: Remediate
```bash
# Rotate the DB password in Vault (zero pod restarts)
vault kv put secret/jcc/db db_password="$(openssl rand -base64 32)"

# Redeploy from known-good Git SHA via ArgoCD
argocd app sync jcc-production --revision <known-good-sha>
```

## Step 6: Post-Mortem
Within 48 hours, publish a blameless post-mortem with:
- Timeline (UTC): start, detection, resolution
- Root cause: one sentence
- Impact: what was affected, for how long
- Detection gap: why it took that long
- Three action items with owners and deadlines
