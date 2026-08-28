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

# Winget updates the user PATH, but an already-running Explorer process may not
# see it until the next sign-in. Locate NuGet directly so native WebView plugin
# dependencies can still be restored on the first launch after setup.
if (-not (Get-Command nuget.exe -ErrorAction SilentlyContinue)) {
    $wingetPackages = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
    $nuget = Get-ChildItem -Path $wingetPackages -Filter nuget.exe -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -like '*Microsoft.NuGet_*' } |
        Select-Object -First 1
    if ($nuget) {
        $env:Path = "$(Split-Path -Parent $nuget.FullName);$env:Path"
    }
}

Write-Host 'Starting Hi Hat' -ForegroundColor Green
& $flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'Flutter dependency setup failed.' }
& $flutter run -d windows
if ($LASTEXITCODE -ne 0) { throw "Flutter exited with code $LASTEXITCODE." }
