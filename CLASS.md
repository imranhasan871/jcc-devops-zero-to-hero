# Class 40 — Distributed Tracing: OpenTelemetry + Grafana Tempo

## The Scenario
The JCC platform occasionally takes 8 seconds to respond to `GET /api/applicants`.
Sometimes fast, sometimes slow. Prometheus shows elevated P99 latency but not why.
Loki logs show the request came in and went out — nothing between. The slow query
could be the database, connection pool exhaustion, or a middleware. Without traces,
you are guessing.

## The Problem
Metrics aggregate. Logs are isolated events. Neither can answer: "of this specific
slow request, which function call consumed 7.8 of the 8 seconds?" That requires a
trace — a causal chain of timestamped spans from the HTTP handler through every
function call to the database query and back.

## Your Mission
- Add OpenTelemetry SDK to `server.js` — it must initialise before any other `require()`.
- Every HTTP request must produce a trace in Tempo with spans for the HTTP handler and each DB query.
- Every log line must include `traceId` so Loki entries link directly to Tempo traces.
- Start the full stack: `docker compose -f monitoring/docker-compose.monitoring.yml up -d`.
- Hit `GET /api/applicants`, find the trace in Grafana Tempo — identify the slowest span.
- In Loki, find the log line for that request by `requestId`, click "View Trace in Tempo" — it must open the correct trace.

## Constraints
- OpenTelemetry must use the OTLP HTTP exporter pointing at Tempo — no Jaeger, no Zipkin.
- Auto-instrumentation must cover both Express HTTP routes and `pg` database queries.
- The `traceId` in log output must be the real OTel trace ID, not a random UUID.

## Verification
```bash
docker compose -f monitoring/docker-compose.monitoring.yml up -d
curl http://localhost:3000/api/applicants

# Query Tempo for recent traces
curl "http://localhost:3200/api/search?service.name=jcc-backend&limit=5" | jq '.traces[0]'

# Confirm traceId in logs
node server.js &
curl -s http://localhost:3000/api/applicants
# Expected: {"level":"info","msg":"applicants fetched","traceId":"abc123...","spanId":"def456..."}
```

## Stretch Challenge
Add a manual span around the database query with a custom attribute `db.row_count` set
to the number of rows returned — make the data volume visible in Tempo span attributes.

## Instructor Notes
The final class closes the loop that started at class-25 with a single Prometheus endpoint.
Students who complete the trace-to-log correlation demo have internalised what it means
to run observable software. The 60-second root-cause walkthrough in
`docs/observability-guide.md` is the artifact they will reference in production.

---

## You Are Now a DevOps Engineer

```
class-01  Single HTML file                -> class-40  Full production system
class-08  Docker multi-stage             -> class-37  Runtime security + Falco
class-14  Push image to registry        -> class-38  Vault-injected secrets
class-21  Rolling updates + HPA        -> class-35  GitOps promotion via PR
class-25  Prometheus dashboard          -> class-40  Metrics + Logs + Traces correlated
```

You have built, secured, deployed, and can now debug this system end-to-end.
That is what separates a DevOps engineer from someone who has read about DevOps.
