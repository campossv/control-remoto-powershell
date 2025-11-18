

Import-Module -Name "$PSScriptRoot\Modules\SSLConfiguration.psm1" -Force
Import-Module -Name "$PSScriptRoot\Modules\CommandHandlers.psm1" -Force

Add-Type -AssemblyName System.Net
Add-Type -AssemblyName System.Security


$cert = @((Initialize-SSLCertificate -dnsName "ServidorRemoto"))[0]
$port = 4430


$listener = New-SSLListener -certificate $cert -port $port
if (-not $listener) { exit }


while ($true) {
    $connectionInfo = Receive-SSLConnection -listener $listener -certificate $cert
    
    if (-not $connectionInfo.Success) {
        continue
    }
    
    $sslStream = $connectionInfo.Stream
    $client = $connectionInfo.Client
    
    $reader = New-Object System.IO.StreamReader($sslStream)
    $writer = New-Object System.IO.StreamWriter($sslStream)

    $encodedCommand = $reader.ReadLine()
    Write-Host "Comando recibido: $($encodedCommand.Substring(0, [Math]::Min(100, $encodedCommand.Length)))..."

    Process-Command -encodedCommand $encodedCommand -writer $writer

    $writer.Flush()
    $sslStream.Close()
    $client.Close()
}

$listener.Stop()

