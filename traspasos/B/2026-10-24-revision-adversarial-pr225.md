# Revisión adversarial independiente del PR #225 (2026-10-24)

PR: «T4-06: la lista P-2 se vacía y los 11 reportes corren en la API de reportes (ADR-109 cl. 8, Q-6)». Rama `a/t4-06-lista-p2`, commit `7394790a`, base `feature/modelo-ng` (rebasado sobre `b9efa9fb`). Equipo A.

Método: solo lectura. Leí `gh pr view 225` y `gh pr diff 225`, y los archivos del árbol de la rama con `git show 7394790a:<ruta>`: vistas `database/ola5/rpt-vistas-tramo4.sql`, esquema `database/empresa/gpos-empresa-20261023024432_Ola5VistasImp.sql`, `EjecutorDisenador.cs` y `EndpointsReportes.cs` de la API de reportes y las páginas `Reportes.razor`. Para simular la unión usé `git merge-tree` contra `origin/feature/modelo-ng` `1b310591`. No hice checkout ni compilé, y no ejecuté la suite. Las dos expresiones regulares de las pruebas textuales las pasé con PowerShell (.NET) sobre los archivos de la rama. [V] = verificado; [I] = inferido.

## Recomendación: RECHAZADO tal como está (técnicamente se corrige rápido)
Hay un hallazgo **Alto** (H-1): una prueba nueva que el PR da por verde falla con el propio código del PR. Además, el PR **está en conflicto** con la base (H-2). El diseño de fondo está bien y cumple ADR-109 cl. 8 / Q-6: con H-1 y H-2 corregidos y H-3 y H-4 resueltos o aceptados por escrito, pasaría a «Aprobado con observaciones».

## Lo verificado (sin hallazgo)
- **Los 11 reportes leen solo de `rpt`** [V]. Las 11 definiciones (`ReportesSemilla.cs:20-130`) usan `rpt.CxcDocumento`, `rpt.CxpDocumento`, `rpt.Compra`, `rpt.DocBanco`, `rpt.CajaChica`, `rpt.MovimientoCaja` y `rpt.CatSucursal`, que existen en `rpt-vistas-tramo4.sql:46-386` y `rpt-vistas-ventas-inventario.sql:1483`. No leen nada de `rptc`. Todas las columnas que usa el SQL existen en las vistas (las cotejé una por una). La teoría que ya existía, `SemillaReportesOla5Tests.El_SQL_del_sistema_sobre_rpt_corre_con_gpos_reportes`, ahora cubre los 11 (filtra por `rpt.`): pasa el análisis estricto y corre como `gpos_reportes` con `TOP (0)`.
- **Corren en la API de reportes** [V]. Sin `EnLaPrincipal`, las rutas `/{id}`, `ejecutar`, `exportar`, `detectar` y `vista-previa` reenvían siempre que `reenvio.Habilitado` (`ReportesEndpoints.cs`). En Release no hay alternativa: `ReportesService.Ejecucion.cs` es un único `#if DEBUG` de principio a fin, así que `EjecutarAsync`, `ExportarAsync`, `VistaPreviaAsync`, `DetectarColumnasAsync` y `EjecutarLecturaAsync` **no existen** en una compilación Release. Una ruta que intentara ejecutar en la principal no compilaría: la garantía la da el compilador, no solo una prueba. `GPOS.Core.csproj` impide Release con DEBUG (la misma guarda DL-02 de `GPOS.Api.csproj`).
- **Arranque, Q-6** [V]. `ReenvioReportes.cs:422` llama a `ValidarModo(op, CompilacionDepuracion)` antes de `ValidarDireccion`. Sin dirección y sin Debug lanza la excepción y la API no arranca. El DEMO ya está protegido: `Publicar-PaqueteDemo.ps1:84` busca el marcador `CompilacionDepuracion`.
- **Solo lectura con la credencial de reportes** [V]. Guardar del diseñador ya no ejecuta el SQL del ADMIN con la conexión de escritura: `NombresDeColumnasAsync` (`ReportesService.cs`) usa `IDetectorColumnas`, y su implementación (`ReenvioReportes.cs:159`) va por la canalización con el token del ADMIN hasta `POST /api/admin/reportes/detectar`. Esa ruta exige `PuedeDisenar` y analiza con `AnalizadorSql.Separar` (`EjecutorDisenador.cs`, `DetectarAsync`). El cuerpo `{ consulta }` y la respuesta `List<ReporteColumnaDto>` coinciden con `ConsultaDetectar` de `EndpointsReportes.cs:17`. Un 403 conserva su estado y su código (`ReenvioReportes.cs:172`).
- **Aislamiento por sucursal** [V]. Los 11 reportes tienen la columna `Sucursal()` con `Catalogo = Sucursales` (código `varchar`, de `x.SucursalCodigo`). La API de reportes la usa para D-03: el restringido sin esa columna recibe 403 y, con ella, se agrega `r.[Sucursal] = @código` como texto (`EjecutorDisenador.cs`, `Preparar` y `RestringirAsync`). El filtro se aplica también antes de agrupar (9 y 10). En Debug sin reenvío, el restringido recibe 403 `SUCURSAL_NO_PERMITIDA` (Q-A4) en `EjecutarAsync(int)`, que también cubre la exportación.
- **Aislamiento por empresa** [V]. La empresa sale del token reenviado, también en Guardar. La lista sigue en GPOS_SYSDATA, con el mismo filtro de visibilidad que la API de reportes (`ServicioReportes.ListarAsync` con `ctx.VeReporte`, frente a `Permisos.VeReporte`) [I: la equivalencia de las dos funciones la inferí, no la recorrí línea por línea].
- **Notificaciones** [V]. `Modo` ya no tiene `enLaPrincipal`. En Release, `ModoReporte.Principal` lanza `ReportesNoDisponibleException` (falla cerrada) y `ReporteEnLaPrincipalAsync` solo existe en Debug. Cierra O175-01.
- **Actualización de la semilla** [V]. `ActualizarSistemaAsync` actualiza las copias intactas por su `HuellaSemilla` y conserva las modificadas por un ADMIN. Esas copias, con SQL sobre tablas, fallarán en la API de reportes (riesgo aceptado en T3-02 y declarado en el PR).
- **Datos que no se pierden** [V]. `cxc.Cuenta.FechaVencimiento`, `cxp.Cuenta.FechaVencimiento` y `caja.CajaChica.JornadaId` son NOT NULL, así que ningún JOIN interno de las vistas deja filas fuera y los tramos no reciben `NULL`. `fiscal.Comprobante` tiene la llave primaria (`DocumentoId`, `Rol`), así que el `LEFT JOIN … Rol = 'O'` no duplica filas.
- La prueba `SqlSoloEnLugaresPermitidosTests` sigue verde con el cambio de excepción: `ReportesService.cs` ya no coincide con ninguna forma de SQL [V, regex .NET].

## Hallazgos

### H-1 (Alta) La prueba nueva `P2_la_lista_ya_no_existe_y_ningun_reporte_del_sistema_lee_fuera_de_rpt` falla con el código del PR
- **Evidencia [V]:**
  - `tests/GPOS.Reportes.Tests/AuditoriaAdr109Tests.cs:38-41` recorre todo `src/**/*.cs` y exige `!Regex.IsMatch(t, @"(Intacto)?EnLaPrincipal(Async)?")`.
  - `src/GPOS.Api/Servicios/TrabajoNotificaciones.cs:111` y `:202` contienen `ReporteEnLaPrincipalAsync`, que contiene `EnLaPrincipalAsync`: la expresión no tiene `\b`. `git grep -c` da 2 coincidencias y `[regex]::IsMatch` da `True`.
  - La prueba hermana `Q6_…` (`AuditoriaAdr109Tests.cs:82`) exige justamente `#if DEBUG\s+return await ReporteEnLaPrincipalAsync`. Las dos pruebas no pueden pasar a la vez.
- **Escenario:** la suite de `GPOS.Reportes.Tests` queda en rojo al unir. El PR informa «AuditoriaAdr109: 19 de 19» y «810 de 810», cifras que no se sostienen con el commit `7394790a`: la evidencia del PR no corresponde al código entregado (C6).
- **Remedio:** anclar la expresión (`\b(Intacto)?EnLaPrincipal(Async)?\b`) o renombrar `ReporteEnLaPrincipalAsync` (por ejemplo, `ReporteLocalDepuracionAsync`) y ajustar `:82`. Después, volver a correr `GPOS.Reportes.Tests` completa y pegar el resultado real en el PR.

### H-2 (Alta para unir; trámite) El PR está en conflicto con `feature/modelo-ng`
- **Evidencia [V]:** `gh pr view 225` da `mergeable: CONFLICTING` y `mergeStateStatus: DIRTY`. `git merge-tree origin/feature/modelo-ng 7394790a` da `CONFLICT (content)` en `tests/GPOS.Tests/Mvp/NotificacionesReportesTests.cs`, por las pruebas B-2 con el emisor real que agregó el #217, ya unido (`1b310591`). El PR anticipaba el conflicto en `TrabajoNotificaciones.cs` (ese archivo se une solo); el que hay está en las pruebas.
- **Escenario:** con el emisor real unido cambian los supuestos de varias pruebas reescritas. AE-02 (`ReportesF9Tests.cs:459-480`) dice «aquí no hay emisor» y por eso inserta la evidencia a mano. `Un_programado_de_un_reporte_antes_P2_del_SUPER…` repite lo que ya prueban `Con_el_emisor_real_…` del #217.
- **Remedio:** rebasar sobre `1b310591` o posterior y resolver `NotificacionesReportesTests.cs` sin perder las pruebas B-2. Luego volver a correr la dirigida de `GPOS.Tests` y las completas de `GPOS.Reportes.Tests` y `GPOS.Tests`, con el filtro oficial y nunca dos a la vez. Por último, revisar si AE-02 puede volver a ser de extremo a extremo con el emisor real.

### H-3 (Media) Drill down roto en los documentos ND y CHD de los reportes de CxC (8 y 10)
- **Evidencia [V]:**
  - `src/GPOS.Web/Components/Pages/Reportes/Reportes.razor:703-704` y su copia en MAUI, `GPOS.UI.MAUI/Components/Pages/Reportes/Reportes.razor:703-704`, enrutan `EnlacesReporte.DocumentoCxc` según la columna `Tipo`: `"NDB"` → `ventas/notas/{n}` y `"CheckDev"` → `ventas/cheques-devueltos/{n}`. Cualquier otro valor abre el diálogo de **factura**.
  - La columna `Tipo` ahora es `x.TipoCodigo` (`ReportesSemilla.cs:20-35`, de `doc.TipoDocumento.Codigo`). En el modelo nuevo esos códigos son `ND` y `CHD` (`gpos-empresa-20261023024432_Ola5VistasImp.sql`, inserción de `doc.TipoDocumento`, filas 5 y 6). Los textos `NDB` y `CheckDev` eran del modelo heredado (`Documentos.cs:88`).
- **Escenario:** en «Antigüedad de saldos por cobrar» o «Estado de cuenta de cliente», el usuario pulsa una nota de débito o un cheque devuelto y se abre el detalle de una factura con ese número. Si existe una factura con el mismo número, ve **otro documento**; si no, ve un vacío o un error. No hay fuga de datos entre empresas, pero sí un dato equivocado en pantalla.
- **Remedio:** aceptar `ND` y `CHD` en las dos copias de `Reportes.razor` (conservando `NDB` y `CheckDev` mientras exista `master`), o devolver en la consulta del reporte el vocabulario que espera la interfaz. Agregar una prueba bUnit en `GPOS.Web.Tests` que cubra el enlace por tipo. Es la frontera con desarrollador-frontend.

### H-4 (Media) Cambios visibles que el PR no declara («qué rompe, a quién afecta», principio rector de CLAUDE.md)
- **Evidencia [V]:**
  1. **Movimientos de caja (23):** el filtro por omisión pasa de `MES_ACTUAL` (`FechaMes()`, `ReportesSemilla.cs:149`) a `HOY` (`:323`). Una regla programada con período «Predeterminado» sobre este reporte pasa a enviar solo el día. Además, `Fecha` ahora es `j.FechaOperacion` de la jornada, no la fecha del registro (`rpt-vistas-tramo4.sql:317`).
  2. **Movimientos de caja:** las filas `NOVENTA` (monto 0) muestran Ingreso y Egreso vacíos en lugar de 0 (`MovCajaRpt`, `CASE … END` sin `ELSE`).
  3. **Facturas de compra (13 y 14):** el NCF ya no toma un comprobante de rol `R`; antes lo hacía con `OUTER APPLY TOP (1)` sin rol.
  4. **Antigüedad por cliente (9):** `OrdenarPor` pasa de `Balance` a `BalanceBase`, y el orden cambia cuando hay varias monedas.
- **Escenario:** el usuario o un ADMIN nota la diferencia sin aviso. Las reglas programadas cambian de contenido en silencio.
- **Remedio:** agregarlos a «Qué cambia para el usuario» del PR, a la nota del reporte (el 23 ya dice «Por omisión, el día de hoy»; falta el efecto sobre los programados) y, si la del período es intencional, que la firme el propietario. Si no lo es, volver a `FechaMes()`.

### H-5 (Media) Falta la prueba de paridad lista/definición que el plan exige para T4-06
- **Evidencia [V]:** el plan del tramo 4 (`docs/arquitectura/2026-10-19-ola5-tramo4-plan-de-trabajo.md:200`) pide `ListaReportesContratoTests.La_lista_y_la_definicion_coinciden_en_visibilidad_para_USER_ADMIN_y_SUPER`. `git grep` en la rama no la encuentra.
- **Escenario:** desde este PR, la lista la arma la principal (`Permisos.VeReporte`) y la definición, la API de reportes (`ctx.VeReporte`). Si las dos reglas divergen, el usuario ve en la lista un reporte que da 403 al abrirlo, o deja de ver uno que sí puede abrir.
- **Remedio:** agregar esa prueba (USER con y sin permiso de área, ADMIN y SUPER; reportes del sistema, `SoloAdmin` y del diseñador), o registrar por escrito que pasa a otro PR antes del G-O5-T4.

### H-6 (Baja) Pruebas que prueban menos de lo que dicen
- `ReportesF9Tests.Ningun_reporte_del_sistema_se_ejecuta_en_la_principal` (`:291`) recorre 10 de los 11 reportes: omite `CXC-ESTADO-CUENTA`, que tiene un filtro obligatorio. El título dice «ningún». Remedio: incluirlo con el filtro `Cliente`.
- La misma prueba, en `:307`, solo exige `NotEqual(OK)` al guardar SQL sobre tablas: también pasaría con un 503 o un 429. Remedio: exigir el estado y el código concretos del rechazo de `gpos_rpt` (400 con el código de consulta fallida, o el que corresponda).
- AE-02 (`:459-480`) ya no ejecuta el programado: inserta la evidencia y comprueba que es la que insertó. Lo que sigue probando es «Verificar» y la copia en el registro, no que el programado deje su evidencia (eso lo cubre `NotificacionesReportesTests` con la API simulada). Remedio: renombrarla o, con el emisor del #217 ya unido, volver a hacerla de extremo a extremo (H-2).
- `ReenvioReportesModoTests.En_Release_la_principal_no_arranca_sin_el_reenvio` prueba `ValidarModo` aislado. Ninguna prueba falla si `AgregarReenvioReportes` deja de llamarlo, porque en Debug la llamada no hace nada. Remedio: una aserción textual en `AuditoriaAdr109Tests` de que `AgregarReenvioReportes` contiene `ValidarModo(op, CompilacionDepuracion)`. El riesgo es de disponibilidad, no de seguridad: sin el reenvío, en Release los caminos locales no existen y todo da 503.
- `Ningun_SQL_del_sistema_lee_tablas` y la versión textual de AuditoriaAdr109 solo detectan `FROM` y `JOIN`; no ven listas separadas por comas ni `APPLY` sobre una función. La defensa real son los permisos de `gpos_rpt`. Queda como nota.

### H-7 (Baja) Restos y advertencias
- `SemillaReportesOla5Tests.cs:15` todavía dice «Los que siguen en la principal (P-2) son exactamente los que no tienen vista».
- CS9113 («`factory` no se lee») en Release es una advertencia nueva, contra el criterio «sin advertencias nuevas». Remedio: `_ = factory;` en un miembro solo de Release, o un `#pragma` justificado.
- `GPOS.Tests` ya no compila en Release (`CostosTests.cs:156,171`, `ReportesTests.cs:124`, `SucursalOrigenTests.cs:82`, `ReferenciasOla4Tests.cs:94` usan miembros que solo existen en Debug). Ningún guion compila las pruebas en Release y no hay CI, así que hoy no rompe nada [V]. Conviene dejarlo escrito o envolverlas en `#if DEBUG`.
- `CXP-PAGOS` (`ReportesSemilla.cs:280`) depende de un `Replace` de texto. Si alguien cambia el `WHERE` de `DocsBancariosRpt`, el reporte pasa a mostrar todos los documentos bancarios sin que ninguna prueba lo note. Remedio: una constante propia o una aserción de que el SQL contiene `SuplidorId IS NOT NULL`.
- `ReenvioReportes.DetectarAsync`: un 200 con un cuerpo que no es JSON lanza `JsonException`, que termina en 500 genérico. Es un caso marginal.

## Condiciones para unir
1. Corregir H-1 y pegar en el PR el resultado real de `GPOS.Reportes.Tests` completa.
2. Rebasar sobre `feature/modelo-ng` ≥ `1b310591`, resolver el conflicto conservando las pruebas B-2 del #217 (H-2) y correr la dirigida de `GPOS.Tests` y las suites completas (con el filtro oficial y nunca dos a la vez).
3. H-3: corregir el enlace de ND y CHD en Web y MAUI en este PR o en uno inmediato de frontend antes de publicar. Al menos registrarlo como pendiente bloqueante de publicación.
4. H-4 y H-5: declarar los cambios visibles (y que el propietario firme el período por omisión del 23 si es intencional) y agregar la prueba de paridad o registrar su traslado.
5. La revisión de seguridad que pide la sesión principal de A, la unión solo con orden del propietario y la actualización de `docs/adr/estado.json` (ADR-109 cl. 8 / P-2 / Q-6) al unir, en `master`.

### Cierre
- Estado: Rechazado (recomendación técnica; la decisión de unir es del propietario)
- Artefactos: C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\B\2026-10-24-revision-adversarial-pr225.md
- Supuestos: no se compiló ni se ejecutó ninguna prueba; H-1 se dedujo con las expresiones exactas de la prueba aplicadas con .NET sobre los archivos de la rama; la equivalencia `Permisos.VeReporte`/`ctx.VeReporte` es inferida.
- Decisiones candidatas a ADR: Ninguna (si el período por omisión del 23 cambia a propósito, es una precisión para firmar, no un ADR).
- Entregas a otros agentes: desarrollador-backend (A) → H-1, H-2, H-6 y H-7; desarrollador-frontend → H-3 (enlace ND/CHD en Web y MAUI); qa-automatizado → H-5 (prueba de paridad) y la corrida completa tras el rebase; arquitecto-maestro → H-4 (cambios visibles para firmar); auditor-seguridad → la revisión pendiente antes de unir.
- Próximo paso recomendado: que A corrija H-1, rebase sobre 1b310591 y vuelva a pedir revisión con las cifras reales de las suites.
