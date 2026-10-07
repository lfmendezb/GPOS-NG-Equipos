---
name: firma-humana-arquitecto-maestro
description: El agente Arquitecto Maestro solo prepara decisiones; el usuario es quien las firma o las corrige.
metadata:
  node_type: memory
  pinned: true
  originSessionId: f996b5de-a7ff-414c-a94d-a243315ed78c
  modified: 2026-09-29T00:01:01.602Z
---

En el ecosistema de agentes del usuario (arquitecto-maestro, orquestador, arquitectos, desarrolladores, QA, auditor, DevOps, documentador), el agente **arquitecto-maestro prepara la decisión** y el usuario (Leonardo Méndez) es quien **la firma como válida o la corrige**. Ningún agente, ni la sesión principal, aprueba en su nombre.

Cómo aplicarlo: cuando un agente de control (Maestro, Orquestador, QA, Auditor, DevOps) emita un veredicto, preséntalo al usuario como una recomendación pendiente de firma. No avances de fase, no des nada por aprobado y no registres un ADR como "Aceptado" hasta que el usuario lo firme en el chat.

El usuario quiere usar estos agentes en todos sus proyectos, según la tarea. Por eso las reglas propias de un proyecto (convenciones de nombres, stack, modelo de tenencia) deben vivir en el CLAUDE.md de ese proyecto y no dentro de las definiciones de los agentes.
