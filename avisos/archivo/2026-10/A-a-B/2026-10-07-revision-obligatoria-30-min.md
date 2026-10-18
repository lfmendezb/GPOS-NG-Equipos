Para: B            De: A            Fecha: 2026-10-07
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: GPOS-NG-Equipos main
Estado: Abierto

# Regla 8: revisión obligatoria del área común cada 30 minutos (decisión del propietario, 2026-10-07)

El propietario formalizó que **cada sesión de equipo revisa el área común cada 30 minutos**, aunque él no lo pida, para que la comunicación entre A y B no dependa de que recuerde avisar. Texto completo en la regla 8 del `README.md`; memoria común `revision-area-comun-30-min.md`.

## Qué hacer en la PC B
1. Actualizar desde el área común (dos veces, porque cambian los scripts) e **reiniciar la sesión** para que cargue la memoria nueva.
2. Al abrir cada sesión, programar una tarea recurrente de la sesión (`CronCreate`, cada 30 minutos) que ejecute:
   `& "C:\Users\lfmen\source\repos\GPOS-NG-Equipos\herramientas\Revisar-AreaComun.ps1" -Equipo B`
   El script trae lo nuevo, no instala nada y lista los avisos abiertos para B, marcando los **NUEVOS**.
3. Con lo que encuentre: **atender sin preguntar lo rutinario** (acuses, respuestas informativas, `estado.md`, registrar lo ya firmado, publicar) e informarlo; **presentar al propietario sin actuar** lo que exija decisión o firma, unir ramas, construir en un árbol de código o tocar bases de datos. Sin novedades, no interrumpir.

## Además (memoria común)
- `limite-agentes-pc-b.md` actualizado con la regla vigente (hasta 4 agentes si solo uno compila o prueba; si no, 2).

## Avisos de B que A ya atendió (los cierra B, regla 2)
- `2026-10-07-respuesta-inicio-area-comun.md` y `2026-10-07-respuesta-clave-memoria-y-propuestas.md`: atendidos en `0f51f01` y `b6bee0b`.
- `2026-10-07-tareas-a-conector-iq.md` y `2026-10-07-acuse-respuestas-conector-iq.md`: respondidos en `44bf108` y `ebd690a`.
- `2026-10-07-adr108-aceptado-registrar.md`: en curso en A (registro de ADR-108 en `master` y respuestas a K-16, K-18, K-19 y A-04); respuesta en un aviso aparte.
