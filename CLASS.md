# Class 37 — Runtime Security: PodSecurity + Falco

## The Scenario
An attacker exploited an npm dependency vulnerability in the JCC backend. Because the
container ran as root with a writable filesystem, they installed a cryptominer and added
a cron job inside the container. The container ran for 3 weeks before unusual CPU usage
was noticed. With a read-only filesystem and a non-root user, this attack would have
failed on the first write attempt.

## The Problem
Kubernetes defaults are dangerously permissive. Containers run as root unless explicitly
configured otherwise. The filesystem is writable. All Linux capabilities are available.
An exploited container is effectively a root shell on a node. Most teams configure
zero of the four available security layers.

## Your Mission
- Update the backend deployment with a hardened `securityContext`: `runAsNonRoot`, `runAsUser: 1000`, `readOnlyRootFilesystem: true`, `allowPrivilegeEscalation: false`, capabilities drop ALL.
- Mount an `emptyDir` volume at `/tmp` so the app can still write temporary files.
- Apply `pod-security-standards.yaml` to label `jcc-production` with the `restricted` enforcement profile.
- Install Falco and load `falco-rules.yaml`.
- Run `kubectl exec -it <backend-pod> -- /bin/sh` — Falco must fire the shell-spawn alert within 10 seconds.
- Write the incident response playbook to `docs/incident-response.md`.

## Constraints
- The backend pod must start and pass its readiness probe with `readOnlyRootFilesystem: true` — no cheating with writable mounts.
- Falco rules must use `CRITICAL` priority for shell spawning.
- The PodSecurity namespace label must use `enforce` mode — `warn` is not sufficient.

## Verification
```bash
# Confirm non-root
kubectl exec deploy/backend -n jcc-production -- id
# Expected: uid=1000 gid=1000

# Confirm read-only root
kubectl exec deploy/backend -n jcc-production -- touch /evil
# Expected: Read-only file system error

# Trigger Falco alert
kubectl exec -it <backend-pod> -n jcc-production -- /bin/sh
kubectl logs -n falco -l app=falco | grep "Shell spawned"
```

## Stretch Challenge
Configure Falco to send alerts to a Slack webhook using the `falcosidekick` sidecar.

## Instructor Notes
The read-only filesystem exercise is the most visceral security lesson in the course —
students feel exactly what an attacker would hit. The Falco alert firing during the
`kubectl exec` demo makes abstract "runtime security" concrete. The incident response
playbook turns this from a configuration exercise into professional practice.
