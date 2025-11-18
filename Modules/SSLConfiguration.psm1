



Import-Module -Name "$PSScriptRoot\CertificateAuth.psm1" -Force

function Initialize-SSLCertificate {
    param ([string]$dnsName = "ServidorRemoto")
    
    $allCerts = Get-ChildItem -Path Cert:\LocalMachine\My | 
                Where-Object { $_.Subject -like "*$dnsName*" } | 
                Sort-Object NotBefore -Descending

    if ($allCerts.Count -gt 0) {
        $cert = $allCerts[0]
    } else {
        $newCert = New-SelfSignedCertificate -DnsName $dnsName `
            -CertStoreLocation "Cert:\LocalMachine\My" `
            -KeyUsage KeyEncipherment, DataEncipherment, KeyAgreement `
            -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.1") `
            -NotAfter (Get-Date).AddYears(5)
        $cert = $newCert
    }

    $cert = @($cert)[0]
    $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]$cert

    
    $null = Import-TrustedClientCertificates

    return $cert
}

function New-SSLListener {
    param (
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$certificate,
        [int]$port
    )
    
    $endpoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, $port)
    $listener = New-Object System.Net.Sockets.TcpListener $endpoint
    
    try {
        $listener.Start()
        Write-Host "[SSL] Escuchando en puerto $port con SSL y autenticacion de cliente..." -ForegroundColor Cyan
        return $listener
    }
    catch {
        if ($_.Exception.Message -like "*Only one usage*") {
            Write-Error "[ERROR] El puerto $port ya está en uso. Libera el puerto o usa otro."
        } else {
            Write-Error "[ERROR] Error iniciando listener: $($_.Exception.Message)"
        }
        return $null
    }
}

function Receive-SSLConnection {
    param (
        [System.Net.Sockets.TcpListener]$listener,
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$certificate
    )
    
    $client = $listener.AcceptTcpClient()
    $clientIP = $client.Client.RemoteEndPoint.Address.ToString()
    
    $sslStream = New-Object System.Net.Security.SslStream($client.GetStream(), $false, {
            param($eventSender, $certificate, $chain, $sslPolicyErrors)
        
            
            if ($sslPolicyErrors -band [System.Net.Security.SslPolicyErrors]::RemoteCertificateNotAvailable) {
                Write-Host "[RECHAZADO] Cliente desde $clientIP no presento certificado" -ForegroundColor Red
                return $false
            }
        
            if ($sslPolicyErrors -band [System.Net.Security.SslPolicyErrors]::RemoteCertificateChainErrors) {
                Write-Host "[ADVERTENCIA] Cliente desde $clientIP presento certificado con errores de cadena" -ForegroundColor Yellow
            }
        
            
            $isAuthorized = Test-ClientCertificate -ClientCertificate $certificate
        
            if (-not $isAuthorized) {
                Write-Host "[RECHAZADO] Cliente desde $clientIP con certificado no autorizado: $($certificate.Subject)" -ForegroundColor Red
                return $false
            }
        
            Write-Host "[OK] Cliente desde $clientIP autenticado con certificado: $($certificate.Subject)" -ForegroundColor Green
        
            
            $clientInfo = Get-ClientCertificateInfo -ClientCertificate $certificate
            Write-Host "   - Thumbprint: $($clientInfo.Thumbprint)" -ForegroundColor Gray
            Write-Host "   - Valido hasta: $($clientInfo.NotAfter)" -ForegroundColor Gray
        
            return $true
        })
    
    try {
        
        $sslStream.AuthenticateAsServer($certificate, $true, [System.Security.Authentication.SslProtocols]::Tls12, $false)
        
        Write-Host "[SSL] Conexión SSL mutua establecida desde $clientIP" -ForegroundColor Green
        
        return @{ 
            Stream   = $sslStream; 
            Client   = $client; 
            Success  = $true;
            ClientIP = $clientIP
        }
    }
    catch {
        Write-Host "[ERROR] Error SSL con cliente ${clientIP}: $($_.Exception.Message)" -ForegroundColor Red
        $sslStream.Close()
        $client.Close()
        return @{ 
            Stream   = $null; 
            Client   = $null; 
            Success  = $false;
            ClientIP = $clientIP
        }
    }
}

function Get-ServerCertificateInfo {
    
    param (
        [string]$dnsName = "ServidorRemoto"
    )
    
    
    $certs = @(Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Subject -like "*$dnsName*" })
    $cert = if ($certs.Count -gt 0) { $certs[0] } else { $null }
    
    if ($cert) {
        return @{
            Subject         = $cert.Subject
            Thumbprint      = $cert.Thumbprint
            Issuer          = $cert.Issuer
            NotBefore       = $cert.NotBefore
            NotAfter        = $cert.NotAfter
            DaysUntilExpiry = ($cert.NotAfter - (Get-Date)).Days
        }
    }
    else {
        return $null
    }
}

Export-ModuleMember -Function Initialize-SSLCertificate, New-SSLListener, Receive-SSLConnection, Get-ServerCertificateInfo

