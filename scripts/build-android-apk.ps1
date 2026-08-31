[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$clientRoot = Join-Path $projectRoot 'client'
$localConfig = Join-Path $projectRoot 'backend\.env'
$flutter = Join-Path $env:USERPROFILE '.puro\envs\hi_hat\flutter\bin\flutter.bat'

if ([string]::IsNullOrWhiteSpace($env:HI_HAT_DEEPL_API_KEY) -and (Test-Path -LiteralPath $localConfig)) {
    foreach ($line in Get-Content -LiteralPath $localConfig) {
        if ($line -match '^HI_HAT_DEEPL_API_KEY=(.+)$') {
            $env:HI_HAT_DEEPL_API_KEY = $Matches[1].Trim()
        }
    }
}
if ([string]::IsNullOrWhiteSpace($env:HI_HAT_DEEPL_API_KEY)) {
    throw 'DEEPL_KEY_MISSING: Add HI_HAT_DEEPL_API_KEY to backend/.env before building.'
}
if (-not (Test-Path -LiteralPath $flutter)) {
    $flutterCommand = Get-Command flutter.bat -ErrorAction SilentlyContinue
    if (-not $flutterCommand) { throw 'Flutter SDK was not found.' }
    $flutter = $flutterCommand.Source
}
if ([string]::IsNullOrWhiteSpace($env:JAVA_HOME)) {
    $androidStudioJdk = 'C:\Program Files\Android\Android Studio\jbr'
    if (-not (Test-Path -LiteralPath (Join-Path $androidStudioJdk 'bin\java.exe'))) {
        throw 'Java was not found. Install Android Studio or set JAVA_HOME.'
    }
    $env:JAVA_HOME = $androidStudioJdk
    $env:Path = "$(Join-Path $androidStudioJdk 'bin');$env:Path"
}

Push-Location $clientRoot
try {
    & $flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Flutter dependency setup failed.' }
    & $flutter build apk --release --dart-define="DEEPL_API_KEY=$env:HI_HAT_DEEPL_API_KEY"
    if ($LASTEXITCODE -ne 0) { throw 'Flutter Android release build failed.' }
    $source = Join-Path $clientRoot 'build\app\outputs\flutter-apk\app-release.apk'
    $destination = Join-Path $clientRoot 'build\app\outputs\flutter-apk\Hi-Hat-Android.apk'
    Copy-Item -LiteralPath $source -Destination $destination -Force
    Write-Output $destination
} finally {
    Pop-Location
}
