#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Complete bootstrap and deployment orchestration script

.DESCRIPTION
    Runs the complete bootstrap workflow:
    1. GitHub OIDC setup (if needed)
    2. CA policy configuration (if needed)
    3. Deploy to production

    This is the main entry point for production deployment.

.PARAMETER ServicePrincipalId
    Azure AD service principal ID (default: github-oidc-capdash)

.PARAMETER SubscriptionId
    Azure subscription ID for OIDC bootstrap. When omitted, the active Azure CLI
    subscription is used.

.PARAMETER SkipOIDC
    Skip OIDC bootstrap if already configured

.PARAMETER SkipCAPolicy
    Skip CA policy bootstrap if already fixed

.PARAMETER TriggerDeployment
    Automatically trigger deployment workflow after bootstrap

.PARAMETER WaitForDeployment
    Wait for deployment workflow to complete

.EXAMPLE
    # Full workflow with interactive prompts
    .\bootstrap-and-deploy.ps1

.EXAMPLE
    # Skip to deployment after CA policy is fixed
    .\bootstrap-and-deploy.ps1 -SkipOIDC -SkipCAPolicy -TriggerDeployment -WaitForDeployment
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$ServicePrincipalId = '81dfa11c-e554-4186-bb38-ae7113862478',

    [Parameter(Mandatory = $false)]
    [string]$TenantId = '72f988bf-86f1-41af-91ab-2d7cd011db47',

    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $false)]
    [string]$GitHubOrganization = 'IBuySpy-Dev',

    [Parameter(Mandatory = $false)]
    [string]$GitHubRepository = 'Capacity-Planning-Dashboard',

    [Parameter(Mandatory = $false)]
    [switch]$SkipOIDC,

    [Parameter(Mandatory = $false)]
    [switch]$SkipCAPolicy,

    [Parameter(Mandatory = $false)]
    [switch]$TriggerDeployment,

    [Parameter(Mandatory = $false)]
    [switch]$WaitForDeployment
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module (Join-Path $scriptDir 'BootstrapHelpers.psm1') -Force -ErrorAction Stop

function Ask-Confirm {
    param(
        [string]$Message,
        [bool]$DefaultYes = $true
    )

    $default = if ($DefaultYes) { '[Y/n]' } else { '[y/N]' }
    $response = Read-Host "$Message $default"

    if ([string]::IsNullOrWhiteSpace($response)) {
        return $DefaultYes
    }

    return $response -match '^[Yy]'
}

function Resolve-SubscriptionId {
    param([string]$ConfiguredSubscriptionId)

    if ($ConfiguredSubscriptionId) {
        return $ConfiguredSubscriptionId
    }

    try {
        $account = Invoke-AzCommand -Command 'account show --query "{id:id, name:name}" -o json' -Description 'Resolve active Azure subscription' -JsonOutput
        if ($account.id) {
            Write-Info "Using active Azure subscription: $($account.id)"
            return [string]$account.id
        }
    } catch {
        Write-Warning "Could not auto-detect Azure subscription: $($_.Exception.Message)"
    }

    return $null
}

Write-DebugDetail 'BOOTSTRAP_DEBUG enabled'
Write-Header 'Capacity Dashboard: Bootstrap & Deployment'

Write-Info 'Configuration:'
Write-Info "  GitHub Org: $GitHubOrganization"
Write-Info "  GitHub Repo: $GitHubRepository"
Write-Info "  Service Principal: $ServicePrincipalId"
Write-Info "  Tenant: $TenantId"
if ($SubscriptionId) {
    Write-Info "  Subscription: $SubscriptionId"
}
Write-Host ''

if (-not $SkipOIDC) {
    Write-Header 'STEP 1: GitHub OIDC Bootstrap'

    Write-Info 'This step configures GitHub OIDC federation for deployments.'
    Write-Info 'It needs to run only once per repository.'
    Write-Host ''

    if (Ask-Confirm 'Run GitHub OIDC bootstrap?' $true) {
        $effectiveSubscriptionId = Resolve-SubscriptionId -ConfiguredSubscriptionId $SubscriptionId
        if (-not $effectiveSubscriptionId) {
            Write-Failure 'SubscriptionId is required for OIDC bootstrap. Provide -SubscriptionId or authenticate with az login first.'
            exit 1
        }

        Write-Step 'Executing GitHub OIDC bootstrap...'
        Write-DebugDetail "command> & '$scriptDir\bootstrap-github-oidc.ps1' -SubscriptionId '$effectiveSubscriptionId' -ResourceGroupName 'rg-capdash-prod' -GitHubOrganization '$GitHubOrganization' -GitHubRepository '$GitHubRepository'"

        & "$scriptDir\bootstrap-github-oidc.ps1" `
            -SubscriptionId $effectiveSubscriptionId `
            -ResourceGroupName 'rg-capdash-prod' `
            -GitHubOrganization $GitHubOrganization `
            -GitHubRepository $GitHubRepository

        if ($LASTEXITCODE -eq 0) {
            Write-Success 'GitHub OIDC bootstrap completed'
        } else {
            Write-Failure 'GitHub OIDC bootstrap failed'
            exit 1
        }
    }
} else {
    Write-Info 'Skipping GitHub OIDC bootstrap (--SkipOIDC flag set)'
}

if (-not $SkipCAPolicy) {
    Write-Header 'STEP 2: Conditional Access Policy Check'

    Write-Info 'This step checks and configures Conditional Access policies.'
    Write-Info 'Required if deployment fails with AADSTS53003 error.'
    Write-Host ''

    if (Ask-Confirm 'Check/configure CA policies?' $true) {
        Write-Step 'Checking current CA policy status...'
        Write-DebugDetail "command> & '$scriptDir\bootstrap-ca-policy.ps1' -ServicePrincipalId '$ServicePrincipalId' -TenantId '$TenantId' -Mode check"

        & "$scriptDir\bootstrap-ca-policy.ps1" `
            -ServicePrincipalId $ServicePrincipalId `
            -TenantId $TenantId `
            -Mode check

        Write-Host ''
        Write-Info 'CA Policy Options:'
        Write-Info "  1. 'check'            - Show current policies (read-only)"
        Write-Info "  2. 'exempt'           - Manual exemption steps"
        Write-Info "  3. 'create-exception' - Create policy exception"
        Write-Host ''

        $mode = Read-Host 'Select mode (1-3) or press Enter to skip'

        if ($mode -match '^[1-3]$') {
            $modeMap = @{
                '1' = 'check'
                '2' = 'exempt'
                '3' = 'create-exception'
            }

            $selectedMode = $modeMap[$mode]

            Write-Step "Running CA policy bootstrap with mode: $selectedMode..."
            Write-DebugDetail "command> & '$scriptDir\bootstrap-ca-policy.ps1' -ServicePrincipalId '$ServicePrincipalId' -TenantId '$TenantId' -Mode '$selectedMode'"

            & "$scriptDir\bootstrap-ca-policy.ps1" `
                -ServicePrincipalId $ServicePrincipalId `
                -TenantId $TenantId `
                -Mode $selectedMode

            Write-Host ''
            Write-Warning 'After manual CA policy changes, deployment may succeed'
            Write-Warning 'If still seeing AADSTS53003, contact Azure AD administrator'
        }
    }
} else {
    Write-Info 'Skipping CA policy bootstrap (--SkipCAPolicy flag set)'
}

Write-Header 'STEP 3: Deploy to Production'

$shouldDeploy = if ($TriggerDeployment) {
    $true
} else {
    Ask-Confirm 'Trigger deployment workflow?' $false
}

if ($shouldDeploy) {
    Write-Step 'Triggering deployment workflow...'
    $repo = "$GitHubOrganization/$GitHubRepository"

    try {
        Invoke-GhCommand -Command "workflow run deploy.yml --repo `"$repo`" -f environment=prod" -Description 'Trigger deployment workflow' | Out-Null
        Write-Success 'Deployment workflow triggered'

        if ($WaitForDeployment) {
            Write-Step 'Waiting for deployment to complete...'
            Start-Sleep -Seconds 3

            $maxWait = 600
            $elapsed = 0
            $checkInterval = 10

            do {
                Start-Sleep -Seconds $checkInterval
                $elapsed += $checkInterval

                $runs = Invoke-GhCommand -Command "run list --repo `"$repo`" --workflow deploy.yml --limit 1 --json status,conclusion" -Description 'Check deployment workflow status' -JsonOutput -AllowEmptyOutput
                $run = @($runs) | Select-Object -First 1

                if ($run) {
                    $pct = [Math]::Round(($elapsed / $maxWait) * 100)
                    Write-Host ("[{0}%] Status: {1} | Conclusion: {2}" -f $pct, $run.status, $run.conclusion) -ForegroundColor Cyan

                    if ($run.status -eq 'completed') {
                        Write-Host ''
                        if ($run.conclusion -eq 'success') {
                            Write-Success 'Deployment completed successfully!'
                        } else {
                            Write-Failure "Deployment failed with conclusion: $($run.conclusion)"
                            exit 1
                        }

                        break
                    }
                }

                if ($elapsed -ge $maxWait) {
                    Write-Warning 'Timeout waiting for deployment (10 minutes)'
                    Write-Info "Check GitHub Actions for status: https://github.com/$repo/actions"
                    break
                }
            } while ($true)
        }
    } catch {
        Write-Failure "Deployment trigger failed: $($_.Exception.Message)"
        exit 1
    }
}

Write-Host ''
Write-Success 'Bootstrap and deployment workflow completed'
Write-Host ''
Write-Info 'Next steps:'
Write-Info '  1. Check GitHub Actions for deployment status'
Write-Info '  2. Verify app deployed successfully'
Write-Info '  3. Test API endpoints'
Write-Info '  4. Verify React UI displays data'
Write-Host ''
