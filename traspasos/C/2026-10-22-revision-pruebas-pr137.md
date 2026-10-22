```
Para: B        De: C        Fecha: 2026-10-22
Tipo: Revisión de pruebas (PR #137: ADR-90, RT-01, PR-1b)
Repositorio y rama: GPOS-NG origin/a/adr90-rt05-escucha-servidor (diff de `gh pr diff 137`, leído en solo lectura)
Estado: Abierto
```

# Revisión de pruebas: #137 (RT-01 / PR-1b: `GPOS.Comun.Servidor`, `EscuchaServidor`, S-02, S-03, S-05, S1b-01..03, 4743-4746)

Leí las 6 clases de prueba (`ArranqueRedTests`, `EscuchaServidorKestrelTests`, `EscuchaServidorTests`, `FuenteConfiguracionRedWindowsTests`, `RedPlataformaArquitecturaTests`, `ProgramaWebRedTests`), `ConfiguracionPruebas.cs`, `SoporteRed.cs` (solo la captura de registro) y la producción (`EscuchaServidor.cs`, `EstadoRed.cs`, `ArranqueRed.cs`, `EventosRed.cs`, `FuenteConfiguracionRed.Windows.cs`, las 4 líneas de `src/GPOS.Web/Program.cs`). Criterio: para cada regla que el PR dice proteger, mutación mental línea a línea.

**No compilé ni ejecuté nada** (ni dotnet, ni SQL, ni pruebas). Todo lo que sigue es lectura del código; donde infiero un comportamiento del marco lo marco como inferido.

## Resumen

| ID | Sev. | Qué | Dónde |
|---|---|---|---|
| P137-01 | Media | La sobrecarga **pública** de `Preparar` (la única que usan la API y la Web) pasa `Environment.GetEnvironmentVariable`; ninguna prueba la ejerce. `DOTNET_STARTUP_HOOKS` y `GPOS_MODO_RED` solo se detectan por esa vía | `EscuchaServidor.cs:37-38` |
| P137-02 | Media | S-02, rama «sin modo» de `Revisar` (puntos de `Kestrel:Endpoints` malos tras recargar → 4746 y detención) sin prueba; tampoco hay prueba de una recarga benigna que **no** detiene | `EscuchaServidor.cs:142-157` |
| P137-03 | Media | S-07 en ejecución: los `catch` de `ComprobarEfectivas` y `Revisar` (4743 con el tipo de la excepción y detención) sin prueba | `EscuchaServidor.cs:123-126, 159-162` |
| P137-04 | Media | «Sin modo + dirección fuera de loopback → 4746 y código ≠ 0» solo se prueba con Kestrel real en una prueba **omitida por omisión** (`GPOST_PRUEBA_ESCUCHA_RED=1`) | `EscuchaServidorKestrelTests.cs:134-147` |
| P137-05 | Media | La fuente de producción: se comprueba que `_comprobarSeguridad` es true, pero no que la raíz sea `HKLM` en la vista de 64 bits ni la subclave | `FuenteConfiguracionRed.Windows.cs:32` |
| P137-06 | Baja | Las pruebas con `WebApplicationBuilder` real y modo presente heredan el entorno real del proceso (`ASPNETCORE_URLS`, `*_HTTP_PORTS`, …) por `builder.Configuration` | `SoporteEscucha.Builder` |
| P137-07 | Baja | `ProgramaWebRedTests` busca texto: una línea comentada cuenta; `UseRechazoOrigenNodo` no tiene respaldo en tiempo de ejecución | `ProgramaWebRedTests.cs:36-54` |
| P137-08 | Baja | El contador estático `FuenteRedPruebasWeb.Lecturas` admite falso positivo si otra fábrica corre en paralelo | `ConfiguracionPruebas.cs`, `ProgramaWebRedTests.cs:171-175` |
| P137-09 | Baja | Bit `CreateLink` (0x0020) de `DerechosDeEscritura` sin caso propio: se puede quitar sin que falle nada | `FuenteConfiguracionRed.Windows.cs:96-97` |
| P137-10 | Baja | Posible fragilidad (inferida) al reescribir el JSON con recarga: escritura no atómica | `EscuchaServidorKestrelTests.cs:168, 189, 224` |
| P137-11 | Baja | «Se detiene una sola vez» y «4745 una sola vez» sin prueba; `reloadOnChange:false` sin efecto verificable | `EscuchaServidor.cs:73, 99, 195-200` |
| P137-12 | Baja | Prioridad `fuente ?? FuenteDePruebas ?? Crear()` sin prueba (la fuente explícita sobre la inyectada) | `EscuchaServidor.cs:59` |

No hay hallazgos Altos. Ninguno bloquea el #137; P137-01 a P137-05 los corregiría antes de unir porque cada uno deja una regla de seguridad descrita en el PR protegida por una sola línea sin prueba.

## Lo que está bien (verificado por lectura, mutación mental)

- **Cada código 4743-4746** tiene prueba con el `Id` exacto, el `Nombre` (4743, 4744, 4745, 4746) y el nivel: `ArranqueRedTests` (unitarias de `Evaluar`, `Exigir`, `ComprobarDirecciones`) y, con host real, `EscuchaServidorTests` y `EscuchaServidorKestrelTests` (4743 por Estricto sin registro, por fuente que lanza y por modo en la recarga; 4744 por línea de órdenes y por recarga de `Kestrel:Endpoints`; 4745 con `Warning`; 4746 con dirección HTTP real y con servidor sin direcciones). `Los_EventId_de_RT01_estan_en_la_franja` solo comprueba el rango, pero los valores exactos están fijados en las demás.
- **S-03, una prueba por elemento de cada lista** (quitar cualquier elemento de `ClavesDeEscucha`, `SeccionesDeEscucha`, `ClavesDeCodigoAjeno`, `VariablesDeEscucha`, `VariablesDeCodigoAjeno`, `VariablesReenvioMarco`, `VariablesIisFueraDeProceso` hace fallar un caso): `PORT`, `Kestrel:EndpointDefaults:Protocols`/`SslProtocols:0`, `hostingStartupAssemblies`, `ASPNETCORE_PORT`, `ASPNETCORE_/DOTNET_HOSTINGSTARTUPASSEMBLIES`, `DOTNET_STARTUP_HOOKS`. Además `Una_variable_de_entorno_del_proceso_llega_a_la_configuracion…` prueba con el `WebApplicationBuilder` real que el entorno llega a `builder.Configuration` con la clave esperada (7 variables), no solo con diccionarios; y el Motivo debe nombrar la fuente y no su valor.
- **`--urls`, `/urls`, `urls=` (y `--URLS`)**: `Las_formas_de_urls_en_la_linea_de_ordenes_llegan_a_la_regla_1` (builder real) y `Urls_por_linea_de_comandos_se_rechazan_con_modo` (`--urls=`, `--urls|…`, `/urls=`, `--http_ports`, `--https_ports`, `--Kestrel:Endpoints:…`); `Con_modo_una_fuente_de_direcciones_en_la_linea_de_ordenes_no_arranca_con_4744` pasa por `Preparar`/`ExigirArranque`.
- **S-02 cargador de Kestrel**: `Con_modo_Kestrel_no_lee_ni_recarga_su_seccion_de_la_configuracion` lee `KestrelServerOptions.ConfigurationLoader.Configuration` y exige que no sea una `IConfigurationSection` y no tenga hijos; `Sin_modo_Kestrel_conserva_su_seccion` da el contraste. Si se quita el `ConfigureKestrel` de `Preparar`, la primera falla. Bien hecho: no depende de abrir sockets.
- **S-02 recarga**: `Con_modo_un_Kestrel_Endpoints_agregado_con_el_servicio_corriendo…` y `Sin_modo_un_modo_de_red_agregado…` usan Kestrel real y un archivo JSON con recarga; esperan por `ApplicationStarted` (no por tiempo fijo), comprueban `ExitCode == 1` y el evento. Si se quita `ChangeToken.OnChange` o el `Detener()` de la rama `Denegado`, fallan (con `TimeoutException` a los 30 s, no con un cuelgue: `WaitAsync(Espera)`).
- **S1b-02 (lista vacía con modo presente)**: `Con_modo_un_servidor_sin_direcciones_efectivas…` es Theory con y sin `IServerAddressesFeature`; el caso contrario (`Sin_modo_un_servidor_sin_direcciones…`) exige exactamente dos 4745 `Warning` y ningún 4746. Invertir la condición `SinModo` o quitar `Detener()` rompe una u otra.
- **S1b-01 / S-05**: la DACL en bruto con SDDL real (`XA`/`XD`, `CIIO`), entrada de objeto, `CustomAce` desconocida, `CommonAce` con callback, sin DACL, dueño distinto, dueño TrustedInstaller, derechos uno por uno (salvo P137-09), y `Una_clave_real_con_una_entrada_condicional_se_lee_en_bruto…` que escribe una DACL real en una subclave de HKCU y comprueba que `DescriptorBruto` la ve condicional. Usa HKCU con GUID propio y limpia en `Dispose`; no toca HKLM.
- **La fuente de producción** comprueba la DACL: `La_fuente_de_produccion_comprueba_la_DACL` (reflexión sobre `_comprobarSeguridad`). Y las pruebas de arquitectura (S-04, S1b-03) fijan que la fuente y `FuenteDePruebas` son internas y que `src/` no las usa fuera de su archivo.
- **S1b-03**: `ConfiguracionPruebas` (Web.Tests) inyecta una fuente «sin modo» y `La_Web_de_prueba_lee_la_fuente_inyectada…` ejecuta la Web completa: sin ella se tendría que leer `HKLM`. Bien.
- **Web cableada con las 4 líneas de HB-14**: verifiqué en `Program.cs` de la rama las cuatro (`AgregarArchivoInstalacion`, `Preparar`, `ExigirArranque`, `UseRechazoOrigenNodo`), y la prueba fija el orden `archivo < Preparar < Build < ExigirArranque < UseForwardedHeaders < Run`, `rechazo < reenvío`, el Estricto de la Web (`ProteccionDatosWeb.EsEstricto(builder.Configuration)`) y que nada toca la configuración ni la escucha después (`Violaciones`, con 11 muestras que prueban que el detector detecta). `Preparar` y `ExigirArranque` además tienen respaldo en tiempo de ejecución (la prueba de la Web completa falla sin ellos).
- **Aislamiento del tiempo y del equipo**: ninguna prueba usa `Thread.Sleep` ni lee `HKLM`; las que cambian variables de entorno o `Environment.ExitCode` van en una colección con `DisableParallelization`, restauran en `finally` y respetan el valor previo (incluida la variable `ASPNETCORE_HOSTINGSTARTUPASSEMBLIES` que el propio proyecto fija).

## Hallazgos

### P137-01 (Media). La sobrecarga pública de `Preparar` no se ejerce; `DOTNET_STARTUP_HOOKS` y `GPOS_MODO_RED` dependen solo de esa línea

`EscuchaServidor.Preparar(builder, servicio, estricto, fuente)` (la que llaman `Program.cs` de la Web y, después, la API) delega en la interna con `Environment.GetEnvironmentVariable` (`EscuchaServidor.cs:37-38`). Todas las pruebas de `EscuchaServidorTests` y `EscuchaServidorKestrelTests` usan la sobrecarga **interna** con `SoporteEscucha.SinVariables`, y la prueba de la Web completa corre «sin modo». Dos fuentes solo se ven por el entorno directo, no por `builder.Configuration`:

- `DOTNET_STARTUP_HOOKS` (el prefijo `DOTNET_` produce la clave `STARTUP_HOOKS`, que no está en ninguna lista).
- `GPOS_MODO_RED` (`WebApplicationBuilder` carga el entorno sin prefijo como clave `GPOS_MODO_RED`, no `GPOS:Red:Modo`) (inferido del comportamiento por omisión del marco; los dos `ModosDeclarados` dependen de `entorno(VariableModo)`).

Mutación: cambiar la línea 38 a `_ => null` deja verdes las ~100 pruebas de esta rama y desactiva en producción la regla 3 (el modo solo sale del registro, por variable) y el rechazo de los ganchos de arranque.

**Prueba sugerida** (en `EscuchaServidorKestrelTests`, que ya está en la colección secuencial y ya sabe restaurar variables): fijar `DOTNET_STARTUP_HOOKS=C:\gancho.dll` en el proceso, crear el builder, llamar a la sobrecarga pública con `new FuenteRedFija(new LecturaRed.Valida(SoporteEscucha.Sitio()))`, y exigir `Denegado`/4744 con el nombre de la variable en el Motivo; ídem con `GPOS_MODO_RED=UnEquipo` frente a un registro `ServidorSitio` → 4743. Restaurar en `finally`.

### P137-02 (Media). Recarga sin modo con puntos de Kestrel malos, y recarga benigna

La rama de `Revisar` para `SinModo` (`EscuchaServidor.cs:142-157`: leer `Kestrel:Endpoints`, `DireccionesNoPermitidas`, 4746 por cada mala, `Detener`) no la recorre ninguna prueba. `Sin_modo_un_modo_de_red_agregado…` solo prueba la salida por `Denegado` (línea 136-141). Mutación: borrar el bloque `if (estado.Decision.Resultado == SinModo) {…}` completo no hace fallar nada. Es la única defensa de «sin modo» contra un punto añadido por recarga (el documento del PR la describe en el punto 4 de la cabecera de `EscuchaServidor`).

Tampoco hay prueba de la recarga que **no** debe detener (p. ej. cambiar `Kestrel:Limits:MaxRequestBodySize` o un valor ajeno): sin ella, una mutación que haga `Revisar` siempre `Detener()` pasa. Y la llamada final `ComprobarEfectivas()` de `Revisar` (línea 157) tampoco se ejerce.

**Pruebas sugeridas** (misma estructura que `Sin_modo_un_modo_de_red_agregado…`): (a) sin modo, escuchando en loopback, el JSON agrega `Kestrel:Endpoints:Abierto:Url = http://0.0.0.0:<puerto>` → `ExitCode == 1` y al menos un 4746 con «Kestrel:Endpoints»; (b) con modo y servicio corriendo, un cambio benigno → tras una espera corta y acotada (`Esperar` hasta que la recarga haya ocurrido, p. ej. leyendo `app.Configuration["x"]` actualizado), `ApplicationStopping` sigue sin cancelarse y `ExitCode` sigue en 0.

### P137-03 (Media). S-07 durante la ejecución: los `catch` de la vigilancia

La cabecera de `EscuchaServidor` promete (punto 5) que una excepción imprevista en cualquiera de los pasos deja 4743 con el tipo de la excepción. Solo se prueba la de la **fuente** al preparar (`Una_excepcion_imprevista_de_la_fuente…`). Los `catch` de `ComprobarEfectivas` (`:123-126`) y `Revisar` (`:159-162`) y `Imprevista` de la vigilancia (`:188-193`) no tienen prueba: quitar el `try/catch` (la excepción saldría por el callback de `ApplicationStarted` o del token) o el `Detener()` no hace fallar nada.

**Prueba sugerida**: `IServer` falso (como `ServidorSinDirecciones`) cuyo `Features` lance al leerse, con modo presente → `CorrerHastaDetenerse` devuelve 1, un 4743 `Critical` con `nameof(...)` de la excepción y sin el texto del mensaje (patrón de la prueba existente de S-07).

### P137-04 (Media). «Sin modo + 0.0.0.0 → 4746 y código ≠ 0» solo con una prueba omitida

`Sin_modo_urls_en_todas_las_interfaces_detiene_el_servicio_con_4746…` es `[FactEscuchaTodasLasInterfaces]`: queda **omitida** salvo con `GPOST_PRUEBA_ESCUCHA_RED=1`. Por lo tanto, en la suite oficial el camino de producción «sin modo, Kestrel enlazó fuera de loopback → 4746 + `ExitCode` + `StopApplication`» (`ComprobarEfectivas` con `SinModo`) no se ejerce con el cableado real; solo la unidad `ComprobarDirecciones_sin_modo_registra_4746…` en `ArranqueRedTests`. El motivo (ventana del cortafuegos) es razonable, pero se evita sin abrir sockets: el doble `ServidorSinDirecciones` ya existe; basta una variante con `IServerAddressesFeature.Addresses = {"http://0.0.0.0:5071"}` (y otra con `"https://[::]:5072"` para el puerto equivocado en modo sitio). La prueba real puede quedar como complemento de laboratorio.

### P137-05 (Media). La fuente de producción: raíz, vista y subclave no se afirman

`La_fuente_de_produccion_comprueba_la_DACL` fija `_comprobarSeguridad`, pero el constructor de producción (`FuenteConfiguracionRed.Windows.cs:32`) también decide `RegistryHive.LocalMachine`, `RegistryView.Registry64` y `ValoresRegistroServidor.Clave`. Esa es justo la garantía de S-04 («una de HKCU o la vista WOW6432Node la podría escribir cualquier usuario»), y `La_fuente_del_registro_es_interna_y_solo_la_crea_la_fabrica` solo mira nombres de constructores y que nadie use `ParaPruebas`. Mutación: cambiar `LocalMachine` por `CurrentUser` o `Registry64` por `Registry32` no hace fallar nada.

**Prueba sugerida** (solo lectura, sin tocar HKLM): con la misma reflexión, leer el campo `_raiz`, invocarlo (`using var k = raiz();`) y afirmar `k.Name == "HKEY_LOCAL_MACHINE"` y `k.View == RegistryView.Registry64`; leer `_subclave` y afirmar `== ValoresRegistroServidor.Clave`. Abrir la base de HKLM no requiere privilegios.

### P137-06 (Baja). Las pruebas con modo presente heredan el entorno real

`SoporteEscucha.Builder` crea un `WebApplicationBuilder` real: su `Configuration` incluye las variables de entorno del proceso (incluidas `ASPNETCORE_URLS`, `ASPNETCORE_HTTP_PORTS`, `DOTNET_URLS`, `ASPNETCORE_FORWARDEDHEADERS_ENABLED`, `TOKEN`, `APPL_PATH`… que pone IIS/ANCM o una imagen de contenedor). `SoporteEscucha.SinVariables` solo vacía la lectura **directa**. Las pruebas que esperan `ConModo` (`Con_modo_y_sin_otras_fuentes…`, `Con_modo_Kestrel_no_lee…`, `Con_modo_un_servidor_sin_direcciones…`, S-02) fallarían en un equipo o CI donde alguna de esas variables exista (p. ej. `ASPNETCORE_HTTP_PORTS=8080` en las imágenes `aspnet` de .NET 8+). Solo se quita la `hostingStartupAssemblies` propia del proyecto. En la PC del propietario es poco probable (inferido), pero es dependencia de entorno.

**Sugerencia**: en `Builder`, quitar la fuente de variables de entorno (`b.Configuration.Sources.OfType<EnvironmentVariablesConfigurationSource>()` → `Remove`) salvo en la Theory que prueba justamente que el entorno llega.

### P137-07 (Baja). Texto en `Program.cs`: comentarios y falta de respaldo en ejecución para el rechazo de nodos

`Unica` busca el fragmento con `IndexOf` sobre todo el archivo, comentarios incluidos: dejar `// app.UseRechazoOrigenNodo(red.IpNodos);` en comentario (o la línea dentro de un comentario) y añadir otra igual no cambia el resultado de «aparece exactamente una vez» salvo que se duplique. Para `Preparar` y `ExigirArranque` lo cubre la prueba en ejecución (`La_Web_de_prueba…` falla sin ellos), pero `UseRechazoOrigenNodo` no: la Web de prueba siempre es «sin modo» (`IpNodos` vacío) y `UseRechazoOrigenNodo` «sin nodos no agrega nada». Sugerencia: quitar los comentarios de línea antes de buscar (`Regex.Replace(t, @"//.*$", "", Multiline)`), y, si se quiere, una Web de prueba con una fuente `ServidorSitio` con un nodo para ver el 403 (esto último puede quedar para PR-4/Web; el filtro en sí está probado en #130).

### P137-08 (Baja). `Lecturas` estático compartido

`La_Web_de_prueba_lee_la_fuente_inyectada…` afirma `Instancia.Lecturas > antes`. `Instancia` es estática del ensamblado; otra fábrica de la Web (de otra clase, en paralelo) la incrementa también, así que la prueba podría pasar aunque **esta** Web no la leyera. Hoy la segunda aserción (el 4745 «no informa direcciones efectivas») respalda el resultado, pero conviene una fuente por fábrica o un contador por instancia (`new FuenteRedPruebasWeb()` inyectado con `ConfigureTestServices` no sirve porque la lectura es de `Program.cs`; basta fijarla antes de crear la fábrica y comparar contra una `Lecturas` exclusiva, o exigir `== antes + 1` con la clase en una colección secuencial).

### P137-09 (Baja). `CreateLink` sin caso propio

`DerechosDeEscritura` incluye `0x0020` (crear vínculos). `Escritura_para_otra_cuenta_no_es_aceptada` cubre `SetValue`, `CreateSubKey`, `Delete`, `ChangePermissions`, `TakeOwnership`, `WriteKey` (= 0x20006, ya lleva SetValue y CreateSubKey), `FullControl` y los genéricos; quitar `0x0020` no hace fallar nada. Añadir `[InlineData(RegistryRights.CreateLink)]`.

### P137-10 (Baja, inferido). Reescritura no atómica del JSON con recarga

Las pruebas de recarga usan `AddJsonFile(optional:false, reloadOnChange:true)` y `File.WriteAllTextAsync` sobre el mismo archivo. El proveedor de archivos espera 250 ms antes de recargar, lo que normalmente evita leer un archivo a medias, pero con un antivirus o un disco lento una lectura de un archivo vacío/truncado lanza en el hilo del temporizador (no optional) y puede tumbar el proceso de pruebas (inferido del comportamiento del marco; no lo verifiqué). Sugerencia: escribir a un archivo temporal y `File.Move(…, overwrite:true)`, o `AddJsonFile(..., optional:true)` con `OnLoadException` que lo ignore.

### P137-11 (Baja). Una sola detención; un solo 4745; `reloadOnChange:false`

- `Detener()` es idempotente (`Interlocked.Exchange`) y los críticos pueden repetirse: la prueba de la recarga lo dice en un comentario («se detiene una sola vez, pero el crítico puede repetirse») y no lo afirma. Quitar el candado no se detecta (`StopApplication` es idempotente).
- El 4745 por «sin direcciones» (`_avisoSinDirecciones`) solo se observa en el arranque (`Assert.Equal(2, …)`); la repetición tras una recarga no se prueba.
- `Configure(…, reloadOnChange:false)` sobre una configuración vacía no tiene diferencia observable (una `IConfiguration` vacía no dispara token); un cambio a `true` sería inocuo. No hace falta prueba; lo anoto para que nadie la busque.

### P137-12 (Baja). Prioridad de la fuente

`fuente ?? FuenteDePruebas?.Invoke() ?? FuenteConfiguracionRed.Crear()`. Se prueba la fuente explícita (con `FuenteDePruebas == null` en `GPOS.Tests`) y la inyectada (Web, con `fuente == null`). No se prueba que la explícita gane sobre la inyectada, ni que el último recurso sea `Crear()` (esto último no se puede probar sin leer HKLM salvo con la reflexión de P137-05). Menor.

## Riesgos que quedan fuera de este PR

- **La API no está cableada** (lo hace PR-4); el criterio «API con las 4 líneas» no aplica aquí y no tiene prueba equivalente a `ProgramaWebRedTests`. Cuando PR-4 la cablee, repetir esa prueba para `src/GPOS.Api/Program.cs`.
- **PR-4 y `ASPNETCORE_HOSTINGSTARTUPASSEMBLIES`**: el proyecto `GPOS.Tests` se registra a sí mismo como ensamblado de inicio en todo el proceso (`CarpetaLicenciaPruebas.Registrar`). `SoporteEscucha.Builder` lo quita de su configuración, pero cualquier fábrica de la API que arranque con **modo presente** (no ocurre hoy: las de la API correrán «sin modo» por `FuenteDePruebas`) recibiría un 4744 por S-03.
- `ProteccionDatosWeb.EsEstricto` en las Web de prueba depende de `GPOS__DataProtection__DpapiDemo` que fija `ConfiguracionPruebas`; no revisé qué hace con `Estricto` en una compilación Release (no es de este PR).
- Las pruebas de HKCU escriben en el perfil del usuario que las ejecuta; si una ejecución se corta antes de `Dispose` queda una subclave `Software\GPOS NG Pruebas\Red-<id>` (inocua).

## Qué no verifiqué

- **No compilé ni ejecuté nada**: ni `dotnet build`, ni `dotnet test`, ni SQL, ni arranqué Kestrel. No sé cuántas pruebas pasan ni si alguna falla hoy; mis afirmaciones son por lectura.
- No leí las pruebas de `FiltroOrigenNodo`/`OrigenNodo` (#130), `InterpretacionRed`, ni `ProteccionDatosWeb`, ni el resto de las 939 modificaciones del diff contra `master` (la rama incluye mucho más que el PR-1b: Reportes, Migración, KDS, etc.). Revisé solo los archivos que se me indicaron más `SoporteRed.cs` (captura de registro).
- No verifiqué el comportamiento del marco que infiero (carga del entorno sin prefijo en `WebApplicationBuilder`, el manejo de un JSON truncado en la recarga, ni que un `IServer` sustituido por un doble no dispare otras rutas de `GenericWebHostService`): están marcados como «inferido».
- No medí cobertura de líneas ni ejecuté mutaciones reales: la «mutación» es mental, línea por línea, sobre las clases listadas.
