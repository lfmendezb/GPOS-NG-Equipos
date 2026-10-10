<#
.SYNOPSIS
  Revisión obligatoria del área común (regla 8): trae lo nuevo y lista los avisos abiertos para el equipo,
  marcando los que llegaron desde la revisión anterior. No instala memoria ni agentes y no publica.
.EXAMPLE
  .\Revisar-AreaComun.ps1 -Equipo A
#>
param(
    [Parameter(Mandatory)][ValidateSet('A', 'B', 'C')][string]$Equipo
)
$ErrorActionPreference = 'Stop'
$raiz = Split-Path -Parent $PSScriptRoot
Set-Location $raiz
$entrantes = @(Get-ChildItem (Join-Path $raiz 'avisos') -Directory -Filter "*-a-$Equipo" -ErrorAction SilentlyContinue | ForEach-Object { "avisos/$($_.Name)" })  # avisos de cualquier equipo a este
$otrosTraspasos = @(Get-ChildItem (Join-Path $raiz 'traspasos') -Directory -ErrorAction SilentlyContinue | Where-Object Name -ne $Equipo | ForEach-Object { "traspasos/$($_.Name)" })

$dirEstado = Join-Path $env:LOCALAPPDATA 'GPOS-NG-Equipos'
New-Item -ItemType Directory -Force $dirEstado | Out-Null
$archivoUltima = Join-Path $dirEstado "ultima-revision-$Equipo.txt"
$ultima = if (Test-Path $archivoUltima) { (Get-Content $archivoUltima -Raw).Trim() } else { $null }

git pull --rebase --autostash --quiet
if ($LASTEXITCODE -ne 0) { throw 'No se pudo traer el área común (git pull).' }
$actual = (git rev-parse HEAD).Trim()

Write-Host "Revisión del área común — equipo $Equipo — $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
if ($ultima -and $ultima -ne $actual) {
    $nuevos = git log --format='%h %s' "$ultima..$actual" -- @($entrantes + $otrosTraspasos + @("estado.md", "memoria", "agentes", "herramientas"))
    if ($nuevos) { Write-Host "`nCommits nuevos que le afectan:"; $nuevos | ForEach-Object { Write-Host "  $_" } }
    else { Write-Host "`nSin commits nuevos que le afecten." }
    $cambiados = @(git diff --name-only "$ultima" "$actual" -- $entrantes)
} elseif (-not $ultima) {
    Write-Host "`nPrimera revisión en este equipo: se listan todos los avisos abiertos."
    $cambiados = @()
} else {
    Write-Host "`nSin cambios desde la revisión anterior."
    $cambiados = @()
}

$abiertos = $entrantes | ForEach-Object { Get-ChildItem "$_/*.md" -ErrorAction SilentlyContinue } |
    Where-Object { (Get-Content $_.FullName -Raw) -match 'Estado:\s*Abierto' }
Write-Host "`nAvisos abiertos para el equipo ${Equipo}: $(@($abiertos).Count)"
foreach ($a in $abiertos) {
    $texto = Get-Content $a.FullName -Raw
    $prioridad = if ($texto -match 'Prioridad:\s*(\w+)') { $Matches[1] } else { '?' }
    $rel = "avisos/$($a.Directory.Name)/$($a.Name)"
    $marca = if ($cambiados -contains $rel) { 'NUEVO ' } else { '      ' }
    Write-Host "  $marca[$prioridad] $rel"
}

Set-Content $archivoUltima $actual -NoNewline
