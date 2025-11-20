param(
    [string]$Path = "."
)

# Extensiones a buscar
$extensions = @("*.ps1", "*.psm1")

Write-Host "Buscando archivos .ps1 y .psm1 en: $Path" 

# Obtener archivos .ps1 y .psm1 en el directorio y subdirectorios
$files = Get-ChildItem -Path $Path -Recurse -File -Include $extensions -ErrorAction SilentlyContinue

if (-not $files) {
    Write-Host "No se encontraron archivos .ps1 o .psm1."
    exit
}

foreach ($file in $files) {
    try {
        # Opcional: solo mostrar si estaba bloqueado (tiene Zone.Identifier)
        $zone = Get-Item -Path $file.FullName -Stream Zone.Identifier -ErrorAction SilentlyContinue
        if ($zone) {
            Unblock-File -Path $file.FullName
            Write-Host "Desbloqueado: $($file.FullName)"
        }
        else {
            Write-Host "Ya estaba desbloqueado: $($file.FullName)"
        }
    }
    catch {
        Write-Warning "No se pudo desbloquear $($file.FullName): $_"
    }
}

Write-Host "Proceso terminado."
