


function Refresh-Processes {
    param (
        [string]$remoteServer,
        [int]$remotePort,
        [System.Windows.Forms.DataGridView]$dataGrid,
        [string]$filtro = "",
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$clientCertificate = $null
    )
    $encodedCmd = Format-CommandPacket -action "GET_PROCESSES" -parameters @($filtro)
    $procesos = Send-RemoteCommand -remoteServer $remoteServer -remotePort $remotePort -command $encodedCmd -clientCertificate $clientCertificate

    if ($procesos) {
        $dataGrid.DataSource = [System.Collections.ArrayList]@($procesos)
        $dataGrid.Refresh()
    }
}

function Terminate-RemoteProcess {
    param (
        [string]$processId,
        [string]$remoteServer,
        [int]$remotePort,
        [System.Windows.Forms.DataGridView]$dataGrid,
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$clientCertificate = $null
    )
    if ($processId) {
        $encodedCmd = Format-CommandPacket -action "TERMINATE_PROCESS" -parameters @($processId)
        $response = Send-RemoteCommand -remoteServer $remoteServer -remotePort $remotePort -command $encodedCmd -clientCertificate $clientCertificate

        if ($response.success) {
            [System.Windows.Forms.MessageBox]::Show("Proceso detenido exitosamente.", "Éxito", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            Refresh-Processes -remoteServer $remoteServer -remotePort $remotePort -dataGrid $dataGrid -clientCertificate $clientCertificate
        }
        else {
            [System.Windows.Forms.MessageBox]::Show("Error al detener el proceso: $($response.message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
    else {
        [System.Windows.Forms.MessageBox]::Show("Por favor, selecciona un proceso para detener.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

Export-ModuleMember -Function Refresh-Processes, Terminate-RemoteProcess

