


Import-Module "$PSScriptRoot\Modules\DatabaseManager.psm1" -Force

Write-Host "=== Diagnóstico de Base de Datos ===" -ForegroundColor Cyan


$dbPath = Join-Path $PSScriptRoot "Database\RemoteAdmin.db"
Write-Host "`n1. Verificando base de datos..." -ForegroundColor Yellow
if (Test-Path $dbPath) {
    Write-Host "   ✓ BD existe: $dbPath" -ForegroundColor Green
}
else {
    Write-Host "   ✗ BD no existe" -ForegroundColor Red
    Write-Host "   Inicializando..." -ForegroundColor Gray
    Initialize-Database
}


Write-Host "`n2. Agregando servidor de prueba..." -ForegroundColor Yellow
$testIP = "192.168.0.19"
$result = Add-Server -IPAddress $testIP -Hostname "AD" -Description "Test Server"
if ($result) {
    Write-Host "   ✓ Servidor agregado" -ForegroundColor Green
}
else {
    Write-Host "   ✗ Error al agregar servidor" -ForegroundColor Red
}


Write-Host "`n3. Verificando servidor en BD..." -ForegroundColor Yellow
try {
    $connectionString = "Data Source=$dbPath;Version=3;"
    $connection = New-Object System.Data.SQLite.SQLiteConnection($connectionString)
    $connection.Open()
    
    $command = $connection.CreateCommand()
    $command.CommandText = "SELECT ServerID, IPAddress, Hostname FROM Servers WHERE IPAddress = '$testIP'"
    $reader = $command.ExecuteReader()
    
    if ($reader.Read()) {
        $serverID = $reader["ServerID"]
        $hostname = $reader["Hostname"]
        Write-Host "   ✓ Servidor encontrado: ID=$serverID, Hostname=$hostname" -ForegroundColor Green
    }
    else {
        Write-Host "   ✗ Servidor NO encontrado en BD" -ForegroundColor Red
    }
    
    $reader.Close()
    $connection.Close()
}
catch {
    Write-Host "   ✗ Error al consultar: $_" -ForegroundColor Red
}


Write-Host "`n4. Probando Add-HardwareInventory..." -ForegroundColor Yellow
$testHW = @(
    @{
        Type         = "CPU"
        Manufacturer = "Intel"
        Model        = "Test CPU"
        SerialNumber = "12345"
        Capacity     = "4 cores"
        Speed        = "2400 MHz"
        Status       = "OK"
    }
)

$hwResult = Add-HardwareInventory -ServerIP $testIP -HardwareComponents $testHW
if ($hwResult) {
    Write-Host "   ✓ Hardware guardado correctamente" -ForegroundColor Green
}
else {
    Write-Host "   ✗ Error al guardar hardware" -ForegroundColor Red
}

Write-Host "`n=== Diagnóstico Completado ===" -ForegroundColor Cyan

