.PHONY: install start lint test docker-build docker-up docker-down docker-logs \
        k8s-apply k8s-status k8s-logs

install:
	npm install

start:
	node server.js

lint:
	npx eslint .

test:
	npm test

docker-build:
	docker build -t jcc-app .

docker-up:
	docker compose up --build -d

docker-down:
	docker compose down

docker-logs:
	docker compose logs -f

k8s-apply:
	kubectl apply -f k8s/namespace.yaml
	kubectl apply -f k8s/config/
	kubectl apply -f k8s/backend/

k8s-status:
	kubectl get deployments,pods,services,configmaps,secrets -n jcc-production

k8s-logs:
	kubectl logs -l app=jcc-backend -n jcc-production --tail=100 -f

# --- Ingress ---
k8s-ingress-enable:
	minikube addons enable ingress
	minikube addons enable ingress-dns
	@echo "Waiting for ingress controller to be ready..."
	kubectl wait --namespace ingress-nginx \
	  --for=condition=ready pod \
	  --selector=app.kubernetes.io/component=controller \
	  --timeout=90s

k8s-ingress-apply:
	kubectl apply -f k8s/ingress/ingress.yaml

k8s-ingress-status:
	kubectl get ingress -n jcc

# --- Rollout management ---
k8s-rollout-status:
	kubectl rollout status deployment/backend -n jcc

k8s-rollback:
	kubectl rollout undo deployment/backend -n jcc
	kubectl rollout status deployment/backend -n jcc

k8s-rollout-history:
	kubectl rollout history deployment/backend -n jcc

k8s-scale:
	kubectl scale deployment/backend --replicas=$(REPLICAS) -n jcc

k8s-hpa-status:
	kubectl get hpa -n jcc

## ── Monitoring ───────────────────────────────────────────────────
monitoring-up: ## Start Prometheus + Grafana stack
	docker compose -f monitoring/docker-compose.monitoring.yml up -d

monitoring-down: ## Stop monitoring stack
	docker compose -f monitoring/docker-compose.monitoring.yml down

metrics-check: ## Hit the /metrics endpoint locally
	curl -s http://localhost:3000/metrics

## ── Helm ─────────────────────────────────────────────────────────
helm-template: ## Render templates locally — no cluster needed
	helm template jcc ./helm/jcc-chart --debug

helm-install: ## Install chart (first time only)
	helm upgrade --install jcc ./helm/jcc-chart \
	  --namespace jcc-production \
	  --create-namespace \
	  --atomic \
	  --timeout 120s

helm-upgrade: ## Upgrade existing release
	helm upgrade jcc ./helm/jcc-chart \
	  --namespace jcc-production \
	  --atomic \
	  --timeout 120s

helm-diff: ## Show what will change — requires helm-diff plugin
	helm diff upgrade jcc ./helm/jcc-chart \
	  --namespace jcc-production

helm-uninstall: ## Remove the release (keeps namespace and PVCs)
	helm uninstall jcc --namespace jcc-production
