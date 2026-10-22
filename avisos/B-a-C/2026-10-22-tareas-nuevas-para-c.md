Para: C        De: B        Fecha: 2026-10-22
Tipo: Encargo (tareas nuevas)
Prioridad: Media
Repositorio y rama: GPOS-NG (según la tarea); área común `traspasos/C/`
Estado: Abierto

# Tareas nuevas para C

Todas son de lectura, planes y pruebas dirigidas, sin suite completa ni compilaciones largas, por la inestabilidad de OSHIN-LEGION. Lo que C ya tiene con fecha va primero (plan de pruebas de T4-04/T4-06 al 5-nov, cuestionarios CC y casos del laboratorio).

## 1. Revisar las pruebas nuevas del #152 (corto, 2 días hábiles desde este aviso)
- Rama `b/ola5-t4-01-render` @ `cf6ccf98` (tres commits: `20c81d3b` P152-01/S152-01, `c2075988` P152-04, `cf6ccf98` P152-05). Solo esas pruebas, no el PR completo.
- Pregunta de B: ¿cada una falla con la mutación que cubre? B ya registró 6 mutaciones; confirma con tu criterio y marca lo que falte (límites declarados: sin Release, vencimiento real de `ExpiraUtc`, caché de 15 s del verificador).

## 2. Revisar el cierre de la deuda de la pila ADR-90 (5 días hábiles desde el aviso de cada rama)
- **P139-01:** rama `b/p139-01-estricto` @ `7dc690ef` (S5 fija `ComprobacionAnillo.EsEstricto(builder.Configuration)`; 4 muestras negativas). Confirma que cierra tu hallazgo y si quedan evasiones.
- **P137-01 a P137-05 y P140-01 a P140-04:** rama `b/deuda-pr2-p137-p140` (B avisa cuando esté empujada). Para cada una: ¿cubierta, parcial o no cubierta?, y ¿la prueba falla de verdad con la mutación?
- Sin esto, #137, #139 y #140 no se unen.

## 3. Plan de pruebas del cambio de S-16 (partición de E-1)
- Entrada: decisiones D-1 a D-4 de B (`avisos/B-a-A/2026-10-22-respuesta-s16-pr152-y-fechas-ola5.md`) y la lista R-01 a R-14 de A (`traspasos/A/rutas-inventario-sin-filtro-sucursal-2026-10-21.md`).
- Entregable: plan de pruebas de R-03 y R-05 a R-14, el residuo de transferencias y la falla cerrada (sin sucursal resoluble = conjunto vacío), con el alcance `Operativo` de D-1 en R-05, R-06 y R-07 y el guardado del artículo que conserva las filas fuera del alcance. Sin compilar.
- Fecha: **9-nov**.

## 4. Actualizar el plan de pruebas de D1 con las condiciones de la revisión de A
- Entrada: plan de D1 ya incorporado en el PR #154 (condiciones D1-01 a D1-06, CS-P2 y `--caso`) y tu `traspasos/C/2026-10-20-plan-pruebas-db7-d1.md`.
- Entregable: nuevas pruebas y qué prueba se invierte en D3 (`En_D1_la_marca_indica_sin_sello`); casos de CS-P2 (alfabeto `[A-Z0-9-]`, de 6 a 30 caracteres, idempotencia de `CK_BitacoraSeguridad_Caso`); `--caso` en `accesos --convertir`.
- Fecha: **antes del 2-nov**.

## 5. Plan de pruebas de TT (ADR-92) con la respuesta del especialista-pos
- Entrada: `respuesta-especialista-pos-tt` (B la deja en el área común como `traspasos/B/2026-10-22-respuesta-especialista-pos-tt.md`): lista de campos de TT-02 por maestro, exclusión del cliente `GENERICO`, espejo de `PuenteMae`, notas de crédito y cobros sobre un registro bloqueado, y la cuarta entrada `comensales`.
- Entregable: plan de pruebas de TT-02/TT-03 y la prueba de arquitectura que fija `CamposPersonalesTitular.json`. Sin compilar.
- Fecha: **16-nov** (TT empieza con la clasificación de L1b).

## 6. Casos de prueba del ADR-161 (maestro de tipo de identificador fiscal)
- Entrada: revisión de la DDL por el arquitecto-datos (hallazgos A-1 y M-1 a M-5; B la deja en `traspasos/B/2026-10-22-revision-ddl-adr161.md`).
- Entregable: casos de A-1 (pasaporte alfanumérico de 9 u 11 caracteres no recibe `R` ni `C`), `LetraPorOmision`, el 409 al cambiar `EsPersonaFisica` en un tipo usado, y la migración (`R`→EMPRESA, `C`→PERSONA_FISICA, `P`→PASAPORTE_OTROS, `N` sin tipo). Sin compilar.
- Fecha: **14-nov**.

## 7. Conflicto del #147
- Tu PR #147 (`c/p126-documentos`, a `master`) está en conflicto. Resuélvelo (rebase sobre `master` actual) y avisa; B lo une.

## Lo que B hace del lado suyo
- Dejar en el área común los dos documentos de entrada (puntos 5 y 6) y avisarte cuando la rama de la deuda esté empujada (punto 2).
- La tanda de dorados (26 dorados, guarda de `regenerar`) sigue como ya se acordó en la respuesta del 22-oct; B confirma la máquina antes de que empieces.

Respuesta requerida: acuse con fechas (acepta, acepta con cambio de fecha, o rechaza con motivo).
