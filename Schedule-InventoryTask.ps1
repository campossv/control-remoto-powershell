param(
    [Parameter(Mandatory = $true, HelpMessage = "Coloca la IP del servidor de administracion")]
    [string]$RemoteServer,
    
    [int]$RemoteServerPort = 5000,
    
    [Parameter(Mandatory = $true, HelpMessage = "Escribe Daily o Weekly")]
    [ValidateSet("Daily", "Weekly")]
    [string]$Frequency = "Daily",

    [Parameter(Mandatory = $true, HelpMessage = "Escribe la hora en formato HH:MM")]
    [string]$Time = "02:00"
)

Write-Host "=== Programador de Inventario Automático (LOCAL) ===" -ForegroundColor Cyan
Write-Host "Servidor remoto (destino inventario): $RemoteServer" -ForegroundColor White
Write-Host "Frecuencia: $Frequency a las $Time" -ForegroundColor White

# Directorio actual
$Directorio = Get-Location

Write-Host "`nCreando tarea programada local..." -ForegroundColor Yellow

# Ruta del script que enviará el inventario
$ScriptPath = Join-Path -Path $Directorio.Path -ChildPath "Servidor-InventoryAgent.ps1"

if (-not (Test-Path $ScriptPath)) {
    Write-Error "No se encontró el script: $ScriptPath"
    exit 1
}

# Acción: ejecutar PowerShell con el script y parámetros
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" -RemoteServer `"$RemoteServer`" -RemoteServerPort $RemoteServerPort"

# Trigger (diario o semanal)
if ($Frequency -eq "Daily") {
    $trigger = New-ScheduledTaskTrigger -Daily -At $Time
}
else {
    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At $Time
}

# Configuración de la tarea
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable

# Ejecutar como SYSTEM
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

$taskName = "InventoryAgent_AutoSend"

# Si ya existe, eliminarla
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# Registrar tarea local
Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Principal $principal `
    -Description "Envía inventario automático al servidor de administración $RemoteServer"

Write-Host "✓ Tarea programada creada: $taskName" -ForegroundColor Green

# Preguntar si quieres probarla
Write-Host "`n¿Deseas ejecutar el inventario ahora para probar? (S/N): " -NoNewline -ForegroundColor Yellow
$response = Read-Host

if ($response -eq "S" -or $response -eq "s") {
    Write-Host "`nEjecutando inventario de prueba..." -ForegroundColor Yellow
    try {
        Start-ScheduledTask -TaskName $taskName
        Write-Host "✓ Tarea ejecutada. Verifica el servidor receptor $RemoteServer :$RemoteServerPort." -ForegroundColor Green
    }
    catch {
        Write-Warning "Error al ejecutar tarea: $_"
    }
}

Write-Host "`n=== Configuración Completada (LOCAL) ===" -ForegroundColor Green
Write-Host "Frecuencia: $Frequency a las $Time" -ForegroundColor White
Write-Host "Destino: ${RemoteServer}:${RemoteServerPort}" -ForegroundColor White
Write-Host "`nPara verificar la tarea en este equipo:" -ForegroundColor Cyan
Write-Host "  Get-ScheduledTask -TaskName 'InventoryAgent_AutoSend'" -ForegroundColor Gray
