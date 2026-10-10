---
name: numero-al-final-del-guardado
description: "Principio del propietario (2026-10-09): un documento hace todo su trabajo y toma la secuencia/número como ÚLTIMO paso antes de guardar, nunca el primero"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 686e2e7b-d221-4745-a8a5-eeb40a6cf428
  modified: 2026-10-10T02:30:26.616Z
---

Principio del propietario (2026-10-09): «si hay trabajo previo antes de guardar un documento, dicho documento agotará todos los procesos que requiere y solo luego de confirmarlos tomará la secuencia que ha de asignar; es el último proceso que todos los documentos deben realizar, no el primero, porque el número se le presenta al operador luego del guardado».

**Why:** la carga T-57 mostró que las ventas hacen cola en `num.Serie [FacturaPos]` y las compras en `num.Serie [FacturaCxp]`, porque el número se toma al principio y el bloqueo se retiene mientras se recalculan costos y se hacen viajes cliente–servidor (venta p95 70-88 ms frente a 52; compra ~1 s frente a 400 ms).

**How to apply:** en todo diseño o revisión de documentos (ventas, compras, inventario, caja, notas), la serie y el NCF se toman al final de la transacción, en un paso corto. Hoy contradice el orden único de bloqueos firmado (series antes de NCF, `MovimientoCaja` y filas de artículos): el cambio requiere el estudio de riesgo (encargado al arquitecto de datos de B el 2026-10-09, `docs/datos/2026-10-09-estudio-numero-al-final.md` en `feature/modelo-ng`) y la firma del propietario antes de construir. Relacionado: [[mvp-fecha-medicion]].
