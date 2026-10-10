# Respuestas contables y fiscales a los puntos «confirma el contador» (2026-10-10)

**Autor:** especialista contable y fiscal (equipo B), análisis de solo lectura.
**Alcance:** seis puntos abiertos de ADR-11 (precisión del 2026-10-10, H-2 y P-1 a P-9), ADR-53 (cl. 9, H-11, PC-9), ADR-100/102 (UX-TI-03, clase 8) y ADR-111 (cl. 7, P-A2).
**Marcas:** **[N]** norma verificada en fuente oficial o en una consulta de la DGII · **[S]** fuente secundaria, sin texto oficial leído · **[I]** inferido por este especialista · **[F]** decisión firmada del proyecto.
**Advertencia general:** no soy contador público autorizado (Ley 633-16). Las respuestas son criterio técnico para diseñar el sistema. Las que comprometen la declaración del cliente llevan la marca **«Confirmar con CPA»**.

**Hecho de contexto que cambia varias respuestas.** Según una fuente secundaria [S] (beancount.io, 2026-09-28, que cita la Ley 32-23, el Reglamento 587-24 y el Aviso DGII 14-25), la emisión **exclusiva** de e-CF rige desde el **1-nov-2026** para los grandes locales y los medianos, y desde el **15-nov-2026** para los micro, los pequeños y los no clasificados (prórroga de mayo de 2026, «la última»). Si se confirma, **todo cliente implantado después del corte de mediados de diciembre de 2026 emite solo e-CF**, y la serie B queda únicamente para la contingencia declarada. Con eso los puntos 2 y 3 pesan menos para los NCF de papel y más para los e-NCF. **Hay que verificarlo en un aviso oficial de la DGII (pregunta Q-0).**

---

## 1. Retención de 10 años de la evidencia de las exportaciones, la bitácora y los registros fiscales

**Pregunta.** ¿Es correcto el plazo de 10 años (art. 50 del Código Tributario u otro) para `audit.Exportacion` (ADR-111, cl. 7, P-A2) y los registros fiscales? ¿Desde qué fecha se cuenta?

**Respuesta.**
- **Sí, 10 años es el mínimo correcto** para todo registro con contenido fiscal o que respalda una declaración: comprobantes, `fiscal.Comprobante` (incluido el rol H), archivos 606/607/608, la bitácora de eventos fiscales (anulaciones, «No generar comprobante», saltos de NCF, desbloqueos tras una restauración, zona incierta) y la evidencia de las exportaciones de reportes con efecto fiscal o contable.
- **Cómputo recomendado [I]:** 10 años desde el **cierre del ejercicio fiscal** al que pertenece el hecho. Para una exportación: `max(fin del ejercicio del período reportado, fin del ejercicio de la fecha de exportación) + 10 años`. Si el período tuvo una rectificativa, una fiscalización o un reclamo, se aplica una **retención por litigio** mientras siga abierto. La ley no fija el punto de partida, así que se toma la lectura más conservadora, la misma que PC-3b-06 / AF-10 de la ola 3b.
- **La bitácora de seguridad no fiscal** (inicios de sesión, segundo factor: `BitacoraSeguridad` de ADR-81, 2 años) **no** necesita 10 años. Hay que **clasificar** cada evento: el evento fiscal o de control contable va a la retención de 10 años, y el de seguridad pura, a la de 2 años.

**Fundamento.**
- **[N vía consulta DGII] Código Tributario (Ley 11-92), art. 50, literal h:** obliga a conservar en forma ordenada, por **10 años**, los libros, los registros, los antecedentes, los comprobantes y cualquier documento físico o electrónico de las operaciones. Lo confirman la DGII, Consulta 9-2022 (almacenamiento digital de libros), y la G. L. 4807 (05/09/2025), citada en `docs/contabilidad/2026-10-07-ola3b-reglas-contables.md` §9.1 (rama `feature/modelo-ng`).
- **[N vía consulta DGII] Decreto 254-06, arts. 7 y 8:** requisitos para que la conservación electrónica sea válida (integridad, legibilidad, reproducción). La Consulta 9-2022 los cita.
- **[N vía consulta DGII] Consulta 8 (conservación) y G. L. 4807:** los documentos de **períodos no prescritos** se conservan además **en físico**. Afecta al cliente, no al software, pero la guía de implantación debe decirlo.
- **[N] G. L. 4859 (03/09/2025):** el emisor de e-CF debe conservarlos y presentarlos (arts. 7 y 50 del Código).
- **[S] Código de Comercio, art. 11:** 10 años para los libros y la correspondencia.
- **[S] Código Tributario, art. 21:** prescripción general de 3 años, con interrupciones y suspensiones; por eso 10 años es un piso holgado.

**Riesgo.**
- Baja si se cumple el plazo, porque en la entrega 1 no hay purga. Pasa a Alta si el archivado por períodos permite bajar el plazo por configuración.
- La contadora del propietario dijo el 2026-10-05 que «ya no es de 10 años» y después «mantener 10 por omisión, variable por empresa» (MD-61). Eso contradice el art. 50 h según la propia DGII en 2022 y 2025.

**Recomendación.**
1. Ratificar P-A2 con **10 años como piso que solo sube** (ni el SUPER lo baja), con cómputo desde el cierre del ejercicio y retención por litigio.
2. Agregar a `audit.Exportacion` el **período fiscal reportado** (si aplica) para poder calcular el vencimiento sin depender de los filtros en texto.
3. Clasificar los eventos de la bitácora: fiscal o contable (10 años) frente a seguridad (2 años).

**¿Confirmar con CPA?** Sí, solo para cerrar la contradicción con la nota de la contadora. La norma es clara.

---

## 2. NCF saltados con «Saltar los NCF del sistema anterior» (H-2, P-3)

**Pregunta.** Cuando una secuencia registrada en GPOS se solapa con NCF ya usados por el sistema anterior y se adelanta `Siguiente` hasta el mayor histórico más uno, ¿esos números van al 608?

**Respuesta.** Hay que separar tres grupos dentro del tramo saltado:

| Grupo | Qué son | ¿608 en GPOS? |
|---|---|---|
| **a. Usados por el sistema anterior** (importados como rol H) | Ventas reales del mismo contribuyente, ya informadas en su 607 | **No, nunca.** Informarlos como anulados declararía como nulas facturas válidas: el cliente perdería el crédito fiscal y la empresa parecería subdeclarar ingresos en el cruce con el 606 de sus clientes |
| **b. Anulados por el sistema anterior** | Ya se informaron en el 608 de su mes | **No.** Duplicaría el informe |
| **c. Huecos sin evidencia** (dentro del tramo, sin H y sin constar como anulados) | Números de la autorización del contribuyente que nadie usó o cuyo uso se desconoce | **No automáticamente.** Primero se investigan contra los 607 y 608 presentados por el sistema anterior (Oficina Virtual). Si se confirma que no se usaron, el contador decide entre dejarlos vencer (NG 06-2018, art. 9) o informarlos en el 608 con el tipo 08, «Errores en secuencias de NCF», en el mes del salto |

El NCF es de **la empresa (el RNC)**, no del sistema: el cambio de software no cambia quién lo emitió. Por eso la pregunta correcta no es si «esta empresa con este sistema» los emitió, sino si ya se informaron.

**Fundamento.**
- **[S/N] Norma General 07-2018, arts. 5 y 8 (608):** se informan los NCF **anulados** con su motivo, a más tardar el día 15 del mes siguiente. Hay diez tipos de anulación, entre ellos el 08 «Errores en secuencias de NCF» (siemprealdia.co, que cita la norma; la página oficial de la DGII sobre el 608 lo confirma en lo general).
- **[N vía avisos DGII] NG 06-2018, art. 9:** las secuencias no usadas vencen solas (por ejemplo, el Aviso 29-25). No encontré ninguna norma que obligue a informar en el 608 un número que simplemente no se usó [I].
- Para los e-NCF del grupo c, el equivalente es el **ANECF** (Formato Anulación de e-NCF v1.0 de la DGII): procede si el e-NCF no se envió a la DGII ni al receptor, o si no se usó. Si se envió, ya no cabe el ANECF: se reversa con una E34.

**Riesgo.**
- **Crítico** si alguna vista o automatismo manda al 608 el tramo saltado entero. El diseño actual de `rpt.Formato608` excluye el rol H (bien) y lee `fiscal.NcfZonaIncierta`; el salto **no** debe escribir en esa tabla.
- **Medio** si los huecos del grupo c quedan sin documentar: en una fiscalización aparecen como faltantes de secuencia sin explicación.

**Recomendación.**
1. «Saltar» guarda en la bitácora: secuencia, desde y hasta saltados, mayor H, conteo de H, **lista de huecos (grupo c)**, motivo, usuario y huella de la lista.
2. Nuevo reporte «Conciliación de secuencia en la implantación»: por prefijo, rango autorizado, H importados, huecos y estado (sin revisar, usado por el sistema anterior, anulado por el sistema anterior, informado en el 608 por GPOS, dejar vencer). El estado lo marca el contador, con motivo.
3. Evidencia que se adjunta como soporte fiscal (ADR-67): copias de los 607 y 608 del sistema anterior de los meses afectados, o la constancia de la Oficina Virtual, y el reporte de huecos firmado por el contador.
4. **Ningún hueco va al 608 sin la marca expresa del contador.** El 608 se aplaza en GPOS ([F] 2026-10-08), así que, si se informa, lo hace el ERP; GPOS solo entrega la lista.
5. Si se confirma Q-0, el caso B se limita a la contingencia; el salto de e-NCF usa la evidencia del proveedor (como P-5 de H-11).

**¿Confirmar con CPA?** **Sí**, sobre el grupo c (608 con tipo 08 o dejar vencer). Los grupos a y b son claros: no van al 608.

---

## 3. Devolución de una factura histórica B en una empresa que ya emite e-CF: ¿B04 o E34?

**Pregunta.** Riesgo RF-5 del arquitecto de datos de A: el diseño elige el tipo de la nota de crédito por el prefijo del origen (`ComprobanteOrigen.Tipo`), así que una histórica B produce B04.

**Respuesta.** **Debe ser E34**, con la referencia al NCF B original: `NCFModificado` = el B01/B02 de 11 posiciones, más `FechaNCFModificado` y el código de modificación. **La B04 solo procede en una contingencia declarada.** El tipo de la nota lo decide el **modo de emisión de la empresa en la fecha de la nota**, no el prefijo del origen. La regla inversa sí está prohibida: una nota B no puede modificar un e-CF.

**Fundamento.**
- **[S oficial, foro de ayuda de la DGII]**, respuesta del moderador oficial (consulta del 14-ene-2026, «Emisión de nota de crédito electrónica a NCF B01»): las notas electrónicas **pueden corregir o modificar comprobantes tradicionales (serie B)**, y los e-CF **no** pueden modificarse con notas de la serie B. Remite al artículo CA5122. Es un canal oficial, pero no es una norma general: hay que verificar CA5122 o el Informe Técnico e-CF.
- **[N] Ley 32-23 y Reglamento 587-24 [S para las fechas]:** después de la fecha de exclusividad, emitir B fuera de la contingencia es una infracción y el comprobante no tiene valor fiscal [S].
- **[I] Efecto en el ITBIS:** el formato e-CF de la E34 trae el **indicador de nota de crédito** (emitida dentro o fuera de los 30 días de la factura). Según el Reglamento del ITBIS (Decreto 293-11) [S, no verificado], una nota emitida **después de 30 días** no reduce el ITBIS. Casi toda devolución de una histórica pasará de 30 días: el sistema debe calcular el indicador desde la fecha del H y el ERP debe leerlo.
- [F] ADR-108: un e-NCF no se anula. No aplica aquí: el origen es B.

**Riesgo.**
- **Alto** si queda la regla por prefijo: B04 emitidas sin valor fiscal, y el cliente que pide la nota no puede soportar la reducción de su crédito.
- **Medio:** si el conector de e-CF (IQ o Polaris) no acepta un `NCFModificado` de 11 posiciones, falla la emisión.

**Recomendación.**
1. Cambiar la regla de D-06 y de `ComprobanteOrigen.Tipo`: si la empresa tiene e-CF activo, la nota de crédito es E34 y la de débito E33, sea cual sea la serie del origen. B04 o B03 solo con la empresa sin e-CF o en contingencia.
2. Agregar a la prueba D-06 el caso «histórica B en una empresa con e-CF → E34 con `NCFModificado` B». Probarlo en la certificación del proveedor (IQ mock, Polaris).
3. Calcular y enviar el indicador de 30 días en el campo canónico (ADR-108: el núcleo decide por campos canónicos).
4. Entregas: especialista POS y arquitecto de integraciones (contrato canónico de la nota con origen B).

**¿Confirmar con CPA?** Conviene que confirme la regla de los 30 días del ITBIS. La regla E34 → B la da la propia DGII.

---

## 4. Zona incierta tras restaurar una base (H-11, ADR-53 cl. 9, PC-9)

**Pregunta.** ¿Cómo trata el contador los NCF que pudieron emitirse después del respaldo y no constan (reconstrucción, 608, ANECF) y en qué plazo?

**Respuesta.** La zona incierta **no es un problema de numeración: son ventas probables no registradas.** Por defecto se presumen **emitidas** hasta que se pruebe lo contrario. Anularlas en el 608 o con un ANECF es la última opción, nunca la primera.

| Serie | Fuente de la verdad | Si consta que se emitió | Si consta que no se emitió |
|---|---|---|---|
| **e-NCF (E31, E32, …)** | **El proveedor de e-CF** ([F] P-5) y la consulta de la DGII | **Reconstruir** el documento en GPOS (venta, ITBIS, CxC o cobro, salida de inventario) con la fecha original y una marca de reconstrucción. No va al 607 ([F] R-8): la DGII ya lo tiene | **ANECF** (no se envió a la DGII ni al receptor) |
| **B de contingencia o de papel** | Copia impresa, comprobante en poder del cliente, cierre Z, cobros con tarjeta o banco, diario electrónico cuando exista (H-14) | **Reconstruir** y que el ERP lo incluya en el 607 del mes de la fecha original | 608 con tipo 08 (o 03/02 si hay evidencia física de un comprobante dañado), en el mes en que se resuelve |
| **Sin evidencia ni en un sentido ni en el otro** | — | — | El contador decide. Recomendado: no informarlo en el 608 mientras se investiga y documentar la diligencia. Informar como anulado un NCF que un cliente usó como crédito fiscal es peor que dejar un hueco explicado |

**Plazos [N para el 608/607; I para el resto].**
- Resolver **antes del día 15 del mes siguiente al de la emisión** (NG 07-2018, art. 8: 607 y 608), y en la práctica antes del **IT-1** del mismo mes (día 20 [S]), porque las ventas reconstruidas cambian el ITBIS por pagar.
- Si se descubre después de presentar: **declaraciones rectificativas** del 607 y del IT-1 (y del 608 si se informó mal), con recargos si hay más impuesto [I]. El archivo fiscal inmutable de ADR-111 guarda la versión nueva con motivo.
- El ANECF no tiene un plazo propio que yo haya encontrado. Recomiendo emitirlo en el mismo ciclo, antes del día 15 [I].

**Riesgo.**
- **Alto:** ingresos omitidos, existencias sobrestimadas (las ventas de la zona no descontaron inventario) y caja descuadrada.
- **Alto** si se anula en el 608 un B que el cliente declaró en su 606: aparece una discrepancia en el cruce de la DGII.
- **Medio** (riesgo ya aceptado en H-11, punto 9): último NCF declarado por debajo del real.

**Recomendación.**
1. La guía al contador de P-6 debe contener: la presunción de emisión, la tabla anterior, la lista de evidencias aceptadas por serie y los plazos.
2. `fiscal.NcfZonaIncierta` necesita, además de A (anulado) y R (reconstruido), un estado **«En investigación»** (no entra al 608) y el vínculo al documento reconstruido. Hoy la vista `rpt.Formato608` toma `Estado = 'A'`. Está bien, siempre que nada llegue a A sin la marca del contador y su motivo.
3. El documento reconstruido entra en el kárdex con la fecha de hoy si el período de inventario está cerrado (regla de C-03: nunca se reabre), y con la fecha original para lo fiscal. Lo decide el arquitecto de datos; yo recomiendo dos fechas, la fiscal (original) y la de registro.
4. Avisar en la pantalla del SUPER al liberar el candado: «Hay N NCF en zona incierta: resolver antes del 15 de <mes>».

**¿Confirmar con CPA?** **Sí**, sobre el tratamiento «sin evidencia» y el uso de rectificativas.

---

## 5. Transferencias entre sucursales: sobrante en la recepción (UX-TI-03) y diferencia de transferencia (clase 8)

**Pregunta.** ¿Cuál es el tratamiento contable del sobrante anotado en el tramo 1 y de la clase 8 del tramo 2? ¿Hace falta un documento fiscal?

**Respuesta fiscal.** **Ningún documento fiscal**: ni NCF ni e-CF, ni ITBIS, ni 606/607/608. El traslado entre establecimientos del mismo contribuyente no es una transferencia de dominio. Basta el conduce interno con su huella ([F] reglas contables de la ola 3b, «Fiscal del traslado»; [S] Código Tributario, art. 335, hecho generador del ITBIS; [I] no existe en RD una guía de remisión fiscal obligatoria para el traslado interno ni un tipo e-CF de traslado). Excepciones:
- El retiro para **uso propio o consumo interno** sí causa ITBIS (T-08; G. L. 3937, 24/04/2024, verificada por el proyecto). No debe disfrazarse de transferencia.
- La **destrucción** de mercancía dañada o vencida que se quiera deducir del ISR exige el procedimiento de la DGII (notificación e inspección previas) [I/S, verificar el procedimiento vigente].

**Respuesta contable (GPOS es auxiliar, ADR-73: entrega datos canónicos y el ERP hace el asiento).**

| Hecho | Medición en GPOS | Asiento que recomiendo al ERP | Soporte |
|---|---|---|---|
| Despacho / recepción (clase 6) | Costo del despacho; neutro para el promedio | Con inventario por sucursal: Inventario en tránsito / Inventario A, y luego Inventario B / Inventario en tránsito. Con una sola cuenta: ninguno | `TI` y conduce |
| **Sobrante del tramo 1 (UX-TI-03, solo anotado)** | **Ninguna en el kárdex** (se recibe hasta lo pendiente) | **Ninguno todavía.** Es una diferencia de inventario **sin registrar**: existencia física de B > libros | Anotación en la recepción |
| Sobrante S1 (tramo 2, clase 8) | Promedio vigente en la fecha de S1 | Inventario B / Otros ingresos: ganancia (sobrante) de inventario, o menor costo de ventas (lo decide el ERP) | Diferencia con el supervisor de B |
| S2: A confirma que mandó de más (clase 8) | Mismo costo que S1 (T-12) | Reversa de la ganancia / Inventario A: neto 0 | Confirmación del supervisor de A |
| Pérdida en tránsito (par clase 6 + clase 8) | Promedio vigente en la fecha en que B la registra ([F] ADR-102) | Gasto: pérdida de inventario (o costo de ventas) / Inventario en tránsito, en el **período en que se registra** (NIIF para PYMES 13.20, análoga a NIC 2.34 [I, de memoria]) | Diferencia, motivo, autorizante y evidencia (acta; denuncia si hubo robo) |
| No apto (entra como no vendible) | Costo del despacho | Inventario no vendible / Tránsito; al cierre, deterioro (NIIF para PYMES 27) | Diferencia con motivo |

**Fiscal de la pérdida [I, confirmar con CPA]:**
- **ISR:** la pérdida es deducible si es real y está documentada (Código Tributario, art. 287 [S]: pérdidas por caso fortuito o hurto no cubiertas por seguro). La imputación interna entre sucursales no cambia la deducción.
- **ITBIS:** la pérdida no genera débito. Si el ITBIS adelantado de lo perdido debe reversarse es una pregunta abierta (C-17 de la ola 3b sigue sin respuesta).
- El **sobrante** no explicado es un ingreso gravado de ISR.

**Riesgo.**
- **Medio (sobrante del tramo 1):** mientras quede solo anotado, B tiene mercancía fuera de los libros. Un conteo de B la da como sobrante sin explicar, se puede vender sin existencia y, si la política permite negativos, distorsiona el costo. Es además un vector de fraude: la mercancía no registrada se sustrae sin rastro.
- **Bajo (tramo 2):** el diseño firmado cuadra kárdex = foto (PB-3b-01 a 05).

**Recomendación.**
1. Tramo 1: el sobrante anotado debe quedar **visible y con dueño**: un listado «Sobrantes anotados sin resolver» en la recepción y en la previa del cierre de período (aviso, sin bloquear: C-01). La mercancía se separa físicamente.
2. Plazo de resolución: hasta que llegue el tramo 2 (S1), se resuelve con los documentos que ya existen en el núcleo, **ajuste de entrada en B con motivo «Sobrante de transferencia TI-n»**, y, si A reconoce que mandó de más, ajuste de salida en A con el mismo costo. En todo caso antes del cierre de inventario del mes. Cuando entre el tramo 2, la vía normal pasa a ser S1/S2.
3. Que el conector distinga en los datos canónicos la ganancia (S1), la pérdida (clase 8) y el traslado (clase 6), con el código de sucursal y la dimensión «En tránsito» (X-03), para que el ERP asiente sin interpretar.
4. Mantener la regla: el motivo de pérdida por robo o hurto exige un número de referencia (denuncia) como evidencia de deducibilidad.

**¿Confirmar con CPA?** **Sí**, en la deducibilidad de las pérdidas y mermas y en el ITBIS adelantado de lo perdido (C-17). El tratamiento contable es estándar.

---

## 6. Fecha de implantación como única fecha de corte (H-2, P-5)

**Pregunta.** ¿Hay algún riesgo contable o fiscal en usar una sola fecha para las facturas históricas, las CxP pendientes, los saldos iniciales y las existencias?

**Respuesta.** **Una sola fecha es lo correcto y lo recomendado**: el balance de apertura del auxiliar debe ser **una sola foto, a la misma fecha**, para conciliar con el mayor del ERP (inventario, CxC, CxP y bancos en el mismo corte). Los riesgos no están en que sea una sola, sino en **cuál** se elige y en **cómo se hace el corte**:

| # | Riesgo | Severidad | Mitigación |
|---|---|---|---|
| R6-1 | Fecha a mitad de mes: el 607, el 608 y el IT-1 de ese mes mezclan el sistema anterior y GPOS (dos fuentes que unir) | Media | Recomendar el **primer día de un mes** (el DEMO ya usa 01/10/2026). Si no se puede, la guía exige combinar las dos fuentes en las declaraciones de ese mes |
| R6-2 | Semántica ambigua: «al día X» puede significar al inicio o al cierre del día | Media | Definirla y mostrarla en pantalla: los saldos son **al cierre del día anterior** a la fecha de implantación (00:00 del día X). Las históricas tienen fecha < X ([F] 51424); la primera operación propia, fecha ≥ X |
| R6-3 | El conteo físico no ocurre exactamente en el corte | Media | Procedimiento de corte documental: último número de factura, de recepción y de conduce del sistema anterior anotados en el acta de conteo. Si el conteo se hace después, se retrotrae con los movimientos intermedios (documentado) |
| R6-4 | Partidas en tránsito al corte: mercancía recibida sin factura del suplidor, factura recibida sin mercancía, transferencias en tránsito del sistema anterior | Media | Plantillas o campos para «compras recibidas no facturadas» y «mercancía en tránsito al corte», o al menos una lista firmada por el contador |
| R6-5 | Saldos que no son facturas: anticipos de clientes, saldos a favor y notas de crédito sin aplicar (ADR-70), cheques en circulación, depósitos en tránsito | Media | Incluirlos en la importación con la misma fecha. Los bancos, con la conciliación al corte (partidas pendientes, no solo el saldo) |
| R6-6 | Valuación inicial distinta de la del ERP (costo del sistema anterior frente al mayor) | Media | Exigir el cuadre `Σ existencias × costo = saldo de inventario en el mayor al corte` antes de liberar la implantación. Una diferencia se ajusta en el ERP, no en GPOS |
| R6-7 | Implantación que cruza la fecha de exclusividad del e-CF (Q-0) | Baja | Las históricas pueden ser B y las propias, E. Ver el punto 3 (nota E34 sobre un origen B) |
| R6-8 | Cambiar la fecha después (solo el SUPER con motivo, [F] P-2) desplaza el corte de la CxP y de las existencias ya importadas | Baja | Al cambiarla, revalidar todas las importaciones contra la fecha nueva o bloquear el cambio si ya hay importaciones de saldos (51423 ya la ata a la primera factura propia) |

**Fundamento.** NIIF para PYMES, secc. 2 (devengo) y secc. 10 (corrección de errores); principio de corte de las aserciones de auditoría (NIA 315/330/501, inventario) [I, de oficio]. Fiscal: NG 07-2018, art. 8 (formatos mensuales) [S].

**Recomendación.**
1. Mantener P-5 (una sola fecha). Recomendar en la pantalla y en la guía el primer día del mes.
2. Agregar al asistente de implantación un **checklist de corte** (R6-2 a R6-6) y un **reporte de apertura** con los totales por rubro para cuadrar con el mayor del ERP, firmado por el contador y adjuntado como soporte fiscal.

**¿Confirmar con CPA?** No es indispensable. Conviene que el contador del cliente firme el acta de corte en cada implantación.

---

## Preguntas para el contador del propietario

- **Q-0.** Confirmar con un aviso oficial de la DGII las fechas de emisión exclusiva de e-CF (1-nov-2026 para los grandes locales y los medianos; 15-nov-2026 para los micro, los pequeños y los no clasificados) y qué uso queda para la serie B (solo contingencia).
- **Q-1.** Plazo de conservación: ¿confirma 10 años como piso legal (art. 50 h, Consultas DGII 9-2022 y G. L. 4807-2025), contados desde el cierre del ejercicio fiscal? ¿En qué se basó la nota «ya no es de 10 años»?
- **Q-2.** Los huecos sin evidencia dentro de un tramo saltado en la implantación: ¿se informan en el 608 con el tipo 08 o se dejan vencer (NG 06-2018, art. 9)?
- **Q-3.** ¿Confirma que, con e-CF activo, la devolución de una factura B histórica sale como E34 con referencia al B, y que la nota emitida después de 30 días no reduce el ITBIS (Decreto 293-11)?
- **Q-4.** Zona incierta sin evidencia en ningún sentido: ¿investigación sin 608, o 608 con tipo 08? ¿Qué evidencia mínima acepta para reconstruir una venta B de contingencia?
- **Q-5.** Pérdidas y mermas en tránsito: ¿qué soporte exige para la deducción del ISR (acta, denuncia, procedimiento de destrucción ante la DGII)? ¿Se reversa el ITBIS adelantado de lo perdido? (C-17 sigue pendiente.)
- **Q-6.** Sobrante no explicado de una transferencia: ¿lo prefiere como otros ingresos o como menor costo de ventas?
- **Q-7.** ¿Firmaría un acta de corte de implantación estándar (fecha, últimos números del sistema anterior, conteo, CxC, CxP, bancos con partidas pendientes, cuadre con el mayor)?

## Supuestos
- Las fechas de exclusividad del e-CF salen de una fuente secundaria.
- La regla E34 → B sale del foro oficial de la DGII, no de una norma general.
- Los arts. 21, 287 y 335 del Código y el Decreto 293-11 no se leyeron en el texto oficial.
- No encontré un plazo propio para el ANECF.
- NIIF para PYMES 13.20 se cita de memoria.

## Fuentes consultadas
- [DGII, Consulta 9-2022, almacenamiento digital de libros contables](https://dgii.gov.do/legislacion/consultas/Consultas%20Tecnicas%202022/Mayo/Consulta%209-Almacenamiento%20digital%20de%20libros%20contables.pdf)
- [DGII, Consulta 8, conservación de documentos](https://dgii.gov.do/legislacion/consultas/Documents/Octubre/Consulta%208-Conservaci%C3%B3n%20de%20documentos.pdf)
- [Siemprealdía, conservación de documentos](https://siemprealdia.co/republica-dominicana/impuestos/conservacion-de-documentos-para-efectos-fiscales/)
- [Siemprealdía, Formato 608 (NG 07-2018, arts. 5 y 8; tipos de anulación)](https://siemprealdia.co/republica-dominicana/impuestos/formato-608/)
- [DGII, Formato 608](https://dgii.gov.do/cicloContribuyente/facturacion/comprobantesFiscales/Paginas/Formato-608.aspx)
- [DGII, Aviso 29-25 (vencimiento de secuencias, NG 06-2018, art. 9)](https://www.dgii.gov.do/publicacionesOficiales/avisosInformativos/Documents/2025/29-25.pdf)
- [DGII, Formato Anulación de e-NCF v1.0](https://dgii.gov.do/cicloContribuyente/facturacion/comprobantesFiscalesElectronicosE-CF/Documentacin%20sobre%20eCF/Formatos%20XML/Formato%20Anulaci%C3%B3n%20de%20e-NCF%20v1.0.pdf)
- [Foro de ayuda de la DGII: nota de crédito electrónica a un NCF B01](https://ayuda.dgii.gov.do/conversations/discusiones/emision-de-nota-de-credito-electronica-a-ncf-b01/6967ff60c836550ff8799939)
- [Foro de ayuda de la DGII: nota de crédito electrónica a una B01/B02](https://ayuda.dgii.gov.do/conversations/discusiones/nota-de-credito-electronica-para-aplicar-a-factura-normal-b01-o-b02/691c833a63b13c77ecf4f387)
- [Beancount, plazos e-CF de noviembre de 2026 (secundaria)](https://beancount.io/es/blog/2026/09/28/dominican-republic-e-cf-electronic-invoicing-november-2026-deadline-guide)
- Proyecto:
  - `docs/adr/ADR-011.md` (precisiones del 2026-10-10)
  - `docs/adr/ADR-053.md` (cl. 9 y precisiones de H-11)
  - `docs/adr/ADR-100.md` (UX-TI-03)
  - `docs/adr/ADR-102.md`
  - `docs/adr/ADR-111.md` (cl. 7, P-A2)
  - `docs/adr/ADR-031.md` (DA-03)
  - `feature/modelo-ng:docs/contabilidad/2026-10-07-ola3b-reglas-contables.md` (§9.1, E-13a a E-13j)
  - `GPOS-NG-Equipos/traspasos/A/datos-h2-h3-ncf-historico-2026-10-10.md` (líneas 269-284, 448, 701-705, 786-806)
  - `traspasos/B/2026-10-10-plan-ola3b.md`
