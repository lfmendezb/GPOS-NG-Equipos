---
name: contabilidad-ligera-erp-externo
description: "2026-10-07: GPOS NG lleva solo una contabilidad ligera de auxiliar; el mayor, asientos y estados financieros son del ERP del cliente (AdmCloud, Alegra u otro)"
metadata:
  node_type: memory
  type: feedback
  originSessionId: fa904a7c-caf5-4d97-b5b8-dcb33eed2e83
  modified: 2026-10-07T01:19:31.212Z
---

El propietario (2026-10-07), tras leer el análisis del especialista-contable: se acogen sus recomendaciones **con una salvedad**: GPOS NG **no es un sistema administrativo contable**. Lleva una **estructura de contabilidad ligera** (auxiliares de ventas, CxC, CxP, caja, bancos e inventario, y lo fiscal que exige la DGII por emitir comprobantes: 606, 607, 608, ITBIS, retenciones, e-CF) y **delega la contabilidad «pura y dura»** (libro mayor, catálogo de cuentas, asientos, estados financieros, cierres contables) a un sistema administrativo contable de terceros: **AdmCloud, Alegra o cualquier otro ERP**.

**Why:** mantener a GPOS NG enfocado en la operación y el cumplimiento fiscal del punto de venta, sin convertirse en un ERP.

**How to apply:** al evaluar recomendaciones contables, separar lo que es del auxiliar o fiscal (se hace en GPOS NG) de lo que es del mayor (se entrega al ERP mediante conectores enchufables, como el de e-CF). No proponer libro mayor, asientos ni estados financieros dentro de GPOS NG. Relacionado: [[devoluciones-son-notas-de-credito]], [[ecf-conectores-enchufables]].

**ADR-73 firmado (B-1 a B-5, 2026-10-07).** Precisión de PA-05: GPOS NG genera 606/607/608 con lo que tiene registrado; el cliente tiene derecho a generarlos en su ERP si lo prefiere.
