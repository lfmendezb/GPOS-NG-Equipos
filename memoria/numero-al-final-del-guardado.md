---
name: numero-al-final-del-guardado
description: "Principio del propietario (2026-10-09): un documento hace todo su trabajo y toma la secuencia/número como ÚLTIMO paso antes de guardar, nunca el primero"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 686e2e7b-d221-4745-a8a5-eeb40a6cf428
  modified: 2026-10-10T03:06:26.789Z
---

Principio del propietario (2026-10-09): «si hay trabajo previo antes de guardar un documento, dicho documento agotará todos los procesos que requiere y solo luego de confirmarlos tomará la secuencia que ha de asignar; es el último proceso que todos los documentos deben realizar, no el primero, porque el número se le presenta al operador luego del guardado».

**Why:** la carga T-57 mostró que las ventas hacen cola en `num.Serie [FacturaPos]` y las compras en `num.Serie [FacturaCxp]`, porque el número se toma al principio y el bloqueo se retiene mientras se recalculan costos y se hacen viajes cliente–servidor (venta p95 70-88 ms frente a 52; compra ~1 s frente a 400 ms).

**Firmado el 2026-10-09 «todo según recomendación»** (hoja `docs/decisiones/2026-10-09-hoja-firma-numero-al-final-y-mc.md` en `feature/modelo-ng`): D-1 a D-7 (número y NCF al final en un solo lote; nuevo orden de bloqueos con la numeración al final; precisiones de ADR-72, ADR-45, F-R1 y F-R5), M-C (foto mensual del costo apoyada en el cierre de ADR-69) y D-8 (recálculo de costo en segundo plano como segunda etapa, solo si tras M-C las compras retroactivas siguen pesando). Calendario: nada antes del MVP del 1-nov; fase 1 + M-C del 2 al 27-nov; medición 30-nov a 2-dic contra 52/400 ms; punto de control del propietario el 3-dic; fase 2 del 3 al 11-dic. Pendiente: registrar las precisiones en master.

**How to apply:** en todo diseño o revisión de documentos (ventas, compras, inventario, caja, notas), la serie y el NCF se toman al final de la transacción, en un paso corto. Hoy contradice el orden único de bloqueos firmado (series antes de NCF, `MovimientoCaja` y filas de artículos): el cambio requiere el estudio de riesgo (encargado al arquitecto de datos de B el 2026-10-09, `docs/datos/2026-10-09-estudio-numero-al-final.md` en `feature/modelo-ng`) y la firma del propietario antes de construir. Relacionado: [[mvp-fecha-medicion]].
