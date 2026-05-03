# Class 25 — Observability: Build the Dashboard Before the Next Outage

## The Scenario

Production went down at 3:17am. The on-call engineer was paged at 4:04am —
47 minutes after the first user impact. Root cause analysis took until 6am: a
memory leak introduced in the previous release caused gradual heap exhaustion over
roughly 6 hours. Node.js eventually ran out of memory, the process restarted, and
the crash loop made the app intermittently unavailable. The engineering post-mortem
produced one damning finding: the memory had been climbing linearly for 6 hours
and there was no alert, no dashboard, and no metric being collected. The CTO's
mandate to the team was direct: "I want a dashboard showing application health
before end of sprint. If this had been in place, we would have been paged at 1am
and the hotfix would have been deployed before anyone noticed."

## The Problem

The JCC server has no observability. There are no metrics, no dashboards, and no
alerts. The only way to know something is wrong is when users complain or the
process crashes. Prometheus, Grafana, and a metrics endpoint are the industry
standard for this problem. But understanding them requires building the smallest
possible piece from scratch — which is why you will implement the Prometheus text
format manually, without a library, before you are allowed to use one.

## Your Mission

- Add a `/metrics` endpoint to the JCC server that outputs metrics in valid
  Prometheus exposition format. You must implement the text format manually —
  do not install `prom-client` or any metrics library.
- The endpoint must expose at minimum: total HTTP request count (labelled by
  route and status code), Node.js heap memory used in bytes, and process uptime
  in seconds.
- Run Prometheus in Docker, configured to scrape `/metrics` every 15 seconds.
- Build a Grafana dashboard with exactly four panels: (1) requests per second,
  (2) error rate (4xx + 5xx as a percentage of total requests), (3) Node.js heap
  memory used in bytes, (4) server uptime in seconds.
- Configure one Prometheus alerting rule: if error rate exceeds 5% for more than
  2 consecutive minutes, fire an alert named `HighErrorRate`. Demonstrate the
  alert firing by generating 404 traffic.
- The entire monitoring stack (Prometheus + Grafana) must be defined in a
  `docker-compose.monitoring.yml` file and must start with a single command.
- The Grafana dashboard must be exported as JSON and committed to the repo so
  that `docker compose up` reproduces the dashboard with no manual clicking.

## What You Need to Know First

- The Prometheus exposition text format: metric names, TYPE and HELP comments,
  label syntax `{key="value"}`, and the counter vs gauge distinction.
- How Prometheus scrape configuration works: `scrape_configs`, `job_name`,
  `static_configs`, `targets`, `scrape_interval`.
- The difference between a Prometheus `counter` (monotonically increasing, never
  reset) and a `gauge` (can go up or down). Request count is a counter. Heap
  memory is a gauge.
- The `rate()` and `increase()` PromQL functions and why you cannot use a raw
  counter value to compute requests per second.
- Grafana provisioning: how to mount a dashboard JSON file so it loads
  automatically without clicking "import" in the UI.

## Constraints

- The `/metrics` endpoint must produce output that passes `promtool check metrics`
  with zero errors. Install promtool: it is part of the Prometheus binary release.
- You may NOT use `prom-client` or any other metrics library. The point is to
  understand the format by writing it. Once this class is done, use a library in
  production — but not here.
- The `docker-compose.monitoring.yml` file must be self-contained: Prometheus
  config and the Grafana dashboard JSON must be mounted from files in the repo,
  not created by hand inside the containers.
- The alert must be defined in a Prometheus rules file (`alert.rules.yml`),
  not in Grafana. Grafana alerts and Prometheus alerts are different systems —
  use Prometheus alerting rules.
- The dashboard JSON must be committed to `monitoring/grafana/dashboards/` in
  the repo. Confirm it is valid by deleting the Grafana container and volume,
  running `docker compose up` again, and verifying the dashboard reappears
  without any manual steps.

## Verification

```bash
# 1. Start the monitoring stack
docker compose -f monitoring/docker-compose.monitoring.yml up -d

# 2. Verify metrics format is valid
curl -s localhost:3000/metrics | promtool check metrics
# Expected output: (no output) — zero errors means the format is valid

# 3. Confirm Prometheus is scraping
curl -s 'localhost:9090/api/v1/targets' | python3 -m json.tool | grep '"health":"up"'
# Expected: at least one line showing health: up for the jcc job

# 4. Generate normal traffic
for i in $(seq 1 100); do curl -s localhost:3000/api/programs > /dev/null; done

# 5. Verify request counter has increased in Prometheus
curl -s 'localhost:9090/api/v1/query?query=jcc_requests_total' \
  | python3 -m json.tool | grep '"value"'
# Expected: non-zero value

# 6. Trigger the HighErrorRate alert
for i in $(seq 1 200); do curl -s localhost:3000/notfound > /dev/null; done
# Wait 2 minutes, then:
curl -s localhost:9090/api/v1/alerts | python3 -m json.tool | grep "HighErrorRate"
# Expected: alert entry with state "firing"

# 7. Confirm dashboard is reproducible
docker compose -f monitoring/docker-compose.monitoring.yml down -v
docker compose -f monitoring/docker-compose.monitoring.yml up -d
# Open localhost:3000 in a browser — dashboard must appear with all 4 panels,
# no import or manual configuration required.
```

## Stretch Challenge

The `/metrics` endpoint exposes internal application details: memory usage, error
rates, internal route names. Any client that can reach the server on port 3000 can
read this data. In a production environment this is a security concern — metrics
endpoints have leaked internal service topology in real breaches.

Implement one of the following protections:

**(a) Bearer token middleware**: Add a middleware in the JCC server that checks
for an `Authorization: Bearer <token>` header on requests to `/metrics`. If the
token is missing or wrong, return HTTP 401. The token must come from an environment
variable, not be hardcoded. Show that `curl localhost:3000/metrics` returns 401,
and that `curl -H "Authorization: Bearer $METRICS_TOKEN" localhost:3000/metrics`
returns valid metrics. Update the Prometheus scrape config to send the token via
`bearer_token_file` or `authorization.credentials`.

**(b) Nginx sidecar**: Add an nginx container to `docker-compose.monitoring.yml`
that proxies requests to the JCC app but blocks external access to `/metrics`.
Only the Prometheus container (by network name) may reach `/metrics`. All other
clients receive HTTP 403.

## Instructor Notes

The manual Prometheus format constraint is not sadism. Students who go straight
to `prom-client` have no mental model of what is being sent to Prometheus — they
cargo-cult metric names, misuse counter vs gauge, and have no idea why `rate()`
does not work on a gauge. Spending 30 minutes writing raw text format by hand
creates the intuition that makes the library make sense.

The most common format errors caught by `promtool check metrics`: missing HELP
line before a TYPE line, using the same metric name as both a counter and a gauge
across different scrapes, label values containing unescaped newlines, and
histogram bucket bounds not in strictly increasing order. All of these represent
genuine Prometheus ingestion failures in production — data is silently dropped.

For the alert exercise: students often set the alert threshold in Grafana instead
of in a Prometheus rules file. Both work for notification, but only Prometheus
alerting rules integrate with Alertmanager, support routing trees, inhibition, and
silences, and appear in the `/api/v1/alerts` endpoint. Grafana alerts are a
separate system with different semantics. The distinction matters when the team
needs to route database alerts to the DBA on-call and application alerts to the
engineering on-call — that is Alertmanager's job, not Grafana's.
