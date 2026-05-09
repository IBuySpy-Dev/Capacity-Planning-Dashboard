<#
.SYNOPSIS
Bootstrap GitHub Workload Identity Federation (OIDC) for Azure deployment

.DESCRIPTION
Creates Azure service principal configured for GitHub OIDC authentication.
This eliminates the need for stored credentials (AZURE_CREDENTIALS secret).

.PARAMETER SubscriptionId
Azure subscription ID where service principal will be created

.PARAMETER ResourceGroupName
Resource group for scoped access

.PARAMETER GitHubOrganization
GitHub organization (e.g., IBuySpy-Dev)

.PARAMETER GitHubRepository
GitHub repository name (e.g., Capacity-Planning-Dashboard)

.PARAMETER ServicePrincipalName
Name for the service principal (default: github-oidc-{org}-{repo})

.PARAMETER EnvironmentName
GitHub environment name (default: production)

.EXAMPLE
.\bootstrap-github-oidc.ps1 `
  -SubscriptionId "844eabcc-dc96-453b-8d45-bef3d566f3f8" `
  -ResourceGroupName "rg-capdash-prod" `
  -GitHubOrganization "IBuySpy-Dev" `
  -GitHubRepository "Capacity-Planning-Dashboard"

.NOTES
Requires:
- Azure CLI installed and authenticated
- Sufficient permissions to create service principals
- GitHub CLI authenticated (gh auth login)

Output:
- Creates service principal with GitHub federated credentials
- Outputs GitHub environment variables to configure
- Provides verification commands
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$GitHubOrganization,

    [Parameter(Mandatory = $true)]
    [string]$GitHubRepository,

    [Parameter(Mandatory = $false)]
    [string]$ServicePrincipalName = "github-oidc-capdash",

    [Parameter(Mandatory = $false)]
    [string]$EnvironmentName = "production"
)

$ErrorActionPreference = "Stop"

# ============================================================================
# COLORS FOR OUTPUT
# ============================================================================
$COLORS = @{
    Header   = "Cyan"
    Success  = "Green"
    Warning  = "Yellow"
    Error    = "Red"
    Info     = "Blue"
    Dim      = "Gray"
}

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor $COLORS.Header
    Write-Host "║ $($Message.PadRight(58)) ║" -ForegroundColor $COLORS.Header
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor $COLORS.Header
    Write-Host ""
}

function Write-Section {
    param([string]$Message)
    Write-Host ""
    Write-Host "▶  $Message" -ForegroundColor $COLORS.Info
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor $COLORS.Success
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor $COLORS.Warning
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor $COLORS.Error
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor $COLORS.Info
}

# ============================================================================
# STEP 1: VALIDATE PREREQUISITES
# ============================================================================
Write-Header "STEP 1: VALIDATING PREREQUISITES"

Write-Section "Checking Azure CLI..."
try {
    $azVersion = az --version 2>$null | Select-Object -First 1
    Write-Success "Azure CLI: $azVersion"
} catch {
    Write-Error "Azure CLI not found. Install from: https://learn.microsoft.com/cli/azure/install-azure-cli"
    exit 1
}

Write-Section "Checking Azure authentication..."
try {
    $account = az account show --query "name" -o tsv
    Write-Success "Authenticated as: $account"
} catch {
    Write-Error "Not authenticated. Run: az login"
    exit 1
}

Write-Section "Checking GitHub CLI..."
try {
    $ghVersion = gh --version 2>$null | Select-Object -First 1
    Write-Success "GitHub CLI: $ghVersion"
} catch {
    Write-Error "GitHub CLI not found. Install from: https://cli.github.com"
    exit 1
}

Write-Section "Checking GitHub authentication..."
try {
    $ghUser = gh api user --jq '.login'
    Write-Success "GitHub authenticated as: $ghUser"
} catch {
    Write-Error "GitHub not authenticated. Run: gh auth login"
    exit 1
}

# ============================================================================
# STEP 2: CREATE SERVICE PRINCIPAL
# ============================================================================
Write-Header "STEP 2: CREATING SERVICE PRINCIPAL"

Write-Section "Service Principal Configuration"
Write-Info "Name: $ServicePrincipalName"
Write-Info "Subscription: $SubscriptionId"
Write-Info "Resource Group: $ResourceGroupName"
Write-Info "GitHub Org: $GitHubOrganization"
Write-Info "GitHub Repo: $GitHubRepository"

Write-Section "Creating service principal..."
try {
    $sp = az ad sp create-for-rbac `
        --name $ServicePrincipalName `
        --role Contributor `
        --scopes "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName" `
        --query "{clientId: appId, subscriptionId: subscriptionId, tenantId: tenantId}" `
        -o json | ConvertFrom-Json
    
    Write-Success "Service principal created: $($sp.clientId)"
    Write-Info "Tenant ID: $($sp.tenantId)"
    Write-Info "Subscription ID: $($sp.subscriptionId)"
} catch {
    Write-Error "Failed to create service principal: $_"
    exit 1
}

$ClientId = $sp.clientId
$TenantId = $sp.tenantId

# Grant User Access Administrator at subscription scope so the SP can create
# subscription-scoped role assignments during Bicep deployment (Reader, GroupQuota
# Request Operator, worker RBAC modules all target subscription() scope).
Write-Section "Granting User Access Administrator at subscription scope..."
try {
    az role assignment create `
        --assignee $ClientId `
        --role "User Access Administrator" `
        --scope "/subscriptions/$SubscriptionId" `
        --output none
    Write-Success "User Access Administrator granted at subscription scope"
} catch {
    Write-Warning "Could not assign User Access Administrator: $_"
    Write-Info "This role is required for Bicep to create subscription-scoped role assignments."
    Write-Info "Assign it manually: az role assignment create --assignee $ClientId --role 'User Access Administrator' --scope /subscriptions/$SubscriptionId"
}

# ============================================================================
# STEP 3: CONFIGURE GITHUB FEDERATED CREDENTIALS
# ============================================================================
Write-Header "STEP 3: CONFIGURING GITHUB FEDERATED CREDENTIALS"

Write-Section "Creating federated credential for GitHub OIDC..."

# Build the issuer and subject claim based on GitHub
$IssuerUrl = "https://token.actions.githubusercontent.com"
$SubjectIdentifier = "repo:$($GitHubOrganization)/$($GitHubRepository):ref:refs/heads/main"

Write-Info "Issuer: $IssuerUrl"
Write-Info "Subject: $SubjectIdentifier"

try {
    # Create federated credential
    $credential = @{
        issuer   = $IssuerUrl
        subject  = $SubjectIdentifier
        audience = "api://AzureADTokenExchange"
    } | ConvertTo-Json

    az ad app federated-credential create `
        --id $ClientId `
        --parameters "$credential" `
        --display-name "github-$GitHubRepository-main" `
        | Out-Null
    
    Write-Success "Federated credential created for branch 'main'"
} catch {
    Write-Error "Failed to create federated credential: $_"
    Write-Warning "You may need to manually create the federated credential"
    Write-Info "Alternative: Create it in Azure Portal → App Registrations → $ServicePrincipalName → Certificates & secrets"
}

# Create additional federated credential for pull requests
Write-Section "Creating federated credential for pull requests..."
$SubjectIdentifierPR = "repo:$($GitHubOrganization)/$($GitHubRepository):pull_request"

try {
    $credentialPR = @{
        issuer   = $IssuerUrl
        subject  = $SubjectIdentifierPR
        audience = "api://AzureADTokenExchange"
    } | ConvertTo-Json

    az ad app federated-credential create `
        --id $ClientId `
        --parameters "$credentialPR" `
        --display-name "github-$GitHubRepository-pr" `
        | Out-Null
    
    Write-Success "Federated credential created for pull requests"
} catch {
    Write-Warning "Pull request federated credential already exists or failed"
}

# ============================================================================
# STEP 4: OUTPUT GITHUB ENVIRONMENT VARIABLES
# ============================================================================
Write-Header "STEP 4: GITHUB ENVIRONMENT CONFIGURATION"

Write-Section "Required GitHub Environment Variables"
Write-Host ""
Write-Host "Add these to your GitHub environment settings:" -ForegroundColor $COLORS.Info
Write-Host ""
Write-Host "Environment Name: $EnvironmentName" -ForegroundColor $COLORS.Warning
Write-Host ""
Write-Host "Variables:" -ForegroundColor $COLORS.Info
Write-Host "  AZURE_CLIENT_ID         = $ClientId" -ForegroundColor $COLORS.Dim
Write-Host "  AZURE_TENANT_ID         = $TenantId" -ForegroundColor $COLORS.Dim
Write-Host "  AZURE_SUBSCRIPTION_ID   = $SubscriptionId" -ForegroundColor $COLORS.Dim
Write-Host "  AZURE_RESOURCE_GROUP    = $ResourceGroupName" -ForegroundColor $COLORS.Dim
Write-Host ""

# ============================================================================
# STEP 5: CONFIGURE GITHUB SECRETS/VARIABLES
# ============================================================================
Write-Header "STEP 5: CONFIGURING GITHUB REPOSITORY"

Write-Section "Setting GitHub environment variables..."

$repo = "$GitHubOrganization/$GitHubRepository"

try {
    # Set environment variables
    gh variable set AZURE_CLIENT_ID --body "$ClientId" --env $EnvironmentName --repo $repo
    Write-Success "AZURE_CLIENT_ID set"
    
    gh variable set AZURE_TENANT_ID --body "$TenantId" --env $EnvironmentName --repo $repo
    Write-Success "AZURE_TENANT_ID set"
    
    gh variable set AZURE_SUBSCRIPTION_ID --body "$SubscriptionId" --env $EnvironmentName --repo $repo
    Write-Success "AZURE_SUBSCRIPTION_ID set"
    
    gh variable set AZURE_RESOURCE_GROUP --body "$ResourceGroupName" --env $EnvironmentName --repo $repo
    Write-Success "AZURE_RESOURCE_GROUP set"
} catch {
    Write-Warning "Failed to set some GitHub variables: $_"
    Write-Info "You can set them manually in GitHub UI or via:"
    Write-Info "  gh variable set <NAME> --body '<VALUE>' --env $EnvironmentName --repo $repo"
}

# ============================================================================
# STEP 6: OUTPUT DEPLOYMENT CONFIGURATION
# ============================================================================
Write-Header "STEP 6: DEPLOYMENT CONFIGURATION"

Write-Section "Workflow Configuration (use in .github/workflows/deploy.yml)"
Write-Host ""
Write-Host "environment:" -ForegroundColor $COLORS.Dim
Write-Host "  name: $EnvironmentName" -ForegroundColor $COLORS.Dim
Write-Host ""
Write-Host "jobs:" -ForegroundColor $COLORS.Dim
Write-Host "  deploy:" -ForegroundColor $COLORS.Dim
Write-Host "    environment:" -ForegroundColor $COLORS.Dim
Write-Host "      name: $EnvironmentName" -ForegroundColor $COLORS.Dim
Write-Host "    runs-on: ubuntu-latest" -ForegroundColor $COLORS.Dim
Write-Host "    permissions:" -ForegroundColor $COLORS.Dim
Write-Host "      contents: read" -ForegroundColor $COLORS.Dim
Write-Host "      id-token: write" -ForegroundColor $COLORS.Dim
Write-Host "    steps:" -ForegroundColor $COLORS.Dim
Write-Host "      - name: Azure Login" -ForegroundColor $COLORS.Dim
Write-Host "        uses: azure/login@v1" -ForegroundColor $COLORS.Dim
Write-Host "        with:" -ForegroundColor $COLORS.Dim
Write-Host '          client-id: ${ vars.AZURE_CLIENT_ID }' -ForegroundColor $COLORS.Dim
Write-Host '          tenant-id: ${ vars.AZURE_TENANT_ID }' -ForegroundColor $COLORS.Dim
Write-Host '          subscription-id: ${ vars.AZURE_SUBSCRIPTION_ID }' -ForegroundColor $COLORS.Dim
Write-Host ""

# ============================================================================
# STEP 7: VERIFICATION COMMANDS
# ============================================================================
Write-Header "STEP 7: VERIFICATION COMMANDS"

Write-Section "Verify setup with these commands:"
Write-Host ""
Write-Host "# Verify service principal exists" -ForegroundColor $COLORS.Dim
Write-Host "az ad sp show --id $ClientId --query '{displayName, appId}'" -ForegroundColor $COLORS.Info
Write-Host ""
Write-Host "# List federated credentials" -ForegroundColor $COLORS.Dim
Write-Host "az ad app federated-credential list --id $ClientId --query '[].{issuer, subject, audience}'" -ForegroundColor $COLORS.Info
Write-Host ""
Write-Host "# Verify GitHub environment variables" -ForegroundColor $COLORS.Dim
Write-Host "gh variable list --env $EnvironmentName --repo $repo" -ForegroundColor $COLORS.Info
Write-Host ""

# ============================================================================
# STEP 8: TESTING OIDC IN WORKFLOW
# ============================================================================
Write-Header "STEP 8: TESTING GITHUB OIDC"

Write-Section "Create a test workflow to verify OIDC works:"
Write-Host ""
Write-Host "name: Test OIDC Login" -ForegroundColor $COLORS.Dim
Write-Host "on: workflow_dispatch" -ForegroundColor $COLORS.Dim
Write-Host ""
Write-Host "jobs:" -ForegroundColor $COLORS.Dim
Write-Host "  test:" -ForegroundColor $COLORS.Dim
Write-Host "    environment: $EnvironmentName" -ForegroundColor $COLORS.Dim
Write-Host "    runs-on: ubuntu-latest" -ForegroundColor $COLORS.Dim
Write-Host "    permissions:" -ForegroundColor $COLORS.Dim
Write-Host "      contents: read" -ForegroundColor $COLORS.Dim
Write-Host "      id-token: write" -ForegroundColor $COLORS.Dim
Write-Host "    steps:" -ForegroundColor $COLORS.Dim
Write-Host "      - name: Checkout" -ForegroundColor $COLORS.Dim
Write-Host "        uses: actions/checkout@v4" -ForegroundColor $COLORS.Dim
Write-Host ""
Write-Host "      - name: Azure Login" -ForegroundColor $COLORS.Dim
Write-Host "        uses: azure/login@v1" -ForegroundColor $COLORS.Dim
Write-Host "        with:" -ForegroundColor $COLORS.Dim
Write-Host '          client-id: ${ vars.AZURE_CLIENT_ID }' -ForegroundColor $COLORS.Dim
Write-Host '          tenant-id: ${ vars.AZURE_TENANT_ID }' -ForegroundColor $COLORS.Dim
Write-Host '          subscription-id: ${ vars.AZURE_SUBSCRIPTION_ID }' -ForegroundColor $COLORS.Dim
Write-Host ""
Write-Host "      - name: Test Azure CLI" -ForegroundColor $COLORS.Dim
Write-Host "        run: az account show" -ForegroundColor $COLORS.Dim
Write-Host ""

# ============================================================================
# STEP 9: CLEANUP OPTIONS
# ============================================================================
Write-Header "STEP 9: CLEANUP (IF NEEDED)"

Write-Section "If you need to delete the service principal:"
Write-Host ""
Write-Host "# Delete service principal" -ForegroundColor $COLORS.Dim
Write-Host "az ad sp delete --id $ClientId" -ForegroundColor $COLORS.Warning
Write-Host ""

# ============================================================================
# FINAL SUMMARY
# ============================================================================
Write-Header "✓ GITHUB OIDC BOOTSTRAP COMPLETE"

Write-Section "Summary"
Write-Host ""
Write-Host "✓ Service Principal Created" -ForegroundColor $COLORS.Success
Write-Host "  ID: $ClientId"
Write-Host ""
Write-Host "✓ GitHub Federated Credentials Configured" -ForegroundColor $COLORS.Success
Write-Host "  - Main branch deployments"
Write-Host "  - Pull request deployments"
Write-Host ""
Write-Host "✓ GitHub Environment Variables Set" -ForegroundColor $COLORS.Success
Write-Host "  Environment: $EnvironmentName"
Write-Host "  Variables: AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID, AZURE_RESOURCE_GROUP"
Write-Host ""
Write-Host "🎯 Next Steps:" -ForegroundColor $COLORS.Info
Write-Host ""
Write-Host "1. Deploy Azure infrastructure (creates all resources + pushes resource vars):"
Write-Host "   gh workflow run bicep-deploy.yml --repo $repo"
Write-Host "   This deploys Bicep and automatically pushes SQL_SERVER_NAME,"
Write-Host "   SQL_DATABASE_NAME, and AZURE_WEBAPP_NAME as repo vars."
Write-Host ""
Write-Host "2. Deploy the application:"
Write-Host "   gh workflow run deploy.yml --repo $repo"
Write-Host ""
Write-Host "3. Run database schema migration:"
Write-Host "   gh workflow run sql-schema.yml --repo $repo"
Write-Host ""
Write-Host "📚 Documentation: https://github.com/Azure/login#github-oidc" -ForegroundColor $COLORS.Info
Write-Host ""
