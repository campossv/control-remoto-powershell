


function Handle-ExecuteCommand {
    param (
        [PSCustomObject]$commandObj,
        [System.IO.StreamWriter]$writer
    )
    $commandToExecute = $commandObj.params[0]
    try {
        $output = Invoke-Expression $commandToExecute | Out-String
        $response = @{ success = $true; output = $output } | ConvertTo-Json
    }
    catch {
        $response = @{ success = $false; message = $_.Exception.Message } | ConvertTo-Json
    }
    $writer.WriteLine($response)
    $writer.Flush()
}

function Handle-UploadFile {
    param (
        [PSCustomObject]$commandObj,
        [System.IO.StreamWriter]$writer
    )
    $remoteFilePath = $commandObj.params[0]
    $fileContentBase64 = $commandObj.params[1]
    try {
        $fileContent = [System.Convert]::FromBase64String($fileContentBase64)
        [System.IO.File]::WriteAllBytes($remoteFilePath, $fileContent)
        $response = @{ success = $true; message = "Archivo subido exitosamente." } | ConvertTo-Json -Compress
    }
    catch {
        $response = @{ success = $false; message = $_.Exception.Message } | ConvertTo-Json -Compress
    }
    Write-Host "Enviando respuesta: $response"
    $writer.WriteLine($response)
    $writer.Flush()
}

function Handle-ListFiles {
    param (
        [PSCustomObject]$commandObj,
        [System.IO.StreamWriter]$writer
    )
    $directoryPath = $commandObj.params[0]
    try {
        Write-Host "[v0] Attempting to list files in: $directoryPath"
        if (Test-Path $directoryPath) {
            $files = Get-ChildItem -Path $directoryPath -ErrorAction Stop | Select-Object -ExpandProperty FullName
            $response = @{ success = $true; files = @($files); currentPath = $directoryPath } | ConvertTo-Json -Compress
        }
        else {
            $response = @{ success = $false; message = "Directorio no encontrado: $directoryPath" } | ConvertTo-Json -Compress
        }
    }
    catch {
        $response = @{ success = $false; message = $_.Exception.Message } | ConvertTo-Json -Compress
    }
    Write-Host "Enviando respuesta: $response"
    $writer.WriteLine($response)
    $writer.Flush()
}

function Handle-DeleteFile {
    param (
        [PSCustomObject]$commandObj,
        [System.IO.StreamWriter]$writer
    )
    $filePath = $commandObj.params[0]
    try {
        Remove-Item -Path $filePath -Force
        $response = @{ success = $true; message = 'Archivo eliminado.' } | ConvertTo-Json -Compress
    }
    catch {
        $response = @{ success = $false; message = $_.Exception.Message } | ConvertTo-Json -Compress
    }
    Write-Host "Enviando respuesta: $response"
    $writer.WriteLine($response)
    $writer.Flush()
}

function Handle-CopyFile {
    param (
        [PSCustomObject]$commandObj,
        [System.IO.StreamWriter]$writer
    )
    $sourcePath = $commandObj.params[0]
    $destinationPath = $commandObj.params[1]
    try {
        Copy-Item -Path $sourcePath -Destination $destinationPath
        $response = @{ success = $true; message = 'Archivo copiado.' } | ConvertTo-Json -Compress
    }
    catch {
        $response = @{ success = $false; message = $_.Exception.Message } | ConvertTo-Json -Compress
    }
    Write-Host "Enviando respuesta: $response"
    $writer.WriteLine($response)
    $writer.Flush()
}

function Handle-MoveFile {
    param (
        [PSCustomObject]$commandObj,
        [System.IO.StreamWriter]$writer
    )
    $sourcePath = $commandObj.params[0]
    $destinationPath = $commandObj.params[1]
    try {
        Move-Item -Path $sourcePath -Destination $destinationPath
        $response = @{ success = $true; message = 'Archivo movido.' } | ConvertTo-Json -Compress
    }
    catch {
        $response = @{ success = $false; message = $_.Exception.Message } | ConvertTo-Json -Compress
    }
    Write-Host "Enviando respuesta: $response"
    $writer.WriteLine($response)
    $writer.Flush()
}

function Handle-DownloadFile {
    param (
        [PSCustomObject]$commandObj,
        [System.IO.StreamWriter]$writer
    )
    $remoteFilePath = $commandObj.params[0]
    try {
        if (Test-Path $remoteFilePath) {
            $fileContent = [System.IO.File]::ReadAllBytes($remoteFilePath)
            $fileContentBase64 = [System.Convert]::ToBase64String($fileContent)
            $response = @{
                success     = $true
                fileContent = $fileContentBase64
                fileName    = [System.IO.Path]::GetFileName($remoteFilePath)
            } | ConvertTo-Json -Compress
        }
        else {
            $response = @{ success = $false; message = "El archivo no existe." } | ConvertTo-Json -Compress
        }
        $writer.WriteLine($response)
        $writer.Flush()
    }
    catch {
        $response = @{ success = $false; message = $_.Exception.Message } | ConvertTo-Json -Compress
        $writer.WriteLine($response)
        $writer.Flush()
    }
}

function Handle-GetProcesses {
    param (
        [PSCustomObject]$commandObj,
        [System.IO.StreamWriter]$writer
    )
    $filtro = $commandObj.params[0]
    $procesos = Get-Process | ForEach-Object {
        [PSCustomObject]@{
            Id            = $_.Id
            Name          = $_.Name
            CPU           = $_.CPU
            "Memory (MB)" = [math]::Round($_.WorkingSet64 / 1MB, 2)
        }
    } | Sort-Object Name

    if ($filtro) {
        $procesos = $procesos | Where-Object { $_.Name -like "*$filtro*" -or $_.Id -like "*$filtro*" }
    }

    $writer.WriteLine(($procesos | ConvertTo-Json))
    $writer.Flush()
}

function Handle-GetServices {
    param (
        [PSCustomObject]$commandObj,
        [System.IO.StreamWriter]$writer
    )
    $filtro = $commandObj.params[0]
    $excluirMicrosoft = [System.Convert]::ToBoolean($commandObj.params[1])
    $servicios = Get-CimInstance -ClassName Win32_Service | Select-Object Name, DisplayName, State, StartMode, @{Name = "CompanyName"; Expression = { $_.PathName | ForEach-Object { (Get-ItemProperty $_).VersionInfo.CompanyName } } } | Sort-Object DisplayName

    if ($filtro) {
        $servicios = $servicios | Where-Object { $_.Name -like "*$filtro*" -or $_.DisplayName -like "*$filtro*" }
    }

    if ($excluirMicrosoft) {
        $servicios = $servicios | Where-Object { $_.CompanyName -notlike "*Microsoft*" }
    }

    $writer.WriteLine(($servicios | ConvertTo-Json))
    $writer.Flush()
}

function Handle-TerminateProcess {
    param (
        [PSCustomObject]$commandObj,
        [System.IO.StreamWriter]$writer
    )
    $processId = $commandObj.params[0]
    try {
        Stop-Process -Id $processId -Force
        $response = @{ success = $true; message = "Proceso terminado" } | ConvertTo-Json
    }
    catch {
        $response = @{ success = $false; message = $_.Exception.Message } | ConvertTo-Json
    }
    $writer.WriteLine($response)
    $writer.Flush()
}

function Handle-StartService {
    param (
        [PSCustomObject]$commandObj,
        [System.IO.StreamWriter]$writer
    )
    $serviceName = $commandObj.params[0]
    try {
        $service = Get-Service -Name $serviceName -ErrorAction Stop
        if ($service.Status -eq 'Stopped') {
            Start-Service -Name $serviceName -ErrorAction Stop
            $response = @{ success = $true; message = "Servicio '$serviceName' iniciado exitosamente." } | ConvertTo-Json
        }
        else {
            $response = @{ success = $false; message = "El servicio '$serviceName' está en ejecución." } | ConvertTo-Json
        }
    }
    catch {
        $response = @{ success = $false; message = "Error al iniciar el servicio '$serviceName': $($_.Exception.Message)" } | ConvertTo-Json
    }
    $writer.WriteLine($response)
    $writer.Flush()
}

function Handle-StopService {
    param (
        [PSCustomObject]$commandObj,
        [System.IO.StreamWriter]$writer
    )
    $serviceName = $commandObj.params[0]
    try {
        $service = Get-Service -Name $serviceName -ErrorAction Stop
        if ($service.Status -eq 'Running') {
            Stop-Service -Name $serviceName -Force -ErrorAction Stop
            $response = @{ success = $true; message = "Servicio '$serviceName' detenido exitosamente." } | ConvertTo-Json
        }
        else {
            $response = @{ success = $false; message = "El servicio '$serviceName' no está en ejecución." } | ConvertTo-Json
        }
    }
    catch {
        $response = @{ success = $false; message = "Error al detener el servicio '$serviceName': $($_.Exception.Message)" } | ConvertTo-Json
    }
    $writer.WriteLine($response)
    $writer.Flush()
}

function Handle-RestartService {
    param (
        [PSCustomObject]$commandObj,
        [System.IO.StreamWriter]$writer
    )
    $serviceName = $commandObj.params[0]
    try {
        $service = Get-Service -Name $serviceName -ErrorAction Stop
        Restart-Service -Name $serviceName -Force -ErrorAction Stop
        $response = @{ success = $true; message = "Servicio '$serviceName' reiniciado exitosamente." } | ConvertTo-Json
    }
    catch {
        $response = @{ success = $false; message = "Error al reiniciar el servicio '$serviceName': $($_.Exception.Message)" } | ConvertTo-Json
    }
    $writer.WriteLine($response)
    $writer.Flush()
}

function Handle-IsDirectory {
    param (
        [PSCustomObject]$commandObj,
        [System.IO.StreamWriter]$writer
    )
    $itemPath = $commandObj.params[0]
    try {
        $isDir = Test-Path -Path $itemPath -PathType Container
        $response = @{ success = $true; isDirectory = $isDir } | ConvertTo-Json -Compress
    }
    catch {
        $response = @{ success = $false; message = $_.Exception.Message } | ConvertTo-Json -Compress
    }
    Write-Host "Enviando respuesta: $response"
    $writer.WriteLine($response)
    $writer.Flush()
}

function Handle-GetSystemInfo {
    param (
        [PSCustomObject]$commandObj,
        [System.IO.StreamWriter]$writer
    )
    try {
        
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $cs = Get-CimInstance -ClassName Win32_ComputerSystem
        $cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
        
        
        $cpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue).CounterSamples.CookedValue
        if (-not $cpuUsage) { $cpuUsage = 0 }
        
        
        $totalRAM = $os.TotalVisibleMemorySize * 1KB
        $freeRAM = $os.FreePhysicalMemory * 1KB
        $usedRAM = $totalRAM - $freeRAM
        $ramUsagePercent = ($usedRAM / $totalRAM) * 100
        
        
        $lastBootTime = $os.LastBootUpTime
        $uptime = (Get-Date) - $lastBootTime
        $uptimeSeconds = [long]$uptime.TotalSeconds
        
        
        $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
            $usedSpace = $_.Size - $_.FreeSpace
            $usagePercent = if ($_.Size -gt 0) { ($usedSpace / $_.Size) * 100 } else { 0 }
            
            @{
                Drive        = $_.DeviceID
                Label        = $_.VolumeName
                TotalSize    = $_.Size
                FreeSpace    = $_.FreeSpace
                UsedSpace    = $usedSpace
                UsagePercent = [math]::Round($usagePercent, 1)
            }
        }
        
        
        $networkAdapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object {
            $ipConfig = Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -First 1
            
            @{
                Name        = $_.Name
                Description = $_.InterfaceDescription
                Status      = $_.Status
                Speed       = $_.LinkSpeed
                IPAddress   = if ($ipConfig) { $ipConfig.IPAddress } else { "N/A" }
                MACAddress  = $_.MacAddress
            }
        }
        
        
        $systemInfo = @{
            ComputerName    = $cs.Name
            OSVersion       = $os.Caption
            OSArchitecture  = $os.OSArchitecture
            CPUName         = $cpu.Name
            CPUCores        = $cpu.NumberOfCores
            CPUUsage        = [math]::Round($cpuUsage, 1)
            TotalRAM        = $totalRAM
            UsedRAM         = $usedRAM
            FreeRAM         = $freeRAM
            RAMUsagePercent = [math]::Round($ramUsagePercent, 1)
            UptimeSeconds   = $uptimeSeconds
            LastBootTime    = $lastBootTime.ToString("yyyy-MM-dd HH:mm:ss")
            Disks           = $disks
            NetworkAdapters = $networkAdapters
        }
        
        $response = @{ success = $true; systemInfo = $systemInfo } | ConvertTo-Json -Depth 10 -Compress
    }
    catch {
        $response = @{ success = $false; message = $_.Exception.Message } | ConvertTo-Json -Compress
    }
    
    Write-Host "Enviando información del sistema"
    $writer.WriteLine($response)
    $writer.Flush()
}

function Handle-GetEventLog {
    param (
        [PSCustomObject]$commandObj,
        [System.IO.StreamWriter]$writer
    )
    
    $logName = $commandObj.params[0]
    $maxEvents = $commandObj.params[1]
    $level = $commandObj.params[2]
    $hours = $commandObj.params[3]
    
    try {
        
        $startTime = (Get-Date).AddHours(-$hours)
        
        
        $filterHash = @{
            LogName   = $logName
            StartTime = $startTime
        }
        
        
        if ($level -ne "All") {
            $levelFilter = switch ($level) {
                "Critical" { 1 }
                "Error" { 2 }
                "Warning" { 3 }
                "Information" { 4 }
                default { @(1, 2, 3, 4) }
            }
            $filterHash.Add("Level", $levelFilter)
        }
        
        
        $rawEvents = @()
        try {
            $rawEvents = Get-WinEvent -FilterHashtable $filterHash -MaxEvents $maxEvents -ErrorAction Stop
        }
        catch {
            
            if ($_.Exception.Message -like "*No events were found*") {
                $rawEvents = @()
            }
            else {
                throw
            }
        }
        
        
        $events = $rawEvents | ForEach-Object {
            @{
                Level       = $_.LevelDisplayName
                TimeCreated = $_.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
                Source      = $_.ProviderName
                EventID     = $_.Id
                Message     = if ($_.Message) { $_.Message.Substring(0, [Math]::Min(500, $_.Message.Length)) } else { "" }
                UserName    = if ($_.UserId) { $_.UserId.Value } else { "N/A" }
            }
        }
        
        $response = @{ 
            success = $true
            events  = @($events)
            count   = $events.Count
        } | ConvertTo-Json -Depth 10 -Compress
    }
    catch {
        $response = @{ 
            success = $false
            message = $_.Exception.Message
        } | ConvertTo-Json -Compress
    }
    
    Write-Host "Enviando eventos del log: $logName"
    $writer.WriteLine($response)
    $writer.Flush()
}

function Handle-GetSoftware {
    param (
        [PSCustomObject]$commandObj,
        [System.IO.StreamWriter]$writer
    )
    
    try {
        Write-Host "Obteniendo lista de software instalado..."
        
        
        $software = @()
        $registryPaths = @(
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )
        
        foreach ($path in $registryPaths) {
            Get-ItemProperty $path -ErrorAction SilentlyContinue | 
            Where-Object { $_.DisplayName } | 
            ForEach-Object {
                $software += [PSCustomObject]@{
                    Name        = $_.DisplayName
                    Version     = $_.DisplayVersion
                    Vendor      = $_.Publisher
                    InstallDate = $_.InstallDate
                }
            }
        }
        
        Write-Host "Encontrados $($software.Count) aplicaciones"
        
        $response = @{ 
            success  = $true
            software = $software
        } | ConvertTo-Json -Depth 10 -Compress
    }
    catch {
        $response = @{ 
            success = $false
            message = $_.Exception.Message 
        } | ConvertTo-Json -Compress
    }
    
    Write-Host "Enviando lista de software"
    $writer.WriteLine($response)
    $writer.Flush()
}

function Handle-UninstallSoftware {
    param (
        [PSCustomObject]$commandObj,
        [System.IO.StreamWriter]$writer
    )
    
    $softwareName = $commandObj.params[0]
    
    try {
        Write-Host "Desinstalando software: $softwareName"
        
        
        $uninstallString = $null
        $registryPaths = @(
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )
        
        foreach ($path in $registryPaths) {
            $app = Get-ItemProperty $path -ErrorAction SilentlyContinue | 
            Where-Object { $_.DisplayName -eq $softwareName } | 
            Select-Object -First 1
            
            if ($app) {
                $uninstallString = $app.UninstallString
                break
            }
        }
        
        if ($uninstallString) {
            Write-Host "Ejecutando: $uninstallString"
            
            
            if ($uninstallString -match 'msiexec') {
                
                $guid = $uninstallString -replace '.*\{([^}]+)\}.*', '{$1}'
                $process = Start-Process -FilePath "msiexec.exe" `
                    -ArgumentList "/x `"$guid`" /quiet /norestart" `
                    -Wait -PassThru -NoNewWindow
            }
            else {
                
                $process = Start-Process -FilePath "cmd.exe" `
                    -ArgumentList "/c `"$uninstallString`" /S /silent /quiet" `
                    -Wait -PassThru -NoNewWindow
            }
            
            if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
                $response = @{
                    success = $true
                    message = "Software desinstalado correctamente"
                } | ConvertTo-Json -Compress
            }
            else {
                $response = @{
                    success = $false
                    message = "Código de salida: $($process.ExitCode)"
                } | ConvertTo-Json -Compress
            }
        }
        else {
            $response = @{
                success = $false
                message = "No se encontró información de desinstalación para: $softwareName"
            } | ConvertTo-Json -Compress
        }
    }
    catch {
        $response = @{
            success = $false
            message = $_.Exception.Message
        } | ConvertTo-Json -Compress
    }
    
    Write-Host "Enviando resultado de desinstalación"
    $writer.WriteLine($response)
    $writer.Flush()
}

function Handle-UploadInstaller {
    param (
        [PSCustomObject]$commandObj,
        [System.IO.StreamWriter]$writer
    )
    
    $fileName = $commandObj.params[0]
    $fileData = $commandObj.params[1]
    
    try {
        Write-Host "Recibiendo instalador: $fileName"
        
        $tempPath = "C:\Temp"
        if (-not (Test-Path $tempPath)) {
            New-Item -ItemType Directory -Path $tempPath -Force | Out-Null
        }
        
        $filePath = Join-Path $tempPath $fileName
        $bytes = [Convert]::FromBase64String($fileData)
        [System.IO.File]::WriteAllBytes($filePath, $bytes)
        
        $response = @{
            Success  = $true
            Message  = "Archivo subido correctamente"
            FilePath = $filePath
        } | ConvertTo-Json -Compress
    }
    catch {
        $response = @{
            Success = $false
            Error   = $_.Exception.Message
        } | ConvertTo-Json -Compress
    }
    
    Write-Host "Enviando confirmación de subida"
    $writer.WriteLine($response)
    $writer.Flush()
}

function Handle-InstallSoftware {
    param (
        [PSCustomObject]$commandObj,
        [System.IO.StreamWriter]$writer
    )
    
    $fileName = $commandObj.params[0]
    
    try {
        Write-Host "Instalando software: $fileName"
        $installer = "C:\Temp\$fileName"
        
        if (Test-Path $installer) {
            if ($installer -like "*.msi") {
                $process = Start-Process -FilePath "msiexec.exe" `
                    -ArgumentList "/i `"$installer`" /quiet /norestart" `
                    -Wait -PassThru
            }
            else {
                $process = Start-Process -FilePath $installer `
                    -ArgumentList "/S /silent /quiet" `
                    -Wait -PassThru
            }
            
            
            Remove-Item $installer -Force -ErrorAction SilentlyContinue
            
            $response = @{
                Success  = $true
                Message  = "Instalación completada"
                ExitCode = $process.ExitCode
            } | ConvertTo-Json -Compress
        }
        else {
            $response = @{
                Success = $false
                Error   = "Instalador no encontrado"
            } | ConvertTo-Json -Compress
        }
    }
    catch {
        $response = @{
            Success = $false
            Error   = $_.Exception.Message
        } | ConvertTo-Json -Compress
    }
    
    Write-Host "Enviando resultado de instalación"
    $writer.WriteLine($response)
    $writer.Flush()
}

function Process-Command {
    param (
        [string]$encodedCommand,
        [System.IO.StreamWriter]$writer
    )
    
    try {
        $json = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encodedCommand))
        Write-Host "JSON recibido: $json"
        

        $commandObj = $json | ConvertFrom-Json
    }
    catch {
        $response = @{ success = $false; message = 'Error decoding command' } | ConvertTo-Json -Compress
        Write-Host "Error: $($_.Exception.Message)"
        $writer.WriteLine($response)
        return
    }
    
    $action = $commandObj.action
    Write-Host "Acción recibida: '$action'"

    switch ($action) {
        "EXECUTE_COMMAND" { Handle-ExecuteCommand -commandObj $commandObj -writer $writer }
        "UPLOAD_FILE" { Handle-UploadFile -commandObj $commandObj -writer $writer }
        "LIST_FILES" { Handle-ListFiles -commandObj $commandObj -writer $writer }
        "DELETE_FILE" { Handle-DeleteFile -commandObj $commandObj -writer $writer }
        "COPY_FILE" { Handle-CopyFile -commandObj $commandObj -writer $writer }
        "MOVE_FILE" { Handle-MoveFile -commandObj $commandObj -writer $writer }
        "DOWNLOAD_FILE" { Handle-DownloadFile -commandObj $commandObj -writer $writer }
        "GET_PROCESSES" { Handle-GetProcesses -commandObj $commandObj -writer $writer }
        "GET_SERVICES" { Handle-GetServices -commandObj $commandObj -writer $writer }
        "TERMINATE_PROCESS" { Handle-TerminateProcess -commandObj $commandObj -writer $writer }
        "START_SERVICE" { Handle-StartService -commandObj $commandObj -writer $writer }
        "STOP_SERVICE" { Handle-StopService -commandObj $commandObj -writer $writer }
        "RESTART_SERVICE" { Handle-RestartService -commandObj $commandObj -writer $writer }
        "IS_DIRECTORY" { Handle-IsDirectory -commandObj $commandObj -writer $writer }
        "GET_SYSTEM_INFO" { Handle-GetSystemInfo -commandObj $commandObj -writer $writer }
        "GET_EVENT_LOG" { Handle-GetEventLog -commandObj $commandObj -writer $writer }
        "GetSoftware" { Handle-GetSoftware -commandObj $commandObj -writer $writer }
        "UninstallSoftware" { Handle-UninstallSoftware -commandObj $commandObj -writer $writer }
        "UploadInstaller" { Handle-UploadInstaller -commandObj $commandObj -writer $writer }
        "InstallSoftware" { Handle-InstallSoftware -commandObj $commandObj -writer $writer }
        default {
            $response = @{ success = $false; message = 'Comando no reconocido' } | ConvertTo-Json -Compress
            Write-Host "Comando no reconocido: $action"
            $writer.WriteLine($response)
        }
    }
}

Export-ModuleMember -Function Process-Command

