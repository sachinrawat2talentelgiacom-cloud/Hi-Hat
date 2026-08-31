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
    throw 'DEEPL_KEY_MISSING: Add HI_HAT_DEEPL_API_KEY to backend/.env before building. No installer was created.'
}

if (-not (Test-Path -LiteralPath $flutter)) {
    $flutterCommand = Get-Command flutter.bat -ErrorAction SilentlyContinue
    if (-not $flutterCommand) { throw 'Flutter SDK was not found.' }
    $flutter = $flutterCommand.Source
}

$isccCandidates = @(
    (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 7\ISCC.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe'),
    (Join-Path ${env:ProgramFiles} 'Inno Setup 7\ISCC.exe'),
    (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe')
)
$iscc = $isccCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $iscc) { throw 'Inno Setup is not installed. Install JRSoftware.InnoSetup with winget.' }

Push-Location $clientRoot
try {
    & $flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Flutter dependency setup failed.' }
    & $flutter build windows --release --dart-define="DEEPL_API_KEY=$env:HI_HAT_DEEPL_API_KEY"
    if ($LASTEXITCODE -ne 0) { throw 'Flutter Windows release build failed.' }
} finally {
    Pop-Location
}

& $iscc (Join-Path $projectRoot 'installer\HiHat.iss')
if ($LASTEXITCODE -ne 0) { throw 'Installer compilation failed.' }

Get-ChildItem -LiteralPath (Join-Path $projectRoot 'dist') -Filter 'HiHat-Setup-*.exe' |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1 -ExpandProperty FullName
