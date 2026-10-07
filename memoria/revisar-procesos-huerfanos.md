---
name: revisar-procesos-huerfanos
description: Al informar el estado de procesos en segundo plano, revisar también bash/pwsh/powershell (bucles de espera huérfanos de agentes), no solo dotnet/testhost/MSBuild
metadata:
  type: feedback
---

El 2026-10-07 el propietario detectó un `bash.exe` huérfano de 4 h (bucle `until … sleep 5` del agente devops esperando la salida de una corrida ya terminada) que mi revisión no vio porque solo buscaba dotnet, testhost y MSBuild.

**Why:** los agentes pueden dejar bucles de espera vivos al terminar; consumen poco pero confunden y pueden bloquear la notificación de cierre del agente.

**How to apply:** al revisar el estado, listar con `Get-CimInstance Win32_Process` los procesos `bash`, `sh`, `pwsh`, `powershell`, `dotnet`, `testhost`, `MSBuild`, `VBCSCompiler`, `sqlcmd` con su línea de comando y hora de inicio; detener los huérfanos de agentes ya terminados (permitido: [[todo-es-desarrollo]]), nunca la consola del propietario.
