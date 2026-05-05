# GitHub OIDC Bootstrap - Quick Reference

## One-Command Setup

```powershell
.\scripts\bootstrap-github-oidc.ps1 `
  -SubscriptionId "844eabcc-dc96-453b-8d45-bef3d566f3f8" `
  -ResourceGroupName "rg-capdash-prod" `
  -GitHubOrganization "IBuySpy-Dev" `
  -GitHubRepository "Capacity-Planning-Dashboard"
```

**What it does:**
- ✅ Creates Azure service principal for GitHub OIDC
- ✅ Configures federated credentials (main + PR)
- ✅ Sets GitHub environment variables
- ✅ Outputs workflow configuration

**Execution time:** 2-3 minutes

## Script Output

The script outputs the exact configuration needed:

```yaml
environment: production

jobs:
  deploy:
    environment: production
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: azure/login@v1
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
```

## Verification Commands

```bash
# Check service principal exists
az ad sp show --id <AZURE_CLIENT_ID>

# List federated credentials
az ad app federated-credential list --id <AZURE_CLIENT_ID>

# Verify GitHub variables
gh variable list --env production --repo IBuySpy-Dev/Capacity-Planning-Dashboard
```

## Testing OIDC

Create a test workflow to verify authentication works:

```bash
gh workflow run test-oidc.yml --repo IBuySpy-Dev/Capacity-Planning-Dashboard
```

Look for: "✓ Successfully authenticated to Azure"

## Before & After

### Before: Service Principal Credentials
```
1. Create service principal: 5 minutes
2. Copy JSON credentials: 2 minutes
3. Manually add to GitHub Secrets: 3 minutes
4. Update workflows: 10 minutes
5. Test: 5 minutes
━━━━━━━━━━━━━━━━
Total: 25 minutes
Risk: Long-lived credentials stored in GitHub
```

### After: GitHub OIDC
```
1. Run bootstrap script: 3 minutes
2. Script updates everything automatically
3. Test workflow: 2 minutes
━━━━━━━━━━━━━━━━
Total: 5 minutes
Risk: Short-lived tokens (1-hour TTL)
```

## Key Advantages

| Aspect | Service Principal | GitHub OIDC |
|--------|-------------------|------------|
| Setup Time | 20+ min | 3 min |
| Credential Storage | JSON in secrets | Variables (non-secret) |
| Token Lifetime | Indefinite | 1 hour |
| Rotation | Manual | Automatic |
| Security | ⚠️ Medium | ✅ High |
| Compliance | Legacy | Modern |

## Migration Path

### Option 1: Parallel Approach (Recommended)
1. Run bootstrap script (creates new OIDC setup)
2. Update workflows to use OIDC
3. Test everything
4. Delete old credentials secret
5. Optionally delete old service principal

### Option 2: Direct Replacement
1. Delete old `AZURE_CREDENTIALS` secret
2. Run bootstrap script
3. Update workflows
4. Test

## Troubleshooting

### Script fails: "Azure CLI not found"
```bash
# Install Azure CLI
# Windows: choco install azure-cli
# macOS: brew install azure-cli
# Linux: see https://learn.microsoft.com/cli/azure/install-azure-cli
```

### Script fails: "Not authenticated"
```bash
az login
# Select your Microsoft account
```

### Script fails: "GitHub not authenticated"
```bash
gh auth login
# Select HTTPS, use personal access token or authenticate with browser
```

### Workflow fails: "Invalid federated credential"
Verify repo name exactly:
```bash
gh repo view --json nameWithOwner
# Must match: repo:IBuySpy-Dev/Capacity-Planning-Dashboard:ref:refs/heads/main
```

## Cleanup (if needed)

```bash
# Delete GitHub environment variables
gh variable delete AZURE_CLIENT_ID --env production
gh variable delete AZURE_TENANT_ID --env production
gh variable delete AZURE_SUBSCRIPTION_ID --env production
gh variable delete AZURE_RESOURCE_GROUP --env production

# Delete service principal
az ad sp delete --id <CLIENT_ID>
```

## Next Steps

1. **Run the bootstrap script**
   ```powershell
   .\scripts\bootstrap-github-oidc.ps1 ...
   ```

2. **Update workflows**
   - Copy YAML from script output
   - Update `.github/workflows/bootstrap-and-deploy.yml`
   - Add `environment: production` to jobs
   - Change Azure Login to use variables

3. **Test the workflow**
   ```bash
   gh workflow run bootstrap-and-deploy.yml
   ```

4. **Verify success**
   - Check workflow logs
   - Look for "✓ Successfully authenticated to Azure"
   - Verify app deployed successfully

5. **Clean up old approach**
   ```bash
   gh secret delete AZURE_CREDENTIALS
   az ad sp delete --id <OLD_SERVICE_PRINCIPAL_ID>
   ```

## Documentation

- **Detailed Guide**: `docs/GITHUB-OIDC-SETUP.md`
- **Azure OIDC Docs**: https://github.com/Azure/login#github-oidc
- **Workload Identity**: https://learn.microsoft.com/azure/active-directory/workload-identities/workload-identity-federation

---

**Time to Setup**: ~3 minutes
**Complexity**: Low (fully automated)
**Security Improvement**: High
