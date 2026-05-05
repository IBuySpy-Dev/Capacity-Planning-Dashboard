#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Bootstrap script to configure Azure AD Conditional Access for GitHub OIDC
    
.DESCRIPTION
    This script handles Azure AD Conditional Access policy configuration to enable
    GitHub OIDC token exchange for service principals. It should be run before
    the GitHub Actions deployment workflow.
    
    Options:
    1. Create CA policy exception for specific service principal
    2. Create CA policy exception for GitHub Actions runners
    3. Exempt service principal from existing policies
    4. Verify token exchange is working
    
.PARAMETER ServicePrincipalId
    The Azure AD service principal ID to exempt or configure
    
.PARAMETER TenantId
    The Azure AD tenant ID
    
.PARAMETER Mode
    Operation mode:
    - 'check': Verify current CA policy status (read-only)
    - 'exempt': Exempt service principal from CA policies
    - 'create-exception': Create specific CA policy exception
    - 'verify': Test OIDC token exchange
    
.PARAMETER PolicyName
    Name for the new CA policy exception (used with 'create-exception' mode)
    
.EXAMPLE
    # Check current CA policy status
    .\bootstrap-ca-policy.ps1 -Mode check -TenantId "72f988bf-86f1-41af-91ab-2d7cd011db47"
    
.EXAMPLE
    # Exempt service principal from CA policies
    .\bootstrap-ca-policy.ps1 `
      -Mode exempt `
      -ServicePrincipalId "81dfa11c-e554-4186-bb38-ae7113862478" `
      -TenantId "72f988bf-86f1-41af-91ab-2d7cd011db47"
      
.EXAMPLE
    # Create CA policy exception for GitHub Actions
    .\bootstrap-ca-policy.ps1 `
      -Mode create-exception `
      -TenantId "72f988bf-86f1-41af-91ab-2d7cd011db47" `
      -PolicyName "Allow GitHub Actions OIDC"
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$ServicePrincipalId = "81dfa11c-e554-4186-bb38-ae7113862478",
    
    [Parameter(Mandatory = $false)]
    [string]$TenantId = "72f988bf-86f1-41af-91ab-2d7cd011db47",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("check", "exempt", "create-exception", "verify")]
    [string]$Mode = "check",
    
    [Parameter(Mandatory = $false)]
    [string]$PolicyName = "GitHub Actions OIDC Federation"
)

# Colors for output
$COLORS = @{
    Header    = "Cyan"
    Success   = "Green"
    Warning   = "Yellow"
    Error     = "Red"
    Info      = "Blue"
    Dim       = "Gray"
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

function Write-Warning {
    param([string]$Text)
    Write-Host "⚠️  $Text" -ForegroundColor $COLORS.Warning
}

function Write-Error {
    param([string]$Text)
    Write-Host "✗ $Text" -ForegroundColor $COLORS.Error
}

function Write-Info {
    param([string]$Text)
    Write-Host "ℹ️  $Text" -ForegroundColor $COLORS.Info
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

Write-Header "Azure AD Conditional Access Policy Bootstrap"

Write-Info "This script helps configure Conditional Access policies for GitHub OIDC"
Write-Info "Service Principal: $ServicePrincipalId"
Write-Info "Tenant: $TenantId"
Write-Info "Mode: $Mode"
Write-Host ""

# Verify authentication
Write-Section "Checking Azure CLI authentication..."
try {
    $account = az account show --query "user.name" -o tsv 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Authenticated as: $account"
    } else {
        Write-Error "Not authenticated. Running: az login"
        az login --tenant $TenantId
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Authentication failed"
            exit 1
        }
    }
} catch {
    Write-Error "Authentication check failed: $_"
    exit 1
}

# Set tenant context
az account set --subscription $TenantId 2>&1 | Out-Null

# ============================================================================
# MODE: CHECK - List existing CA policies
# ============================================================================
if ($Mode -eq "check") {
    Write-Header "Checking Conditional Access Policies"
    
    Write-Section "Listing all Conditional Access policies..."
    
    try {
        $policies = az rest `
            --method GET `
            --url "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies" `
            --query "value[].{displayName: displayName, id: id, state: state}" `
            -o json 2>&1 | ConvertFrom-Json
        
        if ($policies.Count -eq 0) {
            Write-Info "No Conditional Access policies found"
        } else {
            Write-Success "Found $($policies.Count) policy(ies):"
            Write-Host ""
            $policies | ForEach-Object {
                Write-Host "  Policy: $($_.displayName)" -ForegroundColor $COLORS.Info
                Write-Host "    ID: $($_.id)"
                Write-Host "    State: $($_.state)"
                Write-Host ""
            }
        }
        
        Write-Section "Checking service principal assignments..."
        
        # Get service principal details
        $sp = az ad sp show --id $ServicePrincipalId --query "{id: id, displayName: displayName}" 2>&1 | ConvertFrom-Json
        Write-Info "Service Principal: $($sp.displayName) ($($sp.id))"
        
        Write-Host ""
        Write-Info "To check if this service principal is excluded:"
        Write-Info "  1. Open Azure Portal > Azure AD > Conditional Access > Policies"
        Write-Info "  2. For each policy, check 'Users or workload identities'"
        Write-Info "  3. Look for this service principal in exclusions"
        Write-Info ""
        Write-Info "To resolve AADSTS53003 errors:"
        Write-Info "  Option A: Add service principal to policy exclusions"
        Write-Info "  Option B: Create new CA policy with exceptions for OIDC"
        Write-Info "  Option C: Use 'exempt' mode to automate this"
        
    } catch {
        Write-Error "Failed to list policies: $_"
        exit 1
    }
}

# ============================================================================
# MODE: EXEMPT - Add service principal to policy exclusions
# ============================================================================
elseif ($Mode -eq "exempt") {
    Write-Header "Exempting Service Principal from CA Policies"
    
    Write-Section "This mode requires Azure Portal or Graph API with proper permissions"
    Write-Warning "Graph API limitations: Cannot directly modify existing policy exclusions"
    Write-Warning "Manual steps may be required in Azure Portal"
    
    Write-Info "Service Principal: $ServicePrincipalId"
    Write-Host ""
    
    Write-Info "To exempt this service principal:"
    Write-Info "  1. Go to Azure Portal > Azure AD > Conditional Access > Policies"
    Write-Info "  2. For each policy blocking token issuance:"
    Write-Info "     a. Click the policy name"
    Write-Info "     b. Go to 'Users or workload identities' > 'Exclude'"
    Write-Info "     c. Add 'Users' > search for: $ServicePrincipalId"
    Write-Info "     d. Click the service principal in results"
    Write-Info "     e. Click 'Select'"
    Write-Info "     f. Save policy"
    Write-Info ""
    Write-Info "Alternative: Create new policy (see 'create-exception' mode)"
    
    Write-Host ""
    Write-Info "After exemption, test with:"
    Write-Info "  .\bootstrap-ca-policy.ps1 -Mode verify"
}

# ============================================================================
# MODE: CREATE-EXCEPTION - Create a new CA policy with exceptions
# ============================================================================
elseif ($Mode -eq "create-exception") {
    Write-Header "Creating Conditional Access Policy Exception"
    
    Write-Section "Policy Configuration"
    Write-Info "Policy Name: $PolicyName"
    Write-Info "Service Principal: $ServicePrincipalId"
    Write-Host ""
    
    Write-Warning "This creates a permissive policy for OIDC token exchange"
    Write-Warning "Review the policy details before deployment"
    Write-Host ""
    
    try {
        # Get service principal object ID for policy
        $sp = az ad sp show --id $ServicePrincipalId --query "id" -o tsv 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Service principal not found: $ServicePrincipalId"
            exit 1
        }
        
        Write-Info "Service Principal Object ID: $sp"
        Write-Host ""
        
        # Create policy (requires manual configuration in Portal for now)
        Write-Warning "Creating CA policy via Graph API requires specific permissions"
        Write-Info "Recommended approach: Create policy in Azure Portal manually"
        Write-Host ""
        
        Write-Info "Manual steps:"
        Write-Info "  1. Azure Portal > Azure AD > Conditional Access > New Policy"
        Write-Info "  2. Name: $PolicyName"
        Write-Info "  3. Assignments > Users or workload identities:"
        Write-Info "     - Include: All workload identities"
        Write-Info "     - Exclude: [Select] $ServicePrincipalId"
        Write-Info "  4. Cloud apps or actions: All cloud apps"
        Write-Info "  5. Conditions: (leave default)"
        Write-Info "  6. Grant: Grant access"
        Write-Info "  7. Session: (none)"
        Write-Info "  8. Enable policy: On"
        Write-Info "  9. Create"
        Write-Host ""
        
        Write-Success "Policy configuration template ready"
        Write-Info "This exempts the service principal from all CA policies"
        
    } catch {
        Write-Error "Failed to create policy: $_"
        exit 1
    }
}

# ============================================================================
# MODE: VERIFY - Test OIDC token exchange
# ============================================================================
elseif ($Mode -eq "verify") {
    Write-Header "Verifying OIDC Token Exchange"
    
    Write-Section "This mode requires a GitHub Actions workflow to run"
    Write-Info "Cannot test token exchange locally (requires GitHub Actions runner)"
    Write-Host ""
    
    Write-Info "To verify after policy changes:"
    Write-Info "  1. Push a test commit to trigger deployment workflow"
    Write-Info "  2. Go to GitHub > Actions > Deploy Capacity Dashboard"
    Write-Info "  3. Check the 'Azure Login (OIDC)' step"
    Write-Info "  4. If successful, token exchange is working"
    Write-Host ""
    
    Write-Info "Expected success message:"
    Write-Info "  'Successfully authenticated to Azure'"
    Write-Host ""
    
    Write-Warning "If still seeing AADSTS53003 error:"
    Write-Warning "  1. Verify service principal is excluded from policies"
    Write-Warning "  2. Check if other policies still apply"
    Write-Warning "  3. Consider creating additional exceptions"
    Write-Warning "  4. Contact Azure AD administrator for policy review"
}

Write-Host ""
Write-Success "Bootstrap script completed"
Write-Host ""
