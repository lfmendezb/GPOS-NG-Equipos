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

---

## Adenda 2026-10-22: V-RIESGO-1 y F-25 (respuesta al plan de pruebas de C)

```
Para: B (y C)        De: A (arquitecto-software)        Fecha: 2026-10-22
Tipo: Entrega (tarea 2 de avisos/B-a-A/2026-10-22-tareas-nuevas-para-a-y-uniones.md). Fecha prometida: 2026-11-06
Fuentes: traspasos/C/2026-10-22-plan-pruebas-s16-particion-e1.md (completo); avisos/B-a-A/2026-10-22-respuesta-s16-pr152-y-fechas-ola5.md §1;
         traspasos/A/blueprint-t4-06-lista-p2-2026-10-22.md (H-A06-01, IDetectorColumnas)
Base: origin/feature/modelo-ng @ b4378650 (la misma de C). Solo lectura con git show/grep; nada compilado
Estado: Completado
```

### A.1 Resumen

- **V-RIESGO-1 se confirma en la lectura y se corrige en la escritura.** La validación de «existencia insuficiente» **no** usa `LibroInventario.ExistenciasAsync` [V]: es el `UPDATE` condicional atómico de `ConsultasInventario.AplicarExistencia` (`ConsultasInventario.cs:13-39`), y se ejecuta **después** de comprobar que la sucursal del documento puede mover el almacén (`LibroInventario.cs:169-190`). De los tres usos que C llamó «de escritura» (`InventarioService.cs:505, 586, 638`), solo `:586` escribe (la foto del borrador del conteo); `:505` es R-07 y `:638` es el detalle de R-08 [V].
- **Decisión 1.** El alcance **nunca** entra en la función interna. Se separan dos firmas: «existencias para calcular» (interna, almacén obligatorio, sin alcance) y «existencias para mostrar» (exige un `AlcanceResuelto`). En lectura, el alcance se aplica **al resolver el almacén pedido**, antes de leer.
- **Decisión 2 (la fuga real por el guardado).** El guardado decide con la sucursal **del token** (`InventarioService.cs:552`, `DocumentosNg.cs:73-80`). Un token viejo de otra sucursal mueve, y por el mensaje ve, la existencia de almacenes ajenos. Se cierra en la puerta: `RevocacionSesiones.Evaluar` responde **401** si el usuario está restringido y la sucursal del token no es su `SucursalDefault`. Con eso, para un restringido, «sucursal del token = sucursal del servidor» en toda la API, también en las escrituras. Cierra la P-13 de C sin tocar ruta por ruta.
- **Decisión 3 (corrección de D-1).** R-07 (`conteos/preparar`) pasa de `Operativo` a `Consulta`. El conteo solo se guarda en almacenes de la sucursal del documento, también si el almacén está permitido (`InventarioService.cs:556-562`) [V]. Preparar la hoja de un almacén permitido no sirve para nada y revela su existencia. Así la P-07 de C ya no aplica. **B confirma** (Q-A1).
- **F-25.** Ya está resuelto en la API de reportes: `PuedeDisenar => EsAdmin && !RestringirSucursal` (RS-06, `GPOS.Reportes/Contexto/ContextoReportes.cs:43`), con 403 `DISENO_NO_PERMITIDO` en detectar y vista previa [V]. En la principal falta la misma regla (`ReportesService.cs:247-250` solo mira `EsAdmin`). **Entra en E-1** como un cambio de una línea que consume P-0. **T4-06 la conserva** y propaga el 403 por `IDetectorColumnas`. R-14 se cierra con la Q-6 de T4-06 y sale del lote S-16b, siempre que T4-06 se una antes del corte.
- **Esfuerzo:** E-1 sube unos **+0,25 dp**, S-16b unos **+0,05 dp** y T4-06 unos **+0,05 dp**. Total: **+0,35 dp (±40 %)**. Costo de infraestructura: USD 0.

### A.2 V-RIESGO-1: dónde se aplica el alcance

**A.2.1 Qué hace hoy el código** [V]

| Uso | Archivo:línea | Qué es | Almacén |
|---|---|---|---|
| R-05 línea del documento | `CatalogoService.cs:173-174` | lectura (se muestra) | `almacen?.Id`: nulo si no se pide o si el código no existe, lo que da la **suma global** |
| R-07 preparar conteo | `InventarioService.cs:478`, `:505` | lectura | `a0.Id`, no nulo |
| Guardar conteo, borrador | `InventarioService.cs:581-586` | **escritura**: la foto queda en `ConteoLinea.ExistenciaCorte` (`:598`) | `almacen.Id`, no nulo, ya validado por `:556-562` |
| Guardar conteo, aplicado | `InventarioService.cs:583-585` | escritura | **no** usa la función: lee `ConsultasDocInventario.ExistenciaCorte` con las filas bloqueadas |
| R-08 detalle del conteo | `InventarioService.cs:638` | lectura | `h.AlmacenId`, no nulo |
| Existencia insuficiente (ajuste, conduce, venta, etc.) | `LibroInventario.cs:178-190` y `ConsultasInventario.cs:13-39` | escritura | por movimiento; **antes** se exige `Permitido` (propio o regla en `org.SucursalAlmacenPermitido`, `ConsultasInventario.cs:116-128`) |

- La función compartida es `LibroInventario.ExistenciasAsync(u, articulos, short? almacenId)` (`LibroInventario.cs:592-599`). La envuelve `ReferenciasNg.ExistenciasAsync` (`ReferenciasNg.cs:185-191`).
- Su SQL es `ConsultasInventario.Existencias` (`:224-230`), con `(@almacen IS NULL OR e.AlmacenId = @almacen)`. **Falla abierta:** un nulo da «todos».
- **Solo R-05 pasa un nulo** [V]. Los otros cuatro usos pasan un almacén ya resuelto.

**A.2.2 Decisión: dos firmas y ningún nulo que signifique «todos»**

1. **Existencias para calcular** (interna, sin alcance):
   - `LibroInventario.ExistenciasAsync(IUnidadTrabajo u, IReadOnlyCollection<int> articulos, short almacenId, CancellationToken ct)`, con el almacén **no anulable**. Igual en `ReferenciasNg.ExistenciasAsync`.
   - SQL `ConsultasInventario.Existencias`: `WHERE ... AND e.AlmacenId = @almacen`, sin `IS NULL OR`. Un nulo no devuelve filas.
   - **Precondición, escrita en el `<summary>`:** quien llama ya validó el almacén. En lectura, contra el alcance (A.2.3). En escritura, con la regla de movimiento del documento (`LibroInventario.cs:188-190`) o la de conteo (`InventarioService.cs:556-562`).
   - La usan `:505`, `:586` y `:638`, que ya pasan un almacén no nulo, así que **no cambian**.
2. **Existencias para mostrar** (con alcance):
   - `LibroInventario.ExistenciasVisiblesAsync(IUnidadTrabajo u, IReadOnlyCollection<int> articulos, short? almacenId, AlcanceResuelto alcance, CancellationToken ct)`. Lo mismo en `ReferenciasNg`.
   - Consulta nueva `ConsultasInventario.ExistenciasEnAlcance`, con `@ids varchar(8000), @almacen smallint, @global bit, @sucursalAlcance smallint, @operativo bit`. Condición:
     `(@almacen IS NULL OR e.AlmacenId = @almacen) AND EXISTS (SELECT 1 FROM org.Almacen al WHERE al.Id = e.AlmacenId AND (@global = 1 OR al.SucursalId = @sucursalAlcance OR (@operativo = 1 AND EXISTS (SELECT 1 FROM org.SucursalAlmacenPermitido p WHERE p.SucursalId = @sucursalAlcance AND p.AlmacenId = al.Id))))`.
   - Aquí `@almacen` nulo es «la suma **del alcance**», nunca la global. Con `@global = 0` y `@sucursalAlcance` nulo no sale nada (AL-11).
   - Solo la usa R-05 (`CatalogoService.cs:174`) con `Operativo`.
3. **`AlcanceResuelto`** (P-0, en Core):
   - Es un `readonly record struct` con `Global`, `SucursalId` y `Tipo`, y constructor `internal`.
   - Solo lo fabrica `IAlcanceAlmacenes.ResolverAsync(TipoAlcance, ct)`, una vez por petición (memoizado en el *scoped*, AL-15).
   - `default(AlcanceResuelto)` equivale a **Vacío**. Un llamador que «se invente» el alcance obtiene cero filas, no todas.
   - Sin petición HTTP, `ResolverAsync` devuelve Vacío. Esto **responde la P-01 de C**: los procesos internos no necesitan un «Global», porque calculan con la firma interna y no con la de mostrar.
4. **R-05, código desconocido.** Si `idAlmacen` trae un código que no resuelve (`CatalogoService.cs:173`), la existencia es 0 sin consultar. Ya no pasa a ser nulo. Para el GLOBAL, es la P-05 de C, que sigue abierta para B.

**A.2.3 Lectura: el alcance va en la resolución del almacén, no en la suma**

| Ruta | Dónde se comprueba | Fuera del alcance |
|---|---|---|
| R-07 (`Consulta`, decisión 3) | Después de `ReferenciasNg.AlmacenAsync` (`InventarioService.cs:478`) y antes de leer artículos | El mismo «Almacén incorrecto.» que un código inexistente |
| R-08, detalle | Después de leer `h` (`:634`) y antes de `:638` | `null`, que da 404 |
| R-06 (`Operativo`) | Después de resolver `alm` (`LotesService.cs:26-27`) | `null`, que da 404 |

La comprobación es una sola función de P-0, `IAlcanceAlmacenes.IncluyeAsync(AlcanceResuelto, short almacenId)`, que compara por **Id**, nunca por código en C#. Así quedan fuera de juego los vectores V-01, V-02 y V-08 de intercalación.

**A.2.4 Fuga por el mensaje de error y por el guardado**

| Canal | Hoy [V] | Decisión |
|---|---|---|
| «Existencia insuficiente en el almacén: X (existencia N, requerido M)» (`LibroInventario.cs:95-98`) | Muestra la existencia del almacén que se mueve. Solo se alcanza **después** de `Permitido` (`:188-190`) | **Se acepta**: solo revela almacenes que el usuario puede mover, el mismo conjunto que `Operativo` (D-1). Sin cambio |
| «El almacén A es de la sucursal S; pida al administrador…» (`LibroInventario.cs:124-126`) | Revela el código del almacén y de su sucursal, sin cantidades | **Se acepta**: los mismos datos que `/api/catalogos/Almacenes` y `GET /transferencias/almacenes` (F-24) |
| Token viejo: el documento toma la sucursal del token (`InventarioService.cs:552`; `DocumentosNg.cs:73-80`; transferencias `Despacho.cs:77,118` según C) | `Permitido` se evalúa con la sucursal **vieja**, y el mensaje de faltante revela la existencia de sus almacenes | **401 en la puerta** (decisión 2, A.2.5) |
| Sucursal del token inexistente: `SucursalIdAsync` cae a la principal (`DocumentosNg.cs:79`) | Mueve, y por el mensaje ve, almacenes de la principal | Un código **no nulo** que no existe da 422 para todos. El nulo sigue en la principal para el no restringido (residuo 1, ya estimado en 3.3). El inicio de sesión del restringido exige una sucursal disponible (`UsuariosService.cs:766-772`), así que el caso solo aparece por un dato roto |
| Guardar artículo, «convertir en servicio» (`MaestrosService.Articulos.cs:304-306`) | Comprobación global; el mensaje no lleva cifras | **Se acepta**: un bit (tiene o no tiene) necesario para la integridad. Es F-05.6 de C, correcta |
| Guardar artículo, «Requiere lote» (`LotesDocumento.cs:156-168`) | **Fuga** [V]: «X tiene 18,00 unidades sin lote» o «…existencia en 3 lotes», con cifras **globales** (`:162`, `:165`) | La comprobación sigue global. Con un alcance que no es `Global`, el texto **sin cifras**: «X tiene existencia sin lote en la empresa…». Parámetro `bool conCifras` en `MotivoNoCambiarRequiereLoteAsync`; `MaestrosService` pasa `alcance.Global`. Va en E-1 (R-04, guardado) |

**A.2.5 Decisión 2 en detalle: la sucursal del token, validada en `Evaluar`**

- `TokenSesion` (`RevocacionSesiones.cs:228-238`) gana `Sucursal`, leída de `Claims.Sucursal`, que ya se emite (`Seguridad.cs:138`).
- `Evaluar` (`:169-181`) agrega, después del sello: si `cuenta.RestringirSucursal` y `!string.Equals(token.Sucursal?.Trim(), cuenta.SucursalDefault?.Trim(), OrdinalIgnoreCase)`, responde `ValorCredenciales`. Es la misma comparación que hace el inicio de sesión (`UsuariosService.cs:765-770`).
- Necesita los dos campos en `EstadoSesionUsuario`, que ya es el paso 1 de P-0. Costo por petición: una comparación de cadenas, sin E/S, porque la fila ya se leyó.
- Ventana: la de CS-3, como cualquier otra revocación: 15 s entre instancias e inmediata en la instancia que guarda, si quien guarda llama a `Olvidar`.
- **Alternativa descartada:** agregar el cambio de `RestringirSucursal` o `SucursalDefault` a la lista de CS-4 (`InvalidarCredencialesAsync`, `UsuariosService.cs:632-645`). Depende de que **todos** los caminos que escriben esas columnas lo llamen (ficha, importación, herramientas del SUPER). La comprobación en `Evaluar` cubre cualquier causa.
- **Efecto sobre lo ya decidido.** Para R-VIEJO-1 y R-VIEJO-3, «manda la del servidor» (P-0, punto 2) pasa a ser «el servidor rechaza el token». La restricción sigue saliendo del servidor (S-17). R-VIEJO-2 (le quitaron la restricción) no cambia: es GLOBAL.

### A.3 F-25: diseñador en la principal

**Hechos** [V]
- `POST /api/admin/reportes/detectar` y `/vista-previa` están en el grupo `RequiereAdmin()` y `SoloCentral` (`ReportesEndpoints.cs:82-84`, `:90-111`). Sin reenvío, llaman a `ReportesService.DetectarColumnasAsync` y `VistaPreviaAsync` (`ReportesService.cs:158-162`, `:289-295`). También Guardar y Eliminar pasan por `SoloAdmin()` (`:107`, `:146`), que solo comprueba `EsAdmin` (`:247-250`).
- Detectar ejecuta `SELECT TOP (0)` (`:406-415`): devuelve el esquema, **no filas**. La vista previa sí devuelve filas, de cualquier tabla y sucursal, con la fábrica de escritura (`:418-420`; es H-A06-01).
- La API de reportes ya cierra esto: `PuedeDisenar => EsAdmin && !RestringirSucursal` (`ContextoReportes.cs:42-43`), comprobado en detectar (`EjecutorDisenador.cs:236-243`) y en la vista previa (`ServicioReportes.cs:87-92`), con 403 `DISENO_NO_PERMITIDO` (`ErroresLectura.cs:162-163`). Para el diseñador, una columna de sucursal **declarada por el mismo ADMIN** no basta para confinarlo (`EjecutorDisenador.cs:283-286` filtra por la columna que él declara) [I]. Por eso negar el diseño al restringido es la única regla que falla cerrada.

**Decisión**

| Pieza | Dónde | Por qué |
|---|---|---|
| Paridad RS-06 en la principal: `SoloAdmin()` pasa a exigir `EsAdmin && alcance.Global` (P-0). Si no se cumple, 403 `DISENO_NO_PERMITIDO`, el mismo código y texto de la API de reportes | **E-1** (0,05 dp más 0,05 de pruebas) | Es una línea que consume P-0. Cubre detectar, vista previa y **Guardar** (H-A06-01) en Debug, y en todas las compilaciones mientras T4-06 no se una. No espera a la fecha de T4-06, que depende de PR-4 |
| `IDetectorColumnas` (T4-06, blueprint `:110-114`): la implementación Debug (`EsquemaAsync`) queda detrás de la misma comprobación. La Release (`DetectorColumnasReenvio`) **propaga** el 403 `DISENO_NO_PERMITIDO` de la API de reportes como 403, no como 503 | **T4-06** (0,05 dp) | La tabla de contratos de T4-06 (blueprint `:102`) solo prevé 503 en Guardar. Hay que añadir la fila del 403 |
| R-14 (`ejecutar` y `exportar` sin reenvío) | **T4-06**, por la Q-6: Release no arranca sin reenvío y el camino local queda solo en Debug (blueprint `:33`, `:129`) | Sale de S-16b (−0,1 dp), con una condición: si T4-06 no se une antes del corte de la entrega 1, vuelve a S-16b con el 403 `SUCURSAL_NO_PERMITIDA` de 3.2 |

El código de error es `DISENO_NO_PERMITIDO` y no `SUCURSAL_NO_PERMITIDA`, que proponían C (F-25.1) y la sección 3.2. Es el que ya devuelve la API de reportes para lo mismo, así que la interfaz ve un solo error en los dos caminos.

### A.4 Impacto en la partición de E-1

| Lote | Entra (sin cambio) | Se agrega o mueve con esta adenda |
|---|---|---|
| **E-1** (P-0, R-01, R-02, R-04) | Lo de 3.1 | P-0 con `AlcanceResuelto` (tipo cerrado, `default` igual a Vacío); regla de la sucursal del token en `Evaluar` (A.2.5); paridad RS-06 del diseñador (F-25); mensaje de lote sin cifras en el guardado del artículo (A.2.4) |
| **S-16b** (R-03, R-05 a R-14 y transferencias) | R-03, R-06, R-08 a R-13 y el residuo 1 de transferencias | R-05 con las dos firmas (A.2.2); R-07 en `Consulta`; **R-14 sale** (a T4-06, con la condición de A.3); el residuo 2 de transferencias y la P-13 de C quedan cubiertos por `Evaluar` (E-1), sin cambio por ruta |
| **T4-06** | Lo de su blueprint | Propagar el 403 `DISENO_NO_PERMITIDO` en Guardar por `IDetectorColumnas`; conservar la comprobación en el camino Debug |

**Orden:** E-1 antes que S-16b, sin cambio. T4-06 no depende de E-1. Si T4-06 se une antes, la paridad RS-06 de E-1 se escribe sobre el `ReportesService` ya partido, en el archivo de diseño, que no queda dentro del `#if DEBUG`. Es un conflicto menor de rebase.

### A.5 Esfuerzo (todo [I], ±40 %)

| Cambio | Lote | dp |
|---|---|---|
| `Evaluar` con la sucursal del token, más `TokenSesion.Sucursal` y pruebas unitarias | E-1 | +0,10 |
| `AlcanceResuelto` cerrado e `IncluyeAsync` por Id | E-1 | +0,05 |
| Paridad RS-06 en `ReportesService.SoloAdmin` y dos pruebas | E-1 | +0,10 |
| Mensaje de «Requiere lote» sin cifras | E-1 | +0,05 |
| AL-14 se simplifica: los R-VIEJO pasan a 401 | E-1 (pruebas) | −0,05 |
| **E-1** | | **+0,25** (de 1,45 a ~1,70 con mi base; de ~1,95 a ~2,20 con las pruebas de C) |
| Firma interna sin nulo, `ExistenciasVisiblesAsync` y la consulta nueva | S-16b | +0,10 |
| R-14 pasa a T4-06 | S-16b | −0,10 |
| F-26 ampliada (A.6) | S-16b (pruebas) | +0,05 |
| **S-16b** | | **+0,05** (~1,60; ~2,40 con C) |
| 403 propagado en `DetectorColumnasReenvio` y su prueba | T4-06 | +0,05 |
| **Total** | | **+0,35** |

### A.6 Pruebas que cambian respecto del plan de C

| ID de C | Cambio |
|---|---|
| V-RIESGO-1, F-26 | Se reescribe así: **F-26.1** sin cambio (ajuste de R1 en A3: 7 se aprueba; 8 se rechaza con «existencia 7,00»; ese mensaje es aceptable). **F-26.2** se parte en dos: borrador (`:586`, la foto vale 3) y aplicado (`:583-585`, la diferencia contra 3). **F-26.3** sin cambio (A4: 422 `AlmacenOtraSucursal`, sin cantidades). **Nuevas:** F-26.4 (TX): las dos `ExistenciasAsync` internas reciben `short` no anulable y el texto de `ConsultasInventario.Existencias` no contiene `IS NULL OR`. F-26.5 (SQL): `ExistenciasVisiblesAsync` con `default(AlcanceResuelto)` no devuelve filas. F-26.6 (HTTP): R-VIEJO-1 que guarda una salida de A4 recibe 401 `credenciales`, nunca un 422 con cifras. F-26.7: conteo de R1 en A3 da 422 `AlmacenOtraSucursal` (comportamiento actual, fija la decisión 3) |
| AL-10 | `Operativo` solo en R-05 y R-06 |
| AL-12 (P-01) | Se fija: sin petición, Vacío. Ningún proceso interno pide `Global`; calculan con la firma interna |
| AL-14 y la fila R-VIEJO de todas las matrices | R-VIEJO-1 y R-VIEJO-3 esperan **401** con el encabezado `credenciales`, no los datos de S1. R-VIEJO-2 sin cambio. Se agregan pruebas unitarias de `Evaluar`: restringido con sucursal distinta, 401; restringido con token sin sucursal, 401; no restringido con sucursal distinta, válido |
| F-13 | R1 con A3: «Almacén incorrecto.» (`Consulta`), igual que `ZZZ` |
| F-14.4 (P-07) | Se elimina: un restringido no puede contar en A3 |
| F-05.7 | Se concreta: para R1, el texto de «Requiere lote» no contiene ninguna cifra; para GLOBAL, el texto de hoy |
| F-20 | Pasa a T4-06: en Release, la prueba de Q-6 («no arranca sin reenvío»); el camino local, solo Debug. Vuelve a S-16b si se cumple la condición de A.3 |
| F-21.3 y F-21.7 (P-13) | 401 en vez de «usa S1» o «despacha con la sucursal vieja» |
| F-25.1 | Definitiva y en E-1: ADMIN-R recibe 403 `DISENO_NO_PERMITIDO` en detectar, vista previa, Guardar y Eliminar, sin reenvío. ADMIN-GLOBAL y SUPER sin restricción, igual que hoy. **Nuevas:** F-25.2 (T4-06): con reenvío, Guardar de ADMIN-R recibe 403 (no 503) y no ejecuta SQL en la principal. F-25.3 (TX): el texto y el código del 403 son los de `ErroresLectura.cs:162-163` |

### A.7 Preguntas abiertas para B

- **Q-A1 (decisión 3).** ¿Se corrige D-1 con R-07 en `Consulta`? Evidencia: `InventarioService.cs:556-562`. Recomiendo que sí.
- **Q-A2 (decisión 2).** ¿Se acepta el 401 `credenciales` para el restringido cuyo token trae otra sucursal, en lugar de «manda el servidor» con un aviso? Alternativa: un valor nuevo del encabezado (`sucursal`) para que la interfaz lo explique, con un texto de UX más. Recomiendo reutilizar `credenciales`.
- **Q-A3 (F-25).** La paridad RS-06 también impide al ADMIN restringido **guardar y eliminar** definiciones (`SoloAdmin` en `:107` y `:146`), no solo detectar y la vista previa. ¿Se acepta? Recomiendo que sí: guardar ejecuta SQL (H-A06-01).
- **Q-A4 (R-14).** ¿Pasa a T4-06 con la condición de A.3? ¿Se acepta que en Debug sin reenvío el restringido ejecute reportes sin filtro (solo en desarrollo)?
- **Q-A5 (coherencia con la P-02 de C).** RS-06 hoy trata como restringido para el diseño a **cualquier** ADMIN o SUPER con la bandera (`ContextoReportes.cs:43`). C propone que el SUPER nunca se restrinja. B elige una sola regla y se aplica igual en P-0 y en la API de reportes. Recomiendo la de RS-06, porque ya está construida y probada, y que el ADMIN no pueda poner la bandera a un SUPER.
- Siguen abiertas, sin cambio: las P-02 a P-06 y P-08 a P-12, P-14 y P-15 de C. Esta adenda responde la P-01 (A.2.2), la P-07 (Q-A1), la P-13 (A.2.5) y la parte de la P-10 sobre el diseñador (A.3).

### Cierre de la adenda
- Estado: Completado
- Artefactos: esta sección, al final de `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\rutas-inventario-sin-filtro-sucursal-2026-10-21.md`. No se borró nada de lo anterior.
- Supuestos:
  - Base b4378650.
  - `Despacho.cs:77,118` se toma de C, sin releerlo.
  - Que el ADMIN pueda saltarse el filtro con una columna de sucursal que él mismo declara es [I]; no se probó.
  - Los esfuerzos son [I].
- Decisiones candidatas a ADR: ninguna nueva. La decisión 2 y la paridad RS-06 son precisiones de TA-P08 (ADR-93) que B registra.
- Entregas a otros agentes:
  - backend: P-0 ampliado y A.2 a A.3 en E-1 y S-16b.
  - qa-automatizado (C): A.6.
  - auditor-seguridad: confirmar la aceptación de los dos mensajes de A.2.4 y lo [I] de A.3.
  - arquitecto-software de B / T4-06: la fila del 403 en el contrato de Guardar.
  - B: Q-A1 a Q-A5.
- Próximo paso recomendado: que B responda Q-A1 y Q-A2 antes de que empiece P-0, porque cambian la firma de `IAlcanceAlmacenes` y las matrices R-VIEJO.
