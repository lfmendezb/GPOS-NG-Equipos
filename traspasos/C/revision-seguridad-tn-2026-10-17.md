# Informe de seguridad: T-n (fase A de ADR-81 conectada sobre SL, RN y SL-F1/F2)

- **Fecha:** 2026-10-17 · **Auditor:** auditor-seguridad (equipo C) · **Modelo:** Opus
- **Rama:** `c/adr81-tn-sobre-rn` @ `fa00c296`, árbol `GPOS-C-tn`
- **Base de lo ya revisado:** fase A (`origin/c/adr81-fase-a` @ `4e5bc446`, informe `traspasos/C/revision-seguridad-fase-a-final-2026-10-16.md`), SL/RN/SL-F1/F2 (`origin/a/sl-resellar-candado` @ `130306c0`, revisados por A). No se repiten sus hallazgos, en particular AR-01 (SLF-01 eludible con `UPDATE`): T-n no lo empeora.
- **Método:** lectura de `git show --cc 717244af 9e0cf8a5`, `git diff 9e0cf8a5 fa00c296` y del código que tocan. **No ejecuté compilación ni pruebas** (equipo inestable). Lo marcado con [I] es inferido por análisis y no se reprodujo.

---

## 1. Alcance y superficie revisada

| Superficie | Qué cambia en T-n | Evidencia |
|---|---|---|
| `POST /api/auth/login` (anónima; con confirmación) | Comprobante v2 de un solo uso + `PuedeConfirmarSesionAsync` del sello de habilitación | `AuthEndpoints.cs:56-70` |
| Validación por petición (todas las rutas autenticadas) | `RevocacionSesiones.Evaluar`: SH-2 antes del nivel y de CS-1; PA-14 trae ahora `PasswordHash` y las columnas del sello | `RevocacionSesiones.cs:175-180`; `ConsultaEstadoSesion.cs`; `UsuariosService.cs:612-628` |
| `UsuariosService.ValidarAsync` y `CambiarClaveAsync` | Sello antes de la contraseña, hash ficticio contado; cambio de clave con el padrón tomado | `UsuariosService.cs:43-100`, `:740-791` |
| `IFactorSuper` real | `FactorSuperUsuariosFactor` en la API y en `GPOS.Migracion` | `FactorSuperUsuariosFactor.cs`; `ConsultasSegundoFactor.cs:33-34`; `Program.cs:283`; `ComandoSellos.cs:60` |
| Enganche del sello en la fase A | `SelladoCuentaSellos` (singleton) con Iniciar / Sellar / Publicar dentro de la transacción de `SegundoFactorService` | `SelladoCuentaSellos.cs`; `UsuariosService.cs:182-243`; `SegundoFactorService.cs:156-208`, `:304-359`; `SegundoFactorService.Recuperacion.cs:149-195` |
| Consola `restablecer-factor` | Usa el sellado de SL; 409 `USUARIO_SIN_SELLO` → «Negado» | `GPOS.Migracion/Program.cs:371-374`; `RestablecimientoFactor.cs:79-87` |
| S-02, S-03 y S-04 (SUPER) | Publicadas con `RequiereSuper`, `SoloCentral`, `RequiereAutenticacionReciente()` | `SellosEndpoints.cs:31-34`; `CambioRncEndpoints.cs:39-41`; `RutasLicenciaAprobadas.json:24` |
| Catálogo de eventos | Una sola convención MAYÚSCULAS_CON_GUION | `EventosSeguridad.cs`; `PadronSellos.cs:59-69`; `CambioRncService.cs:83` |

Fuera de alcance: pantallas S-01/S-05 (tarea 2), R-5 (tarea 3), acta GSF (tarea 4).

---

## 2. Resumen de hallazgos

| ID | Severidad | Título | Estado |
|---|---|---|---|
| TN-01 | **Media** | S-02 (ahora por la API) legitima a un SUPER cuyo factor desapareció de la base: acepta `FactorAlta = false` sin pedir el restablecimiento | Verificado (código); el ataque completo es [I] |
| TN-02 | Baja | Interbloqueo posible entre las acciones serializables del sello (que ahora leen `UsuariosFactor`) y las del factor que no toman el padrón | [I] por análisis de bloqueos |
| TN-03 | Baja | `CambiarClaveAsync`: la relectura descarta la puesta a cero del contador de CS-5 y no comprueba que el hash siga siendo el que se verificó | Verificado |
| TN-04 | Baja | `/login/factor` emite el token sin volver a evaluar el sello de habilitación (`/login` con confirmación sí lo hace) | Verificado |
| TN-05 | Baja | S-02, S-03 y S-04 sin límite de peticiones; las demás acciones SUPER del factor tienen 5 por minuto | Verificado |
| TN-06 | Baja | Transición: un SUPER sellado con `SinFactorSuper` que ya tenga el factor confirmado queda fuera al activar T-n | [I] solo bases de desarrollo |
| TN-07 | Informativa | Estado en memoria de `SelladoCuentaSellos`: la publicación de una operación la puede borrar la siguiente de la misma cuenta, y los caminos que no sellan dejan el contexto sin liberar | Verificado; impacto autocorregible |
| TN-08 | Informativa | El «Negado» de la consola dice «Solo el Super Usuario puede legitimarla» en lugar de mandar a `sellos --legitimar` | Verificado |
| TN-09 | Informativa | `FilaEstadoSesion` (record) lleva `PasswordHash` y el sello: su `ToString()` los imprimiría si alguien la registra | Verificado (hoy no se registra) |

No hay hallazgos Críticos ni Altos.

---

## 3. Checklist OWASP Top 10 (2021)

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | S-02/S-03/S-04 con `RequiereSuper`, `SoloCentral`, `otp` (FiltroFactor) y autenticación reciente; bloqueadas por el candado del sistema (no llevan `PermitidaConCandado`, `ModoCandadoRestauracion.cs:94-106`). Observaciones: TN-01, TN-04, TN-05 |
| A02 Criptografía | Sin cambios de primitivas. El sello del SUPER cubre ahora el estado real del factor (DL-05 (a)). Cumple |
| A03 Inyección | SQL nuevo parametrizado y con tipos (`ConsultasSegundoFactor.cs:33-34`, `nvarchar(30)` en SYSDATA). Cumple |
| A04 Diseño inseguro | TN-01 (legitimación sin distinguir qué campo cambió). Orden de bloqueos: TN-02 |
| A05 Configuración | `ExigirSuper` forzado en Release (`ValidadorTokenPrincipal.cs:66-73`): en Debug, S-02/03/04 quedan solo con contraseña, aceptable. Cumple |
| A06 Componentes vulnerables | Sin paquetes nuevos en el diff. No aplica |
| A07 Autenticación | Sello antes de la contraseña, hash ficticio contado en los dos caminos (`UsuariosService.cs:46`, `:472`). Comprobante v2 con sello CS-1, `amr` y habilitación. Observaciones: TN-03, TN-04, TN-06 |
| A08 Integridad | El padrón se publica en disco solo después del commit (`UsuariosService.cs:240-243`, `SelladoCuentaSellos.cs:61-65`). TN-07 |
| A09 Registro y monitoreo | Catálogo unificado; nada ya grabado se renombra; sin CHECK sobre `Evento`. TN-09 |
| A10 SSRF | No aplica |

---

## 4. Revisión de los puntos que pidió el desarrollador

### 4.1 Conflictos de `/login` con confirmación — cumple
- La confirmación exige a la vez: comprobante v2 canjeado una vez, `PuedeConfirmarSesionAsync` (habilitada y sello válido), el mismo código, `SelloSeguridad` igual al del comprobante y, si la cuenta requiere factor, `amr` con `otp` (`AuthEndpoints.cs:60-70`). Todas las negativas dan el mismo 401 uniforme. Correcto.
- `/login/factor` no tiene la comprobación equivalente: TN-04.

### 4.2 `RevocacionSesiones.Evaluar` — cumple
Orden: cuenta inexistente → inhabilitada → **habilitación (SH-2)** → nivel → revocación → sello CS-1 → sesión y `jti` (`RevocacionSesiones.cs:171-180`). Todas las salidas son 401 para el portador del token; el orden no crea un oráculo. Correcto.

### 4.3 `ValidarAsync` — cumple
Inexistente/inhabilitada/sin hash → `CalcularHashFicticio`; sello no válido → `CalcularHashFicticio`, sin contar el intento y sin revelar el bloqueo; después el bloqueo y la contraseña. El hash real nunca se compara para una cuenta sin sello: no hay oráculo de contraseña. El residual del rehash (devuelve la cuenta aunque la relectura con el padrón falle, `UsuariosService.cs:84-97`) es de SL (SL-04), no de T-n.

### 4.4 PA-14 con `PasswordHash` — cumple, con TN-09
La consulta sigue siendo una búsqueda por la clave primaria, sin caché propia; el hash solo se usa en memoria para evaluar el sello y no sale en `EstadoSesionUsuario`. Con `PasswordHash` nulo se sella sobre `""`, que no coincide: falla cerrado.

### 4.5 `FactorSuperUsuariosFactor` — cumple
- Solo cuenta el secreto confirmado (`SecretoCifrado IS NOT NULL`, que por `CK_UsuariosFactor_Activo` implica `ConfirmadoUtc`). El alta pendiente usa `SecretoPendienteCifrado` (`ConsultasSegundoFactor.cs:42-53`) y no vuelve a sellar: coherente.
- Revisé todas las escrituras de `SecretoCifrado` y los borrados de la fila: confirmación del alta y del cambio de teléfono, recuperación (a′), vías (a) y (b). Todas pasan por `VolverASellarAsync`. La reconciliación de la restauración no cambia la existencia del factor. No hay ningún camino que cambie el estado «dado de alta» sin volver a sellar.
- Sin la tabla devuelve 0. Un borrado de la tabla deja inválidos los sellos con `FactorAlta = true`: falla cerrado.
- **Efecto de seguridad positivo:** hasta T-n, borrar con SQL la fila del factor de un SUPER llevaba su siguiente inicio de sesión al alta forzada, y quien supiera la contraseña podía dar de alta su propio TOTP. Ahora el sello lo impide (DL-05 (a) efectivo). La recuperación de ese caso tiene un hueco: TN-01.

### 4.6 `CambiarFactorAsync` partido y orden de bloqueos — cumple, con TN-02 y TN-07
- Las cinco operaciones toman el padrón (`UPDLOCK, HOLDLOCK`, `ConsultasSellos.cs:21`) como primer recurso de su transacción. Por el `HOLDLOCK`, el `ReadCommitted` de `SegundoFactorService` basta para serializar el padrón. El comentario de `PadronSellos.TomarAsync` («transacción serializable») ya no es exacto, pero el control se mantiene.
- `SellarCambioFactorAsync` relee la fila antes de sellar, así que cubre la contraseña temporal y el sello CS-1 que la fase A escribe con SQL, y comprueba `factorEsperado` contra la base (`UsuariosService.cs:226-237`).
- Publicación en disco y vaciado de la caché solo después del commit; si la transacción revierte, no se publica nada. Lo confirma la prueba `Si_la_operacion_revierte_despues_de_sellar_no_queda_nada_y_la_cuenta_sigue_entrando` (no la ejecuté).
- **Frente al orden único de CLAUDE.md:** ese orden rige los recursos de negocio de las bases de empresa (jornada, almacenes, documentos, configuración, series, NCF, `MovimientoCaja`, `inv_Articulos`). El orden de `GPOS_SYSDATA` (padrón → `Usuarios` → `UsuariosFactor` → códigos → bitácora) usa recursos disjuntos, así que no hay contradicción. S-03 escribe en la empresa en otra transacción, después del commit de SYSDATA, con un solo recurso (`conf.Empresa`). Conviene dejar escrito el orden de SYSDATA (ver Decisiones candidatas).

### 4.7 SUPER sin sello en orden: 409 y «Negado» — cumple, con TN-08
No bloquea la recuperación del único SUPER. La cadena fuera de banda existe:
1. `sellos --legitimar` (consola, guarda del anillo; un SUPER se legitima aunque el cupo sea 0, `ComandoSellos.cs:973-991`);
2. después, `restablecer-factor`;
3. si ningún padrón verifica, `sellos --resellar` con acta.

`SoloDifiereElFactor` admite el caso legítimo en que solo difiere `FactorAlta` (por ejemplo, la fila del factor perdida). Negar en lugar de legitimar dentro de la vía (b) es correcto: la vía (b) no debe ampliar el cupo ni aceptar campos alterados. Falta que el mensaje lo diga (TN-08) y que el procedimiento SL-02 incluya el orden.

### 4.8 `SelladoCuentaSellos` con su propio `SistemaDbContext` — cumple
`SistemaDbContext` no tiene interceptores registrados: `Program.cs:36` solo hace `UseSqlServer(...)` y no hay `OnConfiguring`, `AddInterceptors` ni estrategia de reintento. El contexto propio usa la misma conexión y la misma transacción (`UseTransactionAsync`), así que no se salta nada. No es dueño de la conexión y no la cierra. Observaciones sobre su estado en memoria: TN-07.

### 4.9 S-02, S-03 y S-04 — cumplen, con TN-01 y TN-05
- `RequiereSuper` + `SoloCentral` + `FiltroFactor` (token con `otp`; en Release `ExigirSuper` es obligatorio) + `RequiereAutenticacionReciente()` (5 min). Ninguna lleva código del factor en el cuerpo (P-81A-16 (a)).
- **Clase de licencia:** S-03 `Esencial` (salida de `Invalida`), en la lista aprobada. S-02 y S-04 `Operativa` por omisión, fuera de la lista. **Es correcto:** en solo consulta quedan cerradas (falla cerrado), y la legitimación consume cupo, que no debe crecer con una licencia inválida. La consola queda como vía fuera de banda. S-04 podría ser `Esencial` (no amplía el cupo), pero no hace falta.
- **Candado de restauración:** las tres quedan bloqueadas con el candado del sistema, como pide SL-F1 (a) (legitimar después de liberar).
- **Límite de peticiones:** TN-05.

### 4.10 Catálogo de eventos — cumple
- No hay literales PascalCase persistidos. Los de la licencia solo eran nombres de `EventId` del registro (4711-4718, 4721), que no cambian.
- `ClavesSellos` y `CambioRncService` remiten al catálogo, y `HayCambiosPreviosAsync` sigue buscando `CAMBIO_RNC_SUPER`.
- La tabla no tiene CHECK sobre `Evento`.
- Detalle menor: `Todos` ofrece en el filtro de 5.11 eventos de licencia que nunca se escriben en la bitácora. Es cosmético.

---

## 5. Hallazgos

### TN-01 (Media): S-02 legitima a un SUPER cuyo factor desapareció, sin forzar el restablecimiento
- **Riesgo.** Con T-n, el sello del SUPER cubre `FactorAlta`. Supongamos un atacante con escritura en `GPOS_SYSDATA` (el adversario contra el que existe el sello) que borra la fila de `UsuariosFactor` de un SUPER cuya contraseña conoce. Ese SUPER queda fuera, que es lo correcto, y S-01 lo muestra solo como `CamposNoCoinciden`. Si otro SUPER (ahora por la API, S-02) o un técnico (`sellos --legitimar`) lo legitima, `LegitimarAsync` sella el estado de la fila tal como quedó, con `FactorAlta = false`. En el siguiente inicio de sesión la cuenta va al alta forzada del factor, y quien tenga la contraseña puede dar de alta su propio TOTP. Pasa lo mismo con un `PasswordHash` sustituido. Eso ya existía en SL, pero T-n lo publica por la API y le suma la dimensión del factor, que es la que DL-05 quería proteger.
- **Evidencia.** `SellosService.cs:103-127`: evalúa y vuelve a sellar sin distinguir qué campo difiere; `MotivosCuentaSinSello` (`LicenciaDtos.cs:99-112`) no detalla el campo; `SellosEndpoints.cs:31-34`; `SellosCuentas.cs:78`: sella con el `FactorAsync` real.
- **Remediación (la más barata que lo cierra, unos 0,5 dp):**
  1. S-01 y el verbo deben decir qué campos difieren, solo los nombres (`FactorAlta`, `PasswordHash`, `Nivel`…), comparando el contenido sellado (`Sellos.Leer`) con la fila.
  2. Si la cuenta es SUPER y difieren `FactorAlta` (de `true` a `false`) o `PasswordHash`, S-02 y `--legitimar` responden 409 y mandan a `restablecer-factor` (vía b), que pone una contraseña temporal y deja el factor vacío. Así la contraseña que conocía el atacante deja de servir. Alternativa: que la legitimación de ese caso fije por sí misma `DebeCambiarClave` y una contraseña temporal.
- **Alternativa descartada:** solo avisar en pantalla. El operador legitima igual, porque no tiene cómo saber que se borró el factor.

### TN-02 (Baja, [I]): interbloqueo S → X entre las acciones serializables del sello y las del factor sin padrón
- **Riesgo.** `CambiarClaveAsync`, el rehash de `ValidarAsync`, S-02 y la edición de cuentas (`ConCambioPadronAsync`, serializable) leen `Usuarios` y, para un SUPER, ahora también `UsuariosFactor`. Retienen locks S hasta el final y después actualizan `Usuarios` (S → X). `IniciarAltaAsync` y `RegenerarRespaldoAsync` no toman el padrón: toman U en `Usuarios`, U en `UsuariosFactor` y después X en `UsuariosFactor`. Para la misma cuenta SUPER puede darse el ciclo «T1 espera X en `Usuarios` (U de T2); T2 espera X en `UsuariosFactor` (S de T1)». Antes de T-n, `SinFactorSuper` no leía `UsuariosFactor` y el ciclo no existía. El efecto es un 500 para la víctima del interbloqueo. No da acceso a nada; la probabilidad es baja (el mismo SUPER, dos acciones a la vez).
- **Evidencia.** `UsuariosService.cs:740-760` (Reload + `EvaluarAsync` en serializable); `SellosCuentas.cs:27`, `:39-42`; `SegundoFactorService.cs:106-136` y `:283-293`; `ConsultasSegundoFactor.cs:13`, `:22`.
- **Remediación.** En las acciones serializables del sello, leer la fila de `Usuarios` con `UPDLOCK` justo después del padrón. Así T2 espera en su primer U y no hay conversión. Es una línea en `ConCambioPadronAsync`/`IniciarCambioFactorAsync`. Alternativa descartada: que `IniciarAltaAsync` y `RegenerarRespaldoAsync` también tomen el padrón, porque serializaría todas las altas de la instalación sin necesidad. Conviene una prueba dirigida de concurrencia (QA).

### TN-03 (Baja): `CambiarClaveAsync` pierde la puesta a cero de CS-5 y no compara el hash verificado
- **Riesgo.** `ComprobarClaveActualAsync` pone `IntentosFallidos = 0` en la entidad sin guardar. Después, `ConCambioPadronAsync` hace `Reload` y lo descarta. Tras un cambio correcto, el contador conserva los fallos previos, y un error posterior en `/clave` o en la reautenticación (P-D81-01) puede bloquear antes de tiempo. Además, la contraseña actual se verifica contra el hash leído antes del padrón, y después del `Reload` no se comprueba que el hash siga siendo ese (el rehash sí lo hace con `hashLeido`). Es un artefacto de la unión: la fase A esperaba un `SaveChanges` directo.
- **Evidencia.** `UsuariosService.cs:742`, `:749`, `:790`; comparar con `:84-92`.
- **Remediación.** Dentro del lambda, después del `Reload`: `if (u.PasswordHash != hashVerificado) throw …` y `u.IntentosFallidos = 0; u.BloqueadoHasta = null;`. Unos 0,1 dp con su prueba.

### TN-04 (Baja): `/login/factor` no vuelve a evaluar el sello de habilitación
- **Riesgo.** Entre la contraseña (que sí evalúa el sello) y el código (hasta 5 minutos) el sello puede dejar de verificar, por ejemplo si otro SUPER inhabilita la cuenta o cambia su nivel. `/login/factor` mira `Inhabilitado` y el sello CS-1, pero no la habilitación, y emite el token. La primera petición con ese token da 401 (SH-2 en `RevocacionSesiones`), así que el impacto es mínimo. Es una incoherencia con `/login` con confirmación, que sí la comprueba.
- **Evidencia.** `AuthEndpoints.SegundoFactor.cs:73-74` frente a `AuthEndpoints.cs:64-65`.
- **Remediación.** Agregar `await usuarios.PuedeConfirmarSesionAsync(u, ct)` a la condición de la línea 74 (y de la 37, para el reenvío del desafío). Unos 0,05 dp.

### TN-05 (Baja): S-02, S-03 y S-04 sin límite de peticiones
- **Riesgo.** No hay secreto que adivinar (la autenticación reciente se pide en `/reautenticar`, que ya tiene límite), pero son escrituras críticas del SUPER, y S-03 escribe además en la base de la empresa. Las rutas SUPER hermanas declaran 5 por minuto (`RutasLicenciaAprobadas.json:21-22`). Un token robado dentro de la ventana de 5 minutos podría repetirlas sin freno, aunque cada una deja su evento crítico.
- **Evidencia.** `SellosEndpoints.cs:33-34`; `CambioRncEndpoints.cs:40-41`.
- **Remediación.** `.RequireRateLimiting(...)` con la misma política de las rutas SUPER del factor. Unos 0,05 dp.

### TN-06 (Baja, [I]): transición de sellos hechos con `SinFactorSuper`
- **Riesgo.** Una base sellada por SL (en Debug, el sellado ocurre al arrancar) cuando el SUPER ya tenía el factor confirmado, por haber usado antes la rama de la fase A, tiene `FactorAlta = false` en el sello y 1 en la tabla. Con T-n, ese SUPER no entra: falla cerrado, y se recupera con `sellos --legitimar`. Con el orden de unión firmado (SL antes que la fase A en `master`) no debería darse en instalaciones nuevas. Hoy todo es desarrollo.
- **Remediación.** En la nota de unión del #57: correr `GPOS.Migracion verificar` después de unir y legitimar los SUPER que salgan con `CUENTA_SIN_SELLO`. Sin código.

### TN-07 (Informativa): estado en memoria de `SelladoCuentaSellos`
- `TomarPadronAsync` hace `_porPublicar.TryRemove(usuario)`. Si una segunda operación de la misma cuenta empieza entre el commit de la primera y su `DespuesDeConfirmarAsync`, la publicación de la primera se pierde. La segunda publica la suya si confirma; si revierte, la copia del disco queda una versión atrás y la caché, hasta 15 s vieja. La regla «prevalece la mayor versión», con la reposición al leer, lo corrige sola, pero durante ese rato la protección contra el retroceso de la base va un paso atrás.
- Los caminos de la confirmación que no llegan a sellar (alta vencida, código incorrecto, secreto ilegible) dejan el `EnCurso` y su `SistemaDbContext` sin liberar hasta que el recolector libera la transacción (`ConditionalWeakTable`). La conexión no es suya, así que no hay fuga de conexiones.
- **Evidencia.** `SelladoCuentaSellos.cs:30-31`, `:35`, `:63`; `SegundoFactorService.cs:166-187`.
- **Remediación (opcional).** Guardar la publicación pendiente por transacción, o con un identificador de operación en lugar de la cuenta, y liberar el `EnCurso` en un `finally` desde `TerminarAsync`.

### TN-08 (Informativa): mensaje de la consola
`RestablecimientoFactor` devuelve el mensaje de `SinSello`: «Solo el Super Usuario puede legitimarla» (`UsuariosService.cs:251-252`, `RestablecimientoFactor.cs:82-87`). En la consola, el paso correcto es `sellos --legitimar <código>` y después repetir. Conviene un mensaje propio de la vía (b), y documentar el orden en el procedimiento SL-02.

### TN-09 (Informativa): `FilaEstadoSesion` lleva el hash
El `ToString()` generado del record incluye `PasswordHash` y `SelloHabilitacion` (`ConsultaEstadoSesion.cs:59-61`). Hoy no se registra en ningún sitio. Para evitar una fuga futura a los registros: `PrintMembers` propio, o una clase sin `ToString` automático.

---

## 6. Controles bien implementados
- **DL-05 (a) efectivo:** el sello del SUPER refleja el factor real en la API y en la consola. Cierra el alta forzada después de borrar la fila del factor (salvo lo que señala TN-01).
- Padrón tomado como primer recurso en las cinco operaciones de la fase A que cambian el factor. Relectura antes de sellar y comprobación de `factorEsperado`. Publicación solo después del commit.
- Negar sin legitimar en todas las operaciones del factor y en la vía (b). Ninguna amplía el cupo.
- Sello antes de la contraseña, con hash ficticio contado y sin contar el intento. Comprobante v2 con tres ataduras (CS-1, `amr` y habilitación).
- S-02/S-03/S-04 con el conjunto completo SUPER + central + `otp` + autenticación reciente, cerradas con el candado y con la clase de licencia coherente.
- Pruebas de arquitectura que fijan el mapeo exacto de las rutas y su ausencia de la lista aprobada (`SellosEnLaApiTests`), y pruebas HTTP de la autenticación reciente y del ADMIN rechazado (`SellosFactorHttpTests.cs:59-96`).
- Catálogo único sin renombrar nada persistido.

---

## 7. Remediaciones priorizadas

| # | Hallazgo | Quién | Esfuerzo | Cuándo |
|---|---|---|---|---|
| 1 | TN-01: detalle de campos en S-01 y negativa de la legitimación del SUPER con `FactorAlta`/hash cambiados | Desarrollador (SL/T-n) | ~0,5 dp | Antes de la primera instalación de cliente; puede ir en un PR siguiente si el propietario lo acepta |
| 2 | TN-03: contador y hash verificado en `CambiarClaveAsync` | Desarrollador C | ~0,1 dp | En este PR o el siguiente |
| 3 | TN-02: `UPDLOCK` en la lectura de `Usuarios` bajo el padrón + prueba de concurrencia | Desarrollador C + QA | ~0,2 dp | Antes del corte |
| 4 | TN-04 y TN-05: comprobación de habilitación en `/login/factor` y límite de peticiones en S-02/03/04 | Desarrollador C | ~0,1 dp | En este PR |
| 5 | TN-06 y TN-08: nota de unión y mensaje de la consola; orden en SL-02 | Desarrollador C, documentador | ~0,1 dp | Al unir el #57 |
| 6 | TN-07 y TN-09 | Desarrollador C | ~0,15 dp | Opcional |

Total aproximado: 1,1 dp.

---

## 8. Recomendación: **Aprobado con observaciones**

No quedan hallazgos Críticos ni Altos. TN-01 (Media) no tiene que cerrarse para unir, porque hoy no hay instalaciones de cliente y la legitimación exige un SUPER con factor y autenticación reciente o acceso al servidor. Sí debe resolverse, o aceptarse por escrito, antes de la primera instalación de cliente. Es una recomendación técnica: la decisión de unir es del propietario.

---

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\revision-seguridad-tn-2026-10-17.md`
- Supuestos: no compilé ni ejecuté pruebas; TN-02, TN-06 y la cadena completa de TN-01 son inferidas; «hoy todo es desarrollo» (memoria del proyecto) para graduar TN-01 y TN-06.
- Decisiones candidatas a ADR: (1) precisión de ADR-83: la legitimación de una cuenta SUPER cuyo sello difiere en `FactorAlta` o `PasswordHash` no se acepta y pasa por el restablecimiento (TN-01); alternativa descartada: solo avisar. (2) Dejar escrito el orden de bloqueos de `GPOS_SYSDATA` (padrón → `Usuarios` con `UPDLOCK` → `UsuariosFactor` → códigos → bitácora) como complemento del orden único de ADR-45, que rige las bases de empresa; alternativa descartada: que todas las acciones del factor tomen el padrón.
- Entregas a otros agentes: desarrollador C → TN-01 a TN-05 y TN-08; qa-automatizado → prueba de concurrencia de TN-02 y prueba de TN-03; documentador → orden `--legitimar` → `restablecer-factor` en SL-02 (TN-08) y nota de unión (TN-06).
- Próximo paso recomendado: corregir TN-03, TN-04 y TN-05 en esta rama y llevar TN-01 a firma del propietario antes de unir el #57.
