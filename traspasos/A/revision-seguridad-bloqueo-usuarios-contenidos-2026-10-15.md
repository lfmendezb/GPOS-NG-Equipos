# Dictamen de seguridad: bloqueo por intentos fallidos en usuarios contenidos de SQL Server

**Fecha:** 2026-10-15 · **Autor:** auditor-seguridad (equipo A) · **Encargo:** derivado de A-N3 (`GPOS-NG-Equipos\avisos\B-a-A\2026-10-15-a-n3-hecha-b-devops-publicacion.md`)
**Código revisado:** `GPOS NG`, `origin/feature/modelo-ng` @ `7898beeb` y `origin/b/devops-publicacion` @ `e6457402`. En lo que aquí importa, las dos ramas son iguales: `e6457402` no toca `database/` ni `src/GPOS.Migracion`.
**Estado de la recomendación:** técnica. La decisión es del propietario (C2).

Convención de evidencia: **[D]** documentación oficial de Microsoft · **[V]** verificado en el código o en la instancia · **[I]** inferido.

---

## 0. Veredicto sobre la suposición

> «La política de bloqueo de cuentas de Windows, la que se aplica con `CHECK_POLICY`, no se aplica a los usuarios contenidos con contraseña.»

**Confirmada (documental).** Vale igual para SQL Server 2022 y 2025.

Microsoft no tiene una frase que diga literalmente «los usuarios contenidos no se bloquean». La conclusión sale de cinco evidencias oficiales que coinciden, y ninguna fuente dice lo contrario:

1. *Security Best Practices with Contained Databases*, sección «Password Policies»: *«Passwords in a database can be required to be strong passwords, but cannot be protected by robust password policies. Use Windows Authentication whenever possible…»* Es decir, la complejidad sí se aplica; el resto de la política (caducidad, historial y bloqueo) no. [D]
2. La sintaxis de `CREATE USER … WITH PASSWORD` y de `ALTER USER … WITH PASSWORD [OLD_PASSWORD]` **no tiene `CHECK_POLICY` ni `CHECK_EXPIRATION`**. Esas opciones solo existen en `CREATE LOGIN` y `ALTER LOGIN`, donde se documentan como *«Applies to SQL Server logins only»*. [D]
3. *Password Policy*, sección «Policy enforcement»: *«The enforcement of password policy can be configured separately for each SQL Server login. Use ALTER LOGIN…»*. El umbral, la duración y el contador de bloqueo se activan *«when CHECK_POLICY is changed to ON»*, y eso es una propiedad del login. La misma página dice que *«the password policy applies to … a contained database user with password»*, pero el párrafo siguiente la reduce a *«complexity and expiration policies»*. En la práctica, al usuario contenido solo le llega la complejidad, porque no tiene ninguna opción para activar la caducidad (punto 2). [D] + [I]
4. `LOGINPROPERTY` (`IsLocked`, `LockoutTime`, `BadPasswordCount`) devuelve *«information about the password policy settings of a SQL Server login»* y se consulta sobre `sys.sql_logins`. `sys.database_principals` no tiene ninguna columna de política, de bloqueo ni de intentos fallidos: solo `authentication_type = 2 (DATABASE)`. **No existe un lugar donde guardar el estado de bloqueo de un usuario contenido.** [D]
5. Las páginas en inglés de *Password Policy* y *Security Best Practices* son las mismas con `view=sql-server-ver16` (2022) y `ver17` (2025), y el texto citado aparece en las dos. La única diferencia entre versiones es el hash de la contraseña (sección 2). [D]

**Lo que falta para pasar de [D] a [V]:** una prueba empírica, que no hice porque las dos instancias de este equipo tienen `contained database authentication = 0` y el encargo era de solo lectura. Propuesta: en una instancia desechable, con la autenticación contenida activa, se supera el umbral de Windows con intentos fallidos contra un usuario contenido y se comprueba que la contraseña correcta sigue entrando. Para comparar, se repite contra un login SQL con `CHECK_POLICY = ON` y se comprueba que `LOGINPROPERTY(…,'IsLocked') = 1`. Lleva unos 0,1 días-persona y puede hacerla QA o devops. No cambia las remediaciones de este dictamen.

### Matiz que la suposición no cubre: complejidad y caducidad frente a bloqueo

| Control de la política | Login SQL, `CHECK_POLICY = ON` (por omisión) | Login SQL, `CHECK_POLICY = OFF` | Usuario contenido con contraseña |
|---|---|---|---|
| Complejidad (3 de 4 categorías, ≥ 8 caracteres, sin el nombre) | Sí [D] | No [D] | **Sí**, si Windows la exige [D] (puntos 1 y 3) |
| Caducidad (`CHECK_EXPIRATION`) | Opcional; por omisión `OFF` [D] | No se admite (`OFF`) [D] | **No**: la opción no existe [D] |
| Historial | Sí [D] | Se borra [D] | No [I] |
| **Bloqueo por intentos fallidos** | **Sí**: umbral, duración y ventana de Windows [D] | **No**; además, pasar a `OFF` reinicia `lockout_time` [D] | **No** [D] (puntos 1, 2 y 4) |

### SQL Server 2022 frente a 2025

| Aspecto | 2022 (16.x) | 2025 (17.x) |
|---|---|---|
| Bloqueo de usuarios contenidos | No [D] | No [D] |
| Bloqueo de logins con `CHECK_POLICY = ON` | Sí [D] | Sí [D] |
| Complejidad en usuarios contenidos | Sí [D] | Sí [D] |
| Hash de la contraseña (logins y usuarios contenidos) | SHA-512 con sal de 32 bits [D] | **PBKDF2 (RFC 2898), SHA-512 con 100.000 iteraciones, activo por omisión** [D] (*What's new in SQL Server 2025*, «PBKDF for password hashes on by default»; `CREATE USER` y `ALTER USER`) |
| Efecto del hash nuevo | — | Un ataque de diccionario contra los hashes de una copia `.bak` de la empresa, donde viajan los de `gpos_app_*`, es unas 10⁵ veces más lento [I]. **Cada intento de login, también los fallidos, cuesta más CPU al servidor**: Microsoft lo reconoce para *«scenarios without pooling»* [D]; del orden de decenas de ms de CPU por intento [I, sin medir] |

En este equipo, `.` es SQL Server 2025 (17.0.1145.4, Enterprise Developer) y `.\SQLEXPRESS` es SQL Server **2019** (15.0.2200.2, Express) [V]. El informe A-N3 dice 17.0.1000.7 en las dos, pero eso se midió en el equipo de B. SQL Server 2019 no es destino del producto y en este tema se comporta como 2022.

---

## 1. Alcance y superficie revisada

- **Documentación oficial** (Microsoft Learn, consultada el 2026-10-15, `view=sql-server-ver16` y `ver17`):
  - https://learn.microsoft.com/en-us/sql/relational-databases/security/contained-database-users-making-your-database-portable
  - https://learn.microsoft.com/en-us/sql/relational-databases/databases/security-best-practices-with-contained-databases
  - https://learn.microsoft.com/en-us/sql/t-sql/statements/create-user-transact-sql
  - https://learn.microsoft.com/en-us/sql/t-sql/statements/alter-user-transact-sql
  - https://learn.microsoft.com/en-us/sql/relational-databases/security/password-policy
  - https://learn.microsoft.com/en-us/sql/t-sql/statements/create-login-transact-sql
  - https://learn.microsoft.com/en-us/sql/t-sql/functions/loginproperty-transact-sql
  - https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-database-principals-transact-sql
  - https://learn.microsoft.com/en-us/sql/relational-databases/databases/contained-databases
  - https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/contained-database-authentication-server-configuration-option
  - https://learn.microsoft.com/en-us/sql/sql-server/what-s-new-in-sql-server-2025
- **Código** (búsqueda de `CREATE USER`, `WITH PASSWORD`, `CHECK_POLICY`, `CHECK_EXPIRATION`, `ALTER USER` y `18456` en las dos ramas):
  - `database/rg14/rg14-00-servidor.sql` (S0). **Solo crea logins `FROM WINDOWS`** (l. 30, 31 y 34) y declara *«no se crea ningún login SQL»* (l. 7). Exige el modo mixto (l. 19) y `sa` deshabilitado (l. 21), y activa `contained database authentication` (l. 22-26). [V]
  - `src/GPOS.Migracion/CredencialApp.cs:96-97`: crea `gpos_app_a|b` con una contraseña aleatoria de 32 bytes en base64url (43 caracteres) mediante `CredencialesLectura.CrearUsuarioAsync`. [V]
  - `src/GPOS.Migracion/Lectura/CredencialesLectura.cs:80`: contraseña de `gpos_rpt_*` y `gpos_lec_*`. L. 218-220: `CREATE USER … WITH PASSWORD` y `ALTER USER … WITH PASSWORD`, sin opciones de política, porque no existen. L. 150-156: exige el modo mixto y `sa` deshabilitado. L. 120: login de reportes `FROM WINDOWS`. [V]
  - `src/GPOS.Core/Infraestructura/CadenaConexion.cs:14-22`: `NeverBlock`. `src/GPOS.Core/Infraestructura/Motor/ReaperturaConexionEmpresa.cs:8-12`: ante un 18456, una sola reapertura, así que cada petición hace como mucho 2 intentos de login. [V]
  - `src/GPOS.Migracion/VerificacionPrivilegios.cs`: `USUARIO_CONTENIDO_AJENO` (l. 49), `AUTO_CLOSE` (l. 157), `SA_HABILITADO` y `CONTENCION_INACTIVA` (l. 180-188). **No hay ninguna comprobación sobre `sys.sql_logins`.** [V]
  - El único `CHECK_POLICY` está en una prueba: `tests/GPOS.Tests/EsquemaBaseAjenaTests.cs:345`, con `OFF`. [V]
  - Documentos: `docs/operaciones/2026-10-15-informe-a-n3.md` §3, `docs/operaciones/2026-10-15-lista-publicacion-release.md` (M5 y M6, §3) y `docs/adr/ADR-044.md:20` (AC-1). [V]
- **Instancias de este equipo**, solo con consultas de catálogo (`sqlcmd -E -C`; no se cambió nada) [V]:

| Instancia | Modo | `contained database authentication` | `audit level` | `sys.sql_logins` | Bases contenidas |
|---|---|---|---|---|---|
| `.\SQLEXPRESS` (2019 Express) | Mixto | 0 | `failure` | `sa`: deshabilitado, política 1. **`gsf`: habilitado, `sysadmin`, política 0, caducidad 0**, sin bloqueo ni fallos | Ninguna |
| `.` (2025 Developer) | Mixto | 0 | `failure` | ídem: `sa` deshabilitado; **`gsf` `sysadmin` con política 0** | Ninguna |

- **Política de Windows de este equipo** (`net accounts`, estación de trabajo, sin dominio) [V]: **umbral de bloqueo de 10 intentos, duración de 10 min y ventana de 10 min.** La caducidad máxima es de 42 días. En los equipos de los clientes con dominio puede ser otra [I].
- **Fuera de alcance:** el resto de RG-14 y la variante S, que todavía no tiene código.

---

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título | Estado |
|---|---|---|---|
| BL-01 | **Media** (pasa a **Alta** si se construye así) | Los logins SQL de servicio (variante S y, si fuera SQL, Backup Tool) heredan el bloqueo por omisión. Con `NeverBlock` la API se bloquea a sí misma, y cualquiera que llegue al puerto puede bloquearla | Preventivo: hoy no existe ningún login SQL de servicio [V] |
| BL-02 | **Media** | Sin bloqueo (usuarios contenidos y logins con `OFF`), el servidor no frena los intentos en línea. En 2025 cada intento fallido cuesta CPU (PBKDF2). Ni K1 ni las alertas cubren el puerto de SQL | Verificado en lo documental; el costo de CPU es inferido |
| BL-03 | **Media** (en un cliente sería **Alta**) | `gsf` (`sysadmin`, login SQL) con `CHECK_POLICY = OFF` en las dos instancias de este equipo, en contra de ADR-44 AC-1 | Verificado |
| BL-04 | Baja | La complejidad sí se aplica a los usuarios contenidos: una contraseña base64url de 43 caracteres falla la política con una probabilidad de alrededor de 1,3 × 10⁻⁴ | Inferido; falla sin dañar nada |
| BL-05 | Baja | Si un usuario contenido se llama igual que un login SQL, ese login no puede entrar a la base contenida (denegación documentada). Hay que tenerlo en cuenta al nombrar los logins de la variante S | Preventivo |
| BL-06 | Baja | Sospecha: restaurar una copia de la empresa anterior a una rotación devuelve hashes viejos de `gpos_app_*`, y quedan 18456 persistentes. No hay bloqueo, pero sí corte de servicio | Sospecha; requiere confirmación |

No hay hallazgos Críticos. No hay ningún Alto **abierto** hoy: BL-01 solo pasa a Alta si S0 o la variante S crean logins sin `CHECK_POLICY = OFF`.

---

## 3. Checklist OWASP (acotado al tema)

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | No aplica a este encargo (lo cubren RG-14 y `verificar`) |
| A02 Criptografía | Bien: 32 bytes del generador criptográfico (`CredencialApp.cs:96`, `CredencialesLectura.cs:80`). En 2025 el hash es PBKDF2. BL-04 (complejidad) |
| A03 Inyección | No aplica. La contraseña va como parámetro y entra al texto con `QUOTENAME(@c,'''')` (`CredencialesLectura.cs:218`) |
| A04 Diseño inseguro | BL-01 y BL-05 (diseño de S0 y de la variante S) |
| A05 Configuración | BL-03 (`gsf`), BL-02 (exposición del puerto y modo mixto) |
| A06 Componentes vulnerables | No aplica |
| A07 Identificación y autenticación | **Tema central.** Suposición confirmada; BL-01 a BL-04 |
| A08 Integridad | No aplica |
| A09 Registro y monitoreo | BL-02: `audit level = failure` [V] deja el 18456 en el registro de errores y en el Visor de eventos, pero nada lo consume ni avisa (en `src` el 18456 solo se maneja, no se alerta [V]) |
| A10 SSRF | No aplica |

---

## 4. Hallazgos

### BL-01 · Logins SQL de servicio con la política por omisión: autobloqueo y bloqueo provocado — Media (Alta si se construye así)

**Riesgo.**
- `CREATE LOGIN … WITH PASSWORD` trae `CHECK_POLICY = ON` por omisión, y eso activa el umbral, la duración y la ventana de bloqueo de Windows [D: CREATE LOGIN, Password Policy].
- La API abre cada conexión con `NeverBlock` y reintenta una sola vez ante un 18456 (`ReaperturaConexionEmpresa.cs:8-12`), así que una petición son 2 intentos [V].
- Con el umbral de 10 de este equipo [V], si la contraseña no coincide (rotación a medias, restauración de `GPOS_SYSDATA` o cadena vieja), unas **5 peticiones** bastan para bloquear la cuenta durante 10 min. Mientras siga el desajuste, el bloqueo se renueva solo [I]. El aviso A-N3 habla de «unas decenas»: con la política por omisión de Windows 11 son 10 intentos.
- Además, cualquiera que llegue al puerto de SQL y conozca el nombre del login puede bloquearlo sin saber la contraseña, y los nombres de servicio son predecibles. Bloquear el login de la variante S deja sin servicio a todo el POS.

**Evidencia.**
- Hoy S0 solo crea logins de Windows (`database/rg14/rg14-00-servidor.sql:7, 30, 31, 34`) y el código no tiene ningún `CREATE LOGIN … WITH PASSWORD` [V].
- La variante S y el posible login SQL de Backup Tool están en el diseño (ADR-82 en borrador, punto 2) y en el encargo para el desarrollador I [V].

**Remediación.** Ver la sección 6, R1 y R2. En resumen: `CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF` explícitos, con una contraseña de 32 bytes del generador criptográfico, y el hallazgo `LOGIN_SERVICIO_CON_POLITICA`.

**Lo que se acepta al apagar la política.** La cuenta queda sin bloqueo y sin control de complejidad. La protección pasa a ser la entropía (256 bits: inviable por fuerza bruta en línea) más los controles de red de BL-02.

*Alternativa descartada:* dejar `ON` con un umbral alto. Depende de la política del dominio del cliente, que GSF no controla. Coincide con lo que descartó devops.

### BL-02 · Sin freno del servidor a los intentos en línea; costo de CPU en 2025; los controles compensatorios no cubren el puerto de SQL — Media

**Riesgo.**
- Que los usuarios contenidos no se bloqueen **es lo que se quiere** para la disponibilidad, porque cierra el residual de `NeverBlock` para `gpos_app_*`, `gpos_rpt_*` y `gpos_lec_*`.
- El reverso es que SQL Server no limita los intentos. La confidencialidad no corre peligro: con 256 bits, adivinar la contraseña en línea es inviable [I, por cálculo].
- Quedan dos riesgos:
  - **(a) Denegación por CPU en 2025.** Con PBKDF2 de 100.000 iteraciones, cada intento fallido obliga al servidor a calcular el hash [D sobre el costo; magnitud I]. Una ráfaga de intentos desde la red, o de la propia API en un desajuste sostenido, consume CPU del mismo equipo que factura.
  - **(b) Nadie se entera.** El 18456 queda en el registro (`audit level = failure` [V]), pero no hay alerta: SQL Server Express no tiene SQL Agent y el código no consume esos eventos [V].
- **K1 no compensa esto.** Los frenos de K1 (`FrenosDispositivos`: 10 fallos por minuto por IP y 60 por minuto en el sitio; `docs/construccion/2026-10-09-k1-correcciones-seguridad.md` §K1-01) son **HTTP**, en los puntos de token y canje de dispositivos [V].
  - Acotan las aperturas de base que puede provocar un anónimo **a través de la API**.
  - No ven una conexión TDS directa al puerto de SQL Server [I, por arquitectura].
- **Lo que sí compensa hoy:**
  - `sa` deshabilitado, exigido en S0 (l. 21), en `CredencialesLectura.cs:156` y en `verificar` (`SA_HABILITADO`) [V];
  - las contraseñas de 32 bytes;
  - la rotación en dos generaciones con `DENY CONNECT` de la anterior (`CredencialApp.cs:104-110`) [V];
  - `USUARIO_CONTENIDO_AJENO` (`VerificacionPrivilegios.cs:49`) [V];
  - `AUTO_CLOSE` vigilado (l. 157). Microsoft lo señala como vector de denegación con bases contenidas [D].

**Remediación.** R4 y R5 de la sección 6: restringir el puerto y alertar sobre el 18456.

### BL-03 · `gsf` (`sysadmin`, login SQL) con `CHECK_POLICY = OFF` — Media (Alta en un cliente)

**Riesgo.**
- `gsf` es el login más poderoso de la instancia y entra por autenticación SQL en modo mixto.
- Con la política apagada no tiene bloqueo ni control de complejidad, así que la única defensa es la calidad de su contraseña, que una persona custodia.
- ADR-44, AC-1 (firmado) pide **`CHECK_POLICY = ON`** y al menos 20 caracteres aleatorios (`docs/adr/ADR-044.md:20`) [V].
- Hoy es un equipo de desarrollo, sin producción. En una instalación de cliente sería Alta.

**Evidencia.** `sys.sql_logins` en `.` y en `.\SQLEXPRESS`: `gsf` con `is_policy_checked = 0`, `is_expiration_checked = 0` y `sysadmin` [V]. Lo mismo informó B para su equipo (A-N3 §3).

**Diferencia con BL-01.** Para una persona, el bloqueo **sí conviene**:
- quien provoque un bloqueo de `gsf` solo deja sin administración a la instancia durante 10 min, sin cortar el POS;
- el bloqueo, a su vez, frena la fuerza bruta contra una cuenta `sysadmin`.

Lo correcto es lo contrario que para los servicios: **`ON` para las personas y `OFF` para los servicios con secreto de máquina.**

**Remediación.** R3. La aplica el propietario, que custodia `gsf`: `ALTER LOGIN` con `CHECK_POLICY = ON` y sin `CHECK_EXPIRATION`, salvo que el propietario anote la fecha de renovación, como dice AC-1. Además, una comprobación en `verificar` y en PUB-06.

### BL-04 · La complejidad sí se aplica a los usuarios contenidos — Baja

**Riesgo.**
- Si la política de Windows exige complejidad (en Windows Server suele venir activa [I]), `CREATE USER` o `ALTER USER … WITH PASSWORD` rechazan las contraseñas que no tengan 3 de las 4 categorías [D].
- La de `CredencialApp.cs:96` es base64url de 43 caracteres: mayúsculas, minúsculas, dígitos y `-`/`_`. Falla si no sale ningún dígito ni ningún símbolo, con una probabilidad de (52/64)^43 ≈ **1,3 × 10⁻⁴**, es decir, una de cada 7.600 rotaciones [I, por cálculo]. El error 15118 aborta `credencial-app` **antes** de cambiar la cadena (`CredencialApp.cs:97-101`) [V].
- **No hay pérdida de seguridad ni de datos**: el comando falla y se repite. Lo mismo vale para `CredencialesLectura.cs:80`.

**Remediación.** R6.

### BL-05 · Usuario contenido con el mismo nombre que un login — Baja

**Riesgo.** Microsoft documenta que, si existe un usuario contenido con el mismo nombre que un login SQL, ese login no puede entrar cuando indica la base contenida como catálogo inicial. Lo trata como *«intentional or accidental denial of service»* [D: Security Best Practices, «Creating a User that Duplicates a Login»]. Hoy no hay choque: los logins son de Windows (`NT SERVICE\…`) [V]. El riesgo aparece si la variante S nombra su login con un nombre de `UsuariosContenidosPropios` (`VerificacionPrivilegios.cs`, propiedad `UsuariosContenidosPropios`).

**Remediación.** R1 (nombres) y R2 (comprobación `CONTENIDO_DUPLICA_LOGIN`).

### BL-06 · Restaurar una copia anterior a la rotación — Baja (sospecha)

**Riesgo.**
- Los hashes de `gpos_app_*` viajan dentro de la base de la empresa [D: «Offline Dictionary Attack»]. Si se restaura una copia hecha antes de la última rotación, la cadena guardada en `GPOS_SYSDATA` no coincide con la base restaurada [I].
- Como no hay bloqueo, no se agrava, pero la empresa queda con 18456 hasta que alguien ejecute `credencial-app`.
- No verifiqué si el flujo de restauración de H-11 ya lo resuelve.

**Remediación.** Confirmarlo con el dueño de H-11. Si no está resuelto, que el procedimiento de restauración termine con `GPOS.Migracion credencial-app --empresa X --rotar`.

---

## 5. Controles que están bien implementados

- Los usuarios contenidos se crean sin opciones de política, porque no existen, y con 32 bytes del generador criptográfico (`CredencialApp.cs:96`, `CredencialesLectura.cs:80`) [V].
- La contraseña viaja como parámetro y entra al texto con `QUOTENAME(@c,'''')`, sin concatenación directa (`CredencialesLectura.cs:216-220`) [V].
- La rotación en dos generaciones evita la ventana de desajuste que tendría un `ALTER USER` sobre el mismo usuario (ADR-82, alternativa descartada) y niega `CONNECT` a la generación anterior (`CredencialApp.cs:104-110`) [V].
- La reapertura ante un 18456 se limita a **una** por petición (`ReaperturaConexionEmpresa.cs`) [V], lo que acota la tasa de intentos que genera la propia API.
- S0 y `CredencialesLectura` no siguen si la instancia está en solo Windows o si `sa` está habilitado (`rg14-00-servidor.sql:19-21`, `CredencialesLectura.cs:150-156`) [V].
- `verificar` vigila `AUTO_CLOSE` y los usuarios contenidos ajenos, los dos vectores que Microsoft señala para las bases contenidas [V].
- S0 crea `FROM WINDOWS` los logins de la API, de reportes y de Backup Tool (l. 30-34): **son cuentas virtuales o de Windows, que no tienen bloqueo por contraseña SQL** [V].

---

## 6. Remediaciones priorizadas

### Para el desarrollador I

**R1 · Paso S0 (y la variante S) — cierra BL-01 y BL-05.** Unos 0,2 días-persona.
1. Crear logins SQL **solo** en la variante S, o para Backup Tool si no hay cuenta de Windows posible, y con un interruptor explícito. El camino por omisión sigue siendo `FROM WINDOWS`, como hoy.
2. La contraseña **no** debe ir en una variable de `sqlcmd`: el guion se sustituye como texto y su encabezado (l. 7) promete que no hay secretos. Que el login SQL de servicio lo cree `GPOS.Migracion`, con una contraseña de 32 bytes generada en memoria y pasada como parámetro (el mismo patrón de `CredencialApp`), y que guarde la cadena cifrada (SEC-05 b).
3. Crear con `CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF` **explícitos**. Si el login ya existe con `is_policy_checked = 1`, ejecutar `ALTER LOGIN … WITH CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF`, que además reinicia `lockout_time` [D].
4. Ningún nombre de login SQL de servicio puede coincidir con uno de `UsuariosContenidosPropios` (`gpos_app_*`, `gpos_rpt_*` ni `gpos_lec_*`). Conviene un prefijo distinto, por ejemplo `gpos_srv_…`.
5. Mantener la comprobación de AC-4 (l. 39-51): la identidad de servicio no tiene permisos de servidor más allá de `CONNECT SQL`.

**R2 · `GPOS.Migracion verificar`: `LOGIN_SERVICIO_CON_POLITICA` y dos comprobaciones vecinas — cierra la detección de BL-01, BL-03 y BL-05.** Unos 0,15 días-persona con pruebas (devops estimó 0,1 solo para la primera).
- **`LOGIN_SERVICIO_CON_POLITICA` (hallazgo; cuenta para `--estricto`).**
  - Dónde: en el lote de `GPOS_SYSDATA` de `SqlBase`, no en `SqlInstancia`, que no sabe qué logins son de servicio.
  - Qué hace: busca por **SID** los logins de `gpos_sistema`, `gpos_respaldo_srv` y los miembros de `gpos_rpt_sis`, los cruza con `sys.sql_logins` y marca los que tengan `is_policy_checked = 1` o `is_expiration_checked = 1`.
  - Detalle sin secretos, en la línea de *«login SQL de servicio con política de bloqueo: con NeverBlock puede quedar bloqueado (M5)»*.
  - Opcional: añadir el estado `LOGINPROPERTY(name,'IsLocked') = 1` en el detalle.
  - Los logins de Windows no salen: no están en `sys.sql_logins`.
- **`LOGIN_ADMIN_SIN_POLITICA` (en `SqlInstancia`).** Marca los `SQL_LOGIN` habilitados con `sysadmin` y `is_policy_checked = 0` (AC-1; es el caso de `gsf`). Como AC-1 está firmado, propongo que sea hallazgo. Si el propietario prefiere no cortar los entornos de desarrollo, puede ser un aviso (`Avisos`).
- **`CONTENIDO_DUPLICA_LOGIN` (en `SqlBase`).** Marca un usuario con `authentication_type = 2` cuyo nombre coincida con un `sys.server_principals.name`.
- **Visibilidad.** Las tres comprobaciones necesitan ver `sys.sql_logins`. `VERIFICADOR_SIN_VISIBILIDAD` ya avisa si no se ve.
- **Pruebas.**
  - Login SQL de servicio con `ON`: hallazgo.
  - Con `OFF` y `OFF`: sin hallazgo.
  - Login de Windows: sin hallazgo.
  - `sysadmin` SQL con `OFF`: `LOGIN_ADMIN_SIN_POLITICA`.
  - Nombre duplicado: `CONTENIDO_DUPLICA_LOGIN`.

**R6 · Complejidad de las contraseñas generadas — cierra BL-04.** Unos 0,05 días-persona.
- En `CredencialApp.cs:96` y `CredencialesLectura.cs:80`, garantizar las 4 categorías. Hay dos formas:
  - volver a generar mientras falte un dígito o un símbolo;
  - o reintentar una vez ante el error 15118.
- No conviene añadir un sufijo fijo: no resta entropía de verdad, pero es un patrón reconocible.

### Para el Arquitecto Maestro: PUB-06 (M5), a la firma del propietario

**R3 · Precisar M5 y añadir dos comprobaciones.** Es redacción, unos 0,1 días-persona.
- **M5 (corregido):**
  - todo `SQL_LOGIN` de la API o de Backup Tool tiene `is_policy_checked = 0`, `is_expiration_checked = 0` e `IsLocked = 0`, con una contraseña de 32 bytes del generador criptográfico;
  - los usuarios contenidos (`gpos_app_*`, `gpos_rpt_*` y `gpos_lec_*`) no se bloquean (este dictamen, con evidencia documental) y no necesitan esta comprobación;
  - los logins de Windows y las cuentas virtuales, tampoco;
  - corregir «unas decenas» por «el umbral de Windows: 10 intentos por omisión en Windows 11; en un dominio, el que fije el dominio».
- **M5-b (nuevo; AC-1):** todo `SQL_LOGIN` `sysadmin` habilitado (`gsf` y los nominales) tiene `is_policy_checked = 1`. Lo comprueba `LOGIN_ADMIN_SIN_POLITICA`.
- **M5-c (nuevo):** ningún usuario contenido se llama igual que un login (`CONTENIDO_DUPLICA_LOGIN`).

**R4 · Puerto de SQL y modo mixto (BL-02; lo implanta devops en PUB-06).** Unos 0,1 días-persona por guía.
- Si SQL Server está en el mismo equipo que la API (el caso normal), la instancia no escucha por TCP desde la red. Si hace falta TCP, la regla del Firewall de Windows limita el puerto al equipo de la API, que es el único cliente SQL.
- En la variante S, la regla limita el puerto a la IP del equipo de la API.
- Costo de licencias o servicios: 0.

**R5 · Alerta de 18456 (BL-02 b).** Unos 0,5 días-persona [I].
- El agente automático o la API leen el Visor de eventos (Aplicación, origen `MSSQL$<instancia>`, evento 18456) o una sesión de Extended Events con *ring buffer*.
- Avisan a GSF cuando hay más de N fallos en M minutos. Valor inicial propuesto: 20 en 5 min, ajustable.
- *Alternativa más barata (0,1 días-persona):* una tarea programada de Windows con un desencadenador por el evento 18456 que escriba una línea en la bitácora de GPOS. Avisa, pero no agrega fallos.
- *Descartada:* alertas de SQL Agent, porque Express no tiene Agent.

**Orden recomendado:** R3 y R1 antes de construir la variante S (si no, BL-01 pasa a Alta) → R2 junto con R1 → R6 → R4 en la guía de PUB-06 → R5 antes de la entrega 1, o declarado como residual. BL-03 lo resuelve el propietario en cuanto quiera: es un comando y no corta nada.

---

## 7. Recomendación

**Aprobado con observaciones**, como recomendación técnica: la decisión es del propietario.
- **D-04 (a) se puede apoyar en la suposición**, que queda confirmada en lo documental: los usuarios contenidos `gpos_app_*` no heredan la política de bloqueo, así que con `NeverBlock` no se bloquean a sí mismos.
- Las observaciones son tres:
  - BL-01, que es preventivo pero pasa a Alta si la variante S se construye sin `CHECK_POLICY = OFF`;
  - BL-02 (falta de freno y de alerta en el puerto de SQL; CPU en 2025);
  - BL-03 (`gsf` en contra de AC-1).
- **No hay ningún Crítico ni Alto abierto hoy.**

---

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\revision-seguridad-bloqueo-usuarios-contenidos-2026-10-15.md`
- Supuestos:
  - los clientes usan Windows 11 o Windows Server con la política local por omisión (umbral de 10) salvo que tengan dominio;
  - el costo de CPU de PBKDF2 por intento es del orden de decenas de ms (no medido);
  - la prueba empírica del bloqueo de usuarios contenidos queda pendiente (las instancias tienen la autenticación contenida en 0 y el encargo era de solo lectura).
- Decisiones candidatas a ADR: precisión de ADR-44 AC-1 y de ADR-82: «política `ON` para los logins SQL de personas y `OFF` para los de servicio con secreto de máquina; los usuarios contenidos no tienen bloqueo». Alternativa descartada: un umbral alto con `ON` para todos, porque depende del dominio del cliente.
- Entregas a otros agentes:
  - desarrollador I → R1, R2 y R6;
  - arquitecto-maestro → R3 (M5, M5-b y M5-c en PUB-06) y la precisión de ADR-44 y ADR-82;
  - devops → R4 y R5 en la guía de PUB-06;
  - qa-automatizado → prueba empírica del bloqueo en una instancia desechable (unos 0,1 días-persona);
  - propietario → `gsf` con `CHECK_POLICY = ON` (BL-03);
  - dueño de H-11 → confirmar BL-06.
- Próximo paso recomendado: que el desarrollador I incorpore R1 y R2 al construir S0 y la variante S, y que el Maestro lleve M5 corregido a la firma de PUB-06.
