# Visor de Logs con Interfaz Gráfica
# Uso: .\Ver-Logs-GUI.ps1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Import-Module -Name ".\Modules\SessionLogger.psm1" -Force

$logsDirectory = Join-Path $PSScriptRoot 'Logs'

# === FORMULARIO PRINCIPAL ===
$form = New-Object System.Windows.Forms.Form
$form.Text = "📊 Visor de Logs de Sesiones Remotas"
$form.Size = New-Object System.Drawing.Size(1200, 700)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# === PANEL SUPERIOR - FILTROS ===
$panelFiltros = New-Object System.Windows.Forms.Panel
$panelFiltros.Location = New-Object System.Drawing.Point(10, 10)
$panelFiltros.Size = New-Object System.Drawing.Size(1160, 80)
$panelFiltros.BorderStyle = "FixedSingle"
$form.Controls.Add($panelFiltros)

# Label título filtros
$lblFiltros = New-Object System.Windows.Forms.Label
$lblFiltros.Text = "🔍 Filtros de Búsqueda"
$lblFiltros.Location = New-Object System.Drawing.Point(10, 5)
$lblFiltros.Size = New-Object System.Drawing.Size(200, 20)
$lblFiltros.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$panelFiltros.Controls.Add($lblFiltros)

# Filtro por Servidor
$lblServidor = New-Object System.Windows.Forms.Label
$lblServidor.Text = "Servidor IP:"
$lblServidor.Location = New-Object System.Drawing.Point(10, 35)
$lblServidor.Size = New-Object System.Drawing.Size(80, 20)
$panelFiltros.Controls.Add($lblServidor)

$txtServidor = New-Object System.Windows.Forms.TextBox
$txtServidor.Location = New-Object System.Drawing.Point(95, 32)
$txtServidor.Size = New-Object System.Drawing.Size(150, 20)
$txtServidor.Text = "*"
$panelFiltros.Controls.Add($txtServidor)

# Filtro por Días
$lblDias = New-Object System.Windows.Forms.Label
$lblDias.Text = "Últimos días:"
$lblDias.Location = New-Object System.Drawing.Point(260, 35)
$lblDias.Size = New-Object System.Drawing.Size(80, 20)
$panelFiltros.Controls.Add($lblDias)

$numDias = New-Object System.Windows.Forms.NumericUpDown
$numDias.Location = New-Object System.Drawing.Point(345, 32)
$numDias.Size = New-Object System.Drawing.Size(60, 20)
$numDias.Minimum = 1
$numDias.Maximum = 365
$numDias.Value = 7
$panelFiltros.Controls.Add($numDias)

# Filtro por Búsqueda
$lblBuscar = New-Object System.Windows.Forms.Label
$lblBuscar.Text = "Buscar texto:"
$lblBuscar.Location = New-Object System.Drawing.Point(420, 35)
$lblBuscar.Size = New-Object System.Drawing.Size(80, 20)
$panelFiltros.Controls.Add($lblBuscar)

$txtBuscar = New-Object System.Windows.Forms.TextBox
$txtBuscar.Location = New-Object System.Drawing.Point(505, 32)
$txtBuscar.Size = New-Object System.Drawing.Size(200, 20)
$panelFiltros.Controls.Add($txtBuscar)

$lblTipoLog = New-Object System.Windows.Forms.Label
$lblTipoLog.Text = "Tipo log:"
$lblTipoLog.Location = New-Object System.Drawing.Point(720, 35)
$lblTipoLog.Size = New-Object System.Drawing.Size(60, 20)
$panelFiltros.Controls.Add($lblTipoLog)

$comboLogType = New-Object System.Windows.Forms.ComboBox
$comboLogType.Location = New-Object System.Drawing.Point(785, 32)
$comboLogType.Size = New-Object System.Drawing.Size(120, 20)
$comboLogType.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$comboLogType.Items.AddRange(@("Sesiones", "Inventario", "Errores"))
$comboLogType.SelectedIndex = 0
$panelFiltros.Controls.Add($comboLogType)

$btnBuscar = New-Object System.Windows.Forms.Button
$btnBuscar.Text = "🔍 Buscar"
$btnBuscar.Location = New-Object System.Drawing.Point(915, 30)
$btnBuscar.Size = New-Object System.Drawing.Size(100, 25)
$btnBuscar.BackColor = [System.Drawing.Color]::LightBlue
$panelFiltros.Controls.Add($btnBuscar)

$btnActualizar = New-Object System.Windows.Forms.Button
$btnActualizar.Text = "🔄 Actualizar"
$btnActualizar.Location = New-Object System.Drawing.Point(1025, 30)
$btnActualizar.Size = New-Object System.Drawing.Size(100, 25)
$btnActualizar.BackColor = [System.Drawing.Color]::LightGreen
$panelFiltros.Controls.Add($btnActualizar)

$btnReporte = New-Object System.Windows.Forms.Button
$btnReporte.Text = "📄 Reporte HTML"
$btnReporte.Location = New-Object System.Drawing.Point(940, 5)
$btnReporte.Size = New-Object System.Drawing.Size(120, 25)
$btnReporte.BackColor = [System.Drawing.Color]::LightCoral
$panelFiltros.Controls.Add($btnReporte)

# === LISTA DE SESIONES ===
$lblSesiones = New-Object System.Windows.Forms.Label
$lblSesiones.Text = "📋 Lista de Sesiones"
$lblSesiones.Location = New-Object System.Drawing.Point(10, 100)
$lblSesiones.Size = New-Object System.Drawing.Size(200, 20)
$lblSesiones.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($lblSesiones)

$listViewSesiones = New-Object System.Windows.Forms.ListView
$listViewSesiones.Location = New-Object System.Drawing.Point(10, 125)
$listViewSesiones.Size = New-Object System.Drawing.Size(560, 480)
$listViewSesiones.View = "Details"
$listViewSesiones.FullRowSelect = $true
$listViewSesiones.GridLines = $true
$listViewSesiones.MultiSelect = $false

# Columnas
$listViewSesiones.Columns.Add("Fecha/Hora", 140) | Out-Null
$listViewSesiones.Columns.Add("Servidor", 120) | Out-Null
$listViewSesiones.Columns.Add("Session ID", 90) | Out-Null
$listViewSesiones.Columns.Add("Tamaño", 80) | Out-Null
$listViewSesiones.Columns.Add("Duración", 100) | Out-Null

$form.Controls.Add($listViewSesiones)

# === PANEL DE DETALLES ===
$lblDetalles = New-Object System.Windows.Forms.Label
$lblDetalles.Text = "📄 Contenido del Log"
$lblDetalles.Location = New-Object System.Drawing.Point(580, 100)
$lblDetalles.Size = New-Object System.Drawing.Size(200, 20)
$lblDetalles.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($lblDetalles)

$txtDetalles = New-Object System.Windows.Forms.RichTextBox
$txtDetalles.Location = New-Object System.Drawing.Point(580, 125)
$txtDetalles.Size = New-Object System.Drawing.Size(590, 430)
$txtDetalles.Font = New-Object System.Drawing.Font("Consolas", 9)
$txtDetalles.ReadOnly = $true
$txtDetalles.BackColor = [System.Drawing.Color]::Black
$txtDetalles.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($txtDetalles)

# === PANEL DE ESTADÍSTICAS ===
$panelStats = New-Object System.Windows.Forms.Panel
$panelStats.Location = New-Object System.Drawing.Point(580, 565)
$panelStats.Size = New-Object System.Drawing.Size(590, 40)
$panelStats.BorderStyle = "FixedSingle"
$form.Controls.Add($panelStats)

$lblStats = New-Object System.Windows.Forms.Label
$lblStats.Location = New-Object System.Drawing.Point(10, 10)
$lblStats.Size = New-Object System.Drawing.Size(570, 20)
$lblStats.Text = "📊 Estadísticas: Cargando..."
$panelStats.Controls.Add($lblStats)

# === BARRA DE ESTADO ===
$statusBar = New-Object System.Windows.Forms.StatusStrip
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text = "Listo"
$statusBar.Items.Add($statusLabel) | Out-Null
$form.Controls.Add($statusBar)

# === FUNCIONES ===
function Load-Sessions {
    param (
        [string]$ServerIP = "*",
        [int]$Days = 7
    )
    
    $statusLabel.Text = "Cargando sesiones..."
    $listViewSesiones.Items.Clear()
    
    try {
        $sessions = Get-SessionHistory -Last 1000 -ServerIP $ServerIP |
        Where-Object { $_.DateTime -gt (Get-Date).AddDays(-$Days) } |
        Sort-Object DateTime -Descending
        
        foreach ($session in $sessions) {
            $item = New-Object System.Windows.Forms.ListViewItem($session.DateTime.ToString("yyyy-MM-dd HH:mm:ss"))
            $item.SubItems.Add($session.ServerIP) | Out-Null
            $item.SubItems.Add($session.SessionID) | Out-Null
            $item.SubItems.Add("$([math]::Round($session.Size / 1KB, 2)) KB") | Out-Null
            
            # Intentar obtener duración del log
            $duration = "N/A"
            try {
                $content = Get-Content $session.LogFile -Encoding UTF8 | Select-String "Duración:"
                if ($content) {
                    $duration = ($content -split "Duración:")[1].Trim()
                }
            }
            catch { }
            
            $item.SubItems.Add($duration) | Out-Null
            $item.Tag = $session.LogFile
            
            $listViewSesiones.Items.Add($item) | Out-Null
        }
        
        # Actualizar estadísticas
        $totalSessions = $sessions.Count
        $uniqueServers = ($sessions | Select-Object -Unique ServerIP).Count
        $totalSize = ($sessions | Measure-Object -Property Size -Sum).Sum
        
        $lblStats.Text = "📊 Total: $totalSessions sesiones | Servidores: $uniqueServers | Tamaño total: $([math]::Round($totalSize / 1MB, 2)) MB"
        $statusLabel.Text = "Listo - $totalSessions sesiones cargadas"
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error al cargar sesiones: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        $statusLabel.Text = "Error al cargar sesiones"
    }
}

function Load-InventoryLogs {
    param (
        [int]$Days = 7
    )
    
    $statusLabel.Text = "Cargando logs de inventario..."
    $listViewSesiones.Items.Clear()
    
    try {
        if (-not (Test-Path $logsDirectory)) {
            $lblStats.Text = "No se encontró el directorio de logs: $logsDirectory"
            $statusLabel.Text = "Sin logs de inventario"
            return
        }
        
        $files = Get-ChildItem -Path $logsDirectory -Filter 'Inventory_*.log' -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-$Days) } |
        Sort-Object LastWriteTime -Descending
        
        foreach ($file in $files) {
            $dateTime = $file.LastWriteTime
            if ($file.Name -match 'Inventory_(\d{8}).log') {
                try {
                    $dateTime = [DateTime]::ParseExact($matches[1], 'yyyyMMdd', $null)
                }
                catch { }
            }
            $item = New-Object System.Windows.Forms.ListViewItem($dateTime.ToString('yyyy-MM-dd HH:mm:ss'))
            $item.SubItems.Add('-') | Out-Null
            $item.SubItems.Add($file.Name) | Out-Null
            $item.SubItems.Add("$([math]::Round($file.Length / 1KB, 2)) KB") | Out-Null
            $item.SubItems.Add('N/A') | Out-Null
            $item.Tag = $file.FullName
            $listViewSesiones.Items.Add($item) | Out-Null
        }
        
        $totalLogs = $files.Count
        $totalSize = ($files | Measure-Object -Property Length -Sum).Sum
        $lblStats.Text = "📊 Total: $totalLogs logs de inventario | Tamaño total: $([math]::Round($totalSize / 1MB, 2)) MB"
        $statusLabel.Text = "Listo - $totalLogs logs de inventario cargados"
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error al cargar logs de inventario: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        $statusLabel.Text = "Error al cargar logs de inventario"
    }
}

function Load-ErrorLogs {
    param (
        [string]$ServerIP = "*",
        [int]$Days = 7
    )
    
    $statusLabel.Text = "Cargando logs de errores..."
    $listViewSesiones.Items.Clear()
    
    try {
        if (-not (Test-Path $logsDirectory)) {
            $lblStats.Text = "No se encontró el directorio de logs: $logsDirectory"
            $statusLabel.Text = "Sin logs de errores"
            return
        }
        
        $pattern = if ($ServerIP -and $ServerIP -ne '*') { "Error_${ServerIP}_*.log" } else { 'Error_*.log' }
        $files = Get-ChildItem -Path $logsDirectory -Filter $pattern -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-$Days) } |
        Sort-Object LastWriteTime -Descending
        
        foreach ($file in $files) {
            $server = '-'
            $dateTime = $file.LastWriteTime
            if ($file.Name -match 'Error_(.+)_(\d{8}).log') {
                $server = $matches[1]
                try {
                    $dateTime = [DateTime]::ParseExact($matches[2], 'yyyyMMdd', $null)
                }
                catch { }
            }
            $item = New-Object System.Windows.Forms.ListViewItem($dateTime.ToString('yyyy-MM-dd HH:mm:ss'))
            $item.SubItems.Add($server) | Out-Null
            $item.SubItems.Add($file.Name) | Out-Null
            $item.SubItems.Add("$([math]::Round($file.Length / 1KB, 2)) KB") | Out-Null
            $item.SubItems.Add('N/A') | Out-Null
            $item.Tag = $file.FullName
            $listViewSesiones.Items.Add($item) | Out-Null
        }
        
        $totalLogs = $files.Count
        $uniqueServers = ($files | ForEach-Object {
                if ($_.Name -match 'Error_(.+)_(\d{8}).log') { $matches[1] } else { $null }
            } | Where-Object { $_ } | Select-Object -Unique).Count
        $totalSize = ($files | Measure-Object -Property Length -Sum).Sum
        $lblStats.Text = "📊 Total: $totalLogs logs de error | Servidores: $uniqueServers | Tamaño total: $([math]::Round($totalSize / 1MB, 2)) MB"
        $statusLabel.Text = "Listo - $totalLogs logs de error cargados"
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error al cargar logs de error: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        $statusLabel.Text = "Error al cargar logs de error"
    }
}

function Load-Logs {
    param (
        [string]$LogType,
        [string]$ServerIP = "*",
        [int]$Days = 7
    )
    
    switch ($LogType) {
        'Sesiones' { Load-Sessions -ServerIP $ServerIP -Days $Days }
        'Inventario' { Load-InventoryLogs -Days $Days }
        'Errores' { Load-ErrorLogs -ServerIP $ServerIP -Days $Days }
        default { Load-Sessions -ServerIP $ServerIP -Days $Days }
    }
}

function Show-LogContent {
    param ([string]$LogFile)
    
    $txtDetalles.Clear()
    
    if (-not (Test-Path $LogFile)) {
        $txtDetalles.Text = "Archivo de log no encontrado."
        return
    }
    
    $statusLabel.Text = "Cargando contenido del log..."
    
    try {
        $content = Get-Content -Path $LogFile -Encoding UTF8
        
        foreach ($line in $content) {
            # Colorear según el nivel
            if ($line -match "\[ERROR\]") {
                $txtDetalles.SelectionColor = [System.Drawing.Color]::Red
            }
            elseif ($line -match "\[WARNING\]") {
                $txtDetalles.SelectionColor = [System.Drawing.Color]::Yellow
            }
            elseif ($line -match "\[SUCCESS\]") {
                $txtDetalles.SelectionColor = [System.Drawing.Color]::LimeGreen
            }
            elseif ($line -match "\[COMMAND\]") {
                $txtDetalles.SelectionColor = [System.Drawing.Color]::Cyan
            }
            elseif ($line -match "\[FILE\]") {
                $txtDetalles.SelectionColor = [System.Drawing.Color]::Magenta
            }
            elseif ($line -match "\[PROCESS\]") {
                $txtDetalles.SelectionColor = [System.Drawing.Color]::LightBlue
            }
            elseif ($line -match "\[SERVICE\]") {
                $txtDetalles.SelectionColor = [System.Drawing.Color]::DarkCyan
            }
            elseif ($line -match "^=+$") {
                $txtDetalles.SelectionColor = [System.Drawing.Color]::Cyan
            }
            else {
                $txtDetalles.SelectionColor = [System.Drawing.Color]::White
            }
            
            $txtDetalles.AppendText("$line`n")
        }
        
        $statusLabel.Text = "Log cargado - $($content.Count) líneas"
    }
    catch {
        $txtDetalles.Text = "Error al cargar el log: $($_.Exception.Message)"
        $statusLabel.Text = "Error al cargar log"
    }
}

function Search-InLogs {
    param ([string]$SearchTerm)
    
    if ([string]::IsNullOrWhiteSpace($SearchTerm)) {
        [System.Windows.Forms.MessageBox]::Show("Por favor ingrese un término de búsqueda.", "Búsqueda", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }
    
    if ($comboLogType.SelectedItem -ne 'Sesiones') {
        [System.Windows.Forms.MessageBox]::Show("La búsqueda solo está disponible en logs de sesión.", "Búsqueda", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }
    
    $statusLabel.Text = "Buscando '$SearchTerm'..."
    $txtDetalles.Clear()
    
    $sessions = Get-SessionHistory -Last 1000
    $found = 0
    
    foreach ($session in $sessions) {
        try {
            $matches = Get-Content -Path $session.LogFile -Encoding UTF8 | Select-String -Pattern $SearchTerm
            
            if ($matches) {
                $found++
                $txtDetalles.SelectionColor = [System.Drawing.Color]::Yellow
                $txtDetalles.AppendText("`n========================================`n")
                $txtDetalles.SelectionColor = [System.Drawing.Color]::Cyan
                $txtDetalles.AppendText("📁 Sesión: $($session.SessionID) - $($session.DateTime.ToString('yyyy-MM-dd HH:mm:ss'))`n")
                $txtDetalles.SelectionColor = [System.Drawing.Color]::Gray
                $txtDetalles.AppendText("   Servidor: $($session.ServerIP)`n")
                $txtDetalles.SelectionColor = [System.Drawing.Color]::Yellow
                $txtDetalles.AppendText("========================================`n")
                
                foreach ($match in $matches) {
                    $txtDetalles.SelectionColor = [System.Drawing.Color]::White
                    $txtDetalles.AppendText("$($match.Line)`n")
                }
            }
        }
        catch { }
    }
    
    if ($found -eq 0) {
        $txtDetalles.SelectionColor = [System.Drawing.Color]::Yellow
        $txtDetalles.AppendText("No se encontraron resultados para: '$SearchTerm'")
    }
    
    $statusLabel.Text = "Búsqueda completada - $found coincidencias encontradas"
}

# === EVENTOS ===
$listViewSesiones.Add_SelectedIndexChanged({
        if ($listViewSesiones.SelectedItems.Count -gt 0) {
            $selectedItem = $listViewSesiones.SelectedItems[0]
            $logFile = $selectedItem.Tag
            Show-LogContent -LogFile $logFile
        }
    })

$btnActualizar.Add_Click({
        Load-Logs -LogType $comboLogType.SelectedItem -ServerIP $txtServidor.Text -Days $numDias.Value
    })

$btnBuscar.Add_Click({
        Search-InLogs -SearchTerm $txtBuscar.Text
    })

$btnReporte.Add_Click({
        $statusLabel.Text = "Generando reporte HTML..."
    
        try {
            $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
            $saveDialog.Filter = "HTML Files (*.html)|*.html"
            $saveDialog.FileName = "SessionReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
        
            if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $reportPath = Export-SessionReport -OutputPath $saveDialog.FileName -Days $numDias.Value
            
                [System.Windows.Forms.MessageBox]::Show("Reporte generado exitosamente en:`n$reportPath", "Reporte HTML", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            
                $result = [System.Windows.Forms.MessageBox]::Show("¿Desea abrir el reporte?", "Abrir Reporte", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
            
                if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                    Start-Process $reportPath
                }
            
                $statusLabel.Text = "Reporte generado exitosamente"
            }
            else {
                $statusLabel.Text = "Generación de reporte cancelada"
            }
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Error al generar reporte: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            $statusLabel.Text = "Error al generar reporte"
        }
    })

$txtBuscar.Add_KeyDown({
        param($sender, $e)
        if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
            $btnBuscar.PerformClick()
        }
    })

Load-Logs -LogType $comboLogType.SelectedItem -ServerIP "*" -Days 7

# Mostrar formulario
$form.ShowDialog() | Out-Null
