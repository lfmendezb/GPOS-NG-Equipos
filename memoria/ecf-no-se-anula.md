---
name: ecf-no-se-anula
description: Regla del propietario 2026-10-08: documento con e-NCF no se anula (se reversa con documento fiscal); solo el rechazo de la DGII anula automáticamente; 607/608 sin e-NCF, solo 606
metadata:
  type: project
---

Con el módulo de facturación electrónica activo, **Anular queda inhabilitado**: ningún documento con e-NCF/e-CF se anula; se emite el documento fiscal que reversa la operación (p. ej. E34). **Única excepción:** respuesta «Rechazado por la DGII» al firmar → anulación automática. **607 y 608 no informan e-NCF**; de momento solo se usa el 606 para ellos.

**Why:** regla fiscal del propietario (2026-10-08) para el e-CF dominicano.

**How to apply:** ningún diseño propone «anular a mano» un e-CF (un `CONFLICTO` sale por reenvío corregido o por dictamen de la DGII); las vistas 607/608 excluyen serie E. Relacionado: [[devoluciones-son-notas-de-credito]], [[ecf-conectores-enchufables]], [[xml-firmado-responsabilidad-proveedor]].
