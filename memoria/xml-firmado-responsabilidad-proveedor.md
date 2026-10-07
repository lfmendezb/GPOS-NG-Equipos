---
name: xml-firmado-responsabilidad-proveedor
description: "2026-10-07: la custodia del XML firmado del e-CF es del proveedor homologado (IQ); GPOS guarda el JSON enviado por firma con huella SHA-256 canónica para auditoría"
metadata:
  node_type: memory
  type: project
  originSessionId: 6bc31041-05a1-4f8b-aeb1-1d4a864e8888
  modified: 2026-10-07T22:51:03.306Z
---

Posición del propietario (2026-10-07, C-03 de la hoja de ADR-108): garantizar el XML firmado por el tiempo que exija la DGII es responsabilidad del proveedor homologado (IQ); el conector solo usa su servicio. GPOS NG guarda el JSON enviado por cada firma, con su huella, para la auditoría. Firmado como DF-06 v4: IQ es garante por contrato y por norma (NG 10-2021); el emisor conserva su obligación legal (Ley 32-23, art. 13). La huella sola no prueba la no adulteración: va con el sello de integridad (ADR-74).

**Why:** el JSON y el registro no deben cambiar; la huella con el sello permite verificarlo.

**How to apply:** el conector guarda la evidencia (JSON enviado, respuesta, timbre, referencia del XML) 10 años; la copia del XML es opcional; el piloto y la producción exigen la constancia escrita de IQ. Relacionado: [[ecf-conectores-enchufables]], [[pruebas-proveedores-con-mock]].
