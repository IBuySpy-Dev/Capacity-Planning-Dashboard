# GitHub Workload Identity Federation (OIDC) Setup Guide

## Overview

GitHub Workload Identity Federation eliminates the need for long-lived credentials (service principal JSON). Instead, GitHub Actions authenticates to Azure using **short-lived OIDC tokens** that are automatically generated and validated.

### Benefits vs. Service Principal Credentials

| Aspect | Service Principal | GitHub OIDC |
|--------|-------------------|------------|
| **Credential Type** | Long-lived JSON | Short-lived tokens |
| **Rotation** | Manual | Automatic per workflow run |
| **Storage** | GitHub Secrets | GitHub Variables (non-secret) |
| **Leak Risk** | High (if exposed) | Low (1-hour token TTL) |
| **Setup Complexity** | Simple (1 step) | Moderate (federated credentials) |
| **Security** | ⚠️ Medium | ✅ High |
| **Best Practice** | Legacy | Modern (CIEM recommended) |

### How It Works

```
GitHub Actions Workflow Run
         ↓
   Request OIDC Token
         ↓
GitHub Issues JWT with:
  - aud: api://AzureADTokenExchange
  - sub: repo:org/repo:ref:refs/heads/main
  - iss: https://token.actions.githubusercontent.com
         ↓
Azure Login Action Receives Token
         ↓
Exchanges Token for Azure Access Token
  (using federated credential)
         ↓
Authenticates to Azure (no secrets stored!)
```

## Quick Start

### Prerequisites

- Azure CLI installed (`az` command)
- GitHub CLI installed (`gh` command)
- Both authenticated:
  - `az login`
  - `gh auth login`

### Setup in 1 Command

```powershell
.\scripts\bootstrap-github-oidc.ps1 `
  -SubscriptionId "844eabcc-dc96-453b-8d45-bef3d566f3f8" `
  -ResourceGroupName "rg-capdash-prod" `
  -GitHubOrganization "IBuySpy-Dev" `
  -GitHubRepository "Capacity-Planning-Dashboard"
```

The script will:
1. ✅ Create service principal for GitHub OIDC
2. ✅ Configure federated credentials (main branch + PRs)
3. ✅ Set GitHub environment variables
4. ✅ Output workflow configuration

## What Gets Created

### 1. Azure Service Principal

```bash
# View the service principal
az ad sp show --id <AZURE_CLIENT_ID> --query '{displayName, appId, id}'
```

**Permissions**: Contributor role on resource group (scoped access)

**Lifespan**: Created once, reused for all workflows

### 2. Federated Credentials

Two credentials are created automatically:

#### a) Main Branch Deployments
```
Issuer:  https://token.actions.githubusercontent.com
Subject: repo:IBuySpy-Dev/Capacity-Planning-Dashboard:ref:refs/heads/main
Allows:  Deployments from main branch
TTL:     1 hour per run
```

#### b) Pull Request Deployments
```
Issuer:  https://token.actions.githubusercontent.com
Subject: repo:IBuySpy-Dev/Capacity-Planning-Dashboard:pull_request
Allows:  Deployments from PR workflows
TTL:     1 hour per run
```

### 3. GitHub Environment Variables

Four variables are configured in your GitHub environment:

```yaml
Environment: production

Variables:
  AZURE_CLIENT_ID         # Service principal app ID
  AZURE_TENANT_ID         # Azure tenant ID
  AZURE_SUBSCRIPTION_ID   # Azure subscription ID
  AZURE_RESOURCE_GROUP    # Resource group name
```

**Note**: These are **variables** (not secrets) — they're not sensitive.

## Updating Workflows

### Old Approach (Service Principal)

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}  # ← Long-lived JSON
```

### New Approach (GitHub OIDC)

```yaml
jobs:
  deploy:
    environment: production  # ← Use environment
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write  # ← Required for OIDC
    steps:
      - uses: azure/login@v1
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
```

**Key differences**:
1. Add `environment: production` to job
2. Add `id-token: write` to permissions
3. Use `vars.` instead of `secrets.`
4. Pass individual fields instead of JSON

## Verification

### Check Service Principal

```bash
az ad sp show --id <CLIENT_ID>
```

Expected output:
```json
{
  "displayName": "github-oidc-capdash",
  "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "objectId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

### List Federated Credentials

```bash
az ad app federated-credential list --id <CLIENT_ID>
```

Expected output:
```json
[
  {
    "audiences": ["api://AzureADTokenExchange"],
    "description": null,
    "displayName": "github-Capacity-Planning-Dashboard-main",
    "id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:IBuySpy-Dev/Capacity-Planning-Dashboard:ref:refs/heads/main"
  }
]
```

### Check GitHub Environment Variables

```bash
gh variable list --env production --repo IBuySpy-Dev/Capacity-Planning-Dashboard
```

Expected output:
```
AZURE_CLIENT_ID         value:hidden   Org
AZURE_RESOURCE_GROUP    value:hidden   Org
AZURE_SUBSCRIPTION_ID   value:hidden   Org
AZURE_TENANT_ID         value:hidden   Org
```

### Test in Workflow

Create `.github/workflows/test-oidc.yml`:

```yaml
name: Test OIDC Authentication

on:
  workflow_dispatch:

jobs:
  test:
    environment: production
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Azure Login
        uses: azure/login@v1
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}

      - name: Verify Authentication
        run: |
          echo "✓ Successfully authenticated to Azure"
          az account show --query '{subscriptionId, tenantId}'
          az group show --name ${{ vars.AZURE_RESOURCE_GROUP }} --query name
```

Then run:
```bash
gh workflow run test-oidc.yml --repo IBuySpy-Dev/Capacity-Planning-Dashboard
```

## Security Considerations

### What's Secure About OIDC?

✅ **No long-lived credentials**: Tokens expire after 1 hour
✅ **Automatic rotation**: New token per workflow run
✅ **Audience binding**: Token only valid for `api://AzureADTokenExchange`
✅ **Subject verification**: Azure validates GitHub repository
✅ **Audit trail**: Azure logs show exact GitHub context (org, repo, branch)

### Potential Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| **Token interception in transit** | Use HTTPS only (automatic in Azure/GitHub) |
| **Compromised workflow job** | Limit federated credentials to specific branches/refs |
| **Malicious fork running workflow** | Configure `if: github.repository == 'IBuySpy-Dev/...'` in critical steps |
| **Over-permissioned service principal** | Always scope to specific resource group |

### Best Practices

1. **Scope to resource group** ✅ (not subscription-wide)
2. **Limit to main branch** ✅ (not all refs)
3. **Add GitHub branch protection** ✅ (require reviews before main)
4. **Use environment approvals** ✅ (require approval for production)
5. **Monitor service principal usage** ✅ (via Azure audit logs)
6. **Rotate federated credentials** ✅ (annually review)

## Troubleshooting

### Error: "Invalid federated credential"

**Cause**: Repository subject doesn't match

**Solution**: Verify the exact repo name:
```bash
gh repo view --json nameWithOwner
# Output: nameWithOwner: IBuySpy-Dev/Capacity-Planning-Dashboard
```

Use this exact format in the federated credential.

### Error: "AADSTS700027: Client assertion is not within its validity period"

**Cause**: System time skew between GitHub and Azure

**Solution**: Ensure systems have synchronized clocks (rarely happens on GitHub Actions)

### Error: "Insufficient privileges to complete the operation"

**Cause**: Service principal lacks required permissions

**Solution**: Assign Contributor role on resource group:
```bash
az role assignment create \
  --assignee <CLIENT_ID> \
  --role Contributor \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>
```

### Error: "The client does not have permission to perform action"

**Cause**: Service principal is valid but lacks specific permissions

**Solution**: 
1. Check what permissions are needed
2. Assign more specific role or additional role
3. Verify scope of assignment

### OIDC Login Works But Azure Commands Fail

**Cause**: Azure token acquired but doesn't have necessary permissions

**Solution**: 
1. Verify service principal has roles assigned
2. Check role scope (should be resource group or higher)
3. Try: `az account show` to verify authentication
4. Try: `az group show --name <RG>` to verify permissions

## Migration from Service Principal Credentials

### Step 1: Create GitHub OIDC Setup

```powershell
.\scripts\bootstrap-github-oidc.ps1 `
  -SubscriptionId "844eabcc-dc96-453b-8d45-bef3d566f3f8" `
  -ResourceGroupName "rg-capdash-prod" `
  -GitHubOrganization "IBuySpy-Dev" `
  -GitHubRepository "Capacity-Planning-Dashboard"
```

### Step 2: Update Workflows

Update `.github/workflows/bootstrap-and-deploy.yml`:

```yaml
# Add environment
jobs:
  setup-secrets:
    environment: production
    
  deploy:
    environment: production
    needs: setup-secrets
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

### Step 3: Test the New Workflow

```bash
gh workflow run bootstrap-and-deploy.yml --repo IBuySpy-Dev/Capacity-Planning-Dashboard
```

Monitor logs for successful Azure authentication.

### Step 4: Delete Old Credentials Secret

Once verified working:

```bash
gh secret delete AZURE_CREDENTIALS --repo IBuySpy-Dev/Capacity-Planning-Dashboard
```

### Step 5: Delete Old Service Principal (if different)

If you created a separate OIDC service principal:

```bash
# List all service principals
az ad sp list --query "[?displayName=='github-*']"

# Delete old service principal (if replacing github-deployment-sp-capdash)
az ad sp delete --id <OLD_CLIENT_ID>
```

## Reference

### Bootstrap Script Output

The bootstrap script outputs:
1. Service principal details (Client ID, Tenant ID)
2. Federated credential configuration
3. GitHub environment variables
4. Workflow YAML examples
5. Verification commands
6. Testing instructions

### Files Modified/Created

```
scripts/
├── bootstrap-github-oidc.ps1       # This bootstrap script (new)
└── bootstrap-sql-managed-identity.ps1  # Existing SQL bootstrap

.github/workflows/
└── bootstrap-and-deploy.yml        # Will be updated to use OIDC

docs/
├── GITHUB-OIDC-SETUP.md           # This guide
└── AUTOMATED-DEPLOYMENT.md         # Will reference OIDC approach
```

### Related Documentation

- [GitHub Actions OIDC Provider](https://github.com/Azure/login#github-oidc)
- [Azure Workload Identity Federation](https://learn.microsoft.com/azure/active-directory/workload-identities/workload-identity-federation)
- [Azure Login Action](https://github.com/Azure/login)

## FAQ

### Q: Should I still use service principal credentials for local development?

**A**: Yes. OIDC only works in GitHub Actions. For local development:
```bash
# Local: Use managed identity or service principal credentials
az login  # or specific service principal

# Workflow: Use OIDC via GitHub Actions
```

### Q: Can I use OIDC with multiple Azure subscriptions?

**A**: Create separate service principals or federated credentials for each subscription. Each would have its own set of GitHub environment variables.

### Q: What if I need to deploy from a pull request?

**A**: The bootstrap script creates federated credentials for both:
- Main branch deployments
- Pull request deployments

PR deployments can be restricted to `environment` with manual approvals.

### Q: How do I rotate OIDC credentials?

**A**: OIDC tokens rotate automatically (1 hour TTL). To rotate the service principal:
```bash
# Create new service principal
az ad sp create-for-rbac --name github-oidc-capdash-new ...

# Create new federated credentials
# Update GitHub variables
# Delete old service principal
az ad sp delete --id <OLD_ID>
```

### Q: Is OIDC supported by all GitHub plans?

**A**: Yes, OIDC is available for all GitHub plans (including free).

---

**Last Updated**: Sprint 4
**Status**: ✅ Bootstrap Script Available
**Maintained By**: Capacity Planning Dashboard Team
