


$sqliteDll = Join-Path $PSScriptRoot "System.Data.SQLite.dll"
$sqliteUrl = "https://system.data.sqlite.org/blobs/1.0.118.0/sqlite-netFx46-binary-x64-2015-1.0.118.0.zip"
$downloadPath = Join-Path $PSScriptRoot "sqlite.zip"
$extractPath = $PSScriptRoot

Write-Host "=== Setup System.Data.SQLite ===" -ForegroundColor Cyan


if (Test-Path $sqliteDll) {
    Write-Host "✓ System.Data.SQLite ya está instalado" -ForegroundColor Green
    
    
    try {
        $assembly = [System.Reflection.Assembly]::LoadFrom($sqliteDll)
        $version = $assembly.GetName().Version
        Write-Host "  Versión: $version" -ForegroundColor Gray
        
        
        Add-Type -Path $sqliteDll -ErrorAction Stop
        Write-Host "  Estado: Funcional" -ForegroundColor Green
        
        $needsInstall = $false
    }
    catch {
        Write-Warning "  La DLL existe pero no es funcional: $_"
        Write-Host "  Reinstalando..." -ForegroundColor Yellow
        $needsInstall = $true
    }
}
else {
    Write-Host "⚠ System.Data.SQLite no encontrado" -ForegroundColor Yellow
    $needsInstall = $true
}


if ($needsInstall) {
    Write-Host "`nDescargando System.Data.SQLite..." -ForegroundColor Cyan
    
    try {
        
        Invoke-WebRequest -Uri $sqliteUrl -OutFile $downloadPath -UseBasicParsing
        
        Write-Host "Extrayendo archivos..." -ForegroundColor Cyan
        
        
        Expand-Archive -Path $downloadPath -DestinationPath $extractPath -Force
        
        
        Remove-Item $downloadPath -Force
        
        
        if (Test-Path $sqliteDll) {
            Write-Host "✓ SQLite instalado correctamente" -ForegroundColor Green
            Write-Host "  Ubicación: $sqliteDll" -ForegroundColor Gray
        }
        else {
            throw "No se encontró System.Data.SQLite.dll después de la extracción"
        }
    }
    catch {
        Write-Warning "Error: $_"
        Write-Host "`nDescarga manual desde:" -ForegroundColor Yellow
        Write-Host "https://system.data.sqlite.org/index.html/doc/trunk/www/downloads.wiki" -ForegroundColor Yellow
        Write-Host "`nBuscar: sqlite-netFx46-binary-x64" -ForegroundColor Yellow
        exit 1
    }
}


Write-Host "`nInicializando base de datos..." -ForegroundColor Cyan

try {
    Import-Module ".\Modules\DatabaseManager.psm1" -Force
    $result = Initialize-Database
    
    if ($result) {
        Write-Host "`n✓ Setup completado exitosamente" -ForegroundColor Green
        Write-Host "  Base de datos lista para usar" -ForegroundColor Gray
    }
    else {
        Write-Warning "Error al inicializar la base de datos"
    }
}
catch {
    Write-Warning "Error al inicializar BD: $_"
    Write-Host "Ejecute manualmente: Initialize-Database" -ForegroundColor Yellow
}

