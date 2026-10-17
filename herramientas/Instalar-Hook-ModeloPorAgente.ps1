<#
  Instala el hook que hace respetar el modelo por agente (decisión del propietario del 2026-10-17).
  - Copia herramientas\hooks\modelo-por-agente.ps1 a %USERPROFILE%\.claude\hooks\.
  - Añade a %USERPROFILE%\.claude\settings.json un PreToolUse con matcher "Agent" (idempotente; respalda el archivo antes).
  Reinicie la sesión de Claude después de instalar.
#>
$ErrorActionPreference = 'Stop'
$raiz     = Split-Path -Parent $PSScriptRoot
$claude   = Join-Path $env:USERPROFILE '.claude'
$origen   = Join-Path $PSScriptRoot 'hooks\modelo-por-agente.ps1'
$destHook = Join-Path $claude 'hooks'
$ajustes  = Join-Path $claude 'settings.json'
$comando  = 'pwsh -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude\hooks\modelo-por-agente.ps1"'

New-Item -ItemType Directory -Force $destHook | Out-Null
Copy-Item $origen $destHook -Force
Write-Host "Script copiado a $destHook"

if (Test-Path $ajustes) {
    $sello = Get-Date -Format 'yyyyMMdd-HHmmss'
    Copy-Item $ajustes "$ajustes.respaldo-$sello"
    $j = Get-Content $ajustes -Raw | ConvertFrom-Json -AsHashtable
} else {
    $j = [ordered]@{}
}
if (-not $j.Contains('hooks'))              { $j['hooks'] = [ordered]@{} }
if (-not $j['hooks'].Contains('PreToolUse')) { $j['hooks']['PreToolUse'] = @() }

$ya = $false
foreach ($g in $j['hooks']['PreToolUse']) {
    foreach ($h in $g['hooks']) { if ([string]$h['command'] -like '*modelo-por-agente.ps1*') { $ya = $true } }
}
if ($ya) {
    Write-Host 'El hook ya estaba registrado en settings.json; no se cambió.'
} else {
    $j['hooks']['PreToolUse'] = @($j['hooks']['PreToolUse']) + @([ordered]@{
        matcher = 'Agent'
        hooks   = @([ordered]@{
            type          = 'command'
            shell         = 'powershell'
            command       = $comando
            timeout       = 20
            statusMessage = 'Modelo por agente'
        })
    })
    $j | ConvertTo-Json -Depth 20 | Set-Content $ajustes -Encoding utf8NoBOM
    Write-Host "Hook registrado en $ajustes"
}

# Prueba rápida: un Explore pedido con opus debe quedar con haiku.
$prueba = '{"tool_name":"Agent","tool_input":{"subagent_type":"Explore","model":"opus","prompt":"x"}}'
$salida = $prueba | pwsh -NoProfile -File (Join-Path $destHook 'modelo-por-agente.ps1')
if ($salida -match '"model"\s*:\s*"haiku"') {
    Write-Host 'Prueba del hook: correcta.'
} else {
    Write-Warning "Prueba del hook: resultado inesperado: $salida"
}
Write-Host 'Reinicie la sesión de Claude para que cargue el hook.'
