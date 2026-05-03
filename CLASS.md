# Class 39 — Centralized Logging: Grafana Loki + Promtail

## The Scenario
Production incident. The app was returning errors for 22 minutes. `kubectl logs backend-pod-abc123`
shows the logs — but the pod has restarted 3 times and those logs are gone. You can only
see the last pod's logs. You need to search across all pod replicas, across restarts, and
across the last 48 hours simultaneously. `kubectl logs` cannot do this.

## The Problem
Container logs are ephemeral. Pod restarts discard log history. Multiple replicas mean
multiple separate streams that `kubectl logs` cannot aggregate. When an incident happens
at 2am, the engineer has no logs from the 20 minutes before the pod crashed — exactly
the window that contains the root cause.

## Your Mission
- Start the monitoring stack: `docker compose -f monitoring/docker-compose.monitoring.yml up -d`.
- Confirm Loki is receiving logs: open Grafana Explore, select Loki datasource.
- Run `{app="jcc", namespace="jcc-production"} |= "error"` — it must return results.
- Filter by a specific `requestId` to trace one request end-to-end across all log lines.
- Verify `level`, `requestId`, `msg`, `duration`, and `status` are independently filterable.
- Simulate a restart: `kubectl rollout restart deployment/backend -n jcc-production` — confirm Loki has logs from before AND after.

## Constraints
- All log output from `server.js` must be structured JSON — no `console.log` with concatenation.
- Every log line must include `timestamp`, `level`, `msg`, and `requestId`.
- Promtail must label every log line with `app`, `namespace`, and `pod` from Kubernetes metadata.

## Verification
```bash
# Confirm structured JSON output
node server.js &
curl -s http://localhost:3000/health
# Expected: {"level":"info","msg":"request completed","timestamp":"...","status":200,...}

# Query Loki
curl -G http://localhost:3100/loki/api/v1/query_range \
  --data-urlencode 'query={job="jcc"} |= "error"' \
  --data-urlencode 'limit=20' | jq '.data.result[].values[][1]'
```

## Stretch Challenge
Create a Grafana panel showing error rate over time:
`rate({app="jcc"} |= "error" [5m])`. Add an alert that fires when error rate exceeds 1/s.

## Instructor Notes
The moment students query logs that survived a pod restart, the gap in their mental model
of Kubernetes closes. `kubectl logs` teaches the wrong lesson — it implies logs are
reliable. Loki teaches the right lesson: logs must be shipped out to survive. The
requestId correlation plants the seed for the trace correlation in class-40.
