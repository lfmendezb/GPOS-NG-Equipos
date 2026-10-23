# Revisión de seguridad del PR #170, rango `f534e7f0..4d676907` (condiciones S170 y T4-03b parcial)

- Fecha: 2026-10-22 · Revisor: auditor-seguridad (equipo A), con Opus
- PR: #170, rama `b/ola5-t4-03a`. Rango de cuatro commits: `24faa356` (capa 0 y M-170-1), `53e8ce7b` (S152-02 C-02-1/C-02-3), `15b85f4f` (S170-01/02/06/07/08) y `4d676907` (EventId 5156). Son 13 archivos, +1235/-44.
- Método: revisión estática en el checkout de solo lectura `GPOS-NG-r170` (`git diff f534e7f0..HEAD` y lectura de los archivos en la punta). No compilé, no ejecuté pruebas y no lancé Chromium. Los resultados de las pruebas (192/192; 7 mutaciones, de las que se detectaron 6) son los que declara B y no los comprobé.
- Marcas: [V] verificado leyendo el código; [I] inferido (comportamiento de Chromium, .NET o Windows que no comprobé ejecutando nada).
- Hallazgos previos: `traspasos/A/revision-seguridad-pr170-t4-03a-2026-10-22.md`. Aviso de B: `avisos/B-a-A/2026-10-22-170-condiciones-y-t4-03b.md`.

## 1. Resumen y recomendación

**Recomendación: Aprobar con condiciones.** Es una recomendación técnica; la firma es del propietario (C2).

Las dos condiciones previas a la unión de la revisión anterior (S170-01 y S170-02) quedan **cerradas**. También S170-06, S170-07 y S170-08, con dos observaciones menores. El desvío del dueño de `render` es **aceptable** (ver la sección 2).

No encontré hallazgos Críticos ni Altos. Encontré **2 Medios** y **4 Bajos** nuevos:

- **O170-01 (Media):** la capa 0 se puede evadir. Su analizador difiere del de HTML en las referencias de caracteres (las con nombre de HTML5 y las numéricas largas) y no mira los documentos anidados (`srcdoc` codificado y marcos `data:`). Mientras la capa 2 esté en pie no sale nada a la red. Pero la capa 0 es justo la barrera para cuando la capa 2 falle (S170-03), y su comentario afirma que lee «como el analizador de HTML», cosa que no se cumple.
- **O170-02 (Media):** C-02-3 cuenta como huérfano todo render personalizado cancelado que aún está cerrando su contexto. Dos cancelaciones cercanas bastan para pedir el reinicio controlado, que queda enclavado. Sin la recuperación del servicio (C-02-4), el servicio queda detenido, también para los estándar.

Condiciones que propongo:

- **O170-01**: arreglarlo antes de habilitar formatos personalizados de terceros fuera del DEMO. Es barato: unas 0,5 jornadas.
- **O170-02**: arreglarlo antes de que T4-02 conecte la principal con cancelación. Unas 2 horas.
- Los Bajos pueden pasar a T4-03b.

**EventId 5156:** confirmado. Es el único uso en `src/` (`ConvertidorPdf.cs:51` [V]). El 5120 de `TurnosRender.cs:31` también es único hoy; B lo renumera a 5157 en un commit aún no empujado y no lo trato como hallazgo.

## 2. Cierre de los hallazgos previos

| ID | Estado | Evidencia y comentario |
|---|---|---|
| **S170-01** | **Cerrado** [V], con un riesgo residual Bajo (O170-04) | `PrepararCarpeta` usa `PrepararPrivada` (`ConvertidorPdf.cs:100-104`). `PrepararPrivada` (`ComprobacionCarpetas.cs:170-187`) hace cuatro cosas: comprueba los padres como antes (`:175`); comprueba `render` si ya existe, con `EvaluarLectores` sobre el mismo identificador (`:145-150`, `:212`); si no existe, la crea con un descriptor **atómico** en el `CreateDirectory` (`:156-161`, `SddlPrivada` `D:PAI` con SY, BA y el SID del servicio con `0x1301bf`, `:64-65`); y la **vuelve a comprobar después** (`:186`). Esa comprobación posterior cierra la carrera entre comprobar y crear: si otro la crea antes con herencia, `Create` no hace nada [I: comportamiento de `FileSystemAclExtensions.Create`] y la segunda comprobación la rechaza. `EvaluarLectores` (`:109-129`): la máscara `FILE_READ_DATA/LIST_DIRECTORY`, `GENERIC_READ` y `GENERIC_ALL` es correcta para una carpeta. `WRITE_DAC` y `WRITE_OWNER` ya los rechaza `Evaluar` como escritura (`0x500D0156`). Una DACL nula o una ACE que no se puede evaluar cuentan como lector ajeno (falla cerrada). Las ACE heredadas y las solo heredables también se evalúan. Los perfiles heredan la DACL protegida (prueba `ChromiumAisladoTests.cs:1101-1104`). **Desvío del dueño, aceptable:** fijar SYSTEM como dueño exige `SeRestorePrivilege`, que una cuenta virtual no tiene [I, conocido de Windows], y ADR-77 ya admite la identidad declarada como dueña dentro del componente (`Evaluar`, `:82-84`). El riesgo que deja es que el dueño tiene `WRITE_DAC` implícito sobre `render` y cada `perfil-*` (O170-04). **Nota funcional:** si el proceso no corre con la identidad declarada (`propia` null, `Program.cs:90`), la carpeta recién creada falla en `Evaluar`, porque la ACE de escritura del SID del servicio no se admite. Da 503 (falla cerrada, no es un agujero). **Ruptura declarada por B:** una `render` heredada de una versión anterior da 503 hasta borrarla (entrega a devops) |
| **S170-02** | **Cerrado** [V] | Los vectores `srcdoc`, `frameset`, `iframe loading=lazy` (arriba y abajo) e `img loading=lazy` se prueban con la capa 1 sola y cada uno tiene la expectativa correcta: corta, o da el PDF sin conexiones (`ChromiumAisladoTests.cs` en `MarcosS17002`, hacia `:1020-1055`). La frase «cada capa corta sola» se corrigió en la documentación: ahora vale para las peticiones de recursos y no para las sugerencias ni para los WebSocket (`PoliticaRedNavegador.cs:20-28`, `ConvertidorPdf.cs:29-31`) |
| **M-170-1** | **Cumplida en pruebas y documentación** [V]; **la capa 0 es evadible** (O170-01) | P-03 tiene los seis vectores (`preconnect`, `dns-prefetch`, `prefetch`, `prerender`, `modulepreload` y `speculationrules`), con el JavaScript apagado y encendido, contra 127.0.0.1 y `localhost`. P-04 documenta la limitación de la capa 1: `preconnect`, `prefetch` y `prerender` llegan, sin 5117. Hay una prueba de extremo a extremo de la capa 0 y una que comprueba que no cambia los dorados (`ReferenceEquals`). La capa 0 está cableada al final de `HtmlAsync`, después de `MarcarCopia`, en los dos modos, Razor y gráfico (`ServicioRender.cs:44-52`). El contenido entra por `SetContentAsync` como cadena (`ConvertidorPdf.cs:164`): no hay cabecera HTTP `Link` ni reinterpretación del juego de caracteres. Lo bueno del diseño: **lee las etiquetas sin contexto y repite hasta el punto fijo**, así que quitar de más nunca abre nada. Mayúsculas, atributos sin comillas, `/` como separador, `rel` repetido, `<link>` en el `body` o en comentarios y etiquetas que se forman al quitar otras quedan bien cubiertos (pruebas hacia `:1300-1360`). Ver O170-01 para lo que no cubre. `dns-prefetch` en P-03 y P-04 solo prueba que no hay conexión: la escucha no ve una resolución de nombre. Lo admite el comentario (`ChromiumAisladoTests.cs` en `Sugerencias`) |
| **S170-06** | **Cerrado** [V] | `Convert.ToHexStringLower(RandomNumberGenerator.GetBytes(16))` da 128 bits (`ConvertidorPdf.cs:414`; `net10.0`). Primero comprueba que el perfil no existe: `Path.Exists` tampoco sigue un enlace colgante [I] (`:415`). Después de crear el perfil y su `tmp`, comprueba que ninguno es un punto de reanálisis (`:420-425`). Se llama fuera del `try`, así que una excepción corta el lanzamiento (`:356`). Residual (Bajo, sin cambio): el identificador de `render` no se retiene entre la comprobación y el uso (`ComprobacionCarpetas.cs:147-148`). Cambiarlo exige escribir en `Reportes`, y eso solo lo pueden hacer cuentas admitidas |
| **S170-07** | **Cerrado** [V] | Toda variable que no está en `EntornoPermitido` llega vacía (`ConvertidorPdf.cs:369-372`; lista en `PoliticaRedNavegador.cs:95-101`, sin `GPOS*`, `ConnectionStrings*`, `ASPNETCORE_*` ni `DOTNET_*`). La prueba lee `Process.StartInfo.Environment` con una variable `GPOS__…` sembrada (`ChromiumAisladoTests.cs`, `El_navegador_no_hereda_el_entorno_del_servicio`): detectaría que se quitara el bucle. Solo se filtran los nombres de las variables, no sus valores; es aceptable |
| **S170-08** | **Cerrado** [V], con O170-03 (Bajo) | `Browser.getBrowserCommandLine` se lee al lanzar (`ConvertidorPdf.cs:375`, `:435-456`). `ProblemaLineaComandos` (`PoliticaRedNavegador.cs:76-89`) rechaza: un prohibido; que falte un argumento de la capa 2 (sin comillas) o `--remote-debugging-pipe`; o que haya más de un `--user-data-dir`, o uno que no sea exactamente el perfil, que es el caso de la ruta partida en «GPOS NG». La falla es cerrada: desecha el navegador, borra el perfil, deja el 5156 crítico y lanza `NavegadorNoDisponibleException`, que da 503 (`ConvertidorPdf.cs:375-389`). Si la lectura falla, también se rechaza (`:452-455`). La ruta con espacios se prueba de verdad con Chromium (`Con_una_ruta_con_espacios_el_perfil_no_se_parte`). El registro no lleva datos sensibles: la ruta del ejecutable y el motivo |
| **S152-02 C-02-1** | **Cerrado** [V] | Hay dos semáforos separados (`TurnosRender.cs:43-45`). El grupo sale del contenido de la solicitud: con formato, personalizado; sin él, estándar (`EndpointsRender.cs:48-50`). Pedir el estándar con un formato no es posible, porque el mismo campo decide el camino de `DocumentoAsync` (`ServicioRender.cs:29`). El estándar tiene como mínimo 2 cupos. Las pruebas cubren el grupo personalizado lleno con los estándar en 200 |
| **S152-02 C-02-3** | **Construido** [V], con O170-02 (Media) | Huérfano, 5120 sin el contenido de la plantilla, 503 `RENDER_REINICIANDO` en `/api/salud` y en los personalizados, los estándar siguen, y salida con el código 3 (`TurnosRender.cs:77-88`, `:113-135`; `ServiciosLectura.cs:52-55`). Las ganchos de prueba (`CompuertaPersonalizado`, `AlReiniciar`) son `internal` y delegados: la configuración no los puede enlazar (`OpcionesRender.cs:79-88`) |

## 3. Tabla resumen de hallazgos nuevos

| ID | Severidad | Título |
|---|---|---|
| O170-01 | Media | La capa 0 se evade con referencias de caracteres que no decodifica y con documentos anidados que no mira |
| O170-02 | Media | C-02-3 cuenta como huérfanos los renders cancelados que solo están cerrando: reinicio por falso positivo, enclavado |
| O170-03 | Baja | Rechazo de la línea de comandos: puede dejar un Chromium vivo, se relanza en cada petición y no normaliza los prefijos `-` y `/` |
| O170-04 | Baja | El dueño de `render` y de los perfiles es la cuenta del servicio: tiene `WRITE_DAC` implícito |
| O170-05 | Baja | La capa 0 es cuadrática en el peor caso y no tiene tope de tamaño |
| O170-06 | Baja | Mutaciones que las pruebas nuevas no detectarían |

Observación sin severidad: `/api/salud` es anónima y su comentario dice «no dice por qué», pero ahora devuelve `codigo = RENDER_REINICIANDO` (`ServiciosLectura.cs:47-55`). La fuga es mínima (un estado transitorio) y basta con alinear el comentario o devolver un 503 genérico.

## 4. Hallazgos

### O170-01 · Media · La capa 0 se puede evadir

**Riesgo.** La capa 0 decide con su propio analizador si un `<link>` lleva `preconnect`, `prefetch` o `prerender`. Las sugerencias que Chromium sí procese y la capa 0 deje pasar abren conexiones que la capa 1 no ve (P-04). En ese caso solo queda la capa 2, que una directiva de grupo de proxy puede anular (S170-03, sin construir). Con eso, una plantilla de un diseñador o del SUPER saca datos del documento en el nombre del anfitrión.

**Evidencia.** Hay tres diferencias con el analizador de HTML:

1. **Referencias con nombre de HTML5.** `Decodificar` usa `WebUtility.HtmlDecode` (`PoliticaRedNavegador.cs:276`), que solo conoce las entidades de HTML 4.01 más `&apos;` [I, implementación de .NET; se confirma con una prueba de una línea]. HTML5 agrega, entre otras, `&Tab;` y `&NewLine;`, que el navegador decodifica como separadores del valor de `rel`. Un `rel` con una palabra cualquiera, uno de esos separadores y `preconnect` queda para el navegador como dos fichas, y una es `preconnect`. Para la capa 0 es una sola ficha desconocida (`RelQuitado`, `:280-282`). Lo mismo pasa con `type` de las reglas de especulación (`:285-287`). Con el JavaScript apagado, P-04 dice que esas reglas no salen, así que ahí el impacto es menor.
2. **Referencias numéricas largas.** La expresión acepta de 1 a 6 dígitos hexadecimales o de 1 a 7 decimales (`:263`). El analizador de HTML acepta cualquier número de ceros a la izquierda [I, regla del estándar de HTML]. Una referencia con ceros de relleno que el navegador lee como una letra, la capa 0 la parte: decodifica un prefijo y deja los dígitos sobrantes como texto. Las pruebas solo cubren referencias cortas (`ChromiumAisladoTests.cs`, casos `&#112;`, `&#x70` y `&#45;`).
3. **Documentos anidados.** La capa 0 solo busca un `<` literal (`:176`):
   - un `<iframe srcdoc>` con el documento interior escrito con `&lt;…&gt;` (la forma normal de escribir un `srcdoc`) pasa sin tocarse, y el navegador analiza ese interior como documento. Ahí las sugerencias funcionan [I]. La prueba de `srcdoc` solo comprueba peticiones de recursos, no sugerencias;
   - un marco con `data:text/html;base64,…` también pasa. M-170-2 corta el render, pero lo más probable es que el documento interior ya haya empezado a analizarse y la conexión anticipada salga antes del corte [I]. El corte evita el PDF, no el efecto.

**Remediación (la más barata que lo cierra; unas 0,5 jornadas).** Pasar de lista negra a lista blanca, sin decodificar de más:

- Un `<link>` solo queda si su `rel` crudo no contiene `&` y sus fichas están en {`stylesheet`} (o {`stylesheet`, `icon`} si algún formato lo usa). Todo lo demás se quita. Esto cubre también `preload`, `compression-dictionary` y futuros `rel` que Chromium agregue.
- Quitar **todo** `<script>`: el JavaScript está apagado en todos los modos (D-T403-2), así que no sirven para nada.
- Rechazar con 400 `FORMATO_INVALIDO` la plantilla que tenga etiquetas `iframe`, `frame`, `frameset`, `object`, `embed`, `portal` o `fencedframe`. Los nombres de etiqueta no admiten referencias de caracteres, así que esta comprobación no se puede disfrazar y cierra `srcdoc` y los marcos `data:` de una vez. Los formatos no necesitan marcos.
- Agregar las tres familias de vectores a las pruebas sin navegador.

Alternativa descartada: usar un analizador HTML5 completo (AngleSharp, MIT, muy usado). Elimina la diferencia de raíz, pero vuelve a serializar el HTML y rompe la igualdad exacta con los dorados. Agrega además una dependencia para un problema que la lista blanca resuelve con unas 40 líneas.

### O170-02 · Media · Huérfanos por falso positivo en C-02-3

**Riesgo.** `Abandonado` cuenta un huérfano cuando el punto final deja de esperar y el trabajo no ha terminado (`EndpointsRender.cs:97-104`, `TurnosRender.cs:79-85`). Pero cuando la principal corta (`RequestAborted`), el trabajo casi nunca ha terminado en ese instante:

- `GenerarAsync` observa la cancelación, pero todavía ejecuta `CerrarContextoAsync` en el `finally` (`ConvertidorPdf.cs:190-194`), lo que tarda decenas o cientos de milisegundos [I];
- si la cancelación llega durante la primera compilación de una plantilla, que es síncrona y de 1 a 3 s [I], el trabajo sigue vivo varios segundos.

Dos cancelaciones solapadas de renders normales bastan para llegar a `TopeHuerfanos = 2`, que es el valor por omisión. El pedido de reinicio queda **enclavado** (`TaskCompletionSource`, `TurnosRender.cs:46,85`): no se deshace cuando los «huérfanos» terminan un instante después. El servicio sale con el código 3 (`:133-134`). Sin la recuperación del servicio (C-02-4, del instalador, pendiente), queda **detenido**, y con él los tickets estándar del POS.

**Evidencia.** Que la principal propague la cancelación del cajero es [I]: el cliente de la principal llega en T4-02 y no está en este rango. Hoy el disparador real es el plazo de 30 s. Ninguna prueba cubre un render cancelado que termina poco después (O170-06).

**Remediación (unas 2 horas).**

- Contar un huérfano solo si el trabajo sigue vivo pasado un periodo de gracia, por ejemplo 5 s (`await Task.WhenAny(trabajo, Task.Delay(gracia))` antes de incrementar el contador).
- Acotar `TopeHuerfanos` a `Math.Min(tope, MaximoSimultaneos)`. Hoy no está acotado (`TurnosRender.cs:38`): con un tope mayor que los cupos, el grupo personalizado se puede llenar de huérfanos sin que se pida el reinicio, y queda en 429 para siempre.
- Agregar una prueba con un render cancelado que termina dentro de la gracia y no cuenta.
- Condición: antes de que T4-02 conecte la principal con cancelación. C-02-4 (recuperación del servicio) sigue siendo condición del instalador.

### O170-03 · Baja · Rechazo de la línea de comandos

**Evidencia** [V]. Tres problemas:

- `ProblemaLineaComandosAsync` solo atrapa `PuppeteerException`, `JsonException`, `InvalidOperationException` y `KeyNotFoundException` (`ConvertidorPdf.cs:452`). Cualquier otra excepción (por ejemplo, `ObjectDisposedException`) sale de `NavegadorAsync` sin desechar `navegador`, que ya está lanzado y que nadie retiene (`:373-392`; el `catch` exterior solo atrapa `ProcessException`, `:394`). El proceso de Chromium y su perfil quedan vivos hasta que el servicio salga. La falla del render sigue siendo cerrada.
- Tras un rechazo no se enclava nada: cada petición personalizada vuelve a lanzar y matar a Chromium y deja otro 5156 crítico. Es serie gracias a `_bloqueo`, pero inunda el registro y gasta de 1 a 2 s de CPU por petición [I].
- `Prohibidos` se compara solo con el prefijo `--` (`PoliticaRedNavegador.cs:78-79`). En Windows, Chromium también acepta `-` y `/` como prefijo de un switch [I]. Hoy los argumentos son constantes, así que solo importaría si cambiara PuppeteerSharp.

**Remediación** (unas 2 horas):

- poner un `catch (Exception)` de falla cerrada, o un `try/finally` que deseche el navegador si no se asignó;
- tras un rechazo, fijar `_motivo` y no relanzar hasta reiniciar el servicio, como con la carpeta;
- normalizar el prefijo del switch (`--`, `-` o `/`) y comparar el nombre hasta el `=`.

### O170-04 · Baja · `WRITE_DAC` implícito del dueño

**Evidencia** [V]: `SddlPrivada` no fija dueño y no lleva una ACE de `OWNER RIGHTS` (`ComprobacionCarpetas.cs:64-65`). El dueño de `render` y de cada `perfil-*` es la cuenta del servicio, que por ser dueña tiene `READ_CONTROL` y `WRITE_DAC` implícitos [I, conocido de Windows]. Con eso puede ampliar la DACL, cosa que `0x1301bf` quería impedir.

**Riesgo.** Lo aprovecha quien ya tiene el token del servicio, por ejemplo tras un escape del sandbox (S170-05). Ese atacante ya lee todo, así que el riesgo es bajo. Un cambio en `render` se detecta al arrancar (LECTOR_NO_PERMITIDO); uno en `perfil-*` no se detecta, pero el perfil se borra.

**Remediación** (menos de 1 hora): agregar `(A;OICI;RC;;;OW)` a `SddlPrivada`. `OWNER RIGHTS` con solo `READ_CONTROL` sustituye los derechos implícitos del dueño, y como `0x20000` no está en ninguna de las dos máscaras, pasa `Evaluar` y `EvaluarLectores`. Hace falta una prueba que lea la ACE.

### O170-05 · Baja · Coste de la capa 0

**Evidencia** [V]: `UnaPasada` llama a `Etiqueta` en cada `<` que empieza por `link` o `script` (`PoliticaRedNavegador.cs:176-190`). Si la etiqueta no se cierra, `Etiqueta` recorre el resto del texto y crea una cadena y una entrada de lista por cada «atributo» (`:203-246`). Un texto con muchas aperturas de `<link ` sin `>` cuesta O(n²) en tiempo y en asignaciones. Lo mismo pasa con el número de pasadas hasta el punto fijo cuando las etiquetas están anidadas (`:159-170`). No hay tope de tamaño: el cuerpo admite 16 MB (`OpcionesRender.MaximoCuerpoBytes`).

**Riesgo.** Hilo ocupado, huérfano y reinicio controlado. Solo lo alcanza el autor de la plantilla, que con Razor ya ejecuta código. Por eso es Bajo.

**Remediación** (2 a 4 horas):

- si `Etiqueta` llega al final del texto fuera de unas comillas, ninguna apertura posterior se puede cerrar: terminar la pasada;
- poner un tope al HTML que entra a la capa 0 (por ejemplo, 2 MB; si lo pasa, 413 o 400);
- poner un tope de pasadas (por ejemplo, 32; si lo pasa, rechazar).

### O170-06 · Baja · Mutaciones que las pruebas no detectarían

[V] Leyendo las pruebas nuevas, estas mutaciones pasarían:

1. **Volver a llamar a `PrepararTemporales` desde `PrepararCarpeta`.** P-11 rechaza por el dueño de la raíz de la prueba (`ChromiumAisladoTests.cs:816-833`), no por los lectores. La prueba de S170-01 llama a `ComprobarPrivada` y a `CrearPrivada` directamente (`:1086-1104`). Falta una prueba de `PrepararCarpeta` con una `render` heredada con AU que espere `LECTOR_NO_PERMITIDO` y el 5119, y otra del camino positivo (crear y aprobar).
2. **Quitar la comprobación final de `PrepararPrivada`** (`ComprobacionCarpetas.cs:186`) o la de una carpeta que ya existe (`:176`). Ninguna prueba pasa por `PrepararPrivada`.
3. **Quitar la llamada a `ProblemaLineaComandosAsync` de `NavegadorAsync`.** Las pruebas llaman a la función pura (`La_linea_de_comandos_se_comprueba_al_lanzar`, `Con_una_ruta_con_espacios…`). Ninguna fuerza un rechazo al lanzar (falta un gancho `internal` que agregue un argumento) ni comprueba el 503, el 5156, el navegador cerrado y el perfil borrado.
4. **Quitar las comprobaciones de `CrearPerfil`** (que el perfil exista o que sea un punto de reanálisis, `ConvertidorPdf.cs:415-425`). La prueba de S170-06 solo mira el nombre y la unicidad.
5. **Capa 0:** los vectores de O170-01 no están, así que la evasión pasa las pruebas.
6. **C-02-3:** no hay un caso de cancelación transitoria (O170-02) ni de `TopeHuerfanos > MaximoSimultaneos`.

**Remediación:** unas 0,5 jornadas, junto con O170-01 y O170-02.

## 5. Checklist OWASP (este rango)

| Punto | Resultado |
|---|---|
| A01 Control de acceso | S170-01 cerrado. O170-04 (Baja). El render sigue solo por la canalización (`EndpointsRender.cs:75` [V], sin cambios) |
| A02 Criptografía | S170-06 cerrado (128 bits de `RandomNumberGenerator`) |
| A03 Inyección | Los argumentos de Chromium siguen constantes. El HTML de la plantilla es hostil por diseño. Ver O170-01 |
| A04 Diseño inseguro | O170-02 (disponibilidad del servicio por el reinicio enclavado) |
| A05 Configuración | S170-07 y S170-08 cerrados. Falta acotar `TopeHuerfanos` (O170-02) |
| A06 Componentes vulnerables | Sin cambios de paquetes en el rango [V] |
| A07 Autenticación | No aplica |
| A08 Integridad | S170-08 cerrado, con O170-03 |
| A09 Registro y monitoreo | 5120 y 5156 sin datos sensibles: el formato, la empresa del token, la ruta del ejecutable y el motivo [V]. Falta un enclavamiento contra la inundación de 5156 (O170-03) |
| A10 SSRF | La capa 0 nueva es evadible (O170-01). Las capas 1 y 2 no cambian |

## 6. Controles bien implementados (del rango)

- **Creación atómica con comprobación posterior** de la carpeta privada: cierra la carrera entre comprobar y crear sin retener identificadores (`ComprobacionCarpetas.cs:156-161,186`).
- **Evaluación de lectores** con falla cerrada para una DACL nula y para las ACE desconocidas, que cubre también las ACE heredadas y las solo heredables (`:109-129`).
- **Capa 0** con lectura sin contexto y punto fijo: quitar de más nunca abre nada. Sus pruebas cubren mayúsculas, atributos sin comillas, `/` como separador, `rel` repetido, etiquetas sin cierre y etiquetas que se forman al quitar otras.
- **P-04 documenta honestamente la limitación de la capa 1**, con una aserción que falla si Chromium cambia.
- **La línea de comandos se comprueba al lanzar** con falla cerrada, y la ruta con espacios se prueba con Chromium.
- **El entorno de Chromium es una lista blanca**, probada sobre `StartInfo.Environment`.
- **Grupos de render separados.** El grupo depende del contenido de la solicitud y no se puede elegir de forma independiente; los ganchos de prueba no se pueden enlazar desde la configuración.

## 7. Remediaciones priorizadas

| # | Hallazgo | Cuándo | Esfuerzo |
|---|---|---|---|
| 1 | O170-01: lista blanca de `rel`, quitar los `<script>`, rechazar los marcos y agregar los vectores | Antes de formatos personalizados de terceros fuera del DEMO (puede ir en T4-03b) | 0,5 jornada |
| 2 | O170-02: gracia antes de contar, acotar el tope y la prueba | Antes de que T4-02 conecte la principal con cancelación | 2 h |
| 3 | O170-06: pruebas de cableado (`PrepararCarpeta`, rechazo al lanzar, `CrearPerfil`) | Con 1 y 2 | 0,5 jornada |
| 4 | O170-03, O170-04, O170-05 | T4-03b | 4-6 h en total |
| 5 | Siguen abiertos de la revisión anterior: S170-03, S170-04, S170-05 (ADR candidato, después del 20-nov), S170-09 a S170-11; C-02-2, C-02-4 y C-02-5 | Según el plan de B | Sin cambios |

## 8. Lo que NO verifiqué

- No ejecuté nada. Los resultados de las pruebas y de las mutaciones son los que declara B.
- La tabla de entidades de `WebUtility.HtmlDecode` en .NET 10 (O170-01.1) y el número de dígitos que admite Chromium en una referencia numérica (O170-01.2). Ambas se confirman con una prueba unitaria y una de navegador.
- Si Chromium procesa `preconnect` dentro de un `srcdoc` o de un marco `data:` antes del corte de M-170-2 (O170-01.3).
- El dueño por omisión del token de una cuenta virtual (O170-04) y si `WindowsServiceLifetime` informa al Administrador de servicios del código de salida 3, que es lo que decide si C-02-4 actúa.
- Si la principal (T4-02) propagará la cancelación del cajero (O170-02).
- `ValidadorPlantillas`, que es el límite real de lo que puede hacer una plantilla Razor dentro del proceso. Fuera del rango; sigue pendiente de una revisión aparte, como en la sección 9 de la revisión anterior.

## 9. Decisiones candidatas a ADR

Ninguna nueva. Sigue en pie la de S170-05 (identidad separada para el render).

## Entregas a otros agentes

- **desarrollador del tramo 4 (B):** O170-01 a O170-06, en el orden de la sección 7.
- **devops / instalador:** C-02-4, la recuperación del servicio en «stops with errors», ahora más urgente por O170-02. Además, al actualizar, borrar `Reportes\render` si quedó heredada, para evitar el 503 que B declara.
- **qa-automatizado:** las pruebas de O170-06 y los vectores de O170-01 con Chrome y Edge.

### Cierre
- Estado: Aprobado con observaciones (recomendación: Aprobar con condiciones; firma del propietario pendiente)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\revision-seguridad-pr170-rango-4d676907-2026-10-22.md`
- Supuestos: `WebUtility.HtmlDecode` solo con entidades HTML 4.01; Chromium acepta ceros de relleno en las referencias numéricas y prefijos `-` y `/`; la principal propagará la cancelación en T4-02.
- Decisiones candidatas a ADR: Ninguna nueva.
- Entregas a otros agentes: B → O170-01 a O170-06; devops → C-02-4 y borrar la `render` heredada al actualizar; qa-automatizado → pruebas de O170-06.
- Próximo paso recomendado: que B cierre O170-01 y O170-02 (con sus pruebas) en T4-03b y que el propietario decida si une el #170 con esas condiciones.
