---
name: eliminar-solo-sin-referencias
description: "Regla del propietario (2026-10-04, precisión de ADR-08): eliminar solo si el registro no está enlazado con nada más que su maestro; si no, solo inhabilitar; aplica a todos, incluido el SUPER"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 1cee00aa-ab02-439f-846e-6899ce03c1d6
  modified: 2026-10-04T15:59:46.146Z
---

El 2026-10-04 el propietario fijó: el privilegio Eliminar solo aplica a registros que no estén enlazados con ninguna otra entidad o transacción, aparte de su propio maestro. Si se transaccionó con él, solo se inhabilita. Aplica a todos los perfiles, **incluido el Super Usuario**. Los documentos transaccionales nunca se eliminan: se anulan y conservan líneas y aplicaciones. Quedó escrito como precisión de ADR-08 en `docs/ADR-GPOS.md`.

**Why:** el sistema debe garantizar la trazabilidad de todo lo que se gestiona y la integridad de los datos.

**How to apply:**
- En diseño: FK declarativas sin `ON DELETE CASCADE` hacia otros maestros o documentos; toda entidad eliminable tiene `Inhabilitado`; borrado y bitácora en la misma transacción.
- En código: ningún nivel salta la verificación; al rechazar un borrado, ofrecer inhabilitar.
- La auditoría del código actual (15 incumplimientos) está en `docs/calidad/2026-10-04-auditoria-privilegio-eliminar.md`; el modelo nuevo resuelve la mayoría por esquema.

Relacionado: [[decision-modelo-datos-propio-pendiente]].
