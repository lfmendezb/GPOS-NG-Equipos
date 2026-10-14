---
name: marcas-migraciones-orden-de-union
description: Regla de B (2026-10-14) — las marcas de las migraciones EF siguen el orden de unión a feature/modelo-ng; la rama que llega después las regenera
metadata:
  type: project
---

Regla fijada por B como coordinador el 2026-10-14, al unir #29, #30, #25 y #27 (`e59d8de`): **las marcas de tiempo de las migraciones de EF de la base de empresa siguen el orden de unión a `feature/modelo-ng`**. La rama que se une después de otra con migraciones regenera las suyas con una marca posterior a la última ya unida, y regenera también el snapshot y el guion acumulado único `database/empresa/gpos-empresa-<última>.sql` (`migrations script --idempotent`). Todas las ramas chocan en rename/rename con ese guion: se resuelve regenerándolo.

**Why:** las marcas de A (H-2, H-11), de C (C-10) y de B (T1 `153018`, ola5 `171353`, 3b `183053`) son todas del 10-oct y se intercalan. Sin regenerarlas, las bases ya creadas (el DEMO) aplicarían migraciones fuera de orden.

**How to apply:**
- Al unir, revisar las marcas nuevas contra la última unida y regenerar si hace falta.
- Ramas de B pendientes: T1 de ADR-118/119 (27-oct) → `b/ola3b` → `b/ola5-auditoria`. Las tres se regeneran al unirse; en `ola5-auditoria`, además, `SecExportacion` va en `Todas` y el DENY ALTER ANY USER pasa a tener un solo dueño, RG-14.
- Orden de A y C al 2026-10-14: #24 → #26 (rebase) → #21 (rebase) → #28 (después de #24, por el GRANT y el DENY de BACKUP).
- Suite oficial: siempre con el filtro de [[filtro-suite-oficial]].
