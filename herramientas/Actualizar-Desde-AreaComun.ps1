<#
.SYNOPSIS
  Trae lo nuevo del área común, instala la memoria y los agentes comunes y lista los avisos abiertos para el equipo.
.EXAMPLE
  .\Actualizar-Desde-AreaComun.ps1 -Equipo B
#>
param(
    [Parameter(Mandatory)][ValidateSet('A', 'B')][string]$Equipo,
    [string]$ClaveMemoria = 'C--Users-lfmen-source-repos-Solucion-GPOS-NG'
)
$ErrorActionPreference = 'Stop'
$raiz = Split-Path -Parent $PSScriptRoot
Set-Location $raiz

git pull --rebase
if ($LASTEXITCODE -ne 0) { throw 'No se pudo traer el área común (git pull).' }

$claude = Join-Path $env:USERPROFILE '.claude'
$destAgentes = Join-Path $claude 'agents'
$destMemoria = Join-Path $claude "projects\$ClaveMemoria\memory"
$sello = Get-Date -Format 'yyyyMMdd-HHmmss'

# Copia de seguridad local antes de reemplazar
foreach ($par in @(@($destAgentes, "agents-respaldo-$sello"), @($destMemoria, "memory-respaldo-$sello"))) {
    if (Test-Path $par[0]) { Copy-Item $par[0] (Join-Path $claude $par[1]) -Recurse }
}
New-Item -ItemType Directory -Force $destAgentes, $destMemoria | Out-Null
Copy-Item (Join-Path $raiz 'agentes\*.md') $destAgentes -Force
Copy-Item (Join-Path $raiz 'memoria\*.md') $destMemoria -Force
Write-Host "Agentes y memoria instalados (copia anterior en $claude\*-respaldo-$sello)."

# Avisos abiertos para este equipo
$otro = if ($Equipo -eq 'A') { 'B' } else { 'A' }
$carpeta = Join-Path $raiz "avisos\$otro-a-$Equipo"
$abiertos = Get-ChildItem $carpeta -Filter *.md -ErrorAction SilentlyContinue |
    Where-Object { (Get-Content $_.FullName -Raw) -match '(?m)^Estado:\s*Abierto' }
if ($abiertos) {
    Write-Host "`nAvisos abiertos para el equipo ${Equipo}:"
    $abiertos | ForEach-Object { Write-Host "  - $($_.Name)" }
} else {
    Write-Host "`nNo hay avisos abiertos para el equipo $Equipo."
}
Write-Host "Lea también estado.md. Reinicie la sesión de Claude si cambiaron los agentes."
