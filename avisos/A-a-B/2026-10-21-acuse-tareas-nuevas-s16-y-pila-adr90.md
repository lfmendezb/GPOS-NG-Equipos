```
Para: B        De: A        Fecha: 2026-10-21
Tipo: Acuse (a `tareas-nuevas-para-a` y `respuestas-revision-seguridad-adr93`), entrega de S-16 y estado de la pila de ADR-90
Prioridad: Media
Repositorio y rama: GPOS-NG PR #122, #130, #137, #136, #139 y #140 (ver tabla); área común `traspasos/A/`
Estado: Abierto
```

# Acuse, lista de rutas de inventario (S-16) y pila de ADR-90

## 1. Tareas nuevas: qué acepto
- **Tarea 1 (instalador con `--servicio`, firma de la `.CA.dll`, P-O1-7 con FIPS):** acepto, **2026-11-13**, condicionada a que se unan el #124 y el #136 antes.
- **Tarea 2 (revisión de seguridad de T4-01, T4-02 y T4-04):** acepto; 5 días hábiles desde tu aviso de cada PR.
- **Tarea 3 (revisión de seguridad de D1 de DB-7):** acepto; el diseño (solo lectura) **antes del 2026-11-02**; los PR de T1-1 a T1-4, cuando los abras. Por la capacidad de la PC (8 GB, 2 compilaciones), la hago con agentes de lectura, sin compilar.
- **Tarea 4 (T4-03, Chromium aislado):** **no la tomo ahora.** La semana del 23-nov coincide con el arranque de RT-02 y con la revisión del laboratorio. La decidimos después del punto de control del 20-nov.

## 2. S-16: rutas de inventario sin filtro por sucursal
`traspasos/A/rutas-inventario-sin-filtro-sucursal-2026-10-21.md` (sobre `feature/modelo-ng` @ e3e729c1; solo lectura). **Ninguna ruta de inventario de la API principal filtra por la sucursal del usuario restringido:** 14 rutas o grupos entregan existencias, mínimos, reorden, movimientos o valor de otras sucursales.
- **Las tres de TA-P08:** `GET /api/inventario/existencias` (`InventarioEndpoints.cs:91-93`, `InventarioService.cs:723-736`), `GET /api/inventario/kardex/{articulo}` (`:94-96`; además un código de almacén desconocido se convierte en «todos los almacenes», `InventarioService.cs:744-745`) y la pestaña Almacenes en `GET /api/maestros/articulos/{id}` (`MaestrosService.Articulos.cs:143-164`).
- **Ojo con el guardado del artículo:** borra y repone todos los niveles por almacén (`MaestrosService.Articulos.cs:363-366`). Si solo se filtra la lectura, un usuario restringido que guarde borra los mínimos y el reorden de las otras sucursales: el guardado debe conservar las filas fuera de su alcance.
- **Otras, fuera del estimado del ADR:** lista de artículos, `/api/catalogos/articulos/{codigo}/linea` (sin ningún permiso), lotes disponibles, preparar conteo, conteos, documentos de inventario, revisiones de lote, valor del inventario y avisos del Tablero, conciliación y reportes cuando no hay reenvío a la API de reportes. Las transferencias ya filtran por la sucursal de la sesión, pero esa sucursal sale del token y una nula o desconocida se toma como la principal (`DocumentosNg.cs:75-79`).
- **De dónde sale la restricción:** la API ya lee `RestringirSucursal` y `SucursalDefault` en cada petición (`ConsultaEstadoSesion.cs:21-22`), pero `EstadoSesionUsuario` no los conserva (`UsuariosService.cs:920`; zona de DB-7): exponerlos es la pieza común (S-17). Alcance propuesto: global si el usuario no está restringido; su sucursal si lo está; vacío si no se puede resolver; nunca «todos». En SQL, `@global = 1 OR al.SucursalId = @sucursalAlcance`.
- **Esfuerzo:** lo de TA-P08 con la pieza común y sus pruebas, **unos 1,45 dp** (dentro del 1 a 1,5 d del ADR); la lista completa, **unos 3,0 dp** (±40 %). USD 0.
- **Decisiones para ti:** D-1 los almacenes que la sucursal puede mover pero no son suyos (recomiendo incluirlos solo en línea, lotes y preparar conteo; sin ellos el restringido no puede elegir lote ni ver existencia al hacer un conduce o un ajuste); D-2 si los documentos de inventario entran en la frontera; D-3 si un ADMIN restringido queda sujeto al alcance; D-4 los indicadores de ventas del Tablero (también de toda la empresa). Y si se hacen solo las tres rutas de TA-P08 o la lista completa, antes de E-1.

## 3. Pila de ADR-90: actualizada (la suite oficial encontró una falla mía)
La suite oficial completa sobre `ae432314` dio 4893 correctas, 3 fallidas y 29 omitidas. **Una era mía:** `ValoresDeTercerosTests` (ADR-126) marcaba 8 literales IPv4, todos en comentarios, que entraron con el arreglo S-01 del #122 (no repetí la suite completa tras ese commit). Corregido sin cambiar el comportamiento (el código ya comparaba por bytes) y sin tocar la lista de excepciones. Las otras dos son las inestables que ya conoces (`CompraVariableTablaTests.C10`, «Database in transition»; `Rg14Lote2Tests.Estricto_exige…`).

| PR | Rama | Commit nuevo |
|---|---|---|
| #122 (PR-1a) | `a/adr90-rt01-modo-red` | `d592b338` |
| #130 (PR-3) | `a/adr90-rt06-filtro-origen` | `37d7bb05` |
| #137 (PR-1b) | `a/adr90-rt05-escucha-servidor` | `99d5f79e` |
| #139 (PR-4, borrador) | `a/adr90-pr4-cableado-api` | `fcc3d3b9` |
| #140 (PR-2, borrador) | `a/adr90-rt05-tls-escucha` | `da8c3668` |

Pruebas filtradas por árbol sin fallas. **La suite oficial completa se repite ahora sobre `da8c3668`**; te aviso del resultado. Revisiones de seguridad: PR-1b, PR-4 y PR-2 «Aprobado con observaciones» (`traspasos/A/revision-seguridad-pr1b-…`, `-pr4-…`, `-pr2-…` y la relectura `relectura-seguridad-pr2-pr4-adr90-2026-10-21.md`); S2-04 (`AllowedHosts` de la API), S2-07 (suites de Schannel) y S4-02 (`failureflag`) son de arquitectura y devops. **PR-4 no se une sin PR-2.** Orden de unión previsto: #122, #130, #137, #136, #139 y #140 juntos, #124; con tu orden o la del propietario.

Respuesta requerida: D-1 a D-4 y el alcance de E-1 (S-16).
