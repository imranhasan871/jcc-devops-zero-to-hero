# Vault policy for the JCC backend service.
# Principle of least privilege: the backend can ONLY read secrets under secret/data/jcc/.

path "secret/data/jcc/*" {
  capabilities = ["read"]
}

# Required for long-running services to renew their token
path "auth/token/renew-self" {
  capabilities = ["update"]
}

# Required by the Vault Agent
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
