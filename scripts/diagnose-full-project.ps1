[CmdletBinding()]
param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'
$resolvedRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$logRoot = Join-Path $resolvedRoot 'logs\diagnostics'
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
$logPath = Join-Path $logRoot ('run-{0}.log' -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
Start-Transcript -Path $logPath -Force | Out-Null

try {
    $flutter = Join-Path $env:USERPROFILE '.puro\envs\hi_hat\flutter\bin\flutter.bat'
    $clientRoot = Join-Path $resolvedRoot 'client'
    if (-not $SkipBuild) {
        Push-Location $clientRoot
        try {
            & $flutter pub get
            if ($LASTEXITCODE -ne 0) { throw '[BUILD_FAILURE] flutter pub get failed.' }
            & $flutter analyze
            if ($LASTEXITCODE -ne 0) { throw '[BUILD_FAILURE] flutter analyze failed.' }
            & $flutter test --exclude-tags playback-smoke
            if ($LASTEXITCODE -ne 0) { throw '[BUILD_FAILURE] Flutter tests failed.' }
            & $flutter build windows --debug
            if ($LASTEXITCODE -ne 0) { throw '[BUILD_FAILURE] Windows build failed.' }
        }
        finally { Pop-Location }
    }

    $exe = Join-Path $clientRoot 'build\windows\x64\runner\Debug\hi_hat.exe'
    $process = Start-Process -FilePath $exe -PassThru -WindowStyle Hidden
    try {
        Start-Sleep -Seconds 5
        Write-Host "APP_PROCESS_STARTED pid=$($process.Id) exited=$($process.HasExited)"
        try {
            & (Join-Path $PSScriptRoot 'hihat-test-client.ps1') -Command PING -PipeName 'HiHat.Diagnostics' -ConnectTimeoutMilliseconds 2000
            Write-Host 'NATIVE_DIAGNOSTIC_CHANNEL_READY'
        }
        catch {
            Write-Host "NATIVE_DIAGNOSTIC_CHANNEL_FAILED error=$($_.Exception.Message)"
        }
    }
    finally {
        if (-not $process.HasExited) {
            Stop-Process -Id $process.Id
            $process.WaitForExit(5000) | Out-Null
            Start-Sleep -Seconds 1
        }
    }

    foreach ($uri in @(
        'https://monochrome-api.samidy.com/search/?s=closer',
        'https://api.monochrome.tf/search/?s=closer'
    )) {
        $timer = [Diagnostics.Stopwatch]::StartNew()
        try {
            $null = Invoke-RestMethod -Uri $uri -TimeoutSec 10
            Write-Host "PROVIDER_SEARCH_PASS uri=$uri elapsed_ms=$($timer.ElapsedMilliseconds)"
        }
        catch {
            Write-Host "PROVIDER_SEARCH_FAIL uri=$uri elapsed_ms=$($timer.ElapsedMilliseconds) error=$($_.Exception.Message)"
        }
    }

    & (Join-Path $PSScriptRoot 'run-full-playback-until-pass.ps1') -ProjectRoot $resolvedRoot -MaxAttempts 2
    if ($LASTEXITCODE -ne 0) { throw '[LOCAL_PIPELINE_FAILURE] Fixture watchdog failed.' }
    Write-Host "DIAGNOSTIC_COMPLETE log=$logPath"
    exit 0
}
finally {
    try {
        Stop-Transcript | Out-Null
    }
    catch {
        Write-Verbose "Transcript was already stopped: $($_.Exception.Message)"
    }
}
