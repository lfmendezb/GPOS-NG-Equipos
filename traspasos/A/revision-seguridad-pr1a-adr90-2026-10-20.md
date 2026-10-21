[Informe de Seguridad] PR-1a de ADR-90 (RT-01, PT-06): `src/GPOS.Comun/Red/*` y pruebas

Fecha: 2026-10-20 · Revisor: auditor-seguridad · Objeto: commit `e840bae3` de la rama `a/adr90-rt01-modo-red` (árbol `GPOS-NG-adr90`), revisado **solo con `git show` y `git grep`**, sin cambiar de rama, sin compilar y sin ejecutar pruebas (había una suite corriendo en ese árbol).
Contratos contrastados: blueprint de A v2 (`traspasos/A/blueprint-adr90-rt01-rt05-rt06-2026-10-20.md`, 4.1 a 5.5, 9 y 11), `docs/seguridad/2026-10-20-revision-adr090-red-tls.md` (H-08) y ADR-129, bloque B (en `origin/master`).

> Recomendación técnica (C2). La decisión de unir es del propietario, vía B.

## 1. Alcance y superficie revisada

- **Archivos (8 de código, 5 de pruebas):** `ArranqueRed.cs`, `DireccionIp.cs`, `EventosRed.cs`, `FuenteConfiguracionRed.cs`, `FuenteConfiguracionRed.Windows.cs`, `InterpretacionRed.cs`, `ModoRed.cs`, `ValoresRegistroServidor.cs`; pruebas en `tests/GPOS.Tests/Red/*` y `Arquitectura/RedPlataformaArquitecturaTests.cs`.
- **Superficie:** no hay superficie de red nueva. PR-1a no toca `Program.cs` de la API ni de la Web (verificado en el *stat* del commit). La superficie es indirecta: decide si los servicios arrancan y con qué direcciones cuando PR-1b lo conecte. Por eso, varios hallazgos son **requisitos para PR-1b**, no defectos de este PR.
- **Comprobaciones ejecutadas:** `git grep` de 4743 a 4752 en las 163 referencias `refs/remotes/origin/*`, en las ramas locales y en el commit; comportamiento de `IPAddress.TryParse` en .NET 10.0.13 (el mismo `net10.0` de `GPOS.Comun.csproj:4`) con `pwsh` 7.6.7, sin tocar el árbol.

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título | Cuándo |
|---|---|---|---|
| S-01 | Media | `IpNodos` acepta IPv4 con ceros a la izquierda (se leen en octal), IPv4 «compatible» y direcciones especiales: el nodo real queda sin filtrar | Antes de unir PR-1a |
| S-02 | Media | TOCTOU: Kestrel recarga `Kestrel:Endpoints` en caliente y la evaluación y el 4746 solo se hacen al arrancar | Requisito de PR-1b |
| S-03 | Baja | Fuentes no listadas en la regla 1: integración con IIS (`ASPNETCORE_PORT`), `Kestrel:EndpointDefaults`, ensamblados de inicio; y la cobertura de `--urls` no se prueba con un `WebApplicationBuilder` real | PR-1b |
| S-04 | Baja | `FuenteConfiguracionRedWindows` es pública y su constructor admite cualquier raíz (por ejemplo, `HKCU`) | Antes de unir PR-1a |
| S-05 | Baja | El servicio no comprueba el dueño ni la DACL de la clave; la protección depende de que el verbo `red` la cree o la rehaga | Verbo `red` (B) y PR-1b |
| S-06 | Baja | «Sin modo» depende solo de un Estricto **explícito**: borrar únicamente `ModoRed` en una instalación sin la clave Estricto da arranque en *loopback* | Antes de unir PR-1a (barato) |
| S-07 | Baja | Lectura no atómica de varios valores mientras escribe el verbo `red`; excepciones no previstas salen sin 4743 | Verbo `red` (B); informativa |
| S-08 | Baja | ADR-129 B.5: CA1416 no está configurado como error en `GPOS.Comun`; la prueba de arquitectura solo busca tres patrones | Fuera del PR (existente) |
| S-09 | Baja | Diferencias con el contrato del blueprint: falta la regla de `Api:Url` y cambian nombres y firma; el mensaje del 4743 puede llevar la ruta de la clave | PR-2 / documental |

**Sin hallazgos Críticos ni Altos.**

## 3. Checklist OWASP Top 10 (2021)

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | Observación: S-01 (la identidad del nodo para RT-06 puede quedar mal) y S-05 (ACL de la fuente única) |
| A02 Fallas criptográficas | No aplica en PR-1a. Las huellas solo se validan por formato (`InterpretacionRed.cs:17-18`, `:101-110`), correcto. Observación de S-03: `Kestrel:EndpointDefaults` debe revisarse en PR-2 |
| A03 Inyección | No aplica: no hay consultas. Los registros usan plantillas estructuradas (`ArranqueRed.cs:152`, `:169`) |
| A04 Diseño inseguro | Bien en general: falla cerrada por omisión. Observaciones: S-02 y S-06 |
| A05 Configuración | Observaciones: S-02, S-03 y S-08 |
| A06 Componentes vulnerables | No aplica: no hay dependencias nuevas (`Microsoft.Win32.Registry` es del marco) |
| A07 Identificación y autenticación | No aplica |
| A08 Integridad de software y datos | Observación: S-05 (integridad de la clave del registro) y S-07 |
| A09 Registro y monitoreo | Bien: los motivos nombran el valor y la regla, nunca el contenido. Los EventId no chocan. Observación menor en S-09 |
| A10 SSRF | No aplica |

## 4. Hallazgos

### S-01 · Media · `IpNodos`: ceros a la izquierda, IPv4 «compatible» y direcciones especiales
- **Riesgo.** `DireccionIp.TryParseHost` solo exige cuatro partes en IPv4 (`DireccionIp.cs:34`) y caracteres hexadecimales, `.` o `:` (`:50-51`). `IPAddress.TryParse` de .NET interpreta en **octal** las partes con un cero a la izquierda. **Verificado** en .NET 10.0.13: `010.000.000.005` da `8.0.0.5`, y `0010.1.1.1` da `8.1.1.1`. Si un técnico rellena con ceros (algunas herramientas y hojas de cálculo lo hacen) o el verbo `red` copia el texto tal cual, `IpNodos` queda con otra IP **sin error**. El nodo real no se reconoce, y RT-06 (PR-3) no lo restringe a `/api/sync/*`: vuelve a tener toda la superficie anónima de la API (H-07 de la revisión previa). Además:
  - `::a00:5` (IPv4 «compatible», obsoleta) se admite y se guarda como IPv6 (verificado). La conexión de doble pila llega como `::ffff:10.0.0.5` → `10.0.0.5`, que no coincide.
  - Se admiten *loopback* (`127.0.0.1`, `::1`), difusión (`255.255.255.255`), multidifusión y enlace local. Un `127.0.0.1` en `IpNodos` haría que la API tratara a la Web (que le llega desde *loopback*) como un nodo, y la dejaría sin servicio.
  - Lo mismo afecta, en menor grado, a `NombresServidor`: `InterpretacionRed.cs:86` clasifica `010.0.0.1` o `167772161` como IP en las entradas 2 a 16. Hoy son texto para `AllowedHosts` y el SAN, sin efecto de filtro.
- **Evidencia.** `src/GPOS.Comun/Red/DireccionIp.cs:32-36`; `src/GPOS.Comun/Red/InterpretacionRed.cs:67-71`; `tests/GPOS.Tests/Red/DireccionIpTests.cs:38-57` (no hay casos con ceros a la izquierda, IPv4 compatible ni *loopback*).
- **Remediación (unos 0,05 dp).**
  1. En IPv4, exigir la forma canónica de ida y vuelta (`normal.ToString() == parteIp`). Así se rechazan los ceros a la izquierda y cualquier otra forma no decimal.
  2. Rechazar la IPv6 «compatible» (los primeros 96 bits en cero y que no sea `::`/`::1`), *loopback*, multidifusión, difusión y enlace local.
  3. Agregar esos casos a `TryParseHost_rechaza_lo_demas`.
  4. Que el verbo `red` (B) use el mismo `TryParseHost` y escriba la forma canónica.
- **Defensa en profundidad.** Que el 4745 o el arranque con modo registren cuántas IP de nodo se cargaron (el número, no las IP). El técnico ve una discrepancia sin exponer datos.

### S-02 · Media · TOCTOU entre la evaluación y la escucha: recarga de Kestrel en caliente
- **Riesgo.** `ArranqueRed` evalúa las fuentes **antes de `Build`** y las direcciones efectivas **una vez**, en `ApplicationStarted` (`ArranqueRed.cs:32-34`, `:41-42`, `:113-114`, `:164-172`). El anfitrión por omisión de ASP.NET Core llama a `KestrelServerOptions.Configure(Configuration.GetSection("Kestrel"), reloadOnChange: true)`. Los proveedores JSON (`appsettings.json` y `appsettings.{Entorno}.json`, este último aunque no exista al arrancar) también recargan. Un `Kestrel:Endpoints` agregado **después** del arranque haría que Kestrel enlace un punto nuevo, quizá HTTP en `0.0.0.0`, sin pasar por la regla 1 ni por el 4746. La falla cerrada se rompería sin dejar evento. [I: comportamiento documentado de .NET 5 a 10; no lo ejecuté.]
- **Probabilidad.** Baja: hace falta escribir en la carpeta de la aplicación (`Program Files`, solo administradores) y `ArchivoInstalacion` filtra todo salvo `GPOS:RncDgii` (`src/GPOS.Comun/Configuracion/ArchivoInstalacion.cs:27`). **Impacto:** alto (abre un puerto). Queda en Media porque el contrato de RT-01 promete detectar justo esto.
- **Remediación para PR-1b (unos 0,1 dp).**
  - Con modo presente, desactivar el cargador de configuración de Kestrel: `builder.WebHost.ConfigureKestrel(o => o.Configure(<configuración vacía>, reloadOnChange: false))`, registrado después del de omisión.
  - Como defensa en profundidad, suscribirse a `IConfiguration.GetReloadToken()` (`ChangeToken.OnChange`) para repetir `FuentesDeEscucha`. Si aparece una fuente, `LogCritical` 4744, `ExitCode = 1` y `StopApplication()`.
  - Prueba: Kestrel real en «un equipo», escribir un `Kestrel:Endpoints` en un JSON con recarga y comprobar que no se enlaza nada nuevo (o que el servicio se detiene).
  - En «sin modo» (sin Estricto, solo desarrollo) basta con la suscripción.

### S-03 · Baja · Fuentes de direcciones o de TLS fuera de la lista de la regla 1
- **Integración con IIS.** `UseIISIntegration` (incluido en los valores por omisión del anfitrión web) lee `PORT`, `APPL_PATH` y `TOKEN` (`ASPNETCORE_PORT`, etc.). Si están las tres, fija `urls = http://127.0.0.1:<puerto>` y `preferHostingUrls = true`, lo que **sustituye** los puntos armados en código. Lo atrapa el 4746 en los dos modos (no es `https`), así que el residual es de disponibilidad. [I: código de ASP.NET Core; no lo ejecuté.] **Remediación:** agregar `PORT` (y `ASPNETCORE_PORT`) a `ClavesDeEscucha` / `VariablesDeEscucha`; costo despreciable.
- **`Kestrel:EndpointDefaults`.** La prueba lo admite de forma explícita (`tests/GPOS.Tests/Red/ArranqueRedTests.cs:104-108`). `Protocols`, `SslProtocols` y `ClientCertificateMode` de esa sección pueden aplicarse a los puntos armados en código según la sobrecarga de `UseHttps` que use PR-2. [I.] **Remediación:** rechazar `Kestrel:EndpointDefaults` con modo presente (lo más simple y en falla cerrada), o fijar una prueba en PR-2 de que no altera los protocolos ni el modo de certificado de cliente.
- **Ensamblados de inicio (`hostingStartupAssemblies`, `ASPNETCORE_HOSTINGSTARTUPASSEMBLIES`) y `DOTNET_STARTUP_HOOKS`.** Ejecutan código en el proceso y pueden rearmar Kestrel. Exigen escribir el entorno del servicio y un ensamblado (administrador, R-9). **Remediación:** rechazarlos con modo presente (dos nombres más en la lista).
- **Cobertura sin probar con el marco real.** La regla 1 confía en que `--urls` (también `/urls` y `urls=`, del proveedor de línea de comandos) y las variables `ASPNETCORE_*`/`DOTNET_*` lleguen a `builder.Configuration`. Las pruebas usan una configuración en memoria (`ArranqueRedTests.cs:22-23`), y el blueprint (5.1, regla 1) pedía «lo fija una prueba» [I]. **Remediación para PR-1b:** una prueba con `WebApplication.CreateBuilder(["--urls", …])` y otra con la variable en el entorno del proceso. Además, `Evaluar` debe llamarse **después** de la última fuente de configuración, incluida `AgregarArchivoInstalacion` (`src/GPOS.Api/Program.cs:27`; `src/GPOS.Web/Program.cs:11`). Conviene una prueba de arquitectura del orden.

### S-04 · Baja · Constructor público que admite otra raíz del registro
- **Riesgo.** El blueprint declara la clase `internal` (blueprint 4.2). El código la hace pública, con un constructor público que recibe cualquier `Func<RegistryKey>` y cualquier subclave (`FuenteConfiguracionRed.Windows.cs:12`, `:21-25`). Un error en PR-1b o en otra pieza, como usarlo con `HKCU` o con `RegistryView.Default`, convertiría la fuente única en una que cualquier usuario escribe (secuestro por `HKCU` o por `WOW6432Node`). No hay prueba que lo impida.
- **Remediación (unos 0,02 dp).** Clase `internal`, constructor de pruebas `internal` con `InternalsVisibleTo("GPOS.Tests")` (o una fábrica solo de pruebas), y una prueba de arquitectura: en `src/` solo se obtiene la fuente con `FuenteConfiguracionRed.Crear()`.
- **Verificado sin problema.** La de producción usa `HKLM` con `RegistryView.Registry64` (`:18`). Un proceso de 32 bits lee igualmente la vista de 64 bits, no `WOW6432Node`. La virtualización de UAC (`VirtualStore` de `HKCU`) no se aplica a los servicios ni a procesos con manifiesto `asInvoker` [I: documentación de Windows]. Solo se abre con lectura (`:33`).

### S-05 · Baja · Sin comprobación del dueño ni de la DACL de la clave al leerla
- **Riesgo.** La garantía de la «fuente única» es la DACL que pone el verbo `red` (blueprint 4.1). Si `HKLM\SOFTWARE\GPOS NG` o `…\Servidor` ya existieran con otro dueño o con escritura para usuarios (otra pieza que la cree con una ACL amplia, o una ocupación previa), quien la ocupa conserva `WRITE_DAC` como dueño y puede cambiar `ModoRed` o vaciar `IpNodos`. Hoy ningún archivo del repositorio crea esa clave (verificado con `git grep` en `*.cs`, `*.wxs` y `*.ps1`), así que el riesgo depende de lo que construya B.
- **Evidencia.** `src/GPOS.Comun/Red/FuenteConfiguracionRed.Windows.cs:32-34` (abre y lee sin mirar la seguridad de la clave).
- **Remediación.**
  - **Verbo `red` (B):** al crear o reutilizar las dos claves, fijar el dueño (Administradores) y una DACL protegida (SYSTEM y Administradores con control total, Usuarios autenticados con lectura), aunque ya existan.
  - **Servicio, defensa en profundidad, unos 0,15 dp en PR-1b:** si el dueño no es SYSTEM, Administradores ni TrustedInstaller, o hay un ACE de escritura para otro SID, devolver `Invalida` (4743).

### S-06 · Baja · «Sin modo» con Estricto implícito
- **Riesgo.** `EsEstricto` exige el texto explícito «Estricto» (`src/GPOS.Core/Infraestructura/Anillo/ComprobacionAnillo.cs:50-51`; `src/GPOS.Web/Servicios/ProteccionDatosWeb.cs:50`). El contrato dice que Estricto es el valor por omisión (`src/GPOS.Contracts/Admin/IdentidadSql.cs:4`), pero ningún `appsettings` publicado lo fija (`git grep`: solo `appsettings.Development.json:7` con `Amplio` y los guiones del DEMO). Si el paquete no escribe la clave Estricto, o una reparación la pierde, borrar **solo** el valor `ModoRed` deja la clave con los demás valores y produce `SinModo` (`InterpretacionRed.cs:26`): arranque en *loopback* con HTTP en vez de 4743. **Impacto acotado:** el 4746 sigue exigiendo *loopback*, así que no hay exposición a la red; el efecto es una degradación silenciosa (las estaciones dejan de conectar).
- **Remediación (unos 0,03 dp).** En `Interpretar`, si la clave existe y tiene cualquiera de los valores del paquete (`PuertoApi`, `IpNodos`, `Version`, `RegistroInstalacion`) pero no `ModoRed`, devolver `Invalida(ModoRed, "falta")` → 4743, sin importar Estricto. «Sin modo» queda solo para la clave ausente (desarrollo, pruebas y DEMO).
- **Entrega a B:** confirmar que INS B-11 escribe la clave Estricto en el entorno del servicio o en un archivo que ninguna reparación pierda.

### S-07 · Baja · Lectura no atómica y excepciones no previstas
- **Análisis (verificado por lectura).** `GetValueNames`, `GetValueKind` y `GetValue` son llamadas separadas (`FuenteConfiguracionRed.Windows.cs:46-56`). Si un valor cambia o se borra entre ellas, el par (tipo, valor) no coincide y cae en `ValorTipoNoAdmitido`, o `GetValueKind` lanza `IOException` (atrapada en `:36`): **falla cerrada**. Entre valores distintos, el verbo `red` puede escribir a medias. Activar «servidor de sitio» con `ModoRed` antes que `IpNodos` da 4743 (cerrado), pero el orden inverso al desactivar no está fijado. Las excepciones fuera de las tres atrapadas (`:36`), como `ArgumentException`, tumban el proceso sin 4743: sigue cerrado, pero sin evento.
- **Remediación.**
  - Verbo `red` (B): al activar, escribir `ModoRed` **al final**; al cambiar de modo, borrarlo **primero**.
  - El refresco de RT-05 debe tomar una lectura completa (una `LecturaRed`) y nunca mezclar valores de dos lecturas.
  - En PR-1b, un `catch` general en `Preparar` que registre 4743 con el tipo de la excepción antes de relanzar.

### S-08 · Baja · ADR-129 B.5 sin el analizador como error
- **Evidencia.** No hay `CA1416` en `GPOS.Comun.csproj`, en `*.props`, en `.editorconfig` ni en `*.globalconfig` (`git grep`). ADR-129, bloque B, punto 5, lo exige como error en los proyectos neutros. La prueba de arquitectura solo busca `Microsoft.Win32`, `RegistryKey` y `Registry.` (`tests/GPOS.Tests/Arquitectura/RedPlataformaArquitecturaTests.cs:28`).
- **Remediación.** `<WarningsAsErrors>CA1416</WarningsAsErrors>` en `GPOS.Comun`, o `dotnet_diagnostic.CA1416.severity = error`. Es anterior a este PR: entrega al responsable de ADR-129 (A, LN).

### S-09 · Baja · Diferencias con el contrato y un detalle del mensaje
- **Diferencias con el blueprint.** El blueprint (5.1) define `EvaluacionArranqueRed.Evaluar(…, apiUrlConfigurada)` con la regla de `Api:Url` → 4743 para la Web. El código expone `ArranqueRed.Evaluar(lectura, IConfiguration, estricto, entorno)` sin esa regla (`ArranqueRed.cs:75`), y nombra `SinPlataforma` lo que el blueprint llama `SinFuente`. El blueprint pone las pruebas de `Api:Url` en PR-2, así que no es un defecto, pero **PR-2 debe agregar la regla** a esta función o al `Preparar` de la Web; si no, la Web podría apuntar a otra URL con el modo presente.
- **Mensaje del 4743.** Al fallar la lectura, el 4743 y `ArranqueRedException` llevan la ruta de la clave (`FuenteConfiguracionRed.Windows.cs:38` → `ArranqueRed.cs:82`), aunque `EventosRed.cs:27` dice «sin rutas». No es sensible (es una constante pública). Basta con ajustar el comentario o usar el nombre lógico («la clave del servidor»).

## 5. Controles que están bien implementados

- **Falla cerrada en la lectura.** Un error de permisos o de E/S se informa como `Invalida`, no como «sin modo» (`FuenteConfiguracionRed.Windows.cs:36-39`). Los tipos se traducen de forma estricta: `REG_EXPAND_SZ`, `REG_QWORD`, `REG_BINARY` y `REG_NONE` no se admiten, y se lee con `DoNotExpandEnvironmentNames` (`:49-55`, prueba en `FuenteConfiguracionRedWindowsTests.cs:61-77`).
- **Vista de 64 bits explícita y solo `HKLM`** en la fuente de producción (`:18`). No lee el entorno.
- **Regla 1 completa respecto del blueprint:**
  - `urls`, `http_ports`, `https_ports`, `preferHostingUrls`, `Kestrel:Endpoints` y `Kestrel:Certificates`, en la configuración y en las seis variables más dos `PREFERHOSTINGURLS` (`ArranqueRed.cs:54-69`, `:108-119`);
  - el valor vacío también se rechaza (`:111`);
  - `preferHostingUrls` se trata en falla cerrada (`:204-205`);
  - la configuración y el entorno de Windows no distinguen mayúsculas, así que `URLS` o `Aspnetcore_Urls` no eluden la regla.
- **Regla 3 (fuente única).** `GPOS_MODO_RED` y `GPOS:Red:Modo` distintos del registro, o presentes sin registro → 4743 (`ArranqueRed.cs:84-89`, `:100-101`). `GPOS__Red__Modo` llega a la misma clave de configuración.
- **Estricto y plataforma (HB-03, HB-04).** Sin modo o sin plataforma con Estricto → 4743 (`:95-99`).
- **Comprobación de direcciones efectivas:**
  - `*` y `+` se tratan como `0.0.0.0`;
  - una dirección que no se puede interpretar, un `unix:` o un `pipe:` se rechazan;
  - en «servidor de sitio», HTTPS y puerto exactos, y ninguna HTTP en *loopback* (`:174-191`);
  - la IPv4 mapeada se normaliza antes de `IsLoopback`.
- **Validación del registro:** `PuertoApi` acotado y distinto de `PuertoWeb`, 5073 y 17654 (`InterpretacionRed.cs:42-47`); huella con expresión anclada (`:17-18`); `IpNodos` obligatorio en «servidor de sitio» y lista vacía válida (HB-05, `:61-73`); prefijo exacto `/32` o `/128` según la forma escrita (`DireccionIp.cs:37-42`); sin ámbito ni espacios.
- **Sin fugas de contenido.** Todos los motivos nombran el valor y la regla, con índice de entrada y nunca el contenido. Las pruebas lo afirman (`ArranqueRedTests.cs:72`, `:91`). Ni el registro ni la excepción llevan valores de configuración.
- **EventId sin choques.** 4743 a 4746 solo aparecen en este commit: ninguna coincidencia en las 163 referencias de `origin` ni en las ramas locales (`git grep`). Se declaran en el formato que reconoce `EventIdUnicosTests` (`EventosRed.cs:14-24`), con una prueba de rango 4743-4752 (`ArranqueRedTests.cs:331`).
- **Plataforma.** Una prueba de arquitectura comprueba que solo `*.Windows.cs` usa el registro y lleva `[SupportedOSPlatform("windows")]`.

## 6. Remediaciones priorizadas

1. **Antes de unir PR-1a (unos 0,1 dp en total):** S-01 (forma canónica y direcciones especiales en `TryParseHost`, con pruebas), S-04 (clase y constructor `internal`) y S-06 (clave con valores pero sin `ModoRed` → 4743).
2. **Requisitos escritos para PR-1b (unos 0,35 dp):** S-02 (sin recarga de Kestrel con modo presente, más suscripción a la recarga), S-03 (`PORT`, `EndpointDefaults`, ensamblados de inicio, prueba con `WebApplicationBuilder` real y orden respecto de `AgregarArchivoInstalacion`), S-05 (comprobación de la DACL) y S-07 (`catch` general con 4743).
3. **B, verbo `red`:** S-05 (dueño y DACL aunque la clave exista), S-07 (orden de escritura de `ModoRed`), S-01 (escribir `IpNodos` canónico) y la confirmación de Estricto de S-06.
4. **PR-2:** la regla de `Api:Url` (S-09) y la decisión sobre `EndpointDefaults` (S-03).
5. **Fuera del PR:** S-08 (CA1416 como error, ADR-129 B.5).

## 7. Recomendación

**Aprobado con observaciones** (recomendación técnica; la decisión es del propietario, vía B). No hay hallazgos Críticos ni Altos, y la lógica de falla cerrada es correcta para todo lo que el contrato enumera. Se recomienda corregir S-01, S-04 y S-06 antes de unir: son baratos y S-01 afecta a la identidad que usará RT-06. S-02 y S-03 deben quedar escritos como criterios de aceptación de PR-1b, porque es ahí donde la falla cerrada se conecta con Kestrel.

### Supuestos
- Reviso el commit `e840bae3` tal cual. No compilé ni ejecuté la suite; el resultado de «148 correctas» es el del mensaje del commit.
- Los comportamientos del marco marcados [I] (recarga de Kestrel, integración con IIS, `EndpointDefaults`, virtualización de UAC) salen del conocimiento de ASP.NET Core y de Windows, no de una ejecución. El análisis octal de `IPAddress.TryParse` sí está verificado en .NET 10.0.13.
- El verbo `red` y la aplicación de Estricto por el paquete (INS B-11) aún no existen en el repositorio.
