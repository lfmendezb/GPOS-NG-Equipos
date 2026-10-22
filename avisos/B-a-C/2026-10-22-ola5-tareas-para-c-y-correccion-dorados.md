```
Para: C        De: B        Fecha: 2026-10-22
Tipo: Encargo (tareas nuevas, corrección de la tarea 1 y aviso de T4-01 en construcción)
Prioridad: Media
Repositorio y rama: GPOS-NG `feature/modelo-ng` (según la tarea); área común `traspasos/C/`
Estado: Abierto
```

# Tareas nuevas para C y corrección de la tarea 1 (archivos dorados de T4-01)

Lo que C ya tiene con fecha **va primero**: revisión de las pruebas de #130 y #122 (28-oct, entregada), revisión crítica del #127 (29-oct, entregada), plan de pruebas de E-1 de ADR-93 (5-nov), y de las cinco tareas del aviso `2026-10-21-tareas-nuevas-para-c.md` las que siguen abiertas (las 4 pruebas inestables, 13-nov; casos de laboratorio para Chromium, antes del 20-nov; cuestionarios CC-01 a CC-05, 6-nov; revisión crítica de los PR de D1). Estas tareas son **después**, o en paralelo si la capacidad lo permite (la PC de C es inestable): **si no les cabe, díganlo y B sigue con ellas.** Las fechas son propuestas de B. **Nada se une sin orden expresa del propietario.**

## Corrección de la tarea 1: archivos dorados de T4-01
- **Qué pasó:** el 2026-10-21 B les asignó «archivos dorados de T4-01 por tipo de formato y papel» (6-nov). El 2026-10-22 B lanzó la construcción de T4-01 y le pidió al agente que construye (rama `b/ola5-t4-01-render`, árbol `GPOS-B-t4-01`) que **capture él mismo la línea base mínima** que el PLAN exige antes de mover el render: los archivos dorados del HTML de los 13 tipos en Carta, 80 mm y 58 mm, y el PDF estándar, desde la principal tal como está (son la entrada de `RenderTrasladoTests`). Las dos asignaciones se solapan.
- **Cómo queda:** el agente deja esa **línea base mínima**; C la **revisa y la amplía**, en lugar de crearla de cero. Concretamente:
  - **Revisar** que los dorados capturados son de la principal sin tocar y que `RenderTrasladoTests` falla de verdad si el HTML cambia (mutación: alterar una línea del formato y comprobar que la prueba cae).
  - **Ampliar** con lo que el mínimo no cubre: variantes fiscales (B01, B02, B14, B15, B16, y e-CF E31 a E34 cuando aplique), formatos con imagen (WEBP, PNG), `MarcarCopia` y `LetraNumero`, documentos con muchas líneas y con caracteres especiales.
  - Es la **fuente de la puerta de regresión de ADR-110, cláusula 9**, así que conviene dejarla bien ordenada y documentada.
- **Fecha:** se mantiene el 2026-11-06. B avisará cuando el agente deje la línea base en la rama (fecha por confirmar; no hay compromiso).

## Tarea 2: revisión crítica de T4-01, cuando B abra el PR
- **Qué:** revisión crítica de las pruebas del PR de T4-01 (render en la API de reportes, aditivo), con el criterio de «pruebas que no fallarían si se quita la línea que protegen» (como P120-01). Informe en `traspasos/C/` y comentario en el PR.
- **Foco:** `RenderTrasladoTests`, `RenderInternoTests` (las rutas solo por la canalización, ACL, 30 s, 429), `ArquitecturaReportesTests.Solo_GPOS_Reportes_Api_trae_motores_de_render` y la que debe seguir intacta (`AuditoriaAdr109Tests.La_API_de_reportes_no_abre_conexiones_salientes...`).
- **Fecha:** 5 días hábiles desde el aviso de B. Se espera el PR hacia el 27-oct.

## Tarea 3: plan de pruebas de T4-02 y fixture del «anfitrión de la API de reportes en el proceso»
- **Qué:** T4-02 saca los motores de render de la principal y obliga a que muchas pruebas corran con la API de reportes en el proceso, como ya hacen las F9. Dejar **diseñado** (no construido):
  - el fixture que levanta el anfitrión de la API de reportes dentro del proceso de pruebas;
  - la lista de pruebas que deben pasar a usarlo: `ImpresionDocumentosTests`, `ModeloNg/ReimpresionTests`, `ModeloNg/ReglasReimpresionTests`, `NumeracionPc3EjemploTests`, `SeguridadPc3Tests` y `Mvp/FlujosMvpTests`;
  - el plan de `ClienteRenderTests` (503 con el documento guardado, reintento que no cuenta otra copia, dueño de la canalización verificado antes de enviar).
- **Por qué:** T1-5 de D1 también adapta en bloque archivos de pruebas, y T4-02 se une después. Tenerlo diseñado baja el riesgo de choque. Fuente: PLAN, T4-02 y sección 6.4.
- **Depende de:** T4-01 (para construirlo); el diseño no.
- **Fecha:** diseño antes del 2026-11-13.

## Tarea 4: plan de pruebas de T4-04 y T4-06
- **Qué:** plan de pruebas (no construcción) de T4-04 (reportes programados con el token de servicio de 5 minutos, Q-T4-04) y de T4-06 (la lista P-2 vacía y el reenvío por ruta). B ofreció a A el token de T4-04 y T4-06; quien las construya usa el plan. Fuente: PLAN y HOJA `docs/decisiones/2026-10-20-hoja-firma-ola5-tramo4-e-instalador.md`, A-4.
- **Fecha:** antes del 2026-11-02.

## Tarea 5: revisión de las pruebas de #137, #139 y #140 (pila de ADR-90)
- **Qué:** C revisó las pruebas de #122 y #130. Faltan **#137** (PR-1b), **#139** (PR-4, borrador) y **#140** (PR-2, borrador). A informó que la suite oficial completa sobre la pila está en verde; falta la revisión crítica de sus pruebas, con el mismo criterio. Esto destraba la unión de la pila (siempre con orden del propietario).
- **Fecha:** 2026-11-02, antes de la unión que A espera para PR-4 y DB-7 (comparten `Program.cs`).

## Tarea 6 (opcional): plan de pruebas de TT (ADR-92)
- **Qué:** las cuatro pruebas de arquitectura de F-4 (lista de campos de TT-02 versionada, sin campos extra en el JSON, clase `Esencial` en la lista aprobada, solo personas físicas) más las pruebas de servicio de rectificar y suprimir, incluida la supresión con deuda pendiente (F-9) y la del historial temporal (F-5). Fuente: la hoja de ADR-92, `docs/decisiones/2026-10-22-hoja-firma-adr92-precisiones.md` en `master` de GPOS-NG.
- **Depende de:** la lista de campos de TT-02 (la fija el especialista-pos; sin ella no se puede cerrar).
- **Fecha:** sin fecha; B responde después del 20-nov.

## Lo que B no propone asignar
- Código de producción de la Ola 5 (T4-01, T4-02, T4-04): lo construye B o A.
- La medición B9 (`MedicionRender`, `MedicionVistasP2`): debe correr sola en `LFMB`.

Respuesta requerida: acuse con fechas, indicando cuáles aceptan y cuáles no.
