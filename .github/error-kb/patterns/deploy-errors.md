# Deploy Error Patterns

Recurring failure modes encountered during Azure CI/CD deployments. Each entry maps to a corresponding entry in `errors.json` with the machine-readable signature and resolution steps.

---

## sqlpackage: Unrecognized argument 'publish'

**Error ID:** `sqlpackage-action-publish-syntax`

**Signal:**

```
*** Unrecognized command line argument 'publish'
Missing required argument '<Action>'
```

**Root Cause:**

`dotnet tool install -g microsoft.sqlpackage` on GitHub-hosted ubuntu runners installs a version that uses the **legacy `/Action:` flag syntax**, not the newer `publish` subcommand style. The subcommand style (`sqlpackage publish \`) is only valid in newer CLI builds distributed differently.

**Fix:**

```yaml
# ❌ Wrong — subcommand style fails with dotnet tool install version
- run: |
    sqlpackage publish \
      /SourceFile:schema.dacpac \
      /TargetServerName:...

# ✅ Correct — legacy flag syntax works with dotnet tool install version
- run: |
    sqlpackage /Action:Publish \
      /SourceFile:schema.dacpac \
      /TargetServerName:...
```

**Verified:** `sql-schema.yml`, PR #73, May 2026.

---

## Azure SQL: DenyPublicEndpointEnabled

**Error ID:** `azure-sql-deny-public-endpoint`

**Signal:**

```
DenyPublicEndpointEnabled
```

Or similar message about public network access being disabled, appearing when running `az sql server firewall-rule create`.

**Root Cause:**

Azure SQL Server has `publicNetworkAccess=Disabled` globally. Even with correct RBAC, firewall rules **cannot be added** while public network access is disabled. The two operations are independent — RBAC controls who can manage the server; `publicNetworkAccess` is a server-level network policy.

**This is NOT the same as Storage Account firewall rules**, which use `networkRuleSet.defaultAction`. The APIs are entirely different.

**Fix:**

```yaml
- name: Open SQL firewall for runner
  run: |
    RUNNER_IP=$(curl -s https://api.ipify.org)
    echo "RUNNER_IP=$RUNNER_IP" >> "$GITHUB_ENV"
    # Step 1: Enable public network access on the server
    az sql server update \
      --name "$SQL_SERVER" \
      --resource-group "$RESOURCE_GROUP" \
      --set publicNetworkAccess=Enabled \
      --output none
    # Step 2: Add the specific IP rule
    az sql server firewall-rule create \
      --resource-group "$RESOURCE_GROUP" \
      --server "$SQL_SERVER" \
      --name "github-runner-${{ github.run_id }}" \
      --start-ip-address "$RUNNER_IP" \
      --end-ip-address "$RUNNER_IP" \
      --output none

- name: Close SQL firewall
  if: always()
  run: |
    az sql server firewall-rule delete \
      --resource-group "$RESOURCE_GROUP" \
      --server "$SQL_SERVER" \
      --name "github-runner-${{ github.run_id }}" \
      --yes 2>/dev/null || true
    az sql server update \
      --name "$SQL_SERVER" \
      --resource-group "$RESOURCE_GROUP" \
      --set publicNetworkAccess=Disabled \
      --output none 2>/dev/null || true
```

**Key:** The cleanup step (firewall close) must use `if: always()` and must restore `publicNetworkAccess=Disabled` even if the main step failed.

**Verified:** `sql-schema.yml`, PR #72, May 2026.

---

## GitHub Actions: Job guard if: fails with environment-scoped variable

**Error ID:** `github-actions-job-if-env-var-scope`

**Signal:**

Deploy job is unexpectedly skipped, even though the required variable is set. The condition evaluates to false.

**Root Cause:**

Job-level `if:` conditions are evaluated **before** the `environment:` block loads. Variables and secrets scoped to a GitHub Environment are not available at job guard evaluation time — they are injected only once the job starts executing.

**This affects any variable set at the Environment level (Settings > Environments) but not at the Repository level.**

**Fix:**

```yaml
# ❌ Wrong — MY_VAR is set only in the "production" Environment,
# not available when the if: is evaluated
jobs:
  deploy:
    environment: production
    if: ${{ vars.MY_VAR != '' }}  # always empty — env not loaded yet

# ✅ Correct — set MY_VAR at BOTH levels:
# - Repository level: used by the job if: guard
# - Environment level (optional): overrides the value within the environment
jobs:
  deploy:
    environment: production
    if: ${{ vars.MY_VAR != '' }}  # works — reads from repo-level var
```

**How to set at both levels:**

1. Go to repo **Settings > Secrets and variables > Actions > Variables**
2. Create `MY_VAR` as a **Repository variable** (so it's visible to job guards)
3. Optionally also create `MY_VAR` under **Settings > Environments > [env-name] > Variables** to allow env-specific overrides during job execution

**Verified:** `deploy.yml` preflight job, PR #71, May 2026.

---

## Azure App Service: Site returns 503 / Application Error

**Error ID:** `appservice-503-application-error`

**Signal:**

```
HTTP 503 Service Unavailable
Application Error — An error occurred while starting the application.
```

Or the site loads a default Azure "App Service" placeholder page instead of your app.

**Decision tree:**

```
503 after deploy?
├─ Yes → check deployment logs first
│   └─ az webapp log deployment show --name <app> --resource-group <rg>
├─ Site never loads (not after deploy) → check if app process crashed
│   └─ az webapp log tail --name <app> --resource-group <rg>
└─ Intermittent / occasional → check health check endpoint and slot state
```

**Step 1 — Stream live logs**

```bash
az webapp log tail \
  --name <app-name> \
  --resource-group <resource-group>
```

Look for:
- `Error: Cannot find module` → missing dependency, `npm install` didn't run
- `EADDRINUSE` → port conflict; ensure app listens on `process.env.PORT`
- `getaddrinfo ENOTFOUND` → wrong DATABASE_SERVER or connection string
- `Login failed for user` → database credentials wrong in App Settings
- Exit code immediately after start → unhandled error in startup path

**Step 2 — Check App Settings (environment variables)**

```bash
az webapp config appsettings list \
  --name <app-name> \
  --resource-group <resource-group> \
  --output table
```

Verify all required variables are present. A missing `SESSION_SECRET`, `DATABASE_SERVER`,
or `AZURE_CLIENT_ID` will cause silent startup failures.

**Step 3 — Restart vs. redeploy decision**

| Situation | Action |
|---|---|
| App crashed after a bad deploy | Redeploy previous known-good artifact |
| Config/env var changed | Restart only: `az webapp restart --name <app> --resource-group <rg>` |
| Transient crash (OOM, timeout) | Restart only |
| Dependency missing (`Cannot find module`) | Redeploy — restart won't fix missing node_modules |
| Wrong startup command | Update `az webapp config set --startup-file` then restart |

**Step 4 — Restart**

```bash
az webapp restart \
  --name <app-name> \
  --resource-group <resource-group>
```

Wait 30–60s then test the health endpoint.

**Step 5 — Verify health endpoint**

```bash
curl -s -o /dev/null -w "%{http_code}" https://<app-name>.azurewebsites.net/health
```

Expected: `200`. If still failing, redeploy from last known-good release.

**Step 6 — Redeploy last known-good**

```bash
# Re-trigger the last successful deploy workflow run
gh run rerun <run-id> --repo OWNER/REPO

# Or deploy a specific image/artifact manually
az webapp deployment source config-zip \
  --name <app-name> \
  --resource-group <resource-group> \
  --src <artifact.zip>
```

**Prevention:**

- Add a `/health` endpoint that returns `200` with `{ "status": "ok" }` — App Service can
  use this as the health check probe (`az webapp config set --generic-configurations`)
- Set `WEBSITE_NODE_DEFAULT_VERSION` App Setting to match local Node version
- Ensure `npm install --production` (or equivalent) runs as part of the deploy step,
  not just `npm ci` in CI — the app needs its deps in the deployed artifact

**Verified:** Deploy workflow, site down incidents May 2026.
