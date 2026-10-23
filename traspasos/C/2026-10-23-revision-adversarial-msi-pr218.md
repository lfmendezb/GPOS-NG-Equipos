Para: B        De: C        Fecha: 2026-10-23
Tipo: Revisión adversarial (backlog autónomo de B-a-C/2026-10-23-backlog-autonomo-para-c-tanda-7, punto 3)
Prioridad: Alta (antes de las sesiones de VM-SRV con el MSI)
Repositorio y rama: GPOS-NG #218 `b/t1b-api-msi` @ 57ba6585 (solo lectura), base `feature/modelo-ng` @ b9efa9fb
Estado: Abierto

Convención: [V] = lo comprobé con un comando y su resultado en mi equipo; [I] = inferido del código, de la documentación o de la conducta conocida de Windows Installer. El árbol es el worktree de C en 57ba6585 (HEAD separado). No cambié el PR, no lo comenté y no empujé nada. Tras cada mutación restauré con `git checkout -- <archivo>`; al terminar, `git status --short` sale vacío [V]. Compilé una sola vez (`GPOS.Tests`, Debug); las pruebas leen el `.wxs` y el `.ps1` en tiempo de ejecución, así que cada mutación se corrió con `--no-build`.

**Lo que no pude correr:** WiX 5.0.2 no está en este equipo (ni en la caché de NuGet ni en el PATH) y no lo descargué. Por eso no construí el `.msi` ni leí sus tablas (`MsiLockPermissionsEx`, `MsiServiceConfig`, `Wix4ServiceConfig`, `File`), ni vi el texto real de `WIX1149`. Tampoco pude lanzar `construir.ps1 -Firmar` a mano (el entorno de C rechaza invocar PowerShell desde la consola del agente); la guarda G-PR4 la ejercí a través de T1-09, que sí lanza PowerShell (sección 3, G1 a G4). No instalé nada.

# Veredicto

**Rechazado para unir tal como está** (recomendación técnica; la decisión es del propietario, C2). El MSI **sirve para el laboratorio** (es `-SINFIRMA` y no se distribuye), pero queda un hallazgo **Alto** sin cambio en 57ba6585: H218-01 (L-02 confirmado por lectura, y agravado: la actualización borra y recrea el servicio, y si la comprobación O-1 rechaza la versión nueva, el equipo queda **sin la API**). B ya anunció la segunda pasada del `.wxs`; con H218-01 y H218-02 resueltos, mi recomendación pasaría a «Aprobado con observaciones».

- Corrida propia sin mutar: `ApiInstaladorTests`, `FragmentosInstaladorTests` y `LaboratorioInstaladorTests`, **38/38** [V], igual que el PR.
- Mutaciones del desarrollador: las 5 que declara el PR (`--urls x`, `Start="install"`, BU por WD, quitar `FailureActionsWhen`, G-PR4) **se detectan** [V las cuatro del `.wxs`; la de G-PR4, por T1-09].
- **No bastan.** De 21 mutaciones mías, la suite mata 8 y **deja vivas 12** (una más es equivalente). Las vivas que importan: **todo `MajorUpgrade`** (quitarlo, permitir la degradación o cambiarle el calendario), el **GUID del componente del servicio**, un `util:PermissionEx` de más que da control total a Usuarios sobre `Api\`, el `Files` sin recursión, y un directorio padre público (`INSTALLDIR`).
- ¿Alguna prueba pasa sin probar? Sí, tres, de alcance (H218-06). T1-07 se llama «El MSI no…», pero solo lee `Package.wxs`, y el MSI sí lleva acciones personalizadas. T1-10 pasa en vacío, como B declara, y además no mira `.wxs` ni el spike. Las tres últimas afirmaciones de la prueba de Q-5 son tautológicas. No encontré ninguna que pase **en falso** (afirmar algo que no es cierto del `.wxs`).
- ACE de BU `0x2008D`: **correcta.** CC (0x1), LC (0x4), SW (0x8), LO (0x80) y RC (0x20000) suman 0x2008D, sin CR, RP, WP, DT ni SD. Coincide con Q-5 y con la fila de `MsiLockPermissionsEx` que B leyó. Hay tres observaciones en H218-05.
- `WIX1149`: aceptable conservarla. Si `MsiServiceConfig` no se aplica, el servicio **falla cerrado** (`ARRANQUE_PRIVILEGIOS`, `src/GPOS.Api/Servicio/ModoServicioApi.cs:200-201`): es un problema de disponibilidad, no de confidencialidad. Falta una comprobación automática después de construir (H218-04).

# 1. Alcance y superficie revisada

- `instalador/Api/Package.wxs` (122 líneas), `GPOS.Api.Instalador.wixproj`, `construir.ps1` (111 líneas) y `tests/GPOS.Tests/Instalador/ApiInstaladorTests.cs` (422 líneas, 11 casos).
- Lo que el MSI compila de fuera:
  - `instalador/Comun/Fragmentos/ComprobacionCarpetasPrevias.wxs`, con las acciones en `:48-50` y su programación en `:72-75`;
  - `RaizGposNg.wxs`;
  - `instalador/Comun/Firma-Instalador.ps1` (`Resolver-Firma`);
  - `instalador/Publicacion/Comprobar-PublicacionRelease.ps1`.
- Contrapartes:
  - `src/GPOS.Api/Servicio/ModoServicioApi.cs`: privilegios en `:20`, argumento en `:42`, comprobación del token en `:186-201`;
  - `src/GPOS.Api/GPOS.Api.csproj`, que no declara `Version` y no hay `Directory.Build.props`;
  - `instalador/Demo/LEEME.md:19`;
  - `tests/laboratorio-adr090/invitado/Probar-Spike-Amplio.ps1:111-115`;
  - `tests/GPOS.Tests/Instalador/FragmentosInstaladorTests.cs:524-528` y `:663-681`.
- Contexto: mis hallazgos L-01 a L-07 (`traspasos/C/2026-10-23-casos-laboratorio-gpos-api-msi.md`, sección 3), la respuesta de B (`avisos/B-a-A/2026-10-23-posicion-de-b-sobre-hallazgos-msi-y-pr-d2.md`) y el cuerpo del PR #218 (leído con `gh pr view`, sin comentar).

**Superficie expuesta del MSI:**
- el objeto de servicio `GPOS.Api` (SDDL de Q-5);
- la clave `HKLM\SYSTEM\CurrentControlSet\Services\GPOS.Api`: el MSI no la escribe, pero su ciclo de vida la crea y la borra (H218-01);
- `%ProgramFiles%\GPOS NG\Api`, con la DACL heredada de Program Files;
- `%ProgramData%\GPOS NG\Api`, con DACL protegida;
- los orígenes del Visor de eventos;
- la tabla `GposCarpetaPrevia` (O-1).

No hay endpoints: el MSI no arranca el servicio.

# 2. Corridas [V]

| Corrida | Filtro | Resultado |
|---|---|---|
| Base (57ba6585, sin mutar), una compilación | `ApiInstaladorTests\|FragmentosInstaladorTests\|LaboratorioInstaladorTests` | **38/38** superadas, 6 s |
| D1 a D4, C01 a C17 y G1 a G4, una por vez | `ApiInstaladorTests` (11 casos); a las sobrevivientes las volví a correr con las tres clases (38) | Tabla de la sección 3. Logs y diffs en el scratchpad de C (`mut218-*.log` y `.diff`, `mut218x-*.log`) |

Guiones: `mut218.sh`, `mut218b.sh` y `mut218c.sh` en el scratchpad de la sesión de C. Cada guion aplica la mutación con `perl -0pi`, comprueba que haya diff, corre y restaura.

# 3. Mutaciones [V]

Líneas de 57ba6585. «Muere» = alguna prueba falla. Las sobrevivientes se volvieron a correr contra las 38 de las tres clases: ninguna muere salvo C13 (por Fragmentos) y C17.

| # | Mutación | Resultado | Prueba que la mata |
|---|---|---|---|
| D1 (de B) | `Arguments="--servicio --urls x"` | Muere | T1-05 y T1-07 |
| D2 (de B) | `ServiceControl … Start="install"` | Muere | T1-05 y T1-07 |
| D3 (de B) | SDDL del servicio: BU → WD | Muere | `El_SDDL_del_servicio_del_MSI_es_el_de_Q5` |
| D4 (de B) | Quitar `FailureActionsWhen` | Muere | T1-05 |
| G1 | Guarda: `Select-String … -NotMatch` | Muere | T1-09 (casos sintéticos) |
| G2 | Guarda: quitar el rechazo si el archivo no existe | Muere | T1-09 (falla cerrada) |
| G3 | Guarda: patrón anclado (`^FijarEscuchaPorOmision`) | Muere | T1-09 |
| G4 | Llamar a la guarda **después** de `Resolver-Firma` | Muere | T1-09 (orden) |
| **C01** | Quitar `<MajorUpgrade … />` (`:34`) | **Vive** | — |
| **C02** | `<MajorUpgrade AllowDowngrades="yes" />` (se puede degradar) | **Vive** | — |
| **C03** | `MajorUpgrade Schedule="afterInstallExecute"` (el arreglo de H218-01) | **Vive** | — (nada fija el calendario en ningún sentido) |
| **C04** | `Files Include="…\*"`, sin recursión (`:117`): se pierden `runtimes\`, `wwwroot\`, etc. | **Vive** | — |
| **C05** | `DirGposNgPrograma` → `INSTALLDIR`, una propiedad pública que se redirige desde la línea de órdenes (S-05) | **Vive** | — (solo se fija el hijo `Api`, `:197`) |
| **C06** | `Scope="perUser"` | **Vive** | — |
| **C07** | Otro GUID para el componente `ProgramaApi` (el del servicio) | **Vive** | — (solo se exige que sea aleatorio y distinto) |
| C08 | `ThirdFailureActionType="none"` (la propuesta de B para L-01) | Muere | T1-05: habrá que actualizarla al decidir Q-3 |
| C09 | GUID de `OrigenInstalacion` igual al de `ProgramaApi` | Muere | T1-08 |
| **C10** | Agregar `<util:PermissionEx User="Users" GenericAll="yes" />` en el `CreateFolder` de `DatosApi` | **Vive** | — (se fija el `PermissionEx` del núcleo, no la ausencia de otros) |
| **C11** | `ServiceInstall … LoadOrderGroup="x"` | **Vive** | — (informativa) |
| **C12** | `construir.ps1`: no borrar `publicacion\` antes de publicar (`:59`) | **Vive** | — |
| C13 | `construir.ps1`: quitar `Comprobar-BinarioEnMsi` (`:100`) | Muere | `FragmentosInstaladorTests…T1_04` |
| **C14** | `construir.ps1`: el `catch` ya no borra el `.msi` sin firma (`:103`) | **Vive** | — |
| C15 | `construir.ps1`: quitar el `$LASTEXITCODE` tras `Comprobar-PublicacionRelease` (`:65`) | Vive, **equivalente**: ese guion lanza (`throw`, `:150`) y `$ErrorActionPreference="Stop"` corta. La línea `:65` es código muerto: lee el código de salida de `dotnet publish` | — |
| **C16** | `construir.ps1`: con `-Firmar`, no borrar los `.msi` previos de `bin` (`:56`) | **Vive** | — |
| C17 | `construir.ps1`: el nombre `-SINFIRMA` deja de aplicarse | Muere | `Construir_ps1_…SINFIRMA…` |

**Conclusión sobre las mutaciones de B.**
- Bastan para lo que declaran: argumento, arranque, Q-5 y `FailureActionsWhen`. La guarda G-PR4 está bien blindada (G1 a G4).
- No cubren el **ciclo de vida del producto**: actualización, degradación, estabilidad del componente del servicio y alcance del ámbito y de los directorios. Tampoco cubren la **ausencia** de permisos de más.
- Las dos más graves son C01 a C03, porque el arreglo de H218-01 quedaría sin protección, y C10, porque deshace ADR-77 en `Api\` sin que falle nada.

# 4. Hallazgos

| ID | Severidad | Título |
|---|---|---|
| H218-01 | **Alta** | `MajorUpgrade` (calendario por omisión) + `ServiceControl Remove="uninstall"`: cada actualización borra y recrea el servicio (L-02), y si O-1 rechaza la versión nueva, el equipo queda sin API |
| H218-02 | **Media** (pruebas) | Nada fija `MajorUpgrade` ni el GUID de `ProgramaApi` (C01, C02, C03 y C07 viven) |
| H218-03 | **Media** | Sin `-Version` todo MSI es 1.0.0: dos compilaciones distintas se instalan una junto a la otra y las `GPOS*.dll` de la segunda no reemplazan a las de la primera; `-Firmar` lo permite |
| H218-04 | Baja | `WIX1149`: nada comprueba, después de construir, que `MsiServiceConfig` lleve las dos filas; el servicio falla cerrado, pero en bucle (L-01) |
| H218-05 | Baja (informativa para el propietario) | ACE de BU `0x2008D`: correcta, pero solo la fija el texto del `.wxs`; Q-5 amplía la consulta de IU/SU a BU; no se sabe si la SACL por omisión sobrevive |
| H218-06 | Baja (pruebas) | Pruebas que pasan sin probar lo que dice su nombre: T1-07 (alcance), T1-10 (en vacío y con alcance corto), afirmaciones tautológicas de Q-5 |
| H218-07 | Baja (pruebas) | Mutantes vivos del paquete y del guion: C04, C05, C06, C10, C12, C14 y C16 |
| H218-08 | Baja | El origen compartido `GPOS.Instalacion` lo posee este MSI con un GUID propio: en una actualización se borra antes de que corra O-1, y otro MSI que lo registre lo perdería al desinstalar |
| H218-09 | Media (diseño) | La propuesta de B para L-04 (`Start="demand"` y la implantación lo pasa a `auto`) choca con H218-01: cada actualización devolvería el servicio a `demand` |
| H218-10 | Informativa | Comentarios del `.wxs` y del PR que no son ciertos (DEMO, «tres veces», G-PR4) |

## H218-01 (Alta): la actualización borra y recrea el servicio y, si O-1 rechaza, deja el equipo sin API

- **Riesgo.**
  - `<MajorUpgrade DowngradeErrorMessage=…/>` no declara `Schedule` (`Package.wxs:34`) [V]. El valor por omisión de WiX 4 y 5 es `afterInstallValidate` [I, documentación de WiX]: `RemoveExistingProducts` desinstala **toda** la versión anterior antes de instalar la nueva.
  - En esa desinstalación, el componente `ProgramaApi` de la versión anterior se quita, y su `ServiceControl Remove="uninstall"` (`:71`) borra el servicio. Después, `InstallServices` de la versión nueva lo crea de cero [I, conducta de Windows Installer].
  - Se pierde todo lo que la implantación haya escrito en la clave del servicio: el valor `Environment` (clave JWT y cadena `Sistema`), la DACL de la clave y el `Start` que haya puesto `servicios`.
  - La clave nueva nace con la DACL por omisión de `Services\`, que Usuarios puede leer [I]. Si alguien vuelve a escribir el `Environment` a mano sin reaplicar la DACL, el secreto queda **legible por Usuarios**. Por eso es Alta y no Media.
  - **Agravante que no estaba en L-02** [I]. Las acciones de O-1 están programadas `Before="InstallInitialize"` y `After="InstallInitialize"` (`ComprobacionCarpetasPrevias.wxs:72-75`), es decir, **después** de `RemoveExistingProducts` (`afterInstallValidate`). En ese punto, la desinstalación de la versión anterior ya se ejecutó como transacción propia, así que la reversión de la instalación nueva no la deshace.
    - Si O-1 rechaza `Api\` (el caso A7, dueño inseguro), el equipo queda **sin la API, sin servicio y sin el origen `GPOS.Instalacion`**, y el 4753 a 4755 del rechazo no se escribe (H218-08).
    - Es justo el «Rechazo (Alta)» de mi A7.
- **Evidencia.**
  - `Package.wxs:34` y `:71` [V].
  - `ComprobacionCarpetasPrevias.wxs:72-75` [V].
  - C03 vive: ninguna prueba fija el calendario [V].
  - El efecto sobre el servicio y la reversión: [I], de alta confianza. Lo miden A2 (centinela en `Environment`) y A7.
- **Remediación (unas 3 h más la VM; es la «segunda pasada» que B anunció).**
  1. `MajorUpgrade Schedule="afterInstallExecute"`.
     - La versión nueva se instala primero y la anterior se quita al final. Como `ProgramaApi` conserva el mismo GUID, su contador de referencias no baja a cero: no hay `DeleteServices` ni se pierde `Environment` [I].
     - O-1 corre con la versión anterior todavía instalada: si rechaza, la reversión deja la v1 intacta.
     - Esto funciona **desde cualquier versión anterior**: el calendario lo pone la versión **nueva**, no la instalada.
  2. **Fijar el GUID** `F073074E-362D-4D5F-A537-575AA1CEFD56` de `ProgramaApi` en una prueba (H218-02). Si cambia, el punto 1 deja de proteger.
  3. Costo de la opción. `afterInstallExecute` exige respetar las reglas de componentes y las de versión de archivos:
     - un archivo versionado que **baja** de versión entre dos publicaciones no se reemplaza;
     - un archivo sin versión que el administrador modificó no se reemplaza.
     - Lo mide A1, ampliado: comparar el `publicacion.sha256` de la v2 contra lo instalado, no solo el `.exe`.
  4. Prueba nueva: `MajorUpgrade` con `Schedule="afterInstallExecute"`, `DowngradeErrorMessage` presente y sin `AllowDowngrades`. Unos 15 minutos.
- **Alternativas descartadas.**
  - `afterInstallInitialize` da reversión ante un fallo, pero **sigue** borrando el servicio: no cierra L-02.
  - Una acción personalizada que respalde y restaure `Environment` metería secretos en una acción del MSI y en su registro.
  - «Reconfigurar siempre con los verbos después de actualizar» como único control no cierra el agravante de A7 y depende de que el técnico no se lo salte.
- **Condición de un componente de servicio ya existente** [I]. Con `afterInstallExecute`, la v2 encuentra el servicio creado. Windows Installer lo reconfigura (`ChangeServiceConfig`); según mi lectura, no falla. Eso reaplica `Start`, la cuenta, los argumentos y el SDDL de `MsiLockPermissionsEx`, sin tocar `Environment` ni la DACL de la clave. A2 debe confirmarlo. Ver también H218-09.

## H218-02 (Media, pruebas): `MajorUpgrade` y el GUID del componente del servicio no están fijados

- C01 (sin `MajorUpgrade`), C02 (`AllowDowngrades="yes"`) y C03 (cambio de calendario) viven contra las 38 pruebas [V].
  - Sin `MajorUpgrade`, una v2 se instala al lado de la v1 o falla al crear el servicio, según el caso [I].
  - Con `AllowDowngrades`, se abre el retroceso que A4 marca como Alta.
- C07: cambiar el GUID de `ProgramaApi` vive [V]. Con el arreglo de H218-01, ese cambio volvería a borrar el servicio en la siguiente actualización.
- **Remediación (unos 30 minutos).**
  - Afirmar `Schedule`, `DowngradeErrorMessage` y la ausencia de `AllowDowngrades` y `AllowSameVersionUpgrades` (salvo que se decida H218-03 de otro modo).
  - Fijar los cuatro GUID propios del paquete (`ProgramaApi`, `DatosApi`, `OrigenEventosApi` y `OrigenInstalacion`) como constantes de la prueba, igual que `RaizGposNg` fija los suyos con el vector v3.

## H218-03 (Media): versión 1.0.0 por omisión y compilaciones de la misma versión

- **Riesgo.**
  - `GPOS.Api.csproj` no declara `Version` y no hay `Directory.Build.props` [V]. Sin `-Version`, el `.exe` sale como 1.0.0.0 y el MSI como **1.0.0** (`!(bind.FileVersion.ApiExe)`) [I].
  - Cada compilación genera un `ProductCode` nuevo [I], y `MajorUpgrade` no detecta la misma versión (sin `AllowSameVersionUpgrades`) [I]. Una segunda compilación con la misma versión **se instala junto a la primera**: dos entradas «GPOS NG API», componentes compartidos con contador, y una desinstalación que no quita el servicio.
  - Peor: las `GPOS*.dll` de la segunda llevan la misma versión de archivo, así que, por las reglas de versión, **no reemplazan** a las instaladas. Una corrección construida sin subir la versión no llega al equipo, y no hay error.
  - `construir.ps1` acepta `-Firmar` sin `-Version` (`:23`, `:41-46`), así que se puede firmar un MSI distribuible 1.0.0 repetido.
- **Evidencia.**
  - `construir.ps1:41-46` [V], `GPOS.Api.csproj` [V].
  - Conducta de `FindRelatedProducts`: [I].
  - Mi caso A6 instala **el mismo archivo** (mismo `ProductCode`), así que no mide esto: hace falta un A6b con una **recompilación** de la misma versión.
- **Remediación (unos 30 minutos).**
  - `-Version` obligatorio cuando se usa `-Firmar` (y, mejor, siempre), más una prueba textual.
  - Alternativa más débil: `AllowSameVersionUpgrades="yes"`. La descarto como único control, porque Windows Installer ignora el cuarto número y no resuelve que las DLL no se reemplacen.

## H218-04 (Baja): `WIX1149` sin comprobación después de construir

- **Riesgo.**
  - El `ServiceConfig` del núcleo (`:60-62`) va a la tabla `MsiServiceConfig`, que procesa `MsiConfigureServices`. El aviso `WIX1149` recuerda que el SDK de Windows Installer la documenta como algo que puede «no funcionar como se espera» [I: texto según el PR; no pude ver el aviso].
  - Si no se aplica:
    - **`RequiredPrivileges`:** el token trae los privilegios por omisión de la cuenta virtual. El servicio lo detecta y se niega a arrancar (`ModoServicioApi.cs:200-201`, 4767): **falla cerrado** [V del código].
    - **`FailureActionsWhen`:** una salida con código distinto de cero no cuenta como fallo y no hay reinicio. Combinado con L-01, la conducta en la VM puede ser cualquiera de las dos.
  - No hay riesgo de confidencialidad; sí de disponibilidad y de diagnóstico.
- **Evidencia.** El PR declara que conserva el aviso y que leyó `MsiLockPermissionsEx`, pero no `MsiServiceConfig` [V del cuerpo del PR]. Ninguna prueba ni ningún guion lee las tablas del `.msi` construido [V].
- **Remediación (cerca de 1 h).**
  - En `construir.ps1`, después de construir y con la misma técnica de solo lectura que `Comprobar-BinarioEnMsi`, comprobar tres cosas:
    - que `MsiServiceConfig` tenga las 2 filas esperadas: privilegios, con `SeChangeNotifyPrivilege`, y la marca de acciones de fallo;
    - que `MsiLockPermissionsEx` tenga el SDDL de Q-5 para `InstalarApi`;
    - que `Wix4ServiceConfig` tenga «reiniciar, reiniciar, …».
  - Que `comprobar-servidor` (PR-V) verifique `sc qprivs` y `sc qfailureflag` como control permanente.
  - En la VM, I3 e I4.
  - Se descarta silenciar el aviso: perdería la señal.

## H218-05 (Baja, informativa): la ACE de BU `0x2008D`

- **Verificado [V].**
  - CC 0x1, LC 0x4, SW 0x8, LO 0x80 y RC 0x20000 suman `0x2008D`.
  - SY y BA: `0xF01FF` (SERVICE_ALL_ACCESS).
  - La prueba lo compara por SID, máscara y tipo de ACE contra el `.wxs`, y D3 la mata.
  - No hay CR (control definido por el usuario), RP, WP, DT ni SD para BU.
- **Observaciones.**
  1. La equivalencia en el **MSI** solo la comprobó B a mano. Lo cubre H218-04.
  2. El SDDL por omisión de un servicio da consulta a IU y SU. Q-5 la da a **BU**, que contiene a Usuarios autentificados y, por lo tanto, también a los inicios de sesión de red [I]. Si el equipo admite el acceso remoto al Administrador de servicios, un usuario autentificado del dominio podría consultar la configuración del servicio (ruta, cuenta, estado), no cambiarla. Q-5 está firmada: lo anoto para el propietario, sin pedir cambio. La alternativa sería `IU` en lugar de `BU`, que es lo más cercano al valor por omisión.
  3. El SDDL lleva solo `D:`. No sé si Windows Installer conserva la SACL de auditoría por omisión del servicio o la vacía [I]. Lo mide I7 (`sc sdshow`).
  4. En la VM, el spike crea el servicio sin el SDDL de Q-5 (`Probar-Spike-Amplio.ps1:112-115`, `sc create` sin `sdset`). Los casos que Q-10 quiere correr dentro del spike (A5, D3 y R2) no miden el SDDL del MSI.

## H218-06 (Baja, pruebas): pruebas que pasan sin probar lo que dice su nombre

- **T1-07** `El_MSI_no_escribe_entorno_del_servicio_ni_red_ni_secretos` (`ApiInstaladorTests.cs:157-172`) solo carga `Package.wxs`. El MSI compila además `ComprobacionCarpetasPrevias.wxs`, que **sí** declara dos `CustomAction` (`:48-50`); y `util:ServiceConfig` y `util:EventSource` se implementan con acciones de la extensión [I]. La afirmación «sin `CustomAction`» y la lista de palabras prohibidas son ciertas de `Package.wxs`, no «del MSI».
  - Remediación: renombrarla («Package.wxs no…»), o extender las palabras prohibidas a los fragmentos compilados y listar las acciones permitidas por nombre.
- **T1-10** (`:374-393`) pasa en vacío, como B declara. Además:
  - solo mira `.cs`, `.ps1` y `.cmd` de `src/GPOS.Migracion` e `instalador/Demo`, y no `.wxs` ni `tests/laboratorio-adr090`, donde el spike sí crea `GPOS.Api` sin Q-5;
  - el `DEMO` no crea servicios (`instalador/Demo/LEEME.md:19`).
  - Cuando PR-V la haga estricta, conviene incluir el spike o excluirlo de forma explícita.
- **Q-5** (`:108-132`): después de `Assert.Equal(SddlServicioQ5, wxs)`, las afirmaciones sobre BU, SY, BA y el conteo de `(A;;` se hacen sobre **la constante**, no sobre el `.wxs`: son tautológicas. No hacen daño (la igualdad ya lo fija todo), pero no aportan.
- **T1-08** (`:202`): la afirmación de que no hay `CreateFolder` en `RaizGposNg` ni en `ConfigGposNg` busca en `Package.wxs`, donde esos componentes no existen: pasa en vacío.

## H218-07 (Baja, pruebas): mutantes vivos del paquete y del guion

Cada uno con su remediación; en total, de 1 a 2 h.

| Mutante | Por qué importa | Afirmación que lo mata |
|---|---|---|
| C10 `util:PermissionEx` de más en `Api\` | Daría control total a Usuarios sobre la carpeta del anillo y la licencia, deshaciendo ADR-77 | Ningún `util:PermissionEx` en el paquete, y exactamente 2 `PermissionEx` del núcleo |
| C05 padre `INSTALLDIR` | S-05: la ruta del ejecutable del servicio se podría redirigir desde la línea de órdenes | Todos los `Directory/@Id` del paquete con minúsculas (hoy solo el hijo `Api`, `:197`) |
| C04 `Files` sin `**` | El MSI sale sin subcarpetas de la publicación; I2 lo vería en la VM, tarde | `Include` termina en `\**` |
| C06 `perUser` | Un servicio en un paquete por usuario | `Scope="perMachine"` |
| C12 no limpiar `publicacion\` | Archivos de una publicación anterior entran en el MSI | Prueba textual del `Remove-Item $publicacion` antes de `dotnet publish` |
| C14 el `catch` no borra el `.msi` | Queda un `GPOS.Api.msi` **sin firma** con el nombre del distribuible | Prueba textual del `Remove-Item` en el `catch` |
| C16 sin borrar `.msi` previos | Con una compilación incremental, `Sort LastWriteTime` (`:94`) podría elegir uno viejo | Prueba textual del borrado previo con `-Firmar` |
| C11 atributos extra en `ServiceInstall` | Informativa | Lista blanca de atributos de `ServiceInstall` |

C15 es equivalente: la línea `construir.ps1:65` es código muerto. Propongo quitarla o comentarla.

## H218-08 (Baja): el origen compartido `GPOS.Instalacion`

- **Riesgo.**
  - El origen lo usan las acciones de O-1 de **todo** MSI que compile el fragmento (`AccionesInstalador.cs:154-160`, «lo crea GPOS.Api.msi»). Lo posee el componente `OrigenInstalacion` de este paquete, con su propio GUID (`Package.wxs:94-97`).
  - En una actualización con el calendario actual, la desinstalación de la v1 lo borra **antes** de que corra O-1 de la v2, y los 4753 a 4755 de esa instalación solo quedan en el registro del MSI [I].
  - Si otro MSI del servidor lo registrara (la ola 5 de reportes) con otro GUID, desinstalar uno lo borraría para el otro [I].
- **Remediación (cerca de 1 h).** Llevar el componente al fragmento común con un GUID canónico fijado por el vector, como `RaizGposNg`. El primer punto se resuelve también con H218-01.

## H218-09 (Media, diseño): `Start="demand"` (propuesta de B para L-04) frente a las actualizaciones

- **Riesgo** [I]. Con cualquier calendario, la v2 reaplica el `ServiceInstall`:
  - con el actual, porque recrea el servicio;
  - con `afterInstallExecute`, porque lo reconfigura (H218-01, condición).
- Si el MSI declara `demand` y la implantación lo pasa a `auto`, **cada actualización lo devuelve a `demand`**. Tras el siguiente reinicio del equipo la API no arranca, y no hay ningún error en la actualización.
- **Remediación (decisión de A y B).** Una de estas:
  - mantener `auto` en el MSI y resolver L-04 con L-01: «reiniciar, reiniciar, ninguna» deja el servicio detenido tras 3 fallos y con su evento;
  - aceptar `demand` y que el procedimiento de actualización ejecute `servicios` siempre después del MSI, con `comprobar-servidor` verificando `START_TYPE`.
- Me inclino por la primera: es más simple y no depende del técnico. Lo mide A1, comparando `sc qc` antes y después.

## H218-10 (Informativa): textos que no son ciertos

- `Package.wxs:25-26` y el PR dicen que el DEMO «crea un servicio con el mismo nombre». El DEMO no instala servicios (`instalador/Demo/LEEME.md:19`) [V]. Que «ServiceInstall falla» si el servicio ya existe es [I] y puede ser falso (H218-01, condición): lo mide N3.
- `Package.wxs:9-10` dice «reiniciar a los 60 s, tres veces», y con L-01 son reinicios sin límite.
- `Package.wxs:27-28` habla de G-PR4 como si `FijarEscuchaPorOmision` todavía existiera (L-05).

# 5. Controles bien implementados [V salvo indicación]

- **Q-5 en el `.wxs`:** igualdad exacta del texto y equivalencia por SID, máscara y tipo de ACE; D3 se detecta. No se usa `util:PermissionEx` en el servicio (`:113`).
- **Privilegios y argumento** salen de las constantes del código (`ModoServicioApi.PrivilegiosDeclarados` y `ArgumentoServicio`), con `OnInstall` y `OnReinstall`. El servicio comprueba su token al arrancar y rechaza privilegios de más (`ModoServicioApi.cs:200-201`): es defensa en profundidad frente a H218-04.
- **`Api\` de datos:** DACL protegida con el SID de la cuenta virtual **calculado** en la prueba (no copiado), máscara Modificar `0x1301bf` sin WRITE_DAC ni WRITE_OWNER, y tres ACE.
- **Sin secretos ni entorno en el paquete;** el MSI no arranca el servicio. `Remove="uninstall"` borra el servicio, y con él su `Environment`, en una desinstalación real: no quedan secretos en el equipo [I].
- **Guarda G-PR4:** falla cerrada, va antes de `Resolver-Firma` y de publicar, y está cubierta por los casos sintéticos y la mutación del archivo real (G1 a G4 mueren). `Resolver-Firma` falla sin `signtool` ni huella antes de tocar nada (`Firma-Instalador.ps1:11-20`).
- **Firma (con `-Firmar`):**
  - la `.CA.dll` firmada se compara con la tabla `Binary` antes de firmar el `.msi` (C13 muere por `FragmentosInstaladorTests` T1-04);
  - el `.msi` sin firma válida se borra (aunque C14 no esté fijado);
  - no hay PIN, `.pfx` ni contraseña en el guion.
- **Publicación Release comprobada** (`Comprobar-PublicacionRelease.ps1` lanza ante una publicación sucia).
- **Ids privados** de directorio (el hijo `Api`), `AllowAdvertise="no"`, `Bitness="always64"` en todos los componentes, GUID aleatorios y distintos del `UpgradeCode` del agente.
- **Orígenes de eventos** bajo `[WindowsFolder]`, nunca una propiedad redirigible.

# 6. Remediaciones priorizadas

1. **H218-01 + H218-02:** `Schedule="afterInstallExecute"`, el GUID de `ProgramaApi` fijado y la prueba de `MajorUpgrade`. Unas 3 h más A1, A2 y A7 en la VM. **Antes de unir y antes de cualquier MSI que vaya a un cliente.**
2. **H218-09:** decidir `auto`/`demand` junto con L-01 (Q-3 y Q-7 de B). Es una decisión, no esfuerzo.
3. **H218-03:** `-Version` obligatorio (al menos con `-Firmar`) y un A6b con una recompilación de la misma versión. Unos 30 min.
4. **H218-04:** lectura de `MsiServiceConfig`, `MsiLockPermissionsEx` y `Wix4ServiceConfig` en `construir.ps1`. Cerca de 1 h. Sirve también a mi guion `Get-MsiTabla.ps1` (punto 1 del backlog).
5. **H218-07:** las afirmaciones de la tabla, empezando por C10 y C05. De 1 a 2 h.
6. **H218-06, H218-08 y H218-10:** renombrar o ampliar T1-07, llevar el origen al fragmento común y corregir los comentarios. Cerca de 2 h en total.

# 7. Qué no verifiqué

- Construir el MSI y leer sus tablas: WiX 5.0.2 no está en este equipo y no lo descargué.
- El texto exacto de `WIX1149` y su referencia en el SDK.
- Ejecutar `construir.ps1` de punta a punta: el entorno de C no me dejó lanzar PowerShell desde la consola. Sí se ejecutó a través de las pruebas T1-09 y T1-11.
- Todo lo que exige instalar:
  - el borrado y la recreación del servicio en `MajorUpgrade` (A2);
  - la reversión ante el rechazo de O-1 (A7);
  - si `InstallServices` reconfigura un servicio existente (N3);
  - la SACL tras aplicar el SDDL (I7);
  - si `MsiServiceConfig` se aplica (I3 e I4);
  - el reemplazo de archivos con `afterInstallExecute` (A1 ampliado).

  Todo eso está marcado [I] y lo miden mis casos de `2026-10-23-casos-laboratorio-gpos-api-msi.md`.
- La revisión de seguridad formal del MSI la hace A, aparte.

### Cierre
- Estado: Rechazado (recomendación técnica para unir tal como está; el `-SINFIRMA` sirve para el laboratorio)
- Artefactos:
  - `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-23-revision-adversarial-msi-pr218.md` (este informe, sin commit);
  - guiones y logs de mutación en el scratchpad de la sesión de C (`mut218.sh`, `mut218b.sh`, `mut218c.sh`, `mut218-*.log` y `.diff`, `mut218x-*.log`).
- Supuestos:
  - Conducta de Windows Installer marcada [I]: calendario por omisión de `MajorUpgrade` en WiX 5, transacción aparte de `RemoveExistingProducts` con `afterInstallValidate`, reconfiguración de un servicio existente, `ProductCode` nuevo en cada compilación.
  - Que el apphost toma la versión de archivo del ensamblado (1.0.0.0 sin `-Version`).
- Decisiones candidatas a ADR: Ninguna. El calendario de `MajorUpgrade` y `auto`/`demand` son decisiones de diseño del MSI (blueprint de A), no de arquitectura.
- Entregas a otros agentes:
  - B → H218-01 a H218-04 y H218-07 en la segunda pasada del `.wxs`;
  - A → H218-09 (con Q-3 y Q-7), H218-05.2 (para el propietario, sin pedir cambio de Q-5) y H218-08 en su revisión de seguridad;
  - laboratorio (B) → agregar A6b y ampliar A1 con el `publicacion.sha256`.
- Próximo paso recomendado: B aplica `Schedule="afterInstallExecute"` con el GUID de `ProgramaApi` fijado y la prueba de `MajorUpgrade`, y el laboratorio corre A2 y A7 con ese MSI antes de unir el #218.
