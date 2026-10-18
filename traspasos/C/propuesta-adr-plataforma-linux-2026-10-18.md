[Decisión preparada por el Arquitecto Maestro (equipo C)]  Estado: **Pendiente de firma**

# Propuesta de ADR: GPOS NG en Linux con las mismas garantías que en Windows (servidor y agente de impresión)

- **Fecha:** 2026-10-18
- **Preparado por:** el Arquitecto Maestro del equipo C, por pedido del propietario del 2026-10-18.
- **Firma:** el propietario (hoja de la sección 10).
- **Registro:** el ADR va **sin número**. Si el propietario firma, **B lo registra en `master`** (`docs/adr/`, índice y `CLAUDE.md`) y le asigna el número. El rango de C (130 a 159) está congelado. Hay números libres en el rango de A (89 a 99) y quedan 127 a 129 en el de B, con 127 y 128 apartados (`docs/adr/README.md` de `origin/master`). C no une ni registra.
- **Base leída (solo lectura, sin checkout, fetch ni escritura en git):**
  - código: árbol `GPOS-C-adr81-fase-a` @ `36bfc36e` (rama `c/adr81-fase-a`: punta de `feature/modelo-ng` `af27e5d4` con la fase A de ADR-81);
  - ADR: `origin/master` @ `9b38c947`, leídos con `git show`, porque al árbol le faltan ADR-78 a 88 y ADR-118 a 126;
  - área común: `README.md`, `estado.md`, `traspasos/B/2026-10-18-hoja-firma-rsv-anillo-sellos.md` (formato) y `traspasos/B/2026-10-18-propuesta-calendario-db7.md`;
  - repositorios hermanos, solo para medir el alcance: `GPOS-NG-AddOn-Kit` y `Backup Tool`.
- **No se ejecutaron compilaciones ni pruebas** (lo pide el encargo). Las cifras de esfuerzo y de precios son inferidas.
- **Unidades:** sp = semana-persona (5 días-persona, dp). Una tanda es un PR que se puede revisar entero.

---

## 1. Contexto y pregunta a decidir

El propietario pidió poder desplegar GPOS NG en Linux **con las mismas garantías que en Windows**, y que el alcance incluya el agente de impresión (`GPOS.AgenteImpresion` y `GPOS.ImpresionDirecta`). Hoy el servidor y el agente solo arrancan en Windows.

**Pregunta:** ¿se admite Linux como plataforma del servidor y de la estación de impresión? Si se admite: con qué equivalencia para cada garantía, en qué orden, cuándo y a qué costo.

### 1.1 Corrección de una premisa: H-17 v2 ya está construido

El encargo parte de que H-17 v2 está «decidido, no implementado». **En `feature/modelo-ng` ya está construido:**
- commit `62051f93` del 2026-10-14, «Licencia CR: H-17 v2, CifradorAnillo y recuperación anclada»;
- `src/GPOS.Criptografia/Anillo/CifradorAnillo.cs`, los 7 archivos de `src/GPOS.Core/Infraestructura/Anillo/` y `ProteccionDatosInstalacion.cs:46-55`.

El `CLAUDE.md` del árbol todavía dice «decidido, no implementado» (línea 41): en ese punto está desactualizado. Para este plan, eso significa tres cosas:
- `CifradorAnillo` **ya es neutro**: usa la clase abstracta `RSA` y `AesGcm` (`CifradorAnillo.cs:93`, `:129` y `:159`), y funciona igual en Linux.
- **La costura ya existe:** `IOrigenCertificadosAnillo` (`OrigenCertificadosAnillo.cs:16-35`). Lo único atado a Windows es su implementación: el almacén `LocalMachine\My` (`:90`) y la comprobación del TPM con el Microsoft Platform Crypto Provider (`:50`).
- La idea de «neutralizar junto con H-17 v2 para no hacerlo dos veces» **ya se cumplió en el anillo**. Lo que todavía se puede construir dos veces es lo que **falta hacer**:
  - la llave ES256 en el TPM (D2 de DB-7, noviembre; precisión DB7-04 (a) de ADR-41, firmada hoy, que nombra el Microsoft Platform Crypto Provider);
  - el consumidor de la cola de comandas (ADR-114, tramo 3b);
  - el instalador de la API (ADR-77, punto 3);
  - el agente de actualización (ADR-63).

  El punto PL-02 los cubre.

### 1.2 Qué ata hoy a Windows (verificado en el código)

| # | Garantía | Mecanismo actual en Windows (evidencia) | Qué pasa hoy fuera de Windows |
|---|---|---|---|
| 1 | Anillo de Data Protection de la API, la Web y `GPOS.Migracion` | Certificado del servidor en `LocalMachine\My` con `CifradorAnillo` (`OrigenCertificadosAnillo.cs:88-92`). DPAPI en Debug y en el DEMO (`ProteccionDatosInstalacion.cs:67-72`; `ProteccionDatosWeb.cs:68-75`) | **Con certificado**, no arranca: en Unix, .NET no admite el almacén personal de máquina (*inferido*). **Con DPAPI y carpeta**, se niega a arrancar (`:69`; `:70`). **Sin carpeta**, las llaves van a la ubicación por omisión del perfil, que fuera de Windows las guarda sin cifrar (hallazgo H-L1) |
| 2 | Carpeta del anillo | DACL protegida (`CarpetaAnillo.cs:28-31` y `:45-80`) | Se crea con modo 0700 (`:31`), pero **`Comprobar` la da por conforme** sin mirar el dueño ni los permisos (`:41`) (H-L2) |
| 3 | Carpetas de la licencia | DACL protegida (`AlmacenLicenciaDisco.cs:82-107`) | **Se crean con los permisos por omisión** (`:89`) (H-L2) |
| 4 | Llave del sitio de reportes | ECDH P-256 en CNG, almacén de máquina, no exportable, con ACL de uso solo para `NT SERVICE\GPOS.Reportes` (`LlaveSitio.cs:18-40` y `:67-94`) | No se registra (`ServiciosLectura.cs:38`) y la API de reportes no arranca (`GPOS.Reportes.Api/Program.cs:15`). La costura ya existe: `ILlaveAcuerdo` / `IProveedorLlaveSitio` |
| 5 | Identidad del canal entre la API y reportes (y con los conectores) | Canalización con nombre con `PipeSecurity`, `GetNamedPipeServerProcessId` y el SID de la cuenta virtual (`IdentidadCanalizacion.cs:21-55`, `ServidorIntrospeccion.cs:55-203`, `ServiciosReportes.cs:80-134`, `VerificadorIntrospeccion.cs:48-161`) | La introspección no se registra (`GPOS.Api/Program.cs:137`) y el reenvío se niega a arrancar (`ReenvioReportes.cs:232-234`) |
| 6 | Identidad del servicio | Cuentas virtuales `NT SERVICE\…` con el SID calculado (`CuentaServicioVirtual.cs:14`; `IdentidadServicio.cs:43-60`) | No existe el concepto |
| 7 | Raíz `%ProgramData%\GPOS NG` | `SpecialFolder.CommonApplicationData` en cinco sitios: `AlmacenLicenciaDisco.cs:65`, `GPOS.Reportes/Exportacion/ComprobacionCarpetas.cs:59`, `OpcionesExportacion.cs:16`, `IdentidadServicio.cs:33` e `ImpresorasEquipo.cs:17`. Además, `LocalApplicationData` en `ConfiguracionAgente.cs:41` | En Unix, .NET resuelve `CommonApplicationData` a `/usr/share` (*inferido*). Esa carpeta es de solo lectura con `ProtectSystem=strict` y, según el estándar de jerarquía de archivos (FHS), no es para datos variables (H-L3) |
| 8 | Comprobación de carpetas de ADR-77 | P/Invoke a `advapi32` y `kernel32` (`GPOS.AgenteImpresion/Estacion/ComprobacionCarpetas.cs:156-165`; `GPOS.Reportes/Exportacion/ComprobacionCarpetas.cs:266-282`) con los vectores `adr077-carpetas.v1.json` y `.v2.json` | Solo Windows (`[SupportedOSPlatform("windows")]`) |
| 9 | Servicios y eventos | `AddWindowsService` y `AddEventLog` (`GPOS.Reportes.Api/Program.cs:21`; `ModoEstacion.cs:17-21`); `EventLog.WriteEntry` (`ComandoAprovisionar.cs:147-149`) | Hoy la API principal no registra `AddWindowsService`: solo lo hacen reportes y el agente. Su forma de alojamiento en producción la fija el instalador pendiente de ADR-77, punto 3 |
| 10 | SQL Server | Seguridad integrada por omisión (`EmpresasSistema.cs:124`; `FuenteSistema.cs:36`); usuarios contenidos `gpos_app_*` (ADR-82) | En Linux no hay cuentas `NT SERVICE` ni seguridad integrada sin Active Directory |
| 11 | Credencial de la estación | DPAPI del perfil de la cuenta virtual (`AlmacenCredencial.cs:37-66`) | No compila para Linux (destino `net10.0-windows`) |
| 12 | Impresión | `System.Drawing.Printing` y el lector de PDF de WinRT (`ImpresorasEquipo.cs:1-8`, `:31` y `:105`) | No existe en Linux |
| 13 | Instaladores | WiX para el agente (`instalador/AgenteImpresion/Package.wxs`); PowerShell para SQL Server y el DEMO | Nada para Linux |

**Cuánto código es propio de Windows.** En los proyectos del servidor hay unos 710 archivos `.cs` y **25** tienen código propio de Windows (≈ 3,5 %):

| Proyecto | Archivos propios de Windows / total |
|---|---|
| Api | 4 de 72 |
| Web | 1 de 71 |
| Core | 4 de 469 |
| Comun | 4 de 10 |
| Migracion | 5 de 19 |
| Reportes | 3 de 52 |
| Reportes.Api | 4 de 8 |
| Criptografia | 0 de 9 |

En el agente son 8 de 10. `GPOS.ImpresionDirecta` depende entero de WinRT. **No hace falta ninguna reescritura**: el trabajo es dar una implementación Linux a menos de cuarenta archivos que ya están separados.

### 1.3 Hallazgos que conviene corregir aunque no se vaya a Linux

- **H-L1 (hoy, Baja).** Sin carpeta configurada, el anillo queda en la ubicación por omisión del perfil y, fuera de Windows, guarda las llaves **sin cifrar** (contra ADR-44). Ocurre con:
  - la Web en Debug o con el indicador del DEMO (`ProteccionDatosWeb.cs:68`);
  - la API en Debug (`ProteccionDatosInstalacion.cs:67`: sin carpeta no hay rama que rechace).

  Es Baja porque no hay ninguna instalación Linux. **Remedio:** fuera de Windows, sin certificado, no arrancar (0,02 sp).
- **H-L2 (hoy, Baja; Alta en una instalación Linux).** La carpeta del anillo y las de la licencia no se comprueban fuera de Windows: la falla es abierta. **Remedio inmediato:** fuera de Windows, `Comprobar` y `Preparar` fallan cerradas hasta que exista la versión Linux (0,03 sp).
- **H-L3.** `CommonApplicationData` no es portable. **Remedio:** una sola clase de rutas (tanda LN1).
- **H-L4 (de Linux).** `usp_RespaldoCopia` agrega `\` a la carpeta de respaldos (`RespaldoCopia.cs:78`; igual en `SqlMigracionesRg14.cs:35`). En SQL Server para Linux esa carpeta es del estilo `/var/opt/mssql/data`. *Inferido:* SQL Server en Linux traduce `\`. Se verifica en LS4; si no lo traduce, se usa el separador que trae la propia ruta.
- **H-L5 (otro repositorio).** Backup Tool protege su anillo con DPAPI solo en Windows y, fuera de Windows, **lo deja sin protección** (`Backup Tool/src/BackupService.Infrastructure/DependencyInjection.cs:42-44`). Además, la ruta de 7-Zip por omisión es de Windows (`StorageSettings.cs:22`). **No debe correr en Linux** hasta que use `CifradorAnillo`, que ya está en el alcance de H-17 v2 (punto 6).
- **Lo que ya está bien resuelto:**
  - Donde no hay versión Linux, el código ya **falla cerrado** con un mensaje claro: la API de reportes (`Program.cs:15`), el reenvío (`ReenvioReportes.cs:232`), las credenciales de lectura (`GPOS.Migracion/Program.cs:58`; `ComandoAprovisionar.cs:114`) y DPAPI con carpeta (`ProteccionDatosInstalacion.cs:69`).
  - Las rutas de Chromium para Linux ya están (`ConvertidorPdf.cs:23`).
  - La hora de la empresa es un desfase fijo de −4 h (`HoraEmpresa.cs:15-16`): no depende de las zonas horarias de Windows.
  - La huella de la licencia se toma del lado de SQL Server (ADR-58, punto 5) y el `MachineGuid` solo es informativo (`LicenciaEndpoints.cs:157-158`).

## 2. Entregables evaluados

**ADR** (`origin/master`):
- ADR-24 (despliegue) y ADR-29 (impresión).
- ADR-41 (con la precisión DB7-04) y ADR-44 (credenciales).
- ADR-53 (MD-49 v2) y ADR-54 (motor).
- ADR-58 a 66: licencia, perfiles, FIPS, respaldos y BitLocker.
- ADR-75 y 76 (identidad y privilegios de los conectores) y ADR-77 con sus vectores v1 y v2 (carpetas).
- ADR-79 (mantenimiento del anillo) y ADR-82 (identidades SQL).
- ADR-114, 120 y 121 (cola de comandas, KDS y dispositivos).

**Otras decisiones:**
- H-17 v2: `docs/decisiones/2026-10-04-cierre-h0.md`, 7.3.2.
- Calendario de DB-7: `traspasos/B/2026-10-18-propuesta-calendario-db7.md`, firmado hoy.

**Código:** el de la tabla 1.2, más el agente completo (`src/GPOS.AgenteImpresion/**`, 10 archivos, y `src/GPOS.ImpresionDirecta/ImpresorasEquipo.cs`).

---

## 3. Texto del ADR propuesto (para que B lo registre)

> **ADR-NNN · Plataforma del servidor: GPOS NG en Windows y en Linux con las mismas garantías, incluida la estación de impresión**
>
> **Estado:** Propuesto · **Fecha:** 2026-10-18 · **Preparado por:** el Arquitecto Maestro del equipo C · **Número:** lo asigna B al registrar · **Precisa:** [ADR-24](ADR-024.md), [ADR-29](ADR-029.md), [ADR-41](ADR-041.md) (DB7-04), [ADR-44](ADR-044.md), [ADR-53](ADR-053.md) (MD-49 v2), [ADR-54](ADR-054.md), [ADR-58](ADR-058.md), [ADR-63](ADR-063.md), [ADR-64](ADR-064.md), [ADR-66](ADR-066.md), [ADR-75](ADR-075.md), [ADR-76](ADR-076.md), [ADR-77](ADR-077.md), [ADR-79](ADR-079.md), [ADR-82](ADR-082.md), [ADR-108](ADR-108.md), [ADR-109](ADR-109.md), [ADR-114](ADR-114.md) y H-17 v2 · **Relacionado:** [ADR-33](ADR-033.md), [ADR-62](ADR-062.md), [ADR-65](ADR-065.md), [ADR-73](ADR-073.md) (73.7), [ADR-110](ADR-110.md), [ADR-120](ADR-120.md) y [ADR-121](ADR-121.md) · **Estado de implementación:** decidido, no implementado (al firmarse)
>
> **Contexto.** El servidor de GPOS NG (API, Web, API de reportes y `GPOS.Migracion`) y el agente de impresión solo arrancan en Windows. La lógica de negocio es neutra. Lo atado a Windows está acotado y separado en unos cuarenta archivos:
> - protección de secretos de máquina (DPAPI, CNG y `LocalMachine\My`);
> - identidad del canal local (canalizaciones con nombre con SID);
> - identidad del servicio (cuentas virtuales);
> - carpetas protegidas (DACL de ADR-77);
> - alojamiento como servicio de Windows y registro en el Visor de eventos;
> - seguridad integrada de SQL Server;
> - impresión con `System.Drawing` y WinRT.
>
> El propietario pidió poder desplegar en Linux con las mismas garantías, sin retirar Windows.
>
> **Decisión.**
>
> **Bloque A · Principio y alcance.**
> 1. El servidor de GPOS NG se admite en **Windows (como hoy) y en Linux**, con la distribución de PL-04. El alcance son `GPOS.Api`, el proceso servidor de `GPOS.Web`, `GPOS.Reportes.Api`, `GPOS.Migracion` y el agente de impresión en modo estación. MAUI y los navegadores no cambian.
> 2. **Paridad de garantías.**
>    - La línea base Básica ([ADR-64](ADR-064.md), punto 1) rige igual en las dos plataformas.
>    - La tabla del bloque C es la **lista cerrada** de equivalencias.
>    - Una garantía sin equivalente Linux aprobado **bloquea** esa función en Linux (falla cerrada); nunca se rebaja.
>    - Toda garantía que se firme en adelante declara su equivalente Linux o su bloqueo.
> 3. **Windows no cambia:** comportamiento, instaladores, rutas y vectores siguen como hoy. Una caja o estación Windows funciona contra un servidor Linux, y al revés.
> 4. La topología es la de [ADR-24](ADR-024.md) y [ADR-53](ADR-053.md). El sistema operativo del servidor no la cambia. SQL Server puede estar en otro equipo con la variante S de [ADR-82](ADR-082.md), igual que en Windows.
> 5. **No es una reescritura:** son implementaciones por plataforma detrás de costuras, dentro de los mismos proyectos (bloque B, punto 3).
>
> **Bloque B · Núcleo neutro.**
> 1. **Costuras:**
>    - `IRutasInstalacion`;
>    - `IProteccionSecretoMaquina`: sella y abre un secreto para la identidad del servicio;
>    - `IOrigenCertificadosAnillo` (ya existe);
>    - `ILlaveAcuerdo` / `IProveedorLlaveSitio` (ya existen);
>    - `ICanalLocal`: servidor y cliente, con la identidad del par verificada;
>    - `IComprobacionCarpetas`: con el vector de cada plataforma;
>    - `IIdentidadProceso`;
>    - `ILlaveFirmaTokens`: ES256 de ADR-41.
>
>    El alojamiento registra a la vez `AddWindowsService` y `AddSystemd`; cada uno no hace nada fuera de su plataforma (*inferido* de Microsoft.Extensions.Hosting).
> 2. **Falla cerrada:** un componente sin implementación para la plataforma no arranca y deja un mensaje, como hace hoy el código. Se corrigen H-L1 y H-L2.
> 3. **Sin proyectos nuevos.**
>    - Las implementaciones viven en los proyectos existentes, en archivos `*.Windows.cs` y `*.Linux.cs` marcados con `[SupportedOSPlatform]`.
>    - `GPOS.AgenteImpresion` y `GPOS.ImpresionDirecta` pasan a compilar para varios destinos (bloque F).
>    - Así se cumple la regla de proyectos nuevos de `CLAUDE.md`.
> 4. **Regla vigente desde la firma.** Todo código nuevo o modificado que toque secretos de máquina, el canal local, carpetas protegidas, la identidad del proceso, el servicio o las rutas lo hace detrás de estas costuras. Rige, en particular, para:
>    - la llave ES256 de D2 de DB-7;
>    - el consumidor de la cola de [ADR-114](ADR-114.md);
>    - el instalador de la API ([ADR-77](ADR-077.md), punto 3);
>    - el agente de actualización ([ADR-63](ADR-063.md)).
> 5. **Vigilancia:** en los proyectos neutros, el analizador de compatibilidad de plataforma (CA1416) es un error, y una prueba de arquitectura comprueba que solo los archivos `*.Windows.cs` y `*.Linux.cs` usan API de una plataforma.
>
> **Bloque C · Equivalencias por garantía (lista cerrada).**
>
> | # | Garantía | Windows (hoy) | Linux (decidido) | Equivalencia y residual |
> |---|---|---|---|---|
> | C1 | Secretos de máquina en Básica: privada del certificado del anillo, cadenas y llaves de servicio | Privada en `LocalMachine\My` (proveedor de software protegido por DPAPI de máquina); DPAPI de la cuenta virtual | **Credenciales cifradas de systemd.** El verbo de implantación sella el secreto con `systemd-creds encrypt` (llave del equipo, más TPM 2.0 si existe). La unidad lo entrega descifrado **solo a ese servicio** con `LoadCredentialEncrypted=`, en `$CREDENTIALS_DIRECTORY` (memoria, no disco). Exige systemd ≥ 252 | Igual o mejor: con TPM 2.0, una copia del disco no alcanza para abrirlo. **Residual común:** root o el administrador local leen la memoria del proceso (actor A3 de [ADR-75](ADR-075.md) y de H-17 v2) |
> | C2 | Servidor sin TPM | Básica no exige TPM | Solo la llave del equipo (archivo de systemd que solo lee root), con el evento `SinTpm` al arrancar y en Diagnóstico | Una copia completa del disco sin cifrar abre los secretos, igual que DPAPI de máquina con la colmena del sistema. Se recomienda LUKS2; en Avanzada es obligatorio |
> | C3 | Llave en el TPM: destinatario principal del anillo en Avanzada (H-17 v2, punto 8), ES256 de la central y de los nodos (ADR-41, DB7-04; MD-49 v2) | Microsoft Platform Crypto Provider | Llave **no exportable** en el TPM 2.0, por el proveedor `tpm2` de OpenSSL 3 (paquete tpm2-openssl), abierta desde .NET con `SafeEvpPKeyHandle.OpenKeyFromProvider` (API de .NET 9 en adelante; *inferido*, se prueba en LS1). Su valor de autorización va sellado como credencial (C1) del servicio, y el acceso a `/dev/tpmrm0` es por el grupo `tss`. En cada arranque se comprueba que la llave viene del proveedor `tpm2` | La llave nunca sale del TPM, igual que en Windows. Riesgo por verificar: que el proveedor `tpm2` funcione con el modo FIPS de OpenSSL (ver bloque H). Si el TPM no admite OAEP con SHA-256, se usa la vía ECDH P-256 que H-17 v2 ya prevé |
> | C4 | Llave del sitio de reportes ([ADR-109](ADR-109.md), cláusula 5) | CNG, no exportable, con ACL de uso para `NT SERVICE\GPOS.Reportes` | Llave ECDH P-256 que crea `GPOS.Migracion llave-sitio` (como root), sellada como credencial (C1) que **solo recibe** `gpos-reportes.service`. La pública y su huella se publican igual | «Uso solo para el servicio» = solo esa unidad recibe la llave. Residual: la llave está en la memoria del proceso; en CNG de software, un administrador también la puede extraer |
> | C5 | Credencial de la estación de impresión ([ADR-114](ADR-114.md), PF-2) | DPAPI de `NT SERVICE\GPOS.EstacionImpresion` | AES-256-GCM en la aplicación con una llave de 256 bits que el paquete genera al instalar y sella como credencial (C1) de `gpos-estacion-impresion.service`. El archivo es `/var/lib/gpos-ng/estacion-impresion/estacion.bin` (0600) y la escritura es atómica, igual que hoy | Residual de una estación sin TPM (por ejemplo, una Raspberry Pi): quien se lleve la tarjeta se lleva la credencial. Se acepta porque la credencial es revocable en 15 s o menos ([ADR-121](ADR-121.md)), tiene un solo permiso y las comandas no llevan datos personales |
> | C6 | Identidad del servicio | Cuenta virtual `NT SERVICE\<servicio>`, con el SID calculado | **Un usuario de sistema dedicado por componente**: `gpos-api`, `gpos-web`, `gpos-reportes`, `gpos-estacion` y uno por conector. Sin shell ni contraseña, creado por el paquete y sin ningún otro uso. La identidad declarada sale de `/etc/gpos-ng/identidades.json` (root, 0644) o del nombre compilado en el binario de `/opt` (equivalente a la nota (a) de las precisiones de [ADR-77](ADR-077.md)). **No** se usa `DynamicUser=` | Igual que en Windows |
> | C7 | Identidad del canal local (API ↔ reportes, estación ↔ utilidad, núcleo ↔ conectores) | Canalización con nombre con `PipeSecurity`, PID del servidor y SID; cliente con `Identification` | **Socket Unix** en una carpeta de ejecución propia, `/run/gpos-ng/<componente>/` (`RuntimeDirectory=`, modo 0750), que solo pueden escribir el usuario del servicio y root. El permiso de conexión se da por grupo. Cada extremo lee la identidad del otro con `SO_PEERCRED` (pid, uid y gid; `Socket.GetRawSocketOption`, sin P/Invoke; *inferido*) y la compara con el usuario declarado (C6). En estos canales **no** se usa la activación por socket de systemd: con ella, `SO_PEERCRED` devolvería el PID 1 | **Más fuerte** que la canalización: el espacio de nombres no es global y un usuario sin privilegios no puede crear el socket, lo que cierra el hueco de arranque de [ADR-75](ADR-075.md). `Identification` no aplica, porque los sockets Unix no admiten suplantación |
> | C8 | Raíz y carpetas protegidas ([ADR-77](ADR-077.md)) | `%ProgramData%\GPOS NG\<Componente>` con DACL protegida | Rutas: datos en `/var/lib/gpos-ng/<componente>`, configuración en `/etc/gpos-ng/`, sockets en `/run/gpos-ng/`, temporales en `/var/cache/gpos-ng/<componente>` o `PrivateTmp=`, binarios en `/opt/gpos-ng/<componente>`. **Reglas:** el dueño es root o, en su propia carpeta, la identidad del componente (análogo a P-77-4); nadie más que el dueño escribe (ni grupo ni otros); se rechaza toda ACL POSIX que dé escritura a otro; no hay enlaces simbólicos en la cadena (`lstat`, de padres a hijos). Las carpetas las **crea el paquete** con dueño y modo. **No se usa `StateDirectory=`**: cambia el dueño de una carpeta existente, que es la «toma de posesión» que descartó [ADR-77](ADR-077.md) (*inferido* de la documentación de systemd). Vector propio: `docs/contratos/vectores/adr077-carpetas-linux.v1.json`; el de Windows (v2) no cambia | En Linux, `/var/lib`, `/etc`, `/run` y `/opt` solo los escribe root, así que la amenaza que motivó [ADR-77](ADR-077.md) (carpetas plantadas por un usuario) no existe. Las comprobaciones se mantienen como defensa ante errores de instalación |
> | C9 | Comprobación previa ([ADR-77](ADR-077.md), punto 3) | Acción diferida del MSI que rechaza con 1603 | El `postinst` del paquete **solo** llama al verificador firmado (`gpos-ng-verificar carpetas --previa`, binario .NET del paquete) antes de habilitar y arrancar los servicios. Si el verificador rechaza, el paquete queda sin configurar y los servicios no arrancan. Ningún guion comprueba por su cuenta | Por el mismo motivo por el que [ADR-77](ADR-077.md) descartó PowerShell |
> | C10 | Privilegios mínimos ([ADR-76](ADR-076.md)) | `RequiredPrivileges` = `SeChangeNotifyPrivilege` | La unidad lleva: `CapabilityBoundingSet=` y `AmbientCapabilities=` vacíos, `NoNewPrivileges=yes`, `ProtectSystem=strict`, `ProtectHome=yes`, `PrivateTmp=yes`, `PrivateDevices=yes` (salvo el acceso al TPM o al USB), `RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6`, `SystemCallFilter=@system-service` y `ReadWritePaths=` solo con su carpeta. **No** lleva `MemoryDenyWriteExecute=`, que es incompatible con el compilador JIT de .NET (*inferido*). Una prueba compara cada unidad con el vector | Igual o más estricto |
> | C11 | Servicio y eventos | Servicio de Windows, Visor de eventos con EventId y recuperación del Administrador de servicios | Unidades `Type=notify` (`AddSystemd`), con `Restart=on-failure`. El registro va a journald con el formato de systemd, que conserva la categoría y el EventId (`<prioridad>Categoría[EventId] mensaje`; *inferido*). Los avisos al SUPER y las bitácoras de la base no cambian | El técnico usa `journalctl` y `systemctl` en lugar del Visor de eventos y del Administrador de servicios |
> | C12 | SQL Server | Seguridad integrada y usuarios contenidos | Bloque D | — |
> | C13 | Reposo en Avanzada ([ADR-66](ADR-066.md)) | BitLocker XTS-AES-256 | LUKS2 con `aes-xts-plain64` y llave de 512 bits (AES-256-XTS), con desbloqueo por TPM 2.0 (`systemd-cryptenroll`) o por frase. Se verifica y se reporta igual (A10, tipo R) | Igual |
> | C14 | Firma de los binarios y actualización ([ADR-33](ADR-033.md), [ADR-63](ADR-063.md)) | Authenticode y manifiesto firmado | Los paquetes no tienen Authenticode. El agente de actualización verifica la firma del manifiesto (sin cambios), el SHA-256 de cada paquete declarado en él y una **firma separada** del paquete hecha con la llave de firma de código de GSF | Precisión del punto 5 de [ADR-63](ADR-063.md) |
> | C15 | Lo que va delante de la Web ([ADR-24](ADR-024.md)) | IIS con HTTPS y Dynamic IP Restrictions | nginx (o Kestrel con HTTPS) con `limit_req`, más la limitación propia de la API (`LimitesPeticiones`, `GPOS.Api/Program.cs:52`). El cortafuegos (nftables o ufw) aplica la misma regla: la API solo desde la Web y la oficina | Igual |
> | C16 | Conectores ([ADR-75](ADR-075.md), [ADR-108](ADR-108.md)) | Firmante Authenticode y SID por la canalización | Bloque G | — |
> | C17 | Lo que ve el usuario en los PDF y en el formato de los números | Fuentes de Windows; ICU de Windows | Arial (`Formatos.cs:46`) se sustituye por Liberation Sans, de métricas compatibles (paquete `fonts-liberation2`). Se instala ICU para `es-DO` y nunca se activa `InvariantGlobalization`. La puerta de regresión de [ADR-110](ADR-110.md) compara los PDF de las dos plataformas | Diferencias mínimas de dibujo; los números y el texto son los mismos |
>
> **Bloque D · SQL Server en Linux.**
> 1. **Ediciones:** rigen las mismas reglas de [ADR-54](ADR-054.md): Express en el cliente pequeño y en los nodos, Standard en la central grande y Enterprise si el presupuesto lo permite. Las ediciones y el precio son los de Windows (*inferido*). La versión (2022 o 2025) se verifica en la matriz de Microsoft al empezar LS4.
> 2. **Lo que no existe en Linux, y por qué no afecta:**
>    - No existen: FILESTREAM y FileTable (ya descartados por [ADR-67](ADR-067.md)), la replicación de mezcla, SSRS y SSAS, `xp_cmdshell` y los procedimientos extendidos, la extensión del grupo de búferes, la autenticación de Windows sin Active Directory, las instancias con nombre (hay una instancia predeterminada por equipo, por TCP 1433) y la memoria compartida (*inferido*; documentación de Microsoft).
>    - **GPOS NG no usa ninguna.** Búsqueda en `database/` y `src/`: no hay `FILESTREAM`, `xp_cmdshell`, `CREATE ASSEMBLY`, trabajos del Agente ni `sp_send_dbmail`. `OPENROWSET` solo aparece en la lista de lo prohibido del analizador (`AnalizadorSql.cs:24`).
>    - Las bases contenidas y `sp_getapplock` sí existen en Linux (*inferido*).
> 3. **Identidades:**
>    - En Linux, la API usa **siempre la variante S** de [ADR-82](ADR-082.md): login `gpos_srv_api`, con la cadena protegida por el anillo (SEC-05 b).
>    - La API de reportes usa el login nuevo `gpos_srv_reportes`, dentro de la regla de nombres `gpos_srv_*`.
>    - Los usuarios contenidos `gpos_app_a|b`, `gpos_rpt_*` y `gpos_lec_*` no cambian.
>    - `GPOS.Migracion` corre con un **login SQL nominal del técnico**. La contraseña se escribe al ejecutar y nunca se guarda. En Linux sustituye a la identidad de Windows de D-09.
>    - `sa` queda deshabilitado y `gsf` se usa como en [ADR-44](ADR-044.md): `mssql-conf setup` crea `sa`, y se deshabilita después de crear `gsf`.
>    - La autenticación Kerberos con Active Directory queda aplazada.
> 4. **Intercalación:** `SQL_Latin1_General_CP1_CI_AS`, fijada con `mssql-conf set-collation` y verificada en la implantación. Es condición de [ADR-50](ADR-050.md).
> 5. **Rutas y tareas programadas:**
>    - `InstanceDefaultBackupPath` y el separador se resuelven según H-L4.
>    - Express no tiene Agente en ninguna plataforma: lo que hoy hace el Programador de tareas pasa a temporizadores de systemd con `sqlcmd` (mssql-tools18).
> 6. **Backup Tool (MD-54):** solo corre en Linux después de corregir H-L5. Eso incluye leer los `.bak` del usuario `mssql` por un grupo o una ACL de lectura. Los respaldos de SQL Server son portables entre Windows y Linux (*inferido*).
> 7. **Pruebas:** `GPOS.Tests` corre contra SQL Server para Linux con `GPOST_TEST_SERVER=<equipo>,1433`. La variable no cambia de nombre.
>
> **Bloque E · Paquetes, instalación y actualización.**
> 1. **Paquetes `.deb`** (y `.rpm` si PL-04 admite RHEL), construidos con nfpm.
>    - Son autocontenidos: `dotnet publish --self-contained`, para `linux-x64` y `linux-arm64`; el equipo no necesita .NET.
>    - Dependencias de la distribución: ICU, `fonts-liberation2`, Chromium (o el que fije [ADR-110](ADR-110.md)), `cups-client` (solo el agente) y `tpm2-openssl` (solo Avanzada).
> 2. **Lista de paquetes:** `gpos-ng-api`, `gpos-ng-web`, `gpos-ng-reportes`, `gpos-ng-migracion` y `gpos-ng-estacion-impresion`, más uno por conector en su repositorio.
>    - Cada paquete crea sus usuarios, carpetas (C8), unidades y la plantilla de nginx.
>    - Las credenciales las sella un **verbo de implantación**, no el `postinst`, que no conoce los secretos.
> 3. **Guion de implantación de SQL Server en Linux**, equivalente a `instalador/SqlServer`: repositorio de Microsoft, `mssql-conf`, intercalación, `sa` y `gsf`, y cortafuegos.
> 4. **Agente de actualización** (todavía no construido; [ADR-63](ADR-063.md)). Versión Linux:
>    - una unidad de sistema con temporizador;
>    - verifica el manifiesto, el SHA-256 y la firma separada (C14);
>    - instala con `apt-get install ./paquete.deb` y reinicia las unidades.
>
>    Sin versiones visibles para el usuario, igual que en Windows.
>
> **Bloque F · Agente de impresión en Linux.**
> 1. **Alcance de la versión 1:** el **modo estación**, como servicio de sistema, en Linux x64 y arm64. El modo de escritorio (localhost) solo si un cliente lo pide.
> 2. **Impresión con CUPS** (`lpstat` y `lp`), con el mismo PDF que en Windows. ESC/POS directo, como opción posterior.
> 3. **Seguridad:**
>    - credencial según C5;
>    - canal de administración según C7: la utilidad corre con `sudo`, el servicio exige uid 0 en el par y la utilidad exige el uid de `gpos-estacion`;
>    - carpetas según C8;
>    - sin puertos abiertos y solo con conexiones salientes ([ADR-114](ADR-114.md), punto 2).
> 4. **Mismo protocolo:** emparejamiento, token `disp+jwt`, llaves SPKI fijadas y revocación ([ADR-121](ADR-121.md)). El ADMIN ve la plataforma «Linux (estación de impresión)».
> 5. Los proyectos existentes compilan para varios destinos; no se crean proyectos nuevos.
> 6. Sigue fuera del límite FIPS, como hoy ([ADR-64](ADR-064.md), punto 7).
>
> **Bloque G · Conectores y herramientas hermanas.**
> 1. **Los conectores (73.7) viven en sus repositorios.** El kit `GPOS.AddOn.Kit` (hoy `net10.0-windows`) agrega el transporte por socket Unix con la identidad del par (C7) y una plantilla de paquete Linux. Cada conector publica su paquete.
> 2. **[ADR-75](ADR-075.md) en Linux:**
>    - **(a) Firmante.** El ejecutable del conector está bajo `/opt/gpos-ng/conectores/<x>/`, donde solo escribe root. Su SHA-256 lo declara el manifiesto firmado ([ADR-63](ADR-063.md)). El `MainPID` de su unidad, leído de systemd por D-Bus, coincide con el PID del par.
>    - **(b) Cuenta.** El uid del par (`SO_PEERCRED`) es el usuario de sistema que declara el descriptor. Los descriptores están en `/etc/gpos-ng/conectores/registro/`, con dueño root y sin escritura ajena.
>    - El mecanismo exacto lo cierra el arquitecto-integraciones.
> 3. **Condición de publicación:** como el e-CF es exclusivo desde el 2026-11-15, una instalación Linux se publica **solo cuando el conector de e-CF de esa empresa tiene versión Linux**.
>
> **Bloque H · Perfil Avanzada (FIPS) en Linux.**
> 1. Mientras no se cumpla el punto 2, Linux ofrece **solo Básica**. Una licencia con `perfilMin = "avanzada"` en Linux deja la instalación en Básica con la alerta diaria de [ADR-64](ADR-064.md), punto 5. Las ventas no se detienen.
> 2. Avanzada en Linux exige:
>    - una distribución con un módulo OpenSSL validado FIPS 140-3, en modo FIPS (RHEL 9 o 10, o Ubuntu Pro FIPS; el estado CMVP se verifica en ese momento);
>    - TPM 2.0 con C3, LUKS2 (C13), y el laboratorio y la revisión del auditor equivalentes a AP-09.
>
>    El texto de declaración de Q-21 no cambia.
> 3. En Linux, .NET usa la OpenSSL del sistema. En modo FIPS, los algoritmos de GPOS NG son aprobados: AES-GCM, RSA-OAEP-SHA256, ECDSA y ECDH P-256, SHA-2 y HMAC (*inferido*).
>
> **Bloque I · Secuencia.**
> 1. **Antes del corte:** solo la regla del bloque B, punto 4, y las correcciones de H-L1 y H-L2.
> 2. **Después del corte, en la etapa prudente:** neutralización (LN1 a LN3). Windows no cambia, y se comprueba con la suite oficial en Windows.
> 3. **Punto de control del propietario** al cerrar LN: decide si se sigue con LS.
> 4. **Servidor Linux** (LS1 a LS5) y **conectores y herramientas** (LC1 a LC3).
> 5. **Agente:** LA1 junto con el consumidor de la cola de [ADR-114](ADR-114.md) (tramo 3b), para que nazca neutro; después, LA2 a LA4.
> 6. **Prioridad:** DB-7 y la fase A de [ADR-81](ADR-081.md) van antes. El orden frente a la fase B de [ADR-81](ADR-081.md) lo decide el propietario (PL-03).
>
> **Precisiones a otros ADR (sin cambiar sus textos firmados; cada una «decidida, no implementada»).**
> - **[ADR-24](ADR-024.md):** en Linux, lo que va delante de la Web y el cortafuegos se rige por C15.
> - **[ADR-29](ADR-029.md):** en Linux, `GPOS.ImpresionDirecta` imprime por CUPS. La configuración del agente pasa de `HKLM\SOFTWARE\GPOS\AgenteImpresion` a `/etc/gpos-ng/agente-impresion.json` (root, 0644), y el registro, a journald.
> - **[ADR-41](ADR-041.md) (DB7-04 (a)):** la llave ES256 de la central se construye detrás de `ILlaveFirmaTokens`. En Linux usa C3. Sin TPM, rigen las condiciones de C49-1 v2, igual que en Windows.
> - **[ADR-44](ADR-044.md):**
>   - el punto 3 (sin texto plano) se cumple en Linux con C1;
>   - en Linux, I-18 (secretos de la configuración fuera del texto plano) se implementa con `LoadCredentialEncrypted=`;
>   - `sa` deshabilitado y `gsf` sin cambios.
> - **[ADR-53](ADR-053.md) (MD-49 v2):** un nodo Linux firma sus tokens con C3. La regla de Avanzada de que ningún nodo esté registrado sin TPM no cambia.
> - **[ADR-54](ADR-054.md):** SQL Server para Linux se admite con las reglas del bloque D.
> - **[ADR-58](ADR-058.md):**
>   - la carpeta de la licencia es `/var/lib/gpos-ng/licencia/` (C8);
>   - la huella blanda no cambia (en Linux, `@@SERVERNAME` es el nombre del equipo);
>   - el dato informativo pasa a ser `/etc/machine-id`, que nunca entra en la huella (NV-04).
> - **[ADR-63](ADR-063.md), punto 5:** en Linux, C14.
> - **[ADR-64](ADR-064.md):** bloque H. Lo que depende del sistema operativo se verifica y se reporta: el modo FIPS (`/proc/sys/crypto/fips_enabled`), LUKS2 y el TPM.
> - **[ADR-66](ADR-066.md):** C13.
> - **H-17 v2:**
>   - en Linux, el origen del certificado (punto 2) es C1 en Básica y C3 en Avanzada (punto 8);
>   - la comprobación del TPM busca el proveedor `tpm2` en lugar del Microsoft Platform Crypto Provider;
>   - `recuperar-anillo` (punto 5) no cambia: es neutro y permite mudar una instalación entre plataformas.
> - **[ADR-75](ADR-075.md) y [ADR-108](ADR-108.md), punto 1:** bloque G y C7.
> - **[ADR-76](ADR-076.md):** C10.
> - **[ADR-77](ADR-077.md):** C8 y C9, con el vector Linux propio. Las precisiones P-77-4 y P-77-2 tienen sus análogos en C8.
> - **[ADR-79](ADR-079.md), punto 1:** en Linux, «servicio de Windows `GPOS.Api` o `GPOS.Reportes` no detenido» se lee «unidad `gpos-api.service` o `gpos-reportes.service` activa».
> - **[ADR-82](ADR-082.md):**
>   - bloque D, punto 3: en Linux, la variante S siempre y el login `gpos_srv_reportes`;
>   - para `GPOS.Migracion`, el login SQL nominal del técnico sustituye a D-09.
> - **[ADR-83](ADR-083.md) y textos de riesgo residual:** «administrador de Windows» se lee «administrador del sistema operativo (root en Linux)».
> - **[ADR-109](ADR-109.md), cláusulas 5 y 6:** C4 y C7.
> - **[ADR-114](ADR-114.md), PF-2:** en Linux, la estación es el servicio de sistema `gpos-estacion-impresion.service`, con el usuario `gpos-estacion` y la credencial según C5, en `/var/lib/gpos-ng/estacion-impresion/` (modo 0700). La plataforma que reporta es «Linux (estación de impresión)».
>
> **Alternativas descartadas.**
> - **Reescritura o bifurcación del código por plataforma:** contradice el principio rector y duplica el mantenimiento.
> - **Proyectos nuevos por plataforma:** exigen una excepción a la regla de proyectos nuevos y duplican el código.
> - **Contenedores (Docker o Podman) como única forma de despliegue en la versión 1:**
>   - agregan una capa más que el técnico debe operar;
>   - complican el TPM, las credenciales de systemd y la comprobación de carpetas;
>   - no le ahorran nada al cliente pequeño.
>
>   Se reevalúan para la nube ([ADR-24](ADR-024.md)).
> - **Archivos con modo 0600 sin cifrar:** violan [ADR-44](ADR-044.md).
> - **PKCS#11 (tpm2-pkcs11) como única vía al TPM:** .NET no trae un proveedor PKCS#11, así que pondría una librería de terceros en la ruta crítica. Queda como reserva si `OpenKeyFromProvider` falla.
> - **TCP local con TLS mutuo para el canal:** suma la custodia de secretos que [ADR-75](ADR-075.md) ya descartó.
> - **`DynamicUser=`:** el uid cambia, lo que complica los dueños de las carpetas y la verificación.
> - **Activación por socket en los canales con identidad:** `SO_PEERCRED` devolvería el PID 1.
> - **Avanzada en Linux desde la primera versión:** depende de que el proveedor `tpm2` funcione en modo FIPS, y eso no está verificado.
> - **Conectores en un equipo Windows aparte:** imposible, porque el canal es local.
>
> **Qué rompe, a quién afecta, por qué se justifica y cómo se migra.**
> - **Qué rompe:** nada en Windows. En Linux, lo visible es poco:
>   - en los PDF, Liberation Sans en lugar de Arial, con las mismas métricas;
>   - los nombres de impresora son los de las colas de CUPS;
>   - el técnico usa `journalctl` y `systemctl`;
>   - la pantalla de dispositivos muestra «Linux (estación de impresión)».
> - **A quién afecta:**
>   - a GSF: los técnicos necesitan conocer Linux, con la guía y el guion de implantación;
>   - a los equipos A y B: construyen las costuras;
>   - a los repositorios de los conectores y de Backup Tool;
>   - al auditor-seguridad y a QA: la matriz de pruebas se duplica;
>   - a los clientes que elijan Linux.
> - **Por qué se justifica:**
>   - **Costo para el cliente:** la licencia de Windows Server de la central (unos USD 1 100 por un servidor de 16 núcleos) y la de Windows en cada nodo de sucursal de la entrega 2. Estaciones de cocina de unos USD 100 en lugar de USD 250 a 400. Todas son cifras *inferidas* que hay que verificar con el distribuidor local.
>   - **Libertad de elección:** el cliente elige el sistema operativo sin perder seguridad.
>   - **Efecto lateral:** la neutralización pone las cuatro copias de la comprobación de carpetas detrás de una sola interfaz y hace el núcleo más fácil de probar.
> - **Cómo se migra:** no hay instalaciones que migrar (todo es desarrollo). Para mudar una instalación de Windows a Linux:
>   - se respaldan y restauran las bases;
>   - se ejecuta `recuperar-anillo` con el custodio y acta (H-17 v2, punto 5): solo cambia la envoltura;
>   - la huella blanda cambia con `@@SERVERNAME` y abre la gracia de entorno ([ADR-59](ADR-059.md)) hasta que GSF reemite la licencia;
>   - los sellos de [ADR-83](ADR-083.md) se conservan, porque dependen del anillo;
>   - las estaciones se emparejan de nuevo: sus credenciales son revocables y no se migran.
>
> **Consecuencias.**
> - Esfuerzo: unas 5,3 sp (de 3,9 a 6,9; ±35 %, *inferido*), en el detalle de la sección 6.
> - Licencias: USD 0 con Ubuntu Server.
> - Equipos: un equipo de pruebas Linux con TPM 2.0 (USD 250 a 400 una vez, o una máquina virtual de USD 20 a 40 al mes) y una impresora térmica de pruebas, si no la hay.
> - La suite oficial sigue corriendo en Windows. En Linux, se corre en LS y antes de cada publicación Linux.
> - El residual común a las dos plataformas es el administrador local o root (actor A3).
>
> **Estado de implementación:** decidido, no implementado (al firmarse).

---

## 4. El agente de impresión: qué hace hoy y cómo se lleva a Linux

### 4.1 Qué hace hoy (verificado)

**Un ejecutable con dos modos**, más una utilidad (`Program.cs:8-19`).

**Modo de escritorio (localhost).**
- Es un `WinExe` con Kestrel que escucha solo en `localhost:17654` (`Program.cs:33`), con una sola instancia por sesión (`Mutex` `Local\…`, `:22`).
- Protecciones: comprueba el encabezado `Host` (contra el reencaminamiento de DNS), la lista de orígenes, CORS y el acceso a la red privada de Chrome y Edge (`:43-79`).
- Rutas: `/estado`, `/predeterminada`, `/prueba` e `/imprimir`, que recibe un PDF de hasta 50 MB (`:82-102`).
- La configuración se lee de `HKLM\SOFTWARE\GPOS\AgenteImpresion` o de la variable `GPOS_AGENTE_ORIGENES` (`ConfiguracionAgente.cs:12-30`). El registro va a `%LOCALAPPDATA%\GPOS\agente-impresion.log` (`:40-41`).

**Impresión (`ImpresorasEquipo.cs`).**
- Lista las impresoras con `PrinterSettings.InstalledPrinters` (`:31`) y lee la predeterminada de Windows.
- La impresora elegida por equipo se guarda en `%ProgramData%\GPOS\impresion.json`, todavía la raíz vieja: el cambio de PA-77-2 está pendiente (`:17`).
- Convierte cada página del PDF en imagen con `Windows.Data.Pdf` (hasta 300 ppp) y la imprime con `PrintDocument` (`:105`). El papel es el de la página o uno personalizado para los rollos, y la imagen se reduce si el papel es más angosto.
- La página de prueba usa Segoe UI.
- **No hay ESC/POS** y no abre la gaveta (ADR-29, «Consecuencias»).

**Modo estación** (ADR-114 PF-2, ADR-121, tanda K1).
- Es un servicio de Windows, `GPOS.EstacionImpresion`, con su cuenta virtual (`ModoEstacion.cs:15-31`), sin Kestrel y sin puertos.
- **Emparejamiento:** con la central, por código o por QR con las llaves SPKI fijadas (`ClienteDispositivo.cs`).
- **Estados:** `SIN_EMPAREJAR`, `PENDIENTE_CONFIRMACION`, `ACTIVA`, `REVOCADA`, `TIPO_NO_VALIDO`, `CREDENCIAL_ILEGIBLE` y `SIN_CONEXION`. El token `disp+jwt` vence a los 15 min (`ServicioEstacion.cs:12-58`).
- **Credencial:** cifrada con DPAPI de la cuenta del servicio en `%ProgramData%\GPOS NG\EstacionImpresion\estacion.bin`, con escritura atómica (`AlmacenCredencial.cs`).
- **Utilidad `emparejar` / `estacion-estado`:** habla con el servicio por una canalización con nombre con ACL (permitida a SYSTEM y Administradores, negada a la red). El servicio exige un administrador elevado. La utilidad comprueba que el proceso servidor es el del servicio registrado en el Administrador de servicios (`CanalAdministracion.cs:49-212`).
- **Carpetas:** se comprueban al arrancar con el vector v2 (`ComprobacionCarpetas.cs`).
- **Privilegio declarado:** solo `SeChangeNotifyPrivilege` (`IdentidadServicio.cs:30`).
- **No consume todavía la cola de comandas.** `ModoEstacion.cs:27-28` deja el punto de enganche `IProveedorTokenEstacion`, y no hay código de comandas en el agente (búsqueda de «comanda» en `src/GPOS.AgenteImpresion`: sin resultados).

**El KDS no pasa por el agente.** La pantalla de cocina (ADR-120) es un navegador que sirve la Web. Solo usa la estación para la impresión de respaldo, por la misma cola.

**Lo que ya es neutro:**
- el cliente HTTP con TLS fijado (`ClienteDispositivo.cs`);
- la lectura del QR;
- la lógica de `NucleoEstacion`, que hoy está marcada como solo Windows únicamente porque depende de `AlmacenCredencial`.

### 4.2 Propuesta para Linux

| Pieza | Hoy (Windows) | Linux | Qué queda igual |
|---|---|---|---|
| Proyectos | Destino `net10.0-windows10.0.19041.0` | Varios destinos: `net10.0-windows10.0.19041.0;net10.0`. Los archivos de cada plataforma van en `*.Windows.cs` / `*.Linux.cs`. Destinos de ejecución: `win-x64`, `linux-x64` y `linux-arm64`. `OutputType=WinExe` solo en Windows. MAUI sigue usando el destino Windows (`GPOS.UI.MAUI.csproj:41`) | El código de emparejamiento, token, TLS y cola |
| Servicio | Servicio de Windows con cuenta virtual | Unidad **de sistema** `gpos-estacion-impresion.service`, con `User=gpos-estacion`, `Type=notify`, el endurecimiento de C10, `Restart=on-failure` y `After=network-online.target cups.service` | Sin puertos; solo conexiones salientes (ADR-114, punto 2) |
| ¿De sistema o de usuario? | — | **De sistema.** PF-2 ya quitó la necesidad de una sesión iniciada. Un servicio de usuario (`systemd --user`) depende de una sesión o de `loginctl enable-linger`, y dejaría la credencial en la carpeta personal de una persona | — |
| Credencial | DPAPI de la cuenta virtual | C5 | Formato del contenido, escritura atómica y estado `CREDENCIAL_ILEGIBLE` |
| Canal de la utilidad | Canalización con ACL, administrador elevado y PID del servicio | Socket en `/run/gpos-ng/estacion-impresion/admin.sock` (C7). El servicio exige que el par tenga uid 0 (`sudo`); la utilidad exige que el servidor tenga el uid de `gpos-estacion` | Mismos verbos y mensajes. El secreto nunca sale del servicio |
| Carpetas | `%ProgramData%\GPOS NG\EstacionImpresion` con DACL | `/var/lib/gpos-ng/estacion-impresion` (gpos-estacion, 0700) y `estacion.bin` (0600), según C8, con el vector Linux | Comprobación al arrancar con falla cerrada |
| Lista de impresoras | `PrinterSettings` | `lpstat -e` y, para la predeterminada, `lpstat -d` (paquete `cups-client`). Se ejecuta con `ArgumentList`, nunca con un intérprete de órdenes | Se valida el nombre contra la lista antes de usarlo, como hoy (`ImpresorasEquipo.cs:51`) |
| Impresión de PDF | WinRT → imagen → `PrintDocument` | `lp -d <cola> -t <trabajo> -o media=Custom.<ancho>x<alto>mm -` con el PDF por la entrada estándar. CUPS dibuja el PDF con sus filtros y el controlador de la impresora | Mismo PDF que genera la API, con el mismo papel y el mismo rollo continuo (`ConvertidorPdf.cs`) |
| Impresoras térmicas | Controlador de Windows del fabricante | Controlador CUPS del fabricante (*inferido*: Epson y otros publican controladores para Linux) o un controlador genérico de trama ESC/POS. QA con dos modelos | — |
| Página de prueba | Dibujo con Segoe UI | Trabajo `text/plain` con el mismo contenido (impresora, equipo y fecha), que CUPS convierte con `texttopdf` | El contenido |
| Configuración | Registro de Windows (HKLM) | `/etc/gpos-ng/agente-impresion.json` (root, 0644). La impresora elegida, en `/var/lib/gpos-ng/impresion/impresion.json` | — |
| Registro | Visor de eventos (estación); archivo en `%LOCALAPPDATA%` (escritorio) | journald; en el modo de escritorio, `~/.local/state/gpos-ng/` | Nada sensible en el registro |
| Cola de ADR-114 y respaldo del KDS (ADR-120) | Todavía no existe | Sondeo largo por HTTP: es neutro. Se construye una sola vez en LA1, con el consumidor del tramo 3b | Aviso a los 10 s, reenvío, respaldo y el riesgo residual de doble impresión |
| Modo de escritorio (opcional) | `WinExe` al iniciar la sesión | Unidad `systemd --user` o arranque automático de XDG, con Kestrel en `localhost:17654` y las mismas comprobaciones de `Host`, origen y red privada | El mismo puerto fijo (precisión de 2026-09-29 de ADR-29) |
| Gaveta | No (ADR-29) | No en la versión 1. Opción (b) de PL-12 | — |

### 4.3 ¿Un proyecto neutro con implementaciones por plataforma, o dos binarios?

| Opción | Qué es | Costo | Valoración |
|---|---|---|---|
| **(a) Los mismos proyectos para varios destinos** | Una sola fuente. Se generan un binario para Windows y otro para Linux (x64 y arm64) | Incluido en LA1 (0,25 sp) | **Recomendada.** No crea proyectos nuevos (cumple la regla de `CLAUDE.md`), no duplica código y MAUI no cambia |
| (b) Dos proyectos (`…Windows` y `…Linux`) | Dos fuentes con una parte común copiada | +0,2 sp, más el mantenimiento doble | Exige una excepción a la regla de proyectos nuevos |
| (c) Un solo `net10.0`, eligiendo la plataforma solo al ejecutar | — | — | **No es posible:** `Windows.Data.Pdf` (WinRT) exige un destino Windows |

---

## 5. Puntos de decisión: opciones, costo y riesgo

Las tandas están en la sección 6. Marco con **[Propietario]** lo que es decisión de negocio, más allá de la técnica.

**PL-01 · Alcance [Propietario]**

| Opción | Costo | Valoración |
|---|---|---|
| **(a)** Linux se admite como plataforma del servidor y de la estación, con paridad de garantías; Windows sigue igual | ≈ 5,3 sp después del corte | **Recomendada:** es lo que pidió el propietario y no rebaja ninguna garantía |
| (b) Solo neutralizar (LN) y decidir Linux con el primer cliente que lo pida | ≈ 1 sp ahora y ≈ 4,3 sp después | Más barata a corto plazo, pero Linux no estaría disponible cuando aparezca el cliente (de 2 a 3 meses de espera) |
| (c) No | 0 | Sin ahorro para el cliente |

**PL-02 · Regla de neutralidad desde la firma y corrección de H-L1 y H-L2**

| Opción | Costo | Valoración |
|---|---|---|
| **(a)** Desde la firma: costuras en todo código nuevo (sobre todo `ILlaveFirmaTokens` en D2 de DB-7) y H-L1 y H-L2 ya | 0,15 a 0,25 sp repartidas, más 0,05 sp | **Recomendada.** Evita rehacer D2 (0,2 a 0,3 sp) y cierra dos fallas abiertas |
| (b) Solo después del corte | 0 ahora | Obliga a rehacer lo que se construya antes con llamadas directas a Windows |

**PL-03 · Momento, secuencia y prioridad [Propietario]**

| Opción | Valoración |
|---|---|
| **(a)** LN en enero de 2027 (etapa prudente); punto de control; LS y LC en febrero y marzo; agente con la cola (3b). DB-7 siempre antes. **La fase B de ADR-81 antes de LS**; puede ir en paralelo con LN si hay dos equipos (no tocan los mismos archivos) | **Recomendada.** No compite con el corte y deja una decisión barata (el punto de control) antes del gasto mayor |
| (b) LN y LS después de la entrega 2 | Más tarde. Los nodos de la entrega 2 nacerían solo para Windows y perderían el ahorro por sucursal |
| (c) Antes del corte | **Descartada:** compite con DB-7, que es condición del primer cliente |

**PL-04 · Distribución admitida [Propietario]**

| Opción | Costo | Valoración |
|---|---|---|
| **(a)** **Ubuntu Server 24.04 LTS**, única distribución para Básica; RHEL solo si un cliente pide Avanzada en Linux | USD 0; systemd 255; soporte estándar hasta 2029 (*inferido*) | **Recomendada:** una sola matriz de pruebas. SQL Server para Linux admite Ubuntu (falta verificar la versión 2025 en LS4) |
| (b) RHEL 9, única | Suscripción anual por servidor, desde unos USD 350 (*inferido*) | FIPS validado de entrada, pero con costo para todos los clientes |
| (c) Ubuntu y RHEL desde el inicio | +0,5 sp (paquetes `.rpm` y matriz doble) | Solo si hay demanda de RHEL |

Debian, Rocky y Alma quedan fuera: Microsoft no admite SQL Server en ellas (*inferido*).

**PL-05 · Secretos de máquina en Linux**

| Opción | Valoración |
|---|---|
| **(a)** Credenciales cifradas de systemd en Básica (C1 y C2; con TPM 2.0 si existe; sin TPM, se admite con el aviso `SinTpm`, en paridad con Básica en Windows) y el proveedor `tpm2` de OpenSSL para las llaves que deben vivir en el TPM (C3) | **Recomendada.** Costo LS1: 0,45 sp, con una prueba de concepto del TPM. Exige systemd ≥ 252 |
| (b) PKCS#11 (tpm2-pkcs11) para todo | Librería de terceros en la ruta crítica; queda como reserva |
| (b′) Exigir TPM 2.0 en todo servidor Linux | Más fuerte, pero excluye las máquinas virtuales sin TPM virtual. Se puede exigir por contrato con `perfilMin` |
| (c) Archivos 0600 sin cifrar | **Descartada:** viola ADR-44 |

**PL-06 · Identidad del canal:**
- **(a)** sockets Unix en una carpeta de ejecución propia, con `SO_PEERCRED` y usuarios de sistema (C6 y C7). **Recomendada.** LS2: 0,3 sp.
- (b) TCP local con TLS mutuo. **Descartada.**

**PL-07 · Carpetas protegidas:**
- **(a)** rutas del estándar FHS (`/var/lib`, `/etc`, `/run`, `/var/cache` y `/opt`), modos POSIX sin ACL que den acceso a otros, aislamiento de systemd, vector Linux propio y sin `StateDirectory=` (C8 y C9). **Recomendada.** LS3: 0,3 sp.
- (b) todo bajo `/opt/gpos-ng`. Mezcla binarios con datos, y con `ProtectSystem=strict` obliga a abrir excepciones de escritura dentro de `/opt`.

**PL-08 · SQL Server en Linux:**
- **(a)** variante S siempre, el login `gpos_srv_reportes` y el login SQL nominal del técnico para `GPOS.Migracion` (bloque D). **Recomendada.** LS4: 0,4 sp.
- (b) unir el servidor a Active Directory con Kerberos. Exige dominio: no sirve al cliente pequeño. Queda como reserva para clientes corporativos.

**PL-09 · Paquetes y actualización**

| Opción | Valoración |
|---|---|
| **(a)** `.deb` autocontenidos con nfpm, por el canal del manifiesto firmado, con SHA-256 y firma separada en lugar de Authenticode (C14) | **Recomendada.** Incluido en LS5 |
| (b) Guion de instalación sobre un `.tar.gz` | −0,1 sp, pero sin dpkg: desinstalar y gestionar dependencias a mano |
| (c) Contenedores | Descartada en la versión 1 (ver las alternativas del ADR) |

**PL-10 · FIPS y perfil Avanzada en Linux [Propietario]**

| Opción | Valoración |
|---|---|
| **(a)** Linux solo con Básica hasta que un cliente pida Avanzada en Linux. Entonces: RHEL (o Ubuntu Pro FIPS), TPM 2.0, LUKS2 y laboratorio de AP-09. Con `perfilMin = "avanzada"`, la instalación queda en Básica con la alerta diaria | **Recomendada.** Avanzada ni siquiera es seleccionable antes de la versión 1 del acceso multiempresa |
| (b) Avanzada en Linux desde la primera versión | +0,5 a 0,8 sp y un laboratorio. El riesgo de usar el proveedor `tpm2` en modo FIPS no está verificado |

**PL-11 · Agente de impresión en Linux: alcance y entrega [Propietario]**

| Opción | Valoración |
|---|---|
| **(a)** Modo estación (servicio de sistema), x64 y arm64, en la **entrega 3, tramo 3b**, junto con el consumidor de la cola; el modo de escritorio solo a pedido | **Recomendada.** La estación vale para las comandas, que llegan en 3b; así la cola nace neutra una sola vez |
| (b) En la entrega 2, junto con el servidor Linux | Antes de que exista la cola, solo serviría para imprimir documentos desde un escritorio Linux, que es un caso raro en las cajas |
| (c) Los dos modos a la vez | +0,15 sp |

**PL-12 · Forma de imprimir en Linux**

| Opción | Valoración |
|---|---|
| **(a)** CUPS para todo, con el mismo PDF; ESC/POS directo (por el puerto 9100 o una cola sin filtro) como opción posterior | **Recomendada:** paridad visual con Windows. LA3: 0,3 sp |
| (b) ESC/POS directo para las comandas desde el inicio | Da la gaveta y más velocidad, pero obliga a un segundo renderizador de comandas en el servidor, con su equivalente en Windows (+0,3 a 0,5 sp). El formato de la comanda es una decisión del tramo 3b que no depende de la plataforma |

**PL-13 · Estructura de proyectos:**
- **(a)** varios destinos en los mismos proyectos, sin proyectos nuevos (4.3). **Recomendada.**
- (b) proyectos por plataforma.

**PL-14 · Conectores en Linux [Propietario]**

| Opción | Valoración |
|---|---|
| **(a)** Una instalación Linux se publica solo cuando el kit y el conector de e-CF de esa empresa tienen versión Linux (AdmCloud o IQS; Polaris es la tercera opción), con la precisión de ADR-75 del bloque G | **Recomendada.** LC1 y LC2: 0,6 a 0,8 sp, en los repositorios de los conectores |
| (b) Publicar Linux sin conectores | **Descartada:** desde el 2026-11-15 prácticamente toda empresa necesita el conector de e-CF |

**PL-15 · Figura:**
- **(a)** ADR nuevo (B le asigna el número), con las precisiones de la lista. **Recomendada.**
- (b) solo precisiones de ADR-24, 54, 64 y 77. Repartiría en notas una decisión que atraviesa todo.

---

## 6. Plan por tandas y costo

| Tanda | Contenido | Esfuerzo (sp, *inferido*) | Equipo sugerido | Cuándo |
|---|---|---|---|---|
| **Antes del corte** | H-L1 y H-L2 (falla cerrada fuera de Windows); `ILlaveFirmaTokens` dentro de D2 de DB-7 | 0,05 + 0,1 | A (H-L) y B (D2) | Con la firma |
| **LN1** | `IRutasInstalacion` (H-L3); `AddSystemd` junto a `AddWindowsService`; registro | 0,15 | A | Enero de 2027 |
| **LN2** | `IProteccionSecretoMaquina` e `IIdentidadProceso`; `AlmacenCredencial` detrás de la costura | 0,3 | A | Enero |
| **LN3** | `ICanalLocal` (introspección, reenvío, el Kestrel de reportes y el canal de la estación) e `IComprobacionCarpetas` (una interfaz sobre las cuatro copias, sin cambiar su comportamiento) | 0,5 | A | Enero |
| *Punto de control* | El propietario decide si sigue con LS | — | Propietario | Fin de enero |
| **LS1** | Secretos en Linux (C1, C2 y C4); origen de certificados para Linux; prueba de concepto del TPM (C3) | 0,45 | A | Febrero |
| **LS2** | Canal en Linux (C7) | 0,3 | A | Febrero |
| **LS3** | Carpetas en Linux, vector `adr077-carpetas-linux.v1.json` y verificador para el `postinst` (C8 y C9) | 0,3 | A | Febrero |
| **LS4** | SQL Server en Linux (bloque D), H-L4 y la suite `GPOS.Tests` contra SQL Server para Linux | 0,4 | A, con arquitecto-datos | Marzo |
| **LS5** | Paquetes, unidades endurecidas, nginx, fuentes, guía y guion de implantación; ensayo de implantación; revisión del auditor-seguridad y QA | 0,8 | devops (B), auditor y QA | Marzo |
| **LC1** | Kit de conectores: transporte por socket Unix y ADR-75 en Linux | 0,3 | Repositorio del kit | Marzo |
| **LC2** | Conectores AdmCloud e IQS en Linux (Polaris, +0,2) | 0,3 a 0,5 | Repositorios de los conectores | Marzo y abril |
| **LC3** | Backup Tool en Linux (H-L5) | 0,2 | Repositorio de Backup Tool | Marzo |
| **LA1** | Agente para varios destinos y núcleo neutro, junto con el consumidor de la cola de ADR-114 | 0,25 | Quien construya 3b | Tramo 3b |
| **LA2** | Estación en Linux (servicio, credencial, canal y carpetas) | 0,3 | Ídem | Tramo 3b |
| **LA3** | Impresión con CUPS | 0,3 | Ídem | Tramo 3b |
| **LA4** | Paquetes x64 y arm64, guía, QA con dos impresoras térmicas y revisión de seguridad | 0,3 | devops y QA | Tramo 3b |
| *LA5 (opcional)* | Modo de escritorio en Linux | 0,15 | — | A pedido |
| **Total** | | **≈ 5,3 sp** (3,9 a 6,9) | | |

Por bloques: neutralización ≈ 0,95 sp, servidor Linux ≈ 2,25 sp, conectores y herramientas ≈ 0,8 a 1,0 sp, agente ≈ 1,15 sp.

**Costo de infraestructura:**
- USD 0 en licencias (Ubuntu).
- Un equipo de pruebas Linux con TPM 2.0: de USD 250 a 400 una vez, o una máquina virtual de USD 20 a 40 al mes. **Lo provee el propietario**, porque los agentes no instalan nada en su PC.
- Para LA4, una Raspberry Pi 5 (unos USD 100 con fuente y tarjeta) y una impresora térmica.

Todas las cifras son *inferidas*.

**Lo que se descarta y cuánto ahorra:** contenedores (0 sp ahorrados: suman costo), RHEL desde el inicio (ahorra 0,5 sp) y Avanzada en Linux (ahorra de 0,5 a 0,8 sp).

## 7. Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| `OpenKeyFromProvider` con el proveedor `tpm2` no admite RSA-OAEP-SHA256 en un TPM concreto | Prueba de concepto en LS1 antes de comprometer C3. H-17 v2 ya prevé la vía ECDH P-256 con la KDF de SP 800-56C. Reserva: PKCS#11 |
| El proveedor `tpm2` no funciona con el modo FIPS de OpenSSL | Avanzada en Linux aplazada (PL-10 (a)) |
| Diferencias visibles en los PDF por las fuentes | Liberation (métricas compatibles) y la puerta de regresión de ADR-110 con tolerancia. Si un formato no pasa, se ajusta la plantilla, no el motor |
| Chromium sin aislamiento dentro de un servicio (Ubuntu 24.04 restringe los espacios de nombres de usuario sin privilegios; *inferido*) | Perfil de AppArmor para el navegador, o el renderizador de ADR-110. **Nunca** `--no-sandbox` en Release sin firma del propietario |
| Controladores CUPS de las impresoras térmicas | QA con dos modelos y una lista de impresoras certificadas; ESC/POS directo como reserva (PL-12 (b)) |
| Los técnicos de GSF conocen poco Linux | Guía, guion de implantación, ensayo y un técnico formado antes del primer cliente Linux |
| La matriz doble alarga los ciclos de pruebas | La suite diaria sigue en Windows. En Linux se corre en LS y antes de cada publicación Linux |
| SQL Server 2025 no está admitido en la distribución elegida | Se verifica al empezar LS4; si no lo está, SQL Server 2022 |
| Código nuevo que se salta las costuras | PL-02, CA1416 como error y la prueba de arquitectura |
| `SO_PEERCRED` con activación por socket devuelve el PID 1 | No se usa la activación por socket en los canales con identidad (C7) |
| No hay equipo de pruebas Linux | LS no empieza sin él (supuesto 10) |
| **Residual aceptado:** root o el administrador local (actor A3) | Igual que en Windows (ADR-75, H-17 v2 y ADR-82) |
| **Residual aceptado:** estación sin TPM | Credencial revocable, con un solo permiso y sin datos personales (C5) |

## 8. Recomendación

**Aprobar** PL-01 (a) a PL-15 (a), con el ADR nuevo de la sección 3 y sus precisiones.

**Ahora** solo se construyen H-L1, H-L2 y la costura `ILlaveFirmaTokens` en D2 de DB-7. Todo lo demás va después del corte, con un punto de control del propietario antes del gasto mayor (LS).

## 9. Si el propietario firma / si rechaza

**Si firma:**
- B registra el ADR y las precisiones en `master` y agrega una línea en el «Stack» de `CLAUDE.md`: «Plataformas del servidor: Windows y Linux (ADR-NNN); decidido, no implementado».
- B corrige en `CLAUDE.md` el estado de H-17 v2 (sección 1.1).
- B encarga a A H-L1 y H-L2 (0,05 sp) y lleva `ILlaveFirmaTokens` a D2.
- El arquitecto-software prepara el blueprint de las costuras para enero (0,1 sp).
- El propietario consigue el equipo de pruebas Linux antes de febrero.

**Si rechaza:**
- **PL-01 (b):** solo LN en enero; LS espera al primer cliente Linux. PL-02 sigue siendo conveniente.
- **PL-01 (c):** se recomienda igual corregir H-L1 y H-L2 (falla cerrada fuera de Windows, 0,05 sp), porque hoy son fallas abiertas aunque nadie las alcance.
- **PL-02 (b):** D2 se construye contra CNG y se rehace en LS1 (+0,2 a 0,3 sp).
- **PL-10 (b):** sumar 0,5 a 0,8 sp a LS y el laboratorio de AP-09 en Linux antes de declarar FIPS.
- **PL-14 (b):** no recomendado. Una instalación Linux sin conector no podría emitir e-CF desde el 2026-11-15.

---

## 10. Hoja de firma

### PL-01 · Alcance [Propietario]
- **Recomendación:** (a) Linux se admite como plataforma del servidor y de la estación, con paridad de garantías; Windows sigue igual.
- **Qué rompe:** nada en Windows.
- **A quién afecta:** a GSF, a los equipos A y B y a los repositorios de los conectores.
- **Por qué:** ahorro de licencias y de equipos para el cliente, sin bajar la seguridad.
- **Cómo se migra:** no aplica.
- [ ] (a) recomendada  [ ] (b) solo neutralizar  [ ] (c) no

### PL-02 · Neutralidad desde la firma, y H-L1 y H-L2
- **Recomendación:** (a) costuras en todo código nuevo (en D2 de DB-7, `ILlaveFirmaTokens`) y corrección de H-L1 y H-L2 ahora (unas 0,2 sp en total, repartidas).
- [ ] (a) recomendada  [ ] (b) después del corte

### PL-03 · Momento, secuencia y prioridad [Propietario]
- **Recomendación:** (a) LN en enero de 2027; punto de control; LS y LC en febrero y marzo; agente en 3b. DB-7 siempre antes. La fase B de ADR-81 antes de LS (en paralelo con LN si hay dos equipos).
- **Decisión del propietario:** ¿qué equipo hace LN?
- [ ] (a) recomendada  [ ] (b) después de la entrega 2  [ ] Otra prioridad: ________

### PL-04 · Distribución [Propietario]
- **Recomendación:** (a) Ubuntu Server 24.04 LTS, única para Básica; RHEL solo con Avanzada.
- [ ] (a) recomendada  [ ] (b) RHEL 9 única  [ ] (c) las dos desde el inicio

### PL-05 · Secretos de máquina
- **Recomendación:** (a) credenciales cifradas de systemd (TPM 2.0 si existe; sin TPM, con aviso) y el proveedor `tpm2` para las llaves que deben vivir en el TPM.
- [ ] (a) recomendada  [ ] (b) PKCS#11  [ ] (b′) exigir TPM 2.0 en todo servidor Linux

### PL-06 · Identidad del canal local
- **Recomendación:** (a) sockets Unix en una carpeta de ejecución propia, con `SO_PEERCRED` y usuarios de sistema dedicados.
- [ ] (a) recomendada  [ ] (b) TCP con TLS mutuo

### PL-07 · Carpetas protegidas y vector Linux
- **Recomendación:** (a) rutas FHS, modos POSIX, aislamiento de systemd, vector `adr077-carpetas-linux.v1.json` y sin `StateDirectory=`.
- [ ] (a) recomendada  [ ] (b) todo bajo `/opt/gpos-ng`

### PL-08 · SQL Server en Linux
- **Recomendación:** (a) variante S siempre, login `gpos_srv_reportes` y login SQL nominal del técnico para `GPOS.Migracion`; mismas ediciones que fija ADR-54.
- [ ] (a) recomendada  [ ] (b) Active Directory con Kerberos

### PL-09 · Paquetes y actualización
- **Recomendación:** (a) `.deb` autocontenidos (nfpm) por el canal del manifiesto firmado, con SHA-256 y firma separada.
- [ ] (a) recomendada  [ ] (b) guion sobre `.tar.gz`  [ ] (c) contenedores

### PL-10 · FIPS y perfil Avanzada [Propietario]
- **Recomendación:** (a) Linux solo con Básica hasta que un cliente pida Avanzada en Linux; entonces RHEL o Ubuntu Pro FIPS, TPM 2.0, LUKS2 y laboratorio.
- [ ] (a) recomendada  [ ] (b) Avanzada en Linux desde la primera versión

### PL-11 · Agente de impresión en Linux [Propietario]
- **Recomendación:** (a) modo estación, x64 y arm64, en la entrega 3 (tramo 3b), junto con la cola; el modo de escritorio solo a pedido.
- [ ] (a) entrega 3, tramo 3b  [ ] (b) entrega 2  [ ] (c) los dos modos a la vez

### PL-12 · Forma de imprimir
- **Recomendación:** (a) CUPS con el mismo PDF; ESC/POS directo como opción posterior.
- [ ] (a) recomendada  [ ] (b) ESC/POS directo para las comandas desde el inicio

### PL-13 · Estructura de proyectos
- **Recomendación:** (a) varios destinos en los proyectos existentes, sin proyectos nuevos.
- [ ] (a) recomendada  [ ] (b) proyectos por plataforma

### PL-14 · Conectores [Propietario]
- **Recomendación:** (a) una instalación Linux se publica solo con el conector de e-CF de la empresa en versión Linux; precisión de ADR-75 para Linux.
- [ ] (a) recomendada  [ ] (b) publicar sin conectores

### PL-15 · Figura
- **Recomendación:** (a) ADR nuevo, con el número que asigne B al registrarlo en `master`, y las precisiones de la sección 3.
- [ ] (a) recomendada  [ ] (b) solo precisiones

**Respuesta del propietario** (fecha, sesión y texto literal):

> ____________________________________________________________

---

### Supuestos
1. En Unix, .NET resuelve `SpecialFolder.CommonApplicationData` a `/usr/share`, y `LocalMachine\My` no se puede usar (solo `Root` y `CA` en el almacén de máquina). *Inferido* del comportamiento de .NET en Unix; no se probó.
2. `SafeEvpPKeyHandle.OpenKeyFromProvider` existe en .NET 10 (llegó en .NET 9). *Inferido*; lo confirma la prueba de concepto de LS1.
3. systemd ≥ 252 trae `LoadCredentialEncrypted=` y `systemd-creds` con TPM 2.0; Ubuntu 24.04 trae la 255. *Inferido* de la documentación de systemd.
4. `Socket.GetRawSocketOption` sirve para leer `SO_PEERCRED` en Linux sin P/Invoke. *Inferido.*
5. Las ediciones, las funciones ausentes y las distribuciones admitidas de SQL Server para Linux son las de la documentación de Microsoft. Se verifican en LS4.
6. Los precios (Windows Server, RHEL, Ubuntu Pro y equipos) son referencias; se verifican con el distribuidor local.
7. SQL Server en Linux traduce `\` en las rutas (H-L4). *Inferido*; se prueba en LS4.
8. El formateador de systemd de .NET conserva el EventId en la línea del registro. *Inferido.*
9. Las fechas de la etapa prudente y de las entregas 2 y 3 no están fijadas. Tomé «después del corte» como enero de 2027.
10. El propietario provee el equipo o la máquina virtual de pruebas Linux: los agentes no instalan programas en su PC.

### Entregas a otros agentes
- **B (coordinador) y documentador-tecnico:** registrar el ADR y las precisiones en `master`, y corregir el estado de H-17 v2 en `CLAUDE.md`.
- **arquitecto-software:** blueprint de las costuras de LN (interfaces, su ubicación en `GPOS.Comun` y la prueba de arquitectura).
- **arquitecto-integraciones:** el mecanismo exacto de ADR-75 en Linux (bloque G) y el transporte del kit.
- **arquitecto-datos:** SQL Server en Linux (intercalación, H-L4, `gpos_srv_reportes` y la matriz de versiones).
- **devops:** paquetes con nfpm, unidades y vectores, nginx, guía y guion de implantación, y temporizadores.
- **auditor-seguridad:** revisar las equivalencias C1 a C17 antes de LS5 y LA4, y confirmar la severidad de H-L1 y H-L2.
- **QA:** matriz Linux e impresoras térmicas.
- **desarrollador-backend (A):** H-L1 y H-L2.
- **Repositorio de Backup Tool:** H-L5.
- **Equipo B (D2 de DB-7):** `ILlaveFirmaTokens`.

### Nota de preparación
Este documento lo preparó el **Arquitecto Maestro del equipo C**. Es una propuesta y no tiene efecto hasta que el propietario la firme. **B lo registra en `master`** cuando el propietario firme: según la regla del área común, los ADR se registran solo en `master`, y C no une ni registra.
