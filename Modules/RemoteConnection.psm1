


function Format-CommandPacket {
    param (
        [string]$action,
        [string[]]$parameters
    )
    $payload = @{
        action = $action
        params = $parameters
    } | ConvertTo-Json -Compress
    return [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($payload))
}

function Parse-CommandPacket {
    param (
        [string]$encodedPacket
    )
    try {
        $json = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encodedPacket))
        return $json | ConvertFrom-Json
    } catch {
        return $null
    }
}

function Send-RemoteCommand {
    param (
        [string]$remoteServer,
        [int]$remotePort,
        [string]$command,
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$clientCertificate = $null
    )
    
    try {
        $client = New-Object System.Net.Sockets.TcpClient($remoteServer, $remotePort)
        
        $sslStream = New-Object System.Net.Security.SslStream(
            $client.GetStream(), 
            $false,
            [System.Net.Security.RemoteCertificateValidationCallback]{
                param($eventSender, $cert, $chain, $sslPolicyErrors)
                
                return $true
            }
        )
        
        
        $clientCertificates = $null
        if ($clientCertificate) {
            $clientCertificates = New-Object System.Security.Cryptography.X509Certificates.X509CertificateCollection
            $clientCertificates.Add($clientCertificate) | Out-Null
            Write-Host " Usando certificado de cliente: $($clientCertificate.Subject)" -ForegroundColor Cyan
        }
        
        
        $sslStream.AuthenticateAsClient($remoteServer, $clientCertificates, [System.Security.Authentication.SslProtocols]::Tls12, $false)
        
        $writer = New-Object System.IO.StreamWriter($sslStream)
        $reader = New-Object System.IO.StreamReader($sslStream)
        
        Write-Host "Enviando comando: $($command.Substring(0, [Math]::Min(50, $command.Length)))..."
        $writer.WriteLine($command)
        $writer.Flush()

        $response = $reader.ReadToEnd()
        Write-Host "Respuesta recibida: $($response.Substring(0, [Math]::Min(100, $response.Length)))"

        $writer.Close()
        $reader.Close()
        $sslStream.Close()
        $client.Close()

        return $response | ConvertFrom-Json
    } catch {
        Write-Host "Error de conexión: $($_.Exception.Message)" -ForegroundColor Red
        [System.Windows.Forms.MessageBox]::Show("Error de conexión: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return $null
    }
}

function Load-ClientCertificate {
    
    param (
        [Parameter(Mandatory=$true)]
        [string]$certificatePath,
        
        [Parameter(Mandatory=$true)]
        [securestring]$password
    )
    
    try {
        if (-not (Test-Path $certificatePath)) {
            Write-Warning "  No se encuentra el archivo de certificado: $certificatePath"
            return $null
        }
        
        $certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certificatePath, $password)
        
        Write-Host " Certificado de cliente cargado: $($certificate.Subject)" -ForegroundColor Green
        return $certificate
    } catch {
        Write-Error " Error cargando certificado: $($_.Exception.Message)"
        return $null
    }
}

function Get-AvailableClientCertificates {
    
    try {
        $certs = Get-ChildItem -Path "Cert:\CurrentUser\My" | 
            Where-Object { $_.HasPrivateKey -and $_.Extensions | Where-Object { $_.Oid.Value -eq "2.5.29.37" -and $_.Oid.FriendlyName -eq "Enhanced Key Usage" } }
        
        return $certs | ForEach-Object {
            @{
                Subject = $_.Subject
                Thumbprint = $_.Thumbprint
                NotAfter = $_.NotAfter
                Certificate = $_
            }
        }
    } catch {
        Write-Warning "  Error obteniendo certificados: $($_.Exception.Message)"
        return @()
    }
}

function Test-ClientCertificateValidity {
    
    param (
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$certificate
    )
    
    if (-not $certificate) {
        return @{ Valid = $false; Reason = "Certificado nulo" }
    }
    
    $now = Get-Date
    
    if ($now -lt $certificate.NotBefore) {
        return @{ Valid = $false; Reason = "Certificado no es válido hasta $($certificate.NotBefore)" }
    }
    
    if ($now -gt $certificate.NotAfter) {
        return @{ Valid = $false; Reason = "Certificado expiró el $($certificate.NotAfter)" }
    }
    
    if (-not $certificate.HasPrivateKey) {
        return @{ Valid = $false; Reason = "Certificado no tiene clave privada" }
    }
    
    
    $eku = $certificate.Extensions | Where-Object { $_.Oid.Value -eq "2.5.29.37" }
    if ($eku) {
        $oid = New-Object System.Security.Cryptography.Oid "1.3.6.1.5.5.7.3.2" 
        if ($eku.EnhancedKeyUsages -notcontains $oid) {
            return @{ Valid = $false; Reason = "Certificado no es válido para autenticación de cliente" }
        }
    }
    
    return @{ Valid = $true; Reason = "Certificado válido" }
}

Export-ModuleMember -Function Format-CommandPacket, Parse-CommandPacket, Send-RemoteCommand, 
    Load-ClientCertificate, Get-AvailableClientCertificates, Test-ClientCertificateValidity

