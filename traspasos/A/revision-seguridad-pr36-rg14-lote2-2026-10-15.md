# Informe de Seguridad: PR #36, RG-14 lote 2 (S0, S1 y `GPOS.Migracion sistema` en Estricto)

**Fecha:** 2026-10-15 · **Auditor:** auditor-seguridad (Opus 5.5) · **Tipo:** revisión de código, solo lectura

**Qué revisé:** el PR #36, rama `a/rg14-lote2` @ `ac4b9489`, contra la base `a/rg14-lote1` @ `e218aa78` (worktree `GPOS-NG-rg14l2`). Son 27 archivos; 10 786 líneas son el `Designer` de EF y no las revisé.

**Contrato:** `datos-t3-12-rg14-2026-10-14.md` (D-01 a D-11, en especial D-04 (i) y (iii), D-05 y D-08) y mi informe del PR #28 (SEG-RG14-05 y SEG-RG14-08).

**Método:** no compilé ni ejecuté pruebas. Las cifras que menciono son las que declara el PR: 7 pruebas nuevas, 230 del filtro de RG-14 y una suite de 2 547 correctas con 1 fallida, una falla de entorno que el PR atribuye a «Database … is in transition». No las reproduje.

---

## 1. Alcance y superficie revisada

| Superficie | Archivos |
|---|---|
| Paso de servidor S0 | `database/rg14/rg14-00-servidor.sql` |
| S1, procedimientos y marca | `src/GPOS.Core/Infraestructura/Motor/PrivilegioMinimoSistema.cs`, `RespaldoCopia.cs` |
| `sistema`, `credencial-app` y `aprovisionar` | `src/GPOS.Migracion/ComandoSistema.cs`, `CredencialApp.cs`, `ComandoAprovisionar.cs`, `Lectura/CredencialesLectura.cs`, `EmpresasSistema.cs` |
| D-05 en la base de empresa | `SqlMigracionesRg14Lote2.cs`; `database/empresa/gpos-empresa-20261015003000_Rg14RespaldoTope.sql` |
| Arranque en Estricto y relectura ante el 18456 | `src/GPOS.Api/Servicios/Inicializacion.cs`, `Program.cs`, `Seguridad/IdentidadSql.cs`; `EmpresasService.Olvidar` |
| SEG-RG14-08 | `VerificacionPrivilegios.cs` |

---

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título |
|---|---|---|
| RG2-01 | Baja | El tope de 12 respaldos por hora limita el ritmo pero no el volumen: 288 respaldos completos al día por base. Además hay una carrera entre contar y respaldar |
| RG2-02 | Baja | Si la revocación de la generación anterior no se aplica, el comando no lo informa como error |
| RG2-03 | Baja | `aprovisionar` comprueba `sysadmin` en la instancia de la empresa, pero no en la de `GPOS_SYSDATA` |
| RG2-04 | Informativa | `CREATE ANY DATABASE` para Backup Tool; activar `contained database authentication` en toda la instancia |
| RG2-05 | Informativa | El `GRANT_BASE_LECTURA` de S4 no detecta concesiones a roles anidados |

No hay hallazgos Críticos, Altos ni Medios.

---

## 3. Checklist OWASP Top 10

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | **Bien:** roles con privilegio mínimo, `DENY` explícitos, `guest` sin `CONNECT`, dueño `sa` y `gpos_sistema` fuera de todo rol fijo |
| A02 Criptografía / secretos | **Bien:** contraseña aleatoria de 32 bytes que solo vive en memoria, viaja como parámetro y se guarda cifrada con el anillo |
| A03 Inyección | **Bien:** nombres de inicio de sesión con `QUOTENAME`, contraseña con `QUOTENAME(…, '''')` y etiqueta del respaldo con lista blanca `[A-Z0-9_]`. En S0, las variables de `sqlcmd` dependen de quien ejecuta, que es `sysadmin` (lo documenta el guion) |
| A04 Diseño inseguro | **Observación** RG2-01 |
| A05 Configuración | **Bien:** Estricto es el valor por omisión y la API no arranca sin la marca. Ver RG2-04 |
| A06 Componentes | **No aplica** |
| A07 Autenticación | **Bien:** credenciales contenidas, rotación a/b y revocación con `DENY CONNECT`. Ver RG2-02 |
| A08 Integridad | **Bien:** la marca de esquema solo sube; S4 verifica TRUSTWORTHY y el dueño |
| A09 Registro y monitoreo | **Bien:** una sola línea de salida sin secretos; el detalle va al Visor de eventos |
| A10 SSRF | **No aplica** |

---

## 4. Verificación del foco pedido

| Punto | Resultado | Evidencia |
|---|---|---|
| Secretos de `credencial-app` y `aprovisionar` | **Verificado.** La clave sale de `RandomNumberGenerator` (32 bytes, en base64url). Viaja a SQL Server solo como parámetro `@c` (`CREATE USER … WITH PASSWORD = QUOTENAME(@c, '''')`). Se guarda solo cifrada (`Protector().Protect` en `dbo.Empresas`). Ni las acciones ni la línea de salida la incluyen. Queda en memoria como `string`, como reconoce el código [I] | `CredencialApp.cs:94-100`; `CredencialesLectura.cs:213-227`; `EmpresasSistema.cs:60-69` |
| Salida de una línea | **Verificado:** `APROVISIONADA`, `AL_DIA` o `ERROR <código>`. El detalle va al Visor de eventos con el número y el texto de la excepción de SQL, sin la cadena ni secretos (el texto de SQL Server puede traer nombres de bases o de inicios de sesión, que no son secretos) | `ComandoAprovisionar.cs:233-262` |
| `sysadmin` antes de tocar nada | **Verificado en la instancia de la empresa**, antes de crear, actualizar, cambiar el dueño o tocar credenciales. Ver RG2-03 | `ComandoAprovisionar.cs:184-191` |
| Revocación de la generación anterior | **Verificado:** después de guardar la cadena nueva y de comprobar que entra, `DENY CONNECT` y cierre de sesiones. Una generación reutilizada (a → b → a) recupera el `CONNECT` con `GRANT CONNECT`. Ver RG2-02 | `CredencialApp.cs:93-103`; `CredencialesLectura.cs:223-224, 274+` |
| Idempotencia | **Verificada:** sin `rotar`, una credencial contenida vigente que entra no se toca (PA-39). Dueño, roles y usuarios con `IF NOT EXISTS`/`IS_ROLEMEMBER` | `CredencialApp.cs:87-91`; `PrivilegioMinimoSistema.S1` |
| `PrivilegioMinimoSistema.S1` | **Verificado:** dueño `sa` por SID (solo con `sysadmin`; si no, aviso 51604, que S4 recoge); `guest` sin `CONNECT`; `gpos_api` con DML sobre `dbo` y `DENY` sobre la bitácora de dispositivos, `BitacoraSeguridad`, las marcas P-7, los latidos y el borrado de la cola de respaldos; `EXECUTE` sobre los procedimientos. `gpos_sistema` se niega si el inicio de sesión de la API es dueño o tiene otro usuario (51606), y se saca de todo rol fijo. `gpos_respaldo` en `db_backupoperator`. Los `DENY` de base (sin `CREATE`/`ALTER ANY`/`BACKUP`) los dejó el lote 1. Los `DENY` de la licencia (L1a-4) entran por `ExtensionesEsquemaSistema.Permisos` después de S1 | `PrivilegioMinimoSistema.cs:42-55, 100-174`; `ComandoSistema.cs:56-66` |
| `usp_RespaldoCopia` | **Verificado:** `EXECUTE AS OWNER` (dueño `sa`, dentro de la base); etiqueta en lista blanca; ruta y nombre fijados por el servidor; `BACKUP … COPY_ONLY, INIT, CHECKSUM`; tope de 12 por hora contado en `msdb.dbo.backupset` a través de `guest` (necesita TRUSTWORTHY desactivado, que S4 vigila). Con dueño `sa`, un TRUSTWORTHY activado sería una vía de escalada a `sysadmin`; S4 lo marca (`TRUSTWORTHY`). Ver RG2-01 | `RespaldoCopia.cs:214-245`; `VerificacionPrivilegios.cs:143-149` |
| `usp_VaciarCargaRnc` | **Correcto:** `EXECUTE AS OWNER` con un `TRUNCATE` sobre una tabla fija, sin parámetros, así que `gpos_api` no necesita `ALTER` | `PrivilegioMinimoSistema.cs:62-72` |
| D-05 | **Verificado:** la migración nueva `20261015003000_Rg14RespaldoTope` (posterior a `Rg14PrivilegioMinimo`) recrea el procedimiento con el tope, concede `EXECUTE` y **vuelve a aplicar `DENY BACKUP DATABASE TO gpos_app`**. El reverso conserva el `DENY`. En `GPOS_SYSDATA`, `gpos_api` tiene `DENY BACKUP DATABASE` desde el lote 1. Ningún camino de la API hace un `BACKUP` directo | `SqlMigracionesRg14Lote2.cs`; guion `…Rg14RespaldoTope.sql` |
| Arranque en Estricto sin marca | **Verificado:** Estricto es el valor por omisión (solo `Amplio` escrito así abre el modo amplio). En Estricto la API no crea ni actualiza `GPOS_SYSDATA`; sin la marca, o con una marca menor, o con un 4060/18456 al abrir, no arranca, con un mensaje sin la cadena y una excepción nueva **sin la interna** | `IdentidadSql.EsAmplioSegun`; `Inicializacion.cs` (`ExigirMarcaSistemaAsync`) |
| La API olvida la cadena ante un 18456 | **Verificado:** el manejador de errores busca un 18456 en la cadena de excepciones y llama a `EmpresasService.Olvidar(empresa del token)`; la petición siguiente vuelve a descifrar. El costo de que alguien lo provoque es despreciable (un descifrado por petición fallida) | `Program.cs`; `EmpresasService.cs` |
| S0 | **Verificado:** exige `sysadmin` (51600), modo mixto (51601) y `sa` deshabilitada (51602); activa `contained database authentication`; crea inicios de sesión de Windows (sin inicios de sesión SQL ni secretos); rechaza identidades de aplicación con roles o permisos de servidor que no sean `CONNECT SQL` (y `CREATE ANY DATABASE` para respaldo) (51603). Ver RG2-04 | `rg14-00-servidor.sql` |
| SEG-RG14-08 | **Cerrado:** S4 marca `GRANT_BASE_LECTURA` (`VIEW DEFINITION` o `SHOWPLAN` de clase 0 a `public`, `gpos_reportes`, `gpos_lectura` o `gpos_rpt_sis`). Ver RG2-05 | `VerificacionPrivilegios.cs` |
| SEG-RG14-05 | **Cerrado** en cuanto al ritmo (12 por hora y por base). Queda el volumen (RG2-01) | `RespaldoCopia.cs` |

---

## 5. Hallazgos

### RG2-01 · Baja · El tope limita el ritmo, no el volumen

Con la credencial de la aplicación comprometida, 12 respaldos completos por hora y por base suman 288 al día. Cada archivo lleva un nombre distinto, así que nada se sobrescribe. Para una base de 5 GB son unos 60 GB por hora: el disco de `InstanceDefaultBackupPath` se sigue llenando en horas y la instancia (todas las empresas) se detiene. Además, contar y respaldar no es atómico: llamadas concurrentes pueden pasar el tope a la vez.
- **Evidencia:** `RespaldoCopia.cs:233-243`.
- **Remediación (≈ 0,1 dp):**
  1. Acotar el volumen con **ranuras rotativas**: el nombre lleva `_<n>` con `n` = (respaldos de la base) módulo K (por ejemplo, K = 4) e `INIT` sobrescribe. El espacio máximo queda en K × tamaño de la base.
  2. O un tope diario además del horario (por ejemplo, 12 al día).
  3. Serializar el procedimiento con `sp_getapplock` por base, que cierra la carrera.

### RG2-02 · Baja · La revocación que no se aplica no se informa como error

Si `RevocarAsync` devuelve null (por ejemplo, porque el usuario anterior ya no existía o el `DENY` no se pudo aplicar), `credencial-app` y `aprovisionar` terminan con éxito sin decirlo. La generación anterior podría seguir entrando.
- **Remediación (≈ 0,02 dp):** después de revocar, comprobar que el usuario anterior tiene `DENY CONNECT` (o que ya no existe) y, si no, devolver un `ERROR`. Que S4 marque cualquier `gpos_app_*` con `CONNECT` que no sea el de la cadena vigente.

### RG2-03 · Baja · `sysadmin` solo en la instancia de la empresa

La comprobación de PA-40 se hace en `master` de la instancia de la empresa. Si `GPOS_SYSDATA` está en otra instancia, un fallo al guardar la cadena deja el trabajo a medias en la empresa: la base creada o actualizada y un `gpos_app_x` creado cuya contraseña nadie conoce. Es inofensivo (contraseña aleatoria, sin uso), pero contradice «nada a medias».
- **Remediación (≈ 0,02 dp):** comprobar también los permisos en la instancia del sistema antes de empezar (o `UPDATE` sobre `dbo.Empresas` con la identidad administrativa), y que S4 marque los `gpos_app_*` que no son los de la cadena.

### RG2-04 · Informativa

- **`GRANT CREATE ANY DATABASE` a Backup Tool (D-08):** permite crear bases y restaurar copias (de las que esa cuenta queda como dueña), pero no sobrescribir bases ajenas. Que Backup Tool limpie las bases temporales y que S5 vigile las bases cuyo dueño sea esa cuenta.
- **`contained database authentication = 1` en toda la instancia (D-04):** los riesgos documentados de los usuarios contenidos son dos. Un usuario con `ALTER ANY USER` dentro de una base contenida puede dar acceso a la instancia (aquí está negado a las identidades de aplicación). Y no hay bloqueo por intentos fallidos, lo que no importa con contraseñas aleatorias de 32 bytes. Aceptable con los `DENY` actuales.

### RG2-05 · Informativa

`GRANT_BASE_LECTURA` mira las concesiones directas a `public` y a los roles de lectura, pero no una concesión a otro rol del que sean miembros. Es un caso raro (exige un error administrativo). Si se quiere cubrir, S4 puede recorrer las pertenencias de los roles de lectura.

---

## 6. Controles bien implementados

- **Secretos:** solo en memoria y como parámetros, guardados cifrados con el anillo, nunca en la salida ni en el registro.
- **Fallar cerrado:** Estricto por omisión, la API sin marca no arranca, `aprovisionar` sin `sysadmin` no empieza y `credencial-app` no cambia la cadena si la credencial nueva no entra.
- **Privilegio mínimo** completo en S1 (dueño `sa`, `guest`, roles, `DENY`, `gpos_sistema` sin roles fijos y 51606 contra el inicio de sesión dueño).
- **D-05** con el `DENY BACKUP` repetido en una migración nueva y conservado en el reverso.
- **Rotación a/b** con prueba de entrada antes de guardar y relectura en la API ante el 18456.
- **S4** con TRUSTWORTHY, dueño y `GRANT_BASE_LECTURA`.

---

## 7. Remediaciones priorizadas

| Orden | ID | Cuándo | Esfuerzo |
|---|---|---|---|
| 1 | RG2-01 | Lote 3 o seguimiento, antes de Estricto en producción | ≈ 0,1 dp |
| 2 | RG2-02, RG2-03 | Seguimiento | ≈ 0,05 dp |
| 3 | RG2-04, RG2-05 | Con S5 y la herramienta de respaldos | — |

---

## 8. Recomendación

**PR #36: Aprobado con observaciones.**

No hay hallazgos Críticos, Altos ni Medios. Quedan cerrados SEG-RG14-08 y SEG-RG14-05 (este último en cuanto al ritmo; queda el volumen, RG2-01). La base `a/rg14-lote1` (#28) tiene que unirse antes, como indica el PR. Es una recomendación técnica: la decisión es del propietario.

---

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\revision-seguridad-pr36-rg14-lote2-2026-10-15.md`
- Supuestos: los resultados de pruebas son los declarados por el PR, sin reproducir; el acceso a `msdb` vía `guest` desde `EXECUTE AS OWNER` lo comprobó el desarrollador, no yo; no revisé el `Designer` de EF (código generado).
- Decisiones candidatas a ADR: Ninguna (RG2-01 precisa SEG-RG14-05 dentro de D-05).
- Entregas a otros agentes:
  - desarrollador-backend (I): RG2-01 (ranuras rotativas o tope diario, y `sp_getapplock`), RG2-02 y RG2-03.
  - devops y la herramienta de respaldos: limpiar las bases temporales de las restauraciones de prueba (RG2-04).
  - qa-automatizado: el vector de concurrencia del tope (RG2-01).
- Próximo paso recomendado: unir el PR #28 y luego el #36, y llevar RG2-01 al lote 3 o a un seguimiento antes de Estricto en producción.

---

## 9. Lectura de diferencias (`ac4b9489..c4a1b259`)

**Commits:** `ecff6f08`, `e2ad4c72`, `38fc998b` y `c4a1b259`. Revisé solo en lectura, sin compilar. No reproduje las pruebas declaradas.

| Punto | Estado | Evidencia y comentario |
|---|---|---|
| **RG2-01** | **Cerrado** | El tope pasa a **4 por hora y 12 por día** por base (`MaximoPorHora`, `MaximoPorDia`). Contar y respaldar ocurre bajo `sp_getapplock` exclusivo **por base** (el recurso de aplicación es de la base en curso), con 60 s de espera; si vence, devuelve 51608. Eso cierra la carrera. El volumen queda acotado a 12 copias completas por base y por día. **Informativa:** sin retención, el disco sigue creciendo a lo largo de varios días; conviene una limpieza de las copias `GPOS - …` antiguas (la herramienta de respaldos o un trabajo del Agente). El historial toma ahora el usuario del nombre del respaldo, porque `user_name` es el dueño (`EXECUTE AS OWNER`); es solo un dato que se muestra en la interfaz (`RespaldoCopia.cs:43-91`) |
| **RG2-02** | **Cerrado** | Tras revocar, `SinConnectAsync` exige que el usuario anterior no exista o tenga `DENY CONNECT`; si no, `credencial-app`/`aprovisionar` terminan en error («puede seguir entrando»). Un permiso tiene un solo estado por principal, así que un `DENY` excluye un `GRANT` vigente. S4 marca `GPOS_APP_CONNECT` (`CredencialApp.cs`; `VerificacionPrivilegios.cs`) |
| **Reapertura PA-30** | **Correcta: no reintenta comandos ni transacciones y no oculta otros errores** | `ReaperturaConexionEmpresa` es un interceptor de **apertura** de conexión. Solo atrapa el `SqlException` 18456 de `Open`; relee la cadena guardada (`Olvidar` y `ObtenerAsync`) y abre **una sola vez** más. Si la relectura no da una cadena, vuelve a lanzar la excepción original, y si la segunda apertura falla, ese error sube tal cual. Cualquier otro número de error no se toca. Como actúa antes de que exista ningún comando, no hay nada que repetir. `UnidadTrabajo` copia el interceptor al contexto que comparte la conexión. `CandadoEmpresas` reintenta solo si la conexión no llegó a abrirse (`!abierta && 18456`). **Informativas:** (a) la ruta síncrona usa `.GetAwaiter().GetResult()`, que no tiene riesgo de bloqueo en ASP.NET Core (no hay contexto de sincronización) pero conviene evitarlo si se usa en otro anfitrión; (b) un 18456 legítimo (contraseña errónea sin rotación) cuesta un descifrado y un intento más, sin efecto de seguridad (`ReaperturaConexionEmpresa.cs`; `Sesion.cs`; `UnidadTrabajo.cs`; `CandadoEmpresas.cs`) |

### Riesgo declarado: bloqueo de sesión que queda tomado

**Diagnóstico.** `BACKUP` no se puede ejecutar dentro de una transacción de usuario, así que **no se puede usar un bloqueo de transacción** (`@LockOwner = 'Transaction'`). El bloqueo de sesión es la única opción dentro del procedimiento. El `CATCH` lo libera ante los errores normales. Lo que **no** pasa por el `CATCH`:
- la **cancelación del cliente**, que envía una atención: la petición HTTP se corta (el `ct` de la petición llega a `ExecuteSqlRawAsync`) o vence el `CommandTimeout` (30 min y 3 600 s). La atención aborta el lote sin ejecutar el `CATCH`;
- un error de severidad 20 o más, que cierra la sesión y con ella libera el bloqueo (ese caso no es problema).

**Consecuencia.** Con la agrupación de conexiones, la conexión vuelve al grupo con el bloqueo tomado. No verifiqué si `sp_reset_connection` libera los bloqueos de aplicación de sesión cuando se reutiliza la conexión [inferido]: hay que comprobarlo con una prueba. Mientras siga tomado, los respaldos siguientes de esa base esperan 60 s y fallan con 51608, hasta que la conexión se cierre (por expiración en el grupo o al reiniciar la API). El efecto es solo de **disponibilidad** y es **restrictivo** (impide respaldos, no permite más), así que la severidad es **Baja**.

**Recomendación**, en lugar de cambiar el tipo de bloqueo:
1. **Llamar al procedimiento con una conexión propia sin agrupación** (`Pooling = false`, o `SqlConnection.ClearPool` al terminar si hubo error o cancelación). Al cerrarla, la sesión termina y SQL Server libera el bloqueo. Cubre la cancelación y el tiempo de espera. Costo ≈ 0,05 dp en `RespaldoService` y `RespaldosPosteriores`.
2. **No propagar al `BACKUP` la cancelación de la petición:** un respaldo iniciado debe terminar aunque el usuario cierre el navegador. Usar un token propio del servidor, o `CancellationToken.None` con el `CommandTimeout` largo que ya tiene.
3. **Mantener el `@LockTimeout = 60000`** como salvaguarda, y como mucho añadir al mensaje de 51608 que puede haber un respaldo en curso (ya lo dice).
4. **Prueba:** cancelar una llamada a mitad del `BACKUP` y comprobar que la siguiente respalda sin esperar.

**Alternativas descartadas:**
- Un bloqueo de transacción: `BACKUP` lo prohíbe.
- Un candado con una fila de tabla y `UPDATE … WHERE libre`: tampoco sobrevive a la atención sin una limpieza por antigüedad, y añade estado.
- Bajar `@LockTimeout` a 0: no arregla el bloqueo que quedó tomado; solo hace que el fallo llegue antes.

### Dictamen final del PR #36

**Aprobado con observaciones.** RG2-01 y RG2-02 están cerrados. La reapertura PA-30 es correcta. Queda RG2-03 (Baja) y una observación Baja nueva: liberar el bloqueo de sesión ante una cancelación, con una conexión sin agrupación y sin propagar la cancelación. No hay hallazgos Críticos, Altos ni Medios. Es una recomendación técnica: la decisión es del propietario.

### Cierre (lectura de diferencias)
- Estado: Aprobado con observaciones
- Artefactos: este informe (sección 9 agregada)
- Supuestos: los resultados de pruebas son los declarados, sin reproducir. No verifiqué si `sp_reset_connection` libera los bloqueos de aplicación de sesión
- Decisiones candidatas a ADR: Ninguna
- Entregas a otros agentes:
  - desarrollador I: conexión sin agrupación y sin la cancelación de la petición para `usp_RespaldoCopia` (con su prueba), y RG2-03;
  - devops o la herramienta de respaldos: retención de las copias `GPOS - …`
- Próximo paso recomendado: unir el PR #28 y luego el #36; la conexión sin agrupación puede ir en el mismo PR o en un seguimiento
