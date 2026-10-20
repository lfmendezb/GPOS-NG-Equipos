# Blueprint de contratos: O-1, O-3 y N-10 del paquete único del servidor (equipo A)

- **Fecha:** 2026-10-20 · **Agente:** arquitecto-software (equipo A) · **Estado del documento:** propuesta técnica. Lo que exige firma queda **Pendiente de firma** del propietario (ver 6).
- **Origen:** diseño v2 del instalador único (`docs/operaciones/2026-10-19-diseno-instalador-reportes.md`, en adelante **INS**) y hoja del tramo 4 (`docs/decisiones/2026-10-20-hoja-firma-ola5-tramo4-e-instalador.md`, en adelante **HOJA**), ambos en `origin/master` (`45a9ab75`).
- **Alcance:** O-1 (acción previa de ADR-77, punto 3), O-3 (componente de la raíz `%ProgramData%\GPOS NG` y de `config\`) y N-10 (privilegios del actualizador para lanzar el *bundle*). **N-1 (modo servicio de `GPOS.Api`) es de B:** aquí solo se anota como dependencia.
- **Método:** todo se leyó con `git show`/`git grep`, sin cambiar de rama ni ejecutar nada. Convención: **[V]** = verificado, con cita `archivo:línea` (rama indicada); **[I]** = inferido, a confirmar al construir o en el laboratorio.
- **Unidades:** esfuerzo en días-persona (dp), con ±50 %. Supuesto para comparar con INS y ADR-77, que usan sp: 1 sp ≈ 5 dp [I].

---

## 0. Hallazgos previos que cambian el planteamiento

| # | Hallazgo | Evidencia | Severidad | Efecto |
|---|---|---|---|---|
| H-1 | **N-10 ya tiene firmado el principio (a)** desde el 2026-10-20: actualización automática; el agente sin privilegios descarga y una tarea elevada fija **vuelve a verificar** el manifiesto, el SHA-256 y Authenticode antes de ejecutar el único archivo. Aquí no se reabre (a) frente a (b): se diseña el contrato de (a) y se deja (b) como modo de reserva. | [V] `docs/adr/ADR-063.md:36`; `docs/adr/ADR-076.md:44`; HOJA:331-349 (B-6 firmado) | — | Ver 3 |
| H-2 | **La raíz ya tiene dos GUID de componente distintos** en dos MSI existentes: el conector IQ usa `9E7A0D3C-1F42-4B6E-8C5D-0A1B2C3D4E5F` y el agente de impresión (estación) usa `0D4B8E27-6A13-4F9C-B852-7E1A9C3D6F20` para la misma carpeta y con el mismo SDDL. Rompe las reglas de componentes de Windows Installer: hoy es benigno porque el SDDL es idéntico y la carpeta solo se borra vacía [I], pero no es el diseño que pide INS. | [V] `GPOS-NG-AddOn-IQS`, `origin/b/conector-iq-instalador`: `instalador/GPOS.Conector.Iq.Instalador/Package.wxs:181-183`; [V] `GPOS-NG`, `origin/feature/modelo-ng`: `instalador/AgenteImpresion/Package.wxs:120-124` | Media | Ver 2 |
| H-3 | **Ya no son tres MSI, sino hasta seis** que comparten la raíz en un servidor: `GPOS.Api.msi`, `GPOS.Reportes.msi`, `GPOS.Web.msi` (N-4, firmado: la Web va como servicio y es el tercer MSI), el agente o estación de impresión y los conectores IQ y AdmCloud, que están en otros repositorios. | [V] HOJA:48 (N-4 confirmado); INS:404 | — | Refuerza el fragmento compartido y el GUID publicado en el vector |
| H-4 | **Puede crearse una raíz sin proteger antes de cualquier MSI.** La cadena de Burn ejecuta `GPOS.Migracion … --fase esquema` **antes** de los MSI (INS:35 y :123), y `CarpetaAnillo.Crear` crea los padres con `Directory.CreateDirectory(padre)`, que hereda la DACL de `%ProgramData%` (Usuarios puede crear). El registro del *bundle* también se escribe en `%ProgramData%\GPOS NG\Instalacion\` (INS:69), y Burn lo crea antes de lanzar el primer paquete [I]. Si la raíz no existía, queda creada por un administrador con escritores heredados (`BUILTIN\Users`): la acción previa del primer MSI la rechaza con `ESCRITOR_NO_PERMITIDO` y **toda instalación nueva falla con 1603** [I]. Si la acción no existiera, la raíz quedaría débil. | [V] `origin/feature/modelo-ng`: `src/GPOS.Core/Infraestructura/Anillo/CarpetaAnillo.cs:39-42`; [V] INS:35, :69, :123 | **Alta** | Contrato C-O1-5 (ver 1.4) |
| H-5 | **El EventId 4742 ya está tomado:** `ModuloVenceIgnorado`, en la rama de A `a/dv07-formato-licencia`. ADR-82 lo daba como «siguiente libre». Este documento propone empezar en el **4743**. | [V] `origin/a/dv07-formato-licencia`: `src/GPOS.Core/Sistema/Licencia/EstadoLicenciaService.cs:145`; [V] `docs/adr/ADR-082.md:220` | Media | Ver 4 |
| H-6 | **La actualización automática choca con D-09 de ADR-82.** `GPOS.Migracion` corre con la identidad nominal de Windows del técnico, y `gpos_esquema` está aplazado. Una tarea elevada (SYSTEM) que ejecuta el *bundle* lanzaría los pasos SQL de la cadena (esquema, credenciales, `verificar`) con `NT AUTHORITY\SYSTEM`, que no tiene esos permisos ni debe tenerlos [I]. | [V] `docs/adr/ADR-082.md:48`, `:91`; INS:134 (autenticación integrada del administrador que instala) | **Alta** | Ver 3.3 (modo híbrido) |
| H-7 | **Discrepancia de asignación:** la tabla de pendientes de HOJA asigna «N-1 (resto): lista de privilegios de `NT SERVICE\GPOS.Api`» al **arquitecto-software de A y devops**. El encargo de esta tarea dice que N-1 es de B. | [V] HOJA:491 y :594 | Baja | Pregunta Q-7 |

---

## 1. O-1 · Acción previa de ADR-77, punto 3

### 1.1 Decisión recomendada

1. **Qué es:** una sola acción personalizada **compartida por todos los MSI del núcleo** que crean carpetas bajo `%ProgramData%\GPOS NG`: Api, Reportes, Web y agente o estación de impresión. Es diferida, sin suplantación (corre como SYSTEM) y se programa **después de `InstallInitialize` y antes de `CreateFolders`**. Aplica el bloque `comprobacionPrevia` del vector v2 tal como está escrito.
2. **Forma:** WiX DTF en C# (.NET Framework 4.7.2, igual que el conector IQ), empaquetada con SfxCA en una `.CA.dll` firmada. El esquema WiX va en un **fragmento fuente compartido** que cada `.wixproj` incluye con `<Compile Include>`. No se usa `.wixlib` ni `.msm` (ver 2).
3. **Dónde vive** (repositorio `GPOS-NG`):
   - `instalador/Comun/GPOS.Instalador.Acciones/GPOS.Instalador.Acciones.csproj`: el proyecto DTF;
   - `instalador/Comun/GPOS.Instalador.Acciones/ComprobacionCarpetasPrevias.cs`: la lógica, sin dependencia de DTF, para que también la compilen las pruebas;
   - `instalador/Comun/Fragmentos/ComprobacionCarpetasPrevias.wxs`: `Binary`, las dos `CustomAction`, la tabla propia, el mensaje `Error` y la secuencia;
   - `instalador/Comun/Fragmentos/RaizGposNg.wxs`: los componentes de O-3.
4. **Quién la construye:** el **desarrollador del equipo A**, porque es la implementación general que ADR-77 asigna a A: «instalador de la API: 0,1» dentro de los 0,43 sp de A [V] `docs/adr/ADR-077.md:57-59`. Cada dueño de MSI la enchufa en el suyo: devops o B en Api, Reportes y Web; A en el agente de impresión.
5. **Punto de partida:** se porta la implementación ya probada del conector IQ (`AccionesInstalador.cs`, `ComprobacionCarpetas.cs`, 390 líneas, error 25001, 19 de 19 vectores v2) [V] `GPOS-NG-AddOn-IQS`, `origin/b/conector-iq-instalador`: `instalador/GPOS.Conector.Iq.Instalador.Acciones/AccionesInstalador.cs:15-88`, `…Acciones.csproj:16,28`; el 19/19 sale del mensaje del *commit* `222a3b2`. Se agregan R-5 (las ACE que no se pueden evaluar cuentan como escritor ajeno) y la lectura por el mismo identificador (`comoLee`). **No** se toma la DLL del repositorio del conector: el núcleo no depende de un complemento (ADR-73, 73.7). Las dos implementaciones se mantienen equivalentes con el mismo vector.
6. **Condición de firma (ya firmada en B-1):** «el *bundle* no se firma ni se publica sin la acción previa» [V] HOJA:241. Se aplica con una guarda en `construir.ps1 -Firmar` de cada MSI y en el del *bundle* (prueba P-O1-6).

### 1.2 ¿Exige excepción a la regla de proyectos nuevos? **Sí.**

- **Regla [V]:** `CLAUDE.md:24` (`master`): «el blueprint de H0 (4.2) admite solo `GPOS.Migracion`», con excepciones nominales (`GPOS.Criptografia`, `GPOS.Comun`, `GPOS.Reportes`, `GPOS.Reportes.Api`, `tests/GPOS.Reportes.Tests` e `instalador/Reportes`). La excepción de la ola 5 nombra expresamente un instalador, `instalador/Reportes` [V] (misma línea; ADR-109:43). Por eso se infiere que **los proyectos de instalador cuentan** como proyectos nuevos [I].
- **Por qué no cabe en un proyecto existente:**
  - una acción DTF de WiX 5 tiene que ser de .NET Framework [I, conocido de WiX 5; el conector IQ usa `net472`, V];
  - todos los proyectos de `src` son `net10.0` [V] `src/GPOS.Comun/GPOS.Comun.csproj:4` (`feature/modelo-ng`).
- **Alternativas descartadas:**
  - **PowerShell:** ADR-77 lo descarta [V] `docs/adr/ADR-077.md:48`.
  - **Una acción de tipo EXE que llame a `GPOS.Migracion.exe comprobar-carpetas`:** el EXE no está instalado cuando corre la acción (`InstallFiles` va después de `CreateFolders`). Habría que meterlo en la tabla `Binary` de cada MSI (decenas de MB, autocontenido [I]), y se ejecutaría como SYSTEM, dentro del MSI, una herramienta capaz de hacer SQL privilegiado, contra el espíritu de ADR-44 y de B-1.
  - **Una acción nativa en C++:** otro tipo de proyecto (`vcxproj`), más riesgo de memoria y ninguna reutilización.
  - **Reutilizar la DLL del conector IQ:** dependencia invertida del núcleo hacia un complemento.
  - **Comprobar solo desde el *bundle*** (un `ExePackage` previo): no protege un MSI instalado por separado (el agente en las estaciones, la reparación de un MSI desde la caché) y no cumple la letra de ADR-77, punto 3 («acción diferida y sin suplantación del MSI»).
- **Alcance de la excepción que se pide (Pendiente de firma, F-1):**
  - un proyecto `instalador/Comun/GPOS.Instalador.Acciones` (`net472`, `WixToolset.Dtf.CustomAction` y `WixToolset.Dtf.WindowsInstaller` 5.0.2, lo mismo que IQ);
  - **fuera de `GPOS-NG.slnx`**, para que la solución siga siendo solo `net10.0`; lo compila el `construir.ps1` de cada instalador, como hace IQ [V] `…Acciones.csproj:10-13`;
  - sin referencias desde `src`;
  - sus pruebas van en `GPOS.Tests`, con el archivo de lógica vinculado: no se crea un proyecto de pruebas nuevo.
- **Costo:** USD 0 de licencias. Es una DLL más que firmar (ADR-77:66, ADR-33).
- **Aviso para B y devops:** los `.wixproj` de `GPOS.Api.msi`, `GPOS.Web.msi` y del *bundle* también son proyectos nuevos, y ADR-109:113 dice que «no se fija aquí el nombre del proyecto del paquete». Conviene que la misma firma F-1 los nombre (Q-1).

### 1.3 Contrato de la acción

**Piezas WiX** (en el fragmento compartido; la sintaxis exacta de `CustomTable` en WiX 5 es [I] y se comprueba al compilar):

| Pieza | Valor |
|---|---|
| Tabla propia `GposCarpetaPrevia` | Columnas: `Id` (clave), `Directorio` (referencia a `Directory`), `Servicio` (texto, puede ser nulo: nombre del servicio de Windows cuya cuenta virtual `NT SERVICE\<Servicio>` es escritora admitida en esa carpeta), `CrearSiFalta` (0 o 1; **solo** la fila de la raíz lleva 1), `Orden` (entero; de padres a hijos) |
| Acción inmediata `GposPrepararCarpetasPrevias` | Lee la tabla, resuelve cada `[Directorio]` y fija `CustomActionData` de la diferida. Secuencia: `Before="InstallInitialize"`, condición `NOT REMOVE~="ALL"` |
| Acción diferida `GposComprobarCarpetasPrevias` | `Execute="deferred"`, `Impersonate="no"`, `Return="check"`. Secuencia: `After="InstallInitialize"`, antes de `StopServices`, `CreateFolders` e `InstallFiles`. Condición `NOT REMOVE~="ALL"`: corre en la instalación, la reparación y la actualización mayor, y no en la desinstalación |
| Mensaje de error | `Error Id="25101"`: «GPOS NG no se instaló: la carpeta [2] no es segura ([3]). No se cambió nada. Ver el procedimiento de operaciones, sección «Carpeta insegura».» Se eligió el 25101 para no confundirlo en soporte con los 25001 a 25003 del conector IQ [V] `…Iq.Instalador/Package.wxs:108-110` |
| Por qué la tabla y no `SetProperty` | Con hasta 6 MSI y los SID de cada servicio, la cadena de `SetProperty` pasaría del límite de 255 caracteres de `CustomAction.Target` que documentó IQ (ICE03) [V] `…Iq.Instalador/Package.wxs:104`. **Alternativa descartada:** `SetProperty` como en IQ, válida si un MSI declara pocas carpetas; queda como reserva si `CustomTable` diera problemas en WiX 5 |

**Entradas:**
- las filas de `GposCarpetaPrevia` del MSI. **Toda** carpeta bajo `CommonAppDataFolder` que el MSI declara con `CreateFolder` lleva su fila (prueba P-O1-3). Las carpetas que crea el servicio en tiempo de ejecución no se declaran ni se comprueban aquí (P-77-4, condición 4; vector `noDeclara`);
- el SID de cada `Servicio` se **calcula** a partir del nombre (S-1-5-80 más el SHA-1 del nombre en mayúsculas), como `CuentaServicioVirtual.Sid` y como admite la nota (a) de ADR-77 [V] `docs/adr/ADR-077.md:105`. Ningún SID se escribe a mano.

**Reglas** (exactamente las del vector v2, sin el dueño adicional de P-77-4, que no rige en el MSI [V] `docs/adr/ADR-077.md:91`):
- de padres a hijos;
- se lee del mismo identificador, abierto sin seguir el punto de reanálisis;
- dueños admitidos: SYSTEM, Administradores y TrustedInstaller;
- escritores admitidos: esos tres más la cuenta de `Servicio` en su fila;
- `CREATOR OWNER` no cuenta como escritor;
- una DACL nula o una ACE que no se puede evaluar cuentan como escritor ajeno;
- **nunca limpia ni cambia el dueño.**

**Creación de la raíz:** si falta la carpeta con `CrearSiFalta=1`, se crea en una sola llamada (`CreateDirectory` con `SECURITY_ATTRIBUTES` construidos desde `raiz.sddl` del vector [V] `adr077-carpetas.v2.json:29`).
- Si la llamada falla con `ERROR_ALREADY_EXISTS` (carrera), la carpeta se comprueba como existente.
- Cualquier otro fallo es `SEGURIDAD_ILEGIBLE`.

**Salidas:**

| Resultado | Qué devuelve | Efecto |
|---|---|---|
| Todo seguro o inexistente | `ActionResult.Success` | La instalación sigue |
| Rechazo | Mensaje 25101 con [2] = ruta y [3] = `PUNTO_DE_REANALISIS` / `NO_ES_CARPETA` / `DUENO_NO_PERMITIDO` / `ESCRITOR_NO_PERMITIDO` / `SEGURIDAD_ILEGIBLE`; `ActionResult.Failure` | **1603**. Windows Installer revierte la instalación sin haber tocado carpetas ni DACL. Dentro del *bundle*, Burn revierte el límite de reversión y el *bundle* sale con 1603 [I] |
| Excepción inesperada | Igual que `SEGURIDAD_ILEGIBLE` (falla cerrada, vector `fallaCerrada`) | 1603 |

**Registro:** una línea por carpeta en el registro del MSI, con el prefijo `GposComprobarCarpetasPrevias:`. Contiene la ruta, el código y el SID culpable. Los SID no son secretos; nunca se registran valores de propiedades.

**Eventos:** origen `GPOS.Instalacion`, registro «Aplicación»:
- la acción **solo escribe el evento si el origen ya existe**. Nunca lo crea, porque eso dejaría una clave de registro fuera del control del MSI. En una instalación nueva queda solo el registro del MSI y de Burn; en una reinstalación o actualización, que es donde una raíz plantada es más probable, queda además el evento;
- EventId en 4.

**Errores SQL:** ninguno, porque la acción no toca SQL. Si alguna pieza de este documento llegara a necesitarlos, quedarían fuera de 51618 a 51644.

### 1.4 Contrato con los pasos de la cadena que corren antes del primer MSI (por H-4)

**C-O1-5 (para B y devops):** ningún paso del *bundle* anterior al primer `MsiPackage` crea nada bajo `%ProgramData%\GPOS NG`. Se cumple de una de estas dos formas:
- **(a, recomendada)** el primer elemento de la cadena es un MSI del núcleo (por ejemplo, `GPOS.Api.msi`), que crea la raíz protegida con su acción previa;
  - los pasos `--fase esquema` que necesiten el anillo de `GPOS.Migracion` van después de él, o
  - `GPOS.Migracion` crea sus carpetas con una función compartida que hace lo mismo que la acción: comprobar y, si falta, crear la raíz en una sola llamada;
  - en cualquier caso, `CarpetaAnillo.Crear` deja de crear padres con DACL heredada fuera de la carpeta del componente (P-77-2);
- **(b)** el registro de Burn queda en su carpeta por omisión (`%TEMP%` de quien instala) y `comprobar-servidor` copia el registro consolidado a `Instalacion\` al final, cuando la raíz ya existe protegida.

La recomendación es (a) junto con (b) para el registro. Esto reordena INS 1.1 y 3.1, que deciden B y devops (Q-2). Si no se hace, la primera instalación limpia falla con 1603 (si existe la acción) o deja la raíz débil (si no existe).

### 1.5 Pruebas requeridas (O-1)

| ID | Prueba | Tipo |
|---|---|---|
| P-O1-1 | La lógica contra los 19 casos del vector v2 (como IQ), más R-5 (ACE compuesta o desconocida: escritor ajeno) y `CREATOR GROUP` y `OWNER RIGHTS` como escritores no admitidos. Lista blanca inyectable para no necesitar elevación | Unitaria en `GPOS.Tests` (archivo vinculado) |
| P-O1-2 | Uniones y vínculos reales: `mklink /J` no exige elevación [I], así que se puede probar `PUNTO_DE_REANALISIS` sin elevación; `NO_ES_CARPETA` con un archivo | Unitaria con carpetas temporales |
| P-O1-3 | Arquitectura: en cada `Package.wxs` del núcleo, toda carpeta bajo `CommonAppDataFolder` con `CreateFolder` tiene su fila en `GposCarpetaPrevia`; solo la raíz lleva `CrearSiFalta=1`; la acción está programada después de `InstallInitialize` y antes de `CreateFolders`, con `Impersonate="no"` | Lectura de `.wxs` (estilo `EstacionInstaladorTests`) |
| P-O1-4 | El SDDL de creación de la raíz es igual a `raiz.sddl` del vector, comparado por SHA-256 del vector | Unitaria |
| P-O1-5 | El SID calculado de `GPOS.Api`, `GPOS.Reportes`, `GPOS.Web` y `GPOS.EstacionImpresion` coincide con `sc showsid` (constantes de prueba) | Unitaria |
| P-O1-6 | `construir.ps1 -Firmar` falla si el `.wxs` no incluye el fragmento o si la `.CA.dll` no verifica con `signtool verify /pa /tw` | Análisis del guion (`Parser::ParseFile`) más una prueba de la guarda |
| P-O1-7 | Laboratorio elevado (una persona, máquina virtual): raíz plantada por un usuario, unión plantada, dueño ajeno y escritor ajeno, cada uno → 1603 sin cambios; raíz ausente → se crea con el SDDL exacto (`icacls`) | Manual, QA y devops |
| P-O1-8 | Cadena del *bundle* con la raíz ausente: la primera instalación limpia termina bien (cubre H-4) | Manual, laboratorio |

### 1.6 Esfuerzo (A, ±50 %)

| Partida | dp |
|---|---|
| Proyecto DTF y puerto de la lógica de IQ con R-5 y `comoLee` | 1,5 |
| Fragmento WiX (tabla, dos acciones, `Error`, secuencia) y guarda de `construir.ps1` | 0,5 |
| Pruebas P-O1-1 a P-O1-6 | 1,0 |
| Enchufarla en el MSI del agente o estación (quita el bloqueo K1-02 [V] `instalador/AgenteImpresion/Package.wxs:25-30, :151-152`) | 0,25 |
| Procedimiento de operaciones («Carpeta insegura») | 0,25 |
| **Total de A** | **3,5 dp** (1,75 a 5,25) |
| Fuera del total: enchufarla en Api, Reportes y Web (devops o B) | unos 0,1 dp por MSI |
| Fuera del total: laboratorio P-O1-7 y P-O1-8 (QA o devops) | 1 dp |

---

## 2. O-3 · Quién declara la raíz `%ProgramData%\GPOS NG` y `config\`

### 2.1 Decisión recomendada

1. **Ningún MSI es «dueño» de la raíz.** Todos los MSI del núcleo declaran los mismos componentes, **byte a byte**, porque incluyen el mismo archivo fuente `instalador/Comun/Fragmentos/RaizGposNg.wxs`. Windows Installer cuenta las referencias por GUID, así que la raíz persiste mientras quede algún cliente.
2. **Un solo GUID canónico por componente, publicado en el vector de ADR-77** (punto 6, «una sola definición»). Se agrega de forma aditiva en una v3 del vector (`componentesCompartidos`), para que los repositorios de los conectores comparen su constante con una prueba, como ya hacen con el SDDL.
3. **`Permanent="yes"`** en los dos componentes. Desinstalar todo nunca quita la raíz ni `config\` (coherente con INS 6, «conserva siempre `%ProgramData%\GPOS NG` completo» [V] INS:242). Además evita que, tras una desinstalación completa, un usuario recree la raíz y bloquee la reinstalación.
4. **No se usa `.msm` ahora.** Si algún día hay que distribuir el fragmento a otros repositorios (AdmCloud, Polaris), se usa **`.wixlib`** dentro de `GPOS.AddOn.Kit`, no `.msm` (ver 2.3).

### 2.2 Contrato de los componentes

| Componente | `Directory` (Id fijo) | GUID canónico | Contenido | Atributos |
|---|---|---|---|---|
| `RaizGposNg` | `DirGposNgDatos` = `CommonAppDataFolder\GPOS NG` | `9E7A0D3C-1F42-4B6E-8C5D-0A1B2C3D4E5F` (el del conector IQ, que es el único MSI con la raíz instalado fuera del desarrollo [V] `…Iq.Instalador/Package.wxs:181`; elegirlo evita cambiar un componente ya instalado en pruebas) | `CreateFolder` + `PermissionEx Sddl="O:SYG:SYD:PAI(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICI;0x1200a9;;;AU)"` (vector `raiz.sddl`) | `Permanent="yes"`, `Bitness="always64"` |
| `ConfigGposNg` | `DirGposNgConfig` = `…\GPOS NG\config` | `0B21B6DB-0F32-4111-AF3D-12630EB877C3` (nuevo; generado para este contrato) | `CreateFolder` + `PermissionEx` con el **mismo SDDL de la raíz**, explícito y protegido: escriben solo SYSTEM y Administradores; leen los procesos (lee `ArchivoInstalacion`, `%ProgramData%\GPOS NG\config\<proceso>.json`) [V] `origin/feature/modelo-ng`: `src/GPOS.Comun/Configuracion/ArchivoInstalacion.cs:29-36` | `Permanent="yes"`, `Bitness="always64"` |

**Reglas del contrato:**
- **R-O3-1.** Lo incluyen todos los MSI del núcleo que escriben o leen bajo la raíz: Api, Reportes, Web y agente o estación.
- **R-O3-2.** Cada MSI declara además **solo** su carpeta de componente (ADR-77, punto 5), con su fila en `GposCarpetaPrevia`.
- **R-O3-3.** El agente de impresión cambia el GUID de su `DatosGposNg` (`0D4B8E27-…`) por el canónico. No rompe nada: esa *feature* solo existe en la compilación de desarrollo [V] `instalador/AgenteImpresion/Package.wxs:92`.
- **R-O3-4.** El conector IQ conserva su GUID (ya es el canónico) y agrega `Permanent="yes"` en su próxima versión. El conector AdmCloud adopta el mismo GUID. Las dos tareas son de B, en sus repositorios (Q-3).
- **R-O3-5.** **`config\` no lleva escritor de servicio:** ningún proceso escribe allí; solo leen. **Alternativa descartada:** dar lectura solo a los SID de los servicios en lugar de a AU. Acopla `config\` a la lista de servicios y obliga a cambiar el GUID o el contenido en cada servicio nuevo, sin una ganancia clara: el archivo no admite secretos por construcción (lista blanca `GPOS:RncDgii`, B-7 firmado) [V] `ArchivoInstalacion.cs:27`.

### 2.3 Alternativas evaluadas

| Opción | Ventajas | Contras | Veredicto |
|---|---|---|---|
| **Fragmento fuente compartido + GUID en el vector (recomendada)** | Contenido idéntico garantizado en el núcleo (un archivo); sin proyecto extra; la prueba del vector cubre los otros repositorios | Los conectores mantienen su copia (se controla con la prueba) | Elegida |
| `.msm` (módulo de combinación) | Una sola pieza binaria | Otro proyecto WiX (otra excepción a `CLAUDE.md:24`); modularización de identificadores; el `.msm` no se firma por sí mismo [I]; habría que consumir un binario del núcleo desde los complementos | Descartada |
| `.wixlib` | Es la forma recomendada por WiX para compartir fragmentos con binarios [I]; podría viajar en `GPOS.AddOn.Kit` | Otro proyecto; hoy no hace falta (el núcleo comparte por fuente) | **Reserva:** si la deriva entre repositorios aparece en la prueba del vector |
| Un solo MSI (Api) declara la raíz | Simple | El agente y los conectores se instalan sin la Api; el orden de la cadena importaría; si se desinstala la Api, la raíz queda sin dueño | Descartada |
| Que ningún MSI la declare (solo la crea la acción) | Mínimo | La reparación no restaura la DACL; `config\` quedaría sin dueño | Descartada |

### 2.4 Pruebas requeridas (O-3)

| ID | Prueba |
|---|---|
| P-O3-1 | Todo `Package.wxs` del núcleo que tiene `CommonAppDataFolder` incluye `RaizGposNg.wxs`; ningún otro componente apunta a `DirGposNgDatos` ni a `DirGposNgConfig` |
| P-O3-2 | Los GUID y el SDDL de `RaizGposNg.wxs` son iguales a los de `componentesCompartidos` del vector v3, comparado por SHA-256 |
| P-O3-3 | Los dos componentes tienen `Permanent="yes"` y ninguna `RemoveFolder` ni `RemoveFile` sobre esas carpetas |
| P-O3-4 | Laboratorio: instalar Reportes y Api, desinstalar Reportes → raíz y `config\` intactos con el SDDL exacto; desinstalar todo → siguen ahí; reinstalar → la acción previa pasa |
| P-O3-5 | (B, repositorios de los conectores) Su prueba del vector compara el GUID canónico |

### 2.5 Esfuerzo (A, ±50 %)

| Partida | dp |
|---|---|
| Fragmento `RaizGposNg.wxs` | 0,25 |
| Vector v3 (aditivo; lo publica el documentador) y pruebas P-O3-1 a P-O3-3 | 0,5 |
| Cambio de GUID en el agente | 0,1 |
| **Total de A** | **0,85 dp** (0,4 a 1,3) |
| Fuera del total: B en IQ y AdmCloud | unos 0,25 dp por conector |

---

## 3. N-10 · Privilegios del agente de actualización para lanzar el *bundle* elevado

### 3.1 Decisión recomendada

**(a), como ya se firmó** [V] ADR-063.md:36, con el contrato de abajo. **(b)** (que el técnico confirme cada actualización) no se descarta: queda como **modo de reserva**, para:
- las versiones que exigen técnico (ver 3.3);
- los sitios donde el propietario lo elija;
- el período en que el agente no exista (ya previsto: «el técnico ejecuta el *bundle* a mano»).

**Comparación de las dos opciones:**

| Criterio | (a) Tarea elevada fija solo para el archivo firmado | (b) Confirmación del técnico |
|---|---|---|
| Cumple la publicación continua (memoria «actualización automática», ADR-63) | Sí | No: depende de una visita o de una sesión remota |
| Superficie de ataque | Un componente SYSTEM que procesa archivos descargados (el manifiesto JWS y el ejecutable). Se mitiga con una nueva verificación sobre una copia en una carpeta SYSTEM-only, sin argumentos del lado sin privilegios, un solo archivo y un solo firmante esperado | Mínima: la persona eleva con UAC |
| Riesgo operativo | Parar la venta a mitad de turno → hace falta una ventana de mantenimiento (Q-5) | Sin parada sorpresa, pero se acumulan versiones sin aplicar (y parches de seguridad) |
| Compatibilidad con D-09 de ADR-82 (H-6) | **No** para las versiones con cambios de esquema → modo híbrido (3.3) | Sí |
| Costo de construcción | 7 a 8 dp (3.6) | unos 1 dp (aviso y botón; ya cubierto por el procedimiento manual) |

### 3.2 Arquitectura y contrato

**Componentes:**
- **`GPOS.Actualizador`** (lado sin privilegios):
  - servicio de Windows con la cuenta virtual `NT SERVICE\GPOS.Actualizador` y `RequiredPrivilege` = **solo `SeChangeNotifyPrivilege`** (ADR-76 con PA-76-1), con la autocomprobación `ARRANQUE_PRIVILEGIOS`;
  - consulta el manifiesto, descarga y verifica por primera vez. No ejecuta nada;
  - salida HTTPS solo hacia el origen del manifiesto. Es la pista aparte de ADR-63 y no se diseña aquí.
- **Lado elevado: el mismo binario firmado en modo `aplicar`**, para no crear un segundo proyecto. Lo lanza **un servicio de Windows de inicio a demanda** como `LocalSystem`, `GPOS.Actualizador.Aplicar`, que **no es residente**: arranca, aplica y se detiene.
  - **Por qué un servicio a demanda y no una tarea programada:**
    - WiX lo declara de forma nativa con `ServiceInstall` y `ServiceConfig`, sin acciones personalizadas; WiX 5 no trae un elemento para tareas programadas [I];
    - el permiso de arranque (`SERVICE_START`) se concede con precisión a `NT SERVICE\GPOS.Actualizador` mediante la DACL del servicio (`PermissionEx` sobre `ServiceInstall` [I]);
    - el Administrador de servicios deja su rastro (7036).
  - Es una «tarea elevada fija» en el sentido de lo firmado. **Alternativa descartada:** una tarea programada como SYSTEM con su descriptor de seguridad. Es equivalente, pero exige una acción personalizada o `schtasks` para registrarla y su ACL es menos visible para el auditor.
  - **Segunda alternativa descartada:** un servicio SYSTEM residente con una canalización de órdenes, que dejaría un servidor SYSTEM permanente que escucha.

**Carpetas** (todas con la acción previa de O-1 y bajo la raíz de O-3):

| Carpeta | DACL protegida | Uso |
|---|---|---|
| `%ProgramData%\GPOS NG\Actualizador\Entrega\` | SY y BA control total; `NT SERVICE\GPOS.Actualizador` Modificar (`0x1301bf`) | El agente deja aquí `manifiesto.jws` y el *bundle* candidato |
| `%ProgramData%\GPOS NG\Actualizador\Aplicar\` | **Solo SY y BA**; sin lectura de AU ni del agente | Copia de trabajo del lado elevado, registros de Burn y los dos últimos *bundles* aplicados (*roll-forward*, O-10) |

**Contrato del modo `aplicar` (lado elevado):**

| Aspecto | Contrato |
|---|---|
| **Entradas** | **Ninguna desde la línea de órdenes ni desde el agente.** Rutas fijas compiladas en el binario, más los valores de `HKLM\SOFTWARE\GPOS NG\Actualizador` (escritura solo de SY y BA): `UltimoSecManifiesto`, `Ventana` y `Modo` (`Automatico` o `Asistido`) |
| **Paso 1. Carpetas** | Comprueba `Entrega\` y `Aplicar\` con las reglas del vector (dueño, escritores, reanálisis) antes de leer nada → si falla, evento 4752 y código 24 |
| **Paso 2. Copia** | Abre cada archivo de `Entrega\` **sin seguir reanálisis** y con `FILE_SHARE_READ` solamente, y lo copia a `Aplicar\`. Desde aquí trabaja solo sobre la copia (cierra la carrera entre comprobar y usar) |
| **Paso 3. Nueva verificación** (no confía en el agente) | (i) Firma JWS del manifiesto con el verificador estricto único de `GPOS.Criptografia` (R-1 de ADR-77 [V] ADR-077.md:76) y con las llaves y la regla INV-3 de ADR-63; (ii) `sec` del manifiesto mayor que `UltimoSecManifiesto` (contra repetición); (iii) la entrada «servidor» declara **un solo archivo** con versión mayor que la instalada (`HKLM\SOFTWARE\GPOS NG\Servidor`); sin degradación → código 23; (iv) SHA-256 de la copia igual al del manifiesto; (v) `WinVerifyTrust` con la cadena válida **y** sujeto, emisor y EKU de firma de código iguales a los esperados del manifiesto (ADR-63, punto 5, con K-06 de ADR-75); (vi) la comparación con el manifiesto anterior que defina el diseño del agente (punto 6). Cada fallo tiene su evento y su código; el archivo se mueve a `Aplicar\rechazados\` |
| **Paso 4. Condiciones** | Dentro de la ventana configurada. Si el manifiesto marca la versión con `requiereTecnico` (3.3), **no se aplica**: evento 4754 y código 31 |
| **Paso 5. Ejecución** | `CreateProcess` (nunca `ShellExecute`) sobre la copia, con argumentos **fijos**: `/quiet /norestart /log "<Aplicar>\registros\<versión>.log"`, más la propiedad del *bundle* `MODO=Automatico` (3.3). Directorio de trabajo `Aplicar\`, entorno mínimo y espera con límite de 60 min [I; medir] |
| **Paso 6. Resultado** | Lee el código de salida del *bundle*: 0 o 3010 → evento 4750 y se actualiza `UltimoSecManifiesto`; otro valor (por ejemplo, 1603 de O-1) → evento 4751 con el código y la ruta del registro. **Nunca reinicia el equipo** (3010 se informa) |
| **Paso 7. Limpieza** | Vacía `Entrega\` y conserva en `Aplicar\` los dos últimos *bundles* aplicados |

**Códigos de salida del modo `aplicar`** (los registra el Administrador de servicios y los lee el agente):

| Código | Significado |
|---|---|
| 0 | Aplicada |
| 3010 | Aplicada; requiere reinicio |
| 10 | No hay nada que aplicar |
| 20 | Manifiesto rechazado |
| 21 | SHA-256 distinto |
| 22 | Authenticode rechazado o firmante inesperado |
| 23 | Degradación o repetición |
| 24 | Carpeta insegura |
| 30 | Fuera de la ventana |
| 31 | La versión exige técnico |
| 40 | El *bundle* falló (su código va en el evento 4751) |
| 1 | Error interno (falla cerrada) |

**Autoactualización del agente:** el agente **no** viaja dentro del *bundle* del servidor, porque el servicio que lanza el *bundle* no puede ser reemplazado por ese mismo *bundle* [I]. Tiene su propia entrada en el manifiesto, y el modo `aplicar` lanza su MSI **desacoplado y termina**. La siguiente ejecución lee el resultado en el registro de Windows Installer y emite el evento 4750 o 4751. Este detalle se cierra en el diseño del agente (Q-6).

**Privilegios (PA-76-1):**
- **lado sin privilegios:** solo `SeChangeNotifyPrivilege` (norma por omisión);
- **lado elevado:** `LocalSystem`. La lista exacta de `RequiredPrivilege` **se mide en el laboratorio**, con `sc qprivs` y una actualización completa del *bundle*, y la revisa el auditor-seguridad.
  - Punto de partida que se propone probar: el mínimo con el que Burn y su motor elevado completan una actualización de máquina, porque el trabajo de los MSI lo hace el servicio `msiserver` con su propio token [I].
  - **Prohibidos de entrada, salvo prueba en contra:** `SeDebugPrivilege`, `SeTcbPrivilege`, `SeImpersonatePrivilege` y `SeAssignPrimaryTokenPrivilege`.
  - Si Burn necesita alguno, se justifica por escrito (ADR-76, punto 2).

### 3.3 Modo híbrido por H-6 (conflicto con D-09 de ADR-82)

1. **Qué marca el manifiesto:** cada versión del servidor declara `requiereTecnico: true|false`. Es `true` si la versión contiene **cualquier** paso con SQL que exija una identidad privilegiada: una migración de esquema, `crear-lectura` o un cambio de sobres. Lo fija la tubería al publicar, comparando las migraciones con las de la versión anterior.
2. **Qué hace cada lado:**
   - con `requiereTecnico: false`, el *bundle* corre en `MODO=Automatico`: **omite los `ExePackage` con SQL** (esquema, credenciales y `verificar`) y la verificación final usa solo comprobaciones locales: R1 a R8, P1 a P7 y K1 a K3, más `/api/salud` de las tres API, que informa si la versión del esquema es compatible;
   - con `requiereTecnico: true`, el lado elevado no aplica la versión: avisa (evento 4754 y aviso en la API) y el técnico ejecuta el *bundle* a mano con su identidad nominal (D-09). Es la opción (b), limitada a esas versiones.
3. **Respaldo previo:** B-5 lo exige antes de **migrar**. En `MODO=Automatico` no hay migración, así que no aplica [I]. Lo confirma el propietario (Q-4).
4. **Alternativas descartadas:**
   - **revivir `gpos_esquema`** con la credencial sellada en la máquina: contradice D-09 sin una firma nueva y crea un secreto más que custodiar;
   - **un login de Windows para la cuenta del lado elevado con permisos de DDL:** convierte el actualizador en una identidad SQL privilegiada permanente;
   - ambas se pueden reabrir si la mayoría de las versiones resulta tener `requiereTecnico: true`. En la fase actual es probable [I]: casi todas las tandas traen migraciones.

### 3.4 Pruebas requeridas (N-10)

| ID | Prueba |
|---|---|
| P-N10-1 | El modo `aplicar` no lee argumentos: con cualquier argumento extra termina con código 1 (prueba unitaria del analizador de órdenes) |
| P-N10-2 | Rechazos: manifiesto mal firmado, `sec` repetido, versión menor, SHA distinto, Authenticode válido de **otro** firmante y archivo sin firma → cada uno con su código y su evento, y nada se ejecuta (ejecutor simulado) |
| P-N10-3 | Carrera: cambiar el archivo de `Entrega\` después de la copia no altera lo que se ejecuta (ejecutor simulado que recibe la ruta de `Aplicar\`) |
| P-N10-4 | `Entrega\` como unión o con un escritor ajeno → código 24 |
| P-N10-5 | `requiereTecnico: true` → código 31 y ninguna ejecución |
| P-N10-6 | Las DACL de `Aplicar\` y `Entrega\` y la DACL del servicio `GPOS.Actualizador.Aplicar` (solo `SERVICE_START` y consulta para el agente) se comparan con constantes (lectura de `.wxs`) |
| P-N10-7 | El *bundle* acepta `MODO=Automatico` y en ese modo la cadena no contiene `ExePackage` con SQL (extiende B-1 y B-4 de INS) |
| P-N10-8 | Laboratorio: actualización completa como SYSTEM y medición de los privilegios mínimos con `sc qprivs`; 1603 forzado (raíz plantada) → evento 4751; 3010 sin reinicio |

### 3.5 Lo que necesita el auditor-seguridad

1. Revisar el contrato del modo `aplicar`: la lista de comprobaciones repetidas, la copia a una carpeta SYSTEM-only y los argumentos fijos.
2. Aprobar o corregir la lista de `RequiredPrivilege` del lado elevado medida en P-N10-8, y la justificación de cada privilegio.
3. Validar la DACL del servicio a demanda: el agente puede arrancarlo, pero no reconfigurarlo (`SERVICE_CHANGE_CONFIG` denegado), y que un agente comprometido no gane nada más allá de forzar una nueva verificación.
4. Evaluar el modo híbrido de 3.3 frente a D-09 y si `MODO=Automatico` debilita la verificación integrada (sin R9 y R10).
5. Evaluar el riesgo residual del parser JWS y de `WinVerifyTrust` corriendo como SYSTEM sobre entradas descargadas, y si conviene una comprobación de revocación en línea.
6. Para O-1: revisar la falla cerrada (`SEGURIDAD_ILEGIBLE`), que la acción nunca limpie, y la DLL de SfxCA firmada por dentro y por fuera (WDAC, AppLocker), como en IQ [V] `…Acciones.csproj:44-55`.

### 3.6 Esfuerzo (±50 %; excluye el agente sin privilegios, que es la pista de ADR-63)

| Partida | dp |
|---|---|
| Modo `aplicar` (pasos 1 a 7, códigos, eventos) | 3,0 |
| Servicio a demanda y sus DACL en el MSI del actualizador | 1,0 |
| `MODO=Automatico` en el *bundle* (B o devops) | 1,0 |
| Pruebas P-N10-1 a P-N10-7 | 2,0 |
| **Total** | **7 dp** (3,5 a 10,5) |
| Fuera del total: laboratorio P-N10-8 (devops o QA) | 1 dp |
| Fuera del total: revisión del auditor | 1 dp |
| Costo de infraestructura | USD 0. Una pieza más que firmar (ADR-33) |

---

## 4. EventId propuestos (origen `GPOS.Instalacion` para O-1 y `GPOS.Actualizador` para N-10)

**Situación:** el 4742 está ocupado (H-5). Se propone **reservar del 4743 al 4756**. Antes de usar cada número se comprueba con `git grep` en todas las ramas de `origin` (regla de ADR-82:220). La reserva la registra el documentador en la nota de ADR-82, coordinada con B, porque N-8 (`GPOS.Instalacion` con 5130 a 5149) es de B y choca con los 5130 a 5133 y 5140 a 5143 de IMP [V] HOJA:495.

| EventId | Nombre | Nivel | Emisor | Datos (sin secretos) |
|---|---|---|---|---|
| 4743 | `CarpetaPreviaRechazada` | Error | Acción de O-1 (si el origen existe) | ruta, código, SID culpable, ProductCode, versión |
| 4744 | `CarpetaPreviaIlegible` | Error | Acción de O-1 | ruta, error de Windows |
| 4745 | `RaizCreadaProtegida` | Información | Acción de O-1 | ruta, SHA-256 del SDDL aplicado |
| 4746 | `ActualizacionCandidata` | Información | Modo `aplicar` | versión y `sec` |
| 4747 | `ActualizacionManifiestoRechazado` | Error | Modo `aplicar` | motivo (firma, INV-3, `sec`) |
| 4748 | `ActualizacionHashDistinto` | Error | Modo `aplicar` | esperado y obtenido |
| 4749 | `ActualizacionFirmaRechazada` | Error | Modo `aplicar` | sujeto, emisor, EKU y resultado de `WinVerifyTrust` |
| 4750 | `ActualizacionAplicada` | Información | Modo `aplicar` | versión, código 0 o 3010, duración |
| 4751 | `ActualizacionFallida` | Error | Modo `aplicar` | código del *bundle* y ruta del registro |
| 4752 | `ActualizacionCarpetaInsegura` | Error | Modo `aplicar` | ruta y código del vector |
| 4753 | `ActualizacionDegradacionRechazada` | Advertencia | Modo `aplicar` | versión instalada y ofrecida |
| 4754 | `ActualizacionRequiereTecnico` | Advertencia | Modo `aplicar` | versión, motivo (`requiereTecnico` o fuera de la ventana) |
| 4755 | `ActualizacionServicioAlterado` | Error | `comprobar-servidor` (comprobación K nueva) | la configuración o la DACL del servicio a demanda no coinciden con lo esperado |
| 4756 | (reserva) | — | — | — |

- **Nota [I]:** en el registro **Seguridad** de Windows, el 4742 al 4756 son eventos de auditoría de cuentas («cuenta de equipo cambiada», etc.). No hay colisión técnica, porque son registro y origen distintos, pero las reglas de alerta del Visor de eventos tienen que filtrar por origen y no solo por número (aviso para devops).
- **Alertas mínimas** (B-8 firmado): 4743, 4744, 4747, 4748, 4749, 4751 y 4752 a 4755.

**Errores SQL:** ninguno en estos tres contratos. Si alguno hiciera falta, se usa la franja libre que fije el arquitecto-datos, **fuera de 51618 a 51644**.

---

## 5. Dependencias (no se diseñan aquí)

- **N-1 (B):** `GPOS.Api` como servicio de Windows. Bloquea `GPOS.Api.msi`, y por tanto el primer MSI de la cadena que, según C-O1-5 (a), crea la raíz. Su lista de privilegios entra en la fila de `GposCarpetaPrevia` solo como nombre de servicio (`GPOS.Api`). Ver H-7.
- **ADR-90 / B-3:** la red y el TLS de la Api y la Web no cambian estos contratos.
- **El agente de actualización** (pista de ADR-63): el lado sin privilegios, el formato del manifiesto (el arquitecto-integraciones agrega `requiereTecnico` y la entrada «servidor» de un solo archivo) y el segundo canal.

---

## 6. Firmas que necesita (Pendientes de firma del propietario)

| # | Qué se firma | Recomendación |
|---|---|---|
| F-1 | Excepción a `CLAUDE.md:24` para `instalador/Comun/GPOS.Instalador.Acciones` (`net472`, fuera de `GPOS-NG.slnx`), como precisión de ADR-77, punto 3. Conviene que nombre en la misma firma los `.wixproj` nuevos del paquete (Api, Web y *bundle*) | Sí |
| F-2 | O-3: fragmento compartido, GUID canónico `9E7A0D3C-…` para la raíz y `0B21B6DB-…` para `config\`, `Permanent="yes"`, GUID publicado en el vector v3 | Sí |
| F-3 | N-10 en detalle: lado elevado como servicio a demanda que reverifica (precisa el principio ya firmado) y **modo híbrido** `requiereTecnico` frente a D-09 | Sí, sujeto a la revisión del auditor |
| F-4 | Reserva de EventId 4743 a 4756 | Sí, coordinada con N-8 de B |

---

## 7. Preguntas abiertas

| # | Para | Pregunta | Recomendación |
|---|---|---|---|
| Q-1 | B, devops y el propietario | ¿Los `.wixproj` de `GPOS.Api.msi`, `GPOS.Web.msi` y del *bundle* entran en la misma excepción F-1? | Sí, nombrados uno por uno |
| Q-2 | B y devops | H-4 / C-O1-5: ¿se reordena la cadena para que el primer elemento sea un MSI del núcleo y el registro de Burn quede fuera de `GPOS NG` hasta el final? | (a) + (b) |
| Q-3 | B | ¿Cuándo alinean IQ (`Permanent="yes"`) y AdmCloud (GUID canónico)? ¿Hay alguna instalación de IQ 0.4.1 fuera del laboratorio? | En la próxima versión de cada conector |
| Q-4 | El propietario | Con `MODO=Automatico` (sin migración), ¿se exige igual el respaldo previo de B-5? | No: B-5 se refiere a migrar |
| Q-5 | El propietario | Ventana de mantenimiento por sitio (por ejemplo, de 02:00 a 05:00) y si debe esperar a que no haya jornadas abiertas | Ventana configurable; jornadas: sí, si la API lo expone sin SQL privilegiado |
| Q-6 | El diseñador del agente (arquitecto-integraciones) | Autoactualización del agente desacoplada (3.2) y formato de `requiereTecnico` en el manifiesto | Entrada propia del agente; bandera booleana firmada |
| Q-7 | B y el coordinador | H-7: ¿quién fija la lista de privilegios de `NT SERVICE\GPOS.Api`, A (HOJA:491) o B (encargo)? | Que lo aclare el coordinador; no bloquea O-1, O-3 ni N-10 |
| Q-8 | B (N-8) | ¿Se adopta 4743 a 4756 en lugar de 5130 a 5149 para `GPOS.Instalacion`, incluidos los eventos de RT-04 de ADR-90? | Sí; deja libre la franja 51xx de reportes |

---

## 8. Riesgos

| Riesgo | Severidad | Mitigación |
|---|---|---|
| H-4: la primera instalación limpia falla, o queda una raíz débil, por un paso previo al MSI | Alta | C-O1-5; P-O1-8 |
| H-6: la actualización automática casi nunca aplica, porque casi todas las versiones migran | Media | Modo híbrido; reabrir `gpos_esquema` con una firma si la medición lo justifica |
| Un componente SYSTEM procesa archivos descargados | Media | Copia a SYSTEM-only, reverificación, argumentos fijos, revisión del auditor |
| Deriva entre las implementaciones de la comprobación de carpetas (IQ MSI, IQ arranque, agente, Reportes y la acción nueva) | Media | Vector común con pruebas en cada repositorio; `.wixlib` como reserva |
| `CustomTable` o `PermissionEx` sobre `ServiceInstall` se comportan distinto en WiX 5 | Baja | Reserva con `SetProperty` (O-1) o tarea programada (N-10); se comprueba al compilar |

---

## Resumen (10 líneas)

1. O-1: hace falta una acción DTF compartida, diferida y sin suplantación (puerto de la de IQ), con el fragmento `instalador/Comun/Fragmentos/ComprobacionCarpetasPrevias.wxs`; la construye el desarrollador de A en unos 3,5 dp.
2. O-1 **sí exige una excepción** a `CLAUDE.md:24` (proyecto `net472` fuera de la solución). No hay alternativa sin proyecto que cumpla ADR-77, punto 3.
3. Contrato de O-1: tabla `GposCarpetaPrevia`, mensaje 25101, salida 1603 y los códigos del vector v2. Nunca limpia; solo crea la raíz si falta.
4. Hallazgo Alto H-4: `GPOS.Migracion` y el registro de Burn pueden crear la raíz sin protegerla antes del primer MSI (`CarpetaAnillo.cs:41`). Hay que reordenar la cadena (C-O1-5).
5. O-3: fragmento fuente compartido con el GUID canónico de IQ (`9E7A0D3C-…`) para la raíz y uno nuevo (`0B21B6DB-…`) para `config\`, `Permanent="yes"` y el GUID publicado en el vector v3. Sin `.msm`.
6. O-3 corrige H-2: el agente y el conector IQ ya usan GUID distintos para la misma raíz. Unos 0,85 dp de A, más el trabajo de B en los conectores.
7. N-10: el principio (a) ya está firmado. Se propone el lado elevado como servicio a demanda que copia a una carpeta SYSTEM-only y reverifica el manifiesto, el SHA-256 y Authenticode, con argumentos fijos. Unos 7 dp.
8. Hallazgo Alto H-6: la actualización automática choca con D-09 de ADR-82 (migración con la identidad del técnico). Se propone un modo híbrido con `requiereTecnico` en el manifiesto.
9. EventId: el 4742 ya está tomado en `a/dv07-formato-licencia`. Se proponen 4743 a 4756 y ningún error SQL; si alguno hiciera falta, fuera de 51618 a 51644.
10. Pendiente de firma: F-1 a F-4. El auditor revisa N-10 (privilegios medidos, DACL del servicio y modo híbrido) y la falla cerrada de O-1.

### Cierre
- Estado: Completado
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\blueprint-instalador-o1-o3-n10-2026-10-20.md`
- Supuestos: 1 sp ≈ 5 dp; la sintaxis de `CustomTable` y de `PermissionEx` sobre `ServiceInstall` en WiX 5, el comportamiento de Burn como SYSTEM y la creación de la carpeta del registro por Burn son inferidos; que los proyectos de instalador cuentan para `CLAUDE.md:24` es inferido de la excepción de ADR-109; el estado del código es el de `origin/master` y `origin/feature/modelo-ng` del 2026-10-20.
- Decisiones candidatas a ADR: precisión de ADR-77, punto 3 (acción compartida, excepción de proyecto, C-O1-5); precisión de ADR-77, punto 6 (GUID de los componentes compartidos en el vector v3); precisión de ADR-63/ADR-76 (lado elevado a demanda y modo híbrido `requiereTecnico` frente a D-09 de ADR-82). Las redacta el arquitecto-maestro.
- Entregas a otros agentes: desarrollador de A → acción y fragmentos; B y devops → C-O1-5, `MODO=Automatico`, Q-1, Q-2, Q-7 y Q-8; B (conectores) → R-O3-4; arquitecto-integraciones → `requiereTecnico` y la entrada del agente en el manifiesto; arquitecto-datos → confirmar que `MODO=Automatico` puede omitir los pasos SQL; auditor-seguridad → 3.5; documentador → vector v3 y reserva de EventId en ADR-82; QA → P-O1-7, P-O1-8, P-O3-4 y P-N10-8.
- Próximo paso recomendado: llevar F-1 a F-4 y Q-2 a la próxima hoja del arquitecto-maestro, y avisar a B de H-4 y H-6 antes de que devops empiece el *bundle*.
