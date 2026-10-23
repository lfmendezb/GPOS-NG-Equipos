[Informe de Seguridad] Revisión estática de las correcciones de PR-V (SPV-01 a SPV-17) · equipo A · 2026-10-23

- **Objeto:** rama `a/pr-v-verbos-servidor`, `git diff 1d298cf9..b8f3487a` (9 commits, 15 archivos, +973/−117). El árbol de trabajo `GPOS-NG-prv` estaba en `b8f3487a` y limpio: las líneas citadas son de esa punta.
- **Contraste:**
  - `revision-seguridad-pr-v-verbos-servidor-2026-10-22.md` (SPV-01 a SPV-17);
  - `blueprint-pr-v-verbos-servidor-2026-10-22.md`;
  - aviso `avisos/A-a-B/2026-10-23-pr-v-correcciones-de-seguridad.md`.
- **Método:** solo lectura. No se compiló, no se ejecutaron pruebas, ni `sc`, `icacls` o servicios. No reproduje el resultado de 747/747 del aviso.
- **Marcas:** [V] verificado por lectura del código; [I] inferido (comportamiento de Windows o SQL Server que hay que confirmar en la VM, spike P-8).
- **Naturaleza:** recomendación técnica. La decisión es del propietario (C2).
- Las rutas son relativas a `src/GPOS.Migracion/Servidor/` salvo que se diga otra cosa.

## Resumen y recomendación

**Quedan cerradas por lectura las siete condiciones de unión: SPV-01, 02, 04, 05, 06, 07 y 08.** De los Bajos:
- se cierran SPV-09, 10, 12, 13, 14, 16 y 17;
- SPV-11 y SPV-15 se cierran en parte; lo que falta coincide con lo que el aviso declara pendiente;
- SPV-03 sigue abierto y es del propietario.

**Lo nuevo no introduce hallazgos Críticos, Altos ni Medios.**
- `CopiarSinReanalisis` está bien planteada:
  - el identificador se abre sin seguir reanálisis y comparte solo lectura;
  - con ese mismo identificador se comprueban los atributos, los vínculos y la ruta final, y se lee de él;
  - la huella se calcula sobre los bytes que se escriben.

  No hay TOCTOU entre la comprobación y la lectura.
- `MismaDacl` no acepta una DACL más permisiva.
- `MotivoClaveServicio` ya funciona como lista blanca de titulares.

Hay **seis hallazgos Bajos nuevos (SPW-01 a SPW-06)**: dos funcionales, dos residuales de controles y dos de pruebas y recuperación.

**Recomendación: Aprobar con condiciones.**
- **Antes de unir:** ninguna condición nueva. Las de la revisión anterior se cumplen [V].
- **Antes del ensayo en la VM:**
  - SPW-01: normalizar `--origen`;
  - SPW-05: borrar `FailureCommand` con `sc failure … command= ""` y no tocando el registro.

  Cuestan 0,1 dp en total [I, ±50 %]. Sin ellas, el ensayo puede dar rechazos engañosos o un falso OK de DM-14.
- **Antes de D4:** sigue pendiente la firma de SPV-03 (residual del DEMO o manifiesto firmado).
- **El resto (SPW-02, 03, 04 y 06):** en la siguiente pasada, unos 0,4 dp [I]. No suma costo de infraestructura.

## 1. Alcance y superficie revisada

- **Fase `servicios`:**
  - copia en tres pasos: preparación → copia previa → destino, con restauración;
  - `CopiarSinReanalisis`;
  - lista de permitidos de `--usuario-instala`;
  - rotación de la clave JWT por la DACL al entrar;
  - `--destino` dentro de `%ProgramFiles%`;
  - validación de las rutas del manifiesto;
  - `FailureCommand`;
  - idempotencia de `sdset`.
- **Fase `carpetas`:** lectores ajenos en las carpetas de componente.
- **Fase `esquema`:** ancla por prefijo; DM-03 con permisos y grupos.
- **`comprobar-servidor`:**
  - R3 con `MismaDacl` y dos filas nuevas;
  - R8 con `Pwd`, `Key` y `Token`;
  - P7 con las distintas grafías;
  - DM-03.
- **Plataforma:** `SeRestorePrivilege` acotado (`ConRestauracion`) y `TipoDeCuenta` (`LookupAccountSid`).
- **Pruebas:** `ComprobarServidorTests`, `ImplantarServidorTests`, `ServidorArquitecturaTests` y el doble `SistemaServidorFalso`.

## 2. Cierre de los hallazgos de la revisión anterior

| ID | Estado | Evidencia | Nota |
|---|---|---|---|
| SPV-01 | **Cerrado** [V] | `FasesImplantacion/FaseServicios.cs:226-301`. Preparación protegida (`:236-237`, DACL `CopiaPrevia`). Huella de lo copiado comparada antes de tocar el destino (`:242-257`). Restauración si falla la verificación en el destino (`:297`, `:320-334`). Pruebas `tests/GPOS.Tests/Servidor/ImplantarServidorTests.cs:377`, `:394` y `:411` | Residuales de recuperación en SPW-02 (disponibilidad, no integridad) |
| SPV-02 | **Cerrado** [V lectura; I comportamiento real] | `SistemaServidorWindows.cs:193-214`: `FILE_FLAG_OPEN_REPARSE_POINT`, comparte solo lectura (`:195`); rechaza reanálisis, carpeta y vínculos ≠ 1 (`:199`) y ruta final distinta (`:201`); lee del mismo identificador (`:203`) | Ver §4 (a). Rechazos funcionales en SPW-01 |
| SPV-03 | **Abierto** (propietario) | `FaseServicios.cs:117-120`: el manifiesto se sigue leyendo de `--origen` sin autenticar | Como en la revisión anterior |
| SPV-04 | **Cerrado** [V] | `ReglasDescriptores.cs:48`, `:100-110`: cualquier ACE de acceso concedido a otro SID es motivo (`Ajenos` con máscara `0xFFFFFFFF`); dueño SY o BA; DACL protegida. Prueba con GX, WD, WO, `0x2`, GW y KR: `ComprobarServidorTests.cs:135` | Las ACE de denegación no cuentan (correcto; `:152`) |
| SPV-05 | **Cerrado** [V] | `FaseServicios.cs:382-387`, `:394`: rota si la DACL no era conforme al entrar o no se pudo leer. `:108-110`: rota si no es Base64 de 48 bytes. Evento 5137 sin el valor (`:407-412`). Pruebas `ImplantarServidorTests.cs:281`, `:290` y `:313` (incluye fragmentos de 12 caracteres) | §4 (e) |
| SPV-06 | **Cerrado** [V], salvo R4 con el PID (pendiente declarado) | `ReglasDescriptores.cs:119-139`; `SistemaServidorWindows.cs:84-110`; comprobación antes de tocar nada (`FaseServicios.cs:45-46`, `:420-442`). Pruebas `ImplantarServidorTests.cs:605`, `:622` y `:632` | Residual SPW-04 (cuentas `…$`) |
| SPV-07 | **Cerrado en lo pedido** [V lectura; I en la instancia] | `SistemaServidorWindows.cs:466-502`: CTE recursiva sobre el login, `public` y los 7 SID de grupo; roles (`type='R'`) y permisos G/W fuera de `CONNECT SQL`, `VIEW ANY DATABASE` y `CONNECT` a extremos. `Comprobaciones/Dm03Sql.cs:24`, `:33-34` | Falsos negativos residuales en SPW-03 |
| SPV-08 | **Cerrado** [V; I marcas reales] | `ReglasDescriptores.cs:172-189`; `Comprobaciones/R3Carpetas.cs:45`. El doble devuelve el SDDL sin `G:` (`tests/…/SistemaServidorFalso.cs`, `ComoLoDevuelveWindows`). Prueba `ComprobarServidorTests.cs:160` | §4 (b) |
| SPV-09 | **Cerrado** [V] | `FasesImplantacion/FaseCarpetas.cs:44-51` (`LECTOR_NO_PERMITIDO`); `R3Carpetas.cs:31-33`. Prueba `ImplantarServidorTests.cs:119` | También rige en la precondición de `servicios` (`crear:false`) |
| SPV-10 | **Cerrado** [V; I en la VM] | `SistemaServidorWindows.cs:158`, `:537-561`: se habilita solo alrededor de `CreateDirectoryW` y se restaura con el estado anterior (no se toca si ya estaba habilitado). La estructura de `TOKEN_PRIVILEGES` (`:620-626`, 16 bytes con `Pack=4`) es correcta | Sin prueba (solo en la VM) |
| SPV-11 | **Parcial** (lo pendiente está declarado) | `FasesImplantacion/FaseEsquema.cs:39-40`: prefijo exacto con `;`, que coincide con `Anillo/MantenimientoAnillo.cs:86`. Prueba `ImplantarServidorTests.cs:675` | Siguen mezcladas la salida estándar y la de error (`SistemaServidorWindows.cs:523-524`) y se ignora el código de salida |
| SPV-12 | **Cerrado** [V] | `Comprobaciones/P7ModoIdentidad.cs:20-28`; `Comprobaciones/R8Entorno.cs:15`, `:18-19`. Pruebas `ComprobarServidorTests.cs:296` y `:311` | Ninguna variable actual de `EntornoApi` ni de `EntornoReportes` contiene `Key` ni `Token` (`DisposicionServidor.cs:114-156`), así que no hay falsos FALLA hoy |
| SPV-13 | **Cerrado** (documentado) | `src/GPOS.Migracion/Program.cs:567-573` | Remediación por documentación, como se ofreció |
| SPV-14 | **Cerrado** [V] | `FaseServicios.cs:180-189` (`IsPathFullyQualified` + `GetFullPath` + prefijo con `\`; las rutas `\\?\` y 8.3 quedan fuera, por falla cerrada); `:195-214` comprueba cada antepasado por debajo de `%ProgramFiles%`. Pruebas `ImplantarServidorTests.cs:509` y `:523` | `%ProgramFiles%` en sí no se comprueba (aceptable) |
| SPV-15 | **Parcial** (la poda está declarada pendiente) | `sdset` idempotente: `MismaDacl` ignora la SACL (`FaseServicios.cs:450`), y el doble agrega la SACL al leer. `FailureCommand`: `SistemaServidorWindows.cs:267-273` | Ver SPW-05: el borrado se hace en el registro |
| SPV-16 | **Cerrado** [V] | `FaseServicios.cs:134-146`, `:164-174`: componentes sin punto ni espacio final, sin dispositivos (incluidos `COM¹-³`), sin `~` seguido de cifra; repetidos sin distinguir mayúsculas | El espacio final de toda la ruta lo quita `Trim()` (`:133`) antes de validar: inocuo, pero ver SPW-06 |
| SPV-17 | **Cerrado** [V] | Cerrojo 1 por comportamiento: `ImplantarServidorTests.cs:537`. Mutaciones de 01, 04, 06 y 08 añadidas. El doble canoniza el SID (`ResolverSid` con `SecurityIdentifier`) | Huecos nuevos en SPW-06 |

## 3. Checklist OWASP (solo el diff)

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | SPV-04, 06, 08, 09 y 14 cerrados. Residual SPW-04 |
| A02 Criptografía | Correcta: rotación con CSPRNG de 48 bytes; SHA-256 incremental sobre lo escrito |
| A03 Inyección | Sin hallazgos [V]. La SQL de DM-03 es constante y va con parámetros (`@login` NVARCHAR(128), `@g0..@g6` VARBINARY(85)), sin `EXECUTE AS`. El SID se canoniza antes de construir el SDDL. El manifiesto no admite `:` ni caracteres no válidos |
| A04 Diseño inseguro | SPW-02 (recuperación del paso 3) |
| A05 Configuración | SPW-03 (DM-03 residual), SPW-05 (`FailureCommand`) |
| A06 Componentes vulnerables | No aplica: no se agregan paquetes |
| A07 Autenticación | SPV-05 cerrado; la clave nunca sale [V] |
| A08 Integridad de software | SPV-01, 02 y 16 cerrados; SPV-03 abierto; SPW-01 |
| A09 Registro y monitoreo | Correcto: el 5137 sin valor; los mensajes de error dan el tipo de excepción, no el mensaje [V] |
| A10 SSRF | No aplica (sin cambios) |

## 4. Análisis de lo nuevo y delicado

### (a) `CopiarSinReanalisis` y el flujo de tres pasos

**Lo que está bien [V]** (`SistemaServidorWindows.cs:193-214`):
- **Apertura:** `CreateFileW(GENERIC_READ, FILE_SHARE_READ, OPEN_EXISTING, FILE_FLAG_OPEN_REPARSE_POINT)`. No comparte escritura ni borrado, así que mientras se lee nadie puede abrir el archivo para escribir, renombrarlo ni borrarlo. Si alguien ya lo tenía abierto para escribir, la apertura falla y lanza `IOException` (`:196`).
- **Rechazos** (`:199`, `:201`):
  - punto de reanálisis o carpeta (`0x400|0x10`);
  - más de un vínculo físico: la ruta final de un vínculo físico es el nombre por el que se abrió, así que solo esta comprobación lo detecta;
  - ruta final distinta de la pedida, lo que detecta uniones en los antepasados.
- **Sin TOCTOU:** todo se evalúa sobre el identificador ya abierto y se lee de él (`new FileStream(h, …)`, `:203`). Cambiar la unión después de abrir no altera qué archivo se lee.
- **Huella:** `IncrementalHash` sobre los mismos bytes que se escriben (`:208-213`). Lo que se compara con el manifiesto es exactamente lo que queda en la preparación. Aunque un escritor previo con una sección mapeada cambiara el archivo durante la lectura [I, caso extremo], la huella describe lo copiado y no se rompe la coherencia.
- **Cierre del identificador:** `using var h` y el `FileStream` que lo envuelve. El doble cierre de un `SafeFileHandle` es inocuo. En los `return null` y en las excepciones se cierra por el `using` [V].

**DACL del destino (hipótesis [I] del agente):** el razonamiento es correcto.
- Un archivo **creado** por `CopyFileEx` en `destino\api` no copia la DACL del origen: recibe la heredada de `%ProgramFiles%` (Usuarios con RX, `CREATOR OWNER` → administradores, TrustedInstaller y SYSTEM). La cuenta virtual lo lee como miembro de `BUILTIN\Users` [I].
- Un archivo **trasladado** dentro del volumen conserva sus ACE heredadas de `.preparacion` (solo SY y BA): el servicio no podría leer su ejecutable.
- Matiz [I, VM]: al **sobrescribir** un archivo que ya existía, la copia conserva la DACL del archivo existente. Hoy es inocuo, porque solo un administrador pudo cambiarla, pero conviene que la VM lo confirme.
- Alternativa descartada, que solo citamos: trasladar y después restablecer la herencia con `SetSecurityInfo` (`UNPROTECTED_DACL` y DACL vacía). No es más atómica que copiar y añade una llamada nativa más.

**¿Puede quedar el destino mezclado o sin servicio?** Por **integridad, no**: todo lo que llega al destino viene de la preparación ya verificada o de `.anterior`. Por **disponibilidad, sí**, en tres casos (SPW-02):
- con el servicio en marcha, los archivos en uso hacen fallar el paso 3, y `Restaurar` se detiene en el primer error;
- si el proceso muere a mitad del paso 3, la siguiente pasada borra `.anterior` y respalda el estado mezclado;
- la ruta de excepción del paso 1 no borra la preparación.

### (b) `MismaDacl` y `MotivoClaveServicio`

**`MismaDacl`** (`ReglasDescriptores.cs:172-189`) exige:
- el mismo dueño, si el esperado lo trae;
- la misma marca de protección (XOR);
- **igualdad de conjuntos** de (tipo, SID, máscara exacta, marcas sin `ID`).

No puede aceptar una DACL más permisiva [V]:
- una ACE de más, un SID distinto, una máscara más amplia o una propagación distinta rompen la igualdad;
- una ACE de objeto o condicional da `false`.

Ignorar el orden no es un riesgo: el esperado no tiene ACE de denegación, así que un conjunto igual tampoco las tiene. Sí hay un hueco de prueba: no hay un caso que cambie solo la máscara (SPW-06). En los objetos de servicio, el esperado no trae `O:` y el dueño no se compara; `sc sdshow` tampoco lo devuelve, así que no es una regresión.

**`MotivoClaveServicio`** (`:100-110`):
- trabaja con lista blanca de titulares;
- exige dueño SY o BA, que es lo que cubre los derechos implícitos del dueño, y DACL protegida;
- rechaza también `OWNER RIGHTS`, `CREATOR OWNER`, los SID de capacidad y las ACE solo heredables de otros SID (estricto, y está bien).

`ProtegerClaveServicio` no fija el dueño (`SistemaServidorWindows.cs:314-323`). Si la clave tuviera otro dueño, la fase se detiene después de protegerla: es falla cerrada [V].

### (c) Lista de permitidos de `--usuario-instala`

Se rechazan [V]:
- los grupos (`SID_NAME_USE` 2, 4 y 5);
- las cuentas desconocidas o borradas (6 a 9 → `Otro`) y lo que `LookupAccountSid` no encuentra;
- los RID integrados 501 a 503 y otros por debajo de 1000;
- cualquier autoridad distinta de `S-1-5-21-` o `S-1-12-1-`, lo que cubre NETWORK, SERVICE, LOCAL, `NT SERVICE\*`, `IIS APPPOOL\*` e Invitados.

Se admiten SYSTEM y Administradores, que ya gobiernan el servicio.

Lo que acepta y quizá no debería (SPW-04):
- cuentas de equipo (`EQUIPO$`), gMSA o MSA y cuentas de confianza entre dominios, que tienen RID ≥ 1000 y `LookupAccountSid` las devuelve como `SidTypeUser` [I];
- cuentas locales deshabilitadas, incluida la 500. Esto es inocuo: no pueden iniciar sesión.

Funcional [I]: con una cuenta de dominio sin contacto con el controlador, `LookupAccountSid` podría no resolver a quien ejecuta, y la fase se detendría con 4 (falla cerrada).

### (d) DM-03

La consulta (`SistemaServidorWindows.cs:472-490`) es constante, va parametrizada y no usa `EXECUTE AS LOGIN` [V]. La recursión es `UNION ALL` con `MAXRECURSION 32`: si hubiera un ciclo o más de 32 niveles, lanza `SqlException` → `null` → Fallida o AVISO, es decir, falla cerrada.

Hay **falsos negativos posibles** (SPW-03):
1. **Grupos fuera de la lista fija.** Por ejemplo, la cuenta virtual añadida a `BUILTIN\Administradores` o a un grupo local propio que tiene inicio de sesión con roles.
2. **Visibilidad de metadatos.** Si quien ejecuta ve el inicio de sesión pero no las pertenencias ni los permisos de otros, el resultado parcial da OK [I].
3. **SQL remoto.** La cuenta virtual se autentica como `DOMINIO\EQUIPO$`, que no se mira. Hoy da AVISO, no OK, porque `NT SERVICE\GPOS.Api` no existe en el remoto; en la fase `esquema`, en cambio, no se comprueba `LoginExiste`.

El caso típico de las instancias antiguas (BU, AU, SERVICE, ALL SERVICES o Todos con roles) sí queda cubierto [V].

### (e) Rotación de la clave JWT

El valor solo existe en la lista que va a `EscribirEntornoServicio` (`FaseServicios.cs:113`, `:398`). El informe y el evento usan una constante (`:409-411`) [V]. Al instalar por primera vez, la DACL por omisión cuenta como «abierta», pero sin clave previa no hay evento (`sustituida` es `false`), y está bien. Una entrada `JWT__CLAVE=` con otras mayúsculas se descarta, porque el entorno se reescribe entero (`:108`, `:113`, `:396-398`) [V].

### (f) `SeRestorePrivilege`

Ver SPV-10 en la tabla: correcto [V]. Mientras dura `CreateDirectoryW`, otros hilos del proceso tienen el privilegio. Es un riesgo despreciable en una herramienta de consola de un solo flujo.

### (g) `--destino` y rutas del manifiesto

Ver SPV-14 y SPV-16 en la tabla [V]. `--origen` **no** se normaliza (SPW-01).

### (h) Pruebas

Prueban lo que dicen en la capa de decisión. Las mutaciones que quedarían sin detectar están en SPW-06.

## 5. Hallazgos nuevos

| ID | Severidad | Título |
|---|---|---|
| SPW-01 | Baja (funcional, falla cerrada) | `--origen` sin normalizar y paquetes en OneDrive: rechazos con el mensaje engañoso «PUNTO_DE_REANALISIS o vínculo» |
| SPW-02 | Baja | Recuperación del paso 3: con los servicios en marcha o tras una caída, el destino puede quedar mezclado y `.anterior` sustituido por ese estado; la preparación queda si hay una excepción en el paso 1 |
| SPW-03 | Baja | DM-03 residual: grupos locales fuera de la lista fija, visibilidad de metadatos de quien ejecuta y SQL remoto (cuenta de equipo) |
| SPW-04 | Baja | `--usuario-instala` acepta cuentas de equipo, gMSA o MSA y de confianza (nombres que terminan en `$`) |
| SPW-05 | Baja | `FailureCommand` se borra escribiendo el registro detrás del SCM; `LeerServicio` también lee el registro, así que no vería una divergencia |
| SPW-06 | Baja | Pruebas: el espacio final pasa por «repetido», `MismaDacl` sin mutación de máscara, y la capa real (copia, `LookupAccountSid`, SQL, privilegio, restauración con excepción) sin prueba fuera de la VM |

### SPW-01 (Baja): `--origen` sin normalizar; OneDrive

- **Riesgo:** `o.Origen` llega tal cual desde `ComandosServidor.cs:24` hasta `FaseServicios.cs:244`. `EsLaRuta` (`SistemaServidorWindows.cs:573-578`) compara la ruta final, absoluta y con `\`, con la pedida. Por eso estas entradas se rechazan con `PUNTO_DE_REANALISIS o vínculo en el paquete` (`FaseServicios.cs:249`), aunque no lo sean [V lectura]:
  - una ruta relativa (`.\paquete`);
  - una con `/`;
  - una con unidad `subst` o de red.

  Además, los archivos de OneDrive (Cloud Files, incluso hidratados) son puntos de reanálisis [I]. Un paquete extraído dentro de una carpeta sincronizada (Escritorio o Documentos redirigidos, o la carpeta compartida del DEMO) se rechaza siempre. No es una brecha, porque falla cerrada, pero sí una regresión funcional respecto de `File.Copy` y una fuente de diagnósticos falsos en la VM.
- **Remediación** (unas 0,05 dp):
  - `Path.GetFullPath` sobre `--origen` y exigir `IsPathFullyQualified`;
  - un mensaje distinto para cada causa: reanálisis, vínculos, ruta final distinta;
  - documentar en `Instalar-Demo` que se extraiga fuera de OneDrive, idealmente en una carpeta solo de administradores, lo que también reduce SPV-03.

### SPW-02 (Baja): recuperación del paso 3

- **Riesgo** [V lectura]:
  - **Servicios en marcha.** El paso 3 copia sin comprobar si los servicios están en marcha (`FaseServicios.cs:286-296`). Un `.dll` o `.exe` en uso falla con `IOException`. `Restaurar` (`:320-334`) recorre **todas** las claves, no solo las copiadas, y aborta al primer error: con el archivo bloqueado vuelve a fallar. El mensaje dice «restaure a mano» aunque casi nada cambió. Los archivos ya restaurados quedan bien y los posteriores no se tocaron, pero el aviso es engañoso.
  - **Caída a mitad del paso 3.** No hay marca de transacción. La pasada siguiente rehace el paso 2 con `CrearCarpetaProtegida`, que **borra** `.anterior` (`:310-313`) y respalda el estado mezclado: se pierde la única copia íntegra anterior.
  - **Excepción en el paso 1.** El `catch` de `:259-262` no borra `.preparacion`. Es inocuo, porque está protegida y la borra la pasada siguiente, pero contradice «no se tocó».

  La integridad se mantiene: cada archivo del destino es una versión verificada. El riesgo es de **disponibilidad** (DLL de versiones mezcladas, servicio que no arranca).
- **Remediación** (unas 0,15 dp):
  - antes del paso 3, comprobar que los dos servicios están detenidos (estado del SCM) y, si no, detener con 4 sin tocar nada;
  - en `Restaurar`, recorrer solo lo copiado y seguir archivo por archivo, informando de lo que no se pudo restaurar;
  - guardar el manifiesto aplicado en `.anterior` y no sustituir `.anterior` si el destino no coincide con él (estado mezclado → detener y pedir restaurar);
  - en el `catch` del paso 1, borrar la preparación.

### SPW-03 (Baja): DM-03 residual

- **Riesgo:** ver §4 (d). Los tres casos exigen un error previo de un administrador o una instancia remota, de ahí la severidad. Evidencia [V]: `SistemaServidorWindows.cs:466-490`, `Dm03Sql.cs:24`, `FaseEsquema.cs:52-57` (no mira `LoginExiste`).
- **Remediación** (unas 0,15 dp):
  - al principio de la lectura, `SELECT HAS_PERMS_BY_NAME(NULL, NULL, 'VIEW ANY DEFINITION')`. Si da 0, devolver `null` (AVISO o Fallida) en vez de un resultado parcial;
  - añadir en la misma consulta los inicios de sesión de tipo `G` (grupos de Windows) que tengan roles o permisos fuera de los de siempre. Se informan como AVISO («confirme que la cuenta virtual no es miembro»), o se cruzan con la pertenencia local de `NT SERVICE\GPOS.Api` (`NetUserGetLocalGroups`) [I];
  - en la fase `esquema`, detener si `LoginExiste` es `false` después de crearlo;
  - documentar que con SQL remoto el principal es la cuenta de equipo.

### SPW-04 (Baja): cuentas `…$` en `--usuario-instala`

- **Riesgo:** `MotivoUsuarioInstala` (`ReglasDescriptores.cs:131-137`) admite cualquier `SidTypeUser` con RID ≥ 1000 de `S-1-5-21-`. Eso incluye cuentas de equipo, gMSA o MSA y cuentas de confianza [I]. Esas cuentas recibirían RP y WP sobre los dos servicios. El operador tendría que pasarlas a propósito.
- **Remediación** (unas 0,05 dp): `TipoDeCuenta` ya obtiene el nombre (`SistemaServidorWindows.cs:100-102`). Devolver `Otro` si termina en `$`, con una prueba con `EQUIPO$`.

### SPW-05 (Baja): `FailureCommand` por el registro

- **Riesgo:** `FijarRecuperacionSoloReinicio` borra el valor con `Registry` (`SistemaServidorWindows.cs:271-272`), por detrás del SCM. Si el SCM usa una copia en memoria de la configuración de recuperación, la acción de comando anterior seguiría activa hasta reiniciar [I]. `LeerServicio` también lee el registro (`:226-231`), así que R1 y DM-14 darían OK igual. Es una vía de persistencia que un administrador previo pudo dejar.
- **Remediación** (unas 0,05 dp): `sc failure <svc> reset= 86400 command= "" actions= …`, porque `ChangeServiceConfig2` con `lpCommand` vacío lo borra por el SCM, y comprobarlo en la VM con `sc qfailure`.

### SPW-06 (Baja): huecos de pruebas

- `ImplantarServidorTests.cs:476`, caso `"GPOS.Api.dll "`: el `Trim()` de `FaseServicios.cs:133` quita el espacio, y la línea se rechaza por **repetida**, no por la regla del espacio final. Quitar `' '` de `ComponenteValido` no se detecta para el último componente. Usar un componente intermedio (`app\api \x.dll`) o un archivo nuevo.
- `MismaDacl`: no hay un caso que difiera **solo en la máscara**, por ejemplo `(A;OICI;FA;;;AU)` frente a `0x1200a9`. Una mutación que no compare la máscara pasa.
- **La capa real no tiene prueba fuera de la VM.** El doble reimplementa:
  - `CopiarSinReanalisis` por antepasados (no ejercita atributos, vínculos ni ruta final);
  - `TipoDeCuenta` como tabla;
  - la consulta de DM-03, de la que solo prueba `Motivos`;
  - `ConRestauracion` y el borrado de `FailureCommand`, sin prueba alguna.

  Es aceptable por la regla del 2026-10-08, pero esas líneas entran en la lista de la VM (§7).
- Falta una prueba con `IOException` en el paso 3 (archivo en uso) que fije el comportamiento de `Restaurar` (SPW-02), y otra de la ruta de excepción del paso 1 (preparación borrada).

## 6. Controles que están bien implementados [V]

- La copia en tres pasos impide que un binario no verificado llegue al destino; la verificación final se hace en el destino con las huellas leídas una vez.
- `CopiarSinReanalisis`: identificador único, sin escritura compartida, huella de lo escrito, rechazo de reanálisis, vínculos y uniones en los antepasados.
- `MotivoClaveServicio` como lista blanca de titulares; `MismaDacl` como igualdad de conjuntos con máscara exacta.
- La rotación de la clave cuando la DACL estuvo abierta o la clave no tiene 48 bytes, sin que el valor salga nunca.
- La lista de permitidos de `--usuario-instala`, comprobada antes de cualquier cambio.
- DM-03 con permisos, `public`, grupos conocidos y roles anidados, sin suplantación y con parámetros.
- `SeRestorePrivilege` acotado a la llamada y restaurado con el estado previo.
- `--destino` normalizado y con todos los antepasados comprobados.
- El manifiesto con lista negra completa de las reinterpretaciones de Windows y sin repetidos.
- Mutaciones nuevas para SPV-01, 02, 04, 05, 06, 07, 08, 09, 11, 12, 14, 16 y 17; el doble ya canoniza el SID y devuelve el SDDL sin grupo y con SACL.

## 7. Lo que solo la VM puede confirmar (spike P-8)

En `VM-SRV`, desde el punto de control `base`, con evidencia sin valores. Además de la lista §7 de la revisión anterior:

1. **`CopiarSinReanalisis` real:**
   - una unión en `--origen\app\api` → 4;
   - un vínculo simbólico de archivo → 4;
   - un vínculo físico creado por el usuario sobre un archivo propio → 4;
   - un paquete en una ruta normal → OK;
   - un paquete en OneDrive → 4 (SPW-01);
   - una ruta 8.3 → OK por `GetLongPathNameW`.
2. **DACL resultante en `%ProgramFiles%\GPOS NG\Demo\api\*`:** `Get-Acl`. En los archivos nuevos, la heredada; en los sobrescritos, la que tenían. Que `NT SERVICE\GPOS.Api` arranca y lee su `.exe` y sus `.dll`.
3. **Paso 3 con `GPOS.Api` en marcha:** el comportamiento de `Restaurar` y el mensaje (SPW-02).
4. **`LookupAccountSid`:**
   - quien ejecuta (local y de dominio, con y sin el controlador accesible);
   - `Invitado`, `DefaultAccount`, `Usuarios del dominio` y una cuenta `EQUIPO$` o gMSA (SPW-04).
5. **DM-03 en SQL 2019 Express y en 2025:**
   - en una instalación limpia, cero filas: que `public` no traiga permisos por omisión fuera de los excluidos, porque si no daría FALLA siempre;
   - con `CONTROL SERVER` concedido a `public`, FALLA;
   - con `BUILTIN\Users` en `sysadmin`, FALLA;
   - con un rol de servidor anidado, FALLA;
   - con quien ejecuta sin `VIEW ANY DEFINITION` (SPW-03);
   - que el token real de la cuenta virtual lleva los 7 SID de `GruposCuentaVirtual` (`whoami /groups` desde un servicio de prueba).
6. **`SeRestorePrivilege`:** habilitado solo durante `CreateDirectoryW` (`whoami /priv` desde un hijo lanzado después: deshabilitado). Dueño `SY` en `.preparacion` y `.anterior`.
7. **`FailureCommand`:**
   - poner uno a mano;
   - ejecutar la fase;
   - comprobar con `sc qfailure` que no queda **sin reiniciar** (SPW-05).
8. **`sdset` y SACL:** si `sdshow` trae `S:`, la segunda pasada da `cambios=0`; si `sdset` con solo `D:` borra la SACL de auditoría.
9. **R3 en una instalación limpia:** OK. Marcas `P`, `AI` e `ID` reales en `Api\registros` y `Api\temp`.
10. **Clave del servicio recién creada:**
    - la DACL por omisión se toma como abierta;
    - en la primera pasada no hay evento 5137;
    - en la segunda la clave se conserva;
    - el dueño de la clave es SY o BA (si no, la fase se detiene).

## 8. Remediaciones priorizadas

| Orden | Hallazgos | Cuándo | Esfuerzo [I] |
|---|---|---|---|
| 1 | SPW-01 (normalizar `--origen`, mensajes por causa) y SPW-05 (`command= ""`) | antes de la VM | 0,1 dp |
| 2 | SPV-03: firma del propietario (residual) o manifiesto firmado | antes de D4 | 0 o 0,5 dp |
| 3 | SPW-02 (servicios detenidos, `Restaurar` por archivo, `.anterior` con manifiesto) | siguiente pasada | 0,15 dp |
| 4 | SPW-03 (visibilidad, grupos `G`, `LoginExiste`) y SPW-04 (`…$`) | siguiente pasada | 0,2 dp |
| 5 | SPW-06 y lo declarado pendiente (R4 con PID, separar salidas, poda, DACL de la clave de `GPOS.Reportes`) | siguiente pasada | 0,3 dp |

## 9. Recomendación

**Aprobar con condiciones.**
- Las condiciones de unión de la revisión del 22-oct están cumplidas [V por lectura].
- No hay hallazgos Críticos, Altos ni Medios nuevos.
- Antes del ensayo en la VM: SPW-01 y SPW-05.
- Antes de D4: la firma de SPV-03.
- La confirmación final de lo marcado [I] depende del spike P-8 (§7).

### Cierre
- Estado: Aprobado con observaciones (recomendación técnica: **Aprobar con condiciones**).
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\revision-seguridad-pr-v-correcciones-b8f3487a-2026-10-23.md`.
- Supuestos (todos [I], a confirmar en la VM):
  - `CopyFileEx` no copia la DACL del origen y conserva la del destino que ya existía;
  - los archivos de OneDrive son puntos de reanálisis;
  - `LookupAccountSid` devuelve `SidTypeUser` para las cuentas `…$`;
  - el SCM no relee `FailureCommand` del registro;
  - la cuenta virtual lleva los 7 SID de `GruposCuentaVirtual`.
- Decisiones candidatas a ADR: ninguna nueva (sigue la de SPV-03, el manifiesto firmado).
- Entregas a otros agentes:
  - desarrollador o arquitecto-software de A → SPW-01 a SPW-06;
  - devops de A (PR-D2) → extraer el paquete fuera de OneDrive y en una carpeta solo de administradores, y detener los servicios antes de `--fase servicios` en `Actualizar`;
  - B/C (spike P-8) → §7;
  - arquitecto-maestro → la firma de SPV-03.
- Próximo paso recomendado: corregir SPW-01 y SPW-05 (0,1 dp) y llevar la §7 a la VM.
