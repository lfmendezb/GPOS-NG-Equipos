# Blueprint técnico (contratos primero): ADR-90, RT-01, escucha de RT-05 y reglas de RT-06 en la aplicación

- **Fecha:** 2026-10-20 · **Autor:** arquitecto-software del equipo A · **Estado:** propuesta de contratos para revisión de B y del auditor-seguridad (no es una decisión firmada).
- **Alcance:** solo lo que A construye en `GPOS.Api` y `GPOS.Web`. No diseña el paquete único, la ACL del registro, las reglas del cortafuegos ni la tarea de renovación (son de B), ni el verbo `GPOS.Migracion tls` (de A, en otro blueprint).
- **Convención:** [V] = verificado con `git show`/`git grep` (cita `archivo:línea`); [I] = inferido. Código leído en `origin/feature/modelo-ng` @ `b8f166db` (base de las ramas `a/`); documentos en `origin/master` @ `45a9ab75`. No se compiló ni se ejecutó nada.

## 0. Fuentes y estado

| Fuente | Estado [V] |
|---|---|
| `docs/adr/ADR-090.md` | **Existe en `origin/master`** (no en `origin/feature/modelo-ng`). RT-01 `:25-33`, RT-05 `:60-70`, RT-06 `:71-79`, PT-01 `:236`, PT-02 `:237`, PT-05 `:240`, PT-06 `:241`, H-15 `:251` |
| `docs/decisiones/2026-10-20-hoja-firma-precisiones-adr090.md` | En `origin/master`. Firmada PT-01 a PT-10 (`:5`). Qué se puede construir ya: `:280-290` |
| `docs/seguridad/2026-10-20-revision-adr090-red-tls.md` | En `origin/master`. H-01, H-02, H-07 y H-08 (`:65-110`) |
| `docs/decisiones/2026-10-20-hoja-firma-ola5-tramo4-e-instalador.md` | En `origin/master`, firmada salvo B-9 (`:5`). **RC-T4-3** (`:72`): lo que toque `src/GPOS.Api/Program.cs` se une **después del 2026-11-16**; la zona S está congelada del 11-11 al 11-13 |

**Hechos del código que fijan el diseño**
- La API no arma su escucha: solo aplica límites a Kestrel con `GPOS:Servidor` (`src/GPOS.Api/Program.cs:45-46`) [V]. `UseHttps`, `Listen*` y `AddWindowsService` no aparecen en `GPOS.Api` [V; el registro como servicio es N-1, de B].
- `ForwardedHeaders` confía en `X-Forwarded-For` de *loopback* y de `ProxiesConfiables` (`Program.cs:49-54`) y lo aplica en `app.UseForwardedHeaders()` (`Program.cs:349`), primer *middleware* de la canalización [V]. (La hoja cita `:37-42` y `:154` de `master`; en la base de A son `:49-54` y `:349`.)
- `LimitesPeticiones.Ip` no normaliza IPv4 mapeada (`src/GPOS.Api/Seguridad/LimitesPeticiones.cs:178`) [V]; `AuthEndpoints` sí lo hace en tres sitios (`src/GPOS.Api/Endpoints/AuthEndpoints.cs:212`, `:257`, `:283`) [V].
- La Web toma `Api:Url` (`src/GPOS.Web/Program.cs:62-67`), con valor por omisión `http://localhost:5071/` (`src/GPOS.Web/appsettings.json:14`), `AllowedHosts: "*"` (`:9`), y agrega `ReenvioIpCliente` a su único `HttpClient` (`Program.cs:59`, `:67`) [V]. Usa HSTS y `UseHttpsRedirection` fuera de `Development` (`Program.cs:103-109`) [V].
- Patrón a reutilizar: la API de reportes rechaza `Kestrel:Endpoints` (`src/GPOS.Reportes.Api/Endpoints/ServiciosReportes.cs:83-85`), valida sus direcciones (`:143-151`) y comprueba las enlazadas de verdad con `IServerAddressesFeature` en `ApplicationStarted` (`:170-179`) [V]. Hoy registra un crítico **sin** `EventId` (`:176`) [V].
- `GPOS.Comun` no tiene referencia a ASP.NET Core (`src/GPOS.Comun/GPOS.Comun.csproj`) y lo usan `GPOS.Api`, `GPOS.Web`, `GPOS.Migracion`, `GPOS.Reportes` y `GPOS.Reportes.Api` [V].
- Ya hay lectura de `HKLM` con `Registry.LocalMachine` en el agente (`src/GPOS.AgenteImpresion/ConfiguracionAgente.cs:13-19`) [V].
- **EventId:** el **4742 ya está tomado** por `ModuloVenceIgnorado` del PR #103 (`origin/a/dv07-formato-licencia:src/GPOS.Core/Sistema/Licencia/EstadoLicenciaService.cs:145`) [V]. Del 4743 al 4769 no aparece ningún número en `src` de ninguna rama de `origin` ni en el área común [V, `git grep` sobre todas las ramas]. Por eso este blueprint empieza en el **4743**.

## 1. Contexto y alcance

| Pieza | Cláusula y precisión | Qué cubre aquí |
|---|---|---|
| **P1** | RT-01 + PT-06 | Modo leído **solo** del registro; falla cerrada; rechazo de todas las fuentes de direcciones; comprobación de las direcciones efectivas |
| **P2** | RT-05 + PT-01 + PT-02 | Escucha armada en código por modo; selector de certificado por huella del registro con caché de 5 min; URL de la Web hacia la API por el nombre del sitio con la conexión TCP a *loopback* (`ConnectCallback`) |
| **P3** | RT-06 + PT-05 (punto 4) | Filtro sobre la IP de la conexión, **antes** de `UseForwardedHeaders`, para la clase «nodos»; normalización de IPv4 mapeada; corrección de `LimitesPeticiones.Ip` |

**Fuera de alcance:** la credencial del nodo con audiencia exclusiva de `/api/sync/*` (PT-05, punto 5; es de la entrega 2 y `/api/sync/*` no existe); H-15 (cookies y `AllowedHosts`), aunque los contratos de P1 la dejan en una línea (ver 10); el verbo `tls`; todo lo de B.

## 2. Módulos y dependencias

```
GPOS.Comun (sin ASP.NET)                 GPOS.Comun.Servidor (nuevo; FrameworkReference Microsoft.AspNetCore.App)
  Red/ModoRed, ConfiguracionRed            Red/EscuchaServidor   (Kestrel, fuentes rechazadas, direcciones efectivas)
  Red/IFuenteConfiguracionRed              Red/SelectorCertificadoServidor (TLS, caché, eventos)
  Red/FuenteRegistroWindows                Red/ClienteApiLocal   (SocketsHttpHandler + ConnectCallback)
  Red/DireccionIp (normalizar, /32)        Red/EventosRed        (EventId 4743-4752)
  Red/ValoresRegistroServidor (nombres)         ^            ^
        ^      ^                                |            |
        |      +---------- GPOS.Migracion (verbo tls: solo nombres de valores)
        |                                       |            |
     GPOS.Api ----------------------------------+        GPOS.Web
       Seguridad/FiltroOrigenNodo (nuevo)              Servicios/RechazoOrigenNodo (nuevo)
```

- Sin ciclos: `GPOS.Comun.Servidor → GPOS.Comun`; `GPOS.Api` y `GPOS.Web → GPOS.Comun.Servidor`.
- **Por qué un proyecto nuevo:** P1 y P2 usan Kestrel y los comparten la API y la Web. **Descartado:** (b) `FrameworkReference` de ASP.NET en `GPOS.Comun`, porque lo arrastraría a `GPOS.Migracion` y a `GPOS.Reportes` (el plan del tramo 4 pide que esa biblioteca no cargue ASP.NET); (c) archivos vinculados (`Compile Include … Link`) como el anillo de la Web: duplica la compilación y las pruebas. Costo de (a): un `.csproj` y una entrada en la solución; el MSI de B recoge un DLL más (pregunta Q-9).
- El filtro de P3 vive en `GPOS.Api/Seguridad/FiltroOrigenNodo.cs`, archivo nuevo **fuera** de la zona S de DB-7 (zona S = `Seguridad.cs`, `Program.cs`, `PermisosServidor.cs`, `RevocacionSesiones.cs`, `ValidacionAcceso`; `docs/arquitectura/2026-10-18-db7-blueprint-v3.md:776` [V]).

## 3. C4

No aplica en nivel de contexto ni de contenedores: los contenedores (`GPOS.Web`, `GPOS.Api`, API de reportes y agente) ya están en ADR-90 y no cambian. Componentes: el diagrama de la sección 2 basta.

## 4. Modelo de dominio (contratos de configuración)

### 4.1 Registro: `HKLM\SOFTWARE\GPOS NG\Servidor` (vista de 64 bits, `RegistryView.Registry64`)

Única fuente del modo, de los puertos y de la huella (PT-06, PT-02). El servicio **no** lee estos valores del entorno ni de `appsettings`.

| Valor | Tipo | Dominio | Lo escribe | Lo lee | Si falta | Si es inválido |
|---|---|---|---|---|---|---|
| `ModoRed` | `REG_SZ` | `UnEquipo` o `ServidorSitio` (comparación ordinal exacta) | paso del *bundle* (B) | API, Web | **Sin modo** (4.3) | 4743, no arranca |
| `PuertoApi` | `REG_DWORD` | 1024–65535; distinto de `PuertoWeb`, de 5073 (reportes) y de 17654 (agente) | *bundle* (B; 5071 si el técnico no da `PUERTO_API`) | API, Web | con `ModoRed`: 4743 | 4743 |
| `PuertoWeb` | `REG_DWORD` | 1–65535 | *bundle* (B), **solo** en la excepción del 443 ocupado (riesgos de ADR-90, `:186`) | Web | 443 | 4743 |
| `NombresServidor` | `REG_MULTI_SZ` | 1 a 16 nombres; el **primero** es un nombre DNS (no IP: sin SNI no hay nombre que validar) y no es `localhost`; sin `.local` (PT-03) | *bundle* (B), desde `NOMBRES_SERVIDOR` | Web | `ServidorSitio`: 4743. `UnEquipo`: no se usa | 4743 |
| `HuellaApi`, `HuellaWeb` | `REG_SZ` | 64 caracteres hexadecimales en mayúsculas: SHA-256 del DER del certificado | verbo `tls` (A), en el orden de PT-02 | API / Web | con `ModoRed`: 4747, no arranca | 4743 |
| `IpNodos` | `REG_MULTI_SZ` | IP literal, con o sin `/32` o `/128`; cualquier otro prefijo es inválido | *bundle* (B), desde `IP_NODOS` | API, Web | lista vacía | 4743, no arranca |

- `SUBREDES_PUESTOS` y `SUBREDES_REMOTOS` (PT-05) **no** los lee la aplicación en la v1: sirven solo al cortafuegos. **Descartado:** clasificar las tres clases en la API desde ya; PT-05 solo ordena filtrar por ruta a los nodos, y la distinción de remotos en la bitácora no tiene un requisito firmado en la API (C13.5).
- **Huella SHA-256 y no la «huella» SHA-1 de Windows:** `X509Store.Find(FindByThumbprint)` usa SHA-1; se busca recorriendo `LocalMachine\My` y comparando `GetCertHash(HashAlgorithmName.SHA256)`. Son pocos certificados [I]. Evita depender de SHA-1 en Avanzada.
- Los nombres de los valores son constantes en `GPOS.Comun/Red/ValoresRegistroServidor.cs`, compartidas con el verbo `tls`.

### 4.2 Tipos (en `GPOS.Comun/Red`)

```csharp
public enum ModoRed { UnEquipo = 1, ServidorSitio = 2 }
public enum ServicioRed { Api, Web }

public sealed record ConfiguracionRed(
    ModoRed Modo, int PuertoApi, int PuertoWeb, IReadOnlyList<string> NombresServidor,
    string? HuellaApi, string? HuellaWeb, IReadOnlySet<IPAddress> IpNodos);   // IpNodos ya normalizadas

public abstract record LecturaRed
{
    public sealed record SinModo : LecturaRed;                          // ModoRed ausente
    public sealed record Valida(ConfiguracionRed Red) : LecturaRed;
    public sealed record Invalida(string Valor, string Motivo) : LecturaRed;   // Motivo sin datos sensibles
}

public interface IFuenteConfiguracionRed { LecturaRed Leer(); }          // también la usa el refresco del selector
[SupportedOSPlatform("windows")] public sealed class FuenteRegistroWindows : IFuenteConfiguracionRed { … }

public static class DireccionIp
{
    public static IPAddress? Normalizar(IPAddress? d);   // IPv4 mapeada → IPv4; IPv6 sin ScopeId
    public static bool TryParseHost(string texto, out IPAddress ip);   // acepta "a.b.c.d", "a.b.c.d/32", "x::y", "x::y/128"
}
```

En Linux (ADR-129) no hay fuente todavía: la fábrica devuelve `SinModo` [I; la fuente de Linux es de la fase de ADR-129].

### 4.3 Estado «sin modo» (registro ausente)

No es un tercer modo instalable: el paquete exige `MODO_RED` en la primera instalación (PT-06), así que solo se da en desarrollo, en las pruebas y en el DEMO que todavía no usa el paquete.

- **(a, recomendada)** Se conserva la configuración actual (`urls`, `launchSettings`, `Api:Url`), pero **toda dirección efectiva debe ser de *loopback*** (cualquier esquema; A5 admite HTTP en *loopback*). Si no, 4746 y se detiene. Cada arranque deja el 4745 (aviso). Es **más** restrictivo que «un equipo», así que no es un valor por omisión que abra puertos.
- **(b)** Igual que hoy, sin comprobar direcciones, con el aviso 4745. No rompe un DEMO que hoy se abra desde otra PC, pero deja sin falla cerrada una instalación a la que se le borre el registro (hace falta ser administrador).
- **(c, descartada)** No arrancar sin registro: rompe el desarrollo, las pruebas y el DEMO hasta que adopte el paquete (A-5).
- Se recomienda (a), salvo que B confirme que el DEMO se usa desde otra PC (Q-3). En ese caso, (b) **hasta la primera instalación de cliente** y luego (a).

## 5. Contratos

### 5.1 P1 · RT-01: arranque con falla cerrada (`GPOS.Comun.Servidor/Red/EscuchaServidor.cs`)

```csharp
public static class EscuchaServidor
{
    // Antes de Build: lee la fuente, valida, rechaza fuentes de direcciones y arma ConfigureKestrel (P2).
    // No lanza: guarda el resultado para registrarlo con el logger real.
    public static EstadoRed Preparar(WebApplicationBuilder builder, ServicioRed servicio, IFuenteConfiguracionRed? fuente = null);

    // Después de Build y antes de Run: registra 4743/4744/4747 y lanza ArranqueRedException (el proceso termina con código ≠ 0);
    // en SinModo registra 4745; engancha la comprobación de direcciones efectivas (4746) a ApplicationStarted.
    public static void ExigirArranque(WebApplication app, EstadoRed estado);
}
public sealed class EstadoRed { public ConfiguracionRed? Red { get; } public IReadOnlySet<IPAddress> IpNodos { get; } /* vacío en SinModo */ … }
public sealed class ArranqueRedException : Exception { … }   // mensaje sin rutas ni valores sensibles
```

**Reglas** (con `ModoRed` presente; en `SinModo` solo rigen la 4 y la comprobación de *loopback* de 4.3):
1. **Fuentes de direcciones rechazadas** (4744): en la configuración, `urls`, `http_ports`, `https_ports`, `preferHostingUrls` (si es `true`), y cualquier hijo de `Kestrel:Endpoints` o de `Kestrel:Certificates`; en el entorno del proceso, `ASPNETCORE_URLS`, `DOTNET_URLS`, `ASPNETCORE_HTTP_PORTS`, `DOTNET_HTTP_PORTS`, `ASPNETCORE_HTTPS_PORTS`, `DOTNET_HTTPS_PORTS`, `ASPNETCORE_PREFERHOSTINGURLS` y `DOTNET_PREFERHOSTINGURLS`. Se miran las dos cosas porque `WebApplicationBuilder` copia la configuración del anfitrión en `builder.Configuration` [I: comportamiento documentado de .NET; lo fija una prueba]. `preferHostingUrls` se incluye porque, en `true`, hace que `urls` **sustituya** a los puntos armados en código [I].
2. **Valores** según la tabla de 4.1; un valor inválido → 4743.
3. **Una sola fuente:** la variable `GPOS_MODO_RED` o la clave `GPOS:Red:Modo`, si aparecen con un valor distinto del registro (o con el registro ausente) → 4743. Si coinciden, se ignoran.
4. **Direcciones efectivas** (4746, en `ApplicationStarted`, con `IServerAddressesFeature`, como `ServiciosReportes.cs:170-179`):
   - `UnEquipo`: toda dirección es `https` y de *loopback*.
   - `ServidorSitio`: toda dirección es `https` y su puerto es el armado; **ninguna** `http`, tampoco en *loopback* (no se arma ninguna).
   - Si falla: `LogCritical(4746)`, `Environment.ExitCode = 1` y `StopApplication()`.
5. La API de reportes **no** cambia en estas piezas (sigue en `http://localhost:5073`, RT-05). Recomendación aparte, sin PR aquí: que su crítico de `:176` lleve un `EventId` (pregunta Q-5).

### 5.2 P2 · RT-05: escucha por modo y selector

**Puntos de escucha armados en código** (dentro de `Preparar`, con `ConfigureKestrel`; se suman a `OpcionesServidor.Aplicar` y `OpcionesServidorWeb.Aplicar`, que no cambian):

| Servicio | `UnEquipo` | `ServidorSitio` |
|---|---|---|
| `GPOS.Api` | `ListenLocalhost(PuertoApi)` + HTTPS | `ListenAnyIP(PuertoApi)` + HTTPS (en Windows, socket `[::]` de doble pila [I]) |
| `GPOS.Web` | `ListenLocalhost(PuertoWeb)` + HTTPS | `ListenAnyIP(PuertoWeb)` + HTTPS |
| Puerto 80 / HTTP | ninguno | ninguno |

- Protocolos: `HttpProtocols.Http1AndHttp2`; TLS: `SslProtocols.Tls12 | Tls13` explícito; sin certificado de cliente. Las suites de Schannel las fija devops (RT-09).
- HTTPS por `ListenOptions.UseHttps(TlsHandshakeCallbackOptions { OnConnection = _ => selector.OpcionesVigentes, HandshakeTimeout = 10 s })`.
  - Así cada saludo usa un `SslStreamCertificateContext` ya construido (`offline: true`, sin descargas AIA), en lugar de armar la cadena en cada conexión [I: a medir en el laboratorio].
  - `ApplicationProtocols` se fija en `[h2, http/1.1]`; con la devolución de llamada no lo pone Kestrel [I; lo fija una prueba].
  - **Descartado:** `ServerCertificateSelector` (más simple, pero no controla el contexto ni los protocolos y no deja cachear la cadena).

**Selector** (`GPOS.Comun.Servidor/Red/SelectorCertificadoServidor.cs`):

```csharp
public interface IAlmacenCertificadosServidor { X509Certificate2? BuscarPorSha256(string huella); }   // prod: LocalMachine\My, ReadOnly|OpenExistingOnly
public sealed class SelectorCertificadoServidor : IDisposable
{
    public SelectorCertificadoServidor(ServicioRed servicio, IFuenteConfiguracionRed fuente, IAlmacenCertificadosServidor almacen,
                                       TimeProvider reloj, ILogger log);
    public SslServerAuthenticationOptions OpcionesVigentes { get; }   // lectura volátil; nunca null tras el arranque
    public string HuellaVigente { get; }
    public bool CargarAlArrancar();                                   // false → 4747 y ExigirArranque no deja arrancar
}
```

- **Refresco:** `PeriodicTimer` de **5 minutos** sobre `TimeProvider`. **No se lee el registro ni el almacén dentro del saludo TLS**: el saludo solo lee una referencia (sin bloqueo ni E/S en el hilo de la conexión).
- **Un certificado es utilizable si:** está en el almacén; su SHA-256 coincide; tiene llave privada **y la cuenta del servicio la abre** (`GetECDsaPrivateKey()`, o `GetRSAPrivateKey()` para un certificado del cliente; una `CryptographicException` lo hace no utilizable); trae EKU `serverAuth`; `NotBefore ≤ ahora < NotAfter`.
- **Cambio de huella:** si la nueva es utilizable, se cambia y se registra el 4749 (información). Si no, **se sigue sirviendo el anterior** y se registra el 4748 (crítico), como mucho una vez por huella en cada refresco (PT-02).
- **El anterior se conserva en memoria** hasta el siguiente cambio, para los saludos en curso, y se libera después.
- **Al arrancar**, sin certificado utilizable: 4747 y no arranca.
- El selector **no** juzga el vencimiento cercano: los avisos a 20, 10 y 3 días son de la tarea de renovación de B (H-11).

**Cliente de la Web hacia la API** (`GPOS.Comun.Servidor/Red/ClienteApiLocal.cs`; PT-01):

```csharp
public static class ClienteApiLocal
{
    public static Uri DireccionApi(ConfiguracionRed red);
    //   UnEquipo:      https://localhost:{PuertoApi}/
    //   ServidorSitio: https://{NombresServidor[0]}:{PuertoApi}/
    public static SocketsHttpHandler CrearManejador(ConfiguracionRed red);
    internal static SocketsHttpHandler CrearManejador(ConfiguracionRed red, X509Certificate2 raizPruebas);   // solo pruebas (InternalsVisibleTo)
}
```

- `ConnectCallback`: si `DnsEndPoint.Host` (sin distinguir mayúsculas) no es el anfitrión de `DireccionApi`, o el puerto no es `PuertoApi`, lanza `HttpRequestException` («destino no permitido»). Si coinciden, conecta un `Socket` a `127.0.0.1` y, si falla, a `::1`, con `NoDelay`. No consulta DNS.
- `SslOptions`: `TargetHost` = el nombre de la URL (SNI y validación sobre ese nombre; lo hace `SocketsHttpHandler` por omisión [I, ya señalado en la hoja `:327`]), `EnabledSslProtocols = Tls12 | Tls13`, `CertificateRevocationCheckMode = NoCheck` (RT-04: no hay CRL ni OCSP).
- **Sin `RemoteCertificateValidationCallback`:** la cadena y el nombre los valida el sistema. Exige que la CA del sitio esté en `LocalMachine\Root` **del propio servidor**; el navegador del servidor la necesita igual (Q-8).
  - **Descartado:** confianza personalizada con la CA de `%ProgramData%\GPOS NG\Servidor\tls\` en producción. Abre un segundo camino de confianza y obliga a excepciones en la prueba de arquitectura de RT-10, punto 5. Solo la sobrecarga interna de pruebas la usa.
- `PooledConnectionLifetime = 10 min`: las conexiones abiertas toman el certificado renovado de la API sin reiniciar la Web.
- **`Api:Url` con modo presente:** la URL sale de `DireccionApi` (registro). Si la configuración trae un `Api:Url` distinto → 4743, no arranca. En `SinModo` rige `Api:Url` como hoy. Esto cumple H-09 («sin `Api:Url` por omisión fuera de `Development`») sin que el MSI escriba la URL. **Alternativa:** que el MSI escriba `Api:Url` en `GPOS.Web.json`. Exige añadir `Api` a `ArchivoInstalacion.SeccionesPermitidas` (`src/GPOS.Comun/Configuracion/ArchivoInstalacion.cs:27`) y abre dos fuentes del puerto que pueden divergir; se descarta salvo que B prefiera (Q-2).

### 5.3 P3 · RT-06: filtro por la IP de la conexión (PT-05, punto 4)

```csharp
// GPOS.Api/Seguridad/FiltroOrigenNodo.cs (nuevo)
public static IApplicationBuilder UseFiltroOrigenNodo(this IApplicationBuilder app, IReadOnlySet<IPAddress> ipNodos);
// GPOS.Web/Servicios/RechazoOrigenNodo.cs (nuevo; defensa en profundidad)
public static IApplicationBuilder UseRechazoOrigenNodo(this IApplicationBuilder app, IReadOnlySet<IPAddress> ipNodos);
```

| Regla | Contrato |
|---|---|
| Posición | **Primer** *middleware* de la API, antes de `app.UseForwardedHeaders()` (`Program.cs:349`); en la Web, antes de `Program.cs:101` |
| IP evaluada | `DireccionIp.Normalizar(ctx.Connection.RemoteIpAddress)`; nunca `X-Forwarded-For`. Si es `null` (canalización, `TestServer`), no se filtra |
| API, IP ∈ `IpNodos` | Solo pasa `ctx.Request.Path.StartsWithSegments("/api/sync", OrdinalIgnoreCase)`; `/api/syncx` no pasa. Lo demás → **403** |
| Web, IP ∈ `IpNodos` | **403** para todo: un nodo no tiene nada que hacer en el 443 (PT-05: el 443 no se abre a esa clase). Cubre un cortafuegos mal configurado |
| Otras clases | Sin filtro por ruta (PT-05) |
| `IpNodos` vacío | El *middleware* no hace nada (nodos de sucursal y sitio único) |
| Respuesta 403 de la API | `application/problem+json`: `{"title":"Origen no permitido","status":403,"codigo":"ORIGEN_NO_PERMITIDO"}`, `Cache-Control: no-store`, sin `detail` (no revela la regla) |
| Respuesta 403 de la Web | Texto plano corto, sin cuerpo HTML |
| Evento | API: 4750 (aviso) con IP, método y ruta truncada a 200 caracteres, **sin la consulta**. Web: 4751. Como mucho uno por IP cada 60 s, con el número de suprimidos. **No** se escribe en `BitacoraSeguridad`: ninguna petición anónima provoca escrituras en SQL (evita amplificar una denegación de servicio). Descartado: una fila por rechazo |

**Corrección de `LimitesPeticiones.Ip`** (`LimitesPeticiones.cs:178`):
`public static string Ip(HttpContext ctx) => DireccionIp.Normalizar(ctx.Connection.RemoteIpAddress)?.ToString() ?? "desconocida";`
Sigue leyendo la IP **después** de `UseForwardedHeaders` (los límites quieren la IP del usuario, no la de la Web): es correcto y no cambia. `AuthEndpoints` (zona T de DB-7) **no** se toca; adoptar `DireccionIp` allí queda para B (Q-10).

### 5.4 Errores

- **HTTP:** solo `403 ORIGEN_NO_PERMITIDO` (P3). Lo demás son fallos de arranque, que no producen respuesta HTTP.
- **SQL:** **ninguno**. Las piezas no tocan la base; no se usa ningún número, tampoco del 51618 al 51644.
- **Excepciones:** `ArranqueRedException` (arranque); `HttpRequestException` del `ConnectCallback` («destino no permitido»), que la Web trata como API no disponible (`/estado-api` → 503, `Program.cs:132-145`).

### 5.5 EventId (rango propuesto: 4743 a 4752; siguiente libre, 4753)

| Id | Nombre | Nivel | Quién | Cuándo |
|---|---|---|---|---|
| 4743 | `RedConfiguracionInvalida` | Crítico | API, Web | Valor del registro inválido, modo del entorno distinto, `Api:Url` distinto, `IpNodos` con prefijo amplio |
| 4744 | `RedFuenteEscuchaRechazada` | Crítico | API, Web | Una fuente de direcciones de 5.1, regla 1 |
| 4745 | `RedSinModo` | Aviso | API, Web | Arranque sin `ModoRed` (4.3) |
| 4746 | `RedDireccionNoPermitida` | Crítico | API, Web | Dirección efectiva fuera de lo armado |
| 4747 | `TlsCertificadoNoDisponible` | Crítico | API, Web | Al arrancar, sin certificado utilizable |
| 4748 | `TlsCertificadoNuevoNoUsable` | Crítico | API, Web | La huella nueva no es utilizable; se sigue con la anterior |
| 4749 | `TlsCertificadoCambiado` | Información | API, Web | El selector tomó la huella nueva |
| 4750 | `OrigenNodoRutaDenegada` | Aviso | API | 403 a un nodo fuera de `/api/sync/*` |
| 4751 | `WebOrigenNodoDenegado` | Aviso | Web | 403 a un nodo en el 443 |
| 4752 | (reservado) | — | — | Para una sola ampliación de estas piezas sin pedir rango |

- Se declaran como `public static readonly EventId X = new(n, "Nombre")` en `EventosRed`, que es el formato que reconoce `EventIdUnicosTests` (`tests/GPOS.Tests/Arquitectura/EventIdUnicosTests.cs:20-24`) [V].
- Antes de unir cada PR, `git grep` en todas las ramas de `origin` (regla de P-D1-01).
- Son eventos del registro de la aplicación, no de `EventosSeguridad`: no entran en la comprobación de catálogo del 4733 de DB-7.
- El origen en el Visor de eventos lo da `AddWindowsService` (N-1, B).

## 6. Interfaces entre módulos

- **Verbo `tls` → servicios:** solo por el registro (`HuellaApi`, `HuellaWeb`) y el almacén `LocalMachine\My`, en el orden de PT-02: emitir, dar lectura de la llave a `NT SERVICE\GPOS.Api|Web`, comprobar que la abre y **luego** publicar la huella. El servicio no avisa al verbo: el refresco de 5 minutos basta.
- **Paquete (B) → servicios:** `ModoRed`, `PuertoApi`, `PuertoWeb`, `NombresServidor` e `IpNodos` en el registro. Ningún valor en el entorno del servicio.
- **Web → API:** `https://<nombre>:<PuertoApi>` por *loopback* (5.2), con el mismo `ReenvioIpCliente` de hoy.

## 7. Estructura de proyectos y carpetas

```
src/GPOS.Comun/Red/{ModoRed,ConfiguracionRed,LecturaRed,IFuenteConfiguracionRed,FuenteRegistroWindows,DireccionIp,ValoresRegistroServidor}.cs
src/GPOS.Comun.Servidor/GPOS.Comun.Servidor.csproj          (net10.0; FrameworkReference Microsoft.AspNetCore.App; → GPOS.Comun)
src/GPOS.Comun.Servidor/Red/{EscuchaServidor,EstadoRed,ArranqueRedException,SelectorCertificadoServidor,
                              IAlmacenCertificadosServidor,AlmacenMaquinaWindows,ClienteApiLocal,EventosRed}.cs
src/GPOS.Api/Seguridad/FiltroOrigenNodo.cs
src/GPOS.Web/Servicios/RechazoOrigenNodo.cs
tests/GPOS.Tests/Red/…           (Comun, Comun.Servidor y el filtro de la API)
tests/GPOS.Web.Tests/Red/…       (manejador y rechazo de la Web)
```

**Puntos de toque en `src/GPOS.Api/Program.cs` (zona S de DB-7; RC-T4-3: unión después del 2026-11-16; A avisa a B antes de abrir el PR):**
1. Tras `:46`: `var red = EscuchaServidor.Preparar(builder, ServicioRed.Api);`
2. Tras `:339`: `EscuchaServidor.ExigirArranque(app, red);`
3. Antes de `:349`: `app.UseFiltroOrigenNodo(red.IpNodos);`
4. Un `using GPOS.Comun.Servidor.Red;` y la referencia en `GPOS.Api.csproj`.

**Todo lo demás se construye sin tocar `Program.cs` de la API:** las bibliotecas, `FiltroOrigenNodo.cs`, `LimitesPeticiones.cs:178`, `Program.cs` de la Web (zona U; DB-7 la ocupa desde el 11-23, `db7-blueprint-v3.md:788` [V]) y todas las pruebas. Las del filtro arman su propia canalización con `TestServer` y no usan `WebApplicationFactory<Program>`.

**Puntos de toque en `src/GPOS.Web/Program.cs`:** tras `:50`, `Preparar(builder, ServicioRed.Web)`. En `:62-67`, la URL de `DireccionApi` y `.ConfigurePrimaryHttpMessageHandler(() => ClienteApiLocal.CrearManejador(red))` con modo presente. Tras `:98`, `ExigirArranque`. Antes de `:101`, `UseRechazoOrigenNodo`.

## 8. División en PR (un PR por cláusula; RC-90-2)

| PR | Rama (base `feature/modelo-ng`) | Contenido | Toca `Program.cs` de la API | Se une | Depende de |
|---|---|---|---|---|---|
| **PR-1 · RT-01** | `a/adr90-rt01-modo-red` | `GPOS.Comun/Red`, proyecto `GPOS.Comun.Servidor` con `EscuchaServidor` (5.1), `EventosRed`, y la conexión en la **Web** | No | Cuando B la revise | — |
| **PR-2 · RT-05** | `a/adr90-rt05-escucha` | Puntos de escucha, selector y `ClienteApiLocal`; conexión en la Web | No | Tras PR-1 | PR-1; Q-8 para el laboratorio, no para unir |
| **PR-3 · RT-06** | `a/adr90-rt06-filtro-origen` | `FiltroOrigenNodo`, `RechazoOrigenNodo` (Web), `DireccionIp` en `LimitesPeticiones.Ip` | No | Tras PR-1 (puede ir en paralelo con PR-2) | PR-1 |
| **PR-4 · conexión en la API** | `a/adr90-api-program` | Las 4 líneas de la sección 7 | **Sí** | **Después del 2026-11-16**, con aviso previo a B | PR-1 a PR-3 |

- **Recomendada (a):** PR-1 a PR-3 se unen ya; en la API el código queda sin conectar hasta PR-4.
- **Descartada (b):** que cada PR lleve sus líneas de la API: los tres esperarían al 16-nov, con tres rebases sobre la zona S.
- Si B acepta adelantar PR-4 a antes del 2026-11-02 (la zona S de DB-7 empieza en S2, `db7-blueprint-v3.md:785` [V]), se ahorra un mes de código sin conectar (Q-6).
- Cada PR cita ADR-90, la cláusula y el PT, y pasa la suite oficial con el filtro vigente.

## 9. Pruebas

**PR-1**
- `FuenteRegistroWindows` con un doble de `IFuenteConfiguracionRed` y, en una prueba marcada solo para Windows, con una subclave temporal de `HKCU` (la fuente recibe la raíz inyectada).
- Tabla de valores válidos e inválidos de 4.1: puerto 0, 70000 o 5073; `NombresServidor[0]` igual a `localhost` o a una IP; `IpNodos` con `/24`; huella de 40 caracteres.
- Cada fuente de 5.1, regla 1, por configuración y por variable de entorno → 4744 y `ArranqueRedException`.
- `GPOS_MODO_RED` distinto, o sin registro → 4743.
- Direcciones efectivas, en tabla:
  - `UnEquipo`: `https://127.0.0.1:5071` sí; `https://[::]:5071` no; `http://localhost:5071` no.
  - `ServidorSitio`: `https://[::]:5071` sí; `http://[::]:80` no; `https://[::]:5072` no.
  - `SinModo`: `http://localhost:5071` sí; `http://0.0.0.0:5071` no.
- Arranque real de Kestrel en modo `SinModo` con `urls=http://0.0.0.0:0` → 4746 y código de salida ≠ 0.

**PR-2**
- Certificados ECDSA P-256 creados en la prueba (`CertificateRequest`) y un `IAlmacenCertificadosServidor` en memoria.
- Kestrel real en un puerto libre: el saludo TLS 1.2 y 1.3 entrega el certificado esperado; TLS 1.1 se rechaza; con `h2` y con HTTP/1.1, y WebSocket (Blazor) por HTTP/1.1.
- Con `FakeTimeProvider`: cambiar la huella → el saludo nuevo usa el certificado nuevo **después** del refresco de 5 min, no antes; 4749.
- Huella nueva sin llave privada, sin EKU `serverAuth` o vencida → se sirve la anterior; 4748 una sola vez por refresco.
- Al arrancar sin certificado → 4747, no arranca.
- `ClienteApiLocal`:
  - con un servidor en *loopback* y un certificado para `gpos-s01.prueba` (raíz de prueba por la sobrecarga interna), la petición a `https://gpos-s01.prueba:{p}` llega sin DNS;
  - un certificado para otro nombre → falla (sin relajar el nombre);
  - una URL con otro anfitrión o puerto → «destino no permitido».
- Prueba de arquitectura: ningún `RemoteCertificateValidationCallback` ni `DangerousAcceptAnyServerCertificateValidator` en `src/GPOS.Web` ni en `src/GPOS.Comun.Servidor`, fuera de la sobrecarga interna.

**PR-3**
- `TestServer` con un *middleware* de prueba que fija `RemoteIpAddress`, y `IpNodos = {10.9.0.5}`:
  - `GET /api/sync/x` desde `10.9.0.5` → no 403 (404, porque la ruta no existe);
  - `/api/auth/empresas` → 403 `ORIGEN_NO_PERMITIDO`;
  - `/API/SYNC/x` → pasa; `/api/syncx` → 403;
  - desde `::ffff:10.9.0.5` → 403;
  - desde `10.9.0.5` con `X-Forwarded-For: 127.0.0.1` → 403;
  - desde *loopback* con `X-Forwarded-For: 10.9.0.5` → **no** se filtra (es la Web; ver riesgo R-5);
  - 100 rechazos en 60 s → un solo 4750 con el número de suprimidos.
- Kestrel real: `/api/sync/../auth/empresas` llega normalizado y se rechaza [I: Kestrel quita los segmentos con punto; la prueba lo fija].
- `LimitesPeticiones.Ip` con `::ffff:192.168.1.10` → `192.168.1.10`.
- Web: un nodo en el 443 → 403 y 4751.

**PR-4**
- Suite oficial completa (sola, según la regla de B).
- Una prueba de humo de `WebApplicationFactory<Program>` en `SinModo` (entorno `Pruebas`) que arranca igual que hoy.
- **Riesgo R-4:** con la API en `[::]` y la Web conectando a `127.0.0.1`, la IP que ve `ForwardedHeaders` es `::ffff:127.0.0.1`. Hay que comprobar que `KnownProxies` la acepta y que los límites por IP siguen viendo la IP del usuario.

**Laboratorio (QA, con el paquete de B; no bloquea unir):** servicio con cuenta virtual, renovación con el reloj adelantado pasado el vencimiento (PT-02), actualización sin `MODO_RED` y con un modo distinto (PT-06), y el filtro con un nodo real por la VPN.

## 10. Esfuerzo (días-persona, ±50 %; 1 sp = 5 dp; USD 1.500 a 2.000 por sp)

| PR | dp | Nota |
|---|---|---|
| PR-1 · RT-01 | 1,0 | Incluye el proyecto nuevo |
| PR-2 · RT-05 | 1,5 | El selector y las pruebas con TLS real son lo más caro |
| PR-3 · RT-06 | 0,6 | |
| PR-4 · conexión en la API | 0,3 | Más una ejecución de la suite completa |
| **Total** | **3,4 dp (1,7 a 5,1), unas 0,68 sp, de USD 1.020 a 1.360** | |

ADR-90 estima para esta fila 0,45 sp, más ~0,02 de PT-01 y 0,05 a 0,10 de PT-05: de 2,6 a 2,9 dp. El exceso, de unos 0,5 dp, viene del proyecto nuevo y de las pruebas con TLS real; está dentro del ±50 %. **Opción más barata:** dejar la Web sin `RechazoOrigenNodo` (−0,1 dp), aceptando que la protección del 443 frente a un nodo dependa solo del cortafuegos. No la recomiendo: es la única defensa si la regla del 443 queda mal configurada. **H-15** (cookies `Secure` y `AllowedHosts` desde `NombresServidor`) cabe en 0,1 dp sobre PR-2 si B lo quiere en la misma tanda.

## 11. Riesgos de seguridad

| # | Riesgo | Prob. / impacto | Mitigación en el contrato | Residual |
|---|---|---|---|---|
| R-1 | Una fuente de direcciones no prevista abre un puerto | Baja / Alto | Lista de 5.1 (incluye `preferHostingUrls`) **y** comprobación de direcciones efectivas (4746), que cubre lo que la lista no vea | Bajo |
| R-2 | El selector bloquea o encarece los saludos (E/S en el hilo de TLS) | Media sin caché / Medio | Refresco por temporizador; el saludo solo lee una referencia; contexto con `offline: true` | Bajo [I, a medir] |
| R-3 | La renovación publica una huella cuya llave el servicio no abre | Media / Alto | Orden de PT-02 en el verbo; el selector conserva el anterior y avisa con 4748 | Bajo |
| R-4 | `ForwardedHeaders` no reconoce `::ffff:127.0.0.1` como proxy conocido y todos los usuarios de la Web comparten un cupo por IP (inicio de sesión) | Media / Medio | Prueba en PR-4; si falla, se agregan `::ffff:127.0.0.1` a `KnownProxies` o se escucha la API con sockets separados para IPv4 e IPv6 | Bajo tras la prueba [I] |
| R-5 | Un nodo llega a la API completa a través de la Web (443) si el cortafuegos queda mal | Baja / Medio | `RechazoOrigenNodo` en la Web; y el acceso a datos exige un token de persona de la central (ADR-53) | Bajo |
| R-6 | Eludir el filtro con trucos de ruta (`%2F`, `..`, mayúsculas) | Baja / Medio | `StartsWithSegments` sobre la ruta ya normalizada por Kestrel; pruebas de PR-3 | Bajo |
| R-7 | Inundación del Visor de eventos con 403 | Media / Bajo | Un evento por IP cada 60 s; sin escrituras en SQL | Bajo |
| R-8 | `SinModo` (a) rompe un DEMO usado desde otra PC; (b) deja una instalación sin falla cerrada si se borra el registro | Media / Bajo | Q-3; (b) solo hasta la primera instalación de cliente | Bajo |
| R-9 | Un administrador local cambia el registro (modo, `IpNodos` vacío) | Baja / Alto | ACL de B (solo Administradores y SYSTEM); un administrador ya controla el equipo | Medio, aceptado (como H-13) |
| R-10 | Bucle de reinicios del servicio tras una falla cerrada, con eventos críticos repetidos | Media / Bajo | Código de salida ≠ 0; las acciones de recuperación del servicio las define B (Q-4) | Bajo |
| R-11 | La Web confía en cualquier raíz del almacén del servidor para hablar con la API | Baja / Medio | El tráfico no sale del equipo (`ConnectCallback` a *loopback*); para suplantar a la API hace falta un proceso local en ese puerto **y** un certificado válido para el nombre | Bajo |

## 12. Preguntas para B

1. **Q-1 · Registro.** ¿Aceptas los nombres, tipos y dominios de 4.1, incluido `PuertoWeb` opcional para la excepción del 443? ¿El paso del *bundle* que escribe el registro es el mismo que crea la ACL?
2. **Q-2 · `Api:Url`.** ¿Te sirve que la Web derive la URL del registro (recomendada), o prefieres que el MSI escriba `Api:Url`? Con esa opción hay que añadir `Api` a `SeccionesPermitidas` y comprobar que coincide con el registro.
3. **Q-3 · DEMO.** ¿El DEMO o alguna prueba de C abre hoy la Web o la API desde otra PC? Decide entre (a) y (b) de 4.3.
4. **Q-4 · Recuperación del servicio.** ¿Qué acciones de recuperación pondrá el MSI (reiniciar, cuántas veces)? Afecta a R-10.
5. **Q-5 · EventId.** ¿Reservas 4743 a 4752 para estas piezas? ¿Tienes en tu árbol, sin publicar, algo del 47xx? ¿Pongo `EventId` también al crítico de la API de reportes (`ServiciosReportes.cs:176`), o lo haces en el tramo 4?
6. **Q-6 · Ventana de `Program.cs` de la API.** ¿PR-4 (4 líneas) espera al 16-nov (RC-T4-3), o puede unirse antes del 2-nov, cuando aún no empieza la zona S de D1?
7. **Q-7 · Nodos.** En un nodo de sucursal, ¿el *bundle* deja `IpNodos` vacío o sin crear? Las dos formas valen.
8. **Q-8 · CA en el servidor.** ¿El paso `tls` del *bundle* instala la CA del sitio en `LocalMachine\Root` del propio servidor? Es necesario para que la Web valide a la API con el sistema y para el navegador del servidor. El verbo es de A; el orden en la cadena es de B.
9. **Q-9 · Proyecto nuevo.** `GPOS.Comun.Servidor.dll` entra en los MSI de la API y de la Web. ¿La recolección de archivos lo toma sola, o hay que listarlo?
10. **Q-10 · DB-7.** `LimitesPeticiones.Ip` normalizado cambia la clave «(cuenta, IP)» que usa D1 (`db7-blueprint-v3.md:631`) solo para clientes IPv4 sobre doble pila. ¿Esa clave se persiste? Si se persiste, ¿conviene que D1 adopte `DireccionIp.Normalizar` en `AuthEndpoints` (zona T) al mismo tiempo?

## 13. Necesidades para Datos e Integraciones

- **Datos:** ninguna; no hay tablas, migraciones ni errores SQL.
- **Integraciones:** ninguna; la credencial del nodo con audiencia `/api/sync/*` (PT-05, punto 5) va con el diseño de la sincronización (entrega 2).

## 14. Decisiones candidatas a precisión (no ADR nuevo)

- **Estado `SinModo`** (4.3): opción (a) o (b). Es la única que cambia qué ve alguien (el DEMO); el Arquitecto Maestro decide si va a firma.
- **URL de la Web derivada del registro** (5.2) frente a `Api:Url` escrito por el MSI (H-09 dice «lo escribe el MSI»).
- **Huella SHA-256** del DER en lugar de la de SHA-1 de Windows. Afecta al verbo `tls`.
- **Proyecto `GPOS.Comun.Servidor`** (2).

## Resumen (10 líneas)

1. ADR-90, la hoja de PT-01 a PT-10 y la revisión de seguridad están en `origin/master` y no en `feature/modelo-ng`. Todo está firmado y sin construir.
2. Única fuente: `HKLM\SOFTWARE\GPOS NG\Servidor`, con `ModoRed`, `PuertoApi`, `PuertoWeb`, `NombresServidor`, `HuellaApi`, `HuellaWeb` e `IpNodos`. Sin registro rige `SinModo` (solo *loopback*).
3. RT-01: se rechazan `urls`, `*_PORTS`, `preferHostingUrls` y `Kestrel:Endpoints/Certificates`, y se comprueban las direcciones efectivas, con falla cerrada.
4. RT-05: HTTPS sin puerto 80. «Un equipo» escucha en `ListenLocalhost` y «servidor de sitio» en `ListenAnyIP`; TLS 1.2 y 1.3 con `TlsHandshakeCallbackOptions`.
5. Selector por huella SHA-256 refrescado cada 5 min fuera del saludo. Si la huella nueva no sirve, sigue con la anterior y avisa (4748).
6. La Web llama a `https://<NombresServidor[0]>:<PuertoApi>` con `ConnectCallback` a *loopback*, valida con el sistema y no tiene validador propio.
7. RT-06: filtro por la IP de la conexión normalizada, antes de `UseForwardedHeaders`. Un nodo solo llega a `/api/sync/*` (403 `ORIGEN_NO_PERMITIDO`), y la Web lo rechaza en el 443.
8. EventId del 4743 al 4752 (el 4742 ya lo usa el PR #103). Ningún error SQL.
9. Cuatro PR. Los de RT-01, RT-05 y RT-06 no tocan `Program.cs` de la API; las 4 líneas de la API van en PR-4, después del 16-nov (RC-T4-3), salvo que B lo adelante.
10. Esfuerzo: 3,4 dp (de 1,7 a 5,1), de USD 1.020 a 1.360. Hay 10 preguntas abiertas para B; las principales son el DEMO (`SinModo`), `Api:Url`, la CA en el servidor y la ventana de PR-4.
