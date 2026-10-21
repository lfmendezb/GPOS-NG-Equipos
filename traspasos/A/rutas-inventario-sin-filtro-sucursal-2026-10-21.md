```
Para: B        De: A (arquitecto-software)        Fecha: 2026-10-21
Tipo: Entrega (PREGUNTA-3 / S-16 de la revisión de seguridad del ADR-93)
Encargo: avisos/B-a-A/2026-10-21-respuestas-revision-seguridad-adr93.md
Base revisada: origin/feature/modelo-ng @ e3e729c1 (solo lectura; sin compilar). ADR-93 en origin/HEAD @ cb9c5fe4
Estado: Completado
```

# Rutas de inventario que no filtran por la sucursal del usuario restringido

## 1. Resumen

- Ninguna ruta de inventario de la API principal aplica `RestringirSucursal`. Hay **14 rutas o grupos** que entregan existencias, niveles, movimientos o valor de almacenes de otras sucursales [V].
- La restricción **ya se lee en el servidor en cada petición**, pero se descarta. `ConsultaEstadoSesion.Sql` trae `RestringirSucursal` y `SucursalDefault` (`src/GPOS.Core/Consultas/Sistema/ConsultaEstadoSesion.cs:21-22`) [V]. Sin embargo, `EstadoSesionUsuario` no los conserva (`src/GPOS.Core/Sistema/UsuariosService.cs:670-671` y `:920-921`) [V]. Exponerlos cuesta cero consultas más y es la pieza común P-0 (que es la de S-17).
- Hay dos fallas abiertas que van más allá de TA-P08 y conviene corregirlas para todos:
  1. Kárdex y existencia de la línea: un código de almacén **desconocido** se convierte en «todos los almacenes» (`InventarioService.cs:744-745`, `CatalogoService.cs:173-174`) [V].
  2. Transferencias: una sucursal nula o desconocida se convierte en la **principal** (`DocumentosNg.cs:73-80`) [V].
- **Trampa de escritura (Alta si se olvida).** La pestaña Almacenes se guarda **borrando y reponiendo todos** los niveles del artículo (`MaestrosService.Articulos.cs:363-366`) [V]. Si solo se filtra la lectura, un restringido que guarde el artículo **borra los mínimos y el reorden de las otras sucursales**.
- **Esfuerzo:**
  - Lo que nombra la precisión de TA-P08 (existencias, kárdex y pestaña Almacenes, con P-0 y sus pruebas): **unos 1,45 dp**, dentro del 1 a 1,5 d del ADR.
  - La lista completa: **unos 3,0 dp (±40 %)**. Las rutas R-05 a R-14 suman unos 1,6 dp **fuera** de lo estimado. B decide cuáles entran en E-1.

## 2. Pieza común P-0: el alcance de almacenes en el servidor (S-17)

**Cómo se obtiene hoy la restricción** [V]
- **Principal.** El token solo lleva la sucursal, y es opcional (`src/GPOS.Api/Seguridad/Seguridad.cs:138`). `ISesionActual.Sucursal` sale del claim (`Seguridad.cs:158`). En cada petición, `RevocacionSesiones` lee la fila de `dbo.Usuarios` (`RevocacionSesiones.cs:36-39`), con caché de 15 s (`:83`). Esa lectura ya incluye `RestringirSucursal` y `SucursalDefault`, pero no los pasa a `EstadoSesionUsuario`.
- **Precedente.** `GPOS.Reportes` hace lo mismo con `rptsis`. Si el usuario está restringido, manda la sucursal asignada; si no la hay, deja la sucursal en nulo y responde 403 (`src/GPOS.Reportes/Contexto/ProveedorContexto.cs:90-98`, `:32-35`).

**Propuesta mínima (0,35 dp, incluidas las pruebas de la pieza)**
1. Agregar `RestringirSucursal` y `SucursalDefault` a `EstadoSesionUsuario` (`UsuariosService.cs:920`). Se llenan con la misma fila (`:670`), sin consulta nueva.
2. Crear `IAlcanceAlmacenes` en Core, con implementación *scoped* en la API. Lee `RevocacionSesiones.Guardada(usuario)` (`RevocacionSesiones.cs:140`), que ya validó esta misma petición. Si no hay lectura guardada, lee la base. Devuelve:
   - `Global`, si `RestringirSucursal = 0`. Es PREGUNTA-4, firmada: global aunque la sesión esté en una sucursal.
   - `Sucursal(id)`, si está restringido y `SucursalDefault` resuelve a una `org.Sucursal`. **Manda la del servidor, no la del token.** Si son distintas, se registra un aviso, como en `ProveedorContexto.cs:94-96`.
   - `Vacio`, si está restringido y no resuelve (sin sucursal, código inexistente o error de lectura). **Nunca `Global`.**
   - Ignora cualquier parámetro del cliente.
3. **Patrón SQL de falla cerrada.** Se agregan `@global bit` y `@sucursalAlcance smallint`, con la condición `AND (@global = 1 OR al.SucursalId = @sucursalAlcance)`. Si falta un parámetro o vale `NULL`, no sale ninguna fila. Nunca salen todas. `Almacen.SucursalId` no admite nulos (`Organizacion.cs:47`), así que no hay fuga por `NULL`.
4. **Dos alcances** (ver la decisión pendiente D-1):
   - `Consulta`: solo los almacenes **de** la sucursal. Es lo que fija el ADR-093:126-128, sin `SucursalAlmacenPermitido`.
   - `Operativo`: los de la sucursal **más** los permitidos (`ConsultasInventario.cs:121-128`, la regla con la que ya se escribe). Se usa solo en las rutas que alimentan un documento (R-05, R-06 y R-07).

## 3. Lista de rutas

Columnas: ruta y evidencia · qué entrega hoy de otras sucursales · filtro propuesto · pantallas (Web; MAUI es espejo en `GPOS.UI.MAUI/…`, mismas líneas de `ApiClient`) · dp.

### 3.1 Las que nombra la precisión de TA-P08

**R-01 · `GET /api/inventario/existencias`**
- **Evidencia.** `src/GPOS.Api/Endpoints/InventarioEndpoints.cs:91-93`, con `RequiereAlgunPermiso(ReportesInventario, Articulos, Conteo)`. `InventarioService.cs:723-736`. SQL `ConsultasDocInventario.cs:87-97`, con `WHERE (@almacen IS NULL OR al.Codigo = @almacen)` [V].
- **Qué entrega.** Existencia, mínimo, máximo, reorden y costo de **todos** los almacenes. El costo y el valor van marcados con `[DatoCosto]` (`Inventario.cs:124-127`). Con `?almacen=` se pide directamente el almacén de otra sucursal.
- **Filtro.** Alcance `Consulta` en el SQL. Un `almacen` fuera del alcance devuelve una lista vacía, igual que uno inexistente.
- **Pantallas.** `Inventario/Existencias.razor:118` (menú `NavMenu.razor:169`, `Home.razor:40`).
- **Esfuerzo.** 0,25 dp.

**R-02 · `GET /api/inventario/kardex/{articulo}`**
- **Evidencia.** `InventarioEndpoints.cs:94-96` (`ReportesInventario` o `Articulos`). `InventarioService.cs:739-758`. SQL `Kardex` y `SaldoAntes` (`ConsultasDocInventario.cs:59-78`) [V].
- **Qué entrega.** Movimientos (fecha, tipo, número del documento, almacén, cantidad, costo unitario y valor) y el saldo de **todos** los almacenes cuando no se indica almacén. **Falla abierta:** un almacén desconocido termina en `almacenId = null`, es decir, todos (`:744-745`).
- **Filtro.**
  1. Almacén fuera del alcance: `[]`.
  2. Sin almacén: solo los del alcance, también en `SaldoAntes`.
  3. Código desconocido: `[]` para todos los usuarios, no «todos».
- **Pantallas.** `Existencias.razor:134` (MAUI `:134`).
- **Esfuerzo.** 0,25 dp.

**R-04 · `GET /api/maestros/articulos/{id}` (pestaña Almacenes) y su guardado**
- **Evidencia.** `TablasEndpoints.cs:39` (grupo `Articulos`). `MaestrosService.Articulos.cs:143-164` [V].
- **Qué entrega.** Los niveles (ubicación, mínimo, máximo y reorden) y la existencia de **cada almacén de todas las sucursales**, además de `dto.Existencia` como suma global.
- **Filtro.**
  - Niveles y existencias limitados al alcance `Consulta`, con el total sobre ese mismo alcance.
  - **Guardado** (`POST`, `:292-298` y `:363-366`): para un restringido, solo se reemplazan las filas de `ArticuloAlmacen` del alcance y se conservan las demás. Una fila del DTO con un almacén fuera del alcance se rechaza con 422.
- **Pantallas.** `Tablas/Articulos.razor:242`, que muestra la pestaña en `:197-209` y el chip «Ex» en `:54`.
- **Esfuerzo.** 0,4 dp, incluido el guardado.

**Pruebas de R-01, R-02 y R-04 (0,2 dp).** Restringido con el token de otra sucursal; restringido sin sucursal resoluble (vacío); sin restricción (global); almacén fuera del alcance; guardado del restringido que conserva los niveles ajenos.

**Subtotal de la precisión: 0,35 + 0,25 + 0,25 + 0,4 + 0,2 = 1,45 dp.**

### 3.2 Otras rutas que entregan existencias o niveles (mismo criterio, fuera del estimado del ADR)

**R-03 · `GET /api/maestros/articulos` (lista)**
- **Evidencia.** `TablasEndpoints.cs:36-37`. `MaestrosService.Articulos.cs:61`, con `Existencia = SUM` de todos los almacenes [V].
- **Qué entrega.** La existencia global de hasta 500 artículos.
- **Filtro.** Sumar dentro del alcance `Consulta`.
- **Pantallas.** `Articulos.razor:248`, columna en `:42`.
- **Esfuerzo.** 0,15 dp.

**R-05 · `GET /api/catalogos/articulos/{codigo}/linea`**
- **Evidencia.** `DocumentosEndpoints.cs:41-48`. Solo exige `RequireAuthorization`, **sin permiso** (`:11`). `CatalogoService.cs:155-177` y `:185-199`. SQL `ConsultasInventario.cs:226-229` [V].
- **Qué entrega.** La existencia del almacén que se pida, de cualquier sucursal. Sin almacén, o con uno desconocido, la **suma global**.
- **Filtro.** Alcance `Operativo`. Fuera del alcance o con almacén desconocido, `Existencia = 0`. Sin almacén, la suma del alcance.
- **Pantallas.** `Compartidos/EditorLineas.razor:374`, `DocInventarioPage.razor:305`, `ConteoFisico.razor:303`, `DevolucionPosPage.razor:167`.
- **Esfuerzo.** 0,15 dp.

**R-06 · `GET /api/inventario/lotes-disponibles`**
- **Evidencia.** `InventarioEndpoints.cs:47-49`. `LotesService.cs:22-31` [V].
- **Qué entrega.** Los lotes, con su existencia y vencimiento, de cualquier almacén.
- **Filtro.** Almacén fuera del alcance `Operativo`: 404, el mismo de «no existe».
- **Pantallas.** `EditorLineas.razor:476`, `DocInventarioPage.razor:436`.
- **Esfuerzo.** 0,1 dp.

**R-07 · `GET /api/inventario/conteos/preparar`**
- **Evidencia.** `InventarioEndpoints.cs:66-67`. `InventarioService.cs:475-522` [V].
- **Qué entrega.** La existencia y el costo de hasta 3000 artículos de cualquier almacén.
- **Filtro.** Fuera del alcance `Operativo`: «Almacén incorrecto», igual que si no existiera.
- **Pantallas.** `ConteoFisico.razor:271`.
- **Esfuerzo.** 0,1 dp.

**R-08 · `GET /api/inventario/conteos` y `/conteos/{numero}`**
- **Evidencia.** `InventarioEndpoints.cs:68-71`. `InventarioService.cs:629-652` y `:681-692` [V].
- **Qué entrega.**
  - La lista: los conteos de todas las sucursales, con el almacén y el valor de la diferencia.
  - El detalle: la existencia del corte o la actual de cada línea.
- **Filtro.** La lista, por almacén dentro del alcance; el detalle, 404 si su almacén está fuera.
- **Pantallas.** `ConteoFisico.razor:258`, `:349`, `:355` y `:363`.
- **Esfuerzo.** 0,15 dp.

**R-09 · `GET /api/inventario/documentos/{tipo}` y `/{numero}`** (entradas, conduces y ajustes)
- **Evidencia.** `InventarioEndpoints.cs:24-27`. `InventarioService.cs:48-100` [V].
- **Qué entrega.** Los documentos de todas las sucursales: almacén, líneas con cantidad y costo, y el total al costo si el usuario tiene «Ver costos». Son las piezas del kárdex.
- **Filtro.** Igual que en R-08. Se recomienda por coherencia con R-02; **B confirma si entra** (D-2).
- **Pantallas.** `DocInventarioPage.razor:297` y `:628`.
- **Esfuerzo.** 0,2 dp.

**R-10 · `GET /api/inventario/revisiones-lote`, `/{id}` y `/abiertas/cantidad`**
- **Evidencia.** `InventarioEndpoints.cs:55-60`. `LotesService.cs:50-78`. `RevisionLoteDto` lleva `Almacen`, `Cantidad` y `ExistenciaLote` (`Contracts/Inventario/Lotes.cs:75-78`) [V].
- **Qué entrega.** Las revisiones de lote de todos los almacenes.
- **Filtro.** Por almacén dentro del alcance; el contador, igual.
- **Pantallas.** `Inventario/RevisionLotes.razor`; el contador del menú usa `ApiClient.Lotes.cs:30`.
- **Esfuerzo.** 0,15 dp.

**R-11 · `GET /api/reportes/dashboard/indicadores`**
- **Evidencia.** `ReportesEndpoints.cs:78`. `DashboardService.cs:53-58`. SQL `ConsultasTablero.cs:72-77`, sin ningún `WHERE` [V].
- **Qué entrega.** El «Valor del inventario» de la empresa entera (requiere `ReportesInventario` y «Ver costos»).
- **Filtro.** Sumar dentro del alcance `Consulta`.
- **Pantallas.** `Compartidos/Tablero.razor:143` y `:148`.
- **Esfuerzo.** 0,1 dp.

**R-12 · `GET /api/reportes/dashboard/avisos`**
- **Evidencia.** `ReportesEndpoints.cs:80`. `DashboardService.cs:66-73` [V].
- **Qué entrega.** El código y nombre de cada sucursal cerrada y cuántos artículos con existencia tiene.
- **Filtro.** Para un restringido, solo su sucursal.
- **Pantallas.** El Tablero.
- **Esfuerzo.** 0,05 dp.

**R-13 · `GET /api/admin/diagnostico/conciliacion`**
- **Evidencia.** `AdminEndpoints.cs:20-23` (privilegio `Conciliacion`, `SoloCentral`). `ConciliacionService.cs:34-37` [V].
- **Qué entrega.** Artículo, almacén, existencia materializada y existencia del kárdex de todos los almacenes.
- **Filtro.** Un restringido recibe **403** (es un diagnóstico de la empresa). Es la opción más barata y falla cerrada. Ver D-3.
- **Pantallas.** `Admin/Conciliacion.razor:99` y `:107`.
- **Esfuerzo.** 0,05 dp.

**R-14 · `/api/reportes/{id}/ejecutar` y `/exportar` sin reenvío**
- **Evidencia.** `ReportesEndpoints.cs:24-71`. `ReenvioReportes.cs:39`: si `Direccion` está vacía, no hay reenvío. `ReportesService.cs:255` [V].
- **Qué entrega.**
  - Sin la API de reportes configurada, la principal ejecuta **todos** los reportes, los de inventario también, sin filtro de sucursal.
  - Con reenvío, `GPOS.Reportes` sí aplica T2-03 y falla cerrado (`IReporteRegistrado.cs:131`, `EjecutorDisenador.cs:285`) [V].
  - Ningún reporte de inventario está en `EnLaPrincipal` (`ReportesSemilla.cs:136-140`) [V].
- **Filtro.** En el camino local, un restringido recibe **403 `SUCURSAL_NO_PERMITIDA`**, o bien se exige el reenvío en producción.
- **Pantallas.** Reportes.
- **Esfuerzo.** 0,1 dp.

### 3.3 Transferencias: ya filtran, con un residuo

**`/api/transferencias/*`**
- **Evidencia.** `TransferenciasEndpoints.cs:24-84`. `TransferenciasService.cs:62-82` y `:109-137`. `TransferenciasService.Recepcion.cs:118` [V].
- **Qué hacen hoy.** Listan, detallan, imprimen el conduce y abren sesiones solo si la sucursal **de la sesión** es la de origen o la de destino. La excepción es la reconciliación desde la central.
- **Residuo 1.** La sucursal sale **del token**, y `SucursalIdAsync` convierte una sucursal nula o desconocida en la **principal** (`DocumentosNg.cs:75-79`). Con «Reconciliación», ese usuario vería todas las transferencias.
- **Residuo 2.** A un restringido siempre se le asigna sucursal al iniciar sesión (`UsuariosService.cs:766-772`). El riesgo es el token viejo después de que el ADMIN cambia la restricción o la sucursal.
- **Filtro.** Si el usuario está restringido, usar la sucursal de P-0 en vez de la del token; si es `Vacio`, 404.
- **`GET /almacenes`.** Devuelve los almacenes **de destino** de todas las sucursales, solo código y nombre, sin existencias. Es así por diseño; no se cambia.
- **Esfuerzo.** 0,1 dp.

### 3.4 Revisadas que no entregan existencias (sin cambio)

- **Catálogo F3 de artículos.** Sin existencia (`ConsultasMaestros.cs:43-50`) [V].
- **`/api/catalogos/Almacenes`.** Solo códigos y nombres. Mejora de UX opcional: mostrarle al restringido solo los suyos en el selector de `Existencias.razor`.
- **Cierre del período de inventario** (`CierrePeriodoInventarioService.cs:34-96`). Es un proceso de la empresa, con privilegio propio.
- **`/api/admin/*`** (cierre de sucursal e importación de existencias). Son rutas del ADMIN; ver D-3.

## 4. Esfuerzo

| Bloque | dp |
|---|---|
| P-0 (pieza común; coincide con S-17) | 0,35 |
| R-01, R-02 y R-04, con sus pruebas (lo que nombra la precisión de TA-P08) | 1,10 |
| **Subtotal de la precisión** | **1,45** |
| R-03 y R-05 a R-14, más transferencias | 1,40 |
| Pruebas de la lista ampliada | 0,20 |
| **Total** | **unos 3,0 (±40 %)** |

Costo de infraestructura: USD 0. No hay tecnología nueva.

## 5. Decisiones pendientes (para B; ninguna reabre el ADR)

- **D-1. ¿Los almacenes permitidos entran en el alcance de R-05, R-06 y R-07?** El ADR-093:128 los deja fuera [I, decisión técnica]. Sin embargo, el restringido **puede mover** esos almacenes (`ConsultasInventario.cs:121-128`). Si se le niega su existencia y sus lotes, no puede elegir un lote ni ver si hay mercancía al hacer el conduce o el ajuste. **Recomendación:** alcance `Operativo` (propios más permitidos) solo en esas tres rutas, y `Consulta` en las demás. El guardado ya revela esa existencia por el error de existencia insuficiente, así que no se abre nada nuevo.
- **D-2. ¿R-09 (documentos de inventario) entra en la frontera?** Recomendado sí.
- **D-3. ¿Un ADMIN con `RestringirSucursal` queda sujeto al alcance?** `ContextoReportes.cs:43` supone que puede existir. **Recomendación:** sí en las rutas de esta lista; las de `/api/admin/*` quedan como están, salvo R-13, que pasa a 403.
- **D-4. Fuera de inventario.** Los indicadores de ventas, CxC y cobros del Tablero (`DashboardService.cs:28-45`) también son de toda la empresa. No entran en TA-P08; se señalan por si el propietario quiere la misma frontera en ventas.

### Cierre
- Estado: Completado
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\rutas-inventario-sin-filtro-sucursal-2026-10-21.md`
- Supuestos:
  - Base: `feature/modelo-ng` @ e3e729c1. Las líneas que citó la revisión previa (fc7f07f2) siguen iguales.
  - Las pantallas MAUI son espejo de las Web. Se verificaron `ApiClient` y `Existencias.razor`; el resto se infiere por la misma estructura.
  - Los esfuerzos son [I], sin compilar ni medir.
- Decisiones candidatas a ADR: ninguna nueva. D-1 a D-3 son precisiones de TA-P08 que B puede registrar.
- Entregas a otros agentes:
  - arquitecto-software o backend: P-0 y R-01 a R-14 en E-1.
  - qa-automatizado: pruebas de la sección 3.1 y de la falla cerrada.
  - disenador-ux-ui: rótulo «Existencia en su sucursal» en la lista y en la pestaña, y selector de almacenes del restringido.
  - B: D-1 a D-4.
- Próximo paso recomendado: que B decida D-1 y el alcance (solo 3.1 o la lista completa) antes de iniciar E-1.
