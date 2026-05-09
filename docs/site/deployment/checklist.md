# First-Run Checklist

Use this checklist after a fresh Bicep deploy to verify the environment is fully operational.

---

## Pre-deploy

- [ ] **Bootstrap script run** — `scripts/bootstrap-github-oidc.ps1` completed successfully
- [ ] **GitHub secrets set** — `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` present in repo settings
- [ ] **`production` environment exists** — GitHub repo → Settings → Environments → `production`
- [ ] **Bicep parameter file updated** — `infra/bicep/params/prod.bicepparam` contains your values
- [ ] **Entra app registered** — `scripts/New-EntraApp.ps1` run; `ENTRA_CLIENT_ID` / `ENTRA_CLIENT_SECRET` obtained

---

## After first Bicep deploy

- [ ] **Deployment succeeded** — `bicep-deploy.yml` workflow shows green
- [ ] **GitHub repo variables populated** — `WEBAPP_NAME`, `SQL_SERVER_NAME`, `SQL_DATABASE_NAME`, `KEY_VAULT_NAME` visible in repo variables
- [ ] **Key Vault secrets set** — create these secrets manually in the Key Vault (or via `az keyvault secret set`):

  | Secret name | Value |
  |---|---|
  | `capdash-session-secret` | 32-byte random hex (`node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"`) |
  | `capdash-ingest-api-key` | Shared secret for worker → API calls |
  | `capdash-worker-shared-secret` | Shared secret for API → worker calls |

- [ ] **App Settings configured** — verify these are set on the App Service (Bicep should set them; verify in portal → Configuration):

  | Setting | Expected value |
  |---|---|
  | `NODE_ENV` | `production` |
  | `AUTH_ENABLED` | `true` |
  | `ENTRA_CLIENT_ID` | App registration client ID |
  | `ENTRA_TENANT_ID` | Entra tenant ID |
  | `ENTRA_CLIENT_SECRET` | Key Vault reference: `@Microsoft.KeyVault(...)` |
  | `SESSION_SECRET` | Key Vault reference |
  | `INGEST_API_KEY` | Key Vault reference |
  | `SQL_SERVER` | `<server>.database.windows.net` |
  | `SQL_DATABASE` | `CapacityDashboard` |
  | `SQL_AUTH_MODE` | `msi` |
  | `QUOTA_MANAGEMENT_GROUP_ID` | Your root management group ID |
  | `CAPACITY_WORKER_BASE_URL` | Function App URL |
  | `CAPACITY_WORKER_SHARED_SECRET` | Key Vault reference |
  | `APPLICATIONINSIGHTS_CONNECTION_STRING` | Key Vault reference or direct string |

---

## Smoke test

- [ ] **Health check** — `GET https://<webapp>.azurewebsites.net/healthz` returns `{ "status": "ok" }`
- [ ] **Login works** — navigate to the app URL and sign in with an Entra account
- [ ] **Capacity tab loads** — capacity explorer renders (may show empty until ingestion runs)
- [ ] **Ingest runs** — Admin panel → Ingestion → Run Now → check for success
- [ ] **Capacity data appears** — refresh capacity explorer, confirm rows appear

---

## Post-deploy automation

Consider scheduling a first ingestion to run immediately after deploy. The `INGEST_ON_STARTUP=true` env var triggers ingestion when the App Service starts.

!!! tip
    Set `INGEST_ON_STARTUP=true` in the Bicep parameters for the first deploy, then revert — this ensures data is populated before the first user visits the site.
