Para: B        De: C        Fecha: 2026-10-23
Tipo: Revisión de pruebas (tarea 1 de B-a-C/2026-10-22-tareas-nuevas-para-c-3: PR #168, E-1)
Prioridad: Media
Repositorio y rama: GPOS-NG `b/e1-adr93-alcance-sucursal` @ 16a66c8d (unido a `feature/modelo-ng`)
Estado: Abierto

# Revisión de las pruebas del PR #168 (E-1, ADR-93, TA-P08)

**Método:** solo lectura. Leí el PR con `gh pr view 168`, el árbol `16a66c8d` con `git show`/`git grep` y mi plan S-16 v2 (`traspasos/C/2026-10-22-plan-pruebas-s16-particion-e1.md`). **No compilé ni ejecuté nada** (ver «Qué no verifiqué»). Las rutas de pruebas sin prefijo son `tests/GPOS.Tests/Alcance/`; `V` = visto en el código o la aserción; `I` = inferido.

## 1. Veredicto

**Aprobado con observaciones (seguimiento; el PR ya está unido).** Lo que E-1 cambia en producción (R-01 existencias, R-02 kárdex con saldo inicial, R-04 pestaña y guardado, el 401 de `Evaluar`, la regla única `Restringe`, el diseñador) tiene pruebas con aserciones por valor sobre el fixture numérico de mi plan (A1=3, A2=5, A3=7, A4=11; restringido = 8, global = 26), con oráculo de «ajeno ≡ inexistente», y esas pruebas matan por su aserción las mutaciones razonables de cada ruta (§4). **No hay hallazgos Críticos ni Altos.** Los huecos son de seguimiento: faltan los 7 casos F-26 (guarda de V-RIESGO-1), el barrido anti-olvido F-22, 10 de los 12 vectores V-xx, casi toda la matriz por HTTP, y una prueba inestable (~2,7 % de fallos espurios por ejecución, P168-05). V-RIESGO-1 **no se materializa** en el código unido (§3) y F-25 está resuelto por dos capas (§3). Los tres fallos preexistentes están explicados por lectura (§5): son pruebas viejas contra el contrato de columnas anterior a `d5962a1b`, ya marcadas `Transicion=Ola5` y excluidas del filtro oficial.

## 2. Hallazgos

| ID | Sev. | Hallazgo | Evidencia | Recomendación |
|---|---|---|---|---|
| P168-01 | Media | **Faltan F-26.1 a F-26.7** (guarda de V-RIESGO-1). Ninguna prueba hace un ajuste, conduce o conteo (borrador/aplicado) con R1. Hoy no hay riesgo porque E-1 no toca la ruta de escritura, pero S-16b (R-05) sí tocará la función compartida y la regresión no tendría quién la detecte. | Búsqueda en los 13 archivos de `Alcance/`: ninguno llama a `GuardarAsync` de ajuste/conduce con R1; solo entradas de siembra (`AlcanceAlmacenesTests.cs:59-67`). Código: `LibroInventario.ExistenciasAsync` y `ReferenciasNg.ExistenciasAsync` sin cambio (`InventarioService.cs:512, 593, 645`, `CatalogoService.cs:174`) [V]. | Escribir ya F-26.1 (salida de 7 y de 8 en A3 por R1), F-26.2/F-26.3 (conteo borrador y aplicado), F-26.5 y F-26.7 (GLOBAL sin cambio): pasan hoy y protegen S-16b. ≈ 0,25 dp [I]. |
| P168-02 | Media | **Sin barrido anti-olvido (F-22).** No existe ninguna de las 3 capas. Las guardas parciales son `InyeccionAlcanceTests.cs:20` (constructor público de 3 servicios) y `AdminSinRestriccionRutasTests.cs:45` (rutas de `/api/admin`). Una consulta nueva sobre `inv.Existencia`/`inv.Movimiento`/`cat.ArticuloAlmacen` sin alcance no hace fallar nada. P-03 sigue sin respuesta. | Ningún archivo de `Alcance/` recorre `[ConsultaRegistrada]` ni `EndpointDataSource` para existencias [V]. | Capa 2 (lista blanca de SQL con motivo) es la más barata: ≈ 0,2 dp [I]. B debe contestar P-03 antes de S-16b. |
| P168-03 | Media | **Vectores V-xx: 2 de 12.** Solo V-01 (`a4`: `AlcanceAlmacenesTests.cs:259-270, :308-317, :435`) y V-11 (token cruzado, `SucursalTokenRestringidoTests.cs:26`, `AlcanceSucursalHttpTests.cs:77-84`). Faltan V-02 (espacios), V-03 (vacío), V-04 (comodines), V-05 (inyección), V-06 (Id numérico), V-07 (parámetro repetido, HTTP), V-08 (Unicode), V-09 (largo), V-10 (`X-Sucursal`/`?sucursal=`), V-12. Mitigación real: el alcance se aplica en SQL por llave y los parámetros están tipados (`ConsultasDocInventario.cs` diff, `AlcanceAlmacenes.cs:125-136`) [V]; por eso no lo marco Alto. | V-03 sigue dependiendo de P-04: ambos servicios tratan el vacío como «sin almacén» (`InventarioService.cs:734-745` y `KardexAsync`) [V]. | Una clase parametrizada `[Theory]` sobre R-01/R-02/guardado cubre V-02..V-06, V-08, V-09 en ~0,15 dp [I]; V-07 y V-10 necesitan HTTP. |
| P168-04 | Media | **La matriz de actores casi no se prueba por HTTP.** Una sola prueba HTTP de alcance (`AlcanceSucursalHttpTests.cs:32`: R1 + R-VIEJO-1 sobre existencias y kárdex). Faltan por HTTP: R-VIEJO-2 y R-VIEJO-3; SUPER-R y ADMIN-R; R-SIN-B (R-SIN-A recibe 401 de `Evaluar` y nunca llega, por diseño); una **ruta de escritura** con 401 (F-26.6, F-21.7); `GET /api/maestros/articulos/{id}` (R-04); `[DatoCosto]` oculto sin «Ver costos» (F-01); el 403 del diseñador por HTTP. | `AdminSinRestriccionHttpTests.cs:92-121` (`RutasDenegadas`) no incluye `/api/admin/reportes/*`, `/api/admin/importaciones` ni `/api/admin/exportaciones/verificar`; la cobertura de esas rutas es solo la guarda estructural `AdminSinRestriccionRutasTests.cs:45` [V]. | Agregar al menos: 1 POST de ajuste con token viejo (401, sin fila ni número consumido), SUPER-R sobre existencias, y las 4 rutas de reportes a `RutasDenegadas`. |
| P168-05 | Media | **Prueba inestable.** `R04_el_rechazo_de_Requiere_lote_no_le_da_cifras_al_restringido` afirma `DoesNotContain("26", mensaje)` (`AlcanceAlmacenesTests.cs:494`), pero el mensaje contiene el código del artículo (`LotesDocumento.cs:160-170`: `{c} tiene existencia sin lote…`), generado con 8 hex aleatorios (`Soporte.cs:55`, `Datos.Id`). Probabilidad de que el código contenga «26» ≈ 7/256 ≈ 2,7 % por ejecución [I: asumo que `Escenario.ArticuloAsync` usa `Datos.Id`; el cálculo es mío]. | Fallo espurio sin cambio de código. | Reemplazar por «el mensaje, quitando el código del artículo, no contiene dígitos» (`Regex.IsMatch(mensaje.Replace(art, ""), @"\d")`) o igualar con el texto exacto esperado. |
| P168-06 | Baja | **F-27 sin prueba y con valor por omisión abierto.** `MotivoNoCambiarRequiereLoteAsync(..., conCifras = true)` (`LotesDocumento.cs:160`): la segunda superficie, la plantilla de artículos (`ImportacionMaestros.cs:389`), no pasa el parámetro y daría cifras globales. Hoy la cierra solo la política de `/api/admin/importaciones` (diff de `ImportacionesEndpoints.cs`), otra capa. F-05.7(b) (desmarcar con lotes) y F-27.1 a F-27.3 no tienen prueba. | `ImportacionMaestros.cs:389`; `AlcanceAlmacenesTests.cs:483-502` solo prueba marcar [V]. | Invertir el valor por omisión (`conCifras = false` o parámetro obligatorio) y una prueba TX de que solo hay dos llamadores. |
| P168-07 | Baja | **Guardado del artículo: casos del plan sin prueba.** F-05.4/F-08 (R1 quita una fila propia), F-05.5 (agrega nivel), **F-05.6 (convertir en servicio: la suma es global, `MaestrosService.Articulos.cs:329-331`)**, F-09.1 (artículo nuevo de R-SIN), F-09.3 (bitácora sin A3/A4 como borrados), F-09.4 (SUPER-R guarda), R-SIN-A/C (solo B, `:448`). F-09.2 (concurrencia) declarado por B. | Mutación «el chequeo de servicio usa el alcance» no la mata ninguna prueba [V]. | F-05.6 es la de mayor valor (3 líneas de prueba). |
| P168-08 | Baja | **F-05 compara menos de lo que pide el plan.** `NivelesEnBaseAsync` solo mira `Minimo/Maximo/Reorden` (`AlcanceAlmacenesTests.cs:374-381`); el plan pedía `UbicacionId`, `rowversion`/auditoría y `EXCEPT` en ambos sentidos. F-05.1 (idempotencia): el código borra y reinserta las filas propias (`MaestrosService.Articulos.cs:392-394`), sin prueba. | Ídem. | Agregar `UbicacionId` a la cadena; decidir si borrar y reponer es aceptable (cambia `Id`/historia). |
| P168-09 | Baja | **Saldo inicial con almacén concreto sin prueba.** Las pruebas con `desde` usan «sin almacén» (`:295-304, :329-336`) o un almacén ajeno, que sale antes de la consulta (`InventarioService.cs:762-770`). La mutación «`SaldoAntes` ignora `@almacen`» no la mata nadie. | `ConsultasDocInventario.cs` (`SaldoAntes`) [V]. | Caso: R1, `almacen = A1`, `desde = mañana` ⇒ saldo 3. |
| P168-10 | Baja | **Orden de `Evaluar` distinto del plan y sin prueba.** El plan AL-18(6) decía «la regla nueva va después de todas»; el código la pone antes de `Validar(sesión)` y de «renovada» (`RevocacionSesiones.cs:179-181`). Un restringido con sesión reemplazada y sucursal cambiada recibe `credenciales`, no `reemplazada`. La única prueba de orden cubre «inhabilitada» (`SucursalTokenRestringidoTests.cs:82`). | [V] | Decidir el orden y fijarlo con una prueba (cerrada, reemplazada, renovada, sello malo). |
| P168-11 | Baja | **Huecos menores de la pieza común.** AL-13 sin SUPER con sucursal nula/inexistente ni USER (`:158-165`); AL-14 sin cambio del código de la sucursal (N-1); AL-15 solo cuenta lecturas de cuenta, no la lectura de la sucursal (`_sucursalLeida`, `AlcanceAlmacenes.cs:111-117`); AL-19(a) (`AlcanceResuelto` sin constructor público) sin prueba de reflexión. | [V] | 3 aserciones más en las pruebas existentes. |
| P168-12 | Baja | **`La_API_registra_el_alcance_de_la_peticion` lee el texto de `Program.cs`** (`InyeccionAlcanceTests.cs:28-33`). Frágil ante formato y exige el árbol de fuentes junto al binario. | [V] | Resolver `IAlcanceAlmacenes` desde `ApiMvpFactory.Services` y comprobar tipo y vida (Scoped). |
| P168-13 | Baja | **Doble capa del diseñador, con códigos distintos por HTTP.** Tras `11207ad7`, `detectar`, `vista-previa`, guardar y eliminar viven bajo `/api/admin/reportes` con `RequiereAdminSinRestriccion()` (`ReportesEndpoints.cs`, diff). El ADMIN restringido recibe por HTTP `RESTRICCION_SUCURSAL_ADMIN` (política) y nunca llega a `DISENO_NO_PERMITIDO` del servicio, que prueba `DisenoReportesRestringidoTests.cs:47`. F-25.4 («403 idéntico») no se cumple por HTTP. Es defensa en profundidad, no un defecto. | [V] | Documentarlo en la prueba y agregar la prueba HTTP (P168-04). |
| P168-14 | Baja | **Cifras del PR desactualizadas y guion de mutaciones sin publicar.** El cuerpo del PR dice «48 pruebas, 6 clases, 20 mutaciones»; hoy hay 13 archivos en `Alcance/` y los comentarios/avisos citan 157, 9, 10 y 14 mutaciones. El guion «está en la carpeta de trabajo de B» (A ya lo señaló como S168-08). | PR #168; `traspasos/A/revision-seguridad-pr168-e1-adr93-2026-10-22.md:62` | Publicar el guion en `GPOS-NG-Equipos` (tabla: archivo:línea, mutación, prueba que falla). |
| P168-15 | Baja | **Tres fábricas de pruebas pasan a alcance global** para seguir verdes (`BusquedaNumeroHttpTests.cs` +4, `NumeracionDiagnosticoTests.cs` +3, `NumeracionAdminRutasTests.cs`). Es correcto, pero esas suites ya no ejercen la restricción; y la suite completa no se corrió. | Diff del PR | Correr la suite oficial (`--filter "Transicion!=Ola5&Transicion!=Defecto"`) en la PC de B antes de dar S-16b por empezado. |

**Calidad de las pruebas (punto 5):** sin `ClearAllPools()`, sin `Thread.Sleep`/`Task.Delay`, sin dependencia de orden entre pruebas (cada prueba que escribe crea su propio artículo: `ArticuloConNivelesAsync`, `:359-365`). Observaciones: (a) `AlcanceAlmacenesTests` guarda el escenario en un `Dictionary` estático por cadena de conexión (`:25-34`): si `PrepararAsync` falla, la tarea fallida queda en caché y todas las pruebas de la clase fallan en cascada (ruido, no falso verde); (b) `DateTime.Today.AddDays(1)` en el kárdex (`:290, :302, :314, :335`) depende de que la fecha del movimiento y la del PC coincidan; en un servidor en UTC entre las 20:00 y las 24:00 (UTC−4) podría desfasarse [I, no verifiqué cómo se estampa `inv.Movimiento.Fecha`]; (c) la colección `bd` es compartida y estas pruebas dejan sucursales, almacenes y una regla de «almacén permitido» permanentes en esa base (con códigos únicos; mismo patrón que `SucursalOrigenTests`); (d) `RestriccionSoloSuperTests` y compañeras usan `SistemaSegundoFactorFixture` (una base por clase, 6 clases: costo de tiempo, no de corrección).

## 3. Matriz plan S-16 v2 → pruebas del PR

Estados: **Cubierto**, **Parcial**, **Falta**, **Fuera de E-1** (la ruta no cambia en E-1: S-16b/T4-06).

| ID del plan | Estado | Prueba(s) (archivo:línea) | Nota |
|---|---|---|---|
| AL-10 | Cubierto (TX no aplica en E-1) | `AlcanceAlmacenesTests.cs:121-127` | `Operativo` no lo pide ninguna ruta de E-1 (R-05/R-06 son S-16b) |
| AL-11 | Cubierto | `:129-142` | Vacío en Consulta y Operativo; el SQL con `@sucursalAlcance = NULL` no se prueba directo (cortocircuito en C#) |
| AL-12 | Cubierto | `:146-154` | usuario vacío, cuenta nula, inhabilitada, `default(AlcanceResuelto)` |
| AL-13 | Parcial | `:158-165` | falta SUPER con sucursal nula/inexistente y USER (P168-11) |
| AL-14 | Parcial | `SucursalTokenRestringidoTests.cs:26-50`; `AlcanceSucursalHttpTests.cs:77-84` | R-VIEJO-1 por HTTP; R-VIEJO-2/3 solo unitarias; falta el cambio de código de sucursal (N-1) |
| AL-15 | Parcial | `AlcanceAlmacenesTests.cs:210-221` | cuenta leída una vez; sucursal no |
| AL-16 | No aplica por tipo | — | `RestringirSucursal` es `bool` no nulo en `EstadoSesionUsuario` [V]; no verifiqué la nulabilidad de la columna |
| AL-17 | Cubierto por pruebas existentes [I] | `ContratoConsultasTests`/CP-169 (B dice que las corrió) | sin prueba nueva |
| AL-18 (8 casos) | Parcial (7 de 8) | (1) `SucursalTokenRestringidoTests.cs:41`; (2) `:26`; (3) `:30`; (4) `:45`; (5) `:53`; (7) `:41` (decisión: sin mayúsculas y con recorte); (8) `:34`; (6) orden: `:82` solo «inhabilitada» | P168-10 |
| AL-19 | Parcial | (b) `AlcanceAlmacenesTests.cs:152-153`, SQL por omisión `:228-236` | (a) y (d) faltan; (c) no existe en E-1 |
| AL-20 | Cubierto | `SucursalTokenRestringidoTests.cs:65-78`; `ProveedorContextoTests.cs` (QA5, +31); `DisenoReportesRestringidoTests.cs:64-70` | la regla única `UsuarioAlcance.Restringe` (`GPOS.Contracts`) hace innecesaria la prueba TX de dos predicados |
| V-01 | Cubierto | `AlcanceAlmacenesTests.cs:259-270, :308-317, :435` | R-01, R-02 y guardado |
| V-02 a V-10, V-12 | Falta | — | P168-03 |
| V-11 | Cubierto | `SucursalTokenRestringidoTests.cs:26`; `AlcanceSucursalHttpTests.cs:77-84` | |
| F-01 (R-01) | Parcial | `AlcanceAlmacenesTests.cs:250-270`; HTTP `AlcanceSucursalHttpTests.cs:68-70` | falta `[DatoCosto]` sin «Ver costos» |
| F-02 (R-02) | Cubierto | `:295-304, :308-317`; HTTP `:71-72` | con saldo inicial |
| F-03 (código desconocido) | Cubierto en R-02; R-05 fuera de E-1 | `:321-326` | GLOBAL recibe `[]` |
| F-04 (R-04 lectura) | Cubierto (servicio) | `:341-356` | falta HTTP |
| F-05 | Parcial | `:388-409` | P168-08 |
| F-05.1 | Falta | — | |
| F-05.2 | Parcial | `:400-407` | no verifica A2 intacta |
| F-05.3 | Cubierto | `:392, :406` | A3 (permitido) conservado |
| F-05.4 / F-05.5 / F-05.6 | Falta | — | P168-07 |
| F-05.7 | Parcial | (a) `:483-502` | (b) y (c) faltan; flaky (P168-05) |
| F-06, F-06.1, F-06.2, F-06.3 | Cubierto | `:416-440` | mensaje idéntico a «inexistente», nada guardado, `a4` |
| F-07, F-07.1 | Cubierto | `:466-476` | |
| F-08 | Falta | — | |
| F-09 | Parcial | `:444-462` | solo R-SIN-B; F-09.1/.2/.3/.4 faltan |
| F-25.1 | Cubierto (servicio) | `DisenoReportesRestringidoTests.cs:47-57` | detectar y vista previa; HTTP solo estructural (P168-13) |
| F-25.2 | Cubierto (servicio) | `:47-57` | guardar y eliminar; ADMIN global/SUPER-R `:64-70` (eliminar no, documentado) |
| F-25.4 | Parcial | `:47-57`, `AdminSinRestriccionRutasTests.cs:45` | |
| F-26.1 a F-26.7 | **Falta** | — | P168-01 |
| F-21.3 / F-21.7 | Parcial | Evaluar + `AlcanceSucursalHttpTests.cs:82-84` | sin ruta de transferencias ni de escritura |
| Barrido F-22 (capas 1 a 3) | **Falta** | — | P168-02 |
| F-27.1 a F-27.3 | Falta | — | P168-06 |
| Caso SUPER-R | Parcial | alcance `:162-163`; `Evaluar` `SucursalTokenRestringidoTests.cs:53`; `ResolverSucursal` (`SucursalesAccesoTests.cs`); diseñador `:64-70` | falta por HTTP y en el guardado (F-09.4) |
| F-10 a F-19, F-20, F-24, F-25.3 | Fuera de E-1 | — | S-16b / T4-06 |

**V-RIESGO-1 (punto 3), verificado contra el código unido:** el alcance se aplica **solo** en `InventarioService.ExistenciasAsync` y `KardexAsync` (`InventarioService.cs:734-780`) y en `MaestrosService.ArticuloAsync`/`GuardarArticuloNgAsync` (`MaestrosService.Articulos.cs:67-72, :222`). `LibroInventario.ExistenciasAsync` y `ReferenciasNg.ExistenciasAsync` **no se modificaron** y no tienen parámetro de alcance (`InventarioService.cs:512, 593, 645`; `ReferenciasNg.cs:189`; `CatalogoService.cs:174`) [V]. Los dos métodos públicos con alcance solo los llaman los endpoints (`InventarioEndpoints.cs:92, :95`) [V]; los constructores «sin alcance» son `internal` y solo los ven `GPOS.Tests` y `GPOS.Migracion` (`GPOS.Core.csproj:49-51`), y la API registra los servicios con el constructor público (`Program.cs:190, :202, :239`) [V]. Conclusión: ninguna escritura de inventario puede dar un «existencia insuficiente» falso por el alcance de E-1. **Hay prueba de que el constructor público exige alcance** (`InyeccionAlcanceTests.cs:20`) pero **no hay prueba de comportamiento** (P168-01).

**F-25 (punto 3), verificado:** `detectar`, `vista-previa`, `POST /` y `DELETE /{id}` están bajo `/api/admin/reportes` con `RequiereAdminSinRestriccion()` (`ReportesEndpoints.cs:82-105`), y además `ReportesService.SoloDisenadorAsync` (`:266`, usada en `:122, :161, :175, :314`) lanza 403 `DISENO_NO_PERMITIDO`. Con reenvío activo, la política decide antes de reenviar. El SUPER con la bandera pasa (`AlcanceAlmacenes.cs:100-101`, prueba `:162-163`). Pregunta cerrada: sí, el código unido evita la fuga; la prueba existe en servicio y estructural, no por HTTP (P168-04, P168-13).

## 4. Mutaciones

**No puedo auditar las 20 de B:** el guion no está en el repositorio ni en el área común (A lo registró como S168-08) y el cuerpo del PR solo da las categorías (existencias, kárdex, saldo inicial, pestaña, guardado, `Evaluar`, `Restringida`, pieza común, diseñador). Lo que sigue es **mi reconstrucción por lectura** de las mutaciones razonables de esas categorías y la aserción que las mata. No ejecuté ninguna; el veredicto es sobre la forma de la aserción [I].

| # | Categoría | Mutación | Prueba que la mata (aserción) | Veredicto |
|---|---|---|---|---|
| 1 | Existencias | quitar `AND (@global = 1 OR al.SucursalId = @sucursalAlcance)` | `AlcanceAlmacenesTests.cs:250-256` (almacenes = {A1,A2}, suma 8) | Mata por valor |
| 2 | Existencias | patrón fail-open (`@sucursalAlcance IS NULL OR …`) | `:228-236` (cero filas) y `:272-280` | Mata por valor |
| 3 | Existencias | `Consulta` → `Operativo` | `:250-256` (A3 es permitido en el fixture y no debe salir) | Mata por valor |
| 4 | Existencias | no pasar `enAlcance.Agregar(parametros)` | todas las de R-01 (parámetro sin declarar) | Mata, pero como excepción SQL, no por aserción |
| 5 | Existencias | almacén ajeno resuelto como «todos» | `:259-270` (lista vacía para A3, A4, `a4`, inexistente) | Mata por valor |
| 6 | Kárdex | sin filtro de alcance en `Kardex` | `:295-304` (almacenes {A1,A2}, entrada 8) | Mata por valor |
| 7 | Saldo inicial | `SaldoAntes` sin join/filtro | `:302-303` (saldo 8, no 26) | Mata por valor |
| 8 | Saldo inicial | `SaldoAntes` ignora `@almacen` | ninguna | **No se prueba** (P168-09) |
| 9 | Kárdex | código desconocido ⇒ «todos» (falla abierta original) | `:321-326`, `:308-317` | Mata por valor |
| 10 | Kárdex | almacén ajeno devuelve la fila de saldo inicial | `:314` (`Assert.Empty` con `desde`) | Mata por valor |
| 11 | Kárdex | quitar `if (enAlcance.Vacio) return []` | ninguna | Equivalente: el SQL con `@global=0` y `NULL` ya da cero filas (`:329-336` pasa igual) |
| 12 | Pestaña | niveles sin filtrar | `:341-347` (ids {A1,A2}) | Mata por valor |
| 13 | Pestaña | `Existencia` total global | `:346` (8, no 26) | Mata por valor |
| 14 | Pestaña | alcance vacío ⇒ global | `:353-355` | Mata por valor |
| 15 | Guardado | `RemoveRange` sin filtro (modelo nuevo) | `:388-409` (A3/A4 antes = después) | Mata por valor |
| 16 | Guardado | `RemoveRange` sin filtro (puente heredado) | `:393-395, :406-407` (compara `Heredado`) | Mata por valor |
| 17 | Guardado | fila ajena aceptada | `:416-440` (`ThrowsAsync`) | Mata |
| 18 | Guardado | mensaje distinto de «inexistente» | `:433-436` (texto exacto) | Mata por valor |
| 19 | Guardado | validar después de guardar | `:437-439` (A1 y descripción intactas) | Mata por valor |
| 20 | Guardado | Vacío borra todos los niveles | `:457` | Mata por valor |
| 21 | Guardado | «Requiere lote» con cifras para el restringido | `:493-494` | Mata, pero la prueba es inestable (P168-05) |
| 22 | `Evaluar` | quitar `SucursalAjena` | `SucursalTokenRestringidoTests.cs:26, :30, :34` y HTTP `AlcanceSucursalHttpTests.cs:82-84` | Mata por valor |
| 23 | `Evaluar` | `OrdinalIgnoreCase` → `Ordinal` | `:41` (`suc1`, ` SUC1 `) | Mata por valor |
| 24 | `Evaluar` | evaluar al SUPER | `:53` | Mata por valor |
| 25 | `Evaluar` | regla antes de «inhabilitada» | `:82` | Mata por valor |
| 26 | `Evaluar` | regla después de `Validar(sesión)` | ninguna | **No se prueba** (P168-10) |
| 27 | `Evaluar` | quitar la comparación de empresa | `:105-123` | Mata por valor |
| 28 | `Restringida` | invertir `!= Super` o comparar sin distinguir mayúsculas | `:65-78` (incluye `"super"` y `null`) | Mata por valor |
| 29 | Pieza común | `default(AlcanceResuelto)` ≠ vacío | `AlcanceAlmacenesTests.cs:152-153` | Mata por valor |
| 30 | Pieza común | cuenta nula/inhabilitada ⇒ global | `:149-151`, `:199-205` | Mata por valor |
| 31 | Pieza común | `Operativo` sin permitidos o `Consulta` con ellos | `:121-127` | Mata por valor |
| 32 | Pieza común | no memoizar la lectura de la sucursal | ninguna | Equivalente funcional (rendimiento); AL-15 no lo cubre |
| 33 | Diseñador | quitar la comprobación en una de las 4 operaciones | `DisenoReportesRestringidoTests.cs:47-57` (recorre las 4) | Mata por valor |
| 34 | Diseñador | bloquear al SUPER con la bandera o al ADMIN global | `:64-70` | Mata por valor |
| 35 | Diseñador | comprobar después de ejecutar SQL | `:47-57` (la base no existe: la excepción sería `SqlException`) | Mata |

**Mutaciones relevantes que no se prueban:** #8 (saldo con almacén concreto), #26 (orden de `Evaluar`), «el chequeo de convertir en servicio usa el alcance» (F-05.6), «desmarcar `Requiere lote` ignora `conCifras`» (F-05.7 b), «`ImportacionMaestros` llama sin `conCifras`» (F-27), «`ExistenciasAsync` sin `Trim()`» (V-02), «vacío ⇒ todos del alcance» (V-03), «`DatoCosto` visible» (F-01), y cualquier cambio en la ruta de escritura de inventario (F-26). **Las categorías de B que sí tienen aserción por valor:** existencias, kárdex, saldo inicial sin almacén, pestaña, guardado, `Evaluar` (salvo el orden), `Restringida` y diseñador.

## 5. Fallos preexistentes de `feature/modelo-ng` (no ejecutados)

Los tres son pruebas **escritas el 2026-09-26** (`e2f59ba7`, «Inicio») contra el contrato de columnas de los reportes de ventas **anterior** a la reescritura sobre `rpt`. Dos veces quedaron desfasadas:

| Fecha | Commit | Efecto |
|---|---|---|
| 2026-10-05 | `5e6bf92e` (Ola 3) | Las facturas pasan al modelo nuevo y los reportes aún leían las tablas heredadas: se marca `[Trait("Transicion","Ola5")]` en `ReportesTests.cs:36` y `:135` y `SucursalOrigenTests.cs:70` (`git log -S` sobre el trait, único commit). `tests/GPOS.Tests/Transicion/ClasificacionPruebas.md:203` las lista como «los reportes de ventas leen el esquema heredado hasta `rpt`». El filtro oficial de la suite excluye `Transicion=Ola5`. |
| 2026-10-10 | `d5962a1b` (Ola 5, tramo 3, F7) | Los reportes pasan a `rpt.VentaDocumento` y cambian sus columnas. Actualizó `DrillDownTests` y `CostosTests` pero **no** estas tres, que siguen marcadas `Ola5` y rotas por otra causa. `ClasificacionPruebas.md` no se actualizó. |

**`ReportesTests.Filtra_antes_de_agrupar_y_totaliza`** (`ReportesTests.cs:37-65`). Afirma: dos facturas de 1 y 2 unidades a 100 con 18 % dan, para `VTA-POR-CLIENTE` filtrado por cliente, una fila con `fila[0]` = cliente, `fila[2]` = 2 facturas, `fila[5]` = 354 y `Totales[5]` = 354; y un Top 1 de `VTA-POR-ARTICULO` con 3 unidades. Causa probable: **[V]** `VTA-POR-CLIENTE` tenía las columnas visibles `Cliente, NombreCliente, Facturas, SubTotal, Itbis, Total` (`d5962a1b^`, `ReportesSemilla.cs:159-160`, `Total` en el índice 5) y ahora tiene `Cliente, NombreCliente, Documentos, VentaNeta` (`ReportesSemilla.cs:173-176`): el índice 5 no existe. **[V]** `VTA-POR-ARTICULO` pasó a `Registrado(...)` con clave `VTA-UTILIDAD-ARTICULO@1` y sin columnas (`ReportesSemilla.cs:184`), así que la segunda parte (`Limite = 1` y `VistaPreviaAsync`) ya no es un SQL del diseñador. **[I]** El 354 sí se conservaría como `VentaNeta` (`TotalBase × Signo`, artículo `ITBIS18`).

**`ReportesTests.Exporta_a_los_seis_formatos_conservando_tipos`** (`:136-181`). Afirma que `VTA-FACTURAS` exporta a pdf, xlsx, docx, csv, json y xml conservando tipos: `total = 2913.42` (2 × 1234,50 + 18 %) como número en xlsx, `Total` y `totales.Total` en json. Causa probable: **[V]** `Total` pasó de `Monto(..)` (con `Totalizar: true`, `d5962a1b^:128`) a `MontoDocumento("Total", ..)` sin `Totalizar` (`ReportesSemilla.cs:130, :162`); el exportador JSON solo escribe en `totales` las columnas con total no nulo (`ExportadorReporte.cs:245-248`), así que `GetProperty("Total")` de `totales` lanza `KeyNotFoundException`. **[I]** Es el primer fallo seguro solo si los pasos anteriores (pdf, xlsx, docx, csv) pasan; no sé cuál aserción rompe primero.

**`SucursalOrigenTests.Ventas_por_sucursal_y_campos_elegidos_por_el_usuario`** (`SucursalOrigenTests.cs:71-105`). Afirma: tres facturas exentas (100 y 50 en la sucursal A, 30 en B); `VTA-POR-SUCURSAL` filtrado por A da una fila con `NombreSucursal` = «Sucursal A», 2 documentos y un `Total` de 150; `VTA-POR-CLIENTE` con las columnas elegidas `Cliente, NombreSucursal, Total` da 2 filas con total 180; un campo falso se ignora. Causa probable: **[V]** `Total` ya no es columna de ninguno de los dos reportes (ahora `VentaNeta`): `r.Columnas.FindIndex(c => c.Campo == "Total")` devuelve −1 y `fila[-1]` lanza; la lista elegida `["Cliente","NombreSucursal","Total"]` devolvería `["Cliente","NombreSucursal"]`. **[I]** Si `rpt.CatSucursal.Descripcion` coincide con «Sucursal X» no lo verifiqué.

**Recomendación (seguimiento, ≈ 0,3 dp [I]):** reescribirlas contra las columnas nuevas (`Documentos`, `VentaNeta`, `TotalBase`) y quitar `Ola5`, o borrarlas con una nota en `ClasificacionPruebas.md` (la cobertura equivalente de `rpt` está en `SemillaReportesOla5Tests`, `IndicadoresVistasOla5Tests`, `MigracionOla5VistasTests`). `DrillDownTests.cs:51` conserva `Ola5` aunque `d5962a1b` la actualizó: revisar si el trait sobra. **B decide** entre reescribir y borrar; no es parte de E-1.

## 6. Qué no verifiqué

- **No compilé ni ejecuté nada**: ni las pruebas del PR, ni las mutaciones, ni los tres fallos, ni la suite oficial. Las cifras de B (48, 157, 9, 10, 14, 20 mutaciones) las tomé del PR y de los avisos sin reproducirlas.
- **No tengo el guion de las 20 mutaciones**: la tabla de §4 es mi reconstrucción, no la lista de B. «Mata por valor» es un juicio sobre la aserción, no una ejecución.
- Leí a fondo `AlcanceAlmacenesTests`, `SucursalTokenRestringidoTests`, `AlcanceSucursalHttpTests`, `DisenoReportesRestringidoTests`, `InyeccionAlcanceTests`, `EstadoSesionRestriccionTests`, `AdminSinRestriccionRutasTests`, y la mitad de `AdminSinRestriccionHttpTests`. De `RestriccionSoloSuper*`, `CuentaFueraDeAlcance*` y `LecturasCuentasRestringidoTests` (M-168-2 y S168, fuera de mi plan S-16) leí solo nombres, cabeceras y el arranque de `RestriccionSoloSuperTests`.
- No verifiqué: que `Escenario.ArticuloAsync` use `Datos.Id` (base de la probabilidad de P168-05); cómo se estampa `inv.Movimiento.Fecha` (riesgo de `DateTime.Today`); la nulabilidad de la columna `RestringirSucursal`; el contenido de `ManejadorAdminSinRestriccion`; el comportamiento con reenvío real a `GPOS.Reportes`; pantallas Web/MAUI; concurrencia del guardado (F-09.2); rendimiento de las consultas con alcance; si otras suites con fábricas propias (`EsquemaPendienteAccesoTests`, `RutasLicenciaHttpTests`) siguen verdes (las primeras usan inicio de sesión real y la segunda un host mínimo sin `Program` [V], así que probablemente sí [I]).
- No evalué la causa de los tres fallos con una ejecución: toda causa marcada [V] viene de comparar `ReportesSemilla.cs` antes y después de `d5962a1b` y de leer las aserciones; las [I] quedan por confirmar.
- Fixture y estimaciones de esfuerzo (dp) son mías, ±40 %.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\AppData\Local\Temp\claude\C--Users-lfmen-source-repos-Solucion-GPOS-NG-GPOS-NG\a3bc09e2-6f31-41d0-8b7c-bb380a2e9bc6\scratchpad\revision-pruebas-pr168.md` (sin commit ni publicación en el área común)
- Supuestos: (1) la reconstrucción de mutaciones de §4 sustituye al guion de B, que no está disponible; (2) las causas de los tres fallos son por lectura; (3) esfuerzos [I]
- Decisiones candidatas a ADR: Ninguna
- Entregas a otros agentes: B → responder P-03 (atributo o lista blanca) y P-04 (vacío = «sin almacén»), decidir el orden de `Evaluar` (P168-10), publicar el guion de mutaciones, decidir si reescribe o borra los 3 fallos Ola5; desarrollador (B) → P168-01, P168-05 y P168-06
- Próximo paso recomendado: arreglar la prueba inestable (P168-05) y escribir F-26.1/F-26.2/F-26.5/F-26.7 antes de empezar S-16b
