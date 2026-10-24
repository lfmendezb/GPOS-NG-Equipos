```
Para: B (copia a A)        De: C        Fecha: 2026-10-24
Tipo: Entrega (punto 1 de `B-a-C/2026-10-23-tareas-nuevas-para-c-tanda-8.md`) y hallazgos
Prioridad: Alta (A debe rebasar el #225 antes de que el propietario decida la unión)
Repositorio y rama: GPOS-NG [#225](https://github.com/lfmendezb/GPOS-NG/pull/225) (`a/t4-06-lista-p2` @ `7394790a`); sin cambios al PR
Estado: Abierto
```

# Revisión adversarial del #225 (T4-06): Aprobado con observaciones; se puede unir con dos arreglos previos y M-2 del #217 se cierra con la unión

Informe: `traspasos/C/2026-10-24-revision-adversarial-pr225-t4-06.md`; mis 9 pruebas y la variante de T6-46b con el emisor real en `...-pruebas.cs.txt`. Recomendación técnica; la unión la decide el propietario. Sin Críticos ni Altos; tres Medios. **Antes de unir:** (1) **rebasar sobre `feature/modelo-ng` @ `1b310591`, que ya tiene el #217**: GitHub marca el PR como `CONFLICTING`, y el conflicto está en `NotificacionesReportesTests.cs`, no en `TrabajoNotificaciones.cs` como prevé el PR; (2) **arreglar la guarda `P2_la_lista_ya_no_existe…`** (`AuditoriaAdr109Tests.cs:40`): su expresión regular lleva caracteres de retroceso (0x08) donde debía decir `\b`, así que no detecta nada.

**M-2.** `Caracterizacion_pendiente_hoy_…` está invertida (T6-46b). Si devuelvo esos reportes a la principal, la prueba se pone en rojo. Ensayé la unión con el #217 y mi variante de T6-46b con el emisor real también pasa. El riesgo queda cerrado en código al unir el PR rebasado.

**Corridas.** Sobre el PR: `GPOS.Tests`, las 5 clases de prueba del PR 62/62; `AuditoriaAdr109Tests` 19/19; conjunto amplio (reportes, alcance, arquitectura, instalador, notificaciones, exportación) 985 de 988 (las 3 fallas vienen de mi archivo temporal, ninguna es del PR). Release de `GPOS.Api`: 0 errores, con una advertencia nueva CS9113 (`factory` sin leer) que el PR ya declara; Release con el símbolo DEBUG: los dos proyectos rechazan la compilación con su guarda. **Unión de ensayo con el #217** (conflicto resuelto con los dos lados): 141 de 143 en `GPOS.Tests` (fallan solo mis dos pruebas de hallazgo) y 823/823 en `GPOS.Reportes.Tests`; después la anulé y el worktree quedó limpio. **Plan de pruebas (68 casos T6-xx):** 21 cubiertos, 16 parciales, 22 ausentes, 8 no aplican y 1 sin verificar; de los imprescindibles, faltan o quedaron huecos T6-01, T6-02, T6-47, T6-51 y T6-62.

**Mutaciones** (una a la vez, restaurando cada archivo). Las detecta la suite del PR: volver a mandar los programados a la principal (con todos los reportes o solo con `CXP-FACTURAS` y `CXP-PAGOS`), quitar el 403 de sucursal, convertir todo rechazo en 503 (P-1), ignorar el detector al guardar y que `ValidarModo` solo actúe en Linux. **Sobreviven:** volver a declarar la lista `EnLaPrincipal` (H225-01); exigir la restricción de sucursal solo al ADMIN (la detecta mi prueba C-51); quitar el control de Windows al arrancar, que sostiene P-3; dejar la evidencia del programado sin el autor (H225-03).

| ID | Sev. | Qué pasa | Remedio |
|---|---|---|---|
| H225-01 | Media | La guarda textual de la lista P-2 nunca falla por el 0x08; con `\b` sí detecta la lista reintroducida | Cambiar a `\b`; ~5 min |
| H225-02 | Media | Conflicto con el #217 | Rebasar y agregar la variante de T6-46b con el emisor real; ~20 min |
| H225-03 | Media | `AE_02` ya no ejecuta la regla: nada comprueba el autor en la evidencia del programado | Afirmar el autor; ~30 min |
| H225-04 | Baja | Al guardar, un 500 de la API de reportes llega como 500 con su detalle (prueba C-22) y un 200 con JSON mal formado da 500 (C-23) | Mapear 5xx a 503 y el JSON inválido a 400; ~1 h |
| H225-05 | Baja | La prueba del 403 de sucursal (Q-A4) solo usa un ADMIN | Aceptar mis C-51, C-55 y C-56 |
| H225-06 | Baja | P-3 (Linux) no tiene costura ni prueba | Agregar una u otra |
| H225-07 | Baja | Faltan T6-02, T6-12, T6-13, T6-15 y T6-17; T6-80 omite `CXC-ESTADO-CUENTA` | — |
| OBS-01 | Baja, anterior al PR | La misma corrupción 0x08 en `AuditoriaAdr109Tests.cs:253` (commit `b3d655f7`) deja `DireccionIp.cs` siempre fuera de la guarda de red saliente | PR aparte de B |

**Lo que se sostiene.** P-1: el 403 `DISENO_NO_PERMITIDO` sale como 403, nunca como 503 (contra la API de reportes real, guardar una copia sobre `rpt` da 200 y una sobre tablas da 4xx). P-2: el camino local solo existe en Debug; en Release los programados y «Ejecutar ahora» fallan cerrados. P-4: el marcador `CompilacionDepuracion` está en su sitio y el guion del DEMO exige `-ConApiReportes`. `ReenvioReportes.NoDisponible()` se reutiliza en las 5 rutas (guardar usa su propio 503 desde Core, con el mismo código `REPORTES_NO_DISPONIBLE`). Supuestos: que el 0x08 vino de un fallo al escribir el archivo; que la API de reportes no pone datos internos en el detalle de sus 500.

**Comprobación de C-T02 (pendiente de mi revisión de la cadena del tablero):** con este PR el gráfico `DASH-CXC-ANTIGUEDAD` deja de ser P-2 y corre en la API de reportes, que sí aplica el alcance; queda para verificar con la base nueva tras el rebase.

**Reparto.** A → rebasar (H225-02), corregir la regex (H225-01), afirmar el autor en la evidencia (H225-03) y valorar H225-04 a H225-06. B → decidir si acepta mis pruebas C-22, C-23, C-51, C-55 y C-56; corregir OBS-01; dar M-2 por cerrado al unirse el #225 rebasado. Luego el propietario decide la unión.

Respuesta requerida: A rebasa y corrige H225-01 y H225-03; avisarme el sha nuevo para repetir mis pruebas.
