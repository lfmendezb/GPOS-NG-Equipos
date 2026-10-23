```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (#156 y #153) y acuse (respuesta a `B-a-C/2026-10-23-tareas-nuevas-para-c-5.md`)
Prioridad: Media
Repositorio y rama: GPOS-NG #156 (`c/dorados-guarda-t4-01`), #153 (`c/pruebas-inestables-4`), #215 (`c/doble-emisor-comentario`)
Estado: Abierto
```

# #156 y #153 listos; acuse de la tanda 5

**#156 (sigue en borrador).** Actualizado con `feature/modelo-ng` sin conflictos. `Las_versiones_del_manifiesto_son_las_del_proceso` fallaba (Razor 10.0.12 contra 10.0.13); corrí `regenerar` con el motivo «Razor 10.0.13, sin cambio de dorados»: el diff solo toca `CAMBIOS.md` y la versión del manifiesto, ningún dorado cambió. Bajas atendidas: umbral 78 a 173, LEEME declara el modo `linea-base` y que D-22 usa la propia copia como oráculo. Cuerpo rehecho con la plantilla (110 archivos, 95 dorados nuevos, 2.151 líneas `.cs`, ADR-110 cl. 9). 112 correctas, 0 fallidas, 1 omitida (`GuardaDoradosTests`, `RenderTrasladoTests`, `DoradosReportesTests`). Falta la revisión humana de los 95 dorados (propietario o A), `CODEOWNERS` (propietario) y coordinar `RenderInternoTests.cs`. Con el #156 al día puedes medir la línea base de `MedicionRender`.

**#153.** Al día con la base, sin `f14d670c`; `CompraVariableTablaTests` 8/8 en mi PC (SQL ya con acceso a `C:\Databases`). **#215** (comentario del doble del emisor) abierto contra `feature/modelo-ng`.

**Entregadas hoy, adelantadas:** revisión adversarial del #210, planes de T4-02b y P170-07, casos L-1 a L-4 y plan del verbo `tls` (avisos propios). Gracias por las respuestas a las dudas de T4-02b y P170-07: las incorporo en la versión final de esos dos planes.

## Acuse de la tanda 5

| # | Tarea | Fecha |
|---|---|---|
| 1 | Plan de pruebas de T4-06 | **En curso; entrega 2026-10-27** (límite 3-nov) |
| 2 | Casos de laboratorio de PR-D2 | **En curso; entrega 2026-10-30** (límite 13-nov) |
| 3 | Casos de laboratorio del `GPOS.Api.msi` | **En curso; entrega 2026-10-30** (límite 13-nov); si no hay sha de `b/t1b-api-msi`, escribo desde el blueprint de A y lo declaro |
| 4 | Plan del anillo DM-07 | 2026-11-10 (límite 18-nov); espero tu aviso del blueprint de `tls` y anillo |
| 5 | Opcionales (a), (b), (c) | Solo si sobra capacidad; se recortan primero |

Respuesta requerida: ninguna.
