



$script:LogDirectory = "$PSScriptRoot\..\Logs"
$script:CurrentSessionLog = $null
$script:CurrentSessionId = $null
$script:SessionStartTime = $null

function Initialize-SessionLogger {
    
    param (
        [string]$LogDirectory = "$PSScriptRoot\..\Logs"
    )
    
    $script:LogDirectory = $LogDirectory
    
    
    if (-not (Test-Path $script:LogDirectory)) {
        New-Item -ItemType Directory -Path $script:LogDirectory -Force | Out-Null
    }
    
    Write-Host "[LOGGER] Sistema de logging inicializado en: $script:LogDirectory" -ForegroundColor Green
}

function Start-RemoteSession {
    
    param (
        [Parameter(Mandatory = $true)]
        [string]$ServerIP,
        
        [string]$ServerName = "Unknown",
        
        [string]$CertificateThumbprint = "N/A"
    )
    
    
    $script:CurrentSessionId = [Guid]::NewGuid().ToString().Substring(0, 8)
    
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $logFileName = "Session_${ServerIP}_${timestamp}_${script:CurrentSessionId}.log"
    $script:CurrentSessionLog = Join-Path $script:LogDirectory $logFileName
    
    
    $header = @"
================================================================================
NUEVA SESIÓN REMOTA
================================================================================
Session ID:    $script:CurrentSessionId
Fecha/Hora:    $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Servidor IP:   $ServerIP
Servidor:      $ServerName
Usuario:       $env:USERNAME
Equipo Local:  $env:COMPUTERNAME
Certificado:   $CertificateThumbprint
================================================================================

"@
    
    Add-Content -Path $script:CurrentSessionLog -Value $header -Encoding UTF8
    
    
    $script:SessionStartTime = Get-Date
    
    Write-Host "[LOGGER] Sesión iniciada: $script:CurrentSessionId" -ForegroundColor Cyan
    
    return $script:CurrentSessionId
}

function Write-SessionLog {
    
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "COMMAND", "FILE", "PROCESS", "SERVICE")]
        [string]$Level,
        
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [string]$Details = ""
    )
    
    if (-not $script:CurrentSessionLog) {
        Write-Warning "[LOGGER] No hay sesión activa. Inicialice con Start-RemoteSession"
        return
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    
    
    $logEntry = "[$timestamp] [$Level] $Message"
    
    if ($Details) {
        $logEntry += "`n    Detalles: $Details"
    }
    
    
    Add-Content -Path $script:CurrentSessionLog -Value $logEntry -Encoding UTF8
    
    
    $color = switch ($Level) {
        "INFO" { "White" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "COMMAND" { "Cyan" }
        "FILE" { "Magenta" }
        "PROCESS" { "Blue" }
        "SERVICE" { "DarkCyan" }
        default { "Gray" }
    }
    
    Write-Host "[LOG] $Message" -ForegroundColor $color
}

function Stop-RemoteSession {
    
    param (
        [string]$Reason = "Usuario cerró la sesión"
    )
    
    if (-not $script:CurrentSessionLog) {
        return
    }
    
    $durationText = "N/A"
    if ($script:SessionStartTime) {
        $duration = (Get-Date) - $script:SessionStartTime
        $durationText = $duration.ToString()
    }
    
    $footer = @"

================================================================================
FIN DE SESIÓN
================================================================================
Session ID:    $script:CurrentSessionId
Fecha/Hora:    $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Motivo:        $Reason
Duración:      $durationText
================================================================================
"@
    
    Add-Content -Path $script:CurrentSessionLog -Value $footer -Encoding UTF8
    
    Write-Host "[LOGGER] Sesión finalizada: $script:CurrentSessionId" -ForegroundColor Yellow
    
    
    $script:CurrentSessionLog = $null
    $script:CurrentSessionId = $null
    $script:SessionStartTime = $null
}

function Get-SessionHistory {
    
    param (
        [int]$Last = 10,
        [string]$ServerIP = "*"
    )
    
    if (-not (Test-Path $script:LogDirectory)) {
        Write-Warning "No hay logs disponibles"
        return @()
    }
    
    $pattern = "Session_${ServerIP}_*.log"
    $logFiles = Get-ChildItem -Path $script:LogDirectory -Filter $pattern |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First $Last
    
    $sessions = @()
    
    foreach ($logFile in $logFiles) {
        
        if ($logFile.Name -match "Session_(.+)_(\d{8}_\d{6})_(.+)\.log") {
            $sessions += [PSCustomObject]@{
                ServerIP  = $matches[1]
                DateTime  = [DateTime]::ParseExact($matches[2], "yyyyMMdd_HHmmss", $null)
                SessionID = $matches[3]
                LogFile   = $logFile.FullName
                Size      = $logFile.Length
            }
        }
    }
    
    return $sessions
}

function Show-SessionLog {
    
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogFile
    )
    
    if (-not (Test-Path $LogFile)) {
        Write-Error "Archivo de log no encontrado: $LogFile"
        return
    }
    
    Get-Content -Path $LogFile -Encoding UTF8 | ForEach-Object {
        $line = $_
        
        
        if ($line -match "\[ERROR\]") {
            Write-Host $line -ForegroundColor Red
        }
        elseif ($line -match "\[WARNING\]") {
            Write-Host $line -ForegroundColor Yellow
        }
        elseif ($line -match "\[SUCCESS\]") {
            Write-Host $line -ForegroundColor Green
        }
        elseif ($line -match "\[COMMAND\]") {
            Write-Host $line -ForegroundColor Cyan
        }
        elseif ($line -match "\[FILE\]") {
            Write-Host $line -ForegroundColor Magenta
        }
        else {
            Write-Host $line
        }
    }
}

function Export-SessionReport {
    
    param (
        [string]$OutputPath = ".\SessionReport.html",
        [int]$Days = 7
    )
    
    $sessions = Get-SessionHistory -Last 1000 |
    Where-Object { $_.DateTime -gt (Get-Date).AddDays(-$Days) }
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Reporte de Sesiones Remotas</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        h1 { color: #333; }
        table { width: 100%; border-collapse: collapse; background: white; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        th { background: #4CAF50; color: white; padding: 12px; text-align: left; }
        td { padding: 10px; border-bottom: 1px solid #ddd; }
        tr:hover { background: #f5f5f5; }
        .stats { display: flex; gap: 20px; margin-bottom: 20px; }
        .stat-card { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); flex: 1; }
        .stat-number { font-size: 32px; font-weight: bold; color: #4CAF50; }
    </style>
</head>
<body>
    <h1>📊 Reporte de Sesiones Remotas</h1>
    <p>Período: Últimos $Days días</p>
    
    <div class="stats">
        <div class="stat-card">
            <div class="stat-number">$($sessions.Count)</div>
            <div>Total de Sesiones</div>
        </div>
        <div class="stat-card">
            <div class="stat-number">$($sessions | Select-Object -Unique ServerIP | Measure-Object | Select-Object -ExpandProperty Count)</div>
            <div>Servidores Únicos</div>
        </div>
    </div>
    
    <table>
        <tr>
            <th>Fecha/Hora</th>
            <th>Servidor IP</th>
            <th>Session ID</th>
            <th>Tamaño Log</th>
            <th>Acción</th>
        </tr>
"@
    
    foreach ($session in $sessions) {
        $html += @"
        <tr>
            <td>$($session.DateTime.ToString("yyyy-MM-dd HH:mm:ss"))</td>
            <td>$($session.ServerIP)</td>
            <td>$($session.SessionID)</td>
            <td>$([math]::Round($session.Size / 1KB, 2)) KB</td>
            <td><a href="file:///$($session.LogFile)">Ver Log</a></td>
        </tr>
"@
    }
    
    $html += @"
    </table>
    <p style="margin-top: 20px; color: 
</body>
</html>
"@
    
    $html | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "[LOGGER] Reporte exportado a: $OutputPath" -ForegroundColor Green
    
    return $OutputPath
}


Export-ModuleMember -Function Initialize-SessionLogger, Start-RemoteSession, Write-SessionLog, Stop-RemoteSession, Get-SessionHistory, Show-SessionLog, Export-SessionReport


