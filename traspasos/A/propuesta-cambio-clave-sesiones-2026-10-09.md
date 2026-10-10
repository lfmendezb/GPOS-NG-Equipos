# Propuesta: ciclo de vida de los tokens frente al cambio de contraseña (H-3, H-4)

**Fecha:** 2026-10-09 · **Autor:** arquitecto-software (equipo A) · **Estado:** Pendiente de firma del propietario
**Base de código leída:** `GPOS-NG-dmvp01`, rama `a/d-mvp-01`, `f206153` (sin cambios en el árbol). Las rutas `src/...` son relativas a esa copia.
**Origen:** aceptación con condición de H-3 y H-4 (2026-10-09): «Plantear una solución para más adelante. El cambio de contraseñas es un tema serio y un token que no se utilizará y sigue abierto es una brecha importante».

Marcas: **[V]** = verificado en el código o en un documento firmado, con su cita · **[I]** = inferido, no verificado.

---

## 0. Resumen

| Qué | Recomendación | Esfuerzo [I] |
|---|---|---|
| H-3 y cambios de credencial en general | **Sello de seguridad por cuenta** (`SelloSeguridad`) dentro del token (`sst`) y de los comprobantes. Se valida en la misma lectura que ya hace la API para el `sid`. Todo evento de credencial renueva el sello con una única operación | 0,5 sp |
| Tokens anteriores de la misma sesión (al renovar con `/clave` o `/empresa`) | **Solo vale el último token de la sesión**: se guarda el `jti` vigente. El cliente reintenta una vez si recibe `renovada` | 0,4 sp |
| H-4 | El fallo de `ClaveActual` usa el **mismo contador y bloqueo** que el inicio de sesión. Al bloquearse, se cierra la sesión. Se escribe una línea en la bitácora y `/clave` tiene un cupo propio en el limitador (10 por minuto y usuario) | 0,3 sp |
| Tokens abiertos sin uso | **Caducidad por inactividad en el servidor** (120 min para los usuarios y la del SUPER según ADR-81) y **tope absoluto** desde el inicio de la sesión. No se recomiendan tokens cortos con renovación | 0,5 sp |
| Huecos relacionados (sección 2) | La propia clave no se cambia desde Administración sin la clave actual. Inhabilitar una cuenta revoca. Se retira el token sin `sid` | 0,15 sp |
| Pruebas de integración y revisión de seguridad | — | 0,5 sp |
| **Total** | Construirlo junto con la **fase A de ADR-81** (toca los mismos archivos) | **≈ 2,3 sp (de 1,8 a 3,0)** |

Ninguna de estas medidas toca los tokens de dispositivo (K1/KDS, SD-01), el agente de impresión ni la autorización de supervisor (sección 6).

---

## 1. Estado actual (verificado)

| Hecho | Evidencia |
|---|---|
| El token de usuario lleva `sub`, `nivel`, `empresa`, `cambiar_clave`, `jti` y `sid`. No lleva sello ni versión de credencial. El `iat` lo pone el manejador, en segundos | `src/GPOS.Api/Seguridad/Seguridad.cs:66-86` [V]; el `iat` automático es la conducta por omisión de `JsonWebTokenHandler` [I] |
| La vigencia es de 12 h para todos, también el SUPER, sin deslizamiento | `Seguridad.cs:20,65`; `src/GPOS.Api/appsettings.json:24` [V] |
| En cada petición se comprueban la revocación (`iat` frente a `SesionesRevocadas`) y el `sid` frente a la sesión registrada, con una caché de 15 s por usuario | `src/GPOS.Api/Program.cs:86-106`; `src/GPOS.Api/Seguridad/RevocacionSesiones.cs:80,84-95` [V] |
| `TokenRevocado` trunca la revocación al segundo: un token emitido en el mismo segundo que la revocación vale | `src/GPOS.Core/Sistema/UsuariosService.cs:325-326`; prueba `tests/GPOS.Tests/CierreSesionForzadoTests.cs:44-45` [V] |
| `/clave` y `/empresa` emiten un token nuevo **con el mismo `sid`** y alargan el vencimiento de la sesión. El token anterior sigue valiendo hasta su `exp`: **H-3**, y lo mismo pasa con `/empresa` | `src/GPOS.Api/Endpoints/AuthEndpoints.cs:107-118,124-143,170-185`; `UsuariosService.cs:300-305` [V] |
| Como cada renovación alarga `exp` 12 h más, una sesión puede durar sin límite si se renueva | `AuthEndpoints.cs:170` («se extiende su vencimiento»), `:178`; `Seguridad.cs:65` [V] |
| `CambiarClaveAsync` no consulta `BloqueadoHasta` y, si falla la clave actual, no incrementa `IntentosFallidos` (**H-4**). `ValidarAsync` sí lo hace (5 intentos y 15 min) | `UsuariosService.cs:355-365` frente a `:27-54`; `src/GPOS.Core/Sistema/PoliticaBloqueo.cs:10-11` [V] |
| `/clave` solo tiene el límite general de 600 peticiones por minuto y usuario. Cada intento calcula un PBKDF2 de 210 000 iteraciones | `src/GPOS.Api/Seguridad/LimitesPeticiones.cs:18,84-89`; `AuthEndpoints.cs:143`; `UsuariosService.cs:15-16` [V] |
| R-a: restablecer la clave o activar «Debe cambiar» llama a `ForzarNuevoInicioAsync` y `Registrar`, **salvo en la propia cuenta** | `src/GPOS.Api/Endpoints/AdminEndpoints.cs:149-163`; `UsuariosService.cs:252-263` [V] |
| El comprobante «cerrar la sesión anterior» (409) protege solo el código del usuario y dura 5 min. Al reenviarlo, abre la sesión sin pedir la contraseña | `AuthEndpoints.cs:44-57,79,155-159` [V] |
| Los clientes consultan `GET /api/auth/sesion` cada 20 s | `GPOS.UI.MAUI/Components/Layout/MainLayout.razor:174-186`; `src/GPOS.Web/Servicios/EstadoCircuito.cs` (`VigilanciaSesion`) [V] |
| La cookie de la Web dura 12 h, sin deslizamiento, y el token de la API queda en el servidor | `src/GPOS.Web/Program.cs:36-47` [V] |
| Los documentos firmados ya prevén un **sello de seguridad** que se renueva con cada cambio de credencial (IDN-04), y que el estado de acceso se lea sin caché (ADR-36). Nada de eso está construido | `docs/arquitectura/2026-09-29-estandar-acceso-multiempresa.md:235,469`; `docs/adr/ADR-036.md:14`; no hay `Sello` en `src/` [V] |

## 2. Huecos relacionados encontrados al verificar

Corresponden a otra especialidad: el auditor de seguridad confirma su severidad.

| # | Hueco | Evidencia | Severidad sugerida [I] |
|---|---|---|---|
| R-1 | Un **ADMIN puede fijar su propia contraseña** con `POST /api/admin/usuarios` (`ClaveNueva`) **sin la clave actual** y sin revocar nada, porque se excluye la propia cuenta. Con un token ADMIN robado, H-4 no hace falta: la cuenta se toma directamente | `AdminEndpoints.cs:15,135-163` (exclusión en `:152`); `UsuariosService.cs:137-144` | Media |
| R-2 | El comprobante 409 sobrevive al cambio de clave: quien lo obtuvo con la clave vieja entra hasta 5 min después del cambio | `AuthEndpoints.cs:44-57,155-159` | Baja-Media |
| R-3 | **Inhabilitar** una cuenta no revoca su token. Un ADMIN inhabilitado conserva la política `admin` hasta 12 h, porque el nivel sale del claim | `AdminEndpoints.cs:153-154`; `Seguridad.cs:155,174`; `src/GPOS.Core/Sistema/PermisosService.cs:19` (solo vacía los permisos, no el nivel) | Media |
| R-4 | Un token **sin `sid`** (de versiones anteriores) vale cuando el usuario no tiene ninguna sesión abierta, por ejemplo después de `/salir` | `RevocacionSesiones.cs:102-105` | Baja (hoy todos los tokens llevan `sid`, `Seguridad.cs:75`) |

---

## 3. H-3: alternativas para que los tokens anteriores al cambio dejen de valer al instante

| | A. Rotar el `sid` en `/clave` | B. Sello de seguridad en el token (**recomendada**) | C. Revocación «desde ahora» |
|---|---|---|---|
| Mecanismo | `RenovarAsync` genera un `sid` nuevo, lo registra y llama a `RegistrarSesion`. El token anterior recibe `reemplazada` | `Usuarios.SelloSeguridad` (32 hex, aleatorio). El token lleva `sst`. La API compara `sst` con el sello de la cuenta en la **misma consulta** que ya hace `EstadoSesionAsync` (`UsuariosService.cs:272-277`) | `SesionesRevocadas = ahora` antes de emitir el token nuevo |
| Cambio de datos | Ninguno | 1 columna | Ninguno |
| Cubre el cambio propio | Sí | Sí | Sí, salvo el mismo segundo (ver abajo) |
| Cubre el comprobante 409 y los comprobantes futuros (IDN-04, SES-03, SES-05) | No | **Sí**: el comprobante lleva el sello y se rechaza si cambió | No |
| Cubre el restablecimiento, «Debe cambiar», «cerrar sesiones», la inhabilitación y el factor de ADR-81 de forma uniforme | Solo cerrando la sesión, como hoy | **Sí**, con una sola operación (sección 4) | Solo como hoy |
| Coherencia con lo firmado | Contradice «conserva el `sid`» del cambio propio (estándar 3.6, `:469`) y obliga a precisarlo | **Es el sello de IDN-04**, adelantado | Mezcla la revocación del administrador con un acto propio. El cliente mostraría «Un administrador actualizó su sesión» (`src/GPOS.Web/Servicios/ApiClient.cs:28`) |
| Granularidad | No depende del reloj | No depende del reloj | **Problema**: `iat` va en segundos y `TokenRevocado` trunca al segundo (`UsuariosService.cs:325-326`). El token nuevo, emitido en el mismo segundo, debe valer, así que también vale un token anterior emitido en ese segundo. Para corregirlo haría falta un claim con milisegundos, que en la práctica es un sello mal hecho |
| Efecto de la caché de 15 s | En esta instancia, inmediato (`RegistrarSesion`). En otra instancia, hasta 15 s | En esta instancia, inmediato si se agrega `RegistrarSello`. En otra, hasta 15 s; con ADR-36, 0 s | Igual |
| Esfuerzo [I] | 0,2 sp | 0,5 sp (incluye el comprobante 409) | 0,2 sp, sin cubrir el mismo segundo |

**Recomendación: B.** Es la única que cierra H-3, R-2 y R-3 con un solo mecanismo, ya está firmada como concepto (IDN-04) y no cuesta una consulta extra. C se descarta por la granularidad y por la semántica. A sirve como parche, pero deja el comprobante abierto y obliga a precisar el estándar.

**La caché de 15 s.** Hoy la API corre como un solo proceso por sitio (ADR-24) [I]. Los cambios de esta instancia se aplican de inmediato a través de la caché (`RevocacionSesiones.cs:108,111-112`), así que la ventana efectiva es 0 s. Solo una segunda instancia de la API vería hasta 15 s. ADR-36 ya decide leer el estado de acceso sin caché, con fallo cerrado. Aquí se recomienda mantener los 15 s y pasar a 0 s con la versión 1 de ADR-36 (CS-3). Costo de 0 s [I]: una lectura por clave primaria en cada petición (menos de 1 ms; ADR-36 fija el umbral en un percentil 95 de 2 ms).

**Complemento: solo vale el último token de la sesión (CS-2).** El sello no resuelve `/empresa`, que renueva el token sin cambiar ninguna credencial, y el token anterior sigue abierto. Se guarda `Usuarios.SesionTokenId` (el `jti` vigente, que ya existe en el token, `Seguridad.cs:74`). Un token del mismo `sid` con otro `jti` recibe 401 `renovada`. **Riesgo de carrera [I]:** una petición en curso con el token anterior en el momento de renovar, por ejemplo la consulta de cada 20 s, recibiría 401. La mitigación es que, ante `renovada`, el cliente reintente **una vez** si su token cambió desde que envió la petición (Web y MAUI, `ApiClient.VerificarAsync`). Descartado: un período de gracia para el `jti` anterior (otra columna y una ventana abierta, justo lo que pide cerrar el propietario).

---

## 4. Una sola operación para todo evento de credencial (uniforme con R-a)

`UsuariosService.InvalidarCredencialesAsync(codigo, motivo, cerrarSesion)`: renueva `SelloSeguridad`. Si `cerrarSesion`, también anula `SesionId`, `SesionTokenId` y `SesionExpira`. Fija `SesionesRevocadas` y devuelve el sello. El endpoint llama a `RevocacionSesiones.RegistrarSello(...)` después de confirmar en la base. R-a y `cerrar-sesiones` pasan a usarla.

| Evento | Hoy | Propuesta | 401 que recibe el token anterior |
|---|---|---|---|
| Cambio propio (`POST /api/auth/clave`) | El token anterior sigue vivo (H-3) | Sello nuevo y token nuevo con el mismo `sid` | `credenciales` |
| Restablecimiento por el administrador (otra cuenta) | R-a (`AdminEndpoints.cs:159-163`) | Sello nuevo y sesión cerrada | `credenciales` |
| Contraseña propia desde Administración | Sin la clave actual y sin revocar (R-1) | **Se rechaza** con 400: «Para cambiar su propia contraseña use Cambiar contraseña» (CS-7) | — |
| Activar «Debe cambiar» | R-a | Sello nuevo y sesión cerrada | `credenciales` |
| «Cerrar sesiones» (administrador) | `ForzarNuevoInicioAsync` (`AdminEndpoints.cs:202-211`) | Sello nuevo y sesión cerrada (además mata los comprobantes) | `revocada` (se mantiene el texto actual) |
| Inhabilitar la cuenta | Nada (R-3) | Sello nuevo y sesión cerrada | `cuenta-inhabilitada` (REV-04) |
| Bloqueo por `ClaveActual` (H-4) | No existe | Sesión cerrada (sección 5) | `cerrada` |
| Restablecer el segundo factor (ADR-81, si se firma) | No existe | Sello nuevo y sesión cerrada | `credenciales` |
| Cambio de privilegios o de perfiles | Nada (decisión del propietario, `AdminEndpoints.cs:149-150`) | Nada | — |
| Bajar el nivel de ADMIN a USER | Nada. El nivel se lee del claim (`Seguridad.cs:155`) | Sello nuevo, sin cerrar la sesión. Es la única excepción de privilegios (CS-8) | `credenciales` |
| Desbloquear | Limpia el contador | Igual | — |

`SesionesRevocadas` y `TokenRevocado` quedan como dato para la administración y como segunda línea hasta la versión 2 del token. La validación principal pasa al sello (CS-4).

---

## 5. H-4: fallos de la clave actual

1. `CambiarClaveAsync` comprueba primero `BloqueadoHasta`, sin calcular el hash: si la cuenta está bloqueada, lanza `UsuarioBloqueadoException` (423, `Program.cs:284`). Después verifica la clave actual con **el mismo procedimiento que `ValidarAsync`**, que se extrae a un método privado común: incrementa el contador, bloquea al llegar a `MaxIntentos` y, si acierta, reinicia el contador. Así ambos caminos quedan iguales.
2. **Al bloquearse por `/clave`**, se cierra la sesión: quien prueba claves con un token tiene, casi seguro, un token robado. El usuario legítimo que se equivoca 5 veces queda igual que en el inicio de sesión: bloqueado 15 min o hasta que un administrador lo desbloquee (CS-5).
3. **Bitácora y registro:** cada fallo escribe un registro del servidor con `EventId` propio («Cambio de contraseña rechazado: contraseña actual incorrecta para {Usuario}, intento {n} de {m}»). El bloqueo y el cambio exitoso escriben además una línea en la bitácora de la empresa de la sesión (`Auditoria.Registrar`, como `AdminEndpoints.cs:263-269`), por ejemplo «Cambiar contraseña (propia)» y «Bloqueo por intentos fallidos al cambiar la contraseña; sesión cerrada». Ninguna incluye contraseñas, hashes ni sellos (TRZ-02). En el modo limitado, sin esquema, va solo el registro del servidor, como `RegistrarModoLimitado` (`AuthEndpoints.cs:150-153`).
4. **Cupo propio del limitador:** política `clave`, 10 por minuto, con partición `clave:u:{usuario}` (`LimitesPeticiones.cs`). No sustituye al bloqueo: limita el costo de CPU del PBKDF2 y el abuso antes de llegar a la base (CS-6).

---

## 6. Tokens abiertos sin uso: vigencia, inactividad y renovación

**Hoy [V]:** 12 h absolutas para todos (`Seguridad.cs:20,65`), cookie de la Web de 12 h sin deslizamiento (`src/GPOS.Web/Program.cs:46-47`) y ninguna caducidad por inactividad en la API. Cada renovación alarga `exp` (`AuthEndpoints.cs:170-185`). El SUPER también tiene 12 h, aunque SUP-02 firmó 2 h (`estándar:309`) y la propuesta de ADR-81 sugiere 4 h y 30 min de inactividad (C-3, `propuesta-segundo-factor-super-2026-10-07.md:29`).

| Opción | Valoración |
|---|---|
| **Inactividad en el servidor** (recomendada, CS-9) | Columna `Usuarios.SesionActividad`. Cada petición autenticada, **excepto `GET /api/auth/sesion`** (la consulta de cada 20 s), la actualiza como mucho una vez por minuto y usuario: menos de una escritura por minuto y usuario activo. En `OnTokenValidated`, si pasaron más de `Sesion:MinutosInactividad` (120 por omisión para los usuarios; el valor que firme ADR-81 para el SUPER), se cierra la sesión y el token recibe 401 `inactiva`. Cubre justo «el token que nadie usa». [I]: si alguna pantalla consulta por su cuenta otra ruta de forma periódica, la mantiene viva; QA debe listarlas |
| **Tope absoluto** (recomendado, CS-10) | `exp = min(ahora + HorasVigencia, SesionInicio + HorasVigencia)`: renovar ya no prolonga la sesión. Se mantienen 12 h configurables (cubre un turno). El SUPER, según ADR-81 o SUP-02 |
| Tokens cortos (15 min) con renovación deslizante | **Descartada.** La API ya valida cada petición contra la base (sello, sesión, `jti`), así que un token corto no revoca nada que no se revoque ya. Costaría un endpoint de renovación, rotación y detección de reutilización, y cambios en Web y MAUI: unos 1,5 a 2 sp [I]. Tiene sentido para el nodo aislado, que ya tiene sus tokens de 8 h y 1 h (`ADR-053.md:54`) |
| Bajar las 12 h | Sin evidencia de que convenga. Lo que el propietario señala (un token sin uso) lo resuelve la inactividad, no un tope menor |

En la Web, la cookie se alinea con el tope: al recibir `inactiva`, `ApiClient` lleva al inicio de sesión con su motivo. No hace falta deslizamiento en la cookie.

---

## 7. Lo que no debe romperse

| Componente | Efecto | Evidencia |
|---|---|---|
| **K1/KDS y comanderas (SD-01, SD-03)** | Ninguno. Usan el esquema `Dispositivo` (`typ = disp+jwt`, sin `sub`, 15 min) con su propio `OnTokenValidated`. El sello, el `jti`, la inactividad y el contador viven solo en el esquema de usuario. `CambioClaveObligatorio.Es` ya excluye los dispositivos | `Seguridad.cs:286-318`; `Program.cs:61-67`; `src/GPOS.Api/Seguridad/AutenticacionDispositivo.cs:59,74`; `CambioClaveObligatorio.cs:22` [V]. Prueba de no regresión con `SeparacionTokensTests` |
| **Agente de impresión** | Ninguno. Usa el token de dispositivo de la estación, de 15 min | `src/GPOS.AgenteImpresion/Estacion/ClienteDispositivo.cs:86,105,136-149` [V] |
| **Autorización de supervisor (R-b)** | Ninguno. No emite token; ya usa `ValidarAsync`, con contador | `src/GPOS.Api/Endpoints/PosEndpoints.cs:45-58`; `src/GPOS.Core/Sistema/AutorizadorSupervisor.cs:31-34` [V] |
| **TOTP del SUPER (ADR-81, sin firmar)** | `/clave` y `/empresa` **conservan** `amr` y `auth_time` (D-7 y 2.6.4 de la propuesta). El sello nuevo no los toca. Restablecer el factor renueva el sello. La inactividad del SUPER es el valor de C-3. El mecanismo de inactividad es el mismo para los dos y se construye una sola vez | `propuesta-segundo-factor-super-2026-10-07.md:20,29,113-115` [V, propuesta sin firmar] |
| **Modo limitado (H-EI-01)** | `/clave` conserva el modo limitado (`AuthEndpoints.cs:127-128`); el sello no lo cambia | [V] |
| **Sucursal sin conexión: nodo (ADR-53) y sucursal en línea con SQLite (después de las olas)** | Entrega 2. Cada nodo firma sus tokens (cláusula 6). El **sello forma parte de las credenciales replicadas** (MD-53 v2) y «la seguridad viaja primero», en 5 min o menos (C50-2). Con el nodo aislado, un cambio hecho en la central llega al reconectar: es la revocación diferida ya aceptada como riesgo Medio (excepción de ADR-36). **El cambio de contraseña solo se hace en la central**: en un nodo, `/clave` responde 503 `REQUIERE_CENTRAL`. Así no aparecen dos sellos que haya que conciliar (CS-11) | `ADR-053.md:52,54`; `ADR-036.md:26` [V]; la regla del nodo es [I] y se decide para la entrega 2 |
| **API de reportes (ADR-109)** | Valida por introspección contra la principal, así que hereda el sello y la inactividad sin cambios | `docs/adr/README.md:84` [V]; el detalle de la introspección es [I] |

---

## 8. Contratos

| Situación | Respuesta |
|---|---|
| Token con un sello distinto del de la cuenta | 401, `X-GPOS-Sesion: credenciales`. Texto: «La contraseña o el acceso de su usuario cambió; inicie sesión de nuevo.» |
| Token anterior de la misma sesión (`jti` distinto) | 401, `X-GPOS-Sesion: renovada`. El cliente reintenta una vez con el token actual |
| Sesión inactiva | 401, `X-GPOS-Sesion: inactiva`. Texto: «Su sesión se cerró por inactividad.» |
| Cuenta inhabilitada | 401, `X-GPOS-Sesion: cuenta-inhabilitada` (REV-04) |
| `/clave` con la clave actual incorrecta | 400, `codigo = CLAVE_ACTUAL_INCORRECTA` (hoy es un 400 sin código, `UsuariosService.cs:359`) |
| `/clave` o login con la cuenta bloqueada | 423, `codigo = USUARIO_BLOQUEADO` (se agrega el código al 423 actual) |
| Más de 10 intentos de `/clave` por minuto | 429 con `Retry-After` (forma actual, `LimitesPeticiones.cs:67-76`) |
| Contraseña propia desde Administración | 400 con un texto que remite a «Cambiar contraseña» |
| Token sin `sid` o sin `sst` | 401 `cerrada` (R-4): todos vuelven a entrar una vez al desplegar. Es aceptable porque hoy todo es desarrollo |
| `/clave` en un nodo (entrega 2) | 503 `REQUIERE_CENTRAL` |

Las constantes nuevas van en `CodigosCuenta` (`src/GPOS.Contracts/Seguridad/Cuentas.cs:95-102`) y en `RevocacionSesiones`. Los textos van en `SesionExpiradaException` de Web y MAUI.

## 9. Cambios de datos (para el arquitecto-datos)

`GPOS_SYSDATA`, `dbo.Usuarios`, con el script idempotente de `src/GPOS.Core/Data/Sistema/EsquemaSistema.cs`:
- `SelloSeguridad varchar(32) NULL`. Si es NULL, se genera al iniciar sesión.
- `SesionTokenId varchar(32) NULL`: el `jti` vigente.
- `SesionActividad datetime2 NULL`.

No llevan índices: se leen por la clave primaria en la consulta que ya existe. No hay migración de datos.

## 10. Pruebas de aceptación

| # | Prueba | Esperado |
|---|---|---|
| PA-1 | Cambiar la clave y usar el token anterior en `/sesion`, `/clave` y `/salir` | 401 `credenciales`; el token nuevo vale |
| PA-2 | PA-1 dentro del mismo segundo de la emisión (reloj simulado) | Igual (no depende de `iat`) |
| PA-3 | Obtener el 409 con la clave vieja, cambiar la clave y reenviar el comprobante | 401 |
| PA-4 | Restablecer la clave, activar «Debe cambiar», cerrar sesiones o inhabilitar la cuenta, y probar con el token anterior | 401 con el motivo de la tabla 4 en la petición siguiente (instancia única) |
| PA-5 | ADMIN que envía `ClaveNueva` para su propia cuenta en `POST /api/admin/usuarios` | 400; la clave no cambia |
| PA-6 | Renovar con `/empresa` y usar el token anterior | 401 `renovada`; el cliente reintenta y sigue sin salir de la pantalla |
| PA-7 | 5 claves actuales incorrectas en `/clave` | 400 ×4, después 423; sesión cerrada; login bloqueado 15 min; registro y bitácora sin secretos |
| PA-8 | Fallos repartidos entre el inicio de sesión y `/clave` | Un solo contador |
| PA-9 | 11 llamadas a `/clave` en un minuto | La 11.ª recibe 429 |
| PA-10 | Sin peticiones durante más de `MinutosInactividad`, con la consulta de `/sesion` cada 20 s activa | 401 `inactiva` |
| PA-11 | Renovar varias veces durante más de `HorasVigencia` | El `exp` no pasa de `SesionInicio + HorasVigencia` |
| PA-12 | KDS, comandera y agente de impresión durante un cambio de clave de cualquier usuario | Sin 401 |
| PA-13 | SUPER con `amr=otp` que cambia la clave (si ADR-81 está construido) | El token nuevo conserva `amr` y `auth_time` |
| PA-14 | Medición de la consulta de validación con las columnas nuevas | Percentil 95 de 2 ms o menos (ADR-36) |

## 11. Esfuerzo [I] (±30 %)

| Bloque | sp |
|---|---|
| Sello: columna, claim, validación, caché, `InvalidarCredencialesAsync`, comprobante 409 | 0,5 |
| Último token (`jti`), `renovada` y reintento en Web y MAUI | 0,4 |
| H-4: contador común, bloqueo, cierre de sesión, bitácora y política `clave` | 0,3 |
| Inactividad y tope absoluto, configuración y mensajes de cliente | 0,5 |
| R-1, R-3 y R-4 | 0,15 |
| Pruebas PA-1 a PA-14 y revisión de seguridad | 0,5 |
| **Total** | **≈ 2,3 sp (de 1,8 a 3,0)** |

**Cuándo:** junto con la fase A de ADR-81 (2026-11-02 a 2026-11-13, si se firma). Toca `AuthEndpoints.cs`, `Program.cs` y `RevocacionSesiones.cs`, igual que la fase A, y comparte la inactividad (C-3). Construirlas por separado es arriesgado porque ambas editan los mismos archivos (Q-09 de la hoja de ADR-81). La alternativa es construir solo CS-1, CS-5 y CS-7 antes (≈ 0,9 sp) y el resto con la fase A.

## 12. Riesgos

- **Carrera al renovar (CS-2):** sin el reintento en el cliente, una pantalla puede volver al inicio de sesión justo después de `/empresa`. Mitigación: el reintento y PA-6.
- **Denegación de servicio por bloqueo:** quien conoce un código de usuario ya puede bloquearlo hoy desde el login. Con H-4, además, quien tiene un token puede bloquear a su dueño. Se acepta: el bloqueo es temporal y la sesión ya estaba comprometida. El bloqueo por (cuenta, IP) de SES-13 lo atenúa en la versión 1 de ADR-36.
- **Inactividad y pantallas que consultan solas** [I]: QA debe listar las rutas periódicas además de `/sesion`.
- **Molestia operativa:** 120 min de inactividad pueden cerrar la sesión de un cajero en una tienda con poco movimiento. Es configurable por instalación.

---

## 13. Hoja de firma

Marque una opción por línea. Hasta la firma, todo queda **Pendiente de firma**.

| # | Decisión | Recomendación | Firma |
|---|---|---|---|
| **CS-1** | Mecanismo para H-3: **sello de seguridad** por cuenta en el token (`sst`) y en los comprobantes (adelanta IDN-04). Descartadas: rotar el `sid` (no cubre el comprobante y contradice el estándar 3.6) y la revocación «desde ahora» (granularidad de 1 s y semántica de administrador) | **Aprobar B (sello)** | [ ] Como se recomienda · [ ] A · [ ] C · [ ] Otra: ___ |
| **CS-2** | Solo vale **el último token de la sesión** (`SesionTokenId` = `jti`), con 401 `renovada` y un reintento del cliente | **Aprobar** | [ ] Sí · [ ] No |
| **CS-3** | Caché del estado de sesión: mantener 15 s (una instancia, aplicación inmediata en esta instancia) y pasar a 0 s con la versión 1 de ADR-36 | **Aprobar** | [ ] Sí · [ ] 0 s ya |
| **CS-4** | Una sola operación `InvalidarCredencialesAsync` para todos los eventos de la tabla 4 (sustituye las llamadas sueltas de R-a). La validación pasa al sello y `SesionesRevocadas` queda como dato y segunda línea | **Aprobar** | [ ] Sí · [ ] Con cambios: ___ |
| **CS-5** | H-4: mismo contador y bloqueo que el inicio de sesión, comprobación previa de `BloqueadoHasta`, **cierre de la sesión al bloquearse**, registro en cada fallo y bitácora al bloquear y al cambiar | **Aprobar** | [ ] Sí · [ ] Sin cerrar la sesión |
| **CS-6** | Cupo propio del limitador para `/clave`: 10 por minuto y usuario | **Aprobar** | [ ] Sí · [ ] Otro valor: ___ |
| **CS-7** | La propia contraseña **no** se cambia desde Administración (R-1): solo con `/clave` y la clave actual | **Aprobar** | [ ] Sí · [ ] No |
| **CS-8** | Inhabilitar la cuenta y bajar el nivel de ADMIN a USER renuevan el sello (R-3). Es la única excepción a «los privilegios no revocan nada» | **Aprobar** | [ ] Sí · [ ] Solo inhabilitar |
| **CS-9** | Caducidad por **inactividad en el servidor**: 120 min para los usuarios (configurable) y el valor de ADR-81 para el SUPER. La consulta `/sesion` no cuenta como actividad | **Aprobar** | [ ] Sí · [ ] Otro valor: ___ |
| **CS-10** | **Tope absoluto**: renovar no alarga la sesión más allá de `SesionInicio + HorasVigencia` (12 h). **Sin** tokens cortos con renovación | **Aprobar** | [ ] Sí · [ ] Con cambios: ___ |
| **CS-11** | Entrega 2: el sello viaja con las credenciales replicadas del nodo. `/clave` solo funciona en la central (503 `REQUIERE_CENTRAL` en un nodo). Lo mismo vale para la sucursal en línea con SQLite | **Aprobar en principio** (se detalla con la entrega 2) | [ ] Sí · [ ] Pendiente |
| **CS-12** | Retirar la aceptación de tokens sin `sid` o sin `sst` (R-4): todos vuelven a entrar una vez al desplegar | **Aprobar** | [ ] Sí · [ ] No |
| **CS-13** | Calendario: junto con la fase A de ADR-81 (≈ 2,3 sp); si ADR-81 se retrasa, adelantar CS-1, CS-5 y CS-7 (≈ 0,9 sp) | **Aprobar** | [ ] Sí · [ ] Otro: ___ |

**Candidatas a ADR (las redacta el Arquitecto Maestro):** ciclo de vida del token de usuario (CS-1, CS-2, CS-9 y CS-10) como precisión de ADR-36 y del estándar 3.6; CS-11 como precisión de la cláusula 6 de ADR-53.

**Firma del propietario (2026-10-09):** CS-1 a CS-13 según la recomendación. Estado: Aceptada. Calendario según CS-13: se construye con la fase A de ADR-81; si ADR-81 se retrasa, se adelantan CS-1, CS-5 y CS-7 (≈ 0,9 sp).

