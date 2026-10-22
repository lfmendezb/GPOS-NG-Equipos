# Informe de seguridad: PR #152 (T4-01, render aditivo en GPOS.Reportes.Api)

Fecha: 2026-10-22 · Auditor: auditor-seguridad (solo lectura) · Rama `b/ola5-t4-01-render` @ `851a1417`, base `origin/feature/modelo-ng` (merge-base `e3e729c1`) · Worktree `C:\Users\lfmen\source\repos\Solucion GPOS NG\GPOS-B-t4-01`

No se compiló, no se ejecutaron pruebas y no se modificó nada. «Verificado» = lectura de código o de git; «Inferido» = razonamiento sin ejecutar. Sin pasos de explotación ni cargas útiles (C10).

## 1. Alcance y superficie revisada

- Archivos nuevos/cambiados de `src/GPOS.Reportes.Api` (22, +1.672 líneas): `Endpoints/EndpointsRender.cs`, `Impresion/*` (`ServicioRender`, `ServiciosRender`, `MotorRazor`, `ValidadorPlantillas`, `ConvertidorPdf`, `TurnosRender`, `OpcionesRender`, `ContratoRender`, `ErroresRender`), `Program.cs`, `appsettings*.json`, `.csproj`.
- Contexto leído (sin cambios en el PR): `Seguridad/AutenticacionIntrospeccion.cs`, `Seguridad/ServiciosSeguridadReportes.cs`, `Seguridad/VerificadorIntrospeccion.cs`, `Endpoints/ServiciosReportes.cs` (canalización y ACL), `Endpoints/EndpointsReportes.cs`, `ErroresReportes.cs`, `GPOS.Contracts/Impresion/GeneradorRazor.cs`, `GPOS.Comun/Configuracion/ArchivoInstalacion.cs`; ADR-110 (cl. 7, precisión del 2026-10-20) y el informe de C (P152-01..20).
- Superficie: 4 rutas `POST /interno/render/{documento,cierre,conduce,resultado}`, alcanzables solo por la canalización con nombre (ACL: cuenta del servicio + cuenta de la principal; Deny NETWORK). El listener HTTP es solo loopback (`ServiciosReportes.cs:143-151`). En T4-01 nadie llama las rutas (aditivo); el riesgo real se activa con T4-02.
- Hecho clave para calibrar severidades (verificado): el cuerpo de `/documento` puede traer una **plantilla Razor completa** (`ContratoRender.cs:25-26`, `ServicioRender.cs:39-41`) que el render compila y ejecuta en el proceso de la API de reportes (`MotorRazor.cs:70-98`). Ese proceso guarda las credenciales de lectura selladas de todas las empresas (`GPOS.Reportes/Lectura/FuenteConexionSobres.cs:91`). La única barrera entre «quien llega a la ruta» y «código C# en ese proceso» es el validador de lista negra.

## 2. Resumen de hallazgos

| ID | Sev. | Título | Estado |
|---|---|---|---|
| S152-01 | **Alta** | El bloqueo de `/interno/*` por HTTP depende de una sola línea de `Program.cs`, sin prueba ni segunda barrera en el punto final (= P152-01, con impacto de seguridad precisado) | Verificado |
| S152-02 | Media | Plantilla Razor sin fin: retiene el cupo para siempre y deja sin impresión también los formatos estándar (= P152-02) | Verificado (código) / Inferido (efecto) |
| S152-03 | Media (condición de T4-02) | H-T4-09: Chromium con JavaScript, sin interceptar peticiones ni bloquear red: salida de red desde el servidor (SSRF) (= P152-08) | Verificado |
| S152-04 | Media | Validador de plantillas: lista negra textual, eludible por clases léxicas de C#; Razor compila contra todas las referencias de la API (SqlClient, `GPOS.Reportes`) | Verificado (patrón) / Sospecha (elusión, no probada) |
| S152-05 | Baja (Media al unir T4-02) | Crecimiento sin tope de plantillas compiladas (ensamblados no descargables) | Verificado (código) / Inferido (efecto) |
| S152-06 | Baja | El cuerpo (hasta 16 MB) se lee y deserializa fuera del grupo de concurrencia | Verificado |
| S152-07 | Baja | Un solo navegador y un solo perfil para todos los renders y empresas; perfil en `%TEMP%` sin borrar; posible pestaña huérfana al cancelar | Verificado / Inferido (ACL de `%TEMP%`) |
| S152-08 | Baja | El render confía en `Empresa.Logo` del cuerpo y no exige `data:` | Verificado |
| S152-09 | Baja | Filtro por prefijo de texto antes del enrutador: variantes de ruta sin probar (= P152-09) | Inferido |
| S152-10 | Baja | Ruta del ejecutable del navegador configurable sin validar | Verificado (mitigado por ACL de configuración) |

Ningún Crítico. Un Alto (S152-01), barato de cerrar.

## 3. Checklist OWASP Top 10 (2021)

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | **Hallazgo** S152-01 (barrera única), S152-09. Bien: política por omisión con usuario autenticado (`ServiciosSeguridadReportes.cs:16-17`); el grupo no tiene `AllowAnonymous` (`EndpointsRender.cs:43`); ACL de la canalización (`ServiciosReportes.cs:117-124`). La autorización por permiso (quién puede imprimir qué) queda en la principal por diseño (Q-T4-01). |
| A02 Criptografía | No aplica (el PR no cifra ni firma; el token lo valida la principal por introspección). |
| A03 Inyección | **Hallazgo** S152-04 (plantilla → compilador C#). Bien: `MarcarCopia` codifica (`ServicioRender.cs:82`); `GeneradorRazor` codifica texto y escapa `@` (`GeneradorRazor.cs:152`) y filtra CSS por lista blanca (`:157-161`). JSON con `System.Text.Json` sin polimorfismo. |
| A04 Diseño inseguro | **Hallazgos** S152-02 (sin forma de cortar Razor), S152-03 (red de Chromium pendiente de T4-03). |
| A05 Configuración | S152-10; S152-07. Bien: `--no-sandbox` ausente (`ConvertidorPdf.cs:109`); `AddServerHeader = false` (`Program.cs:29`); el archivo de instalación solo admite `GPOS:RncDgii` (`ArchivoInstalacion.cs:27`). |
| A06 Componentes vulnerables | No verificado: no se ejecutó `dotnet list package --vulnerable` (instrucción de no compilar). Versiones: RuntimeCompilation 10.0.12, PuppeteerSharp 25.12.0, QuestPDF 2026.9.0 (`GPOS.Reportes.Api.csproj:20-22`), iguales a `GPOS.Api`. |
| A07 Autenticación | Bien: token por petición con caché de 15 s por SHA-256 (`VerificadorIntrospeccion.cs:30,40,106`), falla cerrada, rechazo de modo limitado, cambio de clave y SUPER sin segundo factor (`AutenticacionIntrospeccion.cs:52-75`). La autenticación ocurre **antes** de leer el cuerpo (ver sección 5). |
| A08 Integridad | Precisión de ADR-110 del 2026-10-20 (marca `GuardadoPorSuper` + `Huella` del modo Razor): no está en el render; hoy acepta Razor del cuerpo sin marca. Es de T4-10 («decidido, no implementado»); anotado en S152-04. |
| A09 Registro y monitoreo | Bien: no se registra el token ni el modelo; `EventoImagenOmitida` sin contenido (`ServicioRender.cs:44-45`); 500 genérico (`ErroresReportes.cs:29`). Falta: evento cuando un render agota el plazo con el trabajo vivo (S152-02) y la empresa/usuario del token en el registro del render (auditoría). |
| A10 SSRF | **Hallazgo** S152-03 y S152-08. El código .NET del render no abre red (verificado por C y por lectura); la salida posible es Chromium. |

## 4. Hallazgos

### S152-01 (Alta) — `/interno/*` por HTTP: una sola línea, sin prueba ni segunda barrera
**Riesgo.** Si `app.UsarRutasInternasSoloPorCanal()` falta o cambia de lugar, las rutas de render quedan expuestas en el listener HTTP de loopback. Cualquier proceso local del servidor (en instalaciones pequeñas el servidor suele ser también una caja) con un token válido **de cualquier nivel**, incluso USER, podría enviar un formato Razor propio. El render no comprueba el nivel, porque confía en la principal (`ContratoRender.cs:18-21`). Lo que queda entonces es el validador de lista negra (S152-04) delante de la ejecución de código como `NT SERVICE\GPOS.Reportes`, que guarda las credenciales de lectura de todas las empresas. La principal sí limita Razor al SUPER; aquí esa regla desaparece.
**Evidencia.** `Program.cs:99` (única barrera); `EndpointsRender.cs:31-39` (middleware por prefijo); `EndpointsRender.cs:44-54` (los cuatro puntos finales no repiten la comprobación). En el mismo proyecto, la exportación **sí** la repite en el punto final: `EndpointsReportes.cs:67` (`if (!PorCanalInterno(http)) return Results.NotFound();`). Ninguna prueba ejecuta el `Program.cs` real contra `/interno/render/*` (verificado por C, P152-01; coincide con mi lectura de `Program.cs`).
**Hoy está bien cableado** (verificado: `Program.cs:99` antes de `:100` `UseAuthentication`, `MapRender` en `:104`). El hallazgo es la fragilidad, no un fallo presente.
**Remediación (0,25 a 0,5 dp, inferido):**
1. Defensa en profundidad dentro de `RenderAsync` (primera línea): si la petición no llega por la canalización, responder 404, igual que `EndpointsReportes.cs:67`. Si alguien quita el middleware, la ruta sigue cerrada (aunque responda después de autenticar).
2. Prueba sobre el `Program` real (P152-01, opción 1, en `ReportesF9Tests`) o, como mínimo, prueba de texto del orden en `Program.cs` (opción 2).
3. Opcional: `.RequireAuthorization()` explícito en el grupo (`EndpointsRender.cs:43`), para no depender solo de `FallbackPolicy`.

### S152-02 (Media) — Plantilla Razor sin fin: cupo retenido para siempre
**Riesgo.** El trabajo corre en `Task.Run(..., CancellationToken.None)` y el cupo se libera solo cuando termina (`EndpointsRender.cs:75-76`). Razor es síncrono y no observa `ct` (`MotorRazor.cs:98`). En .NET 10 no existe `Thread.Abort`: un hilo en bucle no se puede matar sin reiniciar el proceso. Con `MaximoSimultaneos = 4` (`OpcionesRender.cs:31`; `appsettings.json`), cuatro renders así dejan en 429 `RENDER_OCUPADO` **todas** las impresiones del servicio, incluso los tickets estándar de QuestPDF, que no tienen nada de Razor, porque comparten el grupo (`TurnosRender.cs:10`). Además quedan 4 núcleos al 100 %. Una variante, un bucle que acumula memoria, puede tumbar el proceso por falta de memoria. Condición previa: un formato Razor guardado por el SUPER, aunque sea por error. Por eso es Media y no Alta.
**Por qué no sirve endurecer el validador.** Detectar bucles sin fin es indecidible. Prohibir `for` o `while` no basta (hay otras construcciones) y rompería plantillas legítimas: el propio generador gráfico emite `@foreach` (`GeneradorRazor.cs:62`). Descartado.
**Remediación concreta (orden de costo):**
1. **Grupos separados** (0,25 dp): un grupo para los estándar (QuestPDF: documento sin formato, cierre, conduce, resultado) y otro para los personalizados (Razor + Chromium). Así una plantilla mala nunca deja la caja sin ticket estándar. `TurnosRender` admite un parámetro de grupo sin cambiar el contrato.
2. **Cuarentena por huella** (0,25 dp): `ProveedorPlantillas.Registrar` ya calcula el SHA-256 del contenido (`MotorRazor.cs:29`). Si una petición vence el plazo con el trabajo vivo, esa huella se pone en cuarentena en memoria y las siguientes peticiones con la misma huella responden 422 al instante, sin compilar ni ejecutar, hasta el reinicio. Así los reintentos de la principal o del usuario no consumen cupos nuevos. Se registra un evento con la huella y el formato, sin el contenido.
3. **Contador de huérfanos y salud** (0,25 dp): al vencer el plazo, el cupo pasa a la cuenta de «huérfanos» (que lo retienen hasta terminar). Si los huérfanos llegan al tamaño del grupo personalizado, `/api/salud` responde 503 con un motivo y se registra un evento para el operador. Si conviene reiniciar solo con `Environment.FailFast` y la recuperación del SCM lo decide A o el propietario: corta las peticiones en curso.
4. **Tope de memoria del proceso**: con `System.GC.HeapHardLimit` en el runtimeconfig (configuración del runtime, no tecnología nueva; valor a medir en R-T4-03, que hoy asume 768 MB), el proceso falla de forma limpia en lugar de llevar al servidor a paginar.
5. **De fondo** (3 a 5 dp, inferido; T4-10 o la v2): ejecutar Razor en un proceso hijo desechable con un *job object* (límite de CPU y de memoria, muerte a los 30 s), o retirar Razor (ADR-110 cl. 3). Es la única corrección completa.
Recomiendo 1 y 2 antes de T4-02 (no bloquean T4-01, que no se llama todavía) y 3 en la misma tanda.

### S152-03 (Media, condición de T4-02) — H-T4-09: Chromium con red
**Riesgo.** El HTML que llega a Chromium puede hacer peticiones de red desde el servidor: imágenes, hojas de estilo, scripts y, con JavaScript activo, peticiones desde el script. Llegan a la red interna del cliente y a Internet (SSRF y canal de exfiltración del contenido del documento). Esto contradice ADR-110 cl. 7 («sin JavaScript en los modos gráfico y Liquid y solo acepta recursos `data:`»). Los vectores son el formato Razor del SUPER (el validador no mira HTML: `ValidadorPlantillas.cs:33-37`) y `Empresa.Logo` (S152-08). En T4-01 nadie llama la ruta; con T4-02 el riesgo se activa.
**Evidencia.** `ConvertidorPdf.cs:40-43` (página nueva y `SetContentAsync` sin `SetRequestInterceptionAsync` ni `SetJavaScriptEnabledAsync(false)`); `ConvertidorPdf.cs:106-110` (argumentos de arranque sin restricción de red). Bien: no hay `--no-sandbox`.
**Remediación (T4-03; 0,5 a 1 dp, inferido), en tres capas:**
1. Interceptar todas las peticiones de la página y abortar las que no sean `data:` (o `about:blank`). Desactivar JavaScript en el modo visual. En Razor también, salvo que se demuestre que alguna de las plantillas base lo necesita. **Por verificar:** que la medición del alto del rollo (`ConvertidorPdf.cs:50`, por CDP) siga funcionando con JavaScript desactivado.
2. Argumentos de arranque que anulen la red aunque falle la capa 1: un proxy inexistente para todo y reglas del resolvedor que no resuelvan ningún nombre.
3. Capa del sistema: regla de salida de Windows Firewall que bloquee el ejecutable del navegador **solo para la cuenta del servicio** (filtro por usuario local con el SID de `NT SERVICE\GPOS.Reportes`), para no afectar al Chrome del usuario. Va en el instalador.
**Condición:** que T4-02 no se una sin T4-03, o sin una aceptación de riesgo escrita del propietario (coincide con C, P152-08). La prueba con `TcpListener` local que propone C sirve como prueba de aceptación.

### S152-04 (Media) — Validador de lista negra y Razor con todas las referencias de la API
**Riesgo.** `ValidadorPlantillas` es una expresión regular sobre el texto (`ValidadorPlantillas.cs:33-37`). El propio comentario dice «defensa adicional, no un aislamiento completo» (`:6-8`), y la mantiene ADR-38. Lo nuevo es **dónde** corre: en el proceso que tiene las credenciales de lectura de todas las empresas y `rptsis`. Antes corría en la principal, que tiene más, así que hay mejora neta del radio de daño (ver sección 5). Pero el render compila con las referencias de toda la aplicación: `ServiciosRender.cs:28-34` añade el ensamblado de la API como parte de la aplicación «porque sus referencias son las que compila Razor», y la API referencia `GPOS.Reportes` → `Microsoft.Data.SqlClient`, Dapper y `FuenteConexionSobres` (`GPOS.Reportes.Api.csproj:35`, `GPOS.Reportes.csproj:13-27`).
**Sospecha (no probada; verificado solo el patrón).** El patrón compara tokens contiguos y separados solo por espacios en blanco. No contempla clases léxicas de C# que producen el mismo símbolo con otro texto (comentarios entre tokens, secuencias de escape en identificadores) ni la escritura de miembros estáticos públicos de ensamblados referenciados. Ejemplo de lo último, verificado: `ImagenDiseno.TopeBytes` es estático con setter público (`GPOS.Contracts/Impresion/ImagenDiseno.cs:28`), y una plantilla podría cambiarlo para todo el proceso. No doy la forma concreta (C10). Cualquier elusión exige llegar a la ruta con un formato Razor: hoy, solo el SUPER a través de la principal (o cualquier usuario si cae S152-01).
**Precisión pendiente.** ADR-110, precisión del 2026-10-20: el render debe rechazar el modo Razor sin la marca `GuardadoPorSuper`/`Huella`. Hoy `FormatoImpresionDto` llega del cuerpo y se compila sin esa comprobación (`ServicioRender.cs:28-31`). Está bien para T4-01 (T4-10 trae las columnas), pero debe quedar en la lista de T4-10 que la comprobación vive **también** en el render, no solo en la principal.
**Remediación:**
1. Reducir las referencias de compilación de Razor (≈1 dp, inferido): un proveedor de referencias propio (o un `AssemblyPart` limitado) que exponga solo el runtime base, `GPOS.Contracts` y lo mínimo de Razor, sin `GPOS.Reportes`, SqlClient, Dapper ni `GPOS.Comun`. No cierra la reflexión, pero quita el acceso directo a las credenciales y a SQL.
2. Validación en el render de la marca y la huella del SUPER (T4-10).
3. De fondo, el mismo proceso hijo de S152-02 punto 5, o la retirada de Razor.

### S152-05 (Baja; Media cuando T4-02 lleve la vista previa al render) — Plantillas compiladas sin tope
**Evidencia.** `ProveedorPlantillas._archivos` solo crece (`MotorRazor.cs:25-32`). Cada contenido distinto produce un ensamblado de Roslyn que no se descarga. ADR-110 cl. 1 prevé una vista previa con la definición en la petición: si la vista previa del modo gráfico del ADMIN pasa por este render, cada cambio del diseño compila un ensamblado nuevo (inferido). Es un problema que ya existe en la principal y que el PR traslada.
**Remediación.** Tope de huellas distintas (p. ej., 1.000; valor a medir), con un evento y un 503 al pasarlo. La vista previa queda fuera de la compilación cuando llegue la v2 (componentes precompilados).

### S152-06 (Baja) — Cuerpo de 16 MB fuera del grupo de concurrencia
**Evidencia.** `LeerCuerpoAsync` (`EndpointsRender.cs:70`) corre antes de `EsperarAsync` (`:73`) y acumula hasta 16 MB en un `MemoryStream` más el objeto deserializado. N peticiones simultáneas son N × (16 MB + modelo). Solo la principal llega a la ruta, así que la probabilidad es baja. **Bien:** `Content-Length` se rechaza antes de leer (`:89`), y el acumulado también (`:95`).
**Remediación.** Tomar el cupo antes de leer el cuerpo (también cuenta dentro de los 30 s) o fijar un máximo de conexiones simultáneas para la canalización.

### S152-07 (Baja) — Navegador y perfil compartidos
**Evidencia.** Hay un solo `IBrowser` para todo el proceso (`ConvertidorPdf.cs:21,89`) y un perfil por arranque en `Path.GetTempPath()` (`:101-102`) que nunca se borra. Todas las páginas de todas las empresas comparten el contexto del navegador (caché HTTP y cookies de orígenes externos). Con S152-03 abierto, eso sirve de canal entre renders. `NewPageAsync().WaitAsync(ct)` (`:40`) puede dejar una pestaña creada y no desechada si el plazo vence en ese punto (observación de C). **Inferido:** la ACL de `%TEMP%` de la cuenta virtual no está verificada. Mitiga que la instalación es de un solo dueño (ADR-43).
**Remediación (T4-03).** Un contexto de navegador incógnito por render, desechado al terminar. El perfil en la carpeta temporal protegida de ADR-77, borrado al cerrar. Desechar la página también cuando la creación termine después de la cancelación.

### S152-08 (Baja) — `Empresa.Logo` sin validar en el render
**Evidencia.** `GeneradorRazor.cs:101` emite `src="@Model.Empresa.Logo"` con el valor del cuerpo. La principal sí valida el logo como imagen PNG, JPG, GIF o WEBP en data URI (`GPOS.Core/Servicios/AdministracionService.cs:81`) y lo arma desde bytes (`:54`), pero el render no lo vuelve a comprobar. Con S152-03 abierto, un logo `http(s)` sería una salida de red.
**Remediación.** En `ServicioRender.HtmlAsync`, si `Logo` no es un data URI de imagen permitida, anularlo y registrar el evento RQ-R12 (≈1 hora).

### S152-09 (Baja) — Filtro por prefijo antes del enrutador
**Evidencia.** `EndpointsRender.cs:33` compara el texto de `Path` antes del enrutamiento. Variantes con barras dobles, barra final o codificación no tienen prueba. **Inferido:** las codificaciones se decodifican antes (salvo `%2F`) y el enrutador no debería casar las variantes, pero no se verificó.
**Remediación.** La comprobación en el punto final de S152-01 cierra el caso aunque el prefijo no case. Prueba de variantes de C (P152-09).

### S152-10 (Baja) — Ejecutable del navegador configurable
**Evidencia.** `GPOS:Reportes:Render:Navegador` (`OpcionesRender.cs:40`) se ejecuta como la cuenta del servicio (`ConvertidorPdf.cs:83-84,106-108`). El archivo de instalación no puede fijarlo (`ArchivoInstalacion.cs:27`, solo `GPOS:RncDgii`): solo se cambia desde `appsettings.json` en Program Files o desde variables del servicio, que requieren administrador. Riesgo bajo.
**Remediación.** Aceptar solo rutas bajo las carpetas de programas, o exigir la firma Authenticode del editor (Google/Microsoft), y registrar la ruta usada (ya se registra: `:105`).

## 5. Controles bien implementados (verificado)

- **Autenticación antes del cuerpo:** el middleware solo mira la ruta y la característica de la canalización (`EndpointsRender.cs:31-39`). `UseAuthentication`/`UseAuthorization` van antes de los puntos finales (`Program.cs:100-104`). Los puntos finales no enlazan `[FromBody]`: leen el cuerpo a mano dentro del manejador (`EndpointsRender.cs:44-54,70`). Una petición sin token válido nunca se lee.
- **Token en cada petición** con caché de 15 s por SHA-256, falla cerrada y comprobación del dueño de la canalización de introspección (`VerificadorIntrospeccion.cs:30,40-46,106-112`).
- **Canalización:** ACL de dos entradas permitidas más Deny NETWORK, sin `CreateNewInstance` para la principal y primera instancia exclusiva (`ServiciosReportes.cs:117-136`). Listener HTTP solo loopback, en todos los entornos (`:143-151`).
- **Tope de 16 MB** por `Content-Length` y por acumulado (`EndpointsRender.cs:89,95`); 413 de 10.000 filas (`ServicioRender.cs:69-71`).
- **30 s no configurables** (`OpcionesRender.cs:10-25`); cancelación ligada a `RequestAborted` (`EndpointsRender.cs:65-67`); `Retry-After` en el 429 (`ErroresReportes.cs:34-35`; `TurnosRender.cs:18`); `Dispose` idempotente del cupo (`TurnosRender.cs:26-29`).
- **Sin credenciales en el contrato** (`ContratoRender.cs:25-37`) y sin acceso a datos en `Impresion/` (también lo verificó C). El render no lee bases: el aislamiento entre empresas no depende de él. No compara la empresa del token con la del modelo, por diseño (Q-T4-01); recomiendo registrar usuario y empresa del token en cada render, para auditoría.
- **Errores:** 500 genérico sin detalle interno (`ErroresReportes.cs:29`); no se registra el token.
- **Radio de daño:** trasladar Razor a la API de reportes saca la compilación de código del proceso que tiene la clave del JWT y las credenciales de escritura (ADR-110 cl. 7). Es una mejora neta respecto de la principal.
- **Sandbox de Chromium activo** (sin `--no-sandbox`, `ConvertidorPdf.cs:109`), como pide ADR-110 cl. 7. Falta la prueba de laboratorio con la cuenta del servicio (R-T4-07).

## 6. Remediaciones priorizadas

| # | Acción | Hallazgo | Cuándo | Esfuerzo (inferido) |
|---|---|---|---|---|
| 1 | Comprobación `PorCanalInterno` en `RenderAsync` + prueba del `Program` real (o de texto) | S152-01 | **Antes de unir #152** | 0,25-0,5 dp |
| 2 | Grupos separados estándar/personalizado + cuarentena por huella + contador de huérfanos con salud 503 | S152-02 | Antes de T4-02 (puede ir en #152) | 0,5-0,75 dp |
| 3 | Interceptar peticiones (solo `data:`), JavaScript desactivado, argumentos sin red y regla de firewall por cuenta del servicio | S152-03, S152-08 | T4-03, **condición de unión de T4-02** | 0,5-1 dp |
| 4 | Validar `Empresa.Logo` en el render | S152-08 | Con #152 o T4-03 | ~1 h |
| 5 | Limitar las referencias de compilación de Razor; marca y huella del SUPER también en el render | S152-04 | T4-10 | ~1 dp |
| 6 | Contexto incógnito por render, perfil en la carpeta de ADR-77 y borrado | S152-07 | T4-03 | 0,25 dp |
| 7 | Tope de plantillas compiladas | S152-05 | Antes de llevar la vista previa al render (T4-02) | 0,25 dp |
| 8 | Cupo antes de leer el cuerpo; validar la ruta del navegador | S152-06, S152-10 | Seguimiento | 0,25 dp |
| 9 | Fondo: Razor en proceso hijo con *job object*, o retirada de Razor | S152-02, S152-04 | Decisión del propietario (candidata a ADR) | 3-5 dp |

## 7. Recomendación

**Corregir antes de unir** (estado C3: Rechazado, recomendación técnica, no aprobación). El único bloqueante es S152-01 (Alta), y su arreglo cuesta de 0,25 a 0,5 dp. Con S152-01 cerrado, el PR quedaría en «Aprobado con observaciones»: S152-02 y S152-03 serían condiciones de T4-02, no de T4-01, porque en T4-01 nadie llama las rutas. La decisión final es del propietario.

### Cierre
- Estado: Rechazado (recomendación técnica: corregir S152-01 antes de unir)
- Artefactos: este informe (scratchpad); no se modificó el repositorio
- Supuestos: no se ejecutó nada; ACL de `%TEMP%` de la cuenta virtual no verificada; la normalización de rutas de Kestrel y del enrutador, inferida; las elusiones del validador son sospecha por lectura del patrón
- Decisiones candidatas a ADR: ejecutar Razor en un proceso hijo desechable con *job object* (alternativa: retirar Razor antes; descartada: endurecer el validador contra bucles); grupos de concurrencia separados estándar/personalizado (precisión de ADR-109 cl. 13)
- Entregas a otros agentes: desarrollador de B → S152-01 y S152-02 (1-2); qa-automatizado/C → pruebas de P152-01, P152-09 y la de red de T4-03; devops → regla de firewall por cuenta del servicio y `HeapHardLimit` en el instalador; arquitecto-maestro → condicionar T4-02 a T4-03 y decidir el proceso hijo de Razor
- Próximo paso recomendado: que B agregue la comprobación de canalización en `RenderAsync` con su prueba y vuelva a pedir la revisión
