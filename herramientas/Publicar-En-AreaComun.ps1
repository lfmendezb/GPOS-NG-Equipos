<#
.SYNOPSIS
  Publica en el área común lo que corresponde al equipo. Con -Equipo A copia además la memoria y los agentes locales.
.EXAMPLE
  .\Publicar-En-AreaComun.ps1 -Equipo B -Mensaje "Aviso sobre la ola 3b"
#>
param(
    [Parameter(Mandatory)][ValidateSet('A', 'B')][string]$Equipo,
    [Parameter(Mandatory)][string]$Mensaje,
    [string]$ClaveMemoria = 'C--Users-lfmen-source-repos-Solucion-GPOS-NG'
)
$ErrorActionPreference = 'Stop'
$raiz = Split-Path -Parent $PSScriptRoot
Set-Location $raiz

git pull --rebase --autostash
if ($LASTEXITCODE -ne 0) { throw 'No se pudo traer el área común antes de publicar (git pull).' }

$rutas = @("avisos/$Equipo-a-*", "traspasos/$Equipo", 'estado.md')
if ($Equipo -eq 'A') {
    $claude = Join-Path $env:USERPROFILE '.claude'
    Copy-Item (Join-Path $claude 'agents\*.md') (Join-Path $raiz 'agentes') -Force
    Copy-Item (Join-Path $claude "projects\$ClaveMemoria\memory\*.md") (Join-Path $raiz 'memoria') -Force
    $rutas += @('memoria', 'agentes', 'herramientas', 'README.md')
}

# Comprobación básica de secretos en lo que se va a publicar
$sospechosos = Get-ChildItem $rutas -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -ne $PSCommandPath } |
    Select-String -Pattern 'Password=|Pwd=|User ID=.*;|Bearer [A-Za-z0-9\-_\.]{20,}' -List
if ($sospechosos) {
    $sospechosos | ForEach-Object { Write-Warning "Posible secreto en $($_.Path)" }
    throw 'Publicación detenida: revise los archivos marcados. Nunca se publican secretos.'
}

git add -- $rutas
git diff --cached --quiet
if ($LASTEXITCODE -eq 0) { Write-Host 'No hay cambios que publicar.'; return }
git commit -m "[$Equipo] $Mensaje"
git push
if ($LASTEXITCODE -ne 0) { throw 'No se pudo publicar (git push).' }
Write-Host "Publicado en el área común: [$Equipo] $Mensaje"
