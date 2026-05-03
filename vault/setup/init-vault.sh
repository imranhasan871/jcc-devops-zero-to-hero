#!/usr/bin/env bash
# init-vault.sh — idempotent Vault bootstrap for local dev
# Run after: docker compose -f docker-compose.vault.yml up -d
set -euo pipefail

export VAULT_ADDR="${VAULT_ADDR:-http://localhost:8200}"
export VAULT_TOKEN="${VAULT_TOKEN:-root}"

echo "==> Waiting for Vault to be ready..."
until vault status 2>/dev/null | grep -q "Initialized.*true"; do
  sleep 1
done

echo "==> Enabling KV v2 at secret/"
vault secrets enable -path=secret kv-v2 2>/dev/null || echo "    (already enabled)"

echo "==> Writing JCC secrets"
vault kv put secret/jcc/db \
  db_password="$(openssl rand -base64 24)" \
  db_user="jcc_user" \
  db_name="jcc"

vault kv put secret/jcc/app \
  jwt_secret="$(openssl rand -base64 32)" \
  session_secret="$(openssl rand -base64 32)"

echo "==> Writing jcc-backend policy"
vault policy write jcc-backend vault/policies/jcc-backend.hcl

echo "==> Enabling Kubernetes auth method"
vault auth enable kubernetes 2>/dev/null || echo "    (already enabled)"

vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"

echo "==> Creating Kubernetes role for jcc-backend"
vault write auth/kubernetes/role/jcc-backend \
  bound_service_account_names=jcc-backend \
  bound_service_account_namespaces=jcc-dev,jcc-production \
  policies=jcc-backend \
  ttl=1h

echo ""
echo "=== Vault initialised ==="
echo "DB password: $(vault kv get -field=db_password secret/jcc/db)"
echo ""
echo "To rotate (zero pod restarts):"
echo "  vault kv patch secret/jcc/db db_password=\"\$(openssl rand -base64 24)\""
