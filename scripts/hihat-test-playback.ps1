[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$FullLength
)

$ErrorActionPreference = 'Stop'
$resolvedFile = (Resolve-Path -LiteralPath $FilePath).Path
$clientRoot = Join-Path $ProjectRoot 'client'
$flutter = Join-Path $env:USERPROFILE '.puro\envs\hi_hat\flutter\bin\flutter.bat'
if (-not (Test-Path -LiteralPath $flutter)) {
    $flutterCommand = Get-Command flutter.bat -ErrorAction SilentlyContinue
    if (-not $flutterCommand) { throw 'Flutter is not installed.' }
    $flutter = $flutterCommand.Source
}

$previousSmokeFile = $env:HIHAT_PLAYBACK_SMOKE_FILE
$previousPath = $env:PATH
$previousFullPlayback = $env:HIHAT_FULL_PLAYBACK_SMOKE
try {
    $env:HIHAT_PLAYBACK_SMOKE_FILE = $resolvedFile
    $runnerDirectory = Join-Path $clientRoot 'build\windows\x64\runner\Debug'
    if (-not (Test-Path -LiteralPath (Join-Path $runnerDirectory 'libmpv-2.dll'))) {
        throw 'The Windows build output does not contain libmpv-2.dll.'
    }
    $env:PATH = "$runnerDirectory;$previousPath"
    $env:HIHAT_FULL_PLAYBACK_SMOKE = if ($FullLength) { '1' } else { '0' }
    Push-Location $clientRoot
    & $flutter test test/playback_smoke_test.dart
    if ($LASTEXITCODE -ne 0) { throw 'Hi Hat media_kit playback smoke failed.' }
}
finally {
    Pop-Location
    $env:HIHAT_PLAYBACK_SMOKE_FILE = $previousSmokeFile
    $env:PATH = $previousPath
    $env:HIHAT_FULL_PLAYBACK_SMOKE = $previousFullPlayback
}

exit 0
