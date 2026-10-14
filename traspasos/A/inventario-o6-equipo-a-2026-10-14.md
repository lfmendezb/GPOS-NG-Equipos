# Inventario O-6 · Equipo A (`DevLab00`, cuenta `DevLab00\lfmen`) frente a E-1 (SEG-L2-25) y E-2 a E-15

- **Fecha:** 2026-10-14
- **Autor:** agente devops (subagente, Opus)
- **Para:** DL-13 y anexo A de `hoja-firma-dl01-dl13-licencia-2026-10-14.md`; `blueprint-licencia-lote2-2026-10-14.md` §10.6 (E-1 con SEG-L2-25)
- **Modo:** **solo lectura.** No se cambió ningún permiso, grupo, servicio, inicio de sesión de SQL, política ni configuración. No se pidió elevación. Lo que exige administrador para leerse se marca como **no verificable sin elevación**.
- **Estado del informe:** **No listo.** El equipo A no cumple E-1 hoy. Es una recomendación técnica: la decisión la firma el propietario (C2).

**Supuesto principal (S-1):** no está confirmado que la PC A sea el «equipo principal del propietario» de F-2 / Q-19 (c). Según la memoria del proyecto, desde el 2026-10-09 el equipo que coordina es el equipo nuevo (B) y la PC A es de soporte, con apagones y sin UPS. Este inventario vale **solo para la PC A**. Si `s1` se va a generar en otro equipo, hay que repetir O-6 allí.

Leyenda: **[V]** verificado en este equipo con el comando indicado · **[I]** inferido · **[NV]** no verificable sin elevación.

---

## 1. Equipo

| Dato | Valor | Origen |
|---|---|---|
| Modelo | HP ProDesk 400 G3 DM, Intel Core i5-7500T (7.ª gen.), BIOS P23 02.49 (2023) | [V] `Win32_ComputerSystem`, `Win32_BIOS` |
| Sistema | Windows 11 Pro 26H2, compilación 26300.9711 (el registro dice «Windows 10 Pro», una rareza conocida). La CPU de 7.ª generación está fuera de la lista oficial de Windows 11 [I] | [V] registro `CurrentVersion` |
| Firmware y disco | UEFI, disco 0 GPT (500 GB) | [V] `Get-ComputerInfo`, `Get-Disk` |
| Actualizaciones | KB5127647, KB5127648 y KB5127694 instaladas el 14/10/2026 | [V] `Get-HotFix` |

## 2. Cuenta `lfmen`, grupos y token (punto 1)

| Comprobación | Resultado | Origen |
|---|---|---|
| Tipo de cuenta | Local vinculada a una **cuenta Microsoft** (grupo `MicrosoftAccount\…` en el token; dirección omitida) | [V] `whoami /groups`, `Get-LocalGroupMember` |
| Grupos locales | **`Administradores`** y `Usuarios` | [V] `net user lfmen` |
| Token actual | **Sin elevar.** `BUILTIN\Administradores` aparece como «Grupo usado solo para denegar». Nivel de integridad medio. Solo 5 privilegios básicos (`SeShutdown`, `SeChangeNotify`, `SeUndock`, `SeIncreaseWorkingSet`, `SeTimeZone`) | [V] `whoami /groups`, `whoami /priv`, `IsInRole(Administrator)` = False |
| Administradores de Hyper-V | Vacío | [V] `Get-LocalGroupMember` |
| Operadores de copia de seguridad | Vacío | [V] |
| Usuarios de escritorio remoto | Vacío | [V] |
| Usuarios de administración remota | Vacío | [V] |
| Usuarios avanzados, Operadores criptográficos, Operadores de configuración de red, Propietarios del dispositivo, Usuarios COM distribuidos, Lectores del registro de eventos, Usuarios de OpenSSH, Operadores de hardware en modo usuario, Usuarios del registro de rendimiento | Vacíos | [V] |
| Usuarios del monitor de sistema | Solo las cuentas de servicio de SQL Server (`NT SERVICE\MSSQL$SQLEXPRESS`, `MSSQLSERVER`, los dos agentes) | [V] |
| `docker-users` | El grupo no existe | [V] |
| Procesos elevados en este momento | **[NV]**: `Get-Process -IncludeUserName` exige elevación | — |

**Conclusión del punto 1:** el único grupo con efecto de administrador es **`Administradores`**, y eso basta para incumplir E-1. Hoy la protección real es solo la división del token de UAC, que en el nivel 5 no es un límite de seguridad (ver §5).

## 3. Otras cuentas locales (punto 6)

| Cuenta | Habilitada | Administradora | Observación |
|---|---|---|---|
| `Administrador` (integrada) | No | Sí | Deshabilitada [V] |
| `BigLocker` | **Sí** | No (solo `Usuarios`) | Nunca inició sesión según `net user`. **Propósito desconocido:** confirmarlo con el propietario [V/I] |
| `lfmen` | Sí | **Sí** | Cuenta diaria |
| `DefaultAccount`, `Invitado`, `WDAGUtilityAccount` | No | No | Cuentas del sistema |
| `gsf-firma` (E-2) | — | — | **No existe** [V] |

**No hay una cuenta administradora aparte habilitada.** La única otra administradora es la integrada, que está deshabilitada. Por eso, si hoy se quitara `lfmen` de `Administradores` sin crear antes otra cuenta, el equipo quedaría sin administrador utilizable.

## 4. Instancias SQL locales (punto 2)

Consultas de solo lectura con `sqlcmd -E -C` (`IS_SRVROLEMEMBER`, `sys.server_role_members`, `sys.server_principals`, `sys.configurations`, `sys.databases`).

| Instancia | Versión | `lfmen` es `sysadmin` | Otros miembros de `sysadmin` | Modo de autenticación | Dueño de las bases de usuario |
|---|---|---|---|---|---|
| `.\SQLEXPRESS` | SQL Server 2019 Express 15.0.2200.2 | **Sí** (inicio de sesión de Windows `DevLab00\lfmen`, directo) | `gsf` (SQL, habilitado); `sa` (SQL, **deshabilitado**); `NT Service\MSSQL$SQLEXPRESS`; `NT SERVICE\SQLWriter`; `NT SERVICE\Winmgmt` | Mixto | `DevLab00\lfmen` en las 5 bases (2 `GPOS_TEST_*`/`GPOS_QA_*`) |
| `.` (MSSQLSERVER) | SQL Server 2025 Enterprise Developer 17.0.1145.4 | **Sí** (directo) | `gsf` (SQL, habilitado); `sa` (deshabilitado); `NT Service\MSSQLSERVER`; `NT SERVICE\SQLSERVERAGENT`; `NT SERVICE\SQLWriter`; `NT SERVICE\Winmgmt` | Mixto | `DevLab00\lfmen` en las 9 bases (4 de prueba) |
| `(localdb)\MSSQLLocalDB` | LocalDB 17.0.4025.3 | **Sí** (por diseño: el dueño de una instancia LocalDB siempre es `sysadmin`) | `NT SERVICE\SQLWriter`; `sa` (deshabilitado) | Mixto | — |

Otros datos [V]:
- En `.\SQLEXPRESS` existe el inicio de sesión `BUILTIN\Usuarios`, sin roles de servidor (solo `public`), que creó el instalador de Express.
- `lfmen`, `gsf` y `BUILTIN\Usuarios` no tienen permisos de servidor explícitos aparte de `CONNECT SQL`.
- En las tres instancias: `xp_cmdshell` = 0, `clr enabled` = 0, `Ole Automation Procedures` = 0 y **`contained database authentication` = 0**.
- Servicios: `MSSQL$SQLEXPRESS` y `MSSQLSERVER` en ejecución y automáticos; SQL Browser en ejecución; los dos agentes de SQL Server detenidos.
- En el repositorio `GPOS-NG-rg14` no se encontró ningún uso de LocalDB en `src` ni en `tests`.

**Por qué importa (SEG-L2-25):** un `sysadmin` puede activar `xp_cmdshell` y ejecutar comandos como la cuenta del servicio, que tiene `SeImpersonatePrivilege`. Desde ahí se puede llegar a `SYSTEM` [I]. En LocalDB el proceso corre con la propia cuenta del usuario, así que ser `sysadmin` allí no da más que los derechos de `lfmen` [I]. El auditor debe decir si lo acepta como excepción o si hay que borrar la instancia (ver §7, paso S-7).

## 5. UAC (punto 4)

`HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System` [V]:

| Valor | Actual | E-1 exige | Cumple |
|---|---|---|---|
| `EnableLUA` | 1 | 1 | Sí |
| `ConsentPromptBehaviorAdmin` | **5** (predeterminado: avisa solo cuando una aplicación que no es de Windows pide cambios; los binarios de Windows se elevan solos) | **2** («notificar siempre») | **No** |
| `PromptOnSecureDesktop` | 1 | 1 | Sí |
| `ConsentPromptBehaviorUser` | 3 (pide credenciales en el escritorio seguro) | 3 para la cuenta estándar | Sí |
| `FilterAdministratorToken` | 1 | — | Sí (protege la cuenta integrada) |
| `EnableInstallerDetection` | 1 | — | Sí |
| `ValidateAdminCodeSignatures` | 0 | — | Neutro |
| Sudo para Windows | Sin configurar | Deshabilitado | Sí |

Con `lfmen` en `Administradores` y el valor 5, un programa con la integridad media de `lfmen` puede elevarse sin preguntar mediante las técnicas conocidas de autoelevación. Ese es precisamente el vector de SEG-L2-03.

## 6. TPM y plataforma (punto 5 y E-7, E-10, E-13)

| Dato | Resultado | Origen |
|---|---|---|
| TPM | **Presente, TPM 2.0, discreto** (no es fTPM): **Infineon SLB9670**, firmware 7.63.3353.0, especificación 1.16, PPP 1.3 | [V] `tpmtool getdeviceinformation` |
| Estado | Inicializado, listo para almacenamiento y atestación, sin bloqueo (contador 0, máximo 32), «firmware vulnerable: Falso» según Windows | [V] `tpmtool` |
| `Win32_Tpm` (CIM) | Acceso denegado | [NV] |
| TPM-FAIL | Afecta a Intel PTT (fTPM) y a ST; **no aplica** a este Infineon discreto | [I] |
| ROCA (Infineon, generación de claves RSA) | Windows no lo marca como vulnerable. Además, solo afecta a RSA generado por el TPM. El auditor lo confirma en E-7 según el algoritmo de `s1` | [I] |
| «El borrado es posible» | Verdadero (E-15: protocolo para no borrarlo) | [V] |
| Enlace PCR7 de BitLocker | «Enlace no posible» (sin arranque seguro) | [V] |
| Arranque seguro | **Deshabilitado** (`UEFISecureBootEnabled` = 0). `Confirm-SecureBootUEFI` exige elevación | [V] registro |
| VBS / HVCI | VBS en ejecución (estado 2); HVCI configurado y en ejecución | [V] `Win32_DeviceGuard` |
| Defender | Modo normal, tiempo real activo, **protección contra alteraciones activa**, firmas del 14/10/2026 | [V] `Get-MpComputerStatus` |
| BitLocker en C: | La propiedad del shell `System.Volume.BitLockerProtection` = 2, que indica **inactivo** [I]. `Get-BitLockerVolume` exige elevación | [I]/[NV] |
| `w32time` | Servicio en ejecución (manual), pero **«sin sincronizar»**: el origen es el reloj CMOS local y no hay ninguna sincronización correcta | [V] `w32tm /query /status` |

## 7. Hyper-V, Docker y WSL (punto 7)

| Componente | Resultado | Origen |
|---|---|---|
| Hyper-V | El rol **no está instalado**: no existen `vmms.exe` ni el servicio `vmms`. El grupo «Administradores de Hyper-V» existe, pero está vacío. `HypervisorPresent` = True se debe a VBS/HVCI | [V]. El estado de la característica (`Get-WindowsOptionalFeature`) es [NV] |
| Docker | No está instalado: no hay `C:\Program Files\Docker`, ni el comando `docker`, ni el grupo `docker-users` | [V] |
| WSL | «El Subsistema de Windows para Linux no está instalado» | [V] `wsl --status` |

## 8. Acceso remoto y sincronización (E-5, E-9)

| Dato | Resultado | Origen |
|---|---|---|
| **AnyDesk** | **Servicio automático en ejecución como `LocalSystem`** | [V] `Win32_Service` |
| Escritorio remoto | `fDenyTSConnections` = 1 (deshabilitado); `TermService` detenido | [V] |
| WinRM / `ssh-agent` | Detenido / deshabilitado | [V] |
| OneDrive | En ejecución en la sesión de `lfmen` | [V] |
| Tareas programadas fuera de `\Microsoft\` | Todas con `Limited` para `lfmen`, salvo la actualización de OneDrive (SYSTEM, del fabricante) | [V] |

## 9. Qué del desarrollo necesita hoy `sysadmin` (punto 3)

Búsqueda en `GPOS-NG-rg14` (la rama más reciente) y en `GPOS NG`. Dato clave [V]: **todas las bases de usuario de las dos instancias son de `DevLab00\lfmen`**, así que `lfmen` es `dbo` en todas aunque deje de ser `sysadmin`.

| Uso | Evidencia | Permiso mínimo real | ¿Basta `dbcreator` + `dbo`? |
|---|---|---|---|
| Crear bases de prueba `GPOS_TEST_*` y borrarlas | `tests/GPOS.Tests/ModeloNg/BasesNgPrueba.cs:108`, `tests/GPOS.Tests/BasesTemporales.cs:29-30`, `tests/GPOS.Reportes.Tests/*SqlTests.cs` (`CREATE`/`DROP DATABASE`) | `CREATE ANY DATABASE` (`dbcreator`); `DROP` como dueño | **Sí** |
| `ALTER DATABASE … SET SINGLE_USER`, `AUTO_CLOSE`, `RCSI`, `RECOVERY`, `QUERY_STORE`, `COLLATE` | `src/GPOS.Migracion/Aprovisionamiento.cs:88-101, 370-378`; `src/GPOS.Core/Infraestructura/Motor/OpcionesBase.cs:42-44`; `tests/GPOS.Tests/ModeloNg/OpcionesBaseTests.cs` | `ALTER` sobre la base (dueño) | **Sí** |
| Crear la base de la empresa desde la API | `src/GPOS.Core/Infraestructura/EsquemaEmpresa.cs:205` | `CREATE ANY DATABASE` | **Sí** |
| `BACKUP DATABASE` | `src/GPOS.Migracion/Aprovisionamiento.cs:416`; `src/GPOS.Core/Servicios/RespaldoService.cs:27`; pruebas del candado | `db_owner` / `db_backupoperator` | **Sí** (con la carpeta escribible por la cuenta del servicio SQL) |
| `RESTORE DATABASE … WITH REPLACE` sobre una base existente | `tests/GPOS.Tests/ModeloNg/CandadoRestauracionApiTests.cs:75-77`; `DesbloqueoRestauracionApiTests.cs:195-197` | `dbcreator` o dueño de la base | **Sí** [I, según la documentación de RESTORE]. Ojo: si restaura otra identidad, el dueño cambia y `lfmen` deja de ser `dbo` |
| `sp_detach_db` / `CREATE DATABASE … FOR ATTACH` | `CandadoRestauracionApiTests.cs:442, 454` | `db_owner` / `CREATE ANY DATABASE` | **Sí** [I] |
| Suplantación `EXECUTE AS USER` en las pruebas | `tests/GPOS.Reportes.Tests/EjecutorConsultasSqlTests.cs:84, 134` | `IMPERSONATE` (dueño de la base) | **Sí** [I]: el caso «sin suplantar = escritura» se cumple como `dbo` |
| Vigía de esperas (`sys.dm_exec_requests`) | `src/GPOS.Core/Infraestructura/Motor/DiagnosticoEsperas.cs:32`; `tests/GPOS.Tests/ModeloNg/DiagnosticoEsperasTests.cs:52` | `VIEW SERVER STATE` | La prueba tolera que falte. Con `GRANT VIEW SERVER STATE` queda como hoy |
| **`CREATE LOGIN` en las pruebas** | `tests/GPOS.Tests/EsquemaBaseAjenaTests.cs:345, 360`; `tests/GPOS.Tests/ModeloNg/Rg14PrivilegioMinimoTests.cs:435-478` (PA-47) | **`ALTER ANY LOGIN`** | **No.** Esas pruebas fallarían |
| `GPOS.Migracion crear-lectura` / `rotar-lectura` (usuarios contenidos, `SET CONTAINMENT = PARTIAL`) | `src/GPOS.Migracion/Lectura/CredencialesLectura.cs:150-170` | Dueño de la base. Exige que `contained database authentication` = 1 (hoy 0) | **Sí, en cada uso.** Activar la opción una vez (`sp_configure`, `ALTER SETTINGS`) exige el inicio de sesión nominal |
| `crear-lectura-sistema --cuenta` (`CREATE LOGIN … FROM WINDOWS`) | `CredencialesLectura.cs:120` | `ALTER ANY LOGIN` | **No** |
| Cerrar sesiones de los usuarios de lectura al rotar | `CredencialesLectura.cs:269-324` | `ALTER ANY CONNECTION` + `VIEW SERVER STATE` | Si faltan, se degrada con aviso |
| API y DEMO en «modo Amplio» con Windows | `instalador/Demo/scripts/herramientas/Comun-Demo.ps1:128, 330`; `Instalar-Demo.ps1:70` («dbcreator o sysadmin») | Dueño de las bases | **Sí** |

**Restricción encontrada [V]:** `GPOS.Migracion` **rechaza `sa` y `gsf`** en `--login` (`src/GPOS.Migracion/Program.cs:39, 259`). Además, `crear-lectura` debe ejecutarse **con la misma cuenta de Windows que la API**, por el anillo de Data Protection (`src/GPOS.Migracion/EmpresasSistema.cs:60-62`). Por eso el «inicio de sesión nominal aparte» de SEG-L2-25 **no puede ser `gsf`**, ni tampoco un inicio de sesión de Windows de la cuenta administradora: tiene que ser **un inicio de sesión de SQL nominal nuevo**, usado desde `lfmen` con `--login` (la contraseña se pide por consola; `src/GPOS.Migracion/EmpresasSistema.cs:70-90`). Para restauraciones manuales en SSMS sigue sirviendo `gsf` (ADR-44: solo para personas).

**Conclusión del punto 3:** `dbcreator` + `dbo` cubre todo el trabajo diario y casi toda la suite. Solo fallarían las pruebas que crean inicios de sesión (2 archivos) y `crear-lectura-sistema --cuenta`. La activación de los usuarios contenidos es una operación única.

## 10. Hallazgos frente a E-1 a E-15

| # | Condición (resumen) | Resultado en PC A | Evidencia |
|---|---|---|---|
| **E-1** | Cuenta diaria estándar | **No cumple**: `lfmen` está en `Administradores` | §2 [V] |
| E-1 | Cuenta administradora aparte | **No cumple**: no existe ninguna habilitada | §3 [V] |
| E-1 | UAC «notificar siempre» y elevación por operación en el escritorio seguro | **No cumple**: `ConsentPromptBehaviorAdmin` = 5. El escritorio seguro sí está activo | §5 [V] |
| E-1 | Sin terminales elevados permanentes | **Cumple en este momento** (token sin elevar). Si hay otros procesos elevados es [NV] | §2 |
| E-1 / SEG-L2-25 | No es `sysadmin` de ninguna instancia SQL local | **No cumple**: `sysadmin` en `.\SQLEXPRESS`, en `.` y en LocalDB | §4 [V] |
| E-1 / SEG-L2-25 | Sin grupos con efecto de administrador (Hyper-V, `docker-users`, Remote Desktop/Management, Backup Operators…) | **Cumple**, salvo `Administradores` | §2, §7 [V] |
| E-2 | Cuenta `gsf-firma` local estándar, sin cuenta Microsoft… | **No cumple**: la cuenta no existe | §3 [V] |
| E-3 | Se entra solo para firmar | No verificable (es un procedimiento; no hay cuenta) | — |
| E-4 | Firewall saliente de `gsf-firma` solo hacia NTP | No verificable (no hay cuenta). Además, el Firewall de Windows no filtra por usuario de forma nativa [I] | — |
| E-5 | Sin acceso remoto activo durante la firma | **No cumple hoy**: AnyDesk automático en ejecución como `LocalSystem`. El escritorio remoto, WinRM y SSH sí están desactivados | §8 [V] |
| E-6 | Llave no exportable, PIN en cada firma | No verificable (no hay llave) | — |
| E-7 | TPM revisado y prueba negativa | **Parcial**: Infineon SLB9670 discreto, firmware 7.63.3353.0, sin vulnerabilidad según Windows; falta la prueba negativa | §6 [V]/[I] |
| E-8 | Resumen y verificación tras firmar | No verificable (no hay emisor) | — |
| E-9 | Carpeta de la llave fuera de respaldos y sincronización | No verificable. OneDrive está activo en `lfmen` (la carpeta de `gsf-firma` debe quedar fuera) | §8 |
| E-10 | BitLocker con PIN de arranque | **No cumple** [I]: propiedad del shell = inactivo; PCR7 sin enlace. Confirmarlo exige elevación [NV] | §6 |
| E-11 | Emisor reproducible instalado con la cuenta administradora | No verificable (no hay emisor ni cuenta administradora) | — |
| E-12 | Registro encadenado, ancla desde otro dispositivo | No verificable | — |
| E-13 | Arranque seguro, HVCI, Defender con protección contra alteraciones, actualizaciones, `w32time` confiable | **No cumple**: arranque seguro deshabilitado y `w32time` sin sincronizar. HVCI, Defender y actualizaciones sí cumplen | §6 [V] |
| E-14 | Auditoría mensual de los usos de la llave | No verificable | — |
| E-15 | No borrar el TPM; protocolo de BIOS; firma trimestral | No verificable (es un procedimiento). El TPM es discreto: lo de «reiniciar el fTPM» no aplica, pero el borrado sí es posible | §6 |

## 11. Cambios necesarios para cumplir E-1 con SEG-L2-25 (NO EJECUTADOS)

Hay que seguirlos en este orden para no quedar sin administrador ni sin `sysadmin`. Las contraseñas se escriben solo en el aviso y se guardan en el gestor de contraseñas: aquí aparecen como `<secreto>`.

**Windows**
- **W-1.** Con `lfmen` elevado (una vez), crear una cuenta local administradora aparte, sin cuenta Microsoft y con una contraseña de 16 caracteres o más. Por ejemplo: `net user adm-<iniciales> * /add`, y luego `net localgroup Administradores adm-<iniciales> /add`.
- **W-2.** **Probar** la cuenta nueva **antes** de seguir: iniciar sesión con ella una vez y abrir una consola elevada desde `lfmen` con sus credenciales.
- **W-3.** Desde la cuenta administradora: `net localgroup Administradores lfmen /delete`. Luego cerrar la sesión de `lfmen` y volver a entrar (el token se recalcula al iniciar sesión).
- **W-4.** UAC: `ConsentPromptBehaviorAdmin` = **2** («notificar siempre»; el valor 1, que pide credenciales en el escritorio seguro, es más estricto). Mantener `PromptOnSecureDesktop` = 1, `EnableLUA` = 1 y `ConsentPromptBehaviorUser` = 3. Mantener Sudo para Windows deshabilitado.
- **W-5.** Mantener deshabilitada la cuenta `Administrador` integrada. Confirmar con el propietario para qué existe `BigLocker` y deshabilitarla si no se usa.
- **W-6.** Comprobar: `whoami /groups` sin `Administradores` y `net localgroup Administradores` = solo `Administrador` (deshabilitada) y `adm-<iniciales>`.

**SQL Server** (en `.\SQLEXPRESS` y en `.`; ejecutar como `gsf` o desde `lfmen` **antes** de quitarle `sysadmin`)
- **S-1.** Comprobar que `gsf` entra y es `sysadmin` (es la red de seguridad para no quedarse sin `sysadmin`).
- **S-2.** `ALTER SERVER ROLE dbcreator ADD MEMBER [DevLab00\lfmen];`
- **S-3.** Opcional, para el vigía de esperas: `GRANT VIEW SERVER STATE TO [DevLab00\lfmen];`
- **S-4.** Crear un **inicio de sesión de SQL nominal aparte** (por ejemplo, `lm_dba`): `CREATE LOGIN [lm_dba] WITH PASSWORD = '<secreto>', CHECK_POLICY = ON;`. Recomendado: permisos mínimos en lugar de `sysadmin`: `dbcreator`, `GRANT ALTER ANY LOGIN`, `GRANT ALTER ANY CONNECTION`, `GRANT VIEW SERVER STATE`. Alternativa: `sysadmin`, como dice SEG-L2-25. Dejarlo deshabilitado (`ALTER LOGIN [lm_dba] DISABLE`) y habilitarlo con `gsf` solo cuando haga falta. No puede ser `gsf` porque `GPOS.Migracion` lo rechaza (§9).
- **S-5.** Solo si se va a usar `crear-lectura` en la instancia, una vez y con `gsf`: `sp_configure 'contained database authentication', 1; RECONFIGURE;`
- **S-6.** Al final: `ALTER SERVER ROLE sysadmin DROP MEMBER [DevLab00\lfmen];`. Comprobar `IS_SRVROLEMEMBER('sysadmin')` = 0 e `IS_SRVROLEMEMBER('dbcreator')` = 1, y ejecutar la suite completa de `GPOS.Tests` y `GPOS.Reportes.Tests`.
- **S-7.** LocalDB: no se usa en el repositorio. Ejecutar `sqllocaldb stop MSSQLLocalDB` y `sqllocaldb delete MSSQLLocalDB` (o desinstalarlo), **o** pedir al auditor que lo acepte como excepción, porque corre con la cuenta del usuario y no da escalada [I].
- **S-8.** Si se restaura una base con `lm_dba` o `gsf`, devolverle el dueño: `ALTER AUTHORIZATION ON DATABASE::[<base>] TO [DevLab00\lfmen];`

**Código y pruebas** (no es de devops; ver la sección de entregas)
- **C-1.** Las pruebas que crean inicios de sesión (`EsquemaBaseAjenaTests.cs:345`, `Rg14PrivilegioMinimoTests.cs:435-478`) deben omitirse con un motivo cuando falte `ALTER ANY LOGIN`, o correr en una sesión aparte con `lm_dba`.

**Lo que E-1 no cubre, pero bloquea AI-09 en este equipo:** AnyDesk (E-5), arranque seguro (E-13; el equipo es UEFI con GPT, así que se activa en el BIOS sin convertir el disco), `w32time` con NTP confiable (E-13), BitLocker con TPM+PIN (E-10) y la cuenta `gsf-firma` (E-2).

## 12. Costo para el desarrollo diario

| Concepto | Estimación | Origen |
|---|---|---|
| Aplicar W-1 a W-6 y S-1 a S-8 y repetir la suite | **≈ 0,5 dp** de devops con el propietario | [I] |
| Adaptar las 2 clases de pruebas que crean inicios de sesión | **≈ 0,25 dp** de desarrollo y QA | [I] |
| Costo en dinero | 0 | — |
| Fricción semanal | **≈ 5-15 min/semana**: escribir la contraseña de administrador en el escritorio seguro para instalar o actualizar Visual Studio, SDK o cargas de MAUI (`dotnet` está en `Program Files`), servicios de Windows (`NT SERVICE\GPOS.Reportes`), el instalador DEMO como servicio y detener o iniciar los servicios de SQL. Además, usar `lm_dba`/`gsf` para `crear-lectura-sistema` y para las restauraciones fuera de las pruebas | [I], según la frecuencia observada en el repositorio |
| Lo que no cambia | `dotnet build`/`test`, MAUI (el modo de desarrollador ya está activo), Kestrel en puertos altos, Git, las tareas programadas `Limited`, los agentes de Claude Code y el DEMO en «modo Amplio» (`lfmen` es dueño de las bases) | [V] por la configuración, [I] por el comportamiento |
| Riesgo de la transición | Quedarse sin administrador o sin `sysadmin` si se altera el orden; un agente o script que hoy dependa en silencio de la autoelevación fallará y habrá que descubrirlo | Se mitiga con W-2 y S-1 |

## 13. Recomendación

1. **No generar `s1` en la PC A.** E-1 no se cumple hoy, y aunque se cumpla, la PC A sigue sin cumplir E-5, E-10 y E-13. Además, según la memoria del proyecto es un equipo de soporte, sin UPS y de 2016 (CPU fuera de la lista oficial de Windows 11). Con la salida que fija DL-13 («no relajar E-1»), este equipo no es un buen emisor.
2. **E-1 sí es viable aquí** si el propietario quiere endurecer la PC A de todos modos: no hay Hyper-V, Docker ni WSL, y como `lfmen` es dueño de todas las bases, `dbcreator` + `dbo` cubre el trabajo diario. Cuesta unos 0,75 dp en total y entre 5 y 15 min por semana. Lo recomiendo como buena práctica, **no** como paso previo a AI-09 en este equipo.
3. **Para AI-09 recomiendo DL-10 (b), las YubiKeys** (≈ USD 110 sin FIPS o ≈ USD 176 con FIPS [I, según `[SEG]`]). El toque físico obligatorio quita el vector de la firma silenciosa en un equipo de desarrollo, y E-1 baja a «muy recomendada» (a'). Si el propietario prefiere `s1` en un TPM, debe ir en **el equipo que de verdad sea el principal** (supuesto S-1), con un O-6 repetido allí antes de AI-09.

---

### Cierre
- Estado: Completado (inventario). Recomendación para E-1 en la PC A: **No listo**
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\inventario-o6-equipo-a-2026-10-14.md`
- Supuestos: S-1 (no está confirmado que la PC A sea el equipo principal; según la memoria, es de soporte); BitLocker inactivo, inferido de la propiedad del shell; el estado de la característica Hyper-V se infiere porque falta `vmms.exe`; los permisos mínimos de RESTORE, ATTACH y `EXECUTE AS` se toman de la documentación de SQL Server, sin probarlos aquí
- Decisiones candidatas a ADR: (1) el inicio de sesión nominal aparte de SEG-L2-25 es un inicio de sesión de SQL nuevo (`lm_dba`), no `gsf` ni uno de Windows, porque `GPOS.Migracion` rechaza `gsf` y exige la cuenta de la API. Alternativa descartada: `gsf`. (2) Darle permisos mínimos (`dbcreator`, `ALTER ANY LOGIN`, `ALTER ANY CONNECTION`, `VIEW SERVER STATE`) en lugar de `sysadmin`. Alternativa: `sysadmin`, como dice SEG-L2-25
- Entregas a otros agentes: auditor-seguridad → decidir sobre LocalDB (excepción o borrado), validar `lm_dba` con permisos mínimos y confirmar ROCA/E-7 según el algoritmo de `s1`; desarrollador o QA → C-1 (omitir las pruebas de `CREATE LOGIN` cuando falte `ALTER ANY LOGIN`); arquitecto-maestro → incluir en la hoja de firma la elección del equipo emisor y DL-10 (b)
- Próximo paso recomendado: que el propietario confirme cuál es el equipo principal y elija DL-10 (b); si `s1` va a un TPM, repetir O-6 en ese equipo antes de AI-09
