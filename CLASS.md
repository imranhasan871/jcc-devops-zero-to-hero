# Class 38 — HashiCorp Vault: Real Secrets Management

## The Scenario
A developer's laptop was stolen. It had a `.env` file with the production database
password. That same password was also in the Jenkins credentials store, a GitHub Actions
secret, a Slack message from 8 months ago, and a `values.yaml` in an old branch.
Rotating it required finding and updating 7 different places. The app was down for
35 minutes during rotation.

## The Problem
Secrets are treated like configuration — copied wherever needed, checked into files,
pasted into chat. The number of places a secret lives grows without bound until no one
knows all of them. Rotation requires a coordinated update across every location, and
any missed location means the old credential stays active. This is not a human failure;
it is an architectural failure.

## Your Mission
- Start the Vault dev server: `make vault-dev-start`, verify the UI at `http://localhost:8200`.
- Run `make vault-init` — confirm `secret/jcc/db` is readable: `vault kv get secret/jcc/db`.
- Configure the backend Kubernetes pod to use the Vault Agent Injector annotations from `vault/k8s/vault-agent-annotations.yaml`.
- Verify the deployed pod has NO `DB_PASSWORD` env var and NO Kubernetes Secret reference in its YAML.
- Verify the DB password IS available: `kubectl exec deploy/backend -- cat /vault/secrets/db.env`.
- Rotate the password: `vault kv patch secret/jcc/db db_password="newpassword"` — the pod must NOT restart.

## Constraints
- The backend pod YAML must contain no password, no base64 string, no `secretKeyRef` for DB credentials.
- The Vault Agent must use Kubernetes authentication — no static Vault tokens in the cluster.
- Password rotation must complete without restarting any pod.

## Verification
```bash
# No password in pod spec
kubectl get pod -l app=jcc -n jcc-production -o yaml | grep -i password
# Expected: no output

# Password available at runtime via Vault Agent injection
kubectl exec deploy/backend -n jcc-production -- cat /vault/secrets/db.env
# Expected: export DB_PASSWORD=...

# Rotate without restart
vault kv patch secret/jcc/db db_password="rotated-$(date +%s)"
sleep 30
kubectl exec deploy/backend -n jcc-production -- cat /vault/secrets/db.env
# Expected: the NEW password; kubectl get pods shows no restarts
```

## Stretch Challenge
Configure Vault's `database` secrets engine to generate short-lived (1-hour TTL)
PostgreSQL credentials dynamically — the application never sees a static password.

## Instructor Notes
The rotation demo is the moment this class lands. Students watch a secret change in
Vault, see the file update in the running pod, and see no restart in `kubectl get pods`.
This makes "rotate every 30 days" go from "painful downtime event" to a cron job.
