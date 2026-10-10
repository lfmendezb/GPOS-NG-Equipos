# [Informe de Seguridad] Ola 5, tramo 3: API de reportes de solo lectura (ADR-109)

**Rama:** `b/ola5` (árbol `GPOS-B-ola5-construccion`) · **Alcance:** `a103a4f..c47d3b0` (sobre `778a437`) más el commit posterior `dcc7a75` · **Fecha:** 2026-10-10 · **Modo:** solo lectura: no se compiló, no se corrieron pruebas y no se editó el árbol. **Commits posteriores:** `dcc7a75` (revisado en la sección 4 bis); no había otros hasta `dcc7a75` cuando se cerró la revisión.

## 1. Alcance y superficie revisada

- **Sobres y llave del sitio:** `src/GPOS.Comun/Sobres/SobreLectura.cs` y `LlaveSitio.cs`.
- **Credenciales:**
  - `src/GPOS.Migracion/Lectura/CredencialesLectura.cs` (también en `dcc7a75`) y `ComandosLectura.cs`;
  - `src/GPOS.Migracion/Program.cs`;
  - `src/GPOS.Core/Datos/Empresa/Migraciones/PermisosLecturaReportes.cs`, `SqlMigracionesOla5.cs` y `20261010111846_Ola5VistasVentasInventario.cs`;
  - `database/ola5/rptsis-vistas-sistema.sql` (tabla `dbo.ConexionLectura` y vista).
- **Fuente de conexión:** `src/GPOS.Reportes/Lectura/FuenteConexionSobres.cs`, `FuenteSistema.cs` e `IFuenteConexionLectura.cs`; `src/GPOS.Reportes/Consultas/Sistema/LectorSistemaSql.cs`; `src/GPOS.Reportes/Ejecucion/PreparadorSesion.cs`.
- **Reenvío e introspección:**
  - `src/GPOS.Api/Endpoints/ReenvioReportes.cs` y `ReportesEndpoints.cs`;
  - `src/GPOS.Api/Seguridad/ValidadorTokenPrincipal.cs` y `Seguridad.cs`;
  - `src/GPOS.Api/Program.cs`;
  - `src/GPOS.Reportes.Api/Seguridad/AutenticacionIntrospeccion.cs` (E1) y `Program.cs`;
  - `src/GPOS.Comun/Introspeccion/ProtocoloIntrospeccion.cs`.
- **Privilegios:**
  - `src/GPOS.Contracts/Seguridad/Permisos.cs`;
  - `src/GPOS.Core/Sistema/PermisosService.cs`;
  - `src/GPOS.Reportes/Contexto/ContextoReportes.cs`;
  - `src/GPOS.Reportes/Definiciones/Registrados/ReportesVentasRegistrados.cs`;
  - `src/GPOS.Reportes/Consultas/Reportes/ConsultasVentasReportes.cs`;
  - `src/GPOS.Core/Servicios/ReportesService.cs`;
  - `src/GPOS.Core/Sistema/ReportesSemilla.cs`;
  - las vistas de `VistasReportesOla5.cs` (enmascarado).
- **N-01 y N-02:** `src/GPOS.Reportes.Api/Endpoints/ServiciosReportes.cs` y `src/GPOS.Reportes/Exportacion/ComprobacionCarpetas.cs`.
- **Interfaz:** `TablaReporte.razor` y `Reportes.razor` (sin `MarkupString`; sin riesgo de XSS).

**Superficie:**

- Principal, rutas autenticadas `/api/reportes/*` y `/api/admin/reportes/*` (solo ADMIN), que reenvían por HTTP de *loopback* o por la canalización.
- API de reportes en *loopback*, con `/api/salud` anónima.
- Canalización de introspección y canalización de exportación.
- `GPOS.Migracion`, que ejecuta un administrador.
- Llave CNG de la máquina.
- `dbo.ConexionLectura` en `GPOS_SYSDATA`.

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título | Estado |
|---|---|---|---|
| T3-01 | Media | El reenvío por HTTP manda el token del usuario a un puerto de *loopback* sin comprobar quién escucha (T2-04 cubre solo la canalización) | Verificado (código); la ocupación del puerto es inferida |
| T3-02 | Media | Un ADMIN puede editar uno de los 11 reportes del sistema que siguen en la principal y su SQL corre en la principal, fuera del aislamiento de la API de reportes | Verificado |
| T3-03 | Media | Rotar no revoca la generación anterior: el `DENY CONNECT` solo ocurre si alguien vuelve a correr el comando pasado un día, y no cierra las sesiones abiertas | Verificado |
| T3-04 | Media | `dcc7a75` exige el modo mixto en la instancia sin comprobar que `sa` está deshabilitado (ADR-44 aún no aplicado, PUB-06) | Verificado (código); el estado de `sa` en las instalaciones es inferido |
| T3-05 | Baja | La introspección acepta tokens con `cambiar_clave = 1` (D-MVP-01) | Verificado |
| T3-06 | Baja | La exportación de la principal (los 11 reportes y toda instalación sin `Direccion`) no exige `rptexportar` | Verificado |
| T3-07 | Baja | La llave del sitio se reutiliza por nombre sin comprobar la política de exportación, el dueño ni la DACL (ocupación previa del nombre) | Sospecha |
| T3-08 | Baja | Los sobres no autentican su origen: quien escribe en `dbo.ConexionLectura` puede redirigir la API de reportes a otro servidor | Verificado (diseño) |
| T3-09 | Baja | El indicador «desarrollo» de la introspección sale del entorno en ejecución, en la principal y en la API de reportes (mismo patrón que N-01) | Verificado |
| T3-10 | Baja | Reporte 7: el anexo muestra el «Esperado» por forma de pago de los Z sin «Ver cuadre de caja», mientras la tabla principal lo oculta | Verificado (código); la intención está por confirmar |
| T3-11 | Baja | La evidencia de la exportación queda solo en el registro (evento 5123, nivel Information); no existe `audit.Exportacion` | Verificado |
| T3-12 | Baja | Contención parcial: amplía quién puede crear credenciales de la instancia (RG-14). Además faltan los `DENY` explícitos de `VIEW DEFINITION` y `SHOWPLAN` que pide la cláusula 3 | Verificado (código); el efecto es inferido |

No hay hallazgos Críticos ni Altos.

## 3. Checklist OWASP Top 10 (2021)

| Categoría | Resultado | Evidencia y observaciones |
|---|---|---|
| A01 Control de acceso | Observaciones | La principal autentica antes de reenviar (`ReportesEndpoints.cs:24`, `RequireAuthorization`). La API de reportes valida cada petición por introspección. `rptexportar` se exige en la API de reportes (`ServicioReportes.cs:113`). Observaciones: T3-02, T3-05, T3-06 y T3-10 |
| A02 Fallas criptográficas | Bien, con observaciones | ECIES P-256 + HKDF-SHA256 + AES-256-GCM correcto (sección 5). Observaciones: T3-07 y T3-08 |
| A03 Inyección | Bien | Todo el SQL dinámico de `GPOS.Migracion` usa `QUOTENAME` sobre parámetros. La contraseña va como parámetro con `QUOTENAME(@c, '''')` (43 caracteres, menos de 128). Los nombres son constantes. El `DENY` generado sale de `sys.schemas` con `QUOTENAME`. `dcc7a75` arma cada sentencia en `@sql` (correcto: `EXEC` no admite expresiones) |
| A04 Diseño inseguro | Observaciones | T3-01, T3-03 y T3-08 |
| A05 Configuración | Observaciones | N-01 cerrado (sección 5). Observaciones: T3-04, T3-09 y T3-12 |
| A06 Componentes vulnerables | No aplica | No hay dependencias nuevas de terceros en el tramo (no se ejecutó una herramienta de auditoría de paquetes) |
| A07 Identificación y autenticación | Observaciones | E1 bien. Observación: T3-05 |
| A08 Integridad de software y datos | Observaciones | T3-08 y T3-11 |
| A09 Registro y monitoreo | Bien, con T3-11 | Ningún registro lleva la cadena, la contraseña ni el sobre (`FuenteConexionSobres.cs:108-169`; `ContenidoSobre.ToString` sin la clave, `SobreLectura.cs:12`). Los mensajes de `GPOS.Migracion` no muestran la contraseña |
| A10 SSRF | Observación | T3-08: un sobre plantado decide a qué servidor SQL se conecta la API de reportes |

## 4. Hallazgos

### T3-01 (Media) El reenvío HTTP entrega el token a cualquiera que escuche en el puerto

- **Riesgo:** `ReenviarAsync` copia `Authorization` y lo envía al cliente HTTP con `BaseAddress = Direccion` (`ReenvioReportes.cs:65-78`, `:172-176`). No se verifica la identidad del servidor. La canalización sí la verifica por su dueño (`:191-215`, T2-04). Esto afecta a la lista, la definición, la ejecución, la detección y la vista previa. Además, `Direccion` no se valida como *loopback*: una mala configuración manda el token en claro por la red.
- **Escenario:** en una caja que también hace de servidor, la sesión de Windows del cajero (sin privilegios) puede escuchar en el puerto de la API de reportes mientras el servicio está detenido, falla o arranca. También puede hacerlo en `[::1]` si el servicio se configuró solo con `127.0.0.1` y la principal usa `localhost` (sospecha). Recibiría los tokens de los usuarios que abren reportes, incluido el SUPER, y podría usarlos contra la principal durante su vigencia (12 h).
- **Remediación:**
  - Reenviar también por la canalización con el dueño verificado, que ya existe (`ClienteCanal`). Esa canalización es hoy solo de la exportación; ampliarla es una decisión de diseño que debe anotarse en ADR-109, cláusula 8. Costo: 0,5 a 1 día-persona.
  - Si se mantiene HTTP: validar al arrancar que `Direccion` sea de *loopback*.
  - Comprobar, antes de cada envío, el proceso dueño del puerto (`GetExtendedTcpTable` y el SID del servicio). Es más frágil.
- **Defensa en profundidad:** hasta tener ES256 con audiencia propia (ADR-41), el token robado vale también en la principal.

### T3-02 (Media) Reporte del sistema editado por un ADMIN que se ejecuta en la principal

- **Riesgo:**
  - `EnLaPrincipalAsync` decide solo por `DelSistema` y `Codigo` (`ReportesService.cs:68-72`).
  - `GuardarAsync` deja que un ADMIN cambie la `Consulta` de un reporte del sistema y conserva `DelSistema` y `Codigo` (`ReportesService.cs:103-134`; el propio mensaje de `:146` dice «puede modificarlos»).
  - Ese SQL lo ejecuta la principal con su login de escritura (`ReportesEndpoints.cs:30-46` y `:53-62`), protegida solo por su validador léxico (`ReportesService.cs:225`), y no con `gpos_rpt` sobre `rpt`.
  - Esto contradice P-2 («los reportes que cree un ADMIN van siempre a la API de reportes»). El riesgo aceptado en P-2 era el del SQL de la semilla, no el del diseñador.
- **Escenario:** un ADMIN (o quien robe su sesión) edita `CXC-ANTIGUEDAD` con SQL que lee tablas fuera de `rpt`, o que intenta saltar el validador, y lo ejecuta con la credencial de la principal (RG-14 abierto).
- **Remediación:** en `EnLaPrincipalAsync`, exigir además que la huella de la definición coincida con `HuellaSemilla`. Si no coincide, reenviar. Alternativa: impedir la edición de los 11 mientras estén en la lista. Costo: 0,25 día-persona. Desaparece al vaciar la lista en el tramo 4.

### T3-03 (Media) La rotación no revoca la generación anterior

- **Riesgo:** el `DENY CONNECT` de la generación retirada solo lo aplica una ejecución posterior de `crear-lectura` o `rotar-lectura`, pasado un día (`CredencialesLectura.cs:86-90`, `:220-232`). La documentación dice «después se le niega CONNECT» (`:24-25`). Si nadie vuelve a correr el comando, la contraseña anterior sigue entrando para siempre. Además, `DENY CONNECT` no cierra las sesiones ya abiertas ni las del *pool*.
- **Escenario:** se rota por sospecha de filtración (volcado de memoria o registro de la API de reportes) y la credencial filtrada sigue siendo válida.
- **Remediación:**
  - Opción `--revocar` (o comportamiento por omisión): `DENY CONNECT` y `KILL` de las sesiones del usuario anterior en cuanto la credencial nueva pasa la prueba.
  - La convivencia no hace falta para la disponibilidad: `FuenteConexionSobres` ya relee los sobres ante el 18456 (`:104-112`).
  - Si se conserva la convivencia, una tarea programada diaria que aplique el `DENY`.
  - Costo: 0,5 día-persona.

### T3-04 (Media) Modo mixto exigido sin comprobar `sa` (commit `dcc7a75`)

- **Riesgo:** `ExigirContencionAsync` detiene el comando con la instancia en «solo Windows» y pide pasarla a modo mixto (`dcc7a75`, `CredencialesLectura.cs`, comprobación de `IsIntegratedSecurityOnly`). El modo mixto habilita la autenticación SQL en toda la instancia. Según CLAUDE.md, `sa` sigue sin deshabilitarse (ADR-44 decidido, no aplicado; PUB-06). Así, el paso de PD-07 puede exponer `sa` a ataques de contraseña desde la red.
- **Escenario:** el técnico sigue el aviso, pasa la instancia a modo mixto y deja `sa` habilitado con la contraseña de la instalación. Un equipo de la LAN prueba contraseñas contra `sa`.
- **Remediación:**
  - Antes de crear usuarios (y en el texto del aviso), comprobar `sys.server_principals` (SID `0x01`, `is_disabled = 1`). Si `sa` está habilitado, detenerse y remitir a PUB-06.
  - Documentar que el modo mixto es una consecuencia de PD-07.
  - Costo: 0,25 día-persona.
  - Alternativa descartada: autenticación de Windows también para las bases de empresa. Una sola identidad del servicio entraría a todas las empresas, y se perdería el aislamiento por empresa en la base, que es el objetivo de la cláusula 4.

### T3-05 (Baja) La introspección acepta `cambiar_clave = 1`

- **Riesgo:** `ValidadorTokenPrincipal` rechaza `esquema_pendiente`, pero no el token con cambio de contraseña obligatorio (`ValidadorTokenPrincipal.cs:39-43`). Tampoco lo rechaza la API de reportes (`ProveedorContexto.cs:29`: «DebeCambiarClave no se usa»). Por el reenvío lo frena la principal; pero quien llame directamente a la API de reportes en *loopback* lee reportes sin haber cambiado la contraseña inicial (D-MVP-01).
- **Remediación:** devolver `Invalido` cuando `cambiar_clave = 1`, igual que con `esquema_pendiente`. Costo: 0,1 día-persona.

### T3-06 (Baja) Exportación en la principal sin `rptexportar`

- **Riesgo:** la ruta de exportación de la principal no comprueba el privilegio (`ReportesEndpoints.cs:59-62`). Afecta a los 11 reportes de `EnLaPrincipal` y a toda instalación sin `Direccion`, que es la configuración por omisión. Un ADMIN que quita «Exportar reportes» cree haber cerrado la extracción masiva, pero no la cerró.
- **Remediación:** exigir `Permisos.ReportesExportar` en esa ruta. Costo: 0,1 día-persona.

### T3-07 (Baja, sospecha) Llave del sitio reutilizada sin comprobar sus propiedades

- **Riesgo:** `llave-sitio` hace `Abrir ?? Crear` (`ComandosLectura.cs:48`). `LlaveSitio.Abrir` (`LlaveSitio.cs:80-92`) y `ProveedorLlaveSitio` (`FuenteConexionSobres.cs:44-47`) aceptan cualquier llave P-256 con ese nombre. No comprueban `ExportPolicy`, el dueño ni la DACL. Además, `Crear` no fija el dueño, que queda en quien la crea (`LlaveSitio.cs:117-118`), y no comprueba que esa identidad sea administrativa.
- **Escenario:** si un usuario local sin privilegios puede crear llaves en el almacén de la máquina (inferido; está por confirmar en Windows 11 y Server), puede crear una llave exportable con ese nombre antes de la instalación. Con acceso de lectura a `dbo.ConexionLectura`, abriría los sobres.
- **Remediación:** al abrir, exigir `ExportPolicy == None`, dueño Administradores o SYSTEM y la DACL esperada; si no se cumplen, fallar cerrado. Al crear, fijar el dueño en Administradores. Costo: 0,5 día-persona, con una prueba del permiso GENERIC_READ con la cuenta del servicio (sigue inferido, sin prueba).

### T3-08 (Baja) Los sobres no autentican su origen

- **Riesgo:** ECIES con llave efímera solo da confidencialidad: cualquiera con la llave pública (que es pública) sella un sobre válido. `FuenteConexionSobres` comprueba que el sobre coincida con su fila (`:146-150`), pero no quién la escribió. `dbo.ConexionLectura` la debería escribir solo `GPOS.Migracion` (`rptsis-vistas-sistema.sql:30-31`), pero el login de la principal tiene escritura en `dbo` (RG-14).
- **Escenario:** con la principal comprometida, se planta un sobre que apunta a un SQL Server hostil. Los reportes y la evidencia de las exportaciones (ADR-111) muestran datos falsos.
- **Remediación:** a corto plazo, `DENY INSERT, UPDATE, DELETE` sobre `dbo.ConexionLectura` al login de la principal (RG-14). Más adelante, firmar los sobres con una llave del operador. Costo: 0,25 día-persona (el `DENY`).

### T3-09 (Baja) El indicador «desarrollo» sale del entorno en ejecución

- **Riesgo:** `AgregarIntrospeccion(config, builder.Environment.IsDevelopment())` (`src/GPOS.Api/Program.cs:123`) y `ResolverCuentaServidor(..., IsDevelopment())` (`src/GPOS.Reportes.Api/Program.cs:27`) relajan S15-02 con solo `ASPNETCORE_ENVIRONMENT`. Es el patrón que N-01 corrigió para la escucha. Se necesita ser administrador para ponerlo.
- **Sobre el riesgo señalado del entorno «Pruebas»** (`src/GPOS.Api/Program.cs:122`): en «Pruebas», sin la configuración explícita, la principal no levanta la introspección y la API de reportes **falla cerrada** (503). No es una apertura (verificado en el código).
- **Remediación:** exigir además la compilación Debug, como con `ComprobarCarpeta`. Costo: 0,1 día-persona.

### T3-10 (Baja) Esperado del conteo visible sin «Ver cuadre de caja»

- **Riesgo:** sin el privilegio, la tabla oculta `EfectivoEsperado` (`ReportesVentasRegistrados.cs:181-184`, `:234-237`), pero el anexo conserva `Esperado` por forma de pago, incluido el efectivo, de los Z no anulados (`:239-241`; `ConsultasVentasReportes.cs:264-269`; contrato `contrato-vistas.v1.json:1940`). El contrato define `vercuadrecaja` como «esperado, declarado, contado y diferencia» (`:14`). El conteo ciego de los X sí se respeta.
- **Remediación:** que el arquitecto de datos y el propietario confirmen la intención. Si RS-02 manda, `Esperado` en NULL en `rpt.CierreCajaConteo` o quitar la columna del anexo sin el privilegio. Costo: 0,1 día-persona.

### T3-11 (Baja) Evidencia de la exportación solo en el registro

- **Riesgo:** la huella SHA-256 del archivo, las filas y la huella de los datos van al evento 5123 en nivel Information (`ReenvioReportes.cs:115-124`). Si el filtro del registro está en Warning, se pierden. No son inalterables y no existe `audit.Exportacion`. El plan exigía su fila en la prueba F9.
- **Remediación:** el DDL de `audit.Exportacion` (arquitecto de datos) antes de publicar; mientras tanto, un nivel o una categoría que no se filtre. Costo: 0,5 día-persona más el DDL.

### T3-12 (Baja) Contención parcial y `DENY` de la cláusula 3

- **Riesgo:**
  - Con `CONTAINMENT = PARTIAL` (`CredencialesLectura.cs`, `ExigirContencionAsync`), todo principal con `ALTER ANY USER` en la base de empresa crea usuarios que se autentican contra la instancia, sin login. Si el login de la principal es `db_owner` (RG-14), eso sirve como persistencia.
  - `PermisosLecturaReportes.Sql` no niega de forma explícita `VIEW DEFINITION` ni `SHOWPLAN` (`:15` los «no concede»), mientras la cláusula 3 de ADR-109 dice «se deniegan». Hoy el efecto es el mismo salvo que alguien los conceda a `public`.
- **Remediación:** `DENY VIEW DEFINITION, SHOWPLAN TO gpos_reportes, gpos_lectura`. Cerrar RG-14: la principal sin `ALTER ANY USER`. Revisar que `AUTO_CLOSE` esté apagado. Costo: 0,1 día-persona más RG-14.

## 4 bis. Commit `dcc7a75` (posterior a `c47d3b0`)

- **Corrección real:** en `c47d3b0`, `EXEC (N'…' + QUOTENAME(@u))` no compila en T-SQL, así que el camino real de `crear-lectura` nunca había corrido. `dcc7a75` arma cada sentencia en `@sql` antes del `EXEC`. Revisé las siete sentencias: todas usan `QUOTENAME` sobre parámetros o sobre `DB_NAME()`. Las entradas tienen 128 caracteres o menos (`QUOTENAME` devolvería NULL por encima, y `EXEC(NULL)` no haría nada, sin abrir una inyección). La cuenta de `crear-lectura-sistema` sigue filtrada (`[`, `]`, `'` y `;`) y debe llevar `\`.
- **5061:** no usa `WITH ROLLBACK IMMEDIATE`, que revertiría las ventas en curso. Es correcto. Exige detener la principal, lo que es operativo, no de seguridad.
- **Modo solo Windows:** la detención temprana es correcta, pero abre T3-04.
- No introduce secretos en mensajes ni registros.

## 5. Controles que están bien implementados

- **Sobre (formato 1):**
  - `[1][punto efímero 65][nonce 12][cifrado][etiqueta 16]` hasta 512 bytes (`SobreLectura.cs:68-77`, `:93-94`).
  - Llave efímera por sobre, así que repetir el nonce no tiene efecto.
  - HKDF con la sal = punto + huella de la llave destino, y la información con largos delante (`:147-170`). Los datos asociados de GCM llevan el formato, la empresa, el rol y el usuario (generación).
  - El usuario de dentro debe coincidir con la fila (`:122`). Se rechazan el formato, el punto no comprimido y la etiqueta.
  - La validación del punto en la curva la hace CNG al importarlo (inferido; la excepción llega como `CryptographicException` y falla cerrada, `:108-112`).
  - El secreto y el texto claro se borran (`:79-83`, `:130-134`). La llave AES no se borra cuando GCM lanza: es menor y no es hallazgo.
- **Llave del sitio:**
  - CNG Software KSP, `ExportPolicy = None`, uso solo para acuerdo y almacén de la máquina (`LlaveSitio.cs:64-76`).
  - DACL protegida: Administradores y SYSTEM con GENERIC_ALL, el servicio con GENERIC_READ (`:109-122`). Que GENERIC_READ baste para el acuerdo es inferido y está sin prueba.
  - El almacén del usuario se rechaza fuera de Debug y desarrollo (`ServiciosLectura.cs`, `AgregarLectura`).
- **Credenciales:**
  - Contraseña de 32 bytes del generador criptográfico (`CredencialesLectura.cs:79`). No se muestra ni se guarda.
  - Prueba de entrada antes de cambiar los sobres (`:183-198`), sin cadena en el mensaje. Transacción serializable para N, R y A (`:200-218`). Índice único de A y N (`rptsis-vistas-sistema.sql`).
  - Roles según ADR-109, cláusula 4: `gpos_reportes` solo `rpt` (`rptc` e `imp` denegados) y `gpos_lectura` `rpt`, `rptc` e `imp`. El encargo decía «`gpos_reportes` solo `rpt` e `imp`»; el código sigue el ADR (sin `imp`), que es lo correcto.
  - `DENY` sobre todo esquema de tablas generado desde `sys.schemas`, `DENY CREATE`, `REVOKE CONNECT` a guest (`PermisosLecturaReportes.cs:47-62`).
  - V-R1 falla cerrado (`SqlMigracionesOla5.cs:13-21`).
  - `gpos_rpt_sis` solo con `rptsis` (`RolSistemaSql`).
- **Fuente de conexión:**
  - Caché de 10 minutos por empresa y rol, solo en memoria. Relectura una sola vez ante 18456 y prueba de A y después N (`FuenteConexionSobres.cs:94-171`).
  - Filtro por la huella de la llave. El servidor y la base del sobre se cotejan con la fila. `PersistSecurityInfo = false`.
  - O-2 en cada sesión de `GPOS_SYSDATA` (`PreparadorSesion.PrepararSistemaAsync`). Huella del contrato `rptsis` comprobada.
- **Introspección y E1:**
  - Los mismos parámetros que `AddJwtBearer` (S15-08) y la misma revocación (R-3). Rechazo de `esquema_pendiente` después de la revocación.
  - `ExigeOtpSuper` aditivo, que falla cerrado con la fase A activa: 401 con `X-GPOS-Sesion: factor` (`AutenticacionIntrospeccion.cs:58-65`, `:82-93`). El 401 se copia al cliente por el reenvío (`ReenvioReportes.cs:60`, `:136`).
- **Canalización de exportación (T2-04, lado del cliente):** dueño comprobado antes del primer byte, suplantación `Identification`, 503 y evento crítico 5122 (`ReenvioReportes.cs:191-215`). Encabezados de respuesta por lista blanca.
- **N-01:** *loopback* en todo entorno, rechazo de `Kestrel:Endpoints` y comprobación de las direcciones efectivas al arrancar (`ServiciosReportes.cs`, `ValidarDireccion`, `DireccionNoPermitida` y `ComprobarDireccionesEfectivas`). **Cerrado.**
- **N-02:** atributos y DACL leídos del mismo identificador, con `OPEN_REPARSE_POINT` y sin `FILE_SHARE_DELETE`. Los identificadores de la raíz y del componente se retienen mientras viva el proceso (`ComprobacionCarpetas.cs`). **Cerrado.**
- **Enmascarado:** cédula o pasaporte en `rpt` como `*******` + los últimos 4; si el tipo no se puede determinar, enmascara (falla cerrada; `VistasReportesOla5.cs:36-45`). El pasaporte nunca sale completo en `rptc`.
- **Privilegios:** «Ver costos» elige la variante `rpt` o `rptc` (reporte 5) y «Ver cuadre de caja» la del reporte 7. `rptexportar` se exige en la API de reportes. El paso único de permisos se aplica una sola vez.

## 6. Remediaciones priorizadas

| Prioridad | Hallazgo | Acción | Responsable | Esfuerzo |
|---|---|---|---|---|
| 1 | T3-04 | Comprobar `sa` deshabilitado antes de exigir el modo mixto; aviso con PUB-06 | B (desarrollo) | 0,25 día-persona |
| 2 | T3-02 | `EnLaPrincipal` solo si la definición está intacta (huella de la semilla) | B | 0,25 día-persona |
| 3 | T3-01 | Reenvío por la canalización verificada, o `Direccion` solo de *loopback* | B (y anotación en ADR-109, cláusula 8) | 0,5 a 1 día-persona |
| 4 | T3-03 | Revocación inmediata (`DENY` y `KILL`) o tarea diaria | B y devops | 0,5 día-persona |
| 5 | T3-05, T3-06, T3-09 | Lote rápido: `cambiar_clave`, `rptexportar` en la principal y desarrollo solo con Debug | B (principal: A) | 0,3 día-persona |
| 6 | T3-07, T3-08, T3-12 | Comprobaciones de la llave, `DENY` sobre `ConexionLectura` y `DENY VIEW DEFINITION`/`SHOWPLAN`; RG-14 | B y A | 1 día-persona |
| 7 | T3-10, T3-11 | Confirmar RS-02 en el anexo; DDL de `audit.Exportacion` | Arquitecto de datos y propietario | 0,5 día-persona más el DDL |

**Condición propuesta:**
- T3-01 a T3-04 antes de configurar `GPOS:Reportes:Reenvio:Direccion` o de crear credenciales en un sitio real.
- T3-11 antes de publicar al cliente.
- Nada de esto impide unir a `feature/modelo-ng`: hoy el reenvío está apagado por omisión y no hay sitios reales.

## 7. Recomendación

**Aprobado con observaciones** para unir `b/ola5` (hasta `dcc7a75`) a `feature/modelo-ng`. Es una recomendación técnica; la decisión es del propietario.

### Supuestos
- `CuentaServicioVirtual`, `IdentidadCanalizacion` y `ServidorIntrospeccion` son del tramo 2 y no se volvieron a revisar en detalle.
- Que la DACL GENERIC_READ baste para el acuerdo de llaves, que CNG valide el punto en la curva y que un usuario sin privilegios pueda crear llaves en el almacén de la máquina son inferencias sin prueba.
- No se ejecutó ninguna herramienta de dependencias.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\AppData\Local\Temp\claude\C--Users-lfmen-source-repos-Solucion-GPOS-NG-GPOS-NG\2ab4d64a-60e5-4721-9bba-4b93894990d8\scratchpad\auditoria-ola5-tramo3.md`
- Supuestos: los de la sección anterior
- Decisiones candidatas a ADR: el reenvío de compatibilidad por la canalización verificada en lugar de HTTP (T3-01; precisión de ADR-109, cláusula 8); el modo mixto como consecuencia de PD-07 con `sa` deshabilitado como requisito (T3-04; precisión de ADR-44 y ADR-109, cláusula 5)
- Entregas a otros agentes: desarrollo B → T3-01 a T3-05, T3-07 y T3-09; equipo A (principal y RG-14) → T3-06, T3-08 y T3-12; arquitecto de datos → T3-10 y `audit.Exportacion` (T3-11); devops → tarea de revocación (T3-03) y comprobación de `sa` en el instalador; qa-automatizado → prueba de la DACL de la llave con la cuenta del servicio y del reenvío con el puerto ocupado
- Próximo paso recomendado: unir a `feature/modelo-ng` y abrir el lote T3-01 a T3-04 antes de encender el reenvío o crear credenciales en un sitio real.

---

## Segunda pasada (2026-10-10)

- **Alcance:** `dcc7a75..30a7c20` en `b/ola5`, es decir `4e1299d`, `2ee844a` y `0b3b62a` a `30a7c20`. Diff de `src`: 17 archivos, +392/−92.
- **Modo:** solo lectura. No compilé ni corrí pruebas; los resultados de pruebas que se citan son los que declaran los mensajes de commit.
- **Commits posteriores a `30a7c20`:** ninguno al cerrar la revisión.

### 1. Estado de cada hallazgo

| ID | Estado | Verificación |
|---|---|---|
| T3-01 | **Cerrado** | Todo el reenvío usa el cliente de la canalización. El dueño se comprueba antes del primer byte y la conexión usa `Identification`; si falla, responde 503 y deja el evento 5122. Ya no existe el cliente HTTP del reenvío (`ReenvioReportes.cs:71-125`, `:205-230`). `Direccion` queda solo como interruptor: debe ser HTTP de *loopback* y Windows, o la principal no arranca (`:171-193`). Detalle en el punto (1) de la sección 2 |
| T3-02 | **Cerrado** | `EnLaPrincipalAsync` exige `IntactoEnLaPrincipal`: el código está en la lista P-2 y la huella es igual a la de la semilla compilada, no a la guardada en la base (`ReportesService.cs:70-74`, `ReportesSemilla.cs:488-497`). Ver el punto (2) |
| T3-03 | **Cerrado, con observación nueva T3-13** | La rotación niega `CONNECT` y hace `KILL` a la generación anterior en la misma ejecución, después de activar el sobre nuevo (`CredencialesLectura.cs`, `AplicarAsync` y `RevocarAsync`). Los retirados de versiones anteriores se niegan sin esperar un día (`RetiradosAsync`). La disponibilidad la da la relectura: `SELECT 1` al abrir, el 18456 en cualquier error del lote y el vaciado del grupo (`FuenteConexionSobres.cs:191-221`, `4e1299d`). Un 18456 en plena petición responde 503 `CREDENCIALES_LECTURA_PENDIENTES`, sin el mensaje del motor que traía el nombre del usuario SQL (`EjecutorConsultas.cs`, `Clasificar`). Ver el punto (3) |
| T3-04 | **Cerrado** | `ExigirSaDeshabilitado` lee `is_disabled` del SID `0x01` (vale aunque `sa` esté renombrada). Si `sa` está habilitada o no se ve su estado (NULL), se detiene sin crear nada: falla cerrada. Se comprueba después del modo mixto y antes de contener la base. El aviso de «solo Windows» pide deshabilitar `sa` antes de pasar a modo mixto |
| T3-05 | **Cerrado** | La principal rechaza `cambiar_clave = 1` después de la revocación, con el motivo `cambio_clave` (`ValidadorTokenPrincipal.cs:43-45`). La API de reportes lo rechaza también como defensa en profundidad, con 403 `CAMBIO_CLAVE_OBLIGATORIO`, sin `X-GPOS-Sesion` (`AutenticacionIntrospeccion.cs:61-66`, `:89-96`, `:103-105`) |
| T3-06 | **Abierto** (Baja; equipo A) | La exportación de la principal sigue sin exigir `rptexportar` (ruta `exportar` sin reenvío en `ReportesEndpoints.cs`) |
| T3-07 | **Cerrado** | `Abrir` exige ECDH P-256, `ExportPolicy = None` y, en la máquina, dueño Administradores o SYSTEM, ACL presente y solo lectura para la cuenta del servicio. Si no cumple, `CryptographicException` (`LlaveSitio.cs`, `Abrir` y `ComprobarSeguridad`). `Crear` fija el dueño en Administradores. `llave-sitio` no reutiliza una llave que no cumpla ni publica su llave pública. La API registra el evento crítico 5115 y responde 503. Ver el punto (4) |
| T3-08 | **Abierto** (Baja; RG-14) | Sin cambios |
| T3-09 | **Cerrado** | `ModoDesarrollo` = entorno de desarrollo **y** `#if DEBUG`; en Release siempre es false, en la principal y en la API de reportes (`ValidadorTokenPrincipal.cs:84-91`, `VerificadorIntrospeccion.cs:68-75`). Ver el punto (5) |
| T3-10 | **Abierto** (Baja; arquitecto de datos y propietario) | Sin cambios |
| T3-11 | **Abierto** (Baja; DDL de `audit.Exportacion`) | Sin cambios; el evento 5123 sigue en nivel Information |
| T3-12 | **Abierto** (Baja; RG-14) | Sin cambios |
| T3-13 | **Nuevo** (Baja) | Sin `VIEW SERVER STATE`, la revocación no ve las sesiones y no lo informa (sección 3) |

### 2. Puntos que pidió revisar el desarrollador

**(1) Canalización con todas las rutas.** Verificado en el código.
- Kestrel atiende todo el *pipeline* también por la canalización (`ListenNamedPipe`, `ServiciosReportes.cs:89-94`). La única ruta restringida a la canalización es la exportación (`EndpointsReportes.cs:67`, `PorCanalInterno`).
- La ACL basta: dueño = la cuenta del servicio (fijado de forma explícita); `FullControl` solo para el servicio; `ReadWrite` para la principal. `PipeAccessRights.ReadWrite` (0x2019B) no incluye `CreateNewInstance` (0x4), así que la principal no puede crear instancias. NETWORK está denegado; no hay Everyone, Authenticated Users ni Usuarios. La primera instancia es exclusiva (`ServiciosReportes.cs:110-135`).
- Llevar más rutas no cambia el modelo. Cada petición trae el token del usuario y la API de reportes la valida por introspección: la canalización autentica al **transporte**, no al usuario. El límite de ritmo se reparte por el `sub` del token, no por IP (`EndpointsReportes.cs:108-113`), así que no se colapsa en una sola partición.
- *Observación sin severidad:* la escucha HTTP de *loopback* de la API de reportes ya no la usa la principal. Si nadie más la necesita (salud y diagnóstico), conviene cerrarla para reducir la superficie: cualquier proceso local que tenga un token la puede usar, aunque no es un riesgo nuevo.

**(2) Regla de la huella de T3-02.** Es correcta y falla del lado seguro.
- Se compara contra la semilla **compilada**, así que un ADMIN no puede «legitimar» su cambio escribiendo `HuellaSemilla` en la base.
- La huella cubre la consulta, las opciones, las columnas, `Enlace`, `Detalle` y la fuente (`ReportesSemilla.cs:467-482`). Va truncada a 64 bits: una segunda preimagen hecha a propósito no es viable en este contexto.
- Al normalizar `\r\n` y recortar los extremos no se esconde ningún cambio que altere la ejecución.
- Caso de una versión anterior intacta: `ActualizarSistemaAsync` la lleva a la semilla actual al arrancar (`ReportesSemilla.cs:400-419`), así que solo quedan distintos los que modificó el ADMIN.
- Consecuencia aceptable: un P-2 modificado no funciona con el reenvío encendido hasta el tramo 4.
- *Recomendación de UX, no de seguridad:* que el error lo explique y ofrezca «Restablecer el reporte del sistema».

**(3) Permisos de `rotar-lectura` y el `KILL`.**
- Quien ejecuta necesita, en la práctica, `sysadmin` o un conjunto equivalente: `ALTER DATABASE` (contención), `ALTER ANY USER` y `CONTROL` en la base, `VIEW ANY DEFINITION` o `ALTER ANY LOGIN` para ver `sa`, `VIEW SERVER STATE` para ver las sesiones y `ALTER ANY CONNECTION` para `KILL`.
- Es coherente con ADR-44: lo ejecuta una persona con `gsf` o con su identidad de Windows administrativa, nunca una aplicación. Conviene documentar el mínimo en la guía de `GPOS.Migracion`.
- El `KILL` es seguro:
  - usa un `smallint` leído de `sys.dm_exec_sessions`, sin datos de entrada;
  - el filtro `login_name = @u AND authenticating_database_id = DB_ID()` solo alcanza al usuario contenido de **esta** base, no a un login homónimo de la instancia;
  - excluye `@@SPID`;
  - 6106 se ignora; 6102 y 297 se cuentan e informan.
- Falta el caso de T3-13.

**(4) Máscara `GENERIC_READ | 0x00120089`.** Correcta.
- `0x00120089` = `FILE_READ_DATA` (0x1) + `FILE_READ_EA` (0x8) + `FILE_READ_ATTRIBUTES` (0x80) + `READ_CONTROL` (0x20000) + `SYNCHRONIZE` (0x100000), es decir `FILE_GENERIC_READ`.
- La comprobación `(máscara & ~permitida) == 0` excluye escritura, `DELETE`, `WRITE_DAC`, `WRITE_OWNER` y `GENERIC_ALL/WRITE`.
- Las reglas de denegación solo restan y se ignoran bien. Un tipo de regla desconocido se rechaza (falla cerrada).
- El control fuerte es el **dueño**: una cuenta sin elevación no puede poner como dueño a Administradores ni a SYSTEM. Eso también cierra el caso de una llave importada con `ExportPolicy = None` por alguien que conserva el material privado.
- Sigue inferido, sin prueba con elevación: que la cuenta virtual pueda usar la llave con GENERIC_READ. El mensaje de `eea38d2` lo reconoce. Queda para qa-automatizado en una máquina con elevación (o en la prueba del instalador).

**(5) `IsDevelopment()` en Release.** Revisé todos los usos en `src/GPOS.Api`, `src/GPOS.Reportes.Api`, `src/GPOS.Reportes` y `src/GPOS.Comun`:
- **Introspección:** `ModoDesarrollo` con `#if DEBUG` en las dos API.
- **Carpeta de temporales:** `puedeOmitirCarpeta` dentro de `#if DEBUG` (`GPOS.Reportes.Api/Program.cs:53-54`).
- **Almacén del usuario de la llave:** atado a ese mismo indicador (`ServiciosLectura.cs`).
- **Únicos usos restantes:**
  - `app.MapOpenApi()` con `IsDevelopment()` (`GPOS.Api/Program.cs:240`). En Release, con la variable `ASPNETCORE_ENVIRONMENT=Development`, publica el documento OpenAPI: divulgación de la superficie, no un relajamiento de controles, y ponerla exige ser administrador. *Observación:* atarlo también a `#if DEBUG`.
  - `IsEnvironment("Pruebas")` (`:122`, `:217`): apaga la introspección (falla cerrada) o **impide** arrancar con `EsquemaUsuarioPruebas`. No relaja nada.
- *Observación menor:* en `VerificadorIntrospeccion.cs` el nuevo `ModoDesarrollo` quedó entre el `<summary>` antiguo de `ResolverCuentaServidor` y el método (dos `<summary>` seguidos). Es documentación, no seguridad.

### 3. Hallazgo nuevo

#### T3-13 (Baja) Revocación sin aviso cuando no se ven las sesiones

- **Riesgo:** sin `VIEW SERVER STATE`, `sys.dm_exec_sessions` devuelve solo la propia sesión. `RevocarAsync` encuentra cero sesiones, no hace `KILL` y no lo dice: el informe solo menciona la falta de `ALTER ANY CONNECTION` (`CredencialesLectura.cs`, `RevocarAsync`).
- **Impacto:** acotado. Según la verificación del desarrollador (SQL Server 2025, 2026-10-10), una sesión de un usuario con `CONNECT` negado ya no ejecuta sentencias (916), y el grupo revalida el inicio de sesión al restablecerse. No lo verifiqué yo.
- **Remediación:** comprobar `HAS_PERMS_BY_NAME(NULL, NULL, 'VIEW SERVER STATE')` y avisar, igual que con `ALTER ANY CONNECTION`. Costo: 0,1 día-persona.

### 4. Observación para la entrega 2 (sin severidad hoy)

- **Riesgo:** la revocación inmediata usa el usuario de la base sin mirar otros sitios. `RevocarAsync(vigente.Usuario)` no comprueba si otro sitio tiene un sobre activo con ese mismo usuario contenido. `RetiradosAsync` sí lo comprueba, pero solo para los retirados. Además, la generación (`_a`/`_b`) se elige por sitio, mientras el usuario es de la base.
- **Efecto:** con dos sitios leyendo la misma base (nodos de ADR-53), rotar en uno negaría o cambiaría la contraseña del otro. Es un problema de disponibilidad, no de confidencialidad, y hoy hay un solo sitio.
- **Remediación (al diseñar el nodo):** usuarios por sitio (`gpos_rpt_{sitio}_{a|b}`), o elegir la generación y revocar considerando todos los sitios.

### 5. Dictamen final para unir `b/ola5`

**Aprobado con observaciones** para unir `b/ola5` (hasta `30a7c20`) a `feature/modelo-ng`. Es una recomendación técnica; la decisión es del propietario.
- Los cuatro Medios de la primera pasada (T3-01 a T3-04) están cerrados, igual que T3-05, T3-07 y T3-09.
- Quedan abiertos solo Bajos: T3-06, T3-08, T3-10, T3-11, T3-12 y el nuevo T3-13.
- **Antes de publicar al cliente:** T3-06 y T3-11, que ya estaban condicionados.
- **Antes del primer sitio real:** la prueba con elevación de la DACL de la llave para la cuenta del servicio.

### Cierre (segunda pasada)
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\AppData\Local\Temp\claude\C--Users-lfmen-source-repos-Solucion-GPOS-NG-GPOS-NG\2ab4d64a-60e5-4721-9bba-4b93894990d8\scratchpad\auditoria-ola5-tramo3.md` (sección «Segunda pasada»)
- Supuestos:
  - Que el `CONNECT` negado corta las sesiones abiertas (916) y que el grupo revalida al restablecerse, según lo verificado por el desarrollador, no por mí.
  - Que GENERIC_READ basta para usar la llave: sigue inferido.
- Decisiones candidatas a ADR: el reenvío de compatibilidad por la canalización verificada como único transporte (nota de aplicación de ADR-109, cláusula 8; ya implementado en `0b3b62a`).
- Entregas a otros agentes:
  - desarrollo B → T3-13 y la observación de documentación de `VerificadorIntrospeccion`;
  - equipo A → T3-06, T3-08 y T3-12 (RG-14);
  - arquitecto de datos → T3-10 y `audit.Exportacion` (T3-11);
  - arquitecto de software → usuarios por sitio para la entrega 2;
  - qa-automatizado → prueba con elevación de la llave de la máquina con `NT SERVICE\GPOS.Reportes`;
  - documentador → permisos mínimos de quien ejecuta `crear-lectura` y `rotar-lectura`.
- Próximo paso recomendado: unir `b/ola5` a `feature/modelo-ng` y llevar T3-06 y T3-11 al lote previo a la publicación.
