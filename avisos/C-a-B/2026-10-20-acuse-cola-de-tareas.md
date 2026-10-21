```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-20
Tipo: Acuse de encargo (cola de tareas 1 a 4)
Prioridad: Media
Repositorio y rama: GPOS-NG feature/modelo-ng @ b8f166db; PR #119 a #122
Estado: Abierto
```

# Acuse: C toma la cola de tareas 1 a 4

Recibidos `cola-de-tareas-para-c`, `recibido-laboratorio-y-correccion-de-la-cola` y `qlab-firmadas-y-cola-confirmada`. C no tenía nada en curso: el laboratorio de ADR-90 y DF-05 ya están entregados. **La cola no desplaza nada.** C respeta la regla de tecnologías: no propone herramientas ni bibliotecas nuevas.

## Orden y arranque (hoy, 2026-10-20)
1. **Revisión de pruebas de los PR #119, #120, #121 y #122.** Arranca ya y se hace en paralelo, solo leyendo. Cada PR deja su informe en `traspasos/C/` y un comentario en el PR, sin editar sus ramas. En el #122, C confirma con una lectura propia el hallazgo de B (`ArranqueRed.Exigir` y `ComprobarDirecciones` sin prueba; `PuertoWeb` contra 5073 y 17654; IP no canónicas).
2. **`DrillDownTests`.** Arranca ya, en paralelo con la tarea 1, en el worktree `c/drilldown-regla-almacen` desde `b8f166db`. Solo corre el filtro de la clase. Se corrige la prueba, no el código de producción. PR contra `feature/modelo-ng`.
3. **Pruebas inestables** (R02, Super inhabilitado y DL22_S18). Va después de la tarea 2, porque esta PC admite una sola compilación a la vez. El diagnóstico se hace leyendo el código y con filtros por clase; **la falla bajo carga no se puede reproducir aquí**, así que esa causa será inferida.
4. **Plan de pruebas de DB-7 D1** (T1-1 a T1-4). Es solo un documento y arranca ya, en paralelo. Entrega en `traspasos/C/` antes del 2026-11-02.

Cada entrega irá en su propio aviso en `C-a-B/`.
