Set-StrictMode -Version Latest

$script:BootstrapColors = @{
    Header  = 'Cyan'
    Success = 'Green'
    Warning = 'Yellow'
    Error   = 'Red'
    Info    = 'Blue'
    Dim     = 'Gray'
}

function Test-BootstrapDebugEnabled {
    return [string]::Equals($env:BOOTSTRAP_DEBUG, 'true', [System.StringComparison]::OrdinalIgnoreCase)
}

function Format-BootstrapElapsed {
    param([Parameter(Mandatory)][TimeSpan]$Elapsed)

    if ($Elapsed.TotalSeconds -ge 1) {
        return ('{0:N2}s' -f $Elapsed.TotalSeconds)
    }

    return ('{0:N0}ms' -f $Elapsed.TotalMilliseconds)
}

function Convert-CommandResultToText {
    param([Parameter(ValueFromPipeline)]$InputObject)

    begin {
        $lines = New-Object System.Collections.Generic.List[string]
    }

    process {
        if ($null -eq $InputObject) {
            return
        }

        if ($InputObject -is [System.Management.Automation.ErrorRecord]) {
            $lines.Add($InputObject.ToString())
            return
        }

        $lines.Add([string]$InputObject)
    }

    end {
        return ($lines -join [Environment]::NewLine).Trim()
    }
}

function Escape-DoubleQuotedArgument {
    param([AllowNull()][string]$Value)

    if ($null -eq $Value) {
        return ''
    }

    return $Value.Replace('`', '``').Replace('"', '`"').Replace('$', '`$')
}

function Write-Header {
    param([Parameter(Mandatory)][string]$Message)

    Write-Host ''
    Write-Host '╔════════════════════════════════════════════════════════════╗' -ForegroundColor $script:BootstrapColors.Header
    Write-Host ("║ {0} ║" -f $Message.PadRight(60)) -ForegroundColor $script:BootstrapColors.Header
    Write-Host '╚════════════════════════════════════════════════════════════╝' -ForegroundColor $script:BootstrapColors.Header
    Write-Host ''
}

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)

    Write-Host ''
    Write-Host ("▶  {0}" -f $Message) -ForegroundColor $script:BootstrapColors.Info
    Write-Host ''
}

function Write-Success {
    param([Parameter(Mandatory)][string]$Message)

    Write-Host ("✓ {0}" -f $Message) -ForegroundColor $script:BootstrapColors.Success
}

function Write-Failure {
    param([Parameter(Mandatory)][string]$Message)

    Write-Host ("✗ {0}" -f $Message) -ForegroundColor $script:BootstrapColors.Error
}

function Write-Info {
    param([Parameter(Mandatory)][string]$Message)

    Write-Host ("ℹ {0}" -f $Message) -ForegroundColor $script:BootstrapColors.Info
}

function Write-Warning {
    param([Parameter(Mandatory)][string]$Message)

    Write-Host ("⚠ {0}" -f $Message) -ForegroundColor $script:BootstrapColors.Warning
}

function Write-DebugDetail {
    param([Parameter(Mandatory)][string]$Message)

    if (Test-BootstrapDebugEnabled) {
        Write-Host ("[debug] {0}" -f $Message) -ForegroundColor $script:BootstrapColors.Dim
    }
}

function Invoke-TrackedCommand {
    param(
        [Parameter(Mandatory)][string]$Executable,
        [Parameter(Mandatory)][string]$Command,
        [Parameter(Mandatory)][string]$Description,
        [string]$StandardInput,
        [switch]$JsonOutput,
        [switch]$AllowEmptyOutput
    )

    $invocation = "$Executable $Command"
    Write-DebugDetail "command> $invocation"

    $exitCode = 0
    $outputText = ''
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $scriptBlock = [scriptblock]::Create($invocation)
        if ($PSBoundParameters.ContainsKey('StandardInput')) {
            $result = $StandardInput | & $scriptBlock 2>&1
        } else {
            $result = & $scriptBlock 2>&1
        }

        $exitCode = $LASTEXITCODE
        $outputText = $result | Convert-CommandResultToText
    } finally {
        $stopwatch.Stop()
    }

    if (Test-BootstrapDebugEnabled) {
        Write-DebugDetail ("elapsed> {0} for {1}" -f (Format-BootstrapElapsed -Elapsed $stopwatch.Elapsed), $Description)
        if ([string]::IsNullOrWhiteSpace($outputText)) {
            Write-DebugDetail 'output> <empty>'
        } else {
            Write-DebugDetail "output> $outputText"
        }
    }

    if ($exitCode -ne 0) {
        if ([string]::IsNullOrWhiteSpace($outputText)) {
            throw "$Description failed with exit code $exitCode."
        }

        throw "$Description failed with exit code $exitCode.`n$outputText"
    }

    if (-not $JsonOutput) {
        return $outputText
    }

    if ([string]::IsNullOrWhiteSpace($outputText)) {
        if ($AllowEmptyOutput) {
            return $null
        }

        throw "$Description returned empty JSON output."
    }

    try {
        $json = $outputText | ConvertFrom-Json -Depth 20
        if (Test-BootstrapDebugEnabled) {
            Write-DebugDetail ("json> {0}" -f ($json | ConvertTo-Json -Depth 20 -Compress:$false))
        }

        return $json
    } catch {
        throw "$Description returned invalid JSON.`n$outputText"
    }
}

function Invoke-AzCommand {
    param(
        [Parameter(Mandatory)][string]$Command,
        [Parameter(Mandatory)][string]$Description,
        [switch]$JsonOutput,
        [switch]$AllowEmptyOutput
    )

    return Invoke-TrackedCommand -Executable 'az' -Command $Command -Description $Description -JsonOutput:$JsonOutput -AllowEmptyOutput:$AllowEmptyOutput
}

function Invoke-GhCommand {
    param(
        [Parameter(Mandatory)][string]$Command,
        [Parameter(Mandatory)][string]$Description,
        [string]$StandardInput,
        [switch]$JsonOutput,
        [switch]$AllowEmptyOutput
    )

    $invokeParams = @{
        Executable       = 'gh'
        Command          = $Command
        Description      = $Description
        JsonOutput       = $JsonOutput
        AllowEmptyOutput = $AllowEmptyOutput
    }

    if ($PSBoundParameters.ContainsKey('StandardInput')) {
        $invokeParams.StandardInput = $StandardInput
    }

    return Invoke-TrackedCommand @invokeParams
}

function Assert-AzCliReady {
    param([string]$SubscriptionId)

    Write-Step 'Checking Azure CLI...'
    try {
        $azVersion = Invoke-AzCommand -Command '--version' -Description 'Azure CLI version check'
        $versionLine = ($azVersion -split "`r?`n" | Select-Object -First 1).Trim()
        if ($versionLine) {
            Write-Success "Azure CLI: $versionLine"
        } else {
            Write-Success 'Azure CLI is installed'
        }
    } catch {
        Write-Failure 'Azure CLI not found. Install from: https://learn.microsoft.com/cli/azure/install-azure-cli'
        throw
    }

    Write-Step 'Checking Azure authentication...'
    try {
        if ($SubscriptionId) {
            Invoke-AzCommand -Command ("account set --subscription `"{0}`"" -f (Escape-DoubleQuotedArgument -Value $SubscriptionId)) -Description 'Azure subscription selection' | Out-Null
        }

        $account = Invoke-AzCommand -Command 'account show --query "{name:name, id:id, user:user.name}" -o json' -Description 'Azure authentication check' -JsonOutput
        $accountName = if ($account.name) { [string]$account.name } else { [string]$account.id }
        $accountUser = if ($account.user) { [string]$account.user } else { 'unknown user' }
        Write-Success "Authenticated as: $accountName ($accountUser)"
    } catch {
        Write-Failure 'Not authenticated. Run: az login'
        throw
    }
}

function Test-GitHubRepoFormat {
    param([Parameter(Mandatory)][string]$Repo)

    return $Repo -match '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$'
}

function Set-GitHubVariable {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Value,
        [Parameter(Mandatory)][string]$Repo,
        [string]$EnvironmentName
    )

    if (-not (Test-GitHubRepoFormat -Repo $Repo)) {
        throw "Invalid GitHub repository format: $Repo"
    }

    $escapedValue = Escape-DoubleQuotedArgument -Value $Value
    $escapedRepo = Escape-DoubleQuotedArgument -Value $Repo
    $environmentClause = if ($EnvironmentName) {
        ' --env `"{0}`"' -f (Escape-DoubleQuotedArgument -Value $EnvironmentName)
    } else {
        ''
    }

    Invoke-GhCommand -Command ("variable set {0} --body `"{1}`"{2} --repo `"{3}`"" -f $Name, $escapedValue, $environmentClause, $escapedRepo) -Description "Set GitHub variable $Name" | Out-Null
    Write-Success "$Name set"
}

Export-ModuleMember -Function @(
    'Assert-AzCliReady',
    'Invoke-AzCommand',
    'Invoke-GhCommand',
    'Set-GitHubVariable',
    'Write-Header',
    'Write-Step',
    'Write-Success',
    'Write-Failure',
    'Write-Info',
    'Write-Warning',
    'Write-DebugDetail'
)
