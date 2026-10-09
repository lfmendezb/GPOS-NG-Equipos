---
name: referencias-api-erp
description: "Documentación de las API (AdmCloud, Alegra, IQ Solution) y formato oficial e-CF de la DGII, al que se subordinan los JSON"
metadata:
  node_type: memory
  type: reference
  originSessionId: 04973234-ae57-4e21-9499-3cc3a1aeef9e
  modified: 2026-10-09T02:25:38.480Z
---

- **AdmCloud:** https://api.admcloud.net/scalar/#description/introduction (Swagger público; integración a fondo y e-CF; complemento actual `C:\Users\lfmen\source\repos\IGpostAC`).
- **IQ Solution (e-CF):** https://ecf.iqsoft.do/ecf-api-doc (dada por el propietario el 2026-10-07; la página se arma con JavaScript: leerla con el navegador integrado, no con una simple descarga). Corrige el supuesto anterior de «IQ sin documentación pública».
- **Formato oficial e-CF de la DGII (v1.0, octubre de 2025):** https://dgii.gov.do/cicloContribuyente/facturacion/comprobantesFiscalesElectronicosE-CF/Documentacin%20sobre%20eCF/Formatos%20XML/Formato%20Comprobante%20Fiscal%20Electr%C3%B3nico%20(e-CF)%20v1.0.pdf — **la estructura de los JSON que se envían a IQ (y el comprobante canónico de GPOS NG) está subordinada a este formato** (propietario, 2026-10-07): mismos nombres de campo, áreas, longitudes, tipos y valores (p. ej. `CodigoModificacion` 1 a 5).
- **Polaris EDI (e-CF, firmado directo como IQ; informado por el propietario el 2026-10-08):** https://docs.polarisedi.com/ (inicio rápido: https://docs.polarisedi.com/docs/inicio-r%C3%A1pido). Ambiente 0 de desarrollo sin empresa ni certificado; flujo: token de acceso → `.../Firmar` → `ConsultarResultado` si queda «En espera». El access token viaja en la query (`?token=`): el conector debe evitar que quede en bitácoras. El token genérico de desarrollo no se copia al repositorio.
- **Alegra:** https://developer.alegra.com/ (dada por el propietario el 2026-10-07 para el conector ERP).

Consultarlas sin credenciales. Relacionado: [[contabilidad-ligera-erp-externo]], [[ecf-conectores-enchufables]].
