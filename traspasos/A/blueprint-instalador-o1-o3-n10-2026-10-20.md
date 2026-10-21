# Blueprint de contratos: O-1, O-3 y N-10 del paquete único del servidor (equipo A) · v2

- **Fecha:** 2026-10-20 (v1 y v2) · **Agente:** arquitecto-software (equipo A) · **Estado del documento:** propuesta técnica, corregida con las respuestas de B. Lo que exige firma queda **Pendiente de firma** del propietario (ver 6).
- **Origen:** diseño v2 del instalador único (`docs/operaciones/2026-10-19-diseno-instalador-reportes.md`, **INS**) y hoja del tramo 4 (`docs/decisiones/2026-10-20-hoja-firma-ola5-tramo4-e-instalador.md`, **HOJA**), en `origin/master` (v1 leyó `45a9ab75`; v2 vuelve a comprobar las líneas citadas de HOJA en `e01784a9`).
- **Respuestas de B que aplica esta v2:** `GPOS-NG-Equipos/traspasos/B/2026-10-20-respuestas-b-a-los-planos-de-a.md` (**RB**) y el aviso `avisos/B-a-A/2026-10-20-encargo-tareas-y-respuestas-a-los-planos.md` (**AV**).
- **Alcance:** O-1 (acción previa de ADR-77, punto 3), O-3 (componente de la raíz `%ProgramData%\GPOS NG` y de `config\`), la **lista de privilegios de `NT SERVICE\GPOS.Api`** (N-1, resto; nueva en v2) y N-10 (privilegios del actualizador). El código de N-1 (`AddWindowsService`, `AddSystemd`, `ARRANQUE_PRIVILEGIOS`) es de B.
- **Método:** todo se leyó con `git show`/`git grep`, sin cambiar de rama ni ejecutar nada. **[V]** = verificado, con cita `archivo:línea` (rama indicada; por omisión `origin/feature/modelo-ng` @ `b8f166db`); **[I]** = inferido.
- **Unidades:** esfuerzo en días-persona (dp), ±50 %; 1 sp = 5 dp.

## Registro de cambios

| Versión | Cambio | Punto de B que lo pide |
|---|---|---|
| v2 | **H-4 confirmado y ampliado (HB-01, Alta).** Se adopta la cadena de B: validación previa, `preparar`, `red`, **`GPOS.Api.msi` primero** (su acción previa crea la raíz protegida), Web, Reportes, `tls`, esquema, credenciales y `verificar`. C-O1-5 se reescribe sobre esa cadena (1.4) | HB-01; RB Q-2 de 1.1; AV punto 4 |
| v2 | **`CarpetaAnillo.Crear` no crea padres con la DACL heredada:** contrato nuevo en 1.4.2 (lo construye A en la pista de H-17 v2) | HB-01 (3); AV punto 4 |
| v2 | **EventId 4753 a 4766** para la acción previa y el actualizador (antes 4743-4756, que se solapaba con ADR-90). 4771-4779 (4767-4770: N-1 de B; aviso B del 2026-10-21) son de `GPOS.Instalacion` de B; por eso el evento de la comprobación K del servicio a demanda pasa a la franja de B | RB Q-8 de 1.1; HB-06; AV «EventId» |
| v2 | Declaración de los EventId de la acción de forma que los vea `EventIdUnicosTests` (o B extiende la prueba a `instalador/**`) | HB-06 (3) |
| v2 | **Lista de privilegios de `NT SERVICE\GPOS.Api`** (sección 4 nueva): la propone A; devops de B la mide con `sc qprivs`; el auditor la revisa | RB Q-7 de 1.1; HB-18; HOJA:491 y :594; AV punto 4 |
| v2 | **O-1 y O-3 esperan la firma de F-1** (excepción de cinco proyectos: acción DTF, tres `.wixproj` y `GPOS.Comun.Servidor`) | RB F-1 y 4.1; AV «Cuando B o el propietario respondan» |
| v2 | **N-10 en detalle, Q-4 y Q-5 no se firman ahora:** primero la revisión del auditor (B-6, HOJA:338). Se incorporan HB-13 (`requiereTecnico` derivado por la tubería; separar las partes con SQL) y la recomendación de B para Q-5 | RB F-3; HB-13; AV |
| v2 | F-2 (O-3) y F-4 (EventId) dejan de ser firmas: son puntos técnicos (HOJA:485-486 y :495) | HB-17; RB sección 2 |
| v2 | O-1 se declara fuente de la implementación Windows de `IComprobacionCarpetas` (ADR-129, B.4) cuando A la construya en LN | HB-07 |
| v2 | Anillo de la Web en `GPOS.Web.msi`: fila en `GposCarpetaPrevia` (lo define devops de B) | HB-16 |
| v2 | Preguntas Q-1 a Q-8 respondidas (sección 7) | RB 1.1 |

---

## 0. Hallazgos previos que cambian el planteamiento

| # | Hallazgo | Evidencia | Severidad | Efecto | Estado tras RB |
|---|---|---|---|---|---|
| H-1 | **N-10 ya tiene firmado el principio (a)**: actualización automática; el agente sin privilegios descarga y una tarea elevada fija **vuelve a verificar** antes de ejecutar el único archivo. | [V] `docs/adr/ADR-063.md:36`; `docs/adr/ADR-076.md:44`; HOJA:331-349 (B-6 firmado) | — | Ver 5 | Sin cambio |
| H-2 | **La raíz tiene dos GUID de componente distintos** en dos MSI: IQ `9E7A0D3C-…` y estación `0D4B8E27-…`. | [V] `GPOS-NG-AddOn-IQS`, `origin/b/conector-iq-instalador`: `instalador/GPOS.Conector.Iq.Instalador/Package.wxs:181-183`; [V] `instalador/AgenteImpresion/Package.wxs:120-124` | Media | Ver 2 | B alinea IQ y AdmCloud en su próxima versión (RB Q-3) |
| H-3 | **Hasta seis MSI** comparten la raíz en un servidor. | [V] HOJA:48; INS:404 | — | Fragmento compartido y GUID en el vector | Sin cambio |
| H-4 | **Puede crearse una raíz sin proteger antes de cualquier MSI** (esquema antes de los MSI; `CarpetaAnillo.Crear` crea el padre con `Directory.CreateDirectory(padre)`, que hereda la DACL; registro de Burn bajo `Instalacion\`). | [V] `src/GPOS.Core/Infraestructura/Anillo/CarpetaAnillo.cs:39-42`; `src/GPOS.Migracion/EmpresasSistema.cs:31` configura el anillo de instalación; `src/GPOS.Core/Infraestructura/Anillo/AnilloDataProtection.cs:257` llama a `Crear()`; INS:35, :69, :123 | **Alta** | 1.4 | **Confirmado por B (HB-01), con dos motivos más**: `sistema --login-api "NT SERVICE\GPOS.Api"` corre antes de que exista el servicio, y `tls` antes de los MSI escribiría `Servidor\tls\` sin la raíz protegida. Resuelto con la nueva cadena y el contrato de `CarpetaAnillo` (1.4) |
| H-5 | **El EventId 4742 ya está tomado** (`ModuloVenceIgnorado`). | [V] `origin/a/dv07-formato-licencia`: `src/GPOS.Core/Sistema/Licencia/EstadoLicenciaService.cs:145` | Media | Ver 6 | Franja de este plano: **4753 a 4766** (RB Q-8). Del 4743 al 4799 no hay ningún número en `src/*.cs` de las 162 referencias de `origin` [V, `git grep` del 2026-10-20] |
| H-6 | **La actualización automática choca con D-09 de ADR-82** (SQL privilegiado con la identidad del técnico). | [V] `docs/adr/ADR-082.md:48`, `:91`; INS:134 | **Alta** | 5.3 | B acepta la dirección; **no se firma ahora** (F-3, tras el auditor). HB-13 añade que un `requiereTecnico: false` equivocado deja el sitio sin servicio en Estricto [V `src/GPOS.Api/Servicios/Inicializacion.cs:105-108` y `:175`] |
| H-7 | Discrepancia de asignación de la lista de privilegios de `NT SERVICE\GPOS.Api`. | [V] HOJA:491 y :594 | Baja | — | **Resuelta: la fija A** (la hoja firmada prevalece sobre el encargo); devops de B la mide. Ver 4 |

---

## 1. O-1 · Acción previa de ADR-77, punto 3 — **espera la firma de F-1**

### 1.1 Decisión recomendada

1. **Qué es:** una sola acción personalizada **compartida por todos los MSI del núcleo** que crean carpetas bajo `%ProgramData%\GPOS NG`: Api, Reportes, Web y agente o estación de impresión. Es diferida, sin suplantación (corre como SYSTEM) y se programa **después de `InstallInitialize` y antes de `CreateFolders`**. Aplica el bloque `comprobacionPrevia` del vector v2 tal como está escrito.
2. **Forma:** WiX DTF en C# (.NET Framework 4.7.2, igual que el conector IQ), empaquetada con SfxCA en una `.CA.dll` firmada. El esquema WiX va en un **fragmento fuente compartido** que cada `.wixproj` incluye con `<Compile Include>`. No se usa `.wixlib` ni `.msm` (ver 2).
3. **Dónde vive** (repositorio `GPOS-NG`):
   - `instalador/Comun/GPOS.Instalador.Acciones/GPOS.Instalador.Acciones.csproj`: el proyecto DTF;
   - `instalador/Comun/GPOS.Instalador.Acciones/ComprobacionCarpetasPrevias.cs`: la lógica, sin dependencia de DTF, que compila en `net472` y en `net10.0` (la vinculan las pruebas);
   - `instalador/Comun/Fragmentos/ComprobacionCarpetasPrevias.wxs`: `Binary`, las dos `CustomAction`, la tabla propia, el mensaje `Error` y la secuencia;
   - `instalador/Comun/Fragmentos/RaizGposNg.wxs`: los componentes de O-3.
4. **Quién la construye:** el **desarrollador del equipo A** (ADR-77 asigna a A el «instalador de la API: 0,1» [V] `docs/adr/ADR-077.md:57-59`). Cada dueño de MSI la enchufa en el suyo: devops o B en Api, Reportes y Web; A en el agente de impresión.
5. **Punto de partida:** se porta la implementación probada del conector IQ (error 25001, 19 de 19 vectores v2) [V] `GPOS-NG-AddOn-IQS`, `origin/b/conector-iq-instalador`: `instalador/GPOS.Conector.Iq.Instalador.Acciones/AccionesInstalador.cs:15-88`. Se agregan R-5 y la lectura por el mismo identificador (`comoLee`). **No** se toma la DLL del conector (ADR-73, 73.7).
6. **Condición firmada (B-1):** «el *bundle* no se firma ni se publica sin la acción previa» [V] HOJA:241. Guarda en `construir.ps1 -Firmar` de cada MSI y del *bundle* (P-O1-6).
7. **Costura de ADR-129, B.4 (HB-07):** `ComprobacionCarpetasPrevias.cs` se escribe con lo que compila en `net472` y `net10.0`, y **se declara fuente de la implementación Windows de `IComprobacionCarpetas`** cuando A la construya en la tanda LN (enero), vinculada en los dos lados. Hasta entonces, el control de deriva entre las cinco implementaciones es el vector v2/v3 en cada una. No bloquea.

### 1.2 Excepción a la regla de proyectos nuevos — **F-1, Pendiente de firma**

- **Regla [V]:** `CLAUDE.md` («Proyectos nuevos») y ADR-129, bloque B, punto 3 («Sin proyectos nuevos», `docs/adr/ADR-129.md:32`). La excepción de la ola 5 nombra un instalador (`instalador/Reportes`, ADR-109:43), así que los proyectos de instalador cuentan [V según RB Q-1].
- **Por qué no cabe en un proyecto existente:** una acción DTF de WiX 5 es de .NET Framework [I; IQ usa `net472`, V]; todos los proyectos de `src` son `net10.0` [V] `src/GPOS.Comun/GPOS.Comun.csproj:4`.
- **Alternativas descartadas:** PowerShell (ADR-77 lo descarta, [V] `docs/adr/ADR-077.md:48`); acción EXE que llame a `GPOS.Migracion.exe` (no está instalado cuando corre la acción y metería SQL privilegiado como SYSTEM dentro del MSI); acción nativa C++; reutilizar la DLL de IQ; comprobar solo desde el *bundle* (no protege un MSI instalado por separado ni cumple la letra de ADR-77, punto 3).
- **Lista de F-1 que propone B y que A hace suya (RB Q-1 de 1.1, opción (a)):**

  | Proyecto | Ruta | Destino | ¿En `GPOS-NG.slnx`? | Construye |
  |---|---|---|---|---|
  | Acción previa compartida (O-1) | `instalador/Comun/GPOS.Instalador.Acciones/GPOS.Instalador.Acciones.csproj` | `net472` | No | A |
  | MSI de la API | `instalador/Api/GPOS.Api.Instalador.wixproj` | WiX 5 | No | devops / B |
  | MSI de la Web | `instalador/Web/GPOS.Web.Instalador.wixproj` | WiX 5 | No | devops / B |
  | *Bundle* | `instalador/Servidor/GPOS.Servidor.Paquete.wixproj` | WiX 5 Burn | No | devops / B |
  | Biblioteca de red de servidor (ADR-90) | `src/GPOS.Comun.Servidor/GPOS.Comun.Servidor.csproj` | `net10.0` | Sí | A |

  - Sin referencias desde `src` hacia `instalador/`. Las pruebas de la acción van en `GPOS.Tests` con el archivo de lógica vinculado (no hay proyecto de pruebas nuevo).
  - `GPOS.Instalacion` **no** es un proyecto: es el origen de eventos del Visor que declara `GPOS.Api.msi` (RB Q-1).
  - El actualizador de N-10 pedirá su propia excepción con F-3.
- **Mientras F-1 no se firme:** A **no** crea `instalador/Comun/` ni modifica el MSI del agente para O-1 u O-3 (AV). Lo que sí puede avanzar sin proyecto nuevo: la lógica de `ComprobacionCarpetasPrevias.cs` como diseño y sus casos de prueba sobre el vector, en este documento.
- **Costo:** USD 0 de licencias; una DLL más que firmar (ADR-77:66, ADR-33).

### 1.3 Contrato de la acción

**Piezas WiX** (en el fragmento compartido; la sintaxis exacta de `CustomTable` en WiX 5 es [I] y se comprueba al compilar):

| Pieza | Valor |
|---|---|
| Tabla propia `GposCarpetaPrevia` | Columnas: `Id` (clave), `Directorio` (referencia a `Directory`), `Servicio` (texto, puede ser nulo: nombre del servicio cuya cuenta virtual `NT SERVICE\<Servicio>` es escritora admitida), `CrearSiFalta` (0 o 1; **solo** la fila de la raíz lleva 1), `Orden` (de padres a hijos) |
| Acción inmediata `GposPrepararCarpetasPrevias` | Lee la tabla, resuelve cada `[Directorio]` y fija `CustomActionData`. `Before="InstallInitialize"`, condición `NOT REMOVE~="ALL"` |
| Acción diferida `GposComprobarCarpetasPrevias` | `Execute="deferred"`, `Impersonate="no"`, `Return="check"`. `After="InstallInitialize"`, antes de `StopServices`, `CreateFolders` e `InstallFiles`. Condición `NOT REMOVE~="ALL"` |
| Mensaje de error | `Error Id="25101"`: «GPOS NG no se instaló: la carpeta [2] no es segura ([3]). No se cambió nada. Ver el procedimiento de operaciones, sección «Carpeta insegura».» (distinto de los 25001 a 25003 de IQ) |
| Por qué la tabla y no `SetProperty` | Límite de 255 caracteres de `CustomAction.Target` (ICE03) con hasta 6 MSI y los SID de cada servicio. `SetProperty` queda como reserva |

**Entradas:** las filas de `GposCarpetaPrevia` del MSI. **Toda** carpeta bajo `CommonAppDataFolder` que el MSI declara con `CreateFolder` lleva su fila (P-O1-3), **incluida la carpeta del anillo de la Web en `GPOS.Web.msi`, con `Servicio = GPOS.Web`** (HB-16; la define devops de B). El SID de cada `Servicio` se **calcula** (S-1-5-80 + SHA-1 del nombre en mayúsculas) [V] `docs/adr/ADR-077.md:105`.

**Reglas** (las del vector v2, sin el dueño adicional de P-77-4, que no rige en el MSI [V] `docs/adr/ADR-077.md:91`): de padres a hijos; se lee del mismo identificador, abierto sin seguir el punto de reanálisis; dueños admitidos SYSTEM, Administradores y TrustedInstaller; escritores admitidos esos tres más la cuenta de `Servicio` de su fila; `CREATOR OWNER` no cuenta; DACL nula o ACE no evaluable = escritor ajeno; **nunca limpia ni cambia el dueño.**

**Creación de la raíz:** si falta la carpeta con `CrearSiFalta=1`, se crea en una sola llamada (`CreateDirectory` con `SECURITY_ATTRIBUTES` desde `raiz.sddl` del vector). `ERROR_ALREADY_EXISTS` (carrera) → se comprueba como existente; cualquier otro fallo → `SEGURIDAD_ILEGIBLE`. **En la cadena de B, la primera en ejecutarse es la de `GPOS.Api.msi` (paso 3), así que es ella la que crea la raíz protegida en una instalación nueva.**

**Salidas:**

| Resultado | Qué devuelve | Efecto |
|---|---|---|
| Todo seguro o inexistente | `ActionResult.Success` | La instalación sigue |
| Rechazo | Mensaje 25101 con [2] = ruta y [3] = `PUNTO_DE_REANALISIS` / `NO_ES_CARPETA` / `DUENO_NO_PERMITIDO` / `ESCRITOR_NO_PERMITIDO` / `SEGURIDAD_ILEGIBLE`; `ActionResult.Failure` | **1603**; Windows Installer revierte. Dentro del *bundle*, Burn revierte el límite de reversión (que agrupa solo los tres MSI) [I] |
| Excepción inesperada | Igual que `SEGURIDAD_ILEGIBLE` (falla cerrada) | 1603 |

**Registro:** una línea por carpeta en el registro del MSI, con el prefijo `GposComprobarCarpetasPrevias:`: ruta, código y SID culpable. Nunca valores de propiedades.

**Eventos:** origen `GPOS.Instalacion`, registro «Aplicación». La acción **solo escribe el evento si el origen ya existe** (no lo crea). EventId en la sección 6 (4753 a 4755).

**Errores SQL:** ninguno.

### 1.4 Contrato con la cadena del *bundle* (H-4 / HB-01) — **cadena de B adoptada**

#### 1.4.1 C-O1-5 (v2): ningún paso anterior al primer `MsiPackage` crea nada bajo `%ProgramData%\GPOS NG`

Se adopta la cadena de RB Q-2 de 1.1 (confirmación del texto de ADR-90 en **F-6 (ii)**, Pendiente de firma):

| # | Paquete | Escribe bajo `%ProgramData%\GPOS NG` | Qué garantiza para O-1 |
|---|---|---|---|
| 0 | `comprobar-servidor --fase previa` | No | Solo lectura |
| 1 | `preparar` (solo en actualización) | No (respaldos en la ruta de MD-54) | — |
| 2 | `red` | No (solo `HKLM\SOFTWARE\GPOS NG\Servidor`) | — |
| 3 | **`GPOS.Api.msi`** | Sí | **Su acción previa crea la raíz protegida** (`CrearSiFalta=1`) y comprueba la carpeta de la API |
| 4-5 | `GPOS.Web.msi`, `GPOS.Reportes.msi` | Sí | Su acción comprueba la raíz ya creada y sus carpetas |
| 6 | `tls` | Sí, bajo la raíz ya protegida (`Servidor\tls\` con DACL protegida explícita) | — |
| 7-8 | `esquema`, `credenciales` | No | El anillo de `GPOS.Migracion` encuentra la raíz protegida; aun así rige 1.4.2 |
| 9 | `verificar` | Sí, al final: crea `Instalacion\` con DACL protegida explícita y copia el registro de Burn | El registro de Burn queda en `%TEMP%` de quien instala hasta aquí (opción (b) de la v1) |

- **Requisito para devops (B):** que `GPOS.Api.msi` sea el primer `MsiPackage` y que ningún `ExePackage` de los pasos 0 a 2 escriba bajo la raíz (prueba P-O1-8). Si en el futuro la cadena empezara con otro MSI del núcleo, vale igual, porque todos incluyen la misma acción y la fila de la raíz.
- **MSI instalado por separado** (estación, reparación desde la caché): la acción previa de ese MSI cubre la raíz por sí misma.

#### 1.4.2 Contrato de `CarpetaAnillo.Crear` (A, pista de H-17 v2; HB-01 (3))

Hoy `Crear` hace `Directory.CreateDirectory(padre)` y luego crea la hoja con su DACL protegida [V] `CarpetaAnillo.cs:39-42`; el padre hereda la DACL de `%ProgramData%` (Usuarios puede crear). Lo usan la API y `GPOS.Migracion` (`AnilloDataProtection.cs:257`; `EmpresasSistema.cs:31`) y, vinculado, la Web (`src/GPOS.Web/GPOS.Web.csproj:16`) [V]. Contrato nuevo (P-77-2: «fuera de la carpeta de componente, toda carpeta se crea con DACL protegida explícita» [V] `docs/adr/ADR-077.md:99`):

1. **Nunca** crea un padre con la DACL heredada.
2. Busca el antepasado existente más cercano. Si es (o está debajo de) un punto de reanálisis → falla cerrada (`InvalidOperationException` con el mismo motivo que `Comprobar`).
3. Cada padre que falte se crea **en una sola llamada con DACL protegida explícita**, de arriba abajo:
   - la raíz `%ProgramData%\GPOS NG`, con `raiz.sddl` del vector v2 (la misma que la acción previa de O-1; prueba P-O1-4 compartida);
   - los intermedios, con la DACL de `CarpetaAnillo.Seguridad()` (SYSTEM, Administradores y la identidad del servicio, sin herencia).
4. **En Estricto, si falta la raíz → falla cerrada** («la raíz la crea el instalador»): en una instalación con el paquete la raíz ya existe desde el paso 3, así que su ausencia es una anomalía. Sin Estricto (desarrollo, pruebas, DEMO) se crea según el punto 3.
5. Sigue sin tocar una carpeta existente (no limpia ni cambia dueños).
6. **Residual:** en desarrollo, una raíz creada por la API tendrá como dueño la cuenta del proceso; un MSI instalado después la rechazaría (`DUENO_NO_PERMITIDO`, la acción no admite P-77-4). Es aceptable: solo ocurre fuera del paquete y se corrige borrando la carpeta de desarrollo.
- **Pruebas:** padre ausente → se crea protegido (sin ACE heredadas; comparación con `raiz.sddl` o con `Seguridad()`); padre unión → falla; Estricto sin raíz → falla; Windows simulado falso → `PlatformNotSupportedException` como hoy.
- **Esfuerzo:** 0,5 dp (A), incluido en la pista de H-17 v2. No necesita proyecto nuevo ni firma.

### 1.5 Pruebas requeridas (O-1)

| ID | Prueba | Tipo |
|---|---|---|
| P-O1-1 | La lógica contra los 19 casos del vector v2, más R-5 y `CREATOR GROUP`/`OWNER RIGHTS` como escritores no admitidos. Lista blanca inyectable | Unitaria en `GPOS.Tests` (archivo vinculado) |
| P-O1-2 | Uniones y vínculos reales (`mklink /J` sin elevación [I]); `NO_ES_CARPETA` con un archivo | Unitaria con carpetas temporales |
| P-O1-3 | En cada `Package.wxs` del núcleo, toda carpeta bajo `CommonAppDataFolder` con `CreateFolder` tiene su fila en `GposCarpetaPrevia` (incluida la del anillo de la Web); solo la raíz lleva `CrearSiFalta=1`; la acción va después de `InstallInitialize` y antes de `CreateFolders`, con `Impersonate="no"` | Lectura de `.wxs` |
| P-O1-4 | El SDDL de creación de la raíz es igual a `raiz.sddl` del vector (SHA-256); la misma constante la usa `CarpetaAnillo` (1.4.2) | Unitaria |
| P-O1-5 | El SID calculado de `GPOS.Api`, `GPOS.Reportes`, `GPOS.Web` y `GPOS.EstacionImpresion` coincide con `sc showsid` | Unitaria |
| P-O1-6 | `construir.ps1 -Firmar` falla si el `.wxs` no incluye el fragmento o si la `.CA.dll` no verifica con `signtool verify /pa /tw` | Análisis del guion |
| P-O1-7 | Laboratorio elevado: raíz plantada, unión plantada, dueño ajeno y escritor ajeno → 1603 sin cambios; raíz ausente → se crea con el SDDL exacto | Manual, QA y devops |
| P-O1-8 | **Cadena de B con la raíz ausente:** la primera instalación limpia termina bien; tras el paso 2 no existe nada bajo `%ProgramData%\GPOS NG`; tras el paso 3 la raíz tiene el SDDL exacto; `Instalacion\` y `Servidor\tls\` quedan con DACL protegida explícita; reversión forzada en cada paso | Manual, laboratorio |

### 1.6 Esfuerzo (A, ±50 %)

| Partida | dp |
|---|---|
| Proyecto DTF y puerto de la lógica de IQ con R-5 y `comoLee` | 1,5 |
| Fragmento WiX y guarda de `construir.ps1` | 0,5 |
| Pruebas P-O1-1 a P-O1-6 | 1,0 |
| Enchufarla en el MSI del agente o estación (quita el bloqueo K1-02 [V] `instalador/AgenteImpresion/Package.wxs:25-30, :151-152`) | 0,25 |
| Procedimiento de operaciones («Carpeta insegura») | 0,25 |
| **Total de A (O-1)** | **3,5 dp** (1,75 a 5,25) |
| Aparte: `CarpetaAnillo.Crear` (1.4.2), pista de H-17 v2 | 0,5 |
| Fuera del total: enchufarla en Api, Reportes y Web (devops o B) | unos 0,1 dp por MSI |
| Fuera del total: laboratorio P-O1-7 y P-O1-8 (QA o devops) | 1 dp |

---

## 2. O-3 · Quién declara la raíz `%ProgramData%\GPOS NG` y `config\` — **punto técnico; espera la firma de F-1**

O-3 es un punto técnico sin firma del propietario [V] HOJA:486 (antes F-2; HB-17). Se construye junto con O-1, **después de la firma de F-1**, porque el fragmento vive en `instalador/Comun/` y solo tiene consumidores con los nuevos `.wixproj` (RB 4.1; AV).

### 2.1 Decisión recomendada (sin cambios de fondo)

1. **Ningún MSI es «dueño» de la raíz.** Todos los MSI del núcleo declaran los mismos componentes, **byte a byte**, con el mismo archivo `instalador/Comun/Fragmentos/RaizGposNg.wxs`. Windows Installer cuenta referencias por GUID.
2. **Un solo GUID canónico por componente, publicado en el vector de ADR-77** (v3 aditiva, `componentesCompartidos`).
3. **`Permanent="yes"`** en los dos componentes (coherente con INS 6 [V] INS:242).
4. **No se usa `.msm`.** Reserva: `.wixlib` en `GPOS.AddOn.Kit` si aparece deriva entre repositorios.

### 2.2 Contrato de los componentes

| Componente | `Directory` (Id fijo) | GUID canónico | Contenido | Atributos |
|---|---|---|---|---|
| `RaizGposNg` | `DirGposNgDatos` = `CommonAppDataFolder\GPOS NG` | `9E7A0D3C-1F42-4B6E-8C5D-0A1B2C3D4E5F` (el de IQ) | `CreateFolder` + `PermissionEx Sddl="O:SYG:SYD:PAI(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICI;0x1200a9;;;AU)"` (vector `raiz.sddl`) | `Permanent="yes"`, `Bitness="always64"` |
| `ConfigGposNg` | `DirGposNgConfig` = `…\GPOS NG\config` | `0B21B6DB-0F32-4111-AF3D-12630EB877C3` (nuevo) | `CreateFolder` + el **mismo SDDL de la raíz**, explícito y protegido [V] `src/GPOS.Comun/Configuracion/ArchivoInstalacion.cs:29-36` | `Permanent="yes"`, `Bitness="always64"` |

**Reglas:** R-O3-1 lo incluyen Api, Reportes, Web y agente o estación. R-O3-2 cada MSI declara además solo su carpeta de componente, con su fila en `GposCarpetaPrevia`. R-O3-3 el agente cambia `0D4B8E27-…` por el canónico (la *feature* solo existe en desarrollo [V] `instalador/AgenteImpresion/Package.wxs:92`). **R-O3-4 (aceptada por B, RB Q-3):** IQ agrega `Permanent="yes"` y conserva su GUID; AdmCloud adopta el canónico; cada conector agrega P-O3-5; unos 0,25 dp por conector, de B; no hay instalaciones de IQ 0.4.1 fuera del laboratorio [I]. R-O3-5 `config\` sin escritor de servicio.

### 2.3 Alternativas evaluadas

| Opción | Veredicto |
|---|---|
| **Fragmento fuente compartido + GUID en el vector** | Elegida |
| `.msm` | Descartada (otro proyecto, otra excepción; no se firma por sí mismo [I]) |
| `.wixlib` | Reserva si aparece deriva |
| Un solo MSI (Api) declara la raíz | Descartada (el agente y los conectores se instalan sin la Api) |
| Ningún MSI la declara (solo la acción) | Descartada (la reparación no restaura la DACL) |

### 2.4 Pruebas (O-3)

P-O3-1 a P-O3-4 como en la v1 (inclusión del fragmento; GUID y SDDL contra el vector v3; `Permanent="yes"`; laboratorio de desinstalación parcial y total). P-O3-5 en los conectores (B).

### 2.5 Esfuerzo (A, ±50 %)

**0,85 dp** (0,4 a 1,3): fragmento 0,25; vector v3 y pruebas 0,5; GUID del agente 0,1. Fuera: B en IQ y AdmCloud, unos 0,25 dp por conector.

---

## 3. Lista de privilegios de `NT SERVICE\GPOS.Api` (N-1, resto) — **propuesta de A; devops de B la mide** (nueva en v2)

**Reparto (RB Q-7 de 1.1; HOJA:491 y :594 [V]):** A propone y justifica privilegio por privilegio (ADR-76, punto 2); **devops de B la mide** en el laboratorio con `sc qprivs GPOS.Api` y una ejecución completa; el **auditor-seguridad** la revisa; el **desarrollador de B** construye N-1 (`AddWindowsService`, `AddSystemd`, `ARRANQUE_PRIVILEGIOS`). No bloquea O-1, O-3 ni N-10.

### 3.1 Propuesta

| Privilegio | ¿En `RequiredPrivilege`? | Justificación (evidencia) |
|---|---|---|
| `SeChangeNotifyPrivilege` | **Sí (único)** | Atravesar carpetas sin permiso de lectura en cada nivel; es la norma por omisión de PA-76-1 y lo que ya declara la estación [V] `instalador/AgenteImpresion/Package.wxs:110-112`; `src/GPOS.AgenteImpresion/Estacion/IdentidadServicio.cs:30` |
| `SeImpersonatePrivilege` | **No** | El único punto de suplantación es la canalización de introspección: `RunAsClient` solo para leer el SID del cliente con `WindowsIdentity.GetCurrent(TokenAccessLevels.Query)` [V] `src/GPOS.Comun/Introspeccion/ServidorIntrospeccion.cs:196-209`, registrada en la API [V] `src/GPOS.Api/Seguridad/ValidadorTokenPrincipal.cs:87` y `:123`. Sin el privilegio, el token del cliente queda en nivel de identificación, que basta para consultar el SID [I; lo comprueba el laboratorio, como dice RB Q-7]. No hay `AddNegotiate`, `RunImpersonated` ni `LogonUser` en `GPOS.Api`, `GPOS.Core`, `GPOS.Comun` ni `GPOS.Criptografia` [V, `git grep`] |
| `SeCreateGlobalPrivilege` | **No** | No hay objetos `Global\`, `Mutex`, `MemoryMappedFile` ni semáforos con nombre en esos proyectos [V, `git grep`]. Las canalizaciones con nombre no lo necesitan [I] |
| `SeTakeOwnershipPrivilege`, `SeRestorePrivilege`, `SeBackupPrivilege`, `SeSecurityPrivilege` | **No** | El código solo fija como dueño la **propia** cuenta (canalización, `ServidorIntrospeccion.cs:120`) y crea las carpetas del anillo y de la licencia con DACL de SYSTEM, Administradores y la identidad del proceso (`CarpetaAnillo.cs:64-71`; `src/GPOS.Core/Sistema/Licencia/AlmacenLicenciaDisco.cs:113-122`) [V], lo que no exige privilegio; no lee ni escribe SACL. Los respaldos de SQL los hace el motor, no la API |
| `SeAuditPrivilege` | **No** | La API escribe en el registro «Aplicación», no en «Seguridad» |
| `SeAssignPrimaryTokenPrivilege`, `SeIncreaseQuotaPrivilege`, `SeTcbPrivilege`, `SeDebugPrivilege` | **No** | La API no lanza procesos con otro token ni lee la memoria de otros procesos. **Corrección v2.1 (2026-10-21, devops):** la frase anterior («no hay `Process.Start`») era literal pero incompleta: `ConvertidorPdf` lanza Chrome o Edge con PuppeteerSharp 25.12.0 (`src/GPOS.Api/Impresion/ConvertidorPdf.cs:75-79`; `GPOS.Api.csproj:18`, rama `b/n1-api-modo-servicio`). El hijo se crea con el mismo token y no necesita estos privilegios (un usuario estándar ejecuta Chrome con *sandbox* sin ellos) [I]; la lista no cambia, pero **L-9 y L-10 del documento de operaciones (`operaciones-gpos-api-servicio-2026-10-21.md`) son condición antes de firmarla**. También: el `TEMP` de la cuenta virtual y el perfil del navegador (no se borra) están en 4.4 de ese documento |
| `SeIncreaseWorkingSetPrivilege`, `SeTimeZonePrivilege`, `SeSystemtimePrivilege` | **No** | Sin uso en el código [V, `git grep` sin `SetSystemTime`] |

**Lo que no necesita privilegio (para que el laboratorio no lo confunda):** abrir la llave privada del certificado TLS (`LocalMachine\My`): la da la ACL de la llave, que concede el verbo `tls` (PT-02); escuchar en `PuertoApi` con Kestrel (Windows no tiene puertos privilegiados y Kestrel no usa HTTP.sys ni `urlacl`) [I]; conectarse a SQL Server con autenticación integrada; escribir eventos en «Aplicación» con un origen ya registrado por el MSI; DPAPI de la máquina.

### 3.2 Contrato para N-1 (B) y el MSI (devops de B)

- `GPOS.Api.msi`: `<ServiceConfig OnInstall="yes" OnReinstall="yes"><RequiredPrivilege Name="SeChangeNotifyPrivilege" /></ServiceConfig>`, como la estación; recuperación como RB Q-4 de 1.2 (60 s, 3 veces, contador diario, `FailureActionsWhen="failedToStopOrReturnedError"`).
- `ARRANQUE_PRIVILEGIOS` (B): la API compara su token con la lista declarada (`["SeChangeNotifyPrivilege"]`, como `IdentidadServicio.PrivilegiosDeclarados`) y, si sobra alguno, falla cerrada con su evento (EventId de N-1, que fija B).
- **Medición (devops de B):** `sc qprivs GPOS.Api` tras instalar; `whoami /priv` desde el proceso (o el evento de `ARRANQUE_PRIVILEGIOS`); ejecución completa: arranque en Estricto, emisión de token, introspección desde `GPOS.Reportes` (`NT SERVICE\GPOS.Reportes`), TLS con el certificado del sitio, renovación de huella y escritura de eventos. Si alguna operación falla por un privilegio, se agrega **solo** ese y se justifica por escrito (ADR-76, punto 2).
- **`NT SERVICE\GPOS.Web` (recomendación, mismo método):** misma lista. La Web no tiene canalización ni suplantación; usa el anillo (vinculado) y el TLS del sitio. La mide el mismo laboratorio.
- **Fuera de Windows (ADR-129):** la equivalencia (capacidades de systemd, `NoNewPrivileges`) es de la tanda LN; no se fija aquí.

**Esfuerzo:** A 0,25 dp (esta sección y la revisión del resultado del laboratorio). Laboratorio: devops de B, unos 0,5 dp [I].

---

## 4. Dependencias (no se diseñan aquí)

- **N-1 (B):** `GPOS.Api` como servicio. Bloquea `GPOS.Api.msi`, que en la cadena de B es el **primer MSI** y crea la raíz (1.4.1).
- **ADR-90 / B-3:** el verbo `red` (B) escribe `HKLM\SOFTWARE\GPOS NG\Servidor` antes de los MSI; el verbo `tls` (A) corre después de los MSI (plano de ADR-90 v2).
- **El agente de actualización** (pista de ADR-63): lado sin privilegios, manifiesto y segundo canal.

---

## 5. N-10 · Privilegios del agente de actualización — **no se firma ahora; primero la revisión del auditor (B-6)**

> **Estado v2:** B acepta la dirección técnica, pero **N-10 en detalle, Q-4 y Q-5 no se firman ahora** (RB F-3; AV). B-6, firmado, exige que el auditor-seguridad revise el diseño antes de construir el actualizador [V] HOJA:338, y el actualizador no entra antes del corte (INS 9.2). Lo que sigue es la **entrada para el auditor**, no una propuesta a firma. Frase, cuando toque: «F-3, Q-4 y Q-5 según la recomendación».

### 5.1 Decisión recomendada

**(a), como ya se firmó** [V] ADR-063.md:36, con el contrato de abajo. **(b)** (que el técnico confirme cada actualización) queda como **modo de reserva** para las versiones que exigen técnico (5.3), los sitios donde el propietario lo elija y el período sin agente.

| Criterio | (a) Lado elevado fijo solo para el archivo firmado | (b) Confirmación del técnico |
|---|---|---|
| Publicación continua (ADR-63) | Sí | No |
| Superficie de ataque | Un componente SYSTEM que procesa archivos descargados; mitigado con nueva verificación sobre copia SYSTEM-only, sin argumentos, un solo archivo y un solo firmante | Mínima |
| Riesgo operativo | Ventana de mantenimiento (Q-5) | Versiones sin aplicar |
| Compatibilidad con D-09 (H-6) | Solo con el modo híbrido (5.3) | Sí |
| Costo | 7 dp (5.6) | unos 1 dp |

### 5.2 Arquitectura y contrato

**Componentes:**
- **`GPOS.Actualizador`** (lado sin privilegios): servicio con `NT SERVICE\GPOS.Actualizador`, solo `SeChangeNotifyPrivilege` y `ARRANQUE_PRIVILEGIOS`; consulta, descarga y verifica por primera vez; no ejecuta nada.
- **Lado elevado: el mismo binario firmado en modo `aplicar`**, lanzado por un **servicio de inicio a demanda** como `LocalSystem`, `GPOS.Actualizador.Aplicar`, no residente. Por qué servicio y no tarea programada: WiX lo declara de forma nativa; el permiso `SERVICE_START` se concede con precisión al agente; el Administrador de servicios deja rastro (7036). Descartadas: tarea programada SYSTEM (exige acción personalizada o `schtasks`); servicio SYSTEM residente con canalización.
- **Excepción de proyecto:** `GPOS.Actualizador` y su MSI son proyectos nuevos; su excepción se pide con F-3 (RB Q-1).

**Carpetas** (con la acción previa de O-1 y bajo la raíz de O-3):

| Carpeta | DACL protegida | Uso |
|---|---|---|
| `%ProgramData%\GPOS NG\Actualizador\Entrega\` | SY y BA control total; `NT SERVICE\GPOS.Actualizador` Modificar (`0x1301bf`) | Manifiesto y *bundle* candidato |
| `%ProgramData%\GPOS NG\Actualizador\Aplicar\` | **Solo SY y BA** | Copia de trabajo, registros de Burn y los dos últimos *bundles* aplicados |

**Contrato del modo `aplicar`:**

| Aspecto | Contrato |
|---|---|
| **Entradas** | **Ninguna desde la línea de órdenes ni desde el agente.** Rutas fijas, más `HKLM\SOFTWARE\GPOS NG\Actualizador` (escritura solo de SY y BA): `UltimoSecManifiesto`, `Ventana`, `Modo`. La versión instalada se lee de `Version` en `HKLM\SOFTWARE\GPOS NG\Servidor`, que escribe el paso 9 (RB Q-1 de 1.2, punto 3) |
| **Paso 1. Carpetas** | Comprueba `Entrega\` y `Aplicar\` con el vector → si falla, evento **4762** y código 24 |
| **Paso 2. Copia** | Abre cada archivo de `Entrega\` sin seguir reanálisis y con `FILE_SHARE_READ`, y lo copia a `Aplicar\` |
| **Paso 3. Nueva verificación** | (i) JWS con el verificador estricto único de `GPOS.Criptografia` e INV-3 de ADR-63; (ii) `sec` mayor que `UltimoSecManifiesto`; (iii) un solo archivo con versión mayor que la instalada (sin degradación → código 23, evento **4763**); (iv) SHA-256 de la copia; (v) `WinVerifyTrust` con sujeto, emisor y EKU esperados (ADR-63, punto 5; K-06 de ADR-75); (vi) comparación con el manifiesto anterior. Cada fallo con su evento (**4757** a **4759**) y su código |
| **Paso 4. Condiciones** | Dentro de la ventana (Q-5). Si el manifiesto marca `requiereTecnico` (5.3), no se aplica: evento **4764** y código 31 |
| **Paso 5. Ejecución** | `CreateProcess` sobre la copia, con argumentos **fijos**: `/quiet /norestart /log "<Aplicar>\registros\<versión>.log"` y `MODO=Automatico`; entorno mínimo; límite de 60 min [I] |
| **Paso 6. Resultado** | 0 o 3010 → evento **4760** y se actualiza `UltimoSecManifiesto`; otro valor → evento **4761** con el código y la ruta del registro. **Nunca reinicia** |
| **Paso 7. Limpieza** | Vacía `Entrega\`; conserva los dos últimos *bundles* en `Aplicar\` |

**Códigos de salida:** 0 aplicada; 3010 aplicada, requiere reinicio; 10 nada que aplicar; 20 manifiesto rechazado; 21 SHA-256 distinto; 22 Authenticode o firmante; 23 degradación o repetición; 24 carpeta insegura; 30 fuera de la ventana; 31 exige técnico; 40 el *bundle* falló; 1 error interno.

**Autoactualización del agente:** entrada propia en el manifiesto; el modo `aplicar` lanza su MSI desacoplado y termina (Q-6, diseño del agente).

**Privilegios del lado elevado (PA-76-1):** `LocalSystem`; la lista de `RequiredPrivilege` se **mide** en el laboratorio (`sc qprivs` y una actualización completa) y la revisa el auditor. Prohibidos de entrada, salvo prueba en contra: `SeDebugPrivilege`, `SeTcbPrivilege`, `SeImpersonatePrivilege` y `SeAssignPrimaryTokenPrivilege`.

### 5.3 Modo híbrido por H-6 (con HB-13)

1. **`requiereTecnico` lo deriva la tubería, nunca a mano (HB-13):** al publicar, compara con los de la versión publicada anterior `EsquemaSistema.Version`, la versión de esquema de empresa, `rpt.VersionContrato` y el contrato de sobres. Si cualquiera cambia → `true`. Motivo: en Estricto la API no arranca si la marca de esquema es menor que la compilada [V] `src/GPOS.Api/Servicios/Inicializacion.cs:105-108` y `:175`, así que un `false` equivocado no corrompe datos pero **deja el sitio sin servicio** hasta que llegue el técnico.
2. **Con `false`:** el *bundle* corre en `MODO=Automatico` y **omite los `ExePackage` con SQL** (esquema, credenciales y `verificar` con SQL); la verificación final usa solo comprobaciones locales y `/api/salud` de las tres API.
3. **Separar lo que tiene SQL (HB-13):** `preparar` mezcla detener (sin SQL) con respaldar (con SQL), y `comprobar-servidor --fase previa` tiene partes con SQL. Para `MODO=Automatico`, B separa esas partes para que el modo automático ejecute solo las que no usan SQL privilegiado.
4. **Con `true`:** el lado elevado no aplica: evento 4764 y aviso; el técnico ejecuta el *bundle* con su identidad (D-09).
5. **Alternativa que el auditor debe evaluar (RB F-3):** que la cuenta virtual del lado elevado tenga un login de Windows con permisos de esquema. No tiene contraseña que custodiar (el motivo de D-09 para aplazar `gpos_esquema` [V según RB] `docs/adr/ADR-082.md:71`), pero es una identidad SQL privilegiada permanente y exigiría precisar D-09 con firma. Otra descartada: revivir `gpos_esquema` con credencial sellada.
6. **Qué rompe (híbrido):** la actualización no es automática en las versiones que migran, hoy casi todas [I].

### 5.4 Pruebas requeridas (N-10)

P-N10-1 a P-N10-8 como en la v1, con los EventId renumerados (5.2 y sección 6) y una más:
- **P-N10-9:** la tubería deriva `requiereTecnico = true` cuando cambia cualquiera de las cuatro versiones de 5.3, punto 1, y `false` solo si ninguna cambia (prueba de la tubería con dos manifiestos).

### 5.5 Lo que necesita el auditor-seguridad (B-6)

1. El contrato del modo `aplicar` (comprobaciones repetidas, copia SYSTEM-only, argumentos fijos).
2. La lista de `RequiredPrivilege` del lado elevado medida en P-N10-8.
3. La DACL del servicio a demanda (el agente puede arrancarlo, no reconfigurarlo).
4. El modo híbrido frente a D-09, la derivación de `requiereTecnico` (HB-13) y la alternativa del login de la cuenta virtual (5.3, punto 5).
5. El riesgo residual del parser JWS y de `WinVerifyTrust` como SYSTEM.
6. Para O-1: la falla cerrada, que la acción nunca limpie y la DLL de SfxCA firmada por dentro y por fuera.
7. **Nuevo en v2:** la lista de privilegios de `NT SERVICE\GPOS.Api` (sección 3) con el resultado del laboratorio.

### 5.6 Esfuerzo (±50 %; excluye el agente sin privilegios)

**7 dp** (3,5 a 10,5): modo `aplicar` 3,0; servicio a demanda y DACL 1,0; `MODO=Automatico` en el *bundle* (B o devops) 1,0; pruebas 2,0. Fuera: laboratorio 1 dp; auditor 1 dp; separación de `preparar` y de la fase previa (B) [I] unos 0,5 dp. USD 0 de infraestructura.

---

## 6. EventId (franja de A para la acción previa y el actualizador: **4753 a 4766**; RB Q-8 de 1.1)

**Reparto de la franja 47xx (técnico, sin firma; B lo registra con el documentador como nota de ADR-82):** 4742 `ModuloVenceIgnorado` (#103); 4743-4752 ADR-90 (A); **4753-4766 acción previa de O-1 (origen `GPOS.Instalacion`) y lado elevado del actualizador (`GPOS.Actualizador`) (A)**; 4771-4779 (4767-4770: N-1 de B; aviso B del 2026-10-21) `GPOS.Instalacion` de B (`comprobar-servidor`, `implantar-servidor`, `red`); 4780-4789 verbo `tls` y su tarea (A); 4791-4799 reserva de DB-7 (4790: T1-7 de B). Se abandona 5130-5149 (choca con 5130-5133 y 5140-5143) [V HOJA:495].

| EventId | Nombre | Nivel | Emisor | Datos (sin secretos) |
|---|---|---|---|---|
| 4753 | `CarpetaPreviaRechazada` | Error | Acción de O-1 (si el origen existe) | ruta, código, SID culpable, ProductCode, versión |
| 4754 | `CarpetaPreviaIlegible` | Error | Acción de O-1 | ruta, error de Windows |
| 4755 | `RaizCreadaProtegida` | Información | Acción de O-1 | ruta, SHA-256 del SDDL aplicado |
| 4756 | `ActualizacionCandidata` | Información | Modo `aplicar` | versión y `sec` |
| 4757 | `ActualizacionManifiestoRechazado` | Error | Modo `aplicar` | motivo (firma, INV-3, `sec`) |
| 4758 | `ActualizacionHashDistinto` | Error | Modo `aplicar` | esperado y obtenido |
| 4759 | `ActualizacionFirmaRechazada` | Error | Modo `aplicar` | sujeto, emisor, EKU y resultado de `WinVerifyTrust` |
| 4760 | `ActualizacionAplicada` | Información | Modo `aplicar` | versión, código 0 o 3010, duración |
| 4761 | `ActualizacionFallida` | Error | Modo `aplicar` | código del *bundle* y ruta del registro |
| 4762 | `ActualizacionCarpetaInsegura` | Error | Modo `aplicar` | ruta y código del vector |
| 4763 | `ActualizacionDegradacionRechazada` | Advertencia | Modo `aplicar` | versión instalada y ofrecida |
| 4764 | `ActualizacionRequiereTecnico` | Advertencia | Modo `aplicar` | versión, motivo (`requiereTecnico` o fuera de la ventana) |
| 4765 | (reserva de la acción previa) | — | — | — |
| 4766 | (reserva del actualizador) | — | — | — |

- **Cambio frente a la v1:** `ActualizacionServicioAlterado` (la comprobación K de `comprobar-servidor` sobre la configuración y la DACL del servicio a demanda) **sale de esta franja**: la emite un verbo de B, así que su número es de 4771-4779 (4767-4770: N-1 de B; aviso B del 2026-10-21) y lo asigna B cuando construya la comprobación (Entregas). Los nombres de 4756 a 4764 pueden cambiar con la revisión del auditor (5); los números quedan reservados.
- **Visibilidad para `EventIdUnicosTests` (HB-06 (3)):** la prueba solo revisa `src/**/*.cs` [V] `tests/GPOS.Tests/Arquitectura/EventIdUnicosTests.cs:10-24`, y la acción DTF vive en `instalador/`. Opciones: **(a, recomendada)** B extiende la prueba a `instalador/**/*.cs` (0,25 dp, B) y A declara los tres números de la acción en `ComprobacionCarpetasPrevias.cs` con la forma que la prueba reconoce (`public static readonly EventId X = new(n, "Nombre")`; en `net472`, con un `EventId` mínimo propio bajo `#if NETFRAMEWORK` para no añadir `Microsoft.Extensions.Logging.Abstractions` a la `.CA.dll` [I]); **(b)** sin extender la prueba, A añade en `src` un espejo con las mismas constantes, que una prueba compara con el archivo de la acción. Los del actualizador vivirán en `src` y la prueba los verá sin cambios.
- **Nota [I]:** en el registro **Seguridad** de Windows, 4742 a 4799 son eventos de auditoría de cuentas; no hay colisión (otro registro y otro origen), pero las alertas filtran por origen y número.
- **Alertas mínimas** (B-8): 4753, 4754, 4757, 4758, 4759, 4761, 4762, 4763 y 4764.
- Antes de unir cada PR que agregue EventId, `git grep` en todas las ramas de `origin` (RB 4.2, regla 7).

**Errores SQL:** ninguno en estos contratos; si alguno hiciera falta, fuera de 51618 a 51644.

---

## 7. Firmas y estado (Pendientes de firma del propietario)

| # | Qué | Estado v2 |
|---|---|---|
| **F-1** | Excepción a la regla de proyectos nuevos para los **cinco** proyectos de 1.2 (acción DTF, tres `.wixproj`, `GPOS.Comun.Servidor`) | **Pendiente de firma; firmar ahora** (RB). Sin ella no empiezan O-1, O-3 ni PR-1b de ADR-90 |
| F-2 | O-3 | **No requiere firma:** punto técnico [V] HOJA:486 (HB-17) |
| **F-3** | N-10 en detalle (servicio a demanda, modo híbrido derivado), Q-4 y Q-5 | **No se firma ahora**: después de la revisión del auditor (B-6, HOJA:338). Incluirá la excepción del proyecto `GPOS.Actualizador` |
| F-4 | Reserva de EventId | **No requiere firma:** punto técnico [V] HOJA:495; resuelto por B (sección 6) |
| F-5, F-6 | De ADR-90 (PR-4 adelantado; `Api:Url`/`AllowedHosts` y orden de `tls`) | Ver el plano de ADR-90 v2. F-6 (ii) confirma el orden de la cadena de 1.4.1 |

## 8. Preguntas de la v1 y respuestas de B (RB 1.1)

| # | Pregunta | Respuesta de B, aplicada en esta v2 |
|---|---|---|
| Q-1 | ¿Los `.wixproj` entran en F-1? | Sí, nombrados uno por uno, más `GPOS.Comun.Servidor` (1.2) |
| Q-2 | ¿Se reordena la cadena? | Sí, (a) + (b) y más: `red` antes de los MSI; `tls`, esquema y credenciales después (1.4.1) |
| Q-3 | IQ y AdmCloud | En la próxima versión de cada conector, y antes de cualquier instalación fuera de desarrollo (R-O3-4) |
| Q-4 | Respaldo en `MODO=Automatico` | Recomendación: sin respaldo, porque no cambia datos. **No se firma ahora** (F-3) |
| Q-5 | Ventana de mantenimiento | Recomendación de B, que A adopta: ventana configurable por sitio, por omisión 02:00-05:00, aplicada solo si no hubo ventas en los últimos 15 minutos (señal sin SQL privilegiado, por `/api/salud`), aplazamiento máximo de 7 días y luego aviso. Se descarta «sin jornadas abiertas» (un negocio de 24 horas nunca aplicaría) [I]. **No se firma ahora** (F-3) |
| Q-6 | Autoactualización del agente y `requiereTecnico` | Entrada del diseño del actualizador; no se decide aquí |
| Q-7 | ¿Quién fija los privilegios de la API? | A (sección 3); devops de B mide; auditor revisa |
| Q-8 | ¿Franja 47xx en lugar de 5130-5149? | Sí, con el reparto de la sección 6 |

## 9. Riesgos

| Riesgo | Severidad | Mitigación |
|---|---|---|
| H-4/HB-01: la primera instalación limpia falla o deja la raíz débil | Alta → **Baja** con la cadena de B | 1.4.1 (`GPOS.Api.msi` primero), 1.4.2 (`CarpetaAnillo`), P-O1-8 |
| F-1 no se firma pronto: O-1 no empieza y el *bundle* no se puede firmar (B-1) | Media / Alto | F-1 primera en la hoja (RB) |
| El nuevo orden de la cadena tiene un efecto de Burn no previsto (reversión, caché) | Media | P-O1-8 con reversión forzada en cada paso |
| La lista de privilegios de la API resulta corta (introspección sin `SeImpersonatePrivilege`) | Baja | Medición de devops; se agrega solo lo que se demuestre, con justificación |
| H-6: la actualización automática casi nunca aplica | Media | Modo híbrido derivado; alternativa del login de la cuenta virtual para el auditor |
| Componente SYSTEM que procesa archivos descargados | Media | Copia SYSTEM-only, reverificación, argumentos fijos, auditor (B-6) |
| Deriva entre las implementaciones de la comprobación de carpetas | Media | Vector común; `IComprobacionCarpetas` en LN con la lógica de O-1 como fuente (HB-07) |
| `CustomTable`, `PermissionEx` sobre `ServiceInstall` o `FailureActionsWhen` en WiX 5 | Baja | Se comprueba al compilar; reservas descritas |

---

## Resumen (10 líneas)

1. v2 aplica las respuestas de B: cadena nueva (HB-01), `CarpetaAnillo` sin padres heredados, EventId 4753-4766, privilegios de la API y estado de las firmas.
2. O-1: acción DTF compartida, diferida y sin suplantación (puerto de IQ); 3,5 dp de A; **espera la firma de F-1** (cinco proyectos).
3. H-4 confirmado por B y resuelto: `GPOS.Api.msi` es el primer MSI y su acción crea la raíz protegida; `red` antes, y `tls`, esquema y credenciales después.
4. `CarpetaAnillo.Crear` dejará de crear padres con DACL heredada: raíz con `raiz.sddl`, intermedios con DACL protegida y, en Estricto, falla si falta la raíz (0,5 dp, pista H-17 v2).
5. O-3: fragmento compartido, GUID canónico de IQ y nuevo para `config\`, `Permanent="yes"`; punto técnico sin firma, construido tras F-1.
6. Privilegios de `NT SERVICE\GPOS.Api`: solo `SeChangeNotifyPrivilege`, justificado contra el código; devops de B lo mide con `sc qprivs` y el auditor lo revisa.
7. EventId: 4753-4755 para la acción previa, 4756-4764 para el actualizador, 4765-4766 de reserva; la comprobación K del servicio a demanda pasa a la franja de B.
8. N-10 en detalle, Q-4 y Q-5 **no se firman ahora**: primero el auditor (B-6). `requiereTecnico` lo deriva la tubería (HB-13).
9. F-2 y F-4 dejan de ser firmas (puntos técnicos de la hoja).
10. Pendiente de firma: F-1 (ahora); F-3 (después del auditor).

### Cierre
- Estado: Completado
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\blueprint-instalador-o1-o3-n10-2026-10-20.md` (v2)
- Supuestos: 1 sp = 5 dp; la sintaxis de `CustomTable`, `PermissionEx` sobre `ServiceInstall` y `FailureActionsWhen` en WiX 5, el comportamiento de Burn como SYSTEM, que la suplantación en nivel de identificación basta para leer el SID del cliente sin `SeImpersonatePrivilege` y que Kestrel no necesita privilegios para escuchar son inferidos; las citas de INS y de `ADR-082.md:71` se toman de RB sin volver a verificarlas.
- Decisiones candidatas a ADR: precisión de ADR-77, punto 3 (acción compartida y C-O1-5 sobre la cadena de B); precisión de ADR-77, punto 6 (GUID en el vector v3); precisión de P-77-2 para `CarpetaAnillo` (padres con DACL protegida explícita; Estricto sin raíz = falla); precisión de ADR-76 (lista de privilegios de `GPOS.Api`); precisión de ADR-63/ADR-76 (lado elevado y modo híbrido derivado) tras el auditor. Las redacta el Arquitecto Maestro.
- Entregas a otros agentes: Arquitecto Maestro → F-1 a la hoja (y F-3 tras el auditor); desarrollador de A → `CarpetaAnillo.Crear` (1.4.2) en la pista de H-17 v2, y O-1/O-3 tras F-1; devops de B → cadena de 1.4.1, fila del anillo de la Web en `GPOS.Web.msi`, medición de privilegios (sección 3), `FailureActionsWhen`; desarrollador de B → N-1 con `ARRANQUE_PRIVILEGIOS`, extensión de `EventIdUnicosTests` a `instalador/**`, número de `ActualizacionServicioAlterado` en 4771-4779 (4767-4770: N-1 de B; aviso B del 2026-10-21), separación de `preparar` y de la fase previa; B (conectores) → R-O3-4; auditor-seguridad → 5.5; documentador → nota de EventId en ADR-82 y vector v3; arquitecto-datos → lista de versiones para derivar `requiereTecnico` y login de `NT SERVICE\GPOS.Api` después del MSI (RB 5); QA → P-O1-7, P-O1-8, P-O3-4 y P-N10-8.
- Próximo paso recomendado: que el Arquitecto Maestro lleve F-1 a la firma antes del 2026-10-28 y que devops de B mida la lista de la sección 3 en cuanto exista `GPOS.Api.msi`.
