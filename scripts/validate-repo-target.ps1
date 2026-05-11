<#
.SYNOPSIS
    Validates that a GitHub owner/repo target is on the internal allowlist.
.DESCRIPTION
    Exits non-zero if the target repository is not allowlisted.
    Used by agents and CI workflows before any GitHub write operation.
.PARAMETER Target
    GitHub owner/repo string (e.g., "ivegamsft/Capacity-Planning-Dashboard")
#>
param(
    [Parameter(Mandatory)]
    [string]$Target
)

# Internal repository allowlist — deny by default
$Allowlist = @(
    'ivegamsft/Capacity-Planning-Dashboard'
)

if ($Target -in $Allowlist) {
    Write-Host "✓ Repository '$Target' is on the internal allowlist." -ForegroundColor Green
    exit 0
} else {
    Write-Host "✗ BLOCKED: Repository '$Target' is NOT on the internal allowlist." -ForegroundColor Red
    Write-Host "  GitHub write operations (issue/PR/comment create/edit/close) are denied." -ForegroundColor Red
    Write-Host "  Update scripts/validate-repo-target.ps1 to add new repositories." -ForegroundColor Yellow
    exit 1
}
