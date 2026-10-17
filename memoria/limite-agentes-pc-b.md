---
name: limite-agentes-pc-b
description: "Equipo de B (coordinador, OSHIN-LEGION): hasta 8 agentes, máximo 3 compilando o probando; suite completa o carga SQL sola (propietario, 2026-10-10)"
metadata:
  type: feedback
---

En el **equipo de B** (OSHIN-LEGION, 16 núcleos, 31 GB), el propietario aprobó el **2026-10-10** («Aprobado según la recomendación») hasta **8 agentes a la vez**, con un **máximo de 3 compilando o corriendo pruebas parciales** al mismo tiempo, y **una sola suite completa de GPOS.Tests o carga SQL a la vez, y sola**.

Sustituye la regla del 2026-10-09 (6 agentes, 2 compilando) y la de la PC B vieja (7,8 GB).

**Why:** cada compilación de la solución usa 2-3 GB; el cuello de botella real es la instancia SQL compartida: las pruebas de tiempo (`ImportacionTercerosTiempoTests`) fallan con la suite cargada y pasan solas.

**How to apply:** antes de lanzar un agente, contar los activos y cuántos compilan o prueban; no pasar de 8 ni de 3. Los agentes de diseño, revisión y documentos casi no cuentan para la carga. Relacionado: [[siguiente-paso-pc-b]], [[revisar-procesos-huerfanos]].
