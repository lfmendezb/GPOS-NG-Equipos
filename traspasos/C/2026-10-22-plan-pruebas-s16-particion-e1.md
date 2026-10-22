```
Para: B        De: C        Fecha: 2026-10-22 (versión 2, 2026-10-22)
Tipo: Entrega (tarea 3 del aviso 2026-10-22: plan de pruebas del cambio de S-16, partición de E-1 de ADR-93) · versión 2: ajustada a Q-A1 a Q-A5
Prioridad: Media
Repositorio y rama: GPOS-NG `feature/modelo-ng` (el cambio se construye allí); fuentes en el área común
Estado: Abierto (plan, sin código; versión 2; sin revisión del auditor-seguridad)
```

# Plan de pruebas del cambio de S-16 (R-03, R-05 a R-14, transferencias, falla cerrada y guardado del artículo) — versión 2

**Fuentes de la versión 2:** `avisos/B-a-C/2026-10-22-q-a1-a-q-a5-ajusta-tu-plan-s16.md` (Q-A1 a Q-A5 aprobadas por el propietario según A) y la adenda de A `avisos/A-a-B/2026-10-22-adenda-s16-v-riesgo-1-y-f25.md`. **Regla de lectura:** donde el aviso de B solo nombra un ajuste (p. ej. «F-26.1 a F-26.7», «F-25.2 y F-25.3», «F-13») y la adenda no lo detalla, el contenido de la prueba lo **diseñé yo** a partir del texto de la adenda y lo marco **[D]**; B/A deben confirmarlo. Base de código re-leída: `origin/feature/modelo-ng` @ **`5237e11b`** (la v1 usó `b4378650`); solo re-verifiqué las líneas que cito como «v2».

## Cambios de la versión 2

| ID | Qué cambió | Por qué |
|---|---|---|
| F-26 (F-26.1 a F-26.7) | **Reescrito.** La v1 suponía que «existencia insuficiente» venía de `LibroInventario.ExistenciasAsync`; A corrigió: viene de un `UPDATE` atómico y solo la foto del borrador del conteo (`InventarioService.cs:586`) escribe. Ahora son 7 pruebas con **separación borrador/aplicado**, más la comprobación de las dos firmas (calcular / mostrar) | Adenda V-RIESGO-1, decisiones 1 y 2 |
| V-RIESGO-1 (§4) | Reescrito con la corrección y las dos firmas (`ExistenciasAsync` interna sin alcance y con almacén obligatorio; `ExistenciasVisiblesAsync(..., AlcanceResuelto)` solo para R-05) | Adenda, decisión 1 |
| AL-10 | `Operativo` ({A1,A2,A3}) **solo en R-05 y R-06**; R-07 pasa a `Consulta` | Q-A1 |
| AL-12 | **Fijado en Vacío** (sin petición/usuario ⇒ Vacío; `AlcanceResuelto` solo lo crea `IAlcanceAlmacenes`, valor por omisión Vacío). Se cierra P-01 | Adenda decisión 1 (responde P-01) |
| AL-13 | Se amplía: el **SUPER nunca se restringe** por la bandera (parametrizada sobre USER/ADMIN/SUPER con `RestringirSucursal=1`: USER y ADMIN ⇒ `Sucursal`, SUPER ⇒ `Global`). Se cierra P-02 | Q-A5 |
| AL-14 | R-VIEJO-1 y R-VIEJO-3 pasan a **401 `credenciales`**; R-VIEJO-2 se mantiene (GLOBAL, 200) | Q-A2 |
| AL-18 (nuevo) | Pruebas unitarias de `RevocacionSesiones.Evaluar` con la regla nueva (8 casos) | Q-A2, adenda decisión 2 |
| AL-19 (nuevo) | Contrato de tipos: `AlcanceResuelto` no se puede construir fuera de `IAlcanceAlmacenes` y su `default` es Vacío | Adenda decisión 1 |
| Matrices §5.1 a §5.10 | **R-VIEJO-1 y R-VIEJO-3 ⇒ 401 `credenciales`** en todas; **fila SUPER-R** (SUPER con la bandera de restricción) ⇒ igual que GLOBAL en todas | Q-A2, Q-A5 |
| F-10 (R-03) a F-19 (R-13) | Solo las celdas R-VIEJO/SUPER-R de arriba; sin otro cambio | Q-A2, Q-A5 |
| F-13 (R-07) | **Cambia de `Operativo` a `Consulta`**: R1 con A3 ⇒ «Almacén incorrecto» (igual que A4); F-13.4 nuevo | Q-A1 |
| F-14.4 | **Eliminada** (ya no hay discrepancia: R-08 `Consulta` y R-07 `Consulta` son coherentes). Se cierra P-07 | Q-A1 |
| F-05.7 | Se concreta la fuga nueva de «Requiere lote» (ficha **y** plantilla de importación; ver F-27): para un no global, mensaje **sin cifras**; GLOBAL sin cambio. F-05.7 (a, b, c) | Adenda, «Fuga nueva» |
| F-05.3, F-06.1, P-15 | Texto: «`Operativo` solo en R-05 y R-06» (antes «R-05..R-07») | Q-A1 |
| F-20 (R-14) | **Sale de S-16b y pasa a T4-06**: F-20 queda como prueba de T4-06 (403 en Release); el camino local de Debug se conserva | Q-A4 |
| F-21.3, F-21.7 | Pasan a **401 `credenciales`** (cierra P-13 sin ruta por ruta); F-21.3 y F-21.7 se vuelven pruebas de `Evaluar` + una integración | Q-A2 |
| F-25.1 | Pasa de «candidata» a **E-1**: paridad con la API de reportes (`PuedeDisenar`): detectar y vista previa ⇒ 403 al ADMIN restringido | Adenda F-25 |
| F-25.2 (nuevo) | **Guardar y Eliminar** definiciones de reportes ⇒ 403 al ADMIN restringido (también `SoloAdmin()` de `ReportesService`) | Q-A3 |
| F-25.3 (nuevo) | **T4-06:** `IDetectorColumnas` en Release propaga el **403**, no un 503; fila nueva en el contrato de Guardar | Adenda F-25, Q-A4 |
| Caso SUPER-R | Nuevo caso transversal (AL-13, AL-20, y una fila en cada matriz) | Q-A5 |
| AL-20 (nuevo) | La regla del SUPER es **una sola** para la principal y para la API de reportes (`ContextoReportes.PuedeDisenar`, hoy `EsAdmin && !RestringirSucursal`, restringiría al SUPER) | Q-A5 |
| F-27 (nuevo) | Fuga de «Requiere lote»: cobertura de **todas** las superficies que llaman a `LotesDocumento.MotivoNoCambiarRequiereLoteAsync` (ficha `MaestrosService.Articulos.cs:311` e importación `ImportacionMaestros.cs:389`) | Adenda «Fuga nueva» (verificado en código) |
| Preguntas | Cerradas: P-01, P-02, P-07, P-13 y la parte de P-10 sobre R-14. Nuevas: N-1 a N-5 (§10) | Q-A1 a Q-A5 |
| §8, §9, §11 | Orden de construcción, esfuerzo y «Qué no verifiqué» actualizados; la partición ahora es **E-1 / S-16b / T4-06** | Adenda «Efecto en la partición» |

**Reparto por lote tras la v2** (según la adenda): **E-1** = P-0, AL-xx, Evaluar (401), V-xx, guardado del artículo con «Requiere lote» (F-05..F-09, F-27), F-25.1/.2, F-26, F-21.3/F-21.7 y R-01/R-02/R-04; **S-16b** = F-10..F-19, F-21 (resto) y el barrido por rutas; **T4-06** = F-20 y F-25.3.

**Fuentes leídas:** `avisos/B-a-C/2026-10-22-tareas-nuevas-para-c.md` (punto 3), `avisos/B-a-A/2026-10-22-respuesta-s16-pr152-y-fechas-ola5.md` (D-1 a D-4), `traspasos/A/rutas-inventario-sin-filtro-sucursal-2026-10-21.md` (P-0, R-01 a R-14) y mi `traspasos/C/2026-10-22-plan-pruebas-e1-adr93-tarjetas.md` (§2 AL-xx, §3 F-xx). Código leído solo con `git show origin/feature/modelo-ng:<ruta>` (solo lectura). **Nada compilado ni ejecutado.**

## 0. Qué decidió B y qué cambia en mi plan previo

B adoptó **las cuatro recomendaciones de A sin modificarlas** (verificado línea por línea en la respuesta, §1):

| Decisión | Respuesta de B | Efecto en el plan |
|---|---|---|
| D-1 (**corregida en v2 por Q-A1**) | Sí. Alcance `Operativo` (propios + `SucursalAlmacenPermitido`) **solo en R-05 y R-06**; `Consulta` (propios) en las demás, **incluida R-07** (el conteo solo se guarda en almacenes de la propia sucursal) | Mi F-11/F-12 y AL-10 son **definitivas**; F-13 pasa a `Consulta`. Para R-05 y R-06 el oráculo es «GLOBAL si no existieran los almacenes que el restringido no puede mover» |
| D-2 | Sí, R-09 entra | F-15 deja de depender de D-2 |
| D-3 | Sí: un ADMIN con `RestringirSucursal` queda sujeto al alcance en las rutas de la lista; `/api/admin/*` como está, **salvo R-13 que pasa a 403** | Toda matriz gana una fila **ADMIN-R** (ADMIN restringido). F-19 pasa a definitiva. Nuevo AL-13 |
| D-4 | Fuera de TA-P08 y de E-1 (B lo lleva al propietario) | No se prueba. Queda como riesgo no cubierto (§9). Los indicadores de ventas/CxC/cobros del Tablero **no** deben ser tocados: se agrega una prueba de no-regresión (F-17.4) |
| Alcance | Lista completa (~3,0 dp); si aprieta, E-1 lleva P-0 + R-01, R-02, R-04 y el resto va **como cambio aparte antes del corte de la entrega 1** | El plan se parte en **lote E-1** (AL-xx, F-01..F-09, ya en mi plan previo) y **lote S-16b** (este documento: F-10..F-21, F-22, F-24, AL-11..AL-14, V-xx). Si B elige la partición, el lote S-16b no puede compilar sin P-0, así que **AL-01..AL-10 son prerrequisito de ambos** |
| Guardado | El guardado del artículo conserva las filas de niveles fuera del alcance | F-05..F-09 se **amplían** (§5.12) |
| Falla cerrada | Sin sucursal resoluble, conjunto vacío; la restricción sale del servidor, no del token (S-17) | AL-04/AL-05 se mantienen; se agregan AL-11 (Vacío también en `Operativo`) y AL-12 (contexto sin petición) |

**Correcciones a mis IDs anteriores** (todas porque B decidió):
1. F-10: ya no se «omite con motivo»; es definitiva (R-03 entra en la lista completa). Sigue omitible solo si B opta por la partición y la deja fuera del lote E-1.
2. F-11, F-12, F-13, AL-10: quitar la dependencia «D-1»; la prueba fija `Operativo`.
3. F-15 (D-2) y F-19 (D-3): definitivas; F-19 ahora distingue ADMIN restringido.
4. F-03: lo extiendo a **R-05** (código desconocido ≠ «todos»), porque A dice que ambas fallas abiertas se corrigen «para todos».
5. F-21: se parte en F-21.1..F-21.5 (las tres entradas de A: sucursal nula, desconocida, token viejo; más el residuo de reconciliación).
6. F-22 (barrido): se concreta en §7 con una propuesta; la pregunta Q-6 de mi plan previo pasa a P-03 de este documento.
7. Nuevo F-25 y F-26 (candidatos que A no listó, ver §1.2). **v2:** A los adoptó en su adenda y B los aprobó (Q-A1 a Q-A5); ya no están condicionados.
8. AM-03/AM-09 (rombos) y S-03 (`Total` del restringido) siguen igual; no cambian con D-1..D-4.

## 1. Verificación contra el código vivo

Base: `origin/feature/modelo-ng` @ **`b4378650`** (2026-10-22 14:46). A revisó `e3e729c1`. Verifiqué solo lo que se necesita para escribir las pruebas.

### 1.1 Rutas y líneas de A

| Elemento (A) | Estado | Evidencia |
|---|---|---|
| R-01 `ConsultasDocInventario.Existencias`, `WHERE (@almacen IS NULL OR al.Codigo = @almacen)` | **Coincide** (`:87-97`) | `ExistenciasAsync` `InventarioService.cs:723-736`; el parámetro es `Sql.Varchar(...,20)` |
| R-02 kárdex, falla abierta `almacenId = alm?.Id` | **Coincide** (`InventarioService.cs:744-745`; SQL `ConsultasDocInventario.cs:59-78`) | el código desconocido ⇒ `alm` nulo ⇒ `@almacen IS NULL` ⇒ todos |
| R-05 `CatalogoService.ArticuloAsync` | **Coincide** (`CatalogoService.cs:173-174`); SQL `ConsultasInventario.cs:226-229` (ruta real en `5237e11b`: `src/GPOS.Core/Consultas/Inventario/ConsultasInventario.cs`; sin releer sus líneas) | la existencia se calcula con `ReferenciasNg.ExistenciasAsync` → `LibroInventario.ExistenciasAsync`, que **también llama código de inventario** (`src/GPOS.Core/Servicios/InventarioService.cs:505, 586, 638`, verificadas en `5237e11b`). **Corrección de A (v2):** el «existencia insuficiente» de las escrituras sale de un `UPDATE` atómico, no de esa función; ver V-RIESGO-1 |
| R-03 `Existencia = SUM(...)` | **Coincide** (`MaestrosService.Articulos.cs:61`) | |
| R-04 lectura `:143-164`, guardado `RemoveRange` `:363-366` | **Coincide** | además `:304-306` suma **global** la existencia para impedir «convertir en servicio»: ver F-05.6 |
| R-06 `LotesService.DisponiblesAsync` | **Coincide** (`:22-31`); devuelve `null` si el almacén no existe ⇒ 404 | |
| R-07 `PrepararConteoAsync` | **Coincide** (`InventarioService.cs:475`) | la firma del servicio no recibe `categoria`, el endpoint sí la declara (`InventarioEndpoints.cs:66`): no afecta, pero el vector «parámetro repetido» debe probar también `categoria` ignorado |
| R-08 `ConteoAsync` `:629`, `BuscarConteosAsync` `:681` | **Coincide** | |
| R-09 `CargarAsync` `:48-100`, `BuscarAsync` `:84` | **Coincide** en la zona | |
| R-10 revisiones `LotesService.cs:50-78` | **Coincide** | |
| R-11 `ConsultasTablero.ValorInventario` `:68-77`, `DashboardService.cs:56` | **Coincide** | |
| R-12 `AvisosAsync` `DashboardService.cs:66-73` | **Coincide** | |
| R-13 `AdminEndpoints.cs:20-23` | **Coincide** (`SoloCentral` + `Permisos.Conciliacion`) | la consulta de existencia está en `ConciliacionService.cs:37` |
| R-14 `ReenvioReportes.Habilitado => Direccion no vacía` | **Coincide** (`ReenvioReportes.cs:39`) | |
| Transferencias `TransferenciasService.cs:62-82`, `:109-137`, `Recepcion.cs:118` | **Líneas movidas.** Hoy la sucursal sale de `DocumentosNg.SucursalIdAsync(u, sesion.Sucursal)` en `TransferenciasService.cs:64` y `:145`; la excepción de reconciliación está en `:74` y `:127`. En `Recepcion.cs` ya no hay referencia | el desarrollador debe re-ubicar; el residuo sigue vigente (`DocumentosNg.cs:73-80` coincide al pie de la letra) |
| P-0: `EstadoSesionUsuario` sin `RestringirSucursal`/`SucursalDefault` | **Líneas movidas**: el registro está en `UsuariosService.cs:920` (A: `:920-921`), el llenado en `:668-669` (A: `:670-671`) | la consulta ya trae ambos campos (`ConsultaEstadoSesion.cs:22`) |
| `RevocacionSesiones.Guardada(usuario)` `:140`, caché de 15 s `:83` | **Coincide** | |
| `IAlcanceAlmacenes` | **No existe todavía** (`git ls-tree` sin coincidencias) | las pruebas se escriben primero y deben fallar en rojo |

### 1.2 Rutas que A no listó y que las pruebas deberían cubrir (candidatas; B decide)

- **F-25 · `POST /api/reportes/diseno/detectar` y `/vista-previa`** (`ReportesEndpoints.cs:91-111`): **aceptado por A y B (v2)**. Sin reenvío ejecutan en la principal el SQL del diseñador sin filtro de sucursal. Decisión (adenda): paridad con la API de reportes (`ContextoReportes.PuedeDisenar => EsAdmin && !RestringirSucursal`, verificado en `src/GPOS.Reportes/Contexto/ContextoReportes.cs`), usando el alcance de P-0; bloquea detectar, vista previa, **Guardar y Eliminar** (`ReportesService.SoloAdmin()`, llamado en `ReportesService.cs:107, 146, 160, 293`; definido en `:247`). Detalle de pruebas en §5.11.
- **F-26 · Escritura de inventario y su lectura de existencia** (no es fuga de lectura, pero el alcance de R-05 no debe romperla): ver V-RIESGO-1 y F-26.1 a F-26.7 en §4.
- `GET /api/inventario/lotes/existe` (`InventarioEndpoints.cs:51`) no recibe almacén: no es un canal; lo dejo solo en el barrido (lista blanca).
- `CierreSucursalService.cs:60` y `ConsultasCierrePeriodo.cs`: procesos de la empresa con privilegio propio (A los deja fuera). Entran a la lista blanca del barrido con motivo.

## 2. Convenciones y fixture

- **Tipo:** SQL = base `GPOS_TEST_*` (`GPOST_TEST_SERVER`); HTTP = API en proceso con base; TX = texto/reflexión/contrato; UI = bUnit (Web) con espejo MAUI. Dependencia: `—` nada abierto; `P-0` = necesita `IAlcanceAlmacenes`; `P-xx` = pregunta a B (§10).
- **Trait:** `Esquema=NG`, `Categoria=Inventario`, `Categoria=Alcance`. Archivos nuevos propuestos: `AlcanceAlmacenesTests` (existente en mi plan previo), `FronteraInventarioTests` (F-xx por ruta, una clase por ruta para poder correr por clase en OSHIN-LEGION), `FronteraInventarioVectoresTests` (V-xx parametrizados), `FronteraInventarioBarridoTests` (F-22).
- **Fixture numérico** (cualquier fuga debe ser detectable por el valor, no solo por la presencia):

| Almacén | Sucursal | Existencia del artículo X | Notas |
|---|---|---|---|
| A1 | S1 | 3 | de R1 |
| A2 | S1 | 5 | de R1; mínimo 10 |
| A3 | S2 | 7 | **permitido** a S1 (`SucursalAlmacenPermitido(S1, A3)`) |
| A4 | S2 | 11 | **no** permitido a S1 |

  Costo promedio de X = 10. Cálculos de referencia: **Consulta de S1 = 8**, **Operativo de S1 = 15**, **GLOBAL = 26**; valor de inventario: 80 / (no aplica) / 260. Un segundo artículo Y solo con movimientos y lotes en A4 (para kárdex, lotes, conteos y revisiones). Conteos, documentos de inventario y revisiones de lote creados en A1 (de S1) y en A4 (de S2). Una sucursal S3 cerrada con existencia en A5 (para R-12).
- **Actores** (cada uno con su token): **GLOBAL** (`RestringirSucursal=0`, nivel USER, con los privilegios de la ruta); **ADMIN-GLOBAL**; **R1** (restringido, `SucursalDefault=S1`); **ADMIN-R** (nivel ADMIN, restringido a S1, D-3); **R-SIN-A** (restringido, `SucursalDefault` nula); **R-SIN-B** (restringido, `SucursalDefault` con código que no existe en `org.Sucursal`); **R-SIN-C** (restringido a una sucursal **inhabilitada**: ver P-05); **R-VIEJO-1** (token con claim S2, servidor dice S1 ⇒ **401 `credenciales`**, Q-A2); **R-VIEJO-2** (token con S1, el ADMIN ya le quitó la restricción ⇒ debe ser GLOBAL, 200); **R-VIEJO-3** (token con S1, el ADMIN lo restringió después a S2 ⇒ **401 `credenciales`**, Q-A2; antes «ve S2»); **SUPER**; **SUPER-R** (v2, Q-A5: SUPER cuya fila tiene `RestringirSucursal=1` ⇒ se comporta como GLOBAL en **todas** las matrices; la bandera se ignora).
- **Regla general de las matrices (v2):** toda fila R-VIEJO-1 y R-VIEJO-3 espera **401 con valor `credenciales`** (el mismo del cuerpo/cabecera de `RevocacionSesiones.ValorCredenciales`), sin cuerpo de datos y **antes** de llegar al servicio (la prueba verifica que no hubo lecturas de inventario). Toda matriz tiene una fila **SUPER-R ≡ GLOBAL**. R-VIEJO-2 sigue 200 como GLOBAL.
- **Oráculo general (`O`):** la respuesta de un restringido es **idéntica, campo por campo y byte por byte del JSON**, a la que daría GLOBAL **si la otra sucursal no existiera** (para `Consulta`: si no existieran A3 ni A4; para `Operativo`: si no existiera A4). Implementación en prueba: sembrar dos bases iguales, una con S2 y otra sin S2 (o con S2 vacío), pedir como GLOBAL en la segunda y como R1 en la primera y comparar. Esto detecta fugas por totales, conteos, paginación y mensajes de error, no solo por filas. Para R-SIN-x, el oráculo es «conjunto vacío» (200 con lista vacía / existencia 0 / 404 o 403 según la ruta, nunca el valor global).
- **Estas pruebas no se corren como suite completa en OSHIN-LEGION:** por clase.

## 3. Pieza común y falla cerrada (completa y corrige mi AL-xx)

AL-01 a AL-09 de mi plan previo se mantienen sin cambio. Cambia AL-10 y se agregan los siguientes.

| ID | Qué se comprueba | Tipo | Falla si… | Dep. |
|---|---|---|---|---|
| AL-10 (v2, Q-A1) | `Consulta` de S1 = {A1, A2}; `Operativo` de S1 = {A1, A2, A3}. A4 en ninguno. Con R-SIN, ambos = ∅. **`Operativo` solo lo piden R-05 y R-06**: prueba de contrato (TX) que R-07, R-08, R-09, R-10 y R-03/R-04/R-11/R-12 piden `Consulta` | SQL + TX | el `Operativo` omite `SucursalAlmacenPermitido`, el `Consulta` lo incluye, o R-07 pide `Operativo` | P-0 |
| AL-11 | `Vacío` también en `Operativo`: R-SIN-A/B no recibe los permitidos de ninguna sucursal (el `EXISTS` sobre `SucursalAlmacenPermitido` con `@sucursalAlcance = NULL` no devuelve nada) | SQL | el `Operativo` hace `OR` con una consulta de permitidos que ignora `@global/@sucursalAlcance` | P-0 |
| AL-12 (v2, **fijado en Vacío**; cierra P-01) | **Contexto sin petición HTTP** (hilos de fondo, `AbrirUnidadAsync(null)`; `CatalogoService.cs:158` ya lo usa con sesión nula): sin `ISesionActual` autenticado ⇒ `Vacío`, nunca `Global`. `AlcanceResuelto` solo lo crea `IAlcanceAlmacenes` y `default(AlcanceResuelto)` es Vacío. Un trabajo interno que necesite existencia global usa la firma interna «para calcular» (almacén obligatorio, sin alcance), no `ExistenciasVisiblesAsync` | SQL + TX | un llamador sin usuario obtiene `Global`; `default(AlcanceResuelto)` no es Vacío | P-0 |
| AL-13 (v2, Q-A5; cierra P-02) | Una sola prueba parametrizada sobre USER/ADMIN/SUPER con `RestringirSucursal=1`: USER y ADMIN ⇒ `Sucursal(S1)` (D-3); **SUPER ⇒ `Global`** (la bandera se ignora; **nunca** se restringe). Y SUPER con `RestringirSucursal=1` y `SucursalDefault` inexistente o nula ⇒ sigue `Global` (no cae a Vacío) | HTTP | el alcance solo se evalúa para USER; el SUPER hereda la restricción; el SUPER con sucursal ilegible queda en Vacío | P-0 |
| AL-14 (v2, Q-A2) | Cambios «en caliente»: R-VIEJO-1 (claim S2, servidor S1) ⇒ **401 `credenciales`**; R-VIEJO-2 (restricción quitada) ⇒ 200 GLOBAL; R-VIEJO-3 (restringido después a S2) ⇒ **401 `credenciales`**; y el cambio del **código** de la sucursal de S1: ver N-1 (qué espera la regla de `Evaluar` si `SucursalDefault` conserva el código viejo). Verifica además el **plazo**: la caché de la cuenta es de 15 s (`RevocacionSesiones`, ver N-2); la prueba fija si el 401 es inmediato (si el cambio de restricción invalida la caché) o dentro de 15 s | HTTP | el alcance cachea la sucursal del token; el token viejo recibe datos de la sucursal anterior | P-0, N-1, N-2 |
| AL-15 | El alcance se evalúa **una vez por petición**, y la consulta SQL usa los mismos valores en todas las lecturas de esa petición (dos consultas de la misma ruta, p. ej. R-04 niveles + existencias, no pueden ver alcances distintos si el ADMIN cambia la restricción entre medio) | HTTP | cada consulta relee | P-0 |
| AL-16 | `Global` solo se obtiene de `RestringirSucursal = 0` leído de la base; un `RestringirSucursal` nulo o ilegible ⇒ `Vacío` (dato corrupto cierra) | SQL | `ISNULL(RestringirSucursal,0)` convierte el nulo en global | P-0 |
| AL-17 | Prueba de contrato de SQL: cada consulta con `@global`/`@sucursalAlcance` declara `@global bit, @sucursalAlcance smallint` en `[ConsultaRegistrada]` (ADR-50: tipo y largo) | TX | alguien pasa `int` o `nvarchar` | — |
| AL-18 (nuevo, Q-A2; **unitarias de `Evaluar`**) | `RevocacionSesiones.Evaluar(cuenta, token)` es estática y pura (verificada en `src/GPOS.Api/Seguridad/RevocacionSesiones.cs:169`): 8 casos [D]. (1) restringido, token con su `SucursalDefault` ⇒ `null`. (2) restringido, token con otra sucursal ⇒ `"credenciales"` (R-VIEJO-1). (3) restringido a S2 después, token S1 ⇒ `"credenciales"` (R-VIEJO-3). (4) **no** restringido, token con cualquier sucursal ⇒ `null` (R-VIEJO-2). (5) **SUPER** con `RestringirSucursal=1` y token de otra sucursal ⇒ `null` (Q-A5). (6) **orden de comprobaciones:** token con sello malo **y** sucursal distinta ⇒ el motivo previo (`credenciales` del sello es el mismo valor; con `revocada`/`cerrada`/`reemplazada` prevalece el anterior: la regla nueva va **después** de las existentes y no cambia ninguna prueba actual de `Evaluar`). (7) comparación **ordinal** de cadenas (ver N-1): `s1` vs `S1`. (8) cuenta restringida con `SucursalDefault` nula y token con sucursal ⇒ ver N-1. Más una prueba de **no regresión**: la suite actual de `Evaluar` sigue en verde sin cambios | Unitaria (sin base) | la regla se agrega antes que el sello/revocación (cambia el motivo devuelto), o compara con `OrdinalIgnoreCase` sin decirlo, o evalúa al SUPER | P-0 (campos en `EstadoSesionUsuario`), N-1 |
| AL-19 (nuevo, Decisión 1) | Contrato de tipos (TX/reflexión): (a) `AlcanceResuelto` no tiene constructor público ni fábrica pública fuera de `IAlcanceAlmacenes`; (b) `default(AlcanceResuelto)` equivale a Vacío (AL-12); (c) `ExistenciasVisiblesAsync` exige un `AlcanceResuelto` (no admite `null`); (d) la firma interna «para calcular» exige almacén y **falla** si se le pasa nulo, no devuelve «todos» (el SQL de `ConsultasInventario.cs:224-230` deja de tratar el nulo como «todos»; prueba SQL con `@almacen = NULL` ⇒ error/0 filas) | TX + SQL | el SQL conserva `@almacen IS NULL OR …` en la firma interna | P-0 |
| AL-20 (nuevo, Q-A5) | **Una sola regla del SUPER para la principal y la API de reportes.** Prueba cruzada: SUPER con `RestringirSucursal=1` puede diseñar (detectar, vista previa, guardar, eliminar) en la principal **y** en `GPOS.Reportes` (`PuedeDisenar` hoy `EsAdmin && !RestringirSucursal` lo bloquearía; debe cambiar a «SUPER siempre / ADMIN solo sin restricción»). La prueba de la API de reportes vive en `tests/GPOS.Reportes.Tests` (equipo B); aquí queda la mitad de la principal y una prueba TX que compara ambos predicados con la misma tabla de verdad (USER/ADMIN/SUPER × restringido sí/no) | HTTP + TX | las dos reglas difieren | P-0, N-3 |

## 4. Vectores adversarios transversales (V-xx, una vez cada uno, parametrizados sobre la capa común)

Se corren contra **las rutas que reciben un código de almacén**: R-01 `?almacen=`, R-02 `?almacen=`, R-05 `?almacen=`, R-06 `almacen`, R-07 `almacen`, y contra los DTO del guardado del artículo (`IdAlmacen`). Se repiten con **R1** y con **R-SIN-A**. Oráculo para todos: **nunca devuelve datos de A4 ni de A3 (salvo `Operativo` para A3)**, y el resultado es idéntico al de un código inexistente.

| ID | Entrada hostil (valor de `almacen`) | Esperado | Falla si… |
|---|---|---|---|
| V-01 | Mayúsculas/minúsculas: `a4`, `A4`, `a4 ` (la intercalación es `CI_AS`, así que `a4` casa con `A4` en SQL) | Se trata igual que `A4`: fuera de alcance ⇒ vacío/404/0. **No** debe eludir el filtro por escribirse distinto ni ser tratado como «desconocido ⇒ todos» | el alcance compara en C# con `==` ordinal (A4 fuera, `a4` «desconocido» ⇒ sin filtro) |
| V-02 | Espacios: `" A4"`, `"A4 "`, `"A4\t"`, `"A 4"` | Mismo trato que el código real tras `Trim()` o rechazo; nunca «todos» | el recorte y el filtro difieren (se recorta para buscar y no para filtrar) |
| V-03 | Cadena de solo espacios `"   "` y vacía `""` | = «sin almacén» **solo si así lo decide B** (P-04); si es «sin almacén», se aplica la suma/lista **del alcance**, nunca la global | «sin almacén» devuelve global |
| V-04 | Comodines `%`, `_`, `A%`, `%4`, `[A-Z]4` (el código se usa con `=` en R-01 y por `Codigo` en `ReferenciasNg`; no hay `LIKE`) | Tratado como código inexistente ⇒ vacío; **no** casa con A4 | alguien cambia a `LIKE '%'+@almacen+'%'` |
| V-05 | Comillas/inyección: `A1' OR 1=1 --`, `A1"; DROP`, `';--` | Inexistente ⇒ vacío; sin 500; sin error SQL en el cuerpo | el parámetro no está tipado (ADR-50) o se concatena |
| V-06 | Id numérico: el `Id` de A4 (`"4"` o `"13"`) en lugar de su código | Inexistente (no se busca por `Id`) ⇒ vacío. Probar también que el **Id de A1** no resuelve A1 por accidente | la resolución acepta `Id` o convierte `varchar`→`int` implícito |
| V-07 | Parámetro repetido: `?almacen=A1&almacen=A4` y `?almacen=A4&almacen=A1` | Una de dos y fijada en la prueba: 400, o un solo valor (el primero/último) **ya filtrado**; nunca la unión | el binder toma una lista y el servicio usa `.First()` antes del filtro |
| V-08 | Valor Unicode/normalización: `Ａ４` (ancho completo), `A4` con `\u200b`, `Á4` (varchar con `CP1252`) | Inexistente ⇒ vacío | el servicio normaliza distinto del filtro |
| V-09 | Largo: 21, 100, 8000 caracteres | 400 o vacío; sin 500; el parámetro es `varchar(20)` (CP-169) | truncamiento silencioso a 20 que convierte `A4XXXXXXXXXXXXXXXXXXXX` en `A4` |
| V-10 | Cabeceras falsificadas: `X-Sucursal: S2`, `X-Empresa`, `Sucursal` en el cuerpo/consulta (`?sucursal=S2`) | Sin efecto (AL-06) | un middleware lee la cabecera |
| V-11 (v2, Q-A2) | Token de S2 con código de almacén de S1 y viceversa (token cruzado), con un restringido | **401 `credenciales`** antes de llegar al servicio (ya no «manda el servidor»); para un token coherente con el servidor, el alcance sale de la base (AL-03) | el alcance usa el claim; la petición llega al servicio con datos |
| V-12 | `?articulo=` hostil en R-02/R-06 (código de artículo que casa con un `ArticuloCodigo` alterno) | No cambia el alcance de almacén | la resolución de artículo abre otro camino |

Nota para B: V-01/V-02 son los que más valor tienen porque la intercalación es `SQL_Latin1_General_CP1_CI_AS` (CLAUDE.md): en SQL `a4 = A4`, así que un filtro hecho en C# con comparación ordinal falla justo ahí.

### V-RIESGO-1 (la mutación más probable del cambio) — reescrito en v2

**Corrección de A (adenda):** el «existencia insuficiente» de ajuste/conduce **no** sale de `LibroInventario.ExistenciasAsync` sino de un `UPDATE` atómico (`ConsultasInventario.cs:13-39`), después de comprobar que la sucursal del documento puede mover el almacén (`LibroInventario.cs:169-190`). De las tres llamadas que mi v1 llamó «de escritura» (`InventarioService.cs:505, 586, 638`), solo `:586` (la foto del borrador del conteo) escribe; `:505` y `:638` son lecturas. **Decisión 1 de A:** dos firmas: «para calcular» (interna: almacén obligatorio, sin alcance, el SQL ya no trata el nulo como «todos») y `ExistenciasVisiblesAsync(..., AlcanceResuelto)` (falla cerrada, solo R-05).

**Mutación que se vigila:** el desarrollador aplica el alcance dentro de la función compartida, o deja que la firma «para calcular» reciba alcance. Efecto: el restringido que descuenta, ajusta o cuenta en un almacén permitido ve un «insuficiente» falso, o la foto del conteo guarda 0; el GLOBAL no se afecta, así que las pruebas de GLOBAL no lo detectan. **Separación borrador/aplicado** [D]: el borrador del conteo **escribe** una foto (`:586`) y por eso depende de la firma «para calcular»; el conteo aplicado lee la foto/corte guardada y no vuelve a calcular; el detalle del borrador (`:638`, rama `aplicado == false`) **lee** la existencia actual y está detrás del alcance de la ruta R-08.

| ID | Caso (fixture §2) | Esperado | Falla si… |
|---|---|---|---|
| F-26.1 | R1 hace un ajuste de **salida de 7 en A3** (permitido a S1, existencia 7) y otro de **8** | 7 ⇒ aprobado, existencia final 0; 8 ⇒ rechazado «existencia insuficiente» con las cifras **de A3** (el almacén del propio movimiento) | el alcance `Consulta` se coló en el cálculo y A3 vale 0 |
| F-26.2 | **Conteo en borrador:** R1 guarda en A1 un conteo (`InventarioService.cs:586`) | la foto del sistema por artículo es la existencia de A1 (3 para X), no 0 y no la global | la foto usa la firma «visible» o un alcance Vacío |
| F-26.3 | **Conteo aplicado:** R1 aplica ese conteo con físico 5 | diferencia = 5 − 3 = +2, calculada contra la **foto del borrador/corte**, aunque entre medias entre una venta en A1 (la foto no se recalcula) | la aplicación relee con alcance, o recalcula |
| F-26.4 | **Detalle del borrador vs aplicado** (`:638`): R1 abre el conteo en borrador de A1 y el aplicado de A1 | borrador: existencia actual de A1; aplicado: la del corte. Un conteo de A4 ⇒ 404 por R-08 (no llega al cálculo) | el detalle aplicado muestra existencia actual, o el del borrador muestra la global |
| F-26.5 | **Conduce de R1 pidiendo A4** (fuera de la sucursal): rechazo | se rechaza por el motivo que hoy ya existe (almacén no permitido, disparador 51309), **mensaje sin cambio** y sin cifras de A4 | el mensaje cambia o revela la existencia de A4 |
| F-26.6 | **Decisión 2, fuga por el guardado:** R-VIEJO-1 (token S2, servidor S1) intenta un ajuste/conduce con faltante | **401 `credenciales`** antes de entrar al servicio (cierra la fuga: antes el documento tomaba la sucursal del token, `DocumentosNg.cs:73-80`, y el mensaje de faltante mostraba existencias de la sucursal anterior). Variante: R-VIEJO-3. Ninguna fila escrita, numeración sin consumir | el documento se crea con la sucursal del token, o el mensaje de faltante trae cifras |
| F-26.7 | **GLOBAL y firma interna (regresión):** GLOBAL hace los mismos ajuste (A4, 11), conteo borrador y aplicado que hoy; la firma «para calcular» con almacén nulo no devuelve la suma de todos (AL-19) | idéntico a hoy en GLOBAL; la firma interna con nulo falla/0 | cualquier cambio de comportamiento del GLOBAL en escritura |

- Falla si… el alcance se coló en la función que sirve a la escritura. Se ejecuta **al final de cada ruta tocada** (§8). Tipo: SQL + HTTP. Dep.: P-0, AL-19, AL-18. **[D]**: el contenido de F-26.1 a F-26.7 es mío; la adenda solo da el número y «separación borrador/aplicado».

## 5. Plan por ruta

Para cada ruta: **matriz** (GLOBAL / restringido con sucursal / restringido sin sucursal resoluble / token viejo), **oráculo**, **vectores**, **tipo**, **falla si…** y **dependencia**. Los valores esperados usan el fixture del §2. «ADMIN-R» se prueba igual que R1 y se anota con `(=R1)`. Ante dos restringidos, R-SIN-A/B/C esperan lo mismo y se parametrizan en una sola prueba.

Prerrequisito común de todas: `P-0` y AL-01..AL-17.

### 5.1 R-03 · `GET /api/maestros/articulos` (lista) · F-10

| Actor | Esperado (`Existencia` del artículo X) |
|---|---|
| GLOBAL / ADMIN-GLOBAL | 26 (hoy) |
| R1 / ADMIN-R | 8 (Consulta; A3 **no** cuenta porque R-03 es `Consulta`) |
| R-SIN-A/B/C | 0 en todos los artículos (200 con la lista completa de artículos y existencia 0; los artículos **no** se filtran, TA-P08 filtra existencias, no artículos) |
| R-VIEJO-1 / R-VIEJO-3 | **401 `credenciales`** (v2, Q-A2) · R-VIEJO-2: 26 |
| SUPER-R (v2, Q-A5) | 26 (≡ GLOBAL; la bandera se ignora) |

- Oráculo: la lista de R1 es igual a la de GLOBAL en una base donde S2 no tiene existencias; y `Total`/orden/cantidad de filas **idénticos** a GLOBAL (el alcance solo toca la columna `Existencia`).
- **F-10.1** un artículo con existencia **solo** en A4 aparece en la lista de R1 con existencia 0 (y no desaparece; fija Q-3). **F-10.2** el tope de 500 filas no cambia. **F-10.3** el contrato de `ArticuloFila` no cambia (compara con P-09 de mi plan previo).
- Vectores: no recibe almacén; solo `texto/categoría` (el filtro de texto no debe poder usarse para inferir existencia en S2, p. ej. ordenar por existencia: verificar que **no existe** parámetro de orden por existencia).
- Tipo: HTTP + SQL. **Falla si…** la suma sigue sobre `ng.Existencias` sin condición de almacén (LINQ `Where(e => e.ArticuloId == a.Id).Sum(...)`, `MaestrosService.Articulos.cs:61`), o si el filtro se aplica a **artículos** en lugar de a existencias. Dep.: P-0.
- Mutación mental adicional: el desarrollador cambia la suma a `Consulta` con `Contains` sobre una lista de `Id`s grande (N+1 o 2100 parámetros): no es de correctitud, pero la prueba con 500 filas debe correr en tiempo razonable (informe, no umbral).

### 5.2 R-05 · `GET /api/catalogos/articulos/{codigo}/linea` · F-11 (alcance `Operativo`)

Solo exige `RequireAuthorization`, **sin permiso** (`DocumentosEndpoints.cs:11`): la matriz incluye un usuario sin ningún privilegio de inventario (SIN-PRIV).

| Actor | `?almacen=` | Esperado `Existencia` |
|---|---|---|
| GLOBAL | A4 | 11 |
| GLOBAL | (sin almacén) | 26 |
| GLOBAL | `ZZZ` (desconocido) | **0** (corrección: antes era 26 por «desconocido ⇒ todos»; A pide corregir «para todos»: **P-05**) |
| R1 / ADMIN-R / SIN-PRIV restringido | A1 | 3 |
| R1 | A3 (permitido) | 7 |
| R1 | A4 (no permitido) | 0 |
| R1 | (sin almacén) | 15 (suma `Operativo`) |
| R1 | `ZZZ` | 0 |
| R-SIN-A/B/C | cualquiera, incluso sin almacén | 0 |
| R-VIEJO-1 / R-VIEJO-3 | cualquiera | **401 `credenciales`** (v2, Q-A2) · R-VIEJO-2: A4 → 11 (ya no restringido) |
| SUPER-R (v2, Q-A5) | A4 / sin almacén / `ZZZ` | 11 / 26 / 0 (≡ GLOBAL) |

- Oráculo: R1 = GLOBAL si no existiera A4. Además la respuesta de R1 con A4 es **idéntica** (misma forma JSON, mismos campos, mismo estado 200) a la de `ZZZ`: sin canal lateral entre «fuera de alcance» e «inexistente».
- **F-11.1** `ArticuloLinea` conserva `Inhabilitado`, `UnidadBase`, `ControlLote`, precio y todo lo demás sin cambio (el alcance solo cambia `Existencia`): comparar el resto del JSON con el de GLOBAL campo por campo.
- **F-11.2** artículo **no inventariable**/servicio: `Existencia = 0` sin consultar (`CatalogoService.cs:171` no entra): sin cambio.
- **F-11.3** regresión del POS: GLOBAL sin almacén sigue dando la suma global; el POS (que pasa el almacén de la sucursal) da la existencia de ese almacén. Es la prueba más importante para no romper venta.
- **F-11.4** otros llamadores de `CatalogoService.ArticuloAsync` (`ArticuloLineaAsync` `:185-200`, y los que llamen a `ArticuloAsync` en conduces/devoluciones): el valor `Existencia` que reciben es el del alcance; nada **de escritura** depende de él (ver V-RIESGO-1).
- Vectores: todos V-01..V-12.
- Tipo: HTTP + SQL. **Falla si…** (a) un código desconocido sigue produciendo `almacenId = null` (`CatalogoService.cs:173-174` con `almacen?.Id`) para el restringido; (b) el alcance se pasa como `NULL` al SQL `ConsultasInventario.Existencias` y `@almacen IS NULL` lo toma como «todos» (el patrón `OR` de `ConsultasInventario.cs:228` **no es falla cerrada**: tiene que cambiar a `@global/@sucursalAlcance` o la prueba de R-SIN falla); (c) `Operativo` se implementa como `Consulta`. Dep.: P-0, **P-04** (vacío = «sin almacén»), **P-05** (GLOBAL con desconocido ⇒ 0).

### 5.3 R-06 · `GET /api/inventario/lotes-disponibles` · F-12 (`Operativo`)

| Actor | `almacen` | Esperado |
|---|---|---|
| GLOBAL | A4 | lotes de Y en A4 |
| R1 | A1 | sus lotes |
| R1 | A3 (permitido) | sus lotes (puede moverlo) |
| R1 | A4 | **404**, idéntico (estado, cuerpo, cabeceras) al de un almacén inexistente |
| R-SIN-A/B/C | A1 | 404 (nada es alcanzable) |
| R-VIEJO-1 / R-VIEJO-3 | A4 | **401 `credenciales`** (v2, Q-A2) · R-VIEJO-2: lotes de A4 |
| SUPER-R (v2, Q-A5) | A4 | lotes de A4 (≡ GLOBAL) |

- Oráculo: R1/A4 ≡ `ZZZ` (404 con el mismo cuerpo `ReglaNegocio`/ProblemDetails); un artículo inexistente con almacén válido ⇒ también 404, así que la prueba compara las **tres** combinaciones inexistente/ fuera de alcance/ ambos desconocidos para que no haya canal lateral por mensaje distinto (S-05).
- **F-12.1** el listado `Vencido` se calcula con la fecha (sin cambio) y no filtra lotes por sucursal además del almacén.
- **F-12.2** lotes de **A4 con artículo X** y almacén A1 del restringido: la respuesta de A1 no incluye lotes que existan en otros almacenes (el SQL `ConsultasLotes.Disponibles` ya filtra por almacén; regresión).
- Falla si… `DisponiblesAsync` resuelve `alm` y no comprueba alcance (`LotesService.cs:26-27`) o el 404 se vuelve 403 (revela existencia). Tipo: HTTP + SQL. Dep.: P-0.

### 5.4 R-07 · `GET /api/inventario/conteos/preparar` · F-13 (alcance `Consulta`; v2, Q-A1)

| Actor | `almacen` | Esperado |
|---|---|---|
| GLOBAL | A4 | hoja de conteo de A4 (existencia y costo) |
| R1 | A1 | su hoja |
| R1 | A3 (permitido, pero R-07 es `Consulta`) | «Almacén incorrecto», idéntico al de A4 y `ZZZ` (v2, Q-A1: antes devolvía la hoja) |
| R1 | A4 | «Almacén incorrecto», idéntico al de `ZZZ` |
| R-SIN-A/B/C | A1 | «Almacén incorrecto» |
| R-VIEJO-1 / R-VIEJO-3 | A4 | **401 `credenciales`** (v2, Q-A2) |
| SUPER-R (v2, Q-A5) | A4 | hoja de A4 (≡ GLOBAL) |

- Oráculo: ≡ `ZZZ` en estado, mensaje y forma.
- **F-13.1** `costo` sigue oculto sin «Ver costos» (`[DatoCosto]`): R1 sin privilegio ⇒ costo ausente aun en A1.
- **F-13.2** los filtros `clasificacion/valor/texto` no amplían el alcance (p. ej. `clasificacion=categoria&valor=` de una categoría con artículos en A4: la hoja de A1 sigue mostrando existencias de A1).
- **F-13.3** tope de 3000 artículos sin cambio.
- **F-13.4 (v2, Q-A1)** [D] coherencia con el guardado: R1 no puede preparar la hoja de A3 **y** tampoco guardar un conteo en A3 (`InventarioService.cs:556-562`: el conteo solo se guarda en almacenes de la propia sucursal); la prueba cruza ambos: todo almacén que `preparar` acepta es uno donde el conteo se puede guardar, y viceversa. Falla si R-07 sigue en `Operativo`.
- Falla si… se valida el alcance después de leer las existencias, o el error es otro texto (canal lateral). Tipo: HTTP + SQL. Dep.: P-0.

### 5.5 R-08 · conteos: lista `GET /conteos` y detalle `GET /conteos/{numero}` · F-14 (`Consulta`)

| Actor | Lista | Detalle de un conteo de A4 | Detalle de uno de A1 |
|---|---|---|---|
| GLOBAL | todos | 200 | 200 |
| R1 / ADMIN-R | solo los de A1/A2 | **404** ≡ número inexistente | 200 |
| R-SIN-A/B/C | lista vacía (200) | 404 | 404 |
| R-VIEJO-1 / R-VIEJO-3 | **401** | **401** | **401** (v2, Q-A2) |
| SUPER-R (v2, Q-A5) | todos | 200 | 200 |

- Oráculo: la lista de R1 ≡ la de GLOBAL en una base sin S2; el **número** consumido no se revela: la numeración es por serie/jornada (ADR-45), así que en la lista del restringido pueden verse **saltos** de numeración que delatan conteos ajenos. **P-06**: ¿es aceptable? (prueba **F-14.1**, fijando la decisión: no se oculta el hueco porque los números son visibles y el modelo de numeración es por empresa).
- **F-14.2** el valor de la diferencia (costo) respeta «Ver costos».
- **F-14.3** `BuscarConteosAsync` con filtros `texto/desde/hasta` no devuelve conteos de A4 por coincidencia de texto en el almacén.

- Falla si… el detalle filtra por alcance pero la lista no (o al revés); el 404 se convierte en 403. Tipo: HTTP + SQL. Dep.: P-0, P-06. (v2: F-14.4 y P-07 eliminadas por Q-A1: R-07 y R-08 son ambas `Consulta`; un restringido no cuenta en A3, así que no hay conteo propio oculto.)

### 5.6 R-09 · documentos de inventario `GET /documentos/{tipo}` y `/{numero}` · F-15 (`Consulta`, D-2 resuelto)

Tipos: `Entrada`, `Conduce`, `Ajuste` (los tres con almacén).

| Actor | Lista | Detalle de A4 |
|---|---|---|
| GLOBAL | todos | 200 |
| R1 / ADMIN-R | solo A1/A2 | 404 ≡ inexistente |
| R-SIN-A/B/C | vacía | 404 |
| R-VIEJO-1 / R-VIEJO-3 | **401** | **401** (v2, Q-A2) |
| SUPER-R (v2, Q-A5) | todos | 200 |

- **F-15.1** el total al costo (`Ver costos`) del listado de R1 suma solo los documentos visibles (oráculo: igual a GLOBAL sin S2).
- **F-15.2** coherencia con kárdex (R-02): todo documento que aparece en el kárdex de R1 es visible en su lista, y todo documento que no es visible no aparece en ningún kárdex de R1 (propiedad cruzada R-02 ↔ R-09).
- **F-15.3** `NuevoAsync`/`EntradaDesdeOrdenAsync` no se tocan (sin existencias): no-regresión.
- **F-15.4** un documento con líneas en varios almacenes (si el modelo lo permite; **[I]**: `AlmacenId` es del encabezado en `CargarAsync`, así que el documento es de un solo almacén) ⇒ la prueba lo confirma o se anota.
- **F-15.5** el detalle de un documento **anulado** de A4 también es 404.
- Falla si… el alcance se aplica a `BuscarAsync` pero no a `CargarAsync`, o el detalle se resuelve por `DocumentosNg.PorNumeroAsync` (`InventarioService.cs:56`) que ignora el almacén y luego `ConsultasDocInventario.PorId`: **el `404` hay que verificarlo en el SQL del detalle, no solo en la lista.** Tipo: HTTP + SQL. Dep.: P-0.

### 5.7 R-10 · revisiones de lote (`GET /revisiones-lote`, `/{id}`, `/abiertas/cantidad`) · F-16 (`Consulta`)

| Actor | Lista | `/{id}` de A4 | `/abiertas/cantidad` |
|---|---|---|---|
| GLOBAL | todas | 200 | N total |
| R1 / ADMIN-R | solo A1/A2 | 404 | cuenta solo las abiertas del alcance |
| R-SIN | vacía | 404 | 0 |
| R-VIEJO-1 / R-VIEJO-3 | **401** | **401** | **401** (v2, Q-A2) |
| SUPER-R (v2, Q-A5) | todas | 200 | N total |

- **F-16.1** `ExistenciaLote` y `Cantidad` de las revisiones visibles son las de su almacén (el SQL `ConsultasLotes.cs:86` suma `inv.ExistenciaLote` **por `LoteId` sin filtrar almacén**: **verificar si `inv.ExistenciaLote` está ligado a almacén**; si no lo está, `ExistenciaLote` mezcla almacenes y es una fuga numérica aun con la fila filtrada. **[I]**, no leí el esquema; prueba **F-16.2**: lote X con existencia 4 en A1 y 6 en A4 ⇒ para R1 `ExistenciaLote` = 4).
- **F-16.3** el contador del menú coincide con el número de filas abiertas de la lista del mismo actor (propiedad).
- **F-16.4** `resolver` (POST) de una revisión de A4 por R1 ⇒ 404 (el alcance de lectura no debe dejar una puerta de **escritura** abierta; si hoy no existe tal comprobación, es un hallazgo aparte, no de esta lista: anotar y avisar). Tipo: HTTP + SQL.
- Falla si… el contador `abiertas/cantidad` queda global (es la ruta más fácil de olvidar: no devuelve filas, solo un número). Dep.: P-0.

### 5.8 R-11 · `GET /api/reportes/dashboard/indicadores` · F-17 (`Consulta`)

| Actor | «Valor del inventario» (solo X con costo 10) |
|---|---|
| GLOBAL con «Ver costos» y `ReportesInventario` | 260 |
| R1 / ADMIN-R | 80 (A1+A2) |
| R-SIN | 0 |
| R-VIEJO-1 / R-VIEJO-3 | **401 `credenciales`** (v2, Q-A2) · R-VIEJO-2: 260 |
| SUPER-R (v2, Q-A5) | 260 (≡ GLOBAL) |

- Oráculo: R1 ≡ GLOBAL sin S2, para **todos** los KPI de la respuesta (no solo el valor).
- **F-17.1** sin «Ver costos» el valor sigue ausente/0 (privilegio primero, alcance después).
- **F-17.2** el redondeo «por fila» (`ConsultasTablero.cs:68-77`: coincide con `rptc.ExistenciaActual.Valor`, reporte 17) se conserva en el alcance: la suma de redondeos por fila del alcance, no el redondeo de la suma (con costos de 6 decimales, un caso que difiera por 0,01).
- **F-17.3** la comparación contra el período anterior (`periodo`) no vuelve a leer global.
- **F-17.4** (D-4) los KPI de **ventas, CxC y cobros** no cambian para R1: son los mismos que GLOBAL. Es una prueba que **fija** que D-4 no se coló (si B más adelante la acepta, se invierte; ver `En_D1_...` como precedente de inversión controlada).
- Falla si… `TotalAsync(db, ConsultasTablero.ValorInventario, ...)` (`DashboardService.cs:56`) sigue sin parámetros y el SQL no tiene `WHERE`. Tipo: HTTP + SQL. Dep.: P-0.

### 5.9 R-12 · `GET /api/reportes/dashboard/avisos` · F-18 (`Consulta`)

| Actor | Esperado |
|---|---|
| GLOBAL | un aviso por sucursal cerrada con existencias (S3 con A5) |
| R1 | **ninguno** (S3 no es su sucursal; no se revela que existe una sucursal cerrada) |
| R de S3 (restringido a una sucursal cerrada) | **P-08:** ¿ve el aviso de su propia sucursal? (propuesta: sí; es su sucursal) |
| R-SIN-A/B/C | ninguno |
| R-VIEJO-1 / R-VIEJO-3 | **401 `credenciales`** (v2, Q-A2) |
| SUPER-R (v2, Q-A5) | un aviso por sucursal cerrada con existencias (≡ GLOBAL) |

- Oráculo: lista vacía idéntica a la de una empresa sin sucursales cerradas.
- **F-18.1** el texto del aviso no incluye totales de otras sucursales (el código y nombre de la sucursal son el dato de fuga hoy).
- Falla si… se filtra por nombre/código de sucursal comparando en C# con otra intercalación que la del servidor. Tipo: HTTP + SQL. Dep.: P-0, P-08.

### 5.10 R-13 · `GET /api/admin/diagnostico/conciliacion` · F-19 (403 al restringido)

| Actor | Esperado |
|---|---|
| GLOBAL con `Conciliacion` / SUPER | 200 con la conciliación **completa** (como hoy) |
| R1 / ADMIN-R con `Conciliacion` | **403** |
| R-SIN-A/B/C con `Conciliacion` | 403 (nunca 200 vacío: falla cerrada) |
| R-VIEJO-1 / R-VIEJO-3 | **401 `credenciales`** (el 401 va antes que el 403; v2, Q-A2) · R-VIEJO-2 (ya global): 200 |
| SUPER-R con `Conciliacion` (v2, Q-A5) | **200** completa (≡ GLOBAL; es el caso que más importa: el SUPER con bandera no cae en el 403 de R-13) |

- Oráculo: el 403 es el mismo para **todas** las comprobaciones (`?comprobacion=` cualquiera de las 8 definiciones de `ConciliacionService.cs:37-59`, no solo la de existencia) y para `tope` cualquiera: probar con la comprobación de **CxC** (que no es de inventario): ¿también 403 o solo la de existencia? **P-09** (A dijo «es un diagnóstico de la empresa»; si el 403 es por endpoint, se prueba por endpoint).
- **F-19.1** orden de evaluación: sin el privilegio `Conciliacion` ⇒ 403 también (mismo cuerpo, no se distingue); sitio no central ⇒ lo que ya hoy responde `SoloCentral` (sin cambio).
- **F-19.2** el 403 no consulta la base (verificar con un interceptor que no hay lecturas de existencia: evita fuga por tiempo).
- Falla si… el 403 se aplica solo a la comprobación de existencia, o si `Conciliacion` + restringido da lista vacía en lugar de 403. Tipo: HTTP. Dep.: P-0, P-09.

### 5.11 R-14 (T4-06) y F-25 (E-1 y T4-06) · reportes sin reenvío y diseñador

**R-14 sale de S-16b (Q-A4):** lo cierra la Q-6 de T4-06 si se une antes del corte; si no se une, **vuelve a S-16b** con las mismas pruebas (por eso las dejo aquí). **F-25 (adenda):** `PuedeDisenar` de la API de reportes (`EsAdmin && !RestringirSucursal`, `ContextoReportes.cs`, 403 `DISENO_NO_PERMITIDO`) se replica en la principal con el alcance de P-0.

**F-20 · R-14 (T4-06): `/api/reportes/{id}/ejecutar` y `/exportar` sin reenvío** [D, el detalle de «403 en Release» no lo da el aviso: ver N-3]

| Compilación / configuración | Actor | Esperado |
|---|---|---|
| Debug, sin reenvío (`Direccion` vacía), reporte de inventario | GLOBAL / SUPER-R | 200 como hoy |
| Debug, sin reenvío | R1 / ADMIN-R / R-SIN | **403 `SUCURSAL_NO_PERMITIDA`** (se conserva el camino local con la comprobación) |
| **Release**, sin reenvío | R1 / ADMIN-R / R-SIN | **403** (no hay camino local; no 503, no 500, no datos) |
| Con reenvío (cualquier compilación) | R1 | reenviado a `GPOS.Reportes` (T2-03 falla cerrado); no-regresión del camino con reenvío |
| Cualquiera | R-VIEJO-1/3 | **401 `credenciales`** antes de todo |

- **F-20.1** ejecutar y exportar (`xlsx`/`pdf`/`csv`/…) dan el mismo 403; ningún formato elude (los formatos no deben leer antes del chequeo).
- **F-20.2** `/api/reportes` y `/{id}` (definiciones, sin datos) siguen 200 para R1.
- **F-20.3** [D] en Release con reenvío habilitado el chequeo local no se activa (depende de la compilación condicional que B ya usa en T4-04); sin reenvío en Release, el restringido recibe 403 (fila de arriba). Ver N-3 si el 403 aplica a todos los reportes o solo a los de inventario (P-10 sigue abierta en esa parte).
- Falla si… el chequeo está en `ejecutar` y no en `exportar` (dos copias en `ReportesEndpoints.cs:40-71`), o se evalúa después de ejecutar el SQL. Tipo: HTTP. Dep.: P-0, T4-06, N-3.

**F-25 · diseñador (principal)**

| ID | Caso | Esperado | Lote |
|---|---|---|---|
| F-25.1 | ADMIN-R y R-SIN (ADMIN) piden `POST /api/reportes/diseno/detectar` y `/diseno/vista-previa` | **403** (paridad con `PuedeDisenar`; sin ejecutar SQL del diseñador). ADMIN-GLOBAL: 200; **SUPER-R: 200** (Q-A5) | **E-1** |
| F-25.2 | ADMIN-R y R-SIN (ADMIN) **guardan** y **eliminan** una definición de reporte (`ReportesService` bajo `SoloAdmin()`, `:107, 146, 160, 293`) | **403** y la definición no cambia (comparar antes/después, incluida la fila de bitácora: no hay). ADMIN-GLOBAL: 200; SUPER-R: 200 (Q-A3 y Q-A5) | **E-1** |
| F-25.3 | **Release:** `IDetectorColumnas` (en T4-06; hoy no existe en `5237e11b`) responde al restringido con **403**, no con 503; el contrato de **Guardar** gana la fila «ADMIN restringido ⇒ 403». En Debug se conserva la comprobación local de F-25.1 | 403 en ambos caminos; el 503 queda solo para «detector no disponible» (sin reenvío y no restringido) | **T4-06** |
| F-25.4 | Propiedades: R-VIEJO-1/3 ⇒ 401 antes del 403; la lista y `GET {id}` de definiciones siguen 200 para ADMIN-R (F-20.2); el 403 es **idéntico** (cuerpo) para detectar, vista previa, guardar y eliminar, salvo el código que decida N-3 | | E-1 |

- Falla si… `SoloAdmin()` sigue mirando solo `EsAdmin` (`ReportesService.cs:247`), o si el SUPER hereda la restricción, o si la regla de la principal y la de `GPOS.Reportes` difieren (AL-20). Tipo: HTTP + TX. Dep.: P-0, AL-20, N-3.
- Pregunta de A que la prueba no resuelve: que un ADMIN pueda saltarse el filtro declarando él mismo la columna de sucursal en el SQL del diseñador **no se probó** (supuesto [I] de la adenda); con F-25.1/F-25.2 el ADMIN restringido ya no llega al diseñador, así que el riesgo queda acotado al ADMIN global.

### 5.12 Transferencias (residuo 1 y 2) · F-21

Referencia: `TransferenciasService.cs:64` y `:145` (sucursal de la sesión), `:74` y `:127` (reconciliación en central), `DocumentosNg.cs:73-80`.

| ID | Caso | Esperado | Falla si… |
|---|---|---|---|
| F-21.1 | R-SIN-A (sucursal nula) lista/detalle/conduce/abre sesiones | **404** (lista: ver P-11), nunca la sucursal principal | `SucursalIdAsync` conserva `?? IdPrincipal` para estos caminos |
| F-21.2 | R-SIN-B (código de sucursal inexistente) | 404 | la sucursal desconocida cae a la principal (`DocumentosNg.cs:79`) |
| F-21.3 (v2, Q-A2) | R-VIEJO-1 (token S2, servidor S1) y R-VIEJO-3 en lista, detalle, abrir sesión y conduce | **401 `credenciales`** (ya no «usa S1»); cubierta por AL-18 y una integración; **lote E-1** | `Evaluar` no se aplica a estas rutas, o se sigue leyendo `sesion.Sucursal` |
| F-21.4 | R1 con `Reconciliación` (`TransfReconciliacion`) **en la central** | **P-12:** hoy `:74` permite ver todas si es la central; ¿un restringido con Reconciliación las ve todas? Propongo que no (D-3: el alcance prevalece). Si B dice que sí, F-21.4 se invierte | la excepción de reconciliación no consulta el alcance |
| F-21.5 | GLOBAL con `Reconciliación` en central | ve todas (sin cambio) | el cambio rompe la reconciliación de la central |
| F-21.6 | Una transferencia de S1 a S2: R1 la ve como origen; R2 (restringido a S2) la ve como destino; R1 no ve una de S2→S3 | | |
| F-21.7 (v2, Q-A2; cierra P-13) | **Escritura** de transferencias (`DocumentosNg.CrearAsync/BorradorSinNumeroAsync(… sesion.Sucursal …)`, `Despacho.cs:77,118`, tomadas de A sin releer): R-VIEJO-1 y R-VIEJO-3 intentan despachar/recibir | **401 `credenciales`**, ningún documento creado, numeración sin consumir. Ya no hay riesgo de despachar con la sucursal vieja; **lote E-1** | el despacho se acepta con la sucursal del token |

- Oráculo: R1 ≡ GLOBAL-en-S1 (sin otras sucursales). Para R-SIN: 404 idéntico al de «no existe».
- **F-21.8 (`GET /almacenes`)** sigue devolviendo código y nombre de **todos** los almacenes de destino, sin existencias (A: diseño; ver F-24): prueba de no-cambio.
- Tipo: HTTP + SQL. Dep.: P-0, P-11, P-12. (F-21.7 ya no depende de P-13.) Fila SUPER-R: ve y despacha como GLOBAL (Q-A5).

### 5.13 Guardado del artículo que conserva las filas fuera del alcance (R-04 escritura) · F-05..F-09 ampliados

Fuente: `MaestrosService.Articulos.cs:291-303` (construye `nivelesDeseados`) y `:363-366` (`RemoveRange` de **todas** las filas y alta de las deseadas).

Estado base: el artículo X tiene `ArticuloAlmacen` en A1 (mín 2, máx 20, reorden 8, ubicación U1), A2, A3 (mín 4, ubicación U3), A4 (mín 9, máx 90, reorden 30, ubicación U4).

| ID | Caso | Esperado | Falla si… |
|---|---|---|---|
| F-05 (ya) | R1 guarda X cambiando solo la descripción, con el DTO que le dio la lectura (solo A1 y A2) | filas de A3 y A4 **intactas**, fila a fila (`Minimo`, `Maximo`, `Reorden`, `UbicacionId` y las columnas de auditoría/`rowversion` de cada fila): comparar antes/después con `EXCEPT` en ambos sentidos | queda el `RemoveRange` global (`:364`) |
| F-05.1 | R1 sin cambiar nada y con el DTO leído: **ninguna** fila de `ArticuloAlmacen` se borra y reinserta (el `Id`/`rowversion` de las filas de A1/A2 no cambia si no cambió el nivel) | idempotente | borrar y reponer cambia el `rowversion` o genera historia de auditoría falsa |
| F-05.2 | R1 cambia el mínimo de A1 | cambia solo la fila A1; A2, A3, A4 intactas | |
| F-05.3 | **A3 (permitido; D-1 v2: `Operativo` solo en R-05 y R-06):** R1 **no** ve A3 en la pestaña (alcance `Consulta`), y su guardado conserva A3 intacto | A3 conservada | el guardado trata A3 como «mío» por `SucursalAlmacenPermitido` |
| F-05.4 | R1 **quita** una fila de A2 (la vacía en el DTO: `Minimo/Maximo/Reorden/Ubicación` todos nulos, regla de `:292`) | se borra la fila de A2, no se toca A3/A4 | |
| F-05.5 | R1 agrega nivel a un almacén de su alcance sin fila previa | se crea | |
| F-05.6 | **Guardado atómico y checks globales:** R1 guarda X cambiando el Tipo a **Servicio** cuando solo A4 (de S2) tiene existencia | **se rechaza** («No puede convertir en servicio un artículo que tiene existencia», `:304-306`), porque la suma es **global**, no la del alcance | el chequeo usa el alcance (R1 «ve» 8, no 0, pero con A1/A2 en 0 y existencia solo en A4 pasaría) |
| F-05.7 (v2) | **Fuga nueva de «Requiere lote»** (`LotesDocumento.MotivoNoCambiarRequiereLoteAsync`, `LotesDocumento.cs:156-168`; usa `ConsultasLotes.ExistenciaPorLote` por código de artículo, es decir **global**; el texto trae `{f.SinLote:N2} unidades sin lote` y `{f.LotesConExistencia} lotes`). Casos: **(a)** R1 marca «Requiere lote» en X con existencia sin lote solo en A4; **(b)** R1 lo desmarca con lotes con existencia solo en A4; **(c)** inhabilitar con existencia | En los tres, **el rechazo sigue basándose en datos globales** (se rechaza igual que GLOBAL) pero el mensaje para un no global **no contiene cifras** (ni unidades, ni número de lotes, ni nombre/código de almacén o sucursal ajenos) [D: texto exacto lo define A/UX, ver N-4]; GLOBAL y SUPER-R: mensaje actual sin cambio (regresión) | el mensaje de R1 trae `3`, `11`, `8`… o el rechazo depende del alcance (R1 «ve» 0 y lo deja pasar) |
| F-06 (ya) | DTO de R1 con una fila de **A4** (fuera de alcance) | 422, **nada guardado** (atómico, `rowversion` y precios intactos) y el mensaje **idéntico** al de un almacén inexistente (`IdAsync(... "Almacén" ...)` produce el texto de `:298`) | el mensaje distingue «no existe» de «fuera de su sucursal» (canal lateral), o el 422 llega después de guardar precios |
| F-06.1 | fila con A3 (permitido) | 422 también (D-1 v2 limita `Operativo` a R-05 y R-06) | `Operativo` aplicado en R-04 |
| F-06.2 | DTO con A1 y A4 mezclados | 422 y A1 **no** se guarda | validación parcial |
| F-06.3 | `IdAlmacen` con vectores V-01..V-09 (minúscula `a4` se normaliza a `A4` por `ToUpperInvariant` en `:293`: ¿se rechaza?) | `a4` ⇒ `A4` ⇒ 422 | la normalización ocurre **después** de comprobar el alcance |
| F-07 (ya) | GLOBAL: reemplaza todas las filas como hoy (regresión) | | |
| F-07.1 | GLOBAL con DTO que omite una fila de A4 ⇒ se borra A4 (comportamiento actual) | idéntico a hoy | el cambio altera el semántica de GLOBAL |
| F-08 (ya) | R1 quita una fila propia no toca las demás; `rowversion` del artículo solo cambia si cambia el artículo | | |
| F-09 (ya) | R-SIN-A/B/C: no puede guardar niveles. **P-14:** ¿el artículo en sí se puede guardar (descripción, precio) y los niveles se ignoran, o se rechaza todo? Propongo: se guarda el artículo y se conservan todas las filas de niveles (alcance vacío ⇒ ningún borrado) | el DTO con niveles ⇒ 422 | R-SIN conserva el `RemoveRange` y borra todo |
| F-09.1 | R-SIN-A guarda un **artículo nuevo** con niveles ⇒ 422 | | |
| F-09.2 | Concurrencia: dos guardados simultáneos (R1 sobre X; GLOBAL sobre X) ⇒ uno gana por `rowversion`/409, no se pierde la fila de A4 | las filas de A4 quedan con el valor del guardado ganador, nunca borradas | el read-modify-write de niveles no está bajo el bloqueo del artículo |
| F-09.4 (v2, Q-A5) | SUPER-R guarda el artículo X: se comporta como GLOBAL (pestaña con 4 filas, `Existencia` 26, reemplazo completo de filas como F-07). R-VIEJO-1/3 guardan ⇒ 401, nada guardado | | la bandera restringe al SUPER |
| F-09.3 | La bitácora del guardado (`RegistroBitacora.Registrar`, `:370`): el «antes/después» del restringido no incluye niveles de otras sucursales (ni como «eliminados») | | el diff de bitácora muestra A3/A4 como borrados |

- **F-27 (v2) · superficies de «Requiere lote»** [D]: `MotivoNoCambiarRequiereLoteAsync` la llaman la ficha (`MaestrosService.Articulos.cs:311`) y la importación de plantilla de artículos (`ImportacionMaestros.cs:389`, verificadas en `5237e11b`). F-27.1: la fila de la plantilla importada por R1 que cambia «Requiere lote» da el mismo rechazo **sin cifras**; F-27.2: prueba TX/reflexión que el único origen del texto es esa función (una tercera superficie nueva hereda la regla); F-27.3: GLOBAL importa con el mensaje actual. Lote E-1.
- Lectura (F-04): la pestaña de R1 trae solo A1/A2 con su existencia; `dto.Existencia` = 8; R-SIN: pestaña vacía y `Existencia` = 0; GLOBAL: 4 filas y 26; ADMIN-R ≡ R1. R-VIEJO-1 ≡ R1.
- Oráculo del guardado: tras cualquier guardado de R1, el estado de las filas fuera del alcance es **bit a bit igual al previo**, y el estado global del artículo es el que habría con GLOBAL aplicando el mismo cambio solo a las filas del alcance.
- Tipo: SQL + HTTP. Dep.: P-0, **P-14**.

## 6. Los demás elementos de mi plan previo que se mantienen o se ajustan

| ID | Estado | Nota |
|---|---|---|
| F-01..F-04 | Sin cambios | F-03 se amplía a R-05 (F-11) |
| F-22 | **Concretado en §7** | |
| F-23 | Sin cambios | opcional |
| F-24 | Sin cambios | `/api/catalogos/Almacenes` y `GET /almacenes` de transferencias: solo código y nombre (confirma que A los deja) |
| F-25, F-26, F-27 | Nuevos (§1.2, §4, §5.11, §5.13) | **v2:** aceptados (Q-A1 a Q-A5); F-25.1/.2, F-26 y F-27 en E-1, F-25.3 y F-20 en T4-06 |

## 7. Barrido anti-olvido (F-22)

**Problema:** hay 14 rutas hoy y cualquier ruta nueva que lea `inv.Existencia`, `inv.Movimiento`, `cat.ArticuloAlmacen`, `inv.ExistenciaLote` o `inv.ArticuloCosto` por almacén puede olvidar el alcance. La prueba de reflexión de mi plan previo dependía de una lista blanca. Propongo **dos capas** (se pueden hacer ambas; la barata primero):

**Capa 1 · Atributo + reflexión (propuesta, necesita decisión de B: P-03).**
- Atributo `[AlcanceAlmacenes(Alcance.Consulta | Alcance.Operativo | Alcance.Ninguno)]` sobre **cada método público de servicio** que abra una `IUnidadTrabajo` y llame a consultas que tocan las tablas anteriores.
- `Alcance.Ninguno` exige `Motivo = "..."` (p. ej. «cierre de sucursal: proceso de la empresa con privilegio propio»).
- Prueba (TX, sin base): por reflexión sobre `GPOS.Core`, recorrer los métodos públicos de las clases `*Service` y comprobar **tres cosas**: (a) todo método cuya consulta registrada (`[ConsultaRegistrada]`) tiene `SqlTexto` con `inv.Existencia|inv.Movimiento|cat.ArticuloAlmacen|inv.ExistenciaLote` lleva el atributo; (b) los métodos con `Consulta`/`Operativo` reciben `IAlcanceAlmacenes` inyectado en la clase; (c) los `Ninguno` están en una lista cerrada con `Motivo` no vacío. Falla si aparece un servicio nuevo sin atributo.
- Esta prueba es la que hace que **«olvidar» sea imposible por construcción**: no depende de la memoria del revisor.

**Capa 2 · Lista blanca de SQL (si B no quiere el atributo).**
- Recorrer **todas** las constantes `[ConsultaRegistrada]` de `src/GPOS.Core/Consultas/**` (ya existen como metadatos: la vigila CP-169) y fallar si el texto de la consulta contiene `inv.Existencia`, `inv.Movimiento`, `cat.ArticuloAlmacen`, `inv.ExistenciaLote` y **no** contiene `@global` y `@sucursalAlcance`, salvo que el nombre de la constante esté en una lista cerrada (`ConsultasBlancas.cs` en la prueba) con motivo. La lista blanca se escribe con las consultas que hoy pasarían por la regla: ver el listado que obtuve (`git grep` de esas tablas): `ConsultasCompras` (1), `ConsultasCierreSucursal` (4), `ConsultasCierrePeriodo` (3), `ConsultasDocInventario` (8), `ConsultasInventario` (14), `ConsultasLotes` (5) y `ConsultasTablero` (1).
- Falla si… alguien agrega una consulta nueva de existencias sin parámetros de alcance y sin entrar en la lista blanca (el desarrollador debe decidir y escribir el motivo).
- **Punto débil honesto de la capa 2:** una consulta escrita en LINQ de EF (como `MaestrosService.Articulos.cs:61, 155` y `:305`) **no** pasa por `[ConsultaRegistrada]`, y la regla no la ve. Para esas se necesita la capa 1 o un segundo barrido que busque `ng.Existencias`/`ng.ArticulosAlmacenes` (Roslyn o `rg` en una prueba de arquitectura sobre las fuentes, como la de los proyectos del blueprint).

**Capa 3 · Barrido por rutas HTTP (la de mi plan previo, pero automatizada).** Enumerar con `EndpointDataSource` todas las rutas que mapean a un servicio con atributo `Consulta/Operativo` y ejecutar **la matriz mínima de 4 actores** (GLOBAL, R1, R-SIN, R-VIEJO-1) comprobando (v2: R-VIEJO-1/3 ⇒ 401 y **SUPER-R ≡ GLOBAL** entran en la matriz mínima, que pasa a 6 actores) que R-SIN **no** devuelve datos numéricos de S2 (el oráculo sobre fixture numérico del §2: ninguna respuesta puede contener 11, 7 o 26 donde sea que corresponda a existencias). Es una prueba de humo genérica y detecta una ruta nueva sin escribir su prueba individual.

Mutaciones: añadir una ruta nueva `GET /api/inventario/existencias-por-sucursal` sin atributo ⇒ la capa 1 falla en rojo; la capa 2 falla si su SQL lo toca; la capa 3 falla si devuelve 26.

## 8. Orden de construcción de las pruebas (v2)

1. **AL-01..AL-20, con AL-18 (`Evaluar`) primero** y P-0 (sin esto nada compila). AL-18 es unitaria, sin base, y es la más barata: cierra R-VIEJO-1/3, F-21.3, F-21.7 y la fuga de F-26.6. AL-12 y AL-19 fijan el diseño de `IAlcanceAlmacenes` y `AlcanceResuelto` (Vacío por omisión).
2. **V-01..V-12** (una prueba parametrizada sobre la capa común; V-11 ahora espera 401).
3. **Barrido (capa 1 o 2) en rojo**, con matriz mínima de 6 actores (§7); cada ruta corregida lo pone en verde.
4. **Lote E-1:** F-01..F-09 + F-05.x/F-06.x/F-09.x (guardado del artículo), F-05.7 y F-27 («Requiere lote»), F-25.1/F-25.2/F-25.4 (diseñador), F-21.3/F-21.7 (401), R-01/R-02/R-04.
5. **F-26.1..F-26.7** al final de cada ruta tocada de E-1 (es lo que se rompe sin avisar); F-26.6 depende de AL-18.
6. **Lote S-16b** en el orden del riesgo de fuga: F-11 (R-05), F-14 y F-15, F-16 (el contador), F-17, F-10, F-12, F-13 (con F-13.4), F-18, F-19, F-21 (resto). Cada matriz con sus filas R-VIEJO (401) y SUPER-R.
7. **T4-06:** F-20 (R-14, 403 en Release) y F-25.3; si T4-06 no se une antes del corte, vuelven a S-16b.
8. **UI (F-23)** y textos, cuando el UX defina el rótulo.

## 9. Esfuerzo inferido (todo [I], v2)

| Bloque | Pruebas (aprox.) | Lote |
|---|---|---|
| AL-10..AL-20 | 11 | E-1 |
| `Evaluar` (AL-18) | 8 | E-1 |
| V-01..V-12 (≈ 70 ejecuciones, 1 clase) | 12 | E-1 |
| Guardado del artículo (F-05.x, F-06.x, F-09.x, F-05.7, F-27) | ≈ 31 | E-1 |
| F-25.1, F-25.2, F-25.4 | 5 | E-1 |
| F-26.1..F-26.7 | 7 | E-1 |
| F-21.3, F-21.7 | 2 | E-1 |
| Barrido (capa 1 + 3) | 3 | E-1 |
| F-10..F-19 y F-21 (resto), con R-VIEJO 401 y SUPER-R | ≈ 62 | S-16b |
| F-20, F-25.3 | ≈ 6 | T4-06 |
| **Total** | **≈ 147** (v1: ≈ 110; +37 por Q-A1..Q-A5, SUPER-R, `Evaluar`, F-26 y F-27) | |

Esfuerzo: **≈ 1,65 dp (±40 %, margen de A, no medido)** frente a 1,3 dp de la v1: E-1 ≈ 0,85 dp, S-16b ≈ 0,75 dp, T4-06 ≈ 0,05 dp. Es coherente con el +0,35 dp que A suma al total (E-1 +0,25, S-16b +0,05, T4-06 +0,05) más mi aumento por F-26/F-27/SUPER-R. Costo de infraestructura: USD 0. Ejecución: por clase (`FronteraInventario*`), con `--filter "Categoria=Alcance"`; nunca suite completa en OSHIN-LEGION.

## 10. Preguntas para B

**Cerradas por Q-A1 a Q-A5 y la adenda:** P-01 (AL-12 = Vacío), P-02 (SUPER nunca restringido), P-07 (F-14.4 eliminada), P-13 (401), y de P-10 la parte de R-14 (pasa a T4-06). **Siguen abiertas** (sin cambio de texto):

- **P-03 (§7).** ¿Prefiere B el atributo `[AlcanceAlmacenes]` (barrido automático por construcción) o la lista blanca de SQL (más barata, sin tocar el código)? Recomiendo el atributo.
- **P-04 (V-03, F-11).** Un `almacen` vacío o de solo espacios ¿es «sin almacén» (suma del alcance) o error? Hoy `ExistenciasAsync` lo trata como nulo (`InventarioService.cs:728`).
- **P-05 (F-03, F-11).** A pide corregir «para todos» el código desconocido (kárdex y línea): ¿el **GLOBAL** también pasa a recibir `[]` / existencia 0 con un código desconocido? Es un cambio de comportamiento visible para el usuario actual (hoy ve la suma de todos los almacenes); por el principio rector del CLAUDE.md debería decir qué rompe y a quién afecta (el POS que pase un código viejo). Propongo confirmarlo o hacerlo solo para el restringido.
- **P-06 (F-14.1).** Los números de los conteos visibles del restringido tendrán saltos por los conteos de otras sucursales: ¿se acepta?
- **P-08 (F-18).** ¿Un restringido a una sucursal cerrada ve el aviso de su propia sucursal?
- **P-09 (F-19).** El 403 de R-13 ¿es para todo el endpoint (las 8 comprobaciones) o solo para las de inventario?
- **P-10 (F-20, F-25).** Camino local de reportes para un restringido: ¿403 `SUCURSAL_NO_PERMITIDA` para **todos** los reportes o solo los de inventario? ¿O se exige el reenvío en producción? ¿Entran `diseno/detectar` y `vista-previa`?
- **P-11 (F-21.1).** Las listas de transferencias para un restringido sin sucursal: ¿404 (A) o 200 con lista vacía (consistente con R-01, R-08)?
- **P-12 (F-21.4).** Un restringido con `TransfReconciliacion` en la central: ¿ve todas las transferencias (hoy) o solo las de su sucursal (D-3)?
- **P-14 (F-09).** Un restringido sin sucursal resoluble que guarda un artículo: ¿se guarda el artículo y se ignoran/conservan los niveles, o se rechaza todo?
- **P-15 (F-05.3).** En la pestaña Almacenes de R-04 (`Consulta`), el restringido no ve A3 aunque lo pueda mover. ¿Se acepta que no pueda **editar** los niveles de un almacén permitido (D-1 limita `Operativo` a R-05..R-07)?

**Nuevas de la versión 2:**
- **N-1 · Comparación de sucursal en `Evaluar`.** PENDIENTE: pregunta para B. ¿El token se compara con `SucursalDefault` en forma ordinal (como el resto de `Evaluar`) o sin distinguir mayúsculas (la base es `CI_AS`)? ¿Qué pasa si el restringido tiene `SucursalDefault` nula y el token trae una sucursal (401) o no trae ninguna (pasa y queda en Vacío, F-21.1)? ¿Y si el ADMIN cambia el **código** de la sucursal y el token conserva el viejo? AL-14 y AL-18 (7, 8) fijan lo que B decida; no lo adiviné.
- **N-2 · Plazo del 401.** PENDIENTE: pregunta para B. La cuenta se cachea 15 s (`RevocacionSesiones`); A descartó el mecanismo CS-4. ¿El cambio de `RestringirSucursal`/`SucursalDefault` invalida la caché (`Olvidar`/`Registrar`) para que el 401 sea inmediato, o se acepta hasta 15 s? AL-14 fija una de las dos.
- **N-3 · R-14 «403 en Release» y código de error.** PENDIENTE: pregunta para B. El aviso dice «F-20 pasa a T4-06 (R-14, 403 en Release)». No queda claro si en Release sin reenvío el restringido recibe 403 en ejecutar/exportar para **todos** los reportes o solo los de inventario (resto de P-10), ni si el código en la principal es `SUCURSAL_NO_PERMITIDA` (R-14) o `DISENO_NO_PERMITIDO` (diseñador, API de reportes) para F-25.1/.2/.3. §5.11 lo deja marcado [D].
- **N-4 · Texto del rechazo de «Requiere lote» sin cifras.** PENDIENTE: pregunta para B. La adenda dice «sin cifras» para el no global; ¿el texto exacto lo fija A/UX? Mi prueba solo afirma ausencia de dígitos y de nombres de almacén/sucursal, y que el rechazo se mantenga.
- **N-5 · Regla del SUPER en `GPOS.Reportes`.** PENDIENTE: pregunta para B. Q-A5 exige «una sola regla»; `ContextoReportes.PuedeDisenar` hoy restringe al SUPER con bandera (`EsAdmin && !RestringirSucursal`). ¿Lo cambia el equipo B y su prueba vive en `GPOS.Reportes.Tests`? AL-20 asume que sí.
- **N-6 · Contenido [D].** La adenda y el aviso dan solo el número de F-26.1..F-26.7, F-25.2/.3, F-13.4 y F-27; el contenido es mío. Pido que A lo confirme.

## 11. Qué no verifiqué (v2)

- **No compilé ni ejecuté nada.** `IAlcanceAlmacenes`, `AlcanceResuelto` y `ExistenciasVisiblesAsync` los doy por no existentes (como en la v1); `IDetectorColumnas` no aparece en `5237e11b` (`git grep`).
- **Verifiqué en `5237e11b` solo:** `LotesDocumento.cs:156-168` y sus dos llamadores (`MaestrosService.Articulos.cs:311`, `ImportacionMaestros.cs:389`); `RevocacionSesiones.Evaluar` (`:169`, estática) y la existencia de la caché; `ContextoReportes.PuedeDisenar`; `ReportesService.SoloAdmin()` y sus usos (`:107, 146, 160, 247, 293`); las llamadas `ExistenciasAsync` de `InventarioService.cs:505, 586, 638`.
- **No re-verifiqué** en el nuevo head las líneas de la v1 (R-01..R-13, transferencias, `Despacho.cs:77,118`) ni `ConsultasInventario.cs:13-39` y `:224-230`, `LibroInventario.cs:169-190`, `InventarioService.cs:552-562`: las tomo de la adenda de A.
- Sigue sin verificar de la v1: `ReferenciasNg.AlmacenAsync`, el esquema de `inv.ExistenciaLote`, `TransferenciasService.Recepcion.cs`, prefijo/privilegio de `diseno/*`, privilegios con ADMIN-R, `ConsultasLotes.Disponibles`, pantallas Web/MAUI.
- No verifiqué si el cambio de restricción de un usuario invalida hoy la caché de 15 s (N-2), ni si Guardar/Eliminar de definiciones tienen otro punto de entrada fuera de `ReportesService`.
- No releí `traspasos/A/rutas-inventario-sin-filtro-sucursal-2026-10-21.md` (la adenda resume sus cambios). Fixture y esfuerzo: diseño e inferencia míos (±40 %, margen de A, no medido). No revisé la rama `b/adr93-ta-p08-confidencialidad` ni el ADR-93.

### Cierre
- Estado: Completado
- Artefactos: `C:/Users/lfmen/source/repos/GPOS-NG-Equipos/traspasos/C/2026-10-22-plan-pruebas-s16-particion-e1.md` (versión 2, editado en su lugar; sin commit ni push)
- Supuestos: (1) base `origin/feature/modelo-ng` @ `5237e11b`; (2) el contenido de F-26.x, F-25.2/.3, F-13.4 y F-27 es diseño mío donde la adenda solo da el número; (3) cifras de esfuerzo [I]
- Decisiones candidatas a ADR: Ninguna (precisiones de TA-P08 que B registra)
- Entregas a otros agentes: B → responder N-1 a N-6 y las P abiertas (en especial P-05, P-10, P-12); A → confirmar el contenido [D]; equipo B (`GPOS.Reportes`) → alinear `PuedeDisenar` con Q-A5 (N-5)
- Próximo paso recomendado: que B responda N-1, N-2 y N-3 antes de que A empiece P-0, porque fijan `Evaluar` y la firma de `IAlcanceAlmacenes`
