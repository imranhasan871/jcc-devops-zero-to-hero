# Observability Guide — The Three Pillars

## What Observability Means
A system is observable if you can answer "why is it slow?" or "what went wrong?" entirely
from its outputs — without adding new instrumentation after the fact. Metrics tell you
something is wrong. Logs tell you what happened. Traces tell you where the time went.

---

## Pillar 1: Metrics (Prometheus + Grafana)
What: Aggregated numeric measurements over time.
When to use: Detect that something is wrong. "Is the system healthy right now?"

```promql
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m])) > 2
```

## Pillar 2: Logs (Loki + Promtail)
What: Discrete events with context, stored and queryable at scale.
When to use: Understand what happened at a specific moment.

```logql
{app="jcc", namespace="jcc-production"} |= "error" | json | level="error"
{app="jcc"} | json | requestId="abc-123-def-456"
```

## Pillar 3: Traces (OpenTelemetry + Tempo)
What: The causal chain of spans that follows a request end-to-end.
When to use: Find WHERE time is spent within a request.

```
Trace: GET /api/applicants  (total: 1.8s)
  express.middleware          3ms
  pg.query SELECT applicants  1.7s  <-- THIS is the slow span
  res.json serialize           4ms
```

---

## From Alert to Root Cause in Under 60 Seconds

1. Grafana alert fires: "P99 latency > 2s on GET /api/applicants"

2. Open Grafana Explore -> Loki (10s):
   {app="jcc", namespace="jcc-production"} |= "/api/applicants" | json | duration > 2000
   Find a log line with "traceId": "abc123..."

3. Click "View Trace in Tempo" next to the log line (5s)

4. Tempo waterfall shows pg.query took 1.7s (10s)
   Span attributes show the exact SQL query.

5. Fix the root cause:
   - Missing index: CREATE INDEX CONCURRENTLY ON applicants(program_id)
   - Connection pool exhaustion: increase pool size in config.js
   - Table bloat: VACUUM ANALYZE applicants

Total: approximately 25 seconds to root cause.
Without traces: still guessing after 25 minutes.
