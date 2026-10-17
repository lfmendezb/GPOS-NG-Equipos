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
- Estado al 2026-10-15: unidos a feature/modelo-ng (30b4d5b3) H11 20261014204007, C-10 20261014205000, Rg14 20261014210613 y Rg14RespaldoTope 20261015003000 (la última). Pendientes de B en b/prep-27oct: NegativosTresNiveles 20261015010000 y Ola3bTransferencias 20261015020000 (ya posteriores; prep rehecha sobre 7898beeb = 855ea392 el 15-oct) y Uf05ForceSeek 20261015142020 (A-N2, 799a5add), la última de prep; b/ola5-auditoria-r (6e472dcb) agrega Ola5AuditExportacion 20261015211406, sin P-B hasta la corrección del 12834 de A. Al unir, alinear el Designer de la última migración con el snapshot (INCLUDE de UQ_CxpAplicacion de C-10) y regenerar un solo guion con dotnet ef.
- Suite oficial: siempre con el filtro de [[filtro-suite-oficial]].
