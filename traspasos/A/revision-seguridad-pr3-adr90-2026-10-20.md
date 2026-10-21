# Informe de seguridad: PR-3 de ADR-90 (RT-06, PT-05 punto 4): filtro por la IP de la conexión

- **Fecha:** 2026-10-20 · **Autor:** auditor-seguridad (recomendación técnica; la decisión es del propietario, C2)
- **Objeto:** commit `4fb77c8a` de la rama `a/adr90-rt06-filtro-origen` (repositorio `GPOS-NG-rt06`), comparado con `origin/a/adr90-rt01-modo-red`. Revisión **solo de lectura** (`git show`, `git diff`): no compilé ni ejecuté pruebas. Los resultados de pruebas que se citan (480/480 y 9/9) los declara el commit; no los verifiqué.
- **Contratos:** blueprint de A v2, sección 5.3 (y 5.1, 5.5, 9, 11); ADR-090 (PT-05) y la revisión `docs/seguridad/2026-10-20-revision-adr090-red-tls.md` (H-07) en `origin/master`.
- **Marcas:** [V] verificado en el código o en git; [I] inferido (comportamiento del marco ASP.NET Core 10 por su código fuente conocido, sin ejecutar).

## 1. Alcance y superficie revisada

| Archivo | Qué hace |
|---|---|
| `src/GPOS.Api/Seguridad/FiltroOrigenNodo.cs` (nuevo, 72 líneas) | Middleware de la API: desde una IP de `IpNodos` solo pasa `/api/sync/*`; lo demás, 403 `ORIGEN_NO_PERMITIDO` y evento 4750 muestreado |
| `src/GPOS.Web/Servicios/RechazoOrigenNodo.cs` (nuevo, 55 líneas) | Middleware de la Web: 403 en texto plano para toda ruta desde una IP de `IpNodos`; evento 4751 |
| `src/GPOS.Comun/Red/OrigenNodo.cs` (nuevo, 114 líneas) | Conjunto validado, pertenencia, saneamiento del texto para el registro, muestreo de 60 s |
| `src/GPOS.Comun/Red/EventosRed.cs` | EventId 4750 y 4751 |
| `src/GPOS.Api/Seguridad/LimitesPeticiones.cs:182` | `Ip()` pasa a `DireccionIp.Texto` (IPv4 mapeada → IPv4, IPv6 sin ámbito) |
| Pruebas (`tests/GPOS.Tests/Red/*`, `tests/GPOS.Web.Tests/Red/*`) | Leídas para contrastar la cobertura; no ejecutadas |

Superficie: todas las peticiones que llegan a la API y a la Web desde una IP de nodo (VPN de sucursal). El filtro **no está cableado** (no toca `Program.cs`; lo hace PR-4), así que hoy no cambia el comportamiento en ejecución salvo `LimitesPeticiones.Ip`.

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título | Estado |
|---|---|---|---|
| S3-01 | **Media** | `ForwardedHeaders_Enabled` (o IIS fuera de proceso) pone `ForwardedHeaders` antes del filtro y permite eludirlo con `X-Forwarded-For` | [I], debe cerrarse antes de PR-4 |
| S3-02 | Baja | El nodo se identifica solo por la IP vista: NAT en el túnel, IPv6 temporal o doble pila hacen que el filtro falle **abierto** sin aviso | [V] el diseño, [I] los escenarios |
| S3-03 | Baja | El filtro decide por prefijo de ruta, no por el endpoint: una plantilla futura con parámetro en el segundo segmento o un comodín de re-despacho bajo `/api/sync` lo heredaría | [V] hoy no existe ninguna |
| S3-04 | Baja | El saneamiento del registro solo cambia la categoría Cc: pasan U+2028/U+2029 y los controles bidireccionales (U+202E); el truncado puede partir un par sustituto | [V] |
| S3-05 | Baja | La escritura del 403 usa `ctx.RequestAborted` en el primer middleware, fuera de `UseExceptionHandler`: un aborto puede dejar errores en el registro fuera del muestreo | Sospecha, sin verificar |
| S3-06 | Baja (preexistente) | `LimitesPeticiones.Ip` particiona IPv6 por /128, mientras `ClaveIp` del emparejamiento usa /64; D2 usará `Ip()` como única fuente | [V] |

No hay hallazgos Críticos ni Altos.

## 3. Checklist OWASP Top 10 (2021)

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | Implementa SR-22/PT-05 como defensa por red. Observaciones S3-01, S3-02 y S3-03. El control de fondo sigue siendo la credencial del nodo con audiencia exclusiva de `/api/sync/*` (PT-05, entrega 2) |
| A02 Criptografía | No aplica (no hay criptografía en el cambio) |
| A03 Inyección | Sin SQL ni plantillas. Registro estructurado con método y ruta saneados (Cc) y truncados; observación S3-04 |
| A04 Diseño inseguro | Correcto: IP de la conexión, nunca `X-Forwarded-For`; falla cerrada al preparar con `IpNodos` inválido. Dependencia de configuración del marco: S3-01 |
| A05 Configuración | S3-01 (interruptor del marco no contemplado en la regla 1 de RT-01) |
| A06 Componentes vulnerables | No aplica (no agrega paquetes) |
| A07 Identificación y autenticación | No aplica directamente; S3-06 afecta al futuro bloqueo (cuenta, IP) de D2 |
| A08 Integridad | No aplica |
| A09 Registro y monitoreo | Bien: 4750/4751 como aviso, un evento por IP cada 60 s con suprimidos, reloj monótono, sin consulta ni encabezados. Observaciones S3-04 y S3-05 |
| A10 SSRF | No aplica |

## 4. Hallazgos

### S3-01 · Media · `ForwardedHeaders_Enabled` o IIS fuera de proceso colocan `ForwardedHeaders` antes del filtro

- **Riesgo.** El filtro supone que es el primer middleware y lee `ctx.Connection.RemoteIpAddress` (`src/GPOS.Api/Seguridad/FiltroOrigenNodo.cs:46`; `src/GPOS.Web/Servicios/RechazoOrigenNodo.cs:35`). Pero ASP.NET Core agrega su propio `ForwardedHeadersMiddleware` **por fuera de toda la canalización de la aplicación** (un `IStartupFilter`) cuando la configuración trae `ForwardedHeaders_Enabled=true` (variable `ASPNETCORE_FORWARDEDHEADERS_ENABLED` o `DOTNET_…`, la variable de entorno sin prefijo o la clave en `appsettings.json`) [I: `WebHost.ConfigureWebDefaults`]. En ese caso el marco **vacía `KnownNetworks` y `KnownProxies`**. Después, la configuración de la aplicación (`src/GPOS.Api/Program.cs:49-54`; `src/GPOS.Web/Program.cs:52-56`) solo agrega `ProxiesConfiables`, que hoy está vacío según la revisión previa (`appsettings.json:35`). Con las dos listas vacías, `ForwardedHeadersMiddleware` **no comprueba el origen** y aplica el `X-Forwarded-For` de cualquiera [I]. Consecuencias:
  1. Un nodo que mande un `X-Forwarded-For` con otra IP deja de ser «nodo» para el filtro y alcanza toda la API (incluida la superficie anónima: enumeración de empresas e inicio de sesión), y la Web, a pesar de `RechazoOrigenNodo`.
  2. Las particiones por IP de `LimitesPeticiones` pasan a ser elegidas por el cliente (efecto que ya existiría sin este PR, pero que el filtro no detecta).
  - Un efecto parecido tiene alojar el servicio detrás de IIS fuera de proceso. `UseIISIntegration` se activa con las variables `ASPNETCORE_PORT` y `ASPNETCORE_TOKEN` y agrega su filtro de encabezados reenviados: el filtro vería *loopback* o la IP reenviada, y fallaría abierto [I].
- **Por qué es Media y no Alta.** Requiere una configuración que hoy no existe en el repositorio (`grep` sin coincidencias de `FORWARDEDHEADERS`, `UseIIS` ni `ListenNamedPipe` en `src`, salvo los `deps.json` del marco [V]). Además, lo que gana el nodo es la superficie anónima, porque los datos exigen el token de persona de la central (ADR-53). Pero es una configuración que un técnico pone siguiendo la guía genérica de Microsoft «detrás de un proxy», y anula en silencio el control que fija SR-22.
- **Evidencia.** `FiltroOrigenNodo.cs:11` y `:46` (supuesto de primer lugar); blueprint 5.1, regla 1: la lista de fuentes rechazadas (4744) no incluye `ForwardedHeaders_Enabled` ni las variables de IIS [V]. El commit nombra la dependencia del orden, pero el código no la comprueba [V].
- **Remediación (la más barata que lo cierra; unos 0,05 a 0,1 días-persona).**
  1. Al preparar, que `UseFiltroOrigenNodo` y `UseRechazoOrigenNodo` lancen `ArgumentException`/`InvalidOperationException` (falla cerrada, como con `IpNodos` inválido) si `IConfiguration["ForwardedHeaders_Enabled"]` es `true`, o si `ASPNETCORE_TOKEN` o `ASPNETCORE_IIS_HTTPAUTH` están presentes, siempre que `IpNodos` no esté vacío. Agregar una prueba con la variable puesta.
  2. **Alternativa equivalente:** agregar esas claves a la regla 1 de RT-01 (4744) en `EvaluacionArranqueRed`. Cubre también los límites por IP sin nodos, pero toca PR-1a, que ya está en revisión. Recomiendo la 1 en PR-3 y la 2 como precisión en RT-01.
  3. **Descartada:** leer la IP original de `X-Original-For`. Si el marco no aplicó el reenvío, ese encabezado puede venir del cliente y no es fiable.
- **Plazo:** antes de unir PR-4 (cableado). No bloquea unir PR-3, que no está cableado.

### S3-02 · Baja · El filtro falla abierto si la IP que llega no es la declarada

- **Riesgo.** Por contrato, solo se filtran las IP que están exactamente en `IpNodos` (`OrigenNodo.cs:48-55`; blueprint 5.3, «Otras clases: sin filtro»). Si el servidor del nodo llega con otra dirección, el filtro no lo reconoce y no deja ningún evento:
  - el túnel hace NAT (por ejemplo, enmascaramiento en el enrutador de la sucursal);
  - el nodo usa IPv6 con direcciones temporales (privacidad SLAAC);
  - la VPN es de doble pila y `IpNodos` solo declara una familia.

  Con NAT también puede pasar lo contrario: si la IP compartida del enrutador se declara como nodo, todos los equipos que salen por ella quedan limitados a `/api/sync/*`. Eso no es una elusión, pero sí un riesgo de disponibilidad.
- **Evidencia.** `src/GPOS.Comun/Red/OrigenNodo.cs:48-55` [V]. Los escenarios de red son [I].
- **Remediación.** Para devops (guía de implantación y lista de R-VPN): túnel sin NAT hacia la central; nodo con IP fija; si hay IPv6, declarar las dos familias o deshabilitar las direcciones temporales en el servidor del nodo. Mantener la prueba de laboratorio «filtro con un nodo real por la VPN» (blueprint 9). Defensa en profundidad, ya decidida: la credencial del nodo con audiencia exclusiva de `/api/sync/*` (PT-05, punto 3). Cuando exista, conviene un aviso si una credencial de nodo llega desde una IP que no está en `IpNodos`. Costo: documentación, sin código en PR-3.

### S3-03 · Baja · Decisión por prefijo de ruta y no por el endpoint

- **Riesgo.** El filtro deja pasar cualquier ruta que empiece por el segmento `/api/sync` (`FiltroOrigenNodo.cs:51-52`). Lo que haya después lo decide el enrutamiento. Hoy ninguna plantilla de la API casa con `/api/sync/...` fuera de la sincronización: los grupos tienen un segundo segmento literal (`/api/tablas/{tabla}`, `/api/documentos/{tipo}`, etc.) y no hay `MapFallback` [V, `grep` de `MapGroup`/`Map*` en `src/GPOS.Api`]. Pero una plantilla futura del tipo `/api/{modulo}/…`, o un endpoint de sync con comodín (`{**ruta}`) que vuelva a despachar internamente, heredaría el paso.
- **Remediación (barata, unos 0,05 días-persona).** Agregar una prueba de arquitectura: todo endpoint cuya plantilla pueda casar con el prefijo `/api/sync` pertenece al grupo de sincronización, y ninguno usa comodín. Opcional, como segunda capa: como la API no llama a `UseRouting()` de forma explícita, `WebApplication` lo agrega al principio [I], y el endpoint ya está elegido cuando corre el filtro. Se podría exigir además un metadato «solo sync» en `ctx.GetEndpoint()` (si es `null`, se deja pasar para que responda 404). **Descartado por ahora:** filtrar solo por el metadato, porque dependería del orden implícito del enrutamiento.

### S3-04 · Baja · Saneamiento incompleto del texto del registro

- **Riesgo.** `TextoRegistro` solo cambia `char.IsControl` (categoría Cc) (`OrigenNodo.cs:62-69`). Kestrel decodifica el UTF-8 de la ruta, así que llegan al evento U+2028/U+2029 (separadores de línea, que algunos destinos de archivo o visores tratan como salto) y los formatos bidireccionales (U+202E, U+2066-2069), que pueden falsear cómo se ve la línea en el Visor de eventos. El corte en 200 caracteres puede dejar un sustituto suelto (U+FFFD en UTF-8). El impacto es bajo: el emisor ya está identificado por la IP, que es canónica, y la frecuencia está muestreada.
- **Remediación.** Cambiar también las categorías Cf, Zl y Zp, y los sustitutos sueltos, o registrar `PathString.ToUriComponent()`, que escapa lo no ASCII, antes de truncar. Agregar un caso de prueba. Costo: menos de 0,05 días-persona.
- **Fuera de alcance (preexistente, otro agente):** `LimitesPeticiones.cs:146` registra `http.Request.Path` sin sanear en el aviso de límite excedido.

### S3-05 · Baja · Sospecha: aborto del cliente durante la escritura del 403

- **Riesgo.** `await r.Body.WriteAsync(Cuerpo, ctx.RequestAborted)` (`FiltroOrigenNodo.cs:70`; `RechazoOrigenNodo.cs:52`) corre antes de `UseExceptionHandler`. Si el nodo corta la conexión, la `OperationCanceledException` sube hasta Kestrel. Según la versión, Kestrel puede registrarla como error de la aplicación, una entrada por petición y **fuera** del muestreo de 60 s (R-7). No lo verifiqué.
- **Remediación.** Escribir con `CancellationToken.None` (son 74 bytes) o capturar la `OperationCanceledException` cuando `RequestAborted` está cancelado. Costo: minutos.

### S3-06 · Baja (preexistente; relevante para D2) · IPv6 por /128 en los límites por IP

- **Riesgo.** `LimitesPeticiones.Ip` (`LimitesPeticiones.cs:182`) da la IPv6 completa. `ClaveIp` del emparejamiento la agrupa por /64 (`src/GPOS.Core/Servicios/Modulos/Restaurante/Dispositivos/Contratos.cs:166-178`, V-01), porque un equipo puede rotar dentro de su /64. El blueprint (5.3) dice que D2 usará `Ip()` como única fuente para la clave (cuenta, IP) del bloqueo: con /128, ese bloqueo se elude rotando direcciones. **No lo introduce este PR.** Lo que sí hace este PR: quitar el `ScopeId` une solo direcciones de enlace local de interfaces distintas, lo que es despreciable para los límites.
- **Remediación.** Para D2: usar una clave de partición por /64 en IPv6 (reutilizar `ClaveIp` o una variante en `DireccionIp`), sin cambiar el texto que se registra.

## 5. Controles bien implementados (verificados)

- **IP de la conexión, nunca `X-Forwarded-For`:** `FiltroOrigenNodo.cs:46`, `RechazoOrigenNodo.cs:35`. Las pruebas cubren `X-Forwarded-For` falsificado en los dos sentidos (`FiltroOrigenNodoTests.cs:133-152`).
- **Normalización de la ruta.** `StartsWithSegments(RutaSync, OrdinalIgnoreCase)` exige `/` o el final después de `sync`. Por eso `/api/syncx`, `/api/sync-x`, `/api/sync;x`, `/api/sync./x`, `/api\sync` y `/api//sync` no pasan: fallan **cerrado**, con 403. Los tres primeros y `//` tienen prueba (`FiltroOrigenNodoTests.cs:100-106`); `;`, el punto final y la barra invertida los deduzco del algoritmo [I]. Kestrel resuelve `..` y `%2e%2e` antes del filtro y deja `%2F` codificado (prueba con Kestrel real, `:295-309`). `/API/SYNC` pasa, igual que en el enrutamiento, que tampoco distingue mayúsculas. `OPTIONS` (CORS *preflight*) a una ruta que no es de sync recibe 403 (`:105`). El método no influye en la decisión.
- **IPv4 mapeada, ámbito e IPv6:** `DireccionIp.Normalizar` (`DireccionIp.cs:13-20`). Hay pruebas con `::ffff:`, `::FFFF:` y `%4` (`FiltroOrigenNodoTests.cs:107-130`).
- **IP nula:** no se filtra, según el contrato (`OrigenNodo.cs:48-55`). En producción Kestrel escucha por TCP; no hay canalizaciones con nombre ni sockets Unix [V, `grep`].
- **Memoria acotada:** `Registrar` solo se llama después de `EsNodo` (`FiltroOrigenNodo.cs:46-56`), así que el diccionario no pasa de `|IpNodos|` entradas (`OrigenNodo.cs:82`). El contador se satura en `int.MaxValue`, el bloqueo es por IP y el reloj es monótono. El 403 es barato (cuerpo fijo, sin SQL). Que corra antes del limitador no es un problema: lo frena el costo, no un cupo.
- **403 sin fuga:** el cuerpo es fijo, sin `detail` ni `traceId`, con `no-store`. Es igual para una ruta que existe y para una que no, así que no permite enumerar rutas (`FiltroOrigenNodo.cs:27`, `:66-70`). La Web responde con texto plano, sin HTML (`RechazoOrigenNodo.cs:19-21`). Lo único que revela es que el origen está clasificado, que es aceptable.
- **Evento sin datos sensibles:** sin la consulta ni encabezados; ruta truncada a 200 y método a 16. Hay prueba con secretos en la consulta, la cookie, `Authorization` y el cuerpo (`FiltroOrigenNodoTests.cs:233-258`).
- **Unión de particiones del limitador:** `::ffff:a.b.c.d` y `a.b.c.d` pasan a ser un solo cupo. Eso cierra el «doble cupo» de un cliente de doble pila y no reduce el cupo de nadie más. `desconocida` no cambia. El freno del emparejamiento ya normalizaba y tiene prueba de equivalencia.
- **Validación al preparar:** con una IP de *loopback*, difusión, multidifusión, enlace local o compatible, se lanza `ArgumentException` al montar la canalización, con la posición y sin la IP (`OrigenNodo.cs:27-41`). Como esto pasa antes de `Run`, el servicio termina con código distinto de 0: **la falla cerrada es correcta**. En la práctica, RT-01 ya valida antes con `TryParseHost` (4743). Si esta excepción llegara a saltar, no dejaría un EventId propio, solo la excepción no controlada; es aceptable porque es un segundo control.
- **EventId 4750/4751 sin choque:** `git grep "475[0-2]"` en todas las referencias de `origin` solo encuentra comentarios en `a/adr90-rt01-modo-red` y el rango 4743-4752 de `ArranqueRedTests.cs:705` [V]. Los nombres coinciden con la tabla 5.5 del blueprint.

## 6. Remediaciones priorizadas

| # | Hallazgo | Acción | Cuándo | Esfuerzo |
|---|---|---|---|---|
| 1 | S3-01 | Falla cerrada al preparar si `ForwardedHeaders_Enabled=true` o hay variables de IIS fuera de proceso, más una prueba. Como precisión, sumar esas claves a la regla 1 de RT-01 | En PR-3, o como muy tarde **antes de PR-4** | 0,05-0,1 dp |
| 2 | S3-03 | Prueba de arquitectura de las plantillas bajo `/api/sync` | Con el primer endpoint de sync, o en PR-4 | 0,05 dp |
| 3 | S3-04 / S3-05 | Sanear Cf/Zl/Zp y los sustitutos; escribir el 403 sin `RequestAborted` | En PR-3 (son de pocas líneas) | <0,05 dp |
| 4 | S3-02 | Guía: túnel sin NAT, IP fija, IPv6 declarada o sin direcciones temporales; laboratorio con un nodo real | Antes del primer cliente con nodo | Documentación |
| 5 | S3-06 | Clave /64 para IPv6 en el bloqueo (cuenta, IP) | D2 (desde el 2026-11-09) | 0,05 dp |

Total del código propuesto: unos 0,15 a 0,25 días-persona.

**Pruebas que conviene agregar** (sin pasos de explotación): las variantes de ruta con `;`, punto final y barra invertida desde un nodo (esperado: 403); `HEAD` desde un nodo (esperado: 403 sin cuerpo); la canalización con `ForwardedHeaders_Enabled=true` (esperado: no prepara).

## 7. Recomendación

**Aprobado con observaciones** (recomendación técnica; la decisión de unir es del propietario a través de B). No quedan hallazgos Críticos ni Altos. El filtro cumple el contrato 5.3: juzga la IP de la conexión, valida la ruta por segmentos, devuelve un 403 sin fuga, deja eventos muestreados con memoria acotada y falla cerrado al preparar. **Condición para PR-4:** cerrar S3-01. Hasta entonces, el control de SR-22 puede anularse en silencio con una opción de configuración del marco.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\revision-seguridad-pr3-adr90-2026-10-20.md`
- Supuestos: comportamiento de ASP.NET Core 10 con `ForwardedHeaders_Enabled`, `UseIISIntegration`, el `UseRouting` implícito y la cancelación de escrituras en Kestrel deducido de su código fuente [I], sin ejecutar; `ProxiesConfiables` vacío en la configuración por omisión, según la revisión previa; resultados de las pruebas tomados del mensaje del commit.
- Decisiones candidatas a ADR: Ninguna. Hay una precisión para RT-01: sumar `ForwardedHeaders_Enabled` y las variables de IIS fuera de proceso a las fuentes rechazadas (4744).
- Entregas a otros agentes: desarrollador (A) → S3-01, S3-04 y S3-05 en PR-3; arquitecto-software → precisión de la regla 1 de RT-01 y prueba de arquitectura de S3-03 en PR-4; devops → guía de S3-02 (sin NAT, IP fija, IPv6); D2 → clave /64 de S3-06; qa-automatizado → las pruebas de la sección 6.
- Próximo paso recomendado: que A agregue la falla cerrada de S3-01 (y S3-04/05) a PR-3 antes de pedir la unión a B.
