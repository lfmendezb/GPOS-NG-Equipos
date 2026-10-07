---
name: mcp-modelos-ia-pendiente
description: "Pendiente del propietario (2026-10-04): crear un servidor MCP para que GPOS NG trabaje con modelos de IA, en la etapa del plan donde sea prudente"
metadata:
  node_type: memory
  type: project
  originSessionId: 1cee00aa-ab02-439f-846e-6899ce03c1d6
  modified: 2026-10-04T19:51:00.159Z
---

El 2026-10-04 el propietario pidió anotar, para la etapa en que sea prudente lanzarla, la creación de un **MCP (Model Context Protocol) para trabajar con modelos de IA** desde GPOS NG.

**Why:** quiere que GPOS NG pueda exponer sus datos y operaciones a modelos de IA de forma controlada.

**How to apply:**
- No construir todavía. Llevarlo al arquitecto-maestro para que proponga en qué etapa entra (candidato natural: después del corte de la entrega 1, cuando el esquema `rpt` y los contratos estén estables; nunca antes del modelo nuevo, para no atarlo al esquema de BP2).
- Al diseñarlo: pasar por arquitecto-software (contratos y herramientas del MCP sobre la API, no sobre la base), auditor-seguridad (permisos por usuario y empresa, ADR-32 datos sensibles, ADR-36 validación en cada petición, solo lectura por omisión, bitácora) y arquitecto-integraciones (proveedores de modelos).
- Recordárselo al propietario al cerrar la entrega 1 o al planificar la siguiente fase.

Relacionado: [[decision-modelo-datos-propio-pendiente]].
