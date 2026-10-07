# Especialista-pos: respuestas a la sección 8 de A (conector de e-CF con IQ, ADR-108)

[Blueprint POS, acotado] · **De:** especialista-pos · **Fecha:** 2026-10-07 · **Responde a:** `respuestas-A-conector-iq-2026-10-07.md`, sección 8, «Especialista-pos» (puntos 1 a 4)
**Base firmada:** P-A1 a P-A7, aprobadas como recomendó A (`decisiones-por-registrar-2026-10-07.md:48-54`). La UX aprobada de B (`docs/ux/2026-10-07-ux-ecf-avisos-y-ri.md`, rama `origin/b/conector-iq-diseno`) se respeta. No toqué ningún árbol.
**Estado:** recomendaciones operativas. Lo que dice «Pregunta» lo decide el propietario (C2).

**Fuentes normativas**
- [FAQ-G] DGII, *Preguntas frecuentes acerca de Facturación Electrónica (Generales)*, PDF oficial en dgii.gov.do. En el texto extraído no aparece la fecha; cita el Decreto 587-24. Es una publicación informativa, **sin valor de norma**.
- [FAQ-T] DGII, *Preguntas frecuentes acerca de Facturación Electrónica (Técnicas)*, abril de 2024, también «publicación informativa sin validez legal».
- La norma de fondo es el Decreto 587-24 y el Informe Técnico e-CF v1.0. No los releí aquí: lo que viene de las preguntas frecuentes está marcado como **[FAQ]**.

---

## 1. RI con QR en `EN_PROCESO`, y qué pasa si después se rechaza

### Regla
1. **La RI con QR se imprime y se entrega apenas hay timbre**, o sea, en `EN_PROCESO`, `ACEPTADO` o `CONDICIONADO`. El cajero imprime lo mismo en los tres casos: **sin leyenda** de «en proceso», con el mismo QR y el mismo código de seguridad.
   - Sin timbre (`PENDIENTE`, `ENVIANDO`, `VERIFICANDO`, `INVALIDO`) se aplica EC-17: comprobante provisional sin QR y RI después. Es otra regla, y está pendiente de la firma del propietario.
2. **La venta nunca se revierte por un dictamen fiscal.** El cobro, la gaveta, el inventario, la CxC y el arqueo del turno no cambian si el e-CF termina `RECHAZADO`.
3. **Si un `EN_PROCESO` termina `RECHAZADO` después de entregar la RI:**
   - **El cajero no ve nada en la caja.** El dictamen llega minutos u horas después, a menudo con el turno ya cerrado.
   - La alerta va a la **bandeja fiscal de la oficina** (supervisor y ADMIN), y en «Últimas ventas» y en la consulta de ventas el documento lleva la marca «Rechazado por la DGII: requiere reemisión».
   - **No se emite una nota de crédito.** Un e-CF rechazado «no es válido para fines tributarios» [FAQ-G 1.4.5]: no hay nada que anular, y una E34 que lo referencie no procede.
   - **Se reemite el mismo documento con un e-NCF nuevo** [FAQ-G 1.4.8 y 1.3.7: «realizar un nuevo e-CF y sustituir el entregado»]. Lleva las mismas líneas, montos, pagos y comprador, y **no mueve inventario ni caja**.
   - Lo hace el **supervisor o el ADMIN desde la oficina**, con el privilegio «Reemitir comprobante rechazado». Si la causa es de datos (por ejemplo, un RNC del comprador inválido), primero corrige la instantánea del comprador.
   - **Entrega de la RI nueva:**
     - con un comprador identificado (E31, E32 de RD$250.000 o más, E44, E45), se avisa al cliente y se le envía o se le imprime la RI;
     - con el cliente genérico, la RI nueva queda disponible para reimprimirse si el cliente vuelve. No hay a quién localizar.
4. **Las reimpresiones** por falla de la impresora o por pedido del cliente se permiten en cualquier estado con timbre y llevan «COPIA». Si la impresora falla al cobrar, la venta ya está guardada: el cajero reimprime desde «Últimas ventas» y no se vuelve a cobrar.

### Por qué
- Es el modelo de la DGII con un receptor no electrónico: el emisor envía, recibe el TrackID y **luego** entrega la RI [FAQ-G, «Modelo Emisor Electrónico - Receptor No Electrónico»]. No exige esperar el dictamen. Retener al cliente hasta tener el dictamen hace la cola inviable.
- Según la nota 2 de [FAQ-G 1.4.6], el estado «En Proceso» aplica a la **factura de crédito fiscal y a la de consumo de RD$250.000 o más**. La E32 de menos de RD$250.000, que es la mayoría de las ventas de la caja, va por el resumen. En la práctica, el rechazo después de la RI cae casi siempre sobre **compradores identificados**, y se les puede localizar.
- La guardia L-1 y la de los datos del comprador atrapan las causas de rechazo que dependen de GPOS NG. Las que quedan son externas: RNC suspendido, certificado vencido, delegación. Son raras, pero suelen afectar a **muchos documentos a la vez**. Por eso la bandeja debe permitir reemitir por lote.

### Hallazgo para A (severidad **Alta**)
La reemisión con un e-NCF nuevo **no cabe** en el modelo actual:
- A-01 sube `Generacion` **solo** si nada llegó al proveedor;
- `fiscal.Comprobante` tiene la PK `(DocumentoId, Rol)`.

Hace falta una forma de dar un segundo e-NCF al mismo documento después de un `RECHAZADO`, sin documento nuevo y sin E34. Además, A-03 dice que «un rechazo de la DGII consume el e-NCF», y [FAQ-G 1.2.27 y 1.4.9] **admite reutilizarlo** en ciertos casos: RNC suspendido, error de confección, certificado inválido y emisor no delegado.

### Preguntas al propietario
- **POS-1.** ¿Siempre se reemite con un e-NCF nuevo, aunque la DGII permita reutilizar el del rechazo en algunos casos? **Recomiendo: siempre nuevo en v1.** Es una sola regla y no exige clasificar la causa del rechazo. El especialista-contable debe confirmar si el e-NCF rechazado que no se reutiliza necesita una ANECF.
- **POS-2.** ¿Debe la reemisión llevar la fecha del documento original o la del día? **Recomiendo** que lo responda el especialista-contable. Por la caja da igual.

---

## 2. «Cambiar tipo de comprobante»: dónde vive, quién lo autoriza y cómo se ve la refacturación (P-A2)

### Regla
1. **Vive en la oficina**, en Ventas › Consulta de ventas › acción «Cambiar tipo de comprobante». **No está en Facturación Ágil.** En la caja, si el cliente lo pide después de pagar, se le envía al supervisor o a servicio al cliente.
2. **Lo autoriza un privilegio propio**, «Cambiar tipo de comprobante», del grupo Especiales.
   - Por omisión lo tienen el supervisor y el ADMIN. **El cajero no lo tiene.**
   - Exige un motivo de catálogo: «El cliente pidió crédito fiscal», «Tipo equivocado» o «Datos del comprador errados».
   - Deja una línea en `_LOG` (patrón RG-04), además del aviso de los 30 días de la UX 3 cuando corresponde.
3. **El mismo flujo corrige los datos del comprador sin cambiar el tipo** (por ejemplo, un RNC errado en una E31). El mecanismo fiscal es el mismo: E34 `ANU` más un documento nuevo.
4. **Precondiciones**, todas verificadas por el servidor:
   - el original está `ACEPTADO` o `CONDICIONADO`. Si está `EN_PROCESO`, se espera. Si está `RECHAZADO`, se usa la reemisión del punto 1;
   - el original no tiene devoluciones ni notas previas (v1);
   - no hay una contingencia abierta, y el original no es un B pendiente de reemplazo;
   - el nuevo tipo exige sus datos: en la E31, un RNC o una cédula con forma válida. La consulta al padrón es opcional, como en la UX 1.5.
5. **Atomicidad:** la E34 `ANU` y el documento nuevo se guardan **en la misma transacción**, con sus dos e-NCF. Si algo falla, no se guarda ninguno. La E34 se despacha con **prioridad** sobre el documento nuevo.
6. **Cómo se ve la refacturación:**
   - **Documento nuevo:** las mismas líneas, cantidades, precios y descuentos, con la fecha del día. En la cabecera lleva la marca «Refacturación de VT-000123 (E32… → E31…). Sin movimiento de inventario».
   - **Original:** lleva «Comprobante sustituido por E34… · Refacturado en VT-000456», con enlaces en las dos direcciones.
   - **Kárdex:** sin movimientos de la E34 ni del documento nuevo. El costo de venta queda en el original, así que los márgenes cuentan la venta una sola vez.
   - **Pago del documento nuevo:** se aplica la E34 (nota `P` consumida, ADR-70), con la forma de pago «Nota de crédito». **No entra dinero ni sale de la gaveta**, y no toca el turno de ningún cajero.
   - **Ventas:** original (+), E34 (−) y refacturación (+) dan la venta neta una sola vez. La E34 y la refacturación salen con el usuario de la oficina, no en el turno del cajero.
   - **Impresión:** la RI del documento nuevo es para el cliente. La RI de la E34 se imprime para el archivo y, si el comprador estaba identificado, también se le entrega.
7. **Sin conexión:** el flujo necesita la API de la empresa, porque lo hace la oficina. Si la API no responde, no se ofrece.

### Por qué
- La operación toma de 1 a 3 minutos: buscar la venta, capturar y verificar el RNC, el aviso, el motivo y dos impresiones. Hecha en la caja, **detiene la cola**, y mezcla una E34 con el turno y el arqueo del cajero.
- En la práctica dominicana, quien pide el crédito fiscal **después** de pagar lo hace casi siempre en servicio al cliente o al día siguiente.
- Pasar un consumo a crédito fiscal con el RNC de un tercero es la vía clásica de **venta de comprobantes**. Por eso necesita un privilegio que no tenga el cajero, un motivo y una bitácora.
- No mover el inventario cumple P-A2 y evita la salida doble de mercancía que señaló A-17.

### Preguntas al propietario
- **POS-3.** ¿Hace falta habilitarlo en la caja con la clave del supervisor? **Recomiendo: no en v1.** Alternativa descartada: botón en «Últimas ventas» con autorización, por la cola y por el arqueo. Se puede agregar después si el piloto lo pide.
- **POS-4.** ¿Se bloquea si el original tiene devoluciones parciales? **Recomiendo: sí en v1.** El caso parcial exige decidir qué líneas se refacturan, y es raro.
- **POS-5.** Si el original era a crédito con saldo pendiente, ¿hereda la refacturación el saldo y el vencimiento originales? **Recomiendo: sí.** El cliente no debe ganar ni perder plazo por un cambio de comprobante.

---

## 3. El cliente de contado de cada caja como comprador genérico, y el nombre escrito (P-A3)

### Regla
1. **El comprador genérico de una venta es el cliente de contado de su caja** (`org.Caja.ClienteContadoId`; verificado en `src/GPOS.Core/Consultas/Caja/ConsultasCaja.cs:19-28`, `GPOS-NG-numeracion`). Se usa **solo** si se cumplen las tres condiciones:
   - el tipo es E32;
   - el total es menor que el umbral (RD$250.000, parámetro de P-A6);
   - la venta **no tiene documento** de identificación.
2. **Con un documento** (RNC, cédula o pasaporte), aunque sea por debajo del umbral, el comprador del e-CF es **lo que se escribió**, con el documento y el nombre. **En la E31 y en la E32 de RD$250.000 o más nunca se usa el genérico** (UX 1.6 ya rechaza el nombre del genérico).
3. **El nombre que escribe el cajero sin documento:**
   - queda en el documento (`Venta.NombreCliente`) y se imprime en la RI con el rótulo **«Atendido a:»**, no «Cliente:» ni «Comprador:»;
   - en el e-CF, `RazonSocialComprador` lleva el nombre del cliente de contado **tomado en la instantánea al emitir** (A-14). Si después se renombra el cliente de contado de la caja, los documentos ya emitidos no cambian.
4. **Configuración de la caja:** el servidor rechaza un cliente de contado que tenga RNC o cédula. El nombre se recomienda genérico («CONSUMIDOR FINAL»). Todas las cajas pueden compartir el mismo cliente; no hace falta uno por caja.
5. **Sin conexión, en la sucursal:** el cliente de contado forma parte de la configuración de la caja que se replica al nodo. Sin ese cliente, la caja no abre jornada; hoy ya es así por `ClienteContadoInhabilitado`.

### Por qué
- El cajero escribe el nombre para atender: llamar al cliente, la entrega o la garantía. Ese nombre no está verificado, y declararlo como comprador lo haría pasar por un dato fiscal que nadie comprobó.
- El QR de la E32 de menos de RD$250.000 **no lleva datos del comprador**: solo el RNC del emisor, el e-NCF, el monto y el código [FAQ-T 16]. El nombre impreso no afecta la verificación del cliente.
- Con «Atendido a:», la RI no da a entender que el nombre impreso es el comprador declarado, que en el XML es otro.
- **Hallazgo para el arquitecto-datos (Media):** A-11.4 propone sacar el nombre del genérico de `Venta.NombreCliente`. Con P-A3, ahí va el nombre escrito. El nombre del genérico va en `fiscal.ComprobanteInstantanea`, junto con la marca de genérico.

### Pregunta al propietario
- **POS-6.** ¿Es «Atendido a:» el rótulo del nombre escrito en la RI? **Recomiendo: sí.** Alternativa descartada: «Cliente:», que hoy usa el ticket (`PlantillasRazor.Rollo.cs:68`) y se confunde con el comprador fiscal.

---

## 4. Efecto de L-1 en el ticket (P-A1 y P-A7)

### Hechos verificados en `GPOS-NG-numeracion` (`feature/modelo-ng`)
- `Calculadora.Calcular` redondea el ITBIS **por línea** y lo suma por tasa (`src/GPOS.Contracts/Documentos/Calculadora.cs:86` y `:95`). La caja, la impresión y la Web la comparten (`Pos.cs:183`, `FabricaModelo.cs:300`).
- **La caja ignora `IncluyeImpuesto`.** El resolvedor la devuelve (`PreciosService.cs:118-131`), pero ningún código de `src` la consume fuera de las listas de precios. Hoy todo precio se trata como **sin ITBIS**, y el impuesto se suma encima.
- **El ticket en rollo** imprime «cantidad × precio sin ITBIS» y, a la derecha, el **neto con ITBIS** de la línea (`FabricaModelo.cs:278-280`: `Total = l.Neto`; `PlantillasRazor.Rollo.cs:86`). Por eso hoy «2 UND x 85,00» muestra 200,60: la cuenta no cuadra a simple vista. Abajo van el subtotal y el ITBIS por tasa (`:96-98`).
- **La factura carta** tiene una columna de ITBIS por línea (`PlantillasRazor.cs:194-195`).

### Centavos frente al cálculo actual
- **Precios con ITBIS incluido** (el caso normal en el comercio dominicano):
  - **el total cobrado es exactamente la suma de los precios de góndola**, sin centavos de diferencia con la góndola;
  - el ITBIS se deriva: base = `round(Σ / 1,18)` e ITBIS = Σ − base;
  - frente a hoy, no hay comparación posible: hoy la caja cobraría el 18 % **encima** del precio de góndola.
- **Precios sin ITBIS:** `round(Σ base × tasa)` frente a `Σ round(base × tasa)`.
  - **Ejemplo:** 3 líneas de 10,03 al 18 %. Hoy 3 × 1,81 = 5,43; con L-1, 30,09 × 0,18 = 5,4162 → **5,42**. El total baja un centavo.
  - **Margen:** como máximo 0,005 por línea y tasa. Lo típico en un ticket de 30 líneas es de ±1 a 2 centavos (desviación ≈ 0,0029·√n; inferido).
- **Conversión de un precio de lista con el otro modo:** se convierte al entrar en la línea y se redondea a 2 decimales una sola vez. **Ejemplo:** con la empresa en modo incluido, un precio de 84,75 sin ITBIS se cobra a 100,01. La caja muestra el precio ya convertido.
- **Devoluciones parciales:** cada nota aplica L-1 a sus propias líneas. Para que el reembolso total nunca pase de lo cobrado, la **última devolución que vacía la factura cierra por diferencia** contra lo que queda del original.
  - Con ITBIS incluido es exacto por construcción.
  - Sin ITBIS puede haber un centavo de diferencia entre notas.
- **Efectivo:** en la calle no circulan centavos. Con L-1 el redondeo por línea deja de importar en la gaveta, pero el vuelto en centavos sigue siendo un tema propio (pregunta POS-9).

### Regla para el ticket y la RI
1. **Cada línea muestra un solo valor, igual a `MontoItem`:**
   - con ITBIS incluido, «cantidad × precio con ITBIS = valor»;
   - sin ITBIS, «cantidad × precio sin ITBIS = valor sin ITBIS».
   La cuenta de la línea cuadra a simple vista en los dos modos. Hoy no cuadra.
2. **El ITBIS no se imprime por línea.** Cada línea lleva solo la marca de su tasa: «18», «16» o «E», al final de la descripción, como hoy «(E)». La razón: con L-1 el ITBIS solo existe **por tasa sobre la suma**, el XML no lo declara por línea, y un ITBIS por línea no sumaría el total.
3. **Pie del ticket:**
   - **con ITBIS incluido:** TOTAL; debajo, «Incluye: base gravada 18 % … · ITBIS 18 % …» por tasa, y «Exento …»;
   - **sin ITBIS:** subtotal, descuento, ITBIS por tasa y TOTAL, como hoy.
4. **Factura carta:** la columna «ITBIS» por línea **se sustituye por «Tasa»**. El ITBIS va en el cuadro de totales, por tasa.
5. **El total que ve el cajero mientras escanea** sale de la misma `Calculadora` con L-1 que usa el servidor. Así el total de la pantalla es igual al que se cobra y al que se declara.

### Preguntas al propietario
- **POS-7.** ¿Se quita el ITBIS por línea de la RI de carta, aunque algunos clientes de crédito fiscal lo pidan? **Recomiendo: sí, sustituirlo por «Tasa».** Alternativa descartada: un ITBIS por línea «referencial» prorrateado para que sume el total. Da cifras que no están en el XML y genera reclamos.
- **POS-8.** Con la empresa en modo incluido, ¿se advierte en Listas de Precios cuando un renglón tiene `IncluyeImpuesto` en el otro modo? **Recomiendo: sí, con un aviso no bloqueante.** Los centavos de la conversión (84,75 → 100,01) sorprenden en la góndola.
- **POS-9 (fuera de L-1, pero se nota en el arqueo).** ¿Cómo se tratan los centavos del vuelto en efectivo? **Recomiendo:** el documento conserva el total exacto, y el vuelto se redondea **a favor del cliente** al peso. La diferencia se registra como «redondeo de efectivo» en el arqueo, para que no aparezca como faltante. Debe confirmarlo el especialista-contable.

---

## Riesgos operativos

| Riesgo | Severidad | Mitigación |
|---|---|---|
| Un rechazo masivo (por ejemplo, certificado o delegación vencidos) con cientos de RI ya entregadas | Alta | Reemisión por lote desde la bandeja (punto 1); alarma de salud del conector |
| Cambio de tipo usado para vender crédito fiscal | Alta | Privilegio sin el cajero, motivo, `_LOG` y reporte en la ola 5 (punto 2) |
| Al pasar al modo incluido se reetiquetan los precios mal | Media | Aviso en las listas (POS-8) y prueba en la DEMO antes del corte |

## Supuestos
- Las preguntas frecuentes de la DGII reflejan el Decreto 587-24 vigente. No releí el decreto.
- El comercio objetivo publica precios con ITBIS incluido (inferido de la práctica local y de la Ley 358-05; sin verificar en la norma).
- El límite de ±1 a 2 centavos es estadístico (inferido), no medido.

### Cierre
- Estado: Completado
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\pos-conector-iq-2026-10-07.md`
- Supuestos: los de la sección «Supuestos»
- Decisiones candidatas a ADR: reemisión con un e-NCF nuevo sobre el mismo documento tras un `RECHAZADO` (alternativa descartada: una E34 sobre el rechazado); «Cambiar tipo» solo en la oficina (alternativa descartada: en la caja con la clave del supervisor)
- Entregas a otros agentes: arquitecto-software y arquitecto-datos de A → la reemisión tras un rechazo (segundo e-NCF del documento, fuera de A-01) y el nombre del genérico en `fiscal.ComprobanteInstantanea`; especialista-contable → POS-1 (ANECF del e-NCF rechazado), POS-2 y POS-9; disenador-ux-ui → la bandeja de rechazos, «Atendido a:», la columna «Tasa» y el pie del ticket por modo
- Próximo paso recomendado: que el propietario responda POS-1 a POS-9 y que A incorpore la reemisión tras un rechazo antes de congelar el DDL de `fiscal.Ecf`
