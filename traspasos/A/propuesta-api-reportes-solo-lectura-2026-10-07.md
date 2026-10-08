# API de reportes con usuario de solo lectura: blueprint técnico

**Autor:** arquitecto-software · **Fecha:** 2026-10-07 · **Árbol revisado (solo lectura):** `GPOS-NG-numeracion`, rama `feature/modelo-ng` · **Estado:** propuesta. Las decisiones de la sección 7 están **pendientes de firma** del propietario.

**Pedido del propietario (2026-10-07):** una API dedicada solo a reportes, con usuario de solo lectura, y que los reportes `rpt` de la propia aplicación (pantallas de Reportes, tablero y KPI, consultas) trabajen con ese mismo aislamiento.

**Convención de evidencia.** *Verificado:* lo leí en esta sesión (ruta:línea). *Inferido:* conclusión o estimación mía, con su base. No compilé ni ejecuté nada. **sp** = semanas-persona, la escala del blueprint H0.

---

## 0. Resumen

| Tema | Recomendación | Por qué | Costo (sp, ±35 %) | Cuándo |
|---|---|---|---|---|
| **Qué aísla de verdad** | El aislamiento lo da **la base**, no el proceso. Todo SQL de reportes (los 27 reportes, el diseñador, la vista previa, el tablero, el drill-down, los reportes programados y la consulta de facturas) corre con `gpos_rpt_<EMP>`, un usuario que solo tiene `SELECT` sobre `rpt` y `DENY` sobre todo lo demás, y nunca con la conexión principal | Hoy `ReportesService` abre la conexión de la aplicación (`ReportesService.cs:356`) y la "solo lectura" depende de una expresión regular (`:188`) y de una transacción que se revierte (`:359`). Ya está decidido (ADR-38 M-2, ADR-40 R1) y planificado (ola 5, H0 3.8), pero no construido | Incluido en la ola 5 (2,5 sp), más **0,8 sp** (de 0,5 a 1,1) de endurecimiento | **Ola 5** (2026-11-16 a 11-24) |
| **Hallazgo nuevo (Alta)** | El usuario de solo lectura **no basta**: un `SELECT … WITH (TABLOCKX)` o `(UPDLOCK, HOLDLOCK)` solo necesita permiso `SELECT`. Dentro de la transacción del motor (`:359`), que dura hasta 120 s (`:365`), detendría el POS entero | La validación (`:27`) no prohíbe pistas de tabla ni `OPTION`. Es el mismo tipo de convoy que la QA de la ola 4 midió, pero provocado desde un reporte | Dentro de las 0,8 sp | **Ola 5**, condición de salida |
| **Proceso aparte `GPOS.Api.Reportes`** | **Sí, pero después del corte.** Primero se extrae el módulo como biblioteca `GPOS.Reportes` con frontera estricta (ola 5). El proceso aparte sirve al **tráfico externo** (Power BI, Excel, contador) y al MCP, y opcionalmente a las pantallas | ADR-40 descartó R2 ("no agrega seguridad"). Con HS256 el proceso aparte necesitaría la clave de firma y **podría emitir tokens**. Con ES256 (ADR-41) y solo credenciales de lectura, sí reduce el radio de daño de la superficie expuesta. En Express no protege el motor: lo protegen los límites | **1,0 sp** (de 0,8 a 1,5) | Después del corte; requiere ES256 |
| **Herramientas externas** | Por HTTP con **claves por empresa con alcance** (reportes, columnas sensibles, costos, vigencia, IP), guardadas como huella SHA-256. **Nunca** un login SQL para Power BI | Un login SQL directo saltaría permisos, límites y bitácora, y DirectQuery cargaría el OLTP | **1,0 sp** (de 0,7 a 1,4) | Después del corte y de la versión 1 del acceso multiempresa (como SA-01) |
| **Escrituras** (preferencias, bitácora) | Ninguna en la base de la empresa. Las preferencias se quedan en `GPOS.Api`; la bitácora va a `GPOS_SYSDATA` con una identidad que solo puede **insertar** en `rep.Ejecucion` | El login de reportes queda de solo lectura de verdad | 0,1 sp (en la ola 5) | Ola 5 |
| **Protección de la operación** | Tiempo máximo de 30 s (ADR-38 M-2; hoy son 120), `LOCK_TIMEOUT`, `OPTION (MAXDOP, MAX_GRANT_PERCENT)`, límite del optimizador, sin transacción explícita, concurrencia por empresa y por usuario, totales en el servidor, paginación y exportación en streaming | SQL Server Express no tiene Resource Governor; la única palanca es lo que el ejecutor manda en cada consulta | Dentro de las 0,8 sp | Ola 5 |
| **Costos y datos sensibles** | Las vistas con costos pasan a un esquema propio `rptc` con una segunda credencial `gpos_rptc_<EMP>`, creada solo en la central. Columnas marcadas `DatoSensible`, fuera por omisión en las claves externas y en el MCP | PR-ADR38 dice que las vistas `…Costos` "solo las lee la API", pero no dice con qué credencial. Con la principal se rompería este aislamiento | 0,1 sp | Ola 5 |
| **Análisis (estrella) y MCP** | Son **clientes y capas encima** de la misma API: el explorador del análisis vive en el proceso de reportes con sus propias credenciales (`ana`/`ana_costo`), y el MCP es un cliente HTTP con clave personal; nunca entra a la base | Una sola superficie de lectura para autenticar, limitar y auditar | MCP: 0,8 a 1,2 sp | MCP después de la entrega 1 |
| **Copia de lectura** | Opcional: una segunda instancia Express con restauración `STANDBY` de los respaldos de registro de 15 min de Backup Tool | Única réplica legible sin licencia Enterprise; desfase de 15 a 30 min | 0,5 a 0,8 sp + equipo | Cuando QA mida el impacto en una central grande |
| **Total** | Ola 5: **+0,8 sp** sobre lo planificado (de 0,5 a 1,1; +1 día de calendario, inferido). Después del corte: **3,3 sp** (de 2,5 a 4,9) | — | — | El corte del **2026-12-02** no se mueve |

**Decisiones para la firma:** ADR-77 a ADR-80 y dos precisiones (sección 7).

---

## 1. Contexto, hechos verificados y alcance

### 1.1 Lo que existe hoy (verificado)

| Hecho | Evidencia |
|---|---|
| El motor de reportes ejecuta SQL **escrito por el ADMIN** (la definición vive en `GPOS_SYSDATA`), envuelto en `SELECT TOP (n+1) … FROM (<consulta>) AS r` | `src/GPOS.Core/Servicios/ReportesService.cs:256-258` |
| La "solo lectura" de hoy es una lista negra por expresión regular | `ReportesService.cs:27-29` y `:181-193` |
| La consulta corre con la **conexión de la empresa de la aplicación** (`IEmpresaDbFactory.CrearAsync`), dentro de una transacción `ReadCommitted` que siempre se revierte, con `CommandTimeout = 120` | `ReportesService.cs:356-366` |
| ADR-38 M-2 exige 30 s, credencial de reportes, límites de filas y de bytes y una única interfaz `IEjecutorConsultas`, sin volver a la conexión principal | `docs/adr/ADR-038.md:11` |
| ADR-40 decidió los reportes **dentro** de la API (R1) con `gpos_rpt_{EMP}` y lista blanca, y **descartó** R2 ("reportes en un proceso aparte: no agrega seguridad y exige un almacén de secretos propio") | `docs/adr/ADR-040.md`, decisión y alternativas descartadas |
| Ya existe el rol `gpos_reportes` con `GRANT SELECT ON SCHEMA::rpt`, **sin miembros**. La API sigue con su login actual, y `gpos_app` tampoco tiene miembros (RG-14 abierto) | `src/GPOS.Core/Datos/Empresa/Migraciones/SqlMigraciones.cs:24-49`; `docs/calidad/2026-10-05-ola1-revision-qa.md:141` |
| **Corrección al encargo:** la API no usa hoy un login `gpos_app`. `gpos_app` es un **rol** de base sin miembros, y la API entra con el login de su cadena de conexión | Mismas fuentes |
| Los 27 reportes del sistema leen **tablas base** del modelo heredado y del nuevo (`cxc_Facturas_e`, `Clientes`, `inv_Articulos`, `cxp.Cuenta`, `doc.Documento`, `fiscal.Registro`…), **no** vistas `rpt` | `src/GPOS.Core/Sistema/ReportesSemilla.cs:15-80`. La ola 5 los reescribe sobre `rpt` (H0 3.8, criterio de salida 1 y 2) |
| Las vistas `rpt.Conciliacion*` también las usa **el dominio** (CxC, CxP, existencia, cierre de período), no solo los reportes | `src/GPOS.Core/Servicios/Modulos/CuentasPorCobrar/Partidas.cs:15`, `Consultas/Inventario/ConsultasCierrePeriodo.cs`, `Dominio/Inventario/Inventario.cs` |
| Los totales se calculan solo sobre las filas devueltas (máximo 10.000) | `ReportesService.cs:331-333`; `src/GPOS.Contracts/Reportes/Reportes.cs:145` |
| La exportación arma el archivo completo en memoria y la Web la reenvía | `src/GPOS.Api/Endpoints/ReportesEndpoints.cs:22-28`; `src/GPOS.Web/Program.cs:146` |
| Límite actual: 30 ejecuciones o exportaciones por minuto y usuario, en ventana fija; sin límite de concurrencia | `src/GPOS.Api/Seguridad/LimitesPeticiones.cs:20` y `:62` |
| Los reportes son `OperacionSitio.Libre` (cualquier sitio) y el diseñador `SoloCentral` | `ReportesEndpoints.cs:16` y `:37`; `src/GPOS.Core/Infraestructura/Sitio/Sitio.cs:52` |
| El tablero (`DashboardService`) lee con Dapper sobre la unidad de trabajo principal | `src/GPOS.Core/Servicios/DashboardService.cs:23` y `:69` |
| JWT firmado hoy con **HS256** (clave simétrica) | `src/GPOS.Api/Seguridad/Seguridad.cs:22`; `Program.cs:56-62` |
| PR-ADR38 (firmada el 2026-10-07): las vistas `rpt` con costos (`…Costos`) no se conceden al usuario de solo lectura; "solo las lee la API". Ya hay una: `rpt.HistorialTransferenciaCostos` | `docs/adr/ADR-038.md:31`; `docs/arquitectura/2026-10-07-ola3b-blueprint.md:216` |
| La base tiene `READ_COMMITTED_SNAPSHOT` | `src/GPOS.Migracion/Aprovisionamiento.cs:298` |

### 1.2 Lectura de arquitectura (criterio propio, C13.3)

1. **El pedido tiene dos partes de valor distinto.** El *usuario de solo lectura impuesto en la base* es lo que protege los datos y ya está decidido y planificado para la ola 5. El *proceso aparte* no protege el motor: en un servidor con SQL Server Express, lo que compite con el POS es la CPU, la memoria intermedia (1.410 MB por instancia en Express) y `tempdb` de **una sola instancia**, y eso pasa igual se llame desde un proceso o desde otro. El proceso aparte vale por otras razones: superficie expuesta a terceros, radio de daño, memoria y CPU del lado .NET (exportaciones) y despliegue independiente.
2. **Contradicción con ADR-40.** El proceso aparte reabre la alternativa R2, descartada en ADR-40. Se justifica reabrirla porque el motivo cambió (exposición externa y MCP, que ADR-40 no contemplaba) y porque ADR-41 (ES256) elimina el argumento del secreto compartido. Esto exige una **precisión de ADR-40** firmada (sección 7).
3. **Con HS256 el proceso aparte empeora la seguridad.** Para validar el token necesitaría la clave simétrica, con la que también puede **emitir** tokens (incluido uno de SUPER). Por eso el proceso aparte depende de ES256: solo recibe la llave pública.
4. **El usuario de solo lectura no impide bloquear.** Leer con pistas de bloqueo no requiere más permiso que `SELECT`, y las pistas puestas sobre una vista se propagan a las tablas base. La defensa es la validación del texto, sin transacción explícita, y `LOCK_TIMEOUT` (sección 3).

### 1.3 Alcance

Dentro: la credencial y su imposición en la base, el ejecutor único, el módulo `GPOS.Reportes`, el proceso `GPOS.Api.Reportes`, los contratos, los límites, la seguridad, la relación con el análisis y el MCP, y el plan. Fuera: el DDL de las vistas `rpt` y `rptc` y los permisos exactos (arquitecto-datos), el servicio de Windows y los certificados (devops), las pantallas (disenador-ux-ui), el contrato del MCP con proveedores de IA (arquitecto-integraciones).

---

## 2. Arquitectura

### 2.1 Módulos y dependencias

| Módulo | Responsabilidad | Depende de | No puede depender de |
|---|---|---|---|
| `GPOS.Contracts` (ya existe) | DTOs de reportes (`ReporteDto`, `ResultadoReporte`, nuevos `PaginaReporte`, `ClaveReporteDto`) | — | — |
| **`GPOS.Reportes`** (nuevo, biblioteca) | Catálogo y permisos de reportes, validación del SQL, armado de la consulta envuelta, **`IEjecutorConsultas`** (única puerta a la base para leer), límites, totales, paginación, exportación en streaming, bitácora | `GPOS.Contracts`, `GPOS.Core` (solo sesión, permisos, `Sitio`, Data Protection de conexiones) | `EmpresaDbContext`, `EmpresaNgDbContext`, `IEmpresaDbFactory` o cualquier conexión de escritura. Lo vigila una **prueba de arquitectura** |
| `GPOS.Api` (ya existe) | Hospeda `GPOS.Reportes` dentro del proceso (fase 1); el diseñador de reportes y las preferencias (escriben en `GPOS_SYSDATA`); administración de claves externas | `GPOS.Reportes`, `GPOS.Core` | — |
| **`GPOS.Api.Reportes`** (nuevo, proceso, fase 2) | Hospeda `GPOS.Reportes` para el tráfico externo (claves), el MCP y, si se firma, las pantallas | `GPOS.Reportes`, `GPOS.Contracts` | `GPOS.Core` de escritura; ninguna credencial `gpos_app_<EMP>`; la clave privada del JWT |
| `GPOS.Web` y `GPOS.UI.MAUI` | Pantallas | `GPOS.Contracts` por HTTP | — |
| `GPOS.Analisis` (futuro, ADR-55 a 57) | Explorador y tableros de la estrella | `GPOS.Reportes` (límites, bitácora, claves, exportación) | La base OLTP, salvo `ext` en la carga |

Sin ciclos: `Contracts ← Core ← Reportes ← {Api, Api.Reportes} ;  Reportes ← Analisis`.

### 2.2 C4, nivel de contenedores (central)

```
[Navegador] --HTTPS--> [IIS: GPOS.Web] --HTTP interno--> [GPOS.Api]  ----- gpos_app_<EMP> ----> [SQL: GPOS_<EMP>]
                                  \                         |  (GPOS.Reportes dentro: fase 1)                ^
[MAUI] ---------------------------+--> [GPOS.Api]           +-- gpos_rpt_<EMP> / gpos_rptc_<EMP> ------------+
                                                            +-- identidad de sistema --> [SQL: GPOS_SYSDATA]
[Power BI / Excel / contador] --HTTPS + clave--> [GPOS.Api.Reportes]  (fase 2, solo central)
[Servidor MCP] -----------------HTTPS + clave personal--^       +-- gpos_rpt_<EMP> / gpos_rptc_<EMP> --> [GPOS_<EMP>]
                                                                +-- gpos_rptsys (SELECT catálogo, INSERT bitácora) --> [GPOS_SYSDATA]
                                                                +-- (análisis) gpos_anl_lec[c]_<EMP> --> [GPOS_<EMP>_ANALISIS]
```

**Nodo de sucursal (ADR-53):** los reportes son `Libre` (`Sitio.cs:52`) y el nodo tiene sus propios reportes del día, el Z y la existencia local. Ahí corre `GPOS.Reportes` **dentro** de la API del nodo, con su propio `gpos_rpt_<EMP>` en la base local. **`GPOS.Api.Reportes`, las claves externas, el MCP y el análisis viven solo en la central** (rol `Central` o `Ambos`), igual que el análisis ([ANL] 3). En un nodo, `/api/reportes/externo/*` responde 503 `REQUIERE_CENTRAL`. `gpos_rptc_<EMP>` no se crea en los nodos (DA-02: costos solo en la central).

### 2.3 Autenticación

| Cliente | Esquema | Detalle |
|---|---|---|
| Web y MAUI | **El mismo JWT de GPOS** | Fase 1: lo valida `GPOS.Api` como hoy. Fase 2: `GPOS.Api.Reportes` lo valida **solo con la llave pública ES256** (ADR-41, `ver = 2`), la misma audiencia y además `rep` en `aud`. **No se habilita con HS256** |
| Herramientas externas (Power BI, Excel, sistema del contador) | **Clave de empresa con alcance** | `Authorization: GposClave <id>.<secreto>`. El secreto (256 bits de `RandomNumberGenerator`) se muestra una vez. Se guarda la huella SHA-256 del secreto con sal, que es aceptable en FIPS porque el secreto tiene entropía completa y no hace falta una derivación lenta. Alcance: empresa, lista de reportes (`rpt:<id>` o código), `costos` (sí/no, solo en la central y solo si quien la emite tiene Ver costos), `sensibles` (sí/no), vigencia máxima de 12 meses, IP o red permitidas (opcional) y cuota. La emite el ADMIN **de esa empresa** o el SUPER |
| MCP de IA | **Clave personal** ligada a un usuario | Sus permisos efectivos son la intersección entre los del usuario en esa empresa y el alcance de la clave. Se revoca al inhabilitar al usuario o su membresía. Nunca `costos` ni `sensibles` por omisión |
| Credenciales de cliente OAuth (`client_credentials`) | **Descartada en la versión 1** | Exigiría un servidor de autorización. Las claves con alcance cubren Power BI y Excel (el conector Web admite encabezados), con menos piezas. Se reconsidera si un ERP la exige |

### 2.4 Credenciales de la base e imposición en el motor

**Identidades por empresa** (creadas por `GPOS.Migracion`, contraseñas generadas, cifradas con Data Protection con propósito propio `GPOS.Reportes.Conexion`; ninguna en `appsettings` ni en texto plano, ADR-44):

| Identidad | Dónde | Permisos | Usa |
|---|---|---|---|
| `gpos_rpt_<EMP>` ∈ rol `gpos_reportes` | Base de la empresa (central y nodo) | `GRANT SELECT ON SCHEMA::rpt`. `DENY SELECT` sobre **cada** esquema base (`cat`, `doc`, `ventas`, `cxc`, `compras`, `cxp`, `banco`, `inv`, `caja`, `fiscal`, `audit`, `conf`, `org`, `rrhh`, `num`, `sync`, `dbo` mientras exista, `ext`, `rptc`, `etl`). `DENY INSERT, UPDATE, DELETE, EXECUTE, ALTER, CONTROL, TAKE OWNERSHIP, VIEW DEFINITION` sobre la base (`ON DATABASE::`). Miembro de `db_denydatawriter` | `IEjecutorConsultas` |
| `gpos_rptc_<EMP>` ∈ rol `gpos_reportes_costo` | **Solo en la base central** | Lo de `gpos_reportes` + `GRANT SELECT ON SCHEMA::rptc` | `IEjecutorConsultas`, cuando la API ya evaluó el privilegio efectivo de Ver costos (DA-02) |
| `gpos_ext_<EMP>` ∈ `gpos_extraccion` | Base central | `SELECT` solo sobre `ext` (AN-02, K-AN-02) | Carga del análisis |
| `gpos_rptsys` | `GPOS_SYSDATA` | `SELECT` sobre el catálogo de reportes, sus columnas, permisos, perfiles, membresías y claves; `INSERT` solo en `rep.Ejecucion`; `DENY UPDATE, DELETE` en todo | `GPOS.Api.Reportes` (fase 2). En la fase 1, la identidad de sistema actual |

**Cómo lo impone la base y no solo el código:**

1. **Encadenamiento de propiedad.** El esquema `rpt` (y `rptc`) pertenece a `dbo`, igual que las tablas, y sus vistas no usan SQL dinámico ni otras bases. SQL Server **no revisa permisos** sobre las tablas que lee una vista del mismo dueño, así que el `DENY SELECT` sobre los esquemas base no afecta a las vistas y sí impide leer las tablas directamente. Comprobación del arquitecto-datos: `ALTER AUTHORIZATION` explícito y una prueba de que ninguna vista `rpt` cambia de dueño.
2. **No usar `db_denydatareader`.** Ese rol deniega `SELECT` también sobre las vistas `rpt`. Por eso los `DENY` van esquema por esquema, y una prueba de permisos efectivos (`fn_my_permissions` y `HAS_PERMS_BY_NAME`) falla si aparece un esquema nuevo sin `DENY` explícito (denegación por omisión verificada en la integración continua).
3. **Aislamiento entre empresas en el motor.** `gpos_rpt_<EMP>` es un usuario **contenido** de su base (ADR-38 M-1; el mismo patrón del análisis, SA-04) o, si devops no habilita la autenticación contenida, un login con usuario **solo** en esa base. No existe en `GPOS_SYSDATA` ni en otra empresa, `guest` está revocado en las bases de GPOS (ADR-38 M-1) y el comando de migración comprueba P-06.1 (sin servidores vinculados, consultas distribuidas ad hoc, encadenamiento entre bases ni `TRUSTWORTHY`). Aunque el SQL del ADMIN intentara `GPOS_OTRA.cat.Cliente`, el motor responde con el error 916 o 229, con o sin la expresión regular.
4. **Sin respaldo.** Si la credencial de reportes no está configurada o falla, la respuesta es **503 `CREDENCIAL_REPORTES_NO_DISPONIBLE`**. Nunca se cae a la conexión principal (ADR-38 M-2).
5. **El dominio no usa `gpos_rpt`.** `Partidas.cs`, `Inventario.cs` y el cierre de período leen `rpt.Conciliacion*` con la credencial de la aplicación, así que el rol `gpos_app` necesita `SELECT ON SCHEMA::rpt`, que hoy **no tiene** (`SqlMigraciones.cs:29-47`). Hallazgo latente para RG-14 (sección 10).

### 2.5 Contratos de la API

Las rutas actuales **se conservan** (H0 3.8: "contratos que se mantienen `/api/reportes/*`"). Todas exigen la empresa y la sucursal de la sesión. La empresa sale del token o de la clave, **nunca** de un parámetro.

| Método y ruta | Entrada | Salida | Permiso | Aislamiento | Errores |
|---|---|---|---|---|---|
| `GET /api/reportes?area&tipo` | Consulta | `List<ReporteResumen>` | Autenticado; se filtra por `rpt:<id>`, el área, `SoloAdmin` (`Permisos.VeReporte`) | Empresa de la sesión; catálogo de `GPOS_SYSDATA` | 401 |
| `GET /api/reportes/{id}` | — | `ReporteDto` (sin `Consulta` si no es ADMIN; sin columnas `DatoCosto` sin Ver costos efectivo; sin `DatoSensible` por clave) | `rpt:<id>` o el del área | Ídem | 403 `SIN_PERMISO`, 404 |
| `POST /api/reportes/{id}/ejecutar` | `EjecutarReporteRequest { Filtros, Columnas?, Pagina (≥1), TamanoPagina (≤ 1.000), Moneda?, ConTotales }` | `ResultadoReporte` + `{ Pagina, TamanoPagina, HayMas, TotalesGlobales, MonedaPresentacion, Tasa, DatosAl }` | `rpt:<id>` | Ejecuta con `gpos_rpt_<EMP>` de la empresa de la sesión (o `gpos_rptc` si aplica) | 400 `VALIDACION` (filtro obligatorio, columnas), 403, 404, 408 `REPORTE_TIEMPO_AGOTADO`, 409 `REPORTE_BLOQUEADO` (`LOCK_TIMEOUT`), 413 `REPORTE_DEMASIADO_GRANDE` (bytes), 429 `REPORTE_EN_CURSO` con `Retry-After`, 503 `CREDENCIAL_REPORTES_NO_DISPONIBLE` |
| `GET /api/reportes/{id}/exportar/{formato}?filtros&columnas` | Consulta | Archivo **en streaming** (CSV y XLSX); PDF hasta 10.000 filas | `rpt:<id>` + `rptexportar` (nuevo, grupo Reportes, concedido por omisión a quien hoy exporta para no romper nada) | Ídem | Ídem + 400 formato |
| `GET /api/reportes/dashboard/indicadores?periodo` | — | `List<KpiDashboard>` | Autenticado + permiso del tablero | Vistas `rpt.Tablero*` con `gpos_rpt`; los KPI de costo (valor de inventario), con `gpos_rptc` o se omiten | 503 |
| `GET /api/reportes/dashboard/avisos` | — | `List<AvisoTableroDto>` | Ídem | `rpt.SucursalCerradaConExistencias` | — |
| `POST /api/ventas/facturas/consulta`, `…/exportar/{formato}` | Sin cambio | Sin cambio | Sin cambio | **Pasa a `IEjecutorConsultas`** sobre `rpt.ConsultaFacturas` | + 408, 429 |
| `GET/PUT /api/reportes/{id}/preferencias` (ola 5, "configuración de campos por usuario") | `{ Columnas[], Orden, FiltrosGuardados }` | Ídem | `rpt:<id>` | **En `GPOS.Api`**, escribe en `GPOS_SYSDATA` (`rep.PreferenciaUsuario`, por usuario y empresa) | 400, 403 |
| `/api/admin/reportes/*` (diseñador: guardar, eliminar, detectar, vista previa) | Sin cambio | Sin cambio | ADMIN, `SoloCentral` | Guardar y eliminar escriben en `GPOS_SYSDATA` desde `GPOS.Api`; **detectar y vista previa ejecutan con `IEjecutorConsultas`** (`gpos_rpt`; `sp_describe_first_result_set` para detectar, P-05) | + 408 |
| `GET /api/reportes/externo/v1/catalogo` (fase 3) | Clave | Reportes del alcance con sus columnas, tipos y filtros | Clave con alcance | Empresa de la clave; solo central | 401, 403, 503 `REQUIERE_CENTRAL` |
| `GET /api/reportes/externo/v1/{codigo}?desde&hasta&<filtro>=…&pagina&formato=json\|csv` (fase 3) | Clave | JSON paginado (`{ columnas, filas, siguiente }`) o CSV en streaming | Clave con alcance | Ídem; columnas sensibles y de costo según el alcance | 400, 401, 403, 408, 429 por cuota de la clave |
| `POST/GET/DELETE /api/admin/claves-reportes` (fase 3) | `{ Nombre, Tipo (Empresa\|Personal), Reportes[], Costos, Sensibles, Vigencia, Redes[] }` | El secreto **una sola vez** en el `POST`; después, solo metadatos | ADMIN de la empresa o SUPER (motivo obligatorio para el SUPER, ADR-35) | En `GPOS.Api`, escribe en `GPOS_SYSDATA` | 400, 403 |

**Códigos de reporte estables.** Las claves externas y el MCP se refieren a los reportes por `Codigo` (los del sistema ya lo tienen). Los reportes a medida reciben un código al publicarse para uso externo, para que una consulta de Power BI no se rompa si el reporte se duplica o se renumera.

### 2.6 Interfaces entre módulos

```csharp
// GPOS.Reportes
public interface IEjecutorConsultas
{
    // Única puerta de lectura de reportes. Elige gpos_rpt o gpos_rptc según el privilegio efectivo; nunca la conexión principal.
    IAsyncEnumerable<object?[]> LeerAsync(ConsultaPreparada consulta, LimitesConsulta limites, CancellationToken ct);
    Task<IReadOnlyList<ColumnaDescrita>> DescribirAsync(string consulta, CancellationToken ct); // sp_describe_first_result_set
}
public sealed record LimitesConsulta(TimeSpan Tiempo, int LockTimeoutMs, int MaxDop, int MaxGrantPercent, long MaxFilas, long MaxBytes);
public interface IFuenteCredencialesReportes   // conexiones por empresa y propósito (Lectura | LecturaCostos), cifradas con Data Protection
{ Task<string?> CadenaAsync(int empresaId, PropositoLectura proposito, CancellationToken ct); }
public interface IBitacoraReportes { ValueTask RegistrarAsync(EjecucionReporte e, CancellationToken ct); }  // rep.Ejecucion, solo inserción
public interface IAutorizadorReportes { DecisionReporte Autorizar(ReporteDefinicion r, PrincipalReportes p); } // usuario o clave
```

`ReportesService` se divide en `CatalogoReportes` (lee `GPOS_SYSDATA`), `ConstructorConsulta` (puro, sin E/S: validación, envoltura, filtros, totales, paginación) y `EjecutorConsultas`. `TrabajoNotificaciones` (`src/GPOS.Api/Servicios/TrabajoNotificaciones.cs:41`) usa el mismo servicio con la identidad `SISTEMA` y el principal del dueño de la regla.

### 2.7 Pantallas de Web y MAUI que pasan a la credencial de solo lectura

| Pantalla | Web | MAUI | Cambio |
|---|---|---|---|
| Reportes | `src/GPOS.Web/Components/Pages/Reportes/Reportes.razor` | `GPOS.UI.MAUI/Components/Pages/Reportes/Reportes.razor` | Paginación, totales globales, preferencias y aviso 429 o 408 |
| Tablero | `Pages/Reportes/Dashboard.razor` y `Components/Compartidos/Tablero.razor` | Las mismas en MAUI | Ninguno visible |
| Diseñador de reportes (vista previa y detectar) | `Pages/Admin/DisenadorReportes.razor` | No aplica | Mensajes de denegación del motor ("La consulta lee fuera de `rpt`") |
| Consulta de facturas | La pantalla de Ventas que usa `/api/ventas/facturas/consulta` | La misma | Ninguno visible |
| Reportes programados | `Pages/Admin/ReglasNotificacion.razor` (evento `ReporteProgramado`) | No aplica | Ninguno |
| Conciliación (Admin) | `Pages/Admin/Conciliacion.razor` | No aplica | **Se queda en la credencial de la aplicación**: es una comprobación del dominio, no un reporte |
| Claves de reportes (nueva, fase 3) | `Pages/Admin/ClavesReportes.razor` | No aplica | Nueva |

En la fase 2, si se firma D-80.b, las pantallas apuntan a la URL base del proceso de reportes. La Web lo hace con su reenvío interno (`Program.cs:146`) y MAUI con una segunda URL base de la configuración del dispositivo. El contrato no cambia.

---

## 3. Lo que NO va por solo lectura

| Escritura | Dónde vive | Cómo se resuelve sin dar escritura a `gpos_rpt` |
|---|---|---|
| Definición de reportes (diseñador) | `GPOS_SYSDATA` | Se queda en `GPOS.Api` (`/api/admin/reportes/*`), con la identidad de sistema. Solo la **ejecución** de prueba usa `gpos_rpt` |
| Preferencias por usuario (columnas, orden, filtros guardados; ola 5) | `GPOS_SYSDATA`, `rep.PreferenciaUsuario` (llave usuario + empresa + reporte; por empresa, ADR-34) | `GPOS.Api`, `GET/PUT /api/reportes/{id}/preferencias`. El proceso de reportes **solo las lee** con `gpos_rptsys` |
| Bitácora de ejecución y exportación | `GPOS_SYSDATA`, `rep.Ejecucion`: quién (usuario o clave), empresa, sitio, reporte, huella de los filtros, columnas, formato, canal (`UI`, `Programado`, `Clave`, `MCP`), filas, bytes, duración, resultado y código de error | **Solo inserción**: `gpos_rptsys` tiene `INSERT` en esa tabla y `DENY UPDATE, DELETE`. Retención de 13 meses con purga por el comando de mantenimiento, no por la API. La escritura es asíncrona (canal en memoria con cola acotada). Si la cola se llena, la exportación **se rechaza** (falla cerrada) y la ejecución en pantalla sigue con un evento de advertencia |
| Línea en `_LOG` de la empresa | Base de la empresa | **No** se escribe desde reportes. La auditoría de lectura es la de `rep.Ejecucion`; `_LOG` sigue siendo de los documentos |
| Claves externas | `GPOS_SYSDATA`, `rep.ClaveAcceso` (huella, alcance, vigencia, último uso) | Se crean y revocan en `GPOS.Api`. El proceso de reportes solo lee y actualiza "último uso" con un procedimiento `rep.usp_MarcarUsoClave` (`EXECUTE` como único permiso de escritura, una sola columna, como mucho una vez por minuto) |
| Caché de resultados | Memoria del proceso | Sin escritura en la base (sección 4.5) |

**Alternativa descartada:** dar a `gpos_rpt` `EXECUTE` sobre un procedimiento de bitácora en la base de la empresa. Aunque el permiso es estrecho, rompe la regla "solo lectura" del pedido, mete datos de auditoría de lectura en el libro fiscal y en los respaldos de 15 minutos, y obligaría a crear una excepción en la prueba de permisos.

---

## 4. Protección de la operación

### 4.1 El problema

En SQL Server Express (2019 y 2022): **1 socket o 4 núcleos, 1.410 MB de memoria intermedia y sin Resource Governor**. Bajo RCSI, un reporte no toma bloqueos compartidos, pero:
- consume CPU, que en la QA de la ola 4 ya estaba al 89 % (`rendimiento-ola4-propuesta-2026-10-07.md`, V1);
- desaloja de la memoria intermedia las páginas calientes del POS (un año de líneas de venta de una central grande no cabe en 1,4 GB);
- usa `tempdb` para ordenar y agregar, y retiene el **almacén de versiones** mientras dura: con 120 s de lectura y la carga de compras y ventas, el almacén crece. Ese es el antecedente del error 468 y de `tempdb`;
- con pistas de bloqueo (`TABLOCKX`, `UPDLOCK`, `HOLDLOCK`, `XLOCK`, `PAGLOCK`, `SERIALIZABLE`, `REPEATABLEREAD`, `READCOMMITTEDLOCK`) **sí** bloquea. Dentro de la transacción de hoy (`ReportesService.cs:359`), esos bloqueos duran hasta la reversión. La expresión regular (`:27`) no los prohíbe. **Severidad: Alta** (inferido; no lo probé). Cualquier ADMIN puede detener el POS con un reporte, aunque sea sin intención.

### 4.2 Límites por consulta (en `LimitesConsulta`; valores iniciales que QA debe ajustar con B9 y T-28)

| Límite | Valor inicial | Mecanismo | Vigente hoy |
|---|---|---|---|
| Tiempo máximo | **30 s** en pantalla (ADR-38 M-2); 120 s en programados y exportaciones grandes, solo fuera del horario de caja que configure la empresa | `CommandTimeout` + cancelación del `HttpContext` (`SqlCommand.Cancel` envía la atención al motor) | 120 s |
| Espera de bloqueos | `SET LOCK_TIMEOUT 2000` al abrir la conexión | Lo envía el ejecutor (el usuario no puede: `SET` está prohibido) | No |
| Sin transacción explícita | Lectura en *autocommit*: cada bloqueo termina con la sentencia | Con `gpos_rpt` (sin escritura en el motor), la transacción que se revierte ya no aporta nada y alarga los bloqueos | Hay transacción |
| Pistas y opciones prohibidas | Rechazar `WITH (` con cualquier pista de tabla, `OPTION`, `NOLOCK`, `READPAST`, `INDEX(`, `FORCESEEK`, `TABLESAMPLE`, `FOR XML`, `FOR JSON` y `OPENJSON` | Validador (`ValidarConsulta`). Aclaración: `WITH` como CTE al principio sigue permitido | No |
| Paralelismo y memoria | `OPTION (MAXDOP 2, MAX_GRANT_PERCENT = 10)` agregado por el envoltorio | Pistas disponibles en todas las ediciones (inferido de la documentación del producto; QA lo verifica en 2019 Express) | No |
| Costo estimado | `SET QUERY_GOVERNOR_COST_LIMIT <n>` por sesión; el ejecutor rechaza los planes cuyo costo estimado supera n **antes** de ejecutar | Configuración de sesión (inferido: disponible en Express) | No |
| Filas | Pantalla: páginas de hasta 1.000; sin tope de filas recorridas. Exportación: CSV 200.000, XLSX 100.000, PDF 10.000 | `TOP` y paginación | 10.000 |
| Bytes | 50 MB por respuesta en pantalla; 200 MB por exportación | Contador en el flujo | No |
| Concurrencia | **Por empresa:** 2 consultas a la vez en Express y 4 en Standard (configurable). **Por usuario o clave:** 1. Quien espera recibe 429 `REPORTE_EN_CURSO` con `Retry-After` (sin cola larga) | `ConcurrencyLimiter` particionado | No |
| Frecuencia | La de hoy (30 por minuto y usuario) + cuota diaria por clave | `RateLimiter` | Parcial |
| Programados | Escalonados: como máximo 1 a la vez por empresa | `TrabajoNotificaciones` | No |

### 4.3 Paginación, totales y streaming (planes de la ola 5)

- **Totales de más de 10.000 filas:** una segunda consulta de agregación sobre la misma envoltura (`SELECT SUM(…) FROM (…) AS r WHERE …`), con los mismos límites, solo si `ConTotales`. Se descartan los totales en el cliente (son incorrectos con paginación) y `SUM() OVER()` en cada fila (repite el cálculo y aumenta el uso de `tempdb`).
- **Paginación:** `ORDER BY <orden> , <llave> OFFSET … FETCH` con `HayMas` (se pide una fila de más), **sin `COUNT(*)`** global salvo que se pida. El paginado por llave (*keyset*) queda para las vistas grandes que lo justifiquen con QA.
- **Streaming:** CSV con `PipeWriter` y XLSX con escritura SAX de OpenXML, fila por fila desde el lector, sin armar el archivo en memoria (hoy se arma, `ReportesEndpoints.cs:27`). PDF con el tope de 10.000 filas.
- **Conversión de moneda:** la tasa sale de una vista `rpt.Tasa` y se aplica en la consulta (`* t.Tasa`). El resultado declara `MonedaPresentacion`, `Tasa` y `FechaTasa`. No se convierte en C# fila por fila.

### 4.4 `tempdb` y almacén de versiones

- El límite de 30 s acota la retención del almacén de versiones. Con el tope de 120 s fuera de horario, el peor caso queda acotado (inferido).
- Devops: `tempdb` con varios archivos de datos del mismo tamaño (hasta 4 en Express), crecimiento fijo y alerta sobre `sys.dm_tran_version_store_space_usage` y `sys.dm_db_file_space_usage`. Corrección pendiente del error 468: la intercalación de `tempdb` frente a la de la base (punto 7 de H-08); los reportes no crean tablas temporales (`INTO` está prohibido).
- La bitácora `rep.Ejecucion` permite a QA y al soporte encontrar los reportes caros (duración, filas, bytes).

### 4.5 Caché

Caché en memoria del resultado **por huella** = empresa + reporte + versión de la definición + filtros + columnas + "ve costos" + "ve sensibles" + página. Tiempo de vida: 60 s en el tablero y los KPI, 0 en los reportes, salvo los de cierre de período ya cerrado (5 min). Nunca entre empresas, porque la empresa forma parte de la llave. **Alternativa descartada:** caché distribuida (Redis): una instalación es un solo servidor (ADR-24) y agregaría una pieza que operar.

### 4.6 Réplica o copia de lectura (opción futura)

| Opción | Viable en | Desfase | Costo | Recomendación |
|---|---|---|---|---|
| **Copia `STANDBY` en una segunda instancia Express**, restaurando los respaldos de registro de 15 minutos de Backup Tool | Express y Standard | De 15 a 30 min; desconexión de los lectores al restaurar | Licencia USD 0; 0,5 a 0,8 sp; en el mismo servidor, una instancia aparte tiene sus propios 4 núcleos y 1,4 GB (sirve si el equipo tiene 8 núcleos o más); en otro equipo, el costo del equipo | **La opción preferida** cuando QA mida una degradación del POS por reportes en una central grande. `IFuenteCredencialesReportes` elige la fuente por reporte (los de "hoy" van a la principal y los históricos a la copia) |
| Replicación transaccional hacia un suscriptor Express | Publicador Standard | Segundos | USD 0 de licencia; operación compleja (agente de distribución) | Solo central Standard, si se pidiera un desfase de segundos |
| Réplica legible de un grupo de disponibilidad | **Solo Enterprise** | Segundos | Licencia Enterprise (del orden de miles de USD por núcleo, inferido) | No, salvo un cliente que ya pague Enterprise (ADR-54) |
| Estrella (módulo de análisis) | Central | Minutos (carga incremental) | 13 sp, ya presupuestado | Para lo histórico **es la respuesta correcta**, no una réplica |

---

## 5. Seguridad

| Requisito | Diseño |
|---|---|
| **Tenencia** | La empresa sale del token o de la clave, **nunca** de la ruta ni del cuerpo. La credencial es de esa base y no tiene usuario en otras (sección 2.4.3). Con el código actual, el permiso se cachea por usuario y no por membresía (H-01, H-14; `PermisosServidor.cs:17-21`, citado en la decisión del análisis): **la exposición externa y el MCP no se publican en una instalación con más de una empresa habilitada hasta la versión 1 del acceso multiempresa** (misma condición que SA-01 del análisis) |
| **Privilegios `rpt:<id>`** | Se mantienen (`Permisos.VeReporte`). Nuevos, en el grupo Reportes: `rptexportar` (concedido a quien hoy tiene acceso a reportes, para no romper nada), `rptclaves` (administrar claves; ADMIN de la empresa) y `rptia` (reservado para el MCP, no se crea aún, igual que `anlia`) |
| **Ver costos (ADR-12, DA-02)** | En la API: columnas `DatoCosto` fuera (ya existe, `ReportesService.cs:239`). **En el motor:** las vistas con costos pasan a `rptc`, que solo lee `gpos_rptc_<EMP>`, creada solo en la central. Si el ADMIN no marca `DatoCosto` en un reporte a medida que lee `rptc`, el motor lo rechaza para quien no tiene el privilegio efectivo: el error 229 se traduce en "Este reporte usa datos de costo" |
| **Datos sensibles** | Marca `DatoSensible` por columna (cédula de persona física, teléfono, correo, dirección, datos de empleados), propuesta por el detector como hoy `DatoCosto`. En pantalla, según el permiso; en las claves y el MCP, **fuera por omisión**. Ley 172-13 de protección de datos de RD: tratamiento mínimo necesario (inferido; confirmarlo con el asesor del propietario) |
| **SQL del ADMIN** | La lista negra se queda como primera barrera y para dar buenos mensajes. La barrera real es el motor. Se agrega la prohibición de pistas y `OPTION` (4.2). El texto de `Consulta` solo lo ve el ADMIN (ya es así) |
| **Auditoría** | `rep.Ejecucion` para todo canal. Alertas: una clave usada desde una red no permitida, más de N exportaciones por hora, intentos 403 repetidos. Revisión mensual del ADMIN (como el control compensatorio de ADR-106) |
| **FIPS (perfil Avanzada)** | TLS 1.2 o 1.3 con suites aprobadas; ES256 (P-256) para el JWT; SHA-256 y `RandomNumberGenerator` para las claves; conexiones SQL con `Encrypt=Strict`; credenciales cifradas con el anillo de `GPOS.Criptografia` (H-17 v2). Nada exclusivo de la Básica |
| **Exposición externa** | Solo `GPOS.Api.Reportes` en la central, con un puerto propio detrás de IIS y HTTPS. Desde internet, **solo por VPN** (ADR-24). Sin login SQL para terceros. Power BI y Excel usan el conector Web con encabezado; el contador recibe una clave limitada a los reportes fiscales (606, 607, 608, 609), sin costos ni sensibles, con vigencia de 3 a 12 meses |
| **MCP de IA** | Cliente con clave personal: permisos ∩ alcance; solo el catálogo y la ejecución paginada (como máximo 500 filas por llamada); sin costos ni sensibles salvo un alcance explícito firmado; cada llamada queda en `rep.Ejecucion` con el canal `MCP`. **Los datos salen hacia un proveedor de IA:** la empresa debe **activarlo expresamente** (SUPER o ADMIN, con aviso) |
| **Proceso aparte** | Cuenta virtual `NT SERVICE\GPOS.Api.Reportes`; `RequiredPrivilege` mínimo (ADR-76 y PA-76-1); binario firmado (ADR-33) y en el manifiesto del agente (ADR-63); sin la clave privada del JWT, sin `gpos_app_<EMP>` ni el anillo de la API principal (el propósito `GPOS.Reportes.Conexion` permite darle solo esas conexiones) |

---

## 6. Relación con el módulo de análisis y el MCP

- **Una sola superficie de lectura.** `GPOS.Api.Reportes` es el contenedor de la lectura de la central: `rpt` por omisión (incluido en la licencia) y, con el módulo activo, las rutas `/api/analisis/*` del explorador, con sus credenciales `gpos_anl_lec_<EMP>` y `gpos_anl_lecc_<EMP>` sobre `GPOS_<EMP>_ANALISIS` (AN-04, AN-09). Comparten el autorizador, los límites, la bitácora, las claves, la exportación en streaming y la caché. **Se mantiene la frontera de ADR-55 a 57:** los permisos `anl:*` no heredan de `rpt:<id>` y viceversa.
- **La carga del análisis** (`TrabajoCargaAnalitica`, con `gpos_ext_<EMP>` sobre `ext`) **no** es tráfico de reportes. Puede vivir en el mismo proceso de reportes, porque solo lee la base OLTP y escribe en la base analítica con `gpos_anl_carga_<EMP>`, sin escribir en la OLTP. Es mejor que en la API principal: aleja una escritura masiva del proceso del POS. Se propone como precisión de AN-05 al construir el módulo, no ahora.
- **AN-02 (`ext`) sigue igual.** `gpos_reportes` lleva `DENY SELECT ON SCHEMA::ext` (SA-16).
- **El MCP es un cliente, no una capa con acceso propio.** Coincide con [ANL] 7.9: consume rutas con el token o la clave del usuario y nunca la base. Sus herramientas (`listar_reportes`, `describir_reporte`, `ejecutar_reporte`, y con el módulo de análisis `explorar`) son envolturas finas de las rutas de la sección 2.5. Se construye después de la entrega 1, en la etapa que decida el propietario (pendiente "MCP para modelos de IA").
- **Alternativa descartada:** que el MCP o el análisis tengan su propia API. Duplicaría la autenticación, los límites y la auditoría, con tres superficies que revisar en vez de una.

---

## 7. Plan por fases (el corte del 2026-12-02 no se mueve)

### 7.1 Ola 5 (del 2026-11-16 al 2026-11-24), dentro de lo ya planificado y con un agregado pequeño

| Id | Trabajo | Planificado en H0 3.8 | Agregado (sp) |
|---|---|---|---|
| R5-1 | `gpos_rpt_<EMP>` creado y asignado por `GPOS.Migracion`; `IEjecutorConsultas` sin respaldo; reescritura de los 27 reportes, del tablero y de la consulta de facturas sobre `rpt` | Sí (SR-03, SR-10) | 0 |
| R5-2 | Biblioteca `GPOS.Reportes` (se extrae `ReportesService` en tres piezas) + prueba de arquitectura (sin referencia a contextos ni fábricas de escritura) | No | 0,10 |
| R5-3 | `DENY` por esquema, `rptc` + `gpos_rptc_<EMP>` (solo central), prueba de permisos efectivos con denegación por omisión | Parcial | 0,15 |
| R5-4 | Endurecimiento del ejecutor: pistas y `OPTION` prohibidos, sin transacción, `LOCK_TIMEOUT`, 30 s, `MAXDOP` y `MAX_GRANT_PERCENT`, límite del optimizador. **Prueba de regresión:** un reporte con `TABLOCKX` se rechaza; un reporte de 25 s durante T-28 no sube el p95 de la venta más de un 10 % | No | 0,15 |
| R5-5 | Concurrencia por empresa y usuario (429) y cancelación | No | 0,10 |
| R5-6 | Totales globales, paginación, exportación CSV y XLSX en streaming, moneda | Sí (planes de la ola 5) | 0,10 (streaming) |
| R5-7 | `rep.Ejecucion` y `rep.PreferenciaUsuario` en `GPOS_SYSDATA`; preferencias en `GPOS.Api` | Preferencias, sí | 0,10 (bitácora) |
| R5-8 | `SELECT ON SCHEMA::rpt` para el rol `gpos_app` (lecturas del dominio) | No | 0,02 |
| | **Total del agregado** | | **≈ 0,8 sp (de 0,5 a 1,1)** |

**Efecto en el calendario (inferido):** a unas 4,6 sp por semana del equipo, 0,8 sp equivalen a unos 0,9 días. La ola 5 tiene holgura hasta el corte (del 25 de noviembre al 2 de diciembre). **Opción más barata:** dejar R5-5 y R5-7 para después del corte (−0,2 sp). **No recomiendo** quitar R5-4: es la corrección del hallazgo Alto.

**Criterio de salida agregado a la ola 5:** (1) ninguna ejecución de reporte, tablero, consulta de facturas, vista previa o programado abre la conexión principal (prueba con un *interceptor* que falla); (2) `gpos_rpt_<EMP>` no puede leer fuera de `rpt` ni escribir (prueba de permisos efectivos); (3) con pistas de bloqueo, el reporte se rechaza; (4) B9 y T-28 sin regresión con reportes en paralelo.

### 7.2 Después del corte

| Fase | Contenido | sp (rango) | Condición |
|---|---|---|---|
| **F2 · Proceso `GPOS.Api.Reportes`** | Hospedaje como servicio de Windows (o sitio de IIS con su propio grupo de aplicaciones, según ADR-24), validación ES256, `gpos_rptsys`, reenvío desde la Web, URL base en MAUI, salud, manifiesto del agente (ADR-63), `RequiredPrivilege` | **1,0** (de 0,8 a 1,5) | ES256 implementado (ADR-41) |
| **F3 · Claves externas** | `rep.ClaveAcceso`, administración, `externo/v1`, CSV y JSON, guía para Power BI y Excel, alertas | **1,0** (de 0,7 a 1,4) | F2 + versión 1 del acceso multiempresa (o instalación con una sola empresa) |
| **F4 · MCP** | Servidor MCP como cliente, clave personal, activación por empresa | **0,8 a 1,2** | F3; etapa elegida por el propietario |
| **F5 · Copia de lectura** (opcional) | `STANDBY` con Backup Tool y fuente por reporte | **0,5 a 0,8** | Medición de QA en una central grande |
| | **Total después del corte** | **3,3 (de 2,5 a 4,9)**, sin F5 | |

---

## 8. Decisiones para la firma del propietario

Números del rango del equipo A: el siguiente libre tras ADR-76 es **ADR-77**. Busqué "ADR-77" y "ADR-78" en `Solucion GPOS NG` y no hay usos. Los asigna en firme el documentador-tecnico al registrarlos.

| Id | Decisión | Recomendación | Alternativas descartadas | Contradice o precisa | Cuándo firmar |
|---|---|---|---|---|---|
| **ADR-77 · Aislamiento de lectura de reportes en el motor** | Todo SQL de reportes (reportes, diseñador, vista previa, tablero, consulta de facturas, programados, drill-down) corre por `IEjecutorConsultas` con `gpos_rpt_<EMP>` (o `gpos_rptc_<EMP>` en la central con Ver costos efectivo), con `DENY` por esquema, encadenamiento de propiedad, sin respaldo en la conexión principal y la biblioteca `GPOS.Reportes` con frontera verificada | **Aprobar** (ola 5) | (a) Solo la expresión regular y la transacción revertida (lo de hoy): no impide leer el resto de la base ni bloquear. (b) `db_denydatareader`: bloquea también `rpt`. (c) Una credencial con lectura de todas las tablas: no aísla | Desarrolla ADR-38 M-2 y ADR-40 R1; **precisa PR-ADR38** (ver P-1) | Antes del 2026-11-16 |
| **P-1 · Precisión de PR-ADR38** | Las vistas con costos van a un esquema `rptc`, que solo lee `gpos_rptc_<EMP>`, creada solo en la central y usada solo cuando la API evaluó el privilegio efectivo (DA-02). "Solo las lee la API" significa "la API, con esa credencial", **nunca** con la conexión principal | **Aprobar** | (a) Dejarlas en `rpt` con `DENY` vista por vista: frágil, una vista nueva sin `DENY` filtra costos. (b) Leerlas con la conexión principal: rompe el aislamiento pedido | PR-ADR38 (firmada el 2026-10-07), ADR-12 | Con ADR-77 |
| **ADR-78 · Protección de la operación frente a los reportes** | Límites de 4.2 (30 s en pantalla, `LOCK_TIMEOUT`, sin transacción, pistas y `OPTION` prohibidos, `MAXDOP` y `MAX_GRANT_PERCENT`, límite del optimizador, concurrencia por empresa y usuario, bytes), totales en el servidor, paginación y streaming | **Aprobar** (ola 5). Los valores los ajusta QA sin firma nueva | (a) Resource Governor: no existe en Express. (b) Solo el límite de frecuencia de hoy: no limita la concurrencia ni el bloqueo. (c) Segunda instancia por omisión: operación sin necesidad medida (como AN-04) | Corrige el desvío de 120 s frente a ADR-38 M-2 | Antes del 2026-11-16 |
| **ADR-79 · Escrituras fuera del login de reportes** | Preferencias en `GPOS.Api`; bitácora `rep.Ejecucion` en `GPOS_SYSDATA`, solo inserción, 13 meses; `_LOG` de la empresa sin cambios | **Aprobar** (ola 5; la bitácora puede pasar a F2 si se recorta) | Procedimiento de bitácora en la base de la empresa con `EXECUTE` para `gpos_rpt`; bitácora solo en archivos de registro (sin consulta para el ADMIN) | Ninguno | Antes del 2026-11-16 |
| **ADR-80 · Proceso `GPOS.Api.Reportes` y exposición externa** | (a) Proceso aparte, **solo en la central**, para claves externas y el MCP, después del corte, **condicionado a ES256** y, con varias empresas, a la versión 1 del acceso multiempresa. (b) **Opcional:** mover también las pantallas al proceso. (c) Claves por empresa y personales con alcance; nunca un login SQL para terceros | **Aprobar (a) y (c); (b) "No por ahora"**, y reabrirlo si QA mide que las exportaciones en la API principal afectan al POS (el streaming de la ola 5 lo reduce) | (a) Todo dentro de la API principal, también lo externo: deja la API del POS expuesta a Power BI y a la IA. (b) Proceso aparte ya en la ola 5: con HS256 tendría la clave de firma y podría emitir tokens, y 1 sp más arriesgaría el corte. (c) OAuth `client_credentials`: requiere un servidor de autorización. (d) Login SQL de solo lectura para Power BI: salta permisos, límites y bitácora | **Precisa ADR-40** (reabre R2 por un motivo nuevo: exposición externa y MCP) y ADR-24 (un servicio más, VPN) | Antes de abrir F2 |
| **P-2 · Relación con el análisis y el MCP** | El explorador del análisis y el MCP son clientes y capas de `GPOS.Api.Reportes`; la carga del análisis puede vivir en ese proceso | **Aprobar en principio**; el detalle, al firmar AN-03 a AN-17 | API propia para el análisis o para el MCP | Precisa [ANL] 7.9 y AN-05 (sin cambiar su fondo) | Con AN-03 a AN-17 |

**Preguntas al propietario:**
- **PR-1:** ¿Las claves de empresa (Power BI, contador) **ocupan un cupo** de la licencia por usuarios (ADR-34, ADR-58)? Recomiendo **no**, pero con un número máximo de claves activas por empresa en la licencia (por ejemplo, 3) y la clave personal ligada a un usuario que ya ocupa un cupo. Alternativa: que cada clave ocupe un cupo (más simple de explicar y más cara para el cliente).
- **PR-2:** ¿El acceso externo es solo por VPN (ADR-24) o se quiere publicar `GPOS.Api.Reportes` en internet detrás de un WAF? Recomiendo **solo VPN** hasta tener la versión en la nube.
- **PR-3:** ¿Se acepta el nuevo privilegio `rptexportar`, concedido por omisión a quien hoy tiene acceso a reportes? Así ningún usuario pierde la exportación con la actualización.

---

## 9. Necesidades para Datos e Integraciones

**arquitecto-datos:**
1. DDL de los roles y usuarios `gpos_reportes`, `gpos_reportes_costo`, `gpos_rpt_<EMP>`, `gpos_rptc_<EMP>` (solo central), con `DENY` por esquema y la prueba de permisos efectivos con denegación por omisión.
2. Esquema `rptc` con dueño `dbo`; mover `rpt.HistorialTransferenciaCostos` y toda vista futura `…Costos`.
3. Vistas de la ola 5 para el tablero (`rpt.Tablero*`), la consulta de facturas (`rpt.ConsultaFacturas`), la tasa (`rpt.Tasa`) y `rpt.SucursalCerradaConExistencias`; marca de las columnas sensibles.
4. Tablas de `GPOS_SYSDATA`: `rep.Ejecucion`, `rep.PreferenciaUsuario`, `rep.ClaveAcceso` (F3) y el procedimiento `rep.usp_MarcarUsoClave`; la identidad `gpos_rptsys` (F2).
5. `GRANT SELECT ON SCHEMA::rpt TO gpos_app` (R5-8) dentro de RG-14.
6. Índices que necesiten los 27 reportes reescritos, medidos con el volumen de la central grande.

**arquitecto-integraciones:** contrato de `externo/v1` para Power BI y Excel (paginación que Power Query pueda seguir), formato de los archivos 606, 607, 608 y 609 para el contador y el contrato del servidor MCP (F4).

---

## 10. Riesgos

| Id | Riesgo | Severidad | Mitigación |
|---|---|---|---|
| **H-RPT-01** | Pistas de bloqueo en el SQL del ADMIN detienen el POS durante una transacción de hasta 120 s (`ReportesService.cs:27`, `:359`, `:365`; inferido, sin prueba) | **Alta** | R5-4 en la ola 5; prueba de regresión. **Recomiendo adelantar la prohibición de pistas y `OPTION` y el `LOCK_TIMEOUT` (unas 0,05 sp) a la próxima corrección de la ola 4**, porque comparte la causa de H-QA4-03 |
| H-RPT-02 | El rol `gpos_app` no tiene `SELECT` sobre `rpt` y el dominio lee `rpt.Conciliacion*`: al cerrar RG-14, CxC, CxP, la existencia y el cierre de período fallarían con el error 229 | Media (latente) | R5-8 |
| H-RPT-03 | La reescritura de los 27 reportes sobre `rpt` es la condición para activar `gpos_rpt`; si se atrasa, la ola 5 no puede imponer el aislamiento | Media | Activarlo reporte por reporte: los ya reescritos, con `gpos_rpt`; los demás, en una lista de excepciones que debe quedar vacía en el corte (criterio 3 de H0 3.8) |
| H-RPT-04 | Exponer reportes con el permiso cacheado por usuario (sin membresías) cruza datos entre empresas | Alta, si se publica antes de la versión 1 | Condición de F3 y F4 (sección 5) |
| H-RPT-05 | Proceso aparte con HS256 | Alta | Condición de F2: ES256 |
| H-RPT-06 | Los límites de 4.2 dejan sin ejecutar reportes legítimos de la central grande (más de 30 s) | Media | Ejecución programada con 120 s fuera de horario, estrella o copia de lectura; QA ajusta los valores |
| H-RPT-07 | La autenticación contenida exige activar `contained database authentication` en la instancia | Baja | Alternativa: login con usuario solo en su base (equivalente para el aislamiento); lo decide devops con ADR-38 M-1 |
| H-RPT-08 | La IA envía datos del cliente a un proveedor externo | Media | Activación expresa por empresa, sin sensibles ni costos por omisión, y bitácora |

---

### Cierre
- Estado: Completado
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\propuesta-api-reportes-solo-lectura-2026-10-07.md`
- Supuestos: límites de Express (4 núcleos, 1.410 MB, sin Resource Governor) según la documentación del producto; `MAXDOP`, `MAX_GRANT_PERCENT` y `QUERY_GOVERNOR_COST_LIMIT` disponibles en Express (inferido, QA lo verifica); el corte vigente es el 2026-12-02; la velocidad del equipo es de unas 4,6 sp por semana (H0 11.2); ADR-77 a 80 están libres (búsqueda sin resultados)
- Decisiones candidatas a ADR: ADR-77 (aislamiento en el motor), P-1 (precisión de PR-ADR38: `rptc`), ADR-78 (protección de la operación), ADR-79 (escrituras fuera del login de reportes), ADR-80 (proceso `GPOS.Api.Reportes` y exposición externa; precisa ADR-40 y ADR-24), P-2 (análisis y MCP como clientes)
- Entregas a otros agentes: arquitecto-datos → sección 9; arquitecto-integraciones → contrato de `externo/v1` y del MCP; devops → `tempdb`, alertas del almacén de versiones, servicio y cuenta virtual, autenticación contenida; auditor-seguridad → revisión de ADR-77, ADR-80 y H-RPT-01; QA → prueba de regresión de H-RPT-01 y valores de 4.2 con B9 y T-28; disenador-ux-ui → paginación, totales, preferencias y la pantalla de claves; arquitecto-maestro → hoja de firma
- Próximo paso recomendado: que el Arquitecto Maestro lleve ADR-77, ADR-78, ADR-79 y P-1 a la firma antes del 2026-11-16, y que la corrección de la ola 4 absorba ya la prohibición de pistas y el `LOCK_TIMEOUT` (H-RPT-01)
