<#
.SYNOPSIS
  Registra (o vuelve a registrar) la tarea programada de Windows que corre Vigilar-AreaComun.ps1 cada 30 minutos, sin el modelo.
  La ejecuta el PROPIETARIO, una vez por equipo: es configuración permanente de Windows y los agentes no la hacen.
  Corre con el usuario actual, solo con la sesión iniciada (para la notificación), sin ventana (conhost --headless).
.EXAMPLE
  .\Registrar-VigilanciaAreaComun.ps1 -Equipo B
.EXAMPLE
  .\Registrar-VigilanciaAreaComun.ps1 -Equipo B -Quitar
#>
param(
    [Parameter(Mandatory)][ValidateSet('A', 'B', 'C')][string]$Equipo,
    [int]$Minuto = 7,          # minutos de la hora en que corre: $Minuto y $Minuto + 30
    [switch]$Quitar
)
$ErrorActionPreference = 'Stop'
$nombre = "GPOS-NG Vigilar área común ($Equipo)"
if ($Quitar) { Unregister-ScheduledTask -TaskName $nombre -Confirm:$false; Write-Host "Tarea quitada: $nombre"; return }

$script = Join-Path $PSScriptRoot 'Vigilar-AreaComun.ps1'
$accion = New-ScheduledTaskAction -Execute 'conhost.exe' `
    -Argument "--headless powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$script`" -Equipo $Equipo"
$ahora = Get-Date
$inicio = $ahora.Date.AddHours($ahora.Hour).AddMinutes($Minuto)
while ($inicio -le $ahora) { $inicio = $inicio.AddMinutes(30) }
$disparador = New-ScheduledTaskTrigger -Once -At $inicio -RepetitionInterval (New-TimeSpan -Minutes 30)
$ajustes = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 5) `
    -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
Register-ScheduledTask -TaskName $nombre -Action $accion -Trigger $disparador -Settings $ajustes -Principal $principal `
    -Description "Vigila el área común y los PR de GPOS-NG para el equipo $Equipo sin usar el modelo. Novedades en %LOCALAPPDATA%\GPOS-NG-Equipos\novedades-$Equipo.md" -Force | Out-Null
Write-Host "Tarea registrada: $nombre. Primera corrida: $($inicio.ToString('HH:mm')); luego cada 30 minutos."
Write-Host "Novedades: $env:LOCALAPPDATA\GPOS-NG-Equipos\novedades-$Equipo.md  |  Registro: vigilancia-$Equipo.log"
