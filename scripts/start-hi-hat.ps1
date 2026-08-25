[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$backendRoot = Join-Path $projectRoot 'backend'
$clientRoot = Join-Path $projectRoot 'client'
$helperRoot = Join-Path $projectRoot 'acquisition_helper'
$pythonExe = Join-Path $backendRoot '.venv\Scripts\python.exe'
$envFile = Join-Path $backendRoot '.env'
$envExample = Join-Path $backendRoot '.env.example'
$setupStamp = Join-Path $backendRoot '.launcher-setup-complete'

function Write-Step([string] $Message) {
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Refresh-Path {
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machinePath;$userPath"
}

function Find-Command([string] $Name) {
    return Get-Command $Name -ErrorAction SilentlyContinue
}

function Install-WingetPackage([string] $Id, [string] $Label, [string] $Override = '') {
    if (-not (Find-Command 'winget.exe')) {
        throw "$Label is missing and winget is unavailable. Install App Installer from Microsoft Store, then double-click this launcher again."
    }

    Write-Step "Installing $Label (one-time setup)"
    $arguments = @('install', '--id', $Id, '--exact', '--accept-package-agreements', '--accept-source-agreements')
    if ($Override) {
        $arguments += @('--override', $Override)
    }
    & winget.exe @arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Label installation failed with exit code $LASTEXITCODE."
    }
    Refresh-Path
}

Set-Location -LiteralPath $projectRoot
Write-Host 'Hi Hat launcher' -ForegroundColor Green
Write-Host 'The first launch downloads and installs the required development tools.'

if (-not (Find-Command 'git.exe')) {
    Install-WingetPackage 'Git.Git' 'Git'
}

if (-not (Find-Command 'ffmpeg.exe')) {
    Install-WingetPackage 'Gyan.FFmpeg' 'FFmpeg'
}

if (-not (Find-Command 'dotnet.exe')) {
    Install-WingetPackage 'Microsoft.DotNet.SDK.8' '.NET 8 SDK'
}

$puroExe = $null
$puroCommand = Find-Command 'puro.exe'
if ($puroCommand) {
    $puroExe = $puroCommand.Source
} else {
    $installedPuro = Join-Path $env:USERPROFILE '.puro\bin\puro.exe'
    if (Test-Path -LiteralPath $installedPuro) {
        $puroExe = $installedPuro
    }
}

if (-not $puroExe) {
    Write-Step 'Installing the Puro Flutter manager (one-time setup)'
    $puroInstaller = Join-Path $env:TEMP 'hi-hat-puro.exe'
    Invoke-WebRequest -Uri 'https://puro.dev/builds/1.5.0/windows-x64/puro.exe' -OutFile $puroInstaller
    & $puroInstaller install-puro --promote
    if ($LASTEXITCODE -ne 0) {
        throw "Puro installation failed with exit code $LASTEXITCODE."
    }
    Refresh-Path
    $puroExe = Join-Path $env:USERPROFILE '.puro\bin\puro.exe'
    if (-not (Test-Path -LiteralPath $puroExe)) {
        $puroCommand = Find-Command 'puro.exe'
        if ($puroCommand) { $puroExe = $puroCommand.Source }
    }
    if (-not $puroExe -or -not (Test-Path -LiteralPath $puroExe)) {
        throw 'Puro installed but its executable could not be found. Restart Windows and try again.'
    }
}

$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
$visualCppPath = $null
if (Test-Path -LiteralPath $vswhere) {
    $visualCppPath = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
}
if (-not $visualCppPath) {
    Install-WingetPackage 'Microsoft.VisualStudio.2022.BuildTools' 'Visual Studio C++ Build Tools' '--wait --passive --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended'
}

if (-not (Test-Path -LiteralPath $pythonExe)) {
    $systemPython = Find-Command 'python.exe'
    if (-not $systemPython) {
        Install-WingetPackage 'Python.Python.3.12' 'Python 3.12'
        $systemPython = Find-Command 'python.exe'
    }
    if (-not $systemPython) {
        throw 'Python could not be found after installation. Restart Windows and try again.'
    }
    Write-Step 'Creating the backend Python environment'
    & $systemPython.Source -m venv (Join-Path $backendRoot '.venv')
}

if (-not (Test-Path -LiteralPath $envFile)) {
    Write-Step 'Creating a secure local backend configuration'
    $bytes = New-Object byte[] 32
    $generator = [Security.Cryptography.RandomNumberGenerator]::Create()
    try { $generator.GetBytes($bytes) } finally { $generator.Dispose() }
    $token = [Convert]::ToBase64String($bytes).Replace('+', '-').Replace('/', '_').TrimEnd('=')
    $configuration = (Get-Content -LiteralPath $envExample -Raw).Replace('replace-with-a-long-random-token', $token)
    [IO.File]::WriteAllText($envFile, $configuration, (New-Object Text.UTF8Encoding($false)))
}

$tokenLine = Get-Content -LiteralPath $envFile | Where-Object { $_ -match '^HI_HAT_API_TOKEN=' } | Select-Object -First 1
if (-not $tokenLine) { throw 'HI_HAT_API_TOKEN is missing from backend\.env.' }
$apiToken = ($tokenLine -split '=', 2)[1].Trim()
if (-not $apiToken) { throw 'HI_HAT_API_TOKEN is empty in backend\.env.' }

$pyproject = Join-Path $backendRoot 'pyproject.toml'
$needsPythonSetup = -not (Test-Path -LiteralPath $setupStamp)
if (-not $needsPythonSetup) {
    $needsPythonSetup = (Get-Item -LiteralPath $pyproject).LastWriteTimeUtc -gt (Get-Item -LiteralPath $setupStamp).LastWriteTimeUtc
}
if ($needsPythonSetup) {
    Write-Step 'Installing backend packages'
    & $pythonExe -m pip install -e "$backendRoot[dev]"
    if ($LASTEXITCODE -ne 0) { throw 'Backend package installation failed.' }
    New-Item -ItemType File -Path $setupStamp -Force | Out-Null
}

$puroEnvironment = Join-Path $env:USERPROFILE '.puro\envs\hi_hat'
if (-not (Test-Path -LiteralPath $puroEnvironment)) {
    Write-Step 'Downloading Flutter 3.47.1 (one-time setup)'
    & $puroExe create hi_hat 3.47.1
    if ($LASTEXITCODE -ne 0) { throw 'Flutter environment setup failed.' }
}

Write-Step 'Preparing the Flutter app'
Push-Location -LiteralPath $clientRoot
try {
    & $puroExe flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Flutter package installation failed.' }
} finally {
    Pop-Location
}

$backendIsRunning = $false
try {
    $backendIsRunning = Test-NetConnection -ComputerName 127.0.0.1 -Port 8765 -InformationLevel Quiet -WarningAction SilentlyContinue
} catch {}

if (-not $backendIsRunning) {
    Write-Step 'Starting the backend'
    $backendScript = Join-Path $PSScriptRoot 'start-backend.ps1'
    Start-Process powershell.exe -WindowStyle Minimized -ArgumentList @(
        '-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $backendScript)
    ) | Out-Null

    $backendReady = $false
    foreach ($attempt in 1..30) {
        Start-Sleep -Milliseconds 500
        try {
            if (Test-NetConnection -ComputerName 127.0.0.1 -Port 8765 -InformationLevel Quiet -WarningAction SilentlyContinue) {
                $backendReady = $true
                break
            }
        } catch {}
    }
    if (-not $backendReady) { throw 'The backend did not start. Check the minimized backend window for details.' }
}

$helperIsRunning = $false
try {
    $helperIsRunning = Test-NetConnection -ComputerName 127.0.0.1 -Port 8876 -InformationLevel Quiet -WarningAction SilentlyContinue
} catch {}

if (-not $helperIsRunning) {
    Write-Step 'Building the provider browser helper'
    & dotnet build $helperRoot --configuration Release
    if ($LASTEXITCODE -ne 0) { throw 'The provider browser helper failed to build.' }
    $helperExe = Join-Path $helperRoot 'bin\Release\net48\HiHat.AcquisitionHelper.exe'
    if (-not (Test-Path -LiteralPath $helperExe)) { throw 'The provider browser helper executable is missing.' }
    Write-Step 'Starting the provider browser helper in visible verification mode'
    Start-Process -FilePath $helperExe | Out-Null
    $helperReady = $false
    foreach ($attempt in 1..40) {
        Start-Sleep -Milliseconds 500
        try {
            $health = Invoke-RestMethod -Uri 'http://127.0.0.1:8876/health' -TimeoutSec 2
            if ($health.webview_ready) { $helperReady = $true; break }
        } catch {}
    }
    if (-not $helperReady) { throw 'The provider browser helper did not become ready.' }
}

Write-Step 'Launching Hi Hat'
Set-Location -LiteralPath $clientRoot
& $puroExe flutter run -d windows "--dart-define=HI_HAT_API_TOKEN=$apiToken"
if ($LASTEXITCODE -ne 0) { throw "Flutter exited with code $LASTEXITCODE." }
