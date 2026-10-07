---
name: limite-agentes-pc-b
description: "Regla del propietario (2026-10-07) para la PC B (portátil): máximo dos agentes a la vez; lo pesado de SQL Server o memoria corre solo"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 6bc31041-05a1-4f8b-aeb1-1d4a864e8888
  modified: 2026-10-07T19:26:31.111Z
---

Regla del propietario del 2026-10-07 para la **PC B**: como máximo **dos agentes a la vez**. Una tarea pesada de SQL Server o de memoria (suite completa, prueba de carga, compilación de toda la solución) corre **sola**: sin otros agentes, sin scripts de Bash en segundo plano y sin aplicaciones .NET abiertas.

**Why:** la PC B es un portátil con recursos limitados; dos compilaciones o suites a la vez la saturan.

**How to apply:** en la PC B, antes de lanzar un agente, contar los activos; si la tarea es pesada, esperar a que no haya ninguno. No aplica a la PC A. Relacionado: [[dos-equipos-a-coordina]], [[revisar-procesos-huerfanos]].
