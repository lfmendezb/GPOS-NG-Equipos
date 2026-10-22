[Blueprint Técnico] T4-03 · Chromium aislado y sin red (Ola 5, tramo 4, PR 3)

Fecha: 2026-10-22 · Autor: arquitecto-software (equipo B) · Estado: **Completado (diseño, sin compilar)**. Las decisiones marcadas **[P]** quedan **Pendientes de firma** del propietario.
Base leída: worktree `GPOS-B-t4-01`, rama `b/ola5-t4-01-render` @ `cf6ccf98` (el informe de seguridad auditó `851a1417`; `ConvertidorPdf.cs` no cambió entre ambos en lo que aquí importa, verificado leyendo la versión actual). No se compiló ni se ejecutó nada.
Convención: **[V]** verificado leyendo código, documentos o la documentación XML del paquete; **[I]** inferido, sin ejecutar.

ADR y cláusulas: ADR-109 cl. 12 (privilegios mínimos; red saliente bloqueada salvo SQL Server y la principal); ADR-110 cl. 7 (sin JavaScript en gráfico y Liquid, solo recursos `data:`, *sandbox* activo, A-6; imágenes PNG/JPEG/GIF/WebP validadas al guardar **y al renderizar**); ADR-77 (P-77-2 y P-77-4: carpetas); ADR-129 bloque B (costura `*.Windows.cs`); ADR-76 PA-76-1 (privilegios). Decisiones del propietario del 2026-10-22: el perfil de Chromium va en `%ProgramData%\GPOS NG\Reportes\render` con la ACL de la cuenta del servicio de reportes (condición de T4-02 y de T4-03); el DEMO pasa a dos servicios (`NT SERVICE\GPOS.Api` y `NT SERVICE\GPOS.Reportes`).

---

## 1. Contexto y alcance

**Problema (S152-03 / H-T4-09, Media, condición de T4-02).** El render de T4-01 crea una página y carga el HTML sin desactivar JavaScript ni interceptar peticiones (`ConvertidorPdf.cs:40-43` [V]). Arranca Chromium con `--disable-gpu --no-first-run --disable-extensions --disable-dev-shm-usage` y nada que limite la red (`ConvertidorPdf.cs:106-110` [V]). Cualquier `<img src="http://…">`, `<link>`, `url()` de CSS, `<iframe>` o `<meta http-equiv=refresh>` de una plantilla Razor del SUPER, o un `Empresa.Logo` que no sea `data:` (S152-08: `GeneradorRazor.cs:101` emite `src="@Model.Empresa.Logo"` sin validar [V]), haría que el proceso de la API de reportes saliera a la red interna o a Internet. Eso es SSRF y un canal para sacar datos del documento en la URL. Contradice ADR-110 cl. 7 y ADR-109 cl. 12.

**Hallazgos que se cierran aquí:** S152-03, S152-08, S152-07 (perfil compartido en `%TEMP%` sin borrar; pestaña huérfana al cancelar) y la parte de S152-10 que afecta a la regla del cortafuegos.

**Fuera de alcance:** el validador Razor y sus referencias (S152-04, T4-10), los grupos de concurrencia (S152-02), la regla general de salida del servicio, «todo bloqueado salvo SQL» (O-5 del diseño del instalador, devops), y Razor en un proceso hijo.

**Cómo encaja con el plan.** El plan da a T4-03 2 dp, lo marca como recortable (`plan:291`, `:423` [V]) y lo pone después de T4-02 (`plan:373-374` [V]). El auditor y C condicionan la unión de T4-02 a T4-03 o a una aceptación de riesgo escrita (informe, S152-03). Hay dos desviaciones del plan, que se presentan como decisiones en la sección 12:
- el plan dice «T4-03 no lo apaga [el JavaScript]; lo resuelve la v2» (`plan:389` [V]). Este diseño lo apaga, porque la medición del rollo no depende del JavaScript de la página (sección 4.1);
- el plan ponía el perfil en `Reportes\temp` (`plan:142` [V]). El propietario lo fijó en `Reportes\render`.

## 2. Módulos y dependencias

| Pieza | Cambio | Depende de |
|---|---|---|
| `GPOS.Reportes.Api/Impresion/ConvertidorPdf.cs` | Capas 1 y 2, contexto por render, perfil, medición sin JavaScript | PuppeteerSharp 25.12.0 (ya referenciado; **sin paquetes nuevos**) |
| `GPOS.Reportes.Api/Impresion/PoliticaRedNavegador.cs` (nuevo) | Lista de argumentos, esquemas permitidos, CSP; funciones puras y probables | — |
| `GPOS.Reportes.Api/Impresion/ContencionNavegador.Windows.cs` (nuevo, `[SupportedOSPlatform("windows")]`) | Job Object (costura de ADR-129, bloque B) | Win32 `kernel32` (P/Invoke, sin paquete) |
| `GPOS.Reportes.Api/Impresion/ServicioRender.cs` | Saneado del modelo (logo) e inyección de la CSP | `GPOS.Contracts.ImagenDiseno` |
| `GPOS.Reportes.Api/Impresion/OpcionesRender.cs` | Opción interna de pruebas para apagar una capa (no se puede enlazar a la configuración) | — |
| `GPOS.Reportes.Api/Program.cs` | Preparar la carpeta `render` con `ComprobacionCarpetas` (como `temp`, `Program.cs:82-90` [V]) | `GPOS.Reportes.Exportacion.ComprobacionCarpetas` |
| `instalador/Reportes` (MSI, **no existe** [V: `instalador/` solo tiene `AgenteImpresion`, `Demo`, `Publicacion`, `SqlServer`]) | Regla del cortafuegos (capa 3) | devops; O-5 |
| `instalador/Demo` (scripts) | Dos servicios, carpeta `Reportes` con ACL, regla del cortafuegos | devops; Q-T4-05 |

Sin ciclos: `Impresion/*` no conoce `Endpoints/*`. `ComprobacionCarpetas` está en `GPOS.Reportes`, que la API ya referencia. No se crea ningún proyecto (`CLAUDE.md`, regla de proyectos nuevos) ni entra tecnología nueva (`CLAUDE.md`, regla del 2026-10-20). El Job Object, el cortafuegos de Windows y las opciones de Chromium son del sistema o del paquete que ya se usa.

## 3. C4

No aplica en los niveles de contexto y contenedores: no cambian. Componentes dentro del contenedor «API de reportes»:

```
ServicioRender ──(HTML saneado + CSP)──> ConvertidorPdf ──CDP (pipe o loopback)──> Chromium (cuenta NT SERVICE\GPOS.Reportes)
     │                                       │                                     │  capa 1: Fetch intercepta → solo data:/about:blank
     └─ valida Empresa.Logo (S152-08)        ├─ PoliticaRedNavegador (args, CSP)   │  capa 2: proxy muerto + resolvedor nulo
                                             └─ ContencionNavegador.Windows (Job)  │  capa 3: regla de salida por SID (instalador)
                                                                                   └─ perfil: %ProgramData%\GPOS NG\Reportes\render\perfil-xxxxxxxx
```

## 4. Diseño por capas

Las capas son independientes. Cada una bloquea sola la salida que cubre, y las pruebas apagan una a la vez (sección 9). Capa por capa:

| Capa | Dónde | Cubre loopback | Cubre la LAN e Internet | Si falla |
|---|---|---|---|---|
| 0. CSP en el documento | HTML | Sí | Sí | Depende de que Blink la respete |
| 1. Intercepción CDP y sin JavaScript | Navegador, por página | Sí | Sí | Error de PuppeteerSharp o del manejador |
| 2. Argumentos sin red | Navegador, por proceso | Sí (con `<-loopback>`) | Sí | Una opción de Chromium cambia de nombre entre versiones |
| 3. Regla del cortafuegos por SID | Sistema operativo | **No** (Windows no filtra el loopback [I, comportamiento conocido de WFP]) | Sí | Falta la regla (instalación manual o desarrollo) |

La capa 3 **no** protege el loopback, donde están la principal, SQL Server local y el puerto de depuración. Por eso las capas 1 y 2 son las obligatorias y la 3 es defensa en profundidad para la red externa.

### 4.1 Capa 1: solo `data:` y `about:blank`, sin JavaScript (obligatoria)

Flujo de `GenerarAsync` (sustituye `ConvertidorPdf.cs:39-43`):
1. `contexto = await navegador.CreateBrowserContextAsync()`: un contexto aislado (incógnito) **por render**, desechado en `finally` (S152-07). Así no comparten caché, cookies ni almacenamiento entre empresas ni entre renders. La API existe en 25.12.0 [V: `IBrowser.CreateBrowserContextAsync`, XML:7560].
2. `pagina = await contexto.NewPageAsync()`, **sin** `.WaitAsync(ct)` que la deje huérfana: si `ct` se cancela durante la creación, la página se desecha en cuanto termine de crearse (observación de C, S152-07).
3. `await pagina.SetJavaScriptEnabledAsync(false)` [V: existe, XML:11571], **antes** de cargar el contenido y **en todos los modos**. Para el modo Razor hace falta decisión: **[P] D-T403-2**.
4. `await pagina.SetRequestInterceptionAsync(true)` [V: XML:11585] y un manejador `Request` que:
   - continúa solo si `PoliticaRedNavegador.Permitida(url)`: esquema `data` o la URL exacta `about:blank` (también `about:srcdoc` si Chromium la emite para un `iframe srcdoc`; [I], lo decide la prueba);
   - aborta todo lo demás con `RequestAbortErrorCode.BlockedByClient`: `http`, `https`, `ws`, `wss`, `ftp`, **`file`**, `blob`, `filesystem`, `chrome`, `chrome-extension`, `edge` y cualquier esquema desconocido. Es una lista blanca: lo que no está permitido se aborta;
   - comprueba `IsInterceptResolutionHandled` antes de resolver y captura las excepciones. Un error del manejador termina en `AbortAsync`, nunca en `ContinueAsync` (falla cerrada);
   - registra el evento **5117 `NavegadorPeticionBloqueada`** (Warning) con el esquema, el anfitrión y el puerto, **sin la ruta ni la consulta** (pueden llevar datos del documento, C10), y con el formato y la empresa del token. Como máximo 5 eventos por render más un contador, para no inundar el registro. El número sale del rango libre 5117 a 5120 [V: hoy se usan 5101-5116, 5121-5127, 5130-5133 y 5140-5143 en `src/`; confirmarlo al construir].
   - Si Chromium no emite `requestPaused` para `data:` [I], el manejador no los ve y no pasa nada: la lista blanca no depende de verlos.
5. `SetContentAsync(html, …)` como hoy. **[I]:** PuppeteerSharp carga el contenido evaluando `document.open/write` desde CDP en un mundo aislado, y `Emulation.setScriptExecutionDisabled` no bloquea las evaluaciones de CDP, solo los scripts de la página. Lo comprueba la prueba P-05.
6. **Medición del alto del rollo** (`ConvertidorPdf.cs:50` [V]). `EvaluateExpressionAsync` es una evaluación de CDP, no JavaScript de la página. Se espera que funcione con JavaScript desactivado [I], pero no conviene depender de eso. **Diseño:** medir con `DOM.getDocument` → `DOM.querySelector("body")` → `DOM.getBoxModel` (la altura del `border` coincide con `getBoundingClientRect().height` [I]) por `pagina.Client.SendAsync`. Si falla, se usa la evaluación actual. La prueba P-06 compara con las alturas doradas de T4-01. Con esto se cae la razón por la que el plan dejaba el JavaScript activo (`plan:389`).
7. Al terminar, `finally`: se desechan la página y el contexto.

*Alternativas consideradas:*
- `LaunchOptions.Allowlist` (URLPattern en todo el navegador) [V: existe, XML:12907]. **Descartada como capa principal:** «Requires Chrome 149+» [V] y la versión de Chrome o Edge del cliente no la controlamos. Si falla, no se sabe si bloquea o deja pasar todo [I]. Se puede sumar más adelante sin costo.
- `SetOfflineModeAsync(true)` [V: existe]. **Descartada:** es una emulación de condiciones de red, no un límite de seguridad documentado, y no se sabe cómo interactúa con la intercepción [I].

### 4.1-bis Capa 0: CSP en el documento (barata, recortable)

`ServicioRender.HtmlAsync` inserta, **justo después de `<head …>`** (si falta, después de `<html …>`; si falta, después del `<!DOCTYPE …>`; si nada de eso existe, al principio), la etiqueta:

```html
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src data:; style-src 'unsafe-inline' data:; font-src data:; script-src 'none'; frame-src 'none'; child-src 'none'; form-action 'none'; base-uri 'none'">
```

- Nunca se inserta antes del `<!DOCTYPE>`: el documento pasaría a modo *quirks* y cambiaría el diseño [I, comportamiento HTML estándar].
- Una CSP de la plantilla solo puede sumar restricciones, nunca abrir lo que esta cierra (las políticas se intersecan).
- **Efecto en T4-01:** la prueba dorada `El_HTML_de_cada_formato_base_es_identico_antes_y_despues_del_traslado` compara el HTML **antes** de la inyección. La inyección se hace en un paso aparte (`AplicarPolitica(html)`) después de `MarcarCopia`.

### 4.2 Capa 2: argumentos de Chromium sin red (obligatoria)

Lista exacta (constante de `PoliticaRedNavegador.Argumentos`). Sustituye `ConvertidorPdf.cs:109`:

| Argumento | Para qué | Estado |
|---|---|---|
| `--disable-gpu` | Ya estaba | [V] |
| `--no-first-run` | Ya estaba | [V] |
| `--disable-extensions` | Ya estaba | [V] |
| `--disable-dev-shm-usage` | Ya estaba (no tiene efecto en Windows) | [V] |
| `--proxy-server=http://127.0.0.1:9` | Todo el tráfico va a un proxy local sin servicio y falla al conectar | [I] |
| `--proxy-bypass-list=<-loopback>` | Quita la excepción implícita del loopback: `localhost` y `127.x` también van al proxy muerto | [I] |
| `--host-resolver-rules=MAP * ~NOTFOUND` | Ningún nombre se resuelve (cubre la resolución previa y lo que no pase por el proxy) | [I] |
| `--disable-background-networking` | Sin tráfico propio del navegador (variaciones, *safe browsing*, actualizaciones de componentes) | [I] |
| `--disable-component-update` | Ídem | [I] |
| `--disable-sync` | Ídem | [I] |
| `--disable-domain-reliability` | Ídem | [I] |
| `--no-pings` | Sin `<a ping>` | [I] |
| `--dns-prefetch-disable` | Sin resolución previa (puede no tener efecto en las versiones recientes; no estorba) | [I] |
| `--force-webrtc-ip-handling-policy=disable_non_proxied_udp` | Sin UDP de WebRTC (además, sin JavaScript no hay WebRTC) | [I] |

**Nunca** van: `--no-sandbox`, `--disable-web-security`, `--allow-file-access-from-files`, `--allow-running-insecure-content`, `--disable-site-isolation-trials`, `--single-process`, `--no-zygote`, `--remote-debugging-address`, `--remote-allow-origins=*` ni `--user-data-dir` fuera de la carpeta `render`. La prueba P-08 lo comprueba sobre la línea de comandos **efectiva** del proceso, que incluye los argumentos que agrega PuppeteerSharp por omisión. Se lee de `IBrowser.Process` [V: la propiedad existe, XML:7518] o con `Browser.getBrowserCommandLine` de CDP [I].

**Puerto del proxy:** 9, fijo en el código y no configurable. Si un equipo tiene activos los «Servicios TCP/IP simples» (*discard* en el 9), la conexión no falla rápido: queda colgada hasta el plazo. Con la capa 1 activa no llega a intentarse. La prueba P-03 mide que falle en menos de 2 s en el equipo de pruebas. *Descartados:* el puerto 0 (Chromium podría considerar el proxy inválido e ignorarlo [I], que es el peor caso) y una IP de TEST-NET (sin RST: la conexión espera hasta el plazo).

**[I] crítico, P-03 lo decide:** que Chromium, con `--proxy-server` fijo, **no** recurra a la conexión directa cuando el proxy falla. Si recurriera, la capa 2 cambia a `--proxy-pac-url` con un PAC `data:` que devuelva solo `PROXY 127.0.0.1:9`, sin `DIRECT`.

**Transporte de CDP: canalización en lugar de puerto (recomendado; recortable).** Hoy PuppeteerSharp abre un puerto de depuración en `127.0.0.1` sin autenticación [I, comportamiento por omisión]. Cualquier proceso local que lo encuentre controla el navegador con la cuenta del servicio. Por ejemplo, podría navegar a `file://` y leer lo que esa cuenta puede leer en `%ProgramData%\GPOS NG\Reportes`. El cortafuegos no lo cubre (es loopback). En las instalaciones pequeñas el servidor también es una caja con cajeros que inician sesión. `LaunchOptions.Pipe = true` usa `--remote-debugging-pipe` [V: existe en 25.12.0, XML:12868; `PipeTransport`, XML:17825]. **[I]:** que funcione en Windows. La documentación habla de los descriptores 3 y 4, que es la forma POSIX. Si no funciona en Windows, se registra como riesgo R-T403-04 y se sigue con el puerto aleatorio.

### 4.3 Capa 3: regla del cortafuegos de Windows por la cuenta del servicio (sistema; la crea el instalador)

**Especificación de la regla.** El instalador crea cuatro reglas, una por ruta conocida, en el grupo «GPOS NG Reportes»:

| Campo | Valor |
|---|---|
| Nombre | `GPOS NG Reportes - Navegador sin red ({Chrome x64 \| Chrome x86 \| Edge x86 \| Edge x64})` |
| Dirección / acción | Salida / **Bloquear** (en Windows, el bloqueo gana sobre el permiso) |
| Perfiles / protocolo | Todos / cualquiera |
| Programa | Las cuatro rutas de `ConvertidorPdf.RutasConocidas()` (`ConvertidorPdf.cs:24-32` [V]), con `%ProgramFiles%` y `%ProgramFiles(x86)%` |
| Usuario local (`LocalUserAuthorizedList`) | SDDL `D:(A;;CC;;;<SID de NT SERVICE\GPOS.Reportes>)`; el SID lo da `CuentaServicioVirtual.Sid("GPOS.Reportes")` y no es secreto |

- Filtrar por **usuario local** y **programa** hace que la regla **no** afecte al Chrome o Edge de las personas, que corren con otro SID, ni al proceso .NET del servicio, que necesita SQL. En una cuenta virtual, el SID de usuario del token es el del servicio y los procesos hijos heredan el token [I]. Si el *sandbox* de red de Chromium corre en un AppContainer de baja privilegio [I, depende de la versión], todavía hay que comprobar que la condición de usuario se cumpla: **prueba de laboratorio L-2**.
- **Alternativa:** la condición «Servicio» (`-Service GPOS.Reportes`) en lugar de «Usuario local». Se descartó como primera opción porque no está claro que alcance a los hijos con token restringido [I]. Si L-2 muestra que la condición de usuario falla y la de servicio funciona, se cambia.
- **Alternativa descartada:** una sola regla sin programa para el SID del servicio. Cortaría también al proceso .NET y su conexión con SQL Server remoto, y para esa regla general hacen falta las excepciones de O-5.
- Si el operador configura `GPOS:Reportes:Render:Navegador` con otra ruta (S152-10), la regla no la cubre. **Recomendación:** en Release, aceptar solo las cuatro rutas conocidas o rutas bajo `%ProgramFiles%`/`%ProgramFiles(x86)%` y registrar la ruta usada. Es parte de la remediación de S152-10, cuesta 0,05 dp y va en T4-03b.

**Quién la crea:**

| Entorno | Responsable | Cómo | Estado |
|---|---|---|---|
| Cliente (paquete único) | devops, MSI `instalador/Reportes` (diseño `docs/operaciones/2026-10-19-diseno-instalador-reportes.md`, fila de cortafuegos `:88`, R7 `:173`, desinstalación `:241`, O-5 `:405` [V]) | `WixToolset.Firewall.wixext` **si** admite la salida y el usuario local (el diseño lo da por no admitido [V, `:405` y `:446`]); si no, una acción en `instalador/Comun/GPOS.Instalador.Acciones` (net472, excepción F-1 de `CLAUDE.md`) con la API COM `INetFwPolicy2` | **No existe**: dependencia abierta |
| DEMO (dos servicios) | devops, `instalador/Demo/scripts` (Q-T4-05) | `New-NetFirewallRule -Direction Outbound -Action Block -Program <ruta> -LocalUser "D:(A;;CC;;;<SID>)" -Group "GPOS NG Reportes"` al instalar y `Remove-NetFirewallRule -Group` al desinstalar [I: parámetros del módulo NetSecurity] | El DEMO actual no arranca la API de reportes (`Iniciar-Demo.ps1:9` [V]) |
| Desarrollo y pruebas | Nadie | Solo las capas 0 a 2 | — |

**Comprobación al arrancar (recortable, T4-03b).** El servicio lee la política de reglas sin modificarla y, si falta la regla de la ruta que usa, deja el evento **5118 `NavegadorSinReglaCortafuegos`** (Warning). **No** falla cerrado, porque las capas 1 y 2 bastan para el loopback y la red. [I]: que una cuenta virtual pueda leer las reglas sin ser administrador. Si no puede, la comprobación pasa a la lista R del instalador.

**Fuera de T4-03:** la regla general «salida del servicio solo hacia SQL Server» (ADR-109 cl. 12, O-5). La regla de Chromium no la sustituye; conviven.

## 5. Perfil y ACL (decisión del propietario del 2026-10-22)

- **Ruta:** `%ProgramData%\GPOS NG\Reportes\render\perfil-{8 hex}`, uno por arranque del navegador. **Ya no** se usa `Path.GetTempPath()` (`ConvertidorPdf.cs:101` [V]).
- **ACL:** `Reportes\` la crea el MSI con SYSTEM y Administradores en control total y la cuenta con `0x1301bf` (Modificar), sin herencia de la raíz (diseño del instalador `:86` [V]; SDDL de la raíz en `ComprobacionCarpetas.cs:36` [V]). `render\` la crea **el servicio, por herencia**, si el padre tiene la DACL protegida y pasa la comprobación (P-77-2), igual que `temp\`. La principal (`NT SERVICE\GPOS.Api`) no tiene acceso.
- **Comprobación al arrancar:** se reutiliza `ComprobacionCarpetas.PrepararTemporales(raiz, "Reportes", …\render, propia)` (`ComprobacionCarpetas.cs:142` [V]; el nombre del método es histórico, sirve para cualquier subcarpeta del componente) con la identidad verificada contra el token (`Program.cs:87-89` [V]). Si no cumple:
  - Release: **los formatos personalizados responden 503 `NAVEGADOR_NO_DISPONIBLE`** con el motivo en el registro (evento **5119 `CarpetaRenderRechazada`**, Critical). Los estándar de QuestPDF siguen funcionando, porque no usan Chromium (falla cerrada parcial, como la exportación con el 5112, `AlmacenTemporales.cs:64` [V]);
  - Desarrollo (`ComprobarCarpeta = false`, solo en Debug, `Program.cs:60-66` [V]): `Path.GetTempPath()\gpos-render`, como hoy.
- **Variables de entorno de Chromium:** `TEMP` y `TMP` apuntan a `perfil-x\tmp` (`LaunchOptions.Env` [V: existe]), para que los temporales del navegador (volcados de *crashpad* y descargas internas) no caigan en el perfil de la cuenta virtual, cuya ACL no se verificó (S152-07).
- **Limpieza:** al cerrar el navegador (`DisposeAsync`, reinicio por cierre inesperado) se borra su `perfil-x`. Al arrancar se borran los `perfil-*` huérfanos de una ejecución anterior (corte de energía), solo los que llevan ese prefijo y no son puntos de reanálisis. No se toca `temp\` (exportación, prefijo `gpos-exp-`).
- **Por qué no `temp\`:** la exportación limpia `temp\` por prefijo y su estado de habilitación es aparte. Una carpeta por propósito evita que una falla de una deshabilite la otra.

## 6. Job Object (recortable, T4-03b)

- `ContencionNavegador.Windows.cs`: `CreateJobObject` sin nombre, `JOBOBJECT_EXTENDED_LIMIT_INFORMATION` con `JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE | JOB_OBJECT_LIMIT_JOB_MEMORY` (1 GB [I], que mide `MedicionRender`) y `AssignProcessToJobObject(browser.Process.Handle)` justo después de `LaunchAsync`. El identificador lo conserva el proceso: si el servicio muere, el sistema cierra el identificador y mata a Chromium y a todos sus hijos.
- **Carrera [I]:** los procesos que Chromium cree antes de la asignación (GPU y red) quedan fuera del límite de memoria. Los renderizadores, que son los que consumen memoria, se crean al abrir la página, después de la asignación, y heredan el job. Windows 8 o posterior admite jobs anidados, así que no choca con los jobs del *sandbox* de Chromium [I].
- Si se supera la memoria, Chromium muere. El render responde 500 y el siguiente vuelve a lanzar el navegador (`_navegador is { IsClosed: false }`, `ConvertidorPdf.cs:89` [V]).
- **Alternativa descartada:** meter el propio servicio en un job heredable. Pondría también al proceso .NET bajo el límite de memoria, que ya tiene su `HeapHardLimit`.

## 7. Imágenes y recursos externos

| Fuente | Hoy | Con T4-03 |
|---|---|---|
| Imagen de un elemento del diseño gráfico | Se valida al generar: `data:image/(png\|jpeg\|gif\|webp);base64` y tope (`GeneradorRazor.cs:106-108`, `ImagenDiseno.Evaluar` [V]) | Sin cambios; además, las capas 0 a 2 |
| `Empresa.Logo` (todos los modos y formatos) | Se valida al guardar en la principal (`AdministracionService.cs:30-31,81` [V]); el render confía en el cuerpo (S152-08) | **`ServicioRender` sanea el modelo una vez, antes de cualquier formato:** si `ImagenDiseno.Evaluar(logo, tope: ParametrosDto.LargoMaximoLogo * 3 / 4)` no da `Valida`, el logo pasa a `null` y queda el evento 4790 `FormatoImagenOmitida` con el elemento `Empresa.Logo` y el motivo, sin el contenido. Tope: `LargoMaximoLogo = 700_000` caracteres, unos 512 KB decodificados (`GPOS.Contracts/Admin/Admin.cs:67` [V]). No se usa el tope de imagen del diseño (300 KB), para no omitir logos que la principal ya aceptó |
| `<img>`, `url()`, `@font-face`, `<link>`, `<iframe>`, `<object>`, `<meta refresh>`, `<base>` con URL externa o `file:` en una plantilla Razor | Se cargaban | Se abortan (capa 1), los niega la CSP (capa 0), no salen (capa 2) y, fuera del loopback, los bloquea la regla (capa 3). El PDF sale sin ese recurso; el render **no** falla |
| `data:image/svg+xml` en una plantilla Razor del SUPER | Se carga | Se permite (`img-src data:`): en `<img>` el SVG no ejecuta código ni carga recursos [I, estándar]. La restricción PNG/JPEG/GIF/WebP de la cl. 7 es para las imágenes que incrusta el ADMIN, que ya se valida |
| SVG de códigos de barras y QR | En línea, los genera el servidor | Sin cambios |
| Fuentes | Del sistema | Sin cambios; `@font-face` solo con `data:` |

## 8. Requisitos de seguridad de arquitectura

- **Autenticación y autorización:** sin cambios (introspección y canalización de T4-01; S152-01 se cierra en el #152).
- **Aislamiento entre empresas:** un contexto de navegador por render (sin caché ni cookies compartidas); el perfil en una carpeta de la cuenta del servicio; el registro del render con la empresa y el usuario del token.
- **Secretos:** ninguno nuevo. La URL bloqueada se registra sin la ruta ni la consulta (C10).
- **Privilegios:** el *sandbox* sigue activo (cl. 7, A-6). La prueba con la cuenta del servicio se hace en el laboratorio (L-1, R-T4-07).

## 9. Pruebas

Ubicación: `tests/GPOS.Reportes.Tests/ChromiumAisladoTests.cs`. Se omiten sin Chrome ni Edge, con el mismo `Skip` de `RenderInternoTests.cs:565` [V]. Cada prueba de red usa un `TcpListener` en `127.0.0.1` con un puerto aleatorio y espera hasta 3 s una conexión. Es loopback a propósito: así se prueban las capas que lo cubren. `AuditoriaAdr109Tests.La_API_de_reportes_no_abre_conexiones_salientes…` (`:200-216` [V]) solo recorre `src/` y sigue en verde: el `TcpListener` está en `tests/`.

| ID | Prueba | Qué comprueba |
|---|---|---|
| P-01 | `Una_imagen_http_en_un_formato_no_sale_a_la_red` (**H-T4-09**, la de la tarea) | Una plantilla Razor con `<img src="http://127.0.0.1:{p}/x.png">` produce el PDF, el *listener* recibe 0 conexiones y queda un 5117 con `http://127.0.0.1:{p}` sin la ruta |
| P-02 | `Ningun_recurso_externo_sale_a_la_red` (teoría) | `<link>`, CSS `url()`, `@font-face`, `<iframe>`, `<object>`, `<meta refresh>`, `<base href>`; anfitriones `127.0.0.1`, `localhost` y `gpos-prueba.invalid`: 0 conexiones |
| P-03 | `La_capa_2_sola_corta_la_red` | Con la capa 1 y la CSP apagadas por la opción interna: 0 conexiones y falla en menos de 2 s. **Decide el [I] del recurso a la conexión directa** |
| P-04 | `La_capa_1_sola_corta_la_red` | Con los argumentos de red quitados (opción interna): 0 conexiones |
| P-05 | `El_JavaScript_no_se_ejecuta_en_ningun_modo` | Un `<script>` que cambia `document.title` en el modo visual y en el Razor: el título no cambia (se lee por CDP) |
| P-06 | `El_alto_del_rollo_es_el_mismo_sin_JavaScript` | 13 tipos en 80 y 58 mm: el alto medido con `DOM.getBoxModel` es igual al dorado de T4-01, con tolerancia de 0,5 mm |
| P-07 | `Un_archivo_local_no_se_carga` | `<img src="file:///…">` y `<iframe src="file:///…">` a un archivo de prueba: abortado y registrado |
| P-08 | `Los_argumentos_nunca_desactivan_el_sandbox` (del plan) | La línea de comandos **efectiva** no tiene ninguno de los prohibidos de 4.2 y sí los de red |
| P-09 | `Cada_render_usa_un_contexto_propio_y_lo_desecha` | Tras N renders, los contextos vuelven al por omisión; cancelar a mitad de la creación no deja páginas abiertas |
| P-10 | `El_perfil_va_en_render_y_se_borra` / `Los_perfiles_huerfanos_se_borran_al_arrancar` | Con una raíz temporal (patrón de `SeguridadTramo2Tests.cs:200-270` [V]) |
| P-11 | `Sin_carpeta_render_valida_los_personalizados_responden_503_y_los_estandar_funcionan` | El 503 `NAVEGADOR_NO_DISPONIBLE`, el evento 5119 y que el ticket estándar sigue saliendo |
| P-12 | `Un_logo_que_no_es_data_uri_de_imagen_se_omite` (S152-08) | `http://`, `data:image/svg+xml` y base64 inválido: el logo se omite, queda el 4790 y no hay conexión; un PNG válido se imprime |
| P-13 | `El_navegador_corre_en_un_Job_Object` (del plan; `[SupportedOSPlatform("windows")]`; T4-03b) | `IsProcessInJob` del navegador y de un renderizador |
| P-14 | `ArquitecturaReportesTests.La_politica_de_red_del_navegador_es_la_del_contrato` | Prueba de texto: los argumentos y la CSP son las constantes de `PoliticaRedNavegador` y nadie más llama a `Puppeteer.LaunchAsync` |

**Laboratorio** (lista manual, máquina virtual del laboratorio de ADR-90; nunca la PC del propietario):
- L-1: *sandbox* activo con `NT SERVICE\GPOS.Reportes` (ADR-110 cl. 7, A-6);
- L-2: con la regla de 4.3 y una compilación de laboratorio con las capas 1 y 2 apagadas, una imagen a una IP de la LAN no sale. Con un Chrome de usuario, la misma imagen sí carga. Si falla la condición de usuario, se prueba la de servicio;
- L-3: el transporte por canalización (`Pipe = true`) funciona como servicio;
- L-4: tiempo de render P95 con la intercepción y el contexto por render, con `MedicionRender.P95_ticket_80_mm_y_factura_carta` (`plan:118` [V]).

## 10. Necesidades para Datos e Integraciones

- **Datos:** ninguna de esquema. Opcional (arquitecto-datos o desarrollador, 0,05 dp): una consulta de diagnóstico de solo lectura que liste los `conf.FormatoImpresion` con `http:`, `https:`, `file:`, `url(` o `<script` en la plantilla, para avisar antes de publicar el DEMO.
- **Integraciones:** no aplica.

## 11. Riesgos

| ID | Riesgo | Prob./Impacto | Mitigación |
|---|---|---|---|
| R-T403-01 | Chromium recurre a la conexión directa si el proxy falla, o una opción cambia de nombre en una versión futura de Chrome o Edge (el cliente actualiza solo) | Baja / Alto | Tres capas independientes; P-03 y P-04 en cada suite con el navegador del equipo; el PAC `data:` como plan B |
| R-T403-02 | La medición sin JavaScript cambia el alto del rollo | Media / Medio | P-06 contra los dorados; si falla, la evaluación de CDP se queda (no es JavaScript de la página) |
| R-T403-03 | La regla de usuario local no alcanza a los procesos de Chromium con token restringido o AppContainer | Media / Bajo (las capas 1 y 2 ya cortan) | L-2; la alternativa por servicio |
| R-T403-04 | El puerto de depuración en loopback queda abierto a procesos locales si `Pipe` no funciona en Windows | Media / Medio | L-3; si falla, aceptarlo y volver a revisarlo en la v2 |
| R-T403-05 | Sin instalador (no existe), el DEMO y las instalaciones manuales quedan sin capa 3 | Cierta hasta que exista / Bajo | Script del DEMO (devops); 5118 al arrancar |
| R-T403-06 | La intercepción y el contexto por render añaden latencia al ticket personalizado | Media / Bajo | L-4; estimado de 10 a 40 ms por render [I], frente al presupuesto de 30 s |
| R-T403-07 | La carpeta `render` mal creada en el DEMO deja los personalizados en 503 | Media / Medio | P-11 avisa; el script del DEMO crea `Reportes\` con la ACL; la lista R3 del instalador |
| R-T403-08 | Capacidad: el plan pone T4-03 después de T4-02 (11-23), pero la condición de seguridad lo pide antes | Alta / Medio | D-T403-1 |

## 12. Decisiones

**Requieren firma del propietario [P]:**

**D-T403-1 [P]. Cómo se cumple la condición «T4-02 no se une sin T4-03 o sin una aceptación de riesgo escrita».**
- **(a, recomendada)** Dividir T4-03:
  - **T4-03a**, *núcleo*, **condición de unión de T4-02**: perfil en `render` con ACL (que ya es condición de T4-02 por la decisión del 2026-10-22), capas 1 y 2, JavaScript apagado, logo (S152-08), contexto por render y las pruebas P-01 a P-12. **1,6 dp.** Se une antes de T4-02 (depende solo de T4-01).
  - **T4-03b**, *recortable* después del corte: Job Object, canalización de CDP, CSP, comprobación de la regla al arrancar, ruta del navegador limitada (S152-10) y P-13. **1,0 dp.**
  - Costo: T4-02 se retrasa entre 1 y 1,5 días respecto del calendario (11-16) si no hay un cupo de compilación libre antes [I].
- **(b)** Unir T4-02 con una aceptación de riesgo escrita hasta que se una T4-03 completo, como tarde el 12-04 (G-O5-T4). Condiciones: ninguna publicación a un cliente sin T4-03a (ya se cumple: DB-7 es condición del primer cliente) y el DEMO sin formatos Razor con recursos externos (consulta de la sección 10). Riesgo residual en esas dos semanas: SSRF solo desde una plantilla del SUPER, porque el logo ya lo valida la principal.
- **(c)** T4-03 completo antes de T4-02 (2,6 dp): T4-02 se retrasa unos 3 días.

**D-T403-2 [P]. JavaScript también apagado en el modo Razor del SUPER.** ADR-110 cl. 7 lo exige solo en los modos gráfico y Liquid.
- **(a, recomendada)** Apagarlo en todos los modos. Ninguna plantilla base usa `<script>` [V: no hay `<script` ni URL externa en `src/GPOS.Contracts/Impresion` ni en las plantillas de impresión].
  - **Qué rompe:** una plantilla Razor del SUPER que use `<script>` deja de ejecutarlo.
  - **A quién afecta:** solo al SUPER. Hoy no hay clientes y BP2 nunca salió a producción.
  - **Por qué se justifica:** el JavaScript solo servía para medir el rollo, y eso se hace por CDP. Con JavaScript, además, una plantilla puede generar peticiones que la capa 0 no ve.
  - **Cómo se migra:** el cálculo pasa a la plantilla Razor, del lado del servidor.
  - Corresponde una precisión de la cl. 7 de ADR-110.
- **(b)** Dejarlo activo en Razor (lo que dice el plan, `:389`). Las capas 1 a 3 siguen cortando la red.

**Técnicas, sin firma (las decide el equipo B, y el auditor las revisa):** el puerto 9 del proxy; DOM.getBoxModel para medir; los eventos 5117 a 5119; la canalización de CDP si L-3 la confirma; la regla por usuario local frente a la regla por servicio (L-2).

**Qué rompe, a quién afecta y cómo se migra (todo T4-03):**

| Qué rompe | A quién afecta | Por qué se justifica | Cómo se migra |
|---|---|---|---|
| Las imágenes, hojas de estilo y fuentes por URL externa en las plantillas Razor dejan de cargarse | SUPER; en el diseño gráfico ya no se permitían | ADR-110 cl. 7 y ADR-109 cl. 12, ya firmados | Incrustarlas como `data:`. El diseñador ya incrusta las imágenes. Consulta de la sección 10 |
| El logo de la empresa que no es una imagen `data:` válida no se imprime | Nadie en la práctica (la principal ya lo valida) | S152-08 | Volver a subir el logo |
| `<script>` en Razor (si D-T403-2 (a)) | SUPER | La de D-T403-2 | La de D-T403-2 |
| Los formatos personalizados en 503 si `Reportes\render` no cumple ADR-77 | Instalaciones manuales y el DEMO mal preparado | Decisión del propietario del 2026-10-22 | El script del DEMO o el MSI crean `Reportes\` con la ACL. Los formatos estándar no se afectan |
| Lo que el usuario ve en la pantalla de impresión | Nada | — | — |

## 13. Estimación

Inferida, ±30 %, calibrada con las 2 dp del plan y los 0,5 a 1 dp del auditor para las capas 1 y 2.

| Bloque | dp | Parte |
|---|---|---|
| Capa 1, JavaScript apagado, contexto por render, página huérfana | 0,5 | a |
| Medición sin JavaScript | 0,15 | a |
| Capa 2 (argumentos y política) | 0,15 | a |
| Perfil en `render`, ADR-77, limpieza, `TEMP` | 0,3 | a |
| Logo (S152-08) | 0,1 | a |
| Pruebas P-01 a P-12 y P-14 | 0,4 | a |
| **Subtotal T4-03a** | **1,6** | |
| Job Object y P-13 | 0,4 | b |
| Canalización de CDP (con L-3) | 0,2 | b |
| CSP (capa 0) y ajuste de los dorados | 0,1 | b |
| Comprobación de la regla al arrancar y ruta del navegador limitada | 0,15 | b |
| Revisión y correcciones | 0,15 | b |
| **Subtotal T4-03b** | **1,0** | |
| **Total T4-03** | **2,6** (el plan decía 2) | |

Fuera de T4-03, de devops:
- regla en el MSI: 0,10 sp, ya contada en INS 9.2 (`instalador:318` [V]);
- regla y carpeta en el script del DEMO: unos 0,25 dp, dentro de Q-T4-05;
- laboratorio L-1 a L-4 (QA o devops): unos 0,5 dp.

Costo en licencias e infraestructura: USD 0. Sin paquetes nuevos.

---

### Cierre
- Estado: Completado (diseño, sin compilar)
- Artefactos: `C:\Users\lfmen\AppData\Local\Temp\claude\C--Users-lfmen-source-repos-Solucion-GPOS-NG-GPOS-NG\a8083c99-fe36-432e-bde4-46ec95e0ccbd\scratchpad\t4-03-blueprint.md` (no se modificó el repositorio)
- Supuestos:
  - no está comprobado el comportamiento de Chromium con `--proxy-server` y `<-loopback>` (que no recurra a la conexión directa), ni que las evaluaciones de CDP funcionen con el JavaScript desactivado, ni que `Pipe` funcione en Windows, ni que la regla de usuario local alcance a los hijos con *sandbox*. Todo [I], con su prueba asignada;
  - los eventos 5117 a 5119, libres según la búsqueda en `src/`;
  - el tope del logo derivado de `LargoMaximoLogo`.
- Decisiones candidatas a ADR:
  - precisión de ADR-110 cl. 7: JavaScript apagado también en Razor (D-T403-2);
  - precisión de ADR-109 cl. 12: Chromium sin red en tres capas; la capa de cortafuegos por usuario local, sin cubrir el loopback (alternativa descartada: solo el cortafuegos).
- Entregas a otros agentes:
  - **propietario:** D-T403-1 y D-T403-2;
  - **desarrollador de B:** construir T4-03a y T4-03b;
  - **devops:** regla del cortafuegos en el MSI (O-5) y en el script del DEMO, y la carpeta `Reportes` con su ACL para los dos servicios (Q-T4-05);
  - **QA / C:** P-01 a P-14 y el laboratorio L-1 a L-4;
  - **auditor-seguridad:** revisar la lista de argumentos, la regla y el riesgo R-T403-04;
  - **arquitecto-datos:** la consulta de diagnóstico de la sección 10 (opcional).
- Próximo paso recomendado: llevar D-T403-1 y D-T403-2 a la firma antes de que T4-02 llegue a revisión (11-13).
