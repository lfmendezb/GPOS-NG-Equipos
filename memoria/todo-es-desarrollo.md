---
name: todo-es-desarrollo
description: "El propietario aclaró (2026-10-04) que hoy todo GPOS NG es desarrollo: no hay ambientes de producción; avisará explícitamente si eso cambia"
metadata:
  node_type: memory
  type: user
  originSessionId: 1cee00aa-ab02-439f-846e-6899ce03c1d6
  modified: 2026-10-04T23:24:20.689Z
---

El 2026-10-04 el propietario dijo: «Ahora mismo todo es desarrollo, no existen ambientes de producción; de cambiar en un futuro te lo indicaré explícitamente para que lo tomes en cuenta».

**Why:** no quiere que se trate como producción lo que corre en sus equipos (procesos de API/Web, bases de prueba, ramas), ni que se frene el trabajo por eso.

**How to apply:**
- Los procesos de desarrollo de GPOS NG en este equipo (API, Web, MAUI lanzados desde las carpetas del repositorio) se pueden detener cuando estorben a la construcción o a las pruebas; avisar al propietario de que se detuvieron.
- Las bases reales del propietario (`GPOS_SYSDATA`, `GPOS_DEV00`, sus bases de demostración) siguen siendo intocables salvo orden expresa: que sea desarrollo no autoriza borrar o modificar sus datos.
- Las acciones hacia afuera (push, PR, unir a master, enviar archivos) siguen requiriendo su orden.
- Si el propietario anuncia un ambiente de producción o un cliente real, cambiar este criterio.

Relacionado: [[un-solo-editor-por-repositorio]].
