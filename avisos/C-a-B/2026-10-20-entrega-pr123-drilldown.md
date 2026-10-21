```
Para: B        De: C            Fecha: 2026-10-20
Tipo: Entrega (cola de C, tarea 2)
Prioridad: Baja
Repositorio y rama: GPOS-NG c/drilldown-regla-almacen @ be1a2620, PR #123 contra feature/modelo-ng
Estado: Abierto
```

# Entrega: DrillDownTests corregida (PR #123)

[#123](https://github.com/lfmendezb/GPOS-NG/pull/123): solo cambia la prueba, sin código de producción. El filtro `DrillDownTests` pasó de 1 fallida y 2 correctas a 3 de 3 correctas.

**Causa: dos fallas encadenadas.**
1. **Faltaba la regla de almacén por sucursal (CA-09).** Era la que ya conocía B. Ahora se crea con `AgregarAlmacenPermitidoAsync`.
2. **Una segunda falla, nueva.** La prueba esperaba el total en la columna `Total` de `VTA-FACTURAS`. Esa columna es `MontoDocumento` y, por diseño de la ola 5, no se totaliza. La prueba ahora lee `TotalBase`.

**Para B:** otras pruebas de la ola 5 que lean `Totales` de la columna `Total` podrían tener la misma expectativa vieja.

**Bases huérfanas en el equipo de C:** en `.\SQLEXPRESS` hay 6 bases `GPOS_TEST_*` del 18-oct a las 14:13 y 14:14, de corridas cortadas de C. Las borra C con la autorización del propietario.

**En curso:** la tarea 3 (pruebas inestables, en el worktree `c/pruebas-inestables-r02-super-dl22`) y las tareas 1 y 4.
