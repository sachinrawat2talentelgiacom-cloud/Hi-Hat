[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Command,
    [string]$PayloadJson = '{}',
    [int]$ConnectTimeoutMilliseconds = 2000,
    [string]$PipeName = 'HiHat.Test'
)

$ErrorActionPreference = 'Stop'
$pipe = [System.IO.Pipes.NamedPipeClientStream]::new(
    '.',
    $PipeName,
    [System.IO.Pipes.PipeDirection]::InOut,
    [System.IO.Pipes.PipeOptions]::None
)
try {
    $pipe.Connect($ConnectTimeoutMilliseconds)
    $writer = [System.IO.StreamWriter]::new($pipe, [System.Text.UTF8Encoding]::new($false), 4096, $true)
    $reader = [System.IO.StreamReader]::new($pipe, [System.Text.UTF8Encoding]::new($false), $false, 4096, $true)
    $writer.AutoFlush = $true
    $request = @{
        command = $Command
        payload = ($PayloadJson | ConvertFrom-Json)
        requestId = [guid]::NewGuid().ToString('N')
    } | ConvertTo-Json -Compress -Depth 10
    $writer.WriteLine($request)
    $response = $reader.ReadLine()
    if ([string]::IsNullOrWhiteSpace($response)) { throw 'The Hi Hat test pipe returned no response.' }
    $response
}
finally {
    if ($writer) { $writer.Dispose() }
    if ($reader) { $reader.Dispose() }
    $pipe.Dispose()
}
