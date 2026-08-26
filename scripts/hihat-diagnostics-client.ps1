[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Command,
    [string]$PayloadJson = '{}',
    [int]$TimeoutMs = 5000
)

$ErrorActionPreference = 'Stop'
try {
    $raw = & (Join-Path $PSScriptRoot 'hihat-test-client.ps1') `
        -Command $Command `
        -PayloadJson $PayloadJson `
        -ConnectTimeoutMilliseconds $TimeoutMs `
        -PipeName 'HiHat.Diagnostics'
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    $parsed = $raw | ConvertFrom-Json
    if ($parsed.ok -ne $true) { Write-Error ($raw | Out-String); exit 1 }
    $parsed | ConvertTo-Json -Compress -Depth 20
}
catch {
    Write-Error $_
    exit 1
}
