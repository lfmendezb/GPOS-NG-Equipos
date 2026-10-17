# Informe de Seguridad: segunda revisión, sobre el código, de la vía (a′) de ADR-81 (T-j2a a T-j2d)

**Auditor:** auditor-seguridad (equipo C) · **Fecha:** 2026-10-16 · **Tipo:** revisión de código antes de unir (condición de §10 del informe de diseño).
**Objeto:** rama `c/adr81-fase-a`, diff `a5229093..0323a4a5` (`29ef393b` T-j2a, `72fc95de` T-j2b, `b409e1f3` T-j2c, `0323a4a5` T-j2d), en `Solucion GPOS NG/GPOS-C-adr81-fase-a`. Las rutas de este informe son relativas a ese árbol.
**Referencias:** informe de diseño `GPOS-NG-Equipos/traspasos/C/revision-seguridad-via-a-prima-2026-10-16.md` (REQ-C-01 a 13); hoja firmada `hoja-firma-via-a-prima-precisiones-2026-10-16.md` (PA-01 a PA-05 en (a)); blueprint `docs/arquitectura/2026-10-16-adr81-fase-a-blueprint-v4.1.md` (D-J2-01 a 06; P-TJ2-01 a 05 firmadas).
**Método:** lectura del diff y de las piezas que toca. **No compilé ni ejecuté pruebas:** el árbol lo comparte otro agente que construye la Web y MAUI, y una compilación escribiría en `bin/` y `obj/`. Lo que digo de las pruebas sale de leer su código, no de su resultado.
**Sin pasos de explotación, pruebas de concepto ni payloads (C10).**

---

## 1. Alcance y superficie revisada

- **Rutas nuevas (anónimas, solo central):**
  - J2-1 `POST /api/auth/login/recuperacion`;
  - J2-2 `POST /api/auth/login/recuperacion/alta`;
  - J2-3 `POST /api/auth/login/recuperacion/confirmar` (`src/GPOS.Api/Endpoints/RecuperacionFactorEndpoints.cs:28-116`).
- **Ruta nueva autenticada:** J2-4 `POST /api/super/avisos-seguridad/{id}/acuse` (`src/GPOS.Api/Endpoints/AdminEndpoints.cs`, bloque agregado en T-j2d).
- **Cambios en rutas existentes:** `RecuperacionDisponible` en el 202 de `/login` (`AuthEndpoints.cs`) y `Recuperaciones` en `AvisosEntrada` (`SegundoFactorService.cs:385-392`).
- **Criptografía:** función `aut`, `typ` de la recuperación, regla «`aut` sin `latente`» (`LlaveGsf.cs:34, 71`; `VerificadorJws.cs:52`; `ConjuntoLlaves.cs:93`).
- **Núcleo:**
  - lector cerrado, verificador puro, piso y disponibilidad (`src/GPOS.Core/Sistema/SegundoFactor/Recuperacion/*`);
  - orden de los pasos (`RecuperacionFactorService.cs`);
  - transacciones (`SegundoFactorService.Recuperacion.cs`).
- **Esquema:** `dbo.AutorizacionesConsumidas`, `dbo.AcusesAvisoSeguridad`, disparadores 52010 y 52011, `DENY` y purga (`EsquemaSegundoFactor.cs:64-138, 202-203`), y marca 5.
- **Fuera de alcance:**
  - la Web y MAUI (T-j2e y T-j2f), que no están en el diff;
  - el emisor de GSF (REQ-E).

---

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título |
|---|---|---|
| SEG-TJ2-01 | Baja | El 401 uniforme no tiene tiempo uniforme con una cuenta inexistente, inhabilitada o sin contraseña (REQ-C-09, D-J2-03) |
| SEG-TJ2-02 | Baja | El tope de 3 contraseñas por `jti` no se cumple con peticiones en paralelo (REQ-C-10) |
| SEG-TJ2-03 | Baja | `RECUPERACION_FACTOR_RECHAZADA` sin `jti`, `kid` ni huella en los rechazos posteriores a la firma (pasos 5 a 8; desvío declarado) |
| SEG-TJ2-04 | Baja | J2-2 y J2-3 no comprueban la disponibilidad (PA-05, §9.1) ni que la llave siga activa |
| SEG-TJ2-05 | Baja | Después de un reinicio, J2-2 con un desafío ya confirmado devuelve el secreto del factor activo |
| SEG-TJ2-06 | Baja (latente) | `AvisosEntrada.Recuperaciones` se calcula para cualquier cuenta que pase `/login/factor`, no solo para el SUPER |
| SEG-TJ2-07 | Informativo | PF-J2-09 (a) solo se prueba en las rutas GET sin parámetros (desvío declarado). Riesgo nulo por construcción |
| SEG-TJ2-08 | Informativo | Un interbloqueo (1205) en la confirmación responde 500; la prueba lo absorbe |
| SEG-TJ2-09 | Informativo | El recurso de desarrollo no trae la llave `gsf-aut-dev`, así que la vía no se puede probar a mano en Debug |

**No hay hallazgos Críticos ni Altos.** Los cuatro puntos de diseño que podían degradar la vía a un bypass del segundo factor están **cumplidos**:
- REQ-C-01: sin JWT;
- REQ-C-02: reemplazo solo desde el desafío;
- REQ-C-03: una sola transacción;
- REQ-C-04: `typ`, `aud` y lector cerrado.

---

## 3. Verificación de REQ-C-01 a REQ-C-13

| REQ | Estado | Evidencia y nota |
|---|---|---|
| **REQ-C-01**: sin JWT, desafío propio de 10 min y un solo uso | **Cumplido** | **Rutas:** ninguna referencia a `EmisorTokens`, `AbrirSesionAsync` ni `RenovarAsync` (`RecuperacionFactorEndpoints.cs:33-115`); la respuesta de J2-3 es `ConfirmarRecuperacionResponse` solo con códigos (`:107`); la prueba de IL lo vigila (`tests/GPOS.Tests/Arquitectura/RecuperacionSinTokensTests.cs:23-33`, con control positivo en `:35-37`). **Desafío:** propósito `GPOS.Auth.RecuperacionFactor.v1`, `Vida = 10 min` y tipo propio (`DesafiosRecuperacion.cs:24-38` del archivo, clase `DesafiosRecuperacion`). **Un solo uso:** en memoria tras confirmar (`Consumir`) y en la base, con R → C de exactamente una fila (`SegundoFactorService.Recuperacion.cs:170-171`). **Portador:** los dos esquemas son `JwtBearer` con firma y `typ` (`Program.cs:60-75`), así que un texto de Data Protection no se valida como token |
| **REQ-C-02**: reemplazo solo desde el desafío; guardas intactas; el factor vale hasta confirmar | **Cumplido** | `AuthEndpoints.SegundoFactor.cs` no está en el diff (409 `ALTA_NO_CORRESPONDE` intacto). La reserva no escribe en `UsuariosFactor` (`SegundoFactorService.Recuperacion.cs:60-95`). El secreto nuevo viaja cifrado en el desafío (D-J2-05) y no en `SecretoPendienteCifrado`. PF-J2-09 (b) prueba los cruces de desafíos (`RecuperacionFactorHttpTests.cs:236-249`); PF-J2-10 prueba el cambio de teléfono (`RecuperacionFactorServicioTests.cs:357-376`) |
| **REQ-C-03**: una sola transacción al confirmar | **Cumplido** | `SegundoFactorService.Recuperacion.cs:134-177` hace, en una transacción: sello y `jti` en R (`:135-141`), I-4 (`:148-153`), secreto nuevo con bloqueo limpio (`:163-167`, `ConsultasRecuperacionFactor.ReemplazarFactor`), códigos borrados y 10 nuevos (`:168`; `NuevosCodigosAsync` en `SegundoFactorService.cs:429-437` hace `BorrarCodigos`), `InvalidarCredenciales` (`:169`), R → C (`:170-171`), `VolverASellarAsync` con `factorDadoDeAlta: true` (`:173`), evento `OK` (`:174-175`) y `COMMIT` (`:177`). PF-J2-11 incluye el caso del espía que lanza |
| **REQ-C-04**: `typ` propio, `aud`, lector cerrado, sin `crit` | **Cumplido** | `typ` registrado con la función `aut` (`VerificadorJws.cs:52`); `crit` y `b64` rechazados (`VerificadorJws.cs:269`); lector cerrado con todos los miembros obligatorios (`LectorAutorizacionRecuperacion.cs:24-25, 43-51`); `aud` ordinal (`VerificadorAutorizacionRecuperacion.cs:75-76`). Matriz PF-J2-02 en `tests/GPOS.Tests/Criptografia/MatrizTiposJwsTests.cs:51-142` (cruces, `lic` y `upd`, `crit` y `b64`, `aud` ajeno, `typ` reservados sin registrar) |
| **REQ-C-05**: función `aut` y piso por perfil | **Cumplido** | La llave debe ser `aut`, `activa`, no retirada y con el nivel del recurso (`VerificadorAutorizacionRecuperacion.cs:65-67`). Piso: Avanzada solo `avanzado`; `desarrollo` solo en Debug; un perfil desconocido no admite ninguna (`DisponibilidadRecuperacion.cs:29-35`). El perfil es el de P-TJ2-03 (a) (`RecuperacionFactorService.cs:61-66`). `IEstadoLicencia` está registrado (`Program.cs:270`) |
| **REQ-C-06**: instalación verificada con el anillo; usuario; SUPER vigente según la base | **Cumplido** | Lectura en el momento con `ProtectorLicencia` y falla cerrada a 503 (`RecuperacionFactorService.cs:85, 96-97, 161-173`); comparación ordinal (`VerificadorAutorizacionRecuperacion.cs:79, 83`); nivel y habilitación leídos con `UPDLOCK` en la reserva y otra vez en la confirmación (`SegundoFactorService.Recuperacion.cs:65-67, 135-138`) |
| **REQ-C-07**: PK `(Tipo, Jti)`, `INSERT` atómico, sin borrado, forma validada | **Cumplido** | PK y `BIN2` (`EsquemaSegundoFactor.cs:72-90`); 52010 y 52011 (`:97, 108`); `DENY DELETE` (`:202`). La reserva toma `UPDLOCK, HOLDLOCK` y trata 2627/2601 como «ya usada» (`SegundoFactorService.Recuperacion.cs:69-90`). La forma del `jti` se valida en el lector (22 caracteres canónicos que decodifican a 16 bytes) y en un `CHECK`. PF-J2-07 en paralelo (`RecuperacionFactorServicioTests.cs:237-266`). Ver D-J2-01 en §4.10 |
| **REQ-C-08**: reloj protegido, `iat` + 5 min, tope de 4 h constante, restauración | **Cumplido** | `TopeVigencia = 4 h` como `static readonly` (`VerificadorAutorizacionRecuperacion.cs:31`); pasos 7 y 8 en `:88-97`. `IRelojProtegido` registrado (`Program.cs:235`), así que el respaldo a `TimeProvider` de `RecuperacionFactorService.cs:218` no se usa en la API. Con una restauración sin reconciliar o un estado ilegible, 503 (`:98-107`). PF-J2-06 incluye la integración real con restauración y liberación (`RecuperacionFactorHttpTests.cs:319-360`). Nota heredada, no de T-j2: entre una restauración en caliente y su detección (vuelta de 15 s del vigilante) la regla todavía no rige; hace falta ser administrador de la instancia |
| **REQ-C-09**: orden y 401 uniforme | **Parcial** | **Orden:** correcto (§4.1). **Respuesta:** idéntica en estado, `codigo` y `detail` para los pasos 6, 9, 10 y 11 (`RecuperacionFactorEndpoints.cs:119-135`; PF-J2-08 en `RecuperacionFactorServicioTests.cs:270-286`). **Tiempo:** no es uniforme con una cuenta inexistente o inhabilitada: **SEG-TJ2-01** |
| **REQ-C-10**: 3 por `jti`, cupo `login` por IP y 4 KB | **Parcial** | Cupo por IP y tope de 4 KB en las tres rutas (`RecuperacionFactorEndpoints.cs:66, 82, 115`); quemado secuencial probado (`RecuperacionFactorServicioTests.cs:299-318`). **En paralelo, el tope de 3 se puede superar: SEG-TJ2-02** |
| **REQ-C-11**: eventos, aviso persistente, sin JWS ni `otpauth` en registros | **Parcial** | `INICIADA` y `OK` (`A`) y `QUEMADA` (`M`) llevan `jti`, `kid` y huella (`SegundoFactorService.Recuperacion.cs:92, 114, 174-175, 230-231`). `RECHAZADA` está limitado (`EventosSeguridad.cs`, `Limitados`). El aviso va a todos los SUPER hasta su acuse (`ConsultasRecuperacionFactor.cs:89-95`). No hay `HttpLogging` ni registro de cuerpos (búsqueda en `src/GPOS.Api`, sin resultados); la nueva vía no escribe en `ILogger`; PF-J2-12 busca el JWS, la firma, `otpauth` y la clave manual en los registros y en la bitácora (`RecuperacionFactorHttpTests.cs:200-205`). **Falta** el `jti` en los rechazos posteriores a la firma: SEG-TJ2-03 |
| **REQ-C-12**: `SoloCentral`, anónima, sin clase de licencia, `no-store`; cliente sin persistencia | **Parcial (API cumplida)** | `Sitio(SoloCentral)` en el grupo (`RecuperacionFactorEndpoints.cs:30`), y la guarda se aplica a los POST (`SitioRutas.cs:21-37`); `AllowAnonymous`; `SinCache` (`:162-166`); fuera de `RutasLicenciaAprobadas.json`. **La parte del cliente (Web y MAUI) no está en el diff:** queda para la revisión de T-j2e y T-j2f |
| **REQ-C-13**: solo ES256; identidad por `jti` | **Cumplido** | El verificador admite solo ES256 en P1363 (preexistente, sin cambio). La identidad es el `jti` del contenido (PK) y la huella del contenido es solo un dato (`AutorizacionRecuperacion.cs:55-56`). El caso de la firma maleada está en `RecuperacionAutorizacionTests.cs` |

---

## 4. Comprobaciones pedidas

### 4.1 Orden obligatorio (punto 3 del encargo)

**Verificado:**
1. Disponibilidad antes de leer el cuerpo (`RecuperacionFactorEndpoints.cs:37-39`).
2. Tope de 4 KB del cuerpo (`UseLimiteCuerpo`) y de 2 KB del artefacto (`VerificadorAutorizacionRecuperacion.cs:47-50`).
3. Firma con `typ` y función (`:53-61`), con la llave activa y el piso (`:65-69`).
4. Contenido y `aud` (`:72-76`).
5. Instalación (`:79-80`).
6. Usuario (`:83-84`).
7. Vigencia con la hora protegida (`:88-93`).
8. Restauración (`:96-97`; 503 si no está reconciliada, `RecuperacionFactorService.cs:98-107`).
9. `jti` (`RecuperacionFactorService.cs:119-128`).
10. Contraseña con `ValidarAsync`, es decir, el contador de CS-5 (`:134-145`).
11. Cuenta y reserva (`:148-155`).

**Desviación menor:** el cupo de 10 por minuto y usuario se aplica después del paso 8, no después del paso 5 o 6 (`RecuperacionFactorEndpoints.cs:53`). No tiene efecto: los pasos 6 a 8 no tocan cuentas.

**Lecturas antes de la firma:** la fila protegida de la instalación y el estado de la restauración se leen antes de verificar la firma (`RecuperacionFactorService.cs:85-86`). No tocan cuentas (I-23). Una petición anónima cuesta unas 3 lecturas de `GPOS_SYSDATA`, acotadas por el cupo `login` por IP. Aceptable.

### 4.2 Ningún camino emite un JWT ni abre una sesión (punto 2)

**Verificado** en el código (§3, REQ-C-01). `ISelladoCuenta.DespuesDeConfirmarAsync` es un no-op por omisión (`ISelladoCuenta.cs:20`). J2-4 exige un token ya existente; no emite ninguno.

### 4.3 El `jti` (punto 4)

- **Estados P, R, Q y C:**
  - el `CHECK` de coherencia y las transiciones que permite el disparador 52011 son P→P, P→R, P→Q y R→C (`EsquemaSegundoFactor.cs:91-108`);
  - las consultas respetan esas transiciones (`ConsultasRecuperacionFactor.cs:32-56`).
- **Atomicidad en paralelo:**
  - **reserva y confirmación:** correctas (PK, `UPDLOCK, HOLDLOCK`, «exactamente una fila»; PF-J2-07);
  - **conteo de contraseñas erróneas:** no es atómico con la comprobación del paso 9 (SEG-TJ2-02).
- **Quemado tras 3 contraseñas:** correcto en secuencia; en paralelo, ver SEG-TJ2-02.
- **Una restauración no lo revive:**
  - se cumple con la regla `iat ≤ CandadoDesdeUtc` → 422, que sigue vigente después de liberar el candado (J-12; PF-J2-06 de integración);
  - además, `ReconciliarRestauracionSistema` renueva todos los `SelloSeguridad`, lo que mata cualquier desafío emitido antes (`SegundoFactorService.Recuperacion.cs:136-138`).

### 4.4 Desafío de recuperación (punto 5)

- **Propósito propio:** `GPOS.Auth.RecuperacionFactor.v1`, distinto del normal; un tipo de .NET propio; `Reemplazo: true` exigido al abrirlo (`DesafiosRecuperacion.cs`, método `Abrir`).
- **El secreto nuevo va dentro**, cifrado con Data Protection (`RecuperacionFactorEndpoints.cs:61-62`), y se pone a cero en memoria después de usarlo (`:65, 81, 100`).
- **No sirve en las rutas autenticadas:** no es un JWT, y los dos esquemas `JwtBearer` exigen firma HS256 y `typ` (SEG-TJ2-07).

### 4.5 JWS, contraseña y `otpauth` fuera de registros y bitácora (punto 6)

**Verificado** (§3, REQ-C-11):
- la contraseña solo llega a `ValidarAsync` y a `CalcularHashFicticio`;
- el URI `otpauth` solo sale en el cuerpo de J2-2;
- en la bitácora quedan `jti`, `kid`, nivel, huella, `iat` y `exp` (`SegundoFactorService.Recuperacion.cs:230-231`);
- `Dispositivo` lo escribe el usuario, va truncado a 100 caracteres y en parámetros SQL.

### 4.6 PA-05: Release (punto 7)

**Verificado:**
- `LlavesGsf.json` no tiene llaves (`"llaves": []`), así que `DisponibilidadRecuperacion.Disponible` es falsa: 503 antes de leer el cuerpo y `RecuperacionDisponible = false` en el 202. Al arrancar se registra una línea informativa (`Program.cs`, bloque nuevo tras la vigilancia de la restauración).
- Las llaves de desarrollo se rechazan en Release por cuatro barreras independientes:
  1. el recurso de desarrollo solo se incrusta con `DEBUG`, con una guarda de coherencia (`GPOS.Criptografia.csproj:19-30`);
  2. `RecursoLlavesGsf` lo rechaza en Release (`RecursoLlavesGsf.cs:32-33`);
  3. el verificador rechaza los kids de desarrollo (`VerificadorJws.cs:70, 152`);
  4. el piso no admite `desarrollo` fuera de Debug (`DisponibilidadRecuperacion.cs:29-35`).
- Probado con `simularRelease` (`RecuperacionAutorizacionTests.cs:280-283`).

**Observación:** J2-2 y J2-3 no repiten la comprobación (SEG-TJ2-04).

### 4.7 a 4.10 Desvíos declarados por el desarrollador (punto 8)

**4.7 `ResultadoConfirmacionRecuperacion` (en lugar de `ResultadoFactor`): aceptado, y mejor que lo planeado.** Es un tipo cerrado sin campo de token ni de sesión (`SegundoFactorService.Recuperacion.cs:35-48`). Reduce la superficie frente a `ResultadoFactor`, que alimenta la emisión en `/login/factor`.

**4.8 PF-J2-09 (a) probado solo en las rutas GET sin parámetros: aceptado con observación** (SEG-TJ2-07). La autenticación se decide en el middleware, antes del enlace del cuerpo y sin importar el método, y el desafío no puede validarse como JWT. El riesgo es nulo por construcción. Recomiendo ampliar la prueba, sin que eso condicione la unión.

**4.9 `RECHAZADA` sin `jti` en los pasos 3 a 8: aceptado en los pasos 3 y 4, no en los pasos 5 a 8** (SEG-TJ2-03).
- **Pasos 3 y 4:** antes de verificar la firma, o con una firma que no corresponde, no registrar el `jti` es lo que pide SEG-AP-11.
- **Pasos 5 a 8:** la firma **ya verificó**. El blueprint (§4.4) y REQ-C-11 piden el `jti`, el `kid` y la huella: un JWS válido de otra instalación, vencido o anterior a una restauración es justo la señal de un artefacto filtrado que hay que cruzar con el registro de emisiones de GSF (REQ-E-10).

**4.10 D-J2-04 (con el factor bloqueado no se consume el `jti`): aceptado.**
- El bloqueo se comprueba dentro de la transacción de la reserva, después de la contraseña, y se deshace todo (`SegundoFactorService.Recuperacion.cs:73-77`). El 423 solo lo ve quien ya presentó un JWS válido **y** la contraseña correcta. No crea ningún oráculo nuevo: con la contraseña correcta y el factor libre, la respuesta sería 200.
- Riesgo residual (R-J2-03, Baja): quien conozca la contraseña puede bloquear el factor por `/login/factor` y retrasar la recuperación del titular hasta 24 h. Ese atacante ya tiene la contraseña, y quedan las vías (a) y (b).
- **D-J2-01 (dos estados R y C):** revisado. Es correcto y conservador. Con P-TJ2-04 (a), una recuperación abandonada no se reabre.

### 4.11 `SoloCentral` en los nodos (punto 9)

**Cumplido en lo declarativo:**
- `Sitio(OperacionSitio.SoloCentral)` está en el grupo (`RecuperacionFactorEndpoints.cs:30`);
- la guarda rechaza los métodos distintos de GET y HEAD según el rol del sitio (`SitioRutas.cs:21-37`), y las tres rutas son POST;
- con el rol `Ambos` de hoy no rechaza nada: los nodos son de la entrega 2.

`PermitidaConCandado(Candados.Ambos)` es coherente: la vía es una salida con la base restaurada, y el paso 8 exige que la restauración esté reconciliada.

---

## 5. Hallazgos

### SEG-TJ2-01 (Baja). El 401 uniforme no tiene tiempo uniforme con una cuenta inexistente, inhabilitada o sin contraseña

- **Riesgo.** D-J2-03 calcula un hash ficticio en los pasos 6 y 9, pero en el paso 10 `ValidarAsync` devuelve `null` **sin calcular PBKDF2** cuando la cuenta no existe, está inhabilitada o no tiene contraseña. Con una cuenta existente y la contraseña errónea, sí lo calcula. La diferencia es del orden del costo de PBKDF2 (decenas a cientos de ms) y permite distinguir «cuenta inhabilitada o inexistente» de «contraseña errónea». REQ-C-09 lo prohíbe. Lo atenúa que hace falta un JWS válido de GSF para ese usuario, con un máximo de 3 intentos por `jti` (SEG-TJ2-02 aparte).
- **Evidencia.**
  - `src/GPOS.Core/Sistema/UsuariosService.cs:32` (retorno temprano sin hash);
  - `src/GPOS.Core/Sistema/SegundoFactor/Recuperacion/RecuperacionFactorService.cs:134, 141-145`.

  Es el mismo defecto preexistente SEG-AP-14 en `/login`.
- **Remediación (≈ 0,02 sp).**
  - En `ValidarAsync`, calcular `CalcularHashFicticio(clave)` antes de devolver `null` cuando la cuenta no existe, está inhabilitada o no tiene contraseña. Es el patrón que ya usa `ValidarAutorizanteAsync` (`UsuariosService.cs:94-99`). Cierra a la vez SEG-AP-14 en `/login`.
  - Prueba: un doble de `PasswordHasher`, o un contador, comprueba que los cuatro casos de 401 calculan exactamente un PBKDF2.

### SEG-TJ2-02 (Baja). El tope de 3 contraseñas por `jti` no se cumple en paralelo

- **Riesgo.** El paso 9 lee el estado del `jti` **sin bloqueo** y fuera de una transacción. Después, `ValidarAsync` comprueba la contraseña. Solo al final, `ContarClaveErroneaAsync` suma el intento con bloqueo. Varias peticiones simultáneas con el mismo JWS pasan todas el paso 9 y prueban cada una una contraseña antes de que la fila llegue a Q.
- **Qué lo acota:**
  - el cupo de 10 por minuto y usuario, en la memoria de cada instancia;
  - el cupo `login` por IP;
  - CS-5 (5 intentos y 15 minutos de bloqueo). CS-5 actualiza la fila con EF sin control de concurrencia, así que bajo carga simultánea también puede perder incrementos. Esto es preexistente e inferido; no lo verifiqué.

  En la práctica, el tope pasa de 3 a unos 10 intentos por ráfaga y por JWS. REQ-C-10 pide 3.
- **Evidencia.**
  - `RecuperacionFactorService.cs:119-145`;
  - `SegundoFactorService.Recuperacion.cs:101-117`;
  - la prueba `PF_J2_08_tres_claves_erroneas…` es solo secuencial (`RecuperacionFactorServicioTests.cs:299-318`).
- **Remediación (≈ 0,05 sp).**
  - Reservar el intento de forma atómica **antes** de comprobar la contraseña. Sin fila: `INSERT` en P con 1 intento, bajo `UPDLOCK, HOLDLOCK`. En P: `UPDATE … SET IntentosClave += 1 WHERE Estado = 'P' AND IntentosClave < 3`, con exactamente una fila afectada; si ninguna, 401 uniforme.
  - Con la contraseña correcta, P → R. Con la tercera errónea, P → Q.
  - Esto cuenta todos los intentos, incluido el correcto. Si se quieren 3 errores más 1 acierto, basta con subir el `CHECK` a 4.
  - Prueba: 10 J2-1 en paralelo con contraseñas erróneas → `ValidarAsync` se invoca como mucho 3 veces y el `jti` queda en Q.

### SEG-TJ2-03 (Baja). `RECUPERACION_FACTOR_RECHAZADA` sin `jti`, `kid` ni huella en los pasos 5 a 8

- **Riesgo.** Hay rechazos con la firma ya verificada: otra instalación, vencida, `iat` futuro, tope o restauración. En ellos el evento solo lleva el motivo y el usuario del contenido. Se pierde la correlación con el registro de emisiones de GSF (REQ-E-10), que es justo lo que delata un artefacto filtrado o reenviado.
- **Evidencia.**
  - `RecuperacionFactorService.cs:94-102` llama a `RechazoAsync` sin la autorización;
  - `:213-216` solo agrega `jti`, `kid` y huella si `a` no es `null`;
  - el blueprint, §4.4, fila `RECHAZADA`, dice «más `jti`, `kid` y huella si la firma verificó».
- **Remediación (≈ 0,03 sp).**
  - Que `ResultadoAutorizacionRecuperacion` devuelva, en los rechazos posteriores a la firma, un registro de solo lectura con `jti`, `kid` y huella, que el servicio pase a `RegistrarRechazoAsync`. El `jti` ya fue validado por el lector, así que es seguro registrarlo.
  - Tampoco hace falta volver a leer el contenido en `UsuarioJws` (`:197-203`).

### SEG-TJ2-04 (Baja). J2-2 y J2-3 no comprueban la disponibilidad ni que la llave siga activa

- **Riesgo.** El blueprint, §9.1, dice que «J2-1 a J2-3 responden 503 `RECUPERACION_NO_DISPONIBLE` antes de leer el cuerpo», y que «si el perfil sube a Avanzada y solo hay llaves `aut` básicas, la vía se apaga sola». Solo J2-1 lo comprueba. Hay dos casos en que un desafío emitido (que vive hasta 10 min) todavía se puede confirmar:
  - el perfil sube a Avanzada;
  - GSF retira la llave firmante al sospechar un compromiso y se publica el recurso.

  La ventana es corta.
- **Evidencia.** `RecuperacionFactorEndpoints.cs:69-82` y `:85-115`, sin `DisponibleAsync`. El desafío lleva el `Kid` (`DesafiosRecuperacion.cs`, registro `DesafioRecuperacion`), pero nadie lo vuelve a comprobar.
- **Remediación (≈ 0,02 sp).** En J2-2 y J2-3:
  - `if (!await recuperacion.DisponibleAsync(ct))` → 503, igual que en J2-1;
  - en J2-3, además, que `d.Kid` siga activo, no retirado y admisible para el perfil (`PisoLlaveAutorizacion`).

### SEG-TJ2-05 (Baja). Después de un reinicio, J2-2 con un desafío ya confirmado devuelve el secreto del factor activo

- **Riesgo.** J2-2 solo comprueba que el desafío no haya vencido y que no esté en el registro de usados, que vive **en memoria**. No consulta la base. Si la API se reinicia (o hay otra instancia) dentro de los 10 minutos posteriores a la confirmación, J2-2 vuelve a entregar el URI `otpauth` y la clave manual de un secreto que **ya es el factor activo**.
  - Quien tenga el desafío ya conocía ese secreto, así que el impacto depende de que el desafío se filtre: por ejemplo, del almacén del servidor de la Web (T-j2e).
  - Junto con la contraseña, eso es la toma de la cuenta. La probabilidad es baja.
- **Evidencia.**
  - `RecuperacionFactorEndpoints.cs:73-79`;
  - `DesafiosRecuperacion.cs`, `_usados` en memoria (ADR-24).

  J2-3 sí está protegida por R → C en la base (`SegundoFactorService.Recuperacion.cs:139-141`).
- **Remediación (≈ 0,02 sp).** En J2-2, leer el estado del `jti` y exigir R (y opcionalmente el `SelloSeguridad` del desafío, que cambia al confirmar). Es una lectura por clave primaria.

### SEG-TJ2-06 (Baja, latente). Los avisos de recuperación llegan a cualquier cuenta que pase `/login/factor`

- **Riesgo.** `AvisosAsync` agrega `Recuperaciones` sin mirar el nivel de la cuenta (`SegundoFactorService.cs:385-392`), y `AvisosPendientes` devuelve las recuperaciones de **todos** los SUPER (`ConsultasRecuperacionFactor.cs:89-95`). Hoy solo el SUPER llega a `/login/factor` (`AuthEndpoints.SegundoFactor.cs:19`, `RequiereFactor` → SUPER). Cuando la fase B habilite el factor optativo para USER y ADMIN, verían el código de las cuentas SUPER y la causa. Eso sirve para elegir objetivos. El blueprint (§5.1) dice «solo para el SUPER».
- **Remediación (≈ 0,01 sp).** Calcular `Recuperaciones` solo si la cuenta es SUPER: pasar el nivel a `AvisosAsync`, o filtrar en la ruta. Prueba: un ADMIN con factor no recibe `Recuperaciones`.

### SEG-TJ2-07 (Informativo). PF-J2-09 (a) solo en GET sin parámetros

- Riesgo nulo por construcción (§4.8).
- Recomendación, sin condicionar la unión: recorrer todas las rutas autenticadas con todos sus métodos, rellenar los parámetros de ruta con valores ficticios y aceptar como correcta solo la respuesta 401.
- **Evidencia:** `RecuperacionFactorHttpTests.cs:251-266`.

### SEG-TJ2-08 (Informativo). Interbloqueo en la confirmación

- La prueba de 10 confirmaciones en paralelo absorbe el error 1205 (`RecuperacionFactorServicioTests.cs:258-260`). En la ruta, una `SqlException` 1205 no se captura y sale como 500. Falla cerrada (no confirma nada), pero no es la respuesta de catálogo.
- **Remediación:** en J2-3, tratar 1205 como 401 `DESAFIO_VENCIDO`, o reintentar una vez.

### SEG-TJ2-09 (Informativo). Sin llave `gsf-aut-dev` en el recurso de desarrollo

- `LlavesGsf.Desarrollo.json` no trae ninguna llave `aut`. El plan de T-j2a la incluía (blueprint, §14).
- La vía solo funciona en las pruebas (`FabricaRecuperacion`). Quien construye T-j2e y T-j2f no la podrá probar a mano en Debug.
- No es un riesgo; si se agrega, que sea con el prefijo `gsf-aut-dev`, que las cuatro barreras de §4.6 ya cubren.

---

## 6. Controles que están bien implementados

- **Cierre de R-4 por construcción:**
  - clase de rutas aparte, sin emisor de tokens, vigilada por una prueba de IL con control positivo;
  - desafío de Data Protection con propósito, tipo y vida propios;
  - respuesta de confirmación sin token.
- **Verificador puro y cerrado:**
  - el objeto «autorización verificada» no se puede fabricar desde fuera (constructor `internal`);
  - el lector rechaza miembros desconocidos o ausentes;
  - catálogo cerrado;
  - el `aud` y el `typ` atan cada artefacto a su uso;
  - la función `aut` separa estas llaves de las de licencias;
  - una llave `aut` no puede estar `latente`.
- **Transacción de confirmación completa**, en el orden de bloqueos documentado. El sellado (I-16) va dentro de la transacción, y una prueba de espía comprueba que, si falla, no queda nada.
- **Tabla de consumidos inmutable** en tres capas: disparador 52010, disparador 52011 de transiciones y `DENY DELETE`. El `Jti` va en `BIN2`.
- **Falla cerrada en todas las lecturas críticas:** anillo, estado de la restauración y perfil desconocido.
- **Condición de publicación sin interruptor:** la vía depende solo del recurso incrustado; hoy, en Release, está apagada.
- **Higiene de secretos:** el secreto se pone a cero en memoria, la contraseña no sale del servicio y la bitácora guarda la huella del contenido, nunca la firma.

---

## 7. Remediaciones priorizadas

1. **Antes de publicar la vía en Release** (no bloquean la unión, porque la vía está apagada por PA-05):
   - SEG-TJ2-01 (tiempo);
   - SEG-TJ2-02 (tope atómico);
   - SEG-TJ2-04 (disponibilidad en J2-2 y J2-3);
   - SEG-TJ2-05 (J2-2 contra la base).

   Unos 0,11 sp en total (±30 %, inferido).
2. **En la misma tanda, si cabe:** SEG-TJ2-03 (`jti` en los rechazos), SEG-TJ2-06 (avisos solo al SUPER) y SEG-TJ2-08 (1205). Unos 0,05 sp.
3. **Mejora de pruebas:** SEG-TJ2-07.
4. **Revisión aparte:** la parte del cliente de REQ-C-12 (T-j2e y T-j2f) y PF-J2-16.

---

## 8. Recomendación: **Aprobado con observaciones**

Recomiendo unir T-j2a a T-j2d:
- No quedan hallazgos Críticos ni Altos.
- Los requisitos estructurales REQ-C-01 a 08 y 13 están cumplidos con evidencia.
- La vía queda apagada en Release mientras no haya llaves `aut` (PA-05).

Quedan **parciales** REQ-C-09 (tiempo), REQ-C-10 (en paralelo), REQ-C-11 (`jti` en los rechazos) y REQ-C-12 (cliente, pendiente de T-j2e y T-j2f). Los Bajos SEG-TJ2-01, 02, 04 y 05 deben estar corregidos **antes de publicar** la vía (antes del PR que agregue las llaves `aut` al recurso de producción), junto con la constancia de REQ-E-01 a 11 que exige PA-05.

Es una recomendación técnica: la decisión de unir y de publicar es del propietario.

### Supuestos
- No ejecuté la compilación ni las pruebas (árbol compartido). Lo que digo de las pruebas sale de leer su código.
- Que `CandadoDesdeUtc` se conserva después de liberar el candado (J-12) lo tomo del blueprint y de PF-J2-06; no lo verifiqué en el procedimiento.
- La pérdida de incrementos de CS-5 bajo concurrencia (SEG-TJ2-02) es inferida: `ValidarAsync` usa EF sin un token de concurrencia visible en este diff.
- Las magnitudes de tiempo de PBKDF2 son inferidas; no las medí.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\GPOS-C-revision-seguridad-tj2-codigo.md`
- Supuestos: los de la sección anterior
- Decisiones candidatas a ADR: Ninguna
- Entregas a otros agentes: desarrollador de T-j2 → SEG-TJ2-01 a 06 y 08 (≈ 0,16 sp); qa-automatizado → SEG-TJ2-07 y las pruebas nuevas de SEG-TJ2-01, 02, 04, 05 y 06; auditor-seguridad → revisión de T-j2e y T-j2f (REQ-C-12, cliente); devops → que el PR de las llaves `aut` exija estas correcciones y la constancia de REQ-E (PA-05)
- Próximo paso recomendado: unir T-j2a a T-j2d y corregir SEG-TJ2-01, 02, 04 y 05 antes de publicar las llaves `aut`

---

## 9. Verificación de correcciones (2026-10-16, diff `61dd46e8..2737ed20`)

**Método:** solo lectura del diff de los commits `d59cd1e2`, `5432a244`, `50ad2f05`, `08f42ffe` y `2737ed20`. **No compilé ni ejecuté las pruebas.** Cuando digo que una prueba cubre algo, es porque leí su código, no porque la haya visto pasar.

| Hallazgo | Commit | Estado | Evidencia |
|---|---|---|---|
| SEG-TJ2-01 (tiempo del 401) | `d59cd1e2` | **Cerrado** | `UsuariosService.ValidarAsync` calcula el hash ficticio con una cuenta inexistente, inhabilitada o sin contraseña (`UsuariosService.cs`, bloque nuevo tras `FirstOrDefaultAsync`). Cierra también SEG-AP-14 en `/login`, salvo el 423, que ya existía y es una respuesta distinta. La prueba `SEG_TJ2_01_…` usa el contador `HashesFicticios`, interno y solo de lectura |
| SEG-TJ2-02 (tope de 3 en paralelo) | `d59cd1e2` | **Cerrado, con una observación** (SEG-TJ2-10) | El intento se toma de forma atómica **antes** de comprobar la contraseña: `ConsultasRecuperacionFactor.TomarIntento` (`UPDLOCK, HOLDLOCK`; si no hay fila, `INSERT` en P con 1; si la hay, `UPDATE … WHERE Estado = 'P' AND IntentosClave < 3 AND UsuarioCodigo = @u`). Después, `Quemar` hace P → Q con 3 intentos o más y exactamente una fila. La reserva P → R admite que el tercer intento sea el correcto. El resultado depende de que `@@ROWCOUNT` refleje el `UPDATE` aunque se dispare el disparador 52011. No lo comprobé contra el motor, pero la prueba secuencial de 3 intentos más 1 fallaría si no fuera así (inferido). Prueba nueva: `SEG_TJ2_02_diez_claves_erroneas_en_paralelo_solo_comprueban_3_y_queman_el_jti` |
| SEG-TJ2-03 (`jti` en los rechazos) | `5432a244` | **Cerrado** | `VerificadorAutorizacionRecuperacion` construye la `AutorizacionRecuperacion` después de comprobar el `aud`, y los rechazos de los pasos 5 a 8 llevan su `Identidad` (`jti`, `kid`, nivel, huella, usuario, motivo). Los rechazos anteriores a la firma siguen sin identidad, como pide SEG-AP-11. Desaparece `UsuarioJws`, que volvía a leer el contenido |
| SEG-TJ2-04 (disponibilidad en J2-2 y J2-3) | `50ad2f05` | **Cerrado** | `DisponibleAsync` se comprueba antes de leer el cuerpo en J2-2 y J2-3, y `LlaveVigenteAsync(d.Kid)` exige una llave `aut` activa, no retirada y con piso para el perfil actual (`RecuperacionFactorService.cs`, método nuevo; `RecuperacionFactorEndpoints.cs`, J2-2 y J2-3). Las rutas leen el cuerpo a mano después de la comprobación, y siguen con `LimiteCuerpo` |
| SEG-TJ2-05 (J2-2 tras un reinicio) | `50ad2f05` | **Cerrado** | `DesafioRecuperacionVigenteAsync` exige en la base que el `jti` esté en R, que sea de la cuenta y que `SelloSeguridad` sea igual al del desafío. La confirmación renueva el sello, así que un desafío confirmado ya no entrega el secreto. El parámetro `Ansi(sello, 32)` coincide con la columna `varchar(32)` |
| SEG-TJ2-06 (avisos solo para el SUPER) | `08f42ffe` | **Cerrado** | `AvisosAsync` solo agrega `Recuperaciones` si `EsSuperHabilitado` es verdadero según la base |
| SEG-TJ2-08 (interbloqueo) | `50ad2f05` | **Cerrado** | Ante un 1205, J2-3 reintenta una vez; si se repite, responde 401 `DESAFIO_VENCIDO`. La transacción víctima se deshace entera, así que el `jti` sigue en R y no hay doble confirmación: la guarda R → C con exactamente una fila se mantiene |
| SEG-TJ2C-02 (enlace solo para el SUPER) | `2737ed20` | **Cerrado** | `AuthEndpoints.OfrecerRecuperacionAsync`: `u.Nivel == SUPER && DisponibleAsync`. Con otro nivel, la disponibilidad ni se consulta. Prueba `SEG_TJ2C_02_…` |
| SEG-TJ2C-03 (largo en el servidor web) | `2737ed20` | **Cerrado** | `VistaRecuperacionFactor.Pedido`, en la Web y en MAUI: rechaza más de 3000 caracteres tal como llegan, antes de recorrer el texto, y más de 2048 sin espacios, sin llamar a la API. Tiene pruebas en `GPOS.Web.Tests` y en las de MAUI |
| SEG-TJ2-07 y 09 | — | Sin cambio | Informativos, no exigidos |

### 9.1 Desvío declarado de SEG-TJ2-02: se devuelve el intento con CS-5 o con el factor bloqueados

**Factor bloqueado (D-J2-04): no abre nada.** El intento se devuelve después de que la contraseña se comprobó y era **correcta**. No se gasta ninguna conjetura: quien llega a ese punto ya tiene el JWS y la contraseña, y la respuesta 423 no le enseña nada que no sepa.

**Cuenta ya bloqueada por CS-5 al llegar: no abre nada.** `ValidarAsync` lanza la excepción antes de comprobar la contraseña, así que no se prueba ninguna y devolver el intento es lo correcto. `DevolverIntento` es una sentencia atómica con `IntentosClave > 0`: no puede bajar de 0 ni tocar un `jti` en R, C o Q.

**Observación nueva: SEG-TJ2-10 (Informativo).**
- **Qué pasa.** `ValidarAsync` lanza la misma `UsuarioBloqueadoException` cuando es **este** intento, con una contraseña errónea, el que alcanza el máximo de CS-5 y bloquea la cuenta (`UsuariosService.cs`, rama `if (bloquear) throw Bloqueado(...)`). En ese caso se probó una contraseña y el intento del `jti` igual se devuelve. Así, quien combina intentos en `/login` con intentos en la vía puede probar más de 3 contraseñas con el mismo JWS a lo largo de su vigencia: uno devuelto por cada ciclo de bloqueo de 15 minutos.
- **Por qué es solo informativo.** El total de contraseñas probadas sigue acotado por CS-5 (5 cada 15 minutos), el mismo límite que ya tiene `/login` sin ningún JWS. Una contraseña acertada en `/login` ya se delata con el 202. El tope por `jti` es defensa en profundidad y no amplía nada que `/login` no permita ya.
- **Remediación opcional (≈ 0,02 sp).** Devolver el intento solo si la cuenta ya estaba bloqueada al entrar. Por ejemplo, con una marca en la excepción que diga si el intento se contó, o leyendo `BloqueadoHasta` antes de `ValidarAsync`. Si no, contarlo y quemar el `jti` si llega a 3.

### 9.2 Veredicto actualizado

**Aprobado con observaciones** (recomendación técnica; la decisión es del propietario).

- Los nueve hallazgos pedidos están **cerrados**: SEG-TJ2-01 a 06 y 08, y SEG-TJ2C-02 y 03.
- REQ-C-09, 10 y 11 pasan de parciales a **cumplidos**.
- En la parte de la API, REQ-C-12 queda **cumplido**. La parte del cliente está en el informe aparte del cliente.
- Lo único abierto son informativos: SEG-TJ2-07, SEG-TJ2-09 y el nuevo SEG-TJ2-10, que no condiciona la unión ni la publicación.
- La publicación de la vía en Release sigue condicionada por PA-05: las llaves `aut` en el recurso y la constancia de REQ-E-01 a 11.

### Cierre (actualizado)
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\GPOS-C-revision-seguridad-tj2-codigo.md` (se agregó la sección 9)
- Supuestos: no se compiló ni se probó; que `@@ROWCOUNT` refleje el `UPDATE` con el disparador es inferido, y lo cubriría la prueba secuencial
- Decisiones candidatas a ADR: Ninguna
- Entregas a otros agentes: desarrollador de T-j2 → SEG-TJ2-10, opcional (≈ 0,02 sp); devops → condición de publicación PA-05 sin cambios
- Próximo paso recomendado: unir T-j2 y dejar la publicación de la vía pendiente de PA-05
