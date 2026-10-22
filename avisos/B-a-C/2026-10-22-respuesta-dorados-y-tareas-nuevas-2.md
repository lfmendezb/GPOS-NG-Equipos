Para: C        De: B        Fecha: 2026-10-22
Tipo: Respuesta (a `C-a-B/2026-10-22-entrega-correcciones-pr152-y-plan-dorados.md` y al acuse de las 7 tareas) y encargo
Prioridad: Media
Repositorio y rama: GPOS-NG `b/ola5-t4-01-render` y área común
Estado: Abierto

# Respuesta sobre la tanda de dorados y tareas nuevas

Excelente lote. Uniones de hoy (propietario): #122, #130, #136, #124, tus #123, #125, #135 y #146, y #133 y #138; tu **#147 queda para la orden del propietario**. La rama de la deuda de P137/P140 aún no está empujada: te aviso.

## Decisiones sobre la tanda de dorados
- **Máquina:** **LFMB.** Tú escribes la guarda (G-1 a G-6) y el código de captura; **B corre la captura** en LFMB y te devuelve los dorados. En OSHIN-LEGION solo la guarda, como recomiendas.
- **Base del PR:** apilado sobre `b/ola5-t4-01-render` (#152), se une después de él. Coordino contigo el archivo del comparador: yo no lo toco hasta tu aviso.
- **D-12 (cultura):** adopta tu recomendación. D-25 no se captura hasta que A decida (pedido).
- **Los 5 Bajos P152b-01 a P152b-05:** quedan como seguimiento de T4-02 y de la tanda; P152b-03 (falla en Release) se cubre con un `#if` documentado o con la tanda en Debug (anótalo en el plan).

## Tareas nuevas
1. **Verificar en el código un hecho que el especialista-pos no pudo:** un cliente **inhabilitado** puede cobrar (recibos), recibir nota de crédito/débito y devolución, y su `GENERICO` no es suprimible; y qué escribe `PuenteMae` hoy en el cliente y el suplidor. Entregable: tabla [V]/[I] con archivo:línea. Fecha: **29-oct**.
2. **Inventario de reportes y vistas `rpt` que muestran la identificación del tercero** (M-5 del ADR-161 y TT): dónde sale completa, qué cambiaría al enmascarar y cuáles dependen de la letra `R`/`C`/`P`. Solo lectura. Fecha: **5-nov**.
3. **Plan de la prueba de arquitectura de `CamposPersonalesTitular.json`** (la que rechaza cualquier campo o ruta fuera de TT-01 a TT-03), (las preguntas 1, 2 y 9 de tu plan de TT todavía no se han llevado al propietario; B las lleva y te avisa; mientras tanto, escribe el plan con la lista de campos del especialista-pos). Fecha: **9-nov**.
4. **Revisión crítica de la DDL rev. 3 de D1** cuando B la publique (CS-P2 y D1-01 a D1-06): lectura, 3 días hábiles. Incluye H-13 (alfabeto de CS-P2); B lleva H-13 al arquitecto-datos y te avisa.

Respuesta requerida: acuse con fechas; si alguna choca con lo que ya tienes, dime cuál va primero.
