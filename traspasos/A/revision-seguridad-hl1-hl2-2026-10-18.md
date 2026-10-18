# Informe de seguridad: H-L1 y H-L2 (falla cerrada fuera de Windows)

- **Fecha:** 2026-10-18 · **Revisor:** auditor-seguridad (A)
- **Objeto:** commit `66672501` (rama `a/hl-falla-cerrada-linux`), base `322b21d6`; `git diff 322b21d6..66672501`
- **Encargo:** PL-02 (a) (propuesta `traspasos/C/propuesta-adr-plataforma-linux-2026-10-18.md`, sección 1.3 y líneas 77-82; aviso `avisos/B-a-A/2026-10-18-encargo-h-l1-h-l2.md`)
- **Recomendación:** **Aprobado con observaciones** (recomendación técnica; la unión la decide B y la firma el propietario)

## 1. Alcance y superficie revisada

Archivos del cambio: `CarpetaAnillo.cs`, `OrigenCertificadosAnillo.cs`, `ProteccionDatosInstalacion.cs`, `AlmacenLicenciaDisco.cs` (GPOS.Core), `ProteccionDatosWeb.cs` y `GPOS.Web.csproj` (GPOS.Web), y tres archivos de pruebas nuevos.

Búsqueda de vías alternativas en todo `src/` del commit (`git grep`): `AddDataProtection`, `PersistKeysTo*`, `ProtectKeysWith*`, `DataProtectionProvider.Create`, `Ephemeral*`, `AnilloDataProtection.Registrar`, `ProveedorSoloLectura`, `new CarpetaAnillo`, `CarpetaAnillo.Comprobar/Crear`, `AlmacenLicenciaDisco`, `.Preparar()`, `Directory.CreateDirectory`, `DirectoryInfo.Create(...)`.

Puntos de arranque comprobados: API (`src/GPOS.Api/Program.cs:38` → `ProteccionDatos.cs:17` → `ProteccionDatosInstalacion.Configurar`), Web (`src/GPOS.Web/Program.cs:12`), GPOS.Migracion (`ComandosAnillo.cs:30`, `EmpresasSistema.cs:31`).

**No ejecutado:** compilación y pruebas (límite de la PC A de dos agentes con actividad pesada). Todo lo que sigue es por lectura del código del commit.

## 2. Tabla resumen

| ID | Severidad | Título |
|---|---|---|
| SEG-HL-01 | Baja | La prueba de arquitectura no exige que los programas llamen al `Configurar` con guarda, y su expresión no cubre `DataProtectionProvider.Create` |
| SEG-HL-02 | Baja | `PadronSellos.EscribirDisco` omite `Preparar` si la carpeta existe y no captura `PlatformNotSupportedException` (residual declarado, hoy inalcanzable) |
| SEG-HL-03 | Baja | Las escrituras de `AlmacenLicenciaDisco` no dependen de `Preparar`; fuera de Windows los archivos tendrían los permisos por omisión (residual declarado, hoy inalcanzable) |
| SEG-HL-04 | Baja | Las pruebas de «en Windows sigue igual» son débiles (una compara dos colecciones vacías) |
| SEG-HL-05 | Informativa | `InternalsVisibleTo GPOS.Web.Tests` en el ensamblado de producción: aceptable |

Ningún hallazgo Crítico ni Alto.

## 3. Checklist OWASP (acotado al cambio)

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | Mejora: fuera de Windows ya no se crean carpetas con permisos por omisión ni se dan por conformes (`CarpetaAnillo.cs:38,54`; `AlmacenLicenciaDisco.cs:89-90`) |
| A02 Fallas criptográficas | Mejora: se cierra la vía de llaves sin cifrar en el perfil fuera de Windows (H-L1) (`ProteccionDatosInstalacion.cs:55-56`; `ProteccionDatosWeb.cs:62-63`) |
| A03 Inyección | No aplica |
| A04 Diseño inseguro | Correcto: falla cerrada antes de registrar nada (las pruebas comprueban `Assert.Empty(servicios)`) |
| A05 Configuración | Correcto: la costura `esWindows` no es configurable y solo endurece (ver 4, decisión 2) |
| A06 Componentes vulnerables | No aplica (sin paquetes nuevos) |
| A07 Autenticación | No aplica directamente (las cookies de la Web dependen del anillo: sin anillo, no arranca) |
| A08 Integridad | Sin cambio en Windows; fuera de Windows no hay arranque |
| A09 Registro y monitoreo | Mensajes sin rutas ni secretos (ver 5) |
| A10 SSRF | No aplica |

## 4. Hallazgos

### SEG-HL-01 · Baja · La prueba de arquitectura no ata los programas al `Configurar` con guarda
- **Riesgo:** ASP.NET Core registra Data Protection de forma implícita (`AddRazorComponents`, antifalsificación, cookies, JWT). Si un cambio futuro quitara o moviera la llamada a `ProteccionDatos(Web).Configurar`, en Linux las llaves irían sin cifrar a `~/.aspnet/DataProtection-Keys` (H-L1 reabierto) y ninguna prueba lo detectaría. Además la expresión de la prueba busca solo `AddDataProtection(`; un `DataProtectionProvider.Create(...)` (paquete `Extensions`, que persiste en disco) la eludiría. Hoy no existe ninguno (verificado por `git grep`).
- **Evidencia:** `tests/GPOS.Tests/Arquitectura/AnilloFueraDeWindowsArquitecturaTests.cs:53-60` (solo `AddDataProtection` y `AnilloDataProtection.Registrar`); `src/GPOS.Api/Program.cs:38`; `src/GPOS.Web/Program.cs:12`.
- **Remediación (0,01 sp):** agregar a la prueba de arquitectura (a) que `GPOS.Api/Program.cs` y `GPOS.Web/Program.cs` contienen la llamada a `Configurar` antes de `builder.Build()`, y (b) `DataProtectionProvider\.Create\s*\(` y `PersistKeysTo\w+\s*\(` a la lista vigilada.

### SEG-HL-02 · Baja · `PadronSellos.EscribirDisco` (residual declarado)
- **Riesgo:** `Preparar` solo se llama si la carpeta no existe; si existe (creada por otro con permisos por omisión), fuera de Windows se escribiría el padrón sin comprobación. Si no existe, la `PlatformNotSupportedException` no está en el filtro y saldría después del commit en la base. **Verificado inalcanzable hoy:** el padrón exige un `IDataProtectionProvider`, que solo se obtiene de los `Configurar` con guarda (API `Program.cs:285-287`; Migración `ComandoSellos.cs:63-76`, que recibe el proveedor de `EmpresasSistema.Proveedor`/`ComandosAnillo`).
- **Evidencia:** `src/GPOS.Core/Sistema/Usuarios/PadronSellos.cs:439` y `:447`.
- **Remediación (tanda LN):** comprobar la plataforma/carpeta antes del commit de la base (o llamar siempre a `Preparar`, idempotente), no dentro de `EscribirDisco`. No hace falta en este commit.

### SEG-HL-03 · Baja · Escrituras de la licencia sin depender de `Preparar` (residual declarado)
- **Riesgo:** `EscribirAtomico` (vigente, protegidos, sellos, procesados) escribe en la carpeta si existe, sin pasar por `Preparar`; fuera de Windows los archivos quedarían con el `umask` del proceso. **Inalcanzable hoy:** `EstadoLicenciaService.ArrancarAsync` llama primero a `Preparar` (`EstadoLicenciaService.cs:236`), que ahora lanza, y los demás usos requieren el proveedor de Data Protection con guarda.
- **Evidencia:** `src/GPOS.Core/Sistema/Licencia/AlmacenLicenciaDisco.cs:200-205`.
- **Remediación (tanda LN, junto al vector de ADR-77 para Linux):** crear los archivos con `UnixCreateMode` 0600 o `File.SetUnixFileMode` y comprobar dueño/modo de la carpeta antes de escribir.

### SEG-HL-04 · Baja · Pruebas de equivalencia en Windows débiles
- **Riesgo:** de verificación, no de explotación. `HL1_en_Windows_la_Web_sigue_igual` usa DEMO sin carpeta; en esa rama `ProteccionDatosWeb.Configurar` no registra nada (`ProteccionDatosWeb.cs:83`), así que compara dos colecciones vacías. Las de API y Web comparan la sobrecarga pública con la costura, no con el comportamiento previo. La identidad del camino Windows la establecí por lectura del diff (ver 5), no por las pruebas.
- **Evidencia:** `tests/GPOS.Web.Tests/AnilloWebFueraDeWindowsTests.cs:41-50`; `tests/GPOS.Tests/Criptografia/Anillo/AnilloFueraDeWindowsTests.cs:48-60`.
- **Remediación (0,01 sp):** en la de la Web usar carpeta configurada y comprobar que hay un registro de `IConfigureOptions<KeyManagementOptions>`/`IXmlRepository`; opcional en la API, comprobar el tipo concreto de repositorio. Las pruebas de falla cerrada (combinaciones con `esWindows: false`, `Assert.Empty(servicios)`, carpeta no creada) sí demuestran lo pedido.

### SEG-HL-05 · Informativa · `InternalsVisibleTo GPOS.Web.Tests`
- **Valoración:** aceptable. Es el mismo patrón ya presente en GPOS.Core (`GPOS.Core.csproj:49,51`). Las sobrecargas expuestas solo endurecen (`!esWindows || !OperatingSystem.IsWindows()`), así que un llamador interno no puede relajar la guarda. El acceso por nombre de ensamblado sin firma fuerte solo sirve a código ya cargado en el proceso, que tendría acceso por reflexión de todos modos. Sin remediación.
- **Evidencia:** `src/GPOS.Web/GPOS.Web.csproj:17-20`.

## 5. Controles bien implementados

- **Decisión 1 (negar también con certificado):** correcta y preferible al texto literal. Fuera de Windows `LocalMachine\My` no existe (inferido de la documentación de .NET; coincide con la propuesta, línea 46) y la vía de `ConPrivada` caía en `CurrentUser\My`, que en Unix guarda la privada en el perfil sin la protección aprobada; además la carpeta no se puede comprobar. Negar todo arranque cierra las tres. La guarda en `Buscar` (`OrigenCertificadosAnillo.cs:113-114`) es una segunda capa coherente.
- **Decisión 2 (costura):** monótona; con `true` fuera de Windows también rechaza (`CarpetaAnillo.cs:38,54`; `ProteccionDatosInstalacion.cs:55`; `ProteccionDatosWeb.cs:62`; `AlmacenLicenciaDisco.cs:89`). La guarda es la primera instrucción en todos, antes de `AddDataProtection` y antes de crear directorios.
- **Sin vías que eludan la guarda (verificado):** `AddDataProtection` solo en `ProteccionDatosInstalacion.cs:57`, `ProteccionDatosWeb.cs:73,84` (tras la guarda) y `AnilloDataProtection.ProveedorSoloLectura` (`AnilloDataProtection.cs:277`: en memoria, sin carpeta, cifrador que se niega; solo se invoca con un origen obtenido de un proveedor ya configurado: `ComprobacionAnillo.cs:96`, `RecuperarAnillo.cs:78`). `AnilloDataProtection.Registrar` solo desde los dos `Configurar`, y aun llamado directamente, su `CarpetaAnillo.Crear()` lanza. Los `Directory.CreateDirectory` restantes de `src/` (AgenteImpresion, ConvertidorPdf, ImpresionDirecta, Reportes) no tocan el anillo ni la licencia. Las capturas de GPOS.Migracion convierten la excepción en `ReglaNegocioException` y abortan (`ComandosAnillo.cs:32-35`; `EmpresasSistema.cs:33-36`); `ComandoSellos.LicenciaVigenteAsync` solo captura `LicenciaArranqueException`, de modo que la nueva excepción de `Preparar` se propaga (falla cerrada).
- **Defensa en profundidad:** en Amplio, una carpeta no conforme solo se registra (`ComprobacionAnillo.cs:133-137`; `ProteccionDatosWeb.cs:108-111`), pero fuera de Windows no se llega ahí: lo cortan `Configurar` y, debajo, `Crear`.
- **Camino Windows idéntico (verificado por el diff):** `Crear` (existe → retorna; crea el padre; `Create(Seguridad())`), `Comprobar` (reanálisis → motivo; `ComprobarDacl`), `Preparar`/`CrearProtegida` y `Buscar` ejecutan las mismas instrucciones; las ramas eliminadas (`if (!OperatingSystem.IsWindows()) throw` dentro de la carpeta y las alternativas Unix) eran inalcanzables en Windows. `[SupportedOSPlatform("windows")]` en `CrearProtegida` solo afecta al analizador.
- **Mensajes:** las constantes nuevas no incluyen rutas, huellas ni configuración; solo nombran el almacén genérico `LocalMachine\My` y las referencias H-L/ADR. El mensaje anterior de la Web citaba la clave de configuración; el nuevo no filtra más. El mensaje preexistente de `Principal` (12 caracteres de la huella pública) no cambia.

## 6. Remediaciones priorizadas

1. SEG-HL-01 (0,01 sp, antes o junto a la unión; no bloquea).
2. SEG-HL-04 (0,01 sp, misma tanda).
3. SEG-HL-02 y SEG-HL-03 en la tanda LN, con el vector de ADR-77 para Linux (permisos de archivos, dueño, comprobación antes del commit).
4. H-L3 y H-L5 siguen fuera de este commit, como declara el desarrollador (LN1 y repositorio de Backup Tool).

## 7. Recomendación

**Aprobado con observaciones.** El objetivo de H-L1 y H-L2 se cumple: fuera de Windows ninguna configuración de la API, la Web ni GPOS.Migracion registra Data Protection, y `CarpetaAnillo.Crear/Comprobar` y `AlmacenLicenciaDisco.Preparar` fallan cerradas; en Windows el comportamiento no cambia. Las observaciones son de cobertura de pruebas y residuales ya declarados, hoy inalcanzables. Falta confirmar la compilación y las pruebas dirigidas (no ejecutadas en esta revisión).
