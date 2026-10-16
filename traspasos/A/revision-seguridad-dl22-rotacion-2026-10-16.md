# Informe de seguridad · DL-22 (a): rotación de `gpos_app_a|b` con DENY inmediato y KILL diferido

- **Fecha:** 2026-10-16 · **Autor:** auditor-seguridad (equipo A) · **Para:** coordinación de A y arquitecto-maestro (vía B)
- **Objeto:** commit `367128f0` de la rama `a/dl22-rotacion` (árbol `GPOS-NG-dl22`), base `ce33b2a8` (`git diff ce33b2a8 367128f0`, 11 archivos, +601 / −112).
- **Referencia firmada:** precisión del 2026-10-15 del punto 3 de ADR-82 (`traspasos/A/adr-licencia-2026-10-15/ADR-082-precisiones-2026-10-15.md`), puntos 1 a 7 y riesgo aceptado.
- **Método:** lectura estática del diff y del código circundante en el commit. **No** se compiló, no se ejecutaron pruebas ni se tocó SQL (por instrucción). Lo que depende del comportamiento del motor se cita como verificado **por el desarrollador** (comentario de la prueba PA-30) o como inferido.

**Dictamen (recomendación técnica, C2): Aprobado con observaciones** en lo que toca a seguridad: no hay hallazgos Críticos ni Altos. Aparte, **DL-22 no se puede dar por cerrada**: el punto 7 firmado (PA-30, «ningún 500») no se cumple, y el remedio firmado («subir hacia 6 min») no ataca la causa. Hace falta una precisión nueva de ADR-82, que prepara el arquitecto-maestro y firma el propietario (estado: **Pendiente de firma**). Mi opinión sobre las opciones A y B está en la sección 8.

---

## 1. Alcance y superficie revisada

| Superficie | Archivos |
|---|---|
| Comando administrativo `GPOS.Migracion credencial-app` (identidad del técnico de GSF, permisos de servidor) | `src/GPOS.Migracion/CredencialApp.cs`, `src/GPOS.Migracion/Program.cs` |
| SQL dinámico de usuarios contenidos, `DENY`, `KILL` | `src/GPOS.Migracion/Lectura/CredencialesLectura.cs` |
| Verificación S4 (`verificar`) | `src/GPOS.Migracion/VerificacionPrivilegios.cs` |
| API: caché de cadenas, `ClearPool`, `Connection Lifetime`, reapertura ante 18456 | `src/GPOS.Api/Program.cs`, `src/GPOS.Core/Infraestructura/CadenaConexion.cs`, `src/GPOS.Core/Infraestructura/Motor/ReaperturaConexionEmpresa.cs`, `src/GPOS.Core/Sistema/EmpresasService.cs` |
| Pruebas (solo para el plazo de Debug y la marca de PA-30) | `tests/GPOS.Tests/ModeloNg/Rg14Lote2Tests.cs` |

No hay endpoints anónimos nuevos. El cambio de la API es interno (manejo de errores y del grupo de conexiones).

## 2. Resumen de hallazgos

| ID | Severidad | Título | Estado |
|---|---|---|---|
| DL22-S01 | Media | El punto 7 (PA-30, «ningún 500») no se cumple y el remedio firmado no sirve: la causa es el DENY, no el KILL | Verificado (código) / verificado por el desarrollador (motor) |
| DL22-S02 | Media | `--urgente` termina con éxito (código 0) aunque no haya podido ver o cerrar las sesiones | Verificado |
| DL22-S03 | Baja | Los permisos de servidor se comprueban después de rotar: un fallo deja la rotación hecha y el KILL obligatorio sin hacer | Verificado |
| DL22-S04 | Baja | Si se agotan los reintentos 1205 al negar CONNECT, el mensaje es genérico y las dos generaciones quedan con CONNECT | Verificado |
| DL22-S05 | Baja | Si el proceso se interrumpe durante el plazo, el KILL queda pendiente sin rastro, y S4 solo da un aviso aunque el plazo haya vencido hace rato | Verificado |
| DL22-S06 | Baja | El bucle de KILL no tiene tope de tiempo | Verificado |
| DL22-S07 | Baja | `Connection Lifetime` igual al plazo, sin margen | Verificado (código) / inferido (efecto) |
| DL22-S08 | Baja | Las opciones desconocidas no se rechazan: un `--urgente` mal escrito puede acabar como rotación normal | Verificado (parser) / sospecha (caso real) |

## 3. Checklist OWASP (Top 10 2021)

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | Correcto en lo esencial. El KILL se limita a los usuarios contenidos de la base (sección 5). Observaciones en S02 y S03 (permisos). |
| A02 Fallos criptográficos | Correcto. Contraseña de 256 bits del generador criptográfico; la cadena se guarda cifrada con el anillo de la API (sin cambios en este commit). |
| A03 Inyección | Correcto. Ver sección 5. |
| A04 Diseño inseguro | S01 (el criterio firmado no se puede cumplir con el mecanismo firmado), S05 (sin estado persistente de retiro pendiente). |
| A05 Configuración de seguridad | Correcto. El plazo corto solo existe en Debug, con guarda transitiva de Release (sección 5). |
| A06 Componentes vulnerables | No aplica (no hay paquetes nuevos). |
| A07 Identificación y autenticación | La rotación cumple la intención: la generación anterior pierde el acceso. Ver S01 y la sección 8. |
| A08 Integridad de software y datos | Correcto. Los reintentos son idempotentes (sección 5). Observación en S04. |
| A09 Registro y monitoreo | Ni la contraseña ni la cadena llegan a la salida ni a los registros. Observaciones en S02 (código de salida) y S05 (S4 solo avisa). |
| A10 SSRF | No aplica. |

## 4. Hallazgos

### DL22-S01 · Media · PA-30 «ningún 500» no se cumple y el remedio firmado no sirve

- **Riesgo:** no es una vulnerabilidad. Es una falta de conformidad con un criterio firmado. La precisión firmada dice que, si PA-30 da errores 500 con 2 minutos, el plazo se sube hacia 6. Según la medición del desarrollador, los 500 salen **en el instante del DENY** y no al vencer el plazo, así que subir el plazo no los quita. Si se aplicara el remedio tal como está, el plazo de las sesiones de la generación anterior crecería (más exposición) sin ganar nada.
- **Evidencia:**
  - `tests/GPOS.Tests/ModeloNg/Rg14Lote2Tests.cs:772-782`: la prueba está marcada `Transicion=Defecto`. El comentario documenta que, en SQL Server 2019, el 916 llega a las sesiones abiertas y el 18456 a la primera orden de una conexión reutilizada del grupo. Salen de 6 a 10 respuestas 500 por cada 750 a 2600 peticiones, en 6 de 6 corridas. El hallazgo lo verificó el desarrollador; yo no lo reproduje.
  - `src/GPOS.Migracion/CredencialApp.cs:175-188`: se guarda la cadena nueva y se niega CONNECT a la anterior en la misma ejecución, sin esperar a que la API cambie de cadena.
  - `src/GPOS.Core/Sistema/EmpresasService.cs:24-37`: la caché de cadenas no caduca. La API solo cambia de cadena después de un 18456 (`src/GPOS.Api/Program.cs:405-407`), y ese 18456 llega a la primera orden y no a la apertura, que es lo único que reintenta `ReaperturaConexionEmpresa`.
- **Lectura de seguridad:** el comportamiento real es **más estricto** que lo firmado. El riesgo aceptado decía «la generación anterior conserva sus sesiones abiertas durante el plazo», pero con el 916 esas sesiones dejan de ejecutar sentencias en el acto. El KILL diferido queda como limpieza.
- **Remediación:** no subir el plazo. Llevar la decisión al arquitecto-maestro como precisión del punto 1 (secciones 8 y 9). Mientras no se firme, la marca `Transicion=Defecto` es correcta y debe salir como pendiente en el informe de DL-22.

### DL22-S02 · Media · `--urgente` informa éxito aunque no haya podido ver o cerrar las sesiones

- **Riesgo:** `--urgente` es el camino de contención ante un compromiso. Si a la identidad que lo ejecuta le falta `VIEW SERVER STATE`, la consulta de sesiones solo devuelve la propia y la lista sale vacía (T3-13). Si le falta `ALTER ANY CONNECTION`, el KILL falla con 6102 o 297. En los dos casos `CerrarSinEsperaAsync` devuelve solo un texto, `AplicarAsync` termina bien y el proceso sale con código 0. El operador puede creer que la contención está completa. El riesgo se atenúa porque, según el desarrollador, la sesión que siga abierta ya no ejecuta sentencias (916).
- **Evidencia:** `src/GPOS.Migracion/CredencialApp.cs:198-206` (no hay `throw` ni comprobación de que no queden sesiones). Compárese con la rotación normal, que sí falla: `CredencialApp.cs:217-219` y `235-237`. Código de salida: `src/GPOS.Migracion/Program.cs:268-278` (solo pone `Error` si hay excepción).
- **Remediación (unos 0,05 dp, inferido):** en `--urgente`, exigir los dos permisos y lanzar un error si falta alguno o si queda `sinPermiso > 0`. Después del KILL, repetir la lectura hasta que no quede ninguna sesión (el mismo bucle de `CerrarAlVencerAsync`). Mejor todavía: hacer la comprobación de permisos **antes** de rotar (ver S03). Como defensa en profundidad, en `--urgente` cambiar también la contraseña de la generación anterior por una aleatoria que se descarta (ver la opción B).

### DL22-S03 · Baja · Los permisos se comprueban después de rotar

- **Riesgo:** `VIEW SERVER STATE` se comprueba después de guardar la cadena y negar CONNECT, y `ALTER ANY CONNECTION` recién al vencer el plazo. Si falta alguno, la rotación ya está hecha y el KILL obligatorio (punto 2) queda sin cumplir. El mensaje pide repetir `credencial-app`, y repetirlo **vuelve a rotar**: activa la generación que se acaba de negar y niega la nueva, en lugar de completar el retiro. No hay exposición, porque CONNECT ya está negado, pero el resultado es confuso y se rota dos veces sin necesidad.
- **Evidencia:** `src/GPOS.Migracion/CredencialApp.cs:217-219` y `235-237` (comprobación tardía); `CredencialApp.cs:168-170` (cada ejecución toma la otra generación).
- **Remediación (unos 0,05 dp):** antes de `CrearUsuarioAsync`, comprobar `HAS_PERMS_BY_NAME(NULL, NULL, 'ALTER ANY CONNECTION')` y `VIEW SERVER STATE` (o `VIEW SERVER PERFORMANCE STATE`) y fallar con «no se cambió nada». Si se quiere permitir que se repita, que `credencial-app` detecte una generación anterior con sesiones y CONNECT negado y complete el retiro sin volver a rotar.

### DL22-S04 · Baja · Si se agotan los reintentos 1205 en el DENY, el mensaje es genérico

- **Riesgo:** si `NegarConnectAsync` pierde 5 interbloqueos seguidos, la `SqlException` sale **después** de guardar la cadena nueva. Quedan las dos generaciones con CONNECT y el mensaje explícito de RG2-02 («puede seguir entrando…») no aparece, solo «SQL Server 1205: …». El código de salida sí es `Error`, y S4 `GPOS_APP_CONNECT` lo detecta (`VerificacionPrivilegios.cs:133-140`). Las lecturas que vienen después (`SinConnectAsync`, `SesionesAsync`, el KILL) no tienen reintento, y con `DEADLOCK_PRIORITY LOW` también pueden ser víctimas. Si eso pasa durante la espera, se abandona el KILL pendiente.
- **Evidencia:** `src/GPOS.Migracion/CredencialApp.cs:182-186`, `254-264`; `CredencialApp.cs:140` (prioridad de toda la sesión).
- **Remediación (unos 0,02 dp):** envolver el DENY para que, si se agotan los reintentos, lance la misma `ReglaNegocioException` de RG2-02. Aplicar el reintento 1205 también a las lecturas del bucle de espera, o volver a `DEADLOCK_PRIORITY NORMAL` después del DDL.

### DL22-S05 · Baja · Si el proceso se interrumpe durante el plazo, el KILL queda pendiente sin rastro

- **Riesgo:** si durante los 2 a 6 minutos se pulsa Ctrl+C, se cae la conexión administrativa o se reinicia el servidor, el KILL no se hace y no queda constancia persistente. S4 solo lo informa como **aviso** (`Avisos`, `VerificacionPrivilegios.cs:542`), así que `verificar --estricto` no lo convierte en hallazgo aunque la sesión lleve horas. El riesgo es bajo por el 916.
- **Evidencia:** `src/GPOS.Migracion/CredencialApp.cs:220-243` (todo en memoria); `src/GPOS.Migracion/VerificacionPrivilegios.cs:144-154` (`GPOS_APP_SESION_ANTERIOR`, sin mirar `login_time`).
- **Remediación (unos 0,05 dp):** en S4, separar en dos condiciones: dentro del plazo máximo firmado (`login_time` dentro de los últimos 6 min), aviso; pasado ese tiempo, hallazgo (código 4 con `--estricto`). Así S4 es la red de seguridad del KILL obligatorio. Además, S4 debería decir cuándo no puede ver sesiones por falta de `VIEW SERVER STATE`, en lugar de devolver vacío (sospecha: no revisé si `verificar` ya lo avisa en otro lugar).

### DL22-S06 · Baja · El bucle de KILL no tiene tope

- **Riesgo:** de disponibilidad del comando, no de confidencialidad. Una sesión que deshace una transacción larga tras el KILL mantiene `credencial-app` en el bucle sin límite, porque el token de cancelación es `CancellationToken.None` (`Program.cs:263-269`). Con `--todas`, eso bloquea la rotación de las empresas siguientes.
- **Evidencia:** `src/GPOS.Migracion/CredencialApp.cs:232-242`.
- **Remediación:** poner un tope (por ejemplo, el plazo más 2 minutos) con un error explícito que diga que la sesión sigue deshaciendo su transacción, y dejar a S4 el seguimiento (S05).

### DL22-S07 · Baja · `Connection Lifetime` igual al plazo, sin margen

- **Riesgo:** `Load Balance Timeout` solo se evalúa cuando la conexión vuelve al grupo. Una conexión creada justo antes de la rotación y tomada a los 119 s puede seguir en uso al vencer los 120 s. Con el diseño actual no cambia nada, porque el DENY ya rompe esas conexiones. Pero si se elige la opción B, ese margen decide si el KILL al vencer el plazo produce un 500 (el desarrollador ya vio alguno «in the kill state»).
- **Evidencia:** `src/GPOS.Core/Infraestructura/CadenaConexion.cs:28` (`VidaMaximaApiSegundos = 120`), `src/GPOS.Migracion/CredencialApp.cs:244`.
- **Remediación:** con la opción B, fijar el Lifetime por debajo del plazo menos la duración máxima de una petición (por ejemplo, 90 s con un plazo de 2 min). La firma dice «igual o menor», así que no hace falta firmar de nuevo.

### DL22-S08 · Baja · Las opciones desconocidas no se rechazan

- **Riesgo:** `Argumentos.Leer` acepta cualquier `--nombre` que no sea una bandera y le asigna el argumento siguiente. Los errores tipográficos más probables con `--urgente` terminan en error («Falta el valor», «Argumento no esperado» o un plazo no numérico), pero no está garantizado para todas las combinaciones. Que una contención de urgencia se ejecute en silencio como rotación normal es justo el tipo de error que no conviene.
- **Evidencia:** `src/GPOS.Migracion/Program.cs:333-346`.
- **Remediación:** lista blanca de opciones por comando y error ante cualquier otra. Es un cambio general del parser y conviene hacerlo en su propio lote.

## 5. Controles que están bien implementados

- **La contraseña no sale de memoria.** Se genera con `RandomNumberGenerator`: 32 bytes en base64url, 43 caracteres (`src/GPOS.Migracion/ClavesSql.cs:21-28`). Viaja como parámetro y se escapa con `QUOTENAME(@c, '''')` (`Lectura/CredencialesLectura.cs:212-226`); con 43 caracteres no llega al límite de 128 de `QUOTENAME`, y aunque lo pasara el fallo sería seguro, porque `EntraAsync` no entraría y no se guardaría nada. No aparece en `Acciones`, en `avance` ni en los mensajes de excepción (`CredencialApp.cs:172-188`, `216-243`). `PersistSecurityInfo = false` (`CredencialApp.cs:257-262`). `EntraAsync` usa `Pooling = false` (`CredencialApp.cs:290-309`). `ConVidaAcotada` y `LimpiarGrupos` solo reconstruyen la cadena en memoria (`CadenaConexion.cs:38-46`, `61-69`). La prueba PA-30 extrae de los registros de la API solo el número y el texto del error de SQL Server (`Rg14Lote2Tests.cs:748-751`); el texto de un 18456 lleva el nombre del usuario, no la contraseña.
- **Sin inyección en el SQL dinámico.**
  - Nombres: `Prefijo + "a" | "b"` sale de constantes, y `Generacion()` solo devuelve `a`, `b` o null (`CredencialApp.cs:94-102`, `168`). Además pasan como parámetro `@u` y se citan con `QUOTENAME` en `CREATE USER`, `ALTER USER`, `GRANT`, `DENY` y `ALTER ROLE` (`CredencialesLectura.cs:214-226`, `285-293`).
  - KILL: el número es un `short` leído de `sys.dm_exec_sessions` y se formatea con la cultura invariante (`CredencialesLectura.cs:319-325`). No hay entrada externa.
  - `--plazo`: `NumberStyles.None`, cultura invariante y rango de 2 a 6 validados **antes** de tocar nada (`CredencialApp.cs:50-58`, `128-130`; `Program.cs:260`).
- **El alcance del KILL es correcto.** La consulta filtra por `login_name = @u AND authenticating_database_id = DB_ID() AND session_id <> @@SPID` (`CredencialesLectura.cs:306-309`). Un inicio de sesión de servidor con el mismo nombre se autentica en `master` (id 1, inferido de la documentación del motor) y no se toca. Las sesiones de otras bases y la propia quedan fuera. S4 usa el mismo filtro (`VerificacionPrivilegios.cs:147-149`).
- **El plazo corto existe solo en Debug.** `PlazoPruebas` y su uso están dentro de `#if DEBUG` (`CredencialApp.cs:30-35`, `40-42`), y ninguna opción de la línea de comandos lo asigna. La prueba comprueba en Release que la propiedad no existe (`Rg14Lote2Tests.cs:438-442`). `GPOS.Migracion` no tiene una guarda propia DEBUG/Release, pero depende de `GPOS.Core`, que depende de `GPOS.Criptografia`, y la guarda de esta (`GPOS.Criptografia.csproj`, target `ComprobarDebugCoherente`) hace fallar una compilación Release con `DEFINE DEBUG` (inferido de la cadena de referencias, sin compilar). Como mejora opcional, se puede añadir a `Comprobar-PublicacionRelease.ps1` la comprobación de que `RotacionApp` no tiene `PlazoPruebas`.
- **El reintento ante 1205 es idempotente.**
  - `CrearUsuarioAsync` repite `ALTER USER … WITH PASSWORD` con la misma clave, un `GRANT CONNECT` idempotente y `ALTER ROLE` protegido por `IS_ROLEMEMBER`. `NegarConnectAsync` comprueba si el DENY ya existe. Cada sentencia se confirma sola y el 1205 (severidad 13) no cierra la conexión.
  - Si se agotan los reintentos **antes** de guardar, la cadena de la empresa no cambia y la generación vigente sigue entrando, así que no hay corte. La generación nueva puede quedar con CONNECT sin ser la vigente, y S4 `GPOS_APP_CONNECT` la marca.
  - `DEADLOCK_PRIORITY LOW` solo afecta a la sesión de `credencial-app` (`CredencialApp.cs:140`).
  - El caso de los reintentos agotados en el DENY está en S04.
- **`--urgente` no se combina mal con `--plazo`.** Son excluyentes (`CredencialApp.cs:53`). `--plazo --urgente` hace que `--urgente` se tome como valor del plazo, y el parseo numérico lo rechaza. Con `--todas`, cada empresa se trata por separado.
- **Mensajes de permisos precisos.** Nombran el permiso exacto (`VIEW SERVER STATE` y `ALTER ANY CONNECTION`) y la identidad que debe ejecutar el comando (`CredencialApp.cs:218-219`, `236-237`). En el DENY, `SinConnectAsync` comprueba el resultado real, no se limita a confiar en que la sentencia no dio error (`CredencialApp.cs:184-186`).
- **`ClearPool` en los dos grupos.** Cubre el de las peticiones y el de los trabajos (`CadenaConexion.cs:61-69`) y también la cadena de la conexión que falló (`ReaperturaConexionEmpresa.cs:29`, `47`, `114-117`). La carrera con otra petición está documentada y es inocua: solo se pierden conexiones libres.
- **Lifetime acotado al leer las cadenas guardadas antes.** Se aplica solo a `gpos_app_*` (`CadenaConexion.cs:38-46`, `EmpresasService.cs:261`). Es defensa en profundidad para las cadenas anteriores a DL-22.

## 6. Remediaciones priorizadas

| Prioridad | ID | Acción | Esfuerzo (inferido) |
|---|---|---|---|
| 1 | S01 | Precisión de ADR-82, punto 1 (sección 8). No subir el plazo como remedio. | Decisión; implementar 0,2 a 0,4 dp según la opción |
| 2 | S02 | `--urgente` falla si no puede ver o cerrar sesiones; comprobación final sin sesiones | 0,05 dp |
| 3 | S03 | Comprobar los permisos antes de rotar; completar el retiro sin volver a rotar | 0,05 dp |
| 4 | S05 | S4: hallazgo si queda una sesión anterior pasados 6 min; avisar de la falta de `VIEW SERVER STATE` | 0,05 dp |
| 5 | S04 | Mensaje RG2-02 si se agotan los 1205; reintento en las lecturas del bucle | 0,02 dp |
| 6 | S06, S07, S08 | Tope del bucle de KILL; Lifetime con margen si se elige B; lista blanca de opciones | 0,05 dp en total más el lote del parser |

## 7. Recomendación

**Aprobado con observaciones** (recomendación técnica; no hay Crítico ni Alto). S02 y S03 conviene corregirlos en esta misma rama antes de unir. El cierre de DL-22 depende de la decisión sobre PA-30 (S01), que está **Pendiente de firma** del propietario.

## 8. Opinión de seguridad sobre las opciones A y B

**Lo firmado como referencia.** Con el DENY inmediato:

- la credencial anterior deja de servir para conexiones nuevas en milisegundos;
- según el desarrollador, sus sesiones abiertas dejan de ejecutar sentencias en el acto (916);
- el riesgo aceptado (sesiones vivas durante el plazo) en la práctica no llega a ocurrir.

Es la variante más estricta, pero da de 6 a 10 respuestas 500 en cada rotación. Cualquier cambio para quitar los 500 abre alguna ventana que hoy no existe. La pregunta es cuál y de qué tamaño.

**El dato que decide.** Según el comentario de la prueba (`Rg14Lote2Tests.cs:772-778`), cambiar la contraseña con `ALTER USER … WITH PASSWORD` tampoco deja reutilizar las conexiones del grupo: «solo falla la reutilizada». Por eso **ninguna** invalidación de la credencial anterior evita los 500 si la API sigue tomando conexiones del grupo viejo. La condición necesaria, tanto en A como en B, es que **la API pase a la cadena nueva antes de que se toque la anterior**.

### Opción A: la API toma la cadena nueva (caché de unos 5 s o una señal) y el DENY se aplica a unos 10 s

- **Ventana nueva:** la credencial anterior sigue **plenamente válida para conexiones nuevas** unos 10 s después de guardar la nueva. Las sesiones de la generación anterior (también las de un atacante) ejecutan sentencias hasta ese DENY.
- **Valoración:** riesgo **Bajo** para una rotación de rutina. La credencial tiene 256 bits y se guarda cifrada. Para conocerla hace falta haber comprometido el anillo de la API o la memoria del proceso, y en ese caso corresponde `--urgente`, que no cambia.
- **Punto débil:** si el proceso se interrumpe entre guardar y negar, la credencial anterior queda válida **sin límite** con su contraseña conocida. Hoy esa ventana dura milisegundos; con A pasaría a unos 10 s. S4 `GPOS_APP_CONNECT` lo detecta, pero solo si alguien ejecuta `verificar`.
- **Condiciones si se elige:**
  - espera fija con tope en el código (≤ 15 s), no configurable hacia arriba;
  - preferir la caché con caducidad (sin superficie nueva) a una señal empujada; si hay señal, que solo provoque releer la cadena cifrada de GPOS_SYSDATA y que nunca transporte la cadena;
  - S05 resuelto, para que una interrupción quede a la vista;
  - `--urgente` sin espera.
- **Costo:** unos 0,2 dp, más una lectura de GPOS_SYSDATA cada 5 s por empresa activa (despreciable).

### Opción B: cambiar la contraseña de la anterior en el acto y aplicar DENY y KILL al vencer el plazo, con sondeo en la apertura

- **Ventana de credencial:** prácticamente nula. La contraseña conocida deja de servir en el acto y la nueva, aleatoria, se descarta sin guardarse. Es tan fuerte como el DENY frente al robo de la credencial.
- **Ventana de sesiones:** las sesiones abiertas de la generación anterior **siguen ejecutando sentencias hasta el plazo** (2 a 6 min), porque cambiar la contraseña no las corta (verificado por el desarrollador). Es justo el «riesgo aceptado» del texto firmado, así que **B está dentro de lo que el propietario ya aceptó**, aunque es menos estricta que el comportamiento actual (916 inmediato).
- **Robustez ante interrupción:** mejor que A y que lo actual. Si el proceso muere antes del DENY, la generación anterior queda con CONNECT pero con una contraseña que nadie conoce. S4 lo marca y el riesgo residual es despreciable.
- **Condición imprescindible:** el «sondeo en la apertura» tiene que hacer que la API deje de usar el grupo viejo **antes** del cambio de contraseña. Si no, los 500 vuelven por la conexión reutilizada (ver el dato que decide). Para que el sondeo no cueste una consulta a GPOS_SYSDATA en cada apertura, se puede comparar una versión de la fila (`rowversion` de `dbo.Empresas`) guardada en caché ≤ 1 s. Cuando la API detecta el cambio, hace `ClearPool` del grupo viejo.
- **Otras condiciones:** ajustar el Lifetime con margen (S07), para que el KILL al vencer el plazo no alcance conexiones en uso, y en `--urgente` hacer DENY, cambio de contraseña y KILL en el acto.
- **Costo:** de 0,3 a 0,4 dp (inferido), por el sondeo con versión en la API.

### Recomendación del auditor

**B es preferible a A** desde el punto de vista de la seguridad: cierra en el acto la ventana más peligrosa (una credencial conocida que sigue autenticando) y es más robusta ante interrupciones. Lo que cede (sesiones vivas hasta el plazo) es exactamente lo que ya firmó el propietario.

Para reducir también la ventana de sesiones, propongo una **variante B+** como opción de la precisión:

1. guardar la cadena nueva;
2. la API la toma en la siguiente apertura gracias al sondeo con versión;
3. cambiar la contraseña de la anterior en el acto;
4. **DENY a los ~10 a 15 s**, cuando ya no quedan peticiones en curso con el grupo viejo, en lugar de esperar al final del plazo;
5. KILL al vencer el plazo.

Así la ventana de credencial queda en cero, la de sesiones en unos 15 s, y los 500 desaparecen siempre que el sondeo funcione. El costo es el mismo que el de B.

**Alternativa descartada:** mantener lo firmado y aceptar los 500 en cada rotación. Es la variante más segura, pero contradice el punto 7 y la intención firmada («sin errores visibles para el cajero en una rotación de rutina»).

**Cualquiera de las tres opciones cambia el punto 1 firmado («DENY CONNECT de inmediato») y necesita una precisión de ADR-82 que prepara el arquitecto-maestro y firma el propietario. Ninguna se debe implementar antes de esa firma.**

---

### Cierre
- Estado: Aprobado con observaciones (seguridad); cierre de DL-22 Pendiente de firma (S01).
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\revision-seguridad-dl22-rotacion-2026-10-16.md`
- Supuestos: el 916 en las sesiones abiertas y el 18456 en las conexiones reutilizadas tras el DENY o tras `ALTER USER … PASSWORD` son mediciones del desarrollador en SQL Server 2019 Express (no reproducidas aquí); `authenticating_database_id = 1` para los inicios de sesión de servidor es inferido de la documentación del motor; la guarda de Release transitiva se infiere de las referencias entre proyectos, sin compilar.
- Decisiones candidatas a ADR: precisión del punto 1 de ADR-82 (DL-22): opción A, B o B+ (recomendada B o B+), con las condiciones de la sección 8.
- Entregas a otros agentes: arquitecto-maestro → preparar la precisión del punto 1 y de PA-30 con las opciones A, B y B+ para la firma del propietario; desarrollador de identidades → corregir S02 y S03 en `a/dl22-rotacion` antes de unir, y después S04 a S07; qa-automatizado → con la opción firmada, PA-30 debe medir también la ventana de credencial y de sesiones, además de los 500.
- Próximo paso recomendado: corregir S02 y S03 en la rama y llevar al arquitecto-maestro la decisión entre A, B y B+ para la firma.

---

## Relectura d6b5b5ea (2026-10-16)

- **Objeto:** `git diff 367128f0 d6b5b5ea` (6 archivos, +294 / −57). Solo lectura: sin compilar ni ejecutar pruebas.
- **Dictamen de la relectura (recomendación técnica, C2): Aprobado con observaciones.** S03, S04, S05, S06 y S08 quedan cerrados. S02 queda cerrado en el camino directo, pero la corrección de S03 y S04 abre una vía nueva por la que `--urgente` puede terminar **sin rotar** (S10, Media); conviene corregirla antes de unir. S07 no aplica mientras siga el diseño actual. S01 sigue pendiente de la firma.

### Estado de cada hallazgo

| ID | Estado | Evidencia en d6b5b5ea | Comentario |
|---|---|---|---|
| S02 | **Cerrado** (con S10 aparte) | `CredencialApp.cs`: `RetirarAsync` → `CerrarSesionesAsync` con plazo cero en `--urgente`; bucle hasta que no quede ninguna sesión; `throw` si `sinPermiso > 0`; permisos exigidos antes de rotar | `--urgente` ya no termina con código 0 si no puede ver o cerrar las sesiones. |
| S03 | **Cerrado** | `ExigirPermisosRetiroAsync` antes de `CrearUsuarioAsync`, con `VIEW SERVER STATE` (o `PERFORMANCE STATE`) y `ALTER ANY CONNECTION`; `RetiroPendienteAsync` completa el retiro sin rotar | Detalle menor: si se pasó `--login-respaldo`, el bloque de `gpos_respaldo_srv` corre **antes** de la comprobación, así que «No se cambió nada» no es exacto en ese caso. Ese bloque es idempotente y ajeno a la rotación: Baja, opcional mover la comprobación arriba. |
| S04 | **Cerrado** | `SinNegar(...)` cuando se agotan los 1205 en el DENY; `ReintentarInterbloqueoAsync` en `SinConnectAsync`, `SesionesAsync` y `CerrarSesionesAsync` | Repetir el KILL es idempotente (6106 se ignora). Ver S09 sobre la reutilización del número de sesión. |
| S05 | **Cerrado con límites aceptables** | `VerificacionPrivilegios.cs`: `GPOS_APP_SESION_VENCIDA` (hallazgo) por `login_time` > 6 min; `VERIFICADOR_SIN_SESIONES` (aviso) | Ver la valoración de los límites más abajo. |
| S06 | **Cerrado** | `TopeKill` = 2 min, comprobado antes de cada vuelta del KILL, con error explícito; con `--todas`, `Program.cs` atrapa el error por empresa y sigue con las demás | No tiene prueba automática; ver los límites. |
| S07 | No aplica | — | Solo cobra sentido si se firma B o B+. |
| S08 | **Cerrado** | `OpcionesComando.cs` (lista blanca por comando, `--login` global), llamado desde `Argumentos.Leer`; pruebas en `Rg14Lote2Tests.cs:429-443` | Los comandos fuera de la lista siguen con «Comando desconocido». Comprobé, sin ser exhaustivo, que las opciones que lee `Program.cs` (`credencial-app`, `aprovisionar`, `crear`, `sistema`, `login-servicio`) están en la lista. Los comandos de lectura no los recorrí: si falta alguna opción, el riesgo es funcional, no de seguridad. |

### Valoración de los límites que declara el desarrollador

1. **S05: falso hallazgo si `verificar --estricto` corre durante el plazo y hay una sesión de más de 6 min. Aceptable.** El error va hacia el lado seguro: avisa de más, no de menos. La ventana dura como mucho el plazo (2 a 6 min), y esas sesiones ya no ejecutan sentencias (916). Sugerencia sin bloqueo: que el texto de `GPOS_APP_SESION_VENCIDA` diga «si `credencial-app` está en curso, espere a que termine antes de repetirlo». Si dos `credencial-app` corren a la vez, el segundo encuentra el retiro pendiente y hace KILL antes; no es peligroso, solo se adelanta el corte.
2. **`VERIFICADOR_SIN_SESIONES` sale también en GPOS_SYSDATA. Aceptable.** Es solo un aviso: hace ruido pero no afecta a `--estricto`. Observación aparte (S12, Baja): como es un aviso, un `verificar --estricto` ejecutado sin `VIEW SERVER STATE` aprueba sin haber podido ver las sesiones vencidas. Sugerencia: en `--estricto`, tratarlo como hallazgo solo en las bases de empresa, lo que de paso elimina el ruido en GPOS_SYSDATA, o documentar que el paso M8 de publicación se ejecuta con la identidad del técnico.
3. **S06 sin prueba automática del tope. Aceptable.** La lógica es mínima (un `Stopwatch` y una comparación) y reproducir en una prueba una transacción que tarde más de 2 min en deshacerse es caro. Sugerencia sin bloqueo: un tope configurable solo en Debug, como `PlazoPruebas`, y una prueba que lo fuerce con una sesión retenida.

### Hallazgos nuevos

#### DL22-S10 · Media · `--urgente` con un retiro pendiente termina sin rotar la credencial vigente

- **Riesgo:** ante una sospecha de compromiso, el operador ejecuta `credencial-app --urgente`. Si quedó un retiro pendiente de una rotación anterior (la otra generación con CONNECT o con sesiones), `AplicarAsync` completa ese retiro y **devuelve sin rotar**: la generación vigente, que es la sospechosa, sigue válida. La salida dice «Para rotar, repita credencial-app» y el código es 0. Las correcciones de S03 a S05 hacen que ese estado intermedio sea ahora explícito y algo más frecuente.
- **Evidencia:** `src/GPOS.Migracion/CredencialApp.cs`, bloque nuevo después de `var usuario = …` (`if (rotar && await RetiroPendienteAsync(...)) { … return new ResultadoCredencialApp(empresa, Prefijo + vigente, false, acciones); }`), sin distinguir `rotacion.Urgente`.
- **Remediación (unos 0,03 dp, inferido):** con `--urgente`, completar el retiro pendiente (KILL de las sesiones de esa generación) y **seguir con la rotación** en la misma ejecución. `CrearUsuarioAsync` ya cambia la contraseña y vuelve a dar CONNECT a esa generación, después se guarda la cadena y se aplica DENY más KILL a la vigente. Si se prefiere no hacerlo en una sola ejecución, como mínimo que `--urgente` falle con código distinto de 0 y un mensaje que diga que la vigente **no** se rotó.

#### DL22-S11 · Baja · La rotación normal con retiro pendiente sale con código 0 sin rotar

- **Riesgo:** un `credencial-app` programado (rotación periódica) que encuentra un retiro pendiente informa éxito sin haber rotado. Si se repite, la siguiente ejecución sí rota, pero la herramienta que lo lanza no lo distingue.
- **Remediación:** devolver un código de salida propio (por ejemplo, «completado sin rotar») o seguir con la rotación también en el modo normal, como en S10.

#### DL22-S09 · Baja · Riesgo de que el KILL alcance a otra sesión por la reutilización del número (anterior a d6b5b5ea, no lo vi en la primera revisión)

- **Riesgo:** entre leer `session_id` en `sys.dm_exec_sessions` y ejecutar `KILL n`, la sesión puede terminar y SQL Server puede dar el mismo número a otra conexión: otra empresa de la misma instancia, la generación nueva u otra aplicación. El bucle cada 500 ms y los reintentos 1205 amplían un poco esa ventana. El impacto es de disponibilidad, porque se cortaría una petición o transacción ajena, y puede cruzar tenants en una instancia compartida. La probabilidad es baja.
- **Evidencia:** `src/GPOS.Migracion/Lectura/CredencialesLectura.cs:316-331` (`KILL` con el número leído antes, sin volver a comprobarlo).
- **Remediación (unos 0,02 dp):** armar por cada número un lote que vuelva a comprobar justo antes: `IF EXISTS (SELECT 1 FROM sys.dm_exec_sessions WHERE session_id = <n> AND login_name = @u AND authenticating_database_id = DB_ID()) KILL <n>`. El número sigue siendo un `smallint` formateado con la cultura invariante, y `@u` pasa como parámetro. La ventana se reduce a microsegundos. Si además se compara `login_time`, la carrera queda prácticamente cerrada.

#### DL22-S12 · Baja · `VERIFICADOR_SIN_SESIONES` es solo un aviso en `--estricto`

Descrito en el punto 2 de los límites.

### Controles nuevos que están bien

- `@vidaSesion` va como parámetro `int`, sin SQL dinámico. La variante con otra antigüedad solo existe en `#if DEBUG` (`VerificacionPrivilegios.cs`, sobrecarga de `VerificarBaseAsync`).
- `RetiroPendienteAsync` usa `@u` como parámetro y el mismo filtro de alcance que el KILL (`authenticating_database_id = DB_ID()`, `<> @@SPID`).
- Los mensajes siguen sin incluir la contraseña ni la cadena.
- El parser sigue rechazando `--clave` y `--password` antes de aplicar la lista blanca.

### Cierre de la relectura
- Estado: Aprobado con observaciones (S10 Media, recomendada antes de unir; S09, S11 y S12 Bajas). S01 sigue Pendiente de firma.
- Entregas: desarrollador de identidades → S10 (y S09 y S11 en el mismo lote si es barato); arquitecto-maestro → S01 sin cambios.

---

## Revisión de d3a65288 (DL-22 b+, 2026-10-16)

- **Objeto:** `git diff cd480ddd d3a65288` en `GPOS-NG-dl22b`, rama `a/dl22-bmas` (7 archivos, +458 / −60). Revisado contra la precisión del punto 1 firmada «(b+)» (`precision-dl22-punto1-2026-10-16.md`, secciones 3 y 5). Solo lectura: no compilé ni ejecuté pruebas; lo medido (ventanas de 3 s y 15 s, PA-30 sin 500) es lo que declaran las pruebas, sin reproducir.
- **Dictamen técnico (recomendación, C2): Aprobado con observaciones.** La construcción sigue el orden firmado: comprobación cada 1 s en la API, contraseña aleatoria a los 3 s, `DENY` a los 15 s, `KILL` al plazo contado desde el `DENY`, `--urgente` sin espera y tiempos fijos. No hay hallazgos Críticos, Altos ni Medios. Hay seis Bajas (S13 a S18). Conviene corregir **S13 y S14 antes del PR** (unos 0,04 dp en total), porque tocan justo el caso que motivó (b+): una interrupción que deja la credencial anterior con su contraseña conocida.

### Estado de los hallazgos anteriores

| ID | Estado | Comprobación en d3a65288 |
|---|---|---|
| S01 | **Cerrado en el código; falta la medición** | La marca `Transicion=Defecto` desaparece de PA-30, que ahora mide además las dos ventanas (`tests/GPOS.Tests/ModeloNg/Rg14Lote2Tests.cs`, `PA30_dos_rotaciones_normales_bajo_carga_sin_ningun_500`). Queda cerrado cuando la suite oficial lo pase en la PC A. |
| S02, S03, S04, S05, S06, S08 | Siguen cerrados | Sin cambios en esas rutas, salvo el parámetro `guardadoEn` de `RetirarAsync`. |
| S07 | No aplica | Solo aplicaba a (b). |
| S09 | Sigue cerrado | `CerrarSesionesVerificadasAsync` (`src/GPOS.Migracion/CredencialApp.cs:375`). |
| S10, S11 | Siguen cerrados | El retiro pendiente se completa y la rotación sigue en la misma ejecución, en los dos modos (`CredencialApp.cs:187-191`). |
| S12 | Sigue cerrado | `VERIFICADOR_SIN_SESIONES` es hallazgo en las bases de empresa (`VerificacionPrivilegios.cs:42`, `:185`). |

### Respuesta a los puntos que pidió mirar el desarrollador

1. **`GPOS_APP_CONNECT_EN_ROTACION` (`VerificacionPrivilegios.cs:145-153`).**
   - Para silenciar el aviso de forma periódica hay que alterar `gpos_app_a` o `gpos_app_b` (`ALTER USER`, es decir, `ALTER ANY USER` o ser `db_owner`). Quien tiene ese permiso ya puede dar `CONNECT` y cambiar contraseñas a su gusto: **no es una escalada**, y S4 no es un control contra un administrador malicioso.
   - El punto débil es otro (S13): la condición usa el `MAX(modify_date)` de **las dos** generaciones. La generación nueva acaba de cambiar (`CrearUsuarioAsync` le pone contraseña), así que una interrupción **antes de los 3 s**, con la anterior todavía con su contraseña conocida y con `CONNECT`, sale como aviso durante 6 min. Cualquier `ALTER USER` sobre la vigente, por descuido, renueva esos 6 min.
   - **`--estricto`:** que siga siendo aviso dentro de los 6 min, como dice el texto firmado, pero medido con el `modify_date` de la propia anterior (ver S13).
2. **El `catch (Exception)` de la relectura (`src/GPOS.Core/Sistema/EmpresasService.cs:84`, `:96`).**
   - **No alarga la validez de la credencial anterior.** El retiro (contraseña a los 3 s, `DENY` a los 15 s) lo hace el servidor y no depende de la caché de la API. Una API que se quede con la cadena vieja solo recibe el 18456; después `Olvidar` y la relectura en frío (`EmpresasService.cs:111-114`) la sacan del grupo. Forzar a la API a quedarse con una cadena retirada solo produce indisponibilidad: no hay acceso de más.
   - Lo que sí oculta: la caída de GPOS_SYSDATA y, sobre todo, una cifrada que no se descifra (otro anillo de claves en otro proceso o nodo). Ese error es de configuración y se convertirá en 500 a los 3 s. No queda registrado (S16).
   - Lo que está bien: `Comprobada` se actualiza también al fallar, así que hay como máximo un intento por segundo, por empresa y por proceso, sin tormenta. La cancelación no se traga.
3. **Relectura dentro de la petición.**
   - **Concurrencia:** correcta. `CompareExchange` sobre `Releyendo` (`EmpresasService.cs:49`) permite una sola relectura por entrada. `Valor` es `volatile` y se sustituye entero. La carrera con `Olvidar` (actualiza una entrada ya retirada) es inofensiva.
   - **Aislamiento entre tenants:** correcto. La clave es (cadena de GPOS_SYSDATA, código en mayúsculas). La relectura abre la misma cadena del sistema (`:78`) y filtra por `Codigo = @c`, parametrizado con `NVarChar(30)`, que coincide con `HasMaxLength(30)` (`src/GPOS.Core/Data/Sistema/SistemaDbContext.cs:29`). Un código más largo nunca llega a tener entrada, porque la lectura en frío no lo encuentra.
   - **Negación de servicio:** es menor y no la puede provocar un cliente (S17). No conviene sacar la relectura de la petición: que la primera petición tras más de 1 s vea la cadena nueva **antes** de usarla es lo que garantiza el orden frente al cambio de contraseña a los 3 s.
4. **Cambio de contraseña de la anterior (`CredencialApp.cs:305-332`).**
   - **Escape:** correcto. `ClavesSql.Generar` produce Base64url de 32 bytes (43 caracteres, alfabeto `A-Z a-z 0-9 - _`), por debajo del límite de 128 de `QUOTENAME` y sin comillas. Como defensa en profundidad, falta una guarda ante un `@sql` nulo (S15).
   - **Secretos:** la contraseña no se guarda, no se muestra y no va en el mensaje (solo `ex.Number`). Inferido, sin verificar: SQL Server enmascara en las trazas los lotes que contienen `PASSWORD`, igual que en `CrearUsuarioAsync`.
   - **1205:** cada reintento genera otra contraseña. El paso es idempotente.
   - **Interrupción:** antes de los 3 s, la anterior queda con su contraseña y `CONNECT`, y `RetiroPendienteAsync` la detecta por el `CONNECT`. Es el riesgo aceptado en la firma. Entre los 3 s y los 15 s, la contraseña ya es desconocida y el pendiente se completa igual. Sugerencia sin ID, más allá de lo firmado: ante la cancelación durante las esperas, aplicar contraseña y `DENY` con `CancellationToken.None` antes de salir. Cerraría la ventana de los 3 s a cambio de algún 500, unos 0,02 dp.
   - **Hueco (S14):** en la rotación normal, si el cambio de contraseña falla, ya no se intenta el `DENY`.
5. **`--urgente` y el retiro pendiente:** correcto. El orden es `DENY`, comprobación de `SinConnect`, contraseña y `KILL` sin espera (`CredencialApp.cs:276-290`). Cada paso que falla lanza un error: `SinNegar`, la excepción de `DescartarClaveAsync`, falta de permiso para el `KILL` o el tope. El retiro pendiente con `--urgente` usa el mismo camino y después rota.
6. **Tiempos fijos:** correcto. Son `const int` en `CadenaConexion.cs:39-52` (1, 3 y 15 s). `RotacionApp` no expone nada para cambiarlos. `--plazo` está limitado a 2-6. `TopeKill` es `static readonly`. `PlazoPruebas` solo existe en Debug y afecta solo al plazo del `KILL`. La prueba `DL22_bmas_los_tiempos_de_la_rotacion_son_los_firmados` fija los valores.

### Hallazgos nuevos

| ID | Severidad | Título | Evidencia | Remediación | Costo [I] |
|---|---|---|---|---|---|
| DL22-S13 | Baja | S4 mide la rotación con el `modify_date` de cualquiera de las dos generaciones: una interrupción antes de los 3 s queda como aviso 6 min | `src/GPOS.Migracion/VerificacionPrivilegios.cs:145-153` (`MAX(q.modify_date)` sobre `gpos_app_a` y `gpos_app_b`) | Usar el `modify_date` de la propia fila (`p.modify_date`): la anterior solo es «reciente» si se le cambió la contraseña (a los 3 s) en los últimos 6 min. En los primeros 3 s de una rotación sana sale un hallazgo, un falso positivo hacia el lado seguro, como ya se aceptó en S05. Variante más estricta, que B debe aprobar porque va más allá de la letra firmada: hallazgo siempre que la anterior conserve `CONNECT` y su `modify_date` sea anterior al de la vigente (su contraseña no se cambió después de la rotación). | 0,02 dp |
| DL22-S14 | Baja | En la rotación normal, si falla el cambio de contraseña no se intenta el `DENY` | `CredencialApp.cs:272` (`DescartarClaveAsync` lanza antes de `NegarConnectAsync`, `:276-286`) | Si `DescartarClaveAsync` falla, intentar igual el `DENY` (sin esperar a los 15 s) y lanzar después un error que diga qué se logró. La anterior queda al menos sin `CONNECT`. | 0,02 dp |
| DL22-S15 | Baja | `EXEC (@sql)` con `@sql` nulo no hace nada y se informa «contraseña sustituida» | `CredencialApp.cs:313-320` | Hoy no se alcanza (43 caracteres). Agregar `IF @sql IS NULL THROW 51610, …` antes del `EXEC`, aquí y en `CredencialesLectura.CrearUsuarioAsync` (`src/GPOS.Migracion/Lectura/CredencialesLectura.cs:214-220`). | 0,01 dp |
| DL22-S16 | Baja | La relectura que falla (GPOS_SYSDATA o descifrado) no deja rastro | `EmpresasService.cs:84-88`, `:96` | Registrar una advertencia limitada (una por minuto, por empresa y por proceso) con el código de empresa, el tipo de excepción y `SqlException.Number`, **nunca** la cadena ni la cifrada. El fallo de descifrado, como error: indica otro anillo de claves y acabará en 500 a los 3 s de la próxima rotación. | 0,03 dp |
| DL22-S17 | Baja | Con GPOS_SYSDATA lenta, la petición que relee espera el `Connect Timeout` de la cadena del sistema más 5 s | `EmpresasService.cs:78-80` | Mantener la relectura dentro de la petición (garantiza el orden), pero con `Connect Timeout` de 2-3 s y `CommandTimeout` de 2 s solo para esa conexión. Afecta a una petición por empresa y proceso en cada ciclo, y un cliente no la puede provocar. | 0,01 dp |
| DL22-S18 | Baja (sospecha) | La relectura no mira `Inhabilitado`: otro proceso sigue sirviendo la cadena de una empresa inhabilitada | `EmpresasService.cs:80` frente a la lectura en frío, que filtra `!x.Inhabilitado`; `GuardarAsync` solo limpia la caché del proceso que guarda | Viene de antes de (b+) (la caché era permanente); ahora cerrarlo cuesta casi nada: leer también `Inhabilitado` y, si vale 1, `Olvidar`. No verifiqué si el inicio de sesión u otra puerta ya rechaza la empresa inhabilitada; si lo hace, queda como mejora. | 0,02 dp |

### Controles nuevos que están bien

- La relectura usa su propia conexión, una consulta parametrizada y la misma GPOS_SYSDATA de la clave. Si la cifrada no cambió, no descifra nada.
- `LimpiarGrupos(anterior)` solo se llama si la cadena cambió de verdad.
- La contraseña de descarte se genera en cada intento y no sale del proceso. Los mensajes de error no la incluyen.
- `Stopwatch` monótono para las esperas y `TickCount64` para la vigencia: no dependen del reloj de pared.
- Las pruebas cubren la relectura en 1 s, GPOS_SYSDATA caída, los tiempos firmados y las ventanas de PA-30. El hallazgo pasado el tiempo solo se prueba en Debug.

### Cierre de la revisión de d3a65288
- Estado: Aprobado con observaciones. Sin hallazgos Críticos, Altos ni Medios; S13 a S18 Bajas. Se recomienda corregir S13 y S14 antes del PR; S15 a S17 en el mismo lote si es barato (unos 0,05 dp); S18 tras confirmar si hay otra puerta.
- Supuestos: las ventanas de 3 s y 15 s y la ausencia de 500 son mediciones de las pruebas, no reproducidas; el enmascaramiento de `PASSWORD` en las trazas es inferido; que `DENY` no mueve `modify_date` lo afirma el código y no lo verifiqué.
- Entregas: desarrollador de identidades → S13 y S14 antes del PR, S15 a S17 en el mismo lote; QA → correr PA-30 en la suite oficial para cerrar S01; arquitecto-maestro (B) → decidir si se adopta la variante estricta de S13, que va más allá del texto firmado.
