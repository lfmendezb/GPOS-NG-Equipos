---
name: dos-equipos-a-coordina
description: "2026-10-06: trabajo en dos PC; la PC A (equipo actual) coordina todo e integra; la PC B es el equipo anterior al 2026-10-02; la PC B toma ola 3b/ola 4 en diseño, Backup Tool y Fable; ADR en master, un archivo por ADR, rangos A 68-99 y B 100-129"
metadata:
  node_type: memory
  type: project
  originSessionId: f2c0a692-b405-4953-8a6f-70fec2b01360
  modified: 2026-10-06T06:54:35.876Z
---

El 2026-10-06 el propietario aprobó trabajar con dos equipos. **La PC A (este equipo) es la que coordina todo**: cierra la ola 3, une ramas a `feature/modelo-ng` y `master`, edita `CLAUDE.md` y el manifiesto de pruebas. La PC B es el equipo anterior al cambio del 2026-10-02 (ya tiene SQL Server, Visual Studio, agentes y una copia vieja que no se usa); trabaja en ramas `b/...`, sube y abre PR, nunca une.

**ADR (aprobado 2026-10-06):** se registran solo en `master`, un archivo por ADR (`docs/adr/ADR-NNN.md`) más índice; cada PC trae `master` a su rama. Rangos: A del 68 al 99, B del 100 al 129. Partir `docs/ADR-GPOS.md` lo hace el documentador en A cuando no haya agentes editando.

**Why:** avanzar más rápido sin que dos editores pisen los mismos archivos ni repitan números de ADR; `feature/modelo-ng` ya se había desfasado de `master` (ADR-54 frente a ADR-67).

**How to apply:** plan en `C:\Users\lfmen\source\repos\Solucion GPOS NG\plan-dos-equipos.md`; paquete y nota para B en `paquete-pc-b\`. Lo que B aprenda llega por `traspaso-B-*.md` y A lo pasa a la memoria. Relacionado: [[un-solo-editor-por-repositorio]], [[agentes-con-opus]], [[cierre-numeracion-nuevo-equipo]].

**Área común (2026-10-07):** la coordinación entre equipos va por el repositorio privado **`lfmendezb/GPOS-NG-Equipos`** (clon local `C:\Users\lfmen\source\repos\GPOS-NG-Equipos`): `estado.md` (cada equipo su sección), `avisos/A-a-B` y `avisos/B-a-A` (cada equipo solo la suya), `traspasos/A|B`, `memoria/` y `agentes/` (solo A publica), scripts `herramientas\Actualizar-Desde-AreaComun.ps1` y `Publicar-En-AreaComun.ps1`. **El propietario decide cuándo** cada equipo actualiza o publica. Commits con prefijo `[A]`/`[B]`; nunca secretos; un aviso no es una decisión. Al publicar como A, actualizar antes la sección de A en `estado.md`.
