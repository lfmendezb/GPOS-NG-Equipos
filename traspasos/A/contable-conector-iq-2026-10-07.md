# Especialista-contable: respuestas a la sección 8 del conector de e-CF con IQ (ADR-108)

**Para:** equipo A, equipo B y propietario · **De:** especialista-contable · **Fecha:** 2026-10-07
**Responde a:** `respuestas-A-conector-iq-2026-10-07.md`, sección 8 «Especialista-contable», puntos 1 a 6.
**Marco:** decisiones del propietario P-A1 a P-A7 (`decisiones-por-registrar-2026-10-07.md`, final) y catálogo de conceptos con `CodigoModificacion` verificado (1 anula, 2 corrige texto, 3 corrige montos, 4 reemplazo de contingencia).
**Estado:** recomendaciones técnicas; nada queda firmado (C2). Trabajé en solo lectura y no toqué `GPOS-NG-numeracion`.

## Fuentes

| Cita | Documento | Estado |
|---|---|---|
| [FMT] | DGII, *Formato Comprobante Fiscal Electrónico (e-CF)* v1.0, oct-2025. Copia local `OneDrive\Documentos\Agentes\…v1.0.pdf`, SHA-256 `c811c91a…7d5a`, **el mismo** que citan [DIS] y [RF] de B | Verificado por mí: p. 7 (`IndicadorNotaCredito`), p. 18-21 (campos 93 y 100 a 103), p. 44 (`MontoItem`), p. 56-57 (`InformacionReferencia`, `CodigoModificacion`, nota 80) |
| [G6] | DGII, *Facturación Electrónica*, guía núm. 6 (biblioteca virtual de dgii.gov.do), SHA-256 `4580592e…c7dd` | Verificado: definición de los estados Aceptado, Rechazado («no es válido para fines fiscales»), Aceptado condicional, En proceso y Anulado |
| [GL-2023] | DGII, consulta G. L. núm. 3591XXX del 11-08-2023, «ITBIS a notas de crédito» | Verificado: la nota de crédito se presenta en el 607 y se declara en el mes en que se emite; pasados 30 días solo se restituye el precio (CT art. 338, párrafo; Decreto 293-11, arts. 8 y 28) |
| [GL-2021] | DGII, consulta G. L. núm. 24318 (comunicación recibida el 06-04-2021), «Reporte de notas de créditos» | Verificado: las notas de crédito van en el 607 (NG 07-2018, modificada por la NG 10-2018, art. 1) |
| [IT] | DGII, *Informe Técnico e-CF* v1.0, actualizado al 23-03-2026 (§12 tolerancias, §13 redondeo, §19 contingencia) | Verificado por el especialista de B ([RF] de B, hash `0f1c5dca…1ff`). Yo no lo releí |
| [R293-11] | Decreto 293-11, arts. 7, 8 y 28 | Verificado por el especialista de B (imágenes de las p. 9 y 25) |
| NG 06-2018, 05-2019, 01-2020 y Ley 32-23 | — | **No las releí** en esta tarea. La Ley 32-23 la verificó B (arts. 5, 13, 17 y 26). Las normas generales quedan como supuesto donde se citan |

---

## 1. L-1 con indicador 0: ITBIS por tasa sobre la suma

**Respuesta: sí.** Es la fórmula del propio formato, y el e-CF queda «Aceptado», no condicional.
- [FMT] campo 93 (p. 18-19): `MontoGravadoI1` es la «suma de valores del monto ítem con indicador de facturación = 1, menos descuentos más recargos».
- [FMT] campos 101 a 103 (p. 20-21): `TotalITBIS1 = MontoGravadoI1 × tasa ITBIS 1`, por tasa y a nivel de documento.
- El detalle del e-CF no tiene un campo de ITBIS por línea; solo lleva `MontoItem`. **Inferido** de la estructura del área de ítems. Por eso la DGII no puede validar el ITBIS línea por línea: lo valida por tasa sobre la suma.
- Con la regla 4 de L-1 (`MontoGravadoIk = Σ MontoItem_k`; `TotalITBISk = round(MontoGravadoIk × tasa)`), la comprobación de la DGII da **diferencia cero**. Solo hay un redondeo, mitad hacia arriba ([IT] §13).
- El cálculo actual por línea (`Σ round(línea × tasa)`) se separa hasta 0,005 × líneas. Eso también quedaría dentro de la tolerancia de la DGII ([IT] §12: tantas unidades como líneas), pero la guardia de L-1 lo rechaza y no cuadraría con lo cobrado. La regla firmada es la correcta.

**Fuente:** [FMT] p. 18-21 (verificado); [IT] §12 y §13 (verificado por B).
**Impacto en el diseño:** ninguno nuevo. Confirma A-19 y P-A1.
- El ticket y la RI pueden seguir mostrando el ITBIS de cada línea como dato informativo. El ITBIS que se declara, se cobra y se cuadra en la caja es el de cada tasa.
- El 607 y la interfaz con el ERP toman `TotalITBISk` del comprobante, nunca la suma de las líneas.
- El descuento global ya repartido por línea (A-05) entra en `MontoItem` antes de sumar.

**¿Pregunta al contador?** No.

---

## 2. Refacturación sin inventario (P-A2) y E34 `ANU` a más de 30 días en el 607

**Respuesta.**
- **El inventario no tiene efecto fiscal directo.** El e-CF y el 607 no llevan cantidades de inventario.
  - El efecto está en el **costo de ventas (ISR)**: la mercancía salió una sola vez, así que el costo se reconoce una sola vez, el del documento original.
  - Con `ANU` sin mercancía y la refacturación sin movimiento, el costo no se revierte ni se duplica. P-A2 es correcta.
- **Efecto en ITBIS (verificado):**
  - Hasta 30 días, la E34 rebaja el ITBIS del original y el documento nuevo lo genera otra vez: se paga una sola vez. Esto vale aunque los dos caigan en meses distintos, porque la nota se declara en su mes ([GL-2023]).
  - Pasados 30 días, la E34 no rebaja el ITBIS ([R293-11] art. 8; CT art. 338, párrafo; [GL-2023]) y el documento nuevo lo vuelve a generar: **el ITBIS se paga dos veces**. Es el costo que avisa DF-05.
- **Fecha del documento nuevo:** la de su emisión, no la del original. Es un comprobante nuevo, no un reemplazo de contingencia (el código 4 no aplica).
- **Requisito del art. 28, párrafo I:** la nota va al **mismo adquiriente**. Si se pasa de una E32 sin identificar a una E31, se entiende que es la misma persona, ahora identificada. Esto es inferido (B ya lo marcó así).
- **E34 `ANU` a más de 30 días en el 607: sí, igual que HC-03.**
  - Toda nota de crédito se informa en el 607 y en el mes de su emisión ([GL-2021] y [GL-2023]). `ANU` y `DEV` no se distinguen para este fin: el art. 8 dice «anuladas, total o parcialmente».
  - Va con ITBIS 0, porque no rebaja el ITBIS, y entra en la línea «ITBIS de devoluciones sin rebaja fiscal» del cuadre. La forma final en el 607 sigue pendiente de **C-02** (ya abierta).
  - El documento nuevo va al 607 con su ITBIS completo.

**Fuente:** [R293-11] arts. 7, 8 y 28; CT art. 338, párrafo (citados en [GL-2023]); [GL-2021]; [GL-2023]. Que el emisor electrónico siga presentando el 607 por sus e-CF es **supuesto**: no encontré la disposición oficial que lo exima o lo obligue (ver C-41).

**Impacto en el diseño:**
- La refacturación lleva una **marca de refacturación y el vínculo al original** (A-17). Así, la interfaz con el ERP no envía costo de ventas por ella, y la E34 `ANU` no envía reversión de costo.
- **Control detectivo:** conciliación mensual «salidas de inventario = líneas facturadas − líneas de refacturación».
- **Riesgo si no se marca:** el costo se registra dos veces en el ERP si el conector del ERP calcula el costo desde las líneas del comprobante y no desde el kárdex.

**¿Pregunta al contador?** Sí, **C-41** (obligación del 607 para los e-CF). La forma del ITBIS 0 sigue en C-02.

---

## 3. Reemplazo de un B de un período ya declarado (607 presentado)

**Respuesta.**
- El e-CF de reemplazo (código 4) **no es una operación nueva**: se envía solo a la DGII y el comprador conserva el B ([IT] §19.3, verificado por B).
- Este caso no es raro, es el normal. El reemplazo puede llegar hasta 30 días después de la salida de la contingencia, y el 607 se presenta antes del día 15 del mes siguiente.
- Criterio: el **B ya informado en el 607 es el registro fiscal de la operación**. El e-CF de reemplazo **no se informa otra vez** en el 607, y **no hace falta un 607 rectificativo** si los montos son iguales a los del B, como deben serlo. Con `FechaEmision` igual a la del B (DF-04), la DGII lo ubica en el mismo período.
- **Excepción:** si el B **no** se informó en el 607 presentado (por omisión o porque se registró tarde), corresponde un 607 rectificativo de ese período con el B, nunca con el E.

**Fuente:** [FMT] p. 56-57 (código 4; `FechaNCFModificado` condicionada al reemplazo; tipo equivalente) y [IT] §19.3. El tratamiento en el 607 **no tiene fuente; es criterio profesional**. Coincide con Q-DGII-1 de B, que sigue abierta.

**Impacto en el diseño:**
- `rpt.Formato607` incluye el rol `O` (el B) y **excluye siempre el rol `R`**. Es la misma regla de A-10 para el ERP.
- El rol `R` queda **exento del bloqueo por período fiscal declarado** (HC-02), porque no cambia montos ni la fecha del documento. A-18 ya lo propone: debe quedar escrito como exención expresa en el servicio.
- Control: conciliación «B emitidos en contingencia = reemplazos aceptados», con alerta a los 20 días (ya en [RF] de B).

**¿Pregunta al contador?** Sí, **C-39**.

---

## 4. `EN_PROCESO` que termina en `RECHAZADO` con la RI ya entregada

> **Sustituido en parte (2026-10-07):** el propietario decidió que un rechazo **anula automáticamente** el documento y que no se reemite (POS-1). Valen la base normativa y el control; la «reemisión del mismo documento», `ComprobanteReemitido` y C-40 quedan reemplazados por la sección 8.

**Respuesta.**
- Un e-CF rechazado **«no es válido para fines fiscales»** ([G6]). Por eso **no se corrige con una E34**: una nota modificaría un comprobante sin validez y rebajaría un ITBIS que nunca quedó declarado.
- Tampoco corresponde una ANECF, que es solo para los e-NCF no enviados a la DGII ni al receptor ([ANECF] p. 3, verificado por B).
- **Corrige un e-CF nuevo**, del mismo tipo y con un **e-NCF nuevo**, por la misma operación y los mismos montos, una vez corregida la causa del rechazo.
  - Que el e-NCF rechazado no se pueda reutilizar lo dicen fuentes secundarias (blogs de Alegra y Siempre al Día). Coincide con R-9 de [ECF-E] y con A-03, pero **no lo verifiqué en una fuente oficial**.
- **Para el cliente:** hay que **entregarle la RI nueva**. Si recibió una E31, el crédito fiscal que tome con el e-NCF rechazado no es válido.

**Fuente:** [G6] (verificado); [FMT] p. 56 (el NCF modificado debe haberse remitido antes a la DGII); [ANECF]. La reemisión con un e-NCF nuevo es **secundaria o criterio profesional**.

**Impacto en el diseño (para A y para el especialista-pos):**
- Es una **reemisión fiscal del mismo documento**, no una venta nueva:
  - sin inventario, sin caja y sin asiento nuevo;
  - un `fiscal.Comprobante` nuevo para el mismo `DocumentoId`;
  - el rechazado se conserva con su respuesta como evidencia (ADR-08: el documento emitido no cambia).
- **Arquitecto-datos:** decidir si es un rol nuevo o una generación del rol `O`. Una generación nueva no basta, porque A-01 solo la permite si nada llegó al proveedor.
- **ERP:** si la venta ya salió con el e-NCF rechazado, se manda un evento aparte, `ComprobanteReemitido`, igual que `ComprobanteReemplazado` (A-10). Nunca se manda la venta otra vez.
- **Control:**
  - alerta inmediata;
  - reporte «e-CF rechazados con RI entregada, sin reemisión» (plazo objetivo: el mismo día);
  - bitácora con el usuario que reemite y la constancia de que se entregó la RI nueva.

**¿Pregunta al contador?** Sí, **C-40**: la fecha del e-CF nuevo cuando el rechazo cruza el fin de mes, y si el e-NCF rechazado se informa en el 608 o en ningún formato.

---

## 5. Devolución total con `DEV`: ¿código 3 o 1?

**Respuesta: la DGII acepta el 3.**
- [FMT] p. 57 solo valida el **código** (1 a 5, nota 80: los códigos 1 a 3 solo en notas de crédito o débito). No hay ninguna validación cruzada entre el código y los montos.
- La única regla de montos ligada a un código es la del **código 2**: `MontoItem` = 0 ([FMT] p. 44, nota 74).
- Una nota con código 3 por el total del comprobante es una «corrección de montos» a cero, válida en el formato.

**Criterio:** el código 1 («Anula el NCF») es semánticamente más exacto para una única devolución por el 100 %. Aun así, **recomiendo mantener el catálogo firmado (3)**:
- no hay efecto fiscal distinto: el ITBIS se rebaja igual y el plazo de 30 días aplica igual;
- con notas parciales anteriores, «anular» el NCF sería ambiguo;
- la anulación queda reservada a `ANU`, que por B-3 cubre el total.

**Fuente:** [FMT] p. 44 y 57 (verificado). Que la DGII no aplique una validación no publicada es **inferido**.
**Impacto en el diseño:** ninguno. Agregar un caso obligatorio en la certificación con IQ: «E34 `DEV` por el total con código 3 → Aceptado». Para qa-automatizado y B.
**¿Pregunta al contador?** No. Si la certificación lo rechaza, se reabre.

---

## 6. Redacción de A-17

**Confirmo, con una precisión.** GPOS NG **no hace el asiento** (ADR-73.2), pero el **efecto fiscal no lo decide el ERP ni el contador**: lo fija la norma ([R293-11] art. 8; CT art. 338, párrafo), y GPOS NG, como auxiliar fiscal, lo aplica.

**Texto propuesto para A-17:**
> El núcleo calcula `FueraPlazoFiscal` y `IndicadorNotaCredito` con una sola función (la de MD-46). Con la marca, aplica el **efecto fiscal**:
> - E34 con indicador 1;
> - 607 con el ITBIS de la nota en 0 (HC-03, forma final según C-02);
> - aviso no bloqueante con línea en `_LOG`;
> - reporte «Notas de crédito con más de 30 días».
>
> Entrega la marca y los montos al ERP como dato. **El asiento lo define el ERP o el contador:** la reducción del ingreso por el precio y el tratamiento del ITBIS no rebajado (gasto o pérdida, según la política del cliente). GPOS NG no genera asientos.

**Otra precisión.** Lo que se le devuelve al cliente (saldo a favor o nota `P` según ADR-70) es una decisión **comercial** del emisor. Fiscalmente, solo el precio reduce la venta. En el cambio de tipo, el emisor normalmente acredita el total al cliente y asume el ITBIS no rebajado.

**Fuente:** [R293-11] art. 8; [GL-2023]; ADR-73.2 y 73.3 (según A).
**Impacto en el diseño:** solo de redacción en ADR-108 y A-17. El cálculo y el reporte ya están planificados.
**¿Pregunta al contador?** No: C-02 ya cubre la forma en el 607.

---

## Preguntas nuevas para el contador del propietario

| # | Pregunta | Recomendación del especialista |
|---|---|---|
| **C-39** | Cuando un B de contingencia ya informado en un 607 presentado se reemplaza con un e-CF de código 4 con la fecha del B, ¿basta con no informar el e-CF de reemplazo en el 607, sin 607 rectificativo? | Sí: el B es el registro fiscal y el reemplazo no cambia montos. Rectificativo solo si el B se omitió |
| **C-40** | Un e-CF rechazado por la DGII después de entregar la RI: ¿se reemite con un e-NCF nuevo y la fecha de la reemisión, aunque el rechazo cruce el fin de mes? ¿El e-NCF rechazado se informa en el 608 o en ningún formato? | e-NCF nuevo, misma operación y montos; fecha de la reemisión; el rechazado no va al 608 (por confirmar) |
| **C-41** | ¿El emisor electrónico sigue obligado a presentar el 607 por las ventas con e-CF, o solo por lo facturado fuera del sistema electrónico (607 complementario)? | Afecta el alcance de `rpt.Formato607` y de HC-03. Hasta que responda, se mantiene el 607 completo |

---

## Riesgos

| Riesgo | Severidad | Control |
|---|---|---|
| Costo de ventas duplicado en el ERP por la refacturación | Alta | Marca de refacturación; el ERP no envía costo; conciliación de salidas de inventario |
| e-CF rechazado con RI entregada sin reemitir (el cliente toma un crédito no válido) | Alta | Alerta, reporte del mismo día y bitácora |
| Reemplazo `R` informado en el 607 o en el ERP (venta e ITBIS dobles) | Alta | Exclusión del rol `R` en `rpt.Formato607` y en la interfaz ERP; conciliación B ↔ e-CF |
| ITBIS pagado dos veces sin que lo vea el contador (cambio de tipo a más de 30 días) | Media | Aviso DF-05 y reporte mensual |

## Supuestos
- Que el e-NCF rechazado no se pueda reutilizar sale de fuentes secundarias y de lo que ya asumen A y B.
- No releí las NG 06-2018, 05-2019 y 01-2020 ni el texto de la NG 07-2018. Su efecto en el 607 de los e-CF depende de C-41.
- El área de ítems del e-CF no tiene un campo de ITBIS por línea (inferido de la estructura del formato).


---

## 8. Adenda (2026-10-07): anulación automática por rechazo, POS-2 y POS-9

### 8.1 Efecto de la anulación automática (POS-1) en los puntos 3 y 4

**Punto 4: cambia la forma, no la base.**
- El e-CF rechazado no tiene validez fiscal ([G6]). Por eso la anulación es **interna de GPOS NG**:
  - no lleva E34, porque no hay comprobante válido que modificar;
  - no lleva ANECF, porque el e-NCF ya se envió ([ANECF] p. 3).
- La decisión del propietario es compatible con la norma. Tiene tres condiciones contables:
  1. **Si la mercancía salió o el servicio se prestó, el documento nuevo no es opcional.** La operación ocurrió y necesita un comprobante válido; si falta, hay una venta sin comprobante. En la caja, este es el caso normal: el cliente se fue con la mercancía.
     - Recomendación: la anulación automática deja una **tarea obligatoria** «emitir el documento sustituto», con alerta. No basta con «si hace falta».
     - Solo se cierra sin documento nuevo si consta que la operación no ocurrió (el cliente devolvió todo).
     - Fuente: criterio profesional. El deber de emitir comprobante en toda transferencia (Código Tributario y Decreto 254-06, art. 4, citado en [GL-2023]) no lo releí artículo por artículo.
  2. **Inventario: el mismo patrón que P-A2.**
     - Si hay documento sustituto: la anulación va **sin** devolver mercancía y el sustituto **sin** mover inventario, ligado al anulado. Así, costo de ventas una sola vez y kárdex sin movimientos ficticios.
     - Si no lo hay (la operación no ocurrió): la anulación devuelve la mercancía.
     - Si se devolviera siempre, quedarían existencias que no están en la tienda.
  3. **Caja y cuentas por cobrar: el cobro no desaparece.**
     - El pago del documento anulado pasa al sustituto.
     - Si no hay sustituto, queda como **saldo a favor del cliente** (ADR-70) o sale como reembolso con soporte.
     - Nunca debe quedar como sobrante sin explicación en el arqueo.
- **ERP:** como un mensaje entregado no se reescribe (73.4), la venta ya enviada se revierte con un evento `DocumentoAnuladoPorRechazo`, y el sustituto viaja como venta nueva **marcada sin costo** si sustituye con mercancía ya entregada. Reemplaza al `ComprobanteReemitido` del punto 4.
- **Excepciones que el arquitecto debe cubrir:**
  - **Rechazo de un e-CF de reemplazo (rol `R`, código 4).** El B de contingencia **sigue siendo válido**: el documento **no** se anula. Se corrige y se envía un reemplazo nuevo dentro del plazo de 30 días. Anular aquí borraría una venta ya declarada en el 607 (punto 3). **Alta.**
  - **Rechazo de una E34 o una E33.** Se anula la nota, no la factura. Si el dinero ya se devolvió al cliente, la nota sustituta es obligatoria por la misma razón que en la condición 1.
- **Punto 3:** sin cambios, salvo la excepción del rol `R` de arriba.

### 8.2 POS-2: fecha del documento sustituto y formato del e-NCF rechazado

**Fecha (criterio profesional, con base normativa):**
- El ITBIS nace al emitir la factura o al entregar el bien, lo que ocurra primero ([R293-11] art. 7, verificado por B). La entrega ocurrió en la fecha de la venta original, así que el sustituto debe llevar **`FechaEmision` = fecha de la operación original**.
- El formato no lo impide: solo exige `FechaHoraFirma` ≤ ahora ([FMT] p. 58).
- Cabe en el **tope de 5 días** hacia atrás (HC-02). El rechazo suele llegar en minutos o en horas.
- **Si el rechazo llega en el mes siguiente:**
  - Período original **aún no declarado** (antes de presentar el 607 y el IT-1, hasta el día 15 o 20): la misma regla, con la fecha original.
  - Período original **ya declarado** (bloqueo de HC-02): el sustituto lleva **la fecha de hoy**, y el reporte de excepciones lo señala al contador. El contador decide si rectifica el período anterior.
  - Fuera del tope de 5 días: la fecha de hoy, con la misma marca.
- Que la DGII acepte una `FechaEmision` anterior a la de firma en un e-CF ordinario es **inferido**. Es la misma duda de IQ-18 para el código 4, y conviene probarlo en la certificación.

**Formato del e-NCF rechazado:**
- **En ningún formato** (criterio profesional).
  - No va al **608**, porque el comprobante no llegó a ser válido. La DGII ya tiene su estado («Rechazado»), y el 608 de comprobantes anulados supone uno válido o un número no usado.
  - No va al **607**, porque no tiene validez fiscal.
  - Tampoco lleva ANECF.
- Queda en el reporte interno «e-NCF rechazados y su sustituto», que también sirve para la prueba de integridad de secuencias (emitidos + rechazados + anulados + disponibles = autorizados).
- **Sin fuente oficial:** no encontré una regla de la DGII sobre el 608 para e-NCF rechazados. Pasa al contador.

### 8.3 POS-9: redondeo del vuelto a favor del cliente

**Respuesta: sin efecto en el 607 ni en el ITBIS; sí tiene un pequeño efecto contable.**
- El documento y el e-CF conservan el total exacto. `MontoTotal` es igual al total del documento (L-1), y `TablaFormasPago` cuadra con ese total.
- El 607 informa el total exacto, también en la columna de efectivo.
- La diferencia (menos de RD$1 por venta) **no es un descuento sobre la venta**: no reduce el ingreso ni la base del ITBIS. Es una **pérdida o gasto por redondeo de efectivo** del emisor.
- Tratarla como descuento obligaría a cambiar el total del comprobante después de emitido. Lo descarto: contradice L-1 y ADR-08.
- Fuente: criterio profesional. No hay una norma de la DGII sobre el redondeo del vuelto.
- La deducibilidad para el ISR de un gasto sin comprobante, aunque es inmaterial, la decide el contador.

**ERP (ADR-73):**
- GPOS NG manda, en el resumen de cobros o del cierre de caja, un concepto aparte, **«Redondeo de efectivo»**, con el monto acumulado del cierre.
- El ERP lo asocia a la cuenta que defina el contador (gasto, o diferencias de caja).
- El efecto del cierre: caja por el efectivo real, ventas o cuentas por cobrar por el total exacto, y «Redondeo de efectivo» por la diferencia.
- GPOS NG no hace el asiento.

**Controles:**
- Solo en efectivo y en el vuelto.
- Diferencia de 0,01 a 0,99 por cobro, nunca un peso entero ni más.
- Calculado por el sistema, no tecleado.
- Línea propia en el arqueo, para que no se mezcle con los faltantes.
- Reporte por cajero y por período, para detectar un abuso por volumen.

### 8.4 Preguntas nuevas para el contador

**C-40 queda sustituida** por C-42 y C-43, adaptadas a la anulación automática.

| # | Pregunta | Recomendación |
|---|---|---|
| **C-42** | Cuando un e-CF rechazado se anula y se emite uno sustituto con un e-NCF nuevo, ¿qué fecha lleva el sustituto si el rechazo llega en el mes siguiente? | La fecha de la operación original si el período no está declarado y cabe en el tope de 5 días; si no, la de hoy, con aviso al contador para una posible rectificación |
| **C-43** | ¿Un e-NCF rechazado por la DGII se informa en el 608 o en algún otro formato? | En ninguno; queda en el reporte interno de secuencias |
| **C-44** | ¿Qué cuenta y qué tratamiento en el ISR lleva el «redondeo de efectivo» del vuelto? | Gasto por diferencias de caja; la deducibilidad la decide el contador |

### 8.5 Riesgos nuevos

| Riesgo | Severidad | Control |
|---|---|---|
| Venta entregada sin comprobante válido porque la anulación automática no exigió el sustituto | Alta | Tarea obligatoria con alerta; reporte «anulados por rechazo sin sustituto» |
| Anular la venta cuando se rechaza un e-CF de reemplazo (rol `R`), con el B ya declarado | Alta | Excluir el rol `R` de la anulación automática |
| Existencias ficticias por devolver la mercancía en la anulación automática | Media | Patrón P-A2: anulación sin mercancía y sustituto sin inventario |
| Abuso del redondeo del vuelto | Baja | Tope por cobro, cálculo automático y reporte por cajero |

### Cierre
- Estado: Completado
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\contable-conector-iq-2026-10-07.md`
- Supuestos: los de la sección «Supuestos»; además, que la DGII acepte en un e-CF ordinario una `FechaEmision` anterior a la de firma (inferido), y que no haya una regla oficial sobre el 608 para los e-NCF rechazados
- Decisiones candidatas a ADR:
  - anulación automática por rechazo con sustituto obligatorio si la operación ocurrió, inventario según el patrón P-A2 y el evento `DocumentoAnuladoPorRechazo` (alternativa descartada: anular siempre con devolución de mercancía);
  - rol `R` excluido de la anulación automática;
  - rol `R` excluido del 607 y exento del bloqueo de HC-02;
  - «Redondeo de efectivo» como concepto aparte del cierre hacia el ERP (alternativa descartada: tratarlo como descuento)
- Entregas a otros agentes:
  - arquitecto-software y arquitecto-datos de A: diseño de la anulación automática con las condiciones de 8.1, la marca de refacturación y del sustituto sin costo, la exención y exclusión del rol `R`, el concepto «Redondeo de efectivo», y el texto de A-17;
  - especialista-pos: la tarea del sustituto en la caja y la RI nueva;
  - qa-automatizado y B: certificación de E34 `DEV` total con código 3 y de `FechaEmision` anterior a la firma;
  - propietario: C-39, C-41, C-42, C-43 y C-44 al contador (C-40 queda sustituida)
- Próximo paso recomendado: que el arquitecto incluya las condiciones de 8.1 en el diseño de la anulación automática antes de traerlo a firma.
