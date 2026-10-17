# Hook PreToolUse (Agent): hace respetar el modelo de la definición de cada agente.
# Regla del propietario del 2026-10-17 (memoria agentes-con-opus):
# - Manda el `model:` de %USERPROFILE%\.claude\agents\<tipo>.md.
# - Bajar de modelo en la llamada se permite (p. ej. desarrollador-backend con sonnet para lo mecánico).
# - Subir de modelo exige una línea "Escalado a Opus: <motivo>" en el encargo; sin ella se quita `model`.
# - Explore corre siempre con haiku.
# - Fable solo con escalado explícito (reservado para la revisión general).
$ErrorActionPreference = 'Stop'
[Console]::InputEncoding  = [Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$entrada = [Console]::In.ReadToEnd() | ConvertFrom-Json
$ti = $entrada.tool_input
if ($null -eq $ti) { exit 0 }

$tipo    = [string]$ti.subagent_type
$pedido  = [string]$ti.model
$encargo = [string]$ti.prompt
$escalado = $encargo -match '(?im)^\s*Escalado a (Opus|Fable)\s*:\s*\S'

$rango = @{ 'haiku' = 1; 'sonnet' = 2; 'opus' = 3; 'fable' = 4 }

function Salir-Con([hashtable]$nuevo, [string]$motivo) {
    $salida = @{
        hookSpecificOutput = @{
            hookEventName            = 'PreToolUse'
            permissionDecision       = 'allow'
            permissionDecisionReason = $motivo
            updatedInput             = $nuevo
            additionalContext        = $motivo
        }
    }
    $salida | ConvertTo-Json -Depth 10 -Compress
    exit 0
}

function Copia-Sin-Model {
    $h = @{}
    foreach ($p in $ti.PSObject.Properties) { if ($p.Name -ne 'model') { $h[$p.Name] = $p.Value } }
    return $h
}

# Explore: siempre haiku.
if ($tipo -eq 'Explore') {
    if ($pedido -eq 'haiku') { exit 0 }
    $h = Copia-Sin-Model
    $h['model'] = 'haiku'
    Salir-Con $h "Modelo por agente: Explore corre con haiku."
}

if ([string]::IsNullOrWhiteSpace($pedido)) { exit 0 }

# Modelo de la definición del agente.
$definido = $null
if ($tipo) {
    $archivo = Join-Path $env:USERPROFILE ".claude\agents\$tipo.md"
    if (Test-Path -LiteralPath $archivo) {
        $linea = Select-String -LiteralPath $archivo -Pattern '^model:\s*(\S+)' | Select-Object -First 1
        if ($linea) { $definido = $linea.Matches[0].Groups[1].Value.ToLowerInvariant() }
    }
}

$rPedido = $rango[$pedido.ToLowerInvariant()]
if ($null -eq $rPedido) { exit 0 }   # valor desconocido: no se toca

if ($escalado) { exit 0 }

$quitar = $false
if ($definido -and $rango.ContainsKey($definido)) {
    if ($rPedido -gt $rango[$definido]) { $quitar = $true }
} elseif ($pedido -eq 'fable') {
    $quitar = $true
}

if ($quitar) {
    $base = if ($definido) { $definido } else { 'el de la sesión' }
    Salir-Con (Copia-Sin-Model) "Modelo por agente: se quitó model='$pedido' de '$tipo'; corre con $base. Para subir de modelo, añada al encargo una línea 'Escalado a Opus: <motivo>'."
}
exit 0
