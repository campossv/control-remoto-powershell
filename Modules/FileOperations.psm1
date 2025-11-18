


function Update-FileList {
    param (
        [string]$remoteServer,
        [int]$remotePort,
        [string]$path,
        [System.Windows.Forms.ListBox]$listBox,
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$clientCertificate = $null
    )
    $encodedCmd = Format-CommandPacket -action "LIST_FILES" -parameters @($path)
    $response = Send-RemoteCommand -remoteServer $remoteServer -remotePort $remotePort -command $encodedCmd -clientCertificate $clientCertificate
    
    if ($response -and $response.success -and $response.files) {
        $listBox.Items.Clear()
        if ($path -ne [System.IO.Path]::GetPathRoot($path)) {
            $listBox.Items.Add('..')
        }
        foreach ($file in $response.files) {
            $listBox.Items.Add($file)
        }
        $listBox.Tag = $path
    }
    else {
        [System.Windows.Forms.MessageBox]::Show("No se pudieron obtener los archivos. Ruta: $path", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Download-RemoteFile {
    param (
        [string]$selectedFile,
        [string]$remoteServer,
        [int]$remotePort,
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$clientCertificate = $null
    )
    if ($selectedFile) {
        $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
        $saveFileDialog.FileName = [System.IO.Path]::GetFileName($selectedFile)
        
        if ($saveFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $localPath = $saveFileDialog.FileName
            
            
            Write-SessionLog -Level "FILE" -Message "Iniciando descarga de archivo" -Details "Remoto: $selectedFile -> Local: $localPath"
            
            $encodedCmd = Format-CommandPacket -action "DOWNLOAD_FILE" -parameters @($selectedFile)
            $response = Send-RemoteCommand -remoteServer $remoteServer -remotePort $remotePort -command $encodedCmd -clientCertificate $clientCertificate
            
            if ($response.success) {
                $fileContentBase64 = $response.fileContent
                $fileContent = [System.Convert]::FromBase64String($fileContentBase64)
                [System.IO.File]::WriteAllBytes($localPath, $fileContent)
                
                
                $fileSize = $fileContent.Length
                Write-SessionLog -Level "SUCCESS" -Message "Archivo descargado exitosamente" -Details "Archivo: $selectedFile, Tamaño: $([math]::Round($fileSize / 1KB, 2)) KB"
                
                [System.Windows.Forms.MessageBox]::Show("Archivo descargado exitosamente.", "Éxito", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            }
            else {
                
                Write-SessionLog -Level "ERROR" -Message "Error al descargar archivo" -Details "Archivo: $selectedFile, Error: $($response.message)"
            }
        }
    }
    else {
        [System.Windows.Forms.MessageBox]::Show("Por favor selecciona un archivo para descargar.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Upload-RemoteFile {
    param (
        [string]$remotePath,
        [string]$remoteServer,
        [int]$remotePort,
        [System.Windows.Forms.ListBox]$listBox,
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$clientCertificate = $null
    )
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = "Seleccionar archivo para subir"
    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $localPath = $openFileDialog.FileName
        if (-not $remotePath) {
            [System.Windows.Forms.MessageBox]::Show("Por favor, selecciona una carpeta de destino.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }
        $remoteFilePath = Join-Path -Path $remotePath -ChildPath (Split-Path -Leaf $localPath)
        $fileContent = [System.IO.File]::ReadAllBytes($localPath)
        $fileSize = $fileContent.Length
        
        
        Write-SessionLog -Level "FILE" -Message "Iniciando subida de archivo" -Details "Local: $localPath -> Remoto: $remoteFilePath, Tamaño: $([math]::Round($fileSize / 1KB, 2)) KB"
        
        $fileContentBase64 = [System.Convert]::ToBase64String($fileContent)
        $encodedCmd = Format-CommandPacket -action "UPLOAD_FILE" -parameters @($remoteFilePath, $fileContentBase64)
        $response = Send-RemoteCommand -remoteServer $remoteServer -remotePort $remotePort -command $encodedCmd -clientCertificate $clientCertificate
        if ($response.success) {
            
            Write-SessionLog -Level "SUCCESS" -Message "Archivo subido exitosamente" -Details "Archivo: $remoteFilePath"
            
            [System.Windows.Forms.MessageBox]::Show("Archivo subido exitosamente.", "Éxito", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            Update-FileList -remoteServer $remoteServer -remotePort $remotePort -path $remotePath -listBox $listBox -clientCertificate $clientCertificate
        }
        else {
            
            Write-SessionLog -Level "ERROR" -Message "Error al subir archivo" -Details "Archivo: $remoteFilePath, Error: $($response.message)"
        }
    }
}

function Delete-RemoteFile {
    param (
        [string]$selectedFile,
        [string]$remoteServer,
        [int]$remotePort,
        [System.Windows.Forms.ListBox]$listBox,
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$clientCertificate = $null
    )
    if ($selectedFile) {
        
        Write-SessionLog -Level "FILE" -Message "Intentando eliminar archivo" -Details "Archivo: $selectedFile"
        
        $encodedCmd = Format-CommandPacket -action "DELETE_FILE" -parameters @($selectedFile)
        $response = Send-RemoteCommand -remoteServer $remoteServer -remotePort $remotePort -command $encodedCmd -clientCertificate $clientCertificate
        if ($response.success) {
            
            Write-SessionLog -Level "SUCCESS" -Message "Archivo eliminado exitosamente" -Details "Archivo: $selectedFile"
            
            [System.Windows.Forms.MessageBox]::Show($response.message, "Éxito", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            Update-FileList -remoteServer $remoteServer -remotePort $remotePort -path (Split-Path -Parent $selectedFile) -listBox $listBox -clientCertificate $clientCertificate
        }
        else {
            
            Write-SessionLog -Level "ERROR" -Message "Error al eliminar archivo" -Details "Archivo: $selectedFile, Error: $($response.message)"
        }
    }
    else {
        [System.Windows.Forms.MessageBox]::Show("Por favor selecciona un archivo para eliminar.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Copy-RemoteFile {
    param (
        [string]$selectedFile,
        [string]$remoteServer,
        [int]$remotePort
    )
    if ($selectedFile) {
        
        $copyForm = New-Object System.Windows.Forms.Form
        $copyForm.Text = "Copiar Archivo - Destino Remoto"
        $copyForm.Size = New-Object System.Drawing.Size(500, 400)
        $copyForm.StartPosition = "CenterScreen"
        $copyForm.FormBorderStyle = "FixedDialog"
        $copyForm.MaximizeBox = $false
        $copyForm.MinimizeBox = $false

        
        $lblInfo = New-Object System.Windows.Forms.Label
        $lblInfo.Text = "Seleccione el destino para copiar:`n$selectedFile"
        $lblInfo.Location = New-Object System.Drawing.Point(20, 20)
        $lblInfo.Size = New-Object System.Drawing.Size(440, 40)
        $copyForm.Controls.Add($lblInfo)

        
        $txtDestination = New-Object System.Windows.Forms.TextBox
        $txtDestination.Location = New-Object System.Drawing.Point(20, 70)
        $txtDestination.Size = New-Object System.Drawing.Size(340, 20)
        $txtDestination.Text = [System.IO.Path]::GetDirectoryName($selectedFile)
        $copyForm.Controls.Add($txtDestination)

        
        $btnBrowse = New-Object System.Windows.Forms.Button
        $btnBrowse.Text = "Explorar..."
        $btnBrowse.Location = New-Object System.Drawing.Point(370, 68)
        $btnBrowse.Size = New-Object System.Drawing.Size(90, 24)
        $copyForm.Controls.Add($btnBrowse)

        
        $lstDestFiles = New-Object System.Windows.Forms.ListBox
        $lstDestFiles.Location = New-Object System.Drawing.Point(20, 100)
        $lstDestFiles.Size = New-Object System.Drawing.Size(440, 200)
        $lstDestFiles.ScrollAlwaysVisible = $true
        $copyForm.Controls.Add($lstDestFiles)

        
        $btnOK = New-Object System.Windows.Forms.Button
        $btnOK.Text = "Copiar"
        $btnOK.Location = New-Object System.Drawing.Point(300, 320)
        $btnOK.Size = New-Object System.Drawing.Size(70, 30)
        $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $copyForm.Controls.Add($btnOK)

        $btnCancel = New-Object System.Windows.Forms.Button
        $btnCancel.Text = "Cancelar"
        $btnCancel.Location = New-Object System.Drawing.Point(380, 320)
        $btnCancel.Size = New-Object System.Drawing.Size(70, 30)
        $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $copyForm.Controls.Add($btnCancel)

        
        function Update-DestinationList {
            param ([string]$path)
            try {
                $encodedCmd = Format-CommandPacket -action "LIST_FILES" -parameters @($path)
                $response = Send-RemoteCommand -remoteServer $remoteServer -remotePort $remotePort -command $encodedCmd -clientCertificate $clientCertificate
                
                $lstDestFiles.Items.Clear()
                if ($response -and $response.success -and $response.files) {
                    if ($path -ne [System.IO.Path]::GetPathRoot($path)) {
                        $lstDestFiles.Items.Add('..')
                    }
                    foreach ($file in $response.files) {
                        $lstDestFiles.Items.Add($file)
                    }
                    $txtDestination.Text = $path
                }
            }
            catch {
                [System.Windows.Forms.MessageBox]::Show("Error al explorar directorio: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        }

        
        $btnBrowse.Add_Click({
                $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
                $folderBrowser.Description = "Seleccione directorio raíz para explorar en sistema remoto"
                $folderBrowser.ShowNewFolderButton = $false
            
                if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                    Update-DestinationList -path $folderBrowser.SelectedPath
                }
            })

        
        $lstDestFiles.Add_DoubleClick({
                $selectedItem = $lstDestFiles.SelectedItem
                if ($selectedItem) {
                    if ($selectedItem -eq '..') {
                        $currentPath = $txtDestination.Text
                        $parentPath = [System.IO.Path]::GetDirectoryName($currentPath)
                        if ($parentPath) {
                            Update-DestinationList -path $parentPath
                        }
                    }
                    else {
                        $isDir = Is-RemoteDirectory -itemPath $selectedItem -remoteServer $remoteServer -remotePort $remotePort -clientCertificate $clientCertificate
                        if ($isDir) {
                            Update-DestinationList -path $selectedItem
                        }
                    }
                }
            })

        
        Update-DestinationList -path $txtDestination.Text

        
        $result = $copyForm.ShowDialog()
        
        if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
            $destinationPath = $txtDestination.Text.Trim()
            if (-not $destinationPath) {
                [System.Windows.Forms.MessageBox]::Show("Por favor seleccione un destino válido.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                return
            }
            
            
            $fileName = [System.IO.Path]::GetFileName($selectedFile)
            $fullDestination = Join-Path -Path $destinationPath -ChildPath $fileName
            
            
            $encodedCmd = Format-CommandPacket -action "COPY_FILE" -parameters @($selectedFile, $fullDestination)
            $response = Send-RemoteCommand -remoteServer $remoteServer -remotePort $remotePort -command $encodedCmd -clientCertificate $clientCertificate
            
            [System.Windows.Forms.MessageBox]::Show($response.message, "Resultado", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
    }
    else {
        [System.Windows.Forms.MessageBox]::Show("Por favor selecciona un archivo para copiar.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Move-RemoteFile {
    param (
        [string]$selectedFile,
        [string]$remoteServer,
        [int]$remotePort,
        [System.Windows.Forms.ListBox]$listBox,
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$clientCertificate = $null
    )
    if ($selectedFile) {
        
        $moveForm = New-Object System.Windows.Forms.Form
        $moveForm.Text = "Mover Archivo - Destino Remoto"
        $moveForm.Size = New-Object System.Drawing.Size(500, 400)
        $moveForm.StartPosition = "CenterScreen"
        $moveForm.FormBorderStyle = "FixedDialog"
        $moveForm.MaximizeBox = $false
        $moveForm.MinimizeBox = $false

        
        $lblInfo = New-Object System.Windows.Forms.Label
        $lblInfo.Text = "Seleccione el destino para mover:`n$selectedFile"
        $lblInfo.Location = New-Object System.Drawing.Point(20, 20)
        $lblInfo.Size = New-Object System.Drawing.Size(440, 40)
        $moveForm.Controls.Add($lblInfo)

        
        $txtDestination = New-Object System.Windows.Forms.TextBox
        $txtDestination.Location = New-Object System.Drawing.Point(20, 70)
        $txtDestination.Size = New-Object System.Drawing.Size(340, 20)
        $txtDestination.Text = [System.IO.Path]::GetDirectoryName($selectedFile)
        $moveForm.Controls.Add($txtDestination)

        
        $btnBrowse = New-Object System.Windows.Forms.Button
        $btnBrowse.Text = "Explorar..."
        $btnBrowse.Location = New-Object System.Drawing.Point(370, 68)
        $btnBrowse.Size = New-Object System.Drawing.Size(90, 24)
        $moveForm.Controls.Add($btnBrowse)

        
        $lstDestFiles = New-Object System.Windows.Forms.ListBox
        $lstDestFiles.Location = New-Object System.Drawing.Point(20, 100)
        $lstDestFiles.Size = New-Object System.Drawing.Size(440, 200)
        $lstDestFiles.ScrollAlwaysVisible = $true
        $moveForm.Controls.Add($lstDestFiles)

        
        $btnOK = New-Object System.Windows.Forms.Button
        $btnOK.Text = "Mover"
        $btnOK.Location = New-Object System.Drawing.Point(300, 320)
        $btnOK.Size = New-Object System.Drawing.Size(70, 30)
        $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $moveForm.Controls.Add($btnOK)

        $btnCancel = New-Object System.Windows.Forms.Button
        $btnCancel.Text = "Cancelar"
        $btnCancel.Location = New-Object System.Drawing.Point(380, 320)
        $btnCancel.Size = New-Object System.Drawing.Size(70, 30)
        $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $moveForm.Controls.Add($btnCancel)

        
        function Update-DestinationList {
            param ([string]$path)
            try {
                $encodedCmd = Format-CommandPacket -action "LIST_FILES" -parameters @($path)
                $response = Send-RemoteCommand -remoteServer $remoteServer -remotePort $remotePort -command $encodedCmd -clientCertificate $clientCertificate
                
                $lstDestFiles.Items.Clear()
                if ($response -and $response.success -and $response.files) {
                    if ($path -ne [System.IO.Path]::GetPathRoot($path)) {
                        $lstDestFiles.Items.Add('..')
                    }
                    foreach ($file in $response.files) {
                        $lstDestFiles.Items.Add($file)
                    }
                    $txtDestination.Text = $path
                }
            }
            catch {
                [System.Windows.Forms.MessageBox]::Show("Error al explorar directorio: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        }

        
        $btnBrowse.Add_Click({
                $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
                $folderBrowser.Description = "Seleccione directorio raíz para explorar en sistema remoto"
                $folderBrowser.ShowNewFolderButton = $false
            
                if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                    Update-DestinationList -path $folderBrowser.SelectedPath
                }
            })

        
        $lstDestFiles.Add_DoubleClick({
                $selectedItem = $lstDestFiles.SelectedItem
                if ($selectedItem) {
                    if ($selectedItem -eq '..') {
                        $currentPath = $txtDestination.Text
                        $parentPath = [System.IO.Path]::GetDirectoryName($currentPath)
                        if ($parentPath) {
                            Update-DestinationList -path $parentPath
                        }
                    }
                    else {
                        $isDir = Is-RemoteDirectory -itemPath $selectedItem -remoteServer $remoteServer -remotePort $remotePort -clientCertificate $clientCertificate
                        if ($isDir) {
                            Update-DestinationList -path $selectedItem
                        }
                    }
                }
            })

        
        Update-DestinationList -path $txtDestination.Text

        
        $result = $moveForm.ShowDialog()
        
        if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
            $destinationPath = $txtDestination.Text.Trim()
            if (-not $destinationPath) {
                [System.Windows.Forms.MessageBox]::Show("Por favor seleccione un destino válido.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                return
            }
            
            
            $fileName = [System.IO.Path]::GetFileName($selectedFile)
            $fullDestination = Join-Path -Path $destinationPath -ChildPath $fileName
            
            
            $encodedCmd = Format-CommandPacket -action "MOVE_FILE" -parameters @($selectedFile, $fullDestination)
            $response = Send-RemoteCommand -remoteServer $remoteServer -remotePort $remotePort -command $encodedCmd -clientCertificate $clientCertificate
            
            [System.Windows.Forms.MessageBox]::Show($response.message, "Resultado", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            
            
            Update-FileList -remoteServer $remoteServer -remotePort $remotePort -path (Split-Path -Parent $selectedFile) -listBox $listBox -clientCertificate $clientCertificate
        }
    }
    else {
        [System.Windows.Forms.MessageBox]::Show("Por favor selecciona un archivo para mover.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Is-RemoteDirectory {
    param (
        [string]$itemPath,
        [string]$remoteServer,
        [int]$remotePort,
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$clientCertificate = $null
    )
    $encodedCmd = Format-CommandPacket -action "IS_DIRECTORY" -parameters @($itemPath)
    $response = Send-RemoteCommand -remoteServer $remoteServer -remotePort $remotePort -command $encodedCmd -clientCertificate $clientCertificate
    
    if ($response -and $response.success) {
        return $response.isDirectory
    }
    return $false
}

Export-ModuleMember -Function Update-FileList, Download-RemoteFile, Upload-RemoteFile, Delete-RemoteFile, Copy-RemoteFile, Move-RemoteFile, Is-RemoteDirectory

