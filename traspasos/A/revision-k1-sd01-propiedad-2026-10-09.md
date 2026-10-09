# Informe de seguridad: revisión de A sobre SD-01 y `Propiedad` (rama `b/kds-k1`)

**Fecha:** 2026-10-09 · **Revisor:** auditor-seguridad del equipo A · **Tipo:** revisión de código de solo lectura (sin compilar ni ejecutar pruebas)
**Pedido:** aviso `GPOS-NG-Equipos/avisos/B-a-A/2026-10-08-k1-sd01-propiedad-para-revision.md`; decisión del propietario del 2026-10-08 (B cambia el núcleo en su rama y A lo revisa antes de unir).
**Commits revisados (base `2078a08`):** `a4b1a9b` (SD-01), `df79075` (`Propiedad`) y, en `dc40169`, la ampliación de la lista cerrada de rutas anónimas de `QaOla4HttpTests`. `Seguridad.cs` y `LimitesPeticiones.cs` no cambian después de `df79075`; `Program.cs` solo suma, después, el registro y el mapeo de los dispositivos (líneas 111-112 y 254). Por eso las líneas citadas de esos tres archivos valen igual en `df79075` y en la punta de `origin/b/kds-k1`.
**Referencias:** blueprint del KDS, 6.1 a 6.3, 5.3.3 y 9.1.1 (`b/restaurante-kds-diseno`, `docs/arquitectura/2026-10-08-kds-y-meseros-blueprint.md`); ADR-41, 68, 109 (cláusula 6, S-15), 121 (PF-1), 122; revisión de B `docs/seguridad/2026-10-09-revision-k1.md` (`8920d7a`); introspección de la ola 5 en `origin/b/ola5`.

---

## 1. Alcance y superficie revisada

| Superficie | Archivos |
|---|---|
| Selección de esquema por `typ` y esquemas `Bearer` (usuario) y `Dispositivo` | `src/GPOS.Api/Program.cs:57-102`; `src/GPOS.Api/Seguridad/Seguridad.cs:226-313` |
| Políticas por omisión, `admin`, `super`, `perm:*`, `algun:*` y `disp:*` | `Seguridad.cs:124-229` |
| Emisor del token de usuario (`typ = JWT`) | `Seguridad.cs:80-86` |
| Partición `d:{id}` del limitador | `src/GPOS.Api/Seguridad/LimitesPeticiones.cs:79-89` |
| `Propiedad` en el validador común de ADR-68 | `src/GPOS.Core/Servicios/Nucleo/AutorizacionesSupervisor.cs:49-58`; `src/GPOS.Core/Infraestructura/Sesion.cs:27-31`; `Seguridad.cs:115-117` |
| Rutas anónimas `emparejar` y `token` (decisión de seguridad) | `src/GPOS.Api/Endpoints/RestauranteDispositivosEndpoints.cs:26-42`; `ServicioDispositivos.cs:200-331`; `Dispositivo.cs:85-144`; `Contratos.cs:88-123`; `tests/GPOS.Tests/ModeloNg/QaOla4HttpTests.cs:92-93` |
| API de reportes (introspección S-15): **todavía no está en `b/kds-k1`** | `origin/b/ola5`: `src/GPOS.Comun/Sesion/ParametrosTokenSesion.cs:24-43`; `src/GPOS.Comun/Introspeccion/LEEME-enganche-principal.md:24-38` |

**Superficie expuesta:** dos rutas anónimas nuevas (`POST …/emparejar`, solo en la central, y `POST …/token`, en cualquier sitio); una ruta solo de dispositivo (`GET …/actual`); las rutas de administración (ADMIN). No hay SignalR, SSE ni sondeos largos en la rama: la búsqueda de `MapHub`, `AddSignalR` y `text/event-stream` en `src/` no da resultados. Ninguna ruta de `src/` usa políticas en línea (`RequireAuthorization(p => …)`), `[Authorize]`, `FallbackPolicy` ni `AuthenticationSchemes` fuera de `ProveedorPoliticas`. Lo verifiqué con `git grep` sobre `origin/b/kds-k1`.

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título | Estado |
|---|---|---|---|
| A-K1-01 | Baja (condición para unir la ola 5) | Al enganchar la introspección de la ola 5 se pierde `ValidTypes = ["JWT"]`: ni `ParametrosTokenSesion` ni el validador de la introspección exigen el tipo | Verificado (lectura cruzada de las dos ramas) |
| A-K1-02 | Baja | Ningún esquema fija `ValidAlgorithms = [HS256]` (perfil FIPS, defensa en profundidad) | Verificado |
| A-K1-03 | Baja | El esquema de las políticas de usuario se deduce de `AuthenticationOptions` en producción | Verificado |
| A-K1-04 | Baja | `IncludeErrorDetails` queda en su valor por omisión: el 401 describe la causa en `WWW-Authenticate` | Inferido (comportamiento de `JwtBearerHandler`; no ejecutado) |
| A-K1-05 | Baja | Faltan pruebas de extremo a extremo para `typ` ausente, `jwt` en minúsculas y `JWT ` con espacio en el esquema de usuario | Verificado (ausencia en `SeparacionTokensTests.cs:303-331`) |
| B: K1-01 / K1-03 | Media / Baja | (Ya informados por el auditor de B.) El freno por dispositivo de `…/token` se cuenta antes del secreto, y la ruta hace una transacción de escritura | Verificado; son la **condición** para aceptar `token` como anónima (sección 4.6) |

No hay hallazgos Críticos ni Altos.

## 3. Checklist OWASP Top 10 (2021), limitado al alcance

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | Correcto. Los tokens quedan separados por esquema en todas las políticas y en el recorrido de todas las rutas (P-K13). `Propiedad` se aplica en el validador común. Observaciones A-K1-03 y A-K1-05 |
| A02 Fallas criptográficas | Correcto. HS256, SHA-256 y `RandomNumberGenerator` están aprobados en el perfil FIPS. Se compara en tiempo constante. Observación A-K1-02 |
| A03 Inyección | Correcto. Las consultas de dispositivos usan parámetros de Dapper, y la pertenencia a la empresa va en el `WHERE` (`ConsultasDispositivos.cs:38, 94, 102, 109`) |
| A04 Diseño inseguro | Correcto en SD-01. En `token`: K1-01 de B (DoS dirigido) |
| A05 Configuración | A-K1-04 |
| A06 Componentes vulnerables | No aplica a estos commits (sin paquetes nuevos en SD-01 ni en `Propiedad`) |
| A07 Autenticación | Correcto. Falla cerrada sin registro y sin `sub`. Código de 40 bits, de un solo uso, que vence a los 10 min, con tope global y confirmación del ADMIN. Secreto de 256 bits |
| A08 Integridad | Correcto. El `typ` va en el encabezado protegido por la firma: no se puede cambiar sin la llave |
| A09 Registro y monitoreo | Los canjes fallidos y el freno se registran. Los fallos de `token` no se registran (K1-07 de B) |
| A10 SSRF | No aplica |

## 4. Verificaciones pedidas

### 4.1 Ningún token de dispositivo satisface una política de usuario, ni al revés: **verificado**
- **Política por omisión** (rutas con solo `RequireAuthorization()`, por ejemplo `/api/catalogos`, `/api/documentos/{tipo}`, `/api/reportes`, `/api/auth/sesion`). `ProveedorPoliticas` vuelve a implementar `IAuthorizationPolicyProvider` (`Seguridad.cs:140`), y `GetDefaultPolicyAsync` (`:167-168`) devuelve una política con el esquema de usuario. La implementación es correcta en C#: al volver a declarar la interfaz, el método `new` es el que usa el `AuthorizationPolicy.CombineAsync` del middleware.
- **`admin`, `super`, `perm:*` y `algun:*`** (`Seguridad.cs:170-201`) se construyen con `DeUsuario()` (`:164`). `RequiereAlgunPermiso` pasó de política en línea a política por nombre (`:212`); antes no tenía esquema y la habría satisfecho cualquier principal del esquema predeterminado.
- **Mecanismo.** Con esquemas en la política, el `PolicyEvaluator` vuelve a autenticar solo con esos esquemas y **reemplaza** `HttpContext.User`. Si ninguno tiene éxito, deja un principal vacío. Un token `disp+jwt` falla en el esquema de usuario por el tipo (`Program.cs:74`), por la audiencia (`GPOS.Dispositivo` frente a `Jwt:Audiencia = GPOS.Web`) y por la falta de `sub` (`Program.cs:84-88`), y recibe 401. Al revés, `disp:*` (`Seguridad.cs:197-199`) autentica solo con `Dispositivo`, que exige `typ = disp+jwt` y la audiencia propia (`:288-293`), y además comprueba `EsDispositivo`. `EsDispositivo` exige `AuthenticationType == "Dispositivo"` y el claim `dis` (`:279-280`), así que un token de usuario recibe 401 o 403.
- **Rutas que combinan una política de usuario y una de dispositivo:** se exigen los requisitos de las dos, así que ningún token pasa con una sola. El blueprint, en 6.1, prevé una política explícita con los dos esquemas para `cocina/tablero` (K2).
- **Prueba.** P-K13 (`SeparacionTokensTests`) recorre **todas** las rutas de la API con un token válido de cada tipo de dispositivo y con un token de usuario, y falla si aparece una ruta sin declarar. No la ejecuté. B informa 18/18.
- **SignalR y SSE:** no existen en la rama. Cuando lleguen los sondeos largos (SD-06), deberán declararse con `RequiereDispositivo` y llamar a `RevalidarAsync` (`AutenticacionDispositivo.cs:105-111`, ya construido).
- **Rutas anónimas:** reciben el principal del esquema predeterminado (selector). Con un token de dispositivo, `HttpContext.User` es el dispositivo, pero ninguna ruta anónima concede nada por los claims. `TransformacionPermisos` sale sin hacer nada cuando falta `sub` (`PermisosServidor.cs:44-45`).

### 4.2 Confusión de tipo o algoritmo: **verificado (selector) e inferido (validador)**
- El selector (`Seguridad.cs:256-276`) compara con `==` ordinal. `DISP+JWT`, `jwt`, `JWT ` (con espacio), un `typ` ausente, un JSON ilegible o un encabezado de más de 2048 caracteres van al esquema de **usuario**. Elegir el esquema no concede nada: cada esquema valida su propio `typ`.
- Según `Microsoft.IdentityModel` 8.x (inferido, no ejecutado), con `ValidTypes` no vacío, un `typ` vacío o ausente se rechaza (IDX10256) y la comparación es ordinal (IDX10257). Así, `jwt`, `JWT ` y un `typ` ausente reciben 401 en el esquema de usuario, y `DISP+JWT` también. Es falla cerrada y no rompe nada, porque el emisor fija `TokenType = "JWT"` (`Seguridad.cs:84`) y solo hay dos `CreateToken` en `src/` (`Seguridad.cs:80` y `AutenticacionDispositivo.cs:71`), los dos con tipo explícito. El token del modo limitado sale del mismo emisor.
- El `typ` está en el encabezado firmado, y `alg=none` se rechaza (`RequireSignedTokens` vale `true` por omisión). Con una llave simétrica, solo los HS* validan. Falta fijar HS256 (A-K1-02).
- `TipoDe` captura `FormatException`, `ArgumentException` y `JsonException`. Si apareciera otra excepción, el resultado sería un 500 solo para esa petición, sin efecto sobre la autorización.

### 4.3 `ctx.Fail` no filtra información: **inferido (correcto)**
`JwtBearerHandler` solo escribe `error_description` para los tipos de excepción conocidos de `Microsoft.IdentityModel` (audiencia, emisor, vencimiento, firma). El texto de `ctx.Fail(string)` (`Program.cs:86`, `Seguridad.cs:303, 310`) no llega al cliente. El encabezado `X-GPOS-Dispositivo` solo lleva `revocado`, `no-confirmado` o `sin-registro`, y solo se entrega a quien presentó el token. Sí se describen las causas del validador, por ejemplo la audiencia inválida o la hora de vencimiento (A-K1-04, Baja).

### 4.4 Falla cerrada sin registro de dispositivos: **verificado**
`ValidarDispositivoAsync` (`Seguridad.cs:299-311`) falla si falta `dis` (`DispositivoId` exige que lo haya autenticado el esquema `Dispositivo` y que sea > 0) y, cuando no hay `IValidadorDispositivo` en el contenedor, usa el motivo `sin-registro` (`:307`). En el validador real, cualquier estado distinto de `A`, incluido un dispositivo inexistente, es `revocado` (`AutenticacionDispositivo.cs:116-121`).

### 4.5 Límites por partición: **verificado**
`LimitesPeticiones.cs:84-89`: la partición `d:{id}` solo se usa si el esquema `Dispositivo` autenticó la petición y el dispositivo está activo, y tiene el mismo cupo que un usuario (600/min). Un token inválido cae en la partición anónima por IP. Un token de dispositivo no tiene `sub`, así que nunca cae en `u:`. El limitador corre después de `UseAuthentication` (`Program.cs:218-220`). Las políticas con nombre (reportes, búsqueda, importaciones) cuentan por usuario o por IP; los dispositivos no llegan a esas rutas.

### 4.6 Rutas anónimas `emparejar` y `token`: **aceptables con condición**
- **`emparejar`** (`RestauranteDispositivosEndpoints.cs:26-28`): el código tiene 40 bits (`Dispositivo.cs:89-101`), es de un solo uso, se canjea de forma atómica (`ConsultasDispositivos.cs:68-81`), vence a los 10 min y el servidor solo guarda su SHA-256. Hay un mensaje único para el código vencido, usado o inexistente, un límite de 10/min por IP real y un tope global de 30 fallos por minuto que activa 429 para todos (`ServicioDispositivos.cs:200-243`). El equipo queda **pendiente** hasta que el ADMIN lo confirma con el nombre, la plataforma y la IP del equipo (PF-1 b). Cálculo: con el freno global, un atacante logra como mucho unos 30 intentos cada 2 min (≈ 21.600 al día). Con 10 códigos vigentes a la vez, la probabilidad de acertar uno en un día es de unos 2·10⁻⁷, y aun así el canje queda sujeto a la confirmación del ADMIN. No permite enumerar. Riesgo residual de disponibilidad: cualquiera puede mantener el emparejamiento frenado (por diseño; documentarlo en la guía de operación).
- **`token`** (`:39-42`): el secreto es de 256 bits y se compara en tiempo constante, con un hash ficticio cuando el dispositivo no existe (`Dispositivo.cs:126-144`). Hay un 401 único para inexistente, secreto errado o revocado, y `NO_CONFIRMADO` solo aparece con el secreto correcto (`ServicioDispositivos.cs:320-327`). No se puede enumerar ni forzar el secreto. **Sin embargo**, el freno por dispositivo se cuenta antes del secreto (K1-01 de B, Media), lo que permite un bloqueo dirigido sin credenciales, y la ruta anónima hace una transacción de escritura (K1-03 de B). La versión del blueprint del 2026-10-09 (6.3) ya fija la corrección.
- **Decisión recomendada:** aceptar las dos rutas en la lista cerrada de `QaOla4HttpTests.cs:92-93`, **con la condición** de que K1-01 y K1-03 estén corregidos y probados antes de unir K1 a `master`. Sin esa corrección, `token` anónima deja un vector de denegación de servicio sobre la cocina.

### 4.7 La API de reportes sigue rechazando los tokens de dispositivo: **verificado por lectura; no ejecutado**
La introspección todavía no está en `b/kds-k1` ni en `master`; vive en `origin/b/ola5`. El validador que A enganchará (`LEEME-enganche-principal.md:24-38`) usa `ParametrosTokenSesion.Crear` con `ValidAudience = Jwt:Audiencia` (`ParametrosTokenSesion.cs:31-32`) y devuelve `Invalido` si falta `sub`. Un token `disp+jwt` (audiencia `GPOS.Dispositivo`, sin `sub`) se rechaza por las dos razones. Sin embargo, `ParametrosTokenSesion` **no** fija `ValidTypes`: ver A-K1-01.

### 4.8 `Propiedad`: **verificado**
- `AutorizacionesSupervisor.ValidarAsync` rechaza con 422 `AUTORIZACION_NO_PERMITIDA_EN_DISPOSITIVO` en la línea 56, **antes** de leer el motivo (`:59`), la credencial (`:72-78`) o de registrar el rechazo (`:82-93`): no se procesa ni se cuenta ningún intento de clave.
- `EsDispositivoPersonal` (`Seguridad.cs:115-117`) exige que el principal lo haya autenticado el esquema `Dispositivo` y que el claim `prop` esté firmado. Cambiar la `Propiedad` obliga a revocar y emparejar de nuevo (blueprint 5.3.2), así que el claim no queda desactualizado. Para las demás implementaciones, el valor por omisión de la interfaz es `false` (`Sesion.cs:31`).
- Los únicos llamadores del validador común en `src/` son `DocumentosComercialesService.Ventas.cs:169` y `PosService.cs:600`. `FechasDocumento` no valida credenciales: usa el privilegio de la sesión.
- La regla depende de que la comandera **nunca** llame con un token de usuario. Así es por diseño (5.3.3: la comandera no inicia sesión de usuario). Si en el futuro una ruta aceptara una sesión de usuario desde la comandera, el control se saltaría: hay que mantener las rutas de la comandera como `disp:COMANDERA`.

## 5. Hallazgos

### A-K1-01 · Baja · Se pierde `ValidTypes` al unir la ola 5 (verificado)
**Riesgo.** S15-08 concentra los parámetros del token de sesión en `GPOS.Comun.Sesion.ParametrosTokenSesion.Crear` (`origin/b/ola5:src/GPOS.Comun/Sesion/ParametrosTokenSesion.cs:24-43`), y el enganche indica reemplazar el inicializador de `Program.cs` por `jwt.ParametrosValidacion()` (`LEEME-enganche-principal.md:116-119`). Esos parámetros no tienen `ValidTypes`. Al unir, el esquema de usuario dejaría de exigir `typ = JWT` sin que falle ninguna prueba, porque la audiencia y la falta de `sub` siguen rechazando los tokens de dispositivo. Se perdería la separación por tipo de PF-1 a («criptográfica, no por convención») en la principal y en la introspección.
**Remediación** (≈ 0,01 sp): agregar `ValidTypes = ["JWT"]` en `ParametrosTokenSesion.Crear` (con la constante compartida) al unir la ola 5 y la K1. Agregar una prueba en `GPOS.Reportes.Tests` y en P-K13: un token `disp+jwt`, y uno de usuario con `typ` distinto, reciben `MotivoInvalido` en la introspección. **Es condición para unir el que llegue segundo.** Corresponde a A (enganche de la ola 5) o a B, según el orden de unión.

### A-K1-02 · Baja · Sin `ValidAlgorithms` fijado (verificado)
**Riesgo.** `ParametrosDispositivo` (`Seguridad.cs:288-293`) y el esquema de usuario (`Program.cs:70-75`) aceptan cualquier HS* firmado con la llave del sitio. No se puede explotar sin la llave, pero el perfil FIPS y S15-08 fijan un único algoritmo.
**Remediación:** `ValidAlgorithms = [SecurityAlgorithms.HmacSha256]` en los dos (en el de usuario llega con A-K1-01).

### A-K1-03 · Baja · El esquema de usuario se deduce de la configuración (verificado)
**Riesgo.** `ProveedorPoliticas.EsquemaUsuario` (`Seguridad.cs:151-159`) usa `DefaultAuthenticateScheme ?? DefaultScheme`. Es una comodidad para los anfitriones de prueba, pero en producción cualquier cambio futuro del esquema predeterminado volvería a ligar **todas** las políticas de usuario a ese esquema, en silencio. Mitiga el problema la prueba `Las_politicas_quedan_ligadas_a_su_esquema` (`SeparacionTokensTests.cs:333`).
**Remediación:** en producción, ligar a `EsquemasAutenticacion.Usuario` como constante y permitir el cambio solo con una opción explícita de pruebas (por ejemplo, `IOptions<OpcionesEsquemaPruebas>` registrada solo por la fábrica de pruebas). O bien, al arrancar fuera de pruebas, fallar si `EsquemaUsuario != "Bearer"`.

### A-K1-04 · Baja · `IncludeErrorDetails` por omisión (inferido)
**Riesgo.** Los 401 llevan `error_description` con la causa (audiencia inválida, hora de vencimiento). Revela poco, pero facilita el sondeo.
**Remediación:** `o.IncludeErrorDetails = false` en los dos `AddJwtBearer`. Los encabezados `X-GPOS-Sesion` y `X-GPOS-Dispositivo` ya dan al cliente lo que necesita.

### A-K1-05 · Baja · Falta probar el validador de usuario con variantes de `typ` (verificado)
**Riesgo.** La prueba del selector (`SeparacionTokensTests.cs:303-331`) demuestra adónde se reenvía cada token, pero no que el **esquema de usuario** rechace un token bien firmado con `typ` ausente, `jwt` o `JWT `. Esa garantía depende del comportamiento de la biblioteca (4.2, inferido).
**Remediación:** una teoría con `TokenType` = `null` (sin `typ`), `"jwt"`, `"JWT "` y `"disp+jwt"` con la audiencia de usuario y `sub` válido, contra `GET /api/auth/sesion`: debe dar 401 en todos los casos.

## 6. Controles bien implementados
- El esquema selector nunca elige el esquema `Dispositivo` por omisión. Cada esquema valida su propio tipo y su propia audiencia (`Seguridad.cs:256-293`; `Program.cs:70-75`).
- La política por omisión y todas las de usuario vuelven a autenticar con su esquema. `RequiereAlgunPermiso` dejó de ser una política en línea sin esquema (`Seguridad.cs:164-212`).
- `ctx.Fail` cuando falta `sub` (`Program.cs:84-88`). Antes, un token así salía con éxito.
- Falla cerrada sin registro y estado desconocido tratado como revocado (`Seguridad.cs:307`; `AutenticacionDispositivo.cs:116-121`).
- `EsDispositivo` exige el tipo de autenticación **y** `dis`. Un token de usuario no puede hacerse pasar por un dispositivo.
- `Propiedad` va en el validador común y se aplica antes de leer la credencial.
- P-K13 recorre todas las rutas con cada tipo de token y obliga a declarar cada ruta nueva.
- Código y secreto con `RandomNumberGenerator`, solo los hashes guardados, comparación en tiempo constante, mensajes únicos y pertenencia a la empresa en cada sentencia.

## 7. Remediaciones priorizadas
1. **Antes de unir K1 a `master`:** K1-01 y K1-03 de B (frenos de `token` separados por aciertos y fallos, sin escritura en la ruta anónima). Es la condición para aceptar `token` como anónima. B ya la tiene en curso (blueprint 6.3, v-K1 del 2026-10-09). ≈ 0,02 sp.
2. **Al unir la ola 5 o la K1 (la que llegue segunda):** A-K1-01 y A-K1-02 en `ParametrosTokenSesion` y en `ParametrosDispositivo`, con las pruebas. ≈ 0,01 sp.
3. **Con K2:** A-K1-03, A-K1-04 y A-K1-05. ≈ 0,02 sp en total.

## 8. Recomendación: **Aprobado con observaciones**
SD-01 y `Propiedad` cumplen 9.1.1, PF-1 a y c y SD-03. No hay hallazgos Críticos ni Altos. Se recomienda aceptar las dos rutas anónimas en la lista cerrada **con la condición del punto 7.1**. Es una recomendación técnica: la unión a `master` la decide el propietario.

## Supuestos
- No compilé ni ejecuté pruebas (instrucción del encargo). Los resultados 18/18 y 30/30 son los que informa B.
- El comportamiento de `ValidTypes` (ordinal; `typ` ausente rechazado) y de `error_description` en `JwtBearerHandler` es inferido de `Microsoft.IdentityModel` 8.x y ASP.NET Core 10. Lo confirma la prueba propuesta en A-K1-05.
- La introspección se revisó en `origin/b/ola5` porque todavía no está unida a la rama revisada.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: C:\Users\lfmen\source\repos\Solucion GPOS NG\revision-k1-sd01-propiedad-2026-10-09.md
- Supuestos: los de la sección anterior
- Decisiones candidatas a ADR: Ninguna (A-K1-01 aplica S15-08 y PF-1 a, ya firmados)
- Entregas a otros agentes: desarrolladores de B → K1-01 y K1-03 antes de unir, y A-K1-03 a A-K1-05 con K2; quien enganche la ola 5 en A → A-K1-01 y A-K1-02; qa-automatizado → teoría de `typ` de A-K1-05 y prueba de frenos de `token`
- Próximo paso recomendado: que B corrija K1-01 y K1-03, y que el propietario decida la unión de SD-01 con este informe y el de B
