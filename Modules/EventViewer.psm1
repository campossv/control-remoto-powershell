



function Get-RemoteEventLog {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RemoteServer,
        
        [Parameter(Mandatory = $true)]
        [int]$RemotePort,
        
        [Parameter(Mandatory = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$ClientCertificate,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("System", "Security", "Application")]
        [string]$LogName,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxEvents = 100,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("All", "Critical", "Error", "Warning", "Information")]
        [string]$Level = "All",
        
        [Parameter(Mandatory = $false)]
        [int]$Hours = 24
    )
    
    try {
        
        $tcpClient = New-Object System.Net.Sockets.TcpClient($RemoteServer, $RemotePort)
        $sslStream = New-Object System.Net.Security.SslStream(
            $tcpClient.GetStream(),
            $false,
            { param($sender, $certificate, $chain, $sslPolicyErrors) return $true }
        )
        
        
        $sslStream.AuthenticateAsClient($RemoteServer, (New-Object System.Security.Cryptography.X509Certificates.X509CertificateCollection $ClientCertificate), [System.Security.Authentication.SslProtocols]::Tls12, $false)
        
        $writer = New-Object System.IO.StreamWriter($sslStream)
        $writer.AutoFlush = $true
        $reader = New-Object System.IO.StreamReader($sslStream)
        
        
        $command = @{
            action = "GET_EVENT_LOG"
            params = @($LogName, $MaxEvents, $Level, $Hours)
        } | ConvertTo-Json -Compress
        
        $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($command))
        
        
        $writer.WriteLine($encodedCommand)
        
        
        $response = $reader.ReadLine()
        Write-Host "[DEBUG] Respuesta recibida (primeros 200 chars): $($response.Substring(0, [Math]::Min(200, $response.Length)))" -ForegroundColor Yellow
        
        $responseObj = $response | ConvertFrom-Json
        Write-Host "[DEBUG] Response success: $($responseObj.success)" -ForegroundColor Yellow
        
        if ($responseObj.success) {
            Write-Host "[DEBUG] Response count: $($responseObj.count)" -ForegroundColor Yellow
            Write-Host "[DEBUG] Response events type: $($responseObj.events.GetType().Name)" -ForegroundColor Yellow
        }
        else {
            Write-Host "[DEBUG] Response error: $($responseObj.message)" -ForegroundColor Red
        }
        
        
        $reader.Close()
        $writer.Close()
        $sslStream.Close()
        $tcpClient.Close()
        
        if ($responseObj.success) {
            Write-Host "[DEBUG] Retornando $($responseObj.events.Count) eventos" -ForegroundColor Yellow
            return $responseObj.events
        }
        else {
            Write-Warning "Error al obtener eventos: $($responseObj.message)"
            return $null
        }
    }
    catch {
        Write-Error "Error de conexion: $($_.Exception.Message)"
        return $null
    }
}


function Format-EventsForGrid {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Events
    )
    
    $formattedEvents = @()
    
    foreach ($event in $Events) {
        $formattedEvents += [PSCustomObject]@{
            Nivel       = $event.Level
            Fecha       = $event.TimeCreated
            Origen      = $event.Source
            EventID     = $event.EventID
            Mensaje     = $event.Message
            Usuario     = if ($event.UserName) { $event.UserName } else { "N/A" }
        }
    }
    
    return $formattedEvents
}


function Get-EventLevelColor {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Level
    )
    
    switch ($Level) {
        "Critical" { return [System.Drawing.Color]::DarkRed }
        "Error" { return [System.Drawing.Color]::Red }
        "Warning" { return [System.Drawing.Color]::Orange }
        "Information" { return [System.Drawing.Color]::Blue }
        default { return [System.Drawing.Color]::Black }
    }
}


function Export-EventsToCSV {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Events,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        $formattedEvents = Format-EventsForGrid -Events $Events
        $formattedEvents | Export-Csv -Path $FilePath -NoTypeInformation -Encoding UTF8
        return $true
    }
    catch {
        Write-Error "Error al exportar eventos: $($_.Exception.Message)"
        return $false
    }
}


function Update-EventLogGrid {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RemoteServer,
        
        [Parameter(Mandatory = $true)]
        [int]$RemotePort,
        
        [Parameter(Mandatory = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$ClientCertificate,
        
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.DataGridView]$DataGrid,
        
        [Parameter(Mandatory = $true)]
        [string]$LogName,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxEvents = 100,
        
        [Parameter(Mandatory = $false)]
        [string]$Level = "All",
        
        [Parameter(Mandatory = $false)]
        [int]$Hours = 24
    )
    
    try {
        
        $events = Get-RemoteEventLog -RemoteServer $RemoteServer -RemotePort $RemotePort `
            -ClientCertificate $ClientCertificate -LogName $LogName `
            -MaxEvents $MaxEvents -Level $Level -Hours $Hours
        
        if ($events) {
            Write-Host "[DEBUG] Eventos recibidos: $($events.Count)" -ForegroundColor Cyan
            Write-Host "[DEBUG] Tipo de eventos: $($events.GetType().Name)" -ForegroundColor Cyan
            
            
            $formattedEvents = Format-EventsForGrid -Events $events
            
            Write-Host "[DEBUG] Eventos formateados: $($formattedEvents.Count)" -ForegroundColor Cyan
            Write-Host "[DEBUG] Tipo de formattedEvents: $($formattedEvents.GetType().Name)" -ForegroundColor Cyan
            if ($formattedEvents.Count -gt 0) {
                Write-Host "[DEBUG] Primer evento: Nivel=$($formattedEvents[0].Nivel), Fecha=$($formattedEvents[0].Fecha)" -ForegroundColor Cyan
            }
            
            
            $DataGrid.DataSource = $null
            Write-Host "[DEBUG] DataSource limpiado" -ForegroundColor Cyan
            
            
            $arrayList = New-Object System.Collections.ArrayList
            $formattedEvents | ForEach-Object { [void]$arrayList.Add($_) }
            
            Write-Host "[DEBUG] ArrayList creado con $($arrayList.Count) elementos" -ForegroundColor Cyan
            
            $DataGrid.DataSource = $arrayList
            Write-Host "[DEBUG] DataSource asignado, Columnas: $($DataGrid.Columns.Count), Filas: $($DataGrid.Rows.Count)" -ForegroundColor Cyan
            
            
            $DataGrid.Refresh()
            Write-Host "[DEBUG] DataGrid.Refresh() ejecutado" -ForegroundColor Cyan
            
            
            if ($DataGrid.Columns.Count -gt 0) {
                foreach ($col in $DataGrid.Columns) {
                    switch ($col.Name) {
                        "Nivel" { $col.Width = 80 }
                        "Fecha" { $col.Width = 150 }
                        "Origen" { $col.Width = 150 }
                        "EventID" { $col.Width = 80 }
                        "Mensaje" { $col.Width = 400 }
                        "Usuario" { $col.Width = 120 }
                    }
                }
                
                
                foreach ($row in $DataGrid.Rows) {
                    if (-not $row.IsNewRow -and $row.Cells["Nivel"].Value) {
                        $color = Get-EventLevelColor -Level $row.Cells["Nivel"].Value
                        $row.Cells["Nivel"].Style.ForeColor = $color
                        $row.Cells["Nivel"].Style.Font = New-Object System.Drawing.Font("Arial", 9, [System.Drawing.FontStyle]::Bold)
                    }
                }
            }
            
            Write-Host "[EventViewer] Eventos cargados: $($formattedEvents.Count)" -ForegroundColor Green
            return $formattedEvents.Count
        }
        else {
            Write-Warning "[EventViewer] No se obtuvieron eventos"
            return 0
        }
    }
    catch {
        Write-Error "[EventViewer] Error: $($_.Exception.Message)"
        return 0
    }
}


Export-ModuleMember -Function Get-RemoteEventLog, Format-EventsForGrid, Get-EventLevelColor, Export-EventsToCSV, Update-EventLogGrid

