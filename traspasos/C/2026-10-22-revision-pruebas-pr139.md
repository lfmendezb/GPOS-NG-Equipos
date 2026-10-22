Para: B        De: C        Fecha: 2026-10-22
Tipo: Revisión de pruebas (PR #139, ADR-90 RT-01/RT-06, PR-4: cableado de la API en Program.cs y retiro de FijarEscuchaPorOmision)
Repositorio y rama: GPOS-NG origin/a/adr90-pr4-cableado-api @ fcc3d3b9 (base: origin/a/adr90-rt05-escucha-servidor @ 99d5f79e, #137; la rama también trae #136, N-1)
Estado: Abierto

# Revisión de pruebas: #139 (PR-4)

Criterio (el de P120-01 y P130-01): para cada regla que el PR dice proteger, ¿hay una prueba que FALLARÍA si se quita o altera la línea que la protege (mutación mental)? Leí el diff contra el #137 con `git diff origin/a/adr90-rt05-escucha-servidor...origin/a/adr90-pr4-cableado-api` y los archivos con `git show`. Del #136 (N-1) miré solo lo que PR-4 toca o reutiliza.

## Resumen

| ID | Severidad | Qué | Dónde |
|---|---|---|---|
| P139-01 | Alta | El argumento `estricto` de `Preparar` en `Program.cs` no lo fija ninguna prueba: con `false` fijo, la API en Estricto sin modo (4743) arrancaría con aviso y ninguna prueba falla | `OrdenProgramaApiTests` S5 |
| P139-02 | Media | La cadena `Preparar` (sobrecarga pública/5 args) → `PuertoSinModo` → 5071 no la ejerce ninguna prueba: todas pasan el puerto explícito | `EscuchaSinModoApiTests` |
| P139-03 | Media | El analizador de `#if` solo entiende `DEBUG` y `!DEBUG` exactos: `#if false`, `#if RELEASE`, `#if DEBUG // x`, `#elif` se leen como código vivo | `ProgramaApiTexto.SinDebug` |
| P139-04 | Baja | S-06 (salida con 1) solo se prueba por texto; nada la ejercita; las excepciones de `UseFiltroOrigenNodo` quedan fuera del `try` | S6 / `Program.cs:363` |
| P139-05 | Baja | Nadie prohíbe `UseUrls` / `UseSetting("urls")` / `Listen…` en el resto de `src/GPOS.Api`; solo se mira `Program.cs` | S5, S7, `ApiModoServicioArquitecturaTests` |
| P139-06 | Baja | `DireccionesDeclaradas` se prueba con listas copiadas a mano: faltan `PORT` y 3 de las 7 variables de `ArranqueRed` | `EscuchaSinModoApiTests` |
| P139-07 | Baja | `Con_Estricto_y_sin_modo_no_se_arma_nada…` y `Con_modo_presente_no_se_arma…` no verifican que no se arme nada (solo 4743/4744 y `urls`) | `EscuchaSinModoApiTests` |
| P139-08 | Baja | Los dos humos con `TestServer` pasan aunque se quite el filtro o `UseForwardedHeaders`; el segundo no prueba lo que dice su nombre | `ApiSinModoHumoTests` |
| P139-09 | Baja | Flakiness menor: `PuertoLibre` (TOCTOU), `Assert.Null(["urls"])` depende del entorno del shell, `Assert.Equal(2, avisos.Count)` | varias |
| P139-10 | Baja | Huecos del analizador textual de `Program.cs` (genéricos anidados, alias de `app`, forma estática, lambda diferida, middleware en otro archivo) | `ProgramaApiTexto` |

Sin P139 bloqueantes salvo P139-01 (Alta): es una línea de regex en S5 y un caso `InlineData`.

## Foco 1: `OrdenProgramaApiTests` (S7 y orden del filtro)

Lo que está bien (por lectura):
- **Orden literal del filtro:** R1 (obligatoria, filtro antes de `UseForwardedHeaders`) y R2 (`UseForwardedHeaders` antes de todo lo demás salvo el filtro) juntas fijan filtro < ForwardedHeaders < el resto. Hay tres redes: R1/R2 por posiciones, `El_orden_del_middleware_es_el_fijado` (lista exacta, por líneas) y `Cada_regla_de_orden_falla_si_se_invierte…` (mueve `A` después de `B` en una copia del `Program.cs` real; exige que R1, R2, R3, R5, R6, R7 y R8 se hayan ejercitado). Si se quita el filtro, se mueve, se duplica o se pone bajo un `if`, fallan varias.
- **Filtro primero tras `Build`:** `El_arranque_de_red…` exige que entre `builder.Build()` y `try {` no haya nada (el texto limpio solo deja espacios), así que ni el filtro ni otra instrucción corren antes de `ExigirArranque`. Exige además que el filtro no sea condicional y que su argumento tenga forma `x.IpNodos`.
- **Comentarios y cadenas:** `Limpiar` quita `//`, `/* */` y `///`, vacía cadenas normales, textuales, interpoladas (con huecos y cadenas anidadas), crudas y caracteres. Una llamada comentada o dentro de un literal no cuenta; R1 es obligatoria, así que dejarla solo en un comentario hace fallar. Las pruebas `El_ayudante_*` lo cubren, con casos feos (URL con `//`, `'"'`, cadena cruda).
- **Mayúsculas:** C# distingue mayúsculas y los patrones son exactos; `app.useFiltro…` no compila. No hay evasión posible sin romper la compilación.
- **Líneas partidas:** los patrones usan `\s*` entre `app`, `.`, el nombre y `(`; `app\n  .UseX\n  (` se detecta. `FinSentencia` cuenta paréntesis, corchetes y llaves.
- **S7:** cubre `WebHost.`, `Host.`, `UseSetting`, `UseUrls`, `UseKestrel*`, `ConfigureKestrel`, `KestrelServerOptions`, fuentes nuevas, `Sources`, claves escritas (`=` y `??=`) también por alias `var config = builder.Configuration`, y después de `Preparar` `app.Urls`, `Listen…(` y `app.Run(url)`. `El_evaluador_de_S7_detecta_cada_via` tiene 15 vías y la prueba sobre copia del `Program.cs` real inserta una vía antes de `Build`.

Huecos (mutación que NO haría fallar nada):

**P139-01 (Alta): el argumento `estricto` de `Preparar` no está fijado.** `Program.cs:56` es `EscuchaServidor.Preparar(builder, ServicioRed.Api, GPOS.Core.Infraestructura.Anillo.ComprobacionAnillo.EsEstricto(builder.Configuration))`. S5 solo comprueba `ServicioRed.Api` en esa sentencia (`OrdenProgramaApiTests.cs:167`). Mutaciones que pasan toda la suite que leí: `…, ServicioRed.Api, false)`, o `EsEstricto(otraConfig)`, o `!EsEstricto(...)`. Con `false` fijo, la API en una instalación Estricta sin `ModoRed` en el registro arrancaría con el aviso 4745 en lugar de negarse con 4743: la falla cerrada de RT-01 se pierde justo donde importa. Las pruebas de 4743 (`Con_Estricto_y_sin_modo_no_se_arma_nada…`, `ArranqueRedTests`) llaman a `Preparar` con `estricto: true` a mano; ninguna pasa por `Program.cs`. La Web sí lo fija: `ProgramaWebRedTests.cs:40` y `:57` comparan la sentencia exacta con `ProteccionDatosWeb.EsEstricto(builder.Configuration)`.
Prueba sugerida (en S5, y un caso de más en `El_evaluador_de_S5_y_S6_detecta_el_desorden`):
```csharp
if (!Regex.IsMatch(sentencia, @"\bServicioRed\s*\.\s*Api\s*,\s*(?:[\w.]+\.)?ComprobacionAnillo\s*\.\s*EsEstricto\s*\(\s*" + b + @"\s*\.\s*Configuration\s*\)\s*\)"))
    errores.Add("S5: Preparar no recibe ComprobacionAnillo.EsEstricto(builder.Configuration) como estricto (RT-01: Estricto sin modo debe negarse con 4743).");
// InlineData("S5", false, "... Preparar(builder, ServicioRed.Api, false);", "")
```
Opcional, más fuerte: una prueba de comportamiento con una fábrica en Estricto y fuente «sin modo» que verifique 4743 (depende de cómo se enciende Estricto en `Pruebas`; no lo verifiqué).

**P139-03 (Media): `#if` distinto de `DEBUG`/`!DEBUG` se lee como código vivo.** `SinDebug` (`ProgramaApiTexto.cs`, la parte de directivas) empuja a la pila `(true,true)` solo si la condición es exactamente `DEBUG` y `(true,false)` solo si es `!DEBUG`; cualquier otra condición se trata como incluida y `#elif` no se procesa. Mutaciones que pasan: poner `app.UseFiltroOrigenNodo(red.IpNodos);` dentro de `#if false … #endif`, `#if RELEASE` (símbolo que Release no define), `#if NET8_0` (falso en net10) o `#if DEBUG // nota` (la condición queda «DEBUG // nota», no igual a «DEBUG», así que se incluye, lo contrario de lo que se pretendía). El filtro queda «presente y en orden» para R1 y no corre. La condicionalidad por `#if` tampoco se ve en `Condicional`.
Prueba sugerida: que `Limpiar` (o una prueba aparte sobre el `Program.cs` real) falle con cualquier directiva `#if`/`#elif` cuya condición no sea exactamente `DEBUG` o `!DEBUG` (tras quitar un comentario final), con un `InlineData` por `#if false`, `#if RELEASE`, `#if DEBUG || X` y `#elif`. Hoy el `Program.cs` real solo tiene `#if DEBUG` (línea 383), así que no cuesta nada.

**P139-10 (Baja): lo que el analizador textual no ve.** Todo lo siguiente deja pasar R1/R2 y el orden por líneas:
- `UseMiddleware<Foo<Bar>>()`: la expresión de genéricos `<[^<>();]*>` no admite anidados, así que la llamada no se cuenta (invisible para R2 y para el orden por posiciones).
- Alias: `var a = app; a.UseX();` o `((IApplicationBuilder)app).UseX()`.
- Forma estática: `Extensiones.UseX(app)` antes del filtro. (Si es el propio filtro, R1 obligatoria falla; si es otro middleware, no se ve.)
- Registro diferido: `Action f = () => app.UseFiltroOrigenNodo(red.IpNodos);` cuenta como llamada incondicional (no tiene `if` ni llaves) y nunca corre.
- Middleware agregado en otro archivo (una extensión de `src/GPOS.Api` que llama a `app.UseX` por dentro, o un `IStartupFilter`, que corre antes de todo el `Program.cs`). Busqué `IStartupFilter|IHostingStartup|UseStartup` en `src/GPOS.Api` y `src/GPOS.Comun.Servidor` y no hay hoy; ninguna prueba lo impide mañana.
No pido arreglarlos todos: son maneras de burlar la regla a propósito, no accidentes probables. Lo razonable es (a) una prueba que prohíba `IStartupFilter`/`IHostingStartup` en `src/GPOS.Api` y (b) anotar en el resumen de `ProgramaApiTexto` que es un análisis textual con esos límites.

## Foco 2: regla sin modo (`ListenLocalhost(5071)` en código, no `UseUrls`)

Bien cubierto (por lectura de `EscuchaServidor.cs` y `EscuchaSinModoApiTests`):
- `Sin_modo_y_sin_direcciones_declaradas…` arranca Kestrel real con puerto libre y exige `["http://localhost:{puerto}"]` como única dirección efectiva, 4745 una vez, ningún 4746, `ExitCode` sin cambio y respuesta 404 por `127.0.0.1`. Falla si se cambia `ListenLocalhost` por `ListenAnyIP`, si se quita el puerto o si se quita la rama.
- `Sin_modo_con_urls_declaradas_manda_la_configuracion…` con `--urls http://127.0.0.1:0`: la única efectiva es la de `--urls` y no el puerto armado. Falla si se quita `!DireccionesDeclaradas(...).Any()` (Kestrel ignoraría `urls` con una escucha en código). Es la prueba de «fuente declarada manda» para línea de órdenes; launchSettings y el DEMO llegan por `ASPNETCORE_URLS`, que solo se prueba en la unidad de `DireccionesDeclaradas` (no extremo a extremo; razonable).
- «`urls` no cuenta como fuente»: `Assert.Empty(ArranqueRed.FuentesDeEscucha(b.Configuration, SinVariables))` tras `Preparar` y `Assert.Null(sinModo.Configuration["urls"])`; con el modo presente, `ArranqueRed.Evaluar(... estricto: true)` da `ConModo` sobre la configuración armada (si `UseUrls` volviera, `urls` sería una fuente y daría 4744). Y `ApiSinModoHumoTests` repite `Assert.Null(["urls"])` sobre la API real.
- Consola 5000→5071: `El_puerto_sin_modo_es_el_5071…` fija la constante y que la Web no arma puerto.

**P139-02 (Media): la cadena hasta el 5071 no se ejerce.** Todas las pruebas con Kestrel usan la sobrecarga de 6 argumentos con un puerto libre explícito. La que usa `Program.cs` es la pública de 4 argumentos → la interna de 5 → `PuertoSinModo(servicio)` → la de 6. Mutaciones que pasan: la sobrecarga de 5 pasa `null`, o `5072`, o `PuertoSinModo` devuelve `null` para la Api. La constante (`PuertoApiSinModo`) y `PuertoSinModo(Api)`/`(Web)` están probadas por separado, pero no que la de 5 argumentos las use. Efecto: la consola (desarrollo, DEMO sin `ASPNETCORE_URLS`, pruebas) volvería a escuchar en 5000 y rompería `Api:Url` de la Web sin que falle ninguna prueba.
Prueba sugerida: exponer el puerto armado en `EstadoRed` (p. ej. `int? PuertoSinModoArmado`, null cuando no se armó) y probar con la sobrecarga de 5 argumentos: `Assert.Equal(5071, estado.PuertoSinModoArmado)` en Api sin modo y sin direcciones, `null` en Web, con direcciones declaradas, con modo y con Estricto. Sin tocar la red, sin puerto fijo. (Alternativa descartada: arrancar de verdad en 5071; el 5071 suele estar ocupado en la PC del propietario por el DEMO o `dotnet run`.)

**P139-06 (Baja): listas copiadas a mano.** `Las_direcciones_declaradas_por_la_configuracion…` prueba 4 casos (`urls`, `http_ports`, `https_ports`, `Kestrel:Endpoints`) y la de entorno 4 variables (`ASPNETCORE_URLS`, `DOTNET_URLS`, `ASPNETCORE_HTTP_PORTS`, `ASPNETCORE_PORT`). `ArranqueRed.ClavesDeEscucha` es `["urls","http_ports","https_ports","PORT"]` y `VariablesDeEscucha` tiene 7 (faltan `DOTNET_HTTP_PORTS`, `ASPNETCORE_HTTPS_PORTS`, `DOTNET_HTTPS_PORTS`). Si alguien dejara de recorrer una de ellas en `DireccionesDeclaradas` (o la sacara de la lista), no falla nada. En #130 el patrón era recorrer la lista de producción (`ArranqueRed.VariablesReenvioMarco`); aquí conviene lo mismo: `[MemberData]` desde `ArranqueRed.ClavesDeEscucha` y `ArranqueRed.VariablesDeEscucha`.

**P139-07 (Baja): dos pruebas prometen más de lo que miden.**
- `Con_Estricto_y_sin_modo_no_se_arma_nada_y_no_arranca_con_4743` solo verifica que `ExigirArranque` lanza 4743. Si se relajara `decision.Resultado == SinModo` y se armara el puerto con Estricto, pasa (es inocuo porque no arranca, pero el nombre dice otra cosa). Con el estado del P139-02 se puede afirmar «no se armó».
- `Con_modo_presente_no_se_arma_el_puerto_sin_modo…` en realidad prueba `sinModo.Configuration["urls"]` nulo y que `--urls` con modo da 4744; no inspecciona que, con modo, Kestrel no tenga `ListenLocalhost`. Hoy lo impide el orden `if/else if` (con modo gana la primera rama), así que es de nuevo P139-02.

## Foco 3: retiro de `FijarEscuchaPorOmision` e índices de `LineasServicio`

- Las 3 líneas que quedan (`WebApplication.CreateBuilder(ModoServicioApi.Opciones(...))`, `ComprobarArranque`, `Registrar`) se buscan por texto exacto (recortado) y se exige `indices` ascendentes, `[0]+1 == [1]` y `[1]+1 == [2]` (`ApiModoServicioArquitecturaTests.cs:71-76`). Un índice desalineado falla: insertar cualquier línea entre ellas, reordenarlas, cambiar su texto o volver a poner una cuarta línea de N-1 en medio. Con la adyacencia con `var builder = …`, nada (ni `AgregarArchivoInstalacion` ni `Preparar`) puede ir antes de la comprobación, porque `builder` aún no existe. Bien.
- Reintroducir el nombre: `Assert.DoesNotContain(lineas, l => l.Contains("FijarEscuchaPorOmision") || l.Contains("UseUrls"))` en `Program.cs`, más S5 (`UseUrls|FijarEscuchaPorOmision` sobre el texto limpio) y S7. Cubre `Program.cs`.
- Fragilidad (falla cerrada, no es hueco): la comparación es por línea completa; si alguien parte la línea de `CreateBuilder` en dos, la prueba falla aunque el orden sea correcto.
- Duplicado: si `ModoServicioApi.Registrar(…)` se repite más abajo, nadie lo ve (S1 solo cuenta los literales `AddWindowsService`/`UseWindowsService` para repetidos, no la costura). Baja; `AddWindowsService` es idempotente en la práctica, no lo verifiqué.

**P139-05 (Baja): `UseUrls` fuera de `Program.cs`.** Los chequeos (`DoesNotContain`, S5, S7) miran solo `Program.cs`. Si la escucha transitoria vuelve dentro de `ModoServicioApi.cs` u otro archivo de `src/GPOS.Api` (con otro nombre de método), el único freno es `Assert.Null(["urls"])` del humo, que corre en `Pruebas` y no en servicio ni consola. `La_API_no_tiene_otra_logica_de_servicio` ya recorre todos los `.cs` de la API pero solo busca systemd/servicio. Prueba sugerida: ahí mismo, prohibir en todo `src/GPOS.Api` `\bUseUrls\s*\(`, `UseSetting\s*\(\s*"urls"`, `KestrelServerOptions` y `\.Listen\w*\(`, con la excepción nombrada de `ConfigureKestrel(servidor.Aplicar)` (que está en `Program.cs`).

## Foco 4: salida con 1 ante `ArranqueRedException` (S-06)

- S6 exige que `ExigirArranque` esté en `try { … } catch (ArranqueRedException) { … }` y que el cuerpo del `catch` tenga `Environment.Exit(1)` o `Environment.ExitCode = 1;` más `return;`. Las 6 variantes de `InlineData` (sin try, `catch (Exception)`, sin código, sin `return`, con `Exit(1)`) y la prueba sobre copia del `Program.cs` real (quita el `try`, vacía el `catch`) lo protegen bien contra las mutaciones comunes.
- Un detalle: el cuerpo del `catch` no puede tener llaves (`[^{}]*`); un `if` dentro hace fallar S6 (falla cerrada, no es hueco).
- Escapan: poner `return;` antes de `Environment.ExitCode = 1;` (código inalcanzable; el compilador avisa, y no es probable) y lo que pase si `app.DisposeAsync()` lanza antes del `return`.

**P139-04 (Baja): sin prueba de comportamiento y alcance del `try`.**
- Nada ejerce que `Program` termine con 1: es solo texto. Se podría hacer con una fábrica en Estricto + «sin modo» (que da `ArranqueRedException` en `Program`), esperando que `WebApplicationFactory` lance «entry point exited without building a host», comprobando `Environment.ExitCode == 1` y restaurándolo. No verifiqué cómo se enciende Estricto en `Pruebas` (y `ExitCode` es global del proceso; haría falta la colección secuencial). Lo dejo opcional.
- `app.UseFiltroOrigenNodo(red.IpNodos)` (`Program.cs:363`) está fuera del `try`: lanza `ArgumentException` (IP de nodo no de un solo equipo) o `InvalidOperationException` (`ExigirSinReenvioDelMarco`). La regla 1 de RT-01 usa la misma lista de reenvío (`ArranqueRed.FuentesDeReenvio`), así que `ExigirArranque` debería negarse antes con 4743 → 1; no verifiqué que el caso del `ArgumentException` también lo detecte antes `InterpretacionRed`. Si no, el proceso caería con la excepción sin tratar (código de salida del tiempo de ejecución, no 1) y sin 4743. Las pruebas del filtro (#130) prueban las dos excepciones a nivel de la extensión, no a nivel de `Program`. Sugiero una prueba de unidad: toda IP de `IpNodos` que pueda salir de `Evaluar` es aceptada por `OrigenNodo.Conjunto` (misma validación), para que ese `ArgumentException` no sea alcanzable.

## Foco 5: flakiness

Bien:
- Ninguna prueba nueva enlaza un puerto fijo: `5071` aparece solo como dato en `Theory`/`InlineData` que no abren sockets; las de Kestrel real usan `127.0.0.1:0` o un puerto libre. `ListenLocalhost` es *loopback*, sin ventana del cortafuegos.
- Orden entre clases: las tres clases nuevas de red están en `EscuchaRedSecuencial` (`DisableParallelization = true`: corre sola, después de las paralelas; la propia definición dice por qué: `ExitCode` y variables de entorno que lee cualquier `WebApplicationBuilder`). Por eso el contador `FuenteRedPruebasApi.Lecturas` de `ApiSinModoHumoTests` no lo toca otra fábrica en paralelo.
- HKLM: `ConfiguracionPruebas` (`ModuleInitializer`) fija `EscuchaServidor.FuenteDePruebas` y la prueba exige `Lecturas > LecturasAlCrear`. Las demás pruebas pasan `FuenteRedFija`. `GPOS.Web.Tests` tiene su propio `ConfiguracionPruebas`. Las fábricas de `GPOS.Reportes.Tests` usan el `Program` de Reportes.Api, no el de la API (no lo audité más). Sin lecturas de HKLM real en lo que vi.
- `Esquema=Neutral` aquí significa neutral al esquema BP2/NG, no «sin SQL»: `ApiSinModoHumoTests` crea una base `GPOS_TEST_SIS_*` y la borra en `DisposeAsync`; necesita SQL en `GPOST_TEST_SERVER`.

**P139-09 (Baja): puntos frágiles menores.**
- `PuertoLibre()` abre y cierra un `TcpListener`: ventana TOCTOU entre cerrar y que Kestrel enlace. Probabilidad pequeña; ocurre en las dos pruebas de Kestrel real. Alternativa: `ListenLocalhost(0)` y leer el puerto de `IServerAddressesFeature` (cambiaría la prueba para que no compare el puerto armado; con el estado de P139-02 no hace falta).
- `Assert.Equal([$"http://localhost:{puerto}"], Efectivas(app))` asume el formato exacto que informa Kestrel para `ListenLocalhost` (`http://localhost:puerto`). Es lo que recuerdo del servidor, no lo comprobé ejecutando.
- `ApiSinModoHumoTests`: `Assert.Null(["urls"])` falla en un shell donde se haya exportado `ASPNETCORE_URLS` (p. ej. el de `tests/GPOS.EnsayoImplantacion/iniciar-api.ps1`, que lo fija en `$env:`) y se lance `dotnet test` desde él. Es el equipo del propietario. Sugerencia: aislar la variable en la fábrica (`UseSetting("urls", null)` no basta; limpiar la variable de proceso en el `ModuleInitializer`) o afirmar con `ArranqueRed.FuentesDeEscucha(config, SinVariables)` vacío.
- `Assert.Equal(2, avisos.Count)` de 4745 acopla la prueba al número exacto de avisos de la vigilancia (arranque + «no informa direcciones»). Una recarga de configuración con otra fuente tras `ApplicationStarted` no lo cambia (hay guarda `_avisoSinDirecciones`), pero un tercer aviso legítimo futuro la rompería. Aceptable.
- Tiempos: esperas de 30 s con `WaitAsync`; sin `Sleep` ni cronómetros. Bien.

## Otras observaciones

**P139-08 (Baja): los humos con `TestServer` no prueban el cableado.** `La_API_arranca_sin_modo…` pasa aunque no estuviera `UseFiltroOrigenNodo`; `Sin_nodos_el_filtro_de_origen_deja_pasar_y_los_encabezados_reenviados_siguen_igual` envía `X-Forwarded-For` pero no mira qué IP vio el resto de la canalización (con `TestServer` la IP de la conexión es nula y, sin nodos, el filtro ni mira): pasa si se quita el filtro y también si se quita `UseForwardedHeaders`. El nombre promete «los encabezados reenviados siguen igual». Para que pruebe algo: un endpoint de prueba o la bitácora de `LimitesPeticiones.Ip` que devuelva la IP con `X-Forwarded-For` de un `KnownProxy`; o renombrar a «humo». Con nodos no se puede en una fábrica (con el modo presente, `TestServer` da 4746 y se detiene), así que el cableado `red.IpNodos` solo lo cubre el texto de `El_arranque_de_red…` (`\(\s*\w+\s*\.\s*IpNodos\s*\)`: acepta cualquier identificador antes de `.IpNodos`; compila solo con `red`, pero el regex es más flojo de lo que parece). `EstadoRed.IpNodos` sí está probado en `EscuchaServidorTests`.

N-1 / #136: lo que PR-4 cambia del #136 (`IdentidadServicio` del agente delega en `IdentidadProceso` compartida por `Compile Include` con enlace) está cubierto por `S07_un_solo_calculo_del_SID…` (valores conocidos de tres servicios) y por `EstacionImpresionTests` (`PrivilegiosSobrantes`, `PrivilegiosDelProceso`, `SidActual`), que siguen llamando a `IdentidadServicio`. Sin hallazgos nuevos ahí.

## Mutaciones mentales: tabla

| Mutación (línea que protege) | ¿Falla alguna prueba? |
|---|---|
| Quitar `app.UseFiltroOrigenNodo(red.IpNodos)` | Sí: R1, `El_orden_del_middleware…`, `El_arranque_de_red…` |
| Filtro después de `UseForwardedHeaders` o de otro middleware | Sí: R1, R2, orden exacto, inversión sobre copia real |
| Filtro bajo `if` | Sí: `El_arranque_de_red…` (Condicional) |
| Filtro bajo `#if false` / `#if RELEASE` | **No** (P139-03) |
| Filtro con otro argumento (`new HashSet<IPAddress>()`) | Sí: regex `x.IpNodos` |
| Algo corre entre `Build()` y el `try` de `ExigirArranque` | Sí: `El_arranque_de_red…` (rebanada solo con `try {`) |
| `Preparar` quitado, repetido, con `ServicioRed.Web`, tras `Build` o antes de `AgregarArchivoInstalacion` | Sí: S5 |
| `Preparar(…, estricto: false)` fijo | **No** (P139-01) |
| `ExigirArranque` sin `try`, `catch (Exception)`, sin `ExitCode`/`return` | Sí: S6 |
| `UseUrls` / `FijarEscuchaPorOmision` en `Program.cs` | Sí: `DoesNotContain`, S5, S7 |
| `UseUrls` en otro archivo de `src/GPOS.Api` | Parcial: solo `Assert.Null(["urls"])` en `Pruebas` (P139-05) |
| `ListenLocalhost` → `ListenAnyIP`; quitar `!DireccionesDeclaradas().Any()`; quitar la rama | Sí: pruebas de Kestrel real |
| La sobrecarga de 5 args deja de usar `PuertoSinModo` / pasa otro puerto | **No** (P139-02) |
| `PuertoApiSinModo` 5071 → otro | Sí (constante) |
| `DireccionesDeclaradas` deja de mirar `PORT` / `*_HTTPS_PORTS` | **No** (P139-06) |
| Índice de `LineasServicio` desalineado, línea insertada o cuarta línea | Sí: adyacencia y `DoesNotContain` |
| Puerto armado también con Estricto | No, pero es inocuo (P139-07) |

## Qué no verifiqué

- **No compilé ni ejecuté nada**: ni `dotnet build`, ni `dotnet test`, ni SQL, ni el servicio. Todo es lectura con `git show`/`git diff` de `origin/a/adr90-pr4-cableado-api` (fcc3d3b9). No sé si las pruebas pasan hoy; los comportamientos de Kestrel y de `WebApplicationFactory` que menciono (formato `http://localhost:puerto`, efecto de una escucha en código sobre `urls`, que un `Main` asíncrono con `return` respete `Environment.ExitCode`) son lo que sé del marco, no algo que probé aquí.
- No ejecuté los regex de `ProgramaApiTexto` ni `OrdenProgramaApiTests` contra el `Program.cs` real: las evasiones de P139-03 y P139-10 las deduje leyendo el código del analizador, no con un programa de muestra.
- Leí completos `OrdenProgramaApiTests`, `ProgramaApiTexto`, `ApiModoServicioArquitecturaTests`, `EndurecimientoServicioApiTests`, `ModoServicioApiTests`, `ApiModoConsolaTests`, `ApiSinModoHumoTests`, `EscuchaSinModoApiTests` y `ConfiguracionPruebas`. De `ModoServicioArquitecturaTests` leí solo las primeras ~140 líneas (B-01 a B-05); no revisé el resto. De `EscuchaServidorKestrelTests` solo la cabecera y la definición de la colección. No revisé las pruebas de #130/#122 que ya revisé el 2026-10-21, ni `GPOS.Web.Tests` salvo la existencia de su `ConfiguracionPruebas`.
- No audité `GPOS.Reportes.Api`, el MSI ni el comportamiento como servicio instalado (eso es del ensayo de devops); ni el efecto de que el proceso salga con 1 antes de registrarse ante el Administrador de servicios.
- No verifiqué cómo se enciende el modo Estricto en el entorno `Pruebas` ni si `InterpretacionRed` rechaza IP de nodo no válidas antes de que lleguen a `UseFiltroOrigenNodo` (P139-04).
- No revisé la corrección del código de producción más allá de lo necesario para razonar sobre las pruebas.

Sin código tocado, sin SQL, sin commit ni push.
