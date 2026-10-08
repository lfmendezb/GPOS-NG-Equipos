# Revisión de seguridad S-15: canalización con nombre con ACL (ola 5, equipo B)

**Fecha:** 2026-10-08 · **Revisor:** auditor-seguridad del equipo A · **Rama:** `b/ola5` en `6a93823` (desde `f21b788`) · **Encargo:** hoja de la ola 5, precisión de DR-04 / S-15; ADR-109 a 111 en `master`
**Tipo:** revisión estática, de solo lectura (`git show`, `git diff`, `git log`). No se compiló ni se ejecutaron pruebas; las 90 de 90 pruebas las informa B y no las verifiqué.

## Resumen

| ID | Severidad | Título | Cuándo cerrarlo |
|---|---|---|---|
| S15-01 | Media | Reportes acepta el token del modo limitado (`esquema_pendiente`) como una sesión completa | Antes de unir el enganche o de la primera ruta con datos |
| S15-02 | Media | No está definida la identidad de la principal y no se rechazan las cuentas compartidas, aunque la protección contra la suplantación depende de esa cuenta | Antes de unir (código) y del instalador (devops) |
| S15-03 | Media | El servidor no reintenta si no puede crear la canalización, así que reportes queda en 503 hasta que se reinicie la principal | Antes de producción |
| S15-04 | Media | No hay limitación de peticiones ni prevalidación antes de la introspección: una ráfaga de tokens falsos vacía la caché y satura las 4 instancias | Antes de exponer reportes fuera del equipo |
| S15-05 | Media | ADR-76 (PA-76-1): el servicio `GPOS.Reportes` no comprueba sus privilegios al arrancar | Antes de producción |
| S15-06 | Baja | Ventana de revocación de hasta 15 s en reportes (riesgo aceptado en ADR-109, cláusula 6); su control compensatorio (`rptsis`) está pendiente | Con las vistas `rptsis` |
| S15-07 | Baja | Al reponer una instancia rota se libera el nombre un momento, y un fallo de `Crear` mata esa instancia sin dejar registro | Antes de producción |
| S15-08 | Baja | El validador de la LEEME no comparte los `TokenValidationParameters` con `Program.cs` ni fija `ValidAlgorithms` | Al unir |
| S15-09 | Baja | La identidad del cliente y del dueño solo se probó con la misma cuenta. Sospecha sin verificar con dos cuentas virtuales | Prueba elevada antes de producción |
| S15-10 | Baja | Se verifica el servidor de otra forma que en ADR-75 (dueño del descriptor en lugar de PID y token) y no está documentado | Nota en ADR-109 |
| S15-11 | Baja | Algunos errores inesperados del cliente salen como 500 en lugar de 503 (siguen fallando cerrados) | Al unir |

**Conteo:** Crítica 0 · Alta 0 · Media 5 · Baja 6.
**Recomendación técnica:** **Aprobado con observaciones.** La decisión es del propietario (C2). S15-01 y S15-02 son condiciones para unir el enganche. S15-03 y S15-05 son condiciones antes de producción.
**Esfuerzo de las remediaciones (inferido):** unos 2,6 días-persona (0,5 semanas-persona). Costo: USD 0.

## 1. Alcance y superficie revisada

- `src/GPOS.Comun`: `Introspeccion/ServidorIntrospeccion.cs`, `ProtocoloIntrospeccion.cs`, `CuentaServicioVirtual.cs`, `IVerificadorToken.cs`, `LEEME-enganche-principal.md`, `Sesion/ClaimsSesion.cs` y `GPOS.Comun.csproj`.
- `src/GPOS.Reportes.Api`: `Program.cs`, `Seguridad/*`, `ErroresReportes.cs`, `appsettings*.json`, `launchSettings.json` y `.csproj`.
- `tests/GPOS.Reportes.Tests`: `IntrospeccionCanalizacionTests.cs`, `AutenticacionReportesTests.cs` (solo los casos) y `.csproj`.
- Contexto en `f21b788`: `src/GPOS.Api/Program.cs:54-94`, `Seguridad/RevocacionSesiones.cs`, `Seguridad/ModoEsquemaPendiente.cs` y `Seguridad/Seguridad.cs:25-40`. En `master`: ADR-41 (nota del 2026-10-08), ADR-75, ADR-76 y ADR-109.
- **Superficie expuesta:**
  - Canalización `\\.\pipe\GPOS.Api.Introspeccion`, local, solo para la cuenta de reportes.
  - Escucha HTTP de reportes en `http://localhost:5073` (`appsettings.json:15`), con `/api/salud` anónima y la política por omisión que exige sesión.
  - Ninguna ruta HTTP de introspección.
- **Fuera de alcance:** `GPOS.Reportes/Ejecucion/*` (ejecutor y analizador SQL), credenciales selladas, vistas e instalador `instalador/Reportes`. Ninguno está en esta tanda o no forma parte de S-15.

## 2. Checklist OWASP Top 10 (2021)

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | La ACL y la verificación de identidad son correctas (sección 5). Hay hallazgos: S15-01 (modo limitado) y S15-06 (ventana de 15 s). |
| A02 Fallas criptográficas | Correcto. La clave de la caché es SHA-256 (aprobado). Reportes nunca recibe la clave HS256 (`GPOS.Reportes.Api.csproj:10-12`; no hay `Jwt` en `appsettings.json`). El SHA-1 de `CuentaServicioVirtual.cs:22` no es criptográfico (sección 5). |
| A03 Inyección | No aplica a S-15. El protocolo es JSON con largo prefijado y topes (`ProtocoloIntrospeccion.cs:60-69`). |
| A04 Diseño inseguro | Hay hallazgos: S15-02 (exclusividad de la cuenta), S15-03 y S15-07 (disponibilidad del canal). |
| A05 Configuración | Hay hallazgos: S15-02 y S15-05. `appsettings.Development.json` no se publica (`GPOS.Reportes.Api.csproj:36-38`). |
| A06 Componentes vulnerables | Ver la sección 5. Las dependencias son de primera parte y van alineadas con 10.0.12. No se corrió `dotnet list package --vulnerable`, porque la revisión era de solo lectura. |
| A07 Identificación y autenticación | Falla cerrada correcta. Hay hallazgos: S15-01, S15-04 y S15-08. |
| A08 Integridad | El cliente comprueba el dueño de la canalización antes de enviar el token (`VerificadorIntrospeccion.cs:90-91`). Ver S15-10. |
| A09 Registro y monitoreo | Ningún registro incluye el token. Los rechazos y la suplantación se registran como `Warning` o `Critical`. Ver S15-07 (fallo sin registro). |
| A10 SSRF | No aplica. El nombre de la canalización es local (`"."`) y viene de la configuración, no del usuario. |

## 3. Hallazgos

### S15-01 · Media · Reportes acepta el token del modo limitado como una sesión completa
- **Riesgo.** En la principal, el claim `esquema_pendiente=1` es una lista blanca que niega todo por omisión: solo sirven las rutas marcadas, y en cada petición se vuelve a comprobar en la base que el usuario sea un SUPER habilitado (`f21b788:src/GPOS.Api/Seguridad/ModoEsquemaPendiente.cs:34-75`). Reportes no tiene un control equivalente. El validador propuesto devuelve todos los claims (`LEEME-enganche-principal.md:37`) y `AutenticacionIntrospeccion.cs:35-41` crea la identidad sin mirarlos, de modo que ese token tendría en reportes todo lo que la política por omisión permita. Hoy el riesgo está **latente**: no hay rutas con datos (`Program.cs:48-50`) y las credenciales de lectura responden 503 (`Program.cs:33-34`). Pasa a ser real con la primera ruta de datos. Además, `ClaimsSesion` no declara ese claim (`ClaimsSesion.cs:8-21`).
- **Remediación (pregunta a):**
  1. El validador de la principal devuelve `Invalido` con un motivo nuevo, `ProtocoloIntrospeccion.MotivoEsquemaPendiente = "esquema_pendiente"`.
  2. Reportes traduce ese motivo a **503 `ESQUEMA_PENDIENTE`**, el mismo código que la principal, sin `X-GPOS-Sesion` y nunca como 401, que cerraría la sesión.
  3. Como defensa en profundidad, `AutenticacionIntrospeccion` también rechaza cualquier conjunto de claims que traiga `ClaimsSesion.EsquemaPendiente = "1"`.
  - Pruebas: una en `GPOS.Reportes.Tests` (servidor que acepta un token con el claim, que debe dar 503) y otra en `GPOS.Tests` con el validador real.
  - Esfuerzo: unas 0,25 días.

### S15-02 · Media · Identidad de la principal sin definir; no se rechazan cuentas compartidas
- **Riesgo.** Lo que impide suplantar al servidor es que solo la cuenta de la principal puede crear instancias (`ServidorIntrospeccion.cs:95`) y que el cliente exige que esa cuenta sea la dueña (`VerificadorIntrospeccion.cs:113-120`). Las dos defensas valen lo mismo que la exclusividad de esa cuenta.
  - Si la principal corre como `LocalSystem`, `NETWORK SERVICE`, `LOCAL SERVICE` o una cuenta de dominio compartida, cualquier otro servicio con esa cuenta puede crear una instancia de la canalización y pasar la comprobación del dueño.
  - Con eso recibiría los tokens de los usuarios y podría reutilizarlos contra la principal durante su vigencia. También podría responder "válido" con claims falsos, por ejemplo de nivel SUPER, a reportes.
  - `CuentaServicioVirtual.Resolver` acepta cualquier SID o cuenta (`CuentaServicioVirtual.cs:32-39`). Ni `Program.cs:55-63` (reportes) ni `ServidorIntrospeccion.cs:69` (principal) rechazan los SID compartidos o de grupo.
  - En `f21b788` no está definido cómo corre la principal en producción: `AddWindowsService` no aparece en `src`, y `docs/operaciones/2026-09-29-deshabilitar-sa-crear-gsf.md:250,643` menciona IIS.
- **Remediación (pregunta c):** la propuesta está en la sección 6. En código, fuera de desarrollo, `CuentaServidor` (reportes) y `CuentaCliente` (principal) solo aceptan SID `S-1-5-80-*` (servicio) o `S-1-5-82-*` (grupo de aplicaciones de IIS). Rechazan al arrancar `S-1-5-18/19/20`, `S-1-1-0`, `S-1-5-11`, `S-1-5-32-*` y los SID de dominio. Esfuerzo: unas 0,25 días de código; el instalador corresponde a devops.

### S15-03 · Media · Sin reintento si no se puede crear la canalización
- **Riesgo.** Si la creación falla, `EjecutarAsync` lo registra y relanza la excepción (`ServidorIntrospeccion.cs:75-82`), y `TrabajoIntrospeccion` la descarta sin reintentar (`LEEME-enganche-principal.md:68-74`). Esto pasa en varios casos:
  - con el reciclado solapado de IIS, porque el proceso nuevo arranca mientras el viejo sigue dueño del nombre y `FirstPipeInstance` falla;
  - si un proceso anterior tarda en terminar;
  - si otro proceso ocupó el nombre un momento.

  En todos, reportes responde 503 **indefinidamente**, hasta el siguiente reinicio de la principal. Falla cerrada, así que no hay riesgo de confidencialidad, pero un ocupante momentáneo del nombre obtiene una denegación de servicio duradera.
- **Remediación.**
  - En `TrabajoIntrospeccion`, un bucle de reintento con espera creciente de 1 a 60 s, que registre un `Critical` limitado (uno por minuto).
  - Mostrar el estado de la introspección en la salud de la principal.
  - Si la principal corre en IIS, `disallowOverlappingRotation=true` en su grupo de aplicaciones.
  - Esfuerzo: unas 0,25 días.

### S15-04 · Media · Sin limitación ni prevalidación antes de la introspección
- **Riesgo.**
  - Cada petición anónima con un `Bearer` arbitrario de hasta 8 KB provoca una pregunta por la canalización (`VerificadorIntrospeccion.cs:60-65`).
  - Los resultados negativos se guardan en la misma caché que los positivos. Al llegar a 10 000 entradas en 15 s se purgan las vencidas y, si no basta, se vacía todo (`VerificadorIntrospeccion.cs:68-79`), con lo que salen también las sesiones legítimas.
  - Reportes no registra `AddRateLimiter` (`Program.cs:20-36`), a diferencia de la principal (`f21b788:src/GPOS.Api/Program.cs:51`).
  - El servidor atiende 4 instancias a la vez (`ServidorIntrospeccion.cs:23`). Con más de 4 conexiones simultáneas, las demás esperan hasta 2 s (`MsConexion`) y después responden 503.
  - **Inferido, sin medición:** la validación HS256 de un token falso es barata, así que el límite está en el canal y no en la CPU. Hoy la escucha está solo en *loopback*, lo que reduce la exposición hasta que se publique reportes.
- **Remediación.**
  1. Prevalidación local barata: 3 segmentos base64url y encabezado `alg=HS256`. Si no cumple, `Invalido` sin preguntar ni guardar en caché.
  2. Caché negativa separada con un tope menor (por ejemplo, 1 000) que nunca expulse entradas positivas.
  3. `AddRateLimiter` por IP para los 401, con los mismos valores de `GPOS:Limites` de la principal.

  Esfuerzo: unas 0,5 días.

### S15-05 · Media · ADR-76 (PA-76-1): sin autocomprobación de privilegios en `GPOS.Reportes`
- **Riesgo.** PA-76-1 extiende ADR-76 a todo servicio de Windows nuevo de GSF. `GPOS.Reportes` es nuevo y su `Program.cs:9-17` no lee los privilegios del token ni deja de arrancar si sobran (punto 4 de ADR-76). Si el instalador no declara `RequiredPrivilege`, el proceso hereda `SeImpersonatePrivilege` por el grupo `SERVICE`. ADR-109 («Consecuencias») acepta que Razor del SUPER corra en este proceso, así que una ejecución de código ahí tiene la vía conocida hacia SYSTEM. El cliente sí se conecta con `Identification` (`VerificadorIntrospeccion.cs:87-88`), así que la principal no puede actuar en nombre de reportes. Eso está bien.
- **Remediación.**
  - Autocomprobación al arrancar con la lista mínima (`SeChangeNotifyPrivilege`) y evento `ARRANQUE_PRIVILEGIOS`. Unas 0,1 días.
  - `RequiredPrivilege` en `instalador/Reportes` (devops), con la verificación `sc qprivs`.
  - La principal tampoco necesita `SeImpersonatePrivilege` para `RunAsClient` en el nivel de identificación. Conviene incluirlo en su lista cuando se defina su servicio.

### S15-06 · Baja · Ventana de revocación de 15 s
- **Riesgo.** La principal aplica de inmediato la revocación hecha en su propio proceso (`f21b788:src/GPOS.Api/Seguridad/RevocacionSesiones.cs:49-54`). Reportes, en cambio, sigue aceptando el token guardado en caché hasta 15 s (`VerificadorIntrospeccion.cs:63`). Con varias instancias de la principal, la ventana llega a unos 30 s, porque se suman las dos cachés. La cláusula 6 de ADR-109 acepta este riesgo. El control compensatorio es la lectura de la sesión vigente en `rptsis` en cada petición (cláusula 6), y está pendiente (`AutenticacionIntrospeccion.cs:20`).
- **Remediación.** Ninguna en esta tanda. Es condición que la comprobación por `rptsis` esté lista antes de la primera ruta con datos. Una prueba debería verificar que una sesión cerrada en `rptsis` da 401 aunque el token siga en la caché.

### S15-07 · Baja · Reposición de instancias
- **Riesgo.**
  - Al fallar una conexión, primero se destruye la instancia y después se crea otra sin `FirstPipeInstance` (`ServidorIntrospeccion.cs:119-125`). Si caen todas a la vez, o con `Instancias=1`, el nombre queda libre un momento. Otro proceso podría crearlo y la principal se uniría a esa canalización o fallaría. El cliente lo detectaría por el dueño, así que el sistema sigue cerrado: el impacto es de disponibilidad.
  - Si `Crear` lanza una excepción en la línea 124, nada la captura. Esa instancia termina y `Task.WhenAll` (línea 85) solo lo deja ver cuando terminan todas, sin registro inmediato.
- **Remediación.**
  - Intentar `Disconnect()` y reutilizar la instancia. Solo si eso falla, recrearla.
  - Capturar y registrar como `Critical` el fallo de `Crear`.
  - Exigir `Instancias >= 2`.

  Esfuerzo: unas 0,25 días.

### S15-08 · Baja · Parámetros de validación duplicados
- **Riesgo.** El validador de ejemplo repite a mano los parámetros de `f21b788:src/GPOS.Api/Program.cs:59-63` (`LEEME-enganche-principal.md:23-27`), y ninguno de los dos fija `ValidAlgorithms`. Si un parámetro cambia en un lugar y no en el otro, reportes acepta lo que la principal rechaza. El riesgo práctico de la falta de `ValidAlgorithms` es bajo, porque con una llave simétrica hace falta la clave.
- **Remediación.** Un único `JwtOpciones.ParametrosValidacion()` con `ValidAlgorithms = [HS256]`, usado por `AddJwtBearer` y por `ValidadorTokenPrincipal`. Esfuerzo: unas 0,25 días.

### S15-09 · Baja · Pruebas solo con la misma cuenta (sospecha, sin verificar)
- **Riesgo.** En la prueba, la cuenta del cliente y la del dueño coinciden (`IntrospeccionCanalizacionTests.cs:17,59-63`). Faltan dos comprobaciones:
  - Que `RunAsClient` con `WindowsIdentity.GetCurrent(TokenAccessLevels.Query)` (`ServidorIntrospeccion.cs:173-177`) devuelva el SID de reportes cuando son dos cuentas virtuales con nivel de identificación.
  - Que `GetAccessControl()` funcione desde la cuenta de reportes (`VerificadorIntrospeccion.cs:115`).

  Si alguna falla, el resultado es un 503 permanente, no una apertura del acceso. Tampoco hay prueba del rechazo por identidad del lado del servidor (ACL alterada).
- **Remediación.** Una prueba elevada en una VM o un mini-PC con los dos servicios instalados. Casos: cuenta ajena, dueño ajeno, principal detenida y reciclado. Unas 0,5 días.

### S15-10 · Baja · Método distinto al de ADR-75
- **Riesgo.** ADR-75 verifica al servidor con `GetNamedPipeServerProcessId` y el SID del token del proceso. Aquí se usa el dueño del descriptor. Las dos formas son equivalentes frente a cuentas sin `SeRestorePrivilege` ni `SeTakeOwnershipPrivilege`, es decir, frente a todo lo que no es administrador, y la del dueño no exige que la principal conceda consulta sobre su proceso. La diferencia no está documentada.
- **Remediación.** Una nota en ADR-109 (cláusula 6) con la equivalencia y su límite: un administrador local queda fuera del modelo de amenaza, igual que en ADR-75. Unas 0,05 días.

### S15-11 · Baja · Algunas excepciones del cliente producen 500
- **Riesgo.** El filtro de `VerificadorIntrospeccion.cs:105-106` no incluye `NotSupportedException` (JSON), `Win32Exception` ni `InvalidOperationException`. Esas excepciones llegan a `ErroresReportes.cs:29` como 500 y se registran con la traza. El token no se acepta igualmente.
- **Remediación.** Capturar toda excepción que no sea una cancelación pedida por el usuario y convertirla en `PrincipalNoDisponibleException`. Unas 0,05 días.

## 4. Puntos del encargo verificados

| Punto | Resultado y evidencia |
|---|---|
| ACL solo para `NT SERVICE\GPOS.Reportes` | Sí. Lectura y escritura solo para el cliente (`ServidorIntrospeccion.cs:94`). La principal solo puede crear instancias (`:95`). No hay ACE para Everyone, Users ni Administrators. Prueba en `IntrospeccionCanalizacionTests.cs:153-166,210-226`. |
| Sin acceso por red | Sí. Hay una ACE que niega `NETWORK` (`ServidorIntrospeccion.cs:93`). No verifiqué si .NET 10 pone `PIPE_REJECT_REMOTE_CLIENTS` por omisión; la ACE cubre el caso. |
| `FirstPipeInstance` | Sí, en la primera instancia (`:73,101`). Prueba en `:182-192`. Ver S15-03 y S15-07. |
| Nadie más crea instancias ni suplanta | Sí, siempre que la cuenta de la principal sea exclusiva (S15-02). El cliente comprueba el dueño **antes** de enviar el token (`VerificadorIntrospeccion.cs:90-91`). |
| Identidad del cliente | Sí. `RunAsClient` y comparación del SID antes de leer el token (`ServidorIntrospeccion.cs:138-143`). Si falla o es anónimo, devuelve `null` y rechaza (`:179`). El cliente se conecta con `Identification` (`VerificadorIntrospeccion.cs:88`). |
| Falla cerrada | Sí. Si el validador lanza una excepción, se cierra sin responder (`ServidorIntrospeccion.cs:156-161`), lo que da 503 y no 401 (`AutenticacionReportesTests.cs:92-100`). Un "válido" sin claims da error (`VerificadorIntrospeccion.cs:93-94`). Un vencido se rechaza aunque la principal diga "válido" (`:66-67`). Los errores no se guardan en la caché. |
| Caché de 15 s por SHA-256 | Clave en hexadecimal sin el token en claro (`:61`). Expira por vigencia y por `exp` (`:63`), con tope de 10 000 entradas (`:32`). Revocación: S15-06. Tamaño y negativos: S15-04. |
| 503 sin filtrar información | Sí. Mensaje genérico y código `PRINCIPAL_NO_DISPONIBLE` (`IVerificadorToken.cs:23`, `ErroresReportes.cs:26`). El detalle de la suplantación solo va al registro (`VerificadorIntrospeccion.cs:117-119`). |
| Sin ruta HTTP de introspección ni `RemoteIpAddress` | Sí. Reportes solo mapea `/api/salud` (`Program.cs:49`). La LEEME no agrega rutas a la principal. No hay ninguna mención a `RemoteIpAddress`. |
| Registros sin tokens ni secretos | Sí. Los mensajes llevan solo la canalización, SID, ruta y código (`ServidorIntrospeccion.cs:78,83,122,141,159`; `VerificadorIntrospeccion.cs:108,117`; `ErroresReportes.cs:32-33`, que usa `Request.Path` sin la consulta). Las excepciones del protocolo solo citan largos. |
| Dependencias nuevas | `Microsoft.Extensions.Logging.Abstractions` 10.0.12 (`GPOS.Comun.csproj:12`) y `Microsoft.Extensions.Hosting.WindowsServices` 10.0.12 (`GPOS.Reportes.Api.csproj:14`). Son de primera parte y van alineadas con `GPOS.Api` (10.0.12). Fuera de S-15: ScriptDom 180.117.0 y SqlClient 7.1.0 en `GPOS.Reportes`. No tengo una herramienta de vulnerabilidades ejecutada. |
| ADR-41 | Se cumple: reportes no tiene la clave, ni `JwtBearer`, ni una sección `Jwt`. |
| Perfil FIPS | SHA-256 está aprobado. El SHA-1 de `CuentaServicioVirtual.cs:22` es la derivación fija del SID de servicio de Windows, sin función de seguridad, la misma que acepta ADR-75. Debe anotarse en el inventario criptográfico como uso no criptográfico, igual que el MD5 de Drive. No es un hallazgo. |

## 5. Controles bien implementados

- La canalización se protege con una ACL de mínimo privilegio, con la red negada y `FirstPipeInstance`, y el cliente comprueba el dueño antes de enviar el primer byte. Es el patrón correcto contra la ocupación previa del nombre.
- El cliente se conecta en el nivel de identificación, así que la principal no puede actuar como reportes.
- La identidad del cliente se comprueba de nuevo en el servidor, como defensa en profundidad.
- Falla cerrada en todo el camino. Un error nunca se convierte en 401 ni en "válido".
- Protocolo acotado: largo prefijado, topes de 16 y 64 KB, versión y 5 s por solicitud.
- Política de autorización por omisión que exige sesión (`ServiciosSeguridadReportes.cs:16-17`).
- `Server` sin encabezado de servidor y `appsettings.Development.json` fuera del paquete.
- El arranque falla fuera de desarrollo si falta `CuentaServidor` (`Program.cs:59-60`). En desarrollo mal configurado en producción, el dueño no coincide y el sistema falla cerrado.

## 6. Recomendaciones sobre las tres preguntas de B

**(a) Token del modo limitado en reportes: no se acepta.** El detalle está en S15-01: lo rechaza la principal con el motivo `esquema_pendiente`, reportes responde 503 `ESQUEMA_PENDIENTE` (no 401) y, además, comprueba el claim por su cuenta. Motivo: el modo limitado niega todo por omisión y existe para aplicar el esquema, y sin esquema no hay vistas que leer.
- *Alternativa descartada:* aceptarlo y copiar en reportes la lista blanca de `ModoEsquemaPendiente`. Duplica la lógica sin ningún caso de uso.

**(b) La principal pasa a `GPOS.Comun.Sesion.ClaimsSesion`: sí, al unir.**
- `ClaimsSesion` reúne los claims **del token**: `sub`, `name`, `nivel`, `empresa`, `empresa_desc`, `sucursal`, `sid`, `cambiar_clave` y el nuevo `esquema_pendiente`, además del encabezado `X-GPOS-Sesion`.
- `permiso` y `acceso` se quedan en `GPOS.Api.Seguridad.Claims`, porque los agrega `TransformacionPermisos` y no viajan en el token (`f21b788:src/GPOS.Api/Seguridad/Seguridad.cs:35-38`).
- `RevocacionSesiones.Valor*` debe usar las constantes `ProtocoloIntrospeccion.Motivo*`.
- Una prueba de arquitectura impide volver a declarar esos nombres en `GPOS.Api`.
- Esfuerzo: unas 0,25 días (41 usos de `Claims.` en `GPOS.Api`, `f21b788`).
- *Alternativa descartada:* mantener la copia con una prueba de igualdad. Deja dos fuentes de verdad.

**(c) Cuenta de servicio de la principal (`GPOS:Introspeccion:CuentaServidor`).**
- **Sin valor por omisión en el código.** Se mantiene que el arranque falle fuera de desarrollo (`Program.cs:59-60`). Un valor por omisión equivocado daría un 503 silencioso o, si fuera una cuenta compartida, una protección ilusoria.
- **Identidad de la principal:**
  - si corre como servicio de Windows, la cuenta virtual exclusiva `NT SERVICE\GPOS.Api`, coherente con ADR-75 y ADR-76;
  - si corre en IIS, un grupo de aplicaciones exclusivo `IIS APPPOOL\GPOS.Api` sin rotación solapada (S15-03);
  - nunca `LocalSystem`, `NETWORK SERVICE`, `LOCAL SERVICE` ni una cuenta de dominio compartida (S15-02).
- **Configuración sin secretos en el repositorio.** El SID no es un secreto.
  - El instalador de reportes (devops) escribe el **SID** (`S-1-5-80-…` o `S-1-5-82-…`, no el nombre, para evitar la traducción por nombre) en el `appsettings.json` del sitio.
  - Lo obtiene de la identidad real de la principal (`sc showsid GPOS.Api` o el SID del grupo de aplicaciones).
  - El archivo tiene una ACL que deja escribir solo a los administradores y leer a `NT SERVICE\GPOS.Reportes`.
  - En el repositorio se queda el valor vacío (`appsettings.json:19`).
- **Lado de la principal.** `CuentaCliente` conserva su valor por omisión y, fuera de desarrollo, solo acepta `S-1-5-80-*`. En desarrollo, la cuenta del programador va en `appsettings.Development.json`, que no se publica.

## 7. Remediaciones priorizadas

1. **Al unir el enganche:** S15-01, S15-02 (código), S15-08 y S15-11. Unas 0,8 días.
2. **Antes de producción:** S15-03, S15-05 (autocomprobación más el instalador), S15-07 y S15-09 (prueba elevada). Unas 1,1 días.
3. **Antes de exponer reportes fuera del equipo:** S15-04. Unas 0,5 días.
4. **Con las vistas `rptsis`:** S15-06 (condición). **Documentación:** S15-10.

## 8. Recomendación

**Aprobado con observaciones**, como recomendación técnica pendiente de la firma del propietario. No hay hallazgos Críticos ni Altos. El diseño cumple la precisión de DR-04 / S-15 y ADR-41, y la falla cerrada es correcta.

## Supuestos
- No verifiqué que .NET 10 ponga `PIPE_REJECT_REMOTE_CLIENTS`; la ACE que niega `NETWORK` cubre el caso.
- Las cifras de esfuerzo son inferidas.
- No se ejecutaron pruebas ni una herramienta de vulnerabilidades.

## Entregas a otros agentes
- **devops:** escribir `CuentaServidor` en el instalador de reportes, con la ACL del archivo; `RequiredPrivilege` en `instalador/Reportes`; definir la identidad de servicio de la principal.
- **Equipo B / desarrolladores:** S15-01, S15-03, S15-04, S15-05, S15-07, S15-08 y S15-11.
- **qa-automatizado:** la prueba elevada de S15-09.
- **documentador-tecnico:** la nota de S15-10 en ADR-109 y la entrada de SHA-1 en el inventario criptográfico.

---
**Decisión del propietario (2026-10-08):** «Como recomiendas, apruebo las tres». (a) reportes **no** acepta el token del modo limitado (503 `ESQUEMA_PENDIENTE`); (b) la principal usa `GPOS.Comun.Sesion.ClaimsSesion` con prueba de arquitectura contra la duplicación; (c) la principal corre con identidad de servicio exclusiva, `CuentaServidor` sin valor por omisión, SID escrito por el instalador (solo `S-1-5-80-*`/`S-1-5-82-*` fuera de desarrollo). Veredicto S-15: Aprobado con observaciones.
