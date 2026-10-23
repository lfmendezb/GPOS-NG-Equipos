Para: B (copia a A, dueño de T4-06)        De: C        Fecha: 2026-10-23
Tipo: Entrega (tarea 1 de B-a-C/2026-10-23-tareas-nuevas-para-c-5: plan de pruebas de T4-06)
Prioridad: Media (antes del 3-nov)
Repositorio y rama: GPOS-NG `feature/modelo-ng` (lectura, punta `b9efa9fb`); hoja en `master`
Estado: Abierto (plan, sin código)

# Plan de pruebas de T4-06 (lista P-2 vacía y reenvío por ruta), versión 3 con las firmas del 2026-10-23

**Método:** solo lectura (`git fetch`, `git show`, `git grep` sobre `origin/feature/modelo-ng` `b9efa9fb`, que ya contiene el #202/T4-07 en `e0b17145`). Fuentes: blueprint de A (`traspasos/A/blueprint-t4-06-lista-p2-2026-10-22.md`, §15 y §17, en adelante BP), hoja `docs/decisiones/2026-10-23-hoja-firma-pr-d2-anillo-restaurar-y-t4-06.md` (en `master`, en adelante HOJA) y mi plan anterior `2026-10-22-plan-pruebas-t4-04-y-t4-06.md` (en adelante V2, §2, casos `L-xx`). **No compilé ni ejecuté nada.** `[V]` = visto en código; `[I]` = inferido.

**Firmado 2026-10-23 (PR #222):** el propietario aceptó M-2 del #217 con T4-06 como fecha de cierre. El cierre lo da la inversión de `Caracterizacion_pendiente_hoy_…` (caso T6-46b): hasta que esa prueba se invierta, el riesgo sigue abierto.

**Qué sustituye este plan:** las tablas `L-xx` de V2 §2 se conservan como base y aquí se **ajustan a lo firmado** (P-1 a P-4, Q-A4 segunda pregunta) y al estado real del código. Los ids nuevos son `T6-xx`; cuando un caso es un `L-xx` de V2 lo cito en «Origen». El resto de V2 (T4-04, DEMO) no cambia.

## 0. Lo que cambió desde BP/V2 y lo que encontré al leer el código

| # | Hallazgo | Evidencia | Efecto en las pruebas |
|---|---|---|---|
| H-1 | **T4-04 ya está unido.** `EjecucionReglas.Modo(reenvioHabilitado, release, enLaPrincipal)`, `ModoReporte.NoDisponible`, `ReportesNoDisponibleException` y `ReporteEnLaPrincipalAsync` existen en `feature/modelo-ng`. BP daba por hecho que T4-06 se unía antes que T4-04 (TA-3 «guarda Release en `EjecucionReglas`») | `TrabajoNotificaciones.cs:~60-215`; `NotificacionesReportesTests.cs:511-545` [V] | P-2 (a) se reduce a **retirar el parámetro `enLaPrincipal` y proteger `ReporteEnLaPrincipalAsync` con `#if DEBUG`** (usa `ReportesService.EjecutarAsync`, que dejará de compilar en Release). Los casos de P-2 (T6-40 a T6-47) son otros que los de L-34 |
| H-2 | **Tres pruebas que fijan la lista no figuran en BP §11.1** y dejan de compilar o de tener sentido: `NotificacionesReportesTests.Sin_la_API_de_reportes_…` (`:513-514`, pasa `enLaPrincipal:`), `Los_reportes_de_la_lista_P2_programados_siguen_en_la_principal` (`:537-540`, usa `ReportesSemilla.EnLaPrincipal`), y las líneas `:823-828` y `:934` (`EnLaPrincipal` en otras dos) | `git grep EnLaPrincipal` [V] | T6-46: reescritura obligatoria; se rompe la compilación de `GPOS.Tests` si A no las toca |
| H-3 | **O175-01** (riesgo Medio aceptado hasta T4-06: el programado de la lista P-2 corre con la sesión sintética de administrador y puede mandar costos a un autor sin «Ver costos») queda cerrado **solo si** ningún reporte del sistema vuelve a `ReporteEnLaPrincipalAsync` | comentario de `TrabajoNotificaciones.cs:~195` [V] | T6-44 lo prueba con un autor sin «Ver costos» |
| H-4 | **El grupo `/api/admin/reportes` ya lleva `RequiereAdminSinRestriccion()`** (S168-02). Un ADMIN restringido recibe en la principal el 403 de la política (`RESTRICCION_SUCURSAL_ADMIN`) **antes** de llegar a `ReportesService` o al reenvío. Por eso el 403 `DISENO_NO_PERMITIDO` del §17 de BP **no es alcanzable por HTTP desde la principal** con un restringido real | `ReportesEndpoints.cs:96`, `AdminSinRestriccion.cs` [V] | La propagación del 403 de `IDetectorColumnas` (P-1) se prueba **a nivel de unidad** con un doble de la canalización (T6-20 a T6-24), no solo por HTTP. Duda D-1 |
| H-5 | **Ya existe la comprobación local de diseño** (`ReportesService.SoloDisenadorAsync`: `AccesoDenegadoException` con `CodigoDisenoNoPermitido`, antes de validar o ejecutar). Guardar la llama primero (`:~108`). Por eso en Debug Guardar y eliminar ya dan `DISENO_NO_PERMITIDO` si se salta la política (servicio directo) | `ReportesService.cs:261-271` [V] | T6-25: la paridad Debug se prueba sobre el servicio; no hay que construirla |
| H-6 | **Q-A4 segunda pregunta aún no tiene código:** `grep SUCURSAL_NO_PERMITIDA` en `GPOS.Core` y `GPOS.Api` da cero resultados; el código solo existe en `GPOS.Reportes` y `GPOS.Web`. La ejecución local de `ReportesService` no consulta el alcance de sucursal (solo `SoloDisenadorAsync`) | [V] | Los casos T6-50 a T6-56 son pruebas **rojas primero**: deben fallar hoy |
| H-7 | **Ortografía del código:** BP §17.1 escribe `SUCURSAL_NO_PERMITIDO` (con O final); la HOJA, `ErroresLectura.cs:90` y `Tablero.razor` usan **`SUCURSAL_NO_PERMITIDA`** | [V] | Todas las aserciones usan la forma con A. La prueba T6-56 compara con la constante de `GPOS.Reportes`, no con un literal |
| H-8 | `ReenvioReportes.NoDisponible()` ya existe y es **público y estático** (agregado por #202) y devuelve 503 `REPORTES_NO_DISPONIBLE` con título «Reportes no disponibles» | `ReenvioReportes.cs:357` [V] | T6-10 a T6-13 comparan contra esa misma función (no contra un literal) y T6-14 vigila que no aparezca un segundo 503 propio |
| H-9 | `ReenvioReportes.ValidarModo`, `CompilacionDepuracion` (en `GPOS.Api`), `IDetectorColumnas`, `DetectorColumnasReenvio` y `ReportesService.Ejecucion.cs` **no existen** todavía. Existe otro `CompilacionDepuracion` en `ProteccionDatosInstalacion`, `ProteccionDatosWeb` y `ComandoLlaveFirma` | `git grep` [V] | La guarda de `Publicar-PaqueteDemo.ps1:85` busca el literal **solo en `ReenvioReportes.cs`**; T6-70 lo fija |

## 1. Convenciones

- **Nivel:** U = unidad sin base; S = servicio con base `GPOS_TEST_*`; H = HTTP con `ApiMvpFactory` y el doble de la API de reportes (`api.ApiReportes`, con `Caida` y `Peticiones`, como en `NotificacionesReportesTests`); TX = prueba textual sobre fuentes (en `GPOS.Reportes.Tests` o `GPOS.Tests`); ARQ = por símbolos del ensamblado; BLD = comando de compilación (criterio de PR); VM = laboratorio (no suite).
- **La suite compila Debug.** Todo lo que dice «en Release» se prueba por una de tres vías: la costura (`ValidarModo(op, depuracion)`), la prueba textual de `#if DEBUG`, o BLD. No se afirma comportamiento Release por HTTP.
- **Mutación:** cambio mínimo al código de T4-06 que **debe** poner la prueba en rojo. «Cumplida» = la ejecuté contra una rama con la mutación. Todas están **sin ejecutar** (no hay código): la columna es el contrato para quien las implemente; la regla del equipo C es que A anote en el PR el resultado de cada mutación marcada con `*` (las imprescindibles).
- **Compilaciones:** el plan no exige más de 3 a la vez; BLD-1 a BLD-4 son secuenciales (§4).
- Sin `Thread.Sleep`; cuentas con `Datos.Id`; una base por clase (mis reglas anti-inestables).

## 2. Casos

### 2.A La lista P-2 ya no existe y las 11 definiciones leen `rpt`

| ID | Prueba | Nivel | Esperado | Mutación | Origen |
|---|---|---|---|---|---|
| T6-01* | `AuditoriaAdr109Tests.P2_la_lista_ya_no_existe_y_ningun_reporte_del_sistema_lee_fuera_de_rpt` (sustituye a `P2_la_lista_de_reportes_que_ejecuta_la_principal_solo_puede_encogerse`, `:38`). Textual: `EnLaPrincipal`, `IntactoEnLaPrincipal`, `EnLaPrincipalAsync` y `HuellasCodigo` no aparecen en `src/**/*.cs`; todo `FROM` o `JOIN` dentro de los literales SQL de `ReportesSemilla.cs` nombra `rpt.` y ninguno `rptc.` | TX | verde | (a) volver a declarar `EnLaPrincipal` vacía; (b) dejar un `FROM cxc.Cuenta` en el 22; (c) usar `rptc.` en el 23. Las tres en rojo | V2 L-01, BP §11.1 |
| T6-02 | Guarda por símbolo en `GPOS.Tests` (el proyecto de reportes no ve Core): `typeof(ReportesService)` no tiene `EnLaPrincipalAsync`; `typeof(ReportesSemilla)` no tiene `EnLaPrincipal` ni `IntactoEnLaPrincipal` (reflexión, `BindingFlags.NonPublic|Public|Static`) | ARQ | verde | Reintroducir el método privado: rojo | V2 L-02 |
| T6-03* | `SemillaReportesOla5Tests`: la prueba `Los_registrados_…_y_P2_lista_los_que_no_tienen_vista` (`:52-65`) se sustituye por `Ningun_SQL_del_sistema_lee_tablas`: toda definición `Fuente = SQL` de la semilla contiene `rpt.`; la teoría `DeVistas` (`:21-50`) corre ahora las **11** con `gpos_reportes` | S | verde; las 11 corren con el login de lectura | Dejar el reporte 15 con `FROM cxp.Cuenta`: la teoría falla con el rechazo del esquema | V2 L-05 |
| T6-04 | Moneda base: con una fixture de dos monedas (tasa distinta de 1) los totales de 8, 9, 10, 27, 13, 14, 15, 16, 21, 22, 23 coinciden con un cálculo independiente `ROUND(monto × tasa, 2)` por fila; las columnas totalizadas terminan en `Base` (`CorrienteBase`, `De1a30Base`, `De31a60Base`, `De61a90Base`, `Mas90Base` en 8 y 15). La regla de `SemillaReportesOla5Tests.cs:35-36` rechaza una totalizada sin `Base` | S | verde | Totalizar `Balance` en lugar de `BalanceBase` en el 8: rojo por diferencia de moneda | V2 L-03; P-5 |
| T6-05 | Sin `ORDER BY` en el SQL de las 11 (`ValidarConsulta` y `AnalizadorSql.cs:119` lo rechazan) y con `OrdenarPor` definido | S | verde | Pegar el `ORDER BY` de N1: rechazo de la semilla | V2 L-03 |
| T6-06 | Paridad de **conjunto de documentos** (no de montos) contra el SQL antiguo guardado como oráculo en la prueba: mismos `Documento`/`Factura` por reporte, sobre la fixture. El 15 trae NCF del B11; el 23 filtra HOY por omisión (Q-T4D-02): el oráculo del 23 aplica el mismo filtro | S | verde | Agregar `WHERE Balance > 0` a la vista del 10: pierde documentos saldados | V2 L-04 |
| T6-07 | Enlaces y detalles: `Documento`, `Factura`, `Cliente` y `Suplidor` siguen en las columnas de las definiciones nuevas; `Detalles` y `EnlaceDe` (`ReportesSemilla.cs:507-520`) resuelven | S | verde | Renombrar `Documento` a `Doc` en el 8: rojo | V2 L-07 |
| T6-08 | `HuellasVersion1` se conserva: un reporte del sistema intacto pasa a la versión nueva con `ActualizarSistemaAsync`; uno **modificado por un ADMIN** conserva su SQL (no se pisa) y por la API de reportes falla con el rechazo del esquema | S, H | verde | Borrar `HuellasVersion1`: el intacto no se actualiza (rojo); actualizar sin comparar huella: se pisa el del ADMIN (rojo) | V2 L-06 |
| T6-09 | Cantidad: el catálogo trae el mismo número de reportes del sistema que antes de T4-06 (sin altas ni bajas); el número se lee de la semilla, no de un literal. **Duda D-6** (26 o 27) | S | verde | Omitir el 27 en la semilla: rojo | V2 Q-9 |

### 2.B Lista siempre local; todo lo demás, por reenvío; 503 con `ReenvioReportes.NoDisponible()`

| ID | Prueba | Nivel | Esperado | Mutación | Origen |
|---|---|---|---|---|---|
| T6-10* | `ReenvioReportesTests.La_lista_la_responde_la_principal_aunque_la_API_de_reportes_no_responda` (`GPOS.Tests/Mvp`, archivo nuevo): con `api.ApiReportes.Caida = true`, `GET /api/reportes` da 200 con la lista completa y **cero** peticiones a la API de reportes | H | 200; `Peticiones` vacío | En el endpoint `"/"` llamar a `reenvio.ReenviarAsync`: 503 o petición registrada (rojo) | V2 L-11, BP §11.2 |
| T6-11* | Con la API caída: `POST /{id}/ejecutar` de un reporte del sistema (p. ej. `CXP-FACTURAS`) responde 503 con el cuerpo de `ReenvioReportes.NoDisponible()` (mismo `codigo`, mismo `statusCode`) | H | 503 `REPORTES_NO_DISPONIBLE` | Hacer que el reporte caiga al camino local (como hoy con la lista P-2): 200 en lugar de 503 | V2 L-11 |
| T6-12 | `GET /api/reportes/{id}` también da 503 al abrir (BP P-8: se reenvía); no 500 ni lista vacía. **Pregunta D-4**: BP la propone y B no la contestó en la HOJA | H | 503 | Responder desde la principal: 200 con la definición (rojo si B confirma P-8) | V2 L-11b |
| T6-13 | `GET /{id}/exportar/{formato}` con la API caída: 503 y **ninguna fila nueva** en `audit.Exportacion` | H, S | 503; evidencia sin cambios | Armar el archivo local: 200 y fila de evidencia | V2 L-11c |
| T6-14* | Textual (`AuditoriaAdr109Tests.Todas_las_rutas_de_reportes_reenviables_…`, `:81`): `g.MapGet("/"` sale del recorrido de «debe llamar al reenvío» y se verifica que su cuerpo **no** contiene `reenvio.`; las demás rutas reenviables contienen `reenvio.` y **ninguna** contiene `Results.Problem(` con `REPORTES_NO_DISPONIBLE` propio (siempre `ReenvioReportes.NoDisponible()`); el conteo del tablero (`:96`, igual a 2) no se toca | TX | verde | (a) agregar `reenvio.` a la lista; (b) quitar `reenvio.` de `/ejecutar`; (c) copiar el 503 en un literal: tres rojos | V2 L-10 |
| T6-15 | El cuerpo del 503 no filtra ruta interna, excepción ni dato de empresa; el campo `codigo` es `REPORTES_NO_DISPONIBLE`; el `title` es el de `NoDisponible()` | H | verde | Poner `ex.Message` en `detail`: rojo (busca `Pipe`, `localhost`, `GPOS.Reportes`) | V2 L-14 |
| T6-16 | Id inexistente, o de otra empresa, da 404/403 igual que antes y sin mensaje distinto (sin canal lateral entre «no existe» y «no es suyo») | H | verde | Devolver «el reporte pertenece a otra empresa»: rojo | V2 L-15 |
| T6-17* | `ListaReportesContratoTests.La_lista_y_la_definicion_coinciden_en_visibilidad_para_USER_ADMIN_y_SUPER`: para USER sin permisos, USER con `ReportesVentas` y `ReportesCompras`, ADMIN y SUPER, cada `Id` de la lista responde 200 en `GET /{id}` (por el reenvío) y uno que no está en la lista, 403 o 404. Ayudante mínimo del SUPER (P-7 (a)) | H | verde | Hacer que `Puede` de la lista deje pasar `SoloAdmin` a un USER: el `GET /{id}` de la API de reportes da 403 y la prueba falla | V2 L-12, BP P-7 |
| T6-18 | Con el nivel efectivo rebajado en `rptsis` (SUPER con nivel menor): la lista y la definición siguen coincidiendo, o la prueba documenta la divergencia con `Trait("Decidido","no-implementado")` si D5/T1-5 aún no la cierra (alarma de BP R-3) | H | verde o caracterización | n/a (es la alarma) | BP R-3 |

### 2.C P-1 (a): Guardar valida las columnas por la API de reportes y propaga el 403 `DISENO_NO_PERMITIDO`

`IDetectorColumnas` (Core) + `DetectorColumnasReenvio` (Api). Por H-4, lo central va a nivel de unidad con un `HttpMessageHandler` doble en lugar de la canalización.

| ID | Prueba | Nivel | Esperado | Mutación | Origen |
|---|---|---|---|---|---|
| T6-20* | `DetectorColumnasReenvio`: la API de reportes responde 403 con `codigo = DISENO_NO_PERMITIDO`. Lanza `ReglaNegocioException` con `EstadoRegla = 403` y `CodigoRegla = "DISENO_NO_PERMITIDO"` y el mismo texto (`ReportesService.MensajeDisenoNoPermitido`) | U | verde | Mapear **todo** error a `ReportesNoDisponibleException` (503): rojo | BP §17.2-17.3 «Un_403…_nunca_se_vuelve_503» |
| T6-21* | Teoría de estados: 403 con otro `codigo` (p. ej. `SUCURSAL_NO_PERMITIDA`) se propaga con su propio código y 403; 400/422 de la API (consulta mal formada, esquema rechazado) conservan su estado y mensaje; 401 no se disfraza de 503 | U | cada estado sale igual que entró | Colapsar todo 4xx a 400: rojo | BP §17.2 («cualquier otro rechazo mantiene su estado») |
| T6-22* | **503 solo si la API cae:** doble que lanza `HttpRequestException`/`IOException`/`CanalSuplantadoException`/timeout: sale `ReportesNoDisponibleException` (503 `REPORTES_NO_DISPONIBLE`, el texto de `ReenvioReportes`). **Un 5xx de la API que no es de disponibilidad (500)** también queda 503 pero **sin** el cuerpo interno | U | verde | Dejar pasar `HttpRequestException` sin traducir: 500 (rojo) | BP §5 |
| T6-23 | Respuesta 200 con JSON mal formado, vacío o con columnas duplicadas: error de regla 400 «La consulta no devuelve…» (no 500, no guardar) | U | verde | Deserializar sin validar: `NullReferenceException` | BP §6 |
| T6-24 | El detector Release lleva el **token de la petición en curso** y ningún otro: la petición al doble tiene `Authorization` igual al entrante; sin token en la petición, no hay llamada y falla cerrado | U | verde | Sustituir por un token de servicio: rojo | BP §6 |
| T6-25 | Paridad Debug sobre `ReportesService` (servicio directo, sin política): ADMIN restringido en Guardar, eliminar, `DetectarColumnasAsync` y `VistaPreviaAsync` → `AccesoDenegadoException` con `CodigoDisenoNoPermitido` y el mismo mensaje que `ErroresLectura.DisenoNoPermitidoException`; **antes** de validar o abrir conexión (contador de conexiones a la empresa = 0). El SUPER con la bandera nunca se restringe (Q-A5) | S | verde | Mover `SoloDisenadorAsync` después de `ValidarDefinicionAsync`: abre conexión (rojo) | BP §17.2; H-5 |
| T6-26* | **Guardar no ejecuta SQL con la fábrica de escritura en Release** (H-A06-01): Guardar recibe `IDetectorColumnas`; en la prueba se inyecta el detector doble y se afirma que `IEmpresaDbFactory` **no se invoca** durante Guardar con el reenvío encendido. Un SQL sobre tablas (`FROM cxc.Cuenta`) **no se guarda**: 400 «La consulta no devuelve…» o el rechazo del esquema de la doble API; nunca 200 | S, H | no guarda; contador de la fábrica = 0 | En Guardar llamar a `EsquemaAsync` local (hoy): la fábrica se invoca y el SQL se guarda (rojo) | V2 L-30; BP §11.2 |
| T6-27 | Con la API caída Guardar da 503 `REPORTES_NO_DISPONIBLE` y **no** crea ni modifica la fila de `dbo.Reportes` | H, S | 503; sin fila | Guardar y validar después: fila creada (rojo) | V2 L-31; BP R-7 |
| T6-28 | El detector Release valida con `gpos_rpt` sobre `rpt`: un SQL que solo el login de escritura veía (tabla fuera de `rpt`) no se guarda. Con el doble de la API que usa `gpos_reportes` real si existe el fixture `ApiReportesEnProceso` | H, S | no guarda | Usar la ruta local: se guarda (rojo) | V2 L-32 |
| T6-29 | **Mutación del 403 por HTTP en la principal**: ADMIN restringido real → `POST /api/admin/reportes` da 403. **El código esperado depende de D-1** (política `RESTRICCION_SUCURSAL_ADMIN` o `DISENO_NO_PERMITIDO`). La prueba afirma el 403 y que **no** hay llamada a la API de reportes ni escritura; el código se fija cuando B responda D-1 | H | 403, sin petición ni escritura | Quitar `RequiereAdminSinRestriccion()` del grupo: pasa a la comprobación del servicio (otro código); si D-1 = «cualquiera de los dos» no falla | BP §17.1; H-4 |
| T6-30 | Eliminar (`DELETE /api/admin/reportes/{id}`) con restringido: 403 y la fila intacta; la guarda local de BP 17.1 se retira cuando la política cubre la ruta (no hay segunda guarda) | H, S | 403; fila intacta | Quitar la política y la guarda local: borra (rojo) | BP §17.3 «Eliminar…restringido…403» |
| T6-31 | Detectar y vista previa con restringido: 403 por la política en HTTP; sin reenvío (Debug), `DISENO_NO_PERMITIDO` por servicio (T6-25) | H, S | 403 | Idem T6-29 | BP §17.3 |

### 2.D P-2 (a): programados y «Ejecutar ahora» sin camino local en Release

El Release real se prueba por costura y por texto; Debug sigue conservando el camino local para el desarrollo.

| ID | Prueba | Nivel | Esperado | Mutación | Origen |
|---|---|---|---|---|---|
| T6-40* | `EjecucionReglas.Modo` ya no tiene el parámetro `enLaPrincipal`: tabla completa `(reenvio, release)`: `(true, *)` → `ApiReportes`; `(false, true)` → `NoDisponible`; `(false, false)` → `Principal`. No hay combinación que dé `Principal` con el reenvío encendido | U | verde | Restaurar `enLaPrincipal` con default true: el caso `(true,true)` da `Principal` (rojo) | H-1; HOJA P-2 |
| T6-41* | Un reporte **del sistema** programado (antes de la lista: `CXP-FACTURAS`, `CXP-PAGOS`) con el reenvío encendido se arma en la API de reportes: el doble registra la petición, hay token de servicio solicitado y `Peticiones(reporte)` no está vacío (el espejo de `Un_programado_se_ejecuta_en_la_API_de_reportes_sin_abrir_conexion_de_empresa_en_la_principal`, `:412`) | H | verde | Dejar `enLaPrincipal` implícito para los de la semilla: la petición no llega al doble | `Los_reportes_de_la_lista_P2_programados_siguen_en_la_principal` (`:537`) pasa a invertirse |
| T6-42* | **Falla cerrada (P-2 (a))** con el reenvío apagado en Release: regla programada y «Ejecutar ahora» terminan con `Enviado = false`, mensaje de `ReportesNoDisponibleException`, `RegistrarResultadoReglaAsync` con ese mensaje, **sin correo en la cola, sin fila en `audit.Exportacion` y sin abrir conexión de empresa**. Se ejercita por la costura `Modo` + el método `ReporteAsync` con `release` inyectable [I: hoy lo lee de `OpcionesSegundoFactor.Release`; ver D-3] | H, U | verde | Hacer que `NoDisponible` caiga a `Principal`: manda correo (rojo) | V2 L-34; N-01 |
| T6-43 | «Ejecutar ahora» (`POST /api/admin/notificaciones/reglas/{id}/ejecutar`) y el trabajo programado devuelven el **mismo** resultado para el mismo estado de la API (misma rama `Modo`) | H | verde | Una sola de las dos rutas llama a `Modo` con `release: false` fijo: difieren (rojo) | V2 |
| T6-44* | **Cierre de O175-01:** un autor de regla **sin** «Ver costos» programa `CXP-FACTURAS` (con columna de costo): el adjunto sale por la API de reportes con el token de servicio del autor y **no contiene** las columnas `DatoCosto`; en ningún caso corre `ReporteEnLaPrincipalAsync` (sesión sintética de administrador) | H, S | verde | Volver a enrutarlo a la principal: el adjunto trae costos (rojo) | H-3; V2 N-12 |
| T6-45* | Textual: `ReporteEnLaPrincipalAsync` y su llamada están dentro de `#if DEBUG`…`#endif`; no hay referencia a `ReportesService.EjecutarAsync` ni a `ExportadorReporte.Exportar` fuera de bloques `#if DEBUG` en `TrabajoNotificaciones.cs` y `ReportesEndpoints.cs` | TX | verde | Sacar la llamada del bloque: rojo (y BLD-2 no compila: doble red) | BP §7.1 |
| T6-46* | Reescrituras forzadas por H-2: `Sin_la_API_de_reportes_la_regla_registra_el_fallo_y_no_envia` sin el argumento `enLaPrincipal:`; `Los_reportes_de_la_lista_P2_programados_siguen_en_la_principal` se **elimina o invierte** (T6-41); `:823-828` y `:934` dejan de citar `ReportesSemilla.EnLaPrincipal` | S | `GPOS.Tests` compila | Dejar una referencia: error de compilación (BLD-1) | H-2 |
| T6-46b* | **Cierre del riesgo M-2 del #217 (aceptado por el propietario con T4-06 como fecha de cierre; firmado 2026-10-23, PR #222).** `NotificacionesReportesTests.Caracterizacion_pendiente_hoy_un_P2_programado_del_SUPER_o_de_un_autor_inhabilitado_se_envia_sin_pasar_por_el_emisor` (`:932`) fija hoy que una regla del SUPER o de un autor inhabilitado sobre `CXP-FACTURAS` **se envía** sin pasar por el emisor (usa `ReportesSemilla.EnLaPrincipal`, que T4-06 elimina). **Su inversión es la que cierra el riesgo**: se renombra (sin «pendiente_hoy»), se quita el `Assert.Contains("CXP-FACTURAS", ReportesSemilla.EnLaPrincipal)` y las aserciones pasan a exigir que ambas reglas **pasen por el emisor de T4-04**: hay solicitud de token de servicio y el emisor deniega (`Denegaciones` contiene la regla), `Enviado = false`, ningún correo en la cola, ninguna petición armada con sesión sintética de administrador. El mensaje exacto lo fija T4-04 [I]. Con T6-44 y T6-41 forman el cierre completo de O175-01; si esta prueba no se invierte, el riesgo M-2 sigue abierto y T4-06 no debe unirse | H | verde | Dejar la caracterización como está: no compila tras borrar `EnLaPrincipal` (BLD-1), o, si se conserva el símbolo, el envío sigue ocurriendo (rojo) | M-2 #217; H-2; T6-41, T6-44, T6-46 |
| T6-47 | `AE_02_el_envio_programado_queda_como_programado_con_la_regla_y_quien_la_guardo` (`:408`) sigue verde en Debug (camino local de desarrollo) o, si se mueve a la API, mantiene sus aserciones de evidencia (`programado:regla {Id}`) | H, S | verde | Perder `UsuarioModificacion` en los parámetros de la evidencia: rojo | BP §11.1 |

### 2.E Q-6 y P-3: la principal Release no arranca sin reenvío; no arranca en Linux

| ID | Prueba | Nivel | Esperado | Mutación | Origen |
|---|---|---|---|---|---|
| T6-60* | `ReenvioReportesTests.En_Release_la_principal_no_arranca_sin_el_reenvio`: `ReenvioReportes.ValidarModo(op sin dirección, depuracion: false)` lanza `InvalidOperationException` cuyo texto contiene «GPOS:Reportes:Reenvio:Direccion» y «Q-6»; con `depuracion: true` no lanza | U | verde | Invertir el `if`: Release arranca sin dirección (rojo) | V2 L-20; HOJA P-2/Q-6 |
| T6-61 | `ValidarModo` con dirección válida y `depuracion: false` o `true` no lanza (el reenvío encendido no se rompe); con dirección **inválida** (no loopback, https) sigue lanzando el error de `ValidarDireccion` en cualquier modo | U | verde | Saltar `ValidarDireccion` cuando `depuracion`: acepta `http://otro-equipo` (rojo) | `ReenvioReportesSeguridadTests` |
| T6-62* | **P-3 (a):** Linux + Release sin socket Unix: la principal no arranca. El mensaje de `AgregarReenvioReportes` (`OperatingSystem.IsWindows()`) se mantiene y menciona que el reenvío solo existe en Windows. Para probarlo desde Windows hace falta una costura (D-2): `ValidarModo(op, depuracion, esWindows)` con `esWindows:false`. Sin la costura la prueba es textual: el literal «solo existe en Windows» sigue en `ReenvioReportes.cs` y el chequeo precede al registro del cliente | U/TX | `InvalidOperationException` | Quitar el chequeo de Windows: en Linux arranca y el 503 llega a la primera petición (rojo) | HOJA P-3 |
| T6-63 | Debug en Linux sin dirección arranca (camino local, desarrollo); Debug en Linux **con** dirección falla (nadie puede usar la canalización) | U | verde | n/a | HOJA P-3 |
| T6-64* | `CompilacionDepuracion` en `GPOS.Api` refleja el símbolo `DEBUG` del ensamblado de la API (no de Core): comprobado textual (`#if DEBUG` → `true`) y que `GPOS.Core.csproj` tiene la misma guarda del símbolo que `GPOS.Api.csproj:42-51` (Release con `DefineConstants=DEBUG` no reactiva la ejecución) | TX | verde | Quitar la guarda de `GPOS.Core.csproj`: rojo | BP §7.1 |
| T6-65* | Textual: `ReportesService.Ejecucion.cs` existe, **empieza** con `#if DEBUG` y **termina** con `#endif`, sin `#if` intercalados; contiene `EjecutarAsync`, `ExportarAsync`, `VistaPreviaAsync`, `DetectarColumnasAsync`, `DetalleAsync`, `EsquemaAsync`, `EjecutarLecturaAsync`; `ReportesService.cs` ya **no** las contiene | TX | verde | Dejar `EjecutarLecturaAsync` en el archivo principal: Release compila la conexión de escritura (rojo) | V2 L-22 |
| T6-66 | Sin truncado silencioso: `resultado.Truncado` y el tope `MaximoFilas` de ejecución local ya no compilan en Release; un reporte de más de 10.000 filas por la API de reportes responde lo que decida esa API (413 `REPORTE_DEMASIADO_GRANDE` o completo), nunca 10.000 en silencio. `ConsultaFacturasEndpoints.cs:71` **conserva** su truncado hasta T4-08 (aserción textual para que nadie lo toque en este PR) | H, TX | verde | Mover `Truncado` fuera del `#if`: textual rojo | V2 L-23 |
| T6-67 | `Limite` válido máximo: `ResultadoReporte.MaximoFilas` sigue como tope válido en Guardar (`ReportesService.cs:198`); un `Limite` mayor se rechaza; el menor se conserva | S | verde | Quitar la validación: se guarda un `Limite` de 1 000 000 | V2 L-24 |

### 2.F Q-A4 segunda pregunta (a): 403 `SUCURSAL_NO_PERMITIDA` también en Debug

Camino local de Debug sin reenvío. Hoy no existe (H-6): **estas pruebas deben estar rojas antes de implementar** y verdes después. Interpretación de partida (D-5): «restringido» = cuenta con bandera, sin ser SUPER (`UsuarioAlcance.Restringe`), leída del servidor.

| ID | Prueba | Nivel | Esperado | Mutación | Origen |
|---|---|---|---|---|---|
| T6-50* | Debug sin reenvío, ADMIN restringido: `POST /{id}/ejecutar` → 403 con `codigo = SUCURSAL_NO_PERMITIDA` y **0 conexiones** a la base de empresa | H | 403 | No comprobar: 200 con datos de todas las sucursales (rojo). Es la prueba que cierra R-14 | HOJA Q-A4(a); BP §17.1 |
| T6-51* | Ídem para un **USER** restringido (no solo ADMIN) | H | 403 | Comprobar solo `EsAdmin`: USER pasa (rojo) | `UsuarioAlcance.Restringe` |
| T6-52 | Ídem en `GET /{id}/exportar/{formato}`: 403 y **sin** fila en `audit.Exportacion` | H, S | 403; sin evidencia | Comprobar solo en `/ejecutar`: la exportación entrega datos (rojo) | HOJA |
| T6-53 | Ídem en `GET /{id}` **no** bloquea (es la definición, no datos)… **o** sí, según D-5. Hasta que B responda se omite y se documenta | H | por decidir | n/a | D-5 |
| T6-54 | El restringido en Debug conserva `GET /api/reportes` (lista, 200); la lista no ejecuta nada y no lleva el 403 | H | 200 | Poner la comprobación en la lista: 403 (rojo) | BP §17.1 |
| T6-55* | El SUPER con la bandera (restringido «en papel») y el ADMIN/USER **sin** bandera pasan con 200 en Debug (Q-A5; M-168-1) | H | 200 | Comprobar `RestringirSucursal` sin pasar por `UsuarioAlcance.Restringe`: el SUPER recibe 403 (rojo) | M-168-1 |
| T6-56 | El código y el mensaje son los de la API de reportes: la aserción compara con la constante pública de `GPOS.Reportes` (o la copia verificada por ARQ), no con un literal; paridad de texto entre `ErroresLectura.cs:90` y el local | ARQ | verde | Escribir `SUCURSAL_NO_PERMITIDO`: rojo | H-7 |
| T6-57* | La restricción se lee de la cuenta guardada en `GPOS_SYSDATA`, **no del token**: cuenta que se restringe **después** de emitir el token (token sin sucursal restringida) recibe 403 en la siguiente petición; cuenta a la que se le quita la restricción, 200 (o 401 por Q-A2 si cambió de sucursal) | H | verde | Leer el claim: 200 con el token viejo (rojo) | BP §17.2 |
| T6-58 | Programado en Debug sin reenvío con el autor restringido: la regla falla (la sesión sintética de administrador del trabajo **no** puede saltarse el 403). **Duda D-7**: BP no dice qué pasa con el programado local | H | por decidir | Ejecutar con sesión sintética: sale con datos (rojo si D-7 = sí bloquear) | D-7 |
| T6-59 | Bitácora de seguridad: el 403 local de Debug deja `ACCESO_RECHAZADO_SUCURSAL` (como el de la política) con método y plantilla de ruta, sin valores. Solo si B lo quiere (D-8); no bloquea | H | por decidir | n/a | `AuditoriaRestriccionSucursal` |

### 2.G P-4: el marcador `CompilacionDepuracion` y los consumidores de la unión

| ID | Prueba | Nivel | Esperado | Mutación | Origen |
|---|---|---|---|---|---|
| T6-70* | `PublicarPaqueteDemoTests` (`:30`, `:49`): sigue verde sin cambios. `ReenvioReportes.cs` contiene el literal `CompilacionDepuracion` y `Publicar-PaqueteDemo.ps1:85` lo busca en `src\GPOS.Api\Endpoints\ReenvioReportes.cs`. Si T6-60 mueve el literal a otro archivo, la prueba y el guion se quedan ciegos | TX | verde | Renombrar a `EsDepuracion`: rojo en `PublicarPaqueteDemoTests` y en T6-70 | HOJA P-4; V2 L-35 |
| T6-71 | La guarda **detecta** el árbol con Q-6: un árbol de prueba con el literal rechaza publicar sin `-ConApiReportes`; sin el literal publica | TX | verde | Cambiar el `-match` a otro texto: la prueba de `PublicarPaqueteDemoTests` falla | DEMO §3.2 |
| T6-72 | `tests/GPOS.EnsayoImplantacion/iniciar-api.ps1:22` y `README.md:17-18` siguen compilando Debug (comentario P-4) hasta la tarea 3; textual: el script no arranca Release sin `Reenvio__Direccion` | TX | verde | Cambiar a Release sin dirección: el ensayo no arranca (VM) | HOJA P-4 (primera parte) |
| T6-73 | `instalador/Demo/Publicar-PaqueteDemo.ps1:130-134` (rechaza que el paquete traiga `Reenvio:Direccion`) no se toca en este PR; el DEMO de `feature/modelo-ng` **no** se publica entre la unión de T4-06 y la tarea 3 (firma de la HOJA). Verificación humana en el PR, no prueba automática | VM | n/a | n/a | BP §7.2 |

### 2.H Reescrituras de pruebas existentes (revisar cada una al adaptarla)

| ID | Prueba existente | Cambio | Comprobación de que no quedó hueca |
|---|---|---|---|
| T6-80 | `ReportesF9Tests.T3_02_un_reporte_P2_modificado_por_el_ADMIN_no_corre_en_la_principal` (`:286`) → `Ningun_reporte_del_sistema_se_ejecuta_en_la_principal` | Para cada reporte del sistema de la lista, `ejecutar` da 200 con `Metadatos["rnc"]` (solo lo pone la API de reportes; el camino local no, `ReportesService.cs:~384`). Se **conserva** la copia modificada por un ADMIN que lee tablas: no responde 200 | Quitar `Metadatos["rnc"]` de la doble API: rojo. Mutación de T6-11 también lo pone en rojo |
| T6-81 | `T3_06_la_exportacion_de_la_principal_exige_exportar_reportes` (`:340`) | Pasa a la API de reportes: mismo 403 `PRIVILEGIO_REQUERIDO` sin `rptexportar`; 200 con él | Dar `rptexportar` a todos: la prueba falla (rojo) |
| T6-82 | `F9_reportes_basicos_por_la_API_de_reportes` (`:215`) | Cambia la aserción «P-2 sigue en la principal» por ejecución reenviada | Idem |
| T6-83 | `T3_11_toda_exportacion_deja_su_evidencia_y_se_verifica_por_huella` (`:530`) y `T3_11_sin_evidencia_no_se_exporta_y_responde_503` (`:655`) | Pasan a exportación reenviada con su evidencia | Con evidencia rota (tabla bloqueada), 503 y archivo no entregado; si la prueba sigue verde con el camino local, está hueca |
| T6-84 | `ReportesTests` y `ModeloNg/ReferenciasOla4Tests` | Siguen en Debug. Revisar `Totales.Max() == 118` del 15 → columna `BalanceBase`; conservar el SQL de cada oráculo | Cambiar un monto de la fixture: el total cambia (no es un literal pegado) |
| T6-85 | `AuditoriaAdr109Tests.GPOS_Api_no_agrega_motores_de_render_a_los_que_ya_tiene` (`:111`) | No se toca (es de T4-02) | Verde sin cambios |
| T6-86 | Conflictos de archivo con T1-5 de D1 (`ReportesF9Tests`, `FlujosMvpTests`, `BaseDatosFixture`, `ApiMvpFactory`) | No mezclar en el mismo commit; T4-06 antes del 11-nov | Revisar el diff: ningún cambio de `UsuarioAsync` |

### 2.I Compilación (criterio de PR; la suite no lo detecta)

| ID | Comando | Esperado | Mutación |
|---|---|---|---|
| BLD-1 | `dotnet build tests/GPOS.Tests -c Debug` | 0 errores (cubre H-2) | n/a |
| BLD-2* | `dotnet build src/GPOS.Api -c Release` | 0 errores, 0 advertencias nuevas. Es la **única** red contra un error dentro del `#else` | Dejar `ReporteEnLaPrincipalAsync` fuera del `#if`: no compila |
| BLD-3* | `dotnet build src/GPOS.Api -c Release -p:DefineConstants=DEBUG` | La guarda del símbolo en `GPOS.Api.csproj` y `GPOS.Core.csproj` lo **ignora**: sigue sin compilar el camino local (T6-64 en vivo). Si compila con el camino local, la guarda está rota | Quitar la guarda de Core |
| BLD-4 | `dotnet build src/GPOS.Reportes.Api -c Release` | 0 errores (no debería cambiar) | n/a |
| RUN-1 | Suite oficial: `--filter "Transicion!=Ola5&Transicion!=Defecto"`, **sola**; después `GPOS.Reportes.Tests` y `GPOS.Web.Tests`, también solas | Informar cifras reales ejecutadas/aprobadas/fallidas | No correr dos suites a la vez |

## 3. Orden sugerido (para que las pruebas rojas guíen el código)

1. T6-50 a T6-52 y T6-57 (Q-A4), T6-26 y T6-20 a T6-22 (P-1), T6-40 y T6-60 (P-2, Q-6): escribirlas **primero y verlas fallar**. Si alguna pasa en rojo-esperado, la prueba está hueca.
2. T6-01 a T6-09 con TA-1 (semilla). 3. T6-10 a T6-18 con TA-3. 4. Reescrituras T6-80 a T6-86 con TA-5. 5. BLD-1 a BLD-4 y RUN-1 con TA-6.
Compilaciones: máximo 3 a la vez; BLD-2 y BLD-3 sobre el mismo proyecto no corren en paralelo.

## 4. Matriz firma → casos

| Firma (HOJA 2026-10-23) | Casos que la prueban |
|---|---|
| P-1 (a): validar columnas con 403 propagado `DISENO_NO_PERMITIDO` | T6-20 a T6-31 |
| P-2 (a): falla cerrada de programados y «Ejecutar ahora» en Release | T6-40 a T6-47, T6-45 |
| P-3 (a): principal Release no arranca en Linux | T6-62, T6-63 |
| Q-A4 (a), segunda pregunta: 403 `SUCURSAL_NO_PERMITIDA` también en Debug | T6-50 a T6-59 |
| P-4: conservar `CompilacionDepuracion`; no publicar DEMO entre T4-06 y la tarea 3 | T6-70 a T6-73 |
| Rebasar sobre #202 y reutilizar `ReenvioReportes.NoDisponible()` | H-8, T6-10, T6-11, T6-14, T6-15 (rebase: el #202 ya está en `feature/modelo-ng`; ver D-9) |

## 5. Dudas para B y A (no las inventé)

| # | Para | Duda | Efecto |
|---|---|---|---|
| D-1 | B / A | S168-02 puso `RequiereAdminSinRestriccion()` sobre todo `/api/admin/reportes`. Un ADMIN restringido real recibe `RESTRICCION_SUCURSAL_ADMIN` (política) y **nunca** llega a `DISENO_NO_PERMITIDO` por HTTP en la principal. La firma P-1 habla de propagar `DISENO_NO_PERMITIDO`: ¿se deja la política (código `RESTRICCION_SUCURSAL_ADMIN`) y `DISENO_NO_PERMITIDO` queda como defensa en profundidad, o se exceptúan las rutas de reportes de la política para que el código sea el de diseño? | T6-29/30/31 no pueden fijar el código; T6-20 a T6-25 sí (unidad/servicio) |
| D-2 | A | Para probar P-3 desde Windows hace falta una costura para el sistema operativo (`ValidarModo(op, depuracion, esWindows)` o similar). ¿Se agrega, o P-3 se prueba solo con texto + VM Linux? | T6-62: unidad vs texto |
| D-3 | A | `ReporteAsync` lee `OpcionesSegundoFactor.Release` (estático). ¿Se inyecta (parámetro o interfaz) para probar la rama Release de un programado de punta a punta (T6-42), o queda solo `Modo(...)` por la costura? | T6-42 |
| D-4 | B | BP P-8 (`GET /{id}` se reenvía; el 503 aparece al abrir el reporte) quedó sin firma en la HOJA. ¿Confirmado? | T6-12 |
| D-5 | B | Q-A4 (a): ¿qué rutas del camino local de Debug dan 403 `SUCURSAL_NO_PERMITIDA` al restringido: solo ejecutar y exportar, o también `GET /{id}`? ¿USER restringido también (mi supuesto) o solo ADMIN? | T6-51, T6-53 |
| D-6 | B | ¿Cuántos reportes del sistema debe devolver la lista: 26 (BP §11.2) o 27 (V2 Q-9)? Uso «los de la semilla» hasta que respondan | T6-09 |
| D-7 | B / A | Programados en Debug sin reenvío con autor restringido: la sesión sintética de administrador no es restringida. ¿También 403 (falla)? Es el único hueco de R-14 que BP §17 no menciona | T6-58 |
| D-8 | B | ¿El 403 local de Debug va a la bitácora de seguridad? | T6-59 |
| D-9 | B | La tarea dice «rebasar sobre el #202»: en la punta `b9efa9fb` el #202 ya está unido (`e0b17145`). ¿Rebasar sobre `feature/modelo-ng` basta, o hay otra rama de T4-07 pendiente? | ninguno si basta |
| D-10 | A | BP supone que T4-04 se une después; **ya está unido** (H-1). ¿Confirma A que TA-3 «guarda en `EjecucionReglas`» se reemplaza por «quitar `enLaPrincipal` y `#if DEBUG` en `ReporteEnLaPrincipalAsync`»? (T6-40 a T6-47 lo suponen) | T6-40 a T6-47 |

## 6. Lo que no verifiqué

- No compilé ni ejecuté nada; ninguna mutación fue corrida (no hay código de T4-06 todavía).
- No leí el cuerpo de `AE_02`, `T3_02`, `T3_06`, `T3_11` ni de `ApiMvpFactory`; los nombres y líneas salen de `git grep` y de V2.
- Que la doble `api.ApiReportes` ofrezca respuestas arbitrarias (403 con `codigo`, JSON mal formado) es [I]; si no, T6-20 a T6-24 usan un `HttpMessageHandler` propio.
- Que `GPOS.Reportes.Tests` no referencie `GPOS.Core` lo tomo de BP (`:9-11`).
- No revisé los guiones del laboratorio ni del instalador (#124, #146): su arranque Release sin la API de reportes es [I] de BP.
