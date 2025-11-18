# Guía de Contribución

¡Gracias por tu interés en contribuir al proyecto de Control Remoto PowerShell!

## Cómo Contribuir

### Reportar Bugs

Si encuentras un bug, por favor abre un issue con:

- **Descripción clara** del problema
- **Pasos para reproducir** el error
- **Comportamiento esperado** vs comportamiento actual
- **Versión de PowerShell** y Windows
- **Logs relevantes** (si aplica)

### Sugerir Features

Para sugerir nuevas características:

- Abre un issue con la etiqueta "enhancement"
- Describe claramente el caso de uso
- Explica cómo beneficiaría al proyecto
- Proporciona ejemplos si es posible

### Pull Requests

1. **Fork** el repositorio
2. Crea una **rama** desde `main`:
   ```powershell
   git checkout -b feature/mi-nueva-caracteristica
   ```
3. Realiza tus cambios siguiendo las guías de estilo
4. **Prueba** tus cambios exhaustivamente
5. **Commit** con mensajes descriptivos:
   ```
   git commit -m "Add: Nueva funcionalidad X"
   git commit -m "Fix: Corregido bug en módulo Y"
   git commit -m "Docs: Actualizada documentación de Z"
   ```
6. **Push** a tu fork:
   ```powershell
   git push origin feature/mi-nueva-caracteristica
   ```
7. Abre un **Pull Request** con descripción detallada

## Guías de Estilo

### PowerShell

- **Nombres de funciones**: Usar verbos aprobados (Get, Set, New, Remove, etc.)
- **Nombres de variables**: PascalCase para parámetros, camelCase para variables locales
- **Indentación**: 4 espacios (no tabs)
- **Comentarios**: Comment-based help para todas las funciones públicas
- **Encoding**: UTF-8 with BOM

Ejemplo:

```powershell
<#
.SYNOPSIS
    Descripción breve de la función.

.DESCRIPTION
    Descripción detallada de lo que hace la función.

.PARAMETER NombreParametro
    Descripción del parámetro.

.EXAMPLE
    Ejemplo-Funcion -NombreParametro "valor"
    Descripción del ejemplo.

.NOTES
    Autor: Tu Nombre
    Fecha: DD/MM/YYYY
#>
function Ejemplo-Funcion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$NombreParametro
    )
    
    # Lógica de la función
    Write-Verbose "Procesando: $NombreParametro"
}
```

### Documentación

- Usar **Markdown** para documentación
- Incluir **ejemplos** de uso
- Mantener **README.md** actualizado
- Documentar **cambios importantes** en CHANGELOG.md

### Testing

- Probar en **Windows Server** y **Windows 10/11**
- Verificar con **PowerShell 5.1** y **7.x**
- Probar con **permisos limitados** y como **administrador**
- Validar **manejo de errores**

## Proceso de Revisión

Los Pull Requests serán revisados considerando:

1. **Calidad del código**: Sigue las guías de estilo
2. **Funcionalidad**: Cumple el propósito declarado
3. **Testing**: Está probado adecuadamente
4. **Documentación**: Incluye documentación necesaria
5. **Compatibilidad**: No rompe funcionalidad existente

## Código de Conducta

- Ser **respetuoso** con otros contribuidores
- Aceptar **críticas constructivas**
- Enfocarse en lo **mejor para el proyecto**
- Ser **paciente** durante el proceso de revisión

## Preguntas

Si tienes preguntas sobre cómo contribuir, abre un issue con la etiqueta "question".

¡Gracias por contribuir!
