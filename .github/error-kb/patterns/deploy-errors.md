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
