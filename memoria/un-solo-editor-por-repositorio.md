---
name: un-solo-editor-por-repositorio
description: "Incidente del 2026-10-04: dos sesiones del propietario editaron a la vez Backup Tool y se pisaron; regla: un solo agente por árbol de trabajo y confirmar o apartar los cambios del propietario antes de que un agente edite"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 9bf422be-17fa-4dbe-9779-4afcf2205243
  modified: 2026-10-04T06:05:52.367Z
---

El 2026-10-04 el propietario tenía dos sesiones de Claude Code activas sobre la misma tarea («Evaluación modelo de datos sin BP2» y «... (ReImplementacion)»). Ambas lanzaron un desarrollador-backend para la fase R0 en `C:\Users\lfmen\source\repos\Backup Tool\` y un devops para el piloto. Los agentes se sobrescribieron archivos (`BackupPolicy.cs` perdido y reconstruido; duplicados en `BackupFileMetadata.cs`, `DatabaseSource.cs`, `NotificationEventCodes.cs`). La rama de partida (`fix/ui-publicada-recursos-estaticos`) tenía 19 archivos modificados y 10 sin seguimiento del propietario, sin confirmar; tres archivos fueron reescritos enteros por un agente.

**Why:** dos escritores sobre un mismo árbol de trabajo destruyen trabajo sin dejar rastro en git; los cambios sin confirmar del propietario no se pueden recuperar.

**How to apply:**
- Antes de lanzar un agente que edite un repositorio, comprobar `git status`; si hay cambios sin confirmar del propietario, pedirle que los confirme o aparte (stash o rama) antes.
- Nunca dos agentes (ni dos sesiones) editando el mismo árbol a la vez; si hace falta paralelismo, usar worktrees separados (`isolation: worktree`).
- Al detectar otra sesión del propietario sobre el mismo repositorio, detener las ediciones y preguntar al propietario qué sesión continúa.
- Los agentes que solo prueban o documentan reciben la prohibición explícita de editar código y de ejecutar git que cambie el árbol.
- La clave heredada de `src/BackupService.Api/appsettings.json` de Backup Tool: el auditor (2026-10-04) vio `ApiKey` vacío en los commits; probablemente solo estuvo en la copia de trabajo. Igual hay que rotarla: la herramienta la migró con hash a LiteDB y la sigue aceptando donde arrancó con ella (pasos K-1 a K-5 en `GPOS NG/docs/seguridad/2026-10-04-revision-bloque-s-modelo-ng.md`).
