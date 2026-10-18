---
name: sesiones-sonnet-medio-escalar-opus
description: "2026-10-18: las sesiones de A, B y C trabajan con Sonnet 5 y esfuerzo medio, y sugieren pasar a Opus 5.5 en una línea para las tareas de riesgo; al terminar, volver a Sonnet"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 924c86d7-164e-4af7-907a-23057f30c43b
  modified: 2026-10-18T16:52:34.897Z
---

**Decisión del propietario, 2026-10-18 (sesión de B):** «sugiere un esquema en donde las sesiones utilicen el modelo Sonnet 5 con un nivel de esfuerzo Medio. Y cuando sea requerido, según la actividad a realizar, sugerir escalarlo a Opus 5.5 oportunamente. Necesito optimizar lo más posible el uso para poder alcanzar mis objetivos.» (Confirmado por el propietario el 2026-10-18: es Sonnet 5, claude-sonnet-5 —no Sonnet 5.5.)

**Why:** el uso se consume rápido y el propietario necesita que alcance para llegar al corte de mediados de diciembre.

**How to apply:**
- **Por omisión, Sonnet 5 con esfuerzo medio** para la rutina: avisos, `estado.md`, publicar, vigilantes, registrar lo ya firmado, uniones sin conflicto con fallas conocidas, correcciones mecánicas y lanzar agentes con un encargo claro.
- **Sugerir Opus 5.5 en una línea antes de empezar, y esperar la respuesta del propietario**, cuando la tarea sea:
  - conflictos de unión en código sensible: autenticación, permisos, aislamiento, licencia, sellos, criptografía, numeración, NCF/e-CF, bloqueos, costos o kárdex, y migraciones que chocan;
  - diagnosticar una falla de la suite que no esté en la lista de las conocidas, o interpretar una medición;
  - una hoja de firma, un ADR nuevo, un blueprint o una respuesta a hallazgos Altos;
  - construir los tramos D1 a D3 de DB-7, seguridad, licencia, fiscal o bloqueos;
  - cuando Sonnet falla dos veces en lo mismo.
- **Al terminar esa tarea, sugerir volver a Sonnet con esfuerzo medio.**
- Los agentes siguen con su modelo por definición ([[agentes-con-opus]]). Las correcciones pequeñas se le piden al mismo agente (continuación), lo mecánico va con `model: "sonnet"` y las búsquedas con Explore.
- Aviso a los tres equipos: `avisos/B-a-A/2026-10-18-sesiones-sonnet-medio-escalar-opus.md` (y su copia en `B-a-C`).
