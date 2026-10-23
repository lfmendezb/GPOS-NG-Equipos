# Revisión de seguridad del PR #170, rango `4d676907..403da3ca` (cierre de O170-01 a O170-06)

- Fecha: 2026-10-23 · Revisor: auditor-seguridad (equipo A), con Opus
- PR: #170, rama `b/ola5-t4-03a`, punta `403da3ca`. Revisé solo lo que B tocó para esto: `git diff 4d676907..HEAD -- src/GPOS.Reportes.Api src/GPOS.Reportes/Exportacion tests/GPOS.Reportes.Tests`, es decir, 11 archivos, +484/-110. La fusión de `feature/modelo-ng` queda fuera. Las pruebas `QA5_*` de `ProveedorContextoTests` vienen de esa fusión y no son de seguridad del render.
- Método: revisión **estática** en el checkout de solo lectura `GPOS-NG-r170`. No compilé, no ejecuté pruebas y no lancé Chromium. Los resultados de las pruebas (265/265) y de las mutaciones (4 de 13) son los que declara B.
- Marcas: [V] lo verifiqué leyendo el código; [I] lo infiero (comportamiento de Chromium, del analizador de HTML, de .NET o de Windows que no comprobé ejecutando nada).
- Antecedentes: la revisión anterior, `traspasos/A/revision-seguridad-pr170-rango-4d676907-2026-10-22.md`, y el aviso de B, `avisos/B-a-A/2026-10-23-170-o170-01-a-06-empujado.md`.
- La renumeración del EventId a 5157 (`TurnosRender.cs:31`) no se trata como hallazgo.

## 1. Resumen y recomendación

**Recomendación: Aprobar con condiciones.** Es una recomendación técnica; la firma es del propietario (C2).

Quedan cerrados **O170-02** y **O170-04**. O170-03, O170-05 y O170-06 quedan **cerrados en parte**. **O170-01 no queda cerrado**: la lista blanca está bien planteada, pero la optimización de O170-05 le metió un agujero (P170-01).

No hay hallazgos Críticos ni Altos. Hay **1 Medio** y **5 Bajos** nuevos, además de un Medio preexistente fuera del rango (P170-07):

- **P170-01 (Media, regresión del rango):** la capa 0 deja de revisar el resto del documento cuando encuentra un `<link` o un `<script` sin cerrar (`PoliticaRedNavegador.cs:234,240`). El navegador no lee como etiqueta un `<link` que está dentro de un comentario, de un valor de atributo, de `<style>`, `<title>`, `<textarea>` o de un CDATA. Así, una apertura sin cerrar puesta en uno de esos lugares deja pasar sin tocar todas las sugerencias de conexión reales que vengan después. Es el mismo riesgo que O170-01. La versión anterior (`4d676907`) no tenía este fallo.
- **P170-02 (Baja):** la capa 0 sigue siendo cuadrática con `<link rel=stylesheet` que se repite sin cerrar hasta un `>` final. El tope de 8 Mi no lo acota.

Condiciones que propongo:

- **Antes de unir el #170:** corregir P170-01 y agregar sus pruebas. Son unos 30 minutos. El PR declara cerrado O170-01, y el arreglo es trivial.
- **Antes de habilitar formatos personalizados de terceros fuera del DEMO:** P170-02 y P170-05 (unas 3 horas en total).
- **En T4-03b:** P170-03, P170-04 y P170-06.
- **P170-07:** como ticket aparte. No condiciona este PR.

**Tamaño máximo (pregunta de B):** **8 Mi caracteres sirve**, con dos condiciones. Primero, que el coste de la capa 0 sea lineal (P170-02). Segundo, que se ponga además un tope al **número de `<`** (por ejemplo, 262.144). El coste no depende del tamaño, sino de cuántas etiquetas hay y del caso cuadrático: las imágenes en base64 no tienen `<` y se recorren con `IndexOf` vectorizado. Detalle en la sección 4, P170-02.

## 2. Cierre de los hallazgos previos

| ID | Estado | Evidencia y comentario |
|---|---|---|
| **O170-01** | **No cerrado** [V], por P170-01 | Lo que está bien [V]: `rel` crudo, sin decodificar (`PoliticaRedNavegador.cs:303`). La lista blanca es `{stylesheet}`, comparada sin distinguir mayúsculas; tiene que haber al menos un `rel`, todos los `rel` tienen que estar admitidos y ninguno puede llevar `&` (`:160`, `:325-330`). Se quitan **todos** los `<script>` con su contenido (`:237-242`, `FinScript` `:308-319`). Los marcos y objetos (`iframe`, `frame`, `frameset`, `object`, `embed`, `portal` y `fencedframe`) se rechazan con 400 `FORMATO_INVALIDO` (`:166`, `:196-197`, `ErroresRender.cs:9`). `Marco` busca en todo el texto, sin contexto y en **cada pasada**, así que también ve un marco que se forma al quitar otra etiqueta (`:207-213`; prueba `<ifr<script></script>ame`). Los nombres de etiqueta y sus terminadores coinciden con los del analizador de HTML (`EmpiezaEtiqueta`, `:216-221`; el CR se normaliza a LF [I]). El fallo: la salida anticipada con `SinCierre` rompe la lectura sin contexto (P170-01). La comprobación `!v.Contains('&')` es redundante con la lista blanca: cualquier `&` deja una ficha que no es `stylesheet`. No sobra (es defensa en profundidad), pero no la detecta ninguna mutación (es la O1 equivalente de B). La sección 3 tiene la cobertura vector por vector |
| **O170-02** | **Cerrado** [V] | Ver el detalle debajo de la tabla |
| **O170-03** | **Cerrado en parte** [V], con P170-03 y P170-04 | Ver el detalle debajo de la tabla |
| **O170-04** | **Cerrado** [V] | `SddlPrivada` agrega `(A;OICI;RC;;;OW)` (`ComprobacionCarpetas.cs:66-67`). `0x20000` no está en `MascaraLectura` ni en `MascaraEscritura`, así que `Evaluar` y `EvaluarLectores` la dejan pasar (`:95`, `:124`). La prueba lee las cuatro ACE, con `S-1-3-4` y `0x20000` sin heredar (`ChromiumAisladoTests.cs` hacia `:1103`). Con `OICI`, los `perfil-*` heredan la ACE de `OWNER RIGHTS` tal cual, y esa ACE limita al dueño de cada perfil [I, semántica de Windows]. El servicio conserva `DELETE` por su propia ACE (`0x1301bf`), así que puede seguir borrando perfiles. Observación sin severidad: una `render` creada por una versión anterior de este PR, sin la ACE de `OW`, pasa `ComprobarPrivada` y conserva el `WRITE_DAC` implícito. Como hoy todo es desarrollo, basta con borrar `render` en los equipos de prueba |
| **O170-05** | **Cerrado en parte** [V], con P170-02 | El tope de 8 Mi caracteres se aplica **antes** de cualquier trabajo de la capa 0 (`PoliticaRedNavegador.cs:191-192`), y el de 32 pasadas termina en un rechazo (`:194-203`). La salida anticipada con `SinCierre` hace lineal el caso de aperturas sin cerrar, pero es la causa de P170-01. **Sigue cuadrático** el caso de un `<link>` admitido que no se cierra hasta un `>` lejano (P170-02). Además, el tope se aplica después de `MarcarCopia`, cuyo `Regex("<body[^>]*>")` recorre una salida de Razor sin límite (`ServicioRender.cs:51,119`; coste cuadrático con muchos `<body` sin `>` [I]). Este último punto es preexistente y lo alcanza el mismo autor que ya puede escribir `@while(true){}` |
| **O170-06** | **Cerrado en parte** [V], con P170-06 | Hay pruebas nuevas: los vectores de evasión, los marcos, los topes, `CrearPerfil`, el rechazo al lanzar, la gracia y el tope de huérfanos. Pero quedan mutaciones sin detectar (sección 4, P170-06), la prueba de 400.000 aperturas se cuelga en vez de fallar y el caso `object` de `Un_documento_data_anidado_corta_el_render` es intermitente |
| Observación de `/api/salud` | **Cerrada** [V] | El comentario ya explica por qué sale `RENDER_REINICIANDO` (`ServiciosLectura.cs:48`) |

**O170-02, detalle.** La gracia funciona así: `Abandonado` ya no cuenta al momento. `ContarSiSigueAsync` espera `WhenAny(trabajo, Delay(gracia))` y solo cuenta si el trabajo sigue vivo después (`TurnosRender.cs:83-98`; gracia de 5 s, `OpcionesRender.cs:94`). El tope se acota con `Math.Clamp(tope, 1, max(1, MaximoSimultaneos))` (`TurnosRender.cs:39`).

Revisé si hay carrera o fuga en el contador y no encontré ninguna:

- Si el trabajo termina entre `IsCompleted` (`:89`) y el `ContinueWith` (`:91`), la continuación se ejecuta en línea y descuenta: el contador queda balanceado.
- La única forma de que un render abandonado nunca descuente es que no termine nunca. Ese es el caso que se busca contar.
- Durante la gracia, el trabajo retiene su cupo (`EndpointsRender.cs:94`). Si se pide el reinicio, `ReinicioRenderControlado` lo espera como un render en curso, hasta `TiempoMaximo` (`TurnosRender.cs:129`).
- La tarea que devuelve `Abandonado` se descarta (`EndpointsRender.cs:103`). Si fallara, sería una excepción no observada, que no tumba el proceso en .NET 10 [I].

Residual [I]: Razor es síncrono y no observa la cancelación. Si un render legítimo que tarda más de 5 s se cancela, cuenta como huérfano. Con plantillas normales es improbable.

**O170-03, detalle.**

- **Cualquier excepción es un rechazo:** hay un `catch (Exception)` alrededor de la comprobación (`ConvertidorPdf.cs:390-398`). El navegador rechazado siempre se desecha (`:405-412`) y su perfil se borra (`:413`).
- **No se relanza:** `_lineaRechazada` (`:67`, `:357`, `:401`) deja un solo 5156 hasta reiniciar.
- **Prefijos:** `NombreSwitch` (`PoliticaRedNavegador.cs:92-99`) normaliza `--`, `-` y `/` y corta en el `=`, pero solo para `Prohibidos` (`:77-79`).
- **¿Hay denegación de servicio con una petición?** **No** [V]. La comprobación no depende del contenido de la petición, `ProblemaLineaComandosAsync` no recibe el `CancellationToken` de la petición (`:463`) y `LaunchAsync` tampoco (`:387`). Un atacante no puede forzar el rechazo. Lo que sí es un riesgo operativo nuevo es que una falla **transitoria** quede enclavada (P170-03). Los estándar no se ven afectados, porque no usan el navegador (`:35`).
- **Lo que falta:** las variantes con prefijo distinto y los duplicados de los switch exigidos y de `--user-data-dir` (P170-04).

## 3. La capa 0 frente a los vectores pedidos

Todo lo marcado [V] es por lectura de `PoliticaRedNavegador.cs:188-330`. El comportamiento del navegador es [I], según el estándar de HTML.

| Vector | ¿Lo cubre la capa 0? | Quién lo cubre si no |
|---|---|---|
| Mayúsculas en etiqueta, atributo o `rel` | Sí [V] (`OrdinalIgnoreCase`). Los caracteres no ASCII que .NET pliega, como `ſ` o `ı`, solo hacen que la capa 0 quite o admita algo que el navegador no reconoce: no abre nada | — |
| Atributos sin comillas, `/` como separador, `=` inicial, `rel` repetido | Sí [V]: el lector de atributos sigue los estados del analizador (`:269-305`) y el `rel` repetido falla cerrado (`:327-329`; prueba `rel="stylesheet" rel="preconnect"`) | — |
| Referencias de caracteres (`&Tab;`, `&NewLine;`, numéricas con ceros) | Sí [V]: un `rel` con `&` no se admite | — |
| Comentarios, CDATA, `<style>`, `<title>` o `<textarea>` que **contienen** un `<link>` o un `<script>` | Sí, quita de más [V]… **salvo** que dentro haya una apertura sin cerrar: entonces se salta todo lo que viene después (**P170-01**) | Capa 2 |
| Etiquetas mal cerradas al final del texto | Sí [V]; el navegador las descarta | — |
| Etiquetas que se forman al quitar otras | Sí [V], con punto fijo y como mucho 32 pasadas | — |
| `<script>` de cualquier tipo, incluido `speculationrules` | Sí [V]: quita todos | — |
| `srcdoc`, marcos `data:`, `<object>`, `<embed>`, `<portal>`, `<fencedframe>`, `<frameset>` | Sí [V]: 400 | — |
| `<base href>` | No | Capas 1 y 2 (cambia la base de peticiones de recursos) |
| `<meta http-equiv=refresh>` | No | Capa 1 (navegación de documento) y capa 2. Además, Chromium bloquea la navegación de nivel superior a `data:` que inicia la página [I] |
| `<meta http-equiv=x-dns-prefetch-control content=on>` junto con `<a href>` | No | **Solo la capa 2** (`--dns-prefetch-disable` y `--host-resolver-rules`). La capa 1 no ve una resolución de nombre (P170-05) [I] |
| `<style>@import`, `url()` en CSS o en `style=` | No | Capas 1 y 2 (peticiones de recursos; S170-02 comprobó que cada una corta sola) |
| `<svg>`/`<image>`/`<use>`, `<img srcset>`, `<video poster>`, `<input type=image>` | No | Capas 1 y 2. Un SVG cargado como imagen no carga subrecursos [I] |
| `<form action>`, `<a ping>` | No | No hay envío sin JavaScript ni interacción. Además, `--no-pings` |
| `<link rel=stylesheet href=http…>` (admitido) | Lo deja pasar a propósito | Capas 1 y 2 (petición de recurso) |

**¿Es aceptable el reparto?** Sí, con dos salvedades.

- Las **peticiones de recursos** pueden quedar a cargo de las capas 1 y 2: cada una las corta sola, y eso se comprobó con Chromium (S170-02).
- La capa 0 tiene que cubrir **lo que la capa 1 no ve**: las sugerencias de conexión, los documentos anidados y las resoluciones previas de nombres.
  - Las dos primeras quedan cubiertas cuando se arregle P170-01.
  - La tercera tiene un camino sin cubrir: la prebúsqueda de DNS de los enlaces `<a>`, activada con un `<meta>` (P170-05).

## 4. Hallazgos nuevos

| ID | Severidad | Título |
|---|---|---|
| P170-01 | Media | La capa 0 deja de revisar el documento en la primera etiqueta sin cerrar (regresión del rango) |
| P170-02 | Baja | La capa 0 sigue siendo cuadrática con `<link>` admitidos sin cerrar; el tope de tamaño no la acota |
| P170-03 | Baja | `_lineaRechazada` enclava también las fallas transitorias, sin señal en `/api/salud` |
| P170-04 | Baja | Línea de comandos: los switch exigidos y `--user-data-dir` no se normalizan ni se comprueba que no estén duplicados |
| P170-05 | Baja | La capa 0 no quita `<meta http-equiv>`: la prebúsqueda de DNS de los enlaces queda solo a cargo de la capa 2 |
| P170-06 | Baja | Pruebas: mutaciones sin detectar, una prueba que se cuelga en vez de fallar y una intermitente |
| P170-07 | Media (preexistente, fuera del rango) | La marca de copia (RO-54) se puede ocultar desde la plantilla |

### P170-01 · Media · La capa 0 deja de revisar el documento en la primera etiqueta sin cerrar

**Riesgo.** La capa 0 es segura porque revisa **todas** las apariciones literales de `<link` y `<script` del texto, sin contexto. En la versión final, cada `<link` que queda tiene que ser una hoja de estilo admitida. Con eso, el navegador solo puede crear un `<link>` en un punto donde la capa 0 leyó lo mismo que él.

La salida anticipada rompe esa garantía:

- `if (fin == SinCierre) break;` (`PoliticaRedNavegador.cs:234`, y lo mismo para `script` en `:240`) termina la pasada en la primera apertura cuyo valor entre comillas no se cierra hasta el final del texto.
- El comentario lo justifica diciendo que «ninguna apertura posterior se puede cerrar» (`:234`). Eso solo es cierto si el navegador está leyendo etiquetas en ese punto.
- Dentro de un comentario, de un valor de atributo, de `<style>`, `<title>`, `<textarea>` o de un CDATA, el navegador no lee esa apertura como etiqueta [I]. Tampoco busca la comilla que la cerraría. Sí analiza normalmente todo lo que viene después, incluidas las sugerencias de conexión reales.

Al autor de la plantilla le basta con no usar ese tipo de comilla en el resto del documento. Razor ya codifica la comilla simple de los datos del modelo y `MarcarCopia` no la usa. Con eso, la capa 0 devuelve el HTML sin tocarlo. Para esas sugerencias, la capa 1 no ve nada (P-04) y queda solo la capa 2. Es el mismo escenario y el mismo impacto que O170-01: sacar datos del documento en el nombre del anfitrión si la capa 2 falla (S170-03).

**Evidencia** [V]: `PoliticaRedNavegador.cs:223-257`, en particular `:233-234` y `:239-240`, y `Etiqueta` `:288` y `:291-292`. En `4d676907`, `Etiqueta` devolvía `false` y el bucle seguía con `i++`: esta evasión no existía. La prueba `La_capa_0_lee_el_final_de_la_etiqueta_como_el_navegador` (`ChromiumAisladoTests.cs:1466`) solo cubre la apertura sin cerrar al final real del texto. Ninguna prueba pone una apertura sin cerrar dentro de un comentario y después una sugerencia real.

**Remediación (unos 30 minutos).** Con `SinCierre`, **rechazar con 400 `FORMATO_INVALIDO`**: «una etiqueta `link` o `script` sin cerrar». Es lineal, falla cerrada y ningún formato legítimo la necesita.

- Alternativa descartada: quitar desde la apertura hasta el final del texto. También es segura para la red, pero borra en silencio el pie y la banda de `MarcarCopia` (RO-54) cuando el navegador sí los habría mostrado. Le daría al autor otra forma de quitar la marca de copia.
- Alternativa descartada: volver a `i++`. Reabre O170-05.

**Pruebas que hay que agregar:**

- comentario con apertura sin cerrar y después una sugerencia real;
- lo mismo con `<style>`, `<title>` y `<textarea>`;
- lo mismo con un valor de atributo (`<div title="<link a='">`);
- lo mismo con CDATA en `<svg>`;
- la variante con `<script a='`;
- todas deben esperar 400.

### P170-02 · Baja · La capa 0 sigue siendo cuadrática con `<link>` admitidos

**Evidencia** [V]: si el `<link>` se admite, `fin = -1` y el bucle avanza un solo carácter (`PoliticaRedNavegador.cs:235`, `:244-247`). Un texto con muchas `<link rel=stylesheet ` seguidas y un solo `>` al final cumple tres cosas a la vez:

- cada apertura se lee hasta ese `>` y crea una cadena por cada «atributo» (`:279-303`);
- todas se admiten, porque los otros atributos no importan (`:327`);
- la siguiente apertura empieza dentro de la anterior.

Coste estimado [I], con unos 21 caracteres por apertura:

| HTML | Aperturas | Coste |
|---|---|---|
| 8 Mi caracteres | ~400.000 | Unas 1,7·10¹² lecturas de carácter más ~10¹¹ cadenas: horas de CPU |
| 2 Mi caracteres | — | Minutos o más |

La prueba de 400.000 aperturas (`ChromiumAisladoTests.cs:1498`) usa `<link a=b ` **sin** `>`, que es el caso que corta la salida anticipada. Por eso no ve este otro.

**Riesgo.** El hilo queda ocupado. A los 30 s el render se abandona; pasados los 5 s de gracia, cuenta como huérfano; dos huérfanos piden el reinicio controlado, y sin C-02-4 el servicio queda detenido. Solo lo alcanza el autor de la plantilla, que puede generar ese texto con un `@for` de pocas líneas (`ValidadorPlantillas.cs:33-38` no prohíbe los bucles) y que ya puede escribir `@while(true){}` con el mismo efecto. Por eso es Baja.

**Remediación (1 a 2 horas).**

- Un `<link>` cuyo tramo leído (`i+1` a `fin`) contiene otro `<` no se admite: se quita. Es quitar de más, que no abre nada, y deja la pasada en tiempo lineal, porque el tramo admitido ya no contiene ninguna apertura que haya que volver a leer.
- **No** saltar a `fin` sin más: dentro de un comentario rompería la lectura sin contexto, igual que P170-01.

**Tamaño máximo (respuesta a B).** Dejar **8 Mi caracteres** (son ~16 MiB en memoria, en línea con los 16 MB del cuerpo), con tres condiciones:

- arreglar lo anterior;
- agregar un tope de **262.144 `<`** por documento: un formato legítimo tiene del orden de 10³ a 10⁴ etiquetas [I]. Con eso, el peor caso queda en 32 pasadas × 262.144 × 7 comparaciones de `Marco`, unos 6·10⁷ comparaciones cortas, por debajo de 1 s [I]. Hoy es de unos 10–20 s con 8 Mi de `<` en 32 pasadas [I, estimado sin medir];
- comprobar el tamaño **justo después de Razor**, antes de `MarcarCopia` (`ServicioRender.cs:51`).

Bajar a 2 MB rompería formatos gráficos legítimos con varias imágenes (cada una ocupa hasta ~450 mil caracteres en base64) y no arreglaría el caso cuadrático. El mensaje de `:192` dice «MB», pero la unidad son caracteres: conviene corregirlo.

### P170-03 · Baja · Una falla transitoria deja los personalizados en 503 hasta reiniciar

**Evidencia** [V]: el `catch (Exception)` de `ConvertidorPdf.cs:395-398` y el `catch` interno de `:480-483` convierten en rechazo **cualquier** problema al leer la línea de comandos. Eso incluye un tiempo de espera de CDP con el equipo cargado, un navegador que se cierra en ese instante o una actualización de Chrome en curso [I]. Además, `_lineaRechazada = true` (`:401`) lo enclava. Desde ese momento, todos los formatos personalizados responden 503 hasta que alguien reinicie el servicio a mano. La única señal es un 5156 crítico: `/api/salud` sigue en 200 (`ServiciosLectura.cs:47-55` solo mira el reinicio controlado y la base).

**Riesgo.** No es explotable con una petición (sección 2, O170-03). Es un riesgo operativo nuevo, de disponibilidad: una caja que imprime facturas con formato personalizado se queda sin PDF por un incidente pasajero. Los tickets estándar siguen funcionando.

**Remediación (unas 2 horas).**

- Distinguir dos casos:
  - **«se leyó y no cumple»**, que es un evento de seguridad: enclavar, como hoy;
  - **«no se pudo leer»**: desechar el navegador, borrar el perfil y dejar un 5156 de nivel Warning. Relanzar con espera creciente (por ejemplo 5 s, 30 s y 120 s) y enclavar solo tras 3 fallas seguidas.
- Hacer visible el estado enclavado en `/api/salud`, con un 503 genérico o un código de estado sin detalle, para que el monitoreo lo vea.

Alternativa descartada: salir con el código 3, como en el reinicio controlado. Depende de C-02-4, que sigue pendiente.

### P170-04 · Baja · Línea de comandos: prefijos y duplicados de los switch exigidos

**Evidencia** [V]: la normalización de `NombreSwitch` solo se aplica a `Prohibidos` (`PoliticaRedNavegador.cs:77-79`). El resto se compara de forma literal:

- los argumentos de la capa 2 se buscan con `Contains` exacto (`:80-82`);
- `--user-data-dir` solo se cuenta con el prefijo `--` (`:84`).

Si se repite un switch, Chromium se queda con el **último** valor [I]. Por eso, un `--proxy-server=…` o un `/proxy-server=…` posterior anularía la capa 2 y pasaría la comprobación. Pasaría lo mismo con un `-user-data-dir=…` o un `/user-data-dir=…` agregado al final.

**Riesgo.** Bajo: hoy los argumentos son constantes, no se pueden configurar y `ArgumentosPrueba` es interno (`OpcionesRender.cs:97`). Solo importaría si PuppeteerSharp agregara argumentos o si alguien cambiara la configuración.

**Remediación (1 hora).** Agrupar la línea efectiva por `NombreSwitch` y exigir que cada switch de `ArgumentosRed`, `remote-debugging-pipe` y `user-data-dir` aparezca **exactamente una vez**, con el valor esperado. Hace falta una prueba de tabla con los duplicados y los prefijos `-` y `/`.

### P170-05 · Baja · La capa 0 no quita `<meta http-equiv>`

**Evidencia** [V para la capa 0; I para Chromium]: la capa 0 solo trata `link`, `script` y los marcos (`PoliticaRedNavegador.cs:196-243`). Chromium desactiva por omisión la prebúsqueda de DNS de los `<a href>` en un documento que no es `http:`. Pero `<meta http-equiv="x-dns-prefetch-control" content="on">` la activa [I]. Una resolución de nombre no es una petición de recurso, así que la capa 1 no la ve. Es el mismo caso que `dns-prefetch`, que la capa 0 sí quita, y aquí depende solo de la capa 2 (`--dns-prefetch-disable` y `--host-resolver-rules`, `:44`, `:50`).

**Riesgo.** El dato saldría por DNS si fallaran a la vez los dos switch de la capa 2. Es menos probable que con el proxy: estos switch no se anulan con la directiva de grupo de proxy de S170-03 [I].

**Remediación (30 minutos).** Quitar todo `<meta>` que tenga `http-equiv`. Un formato solo necesita `charset` y `viewport`. Ya puestos, quitar también `<base>`: no es necesario, porque sus efectos son peticiones de recursos, pero reduce superficie y no cuesta nada. Hace falta una prueba de que los dorados siguen idénticos.

### P170-06 · Baja · Pruebas

**1. Mutaciones que pasarían.** Las deduje leyendo las pruebas [V]; no las ejecuté:

| # | Mutación | Por qué no se detecta |
|---|---|---|
| M1 | Quitar `"frame"` de `EtiquetasMarco` (`PoliticaRedNavegador.cs:166`) | El único caso es `<frameset><frame …>`, que se rechaza por `frameset` |
| M2 | Quitar `"frameset"` | El mismo caso se rechaza por `frame` |
| M3 | Quitar el `catch (Exception)` de `ConvertidorPdf.cs:395-398` | Ninguna prueba provoca una excepción fuera del filtro interno |
| M4 | Volver a filtrar el `catch` del `DisposeAsync` rechazado (`:409`) | Sin prueba |
| M5 | Quitar la comprobación de punto de reanálisis del perfil (`:449-450`) | `Un_perfil_que_ya_existe_no_se_usa` (`ChromiumAisladoTests.cs:1220`) crea la unión **antes**, así que la detiene `Path.Exists` (`:443`) y nunca llega a `:449` |
| M6 | Quitar la comprobación de `tmp` (`:452-453`) | Sin prueba |
| M7 | Quitar la comprobación final de `PrepararPrivadaEnComponente` (`ComprobacionCarpetas.cs:198` → `return null`) | La carpeta recién creada cumple de todos modos; haría falta un gancho que simule la carrera |
| M8 | `PrepararCarpeta` sin `PrepararPrivada` o con `PrepararTemporales` (`ConvertidorPdf.cs:104`) | B lo admite: la prueba entra por `PrepararCarpetaEnComponente` |
| M9 | Cambiar el `break` de `SinCierre` por `i++` | La prueba de 400.000 se **cuelga** en vez de fallar (O5 de B) |
| M10 | Quitar `_lineaRechazada` de `:357` | Solo lo detecta `[FactConNavegador]`, que se omite donde no hay Chrome ni Edge (`RenderInternoTests.cs:820-829`) |
| M11 | `!v.Contains('&')` | Equivalente: la lista blanca ya lo cubre |

Faltan también las pruebas de P170-01 y P170-02.

**2. La prueba de 400.000 aperturas** (`ChromiumAisladoTests.cs:1498-1510`). Es un `[Fact]` síncrono, y el `Stopwatch` solo se mira **después** de volver. Si una regresión vuelve cuadrática la función, la prueba no falla: se cuelga. El repositorio no tiene flujos de CI (`.github/workflows` no existe [V]). Las suites corren en los equipos A, B y C, donde un `testhost` colgado bloquea la sesión del agente y deja procesos huérfanos.

Es un riesgo real para la «CI» de hoy, aunque no para el producto. Remediación (15 minutos):

- convertirla en `async` con `await Task.Run(() => SanearHtml(…)).WaitAsync(TimeSpan.FromSeconds(10))`. El hilo sigue ocupado, pero la prueba falla;
- agregar `--blame-hang-timeout 10m` a las órdenes de la suite;
- lo mismo para la prueba nueva de P170-02.

**3. El caso `object` de `Un_documento_data_anidado_corta_el_render`** (`:938`) es intermitente. Con la capa 1 sola, «salió a la red». Confirma la inferencia de O170-01.3: el documento anidado empieza a analizarse antes del corte. Una prueba de seguridad intermitente acostumbra a ignorar los fallos. Hay que hacerla determinista:

- o documentar el caso como **limitación conocida** de la capa 1, como P-04, con una aserción de «puede salir»;
- o quitar el caso `object`, porque ahora lo rechaza la capa 0 y lo corta la capa 2.

**4. Superficie de prueba en la librería.** `ComprobacionCarpetas.PrepararPrivadaEnComponente` es **pública** (`ComprobacionCarpetas.cs:185`) y se salta la comprobación de los padres de ADR-77. Conviene hacerla `internal` con `InternalsVisibleTo` para `GPOS.Reportes.Api` y las pruebas, o darle un nombre que lo deje claro. Es una observación sin severidad.

### P170-07 · Media (preexistente, fuera del rango) · La marca de copia se puede ocultar desde la plantilla

**Evidencia** [V en el código; I en el navegador]: `MarcarCopia` hace dos inserciones:

- la banda, después del **primer** `<body[^>]*>` del texto (`ServicioRender.cs:119-120`);
- el pie «Reimpreso el …», antes del **último** `</body>` (`:121-122`).

Una plantilla que lleve un `<body>` dentro de un comentario antes del real, o un `</body>` dentro de un comentario al final, hace que la banda o el pie caigan dentro del comentario. El navegador no los muestra. H-6 cubre el CSS, pero no esto.

**Riesgo (fraude en caja).** Un autor de formatos (administrador o SUPER) puede reimprimir un comprobante sin la marca de copia, y la reimpresión pasa por original. No lo introduce este rango y no condiciona el #170.

**Remediación (unas 0,5 jornadas), en un ticket aparte:**

- poner en la banda y en el pie una clase con un valor aleatorio por render;
- después de `SetContentAsync`, comprobar por CDP (como `AltoPorDomAsync`, `ConvertidorPdf.cs:305-326`) que existen exactamente una banda y un pie con esa clase y con caja distinta de cero; si no, 400.

Alternativa más robusta, pero más cara: estampar la marca sobre el PDF ya generado.

## 5. Checklist OWASP (este rango)

| Punto | Resultado |
|---|---|
| A01 Control de acceso | O170-04 cerrado. Las rutas internas no cambian (`EndpointsRender.cs:76`) |
| A02 Criptografía | No aplica (sin cambios) |
| A03 Inyección | El HTML de la plantilla es hostil por diseño. La capa 0 es evadible por P170-01 |
| A04 Diseño inseguro | P170-07 (preexistente). P170-03 (disponibilidad) |
| A05 Configuración | Los ganchos nuevos (`GraciaHuerfano`, `ArgumentosPrueba`) son `internal`: la configuración no los puede enlazar (`OpcionesRender.cs:94,97`) [V] |
| A06 Componentes vulnerables | Sin cambios de paquetes en los archivos revisados |
| A07 Autenticación | No aplica |
| A08 Integridad | O170-03 cerrado en parte; P170-04 |
| A09 Registro y monitoreo | 5156 y 5157 sin datos sensibles [V]. El estado enclavado no se ve en `/api/salud` (P170-03) |
| A10 SSRF | P170-01 (Media) y P170-05 (Baja). Las capas 1 y 2 no cambian |

## 6. Controles bien implementados

- **Lista blanca de `rel` sin decodificar:** elimina de raíz la diferencia de referencias de caracteres de O170-01 (`PoliticaRedNavegador.cs:303,325-330`).
- **Rechazo de los marcos por nombre de etiqueta, en cada pasada:** cierra `srcdoc` y `data:` sin depender del navegador (`:196-197,207-213`).
- **Gracia del huérfano sin bloquear a quien llama, con el contador balanceado** (`TurnosRender.cs:83-98`), y el **tope acotado** a los cupos (`:39`).
- **Falla cerrada completa al rechazar la línea de comandos:** cualquier excepción, el navegador siempre desechado y el perfil borrado (`ConvertidorPdf.cs:390-415`).
- **`OWNER RIGHTS` con solo `READ_CONTROL`**, comprobado en la prueba de la DACL.
- **Ganchos de prueba internos:** no se pueden enlazar desde la configuración.

## 7. Remediaciones priorizadas

| # | Hallazgo | Cuándo | Esfuerzo |
|---|---|---|---|
| 1 | P170-01: 400 con `SinCierre` y las pruebas de contexto | **Antes de unir el #170** | 30 min |
| 2 | P170-02: no admitir un `<link>` con `<` dentro, tope de `<` y tope justo después de Razor | Antes de formatos de terceros fuera del DEMO | 1-2 h |
| 3 | P170-05: quitar `<meta http-equiv>` (y `<base>`) | Igual que el 2 | 30 min |
| 4 | P170-06: pruebas M1-M8, plazo en la prueba de rendimiento, caso `object` determinista | T4-03b | 0,5 jornada |
| 5 | P170-03 y P170-04 | T4-03b | 3 h |
| 6 | P170-07 | Ticket aparte, antes de la primera venta con formatos personalizados | 0,5 jornada |
| 7 | Siguen abiertos: S170-03, S170-04, S170-05 (ADR candidato), S170-09 a S170-11, C-02-2, C-02-4 y C-02-5 | Según el plan de B | Sin cambios |

## 8. Lo que no verifiqué

- No ejecuté nada. Las cifras de coste de P170-02 y del peor caso de `Marco` son estimaciones [I], sin medir.
- Si Chromium 156 mantiene la prebúsqueda de DNS de los `<a href>` con `x-dns-prefetch-control` (P170-05).
- Si Chromium se queda con el último valor de un switch repetido (P170-04).
- La semántica de herencia de `OWNER RIGHTS` en los `perfil-*` que crea Chromium (O170-04).
- Si el `Regex` de `MarcarCopia` es cuadrático en .NET 10 con la optimización atómica (O170-05, residual).
- `ValidadorPlantillas` como límite de la plantilla Razor sigue sin una revisión propia.

## 9. Decisiones candidatas a ADR

Ninguna nueva. Sigue en pie la de S170-05 (identidad separada para el render).

## Entregas a otros agentes

- **desarrollador del tramo 4 (B):** P170-01 antes de unir; P170-02 a P170-06 según la sección 7. Respuesta sobre el tamaño: 8 Mi caracteres sirve, con P170-02 arreglado y el tope de `<`.
- **qa-automatizado:** las mutaciones M1-M8 y el caso `object` intermitente. Correr la suite con `--blame-hang-timeout`.
- **devops / instalador:** C-02-4 (la recuperación del servicio) sigue pendiente, y P170-03 le suma motivos.
- **arquitecto-maestro / propietario:** decidir si P170-07 (la marca de copia que oculta un autor de formatos) va a un ticket antes de la primera venta con formatos personalizados.

### Cierre
- Estado: Aprobado con observaciones (recomendación: Aprobar con condiciones; firma del propietario pendiente)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\revision-seguridad-pr170-o170-403da3ca-2026-10-23.md`
- Supuestos: el analizador de HTML no lee etiquetas dentro de comentarios, de `<style>`, `<title>`, `<textarea>`, de un CDATA ni de un valor de atributo; Chromium se queda con el último switch repetido; `x-dns-prefetch-control` activa la prebúsqueda de DNS de los enlaces; los costes de P170-02 son estimados.
- Decisiones candidatas a ADR: Ninguna nueva.
- Entregas a otros agentes: B → P170-01 (antes de unir) a P170-06; qa-automatizado → M1-M8 y la prueba intermitente; devops → C-02-4; arquitecto-maestro → P170-07.
- Próximo paso recomendado: que B corrija P170-01 con sus pruebas (unos 30 minutos) y que el propietario decida si une el #170 con las demás condiciones.
