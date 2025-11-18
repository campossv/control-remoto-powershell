



Add-Type -Path "$PSScriptRoot\..\System.Data.SQLite.dll" -ErrorAction SilentlyContinue


$script:DatabasePath = Join-Path $PSScriptRoot "..\Database\RemoteAdmin.db"
$script:ConnectionString = "Data Source=$script:DatabasePath;Version=3;"

function Initialize-Database {
    try {
        $dbFolder = Split-Path $script:DatabasePath -Parent
        if (-not (Test-Path $dbFolder)) {
            New-Item -ItemType Directory -Path $dbFolder -Force | Out-Null
        }
        
        $connection = New-Object System.Data.SQLite.SQLiteConnection($script:ConnectionString)
        $connection.Open()
        
        $command = $connection.CreateCommand()
        
        
        $command.CommandText = @"
CREATE TABLE IF NOT EXISTS Servers (
    ServerID INTEGER PRIMARY KEY AUTOINCREMENT,
    IPAddress TEXT NOT NULL UNIQUE,
    Hostname TEXT,
    Description TEXT,
    OS TEXT,
    LastConnection DATETIME,
    Status TEXT DEFAULT 'Active',
    CertificateThumbprint TEXT,
    Notes TEXT,
    CreatedDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    ModifiedDate DATETIME DEFAULT CURRENT_TIMESTAMP
);
"@
        $command.ExecuteNonQuery() | Out-Null
        
        
        $command.CommandText = @"
CREATE TABLE IF NOT EXISTS SessionLogs (
    LogID INTEGER PRIMARY KEY AUTOINCREMENT,
    SessionID TEXT NOT NULL,
    ServerID INTEGER,
    EventType TEXT NOT NULL,
    Level TEXT NOT NULL,
    Message TEXT,
    Details TEXT,
    Username TEXT,
    Timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ServerID) REFERENCES Servers(ServerID)
);
"@
        $command.ExecuteNonQuery() | Out-Null
        
        
        $command.CommandText = @"
CREATE TABLE IF NOT EXISTS CommandHistory (
    CommandID INTEGER PRIMARY KEY AUTOINCREMENT,
    SessionID TEXT NOT NULL,
    ServerID INTEGER,
    Command TEXT NOT NULL,
    Output TEXT,
    Success BOOLEAN,
    Timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ServerID) REFERENCES Servers(ServerID)
);
"@
        $command.ExecuteNonQuery() | Out-Null
        
        
        $command.CommandText = @"
CREATE TABLE IF NOT EXISTS SystemMetrics (
    MetricID INTEGER PRIMARY KEY AUTOINCREMENT,
    ServerID INTEGER,
    CPUUsage REAL,
    MemoryUsage REAL,
    ProcessCount INTEGER,
    ServiceCount INTEGER,
    Timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ServerID) REFERENCES Servers(ServerID)
);
"@
        $command.ExecuteNonQuery() | Out-Null
        
        
        $command.CommandText = @"
CREATE TABLE IF NOT EXISTS HardwareInventory (
    HardwareID INTEGER PRIMARY KEY AUTOINCREMENT,
    ServerID INTEGER,
    ComponentType TEXT NOT NULL,
    Manufacturer TEXT,
    Model TEXT,
    SerialNumber TEXT,
    Capacity TEXT,
    Speed TEXT,
    Status TEXT,
    AdditionalInfo TEXT,
    LastScan DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ServerID) REFERENCES Servers(ServerID)
);
"@
        $command.ExecuteNonQuery() | Out-Null
        
        
        $command.CommandText = @"
CREATE TABLE IF NOT EXISTS SoftwareInventory (
    SoftwareID INTEGER PRIMARY KEY AUTOINCREMENT,
    ServerID INTEGER,
    SoftwareName TEXT NOT NULL,
    Version TEXT,
    Publisher TEXT,
    InstallDate TEXT,
    InstallLocation TEXT,
    UninstallString TEXT,
    Size INTEGER,
    LastScan DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ServerID) REFERENCES Servers(ServerID)
);
"@
        $command.ExecuteNonQuery() | Out-Null
        
        
        $command.CommandText = @"
CREATE TABLE IF NOT EXISTS SoftwareChanges (
    ChangeID INTEGER PRIMARY KEY AUTOINCREMENT,
    ServerID INTEGER,
    SoftwareName TEXT NOT NULL,
    Version TEXT,
    ChangeType TEXT NOT NULL,
    ChangeDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ServerID) REFERENCES Servers(ServerID)
);
"@
        $command.ExecuteNonQuery() | Out-Null
        
        
        $command.CommandText = @"
CREATE TABLE IF NOT EXISTS DiskInventory (
    DiskID INTEGER PRIMARY KEY AUTOINCREMENT,
    ServerID INTEGER,
    DriveLetter TEXT,
    Label TEXT,
    FileSystem TEXT,
    TotalSize INTEGER,
    FreeSpace INTEGER,
    UsedSpace INTEGER,
    PercentFree REAL,
    LastScan DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ServerID) REFERENCES Servers(ServerID)
);
"@
        $command.ExecuteNonQuery() | Out-Null
        
        $connection.Close()
        
        Write-Host "Base de datos inicializada: $script:DatabasePath" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Warning "Error al inicializar BD: $_"
        return $false
    }
}

function Add-Server {
    param(
        [Parameter(Mandatory = $true)]
        [string]$IPAddress,
        [string]$Hostname,
        [string]$Description,
        [string]$OS = "",
        [string]$CertificateThumbprint = ""
    )
    
    try {
        $connection = New-Object System.Data.SQLite.SQLiteConnection($script:ConnectionString)
        $connection.Open()
        
        $command = $connection.CreateCommand()
        $command.CommandText = @"
INSERT OR REPLACE INTO Servers 
(IPAddress, Hostname, Description, OS, CertificateThumbprint, LastConnection, Status) 
VALUES (@IP, @Host, @Desc, @OS, @Cert, @Time, 'Active')
"@
        $command.Parameters.AddWithValue("@IP", $IPAddress) | Out-Null
        $command.Parameters.AddWithValue("@Host", $Hostname) | Out-Null
        $command.Parameters.AddWithValue("@Desc", $Description) | Out-Null
        $command.Parameters.AddWithValue("@OS", $OS) | Out-Null
        $command.Parameters.AddWithValue("@Cert", $CertificateThumbprint) | Out-Null
        $command.Parameters.AddWithValue("@Time", (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")) | Out-Null
        
        $command.ExecuteNonQuery() | Out-Null
        $connection.Close()
        return $true
    }
    catch {
        Write-Warning "Error: $_"
        return $false
    }
}

function Get-Servers {
    try {
        
        if (-not (Test-Path $script:DatabasePath)) {
            Write-Warning "Base de datos no encontrada: $script:DatabasePath"
            return $null
        }
        
        $connection = New-Object System.Data.SQLite.SQLiteConnection($script:ConnectionString)
        $connection.Open()
        
        $command = $connection.CreateCommand()
        $command.CommandText = "SELECT * FROM Servers WHERE Status = 'Active' ORDER BY LastConnection DESC"
        
        $adapter = New-Object System.Data.SQLite.SQLiteDataAdapter($command)
        $dataSet = New-Object System.Data.DataSet
        $rowCount = $adapter.Fill($dataSet)
        
        $connection.Close()
        
        if ($rowCount -gt 0) {
            
            return , $dataSet.Tables[0]
        }
        else {
            return $null
        }
    }
    catch {
        Write-Warning "Error al consultar servidores: $_"
        return $null
    }
}

function Add-SessionLog {
    param(
        [string]$SessionID,
        [string]$ServerIP,
        [string]$Level,
        [string]$Message
    )
    
    try {
        $connection = New-Object System.Data.SQLite.SQLiteConnection($script:ConnectionString)
        $connection.Open()
        
        $command = $connection.CreateCommand()
        $command.CommandText = "INSERT INTO SessionLogs (SessionID, EventType, Level, Message, Username) VALUES (@SID, @Type, @Level, @Msg, @User)"
        $command.Parameters.AddWithValue("@SID", $SessionID) | Out-Null
        $command.Parameters.AddWithValue("@Type", "Session") | Out-Null
        $command.Parameters.AddWithValue("@Level", $Level) | Out-Null
        $command.Parameters.AddWithValue("@Msg", $Message) | Out-Null
        $command.Parameters.AddWithValue("@User", $env:USERNAME) | Out-Null
        
        $command.ExecuteNonQuery() | Out-Null
        $connection.Close()
        return $true
    }
    catch {
        return $false
    }
}

function Add-HardwareInventory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServerIP,
        [Parameter(Mandatory = $true)]
        [array]$HardwareComponents
    )
    
    try {
        $connection = New-Object System.Data.SQLite.SQLiteConnection($script:ConnectionString)
        $connection.Open()
        
        $command = $connection.CreateCommand()
        $command.CommandText = "SELECT ServerID FROM Servers WHERE IPAddress = @IP"
        $command.Parameters.AddWithValue("@IP", $ServerIP) | Out-Null
        $serverID = $command.ExecuteScalar()
        
        if (-not $serverID) {
            Write-Warning "Add-HardwareInventory: Servidor no encontrado en BD: $ServerIP"
            $connection.Close()
            return $false
        }
        
        Write-Verbose "Add-HardwareInventory: ServerID=$serverID, Componentes=$($HardwareComponents.Count)"
        
        $command.CommandText = "DELETE FROM HardwareInventory WHERE ServerID = @SID"
        $command.Parameters.Clear()
        $command.Parameters.AddWithValue("@SID", $serverID) | Out-Null
        $command.ExecuteNonQuery() | Out-Null
        
        $insertedCount = 0
        foreach ($hw in $HardwareComponents) {
            $command.CommandText = "INSERT INTO HardwareInventory (ServerID, ComponentType, Manufacturer, Model, SerialNumber, Capacity, Speed, Status) VALUES (@SID, @Type, @Mfr, @Model, @Serial, @Cap, @Speed, @Status)"
            $command.Parameters.Clear()
            $command.Parameters.AddWithValue("@SID", $serverID) | Out-Null
            $command.Parameters.AddWithValue("@Type", $hw.Type) | Out-Null
            $command.Parameters.AddWithValue("@Mfr", $hw.Manufacturer) | Out-Null
            $command.Parameters.AddWithValue("@Model", $hw.Model) | Out-Null
            $command.Parameters.AddWithValue("@Serial", $hw.SerialNumber) | Out-Null
            $command.Parameters.AddWithValue("@Cap", $hw.Capacity) | Out-Null
            $command.Parameters.AddWithValue("@Speed", $hw.Speed) | Out-Null
            $command.Parameters.AddWithValue("@Status", $hw.Status) | Out-Null
            $command.ExecuteNonQuery() | Out-Null
            $insertedCount++
        }
        
        $connection.Close()
        Write-Verbose "Add-HardwareInventory: Insertados $insertedCount componentes"
        return $true
    }
    catch {
        Write-Warning "Error al guardar hardware: $_"
        Write-Warning "StackTrace: $($_.ScriptStackTrace)"
        return $false
    }
}

function Add-SoftwareInventory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServerIP,
        [Parameter(Mandatory = $true)]
        [array]$SoftwareList
    )
    
    try {
        $connection = New-Object System.Data.SQLite.SQLiteConnection($script:ConnectionString)
        $connection.Open()
        
        $command = $connection.CreateCommand()
        $command.CommandText = "SELECT ServerID FROM Servers WHERE IPAddress = @IP"
        $command.Parameters.AddWithValue("@IP", $ServerIP) | Out-Null
        $serverID = $command.ExecuteScalar()
        
        if (-not $serverID) {
            Write-Warning "Add-SoftwareInventory: Servidor no encontrado en BD: $ServerIP"
            $connection.Close()
            return $false
        }
        
        Write-Verbose "Add-SoftwareInventory: ServerID=$serverID, Software=$($SoftwareList.Count)"
        
        $command.CommandText = "DELETE FROM SoftwareInventory WHERE ServerID = @SID"
        $command.Parameters.Clear()
        $command.Parameters.AddWithValue("@SID", $serverID) | Out-Null
        $command.ExecuteNonQuery() | Out-Null
        
        $insertedCount = 0
        foreach ($sw in $SoftwareList) {
            $command.CommandText = "INSERT INTO SoftwareInventory (ServerID, SoftwareName, Version, Publisher, InstallDate, InstallLocation, Size) VALUES (@SID, @Name, @Ver, @Pub, @Date, @Loc, @Size)"
            $command.Parameters.Clear()
            $command.Parameters.AddWithValue("@SID", $serverID) | Out-Null
            $command.Parameters.AddWithValue("@Name", $sw.Name) | Out-Null
            $command.Parameters.AddWithValue("@Ver", $sw.Version) | Out-Null
            $command.Parameters.AddWithValue("@Pub", $sw.Publisher) | Out-Null
            $command.Parameters.AddWithValue("@Date", $sw.InstallDate) | Out-Null
            $command.Parameters.AddWithValue("@Loc", $sw.InstallLocation) | Out-Null
            $command.Parameters.AddWithValue("@Size", $sw.Size) | Out-Null
            $command.ExecuteNonQuery() | Out-Null
            $insertedCount++
        }
        
        $connection.Close()
        Write-Verbose "Add-SoftwareInventory: Insertados $insertedCount aplicaciones"
        return $true
    }
    catch {
        Write-Warning "Error al guardar software: $_"
        Write-Warning "StackTrace: $($_.ScriptStackTrace)"
        return $false
    }
}

Export-ModuleMember -Function Initialize-Database, Add-Server, Get-Servers, Add-SessionLog, Add-HardwareInventory, Add-SoftwareInventory

