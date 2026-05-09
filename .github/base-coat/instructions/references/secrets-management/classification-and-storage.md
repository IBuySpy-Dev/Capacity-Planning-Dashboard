# Secrets Classification and Storage Patterns

## Classification

### Type 1: Application Secrets (Runtime)

- API keys for external integrations (Stripe, SendGrid, AWS)
- Database credentials (username, password, connection strings)
- Service account credentials
- OAuth2 tokens, JWT secrets
- Encryption keys for data at rest

**Management:** Injected at deployment time, stored in Vault, rotated per policy.

### Type 2: Infrastructure Secrets

- SSH private keys
- TLS/SSL certificates and private keys
- VPN credentials
- Container registry credentials
- Code signing certificates

**Management:** Stored in Vault or certificate management service, short-lived leases.

### Type 3: Supply Chain Secrets

- Package repository credentials (npm, PyPI)
- Artifact repository tokens
- Git personal access tokens (PATs)
- CI/CD runner credentials

**Management:** Vault or CI/CD platform secrets store, minimize lifetime.

## Storage Patterns

### Pattern 1: Vault + Workload Identity (Recommended)

```yaml
Architecture:
  App Container
    ↓ (OIDC or mTLS)
  Kubernetes Service Account
    ↓ (WorkloadIdentity)
  Identity Provider (OIDC)
    ↓
  Vault
    ↓ (issues temporary token)
  App reads secret

Benefits:
  - No long-lived keys in code
  - RBAC integrated with Kubernetes identity
  - Automatic credential rotation
  - Audit trail per service
  - Token auto-expires (typically 1 hour)
```

**Kubernetes + Vault Setup:**

```bash
# 1. Create Kubernetes service account
kubectl create serviceaccount myapp -n default

# 2. Enable Vault Kubernetes auth backend
vault auth enable kubernetes

# 3. Create Vault policy
vault policy write myapp -<<EOF
path "secret/data/myapp/*" {
  capabilities = ["read", "list"]
}
EOF

# 4. Bind Kubernetes SA to Vault role
vault write auth/kubernetes/role/myapp \
  bound_service_account_names=myapp \
  bound_service_account_namespaces=default \
  policies=myapp

# 5. App reads at runtime via OIDC → Vault → temporary token
```

### Pattern 2: Deployment-Time Injection (CI/CD)

For non-Kubernetes or external services:

```yaml
Pipeline Steps:
  1. Build image (no secrets embedded)
  2. On deploy:
     - Retrieve secret from Vault
     - Inject as env var or mounted file
     - Deploy container
     - Secret lives only in running container memory
```

**Example (GitLab CI/CD):**

```yaml
deploy:
  script:
    - export DB_PASSWORD=$(vault kv get -field=password secret/db/prod)
    - docker run -e DB_PASSWORD=$DB_PASSWORD myimage:latest
  secrets:
    VAULT_TOKEN:
      vault: ci/vault-token
```

### Pattern 3: .env File (Dev Only — NOT for Production)

```yaml
Rules:
  - Never commit to repository (.gitignore must include .env)
  - Document in .env.example with masked/placeholder values
  - Use for local development and testing only
  - Never share .env files over email or chat

Example .env.example:
  DATABASE_URL=postgresql://user:PASSWORD@host:5432/db
  API_KEY=CHANGE_ME_IN_PRODUCTION
  JWT_SECRET=CHANGE_ME_IN_PRODUCTION
```

## Pre-Commit Secret Detection

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: detect-private-key
```

**Install:**

```bash
pip install pre-commit detect-secrets
pre-commit install
detect-secrets scan > .secrets.baseline
pre-commit run --all-files
```

## .gitignore Patterns

```gitignore
.env
.env.*
*.pem
*.key
*.p12
*.pfx
secrets/
vault-token
```
