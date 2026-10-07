---
name: estrategia-acceso-datos-preferida
description: "Esquema de acceso a datos que prefiere el propietario por rendimiento: EF Core para DbContext y migraciones, Dapper para la mayoría de las consultas, ADO.NET puro para lo crítico"
metadata:
  node_type: memory
  type: user
  originSessionId: 2d7f126f-da10-49d8-816e-0263756730c0
  modified: 2026-10-03T08:23:22.868Z
---

El propietario fijó el 2026-10-03 su esquema preferido de acceso a datos, por rendimiento:
- **EF Core** para manejar los DbContext y controlar las migraciones;
- **Dapper** para la mayoría de las consultas;
- **ADO.NET puro** para migraciones y para transacciones de mayor impacto en el rendimiento.

**Why:** lo pidió al ver que GPOS NG usa EF Core como medio principal de consulta, a raíz de que la prueba CP141 (Z con muchos pendientes) vence su tiempo de espera en SQL Server 2025.

**How to apply:**
- En proyectos nuevos, proponga este esquema por omisión.
- **En GPOS NG, el propietario desestimó el cambio general (2026-10-03).** Dos de las tres piezas ya se aplican: el esquema con ADO.NET puro y la numeración, los NCF y los bloqueos con ADO.NET sobre la transacción de EF. Son las que de verdad afectan el rendimiento. EF Core sigue como acceso por omisión y ADR-07 no cambia.
- El análisis está en `docs/decisiones/2026-10-03-decision-estrategia-acceso-datos.md`. Cualquier ajuste puntual se evalúa con el diagnóstico de CP141 del arquitecto-datos.

Relacionado: [[politica-actualizacion-paquetes]], [[firma-humana-arquitecto-maestro]].
