[CmdletBinding()]
param(
    [string]$Query = 'public-domain-fixture',
    [Parameter(Mandatory = $true)]
    [string]$OutputPath,
    [int]$TimeoutSeconds = 120,
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'

if ($Query -ne 'public-domain-fixture') {
    throw 'No authorized automated online acquisition hook is configured. Use the public-domain-fixture query or complete provider acquisition interactively.'
}

$fixture = Join-Path $ProjectRoot 'backend\tests\assets\player_test.flac'
if (-not (Test-Path -LiteralPath $fixture)) {
    throw "Public-domain FLAC fixture is missing: $fixture"
}

$acquisitionRoot = Join-Path $env:LOCALAPPDATA 'HiHat\Acquisitions\smoke-public-domain'
New-Item -ItemType Directory -Force -Path $acquisitionRoot | Out-Null
$partPath = Join-Path $acquisitionRoot 'incoming.flac.part'
$finalPath = Join-Path $acquisitionRoot 'incoming.flac'

Copy-Item -LiteralPath $fixture -Destination $partPath -Force
Move-Item -LiteralPath $partPath -Destination $finalPath -Force

$outputDirectory = Split-Path -Parent $OutputPath
if ($outputDirectory) {
    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}
Set-Content -LiteralPath $OutputPath -Value $finalPath -NoNewline
Write-Host "Acquired permitted public-domain fixture: $finalPath"
exit 0
