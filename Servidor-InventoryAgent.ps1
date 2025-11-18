


param(
    [Parameter(Mandatory = $true)]
    [string]$ClientIP,
    
    [int]$ClientPort = 5000,
    
    [string]$ServerDescription = $env:COMPUTERNAME
)

Write-Host "=== Agente de Inventario ===" -ForegroundColor Cyan
Write-Host "Servidor: $env:COMPUTERNAME" -ForegroundColor White
Write-Host "Cliente: ${ClientIP}:${ClientPort}" -ForegroundColor White


$serverIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.*" } | Select-Object -First 1).IPAddress


try {
    $osInfo = Get-CimInstance Win32_OperatingSystem
    $osName = "$($osInfo.Caption) $($osInfo.Version)"
}
catch {
    $osName = "Unknown"
}


try {
    $cert = Get-ChildItem Cert:\LocalMachine\My | 
    Where-Object { $_.Subject -like "*$env:COMPUTERNAME*" } | 
    Select-Object -First 1
    $certThumbprint = if ($cert) { $cert.Thumbprint } else { "" }
}
catch {
    $certThumbprint = ""
}

$inventory = @{
    ServerIP              = $serverIP
    Hostname              = $env:COMPUTERNAME
    Description           = $ServerDescription
    OS                    = $osName
    CertificateThumbprint = $certThumbprint
    Timestamp             = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Hardware              = @()
    Software              = @()
}


Write-Host "`nRecopilando hardware..." -ForegroundColor Yellow


try {
    $cpu = Get-WmiObject -Class Win32_Processor
    foreach ($proc in $cpu) {
        $inventory.Hardware += @{
            Type         = "CPU"
            Manufacturer = $proc.Manufacturer
            Model        = $proc.Name
            SerialNumber = $proc.ProcessorId
            Capacity     = "$($proc.NumberOfCores) cores"
            Speed        = "$($proc.MaxClockSpeed) MHz"
            Status       = $proc.Status
        }
    }
    Write-Host "  ✓ CPU: $($cpu.Count) procesador(es)" -ForegroundColor Green
}
catch {
    Write-Warning "  Error al obtener CPU: $_"
}


try {
    $memory = Get-WmiObject -Class Win32_PhysicalMemory
    foreach ($mem in $memory) {
        $capacityGB = [math]::Round($mem.Capacity / 1GB, 2)
        $inventory.Hardware += @{
            Type         = "RAM"
            Manufacturer = $mem.Manufacturer
            Model        = $mem.PartNumber
            SerialNumber = $mem.SerialNumber
            Capacity     = "$capacityGB GB"
            Speed        = "$($mem.Speed) MHz"
            Status       = "OK"
        }
    }
    $totalRAM = ($memory | Measure-Object -Property Capacity -Sum).Sum / 1GB
    Write-Host "  ✓ RAM: $([math]::Round($totalRAM, 2)) GB total" -ForegroundColor Green
}
catch {
    Write-Warning "  Error al obtener RAM: $_"
}


try {
    $disks = Get-WmiObject -Class Win32_DiskDrive
    foreach ($disk in $disks) {
        $sizeGB = [math]::Round($disk.Size / 1GB, 2)
        $inventory.Hardware += @{
            Type         = "Disk"
            Manufacturer = $disk.Manufacturer
            Model        = $disk.Model
            SerialNumber = $disk.SerialNumber
            Capacity     = "$sizeGB GB"
            Speed        = $disk.InterfaceType
            Status       = $disk.Status
        }
    }
    Write-Host "  ✓ Discos: $($disks.Count) unidad(es)" -ForegroundColor Green
}
catch {
    Write-Warning "  Error al obtener discos: $_"
}


try {
    $network = Get-WmiObject -Class Win32_NetworkAdapter | Where-Object { $_.PhysicalAdapter -eq $true }
    foreach ($nic in $network) {
        $speedMbps = if ($nic.Speed) { [math]::Round($nic.Speed / 1MB, 0) } else { 0 }
        $inventory.Hardware += @{
            Type         = "Network"
            Manufacturer = $nic.Manufacturer
            Model        = $nic.Name
            SerialNumber = $nic.MACAddress
            Capacity     = "$speedMbps Mbps"
            Speed        = $nic.AdapterType
            Status       = $nic.NetConnectionStatus
        }
    }
    Write-Host "  ✓ Red: $($network.Count) adaptador(es)" -ForegroundColor Green
}
catch {
    Write-Warning "  Error al obtener red: $_"
}


Write-Host "`nRecopilando software..." -ForegroundColor Yellow

try {
    
    $software64 = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Where-Object { $_.DisplayName } |
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, InstallLocation, EstimatedSize
    
    
    $software32 = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName } |
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, InstallLocation, EstimatedSize
    
    $allSoftware = $software64 + $software32 | Sort-Object DisplayName -Unique
    
    foreach ($sw in $allSoftware) {
        $inventory.Software += @{
            Name            = $sw.DisplayName
            Version         = $sw.DisplayVersion
            Publisher       = $sw.Publisher
            InstallDate     = $sw.InstallDate
            InstallLocation = $sw.InstallLocation
            Size            = $sw.EstimatedSize
        }
    }
    
    Write-Host "  ✓ Software: $($inventory.Software.Count) aplicaciones" -ForegroundColor Green
}
catch {
    Write-Warning "  Error al obtener software: $_"
}


Write-Host "`nEnviando inventario al cliente..." -ForegroundColor Yellow

try {
    $json = $inventory | ConvertTo-Json -Depth 10
    $url = "http://${ClientIP}:${ClientPort}/inventory/"
    
    $response = Invoke-RestMethod -Uri $url -Method Post -Body $json -ContentType "application/json" -TimeoutSec 30
    
    if ($response.status -eq "success") {
        Write-Host "✓ Inventario enviado correctamente" -ForegroundColor Green
        Write-Host "  Respuesta: $($response.message)" -ForegroundColor Gray
        exit 0
    }
    else {
        Write-Warning "Advertencia: $($response.message)"
        exit 1
    }
}
catch {
    Write-Error "Error al enviar inventario: $_"
    Write-Host "URL: $url" -ForegroundColor Gray
    exit 2
}

