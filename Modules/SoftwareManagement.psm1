


function Get-RemoteSoftware {
    
    param(
        [Parameter(Mandatory = $true)]
        [string]$RemoteServer,
        
        [Parameter(Mandatory = $true)]
        [int]$RemotePort,
        
        [Parameter(Mandatory = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$ClientCertificate
    )
    
    try {
        
        $encodedCmd = Format-CommandPacket -action "GetSoftware" -parameters @()
        
        
        $response = Send-RemoteCommand -remoteServer $RemoteServer `
            -remotePort $RemotePort `
            -command $encodedCmd `
            -clientCertificate $ClientCertificate
        
        return $response
    }
    catch {
        Write-Warning "Error al obtener software remoto: $_"
        return @{
            Success = $false
            Error   = $_.Exception.Message
        }
    }
}

function Uninstall-RemoteSoftware {
    
    param(
        [Parameter(Mandatory = $true)]
        [string]$RemoteServer,
        
        [Parameter(Mandatory = $true)]
        [int]$RemotePort,
        
        [Parameter(Mandatory = $true)]
        [string]$SoftwareName,
        
        [Parameter(Mandatory = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$ClientCertificate
    )
    
    try {
        
        $encodedCmd = Format-CommandPacket -action "UninstallSoftware" -parameters @($SoftwareName)
        
        
        $response = Send-RemoteCommand -remoteServer $RemoteServer `
            -remotePort $RemotePort `
            -command $encodedCmd `
            -clientCertificate $ClientCertificate
        
        return $response
    }
    catch {
        Write-Warning "Error al desinstalar software remoto: $_"
        return @{
            Success = $false
            Error   = $_.Exception.Message
        }
    }
}

function Install-RemoteSoftware {
    
    param(
        [Parameter(Mandatory = $true)]
        [string]$RemoteServer,
        
        [Parameter(Mandatory = $true)]
        [int]$RemotePort,
        
        [Parameter(Mandatory = $true)]
        [string]$InstallerPath,
        
        [Parameter(Mandatory = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$ClientCertificate
    )
    
    try {
        
        if (-not (Test-Path $InstallerPath)) {
            return @{
                Success = $false
                Error   = "El archivo instalador no existe"
            }
        }
        
        
        $fileBytes = [System.IO.File]::ReadAllBytes($InstallerPath)
        $fileName = [System.IO.Path]::GetFileName($InstallerPath)
        $fileBase64 = [Convert]::ToBase64String($fileBytes)
        
        Write-Host "Subiendo instalador ($([math]::Round($fileBytes.Length / 1MB, 2)) MB)..." -ForegroundColor Yellow
        
        
        $encodedUploadCmd = Format-CommandPacket -action "UploadInstaller" -parameters @($fileName, $fileBase64)
        
        $uploadResponse = Send-RemoteCommand -remoteServer $RemoteServer `
            -remotePort $RemotePort `
            -command $encodedUploadCmd `
            -clientCertificate $ClientCertificate
        
        $uploadResult = $uploadResponse
        
        if (-not $uploadResult.Success) {
            return $uploadResult
        }
        
        Write-Host "Archivo subido. Iniciando instalación..." -ForegroundColor Yellow
        
        
        $encodedInstallCmd = Format-CommandPacket -action "InstallSoftware" -parameters @($fileName)
        
        $installResponse = Send-RemoteCommand -remoteServer $RemoteServer `
            -remotePort $RemotePort `
            -command $encodedInstallCmd `
            -clientCertificate $ClientCertificate
        
        return $installResponse
    }
    catch {
        Write-Warning "Error al instalar software remoto: $_"
        return @{
            Success = $false
            Error   = $_.Exception.Message
        }
    }
}


Export-ModuleMember -Function Get-RemoteSoftware, Uninstall-RemoteSoftware, Install-RemoteSoftware

