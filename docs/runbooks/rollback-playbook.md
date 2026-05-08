# Rollback Playbook

**Audience:** On-call operator or release engineer  
**Purpose:** Restore the production Capacity Planning Dashboard to a known-good state after a failed or bad deployment  
**Estimated time:** 10–20 minutes  
**Related:** [Release Verification Checklist](./release-verification.md) | [CI/CD Reference](../GITHUB-ACTIONS.md) | [First Deployment Runbook](../FIRST-DEPLOYMENT-RUNBOOK.md)

---

## When to Use This Playbook

Initiate rollback when **any** of the following are true after a production deployment:

| Signal | Threshold |
|---|---|
| `/healthz` returns non-2xx after 3 consecutive retries | Immediate |
| Main dashboard page (HTTP 200) not reachable | Immediate |
| SQL migration failed or left the DB in a partial state | Immediate |
| Critical business functionality broken | Within 5 minutes of detection |
| Elevated error rate in App Service logs | Operator judgment |

**Do not wait.** A rollback costs less than extended downtime. If unsure, roll back and investigate from a stable baseline.

---

## Prerequisites

Before starting, confirm you have:

- [ ] Azure CLI installed and authenticated (`az login` or OIDC token active in your shell)
- [ ] GitHub CLI installed and authenticated (`gh auth login`)
- [ ] Access to the Azure portal or the ability to run `az` commands against subscription `AZURE_SUBSCRIPTION_ID`
- [ ] Access to the SQL database (`sqldb-capdash-prod` on `sql-capdash-prod-prod01`) via SSMS, Azure Data Studio, or `sqlcmd`

**Key resource names:**

| Resource | Value |
|---|---|
| App Service name | `app-capdash-prod-prod01` |
| Resource group | `rg-capdash-prod` (verify via `az webapp show --name app-capdash-prod-prod01 --query resourceGroup`) |
| SQL Server | `sql-capdash-prod-prod01` |
| SQL Database | `sqldb-capdash-prod` |
| GitHub repo | `ivegamsft/Capacity-Planning-Dashboard` |
| Health endpoint | `https://app-capdash-prod-prod01.azurewebsites.net/healthz` |

---

## Rollback Steps

### Step 1 — Confirm the Failure

Do not skip this step. Misidentifying a transient hiccup as a deployment failure wastes time and triggers an unnecessary rollback.

```powershell
# Attempt /healthz up to 5 times, 10 seconds apart
$url = "https://app-capdash-prod-prod01.azurewebsites.net/healthz"
for ($i = 1; $i -le 5; $i++) {
    try {
        $r = Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction Stop -TimeoutSec 10
        Write-Host "Attempt $i — HTTP $($r.StatusCode) — OK"
        break
    } catch {
        Write-Host "Attempt $i — FAILED: $($_.Exception.Message)"
        Start-Sleep -Seconds 10
    }
}
```

**Continue with rollback only if** you see 3+ consecutive failures, or the app is returning 5xx errors consistently.

Check the deploy workflow logs for the failing step:

```bash
# Find the latest deploy run and print its job status
gh run list --repo ivegamsft/Capacity-Planning-Dashboard --workflow deploy.yml --limit 5
gh run view <RUN_ID> --repo ivegamsft/Capacity-Planning-Dashboard --log-failed
```

---

### Step 2 — Identify the Last Known-Good Commit

```bash
# List recent commits on main to find the previous stable SHA
gh api repos/ivegamsft/Capacity-Planning-Dashboard/commits \
  --jq '.[].sha + " " + .[].commit.message' | head -10
```

Note the SHA immediately **before** the failing commit. This is your rollback target (`<GOOD_SHA>`).

Alternatively, find the last successful deploy run and its associated commit:

```bash
gh run list --repo ivegamsft/Capacity-Planning-Dashboard \
  --workflow deploy.yml \
  --status success \
  --limit 3 \
  --json headSha,displayTitle,createdAt
```

---

### Step 3 — Redeploy the Known-Good Commit

#### Option A: Manual workflow dispatch (preferred)

Re-trigger the deploy workflow pointing at the known-good SHA:

```bash
# Trigger a manual deployment from the stable commit
gh workflow run deploy.yml \
  --repo ivegamsft/Capacity-Planning-Dashboard \
  --field environment=prod \
  --ref <GOOD_SHA>
```

Monitor the run:

```bash
gh run watch --repo ivegamsft/Capacity-Planning-Dashboard
```

#### Option B: Revert commit and push to main

If the bad commit cannot be cleanly re-triggered via dispatch:

```bash
# Create a revert commit on main (requires push access to main)
git checkout main
git pull origin main
git revert <BAD_COMMIT_SHA> --no-edit
git push origin main
```

This automatically triggers the `deploy.yml` workflow via the `push` to `main` trigger.

> **Important:** Use `git revert` (creates a new commit), not `git reset --hard` (rewrites history). Rewriting history on `main` is prohibited under the project's governance rules.

---

### Step 4 — Verify the Rollback

After the rollback deploy workflow completes, re-run the full smoke test suite from the [Release Verification Checklist](./release-verification.md) §3, or at minimum:

```powershell
$base = "https://app-capdash-prod-prod01.azurewebsites.net"

# 1. Health check
$h = Invoke-WebRequest -Uri "$base/healthz" -UseBasicParsing
Write-Host "Health: HTTP $($h.StatusCode)"

# 2. Homepage reachability
$home = Invoke-WebRequest -Uri $base -UseBasicParsing
Write-Host "Homepage: HTTP $($home.StatusCode)"

# 3. Spot-check API
$api = Invoke-WebRequest -Uri "$base/api/capacity" -UseBasicParsing
Write-Host "API /capacity: HTTP $($api.StatusCode)"
```

**All three must return 2xx.** If the rollback deploy itself fails, escalate immediately (see §Escalation Contacts).

---

### Step 5 — Address Database State

SQL migrations are **not automatically reversed** by a code rollback. Assess the migration state:

#### If the migration failed mid-run

The migration script (`scripts/bootstrap-sql-managed-identity.ps1`) is designed to be idempotent — re-running it against the previous code state is usually safe. Confirm with:

```sql
-- Check migration log for partial or failed operations
SELECT TOP 20
    OperationName,
    OperationStatus,
    OperationMessage,
    CreatedAt
FROM dbo.DashboardOperationLog
ORDER BY CreatedAt DESC;
```

Look for rows with `OperationStatus` indicating failure. If partial schema changes were applied, you must manually reverse them using the inverse SQL before the rollback deploy goes live.

#### If the migration succeeded but is incompatible with the rolled-back code

This is the most complex scenario. Options in order of preference:

1. **Add a compatibility shim** in the previous code version to tolerate the new schema (preferred — no data risk)
2. **Apply a compensating migration** that reverts the schema to the state expected by the old code
3. **Restore from a database backup** — last resort; coordinate with the DBA and notify affected users of data loss window

```powershell
# List available automated backups (retention: 7–35 days depending on tier)
az sql db list-restore-points \
  --name sqldb-capdash-prod \
  --server sql-capdash-prod-prod01 \
  --resource-group rg-capdash-prod \
  --output table
```

> **Warning:** Database restore to a point-in-time will cause data loss for writes between the restore point and now. Always attempt schema-level remediation first.

---

## Escalation Contacts

If rollback does not restore service within **20 minutes**, escalate:

| Role | Contact | When to escalate |
|---|---|---|
| Repository owner | `@ivegamsft` (GitHub) | Rollback workflow fails or push to main is blocked |
| Azure subscription admin | *(add contact)* | Azure resource errors, firewall issues, OIDC failures |
| Database administrator | *(add contact)* | Partial migrations, database restore required |
| Product owner | *(add contact)* | Extended outage >30 minutes; customer impact |

> **Action required:** Replace `*(add contact)*` placeholders with actual names, aliases, or on-call rotation links before this playbook goes live in production.

---

## Post-Rollback Review

Within 24 hours of a rollback, open a post-incident review issue:

```bash
gh issue create \
  --repo ivegamsft/Capacity-Planning-Dashboard \
  --title "PIR: Rollback triggered on <DATE> — <SHORT_DESCRIPTION>" \
  --label "incident,documentation" \
  --body "## What happened
<describe the failing deployment>

## Impact
<duration, affected features, user impact>

## Root cause
<initial hypothesis>

## Rollback actions taken
<steps executed, time taken>

## Prevention
<what change would prevent recurrence>
"
```

---

*See also: [Release Verification Checklist](./release-verification.md) — run the full smoke test suite after rollback is complete.*
