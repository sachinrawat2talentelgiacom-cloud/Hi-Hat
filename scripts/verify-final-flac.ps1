[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,
    [double]$ExpectedDurationSeconds = 0
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $FilePath)) { throw 'FLAC_NOT_CREATED' }
$json = & ffprobe -v error -show_entries 'stream=codec_name,sample_rate,channels,bits_per_raw_sample,bits_per_sample:format=duration,size:format_tags=title,artist,album' -of json $FilePath
if ($LASTEXITCODE -ne 0) { throw 'FLAC_INVALID' }
$probe = $json | ConvertFrom-Json
$stream = @($probe.streams)[0]
if ($stream.codec_name -ne 'flac') { throw 'FLAC_INVALID_CODEC' }
if ([double]$probe.format.duration -le 0 -or [int]$stream.sample_rate -le 0 -or [int]$stream.channels -le 0) { throw 'FLAC_INVALID_PROPERTIES' }
if ($ExpectedDurationSeconds -gt 0 -and [math]::Abs([double]$probe.format.duration - $ExpectedDurationSeconds) -gt 5) { throw 'FULL_TRACK_VALIDATION_FAILED' }
@{
    ok = $true
    path = (Resolve-Path -LiteralPath $FilePath).Path
    codec = $stream.codec_name
    durationSeconds = [double]$probe.format.duration
    sampleRate = [int]$stream.sample_rate
    channels = [int]$stream.channels
    fileSize = (Get-Item -LiteralPath $FilePath).Length
    sha256 = (Get-FileHash -LiteralPath $FilePath -Algorithm SHA256).Hash.ToLowerInvariant()
    tags = $probe.format.tags
} | ConvertTo-Json -Compress -Depth 10
