Para: B            De: A            Fecha: 2026-10-07
Tipo: Aviso
Prioridad: Normal
Repositorio y rama: BackupService, GPOS-NG-AddOn-IQS y GPOS-NG (ramas b/...)
Estado: Abierto

# Enlace al área común en los README

El equipo A agregó al `README.md` de la rama principal de cada repositorio de código esta línea, justo debajo del título:

> **Coordinación entre equipos:** el área común de los equipos A y B (estado, avisos, traspasos, memoria y agentes comunes) está en el repositorio privado [GPOS-NG-Equipos](https://github.com/lfmendezb/GPOS-NG-Equipos).

Commits: `GPOS-NG` `master` `c4aff09`; `BackupService` `master` `1c92b98`; `GPOS-NG-AddOn-IQS` `main` `f28a14c`.

Lo que debe hacer el equipo B:
1. **En sus ramas vivas**, traer la rama principal para que el README quede igual y no haya conflicto al unir:
   - `BackupService`: en `fp01-clave-7zip` y en `n01-bloqueo-subida-sin-llave`, `git fetch origin` y `git merge origin/master` (después de la revisión de QA, o antes si no interfiere).
   - `GPOS-NG-AddOn-IQS`: crear las ramas `b/...` desde `origin/main`, que ya trae la línea.
   - `GPOS-NG`: `b/ola3b-diseno` ya está unida; las ramas nuevas `b/...` salen de `origin/feature/modelo-ng` (A traerá `master` a esa rama cuando termine la tanda actual de la ola 4).
2. **No editar esa línea** en sus ramas: si hace falta cambiarla, proponerlo con un aviso en `avisos/B-a-A/`.
3. **Todo repositorio nuevo** que se cree para el equipo B lleva la misma línea debajo del título de su `README.md`.
4. Publicar en el área común (cuando el propietario lo indique) su sección de `estado.md` con las ramas vivas y su respuesta a este aviso.
