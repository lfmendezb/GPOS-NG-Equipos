```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: GPOS-NG-AddOn-IQS b/conector-iq-instalador (95c4271; MSI construido en 3c7344b)
Estado: Abierto
```

# Conector IQ 0.4.2: H-1, dictamen por `codigo` y duplicado con contraste; códigos nuevos para el despachador (T-29c)

**Estado:** MSI 0.4.2 sin firma; 561 de 561 pruebas en dos corridas seguidas. Sigue la prueba elevada del propietario.

## Cambios
- **H-1:** un 400 de validación pasa directo a `CONFLICTO` (`ECF-IQ-0400`), sin consultar ni reenviar.
  - Defensa para los diarios que vienen de 0.4.1: el primer «no encontrado» después de un 400 también lleva a `CONFLICTO`.
- **Dictamen por `codigo`** (1, 2, 3 o 4; llega como número o como texto), con el texto de `estado` solo como comprobación.
  - Si código y texto no coinciden, manda el código y queda una alerta.
  - Aceptado Condicional cuenta como aceptado, con una alerta que lleva los códigos de `mensajes[]`.
- **Rechazo en una respuesta 200 (código 2):** queda `FINAL` `RECHAZADO`, con `accionRechazo` (P-04-a).
- **400 «Esta secuencia ya ha sido utilizada con el estatus X.»:**
  1. Se extrae X y se compara con una tabla cerrada (H-5).
  2. Si X está en la tabla, la operación pasa a `VERIFICANDO` y se consulta `ConsultECF` (ruta FC para E32, eCF para el resto).
  3. **Antes de adoptar el estado se contrasta (H-6)** con cinco datos: código de seguridad, RNC del emisor, monto total, fecha de emisión y RNC del comprador.
  4. Si el contraste coincide, se adopta el estado (P-04-b, o P-04-a si es Rechazado).
- **`trackid` nulo:** se admite.
- **K18-a:** ya no se ofrece anular a mano.
- **H-3:** un segundo «Reenviar corregido» responde 409 `ENCF_REGISTRADO_EN_PROVEEDOR`.
- **Retirado:** `ECF-IQ-0012` (`EstadoEnError`).

## Códigos nuevos para el despachador del núcleo
| Código | Significado |
|---|---|
| `ECF-IQ-0032` | IQ dice «ya utilizada», pero dos consultas no la encuentran → `CONFLICTO`, sin reenvío |
| `ECF-IQ-0034` | El estatus X falta o no está en la tabla → `CONFLICTO`, sin consultar |
| `ECF-IQ-0035` | El contraste no coincide (puede ser un choque de numeración) → `CONFLICTO`, sin adoptar ni anular |
| 409 `ENCF_REGISTRADO_EN_PROVEEDOR` | Un segundo «Reenviar corregido» después de `ECF-IQ-0033` |

**Desviación respecto del aviso de A** («nunca `CONFLICTO`» en la ruta del duplicado): `0032` y `0035` llevan a `CONFLICTO`. Es la salida segura: reenviar volvería a dar el 400, una y otra vez, y adoptar sin contraste podría tomar el estado de otro documento. **Por favor, confirmen.**

## Pendiente para la entrega siguiente
- **H-2:** el timbre y el seguimiento con `ECF-IQ-0033`.
- **El resto de H-6:** contrastar también al adoptar después de un 5xx o de un tiempo agotado, y comparar `jsondata` con `H_j`.
- **La operación `GET …/contraste`,** que el núcleo necesita para P-04-b (H-4).

**Candidatas a precisión de ADR-108:**
- el dictamen por `codigo`, con el texto como comprobación;
- adoptar el duplicado solo tras el contraste.
