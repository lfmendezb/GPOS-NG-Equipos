<#
.SYNOPSIS
  Trae lo nuevo del área común, instala la memoria y los agentes comunes y lista los avisos abiertos para el equipo.
.EXAMPLE
  .\Actualizar-Desde-AreaComun.ps1 -Equipo B
#>
param(
    [Parameter(Mandatory)][ValidateSet('A', 'B', 'C')][string]$Equipo,
    [string]$ClaveMemoria = 'C--Users-lfmen-source-repos-Solucion-GPOS-NG'
)
$ErrorActionPreference = 'Stop'
$raiz = Split-Path -Parent $PSScriptRoot
Set-Location $raiz

$antes = git rev-parse HEAD
git pull --rebase --autostash
if ($LASTEXITCODE -ne 0) { throw 'No se pudo traer el área común (git pull).' }
if (git diff --name-only $antes HEAD -- herramientas) {
    Write-Warning 'El pull actualizó los scripts de herramientas/. Vuelva a ejecutar este script para usar la versión nueva.'
    return
}

$claude = Join-Path $env:USERPROFILE '.claude'
$destAgentes = Join-Path $claude 'agents'
$sello = Get-Date -Format 'yyyyMMdd-HHmmss'

# La memoria de Claude va por carpeta de proyecto, y su nombre sale de la carpeta desde la que se abre la sesión
# (por ejemplo «...Solucion GPOS NG» o «...Solucion GPOS NG\GPOS NG»). Se instala en la clave por omisión y en
# todas las que ya existan para la solución, para que la cargue cualquier sesión del equipo.
$proyectos = Join-Path $claude 'projects'
$claves = @($ClaveMemoria)
if (Test-Path $proyectos) {
    $claves += Get-ChildItem $proyectos -Directory | Where-Object { $_.Name -like '*Solucion-GPOS-NG*' } | ForEach-Object Name
}
$claves = $claves | Sort-Object -Unique

# Copia de seguridad local antes de reemplazar
if (Test-Path $destAgentes) { Copy-Item $destAgentes (Join-Path $claude "agents-respaldo-$sello") -Recurse }
New-Item -ItemType Directory -Force $destAgentes | Out-Null
Copy-Item (Join-Path $raiz 'agentes\*.md') $destAgentes -Force

foreach ($clave in $claves) {
    $destMemoria = Join-Path $proyectos "$clave\memory"
    if (Test-Path $destMemoria) { Copy-Item $destMemoria (Join-Path $claude "memory-respaldo-$sello-$clave") -Recurse }
    New-Item -ItemType Directory -Force $destMemoria | Out-Null
    # Las líneas del índice local que apuntan a memorias propias del equipo (no vienen del área común) se conservan
    $indiceLocal = Join-Path $destMemoria 'MEMORY.md'
    $comunes = (Get-ChildItem (Join-Path $raiz 'memoria\*.md')).Name
    $propias = @()
    if (Test-Path $indiceLocal) {
        $propias = @(Get-Content $indiceLocal | Where-Object {
            $_ -match '\(([^()]+\.md)\)' -and ($comunes -notcontains $Matches[1]) -and (Test-Path (Join-Path $destMemoria $Matches[1]))
        })
    }
    Copy-Item (Join-Path $raiz 'memoria\*.md') $destMemoria -Force
    if ($propias.Count -gt 0) {
        Add-Content $indiceLocal $propias
        Write-Host "  Conservadas $($propias.Count) líneas propias del índice en $clave"
    }
    Write-Host "Memoria instalada en: $clave"
}
Write-Host "Agentes instalados. Copias anteriores en $claude\*-respaldo-$sello*."

# Avisos abiertos para este equipo
# Avisos de cualquier equipo a este (A, B o C)
$carpetas = Get-ChildItem (Join-Path $raiz "avisos") -Directory -Filter "*-a-$Equipo" -ErrorAction SilentlyContinue
$abiertos = $carpetas | ForEach-Object { Get-ChildItem $_.FullName -Filter *.md } |
    Where-Object { (Get-Content $_.FullName -Raw) -match '(?m)^Estado:\s*Abierto' }
if ($abiertos) {
    Write-Host "`nAvisos abiertos para el equipo ${Equipo}:"
    $abiertos | ForEach-Object { Write-Host "  - $($_.Directory.Name)/$($_.Name)" }
} else {
    Write-Host "`nNo hay avisos abiertos para el equipo $Equipo."
}
Write-Host "Lea también estado.md. Reinicie la sesión de Claude si cambiaron los agentes."
