Para: B        De: A (auditor-seguridad)        Fecha: 2026-10-22
Tipo: Revisión de seguridad (tarea 2): PR #152, T4-01 (Ola 5, tramo 4): render en la API de reportes, aditivo
Repositorio y rama: GPOS-NG `origin/b/ola5-t4-01-render` @ `cf6ccf98` (punta verificada con `gh pr view 152` y `git rev-parse`), base `feature/modelo-ng`
Estado: Abierto

# Informe de seguridad: #152 (T4-01)

**Método.** Solo lectura: `gh pr view/diff`, `git show origin/b/ola5-t4-01-render:<ruta>`, `git grep`. Nada compilado ni ejecutado; no se cambió de rama en ningún árbol. Además se leyeron las cadenas de `PuppeteerSharp.dll` 25.12.0 de la caché de NuGet de la PC A (sin ejecutarla) para saber qué transportes ofrece. **[V]** = verificado en código o en git con `ruta:línea` (rama del PR salvo que se diga otra); **[I]** = inferido (comportamiento de Chromium, Windows o .NET que hay que confirmar). Sin secretos, sin pasos de explotación ni cargas (C10).

**Fuentes leídas.** Aviso `avisos/B-a-A/2026-10-22-respuesta-s16-pr152-y-fechas-ola5.md` (sección 2); `traspasos/C/2026-10-22-revision-pruebas-pr152-t4-01-y-dorados.md` y `traspasos/C/2026-10-22-revision-correcciones-pr152.md`; cuerpo y comentarios del #152 (la revisión de seguridad de B con los S152-xx no está como archivo en el área común: tomo su contenido del aviso y del cuerpo del PR); plan `origin/master:docs/arquitectura/2026-10-19-ola5-tramo4-plan-de-trabajo.md` (T4-01, T4-03, H-T4-09, R-T4-03); `origin/master:docs/adr/ADR-109.md` cl. 1, 6, 12 y 13; `origin/master:docs/adr/ADR-110.md` cl. 7 y su precisión del 2026-10-20; mi dictamen `traspasos/A/dictamen-seguridad-demo-jwt-d5-2026-10-22.md` (DM-04, DM-11, DM-12).

## 1. Alcance y superficie revisada

| Superficie | Exposición | Evidencia |
|---|---|---|
| `POST /interno/render/{documento,cierre,conduce,resultado}` | Solo por la canalización con nombre de la exportación (ACL: dueño = cuenta del servicio; lectura y escritura para la cuenta de la principal; NETWORK denegado). Por el *listener* HTTP de loopback: 404 | [V] `Endpoints/EndpointsRender.cs:31-39`, `:67`; `Program.cs:99-104`; `Endpoints/ServiciosReportes.cs:93`, `:117-124` |
| Autenticación | Token del usuario por introspección (caché de 15 s), política por omisión que exige sesión | [V] `Seguridad/ServiciosSeguridadReportes.cs:16-17`; ADR-109 cl. 6 |
| Motor Razor (Roslyn) en proceso | Compila y ejecuta la plantilla que llega **en el cuerpo** (`FormatoImpresionDto.Plantilla`) | [V] `Impresion/ServicioRender.cs:39-41`, `Impresion/MotorRazor.cs:72-98` |
| Chromium (PuppeteerSharp 25.12.0) | Proceso hijo de la cuenta `NT SERVICE\GPOS.Reportes`; **se lanza al arrancar el servicio** por el precalentamiento, aunque nadie llame las rutas | [V] `Impresion/ServiciosRender.cs:38`, `:49-66`; `appsettings.json:41` (`Precalentar: true`); `Impresion/ConvertidorPdf.cs:87-110` |
| QuestPDF (estándar, cierre, conduce, resultado) | En proceso, sin código de usuario | [V] `Impresion/ServicioRender.cs:49-73`, `:101-105` |
| Tareas en segundo plano | `PrecalentadorRender` | [V] `Impresion/ServiciosRender.cs:49-73` |

Fuera de alcance: la principal (`GPOS.Api`), salvo para comprobar de dónde vienen los datos; T4-02 y T4-03 (solo como condiciones).

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título | Estado |
|---|---|---|---|
| R152-01 | — | S152-01/P152-01: dos barreras para `/interno/render/*` | **Cerrado** [V] |
| R152-02 | — | P152-04: 401 en las 4 rutas; validación por petición | **Cerrado** [V] (matiz: revocación visible en ≤ 15 s por la caché, por diseño de la cl. 6) |
| R152-03 | — | P152-05: el cuerpo no se lee antes de autenticar; 16 MB → 413 | **Cerrado** [V] |
| R152-04 | Media | S152-02: una plantilla Razor que no termina (o que desborda la pila o la memoria) degrada o tira el servicio | Abierto; decisión en 6.1 |
| R152-05 | Media | S152-03/P152-08: Chromium con JavaScript y sin interceptar peticiones; el logo no se revalida al renderizar (cl. 7) | Abierto; decisión en 6.2 |
| R152-06 | Media | **Nuevo.** Chromium se controla por un puerto TCP de depuración en loopback sin autenticación (transporte por omisión de PuppeteerSharp) | Abierto [V opción / I por omisión] |
| R152-07 | Media | DM-11 aplicado al #152: perfil de Chromium en `TEMP`, nombre de 32 bits, nunca se borra | Abierto [V] |
| R152-08 | Media | La lista negra de `ValidadorPlantillas` es evadible; la plantilla Razor corre con las credenciales y la memoria del servicio de reportes | Abierto (riesgo existente; el PR reduce el impacto frente a la principal) [V/I] |
| R152-09 | Baja | Caché de plantillas sin tope: cada contenido distinto queda en memoria y su ensamblado compilado no se descarga | Abierto [V/I] |
| R152-10 | Baja | Un formato `Visual` sin `Diseno` ejecuta `Plantilla` como Razor (no falla cerrado) | Abierto [V] |
| R152-11 | Baja | Cuerpo leído y deserializado **antes** de tomar cupo: la memoria de lectura no la acota el grupo de concurrencia | Abierto [V] |
| R152-12 | Baja | `PorCanalInterno` acepta cualquier canalización, no la de nombre esperado | Abierto [V] |
| R152-13 | Baja | DM-04 aplicado al #152: Chromium hereda el entorno del servicio de reportes | Abierto [V/I] |
| R152-14 | Baja | Las rutas de render no leen `rptsis` (cl. 6 dice «en cada petición»): desvío aceptable que debe quedar escrito | Abierto (documental) [V] |

Ningún hallazgo Crítico ni Alto abierto.

## 3. Checklist OWASP Top 10 (2021)

| Categoría | Resultado | Hallazgos |
|---|---|---|
| A01 Control de acceso | Bien: doble barrera, ACL de canalización, política por omisión. Matices | R152-01, R152-02, R152-06, R152-07, R152-12, R152-14 |
| A02 Fallas criptográficas | No aplica al render (no cifra ni firma; la huella SHA-256 truncada a 96 bits de `ProveedorPlantillas` solo nombra archivos) | — |
| A03 Inyección | Datos del modelo codificados por Razor; `Html.Raw` prohibido; `GeneradorRazor` codifica y escapa `@` [V `GPOS.Contracts/Impresion/GeneradorRazor.cs:152`]. Código Razor del SUPER: R152-08 | R152-08, R152-10 |
| A04 Diseño inseguro | Razor en proceso sin aislamiento de CPU, pila ni memoria | R152-04, R152-09, R152-11 |
| A05 Configuración de seguridad | Chromium sin intercepción, con JS y con puerto de depuración; perfil en `TEMP` | R152-05, R152-06, R152-07 |
| A06 Componentes vulnerables | Sin herramienta de análisis ejecutada (no se corrió `dotnet list package --vulnerable`). Versiones iguales a la principal [V PR, `.csproj:20-22`]. Chromium es el del sistema (Chrome/Edge): su parcheo depende de Windows Update/Edge Update del cliente [I] | Supuesto |
| A07 Identificación y autenticación | Introspección por petición, 401 en las 4 rutas, falla cerrada | R152-02 |
| A08 Integridad de software y datos | Plantillas compiladas desde el cuerpo de la petición (confianza en la principal; la huella de la precisión de cl. 7 llega con T4-10). D-25 toca la integridad del documento impreso | R152-08, D-25 |
| A09 Registro y monitoreo | 500 sin detalles internos y traza solo de los no esperados [V `ErroresReportes.cs:29`, `:32`]; el registro de imagen omitida no lleva contenido [V `ServicioRender.cs:42-45`]. Falta evento de render abandonado/hilo huérfano | R152-04 |
| A10 SSRF | Chromium puede pedir URL externas o de loopback desde la cuenta del servicio | R152-05 |

## 4. Hallazgos

### 4.1 Correcciones pedidas (alcance 1)

**R152-01 — S152-01/P152-01: cerrado [V].**
- Primera barrera: `UsarRutasInternasSoloPorCanal` responde 404 antes de la autenticación si la conexión no es de canalización (`EndpointsRender.cs:31-39`), registrada antes de `UseAuthentication` (`Program.cs:99-100`).
- Segunda barrera: `RenderAsync` responde 404 fuera de la canalización **antes** de crear el plazo y de leer el cuerpo (`EndpointsRender.cs:67` < `:73`). Con esta barrera las variantes de ruta que el filtro no reconozca (prefijo con segmentos codificados, barras dobles: P152-09 de C) dejan de importar para el render: el punto final mismo exige la canalización.
- Prueba del `Program` real (`RenderInternoTests.cs:282`) y prueba sin filtro (`:241`): la revisión de C las somete a mutación y coincido.
- Residuo sin severidad propia: si falta la primera barrera, una petición HTTP sin token recibe 401 (no 404) porque la autorización corre antes del punto final; revela la ruta pero no da acceso. La prueba del `Program` real lo detecta. La prueba solo corre en Debug (P152b-03 de C): la segunda barrera cubre la compilación Release.

**R152-02 — P152-04: cerrado [V].** La política por omisión exige usuario autenticado con el esquema de introspección (`ServiciosSeguridadReportes.cs:16-17`); el grupo `MapGroup` no tiene `AllowAnonymous` (`EndpointsRender.cs:43`). La `Theory` cubre las 4 rutas (`RenderInternoTests.cs:340-345`) y la revocación en la misma conexión (`:368`). Matiz (P152b-01 de C, coincido): en producción la revocación se ve en ≤ 15 s por la caché del verificador; es lo firmado en ADR-109 cl. 6 («caché de 15 s, falla cerrada»), no un defecto. Pido solo que el nombre o el comentario de la prueba no prometa revocación inmediata.

**R152-03 — P152-05: cerrado [V].** El cuerpo se lee dentro del punto final (`EndpointsRender.cs:73`), que corre después de autenticación y autorización; no hay `[FromBody]` ni `app.Use` que lo lea antes. Doble control del tope: `ContentLength` (`:92`) y acumulado en *streaming* (`:98`), de modo que una petición sin longitud no lo evade. El JSON inválido da 400 sin detalles (`:107-110`). Matiz de prueba (P152b-02 de C): un *middleware* futuro que leyera sin efectos visibles antes de autenticar no lo detecta la prueba; la mejora barata que propone C (cuerpo anunciado y no enviado con token inválido → 401 inmediato) la recomiendo, no la exijo.

**Regresiones o evasiones de las correcciones:** no encontré. La segunda barrera no cambia la respuesta de las rutas de reportes; el 401 por las 4 rutas no abre `AllowAnonymous` en ningún lado; el tope de 16 MB no altera el de 10.000 filas de `/resultado` (`ServicioRender.cs:69-71`). Nuevo residuo de diseño en R152-11 (memoria de lectura fuera del cupo), que ya existía antes de las correcciones.

### 4.2 Revisión general (alcance 2)

**R152-04 (Media) — S152-02: plantilla Razor sin fin, desbordamiento de pila o de memoria.**
- **Riesgo.** El trabajo corre con `Task.Run(..., CancellationToken.None)` y libera el cupo solo al terminar de verdad (`EndpointsRender.cs:78-79`); `RenderAsync` de la vista no observa cancelación (`MotorRazor.cs:98`); el grupo es un `SemaphoreSlim` de 4 (`TurnosRender.cs:10`; `OpcionesRender.cs:31`) compartido por estándar y personalizado. Coincido con B y C: cuatro renders que no terminan dejan **todas** las impresiones, también los tickets estándar de QuestPDF, en 429 hasta reiniciar, con 4 núcleos ocupados.
- **Lo que falta en el análisis de B [V/I].** El validador prohíbe `@functions` pero no los bloques de código ni las funciones locales (`ValidadorPlantillas.cs:33-37`) [V], así que una plantilla con recursión sin fin es posible [I]; un desbordamiento de pila **no se puede capturar en .NET y termina el proceso** [I: comportamiento documentado de .NET], es decir, cae también la exportación y los reportes hasta que el Administrador de servicios lo reinicie (si está configurado para hacerlo). Una plantilla que reserve memoria sin medida choca con `HeapHardLimit` de 768 MiB (`GPOS.Reportes.Api.csproj:47`, 805306368) y el `OutOfMemoryException` puede afectar a peticiones ajenas que reservan en ese momento [I]. El bucle sin fin es solo uno de tres modos de fallo.
- **Quién lo dispara.** Solo el SUPER crea o edita y previsualiza modo Razor [V `GPOS.Core/Servicios/FormatosService.cs:85`, `:160`; `GPOS.Api/Endpoints/ImpresionEndpoints.cs:71`]. Probabilidad: baja, y casi siempre accidental. Impacto: alto en operación (caja sin tickets). Media.
- **Remediación:** ver la decisión 6.1.

**R152-05 (Media) — S152-03/P152-08: Chromium con JavaScript y sin intercepción; logo sin revalidar.**
- **Riesgo.** `SetContentAsync` sin `SetRequestInterceptionAsync` ni `SetJavaScriptEnabledAsync(false)` (`ConvertidorPdf.cs:40-43`); argumentos sin restricción de red (`:106-110`) [V]. Un recurso con URL en el HTML hace que Chromium pida esa dirección desde la cuenta del servicio, también a servicios de **loopback** del propio equipo [I], lo que contradice ADR-110 cl. 7 («solo acepta recursos `data:`») y ADR-109 cl. 12 («red saliente bloqueada salvo SQL Server y la principal").
- **Hueco concreto [V].** ADR-110 cl. 7 exige validar las imágenes «al guardar **y al renderizar**». El logo de la empresa se valida al guardar en la principal (`GPOS.Core/Servicios/AdministracionService.cs:81`), pero el render lo emite tal cual en `src` (`GPOS.Contracts/Impresion/GeneradorRazor.cs:101`; también las plantillas base, según C) sin comprobar que sea `data:`; las imágenes del diseño sí se revalidan al generar (`GeneradorRazor.cs:104-108`). Un logo con URL que entre por un camino que no sea `AdministracionService` (datos heredados, importación, escritura directa) llegaría a Chromium [I]. El logo lo administra el ADMIN de cada empresa, no solo el SUPER: es la vía más probable.
- **Cortafuegos.** El de Windows no filtra *loopback* por omisión [I]: la regla por cuenta del servicio (INS 2.1) es una buena segunda capa para salidas a la red, pero **no** cubre las peticiones al propio equipo. La intercepción en Chromium es el control efectivo.
- **Memoria de Chromium.** Los procesos de render de Chromium no cuentan para `HeapHardLimit`; sin el *Job Object* de T4-03 una página puede consumir memoria del servidor que comparte con SQL Server [I].
- **Remediación:** ver la decisión 6.2. En T4-01, barata y recomendada: rechazar en el render un `Empresa.Logo` que no sea `data:image/(png|jpeg|gif|webp);base64,` (la misma expresión de la principal), ~0,1 dp.

**R152-06 (Media) — Nuevo: puerto de depuración de Chromium en loopback.**
- **Evidencia.** `LaunchOptions` sin `Pipe` (`ConvertidorPdf.cs:106-110`) [V]. La DLL de PuppeteerSharp 25.12.0 contiene los dos transportes: `--remote-debugging-port=0` y `--remote-debugging-pipe`, con la propiedad `Pipe` [V: cadenas de `lib/net8.0/PuppeteerSharp.dll` en la caché de NuGet]. Por omisión usa el puerto [I: comportamiento de Puppeteer; confirmar con `netstat -ano` sobre el proceso de Chromium en la máquina de pruebas].
- **Riesgo [I].** El protocolo de depuración en `127.0.0.1` no pide autenticación. Cualquier proceso local de **otro** usuario del servidor (en tiendas pequeñas el servidor suele ser también una caja con sesión de Windows) podría tomar el control del navegador que corre como `NT SERVICE\GPOS.Reportes`: ver los documentos que se renderizan y leer archivos a los que esa cuenta tiene acceso, entre ellos los temporales de exportación de cualquier empresa en `%ProgramData%\GPOS NG\Reportes\temp`. Eso anula el aislamiento entre empresas y la ACL de la canalización por una vía lateral.
- **«Aditivo» no lo cubre.** El precalentamiento está activo por omisión (`appsettings.json:41`; `ServiciosRender.cs:38`) [V]: al desplegar el #152, Chromium arranca con el servicio aunque nadie llame las rutas. La principal tiene el mismo patrón hoy (`GPOS.Api/Impresion/ConvertidorPdf.cs`, según mi dictamen DM-12) [V en el dictamen].
- **Remediación.** `Pipe = true` en `LaunchOptions` (una línea; ~0,1 dp con su prueba: el proceso de Chromium no escucha en TCP, o sus argumentos llevan `--remote-debugging-pipe`). Aplicarlo también en la principal mientras siga renderizando. Alternativa descartada: filtrar el puerto con el cortafuegos (no filtra *loopback*).

**R152-07 (Media) — DM-11 aplicado al #152: perfil de Chromium.**
- **Evidencia [V].** Perfil en `Path.GetTempPath()\gpos-pdf-navegador\<8 hex>` (`ConvertidorPdf.cs:101-102`), nombre de 32 bits, sin borrado en ningún punto de la clase (`:126-130`). Con el servicio, `TEMP` puede resolver a una carpeta compartida [I]; la carpeta intermedia la puede crear antes otro usuario con su ACL [I].
- **Remediación** (mi dictamen DM-11, sin cambios): `%ProgramData%\GPOS NG\Reportes\render` con SDDL `O:SYG:SYD:PAI(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICI;0x1301bf;;;<SID de NT SERVICE\GPOS.Reportes>)`; (i) comprobar al arrancar dueño y que no sea punto de reanálisis; (ii) subcarpeta por arranque de 128 bits; (iii) borrarla al cerrar el navegador y purgar restos al iniciar; (iv) sin código: `TMP`/`TEMP` del servicio en `%ProgramData%\GPOS NG\Reportes\temp`. El plan de T4-03 dice «perfil en la carpeta temporal del servicio» (plan, T4-03): vale si esa carpeta cumple (i) a (iii). ~0,5 dp.

**R152-08 (Media) — Razor: lista negra evadible, código con el poder del servicio.**
- **Evidencia.** El validador es una expresión regular de construcciones prohibidas (`ValidadorPlantillas.cs:33-38`) [V]; el propio comentario dice «no es un aislamiento completo» (`:8`) [V]. Hay sintaxis válida de C# que la expresión no normaliza y que permite escribir nombres prohibidos sin que coincidan [I; no detallo cuál, C10]. La plantilla corre dentro del proceso que tiene las credenciales selladas de lectura, el contexto de `rptsis` y, en memoria, los modelos y tokens de las peticiones de otras empresas [I].
- **Contexto.** Hoy ocurre en la principal, que tiene credenciales de escritura: mover Razor a reportes **reduce** el impacto (ADR-109 cl. 1). Solo el SUPER escribe Razor [V, R152-04]. Riesgo interno y de baja probabilidad, impacto alto (confidencialidad entre empresas): Media, no bloquea.
- **Remediación.** La de fondo es Razor fuera del proceso, con cuenta o *token* restringido sin acceso a credenciales (decisión del 20-nov, ver 6.1). Mientras tanto: Razor sigue siendo solo del SUPER (ADR-110 cl. 3) y no se abre al ADMIN bajo ninguna forma antes del proceso hijo; la huella y la marca `GuardadoPorSuper` de la precisión de cl. 7 (T4-10) se aplican también en el camino temporal de A-1, como ya está firmado.

**R152-09 (Baja) — Caché de plantillas sin tope.** `ProveedorPlantillas` guarda cada contenido distinto en un `ConcurrentDictionary` sin expulsión (`MotorRazor.cs:25-33`) [V]; la compilación en tiempo de ejecución carga un ensamblado por vista que no se descarga [I]. Con T4-02, cada vista previa del SUPER con un cambio suma una entrada: crecimiento hasta reiniciar, contra 768 MiB (R-T4-03). Remediación: contador y evento al pasar N plantillas distintas (p. ej. 500), reinicio controlado por encima de un tope, y medirlo en B9. Con el proceso hijo desaparece (el hijo se recicla). ~0,25 dp.

**R152-10 (Baja) — `Visual` sin `Diseno` ejecuta `Plantilla`.** `ServicioRender.cs:39-41` [V] usa `f.Plantilla` si el modo es visual y falta el diseño. El ADMIN crea formatos visuales (`ImpresionEndpoints.cs:71`) [V]; la principal exige el diseño al guardar (`FormatosService.cs:78`) [V], de modo que solo llegaría por datos heredados o un error de la principal en T4-02 [I], pero entonces ejecutaría como Razor un texto que no escribió un SUPER. Remediación: modo visual sin diseño → 400 `FORMATO_INVALIDO`; Razor solo con modo `R` explícito. ~0,1 dp.

**R152-11 (Baja) — Lectura del cuerpo fuera del cupo.** La lectura (hasta 16 MB) y la deserialización ocurren antes de `EsperarAsync` (`EndpointsRender.cs:73` < `:76`) [V]: la memoria de N peticiones simultáneas no la acota el grupo de 4. El único cliente es la principal con tokens válidos, por eso Baja. Remediación: un semáforo pequeño solo para la lectura (p. ej. 8) o tope de conexiones de la canalización; medir en B9. ~0,1 dp.

**R152-12 (Baja) — `PorCanalInterno` no mira el nombre.** Comprueba solo que exista `IConnectionNamedPipeFeature` (`EndpointsReportes.cs:129`) [V]. Hoy hay una sola canalización (`ServiciosReportes.cs:93`) [V]; si mañana se agrega otra con ACL distinta, el render quedaría expuesto por ella. Remediación: comparar el nombre del punto de conexión con `Exportacion.Canalizacion`. ~0,1 dp. Puede ir en T4-02.

**R152-13 (Baja) — DM-04 aplicado al #152.** Chromium hereda el entorno del servicio de reportes [I]. No encontré secretos en ese entorno (la API de reportes valida por introspección y no usa la clave JWT; sus credenciales van selladas en archivo) [I]. Condición: `comprobar-servidor` aplica a `GPOS.Reportes` la misma comprobación K3 que a `GPOS.Api` (ningún nombre con `Clave`, `Password`, `Secret` ni cadena con `Password=` en el entorno del servicio). Si PuppeteerSharp permite fijar el entorno del hijo, pasarle uno mínimo [I: confirmar si `LaunchOptions` reemplaza o solo agrega variables].

**R152-14 (Baja, documental) — Las rutas de render no leen `rptsis`.** ADR-109 cl. 6 dice que en cada petición se leen sesión, permisos y acceso a la empresa; el render solo valida el token (cuerpo del PR, «no consultan `rptsis`: la principal ya autorizó») [V]. Desde la seguridad es aceptable: el render es una función pura del modelo que envía el mismo llamador, no lee la base [V: C, P152-12, y `ServicioRender.cs`], y cruzar `token.empresa` con `modelo.Empresa` no protege nada mientras la principal arme el modelo (Q-T4-01 (a)). Pero debe quedar escrito como precisión de cl. 6 para el render puro y **caduca en T4-11**, cuando el render lea por `imp`: entonces sí aplica la cl. 6 completa y el cruce de empresa (P152b-05 de C).

**Aislamiento entre empresas en el render (pedido explícito).** Sin hallazgo propio más allá de R152-06, R152-08 y R152-14: el render no lee datos [V], la caché de plantillas va por contenido y no guarda datos de empresa [V `MotorRazor.cs:27-33`], el tope de imagen es estático y global por diseño (`ServiciosRender.cs:40`) [V]. El aislamiento depende de la principal (que arma el modelo) y de que nadie salvo la principal llegue al proceso: por eso R152-06 es Media.

**Datos sensibles.** Respuestas de error sin detalles internos [V `ErroresReportes.cs:29`]; los diagnósticos de compilación vuelven al SUPER (`MotorRazor.cs:116-122`), aceptable. Nada registra el token ni el cuerpo [V en los archivos del PR]. El nombre del archivo PDF sale del número del documento (`EndpointsRender.cs:46`), que `Results.File` codifica [I].

**Límites (30 s, cancelación, grupo propio).** 30 s constantes y solo reducibles [V `OpcionesRender.cs:10-25`]; cubren lectura, espera y generación [V `EndpointsRender.cs:68-80`]; cancelación hacia Chromium por `WaitAsync` en cada paso [V `ConvertidorPdf.cs:40-58`]; grupo propio sin ritmo de consultas [V `TurnosRender.cs`]. Huecos: Razor no se cancela (R152-04) y la página creada después de vencer el plazo en `NewPageAsync` no se desecha (observación de C, P152-03 punto 3) [V lectura]. Esto último es una fuga de una pestaña por corte: agregarlo a T4-03.

## 5. Controles bien implementados
- Doble barrera de canalización y prueba del `Program` real (R152-01).
- Política por omisión que protege toda ruta nueva salvo `AllowAnonymous` explícito (`ServiciosSeguridadReportes.cs:16-17`).
- ACL de la canalización con dueño explícito, NETWORK denegado, primera instancia exclusiva contra canalizaciones impostoras (`ServiciosReportes.cs:110-137`).
- Tope de cuerpo doble y lectura después de autenticar (R152-03).
- 30 s no configurables; error 422 sin detalles; `Retry-After` en 429.
- `GeneradorRazor` codifica todo texto del ADMIN y escapa `@`; imágenes del diseño revalidadas al generar (`GeneradorRazor.cs:104-108`, `:152`).
- `Html.Raw`, `@inject`, `@functions`, reflexión y clientes de red prohibidos en plantillas (con los límites de R152-08).
- Sin `--no-sandbox` (ADR-110 cl. 7, A-6) [V `ConvertidorPdf.cs:109`].
- Marca de copia con estilos en línea `!important` que el CSS del formato no oculta (`ServicioRender.cs:83-91`).
- Motores solo en `GPOS.Reportes.Api` y sin referencia a `GPOS.Core` (prueba de arquitectura; C, P152-10).

## 6. Decisiones que B pide a A (alcance 3)

### 6.1 S152-02 (R152-04): ¿basta lo que propone B?

**Dictamen: basta para T4-02 con cuatro ajustes; el proceso hijo es la solución de fondo y conviene decidirlo el 20-nov a favor, para después del corte.**

Lo propuesto por B y mi valoración:

| Medida de B | Valoración | Ajuste de A |
|---|---|---|
| Grupos separados estándar y personalizado | **Sí, imprescindible.** Garantiza que el ticket estándar de QuestPDF (sin código de usuario) siga saliendo con el grupo personalizado lleno | Estándar: 2 cupos propios como mínimo; el personalizado no puede tomar cupos del estándar |
| Cuarentena por huella SHA-256 | **Sí, pero no basta sola.** Una huella cambia con cualquier edición, y en memoria se pierde con el reinicio que el mismo fallo provoca (desbordamiento de pila) → bucle de caídas | (a) Usar la **misma huella** que la precisión de ADR-110 cl. 7 (columna `Huella`, T4-10), así hay una sola definición. (b) **Persistir** la cuarentena en `%ProgramData%\GPOS NG\Reportes\render` (ACL de R152-07) o devolverla a la principal para que marque el formato. (c) **Formato en cuarentena → el render responde con el formato estándar** (o la principal lo pide así) con aviso y evento para el SUPER: la caja sigue imprimiendo. (d) Marcar al empezar y desmarcar al terminar (un render que tira el proceso queda marcado al volver) |
| Contador de huérfanos con `/api/salud` en 503 | **Insuficiente solo.** Un 503 en salud no reinicia nada: nadie actúa sobre él hoy. Los hilos que giran solo se recuperan terminando el proceso | Al llegar a N huérfanos (propongo 2 de 4 personalizados), **reinicio controlado**: dejar de aceptar renders personalizados, terminar los en curso hasta 30 s y salir con código de error para que el Administrador de servicios reinicie. El 503 en `/api/salud` mientras tanto, sí. Evento en el visor (franja de reportes) con la huella, nunca con el contenido |
| `HeapHardLimit` antes de T4-02 | **Ya está** (`GPOS.Reportes.Api.csproj:47`, 768 MiB) [V] | Lo que falta es **medirlo** (B9, R-T4-03) y fijar el valor con evidencia |
| Proceso hijo con *job object*, decisión el 20-nov | **Es la solución de fondo**: el único control que contiene a la vez bucle, pila, memoria y código malicioso (R152-08) | Recomiendo decidir **a favor** el 20-nov, construcción después del corte de la entrega 1, salvo que antes se abra Razor a alguien que no sea el SUPER (entonces pasa a condición previa) |

**Condiciones exactas de A para T4-02 (S152-02):**
1. **C-02-1** Dos grupos: estándar (QuestPDF) y personalizado (Razor/Chromium), con prueba: grupo personalizado lleno → un ticket estándar responde 200.
2. **C-02-2** Cuarentena por la huella común (cl. 7 / T4-10), persistida, marcada al empezar el render; un formato en cuarentena se imprime con el estándar y deja evento. Prueba: plantilla que excede 30 s → la siguiente impresión del mismo formato sale con el estándar sin esperar.
3. **C-02-3** Contador de huérfanos con 503 en `/api/salud` **y** reinicio controlado al tope. Prueba con un generador costura (compuerta), sin bucles de CPU (P152-03 de C).
4. **C-02-4** Recuperación del servicio configurada por el instalador (reiniciar ante fallo, en la primera, segunda y siguientes, con espera corta) y comprobada por `comprobar-servidor`: es lo único que cubre el desbordamiento de pila.
5. **C-02-5** Escrito en el plan o en `estado.json`: Razor solo del SUPER hasta el proceso hijo; el proceso hijo se decide el 20-nov.

Esfuerzo [I, ±40 %]: C-02-1 0,25 dp; C-02-2 0,75 dp (incluye el respaldo al estándar en la principal); C-02-3 0,5 dp; C-02-4 0,25 dp (instalador); pruebas 0,5 dp. **Total ~2,25 dp**, sin costo de infraestructura.

**Alternativas evaluadas:**
- *Endurecer el validador (prohibir bucles y recursión):* descartada, como dice B (indecidible y evadible, R152-08) y rompe plantillas legítimas.
- *Proceso hijo ya, antes de T4-02:* mejor control, pero ~4 a 6 dp [I, ±50 %] (comunicación entre procesos, conjunto de trabajadores con su caché de compilación, *job object* con tope de CPU y memoria, cuenta o *token* restringido) y no cabe antes del corte con R-T4-01. Descartada **para T4-02**, recomendada para después.
- *Aceptar el riesgo sin medidas:* descartada; el impacto (caja sin ticket) es de operación diaria y las medidas cuestan ~2 dp.

### 6.2 S152-03/P152-08 (R152-05): ¿T4-03 o aceptación de riesgo?

**Recomendación: T4-03 como condición de T4-02, con un núcleo no recortable; la aceptación de riesgo solo como respaldo con caducidad.**

Motivos: el control efectivo es barato y la aceptación de riesgo deja sin cumplir dos cláusulas firmadas (ADR-110 cl. 7 y ADR-109 cl. 12) en el momento en que el render pasa a ser el único camino de impresión. El cortafuegos por cuenta del servicio no basta (no filtra *loopback*, R152-05).

**Núcleo no recortable (puede viajar en T4-02 si T4-03 se recorta):**
1. **N-1** Intercepción: solo `data:` y `about:blank`; lo demás se aborta y se registra (sin la URL completa si lleva parámetros; basta esquema y anfitrión).
2. **N-2** `Pipe = true` (R152-06).
3. **N-3** Perfil según DM-11 (R152-07).
4. **N-4** Logo y toda imagen revalidados como `data:` permitido al renderizar (cl. 7; R152-05).
5. **N-5** JavaScript de la página apagado en los formatos que no lo necesitan. **Nota:** el plan dice que T4-03 no apaga JS porque se usa para medir el rollo (plan, «ADR-110 cl. 7»). La medición se hace con `EvaluateExpressionAsync` por el protocolo de depuración, que en Puppeteer sigue funcionando con el JS de la página apagado [I: confirmar con una prueba con navegador]. Si se confirma, apagar el JS de la página en todos los modos no rompe la medición y cierra `<script>` de plantillas Razor; si no, queda para la v2 como dice el plan, y N-1 basta para la red.

Recortable dentro de T4-03 (después del corte, sin bloquear T4-02): *Job Object* de memoria para Chromium y la regla de cortafuegos por cuenta del servicio.

Esfuerzo del núcleo [I, ±40 %]: ~1 a 1,25 dp (de los 2 dp de T4-03). Costo de infraestructura: ninguno.

**Respaldo, si ni el núcleo cabe:** aceptación de riesgo **escrita y firmada por el propietario** (C2), con: alcance (solo plantillas del SUPER y logos validados al guardar), caducidad fija (el 2026-12-04, G-O5-T4, o antes de cualquier cliente beta) y el núcleo N-2 y N-4 hechos de todos modos (0,2 dp). No recomiendo esta vía.

### 6.3 D-25 (A4, Oficio y Media carta con `size: letter`)

**Es un defecto, con efecto en la integridad del documento; no es de confidencialidad.** Evidencia [V]: `PlantillasRazor.Para` emite `@page { size: letter; ... }` para todo papel de hoja (`GPOS.Contracts/Impresion/PlantillasRazor.cs:37`); `ConvertidorPdf` da preferencia al tamaño del CSS en hoja (`PreferCSSPageSize = !papel.Continuo`, `ConvertidorPdf.cs:57`); los papeles miden Carta 215,9 × 279,4 mm, Media carta 215,9 × 139,7, A4 210 × 297 y Oficio 215,9 × 355,6 (`GPOS.Contracts/Impresion/ModeloImpresion.cs:194-197`). Consecuencias [I, según la impresora]: en A4 se pierden ~5,9 mm del borde derecho, donde van las columnas de montos; en Media carta el PDF sale con el doble de alto y la parte de abajo (totales, ITBIS, firmas) pasa a otra hoja o se corta. Un documento fiscal impreso sin sus totales es un problema de integridad.
- **Recomendación:** no capturar dorados de A4/Oficio/Media carta hasta corregirlo; corregirlo en un cambio aparte y pequeño (emitir `size` con las medidas del papel, como ya hace `GeneradorRazor.cs:44`), ~0,25 dp con pruebas. El #152 no lo introduce (copia el comportamiento) y no lo bloquea. La decisión de producto (¿plantillas base distintas por papel?) es de B y del propietario.

### 6.4 D-26 (método de comparación visual)

**Opino a favor de la comparación estructural como puerta (la que recomienda C), con dos agregados de integridad:**
1. Puerta bloqueante, portátil: número de páginas, `/MediaBox` en mm con tolerancia de 0,5 mm, texto extraído por página normalizado (PdfPig, ya pública), número de imágenes. Que el texto obligatorio esté presente: NCF/e-NCF, totales, ITBIS, «COPIA n» y «Reimpreso el» (RO-54) cuando correspondan.
2. **Sin contenido activo:** el PDF de salida no contiene `/JavaScript`, `/Launch`, `/EmbeddedFile` ni `/OpenAction` de script; `/URI` solo si la plantilla trae un enlace. Es una línea más con PdfPig y protege a quien recibe el PDF.
3. Ráster con tolerancia: solo informativo, en una máquina de referencia, no bloqueante (el PDF de Chromium no es determinista entre equipos ni versiones del navegador del sistema).

Alternativa descartada: ráster como puerta (falsos rojos por fuentes y versión de Chrome/Edge del cliente; cuesta mantener una máquina de referencia).

### 6.5 DM-11 y DM-04 aplicados al #152
- **DM-11:** aplica tal cual (R152-07). Condición de T4-02 (núcleo N-3). Para la unión del #152 basta con la condición U-2 de la sección 7.
- **DM-04:** aplica con riesgo menor que en la principal (R152-13): condición en `comprobar-servidor` para `GPOS.Reportes`.

## 7. Remediaciones priorizadas y recomendación

**Condiciones para unir el #152 (las decide el propietario; recomendación técnica):**
- **U-1** Suite del proyecto de reportes en verde sobre la punta (B informa 469 correctas y 0 con error en `cf6ccf98`; no lo verifiqué).
- **U-2** R152-06 y R152-07 mientras no haya T4-03: **o** `Pipe = true` (una línea, ~0,1 dp), **o** `Precalentar: false` por omisión en `appsettings.json` hasta T4-03. Motivo: el precalentamiento lanza Chromium al desplegar aunque nadie llame las rutas, así que el «aditivo» no cubre esta superficie. Si B prefiere no tocar la rama, aceptable como condición **antes del primer despliegue** (DEMO con la API de reportes) en vez de antes de unir.
- **Recomendadas, no exigidas para unir:** R152-10 (~0,1 dp), validación del logo de R152-05 (~0,1 dp), aclaración de la prueba de revocación (R152-02) y la prueba de cuerpo sin enviar (R152-03).

**Condiciones para T4-02:**
1. C-02-1 a C-02-5 (sección 6.1; ~2,25 dp).
2. Núcleo de T4-03, N-1 a N-5 (sección 6.2; ~1 a 1,25 dp), o la aceptación de riesgo firmada como respaldo.
3. R152-09 (contador y tope de plantillas compiladas) y medición B9 de memoria con la caché (~0,25 dp).
4. R152-12 (nombre de la canalización) y R152-13 (`comprobar-servidor` para el entorno de `GPOS.Reportes`) (~0,25 dp).
5. R152-14 escrito como precisión de cl. 6 para el render puro, con caducidad en T4-11.
6. La fuga de pestaña al cortar en `NewPageAsync` (C, P152-03.3) corregida o anotada en T4-03.

**Orden sugerido:** U-2 → núcleo de T4-03 (N-2 y N-4 primero, son de horas) → C-02-1 y C-02-3 → C-02-2 → el resto.

**Recomendación: Aprobado con observaciones** para unir el #152, con U-1 y U-2. Ningún hallazgo Crítico ni Alto abierto; los tres cierres pedidos (S152-01/P152-01, P152-04, P152-05) están bien hechos. Es una recomendación técnica: la orden de unión es del propietario (C2).

## Supuestos
- La revisión de seguridad de B con los S152-xx no está en el área común como archivo; tomo su contenido del aviso del 22-oct y del cuerpo del #152.
- PuppeteerSharp 25.12.0 usa el puerto de depuración si `Pipe` no se activa (comportamiento de Puppeteer; la DLL contiene ambos transportes).
- El cortafuegos de Windows no filtra *loopback* por omisión; un desbordamiento de pila termina el proceso de .NET.
- No se ejecutó ninguna herramienta de análisis de dependencias vulnerables.
- No se leyeron `IntrospeccionCanalizacionTests` ni `GPOS.Api/Impresion/ConvertidorPdf.cs` completos en esta tarea (este último lo cito por mi dictamen del mismo día).

## Decisiones candidatas a ADR
- **Precisión de ADR-109 cl. 6 para el render puro** (R152-14): las rutas `/interno/render/*` validan el token pero no leen `rptsis` mientras la principal arme el modelo (Q-T4-01 (a)); caduca en T4-11. Alternativa descartada: leer `rptsis` en cada render (agrega latencia y una dependencia sin proteger nada mientras el render no lea datos).
- **Proceso hijo para Razor** (R152-04, R152-08), al punto de control del 20-nov: recomendación a favor, después del corte. Alternativas descartadas: validador endurecido; en proceso con medidas (solo como paso intermedio).
- **Respaldo al formato estándar con un formato personalizado en cuarentena** (C-02-2): cambia el comportamiento visible de la impresión; requiere firma.

## Entregas a otros agentes
- **B (desarrollador backend):** U-2; R152-10 y la validación del logo si las toma en T4-01; C-02-1 a C-02-3 y el núcleo de T4-03 en T4-02/T4-03.
- **devops / instalador (B):** C-02-4 (recuperación del servicio), `TMP`/`TEMP` del servicio (DM-11 iv), K3 para `GPOS.Reportes` (R152-13), regla de cortafuegos por cuenta del servicio (segunda capa).
- **arquitecto-maestro (B):** redactar la precisión de cl. 6 y preparar para el 20-nov la decisión del proceso hijo; llevar al propietario C-02-2 (respaldo al estándar) y, solo si hiciera falta, la aceptación de riesgo de 6.2.
- **qa-automatizado (C):** pruebas de C-02-1 a C-02-3 con generador costura; prueba con navegador de N-1 (sin conexión entrante a un `TcpListener` local) y de N-5 (medición del rollo con JS de página apagado); D-26 con los agregados de 6.4.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\revision-seguridad-pr152-t4-01-2026-10-22.md`
- Supuestos: los de la sección «Supuestos»
- Decisiones candidatas a ADR: precisión de ADR-109 cl. 6 para el render puro; proceso hijo para Razor (20-nov); respaldo al formato estándar en cuarentena
- Entregas a otros agentes: B (backend, instalador, arquitecto-maestro) y C (qa-automatizado), según la sección anterior
- Próximo paso recomendado: B aplica U-2 (`Pipe = true` o precalentamiento apagado) y lleva al propietario la orden de unión del #152 con las condiciones de T4-02 de la sección 7
