# Informe de seguridad: revisión final de la fase A de ADR-81 (T-r)

**Fecha:** 2026-10-16 · **Equipo:** C · **Rama:** `c/adr81-fase-a` @ `06b913c8` · **Árbol:** `GPOS-C-adr81-fase-a` · **Diff revisado:** `ce33b2a8..06b913c8` (184 archivos).
**Revisión de solo lectura:** no se editó código ni se ejecutaron pruebas. Los resultados de las pruebas que se citan son los del informe de QA de T-r.

**Referencias:**
- ADR-81 con las precisiones del 2026-10-16 (rama `origin/c/adr-precisiones-2026-10-16`, PR #53).
- Blueprints v3 (`docs/arquitectura/2026-10-10-adr81-fase-a-blueprint.md`), v4 y v4.1.
- Hoja `docs/decisiones/2026-10-16-preguntas-adr81-fase-a-v4.md`, con P-81A-15 a P-81A-17 firmadas en (a).
- Hojas del área común `traspasos/C/`.
- Mis revisiones anteriores de la vía (a′): diseño, código con su verificación y cliente.
- Informe de QA de T-r.

---

## 1. Alcance y superficie revisada

Fuera del alcance: la vía (a′) (J2-1 a J2-4, `RecuperacionFactorService`, `DesafiosRecuperacion` y P17), que ya tiene sus tres revisiones, todas «Aprobado con observaciones». Solo se comprobó cómo se integra con el resto.

**Superficie anónima**

| Ruta | Protección |
|---|---|
| `POST /api/auth/login` | Contraseña |
| `POST /api/auth/login/alta` (5.2) | Desafío |
| `POST /api/auth/login/factor` (5.3) | Desafío |
| `POST /api/auth/login/recuperacion/` (J2-1) | JWS más contraseña |
| `POST /api/auth/login/recuperacion/alta` (J2-2) | Desafío de recuperación |
| `POST /api/auth/login/recuperacion/confirmar` (J2-3) | Desafío de recuperación |

**Superficie autenticada nueva o modificada**
- `/reautenticar`, `/factor`, `/factor/codigos-respaldo`, `/factor/cambio` y `/factor/cambio/confirmar`.
- Las rutas `/api/super/*` de la fase A: 5.9, 5.10, 5.11 y J2-4.
- Las marcas de autenticación reciente en las rutas existentes de 5.5.
- El ciclo de vida del token en `OnTokenValidated` y en la introspección.

**Fuera de HTTP**
- `GPOS.Migracion restablecer-factor` (vía b).
- La purga diaria de la bitácora.
- `dbo.ReconciliarRestauracionSistema` v2.

**Clientes**
- Web: `AlmacenDesafiosWeb`, la cookie `GPOS.Factor`, `ApiClient` y `Clear-Site-Data`.
- MAUI: el token solo en memoria y `ApiClient`.

---

## 2. Resumen de hallazgos

| ID | Severidad | Título | Estado |
|---|---|---|---|
| SEG-FA-01 | **Media** | El refresco automático del Tablero cada 5 min cuenta como actividad: la sesión del SUPER no cierra por inactividad (CS-9) mientras el Inicio esté abierto | Verificado en el código; efecto inferido, no ejecutado |
| SEG-FA-02 | **Media** | `POST /api/admin/usuarios/{codigo}/inhabilitar` no exige la autenticación reciente que sí exige la misma acción por `POST /api/admin/usuarios` | Verificado |
| SEG-FA-03 | Baja | `GPOS:Sesion:HorasVigenciaSuper` no tiene tope: ADR-81, punto 14, fija «4 h como máximo» | Verificado |
| SEG-FA-04 | Baja | La vía (b) escribe la contraseña temporal en la salida estándar aunque esté redirigida a un archivo | Verificado |
| SEG-FA-05 | Baja | 5.2 y 5.3 son anónimas y no llevan `LimiteCuerpo`; J2-1 a J2-3 sí lo llevan | Verificado |
| SEG-FA-06 | Baja | La vía (b) no comprueba el perfil de la instalación: (b+) queda fuera de la fase A | Sospecha que requiere confirmación |
| SEG-FA-07 | Informativa | Los comprobantes y desafíos usados se recuerdan solo en memoria: un reinicio de la API permite volver a canjear un comprobante dentro de sus 5 min | Verificado |
| SEG-FA-08 | Informativa | `FiltroFactor` toma el nivel de la cuenta de la caché y no de la lectura que acaba de hacer `MotivoInvalidoAsync` | Verificado |
| SEG-FA-09 | Informativa | `Clear-Site-Data` solo con `"cache"`, cuando 8.6 del blueprint v3 pide también `"storage"`; la desviación está justificada | Verificado |
| SEG-FA-10 | Informativa | La liberación del candado sigue sin la clase `Esencial` que firmó P-81A-17 (a); la marca va en el PR #45 de A | Verificado |

**Sin hallazgos Críticos ni Altos.**

---

## 3. Checklist OWASP Top 10 (2021)

| # | Categoría | Resultado | Evidencia principal |
|---|---|---|---|
| A01 | Control de acceso | Cumple, con SEG-FA-02 | `FiltroFactor.cs:24-51` y su lista cerrada (4 rutas `PermitidaSinFactor`: `AuthEndpoints.cs:122,126` y `AuthEndpoints.SegundoFactor.cs:150,172`). Vía (a): actor SUPER según la base (`SegundoFactorService.cs:441-449`). 5.11 con `RequiereSuper` (`AdminEndpoints.cs:345-354`). Datos del factor en la lista de usuarios solo para el SUPER (`UsuariosService.cs`, `ListarAsync`) |
| A02 | Criptografía | Cumple | HMAC con `FixedTimeEquals` (`Totp.cs:54`). Secreto de 160 bits (`GeneradorSecretos.cs:16`). Data Protection con propósito más usuario (`SegundoFactorService.cs:477`). PBKDF2 V3 de Identity con el costo de las contraseñas (`CodigosRespaldo.cs:17-18`). Desafíos y comprobantes con `ITimeLimitedDataProtector` (`DesafiosFactor.cs:37-38`) |
| A03 | Inyección | Cumple | Todo el SQL de la fase A va con parámetros de tipo y largo (`ConsultasSegundoFactor.cs`, `ConsultasBitacoraSeguridad.cs`). Las cadenas que entran en la bitácora se recortan y se tipan (`BitacoraSeguridad.cs:53-58`). Blazor codifica la salida |
| A04 | Diseño inseguro | Cumple, con SEG-FA-01 y SEG-FA-06 | SF-03: el 409 solo sale después del factor (`AuthEndpoints.SegundoFactor.cs:77-78`; PF-17). La reconciliación v2 es idempotente por fork (`EsquemaSegundoFactor.cs:148-177`) |
| A05 | Configuración | Cumple, con SEG-FA-03 | `ExigirSuper` obligatorio en Release (`ValidadorTokenPrincipal.cs:63-80`). Tope de 60 min de inactividad (`OpcionesSesion.cs:25-31`). `no-store` (`AutenticacionReciente.cs:50-65`; `Program.cs` de la Web, `/cuenta/*`) |
| A06 | Componentes vulnerables | No aplica | El diff no agrega paquetes de NuGet al servidor. Sin herramienta de vulnerabilidades en esta revisión |
| A07 | Identificación y autenticación | Cumple | Ventana de ±1 (`PoliticaFactor.cs:332`). Paso de un solo uso (`ConsultasSegundoFactor.cs:68-71`). Bloqueo progresivo en una sentencia (`:86-95`). 10 por minuto y usuario (`DesafiosFactor.cs:57,82-89`). CS-1, CS-2 y CS-12 (`RevocacionSesiones.cs:158-168`). Autenticación reciente C-3 (`AutenticacionReciente.cs:76-91`) |
| A08 | Integridad de software y datos | Cumple | `UltimoPaso` y los códigos se protegen en la base con `UPDLOCK` y `UPDATE` condicionales. La bitácora solo admite inserciones (A, I-10). Guarda de la versión de la reconciliación (`EsquemaSegundoFactor.cs:144-183`) |
| A09 | Registro y monitoreo | Cumple | Catálogo de eventos de 4.4. Limitador D81-10 (`BitacoraSeguridad.cs:116-134`). Purga con el candado considerado (`TrabajoPurgaBitacoraSeguridad.cs:176-195`). Cero secretos en los registros (PF-24 de QA, 4742 líneas de nivel Trace) |
| A10 | SSRF | No aplica | Ninguna ruta nueva hace peticiones salientes |

---

## 4. Revisión por punto del encargo

### 4.1 Cálculo TOTP — cumple
- **Tiempo constante:** se recorre toda la ventana aunque ya haya coincidido, y la comparación es con `FixedTimeEquals` (`Totp.cs:50-56`). El HMAC y el esperado se borran (`:57`, `:86`). Un código mal formado sale antes de calcular, pero eso no revela nada secreto.
- **Ventana de ±1:** `PoliticaFactor.Ventana = 1` (`PoliticaFactor.cs:332`). La entrada se valida: entre 0 y 10 pasos y con 6 u 8 dígitos (`Totp.cs:42-43`).
- **Un código no se usa dos veces:** el paso se rechaza en memoria si es menor o igual que `UltimoPaso` (`Totp.cs:55`) y otra vez en la base, con `UltimoPaso < @paso` (`ConsultasSegundoFactor.cs:68-71`). Si el `UPDATE` no afecta ninguna fila, cuenta como fallo (`SegundoFactorService.cs:223-224`). Las peticiones del mismo usuario se serializan con `UPDLOCK` (`ConsultasSegundoFactor.cs:22`). La confirmación del alta fija `UltimoPaso` (`:47-53`), así que el código del alta no sirve para entrar.
- **Deriva del reloj:** primero el reloj protegido y, solo si difiere en al menos un paso, el del sistema, con `DERIVA_RELOJ` (`SegundoFactorService.cs:420-429`, `:202`, `:228`). Es la decisión firmada P-81A-02. Con los dos relojes desfasados, la ventana efectiva llega a 6 pasos; está aceptado y queda registrado.
- **Bloqueado no calcula:** `SegundoFactorService.cs:163-164` (I-4).
- **Códigos de respaldo:**
  - 10 de 60 bits cada uno (`CodigosRespaldo.cs:123-141`);
  - PBKDF2 con `PoliticaClaves.IteracionesHash` (`:17-18`);
  - se recorren todos los sin usar, así que el tiempo no dice cuál coincidió (`SegundoFactorService.cs:243-244`);
  - un solo uso, con `UsadoUtc IS NULL` (`ConsultasSegundoFactor.cs:74-76`);
  - comparten el contador de bloqueo.

  PF-12 midió 1,15 s como máximo para 10 PBKDF2. La amplificación de CPU exige tener la contraseña y está acotada por los cupos.

### 4.2 El secreto — cumple
- **Protección:** cifrado con Data Protection, propósito `GPOS.Usuarios.SegundoFactor.v1` más el código del usuario (`SegundoFactorService.cs:90`, `:126`, `:477`). Va a `varbinary` (`EsquemaSegundoFactor.cs:41,43`). El texto claro se borra después de usarlo (`:120`, `:140`, `:193`, `:221`). Si no se descifra, se registra `FACTOR_SECRETO_ILEGIBLE` y no cuenta como fallo (`:212-217`).
- **URI y QR en el servidor:**
  - el URI se arma en `UriOtpAuth.Crear` (`UriOtpAuth.cs:299-307`);
  - la Web genera el QR en el servidor (`VistaSegundoFactor.Qr`, desde `FactorAlta.razor:146`, `DialogoCambioTelefono.razor:132` y `Recuperacion.razor:234`) y lo entrega como PNG en un data URI;
  - el texto alternativo no lleva el secreto (`VistaCodigoQr.razor:10`);
  - en la Web, el alta vive solo en la memoria del servidor (`AlmacenDesafiosWeb.cs:31-33`);
  - en MAUI, solo en la memoria del proceso (`InicioSesionFactor.cs:43`; `MauiProgram.cs:43-46`).
- **Ningún registro:** las llamadas a `Log*` nuevas solo llevan el usuario y los contadores (por ejemplo, `AuthEndpoints.SegundoFactor.cs:60`). La API no usa `HttpLogging`. QA (PF-24) buscó 60 valores en el registro de nivel Trace, en los cuerpos de error, en `BitacoraSeguridad`, en `Usuarios` y en las tablas del factor: **cero apariciones**.

### 4.3 Inicio de sesión en dos pasos y SF-03 — cumple

**Comprobante v2 y sesión única**
- El 202 sale antes de la regla de la sesión única (`AuthEndpoints.cs`, cuerpo de `/login`: `comprobante is null && RequiereFactor(u, factor)` → 202).
- El 409 solo sale en `/login/factor`, después de verificar el código y consumir el desafío (`AuthEndpoints.SegundoFactor.cs:67-78`).
- El comprobante:
  - es de un solo uso (`DesafiosFactor.cs:53`, `Usar("c:"…)`);
  - vence a los 5 min (`:29`);
  - está cifrado y autenticado con Data Protection;
  - está ligado al sello de la cuenta;
  - no se acepta sin `otp` en una cuenta que requiere el factor (`AuthEndpoints.cs`, condición `RequiereFactor(u, factor) && !comprobante.Amr.Contains(MetodoOtp)`);
  - la empresa y la sucursal salen del comprobante, no de la petición.
- El desafío se invalida si cambia el sello (`AuthEndpoints.SegundoFactor.cs:31`, `:68`). Así, un restablecimiento por la vía (a) en medio del inicio de sesión lo anula. El desafío solo se consume con un acierto. Los intentos fallidos los acotan el cupo de 10 por minuto y el bloqueo cada 5 fallos.

**`FiltroFactor`: lista cerrada**
- Solo cuatro rutas llevan `PermitidaSinFactor`: `/salir`, `/sesion`, `/reautenticar` y `GET /factor` (grep de `PermitidaSinFactor()` en `src`). PF-42 vigila la lista.
- El filtro va después de la autorización y antes de la autenticación reciente y del cambio de clave (`Program.cs` de la API, `UseFiltroFactor` → `UseAutenticacionReciente` → `UseCambioClaveObligatorio`).
- Compara el nivel del token **o** el de la cuenta (`FiltroFactor.cs:21-22`; `Program.cs:97-100`). Detalle en SEG-FA-08.

**`/reautenticar` y C-3**
- Cupo de 10 por minuto y usuario (`AuthEndpoints.SegundoFactor.cs:90`).
- Un código revivido exige la contraseña, que se decide por la marca de la cuenta y no es un oráculo (`SegundoFactorService.cs:237-238`). La contraseña cuenta en CS-5 (`:93-108`).
- El token nuevo trae `amr` más `otp`, `auth_time = ahora`, el mismo `sid` y un `jti` nuevo (`:143-146`).
- El tope CS-10 se conserva: `RenovarAsync` pasa `u.SesionInicio`.
- La autenticación reciente responde 401 `REAUTENTICAR` sin `X-GPOS-Sesion` (`AutenticacionReciente.cs:76-91`).
- La lista de 5.5 está completa en las 15 rutas marcadas, salvo SEG-FA-02.

**`no-store` (C-2)**
- Middleware para las respuestas autenticadas y para `/api/auth/*` (`AutenticacionReciente.cs:110-126`; `Program.cs`, `app.UseSinCache()`).
- Encabezados explícitos en las rutas `/api/super/*` del factor y de la restauración.
- En la Web, `/cuenta/*` (`Program.cs` de la Web, el bloque C-2).

### 4.4 Ciclo de vida de los tokens — cumple, con SEG-FA-01 y SEG-FA-03

| Control | Evidencia | Resultado |
|---|---|---|
| CS-1 (sello) | `Seguridad.cs`: sin sello no hay token; claim `sst`. `RevocacionSesiones.cs:165` | Cumple |
| CS-2 (`jti` vigente) | `RevocacionSesiones.cs:167`. `UsuariosService.RenovarSesionAsync` actualiza `SesionTokenId` | Cumple |
| CS-4 (operación única) | `UsuariosService.InvalidarCredencialesAsync`; `ConsultasSegundoFactor.cs:101-104` (vías a y b); cambio de teléfono (`AuthEndpoints.SegundoFactor.cs:215-216`); «Forzar nuevo inicio» también renueva el sello | Cumple |
| CS-5 | `UsuariosService.ComprobarClaveActualAsync`: mismo contador; al bloquear, cierra la sesión | Cumple |
| CS-6 | `/clave` con `RequireRateLimiting(Clave)` (`AuthEndpoints.cs:185`) | Cumple |
| CS-9 (inactividad) | `RevocacionSesiones.cs:107-126`; `Program.cs:101-102` | Cumple en el servidor. **Lo anula el refresco del Tablero (SEG-FA-01)** |
| CS-10 (tope) | `EmisorTokens.Emitir`: `inicioSesionUtc + horas`. Todas las renovaciones pasan `u.SesionInicio` | Cumple. **Sin tope de configuración (SEG-FA-03)** |
| CS-12 (token sin `sid` ni sello) | `RevocacionSesiones.cs:165`, `:174-176` | Cumple |
| Revocación | La revocación va antes que el sello (`:164`); la introspección la aplica igual (`ValidadorTokenPrincipal.cs:36-37`) | Cumple |
| `inactiva` y `renovada` | Valores en `RevocacionSesiones.cs:74-76`; mensajes en `Program.cs`. La Web y MAUI repiten una vez con `renovada` (`ApiClient.cs`, `ManejadorSesion`) | Cumple |

### 4.5 Restablecimiento de la cuenta — cumple, con SEG-FA-04 y SEG-FA-06

**Vía (a)**
- La ruta exige `RequiereSuper`, `otp`, autenticación reciente, cupo de 5 por minuto, motivo de 10 a 400 caracteres y `SoloCentral` (`AdminEndpoints.cs:383-398`).
- Nunca sobre sí mismo, y el actor debe ser SUPER según la base (`SegundoFactorService.cs:441-449`; I-9).
- Borra el factor (los códigos caen en cascada), renueva el sello, cierra la sesión, vuelve a sellar, registra el evento A y confirma (`:344-353`). La contraseña no cambia (I-8).

**Vía (b)**
- Sin contraseñas en la línea de comandos: la temporal la genera el comando con unos 115 bits (`RestablecimientoFactor.cs:116-124`), y la de `--login` se pide por la consola.
- Pide escribir otra vez el código para confirmar (`GPOS.Migracion/Program.cs:331-337`).
- Guarda del anillo contra `Licencia.InstalacionId` antes de la transacción (`RestablecimientoFactor.cs:58`, `:82-94`).
- Solo cuentas SUPER habilitadas (`SegundoFactorService.cs:325-327`).
- En una transacción: contraseña temporal con «Debe cambiar», borrado del factor, sello nuevo, sesión cerrada y nuevo sellado (`:328-331`).
- El actor queda con la cuenta de Windows, su SID y el equipo (`RestablecimientoFactor.cs:97-108`).

**Sello (`ISelladoCuenta`)**
- Se llama dentro de la transacción, antes del evento, en la confirmación del alta, en el cambio de teléfono y en las vías (a) y (b) (`SegundoFactorService.cs:200`, `:349`). `DespuesDeConfirmarAsync` va fuera.
- Hoy es `SelladoCuentaNulo` (`ISelladoCuenta.cs:24-28`; registrado en `Program.cs`). El enganche cumple P-81A-15 (a); falta la integración con SL de A (DC-10). Ver el riesgo residual RR-1.

### 4.6 Bitácora — cumple
- **Limitador:** como mucho un evento por minuto, evento y usuario (`BitacoraSeguridad.cs:116-134`). Se aplica solo a los eventos de `EventosSeguridad.Limitados`. Un tercero solo puede provocar los demás teniendo ya la contraseña o el token, con cupos.
- **Purga:** diaria y con desplazamiento aleatorio. Se omite con el candado activo, o con su estado sin conocer, porque arranca activo (`TrabajoPurgaBitacoraSeguridad.cs:176-182`). El corte lo calcula la base: 2 años y 1 día, en lotes de hasta 4000 (`EsquemaSegundoFactor.cs:128-140`). La API solo tiene `EXECUTE` (`:198`).
- **Consulta 5.11:**
  - solo el SUPER, con `otp` por `FiltroFactor`;
  - rango de 92 días como máximo y páginas de 1 a 200, validados (`BitacoraSeguridad.cs:65-84`);
  - filtros con parámetros y `no-store`;
  - sin exportación.
- **Sin datos sensibles:** `Detalle` lleva el paso relativo y el reloj, el método y la ruta (sin la consulta), los forks o la credencial de SQL (el login, nunca la contraseña). Cero secretos (PF-24). La IP se guarda 2 años, que es la retención firmada en ADR-81, punto 12. Es un dato personal: debe quedar en el aviso de privacidad del cliente (Ley 172-13).

### 4.7 Restauración con la reconciliación v2 — cumple
`EsquemaSegundoFactor.cs:148-177`:
- **Una vez por fork** (I-13), con `UPDLOCK, HOLDLOCK`.
- **Sello nuevo de todas las cuentas**, con `CRYPT_GEN_RANDOM` por fila (`:163-164`), más `SesionId` y `SesionTokenId` a NULL y `SesionesRevocadas = ahora`.
- **`UltimoPaso`** se adelanta al paso de la hora de la base menos uno (`:165-167`).
- **`CodigosRevividos = 1`** en todo factor activo con códigos sin usar (`:168-169`).
- **Evento** `SISTEMA_RESTAURADO`.
- **Guarda de versión** (`:144-146`, `:178-182`): la versión 1 de A no la reemplaza.

QA comprobó los recorridos S1, S3, S4, S5, S7, S8 y S10, y PF-40: el candado rigió a los 6,4 a 8,0 s de restaurar sin detener la API.

### 4.8 Clase de licencia (T-m) — cumple, con SEG-FA-10
- Las siete rutas `Esencial` nuevas de `RutasLicenciaAprobadas.json` coinciden con P-81A-17 (a), firmada, y con P-TJ2-02 (a), firmada, para el acuse J2-4: reautenticar, códigos, cambio, confirmar el cambio, restablecer, desbloquear y acuse.
- **Nada sensible queda `Esencial` sin firma:** las consultas (`GET /factor`, 5.11 y 5.14.1) quedan como consulta, y las anónimas no pasan por la licencia.
- La ruta que P-81A-17 (a) también incluye, la liberación, todavía no está marcada (SEG-FA-10).
- `UseLicencia` todavía no está activo en `Program.cs`. Hoy no tiene efecto.

### 4.9 D-01 del informe de QA: las 5 rutas anónimas — **confirmado**
Las cinco son anónimas por diseño y cada una exige su propio artefacto:

| Ruta | Artefacto exigido | Evidencia |
|---|---|---|
| 5.2 `/login/alta` | Desafío de `GPOS.Auth.SegundoFactor.v1`, que solo se obtiene con la contraseña correcta, más el sello vigente, la cuenta habilitada y el cupo por usuario. Con el factor activo, 409 | `AuthEndpoints.SegundoFactor.cs:28-34` |
| 5.3 `/login/factor` | El mismo desafío, más el código | `:44-47` |
| J2-1 | JWS de GSF más la contraseña | Mis revisiones de T-j2 |
| J2-2 y J2-3 | Desafío de recuperación con propósito propio, comprobado en la base | `RecuperacionFactorEndpoints.cs:73-77`, `:95-98` |

- Ninguna emite un token sin el factor.
- Todas llevan el cupo `login` por IP y `PermitidaConCandado(Ambos)`, que es lo correcto por I-15.
- La lista actualizada de `QaOla4HttpTests.cs` es la correcta.
- Nota O-1 de QA: la barra final de J2-1 (`/recuperacion/`) es inocua para la seguridad.

### 4.10 `ExigirSuper` obligatorio en Release — cumple
`OpcionesSegundoFactor.Resolver` (`ValidadorTokenPrincipal.cs:63-80`):
- en Release, sin valor, vale `true`;
- con un valor que no da `true` (`false`), lanza la excepción y la API no arranca;
- un valor que no es booleano también falla al enlazar.

`Release` es una constante de compilación (`#if DEBUG`), no de configuración. La resolución se usa en `Program.cs` (`AddSingleton(OpcionesSegundoFactor.Resolver(config, OpcionesSegundoFactor.Release))`). La API de reportes recibe `ExigeOtpSuper`. Prueba `V4_15_ExigirSuper_es_obligatorio_en_Release`: verde, según QA.

### 4.11 Web y MAUI — cumple, con SEG-FA-09

**MAUI: el token solo en memoria**
- `Sesion.cs:6-9` y `MauiProgram.cs:43-46`.
- Un grep de `SecureStorage` y `Preferences.Set/Get` en `GPOS.UI.MAUI` solo encuentra comentarios.

**`Clear-Site-Data`**
- `"cache"` al salir (`Program.cs` de la Web, `:160`). Ver SEG-FA-09.

**Cookie `GPOS.Factor`**
- `HttpOnly`, `SameSite=Strict`, `Path=/cuenta` y `Secure` con HTTPS (`InicioSesionWeb.cs:82-90`).
- Valor de 256 bits aleatorios (`AlmacenDesafiosWeb.cs:196`).
- El desafío, el alta, los códigos y el comprobante quedan en la memoria del servidor web, con vencimiento (`AlmacenDesafiosWeb.cs:101-205`).
- Una observación informativa: después del código, la entrada guarda el `LoginResponse` hasta 30 min (`:145`), así que la cookie del paso equivale en ese tiempo a una credencial de sesión. Tiene la misma protección que `GPOS.Sesion` y no hace falta cambiarla.

**El 401 `factor` no cierra la sesión**
- `ApiClient.cs`, `ManejadorSesion`: «factor» y `REAUTENTICAR` abren P6 y repiten la petición una sola vez.
- `renovada` repite con el token vigente.
- Un 401 `factor` repetido cierra la sesión con `definitiva` (5.15).
- Las rutas de la sesión y del factor nunca abren el diálogo.
- Los 401 propios del factor (código erróneo) no cierran la sesión (`CodigoFactorAsync`).
- PF-41: verde, según QA.

---

## 5. Hallazgos

### SEG-FA-01 (Media): el refresco del Tablero mantiene viva la sesión del SUPER

- **Riesgo.** El Tablero del Inicio vuelve a pedir indicadores, avisos y reportes cada 5 minutos mientras la pantalla esté abierta, en la Web y en MAUI. La API cuenta como actividad (CS-9) toda petición válida, salvo `GET /api/auth/sesion`.
  - **Consecuencia:** un SUPER que deja el Inicio abierto no llega nunca a los 30 min de inactividad de ADR-81, punto 14. Su sesión sigue utilizable hasta el tope de 4 h.
  - **Aviso del cliente:** el aviso de 2 min antes (UX-81A-04) tampoco aparece, porque `ApiClient` anota la misma actividad.
  - **Qué reduce el impacto:** quien llegue a un equipo desatendido no puede hacer ninguna acción de 5.5 sin el teléfono, porque `auth_time` vence a los 5 min. Sí puede hacer todo lo demás: consultar, operar y la administración que no está en la lista (ver SEG-FA-02).
  - Afecta igual a los demás usuarios (120 min).
- **Evidencia:**
  - `src/GPOS.Web/Components/Compartidos/Tablero.razor:118`, `:122-131` (`PeriodicTimer` de 5 min que llama a `CargarAsync`);
  - lo mismo en `GPOS.UI.MAUI/Components/Compartidos/Tablero.razor:118`, `:122-131`;
  - la única excepción del servidor: `src/GPOS.Api/Program.cs:101-102`;
  - la anotación: `src/GPOS.Api/Seguridad/RevocacionSesiones.cs:117-126`;
  - la introspección también anota (`ValidadorTokenPrincipal.cs`, «CS-9: usar la API de reportes también es actividad»).
  - **Inferido, no ejecutado:** no hay ninguna prueba con el Tablero abierto.
- **Remediación (la más barata, ≈ 0,1 sp):**
  1. El cliente marca las peticiones automáticas con un encabezado (por ejemplo, `X-GPOS-Automatica: 1`) desde el refresco del Tablero.
  2. `OnTokenValidated` y la introspección no llaman a `AnotarActividadAsync` cuando lo traen. Es el mismo criterio de `GET /api/auth/sesion`.
  3. `ManejadorSesion.Anotar` tampoco actualiza `UltimaActividadUtc`.

  El encabezado solo puede **quitar** actividad, nunca agregarla, así que un cliente malicioso no gana nada al enviarlo.

  Prueba: con un reloj falso, 31 min de refresco automático dan `inactiva`.
- **Alternativa descartada:** pausar el refresco cuando el navegador no tiene el foco. Depende de JavaScript y no cubre una pestaña visible en un equipo desatendido.

### SEG-FA-02 (Media): `inhabilitar` evita la autenticación reciente

- **Riesgo.** 5.5 marca «Crear o modificar un usuario» (`POST /api/admin/usuarios`) como acción sensible. Inhabilitar una cuenta por esa ruta exige `auth_time` de menos de 5 min. La ruta propia `POST /api/admin/usuarios/{codigo}/inhabilitar` produce **el mismo efecto** (inhabilita la cuenta, renueva el sello y cierra la sesión) **sin** la marca.
  - Con una sesión SUPER desatendida o un token robado con `otp`, se pueden inhabilitar en segundos los demás SUPER y ADMIN.
  - Eso deja sin la vía (a) a quien la necesite y obliga a la vía (b).
  - No es una escalada: es una negación de servicio que se puede revertir y queda auditada en la bitácora de la empresa.
- **Evidencia:** `src/GPOS.Api/Endpoints/AdminEndpoints.cs:263-283` (sin `.RequiereAutenticacionReciente()`), frente a `:209`.
- **Remediación (≈ 0,02 sp):** agregar `.RequiereAutenticacionReciente()` a `:283`. Para un ADMIN no cambia nada, porque la marca solo actúa con `otp`. Agregar la ruta a la prueba de la lista de 5.5.
- **Opcional, a decidir por el Arquitecto Maestro:** si `POST /api/admin/perfiles` y `DELETE /perfiles/{codigo}`, que cambian privilegios en bloque, deben entrar en la lista de 5.5. No es un hallazgo: la lista firmada no las incluye.

### SEG-FA-03 (Baja): la vigencia del SUPER no tiene tope

- **Riesgo.** ADR-81, punto 14, dice «sesión del SUPER de 30 min de inactividad (configurable hasta 60) y **4 h como máximo**». El código hace cumplir el tope de 60 min, pero `HorasVigenciaSuper` acepta cualquier valor de 1 en adelante. Un técnico que la ponga en 24 deja sin efecto CS-10 sin que nada lo advierta. Hace falta acceso de escritura a la configuración del servidor.
- **Evidencia:** `src/GPOS.Api/Seguridad/OpcionesSesion.cs:19`, `:25-31` (solo `< 1`).
- **Remediación (≈ 0,01 sp):** que `Validar` falle con más de 4, como ya hace `TopeMinutosInactividadSuper`, y una prueba unitaria.

### SEG-FA-04 (Baja): la contraseña temporal puede quedar en un archivo

- **Riesgo.** La vía (b) escribe la contraseña temporal con `Console.WriteLine`. Si el técnico ejecuta el comando con la salida redirigida, queda en texto plano en un disco. Pasa con `> salida.txt`, con una herramienta de soporte remoto que captura la salida o con un script que guarda los registros. Contradice «no se escribe en disco» (`RestablecimientoFactor.cs:27-28`) y el principio de ADR-44.
- **Evidencia:** `src/GPOS.Migracion/Program.cs:348`.
- **Remediación (≈ 0,02 sp):** si `Console.IsOutputRedirected`, no mostrarla y terminar con salida 1 antes de abrir la transacción, con el mensaje «ejecute el comando en una consola interactiva». La alternativa es escribirla directamente en la consola (`CONOUT$`). La comprobación debe ir **antes** del cambio, para no dejar una contraseña que nadie vio.

### SEG-FA-05 (Baja): 5.2 y 5.3 sin tope de cuerpo

- **Riesgo.** Son anónimas y deserializan JSON con el tope general de Kestrel (30 MB). Las rutas J2 y las del registro de dispositivos ya tienen su `LimiteCuerpo` (V-07). El cupo `login` de 20 por minuto e IP acota el abuso, pero cada petición puede obligar a leer 30 MB.
- **Evidencia:** `src/GPOS.Api/Endpoints/AuthEndpoints.SegundoFactor.cs:37`, `:81`, frente a `RecuperacionFactorEndpoints.cs:62,85,134`.
- **Remediación (≈ 0,01 sp):** `.LimiteCuerpo(4 * 1024)` en las dos rutas; el desafío más el código ocupan menos de 1 KB. Conviene hacer lo mismo en `/login`, que es anterior a la fase A.

### SEG-FA-06 (Baja, sospecha): la vía (b) no distingue el perfil Avanzada

- **Riesgo.** ADR-81, punto 7, exige en el perfil Avanzada que el comando lleve además una autorización firmada por GSF: es la vía (b+). La fase A la deja fuera (blueprint v3, §1.2) y el perfil no es seleccionable antes de la versión 1. Pero `Licencias.PerfilMin` ya existe y lo usa la vía (a′) (`ConsultasRecuperacionFactor.cs:103-107`). Si una licencia aceptada ya puede fijar `avanzado`, la vía (b) funcionaría en esa instalación sin (b+).
- **Evidencia:** `src/GPOS.Migracion/RestablecimientoFactor.cs:49-76`, sin ninguna comprobación del perfil.
- **Confirmación pendiente:** si alguna ruta de hoy puede dejar `PerfilMin = 'avanzado'` en producción.
- **Remediación (≈ 0,03 sp):** si puede, que la vía (b) se niegue (salida 2, sin cambios) con el perfil Avanzada mientras (b+) no exista, con el mensaje «use la vía (a) o (a′)». Si no puede, basta una prueba de arquitectura que falle el día que el perfil sea seleccionable.

### SEG-FA-07 (Informativa): lo usado se recuerda solo en memoria

- **Qué pasa:** `_usados` es de la instancia (`DesafiosFactor.cs:34`, `:53`, `:193-199`). Tras reiniciar la API, un comprobante v2 ya canjeado vale otra vez durante lo que le quede de sus 5 min. Con él se abriría otra vez la sesión y se reemplazaría la nueva.
- **Qué hace falta para aprovecharlo:** haber capturado el comprobante, que viaja solo entre la API y el servidor web o MAUI, y que el sello no haya cambiado. Con ADR-24 (un proceso por sitio) está aceptado.
- **Remediación, si se quiere:** renovar `SesionTokenId` o el sello al canjear, para que el comprobante no sirva dos veces. No hace falta para la unión.

### SEG-FA-08 (Informativa): el nivel de la cuenta en `FiltroFactor` sale de la caché

- **Qué pasa:** `Program.cs:97-100` usa `Guardada(token.Usuario)?.Nivel`. Si otra petición llamó a `Olvidar` justo entre la lectura y esta línea, la caché está vacía y el ADMIN recién ascendido pasa una petición con el nivel ADMIN de su token. Los permisos son los de ADMIN, así que no hay escalada.
- **Remediación sugerida:** que `MotivoInvalidoAsync` devuelva también la cuenta leída, para no depender de la caché.

### SEG-FA-09 (Informativa): `Clear-Site-Data` sin `"storage"`

- **Qué pasa:** 8.6 del blueprint v3 pide `"cache", "storage"`. El código envía solo `"cache"` y lo justifica: el almacenamiento local solo guarda preferencias. Lo verifiqué en `gpos.js:29-30,336-337,622-638`: tema, zoom y tamaño de página. Ningún token ni dato de sesión va al almacenamiento local ni a `sessionStorage`.
- **Remediación:** que el documentador alinee 8.6 con lo construido, o que se registre la desviación. Una prueba de arquitectura que prohíba guardar en el almacenamiento local claves con `token` o `sesion` mantendría la justificación.

### SEG-FA-10 (Informativa): la liberación del candado sin la clase `Esencial`

- **Qué pasa:** P-81A-17 (a), firmada, incluye `POST /api/super/sistema/restauracion/liberar` entre las `Esencial`. La marca quedó para el PR #45 de A (`ClaseLicenciaFactorTests.cs:87`; H-V4-02). Mientras `UseLicencia` no esté activo, no tiene efecto.
- **Si se olvida:** con la licencia activa y todas las empresas en solo consulta, el SUPER no podría liberar el candado y se rompería I-15.
- **Remediación:** condición de activación de `UseLicencia`. Se entrega a A.

---

## 6. Controles bien implementados

- Verificación TOTP y respaldo resistentes al tiempo y a las peticiones en paralelo:
  - ventana completa y `FixedTimeEquals`;
  - `UPDLOCK` y `UPDATE` condicionales para el paso y para los códigos;
  - incremento y bloqueo en una sola sentencia.
- El secreto nunca en claro fuera de la operación: Data Protection con un propósito por usuario y borrado de la memoria.
- El QR se genera en el servidor web y el alta queda solo en la memoria del servidor o del proceso.
- SF-03 hecho por construcción. El comprobante v2 está ligado al sello, al `amr` y a un solo uso. El desafío se invalida con cualquier cambio de credenciales.
- `FiltroFactor` con una lista cerrada de cuatro rutas y la prueba PF-42. El nivel se toma del token **o** de la cuenta.
- La autenticación reciente se aplica a las 15 rutas de 5.5, incluidas las de A (R3 y la liberación).
- Las vías (a) y (b) en una sola transacción con el orden de 8.4. I-9 se comprueba en la base. La vía (b) tiene la guarda del anillo y un actor con SID.
- Reconciliación v2 completa e idempotente, con la guarda de versión.
- `ExigirSuper` sin interruptor en Release.
- PF-24 con cero apariciones de secretos, en el registro Trace y en las tablas.
- La Web y MAUI no cierran la sesión por los 401 del factor, con una sola repetición. El token de MAUI vive solo en memoria.

---

## 7. Riesgos residuales (no son de la fase A)

- **RR-1 (Media, depende de ADR-83 SL y de PUB-06):** mientras exista `SelladoCuentaNulo` y la credencial de la API siga en texto plano (I-18 sin implementar), quien obtenga el DML de `GPOS_SYSDATA` con esa credencial puede borrar la fila de `UsuariosFactor` de un SUPER y cambiar su `PasswordHash`. Con eso entra sin el segundo factor. Es la amenaza que cierra el sello de habilitación de ADR-83. No se acepta en producción sin SL o sin PUB-06.
- **RR-2 (Baja):** al restaurar `GPOS_SYSDATA` vuelve el secreto TOTP que tenía el respaldo. Si el SUPER cambió de teléfono porque perdió el anterior, ese teléfono perdido vale otra vez. Lo mitigan el candado (solo entra el SUPER), la contraseña y `UltimoPaso`.
  - **Recomendación para la tarjeta de revisión de 5.14:** «si cambió de teléfono después de la fecha del respaldo, haga el cambio de teléfono antes de liberar». Es un texto de UX, sin código de seguridad.

---

## 8. Criterio de salida de seguridad (T-r)

| # | Punto del encargo | Resultado | Hallazgos |
|---|---|---|---|
| 1 | Cálculo TOTP (tiempo constante, ±1, un solo uso, deriva, PBKDF2) | **Cumple** | — |
| 2 | Secreto con Data Protection; `otpauth` y QR en el servidor, sin registros | **Cumple** | — |
| 3 | Dos pasos, SF-03, comprobante v2, `FiltroFactor`, `/reautenticar`, C-3 y `no-store` | **Cumple** | SEG-FA-02 (M), SEG-FA-05 (B), SEG-FA-07 (I), SEG-FA-08 (I) |
| 4 | Tokens: CS-1, 2, 4, 5, 6, 9, 10 y 12; revocación; `inactiva` y `renovada` | **Cumple en el servidor** | SEG-FA-01 (M), SEG-FA-03 (B) |
| 5 | Vía (a), vía (b) y `ISelladoCuenta` | **Cumple** | SEG-FA-04 (B), SEG-FA-06 (B, sospecha); RR-1 |
| 6 | Bitácora: limitador, purga, 5.11 y sin datos sensibles | **Cumple** | — |
| 7 | Reconciliación v2: sello de todas las cuentas y códigos revividos | **Cumple** | RR-2 |
| 8 | Clase de licencia T-m | **Cumple** | SEG-FA-10 (I) |
| 9 | D-01: las 5 rutas anónimas | **Confirmado** | — |
| 10 | `ExigirSuper` obligatorio en Release | **Cumple** | — |
| 11 | Web y MAUI: token en memoria, `Clear-Site-Data`, `GPOS.Factor` y el 401 `factor` | **Cumple** | SEG-FA-09 (I) |
| — | **Hallazgos Críticos o Altos abiertos** | **Ninguno** | — |

---

## 9. Remediaciones priorizadas

| Prioridad | ID | Remediación | Esfuerzo | Cuándo |
|---|---|---|---|---|
| 1 | SEG-FA-02 | `.RequiereAutenticacionReciente()` en `/inhabilitar` | 0,02 sp | Antes de unir, o en el primer lote después |
| 2 | SEG-FA-01 | Encabezado de petición automática, excluido de `AnotarActividadAsync` y de `UltimaActividadUtc` | 0,1 sp | Antes de publicar al cliente |
| 3 | SEG-FA-03 | Tope de 4 h en `OpcionesSesion.Validar` | 0,01 sp | Con SEG-FA-02 |
| 4 | SEG-FA-04 | Negarse con la salida redirigida, antes de la transacción | 0,02 sp | Antes de publicar |
| 5 | SEG-FA-05 | `LimiteCuerpo` en 5.2, 5.3 y `/login` | 0,01 sp | Con SEG-FA-02 |
| 6 | SEG-FA-06 | Confirmar si `PerfilMin = avanzado` puede existir hoy; si puede, negar la vía (b) | 0,03 sp | Antes de que el perfil Avanzada sea seleccionable |
| 7 | SEG-FA-10 | Marcar `liberar` como `Esencial` (PR #45 de A) | 0,01 sp | Antes de activar `UseLicencia` |
| 8 | SEG-FA-07, 08 y 09 | Opcionales o de documentación | ≤ 0,05 sp | Sin plazo |

Total de lo recomendado antes de publicar: ≈ 0,2 sp [inferido, ±50 %].

---

## 10. Recomendación: **Aprobado con observaciones**

Recomendación técnica: la decisión de unir es del propietario (C2).
- No queda ningún hallazgo Crítico ni Alto abierto, así que se cumple el criterio de salida de seguridad de la fase A.
- Los dos hallazgos Medios (SEG-FA-01 y SEG-FA-02) no permiten saltarse el segundo factor:
  - uno debilita el cierre por inactividad;
  - el otro deja una acción de administración fuera de la autenticación reciente.

  Los dos se corrigen con unas pocas líneas y deben quedar resueltos antes de publicar al cliente.
- Se confirma D-01 del informe de QA.
- La publicación sigue condicionada, además, a RR-1: el sello SL de ADR-83 y PUB-06.

---

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\GPOS-C-revision-seguridad-fase-a-final.md`
- Supuestos: el commit de QA `06b913c8` es el que se une; los resultados de las pruebas son los del informe de QA de T-r, sin volver a ejecutarlas; el efecto de SEG-FA-01 se infiere de la lectura del código; la vía (a′) se da por revisada en las tres revisiones anteriores.
- Decisiones candidatas a ADR: ninguna. Si `/perfiles` entra en la lista de 5.5 (SEG-FA-02, opcional), sería una precisión de ADR-81, punto 14, a cargo del Arquitecto Maestro.
- Entregas a otros agentes:
  - desarrollador de C (T-e/T-f): SEG-FA-01 a SEG-FA-05;
  - equipo A: SEG-FA-10 (PR #45) y la confirmación de SEG-FA-06 (`PerfilMin`);
  - documentador técnico: SEG-FA-09 (8.6) y O-1 de QA;
  - diseñador UX: el texto de RR-2 en la tarjeta de 5.14;
  - Arquitecto Maestro: si `/perfiles` es sensible.
- Próximo paso recomendado: corregir SEG-FA-02, SEG-FA-03 y SEG-FA-05 (unas pocas líneas) y unir; SEG-FA-01 y SEG-FA-04 en el primer lote después de la unión, antes de publicar.

---

## 11. Verificación de correcciones (`06b913c8..3b1fa070`)

**Fecha:** 2026-10-16 · Revisión de solo lectura del diff: 27 archivos, de los que 8 son de pruebas con +286 líneas. No ejecuté pruebas.

| ID | Commit | Corrección | Resultado |
|---|---|---|---|
| SEG-FA-02 | `54d300fa` | `.RequiereAutenticacionReciente()` en `POST /api/admin/usuarios/{codigo}/inhabilitar` (`AdminEndpoints.cs:283-285`) | **Cerrado** |
| SEG-FA-03 | `d438cfb6` | `TopeHorasVigenciaSuper = 4`; `Validar` falla fuera de 1 a 4 (`OpcionesSesion.cs`) | **Cerrado** |
| SEG-FA-01 | `d438cfb6` | Encabezado `X-GPOS-Automatica: 1` en el refresco del Tablero (Web y MAUI). La principal no anota actividad (`RevocacionSesiones.CuentaComoActividad`, `Program.cs:101-102`) y la introspección tampoco (`SolicitudIntrospeccion.Automatica`). El cliente no actualiza `UltimaActividadUtc` | **Cerrado** |
| SEG-FA-04 | `c399b956` | `ComprobarSalida(Console.IsOutputRedirected)` devuelve salida 1 **antes** de leer la configuración, de pedir la confirmación y de abrir la transacción (`GPOS.Migracion/Program.cs:323-328`; `RestablecimientoFactor.cs:44-55`) | **Cerrado** |
| SEG-FA-05 | `3b1fa070` | `LimiteCuerpo(4096)` en 5.2 y 5.3 (`AuthEndpoints.SegundoFactor.cs:43`, `:87`) | **Cerrado** |

### 11.1 El encabezado `X-GPOS-Automatica` solo quita actividad — verificado

- **Usos en `src`.** Aparece en cuatro sitios de código y en el cliente:
  - `RevocacionSesiones.CuentaComoActividad`;
  - el reenvío a la API de reportes (`ReenvioReportes.cs:111-113`);
  - la autenticación de la API de reportes (`AutenticacionIntrospeccion.cs:47-49`);
  - la constante de `ClaimsSesion`;
  - en el cliente, `ApiClient` de la Web y de MAUI.
- **Ningún uso decide el acceso.** En la principal, la comprobación va **después** de `MotivoInvalidoAsync` y de la marca de `FiltroFactor`, dentro de la rama del token válido (`Program.cs:97-102`). Solo decide si se llama a `AnotarActividadAsync`.
- **En la introspección, solo salta la anotación.** `ValidadorTokenPrincipal.ValidarAsync(token, automatica, ct)` hace todas las comprobaciones (firma, revocación, `esquema-pendiente` y `cambiar_clave`) antes del `if (!automatica)`.
- **No toca nada más:** ni la autorización, ni el limitador de peticiones, ni el candado, ni la autenticación reciente, ni `FiltroFactor`.
- **Peor caso para un cliente que lo envía siempre:** su sesión nunca registra actividad y se cierra por inactividad a los 30 min (SUPER) o 120 min (resto), como mucho antes que sin el encabezado. Es fallo seguro: no alarga ninguna sesión ni afecta a otra cuenta, porque la anotación es del token propio.
- **Lo que el navegador no puede hacer:** inyectarlo en las peticiones del servidor web, que las construye `ApiClient`.
- **Valor estricto:** `EsAutomatica` exige `"1"`, sin distinguir otro texto (`ClaimsSesion.cs`). Cualquier otro valor cuenta como actividad, que es el comportamiento anterior.
- **Alcance de la marca:**
  - el `AsyncLocal<bool>` solo vale dentro del `using (Api.Automatica())` del refresco y se restaura al salir;
  - si se escapara a otra petición, el efecto sería el mismo peor caso: menos actividad, nunca más acceso;
  - el botón «Actualizar» y el cambio de período siguen contando como actividad.

**Observaciones informativas, sin acción obligatoria:**
- **SEG-FA-11 (Informativa):** si un sondeo automático recibe un 401 `factor` o `REAUTENTICAR`, `ManejadorSesion` puede abrir P6 sin que la persona haya hecho nada. Ya pasaba antes de la corrección: no es seguridad, es experiencia. Sugerencia: con la marca automática, no abrir el diálogo y devolver el 401 a la pantalla.
- **SEG-FA-12 (Informativa):** la caché de `VerificadorIntrospeccion` reutiliza la respuesta de un sondeo automático para una petición real dentro de su vigencia (de segundos), y esa petición no anota actividad en la principal. El efecto, despreciable, es que se cuenta menos actividad: el lado seguro. Además, la petición del visor ya pasa antes por la principal por el reenvío, que la anota si no viene marcada.

### 11.2 Cambio del protocolo de introspección (de B) — compatible

- **Campo aditivo y opcional.** `SolicitudIntrospeccion(string Token, int Version = 1, bool Automatica = false)` (`ProtocoloIntrospeccion.cs:290`). La versión sigue en 1 y el servidor sigue exigiendo `Version == 1` (`ServidorIntrospeccion.cs:176`).
- **Compatibilidad en los dos sentidos.** El serializador es `JsonSerializerDefaults.Web` (`ProtocoloIntrospeccion.cs:62`), sin `UnmappedMemberHandling.Disallow`:
  - un cliente anterior no manda el campo, se toma `false` y todo cuenta como antes;
  - un servidor anterior ignora el campo desconocido.

  Por eso no hace falta subir la versión.
- **Interfaces sin romper.** `IVerificadorToken` y `IValidadorTokenLocal` ganan la sobrecarga con una implementación por omisión que delega en la anterior.
- **Sin efecto en la validez.** El campo no cambia la respuesta (`Valido`, `Motivo`, `Claims`), solo si se anota la actividad. El canal sigue con su ACL y la comprobación del dueño, así que solo lo envía la cuenta del servicio de la API de reportes.
- **Pendiente:** como el protocolo es de B, B debe dar su visto bueno al unir. Se entrega a B.

### 11.3 Notas sobre SEG-FA-04 y SEG-FA-05

- **SEG-FA-04:** `Console.IsOutputRedirected` no detecta una pseudoconsola que captura la pantalla, como algunas herramientas de soporte remoto con ConPTY. Ese riesgo residual es de procedimiento, y la guía de la vía (b) debería decir «ejecútelo en una consola local o por RDP, sin herramientas que graben la sesión». Severidad Informativa (SEG-FA-13).
- **SEG-FA-05:** `/login` sigue sin `LimiteCuerpo`. Es anterior a la fase A y queda como recomendación (Baja), sin condicionar la unión.

### 11.4 Veredicto actualizado: **Aprobado con observaciones**

- SEG-FA-01 a SEG-FA-05 están cerrados.
- Ningún hallazgo Crítico, Alto ni Medio queda abierto.
- Siguen abiertos:
  - SEG-FA-06 (Baja, sospecha; confirmación de A sobre `PerfilMin`);
  - los informativos SEG-FA-07 a 13;
  - los riesgos residuales RR-1 (ADR-83 SL y PUB-06) y RR-2.

Ninguno condiciona la unión. Es una recomendación técnica: la decisión es del propietario (C2).

### Cierre (verificación)
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\GPOS-C-revision-seguridad-fase-a-final.md` (sección 11 agregada)
- Supuestos: verificación por lectura del diff, sin ejecutar pruebas; las 8 pruebas nuevas del diff no se corrieron en esta revisión.
- Decisiones candidatas a ADR: ninguna.
- Entregas a otros agentes:
  - equipo B: visto bueno del campo `Automatica` del protocolo de introspección;
  - equipo A: SEG-FA-06 y SEG-FA-10;
  - frontend de C: SEG-FA-11 (opcional);
  - documentador: la nota de la guía de la vía (b) (SEG-FA-13).
- Próximo paso recomendado: correr la suite oficial sobre `3b1fa070` y unir con el visto bueno de B al protocolo.

---

## Actualización del 2026-10-17: SEG-FA-06 reclasificado

**Confirmación de A** (`avisos/A-a-B/2026-10-17-d03-d04-seg-fa-06`): hoy no hay ninguna ruta de producción que deje `PerfilMin = 'avanzada'`.
- `ReglasAceptacion` solo toma `perfilMin` de una firma Avanzada propia.
- `LlavesGsf.json` no trae llaves de licencia de nivel Avanzado.
- Escribir la fila a mano ya está cubierto por RR-1.

**Nueva clasificación de SEG-FA-06:** **no explotable hoy**. Lo cubre una prueba de arquitectura (`ViaBPerfilAvanzadaTests`, PR #58 de A, `045b136c`), que falla el día que el recurso de llaves traiga una llave de licencia de nivel Avanzado mientras la vía (b) no compruebe el perfil.

**Pendiente:** decidir si la negativa de la vía (b) se construye junto con (b+), como recomienda A, o antes (unos 0,03 sp). Lo decide B con el propietario.

**SEG-FA-10:** cerrado en el PR #45 de A (`330d5c71`). `/liberar` y `/desbloquear` son Esenciales.
