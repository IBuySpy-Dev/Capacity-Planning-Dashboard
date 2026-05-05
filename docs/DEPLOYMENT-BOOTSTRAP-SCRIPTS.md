# Pre-Deployment Bootstrap Scripts Summary

## Problem
Deployment requires handling Azure AD Conditional Access policies before the GitHub Actions workflow can exchange OIDC tokens for Azure credentials. The policy check (AADSTS53003 error) needs to be resolved before deployment.

## Solution: Separate Bootstrap Scripts

Created three complementary bootstrap scripts that can run independently before deployment:

### 1. bootstrap-github-oidc.ps1
**Purpose:** Initial one-time setup of GitHub OIDC federation

**When to run:** First deployment only (or when resetting OIDC)

**What it does:**
- Creates Azure AD service principal
- Configures federated credentials for GitHub Actions
- Sets GitHub environment variables
- Outputs workflow configuration

**Command:**
```powershell
.\scripts\bootstrap-github-oidc.ps1 `
  -SubscriptionId "844eabcc-dc96-453b-8d45-bef3d566f3f8" `
  -ResourceGroupName "rg-capdash-prod" `
  -GitHubOrganization "IBuySpy-Dev" `
  -GitHubRepository "Capacity-Planning-Dashboard"
```

**Output:** Service principal ID and federated credentials configured

---

### 2. bootstrap-ca-policy.ps1
**Purpose:** Diagnose and fix Conditional Access policy issues

**When to run:** If deployment fails with AADSTS53003 error

**Modes:**

**check** - Diagnose current policies (read-only)
```powershell
.\scripts\bootstrap-ca-policy.ps1 -Mode check
```
- Lists all CA policies in tenant
- Shows service principal details
- Reports if service principal is excluded

**exempt** - Steps to manually exempt service principal
```powershell
.\scripts\bootstrap-ca-policy.ps1 -Mode exempt
```
- Provides step-by-step Azure Portal instructions
- Shows where to add service principal to policy exclusions

**create-exception** - Create new CA policy exception
```powershell
.\scripts\bootstrap-ca-policy.ps1 -Mode create-exception -PolicyName "GitHub Actions OIDC"
```
- Guides creation of new CA policy
- Exempts service principal from all other policies
- One-time Azure AD administrator task

**verify** - Test OIDC token exchange
```powershell
.\scripts\bootstrap-ca-policy.ps1 -Mode verify
```
- Guidance for testing after CA policy fixes
- Instructions to check GitHub Actions deployment

---

### 3. bootstrap-and-deploy.ps1
**Purpose:** Complete orchestration - runs all steps in sequence

**When to run:** When doing a complete fresh deployment

**What it does:**
1. Runs GitHub OIDC bootstrap (if needed)
2. Checks/fixes CA policies (if needed)
3. Triggers deployment workflow
4. Optionally waits for deployment completion

**Command:**
```powershell
# Interactive mode - prompts for each step
.\scripts\bootstrap-and-deploy.ps1

# Full automation
.\scripts\bootstrap-and-deploy.ps1 `
  -SkipOIDC `
  -SkipCAPolicy `
  -TriggerDeployment `
  -WaitForDeployment
```

**Flags:**
- `-SkipOIDC` - Skip GitHub OIDC setup (already done)
- `-SkipCAPolicy` - Skip CA policy checks (already fixed)
- `-TriggerDeployment` - Auto-trigger workflow (no prompt)
- `-WaitForDeployment` - Wait for workflow completion (blocks until done)

---

## Deployment Workflow

### Option A: Full Automation (Recommended)
```powershell
# One command does everything
.\scripts\bootstrap-and-deploy.ps1 `
  -SkipOIDC `           # If already set up OIDC
  -SkipCAPolicy `       # If CA policy already fixed
  -TriggerDeployment `  # Auto-trigger deploy
  -WaitForDeployment    # Wait for completion
```

### Option B: Manual Steps
```powershell
# Step 1: Setup OIDC (one-time only)
.\scripts\bootstrap-github-oidc.ps1 `
  -SubscriptionId "844eabcc-dc96-453b-8d45-bef3d566f3f8" `
  -ResourceGroupName "rg-capdash-prod" `
  -GitHubOrganization "IBuySpy-Dev" `
  -GitHubRepository "Capacity-Planning-Dashboard"

# Step 2: Fix CA policy (if needed)
.\scripts\bootstrap-ca-policy.ps1 -Mode check
# Then manually fix in Azure Portal or use create-exception mode

# Step 3: Deploy
gh workflow run deploy.yml --repo IBuySpy-Dev/Capacity-Planning-Dashboard -f environment=prod
```

### Option C: Orchestrated with Prompts
```powershell
# Interactive prompts for each step
.\scripts\bootstrap-and-deploy.ps1
```

---

## Success Indicators

### After bootstrap-github-oidc.ps1:
- ✅ Service principal created
- ✅ Federated credentials configured
- ✅ GitHub environment variables set
- ✅ No errors in output

### After bootstrap-ca-policy.ps1 (exempt mode):
- ✅ Service principal added to policy exclusions
- ✅ No "Access blocked by Conditional Access" errors

### After deployment workflow:
- ✅ Azure Login (OIDC) step succeeds
- ✅ App deployed to App Service
- ✅ SQL bootstrap runs without errors
- ✅ App restarts successfully

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| AADSTS53003 after deploy | Run `bootstrap-ca-policy.ps1 -Mode exempt` |
| Service principal not found | Check subscription ID matches actual subscription |
| GitHub environment vars not set | Verify GitHub CLI authentication with `gh auth status` |
| Deployment still fails after CA fix | Check Application Insights logs for specific errors |
| CA policy exemption not working | Verify correct service principal ID in policy settings |

---

## Key Advantages

1. **Modular**: Each script runs independently
2. **Reusable**: Run scripts multiple times without side effects
3. **Diagnostic**: Built-in check mode to diagnose issues
4. **Idempotent**: Safe to re-run scripts multiple times
5. **Documented**: Each script has comprehensive inline help
6. **Flexible**: Support interactive prompts or automated flags
7. **Orchestrated**: One script can run the complete workflow

---

## Technical Details

### OIDC Flow
```
GitHub Actions Workflow
    ↓
Request OIDC Token (with GitHub context)
    ↓
GitHub Issues Token to runner
    ↓
Exchange Token with Azure AD
    ↓ [CA Policy Check Happens Here]
    ↓
Receive Azure Access Token (1 hour TTL)
    ↓
Deploy to Azure
```

### Federated Credentials
- **Main branch:** `repo:IBuySpy-Dev/Capacity-Planning-Dashboard:ref:refs/heads/main`
- **Pull requests:** `repo:IBuySpy-Dev/Capacity-Planning-Dashboard:pull_request`
- **Audience:** `api://AzureADTokenExchange`

### CA Policy Context
- Service Principal: `github-oidc-capdash` (81dfa11c-e554-4186-bb38-ae7113862478)
- Tenant: Microsoft (72f988bf-86f1-41af-91ab-2d7cd011db47)
- Error: AADSTS53003 (Access blocked by Conditional Access policies)
- Resolution: Exemption or policy exception required

---

## Files

| File | Purpose | Size |
|------|---------|------|
| `scripts/bootstrap-github-oidc.ps1` | OIDC setup | 440 lines |
| `scripts/bootstrap-ca-policy.ps1` | CA policy config | 330 lines |
| `scripts/bootstrap-and-deploy.ps1` | Orchestration | 280 lines |
| `docs/GITHUB-OIDC-SETUP.md` | Architecture guide | 13 KB |
| `docs/GITHUB-OIDC-QUICK-START.md` | Quick reference | 5 KB |
| `README.md` (updated) | Deployment guide | 50 KB |

---

## Next Steps

1. **First deployment:** Run `bootstrap-and-deploy.ps1` interactively
2. **If CA policy error:** Run `bootstrap-ca-policy.ps1 -Mode exempt` (Azure admin task)
3. **After CA fix:** Re-run deployment workflow
4. **Verify success:** Check app loads and APIs return data

---

**Status:** Complete. All bootstrap scripts ready for use. Deployment can now handle CA policy configuration as a separate pre-deployment step.
