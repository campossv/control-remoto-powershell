

Import-Module -Name "$PSScriptRoot\Modules\RemoteConnection.psm1" -Force -Global


Import-Module -Name "$PSScriptRoot\Modules\FileOperations.psm1" -Force
Import-Module -Name "$PSScriptRoot\Modules\ProcessManagement.psm1" -Force
Import-Module -Name "$PSScriptRoot\Modules\ServiceManagement.psm1" -Force
Import-Module -Name "$PSScriptRoot\Modules\SessionLogger.psm1" -Force
Import-Module -Name "$PSScriptRoot\Modules\SystemInfo.psm1" -Force
Import-Module -Name "$PSScriptRoot\Modules\EventViewer.psm1" -Force
Import-Module -Name "$PSScriptRoot\Modules\DatabaseManager.psm1" -Force
Import-Module -Name "$PSScriptRoot\Modules\SoftwareManagement.psm1" -Force


$global:clientCertificate = $null
$global:certificateLoaded = $false


$global:sessionActive = $false
$global:sessionId = $null


$script:CommandHistory = New-Object System.Collections.Generic.List[string]
$script:HistoryIndex = -1


Initialize-SessionLogger


Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing


Add-Type @"
using System;
using System.Runtime.InteropServices;

public class User32 {
    [DllImport("user32.dll")]
    public static extern bool DestroyIcon(IntPtr hIcon);
}
"@


$Global:puerto = 4430
$ImagenBytes = [Convert]::FromBase64String('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')
$ms = New-Object System.IO.MemoryStream(, $ImagenBytes)
$image = [System.Drawing.Image]::FromStream($ms)
$bitmap = New-Object System.Drawing.Bitmap($image)
$iconHandle = $bitmap.GetHicon()
$icon = [System.Drawing.Icon]::FromHandle($iconHandle)
$image.Dispose()
$bitmap.Dispose()


function Load-ServerList {
    
    $serverList = @()
    
    try {
        
        $dbServers = Get-Servers
        
        if ($dbServers -ne $null -and $dbServers.Rows -ne $null -and $dbServers.Rows.Count -gt 0) {
            foreach ($row in $dbServers.Rows) {
                
                $dateTime = if ($row["LastConnection"] -and $row["LastConnection"] -ne [DBNull]::Value) {
                    try {
                        [DateTime]::Parse($row["LastConnection"].ToString()).ToString("dd/MM/yyyy HH:mm:ss")
                    }
                    catch {
                        (Get-Date).ToString("dd/MM/yyyy HH:mm:ss")
                    }
                }
                else {
                    (Get-Date).ToString("dd/MM/yyyy HH:mm:ss")
                }
                
                $serverList += [PSCustomObject]@{
                    DateTime    = $dateTime
                    IP          = $row["IPAddress"].ToString()
                    Description = if ($row["Description"] -and $row["Description"] -ne [DBNull]::Value) { $row["Description"].ToString() } else { $row["Hostname"].ToString() }
                    Hostname    = if ($row["Hostname"] -and $row["Hostname"] -ne [DBNull]::Value) { $row["Hostname"].ToString() } else { "" }
                    ServerID    = $row["ServerID"]
                }
            }
            Write-Host "✓ Servidores cargados desde BD: $($serverList.Count)" -ForegroundColor Green
        }
        else {
            Write-Host "⚠ No hay servidores en la BD, cargando desde servers.txt..." -ForegroundColor Yellow
            
            if (Test-Path "servers.txt") {
                Get-Content "servers.txt" | ForEach-Object {
                    if ($_ -match "(\d{2}/\d{2}/\d{4} \d{2}:\d{2}:\d{2}) - (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) - (.+)") {
                        
                        $serverList += [PSCustomObject]@{
                            DateTime    = $matches[1]
                            IP          = $matches[2]
                            Description = $matches[3]
                            Hostname    = ""
                            ServerID    = $null
                        }
                        
                        
                        Add-Server -IPAddress $matches[2] -Description $matches[3] | Out-Null
                    }
                }
                if ($serverList.Count -gt 0) {
                    Write-Host "✓ Servidores migrados a BD: $($serverList.Count)" -ForegroundColor Green
                }
            }
        }
    }
    catch {
        Write-Warning "Error al cargar servidores desde BD: $_"
        
        if (Test-Path "servers.txt") {
            Get-Content "servers.txt" | ForEach-Object {
                if ($_ -match "(\d{2}/\d{2}/\d{4} \d{2}:\d{2}:\d{2}) - (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) - (.+)") {
                    $serverList += [PSCustomObject]@{
                        DateTime    = $matches[1]
                        IP          = $matches[2]
                        Description = $matches[3]
                        Hostname    = ""
                        ServerID    = $null
                    }
                }
            }
        }
    }
    
    return $serverList
}


function Load-ClientCertificateUI {
    
    $certForm = New-Object System.Windows.Forms.Form
    $certForm.Text = "Cargar Certificado de Cliente"
    $certForm.Size = New-Object System.Drawing.Size(500, 300)
    $certForm.StartPosition = "CenterScreen"
    $certForm.FormBorderStyle = "FixedDialog"
    $certForm.MaximizeBox = $false
    $certForm.MinimizeBox = $false

    
    $lblInstructions = New-Object System.Windows.Forms.Label
    $lblInstructions.Text = "Seleccione el archivo de certificado (.pfx) del cliente:"
    $lblInstructions.Location = New-Object System.Drawing.Point(20, 20)
    $lblInstructions.Size = New-Object System.Drawing.Size(440, 20)
    $certForm.Controls.Add($lblInstructions)

    
    $txtCertPath = New-Object System.Windows.Forms.TextBox
    $txtCertPath.Location = New-Object System.Drawing.Point(20, 50)
    $txtCertPath.Size = New-Object System.Drawing.Size(340, 20)
    $certForm.Controls.Add($txtCertPath)

    
    $btnBrowse = New-Object System.Windows.Forms.Button
    $btnBrowse.Text = "Explorar..."
    $btnBrowse.Location = New-Object System.Drawing.Point(370, 48)
    $btnBrowse.Size = New-Object System.Drawing.Size(90, 24)
    $certForm.Controls.Add($btnBrowse)

    
    $lblPassword = New-Object System.Windows.Forms.Label
    $lblPassword.Text = "Contraseña del certificado:"
    $lblPassword.Location = New-Object System.Drawing.Point(20, 90)
    $lblPassword.Size = New-Object System.Drawing.Size(200, 20)
    $certForm.Controls.Add($lblPassword)

    
    $txtPassword = New-Object System.Windows.Forms.TextBox
    $txtPassword.Location = New-Object System.Drawing.Point(20, 110)
    $txtPassword.Size = New-Object System.Drawing.Size(200, 20)
    $txtPassword.UseSystemPasswordChar = $true
    $certForm.Controls.Add($txtPassword)

    
    $btnLoad = New-Object System.Windows.Forms.Button
    $btnLoad.Text = "Cargar"
    $btnLoad.Location = New-Object System.Drawing.Point(300, 150)
    $btnLoad.Size = New-Object System.Drawing.Size(70, 30)
    $btnLoad.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $certForm.Controls.Add($btnLoad)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Cancelar"
    $btnCancel.Location = New-Object System.Drawing.Point(380, 150)
    $btnCancel.Size = New-Object System.Drawing.Size(70, 30)
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $certForm.Controls.Add($btnCancel)

    
    $btnBrowse.Add_Click({
            $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
            $openFileDialog.Title = "Seleccionar Certificado de Cliente"
            $openFileDialog.Filter = "Archivos PFX (*.pfx)|*.pfx|Todos los archivos (*.*)|*.*"
            $openFileDialog.Multiselect = $false

            if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $txtCertPath.Text = $openFileDialog.FileName
            }
        })

    
    $btnLoad.Add_Click({
            $certPath = $txtCertPath.Text.Trim()
            $password = $txtPassword.Text

            if ([string]::IsNullOrWhiteSpace($certPath)) {
                [System.Windows.Forms.MessageBox]::Show("Por favor seleccione un archivo de certificado.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                $certForm.DialogResult = [System.Windows.Forms.DialogResult]::None
                return
            }

            if (-not (Test-Path $certPath)) {
                [System.Windows.Forms.MessageBox]::Show("El archivo de certificado no existe.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                $certForm.DialogResult = [System.Windows.Forms.DialogResult]::None
                return
            }

            
            try {
                $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
                $global:clientCertificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certPath, $securePassword, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet)

                if ($global:clientCertificate) {
                    $global:certificateLoaded = $true
                    [System.Windows.Forms.MessageBox]::Show("Certificado cargado exitosamente.`n$($global:clientCertificate.Subject)", "Éxito", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                }
                else {
                    $global:certificateLoaded = $false
                    [System.Windows.Forms.MessageBox]::Show("Error al cargar el certificado.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                    $certForm.DialogResult = [System.Windows.Forms.DialogResult]::None
                }
            }
            catch {
                $global:certificateLoaded = $false
                [System.Windows.Forms.MessageBox]::Show("Error al cargar el certificado: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                $certForm.DialogResult = [System.Windows.Forms.DialogResult]::None
            }
        })

    $certForm.ShowDialog()
    return $global:certificateLoaded
}

function Show-CertificateStatus {
    
    if ($global:certificateLoaded -and $global:clientCertificate) {
        $validation = Test-ClientCertificateValidity -Certificate $global:clientCertificate
        
        $statusForm = New-Object System.Windows.Forms.Form
        $statusForm.Text = "Estado del Certificado"
        $statusForm.Size = New-Object System.Drawing.Size(400, 250)
        $statusForm.StartPosition = "CenterScreen"
        $statusForm.FormBorderStyle = "FixedDialog"

        $lblStatus = New-Object System.Windows.Forms.Label
        $lblStatus.Location = New-Object System.Drawing.Point(20, 20)
        $lblStatus.Size = New-Object System.Drawing.Size(340, 150)
        
        $statusText = "Estado del Certificado de Cliente:`n`n"
        $statusText += "Subject: $($global:clientCertificate.Subject)`n"
        $statusText += "Thumbprint: $($global:clientCertificate.Thumbprint)`n"
        $statusText += "Válido hasta: $($global:clientCertificate.NotAfter)`n"
        $statusText += "Estado: $(if ($validation.Valid) { '✅ VÁLIDO' } else { '❌ INVÁLIDO' })`n"
        $statusText += "Motivo: $($validation.Reason)"
        
        $lblStatus.Text = $statusText
        $lblStatus.ForeColor = if ($validation.Valid) { [System.Drawing.Color]::Green } else { [System.Drawing.Color]::Red }
        $statusForm.Controls.Add($lblStatus)

        $btnOK = New-Object System.Windows.Forms.Button
        $btnOK.Text = "OK"
        $btnOK.Location = New-Object System.Drawing.Point(150, 180)
        $btnOK.Size = New-Object System.Drawing.Size(70, 30)
        $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $statusForm.Controls.Add($btnOK)

        $statusForm.ShowDialog()
    }
    else {
        [System.Windows.Forms.MessageBox]::Show("No hay ningún certificado de cliente cargado.", "Información", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
}

function Execute-RemoteCommand {
    param ([string]$command)
    
    
    if (-not $global:certificateLoaded -or -not $global:clientCertificate) {
        [System.Windows.Forms.MessageBox]::Show("Debe cargar un certificado de cliente antes de ejecutar comandos.`nUse el menú 'Certificado' -> 'Cargar Certificado'.", "Error de Autenticación", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        Write-SessionLog -Level "ERROR" -Message "Intento de ejecutar comando sin certificado" -Details "Comando: $command"
        return
    }
    
    
    Write-SessionLog -Level "COMMAND" -Message "Ejecutando comando remoto" -Details $command

    if (-not [string]::IsNullOrWhiteSpace($command)) {
        $script:CommandHistory.Add($command)
        $script:HistoryIndex = $script:CommandHistory.Count
    }
    
    try {
        $commandToSend = Format-CommandPacket -action "EXECUTE_COMMAND" -parameters @($command)
        $response = Send-RemoteCommand -remoteServer $global:selectedServer.IP -remotePort $Global:puerto -command $commandToSend -clientCertificate $global:clientCertificate
        
        $prompt = "PS $($global:selectedServer.IP)> "

        if ($response.success) {
            $txtSalida.SelectionColor = [System.Drawing.Color]::Cyan
            $txtSalida.AppendText($prompt)

            $txtSalida.SelectionColor = [System.Drawing.Color]::White
            $txtSalida.AppendText($command + "`r`n")

            if ($response.output) {
                $txtSalida.SelectionColor = [System.Drawing.Color]::LightGray
                $txtSalida.AppendText($response.output + "`r`n")
            }

            $txtSalida.SelectionColor = [System.Drawing.Color]::White
            $txtSalida.AppendText("`r`n")

            $txtSalida.ScrollToCaret()

            Write-SessionLog -Level "SUCCESS" -Message "Comando ejecutado exitosamente" -Details "Salida: $($response.output.Length) caracteres"
        }
        else {
            $txtSalida.SelectionColor = [System.Drawing.Color]::Cyan
            $txtSalida.AppendText($prompt)

            $txtSalida.SelectionColor = [System.Drawing.Color]::White
            $txtSalida.AppendText($command + "`r`n")

            $txtSalida.SelectionColor = [System.Drawing.Color]::Red
            $txtSalida.AppendText("Error: $($response.message)`r`n`r`n")

            $txtSalida.SelectionColor = [System.Drawing.Color]::White
            $txtSalida.ScrollToCaret()

            Write-SessionLog -Level "ERROR" -Message "Error al ejecutar comando" -Details $response.message
        }
    }
    catch {
        $txtSalida.SelectionColor = [System.Drawing.Color]::Red
        $txtSalida.AppendText("Error de ejecución: $($_.Exception.Message)`r`n`r`n")
        $txtSalida.SelectionColor = [System.Drawing.Color]::White
        Write-SessionLog -Level "ERROR" -Message "Excepción al ejecutar comando" -Details $_.Exception.Message
    }
}
function Return-ToServerSelection {
    
    
    
    if ($global:sessionActive) {
        Stop-RemoteSession -Reason "Usuario regresó a selección de servidores"
        
        
        Add-SessionLog -SessionID $global:sessionId -ServerIP $global:selectedServer.IP -Level "INFO" -Message "Sesión finalizada - Regreso a selección" | Out-Null
        
        $global:sessionActive = $false
    }
    
    
    $form.Hide()
    
    
    $listBox.Items.Clear()
    $txtSalida.Clear()
    
    
    $dataGridProcesos.DataSource = $null
    $dataGridServicios.DataSource = $null
    
    
    $serverSelectionForm.Show()
    $serverSelectionForm.BringToFront()
    $serverSelectionForm.Focus()
}


$serverSelectionForm = New-Object System.Windows.Forms.Form
$serverSelectionForm.Text = "Seleccionar Servidor"
$serverSelectionForm.Size = New-Object System.Drawing.Size(450, 380)
$serverSelectionForm.StartPosition = "CenterScreen"
$serverSelectionForm.Icon = $icon


$lblServers = New-Object System.Windows.Forms.Label
$lblServers.Text = "Servidores disponibles:"
$lblServers.Location = New-Object System.Drawing.Point(10, 10)
$lblServers.Size = New-Object System.Drawing.Size(400, 20)
$serverSelectionForm.Controls.Add($lblServers)

$serverListBox = New-Object System.Windows.Forms.ListBox
$serverListBox.Location = New-Object System.Drawing.Point(10, 35)
$serverListBox.Size = New-Object System.Drawing.Size(410, 180)
$serverSelectionForm.Controls.Add($serverListBox)


$lblCertificate = New-Object System.Windows.Forms.Label
$lblCertificate.Location = New-Object System.Drawing.Point(10, 225)
$lblCertificate.Size = New-Object System.Drawing.Size(410, 20)
$lblCertificate.Text = "Buscando certificado..."
$lblCertificate.ForeColor = [System.Drawing.Color]::Gray
$serverSelectionForm.Controls.Add($lblCertificate)


$lblPassword = New-Object System.Windows.Forms.Label
$lblPassword.Text = "Contraseña del certificado:"
$lblPassword.Location = New-Object System.Drawing.Point(10, 250)
$lblPassword.Size = New-Object System.Drawing.Size(200, 20)
$serverSelectionForm.Controls.Add($lblPassword)


$txtCertPassword = New-Object System.Windows.Forms.TextBox
$txtCertPassword.Location = New-Object System.Drawing.Point(10, 275)
$txtCertPassword.Size = New-Object System.Drawing.Size(300, 20)
$txtCertPassword.UseSystemPasswordChar = $true
$serverSelectionForm.Controls.Add($txtCertPassword)

$connectButton = New-Object System.Windows.Forms.Button
$connectButton.Location = New-Object System.Drawing.Point(320, 273)
$connectButton.Size = New-Object System.Drawing.Size(100, 30)
$connectButton.Text = "Conectar"
$serverSelectionForm.Controls.Add($connectButton)

$connectButton.Add_Click({
        if (-not $serverListBox.SelectedItem) {
            [System.Windows.Forms.MessageBox]::Show("Por favor, seleccione un servidor.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }
        
        if ([string]::IsNullOrWhiteSpace($txtCertPassword.Text)) {
            [System.Windows.Forms.MessageBox]::Show("Por favor, ingrese la contraseña del certificado.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }
        
        
        try {
            $securePassword = ConvertTo-SecureString -String $txtCertPassword.Text -AsPlainText -Force
            $global:clientCertificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($global:certificatePath, $securePassword, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet)
            
            if (-not $global:clientCertificate) {
                [System.Windows.Forms.MessageBox]::Show("Error al cargar el certificado. Verifique la contraseña.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                return
            }
            
            $global:certificateLoaded = $true
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Error al cargar el certificado: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }
        
        $global:selectedServer = $servers[$serverListBox.SelectedIndex]
        
        
        $certThumbprint = if ($global:clientCertificate) { $global:clientCertificate.Thumbprint } else { "N/A" }
        $global:sessionId = Start-RemoteSession -ServerIP $global:selectedServer.IP -ServerName $global:selectedServer.Description -CertificateThumbprint $certThumbprint
        $global:sessionActive = $true
        
        Write-SessionLog -Level "INFO" -Message "Conexión establecida con servidor" -Details "IP: $($global:selectedServer.IP), Puerto: $Global:puerto"
        
        
        Add-SessionLog -SessionID $global:sessionId -ServerIP $global:selectedServer.IP -Level "INFO" -Message "Conexión establecida" | Out-Null
        
        $serverSelectionForm.Hide()
        [User32]::DestroyIcon($iconHandle)
        
        Write-SessionLog -Level "INFO" -Message "Cargando estructura de archivos inicial" -Details "Ruta: C:\\"

        $rootPath = "C:\\"
        $rootNode = $treeDirectories.Nodes.Add($rootPath, $rootPath)
        
        $entries = Get-RemoteDirectoryEntries -Path $rootPath
        foreach ($entry in $entries) {
            $isDir = Is-RemoteDirectory -itemPath $entry -remoteServer $global:selectedServer.IP -remotePort $Global:puerto -clientCertificate $global:clientCertificate
            if ($isDir) {
                $childPath = $entry
                $childNode = $rootNode.Nodes.Add($childPath, [System.IO.Path]::GetFileName($childPath))
            }
        }

        $treeDirectories.ExpandAll()

        Update-FileList -remoteServer $global:selectedServer.IP -remotePort $Global:puerto -path $rootPath -listBox $listBox -clientCertificate $global:clientCertificate
        $listBox.Tag = $rootPath
        
        Write-SessionLog -Level "INFO" -Message "Actualizando lista de procesos"
        Refresh-Processes -remoteServer $global:selectedServer.IP -remotePort $Global:puerto -dataGrid $dataGridProcesos -clientCertificate $global:clientCertificate
        
        Write-SessionLog -Level "INFO" -Message "Actualizando lista de servicios"
        Refresh-Services -remoteServer $global:selectedServer.IP -remotePort $Global:puerto -dataGrid $dataGridServicios -clientCertificate $global:clientCertificate
        
        $form.ShowDialog()
        
        
        if ($global:sessionActive) {
            Stop-RemoteSession -Reason "Usuario cerró la aplicación"
            
            
            Add-SessionLog -SessionID $global:sessionId -ServerIP $global:selectedServer.IP -Level "INFO" -Message "Sesión finalizada - Aplicación cerrada" | Out-Null
            
            $global:sessionActive = $false
        }
    })


$global:certificatePath = $null
$certificatesFolder = Join-Path $PSScriptRoot "Certificates"

if (Test-Path $certificatesFolder) {
    $pfxFiles = Get-ChildItem -Path $certificatesFolder -Filter "*.pfx"
    
    if ($pfxFiles.Count -gt 0) {
        
        $clientCert = $pfxFiles | Where-Object { $_.Name -like "*client*" -or $_.Name -like "*cliente*" } | Select-Object -First 1
        
        if ($clientCert) {
            $global:certificatePath = $clientCert.FullName
            $lblCertificate.Text = "✓ Certificado encontrado: $($clientCert.Name)"
        }
        else {
            
            $global:certificatePath = $pfxFiles[0].FullName
            $lblCertificate.Text = "✓ Certificado encontrado: $($pfxFiles[0].Name)"
        }
        
        $lblCertificate.ForeColor = [System.Drawing.Color]::Green
    }
    else {
        $lblCertificate.Text = "⚠ No se encontró ningún certificado (.pfx) en la carpeta Certificates"
        $lblCertificate.ForeColor = [System.Drawing.Color]::Red
        $connectButton.Enabled = $false
    }
}
else {
    $lblCertificate.Text = "⚠ No existe la carpeta Certificates"
    $lblCertificate.ForeColor = [System.Drawing.Color]::Red
    $connectButton.Enabled = $false
}


$servers = Load-ServerList
foreach ($server in $servers) {
    $serverListBox.Items.Add("$($server.DateTime) - $($server.IP) - $($server.Description)")
}


$form = New-Object System.Windows.Forms.Form
$form.Text = "Administrador de Equipos Remotos - $($global:selectedServer.IP)"
$form.Size = New-Object System.Drawing.Size(1200, 900)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = 'FixedDialog'
$form.ControlBox = $false


$menuStrip = New-Object System.Windows.Forms.MenuStrip
$form.MainMenuStrip = $menuStrip


$menuCertificado = New-Object System.Windows.Forms.ToolStripMenuItem
$menuCertificado.Text = "Certificado"

$menuLoadCert = New-Object System.Windows.Forms.ToolStripMenuItem
$menuLoadCert.Text = "Cargar Certificado"
$menuLoadCert.Add_Click({ Load-ClientCertificateUI })

$menuCertStatus = New-Object System.Windows.Forms.ToolStripMenuItem
$menuCertStatus.Text = "Ver Estado"
$menuCertStatus.Add_Click({ Show-CertificateStatus })

$menuCertificado.DropDownItems.AddRange(@($menuLoadCert, $menuCertStatus))

$menuStrip.Items.Add($menuCertificado)
$form.Controls.Add($menuStrip)

$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Location = New-Object System.Drawing.Point(0, 24)
$tabControl.Size = New-Object System.Drawing.Size(1200, 876)

$TabFiles = New-Object System.Windows.Forms.TabPage
$TabFiles.Text = "Archivos"

$tabPageProcesos = New-Object System.Windows.Forms.TabPage
$tabPageProcesos.Text = "Procesos"
$tabPageProcesos.Add_Enter({ Refresh-Processes -remoteServer $global:selectedServer.IP -remotePort $Global:puerto -dataGrid $dataGridProcesos -clientCertificate $global:clientCertificate })

$tabPageServicios = New-Object System.Windows.Forms.TabPage
$tabPageServicios.Text = "Servicios"
$tabPageServicios.Add_Enter({ Refresh-Services -remoteServer $global:selectedServer.IP -remotePort $Global:puerto -dataGrid $dataGridServicios -clientCertificate $global:clientCertificate })

$tabPageSysInfo = New-Object System.Windows.Forms.TabPage
$tabPageSysInfo.Text = "Info Sistema"
$tabPageSysInfo.Add_Enter({ Update-SystemInfoPanel })

$tabPageEventos = New-Object System.Windows.Forms.TabPage
$tabPageEventos.Text = "Eventos"

$tabPageSoftware = New-Object System.Windows.Forms.TabPage
$tabPageSoftware.Text = "Software"
$tabPageSoftware.Add_Enter({ Refresh-Software })

$tabPageMassInstall = New-Object System.Windows.Forms.TabPage
$tabPageMassInstall.Text = "Instalación Masiva"

$tabControl.TabPages.Add($TabFiles)
$tabControl.TabPages.Add($tabPageProcesos)
$tabControl.TabPages.Add($tabPageServicios)
$tabControl.TabPages.Add($tabPageSysInfo)
$tabControl.TabPages.Add($tabPageEventos)
$tabControl.TabPages.Add($tabPageSoftware)
$tabControl.TabPages.Add($tabPageMassInstall)
$form.Controls.Add($tabControl)




function Get-RemoteDirectoryEntries {
    param (
        [string]$Path
    )

    try {
        $encodedCmd = Format-CommandPacket -action "LIST_FILES" -parameters @($Path)
        $response = Send-RemoteCommand -remoteServer $global:selectedServer.IP -remotePort $Global:puerto -command $encodedCmd -clientCertificate $global:clientCertificate

        if ($response -and $response.success -and $response.files) {
            return $response.files
        }
        else {
            return @()
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error al obtener contenido del directorio remoto: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return @()
    }
}


$panelSysInfo = New-Object System.Windows.Forms.Panel
$panelSysInfo.Location = New-Object System.Drawing.Point(200, 10)
$panelSysInfo.Size = New-Object System.Drawing.Size(770, 600)
$panelSysInfo.AutoScroll = $true
$panelSysInfo.BorderStyle = "FixedSingle"
$tabPageSysInfo.Controls.Add($panelSysInfo)


$btnRefreshSysInfo = New-Object System.Windows.Forms.Button
$btnRefreshSysInfo.Text = "Actualizar"
$btnRefreshSysInfo.Location = New-Object System.Drawing.Point(200, 615)
$btnRefreshSysInfo.Size = New-Object System.Drawing.Size(100, 30)
$btnRefreshSysInfo.Add_Click({ Update-SystemInfoPanel })
$tabPageSysInfo.Controls.Add($btnRefreshSysInfo)


$btnSalirSysInfo = New-Object System.Windows.Forms.Button
$btnSalirSysInfo.Text = "Salir"
$btnSalirSysInfo.Location = New-Object System.Drawing.Point(870, 615)
$btnSalirSysInfo.Size = New-Object System.Drawing.Size(100, 30)
$btnSalirSysInfo.Add_Click({ Return-ToServerSelection })
$tabPageSysInfo.Controls.Add($btnSalirSysInfo)


$lblSysInfoStatus = New-Object System.Windows.Forms.Label
$lblSysInfoStatus.Location = New-Object System.Drawing.Point(350, 620)
$lblSysInfoStatus.Size = New-Object System.Drawing.Size(550, 20)
$lblSysInfoStatus.Text = "Haz clic en 'Actualizar' para obtener informacion del sistema"
$lblSysInfoStatus.ForeColor = [System.Drawing.Color]::Gray
$tabPageSysInfo.Controls.Add($lblSysInfoStatus)


function New-TitleLabel {
    param([string]$Text, [int]$Y)
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $label.Location = New-Object System.Drawing.Point(10, $Y)
    $label.Size = New-Object System.Drawing.Size(740, 25)
    $label.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
    $label.BackColor = [System.Drawing.Color]::LightSteelBlue
    $label.ForeColor = [System.Drawing.Color]::DarkBlue
    $label.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    return $label
}


function New-InfoLabel {
    param([string]$Text, [int]$Y, [System.Drawing.Color]$Color = [System.Drawing.Color]::Black)
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $label.Location = New-Object System.Drawing.Point(20, $Y)
    $label.Size = New-Object System.Drawing.Size(720, 20)
    $label.Font = New-Object System.Drawing.Font("Consolas", 9)
    $label.ForeColor = $Color
    return $label
}


function Update-SystemInfoPanel {
    try {
        $lblSysInfoStatus.Text = "Obteniendo informacion del sistema..."
        $lblSysInfoStatus.ForeColor = [System.Drawing.Color]::Blue
        
        
        $panelSysInfo.Controls.Clear()
        
        
        $sysInfo = Get-RemoteSystemInfo -RemoteServer $global:selectedServer.IP -RemotePort $Global:puerto -ClientCertificate $global:clientCertificate
        
        if (-not $sysInfo) {
            $lblSysInfoStatus.Text = "Error: No se pudo obtener informacion del sistema"
            $lblSysInfoStatus.ForeColor = [System.Drawing.Color]::Red
            return
        }
        
        
        $formatted = Format-SystemInfoDisplay -SystemInfo $sysInfo
        
        $yPos = 10
        
        
        $panelSysInfo.Controls.Add((New-TitleLabel -Text "INFORMACION GENERAL" -Y $yPos))
        $yPos += 30
        
        $panelSysInfo.Controls.Add((New-InfoLabel -Text "Nombre del Equipo:  $($formatted.ComputerName)" -Y $yPos))
        $yPos += 25
        
        $panelSysInfo.Controls.Add((New-InfoLabel -Text "Sistema Operativo:  $($formatted.OSVersion)" -Y $yPos))
        $yPos += 25
        
        $panelSysInfo.Controls.Add((New-InfoLabel -Text "Arquitectura:       $($formatted.OSArchitecture)" -Y $yPos))
        $yPos += 25
        
        $panelSysInfo.Controls.Add((New-InfoLabel -Text "Ultimo Arranque:    $($formatted.LastBootTime)" -Y $yPos))
        $yPos += 25
        
        $panelSysInfo.Controls.Add((New-InfoLabel -Text "Tiempo Encendido:   $($formatted.Uptime)" -Y $yPos))
        $yPos += 35
        
        
        $panelSysInfo.Controls.Add((New-TitleLabel -Text "PROCESADOR" -Y $yPos))
        $yPos += 30
        
        $panelSysInfo.Controls.Add((New-InfoLabel -Text "Procesador:  $($formatted.CPUName)" -Y $yPos))
        $yPos += 25
        
        $panelSysInfo.Controls.Add((New-InfoLabel -Text "Nucleos:     $($formatted.CPUCores)" -Y $yPos))
        $yPos += 25
        
        $cpuColor = Get-CPUUsageColor -UsagePercent ([double]$formatted.CPUUsage.TrimEnd('%'))
        $panelSysInfo.Controls.Add((New-InfoLabel -Text "Uso de CPU:  $($formatted.CPUUsage)" -Y $yPos -Color $cpuColor))
        $yPos += 35
        
        
        $panelSysInfo.Controls.Add((New-TitleLabel -Text "MEMORIA RAM" -Y $yPos))
        $yPos += 30
        
        $panelSysInfo.Controls.Add((New-InfoLabel -Text "Total:       $($formatted.TotalRAM)" -Y $yPos))
        $yPos += 25
        
        $panelSysInfo.Controls.Add((New-InfoLabel -Text "En Uso:      $($formatted.UsedRAM)" -Y $yPos))
        $yPos += 25
        
        $panelSysInfo.Controls.Add((New-InfoLabel -Text "Libre:       $($formatted.FreeRAM)" -Y $yPos))
        $yPos += 25
        
        $ramColor = Get-RAMUsageColor -UsagePercent ([double]$formatted.RAMUsagePercent.TrimEnd('%'))
        $panelSysInfo.Controls.Add((New-InfoLabel -Text "Uso:         $($formatted.RAMUsagePercent)" -Y $yPos -Color $ramColor))
        $yPos += 35
        
        
        $panelSysInfo.Controls.Add((New-TitleLabel -Text "DISCOS" -Y $yPos))
        $yPos += 30
        
        foreach ($disk in $formatted.Disks) {
            $diskLabel = if ($disk.Label) { $disk.Label } else { "Sin etiqueta" }
            $panelSysInfo.Controls.Add((New-InfoLabel -Text "Disco $($disk.Drive) - $diskLabel" -Y $yPos))
            $yPos += 20
            
            $totalSize = Format-Bytes -Bytes $disk.TotalSize
            $freeSpace = Format-Bytes -Bytes $disk.FreeSpace
            $usedSpace = Format-Bytes -Bytes $disk.UsedSpace
            
            $panelSysInfo.Controls.Add((New-InfoLabel -Text "  Total: $totalSize | Libre: $freeSpace | Usado: $usedSpace" -Y $yPos))
            $yPos += 20
            
            $diskColor = Get-DiskUsageColor -UsagePercent $disk.UsagePercent
            $panelSysInfo.Controls.Add((New-InfoLabel -Text "  Uso: $($disk.UsagePercent)%" -Y $yPos -Color $diskColor))
            $yPos += 25
        }
        
        $yPos += 10
        
        
        $panelSysInfo.Controls.Add((New-TitleLabel -Text "ADAPTADORES DE RED" -Y $yPos))
        $yPos += 30
        
        foreach ($adapter in $formatted.NetworkAdapters) {
            $panelSysInfo.Controls.Add((New-InfoLabel -Text "Adaptador: $($adapter.Name)" -Y $yPos))
            $yPos += 20
            
            $panelSysInfo.Controls.Add((New-InfoLabel -Text "  Descripcion: $($adapter.Description)" -Y $yPos))
            $yPos += 20
            
            $panelSysInfo.Controls.Add((New-InfoLabel -Text "  Estado: $($adapter.Status) | Velocidad: $($adapter.Speed)" -Y $yPos))
            $yPos += 20
            
            $panelSysInfo.Controls.Add((New-InfoLabel -Text "  IP: $($adapter.IPAddress) | MAC: $($adapter.MACAddress)" -Y $yPos))
            $yPos += 25
        }
        
        $lblSysInfoStatus.Text = "Informacion actualizada correctamente - $($formatted.ComputerName)"
        $lblSysInfoStatus.ForeColor = [System.Drawing.Color]::Green
        
        
        Write-SessionLog -Level "INFO" -Message "Informacion del sistema consultada" -Details "Servidor: $($formatted.ComputerName)"
        
    }
    catch {
        $lblSysInfoStatus.Text = "Error: $($_.Exception.Message)"
        $lblSysInfoStatus.ForeColor = [System.Drawing.Color]::Red
        Write-SessionLog -Level "ERROR" -Message "Error al obtener informacion del sistema" -Details $_.Exception.Message
    }
}




$lblLogName = New-Object System.Windows.Forms.Label
$lblLogName.Text = "Log:"
$lblLogName.Location = New-Object System.Drawing.Point(10, 15)
$lblLogName.Size = New-Object System.Drawing.Size(40, 20)
$tabPageEventos.Controls.Add($lblLogName)

$comboLogName = New-Object System.Windows.Forms.ComboBox
$comboLogName.Location = New-Object System.Drawing.Point(50, 12)
$comboLogName.Size = New-Object System.Drawing.Size(120, 20)
$comboLogName.DropDownStyle = "DropDownList"
$comboLogName.Items.AddRange(@("System", "Security", "Application"))
$comboLogName.SelectedIndex = 0
$tabPageEventos.Controls.Add($comboLogName)


$lblLevel = New-Object System.Windows.Forms.Label
$lblLevel.Text = "Nivel:"
$lblLevel.Location = New-Object System.Drawing.Point(180, 15)
$lblLevel.Size = New-Object System.Drawing.Size(40, 20)
$tabPageEventos.Controls.Add($lblLevel)

$comboLevel = New-Object System.Windows.Forms.ComboBox
$comboLevel.Location = New-Object System.Drawing.Point(225, 12)
$comboLevel.Size = New-Object System.Drawing.Size(120, 20)
$comboLevel.DropDownStyle = "DropDownList"
$comboLevel.Items.AddRange(@("All", "Critical", "Error", "Warning", "Information"))
$comboLevel.SelectedIndex = 0
$tabPageEventos.Controls.Add($comboLevel)


$lblHours = New-Object System.Windows.Forms.Label
$lblHours.Text = "Horas:"
$lblHours.Location = New-Object System.Drawing.Point(355, 15)
$lblHours.Size = New-Object System.Drawing.Size(45, 20)
$tabPageEventos.Controls.Add($lblHours)

$numHours = New-Object System.Windows.Forms.NumericUpDown
$numHours.Location = New-Object System.Drawing.Point(405, 12)
$numHours.Size = New-Object System.Drawing.Size(60, 20)
$numHours.Minimum = 1
$numHours.Maximum = 168
$numHours.Value = 24
$tabPageEventos.Controls.Add($numHours)


$lblMaxEvents = New-Object System.Windows.Forms.Label
$lblMaxEvents.Text = "Max:"
$lblMaxEvents.Location = New-Object System.Drawing.Point(475, 15)
$lblMaxEvents.Size = New-Object System.Drawing.Size(35, 20)
$tabPageEventos.Controls.Add($lblMaxEvents)

$numMaxEvents = New-Object System.Windows.Forms.NumericUpDown
$numMaxEvents.Location = New-Object System.Drawing.Point(515, 12)
$numMaxEvents.Size = New-Object System.Drawing.Size(70, 20)
$numMaxEvents.Minimum = 10
$numMaxEvents.Maximum = 1000
$numMaxEvents.Value = 100
$numMaxEvents.Increment = 10
$tabPageEventos.Controls.Add($numMaxEvents)


$btnRefreshEvents = New-Object System.Windows.Forms.Button
$btnRefreshEvents.Text = "Actualizar"
$btnRefreshEvents.Location = New-Object System.Drawing.Point(595, 10)
$btnRefreshEvents.Size = New-Object System.Drawing.Size(90, 25)
$tabPageEventos.Controls.Add($btnRefreshEvents)


$btnExportEvents = New-Object System.Windows.Forms.Button
$btnExportEvents.Text = "Exportar CSV"
$btnExportEvents.Location = New-Object System.Drawing.Point(690, 10)
$btnExportEvents.Size = New-Object System.Drawing.Size(90, 25)
$tabPageEventos.Controls.Add($btnExportEvents)


$dataGridEventos = New-Object System.Windows.Forms.DataGridView
$dataGridEventos.Location = New-Object System.Drawing.Point(10, 45)
$dataGridEventos.Size = New-Object System.Drawing.Size(1150, 650)
$dataGridEventos.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
$dataGridEventos.ReadOnly = $true
$dataGridEventos.AllowUserToAddRows = $false
$dataGridEventos.SelectionMode = "FullRowSelect"
$dataGridEventos.MultiSelect = $false
$tabPageEventos.Controls.Add($dataGridEventos)


$lblEventStatus = New-Object System.Windows.Forms.Label
$lblEventStatus.Location = New-Object System.Drawing.Point(10, 750)
$lblEventStatus.Size = New-Object System.Drawing.Size(300, 20)
$lblEventStatus.Text = "Selecciona opciones y haz clic en 'Actualizar'"
$lblEventStatus.ForeColor = [System.Drawing.Color]::Gray
$tabPageEventos.Controls.Add($lblEventStatus)


$btnSalirEventos = New-Object System.Windows.Forms.Button
$btnSalirEventos.Text = "Salir"
$btnSalirEventos.Location = New-Object System.Drawing.Point(500, 750)
$btnSalirEventos.Size = New-Object System.Drawing.Size(100, 30)
$btnSalirEventos.Add_Click({ Return-ToServerSelection })
$tabPageEventos.Controls.Add($btnSalirEventos)


$btnRefreshEvents.Add_Click({
        try {
            $lblEventStatus.Text = "Obteniendo eventos..."
            $lblEventStatus.ForeColor = [System.Drawing.Color]::Blue
        
            $count = Update-EventLogGrid `
                -RemoteServer $global:selectedServer.IP `
                -RemotePort $Global:puerto `
                -ClientCertificate $global:clientCertificate `
                -DataGrid $dataGridEventos `
                -LogName $comboLogName.SelectedItem `
                -MaxEvents $numMaxEvents.Value `
                -Level $comboLevel.SelectedItem `
                -Hours $numHours.Value
        
            if ($count -gt 0) {
                $lblEventStatus.Text = "Eventos cargados: $count"
                $lblEventStatus.ForeColor = [System.Drawing.Color]::Green
            
                Write-SessionLog -Level "INFO" -Message "Eventos consultados" `
                    -Details "Log: $($comboLogName.SelectedItem), Eventos: $count"
            }
            else {
                $lblEventStatus.Text = "No se encontraron eventos"
                $lblEventStatus.ForeColor = [System.Drawing.Color]::Orange
            }
        }
        catch {
            $lblEventStatus.Text = "Error: $($_.Exception.Message)"
            $lblEventStatus.ForeColor = [System.Drawing.Color]::Red
            Write-SessionLog -Level "ERROR" -Message "Error al obtener eventos" `
                -Details $_.Exception.Message
        }
    })


$btnExportEvents.Add_Click({
        try {
            if ($dataGridEventos.Rows.Count -eq 0) {
                [System.Windows.Forms.MessageBox]::Show(
                    "No hay eventos para exportar",
                    "Exportar Eventos",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                )
                return
            }
        
            $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
            $saveDialog.Filter = "CSV files (*.csv)|*.csv"
            $saveDialog.FileName = "Eventos_$($comboLogName.SelectedItem)_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        
            if ($saveDialog.ShowDialog() -eq "OK") {
                $events = @()
                foreach ($row in $dataGridEventos.Rows) {
                    $events += [PSCustomObject]@{
                        Nivel   = $row.Cells["Nivel"].Value
                        Fecha   = $row.Cells["Fecha"].Value
                        Origen  = $row.Cells["Origen"].Value
                        EventID = $row.Cells["EventID"].Value
                        Mensaje = $row.Cells["Mensaje"].Value
                        Usuario = $row.Cells["Usuario"].Value
                    }
                }
            
                $events | Export-Csv -Path $saveDialog.FileName -NoTypeInformation -Encoding UTF8
            
                [System.Windows.Forms.MessageBox]::Show(
                    "Eventos exportados exitosamente a:`n$($saveDialog.FileName)",
                    "Exportar Eventos",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
            
                Write-SessionLog -Level "INFO" -Message "Eventos exportados" `
                    -Details "Archivo: $($saveDialog.FileName), Eventos: $($events.Count)"
            }
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show(
                "Error al exportar eventos:`n$($_.Exception.Message)",
                "Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
        }
    })


$txtBusquedaProcesos = New-Object System.Windows.Forms.TextBox
$txtBusquedaProcesos.Location = New-Object System.Drawing.Point(10, 10)
$txtBusquedaProcesos.Size = New-Object System.Drawing.Size(200, 20)
$tabPageProcesos.Controls.Add($txtBusquedaProcesos)

$btnBuscarProcesos = New-Object System.Windows.Forms.Button
$btnBuscarProcesos.Location = New-Object System.Drawing.Point(220, 10)
$btnBuscarProcesos.Size = New-Object System.Drawing.Size(80, 23)
$btnBuscarProcesos.Text = "Buscar"
$tabPageProcesos.Controls.Add($btnBuscarProcesos)
$btnBuscarProcesos.Add_Click({ Refresh-Processes -remoteServer $global:selectedServer.IP -remotePort $Global:puerto -dataGrid $dataGridProcesos -filtro $txtBusquedaProcesos.Text -clientCertificate $global:clientCertificate })

$btnMatarProcesos = New-Object System.Windows.Forms.Button
$btnMatarProcesos.Location = New-Object System.Drawing.Point(300, 750)
$btnMatarProcesos.Size = New-Object System.Drawing.Size(150, 23)
$btnMatarProcesos.Text = "Terminar proceso"
$tabPageProcesos.Controls.Add($btnMatarProcesos)

$dataGridProcesos = New-Object System.Windows.Forms.DataGridView
$dataGridProcesos.Location = New-Object System.Drawing.Point(10, 40)
$dataGridProcesos.Size = New-Object System.Drawing.Size(1160, 680)
$dataGridProcesos.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
$dataGridProcesos.ReadOnly = $true
$dataGridProcesos.AllowUserToAddRows = $false
$dataGridProcesos.SelectionMode = "FullRowSelect"
$tabPageProcesos.Controls.Add($dataGridProcesos)

$btnMatarProcesos.Add_Click({
        if ($dataGridProcesos.SelectedRows.Count -gt 0) {
            $procesoseleccionado = $dataGridProcesos.SelectedRows[0].Cells["Id"].Value
            Terminate-RemoteProcess -processId $procesoseleccionado -remoteServer $global:selectedServer.IP -remotePort $Global:puerto -dataGrid $dataGridProcesos -clientCertificate $global:clientCertificate
        }
    })


$buttonSalirProcesos = New-Object System.Windows.Forms.Button
$buttonSalirProcesos.Text = "Salir"
$buttonSalirProcesos.Size = New-Object System.Drawing.Size(150, 23)
$buttonSalirProcesos.Location = New-Object System.Drawing.Point(680, 750)
$buttonSalirProcesos.Add_Click({ Return-ToServerSelection })
$tabPageProcesos.Controls.Add($buttonSalirProcesos)


$txtBusquedaServicios = New-Object System.Windows.Forms.TextBox
$txtBusquedaServicios.Location = New-Object System.Drawing.Point(10, 10)
$txtBusquedaServicios.Size = New-Object System.Drawing.Size(200, 20)
$tabPageServicios.Controls.Add($txtBusquedaServicios)

$btnBuscarServicios = New-Object System.Windows.Forms.Button
$btnBuscarServicios.Location = New-Object System.Drawing.Point(220, 10)
$btnBuscarServicios.Size = New-Object System.Drawing.Size(80, 23)
$btnBuscarServicios.Text = "Buscar"
$tabPageServicios.Controls.Add($btnBuscarServicios)
$btnBuscarServicios.Add_Click({ Refresh-Services -remoteServer $global:selectedServer.IP -remotePort $Global:puerto -dataGrid $dataGridServicios -filtro $txtBusquedaServicios.Text -clientCertificate $global:clientCertificate })

$btnExcluirMicrosoft = New-Object System.Windows.Forms.Button
$btnExcluirMicrosoft.Location = New-Object System.Drawing.Point(310, 10)
$btnExcluirMicrosoft.Size = New-Object System.Drawing.Size(200, 23)
$btnExcluirMicrosoft.Text = "Excluir servicios de Microsoft"
$tabPageServicios.Controls.Add($btnExcluirMicrosoft)

$dataGridServicios = New-Object System.Windows.Forms.DataGridView
$dataGridServicios.Location = New-Object System.Drawing.Point(10, 40)
$dataGridServicios.Size = New-Object System.Drawing.Size(1150, 680)
$dataGridServicios.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
$dataGridServicios.ReadOnly = $true
$dataGridServicios.AllowUserToAddRows = $false
$dataGridServicios.SelectionMode = "FullRowSelect"
$tabPageServicios.Controls.Add($dataGridServicios)

$btnRefrescarServicios = New-Object System.Windows.Forms.Button
$btnRefrescarServicios.Location = New-Object System.Drawing.Point(10, 750)
$btnRefrescarServicios.Size = New-Object System.Drawing.Size(120, 23)
$btnRefrescarServicios.Text = "Refrescar Servicios"
$tabPageServicios.Controls.Add($btnRefrescarServicios)
$btnRefrescarServicios.Add_Click({ $global:excluirMicrosoft = $false; $btnExcluirMicrosoft.Text = "Excluir servicios de Microsoft"; Refresh-Services -remoteServer $global:selectedServer.IP -remotePort $Global:puerto -dataGrid $dataGridServicios -clientCertificate $global:clientCertificate })

$btnIniciarServicio = New-Object System.Windows.Forms.Button
$btnIniciarServicio.Location = New-Object System.Drawing.Point(140, 750)
$btnIniciarServicio.Size = New-Object System.Drawing.Size(80, 23)
$btnIniciarServicio.Text = "Iniciar"
$tabPageServicios.Controls.Add($btnIniciarServicio)
$btnIniciarServicio.Add_Click({
        if ($dataGridServicios.SelectedRows.Count -gt 0) {
            $selectedService = $dataGridServicios.SelectedRows[0].Cells["Name"].Value
            Start-RemoteService -serviceName $selectedService -remoteServer $global:selectedServer.IP -remotePort $Global:puerto -dataGrid $dataGridServicios -clientCertificate $global:clientCertificate
        }
    })

$btnDetenerServicio = New-Object System.Windows.Forms.Button
$btnDetenerServicio.Location = New-Object System.Drawing.Point(230, 750)
$btnDetenerServicio.Size = New-Object System.Drawing.Size(80, 23)
$btnDetenerServicio.Text = "Detener"
$tabPageServicios.Controls.Add($btnDetenerServicio)
$btnDetenerServicio.Add_Click({
        if ($dataGridServicios.SelectedRows.Count -gt 0) {
            $selectedService = $dataGridServicios.SelectedRows[0].Cells["Name"].Value
            Stop-RemoteService -serviceName $selectedService -remoteServer $global:selectedServer.IP -remotePort $Global:puerto -dataGrid $dataGridServicios -clientCertificate $global:clientCertificate
        }
    })

$btnReiniciarServicio = New-Object System.Windows.Forms.Button
$btnReiniciarServicio.Location = New-Object System.Drawing.Point(320, 750)
$btnReiniciarServicio.Size = New-Object System.Drawing.Size(80, 23)
$btnReiniciarServicio.Text = "Reiniciar"
$tabPageServicios.Controls.Add($btnReiniciarServicio)
$btnReiniciarServicio.Add_Click({
        if ($dataGridServicios.SelectedRows.Count -gt 0) {
            $selectedService = $dataGridServicios.SelectedRows[0].Cells["Name"].Value
            Restart-RemoteService -serviceName $selectedService -remoteServer $global:selectedServer.IP -remotePort $Global:puerto -dataGrid $dataGridServicios -clientCertificate $global:clientCertificate
        }
    })

$btnExcluirMicrosoft.Add_Click({
        $global:excluirMicrosoft = -not $global:excluirMicrosoft
        if ($global:excluirMicrosoft) {
            $btnExcluirMicrosoft.Text = "Mostrar todos los servicios"
        }
        else {
            $btnExcluirMicrosoft.Text = "Excluir servicios de Microsoft"
        }
        Refresh-Services -remoteServer $global:selectedServer.IP -remotePort $Global:puerto -dataGrid $dataGridServicios -excluirMicrosoft $global:excluirMicrosoft -clientCertificate $global:clientCertificate
    })


$buttonSalirServicios = New-Object System.Windows.Forms.Button
$buttonSalirServicios.Text = "Salir"
$buttonSalirServicios.Size = New-Object System.Drawing.Size(100, 30)
$buttonSalirServicios.Location = New-Object System.Drawing.Point(680, 750)
$buttonSalirServicios.Add_Click({ Return-ToServerSelection })
$tabPageServicios.Controls.Add($buttonSalirServicios)


$treeDirectories = New-Object System.Windows.Forms.TreeView
$treeDirectories.Size = New-Object System.Drawing.Size(260, 240)
$treeDirectories.Location = New-Object System.Drawing.Point(20, 20)
$treeDirectories.HideSelection = $false
$TabFiles.Controls.Add($treeDirectories)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Size = New-Object System.Drawing.Size(480, 240)
$listBox.Location = New-Object System.Drawing.Point(300, 20)
$TabFiles.Controls.Add($listBox)

$txtComando = New-Object System.Windows.Forms.TextBox
$txtComando.Location = New-Object System.Drawing.Point(20, 320)
$txtComando.Size = New-Object System.Drawing.Size(750, 20)
$txtComando.Font = New-Object System.Drawing.Font("Consolas", 10)
$TabFiles.Controls.Add($txtComando)

$txtSalida = New-Object System.Windows.Forms.RichTextBox
$txtSalida.Location = New-Object System.Drawing.Point(20, 350)
$txtSalida.Size = New-Object System.Drawing.Size(1130, 430)
$txtSalida.Multiline = $true
$txtSalida.ScrollBars = "Vertical"
$txtSalida.BackColor = [System.Drawing.Color]::Black
$txtSalida.ForeColor = [System.Drawing.Color]::White
$txtSalida.Rtf = "{\rtf1\ansi\deff0{\fonttbl{\f0 Consolas;}}{\f0\fs20\sl240\slmult1}}"
$txtSalida.ReadOnly = $true
$TabFiles.Controls.Add($txtSalida)


$txtComando.Add_KeyDown({
        param($eventSender, $e)

        if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
            if ($txtComando.Text.Trim()) {
                Execute-RemoteCommand -command $txtComando.Text.Trim()
                $txtComando.Clear()
            }
            $e.SuppressKeyPress = $true
        }
        elseif ($e.KeyCode -eq [System.Windows.Forms.Keys]::Up) {
            if ($script:CommandHistory.Count -gt 0) {
                if ($script:HistoryIndex -gt 0) {
                    $script:HistoryIndex--
                }
                if ($script:HistoryIndex -ge 0 -and $script:HistoryIndex -lt $script:CommandHistory.Count) {
                    $txtComando.Text = $script:CommandHistory[$script:HistoryIndex]
                    $txtComando.SelectionStart = $txtComando.Text.Length
                }
            }
            $e.SuppressKeyPress = $true
        }
        elseif ($e.KeyCode -eq [System.Windows.Forms.Keys]::Down) {
            if ($script:CommandHistory.Count -gt 0) {
                if ($script:HistoryIndex -lt ($script:CommandHistory.Count - 1)) {
                    $script:HistoryIndex++
                    $txtComando.Text = $script:CommandHistory[$script:HistoryIndex]
                }
                else {
                    $script:HistoryIndex = $script:CommandHistory.Count
                    $txtComando.Clear()
                }
                $txtComando.SelectionStart = $txtComando.Text.Length
            }
            $e.SuppressKeyPress = $true
        }
    })

$buttonDownload = New-Object System.Windows.Forms.Button
$buttonDownload.Text = "Descargar"
$buttonDownload.Size = New-Object System.Drawing.Size(100, 30)
$buttonDownload.Location = New-Object System.Drawing.Point(10, 270)
$TabFiles.Controls.Add($buttonDownload)
$buttonDownload.Add_Click({ Download-RemoteFile -selectedFile $listBox.SelectedItem -remoteServer $global:selectedServer.IP -remotePort $Global:puerto -clientCertificate $global:clientCertificate })

$buttonUpload = New-Object System.Windows.Forms.Button
$buttonUpload.Text = "Subir"
$buttonUpload.Size = New-Object System.Drawing.Size(100, 30)
$buttonUpload.Location = New-Object System.Drawing.Point(450, 270)
$TabFiles.Controls.Add($buttonUpload)
$buttonUpload.Add_Click({ Upload-RemoteFile -remotePath $listBox.SelectedItem -remoteServer $global:selectedServer.IP -remotePort $Global:puerto -listBox $listBox -clientCertificate $global:clientCertificate })

$buttonDelete = New-Object System.Windows.Forms.Button
$buttonDelete.Text = "Eliminar"
$buttonDelete.Size = New-Object System.Drawing.Size(100, 30)
$buttonDelete.Location = New-Object System.Drawing.Point(120, 270)
$TabFiles.Controls.Add($buttonDelete)
$buttonDelete.Add_Click({ Delete-RemoteFile -selectedFile $listBox.SelectedItem -remoteServer $global:selectedServer.IP -remotePort $Global:puerto -listBox $listBox -clientCertificate $global:clientCertificate })

$buttonMove = New-Object System.Windows.Forms.Button
$buttonMove.Text = "Mover"
$buttonMove.Size = New-Object System.Drawing.Size(100, 30)
$buttonMove.Location = New-Object System.Drawing.Point(340, 270)
$TabFiles.Controls.Add($buttonMove)
$buttonMove.Add_Click({ Move-RemoteFile -selectedFile $listBox.SelectedItem -remoteServer $global:selectedServer.IP -remotePort $Global:puerto -listBox $listBox -clientCertificate $global:clientCertificate })

$buttonCopiar = New-Object System.Windows.Forms.Button
$buttonCopiar.Text = "Copiar"
$buttonCopiar.Size = New-Object System.Drawing.Size(100, 30)
$buttonCopiar.Location = New-Object System.Drawing.Point(230, 270)
$TabFiles.Controls.Add($buttonCopiar)
$buttonCopiar.Add_Click({ Copy-RemoteFile -selectedFile $listBox.SelectedItem -remoteServer $global:selectedServer.IP -remotePort $Global:puerto -clientCertificate $global:clientCertificate })

$buttonSalir = New-Object System.Windows.Forms.Button
$buttonSalir.Text = "Salir"
$buttonSalir.Size = New-Object System.Drawing.Size(100, 30)
$buttonSalir.Location = New-Object System.Drawing.Point(560, 270)
$TabFiles.Controls.Add($buttonSalir)
$buttonSalir.Add_Click({ Return-ToServerSelection })

$buttonRDP = New-Object System.Windows.Forms.Button
$buttonRDP.Text = "Escritorio Remoto"
$buttonRDP.Size = New-Object System.Drawing.Size(100, 30)
$buttonRDP.Location = New-Object System.Drawing.Point(670, 270)
$TabFiles.Controls.Add($buttonRDP)
$buttonRDP.Add_Click({ Start-Process "mstsc.exe" -ArgumentList "/v:$($global:selectedServer.IP) /f" })

$treeDirectories.add_AfterSelect({
        param($sender, $e)
        $selectedNode = $e.Node
        if ($null -ne $selectedNode -and $selectedNode.FullPath) {
            $path = $selectedNode.Name
            if (-not $path) {
                $path = $selectedNode.Text
            }

            if ($path) {
                Update-FileList -remoteServer $global:selectedServer.IP -remotePort $Global:puerto -path $path -listBox $listBox -clientCertificate $global:clientCertificate
                $listBox.Tag = $path
            }
        }
    })

$dataGridSoftware = New-Object System.Windows.Forms.DataGridView
$dataGridSoftware.Location = New-Object System.Drawing.Point(10, 10)
$dataGridSoftware.Size = New-Object System.Drawing.Size(750, 600)
$dataGridSoftware.AllowUserToAddRows = $false
$dataGridSoftware.AllowUserToDeleteRows = $false
$dataGridSoftware.ReadOnly = $true
$dataGridSoftware.SelectionMode = "FullRowSelect"
$dataGridSoftware.MultiSelect = $false
$dataGridSoftware.AutoSizeColumnsMode = "Fill"
$tabPageSoftware.Controls.Add($dataGridSoftware)


$panelSoftwareInfo = New-Object System.Windows.Forms.Panel
$panelSoftwareInfo.Location = New-Object System.Drawing.Point(770, 10)
$panelSoftwareInfo.Size = New-Object System.Drawing.Size(400, 600)
$panelSoftwareInfo.BorderStyle = "FixedSingle"
$panelSoftwareInfo.BackColor = [System.Drawing.Color]::FromArgb(250, 250, 250)
$tabPageSoftware.Controls.Add($panelSoftwareInfo)


$lblSoftwareInfoTitle = New-Object System.Windows.Forms.Label
$lblSoftwareInfoTitle.Text = "Información del Software"
$lblSoftwareInfoTitle.Location = New-Object System.Drawing.Point(10, 10)
$lblSoftwareInfoTitle.Size = New-Object System.Drawing.Size(380, 25)
$lblSoftwareInfoTitle.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$lblSoftwareInfoTitle.ForeColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$panelSoftwareInfo.Controls.Add($lblSoftwareInfoTitle)


$txtSoftwareInfo = New-Object System.Windows.Forms.TextBox
$txtSoftwareInfo.Location = New-Object System.Drawing.Point(10, 45)
$txtSoftwareInfo.Size = New-Object System.Drawing.Size(380, 400)
$txtSoftwareInfo.Multiline = $true
$txtSoftwareInfo.ReadOnly = $true
$txtSoftwareInfo.ScrollBars = "Vertical"
$txtSoftwareInfo.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$txtSoftwareInfo.BackColor = [System.Drawing.Color]::White
$txtSoftwareInfo.Text = "Selecciona un software de la lista para ver su información"
$panelSoftwareInfo.Controls.Add($txtSoftwareInfo)


$btnUninstallSoftware = New-Object System.Windows.Forms.Button
$btnUninstallSoftware.Text = "🗑️ Desinstalar"
$btnUninstallSoftware.Location = New-Object System.Drawing.Point(10, 460)
$btnUninstallSoftware.Size = New-Object System.Drawing.Size(380, 40)
$btnUninstallSoftware.BackColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
$btnUninstallSoftware.ForeColor = [System.Drawing.Color]::White
$btnUninstallSoftware.FlatStyle = "Flat"
$btnUninstallSoftware.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnUninstallSoftware.Enabled = $false
$panelSoftwareInfo.Controls.Add($btnUninstallSoftware)


$btnInstallSoftware = New-Object System.Windows.Forms.Button
$btnInstallSoftware.Text = "📦 Instalar Software"
$btnInstallSoftware.Location = New-Object System.Drawing.Point(10, 510)
$btnInstallSoftware.Size = New-Object System.Drawing.Size(185, 40)
$btnInstallSoftware.BackColor = [System.Drawing.Color]::FromArgb(40, 167, 69)
$btnInstallSoftware.ForeColor = [System.Drawing.Color]::White
$btnInstallSoftware.FlatStyle = "Flat"
$btnInstallSoftware.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$panelSoftwareInfo.Controls.Add($btnInstallSoftware)


$btnInstallWithParams = New-Object System.Windows.Forms.Button
$btnInstallWithParams.Text = "⚙️ Instalar (Params)"
$btnInstallWithParams.Location = New-Object System.Drawing.Point(205, 510)
$btnInstallWithParams.Size = New-Object System.Drawing.Size(185, 40)
$btnInstallWithParams.BackColor = [System.Drawing.Color]::FromArgb(23, 162, 184)
$btnInstallWithParams.ForeColor = [System.Drawing.Color]::White
$btnInstallWithParams.FlatStyle = "Flat"
$btnInstallWithParams.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$panelSoftwareInfo.Controls.Add($btnInstallWithParams)


$btnRefreshSoftware = New-Object System.Windows.Forms.Button
$btnRefreshSoftware.Text = "🔄 Actualizar"
$btnRefreshSoftware.Location = New-Object System.Drawing.Point(10, 620)
$btnRefreshSoftware.Size = New-Object System.Drawing.Size(120, 30)
$btnRefreshSoftware.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnRefreshSoftware.ForeColor = [System.Drawing.Color]::White
$btnRefreshSoftware.FlatStyle = "Flat"
$btnRefreshSoftware.Add_Click({ Refresh-Software })
$tabPageSoftware.Controls.Add($btnRefreshSoftware)


$lblSoftwareStatus = New-Object System.Windows.Forms.Label
$lblSoftwareStatus.Location = New-Object System.Drawing.Point(210, 615)
$lblSoftwareStatus.Size = New-Object System.Drawing.Size(600, 20)
$lblSoftwareStatus.Text = "Haz clic en 'Actualizar' para obtener la lista de software"
$lblSoftwareStatus.ForeColor = [System.Drawing.Color]::Gray
$tabPageSoftware.Controls.Add($lblSoftwareStatus)




$panelMassServers = New-Object System.Windows.Forms.Panel
$panelMassServers.Location = New-Object System.Drawing.Point(10, 10)
$panelMassServers.Size = New-Object System.Drawing.Size(450, 600)
$panelMassServers.BorderStyle = "FixedSingle"
$panelMassServers.BackColor = [System.Drawing.Color]::White
$tabPageMassInstall.Controls.Add($panelMassServers)


$lblMassTitle = New-Object System.Windows.Forms.Label
$lblMassTitle.Text = "🖥️ Selección de Servidores"
$lblMassTitle.Location = New-Object System.Drawing.Point(10, 10)
$lblMassTitle.Size = New-Object System.Drawing.Size(430, 25)
$lblMassTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$lblMassTitle.ForeColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$panelMassServers.Controls.Add($lblMassTitle)


$lblFilterTags = New-Object System.Windows.Forms.Label
$lblFilterTags.Text = "🏷️ Filtrar por Etiquetas:"
$lblFilterTags.Location = New-Object System.Drawing.Point(10, 45)
$lblFilterTags.Size = New-Object System.Drawing.Size(150, 20)
$panelMassServers.Controls.Add($lblFilterTags)

$cmbFilterTags = New-Object System.Windows.Forms.ComboBox
$cmbFilterTags.Location = New-Object System.Drawing.Point(10, 68)
$cmbFilterTags.Size = New-Object System.Drawing.Size(320, 25)
$cmbFilterTags.DropDownStyle = "DropDownList"
$panelMassServers.Controls.Add($cmbFilterTags)

$btnFilterByTag = New-Object System.Windows.Forms.Button
$btnFilterByTag.Text = "Filtrar"
$btnFilterByTag.Location = New-Object System.Drawing.Point(340, 66)
$btnFilterByTag.Size = New-Object System.Drawing.Size(90, 27)
$btnFilterByTag.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnFilterByTag.ForeColor = [System.Drawing.Color]::White
$btnFilterByTag.FlatStyle = "Flat"
$panelMassServers.Controls.Add($btnFilterByTag)


$lblServerList = New-Object System.Windows.Forms.Label
$lblServerList.Text = "Servidores Disponibles (0 seleccionados):"
$lblServerList.Location = New-Object System.Drawing.Point(10, 105)
$lblServerList.Size = New-Object System.Drawing.Size(430, 20)
$panelMassServers.Controls.Add($lblServerList)

$chkListServers = New-Object System.Windows.Forms.CheckedListBox
$chkListServers.Location = New-Object System.Drawing.Point(10, 130)
$chkListServers.Size = New-Object System.Drawing.Size(430, 400)
$chkListServers.CheckOnClick = $true
$panelMassServers.Controls.Add($chkListServers)


$btnSelectAll = New-Object System.Windows.Forms.Button
$btnSelectAll.Text = "✓ Todos"
$btnSelectAll.Location = New-Object System.Drawing.Point(10, 540)
$btnSelectAll.Size = New-Object System.Drawing.Size(100, 30)
$btnSelectAll.BackColor = [System.Drawing.Color]::FromArgb(40, 167, 69)
$btnSelectAll.ForeColor = [System.Drawing.Color]::White
$btnSelectAll.FlatStyle = "Flat"
$panelMassServers.Controls.Add($btnSelectAll)

$btnSelectNone = New-Object System.Windows.Forms.Button
$btnSelectNone.Text = "✗ Ninguno"
$btnSelectNone.Location = New-Object System.Drawing.Point(120, 540)
$btnSelectNone.Size = New-Object System.Drawing.Size(100, 30)
$btnSelectNone.BackColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
$btnSelectNone.ForeColor = [System.Drawing.Color]::White
$btnSelectNone.FlatStyle = "Flat"
$panelMassServers.Controls.Add($btnSelectNone)

$btnRefreshMassServers = New-Object System.Windows.Forms.Button
$btnRefreshMassServers.Text = "🔄 Actualizar"
$btnRefreshMassServers.Location = New-Object System.Drawing.Point(230, 540)
$btnRefreshMassServers.Size = New-Object System.Drawing.Size(100, 30)
$btnRefreshMassServers.BackColor = [System.Drawing.Color]::FromArgb(108, 117, 125)
$btnRefreshMassServers.ForeColor = [System.Drawing.Color]::White
$btnRefreshMassServers.FlatStyle = "Flat"
$panelMassServers.Controls.Add($btnRefreshMassServers)


$panelMassConfig = New-Object System.Windows.Forms.Panel
$panelMassConfig.Location = New-Object System.Drawing.Point(470, 10)
$panelMassConfig.Size = New-Object System.Drawing.Size(500, 600)
$panelMassConfig.BorderStyle = "FixedSingle"
$panelMassConfig.BackColor = [System.Drawing.Color]::FromArgb(250, 250, 250)
$tabPageMassInstall.Controls.Add($panelMassConfig)


$lblConfigTitle = New-Object System.Windows.Forms.Label
$lblConfigTitle.Text = "⚙️ Configuración de Instalación"
$lblConfigTitle.Location = New-Object System.Drawing.Point(10, 10)
$lblConfigTitle.Size = New-Object System.Drawing.Size(480, 25)
$lblConfigTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$lblConfigTitle.ForeColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$panelMassConfig.Controls.Add($lblConfigTitle)


$lblInstaller = New-Object System.Windows.Forms.Label
$lblInstaller.Text = "📦 Archivo Instalador:"
$lblInstaller.Location = New-Object System.Drawing.Point(10, 50)
$lblInstaller.Size = New-Object System.Drawing.Size(480, 20)
$panelMassConfig.Controls.Add($lblInstaller)

$txtInstallerPath = New-Object System.Windows.Forms.TextBox
$txtInstallerPath.Location = New-Object System.Drawing.Point(10, 75)
$txtInstallerPath.Size = New-Object System.Drawing.Size(380, 25)
$txtInstallerPath.ReadOnly = $true
$panelMassConfig.Controls.Add($txtInstallerPath)

$btnBrowseInstaller = New-Object System.Windows.Forms.Button
$btnBrowseInstaller.Text = "📂 Buscar"
$btnBrowseInstaller.Location = New-Object System.Drawing.Point(400, 73)
$btnBrowseInstaller.Size = New-Object System.Drawing.Size(90, 27)
$btnBrowseInstaller.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnBrowseInstaller.ForeColor = [System.Drawing.Color]::White
$btnBrowseInstaller.FlatStyle = "Flat"
$panelMassConfig.Controls.Add($btnBrowseInstaller)


$lblParams = New-Object System.Windows.Forms.Label
$lblParams.Text = "⚙️ Parámetros de Instalación:"
$lblParams.Location = New-Object System.Drawing.Point(10, 115)
$lblParams.Size = New-Object System.Drawing.Size(480, 20)
$panelMassConfig.Controls.Add($lblParams)

$txtInstallParams = New-Object System.Windows.Forms.TextBox
$txtInstallParams.Location = New-Object System.Drawing.Point(10, 140)
$txtInstallParams.Size = New-Object System.Drawing.Size(480, 25)
$txtInstallParams.Text = "/silent /norestart"
$panelMassConfig.Controls.Add($txtInstallParams)


$chkParallel = New-Object System.Windows.Forms.CheckBox
$chkParallel.Text = "⚡ Instalación Paralela (más rápido)"
$chkParallel.Location = New-Object System.Drawing.Point(10, 180)
$chkParallel.Size = New-Object System.Drawing.Size(480, 25)
$chkParallel.Checked = $true
$panelMassConfig.Controls.Add($chkParallel)

$chkStopOnError = New-Object System.Windows.Forms.CheckBox
$chkStopOnError.Text = "🛑 Detener si hay error"
$chkStopOnError.Location = New-Object System.Drawing.Point(10, 210)
$chkStopOnError.Size = New-Object System.Drawing.Size(480, 25)
$panelMassConfig.Controls.Add($chkStopOnError)


$lblPreview = New-Object System.Windows.Forms.Label
$lblPreview.Text = "👁️ Vista Previa:"
$lblPreview.Location = New-Object System.Drawing.Point(10, 250)
$lblPreview.Size = New-Object System.Drawing.Size(480, 20)
$lblPreview.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$panelMassConfig.Controls.Add($lblPreview)

$txtPreview = New-Object System.Windows.Forms.TextBox
$txtPreview.Location = New-Object System.Drawing.Point(10, 275)
$txtPreview.Size = New-Object System.Drawing.Size(480, 120)
$txtPreview.Multiline = $true
$txtPreview.ReadOnly = $true
$txtPreview.ScrollBars = "Vertical"
$txtPreview.BackColor = [System.Drawing.Color]::White
$txtPreview.Text = "Selecciona servidores y un instalador para ver la vista previa..."
$panelMassConfig.Controls.Add($txtPreview)


$lblProgress = New-Object System.Windows.Forms.Label
$lblProgress.Text = "📊 Progreso:"
$lblProgress.Location = New-Object System.Drawing.Point(10, 410)
$lblProgress.Size = New-Object System.Drawing.Size(480, 20)
$lblProgress.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$panelMassConfig.Controls.Add($lblProgress)

$progressMass = New-Object System.Windows.Forms.ProgressBar
$progressMass.Location = New-Object System.Drawing.Point(10, 435)
$progressMass.Size = New-Object System.Drawing.Size(480, 25)
$panelMassConfig.Controls.Add($progressMass)

$txtProgressLog = New-Object System.Windows.Forms.TextBox
$txtProgressLog.Location = New-Object System.Drawing.Point(10, 470)
$txtProgressLog.Size = New-Object System.Drawing.Size(480, 80)
$txtProgressLog.Multiline = $true
$txtProgressLog.ReadOnly = $true
$txtProgressLog.ScrollBars = "Vertical"
$txtProgressLog.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
$panelMassConfig.Controls.Add($txtProgressLog)


$btnMassInstall = New-Object System.Windows.Forms.Button
$btnMassInstall.Text = "🚀 INSTALAR EN SERVIDORES SELECCIONADOS"
$btnMassInstall.Location = New-Object System.Drawing.Point(10, 560)
$btnMassInstall.Size = New-Object System.Drawing.Size(480, 35)
$btnMassInstall.BackColor = [System.Drawing.Color]::FromArgb(40, 167, 69)
$btnMassInstall.ForeColor = [System.Drawing.Color]::White
$btnMassInstall.FlatStyle = "Flat"
$btnMassInstall.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnMassInstall.Enabled = $false
$panelMassConfig.Controls.Add($btnMassInstall)



function Refresh-Software {
    try {
        if (-not $global:selectedServer) {
            $lblSoftwareStatus.Text = "❌ No hay servidor seleccionado"
            $lblSoftwareStatus.ForeColor = [System.Drawing.Color]::Red
            return
        }
        
        $lblSoftwareStatus.Text = "⏳ Obteniendo lista de software..."
        $lblSoftwareStatus.ForeColor = [System.Drawing.Color]::Blue
        
        $softwareList = Get-RemoteSoftware -RemoteServer $global:selectedServer.IP `
            -RemotePort $Global:puerto `
            -ClientCertificate $global:clientCertificate
        
        if ($softwareList -and $softwareList.success) {
            
            $softwareArray = [System.Collections.ArrayList]@()
            foreach ($sw in $softwareList.software) {
                $softwareArray.Add($sw) | Out-Null
            }
            
            $dataGridSoftware.DataSource = $softwareArray
            $dataGridSoftware.Refresh()
            
            $lblSoftwareStatus.Text = "✓ Software cargado: $($softwareArray.Count) aplicaciones"
            $lblSoftwareStatus.ForeColor = [System.Drawing.Color]::Green
        }
        else {
            $errorMsg = if ($softwareList.message) { $softwareList.message } else { "Error desconocido" }
            $lblSoftwareStatus.Text = "❌ Error: $errorMsg"
            $lblSoftwareStatus.ForeColor = [System.Drawing.Color]::Red
        }
    }
    catch {
        $lblSoftwareStatus.Text = "❌ Error al obtener software: $_"
        $lblSoftwareStatus.ForeColor = [System.Drawing.Color]::Red
    }
}


$dataGridSoftware.Add_SelectionChanged({
        if ($dataGridSoftware.SelectedRows.Count -gt 0) {
            $selectedSoftware = $dataGridSoftware.SelectedRows[0]
            
            $swName = $selectedSoftware.Cells["Name"].Value
            $swVersion = $selectedSoftware.Cells["Version"].Value
            $swVendor = $selectedSoftware.Cells["Vendor"].Value
            $swInstallDate = $selectedSoftware.Cells["InstallDate"].Value
            
            $info = @"
Nombre: $swName

Versión: $swVersion

Fabricante: $swVendor

Fecha de Instalación: $swInstallDate

Estado: Instalado
"@
            
            $txtSoftwareInfo.Text = $info
            $btnUninstallSoftware.Enabled = $true
        }
        else {
            $txtSoftwareInfo.Text = "Selecciona un software de la lista para ver su información"
            $btnUninstallSoftware.Enabled = $false
        }
    })


$btnUninstallSoftware.Add_Click({
        if ($dataGridSoftware.SelectedRows.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show(
                "Por favor selecciona un software primero",
                "Advertencia",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            return
        }
        
        $selectedSoftware = $dataGridSoftware.SelectedRows[0]
        $softwareName = $selectedSoftware.Cells["Name"].Value
        
        $result = [System.Windows.Forms.MessageBox]::Show(
            "¿Está seguro de desinstalar '$softwareName'?`n`nEsta acción no se puede deshacer.",
            "Confirmar Desinstalación",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        
        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
            try {
                $lblSoftwareStatus.Text = "⏳ Desinstalando '$softwareName'..."
                $lblSoftwareStatus.ForeColor = [System.Drawing.Color]::Blue
                
                $response = Uninstall-RemoteSoftware -RemoteServer $global:selectedServer.IP `
                    -RemotePort $Global:puerto `
                    -SoftwareName $softwareName `
                    -ClientCertificate $global:clientCertificate
                
                if ($response.success) {
                    $lblSoftwareStatus.Text = "✓ Software desinstalado correctamente"
                    $lblSoftwareStatus.ForeColor = [System.Drawing.Color]::Green
                    
                    [System.Windows.Forms.MessageBox]::Show(
                        "Software desinstalado exitosamente.`n`nActualiza la lista para ver los cambios.",
                        "Desinstalación Exitosa",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Information
                    )
                    
                    Refresh-Software
                }
                else {
                    $errorMsg = if ($response.message) { $response.message } else { "Error desconocido" }
                    $lblSoftwareStatus.Text = "❌ Error: $errorMsg"
                    $lblSoftwareStatus.ForeColor = [System.Drawing.Color]::Red
                    
                    [System.Windows.Forms.MessageBox]::Show(
                        "Error al desinstalar: $errorMsg",
                        "Error",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Error
                    )
                }
            }
            catch {
                $lblSoftwareStatus.Text = "❌ Error al desinstalar: $_"
                $lblSoftwareStatus.ForeColor = [System.Drawing.Color]::Red
            }
        }
    })


$btnInstallSoftware.Add_Click({
        $openDialog = New-Object System.Windows.Forms.OpenFileDialog
        $openDialog.Filter = "Instaladores|*.msi;*.exe|Todos los archivos|*.*"
        $openDialog.Title = "Seleccionar instalador"
        
        if ($openDialog.ShowDialog() -eq "OK") {
            $installerPath = $openDialog.FileName
            $installerName = [System.IO.Path]::GetFileName($installerPath)
            
            $result = [System.Windows.Forms.MessageBox]::Show(
                "¿Instalar '$installerName' en el servidor remoto?`n`nEl archivo se copiará y ejecutará automáticamente con parámetros predeterminados.",
                "Confirmar Instalación",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )
            
            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                try {
                    $lblSoftwareStatus.Text = "⏳ Instalando '$installerName'..."
                    $lblSoftwareStatus.ForeColor = [System.Drawing.Color]::Blue
                    
                    $response = Install-RemoteSoftware -RemoteServer $global:selectedServer.IP `
                        -RemotePort $Global:puerto `
                        -InstallerPath $installerPath `
                        -ClientCertificate $global:clientCertificate
                    
                    if ($response.success) {
                        $lblSoftwareStatus.Text = "✓ Instalación completada"
                        $lblSoftwareStatus.ForeColor = [System.Drawing.Color]::Green
                        
                        $exitCode = if ($response.ExitCode) { $response.ExitCode } else { "0" }
                        [System.Windows.Forms.MessageBox]::Show(
                            "Instalación completada.`n`nCódigo de salida: $exitCode`n`nActualiza la lista para ver los cambios.",
                            "Instalación Completada",
                            [System.Windows.Forms.MessageBoxButtons]::OK,
                            [System.Windows.Forms.MessageBoxIcon]::Information
                        )
                        
                        Refresh-Software
                    }
                    else {
                        $errorMsg = if ($response.message) { $response.message } else { "Error desconocido" }
                        $lblSoftwareStatus.Text = "❌ Error: $errorMsg"
                        $lblSoftwareStatus.ForeColor = [System.Drawing.Color]::Red
                        
                        [System.Windows.Forms.MessageBox]::Show(
                            "Error al instalar: $errorMsg",
                            "Error",
                            [System.Windows.Forms.MessageBoxButtons]::OK,
                            [System.Windows.Forms.MessageBoxIcon]::Error
                        )
                    }
                }
                catch {
                    $lblSoftwareStatus.Text = "❌ Error al instalar: $_"
                    $lblSoftwareStatus.ForeColor = [System.Drawing.Color]::Red
                }
            }
        }
    })


$btnInstallWithParams.Add_Click({
        $openDialog = New-Object System.Windows.Forms.OpenFileDialog
        $openDialog.Filter = "Instaladores|*.msi;*.exe|Todos los archivos|*.*"
        $openDialog.Title = "Seleccionar instalador"
        
        if ($openDialog.ShowDialog() -eq "OK") {
            $installerPath = $openDialog.FileName
            $installerName = [System.IO.Path]::GetFileName($installerPath)
            $extension = [System.IO.Path]::GetExtension($installerPath).ToLower()
            
            
            $paramForm = New-Object System.Windows.Forms.Form
            $paramForm.Text = "Parámetros de Instalación"
            $paramForm.Size = New-Object System.Drawing.Size(500, 250)
            $paramForm.StartPosition = "CenterScreen"
            $paramForm.FormBorderStyle = "FixedDialog"
            $paramForm.MaximizeBox = $false
            $paramForm.MinimizeBox = $false
            
            $lblInfo = New-Object System.Windows.Forms.Label
            $lblInfo.Text = "Instalador: $installerName`nTipo: $extension"
            $lblInfo.Location = New-Object System.Drawing.Point(10, 10)
            $lblInfo.Size = New-Object System.Drawing.Size(470, 40)
            $paramForm.Controls.Add($lblInfo)
            
            $lblParams = New-Object System.Windows.Forms.Label
            $lblParams.Text = "Parámetros de instalación:"
            $lblParams.Location = New-Object System.Drawing.Point(10, 60)
            $lblParams.Size = New-Object System.Drawing.Size(470, 20)
            $paramForm.Controls.Add($lblParams)
            
            $txtParams = New-Object System.Windows.Forms.TextBox
            $txtParams.Location = New-Object System.Drawing.Point(10, 85)
            $txtParams.Size = New-Object System.Drawing.Size(470, 25)
            $txtParams.Font = New-Object System.Drawing.Font("Consolas", 10)
            
            
            if ($extension -eq ".msi") {
                $txtParams.Text = "/quiet /norestart INSTALLDIR=`"C:\Program Files\App`""
            }
            else {
                $txtParams.Text = "/S /silent /D=C:\Program Files\App"
            }
            $paramForm.Controls.Add($txtParams)
            
            $lblHelp = New-Object System.Windows.Forms.Label
            $lblHelp.Text = if ($extension -eq ".msi") {
                "Ejemplos MSI:`n/quiet /norestart - Instalación silenciosa`n/qn INSTALLDIR=`"ruta`" - Directorio personalizado"
            }
            else {
                "Ejemplos EXE:`n/S - Instalación silenciosa (NSIS)`n/silent /quiet - Silencioso (otros)`n/D=ruta - Directorio destino"
            }
            $lblHelp.Location = New-Object System.Drawing.Point(10, 120)
            $lblHelp.Size = New-Object System.Drawing.Size(470, 60)
            $lblHelp.ForeColor = [System.Drawing.Color]::Gray
            $paramForm.Controls.Add($lblHelp)
            
            $btnOK = New-Object System.Windows.Forms.Button
            $btnOK.Text = "Instalar"
            $btnOK.Location = New-Object System.Drawing.Point(280, 185)
            $btnOK.Size = New-Object System.Drawing.Size(100, 30)
            $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $paramForm.Controls.Add($btnOK)
            $paramForm.AcceptButton = $btnOK
            
            $btnCancel = New-Object System.Windows.Forms.Button
            $btnCancel.Text = "Cancelar"
            $btnCancel.Location = New-Object System.Drawing.Point(390, 185)
            $btnCancel.Size = New-Object System.Drawing.Size(90, 30)
            $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
            $paramForm.Controls.Add($btnCancel)
            $paramForm.CancelButton = $btnCancel
            
            if ($paramForm.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $customParams = $txtParams.Text.Trim()
                
                try {
                    $lblSoftwareStatus.Text = "⏳ Instalando '$installerName' con parámetros personalizados..."
                    $lblSoftwareStatus.ForeColor = [System.Drawing.Color]::Blue
                    
                    $response = Install-RemoteSoftware -RemoteServer $global:selectedServer.IP `
                        -RemotePort $Global:puerto `
                        -InstallerPath $installerPath `
                        -CustomParams $customParams `
                        -ClientCertificate $global:clientCertificate
                    
                    if ($response.success) {
                        $lblSoftwareStatus.Text = "✓ Instalación completada"
                        $lblSoftwareStatus.ForeColor = [System.Drawing.Color]::Green
                        
                        $exitCode = if ($response.ExitCode) { $response.ExitCode } else { "0" }
                        [System.Windows.Forms.MessageBox]::Show(
                            "Instalación completada.`n`nParámetros: $customParams`nCódigo de salida: $exitCode`n`nActualiza la lista para ver los cambios.",
                            "Instalación Completada",
                            [System.Windows.Forms.MessageBoxButtons]::OK,
                            [System.Windows.Forms.MessageBoxIcon]::Information
                        )
                        
                        Refresh-Software
                    }
                    else {
                        $errorMsg = if ($response.message) { $response.message } else { "Error desconocido" }
                        $lblSoftwareStatus.Text = "❌ Error: $errorMsg"
                        $lblSoftwareStatus.ForeColor = [System.Drawing.Color]::Red
                        
                        [System.Windows.Forms.MessageBox]::Show(
                            "Error al instalar: $errorMsg",
                            "Error",
                            [System.Windows.Forms.MessageBoxButtons]::OK,
                            [System.Windows.Forms.MessageBoxIcon]::Error
                        )
                    }
                }
                catch {
                    $lblSoftwareStatus.Text = "❌ Error al instalar: $_"
                    $lblSoftwareStatus.ForeColor = [System.Drawing.Color]::Red
                }
            }
            
            $paramForm.Dispose()
        }
    })



function Load-MassInstallServers {
    try {
        $chkListServers.Items.Clear()
        $cmbFilterTags.Items.Clear()
        
        
        $cmbFilterTags.Items.Add("(Todos los servidores)") | Out-Null
        $allTags = Get-AllTags
        if ($allTags -and $allTags.Rows.Count -gt 0) {
            foreach ($tag in $allTags.Rows) {
                $tagDisplay = if ($tag.TagCategory) { "$($tag.TagName) ($($tag.TagCategory)) - $($tag.ServerCount) servidor(es)" } else { "$($tag.TagName) - $($tag.ServerCount) servidor(es)" }
                $cmbFilterTags.Items.Add($tagDisplay) | Out-Null
            }
        }
        $cmbFilterTags.SelectedIndex = 0
        
        
        $servers = Get-Servers
        if ($servers -and $servers.Rows.Count -gt 0) {
            foreach ($row in $servers.Rows) {
                $serverDisplay = "$($row['Hostname']) - $($row['IPAddress'])"
                $chkListServers.Items.Add($serverDisplay, $false) | Out-Null
            }
        }
        
        Update-MassInstallPreview
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error al cargar servidores: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Update-MassInstallPreview {
    $selectedCount = $chkListServers.CheckedItems.Count
    $lblServerList.Text = "Servidores Disponibles ($selectedCount seleccionados):"
    
    if ($selectedCount -gt 0 -and $txtInstallerPath.Text) {
        $installerName = [System.IO.Path]::GetFileName($txtInstallerPath.Text)
        $params = $txtInstallParams.Text
        
        $preview = @"
📦 Instalador: $installerName
⚙️ Parámetros: $params
🖥️ Servidores: $selectedCount

Servidores seleccionados:
"@
        
        foreach ($item in $chkListServers.CheckedItems) {
            $preview += "`n  • $item"
        }
        
        $txtPreview.Text = $preview
        $btnMassInstall.Enabled = $true
    }
    else {
        $txtPreview.Text = "Selecciona servidores y un instalador para ver la vista previa..."
        $btnMassInstall.Enabled = $false
    }
}


$btnRefreshMassServers.Add_Click({
        Load-MassInstallServers
    })


$btnSelectAll.Add_Click({
        for ($i = 0; $i -lt $chkListServers.Items.Count; $i++) {
            $chkListServers.SetItemChecked($i, $true)
        }
        Update-MassInstallPreview
    })


$btnSelectNone.Add_Click({
        for ($i = 0; $i -lt $chkListServers.Items.Count; $i++) {
            $chkListServers.SetItemChecked($i, $false)
        }
        Update-MassInstallPreview
    })


$chkListServers.Add_ItemCheck({
        
        $form.BeginInvoke([Action] { Update-MassInstallPreview })
    })


$btnFilterByTag.Add_Click({
        try {
            $chkListServers.Items.Clear()
            
            $selectedTag = $cmbFilterTags.SelectedItem
            if (-not $selectedTag -or $selectedTag -eq "(Todos los servidores)") {
                
                $servers = Get-Servers
                if ($servers -and $servers.Rows.Count -gt 0) {
                    foreach ($row in $servers.Rows) {
                        $serverDisplay = "$($row['Hostname']) - $($row['IPAddress'])"
                        $chkListServers.Items.Add($serverDisplay, $false) | Out-Null
                    }
                }
            }
            else {
                
                $tagName = if ($selectedTag -match '^(.+?)\s+\(') { $matches[1] } else { $selectedTag -replace '\s+-\s+\d+\s+servidor.*$', '' }
                
                
                $servers = Get-ServersByTag -TagNames @($tagName)
                if ($servers -and $servers.Rows.Count -gt 0) {
                    foreach ($row in $servers.Rows) {
                        $serverDisplay = "$($row['Hostname']) - $($row['IPAddress'])"
                        $chkListServers.Items.Add($serverDisplay, $false) | Out-Null
                    }
                }
            }
            
            Update-MassInstallPreview
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Error al filtrar: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })


$btnBrowseInstaller.Add_Click({
        $openDialog = New-Object System.Windows.Forms.OpenFileDialog
        $openDialog.Filter = "Instaladores|*.msi;*.exe|Todos los archivos|*.*"
        $openDialog.Title = "Seleccionar instalador"
        
        if ($openDialog.ShowDialog() -eq "OK") {
            $txtInstallerPath.Text = $openDialog.FileName
            Update-MassInstallPreview
        }
    })


$btnMassInstall.Add_Click({
        $selectedCount = $chkListServers.CheckedItems.Count
        
        if ($selectedCount -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Por favor selecciona al menos un servidor", "Advertencia", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
        
        if (-not $txtInstallerPath.Text) {
            [System.Windows.Forms.MessageBox]::Show("Por favor selecciona un instalador", "Advertencia", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
        
        $installerName = [System.IO.Path]::GetFileName($txtInstallerPath.Text)
        $result = [System.Windows.Forms.MessageBox]::Show(
            "¿Instalar '$installerName' en $selectedCount servidor(es)?`n`nEsta operación no se puede deshacer.",
            "Confirmar Instalación Masiva",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        
        if ($result -ne [System.Windows.Forms.DialogResult]::Yes) {
            return
        }
        
        
        $btnMassInstall.Enabled = $false
        $btnBrowseInstaller.Enabled = $false
        $chkListServers.Enabled = $false
        
        
        $progressMass.Value = 0
        $progressMass.Maximum = $selectedCount
        $txtProgressLog.Clear()
        
        $installerPath = $txtInstallerPath.Text
        $customParams = $txtInstallParams.Text
        $useParallel = $chkParallel.Checked
        $stopOnError = $chkStopOnError.Checked
        
        $successCount = 0
        $errorCount = 0
        
        try {
            if ($useParallel) {
                
                $txtProgressLog.AppendText("⚡ Iniciando instalación paralela...`r`n")
                
                $jobs = @()
                foreach ($item in $chkListServers.CheckedItems) {
                    $serverInfo = $item.ToString() -split ' - '
                    $hostname = $serverInfo[0]
                    $serverIP = $serverInfo[1]
                    
                    $txtProgressLog.AppendText("🚀 Iniciando en $hostname...`r`n")
                    
                    
                    $job = Start-Job -ScriptBlock {
                        param($ip, $port, $path, $params, $cert)
                        
                        
                        Import-Module "$using:PSScriptRoot\Modules\SoftwareManagement.psm1" -Force
                        
                        Install-RemoteSoftware -RemoteServer $ip -RemotePort $port -InstallerPath $path -CustomParams $params -ClientCertificate $cert
                    } -ArgumentList $serverIP, $Global:puerto, $installerPath, $customParams, $global:clientCertificate
                    
                    $jobs += @{ Job = $job; Hostname = $hostname; IP = $serverIP }
                }
                
                
                foreach ($jobInfo in $jobs) {
                    $job = $jobInfo.Job
                    $hostname = $jobInfo.Hostname
                    
                    Wait-Job -Job $job | Out-Null
                    $response = Receive-Job -Job $job
                    Remove-Job -Job $job
                    
                    $progressMass.Value++
                    
                    if ($response -and $response.success) {
                        $successCount++
                        $txtProgressLog.AppendText("✅ $hostname - Instalado exitosamente`r`n")
                    }
                    else {
                        $errorCount++
                        $errorMsg = if ($response.message) { $response.message } else { "Error desconocido" }
                        $txtProgressLog.AppendText("❌ $hostname - Error: $errorMsg`r`n")
                        
                        if ($stopOnError) {
                            $txtProgressLog.AppendText("🛑 Deteniendo instalación por error`r`n")
                            break
                        }
                    }
                }
            }
            else {
                
                $txtProgressLog.AppendText("📋 Iniciando instalación secuencial...`r`n")
                
                foreach ($item in $chkListServers.CheckedItems) {
                    $serverInfo = $item.ToString() -split ' - '
                    $hostname = $serverInfo[0]
                    $serverIP = $serverInfo[1]
                    
                    $txtProgressLog.AppendText("⏳ Instalando en $hostname...`r`n")
                    
                    try {
                        $response = Install-RemoteSoftware -RemoteServer $serverIP `
                            -RemotePort $Global:puerto `
                            -InstallerPath $installerPath `
                            -CustomParams $customParams `
                            -ClientCertificate $global:clientCertificate
                        
                        if ($response -and $response.success) {
                            $successCount++
                            $txtProgressLog.AppendText("✅ $hostname - Instalado exitosamente`r`n")
                        }
                        else {
                            $errorCount++
                            $errorMsg = if ($response.message) { $response.message } else { "Error desconocido" }
                            $txtProgressLog.AppendText("❌ $hostname - Error: $errorMsg`r`n")
                            
                            if ($stopOnError) {
                                $txtProgressLog.AppendText("🛑 Deteniendo instalación por error`r`n")
                                break
                            }
                        }
                    }
                    catch {
                        $errorCount++
                        $txtProgressLog.AppendText("❌ $hostname - Excepción: $_`r`n")
                        
                        if ($stopOnError) {
                            $txtProgressLog.AppendText("🛑 Deteniendo instalación por error`r`n")
                            break
                        }
                    }
                    
                    $progressMass.Value++
                }
            }
            
            
            $txtProgressLog.AppendText("`r`n=== RESUMEN ===`r`n")
            $txtProgressLog.AppendText("✅ Exitosos: $successCount`r`n")
            $txtProgressLog.AppendText("❌ Errores: $errorCount`r`n")
            $txtProgressLog.AppendText("📊 Total: $selectedCount`r`n")
            
            [System.Windows.Forms.MessageBox]::Show(
                "Instalación masiva completada`n`nExitosos: $successCount`nErrores: $errorCount",
                "Instalación Completada",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        }
        catch {
            $txtProgressLog.AppendText("`r`n❌ ERROR CRÍTICO: $_`r`n")
            [System.Windows.Forms.MessageBox]::Show("Error crítico: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
        finally {
            
            $btnMassInstall.Enabled = $true
            $btnBrowseInstaller.Enabled = $true
            $chkListServers.Enabled = $true
        }
    })


$tabPageMassInstall.Add_Enter({
        Load-MassInstallServers
    })

$form.Add_FormClosing({
        Return-ToServerSelection
        $_.Cancel = $true
    })


$listBox.Add_DoubleClick({
        $selectedItem = $listBox.SelectedItem
        if ($selectedItem) {
            try {
                if ($selectedItem -eq '..') {
                    $currentPath = $listBox.Tag
                    $parentPath = [System.IO.Path]::GetDirectoryName($currentPath)
                    Update-FileList -remoteServer $global:selectedServer.IP -remotePort $Global:puerto -path $parentPath -listBox $listBox -clientCertificate $global:clientCertificate
                    $listBox.Tag = $parentPath
                }
                else {
                    $isDir = Is-RemoteDirectory -itemPath $selectedItem -remoteServer $global:selectedServer.IP -remotePort $Global:puerto -clientCertificate $global:clientCertificate
                    if ($isDir) {
                        Update-FileList -remoteServer $global:selectedServer.IP -remotePort $Global:puerto -path $selectedItem -listBox $listBox -clientCertificate $global:clientCertificate
                        $listBox.Tag = $selectedItem
                    }
                }
            }
            catch {
                [System.Windows.Forms.MessageBox]::Show("Error al navegar: $($_.Exception.Message)", "Error de Acceso", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        }
    })

$serverSelectionForm.ShowDialog()

