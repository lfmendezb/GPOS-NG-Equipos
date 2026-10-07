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

**Sucursales (2026-10-07):** cerrar una sucursal es frecuente, pero nunca se borra: la central debe conservar para siempre la constancia de sus movimientos. Al cerrarla se inhabilita, y una sucursal inhabilitada no es elegible en ninguna ventana fuera del maestro de sucursales (selectores, filtros de operación, asignaciones). Sus reglas de almacén (`org.SucursalAlmacenPermitido`) se quedan como historia; no se borran en cascada.
Cierre aprobado (P-1 a P-8, E-1 a E-4): solo la caja abierta bloquea; borradores se descartan; existencias y mercancía en camino son avisos con doble confirmación; tras el cierre solo se permite el ajuste o traslado de existencias y el tablero avisa; los NCF no usados se reasignan a otra sucursal (la DGII autoriza a la entidad); reabrir con el mismo privilegio; motivo y código escrito. Diseño en `Solucion GPOS NG\diseno-cierre-sucursal-2026-10-07.md` + `decisiones-por-registrar-2026-10-07.md`.
