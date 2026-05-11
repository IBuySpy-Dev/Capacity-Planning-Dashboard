# Configuration Reference

All configuration is driven by environment variables. In production, sensitive values are stored in Azure Key Vault and injected into App Service as **Key Vault references** — they never appear as plain text in App Settings.

---

## Quick reference

| Variable | Required | Default | Production source |
|---|---|---|---|
| `NODE_ENV` | Yes | `development` | App Settings (plain) |
| `PORT` | No | `3000` | App Settings (plain) |
| `AUTH_ENABLED` | Yes | `false` | App Settings (plain) |
| `ENTRA_CLIENT_ID` | If auth | — | App Settings (plain) |
| `ENTRA_TENANT_ID` | If auth | — | App Settings (plain) |
| `ENTRA_CLIENT_SECRET` | If auth | — | **Key Vault reference** |
| `ADMIN_GROUP_ID` | No | — | App Settings (plain) |
| `AUTH_REDIRECT_URI` | If auth | `http://localhost:3000/auth/callback` | App Settings (plain) |
| `SESSION_SECRET` | Yes | — | **Key Vault reference** |
| `SQL_SERVER` | Yes | — | App Settings (plain) |
| `SQL_DATABASE` | Yes | — | App Settings (plain) |
| `SQL_AUTH_MODE` | Yes | `msi` | App Settings (plain) |
| `INGEST_API_KEY` | Yes | — | **Key Vault reference** |
| `INGEST_SUBSCRIPTION_IDS` | No | auto-discover | App Settings (plain) |
| `INGEST_REGION_PRESET` | No | `USMajor` | App Settings (plain) |
| `INGEST_ON_STARTUP` | No | `false` | App Settings (plain) |
| `INGEST_INTERVAL_MINUTES` | No | `0` (disabled) | App Settings (plain) |
| `QUOTA_MANAGEMENT_GROUP_ID` | No | — | App Settings (plain) |
| `CAPACITY_WORKER_BASE_URL` | No | — | App Settings (plain) |
| `CAPACITY_WORKER_SHARED_SECRET` | No | — | **Key Vault reference** |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | No | — | **Key Vault reference** |

---

## Key Vault reference format

App Settings that reference Key Vault use this syntax:

```
@Microsoft.KeyVault(VaultName=kv-capdash-prod;SecretName=capdash-session-secret)
```

The App Service managed identity must have **Key Vault Secrets User** role on the vault.

---

## Authentication settings

| Variable | Description |
|---|---|
| `AUTH_ENABLED` | Set `true` in production to require Entra login. `false` bypasses auth entirely. |
| `ENTRA_CLIENT_ID` | App registration client ID from `scripts/New-EntraApp.ps1` output |
| `ENTRA_TENANT_ID` | Your Entra tenant ID |
| `ENTRA_CLIENT_SECRET` | Client secret — **Key Vault reference in production** |
| `ADMIN_GROUP_ID` | Object ID of the Entra group whose members get Admin access. Empty = all authenticated users are admin. |
| `AUTH_REDIRECT_URI` | Must match the redirect URI registered on the app. |
| `SESSION_SECRET` | 32-byte random hex — **Key Vault reference in production** |
| `SESSION_MAX_AGE_MS` | Session lifetime in ms. Default: `28800000` (8 hours) |

---

## SQL settings

| Variable | Description |
|---|---|
| `SQL_SERVER` | Azure SQL server hostname (e.g., `capdash-prod.database.windows.net`) |
| `SQL_DATABASE` | Database name (default: `CapacityDashboard`) |
| `SQL_AUTH_MODE` | `msi` for managed identity (production), `sql` for username/password (local dev) |
| `SQL_USER` | Only for local dev with SQL auth |
| `SQL_PASSWORD` | Only for local dev with SQL auth |
| `SQL_TRUST_SERVER_CERTIFICATE` | `true` for local Docker SQL only — **never `true` in production** |
| `SQL_REQUEST_TIMEOUT_MS` | Query timeout in ms. Default: `30000` |

---

## Ingestion settings

| Variable | Description |
|---|---|
| `INGEST_API_KEY` | HMAC key for worker→API authentication — **Key Vault reference in production** |
| `INGEST_SUBSCRIPTION_IDS` | Comma-separated subscription IDs to ingest. Auto-discovers accessible subscriptions if empty. |
| `INGEST_REGION_PRESET` | Region filter preset. Options: `USMajor`, `All`, or custom CSV of Azure region names. |
| `INGEST_ON_STARTUP` | `true` to run ingestion immediately on app start. Default `false`. |
| `INGEST_INTERVAL_MINUTES` | Minutes between scheduled ingestion runs. `0` = disabled. |
| `INGEST_ARM_MAX_RETRIES` | Max retries for transient ARM errors (429, 503). Default `3`. |
| `INGEST_REGION_CONCURRENCY` | Parallel region ingestion count. Default: auto (based on subscription count). |
| `INGEST_AI_ENABLED` | `true` to ingest Azure AI model quota data. Default `false`. |
| `INGEST_AI_MODEL_CATALOG` | `true` to ingest AI model catalog. Default `true`. |

---

## Quota settings

| Variable | Description |
|---|---|
| `QUOTA_MANAGEMENT_GROUP_ID` | Root management group ID for quota discovery (e.g., `mg-contoso`). Without this, the `/api/quota/management-groups` endpoint returns an error. |

---

## Capacity worker settings

| Variable | Description |
|---|---|
| `CAPACITY_WORKER_BASE_URL` | Function App base URL (e.g., `https://func-capdash-worker.azurewebsites.net`) |
| `CAPACITY_WORKER_SHARED_SECRET` | Shared HMAC secret — **Key Vault reference in production** |
| `CAPACITY_WORKER_TIMEOUT_MS` | Request timeout for worker calls. Default `60000`. |
| `CAPACITY_WORKER_DISABLE_LOCAL_FALLBACK` | `true` to error instead of falling back to local computation. |

---

## Live placement refresh settings

| Variable | Description |
|---|---|
| `LIVE_PLACEMENT_REFRESH_ON_STARTUP` | Run live placement refresh on app start. Default `false`. |
| `LIVE_PLACEMENT_REFRESH_INTERVAL_MINUTES` | Minutes between refreshes. `0` = disabled. |
| `LIVE_PLACEMENT_REFRESH_REGION_PRESET` | Region scope for live refresh. |
| `LIVE_PLACEMENT_REFRESH_DESIRED_COUNT` | Number of placement candidates to score. Default `1`. |

---

## Observability

| Variable | Description |
|---|---|
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | Application Insights connection string — **Key Vault reference in production** |

!!! tip
    See `.env.example` at the repo root for a fully commented template of all variables with their defaults.
