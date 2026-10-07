---
name: bp2-nunca-en-produccion
description: "BP2 (GPOS VB6 nuevo) nunca salió a producción como POS: no hay clientes de BP2; la «identidad de BP2» no obliga a conservar costumbres operativas que nunca existieron"
metadata:
  node_type: memory
  type: project
  originSessionId: fa904a7c-caf5-4d97-b5b8-dcb33eed2e83
  modified: 2026-10-07T02:23:19.551Z
---

El propietario aclaró (2026-10-07): **BP2 nunca salió a producción; no existen clientes de BP2.** (Los complementos de e-CF sí están en producción con GPOS VB6, que es otra cosa.)

**Why:** varias preguntas («¿BP2 tenía conciliación bancaria / devolución a suplidor / fecha libre?») se plantearon para respetar la identidad de negocio de ADR-52; sin clientes reales, no hay costumbre que proteger.

**How to apply:** ante preguntas de identidad de BP2, no frenar el diseño: aplicar la recomendación del especialista (contable o POS) y lo firmado. La implantación es desde cero (J-3). Relacionado: [[contabilidad-ligera-erp-externo]].
