---
name: motor-sql-server-decidido
description: El propietario decidió el 2026-10-04 mantener SQL Server como motor de GPOS NG tras evaluar PostgreSQL 18 por costo; se reabre solo con cartera de 3+ clientes grandes
metadata:
  node_type: memory
  type: project
  originSessionId: 9bf422be-17fa-4dbe-9779-4afcf2205243
  modified: 2026-10-04T04:12:05.953Z
---

El 2026-10-04 el propietario pidió evaluar el cambio de motor a PostgreSQL 18+ «por un tema de economía», con la advertencia «si no conviene mantengo SQL Server». Los arquitectos de datos y de software recomendaron mantener SQL Server (ahorro cero en clientes pequeños con Express; solo la licencia Standard de la central en clientes grandes, que paga el cliente final; costo del cambio de 7 a 16 semanas-persona). **El propietario decidió: se mantiene SQL Server.**

**Why:** el ahorro de licencias no compensa el costo de reescritura, pericia y riesgo operativo mientras no haya cartera de clientes grandes.

**How to apply:**
- No proponer PostgreSQL ni diseño neutral a dos motores en GPOS NG.
- Sí aplicar las prácticas sin costo que dejan abierta la puerta: códigos en mayúsculas, listas como parámetros de tabla, sin pistas del optimizador fuera de casos documentados, SQL a mano concentrado en pocos archivos.
- Umbral para reabrir la evaluación (Parte E de la propuesta de datos): cartera de 3 o más clientes grandes con central Standard, o 4 o más instancias en la nube; entonces prueba comparativa de ~2 semanas-persona.
- Evaluaciones: Parte E de `docs/propuestas/2026-10-03-modelo-datos-ng-propuesta.md`, sección 11 de `...-impacto-aplicacion.md`, y `docs/operaciones/2026-10-03-evaluacion-motor-postgresql.md` (DevOps).

Relacionado: [[decision-modelo-datos-propio-pendiente]], [[respuestas-propietario-modelo-datos]].

**Edición y archivado (propietario, 2026-10-08, vía B):** la edición de la central (Standard o Express) la elige el cliente. Con Express, GPOS NG tendrá **archivado por períodos que elige el cliente** para no llegar a 10 GB. **Después del corte de la entrega 1**. Archivar no borra (retención de 10 años, MD-61): los períodos cerrados van a otra base que se sigue consultando. Candidata a ADR o precisión de ADR-54, a cargo de A. Hasta entonces, no cerrarle el paso: vistas y reportes con el período como filtro.
