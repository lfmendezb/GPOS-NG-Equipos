# Consulta preliminar al abogado colegiado: solicitudes de los titulares de datos personales en GPOS NG (ADR-92, fase TT), deuda pendiente, conservación fiscal, cédula en impresos y padrón de comensales

> **Borrador de trabajo, no es asesoría legal; requiere la revisión de un abogado colegiado.**
> Lo prepara el asesor-legal (agente) para el propietario. No se ha enviado a nadie. El propietario lo revisa, lo corrige y decide si lo envía.

- **Fecha:** 2026-10-22 · **Para:** abogado colegiado del propietario (por medio del propietario) · **De:** GSF (propietario), con el apoyo de los agentes del proyecto
- **Plazo pedido:** respuesta **preliminar antes del 2026-11-09**; definitiva antes del **2026-11-16**, cuando el equipo B empieza a construir la fase TT (hoja de firma de las precisiones de ADR-92, «Puntos abiertos»; marco normativo, sección 4) [V].
- **Número de la consulta:** borrador 2. El borrador 1 es la consulta del CI-7 (`docs/decisiones/2026-10-20-consulta-legal-ci7-borrador.md`), con el marco normativo verificado (`docs/legal/2026-10-20-marco-normativo-verificado.md`) y sus preguntas L-01 a L-16. Esta consulta **no los sustituye**: precisa L-03 y L-04 y agrega preguntas nuevas.
- **Confidencialidad:** no contiene datos de ningún cliente ni datos personales; los casos son genéricos.

**Marcas.**
- **[V]**: citado de un documento del repositorio del proyecto o del área común (con su ruta). Cuando el dato es un artículo de ley, [V] significa que **el marco normativo del 2026-10-20 lo leyó en una copia oficial** (`docs/legal/2026-10-20-marco-normativo-verificado.md`); no se volvió a leer la ley en esta sesión y **ninguna norma se cotejó con la Gaceta Oficial** (marco, sección 0).
- **[I]**: inferencia o postura de GSF, no verificada. Es una hipótesis para el abogado.
- **«A confirmar por el abogado»**: norma, artículo o principio que no se pudo verificar; no se cita como hecho.

**Documentos que conviene adjuntar al enviar** (todos internos, sin datos de clientes): ADR-92 (`docs/adr/ADR-092.md`), la hoja de firma del 2026-10-22 (`docs/decisiones/2026-10-22-hoja-firma-adr92-precisiones.md`), la consulta del CI-7 y el marco normativo del 2026-10-20.

---

## 1. Resumen (una página)

**Qué es GPOS NG y quién es quién [V con I].** Sistema de gestión y punto de venta por suscripción, instalado en los servidores del cliente (no SaaS); GSF entrega la licencia y las actualizaciones y no aloja los datos (`CLAUDE.md`). Hipótesis de trabajo, aún sin confirmar (L-01 del marco): **el cliente es el responsable del tratamiento** y GSF solo actúa como **encargado** cuando su personal entra con el rol SUPER por una solicitud válida (marco, 2.1, «Conclusión del tema») [I].

**Qué decidió ya el propietario (ADR-92 y precisiones del 2026-10-22) [V].**
- La empresa cliente atiende las solicitudes de rectificar o suprimir **solo de personas físicas** (TT-01), deducidas hoy por el tipo de identificación (cédula, pasaporte o sin número = física; RNC de 9 dígitos = jurídica).
- **Suprimir = anonimizar lo que no hay que conservar y bloquear lo que sí** (TT-03): se conservan el nombre y el documento para los comprobantes ya emitidos y las autoridades; teléfonos, correos, dirección y notas se anonimizan. Es irreversible.
- Los **comprobantes emitidos no se tocan** (TT-04). La supresión **sí alcanza el historial temporal** del maestro (F-5), pero **no los respaldos** (P-1, riesgo residual aceptado).
- **Deuda (F-9):** los saldos a favor no bloquean; con deuda por cobrar, la empresa **aplaza solo la supresión de los datos estrictamente necesarios** para cobrar y no los usa para otro fin; con una cuenta por pagar a un proveedor, una bandera con dos opciones («Proceder de todos modos» o «Esperar a saldar la deuda»).
- Al terminar la conservación (10 años desde el último comprobante), el ADMIN dispara a mano la anonimización final del nombre y el documento (F-7).

**Lo que necesitamos del abogado, en cinco temas.**
1. **L-03 (alcance):** si basta limitar a personas físicas; si la persona física comerciante con RNC está protegida; si la supresión debe alcanzar respaldos, bitácoras y adjuntos (preguntas 1 a 5).
2. **L-04 (bloqueo y anonimización):** si el bloqueo con anonimización cumple la supresión, qué campos exige conservar el fisco, y qué pasa con las copias en documentos, con cotizaciones y pedidos y con las notas de crédito posteriores (preguntas 6 a 11).
3. **Deuda (F-9):** si una deuda permite aplazar la supresión dentro del plazo de 10 días hábiles, qué datos bastan para cobrar, y si el saldo a favor y la deuda con un proveedor se tratan bien (preguntas 12 a 16).
4. **Conservación fiscal:** si la obligación de conservar justifica guardar los datos del titular en el maestro bloqueado, desde cuándo cuenta el plazo (con el contador, Q-TT5-a) y si la anonimización final puede quedar a mano (preguntas 17 a 20).
5. **Cédula en impresos no fiscales (C-1 de T4-10)** y **padrón de comensales** de un empleador (encargado frente a responsable) (preguntas 21 a 27).

**Lo más urgente (bloquea construir TT el 2026-11-16) [I]:** las preguntas 6, 7, 12 y 17. Si el abogado solo puede responder unas pocas antes del 2026-11-09, que sean esas.

**Riesgo principal si no hay respuesta:** GSF construye con las opciones recomendadas; si alguna resulta contraria a la ley, el cliente (responsable) queda expuesto a un hábeas data o a una indemnización, y ese riesgo podría trasladarse a la relación con GSF (marco, 2.1) [I]. El costo de corregir después es mayor si toca documentos fiscales sellados (ADR-74, citado en TT-04) [V].

**Nota sobre L-03 [V].** Los documentos del proyecto usan L-03 con dos alcances distintos: el marco (sección 4) la define como «limitar a personas físicas; alcance a respaldos, bitácoras y adjuntos»; ADR-92 (TT-01 y TT-04) la cita para «la persona física comerciante con RNC propio» y «el historial temporal». Esta consulta cubre **los dos alcances** (preguntas 1 a 5). El texto de L-04 coincide en ambos documentos.

---

## 2. Preguntas

Formato de cada pregunta: **pregunta cerrada (Sí / No / Depende)**; contexto breve; postura o recomendación de GSF (con su fuente); qué decide el abogado; riesgo si la respuesta de diseño resulta equivocada.

### Bloque A · L-03: alcance de la protección y de la supresión

**1. ¿Basta con que la atención de las solicitudes de rectificar o suprimir se limite a los registros de personas físicas, y no a los de personas jurídicas ni a los datos profesionales de quienes trabajan para ellas? (Sí / No / Depende)**
- **Contexto.** El marco leyó que la Ley 172-13 no se aplica a los datos de personas jurídicas ni a los archivos con solo datos profesionales de las personas físicas que trabajan para ellas (art. 4.4) [V, marco 2.1]. ADR-92 limita la acción a personas físicas y excluye el campo «Contacto» de los clientes con RNC (TT-01 a) [V].
- **Postura de GSF.** Sí: TT-01 (a), firmada el 2026-10-20 [V].
- **Decide el abogado.** Si el art. 4.4 permite esa exclusión sin más, y si hay casos de persona jurídica cuyos datos igual deban tratarse como personales.
- **Riesgo si se equivoca.** Si la exclusión no basta: un titular no podría ejercer su derecho desde GPOS NG y el cliente incumpliría el plazo de 10 días hábiles (art. 8, marco 2.1 [V]). Corrección: ampliar la ruta (costo inferido bajo, porque la regla es por tipo de registro).

**2. ¿La persona física comerciante que factura con su propio RNC (sea su cédula de 11 dígitos o un RNC antiguo de 9 dígitos) está protegida por la Ley 172-13 en sus datos de contacto comercial? (Sí / No / Depende)**
- **Contexto.** El sistema deduce el tipo por el largo del número: 11 dígitos = cédula (`C`, persona física), 9 dígitos = RNC (`R`, persona jurídica) (respuesta del especialista-pos, hallazgo 0.1 y 2.2) [V]. El propietario confirmó que ningún dato distingue a una persona física con RNC; solo la estructura del número (hoja, Q-TT1-a) [V]. Según el especialista-pos, pueden existir personas físicas con RNC antiguo de 9 dígitos, que el sistema trataría como jurídicas [I, no verificado en fuente de la DGII]. El propietario aprobó un maestro «Tipo de identificador fiscal» (ADR-161, aún no construido) que lo resolverá (hoja, P-3) [V].
- **Postura de GSF.** Mientras no exista el maestro: deducción por el largo; el caso del RNC de 9 dígitos de persona física queda como riesgo residual (hoja, sección 3, TT-P1) [V].
- **Decide el abogado.** Si esa persona está protegida y, si lo está, si sus datos de contacto comercial (teléfono, correo, dirección del negocio) son personales o «profesionales» en el sentido del art. 4.4.
- **Riesgo si se equivoca.** Si está protegida y el sistema la trata como jurídica: el cliente no puede atenderla desde la ruta de TT (error por defecto) hasta que exista el maestro de ADR-161. Riesgo inferido: probabilidad baja, impacto medio.

**3. ¿El derecho de supresión obliga a suprimir o bloquear también el dato en los respaldos de la base de datos? (Sí / No / Depende)**
- **Contexto.** El marco no halló una regla expresa sobre respaldos [I, consulta CI-7, 1.4]. El propietario decidió que la supresión **no** cubre los respaldos (hoja, P-1) [V]; el respaldo lo hace el cliente con la herramienta del propietario (`CLAUDE.md`, «Respaldo»).
- **Postura de GSF.** No; riesgo residual aceptado (P-1) [V]. [I] Una práctica posible, sin costo de construcción: que el procedimiento de restauración obligue a repetir las supresiones registradas en la bitácora después de restaurar.
- **Decide el abogado.** Si basta con no tocar los respaldos, si hace falta la medida de «repetir al restaurar» o si hay que fijar un plazo máximo de conservación de los respaldos.
- **Riesgo si se equivoca.** Al restaurar un respaldo antiguo, reaparecen datos suprimidos y el cliente los vuelve a tratar. Con la medida anterior el riesgo baja; sin ella, el cliente podría incumplir sin saberlo [I].

**4. ¿Las bitácoras del sistema deben anonimizarse al suprimir, o basta con que no registren los valores de los datos? (Sí, anonimizar / No, basta lo previsto / Depende)**
- **Contexto.** El acto de rectificar o suprimir queda en la bitácora de la empresa con el motivo, la fecha, el código del registro y **los nombres de los campos tocados, sin sus valores**, por al menos 10 años (TT-06 y F-6) [V]. La bitácora de accesos del SUPER guarda 5 años, plazo que el abogado debe confirmar (L-12; ADR-92, CS-08) [V].
- **Postura de GSF.** No anonimizar: la bitácora no guarda el dato suprimido [V, TT-06].
- **Decide el abogado.** Si el código del registro y la fecha, junto con el comprobante conservado, son a su vez un dato personal que deba bloquearse, y si los 10 años de F-6 se justifican.
- **Riesgo si se equivoca.** Bajo [I]: la bitácora no conserva los valores suprimidos.

**5. ¿El documento del poder del apoderado del titular, que el cliente adjunta a la solicitud, debe conservarse durante un plazo fijo y luego destruirse? (Sí / No / Depende)**
- **Contexto.** El propietario decidió registrar al apoderado y adjuntar el poder íntegro «como aval en caso de proceso legal» (hoja, P-2) [V]. Si va a la papelera de 30 días o se conserva como soporte, y por cuánto, está sin definir (hoja, «Puntos abiertos») [V]. El poder contiene datos personales del titular y del apoderado [I].
- **Postura de GSF.** Ninguna todavía; propuesta [I]: conservarlo mientras dure la prescripción de las responsabilidades por la solicitud y luego destruirlo.
- **Decide el abogado.** El plazo y si basta una copia parcial (en vez del documento íntegro).
- **Riesgo si se equivoca.** Conservar de más un documento con datos personales, o destruirlo antes de una reclamación del titular.

### Bloque B · L-04: supresión por bloqueo o anonimización

**6. ¿Cumple el cliente con el derecho de supresión si, en un registro que aparece en comprobantes fiscales, anonimiza los campos que no exige la ley fiscal y bloquea el resto (nombre y documento), en vez de borrarlo? (Sí / No / Depende)**
- **Contexto.** El marco leyó que la supresión no procede cuando hay una obligación legal o contractual de conservar, y que la cancelación equivale al bloqueo: el responsable deja de usar el dato y lo conserva solo para las autoridades durante la prescripción de las responsabilidades (Ley 172-13, arts. 6.5, 8 y 15) [V, marco 2.1]; y que el Código Tributario obliga a conservar 10 años los comprobantes y documentos (art. 50 h, redacción de la Ley 495-06) [V, marco 2.2]. ADR-92 lo aplica en TT-03 (a) [V].
- **Postura de GSF.** Sí: TT-03 (a), firmada [V].
- **Decide el abogado.** Si la mecánica cumple; si el bloqueo debe impedir también la consulta del registro por los usuarios comunes (hoy solo impide usarlo en documentos nuevos y reactivarlo) [I].
- **Riesgo si se equivoca.** Alto: es la regla central de TT. Si no cumple, hay que rediseñar la supresión antes de construir.

**7. ¿Es correcta esta lista de qué se conserva y qué se anonimiza al suprimir? (Sí / No, con cambios)**
- **Contexto.** Propuesta del especialista-pos, por maestro (respuesta del especialista-pos, 1.2, 1.5 y 1.7) [V]:
  - **Clientes y suplidores:** se conservan la razón social (el nombre) y el documento de identidad; se anonimizan el nombre comercial, los teléfonos (incluido el fax), los correos, la dirección, el contacto, la página web y la nota.
  - **Empleados:** se conservan nombres, apellidos y cédula; se anonimizan teléfono y correo.
- **Postura de GSF.** Sí, como propuesta; ADR-92 reservaba la lista final al abogado con el contador (TT-03 i) [V].
- **Decide el abogado** (con el contador): campo por campo. En especial: el **nombre comercial** (no aparece en el comprobante fiscal [I]); el **contacto**, que es el nombre de otra persona (un tercero) [V, especialista-pos 1.2]; y qué datos del **empleado** obliga a conservar la ley laboral y por cuánto tiempo (especialista-pos, sección 5, punto 6) [V].
- **Riesgo si se equivoca.** Anonimizar un dato que el fisco o la ley laboral exige (sanción por deberes formales, Código Tributario art. 257 [V, marco 2.2]) o conservar uno que debía suprimirse (hábeas data). Cambiar la lista después es barato: es un archivo versionado (hoja, F-4) [V].

**8. ¿Deben anonimizarse el teléfono y el correo del titular que quedaron copiados en las facturas ya emitidas? (Sí / No / Depende)**
- **Contexto.** Cada venta guarda su propia copia del nombre, la identificación, el teléfono y el correo del cliente (especialista-pos, 1.1) [V]. ADR-92 no toca los documentos emitidos mientras el abogado no diga lo contrario (TT-04) [V]. Un correo anonimizado impide reenviar el comprobante al titular, sin afectar su validez ante la DGII (especialista-pos, 3.3.1) [I].
- **Postura de GSF.** No: los documentos emitidos y sellados no se modifican (TT-04) [V].
- **Decide el abogado.** Si la obligación de conservar el comprobante alcanza a esos dos datos o solo al nombre y al documento.
- **Riesgo si se equivoca.** Si hay que anonimizarlos: precisión con costo, porque toca documentos sellados (ADR-74) [V, TT-04]; mientras tanto, el dato sigue en cada documento del titular.

**9. ¿Puede el cliente conservar sin cambios el nombre y el teléfono del titular en las cotizaciones y los pedidos que nunca se convirtieron en factura? (Sí / No / Depende)**
- **Contexto.** Cotizaciones y pedidos no son comprobantes fiscales (`docs/pos/2026-10-01-ncf-y-existencias-iniciales.md:83`, citado por el especialista-pos, 3.1) [V]; no hay obligación fiscal de conservarlos [I].
- **Postura de GSF.** Sí para la v1: conservarlos como están hasta su archivado normal (opción (a) del especialista-pos, 3.1); pendiente de la decisión del propietario [V].
- **Decide el abogado.** Si la supresión debe alcanzarlos.
- **Riesgo si se equivoca.** Medio [I]: son documentos sin justificación fiscal de conservación. Si la respuesta es No, hay que anonimizarlos al suprimir (opción (b)), con un costo de construcción no estimado.

**10. ¿Puede el cliente seguir emitiendo, a un titular bloqueado, notas de crédito o débito, devoluciones y recibos de cobro que modifican o cobran comprobantes ya emitidos? (Sí / No / Depende)**
- **Contexto.** Según un documento del proyecto, la Ley 32-23 (art. 15, nums. 3 y 4) dice que la nota de crédito o débito solo puede emitirse al mismo adquiriente para modificar comprobantes anteriores (`docs/pos/2026-10-01-ncf-y-existencias-iniciales.md:68`, citado por el especialista-pos, 3.2) [V como cita del documento; el artículo no se leyó en esta sesión: a confirmar por el abogado]. Un documento con e-NCF no se anula: se reversa con nota de crédito (ADR-108; `CLAUDE.md`) [V].
- **Postura de GSF.** Sí: el bloqueo impide documentos nuevos, no los que modifican, cobran o pagan comprobantes o saldos anteriores del mismo tercero (redacción propuesta por el especialista-pos, 3.2; sin firmar) [V].
- **Decide el abogado.** Si ese uso del dato bloqueado es compatible con el bloqueo (dejar de usar el dato salvo para las autoridades).
- **Riesgo si se equivoca.** Si no se permite: el cliente no podría corregir una factura ni cobrar una deuda del titular, y tendría que elegir entre incumplir la norma fiscal o la de datos personales.

**11. ¿El campo «contacto» de un cliente persona física (nombre de un familiar o de un asistente) es un dato de un tercero que el cliente debe tratar con sus propias reglas? (Sí / No / Depende)**
- **Contexto.** El especialista-pos señala que es el nombre de otra persona (1.2) [V].
- **Postura de GSF.** Anonimizarlo al suprimir el registro del titular (especialista-pos, 1.7) [V].
- **Decide el abogado.** Si ese tercero tiene sus propios derechos sobre el campo (por ejemplo, pedir que se borre aunque el titular no lo pida).
- **Riesgo si se equivoca.** Bajo [I]; afecta al texto de la pantalla y quizás a una acción separada.

### Bloque C · Deuda pendiente (F-9)

**12. ¿Puede el cliente, ante una solicitud de supresión de un titular que le debe dinero por una deuda emitida legítimamente, aplazar la supresión de los datos estrictamente necesarios para cobrar, más allá del plazo de 10 días hábiles? (Sí / No / Depende)**
- **Contexto.** El marco leyó que la supresión no procede cuando perjudique derechos de terceros o exista una obligación contractual o legal de conservar (art. 8; art. 15) [V, marco 2.1]. También leyó que el responsable debe garantizar el hábeas data «en cualquier circunstancia» (art. 13) [V, marco 2.1]. El propietario sostiene que la deuda emitida legítimamente está protegida por la ley y justifica aplazar (hoja, registro de la firma de F-9) [V]; la hoja deja ese razonamiento «a confirmar con el abogado» [V].
- **Postura de GSF.** Sí, con tres límites: aplazar solo los datos estrictamente necesarios, suprimir el resto dentro del plazo, y no usar los aplazados para otro fin que el cobro (F-9) [V].
- **Decide el abogado.** Si la deuda es una «obligación contractual» o un «derecho de tercero» en el sentido del art. 8 (texto a confirmar por el abogado); si hay que comunicar al titular, dentro de los 10 días hábiles, qué se suprimió, qué se aplazó y por qué; y hasta cuándo dura el aplazamiento (¿hasta el pago o hasta que prescriba la acción de cobro?).
- **Riesgo si se equivoca.** Alto: si el aplazamiento no está permitido, el cliente incumple el plazo y el titular puede ir al hábeas data (art. 8, marco 2.1 [V]). Si sí lo está pero no se comunica, el titular no sabe por qué no se suprimió.

**13. ¿Bastan el nombre, el documento de identidad y un solo medio de contacto como datos «estrictamente necesarios» para cobrar la deuda? (Sí / No, con cambios)**
- **Contexto.** Propuesta de B, sin firmar (hoja, «Puntos abiertos») [V]. Quien completa la supresión cuando se salda la deuda: propuesta de B, el ADMIN desde un listado de supresiones aplazadas, sin destrucción automática (hoja, «Puntos abiertos») [V].
- **Postura de GSF.** Sí, como propuesta [V].
- **Decide el abogado.** La lista, y si la dirección hace falta para una intimación o una demanda de cobro.
- **Riesgo si se equivoca.** Conservar de más (exceso) o no poder demandar por falta de un dato (por ejemplo, el domicilio).

**14. ¿Basta con que el registro quede bloqueado para documentos nuevos para cumplir que los datos aplazados «no se usen para otros fines» que el cobro? (Sí / No / Depende)**
- **Contexto.** El registro bloqueado no se puede usar en documentos nuevos (TT-03 ii) [V]. Falta verificar en el código si puede seguir recibiendo avisos o correos masivos (hoja, «Puntos abiertos») [V]; también si un cliente inhabilitado puede recibir cobros (hoja, «Puntos abiertos»; especialista-pos, 3.2) [V].
- **Postura de GSF.** Sí, si se excluye el registro de envíos masivos [I].
- **Decide el abogado.** Si hace falta un control más (por ejemplo, una marca visible «solo para cobro» o un registro de cada uso).
- **Riesgo si se equivoca.** Uso del dato fuera de su finalidad, sancionable [I; las sanciones de la ley están en el marco 2.1].

**15. ¿Puede el cliente suprimir los datos de un titular que tiene un saldo a su favor (por ejemplo, un anticipo o una nota de crédito sin usar), sin avisarle del saldo? (Sí / No / Depende)**
- **Contexto.** El propietario decidió que los saldos a favor no bloquean la supresión, «puesto que si el solicitante no ejerce su derecho de consumirlo no es responsabilidad del negocio recordárselo» (hoja, F-9) [V]. El saldo sigue registrado contra un registro bloqueado; el titular podría reclamarlo después [I].
- **Postura de GSF.** Sí, no bloquea (F-9) [V].
- **Decide el abogado.** Si suprimir los datos de contacto sin informar del saldo puede verse como un obstáculo a que el titular cobre lo suyo (en particular si el titular es un consumidor; aplicación de la Ley 358-05 a ese caso: a confirmar por el abogado); y cómo se identifica después al titular que reclama el saldo (el nombre y el documento se conservan bloqueados).
- **Riesgo si se equivoca.** Medio [I]: reclamación del titular o discusión sobre enriquecimiento indebido; se mitiga con un texto en la respuesta a la solicitud.

**16. Cuando el cliente debe dinero a un proveedor persona física que pide suprimir sus datos, ¿puede «proceder de todos modos» con la supresión sin afectar su obligación de pagar ni sus deberes fiscales? (Sí / No / Depende)**
- **Contexto.** El propietario decidió una bandera con el motivo (la cuenta por pagar adeudada) y dos opciones claramente reconocibles: «Proceder de todos modos» o «Esperar a saldar la deuda» (hoja, F-9) [V]. Si el proveedor es informal, el propio cliente emite el comprobante de compras y retiene impuestos; el nombre y la cédula son soporte de ese comprobante (especialista-pos, 1.3) [I, a confirmar por el contador].
- **Postura de GSF.** Sí, porque el nombre y el documento se conservan bloqueados y el pago puede seguir registrándose (TT-03; especialista-pos, 3.2) [V con I].
- **Decide el abogado.** Si el cliente puede atender la supresión de un acreedor sin perjudicarlo (¿pierde el medio de contacto para pagarle?), y si «esperar a saldar la deuda» es una negativa que debe comunicarse al titular dentro del plazo.
- **Riesgo si se equivoca.** Bajo a medio [I]: dificulta el pago al proveedor; no elimina la deuda.

### Bloque D · Conservación fiscal de los datos del titular

**17. ¿La obligación de conservar los comprobantes fiscales (facturas, notas de crédito y débito, e-NCF) justifica que el cliente conserve, bloqueados en el maestro, el nombre y el documento del titular durante el mismo plazo, y no solo dentro de cada comprobante? (Sí / No / Depende)**
- **Contexto.** El Código Tributario obliga a conservar 10 años los comprobantes y cualquier documento, físico o electrónico, y los medios de almacenamiento de los sistemas (art. 50 h, redacción de la Ley 495-06) [V, marco 2.2]; para los e-CF lo repiten la Ley 32-23 (arts. 13 y 17) y la NG 01-2020 (art. 16) [V, marco sección 3, punto 1]. El e-CF firmado lo custodia el proveedor (IQ); GPOS NG guarda el JSON enviado con huella y sello (`CLAUDE.md` y memoria del proyecto) [V]. ADR-92 conserva el nombre y el documento en el maestro bloqueado (TT-03 ii) [V]. Cuentan como «comprobante que lo usa» los documentos fiscales y los saldos vivos, no las cotizaciones ni los pedidos (especialista-pos, 3.1; pendiente de Q-TT5-b) [V].
- **Postura de GSF.** Sí: el comprobante y su soporte en el maestro forman la misma conservación [I].
- **Decide el abogado** (con el contador): si el maestro bloqueado está cubierto por la obligación o si basta la copia del comprobante (en cuyo caso el maestro podría anonimizarse por completo antes).
- **Riesgo si se equivoca.** Si basta la copia: el cliente conserva sin necesidad el nombre y el documento en el maestro hasta 10 años. Si no se conservara y la DGII pide el soporte: deber formal incumplido (art. 257, marco 2.2 [V]).

**18. ¿El plazo de conservación que justifica el bloqueo se cuenta desde la fecha de cada comprobante? (Sí / No: desde el cierre del ejercicio o la declaración / Depende)**
- **Contexto.** Es la pregunta **Q-TT5-a del contador** (hoja, «Puntos abiertos») [V]; aquí se pide al abogado solo su lado: la Ley 172-13 permite conservar el dato bloqueado «durante la prescripción de las responsabilidades» (art. 15, marco 2.1) [V], que no tiene por qué coincidir con los 10 años del art. 50 h. El marco leyó que el art. 21 del Código Tributario fija la prescripción en tres años y que la Ley 30-26 modifica el art. 24 (prescripción), cuyo efecto queda por revisar con el contador [V, marco 2.2].
- **Postura de GSF.** Hoy el sistema calcula «10 años desde el último comprobante que lo usa», sin guardar la fecha (F-7) [V]. Si el contador responde «desde el cierre del ejercicio», cambia la fórmula, no el diseño [I].
- **Decide el abogado.** Cuál de los dos plazos (conservación fiscal o prescripción de las responsabilidades) manda para el bloqueo de datos personales, y si el más largo siempre se impone.
- **Riesgo si se equivoca.** Contar desde la fecha del comprobante cuando debía contarse desde el cierre acorta la conservación hasta casi un año [I]; lo contrario la alarga sin base.

**19. Vencido el plazo de conservación, ¿basta con que el ADMIN dispare a mano la anonimización final desde un listado, sin una tarea automática? (Sí / No / Depende)**
- **Contexto.** Decisión F-7: el sistema calcula el fin de la conservación y lo muestra en «Registros bloqueados con conservación vencida»; el ADMIN decide [V]. El marco leyó que, cumplido el plazo, el responsable suprime (art. 15) [V, marco 2.1].
- **Postura de GSF.** Sí: el sistema no destruye datos sin una decisión humana (hoja, «Puntos abiertos», propuesta de B) [V].
- **Decide el abogado.** Si la ley exige suprimir de oficio al vencer el plazo y, si es así, si basta un aviso al ADMIN o hace falta un plazo máximo para actuar.
- **Riesgo si se equivoca.** Datos conservados más allá del plazo si el ADMIN no actúa (riesgo del cliente, responsable) [I].

**20. ¿Hay una obligación legal (laboral o de seguridad social) de conservar los datos del empleado que impida anonimizarlos al suprimir, y por cuánto tiempo? (Sí / No / Depende)**
- **Contexto.** El empleado no tiene comprobante fiscal propio en GPOS NG; su conservación se justifica por la relación laboral y las comisiones (especialista-pos, 1.5 y sección 5, punto 6) [V]. Normas laborales: no se revisaron en esta consulta, **a confirmar por el abogado**.
- **Postura de GSF.** Conservar nombres, apellidos y cédula; anonimizar teléfono y correo (especialista-pos, 1.5) [V].
- **Decide el abogado.** El plazo y los datos.
- **Riesgo si se equivoca.** Anonimizar datos que una inspección laboral pueda pedir, o conservar sin base [I].

### Bloque E · Cédula en impresos que no son fiscales (C-1 de T4-10)

**21. ¿Puede el cliente imprimir la cédula completa del cliente en documentos que no son comprobantes fiscales con receptor (cotización, pedido, conduce, cheque devuelto, ticket de consumo final sin receptor)? (Sí / No: debe enmascararse / Depende)**
- **Contexto.** La decisión C-1 del tramo 4 de la ola 5 manda imprimir el RNC y la cédula íntegros en todo documento (ADR-109, línea 127, citada por el auditor-seguridad) [V]. El auditor-seguridad lo marcó como hallazgo S-03 (Medio): la obligación fiscal justifica la cédula íntegra en los comprobantes que exigen identificar al receptor y en la constancia de retención, pero no en los demás (revisión previa de T4-10, S-03) [V como opinión técnica; su lectura de la ley es [I] según el propio auditor]. En los reportes la cédula ya va enmascarada con los últimos 4 dígitos (`*******1234`), y completa solo con el privilegio de ver datos personales (S-03) [V].
- **Principio legal.** Si la Ley 172-13 contiene un principio de calidad o de proporcionalidad (datos adecuados, pertinentes y no excesivos para la finalidad), y en qué artículo, **no se verificó en el marco del 2026-10-20: a confirmar por el abogado**. Lo que sí leyó el marco: el responsable debe limitar el acceso a quienes tengan derecho (art. 13) [V, marco 2.1], y el tratamiento sin consentimiento se admite, entre otros casos, por obligación legal o cuando deriva de una relación comercial y es necesario para cumplirla (art. 27, nums. 2 y 4) [V, marco 2.1].
- **Postura de GSF (recomendación del auditor-seguridad, aún no firmada por el propietario).** Enmascarar: cédula íntegra **solo** si es la del receptor del comprobante fiscal, en la constancia de retención y en el gasto de caja chica con NCF; en lo demás, `*******` más los últimos 4. El RNC de 9 dígitos, íntegro siempre; el pasaporte, sin cambios (nunca íntegro, ADR-115) (S-03) [V]. Costo inferido: 0,25 días-persona [V, S-03].
- **Decide el abogado.** Si la impresión íntegra en documentos no fiscales excede lo necesario. El contador confirma los tipos de comprobante que exigen la cédula (S-03) [V].
- **Riesgo si se equivoca.** Si se imprime íntegra sin base: exposición de la cédula a quien recibe el documento y a todo cajero que lo reimprime (S-03 describe la reimpresión como «canal de lectura masiva» que esquiva el privilegio de datos personales) [V]. Si se enmascara de más: un comprobante fiscal sin el dato que exige la DGII (por eso la excepción del receptor fiscal).

**22. ¿La reimpresión de documentos con la cédula por usuarios que no tienen el privilegio de ver datos personales es un acceso que el cliente, como responsable, debe limitar o registrar? (Sí / No / Depende)**
- **Contexto.** Quien tiene el permiso de «Punto de venta» puede reimprimir cualquier ticket de su sucursal; la reimpresión deja la marca «COPIA n», pero no hay control preventivo (S-03) [V]. El auditor recomienda registrar en la bitácora la reimpresión de documentos con identificación personal y un tope por usuario y hora [V como recomendación; cifra [I]].
- **Postura de GSF.** Registrar la reimpresión (recomendación del auditor) [V].
- **Decide el abogado.** Si el registro basta o hace falta restringir la reimpresión.
- **Riesgo si se equivoca.** Medio [I]: lectura masiva de cédulas por personal del cliente.

**23. ¿Puede imprimirse íntegro el RNC de 9 dígitos de una persona física inscrita con ese número, por figurar en el padrón público de la DGII? (Sí / No / Depende)**
- **Contexto.** El auditor considera que el RNC de 9 dígitos es público por estar en el padrón de la DGII (S-03) [I]. El sistema guarda el padrón en la base del sistema (`CLAUDE.md`, «Dominio») [V].
- **Postura de GSF.** Sí (S-03) [V como recomendación].
- **Decide el abogado.** Si estar en un registro público permite cualquier uso del dato.
- **Riesgo si se equivoca.** Bajo [I].

### Bloque F · Padrón de comensales de un empleador (`com.Comensal`)

**24. Cuando un restaurante (cliente de GSF) atiende el consumo corporativo de los empleados de una empresa (su cliente) y carga en GPOS NG el padrón de comensales que esa empresa le entrega, ¿es la empresa empleadora la responsable de ese padrón y el restaurante su encargado? (Sí / No / Depende)**
- **Contexto.** El padrón vive en `com.Comensal`: código del empleado en la empresa cliente, nombre, departamento opcional y estado, sin cédula; el ADMIN del restaurante lo importa por plantilla (`docs/adr/ADR-128.md:22`; ADR-88, precisión 7) [V]. La factura del período se emite a la empresa cliente y la relación de consumos por empleado se le entrega a ella (especialista-pos, 4.3) [V]. Puede haber foto, con consentimiento registrado y aviso informativo que nombra al responsable y a los encargados (ADR-88, precisión 2) [V]. ADR-88 ya prevé «cláusulas de encargado del tratamiento en el contrato con el tercero y en el de GSF con el cliente» [V]. **Nada de esto está construido**: es diseño de la entrega 3 (especialista-pos, 4.1) [V].
- **Postura de GSF.** Sí: la empresa empleadora es la responsable y el restaurante su encargado; GSF, cuando su personal entra por una solicitud válida, actuaría por cuenta del restaurante (especialista-pos, 4.3 [I]; marco 2.1 [I]).
- **Decide el abogado.** La calificación, y si cambia cuando el restaurante agrega datos propios (la foto tomada en el restaurante, los consumos, el carné).
- **Riesgo si se equivoca.** Si el restaurante es responsable (o corresponsable): debe atender él las solicitudes de los comensales en el plazo de 10 días hábiles y necesita su propio aviso y base de licitud; el diseño cambia (la solicitud no se encauza al empleador).

**25. Si el restaurante es encargado, ¿debe remitir a la empresa empleadora la solicitud de supresión de un comensal en vez de atenderla por su cuenta? (Sí / No / Depende)**
- **Contexto.** El especialista-pos propone encauzar la solicitud al empleador (4.3) [I]. Es el mismo criterio que la consulta del CI-7 aplicó a GSF frente al cliente (1.5, «GSF reenvía la solicitud al cliente») [V].
- **Postura de GSF.** Sí, salvo la foto: su consentimiento lo da el comensal y su retirada borra la foto en el acto (ADR-88, precisión 2) [V].
- **Decide el abogado.** El cauce, el plazo de remisión y qué hace el restaurante si el empleador no responde.
- **Riesgo si se equivoca.** El comensal queda sin respuesta en plazo, o el restaurante borra datos que el empleador necesita para la factura del período.

**26. ¿Debe el contrato del restaurante con la empresa empleadora incluir cláusulas de encargo del tratamiento, aunque la Ley 172-13 no regule con detalle ese contrato? (Sí / No / Depende)**
- **Contexto.** El marco leyó que la ley define al encargado (art. 6.12), le impone la seguridad (art. 5.5) y el secreto, que subsiste al terminar la relación (art. 5.6), pero no regula el contrato de encargo [V, marco 2.1; la ausencia de régimen detallado es [I]].
- **Postura de GSF.** Sí (ADR-88, precisión 2) [V]. GSF no redacta el contrato del restaurante; puede ofrecer un modelo [I, decisión comercial del propietario].
- **Decide el abogado.** El contenido mínimo, y si GSF debe ofrecer el modelo (lo que podría trasladarle responsabilidad).
- **Riesgo si se equivoca.** Sin contrato, el restaurante trata datos de terceros sin un título claro [I].

**27. ¿Cambia la respuesta a la pregunta 24 si el restaurante arma el padrón por su cuenta (sin que la empresa empleadora se lo entregue)? (Sí / No / Depende)**
- **Contexto.** El diseño admite el padrón ligado a un cliente o propio (especialista-pos, 4.3, «modelo B, `ClienteId` informado») [V]; cómo se origina el padrón en cada caso no está fijado [I].
- **Postura de GSF.** Sí: en ese caso el restaurante sería el responsable [I].
- **Decide el abogado.** La calificación.
- **Riesgo si se equivoca.** El mismo de la pregunta 24, invertido.

---

## 3. Qué es ley, qué es práctica y qué es decisión comercial

| Punto | Tipo | Base |
|---|---|---|
| Plazo de 10 días hábiles para rectificar o suprimir; bloqueo cuando hay obligación de conservar | Obligación legal | Ley 172-13, arts. 8 y 15 [V, marco 2.1] |
| Conservación de comprobantes 10 años | Obligación legal | Código Tributario, art. 50 h [V, marco 2.2] |
| Que el cliente sea el responsable y GSF el encargado | Hipótesis | [I], L-01 |
| Lista de campos que se conservan o anonimizan | Práctica propuesta, sujeta a la ley | Especialista-pos 1.7; preguntas 6 y 7 |
| No tocar los respaldos (P-1) | Decisión del propietario | Hoja del 2026-10-22; pregunta 3 |
| Suprimir el historial temporal (F-5) | Decisión del propietario, más allá del mínimo inferido | Hoja del 2026-10-22 |
| Aplazar por deuda; saldo a favor no bloquea; bandera del proveedor (F-9) | Decisión del propietario, cuya licitud se consulta | Hoja del 2026-10-22; preguntas 12 a 16 |
| Anonimización final a mano por el ADMIN (F-7) | Decisión del propietario | Pregunta 19 |
| Enmascarar la cédula en impresos no fiscales | Recomendación técnica, sin firmar | S-03; pregunta 21 |
| Cláusulas de encargo con el empleador del comensal | Decisión firmada (ADR-88); contenido legal | Pregunta 26 |

## 4. Supuestos

1. El cliente es el responsable del tratamiento y GSF un encargado ocasional (L-01, sin respuesta) [I].
2. La Ley 172-13 sigue vigente y sin reglamento general (marco 2.1) [I].
3. Los artículos citados se tomaron del marco del 2026-10-20 y no se volvieron a leer en esta sesión; la Ley 32-23, art. 15, se cita por un documento del proyecto.
4. Nada de TT, de las vistas de impresión `imp` ni del padrón `com.Comensal` está construido (ADR-92; hoja; especialista-pos, 4.1) [V].

## 5. Preguntas abiertas, responsable y fecha

| # | Pregunta | Responsable | Fecha |
|---|---|---|---|
| 1 | Preguntas 1 a 27 de esta consulta | Abogado colegiado del propietario | Preliminar antes del 2026-11-09; definitiva antes del 2026-11-16 |
| 2 | Q-TT5-a (desde cuándo cuentan los 10 años) y tipos de comprobante que exigen la cédula (preguntas 18 y 21) | Contador | Antes del 2026-11-09 |
| 3 | Revisar este borrador, ajustar el tono y decidir si se envía y con qué anexos | Propietario | Antes del 2026-10-30 [I, sugerida para dejar al abogado al menos una semana] |
| 4 | Firmar o rechazar la precisión de C-1 (pregunta 21) | Propietario, preparada por el arquitecto-maestro | Antes de unir T4-10 (S-03) |
| 5 | Cotizaciones y pedidos del titular suprimido: conservar o anonimizar (pregunta 9) | Propietario, tras la respuesta del abogado | Antes del 2026-11-16 |
| 6 | Verificar en el código si un cliente inhabilitado puede recibir cobros y notas (preguntas 10 y 14) | Desarrollador-backend del equipo B | Antes del 2026-11-16 |
| 7 | Lo que cambie el diseño tras la respuesta del abogado se prepara como precisión de ADR-92 o de ADR-109 | Arquitecto-maestro, firma el propietario | Tras la respuesta |
