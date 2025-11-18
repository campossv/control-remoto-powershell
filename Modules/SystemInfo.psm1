


function Get-RemoteSystemInfo {
    
    param (
        [Parameter(Mandatory = $true)]
        [string]$RemoteServer,
        
        [Parameter(Mandatory = $true)]
        [int]$RemotePort,
        
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$ClientCertificate = $null
    )
    
    try {
        
        $encodedCmd = Format-CommandPacket -action "GET_SYSTEM_INFO" -parameters @()
        $response = Send-RemoteCommand -remoteServer $RemoteServer -remotePort $RemotePort -command $encodedCmd -clientCertificate $ClientCertificate
        
        if ($response -and $response.success) {
            return $response.systemInfo
        }
        else {
            Write-Warning "No se pudo obtener información del sistema: $($response.message)"
            return $null
        }
    }
    catch {
        Write-Error "Error al obtener información del sistema: $($_.Exception.Message)"
        return $null
    }
}

function Format-SystemInfoDisplay {
    
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$SystemInfo
    )
    
    $formatted = @{
        ComputerName    = $SystemInfo.ComputerName
        OSVersion       = $SystemInfo.OSVersion
        OSArchitecture  = $SystemInfo.OSArchitecture
        CPUName         = $SystemInfo.CPUName
        CPUCores        = $SystemInfo.CPUCores
        CPUUsage        = "$([math]::Round($SystemInfo.CPUUsage, 1))%"
        TotalRAM        = Format-Bytes -Bytes $SystemInfo.TotalRAM
        UsedRAM         = Format-Bytes -Bytes $SystemInfo.UsedRAM
        FreeRAM         = Format-Bytes -Bytes $SystemInfo.FreeRAM
        RAMUsagePercent = "$([math]::Round($SystemInfo.RAMUsagePercent, 1))%"
        Uptime          = Format-Uptime -Seconds $SystemInfo.UptimeSeconds
        LastBootTime    = $SystemInfo.LastBootTime
        Disks           = $SystemInfo.Disks
        NetworkAdapters = $SystemInfo.NetworkAdapters
    }
    
    return $formatted
}

function Format-Bytes {
    
    param (
        [Parameter(Mandatory = $true)]
        [long]$Bytes
    )
    
    if ($Bytes -ge 1TB) {
        return "$([math]::Round($Bytes / 1TB, 2)) TB"
    }
    elseif ($Bytes -ge 1GB) {
        return "$([math]::Round($Bytes / 1GB, 2)) GB"
    }
    elseif ($Bytes -ge 1MB) {
        return "$([math]::Round($Bytes / 1MB, 2)) MB"
    }
    elseif ($Bytes -ge 1KB) {
        return "$([math]::Round($Bytes / 1KB, 2)) KB"
    }
    else {
        return "$Bytes Bytes"
    }
}

function Format-Uptime {
    
    param (
        [Parameter(Mandatory = $true)]
        [long]$Seconds
    )
    
    $timespan = [TimeSpan]::FromSeconds($Seconds)
    
    $days = $timespan.Days
    $hours = $timespan.Hours
    $minutes = $timespan.Minutes
    
    $parts = @()
    if ($days -gt 0) { $parts += "$days días" }
    if ($hours -gt 0) { $parts += "$hours horas" }
    if ($minutes -gt 0) { $parts += "$minutes minutos" }
    
    if ($parts.Count -eq 0) {
        return "Menos de 1 minuto"
    }
    
    return $parts -join ", "
}

function Get-DiskUsageColor {
    
    param (
        [Parameter(Mandatory = $true)]
        [double]$UsagePercent
    )
    
    if ($UsagePercent -ge 90) {
        return "Red"
    }
    elseif ($UsagePercent -ge 75) {
        return "Orange"
    }
    elseif ($UsagePercent -ge 50) {
        return "Yellow"
    }
    else {
        return "Green"
    }
}

function Get-RAMUsageColor {
    
    param (
        [Parameter(Mandatory = $true)]
        [double]$UsagePercent
    )
    
    if ($UsagePercent -ge 90) {
        return "Red"
    }
    elseif ($UsagePercent -ge 75) {
        return "Orange"
    }
    elseif ($UsagePercent -ge 60) {
        return "Yellow"
    }
    else {
        return "Green"
    }
}

function Get-CPUUsageColor {
    
    param (
        [Parameter(Mandatory = $true)]
        [double]$UsagePercent
    )
    
    if ($UsagePercent -ge 80) {
        return "Red"
    }
    elseif ($UsagePercent -ge 60) {
        return "Orange"
    }
    elseif ($UsagePercent -ge 40) {
        return "Yellow"
    }
    else {
        return "Green"
    }
}


Export-ModuleMember -Function Get-RemoteSystemInfo, Format-SystemInfoDisplay, Format-Bytes, Format-Uptime, Get-DiskUsageColor, Get-RAMUsageColor, Get-CPUUsageColor

