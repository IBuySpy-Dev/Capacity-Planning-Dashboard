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

Set BOOTSTRAP_DEBUG=true to log CLI commands, JSON payloads, and per-step timings.
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
    [string]$ServicePrincipalName = 'github-oidc-capdash',

    [Parameter(Mandatory = $false)]
    [string]$EnvironmentName = 'production'
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module (Join-Path $scriptDir 'BootstrapHelpers.psm1') -Force -ErrorAction Stop

Write-DebugDetail 'BOOTSTRAP_DEBUG enabled'

try {
    Write-Header 'STEP 1: VALIDATING PREREQUISITES'
    Assert-AzCliReady -SubscriptionId $SubscriptionId

    Write-Step 'Checking GitHub CLI...'
    try {
        $ghVersion = Invoke-GhCommand -Command '--version' -Description 'GitHub CLI version check'
        $versionLine = ($ghVersion -split "`r?`n" | Select-Object -First 1).Trim()
        if ($versionLine) {
            Write-Success "GitHub CLI: $versionLine"
        } else {
            Write-Success 'GitHub CLI is installed'
        }
    } catch {
        Write-Failure 'GitHub CLI not found. Install from: https://cli.github.com'
        throw
    }

    Write-Step 'Checking GitHub authentication...'
    try {
        $ghUser = Invoke-GhCommand -Command "api user --jq '.login'" -Description 'GitHub authentication check'
        Write-Success ("GitHub authenticated as: {0}" -f $ghUser.Trim())
    } catch {
        Write-Failure 'GitHub not authenticated. Run: gh auth login'
        throw
    }

    Write-Header 'STEP 2: CREATING SERVICE PRINCIPAL'
    Write-Step 'Service Principal Configuration'
    Write-Info "Name: $ServicePrincipalName"
    Write-Info "Subscription: $SubscriptionId"
    Write-Info "Resource Group: $ResourceGroupName"
    Write-Info "GitHub Org: $GitHubOrganization"
    Write-Info "GitHub Repo: $GitHubRepository"

    Write-Step 'Creating service principal...'
    $sp = Invoke-AzCommand `
        -Command "ad sp create-for-rbac --name `"$ServicePrincipalName`" --role Contributor --scopes `"/subscriptions/$SubscriptionId`" --query `"{clientId: appId, subscriptionId: subscriptionId, tenantId: tenantId}`" -o json" `
        -Description 'Create service principal' `
        -JsonOutput

    Write-Success "Service principal created: $($sp.clientId)"
    Write-Info "Tenant ID: $($sp.tenantId)"
    Write-Info "Subscription ID: $($sp.subscriptionId)"

    $ClientId = $sp.clientId
    $TenantId = $sp.tenantId

    Write-Step 'Granting Contributor at subscription scope...'
    try {
        Invoke-AzCommand -Command "role assignment create --assignee `"$ClientId`" --role `"Contributor`" --scope `"/subscriptions/$SubscriptionId`" --output none" -Description 'Grant Contributor at subscription scope' | Out-Null
        Write-Success 'Contributor granted at subscription scope'
    } catch {
        Write-Warning "Could not assign Contributor at subscription scope: $($_.Exception.Message)"
        Write-Info 'Required for Bicep cross-scope module deployments (subscription() scope).'
        Write-Info "Assign manually: az role assignment create --assignee $ClientId --role 'Contributor' --scope /subscriptions/$SubscriptionId"
    }

    Write-Step 'Granting User Access Administrator at subscription scope...'
    try {
        Invoke-AzCommand -Command "role assignment create --assignee `"$ClientId`" --role `"User Access Administrator`" --scope `"/subscriptions/$SubscriptionId`" --output none" -Description 'Grant User Access Administrator at subscription scope' | Out-Null
        Write-Success 'User Access Administrator granted at subscription scope'
    } catch {
        Write-Warning "Could not assign User Access Administrator: $($_.Exception.Message)"
        Write-Info 'This role is required for Bicep to create subscription-scoped role assignments.'
        Write-Info "Assign it manually: az role assignment create --assignee $ClientId --role 'User Access Administrator' --scope /subscriptions/$SubscriptionId"
    }

    Write-Header 'STEP 3: CONFIGURING GITHUB FEDERATED CREDENTIALS'
    Write-Step 'Creating federated credential for GitHub OIDC...'

    $IssuerUrl = 'https://token.actions.githubusercontent.com'
    $SubjectIdentifier = "repo:$GitHubOrganization/$GitHubRepository:ref:refs/heads/main"

    Write-Info "Issuer: $IssuerUrl"
    Write-Info "Subject: $SubjectIdentifier"

    try {
        $credential = @{
            issuer   = $IssuerUrl
            subject  = $SubjectIdentifier
            audience = 'api://AzureADTokenExchange'
        } | ConvertTo-Json -Compress

        Invoke-AzCommand -Command "ad app federated-credential create --id `"$ClientId`" --parameters '$credential' --display-name `"github-$GitHubRepository-main`"" -Description 'Create main branch federated credential' | Out-Null
        Write-Success "Federated credential created for branch 'main'"
    } catch {
        Write-Failure "Failed to create federated credential: $($_.Exception.Message)"
        Write-Warning 'You may need to manually create the federated credential'
        Write-Info "Alternative: Create it in Azure Portal -> App Registrations -> $ServicePrincipalName -> Certificates & secrets"
    }

    Write-Step 'Creating federated credential for pull requests...'
    $SubjectIdentifierPR = "repo:$GitHubOrganization/$GitHubRepository:pull_request"

    try {
        $credentialPR = @{
            issuer   = $IssuerUrl
            subject  = $SubjectIdentifierPR
            audience = 'api://AzureADTokenExchange'
        } | ConvertTo-Json -Compress

        Invoke-AzCommand -Command "ad app federated-credential create --id `"$ClientId`" --parameters '$credentialPR' --display-name `"github-$GitHubRepository-pr`"" -Description 'Create pull request federated credential' | Out-Null
        Write-Success 'Federated credential created for pull requests'
    } catch {
        Write-Warning 'Pull request federated credential already exists or failed'
    }

    Write-Step "Creating federated credential for '$EnvironmentName' environment..."
    $SubjectIdentifierEnv = "repo:$GitHubOrganization/$GitHubRepository:environment:$EnvironmentName"

    try {
        $credentialEnv = @{
            issuer   = $IssuerUrl
            subject  = $SubjectIdentifierEnv
            audience = 'api://AzureADTokenExchange'
        } | ConvertTo-Json -Compress

        Invoke-AzCommand -Command "ad app federated-credential create --id `"$ClientId`" --parameters '$credentialEnv' --display-name `"github-$GitHubRepository-env-$EnvironmentName`"" -Description 'Create environment federated credential' | Out-Null
        Write-Success "Federated credential created for environment '$EnvironmentName'"
    } catch {
        Write-Warning "Environment federated credential already exists or failed: $($_.Exception.Message)"
    }

    Write-Header 'STEP 4: GITHUB ENVIRONMENT CONFIGURATION'
    Write-Step 'Required GitHub Environment Variables'
    Write-Host ''
    Write-Host 'Add these to your GitHub environment settings:' -ForegroundColor Blue
    Write-Host ''
    Write-Host "Environment Name: $EnvironmentName" -ForegroundColor Yellow
    Write-Host ''
    Write-Host 'Variables:' -ForegroundColor Blue
    Write-Host "  AZURE_CLIENT_ID         = $ClientId" -ForegroundColor Gray
    Write-Host "  AZURE_TENANT_ID         = $TenantId" -ForegroundColor Gray
    Write-Host "  AZURE_SUBSCRIPTION_ID   = $SubscriptionId" -ForegroundColor Gray
    Write-Host "  AZURE_RESOURCE_GROUP    = $ResourceGroupName" -ForegroundColor Gray
    Write-Host ''

    Write-Header 'STEP 5: CONFIGURING GITHUB REPOSITORY'
    Write-Step 'Setting GitHub environment variables...'

    $repo = "$GitHubOrganization/$GitHubRepository"

    try {
        Set-GitHubVariable -Name 'AZURE_CLIENT_ID' -Value "$ClientId" -EnvironmentName $EnvironmentName -Repo $repo
        Set-GitHubVariable -Name 'AZURE_TENANT_ID' -Value "$TenantId" -EnvironmentName $EnvironmentName -Repo $repo
        Set-GitHubVariable -Name 'AZURE_SUBSCRIPTION_ID' -Value "$SubscriptionId" -EnvironmentName $EnvironmentName -Repo $repo
        Set-GitHubVariable -Name 'AZURE_RESOURCE_GROUP' -Value "$ResourceGroupName" -EnvironmentName $EnvironmentName -Repo $repo
    } catch {
        Write-Warning "Failed to set some GitHub variables: $($_.Exception.Message)"
        Write-Info 'You can set them manually in GitHub UI or via:'
        Write-Info "  gh variable set <NAME> --body '<VALUE>' --env $EnvironmentName --repo $repo"
    }

    Write-Step 'Configuring management group access...'
    $RootManagementGroupId = $TenantId

    try {
        $detectedMg = Invoke-AzCommand -Command 'account management-group list --query "[?properties.parent==null].name | [0]" -o tsv' -Description 'Detect root management group' -AllowEmptyOutput
        if ($detectedMg) {
            $RootManagementGroupId = $detectedMg.Trim()
            Write-Success "Detected root management group: $RootManagementGroupId"
        } else {
            Write-Info "Could not enumerate management groups - using tenant ID as root MG: $RootManagementGroupId"
        }
    } catch {
        Write-Info "Management group enumeration skipped - using tenant ID as root MG: $RootManagementGroupId"
    }

    try {
        Set-GitHubVariable -Name 'AZURE_MANAGEMENT_GROUP_ID' -Value "$RootManagementGroupId" -EnvironmentName $EnvironmentName -Repo $repo
        Write-Success "AZURE_MANAGEMENT_GROUP_ID set to $RootManagementGroupId"
    } catch {
        Write-Warning "Could not set AZURE_MANAGEMENT_GROUP_ID: $($_.Exception.Message)"
        Write-Info "Set manually: gh variable set AZURE_MANAGEMENT_GROUP_ID --body '$RootManagementGroupId' --env $EnvironmentName --repo $repo"
    }

    Write-Step 'Granting User Access Administrator at management group scope...'
    $mgScope = "/providers/Microsoft.Management/managementGroups/$RootManagementGroupId"
    try {
        Invoke-AzCommand -Command "role assignment create --assignee `"$ClientId`" --role `"User Access Administrator`" --scope `"$mgScope`" --output none" -Description 'Grant User Access Administrator at management group scope' | Out-Null
        Write-Success "User Access Administrator granted at $mgScope"
    } catch {
        Write-Warning "Could not assign User Access Administrator at MG scope: $($_.Exception.Message)"
        Write-Info 'This is needed for bicep-deploy.yml to grant Management Group Reader to the web app identity.'
        Write-Info 'If you have permissions, assign manually:'
        Write-Info "  az role assignment create --assignee $ClientId --role 'User Access Administrator' --scope '$mgScope'"
    }

    Write-Step 'Configuring GitHub Pages...'
    try {
        Invoke-GhCommand -Command "api `"repos/$repo/pages`" --method GET" -Description 'Check GitHub Pages status' | Out-Null
        Write-Success 'GitHub Pages already enabled - skipping'
    } catch {
        try {
            Invoke-GhCommand -Command "api `"repos/$repo/pages`" --method POST --input -" -Description 'Enable GitHub Pages' -StandardInput '{"build_type":"workflow"}' | Out-Null
            Write-Success 'GitHub Pages enabled (source: GitHub Actions)'
        } catch {
            Write-Warning "Could not enable GitHub Pages automatically: $($_.Exception.Message)"
            Write-Info 'Enable manually: Settings -> Pages -> Source -> GitHub Actions'
        }
    }

    Write-Header 'STEP 6: DEPLOYMENT CONFIGURATION'
    Write-Step 'Workflow Configuration (use in .github/workflows/deploy.yml)'
    Write-Host ''
    Write-Host 'environment:' -ForegroundColor Gray
    Write-Host "  name: $EnvironmentName" -ForegroundColor Gray
    Write-Host ''
    Write-Host 'jobs:' -ForegroundColor Gray
    Write-Host '  deploy:' -ForegroundColor Gray
    Write-Host '    environment:' -ForegroundColor Gray
    Write-Host "      name: $EnvironmentName" -ForegroundColor Gray
    Write-Host '    runs-on: ubuntu-latest' -ForegroundColor Gray
    Write-Host '    permissions:' -ForegroundColor Gray
    Write-Host '      contents: read' -ForegroundColor Gray
    Write-Host '      id-token: write' -ForegroundColor Gray
    Write-Host '    steps:' -ForegroundColor Gray
    Write-Host '      - name: Azure Login' -ForegroundColor Gray
    Write-Host '        uses: azure/login@v1' -ForegroundColor Gray
    Write-Host '        with:' -ForegroundColor Gray
    Write-Host '          client-id: ${ vars.AZURE_CLIENT_ID }' -ForegroundColor Gray
    Write-Host '          tenant-id: ${ vars.AZURE_TENANT_ID }' -ForegroundColor Gray
    Write-Host '          subscription-id: ${ vars.AZURE_SUBSCRIPTION_ID }' -ForegroundColor Gray
    Write-Host ''

    Write-Header 'STEP 7: VERIFICATION COMMANDS'
    Write-Step 'Verify setup with these commands:'
    Write-Host ''
    Write-Host '# Verify service principal exists' -ForegroundColor Gray
    Write-Host "az ad sp show --id $ClientId --query '{displayName, appId}'" -ForegroundColor Blue
    Write-Host ''
    Write-Host '# List federated credentials' -ForegroundColor Gray
    Write-Host "az ad app federated-credential list --id $ClientId --query '[].{issuer, subject, audience}'" -ForegroundColor Blue
    Write-Host ''
    Write-Host '# Verify GitHub environment variables' -ForegroundColor Gray
    Write-Host "gh variable list --env $EnvironmentName --repo $repo" -ForegroundColor Blue
    Write-Host ''

    Write-Header 'STEP 8: TESTING GITHUB OIDC'
    Write-Step 'Create a test workflow to verify OIDC works:'
    Write-Host ''
    Write-Host 'name: Test OIDC Login' -ForegroundColor Gray
    Write-Host 'on: workflow_dispatch' -ForegroundColor Gray
    Write-Host ''
    Write-Host 'jobs:' -ForegroundColor Gray
    Write-Host '  test:' -ForegroundColor Gray
    Write-Host "    environment: $EnvironmentName" -ForegroundColor Gray
    Write-Host '    runs-on: ubuntu-latest' -ForegroundColor Gray
    Write-Host '    permissions:' -ForegroundColor Gray
    Write-Host '      contents: read' -ForegroundColor Gray
    Write-Host '      id-token: write' -ForegroundColor Gray
    Write-Host '    steps:' -ForegroundColor Gray
    Write-Host '      - name: Checkout' -ForegroundColor Gray
    Write-Host '        uses: actions/checkout@v4' -ForegroundColor Gray
    Write-Host ''
    Write-Host '      - name: Azure Login' -ForegroundColor Gray
    Write-Host '        uses: azure/login@v1' -ForegroundColor Gray
    Write-Host '        with:' -ForegroundColor Gray
    Write-Host '          client-id: ${ vars.AZURE_CLIENT_ID }' -ForegroundColor Gray
    Write-Host '          tenant-id: ${ vars.AZURE_TENANT_ID }' -ForegroundColor Gray
    Write-Host '          subscription-id: ${ vars.AZURE_SUBSCRIPTION_ID }' -ForegroundColor Gray
    Write-Host ''
    Write-Host '      - name: Test Azure CLI' -ForegroundColor Gray
    Write-Host '        run: az account show' -ForegroundColor Gray
    Write-Host ''

    Write-Header 'STEP 9: CLEANUP (IF NEEDED)'
    Write-Step 'If you need to delete the service principal:'
    Write-Host ''
    Write-Host '# Delete service principal' -ForegroundColor Gray
    Write-Host "az ad sp delete --id $ClientId" -ForegroundColor Yellow
    Write-Host ''

    Write-Header '✓ GITHUB OIDC BOOTSTRAP COMPLETE'
    Write-Step 'Summary'
    Write-Host ''
    Write-Host '✓ Service Principal Created' -ForegroundColor Green
    Write-Host "  ID: $ClientId"
    Write-Host '  Roles: Contributor + User Access Administrator (subscription scope)'
    Write-Host ''
    Write-Host '✓ GitHub Federated Credentials Configured' -ForegroundColor Green
    Write-Host '  - Main branch deployments'
    Write-Host '  - Pull request deployments'
    Write-Host "  - Environment: $EnvironmentName"
    Write-Host ''
    Write-Host '✓ GitHub Environment Variables Set' -ForegroundColor Green
    Write-Host "  Environment: $EnvironmentName"
    Write-Host '  Variables: AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID, AZURE_RESOURCE_GROUP, AZURE_MANAGEMENT_GROUP_ID'
    Write-Host ''
    Write-Host '✓ Management Group Configured' -ForegroundColor Green
    Write-Host "  Root MG: $RootManagementGroupId"
    Write-Host '  Deployment SPN granted User Access Administrator at MG scope (enables post-deploy MG Reader assignment)'
    Write-Host ''
    Write-Host '✓ GitHub Pages Configured' -ForegroundColor Green
    Write-Host '  Source: GitHub Actions (docs.yml deploys on push to main)'
    Write-Host ''
    Write-Host '🎯 Next Steps:' -ForegroundColor Blue
    Write-Host ''
    Write-Host '1. Deploy Azure infrastructure (creates all resources + pushes resource vars):'
    Write-Host "   gh workflow run bicep-deploy.yml --repo $repo"
    Write-Host '   This deploys Bicep and automatically pushes SQL_SERVER_NAME,'
    Write-Host '   SQL_DATABASE_NAME, and AZURE_WEBAPP_NAME as repo vars.'
    Write-Host ''
    Write-Host '2. Deploy the application:'
    Write-Host "   gh workflow run deploy.yml --repo $repo"
    Write-Host ''
    Write-Host '3. Run database schema migration:'
    Write-Host "   gh workflow run sql-schema.yml --repo $repo"
    Write-Host ''
    Write-Host '📚 Documentation: https://github.com/Azure/login#github-oidc' -ForegroundColor Blue
    Write-Host ''
} catch {
    Write-Failure $_.Exception.Message
    exit 1
}
