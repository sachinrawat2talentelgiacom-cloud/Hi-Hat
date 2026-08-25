[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$clientRoot = Join-Path $projectRoot 'client'
$flutter = Join-Path $env:USERPROFILE '.puro\envs\hi_hat\flutter\bin\flutter.bat'

if (-not (Test-Path -LiteralPath $flutter)) {
    $flutterCommand = Get-Command flutter.bat -ErrorAction SilentlyContinue
    if (-not $flutterCommand) {
        throw 'Flutter is not installed. Install Flutter, then start Hi Hat again.'
    }
    $flutter = $flutterCommand.Source
}

Set-Location -LiteralPath $clientRoot
Write-Host 'Starting Hi Hat' -ForegroundColor Green
& $flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'Flutter dependency setup failed.' }
& $flutter run -d windows
if ($LASTEXITCODE -ne 0) { throw "Flutter exited with code $LASTEXITCODE." }
