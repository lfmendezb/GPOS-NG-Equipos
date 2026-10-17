# Informe de seguridad: pieza SL «Sello y padrón» (licencia, lote 2)

- **Fecha:** 2026-10-17 · **Auditor:** auditor-seguridad (v3.1.0)
- **Árbol:** `GPOS-NG-sl`, rama `a/sl-sello-padron`, `git diff e80f4654..27d49c95` (23 archivos; `994e0fcb` implementación, `27d49c95` pruebas). HEAD verificado: `27d49c95`.
- **Referencias:** `[BP]` blueprint-licencia-lote2-2026-10-14.md (§2 SH-1 a SH-7, §2.3, §2.4, §5, §6.3, §8); `[SEG]` revision-seguridad-blueprint-licencia-lote2-2026-10-14.md; hoja firmada DL-01 a DL-05.
- **Modo:** solo lectura. No ejecuté compilación ni pruebas (límite de agentes con carga en el equipo); las afirmaciones sobre el código son [V] por lectura, y las de comportamiento en ejecución son [I] salvo que las cubra una prueba citada.
- **Recomendación técnica:** **Aprobado con observaciones**. Pendiente de firma del propietario (C2).

---

## 1. Alcance y superficie revisada

| Superficie | Archivos |
|---|---|
| Inicio de sesión, confirmación de sesión y autorizante (anónimos) | `UsuariosService.cs` (`ValidarAsync`, `SelloEnOrdenAsync`, `ValidarAutorizanteAsync`, `PuedeConfirmarSesionAsync`); `AuthEndpoints.cs:56-58` |
| Validación por petición | `RevocacionSesiones.cs:88`; `UsuariosService.EstadoSesionAsync` |
| Administración de cuentas (ADMIN o SUPER) | `UsuariosService.GuardarAsync`, `CambiarClaveAsync`, `ResellarAsync`, `LicenciaAsync` |
| Rutas del SUPER | `SellosEndpoints.cs` (S-01 publicada; S-02 y S-04 sin mapear) |
| Sello y padrón | `SellosHabilitacion.cs`, `PadronSellos.cs`, `SellosCuentas.cs`, `SellosService.cs`, `FactorSuper.cs`, `ConsultasSellos.cs` |
| Arranque | `Inicializacion.cs` (sellado de desarrollo), `Program.cs` (registro) |
| Verbos de servidor | `GPOS.Migracion/Program.cs`, `ComandoSistema.cs`, `Sellos/ComandoSellos.cs` |
| Pruebas | `SellosEnLaApiTests.cs`, `SellosPadronTests.cs`, `SellosHabilitacionTests.cs`, `SellosHttpTests.cs` |

Modelo de amenazas que aplico (el de `[BP]` §2.2 y §2.5): un `sysadmin` de SQL **sin** acceso al sistema de archivos del servidor de la API no debe poder ampliar el cupo, fabricar o tomar una cuenta, ni volver atrás el padrón. Un administrador de Windows con el anillo es el residual aceptado (CP-4, R-S2).

### Verificación de lo que declara el desarrollador

| Declaración | Resultado | Evidencia |
|---|---|---|
| El sello lleva instalación, código, nivel, habilitación, huella de 8 bytes de empresa y sucursal (solo con restricción), SHA-256 del `PasswordHash` y `FactorAlta` (solo SUPER) | **Verificado** | `SellosHabilitacion.cs:53-63`, `:110-114`, `:155`, `:158-159` |
| `IFactorSuper` devuelve false hasta la fase A de ADR-81 | **Verificado** | `FactorSuper.cs:21-26`; `Program.cs:255` |
| Padrón en `Configuracion` como fuente del cupo; cambios por diferencias con `UPDLOCK, HOLDLOCK` en transacción serializable | **Verificado** (ver SL-04 para la única escritura que no relee la fila dentro del bloqueo) | `ConsultasSellos.cs:21`; `PadronSellos.cs:292-302`, `:132-146`; `UsuariosService.cs:251-253`, `:291-296`; `SellosService.cs:264-270` |
| Copia en disco `Licencia\padron` con reemplazo atómico; prevalece la mayor versión que verifica | **Verificado**, con una desviación del blueprint: falta el evento cuando el archivo falta (SL-01) | `PadronSellos.cs:326-334`, `:386-406` |
| Inicio de sesión: sello antes que contraseña y bloqueo, hash ficticio, sin contar el intento | **Verificado** | `UsuariosService.cs:46` (antes de `:48` y `:50`), `:90`; prueba `SellosPadronTests.cs:175`, `:197` |
| Autorizante igual | **Verificado** | `UsuariosService.cs:191-198` |
| 401 por petición vía `RevocacionSesiones` con caché de 15 s | **Verificado** | `RevocacionSesiones.cs:88`; `UsuariosService.EstadoSesionAsync`; caché global `PadronSellos.cs:187`, `:249-286` |
| S-01 solo para el SUPER; S-02 y S-04 construidas y sin mapear | **Verificado** | `SellosEndpoints.cs:25-26`, `:31-37`; prueba `SellosEnLaApiTests.cs:45-53` |
| Sellado al arrancar solo en Debug; evento 5142 en Release | **Verificado** | `Inicializacion.cs:19-23`, `:29`, `:44-56`; `ComprobarDebugCoherente` en `GPOS.Api.csproj:41` |
| Verbos `sistema --cuentas-iniciales --confirmar-sellado --motivo`, `sellos --purgar`, `verificar` | **Verificado** | `GPOS.Migracion/Program.cs` (casos `sistema` y `sellos`); `ComandoSellos.cs:63-158` |
| El inicio de sesión de una cuenta inexistente sigue sin hash ficticio | **Verificado** (también para cuentas inhabilitadas y sin hash) | `UsuariosService.cs:42` |

---

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título |
|---|---|---|
| SL-01 | Media | La copia del padrón en el disco puede faltar o quedar atrás sin ningún evento: SEG-L2-07 se anula sin rastro |
| SL-02 | Media | La restauración legítima de `GPOS_SYSDATA` deja cuentas fuera, el SUPER incluido, y no hay vía de recuperación construida |
| SL-03 | Media | Cambiar un campo sellado de una cuenta inhabilitada (o al inhabilitarla) deja un sello que ya no es propio: la cuenta no se puede rehabilitar |
| SL-04 | Baja | El hash rehecho al entrar escribe el padrón con la fila leída fuera de la transacción |
| SL-05 | Baja | Oráculo de existencia por tiempo (anterior a SL) y por bloqueo; conviene cerrar el de tiempo aquí |
| SL-06 | Baja | El sellado inicial no revalida dentro de la transacción que el padrón no existe; el de Debug lo reconstruye desde las filas |
| SL-07 | Baja | `UsuariosService` falla abierto si se construye sin `SellosCuentas` |
| SL-08 | Baja | `USUARIO_SIN_SELLO`: registro crítico sin límite y respuesta 500 si falla la bitácora con un error que no es de SQL |
| SL-09 | Baja | La regla «debe quedar un SUPER/ADMIN habilitado» cuenta filas, no entradas del padrón |
| SL-10 | Baja | El 409 `PADRON_NO_DISPONIBLE` expone detalles internos |

No hay hallazgos Críticos ni Altos. No encontré ninguna vía de Release que cree o selle cuentas sin el verbo y el anillo, ni código del sello que lea configuración o entorno para saltarlo (ver §4, «Comprobaciones pedidas»).

---

## 3. Checklist OWASP (Top 10 2021)

| Categoría | Resultado |
|---|---|
| A01 Control de acceso roto | Cupo desde el padrón, por diferencias y en serie: correcto. S-01 con `RequiereSuper` y `SoloCentral`. S-02 y S-04 no publicadas. `GuardarAsync` no legitima (SH-6). Observaciones: SL-04 y SL-09 |
| A02 Fallas criptográficas | Data Protection con propósitos separados (`GPOS.Usuarios.Sello.v1`, `GPOS.Usuarios.Padron.v1`) y anillo protegido con certificado (H-17 v2). La huella de 96 bits del padrón y la de 64 bits de la sucursal van dentro de contenido autenticado: no son la protección. Sin hallazgos |
| A03 Inyección | Todo el SQL nuevo es parametrizado (`ConsultasSellos.cs`; `ComandoSellos.cs:121-126`, `:151-153`). Sin hallazgos |
| A04 Diseño inseguro | SL-01 (detección del retroceso), SL-02 (recuperación), SL-03, SL-06 |
| A05 Configuración insegura | Sin interruptores del sello. La única configuración que influye es la carpeta `GPOS:Licencia:Carpeta` (SL-01) |
| A06 Componentes vulnerables | No aplica: la pieza no agrega paquetes |
| A07 Identificación y autenticación | Orden sello→contraseña correcto (SEG-L2-17). Residuales: SL-05 (oráculos de existencia) y SL-08 |
| A08 Integridad de software y datos | El sello cubre lo que exige SH-5 y DL-05 (a). Padrón con versión monótona y copia en disco. SL-01 y SL-06 |
| A09 Registro y monitoreo | Eventos `USUARIO_SIN_SELLO`, `PADRON_RETROCEDIDO`, `SELLADO_INICIAL`, `CUENTAS_INICIALES_CREADAS`, `PADRON_PURGADO` con actor y SID. Faltan el evento del disco ausente (SL-01) y el aviso al SUPER (SL-02); SL-08 |
| A10 SSRF | No aplica |

---

## 4. Hallazgos

### SL-01 · Media · La copia del padrón en el disco puede faltar o quedar atrás sin ningún evento

- **Riesgo.** El control de SEG-L2-07 depende de que exista la copia del disco. Hoy, si falta o no verifica, `Resolver` elige la base y reescribe el disco **en silencio**:
  - borrar el archivo `padron`, o apuntar `GPOS:Licencia:Carpeta` a otra carpeta, y después volver atrás la base deja entrar los estados anteriores (por ejemplo, las cuentas de antes de una reducción de cupo) sin ningún rastro;
  - si la API no puede escribir el disco (permisos de la carpeta, disco lleno), solo queda un `LogError` por intento, y la protección se reduce a la base sin que nadie lo sepa;
  - `GPOS.Migracion` lee la carpeta de su propia configuración (`GPOS.Migracion.json` y variables), no de la de la API. Si no coinciden, el sellado inicial y `sellos --purgar` escriben la copia en otra carpeta, y la comprobación de SH-7 «el padrón no existe en el disco» mira la carpeta equivocada [I: depende de cómo se instale].
  - `[BP]` §2.3 lo exige: «Si falta el archivo, se reescribe desde la base **y se registra el evento**». Es una desviación verificada.
  - Borrar el archivo exige acceso de Windows, que es el residual R-S2. Pero R-S2 dice «no se impide: **se detecta**», y aquí no se detecta.
- **Evidencia.** `PadronSellos.cs:330-333` (con `enDisco` null gana la base y `ReescribirDisco` es true, sin evento); `:401-405` (falla de escritura: solo registro); `Program.cs:216-217` (carpeta desde la configuración); `ComandoSellos.cs:32-33` (carpeta de la configuración de `GPOS.Migracion`); `SellosService.cs:162`.
- **Remediación (unos 0,25 dp; USD 0).**
  1. En `Resolver`/`VigenteAsync`: si la base verifica con `Version > 1` (o existe `Licencia.SelloInicial`) y el disco falta o no verifica, registrar un evento crítico nuevo (`PADRON_DISCO_AUSENTE`, `EventId` 5143) en la bitácora y en el registro, una vez por proceso o con el limitador. Después reescribir, como hoy.
  2. Si `EscribirDisco` falla dos lecturas seguidas, el mismo evento con «no se pudo escribir».
  3. `verificar` y los verbos imprimen la ruta de la carpeta que usan. El instalador fija la misma clave para la API y para `GPOS.Migracion` (entrega a devops).
- **Alternativa descartada:** negarse a operar si falta el archivo. Es más fuerte, pero rompe la primera reescritura legítima tras una caída entre el commit y la escritura, y convierte un borrado en denegación de servicio. Detectar es lo que firma R-S2.

### SL-02 · Media · La restauración legítima de `GPOS_SYSDATA` deja cuentas fuera y no hay vía de recuperación

- **Riesgo.** Al restaurar una copia de seguridad de `GPOS_SYSDATA`, la base vuelve a una versión del padrón menor que la del disco. La API usa la del disco y la repone (`PADRON_RETROCEDIDO`). Esto es lo que SEG-L2-07 pide. Las consecuencias [V por lectura; sin prueba de punta a punta]:
  - toda cuenta cuyo sello cambió después de la copia (cambio o restablecimiento de contraseña, hash rehecho, cambio de nivel o de sucursal, rehabilitación) queda `FueraDePadron` y no entra. **Puede ser el SUPER**: por ejemplo, si cambió su contraseña después de la copia;
  - con la base del sistema restaurada, el candado de restauración solo deja entrar al SUPER (`AuthEndpoints.cs:73-75`). Si el SUPER quedó fuera, nadie entra;
  - la recuperación prevista es `sellos --legitimar` (pieza RN) o S-02, y **ninguna existe todavía** (`ComandoSellos.cs:26`, `:94-95`; `SellosEndpoints.cs:31-37`). El mensaje de `Inicializacion.cs` ya manda a «legitímelo en el servidor»;
  - la única salida hoy es borrar la copia del disco, que es justo el retroceso que SL-01 no detecta. Es probable que un técnico bajo presión la descubra y la use como procedimiento;
  - `[BP]` §2.3 dice «se registra `PadronRetrocedido` **y se avisa al SUPER**». El evento existe (`PadronSellos.cs:345-352`), pero no hay aviso en S-01 ni en Diagnóstico.
  - Lo mismo pasa con `sistema --cuentas-iniciales` en una instalación ya sellada (por ejemplo, si se borró el GSF): crea una cuenta sin sello que nadie puede legitimar.
- **Severidad.** Es disponibilidad, no una evasión: la pieza falla cerrada, que es lo correcto. Queda en Media porque hoy todo es desarrollo (no hay instalaciones de cliente), y no bloquea esta pieza.
- **Evidencia.** `PadronSellos.cs:269-273`, `:330`; `SellosCuentas.cs:31-36`; `ComandoSellos.cs:94-95`; `Inicializacion.cs` (mensaje de `EventoSinSuperUsuario`).
- **Remediación.**
  1. **Condición previa a la primera instalación de cliente o al primer uso del procedimiento de restauración de H-11 fuera de desarrollo:** unir la pieza RN con `sellos --legitimar` (cupo desde el padrón, motivo, evento con el SID). Ya está estimada en RN.
  2. Procedimiento escrito en `docs/operaciones/` para la restauración de `GPOS_SYSDATA`: `verificar`, después `sellos --legitimar` de cada cuenta legítima con acta y `sellos --purgar` de las `FilaAusente`. Debe decir de forma explícita que **no** se borra el archivo `padron` (unos 0,25 dp, documentador y devops).
  3. Aviso de `PADRON_RETROCEDIDO` y de `PADRON_DISCO_AUSENTE` en S-01 o Diagnóstico para el SUPER (unos 0,1 dp).
  4. Prueba de QA: restaurar una copia anterior a un cambio de contraseña del SUPER y comprobar el resultado y la recuperación con el verbo.

### SL-03 · Media · Cambiar un campo sellado de una cuenta inhabilitada deja un sello que ya no es propio

- **Riesgo.** `SellarAsync` no vuelve a sellar una cuenta que queda inhabilitada: solo retira la entrada. `GuardarAsync` aplica antes los cambios del formulario. Si el ADMIN inhabilita una cuenta y en el mismo guardado cambia su contraseña, su nivel o su sucursal restringida (o edita esos campos de una cuenta ya inhabilitada), el sello deja de coincidir con la fila. Al rehabilitarla, `SelloPropioAsync` da false y la respuesta es 409 `USUARIO_SIN_SELLO`. La única salida sería legitimar, que hoy no existe (SL-02).
  - No es una evasión: falla cerrada. Pero deja cuentas legítimas irrecuperables por una acción normal de la API, y empuja a soluciones por SQL.
- **Evidencia.** `SellosCuentas.cs:61-65` (rama `Inhabilitado`: `Quitar` y `return`, sin sellar); `UsuariosService.cs:280-285` (la comprobación del sello se omite si `dto.Inhabilitado`), `:312-321` (cambios aplicados), `:353-357`. Ninguna prueba cubre «inhabilitar y cambiar la clave en el mismo guardado».
- **Remediación (unos 0,1 dp).** En `GuardarAsync`, antes de aplicar el DTO, calcular `propioAntes = SelloPropioAsync(...)` o `Evaluar == Valido`. Si la cuenta termina inhabilitada y `propioAntes` es true, sellarla con `SellarInhabilitadaAsync`: queda fuera del padrón, sin cupo ni acceso. Si `propioAntes` es false, no se sella: así se respeta SH-6. Agregar la prueba.

### SL-04 · Baja · El hash rehecho al entrar escribe el padrón con una fila leída fuera de la transacción

- **Riesgo.** `ValidarAsync` lee la fila sin transacción, compara la contraseña (PBKDF2, unos cientos de ms) y solo después abre la transacción serializable y toma el padrón para rehacer el hash. No relee la fila ni vuelve a evaluar el sello dentro del bloqueo, a diferencia de `CambiarClaveAsync` (`:572-573`). Si en ese intervalo un ADMIN inhabilita la cuenta, cambia su nivel o restablece su contraseña:
  - el padrón vuelve a recibir la entrada de una cuenta inhabilitada (consume cupo);
  - o se sella con el nivel viejo (la cuenta queda `CamposNoCoinciden`);
  - o el restablecimiento de contraseña del ADMIN se pierde. Esta última parte ya pasaba antes de SL.
  - La probabilidad es baja: solo ocurre una vez por cuenta, con hashes anteriores a H-15, y en concurrencia con una acción del ADMIN.
- **Evidencia.** `UsuariosService.cs:41`, `:67-76`; comparar con `:570-576`.
- **Remediación (unos 0,05 dp).** Dentro del delegado: `ReloadAsync` de la fila y `EvaluarAsync(db, u, cambio) == Valido`. Si no es válido, no rehacer el hash; si cambió el hash, no tocarlo. Es el mismo patrón de `CambiarClaveAsync`.

### SL-05 · Baja · Oráculo de existencia por tiempo y por bloqueo

- **Riesgo.**
  - **Tiempo** (anterior a SL, verificado): una cuenta inexistente, inhabilitada o sin hash responde sin PBKDF2, y una existente con PBKDF2. La diferencia (unos 100 a 300 ms [I]) revela qué códigos existen y cuáles están inhabilitados.
  - **Bloqueo:** una cuenta sellada se bloquea tras N intentos y da otra respuesta. Una inexistente, o una sin sello, nunca se bloquea. Es un oráculo de existencia, y de «tiene sello», que no depende del tiempo.
  - El valor para un atacante es bajo: los códigos son de baja entropía (ADMIN, GSF, CAJERO1) y el inicio de sesión está limitado a 20 por minuto por IP (`LimitesPeticiones.cs:14`).
- **¿Conviene cerrarlo aquí?** **Sí, el de tiempo.** Es una línea en la misma función que esta pieza ya toca y que declara «sin oráculo por tiempo» (SEG-L2-17). No cuesta más CPU que una contraseña incorrecta, y el limitador acota el abuso. El del bloqueo se deja como residual aceptado y documentado: cerrarlo exige bloquear también códigos inexistentes (estado por código arbitrario, con riesgo de agotar memoria), y no compensa.
- **Evidencia.** `UsuariosService.cs:42` frente a `:90` y `:193`; prueba `SellosPadronTests.cs:197` (solo cubre «sin sello» frente a «contraseña incorrecta»).
- **Remediación (unos 0,05 dp).** En `:42`, verificar `HashFicticio` antes de `return null`, como hace `ValidarAutorizanteAsync:191-195`. Extender la prueba de tiempo a las cuentas inexistentes e inhabilitadas.

### SL-06 · Baja · El sellado inicial no revalida dentro de la transacción; el de Debug reconstruye el padrón

- **Riesgo.**
  - `SellarInicialAsync` comprueba las condiciones de SH-7 **antes** de abrir la transacción. Dentro de ella solo vuelve a mirar `Licencia.SelloInicial`. Después, `Crear()` descarta las entradas del padrón tomado y conserva su versión.
  - Si entre la comprobación y la transacción aparece un padrón o una licencia aceptada (por ejemplo, la API corriendo en paralelo), el sellado reconstruye el padrón desde las filas, que es lo que `[BP]` §2.3 prohíbe («nunca se reconstruye»). La ventana es pequeña y la abre un técnico [I].
  - En Debug (`desarrollo: true`) esto es deliberado (R-S3): si alguien borra la fila `Licencia.SelloInicial`, el siguiente arranque vuelve a sellar todas las filas, incluidas las insertadas, y el padrón nuevo gana al del disco por versión. Solo es grave si se despliega un binario Debug, que ya es un riesgo general del proyecto (`#if DEBUG` en `LlaveGsf.cs:78`, entre otros) y lo cubre DL-02.
- **Evidencia.** `SellosService.cs:176-186`; `PadronSellos.cs:149-155`.
- **Remediación (unos 0,05 dp).** Dentro de la transacción, con el padrón tomado: si `!desarrollo && cambio.Actual is not null`, abortar. También en Debug, no sellar si hay un padrón que verifica o una licencia `Produccion` o `Beta` aceptada: se registra un aviso y no se hace nada.

### SL-07 · Baja · `UsuariosService` falla abierto sin `SellosCuentas`

- **Riesgo.** `sellos` es un parámetro opcional. Si falta, el inicio de sesión no comprueba el sello, `EstadoSesionAsync` devuelve `Valido` y el cupo se cuenta por columnas. Hoy la API lo registra sin condición, y lo comprueban una prueba de texto sobre `Program.cs` y otra sobre un contenedor propio. Ninguna de las dos prueba el arranque real. Una refactorización del registro, o un servicio resuelto en otro proceso (por ejemplo, un `new UsuariosService(db)` como el de `CuentasIniciales.cs:32`), apagaría el control sin aviso.
- **Evidencia.** `UsuariosService.cs:20-21`, `:87`, `:115-120`, `:467-469`; `SellosEnLaApiTests.cs:80-91`.
- **Remediación (unos 0,05 dp).** Al arrancar la API, resolver `UsuariosService` en un ámbito y detener el arranque si `!ConSellos`. Alternativa más fuerte: una subclase o un constructor de la API con `SellosCuentas` obligatorio.

### SL-08 · Baja · `USUARIO_SIN_SELLO`: registro sin límite y posible 500

- **Riesgo.**
  - El `LogCritical` se emite en cada intento. La bitácora sí tiene el límite de uno por minuto y cuenta. Un tercero que conozca el código de una cuenta sin sello (después de una restauración pueden ser muchas) genera hasta 20 eventos críticos por minuto por IP. Eso causa fatiga de alertas y ruido que puede tapar otros eventos.
  - Solo se captura `SqlException`. Cualquier otra falla al escribir la bitácora, o al reponer el padrón en la lectura (`ReponerBaseAsync`, en el mismo camino), da 500 en lugar del 401 uniforme, y distingue «sin sello» de «contraseña incorrecta».
  - El texto no expone nada más: el detalle es el nombre del resultado y no hay secretos.
- **Evidencia.** `UsuariosService.cs:91-104`; `SellosCuentas.cs:33-34`; `PadronSellos.cs:269-273`.
- **Remediación (unos 0,05 dp).** Aplicar el mismo `Limitador.Permite` al `LogCritical` (las repeticiones, como `Debug` o un contador), y capturar `DbException` e `InvalidOperationException` para mantener el 401.

### SL-09 · Baja · «Debe quedar un SUPER/ADMIN habilitado» cuenta filas

- **Riesgo.** La regla cuenta filas por columnas. Con una fila SUPER insertada por SQL (sin sello), un SUPER puede inhabilitar al último SUPER **sellado**, y la instalación queda sin nadie que entre como SUPER hasta legitimar (SL-02). Exige SQL y una acción del SUPER: es baja.
- **Evidencia.** `UsuariosService.cs:268-275`.
- **Remediación (unos 0,05 dp).** Con el padrón tomado, contar las entradas SUPER de `padron.Entradas` distintas de la cuenta (y las ADMIN o SUPER para la regla del administrador), en lugar de las filas.

### SL-10 · Baja · El 409 `PADRON_NO_DISPONIBLE` expone detalles internos

- **Riesgo.** El mensaje que recibe un ADMIN nombra `Licencia.InstalacionId`, «el anillo» y `GPOS.Migracion`. Es poco, y el ADMIN está autenticado, pero son detalles de la implementación que no le sirven.
- **Evidencia.** `PadronSellos.cs:129`, `:171-173`.
- **Remediación (unos 0,02 dp).** Al cliente, un texto genérico («contacte a soporte de GSF», con el código); la causa, al registro.

### Comprobaciones pedidas expresamente

1. **¿Alguna vía de Release crea o sella cuentas sin el verbo y el anillo?** **No** [V].
   - La creación al arrancar depende de la constante `#if DEBUG` (`Inicializacion.cs:19-23`, `:91-94`) y el sellado al arrancar, de la misma constante (`:29`, `:50-56`).
   - En `GPOS.Migracion`, las cuentas solo se crean con `--cuentas-iniciales` y quedan sin sello.
   - El sellado inicial exige `--confirmar-sellado`, el motivo y que verifique `Licencia.InstalacionId` (`SellosService.cs:200-201`); `sellos --purgar` exige el anillo (`ComandoSellos.cs:149-157`).
   - En la API, solo sellan el alta y la rehabilitación de `GuardarAsync` (ADMIN autenticado, con cupo y sello propio), el cambio de contraseña y el hash rehecho (con sello válido), y `ResellarAsync`, que no tiene ninguna ruta.
   - Nota para la fase A: `ResellarAsync` (por `EsCambioDeFactor`) da por bueno el estado de la tabla de factor. Solo debe llamarse dentro de la transacción que escribe `UsuariosFactor` y nunca desde una ruta.
2. **Carreras en el padrón y el cupo.** Toda escritura del padrón toma primero las filas con `UPDLOCK, HOLDLOCK` en una transacción. Así quedan en serie la API, las instancias que hubiera y `GPOS.Migracion`, y el cupo se controla con el padrón tomado. La reposición desde el disco en el camino de lectura es condicional sobre el valor anterior (`ConsultasSellos.cs:34-39`). Única excepción: SL-04. **Falta una prueba de dos altas concurrentes en el límite del cupo** (entrega a QA).
3. **Retroceso de la base frente al disco.** Un `sysadmin` de SQL sin acceso al disco no puede volver atrás: gana la mayor versión que verifica y la base se repone (prueba `SellosPadronTests.cs:394`). Residuales: SL-01 (borrar o mover el disco no deja rastro) y SL-02 (la restauración legítima no tiene recuperación).
4. **Filtración en códigos de error y en el límite de `USUARIO_SIN_SELLO`.** El inicio de sesión, la confirmación y el autorizante dan el mismo 401 «Usuario o contraseña incorrectos» [V]. El 409 `USUARIO_SIN_SELLO` solo llega a un ADMIN autenticado. Observaciones: SL-05, SL-08 y SL-10.
5. **¿El sello cubre lo que exige SH-5?** **Sí.** Cubre la huella del `PasswordHash` y `FactorAlta` en los SUPER, con un sellado nuevo en el cambio y el restablecimiento de la contraseña, en el hash rehecho y en el punto de conexión del factor (`FactorSuper.cs:5-12`). Lo que no cubre está aceptado en `[BP]` SH-2: permisos granulares, `DebeCambiarClave`, bloqueo, revocaciones, y la empresa y la sucursal por omisión sin restricción.
6. **¿Algo lee configuración o entorno para saltarse el sello?** **No** [V]. El código de `Sistema/Usuarios` y `SellosEndpoints` no usa `IConfiguration`, `IOptions` ni el entorno (prueba `SellosEnLaApiTests.cs:64-77`). `UsuariosService` tampoco. El registro en `Program.cs:250-261` no tiene condición. La única configuración que influye es la carpeta del disco (SL-01), que afecta a la detección del retroceso, no al sello.
7. **Oráculo de existencia por tiempo.** Confirmado y anterior a SL. Recomiendo cerrar aquí el de tiempo (SL-05).

---

## 5. Controles bien implementados

- El orden sello → bloqueo → contraseña, con hash ficticio y sin contar el intento, cumple SEG-L2-17 con exactitud (`UsuariosService.cs:46-50`, `:90`). El autorizante lo repite antes de delegar.
- Las tres condiciones de ADR-83 se aplican en el orden correcto (`SellosHabilitacion.cs:141-149`): el sello verifica, los campos coinciden con la fila y el padrón tiene la entrada con la huella y **el mismo nivel** (SEG-L2-01).
- El cupo sale de las entradas no SUPER del padrón y nunca de las columnas, con la regla `excepto` para no contar dos veces la misma cuenta (`PadronSellos.cs:123-124`). `LicenciaAsync` también lo usa y muestra las `FilaAusente`.
- `GuardarAsync` no legitima (SH-6): una cuenta habilitada sin sello válido, o inhabilitada con un sello que no es suyo, da 409. Inhabilitar sí se permite.
- El padrón falla cerrado cuando falta o no verifica (409 `PADRON_NO_DISPONIBLE`) y nunca se reconstruye en Release.
- El disco se escribe solo después del commit, con temporal y `File.Replace`, en una carpeta creada con su DACL (`AlmacenLicenciaDisco.Preparar`).
- Caché global de 15 s que solo descifra si cambió el SHA-256 de la base o del disco (SEG-L2-20).
- La confirmación de una sesión en uso vuelve a exigir el sello (`AuthEndpoints.cs:56-58`): cierra la reutilización de un comprobante emitido antes de invalidar el sello.
- Los verbos exigen el anillo y dejan un evento crítico con la cuenta de Windows, el SID, el equipo y el motivo (condiciones 1 y 2 de `[SEG-D]` D.2). `--cuentas-iniciales` ya no es implícito.
- S-02 y S-04 no se mapean y no hay ningún `IVerificadorSegundoFactor` registrado. Hay una prueba de arquitectura que lo vigila.
- Los mensajes y los eventos no llevan secretos, hashes ni el contenido del sello.

---

## 6. Remediaciones priorizadas

| Prioridad | Acción | Hallazgo | Responsable | Esfuerzo | Momento |
|---|---|---|---|---|---|
| 1 | Evento `PADRON_DISCO_AUSENTE` y falla de escritura persistente; ruta de la carpeta en `verificar` | SL-01 | Desarrollador I (SL) | 0,25 dp | En este PR o en el siguiente de SL, antes de unir RN |
| 2 | Volver a sellar fuera del padrón una cuenta inhabilitada con sello propio | SL-03 | Desarrollador I | 0,1 dp | En este PR |
| 3 | Hash ficticio para cuentas inexistentes, inhabilitadas o sin hash | SL-05 | Desarrollador I | 0,05 dp | En este PR |
| 4 | Releer la fila y volver a evaluar el sello en el hash rehecho | SL-04 | Desarrollador I | 0,05 dp | En este PR |
| 5 | `sellos --legitimar` (RN), procedimiento de restauración y aviso al SUPER | SL-02 | Desarrollador I (RN), documentador, devops | RN ya estimado + 0,35 dp | **Antes de la primera instalación de cliente** |
| 6 | SL-06, SL-07, SL-08, SL-09, SL-10 | — | Desarrollador I | unos 0,22 dp | Con SL o con RN |

En total, sin RN: unos 0,67 dp y USD 0.

---

## 7. Recomendación

**Aprobado con observaciones** (recomendación técnica; pendiente de firma del propietario).

- No hay hallazgos Críticos ni Altos. Lo que exige la hoja firmada está implementado y verificado: DL-01 (a)+(b), DL-02 (a) y DL-05 (a), además de SEG-L2-01, 05, 06, 07, 12, 17 y 20.
- Recomiendo corregir en este PR SL-03, SL-04 y SL-05 (unos 0,2 dp). SL-01 puede ir aquí o en el siguiente PR de SL.
- SL-02 no bloquea esta pieza porque hoy no hay instalaciones de cliente, pero **es condición previa a la primera instalación de cliente** (RN con `sellos --legitimar` y el procedimiento de restauración).
- No ejecuté pruebas. La aprobación supone que la suite oficial y la categoría `Sellos` pasan en la validación de B o de C.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\revision-seguridad-sl-sello-padron-2026-10-17.md`
- Supuestos: no ejecuté compilación ni pruebas; la diferencia de tiempo de PBKDF2 (100 a 300 ms) y la desalineación de carpetas entre la API y `GPOS.Migracion` son [I]; «hoy todo es desarrollo» (memoria del proyecto) para graduar SL-02.
- Decisiones candidatas a ADR: precisar en ADR-83 que la ausencia del archivo `padron` con una base de versión mayor que 1 es un evento crítico (SL-01), y que el procedimiento de restauración de `GPOS_SYSDATA` pasa por `verificar` y `sellos --legitimar`, nunca por borrar el disco (SL-02). Alternativa descartada: negarse a operar sin el archivo (convierte un borrado en denegación de servicio).
- Entregas a otros agentes: desarrollador I → SL-01, SL-03 a SL-10; qa-automatizado → prueba de dos altas concurrentes en el límite del cupo, prueba de restauración con cambio de contraseña del SUPER, prueba de inhabilitar y cambiar la clave en el mismo guardado, y prueba de tiempo con cuentas inexistentes; devops → misma `GPOS:Licencia:Carpeta` para la API y `GPOS.Migracion` en el instalador; documentador-técnico → procedimiento de restauración en `docs/operaciones/`; equipo C (fase A de ADR-81) → `ResellarAsync` solo dentro de la transacción que escribe `UsuariosFactor`.
- Próximo paso recomendado: que el desarrollador corrija SL-03, SL-04 y SL-05 (y, si cabe, SL-01) en la rama `a/sl-sello-padron` antes de la validación de B.
