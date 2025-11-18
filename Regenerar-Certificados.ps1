


Import-Module -Name ".\Modules\CertificateAuth.psm1" -Force

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  REGENERACIÓN DE CERTIFICADOS" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""


$defaultName = $env:COMPUTERNAME
Write-Host "Nombre del cliente (Enter para usar: $defaultName): " -NoNewline -ForegroundColor Yellow
$clientName = Read-Host
if ([string]::IsNullOrWhiteSpace($clientName)) {
    $clientName = $defaultName
}

Write-Host ""
Write-Host "Contraseña del certificado (Enter para usar: P@ssw0rd123!): " -NoNewline -ForegroundColor Yellow
$passwordInput = Read-Host -AsSecureString


if ($passwordInput.Length -eq 0) {
    $password = ConvertTo-SecureString -String "P@ssw0rd123!" -AsPlainText -Force
    $passwordText = "P@ssw0rd123!"
}
else {
    $password = $passwordInput
    
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
    $passwordText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Generando certificado..." -ForegroundColor Yellow
Write-Host "  Cliente: $clientName" -ForegroundColor White
Write-Host "  Contraseña: $passwordText" -ForegroundColor White
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""


$oldCer = ".\Certificates\$clientName.cer"
$oldPfx = ".\Certificates\$clientName.pfx"

if (Test-Path $oldCer) {
    Write-Host "Eliminando certificado antiguo: $oldCer" -ForegroundColor Yellow
    Remove-Item $oldCer -Force
}

if (Test-Path $oldPfx) {
    Write-Host "Eliminando certificado antiguo: $oldPfx" -ForegroundColor Yellow
    Remove-Item $oldPfx -Force
}

Write-Host ""


$result = New-ClientCertificate -ClientName $clientName -OutputPath ".\Certificates" -Password $password

if ($result) {
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host "  ✅ CERTIFICADO GENERADO EXITOSAMENTE" -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "INFORMACIÓN DEL CERTIFICADO:" -ForegroundColor Cyan
    Write-Host "  • Cliente: $clientName" -ForegroundColor White
    Write-Host "  • Thumbprint: $($result.Thumbprint)" -ForegroundColor White
    Write-Host "  • Válido hasta: $($result.Certificate.NotAfter)" -ForegroundColor White
    Write-Host ""
    Write-Host "ARCHIVOS GENERADOS:" -ForegroundColor Cyan
    Write-Host "  • Público (.cer): $($result.PublicPath)" -ForegroundColor White
    Write-Host "  • Privado (.pfx): $($result.PrivatePath)" -ForegroundColor White
    Write-Host ""
    Write-Host "CONTRASEÑA DEL CERTIFICADO:" -ForegroundColor Yellow
    Write-Host "  $passwordText" -ForegroundColor Green
    Write-Host ""
    Write-Host "PRÓXIMOS PASOS:" -ForegroundColor Cyan
    Write-Host "  1. En el SERVIDOR: Ejecutar Setup-ClientCertificates.ps1" -ForegroundColor White
    Write-Host "     y seleccionar 'Importar certificados de cliente autorizados'" -ForegroundColor White
    Write-Host ""
    Write-Host "  2. En el CLIENTE: Usar el archivo .pfx con la contraseña" -ForegroundColor White
    Write-Host "     mostrada arriba para cargar el certificado" -ForegroundColor White
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Green
}
else {
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Red
    Write-Host "  ❌ ERROR AL GENERAR CERTIFICADO" -ForegroundColor Red
    Write-Host "=========================================" -ForegroundColor Red
    Write-Host ""
}

Write-Host "Presione Enter para salir..." -ForegroundColor Gray
Read-Host

