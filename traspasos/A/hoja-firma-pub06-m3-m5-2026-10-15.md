# Hoja de firma corta: precisión de PUB-06 (ADR-44, AC-8) con M3, M5 y el dictamen sobre el bloqueo de cuentas

**Fecha:** 2026-10-15 · **Versión:** 1 · **Preparada por:** Arquitecto Maestro (equipo A) · **Decide y firma:** el propietario (Leonardo Méndez)
**Estado: Pendiente de firma.** Esta hoja no firma nada y **no edita ADR-44**, que está firmado. Si el propietario la firma, B registra el bloque de la sección 4 como precisión al final de `docs/adr/ADR-044.md` y la nota de la sección 4.2 en `docs/adr/ADR-082.md`.

```
[Decisión preparada por el Arquitecto Maestro]  Estado: Pendiente de firma
```

**Fuentes (solo lectura)**
- `[ADR-44]`: `docs/adr/ADR-044.md` en `master`. **AC-1:** `gsf` con `CHECK_POLICY = ON`. **AC-8:** los puntos 4 (`sa` deshabilitado) y 5 (`gsf` creado) se aplican antes de publicar la versión 1, y **esa es la condición PUB-06**.
- `[ADR-82]`: `docs/adr/ADR-082.md` en `master`: punto 2 (variante S, login SQL de la API), punto 3 (usuarios contenidos `gpos_app_a|b`), punto 9 (Amplio) y punto 11 (Backup Tool con login propio).
- `[LPR]`: `docs/operaciones/2026-10-15-lista-publicacion-release.md`, rama `b/devops-publicacion` @ `e6457402` (devops del equipo B, encargo A-N3): comprobaciones manuales M1 a M7 y consultas de la sección 3.
- `[BL]`: `Solucion GPOS NG\revision-seguridad-bloqueo-usuarios-contenidos-2026-10-15.md` (auditor-seguridad, equipo A): **Aprobado con observaciones**. BL-01 a BL-06 y remediaciones R1 a R6. Sin Críticos ni Altos abiertos.
- Aviso `GPOS-NG-Equipos/avisos/B-a-A/2026-10-15-a-n3-hecha-b-devops-publicacion.md` y hoja de licencia v2.13 (DL-02 (a) firmada el 2026-10-15).

**Convención.** *[V]* verificado en la fuente; *[I]* inferido. **dp** = días-persona (USD 300 a 400 cada uno).

---

## 1. Contexto y pregunta a decidir

Hoy PUB-06 exige dos cosas antes de entregar la versión 1 a un cliente: `sa` deshabilitado y `gsf` creado (AC-8). Al preparar la publicación en Release, devops (`[LPR]`) y el auditor (`[BL]`) encontraron tres riesgos que esa lista no cubre:
- **El modo Amplio puede llegar a un cliente.** Es una clave de configuración: `Comun-Demo.ps1` la fija en `Amplio` para el DEMO [V, `[LPR]` §1]. El bloqueo en el código que firmaste con DL-02 (M4) todavía no existe, así que hasta que exista la única barrera es comprobarlo a mano (M3).
- **Un login SQL de servicio se puede bloquear a sí mismo.** `CREATE LOGIN … WITH PASSWORD` activa por omisión la política de bloqueo de Windows. Con `NeverBlock`, cada petición con una contraseña desajustada hace 2 intentos, y con el umbral por omisión de Windows 11 (10 intentos) bastan **unas 5 peticiones para dejar sin servicio a todo el POS durante 10 minutos**. Además, cualquiera que llegue al puerto y conozca el nombre del login lo puede bloquear sin saber la contraseña [`[BL]` BL-01]. Hoy no existe ningún login SQL de servicio [V], así que es preventivo.
- **`gsf` está con la política apagada** en las dos instancias de la PC A, en contra de AC-1, que ya firmaste [V, `[BL]` BL-03]. Para una persona es al revés que para un servicio: el bloqueo **sí** conviene.

**El auditor confirmó la suposición clave** (en lo documental, para SQL Server 2022 y 2025): **los usuarios contenidos (`gpos_app_*`, `gpos_rpt_*`, `gpos_lec_*`) no tienen bloqueo por intentos fallidos.** La sintaxis de `CREATE USER … WITH PASSWORD` no admite `CHECK_POLICY` y no hay dónde guardar el estado de bloqueo. Lo que sí les llega es la complejidad [`[BL]` §0]. Falta una prueba empírica de 0,1 dp (QA o devops) que no cambia las remediaciones.

**Pregunta:** ¿se precisa PUB-06 para incluir M3, M5 corregido, M5-b y M5-c? ¿Se adopta la regla «política ON para las personas, OFF para los servicios»? ¿Se agregan R4 (puerto de SQL) y R5 (alerta del 18456)?

---

## 2. Resumen

| # | En una línea | Recomendación | Costo | Antes de |
|---|---|---|---|---|
| **PB-1 (M3)** | Ninguna instalación de cliente lleva el modo Amplio | **Aprobar** | ≈ 0 (minutos por instalación) | El primer cliente |
| **PB-2 (M5)** | Los logins SQL de servicio, sin política de bloqueo; los usuarios contenidos no se bloquean | **Aprobar** | ≈ 0,15 dp (R2) + 0,2 dp (R1), ya encargados al desarrollador I | Construir la variante S |
| **PB-3 (M5-b)** | Todo login SQL `sysadmin` habilitado, con `CHECK_POLICY = ON` (AC-1) | **Aprobar como hallazgo**, y corregir ya `gsf` en la PC A | 1 comando tuyo | Ya (desarrollo) y el primer cliente |
| **PB-4 (M5-c)** | Ningún usuario contenido se llama igual que un login | **Aprobar** | Incluido en R2 | Construir la variante S |
| **PB-5** | Precisión de ADR-44 (AC-1) y ADR-82: política ON para las personas y OFF para los servicios con contraseña de máquina | **Aprobar** | 0 | Junto con PB-2 |
| **PB-6 (R4)** | El puerto de SQL solo admite al equipo de la API | **Aprobar (a)** | ≈ 0,1 dp de devops (guía) | El primer cliente |
| **PB-7 (R5)** | Alerta de intentos fallidos (18456) | **Aprobar (b)** para la entrega 1; (a) con el agente | (b) ≈ 0,1 dp · (a) ≈ 0,5 dp | (b) la entrega 1 |

**Recomendación de conjunto: Aprobar con observaciones.** Nada de esto cambia el calendario del corte: PB-2 a PB-4 ya están en el encargo del desarrollador I (R1 y R2, unos 0,35 dp entre los dos), y PB-6 y PB-7 (b) son de devops. Las observaciones están en la sección 5.

---

## 3. Las decisiones, una por una

### PB-1 · M3: ninguna instalación de cliente lleva el modo Amplio

**Qué se decide.** Agregar a PUB-06 esta comprobación de `[LPR]` M3: en la instalación del cliente, `GPOS:Seguridad:ModoIdentidad` (o `GPOS__Seguridad__ModoIdentidad`) está ausente o vale `Estricto`:
- en la configuración del servicio `GPOS.Api`;
- en las variables de entorno del servicio y del equipo (`[Environment]::GetEnvironmentVariable('GPOS__Seguridad__ModoIdentidad','Machine')`);
- y en el Visor de eventos no hay ningún evento 5130 («IdentidadAmplia») después del arranque.

La hace el técnico de GSF. El paquete ya se arma con `-Destino Cliente`, que rechaza un paquete que fije Amplio (A10 de `[LPR]`), pero eso no cubre una variable puesta en el equipo después de instalar.

| Opción | Consecuencia |
|---|---|
| **(a) M3 en PUB-06, también cuando exista M4 (recomendada)** | Hasta que exista el bloqueo en código de DL-02 (M4), es la **única** barrera. Después queda como defensa en profundidad: M4 impide arrancar en Amplio con una licencia `Produccion` o `Beta`, pero no con una licencia ausente o de otro anillo [I] |
| (b) M3 solo hasta que exista M4 | Un control menos que mantener, pero una instalación sin licencia cargada podría quedar en Amplio sin que nadie lo vea |
| (c) No agregarla | Hasta M4, nada impide entregar un cliente en Amplio, que anula los `DENY` de RG-14 y la licencia (ADR-60, punto 6) |

**Costo:** unos minutos por instalación. Se puede automatizar después en `GPOS.Migracion verificar` [I].

`[ ] Aprobar (a)`   `[ ] (b)`   `[ ] (c)`

---

### PB-2 · M5 corregido: los logins SQL de servicio, sin política de bloqueo

**Qué se decide.** El texto de M5 de `[LPR]`, con las correcciones del auditor (R3):
- **Todo `SQL_LOGIN` que use la API o Backup Tool** tiene `is_policy_checked = 0`, `is_expiration_checked = 0` e `IsLocked = 0`, con una contraseña de 32 bytes del generador criptográfico. Hoy solo existiría en la variante S de ADR-82 (SQL Server en otro equipo sin dominio) o si Backup Tool no pudiera usar una cuenta de Windows.
- **Los usuarios contenidos** (`gpos_app_*`, `gpos_rpt_*` y `gpos_lec_*`) **no se bloquean** [`[BL]` §0] y no necesitan esta comprobación. Tampoco los logins de Windows ni las cuentas virtuales (`NT SERVICE\GPOS.Api`), que no están en `sys.sql_logins`.
- **Umbral:** donde `[LPR]` decía «unas decenas» de intentos, se lee «el umbral de Windows: **10 intentos** por omisión en Windows 11; en un dominio, el que fije el dominio».
- Lo detecta el hallazgo **`LOGIN_SERVICIO_CON_POLITICA`** de `GPOS.Migracion verificar` (cuenta para `--estricto`), que busca por SID los logins de la API, de Backup Tool y de reportes en `sys.sql_logins` (R2).
- Al crear un login SQL de servicio, `GPOS.Migracion` lo hace con `CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF` explícitos, con la contraseña generada en memoria y pasada como parámetro (nunca como variable de `sqlcmd`), y la cadena cifrada (SEC-05 b). Si ya existe con la política activa, `ALTER LOGIN … WITH CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF`, que además reinicia el bloqueo (R1).

| Opción | Consecuencia |
|---|---|
| **(a) Política apagada en los logins de servicio, con 32 bytes aleatorios (recomendada)** | La API no se bloquea a sí misma ni la bloquea un tercero que llegue al puerto. **Se acepta** que esas cuentas quedan sin bloqueo ni control de complejidad: la protección pasa a ser la entropía (256 bits; adivinarla en línea es inviable) más PB-6 y PB-7 |
| (b) Política activa con un umbral alto | **Descartada por devops y por el auditor:** el umbral lo fija el dominio del cliente, que GSF no controla |
| (c) Dejar la política por omisión | Con unas 5 peticiones desajustadas el POS entero queda 10 min sin servicio, y el bloqueo se renueva solo mientras siga el desajuste (BL-01 pasaría a **Alta**) |

**Costo:** R1 unos 0,2 dp y R2 unos 0,15 dp con pruebas, del desarrollador I (ya encargados por B). Ninguna licencia.

`[ ] Aprobar (a)`   `[ ] (b)`   `[ ] (c)`

---

### PB-3 · M5-b: los logins SQL de personas con `sysadmin`, con la política activa (AC-1)

**Qué se decide.** Agregar a PUB-06: **todo `SQL_LOGIN` habilitado con `sysadmin`** (`gsf` y los nominales de cada técnico) tiene `is_policy_checked = 1`. Es la verificación de AC-1, que ya firmaste el 2026-09-29. Lo detecta `LOGIN_ADMIN_SIN_POLITICA` en `verificar` (R2).

**Por qué es lo contrario que en PB-2.** Si alguien provoca el bloqueo de `gsf`, la instancia queda sin administración unos 10 minutos, pero el POS sigue vendiendo. A cambio, el bloqueo frena la fuerza bruta contra la cuenta más poderosa de la instancia. `CHECK_EXPIRATION` sigue apagado salvo que anotes la fecha de renovación, como dice AC-1.

**Situación hoy** [V, `[BL]` §1]: en las dos instancias de la PC A (`.` y `.\SQLEXPRESS`), `gsf` es `sysadmin` con `CHECK_POLICY = 0`. B informó lo mismo para su equipo. En desarrollo es Media; en un cliente sería Alta (BL-03). **Lo corriges tú, que custodias `gsf`:** un `ALTER LOGIN gsf WITH CHECK_POLICY = ON` en cada instancia, sin corte. No escribas la contraseña en ningún lado (AC-3).

| Opción | Consecuencia |
|---|---|
| **(a) `LOGIN_ADMIN_SIN_POLITICA` como hallazgo (recomendada)** | Coherente con AC-1, que está firmado. `verificar --estricto` falla en los equipos de desarrollo mientras `gsf` siga con la política apagada: se resuelve con el comando de arriba |
| (b) Como aviso, sin hallazgo | No interrumpe el desarrollo, pero una instalación de cliente con `gsf` sin política pasaría `verificar --estricto`. Si la eliges, M5-b queda como comprobación manual del técnico en PUB-06 |

**Costo:** dentro de R2; un comando tuyo por instancia.

`[ ] Aprobar (a)`   `[ ] (b)`

---

### PB-4 · M5-c: ningún usuario contenido se llama igual que un login

**Qué se decide.** Agregar a PUB-06: ninguna base de empresa tiene un usuario contenido (`authentication_type = 2`) con el mismo nombre que un login de la instancia. Microsoft documenta que, si existe, **ese login no puede entrar a la base contenida**, y lo trata como una denegación de servicio intencional o accidental [`[BL]` BL-05]. Lo detecta `CONTENIDO_DUPLICA_LOGIN` en `verificar` (R2). Para no provocarlo, los logins SQL de servicio usan un prefijo distinto de `gpos_app_`, `gpos_rpt_` y `gpos_lec_` (el auditor propone `gpos_srv_…`; el nombre lo fija el desarrollador I) (R1).

Hoy no hay choque: los logins de servicio son de Windows [V].

| Opción | Consecuencia |
|---|---|
| **(a) Comprobación y prefijo distinto (recomendada)** | Cierra BL-05 sin costo adicional |
| (b) Sin comprobación | Un nombre mal elegido en la variante S deja a la API sin entrar a las bases de empresa |

`[ ] Aprobar (a)`   `[ ] (b)`

---

### PB-5 · Precisión de ADR-44 (AC-1) y de ADR-82: política ON para las personas y OFF para los servicios

**Qué se decide.** Dejar escrita una regla general, para que no dependa de cada guion. Es la decisión candidata a ADR del auditor. El texto para registrar está en la sección 4.

| Opción | Consecuencia |
|---|---|
| **(a) Política `ON` en los logins SQL de personas; `OFF` en los de servicio con contraseña de máquina de 32 bytes; los usuarios contenidos no tienen bloqueo (recomendada)** | Cada tipo de cuenta queda con el control que le conviene: el bloqueo frena la fuerza bruta contra una persona y no puede tumbar un servicio |
| (b) Política `ON` con un umbral alto para todos | **Descartada por el auditor:** depende del dominio del cliente |
| (c) No escribir la regla y dejarla en las comprobaciones | Funciona igual hoy, pero la próxima identidad de servicio (por ejemplo, un conector) no tendría una regla firmada que seguir |

**Costo:** 0.

`[ ] Aprobar (a)`   `[ ] (b)`   `[ ] (c)`

---

### PB-6 · R4: el puerto de SQL solo admite al equipo de la API

**Qué se decide.** Como los usuarios contenidos y los logins de servicio no se bloquean, SQL Server no frena los intentos desde la red. La confidencialidad no corre peligro (256 bits), pero quedan dos efectos: en SQL Server 2025 cada intento fallido cuesta CPU del servidor que factura, porque el hash nuevo usa PBKDF2 con 100 000 iteraciones [D sobre el costo; magnitud I], y nadie se entera. Los frenos HTTP de K1 no ven una conexión directa al puerto de SQL [`[BL]` BL-02]. La guía de PUB-06 de devops agrega:

| Opción | Consecuencia | Costo |
|---|---|---|
| **(a) Si SQL Server está en el mismo equipo que la API (el caso normal), la instancia no escucha por TCP desde la red. Si hace falta TCP, el Firewall de Windows limita el puerto al equipo de la API; en la variante S, a la IP del equipo de la API (recomendada)** | Cierra el acceso directo al puerto desde el resto de la red del cliente. Una herramienta del cliente que hoy lea SQL por la red deja de poder hacerlo: los reportes externos van por la API de reportes (ADR-109) | ≈ 0,1 dp de devops; sin licencias |
| (b) Solo recomendarlo en la guía, sin comprobarlo | Depende de cada técnico | 0 |
| (c) Nada | Queda BL-02 (a) completo | 0 |

**Observación:** si un cliente necesita acceso SQL desde otro equipo (por ejemplo, su TI), se agrega su IP a la regla con motivo en el acta de instalación; nunca se abre el puerto a toda la red [I].

`[ ] Aprobar (a)`   `[ ] (b)`   `[ ] (c)`

---

### PB-7 · R5: alerta de intentos fallidos (error 18456)

**Qué se decide.** Hoy `audit level = failure` deja el 18456 en el registro de errores y en el Visor de eventos [V], pero nada lo lee ni avisa. SQL Server Express no tiene SQL Agent.

| Opción | Qué es | Consecuencia | Costo |
|---|---|---|---|
| (a) Agregación por el agente o la API | Leen el Visor de eventos (Aplicación, origen `MSSQL$<instancia>`, evento 18456) o una sesión de Extended Events, y avisan a GSF con más de N fallos en M minutos (valor inicial: 20 en 5 min, ajustable) | La alerta buena. Pero el agente automático (L4) no está en la entrega 1, y en la API le quita tiempo al desarrollador I, que tiene poco margen | ≈ 0,5 dp [I] |
| **(b) Tarea programada de Windows (recomendada para la entrega 1)** | Un desencadenador por el evento 18456 escribe una línea en la bitácora de GPOS; la crea el instalador | Deja rastro visible para el SUPER y para GSF, pero no agrega fallos ni avisa por tasa | ≈ 0,1 dp de devops |
| (c) Declararlo como residual aceptado | Nada se construye | Un intento masivo o un desajuste sostenido pasan sin que nadie lo vea | 0 |
| *Descartada* | Alertas de SQL Agent | Express no tiene Agent | — |

**Recomendación: (b) ahora**, porque es barata, la hace devops y no toca el margen del corte; **(a) cuando exista el agente**, como parte de su diseño. Si prefieres no gastar nada antes del corte, (c) es aceptable: hoy no hay ningún cliente y la confidencialidad no depende de esta alerta.

`[ ] (b) ahora y (a) con el agente`   `[ ] (a) ya`   `[ ] (c) residual`

---

## 4. Texto para registrar si firmas (B lo copia; ADR-44 no se edita hasta entonces)

### 4.1 En `docs/adr/ADR-044.md`, al final

> **Precisión del AAAA-MM-DD de AC-1 y de AC-8 (PUB-06): comprobaciones de publicación y política de bloqueo por tipo de cuenta (hoja de firma `traspasos/A/hoja-firma-pub06-m3-m5-2026-10-15.md` del área común\*; firmada por Leonardo Méndez, propietario, el AAAA-MM-DD: «<respuesta literal>»; fuentes: la lista de publicación Release de devops, `docs/operaciones/2026-10-15-lista-publicacion-release.md`, y el dictamen del auditor-seguridad sobre el bloqueo de usuarios contenidos, `revision-seguridad-bloqueo-usuarios-contenidos-2026-10-15.md`, Aprobado con observaciones).** Sin cambiar el texto firmado de arriba:
> 1. **Política de bloqueo por tipo de cuenta (PB-5; precisa AC-1).**
>    - Los **logins SQL de personas** (`gsf` y los nominales de cada técnico) tienen `CHECK_POLICY = ON`. `CHECK_EXPIRATION` solo si se anota la fecha de renovación (AC-1).
>    - Los **logins SQL de servicio** (la variante S de [ADR-82](ADR-082.md), punto 2, y Backup Tool si no puede usar una cuenta de Windows) se crean con `CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF` explícitos y una contraseña de 32 bytes del generador criptográfico, generada en memoria y guardada solo cifrada. Su nombre no coincide con el de ningún usuario contenido de GPOS NG.
>    - Los **usuarios contenidos** (`gpos_app_*`, `gpos_rpt_*`, `gpos_lec_*`) no tienen bloqueo por intentos fallidos; sí les llega la complejidad de Windows.
>    - Las cuentas de Windows y las cuentas virtuales no usan contraseña SQL.
> 2. **PUB-06 (AC-8) incluye además, antes de entregar a un cliente:**
>    - **M3 (PB-1):** `GPOS:Seguridad:ModoIdentidad` ausente o `Estricto` en la configuración del servicio y en las variables de entorno del servicio y del equipo, y ningún evento 5130 después del arranque. Se mantiene también después de que exista el bloqueo en código de DL-02.
>    - **M5 (PB-2):** todo `SQL_LOGIN` de servicio con `is_policy_checked = 0`, `is_expiration_checked = 0` e `IsLocked = 0` (`LOGIN_SERVICIO_CON_POLITICA`).
>    - **M5-b (PB-3):** todo `SQL_LOGIN` `sysadmin` habilitado con `is_policy_checked = 1` (`LOGIN_ADMIN_SIN_POLITICA`, <hallazgo | aviso, según la opción firmada>).
>    - **M5-c (PB-4):** ningún usuario contenido con el mismo nombre que un login (`CONTENIDO_DUPLICA_LOGIN`).
>    - **R4 (PB-6, si se firma (a)):** la instancia no escucha por TCP desde la red, o el Firewall de Windows limita el puerto al equipo de la API.
>    - **R5 (PB-7, según la opción firmada):** <tarea programada sobre el evento 18456 | agregación por el agente | residual aceptado>.
> 3. **Riesgo aceptado:** las cuentas de servicio y los usuarios contenidos quedan sin bloqueo; los protegen la entropía de 256 bits, el puerto restringido y la alerta del 18456.
>
> **Decidido, no implementado.**
>
> \* *La hoja vive en el área común; no está copiada en `master`.*

### 4.2 En `docs/adr/ADR-082.md`, al final

> **Nota del registro (AAAA-MM-DD): política de bloqueo de las identidades de servicio (precisión de [ADR-44](ADR-044.md) de la misma fecha, PB-5).** Los logins SQL de la variante S (punto 2) y, si llega a ser SQL, el de Backup Tool (punto 11) se crean con `CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF` y un nombre distinto de los usuarios contenidos `gpos_app_*`, `gpos_rpt_*` y `gpos_lec_*`. Los usuarios contenidos del punto 3 no tienen bloqueo por intentos fallidos (dictamen del auditor-seguridad del 2026-10-15). `GPOS.Migracion verificar` informa `LOGIN_SERVICIO_CON_POLITICA`, `LOGIN_ADMIN_SIN_POLITICA` y `CONTENIDO_DUPLICA_LOGIN`.

---

## 5. Riesgos, observaciones y lo que no cubre esta hoja

| # | Observación | Severidad | Cómo queda |
|---|---|---|---|
| O-1 | **`gsf` sin política en la PC A** (BL-03), en contra de AC-1 | Media (Alta en un cliente) | Lo corriges tú con un comando por instancia; no necesita esta firma porque AC-1 ya está firmado |
| O-2 | La suposición sobre los usuarios contenidos está confirmada **en lo documental**, no en una prueba | Baja | Prueba empírica de 0,1 dp en una instancia desechable (QA o devops). No cambia las remediaciones |
| O-3 | **BL-04:** la complejidad de Windows puede rechazar 1 de cada unas 7 600 contraseñas generadas (base64url sin dígito ni símbolo) | Baja | R6 del desarrollador I (0,05 dp): regenerar hasta tener las cuatro categorías. Sin firma: aplica lo ya firmado |
| O-4 | **BL-06 (sospecha):** restaurar una copia de empresa anterior a una rotación deja 18456 persistentes | Baja | Lo confirma el dueño de H-11; si hace falta, la restauración termina con `credencial-app --rotar`. Sin firma |
| O-5 | **M6** (`contained database authentication = 1`): hoy está en 0 en las dos instancias locales, y D-04 (a) la necesita | Baja | La activa el paso S0 (`database/rg14/rg14-00-servidor.sql:22-26` [V, según `[BL]`]). Es la verificación de algo ya firmado: B puede agregarla a la lista de PUB-06 sin firma |
| O-6 | **En SQL Server 2025** cada intento fallido cuesta más CPU (PBKDF2) | Baja [I, sin medir] | Lo acotan PB-6 y la reapertura única por petición de la API |

**Alternativas consideradas en conjunto:** firmar solo M3 y M5 como pidió B (deja `gsf` y el puerto sin regla, con el dictamen ya disponible), o esperar a construir la variante S para decidir (con el riesgo de que BL-01 pase a Alta si se construye antes de la firma). Recomiendo firmarlo todo ahora: no cuesta tiempo de desarrollo del corte más allá de lo ya encargado.

---

## 6. Si firmas / si rechazas

**Si firmas según la recomendación:**
- B registra la sección 4 en `master` (ADR-44 y la nota de ADR-82) y actualiza `[LPR]`.
- El desarrollador I construye R1 y R2 (y R6) con S0 y la variante S.
- Devops agrega PB-6 (a) y PB-7 (b) a la guía de PUB-06 y hace la prueba empírica de O-2 junto con QA.
- Tú corriges `gsf` en las dos instancias de la PC A (y en el equipo B).

**Si rechazas alguna:**
- **PB-1:** hasta M4 nada impide entregar un cliente en Amplio.
- **PB-2 (c):** la variante S puede dejar el POS sin servicio con unos 10 intentos; BL-01 pasa a Alta y bloquea la variante S.
- **PB-3 (b):** M5-b queda como comprobación manual.
- **PB-4:** riesgo de denegación por nombres duplicados en la variante S.
- **PB-5:** las reglas quedan solo en las comprobaciones, sin texto firmado para las identidades futuras.
- **PB-6 o PB-7 (c):** BL-02 queda como residual aceptado de forma expresa.

---

## 7. Registro de la firma

| Campo | Valor |
|---|---|
| Firmado por | — |
| Fecha | — |
| Respuesta literal | — |
| Firmadas | — |
| Siguen Pendientes de firma | PB-1 a PB-7 |

### Cierre
- Estado: Pendiente de firma (recomendación: Aprobar con observaciones)
- Artefactos: `GPOS-NG-Equipos\traspasos\A\hoja-firma-pub06-m3-m5-2026-10-15.md`
- Supuestos: la protección de M3 frente a una licencia ausente es inferida; los costos de R4 y R5 son los del auditor (inferidos); el umbral de 10 intentos vale para Windows 11 sin dominio
- Decisiones candidatas a ADR: precisión de ADR-44 (AC-1 y AC-8) y nota de ADR-82 (sección 4)
- Entregas a otros agentes: desarrollador I → R1, R2 y R6; devops → R4, R5 y la prueba empírica con QA; dueño de H-11 → BL-06; propietario → `gsf` con `CHECK_POLICY = ON`
- Próximo paso recomendado: que B presente esta hoja al propietario junto con la corrección de `gsf`
