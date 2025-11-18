


function New-ClientCertificate {
    
    param (
        [string]$ClientName,
        [string]$OutputPath = ".\Certificates",
        [securestring]$Password = (ConvertTo-SecureString -String "P@ssw0rd123!" -Force -AsPlainText)
    )
    
    
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    Write-Host "[CERT] Generando certificado de cliente para: $ClientName" -ForegroundColor Cyan
    
    try {
        
        $clientCert = New-SelfSignedCertificate -DnsName $ClientName `
            -CertStoreLocation "Cert:\CurrentUser\My" `
            -KeyUsage KeyEncipherment, DataEncipherment, KeyAgreement, DigitalSignature `
            -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2") `
            -NotAfter (Get-Date).AddYears(2) `
            -KeyExportPolicy Exportable `
            -Provider "Microsoft Strong Cryptographic Provider"
        
        Write-Host "[OK] Certificado creado: $($clientCert.Thumbprint)" -ForegroundColor Green
        
        
        $publicCertPath = Join-Path $OutputPath "$ClientName.cer"
        Export-Certificate -Cert $clientCert -FilePath $publicCertPath | Out-Null
        
        
        $privateCertPath = Join-Path $OutputPath "$ClientName.pfx"
        
        Export-PfxCertificate -Cert $clientCert -FilePath $privateCertPath -Password $Password | Out-Null
        
        Write-Host "[INFO] Certificados exportados a: $OutputPath" -ForegroundColor Yellow
        Write-Host "   - Publico: $publicCertPath" -ForegroundColor White
        Write-Host "   - Privado: $privateCertPath" -ForegroundColor White
        
        return @{
            Certificate = $clientCert
            PublicPath  = $publicCertPath
            PrivatePath = $privateCertPath
            Password    = $Password
            Thumbprint  = $clientCert.Thumbprint
        }
    }
    catch {
        Write-Error "[ERROR] Error al generar certificado: $($_.Exception.Message)"
        return $null
    }
}

function Import-TrustedClientCertificates {
    
    param (
        [string]$CertificatesPath = ".\Certificates"
    )
    
    Write-Host "[IMPORT] Importando certificados de cliente autorizados..." -ForegroundColor Cyan
    
    try {
        
        $certFiles = Get-ChildItem -Path $CertificatesPath -Filter "*.cer" -ErrorAction SilentlyContinue
        
        if ($certFiles.Count -eq 0) {
            Write-Warning "[ADVERTENCIA] No se encontraron certificados .cer en $CertificatesPath"
            return $false
        }
        
        $importedCount = 0
        foreach ($certFile in $certFiles) {
            try {
                
                
                $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certFile.FullName)
                
                if ($cert.EnhancedKeyUsageList -and $cert.EnhancedKeyUsageList.FriendlyName -contains "Client Authentication") {
                    Import-Certificate -FilePath $certFile.FullName -CertStoreLocation "Cert:\LocalMachine\TrustedPeople" -ErrorAction Stop | Out-Null
                    Write-Host "[OK] Certificado importado: $($certFile.Name)" -ForegroundColor Green
                    $importedCount++
                }
                else {
                    Write-Warning "[ADVERTENCIA] El certificado $($certFile.Name) no tiene el EKU correcto"
                }
            }
            catch {
                Write-Warning "[ADVERTENCIA] Error importando $($certFile.Name): $($_.Exception.Message)"
            }
        }
        
        Write-Host "[RESUMEN] Total certificados importados: $importedCount/$($certFiles.Count)" -ForegroundColor Yellow
    }
    catch {
        Write-Error "[ERROR] Error al importar certificados: $($_.Exception.Message)"
    }
}

function Test-ClientCertificate {
    
    param (
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$ClientCertificate
    )
    
    if (-not $ClientCertificate) {
        Write-Warning "[ADVERTENCIA] Cliente no presentó certificado"
        return $false
    }
    
    try {
        
        $trustedCert = Get-ChildItem -Path "Cert:\LocalMachine\TrustedPeople" | 
        Where-Object { $_.Thumbprint -eq $ClientCertificate.Thumbprint }
        
        if ($trustedCert) {
            Write-Host "[OK] Certificado de cliente autorizado: $($ClientCertificate.Subject)" -ForegroundColor Green
            return $true
        }
        else {
            Write-Warning "[RECHAZADO] Certificado de cliente no autorizado: $($ClientCertificate.Subject)"
            return $false
        }
    }
    catch {
        Write-Error "[ERROR] Error validando certificado: $($_.Exception.Message)"
        return $false
    }
}

function Get-ClientCertificateInfo {
    
    param (
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$ClientCertificate
    )
    
    if (-not $ClientCertificate) {
        return $null
    }
    
    return @{
        Subject      = $ClientCertificate.Subject
        Issuer       = $ClientCertificate.Issuer
        Thumbprint   = $ClientCertificate.Thumbprint
        NotBefore    = $ClientCertificate.NotBefore
        NotAfter     = $ClientCertificate.NotAfter
        SerialNumber = $ClientCertificate.SerialNumber
        IsValid      = (Get-Date) -ge $ClientCertificate.NotBefore -and (Get-Date) -le $ClientCertificate.NotAfter
    }
}

function Remove-ExpiredClientCertificates {
    
    try {
        $expiredCerts = Get-ChildItem -Path "Cert:\LocalMachine\TrustedPeople" | 
        Where-Object { $_.NotAfter -lt (Get-Date) }
        
        if ($expiredCerts.Count -gt 0) {
            Write-Host "[LIMPIEZA] Limpiando $($expiredCerts.Count) certificados expirados..." -ForegroundColor Yellow
            foreach ($cert in $expiredCerts) {
                Remove-Item -Path "Cert:\LocalMachine\TrustedPeople\$($cert.Thumbprint)" -Force
                Write-Host "   - Eliminado: $($cert.Subject)" -ForegroundColor Gray
            }
        }
        
        return $expiredCerts.Count
    }
    catch {
        Write-Warning "[ADVERTENCIA] Error limpiando certificados expirados: $($_.Exception.Message)"
        return 0
    }
}

Export-ModuleMember -Function New-ClientCertificate, Import-TrustedClientCertificates, 
Test-ClientCertificate, Get-ClientCertificateInfo, Remove-ExpiredClientCertificates

