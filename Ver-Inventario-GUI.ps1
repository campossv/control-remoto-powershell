


Import-Module "$PSScriptRoot\Modules\DatabaseManager.psm1" -Force

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing


$form = New-Object System.Windows.Forms.Form
$form.Text = "Inventario de Servidores"
$form.Size = New-Object System.Drawing.Size(1200, 700)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::White


$panelServers = New-Object System.Windows.Forms.Panel
$panelServers.Location = New-Object System.Drawing.Point(10, 10)
$panelServers.Size = New-Object System.Drawing.Size(1160, 200)
$panelServers.BorderStyle = "FixedSingle"

$lblServers = New-Object System.Windows.Forms.Label
$lblServers.Text = "Servidores Registrados:"
$lblServers.Location = New-Object System.Drawing.Point(5, 5)
$lblServers.Size = New-Object System.Drawing.Size(200, 20)
$lblServers.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$panelServers.Controls.Add($lblServers)

$dgvServers = New-Object System.Windows.Forms.DataGridView
$dgvServers.Location = New-Object System.Drawing.Point(5, 30)
$dgvServers.Size = New-Object System.Drawing.Size(1145, 160)
$dgvServers.AllowUserToAddRows = $false
$dgvServers.AllowUserToDeleteRows = $false
$dgvServers.ReadOnly = $true
$dgvServers.SelectionMode = "FullRowSelect"
$dgvServers.MultiSelect = $false
$dgvServers.AutoSizeColumnsMode = "Fill"
$dgvServers.BackgroundColor = [System.Drawing.Color]::White
$panelServers.Controls.Add($dgvServers)

$form.Controls.Add($panelServers)


$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Location = New-Object System.Drawing.Point(10, 220)
$tabControl.Size = New-Object System.Drawing.Size(1160, 400)


$tabHardware = New-Object System.Windows.Forms.TabPage
$tabHardware.Text = "Hardware"
$tabHardware.BackColor = [System.Drawing.Color]::White

$dgvHardware = New-Object System.Windows.Forms.DataGridView
$dgvHardware.Location = New-Object System.Drawing.Point(5, 5)
$dgvHardware.Size = New-Object System.Drawing.Size(1140, 360)
$dgvHardware.AllowUserToAddRows = $false
$dgvHardware.AllowUserToDeleteRows = $false
$dgvHardware.ReadOnly = $true
$dgvHardware.AutoSizeColumnsMode = "Fill"
$dgvHardware.BackgroundColor = [System.Drawing.Color]::White
$tabHardware.Controls.Add($dgvHardware)


$tabSoftware = New-Object System.Windows.Forms.TabPage
$tabSoftware.Text = "Software"
$tabSoftware.BackColor = [System.Drawing.Color]::White


$dgvSoftware = New-Object System.Windows.Forms.DataGridView
$dgvSoftware.Location = New-Object System.Drawing.Point(5, 5)
$dgvSoftware.Size = New-Object System.Drawing.Size(1140, 360)
$dgvSoftware.AllowUserToAddRows = $false
$dgvSoftware.AllowUserToDeleteRows = $false
$dgvSoftware.ReadOnly = $true
$dgvSoftware.SelectionMode = "FullRowSelect"
$dgvSoftware.MultiSelect = $false
$dgvSoftware.AutoSizeColumnsMode = "Fill"
$dgvSoftware.BackgroundColor = [System.Drawing.Color]::White
$tabSoftware.Controls.Add($dgvSoftware)


$tabSearchSoftware = New-Object System.Windows.Forms.TabPage
$tabSearchSoftware.Text = "Búsqueda Software"
$tabSearchSoftware.BackColor = [System.Drawing.Color]::White


$panelSearch = New-Object System.Windows.Forms.Panel
$panelSearch.Location = New-Object System.Drawing.Point(5, 5)
$panelSearch.Size = New-Object System.Drawing.Size(1140, 80)
$panelSearch.BorderStyle = "FixedSingle"
$panelSearch.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)
$tabSearchSoftware.Controls.Add($panelSearch)

$lblSearchTitle = New-Object System.Windows.Forms.Label
$lblSearchTitle.Text = "🔍 Buscar Software en Todos los Servidores"
$lblSearchTitle.Location = New-Object System.Drawing.Point(10, 10)
$lblSearchTitle.Size = New-Object System.Drawing.Size(400, 25)
$lblSearchTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$lblSearchTitle.ForeColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$panelSearch.Controls.Add($lblSearchTitle)

$lblSearchSoftware = New-Object System.Windows.Forms.Label
$lblSearchSoftware.Text = "Nombre del software:"
$lblSearchSoftware.Location = New-Object System.Drawing.Point(10, 45)
$lblSearchSoftware.Size = New-Object System.Drawing.Size(150, 20)
$panelSearch.Controls.Add($lblSearchSoftware)

$txtSearchSoftware = New-Object System.Windows.Forms.TextBox
$txtSearchSoftware.Location = New-Object System.Drawing.Point(160, 42)
$txtSearchSoftware.Size = New-Object System.Drawing.Size(700, 25)
$txtSearchSoftware.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$panelSearch.Controls.Add($txtSearchSoftware)

$btnSearch = New-Object System.Windows.Forms.Button
$btnSearch.Text = "🔍 Buscar"
$btnSearch.Location = New-Object System.Drawing.Point(870, 40)
$btnSearch.Size = New-Object System.Drawing.Size(120, 30)
$btnSearch.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnSearch.ForeColor = [System.Drawing.Color]::White
$btnSearch.FlatStyle = "Flat"
$btnSearch.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$panelSearch.Controls.Add($btnSearch)

$btnClearSearch = New-Object System.Windows.Forms.Button
$btnClearSearch.Text = "✖ Limpiar"
$btnClearSearch.Location = New-Object System.Drawing.Point(1000, 40)
$btnClearSearch.Size = New-Object System.Drawing.Size(100, 30)
$btnClearSearch.BackColor = [System.Drawing.Color]::FromArgb(108, 117, 125)
$btnClearSearch.ForeColor = [System.Drawing.Color]::White
$btnClearSearch.FlatStyle = "Flat"
$panelSearch.Controls.Add($btnClearSearch)


$dgvSearchResults = New-Object System.Windows.Forms.DataGridView
$dgvSearchResults.Location = New-Object System.Drawing.Point(5, 95)
$dgvSearchResults.Size = New-Object System.Drawing.Size(1140, 260)
$dgvSearchResults.AllowUserToAddRows = $false
$dgvSearchResults.AllowUserToDeleteRows = $false
$dgvSearchResults.ReadOnly = $true
$dgvSearchResults.SelectionMode = "FullRowSelect"
$dgvSearchResults.MultiSelect = $false
$dgvSearchResults.AutoSizeColumnsMode = "Fill"
$dgvSearchResults.BackgroundColor = [System.Drawing.Color]::White
$tabSearchSoftware.Controls.Add($dgvSearchResults)


$lblSearchStatus = New-Object System.Windows.Forms.Label
$lblSearchStatus.Location = New-Object System.Drawing.Point(10, 365)
$lblSearchStatus.Size = New-Object System.Drawing.Size(1120, 20)
$lblSearchStatus.Text = "Ingresa el nombre del software y haz clic en Buscar"
$lblSearchStatus.ForeColor = [System.Drawing.Color]::Gray
$tabSearchSoftware.Controls.Add($lblSearchStatus)

$tabControl.TabPages.Add($tabHardware)
$tabControl.TabPages.Add($tabSoftware)
$tabControl.TabPages.Add($tabSearchSoftware)
$form.Controls.Add($tabControl)


$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Text = "🔄 Actualizar"
$btnRefresh.Location = New-Object System.Drawing.Point(10, 630)
$btnRefresh.Size = New-Object System.Drawing.Size(120, 30)
$btnRefresh.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnRefresh.ForeColor = [System.Drawing.Color]::White
$btnRefresh.FlatStyle = "Flat"
$form.Controls.Add($btnRefresh)

$btnExport = New-Object System.Windows.Forms.Button
$btnExport.Text = "📊 Exportar CSV"
$btnExport.Location = New-Object System.Drawing.Point(140, 630)
$btnExport.Size = New-Object System.Drawing.Size(120, 30)
$btnExport.BackColor = [System.Drawing.Color]::FromArgb(16, 124, 16)
$btnExport.ForeColor = [System.Drawing.Color]::White
$btnExport.FlatStyle = "Flat"
$form.Controls.Add($btnExport)

$btnEdit = New-Object System.Windows.Forms.Button
$btnEdit.Text = "✏️ Editar"
$btnEdit.Location = New-Object System.Drawing.Point(270, 630)
$btnEdit.Size = New-Object System.Drawing.Size(120, 30)
$btnEdit.BackColor = [System.Drawing.Color]::FromArgb(255, 140, 0)
$btnEdit.ForeColor = [System.Drawing.Color]::White
$btnEdit.FlatStyle = "Flat"
$form.Controls.Add($btnEdit)

$btnDelete = New-Object System.Windows.Forms.Button
$btnDelete.Text = "🗑️ Eliminar"
$btnDelete.Location = New-Object System.Drawing.Point(400, 630)
$btnDelete.Size = New-Object System.Drawing.Size(120, 30)
$btnDelete.BackColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
$btnDelete.ForeColor = [System.Drawing.Color]::White
$btnDelete.FlatStyle = "Flat"
$form.Controls.Add($btnDelete)

$btnChangeStatus = New-Object System.Windows.Forms.Button
$btnChangeStatus.Text = "🔄 Cambiar Estado"
$btnChangeStatus.Location = New-Object System.Drawing.Point(530, 630)
$btnChangeStatus.Size = New-Object System.Drawing.Size(140, 30)
$btnChangeStatus.BackColor = [System.Drawing.Color]::FromArgb(108, 117, 125)
$btnChangeStatus.ForeColor = [System.Drawing.Color]::White
$btnChangeStatus.FlatStyle = "Flat"
$form.Controls.Add($btnChangeStatus)

$btnManageTags = New-Object System.Windows.Forms.Button
$btnManageTags.Text = "🏷️ Etiquetas"
$btnManageTags.Location = New-Object System.Drawing.Point(680, 630)
$btnManageTags.Size = New-Object System.Drawing.Size(120, 30)
$btnManageTags.BackColor = [System.Drawing.Color]::FromArgb(102, 16, 242)
$btnManageTags.ForeColor = [System.Drawing.Color]::White
$btnManageTags.FlatStyle = "Flat"
$form.Controls.Add($btnManageTags)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Location = New-Object System.Drawing.Point(810, 635)
$lblStatus.Size = New-Object System.Drawing.Size(360, 20)
$lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblStatus.ForeColor = [System.Drawing.Color]::Gray
$form.Controls.Add($lblStatus)


function Update-ServerStatus {
    
    try {
        $dbPath = Join-Path $PSScriptRoot "Database\RemoteAdmin.db"
        $connectionString = "Data Source=$dbPath;Version=3;"
        $connection = New-Object System.Data.SQLite.SQLiteConnection($connectionString)
        $connection.Open()
        
        $command = $connection.CreateCommand()
        $command.CommandText = @"
UPDATE Servers 
SET Status = 'Inactive'
WHERE Status = 'Active' 
AND datetime(LastConnection) < datetime('now', '-1 day')
"@
        $rowsAffected = $command.ExecuteNonQuery()
        $connection.Close()
        
        if ($rowsAffected -gt 0) {
            Write-Verbose "$rowsAffected servidor(es) marcado(s) como inactivo(s)"
        }
    }
    catch {
        Write-Warning "Error al actualizar estados: $_"
    }
}

function Load-Servers {
    try {
        
        #Update-ServerStatus
        
        $servers = Get-Servers
        
        if ($servers) {
            
            $servers.Columns.Add("Tags", [string]) | Out-Null
            
            
            foreach ($row in $servers.Rows) {
                $serverIP = $row["IPAddress"]
                $tags = Get-ServerTags -ServerIP $serverIP
                if ($tags -and $tags.Rows.Count -gt 0) {
                    $tagList = ($tags.Rows | ForEach-Object { $_.TagName }) -join ", "
                    $row["Tags"] = $tagList
                }
                else {
                    $row["Tags"] = ""
                }
            }
            
            $dgvServers.DataSource = $servers
            $dgvServers.Columns["ServerID"].HeaderText = "ID"
            $dgvServers.Columns["ServerID"].Width = 50
            $dgvServers.Columns["IPAddress"].HeaderText = "IP"
            $dgvServers.Columns["IPAddress"].Width = 120
            $dgvServers.Columns["Hostname"].HeaderText = "Hostname"
            $dgvServers.Columns["Hostname"].Width = 150
            $dgvServers.Columns["Description"].HeaderText = "Descripción"
            $dgvServers.Columns["Description"].Width = 200
            $dgvServers.Columns["Tags"].HeaderText = "🏷️ Etiquetas"
            $dgvServers.Columns["Tags"].Width = 150
            $dgvServers.Columns["LastConnection"].HeaderText = "Última Conexión"
            $dgvServers.Columns["LastConnection"].Width = 150
            $dgvServers.Columns["Status"].HeaderText = "Estado"
            $dgvServers.Columns["Status"].Width = 80
            
            
            foreach ($row in $dgvServers.Rows) {
                $status = $row.Cells["Status"].Value
                if ($status -eq "Inactive") {
                    $row.DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(255, 240, 240)
                    $row.DefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(180, 0, 0)
                }
                elseif ($status -eq "Active") {
                    $row.DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(240, 255, 240)
                    $row.DefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(0, 128, 0)
                }
            }
            
            
            if ($dgvServers.Columns["OS"]) { $dgvServers.Columns["OS"].Visible = $false }
            if ($dgvServers.Columns["CertificateThumbprint"]) { $dgvServers.Columns["CertificateThumbprint"].Visible = $false }
            if ($dgvServers.Columns["Notes"]) { $dgvServers.Columns["Notes"].Visible = $false }
            if ($dgvServers.Columns["CreatedDate"]) { $dgvServers.Columns["CreatedDate"].Visible = $false }
            if ($dgvServers.Columns["ModifiedDate"]) { $dgvServers.Columns["ModifiedDate"].Visible = $false }
            
            $lblStatus.Text = "✓ $($servers.Rows.Count) servidor(es) encontrado(s)"
            $lblStatus.ForeColor = [System.Drawing.Color]::Green
        }
        else {
            $lblStatus.Text = "⚠ No hay servidores registrados"
            $lblStatus.ForeColor = [System.Drawing.Color]::Orange
        }
    }
    catch {
        $lblStatus.Text = "✗ Error al cargar servidores: $_"
        $lblStatus.ForeColor = [System.Drawing.Color]::Red
    }
}

function Load-Hardware {
    param([string]$ServerIP)
    
    try {
        $dbPath = Join-Path $PSScriptRoot "Database\RemoteAdmin.db"
        $connectionString = "Data Source=$dbPath;Version=3;"
        $connection = New-Object System.Data.SQLite.SQLiteConnection($connectionString)
        $connection.Open()
        
        $command = $connection.CreateCommand()
        $command.CommandText = @"
SELECT h.ComponentType as 'Tipo', h.Manufacturer as 'Fabricante', 
       h.Model as 'Modelo', h.SerialNumber as 'Serie', 
       h.Capacity as 'Capacidad', h.Speed as 'Velocidad', 
       h.Status as 'Estado', h.LastScan as 'Último Escaneo'
FROM HardwareInventory h
INNER JOIN Servers s ON h.ServerID = s.ServerID
WHERE s.IPAddress = @IP
ORDER BY h.ComponentType, h.Model
"@
        $command.Parameters.AddWithValue("@IP", $ServerIP) | Out-Null
        
        $adapter = New-Object System.Data.SQLite.SQLiteDataAdapter($command)
        $dataSet = New-Object System.Data.DataSet
        $rowCount = $adapter.Fill($dataSet)
        
        $connection.Close()
        
        if ($rowCount -gt 0) {
            $dgvHardware.DataSource = $dataSet.Tables[0]
            $lblStatus.Text = "✓ $rowCount componente(s) de hardware"
            $lblStatus.ForeColor = [System.Drawing.Color]::Green
        }
        else {
            $dgvHardware.DataSource = $null
            $lblStatus.Text = "⚠ No hay hardware registrado para este servidor"
            $lblStatus.ForeColor = [System.Drawing.Color]::Orange
        }
    }
    catch {
        $lblStatus.Text = "✗ Error al cargar hardware: $_"
        $lblStatus.ForeColor = [System.Drawing.Color]::Red
    }
}

function Load-Software {
    param([string]$ServerIP)
    
    try {
        $dbPath = Join-Path $PSScriptRoot "Database\RemoteAdmin.db"
        $connectionString = "Data Source=$dbPath;Version=3;"
        $connection = New-Object System.Data.SQLite.SQLiteConnection($connectionString)
        $connection.Open()
        
        $command = $connection.CreateCommand()
        $command.CommandText = @"
SELECT s.SoftwareName as 'Nombre', s.Version as 'Versión', 
       s.Publisher as 'Fabricante', s.InstallDate as 'Fecha Instalación',
       s.Size as 'Tamaño (KB)', s.LastScan as 'Último Escaneo'
FROM SoftwareInventory s
INNER JOIN Servers sv ON s.ServerID = sv.ServerID
WHERE sv.IPAddress = @IP
ORDER BY s.SoftwareName
"@
        $command.Parameters.AddWithValue("@IP", $ServerIP) | Out-Null
        
        $adapter = New-Object System.Data.SQLite.SQLiteDataAdapter($command)
        $dataSet = New-Object System.Data.DataSet
        $rowCount = $adapter.Fill($dataSet)
        
        $connection.Close()
        
        if ($rowCount -gt 0) {
            $dgvSoftware.DataSource = $dataSet.Tables[0]
            $lblStatus.Text = "✓ $rowCount aplicación(es) instalada(s)"
            $lblStatus.ForeColor = [System.Drawing.Color]::Green
        }
        else {
            $dgvSoftware.DataSource = $null
            $lblStatus.Text = "⚠ No hay software registrado para este servidor"
            $lblStatus.ForeColor = [System.Drawing.Color]::Orange
        }
    }
    catch {
        $lblStatus.Text = "✗ Error al cargar software: $_"
        $lblStatus.ForeColor = [System.Drawing.Color]::Red
    }
}

function Edit-Server {
    param([int]$ServerID)
    
    try {
        $dbPath = Join-Path $PSScriptRoot "Database\RemoteAdmin.db"
        $connectionString = "Data Source=$dbPath;Version=3;"
        $connection = New-Object System.Data.SQLite.SQLiteConnection($connectionString)
        $connection.Open()
        
        $command = $connection.CreateCommand()
        $command.CommandText = "SELECT * FROM Servers WHERE ServerID = @ID"
        $command.Parameters.AddWithValue("@ID", $ServerID) | Out-Null
        $reader = $command.ExecuteReader()
        
        if ($reader.Read()) {
            $currentHostname = $reader["Hostname"]
            $currentDesc = $reader["Description"]
            $currentOS = $reader["OS"]
            $currentCert = $reader["CertificateThumbprint"]
            $currentNotes = $reader["Notes"]
            $reader.Close()
            
            
            $editForm = New-Object System.Windows.Forms.Form
            $editForm.Text = "Editar Servidor"
            $editForm.Size = New-Object System.Drawing.Size(500, 420)
            $editForm.StartPosition = "CenterParent"
            $editForm.FormBorderStyle = "FixedDialog"
            $editForm.MaximizeBox = $false
            $editForm.BackColor = [System.Drawing.Color]::White
            
            $yPos = 15
            
            
            $lblHostname = New-Object System.Windows.Forms.Label
            $lblHostname.Text = "Hostname:"
            $lblHostname.Location = New-Object System.Drawing.Point(15, $yPos)
            $lblHostname.Size = New-Object System.Drawing.Size(100, 20)
            $lblHostname.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
            $editForm.Controls.Add($lblHostname)
            
            $txtHostname = New-Object System.Windows.Forms.TextBox
            $txtHostname.Location = New-Object System.Drawing.Point(120, $yPos)
            $txtHostname.Size = New-Object System.Drawing.Size(350, 20)
            $txtHostname.Text = $currentHostname
            $editForm.Controls.Add($txtHostname)
            
            $yPos += 35
            
            
            $lblOS = New-Object System.Windows.Forms.Label
            $lblOS.Text = "Sistema Operativo:"
            $lblOS.Location = New-Object System.Drawing.Point(15, $yPos)
            $lblOS.Size = New-Object System.Drawing.Size(100, 20)
            $lblOS.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
            $editForm.Controls.Add($lblOS)
            
            $txtOS = New-Object System.Windows.Forms.TextBox
            $txtOS.Location = New-Object System.Drawing.Point(120, $yPos)
            $txtOS.Size = New-Object System.Drawing.Size(350, 20)
            if ([string]::IsNullOrWhiteSpace($currentOS)) {
                $txtOS.Text = ""
                $txtOS.ForeColor = [System.Drawing.Color]::Gray
            }
            else {
                $txtOS.Text = $currentOS
            }
            $editForm.Controls.Add($txtOS)
            
            $yPos += 35
            
            
            $lblDesc = New-Object System.Windows.Forms.Label
            $lblDesc.Text = "Descripción:"
            $lblDesc.Location = New-Object System.Drawing.Point(15, $yPos)
            $lblDesc.Size = New-Object System.Drawing.Size(100, 20)
            $lblDesc.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
            $editForm.Controls.Add($lblDesc)
            
            $txtDesc = New-Object System.Windows.Forms.TextBox
            $txtDesc.Location = New-Object System.Drawing.Point(120, $yPos)
            $txtDesc.Size = New-Object System.Drawing.Size(350, 50)
            $txtDesc.Multiline = $true
            $txtDesc.ScrollBars = "Vertical"
            $txtDesc.Text = $currentDesc
            $editForm.Controls.Add($txtDesc)
            
            $yPos += 60
            
            
            $lblCert = New-Object System.Windows.Forms.Label
            $lblCert.Text = "Cert. Thumbprint:"
            $lblCert.Location = New-Object System.Drawing.Point(15, $yPos)
            $lblCert.Size = New-Object System.Drawing.Size(100, 20)
            $lblCert.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
            $editForm.Controls.Add($lblCert)
            
            $txtCert = New-Object System.Windows.Forms.TextBox
            $txtCert.Location = New-Object System.Drawing.Point(120, $yPos)
            $txtCert.Size = New-Object System.Drawing.Size(350, 20)
            $txtCert.Font = New-Object System.Drawing.Font("Consolas", 8)
            if ([string]::IsNullOrWhiteSpace($currentCert)) {
                $txtCert.Text = ""
                $txtCert.ForeColor = [System.Drawing.Color]::Gray
            }
            else {
                $txtCert.Text = $currentCert
            }
            $editForm.Controls.Add($txtCert)
            
            $yPos += 35
            
            
            $lblNotes = New-Object System.Windows.Forms.Label
            $lblNotes.Text = "Notas:"
            $lblNotes.Location = New-Object System.Drawing.Point(15, $yPos)
            $lblNotes.Size = New-Object System.Drawing.Size(100, 20)
            $lblNotes.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
            $editForm.Controls.Add($lblNotes)
            
            $txtNotes = New-Object System.Windows.Forms.TextBox
            $txtNotes.Location = New-Object System.Drawing.Point(120, $yPos)
            $txtNotes.Size = New-Object System.Drawing.Size(350, 80)
            $txtNotes.Multiline = $true
            $txtNotes.ScrollBars = "Vertical"
            $txtNotes.Text = $currentNotes
            $editForm.Controls.Add($txtNotes)
            
            $yPos += 90
            
            
            $btnSave = New-Object System.Windows.Forms.Button
            $btnSave.Text = "💾 Guardar"
            $btnSave.Location = New-Object System.Drawing.Point(280, $yPos)
            $btnSave.Size = New-Object System.Drawing.Size(90, 30)
            $btnSave.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
            $btnSave.ForeColor = [System.Drawing.Color]::White
            $btnSave.FlatStyle = "Flat"
            $btnSave.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $editForm.Controls.Add($btnSave)
            
            $btnCancel = New-Object System.Windows.Forms.Button
            $btnCancel.Text = "❌ Cancelar"
            $btnCancel.Location = New-Object System.Drawing.Point(380, $yPos)
            $btnCancel.Size = New-Object System.Drawing.Size(90, 30)
            $btnCancel.BackColor = [System.Drawing.Color]::FromArgb(108, 117, 125)
            $btnCancel.ForeColor = [System.Drawing.Color]::White
            $btnCancel.FlatStyle = "Flat"
            $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
            $editForm.Controls.Add($btnCancel)
            
            $editForm.AcceptButton = $btnSave
            $editForm.CancelButton = $btnCancel
            
            if ($editForm.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $command.CommandText = @"
UPDATE Servers 
SET Hostname = @Host, 
    Description = @Desc, 
    OS = @OS,
    CertificateThumbprint = @Cert,
    Notes = @Notes,
    ModifiedDate = datetime('now') 
WHERE ServerID = @ID
"@
                $command.Parameters.Clear()
                $command.Parameters.AddWithValue("@Host", $txtHostname.Text) | Out-Null
                $command.Parameters.AddWithValue("@Desc", $txtDesc.Text) | Out-Null
                $command.Parameters.AddWithValue("@OS", $txtOS.Text) | Out-Null
                $command.Parameters.AddWithValue("@Cert", $txtCert.Text) | Out-Null
                $command.Parameters.AddWithValue("@Notes", $txtNotes.Text) | Out-Null
                $command.Parameters.AddWithValue("@ID", $ServerID) | Out-Null
                $command.ExecuteNonQuery() | Out-Null
                
                $lblStatus.Text = "✓ Servidor actualizado correctamente"
                $lblStatus.ForeColor = [System.Drawing.Color]::Green
                Load-Servers
            }
        }
        
        $connection.Close()
    }
    catch {
        $lblStatus.Text = "✗ Error al editar servidor: $_"
        $lblStatus.ForeColor = [System.Drawing.Color]::Red
    }
}

function Remove-Server {
    param([int]$ServerID, [string]$Hostname)
    
    $result = [System.Windows.Forms.MessageBox]::Show(
        "¿Está seguro de eliminar el servidor '$Hostname'?`n`nEsto eliminará también todo su inventario (hardware y software).",
        "Confirmar Eliminación",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        try {
            $dbPath = Join-Path $PSScriptRoot "Database\RemoteAdmin.db"
            $connectionString = "Data Source=$dbPath;Version=3;"
            $connection = New-Object System.Data.SQLite.SQLiteConnection($connectionString)
            $connection.Open()
            
            
            $command = $connection.CreateCommand()
            $command.CommandText = "DELETE FROM HardwareInventory WHERE ServerID = @ID"
            $command.Parameters.AddWithValue("@ID", $ServerID) | Out-Null
            $command.ExecuteNonQuery() | Out-Null
            
            $command.CommandText = "DELETE FROM SoftwareInventory WHERE ServerID = @ID"
            $command.Parameters.Clear()
            $command.Parameters.AddWithValue("@ID", $ServerID) | Out-Null
            $command.ExecuteNonQuery() | Out-Null
            
            
            $command.CommandText = "DELETE FROM Servers WHERE ServerID = @ID"
            $command.Parameters.Clear()
            $command.Parameters.AddWithValue("@ID", $ServerID) | Out-Null
            $command.ExecuteNonQuery() | Out-Null
            
            $connection.Close()
            
            $lblStatus.Text = "✓ Servidor '$Hostname' eliminado correctamente"
            $lblStatus.ForeColor = [System.Drawing.Color]::Green
            
            
            $dgvHardware.DataSource = $null
            $dgvSoftware.DataSource = $null
            
            Load-Servers
        }
        catch {
            $lblStatus.Text = "✗ Error al eliminar servidor: $_"
            $lblStatus.ForeColor = [System.Drawing.Color]::Red
        }
    }
}

function Change-ServerStatus {
    param([int]$ServerID, [string]$CurrentStatus)
    
    $newStatus = if ($CurrentStatus -eq "Active") { "Inactive" } else { "Active" }
    
    try {
        $dbPath = Join-Path $PSScriptRoot "Database\RemoteAdmin.db"
        $connectionString = "Data Source=$dbPath;Version=3;"
        $connection = New-Object System.Data.SQLite.SQLiteConnection($connectionString)
        $connection.Open()
        
        $command = $connection.CreateCommand()
        $command.CommandText = "UPDATE Servers SET Status = @Status, ModifiedDate = datetime('now') WHERE ServerID = @ID"
        $command.Parameters.AddWithValue("@Status", $newStatus) | Out-Null
        $command.Parameters.AddWithValue("@ID", $ServerID) | Out-Null
        $command.ExecuteNonQuery() | Out-Null
        
        $connection.Close()
        
        $lblStatus.Text = "✓ Estado cambiado a: $newStatus"
        $lblStatus.ForeColor = [System.Drawing.Color]::Green
        Load-Servers
    }
    catch {
        $lblStatus.Text = "✗ Error al cambiar estado: $_"
        $lblStatus.ForeColor = [System.Drawing.Color]::Red
    }
}

function Uninstall-RemoteSoftware {
    param(
        [string]$ServerIP,
        [string]$SoftwareName,
        [string]$UninstallString
    )
    
    $result = [System.Windows.Forms.MessageBox]::Show(
        "¿Está seguro de desinstalar '$SoftwareName' del servidor $ServerIP?`n`nEsta acción no se puede deshacer.",
        "Confirmar Desinstalación Remota",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        try {
            $lblStatus.Text = "⏳ Desinstalando '$SoftwareName' en $ServerIP..."
            $lblStatus.ForeColor = [System.Drawing.Color]::Blue
            
            
            $uninstallScript = @"
`$software = Get-WmiObject -Class Win32_Product | Where-Object { `$_.Name -eq '$SoftwareName' }
if (`$software) {
    `$result = `$software.Uninstall()
    if (`$result.ReturnValue -eq 0) {
        Write-Output "SUCCESS: Software desinstalado correctamente"
    } else {
        Write-Output "ERROR: Código de retorno: `$(`$result.ReturnValue)"
    }
} else {
    Write-Output "ERROR: Software no encontrado"
}
"@
            
            
            $scriptBlock = [scriptblock]::Create($uninstallScript)
            $output = Invoke-Command -ComputerName $ServerIP -ScriptBlock $scriptBlock -ErrorAction Stop
            
            if ($output -like "SUCCESS:*") {
                $lblStatus.Text = "✓ Software desinstalado correctamente"
                $lblStatus.ForeColor = [System.Drawing.Color]::Green
                
                [System.Windows.Forms.MessageBox]::Show(
                    "Software desinstalado exitosamente.`n`nActualiza el inventario para ver los cambios.",
                    "Desinstalación Exitosa",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
            }
            else {
                throw $output
            }
        }
        catch {
            $lblStatus.Text = "✗ Error al desinstalar: $_"
            $lblStatus.ForeColor = [System.Drawing.Color]::Red
            
            [System.Windows.Forms.MessageBox]::Show(
                "Error al desinstalar software:`n`n$_`n`nVerifica:`n- Conectividad con el servidor`n- Permisos de administrador`n- WinRM habilitado",
                "Error de Desinstalación",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
        }
    }
}

function Install-RemoteSoftware {
    param([string]$ServerIP)
    
    
    $openDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openDialog.Filter = "Instaladores|*.msi;*.exe|Todos los archivos|*.*"
    $openDialog.Title = "Seleccionar instalador para $ServerIP"
    
    if ($openDialog.ShowDialog() -eq "OK") {
        $installerPath = $openDialog.FileName
        $installerName = [System.IO.Path]::GetFileName($installerPath)
        
        $result = [System.Windows.Forms.MessageBox]::Show(
            "¿Instalar '$installerName' en el servidor $ServerIP?`n`nEl archivo se copiará al servidor y se ejecutará.",
            "Confirmar Instalación Remota",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )
        
        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
            try {
                $lblStatus.Text = "⏳ Instalando '$installerName' en $ServerIP..."
                $lblStatus.ForeColor = [System.Drawing.Color]::Blue
                
                
                $remotePath = "\\$ServerIP\C$\Temp\$installerName"
                $remoteDir = "\\$ServerIP\C$\Temp"
                
                if (-not (Test-Path $remoteDir)) {
                    New-Item -ItemType Directory -Path $remoteDir -Force | Out-Null
                }
                
                Copy-Item -Path $installerPath -Destination $remotePath -Force
                
                
                $installScript = @"
`$installer = "C:\Temp\$installerName"
if (Test-Path `$installer) {
    if (`$installer -like "*.msi") {
        `$process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `$installer /quiet /norestart" -Wait -PassThru
    } else {
        `$process = Start-Process -FilePath `$installer -ArgumentList "/S /silent /quiet" -Wait -PassThru
    }
    
    if (`$process.ExitCode -eq 0) {
        Write-Output "SUCCESS: Instalación completada"
    } else {
        Write-Output "WARNING: Código de salida: `$(`$process.ExitCode)"
    }
    
    # Limpiar
    Remove-Item `$installer -Force -ErrorAction SilentlyContinue
} else {
    Write-Output "ERROR: Instalador no encontrado"
}
"@
                
                $scriptBlock = [scriptblock]::Create($installScript)
                $output = Invoke-Command -ComputerName $ServerIP -ScriptBlock $scriptBlock -ErrorAction Stop
                
                if ($output -like "SUCCESS:*" -or $output -like "WARNING:*") {
                    $lblStatus.Text = "✓ Instalación completada"
                    $lblStatus.ForeColor = [System.Drawing.Color]::Green
                    
                    [System.Windows.Forms.MessageBox]::Show(
                        "Instalación completada.`n`n$output`n`nActualiza el inventario para ver los cambios.",
                        "Instalación Completada",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Information
                    )
                }
                else {
                    throw $output
                }
            }
            catch {
                $lblStatus.Text = "✗ Error al instalar: $_"
                $lblStatus.ForeColor = [System.Drawing.Color]::Red
                
                [System.Windows.Forms.MessageBox]::Show(
                    "Error al instalar software:`n`n$_`n`nVerifica:`n- Conectividad con el servidor`n- Permisos de administrador`n- Espacio en disco`n- WinRM habilitado",
                    "Error de Instalación",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                )
            }
        }
    }
}

function Export-ToCSV {
    try {
        
        $activeTab = $tabControl.SelectedTab
        
        $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
        $saveDialog.Filter = "CSV files (*.csv)|*.csv"
        
        
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        
        if ($activeTab -eq $tabHardware) {
            $saveDialog.FileName = "Hardware_$timestamp.csv"
        }
        elseif ($activeTab -eq $tabSoftware) {
            $saveDialog.FileName = "Software_$timestamp.csv"
        }
        elseif ($activeTab -eq $tabSearchSoftware) {
            $saveDialog.FileName = "BusquedaSoftware_$timestamp.csv"
        }
        else {
            $saveDialog.FileName = "Inventario_$timestamp.csv"
        }
        
        if ($saveDialog.ShowDialog() -eq "OK") {
            $exportPath = $saveDialog.FileName
            $exported = $false
            $message = ""
            
            
            if ($activeTab -eq $tabHardware) {
                
                if ($dgvHardware.DataSource) {
                    $dgvHardware.DataSource | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8
                    $exported = $true
                    $message = "Hardware exportado a:`n$exportPath"
                }
                else {
                    $message = "No hay datos de hardware para exportar"
                }
            }
            elseif ($activeTab -eq $tabSoftware) {
                
                if ($dgvSoftware.DataSource) {
                    $dgvSoftware.DataSource | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8
                    $exported = $true
                    $message = "Software exportado a:`n$exportPath"
                }
                else {
                    $message = "No hay datos de software para exportar"
                }
            }
            elseif ($activeTab -eq $tabSearchSoftware) {
                
                if ($dgvSearchResults.DataSource) {
                    $dgvSearchResults.DataSource | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8
                    $exported = $true
                    $message = "Resultados de búsqueda exportados a:`n$exportPath"
                }
                else {
                    $message = "No hay resultados de búsqueda para exportar"
                }
            }
            
            
            if ($exported) {
                $lblStatus.Text = "✓ Exportación exitosa"
                $lblStatus.ForeColor = [System.Drawing.Color]::Green
                
                [System.Windows.Forms.MessageBox]::Show(
                    $message,
                    "Exportación Exitosa",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
            }
            else {
                $lblStatus.Text = "⚠️ No hay datos para exportar"
                $lblStatus.ForeColor = [System.Drawing.Color]::Orange
                
                [System.Windows.Forms.MessageBox]::Show(
                    $message,
                    "Advertencia",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                )
            }
        }
    }
    catch {
        $lblStatus.Text = "✗ Error al exportar: $_"
        $lblStatus.ForeColor = [System.Drawing.Color]::Red
        
        [System.Windows.Forms.MessageBox]::Show(
            "Error al exportar: $_",
            "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}


function Search-SoftwareInServers {
    param(
        [string]$SoftwareName
    )
    
    if ([string]::IsNullOrWhiteSpace($SoftwareName)) {
        $lblSearchStatus.Text = "⚠️ Por favor ingresa un nombre de software"
        $lblSearchStatus.ForeColor = [System.Drawing.Color]::Orange
        return
    }
    
    $lblSearchStatus.Text = "🔍 Buscando '$SoftwareName' en todos los servidores..."
    $lblSearchStatus.ForeColor = [System.Drawing.Color]::Blue
    
    try {
        
        $servers = Get-Servers
        
        if ($servers -eq $null -or $servers.Rows.Count -eq 0) {
            $lblSearchStatus.Text = "❌ No hay servidores registrados"
            $lblSearchStatus.ForeColor = [System.Drawing.Color]::Red
            return
        }
        
        
        $results = @()
        $searchPattern = "%$SoftwareName%"
        
        try {
            
            $dbPath = Join-Path $PSScriptRoot "Database\RemoteAdmin.db"
            
            if (-not (Test-Path $dbPath)) {
                $lblSearchStatus.Text = "❌ Base de datos no encontrada"
                $lblSearchStatus.ForeColor = [System.Drawing.Color]::Red
                return
            }
            
            $connectionString = "Data Source=$dbPath;Version=3;"
            $connection = New-Object System.Data.SQLite.SQLiteConnection($connectionString)
            $connection.Open()
            
            
            $query = @"
SELECT 
    srv.Hostname,
    srv.IPAddress,
    s.SoftwareName,
    s.Version,
    s.Publisher,
    s.InstallDate
FROM SoftwareInventory s
INNER JOIN Servers srv ON s.ServerID = srv.ServerID
WHERE s.SoftwareName LIKE @searchPattern
ORDER BY srv.Hostname, s.SoftwareName
"@
            
            $command = $connection.CreateCommand()
            $command.CommandText = $query
            $command.Parameters.AddWithValue("@searchPattern", $searchPattern) | Out-Null
            
            $adapter = New-Object System.Data.SQLite.SQLiteDataAdapter($command)
            $dataTable = New-Object System.Data.DataTable
            $adapter.Fill($dataTable) | Out-Null
            
            
            if ($dataTable.Rows.Count -gt 0) {
                foreach ($row in $dataTable.Rows) {
                    $results += [PSCustomObject]@{
                        Servidor         = $row["Hostname"]
                        IP               = $row["IPAddress"]
                        Software         = $row["SoftwareName"]
                        Version          = $row["Version"]
                        Fabricante       = $row["Publisher"]
                        FechaInstalacion = $row["InstallDate"]
                    }
                }
            }
            
            $connection.Close()
        }
        catch {
            Write-Host "Error en consulta SQL: $_" -ForegroundColor Red
            if ($connection -and $connection.State -eq 'Open') {
                $connection.Close()
            }
            throw
        }
        
        
        if ($results.Count -gt 0) {
            $dgvSearchResults.DataSource = [System.Collections.ArrayList]@($results)
            $lblSearchStatus.Text = "✓ Encontrados $($results.Count) resultado(s) en $($results | Select-Object -Unique Servidor | Measure-Object).Count servidor(es)"
            $lblSearchStatus.ForeColor = [System.Drawing.Color]::Green
        }
        else {
            $dgvSearchResults.DataSource = $null
            $lblSearchStatus.Text = "ℹ️ No se encontró '$SoftwareName' en ningún servidor"
            $lblSearchStatus.ForeColor = [System.Drawing.Color]::Orange
        }
    }
    catch {
        $lblSearchStatus.Text = "❌ Error al buscar: $($_.Exception.Message)"
        $lblSearchStatus.ForeColor = [System.Drawing.Color]::Red
        Write-Host "Error en búsqueda: $_" -ForegroundColor Red
    }
}


$dgvServers.Add_SelectionChanged({
        if ($dgvServers.SelectedRows.Count -gt 0) {
            $selectedRow = $dgvServers.SelectedRows[0]
            $serverIP = $selectedRow.Cells["IPAddress"].Value
            $hostname = $selectedRow.Cells["Hostname"].Value
        
            $lblStatus.Text = "Cargando inventario de $hostname ($serverIP)..."
            $lblStatus.ForeColor = [System.Drawing.Color]::Blue
        
            Load-Hardware -ServerIP $serverIP
            Load-Software -ServerIP $serverIP
        }
    })

$btnRefresh.Add_Click({
        $lblStatus.Text = "Actualizando..."
        $lblStatus.ForeColor = [System.Drawing.Color]::Blue
        Load-Servers
    })

$btnExport.Add_Click({
        
        $activeTab = $tabControl.SelectedTab
        
        if (($activeTab -eq $tabHardware -or $activeTab -eq $tabSoftware) -and $dgvServers.SelectedRows.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show(
                "Por favor selecciona un servidor primero",
                "Advertencia",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            return
        }
        
        Export-ToCSV
    })

$btnEdit.Add_Click({
        if ($dgvServers.SelectedRows.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show(
                "Por favor selecciona un servidor primero",
                "Advertencia",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            return
        }
        $selectedRow = $dgvServers.SelectedRows[0]
        $serverID = $selectedRow.Cells["ServerID"].Value
        Edit-Server -ServerID $serverID
    })

$btnDelete.Add_Click({
        if ($dgvServers.SelectedRows.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show(
                "Por favor selecciona un servidor primero",
                "Advertencia",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            return
        }
        $selectedRow = $dgvServers.SelectedRows[0]
        $serverID = $selectedRow.Cells["ServerID"].Value
        $hostname = $selectedRow.Cells["Hostname"].Value
        Remove-Server -ServerID $serverID -Hostname $hostname
    })

$btnChangeStatus.Add_Click({
        if ($dgvServers.SelectedRows.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show(
                "Por favor selecciona un servidor primero",
                "Advertencia",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            return
        }
        $selectedRow = $dgvServers.SelectedRows[0]
        $serverID = $selectedRow.Cells["ServerID"].Value
        $currentStatus = $selectedRow.Cells["Status"].Value
        Change-ServerStatus -ServerID $serverID -CurrentStatus $currentStatus
    })

$btnManageTags.Add_Click({
        if ($dgvServers.SelectedRows.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show(
                "Por favor selecciona un servidor primero",
                "Advertencia",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            return
        }
        
        $selectedRow = $dgvServers.SelectedRows[0]
        $serverIP = $selectedRow.Cells["IPAddress"].Value
        $hostname = $selectedRow.Cells["Hostname"].Value
        
        
        $tagForm = New-Object System.Windows.Forms.Form
        $tagForm.Text = "Gestionar Etiquetas - $hostname"
        $tagForm.Size = New-Object System.Drawing.Size(500, 450)
        $tagForm.StartPosition = "CenterParent"
        $tagForm.FormBorderStyle = "FixedDialog"
        $tagForm.MaximizeBox = $false
        
        
        $lblCurrent = New-Object System.Windows.Forms.Label
        $lblCurrent.Text = "Etiquetas Actuales:"
        $lblCurrent.Location = New-Object System.Drawing.Point(10, 10)
        $lblCurrent.Size = New-Object System.Drawing.Size(470, 20)
        $lblCurrent.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $tagForm.Controls.Add($lblCurrent)
        
        
        $lstCurrentTags = New-Object System.Windows.Forms.ListBox
        $lstCurrentTags.Location = New-Object System.Drawing.Point(10, 35)
        $lstCurrentTags.Size = New-Object System.Drawing.Size(470, 120)
        $tagForm.Controls.Add($lstCurrentTags)
        
        
        $currentTags = Get-ServerTags -ServerIP $serverIP
        if ($currentTags -and $currentTags.Rows.Count -gt 0) {
            foreach ($tag in $currentTags.Rows) {
                $tagDisplay = if ($tag.TagCategory) { "$($tag.TagName) ($($tag.TagCategory))" } else { $tag.TagName }
                $lstCurrentTags.Items.Add($tagDisplay) | Out-Null
            }
        }
        
        
        $btnRemoveTag = New-Object System.Windows.Forms.Button
        $btnRemoveTag.Text = "❌ Eliminar Seleccionada"
        $btnRemoveTag.Location = New-Object System.Drawing.Point(10, 165)
        $btnRemoveTag.Size = New-Object System.Drawing.Size(150, 30)
        $btnRemoveTag.BackColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
        $btnRemoveTag.ForeColor = [System.Drawing.Color]::White
        $btnRemoveTag.FlatStyle = "Flat"
        $tagForm.Controls.Add($btnRemoveTag)
        
        
        $lblNew = New-Object System.Windows.Forms.Label
        $lblNew.Text = "Agregar Nueva Etiqueta:"
        $lblNew.Location = New-Object System.Drawing.Point(10, 210)
        $lblNew.Size = New-Object System.Drawing.Size(470, 20)
        $lblNew.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $tagForm.Controls.Add($lblNew)
        
        
        $lblTagName = New-Object System.Windows.Forms.Label
        $lblTagName.Text = "Nombre:"
        $lblTagName.Location = New-Object System.Drawing.Point(10, 240)
        $lblTagName.Size = New-Object System.Drawing.Size(80, 20)
        $tagForm.Controls.Add($lblTagName)
        
        $txtTagName = New-Object System.Windows.Forms.TextBox
        $txtTagName.Location = New-Object System.Drawing.Point(100, 238)
        $txtTagName.Size = New-Object System.Drawing.Size(380, 25)
        $tagForm.Controls.Add($txtTagName)
        
        
        $lblTagCategory = New-Object System.Windows.Forms.Label
        $lblTagCategory.Text = "Categoría:"
        $lblTagCategory.Location = New-Object System.Drawing.Point(10, 275)
        $lblTagCategory.Size = New-Object System.Drawing.Size(80, 20)
        $tagForm.Controls.Add($lblTagCategory)
        
        $cmbTagCategory = New-Object System.Windows.Forms.ComboBox
        $cmbTagCategory.Location = New-Object System.Drawing.Point(100, 273)
        $cmbTagCategory.Size = New-Object System.Drawing.Size(380, 25)
        $cmbTagCategory.DropDownStyle = "DropDownList"
        $cmbTagCategory.Items.AddRange(@("", "Ubicación", "Función", "Ambiente", "Departamento", "Aplicación", "Otro"))
        $cmbTagCategory.SelectedIndex = 0
        $tagForm.Controls.Add($cmbTagCategory)
        
        
        $btnAddTag = New-Object System.Windows.Forms.Button
        $btnAddTag.Text = "➕ Agregar Etiqueta"
        $btnAddTag.Location = New-Object System.Drawing.Point(10, 315)
        $btnAddTag.Size = New-Object System.Drawing.Size(150, 30)
        $btnAddTag.BackColor = [System.Drawing.Color]::FromArgb(40, 167, 69)
        $btnAddTag.ForeColor = [System.Drawing.Color]::White
        $btnAddTag.FlatStyle = "Flat"
        $tagForm.Controls.Add($btnAddTag)
        
        
        $btnClose = New-Object System.Windows.Forms.Button
        $btnClose.Text = "Cerrar"
        $btnClose.Location = New-Object System.Drawing.Point(330, 370)
        $btnClose.Size = New-Object System.Drawing.Size(150, 30)
        $btnClose.BackColor = [System.Drawing.Color]::FromArgb(108, 117, 125)
        $btnClose.ForeColor = [System.Drawing.Color]::White
        $btnClose.FlatStyle = "Flat"
        $btnClose.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $tagForm.Controls.Add($btnClose)
        
        
        $btnAddTag.Add_Click({
                $tagName = $txtTagName.Text.Trim()
                if ([string]::IsNullOrWhiteSpace($tagName)) {
                    [System.Windows.Forms.MessageBox]::Show("Por favor ingresa un nombre de etiqueta", "Advertencia", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                    return
                }
                
                $category = $cmbTagCategory.SelectedItem
                if (Add-ServerTag -ServerIP $serverIP -TagName $tagName -TagCategory $category) {
                    $tagDisplay = if ($category) { "$tagName ($category)" } else { $tagName }
                    $lstCurrentTags.Items.Add($tagDisplay) | Out-Null
                    $txtTagName.Clear()
                    $cmbTagCategory.SelectedIndex = 0
                    [System.Windows.Forms.MessageBox]::Show("Etiqueta agregada exitosamente", "Éxito", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                }
                else {
                    [System.Windows.Forms.MessageBox]::Show("Error al agregar etiqueta", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }
            })
        
        $btnRemoveTag.Add_Click({
                if ($lstCurrentTags.SelectedIndex -ge 0) {
                    $selectedTag = $lstCurrentTags.SelectedItem.ToString()
                    $tagName = if ($selectedTag -match '^(.+?)\s+\(') { $matches[1] } else { $selectedTag }
                    
                    $result = [System.Windows.Forms.MessageBox]::Show("¿Eliminar la etiqueta '$tagName'?", "Confirmar", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
                    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                        if (Remove-ServerTag -ServerIP $serverIP -TagName $tagName) {
                            $lstCurrentTags.Items.RemoveAt($lstCurrentTags.SelectedIndex)
                            [System.Windows.Forms.MessageBox]::Show("Etiqueta eliminada exitosamente", "Éxito", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                        }
                        else {
                            [System.Windows.Forms.MessageBox]::Show("Error al eliminar etiqueta", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                        }
                    }
                }
            })
        
        
        $result = $tagForm.ShowDialog()
        
        
        Load-Servers
    })






$btnSearch.Add_Click({
        $searchTerm = $txtSearchSoftware.Text.Trim()
        Search-SoftwareInServers -SoftwareName $searchTerm
    })


$btnClearSearch.Add_Click({
        $txtSearchSoftware.Clear()
        $dgvSearchResults.DataSource = $null
        $lblSearchStatus.Text = "Ingresa el nombre del software y haz clic en Buscar"
        $lblSearchStatus.ForeColor = [System.Drawing.Color]::Gray
    })


$txtSearchSoftware.Add_KeyDown({
        param($sender, $e)
        if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
            $searchTerm = $txtSearchSoftware.Text.Trim()
            Search-SoftwareInServers -SoftwareName $searchTerm
            $e.SuppressKeyPress = $true
        }
    })


Load-Servers


[void]$form.ShowDialog()

