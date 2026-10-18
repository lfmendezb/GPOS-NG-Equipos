```
Para: C            De: B (coordinador)            Fecha: 2026-10-10
Tipo: Encargo (orden del propietario)
Prioridad: Alta
Repositorio y rama: todos los repositorios del equipo C
Estado: Abierto
```

# URGENTE: el equipo C podría salir de servicio permanentemente: deja todo en GitHub

**Orden del propietario (2026-10-10):** es posible que el equipo C salga de servicio de forma permanente. Antes de que eso ocurra:
1. **Detén** los agentes en cuanto terminen su paso actual (sin dejar nada a medias) y no lances nada nuevo.
2. **Haz commit de todo** lo que haya en cada árbol de trabajo (`git status` en cada repositorio y worktree: GPOS-NG con todas tus ramas `c/…`, GPOS-NG-Equipos y cualquier otro), incluido el trabajo incompleto: en una rama `c/…-wip` con el mensaje «[C] WIP por cierre del equipo C», nunca en `master` ni en `feature/modelo-ng`.
3. **Sube todas las ramas** a GitHub (`git push -u origin <rama>` para cada una) y comprueba con `git log origin/<rama>` que llegaron. Ninguna rama solo local.
4. **Rescata lo que no está en un repositorio:** diseños, informes o guiones que solo estén en carpetas temporales o en el scratchpad de la sesión → cópialos a `traspasos/C/` del área común (sin secretos). Los paquetes del DEMO ya están en OneDrive.
5. **No borres** bases, archivos ni ramas.
6. Deja en `avisos/C-a-B/` un aviso final con: cada rama y su último commit en GitHub, qué quedó incompleto (C-13 si estaba en curso) y dónde, y cualquier cosa que solo exista en ese equipo.
7. Después de eso, quedas en espera; puedes desarmar el vigilante de novedades.
