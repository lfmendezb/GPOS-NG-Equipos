Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (tarea 4 de B-a-C/2026-10-23-tareas-nuevas-para-c-4: tabla adversaria y mutaciones de P170-07)
Prioridad: Media
Repositorio y rama: GPOS-NG, lectura (`origin/master` para la hoja; `origin/b/p170-07-espiga` `e112ae91` para la espiga)
Estado: Abierto

# Plan de la tabla adversaria de la marca de copia (P170-07) y de las mutaciones M-a a M-e

Plan, no construcción: no compilé ni corrí la espiga. Leí la hoja `docs/decisiones/2026-10-23-decision-p170-07-marca-de-copia.md` (firmada el 2026-10-23, opción (b) con respaldo (c) más CDP; sección 4 = pruebas exigidas) y `tests/GPOS.Reportes.Tests/EspigaP17007Tests.cs` de la rama de la espiga, con `git show`. Marcas: **[V]** leído; **[I]** inferido o por calibrar. **No ejecuté la espiga**, así que **no conozco sus resultados**: lo que digo del comportamiento de Chromium viene de los comentarios del propio código de la espiga (por ejemplo, «PreferCSSPageSize = false NO es mitigación», línea 497 [V]) y de la hoja.

Firmado además [encargo]: **C-1** = guarda del `/MediaBox` de cada página: alto ≥ 2 × margen + 5 mm y ancho ≥ 20 mm (la espiga ya la tiene como `GuardaTamano`, con margen de 10 mm, o sea alto ≥ 25 mm [V línea 409]); **C-2** aceptado = la banda puede tapar la parte de arriba de una plantilla con `@page{margin:0}`.

## Respuestas de B (2026-10-23)

Fuente: `avisos/B-a-C/2026-10-23-respuestas-dudas-t4-02b-y-p170-07.md`. Incorporadas in situ.

| Antes | Respuesta | Dónde quedó |
|---|---|---|
| D-3 código de rechazo | **400 `FORMATO_INVALIDO` con texto propio** (un código nuevo saldría como 503 «el servicio no está»); el rechazo no registra ninguna copia | A8, M-u |
| D-4 doble banda | No puede ocurrir: cada documento pasa por un solo motor (`ServicioRender.cs:29,33`) | RG-04 |
| D-7 margen | Fijo de 10 mm en una sola constante; las pruebas escriben 25 mm y 20 mm a mano para que un cambio del margen se note | TA-46, TA-50, TA-51 |
| D-8 espiga | B revisó los PDF y PNG de `%TEMP%\GPOS_TEST_ESPIGA_P17007` (no hay registro de qué pruebas pasaron). TA-27: cajas de margen alrededor de la banda, marca y pie encima y completos. TA-43: marca y pie en su sitio. TA-54: ningún PDF trae `/Rotate`; **la guarda debe rechazar `/Rotate` o un número de `/MediaBox` distinto del de páginas**. Ninguno rompe (b): no se pasa a (c) | TA-27, TA-43, TA-54, TA-55 |
| D-1 técnica de lectura | Se adopta la técnica de la espiga (solo la biblioteca base de .NET; no necesita consulta) | Resumen 2 |
| D-2 espiga | Se porta, pero las pruebas van contra el código de producción | Sección 6 |
| D-5 vista previa | Con copia manda la vista previa (`ModeloImpresion.cs:68`) | UO-04 |
| D-6 M-d | Se registra «No aplica» | M-d |
| Otras | P170-07 va en su propio PR, después de T4-02b; contrato versión 1; el pie de hoy sigue sin `!important` (`ServicioRender.cs:128-129`): cambio de una línea que hace B | UO-04 |
| Pendiente | **P-1** (guarda C-1 también en la vista previa con comprobante real): decide el propietario; recomendación de B: sí. Trabajo con «sí» | TA-56, sección 7 |

## 0. Resumen

1. **La espiga ya contiene 23 casos adversarios** (`Adversarios()`, líneas 342-364 [V]) más tres teorías de tamaño. La tabla adversaria de producción **parte de ella** y le agrega lo que la espiga no tiene: la **unidad de las opciones del PDF** (sin Chromium), el **rechazo con la guarda C-1**, el **rollo continuo**, la **paginación original frente a copia** y la **vista previa**.
2. **Hay un desfase entre la hoja y la espiga que hay que resolver:** la hoja (sección 4, punto 1) lista 14 casos; la espiga tiene 23 y usa la lectura de texto con `ZLibStream`/`ToUnicode` y el rasterizado con el visor de Chrome. La hoja (punto 3) dice que **no hay librería de lectura de PDF** y que agregarla exige consulta al propietario; la espiga ya resuelve la lectura **sin librería nueva**. Recomiendo que la prueba de producción adopte esa técnica, pero hay que decidirlo (D-1).
3. **Hallazgo de la espiga que cambia la mitigación [V línea 497]:** `PreferCSSPageSize = false` **no** neutraliza el `@page size` hostil (con alto de 1 mm la hoja sale apaisada, en 21 páginas y sin pie). Por eso la guarda C-1 es la mitigación real y **falla cerrada** (rechaza), no corrige. La prueba tiene que fijar ese rechazo y su código de error .
4. **Cinco mutaciones M-a a M-e** de la hoja (4.4); cada una con el caso que la mata. M-d se refiere a (c) y se registra **«No aplica»** (decisión de B; no se pasa a (c)). Agrego M-f a M-n propias.
5. **Dos huecos que no cubre nada de la hoja ni de la espiga** (sección 5): la marca cuando el texto del encabezado lleva caracteres especiales (codificación del HTML del `HeaderTemplate`) y la copia de la principal (`ServicioImpresion.cs:86-102`) mientras viva.

Niveles: **U** = unitaria sobre las opciones del PDF (`PdfOptions`), sin navegador; **N** = con navegador `[FactConNavegador]` y lectura del PDF; **R** = además rasterizado del visor de Chrome (para visibilidad real, no solo texto).

Constantes de la espiga que el plan usa [V]: `Marca` y `Pie` (textos «COPIA 3» y «Reimpreso el»); `MargenMm = 10`; colores de prueba (marca magenta, capa del atacante verde, título de la plantilla azul); contenido de la plantilla «FACTURA DE CONSUMO», «NCF B0200000001», «Total RD$ 1,180.00».

## 1. Aserciones comunes (se evalúan en cada fila de la tabla 2)

Para la copia `Copia = 3` en carta (215,9 × 279,4 mm) salvo que la fila diga otra cosa:

| Id | Aserción | Cómo | Tipo |
|---|---|---|---|
| A1 | Texto «COPIA 3» presente en **cada página** | `PaginasCon(pdf, Marca) == Paginas(pdf)` | N |
| A2 | Texto «Reimpreso el …» presente en **cada página** | `PaginasCon(pdf, Pie) == Paginas(pdf)` | N |
| A3 | Banda de la marca **visible**: al menos 5 filas con ≥ 30 % de píxeles magenta en la parte superior | `img.Filas(Magenta)` en la mitad de arriba | R |
| A4 | Banda del pie visible, igual abajo | idem mitad de abajo | R |
| A5 | **0 píxeles de la capa del atacante** (verde) dentro de las filas de las bandas | `verdeEnBanda == 0` | R |
| A6 | Contenido fiscal de la plantilla presente (no se perdió «FACTURA DE CONSUMO», NCF y total) | `Contiene(pdf, "FACTURA…")` | N |
| A7 | **El título azul de la plantilla no cae dentro del margen reservado** (la plantilla no invade la banda) | `azulEnMargen == 0`; en los casos de C-2 (`@page{margin:0}`) la espiga mide esto; ver la sección 3 | R |
| A8 | Para la guarda C-1: si la página no cumple alto ≥ 25 mm y ancho ≥ 20 mm, o aparece `/Rotate`, o el número de `/MediaBox` no coincide con el de páginas, **la copia se rechaza**: **400 `FORMATO_INVALIDO` con un texto propio**, y **no se registra ninguna copia** (0 filas en `doc.Impresion`). A1 a A5 no se evalúan | Un código nuevo caería en el caso por omisión de `ClienteRender` y saldría como 503 «el servicio no está», que es falso; la prueba exige 400 | N |

Un caso puede pasar de dos maneras: cumple A1 a A6 (la marca sobrevive), o la guarda lo rechaza (A8). **Ninguna tercera:** una copia sin marca visible que se entrega es el defecto crítico.

## 2. Tabla adversaria

Cada fila trae: caso (nombre de la espiga entre paréntesis), plantilla, qué vector prueba la hoja, qué se espera (A#), qué prueba lo detecta y qué mutación lo mataría.

Los 14 de la hoja (sección 4, punto 1) están marcados **H**; los de la espiga que la hoja no lista, **E**; los nuevos de este plan, **N**.

### 2.1 Vectores de la hoja: búsqueda de `<body>` y `</body>` (con (b) deben ser irrelevantes: la marca ya no está en el HTML)

| Id | Origen | Plantilla (resumen) | Esperado con (b) | Detecta | Muta |
|---|---|---|---|---|---|
| TA-01 | H (`01-comentario-body`) | `<!-- <body> -->` antes del `<body>` real | A1-A6 | N+R | M-e |
| TA-02 | H (`01b-comentario-cierre`) | `<!-- </body> -->` al final | A1-A6 | N+R | M-e |
| TA-03 | H | `<title><body></title>` (el `<body>` dentro del título) | A1-A6 | N | M-e |
| TA-04 | H | `<textarea><body></textarea>` | A1-A6 | N | M-e |
| TA-05 | H | `<style>/*<body>*/</style>` y `<style><body></style>` | A1-A6 | N | M-e |
| TA-06 | H | `<xmp><body></xmp>` | A1-A6 | N | M-e |
| TA-07 | H | `<noembed><body></noembed>` | A1-A6 | N | M-e |
| TA-08 | H | `<template><body></template>` | A1-A6 | N | M-e |
| TA-09 | H | `<div title="<body>">…</div>` | A1-A6 | N | M-e |
| TA-10 | H | CDATA en `<svg>`: `<svg><![CDATA[<body>]]></svg>` | A1-A6 | N | M-e |
| TA-11 | H | `<bodyx>` (nombre que casa con la búsqueda literal) | A1-A6 | N | M-e |
| TA-12 | H (`02-script-body`) | `<script><body></script>` (la capa 0 borra todos los `<script>` **después**, `ServicioRender.cs:56-57`) | A1-A6. Con (b) la marca no pasa por la capa 0, así que no debe desaparecer | N | M-e, M-h |
| TA-13 | N | `<BODY>`, `<Body>` y `<body\n>` (mayúsculas, salto de línea) | A1-A6 | N | M-e |
| TA-14 | N | Dos `<body>` reales y dos `</body>` | A1-A6 | N | M-e |
| TA-15 | N | Sin `<body>` ni `</body>` (fragmento) | A1-A6 | N | M-e |
| TA-16 | N | `<body>` con `<!--[if IE]>…` (comentario condicional) | A1-A6 | N | M-e |

Las filas TA-03 a TA-11 y TA-13 a TA-16 no están en la espiga (solo `01`, `01b`, `02`). Con (b) deberían ser verdes por construcción; las incluyo porque su valor es **negativo**: demuestran que (b) no depende del analizador, y son baratas (un `Theory` sobre una lista de cadenas). **Decisión:** se mantienen en una sola `Theory` con `[MemberData]` y un solo Chromium por colección (R-T402-07 del blueprint: la suite se vuelve lenta con muchos navegadores).

### 2.2 Vectores de CSS

| Id | Origen | Plantilla | Esperado | Detecta | Muta |
|---|---|---|---|---|---|
| TA-20 | H (`03-display-none`) | `div{display:none !important} *{display:none !important}` | A1-A5 (la marca no vive en el DOM de la plantilla, así que no se oculta) | R | M-a, M-e |
| TA-21 | H (`04-capa-opaca-zindex`) | capa `position:fixed` de 100 % y `z-index:2147483647` verde después | A3, A4, A5 (0 verde dentro de las bandas) | R | M-c, M-e |
| TA-22 | E (`04b-capa-opaca-desbordada`) | capa `absolute` de 500 mm desde `-80 mm` | Idem | R | M-c |
| TA-23 | H (`05-overflow-alto-cero`) | `html,body{overflow:hidden;height:0}` | A1-A6 | R | M-e |
| TA-24 | E (`10-html-display-none`) | `html{display:none !important}` | La marca (encabezado) **se ve**; el contenido de la plantilla desaparece. A1, A2, A3, A4; **A6 no aplica**; documentar | R | M-e |
| TA-25 | H (`07-fixed-top-negativo`) | `position:fixed;top:-20mm;height:40mm` verde | A5 (el verde no entra en la banda) | R | M-c |
| TA-26 | E (`07b-margen-negativo`) | `margin-top:-60mm;height:30mm` verde | A5 | R | M-c |
| TA-27 | E (`08-caja-de-margen`) | `@page{@top-center{content:'TAPA';background:#00ff00} @bottom-center{…}}` (cajas de margen CSS) | A5. **Resuelto por B** (revisó los PDF y PNG de la corrida de la espiga): las cajas de margen se pintan alrededor de la banda y la marca y el pie quedan encima y completos. No rompe (b) | R | M-c, M-f |
| TA-28 | E (`09-transform-escala`) | `body{transform:scale(3)}` + bloque verde | A5 | R | M-c |
| TA-29 | N | `@media print{*{visibility:hidden}}` y `@media print{body{display:none}}` | A3, A4 (la marca no está en el DOM) | R | M-a |
| TA-30 | N | `html{filter:opacity(0)}` o `mix-blend-mode` a pantalla completa | A3, A4, A5 | R | M-c |
| TA-31 | N | `position:fixed` + `z-index` + `top:0;height:12mm;background:magenta` (la plantilla **imita** la marca en el mismo color) | A5 no sirve (mismo color): la prueba usa un **color de marca distinto** del color de la capa; documentar que la imitación visual no es detectable por píxeles | R | — |

TA-31 es un límite honesto: la plantilla puede **pintar una marca falsa** («COPIA 1» en lugar de «COPIA 3») además de la verdadera. La hoja no lo contempla. El control es el **texto** (A1 con el número exacto) y que haya **una sola** banda (D-4).

### 2.3 Vectores de `@page` (márgenes y tamaño) — la parte más delicada, ligada a C-1 y C-2

| Id | Origen | Plantilla | Esperado | Detecta | Muta |
|---|---|---|---|---|---|
| TA-40 | H (`06-page-margin-0`) | `@page{margin:0}` | **C-2 aceptado:** A1 a A5 se cumplen y la banda **puede tapar la parte de arriba** del contenido. A7 **no es exigible** (es lo aceptado). La prueba mide cuánto tapa (`azulEnMargen`) y lo registra; el esperado fijo: A1, A2, A3, A4, A5 | R | M-c, M-g |
| TA-41 | E (`06b-…-important`) | `@page{margin:0 !important} @page :first{margin:0 !important}` | Igual que TA-40 | R | M-c, M-g |
| TA-42 | E (`06f-pagina-con-nombre`) | `@page tapa:first{margin:0 !important} body{page:tapa}` | Igual que TA-40 | R | M-g |
| TA-43 | E (`06e-page-margen-enorme`) | `@page{margin-top:150mm}` | A1, A2. **Resuelto por B:** la marca y el pie salen en su sitio y la plantilla solo baja su contenido | R | M-g |
| TA-44 | E (`06c-page-size-y-margen`) | `@page{size:100mm 60mm;margin:0}` | La página mide 100 × 60 mm: **cumple C-1** (60 ≥ 25 y 100 ≥ 20): A1 a A5 deben cumplirse | N+R | M-i |
| TA-45 | H (`06d-page-size-diminuto`) | `@page{size:80mm 15mm;margin:0}` | 15 mm < 25 mm: **la guarda C-1 la RECHAZA** (A8). Sin guarda pierde la marca o el pie (la espiga lo documenta) | N | M-i |
| TA-46 | H (`06h-page-alto-25mm`) | `@page{size:216mm 25mm;margin:0}` | **Límite exacto**: 25 mm = 2 × 10 + 5 → la guarda **admite** (≥) y A1 a A5 se cumplen. Si el `/MediaBox` redondea (24,99 mm), la guarda rechaza: la prueba fija cuál; [I] riesgo de un valor al borde | N+R | M-j |
| TA-47 | H (`06g-page-alto-1mm`) | `@page{size:216mm 1mm;margin:0}` | **RECHAZADA** (A8). La espiga halló que con `PreferCSSPageSize=false` la hoja sale apaisada en 21 páginas y sin pie [V línea 497]: el rechazo debe ocurrir **sobre el PDF generado**, no sobre la plantilla | N | M-i, M-k |
| TA-48 | H (`06i-page-ancho-1mm`) | `@page{size:1mm 279mm;margin:0}` | 1 mm < 20 mm: **RECHAZADA** (A8) | N | M-i |
| TA-49 | H (`06j-segunda-pagina-diminuta`) | `@page chica{size:216mm 1mm;margin:0} .x{page:chica}` + `<div class="x">OCULTO</div>` | Una **segunda página** diminuta: la guarda debe mirar **todas** las páginas, no solo la primera. **RECHAZADA** (A8) | N | M-k |
| TA-50 | N | Umbral de ancho: `@page{size:19mm 279mm}`, `20mm`, `21mm` | 19: rechaza; 20: admite (≥); 21: admite | N | M-j |
| TA-51 | N | Umbral de alto: `24mm`, `25mm`, `26mm` | 24: rechaza; 25: admite; 26: admite | N | M-j |
| TA-52 | N | Documento de muchas páginas donde **solo la 20.ª** tiene tamaño hostil (`@page :nth(20)` no existe; usar varios `page:` con nombre) | Rechazada: la guarda recorre todos los `/MediaBox` | N | M-k |
| TA-53 | N | Documento de 200 páginas | Todas con marca y pie; el recorrido de `/MediaBox` es lineal (tiempo < 2 s) [I] | N | M-k |
| TA-54 | N | `/MediaBox` apaisado: Chromium intercambia ancho y alto, **ningún PDF trae `/Rotate`** (hallazgo de B) | La guarda **rechaza** si aparece `/Rotate` (400 `FORMATO_INVALIDO`, A8). Caso con un PDF sintético que lo trae | N | M-i, M-w |
| TA-55 | N | `/MediaBox` en número distinto del de páginas (PDF sintético, o un PDF con una página extra de caja) | La guarda **rechaza** (A8) | N | M-w |
| TA-56 | N | Vista previa con comprobante real y tamaño hostil (P-1, **pendiente del propietario**; recomendación de B: la guarda también aplica en la vista previa) | Con P-1 = sí: 400 `FORMATO_INVALIDO`; con P-1 = no, la vista previa puede salir sin «SIN VALOR FISCAL». Se escribe con el supuesto de trabajo «sí» y se marca | N | M-i |

### 2.4 Posiciones y tamaños no relacionados con `@page`

| Id | Plantilla | Esperado |
|---|---|---|
| TA-60 | `position:fixed` que se repite en cada página y cubre el margen inferior | A4, A5 (0 verde en la banda del pie) |
| TA-61 | `<iframe src="about:blank">` o `<object>` a pantalla completa | A3, A4, A5; el JavaScript está apagado [V ConvertidorPdf.cs:259 de la hoja] |
| TA-62 | Contenido muy alto en una sola caja (no corta página) | A1, A2 en cada página que Chromium genere |
| TA-63 | Imagen de fondo en `body` con `background-attachment:fixed` | A3 a A5 |

## 3. Casos de la unidad (sin navegador) — lo que la hoja pide en el punto 2

La hoja (4.2) exige pruebas **unitarias de las opciones del PDF**. Son baratas, deterministas y no dependen de Chromium; deben ser **la primera línea** (la tabla 2 es la segunda).

| Id | Caso | Esperado | Muta |
|---|---|---|---|
| UO-01 | `Copia = 3`, papel carta | `DisplayHeaderFooter = true`; `HeaderTemplate` contiene «COPIA 3»; `FooterTemplate` contiene «Reimpreso el»; `MarginOptions.Top` y `.Bottom` > 0 | M-a, M-b, M-c |
| UO-02 | `Copia = 0` y sin vista previa | `DisplayHeaderFooter = false` (o plantillas vacías); márgenes **iguales a los del original** (la hoja 5: «los originales no cambian si el margen se reserva solo en las copias») | M-l |
| UO-03 | Vista previa (`VistaPreviaSinValor`) | Encabezado «VISTA PREVIA – SIN VALOR FISCAL»; **no** «Reimpreso el» | M-m |
| UO-04 | Vista previa con `Copia > 0` | **Manda la vista previa** (`ModeloImpresion.cs:68`): encabezado «SIN VALOR FISCAL», sin «Reimpreso el» como marca de copia. Replicar el orden de `MarcarCopia` [V `ServicioRender.cs:115-134`]. El pie de hoy **no lleva `!important`** (`ServicioRender.cs:128-129`): B lo cambia en una línea de la hoja y la prueba lo fija | M-m
| UO-05 | Copia en rollo continuo (`papel.Continuo`) | Alto del PDF = alto del contenido **+ margen superior + margen inferior** (`ConvertidorPdf.cs:196-201`, pregunta 3 de la espiga) | M-n |
| UO-06 | `PreferCSSPageSize` | Documentar el valor para copia y original (la espiga halló que `false` **no** mitiga); la prueba fija el valor elegido | M-o |
| UO-07 | El texto «Copia n» con `n` de 1 a 999 | Sale el número exacto; no hay «COPIA 3» para `Copia = 4` | M-p |
| UO-08 | Codificación del HTML del encabezado | Un nombre de empresa o usuario con `<`, `&`, `"` y `'` se codifica (el `HeaderTemplate` es HTML de Chromium); `<script>` en un nombre no se ejecuta ni rompe la plantilla (hoja 4.2: «el encabezado lleva el texto codificado») | M-q |
| UO-09 | Fecha «Reimpreso el»: formato y zona (hora del servidor) | Mismo formato que hoy; comparar con la salida de `MarcarCopia` | M-r |
| UO-10 | Clases de Chromium del encabezado (`date`, `title`, `pageNumber`, `totalPages`) | El `HeaderTemplate` no incluye `title` ni `url` (Chromium las rellena con el título de la plantilla; una plantilla con `<title>` distinto **no puede** inyectar texto en el encabezado) | M-s |

UO-10 es un vector que la hoja y la espiga no cubren: Chromium sustituye `<span class="title">` por el `<title>` del documento, que **controla la plantilla**. Con una plantilla de `<title>` hostil, esa sustitución metería texto del atacante en la marca. Por eso la prueba exige que la marca no use las clases de sustitución.

## 4. Mutaciones M-a a M-e de la hoja (sección 4.4) y las que agrego

Cada mutación se aplica sobre el código de producción en una rama temporal, se corre la tabla y **debe fallar al menos una prueba**; se informa el resultado real. Las de la hoja:

| Id | Hoja | Qué cambia | La mata | Debe fallar |
|---|---|---|---|---|
| **M-a** | `DisplayHeaderFooter = false` | La marca no se dibuja | UO-01, y toda la tabla 2 por A1/A3 (la marca falta en **todos** los casos) | Sí: UO-01 (U) y TA-01 a TA-63 (N). Mutación **fuerte**: si no mata a casi todo, la tabla está vacía |
| **M-b** | quitar el `FooterTemplate` | El pie «Reimpreso el» no sale | UO-01 (pie), A2 y A4 en toda la tabla 2 | Sí |
| **M-c** | márgenes a cero | La marca cae sobre el contenido o no se dibuja | UO-01 (márgenes > 0), A5 y A7 en TA-21, 22, 25, 26, 27, 28, 30, 60 | Sí |
| **M-d** | con (c): «exactamente una» → «al menos una» | Solo aplica al respaldo (c) | **No aplica** (decisión de B): con (b) no hay conteo de `<body>`; se registra «No aplica» en el informe |
| **M-e** | volver a insertar la banda en el HTML sin el encabezado | Regresa el vector original | TA-01 a TA-16 (los de comentario y `<script>`), TA-12 en particular, TA-20 (`display:none !important`) | Sí: la hoja pide que mate «los casos de comentario y de `<script>`» |

Adicionales de este plan:

| Id | Qué cambia | La mata | Estado |
|---|---|---|---|
| M-f | El `HeaderTemplate` usa `position:fixed` o `z-index` dentro del encabezado | TA-27 (cajas de margen) y A5 | Mata solo si TA-27 corre en el visor real; no la mata nada sin R |
| M-g | El margen superior se reserva **solo si la plantilla no define `@page`** (el margen de la plantilla manda) | TA-40, TA-41, TA-42 (la marca debe seguir: C-2) | Mata |
| M-h | La capa 0 (`ServicioRender.cs:56-57`) se mueve **después** de estampar la marca (con (b) no hay estampado en el HTML) | TA-12 | Con (b) es equivalente; documentar |
| M-i | Guarda C-1 deshabilitada (siempre admite) | TA-45, TA-47, TA-48, TA-49, TA-54 | Mata |
| M-j | Guarda con `>` en vez de `>=` (o 24 mm / 26 mm en lugar de 25 mm) | TA-46, TA-50, TA-51 (los umbrales exactos) | Mata |
| M-k | La guarda mira solo la primera página | TA-49, TA-52 | Mata |
| M-l | El margen de la copia se aplica también al original | UO-02 | Mata |
| M-m | Vista previa muestra «COPIA n» en lugar de «SIN VALOR FISCAL» | UO-03 | Mata |
| M-n | El rollo continuo no suma el alto del encabezado/pie | UO-05 | Mata |
| M-o | `PreferCSSPageSize` cambia a `false`/`true` | UO-06 | Mata (fija el valor) |
| M-p | El número de copia es siempre 1, o resta uno | UO-07, TA-01 (A1 con «COPIA 3») | Mata |
| M-q | El texto del encabezado no se codifica | UO-08 | Mata |
| M-r | La fecha pierde el formato | UO-09 | Mata |
| M-s | El `HeaderTemplate` incluye `<span class="title">` | UO-10 | Mata |
| M-t | La copia de la principal (`ServicioImpresion.cs:86-102`) se queda con el `Regex` y la API de reportes usa (b) | `ReglasReimpresionTests` adaptado y TA-01 a TA-12 contra la principal mientras viva | **No la mata nada hoy** si la principal ya no renderiza (T4-02b); mutación a aplicar solo si T4-02 se retrasa |
| M-u | El rechazo de C-1 devuelve 200 con el PDF sin marca, o responde 503/otro código, o registra la copia, en lugar de 400 `FORMATO_INVALIDO` | Aserción de A8 (código HTTP y 0 filas) | Mata |
| M-v | La guarda rechaza por `Pages` pero no por `/MediaBox` (usa una propiedad de Chromium) | TA-46 (borde), TA-54 | Mata |
| M-w | La guarda no rechaza `/Rotate` ni un número de `/MediaBox` distinto del de páginas | TA-54, TA-55 | Mata |

## 5. Regresión y huecos

| Id | Caso | Esperado |
|---|---|---|
| RG-01 | Dorados de las plantillas base en **original** (`PlantillasRazor`, `GeneradorRazor`) | Idénticos a los de hoy (hoja 4.5); cualquier cambio es hallazgo |
| RG-02 | Dorados en **copia** | Cambian solo el encabezado, el pie y los márgenes (hoja 4.5). La prueba compara el contenido de la hoja (texto del cuerpo) y excluye las bandas |
| RG-03 | Paginación original frente a copia en una tabla en carta con `@page{margin:0}`, `@page{margin:15mm}` y sin `@page` (pregunta 4 de la espiga: primera cantidad de filas que pasa a 2 páginas con 10, 15 y 20 mm) | La copia puede paginar **distinto** (aceptado por la hoja, sección 6): la prueba **fija** la diferencia de filas con el margen de 10 mm, para que un cambio de margen se note |
| RG-04 | Cada documento pasa por **un solo motor** (`ServicioRender.cs:29,33`): no puede haber doble banda con QuestPDF (respuesta de B). Prueba: un formato estándar de QuestPDF con `Copia > 0` tiene una sola banda | Una sola banda |
| RG-05 | `ReglasReimpresionTests.cs:79-101` y `ChromiumAisladoTests.cs:1934-1966` (las dos pruebas existentes de la marca, solo con plantillas bien formadas [V hoja]) | Se **reemplazan** por las de este plan; no se dejan en paralelo comprobando el mecanismo viejo |
| RG-06 | Control negativo (espiga: `Control_sin_copia_no_hay_marca`) | Original sin copia: sin texto de marca y sin banda magenta, con el contenido presente |
| RG-07 | `[FactConNavegador]` en CI sin Chromium | Se omiten con motivo; las **U** (UO-01 a UO-10) siguen corriendo: la marca nunca queda sin ninguna prueba |

**Huecos que no cubre nada de esto:**
1. **Imitación visual** (TA-31): la plantilla puede pintar texto como «COPIA 1». No se detecta por píxeles. Mitigación parcial: A1 exige el número exacto y una sola banda.
2. **Lectura de PDF por texto sin librería**: la técnica de la espiga (flujos con `ZLibStream` y `ToUnicode`) es frágil ante cambios de Chromium (otra codificación o una fuente sin `ToUnicode`). Si falla, A1/A2 dan falsos negativos. Mitigación: un control positivo (RG-06 al revés: el PDF de la copia limpia **sí** contiene la marca).
3. **Visor de Chrome para rasterizar:** distinto del Chromium que genera; el rasterizado de la espiga cubre solo la primera página y a 1000 × 1300 [V línea 220]. A3/A4/A5 son de la **primera página**. Para el resto, solo el texto.
4. **Chromium en Edge:** el camino L-1 de T4-03 (lo que no se verificó en #170) cambia el navegador; las pruebas N deben correr también con Edge cuando se haga esa verificación.
5. **Versiones:** el comportamiento del encabezado cambia entre versiones de Chromium. Registrar la versión usada en el informe de mutaciones.

## 6. Orden y esfuerzo [I]

| Tanda | Contenido | dp |
|---|---|---|
| T0 | UO-01 a UO-10 (sin navegador) y sus mutaciones M-a, M-b, M-c, M-l a M-s | 0,5 |
| T1 | Tabla 2 sobre la técnica de la espiga (N y R), incluidas TA-45 a TA-54 con la guarda C-1 | 0,75 |
| T2 | M-a a M-e y M-f a M-v, con el informe de resultados reales | 0,5 |
| T3 | RG-01 a RG-07 | 0,25 |
| Total | | **2,0** (±50 %) |

La hoja estima 1 a 1,25 dp para construir (b); estas pruebas son aparte (la hoja dice «todas de B»). La espiga (576 líneas) ya cubre ~40 % de la tabla 2 y puede **portarse** en lugar de reescribirse.

## 7. Dudas abiertas (las resueltas están en «Respuestas de B»)

| # | Duda | Quién |
|---|---|---|
| P-1 | ¿La guarda C-1 también en la vista previa con un comprobante real? Recomendación de B: sí (0 dp). Pendiente del propietario; TA-56 se escribe con «sí» como supuesto de trabajo | Propietario |


### Cierre
- Estado: Completado (plan; sin ejecutar)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-23-plan-tabla-adversaria-p170-07.md`
- Supuestos: la espiga leída en `e112ae91` es la vigente; MargenMm = 10 mm es el valor definitivo
- Decisiones candidatas a ADR: Ninguna
- Entregas a otros agentes: Propietario → P-1; A → revisar TA-31 (imitación visual) como riesgo residual
- Próximo paso recomendado: el propietario firma P-1; B construye P170-07 en su propio PR, después de T4-02b
