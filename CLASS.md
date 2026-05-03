# Class 26 — Helm: Kubernetes Package Manager

## Objective
Raw Kubernetes YAML manifests work fine for a single environment, but the moment you need dev,
staging, and production with different replica counts, image tags, and resource limits you end
up copy-pasting YAML files and making subtle mistakes. Helm solves this by introducing
templating, versioned releases, and a package ecosystem — turning a directory of YAML into a
parameterised, upgradeable, rollback-able application unit.

## Why This Matters in Production
Netflix, Shopify, and virtually every company running Kubernetes uses Helm or builds their own
equivalent. Without it a three-environment rollout means three nearly-identical directories of
YAML that inevitably drift apart. The classic war story: a developer updates the production
deployment YAML but forgets staging, so the next promotion silently rolls back a security
patch. Helm forces you to parameterise the differences and track everything as a versioned
Release. The Helm Hub (Artifact Hub) also hosts thousands of community charts — Postgres,
Redis, Nginx, cert-manager — so you stop reinventing the wheel for common infrastructure.

## What You'll Learn
- The difference between a Chart, a Release, and a Repository
- How Go templates work in Helm: `{{ .Values.* }}`, `{{ include }}`, `{{ toYaml | nindent }}`
- How `_helpers.tpl` defines reusable named templates used across all manifests
- How `helm install` differs from `helm upgrade --install` and when to use each
- How to override values per environment with `-f values-production.yaml` or `--set`
- How `--dry-run --debug` lets you inspect fully-rendered YAML before anything hits the cluster
- How `helm diff` (plugin) shows exactly what will change on an upgrade before you commit

## What Changed in This Class
- `helm/jcc-chart/Chart.yaml` — chart metadata: name, version, appVersion
- `helm/jcc-chart/values.yaml` — all tuneable parameters with sane defaults
- `helm/jcc-chart/templates/_helpers.tpl` — defines `jcc.fullname`, `jcc.labels`, `jcc.selectorLabels`
- `helm/jcc-chart/templates/deployment.yaml` — parameterised Deployment using `.Values.*`
- `helm/jcc-chart/templates/service.yaml` — Service with port driven from values
- `helm/jcc-chart/templates/configmap.yaml` — ConfigMap populated from values
- `helm/jcc-chart/templates/ingress.yaml` — conditional Ingress (only rendered if `ingress.enabled: true`)
- `Makefile` — added helm-install, helm-upgrade, helm-diff, helm-uninstall, helm-template targets

## Concept Deep Dive

**Chart vs Release vs Repository** — A Chart is a directory (or `.tgz` archive) containing
templates and a values file. It is the blueprint. A Release is a named, running instance of a
chart in a cluster — you can install the same chart twice with different names (`jcc-dev`,
`jcc-prod`) and get two completely independent releases with independent upgrade histories. A
Repository is a URL hosting an index of charts (like npm registry, but for Kubernetes
applications). Chart version and appVersion are separate: chart `0.1.0` can package app
version `2.3.1`, which is intentional — you can improve the chart without releasing a new
application version.

**helm install vs helm upgrade --install** — `helm install` fails if the release already
exists. `helm upgrade --install` is idempotent: install if absent, upgrade if present. In
CI/CD pipelines always use `upgrade --install`. Add `--atomic` to enable automatic rollback on
failure — if the new pods do not become Ready within the timeout, Helm rolls the release back
to the previous revision automatically, which is exactly the behavior you want in production.

**Values override precedence** — Helm merges values in this order (later wins): chart defaults
→ `-f file1.yaml` → `-f file2.yaml` → `--set key=value`. Use `-f values-production.yaml` for
environment-wide overrides and `--set image.tag=$CI_SHA` for per-deployment CI overrides.
Never put real secrets in values files that live in version control. The `--set` flag value
comes from your CI secret store and is never written to disk.

## Hands-On Exercise
1. Install the Helm CLI: `brew install helm` (macOS) or see helm.sh/docs for other platforms
2. Render templates locally without a cluster: `make helm-template`
3. Inspect the output — verify replica count, image tag, and namespace match your values
4. Try a dry-run: `helm install jcc ./helm/jcc-chart --dry-run --debug --namespace jcc-production`
5. Install the helm-diff plugin: `helm plugin install https://github.com/databus23/helm-diff`
6. Change `replicaCount` to 3 in values.yaml, then: `make helm-diff` — review before applying
7. Run `make helm-upgrade` and confirm with `kubectl get pods -n jcc-production`

## Common Mistakes
1. **Forgetting `nindent` on `toYaml`** — `toYaml .Values.resources` produces correct YAML
   but with no indentation offset. Without `| nindent 12` the surrounding block is misaligned,
   which produces invalid YAML that `helm template` renders but `kubectl apply` rejects with a
   confusing parse error. Always pair `toYaml` with `nindent`.
2. **Using `helm install` in CI pipelines** — it fails on the second deployment. Always use
   `upgrade --install` in automation. Add `--wait` so the pipeline step only succeeds once
   pods are actually Running, not just once the API call is accepted.
3. **Hardcoding namespace in Chart.yaml** — Chart.yaml is for chart metadata only. Namespace
   belongs in values so it can differ between environments. Students who hardcode it discover
   the problem when they try to deploy the same chart to `jcc-dev` and `jcc-production`.

## Next Class Preview
Class 27 locks down who and what can do what inside your cluster with Kubernetes RBAC —
the first thing a security auditor checks after gaining access.
