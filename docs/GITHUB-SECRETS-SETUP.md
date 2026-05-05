# GitHub Actions Deployment Setup - Sprint 4 Blocker

## Problem
Deployment workflow is failing because GitHub Actions secrets are not configured.

## Root Cause
The CI/CD workflow requires 4 secrets to be set in GitHub repository settings:
1. `AZURE_SUBSCRIPTION_ID` - Azure subscription ID
2. `AZURE_RESOURCE_GROUP` - Azure resource group name
3. `AZURE_WEBAPP_NAME` - Azure App Service name
4. `AZURE_CREDENTIALS` - Service principal credentials (JSON)

## Solution

### Step 1: Service Principal Creation (Completed)

A service principal has been created with credentials stored securely. The credentials follow this format:

```json
{
  "appId": "YOUR_APP_ID",
  "displayName": "github-deployment-sp-capdash",
  "password": "YOUR_SECRET_PASSWORD",
  "tenant": "YOUR_TENANT_ID"
}
```

**Important:** The actual service principal password and credentials are sensitive and stored securely. They should be treated like API keys and protected from exposure in source code.

### Step 2: Configure GitHub Actions Secrets

Go to: https://github.com/IBuySpy-Dev/Capacity-Planning-Dashboard/settings/secrets/actions

Add the following secrets:

#### Secret 1: AZURE_SUBSCRIPTION_ID
- **Name:** `AZURE_SUBSCRIPTION_ID`
- **Value:** `844eabcc-dc96-453b-8d45-bef3d566f3f8`

#### Secret 2: AZURE_RESOURCE_GROUP
- **Name:** `AZURE_RESOURCE_GROUP`
- **Value:** `rg-capdash-prod`

#### Secret 3: AZURE_WEBAPP_NAME
- **Name:** `AZURE_WEBAPP_NAME`
- **Value:** `app-capdash-prod-prod01`

#### Secret 4: AZURE_CREDENTIALS
- **Name:** `AZURE_CREDENTIALS`
- **Value:** (Copy the entire JSON object from service principal creation)

```json
{
  "appId": "YOUR_APP_ID",
  "displayName": "github-deployment-sp-capdash",
  "password": "YOUR_SECRET_PASSWORD",
  "tenant": "YOUR_TENANT_ID"
}
```

**Note:** Use the actual service principal credentials from the setup process above.

### Step 3: Verify Secrets are Set

1. Go to repository Settings → Secrets and variables → Actions
2. You should see 4 secrets listed:
   - ✓ AZURE_CREDENTIALS
   - ✓ AZURE_RESOURCE_GROUP
   - ✓ AZURE_SUBSCRIPTION_ID
   - ✓ AZURE_WEBAPP_NAME

**Note:** Secret values are masked in the UI and cannot be viewed after creation (for security).

### Step 4: Re-run Deployment

Once secrets are configured, trigger the deployment:

**Option A:** Via GitHub Actions UI
1. Go to: https://github.com/IBuySpy-Dev/Capacity-Planning-Dashboard/actions
2. Select "Deploy Capacity Dashboard" workflow
3. Click "Run workflow"
4. Select branch: `main`
5. Click "Run workflow"

**Option B:** Via CLI
```bash
gh workflow run deploy.yml
```

**Option C:** Via Git Push
```bash
git push upstream main
```

### Step 5: Monitor Deployment

1. Go to Actions tab: https://github.com/IBuySpy-Dev/Capacity-Planning-Dashboard/actions
2. Click the latest "Deploy Capacity Dashboard" run
3. Watch jobs execute:
   - `build-and-test` - Runs npm ci, npm test (~2-3 min)
   - `deploy` - Deploys app and SQL bootstrap (~5-10 min)
4. Look for these steps in the deploy job:
   - ✓ Deploy to Azure App Service
   - ✓ Bootstrap SQL Database for Managed Identity (NEW)
   - ✓ Restart App Service (NEW)
   - ✓ Verify deployment

### Step 6: Verify Deployment Success

After deployment completes (should show green checkmarks):

1. **Check SQL Bootstrap Success:**
   - In deploy job, expand "Bootstrap SQL Database for Managed Identity" step
   - Should see: "✓ SQL script executed successfully"

2. **Test API Endpoints:**
   ```bash
   # Get authentication token (requires Entra ID credentials)
   # Then test endpoint
   curl -H "Authorization: Bearer {token}" \
     https://app-capdash-prod-prod01.azurewebsites.net/api/subscriptions
   ```
   Expected: HTTP 200 with JSON data (not HTTP 500 "Login failed")

3. **Check Application Insights:**
   - Azure Portal → Resource Groups → rg-capdash-prod → appi-capdash-prod-prod01
   - Look for successful database queries
   - Should see NO "Login failed for user" errors

## Troubleshooting

### Deployment Still Fails After Setting Secrets

1. **Check secret values are exactly correct:**
   - No extra spaces or quotes
   - JSON is valid format for AZURE_CREDENTIALS
   
2. **Verify service principal permissions:**
   ```bash
   az role assignment list \
     --assignee 0bc59137-dbbf-4da3-9639-1fcb14b33fe2 \
     --scope /subscriptions/844eabcc-dc96-453b-8d45-bef3d566f3f8/resourceGroups/rg-capdash-prod
   ```

3. **View workflow logs:**
   - Click failed workflow run
   - Expand "Azure Login" step
   - Should say "✓ Logged in successfully"

### SQL Bootstrap Fails

If bootstrap step fails with "sqlcmd not found":
- Ubuntu runners have sqlcmd pre-installed
- If error persists, check if sqlcmd-tools package needs update

If SQL script execution fails:
- Check if SQL Server has Azure AD admin configured
- Verify service principal has SQL admin rights
- Check Application Insights logs for exact error

## Security Considerations

1. **Service Principal Password:**
   - Treat like an API key or password
   - Rotate periodically (recommended: every 90 days)
   - Keep out of source control

2. **GitHub Secrets:**
   - Masked in logs (good security practice)
   - Only exposed to workflow steps that declare them as `env` variables
   - Recommended: Create organization-level secrets if multiple repos need them

3. **SQL Access:**
   - Service principal only has Contributor role on resource group
   - Cannot create/delete resources at subscription level
   - Can only manage resources in rg-capdash-prod

## Next Steps (After Secrets Configured)

1. ✅ Configure GitHub Actions secrets
2. ✅ Trigger deployment workflow
3. ✅ Monitor SQL bootstrap execution
4. ✅ Verify APIs return data
5. ✅ Test React UI
6. ✅ Mark issues as FIXED

See Sprint 4 plan for full testing checklist.
