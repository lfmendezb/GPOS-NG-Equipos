```
Para: B                         De: C (QA)                    Fecha: 2026-10-20
Tipo: Revisión de pruebas, solo lectura (tarea 1 de la cola del 2026-10-20)
PR: #119 (T1-7, RQ-R12), rama b/t1-7-rq-r12, contra feature/modelo-ng @ b8f166db
Estado: Abierto
```

# Revisión de pruebas del PR #119 (T1-7 · RQ-R12)

## Dictamen: Suficiente con observaciones

Las cinco pruebas que nombra el plan de D1 (T1-7) existen y las cuatro de `GeneradorRazorSeguroTests` ejercitan los caminos que dicen probar. El recorrido por reflexión de `Ninguna_propiedad_de_texto…` cumple lo que pide ADR-38 («una prueba que recorra todos los campos del diseño»). No hay ningún defecto Crítico ni Alto. Lo que falta son pruebas de ejecución real (el motor Razor, el registro 4790, la ruta HTTP de guardado), los bordes de configuración y del alfabeto, y la pantalla del diseñador.

Alcance de la revisión: lectura de `git diff b8f166db origin/b/t1-7-rq-r12` y del código de la rama; no se compiló ni se ejecutó nada. «Verificado» abajo significa leído en la rama; lo que se infiere se marca *inferido*.

## Lo que está bien (verificado en la rama)

- `ImagenDiseno.cs:52-65`: el borde de 300 KB tiene prueba exacta: 307 200 bytes pasa y 307 201 falla (`GeneradorRazorSeguroTests.cs:144-150`, `:159-163`) y se repite al guardar (`:159-163`).
- La compuerta `Emitible` evita falsos 400 por imágenes que el generador nunca emitiría (`ImagenDiseno.cs:46-47`, `FormatosService.cs:204-208`).
- La mayúscula de `DATA:IMAGE/PNG…` (cambio declarado en el PR) tiene su caso (`GeneradorRazorSeguroTests.cs:124`).
- Control positivo del PDF: `ImagenWebpRenderTests.cs:75-78` compara contra el PNG de control y contra «sin imagen», así que no pasa por un PDF vacío.
- `EventIdUnicosTests` recoge la declaración `new(4790,"FormatoImagenOmitida")` con su patrón (`ServicioImpresion.cs:18`), así que un choque con otro 4790 en `src/` se detecta.
- MAUI: el cambio es el mismo texto que el de Web y `ComponentesCompartidosTests` (`tests/GPOS.Web.Tests/ComponentesCompartidosTests.cs:19`) compara `DisenadorVisual.razor` de Web y de MAUI. **Dato nuevo para NU1301:** la identidad de los dos archivos queda cubierta por una prueba que B sí puede correr sin compilar MAUI; conviene citarla en el PR (`--filter "FullyQualifiedName~ComponentesCompartidosTests"` en `GPOS.Web.Tests`).

## Hallazgos

### P119-01 · Media · El alfabeto base64 está probado con un solo carácter inválido y sin afirmar el motivo
- **Evidencia:** `ImagenDiseno.cs:56-62` (longitud y alfabeto); `GeneradorRazorSeguroTests.cs:118-125` y `:135`.
- **Detalle:** de los ocho datos del `Theory`, solo `iVBO" onerror="x` (16 caracteres) llega al bucle del alfabeto. `@Model.Numero` (13), `iVB` (3) y vacío caen por la longitud o por el prefijo. El `Assert` de `:133` es `NotEqual(Valida, …)`: no distingue `NoBase64` de `TipoNoPermitido` ni de `ExcedeTope`; si el bucle se quitara y el caso cayera en otra rama, la prueba seguiría verde.
- **Prueba propuesta:** `GeneradorRazorSeguroTests.Evaluar_clasifica_cada_caracter_fuera_del_alfabeto_como_NoBase64` (`[Theory]`, todas con largo múltiplo de 4 para no caer por longitud): `AA@A`, `AA<A`, `AA A`, `AA\nA`, `AA-_`, `AÑAA`, `A=AA` (relleno en medio), `A===`, `====`, `AAAA` con un cero ancho. Afirma `Assert.Equal(Resultado.NoBase64, ImagenDiseno.Evaluar("data:image/png;base64," + x))` y, para los que llevan `@`, que `Generar` no emite `<img` y que `omitidas.Single().Motivo == NoBase64`. Añade el caso válido con relleno `AAA=` y `AA==` → `Valida`, para fijar que el relleno legítimo sigue pasando.

### P119-02 · Media · Ninguna prueba hace pasar el payload por el motor Razor
- **Evidencia:** `GeneradorRazorSeguroTests.cs:61-73` comprueba arrobas en la cadena (`SinArrobaSuelta`) y que `ValidarPlantilla` (un filtro de expresión regular, `FormatosService.cs:190-197`) no se queje. `ImagenWebpRenderTests` renderiza solo imágenes válidas.
- **Detalle:** el requisito es que el modo gráfico no ejecute código (BP3 10.3; ADR-38 «M-3»). La prueba afirma una propiedad de la cadena, no el comportamiento del motor. Además, para `Texto`, `Titulo`, etc., no se afirma que el valor aparezca escapado (solo que no aparece una arroba suelta): una regresión que suprima el campo entero también pasa.
- **Prueba propuesta:** `GeneradorRazorSeguroTests.Un_texto_del_diseno_con_codigo_Razor_se_imprime_literal_y_no_se_evalua`. Diseño con `Texto = "@(7*7) @Model.Numero @{ var x = 1; }"`, `Titulo` de columna igual; genera con `GeneradorRazor.Generar`, la pasa por `MotorRazor.RenderizarAsync` con `fabrica.EjemploAsync` (mismo escenario que `ImagenWebpRenderTests`, con `api.Services.CreateScope()`) y afirma: el HTML contiene `@(7*7)` literal, no contiene `49`, y contiene el texto con `&lt;`/`&quot;` donde corresponda. Añade el control: el campo del catálogo `Numero` sí se evalúa (el número de ejemplo aparece), para que la prueba no pase con un motor que no renderiza nada.

### P119-03 · Media · El evento 4790 y su registro no tienen prueba
- **Evidencia:** `ServicioImpresion.cs:18` (id y nombre), `:73-76` (el `LogWarning`); ninguna prueba nombra `EventoImagenOmitida` ni 4790 (`git grep 4790 -- tests` sin resultados).
- **Detalle:** la tarea dice «al imprimir se omite con el evento 4790 `FormatoImagenOmitida`». La omisión sí se prueba (`omitidas`), pero no que el servicio la registre, ni que el registro no contenga la imagen, ni el recorte del `ElementoId` a 32 caracteres (`:75`). El `Id` del elemento viene del JSON del cliente: `\r\n` en el id no se prueba.
- **Prueba propuesta:** `ImagenWebpRenderTests.Imprimir_un_formato_con_imagen_svg_registra_el_evento_4790_sin_el_contenido`. Con `ApiBusquedaFactory` y un `ILoggerProvider` en memoria (`WithWebHostBuilder` + `ConfigureLogging`; hay un `RegistroMemoria` equivalente en `tests/GPOS.Tests/Acceso/LlavesFirmaPruebas.cs` en el PR #120, que puede copiarse sin paquetes nuevos), vista previa con SVG y afirma: una sola entrada de nivel `Warning`, `EventId.Id == 4790`, `Name == "FormatoImagenOmitida"`, el mensaje contiene el motivo `TipoNoPermitido` y no contiene la cadena base64. Segunda prueba: `…El_id_del_elemento_se_recorta_a_32_caracteres` con un `Id` de 80 caracteres.

### P119-04 · Media · El tope de 360 KB «cabe» solo con una imagen; con dos el mensaje es otro
- **Evidencia:** `ImagenDiseno.cs:14-18` (el comentario afirma que 360 KB caben en los 500 000 caracteres); `FormatosService.cs:80-81` (`ValidarPlantilla` va antes de `ValidarDiseno`) y `:197`; `ImpresionEndpoints.cs:92-96` (el servidor regenera la plantilla con las imágenes dentro); prueba solo con una imagen: `GeneradorRazorSeguroTests.cs:154-156`.
- **Detalle:** dos imágenes válidas de 200 KB (273 000 caracteres cada una) suman más de 500 000: se rechaza con «La plantilla es demasiado grande», que no nombra la imagen ni el tope, aunque cada imagen cumpla. *Inferido* por lectura (no se ejecutó). No es una regresión (antes pasaba lo mismo con el límite de la plantilla), pero la documentación del tope promete lo contrario.
- **Prueba propuesta:** `GeneradorRazorSeguroTests.Dos_imagenes_validas_que_suman_mas_de_500000_caracteres_se_rechazan_con_un_mensaje_que_lo_explica`: encabezado y pie con 200 KB cada uno; afirma la regla que B decida (la recomendada: que `ValidarDiseno` sume las imágenes y diga «las imágenes del formato suman X KB; el máximo es Y KB»; si se deja el mensaje genérico, la prueba lo fija y corrige el comentario de `ImagenDiseno.cs:14`).

### P119-05 · Media · La ruta HTTP de guardado (400) y la impresión de un formato ya guardado no se ejercitan
- **Evidencia:** `GeneradorRazorSeguroTests.cs:89` (`SinBase()` con `new(null!, new SesionPrueba())`) llama a `FormatosService.GuardarAsync` directo; `ImpresionEndpoints.cs:92-96` regenera `dto.Plantilla` antes de guardar; `Program.cs:484` traduce `ReglaNegocioException` a 400.
- **Detalle:** el criterio de la tarea es «una imagen SVG, no base64 o sobre el tope da 400». Se prueba la excepción, no el 400, ni el mensaje que recibe el diseñador. Tampoco se prueba el caso de «un SVG guardado antes de RQ-R12»: `GeneradorRazorSeguroTests.cs:110-114` lo simula con `Generar` directo, pero no con la fila guardada que lee `ObtenerAsync` y deserializa `ADto` (`FormatosService.cs:170-175`) antes de `PersonalizadoAsync`.
- **Pruebas propuestas:**
  - `ImagenWebpRenderTests.POST_admin_formatos_con_imagen_svg_responde_400_con_el_mensaje_de_SVG` (afirma código 400 y que el cuerpo contiene «SVG»; con PNG responde 200 y el formato queda guardado).
  - `…POST_admin_formatos_con_imagen_sobre_el_tope_responde_400_con_el_tope_en_KB`.
  - `…Un_formato_guardado_antes_con_svg_se_imprime_sin_la_imagen`: inserta la fila con el diseño que contiene SVG por SQL o por el contexto de pruebas, imprime con `DocumentoAsync` por formato y afirma 200, PDF sin objeto de imagen y 4790 registrado.

### P119-06 · Media · La configuración del tope y su estado estático no se prueban
- **Evidencia:** `Program.cs:327` (lee `Impresion:TopeImagenBytes`); `ImagenDiseno.cs:20-30` (setter con recorte); `GeneradorRazorSeguroTests.cs:159` (`Assert.Equal(TopePorOmision, TopeBytes)`).
- **Detalle:**
  1. El recorte a 360 KB y el valor menor que 1 no tienen prueba.
  2. `TopeBytes` es estático y mutable: la afirmación de `:159` depende de que ninguna otra clase de la misma ejecución (por ejemplo una `WebApplicationFactory<Program>` con la clave configurada) lo cambie, y una prueba que lo cambie sin restaurarlo contaminaría a las demás.
  3. El tope por omisión es múltiplo de 3 (307 200 = 3 × 102 400), por lo que el cálculo del relleno (`ImagenDiseno.cs:57,63`) nunca se distingue en el borde por omisión: un error en el relleno solo se vería con otro tope.
  4. `Program.cs:327` usa `GetValue<int?>`: un valor no numérico en la configuración lanza al arrancar (*inferido*).
- **Pruebas propuestas:**
  - `GeneradorRazorSeguroTests.TopeBytes_se_recorta_al_maximo_y_un_valor_menor_que_1_deja_el_de_omision` (restaura en `finally`; la clase va en una `[Collection("ImagenTope")]` sin paralelismo con las demás que usan `ImagenDiseno`): `int.MaxValue` → `TopeMaximo`; `0` y `-5` → `TopePorOmision`.
  - `…Evaluar_cuenta_el_relleno_con_un_tope_que_no_es_multiplo_de_3`: tope 4 → `AAAAAA==` (4 bytes) `Valida`, `AAAAAAA=` (5 bytes) `ExcedeTope`; tope 5 → 5 bytes `Valida`.
  - `…Impresion_TopeImagenBytes_no_numerico_falla_con_un_mensaje_claro` solo si B decide tratarlo (hoy lanza al arrancar).

### P119-07 · Media · El diseñador (Web y MAUI) no tiene prueba: cualquier tipo del navegador se convierte en data URI
- **Evidencia:** `src/GPOS.Web/Components/Pages/Admin/DisenadorVisual.razor:155` (`Accept` solo es una sugerencia del selector), `:503-506` (`data:{archivo.ContentType};base64,…` sin validar); en contraste, `Parametros.razor:166` valida el tipo del logo con la lista de cuatro. Mismo código en MAUI. Existen pruebas bUnit del mismo componente (`LienzoZoomTests.cs:22-27`, `LienzoSeleccionMultipleTests.cs:195-200`).
- **Detalle:** con «Todos los archivos» el usuario elige un `.svg` (o un tipo vacío/`image/x-png`); el diseñador lo acepta, lo muestra en el lienzo (`DisenadorVisual.razor:368`) y el 400 solo llega al guardar, sin indicar qué elemento. El diseñador usa `TopePorOmision` aunque el servidor tenga otro tope configurado (`ImagenDiseno.TopeBytes`): con un tope menor, la pantalla deja pasar lo que el servidor rechazará.
- **Pruebas propuestas** (bUnit, ya en el proyecto; sin paquetes nuevos):
  - `DisenadorImagenTests.El_selector_acepta_png_jpg_jpeg_gif_y_webp_y_no_svg` (lee el atributo `accept`).
  - `…CargarImagen_con_un_svg_avisa_y_no_asigna_Imagen` (requiere que B valide `archivo.ContentType` contra `ImagenDiseno.TiposPermitidos` como hace `Parametros.razor:166`).
  - `…CargarImagen_de_307200_bytes_se_acepta_y_de_307201_avisa` (el borde de la pantalla).
  - `…Un_formato_antiguo_con_svg_se_ve_en_el_lienzo_pero_se_marca_como_omitida` solo si B decide avisar en el lienzo (hoy el lienzo muestra la imagen que la impresión omitirá).

### P119-08 · Baja · El contenido real no se compara con el tipo declarado
- **Evidencia:** `ImagenDiseno.cs:52-65` (solo el prefijo y el alfabeto); el texto de BP3 10.3 no pide firma de archivo.
- **Detalle:** `data:image/png;base64,` seguido de los bytes de un SVG, o de texto cualquiera, pasa como válida. Por cómo se incrusta (`<img src>` en Chromium) el riesgo es bajo: una imagen en `<img>` no ejecuta scripts y Chromium no interpreta como SVG un data URI de tipo `image/png` (*inferido*, no verificado). El efecto práctico es una imagen rota en el papel.
- **Prueba propuesta (documenta el comportamiento actual sin tocar código):** `ImagenWebpRenderTests.Un_svg_declarado_como_png_no_se_incrusta_en_el_PDF`: vista previa con `data:image/png;base64,` + base64 de un `<svg …/>`; afirma que `Imagenes(pdf) == sinImagen`. Si B prefiere cerrar el hueco en el código: `Evaluar_rechaza_un_contenido_que_no_empieza_con_la_firma_de_su_tipo` (PNG `89 50 4E 47`, JPEG `FF D8 FF`, GIF `GIF8`, WEBP `RIFF….WEBP`).

### P119-09 · Baja · Una prueba con nombre que no dice lo que prueba
- **Evidencia:** `GeneradorRazorSeguroTests.cs:141-167`, `Una_imagen_de_mas_de_2_MB_se_rechaza` (el propio comentario de `:138-140` explica que el tope es 300 KB).
- **Detalle:** el nombre viene del plan (2 MB) y quedó desfasado tras la opción A. Quien lea un fallo de CI pensará en 2 MB. Además hace seis comprobaciones de naturaleza distinta en una sola prueba.
- **Propuesta:** renombrar a `Una_imagen_sobre_el_tope_de_300_KB_se_rechaza` y separar el caso de configuración (`Evaluar` con tope explícito) y el del borde al guardar. Los nombres originales del plan se conservan como alias solo si B quiere trazabilidad literal con T1-7.

### P119-10 · Baja · `ValidarDiseno` tolera bandas y elementos nulos; `GeneradorRazor` no
- **Evidencia:** `FormatosService.cs:204-208` (`b?.Elementos ?? []`, `e is not null`) frente a `GeneradorRazor.cs:76-80` (`b.AltoMm`, `b.Elementos.Count` sin comprobación) y `ImpresionEndpoints.cs:94-95` (llama a `Generar` antes de guardar).
- **Detalle:** un JSON con `"Encabezado": null` o un elemento `null` en la lista provoca una `NullReferenceException` en `Generar` (500) antes de llegar a `ValidarDiseno`, así que la tolerancia nueva es código muerto. No lo introduce el PR, pero el PR escribe esa tolerancia sin ejercitarla.
- **Prueba propuesta:** `GeneradorRazorSeguroTests.Un_diseno_con_banda_o_elemento_nulo_se_rechaza_con_400_y_no_con_500` (o, si B prefiere mantener la tolerancia, que `Generar` también la tenga y la prueba afirme que se imprime sin la banda).

### P119-11 · Baja · Casos de `Emitible` sin prueba
- **Evidencia:** `ImagenDiseno.cs:46-47`.
- **Propuesta:** `GeneradorRazorSeguroTests.ValidarDiseno_ignora_la_imagen_de_un_elemento_que_no_se_emite`: (a) elemento `Tipo = Texto` con `Imagen` SVG; (b) elemento de imagen con `Campo = "Empresa.Logo"` y `Imagen` SVG; (c) `Imagen = "   "`. Afirma que no lanza y que `Generar` no agrega a `omitidas`. Fija lo que el PR declara («solo las que el generador emitiría»).

### P119-12 · Baja · Mensaje del 400 con cultura actual y sin identificar el elemento
- **Evidencia:** `ImagenDiseno.cs:75` (`{tope/1024m:0.##}` usa la cultura del hilo; `390,63 KB` con coma en una cultura `es-ES`), `:68-76` (el mensaje no dice qué banda o elemento).
- **Propuesta:** `GeneradorRazorSeguroTests.El_mensaje_del_tope_usa_cultura_invariante` (con `CultureInfo.CurrentCulture = es-ES`, tope 400 000 → «390.63 KB»); y, si B acepta mejorar el mensaje, `…El_mensaje_nombra_la_banda_y_el_elemento`.

## Lo que no encontré (para tranquilidad de B)

- Ningún `Assert` trivial que apruebe por construcción en los cinco tests del plan; el único dato que hace trivial un caso es el de P119-01 (longitud) y el `Imagen` del reflejo de `Ninguna_propiedad…`: sus dos valores de imagen (`GeneradorRazorSeguroTests.cs:61`) son inválidos (el segundo tiene 16 caracteres con símbolos), así que la propiedad `Imagen` se omite antes de llegar a `Texto()`. Es inevitable (una imagen válida no lleva arroba), pero el comentario de `:60` («es el que dejaba pasar R-12») ya no describe lo que la prueba comprueba: hoy el control es `Evaluar`, y el `Texto()` de `GeneradorRazor.cs:108` queda como defensa en profundidad sin prueba posible. Se sugiere ajustar el comentario.
- No vi prueba que dependa del orden de ejecución, salvo el estado estático de P119-06.
- Los datos de `Una_imagen_png_valida_se_imprime_igual_que_antes` reutilizan los bytes PNG bajo las cuatro etiquetas MIME: sirve para el contrato de texto, no para decodificación; la decodificación real de WEBP la cubre `ImagenWebpRenderTests`.
- `ImagenWebpRenderTests` necesita Chrome o Edge y falla (no se omite) si no están: es el patrón de las demás pruebas de impresión, pero conviene recordarlo en la lista de pruebas que no corren en equipos sin navegador.

## Riesgos que las pruebas no cubren
- Chromium del servidor del cliente (la versión del equipo de B no es la del cliente); WEBP animado o grande; el logo en WEBP dentro del PDF (lo declara el PR).
- Compilación de MAUI (NU1301): mitigada por `ComponentesCompartidosTests`, ver arriba.

---

## Texto de comentario para el PR #119

```
Revisión de pruebas (QA del equipo C, solo lectura; no se compiló ni se corrió nada). Dictamen: Suficiente con observaciones. Informe completo: traspasos/C/2026-10-20-revision-pruebas-pr119.md.

Lo bueno: las cinco pruebas del plan existen, el borde 307 200 / 307 201 está probado también al guardar, el PDF de WEBP lleva control positivo (PNG) y negativo (SVG), y 4790 queda cubierto contra duplicados por EventIdUnicosTests. Sobre NU1301: ComponentesCompartidosTests.cs:19 ya compara DisenadorVisual.razor de Web y MAUI; basta correrlo.

Observaciones (ningún Alto):
- P119-01 (Media): de los 8 casos de «no base64», solo uno llega al bucle del alfabeto; el resto cae por la longitud. Propuesta: Evaluar_clasifica_cada_caracter_fuera_del_alfabeto_como_NoBase64, con largo múltiplo de 4 y afirmando NoBase64.
- P119-02 (Media): nada pasa el payload por MotorRazor; la prueba de reflexión mide la cadena. Propuesta: Un_texto_del_diseno_con_codigo_Razor_se_imprime_literal_y_no_se_evalua (@(7*7) no debe dar 49).
- P119-03 (Media): el evento 4790 y su LogWarning no tienen prueba (ni el recorte del id a 32 caracteres).
- P119-04 (Media): dos imágenes válidas de 200 KB superan los 500 000 caracteres de ValidarPlantilla y dan «plantilla demasiado grande»; el comentario de TopeMaximo promete que caben.
- P119-05 (Media): no hay prueba por HTTP del 400 al guardar ni de imprimir un formato ya guardado con SVG.
- P119-06 (Media): el recorte a 360 KB y el valor menor que 1 no se prueban; TopeBytes es estático (riesgo de contaminar otras clases); 307 200 es múltiplo de 3, por lo que el relleno no se distingue en el borde.
- P119-07 (Media): el diseñador no valida ContentType (sí lo hace Parametros.razor:166) y no tiene prueba bUnit; con «Todos los archivos» entra un SVG hasta el 400.
- Bajas: MIME contra firma real no se verifica (P119-08); nombre «de_mas_de_2_MB» desfasado (P119-09); ValidarDiseno tolera nulos que Generar no (P119-10); casos de Emitible (P119-11); mensaje del tope con cultura actual (P119-12).

No encontré Asserts que pasen por razón equivocada en las cinco pruebas del plan; la propiedad Imagen del recorrido por reflexión se omite antes de Texto() (inevitable), conviene ajustar el comentario de la línea 60.
```

### Cierre
- Estado: Aprobado con observaciones (para las pruebas del PR #119; recomendación técnica, no decisión)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-20-revision-pruebas-pr119.md`
- Supuestos: números de línea tomados de `origin/b/t1-7-rq-r12` (fetch del 2026-10-20); nada compilado ni ejecutado; los puntos marcados *inferido* no se verificaron.
- Decisiones candidatas a ADR: Ninguna (P119-04 y P119-08 piden una decisión de B sobre el comportamiento, sin alcance de ADR).
- Entregas a otros agentes: desarrollador (B) → P119-01 a P119-07 (pruebas); disenador-ux-ui → mensaje del 400 que nombre el elemento y aviso en el lienzo (P119-07, P119-12).
- Próximo paso recomendado: publicar el texto del comentario en el PR #119 y decidir P119-04 (mensaje o suma de imágenes) antes de unir.
