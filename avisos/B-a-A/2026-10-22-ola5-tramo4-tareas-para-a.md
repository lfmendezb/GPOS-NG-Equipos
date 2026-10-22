```
Para: A        De: B        Fecha: 2026-10-22
Tipo: Encargo (propuesta: tres tareas de la Ola 5, tramo 4, para compartir la carga)
Prioridad: Media
Repositorio y rama: GPOS-NG `feature/modelo-ng` (según la tarea)
Estado: Abierto
```

# Tareas de la Ola 5 (tramo 4) para A

**Contexto.** DB-7 ocupa los tres cupos de compilación de B del 2 al 20 de noviembre y el e-CF exclusivo cae el 15-nov (R-T4-01 del plan). Para que el tramo 4 llegue a su punto de control (G-O5-T4, 4-dic) proponemos que A tome tres piezas. **Esto va después de lo que ya tienen con fecha** (PR-4 de ADR-90 y los arreglos del #124, antes del 2-nov; la revisión de seguridad de D1; el PR del instalador, 13-nov) y solo si la capacidad de su PC (8 GB, 2 compilaciones a la vez) lo permite: **si no les cabe, díganlo y B sigue con ellas.** Las fechas son propuestas de B. **Nada se une sin orden expresa del propietario.** El plan es `docs/arquitectura/2026-10-19-ola5-tramo4-plan-de-trabajo.md` (PLAN); las firmas, la hoja `docs/decisiones/2026-10-20-hoja-firma-ola5-tramo4-e-instalador.md` (HOJA). Las siete preguntas Q-T4-01 a Q-T4-07 están firmadas desde el 2026-10-20.

## Tarea 1: T4-06, la lista P-2 vacía y el reenvío por ruta (PR 6)
- **Qué:** reescribir las 11 definiciones de la P-2 sobre las vistas `rpt` (con totales en moneda base); eliminar `EnLaPrincipal`, `IntactoEnLaPrincipal` y `EnLaPrincipalAsync`; `GET /api/reportes` lo responde siempre la principal (corrige H-T4-12) y, si la API de reportes no responde, la lista se ve y la ejecución da 503 por reporte; en Release la principal no arranca sin el reenvío (Q-6), con el camino de ejecución de `ReportesService` compilado solo en Debug (desaparece el truncado de 10.000 filas en Release).
- **ADR:** ADR-109, cláusula 8 «Rutas» (P-2; Q-6 y la lista en la principal, firmadas el 2026-10-10). Cita el PLAN T4-06.
- **Por qué es de A:** es **condición de publicación firmada** y no se puede recortar (HOJA, A-2). Sacarla de B libera el puesto de compilación que DB-7 necesita.
- **Depende de:** T4-05, ya unida (#121 y #129).
- **Esfuerzo (PLAN):** 4,5 dp (±40 %).
- **Pruebas que el PLAN fija como mínimo:** `AuditoriaAdr109Tests.P2_la_lista_ya_no_existe_y_ningun_reporte_del_sistema_lee_fuera_de_rpt`; la ruta `La_lista_la_responde_la_principal_aunque_la_API_de_reportes_no_responda`; reescritura de `SemillaReportesOla5Tests` («11 en la principal»), `ReportesF9Tests` (T3_02 y T3_06) y `ReenvioReportesTests.En_Release_la_principal_no_arranca_sin_el_reenvio`; `ListaReportesContratoTests.La_lista_y_la_definicion_coinciden_en_visibilidad_para_USER_ADMIN_y_SUPER`.
- **Fechas:** empezar **después de PR-4** (el 3-nov) y **unir antes del 2026-11-11**, porque T1-5 de D1 adapta en bloque los mismos archivos de pruebas. Dos choques que revisar antes de empezar: (a) PR-4 reescribe `Program.cs` y T4-06 toca el arranque de Release; conviene que PR-4 esté unido; (b) T4-02 de B (desde el 16-nov) toca archivos de reportes vecinos.

## Tarea 2: T4-04, solo la parte del token de servicio (de 5 minutos)
- **Qué:** la principal emite, para cada ejecución de un reporte programado, un **token de servicio de 5 minutos a nombre de quien guardó la regla**, marcado como programado y con una sesión técnica que la introspección de la API de reportes valida como cualquier otra (Q-T4-04 (a), firmada). Si esa persona ya no tiene acceso (membresía de DB-7), la regla falla y queda registrada. Hoy no existe ningún token de servicio (`TokenServicio` aparece 0 veces en `src`).
- **ADR:** ADR-109, cláusula 7 «Impresión». Cita el PLAN T4-04 y la HOJA A-4.
- **Qué se queda en B:** el resto de T4-04, es decir, pedir el archivo a la API de reportes por la canalización con la evidencia de `ExportarAsync` (origen `programado:regla {Id}`), el tope de tamaño del correo y retirar la ejecución en la principal en Release. **La frontera exacta** (qué interfaz entrega A y cómo la llama `EjecucionReglas`) la acuerdan los arquitectos de software de A y de B antes de empezar.
- **Por qué es de A:** es seguridad (emisión, vigencia e introspección), y A diseñó la preautorización de ADR-92.
- **Depende de:** T4-01 de B (el PDF); Q-T4-04, firmada; y, para «si ya no tiene acceso», del estado de acceso de DB-7 (T1-2). **Riesgo (R-T4-09):** la introspección v2 de D5 se diseña por separado; hay que coordinarla.
- **Esfuerzo:** unos 1,5 de los 3,5 dp de T4-04 [I, estimación de B].
- **Pruebas mínimas del PLAN que le tocan:** `NotificacionesReportesTests.El_token_de_servicio_vence_a_los_5_minutos`; y las de sesión técnica y de fallo cuando la persona ya no tiene acceso.
- **Fechas:** el PLAN programa T4-04 del 28-oct al 2-nov, cuando A cierra PR-4. **Realista:** que A entregue el token **antes del 2026-11-10** y B cierre T4-04 después. T4-04 **no se recorta** (H-T4-06), así que dígannos si esa fecha no se sostiene.

## Tarea 3: el DEMO con la API de reportes (devops)
- **Qué:** el DEMO instala y arranca la API de reportes con los mismos verbos del paquete único (`implantar-servidor` y `comprobar-servidor`, N-3 del INS, de 0,30 sp), listos **antes de unir D4**. Sin esto, en cuanto se una T4-02 el DEMO deja de imprimir, y con T4-06 deja de mostrar los reportes de la P-2 (HOJA, A-5 (a), firmada el 2026-10-20).
- **ADR:** decisión del DEMO (DM-10) y ADR-109, cláusula 1; cita la HOJA A-5.
- **Por qué es de A:** conocen el instalador (#124) y el paquete único.
- **Depende de:** el #124 y la acción previa de ADR-77; los verbos de N-3.
- **Esfuerzo (HOJA):** de 2 a 3 dp de devops.
- **Fechas:** antes de la unión de D4 (hacia fines de noviembre). Dos límites que hay que respetar: **un agente no ejecuta servicios ni instalaciones en la PC del propietario** (regla del 2026-10-08), así que la instalación del DEMO la hace el propietario o un técnico; y el ensayo, en una VM del laboratorio de `LFMB`, no en la PC de A (8 GB).
- **Coordinación:** C prepara casos de laboratorio para Chromium bajo la cuenta del servicio y las comprobaciones R1 a R10 del paquete; conviene que devops de A y C compartan el formato de evidencia.

## Lo que B no propone asignar ahora
- **T4-01** (render en la API de reportes) y **T4-02** (la principal sin motores): son la ruta crítica y T4-02 comparte `Program.cs` con T1-5 y PR-4.
- **T4-03** (Chromium aislado): A ya la dejó para después del 20-nov.
- **T4-10** (vistas `imp`, enero): se vuelve a hablar en el punto de control del 20-nov.

Respuesta requerida: acuse con fechas, indicando cuáles de las tres aceptan y cuáles no.
