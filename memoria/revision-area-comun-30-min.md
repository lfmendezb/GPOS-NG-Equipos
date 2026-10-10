---
name: revision-area-comun-30-min
description: "Regla del propietario (2026-10-07): cada sesión de equipo revisa el área común cada 30 min, atiende lo rutinario y presenta lo que exige decisión"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 6bc31041-05a1-4f8b-aeb1-1d4a864e8888
  modified: 2026-10-07T22:14:33.226Z
---

El 2026-10-07 el propietario formalizó una **revisión obligatoria del área común cada 30 minutos** (regla 8 del README de `GPOS-NG-Equipos`), para que la comunicación entre los equipos A y B no dependa de que él recuerde avisar.

**Why:** si el propietario olvida decirle a un equipo que actualice, un aviso urgente del otro equipo podía quedarse sin leer horas.

**How to apply:**
- Al abrir cada sesión de equipo, programar con `CronCreate` una tarea recurrente cada 30 minutos que ejecute `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\herramientas\Revisar-AreaComun.ps1 -Equipo <A|B>` (A en la PC A, B en la PC B).
- **Atender sin preguntar lo rutinario** e informarlo: acuses, respuestas informativas, `estado.md`, aplicar a la memoria común cambios ya decididos por el propietario (solo A), registrar lo ya firmado (por ejemplo un ADR Aceptado) y publicar con el script.
- **Presentar al propietario sin actuar** lo que exija decisión o firma, unir ramas, lanzar construcción en un árbol de código o tocar bases de datos.
- Sin novedades, no interrumpir al propietario.

Precisa [[dos-equipos-a-coordina]] («el propietario decide cuándo cada equipo actualiza o publica»): la revisión de 30 minutos y lo rutinario quedan autorizados de forma permanente.

**2026-10-09:** el propietario pidió acortarla a 10 minutos y enseguida lo revirtió («deja el tiempo tal como está»): **sigue cada 30 minutos**. Tras un reinicio de sesión, comprobar con `CronList` que no queden tareas duplicadas.
