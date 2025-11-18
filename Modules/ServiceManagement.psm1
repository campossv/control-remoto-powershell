


function Refresh-Services {
    param (
        [string]$remoteServer,
        [int]$remotePort,
        [System.Windows.Forms.DataGridView]$dataGrid,
        [string]$filtro = "",
        [bool]$excluirMicrosoft = $false,
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$clientCertificate = $null
    )
    $encodedCmd = Format-CommandPacket -action "GET_SERVICES" -parameters @($filtro, [string]$excluirMicrosoft)
    $servicios = Send-RemoteCommand -remoteServer $remoteServer -remotePort $remotePort -command $encodedCmd -clientCertificate $clientCertificate

    if ($servicios) {
        $dataGrid.DataSource = [System.Collections.ArrayList]@($servicios)
        $dataGrid.Refresh()
    }
}

function Start-RemoteService {
    param (
        [string]$serviceName,
        [string]$remoteServer,
        [int]$remotePort,
        [System.Windows.Forms.DataGridView]$dataGrid,
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$clientCertificate = $null
    )
    if ($serviceName) {
        $encodedCmd = Format-CommandPacket -action "START_SERVICE" -parameters @($serviceName)
        $response = Send-RemoteCommand -remoteServer $remoteServer -remotePort $remotePort -command $encodedCmd -clientCertificate $clientCertificate

        if ($response.success) {
            [System.Windows.Forms.MessageBox]::Show("Servicio iniciado exitosamente.", "Éxito", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            Refresh-Services -remoteServer $remoteServer -remotePort $remotePort -dataGrid $dataGrid -clientCertificate $clientCertificate
        } else {
            [System.Windows.Forms.MessageBox]::Show("Error al iniciar el servicio: $($response.message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Por favor, selecciona un servicio para iniciar.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Stop-RemoteService {
    param (
        [string]$serviceName,
        [string]$remoteServer,
        [int]$remotePort,
        [System.Windows.Forms.DataGridView]$dataGrid,
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$clientCertificate = $null
    )
    if ($serviceName) {
        $encodedCmd = Format-CommandPacket -action "STOP_SERVICE" -parameters @($serviceName)
        $response = Send-RemoteCommand -remoteServer $remoteServer -remotePort $remotePort -command $encodedCmd -clientCertificate $clientCertificate
        
        if ($response.success) {
            [System.Windows.Forms.MessageBox]::Show("Servicio detenido exitosamente.", "Éxito", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            Refresh-Services -remoteServer $remoteServer -remotePort $remotePort -dataGrid $dataGrid -clientCertificate $clientCertificate
        } else {
            [System.Windows.Forms.MessageBox]::Show("Error al detener el servicio: $($response.message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Por favor, selecciona un servicio para detener.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Restart-RemoteService {
    param (
        [string]$serviceName,
        [string]$remoteServer,
        [int]$remotePort,
        [System.Windows.Forms.DataGridView]$dataGrid,
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$clientCertificate = $null
    )
    if ($serviceName) {
        $encodedCmd = Format-CommandPacket -action "RESTART_SERVICE" -parameters @($serviceName)
        $response = Send-RemoteCommand -remoteServer $remoteServer -remotePort $remotePort -command $encodedCmd -clientCertificate $clientCertificate
        
        if ($response.success) {
            [System.Windows.Forms.MessageBox]::Show("Servicio reiniciado exitosamente.", "Éxito", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            Refresh-Services -remoteServer $remoteServer -remotePort $remotePort -dataGrid $dataGrid -clientCertificate $clientCertificate
        } else {
            [System.Windows.Forms.MessageBox]::Show("Error al reiniciar el servicio: $($response.message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Por favor, selecciona un servicio para reiniciar.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

Export-ModuleMember -Function Refresh-Services, Start-RemoteService, Stop-RemoteService, Restart-RemoteService

