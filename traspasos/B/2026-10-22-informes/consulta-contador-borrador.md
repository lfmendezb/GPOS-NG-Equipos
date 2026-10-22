# BORRADOR · Consulta al contador sobre conservación de datos de titulares y comprobantes fiscales (GPOS NG, ADR-92, fase TT)

- **Estado:** borrador para que lo revise el propietario. **No se ha enviado.** No contiene dictámenes: cada «opción recomendada» es una propuesta técnica del equipo B, no una opinión contable.
- **Fecha del borrador:** 2026-10-22 · **Preparado por:** especialista en contabilidad (agente) para el equipo B.
- **Convención:** **[V]** = verificado en un documento del repositorio (se cita la ruta y la línea) · **[I]** = inferido o conocimiento general, no verificado en una fuente oficial en esta sesión. Toda norma que no se pudo verificar se marca «a confirmar por el contador». Que una norma esté citada en un documento del repositorio no significa que se haya releído su texto oficial en esta sesión.
- **Fuentes del repositorio:** `CLAUDE.md`; `docs/adr/ADR-092.md`; `docs/decisiones/2026-10-22-hoja-firma-adr92-precisiones.md` (en adelante, «hoja»); `docs/pos/2026-10-01-ncf-y-existencias-iniciales.md` (en adelante, «NCF-01»); `docs/adr/ADR-067.md`; `docs/adr/ADR-111.md`; y la respuesta del especialista-pos en `GPOS-NG-Equipos/traspasos/B/2026-10-22-respuesta-especialista-pos-tt.md` (en adelante, «POS-TT»).

---

## Resumen (una página)

**Para qué es la consulta.** GPOS NG va a permitir que una empresa atienda la solicitud de una persona física (cliente, suplidor o empleado) que pida suprimir sus datos personales (Ley 172-13). El diseño firmado (ADR-92, TT-03) dice: se **anonimizan** los datos que no hay obligación de conservar (teléfonos, correos, dirección, notas) y se **bloquean** los que sí, que son el nombre y el documento de identidad, porque aparecen en comprobantes fiscales que se deben conservar 10 años [V `docs/adr/ADR-092.md:23-26`]. Cuando termina la conservación, el ADMIN puede anonimizar también el nombre y el documento desde un listado; el sistema calcula la fecha, no la guarda [V hoja:23]. Para construirlo necesitamos que el contador confirme **cuándo empieza y cuándo termina** la obligación de conservar y **qué documentos la generan**.

**Las siete preguntas, en una línea cada una:**
1. **Desde cuándo se cuentan los 10 años** (comprobante, cierre del ejercicio o declaración). Recomendación de B: desde el cierre del ejercicio fiscal del último documento, suspendido mientras haya fiscalización, igual que lo ya firmado para adjuntos y archivos fiscales [V `docs/adr/ADR-067.md:88`; `docs/adr/ADR-111.md:53`]. Hay una incoherencia interna que la respuesta resuelve: ADR-92 dice «desde el último comprobante».
2. **Qué documentos obligan a conservar** el nombre y el documento del titular. Recomendación: facturas, notas, devoluciones, recibos, cheque devuelto, compras y pagos, y todo saldo vivo; no las cotizaciones, pedidos, conduces ni órdenes de compra sin factura.
3. **Nota de crédito después del bloqueo:** si es válida y obligatoria. Recomendación: permitirla, junto con cobros y pagos de saldos anteriores.
4. **B11 y B13 con persona física:** qué datos obliga a conservar la empresa que emite el comprobante.
5. **Consumo final de RD$250.000 o más:** si obliga a identificar al comprador en la venta (y por tanto a conservar sus datos).
6. **Qué comprobantes exigen la cédula o el RNC del receptor.**
7. **Suplidor extranjero y el 606** (aplazado en GPOS NG, pero la pregunta de fondo sigue) y **si la cédula debe imprimirse íntegra** en el comprobante.

**Por qué importa.** Si conservamos de menos, la empresa puede quedar sin soporte ante una fiscalización (riesgo fiscal). Si conservamos de más, la empresa incumple la supresión que pide la Ley 172-13 (riesgo de protección de datos). La supresión es **irreversible** [V `docs/adr/ADR-092.md:23`], así que un error por defecto no se puede corregir después.

**Qué no se pregunta aquí** (va al abogado): si la persona física comerciante con RNC está protegida (L-03), si la deuda permite aplazar la supresión (F-9) y la lista final de campos anonimizables junto con el contador (L-04) [V hoja:58, 67].

**Plazo útil para B:** antes del 2026-11-09 (fecha de la consulta preliminar al abogado, hoja:67). La fase TT se construye desde el 2026-11-16 [V `docs/adr/ADR-092.md:71`].

---

## Preguntas

Cada pregunta trae el contexto, las opciones cerradas, la opción recomendada por B (si la hay) y el efecto en el sistema si la respuesta resulta ser otra.

### 1. Q-TT5-a · ¿Desde cuándo se cuentan los 10 años de conservación?

**Contexto.**
- ADR-92 (TT-03) y la precisión F-7 dicen «10 años desde el último comprobante que lo usa» [V `docs/adr/ADR-092.md:26`; hoja:23].
- En cambio, para los adjuntos de soporte fiscal ya se firmó que el plazo se cuenta **desde el cierre del ejercicio** del documento (PC-3b-06), con el mes de cierre como parámetro por empresa (3, 6, 9 o 12) y un piso de 10 años que el cliente solo puede subir (PC-3b-05) [V `docs/adr/ADR-067.md:88`]. Para los archivos fiscales, el propietario confirmó 10 años «contados desde el cierre del ejercicio fiscal y suspendidos mientras haya fiscalización o reclamo» (Q-1, 2026-10-10) [V `docs/adr/ADR-111.md:53`].
- El repositorio atribuye los 10 años al Código Tributario, art. 50, lit. h [V citado en `docs/adr/ADR-092.md:24` y `docs/adr/ADR-111.md:53`; el texto no se releyó en esta sesión: a confirmar por el contador]. También anota que la contadora indicó en su momento que «el plazo obligatorio ya no es de 10 años», y que la hoja de la ola 3b cita en contra las consultas de la DGII G. L. 4807 y 4859 de 2025 [V `docs/adr/ADR-067.md:91`; esas consultas no se leyeron: a confirmar por el contador].

**Preguntas cerradas.**
- 1.a ¿Desde qué fecha empieza el plazo? (a) la fecha del comprobante; (b) el cierre del ejercicio fiscal al que pertenece el comprobante; (c) la fecha de presentación de la declaración de ese ejercicio; (d) otra (indicar).
- 1.b ¿El plazo se **suspende** mientras haya una fiscalización, un reclamo o un proceso abierto? Sí / No.
- 1.c ¿El plazo es de **10 años**? Sí / No (indicar el plazo y la norma).
- 1.d ¿Un **saldo pendiente** (cuenta por cobrar o por pagar) mantiene viva la obligación aunque el comprobante sea más antiguo que el plazo? Sí / No.

**Recomendación de B:** 1.a = (b), 1.b = Sí, 1.c = Sí (como piso), 1.d = Sí. Motivo: es lo ya firmado para adjuntos y archivos fiscales, y un solo criterio en todo el sistema evita que el nombre de un titular se anonimice antes de que venza el soporte fiscal que lo cita.

**Efecto si se equivoca.**
- Si contamos desde el comprobante y la ley cuenta desde el cierre o la declaración, el listado «Registros bloqueados con conservación vencida» ofrecería anonimizar el nombre y la cédula **hasta un año antes** de tiempo (más si hay fiscalización). Es irreversible.
- Si contamos desde el cierre y la ley cuenta desde el comprobante, se conservan datos hasta un año de más: incumplimiento menor de la supresión, corregible.
- Cambiar la regla después cuesta poco (la fecha se calcula, no se guarda, hoja:23), siempre que no se haya anonimizado nada antes.

### 2. ¿Qué documentos cuentan como «comprobante que usa» los datos del titular?

**Contexto.** El fin de la conservación se calcula desde el último documento que «usa» al titular [V hoja:23]. El especialista-pos propone la lista de abajo como criterio de operación [V POS-TT:163-175; el criterio es [I]]. Que cotización, pedido, conduce, entrada, ajuste, conteo, transferencia y recibo de cobro **no son comprobantes fiscales** está escrito en NCF-01:83 [V].

**Preguntas cerradas** (marcar Sí o No en cada fila: «¿obliga a conservar el nombre y el documento del titular?»).

| # | Documento | Propuesta de B |
|---|---|---|
| 2.1 | Factura de venta y factura POS con NCF o e-NCF | Sí |
| 2.2 | Nota de crédito, nota de débito y devolución que modifica una factura | Sí |
| 2.3 | Recibo de cobro (no es comprobante fiscal, NCF-01:83, pero es soporte del saldo) | Sí |
| 2.4 | Cheque devuelto | Sí |
| 2.5 | Factura de compra con NCF del suplidor, devolución de compra, notas de CxP | Sí |
| 2.6 | Cheque, transferencia o solicitud de pago al suplidor; caja chica con beneficiario y cédula | Sí |
| 2.7 | Saldo vivo en CxC o CxP, aunque el comprobante sea antiguo | Sí |
| 2.8 | Cotización y pedido | No |
| 2.9 | Conduce | No |
| 2.10 | Solicitud de compra y orden de compra sin factura de compra | No |
| 2.11 | Factura emitida **sin NCF** («No generar comprobante») | Sin propuesta: ¿es soporte contable que obliga a conservar? |

- 2.12 Para los documentos de las filas 2.8 a 2.10 de un titular que pidió la supresión: ¿la empresa puede (a) conservarlos tal cual hasta su archivado normal o (b) debe anonimizar los datos del titular? Recomendación del especialista-pos: (a) para la primera versión [V POS-TT:177]; es también una pregunta para el abogado.

**Efecto si se equivoca.** Si un documento que sí obliga queda fuera de la lista, el sistema calcula un fin de conservación más temprano y ofrece anonimizar antes de tiempo (riesgo fiscal, irreversible). Si se incluye uno que no obliga, se conservan datos de más (riesgo de protección de datos, corregible). Agregar o quitar un tipo de documento del cálculo es un cambio pequeño antes de construir; después, también, porque el cálculo no se guarda.

### 3. ¿Una nota de crédito posterior al bloqueo del titular es válida y obligatoria?

**Contexto.**
- El bloqueo de TT-03 impide usar el registro «en documentos nuevos» [V `docs/adr/ADR-092.md:23`].
- La Ley 32-23, art. 15, num. 3 y 4, dice que las notas de débito y de crédito «solo podrán ser emitidas al mismo adquiriente o usuario para modificar comprobantes fiscales emitidos con anterioridad» [V citado y marcado «Verificado» en NCF-01:68; no se releyó en esta sesión]. Con e-NCF el documento no se anula: se reversa con su nota de crédito [V `CLAUDE.md`, «Dominio»; ADR-108]. En GPOS NG toda devolución es nota de crédito.
- El especialista-pos propone precisar TT-03: «El bloqueo impide documentos nuevos; no impide los documentos que modifican, cobran o pagan comprobantes o saldos ya emitidos al mismo tercero» [V POS-TT:187].

**Preguntas cerradas.**
- 3.a Si el titular bloqueado devuelve mercancía de una factura anterior, ¿la empresa **debe** emitir la nota de crédito a ese mismo titular (y no a otro tercero ni dejar de emitirla)? Sí / No.
- 3.b ¿Vale lo mismo para la nota de débito que modifica una factura anterior, el recibo de cobro, la aplicación de un saldo a favor, el cheque devuelto y el pago de una CxP? Sí / No / Cuáles no.
- 3.c ¿Esa nota posterior **reinicia** el plazo de conservación del titular (porque es un comprobante nuevo que lo cita)? Sí / No.
- 3.d ¿Existe un plazo máximo para emitir una nota de crédito sobre una factura (el repositorio menciona una regla de 30 días del Reglamento 293-11, art. 8, solo de fuente secundaria, NCF-01:320)? Indicar si sigue vigente y si afecta este caso.

**Recomendación de B:** 3.a = Sí, 3.b = Sí, 3.c = Sí (el cálculo ya lo hace solo).

**Efecto si se equivoca.** Si se prohíbe la nota y la ley la exige, la empresa no puede reversar una venta con e-NCF de un titular bloqueado (no hay otra vía: el e-NCF no se anula) y tampoco puede cobrarle la deuda que F-9 exige saldar. Si se permite y la ley no la exige, el único efecto es que el titular aparece en un documento posterior a su bloqueo, siempre ligado a un comprobante anterior.

### 4. B11 (compras a informales) y B13 (gastos menores) con una persona física

**Contexto.**
- En el B11 la empresa es la **emisora** del comprobante a nombre de un suplidor persona física, y le retiene; por eso su copia del nombre y la cédula es soporte de su propio comprobante [I, POS-TT:52, marcado para confirmación del contador].
- En GPOS NG, B11 y B13 se rechazan sin secuencia, solo cuando el usuario pide el comprobante [V NCF-01:339]. La evidencia del B11 y del B13 está entre los adjuntos de soporte fiscal que no van a la papelera [V `docs/adr/ADR-067.md:78`].

**Preguntas cerradas.**
- 4.a En el B11, ¿la empresa está obligada a registrar y conservar el **nombre y la cédula** del suplidor informal? Sí / No. ¿Algún otro dato (dirección, teléfono)? Indicar cuál.
- 4.b En el B13, ¿el comprobante debe identificar a la persona física que recibió el pago? Sí / No. Si sí, ¿con qué dato?
- 4.c ¿Las retenciones (ITBIS, ISR) asociadas a esos comprobantes amplían el plazo o los datos que hay que conservar? Sí / No.

**Recomendación de B:** ninguna (depende del contador). El diseño ya conserva nombre e identificación de todo suplidor bloqueado [V POS-TT:52; `docs/adr/ADR-092.md:23`].

**Efecto si se equivoca.** Si el B11 exige conservar un dato que la supresión anonimiza (por ejemplo, la dirección), el comprobante emitido por la propia empresa quedaría sin soporte del maestro. La copia en el documento emitido no se toca (TT-04), lo que mitiga el riesgo solo si esa copia guarda el dato exigido.

### 5. Consumo final de RD$250.000 o más: ¿hay que identificar al comprador?

**Contexto.**
- El especialista-pos lo marcó como [I] a confirmar [V POS-TT:192]; el cierre de H0 lo «entiende» así, como fuente secundaria [V `docs/decisiones/2026-10-04-cierre-h0.md:524`].
- **Pero ya hay una lectura verificada en el repositorio:** la Norma General 10-18, art. 1 (que reescribe el art. 4 de la Norma General 07-2018), dice que el umbral **no exime del NCF** y que las facturas de consumo desde RD$250.000 se informan **una por una en el 607, con el documento de identidad del comprador**; las menores, en resumen [V NCF-01:65, marcado «Verificado» por quien lo leyó el 2026-10-01; no se releyó en esta sesión].
- Hoy el sistema no exige la identificación por monto: solo por tipo de comprobante (no hay ningún tope de 250.000 en `src/`) [V NCF-01:274].
- El 607 no lleva e-NCF (ADR-108); con e-CF el dato del comprador viajaría en el propio e-CF [I].

**Preguntas cerradas.**
- 5.a ¿Confirma que desde RD$250.000 la factura de consumo debe llevar la cédula o el RNC del comprador? Sí / No.
- 5.b ¿La obligación es **capturar el dato al vender** (y por tanto la venta no se puede completar sin él), o solo **informarlo** después en el 607? (a) capturar al vender; (b) solo informar.
- 5.c ¿El umbral se mide por factura, con o sin ITBIS? (a) total con ITBIS; (b) base sin ITBIS; (c) otro.
- 5.d Con e-CF de consumo (E32), ¿rige el mismo umbral para enviar el comprobante completo con la identificación del comprador? Sí / No / Indicar la regla.

**Recomendación de B:** 5.a = Sí y 5.b = (a), con base en la lectura verificada de la Norma 10-18; 5.c y 5.d sin propuesta.

**Efecto si se equivoca.** Si la ley exige identificar y el sistema no lo pide, la venta queda sin el dato que debe informarse (y la persona queda en el cliente genérico, sin registro propio que conservar o bloquear). Si no lo exige y el sistema lo pide, se recogen cédulas de más (minimización de datos) y se frena la caja en ventas grandes.

### 6. ¿Qué comprobantes exigen la cédula o el RNC del receptor?

**Contexto.** Hoy el sistema exige RNC o cédula al cliente cuyo tipo de comprobante es crédito fiscal (B01/E31), régimen especial (B14/E44) o gubernamental (B15/E45) [V POS-TT:58 y 143, que cita el código]. Exportación (B16) no está en esa lista [I].

**Preguntas cerradas** (Sí / No por fila: «¿el comprobante debe llevar la cédula o el RNC del receptor?»).

| # | Comprobante | Hoy en GPOS NG |
|---|---|---|
| 6.1 | Crédito fiscal B01 / E31 | Exige [V] |
| 6.2 | Consumo B02 / E32 (por debajo del umbral) | No exige [V] |
| 6.3 | Nota de débito B03 / E33 y nota de crédito B04 / E34 | Siguen al comprobante que modifican [I] |
| 6.4 | Compras B11 / E41 | Ver pregunta 4 |
| 6.5 | Gastos menores B13 / E43 | Ver pregunta 4 |
| 6.6 | Régimen especial B14 / E44 | Exige [V] |
| 6.7 | Gubernamental B15 / E45 | Exige [V] |
| 6.8 | Exportación B16 / E46 | No exige [I] |
| 6.9 | Pagos al exterior B17 / E47 | Sin regla [I] |

- 6.10 ¿Una persona física que pide crédito fiscal (B01) puede identificarse con la cédula (11 dígitos), o necesita un RNC de 9 dígitos? El sistema hoy acepta los dos largos y deduce el tipo del largo [V POS-TT:12, 153; que la DGII use la cédula como RNC de la persona física es [I], a confirmar].

**Efecto si se equivoca.** Si un comprobante exige el dato y el sistema no lo pide, se emiten comprobantes incompletos. En la supresión, el dato del receptor de cualquiera de estos comprobantes es el que se bloquea y no se anonimiza; un error en esta lista cambia qué se conserva.

### 7. Suplidor extranjero, el 606 y la cédula impresa íntegra

**Contexto.**
- Los reportes 606, 607 y 608 están **aplazados** en GPOS NG: los produce el ERP del cliente [V `docs/adr/ADR-111.md:32-39`]. La pregunta de fondo sigue: qué datos de un suplidor extranjero persona física hay que conservar.
- En el sistema, un número que no mide 9 ni 11 dígitos se registra como tipo `P` (pasaporte u otro), incluidos los identificadores extranjeros [V POS-TT:12-14, 145].
- Los reportes ya enmascaran la cédula a quien no tiene el privilegio «Ver datos personales» [V `docs/arquitectura/2026-10-19-ola5-tramo4-plan-de-trabajo.md:228`], y la lista de empleados la muestra enmascarada [V `docs/datos/2026-10-03-empleados-vendedores.md:277`]. El comprobante impreso hoy no se enmascara [I].

**Preguntas cerradas.**
- 7.a Para un suplidor extranjero persona física sin RNC ni cédula dominicana, ¿qué identificador debe conservar la empresa como soporte del gasto (pasaporte, identificador fiscal extranjero, ninguno)? Indicar.
- 7.b ¿Ese pago exige un comprobante propio (por ejemplo, el de pagos al exterior) y una retención que amplíe los datos que hay que conservar? Sí / No / Indicar cuál [I: la existencia y el uso de ese comprobante no se verificaron en esta sesión].
- 7.c Si el identificador del suplidor se **rectifica** después de haberse reportado en un 606, ¿la empresa debe presentar una rectificativa del 606, o basta con que el comprobante ya informado conserve el dato original? (a) rectificativa; (b) se conserva el original; (c) otro.
- 7.d ¿La cédula del **receptor** debe imprimirse **íntegra** en el comprobante fiscal (factura, nota, B11)? Sí / No.
- 7.e ¿Y la cédula de una persona que **no es el receptor** (por ejemplo, el beneficiario de un pago de caja chica o el empleado que entrega una mercancía), debe salir íntegra en algún documento fiscal? Sí / No.

**Recomendación de B:** 7.c = (b), porque los documentos emitidos no se modifican (TT-04) [V `docs/adr/ADR-092.md:28`] y el especialista-pos ya advierte que rectificar el documento de un suplidor desalinea el 606 reportado [V POS-TT:53]. 7.d y 7.e: sin propuesta; si la respuesta de 7.e es No, B propondría enmascarar la cédula de terceros en las impresiones que no son comprobantes.

**Efecto si se equivoca.** 7.a y 7.b: si hace falta un identificador que la supresión anonimiza, el gasto queda sin soporte. 7.c: si la norma exige rectificativa, la rectificación del titular tendría un efecto fiscal que la pantalla hoy no avisa. 7.d y 7.e: si se enmascara una cédula que debía salir íntegra, el comprobante queda incompleto; si se imprime íntegra una que no hacía falta, se expone un dato personal en cada copia impresa.

---

## Nota para el propietario (no se envía al contador)

- **Incoherencia interna que la pregunta 1 resuelve:** ADR-92 (TT-03) y la hoja (F-7) dicen «10 años desde el último comprobante»; ADR-67 (PC-3b-06) y ADR-111 (Q-1) dicen «desde el cierre del ejercicio, suspendido por fiscalización». Si el contador confirma el cierre del ejercicio, hace falta una precisión de ADR-92 que lo alinee (la prepara el Arquitecto Maestro).
- **El umbral de RD$250.000 (pregunta 5) ya tiene una lectura verificada** en NCF-01:65; la pregunta es para confirmarla y precisar el momento de la captura, no para empezar de cero.
- La pregunta 2.11 (factura sin NCF, «No generar comprobante») no tiene propuesta a propósito: GPOS NG no debe fomentar esa opción, y su tratamiento lo decide el contador.

### Cierre
- Estado: Completado
- Artefactos: C:\Users\lfmen\AppData\Local\Temp\claude\C--Users-lfmen-source-repos-Solucion-GPOS-NG-GPOS-NG\a8083c99-fe36-432e-bde4-46ec95e0ccbd\scratchpad\consulta-contador-borrador.md
- Supuestos: lo marcado [I]; las normas citadas como [V] lo son por estar escritas en documentos del repositorio, no por haberse releído su texto oficial en esta sesión
- Decisiones candidatas a ADR: precisión de ADR-92 (TT-03 y F-7) para alinear el cómputo con PC-3b-06 y ADR-111 Q-1, según la respuesta 1; precisión de TT-03 sobre notas y cobros sobre registros bloqueados, según la respuesta 3
- Entregas a otros agentes: arquitecto-maestro → precisiones anteriores cuando responda el contador; especialista-pos → identificación del comprador desde RD$250.000 si se confirma la pregunta 5
- Próximo paso recomendado: el propietario revisa, ajusta y envía el borrador a su contador antes del 2026-11-09
