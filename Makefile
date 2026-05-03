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
