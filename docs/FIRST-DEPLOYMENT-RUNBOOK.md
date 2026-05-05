# First Deployment Runbook

## Overview

This document provides the exact sequence to perform the first deployment of the Capacity Planning Dashboard to Azure using GitHub Actions with OIDC authentication.

**Estimated time:** 15-30 minutes (depending on CA policy approval)

## Prerequisites

- Azure subscription with available capacity
- GitHub repository with Actions enabled
- Azure CLI (`az`) installed and authenticated (`az login`)
- GitHub CLI (`gh`) installed and authenticated (`gh auth login`)
- Permissions: Azure subscription admin, Azure AD admin, GitHub repo admin

## Deployment Sequence

### Phase 1: Pre-Deployment Bootstrap (Local Machine)

**Duration:** 5-10 minutes

#### Step 1.1: Run OIDC Bootstrap
```powershell
cd F:\Git\Capacity-Planning-Dashboard

# This creates the service principal and configures GitHub
.\scripts\bootstrap-github-oidc.ps1 `
  -SubscriptionId "844eabcc-dc96-453b-8d45-bef3d566f3f8" `
  -ResourceGroupName "rg-capdash-prod" `
  -GitHubOrganization "IBuySpy-Dev" `
  -GitHubRepository "Capacity-Planning-Dashboard"
```

**Expected output:**
- ✓ Service principal created (github-oidc-capdash)
- ✓ Federated credentials configured
- ✓ GitHub environment variables set
- ✓ Verification commands provided

**Verify:** 
```powershell
# Confirm environment was created
gh api repos/IBuySpy-Dev/Capacity-Planning-Dashboard/environments --jq '.[].name'
# Should show: production
```

#### Step 1.2: Diagnose Conditional Access Policy
```powershell
# Check current CA policy status
.\scripts\bootstrap-ca-policy.ps1 -Mode check
```

**Expected output:**
- Lists all Conditional Access policies
- Shows service principal details
- Provides guidance on where exclusions need to be added

**If AADSTS53003 error is mentioned:** Proceed to Step 1.3

#### Step 1.3: Create CA Policy Exception

**Option A: Manual (if admin prefers)**
```powershell
# Shows step-by-step manual instructions
.\scripts\bootstrap-ca-policy.ps1 -Mode exempt
```

Follow the instructions to:
1. Go to Azure Portal → Azure AD → Conditional Access → Policies
2. For each policy that blocks token issuance:
   - Click policy name
   - Go to "Users or workload identities" → "Exclude"
   - Search for: `github-oidc-capdash`
   - Add to exclusions
   - Save policy

**Option B: Guided (if automated steps available)**
```powershell
# Attempts to create and configure policy programmatically
.\scripts\bootstrap-ca-policy.ps1 -Mode create-exception
```

**Note:** Typically requires Azure AD admin approval. May need to open Azure Portal and approve/complete the policy modification.

#### Step 1.4: Verify OIDC Token Exchange Works
```powershell
# Tests that the GitHub token can be exchanged for an Azure token
.\scripts\bootstrap-ca-policy.ps1 -Mode verify
```

**Expected output:**
- ✓ Successfully exchanged GitHub token
- ✓ Received Azure access token
- ✓ Service principal ready for deployment

**Troubleshooting:** If this fails, go back to Step 1.3 - CA policy may not be fully configured.

---

### Phase 2: GitHub Actions Deployment (Automated)

**Duration:** 5-15 minutes (automatic)

#### Step 2.1: Trigger Deployment Workflow

```powershell
# Trigger the deployment workflow
gh workflow run deploy.yml `
  --repo IBuySpy-Dev/Capacity-Planning-Dashboard `
  -f environment=prod
```

Or use the orchestration script:
```powershell
# Orchestrates everything and can trigger deployment
.\scripts\bootstrap-and-deploy.ps1 `
  -SkipOIDC `
  -SkipCAPolicy `
  -TriggerDeployment `
  -WaitForDeployment
```

**Expected:** Workflow queued message

#### Step 2.2: Monitor Deployment

Watch the workflow run:
```powershell
# Shows workflow status
gh run list --repo IBuySpy-Dev/Capacity-Planning-Dashboard --workflow=deploy.yml --limit=1

# Watch live logs
gh run watch --repo IBuySpy-Dev/Capacity-Planning-Dashboard
```

**Workflow steps (in order):**
1. ✓ Checkout code
2. ✓ Setup Node.js
3. ✓ Install dependencies
4. ✓ Run tests
5. ✓ Azure Login (OIDC)
6. ✓ Create deployment package
7. ✓ Deploy to App Service
8. ✓ Bootstrap SQL Database for Managed Identity ← **NEW: With error checking**
9. ✓ Restart App Service
10. ✓ Wait for App Service to be ready ← **NEW: Health check**
11. ✓ Verify deployment

**If any step fails:**
- Check the step logs in GitHub Actions
- Resolve the issue
- Re-run the workflow: `gh run rerun {run-id}`

---

### Phase 3: Post-Deployment Verification

**Duration:** 5-10 minutes

#### Step 3.1: Verify App Service is Running
```powershell
# Check app service status
az webapp show `
  --resource-group rg-capdash-prod `
  --name app-capdash-prod-prod01 `
  --query "state"

# Should return: "Running"
```

#### Step 3.2: Test API Endpoints
```powershell
$appUrl = "https://app-capdash-prod-prod01.azurewebsites.net"

# Test subscriptions endpoint
$response = Invoke-WebRequest -Uri "$appUrl/api/subscriptions" -UseBasicParsing
Write-Host "Subscriptions endpoint: $($response.StatusCode)"

# Test capacity endpoint
$response = Invoke-WebRequest -Uri "$appUrl/api/capacity" -UseBasicParsing
Write-Host "Capacity endpoint: $($response.StatusCode)"

# Test analytics endpoint
$response = Invoke-WebRequest -Uri "$appUrl/api/analytics" -UseBasicParsing
Write-Host "Analytics endpoint: $($response.StatusCode)"
```

**Expected:** All return HTTP 200

#### Step 3.3: Verify React UI
1. Open browser: `https://app-capdash-prod-prod01.azurewebsites.net`
2. Confirm page loads (should see Capacity Dashboard or login page)
3. Login with Azure AD credentials
4. Verify subscription and capacity data displays

#### Step 3.4: Check SQL Managed Identity Configuration
```powershell
# Verify SQL database user was created
az sql server ad-admin list `
  --resource-group rg-capdash-prod `
  --server-name sql-capdash-prod-prod01

# Verify app service managed identity was assigned
az identity show `
  --resource-group rg-capdash-prod `
  --name app-capdash-prod-prod01 \
  --query id
```

#### Step 3.5: Review Application Insights Logs
```powershell
# Check for errors in Application Insights
az monitor app-insights metrics show \
  --resource-group rg-capdash-prod \
  --app app-capdash-prod-prod01 \
  --metric "requests/failed" \
  --interval PT1H
```

---

## Troubleshooting

### AADSTS53003 Error During Deployment

**Problem:** Workflow fails at "Azure Login (OIDC)" step with AADSTS53003

**Cause:** Conditional Access policy blocking GitHub OIDC service principal

**Solution:**
1. Run CA policy diagnostic: `.\scripts\bootstrap-ca-policy.ps1 -Mode check`
2. Exempt service principal: `.\scripts\bootstrap-ca-policy.ps1 -Mode exempt`
3. Wait 2-3 minutes for policy to apply
4. Re-run deployment: `gh run rerun {run-id}`

### SQL Bootstrap Fails

**Problem:** Workflow fails at "Bootstrap SQL Database for Managed Identity" step

**Cause:** Service principal doesn't have proper permissions or SQL server is misconfigured

**Solution:**
1. Check error message in workflow logs
2. Verify service principal has Contributor role: `az role assignment list --resource-group rg-capdash-prod`
3. Verify SQL server allows Azure AD authentication
4. Check SQL error logs: `az sql server ad-admin list --resource-group rg-capdash-prod --server-name sql-capdash-prod-prod01`

### App Service Won't Become Ready

**Problem:** Workflow completes "Restart App Service" but times out on "Wait for App Service to be ready"

**Cause:** App is taking too long to start or startup errors

**Solution:**
1. SSH into app service: `az webapp create-remote-connection --resource-group rg-capdash-prod --name app-capdash-prod-prod01`
2. Check application logs
3. Verify environment variables are set correctly
4. Check if Node.js process is running

### Cannot Login to React UI After Deployment

**Problem:** App loads but login fails

**Cause:** Entra ID configuration issue or missing redirect URI

**Solution:**
1. Verify Entra ID app registration is configured
2. Check redirect URI includes `https://app-capdash-prod-prod01.azurewebsites.net/auth/callback`
3. Verify API permissions are granted
4. Check Application Insights for authentication errors

---

## Rollback Procedure

If deployment fails and needs to be rolled back:

```powershell
# Get previous deployment slot
az webapp deployment slot list \
  --resource-group rg-capdash-prod \
  --name app-capdash-prod-prod01

# Swap back to previous version if available
az webapp deployment slot swap \
  --resource-group rg-capdash-prod \
  --name app-capdash-prod-prod01 \
  --slot staging

# Or restart from last known good state
az webapp restart \
  --resource-group rg-capdash-prod \
  --name app-capdash-prod-prod01
```

---

## Subsequent Deployments

After the first deployment succeeds, subsequent deployments are automatic:

```powershell
# Simply push to main branch - workflow triggers automatically
git push origin main

# Or manually trigger:
gh workflow run deploy.yml --repo IBuySpy-Dev/Capacity-Planning-Dashboard -f environment=prod
```

No bootstrap steps needed on subsequent deployments - OIDC federation and CA policy exception remain in place.

---

## Reference Commands

### Get App Service URL
```powershell
az webapp show `
  --resource-group rg-capdash-prod `
  --name app-capdash-prod-prod01 `
  --query "defaultHostName"
```

### Check Deployment Status
```powershell
gh run list --repo IBuySpy-Dev/Capacity-Planning-Dashboard --workflow=deploy.yml
```

### View Workflow Logs
```powershell
gh run view {run-id} --repo IBuySpy-Dev/Capacity-Planning-Dashboard --log
```

### Access SQL Database
```powershell
# Connect via SQL Server Management Studio (if installed)
# Server: sql-capdash-prod-prod01.database.windows.net
# Database: sqldb-capdash-prod
# Auth: Azure AD - Integrated
# User: app-capdash-prod-prod01 (managed identity)
```

---

## Success Criteria

Deployment is successful when:

- ✅ GitHub Actions workflow completes with all green checkmarks
- ✅ App Service is running and responsive (HTTP 200)
- ✅ All API endpoints return data (HTTP 200)
- ✅ React UI loads and displays subscription/capacity data
- ✅ SQL database queries execute through managed identity
- ✅ No errors in Application Insights
- ✅ Users can login with Azure AD credentials

---

## Timeline

| Phase | Task | Time | Status |
|-------|------|------|--------|
| 1 | OIDC Bootstrap | 2 min | Completed ✓ |
| 1 | CA Policy Diagnostic | 2 min | Ready |
| 1 | CA Policy Exception | 5-10 min | **Awaiting admin** |
| 1 | OIDC Verification | 2 min | Awaiting CA policy |
| 2 | Trigger Deployment | 1 min | Awaiting CA policy |
| 2 | Monitor Workflow | 10-15 min | Awaiting trigger |
| 3 | Verify Endpoints | 5 min | Awaiting deployment |
| 3 | Test React UI | 5 min | Awaiting deployment |
| 3 | Review Logs | 5 min | Awaiting deployment |

---

## Support

For issues or questions:
1. Check troubleshooting section above
2. Review Application Insights logs
3. Check GitHub Actions workflow logs
4. Contact: Azure AD admin or platform team

