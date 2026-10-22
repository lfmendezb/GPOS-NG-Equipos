# Segunda relectura de seguridad · PR-2 de ADR-90 (correcciones R-01 a R-05 y S2-04)

- **Fecha:** 2026-10-22 · **Auditor:** auditor-seguridad (equipo A) · **Recomendación técnica; la decisión de unir es del propietario, vía B.**
- **Objeto:** `0102cbca` (R-01, R-02) y `23176529` (R-03, R-04, R-05, S2-04) sobre `da8c3668`, en `a/adr90-rt05-tls-escucha` (repositorio `GPOS-NG-pr2`).
- **Informes de origen:** `relectura-seguridad-pr2-pr4-adr90-2026-10-21.md` (R-01 a R-05) y `revision-seguridad-pr2-adr90-2026-10-21.md` (S2-04), en esta misma carpeta.
- **Método:** solo lectura (`git show`, `git diff`, `git grep`). No compilé, no ejecuté nada y no cambié de rama. [V] = verificado en el código; [I] = inferido del comportamiento del marco (.NET 10 / ASP.NET Core 10), no medido.
- Las líneas citadas son las de la punta de la rama (`23176529`).

## 1. Alcance y superficie revisada

| Pieza | Archivo |
|---|---|
| Excepción encadenada | `src/GPOS.Comun/Red/EventosRed.cs:53-57`; `src/GPOS.Comun.Servidor/Red/EscuchaServidor.cs:256-275` |
| `catch` de arranque | `src/GPOS.Api/Program.cs:350-351`; `src/GPOS.Web/Program.cs:110-111` |
| Pruebas contra la validación propia | `tests/GPOS.Tests/Arquitectura/RedPlataformaArquitecturaTests.cs:111-262` |
| Reenvío sin `X-Forwarded-Proto` con el modo | `EscuchaServidor.cs:191-210`; `src/GPOS.Web/Program.cs:57-63`, `:116-127` |
| `ExigirUrlApi` | `src/GPOS.Comun.Servidor/Red/ClienteApiLocal.cs:52-63`; `src/GPOS.Web/Program.cs:70-71` |
| Regla S8 | `tests/GPOS.Tests/Arquitectura/OrdenProgramaApiTests.cs:204-233`; `ProgramaApiTexto.cs:293-328` |
| S2-04 | `EscuchaServidor.cs:183-189`; `tests/GPOS.Tests/Red/EscuchaWebModoTests.cs:262-268`; plano en `blueprint-adr90-rt01-rt05-rt06-2026-10-20.md:26`, `:269` |

**Superficie:** no cambia. Hay dos cambios de comportamiento:
- con el modo, la Web deja de aceptar `X-Forwarded-Proto`;
- sin modo, un `Api:Url` mal formado ya no deja arrancar la Web.

Lo demás son pruebas y comentarios.

## 2. Tabla resumen

### 2.1 Estado de las observaciones anteriores

| ID | Severidad original | Estado | Regresión |
|---|---|---|---|
| R-01 | Baja | **Cerrado**. Queda un residuo en la prueba de la API (R2-01) | No |
| R-02 | Baja | **Cerrado en lo pedido**. La desviación en la API basta. Quedan dos huecos de patrón (R2-02) | No |
| R-03 | Baja | **Cerrado** | No: mejora HSTS y la redirección |
| R-04 | Baja | **Cerrado**. El motivo no lleva el valor | No |
| R-05 | Baja | **Cerrado en lo pedido**. Solo quedan evasiones deliberadas (R2-03) | No |
| S2-04 | Baja | **Cerrado con la opción (b)**, aceptable con el modo. Queda un pendiente documental (R2-04) | No |

### 2.2 Observaciones nuevas

| ID | Severidad | Título |
|---|---|---|
| R2-01 | Baja | La regla S6 de la API no fija qué se escribe en `Console.Error`. Un `WriteLine(ex)` pasaría y volcaría la excepción interna, con rutas |
| R2-02 | Baja | Hay dos vías que el patrón de R-02 todavía no ve: `SslStream` creado con `new(…)` o con el nombre completo, y `ServicePointManager.ServerCertificateValidationCallback`. Además, la lista de proyectos es fija |
| R2-03 | Baja (informativa) | S8 se puede evadir con construcciones deliberadas (hueco de interpolación vaciado, escape Unicode en el identificador, `Unsafe.AsRef(in …)`) |
| R2-04 | Baja (informativa) | S2-04 (b) está en el plano de A, pero no en `ADR-090.md`. Sin modo, el riesgo de *DNS rebinding* sobre HTTP de *loopback* sigue como antes |

No hay hallazgos Críticos, Altos ni Medios.

## 3. Checklist OWASP Top 10 (2021), para este lote

| Categoría | Resultado | Ref. |
|---|---|---|
| A01 Control de acceso | Bien. Con el modo, la API se protege con TLS validado por nombre en lugar del filtro de anfitrión (S2-04 b) | R2-04 |
| A02 Criptografía | Bien. La vigilancia de la validación propia cubre más vías y más proyectos | R2-02 |
| A03 Inyección | No aplica | — |
| A04 Diseño inseguro | Bien. Las dos salidas siguen fallando cerradas con código 1. `Api:Url` se valida al arrancar | — |
| A05 Configuración | Bien. Con el modo, la Web ignora `X-Forwarded-Proto`, sin regresiones | — |
| A06 Componentes vulnerables | No aplica (no hay paquetes nuevos) | — |
| A07 Autenticación | Bien. Con el modo, `Request.IsHttps` ya no depende de un encabezado, así que las cookies, HSTS y la antifalsificación quedan coherentes | — |
| A08 Integridad | Bien. S8 y los patrones de R-02 endurecen las pruebas de arquitectura | R2-02, R2-03 |
| A09 Registro y monitoreo | Bien. La causa queda encadenada y el motivo saneado llega a `Console.Error`. El registro no cambia | R2-01 |
| A10 SSRF | No aplica. El `ConnectCallback` no cambia. El esquema de `Api:Url` sin modo queda limitado a http/https | — |

## 4. Verificación por punto pedido

### (1) R-01 · Cerrado

- **[V] Encadenamiento.** El constructor nuevo `ArranqueRedException(EventId, string, Exception interna)` llama a `base(mensaje, interna)` (`EventosRed.cs:57`). Solo se usa en la salida imprevista (`EscuchaServidor.cs:274`). El mensaje sigue siendo `Imprevista(…)`, que lleva solo `e.GetType().Name` (`:297-298`). Las otras dos salidas (`ArranqueRed.cs:214` y `EscuchaServidor.cs:288`) no encadenan nada.
- **[V] La interna no llega al registro.** El crítico registra `d.Motivo` como parámetro de la plantilla, sin el argumento `exception` (`EscuchaServidor.cs:268`). No hay otro `Log*` con `e`.
- **[V] La interna no llega a `Console.Error`.** Los dos `catch` escriben `ex.Message` (`src/GPOS.Api/Program.cs:351`, `src/GPOS.Web/Program.cs:111`), no `ex` ni `ex.ToString()`. `Exception.Message` no incluye el mensaje de la interna [I: comportamiento de la BCL].
- **[V] El mensaje no lleva datos sensibles.** Todos los motivos que pueden llegar ahí nombran la clave, el valor o la regla, nunca el contenido:
  - `InterpretacionRed.cs:13` lo declara así y los motivos lo cumplen (`:125-126`);
  - las fuentes de escucha y de reenvío se citan sin su valor (`ArranqueRed.cs:150-185`);
  - la lectura del registro da solo el tipo de la excepción (`FuenteConfiguracionRed.Windows.cs:65`) y motivos fijos de la DACL (`:121-135`);
  - el certificado: «falta …», «no está en el almacén», «no se pudo cargar (Tipo)» (`SelectorCertificadoServidor.cs:91-214`);
  - `Api:Url`: solo el nombre de la clave (`ClienteApiLocal.cs:58`, `:62`).

  La ruta fija de la clave del registro sí aparece, pero no es secreta y ya figuraba en el visor de eventos.
- **Falla cerrada y S6 [V].** El `catch` sigue siendo único, sin condición, y termina en `Environment.ExitCode = 1; … return;`. La regla S6 lo admite (`OrdenProgramaApiTests.cs:184-200`, muestra nueva en `:536-537`). La Web fija el texto exacto del `catch` (`tests/GPOS.Web.Tests/Red/ProgramaWebRedTests.cs:45`).
- **¿`Console.Error.WriteLine` puede impedir la salida?** En un servicio de Windows, la salida de error no tiene identificador y .NET escribe en un flujo nulo. Una tubería rota se ignora al escribir [I]. Si aun así lanzara, la excepción saldría sin manejar antes de `app.Run`: el servicio no arranca (falla cerrada) y solo se pierde el código 1.
- Queda un residuo: R2-01.

### (2) R-02 · Cerrado en lo pedido; la desviación de la API basta

- **[V] Patrones.**
  - `ValidacionPropia` suma `\bnew\s+SslStream\b|VerificationFlags` (`RedPlataformaArquitecturaTests.cs:117-119`).
  - `ManejadorPrimario` suma `UseSocketsHttpHandler`, `PrimaryHandler`, `HttpMessageHandlerBuilderActions` e `IHttpMessageHandlerBuilderFilter` (`:126-128`).
  - Hay una autoprueba por vía (`:220-223`, `:252-262`).
- **[V] Proyectos.**
  - Se recorren `GPOS.Web`, `GPOS.Comun.Servidor`, `GPOS.Api`, `GPOS.Core`, `GPOS.Comun` y `GPOS.Reportes.Api` (`:142-143`).
  - `GPOS.AgenteImpresion` entra con una excepción nombrada, acotada al cuerpo de `CrearManejador(IReadOnlyList<string> fijadas)` (`:146`, `:201-211`).
  - No se recorren `GPOS.Contracts`, `GPOS.Criptografia`, `GPOS.ImpresionDirecta`, `GPOS.Migracion` ni `GPOS.Reportes`. Hoy ninguno usa `HttpClient`, `SslStream`, `X509Chain` ni `SocketsHttpHandler` (`git grep` sin resultados).
- **Desviación en la API: basta.**
  - Lo que importa en la API es que nadie relaje la **confianza**, y eso lo cubre `ValidacionPropia`, que sí recorre `GPOS.Api` entero. Un manejador propio de un cliente con nombre no puede traer una devolución de llamada, una política de cadena ni `VerificationFlags` sin que la prueba falle.
  - La restricción del manejador primario protegía el `ConnectCallback` a *loopback* de `ClienteApiLocal`. La API no usa ese cliente, así que solo hace falta prohibir las vías que alcanzan a **todos** los clientes (`:135-136`).
  - `ReenvioReportes.cs:253` es legítimo [V]. Su manejador (`:263-280`) conecta por una canalización con nombre a un servidor HTTP de *loopback* (no hay TLS que validar) y comprueba el dueño de la canalización.
  - Hay dos vías globales que no están en el patrón: sustituir en el contenedor `HttpMessageHandlerBuilder` o `IHttpMessageHandlerFactory`. Son rebuscadas y, por la misma razón, no pueden relajar la validación sin que `ValidacionPropia` lo vea. No las pido.
- **Lo que falta:** R2-02 (minutos, no bloquea).

### (3) R-03 · Cerrado, sin regresiones

- **[V] Cambio.** `AplicarWeb` registra `PostConfigure<ForwardedHeadersOptions>(o => o.ForwardedHeaders &= ~XForwardedProto)` solo con el modo (`EscuchaServidor.cs:209`). Los `PostConfigure` corren después de todos los `Configure`, en cualquier orden de registro [I]. Por eso el `Configure` de `Program.cs:58-63`, que va después de `Preparar`, no lo deshace. Lo comprueba `EscuchaWebModoTests.cs:251`, con el `Configure` en el mismo orden que el programa.
- **[V] No hay otra vía que lo reponga.**
  - No hay otro `Configure` ni `PostConfigure` de `ForwardedHeadersOptions` en `src/GPOS.Web` ni en `GPOS.Comun.Servidor`.
  - `UseForwardedHeaders()` va sin opciones explícitas (`Program.cs:116`), así que lee `IOptions`. La prueba de la Web fija ese texto.
  - El reenvío del marco por variable de entorno ya da 4744 con el modo (S3-01).
- **Regresiones revisadas.** Con el modo, toda la escucha es HTTPS (S4-01), así que el esquema real es siempre `https`:
  - **Esquema y URL absolutas:** `Request.Scheme` es el de la conexión (`https`). `X-Forwarded-Host` nunca estuvo habilitado (`Program.cs:60`), así que el `Host` sigue saliendo del encabezado, que filtra `AllowedHosts`. **Sin regresión.**
  - **Cookies `Secure`:** las políticas `Always` no dependían del esquema. `InicioSesionWeb.cs:87` (`Secure = ctx.Request.IsHttps`) ahora siempre es verdadero con el modo. **Mejora.**
  - **HSTS:** `UseHsts` solo emite el encabezado si `IsHttps` [I]. Antes, un `X-Forwarded-Proto: http` lo suprimía; ahora sale siempre con el modo. Las exclusiones de `localhost` del marco no cambian [I]. **Mejora.**
  - **Redirección HTTPS:** `UseHttpsRedirection` (`Program.cs:127`) no actúa si `IsHttps`. Antes, ese mismo encabezado provocaba un 307 hacia sí misma (bucle). **Mejora.**
  - **Antifalsificación:** desaparece el 500 por `SecurePolicy = Always` con `IsHttps` falso. **Resuelto.**
  - **`X-Forwarded-For`:** sigue con `ForwardLimit = 1` y los mismos `KnownProxies`. El rechazo de nodos va antes y usa la IP de la conexión (`Program.cs:114-115`). **Sin cambio.**
  - **Sin modo y DEMO:** no se registra nada y el reenvío queda `For | Proto` (prueba `:251`, caso `false`). **Sin cambio.**
- El encabezado `X-Forwarded-Proto` no consumido sigue en la petición. Ningún código de `src/GPOS.Web` lo lee [V: `git grep` sin resultados fuera de comentarios].

### (4) R-04 · Cerrado

- **[V]** Sin modo, `ExigirUrlApi` niega con 4743 (`EventosRed.ConfiguracionInvalida`, sin EventId nuevo) en dos casos: si el valor está en blanco (`ClienteApiLocal.cs:56-58`) o si no es una dirección absoluta `http`/`https` (`:59-62`).
- **[V] El motivo no filtra el valor.** Las dos cadenas son constantes con solo el nombre de la clave (`«{ClaveUrlApi}»`). La prueba `EscuchaWebModoTests.cs` (casos `:96-103`) comprueba `DoesNotContain(configurada, Motivo)`. Una contraseña puesta por error en la parte de usuario de la URL tampoco aparecería.
- **[V] Casos.** Se rechazan una ruta relativa, un anfitrión sin esquema, `ftp:`, `file:` (también una ruta de disco o UNC, que `Uri` interpreta como `file`) y `ws:`. El esquema se compara con `Uri.UriSchemeHttp`/`Https`, que `Uri` normaliza a minúsculas (`HTTPS://…` se admite) [I].
- **[V]** Con el modo, o con la decisión ya denegada, no cambia nada (`:55`). El `?? throw` (`Program.cs:71`) queda como guarda, y la prueba de texto lo fija (`ProgramaWebRedTests.cs`, línea agregada en `23176529`).
- **Residuo conocido, sin cambio:** sin modo se sigue admitiendo `http://` hacia otro equipo. Es el comportamiento heredado. Con Estricto no hay «sin modo».

### (5) R-05 · Cerrado en lo pedido; solo es evadible a propósito

- **[V] Regla S8** (`OrdenProgramaApiTests.cs:204-233`). Comprueba que:
  - hay una sola llamada a `Preparar` y otra a `ExigirArranque`;
  - el resultado de `Preparar` se guarda en una variable nueva (`var|EstadoRed v =`);
  - el segundo argumento posicional de `ExigirArranque` es exactamente `v` (un argumento con nombre, `v!`, `v.ConDecision(…)` o un tercer argumento fallan);
  - no hay reasignación entre las dos llamadas (`=`, operadores compuestos, `??=`, `++`/`--`, `ref`/`out`, deconstrucción), ni en una función local o una lambda en cualquier parte del archivo.

  Hay casos sintéticos positivos y negativos (`:714-760`) y una copia del `Program.cs` real.
- **[V] Por qué el riesgo de fondo es menor de lo que parece.**
  - `EstadoRed` es inmutable y su constructor y `ConDecision` son `internal`. `InternalsVisibleTo` solo incluye los proyectos de pruebas (`GPOS.Comun.Servidor.csproj:23-24`).
  - Desde la API solo se puede obtener otro estado con un segundo `Preparar` (que S5/S8 cuentan en `Program.cs`) o con `ExigirUrlApi`, que solo puede negar.
- **¿Evadible?** Solo con construcciones deliberadas que la regla de texto no ve (R2-03). Ninguna aparece por accidente, y la revisión de código las detectaría. No pido cambios.

### (6) S2-04, opción (b) · Aceptable

- **[V]** La nota está en `AplicarWeb` (`EscuchaServidor.cs:188-189`), junto a la prueba que fija `AllowedHosts = *` en la API (`EscuchaWebModoTests.cs:262-268`) y en el plano de A (`blueprint-adr90-rt01-rt05-rt06-2026-10-20.md:26`, `:269`), con la alternativa (a) descartada y su costo (0,05 dp).
- **¿Basta cerrar H-15 solo en la Web? Sí, con el modo.**
  - El *DNS rebinding* necesita que el navegador de la víctima hable con la API bajo un nombre del atacante. Con el modo, la API solo escucha HTTPS (S4-01) con un certificado elegido por huella, y el navegador valida el nombre. La conexión falla en el saludo, antes de que el `Host` importe [I: validación de nombre del navegador].
  - La API no usa cookies. Los puntos anónimos (inicio de sesión, factor, recuperación, emparejamiento, estado: `AuthEndpoints.cs:33`, `:44`, `:112`; `RecuperacionFactorEndpoints.cs:62`, `:85`, `:134`; `RestauranteDispositivosEndpoints.cs:34`, `:54`; `Program.cs:414`) tienen límite de peticiones y no confían en el origen *loopback* [V: no hay `IsLoopback` como criterio de confianza en `src/GPOS.Api`, salvo la validación de destino de `ReenvioReportes.cs:245`].
- **Condiciones de la aceptación (R2-04):**
  - el certificado de la API no puede ser comodín sobre un dominio que controle un tercero (lo cubre el selector por huella; S2-08 sigue abierto para el SAN);
  - sin modo (DEMO), la API y la Web escuchan HTTP en *loopback* con `AllowedHosts` de su configuración, y ahí el *DNS rebinding* desde un navegador del mismo equipo sí alcanza los puntos anónimos. Es exactamente lo que había antes, aplica también a la Web sin modo y queda fuera de Estricto. Solo lo registro como riesgo residual conocido.
- **Pendiente documental:** `ADR-090.md` (H-15, `:251` según el plano) no recoge la precisión. El plano dice que H-15 se cierra solo en la Web; conviene que el ADR lo diga también.

## 5. Observaciones nuevas

### R2-01 · Baja · S6 de la API no fija el contenido de `Console.Error`

- **Evidencia [V].** La regla S6 (`OrdenProgramaApiTests.cs:184-200`) solo exige la salida con 1, sin condición y con un solo `catch`. No mira qué se escribe. La Web sí fija el texto exacto (`ProgramaWebRedTests.cs:45`).
- **Riesgo.** Es de exposición menor y futura. Un cambio a `Console.Error.WriteLine(ex)` en `src/GPOS.Api/Program.cs:351` pasaría la regla. Ese cambio escribiría `ex.ToString()`, que incluye el mensaje y la traza de la excepción interna (la que R-01 encadena), con rutas y mensajes del proveedor. Si el servicio redirige la salida de error a un archivo (instaladores o scripts), terminarían ahí.
- **Remediación (minutos).** En S6, si el `catch` escribe en `Console.Error`/`Console.Out`, el único argumento admitido es `<variable>.Message`. Alternativa: fijar el texto exacto, como en la Web.
  - *Descartada:* prohibir `InnerException` y `ToString` por separado. Es más frágil que exigir `.Message`.

### R2-02 · Baja · Huecos que quedan en el patrón de R-02

- **Evidencia [V].** `ValidacionPropia` (`RedPlataformaArquitecturaTests.cs:117-119`).
- **Riesgo.** Hoy no aparece ninguna de estas vías en `src/` [V]. Mañana la prueba no vería:
  - `SslStream s = new(flujo, false, (…) => true)` (creación por tipo de destino) ni `new System.Net.Security.SslStream(…)` (nombre completo): `\bnew\s+SslStream\b` exige la palabra justo después de `new`;
  - `ServicePointManager.ServerCertificateValidationCallback = …`, que el patrón no nombra (solo `ServerCertificateCustomValidationCallback`). En .NET 10 no afecta a `HttpClient`, pero sí a `HttpWebRequest`/`WebClient`, que están obsoletos pero siguen disponibles [I];
  - un proyecto nuevo bajo `src/`: la lista es fija (`:142-143`).
- **Remediación (minutos).**
  - Cambiar `\bnew\s+SslStream\b` por `\bSslStream\b`. No coincide con `SslStreamCertificateContext`, que sí se usa en `SelectorCertificadoServidor.cs`.
  - Cambiar `ServerCertificateCustomValidationCallback` por `ServerCertificate\w*ValidationCallback`.
  - Recorrer todos los proyectos de `src/` salvo las excepciones nombradas, en lugar de una lista cerrada.

### R2-03 · Baja (informativa) · Evasiones deliberadas de S8

- **Evidencia [V/I].**
  - La limpieza vacía los huecos de interpolación (`ProgramaApiTexto.cs:250`), así que una reasignación dentro de `$"{…}"` no se ve [V].
  - C# admite escapes Unicode en los identificadores, y el patrón busca el nombre literal (`:321-328`) [I].
  - `Unsafe.AsRef(in v) = …` usa `in`, que el patrón no incluye [V].
- **Riesgo.** Hacen falta cambios intencionales y llamativos. Los frena la revisión de código. La regla es una guarda contra regresiones.
- **Remediación.** Ninguna obligatoria. Si se quiere cerrar del todo, la vía es un analizador de Roslyn sobre `Program.cs` (alrededor de 1 día-persona), que no compensa hoy.

### R2-04 · Baja (informativa) · S2-04 (b): registro en el ADR y residuo sin modo

- **Evidencia [V].** El plano de A recoge la decisión (`:269`). El commit no toca `docs/` (`git diff da8c3668 23176529 -- docs` vacío).
- **Riesgo.** Es documental: el ADR y el plano dicen cosas distintas. Sin modo, el *DNS rebinding* sobre HTTP de *loopback* sigue igual que antes, en la API y en la Web.
- **Remediación.** El documentador registra la precisión en `ADR-090.md` (H-15) cuando B pase el plano a firma, junto con el riesgo residual sin modo, que es solo DEMO y desarrollo.

## 6. Controles bien implementados

- La causa del fallo imprevisto queda encadenada sin llegar al registro ni a la salida de error. Solo sale el motivo saneado (R-01).
- La vigilancia de la validación propia cubre seis proyectos y el agente de impresión, con una excepción acotada al cuerpo de su fábrica. En la API se separa bien lo que es de un cliente de lo que es global (R-02).
- Con el modo, `Request.IsHttps` ya no depende de ningún encabezado: las cookies, HSTS, la redirección y la antifalsificación quedan coherentes (R-03).
- `Api:Url` se valida al arrancar con un motivo sin el valor (R-04).
- S8 sigue el valor de `Preparar` hasta `ExigirArranque`, con casos negativos variados (R-05).

## 7. Remediaciones priorizadas

| # | ID | Acción | Responsable | Cuándo | Esfuerzo |
|---|---|---|---|---|---|
| 1 | R2-01 | S6 de la API: solo `.Message` en `Console.Error` (o el texto exacto) | Desarrollador de A | PR siguiente | Minutos |
| 2 | R2-02 | `\bSslStream\b`, `ServerCertificate\w*ValidationCallback`, recorrer todo `src/` | Desarrollador de A | PR siguiente | Minutos |
| 3 | R2-04 | Precisión de H-15 en `ADR-090.md` | Arquitecto de A → documentador | Con la firma del plano | Minutos |
| — | R2-03 | Ninguna (solo con un analizador Roslyn si algún día se justifica) | — | — | — |
| — | S2-07, S2-08, S4-02, S4-05, S4-06 | Siguen como en los informes de origen | A / devops / arquitecto | Según esos informes | — |

## 8. Recomendación

**Aprobado con observaciones** para unir PR-2 junto con PR-4 o antes que él (recomendación técnica; la unión la ordena el propietario por medio de B).

- R-01 a R-05 y S2-04 quedan cerrados sin regresiones de seguridad. R-03 mejora HSTS y la redirección con el modo.
- No hay hallazgos Críticos, Altos ni Medios. R2-01 a R2-04 son Bajos y no bloquean. Conviene llevar R2-01 y R2-02 al PR siguiente.
- Siguen en pie las condiciones de los informes de origen: firma de F-5, N-1 unido y la suite oficial (`Transicion!=Ola5&Transicion!=Defecto`) en verde sobre `23176529`. Este revisor no la ejecutó.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\relectura2-seguridad-pr2-adr90-2026-10-22.md`
- Supuestos (todos [I]; no se compiló ni se ejecutó nada):
  - `Exception.Message` no incluye la interna;
  - `Console.Error` no lanza en un servicio ni con una tubería rota;
  - `PostConfigure` corre después de todo `Configure`;
  - `UseHsts` y `UseHttpsRedirection` dependen de `IsHttps`;
  - `Uri` normaliza el esquema a minúsculas;
  - el navegador valida el nombre del certificado (base de S2-04 b);
  - `ServicePointManager.ServerCertificateValidationCallback` sigue afectando a `HttpWebRequest` en .NET 10;
  - C# admite escapes Unicode en los identificadores.
- Decisiones candidatas a ADR: Ninguna nueva. Solo la precisión de H-15 de S2-04 (b) en `ADR-090.md`, que ya decidió el arquitecto de A y queda pendiente de la firma del propietario.
- Entregas a otros agentes:
  - desarrollador de A → R2-01 y R2-02 (minutos, PR siguiente);
  - arquitecto de A y documentador → R2-04 (registrar la precisión de H-15 y el residuo sin modo en `ADR-090.md`);
  - QA o C → suite oficial sobre `23176529` antes de unir.
- Próximo paso recomendado: avisar a B de que PR-2 sigue en «Aprobado con observaciones» tras R-01 a R-05 y S2-04, para unirlo cuando la suite en curso termine en verde, y llevar R2-01 y R2-02 al PR siguiente.
