[CmdletBinding()]
param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot), [int]$MaxAttempts = 5)
$ErrorActionPreference = 'Continue'
for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
    & (Join-Path $PSScriptRoot 'diagnose-live-hihat.ps1') -ProjectRoot $ProjectRoot
    if ($LASTEXITCODE -eq 0) { exit 0 }
    $report = Join-Path $ProjectRoot 'docs\diagnostics\LIVE_FAILURE_ROOT_CAUSE.md'
    if (Test-Path -LiteralPath $report) {
        $text = Get-Content -LiteralPath $report -Raw
        if ($text -match 'AUTH_REQUIRED|external access') { exit 2 }
    }
    if ($attempt -lt $MaxAttempts) { Start-Sleep -Seconds 3 }
}
exit 1
