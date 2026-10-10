<#
.SYNOPSIS
  Vigilancia del área común y de los PR sin el modelo (sustituye el reloj de la regla 8 que despertaba al modelo cada 30 minutos).
  La corre una tarea programada de Windows. No toca la copia de trabajo: solo hace fetch y lee origin/main.
  Si no hay novedades, termina sin escribir nada. Si las hay, agrega un bloque a %LOCALAPPDATA%\GPOS-NG-Equipos\novedades-<Equipo>.md
  y muestra una notificación de Windows. El modelo lee ese archivo cuando el propietario lo pide o al abrir la sesión.
.EXAMPLE
  .\Vigilar-AreaComun.ps1 -Equipo B
.EXAMPLE
  .\Vigilar-AreaComun.ps1 -Equipo B -SinNotificacion    # prueba manual, sin aviso de Windows
#>
param(
    [Parameter(Mandatory)][ValidateSet('A', 'B', 'C')][string]$Equipo,
    [string]$RepoPr = 'lfmendezb/GPOS-NG',
    [switch]$SinNotificacion
)
$ErrorActionPreference = 'Stop'
# PowerShell 5.1 decodifica la salida de git y gh con la página de códigos de la consola: sin esto, las tildes salen como «├®»
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$raiz = Split-Path -Parent $PSScriptRoot
$dirEstado = Join-Path $env:LOCALAPPDATA 'GPOS-NG-Equipos'
New-Item -ItemType Directory -Force $dirEstado | Out-Null
$archivoUltima = Join-Path $dirEstado "vigilancia-commit-$Equipo.txt"
$archivoPr = Join-Path $dirEstado "vigilancia-pr-$Equipo.json"
$archivoNovedades = Join-Path $dirEstado "novedades-$Equipo.md"
$archivoRegistro = Join-Path $dirEstado "vigilancia-$Equipo.log"

function Registrar([string]$texto) { Add-Content $archivoRegistro "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $texto" -Encoding UTF8 }

try {
    # ---------------------------------------------------------------- área común (sin tocar la copia de trabajo)
    git -C $raiz fetch --quiet origin 2>$null
    if ($LASTEXITCODE -ne 0) { throw 'git fetch del área común falló' }
    $actual = (git -C $raiz rev-parse origin/main).Trim()
    $ultima = if (Test-Path $archivoUltima) { (Get-Content $archivoUltima -Raw).Trim() } else { $null }

    $avisos = @()
    if ($ultima -and $ultima -ne $actual) {
        $lineas = @(git -C $raiz diff --name-status --diff-filter=AM "$ultima" "$actual" -- "avisos/*-a-$Equipo/*.md" "traspasos")
        foreach ($l in $lineas) {
            if (-not $l) { continue }
            $estado, $ruta = $l -split "`t", 2
            $texto = (git -C $raiz show "${actual}:$ruta") -join "`n"
            $tipo = if ($texto -match '(?m)^Tipo:\s*([^\r\n]+)') { $Matches[1].Trim() } elseif ($ruta -like 'traspasos/*') { 'Traspaso' } else { '?' }
            $prioridad = if ($texto -match 'Prioridad:\s*(\w+)') { $Matches[1] } else { '?' }
            $titulo = if ($texto -match '(?m)^#\s+(.+)$') { $Matches[1].Trim() } else { Split-Path $ruta -Leaf }
            $avisos += [pscustomobject]@{
                Ruta = $ruta; Tipo = $tipo; Prioridad = $prioridad; Titulo = $titulo
                Nuevo = ($estado -eq 'A'); EsAcuse = (($tipo -match '\bAcuse\b' -or $titulo -match '^Acuse\b') -and $tipo -notmatch 'Pregunta|Hallazgo|Encargo|Entrega|Decisi' -and $titulo -notmatch 'Falta|pregunta')
            }
        }
    }

    # ---------------------------------------------------------------- PR abiertos o actualizados
    $prs = @()
    $previos = @{}
    if (Test-Path $archivoPr) { (Get-Content $archivoPr -Raw | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $previos[$_.Name] = $_.Value } }
    $json = gh pr list --repo $RepoPr --state open --limit 50 --json number,title,headRefName,updatedAt,isDraft 2>$null
    if ($LASTEXITCODE -ne 0) { throw 'gh pr list falló' }
    # PowerShell 5.1: gh devuelve líneas y ConvertFrom-Json entrega el arreglo como un solo objeto; se une y se desenrolla
    $abiertos = @(($json -join "`n") | ConvertFrom-Json | ForEach-Object { $_ })
    $estadoPr = [ordered]@{}
    foreach ($p in $abiertos) {
        $clave = [string]$p.number
        $estadoPr[$clave] = $p.updatedAt
        if (-not $previos.ContainsKey($clave)) { $prs += [pscustomobject]@{ P = $p; Que = 'nuevo' } }
        elseif ($previos[$clave] -ne $p.updatedAt) { $prs += [pscustomobject]@{ P = $p; Que = 'actualizado' } }
    }
    $primeraVez = -not (Test-Path $archivoPr)

    # ---------------------------------------------------------------- resultado
    $accion = @($avisos | Where-Object { -not $_.EsAcuse })
    $acuses = @($avisos | Where-Object { $_.EsAcuse })
    if (-not $primeraVez -and ($avisos.Count -gt 0 -or $prs.Count -gt 0)) {
        $b = [System.Text.StringBuilder]::new()
        [void]$b.AppendLine("## $(Get-Date -Format 'yyyy-MM-dd HH:mm') — equipo $Equipo")
        foreach ($a in $accion) { [void]$b.AppendLine("- [$($a.Prioridad)] $(if ($a.Nuevo) { 'NUEVO' } else { 'CAMBIADO' }) $($a.Tipo): $($a.Titulo) — ``$($a.Ruta)``") }
        if ($acuses.Count) { [void]$b.AppendLine("- Acuses ($($acuses.Count)): " + (($acuses | ForEach-Object { Split-Path $_.Ruta -Leaf }) -join ', ')) }
        foreach ($x in $prs) { [void]$b.AppendLine("- PR #$($x.P.number) $($x.Que)$(if ($x.P.isDraft) { ' (borrador)' }): $($x.P.title) — ``$($x.P.headRefName)``") }
        [void]$b.AppendLine()
        Add-Content $archivoNovedades $b.ToString() -Encoding UTF8
        Registrar "novedades: $($accion.Count) avisos con acción, $($acuses.Count) acuses, $($prs.Count) PR"

        if (-not $SinNotificacion) {
            $resumen = "$($accion.Count) avisos con acción, $($acuses.Count) acuses, $($prs.Count) PR"
            try {
                [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
                [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
                $xml = [Windows.Data.Xml.Dom.XmlDocument]::new()
                $xml.LoadXml("<toast><visual><binding template='ToastGeneric'><text>GPOS NG — área común ($Equipo)</text><text>$([Security.SecurityElement]::Escape($resumen))</text></binding></visual></toast>")
                $app = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
                [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($app).Show([Windows.UI.Notifications.ToastNotification]::new($xml))
            } catch { Registrar "sin notificación: $($_.Exception.Message)" }
        }
    } elseif ($primeraVez) {
        Registrar "primera vigilancia: se toma como punto de partida ($($abiertos.Count) PR abiertos)"
    }

    Set-Content $archivoUltima $actual -NoNewline
    $estadoPr | ConvertTo-Json | Set-Content $archivoPr
} catch {
    Registrar "ERROR: $($_.Exception.Message)"
    exit 1
}
