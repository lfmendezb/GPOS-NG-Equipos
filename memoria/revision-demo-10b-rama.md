---
name: revision-demo-10b-rama
description: "Correcciones de la revisión del DEMO 2026-10-10b en la rama b/demo-revision-1 (worktree GPOS-B-demo-rev1), sin unir ni subir"
metadata:
  node_type: memory
  type: project
  originSessionId: c4ab64f7-cdf4-45ed-9334-901ddbd4a4af
  modified: 2026-10-11T00:24:05.556Z
---

Las correcciones de la revisión del DEMO 2026-10-10b que hizo el propietario (documento de OneDrive «Mejoras y Correcciones») van en la rama `b/demo-revision-1`, creada desde `feature/modelo-ng` (4d376a6) en el worktree `../GPOS-B-demo-rev1`. Commit aca9b04 (2026-10-10), con los puntos 1 a 3: Guardar junto a «Nuevo usuario», calendarios recortados por el `Style` de MudBlazor 9 y alineación de Consultar en el Cierre de Caja.

**Why:** el propietario aprobó el resultado («perfecto»), pero no pidió unirla. Queda pendiente de juntarla con los demás puntos que salgan de la revisión.

**How to apply:** agregar los nuevos puntos de la revisión del DEMO a esta misma rama. Unirla a `feature/modelo-ng` solo cuando el propietario lo pida. En MudBlazor 9, nunca limitar el ancho de un `MudDatePicker` con `Style`: usar un contenedor. Ver [[pendientes-prueba-demo]].
