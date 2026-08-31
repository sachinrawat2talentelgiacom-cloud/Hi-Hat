[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$clientRoot = Join-Path $projectRoot 'client'
$localConfig = Join-Path $projectRoot 'backend\.env'
$flutter = Join-Path $env:USERPROFILE '.puro\envs\hi_hat\flutter\bin\flutter.bat'

# Desktop lyrics translation calls DeepL directly. Keep the credential in the
# ignored local config and pass it only to the child app process.
if (Test-Path -LiteralPath $localConfig) {
    foreach ($line in Get-Content -LiteralPath $localConfig) {
        if ($line -match '^HI_HAT_DEEPL_API_KEY=(.+)$') {
            $env:HI_HAT_DEEPL_API_KEY = $Matches[1].Trim()
        }
    }
}

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
# Impeller's Windows OpenGL backend intermittently faults inside
# flutter_windows.dll on this machine. Skia avoids that native startup crash.
if ([string]::IsNullOrWhiteSpace($env:HI_HAT_DEEPL_API_KEY)) {
    throw 'DEEPL_KEY_MISSING: Add HI_HAT_DEEPL_API_KEY to backend/.env before starting Hi Hat.'
}
& $flutter run -d windows --no-enable-impeller --dart-define="DEEPL_API_KEY=$env:HI_HAT_DEEPL_API_KEY"
if ($LASTEXITCODE -ne 0) { throw "Flutter exited with code $LASTEXITCODE." }
