# Environment Variables Reference

All environment variables recognised by the Capacity Planning Dashboard.
Copy `.env.example` to `.env` and fill in the values for local development.
**Never commit `.env` or any file containing real secrets.**

---

## Server

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `PORT` | No | `3000` | HTTP port the Express server listens on. |
| `NODE_ENV` | No | `development` | Node environment. Use `production` for Azure deployments. Affects session store, error verbosity, and SQL session table. |

---

## Authentication (Entra ID / MSAL)

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `AUTH_ENABLED` | No | `false` | Set `true` to enforce Entra ID login. Leave `false` for local dev without credentials. |
| `ENTRA_CLIENT_ID` | If `AUTH_ENABLED=true` | — | Application (client) ID of the Entra app registration. Generate with `scripts/New-EntraApp.ps1`. |
| `ENTRA_TENANT_ID` | If `AUTH_ENABLED=true` | — | Directory (tenant) ID. |
| `ENTRA_CLIENT_SECRET` | If `AUTH_ENABLED=true` | — | Client secret for the Entra app. **In production, inject via Azure Key Vault reference — do not set here.** |
| `ADMIN_GROUP_ID` | No | — | Object ID of the Entra security group whose members get Admin access. Leave empty to allow all authenticated users admin access. |
| `AUTH_REDIRECT_URI` | No | `http://localhost:3000/auth/callback` | OAuth redirect URI registered on the app. For Azure App Service: `https://<app>.azurewebsites.net/auth/callback`. |
| `SESSION_SECRET` | Yes (production) | — | Random secret for express-session cookie signing. Generate: `node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"`. **In production, inject via Azure Key Vault reference.** |
| `SESSION_STORE_SQL_ENABLED` | No | `false` | Set `true` in production to persist sessions to SQL instead of in-memory MemoryStore. Requires `NODE_ENV=production`. |
| `SESSION_STORE_SQL_TABLE` | No | `AppSessions` | SQL table name for session persistence when `SESSION_STORE_SQL_ENABLED=true`. |

---

## Azure SQL

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SQL_SERVER` | Yes | — | Fully qualified SQL Server hostname (e.g. `myserver.database.windows.net`). Also accepted as `Sql__Server`. |
| `SQL_DATABASE` | Yes | — | SQL database name. Also accepted as `Sql__Database`. |
| `SQL_AUTH_MODE` | No | `msi` | Authentication mode. `msi` = Managed Identity (production default). `sql` = SQL username/password (local dev only). Also accepted as `Sql__AuthMode`. |
| `SQL_USER` | If `SQL_AUTH_MODE=sql` | — | SQL login username. Local dev only — never use in production. |
| `SQL_PASSWORD` | If `SQL_AUTH_MODE=sql` | — | SQL login password. Local dev only — never use in production. |
| `SQL_MSI_CLIENT_ID` | No | — | Client ID of the user-assigned managed identity to use for SQL auth. If omitted, uses the system-assigned identity. Also accepted as `Sql__MsiClientId`. |
| `SQL_TRUST_SERVER_CERTIFICATE` | No | `false` | Set `true` to trust self-signed TLS certificates. **Use only for local dev (Docker SQL) and CI. Never set in production.** |
| `SQL_REQUEST_TIMEOUT_MS` | No | `30000` | SQL query request timeout in milliseconds. |

---

## Ingestion

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `INGEST_API_KEY` | Yes (if ingesting) | — | API key for the ingestion endpoint. **In production, inject via Azure Key Vault reference.** |
| `INGEST_REGION_PRESET` | No | `USMajor` | Named preset of Azure regions to ingest. Options: `USMajor`, `All`, custom comma-separated list. |
| `INGEST_SUBSCRIPTION_IDS` | No | — | Comma-separated list of Azure subscription IDs to ingest. If omitted, auto-discovers subscriptions visible to the managed identity. |
| `INGEST_SUBSCRIPTION_HASH_SALT` | No | — | Salt used when hashing subscription IDs in stored data. Set to any random string. |
| `INGEST_ON_STARTUP` | No | `false` | Set `true` to run ingestion immediately on app startup. |
| `INGEST_INTERVAL_MINUTES` | No | `0` | Recurring ingestion interval in minutes. `0` disables scheduled ingestion. |
| `INGEST_QUOTA_FAMILY_FILTERS` | No | — | Comma-separated VM family prefixes to include (e.g. `Standard_D,Standard_E`). If omitted, all families are ingested. |
| `INGEST_MANAGEMENT_GROUP_NAMES` | No | — | Comma-separated management group names to scope subscription discovery. |
| `INGEST_MSI_CLIENT_ID` | No | — | Client ID of user-assigned managed identity for ARM API calls during ingestion. |
| `INGEST_ARM_MAX_RETRIES` | No | `3` | Maximum number of retry attempts for transient ARM API failures (429, 503, network timeout). |
| `INGEST_REGION_CONCURRENCY` | No | — | Number of regions to ingest concurrently. |
| `INGEST_ENABLE_PRICING` | No | `false` | Set `true` to fetch and store VM pricing data during ingestion. |

### AI / Model Catalog Ingestion

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `INGEST_AI_ENABLED` | No | `false` | Enable AI quota ingestion. |
| `INGEST_AI_PROVIDER_QUOTA_ENABLED` | No | `false` | Enable provider-aware AI quota discovery. Keep off until rollout validation is complete. |
| `INGEST_AI_MODEL_CATALOG` | No | `true` | Enable AI model catalog ingestion. |
| `INGEST_AI_MODEL_CATALOG_INTERVAL_MINUTES` | No | `1440` | Interval for AI model catalog refresh in minutes (default: 24 hours). |
| `INGEST_OPENAI_ENABLED` | No | — | Legacy alias for `INGEST_AI_ENABLED`. |
| `INGEST_OPENAI_MODEL_CATALOG` | No | — | Legacy alias for `INGEST_AI_MODEL_CATALOG`. |
| `INGEST_OPENAI_MODEL_CATALOG_INTERVAL_MINUTES` | No | — | Legacy alias for `INGEST_AI_MODEL_CATALOG_INTERVAL_MINUTES`. |

---

## Live Placement Refresh

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `LIVE_PLACEMENT_REFRESH_ON_STARTUP` | No | `false` | Run live placement refresh on app startup. |
| `LIVE_PLACEMENT_REFRESH_INTERVAL_MINUTES` | No | `0` | Recurring live placement refresh interval. `0` disables. |
| `LIVE_PLACEMENT_REFRESH_REGION_PRESET` | No | `USMajor` | Region preset for scheduled live placement refreshes. |
| `LIVE_PLACEMENT_REFRESH_DESIRED_COUNT` | No | `1` | Number of placement results to fetch per SKU. |
| `LIVE_PLACEMENT_REFRESH_SUBSCRIPTION_IDS` | No | — | Comma-separated list of subscriptions. Falls back to `INGEST_SUBSCRIPTION_IDS` if omitted. |
| `LIVE_PLACEMENT_REFRESH_REGION` | No | `all` | Region filter for live placement refresh. |
| `LIVE_PLACEMENT_REFRESH_FAMILY` | No | `all` | VM family filter for live placement refresh. |
| `LIVE_PLACEMENT_REFRESH_AVAILABILITY` | No | `all` | Availability filter for live placement refresh. |
| `LIVE_PLACEMENT_REFRESH_EXTRA_SKUS` | No | — | Comma-separated extra SKUs to include in scheduled refreshes. |

---

## Capacity Worker

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `CAPACITY_WORKER_BASE_URL` | No | — | Base URL of the Azure Functions capacity worker. Required if using the remote worker. |
| `CAPACITY_WORKER_SHARED_SECRET` | No | — | Shared secret for authenticating calls to the capacity worker. |
| `CAPACITY_WORKER_TIMEOUT_MS` | No | `60000` | Timeout for capacity worker HTTP calls in milliseconds. |
| `CAPACITY_WORKER_DISABLE_LOCAL_FALLBACK` | No | `false` | Set `true` to disable local PowerShell fallback when the remote worker is unavailable. |
| `CAPACITY_LIVE_PLACEMENT_USE_WORKER` | No | — | Use the remote capacity worker for live placement scoring. |
| `CAPACITY_LIVE_REFRESH_MAX_CALLS` | No | — | Maximum concurrent ARM API calls during live placement refresh. |
| `CAPACITY_RECOMMEND_MAX_BUFFER_BYTES` | No | — | Maximum buffer size in bytes for recommendation results. |
| `CAPACITY_RECOMMEND_REGION_CONCURRENCY` | No | — | Number of regions to evaluate concurrently for recommendations. |
| `CAPACITY_RECOMMEND_SUBSCRIPTION_ID` | No | — | Subscription ID to use for recommendation queries. |
| `CAPACITY_RECOMMEND_USE_DIRECT_API` | No | — | Bypass the local PowerShell wrapper and call the ARM API directly for recommendations. |
| `CAPACITY_RECOMMEND_WORKER_TIMEOUT_MS` | No | — | Timeout for recommendation worker calls. |
| `CAPACITY_RECOMMEND_WRAPPER_PATH` | No | — | Filesystem path to the recommendation PowerShell wrapper script. |
| `CAPACITY_PAAS_WORKER_TIMEOUT_MS` | No | — | Timeout for PaaS capacity worker calls. |
| `CAPACITY_PAAS_WRAPPER_PATH` | No | — | Filesystem path to the PaaS availability PowerShell wrapper. |
| `CAPACITY_PLACEMENT_WRAPPER_PATH` | No | — | Filesystem path to the live placement PowerShell wrapper. |
| `CAPACITY_RUNTIME_ROOT` | No | — | Root directory for capacity runtime scripts. |
| `CAPACITY_PWSH_PATH` | No | — | Filesystem path to the PowerShell executable. |
| `GET_AZ_PAAS_AVAILABILITY_ROOT` | No | — | Root path for PaaS availability ARM API calls. |
| `GET_AZ_VM_AVAILABILITY_ROOT` | No | — | Root path for VM availability ARM API calls. |

---

## Quota Management

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `QUOTA_MANAGEMENT_GROUP_ID` | No | — | Azure Management Group ID to scope quota discovery. |
| `QUOTA_APPLY_MSI_CLIENT_ID` | No | — | Client ID of user-assigned managed identity for applying quota changes. |
| `QUOTA_WRITE_MSI_CLIENT_ID` | No | — | Client ID of user-assigned managed identity for writing quota data. |

---

## Observability

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | No | — | Azure Application Insights connection string. When set, telemetry, structured events, and request tracking are enabled. **In production, inject via Azure Key Vault reference.** Visible (as a boolean `configured` flag) in `/api/admin/config`. |

---

## SKU Catalog

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SKU_CATALOG_SEED_REGION` | No | — | Azure region used to seed the initial SKU catalog. |
| `SKU_FAMILY_CATALOG_TTL_MS` | No | — | TTL in milliseconds for the in-memory SKU family catalog cache. |

---

## Azure Identity (Local Dev)

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `AZURE_CLIENT_ID` | No | — | Optional: managed identity client ID for local development with `DefaultAzureCredential`. |

---

## Azure App Service (Runtime-Injected)

These variables are injected automatically by the Azure App Service runtime. Do not set them locally.

| Variable | Source | Description |
|----------|--------|-------------|
| `WEBSITE_SITE_NAME` | App Service | The name of the App Service instance. Used in diagnostics. |
| `WEBSITE_INSTANCE_ID` | App Service | Unique instance ID for the running host. |

---

## Quick Reference: What Goes in `.env` vs Key Vault

| Value | Where to set |
|-------|-------------|
| `SESSION_SECRET` | Azure Key Vault secret → Key Vault reference in App Service |
| `ENTRA_CLIENT_SECRET` | Azure Key Vault secret → Key Vault reference in App Service |
| `INGEST_API_KEY` | Azure Key Vault secret → Key Vault reference in App Service |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | Azure Key Vault secret → Key Vault reference in App Service |
| `CAPACITY_WORKER_SHARED_SECRET` | Azure Key Vault secret → Key Vault reference in App Service |
| `SQL_SERVER`, `SQL_DATABASE` | GitHub variable (set by `bicep-deploy.yml`) → App Service env var |
| `AUTH_ENABLED`, `ADMIN_GROUP_ID`, `ENTRA_*` | App Service application settings (non-secret) |
| All other non-secret vars | `.env` locally; App Service application settings in production |
