[Informe de Seguridad] PR-1b de ADR-90 (RT-01 conectado con Kestrel): `GPOS.Comun.Servidor`, S-03, S-05 y cableado de la Web

Fecha: 2026-10-21 · Revisor: auditor-seguridad · Objeto: commits `bf4a8685` (parte 1: S-03 y S-05) y `0477c5dc` (parte 2: `GPOS.Comun.Servidor`, `EscuchaServidor`, Web) de la rama `a/adr90-rt05-escucha-servidor` (árbol `GPOS-NG-pr1b`), contra `origin/a/adr90-rt06-filtro-origen`. Revisión **solo de lectura** (`git show`, `git diff`, `git grep`): no compilé, no ejecuté pruebas ni cambié de rama.
Contratos: blueprint de A v2 (`traspasos/A/blueprint-adr90-rt01-rt05-rt06-2026-10-20.md`, 5.1, 7, 9), ADR-090 (`origin/master`), revisiones previas `revision-seguridad-pr1a-adr90-2026-10-20.md` y `revision-seguridad-pr3-adr90-2026-10-20.md`.
Marcas: [V] verificado en el código o en git; [I] inferido del comportamiento conocido de ASP.NET Core 10, .NET 10 o Windows, sin ejecutar.

> Recomendación técnica (C2). La decisión de unir es del propietario, vía B.

## 1. Alcance y superficie revisada

| Archivo | Cambio |
|---|---|
| `src/GPOS.Comun.Servidor/GPOS.Comun.Servidor.csproj` (nuevo) | Solo `Microsoft.AspNetCore.App` y `GPOS.Comun`; `InternalsVisibleTo("GPOS.Tests")` |
| `src/GPOS.Comun.Servidor/Red/EscuchaServidor.cs` (nuevo, 164 l.) | `Preparar` (antes de `Build`), `ExigirArranque` (después), vigilancia de `ApplicationStarted` y de la recarga de la configuración |
| `src/GPOS.Comun.Servidor/Red/EstadoRed.cs` (nuevo) | Decisión, lectura única y entorno |
| `src/GPOS.Comun/Red/ArranqueRed.cs` | S-03: `PORT`, `Kestrel:EndpointDefaults`, `hostingStartupAssemblies`, `*_HOSTINGSTARTUPASSEMBLIES`, `DOTNET_STARTUP_HOOKS`, `ASPNETCORE_PORT` |
| `src/GPOS.Comun/Red/FuenteConfiguracionRed.Windows.cs` | S-05: dueño y DACL de la clave antes de leer |
| `src/GPOS.Web/Program.cs`, `GPOS.Web.csproj` | `Preparar` (:55), `ExigirArranque` (:105), `UseRechazoOrigenNodo` (:109) antes de `UseForwardedHeaders` (:110) |
| Pruebas | `EscuchaServidorTests`, `EscuchaServidorKestrelTests`, `FuenteConfiguracionRedWindowsTests` (S-05), `RedPlataformaArquitecturaTests`, `GPOS.Web.Tests/Red/ProgramaWebRedTests` (leídas, no ejecutadas) |

Superficie: el arranque y la escucha de **GPOS.Web** (la API no se cablea en este PR; es PR-4) y la lectura de `HKLM\SOFTWARE\GPOS NG\Servidor` (vista de 64 bits).

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título |
|---|---|---|
| S1b-01 | Baja | La comprobación de la DACL no ve las ACE condicionales (de *callback*) ni las no reconocidas: las omite .NET |
| S1b-02 | Baja | Lista de direcciones efectivas vacía = aprobada: con un `IServer` sin `IServerAddressesFeature` (TestServer, IIS en proceso) el 4746 no actúa |
| S1b-03 | Baja | Las pruebas de `GPOS.Web.Tests` (y las de la API cuando PR-4 la cablee) leen el registro real del equipo: comportamiento distinto según la máquina |
| S1b-04 | Baja | La prueba de orden de la Web solo busca `builder.Configuration.Add` entre `Preparar` y `Build`; no `WebHost.UseSetting/UseUrls/ConfigureKestrel` |
| S1b-05 | Baja | Ventana entre el enlace de Kestrel y `ApplicationStarted` (milisegundos) y, sin modo, entre la recarga de `Kestrel:Endpoints` y la detención |
| S1b-06 | Baja (informativa) | Ensamblados de inicio y ganchos de arranque se detectan **después** de que corrieron; no es una frontera contra código hostil |
| S1b-07 | Baja (para N-1, B) | Código de salida 1 frente al SCM cuando la Web sea servicio de Windows: sin verificar que llegue como fallo del servicio |
| S1b-08 | Baja (disponibilidad, B) | Dueño de la clave distinto de Administradores/SYSTEM → 4743: el verbo `red` debe fijarlo siempre; claves genéricas `PORT`/`TOKEN`/`APPL_PATH` sin prefijo también dan falsos 4744 |

**Sin hallazgos Críticos ni Altos.**

### Estado de los hallazgos previos

| Previo | Estado | Evidencia |
|---|---|---|
| S-02 (Media, PR-1a) | **Cerrado** | Con modo, el cargador de Kestrel se sustituye por una configuración vacía sin recarga (`EscuchaServidor.cs:58-63`), registrado después del de omisión; prueba `EscuchaServidorTests.cs:169-180`. Defensa en profundidad: `ChangeToken.OnChange` sobre la recarga (`:94`), que repite la regla 1 y la 3 (`:112-145`); prueba con Kestrel real y un JSON con recarga (`EscuchaServidorKestrelTests.cs:158-198`). Sin modo: revisa los `Kestrel:Endpoints` declarados y las efectivas (`:123-139`) |
| S-03 (Baja) | **Cerrado** | `PORT`/`ASPNETCORE_PORT` (`ArranqueRed.cs:58`, `:83`), `Kestrel:EndpointDefaults` (`:64`), ensamblados de inicio y `DOTNET_STARTUP_HOOKS` (`:70-74`, `:157-160`). Prueba con `WebApplicationBuilder` real: `--urls`, `/urls`, `urls=`, `--URLS` (`EscuchaServidorKestrelTests.cs:270-280`) y variables del entorno del proceso (`:234-268`). Orden respecto de `AgregarArchivoInstalacion`: `ProgramaWebRedTests.cs:27-45` (ver S1b-04) |
| S-05 (Baja) | **Cerrado en el servicio** (queda la parte de B) | `FuenteConfiguracionRed.Windows.cs:53-55`, `:93-124`; la de producción la activa (`:29-31`) y una prueba lo fija (`FuenteConfiguracionRedWindowsTests.cs` «La_fuente_de_produccion_comprueba_la_DACL»). Ver S1b-01 y S1b-08 |
| S-07 (Baja) | **Cerrado** | `catch (Exception)` general en la lectura con solo el tipo (`FuenteConfiguracionRed.Windows.cs:58-64`), en `Preparar` (`EscuchaServidor.cs:51-55`) y en las comprobaciones en marcha (`:105-108`, `:141-144`); una sola lectura en `EstadoRed.Lectura` (`EstadoRed.cs:36-37`), reutilizada al recargar (`EscuchaServidor.cs:117`). El orden de escritura de `ModoRed` sigue siendo de B |
| S3-01 (Media, PR-3) | **Cerrado para la Web** | Con modo, la regla 1 rechaza `ForwardedHeaders_Enabled` e IIS fuera de proceso (`ArranqueRed.cs:161`, `:169-179`); con nodos, `UseRechazoOrigenNodo` falla cerrado al preparar (`RechazoOrigenNodo.cs:31-32` → `OrigenNodo.cs:67-72`). Va antes de `UseForwardedHeaders` (`Program.cs:109-110`), fijado por `ProgramaWebRedTests.cs:41`. La API queda para PR-4 |

## 3. Checklist OWASP Top 10 (2021)

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | Bien: S3-01 cerrado en la Web; orden del filtro de nodos correcto. Observaciones S1b-01 (DACL) |
| A02 Fallas criptográficas | No aplica (TLS es PR-2). `Kestrel:Certificates` y `EndpointDefaults` rechazados con modo |
| A03 Inyección | No aplica: sin consultas; registro estructurado; los motivos no llevan valores ni rutas (prueba `EscuchaServidorTests.cs:141-157`) |
| A04 Diseño inseguro | Bien: falla cerrada en todas las ramas revisadas. Observaciones S1b-02, S1b-05 |
| A05 Configuración | Bien: S-02 y S-03 cerrados. Observaciones S1b-04, S1b-08 |
| A06 Componentes vulnerables | No aplica: sin paquetes nuevos (prueba de arquitectura de `GPOS.Comun.Servidor`) |
| A07 Identificación y autenticación | No aplica |
| A08 Integridad | Bien: dueño y DACL de la clave comprobados sobre el mismo *handle* que se lee. Observaciones S1b-01, S1b-06 |
| A09 Registro y monitoreo | Bien: 4743/4744/4745/4746 en todas las salidas; excepción imprevista con su tipo. Observación S1b-07 |
| A10 SSRF | No aplica |

## 4. Análisis de elusión de la falla cerrada (lo pedido)

1. **Orden `Preparar` → `Build` → `ExigirArranque` → `Run`.** [V] `Program.cs:13` (última fuente), `:55`, `:102`, `:105`, `:194`. Denegado → `ArranqueRed.Exigir` registra el crítico y lanza (`ArranqueRed.cs:212-214`); no hay `try` alrededor en `Program.cs`, así que el proceso termina con código distinto de 0 antes de `Run`. Con la decisión denegada `Preparar` no toca Kestrel, pero no importa porque nunca llega a enlazar. Si alguien olvidara `ExigirArranque`, la prueba de texto lo detecta (`ProgramaWebRedTests.cs:33`).
2. **`ApplicationStarted` y `ExitCode`.** [V] `Detener` es idempotente con `Interlocked.Exchange` (`EscuchaServidor.cs:157-162`), fija `Environment.ExitCode = 1` **antes** de `StopApplication`, y nada en `Program.cs` lo devuelve a 0 (no hay código después de `app.Run()`, `:194`). El `Main` de instrucciones de nivel superior sin `return` sale con `Environment.ExitCode` [I]. Si la recarga dispara `Detener` antes de `Run`, el anfitrión arranca con `ApplicationStopping` ya cancelado y se detiene o no llega a iniciar; en ambos casos con código 1 [I]. Servicio de Windows: S1b-07.
3. **TOCTOU registro/uso.** [V] La DACL y los valores se leen del **mismo *handle*** (`FuenteConfiguracionRed.Windows.cs:52-56`), así que un vínculo simbólico del registro o una sustitución de la clave entre ambos pasos no separa lo comprobado de lo leído: se comprueba la DACL del destino real. Después, la lectura queda congelada en `EstadoRed` (por diseño, hasta el refresco de RT-05); un cambio posterior lo hace solo quien tiene escritura (SYSTEM o Administradores, R-9 aceptado).
4. **Configuración de Kestrel vacía con `reloadOnChange: false`: ¿otra fuente reinyecta puntos?** [V/I] `KestrelServerOptions.Configure(config, reload)` **sustituye** el cargador; el de omisión (`Kestrel`, con recarga) se registró en `CreateBuilder`, antes, y `ConfigureKestrel` de `Preparar` va después (`Program.cs:52` no llama a `Configure`, solo límites: `ProteccionWeb.cs:75-84`). Las vías que quedan para fijar direcciones son: `urls`/`*_ports`/`preferHostingUrls` (regla 1 al preparar y al recargar), `IServerAddressesFeature` desde código (`app.Urls`, `UseUrls`, `Listen`, otro `ConfigureKestrel` posterior) y código ajeno en el proceso (S1b-06). Las de código no las cubre la prueba de orden (S1b-04); en todo caso el 4746 las atrapa al arrancar, salvo con una lista vacía (S1b-02).
5. **`ChangeToken.OnChange` y carreras.** [V] La suscripción se crea en `ExigirArranque` (`:94`) y se libera al detenerse (`:95`). `Revisar` y `ComprobarEfectivas` pueden correr a la vez (hilo del observador de archivos y el de `ApplicationStarted`): ambas leen `_detenida` con `Volatile.Read` y solo detienen una vez; un doble aviso del observador repite el crítico pero no el `StopApplication` (lo asume la prueba, `EscuchaServidorKestrelTests.cs:188-190`). Sin modo, el orden entre la recarga de Kestrel y `Revisar` no está garantizado: por eso, además de las efectivas, se revisan las URL declaradas (`:127`), y una URL vacía o no interpretable se rechaza (`ArranqueRed.cs:238-244`). Ventana residual: S1b-05.
6. **`StopApplication` frente al código de salida.** [V] Correcto: el código queda fijado antes de pedir la detención; el apagado detiene primero el servicio web (Kestrel deja de aceptar conexiones) [I].
7. **Cableado de la Web.** [V] `UseRechazoOrigenNodo(red.IpNodos)` antes de `UseForwardedHeaders` y de `UseExceptionHandler`; sin nodos no agrega nada. `EsEstricto` de la Web (`ProteccionDatosWeb.cs:50`, `OrdinalIgnoreCase`) se lee de `builder.Configuration` ya completa, y en la recarga se reutiliza el valor inicial (`EstadoRed.cs:33-34`): un cambio en caliente de `ModoIdentidad` no puede relajar la regla. `ArchivoInstalacion` no admite esa clave (solo `GPOS:RncDgii`, según la revisión de PR-1a). Pendiente de PR-2 (no es de este PR): la regla de `Api:Url` (S-09).
8. **`GPOS.Tests` como su propio ensamblado de inicio** (`tests/GPOS.Tests/CarpetaLicenciaPruebas.cs:25-34`). [V]
   - **Producción:** sin efecto. La variable la pone un `ModuleInitializer` solo dentro del proceso de pruebas; `src/` no tiene ninguna lista de permitidos para `GPOS.Tests` ni para ningún ensamblado: `ClavesDeCodigoAjeno` rechaza cualquier valor (`ArranqueRed.cs:157-158`).
   - **Validez de las pruebas:** `SoporteEscucha.Builder` quita la clave solo si vale exactamente `GPOS.Tests` (`EscuchaServidorTests.cs:50-52`); el inicio ya corrió en `CreateBuilder`, pero solo fija `GPOS:Licencia:Carpeta` y un servicio hospedado de limpieza (`CarpetaLicenciaPruebas.cs:40-49`), nada de Kestrel ni de red. Las pruebas que esperan 4744 comprueban el **motivo** (`EscuchaServidorKestrelTests.cs:267`): si la limpieza fallara, darían falso negativo (fallo), no falso positivo. Los casos de ensamblados de inicio usan otro valor o quitan la variable propia (`:248-261`), así que prueban lo que dicen.
   - **Riesgo futuro:** cuando PR-4 cablee la API, todas las fábricas de `GPOS.Tests` pasarán por `Preparar` con el registro real y esa variable puesta (S1b-03).

## 5. Hallazgos

### S1b-01 · Baja · ACE condicionales o no reconocidas fuera de la comprobación de la DACL
- **Riesgo.** `MotivoSeguridad` recorre `RegistrySecurity.GetAccessRules` (`FuenteConfiguracionRed.Windows.cs:115`). .NET omite en esa colección las ACE de *callback* (condicionales) y las que no son `QualifiedAce` [I: `CommonObjectSecurity.GetRules` las salta]. Una ACE condicional de permitir con escritura para Usuarios (posible en registro desde Windows 8) pasaría la comprobación. Probabilidad muy baja: ponerla exige `WRITE_DAC`, que solo tienen el dueño de confianza o un administrador (R-9). La DACL nula sí se detecta (.NET la representa como control total para Todos; prueba `La_DACL_nula_no_es_aceptada`).
- **Evidencia.** `FuenteConfiguracionRed.Windows.cs:110-124`.
- **Remediación (unos 0,05 dp).** Recorrer la DACL en bruto (`GetSecurityDescriptorBinaryForm` → `RawSecurityDescriptor.DiscretionaryAcl`) y tratar como **inválida** toda ACE de permitir que no sea `CommonAce` simple (callback, objeto o personalizada), además de la regla actual. Prueba con una SDDL que lleve `XA;` para Usuarios.
- **Verificado sin problema.** Dueño fuera de SYSTEM/Administradores/TrustedInstaller → 4743; el SID de TrustedInstaller es el correcto; las ACE heredadas cuentan (`includeInherited: true`); las de solo herencia (incluido CREATOR OWNER, que en la clave es *InheritOnly*) se omiten con razón; una CREATOR OWNER efectiva sobre la propia clave se rechaza (cierra, no abre); las de denegar no aflojan; los derechos de escritura cubren `KEY_SET_VALUE`, `KEY_CREATE_SUB_KEY`, `KEY_CREATE_LINK`, `DELETE`, `WRITE_DAC`, `WRITE_OWNER`, `GENERIC_ALL` y `GENERIC_WRITE`; una excepción al pedir la seguridad cae en el `catch` general → `Invalida` → 4743 (falla cerrada); sin clave sigue siendo «sin modo» (con Estricto → 4743). La DACL de omisión de una clave nueva bajo `HKLM\SOFTWARE` (SYSTEM y Administradores con control total, Usuarios y ALL APPLICATION PACKAGES con lectura, CREATOR OWNER solo herencia) pasa [I]. No se comprueba la clave padre `GPOS NG`, y no hace falta: cambiar los valores o borrar `Servidor` exige derechos sobre `Servidor`; quien solo puede crear subclaves en el padre y crea `Servidor` queda como dueño y da 4743.
- **Fuera del control (informativo).** Las cuentas con `SeRestorePrivilege`/`SeBackupPrivilege` (Operadores de copia de seguridad) escriben sin pasar por la DACL; equivalen a administradores (R-9).

### S1b-02 · Baja · Lista de direcciones efectivas vacía = aprobada
- **Riesgo.** `Efectivas()` devuelve `[]` si el `IServer` no tiene `IServerAddressesFeature` (`EscuchaServidor.cs:147-148`), y `ComprobarDirecciones` con una lista vacía devuelve `true` (`ArranqueRed.cs:225-232`). Con Kestrel no ocurre, pero con otro servidor (TestServer en las pruebas; IIS en proceso, que el marco activa dentro de `w3wp`) el 4746 no actúa. IIS en proceso, con modo, ya lo frena la regla 1 por `ASPNETCORE_IIS_HTTPAUTH` [I: ANCM la pone también en proceso]; sin modo no.
- **Remediación (minutos).** Con modo presente, lista vacía o `IServer` sin la característica → 4746 y detener. Sin modo, aviso. Ajustar las fábricas de prueba (S1b-03).

### S1b-03 · Baja · Pruebas que dependen del registro real del equipo
- **Riesgo.** `GPOS.Web.Tests` crea la Web con `WebApplicationFactory` (`ConfiguracionPruebas.cs`, `InicioSesionFactorWebTests.cs`, `LoginAntifalsificacionTests.cs`, `RecuperacionFactorTests.cs`) y ahora `Program.cs:55` lee `HKLM\SOFTWARE\GPOS NG\Servidor` con la fuente de producción. En un equipo de laboratorio o de QA donde ya corrió el verbo `red` (por ejemplo, el de C), la suite cambia de comportamiento (con modo: cargador de Kestrel vacío, 4744 si hay alguna fuente; sin TestServer de por medio, el 4746 tampoco actúa por S1b-02). Al cablear la API (PR-4), las fábricas de `GPOS.Tests` además llevan `hostingStartupAssemblies=GPOS.Tests` → 4744 en todo el conjunto. No es una vulnerabilidad: es una prueba que puede aprobar o reprobar según la máquina, y tiende a que alguien «arregle» la regla.
- **Remediación (unos 0,1 dp).** Una costura de pruebas explícita (por ejemplo, `IFuenteConfiguracionRed` registrada por la fábrica antes de `Preparar`, o una clave de configuración solo de pruebas que **solo** pueda endurecer), y que las fábricas de `GPOS.Tests` de la API quiten su propio ensamblado de inicio como ya hace `SoporteEscucha`. Nunca una lista de permitidos en `src/`.

### S1b-04 · Baja · La prueba de orden no cubre otras vías de configurar la escucha
- **Riesgo.** `ProgramaWebRedTests.cs:44` solo prohíbe `builder.Configuration.Add` entre `Preparar` y `Build`. Un `builder.WebHost.UseSetting("urls", …)`, `UseUrls`, `UseKestrel`/`ConfigureKestrel` con `Configure(builder.Configuration.GetSection("Kestrel"), true)` o un `builder.Configuration["…"] = …` posteriores eludirían la regla 1 y S-02 sin fallar la prueba. El 4746 los atraparía al arrancar en la mayoría de los casos.
- **Remediación (unos 0,03 dp).** Ampliar el patrón entre `Preparar` y `Build` a `builder.WebHost.`, `builder.Configuration[` y `UseUrls`, y exigir que `Preparar` sea el último `ConfigureKestrel` del archivo. Repetirlo en la API en PR-4.

### S1b-05 · Baja · Ventanas residuales de exposición
- **Riesgo.** (a) Entre el enlace de Kestrel y la devolución de llamada de `ApplicationStarted` se pueden aceptar conexiones durante milisegundos con una dirección que luego da 4746 [I]. (b) Sin modo (solo sin Estricto: desarrollo, pruebas y DEMO), Kestrel recarga `Kestrel:Endpoints` y puede enlazar el punto nuevo antes de que `Revisar` detenga el servicio. El diseño ya lo aceptaba (blueprint 5.1, regla 4).
- **Remediación opcional (unos 0,05 dp).** Un primer middleware que responda 503 hasta que la comprobación de efectivas haya pasado una vez (bandera que pone `ComprobarEfectivas`). Barato y cierra (a) para HTTP; (b) solo afecta a instalaciones sin Estricto.

### S1b-06 · Baja (informativa) · Código ajeno detectado después de ejecutarse
- **Riesgo.** Los ensamblados de inicio corren dentro de `WebApplication.CreateBuilder` y los ganchos de arranque antes de `Main`, es decir, **antes** de `Preparar`. Rechazarlos (4744) protege contra una configuración accidental (herramientas de desarrollo, guías genéricas), pero un código hostil ya está dentro del proceso y puede borrar su rastro del entorno. No es un defecto del PR: la frontera real es la ACL del entorno del servicio y de la carpeta de binarios (R-9).
- **Decisión que conviene dejar escrita.** No sumar `CORECLR_ENABLE_PROFILING`/`CORECLR_PROFILER*` ni `DOTNET_ADDITIONAL_DEPS` a la lista: rompería agentes de APM legítimos y no aporta frontera. Documentarlo en la guía de operación (devops).

### S1b-07 · Baja · Código de salida y SCM (para N-1)
- **Riesgo.** Hoy la Web no se registra como servicio en el código (`AddWindowsService` no aparece en `src/GPOS.Web`) [V]; ADR-090 fija que irá como servicio (N-4). Con `WindowsServiceLifetime`, una detención pedida desde dentro puede llegar al SCM como parada limpia aunque `Environment.ExitCode = 1`, según cómo la versión del paquete propague el código [I, sin verificar]. Efecto: el monitoreo no ve «fallo» y las acciones de recuperación del SCM no se disparan (o, al revés, un reinicio en bucle si se configuran ante fallo).
- **Remediación.** Para B en N-1: una prueba de laboratorio que fije qué ve el SCM tras un 4743/4746 y una decisión sobre las acciones de recuperación (recomendación: no reiniciar en bucle; reintento acotado y alerta por el evento).

### S1b-08 · Baja (disponibilidad) · Dueño de la clave y claves genéricas sin prefijo
- **Dueño.** Lo que señala el agente es correcto con matices. Un proceso **elevado** de un administrador crea objetos con dueño Administradores, y uno de SYSTEM con dueño SYSTEM; los dos se aceptan [I]. El 4743 aparece si el verbo corre con UAC desactivado y la directiva «Propietario predeterminado de los objetos creados por miembros del grupo Administradores» está en «Creador del objeto», o si la clave ya existía con otro dueño (instalación previa, creación manual). **Falla cerrada**: no abre nada, pero deja la Web sin arrancar, y el motivo del 4743 lo explica sin nombrar cuentas. **Remediación (B, verbo `red`):** fijar siempre el dueño Administradores y una DACL protegida (sin herencia), aunque la clave exista, y verificar al final con el **mismo** criterio que el servicio. Para no tener dos reglas, exponer `MotivoSeguridad` a `GPOS.Migracion` (`InternalsVisibleTo` o un método público en `GPOS.Comun`).
- **Claves genéricas.** `PORT` (`ArranqueRed.cs:58`) y `TOKEN`/`APPL_PATH` (`:104`) también llegan desde variables de entorno **sin prefijo** de la máquina. Una variable de sistema con ese nombre, puesta por otro producto, da 4744 con modo. Es falla cerrada y el motivo nombra la clave; basta con una nota en la guía de diagnóstico (devops).

## 6. Controles que están bien implementados

- **S-02:** sustitución del cargador de Kestrel con modo, con prueba que comprueba que la configuración del cargador no es la sección `Kestrel` y está vacía (`EscuchaServidorTests.cs:169-180`), y que sin modo sí lo es (`:182-190`); vigilancia de la recarga con Kestrel real (`EscuchaServidorKestrelTests.cs:158-232`).
- **Fuentes del marco probadas con el `WebApplicationBuilder` real**, incluidas las cuatro formas de `urls` en la línea de órdenes, `ASPNETCORE_`/`DOTNET_` y `Kestrel__Endpoints` desde el entorno.
- **Falla cerrada en todas las salidas:** lectura (`catch` general), `Preparar`, `ApplicationStarted` y recarga; fuente que devuelve `null` → 4743 (`EscuchaServidorTests.cs:159-164`).
- **Sin fugas:** los motivos llevan el tipo de la excepción y el nombre de la fuente, nunca el valor, el mensaje ni la ruta (pruebas `:117`, `:141-157`; `FuenteConfiguracionRedWindowsTests` comprueba que el motivo de S-05 no lleva el SID).
- **Comprobación de la DACL sobre el mismo *handle*** que se lee, solo en la fuente de producción, con prueba de que esta la activa.
- **Proyecto `GPOS.Comun.Servidor` acotado** por prueba de arquitectura: sin paquetes, solo `GPOS.Comun`, y solo lo referencian la API y la Web; ASP.NET Core no entra en `GPOS.Comun` (F-1, opción a).
- **Cableado de la Web en el orden del contrato** (blueprint 7) y fijado por una prueba de texto.

## 7. Remediaciones priorizadas

| # | Hallazgo | Acción | Quién | Cuándo | Esfuerzo |
|---|---|---|---|---|---|
| 1 | S1b-02 | Con modo, lista de efectivas vacía → 4746 | A | En este PR (minutos) | <0,02 dp |
| 2 | S1b-01 | Recorrer la DACL en bruto y rechazar ACE de *callback* u otras no simples | A | En este PR o en PR-2 | 0,05 dp |
| 3 | S1b-04 | Ampliar la prueba de orden de la Web (y la de la API en PR-4) | A | En este PR | 0,03 dp |
| 4 | S1b-03 | Costura de pruebas para la fuente de red; las fábricas de la API quitan su ensamblado de inicio | A | Antes de PR-4 | 0,1 dp |
| 5 | S1b-08 | Verbo `red`: dueño y DACL protegida siempre, verificación con el mismo criterio | B | Con el verbo `red` | 0,05 dp |
| 6 | S1b-07 | Prueba de laboratorio del código de salida con el SCM; política de recuperación | B (N-1) | Con N-1 | Laboratorio |
| 7 | S1b-05 | 503 hasta la primera comprobación de efectivas (opcional) | A | PR-2 | 0,05 dp |
| 8 | S1b-06, S1b-08 (claves genéricas) | Notas en la guía de operación y diagnóstico | devops | Antes del primer cliente | Documentación |

Total de código para A: unos 0,1 a 0,25 días-persona.

## 8. Recomendación

**Aprobado con observaciones** (recomendación técnica; la decisión de unir es del propietario, vía B). No hay hallazgos Críticos ni Altos. S-02, S-03, S-05 (parte del servicio), S-07 y S3-01 (para la Web) quedan cerrados con código y pruebas. No encontré ninguna vía que eluda la falla cerrada con Kestrel: el orden `Preparar`/`Build`/`ExigirArranque` es correcto, el código de salida se fija antes de detener y la sustitución del cargador no deja otra fuente de configuración que reinyecte puntos. Las vías que quedan son de código (S1b-04) o de otro servidor (S1b-02). Conviene corregir S1b-02 y S1b-04 en este PR (son de minutos) y S1b-01 aquí o en PR-2.

### Supuestos
- Revisé los dos commits tal cual, sin compilar ni ejecutar; los resultados de las pruebas son los que declaran los commits.
- Lo marcado [I] (sustitución del cargador por `Configure`, omisión de ACE de *callback* en `GetRules`, dueño por omisión de los objetos creados por un administrador elevado, variables de ANCM en proceso, propagación del código de salida con `WindowsServiceLifetime`) sale del conocimiento de .NET 10 y de Windows, no de una ejecución.
- No volví a verificar S-01, S-04, S-06 ni S-09 de PR-1a, que no eran el objeto de esta revisión.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\revision-seguridad-pr1b-adr90-2026-10-21.md`
- Supuestos: los de la sección anterior
- Decisiones candidatas a ADR: ninguna nueva. Precisión de operación: no rechazar las variables de *profiler* de APM (S1b-06)
- Entregas a otros agentes: desarrollador (A) → S1b-01 a S1b-04; B (verbo `red`, N-1) → S1b-07 y S1b-08; devops → notas de S1b-06 y S1b-08; qa-automatizado → pruebas de S1b-01 (ACE condicional), S1b-02 (lista vacía) y S1b-03 (costura de la fuente)
- Próximo paso recomendado: que A agregue S1b-02 y S1b-04 (minutos) a PR-1b antes de pedir la unión a B.
