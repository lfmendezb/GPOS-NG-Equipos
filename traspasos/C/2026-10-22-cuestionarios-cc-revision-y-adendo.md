```
Para: B        De: C        Fecha: 2026-10-22
Tipo: Entrega (tarea 4 del aviso 2026-10-21: borradores de los cuestionarios CC-01 a CC-05)
Prioridad: Baja
Repositorio y rama: GPOS-NG `master` (`docs/decisiones/2026-10-19-cuestionarios-catering-propietario-y-contador.md`)
Estado: Abierto (propuesta de cambios; nada enviado al contador)
```

# Cuestionarios CC-01 a CC-05: ya existen; revisión y adendo propuesto

## 1. Hallazgo principal
El encargo pedía «redactar los cuestionarios». **Ya están redactados**: la Parte B del documento del 2026-10-19 (en `master`) es un correo listo para reenviar, con las cinco preguntas, opciones, recomendación y casillas de respuesta. No escribí un segundo juego: habría partido la numeración (41, 42, 52, 53, 54 del correo consolidado) que el propio documento pide conservar. Lo que entrego es una **revisión** y un **adendo** para que B decida.

## 2. Revisión de la Parte B (lo que leí y lo que cambiaría)
Leí la Parte B completa, el ADR-128 y las respuestas P-01 a P-06. No verifiqué ninguna norma citada (art. 338 del Código Tributario, Reglamento 293-11, Norma General 06-2018): siguen «por confirmar», como el texto dice.

| # | Observación | Propuesta |
|---|---|---|
| R-1 | **La pregunta 1 no dice que el uso principal es Mensual.** Tras P-03 (2026-10-19), el cliente típico pide mensual; el texto del contador solo lo menciona como ejemplo («una factura al mes por empresa») y su ejemplo numérico es mensual, pero no declara que es el caso dominante. Para el contador cambia el peso de la respuesta | Agregar una frase: «El caso más común de nuestros clientes es la facturación mensual por mes calendario». |
| R-2 | **Falta el descuento por nómina (P-04, aclaración del propietario).** La pregunta 4 solo cubre el excedente pagado en caja por el empleado (factura B02/E32 aparte). Con el descuento por nómina, el restaurante factura **todo** el consumo, excedente incluido, en la factura agrupada de la empresa, y la empresa lo descuenta al empleado. No hay pregunta fiscal sobre eso | Agregar la pregunta 6 de este adendo (§3). Es la «necesidad nueva» que ADR-128 anota para P-04 |
| R-3 | **Series B vs e-CF.** Por la prórroga de la DGII (aviso 06-26), la emisión es exclusiva de e-CF desde el 2026-11-15. El correo habla de «B01 o E31» y «B02 o E32»; para un contador que lo lee después de esa fecha, conviene decir que **el comprobante vigente será el e-CF** | Agregar una nota de una línea en el contexto. No cambia ninguna pregunta |
| R-4 | **No se aclara si el correo consolidado del 2026-10-09 se envió** (el documento mismo lo dice: «no pude verificar»). Si ya salió, esta Parte B solo sirve de recordatorio; si no, conviene el consolidado de 19 preguntas | El propietario confirma; ya está como paso recomendado en el cierre del documento |
| R-5 | **Pregunta 5 b) mezcla dos asuntos** (facturar el mínimo no consumido, y la propina sobre lo no consumido) en una sola casilla doble. Está bien para el contador, pero al registrar la respuesta puede quedar ambigua (¿qué CC-05 desbloquea qué?) | Mantener; al registrar, anotar a) y b) por separado como ya hace la tabla C.1 |
| R-6 | **CC-01 c) «¿es aceptable al menos una factura diaria?»** es la que desbloquea el valor por omisión. Con P-03 (mensual dominante), una respuesta «solo diaria» deja al cliente típico con una factura por día; conviene que el correo pida al contador **su criterio sobre el plazo máximo en días**, no solo sí/no | Ya está en b) y en la casilla «con un plazo máximo de ______ días». Sin cambio |

## 3. Adendo propuesto: pregunta 6 (nueva)

> **Pregunta 6. Consumo corporativo: el excedente que la empresa descuenta al empleado por nómina.** *(Nueva; no tiene número en el correo del 2026-10-09)*
>
> *Qué pasa en el negocio:* algunas empresas clientes pagan **todo** el consumo del empleado al restaurante y después descuentan al empleado el excedente sobre su tope, por nómina.
>
> *Qué propone el sistema:* el restaurante incluye **todo** el consumo, excedente incluido, en la factura de crédito fiscal agrupada de la empresa. El sistema entrega a la empresa una relación del excedente por empleado y período para que haga el descuento. El restaurante no emite ningún comprobante al empleado.
>
> *Por qué preguntamos:* queremos confirmar que facturar todo a la empresa es correcto cuando la empresa luego lo recupera del empleado, y que el restaurante no tiene obligación adicional frente al empleado.
>
> Preguntas:
> - a) ¿Es correcto facturar a la empresa el 100 % del consumo, incluido lo que ella descontará por nómina?
> - b) ¿La relación del excedente por empleado debe llevar algún dato para respaldar el descuento (por ejemplo, la fecha de cada consumo)?
>
> Respuesta: a) [ ] De acuerdo. [ ] Otro: ______  b) ______

**Qué desbloquea:** el reporte de excedente por empleado y período que ADR-128 deja «decidido el comportamiento, no diseñado el reporte» (P-04). **Esa pregunta no es del contador del cliente sino de la empresa cliente** en parte (b); B decide a quién se dirige.

## 4. Lo que NO hice
- No envié nada al contador ni al propietario.
- No toqué `master` ni el documento de B: son propuestas de texto.
- No verifiqué normas (ver §2) ni confirmé si el correo del 2026-10-09 salió (R-4).

## 5. Qué necesito de B
Decidir si quiere R-1, R-2 (pregunta 6) y R-3 incorporados al documento, y por quién. Si dice que sí, C prepara el PR sobre `master` con solo esos cambios de texto (sin tocar los números 41, 42, 52, 53 y 54).
