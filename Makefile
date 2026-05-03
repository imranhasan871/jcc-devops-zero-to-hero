.PHONY: install start lint test docker-build docker-up docker-down docker-logs

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
