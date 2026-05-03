# Class 25 — Monitoring: Prometheus + Grafana (Hero Final Class)

## Objective
Add observability to the JCC platform so you can see what's happening in production in real time.
This is the final class — you have gone from a plain HTML file to a fully monitored, containerised,
CI/CD-deployed, Kubernetes-orchestrated application. That is the complete DevOps journey.

## What You'll Learn
- What the 4 Golden Signals of monitoring are
- How Prometheus scrapes metrics from your app
- How Grafana reads Prometheus data and builds dashboards
- How to expose a `/metrics` endpoint from a Node.js app (no extra library)
- How to run the entire monitoring stack with one `make` command

## What Changed in This Class
- `server.js` — added `metricsMiddleware` (counts all requests) and `/metrics` endpoint (Prometheus text format)
- `monitoring/prometheus.yml` — scrape config targeting the JCC app's `/metrics` endpoint
- `monitoring/docker-compose.monitoring.yml` — Prometheus + Grafana as Docker Compose services
- `monitoring/grafana-datasource.yml` — auto-provisions Prometheus as Grafana datasource
- `monitoring/grafana-dashboard.json` — pre-built dashboard with request count, uptime, heap memory panels
- `Makefile` — added `monitoring-up`, `monitoring-down`, `metrics-check` targets

## The 4 Golden Signals
Every production system should be monitored against these four signals:

| Signal | What it measures | JCC metric |
|--------|-----------------|------------|
| **Latency** | How long requests take | Response time (add with histogram) |
| **Traffic** | How many requests per second | `jcc_requests_total` counter |
| **Errors** | Rate of failed requests | Add HTTP 5xx label to counter |
| **Saturation** | How full your resources are | `jcc_heap_bytes`, CPU via node-exporter |

## Hands-On Exercise
1. Start the full stack: `make docker-up`
2. Start monitoring: `make monitoring-up`
3. Send some traffic: `curl http://localhost:3000/api/programs` (repeat 5-10 times)
4. Check raw metrics: `make metrics-check` — you'll see Prometheus text format
5. Open Prometheus UI at `http://localhost:9090` → query `jcc_requests_total`
6. Open Grafana at `http://localhost:3001` (admin / admin) → find the JCC dashboard
7. Watch the "Total Requests" panel update as you send more traffic

## Key Concepts

**Prometheus Scraping** — Prometheus works by PULLING metrics from your app at a regular interval
(every 15s by default). Your app exposes `/metrics` in plain text format; Prometheus reads it
and stores the data as time-series. This is the opposite of traditional logging (push model).

**Grafana Datasource** — Grafana does not store data itself. It connects to data sources
(Prometheus, Loki, InfluxDB) and visualises them. One Grafana instance can show metrics from
many different systems on a single dashboard.

**Counter vs Gauge** — A Counter only goes up (total requests). A Gauge can go up or down
(heap memory, active connections). Prometheus `rate()` function turns counter deltas into
per-second rates, which is how you get "requests per second" from a counter.

## You Made It

```
class-01  Plain HTML, no server              <- where you started
class-05  Node.js + npm scripts + Makefile
class-08  Docker (multi-stage, non-root user)
class-10  Docker Compose + PostgreSQL
class-14  CI/CD with GitHub Actions
class-17  Kubernetes (Deployments, Services, Secrets)
class-21  Rolling updates + autoscaling (HPA)
class-24  Jenkins full CD pipeline to production
class-25  Prometheus + Grafana monitoring    <- where you are now
```

Every company running software at scale uses tools from this exact stack.
You now understand how they fit together end-to-end.
