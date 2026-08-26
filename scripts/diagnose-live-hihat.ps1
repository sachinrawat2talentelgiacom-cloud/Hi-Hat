[CmdletBinding()]
param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$Query = 'closer',
    [string]$TrackId = 'monochrome:63232677',
    [switch]$Build
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$logRoot = Join-Path $root 'logs\diagnostics'
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
$log = Join-Path $logRoot ('live-{0}.log' -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
Start-Transcript -Path $log -Force | Out-Null
try {
    if ($Build) {
        Push-Location (Join-Path $root 'client')
        try { puro flutter build windows --debug; if ($LASTEXITCODE -ne 0) { throw 'BUILD_FAILED' } } finally { Pop-Location }
    }
    $exe = Join-Path $root 'client\build\windows\x64\runner\Debug\hi_hat.exe'
    $process = Start-Process -FilePath $exe -PassThru
    Start-Sleep -Seconds 5
    & (Join-Path $PSScriptRoot 'hihat-diagnostics-client.ps1') -Command PING
    & (Join-Path $PSScriptRoot 'hihat-diagnostics-client.ps1') -Command SEARCH -PayloadJson (@{ query = $Query } | ConvertTo-Json -Compress) -TimeoutMs 15000
    & (Join-Path $PSScriptRoot 'hihat-diagnostics-client.ps1') -Command PLAY_TRACK -PayloadJson (@{ trackId = $TrackId } | ConvertTo-Json -Compress)
    $deadline = (Get-Date).AddSeconds(185)
    do {
        $raw = & (Join-Path $PSScriptRoot 'hihat-test-client.ps1') -PipeName 'HiHat.Diagnostics' -Command GET_ACQUISITION_STATE -PayloadJson (@{ trackId = $TrackId } | ConvertTo-Json -Compress)
        Write-Host "$(Get-Date -Format o) $raw"
        $state = ($raw | ConvertFrom-Json).state
        if ($state -in @('COMPLETED', 'FAILED', 'AUTH_REQUIRED', 'CANCELLED')) { break }
        Start-Sleep -Seconds 1
    } while ((Get-Date) -lt $deadline)
    if ($state -ne 'COMPLETED') { throw "LIVE_ACQUISITION_$state" }
    exit 0
}
finally {
    if ($process -and -not $process.HasExited) { Stop-Process -Id $process.Id }
    try { Stop-Transcript | Out-Null } catch { Write-Verbose $_ }
}
