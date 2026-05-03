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
	kubectl apply -f k8s/backend/

k8s-status:
	kubectl get deployments,pods,services -n jcc-production

k8s-logs:
	kubectl logs -l app=jcc-backend -n jcc-production --tail=100 -f
