


param(
    [string]$ClientIP,
    [int]$Port = 5000,
    [ValidateSet("Daily", "Weekly")]
    [string]$Frequency = "Daily",
    [string]$Time = "02:00"
)

Write-Host "=== Configuración de Inventario Automático ===" -ForegroundColor Cyan


if (-not $ClientIP) {
    $ClientIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.*" } | Select-Object -First 1).IPAddress
    Write-Host "IP del cliente detectada: $ClientIP" -ForegroundColor Yellow
}

Write-Host "`nConfiguración:" -ForegroundColor White
Write-Host "  Cliente: $ClientIP" -ForegroundColor Gray
Write-Host "  Puerto: $Port" -ForegroundColor Gray
Write-Host "  Frecuencia: $Frequency a las $Time" -ForegroundColor Gray


Write-Host "`n[1/4] Configurando firewall..." -ForegroundColor Yellow

try {
    $existingRule = Get-NetFirewallRule -DisplayName "Inventory Receiver" -ErrorAction SilentlyContinue
    
    if ($existingRule) {
        Write-Host "  ⚠ Regla de firewall ya existe" -ForegroundColor Yellow
    }
    else {
        New-NetFirewallRule -DisplayName "Inventory Receiver" `
            -Direction Inbound `
            -LocalPort $Port `
            -Protocol TCP `
            -Action Allow | Out-Null
        
        Write-Host "  ✓ Regla de firewall creada" -ForegroundColor Green
    }
}
catch {
    Write-Warning "  Error al configurar firewall: $_"
    Write-Host "  Ejecuta manualmente como Administrador:" -ForegroundColor Yellow
    Write-Host "  New-NetFirewallRule -DisplayName 'Inventory Receiver' -Direction Inbound -LocalPort $Port -Protocol TCP -Action Allow" -ForegroundColor Gray
}


Write-Host "`n[2/4] Iniciando receptor..." -ForegroundColor Yellow

try {
    $receiverScript = Join-Path $PSScriptRoot "Start-InventoryListener.ps1"
    
    Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$receiverScript`"", "-Port", $Port
    
    Write-Host "  ✓ Receptor iniciado en ventana separada" -ForegroundColor Green
    Write-Host "  Puerto: $Port" -ForegroundColor Gray
    
    Start-Sleep -Seconds 2
}
catch {
    Write-Warning "  Error al iniciar receptor: $_"
}


Write-Host "`n[3/4] Cargando servidores desde BD..." -ForegroundColor Yellow

Import-Module "$PSScriptRoot\Modules\DatabaseManager.psm1" -Force

$servers = Get-Servers

if ($servers -and $servers.Rows.Count -gt 0) {
    Write-Host "  ✓ Servidores encontrados: $($servers.Rows.Count)" -ForegroundColor Green
    
    foreach ($row in $servers.Rows) {
        Write-Host "    - $($row['IPAddress']) - $($row['Description'])" -ForegroundColor Gray
    }
}
else {
    Write-Warning "  No hay servidores en la BD"
    Write-Host "  Agrega servidores primero o ejecuta Cliente-Modular.ps1" -ForegroundColor Yellow
    exit 1
}


Write-Host "`n[4/4] Programando inventario en servidores..." -ForegroundColor Yellow
Write-Host "¿Deseas programar el inventario en TODOS los servidores? (S/N): " -NoNewline -ForegroundColor Yellow
$response = Read-Host

if ($response -eq "S" -or $response -eq "s") {
    $successCount = 0
    $failCount = 0
    
    foreach ($row in $servers.Rows) {
        $serverIP = $row['IPAddress']
        Write-Host "`n  Configurando: $serverIP" -ForegroundColor Cyan
        
        try {
            & "$PSScriptRoot\Schedule-InventoryTask.ps1" `
                -RemoteServer $serverIP `
                -ClientIP $ClientIP `
                -ClientPort $Port `
                -Frequency $Frequency `
                -Time $Time `
                -ErrorAction Stop
            
            $successCount++
            Write-Host "    ✓ Configurado" -ForegroundColor Green
        }
        catch {
            $failCount++
            Write-Warning "    Error: $_"
        }
    }
    
    Write-Host "`n=== Resumen ===" -ForegroundColor Cyan
    Write-Host "  Exitosos: $successCount" -ForegroundColor Green
    Write-Host "  Fallidos: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Gray" })
}
else {
    Write-Host "  Configuración manual requerida" -ForegroundColor Yellow
    Write-Host "  Usa: .\Schedule-InventoryTask.ps1 -RemoteServer IP -ClientIP $ClientIP" -ForegroundColor Gray
}

Write-Host "`n=== Configuración Completada ===" -ForegroundColor Green
Write-Host "`nEl receptor está corriendo en segundo plano." -ForegroundColor White
Write-Host "Los servidores enviarán inventario automáticamente según programación." -ForegroundColor White
Write-Host "`nPara ver inventarios recibidos:" -ForegroundColor Cyan
Write-Host "  Import-Module .\Modules\DatabaseManager.psm1" -ForegroundColor Gray
Write-Host "  Get-HardwareInventory -ServerIP '192.168.1.100'" -ForegroundColor Gray
Write-Host "  Get-SoftwareInventory -ServerIP '192.168.1.100'" -ForegroundColor Gray

