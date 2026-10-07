---
name: pruebas-proveedores-con-mock
description: "Pruebas: IQ Solution solo contra un mock local (nunca el endpoint real); AdmCloud contra la empresa de pruebas del propietario, con credenciales fuera del repo"
metadata:
  type: feedback
---

Regla del propietario (2026-10-07): **las pruebas de la integración con IQ Solution no pueden atacar el endpoint real de su API.** Se crea un **mock local** de la API de IQ (con el contrato deducido de `GSF.SyncToIQS`: login/token, firma, estados, TrackID, errores y duplicados) y todas las pruebas corren contra él.

**Why:** el endpoint real firma comprobantes fiscales y consume e-NCF reales; una prueba contra producción tendría efecto fiscal.

**How to apply:** ningún agente usa credenciales ni URL reales de IQ en pruebas, scripts o CI; el mock vive fuera del núcleo (ADR-73.7), junto al conector. Recomendado aplicar el mismo criterio a AdmCloud y Alegra salvo en un ambiente de certificación expresamente autorizado. Relacionado: [[ecf-conectores-enchufables]], [[contabilidad-ligera-erp-externo]].

**AdmCloud es distinto (propietario, 2026-10-07):** el propietario tiene acceso a una **empresa de pruebas en AdmCloud** que se puede usar para las pruebas de integración. Reglas: las credenciales de esa empresa las configura el propietario fuera del repositorio (secretos de usuario o almacén de credenciales de Windows), nunca en texto plano ni en el código; los agentes no las escriben ni las muestran; las pruebas contra AdmCloud real se marcan aparte (no corren en la suite normal) y **siempre se pregunta al propietario antes de lanzarlas** (cada vez, sin excepción). Pendiente de confirmar: si la firma de e-CF en esa empresa de pruebas tiene efecto ante la DGII. Alegra: mock local hasta nueva indicación.

**Excepción en AdmCloud (propietario, 2026-10-07):** la gran mayoría de las pruebas van contra la empresa de pruebas, **pero la facturación electrónica (firma y consulta de estado) se prueba con un mock local** de los endpoints `ElectronicSign` y `ElectronicCheckStatus`, construido a partir de las respuestas reales de muestra que dio el propietario: `C:\Users\lfmen\OneDrive\Escritorio\All\Add On GPOS\Facturación electronica - Firmado y Timbrado\ElectronicSign.JSON` y `ElectronicCheckStatus.json`. Forma de la respuesta: `{success, message, data:{Signed, SequenceUsed, Status, Identifier, NCF, SignedData[{Field:"ResponseJson", Value:<JSON DGII con Estado, TransaccionID, Mensajes, Valores: ValorCodigoSeguridad, ValorFechaHoraFirmaUtc, ValorAcuseRecibo, ValorConsultaTimbreUrl>}], ElectronicInvoicingGatewayType, Success, Code, Message, ErrorService}}`; la consulta trae `StatusData[{Field:"AuthorizationJson"...}]` con `SecuenciaUtilizada` y `ValorFechaHoraConsultaResultadoRecepcion`. Son datos del servidor de pruebas del proveedor de AdmCloud (ambiente TesteCF): se pueden copiar tal cual como datos de prueba, sin anonimizar (propietario, 2026-10-07).
