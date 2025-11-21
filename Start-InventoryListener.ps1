


param(
    [int]$Port = 5000,
    [string]$CertificateThumbprint
)

Import-Module "$PSScriptRoot\Modules\DatabaseManager.psm1" -Force

$logDir = Join-Path $PSScriptRoot 'logs'
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

$logFile = Join-Path $logDir ("Inventory_{0:yyyyMMdd}.log" -f (Get-Date))

function Write-InventoryLog {
    param(
        [string]$Level,
        [string]$Message
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$timestamp] [$Level] $Message"
    Add-Content -Path $logFile -Value $line
}

Write-Host "=== Iniciando Receptor de Inventario ===" -ForegroundColor Cyan
Write-Host "Puerto: $Port" -ForegroundColor Gray
Write-InventoryLog -Level 'INFO' -Message "Receptor de inventario iniciado en puerto $Port"

Write-Host "Inicializando base de datos..." -ForegroundColor Gray
Write-InventoryLog -Level 'INFO' -Message 'Inicializando base de datos'
$dbInit = Initialize-Database
if (-not $dbInit) {
    Write-Error "No se pudo inicializar la base de datos"
    Write-InventoryLog -Level 'ERROR' -Message 'No se pudo inicializar la base de datos'
    exit 1
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:$Port/inventory/")
$listener.Start()

Write-Host "✓ Escuchando en puerto $Port" -ForegroundColor Green
Write-Host "Esperando inventarios de servidores..." -ForegroundColor Yellow
Write-Host "Presiona Ctrl+C para detener" -ForegroundColor Gray

try {
    while ($listener.IsListening) {
        
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] Solicitud recibida desde: $($request.RemoteEndPoint)" -ForegroundColor Cyan
        Write-InventoryLog -Level 'INFO' -Message "Solicitud recibida desde $($request.RemoteEndPoint) con método $($request.HttpMethod)"
        
        try {
            
            if ($request.HttpMethod -ne "POST") {
                $response.StatusCode = 405
                $response.Close()
                Write-Warning "Método no permitido: $($request.HttpMethod)"
                Write-InventoryLog -Level 'WARN' -Message "Método no permitido: $($request.HttpMethod) desde $($request.RemoteEndPoint)"
                continue
            }
            
            
            $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
            $body = $reader.ReadToEnd()
            $reader.Close()
            
            
            $inventory = $body | ConvertFrom-Json
            Write-InventoryLog -Level 'INFO' -Message "Inventario recibido de servidor $($inventory.ServerIP) hostname $($inventory.Hostname)"
            
            Write-Host "  Servidor: $($inventory.ServerIP)" -ForegroundColor White
            Write-Host "  Hostname: $($inventory.Hostname)" -ForegroundColor White
            Write-Host "  OS: $($inventory.OS)" -ForegroundColor Gray
            Write-Host "  Hardware: $($inventory.Hardware.Count) componentes" -ForegroundColor Gray
            Write-Host "  Software: $($inventory.Software.Count) aplicaciones" -ForegroundColor Gray
            
            
            $serverAdded = Add-Server -IPAddress $inventory.ServerIP -Hostname $inventory.Hostname -Description $inventory.Description -OS $inventory.OS -CertificateThumbprint $inventory.CertificateThumbprint
            if ($serverAdded) {
                Write-Host "  ✓ Servidor registrado" -ForegroundColor Green
                Write-InventoryLog -Level 'INFO' -Message "Servidor $($inventory.ServerIP) registrado correctamente"
            }
            else {
                Write-Warning "  Error al registrar servidor"
                Write-InventoryLog -Level 'WARN' -Message "Error al registrar servidor $($inventory.ServerIP)"
            }
            
            
            $saved = $false
            
            
            if ($inventory.Hardware -and $inventory.Hardware.Count -gt 0) {
                $hwResult = Add-HardwareInventory -ServerIP $inventory.ServerIP -HardwareComponents $inventory.Hardware
                if ($hwResult) {
                    Write-Host "  ✓ Hardware guardado" -ForegroundColor Green
                    Write-InventoryLog -Level 'INFO' -Message "Hardware guardado para servidor $($inventory.ServerIP) (componentes: $($inventory.Hardware.Count))"
                    $saved = $true
                }
                else {
                    Write-Warning "  Error al guardar hardware"
                    Write-InventoryLog -Level 'WARN' -Message "Error al guardar hardware para servidor $($inventory.ServerIP)"
                }
            }
            
            
            if ($inventory.Software -and $inventory.Software.Count -gt 0) {
                $swResult = Add-SoftwareInventory -ServerIP $inventory.ServerIP -SoftwareList $inventory.Software
                if ($swResult) {
                    Write-Host "  ✓ Software guardado" -ForegroundColor Green
                    Write-InventoryLog -Level 'INFO' -Message "Software guardado para servidor $($inventory.ServerIP) (aplicaciones: $($inventory.Software.Count))"
                    $saved = $true
                }
                else {
                    Write-Warning "  Error al guardar software"
                    Write-InventoryLog -Level 'WARN' -Message "Error al guardar software para servidor $($inventory.ServerIP)"
                }
            }
            
            
            if ($saved) {
                $responseData = @{
                    status    = "success"
                    message   = "Inventario recibido y guardado"
                    timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                } | ConvertTo-Json
                
                $response.StatusCode = 200
                Write-Host "  ✓ Inventario procesado correctamente" -ForegroundColor Green
                Write-InventoryLog -Level 'INFO' -Message "Inventario procesado correctamente para servidor $($inventory.ServerIP)"
            }
            else {
                $responseData = @{
                    status  = "warning"
                    message = "Inventario recibido pero sin datos válidos"
                } | ConvertTo-Json
                
                $response.StatusCode = 200
                Write-Warning "  Inventario sin datos válidos"
                Write-InventoryLog -Level 'WARN' -Message "Inventario sin datos válidos para servidor $($inventory.ServerIP)"
            }
            
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseData)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.Close()
        }
        catch {
            Write-Warning "Error al procesar solicitud: $_"
            Write-InventoryLog -Level 'ERROR' -Message "Error al procesar solicitud desde $($request.RemoteEndPoint): $($_.Exception.Message)"
            
            $errorData = @{
                status  = "error"
                message = $_.Exception.Message
            } | ConvertTo-Json
            
            $response.StatusCode = 500
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($errorData)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.Close()
        }
    }
}
finally {
    $listener.Stop()
    Write-Host "`n✓ Receptor detenido" -ForegroundColor Yellow
    Write-InventoryLog -Level 'INFO' -Message 'Receptor de inventario detenido'
}

