```
Para: B        De: C        Fecha: 2026-10-22
Tipo: Entrega (tarea 3 del aviso 2026-10-22: plan de pruebas del cambio de S-16, partición de E-1 de ADR-93)
Prioridad: Media
Repositorio y rama: GPOS-NG `feature/modelo-ng` (el cambio se construye allí); fuentes en el área común
Estado: Abierto (plan, sin código; adelantado respecto de la fecha 9-nov; sin revisión del auditor-seguridad)
```

# Plan de pruebas del cambio de S-16 (R-03, R-05 a R-14, transferencias, falla cerrada y guardado del artículo)

**Fuentes leídas:** `avisos/B-a-C/2026-10-22-tareas-nuevas-para-c.md` (punto 3), `avisos/B-a-A/2026-10-22-respuesta-s16-pr152-y-fechas-ola5.md` (D-1 a D-4), `traspasos/A/rutas-inventario-sin-filtro-sucursal-2026-10-21.md` (P-0, R-01 a R-14) y mi `traspasos/C/2026-10-22-plan-pruebas-e1-adr93-tarjetas.md` (§2 AL-xx, §3 F-xx). Código leído solo con `git show origin/feature/modelo-ng:<ruta>` (solo lectura). **Nada compilado ni ejecutado.**

## 0. Qué decidió B y qué cambia en mi plan previo

B adoptó **las cuatro recomendaciones de A sin modificarlas** (verificado línea por línea en la respuesta, §1):

| Decisión | Respuesta de B | Efecto en el plan |
|---|---|---|
| D-1 | Sí. Alcance `Operativo` (propios + `SucursalAlmacenPermitido`) **solo** en R-05, R-06 y R-07; `Consulta` (propios) en las demás | Mi F-11/F-12/F-13 y AL-10 pasan de «dependen de D-1» a **definitivas**. Para R-05 a R-07 el oráculo es «GLOBAL si no existieran los almacenes que el restringido no puede mover» |
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
7. Nuevo F-25 y F-26 (candidatos que A no listó, ver §1.2). Quedan **condicionados** a que B los acepte.
8. AM-03/AM-09 (rombos) y S-03 (`Total` del restringido) siguen igual; no cambian con D-1..D-4.

## 1. Verificación contra el código vivo

Base: `origin/feature/modelo-ng` @ **`b4378650`** (2026-10-22 14:46). A revisó `e3e729c1`. Verifiqué solo lo que se necesita para escribir las pruebas.

### 1.1 Rutas y líneas de A

| Elemento (A) | Estado | Evidencia |
|---|---|---|
| R-01 `ConsultasDocInventario.Existencias`, `WHERE (@almacen IS NULL OR al.Codigo = @almacen)` | **Coincide** (`:87-97`) | `ExistenciasAsync` `InventarioService.cs:723-736`; el parámetro es `Sql.Varchar(...,20)` |
| R-02 kárdex, falla abierta `almacenId = alm?.Id` | **Coincide** (`InventarioService.cs:744-745`; SQL `ConsultasDocInventario.cs:59-78`) | el código desconocido ⇒ `alm` nulo ⇒ `@almacen IS NULL` ⇒ todos |
| R-05 `CatalogoService.ArticuloAsync` | **Coincide** (`CatalogoService.cs:173-174`); SQL `ConsultasInventario.cs:226-229` | **hallazgo nuevo para las pruebas:** la existencia se calcula con `ReferenciasNg.ExistenciasAsync` → `LibroInventario.ExistenciasAsync` (`LibroInventario.cs:593-596`), que **también usan las rutas de escritura** (`InventarioService.cs:505, 586, 638`). Ver V-RIESGO-1 |
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

- **F-25 · `POST /api/reportes/diseno/detectar` y `/vista-previa`** (`ReportesEndpoints.cs:91-111`): igual que R-14, sin reenvío ejecutan en la principal el SQL del diseñador (o el Razor del SUPER) sin filtro de sucursal. Mismo criterio que R-14 (403 `SUCURSAL_NO_PERMITIDA` para el restringido en el camino local). **[I]**: no verifiqué el prefijo del grupo ni el privilegio; los leí por las líneas. Si el diseñador solo lo usan ADMIN/SUPER, D-3 los alcanza.
- **F-26 · Lectura de existencia dentro de rutas de escritura** (no es fuga de lectura, pero el filtro de R-05 no debe romperlas): `GuardarAsync` de ajuste/conduce/conteo (`InventarioService.cs:505, 586, 638`) calcula la existencia insuficiente con el mismo servicio. Ver V-RIESGO-1.
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
- **Actores** (cada uno con su token): **GLOBAL** (`RestringirSucursal=0`, nivel USER, con los privilegios de la ruta); **ADMIN-GLOBAL**; **R1** (restringido, `SucursalDefault=S1`); **ADMIN-R** (nivel ADMIN, restringido a S1, D-3); **R-SIN-A** (restringido, `SucursalDefault` nula); **R-SIN-B** (restringido, `SucursalDefault` con código que no existe en `org.Sucursal`); **R-SIN-C** (restringido a una sucursal **inhabilitada**: ver P-05); **R-VIEJO-1** (token con claim S2, servidor dice S1); **R-VIEJO-2** (token con S1, el ADMIN ya le quitó la restricción ⇒ debe ser GLOBAL); **R-VIEJO-3** (token con S1, el ADMIN lo restringió después a S2 ⇒ ve S2, no S1); **SUPER**.
- **Oráculo general (`O`):** la respuesta de un restringido es **idéntica, campo por campo y byte por byte del JSON**, a la que daría GLOBAL **si la otra sucursal no existiera** (para `Consulta`: si no existieran A3 ni A4; para `Operativo`: si no existiera A4). Implementación en prueba: sembrar dos bases iguales, una con S2 y otra sin S2 (o con S2 vacío), pedir como GLOBAL en la segunda y como R1 en la primera y comparar. Esto detecta fugas por totales, conteos, paginación y mensajes de error, no solo por filas. Para R-SIN-x, el oráculo es «conjunto vacío» (200 con lista vacía / existencia 0 / 404 o 403 según la ruta, nunca el valor global).
- **Estas pruebas no se corren como suite completa en OSHIN-LEGION:** por clase.

## 3. Pieza común y falla cerrada (completa y corrige mi AL-xx)

AL-01 a AL-09 de mi plan previo se mantienen sin cambio. Cambia AL-10 y se agregan los siguientes.

| ID | Qué se comprueba | Tipo | Falla si… | Dep. |
|---|---|---|---|---|
| AL-10 (corregido) | `Consulta` de S1 = {A1, A2}; `Operativo` de S1 = {A1, A2, A3}. A4 en ninguno. Con R-SIN, ambos = ∅ | SQL | el `Operativo` omite `SucursalAlmacenPermitido`, o el `Consulta` lo incluye | P-0 |
| AL-11 | `Vacío` también en `Operativo`: R-SIN-A/B no recibe los permitidos de ninguna sucursal (el `EXISTS` sobre `SucursalAlmacenPermitido` con `@sucursalAlcance = NULL` no devuelve nada) | SQL | el `Operativo` hace `OR` con una consulta de permitidos que ignora `@global/@sucursalAlcance` | P-0 |
| AL-12 | **Contexto sin petición HTTP** (hilos de fondo, `AbrirUnidadAsync(null)`; `CatalogoService.cs:158` ya lo usa con sesión nula): definir el comportamiento y fijarlo. Mi propuesta: sin `ISesionActual` autenticado ⇒ `Vacío`, nunca `Global`; los trabajos internos que necesiten existencia global deben pedirla por una API interna explícita | SQL + TX | un llamador sin usuario obtiene `Global` | **P-01** |
| AL-13 | D-3: ADMIN-R recibe `Sucursal(S1)` igual que R1; el nivel no concede `Global`. Se prueba en una sola prueba parametrizada sobre los tres niveles USER/ADMIN/SUPER con `RestringirSucursal=1` | HTTP | el alcance solo se evalúa para USER | P-0, **P-02** |
| AL-14 | Los 4 «cambios en caliente» de R-VIEJO-1/2/3 más el que cambia el **código** de la sucursal de S1 (alcance por `Id`, no por código viejo) | HTTP | el alcance cachea la sucursal del token | P-0 |
| AL-15 | El alcance se evalúa **una vez por petición**, y la consulta SQL usa los mismos valores en todas las lecturas de esa petición (dos consultas de la misma ruta, p. ej. R-04 niveles + existencias, no pueden ver alcances distintos si el ADMIN cambia la restricción entre medio) | HTTP | cada consulta relee | P-0 |
| AL-16 | `Global` solo se obtiene de `RestringirSucursal = 0` leído de la base; un `RestringirSucursal` nulo o ilegible ⇒ `Vacío` (dato corrupto cierra) | SQL | `ISNULL(RestringirSucursal,0)` convierte el nulo en global | P-0 |
| AL-17 | Prueba de contrato de SQL: cada consulta con `@global`/`@sucursalAlcance` declara `@global bit, @sucursalAlcance smallint` en `[ConsultaRegistrada]` (ADR-50: tipo y largo) | TX | alguien pasa `int` o `nvarchar` | — |

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
| V-11 | Token de S2 con código de almacén de S1 y viceversa (token cruzado) | Manda el servidor (AL-03) | el alcance usa el claim |
| V-12 | `?articulo=` hostil en R-02/R-06 (código de artículo que casa con un `ArticuloCodigo` alterno) | No cambia el alcance de almacén | la resolución de artículo abre otro camino |

Nota para B: V-01/V-02 son los que más valor tienen porque la intercalación es `SQL_Latin1_General_CP1_CI_AS` (CLAUDE.md): en SQL `a4 = A4`, así que un filtro hecho en C# con comparación ordinal falla justo ahí.

### V-RIESGO-1 (la mutación más probable del cambio)

`ReferenciasNg.ExistenciasAsync`/`LibroInventario.ExistenciasAsync` sirve **a la lectura (R-05) y a la escritura** (existencia insuficiente en ajuste/conduce/conteo). Si el desarrollador aplica el alcance dentro de esa función compartida:
- el restringido que descuenta o ajusta en un almacén **permitido** (A3) vería «existencia insuficiente» falsa;
- el GLOBAL no se afecta, así que las pruebas de GLOBAL no lo detectan.
- Prueba **F-26.1**: R1 hace un ajuste de salida de 7 en A3 (permitido, existencia 7) ⇒ **aprobado**; de 8 ⇒ rechazado por existencia insuficiente. **F-26.2**: R1 guarda un conteo físico aplicado en A1 y la diferencia se calcula contra 3, no contra 0. **F-26.3**: un conduce de R1 que pida de A4 (fuera de `Operativo`) ⇒ se rechaza por el motivo que hoy ya existe (almacén no permitido, disparador 51309), sin cambiar el mensaje.
- Falla si… el alcance se coló en la función de escritura.

## 5. Plan por ruta

Para cada ruta: **matriz** (GLOBAL / restringido con sucursal / restringido sin sucursal resoluble / token viejo), **oráculo**, **vectores**, **tipo**, **falla si…** y **dependencia**. Los valores esperados usan el fixture del §2. «ADMIN-R» se prueba igual que R1 y se anota con `(=R1)`. Ante dos restringidos, R-SIN-A/B/C esperan lo mismo y se parametrizan en una sola prueba.

Prerrequisito común de todas: `P-0` y AL-01..AL-17.

### 5.1 R-03 · `GET /api/maestros/articulos` (lista) · F-10

| Actor | Esperado (`Existencia` del artículo X) |
|---|---|
| GLOBAL / ADMIN-GLOBAL | 26 (hoy) |
| R1 / ADMIN-R | 8 (Consulta; A3 **no** cuenta porque R-03 es `Consulta`) |
| R-SIN-A/B/C | 0 en todos los artículos (200 con la lista completa de artículos y existencia 0; los artículos **no** se filtran, TA-P08 filtra existencias, no artículos) |
| R-VIEJO-1 | 8 (manda el servidor) · R-VIEJO-2: 26 · R-VIEJO-3: 18 (A3+A4 si solo restringido a S2 y sin `Operativo`: 7+11) |

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
| R-VIEJO-1 | A4 | 0; A1 → 3 · R-VIEJO-2: A4 → 11 (ya no restringido) |

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
| R-VIEJO-1 | A4 | 404 · R-VIEJO-2: lotes de A4 |

- Oráculo: R1/A4 ≡ `ZZZ` (404 con el mismo cuerpo `ReglaNegocio`/ProblemDetails); un artículo inexistente con almacén válido ⇒ también 404, así que la prueba compara las **tres** combinaciones inexistente/ fuera de alcance/ ambos desconocidos para que no haya canal lateral por mensaje distinto (S-05).
- **F-12.1** el listado `Vencido` se calcula con la fecha (sin cambio) y no filtra lotes por sucursal además del almacén.
- **F-12.2** lotes de **A4 con artículo X** y almacén A1 del restringido: la respuesta de A1 no incluye lotes que existan en otros almacenes (el SQL `ConsultasLotes.Disponibles` ya filtra por almacén; regresión).
- Falla si… `DisponiblesAsync` resuelve `alm` y no comprueba alcance (`LotesService.cs:26-27`) o el 404 se vuelve 403 (revela existencia). Tipo: HTTP + SQL. Dep.: P-0.

### 5.4 R-07 · `GET /api/inventario/conteos/preparar` · F-13 (`Operativo`)

| Actor | `almacen` | Esperado |
|---|---|---|
| GLOBAL | A4 | hoja de conteo de A4 (existencia y costo) |
| R1 | A1, A3 | su hoja (A3 permitido) |
| R1 | A4 | «Almacén incorrecto», idéntico al de `ZZZ` |
| R-SIN-A/B/C | A1 | «Almacén incorrecto» |
| R-VIEJO-1 | A4 | «Almacén incorrecto» |

- Oráculo: ≡ `ZZZ` en estado, mensaje y forma.
- **F-13.1** `costo` sigue oculto sin «Ver costos» (`[DatoCosto]`): R1 sin privilegio ⇒ costo ausente aun en A1.
- **F-13.2** los filtros `clasificacion/valor/texto` no amplían el alcance (p. ej. `clasificacion=categoria&valor=` de una categoría con artículos en A4: la hoja de A1 sigue mostrando existencias de A1).
- **F-13.3** tope de 3000 artículos sin cambio.
- Falla si… se valida el alcance después de leer las existencias, o el error es otro texto (canal lateral). Tipo: HTTP + SQL. Dep.: P-0.

### 5.5 R-08 · conteos: lista `GET /conteos` y detalle `GET /conteos/{numero}` · F-14 (`Consulta`)

| Actor | Lista | Detalle de un conteo de A4 | Detalle de uno de A1 |
|---|---|---|---|
| GLOBAL | todos | 200 | 200 |
| R1 / ADMIN-R | solo los de A1/A2 | **404** ≡ número inexistente | 200 |
| R-SIN-A/B/C | lista vacía (200) | 404 | 404 |
| R-VIEJO-1 | solo A1/A2 | 404 | 200 |

- Oráculo: la lista de R1 ≡ la de GLOBAL en una base sin S2; el **número** consumido no se revela: la numeración es por serie/jornada (ADR-45), así que en la lista del restringido pueden verse **saltos** de numeración que delatan conteos ajenos. **P-06**: ¿es aceptable? (prueba **F-14.1**, fijando la decisión: no se oculta el hueco porque los números son visibles y el modelo de numeración es por empresa).
- **F-14.2** el valor de la diferencia (costo) respeta «Ver costos».
- **F-14.3** `BuscarConteosAsync` con filtros `texto/desde/hasta` no devuelve conteos de A4 por coincidencia de texto en el almacén.
- **F-14.4** un conteo de A3 (permitido) **no** se muestra en la lista (alcance `Consulta`, D-1) aunque R1 pueda contarlo: **P-07** (¿es el comportamiento buscado? Un restringido que cuenta A3 no vería su propio conteo en la lista). Recomiendo B confirme o suba R-08 a `Operativo`; la prueba fija lo que B decida.
- Falla si… el detalle filtra por alcance pero la lista no (o al revés); el 404 se convierte en 403. Tipo: HTTP + SQL. Dep.: P-0, P-06, P-07.

### 5.6 R-09 · documentos de inventario `GET /documentos/{tipo}` y `/{numero}` · F-15 (`Consulta`, D-2 resuelto)

Tipos: `Entrada`, `Conduce`, `Ajuste` (los tres con almacén).

| Actor | Lista | Detalle de A4 |
|---|---|---|
| GLOBAL | todos | 200 |
| R1 / ADMIN-R | solo A1/A2 | 404 ≡ inexistente |
| R-SIN-A/B/C | vacía | 404 |
| R-VIEJO-1 | A1/A2 | 404 |

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
| R-VIEJO-1 | A1/A2 | 404 | alcance S1 |

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
| R-VIEJO-1 | 80 · R-VIEJO-2: 260 |

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
| R-VIEJO-1 | ninguno (S1 no está cerrada) |

- Oráculo: lista vacía idéntica a la de una empresa sin sucursales cerradas.
- **F-18.1** el texto del aviso no incluye totales de otras sucursales (el código y nombre de la sucursal son el dato de fuga hoy).
- Falla si… se filtra por nombre/código de sucursal comparando en C# con otra intercalación que la del servidor. Tipo: HTTP + SQL. Dep.: P-0, P-08.

### 5.10 R-13 · `GET /api/admin/diagnostico/conciliacion` · F-19 (403 al restringido)

| Actor | Esperado |
|---|---|
| GLOBAL con `Conciliacion` / SUPER | 200 con la conciliación **completa** (como hoy) |
| R1 / ADMIN-R con `Conciliacion` | **403** |
| R-SIN-A/B/C con `Conciliacion` | 403 (nunca 200 vacío: falla cerrada) |
| R-VIEJO-1 | 403 · R-VIEJO-2 (ya global): 200 |

- Oráculo: el 403 es el mismo para **todas** las comprobaciones (`?comprobacion=` cualquiera de las 8 definiciones de `ConciliacionService.cs:37-59`, no solo la de existencia) y para `tope` cualquiera: probar con la comprobación de **CxC** (que no es de inventario): ¿también 403 o solo la de existencia? **P-09** (A dijo «es un diagnóstico de la empresa»; si el 403 es por endpoint, se prueba por endpoint).
- **F-19.1** orden de evaluación: sin el privilegio `Conciliacion` ⇒ 403 también (mismo cuerpo, no se distingue); sitio no central ⇒ lo que ya hoy responde `SoloCentral` (sin cambio).
- **F-19.2** el 403 no consulta la base (verificar con un interceptor que no hay lecturas de existencia: evita fuga por tiempo).
- Falla si… el 403 se aplica solo a la comprobación de existencia, o si `Conciliacion` + restringido da lista vacía en lugar de 403. Tipo: HTTP. Dep.: P-0, P-09.

### 5.11 R-14 (y F-25) · `/api/reportes/{id}/ejecutar` y `/exportar` sin reenvío · F-20 (403 `SUCURSAL_NO_PERMITIDA`)

| Configuración | Actor | Esperado |
|---|---|---|
| Sin reenvío (`Direccion` vacía), reporte de inventario (los de `rpt`/`rptc`) | GLOBAL | 200 como hoy |
| Sin reenvío | R1 / ADMIN-R | **403 `SUCURSAL_NO_PERMITIDA`** |
| Sin reenvío | R-SIN | 403 (mismo código) |
| Con reenvío | R1 | reenviado a `GPOS.Reportes`, que ya aplica T2-03 y falla cerrado (**no** es 403 de la principal; prueba de no-regresión del camino con reenvío) |
| Sin reenvío, reporte **no** de inventario | R1 | **P-10:** ¿403 también (A dice «un restringido recibe 403» en el camino local, sin distinguir)? |

- **F-20.1** ejecutar y exportar (`xlsx`/`pdf`/`csv`/…) dan el mismo 403; ningún formato elude (los formatos no deben leer antes del chequeo).
- **F-20.2** `/api/reportes` y `/{id}` (definiciones, sin datos) siguen 200 para R1.
- **F-25.1 (candidata)** `diseno/detectar` y `diseno/vista-previa` sin reenvío: igual que F-20 (ver §1.2).
- **F-20.3** en **Release** con reenvío habilitado, el chequeo no se activa (no hay camino local): la prueba depende de la compilación condicional que B ya usa en T4-04 (N-06 de mi plan de T4-04/T4-06). **P-10** también cubre la alternativa de A («exigir el reenvío en producción»): si B la elige, F-20 cambia a «la principal no arranca con reenvío vacío en Release» (prueba de configuración, ya cubierta por C-xx del plan de la API de reportes).
- Falla si… el chequeo está en el endpoint de `ejecutar` y no en el de `exportar` (dos rutas con dos copias de código, `ReportesEndpoints.cs:40-71`), o se evalúa después de ejecutar el SQL. Tipo: HTTP. Dep.: P-0, P-10.

### 5.12 Transferencias (residuo 1 y 2) · F-21

Referencia: `TransferenciasService.cs:64` y `:145` (sucursal de la sesión), `:74` y `:127` (reconciliación en central), `DocumentosNg.cs:73-80`.

| ID | Caso | Esperado | Falla si… |
|---|---|---|---|
| F-21.1 | R-SIN-A (sucursal nula) lista/detalle/conduce/abre sesiones | **404** (lista: ver P-11), nunca la sucursal principal | `SucursalIdAsync` conserva `?? IdPrincipal` para estos caminos |
| F-21.2 | R-SIN-B (código de sucursal inexistente) | 404 | la sucursal desconocida cae a la principal (`DocumentosNg.cs:79`) |
| F-21.3 | R-VIEJO-1 (token S2, servidor S1) | usa S1: ve las transferencias de S1, no las de S2 | se sigue leyendo `sesion.Sucursal` |
| F-21.4 | R1 con `Reconciliación` (`TransfReconciliacion`) **en la central** | **P-12:** hoy `:74` permite ver todas si es la central; ¿un restringido con Reconciliación las ve todas? Propongo que no (D-3: el alcance prevalece). Si B dice que sí, F-21.4 se invierte | la excepción de reconciliación no consulta el alcance |
| F-21.5 | GLOBAL con `Reconciliación` en central | ve todas (sin cambio) | el cambio rompe la reconciliación de la central |
| F-21.6 | Una transferencia de S1 a S2: R1 la ve como origen; R2 (restringido a S2) la ve como destino; R1 no ve una de S2→S3 | | |
| F-21.7 | Regla de unicidad: **escritura** (`DocumentosNg.CrearAsync/BorradorSinNumeroAsync(… sesion.Sucursal …)`, `Despacho.cs:77,118`) usa la sucursal del token: R-VIEJO-1 despacharía **con la sucursal vieja**. No es fuga de lectura, es integridad: prueba que fija el comportamiento y se pasa a A como pregunta (**P-13**) | | |

- Oráculo: R1 ≡ GLOBAL-en-S1 (sin otras sucursales). Para R-SIN: 404 idéntico al de «no existe».
- **F-21.8 (`GET /almacenes`)** sigue devolviendo código y nombre de **todos** los almacenes de destino, sin existencias (A: diseño; ver F-24): prueba de no-cambio.
- Tipo: HTTP + SQL. Dep.: P-0, P-11, P-12, P-13.

### 5.13 Guardado del artículo que conserva las filas fuera del alcance (R-04 escritura) · F-05..F-09 ampliados

Fuente: `MaestrosService.Articulos.cs:291-303` (construye `nivelesDeseados`) y `:363-366` (`RemoveRange` de **todas** las filas y alta de las deseadas).

Estado base: el artículo X tiene `ArticuloAlmacen` en A1 (mín 2, máx 20, reorden 8, ubicación U1), A2, A3 (mín 4, ubicación U3), A4 (mín 9, máx 90, reorden 30, ubicación U4).

| ID | Caso | Esperado | Falla si… |
|---|---|---|---|
| F-05 (ya) | R1 guarda X cambiando solo la descripción, con el DTO que le dio la lectura (solo A1 y A2) | filas de A3 y A4 **intactas**, fila a fila (`Minimo`, `Maximo`, `Reorden`, `UbicacionId` y las columnas de auditoría/`rowversion` de cada fila): comparar antes/después con `EXCEPT` en ambos sentidos | queda el `RemoveRange` global (`:364`) |
| F-05.1 | R1 sin cambiar nada y con el DTO leído: **ninguna** fila de `ArticuloAlmacen` se borra y reinserta (el `Id`/`rowversion` de las filas de A1/A2 no cambia si no cambió el nivel) | idempotente | borrar y reponer cambia el `rowversion` o genera historia de auditoría falsa |
| F-05.2 | R1 cambia el mínimo de A1 | cambia solo la fila A1; A2, A3, A4 intactas | |
| F-05.3 | **A3 (permitido, D-1 solo Operativo en R-05..R-07):** R1 **no** ve A3 en la pestaña (alcance `Consulta`), y su guardado conserva A3 intacto | A3 conservada | el guardado trata A3 como «mío» por `SucursalAlmacenPermitido` |
| F-05.4 | R1 **quita** una fila de A2 (la vacía en el DTO: `Minimo/Maximo/Reorden/Ubicación` todos nulos, regla de `:292`) | se borra la fila de A2, no se toca A3/A4 | |
| F-05.5 | R1 agrega nivel a un almacén de su alcance sin fila previa | se crea | |
| F-05.6 | **Guardado atómico y checks globales:** R1 guarda X cambiando el Tipo a **Servicio** cuando solo A4 (de S2) tiene existencia | **se rechaza** («No puede convertir en servicio un artículo que tiene existencia», `:304-306`), porque la suma es **global**, no la del alcance | el chequeo usa el alcance (R1 «ve» 8, no 0, pero con A1/A2 en 0 y existencia solo en A4 pasaría) |
| F-05.7 | Idem con «Requiere lote» (UX-118-09, `:308+`) y con inhabilitar con existencia | misma regla con datos **globales**; el mensaje no incluye cifras de otras sucursales (ni el nombre del almacén de S2) | el mensaje revela «existencia 11 en A4» |
| F-06 (ya) | DTO de R1 con una fila de **A4** (fuera de alcance) | 422, **nada guardado** (atómico, `rowversion` y precios intactos) y el mensaje **idéntico** al de un almacén inexistente (`IdAsync(... "Almacén" ...)` produce el texto de `:298`) | el mensaje distingue «no existe» de «fuera de su sucursal» (canal lateral), o el 422 llega después de guardar precios |
| F-06.1 | fila con A3 (permitido) | 422 también (D-1 limita `Operativo` a R-05..R-07) | `Operativo` aplicado en R-04 |
| F-06.2 | DTO con A1 y A4 mezclados | 422 y A1 **no** se guarda | validación parcial |
| F-06.3 | `IdAlmacen` con vectores V-01..V-09 (minúscula `a4` se normaliza a `A4` por `ToUpperInvariant` en `:293`: ¿se rechaza?) | `a4` ⇒ `A4` ⇒ 422 | la normalización ocurre **después** de comprobar el alcance |
| F-07 (ya) | GLOBAL: reemplaza todas las filas como hoy (regresión) | | |
| F-07.1 | GLOBAL con DTO que omite una fila de A4 ⇒ se borra A4 (comportamiento actual) | idéntico a hoy | el cambio altera el semántica de GLOBAL |
| F-08 (ya) | R1 quita una fila propia no toca las demás; `rowversion` del artículo solo cambia si cambia el artículo | | |
| F-09 (ya) | R-SIN-A/B/C: no puede guardar niveles. **P-14:** ¿el artículo en sí se puede guardar (descripción, precio) y los niveles se ignoran, o se rechaza todo? Propongo: se guarda el artículo y se conservan todas las filas de niveles (alcance vacío ⇒ ningún borrado) | el DTO con niveles ⇒ 422 | R-SIN conserva el `RemoveRange` y borra todo |
| F-09.1 | R-SIN-A guarda un **artículo nuevo** con niveles ⇒ 422 | | |
| F-09.2 | Concurrencia: dos guardados simultáneos (R1 sobre X; GLOBAL sobre X) ⇒ uno gana por `rowversion`/409, no se pierde la fila de A4 | las filas de A4 quedan con el valor del guardado ganador, nunca borradas | el read-modify-write de niveles no está bajo el bloqueo del artículo |
| F-09.3 | La bitácora del guardado (`RegistroBitacora.Registrar`, `:370`): el «antes/después» del restringido no incluye niveles de otras sucursales (ni como «eliminados») | | el diff de bitácora muestra A3/A4 como borrados |

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
| F-25, F-26 | Nuevos (§1.2, §4) | condicionados a la aceptación de B |

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

**Capa 3 · Barrido por rutas HTTP (la de mi plan previo, pero automatizada).** Enumerar con `EndpointDataSource` todas las rutas que mapean a un servicio con atributo `Consulta/Operativo` y ejecutar **la matriz mínima de 4 actores** (GLOBAL, R1, R-SIN, R-VIEJO-1) comprobando que R-SIN **no** devuelve datos numéricos de S2 (el oráculo sobre fixture numérico del §2: ninguna respuesta puede contener 11, 7 o 26 donde sea que corresponda a existencias). Es una prueba de humo genérica y detecta una ruta nueva sin escribir su prueba individual.

Mutaciones: añadir una ruta nueva `GET /api/inventario/existencias-por-sucursal` sin atributo ⇒ la capa 1 falla en rojo; la capa 2 falla si su SQL lo toca; la capa 3 falla si devuelve 26.

## 8. Orden de construcción de las pruebas

1. **AL-01..AL-17** con P-0 (sin esto nada compila). Incluye AL-12 (contexto sin petición) porque cambia el diseño de `IAlcanceAlmacenes`.
2. **V-01..V-12** (una prueba parametrizada sobre la capa común: se escribe una vez y se activa con cada ruta).
3. **Barrido (capa 1 o 2) en rojo**: escribirlo ya, con la lista de rutas pendientes como «esperadas»; cada ruta que se corrige lo pone en verde. Da el avance medible.
4. **Lote E-1** (si B parte): F-01..F-09 + F-05.x/F-06.x/F-09.x (guardado del artículo; es lo que más cuesta si se olvida).
5. **Lote S-16b** en el orden del riesgo de fuga: F-11 (R-05, sin permiso y alimenta la venta), F-14 y F-15 (los más numerosos), F-16 (el contador), F-17, F-10, F-12, F-13, F-18, F-19, F-20/F-25, F-21.
6. **F-26** (no-regresión de escritura) **al final de cada ruta tocada**, no al final del plan: es lo que se rompe sin avisar.
7. **UI (F-23)** y las demás de textos, cuando el UX defina el rótulo.

## 9. Esfuerzo inferido (todo [I])

| Bloque | Pruebas (aprox.) | Esfuerzo |
|---|---|---|
| AL-10..AL-17 | 8 | 0,15 dp |
| V-01..V-12 | 12 casos × 6 rutas, parametrizados (≈ 70 ejecuciones, 1 clase) | 0,2 dp |
| F-10..F-21 (11 rutas × 3 a 8 casos) | ≈ 60 | 0,6 dp |
| Guardado del artículo (F-05.x, F-06.x, F-09.x) | ≈ 22 | 0,25 dp |
| Barrido (capa 1 + 3) | 3 | 0,15 dp |
| F-25, F-26 | 6 | 0,1 dp |
| **Total** | **≈ 110 casos** | **≈ 1,3 dp (±40 %)** |

Nota: A asignó **0,2 dp** a «pruebas de la lista ampliada» (A, §4). Mi estimación del plan **supera** ese número en ~1,1 dp porque cuento la matriz de 4-5 actores por ruta, el guardado del artículo y el barrido. Sugiero que B no sume los dos números: **el 3,0 dp de A deja las pruebas de la lista ampliada subestimadas**; la cifra realista para E-1 completa es ≈ 3,0 − 0,2 + 1,3 = **4,1 dp**. Si B parte, el lote E-1 queda ≈ 1,45 + 0,5 y el cambio aparte ≈ 1,55 + 0,8. Costo de infraestructura: USD 0. Ejecución: ninguna se corre en OSHIN-LEGION como suite completa; por clase (`FronteraInventario*`), con `--filter "Categoria=Alcance"`.

## 10. Preguntas para B (ninguna bloquea el plan; fijan una prueba)

- **P-01 (AL-12).** ¿Qué hace `IAlcanceAlmacenes` cuando no hay petición HTTP ni usuario (p. ej. `CatalogoService.cs:158` abre la unidad con sesión nula; trabajos de fondo)? Propongo `Vacío` y que los trabajos internos pidan lo global por una API interna con nombre propio. Si B quiere `Global` para procesos internos, hay que decirlo para que la prueba lo fije (no se infiere).
- **P-02 (AL-13).** ¿Un **SUPER** con `RestringirSucursal = 1` queda sujeto? El SUPER es global (CLAUDE.md), pero la bandera puede existir en su fila. Propongo: el SUPER nunca se restringe por esta bandera (se ignora y se registra), el ADMIN sí (D-3).
- **P-03 (§7).** ¿Prefiere B el atributo `[AlcanceAlmacenes]` (barrido automático por construcción) o la lista blanca de SQL (más barata, sin tocar el código)? Recomiendo el atributo.
- **P-04 (V-03, F-11).** Un `almacen` vacío o de solo espacios ¿es «sin almacén» (suma del alcance) o error? Hoy `ExistenciasAsync` lo trata como nulo (`InventarioService.cs:728`).
- **P-05 (F-03, F-11).** A pide corregir «para todos» el código desconocido (kárdex y línea): ¿el **GLOBAL** también pasa a recibir `[]` / existencia 0 con un código desconocido? Es un cambio de comportamiento visible para el usuario actual (hoy ve la suma de todos los almacenes); por el principio rector del CLAUDE.md debería decir qué rompe y a quién afecta (el POS que pase un código viejo). Propongo confirmarlo o hacerlo solo para el restringido.
- **P-06 (F-14.1).** Los números de los conteos visibles del restringido tendrán saltos por los conteos de otras sucursales: ¿se acepta?
- **P-07 (F-14.4).** Un restringido que cuenta en un almacén **permitido** (A3) no vería ese conteo en la lista de R-08 (alcance `Consulta`, D-1): ¿se acepta o R-08 debe ser `Operativo`?
- **P-08 (F-18).** ¿Un restringido a una sucursal cerrada ve el aviso de su propia sucursal?
- **P-09 (F-19).** El 403 de R-13 ¿es para todo el endpoint (las 8 comprobaciones) o solo para las de inventario?
- **P-10 (F-20, F-25).** Camino local de reportes para un restringido: ¿403 `SUCURSAL_NO_PERMITIDA` para **todos** los reportes o solo los de inventario? ¿O se exige el reenvío en producción? ¿Entran `diseno/detectar` y `vista-previa`?
- **P-11 (F-21.1).** Las listas de transferencias para un restringido sin sucursal: ¿404 (A) o 200 con lista vacía (consistente con R-01, R-08)?
- **P-12 (F-21.4).** Un restringido con `TransfReconciliacion` en la central: ¿ve todas las transferencias (hoy) o solo las de su sucursal (D-3)?
- **P-13 (F-21.7).** La **escritura** de transferencias usa `sesion.Sucursal` del token (`Despacho.cs:77,118`). Un token viejo puede despachar con la sucursal anterior. ¿Entra en S-16 o es un hallazgo aparte para A?
- **P-14 (F-09).** Un restringido sin sucursal resoluble que guarda un artículo: ¿se guarda el artículo y se ignoran/conservan los niveles, o se rechaza todo?
- **P-15 (F-05.3).** En la pestaña Almacenes de R-04 (`Consulta`), el restringido no ve A3 aunque lo pueda mover. ¿Se acepta que no pueda **editar** los niveles de un almacén permitido (D-1 limita `Operativo` a R-05..R-07)?

## 11. Qué no verifiqué

- **No compilé ni ejecuté nada.** Ninguna prueba de este plan corre hoy; `IAlcanceAlmacenes` no existe aún.
- Solo leí fragmentos de los archivos citados; **no leí** `ReferenciasNg.AlmacenAsync` (cómo resuelve y normaliza el código: de ahí que V-01/V-02/V-08 sean hipótesis a confirmar), ni el esquema de `inv.ExistenciaLote` (si ligado a almacén, F-16.2), ni `TransferenciasService.Recepcion.cs` completo, ni el prefijo del grupo ni el privilegio de `diseno/detectar` y `vista-previa` (F-25), ni los privilegios exactos de `Permisos.ReportesInventario`/`Articulos` con ADMIN-R, ni `ConsultasLotes.Disponibles` completo.
- No verifiqué las pantallas Web/MAUI de A (Existencias.razor, Articulos.razor, Tablero.razor); las pruebas UI de este plan se limitan a F-23 y quedan por definir con el UX.
- Los valores del fixture (3/5/7/11, costo 10) son diseño mío; el artículo con descripciones repetidas y el conteo de 130 artículos de mi plan previo se reutilizan, pero no los validé contra un fixture existente en `tests/GPOS.Tests`.
- No busqué si ya existe en `tests/` alguna prueba de frontera de sucursal (`git ls-tree` con «Alcance|Frontera|Confidencial» no devolvió nada, lo que sugiere que no).
- Las cifras de esfuerzo son [I]; el rango ±40 % es el de A, no medido.
- No revisé la rama `b/adr93-ta-p08-confidencialidad` ni el texto del ADR-93 en sí; tomé «unidad de alcance = almacén» de A y de mi plan previo.

### Cierre
- Estado: Completado
- Artefactos: `C:/Users/lfmen/source/repos/GPOS-NG-Equipos/traspasos/C/2026-10-22-plan-pruebas-s16-particion-e1.md`
- Supuestos: (1) base `origin/feature/modelo-ng` @ `b4378650`; (2) B adoptó las cuatro recomendaciones de A tal cual (así consta en su respuesta); (3) fixture numérico de diseño mío; (4) cifras de esfuerzo [I]
- Decisiones candidatas a ADR: Ninguna (P-01..P-15 son precisiones de TA-P08 para B)
- Entregas a otros agentes: B → responder P-01..P-15 (en especial P-05, P-10, P-12 y P-13) y decidir si F-25 entra; arquitecto-software/backend (A) → implementar P-0 con AL-12/AL-16; qa-automatizado → construir en el orden del §8
- Próximo paso recomendado: que B responda P-01, P-03 y P-05 antes de que A empiece P-0, porque fijan el diseño de `IAlcanceAlmacenes` y el atributo del barrido
