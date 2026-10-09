---
name: archivado-por-periodos-express
description: "Decisión del propietario (2026-10-08): la edición de SQL Server (Standard o Express) la elige el cliente; con Express, GPOS NG archiva por períodos que elige el cliente"
metadata:
  node_type: memory
  type: project
  originSessionId: befce104-4e9f-475e-b511-89ad28246638
  modified: 2026-10-08T15:05:14.024Z
---

El 2026-10-08, al revisar la capacidad de la central de Duty Free (tres tiendas con nodo y 10 años de retención), el propietario decidió:
- **La edición de SQL Server de la central la elige el cliente.**
- **Con Express, GPOS NG implementa un mecanismo de archivado por períodos, y los períodos los elige el cliente.**

**Why:** con la retención de 10 años (MD-61), una central en Express (10 GB) se llena entre el año 6 y el 20, según el volumen. El propietario no quiere imponer la licencia Standard (unos USD 7.800, inferido).

**How to apply:**
- Es una capacidad **general del producto**, no solo de Duty Free; es candidata a ADR o a precisión de ADR-54 ([[motor-sql-server-decidido]]).
- Archivar **no borra**: mueve los períodos cerrados a otra base que sigue siendo consultable, por la API de reportes y las vistas.
- Al diseñarlo hay que resolver:
  - los archivos fiscales presentados (ADR-111);
  - el respaldo de las bases de archivo (MD-54);
  - los nodos (retención local de 90 días);
  - no archivar períodos abiertos ni períodos de inventario sin cerrar (ADR-69).
- **Cuándo:** después del corte de la entrega 1 (propietario, 2026-10-08); A ya tiene el aviso `2026-10-08-archivado-por-periodos-express`.
- Registro: `docs/decisiones/2026-10-08-respuestas-propietario-duty-free.md`, rama `b/verticales-diseno` (`ced7cef`).
