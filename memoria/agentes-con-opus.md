---
name: agentes-con-opus
description: "Modelo por agente (propietario, 2026-10-17): Opus para arquitectos de riesgo, auditor, contable y backend; Sonnet para el resto; Haiku para orquestador y Explore; ya no se fuerza Opus"
metadata:
  node_type: memory
  type: feedback
  originSessionId: ba9c53ea-5cf6-4307-bf2c-3f3a1f4b6f99
  modified: 2026-10-17T18:26:11.054Z
---

**2026-10-17, sustituye la regla del 2026-10-04** («todos los agentes con Opus 5.5, pasar `model: "opus"` siempre»). El propietario aprobó «tal cual» una asignación por tipo de trabajo porque el uso se consumía demasiado rápido.

| Modelo | Agentes |
|---|---|
| Opus 5.5 (`opus`) | arquitecto-maestro, arquitecto-datos, arquitecto-software, auditor-seguridad, especialista-contable, desarrollador-backend (por omisión) |
| Sonnet 5.5 (`sonnet`) | arquitecto-integraciones, especialista-pos, desarrollador-frontend, disenador-ux-ui, documentador-tecnico, qa-automatizado, devops |
| Haiku 5.5 (`haiku`) | orquestador; agentes Explore y búsquedas de solo lectura |

**Why:** ahorrar consumo sin perder calidad donde un error sale caro (decisiones de firma, esquema y bloqueos, seguridad, fiscal).

**How to apply:**
- Manda el `model:` de la definición del agente (`%USERPROFILE%\.claude\agents`, copia en `agentes/` del área común). **No** pasar `model: "opus"` por costumbre; cambiarlo en la llamada solo por un motivo concreto.
- desarrollador-backend se lanza con `model: "sonnet"` para lo mecánico: rebase, renombres, SQL idempotente ya diseñado, correcciones de una o dos líneas.
- **Escalar a Opus** cualquier agente cuando la tarea toque el orden de bloqueos, NCF o e-CF, costos o kárdex, aislamiento entre empresas, criptografía o licencia, o cuando un agente con Sonnet falle dos veces en lo mismo. Integraciones: Opus para diseñar el contrato de un tercero nuevo. QA: Opus para analizar concurrencia o carga.
- Fable 5.1 sigue reservado para la revisión general al cerrar las olas ([[fable-revision-general-tras-olas]]).
- Aviso publicado a A y C en el área común (`avisos/B-a-A/2026-10-17-modelos-por-agente.md`).

Relacionado: [[firma-humana-arquitecto-maestro]], [[limite-agentes-pc-b]].
