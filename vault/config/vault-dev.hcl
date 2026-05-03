# Vault dev server configuration.
# WARNING: dev mode stores data in memory — lost on restart.
# For production use a Raft or Consul storage backend with TLS.

ui           = true
log_level    = "info"
api_addr     = "http://0.0.0.0:8200"
cluster_addr = "http://0.0.0.0:8201"

storage "inmem" {}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true
}

# Start with: vault server -dev -dev-root-token-id="root" -config=vault-dev.hcl
