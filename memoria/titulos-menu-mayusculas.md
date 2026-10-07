---
name: titulos-menu-mayusculas
description: "RG-30: se mantiene «Gestión de Secuencias» con mayúsculas de título; todos los títulos del menú deben seguir ese mismo principio (siguiente fase)"
metadata:
  node_type: memory
  type: project
  originSessionId: 2d7f126f-da10-49d8-816e-0263756730c0
  modified: 2026-10-03T15:41:22.568Z
---

Decisión del propietario del 2026-10-03 sobre RG-30 de la revisión general con Fable:

- Se **mantiene "Gestión de Secuencias"** tal cual, con mayúsculas de título. Se descarta la propuesta de Fable de pasarlo a minúscula de frase.
- **Todos los títulos del menú** (`NavMenu.razor` en Web y MAUI) se revisan para que sigan ese **mismo principio** de mayúsculas de título.

**Why:** el propietario prefiere unificar el menú con el estilo del nombre que eligió en PC-4 C-6, y no cambiar ese nombre.

**How to apply:**
- La revisión del menú va en la **siguiente fase**, no antes de la unión a master ni en el bloque "antes de publicar".
- Hágala en las dos copias, Web y MAUI (ADR-04).
- Lo de "Secuencias NCF" frente a "Gestión de Secuencias" (la posible confusión que señaló Fable) queda cubierto por esta misma revisión.

Relacionado: [[cierre-numeracion-nuevo-equipo]].
