# DevOps Zero to Hero — JCC Platform

A hands-on, practical DevOps course built around a real project: the **John Casablancas Centers (JCC)** applicant management platform. You start with a single HTML file and finish with a production-grade system running on Kubernetes, deployed by Jenkins, and monitored by Prometheus and Grafana.

Each class is its own Git branch. Checkout a branch, read `CLASS.md`, follow the exercises, then move to the next one.

---

## How to Use This Repo

```bash
# Clone
git clone https://github.com/imranhasan871/jcc-devops-zero-to-hero.git
cd jcc-devops-zero-to-hero

# See all 25 class branches
git branch -a

# Start from the beginning
git checkout class-01
cat CLASS.md

# Move to the next class
git checkout class-02
cat CLASS.md
```

Each `CLASS.md` contains:
- **Objective** — what this class achieves
- **What You'll Learn** — skills gained
- **What Changed** — exact files added or modified
- **Hands-On Exercise** — step-by-step tasks to run yourself
- **Key Concepts** — theory explained simply
- **Next Class Preview** — what's coming

---

## The Project

**John Casablancas Centers (JCC)** is a real-world-style applicant management platform with:

| Layer | Technology |
|-------|-----------|
| Frontend | Static HTML + vanilla JS |
| Backend | Node.js + Express |
| Database | PostgreSQL |
| Container | Docker (multi-stage) |
| Orchestration | Kubernetes |
| CI/CD | GitHub Actions + Jenkins |
| Monitoring | Prometheus + Grafana |

---

## Course Curriculum

### Phase 1 — Foundation (Classes 01–05)
> Goal: get comfortable with the app and basic developer tooling before touching any DevOps.

| Branch | Title | What You Build |
|--------|-------|----------------|
| `class-01` | Plain HTML App | Single `index.html` — the entire app with no server, no tools |
| `class-02` | Node.js + Express Server | REST API (`/api/applicants`, `/api/programs`, `/health`), in-memory storage |
| `class-03` | Project Structure & Git Hygiene | `.gitignore`, `README`, move HTML to `public/`, clean folder layout |
| `class-04` | Environment Configuration | `.env.example`, `config.js`, dotenv — never hardcode secrets |
| `class-05` | npm Scripts & Makefile | `make dev`, `make lint`, `make test` — repeatable developer workflow |

---

### Phase 2 — Docker (Classes 06–10)
> Goal: package the app so it runs identically everywhere — your laptop, CI, and production.

| Branch | Title | What You Build |
|--------|-------|----------------|
| `class-06` | First Dockerfile | Single-stage `node:20-alpine` image, every instruction explained |
| `class-07` | Layer Caching & .dockerignore | Copy `package.json` first → faster rebuilds; ignore noise files |
| `class-08` | Multi-Stage Build | `builder` stage + lean `production` stage, non-root `USER node` |
| `class-09` | Docker Compose — App | `docker-compose.yml` with networking, `make docker-up/down/logs` |
| `class-10` | Docker Compose + PostgreSQL | Add `db` service with healthcheck, named volume, `database/init.sql`, switch server to `pg.Pool` |

---

### Phase 3 — CI/CD with GitHub Actions (Classes 11–14)
> Goal: every git push automatically lints, tests, and packages your code.

| Branch | Title | What You Build |
|--------|-------|----------------|
| `class-11` | First CI Workflow | `.github/workflows/ci.yml` — install + lint + test on every push |
| `class-12` | Tests + Coverage | Jest + Supertest test suite, coverage report uploaded as CI artifact |
| `class-13` | Docker Build in CI | Add `build-image` job using Docker Buildx, tagged with commit SHA |
| `class-14` | Push to Container Registry | Push to `ghcr.io` on `main` only, using GitHub secrets for auth |

---

### Phase 4 — Kubernetes (Classes 15–21)
> Goal: run the app reliably at scale with self-healing, autoscaling, and zero-downtime deploys.

| Branch | Title | What You Build |
|--------|-------|----------------|
| `class-15` | K8s Concepts + Namespace | `k8s/namespace.yaml`, full glossary: cluster / node / pod / deployment / service |
| `class-16` | Deployment + Service | `deployment.yaml` (2 replicas), `service.yaml` (ClusterIP), `make k8s-apply` |
| `class-17` | ConfigMap + Secret | Externalise all config; learn why you never hardcode secrets in manifests |
| `class-18` | PersistentVolumeClaim + StatefulSet | Give PostgreSQL a real persistent disk; understand why DBs need StatefulSets |
| `class-19` | Ingress + Routing | Nginx Ingress routes `/api` → backend, `/` → frontend at `jcc.local` |
| `class-20` | Health Probes | Readiness probe (stop traffic), liveness probe (restart), startup probe (slow boot) |
| `class-21` | Rolling Updates + HPA | Zero-downtime deploy strategy, `kubectl rollout undo`, autoscale 2–5 pods at 70% CPU |

---

### Phase 5 — Jenkins (Classes 22–24)
> Goal: self-hosted CI/CD pipeline — build, test, and deploy from a Jenkinsfile.

| Branch | Title | What You Build |
|--------|-------|----------------|
| `class-22` | Jenkins Setup + First Pipeline | Declarative `Jenkinsfile` with Checkout → Install → Lint → Test stages |
| `class-23` | Jenkins Full CI | Parallel Docker build stages, Trivy security scan stub, branch-gated image push |
| `class-24` | Jenkins + K8s Full CD | `kubectl set image` deploy to dev, **manual approval gate** before production |

---

### Phase 6 — Monitoring (Class 25)
> Goal: see exactly what your application is doing in production, in real time.

| Branch | Title | What You Build |
|--------|-------|----------------|
| `class-25` | Prometheus + Grafana | `/metrics` endpoint in Node.js, Prometheus scrape config, Grafana dashboard with request count, uptime, and heap memory |

---

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Git | any | checking out class branches |
| Node.js | 20+ | running the app locally |
| Docker + Docker Compose | v2+ | classes 06–14 |
| kubectl + minikube | 1.28+ | classes 15–21 |
| Jenkins | LTS | classes 22–24 (Docker install provided in `jenkins/README.md`) |

You don't need everything installed on day one. Install tools as each phase begins.

---

## Quick Reference

```bash
# Run locally (class-10+)
make docker-up               # start app + postgres
make docker-logs             # tail logs

# Run tests
make test

# Kubernetes
make k8s-apply               # apply all manifests
make k8s-status              # check pods/services
make k8s-rollback            # undo last deploy

# Monitoring (class-25)
make monitoring-up           # start Prometheus + Grafana
make metrics-check           # curl /metrics endpoint
# Prometheus → http://localhost:9090
# Grafana    → http://localhost:3001  (admin / admin)
```

---

## Progress Tracker

Copy this into your notes and check off each class as you complete it:

```
[ ] class-01  Plain HTML app
[ ] class-02  Node.js + Express
[ ] class-03  Project structure
[ ] class-04  Environment config
[ ] class-05  npm scripts + Makefile
[ ] class-06  First Dockerfile
[ ] class-07  Layer caching + .dockerignore
[ ] class-08  Multi-stage build
[ ] class-09  Docker Compose
[ ] class-10  Docker Compose + PostgreSQL
[ ] class-11  GitHub Actions CI
[ ] class-12  Tests + coverage
[ ] class-13  Docker build in CI
[ ] class-14  Push to registry
[ ] class-15  K8s concepts + namespace
[ ] class-16  Deployment + Service
[ ] class-17  ConfigMap + Secret
[ ] class-18  PVC + StatefulSet
[ ] class-19  Ingress + routing
[ ] class-20  Health probes
[ ] class-21  Rolling updates + HPA
[ ] class-22  Jenkins setup
[ ] class-23  Jenkins CI pipeline
[ ] class-24  Jenkins + K8s CD
[ ] class-25  Prometheus + Grafana
```

---

## Repo Structure (final state at class-25)

```
.
├── public/               # Frontend — static HTML served by Express
├── server.js             # Node.js + Express backend
├── config.js             # Environment-aware config
├── database/
│   └── init.sql          # Schema + seed data
├── tests/
│   └── server.test.js    # Jest + Supertest API tests
├── Dockerfile            # Multi-stage production image
├── docker-compose.yml    # App + PostgreSQL for local dev
├── Makefile              # All common commands in one place
├── .github/
│   └── workflows/
│       └── ci.yml        # GitHub Actions: lint → test → build → push
├── k8s/
│   ├── namespace.yaml
│   ├── backend/          # Deployment, Service, HPA
│   ├── config/           # ConfigMap, Secret
│   ├── database/         # StatefulSet, PVC, Service
│   ├── ingress/          # Ingress + controller setup
│   └── namespaces/       # dev + production with ResourceQuota
├── Jenkinsfile           # Full CI/CD pipeline with K8s deploy
├── jenkins/
│   └── README.md         # Jenkins Docker setup instructions
└── monitoring/
    ├── prometheus.yml
    ├── grafana-dashboard.json
    ├── grafana-datasource.yml
    └── docker-compose.monitoring.yml
```

---

## Instructor

Built for the mentoring engagement between **Tukrim Sohorabil** and **Imran Hasan**.

> "We start from a single HTML file and finish with a system you could run in production tomorrow."
