# Relectura de seguridad · PR-2 y PR-4 de ADR-90 (correcciones S2-xx y S4-xx)

- **Fecha:** 2026-10-21 · **Auditor:** auditor-seguridad (equipo A) · **Recomendación técnica; la decisión de unir es del propietario, vía B.**
- **Objeto:** los 8 commits sobre `81edccad` en `a/adr90-rt05-tls-escucha` (repositorio `GPOS-NG-pr2`): `a4ded785` (S2-01), `42d10865` (S2-03), `fa28b930` (S2-02), `bab1b631` (S2-05), `a6185a6a` (S2-06), `3bd361f3` (S4-03), `4c0ff3ed` (S4-04) y `ae432314` (S4-01).
- **Informes de origen:** `revision-seguridad-pr2-adr90-2026-10-21.md` y `revision-seguridad-pr4-adr90-2026-10-21.md` (misma carpeta).
- **Método:** solo lectura (`git show`, `git diff`, `git grep` sobre la rama). No compilé ni ejecuté nada (hay una suite corriendo en ese árbol) y no cambié de rama. [V] = verificado en el código; [I] = inferido del comportamiento del marco (.NET 10 / ASP.NET Core 10), no medido.
- Las líneas citadas son las de la punta de la rama (`ae432314`).

## 1. Alcance y superficie revisada

| Pieza | Archivo |
|---|---|
| Refresco del certificado | `src/GPOS.Comun.Servidor/Red/SelectorCertificadoServidor.cs:130-244` |
| `AplicarWeb` (H-15: `AllowedHosts`, `AllowEmptyHosts`, cookies) | `src/GPOS.Comun.Servidor/Red/EscuchaServidor.cs:188-203` |
| `ExigirArranque` y `Exigir` | `EscuchaServidor.cs:238-290` |
| `ExigirUrlApi` / `UrlApi` | `src/GPOS.Comun.Servidor/Red/ClienteApiLocal.cs:51-73`; `EstadoRed.cs` (`ConDecision`) |
| Canalización y arranque de la Web | `src/GPOS.Web/Program.cs:57-74`, `:104-129`; `Servicios/InicioSesionWeb.cs:83-90` |
| Pruebas nuevas | `SelectorCertificadoServidorTests.cs:153`, `EscuchaTlsKestrelTests.cs:141`, `:262`, `EscuchaWebModoTests.cs:69`, `:170`, `:183`, `:193-196`, `EscuchaServidorTests.cs:217`, `:231`, `CookiePasoFactorTests.cs:47`, `:57`, `ProgramaWebRedTests.cs:71`, `RedPlataformaArquitecturaTests.cs:115-200`, `OrdenProgramaApiTests.cs:145-200`, `:595`, `ProgramaApiTexto.cs:40-111` |

**Superficie:** no cambia respecto de las revisiones anteriores. Los commits endurecen la Web con el modo (filtro de anfitrión, cookies), el arranque de las dos aplicaciones (`ExigirArranque`) y las pruebas de arquitectura. Sin modo, el único cambio de comportamiento es S2-06 (la Web sin `Api:Url` sale con 4743 en lugar de una excepción sin manejar).

## 2. Tabla resumen

### 2.1 Estado de los hallazgos anteriores

| ID | Severidad original | Estado | Regresión |
|---|---|---|---|
| S2-01 | Baja | **Cerrado** | No |
| S2-02 | Baja | **Cerrado** | No (ver R-03, que ya existía antes) |
| S2-03 | Baja | **Cerrado** | No |
| S2-05 | Baja | **Cerrado en lo pedido**; quedan vías menores (R-02) | No |
| S2-06 | Baja | **Cerrado** (ver R-04) | No |
| S4-01 | Media | **Cerrado** (lo cierra PR-2; la prueba lo fija) | No |
| S4-03 | Baja | **Cerrado**; se pierde diagnóstico (R-01) | No |
| S4-04 | Baja | **Cerrado en lo pedido**; quedan evasiones rebuscadas (R-05) | No |
| S2-04, S2-07, S2-08, S4-02, S4-05, S4-06 | Baja | Siguen abiertos; no estaban en este lote ni bloquean | — |

### 2.2 Observaciones nuevas de la relectura

| ID | Severidad | Título |
|---|---|---|
| R-01 | Baja | S4-03 descarta la excepción original y, si el registro falla, también el motivo específico (4744/4747). No queda ningún rastro del fallo |
| R-02 | Baja | S2-05: la prueba no ve `new SslStream(…, callback)`, `VerificationFlags`, `UseSocketsHttpHandler` ni `PrimaryHandler`, y no recorre `GPOS.Core`, `GPOS.Comun` ni `GPOS.Reportes.Api` |
| R-03 | Baja (informativa, ya existía) | Con el modo, un `X-Forwarded-Proto: http` de un proxy conocido hace fallar la antifalsificación (500) |
| R-04 | Baja (informativa) | Sin modo, `Api:Url` no se valida: un valor mal formado falla tarde, al crear el cliente; el `?? throw` es inalcanzable |
| R-05 | Baja (informativa) | S4-04: las pruebas de texto no comprueban que el `red` de `ExigirArranque` sea el de `Preparar` |

No hay hallazgos Críticos, Altos ni Medios.

## 3. Checklist OWASP Top 10 (2021), para este lote

| Categoría | Resultado | Ref. |
|---|---|---|
| A01 Control de acceso | Bien. El filtro de anfitrión es una lista cerrada con el modo (S2-03) | — |
| A02 Criptografía | Bien. Se vuelve a juzgar la vigencia (S2-01) y se amplía la vigilancia de la validación propia | R-02 |
| A03 Inyección | No aplica | — |
| A04 Diseño inseguro | Bien. Todas las salidas de `ExigirArranque` fallan cerradas con código 1 (S4-03); la API con modo ya no arranca en HTTP (S4-01) | R-01 |
| A05 Configuración | Bien. H-09 tiene una salida ordenada (S2-06). Observaciones de disponibilidad | R-03, R-04 |
| A06 Componentes vulnerables | No aplica (no hay paquetes nuevos) | — |
| A07 Autenticación | Bien. `Secure` en todas las cookies con el modo (S2-02) | R-03 |
| A08 Integridad | Bien. Pruebas de arquitectura más estrictas (S4-04, S2-05) | R-02, R-05 |
| A09 Registro y monitoreo | Bien, con salvedad: el 4743 imprevisto no deja rastro de la causa | R-01 |
| A10 SSRF | No aplica (el `ConnectCallback` no cambia) | — |

## 4. Verificación por hallazgo

### S2-01 · Cerrado

- **[V]** Con la misma huella, `Refrescar` llama a `MotivoNoUtilizable(vigente.Certificado, …)` y, si hay motivo, solo registra (`SelectorCertificadoServidor.cs:149-155`, `NoUsable` en `:185-188`). No toca `_vigente`, `_anterior` ni las opciones.
- **¿Puede dejar de servir un certificado válido?** No. La rama nueva no tiene ningún camino que cambie o libere el certificado: solo escribe en el registro. La llave se abre con `using` y se libera la copia (`:228-232`), no el contexto que sirve Kestrel [I: `GetECDsaPrivateKey`/`GetRSAPrivateKey` devuelven un objeto propio]. Una excepción imprevista cae en el `catch` general (`:179-182`), que tampoco cambia el certificado.
- **¿Bucle de eventos?** No. Hay un solo refresco por tick del `PeriodicTimer` de 5 min (`:115-121`), sin reintento ni rearmado, y el 4748 no dispara ninguna acción. El costo es el volumen: con un certificado vencido salen unos 288 críticos por día y por servicio, que es lo que pedí («uno por refresco»). Un fallo pasajero al abrir la llave (`CryptographicException`, `:235-237`) produciría un 4748 falso, sin efecto en el servicio. La alerta de RT-03 debería agruparlos por huella (no es un hallazgo).
- La prueba `SelectorCertificadoServidorTests.cs:153` usa el reloj manual y cubre: sigue sirviendo, 4748 crítico con motivo «vencido», uno por refresco y sin 4749.

### S2-02 · Cerrado

- **[V]** `AplicarWeb` fija `CookiePolicyOptions.Secure = Always` solo con el modo (`EscuchaServidor.cs:202`). `UseCookiePolicy()` está en `src/GPOS.Web/Program.cs:117`.
- **Posición en la canalización** (`Program.cs:113-129`): rechazo de nodos → `UseForwardedHeaders` → `UseCookiePolicy` → manejador de excepciones/HSTS → `UseAuthentication` → `UseAntiforgery` → páginas. Es correcta:
  - con `Secure = Always`, la política no depende de `Request.IsHttps`, así que da igual que vaya detrás del reenvío;
  - va antes de todo lo que emite cookies: autenticación, antifalsificación, `FijarPaso` en las páginas de `/cuenta`, y también la reejecución de `UseExceptionHandler`/`UseStatusCodePages`, que queda por dentro;
  - lo que está por delante (filtro de anfitrión, rechazo de nodos, reenvío) no emite cookies;
  - en `src/GPOS.Web` y `GPOS.Comun.Servidor` nadie escribe `Set-Cookie` a mano (`git grep`: el único `Cookies.Append` es `InicioSesionWeb.cs:83`).

  La prueba `ProgramaWebRedTests.cs:71` fija el orden.
- **Cookies de antifalsificación:** ya tenían su propio `SecurePolicy = Always` (`:199`). La política no cambia nada en ellas. Ver R-03 sobre el reenvío.
- **DEMO y sin modo:** `AplicarWeb` no se llama. `CookiePolicyOptions` queda con los valores por omisión: `Secure = None`, `HttpOnly = None`, `MinimumSameSitePolicy = Unspecified` y sin consentimiento [I: valores del marco]. Así, `UseCookiePolicy` no cambia ningún atributo, y lo comprueban `EscuchaWebModoTests.cs:196` y `CookiePasoFactorTests.cs:57`. No hay otro `Configure<CookiePolicyOptions>` en `src/` [V]. El DEMO no cambia.

### S2-03 · Cerrado

- **[V]** `AllowEmptyHosts = false` en el mismo `PostConfigure` que `AllowedHosts` (`EscuchaServidor.cs:192-197`), solo con el modo. Sin modo sigue en `true` (`EscuchaWebModoTests.cs:193`).
- **Comportamiento:** HTTP/1.0 sin `Host` → 400 y con `Host: localhost` → 200, sobre Kestrel real con TLS (`EscuchaTlsKestrelTests.cs:262`). El caso de un `Host` ajeno → 400 ya estaba cubierto (`EscuchaTlsKestrelTests.cs`, prueba de PR-2).
- El filtro de anfitrión del marco va al principio de la canalización, antes del rechazo de nodos [I].
- La Web no recibe llamadas internas sin `Host`: su cliente llama a la API, no a sí misma. No veo pérdida de disponibilidad.
- La validación propia con `(_,_,_,_) => true` en `PedirCrudo` está en `tests/`, fuera del alcance de la prueba de arquitectura. Es correcto.

### S2-05 · Cerrado en lo pedido (residuo en R-02)

- **[V]** El patrón incluye `CertificateChainPolicy|CustomTrustStore|X509ChainTrustMode` (`RedPlataformaArquitecturaTests.cs:115-117`). Recorre `GPOS.Web`, `GPOS.Comun.Servidor` y ahora `GPOS.Api`, y exige que cada aparición esté **dentro del cuerpo** de la sobrecarga interna para pruebas (`ClienteApiLocal.cs:92-109`), no solo en su archivo.
- Hay una autoprueba por cada vía (`:178`). Una prueba nueva fija que `ConfigurePrimaryHttpMessageHandler` y `ConfigureHttpClientDefaults` aparecen una sola vez en la Web y en `GPOS.Comun.Servidor`, dentro de `UsarClienteApiLocal` (`:187`), y que en la API no hay `ConfigureHttpClientDefaults`.
- Hoy, en `src/`, solo aparecen `ClienteApiLocal.cs:96`, `:102` (la sobrecarga para pruebas) y `GPOS.AgenteImpresion/Estacion/ClienteDispositivo.cs:80`, que es fijación de certificado legítima y está fuera del alcance de la prueba [V].
- **¿Se puede evadir todavía?** Sí, por vías menos obvias (R-02). La prueba vigila regresiones accidentales y no sustituye la revisión de código.

### S2-06 · Cerrado

- **[V]** `ExigirUrlApi` convierte «sin modo y `Api:Url` nulo, vacío o en blanco» en `Denegado` 4743, sin EventId nuevo (`ClienteApiLocal.cs:51-57`). La Web la llama antes de `UrlApi` (`Program.cs:68`). Después, `ExigirArranque` registra el crítico y lanza `ArranqueRedException`, que el `catch` existente convierte en código 1 (`:108-109`). Lo cubren `EscuchaWebModoTests.cs:69` y el orden en `ProgramaWebRedTests.cs`.
- Con el modo, o con la decisión ya denegada, el estado no cambia (`Assert.Same`). El cambio a `Denegado` no deja nada armado: sin modo, la Web no arma escucha (`PuertoSinModo` es null para la Web, `EscuchaServidor.cs:84`).
- **El `?? throw` que queda (`Program.cs:69`):** ahora es **inalcanzable**. `UrlApi` solo devuelve null con `SinModo` y `configurada` nula (`ClienteApiLocal.cs:64-73`), y ese caso ya lo negó `ExigirUrlApi`. Con `Denegado` devuelve la dirección fija. Lo dejaría como guarda defensiva: si alguien quita `ExigirUrlApi`, falla cerrado igual que antes. La prueba de orden impide quitarla.
- **DEMO:** pasa `Api__Url` por el entorno (`instalador/Demo/scripts/herramientas/Comun-Demo.ps1:375`), así que no cambia. Las fábricas de `GPOS.Web.Tests` fijan `Api:Url` (`InicioSesionFactorWebTests.cs:50`, `LoginAntifalsificacionTests.cs:42`, `:334`, `RecuperacionFactorTests.cs:60`).
- Queda la validación del formato (R-04).

### S4-01 · Cerrado

- **[V]** Con el modo, `Preparar` sustituye `Kestrel:*` por una configuración vacía y sin recarga, y arma solo HTTPS en el puerto del modo (`EscuchaServidor.cs:118-131`, `:149-164`). Kestrel ya no queda en su dirección por omisión, y el 4746 no tiene nada que detener después del anillo.
- La prueba `EscuchaTlsKestrelTests.cs:141` comprueba, sobre Kestrel real:
  - ninguna dirección `http://` ni `:5000`;
  - todas las direcciones en el puerto del modo;
  - sin 4743, 4744, 4746 ni 4747;
  - la aplicación sin detenerse.
- La prueba arranca un anfitrión mínimo con `Preparar(ServicioRed.Api)`, no el `Program.cs` de la API. Basta, porque S3 y S5 (texto) obligan a que `Program.cs` llame a `Preparar` y a `ExigirArranque` sin condición y antes de los datos.
- Las otras salidas con el modo también fallan antes del anillo y de SQL: modo con otra fuente de direcciones → 4743/4744 en `Preparar`/`ExigirArranque`; sin certificado → 4747 en `ExigirArranque`.

### S4-03 · Cerrado (con R-01)

- **[V]** `ExigirArranque` atrapa toda excepción que no sea `ArranqueRedException` y lanza una `ArranqueRedException` 4743 «excepción imprevista al exigir el arranque (Tipo)» (`EscuchaServidor.cs:238-268`). Intenta el crítico con el registro de la clase o con `app.Logger`, sin que un segundo fallo impida lanzar (`:258-265`). `ArranqueRedException` se relanza tal cual (`:248-251`), así que 4743, 4744 y 4747 conservan su evento.
- **¿Se puede saltar la detención?** No. Todas las ramas del `catch` terminan en `throw`, y en `Program.cs` el único `catch` sale con código 1 antes del anillo (S6 lo fija).
  - Un registro de `ApplicationStarted`/`ApplicationStopped` que haya quedado a medias no se ejecuta, porque la aplicación no llega a arrancar.
  - El certificado cargado se libera al terminar el proceso.
- **`OutOfMemoryException`:** `catch (Exception)` la atrapa. Si no hay memoria para armar el 4743, la nueva OOM sale sin manejar y el proceso termina sin arrancar. La falla sigue cerrada; solo se pierde el código 1 [I].
- **`ThreadAbortException`:** no existe en .NET 10 (`Thread.Abort` no está soportado) [I].
- **`StackOverflowException` y estado corrupto:** no se pueden atrapar; el proceso muere. Falla cerrada.
- **¿Oculta un error útil?** Sí, en parte (R-01).
  - El motivo lleva solo el tipo, sin mensaje ni traza. Es intencional para no filtrar rutas, y la prueba `:217` lo fija.
  - La excepción original no se encadena: `ArranqueRedException` no tiene constructor con `inner` (`src/GPOS.Comun/Red/EventosRed.cs:51-57`).
  - Si el registro falla dentro de `ArranqueRed.Exigir` o del 4747 (`:276-281`), justo antes de lanzar el motivo previsto, ese motivo específico (4744 o «sin certificado») se convierte en «4743 imprevista (AggregateException)».
  - `Program.cs` no imprime el mensaje (`src/GPOS.Web/Program.cs:109`; lo mismo en `src/GPOS.Api/Program.cs:350-351`). Con el registro roto, no queda ningún rastro.

### S4-04 · Cerrado en lo pedido (residuo en R-05)

- **[V]** Lo que comprueban ahora las reglas:
  - **S3:** el `try` de `ExigirArranque` (o la llamada) va con profundidad de llaves 0, fuera de `#if` y sin nada delante en su sentencia (`OrdenProgramaApiTests.cs:145-148`; `ProgramaApiTexto.cs:83-105`).
  - **S5:** igual para `Preparar`, que solo puede ir como `var|EstadoRed x =` (`:175`).
  - **S6:** un solo `catch`, sin `finally`, y una salida sin condición (`:194-200`). El `return` tiene que ser lo último del `catch`, y no puede haber `if`, `?:`, `&&`, `||`, bucles ni `goto`.
  - **S7:** también fuera de `Program.cs`. En `src/GPOS.Api` nadie usa `KestrelServerOptions` salvo `LimitesPeticiones.cs`, ni `ConfigureKestrel`, `UseKestrel*`, `UseUrls`, `UseSetting`, `Listen…`, `.Urls` o `IServerAddressesFeature` (`:595`).
- Hay casos sintéticos para cada evasión que señalé: `catch (Exception)`, `catch { }`, `finally`, `when`, `if` sin llaves, bloque, `#if`, lambda y `&&`.
- **¿Siguen siendo evadibles?** Solo con construcciones rebuscadas (R-05). Lo relevante: S4-03 hace que un `catch` extra ya no sea necesario para cubrir excepciones imprevistas, y el control real sigue siendo el 4746 en ejecución.

## 5. Observaciones nuevas

### R-01 · Baja · El 4743 imprevisto no deja rastro de la causa

- **Evidencia [V].** `EscuchaServidor.cs:257-266` (sin `inner`); `EventosRed.cs:53` (sin constructor con `inner`); `src/GPOS.Web/Program.cs:109` y `src/GPOS.Api/Program.cs:350-351` (el `catch` no escribe el mensaje).
- **Riesgo.** Es de diagnóstico, no de exposición. La falla sigue cerrada. Pero con un proveedor de registro roto (justo el caso que motivó S4-03), el servicio no arranca, sale con 1 y no deja en ningún sitio ni el motivo previsto ni la traza. Además, el motivo de un 4744 o un 4747 se sustituye por «imprevista».
- **Remediación (minutos).**
  - Agregar `ArranqueRedException(EventId, string, Exception inner)` y encadenar `e` en `:266`. El mensaje sigue sin la ruta, y la traza queda para un volcado o el depurador.
  - En el `catch` de `Program.cs` (API y Web), escribir `ex.Message` en `Console.Error`. El mensaje ya está saneado: solo lleva el tipo y el motivo de la regla.
  - *Alternativa descartada:* registrar `e` completo en el crítico. Llevaría al visor de eventos rutas y mensajes del proveedor, justo lo que S4-03 evitaba.

### R-02 · Baja · Vías de validación propia que la prueba todavía no ve

- **Evidencia [V].** Patrón en `RedPlataformaArquitecturaTests.cs:115-117`. Proyectos recorridos: `GPOS.Web`, `GPOS.Comun.Servidor` y `GPOS.Api` (`:155-157`). La prueba de manejador primario recorre solo la Web y `GPOS.Comun.Servidor` (`:187-200`).
- **Riesgo.** Hoy no aparece ninguna de estas vías en `src/` [V: `git grep`]. Mañana la prueba no impediría:
  - `new SslStream(flujo, false, (…) => true)`: el delegado va por posición y no nombra `RemoteCertificateValidationCallback`;
  - un `X509Chain` manual con `ChainPolicy.VerificationFlags = AllowUnknownCertificateAuthority` o `Ignore…`;
  - `UseSocketsHttpHandler(…)` (.NET 8 y posteriores), que sustituye el manejador primario igual que `ConfigurePrimaryHttpMessageHandler`;
  - `HttpMessageHandlerBuilderActions`/`PrimaryHandler` o un `IHttpMessageHandlerBuilderFilter` registrado, que también cambian el manejador del cliente de la API;
  - cualquiera de estas en `GPOS.Core`, `GPOS.Comun` o `GPOS.Reportes.Api`, que no se recorren.
- **Remediación (minutos).**
  - Agregar al patrón `\bnew\s+SslStream\b|VerificationFlags`.
  - Agregar a la prueba de manejador `\bUseSocketsHttpHandler\b|\bPrimaryHandler\b|HttpMessageHandlerBuilderActions|IHttpMessageHandlerBuilderFilter`.
  - Recorrer también `GPOS.Core`, `GPOS.Comun` y `GPOS.Reportes.Api`.
  - `GPOS.AgenteImpresion` (fijación en `ClienteDispositivo.cs:75-90`) puede entrar como excepción nombrada.

### R-03 · Baja (informativa, ya existía en `81edccad`) · `X-Forwarded-Proto: http` y antifalsificación

- **Evidencia [V].** La Web acepta `XForwardedProto` de *loopback* y de `ProxiesConfiables` (`src/GPOS.Web/Program.cs:57-62`). Con el modo, `AntiforgeryOptions.Cookie.SecurePolicy = Always` (`EscuchaServidor.cs:199`).
- **Riesgo.** Es de disponibilidad. El antifalsificación del marco lanza `InvalidOperationException` si su política es `Always` y la petición no es HTTPS [I: comprobación de SSL de `DefaultAntiforgery`]. Un proxy conocido que reenvíe `http` dejaría el inicio de sesión en 500. S2-02 no lo crea ni lo agrava: la cookie ya sale `Secure` de todos modos.
- **Remediación (minutos, opcional).** Con el modo, quitar `XForwardedProto` del reenvío, porque no hay proxy HTTP admitido delante de la Web. Ya la propuse como opcional en S2-02.

### R-04 · Baja (informativa) · `Api:Url` sin modo no se valida

- **Evidencia [V].** `ExigirUrlApi` solo comprueba si está en blanco (`ClienteApiLocal.cs:54`). `new Uri(urlApi…)` está dentro de la lambda de `AddHttpClient` (`src/GPOS.Web/Program.cs:70-73`), que se ejecuta al crear el primer cliente, no al arrancar [I]. El `?? throw` de `:69` es inalcanzable (sección 4, S2-06).
- **Riesgo.** Es de diagnóstico. Un `Api:Url` mal formado deja arrancar la Web y falla en cada llamada. Sin modo, un `http://` hacia otro equipo sigue permitido. Es el comportamiento heredado; con Estricto no hay «sin modo».
- **Remediación (minutos).** En `ExigirUrlApi`, negar también con 4743 cuando `!Uri.TryCreate(…, UriKind.Absolute, …)` o el esquema no sea `http`/`https`. Dejar el `?? throw` como guarda.

### R-05 · Baja (informativa) · Residuos de S4-04

- **Evidencia [V].** S3 y S6 no comprueban que el argumento de `ExigirArranque` sea la variable que devolvió `Preparar` (`OrdenProgramaApiTests.cs:145-200`). En la API, un `red = …` en medio pasaría (en la Web hay uno legítimo, `ExigirUrlApi`, `Program.cs:68`). Tampoco se detecta un `goto` o un `return` previos de nivel superior (este último no arranca nada, así que es inocuo).
- **Riesgo.** Solo con un cambio deliberado, que debe frenar la revisión de código. Las pruebas son una guarda contra regresiones, no una frontera.
- **Remediación (opcional, 30 min).** En la API, que la variable de `Preparar` no se reasigne entre `Preparar` y `ExigirArranque`, y que sea el segundo argumento.

## 6. Controles bien implementados

- El refresco no cambia lo que se sirve cuando el certificado vigente deja de ser utilizable, y lo dice en cada tick (S2-01).
- `Secure` en todas las cookies de la Web con el modo, sin depender del esquema de la petición, y sin efecto sin modo ni en el DEMO (S2-02).
- El filtro de anfitrión es una lista cerrada, probada sobre Kestrel real con TLS (S2-03).
- La validación propia queda acotada al cuerpo de la sobrecarga para pruebas, y el manejador primario a `UsarClienteApiLocal` (S2-05).
- Todas las salidas de `ExigirArranque` son `ArranqueRedException` con código 1, sin filtrar mensajes del proveedor; la prueba usa un mensaje con una ruta y comprueba que no aparece (S4-03).
- H-09 tiene una salida ordenada en la Web (S2-06).
- Las pruebas de texto exigen llamadas incondicionales, un solo `catch` y ninguna escucha fuera de `Program.cs` (S4-04).
- La API con modo ya no queda en HTTP ni en `:5000` (S4-01).

## 7. Remediaciones priorizadas

| # | ID | Acción | Responsable | Cuándo | Esfuerzo |
|---|---|---|---|---|---|
| 1 | R-01 | `inner` en `ArranqueRedException` y `Console.Error` en el `catch` de los dos `Program.cs` | A | PR siguiente (o este, si se reabre) | Minutos |
| 2 | R-02 | Ampliar los patrones y los proyectos de las dos pruebas | A | PR siguiente | Minutos |
| 3 | R-04 | Validar el formato de `Api:Url` sin modo (4743) | A | Cuando convenga | Minutos |
| 4 | R-03 | Sin `XForwardedProto` con el modo | A | Opcional | Minutos |
| 5 | R-05 | `red` no reasignado entre `Preparar` y `ExigirArranque` en la API | A | Opcional | 30 min |
| — | S2-04, S2-07, S2-08, S4-02, S4-05, S4-06 | Siguen como en los informes de origen | A / devops / arquitecto | Según esos informes | — |

## 8. Recomendación

**Aprobado con observaciones** para unir PR-4 y PR-2 (recomendación técnica; la unión la ordena el propietario por medio de B).

- Los ocho hallazgos del lote quedan cerrados sin regresiones de seguridad.
- La condición dura de PR-4 (S4-01, «no unir antes de PR-2») queda satisfecha si se unen juntos o PR-2 antes.
- No hay hallazgos Críticos, Altos ni Medios. R-01 a R-05 son Bajos y no bloquean.
- Siguen en pie las condiciones de los informes de origen: firma de F-5, N-1 unido y la suite oficial (`Transicion!=Ola5&Transicion!=Defecto`) en verde. Este revisor no la ejecutó: corre en el árbol en este momento.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\relectura-seguridad-pr2-pr4-adr90-2026-10-21.md`
- Supuestos: valores por omisión de `CookiePolicyOptions` (sin efecto) y orden del filtro de anfitrión del marco; la comprobación de SSL de `DefaultAntiforgery`; `GetECDsaPrivateKey` devuelve un objeto propio; `ThreadAbortException` inexistente en .NET 10; la lambda de `AddHttpClient` se ejecuta tarde. Todos son [I]. No se compiló ni se ejecutó nada.
- Decisiones candidatas a ADR: Ninguna.
- Entregas a otros agentes: desarrollador de A → R-01 y R-02 (minutos), R-04 opcional. QA o C → la suite oficial de la rama antes de unir. Devops y arquitecto → los pendientes S2-07, S4-02 y S2-04 de los informes de origen.
- Próximo paso recomendado: avisar a B de que PR-2 y PR-4 quedan en «Aprobado con observaciones» para unirlos juntos cuando la suite en curso termine en verde, y llevar R-01 y R-02 al PR siguiente.
