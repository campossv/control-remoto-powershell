


param(
    [int]$Port = 5000,
    [string]$CertificateThumbprint
)

Import-Module "$PSScriptRoot\Modules\DatabaseManager.psm1" -Force

Write-Host "=== Iniciando Receptor de Inventario ===" -ForegroundColor Cyan
Write-Host "Puerto: $Port" -ForegroundColor Gray


Write-Host "Inicializando base de datos..." -ForegroundColor Gray
$dbInit = Initialize-Database
if (-not $dbInit) {
    Write-Error "No se pudo inicializar la base de datos"
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
        
        try {
            
            if ($request.HttpMethod -ne "POST") {
                $response.StatusCode = 405
                $response.Close()
                Write-Warning "Método no permitido: $($request.HttpMethod)"
                continue
            }
            
            
            $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
            $body = $reader.ReadToEnd()
            $reader.Close()
            
            
            $inventory = $body | ConvertFrom-Json
            
            Write-Host "  Servidor: $($inventory.ServerIP)" -ForegroundColor White
            Write-Host "  Hostname: $($inventory.Hostname)" -ForegroundColor White
            Write-Host "  OS: $($inventory.OS)" -ForegroundColor Gray
            Write-Host "  Hardware: $($inventory.Hardware.Count) componentes" -ForegroundColor Gray
            Write-Host "  Software: $($inventory.Software.Count) aplicaciones" -ForegroundColor Gray
            
            
            $serverAdded = Add-Server -IPAddress $inventory.ServerIP -Hostname $inventory.Hostname -Description $inventory.Description -OS $inventory.OS -CertificateThumbprint $inventory.CertificateThumbprint
            if ($serverAdded) {
                Write-Host "  ✓ Servidor registrado" -ForegroundColor Green
            }
            else {
                Write-Warning "  Error al registrar servidor"
            }
            
            
            $saved = $false
            
            
            if ($inventory.Hardware -and $inventory.Hardware.Count -gt 0) {
                $hwResult = Add-HardwareInventory -ServerIP $inventory.ServerIP -HardwareComponents $inventory.Hardware
                if ($hwResult) {
                    Write-Host "  ✓ Hardware guardado" -ForegroundColor Green
                    $saved = $true
                }
                else {
                    Write-Warning "  Error al guardar hardware"
                }
            }
            
            
            if ($inventory.Software -and $inventory.Software.Count -gt 0) {
                $swResult = Add-SoftwareInventory -ServerIP $inventory.ServerIP -SoftwareList $inventory.Software
                if ($swResult) {
                    Write-Host "  ✓ Software guardado" -ForegroundColor Green
                    $saved = $true
                }
                else {
                    Write-Warning "  Error al guardar software"
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
            }
            else {
                $responseData = @{
                    status  = "warning"
                    message = "Inventario recibido pero sin datos válidos"
                } | ConvertTo-Json
                
                $response.StatusCode = 200
                Write-Warning "  Inventario sin datos válidos"
            }
            
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseData)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.Close()
        }
        catch {
            Write-Warning "Error al procesar solicitud: $_"
            
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
}

