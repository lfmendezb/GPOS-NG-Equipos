# Informe de seguridad: O-1 (acción previa de ADR-77, punto 3) y O-3 (raíz y config\ con GUID fijos)

- **Fecha:** 2026-10-20 · **Agente:** auditor-seguridad (equipo A) · **Estado de la decisión:** recomendación técnica; la decisión es del propietario (Pendiente de firma).
- **Objeto:** rama `a/instalador-o1-o3` en `C:\Users\lfmen\source\repos\GPOS-NG-o1`, commits `41fdcc03` (O-1) y `57af7d9d` (O-3), contra `origin/feature/modelo-ng`.
- **Método:** solo lectura (`git log`, `git diff`, `git show`, lectura de archivos). No compilé, no ejecuté pruebas, no cambié de rama ni ejecuté MSI ni nada elevado. **[V]** significa verificado leyendo el código, con cita `archivo:línea`. **[I]** significa inferido: hay que confirmarlo en laboratorio.
- **Contratos:** blueprint v2 de A (`traspasos/A/blueprint-instalador-o1-o3-n10-2026-10-20.md`), respuestas de B (`traspasos/B/2026-10-20-respuestas-b-a-los-planos-de-a.md`), ADR-77 con sus precisiones y el vector v2 (`origin/master`), vector v3 de la rama, ADR-33.
- **Rutas citadas** (relativas a la raíz de `GPOS-NG-o1`):
  - **CCP** = `instalador/Comun/GPOS.Instalador.Acciones/ComprobacionCarpetasPrevias.cs`
  - **AI** = `instalador/Comun/GPOS.Instalador.Acciones/AccionesInstalador.cs`
  - **CSPROJ** = `instalador/Comun/GPOS.Instalador.Acciones/GPOS.Instalador.Acciones.csproj`
  - **FCP** = `instalador/Comun/Fragmentos/ComprobacionCarpetasPrevias.wxs`
  - **FRZ** = `instalador/Comun/Fragmentos/RaizGposNg.wxs`
  - **PKG** = `instalador/AgenteImpresion/Package.wxs`
  - **V3** = `docs/contratos/vectores/adr077-carpetas.v3.json`

## 1. Alcance y superficie revisada

| Superficie | Qué se revisó |
|---|---|
| Acción inmediata `GposPrepararCarpetasPrevias` (corre como el servicio MSI, sin tocar el disco) | Lectura de la tabla `GposCarpetaPrevia`, resolución de directorios y serialización de `CustomActionData` (AI:21-58; CCP:241-296) |
| Acción diferida `GposComprobarCarpetasPrevias` (SYSTEM, sin suplantación) | Apertura sin seguir el punto de reanálisis, lectura del descriptor por identificador, evaluación de las ACE, creación de la raíz, falla cerrada, eventos y error 25101 (AI:66-158; CCP:298-617) |
| Esquema WiX | `Binary`, acciones, tabla propia, error 25101 y secuencia (FCP:26-50); componentes `RaizGposNg` y `ConfigGposNg` con `Permanent="yes"` y GUID fijos (FRZ:21-54) |
| Consumidor | MSI del agente o estación de impresión, solo en la compilación de desarrollo (PKG:93-162; `construir.ps1:50`, `:95-99`) |
| Cadena de firma | Firma interna en CSPROJ:54-60; `construir.ps1` |
| Vector v3 y pruebas | V3:204-244; `tests/GPOS.Tests/Instalador/*.cs` |

Fuera de la superficie: endpoints, tenants y SQL (no aplican). El *bundle* y los MSI de Api, Web y Reportes no existen todavía; se revisan sus futuras filas solo como riesgo latente.

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título | Tipo |
|---|---|---|---|
| S-01 | Media | La tabla no garantiza la cadena completa de padres, una sola raíz ni que todas las filas estén bajo la raíz. Los directorios intermedios se recorren siguiendo los puntos de reanálisis | [V], latente |
| S-02 | Media | TOCTOU con el servicio todavía en marcha: no se impide que haya una fila debajo de una carpeta en la que escribe un servicio | [V] diseño, latente |
| S-03 | Media | Con la directiva FIPS activa, la huella SHA-256 del evento 4755 puede lanzar una excepción y hacer fallar la primera instalación después de crear la raíz | [I], confirmar en laboratorio |
| S-04 | Media | La `.CA.dll` exterior no se firma en `construir.ps1` (P-O1-6), y el `.wixproj` la toma de `bin` sin verificar la firma | [V], contenido por K1-02 |
| S-05 | Baja | `ESTACION_DATOS` es un directorio público (todo en mayúsculas): se puede redirigir y la acción no lo acota a la raíz | [V] |
| S-06 | Baja | La acción corre y crea la raíz aunque no se instale la *feature* que declara los componentes | [V] |
| S-07 | Baja | GUID con patrón no aleatorio (`…0A1B2C3D4E5F`) en un componente `Permanent` compartido entre productos | [V] |
| S-08 | Baja | Consecuencias de `Permanent="yes"` con GUID compartido: residuo permanente, deriva del SDDL entre MSI y repositorios, IQ 0.4.1 sin `Permanent` | [V] |
| S-09 | Baja | No hay prueba con uniones reales (P-O1-2); el reanálisis solo se prueba con atributos simulados | [V] |
| S-10 | Baja | El mensaje «No se modificó / no se cambió nada» puede ser falso si la raíz se creó en esa misma ejecución; no hay reversión de la raíz | [V] |
| S-11 | Baja | Si el MSI del agente se instala solo, no deja eventos en el Visor (el origen `GPOS.Instalacion` lo crea `GPOS.Api.msi`) | [V] |

No hay hallazgos Críticos ni Altos.

## 3. Checklist OWASP (adaptado a una acción de instalador)

| Punto | Resultado |
|---|---|
| A01 Control de acceso roto | Revisado. La evaluación de dueño y DACL es correcta y conservadora (sección 5). Brechas latentes en S-01 y S-02 |
| A02 Fallas criptográficas | SHA-1 solo para derivar el SID de la cuenta virtual (es el algoritmo de Windows; no es un uso de seguridad). SHA-256 de la huella: S-03 (FIPS) |
| A03 Inyección | `CustomActionData` usa separadores que no pueden aparecer en una ruta de Windows y valida el servicio (CCP:238-296). La tabla viene del MSI firmado. Las rutas con `..\`, UNC o `\\?\` solo pueden llegar a la acción desde la creación del MSI o desde un directorio público: S-05 |
| A04 Diseño inseguro | S-01 y S-02 |
| A05 Configuración insegura | S-06, S-07 y S-08 |
| A06 Componentes vulnerables | WiX DTF 5.0.2 (CSPROJ:33-34). No ejecuté ninguna herramienta de dependencias. Las CVE de WiX de 2024 (CVE-2024-29187: Burn como SYSTEM; CVE-2024-29188: extracción de CAB) quedaron corregidas en 4.0.5 y la rama 5 [I] y afectan a Burn, no a esta acción. Hay que revisarlas de nuevo cuando exista el *bundle* |
| A07 Autenticación | No aplica |
| A08 Integridad del software | S-04 (firma de la `.CA.dll`). SfxCA extrae la DLL en la carpeta temporal del servicio MSI (`%windir%\Installer`), que solo pueden escribir los administradores [I] |
| A09 Registro y monitoreo | Hay una línea por carpeta en el registro del MSI. Los eventos 4753 a 4755 solo se escriben si existe el origen: S-11. No se registran secretos |
| A10 SSRF | No aplica. Una ruta UNC solo puede llegar por S-05 |
| Aislamiento entre tenants | No aplica (acción de máquina, sin datos de empresa) |
| Secretos | Ninguno en el código, el fragmento ni el vector. La firma usa solo la huella del certificado y el PIN lo pide el token (CSPROJ:49-60) |

## 4. Hallazgos

### S-01 · Media · La tabla no garantiza la cadena de padres y los intermedios se siguen

- **Riesgo.**
  - `CreateFileW` con `FILE_FLAG_OPEN_REPARSE_POINT` solo deja de seguir el reanálisis en el **último** componente de la ruta. Los intermedios se recorren siguiendo uniones y vínculos.
  - El vector exige comprobar «que ninguno de sus padres es un punto de reanálisis» (V3:122). La implementación lo reduce a «ninguno de sus padres **de la tabla**» (CCP:139).
  - `Ordenar` solo comprueba que ningún hijo vaya antes que su padre y que no haya filas repetidas (CCP:303-343). No exige:
    - que exista exactamente una fila con `CrearSiFalta=1` (se acepta cero: CCP:318-326);
    - que toda otra fila esté debajo de la raíz;
    - que cada antepasado entre la raíz y la fila tenga su propia fila.
  - Con un directorio intermedio sin fila y escribible por un servicio, la comprobación de la hija leería los atributos y la DACL del **destino** de una unión (por ejemplo, una carpeta del sistema que pasa la lista blanca). Después `CreateFolders` aplicaría la DACL de la fila a través de la unión.
- **Estado.** Hoy no se puede explotar: las tres filas del agente forman la cadena completa: raíz, `config\` y `EstacionImpresion` (FRZ:41-54; PKG:150-158). La prueba P-O1-3 lo comprueba para este MSI (`FragmentosInstaladorTests.cs:206-240`). El riesgo aparece cuando Api, Web y Reportes agreguen sus filas.
- **Evidencia:** CCP:139, :303-343, :431-432; V3:122.
- **Remediación** (unos 0,25 dp, ±50 %):
  1. En `Ordenar`, rechazar con `SEGURIDAD_ILEGIBLE` en estos casos:
     - (a) el número de filas con `CrearSiFalta=1` es distinto de 1;
     - (b) una fila no desciende de la raíz;
     - (c) a una fila le falta la fila de algún antepasado entre ella y la raíz.
  2. **Defensa en profundidad:** después de abrir, llamar a `GetFinalPathNameByHandleW` (`FILE_NAME_NORMALIZED`, `VOLUME_NAME_DOS`) y comparar el resultado con la ruta pedida, sin distinguir mayúsculas y sin el prefijo `\\?\`. Si no coinciden, `PUNTO_DE_REANALISIS`. Cubre también los antepasados que están fuera de la tabla (`C:\ProgramData`).
  - **Alternativa descartada:** abrir cada componente de la ruta con `NtCreateFile` relativo al identificador del padre. Es más robusto, pero cuesta unos 1,5 dp y suma código nativo, sin una ganancia proporcional una vez aplicados los puntos 1 y 2.

### S-02 · Media · TOCTOU con el servicio en marcha bajo carpetas en las que escribe

- **Riesgo.**
  - La acción va antes de `StopServices` (FCP:49-50; blueprint 1.3). En una reparación o una actualización menor, el servicio sigue en marcha entre la comprobación y `CreateFolders`.
  - Si una fila está **debajo** de una carpeta en la que escribe un servicio, ese servicio, si está comprometido, puede sustituir la hija por una unión después de la comprobación. Windows Installer aplicaría entonces la DACL de la fila sobre el destino. Es una escalada desde la cuenta virtual hasta un cambio de ACL hecho como SYSTEM.
  - **Hoy no ocurre:** `EstacionImpresion` es una hoja y su padre (la raíz) no admite al servicio (PKG:131-133, :150-158). Es probable que aparezca con la fila del anillo de la Web (`Servicio = GPOS.Web`, HB-16) si el anillo cuelga de la carpeta de la Web [I].
- **Evidencia:** FCP:49-50; CCP:546-550 (el escritor de servicio se admite por fila, sin restricción de posición); blueprint v2, 1.3 (fila del anillo de la Web).
- **Remediación** (unos 0,1 dp): en `Ordenar`, rechazar toda fila que sea descendiente de una fila con `Servicio`. Las carpetas en las que escribe un servicio deben ser hojas en la tabla. Si el anillo de la Web tiene que ir debajo, se declara como hermana: `…\GPOS NG\Web` y `…\GPOS NG\Web-Anillo`, o el servicio la crea en tiempo de ejecución según P-77-2 y queda fuera de la tabla por `noDeclara`.
  - **Alternativa descartada:** comprobar de nuevo después de `StopServices`. Duplica la acción y sigue dejando una ventana mientras otros procesos del componente están en marcha.

### S-03 · Media · FIPS: la huella del evento 4755 puede romper la primera instalación [I]

- **Riesgo.**
  - `HuellaSddl` usa `SHA256.Create()` (CCP:231-235). En .NET Framework, por omisión eso devuelve `SHA256Managed` [I]. Con la directiva «Usar algoritmos compatibles con FIPS» activa, ese tipo lanza `InvalidOperationException` cuando el dominio de aplicación se trata como anterior a 4.8 [I].
  - Es lo esperable en el dominio que crea SfxCA, porque `CustomAction.config` declara `supportedRuntime version="v4.0"` sin `sku`.
  - La huella se calcula **antes** de entrar en el `try` de `Evento`, dentro del *callback* `alCrear` (AI:82-85). La excepción la recoge el `catch` general (AI:88-93) y produce `SEGURIDAD_ILEGIBLE` en «(comprobación)». Resultado: 1603 **después de haber creado la raíz**.
  - En el segundo intento la raíz ya existe y la instalación pasa. El fallo confunde el diagnóstico y choca con el perfil Avanzado (FIPS) firmado.
  - Riesgo de disponibilidad, no de confidencialidad. La comprobación sigue cerrada.
- **Evidencia:** CCP:231-235; AI:82-85, :88-93; `CustomAction.config:3-4`.
- **Remediación** (0,1 dp):
  1. La huella es la de una constante. Se publica como constante literal (comprobada contra `raiz.sddl` del vector en P-O1-4) o se calcula con `SHA256CryptoServiceProvider` bajo `#if NETFRAMEWORK`.
  2. El texto del evento se construye dentro del `try` de `Evento`, para que nada del evento pueda cambiar el veredicto.
  3. Agregar `sku=".NETFramework,Version=v4.7.2"` a `supportedRuntime` [I: confirmar con SfxCA].
  4. Agregar a P-O1-7 un caso con la directiva FIPS activa.

### S-04 · Media · Firma de la `.CA.dll` sin implementar (P-O1-6)

- **Riesgo.**
  - ADR-33 exige que todo ejecutable distribuido lleve firma Authenticode con sello de tiempo. ADR-77 lo extiende a la DLL de cada instalador.
  - La firma interna solo ocurre si se pasa `SigntoolFirma` (CSPROJ:54-60). `construir.ps1` compila la acción **sin** esas propiedades (`construir.ps1:96-99`) y no firma la `.CA.dll` exterior.
  - El `.wixproj` toma la DLL de `bin\$(Configuration)\net472` sin verificar la firma (cambio en `GPOS.AgenteImpresion.Instalador.wixproj`, propiedad `GposAcciones`).
  - Una DLL que corre como SYSTEM sin firma no supera WDAC ni AppLocker con reglas de DLL y no deja rastro de su origen.
  - **Contenido hoy:** `-EstacionDesarrollo` no admite `-Firmar` (`construir.ps1:50`), y el MSI normal no enlaza el fragmento (PKG:163-166). Es condición para retirar K1-02.
- **Evidencia:** CSPROJ:54-60; `construir.ps1:50`, `:96-99`, `:106-111`; ADR-33:10-11.
- **Remediación** (0,25 dp). En `construir.ps1 -Firmar`:
  1. Compilar la acción con `-p:SigntoolFirma=… -p:HuellaFirma=… -p:ServidorSelloFirma=…`. La firma interna ocurre antes de `PackCustomAction`.
  2. Firmar la `.CA.dll` exterior con `Firmar-Archivo` **antes** de compilar el `.wixproj`.
  3. Comprobar con `Get-AuthenticodeSignature` que la DLL que entra en el MSI es la firmada, con el mismo certificado.
  4. Fallar si el MSI enlaza `GposAcciones` y la DLL no está firmada.
  5. Registrar la huella SHA-256 de la DLL junto a la del `.msi` (ADR-33).

### S-05 · Baja · `ESTACION_DATOS` es un directorio público

- **Riesgo.**
  - Un `Id` de directorio todo en mayúsculas es una propiedad pública. Quien instala (un administrador, o cualquiera si la política de elevación del equipo está mal configurada) puede pasar `ESTACION_DATOS=<otra ruta>`, incluida una ruta UNC.
  - La acción comprueba la ruta redirigida. Si es una carpeta del sistema con dueño TrustedInstaller y sin escritores ajenos, **pasa**, y `CreateFolders` le aplicaría el SDDL de la estación, que da Modificar a la cuenta virtual.
  - Exige estar ya en posición de administrador, por eso es Baja. El `Id` ya existía antes del cambio; ahora además es entrada de la acción.
- **Evidencia:** PKG:96, :161; CCP:303-343 (no acota a la raíz).
- **Remediación** (0,05 dp): renombrar a un `Id` privado (por ejemplo, `DirEstacionDatos`, actualizando `SetProperty` en PKG:161 y las pruebas). Lo cubre también S-01 (b).

### S-06 · Baja · La acción corre aunque no se instale la *feature* de la raíz

- **Riesgo.** La secuencia solo se condiciona con `NOT REMOVE~="ALL"` (FCP:49-50). Por eso:
  - en una instalación solo del agente (`Agente`), la acción **crea** `%ProgramData%\GPOS NG`, protegida, aunque ningún componente la declare;
  - una carpeta `EstacionImpresion` insegura bloquea la actualización del agente, que no la usa.
  - No abre ninguna puerta, porque la raíz queda protegida, pero deja un residuo y una denegación ajena al cambio.
- **Evidencia:** FCP:49-50; PKG:100, :127.
- **Remediación** (0,1 dp): condicionar las dos acciones en el MSI del agente al estado de la *feature* (`&EstacionImpresion=3 OR !EstacionImpresion=3`). La alternativa es una columna `Condicion` en la tabla, evaluada por la acción inmediata. Si se acepta tal cual, documentarlo en «Carpeta insegura».

### S-07 · Baja · GUID con patrón no aleatorio en un componente `Permanent` compartido

- **Riesgo.**
  - `9E7A0D3C-1F42-4B6E-8C5D-0A1B2C3D4E5F` termina en una secuencia (`0A1B2C3D4E5F`). El de `Conectores` de IQ también (`AF8B1E4D-…-1B2C3D4E5F60`). No parecen salidos de un generador aleatorio.
  - Si otro producto usa el mismo GUID con otra ruta clave, se rompen las reglas de componentes de Windows Installer. Con `Permanent` el problema no se puede corregir después.
  - Probabilidad baja, impacto permanente.
- **Evidencia:** FRZ:28; V3:212; IQ `origin/b/conector-iq-instalador:instalador/GPOS.Conector.Iq.Instalador/Package.wxs:181`, `:186`.
- **Remediación** (unos 0,1 dp en A más la versión de IQ ya prevista por R-O3-4): no hay instalaciones de IQ 0.4.1 fuera del laboratorio [I, blueprint 2.2]. Mientras sea así, cambiar el GUID cuesta casi nada: generar uno con `New-Guid`, publicarlo en el vector (v3 sin publicar todavía, o v4) y que IQ lo adopte en la misma versión en la que agrega `Permanent`. Si se decide conservarlo, dejarlo registrado como riesgo aceptado. *(Fuera de este cambio, PKG:86, :105, :131 y :143 muestran el mismo patrón; conviene revisarlos.)*

### S-08 · Baja · Riesgos de `Permanent="yes"` con GUID compartido

- **Riesgo.**
  1. Desinstalar todos los productos deja la raíz, `config\` y el registro del componente para siempre. Es coherente con conservar los datos de máquina, pero hace falta un procedimiento manual de retiro.
  2. Un cambio futuro del SDDL obliga a cambiar a la vez seis MSI y los conectores, que viven en otros repositorios. Mientras tanto gana el último que instala o repara.
  3. Hasta R-O3-4, IQ 0.4.1 declara el mismo GUID **sin** `Permanent`. Es inofensivo: el cliente «sistema» que registra cualquier MSI con `Permanent` retiene el componente. El contenido es idéntico en los dos lados (mismo SDDL y misma ruta).
  4. **Verificado que no hay riesgo de borrado:** ninguno de los dos componentes lleva `RemoveFolder` ni archivos.
- **Evidencia:** FRZ:28-37; IQ `Package.wxs:181-185`; V3:204-243.
- **Remediación** (0,1 dp, documental):
  - procedimiento de retiro en operaciones;
  - P-O3-5 en IQ y AdmCloud (de B), comparando GUID y SDDL contra el vector;
  - regla en V3: cambiar el SDDL de la raíz exige una nueva versión del vector y la actualización coordinada de todos los consumidores.

### S-09 · Baja · Falta la prueba con uniones reales (P-O1-2)

- **Riesgo.** El caso de reanálisis se prueba solo con atributos simulados en `Decidir`. No hay ninguna prueba que plante una unión real (`mklink /J`, que no requiere elevación) y pase por `ComprobarUna`. Un cambio en las banderas de `CreateFileW`, por ejemplo quitar `FILE_FLAG_OPEN_REPARSE_POINT`, no lo detectaría ninguna prueba.
- **Evidencia:** `tests/GPOS.Tests/Instalador/ComprobacionCarpetasPreviasTests.cs:35-45`. La búsqueda de `mklink|Junction|CreateSymbolicLink` en `tests/GPOS.Tests/Instalador` no encuentra nada.
- **Remediación** (0,25 dp): una prueba con una unión real como hoja (`PUNTO_DE_REANALISIS`), otra como intermedio (rechazo una vez aplicado S-01), otra con una unión a una carpeta que pasa la lista blanca y otra con una raíz plantada como unión (`CrearSiFalta` → 183 → rechazo).

### S-10 · Baja · Texto de «no se cambió nada» y la raíz creada

- **Riesgo.**
  - AI:101 registra «No se modificó ninguna carpeta», y el error 25101 dice «No se cambió nada» (FCP:45).
  - Si la acción creó la raíz en esa misma ejecución y después falla (S-03, o una carrera), el texto es falso. No hay acción de reversión, así que la raíz queda creada y protegida.
  - Es inofensivo para la seguridad, pero engaña a quien diagnostica.
- **Evidencia:** AI:101; FCP:45; CCP:418-429.
- **Remediación** (0,05 dp): si `estado == Creada` antes del rechazo, registrar «se creó la raíz X con su DACL protegida; no se modificó ninguna carpeta existente». Ajustar el texto de 25101. No hace falta revertir la raíz.

### S-11 · Baja · Sin eventos en el Visor cuando el agente se instala solo

- **Riesgo.** La acción solo escribe en el Visor si el origen `GPOS.Instalacion` ya existe (AI:141-157), y ese origen lo crea `GPOS.Api.msi`. En un puesto con solo el agente o la estación, los rechazos 4753 y 4754 y la creación 4755 quedan solo en el registro del MSI, que se pierde si no se pidió `/l*v`. Así lo dice el contrato (blueprint 1.3), pero el monitoreo de la estación pierde visibilidad.
- **Evidencia:** AI:141-157; CCP:164-165.
- **Remediación:** opción sin costo de código: documentar que el instalador de la estación se ejecuta siempre con `/l*v`. Opción de unos 0,1 dp: que el MSI del agente declare el mismo origen con `util:EventSource` (componente compartido con GUID fijo, como la raíz).

## 5. Controles bien implementados [V]

- **CB-4, creación atómica de la raíz:**
  - `CreateDirectoryW` con `SECURITY_ATTRIBUTES` construido desde `SddlRaiz`, en una sola llamada (CCP:600-617);
  - 183 (ya existe) sigue a la comprobación como carpeta existente y cualquier otro error es `SEGURIDAD_ILEGIBLE` (CCP:418-429, :483-484);
  - si la raíz se creó y luego desaparece, falla cerrada (CCP:438-442).
  - Una raíz plantada como unión, vínculo o archivo devuelve 183 y se rechaza al abrirla sin seguirla.
- **Lectura por identificador:** se abre con `FILE_FLAG_OPEN_REPARSE_POINT | FILE_FLAG_BACKUP_SEMANTICS` y solo `READ_CONTROL | FILE_READ_ATTRIBUTES` (CCP:431-432). Los atributos (`GetFileInformationByHandle`) y el descriptor (`GetSecurityInfo`) salen del mismo identificador (CCP:451-468). El reanálisis se evalúa antes que «no es carpeta» y antes de leer la seguridad (CCP:505-513).
- **Evaluación de ACE, fiel al vector:**
  - dueño en la lista blanca, nunca el servicio (CCP:529-538);
  - DACL nula equivale a escritor ajeno (CCP:541-544);
  - toda ACE que no sea `CommonAce` (de objeto, compuesta o desconocida) equivale a escritor ajeno (R-5, CCP:556-559);
  - las denegaciones y las auditorías no cuentan (CCP:561-564);
  - solo se ignora `CREATOR OWNER` (CCP:566-569);
  - `CREATOR GROUP`, `OWNER RIGHTS`, las ACE solo heredables y las ACE condicionales sí cuentan (no se filtran);
  - la máscara `0x500D0156` coincide con el vector (CCP:171; V3:43) e incluye `DELETE` y `FILE_DELETE_CHILD`;
  - el servicio solo es escritor en su propia fila (CCP:546-550).
- **Falla cerrada:**
  - tabla ausente, `GetTargetPath` fallido o servicio no válido detienen la acción inmediata con `Failure` (AI:29-57; CCP:256-259);
  - `CustomActionData` vacío o mal formado lanza `FormatException` (CCP:272-290);
  - una tabla sin filas, con hijos antes que el padre, con filas repetidas, con más de una raíz o con una raíz con servicio es `SEGURIDAD_ILEGIBLE` (CCP:312-340);
  - cualquier excepción es `SEGURIDAD_ILEGIBLE` y 1603 (AI:87-93);
  - un descriptor que no se puede interpretar es ilegible (CCP:465-468, :499-500).
- **Nunca limpia ni cambia el dueño:** la única llamada que escribe es `CreateDirectoryW`. No hay `SetSecurityInfo`, `SetNamedSecurityInfo`, `RemoveDirectory`, `DeleteFile` ni toma de posesión en todo CCP ni en AI (leídos completos).
- **SID de la cuenta virtual:** S-1-5-80 más el SHA-1 del nombre en mayúsculas en UTF-16LE, en cinco enteros sin signo (CCP:204-224). El nombre se valida con un conjunto ASCII cerrado que también impide los separadores (CCP:227-228).
- **Secuencia:** inmediata antes de `InstallInitialize` y diferida después, con `Impersonate="no"` y `Return="check"`, antes de `StopServices` y `CreateFolders`. No corre al desinstalar (FCP:28-31, :49-50). `MajorUpgrade` usa su programación por omisión (después de `InstallValidate`), así que el producto anterior se quita antes de la comprobación.
- **SDDL exacto:** el SDDL de creación, el `PermissionEx` de la raíz y el de `config\` son idénticos a `raiz.sddl` del vector (CCP:168; FRZ:30, :35; V3:30, :213, :224), con la DACL protegida (`P`) y el dueño SYSTEM.
- **EventId:** 4753, 4754 y 4755 en la franja de A. Una prueba comprueba que no chocan con `src` (`FragmentosInstaladorTests.cs:273-282`). La acción no crea el origen.
- **Registro:** prefijo fijo, ruta, código y SID culpable; nunca valores de propiedades ni secretos.
- **Bloqueo K1-02 en vigor:** el MSI normal no contiene la estación y la compilación de desarrollo no se puede firmar (`construir.ps1:50`; PKG:163-166).

## 6. Remediaciones priorizadas

| Prioridad | Hallazgos | Cuándo | Esfuerzo (±50 %) |
|---|---|---|---|
| 1 | S-04 (firma de la `.CA.dll`) y P-O1-7 (laboratorio elevado) | Antes de retirar K1-02 o de firmar cualquier MSI que enlace la acción | 0,25 dp + laboratorio |
| 2 | S-01 y S-02 (invariantes de la tabla y `GetFinalPathNameByHandleW`) | Antes de que Api, Web o Reportes agreguen filas | 0,35 dp |
| 3 | S-03 (FIPS) | Antes de la primera instalación en un equipo con el perfil Avanzado | 0,1 dp |
| 4 | S-09 (pruebas con uniones reales) | Junto con S-01 | 0,25 dp |
| 5 | S-05, S-06, S-10 y S-11 | Antes de la entrega 1 | 0,3 dp |
| 6 | S-07 y S-08 (decisión sobre el GUID y documentación) | Antes de la primera instalación fuera del laboratorio | 0,2 dp más la versión de IQ |

Total: unos 1,45 dp de A (0,7 a 2,2), más lo de B en IQ y AdmCloud, que ya está previsto en R-O3-4. Costo de infraestructura: USD 0.

## 7. Recomendación

**Aprobado con observaciones** (recomendación técnica; la decisión es del propietario). No hay hallazgos Críticos ni Altos. La acción cumple el bloque `comprobacionPrevia` del vector en todo lo que se puede verificar leyendo el código, con una excepción: el texto «ninguno de sus padres» se implementa como «ninguno de sus padres de la tabla» (S-01). Hoy esa diferencia queda cubierta por la composición de la tabla del agente.

Condiciones:
- S-04 y P-O1-7 son requisito para retirar K1-02.
- S-01 y S-02 son requisito antes de que otro MSI agregue filas.
- S-03 es requisito antes de instalar en un equipo con FIPS.

## Supuestos

- No compilé ni ejecuté las pruebas. Tomo como ciertos los resultados que declara el autor de la rama.
- S-03 se basa en el comportamiento documentado de .NET Framework con FIPS (`SHA256Managed` y el interruptor `UseLegacyFipsThrow` de 4.8) y en cómo SfxCA crea su dominio de aplicación. Hay que confirmarlo en el laboratorio con la directiva activa.
- La ubicación de extracción de SfxCA para las acciones diferidas (`%windir%\Installer`) es inferida.
- Que no hay instalaciones de IQ 0.4.1 fuera del laboratorio lo dice el blueprint (2.2) como [I].

## Decisiones candidatas a ADR

- S-07: conservar o cambiar el GUID canónico de la raíz antes de la primera instalación fuera del laboratorio. Opciones: (a) conservar `9E7A0D3C-…` (sin costo, riesgo residual permanente) o (b) regenerarlo y que IQ lo adopte junto con R-O3-4 (unos 0,1 dp más la versión de IQ ya prevista). Recomendada: (b). Le toca al arquitecto maestro.

## Entregas a otros agentes

- **desarrollador (A):** S-01, S-02, S-03, S-05, S-06, S-09, S-10 y S-11.
- **devops (A y B):** S-04 (firma en `construir.ps1` y en los futuros MSI); en Api, Web y Reportes, que las filas cumplan S-01 y S-02; laboratorio P-O1-7 con el caso FIPS de S-03.
- **qa-automatizado:** S-09; caso FIPS en P-O1-7.
- **arquitecto-maestro:** decisión de S-07.
- **B (conectores):** P-O3-5 y, si se firma S-07 (b), el GUID nuevo en IQ y AdmCloud.
