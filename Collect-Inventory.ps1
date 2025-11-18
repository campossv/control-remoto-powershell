


param(
    [Parameter(Mandatory = $true)]
    [string]$ServerIP
)

Import-Module ".\Modules\DatabaseManager.psm1" -Force

Write-Host "Recopilando inventario de $ServerIP..." -ForegroundColor Cyan


Write-Host "`n[1/3] Recopilando hardware..." -ForegroundColor Yellow

$hardwareComponents = @()


try {
    $cpu = Get-WmiObject -Class Win32_Processor -ComputerName $ServerIP
    foreach ($proc in $cpu) {
        $hardwareComponents += @{
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
    $memory = Get-WmiObject -Class Win32_PhysicalMemory -ComputerName $ServerIP
    foreach ($mem in $memory) {
        $capacityGB = [math]::Round($mem.Capacity / 1GB, 2)
        $hardwareComponents += @{
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
    $disks = Get-WmiObject -Class Win32_DiskDrive -ComputerName $ServerIP
    foreach ($disk in $disks) {
        $sizeGB = [math]::Round($disk.Size / 1GB, 2)
        $hardwareComponents += @{
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
    $network = Get-WmiObject -Class Win32_NetworkAdapter -ComputerName $ServerIP | Where-Object { $_.PhysicalAdapter -eq $true }
    foreach ($nic in $network) {
        $hardwareComponents += @{
            Type         = "Network"
            Manufacturer = $nic.Manufacturer
            Model        = $nic.Name
            SerialNumber = $nic.MACAddress
            Capacity     = "$($nic.Speed / 1MB) Mbps"
            Speed        = $nic.AdapterType
            Status       = $nic.NetConnectionStatus
        }
    }
    Write-Host "  ✓ Red: $($network.Count) adaptador(es)" -ForegroundColor Green
}
catch {
    Write-Warning "  Error al obtener red: $_"
}


if ($hardwareComponents.Count -gt 0) {
    $result = Add-HardwareInventory -ServerIP $ServerIP -HardwareComponents $hardwareComponents
    if ($result) {
        Write-Host "  ✓ Hardware guardado en BD: $($hardwareComponents.Count) componentes" -ForegroundColor Green
    }
}


Write-Host "`n[2/3] Recopilando software..." -ForegroundColor Yellow

$softwareList = @()

try {
    
    $software64 = Invoke-Command -ComputerName $ServerIP -ScriptBlock {
        Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
        Where-Object { $_.DisplayName } |
        Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, InstallLocation, EstimatedSize
    }
    
    
    $software32 = Invoke-Command -ComputerName $ServerIP -ScriptBlock {
        Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
        Where-Object { $_.DisplayName } |
        Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, InstallLocation, EstimatedSize
    }
    
    $allSoftware = $software64 + $software32 | Sort-Object DisplayName -Unique
    
    foreach ($sw in $allSoftware) {
        $softwareList += @{
            Name            = $sw.DisplayName
            Version         = $sw.DisplayVersion
            Publisher       = $sw.Publisher
            InstallDate     = $sw.InstallDate
            InstallLocation = $sw.InstallLocation
            Size            = $sw.EstimatedSize
        }
    }
    
    Write-Host "  ✓ Software encontrado: $($softwareList.Count) aplicaciones" -ForegroundColor Green
}
catch {
    Write-Warning "  Error al obtener software: $_"
}


if ($softwareList.Count -gt 0) {
    $result = Add-SoftwareInventory -ServerIP $ServerIP -SoftwareList $softwareList
    if ($result) {
        Write-Host "  ✓ Software guardado en BD" -ForegroundColor Green
    }
}


Write-Host "`n[3/3] Resumen del inventario:" -ForegroundColor Yellow
Write-Host "  • Hardware: $($hardwareComponents.Count) componentes" -ForegroundColor White
Write-Host "  • Software: $($softwareList.Count) aplicaciones" -ForegroundColor White


if ($softwareList.Count -gt 0) {
    Write-Host "`n  Top 10 software por tamaño:" -ForegroundColor Cyan
    $softwareList | Where-Object { $_.Size } | 
    Sort-Object Size -Descending | 
    Select-Object -First 10 | 
    ForEach-Object {
        $sizeMB = [math]::Round($_.Size / 1024, 2)
        Write-Host "    - $($_.Name): $sizeMB MB" -ForegroundColor Gray
    }
}

Write-Host "`n✓ Inventario completado" -ForegroundColor Green

