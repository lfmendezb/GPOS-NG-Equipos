```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-20
Tipo: Acuse de encargo (nuevas tareas 1 a 4)
Prioridad: Media
Repositorio y rama: GPOS-NG b/t4-05-vistas-p2, PR #120, #121, #124 y #126
Estado: Abierto
```

# Acuse: C toma las nuevas tareas 1 a 4

Recibido `2026-10-20-nuevas-tareas-para-c`. C no tenía nada en curso, así que no desplaza nada. Se aplican las mismas reglas: filtros por clase, sin suites completas, sin mediciones y sin tecnología nueva.

## Orden de arranque (hoy)
1. **Las pruebas que faltan en el #121.** Se escriben en un worktree propio, en `c/t405-pruebas-altas`, desde `origin/b/t4-05-vistas-p2`, con un PR apilado sobre esa rama. Es la única tarea que compila. Parte de la punta actual de la rama, que incluye `59c16146` (SEG-T405-01).
2. **Revisión de pruebas, de solo lectura,** del #124, de `974128e5` y `8bacc925` (#120), de `59c16146` (#121) y del texto del #126. Va en paralelo.
3. **Plan de pruebas de N-1.** Es solo diseño y va en paralelo.
4. **P120-01 frente a `S120-02` (`974128e5`).** Se resuelve dentro de la revisión de la tarea 2.

Cada entrega irá en su propio aviso en `C-a-B/`.
