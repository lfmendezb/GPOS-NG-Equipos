# Blueprint técnico (contratos primero): ADR-90, RT-01, escucha de RT-05 y reglas de RT-06 en la aplicación · v2

- **Fecha:** 2026-10-20 (v1 y v2) · **Autor:** arquitecto-software del equipo A · **Estado:** propuesta de contratos, corregida con las respuestas de B. Lo que pide firma (F-1, F-5, F-6) sigue **Pendiente de firma** del propietario.
- **Alcance:** solo lo que A construye en `GPOS.Api` y `GPOS.Web`. No diseña el paquete único, el verbo `red`, la ACL del registro, las reglas del cortafuegos ni la tarea de renovación (son de B), ni el verbo `GPOS.Migracion tls` (de A, en otro blueprint).
- **Convención:** [V] = verificado con `git show`/`git grep` (cita `archivo:línea`); [I] = inferido. Código leído en `origin/feature/modelo-ng` @ `b8f166db` (base de las ramas `a/`); documentos en `origin/master` @ `e01784a9` (v1 usó `45a9ab75`; ADR-090 no cambió entre los dos, y las líneas de la hoja del tramo 4 que se citan aquí se volvieron a comprobar). No se compiló ni se ejecutó nada.
- **Respuestas de B que aplica esta v2:** `GPOS-NG-Equipos/traspasos/B/2026-10-20-respuestas-b-a-los-planos-de-a.md` (en adelante **RB**) y el aviso `avisos/B-a-A/2026-10-20-encargo-tareas-y-respuestas-a-los-planos.md` (**AV**).

## Registro de cambios

| Versión | Cambio | Punto de B que lo pide |
|---|---|---|
| v2 | `FuenteRegistroWindows.cs` pasa a `FuenteConfiguracionRed.Windows.cs` y `AlmacenMaquinaWindows.cs` a `AlmacenCertificadosServidor.Windows.cs` (convención de ADR-129, B.3 y B.5) | HB-03; AV punto 4 |
| v2 | Fuera de Windows ya no se devuelve `SinModo`: con Estricto, falla cerrada (ADR-129, B.2); sin Estricto, el mismo «sin modo» que en Windows | HB-03; RB Q-3 de 1.2 |
| v2 | «Sin modo» se admite **solo si el modo de identidad no es Estricto**; con Estricto y sin `ModoRed`, 4743 y no arranca. Se elimina la opción (b) de 4.3 | HB-04; RB Q-3 de 1.2 |
| v2 | `IpNodos` lo escribe siempre el paquete (vacío en nodos y sitio único); en «servidor de sitio», si **falta**, 4743 (antes: «lista vacía») | HB-05; RB Q-1 punto 1 y Q-7 de 1.2 |
| v2 | Escritor único del registro: el verbo `red` de `GPOS.Migracion` (B), que crea la clave con su DACL; los MSI solo leen. Se suman `Version`, `FechaInstalacion` y `RegistroInstalacion` (los escribe el paso 9) | HB-08; RB Q-1 puntos 2 y 3 |
| v2 | RT-01 sin proyecto nuevo: **PR-1a** solo en `GPOS.Comun/Red`; `GPOS.Comun.Servidor` solo en **PR-1b**, tras la firma de F-1 | HB-02; RB F-1 y 4.1; AV «Ya» punto 2 |
| v2 | Reparto de PR: PR-3 antes del 2026-11-09; PR-2 después; PR-4 tras el PR de N-1 de B y la firma de F-5 (ventana 10-28 a 11-06; si no, después del 11-20). Hasta entonces no se toca `src/GPOS.Api/Program.cs` | HB-09, HB-14; RB 4.1 y 4.2; AV «Cuando B o el propietario respondan» |
| v2 | EventId 4743 a 4752 confirmados para estas piezas (franja de A en la tabla de RB Q-8 de 1.1). El crítico de la API de reportes lo hace B con el 5119 | RB Q-5 de 1.2; Q-8 de 1.1 |
| v2 | `Api:Url` y `AllowedHosts` se derivan del registro en el código (pendiente de confirmación en F-6); H-15 entra en PR-2 | RB Q-2 de 1.2; F-6 (i) |
| v2 | El verbo `tls` instala la CA del sitio en `LocalMachine\Root` del servidor (paso 6 de la cadena, después de los MSI) | RB Q-8 de 1.2; F-6 (ii) |
| v2 | Recuperación del servicio: como la estación, más `FailureActionsWhen`; R-10 queda Bajo | RB Q-4 de 1.2; HB-15 |
| v2 | La clave (cuenta, IP) es de D2 y vive en memoria; PR-3 agrega la prueba del freno de emparejamiento con IPv4 mapeada | HB-10; RB Q-10 de 1.2 |
| v2 | R-4 probablemente lo cubre el marco; se conserva la prueba en PR-4 | HB-11 |
| v2 | Las preguntas Q-1 a Q-10 pasan a la sección 12 como «respondidas» | RB 1.2 |

## 0. Fuentes y estado

| Fuente | Estado [V] |
|---|---|
| `docs/adr/ADR-090.md` | En `origin/master` (no en `origin/feature/modelo-ng`). RT-01 `:25-33`, RT-05 `:60-70`, RT-06 `:71-79`, «Impacto en el paquete único» `:137`, PT-01 `:236`, PT-02 `:237`, PT-05 `:240`, PT-06 `:241`, H-15 `:251` |
| `docs/decisiones/2026-10-20-hoja-firma-precisiones-adr090.md` | En `origin/master`. Firmada PT-01 a PT-10 (`:5`). Qué se puede construir ya: `:280-290` |
| `docs/seguridad/2026-10-20-revision-adr090-red-tls.md` | En `origin/master`. H-01, H-02, H-07 y H-08 (`:65-110`) |
| `docs/decisiones/2026-10-20-hoja-firma-ola5-tramo4-e-instalador.md` | En `origin/master`. **RC-T4-3** (`:72`): lo que toque `src/GPOS.Api/Program.cs` se une **después del 2026-11-16**; la zona S está congelada del 11-11 al 11-13. F-5 propone adelantar PR-4 (sección 8) |
| `docs/adr/ADR-129.md` | B.2 falla cerrada sin implementación para la plataforma (`:31`); B.3 sin proyectos nuevos y archivos `*.Windows.cs` / `*.Linux.cs` (`:32`); B.5 vigilancia con CA1416 y prueba de arquitectura (`:34`) |
| RB | Respuestas de B; F-1, F-5 y F-6 **Pendientes de firma**; el resto, decisiones técnicas de B |

**Hechos del código que fijan el diseño**
- La API no arma su escucha: solo aplica límites a Kestrel con `GPOS:Servidor` (`src/GPOS.Api/Program.cs:45-46`) [V]. `UseHttps`, `Listen*` y `AddWindowsService` no aparecen en `GPOS.Api` [V; `AddWindowsService` solo está en `src/GPOS.Reportes.Api/Program.cs:24` y `src/GPOS.AgenteImpresion/Estacion/ModoEstacion.cs:17`; el registro como servicio de la API es N-1, de B].
- `ForwardedHeaders` confía en `X-Forwarded-For` de *loopback* y de `ProxiesConfiables` (`Program.cs:49-54`) y lo aplica en `app.UseForwardedHeaders()` (`Program.cs:349`), primer *middleware* de la canalización [V].
- `LimitesPeticiones.Ip` no normaliza IPv4 mapeada (`src/GPOS.Api/Seguridad/LimitesPeticiones.cs:178`) [V]; `AuthEndpoints` sí lo hace en tres sitios (`src/GPOS.Api/Endpoints/AuthEndpoints.cs:212`, `:257`, `:283`) [V].
- La Web toma `Api:Url` (`src/GPOS.Web/Program.cs:62-67`), con valor por omisión `http://localhost:5071/` (`src/GPOS.Web/appsettings.json:14`), `AllowedHosts: "*"` (`:9`), y agrega `ReenvioIpCliente` a su único `HttpClient` (`Program.cs:59`, `:67`) [V]. Usa HSTS y `UseHttpsRedirection` fuera de `Development` (`Program.cs:103-109`) [V].
- Patrón a reutilizar: la API de reportes rechaza `Kestrel:Endpoints` (`src/GPOS.Reportes.Api/Endpoints/ServiciosReportes.cs:83-85`), valida sus direcciones (`:143-151`) y comprueba las enlazadas de verdad con `IServerAddressesFeature` en `ApplicationStarted` (`:170-179`) [V].
- **Modo Estricto:** la API lo lee con `ComprobacionAnillo.EsEstricto(IConfiguration)` sobre `GPOS:Seguridad:ModoIdentidad` (`src/GPOS.Core/Infraestructura/Anillo/ComprobacionAnillo.cs:47-51`) y la Web con `ProteccionDatosWeb.EsEstricto` (`src/GPOS.Web/Servicios/ProteccionDatosWeb.cs:35` y `:50`) [V]. La Web no referencia `GPOS.Core` (`src/GPOS.Web/GPOS.Web.csproj:4-16`) [V], así que `GPOS.Comun` **no** lee el modo: lo recibe como parámetro (5.1).
- `GPOS.Comun` no tiene referencia a ASP.NET Core, pero sí a `Microsoft.Extensions.Logging.Abstractions` y a `Microsoft.Extensions.Configuration.Json` (`src/GPOS.Comun/GPOS.Comun.csproj`) [V]. Por eso `EventosRed` y la evaluación de RT-01 caben en `GPOS.Comun/Red` sin proyecto nuevo (PR-1a). Lo usan `GPOS.Api`, `GPOS.Web`, `GPOS.Migracion`, `GPOS.Reportes` y `GPOS.Reportes.Api` [V].
- Ya hay lectura de `HKLM` con `Registry.LocalMachine` en el agente (`src/GPOS.AgenteImpresion/ConfiguracionAgente.cs:13-19`) [V]. En `src` no existe todavía ningún archivo `*.Windows.cs` ni `*.Linux.cs` [V, `git ls-tree` en `feature/modelo-ng` y `master`]: estas piezas serán las primeras con la convención.
- **EventId:** el 4742 ya está tomado por `ModuloVenceIgnorado` del PR #103 (`origin/a/dv07-formato-licencia:src/GPOS.Core/Sistema/Licencia/EstadoLicenciaService.cs:145`) [V]. Del 4743 al 4799 no aparece ningún número en `src/*.cs` de las 162 referencias de `origin` [V, `git grep` del 2026-10-20].

## 1. Contexto y alcance

| Pieza | Cláusula y precisión | Qué cubre aquí |
|---|---|---|
| **P1** | RT-01 + PT-06 | Modo leído **solo** del registro; falla cerrada (también «sin modo» con Estricto y fuera de Windows con Estricto); rechazo de todas las fuentes de direcciones; comprobación de las direcciones efectivas |
| **P2** | RT-05 + PT-01 + PT-02 | Escucha armada en código por modo; selector de certificado por huella del registro con caché de 5 min; URL de la Web hacia la API por el nombre del sitio con la conexión TCP a *loopback* (`ConnectCallback`); `Api:Url` y `AllowedHosts` derivados (H-09, H-15; F-6 (i)) |
| **P3** | RT-06 + PT-05 (punto 4) | Filtro sobre la IP de la conexión, **antes** de `UseForwardedHeaders`, para la clase «nodos»; normalización de IPv4 mapeada; corrección de `LimitesPeticiones.Ip` |

**Fuera de alcance:** la credencial del nodo con audiencia exclusiva de `/api/sync/*` (PT-05, punto 5; entrega 2); el verbo `tls` (incluida la CA en `LocalMachine\Root`, RB Q-8); el verbo `red` y todo lo del paquete (B); el crítico de la API de reportes (B, 5119; RB Q-5 de 1.2).

## 2. Módulos y dependencias

```
GPOS.Comun (sin ASP.NET) — PR-1a, sin proyecto nuevo          GPOS.Comun.Servidor (nuevo; FrameworkReference Microsoft.AspNetCore.App)
  Red/ModoRed, ConfiguracionRed, LecturaRed                       — solo PR-1b y PR-2, tras la firma de F-1
  Red/IFuenteConfiguracionRed, FuenteConfiguracionRed (fábrica)     Red/EscuchaServidor   (Kestrel, ApplicationStarted)
  Red/FuenteConfiguracionRed.Windows.cs                             Red/SelectorCertificadoServidor (TLS, caché)
  Red/DireccionIp (normalizar, /32)                                 Red/IAlmacenCertificadosServidor
  Red/ValoresRegistroServidor (nombres)                             Red/AlmacenCertificadosServidor.Windows.cs
  Red/EvaluacionArranqueRed (reglas puras de RT-01)                 Red/ClienteApiLocal   (SocketsHttpHandler + ConnectCallback)
  Red/EventosRed (EventId 4743-4752)                                    ^            ^
        ^      ^                                                        |            |
        |      +---------- GPOS.Migracion (verbos red y tls: solo nombres de valores)
        |                                                               |            |
     GPOS.Api --------------------------------------------------------+        GPOS.Web
       Seguridad/FiltroOrigenNodo (nuevo; PR-3)                             Servicios/RechazoOrigenNodo (nuevo; PR-3)
```

- Sin ciclos: `GPOS.Comun.Servidor → GPOS.Comun`; `GPOS.Api` y `GPOS.Web → GPOS.Comun.Servidor` (desde PR-1b) y `→ GPOS.Comun` (ya existe).
- **PR-1a no necesita proyecto nuevo (HB-02).** Todo lo que no usa tipos de ASP.NET (`WebApplicationBuilder`, `ListenOptions`, `IServerAddressesFeature`) se mueve a `GPOS.Comun/Red`: tipos, fuente, validación de la tabla 4.1 y **las reglas de RT-01 como función pura** (`EvaluacionArranqueRed`), que reciben listas de claves y de direcciones como texto. `GPOS.Comun.Servidor` queda reducido a la conexión con Kestrel (PR-1b) y al TLS (PR-2).
- **`GPOS.Comun.Servidor` exige la firma de F-1** (excepción a la regla de proyectos nuevos de `CLAUDE.md` y de ADR-129, B.3, `docs/adr/ADR-129.md:32` [V]). *Alternativa (F-1 b), si el propietario no exceptúa la biblioteca:* las piezas de Kestrel de PR-1b y PR-2 se comparten entre la API y la Web con archivos vinculados (`Compile Include … Link`), como el anillo en la Web (`src/GPOS.Web/GPOS.Web.csproj:14-16`) [V]. Costo: unos +0,3 dp de pruebas y una prueba de arquitectura que compare los vínculos [I]. Los contratos de la sección 5 no cambian; solo cambia el ensamblado que los contiene.
- **Descartado:** `FrameworkReference` de ASP.NET en `GPOS.Comun`, porque lo arrastraría a `GPOS.Migracion` y a `GPOS.Reportes`.
- El filtro de P3 vive en `GPOS.Api/Seguridad/FiltroOrigenNodo.cs`, archivo nuevo **fuera** de la zona S de DB-7 (zona S = `Seguridad.cs`, `Program.cs`, `PermisosServidor.cs`, `RevocacionSesiones.cs`, `ValidacionAcceso`; `docs/arquitectura/2026-10-18-db7-blueprint-v3.md:776` [V]). `GPOS.Api` ya tiene ASP.NET por `GPOS.Core` (`src/GPOS.Core/GPOS.Core.csproj:11`) [V], así que PR-3 **no** depende de `GPOS.Comun.Servidor`.

## 3. C4

No aplica en nivel de contexto ni de contenedores: los contenedores (`GPOS.Web`, `GPOS.Api`, API de reportes y agente) ya están en ADR-90 y no cambian. Componentes: el diagrama de la sección 2 basta.

## 4. Modelo de dominio (contratos de configuración)

### 4.1 Registro: `HKLM\SOFTWARE\GPOS NG\Servidor` (vista de 64 bits, `RegistryView.Registry64`)

Única fuente del modo, de los puertos, de los nombres, de `IpNodos` y de la huella (PT-06, PT-02). El servicio **no** lee estos valores del entorno ni de `appsettings`.

- **Escritor único: el verbo `red` de `GPOS.Migracion` (B)**, paso 2 de la cadena, **antes** de los MSI. El mismo paso crea la clave con DACL protegida: SYSTEM y Administradores con control total; Usuarios autenticados con lectura (ningún valor es secreto). Los MSI solo leen (`RegistrySearch` para su regla de cortafuegos). El verbo `tls` (A) escribe solo `HuellaApi` y `HuellaWeb` (RB Q-1 de 1.2, HB-08).

| Valor | Tipo | Dominio | Lo escribe | Lo lee | Si falta | Si es inválido |
|---|---|---|---|---|---|---|
| `ModoRed` | `REG_SZ` | `UnEquipo` o `ServidorSitio` (comparación ordinal exacta) | verbo `red` (B) | API, Web | Sin Estricto: **sin modo** (4.3). Con Estricto: **4743, no arranca** | 4743, no arranca |
| `PuertoApi` | `REG_DWORD` | 1024–65535; distinto de `PuertoWeb`, de 5073 (reportes) y de 17654 (agente) | verbo `red` (5071 si el técnico no da `PUERTO_API`) | API, Web | con `ModoRed`: 4743 | 4743 |
| `PuertoWeb` | `REG_DWORD` | 1–65535 | verbo `red`, **solo** en la excepción del 443 ocupado (riesgos de ADR-90) | Web | 443 | 4743 |
| `NombresServidor` | `REG_MULTI_SZ` | 1 a 16 nombres; el **primero** es un nombre DNS (no IP) y no es `localhost`; sin `.local` (PT-03) | verbo `red`, desde `NOMBRES_SERVIDOR` | Web (URL de la API y `AllowedHosts`) | `ServidorSitio`: 4743. `UnEquipo`: no se usa | 4743 |
| `HuellaApi`, `HuellaWeb` | `REG_SZ` | 64 caracteres hexadecimales en mayúsculas: SHA-256 del DER del certificado | verbo `tls` (A), en el orden de PT-02 | API / Web | con `ModoRed`: 4747, no arranca | 4743 |
| `IpNodos` | `REG_MULTI_SZ` | IP literal, con o sin `/32` o `/128`; cualquier otro prefijo es inválido. **El paquete lo escribe siempre**, vacío en los nodos de sucursal y en un sitio único | verbo `red`, desde `IP_NODOS` | API, Web | `ServidorSitio`: **4743, no arranca** (falla cerrada; HB-05). `UnEquipo`: no se lee | 4743, no arranca |
| `Version`, `FechaInstalacion`, `RegistroInstalacion` | `REG_SZ` | Los del paquete (INS:68) | paso 9 `verificar` (B), al terminar bien | lado elevado de N-10; `comprobar-servidor` | No afecta al arranque de la API ni de la Web | No afecta |

- **Lista vacía frente a valor ausente:** un `REG_MULTI_SZ` presente y vacío es un conjunto vacío válido (el filtro no hace nada). Un valor ausente en «servidor de sitio» es una instalación incompleta o manipulada: **no** se interpreta como vacío.
- `SUBREDES_PUESTOS` y `SUBREDES_REMOTOS` (PT-05) **no** los lee la aplicación en la v1: sirven solo al cortafuegos. **Descartado:** clasificar las tres clases en la API desde ya; PT-05 solo ordena filtrar por ruta a los nodos (C13.5).
- **Huella SHA-256 y no la «huella» SHA-1 de Windows:** `X509Store.Find(FindByThumbprint)` usa SHA-1; se busca recorriendo `LocalMachine\My` y comparando `GetCertHash(HashAlgorithmName.SHA256)`. Son pocos certificados [I]. Evita depender de SHA-1 en Avanzada.
- Los nombres de los valores son constantes en `GPOS.Comun/Red/ValoresRegistroServidor.cs`, compartidas con los verbos `red` (B) y `tls` (A).

### 4.2 Tipos (en `GPOS.Comun/Red`; PR-1a)

```csharp
public enum ModoRed { UnEquipo = 1, ServidorSitio = 2 }
public enum ServicioRed { Api, Web }

public sealed record ConfiguracionRed(
    ModoRed Modo, int PuertoApi, int PuertoWeb, IReadOnlyList<string> NombresServidor,
    string? HuellaApi, string? HuellaWeb, IReadOnlySet<IPAddress> IpNodos);   // IpNodos ya normalizadas

public abstract record LecturaRed
{
    public sealed record SinModo : LecturaRed;                                  // ModoRed ausente (solo se admite sin Estricto)
    public sealed record SinFuente : LecturaRed;                                // la plataforma no tiene fuente (fuera de Windows, hoy)
    public sealed record Valida(ConfiguracionRed Red) : LecturaRed;
    public sealed record Invalida(string Valor, string Motivo) : LecturaRed;    // Motivo sin datos sensibles (incluye IpNodos ausente en ServidorSitio)
}

public interface IFuenteConfiguracionRed { LecturaRed Leer(); }               // también la usa el refresco del selector

// FuenteConfiguracionRed.cs (neutro): fábrica. En Windows devuelve la implementación de abajo; en otra plataforma, una fuente que
// devuelve SinFuente. La decisión de arrancar o no la toma EvaluacionArranqueRed con el modo Estricto (5.1).
public static class FuenteConfiguracionRed { public static IFuenteConfiguracionRed Crear(); }

// FuenteConfiguracionRed.Windows.cs (ADR-129, B.3 y B.5: único archivo de estas piezas que usa Microsoft.Win32.Registry)
[SupportedOSPlatform("windows")] internal sealed class FuenteConfiguracionRedWindows : IFuenteConfiguracionRed { … }

public static class DireccionIp
{
    public static IPAddress? Normalizar(IPAddress? d);   // IPv4 mapeada → IPv4; IPv6 sin ScopeId
    public static bool TryParseHost(string texto, out IPAddress ip);   // acepta "a.b.c.d", "a.b.c.d/32", "x::y", "x::y/128"
}
```

**Fuera de Windows (ADR-129, B.2; HB-03):** no hay fuente todavía (la de Linux es de la fase LN). La fábrica devuelve `SinFuente`, y la evaluación la trata igual que `SinModo`: **con Estricto, 4743 y no arranca**; sin Estricto, el «sin modo» de 4.3 (solo *loopback*). **Se descarta** lo que decía la v1 («en Linux la fábrica devuelve `SinModo`» sin condición), porque dejaba arrancar una instalación Estricta sin falla cerrada.

### 4.3 Estado «sin modo» (registro ausente) — **solo sin Estricto** (HB-04; RB Q-3 de 1.2)

No es un tercer modo instalable: el paquete exige `MODO_RED` en la primera instalación (PT-06) e impone Estricto (INS B-11), así que «sin modo» solo se da en desarrollo, en las pruebas y en el DEMO que todavía no usa el paquete.

| Modo de identidad | `ModoRed` ausente (o `SinFuente`) |
|---|---|
| **Estricto** (`GPOS:Seguridad:ModoIdentidad = Estricto`) | **4743 y no arranca.** Es la falla cerrada de RT-01 y PT-06: una instalación de cliente a la que le borren el registro no arranca en *loopback* con HTTP |
| **No Estricto** (desarrollo, pruebas, DEMO) | Se conserva la configuración actual (`urls`, `launchSettings`, `Api:Url`), pero **toda dirección efectiva debe ser de *loopback*** (cualquier esquema; A5 admite HTTP en *loopback*). Si no, 4746 y se detiene. Cada arranque deja el 4745 (aviso) |

- **Por qué no rompe nada hoy [V, según RB Q-3]:** el DEMO escucha solo en `localhost` (`instalador/Demo/scripts/herramientas/Comun-Demo.ps1:344` y `:374`), igual que `launchSettings` de la API y de la Web, el ensayo de implantación y las pruebas con Kestrel (`127.0.0.1`).
- **Cuando el DEMO adopte el paquete (A-5):** usará «un equipo», y devops quitará `ASPNETCORE_URLS` de sus guiones, porque con el modo presente es una fuente rechazada (regla 1 de 5.1).
- **Descartadas:** (b) de la v1 (sin comprobar direcciones), porque deja sin falla cerrada una instalación a la que se le borre el registro; (c) no arrancar nunca sin registro, porque rompe el desarrollo, las pruebas y el DEMO hasta A-5.
- **Residual:** el modo Estricto sale de la configuración (`ComprobacionAnillo.cs:47`) [V], que en una instalación solo puede escribir un administrador [I]. Quitar a la vez el registro y Estricto exige ser administrador, igual que R-9.

## 5. Contratos

### 5.1 P1 · RT-01: arranque con falla cerrada

**Reglas puras (PR-1a, `GPOS.Comun/Red/EvaluacionArranqueRed.cs`):**

```csharp
public static class EvaluacionArranqueRed
{
    // Antes de Build. No lanza: devuelve el resultado para registrarlo con el logger real.
    // estricto: lo calcula el llamador (API: ComprobacionAnillo.EsEstricto; Web: ProteccionDatosWeb.EsEstricto).
    // clavesConfiguracion / variablesEntorno: nombres presentes (y el valor de preferHostingUrls), no sus valores.
    public static ResultadoArranqueRed Evaluar(ServicioRed servicio, LecturaRed lectura, bool estricto,
        IReadOnlyDictionary<string, string?> clavesConfiguracion, IReadOnlyDictionary<string, string?> variablesEntorno,
        string? apiUrlConfigurada);

    // En ApplicationStarted: direcciones efectivas como texto (IServerAddressesFeature.Addresses).
    public static ResultadoDirecciones ComprobarDirecciones(ResultadoArranqueRed arranque, IEnumerable<string> direccionesEfectivas);
}
public sealed record ResultadoArranqueRed(bool PuedeArrancar, EventId? Evento, string? Motivo, ConfiguracionRed? Red, bool SinModo)
{ public IReadOnlySet<IPAddress> IpNodos { get; } /* vacío en SinModo */ }
```

**Conexión con Kestrel (PR-1b, tras F-1; `GPOS.Comun.Servidor/Red/EscuchaServidor.cs`):**

```csharp
public static class EscuchaServidor
{
    // Antes de Build: lee la fuente, llama a Evaluar y arma ConfigureKestrel (P2, desde PR-2).
    public static EstadoRed Preparar(WebApplicationBuilder builder, ServicioRed servicio, bool estricto, IFuenteConfiguracionRed? fuente = null);

    // Después de Build y antes de Run: registra 4743/4744/4747 y lanza ArranqueRedException (el proceso termina con código ≠ 0);
    // en SinModo registra 4745; engancha ComprobarDirecciones (4746) a ApplicationStarted.
    public static void ExigirArranque(WebApplication app, EstadoRed estado);
}
public sealed class ArranqueRedException : Exception { … }   // mensaje sin rutas ni valores sensibles
```

**Reglas** (con `ModoRed` presente; en «sin modo» —solo sin Estricto— rigen únicamente la 4 y la comprobación de *loopback* de 4.3):
0. **Lectura y modo:** `SinModo` o `SinFuente` con Estricto → 4743, no arranca. `Invalida` → 4743, no arranca (incluye `IpNodos` ausente en «servidor de sitio»).
1. **Fuentes de direcciones rechazadas** (4744): en la configuración, `urls`, `http_ports`, `https_ports`, `preferHostingUrls` (si es `true`), y cualquier hijo de `Kestrel:Endpoints` o de `Kestrel:Certificates`; en el entorno del proceso, `ASPNETCORE_URLS`, `DOTNET_URLS`, `ASPNETCORE_HTTP_PORTS`, `DOTNET_HTTP_PORTS`, `ASPNETCORE_HTTPS_PORTS`, `DOTNET_HTTPS_PORTS`, `ASPNETCORE_PREFERHOSTINGURLS` y `DOTNET_PREFERHOSTINGURLS`. Se miran las dos cosas porque `WebApplicationBuilder` copia la configuración del anfitrión en `builder.Configuration` [I: comportamiento documentado de .NET; lo fija una prueba].
2. **Valores** según la tabla de 4.1; un valor inválido → 4743.
3. **Una sola fuente:** la variable `GPOS_MODO_RED` o la clave `GPOS:Red:Modo`, si aparecen con un valor distinto del registro (o con el registro ausente) → 4743. Si coinciden, se ignoran. En la Web, un `Api:Url` configurado distinto del derivado del registro → 4743 (5.2).
4. **Direcciones efectivas** (4746, en `ApplicationStarted`, con `IServerAddressesFeature`, como `ServiciosReportes.cs:170-179`):
   - `UnEquipo`: toda dirección es `https` y de *loopback*.
   - `ServidorSitio`: toda dirección es `https` y su puerto es el armado; **ninguna** `http`, tampoco en *loopback*.
   - «Sin modo» (sin Estricto): toda dirección es de *loopback*.
   - Si falla: `LogCritical(4746)`, `Environment.ExitCode = 1` y `StopApplication()`.
5. La API de reportes **no** cambia en estas piezas (sigue en `http://localhost:5073`, RT-05). Su crítico sin `EventId` lo corrige **B** en un PR del tramo 4 con el **5119 `DireccionNoPermitida`** y `Environment.ExitCode = 1` (RB Q-5 de 1.2; HB-12). A no lo toca.

### 5.2 P2 · RT-05: escucha por modo y selector (PR-2, tras PR-1b)

**Puntos de escucha armados en código** (dentro de `Preparar`, con `ConfigureKestrel`; se suman a `OpcionesServidor.Aplicar` y `OpcionesServidorWeb.Aplicar`, que no cambian):

| Servicio | `UnEquipo` | `ServidorSitio` |
|---|---|---|
| `GPOS.Api` | `ListenLocalhost(PuertoApi)` + HTTPS | `ListenAnyIP(PuertoApi)` + HTTPS (en Windows, socket `[::]` de doble pila [I]) |
| `GPOS.Web` | `ListenLocalhost(PuertoWeb)` + HTTPS | `ListenAnyIP(PuertoWeb)` + HTTPS |
| Puerto 80 / HTTP | ninguno | ninguno |

- Protocolos: `HttpProtocols.Http1AndHttp2`; TLS: `SslProtocols.Tls12 | Tls13` explícito; sin certificado de cliente. Las suites de Schannel las fija devops (RT-09).
- HTTPS por `ListenOptions.UseHttps(TlsHandshakeCallbackOptions { OnConnection = _ => selector.OpcionesVigentes, HandshakeTimeout = 10 s })`.
  - Cada saludo usa un `SslStreamCertificateContext` ya construido (`offline: true`, sin descargas AIA) [I: a medir en el laboratorio].
  - `ApplicationProtocols` se fija en `[h2, http/1.1]` [I; lo fija una prueba].
  - **Descartado:** `ServerCertificateSelector` (no controla el contexto ni los protocolos y no deja cachear la cadena).

**Selector** (`GPOS.Comun.Servidor/Red/SelectorCertificadoServidor.cs`):

```csharp
public interface IAlmacenCertificadosServidor { X509Certificate2? BuscarPorSha256(string huella); }
// AlmacenCertificadosServidor.Windows.cs (ADR-129, B.3): [SupportedOSPlatform("windows")] internal sealed class
//   AlmacenCertificadosServidorWindows : IAlmacenCertificadosServidor — LocalMachine\My, ReadOnly|OpenExistingOnly.
// Fuera de Windows no hay implementación: con Estricto ya no se llega aquí (5.1, regla 0); sin Estricto no se arma HTTPS ("sin modo").
public sealed class SelectorCertificadoServidor : IDisposable
{
    public SelectorCertificadoServidor(ServicioRed servicio, IFuenteConfiguracionRed fuente, IAlmacenCertificadosServidor almacen,
                                       TimeProvider reloj, ILogger log);
    public SslServerAuthenticationOptions OpcionesVigentes { get; }   // lectura volátil; nunca null tras el arranque
    public string HuellaVigente { get; }
    public bool CargarAlArrancar();                                   // false → 4747 y ExigirArranque no deja arrancar
}
```

- **Refresco:** `PeriodicTimer` de **5 minutos** sobre `TimeProvider`. **No se lee el registro ni el almacén dentro del saludo TLS.**
- **Un certificado es utilizable si:** está en el almacén; su SHA-256 coincide; tiene llave privada **y la cuenta del servicio la abre** (`GetECDsaPrivateKey()`, o `GetRSAPrivateKey()` para un certificado del cliente; una `CryptographicException` lo hace no utilizable); trae EKU `serverAuth`; `NotBefore ≤ ahora < NotAfter`.
- **Cambio de huella:** si la nueva es utilizable, se cambia y se registra el 4749. Si no, **se sigue sirviendo el anterior** y se registra el 4748 (crítico), como mucho una vez por huella en cada refresco (PT-02). El anterior se conserva en memoria hasta el siguiente cambio.
- **Al arrancar**, sin certificado utilizable: 4747 y no arranca. Con las acciones de recuperación del MSI (RB Q-4), un 4747 transitorio (la tarea de renovación aún no dio la lectura de la llave) se recupera solo.
- El selector **no** juzga el vencimiento cercano: los avisos a 20, 10 y 3 días son de la tarea de renovación (EventId 4780 a 4789, del verbo `tls`).

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
- `SslOptions`: `TargetHost` = el nombre de la URL, `EnabledSslProtocols = Tls12 | Tls13`, `CertificateRevocationCheckMode = NoCheck` (RT-04).
- **Sin `RemoteCertificateValidationCallback`:** la cadena y el nombre los valida el sistema. **La CA del sitio la instala el verbo `tls` en `LocalMachine\Root` del propio servidor, en los dos modos, en el paso 6 de la cadena** (RB Q-8 de 1.2). Con el «certificado del cliente» no instala nada. La Web no fija una CA propia: usa solo el almacén del sistema (coherente con PT-03).
- `PooledConnectionLifetime = 10 min`: las conexiones abiertas toman el certificado renovado de la API sin reiniciar la Web.
- **`Api:Url` derivado (RB Q-2; pendiente de confirmación en F-6 (i)):** con modo presente, la URL sale de `DireccionApi`. Si la configuración trae un `Api:Url` distinto → 4743, no arranca. En «sin modo» rige `Api:Url` como hoy. El MSI **no** escribe `Api:Url`, y `ArchivoInstalacion.SeccionesPermitidas` sigue solo con `GPOS:RncDgii` (`src/GPOS.Comun/Configuracion/ArchivoInstalacion.cs:27`) [V].
- **H-15 en PR-2 (unos 0,1 dp):** `AllowedHosts` se arma en el código a partir de `NombresServidor` (más `localhost` en «un equipo»); cookies con `Secure`. Una sola fuente (PT-06). También pendiente de confirmación en F-6 (i).

### 5.3 P3 · RT-06: filtro por la IP de la conexión (PT-05, punto 4; PR-3)

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
| Web, IP ∈ `IpNodos` | **403** para todo (PT-05: el 443 no se abre a esa clase) |
| Otras clases | Sin filtro por ruta (PT-05) |
| `IpNodos` vacío | El *middleware* no hace nada (nodos de sucursal y sitio único). `IpNodos` **ausente** en «servidor de sitio» ya no llega aquí: el servicio no arrancó (4743) |
| Respuesta 403 de la API | `application/problem+json`: `{"title":"Origen no permitido","status":403,"codigo":"ORIGEN_NO_PERMITIDO"}`, `Cache-Control: no-store`, sin `detail` |
| Respuesta 403 de la Web | Texto plano corto, sin cuerpo HTML |
| Evento | API: 4750 (aviso) con IP, método y ruta truncada a 200 caracteres, **sin la consulta**. Web: 4751. Como mucho uno por IP cada 60 s, con el número de suprimidos. **No** se escribe en `BitacoraSeguridad` |

**Corrección de `LimitesPeticiones.Ip`** (`LimitesPeticiones.cs:178`):
`public static string Ip(HttpContext ctx) => DireccionIp.Normalizar(ctx.Connection.RemoteIpAddress)?.ToString() ?? "desconocida";`
Sigue leyendo la IP **después** de `UseForwardedHeaders`. `AuthEndpoints` (zona T de DB-7) **no** se toca: cambiar sus tres normalizaciones en línea por `DireccionIp.Normalizar` lo hará D2 cuando toque ese archivo (RB Q-10 de 1.2).

**Clave (cuenta, IP) de DB-7 (corrige la v1; HB-10):** es de **D2**, no de D1, y vive en memoria (15 min, tope de 100 000 entradas), sin persistirse (BP3:528, :631, :767 y :1083, según RB). Normalizar `LimitesPeticiones.Ip` solo trae beneficios: D2 lo usará como única fuente. `LimitesPeticiones.Ip` también lo usan el emparejamiento y la autenticación de dispositivos (`src/GPOS.Api/Endpoints/RestauranteDispositivosEndpoints.cs:33`; `src/GPOS.Api/Seguridad/AutenticacionDispositivo.cs:41`, según HB-10), cuya clave ya normaliza (`src/GPOS.Core/Servicios/Modulos/Restaurante/Dispositivos/Contratos.cs:170-178`, según RB). PR-3 agrega una prueba de que el freno de emparejamiento sigue igual con IPv4 mapeada. **PR-3 se une antes del 2026-11-09**, cuando D2 empieza a usar la IP para el bloqueo.

### 5.4 Errores

- **HTTP:** solo `403 ORIGEN_NO_PERMITIDO` (P3). Lo demás son fallos de arranque, sin respuesta HTTP.
- **SQL:** **ninguno**. Las piezas no tocan la base; no se usa ningún número, tampoco del 51618 al 51644.
- **Excepciones:** `ArranqueRedException` (arranque); `HttpRequestException` del `ConnectCallback` («destino no permitido»), que la Web trata como API no disponible (`/estado-api` → 503, `Program.cs:132-145`).

### 5.5 EventId (franja de A para ADR-90: 4743 a 4752; tabla de RB Q-8 de 1.1)

| Id | Nombre | Nivel | Quién | Cuándo |
|---|---|---|---|---|
| 4743 | `RedConfiguracionInvalida` | Crítico | API, Web | Valor del registro inválido; **`ModoRed` ausente con Estricto**; **sin fuente para la plataforma con Estricto**; **`IpNodos` ausente en «servidor de sitio»**; modo del entorno distinto; `Api:Url` distinto; `IpNodos` con prefijo amplio |
| 4744 | `RedFuenteEscuchaRechazada` | Crítico | API, Web | Una fuente de direcciones de 5.1, regla 1 |
| 4745 | `RedSinModo` | Aviso | API, Web | Arranque sin `ModoRed` y **sin** Estricto (4.3) |
| 4746 | `RedDireccionNoPermitida` | Crítico | API, Web | Dirección efectiva fuera de lo armado |
| 4747 | `TlsCertificadoNoDisponible` | Crítico | API, Web | Al arrancar, sin certificado utilizable |
| 4748 | `TlsCertificadoNuevoNoUsable` | Crítico | API, Web | La huella nueva no es utilizable; se sigue con la anterior |
| 4749 | `TlsCertificadoCambiado` | Información | API, Web | El selector tomó la huella nueva |
| 4750 | `OrigenNodoRutaDenegada` | Aviso | API | 403 a un nodo fuera de `/api/sync/*` |
| 4751 | `WebOrigenNodoDenegado` | Aviso | Web | 403 a un nodo en el 443 |
| 4752 | (reservado) | — | — | Para una sola ampliación de estas piezas sin pedir rango |

- Se declaran como `public static readonly EventId X = new(n, "Nombre")` en `GPOS.Comun/Red/EventosRed.cs` (PR-1a), que es el formato que reconoce `EventIdUnicosTests` (`tests/GPOS.Tests/Arquitectura/EventIdUnicosTests.cs:20-21`) [V]. `GPOS.Comun` ya referencia `Microsoft.Extensions.Logging.Abstractions` [V], así que no hace falta `GPOS.Comun.Servidor` para declararlos. *Diferencia con RB 4.1, que ponía `EventosRed` en PR-1b:* se adelanta a PR-1a porque AV pide «PR-1a con los EventId 4743 a 4752» y las pruebas de la evaluación pura los necesitan; no cambia ningún número.
- Resto de la franja 47xx (no son de este plano): 4753-4766 acción previa y actualizador (A); 4771-4779 (4767-4770: N-1 de B; aviso B del 2026-10-21) `GPOS.Instalacion` de B; 4780-4789 verbo `tls` y su tarea (A); 4791-4799 reserva de DB-7 (4790: T1-7 de B). Se abandona 5130-5149.
- Antes de unir cada PR, `git grep` en todas las ramas de `origin` (regla de ADR-82:220; RB 4.2, regla 7).
- Son eventos del registro de la aplicación, no de `EventosSeguridad`: no entran en la comprobación de catálogo del 4733 de DB-7.
- El origen en el Visor de eventos lo da `AddWindowsService` (N-1, B).

## 6. Interfaces entre módulos

- **Verbo `red` (B) → servicios:** `ModoRed`, `PuertoApi`, `PuertoWeb`, `NombresServidor` e `IpNodos` (siempre presente) en el registro, escritos en el paso 2 de la cadena, antes de los MSI. Si cambia el modo, deja el evento de PT-06 (franja 4771-4779 (4767-4770: N-1 de B; aviso B del 2026-10-21) de B). Ningún valor en el entorno del servicio.
- **Verbo `tls` (A) → servicios:** solo por el registro (`HuellaApi`, `HuellaWeb`) y el almacén `LocalMachine\My`, en el orden de PT-02: emitir, dar lectura de la llave a `NT SERVICE\GPOS.Api|Web`, comprobar que la abre y **luego** publicar la huella. Corre en el paso 6, **después** de los MSI (las cuentas virtuales ya existen y la raíz ya está protegida; HB-01; F-6 (ii)). El servicio no avisa al verbo: el refresco de 5 minutos basta.
- **Web → API:** `https://<nombre>:<PuertoApi>` por *loopback* (5.2), con el mismo `ReenvioIpCliente` de hoy.

## 7. Estructura de proyectos y carpetas

```
src/GPOS.Comun/Red/{ModoRed,ServicioRed,ConfiguracionRed,LecturaRed,IFuenteConfiguracionRed,FuenteConfiguracionRed,
                    DireccionIp,ValoresRegistroServidor,EvaluacionArranqueRed,EventosRed}.cs                          (PR-1a)
src/GPOS.Comun/Red/FuenteConfiguracionRed.Windows.cs                                                                  (PR-1a)
src/GPOS.Comun.Servidor/GPOS.Comun.Servidor.csproj   (net10.0; FrameworkReference Microsoft.AspNetCore.App; → GPOS.Comun) (PR-1b, tras F-1)
src/GPOS.Comun.Servidor/Red/{EscuchaServidor,EstadoRed,ArranqueRedException}.cs                                         (PR-1b)
src/GPOS.Comun.Servidor/Red/{SelectorCertificadoServidor,IAlmacenCertificadosServidor,ClienteApiLocal}.cs              (PR-2)
src/GPOS.Comun.Servidor/Red/AlmacenCertificadosServidor.Windows.cs                                                      (PR-2)
src/GPOS.Api/Seguridad/FiltroOrigenNodo.cs                                                                              (PR-3)
src/GPOS.Web/Servicios/RechazoOrigenNodo.cs                                                                             (PR-3)
tests/GPOS.Tests/Red/…           (Comun, Comun.Servidor y el filtro de la API)
tests/GPOS.Web.Tests/Red/…       (manejador y rechazo de la Web)
```

- Solo los archivos `*.Windows.cs` usan API de una plataforma (registro, almacén de certificados), para que pase la prueba de arquitectura de ADR-129, B.5 [V `docs/adr/ADR-129.md:34`]. `DireccionIp`, `EvaluacionArranqueRed` y el selector son neutros.

**Puntos de toque en `src/GPOS.Api/Program.cs` (zona S de DB-7; solo en PR-4):**
1. Tras `:46`: `var red = EscuchaServidor.Preparar(builder, ServicioRed.Api, ComprobacionAnillo.EsEstricto(builder.Configuration));`
2. Tras `:339`: `EscuchaServidor.ExigirArranque(app, red);`
3. Antes de `:349`: `app.UseFiltroOrigenNodo(red.IpNodos);`
4. Un `using GPOS.Comun.Servidor.Red;` y la referencia en `GPOS.Api.csproj`.

**Todo lo demás se construye sin tocar `Program.cs` de la API:** las bibliotecas, `FiltroOrigenNodo.cs`, `LimitesPeticiones.cs:178` y todas las pruebas. Las del filtro arman su propia canalización con `TestServer` y no usan `WebApplicationFactory<Program>`.

**Puntos de toque en `src/GPOS.Web/Program.cs` (zona U de DB-7 desde el 11-23; HB-14):** tras `:50`, `Preparar(builder, ServicioRed.Web, ProteccionDatosWeb.EsEstricto(builder.Configuration))` (PR-1b). En `:62-67`, la URL de `DireccionApi` y `.ConfigurePrimaryHttpMessageHandler(() => ClienteApiLocal.CrearManejador(red))` con modo presente (PR-2). Tras `:98`, `ExigirArranque` (PR-1b). Antes de `:101`, `UseRechazoOrigenNodo` (PR-3, o PR-1b si PR-3 se une antes). **Las partes de la Web se unen antes del 11-20**, o esperan a que se una D4.

## 8. División en PR (un PR por cláusula; RC-90-2) — reparto de RB 4.1 y AV

| PR | Rama (base `feature/modelo-ng`) | Contenido | Toca `Program.cs` de la API | Se une | Depende de |
|---|---|---|---|---|---|
| **PR-1a · RT-01, núcleo** | `a/adr90-rt01-modo-red` | `GPOS.Comun/Red` completo (4.2, `EvaluacionArranqueRed`, `EventosRed` 4743-4752, `FuenteConfiguracionRed.Windows.cs`, constantes del registro). **Sin proyecto nuevo y sin conectar** | No | **Ya** (10-22 a 10-27), cuando B lo revise | — |
| **PR-1b · RT-01, Kestrel** | `a/adr90-rt01-escucha-servidor` | Proyecto `GPOS.Comun.Servidor`, `EscuchaServidor`, `EstadoRed`, conexión en la **Web** | No | Tras la firma de **F-1**; parte de la Web antes del 11-20 | PR-1a; F-1 |
| **PR-3 · RT-06** | `a/adr90-rt06-filtro-origen` | `FiltroOrigenNodo`, `RechazoOrigenNodo` (Web), `DireccionIp` en `LimitesPeticiones.Ip`, prueba del freno de emparejamiento | No | **Antes del 2026-11-09** (D2) | **Solo PR-1a** (la API tiene ASP.NET por `GPOS.Core`; la Web también) |
| **PR-2 · RT-05** | `a/adr90-rt05-escucha` | Puntos de escucha, selector, `AlmacenCertificadosServidor.Windows.cs`, `ClienteApiLocal`, H-15; conexión en la Web | No | **Después de PR-3**; parte de la Web antes del 11-20 o tras D4 | PR-1b (y F-1) |
| **PR-4 · conexión en la API** | `a/adr90-api-program` | Las 4 líneas de la sección 7 | **Sí** | Con **F-5** firmada: en la ventana del **10-28 al 11-06**, **después del PR de N-1 de B**. Sin F-5 o si no llega: **después del 11-20** | PR-1a a PR-3; PR de N-1 (B); F-5 **v2.2 (revisión de seguridad de PR-4, S4-01): PR-4 NO se une antes de PR-2** (con el modo presente y sin RT-05 la API ejecuta anillo, `Inicializacion` y trabajos en segundo plano, enlaza HTTP en loopback y solo entonces se detiene con 4746). PR-2 se apila sobre PR-4 y se unen juntos; orden: #122, #130, PR-1b, #136, PR-4 + PR-2. |

- **Hasta que se firme F-5 y se una el PR de N-1, A no toca `src/GPOS.Api/Program.cs`** (AV).
- PR-4 contiene **solo** las 4 líneas, el `using` y la referencia del `.csproj`, más una **prueba de arquitectura** sobre el texto de `Program.cs`: `UseFiltroOrigenNodo` antes de `UseForwardedHeaders` y `ExigirArranque` después de `builder.Build()` (RB 4.2, regla 3).
- **Antes de abrir PR-4**, A deja un aviso en `avisos/A-a-B/`; B confirma la ventana y hace la unión. La suite completa corre sola, con el filtro oficial `Transicion!=Ola5&Transicion!=Defecto` (RB 4.2, regla 6). Los días 11-16 y 11-17 no se corren suites.
- **Si F-1 se firma con la opción (b)** (sin `GPOS.Comun.Servidor`), PR-1b y PR-2 vinculan los archivos de Kestrel en `GPOS.Api.csproj` y `GPOS.Web.csproj`; el reparto y las fechas no cambian.
- Cada PR cita ADR-90, la cláusula y el PT, y pasa la suite oficial con el filtro vigente.

## 9. Pruebas

**PR-1a**
- `FuenteConfiguracionRedWindows` con un doble de `IFuenteConfiguracionRed` y, en una prueba marcada solo para Windows, con una subclave temporal de `HKCU` (la fuente recibe la raíz inyectada).
- Tabla de valores válidos e inválidos de 4.1: puerto 0, 70000 o 5073; `PuertoApi = PuertoWeb`; `NombresServidor[0]` igual a `localhost` o a una IP; `IpNodos` con `/24`; huella de 40 caracteres.
- **`IpNodos`:** presente y vacío en «servidor de sitio» → válido, conjunto vacío; **ausente** en «servidor de sitio» → `Invalida` y 4743; ausente en «un equipo» → válido.
- **Estricto:** `SinModo` + Estricto → no arranca, 4743; `SinModo` sin Estricto → arranca con 4745; `SinFuente` (plataforma simulada) + Estricto → 4743; `SinFuente` sin Estricto → como `SinModo`.
- Cada fuente de 5.1, regla 1, por configuración y por variable de entorno → 4744.
- `GPOS_MODO_RED` distinto, o sin registro → 4743.
- `ComprobarDirecciones` en tabla:
  - `UnEquipo`: `https://127.0.0.1:5071` sí; `https://[::]:5071` no; `http://localhost:5071` no.
  - `ServidorSitio`: `https://[::]:5071` sí; `http://[::]:80` no; `https://[::]:5072` no.
  - «Sin modo»: `http://localhost:5071` sí; `http://0.0.0.0:5071` no.
- Prueba de arquitectura de ADR-129, B.5, sobre `GPOS.Comun/Red`: `Microsoft.Win32.Registry` solo en `*.Windows.cs`.

**PR-1b**
- Arranque real de Kestrel en «sin modo» con `urls=http://0.0.0.0:0` → 4746 y código de salida ≠ 0.
- `ArranqueRedException` con 4743/4744 desde `ExigirArranque`; en Estricto sin registro, la Web no arranca.

**PR-2**
- Certificados ECDSA P-256 creados en la prueba (`CertificateRequest`) y un `IAlmacenCertificadosServidor` en memoria.
- Kestrel real en un puerto libre: el saludo TLS 1.2 y 1.3 entrega el certificado esperado; TLS 1.1 se rechaza; con `h2` y con HTTP/1.1, y WebSocket (Blazor) por HTTP/1.1.
- Con `FakeTimeProvider`: cambiar la huella → el saludo nuevo usa el certificado nuevo **después** del refresco de 5 min; 4749.
- Huella nueva sin llave privada, sin EKU `serverAuth` o vencida → se sirve la anterior; 4748 una sola vez por refresco.
- Al arrancar sin certificado → 4747, no arranca.
- `ClienteApiLocal`: con un servidor en *loopback* y un certificado para `gpos-s01.prueba` (raíz de prueba por la sobrecarga interna), la petición llega sin DNS; un certificado para otro nombre → falla; otro anfitrión o puerto → «destino no permitido».
- `Api:Url` distinto del derivado → 4743. `AllowedHosts` derivado de `NombresServidor` (H-15).
- Prueba de arquitectura: ningún `RemoteCertificateValidationCallback` ni `DangerousAcceptAnyServerCertificateValidator` en `src/GPOS.Web` ni en `src/GPOS.Comun.Servidor`, fuera de la sobrecarga interna.

**PR-3**
- `TestServer` con un *middleware* de prueba que fija `RemoteIpAddress`, y `IpNodos = {10.9.0.5}`:
  - `GET /api/sync/x` desde `10.9.0.5` → no 403 (404, porque la ruta no existe);
  - `/api/auth/empresas` → 403 `ORIGEN_NO_PERMITIDO`;
  - `/API/SYNC/x` → pasa; `/api/syncx` → 403;
  - desde `::ffff:10.9.0.5` → 403;
  - desde `10.9.0.5` con `X-Forwarded-For: 127.0.0.1` → 403;
  - desde *loopback* con `X-Forwarded-For: 10.9.0.5` → **no** se filtra (es la Web; ver R-5);
  - 100 rechazos en 60 s → un solo 4750 con el número de suprimidos.
- Kestrel real: `/api/sync/../auth/empresas` llega normalizado y se rechaza [I: la prueba lo fija].
- `LimitesPeticiones.Ip` con `::ffff:192.168.1.10` → `192.168.1.10`.
- **Freno de emparejamiento** de dispositivos: mismo resultado con `192.168.1.10` y con `::ffff:192.168.1.10` (HB-10).
- Web: un nodo en el 443 → 403 y 4751.

**PR-4**
- Suite oficial completa (sola).
- Prueba de humo de `WebApplicationFactory<Program>` en «sin modo» (entorno `Pruebas`, sin Estricto) que arranca igual que hoy.
- Prueba de arquitectura del orden en `Program.cs` (sección 8).
- **R-4:** con la API en `[::]` y la Web conectando a `127.0.0.1`, la IP que ve `ForwardedHeaders` es `::ffff:127.0.0.1`. Se comprueba que `KnownProxies` la acepta y que los límites por IP siguen viendo la IP del usuario. Según HB-11, probablemente lo cubre el marco [I], porque el código solo agrega proxies a los valores por omisión (`Program.cs:49-54`) [V]; la prueba se conserva.

**Laboratorio (QA, con el paquete de B; no bloquea unir):** servicio con cuenta virtual, renovación con el reloj adelantado pasado el vencimiento (PT-02), actualización sin `MODO_RED` y con un modo distinto (PT-06), registro borrado con Estricto (no arranca, 4743), `IpNodos` borrado en «servidor de sitio» (no arranca), recuperación del servicio tras 4747 transitorio (RB Q-4), y el filtro con un nodo real por la VPN.

## 10. Esfuerzo (días-persona, ±50 %; 1 sp = 5 dp; USD 1.500 a 2.000 por sp)

| PR | dp | Nota |
|---|---|---|
| PR-1a · RT-01 núcleo | 0,7 | Evaluación pura, fuente, Estricto y `IpNodos`; sin proyecto nuevo |
| PR-1b · RT-01 Kestrel | 0,4 | Incluye el proyecto nuevo (o los vínculos, si F-1 b) |
| PR-2 · RT-05 | 1,6 | Incluye H-15 (0,1) |
| PR-3 · RT-06 | 0,65 | Incluye la prueba del freno de emparejamiento (0,05) |
| PR-4 · conexión en la API | 0,3 | Más una ejecución de la suite completa |
| **Total** | **3,65 dp (1,8 a 5,5), unas 0,73 sp, de USD 1.100 a 1.460** | +0,25 dp frente a la v1: separar PR-1a/PR-1b, H-15 y las pruebas de Estricto e `IpNodos` |

**Opción más barata:** dejar la Web sin `RechazoOrigenNodo` (−0,1 dp). No la recomiendo: es la única defensa si la regla del 443 queda mal configurada. Con F-1 (b), +0,3 dp.

## 11. Riesgos de seguridad

| # | Riesgo | Prob. / impacto | Mitigación en el contrato | Residual |
|---|---|---|---|---|
| R-1 | Una fuente de direcciones no prevista abre un puerto | Baja / Alto | Lista de 5.1 **y** comprobación de direcciones efectivas (4746) | Bajo |
| R-2 | El selector bloquea o encarece los saludos | Media sin caché / Medio | Refresco por temporizador; el saludo solo lee una referencia | Bajo [I, a medir] |
| R-3 | La renovación publica una huella cuya llave el servicio no abre | Media / Alto | Orden de PT-02 en el verbo; el selector conserva el anterior (4748) | Bajo |
| R-4 | `ForwardedHeaders` no reconoce `::ffff:127.0.0.1` | Baja / Medio | Probablemente lo cubre el marco (HB-11); prueba en PR-4 | Bajo |
| R-5 | Un nodo llega a la API completa a través de la Web (443) si el cortafuegos queda mal | Baja / Medio | `RechazoOrigenNodo`; el acceso a datos exige un token de persona (ADR-53) | Bajo |
| R-6 | Eludir el filtro con trucos de ruta | Baja / Medio | `StartsWithSegments` sobre la ruta normalizada; pruebas de PR-3 | Bajo |
| R-7 | Inundación del Visor de eventos con 403 | Media / Bajo | Un evento por IP cada 60 s; sin escrituras en SQL | Bajo |
| R-8 | Una instalación de cliente con el registro borrado arranca abierta | Baja / Alto | «Sin modo» solo sin Estricto; con Estricto, 4743 (HB-04). `IpNodos` ausente en «servidor de sitio» → 4743 (HB-05) | Bajo |
| R-9 | Un administrador local cambia el registro (modo, `IpNodos` vacío) o quita Estricto | Baja / Alto | DACL del verbo `red` (solo SYSTEM y Administradores escriben); un administrador ya controla el equipo | Medio, aceptado (como H-13) |
| R-10 | Bucle de reinicios tras una falla cerrada | Media / Bajo | Código de salida ≠ 0; recuperación del MSI: 3 reinicios a los 60 s, contador diario, `FailureActionsWhen="failedToStopOrReturnedError"`; después, alerta de «servicio detenido más de 2 minutos» (B-8) (RB Q-4; HB-15) | Bajo |
| R-11 | La Web confía en cualquier raíz del almacén del servidor | Baja / Medio | El tráfico no sale del equipo (`ConnectCallback` a *loopback*) | Bajo |
| R-12 | F-1 no se firma pronto y PR-1b/PR-2 se retrasan hasta chocar con D4 en la Web (11-23) | Media / Medio | PR-1a y PR-3 no dependen de F-1; con F-1 (b) se sigue con vínculos | Bajo |

## 12. Preguntas de la v1 y respuestas de B (RB 1.2)

| # | Pregunta | Respuesta de B, aplicada en esta v2 |
|---|---|---|
| Q-1 | Registro | Aceptado con cinco cambios: `IpNodos` ausente → 4743 en «servidor de sitio»; escritor único `red` con su ACL; `Version`, `FechaInstalacion`, `RegistroInstalacion`; `PuertoApi ≠ PuertoWeb`; `PuertoWeb` opcional (4.1) |
| Q-2 | `Api:Url` | Derivado del registro; también `AllowedHosts` (H-15) en PR-2. Confirmación en F-6 (i) |
| Q-3 | DEMO | Nadie abre el DEMO desde otra PC; «sin modo» solo sin Estricto (4.3) |
| Q-4 | Recuperación del servicio | Como la estación, más `FailureActionsWhen` (R-10) |
| Q-5 | EventId | 4743-4752 para A; el 5119 de reportes lo hace B |
| Q-6 | Ventana de PR-4 | Exige firma (F-5): ventana 10-28 a 11-06 tras N-1 de B; si no, después del 11-20 |
| Q-7 | `IpNodos` en un nodo | Vacío, nunca sin crear |
| Q-8 | CA en el servidor | Sí, la instala el verbo `tls` en el paso 6 |
| Q-9 | Recolección del DLL nuevo | La toma sola (`Files` de WiX 5 [I]); `construir.ps1 -Firmar` rechaza un `GPOS.*.dll` sin firma |
| Q-10 | Clave (cuenta, IP) | Es de D2 y en memoria; PR-3 antes del 11-09 |

**Abierto:** nada para B. Las firmas F-1, F-5 y F-6 las prepara el Arquitecto Maestro y las firma el propietario.

## 13. Necesidades para Datos e Integraciones

- **Datos:** ninguna; no hay tablas, migraciones ni errores SQL.
- **Integraciones:** ninguna; la credencial del nodo con audiencia `/api/sync/*` (PT-05, punto 5) va con el diseño de la sincronización (entrega 2).

## 14. Decisiones candidatas a precisión (no ADR nuevo)

- **«Sin modo» solo sin Estricto; fuera de Windows, falla cerrada con Estricto** (4.3, 4.2). Precisión de RT-01 (RB, candidata 3). Técnica, sin firma.
- **`IpNodos` siempre escrito; ausente en «servidor de sitio» = 4743.** Precisión de PT-05/PT-06. Técnica.
- **URL de la Web y `AllowedHosts` derivados del registro** (5.2) — **F-6 (i), Pendiente de firma** (confirmación).
- **Huella SHA-256** del DER en lugar de la SHA-1 de Windows. Afecta al verbo `tls`.
- **Proyecto `GPOS.Comun.Servidor`** — dentro de **F-1, Pendiente de firma**; alternativa (b) con vínculos.
- **PR-4 adelantado** — **F-5, Pendiente de firma**.

## Resumen (10 líneas)

1. v2 aplica las respuestas de B (RB y AV): renombres `*.Windows.cs`, «sin modo» solo sin Estricto, `IpNodos` obligatorio y nuevo reparto de PR.
2. Única fuente: `HKLM\SOFTWARE\GPOS NG\Servidor`, escrita solo por el verbo `red` de B antes de los MSI; `tls` escribe solo las huellas.
3. Con Estricto, sin `ModoRed` o sin fuente para la plataforma → 4743 y no arranca; sin Estricto, «sin modo» solo en *loopback* (4745).
4. `IpNodos` presente y vacío es válido; ausente en «servidor de sitio» → 4743 (falla cerrada).
5. RT-01 se parte: PR-1a en `GPOS.Comun/Red`, sin proyecto nuevo, con `EventosRed` 4743-4752; PR-1b con `GPOS.Comun.Servidor` tras F-1.
6. RT-05: HTTPS sin puerto 80; selector por huella SHA-256 con refresco de 5 min; la Web llama a la API por *loopback* con el nombre del sitio; `Api:Url` y `AllowedHosts` derivados (F-6).
7. RT-06: filtro por la IP de la conexión normalizada antes de `UseForwardedHeaders`; PR-3 depende solo de PR-1a y se une antes del 11-09.
8. PR-2 después de PR-3; PR-4 tras N-1 de B y F-5 (ventana 10-28 a 11-06) o después del 11-20; hasta entonces no se toca el `Program.cs` de la API. **v2.2: PR-4 depende de PR-2 y se une con él (S4-01).**
9. Ningún error SQL; EventId 4743-4752 libres en las 162 referencias de `origin` (comprobado el 2026-10-20).
10. Esfuerzo: 3,65 dp (1,8 a 5,5), de USD 1.100 a 1.460. Pendientes de firma: F-1, F-5 y F-6.

### Cierre
- Estado: Completado
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\blueprint-adr90-rt01-rt05-rt06-2026-10-20.md` (v2)
- Supuestos: `Microsoft.Win32.Registry` está disponible en `net10.0` sin paquete extra [I]; el comportamiento de `WebApplicationBuilder` con `urls` y `preferHostingUrls`, de `ForwardedHeadersMiddleware` con IPv4 mapeada y de `Files`/`FailureActionsWhen` en WiX 5 es [I] y lo fijan pruebas o el laboratorio; las citas de BP3 y de `RestauranteDispositivosEndpoints.cs`/`AutenticacionDispositivo.cs`/`Contratos.cs` se toman de RB sin volver a verificarlas.
- Decisiones candidatas a ADR: las de la sección 14 (precisiones de ADR-90; sin ADR nuevo).
- Entregas a otros agentes: Arquitecto Maestro → F-1, F-5 y F-6 a la hoja; desarrollador de A → PR-1a ya y PR-3 antes del 11-09; B → revisión de PR-1a, verbo `red`, PR de N-1 y 5119; devops de B → recuperación con `FailureActionsWhen`, quitar `ASPNETCORE_URLS` del DEMO al adoptar el paquete; QA → laboratorio de la sección 9.
- Próximo paso recomendado: que el desarrollador de A abra PR-1a sobre `feature/modelo-ng` con los contratos de 4.2, 5.1 y 5.5.
