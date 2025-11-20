<#
.SYNOPSIS
    Script de diagnóstico para verificar la configuración del servidor de Control Remoto.

.DESCRIPTION
    Verifica todos los requisitos y configuraciones necesarias para que el servidor
    de Control Remoto funcione correctamente.

.EXAMPLE
    .\Test-ServerSetup.ps1

.NOTES
    Autor: Vladimir Campos
    Versión: 1.0
    Fecha: Noviembre 2024
#>

[CmdletBinding()]
param()

Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     DIAGNÓSTICO DE CONFIGURACIÓN - CONTROL REMOTO             ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

$allChecksPass = $true

# 1. Verificar versión de PowerShell
Write-Host "1. Versión de PowerShell" -ForegroundColor Yellow
$psVersion = $PSVersionTable.PSVersion
Write-Host "   Versión: $($psVersion.Major).$($psVersion.Minor).$($psVersion.Build)" -ForegroundColor Gray
if ($psVersion.Major -ge 5 -and $psVersion.Minor -ge 1) {
    Write-Host "   ✅ PowerShell 5.1 o superior - OK" -ForegroundColor Green
}
else {
    Write-Host "   ❌ Se requiere PowerShell 5.1 o superior" -ForegroundColor Red
    $allChecksPass = $false
}

# 2. Verificar permisos de administrador
Write-Host "`n2. Permisos de Administrador" -ForegroundColor Yellow
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    Write-Host "   ✅ Ejecutando como Administrador - OK" -ForegroundColor Green
}
else {
    Write-Host "   ❌ NO se está ejecutando como Administrador" -ForegroundColor Red
    Write-Host "   Ejecutar: Start-Process powershell -Verb RunAs" -ForegroundColor Yellow
    $allChecksPass = $false
}

# 3. Verificar .NET Framework
Write-Host "`n3. .NET Framework" -ForegroundColor Yellow
try {
    $netVersion = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -Name Release -ErrorAction Stop
    if ($netVersion -ge 461808) {
        Write-Host "   ✅ .NET Framework 4.7.2 o superior - OK" -ForegroundColor Green
    }
    else {
        Write-Host "   ⚠️ .NET Framework antiguo (versión: $netVersion)" -ForegroundColor Yellow
        Write-Host "   Recomendado: .NET Framework 4.8" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "   ❌ No se pudo verificar .NET Framework" -ForegroundColor Red
    $allChecksPass = $false
}

# 4. Verificar puerto 4430 disponible
Write-Host "`n4. Disponibilidad del Puerto 4430" -ForegroundColor Yellow
$portInUse = Get-NetTCPConnection -LocalPort 4430 -ErrorAction SilentlyContinue
if ($portInUse) {
    $process = Get-Process -Id $portInUse.OwningProcess -ErrorAction SilentlyContinue
    Write-Host "   ❌ Puerto 4430 EN USO" -ForegroundColor Red
    Write-Host "   Proceso: $($process.ProcessName) (PID: $($process.Id))" -ForegroundColor Gray
    Write-Host "   Solución: Stop-Process -Id $($process.Id) -Force" -ForegroundColor Yellow
    $allChecksPass = $false
}
else {
    Write-Host "   ✅ Puerto 4430 DISPONIBLE - OK" -ForegroundColor Green
}
Write-Host "`n4. Disponibilidad del Puerto 5000" -ForegroundColor Yellow
$portInUse = Get-NetTCPConnection -LocalPort 5000 -ErrorAction SilentlyContinue
if ($portInUse) {
    $process = Get-Process -Id $portInUse.OwningProcess -ErrorAction SilentlyContinue
    Write-Host "   ❌ Puerto 5000 EN USO" -ForegroundColor Red
    Write-Host "   Proceso: $($process.ProcessName) (PID: $($process.Id))" -ForegroundColor Gray
    Write-Host "   Solución: Stop-Process -Id $($process.Id) -Force" -ForegroundColor Yellow
    $allChecksPass = $false
}
else {
    Write-Host "   ✅ Puerto 5000 DISPONIBLE - OK" -ForegroundColor Green
}
# 5. Verificar certificado SSL
Write-Host "`n5. Certificado SSL" -ForegroundColor Yellow
$cert = Get-ChildItem Cert:\LocalMachine\My -ErrorAction SilentlyContinue | Where-Object { $_.Subject -like "*ServidorRemoto*" }
if ($cert) {
    Write-Host "   ✅ Certificado encontrado - OK" -ForegroundColor Green
    Write-Host "   Subject: $($cert.Subject)" -ForegroundColor Gray
    Write-Host "   Válido desde: $($cert.NotBefore)" -ForegroundColor Gray
    Write-Host "   Expira: $($cert.NotAfter)" -ForegroundColor Gray
    
    # Verificar si está expirado
    if ($cert.NotAfter -lt (Get-Date)) {
        Write-Host "   ⚠️ CERTIFICADO EXPIRADO" -ForegroundColor Red
        Write-Host "   Solución: .\Regenerar-Certificados.ps1" -ForegroundColor Yellow
        $allChecksPass = $false
    }
}
else {
    Write-Host "   ❌ Certificado NO encontrado" -ForegroundColor Red
    Write-Host "   Solución: .\Regenerar-Certificados.ps1" -ForegroundColor Yellow
    $allChecksPass = $false
}

# 6. Verificar System.Data.SQLite
Write-Host "`n6. System.Data.SQLite" -ForegroundColor Yellow
$sqliteDll = Get-ChildItem -Path $PSScriptRoot -Filter "System.Data.SQLite.dll" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if ($sqliteDll) {
    Write-Host "   ✅ System.Data.SQLite instalado - OK" -ForegroundColor Green
    Write-Host "   Ubicación: $($sqliteDll.DirectoryName)" -ForegroundColor Gray
}
else {
    Write-Host "   ❌ System.Data.SQLite NO instalado" -ForegroundColor Red
    Write-Host "   Solución: .\Setup-SQLite.ps1" -ForegroundColor Yellow
    $allChecksPass = $false
}

# 7. Verificar módulos requeridos
Write-Host "`n7. Módulos de PowerShell" -ForegroundColor Yellow
$requiredModules = @(
    "SSLConfiguration.psm1",
    "CommandHandlers.psm1",
    "CertificateAuth.psm1",
    "DatabaseManager.psm1"
)

$modulesOk = $true
foreach ($module in $requiredModules) {
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "Modules\$module"
    if (Test-Path $modulePath) {
        Write-Host "   ✅ $module" -ForegroundColor Green
    }
    else {
        Write-Host "   ❌ $module NO encontrado" -ForegroundColor Red
        $modulesOk = $false
        $allChecksPass = $false
    }
}

# 8. Verificar base de datos
Write-Host "`n8. Base de Datos SQLite" -ForegroundColor Yellow
$dbPath = Join-Path -Path $PSScriptRoot -ChildPath "Database\RemoteAdmin.db"
if (Test-Path $dbPath) {
    $dbInfo = Get-Item $dbPath
    Write-Host "   ✅ Base de datos existe - OK" -ForegroundColor Green
    Write-Host "   Tamaño: $([math]::Round($dbInfo.Length / 1KB, 2)) KB" -ForegroundColor Gray
    Write-Host "   Última modificación: $($dbInfo.LastWriteTime)" -ForegroundColor Gray
}
else {
    Write-Host "   ⚠️ Base de datos NO existe" -ForegroundColor Yellow
    Write-Host "   Se creará automáticamente al recopilar inventario" -ForegroundColor Gray
    Write-Host "   Solución: .\Collect-Inventory.ps1 -SaveToDatabase" -ForegroundColor Yellow
}

# 9. Verificar regla de firewall
Write-Host "`n9. Regla de Firewall" -ForegroundColor Yellow
$fwRule = Get-NetFirewallRule -DisplayName "Control Remoto*" -ErrorAction SilentlyContinue
if ($fwRule) {
    Write-Host "   ✅ Regla de firewall configurada - OK" -ForegroundColor Green
    Write-Host "   Estado: $($fwRule.Enabled)" -ForegroundColor Gray
}
else {
    Write-Host "   ⚠️ Regla de firewall NO configurada" -ForegroundColor Yellow
    Write-Host "   Recomendado para conexiones remotas" -ForegroundColor Gray
    Write-Host "   Solución: New-NetFirewallRule -DisplayName 'Control Remoto PowerShell' -Direction Inbound -LocalPort 4430 -Protocol TCP -Action Allow" -ForegroundColor Yellow
}

# 10. Verificar carpetas necesarias
Write-Host "`n10. Estructura de Carpetas" -ForegroundColor Yellow
$requiredFolders = @("Modules", "Logs", "Database", "Certificates")
$foldersOk = $true
foreach ($folder in $requiredFolders) {
    $folderPath = Join-Path -Path $PSScriptRoot -ChildPath $folder
    if (Test-Path $folderPath) {
        Write-Host "   ✅ $folder\" -ForegroundColor Green
    }
    else {
        Write-Host "   ⚠️ $folder\ NO existe (se creará automáticamente)" -ForegroundColor Yellow
    }
}

# Resumen final
Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    RESUMEN DEL DIAGNÓSTICO                     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

if ($allChecksPass) {
    Write-Host "✅ TODAS LAS VERIFICACIONES PASARON" -ForegroundColor Green
    Write-Host "`nEl servidor está listo para iniciarse." -ForegroundColor Green
    Write-Host "Ejecutar: .\Servidor.ps1`n" -ForegroundColor Cyan
}
else {
    Write-Host "❌ ALGUNAS VERIFICACIONES FALLARON" -ForegroundColor Red
    Write-Host "`nPor favor, corregir los problemas indicados arriba antes de iniciar el servidor.`n" -ForegroundColor Yellow
    
    Write-Host "Pasos recomendados:" -ForegroundColor Cyan
    Write-Host "1. Ejecutar como Administrador (si no lo está)" -ForegroundColor White
    Write-Host "2. Instalar SQLite: .\Setup-SQLite.ps1" -ForegroundColor White
    Write-Host "3. Generar certificados: .\Regenerar-Certificados.ps1" -ForegroundColor White
    Write-Host "4. Configurar firewall: New-NetFirewallRule -DisplayName 'Control Remoto PowerShell' -Direction Inbound -LocalPort 4430 -Protocol TCP -Action Allow" -ForegroundColor White
    Write-Host "5. Inicializar BD: .\Collect-Inventory.ps1 -SaveToDatabase`n" -ForegroundColor White
}

# Información adicional
Write-Host "Para más ayuda, consultar: README.md" -ForegroundColor Gray
Write-Host "Sección: Inicio Rápido y Troubleshooting`n" -ForegroundColor Gray
