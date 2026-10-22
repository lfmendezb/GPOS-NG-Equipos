Para: B        De: C        Fecha: 2026-10-22
Tipo: Revisión de pruebas (correcciones del PR #152, T4-01: S152-01/P152-01, P152-04, P152-05)
Repositorio y rama: GPOS-NG origin/b/ola5-t4-01-render @ cf6ccf98 (commits 20c81d3b, c2075988, cf6ccf98)
Estado: Abierto

# Revisión de las correcciones del #152

Leí con `git show` los tres commits y el código que respaldan (`Program.cs`, `EndpointsRender.cs`, `EndpointsReportes.PorCanalInterno`, `AutenticacionIntrospeccion`, `VerificadorIntrospeccion`, `ServiciosSeguridadReportes`, ayudantes de `RenderInternoTests`). **No compilé ni ejecuté nada** (ni dotnet, ni SQL, ni pruebas): no sé si pasan ni cuánto tardan. Criterio: mutación mental línea a línea. «Leído» = visto en código; «inferido» = deducido.

## Resumen

| ID | Sev. | Qué |
|---|---|---|
| P152b-01 | Baja | La prueba de revocación usa un verificador falso sin caché: prueba «una validación por petición» en el manejador, no que una revocación se vea en la petición siguiente; el verificador real tiene caché de 15 s |
| P152b-02 | Baja | «El cuerpo no se lee antes de autenticar» se prueba por el estado (401 en vez de 413/400): detecta lectura con efectos, no una lectura/almacenamiento sin tope antes de autenticar |
| P152b-03 | Baja | La prueba del `Program` real depende de `#if DEBUG`/modo desarrollo y, por inferencia, del `%ProgramData%` de la PC; falla en Release |
| P152b-04 | Baja | Fragilidad por conteos exactos (`conexiones == 1`, validaciones `== 2×4`) y por cuerpos de 16 MB enviados a un servidor que responde 401 sin leerlos (inferido, no ejecutado) |
| P152b-05 | Baja | P152-04 (c) empresa y (d) token fuera del registro siguen sin prueba; «vencido» solo por el verificador falso |

Ningún Alto ni Medio nuevo. Los tres hallazgos Medios/Alto prometidos (P152-01/S152-01, P152-04, P152-05) quedan **cerrados en lo esencial**; los matices son Bajos.

## Qué quedó bien cubierto (mutación mental)

### S152-01 / P152-01
**Leído:** `Las_rutas_de_render_del_programa_real_solo_existen_por_la_canalizacion` usa `WebApplicationFactory<Program>` (el `Program` real; `public partial class Program;`, `Program.cs:111`) con `UseKestrel()` y `StartServer()`: no recompone el pipeline. Solo sustituye el verificador (`ConfigureTestServices`) y fija configuración. Es comportamiento observable, no búsqueda de texto: comentarios, strings y `#if` no pueden engañarla.

| Mutación en `Program.cs` | Qué falla |
|---|---|
| Borrar `UsarRutasInternasSoloPorCanal` (l. 99) | HTTP sin token: ahora responde 401 en vez de 404 → falla |
| Moverla después de `UseAuthentication` | igual, 401 sin token → falla |
| Quitar `MapRender()` (l. 104) | la canalización da 404 en vez de PDF → falla en `PdfAsync` |
| Quitar `AgregarRender(...)` (l. 74) | falta `ServicioRender`/`TurnosRender` en DI: 500 por la canalización → falla |
| Quitar la comprobación de `RenderAsync` (l. 67) con el filtro presente | **no falla en el `Program` real** (el filtro ya da 404); la cubre `Sin_el_filtro_del_pipeline_...`: con el filtro apagado y token válido, la ruta daría 200 con PDF en vez de 404 → falla |
| Quitar filtro y comprobación a la vez | HTTP con token válido da PDF; sin token 401 → falla |

Las dos pruebas se complementan: el `Program` real fija el cableado y el orden; la recompuesta (con `filtroPorCanal: false`) fija la segunda barrera. Cada prueba recorre las cuatro rutas con `foreach` y `Assert` dentro: ninguna ruta se puede saltar.

**Qué verifica la comprobación de `RenderAsync` (leído):** `EndpointsReportes.PorCanalInterno` = `http.Features.Get<IConnectionNamedPipeFeature>() is not null` (`EndpointsReportes.cs:129`): la conexión llegó por un transporte de canalización con nombre. No verifica el dueño ni la ACL de esa canalización (eso lo hace `EscucharConCanalInterno`/ACL, ya probada aparte) ni que sea *la* canalización de la principal. Es lo mismo que hace la exportación; coherente. Corre antes de crear el plazo y de leer el cuerpo (l. 67 < l. 73).

### P152-04
**Leído:** la `Theory` tiene un `InlineData` por ruta (`/documento`, `/cierre`, `/conduce`, `/resultado`) y cada caso recorre `null`, `"invalido"`, `vencido` y `REVOCADO|USER`, exige 401 y comprueba el encabezado `X-GPOS-Sesion` (solo en la revocada; coincide con `HandleChallengeAsync`: el encabezado solo se escribe para motivos de sesión o de factor, así que `vencido` e `invalido` sin encabezado es lo correcto). Termina con un 200 con token válido por la misma conexión (evita el falso verde «401 para todo»). Mutaciones: `.AllowAnonymous()` en cualquiera de las cuatro rutas, `FallbackPolicy` nulo, tratar `vencido` como válido: cada una hace fallar el caso de su ruta.
**Revocación en la misma conexión:** el cliente es uno solo (`PorCanal(...)`), cuenta las conexiones con `ConnectCallback` (`== 1`) y las validaciones (`2 × Rutas.Length`): detectaría validar una vez por conexión o cachear en el manejador (ver P152b-01 sobre el verificador).

### P152-05
**Leído:** `LeerCuerpoAsync` tiene dos controles: `req.ContentLength > maximo` (l. 92) y acumulado en streaming (`ms.Length + leidos > maximo`, l. 98), de modo que **no depende solo de `ContentLength`**: chunked no lo evade. La prueba cubre ambos:
- Quitar el control por longitud: el 413 de `ByteArrayContent` lo sigue dando el streaming, pero el caso del tubo crudo (`Content-Length: 16 MB + 1`, solo se envía `{`, lectura con tope de 10 s) se queda esperando el cuerpo y falla. Bien pensado.
- Quitar el control de streaming: el caso `SinLongitud` (chunked, 16 MB + 1 de espacios) pasa el tope y responde 400, no 413 → falla.
- `>` por `>=` en cualquiera de los dos: los «16 MB exactos» (`ByteArrayContent(grande, 0, maximo)`) responden 413 en vez de 400 → falla.
- Cuerpo de 16 MB + 1 y JSON malformado con token inválido o sin token: 401, no 413 ni 400 → detecta un `[FromBody]`/lectura con validación antes de autenticar.
- `Assert.Equal(16 * 1024 * 1024, maximo)` fija el tope.

## Hallazgos

### P152b-01 (Baja) — Revocación: se prueba la costura, no la latencia real
**Leído:** el verificador de la prueba (`Verificador`) no tiene caché. El de producción sí: `VerificadorIntrospeccion` guarda cada respuesta 15 s por SHA-256 del token (`Vigencia = 15 s`, líneas 33 y 106). Por tanto «un token aceptado y luego revocado se rechaza en la petición siguiente» es cierto solo con el falso. En producción la revocación se ve a los 15 s como máximo (por diseño, igual que `RevocacionSesiones`).
**Qué sí prueba:** que el manejador llama a `ValidarAsync` en cada petición y no cachea por conexión ni por token. Es útil, pero el nombre de la prueba y el mensaje del commit («una validación por petición») pueden leerse como una garantía de revocación inmediata.
**Propuesta:** aclarar el comentario («en el manejador; el verificador real cachea 15 s») o agregar una prueba corta con `VerificadorIntrospeccion` real y `FakeTimeProvider`: revocar, avanzar 14 s (sigue válido), avanzar 1 s (se rechaza). Lo segundo puede que ya esté en `IntrospeccionCanalizacionTests` (no lo leí).

### P152b-02 (Baja) — «No se lee antes de autenticar» se prueba por proxy
**Leído:** todos los casos con token inválido solo comprueban `401`. Un `app.Use` previo a la autenticación que lea o haga `EnableBuffering` del cuerpo **sin imponer el tope ni parsear** devolvería igual 401 y pasaría (Kestrel acepta hasta 30 MB por omisión; 16 MB + 1 cabe). Lo que sí se detecta es una lectura con efecto visible (tope → 413, JSON → 400).
**Qué cerraría el hueco con una prueba barata:** el patrón del tubo crudo que ya escribieron, pero con token inválido: `Content-Length: 16 MB + 1`, cuerpo sin enviar, y exigir `HTTP/1.1 401` en menos de 10 s. Un middleware que espere el cuerpo antes de autenticar se colgaría. Solo hay esa prueba con token válido (que cubre otra cosa: el control por longitud).

### P152b-03 (Baja) — El `Program` real: dependencias del entorno
- **Leído:** `Program.cs:60-66`: fuera de `#if DEBUG`, `puedeOmitirCarpeta` es `const false` y la configuración `ComprobarCarpeta = false` de la prueba lanza `InvalidOperationException`. Además `VerificadorIntrospeccion.ModoDesarrollo` exige también Debug (T3-09). La prueba solo funciona en Debug; una corrida `dotnet test -c Release` la rompe. Conviene saberlo si el filtro oficial o una CI corre en Release (inferido: no sé cómo corre B).
- **Inferido, no verificado:** `Program.cs:24` lee `%ProgramData%\GPOS NG\config\GPOS.Reportes.Api.json` de la máquina; si existe en la PC de pruebas (LFMB con una instalación), podría aportar claves. No sé si las claves permitidas pueden pisar `urls`/`Canalizacion`; vale una línea de comprobación.
- La prueba hace `.Single(a => a.StartsWith("http://127.0.0.1:"))` sobre las direcciones: si el transporte de canalización agrega otra dirección con ese prefijo, falla (improbable; la prueba recompuesta usa la misma línea).
- No cubre `AddWindowsService` ni el orden de `UseExceptionHandler` respecto del filtro (si el filtro va antes del manejador de excepciones, el 404 sigue saliendo igual). No es un riesgo del PR.

### P152b-04 (Baja) — Fragilidad (todo inferido; no ejecuté nada)
1. `Assert.Equal(1, conexiones)` supone que Kestrel mantiene viva la conexión tras un 401 con cuerpo sin leer (cuerpos pequeños; lo normal es que lo drene). Si la cierra, el cliente reconecta y la prueba falla sin que haya defecto.
2. `Assert.Equal(2 * Rutas.Length, validaciones)` supone una única llamada al verificador por petición. Hoy el manejador de autenticación guarda su resultado por petición, así que es 1; un segundo esquema o un cambio en la política lo alteraría. Comprobarlo cuando corran la suite.
3. Los casos de 16 MB: unas 9 transferencias de 16 MB por canalización (6 con token inválido/sin token, de las cuales 4 son 401 que el servidor no lee, más 3 válidas). Una PC lenta o con carga puede acercarse al `Timeout` de 90 s del cliente. En los 401 con cuerpo sin leer, el cliente puede ver una escritura interrumpida si el servidor cierra la conexión (Kestrel normalmente drena; no lo verifiqué).
4. No hay dependencias de puertos fijos ni de relojes en las pruebas nuevas, salvo el tope de 10 s del tubo crudo (para una espera negativa que no aprueba en vacío: si el 413 no llega, falla). El nombre de la canalización es por instancia (`_canal`) y `_verificador` es del objeto de prueba, sin estado estático.

### P152b-05 (Baja) — Lo de P152-04 que no entró
Queda sin prueba lo que mi informe llamó (c) y (d): que el render **no** cruza `token.empresa` con `modelo.Empresa` (diseño temporal de Q-T4-01; sin prueba ni comentario) y que el token no sale en el registro de error. Además «vencido» se prueba con el verificador falso (`MotivoVencido`), no con un token que expire de verdad; el camino real (`ExpiraUtc <= ahora`, `VerificadorIntrospeccion.cs:109`) está en otro archivo de pruebas que no leí. B no se comprometió con (c) y (d); lo dejo anotado para T4-02.

## Regresiones en las pruebas existentes (leído)
- `IniciarAsync` agrega el parámetro `filtroPorCanal = true` y usa el campo `_verificador`: las pruebas anteriores conservan su comportamiento. `Verificador` conserva el formato `usuario|nivel`; las constantes nuevas (`vencido`, `Revocados`) no chocan con los tokens existentes (`CAJERO|USER`).
- `PorCanal(Action? alConectar = null)`: compatible con los usos previos.
- `Solo_la_cuenta_de_la_principal_...` sigue cubriendo `/documento`; ahora duplica en parte la `Theory`, sin conflicto.
- La primera barrera sigue ahí; la segunda no cambia la respuesta de las pruebas anteriores (el listener HTTP ya devolvía 404).
- Nuevas dependencias de pruebas: `Microsoft.AspNetCore.Mvc.Testing` y `TestHost` en `GPOS.Reportes.Tests`; no comprobé que el `.csproj` ya las referencie (el commit no toca el `.csproj`, así que o ya estaban o la compilación fallaría). **Inferido; lo sabrá B en la compilación.**

## Qué no verifiqué
- Nada se compiló ni se ejecutó: no sé si las tres pruebas nuevas ni la `Theory` pasan, ni sus tiempos, ni la memoria de los casos de 16 MB.
- Si `GPOS.Reportes.Tests` ya referencia `Microsoft.AspNetCore.Mvc.Testing` (el commit no toca `.csproj`).
- El comportamiento real de Kestrel con 401 y cuerpo sin leer (drenado o cierre de la conexión).
- El efecto de un archivo de instalación en `%ProgramData%` sobre la prueba del `Program` real.
- `IntrospeccionCanalizacionTests` (caché de 15 s, vencimiento real) y la prueba de DACL de canalización.
- Que S152-02 y S152-03 (los otros hallazgos del revisor de seguridad) estén resueltos: fuera de alcance.

## Recomendación a B
Los tres cierres son suficientes para unir en lo que toca a pruebas. Antes: correr la suite filtrada y revisar que el conteo de validaciones y de conexiones se cumpla (P152b-04). Opcional y barato: P152b-02 (un caso con token inválido y `Content-Length` sin cuerpo) y la aclaración de P152b-01.
