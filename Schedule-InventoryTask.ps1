


param(
    [Parameter(Mandatory = $true)]
    [string]$RemoteServer,
    
    [Parameter(Mandatory = $true)]
    [string]$ClientIP,
    
    [int]$ClientPort = 5000,
    
    [ValidateSet("Daily", "Weekly")]
    [string]$Frequency = "Daily",
    
    [string]$Time = "02:00",
    
    [System.Management.Automation.PSCredential]$Credential
)

Write-Host "=== Programador de Inventario Automático ===" -ForegroundColor Cyan
Write-Host "Servidor remoto: $RemoteServer" -ForegroundColor White
Write-Host "Cliente receptor: ${ClientIP}:${ClientPort}" -ForegroundColor White
Write-Host "Frecuencia: $Frequency a las $Time" -ForegroundColor White


Write-Host "`nValidando conexión..." -ForegroundColor Yellow
try {
    $testConnection = Test-Connection -ComputerName $RemoteServer -Count 1 -Quiet
    if (-not $testConnection) {
        throw "No se puede conectar a $RemoteServer"
    }
    Write-Host "✓ Conexión exitosa" -ForegroundColor Green
}
catch {
    Write-Error "Error de conexión: $_"
    exit 1
}


Write-Host "`nCopiando agente al servidor..." -ForegroundColor Yellow

$agentPath = "$PSScriptRoot\Servidor-InventoryAgent.ps1"
$remotePath = "\\$RemoteServer\C$\Scripts\InventoryAgent"

try {
    
    if (-not (Test-Path $remotePath)) {
        New-Item -ItemType Directory -Path $remotePath -Force | Out-Null
    }
    
    
    Copy-Item -Path $agentPath -Destination "$remotePath\Servidor-InventoryAgent.ps1" -Force
    
    Write-Host "✓ Agente copiado a: $remotePath" -ForegroundColor Green
}
catch {
    Write-Error "Error al copiar agente: $_"
    exit 2
}


Write-Host "`nCreando tarea programada..." -ForegroundColor Yellow

$scriptBlock = {
    param($RemoteServer, $ClientIP, $ClientPort, $Frequency, $Time)
    
    
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
        -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\Scripts\InventoryAgent\Servidor-InventoryAgent.ps1 -ClientIP $ClientIP -ClientPort $ClientPort"
    
    
    if ($Frequency -eq "Daily") {
        $trigger = New-ScheduledTaskTrigger -Daily -At $Time
    }
    else {
        $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At $Time
    }
    
    
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RunOnlyIfNetworkAvailable
    
    
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    
    $taskName = "InventoryAgent_AutoSend"
    
    
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }
    
    
    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Principal $principal `
        -Description "Envía inventario automático al cliente de administración"
    
    return $taskName
}

try {
    if ($Credential) {
        $taskName = Invoke-Command -ComputerName $RemoteServer -Credential $Credential -ScriptBlock $scriptBlock `
            -ArgumentList $RemoteServer, $ClientIP, $ClientPort, $Frequency, $Time
    }
    else {
        $taskName = Invoke-Command -ComputerName $RemoteServer -ScriptBlock $scriptBlock `
            -ArgumentList $RemoteServer, $ClientIP, $ClientPort, $Frequency, $Time
    }
    
    Write-Host "✓ Tarea programada creada: $taskName" -ForegroundColor Green
}
catch {
    Write-Error "Error al crear tarea: $_"
    exit 3
}


Write-Host "`n¿Deseas ejecutar el inventario ahora para probar? (S/N): " -NoNewline -ForegroundColor Yellow
$response = Read-Host

if ($response -eq "S" -or $response -eq "s") {
    Write-Host "`nEjecutando inventario de prueba..." -ForegroundColor Yellow
    
    try {
        $testScript = {
            Start-ScheduledTask -TaskName "InventoryAgent_AutoSend"
        }
        
        if ($Credential) {
            Invoke-Command -ComputerName $RemoteServer -Credential $Credential -ScriptBlock $testScript
        }
        else {
            Invoke-Command -ComputerName $RemoteServer -ScriptBlock $testScript
        }
        
        Write-Host "✓ Tarea ejecutada. Verifica el receptor en el cliente." -ForegroundColor Green
    }
    catch {
        Write-Warning "Error al ejecutar tarea: $_"
    }
}

Write-Host "`n=== Configuración Completada ===" -ForegroundColor Green
Write-Host "Servidor: $RemoteServer" -ForegroundColor White
Write-Host "Frecuencia: $Frequency a las $Time" -ForegroundColor White
Write-Host "Destino: ${ClientIP}:${ClientPort}" -ForegroundColor White
Write-Host "`nPara verificar la tarea en el servidor:" -ForegroundColor Cyan
Write-Host "  Get-ScheduledTask -TaskName 'InventoryAgent_AutoSend' -CimSession $RemoteServer" -ForegroundColor Gray

