[CmdletBinding()]
param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [int]$MaxAttempts = 10,
    [int]$DelaySeconds = 3,
    [string]$SmokeScript = 'scripts\smoke-full-flac.ps1',
    [string]$LogDir = 'logs\flac-loop'
)

$ErrorActionPreference = 'Stop'
$resolvedRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$resolvedLogDir = Join-Path $resolvedRoot $LogDir
New-Item -ItemType Directory -Force -Path $resolvedLogDir | Out-Null
$smokePath = Join-Path $resolvedRoot $SmokeScript
if (-not (Test-Path -LiteralPath $smokePath)) { Write-Error "Smoke test not found: $smokePath"; exit 2 }

for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $logPath = Join-Path $resolvedLogDir ('attempt-{0:D2}-{1}.log' -f $attempt, $timestamp)
    Write-Host "Attempt $attempt / $MaxAttempts" -ForegroundColor Cyan
    try {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $smokePath -ProjectRoot $resolvedRoot *>&1 | Tee-Object -FilePath $logPath
        $exitCode = $LASTEXITCODE
    }
    catch {
        $_ | Out-String | Tee-Object -FilePath $logPath -Append
        $exitCode = 1
    }
    if ($exitCode -eq 0) { Write-Host "SUCCESS - FULL FLAC PIPELINE PASSED on attempt $attempt" -ForegroundColor Green; exit 0 }
    if ($attempt -lt $MaxAttempts) { Start-Sleep -Seconds $DelaySeconds }
}

Write-Host "FAILED - review $resolvedLogDir" -ForegroundColor Red
exit 1
