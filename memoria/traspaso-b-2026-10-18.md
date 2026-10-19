---
name: traspaso-b-2026-10-18
description: LEER PRIMERO al abrir sesión de B: estado del 2026-10-18 (tarde); punta 322b21d6; D0 de DB-7 firmado; qué sigue
metadata:
  type: project
---

Estado de B el 2026-10-18 (tarde). Detalle en `estado.md` del área común (sección B) y en sus avisos del día.

- **`feature/modelo-ng` = `fd4f79bd`**: toda la cola unida (#52 a #84). Última marca de migración: `20261018181156`. Medición del #61 y el #71: cumplen (informe `traspasos/B/2026-10-18-medicion-61-71.md`).
- **`master`**: firmas del día registradas (DB-7, RSV con ADR-79, D0); `CLAUDE.md` recortado (historial en `docs/adr/estado-de-construccion.md`).
- **PAUSA hasta el miércoles 21 de octubre (propietario):** cuota de uso al límite; A y C sin tareas nuevas. B gestiona todo con el mínimo de sesiones y sin vigilantes.
- **Pendiente para el miércoles:** registrar el ADR de Linux con PL-10 (a) **con el número ADR-129** (asignado por el propietario el 2026-10-18; el rango de C sigue congelado; el 127 y el 128 quedan para los dos ADR de catering) y proponer el equipo de LN (PL-03); LC-03 a LC-05 del #79 y S04, S05 y S07 del #81; D1 de DB-7 desde el 2-nov (lo construye B).
- **NuGet:** con paquetes nuevos hay que restaurar con `dotnet restore GPOS-NG.slnx --source https://api.nuget.org/v3/index.json` y compilar con `--no-restore` (el origen local de la configuración no existe).

**Why:** la sesión del 18-oct hizo mucho; sin esta nota, la siguiente repetiría o perdería trabajo.
**How to apply:** leer esto, `estado.md` (B) y los avisos posteriores a `322b21d6`; trabajar con Sonnet 5.5 y esfuerzo medio, y sugerir Opus 5.5 para las uniones con conflicto y el análisis de la medición ([[sesiones-sonnet-medio-escalar-opus]]).

**PAUSA hasta el miércoles 21 de octubre de 2026 (propietario, 2026-10-18):** la cuota de uso está al límite. No se asignan tareas nuevas a A ni a C; terminan lo asignado y esperan. En B, sin vigilantes de sesión; la medición del #61 y el #71 corre sola (`Medicion-61-71.ps1`, resultados en `GPOS-B-prep27\TestResults\M61-71-*`). El miércoles: comparar cifras, unir #61 y #71 (conflicto con SC08 ya resuelto en `b/medir-cand`), #75, #76, #77, #78, #79 y #80, registrar el ADR de Linux (PL-10 (a)) y D1 de DB-7 desde el 2-nov.

**Plan si N6-02 (ruta B) sigue sobre 1,05 tras la repetición (propietario de acuerdo, 2026-10-18):** medir el #61 y el #71 por separado; si el costo es del #61, hacer la opción 1: traer el modo del e-CF dentro de una consulta que ya corre antes de la transacción (p. ej. `TiposAsync` en `PosService.ComprobanteAsync`), sin caché y sin mover la lectura al final (alargaría el bloqueo de la serie). Informe en `traspasos/B/2026-10-18-medicion-61-71.md`.
