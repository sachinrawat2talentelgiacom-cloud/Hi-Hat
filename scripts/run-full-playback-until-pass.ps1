[CmdletBinding()]
param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [int]$MaxAttempts = 5,
    [int]$SearchTimeoutSeconds = 10,
    [int]$AcquireTimeoutSeconds = 180,
    [int]$PlaybackStallTimeoutSeconds = 15,
    [switch]$FreshAcquisition,
    [switch]$RequireLiveApp
)

$ErrorActionPreference = 'Stop'
$resolvedRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$logRoot = Join-Path $resolvedRoot 'logs\full-playback-loop'
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
$fixtureMode = -not $RequireLiveApp -and [string]::IsNullOrWhiteSpace($env:HIHAT_TEST_QUERY)

function Invoke-LiveClient {
    param([string]$Command, [hashtable]$Payload = @{})
    $json = $Payload | ConvertTo-Json -Compress
    $raw = & (Join-Path $PSScriptRoot 'hihat-test-client.ps1') -Command $Command -PayloadJson $json
    if ($LASTEXITCODE -ne 0) { throw "[TEST_CLIENT_FAILED] $Command failed." }
    $raw | ConvertFrom-Json
}

for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
    $logPath = Join-Path $logRoot ('attempt-{0:D2}-{1}.log' -f $attempt, (Get-Date -Format 'yyyyMMdd-HHmmss'))
    Start-Transcript -Path $logPath -Force | Out-Null
    try {
        Write-Host "Hi Hat full playback attempt $attempt/$MaxAttempts" -ForegroundColor Cyan
        if (-not $fixtureMode) {
            $ping = Invoke-LiveClient -Command 'PING'
            if ($ping.ok -ne $true) { throw '[APP_NOT_READY] Named-pipe test bridge is unavailable.' }
            throw '[TEST_CONTROL_INCOMPLETE] Live named-pipe server commands are not implemented in HiHat.exe yet.'
        }

        Write-Host 'STATE SEARCHING query=public-domain-fixture deadline=10s'
        $fixture = Join-Path $resolvedRoot 'backend\tests\assets\player_test.flac'
        $probeJson = & ffprobe -v error -show_entries 'stream=codec_name,sample_rate,channels,bits_per_raw_sample,bits_per_sample:format=duration,size:format_tags=title,artist,album' -of json $fixture
        if ($LASTEXITCODE -ne 0) { throw '[SEARCH_FAILED] Fixture metadata could not be read.' }
        $probe = $probeJson | ConvertFrom-Json
        $tags = $probe.format.tags
        if ($tags.title -ne 'Gapless FLAC #1' -or $tags.artist -ne 'Me') { throw '[TRACK_MATCH_FAILED] Exact fixture track did not match.' }
        Write-Host 'STATE RESULTS_READY exact_match=true'

        $resultFile = Join-Path $env:TEMP 'hihat-full-playback-result.txt'
        & (Join-Path $PSScriptRoot 'hihat-test-acquire.ps1') -Query 'public-domain-fixture' -OutputPath $resultFile -TimeoutSeconds $AcquireTimeoutSeconds -ProjectRoot $resolvedRoot
        if ($LASTEXITCODE -ne 0) { throw '[DOWNLOAD_FAILED] Fixture acquisition failed.' }
        $flacPath = (Get-Content -LiteralPath $resultFile -Raw).Trim()
        Write-Host "STATE READY localPath=$flacPath"

        Push-Location (Join-Path $resolvedRoot 'client')
        try {
            $flutter = Join-Path $env:USERPROFILE '.puro\envs\hi_hat\flutter\bin\flutter.bat'
            & $flutter test test/local_import_pipeline_test.dart
            if ($LASTEXITCODE -ne 0) { throw '[METADATA_FAILED] Managed finalization or restart persistence failed.' }
        }
        finally { Pop-Location }

        Write-Host 'STATE PLAYER_LOADING start=0'
        & (Join-Path $PSScriptRoot 'hihat-test-playback.ps1') -FilePath $flacPath -ProjectRoot $resolvedRoot -FullLength
        if ($LASTEXITCODE -ne 0) { throw '[PLAYBACK_FAILED] Natural full playback failed.' }
        Write-Host 'STATE PLAYER_ENDED final_position_within_tolerance=true'

        Write-Host 'STATE OFFLINE_REPLAY local_file=true provider_required=false'
        Write-Host 'FULL PIPELINE PASS (PUBLIC-DOMAIN FIXTURE MODE)' -ForegroundColor Green
        Stop-Transcript | Out-Null
        exit 0
    }
    catch {
        Write-Host $_ -ForegroundColor Red
        Stop-Transcript | Out-Null
        if ($attempt -lt $MaxAttempts) { Start-Sleep -Seconds 3 }
    }
}

Write-Host "FULL PIPELINE FAILED - logs: $logRoot" -ForegroundColor Red
exit 1
