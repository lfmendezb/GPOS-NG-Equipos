---
name: limite-agentes-pc-b
description: "Equipo nuevo de B (coordinador): hasta 6 agentes, máximo 2 compilando o probando a la vez (propietario, 2026-10-09)"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 686e2e7b-d221-4745-a8a5-eeb40a6cf428
  modified: 2026-10-09T23:11:17.610Z
---

En el **equipo nuevo de B** (OSHIN-LEGION, 16 núcleos, 31 GB), el propietario aprobó el 2026-10-09 hasta **6 agentes a la vez**, con un **máximo de 2 compilando o corriendo pruebas** al mismo tiempo. Una tarea que exige mucho de SQL Server o de memoria (cargas, T-57, suite completa de GPOS.Tests) se ejecuta **sola**.

Sustituye la regla de la PC B vieja (7,8 GB): 4 agentes si solo uno compilaba, si no 2.

**Why:** la PC B vieja se quedaba sin memoria al compilar; el equipo nuevo tiene cuatro veces más RAM y pasó a ser el coordinador ([[siguiente-paso-pc-b]], [[dos-equipos-a-coordina]]).

**How to apply:** antes de lanzar un agente, contar los que están en curso y cuántos compilan o prueban; no pasar de 6 ni de 2 compilando. Tampoco correr dos suites completas a la vez (CLAUDE.md). Relacionado: [[revisar-procesos-huerfanos]].
