# DevOps Zero to Hero — JCC Platform

![Branches](https://img.shields.io/badge/branches-40-blue?style=flat-square) ![License](https://img.shields.io/badge/license-MIT-green?style=flat-square) ![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen?style=flat-square)

This course uses the **John Casablancas Centers (JCC) applicant management platform** — a real, production-grade web application — as the vehicle to teach every layer of modern DevOps from scratch. Unlike tutorial projects that get thrown away, every class builds on the last: you finish class 40 with the same app you started in class 01, now running on Kubernetes with GitOps, secrets management, and full distributed tracing.

---

## What You Will Be Able to Do

| Before this course | After this course |
|---|---|
| Can write an app | Can deploy it to production safely and repeatably |
| Writes code locally, ships manually | Has a full CI/CD pipeline that builds, tests, and deploys on every push |
| Copies `.env` files around | Manages secrets with HashiCorp Vault and never commits credentials |
| "It works on my machine" | Containerised app runs identically in dev, staging, and production |
| Restarts services manually when they crash | Kubernetes self-heals, scales, and rolls back automatically |
| Guesses what is broken in production | Has Prometheus metrics, Loki logs, and Tempo traces to find the root cause in minutes |
| Provisions servers by clicking in a console | Spins up a full VPC, RDS, and EKS cluster with a single `terraform apply` |
| Deploys by SSHing into a server | ArgoCD watches Git and reconciles the cluster automatically |

---

## Architecture Evolution

The application grows across 11 phases. Each ASCII diagram shows the state of the system at the end of that phase.

```
Phase 1 — class-01 (plain file)
─────────────────────────────
[Browser] ──► [index.html]


Phase 2 — class-10 (Docker + Compose + PostgreSQL)
──────────────────────────────────────────────────
[Browser] ──► [Express :3000]
                     │
               [PostgreSQL :5432]

All services launched with: docker compose up


Phase 3 — class-14 (CI/CD pipeline added)
──────────────────────────────────────────
  [Git Push]
      │
      ▼
[GitHub Actions]
  ├── lint & test
  ├── build Docker image
  └── push to GHCR
      │
      ▼
[Browser] ──► [Express :3000] ──► [PostgreSQL :5432]


Phase 5 — class-21 (Kubernetes cluster)
────────────────────────────────────────
[Browser]
    │
    ▼
[Nginx Ingress Controller]
    │
    ▼
[K8s Service]
    │
    ├──► [Express Pod 1]  ─┐
    ├──► [Express Pod 2]  ─┼──► [PostgreSQL StatefulSet]
    └──► [Express Pod 3]  ─┘         (PVC-backed)

Managed by: kubectl / YAML manifests


Phase 8 — class-36 (GitOps with ArgoCD)
─────────────────────────────────────────
[Git repo: k8s/]
    │  (watches)
    ▼
[ArgoCD]
    │  (reconciles)
    ▼
[K8s Cluster]
    ├── [Ingress]
    ├── [Express Deployment x3]
    └── [PostgreSQL StatefulSet]

Promotion: merge to main → ArgoCD detects drift → auto-sync


Phase 10 — class-40 (Full observability stack)
───────────────────────────────────────────────
[Browser]
    │
    ▼
[Ingress] ──► [Express Deployment x3] ──► [PostgreSQL StatefulSet]
    │               │         │
    │       [OTLP traces]  [/metrics]
    │               │         │
    ▼               ▼         ▼
[Loki]          [Tempo]  [Prometheus]
[Promtail]                    │
    │                         │
    └──────────┬──────────────┘
               ▼
           [Grafana]
    (logs + traces + metrics in one UI)
```

---

## How to Use This Repo

```bash
# Clone
git clone https://github.com/imranhasan871/jcc-devops-zero-to-hero.git
cd jcc-devops-zero-to-hero

# See all 40 class branches
git branch -a

# Start from zero
git checkout class-01
cat CLASS.md        # read this first — every class has one

# Move to the next class
git checkout class-02
git diff class-01   # see exactly what changed between classes
```

Every branch is a complete, working snapshot of the application. Each `CLASS.md` file contains:

1. **Objective** — the one thing this class achieves
2. **Concepts** — the theory you need before touching any code
3. **What changed** — a plain-English summary of every file added or modified
4. **Step-by-step instructions** — commands to run, in order
5. **Verification** — how to confirm everything is working
6. **Common errors** — the 2–3 mistakes most people hit, and the fix
7. **Further reading** — official docs links, not blog posts

### Studying changes between any two classes

```bash
# See all files changed between class-05 and class-10
git diff class-05 class-10 --name-only

# See full diff (great for code review practice)
git diff class-05 class-10

# Diff a single file across two classes
git diff class-10 class-14 -- .github/workflows/ci.yml

# List commits added in a range
git log class-10..class-14 --oneline
```

---

## Prerequisites & Installation

Install tools before starting the phase that requires them — you do not need everything on day one.

| Phase | Tool | Version | Install command |
|---|---|---|---|
| 1 | Git | 2.x | `brew install git` / `apt install git` |
| 1 | Node.js | 20 LTS | `nvm install 20 && nvm use 20` |
| 2 | Docker Desktop | Latest | https://docs.docker.com/get-docker/ |
| 2 | Docker Compose | v2 (bundled) | `docker compose version` |
| 3 | GitHub CLI | 2.x | `brew install gh` / `winget install GitHub.cli` |
| 4 | kubectl | 1.28+ | `brew install kubectl` |
| 4 | minikube | Latest | `brew install minikube` |
| 4 | Helm | 3.x | `brew install helm` |
| 5 | Java 17 (for Jenkins) | 17 LTS | `brew install openjdk@17` |
| 7 | ArgoCD CLI | 2.x | `brew install argocd` |
| 8 | Terraform | 1.7+ | `brew install terraform` |
| 10 | Vault CLI | 1.15+ | `brew install vault` |
| 10 | Trivy | Latest | `brew install trivy` |
| 11 | logcli | Latest | `brew install logcli` |

Verify all tools are present before starting class-15:

```bash
git --version && node --version && docker --version && \
kubectl version --client && helm version && terraform --version
```

---

## Full Curriculum — All 40 Classes

### Phase 1 — Foundation (classes 01–05)

**Phase Goal:** Take a raw HTML file and turn it into a structured, configurable Node.js application with a reproducible build process.

| Branch | Title | What you build |
|---|---|---|
| `class-01` | The Starting Point | A single `index.html` page for JCC — the baseline every future class improves |
| `class-02` | Node.js Entry Point | An Express server that serves the HTML and responds to `/health` |
| `class-03` | Project Structure | A `src/` layout with controllers, routes, and middleware separating concerns |
| `class-04` | Environment Config | A `.env`-driven config module so no credentials ever touch source code |
| `class-05` | Makefile | A `Makefile` with `dev`, `test`, `lint`, and `clean` targets so every teammate runs the same commands |

### Phase 2 — Docker (classes 06–10)

**Phase Goal:** Package the application so it runs identically everywhere, and compose it with a real database.

| Branch | Title | What you build |
|---|---|---|
| `class-06` | First Dockerfile | A working `Dockerfile` that builds and runs the Express app in a container |
| `class-07` | Layer Caching | An optimised Dockerfile that copies `package.json` first so `npm install` only re-runs when dependencies change |
| `class-08` | Multi-Stage Build | A two-stage Dockerfile (builder + runtime) that produces a slim production image |
| `class-09` | Docker Compose | A `docker-compose.yml` that starts the app and a PostgreSQL database together |
| `class-10` | Database Integration | The Express app connected to PostgreSQL via `pg`, with schema migrations and seed data |

### Phase 3 — CI/CD: GitHub Actions (classes 11–14)

**Phase Goal:** Automate quality gates and image delivery so no broken code ever reaches the registry.

| Branch | Title | What you build |
|---|---|---|
| `class-11` | Lint and Test Pipeline | A GitHub Actions workflow that runs ESLint and Jest on every pull request |
| `class-12` | Code Coverage Gate | Coverage reporting added to the workflow; the pipeline fails if coverage drops below 80% |
| `class-13` | Docker Build in CI | The workflow builds the Docker image and validates it starts cleanly |
| `class-14` | Push to GHCR | The workflow tags and pushes the image to GitHub Container Registry on every merge to `main` |

### Phase 4 — Kubernetes Core (classes 15–21)

**Phase Goal:** Run the application on Kubernetes with full reliability features — self-healing, scaling, persistent storage, and live traffic management.

| Branch | Title | What you build |
|---|---|---|
| `class-15` | Namespace and Context | A `jcc` namespace and a `kubectl` context configured to use it by default |
| `class-16` | Deployment and Service | A `Deployment` running 2 replicas and a `ClusterIP` Service in front of them |
| `class-17` | ConfigMap and Secret | App config loaded from a `ConfigMap` and database credentials from a `Secret` |
| `class-18` | PVC and StatefulSet | PostgreSQL running as a `StatefulSet` with a `PersistentVolumeClaim` so data survives pod restarts |
| `class-19` | Ingress | An Nginx Ingress resource that routes `jcc.local` to the Express service |
| `class-20` | Liveness and Readiness Probes | HTTP probes on `/health` that prevent bad pods from receiving traffic |
| `class-21` | Rolling Updates and HPA | A `HorizontalPodAutoscaler` that scales the deployment based on CPU, plus a zero-downtime rolling update strategy |

### Phase 5 — Jenkins (classes 22–24)

**Phase Goal:** Run an equivalent CI/CD pipeline on self-hosted Jenkins to understand enterprise pipeline tooling.

| Branch | Title | What you build |
|---|---|---|
| `class-22` | First Jenkinsfile | A declarative `Jenkinsfile` with stages for checkout, lint, and test |
| `class-23` | Full Jenkins CI | The pipeline extended with Docker build, image scan (Trivy), and push to registry |
| `class-24` | Kubernetes CD with Approval Gate | A `deploy` stage that applies K8s manifests, preceded by a manual approval input step |

### Phase 6 — Monitoring: Prometheus + Grafana (class 25)

**Phase Goal:** Expose application metrics and visualise them in a real-time dashboard.

| Branch | Title | What you build |
|---|---|---|
| `class-25` | Metrics and Grafana Dashboard | A `/metrics` endpoint (via `prom-client`), Prometheus scrape config, and a Grafana dashboard JSON showing request rate, error rate, and latency |

### Phase 7 — Advanced Kubernetes (classes 26–30)

**Phase Goal:** Harden the cluster for production: access control, network isolation, high availability, and external secret management.

| Branch | Title | What you build |
|---|---|---|
| `class-26` | Helm Chart | The entire JCC application packaged as a Helm chart with `values.yaml` and environment overrides |
| `class-27` | RBAC | `ServiceAccount`, `Role`, and `RoleBinding` resources that give the app only the permissions it needs |
| `class-28` | NetworkPolicies | Policies that allow only the Express pods to reach PostgreSQL, and deny all other pod-to-pod traffic by default |
| `class-29` | PDB and PriorityClass | A `PodDisruptionBudget` that keeps at least 2 replicas alive during node drains, and a `PriorityClass` for critical workloads |
| `class-30` | ExternalSecrets | The `external-secrets` operator pulling JCC secrets from AWS Secrets Manager into K8s `Secret` objects automatically |

### Phase 8 — Infrastructure as Code: Terraform (classes 31–33)

**Phase Goal:** Provision all cloud infrastructure from code so every environment is reproducible and auditable.

| Branch | Title | What you build |
|---|---|---|
| `class-31` | VPC and RDS | Terraform code that creates a VPC with public/private subnets and an RDS PostgreSQL instance in the private subnet |
| `class-32` | Modules and Remote State | The Terraform code refactored into reusable modules, with state stored in S3 and locked with DynamoDB |
| `class-33` | EKS Cluster | A production-ready EKS cluster (using the `terraform-aws-eks` module) with managed node groups and IRSA |

### Phase 9 — GitOps: ArgoCD (classes 34–35)

**Phase Goal:** Let Git be the single source of truth — no `kubectl apply` by hand in production, ever.

| Branch | Title | What you build |
|---|---|---|
| `class-34` | ArgoCD Install and Core Concepts | ArgoCD installed in the cluster, with the JCC `Application` manifest pointing at the `k8s/` directory |
| `class-35` | Multi-Env Promotion with Kustomize | A `kustomize` overlay structure (`base/`, `overlays/staging/`, `overlays/production/`) and an ArgoCD `ApplicationSet` that manages both environments |

### Phase 10 — Security (classes 36–38)

**Phase Goal:** Catch vulnerabilities before deploy, enforce runtime policies, and eliminate static secrets entirely.

| Branch | Title | What you build |
|---|---|---|
| `class-36` | Trivy and OPA | Trivy image scanning in the CI pipeline (fails on CRITICAL CVEs) and an OPA Gatekeeper policy that blocks `latest` tags |
| `class-37` | PodSecurity and Falco | Pod Security Admission enforcing `restricted` profile on the `jcc` namespace, and Falco alerting on suspicious syscalls |
| `class-38` | HashiCorp Vault | Vault running in the cluster, the JCC app retrieving database credentials via the Vault Agent sidecar injector |

### Phase 11 — Full Observability (classes 39–40)

**Phase Goal:** Correlate logs, metrics, and traces so any production incident can be investigated end-to-end without guessing.

| Branch | Title | What you build |
|---|---|---|
| `class-39` | Grafana Loki and Promtail | Loki deployed in the cluster, Promtail collecting container logs, structured log queries in Grafana |
| `class-40` | OpenTelemetry and Grafana Tempo | The Express app instrumented with the OpenTelemetry SDK, traces shipped to Tempo, and a Grafana data source linking traces to logs |

---

## Skills Matrix

| After Phase | You can... |
|---|---|
| Phase 1 — Foundation | Structure a Node.js project professionally, manage environment config safely, and give every teammate a reproducible local workflow |
| Phase 2 — Docker | Containerise any application, understand how image layers affect build time and image size, and run multi-service apps locally with a single command |
| Phase 3 — CI/CD | Prevent broken code from reaching main via automated quality gates, and ship a versioned Docker image to a registry on every merge |
| Phase 4 — Kubernetes Core | Deploy a stateful application to Kubernetes, expose it to traffic via Ingress, make it self-heal with probes, and autoscale it under load |
| Phase 5 — Jenkins | Build and operate an enterprise CI/CD pipeline with manual approval gates, and articulate the trade-offs between hosted and self-hosted CI |
| Phase 6 — Monitoring | Expose meaningful application metrics, build a Grafana dashboard from scratch, and use it to answer "is the app healthy?" in under 30 seconds |
| Phase 7 — Advanced Kubernetes | Package applications as Helm charts, enforce least-privilege access with RBAC, isolate services with NetworkPolicies, and sync secrets from external stores |
| Phase 8 — Terraform | Provision a complete cloud environment (network, database, Kubernetes cluster) from code, and manage state safely across a team |
| Phase 9 — GitOps | Operate ArgoCD to manage multi-environment deployments where Git is the only deployment interface, and promote changes through environments without touching the cluster directly |
| Phase 10 — Security | Find and block container vulnerabilities before deploy, enforce runtime security policies, and eliminate hardcoded secrets from every system boundary |
| Phase 11 — Full Observability | Investigate a production incident end-to-end — from an alert firing in Prometheus, to the error log in Loki, to the exact slow database query in Tempo — in under 10 minutes |

---

## Real-World Context

Understanding which companies use these tools at scale makes the material concrete, not abstract.

### Phase 1–2: Node.js + Docker
- **Netflix** runs 500+ microservices in Docker containers, using the same multi-stage build pattern you learn in class-08.
- **Shopify** containerised its Rails monolith incrementally — exactly the "add Docker without rewriting the app" approach in Phase 2.
- **GitHub** itself runs on containers; every CI job in GitHub Actions is a Docker container.

### Phase 3: GitHub Actions
- **Vercel**, **Netlify**, and virtually every SaaS startup use GitHub Actions as their primary CI platform.
- **Microsoft** migrated most open-source projects (VS Code, TypeScript) from Azure DevOps Pipelines to GitHub Actions.

### Phase 4: Kubernetes
- **Google** created Kubernetes from Borg, their internal cluster manager, and runs all production workloads on it.
- **Spotify** moved from on-premise bare metal to Kubernetes on GKE, scaling their backend from 150 to 1,000+ microservices.
- **Airbnb** uses Kubernetes to run tens of thousands of pods, with the same Ingress + HPA patterns you build in class-19 and class-21.

### Phase 5: Jenkins
- **LinkedIn** runs one of the largest Jenkins installations in the world, handling thousands of builds per day.
- **Netflix** uses Jenkins for their full release pipeline, including the manual approval gates you build in class-24.

### Phase 6: Prometheus + Grafana
- **SoundCloud** created Prometheus; it is now the de facto standard for Kubernetes metrics.
- **GitLab** exposes hundreds of Prometheus metrics and ships preconfigured Grafana dashboards with their product.
- **DigitalOcean** uses the exact Prometheus + Grafana stack from Phase 6 to monitor their managed Kubernetes offering.

### Phase 7: Helm + RBAC + ExternalSecrets
- **Bitnami** (VMware) maintains the most widely-used Helm chart repository; the chart structure from class-26 mirrors their conventions.
- **Goldman Sachs** enforces RBAC and NetworkPolicies on all internal Kubernetes clusters as a compliance requirement.
- **AWS** recommends ExternalSecrets with Secrets Manager (class-30) as the standard pattern for secrets in EKS.

### Phase 8: Terraform
- **Stripe** manages their entire AWS infrastructure — hundreds of VPCs and thousands of resources — with Terraform.
- **HashiCorp** (the creators) use Terraform internally; the module and remote state patterns from class-32 are their official recommendations.
- **Atlassian** uses Terraform to provision EKS clusters (same as class-33) across multiple AWS accounts.

### Phase 9: ArgoCD
- **Intuit** (TurboTax, QuickBooks) was one of the earliest adopters of ArgoCD and is a core contributor to the project.
- **IBM** uses ArgoCD to manage GitOps workflows across hundreds of internal Kubernetes clusters.
- **Red Hat** ships ArgoCD as the GitOps engine in OpenShift GitOps, their enterprise Kubernetes distribution.

### Phase 10: Security (Trivy, Falco, Vault)
- **Aqua Security** (creators of Trivy) use it in production deployments at Goldman Sachs, Microsoft, and HPE.
- **Sysdig** (creators of Falco) power runtime security at Booz Allen Hamilton and Zendesk.
- **HashiCorp Vault** is the standard secrets manager at Cloudflare, GitHub, and Pinterest.

### Phase 11: Observability (Loki, Tempo, OpenTelemetry)
- **Grafana Labs** runs Loki and Tempo in production for their own Cloud platform, handling petabytes of logs per day.
- **Shopify** adopted OpenTelemetry early and contributed the Node.js SDK; their instrumentation approach mirrors class-40.
- **Uber** uses a full traces + logs + metrics correlation stack (same architecture as class-40) to debug cross-service latency across thousands of microservices.

---

## Common Mistakes and How to Avoid Them

1. **Committing `.env` files with real credentials**
   *Why it happens:* `.gitignore` is set up late, or someone adds a new environment file and forgets to add it to the ignore list.
   *Fix:* Add `.env*` to `.gitignore` in class-01 and never remove it. Use `git secrets` or `gitleaks` in a pre-commit hook. If a secret is committed, rotate it immediately — git history is public even after you delete the file.

2. **Running containers as root**
   *Why it happens:* The default `FROM node:20` image runs as root unless you explicitly add a non-root user.
   *Fix:* Add `USER node` at the end of your Dockerfile (or create a dedicated user). Enable `runAsNonRoot: true` in your Kubernetes `securityContext`. The OPA policy in class-36 will enforce this automatically.

3. **Not setting resource limits (leads to OOMKilled in production)**
   *Why it happens:* Limits feel like premature optimisation locally, but a Node.js memory leak with no limit will take down the entire node.
   *Fix:* Set `resources.requests` and `resources.limits` on every container from class-16 onward. Start with `memory: 256Mi / 512Mi` and `cpu: 100m / 500m`, then tune based on Prometheus data.

4. **Storing Terraform state locally**
   *Why it happens:* `terraform init` defaults to a local `terraform.tfstate` file; it works fine alone but breaks immediately with a second person.
   *Fix:* Configure an S3 backend with DynamoDB locking (class-32) before sharing the repo with anyone. Never commit `terraform.tfstate` to git — add it to `.gitignore`.

5. **Using the `latest` tag in Kubernetes deployments**
   *Why it happens:* `latest` is the default when no tag is specified, and it works during early development.
   *Fix:* Always use immutable, content-addressed tags in Kubernetes manifests (e.g., `ghcr.io/org/jcc:sha-abc1234`). The OPA Gatekeeper policy in class-36 will reject `latest` tags at admission time. Use `imagePullPolicy: IfNotPresent` to avoid unnecessary pulls.

6. **Not adding health check probes and getting traffic sent to crashed pods**
   *Why it happens:* Without probes, Kubernetes marks a pod as Ready as soon as the container starts, even if the app has not finished initialising.
   *Fix:* Add a `readinessProbe` that hits `/health` from class-20 onward. The readiness probe keeps the pod out of the load-balancer pool until the app is genuinely ready. Add a `livenessProbe` to restart pods that enter a hung state.

7. **Hardcoding the Docker image tag in CI instead of using the Git SHA**
   *Why it happens:* It is faster to write `image: myapp:v1` than to wire up the SHA correctly.
   *Fix:* Use `${{ github.sha }}` in GitHub Actions (class-14) as the image tag. This creates a direct, auditable link between a running container and the exact commit that produced it.

8. **Running `kubectl apply` directly in production instead of using GitOps**
   *Why it happens:* It is the fastest way to fix something when something is on fire, and it feels acceptable as a "one-time exception."
   *Fix:* Once ArgoCD is in place (class-34), treat direct `kubectl apply` as a policy violation. ArgoCD will overwrite it on the next sync cycle anyway. Fix forward by committing to Git, not sideways by touching the cluster.

9. **Using a single Kubernetes namespace for everything**
   *Why it happens:* The default namespace works and adding namespaces feels like overhead.
   *Fix:* Create separate namespaces from the start (class-15): one per environment (`jcc-dev`, `jcc-staging`, `jcc-prod`). Namespaces are the boundary for RBAC, NetworkPolicies, and ResourceQuotas — you cannot retrofit them easily.

10. **Not pinning dependency versions in `package.json`**
    *Why it happens:* `npm install express` adds `"express": "^4.18.2"` with a caret, which allows minor version bumps that can silently break behaviour.
    *Fix:* Use `npm ci` in Docker and CI instead of `npm install`. Commit `package-lock.json`. Consider using exact versions (`"express": "4.18.2"`) for production dependencies and running `npm audit` in the CI pipeline.

---

## Quick Reference Card

```bash
## Local Development
make dev             # start app with nodemon (auto-reload on save)
make docker-up       # start all services via Docker Compose
make docker-down     # stop all services and remove containers
make test            # run Jest test suite
make lint            # run ESLint
make clean           # remove node_modules, dist, coverage

## Kubernetes
make k8s-apply       # kubectl apply -f k8s/ --recursive
make k8s-rollback    # kubectl rollout undo deployment/jcc-app
make k8s-scale REPLICAS=5   # scale app deployment to N replicas
make k8s-logs        # tail logs from all app pods
make k8s-status      # get pods, services, ingress in jcc namespace

## Helm
make helm-install    # helm install jcc ./helm/jcc -n jcc
make helm-upgrade    # helm upgrade jcc ./helm/jcc -n jcc
make helm-diff       # helm diff upgrade (preview changes before applying)
make helm-uninstall  # helm uninstall jcc -n jcc

## Monitoring
make monitoring-up   # deploy Prometheus + Grafana + Loki + Tempo stack
make monitoring-down # remove the observability stack
make metrics-check   # curl localhost:3000/metrics and pretty-print output
make logs-query      # logcli query '{app="jcc"}' --tail

## Security
make security-audit  # trivy image + npm audit + kubesec scan
make vault-dev-start # start Vault in dev mode (for local testing)
make vault-setup     # configure Vault policies and secrets for JCC
make policy-check    # run OPA/Conftest against all k8s manifests

## Terraform
make tf-init         # terraform init (sets up backend)
make tf-plan         # terraform plan -out=tfplan
make tf-apply        # terraform apply tfplan
make tf-destroy      # terraform destroy (with confirmation prompt)

## CI/CD Helpers
make ci-local        # run the full CI pipeline locally using act
make image-build     # docker build with correct tag (git SHA)
make image-push      # push to GHCR (requires GITHUB_TOKEN)
```

---

## Progress Tracker

Copy this checklist into your notes. Check each box as you complete the class.

<table>
<tr>
<td>

- [ ] class-01 — Starting Point
- [ ] class-02 — Node.js Entry Point
- [ ] class-03 — Project Structure
- [ ] class-04 — Environment Config
- [ ] class-05 — Makefile
- [ ] class-06 — First Dockerfile
- [ ] class-07 — Layer Caching
- [ ] class-08 — Multi-Stage Build
- [ ] class-09 — Docker Compose
- [ ] class-10 — Database Integration
- [ ] class-11 — Lint and Test Pipeline
- [ ] class-12 — Code Coverage Gate
- [ ] class-13 — Docker Build in CI

</td>
<td>

- [ ] class-14 — Push to GHCR
- [ ] class-15 — Namespace and Context
- [ ] class-16 — Deployment and Service
- [ ] class-17 — ConfigMap and Secret
- [ ] class-18 — PVC and StatefulSet
- [ ] class-19 — Ingress
- [ ] class-20 — Liveness and Readiness Probes
- [ ] class-21 — Rolling Updates and HPA
- [ ] class-22 — First Jenkinsfile
- [ ] class-23 — Full Jenkins CI
- [ ] class-24 — K8s CD with Approval Gate
- [ ] class-25 — Metrics and Grafana Dashboard
- [ ] class-26 — Helm Chart

</td>
<td>

- [ ] class-27 — RBAC
- [ ] class-28 — NetworkPolicies
- [ ] class-29 — PDB and PriorityClass
- [ ] class-30 — ExternalSecrets
- [ ] class-31 — VPC and RDS
- [ ] class-32 — Modules and Remote State
- [ ] class-33 — EKS Cluster
- [ ] class-34 — ArgoCD Install
- [ ] class-35 — Multi-Env GitOps
- [ ] class-36 — Trivy and OPA
- [ ] class-37 — PodSecurity and Falco
- [ ] class-38 — HashiCorp Vault
- [ ] class-39 — Loki and Promtail
- [ ] class-40 — OpenTelemetry and Tempo

</td>
</tr>
</table>

---

## Repo Structure (final state at class-40)

```
jcc-devops-zero-to-hero/
├── CLASS.md                    # class notes for current branch
├── Makefile                    # all common tasks
├── package.json
├── package-lock.json
├── .env.example                # template — never commit .env
├── .gitignore
├── Dockerfile                  # multi-stage production build
├── docker-compose.yml          # local dev: app + postgres + redis
│
├── src/
│   ├── index.js                # Express entry point
│   ├── config/
│   │   └── index.js            # env-driven config module
│   ├── routes/
│   │   ├── applicants.js
│   │   └── health.js
│   ├── controllers/
│   │   └── applicants.js
│   ├── middleware/
│   │   ├── auth.js
│   │   └── logger.js
│   ├── db/
│   │   ├── index.js            # pg connection pool
│   │   └── migrations/
│   └── telemetry/
│       └── index.js            # OpenTelemetry SDK setup (class-40)
│
├── tests/
│   ├── unit/
│   └── integration/
│
├── .github/
│   └── workflows/
│       ├── ci.yml              # lint → test → build → push
│       └── security.yml        # Trivy scan on schedule
│
├── Jenkinsfile                 # declarative Jenkins pipeline
│
├── k8s/
│   ├── namespace.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   ├── secret.yaml             # template — real values from Vault
│   ├── statefulset-postgres.yaml
│   ├── pvc.yaml
│   ├── hpa.yaml
│   ├── rbac/
│   │   ├── serviceaccount.yaml
│   │   ├── role.yaml
│   │   └── rolebinding.yaml
│   ├── networkpolicies/
│   │   └── deny-all.yaml
│   ├── pdb.yaml
│   └── vault/
│       └── agent-inject.yaml
│
├── helm/
│   └── jcc/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── values-staging.yaml
│       ├── values-production.yaml
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── ingress.yaml
│           └── _helpers.tpl
│
├── kustomize/
│   ├── base/
│   └── overlays/
│       ├── staging/
│       └── production/
│
├── argocd/
│   ├── application.yaml
│   └── applicationset.yaml
│
├── terraform/
│   ├── modules/
│   │   ├── vpc/
│   │   ├── rds/
│   │   └── eks/
│   ├── environments/
│   │   ├── staging/
│   │   └── production/
│   └── backend.tf
│
├── monitoring/
│   ├── prometheus/
│   │   └── values.yaml         # kube-prometheus-stack overrides
│   ├── grafana/
│   │   └── dashboards/
│   │       └── jcc-overview.json
│   ├── loki/
│   │   └── values.yaml
│   └── tempo/
│       └── values.yaml
│
├── security/
│   ├── policies/
│   │   └── no-latest-tag.rego  # OPA/Conftest policy
│   ├── falco/
│   │   └── rules.yaml
│   └── vault/
│       ├── policy.hcl
│       └── setup.sh
│
└── scripts/
    ├── setup-minikube.sh
    ├── seed-db.sh
    └── generate-certs.sh
```

---

## About This Course

This repository was built for a private mentoring engagement between **Tukrim Sohorabil** and **Imran Hasan**, a senior DevOps engineer. The curriculum was designed to address a specific gap: most DevOps courses teach tools in isolation using toy applications that get thrown away at the end of each module. This course takes the opposite approach — one real application, evolved continuously across 40 classes, each branch a deployable checkpoint.

The philosophy is simple: you learn DevOps by doing DevOps on something that matters. Every class starts with a working application and ends with a working application — just more production-ready than before. There are no slides-only sessions. If you are not running a command or reading a diff, the class is not over. The JCC platform is a real applicant management system with authentication, a relational database, and real traffic patterns. The problems it surfaces — slow queries, OOMKilled pods, failed deploys — are the same problems you will face on the job. Learning to solve them here, with a mentor, means you will recognise and fix them alone in production.
