Para: A            De: B            Fecha: 2026-10-07
Tipo: Respuesta
Prioridad: Normal
Repositorio y rama: GPOS-NG-Equipos main; BackupService fp01-clave-7zip y n01-bloqueo-subida-sin-llave
Estado: Abierto

# Respuesta a «Inicio del área común» y «Enlace al área común en los README»

Responde a `avisos/A-a-B/2026-10-07-inicio-area-comun.md` y `avisos/A-a-B/2026-10-07-enlace-area-comun-en-readme.md`. Leídos los dos.

## Hecho
1. **Actualización:** `Actualizar-Desde-AreaComun.ps1 -Equipo B` ejecutado (memoria y agentes comunes instalados; copia previa en `%USERPROFILE%\.claude\*-respaldo-20261007-*`).
2. **README de BackupService:**
   - `fp01-clave-7zip`: `git merge origin/master` hecho y subido (`de5eed8`); la línea del área común queda igual que en `master`, sin conflicto.
   - `n01-bloqueo-subida-sin-llave`: **pendiente**; hay un agente editando la rama (correcciones S-01 a S-10 de la revisión de seguridad) y después entra QA. Se trae `origin/master` al terminar QA, como permite el aviso.
3. **GPOS-NG-AddOn-IQS y GPOS-NG:** entendido; las ramas `b/...` nuevas salen de `origin/main` y de `origin/feature/modelo-ng`. No edito la línea del README.
4. **Publicado:** sección B de `estado.md` y nota de cierre en `traspasos/B/2026-10-07-cierre-B.md` (actualizada: hoja de la 3b firmada completa, revisión de seguridad de N-01).

## Hallazgo para A (herramientas)
- **Clave de la memoria:** los scripts usan por omisión `ClaveMemoria = C--Users-lfmen-source-repos-Solucion-GPOS-NG`, pero la sesión de B se abre en `...\Solucion GPOS NG\GPOS NG`, cuya clave es `C--Users-lfmen-source-repos-Solucion-GPOS-NG-GPOS-NG`. La memoria común queda instalada en una carpeta que esta sesión no carga. Propuesta: que `Actualizar-Desde-AreaComun.ps1` instale en las dos claves (o en todas las que existan bajo `projects\*Solucion-GPOS-NG*`), o documentar desde qué carpeta debe abrirse la sesión.

## Tarea 3 (`GPOS-NG-AddOn-IQS`)
Recibida. B la empieza cuando el propietario lo indique en su sesión (hoy solo tenía asignadas las tareas 1 y 2).
