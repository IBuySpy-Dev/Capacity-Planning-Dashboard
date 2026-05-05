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
    [string]$ServicePrincipalId = "81dfa11c-e554-4186-bb38-ae7113862478",
    
    [Parameter(Mandatory = $false)]
    [string]$TenantId = "72f988bf-86f1-41af-91ab-2d7cd011db47",
    
    [Parameter(Mandatory = $false)]
    [string]$GitHubOrganization = "IBuySpy-Dev",
    
    [Parameter(Mandatory = $false)]
    [string]$GitHubRepository = "Capacity-Planning-Dashboard",
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipOIDC,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipCAPolicy,
    
    [Parameter(Mandatory = $false)]
    [switch]$TriggerDeployment,
    
    [Parameter(Mandatory = $false)]
    [switch]$WaitForDeployment
)

# Colors
$COLORS = @{
    Header    = "Cyan"
    Success   = "Green"
    Warning   = "Yellow"
    Error     = "Red"
    Info      = "Blue"
}

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor $COLORS.Header
    Write-Host "║ $($Text.PadRight(60)) ║" -ForegroundColor $COLORS.Header
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor $COLORS.Header
}

function Write-Section {
    param([string]$Text)
    Write-Host ""
    Write-Host "▶  $Text" -ForegroundColor $COLORS.Header
}

function Write-Success {
    param([string]$Text)
    Write-Host "✓ $Text" -ForegroundColor $COLORS.Success
}

function Write-Info {
    param([string]$Text)
    Write-Host "ℹ️  $Text" -ForegroundColor $COLORS.Info
}

function Write-Warning {
    param([string]$Text)
    Write-Host "⚠️  $Text" -ForegroundColor $COLORS.Warning
}

function Write-Error {
    param([string]$Text)
    Write-Host "✗ $Text" -ForegroundColor $COLORS.Error
}

function Ask-Confirm {
    param(
        [string]$Message,
        [bool]$DefaultYes = $true
    )
    $default = if ($DefaultYes) { "[Y/n]" } else { "[y/N]" }
    $response = Read-Host "$Message $default"
    
    if ([string]::IsNullOrWhiteSpace($response)) {
        return $DefaultYes
    }
    
    return $response -match "^[Yy]"
}

# ============================================================================
# MAIN WORKFLOW
# ============================================================================

Write-Header "Capacity Dashboard: Bootstrap & Deployment"

Write-Info "Configuration:"
Write-Info "  GitHub Org: $GitHubOrganization"
Write-Info "  GitHub Repo: $GitHubRepository"
Write-Info "  Service Principal: $ServicePrincipalId"
Write-Info "  Tenant: $TenantId"
Write-Host ""

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ============================================================================
# STEP 1: GitHub OIDC Bootstrap (Optional)
# ============================================================================
if (-not $SkipOIDC) {
    Write-Header "STEP 1: GitHub OIDC Bootstrap"
    
    Write-Info "This step configures GitHub OIDC federation for deployments."
    Write-Info "It needs to run only once per repository."
    Write-Host ""
    
    if (Ask-Confirm "Run GitHub OIDC bootstrap?" $true) {
        Write-Section "Executing GitHub OIDC bootstrap..."
        
        & "$scriptDir/bootstrap-github-oidc.ps1" `
            -SubscriptionId $TenantId `
            -ResourceGroupName "rg-capdash-prod" `
            -GitHubOrganization $GitHubOrganization `
            -GitHubRepository $GitHubRepository
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "GitHub OIDC bootstrap completed"
        } else {
            Write-Error "GitHub OIDC bootstrap failed"
            exit 1
        }
    }
} else {
    Write-Info "Skipping GitHub OIDC bootstrap (--SkipOIDC flag set)"
}

# ============================================================================
# STEP 2: CA Policy Bootstrap (Optional)
# ============================================================================
if (-not $SkipCAPolicy) {
    Write-Header "STEP 2: Conditional Access Policy Check"
    
    Write-Info "This step checks and configures Conditional Access policies."
    Write-Info "Required if deployment fails with AADSTS53003 error."
    Write-Host ""
    
    if (Ask-Confirm "Check/configure CA policies?" $true) {
        Write-Section "Checking current CA policy status..."
        
        & "$scriptDir/bootstrap-ca-policy.ps1" `
            -ServicePrincipalId $ServicePrincipalId `
            -TenantId $TenantId `
            -Mode check
        
        Write-Host ""
        Write-Info "CA Policy Options:"
        Write-Info "  1. 'check'           - Show current policies (read-only)"
        Write-Info "  2. 'exempt'          - Manual exemption steps"
        Write-Info "  3. 'create-exception' - Create policy exception"
        Write-Host ""
        
        $mode = Read-Host "Select mode (1-3) or press Enter to skip"
        
        if ($mode -match "^[1-3]$") {
            $modeMap = @{
                "1" = "check"
                "2" = "exempt"
                "3" = "create-exception"
            }
            
            $selectedMode = $modeMap[$mode]
            
            Write-Section "Running CA policy bootstrap with mode: $selectedMode..."
            
            & "$scriptDir/bootstrap-ca-policy.ps1" `
                -ServicePrincipalId $ServicePrincipalId `
                -TenantId $TenantId `
                -Mode $selectedMode
            
            Write-Host ""
            Write-Warning "After manual CA policy changes, deployment may succeed"
            Write-Warning "If still seeing AADSTS53003, contact Azure AD administrator"
        }
    }
} else {
    Write-Info "Skipping CA policy bootstrap (--SkipCAPolicy flag set)"
}

# ============================================================================
# STEP 3: Trigger Deployment
# ============================================================================
Write-Header "STEP 3: Deploy to Production"

$shouldDeploy = if ($TriggerDeployment) {
    $true
} else {
    Ask-Confirm "Trigger deployment workflow?" $false
}

if ($shouldDeploy) {
    Write-Section "Triggering deployment workflow..."
    
    $repo = "$GitHubOrganization/$GitHubRepository"
    
    try {
        gh workflow run deploy.yml --repo $repo -f environment=prod
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Deployment workflow triggered"
            
            if ($WaitForDeployment) {
                Write-Section "Waiting for deployment to complete..."
                
                Start-Sleep -Seconds 3
                
                $maxWait = 600  # 10 minutes
                $elapsed = 0
                $checkInterval = 10
                
                do {
                    Start-Sleep -Seconds $checkInterval
                    $elapsed += $checkInterval
                    
                    $runs = gh run list --repo $repo --workflow deploy.yml --limit 1 --json status,conclusion 2>&1 | ConvertFrom-Json
                    
                    if ($runs.Count -gt 0) {
                        $run = $runs[0]
                        $pct = [Math]::Round(($elapsed / $maxWait) * 100)
                        Write-Host "[$pct%] Status: $($run.status) | Conclusion: $($run.conclusion)" -ForegroundColor Cyan
                        
                        if ($run.status -eq "completed") {
                            Write-Host ""
                            if ($run.conclusion -eq "success") {
                                Write-Success "Deployment completed successfully!"
                            } else {
                                Write-Error "Deployment failed with conclusion: $($run.conclusion)"
                                exit 1
                            }
                            break
                        }
                    }
                    
                    if ($elapsed -ge $maxWait) {
                        Write-Warning "Timeout waiting for deployment (10 minutes)"
                        Write-Info "Check GitHub Actions for status: https://github.com/$repo/actions"
                        break
                    }
                } while ($true)
            }
        } else {
            Write-Error "Failed to trigger deployment workflow"
            exit 1
        }
    } catch {
        Write-Error "Deployment trigger failed: $_"
        exit 1
    }
}

Write-Host ""
Write-Success "Bootstrap and deployment workflow completed"
Write-Host ""
Write-Info "Next steps:"
Write-Info "  1. Check GitHub Actions for deployment status"
Write-Info "  2. Verify app deployed successfully"
Write-Info "  3. Test API endpoints"
Write-Info "  4. Verify React UI displays data"
Write-Host ""
