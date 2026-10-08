# Referencia: lo que responde la API de IQ Solution en cada estado (2026-10-08)

**Fuente:** tablas `dbo.FE_ElectronicSign_SignedDatum` y `dbo.FE_ElectronicSign_SignedDatum_Message` de una base de cliente que usa el complemento `GSF.SyncToIQS`. La base se nombra solo en la conversación con el propietario.
**Confidencialidad (regla del propietario):** la base es de un cliente real. Aquí solo hay **conteos, códigos y textos genéricos de validación de la DGII**, con los dígitos ocultos. No hay RNC, e-NCF, montos, nombres, códigos de seguridad, TrackId ni fechas de documentos. **Nunca usar estos datos para ejemplos, demo ni pruebas.**
**Método:** consultas agregadas de solo lectura (`COUNT`, `GROUP BY`), sin copiar filas.

## 1. Estados que devuelve IQ (respuesta 200 de `SendECF` y de `ConsultECF`)

| `Estado` (texto) | `codigo` | Respuestas | ¿Trae código de seguridad? | ¿Trae mensajes? |
|---|---|---|---|---|
| Aceptado | 1 | 1.117 | Sí, siempre | Sí: uno con código 0 y texto vacío |
| Aceptado Condicional | 4 | 65 | Sí, siempre | Sí: códigos de la DGII (tabla 2) |
| Rechazado | 2 | 10 | Sí, siempre | Sí: códigos de la DGII (tabla 2) |
| En Proceso | 3 | 1 | Sí | Uno con código 0 |

Lo que se ve en los datos:
- **El rechazo de la DGII llega como respuesta exitosa** (la guarda el mismo código del complemento que guarda las aceptaciones), con `estado = "Rechazado"`, `codigo = 2` y la causa en `mensajes[]` con su **código numérico de la DGII**. No llega como un 400. Esto confirma lo que dijo el propietario.
- **El `codigo` del estado es estable** (1, 2, 3, 4). El conector puede usarlo en lugar del texto, con el texto solo para comprobar.
- Las 4 respuestas «En Proceso» y «Aceptado Condicional» también traen código de seguridad: el timbre existe desde la primera respuesta.

## 2. Códigos de mensaje observados (textos de la DGII; dígitos ocultos)

| Código | Estado en que aparece | Texto (resumido) |
|---|---|---|
| 0 | Aceptado, En Proceso | (vacío) |
| 11014 / 11034 | Aceptado Condicional | TotalITBIS# no coincide con Monto Gravado # × ITBIS Tasa # |
| 1934 | Aceptado Condicional | MontoGravadoI# no coincide con la suma del detalle gravado menos descuentos más recargos |
| 11105 / 3205 | Aceptado Condicional | MontoTotal no es válido |
| 11123 | Aceptado Condicional | MontoPeriodo no coincide con Monto Total + Monto no facturable |
| 1385 | Aceptado Condicional | RNCComprador no es válido |
| **1960** | **Rechazado** | MontoExento no es válido |
| **145** | **Rechazado** | Fecha de vencimiento de secuencia inválida |
| **1100** | **Rechazado** | FechaLimitePago no es válido |
| **1209** | **Rechazado** | **Este número de secuencia ya ha sido utilizado** (dictamen de la DGII) |

Lecturas:
- Los avisos de **redondeo del ITBIS y de los totales** (11014, 1934, 11105) son casi todos los «Aceptado Condicional». Confirma que vale la pena hacer A-19 (un solo redondeo) y L-1 (ITBIS por tasa sobre la suma) antes del primer cliente.
- **1209** existe como causa de **rechazo de la DGII**. Es distinto del 400 de IQ «Esta secuencia ya ha sido utilizada con el estatus X», que es la protección de IQ contra duplicados y que no se guarda en estas tablas.

## 3. Reenvíos y consultas

- 1.095 documentos y 1.193 respuestas. 1.094 documentos tienen **una sola** respuesta.
- Las 99 filas restantes llevan el GUID vacío. Son las **respuestas de `ConsultECF`** que guarda el complemento cuando recibe el 400 «secuencia ya utilizada con el estatus Aceptado» (`DocumentSignService.cs:122` → `SearchDocuments` sin `GuidDoc`):
  - 90 «Aceptado» y 9 «Aceptado Condicional», nunca un «Rechazado»;
  - en 86 la consulta devuelve **`trackid: null`**: la consulta de IQ no siempre trae el TrackId de la DGII. Afecta a IQ-P1;
  - el complemento no puede asociar estas filas a su documento, porque guarda el GUID vacío. Es un defecto del complemento viejo, no de GPOS NG.
- **No hay ningún documento con «Rechazado» seguido de otra respuesta.** Un rechazo del complemento viejo no se reenvía. Encaja con la regla vigente: el rechazo anula automáticamente.

## 4. Efecto en GPOS NG (para el conector de B y el núcleo)

1. **Dictamen de la DGII:** se interpreta con `codigo` (1 Aceptado, 2 Rechazado, 3 En Proceso, 4 Aceptado Condicional) y se guarda `mensajes[]` con su código. **Aceptado Condicional es aceptado**: se emite, entra al 606/ERP y la alerta lleva el código.
2. **400 de IQ «secuencia ya utilizada con el estatus X»:** se extrae X del texto de `error` y se consulta `ConsultECF` (FC para E32; eCF para el resto) para traer el timbre. **Nunca es `CONFLICTO`.** El campo `estado` dentro del 400 no existe en la práctica (`EstadoEnError` de B no se activaría).
3. **`trackid` puede venir nulo en la consulta:** el contraste de ADR-74 no debe exigirlo; la evidencia es el código de seguridad más e-NCF, RNC, monto y fecha de firma.
4. **El cuestionario a IQ se reduce.** Quedan:
   - el 400 de validación (puntos 2, 3, 5 y 6 de P-02);
   - por qué la consulta trae `trackid` nulo (IQ-P1);
   - `CancelECF` (IQ-P3).
