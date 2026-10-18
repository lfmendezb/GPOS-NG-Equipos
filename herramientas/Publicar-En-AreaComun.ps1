<#
.SYNOPSIS
  Publica en el área común lo que corresponde al equipo. Con -Equipo B (coordinador) copia además la memoria y los agentes locales.
.EXAMPLE
  .\Publicar-En-AreaComun.ps1 -Equipo B -Mensaje "Aviso sobre la ola 3b"
#>
param(
    [Parameter(Mandatory)][ValidateSet('A', 'B', 'C')][string]$Equipo,
    [Parameter(Mandatory)][string]$Mensaje,
    [string]$ClaveMemoria = 'C--Users-lfmen-source-repos-Solucion-GPOS-NG-GPOS-NG'
)
$ErrorActionPreference = 'Stop'
$raiz = Split-Path -Parent $PSScriptRoot
Set-Location $raiz

git pull --rebase --autostash
if ($LASTEXITCODE -ne 0) { throw 'No se pudo traer el área común antes de publicar (git pull).' }

$rutas = @("avisos/$Equipo-a-*", "traspasos/$Equipo", 'estado.md')
if ($Equipo -eq 'B') {  # B coordina desde el 2026-10-09: solo el coordinador publica memoria y agentes
    $claude = Join-Path $env:USERPROFILE '.claude'
    # Copia lo local al área común sin pisar un cambio más reciente de otro equipo (2026-10-18: el commit 10fa36c revirtió las comillas que A
    # puso en dos agentes, porque las copias locales de B eran más viejas). Si el archivo del área común cambió en un commit posterior a la
    # última modificación de la copia local, se trae al local en lugar de sobrescribirlo, y se avisa.
    function Sincronizar([string]$origen, [string]$destino) {
        foreach ($local in Get-ChildItem $origen -File) {
            $comun = Join-Path $destino $local.Name
            if (Test-Path $comun) {
                $rel = (Resolve-Path -Relative $comun) -replace '^\.\\', '' -replace '\\', '/'
                $fechaComun = git log -1 --format=%cI -- $rel
                if ($fechaComun -and ([datetime]$fechaComun) -gt $local.LastWriteTime -and
                    (Get-FileHash $comun).Hash -ne (Get-FileHash $local.FullName).Hash) {
                    Copy-Item $comun $local.FullName -Force
                    Write-Warning "$rel cambió en el área común después de la copia local: se trajo al local y no se pisó."
                    continue
                }
            }
            Copy-Item $local.FullName $comun -Force
        }
    }
    Sincronizar (Join-Path $claude 'agents\*.md') (Join-Path $raiz 'agentes')
    Sincronizar (Join-Path $claude "projects\$ClaveMemoria\memory\*.md") (Join-Path $raiz 'memoria')
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
