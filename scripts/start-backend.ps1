param(
    [switch]$Lan
)

$projectRoot = Split-Path -Parent $PSScriptRoot
$backendRoot = Join-Path $projectRoot 'backend'
$pythonExe = Join-Path $backendRoot '.venv\Scripts\python.exe'

if (-not (Test-Path -LiteralPath $pythonExe)) {
    throw 'Backend virtual environment is missing. Run the setup instructions in README.md.'
}

if ($Lan) {
    $env:HI_HAT_BIND_HOST = '0.0.0.0'
}

Set-Location -LiteralPath $backendRoot
$bindHost = if ($env:HI_HAT_BIND_HOST) { $env:HI_HAT_BIND_HOST } else { '127.0.0.1' }
$bindPort = if ($env:HI_HAT_BIND_PORT) { $env:HI_HAT_BIND_PORT } else { '8765' }
& $pythonExe -m uvicorn hi_hat_backend.main:app --host $bindHost --port $bindPort
