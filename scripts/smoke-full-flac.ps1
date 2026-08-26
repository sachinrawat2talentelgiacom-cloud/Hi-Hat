[CmdletBinding()]
param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [int]$AcquireTimeoutSeconds = 120
)

$ErrorActionPreference = 'Stop'
$clientRoot = Join-Path $ProjectRoot 'client'
$flutter = Join-Path $env:USERPROFILE '.puro\envs\hi_hat\flutter\bin\flutter.bat'
if (-not (Test-Path -LiteralPath $flutter)) {
    $flutterCommand = Get-Command flutter.bat -ErrorAction SilentlyContinue
    if (-not $flutterCommand) { throw 'BUILD_FAILURE: Flutter is not installed.' }
    $flutter = $flutterCommand.Source
}

Write-Host '==> Building and testing Hi Hat' -ForegroundColor Cyan
Push-Location $clientRoot
try {
    & $flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'BUILD_FAILURE: flutter pub get failed.' }
    & $flutter test --exclude-tags playback-smoke
    if ($LASTEXITCODE -ne 0) { throw 'BUILD_FAILURE: Flutter tests failed.' }
    & $flutter build windows --debug
    if ($LASTEXITCODE -ne 0) { throw 'BUILD_FAILURE: Windows build failed.' }
}
finally {
    Pop-Location
}

$query = if ($env:HIHAT_TEST_QUERY) { $env:HIHAT_TEST_QUERY } else { 'public-domain-fixture' }
$resultFile = Join-Path $env:TEMP 'hihat-smoke-result.txt'
Remove-Item -LiteralPath $resultFile -ErrorAction SilentlyContinue

& (Join-Path $PSScriptRoot 'hihat-test-acquire.ps1') -Query $query -OutputPath $resultFile -TimeoutSeconds $AcquireTimeoutSeconds -ProjectRoot $ProjectRoot
if ($LASTEXITCODE -ne 0) { throw 'DOWNLOAD_FAILURE: Test acquisition failed.' }

$flacPath = (Get-Content -LiteralPath $resultFile -Raw).Trim()
if (-not (Test-Path -LiteralPath $flacPath)) { throw "DOWNLOAD_FAILURE: Missing FLAC: $flacPath" }

$ffprobe = Get-Command ffprobe -ErrorAction SilentlyContinue
if (-not $ffprobe) { throw 'VALIDATION_FAILURE: ffprobe was not found in PATH.' }
$probeJson = & $ffprobe.Source -v error -show_entries 'stream=codec_name,sample_rate,channels,bits_per_raw_sample,bits_per_sample:format=duration,size:format_tags=title,artist,album' -of json $flacPath
if ($LASTEXITCODE -ne 0) { throw 'VALIDATION_FAILURE: ffprobe failed.' }
$probe = $probeJson | ConvertFrom-Json
$stream = @($probe.streams)[0]
if (-not $stream -or $stream.codec_name -ne 'flac') { throw 'VALIDATION_FAILURE: File is not FLAC.' }

$actualDuration = [double]$probe.format.duration
$expectedDuration = if ($env:HIHAT_TEST_EXPECTED_DURATION_SECONDS) { [double]$env:HIHAT_TEST_EXPECTED_DURATION_SECONDS } else { 10.0 }
if ([math]::Abs($actualDuration - $expectedDuration) -gt 5.0) { throw "FULL_TRACK_FAILURE: Expected ~$expectedDuration sec, got $actualDuration sec." }

$expectedTitle = if ($env:HIHAT_TEST_EXPECTED_TITLE) { $env:HIHAT_TEST_EXPECTED_TITLE } else { 'Gapless FLAC #1' }
$expectedArtist = if ($env:HIHAT_TEST_EXPECTED_ARTIST) { $env:HIHAT_TEST_EXPECTED_ARTIST } else { 'Me' }
$expectedAlbum = if ($env:HIHAT_TEST_EXPECTED_ALBUM) { $env:HIHAT_TEST_EXPECTED_ALBUM } else { 'Exaile Test Files' }
$tags = $probe.format.tags
if ($tags.title -ne $expectedTitle) { throw "METADATA_FAILURE: Title mismatch: $($tags.title)" }
if ($tags.artist -ne $expectedArtist) { throw "METADATA_FAILURE: Artist mismatch: $($tags.artist)" }
if ($tags.album -ne $expectedAlbum) { throw "METADATA_FAILURE: Album mismatch: $($tags.album)" }
if ([int]$stream.sample_rate -le 0 -or [int]$stream.channels -le 0) { throw 'METADATA_FAILURE: Invalid measured audio properties.' }
$bitDepth = if ([int]$stream.bits_per_raw_sample -gt 0) { [int]$stream.bits_per_raw_sample } else { [int]$stream.bits_per_sample }
if ($bitDepth -le 0) { throw 'METADATA_FAILURE: Bit depth is missing.' }

$hash = (Get-FileHash -LiteralPath $flacPath -Algorithm SHA256).Hash.ToLowerInvariant()
& (Join-Path $PSScriptRoot 'hihat-test-playback.ps1') -FilePath $flacPath -ProjectRoot $ProjectRoot
if ($LASTEXITCODE -ne 0) { throw 'PLAYBACK_FAILURE: Playback smoke failed.' }

Write-Host ''
Write-Host 'FULL FLAC READY' -ForegroundColor Green
Write-Host "Path:        $flacPath"
Write-Host "Title:       $($tags.title)"
Write-Host "Artist:      $($tags.artist)"
Write-Host "Album:       $($tags.album)"
Write-Host "Codec:       $($stream.codec_name)"
Write-Host "Duration:    $actualDuration sec"
Write-Host "Sample rate: $($stream.sample_rate)"
Write-Host "Bit depth:   $bitDepth"
Write-Host "Channels:    $($stream.channels)"
Write-Host "File size:   $((Get-Item -LiteralPath $flacPath).Length) bytes"
Write-Host "SHA-256:     $hash"
Write-Host 'Playback smoke: PASS'
exit 0
