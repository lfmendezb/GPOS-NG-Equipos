---
name: documentacion-estricta-estado-de-firmas
description: "El propietario exige documentación estricta: ningún texto debe dar por pendiente lo ya firmado; al firmar, barrer todas las referencias"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 6965fb50-50eb-4ff7-a665-f0391bbc4853
  modified: 2026-10-20T22:45:05.637Z
---

El 2026-10-20 el propietario pidió que la documentación sea más estricta para evitar falsas inferencias sobre puntos pendientes. Caso que lo originó: ADR-62 (precisión del 2026-10-14, punto 5) seguía diciendo que DL-10 a DL-13 «siguen sin firmar» cuando ya estaban firmadas (14 y 15 de octubre), y yo lo repetí al propietario como pendiente.

**Why:** un texto de ADR que describe un estado mutable («sin firmar», «pendiente») envejece en silencio y lleva a decisiones y avisos equivocados.

**How to apply:**
- Antes de afirmar que algo está pendiente o sin firmar, verificar contra la fuente más reciente (hoja de firma vigente, `docs/adr/estado.json`, registro de novedades), no contra un ADR histórico; citar la fuente y la fecha.
- Al registrar una firma, hacer el barrido: buscar con Grep los identificadores firmados (DL-nn, PT-nn, A-n…) en `docs/` y marcar o corregir cada referencia que los dé por pendientes («vigente al AAAA-MM-DD» o «historia»).
- Todo estado mutable que se escriba en prosa lleva fecha y remite a la fuente viva.
- Propuesta en curso: regla de barrido en la guía de PR y una guarda de prueba; requiere ADR firmado por el propietario. Ver [[gobernanza-adr-ga01-ga08]].
