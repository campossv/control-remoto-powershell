


Import-Module -Name ".\Modules\CertificateAuth.psm1" -Force

Write-Host "[CONFIG] CONFIGURACION DE CERTIFICADOS DE CLIENTE" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan


function Show-Menu {
    Write-Host "`nSeleccione una opcion:" -ForegroundColor Yellow
    Write-Host "1) Generar nuevo certificado de cliente" -ForegroundColor White
    Write-Host "2) Importar certificados de cliente autorizados" -ForegroundColor White
    Write-Host "3) Ver certificados de cliente disponibles" -ForegroundColor White
    Write-Host "4) Validar certificado de cliente" -ForegroundColor White
    Write-Host "5) Limpiar certificados expirados" -ForegroundColor White
    Write-Host "6) Salir" -ForegroundColor White
    Write-Host "`nOpcion: " -NoNewline -ForegroundColor Gray
}


function New-ClientCertificateMenu {
    Write-Host "`n[FORM] GENERAR CERTIFICADO DE CLIENTE" -ForegroundColor Green
    Write-Host "--------------------------------" -ForegroundColor Green
    
    $clientName = Read-Host "Ingrese el nombre del cliente (ej: AdminPC01)"
    $outputPath = Read-Host "Ingrese ruta de salida (Enter para .\Certificates)"
    $password = Read-Host "Ingrese contrasena (Enter para default)" -AsSecureString
    
    if ([string]::IsNullOrWhiteSpace($clientName)) {
        Write-Warning "[ADVERTENCIA] El nombre del cliente no puede estar vacio"
        return
    }
    
    if ([string]::IsNullOrWhiteSpace($outputPath)) {
        $outputPath = ".\Certificates"
    }
    
    if ($password) {
        $passwordText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
        $securePassword = $password
    }
    else {
        $passwordText = "P@ssw0rd123!"
        $securePassword = ConvertTo-SecureString -String $passwordText -Force -AsPlainText
    }
    
    $result = New-ClientCertificate -ClientName $clientName -OutputPath $outputPath -Password $securePassword
    
    if ($result) {
        Write-Host "`n[OK] CERTIFICADO GENERADO EXITOSAMENTE" -ForegroundColor Green
        Write-Host "[RESUMEN] Resumen:" -ForegroundColor Yellow
        Write-Host "   - Cliente: $clientName" -ForegroundColor White
        Write-Host "   - Thumbprint: $($result.Thumbprint)" -ForegroundColor White
        Write-Host "   - Valido hasta: $($result.Certificate.NotAfter)" -ForegroundColor White
        Write-Host "   - Archivos generados:" -ForegroundColor White
        Write-Host "     - Publico: $($result.PublicPath)" -ForegroundColor Gray
        Write-Host "     - Privado: $($result.PrivatePath)" -ForegroundColor Gray
        Write-Host "     - Contrasena: $passwordText" -ForegroundColor Gray
        
        Write-Host "`n[INFO] INSTRUCCIONES:" -ForegroundColor Cyan
        Write-Host "1. Copie el archivo .cer al servidor y ejecutar 'Importar certificados'" -ForegroundColor White
        Write-Host "2. Copie el archivo .pfx al cliente y use 'Cargar certificado'" -ForegroundColor White
        Write-Host "3. La contrasena del certificado es: $passwordText" -ForegroundColor Yellow
    }
}


function Import-ClientCertificatesMenu {
    Write-Host "`n[IMPORT] IMPORTAR CERTIFICADOS AUTORIZADOS" -ForegroundColor Green
    Write-Host "------------------------------------" -ForegroundColor Green
    
    $certPath = Read-Host "Ingrese ruta del directorio con certificados .cer (Enter para .\Certificates)"
    
    if ([string]::IsNullOrWhiteSpace($certPath)) {
        $certPath = ".\Certificates"
    }
    
    if (-not (Test-Path $certPath)) {
        Write-Warning "[ADVERTENCIA] El directorio $certPath no existe"
        return
    }
    
    Write-Host "[BUSQUEDA] Buscando certificados en: $certPath" -ForegroundColor Yellow
    
    $success = Import-TrustedClientCertificates -CertificatesPath $certPath
    
    if ($success) {
        Write-Host "`n[OK] CERTIFICADOS IMPORTADOS EXITOSAMENTE" -ForegroundColor Green
        Write-Host "[SEGURO] El servidor ahora aceptara conexiones de estos clientes" -ForegroundColor White
    }
    else {
        Write-Warning "`n[ERROR] No se pudieron importar certificados"
    }
}


function Show-ClientCertificatesMenu {
    Write-Host "`n[VER] CERTIFICADOS DE CLIENTE DISPONIBLES" -ForegroundColor Green
    Write-Host "---------------------------------------" -ForegroundColor Green
    
    Import-Module -Name ".\Modules\RemoteConnection.psm1" -Force
    $certs = Get-AvailableClientCertificates
    
    if ($certs.Count -eq 0) {
        Write-Warning "[ADVERTENCIA] No se encontraron certificados de cliente disponibles"
        Write-Host "[INFO] Genere un nuevo certificado usando la opcion 1" -ForegroundColor Cyan
        return
    }
    
    Write-Host "[RESUMEN] Se encontraron $($certs.Count) certificados:" -ForegroundColor Yellow
    
    for ($i = 0; $i -lt $certs.Count; $i++) {
        $cert = $certs[$i]
        $daysUntilExpiry = ($cert.NotAfter - (Get-Date)).Days
        
        Write-Host "`n   [$($i+1)] $($cert.Subject)" -ForegroundColor White
        Write-Host "       Thumbprint: $($cert.Thumbprint)" -ForegroundColor Gray
        Write-Host "       Valido hasta: $($cert.NotAfter)" -ForegroundColor Gray
        Write-Host "       Dias restantes: $daysUntilExpiry" -ForegroundColor $(if ($daysUntilExpiry -gt 30) { 'Green' } elseif ($daysUntilExpiry -gt 7) { 'Yellow' } else { 'Red' })
    }
}


function Test-ClientCertificateMenu {
    Write-Host "`n[VALIDAR] VALIDAR CERTIFICADO DE CLIENTE" -ForegroundColor Green
    Write-Host "-----------------------------------" -ForegroundColor Green
    
    $certPath = Read-Host "Ingrese ruta del archivo .pfx a validar"
    
    if ([string]::IsNullOrWhiteSpace($certPath)) {
        Write-Warning "[ADVERTENCIA] La ruta del certificado no puede estar vacia"
        return
    }
    
    if (-not (Test-Path $certPath)) {
        Write-Warning "[ADVERTENCIA] El archivo $certPath no existe"
        return
    }
    
    $password = Read-Host "Ingrese contrasena del certificado" -AsSecureString
    $passwordText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
    
    Write-Host "[VALIDANDO] Validando certificado..." -ForegroundColor Yellow
    
    $isValid = Test-ClientCertificate -CertificatePath $certPath -Password $passwordText
    
    if ($isValid) {
        Write-Host "[OK] El certificado es valido y puede ser usado para autenticacion" -ForegroundColor Green
    }
    else {
        Write-Warning "[ERROR] El certificado no es valido o esta expirado"
    }
}


function Remove-ExpiredCertificatesMenu {
    Write-Host "`n[LIMPIAR] LIMPIAR CERTIFICADOS EXPIRADOS" -ForegroundColor Green
    Write-Host "--------------------------------" -ForegroundColor Green
    
    $confirm = Read-Host "Esta seguro de eliminar certificados expirados? (S/N)"
    
    if ($confirm -ne "S" -and $confirm -ne "s") {
        Write-Host "Operacion cancelada." -ForegroundColor Yellow
        return
    }
    
    Write-Host "[BUSQUEDA] Buscando certificados expirados..." -ForegroundColor Yellow
    
    $removed = Remove-ExpiredClientCertificates
    
    if ($removed -gt 0) {
        Write-Host "[OK] Se eliminaron $removed certificados expirados" -ForegroundColor Green
    }
    else {
        Write-Host "[INFO] No se encontraron certificados expirados" -ForegroundColor Cyan
    }
}


do {
    Show-Menu
    $choice = Read-Host
    
    switch ($choice) {
        "1" { New-ClientCertificateMenu }
        "2" { Import-ClientCertificatesMenu }
        "3" { Show-ClientCertificatesMenu }
        "4" { Test-ClientCertificateMenu }
        "5" { Remove-ExpiredCertificatesMenu }
        "6" { 
            Write-Host "[SALIR] Saliendo del programa..." -ForegroundColor Yellow
            break 
        }
        default { 
            Write-Warning "[ADVERTENCIA] Opcion invalida. Intente nuevamente." 
        }
    }
    
    if ($choice -ne "6") {
        Write-Host "`nPresione Enter para continuar..." -ForegroundColor Gray
        Read-Host
    }
} while ($choice -ne "6")

Write-Host "`n[COMPLETADO] CONFIGURACION COMPLETADA" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green

