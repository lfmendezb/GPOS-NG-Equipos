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

**2026-10-10 (sustituye el CronCreate):** para no gastar vueltas del modelo, la regla 8 la hace una **tarea programada de Windows** registrada por el propietario («GPOS-NG Vigilar área común (B)»; **cada 10 minutos** desde el 2026-10-10, precisión del propietario: sin costo de modelo; desfase B 2, A 5, C 8) que corre `herramientas\Vigilar-AreaComun.ps1 -Equipo B` sin el modelo. Escribe novedades (avisos con acción, acuses agrupados y PR abiertos nuevos o actualizados) solo si las hay, en `%LOCALAPPDATA%\GPOS-NG-Equipos\novedades-B.md`, con notificación de Windows; registro en `vigilancia-B.log`. **Al abrir sesión: NO programar CronCreate**; leer `novedades-B.md` (y cuando el propietario lo pida), atender lo rutinario y presentar lo que exige decisión. Tras leer, mover lo atendido a `novedades-B-leidas.md` para que el archivo quede con lo pendiente. A y C pueden registrar la suya con `Registrar-VigilanciaAreaComun.ps1 -Equipo A -Minuto 5` y `-Equipo C -Minuto 8`.

**2026-10-10 (vigilante en la sesión, decisión del propietario):** al abrir sesión, armar `Monitor` (timeout_ms 1800000) con `f="$LOCALAPPDATA/GPOS-NG-Equipos/novedades-B.md"; touch "$f"; tail -n0 -F "$f" 2>/dev/null | grep --line-buffered -E "^## |^- "` y **re-armarlo cada vez que vence**. Al despertar: leer el aviso, atender lo rutinario y presentar lo que exige decisión. Motivo: C dejó encargos sin empezar casi 2 horas porque la sesión no leía las novedades sola. Regla 8 del README del área común.

**Corrección (2026-10-10, 11:15):** NO usar `tail -F` (bloquea el archivo y la tarea de Windows no puede escribir). Comando correcto del Monitor: `f="$LOCALAPPDATA/GPOS-NG-Equipos/novedades-B.md"; touch "$f"; n=$(wc -l < "$f"); while true; do m=$(wc -l < "$f" 2>/dev/null || echo "$n"); if [ "$m" -gt "$n" ]; then sed -n "$((n+1)),${m}p" "$f" | grep -E "^## |^- "; n=$m; fi; sleep 20; done`. Vigilar-AreaComun.ps1 reintenta la escritura.
**Ojo (11:46):** un Monitor vencido puede dejar procesos hijos huérfanos (tail.exe, sleep) que siguen corriendo; si la vigilancia registra «está siendo utilizado en otro proceso», buscar y detener esos procesos propios.
