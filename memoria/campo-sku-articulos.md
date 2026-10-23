---
name: campo-sku-articulos
description: "2026-10-22: el propietario pide un campo nuevo SKU en artículos y servicios, mismo alcance que Código, Código de barras y Referencia, y campo principal de búsqueda en todas las ventanas; sin ADR ni diseño aún"
metadata:
  node_type: memory
  type: project
  originSessionId: 8d3579bd-595e-4fdd-99fe-94d543735f58
---

El propietario pidió (chat del 2026-10-22) agregar un campo **SKU** a los artículos y servicios, con el mismo alcance que `Codigo`, `CodigoBarras` y `Referencia`, y como **campo principal por el que se busca en todas las ventanas** que usan un artículo o servicio. En el código de `feature/modelo-ng` no existe ningún campo SKU (solo `Codigo`, `Referencia`, `ReferenciaFabricante`, `ReferenciaSuplidor`, `CodigoBarras` y `ArticuloCodigo`); «SKU» aparece solo en los documentos del conector AdmCloud (código del ítem en AdmCloud).

**Why:** que se pueda buscar un artículo por su SKU en todas las pantallas.
**Decidido el 2026-10-22:** 7 decisiones de diseño y Q-SK-1 a Q-SK-5 aprobadas según mi recomendación (único con vacíos, opcional, fijo con movimientos, sin acentos y sin distinguir mayúsculas, exacta y luego parcial, importación y reportes sí; segundo en la búsqueda exacta, varchar(30) A-Z 0-9 - _ . /, no coincide con código ni alternos de otro, lleva al artículo). Observación: **el SKU de AdmCloud se puede unir con el SKU de GPOS** (se decide con el diseño del conector). ADR propuesto sin número en el PR #150; falta el número y su firma.

**How to apply:** es un cambio de arquitectura y de datos: necesita ADR (sin número: el rango de B está agotado), estimado y migración antes de construir; Conviene hacerlo junto con el cambio de contrato del listado de E-1 (ADR-93). Nada debe desplazar a DB-7. Relacionado: [[tarjetas-articulos-decisiones]], [[tecnologia-solo-con-consulta]].
