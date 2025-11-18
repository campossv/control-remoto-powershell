


Write-Host "=== Convirtiendo archivos a UTF-8 with BOM ===" -ForegroundColor Cyan


$files = Get-ChildItem -Path $PSScriptRoot -Recurse -Include *.ps1, *.psm1 | Where-Object { $_.FullName -notlike "*\Archive\*" }

Write-Host "Archivos encontrados: $($files.Count)" -ForegroundColor White

$converted = 0
$errors = 0

foreach ($file in $files) {
    try {
        
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
        
        
        $utf8BOM = New-Object System.Text.UTF8Encoding $true
        [System.IO.File]::WriteAllText($file.FullName, $content, $utf8BOM)
        
        Write-Host "✓ $($file.Name)" -ForegroundColor Green
        $converted++
    }
    catch {
        Write-Host "✗ $($file.Name): $_" -ForegroundColor Red
        $errors++
    }
}

Write-Host "`n=== Resumen ===" -ForegroundColor Cyan
Write-Host "Convertidos: $converted" -ForegroundColor Green
Write-Host "Errores: $errors" -ForegroundColor $(if ($errors -gt 0) { 'Red' } else { 'Gray' })

