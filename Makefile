# ──────────────────────────────────────────────────────────────────────────────
# JCC Platform — Makefile
# Usage: make <target>
# ──────────────────────────────────────────────────────────────────────────────

.PHONY: install dev start lint test clean help

## install: Install all npm dependencies
install:
	npm install

## dev: Start server in watch mode (auto-restarts on file change)
dev:
	npm run dev

## start: Start server in production mode
start:
	npm start

## lint: Run ESLint on all JavaScript files
lint:
	npm run lint

## test: Run the test suite
test:
	npm test

## clean: Remove generated files (node_modules, logs)
clean:
	rm -rf node_modules
	find . -name "*.log" -delete

## help: Print this help message
help:
	@grep -E '^## ' Makefile | sed 's/## /  /'
