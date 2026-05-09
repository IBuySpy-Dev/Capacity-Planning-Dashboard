# Release Verification Checklist

**Audience:** Release engineer or on-call operator  
**Purpose:** Gate-check before merge to `main` and verify a successful production deployment  
**Estimated time:** 15–20 minutes  
**Related:** [Rollback Playbook](./rollback-playbook.md) | [CI/CD Reference](../GITHUB-ACTIONS.md) | [First Deployment Runbook](../FIRST-DEPLOYMENT-RUNBOOK.md)

---

## 1. Pre-Deploy Gates

Complete every item before merging the PR to `main`. A failed gate blocks the merge.

### 1.1 CI Pipeline

| Check | Command / Location | Pass Criteria |
|---|---|---|
| CI workflow is green | GitHub Actions → **CI** tab for the PR | All jobs pass (`npm ci`, `npm test`) |
| No skipped tests | CI run logs | Zero skipped or pending test cases |
| Branch is up to date with `main` | GitHub PR page | "This branch has no conflicts with the base branch" |

### 1.2 Code Review

| Check | Location | Pass Criteria |
|---|---|---|
| PR approved | GitHub PR → Reviews | ≥ 1 approving review |
| All review comments resolved | GitHub PR → Conversations | 0 unresolved threads |
| No `TODO` / `FIXME` left in touched files | `grep -r "TODO\|FIXME" src/ server.js app.js` | Returns nothing |

### 1.3 Secrets and Configuration

| Check | How to verify | Pass Criteria |
|---|---|---|
| Required GitHub secrets present | `gh secret list --repo ivegamsft/Capacity-Planning-Dashboard` | `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` visible |
| Required GitHub variables present | `gh api repos/ivegamsft/Capacity-Planning-Dashboard/actions/variables --jq '.variables[].name'` | `AZURE_RESOURCE_GROUP`, `AZURE_SUBSCRIPTION_ID` present |
| No secrets committed in diff | Review PR file changes | No plaintext credentials or connection strings |

### 1.4 Database Migration Review

| Check | How to verify | Pass Criteria |
|---|---|---|
| Migration scripts reviewed | Inspect any new files under `sql/` | Scripts are idempotent; no destructive `DROP` without guard |
| Migration tested against staging | Manual run or staging deploy | Script completes without error in a non-prod environment |

---

## 2. Merge and Deploy Trigger

Once all pre-deploy gates pass:

```bash
# Merge via GitHub UI (squash or merge commit — do not rebase)
gh pr merge <PR_NUMBER> --repo ivegamsft/Capacity-Planning-Dashboard --squash

# Verify the deploy workflow fired
gh run list --repo ivegamsft/Capacity-Planning-Dashboard --workflow deploy.yml --limit 3
```

The `Deploy Capacity Dashboard` workflow starts automatically on push to `main`.  
Monitor it at: **GitHub Actions → Deploy Capacity Dashboard → latest run**

---

## 3. Post-Deploy Smoke Tests

Run the following checks in order within **10 minutes** of the deploy workflow completing.

### 3.1 Workflow Completion Check

```bash
# Wait for the run to finish and confirm success
gh run watch --repo ivegamsft/Capacity-Planning-Dashboard
```

Expected final status: **Success** on all jobs (`build-and-test` and `deploy`).

### 3.2 App Service Health Check

```powershell
$appUrl = "https://app-capdash-prod-prod01.azurewebsites.net"

# Health probe — deploy.yml polls /healthz; returns 2xx on success
$response = Invoke-WebRequest -Uri "$appUrl/healthz" -UseBasicParsing -ErrorAction Stop
Write-Host "HTTP $($response.StatusCode) — $($response.StatusDescription)"
```

**Pass criteria:** HTTP `200` (or any `2xx`) within 30 seconds.  
**If it fails:** See [Rollback Playbook](./rollback-playbook.md) → Step 1.

### 3.3 Application Reachability

```powershell
# Main dashboard page must load
$r = Invoke-WebRequest -Uri "https://app-capdash-prod-prod01.azurewebsites.net" -UseBasicParsing
Write-Host "HTTP $($response.StatusCode)"
```

**Pass criteria:** HTTP `200`; page body contains `Capacity Planning`.

### 3.4 SQL Migration Verification

Confirm the migration ran and logged to the operation log table:

```sql
-- Run in Azure SQL: sqldb-capdash-prod (sql-capdash-prod-prod01)
SELECT TOP 5
    OperationName,
    OperationStatus,
    OperationMessage,
    CreatedAt
FROM dbo.DashboardOperationLog
ORDER BY CreatedAt DESC;
```

**Pass criteria:**  
- At least one row with `OperationName` matching the migration or bootstrap step executed in this release  
- `OperationStatus` = `Success` (or equivalent success value for your schema)  
- No rows with `OperationStatus` = `Error` from the current deploy timestamp

> **Note:** If `dbo.DashboardOperationLog` does not yet exist in your environment, the SQL bootstrap step in `scripts/bootstrap-sql-managed-identity.ps1` should create it on first run. Verify the bootstrap job in the deploy workflow completed without error.

### 3.5 API Endpoint Spot-Check

```powershell
$base = "https://app-capdash-prod-prod01.azurewebsites.net"

# Check a representative data endpoint
Invoke-WebRequest -Uri "$base/api/capacity" -UseBasicParsing | Select-Object StatusCode
```

**Pass criteria:** HTTP `200` with a JSON body containing capacity data. HTTP `401`/`403` is also acceptable if the endpoint requires auth — confirm the auth error is expected, not a broken middleware response.

---

## 4. Sign-Off

Once all smoke tests pass, record sign-off in the GitHub PR or the linked issue.

```
### Release Sign-Off

- **Release date:** YYYY-MM-DD HH:MM UTC
- **Deploy workflow run:** <link to GitHub Actions run>
- **Health check:** PASS — HTTP 200 from /healthz
- **SQL migration:** PASS — logged to DashboardOperationLog at <timestamp>
- **Signed off by:** @<github-username>
```

> Post the sign-off as a comment on the PR and close issue #5 (or the relevant tracking issue) once production is confirmed healthy.

---

## 5. Known Gaps and Limitations

| Gap | Impact | Recommended action |
|---|---|---|
| No dedicated `/health` route in `server.js` | The `/healthz` endpoint used by `deploy.yml` may return a `302` redirect or an app-specific error rather than a purpose-built health response | Add a `GET /healthz` route to `server.js` that returns `{"status":"ok"}` with HTTP 200 — track in a follow-up issue |
| Smoke tests are manual | Human error in the verification step | Consider automating post-deploy smoke tests via a GitHub Actions post-deploy job |
| No staging environment in pipeline | Migrations cannot be fully pre-validated | Add a `staging` environment and deploy gate before production |

---

*See also: [Rollback Playbook](./rollback-playbook.md) — use immediately if any smoke test fails.*
