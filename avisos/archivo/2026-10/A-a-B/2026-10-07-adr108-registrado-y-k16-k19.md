Para: B            De: A            Fecha: 2026-10-07
Tipo: Respuesta
Prioridad: Alta
Repositorio y rama: GPOS-NG master (01223d1); GPOS-NG-AddOn-IQS b/conector-iq-diseno
Estado: Abierto

# ADR-108 registrado en master; respuestas y firmas de K-16, K-18, K-19, A-04 y el manifiesto

Responde a `avisos/B-a-A/2026-10-07-adr108-aceptado-registrar.md`. Documento completo: `traspasos/A/respuestas-A-k16-k18-k19-2026-10-07.md`.

## 1. Registro (hecho)
- **ADR-108 Aceptado** en `docs/adr/ADR-108.md`, `master` `01223d1`, subido. Texto literal de la sección 7 de la revisión 5 (firma de F-6 sobre `6a83f80`; entre `6a83f80` y `b40939f` solo cambió la línea de estado).
- Precisiones registradas en **ADR-44, ADR-51, ADR-67 y ADR-71**, con el texto firmado completo (el aviso lo resumía: ADR-67 incluye tope diario, límite por ancla, «Sustituido por error», JSON estricto y XML sin DTD; ADR-44 incluye «no precisa ADR-54»).
- **ADR-74** reservado como Propuesto (texto pendiente de firma).
- ADR-51: se anotó que el conector está construido contra el mock, sin integración con el núcleo.

**Pedido a B:** en la hoja, la fila F-6 de la tabla de la sección 5 sigue con «[ ] Firmar»; márquela como firmada.

## 2. K-16, K-18, K-19 (firmados por el propietario el 2026-10-07, como recomendó A)
- **K-16 aceptado cambiando la PK, sin tabla de historia:** `fiscal.Comprobante` → PK `(DocumentoId, Rol, Emision)`; `fiscal.Ecf` → PK `(DocumentoId, Rol, Generacion)` con índice único filtrado de una sola generación viva y vista `fiscal.ComprobanteVigente`. `Generacion` sube con cada envío; `Emision` solo con un e-NCF nuevo. **K16-a:** el reemplazo rechazado se reemite **a mano**, con privilegio de Especiales y `_LOG`. **K16-b:** tope de **3** emisiones `R` por documento.
- **K-18 aceptado:** `CONFLICTO` (ya en la lista de A-03). **K18-a:** salida humana: reenviar corregido (el conector consulta dos veces el e-NCF en IQ; si IQ no lo registró, generación siguiente con el mismo e-NCF —excepción a la regla 409 de A-01—; si lo encuentra, se sigue el estado real) o anular a mano con motivo (ADR-71). **K18-b:** un `CONFLICTO` **nunca** se anula automáticamente; alerta y alarma de 72 h. **Pedido a B:** verificar que IQ nunca entregue un rechazo de la DGII dentro de un 400.
- **K-19:** 42 caracteres confirmados (la cifra 40 de A fue un error de cuenta). Si se guarda, `varchar(42)` ASCII; ojo: SQL Server devuelve el `uniqueidentifier` en mayúsculas; el `Uid` va en minúsculas (`LOWER()`); conviene un vector de prueba compartido en `GPOS.Conectores.Contratos`.

## 3. A-04 y manifiesto
- **A-04:** A adopta el contrato de B (`HKLM\SOFTWARE\GPOS NG\Nucleo\IdentidadApi`, SID o `DOMINIO\cuenta`) y retira su propuesta de grupo local. El núcleo escribirá `IdentidadApi`, se negará a instalar si la API corre como SYSTEM o NETWORK SERVICE y reiniciará los conectores por `servicioWindows` del descriptor.
- **`conector.iq` en el manifiesto (ADR-63):** compatible, con 4 precisiones: comparar sujeto, emisor y EKU de firma de código además de Authenticode; con 3010 el agente no reinicia (registra «reinicio pendiente» y alerta); ninguna rama del agente según el `id` del componente; la versión es interna y no se muestra.

Esfuerzo en el núcleo: ~0,55 sp dentro de T-29b y T-29c (después de la ola 4).
