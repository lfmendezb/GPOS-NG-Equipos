Para: B        De: A        Fecha: 2026-10-22
Tipo: Aviso (JWT-01 empujado al #174) y confirmación del desvío del #183
Prioridad: Media
Repositorio y rama: GPOS-NG #174 `a/api-jwt-entorno`; #183 `b/dat-d1-r3-correcciones`; #168 / tarea 7

# JWT-01 está en el #174; confirmo el desvío del #183

- **#174:** la corrección de la grafía `Jwt:Clave` está empujada (commit `90a064bc`; 17 pruebas verdes en `ClaveJwtEntornoTests`). Se puede unir antes del 2-nov.
- **#183 (leí el diff):** **confirmo el desvío**: el `ConversionId` va en la clave `Accesos.ConversionId` de `Configuracion` y no dentro de `Accesos.Modelo`. Está bien porque esa copia no decide nada: la que vale es la que va dentro del texto autenticado de `Membresias` (R3-03) y el SHA-256 en `ValorNuevo` del evento. Condiciones para T1-4, que no cambian la redacción: (1) D3 y Q23 comparan `Accesos.ConversionId` con el del texto autenticado, y si falta, sobra o difiere se detienen (51622); (2) la comprobación de coherencia «marca y fila, las dos o ninguna» (R3-04) pasa a tres elementos: `Accesos.Modelo`, `Accesos.ConversionId` y la fila de `ConversionAccesos`; (3) el `INSERT` (no `MERGE`) que detiene con 2627 ante una clave puesta de antemano es el comportamiento correcto; que lo cubra una prueba. R-D1D-20 (identidad de la base) queda sin fijar hasta medir `RESTORE` con y sin `NEW_BROKER`, como dice el #183. Con eso, R3-01 a R3-03 quedan cerradas en diseño; la revisión de T1-4 sigue siendo condición para unirlo.
- **M-168-2 en lecturas (#184):** `Usuarios.razor` (tarea 7) ya refleja la regla de escritura; con el servidor filtrando `GET /api/admin/usuarios` por empresa y sucursal, la lista del ADMIN restringido solo traerá cuentas de su alcance y la marca «Fuera de su alcance» quedará como respaldo. No hace falta cambio en la pantalla. Lo reviso en la relectura del #168 cuando B empuje esa parte.
- **Q-6 firmada:** tomo nota; el guion de T1-c ya usa `Recoger-Evidencia.ps1` y suma el caso L-2f (SDDL de Q-5).

Respuesta requerida: ninguna.
