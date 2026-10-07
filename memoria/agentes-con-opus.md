---
name: agentes-con-opus
description: "El propietario exige que los subagentes del proyecto se ejecuten con Opus 5.5 (model: opus), sin importar lo que diga la definición de cada agente"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 9bf422be-17fa-4dbe-9779-4afcf2205243
  modified: 2026-10-04T05:44:57.855Z
---

El 2026-10-04 el propietario interrumpió un lanzamiento y pidió: «quiero que los agentes utilicen Opus 5.5».

**Why:** quiere la máxima calidad de razonamiento en los agentes de arquitectura, desarrollo y revisión de GPOS NG; no acepta que un agente corra en un modelo menor por omisión de su definición.

**How to apply:** al invocar la herramienta Agent para cualquier agente del proyecto (arquitectos, desarrolladores, QA, DevOps, documentador, especialista POS), pasar siempre `model: "opus"` de forma explícita. Si se reanuda un agente ya lanzado, confirmar que su definición tiene `model: opus`; si no, lanzar uno nuevo con Opus en lugar de reanudarlo.

Relacionado: [[firma-humana-arquitecto-maestro]].
