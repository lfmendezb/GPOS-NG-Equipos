```
Para: B        De: C        Fecha: 2026-10-22
Tipo: Entrega (código de captura de los dorados de T4-01, grupos 1 a 6), respuesta a `B-a-C/2026-10-22-respuesta-veredicto-deuda-y-guarda-dorados.md`
Prioridad: Media
Repositorio y rama: GPOS-NG `c/dorados-guarda-t4-01` @ ae1b2203 (PR #156, borrador, sobre `b/ola5-t4-01-render` = #152). Empujada.
Estado: Completado (código); la captura la corre B en LFMB
```

# Código de captura de los dorados de T4-01, grupos 1 a 6

Fuentes: plan `traspasos/C/2026-10-22-plan-tanda-dorados-t4-01.md` §3 y la lista D-01..D-26 de `2026-10-22-revision-pruebas-pr152-t4-01-y-dorados.md` (P152-17).
No hice D-07, D-25 ni D-26 (esperan a A). **No capturé nada:** ningún dorado nuevo, ni `manifiesto.json`, ni `CAMBIOS.md`, ni los 78 existentes cambiaron (`git status` limpio tras cada corrida).

## Qué hay en la rama (7 commits sobre 847527ae)

| Commit | Contenido |
|---|---|
| ac1d0cfc | Guarda: `Un_dorado_ausente_falla_con_el_aviso_de_recaptura_y_no_se_crea` (HTML y PDF; mensaje con la variable y el motivo; la carpeta no cambia). **Verifiqué que la guarda ya fallaba con el dorado ausente** (`GuardaDorados.CompararHtml/CompararPdf`: `Assert.True(File.Exists(ruta), Falta(ruta))`); no creaba nada en silencio. La prueba solo lo fija. |
| dba8ac64 | Grupo 1 + `CasosDorados.cs` (ejecuta un caso con modelo propio) + `ServiciosPrincipal`/`ServiciosReportes` de `RenderTrasladoTests` pasan de `private` a `internal` (único cambio en ese archivo) |
| 89b656e8 | Grupo 2 |
| c5b8c99e | Grupo 3 |
| f0ef4eb9 | Grupo 4 |
| f922e09d | Grupo 5 |
| ae1b2203 | Grupo 6 |

Cómo funciona un caso: con la cultura `es-DO` fijada (también en las continuaciones asíncronas), la principal y la API de reportes generan su salida (cada una con su propio modelo); **antes de la guarda** se comprueba que las dos dan lo mismo (`CasosDorados.MismaSalida`) y luego `GuardaDorados.Real.Html/Pdf` compara con el dorado. Por eso, que hoy un caso falle con «Falta el archivo dorado …» **ya prueba que la copia coincide con la principal** en esa variante.

## Corrido (OSHIN-LEGION, rama @ ae1b2203, sin SQL, sin variables de dorados ni de CI)

- `dotnet build tests/GPOS.Tests`: 0 errores; las advertencias son las de antes (29 en compilación completa; ninguna en `tests/GPOS.Tests/Impresion`).
- Por grupo, `dotnet test tests/GPOS.Tests --no-build --filter "FullyQualifiedName~GPOS.Tests.Impresion.<Clase>"`, y al final todo `GPOS.Tests.Impresion.` junto: **250 casos: 95 con error, 153 superados, 2 omitidos (la línea base y la medición), 23 s.** Los 95 errores son exactamente los 95 dorados nuevos, todos con «Falta el archivo dorado …» (95 nombres distintos; ningún otro mensaje). Los 106 de `RenderTrasladoTests` + `GuardaDoradosTests` siguen en verde.
- Ninguna prueba necesitó SQL (`GPOST_TEST_SERVER` sin definir).

## Por grupo

### Grupo 1 · Fiscales — `DoradosFiscalesTests` (41 dorados)
| Caso (Theory) | Dorados |
|---|---|
| `D01_Html_factura_anulada` ×3 | `html/FacturaCxc.{Carta,Ticket80,Ticket58}.Anulada.html` |
| `D01_Pdf_factura_anulada` ×3 | `pdf/Documento.FacturaCxc.{3}.Anulada.pdf` |
| `D02_Html_factura_de_consumo_B02` ×3 | `html/FacturaCxc.{3}.B02.html` |
| `D03_Html_regimen_especial_B14` ×3 | `html/FacturaCxc.{3}.B14.html` |
| `D04_Html_gubernamental_B15` ×3 | `html/FacturaCxc.{3}.B15.html` |
| `D05_Html_exportacion_en_dolares_B16` ×3 / `D05_Pdf_…` ×3 | `html/FacturaCxc.{3}.B16_USD.html`, `pdf/Documento.FacturaCxc.{3}.B16_USD.pdf` |
| `D06_Html_nota_con_NCF_modificado` ×9 | `html/NotaCxc.{3}.B04.html`, `html/DevolucionCxc.{3}.B04.html`, `html/NotaCxc.{3}.B03.html` |
| `D08_Html_compra_con_retenciones` ×3 | `html/FacturaCxp.{3}.Retenciones.html` |
| `D08_Pdf_constancia_con_retenciones` ×3 | `pdf/Documento.ConstanciaRetencion.{3}.Retenciones.pdf` |
| `D09_Html_constancia_con_datos_reales` ×3 | `html/ConstanciaRetencion.{3}.DatosReales.html` |
| `D10_Html_original_sin_marca_de_copia` ×2 | `html/TicketPos.Ticket80.Original.html`, `html/FacturaCxc.Carta.Original.html` |

En verde sin dorado: `D04_El_nombre_largo_tiene_80_caracteres`, `D03_D05_Los_totales_sin_ITBIS_cuadran`, `D09_La_constancia_cuadra`.
Títulos: los `TituloImpresion` del maestro `fiscal.TipoComprobante` (`SqlMigracionesCfg.cs`), como los pone `FabricaModelo` con `TituloNcfAsync`: B02 «FACTURA DE CONSUMO», B14 «FACTURA PARA REGÍMENES ESPECIALES», **B15 «FACTURA GUBERNAMENTAL»** (el plan decía «COMPROBANTE GUBERNAMENTAL»; manda el maestro), **B16 «FACTURA DE EXPORTACIÓN»**, B04 «NOTA DE CRÉDITO», B03 «NOTA DE DÉBITO», B11 «COMPROBANTE DE COMPRAS».

### Grupo 2 · Marcas — `DoradosMarcasTests` (3 dorados) y `MarcarCopiaTests` (sin dorado)
- `D11_Html_vista_previa_sin_valor_fiscal` ×3 → `html/TicketPos.{3}.VistaPrevia.html`.
- `MarcarCopiaTests` (D-12): **24 casos, en verde ya**, principal y API de reportes, con cadenas esperadas escritas a mano: sin marca (devuelve la misma cadena), rollo «COPIA 2», hoja «COPIA 12», vista previa sin pie (rollo y hoja), sin `<body>`, `<BODY class>` en mayúsculas, sin `</body>`, dos cierres (el pie va antes del último) y `>` dentro de un atributo del body (**fija el corte actual**: la banda queda dentro del valor del atributo). Cultura: `es-DO` y `en-US` → `22/10/2026 10:30`; **`de-DE` → `22.10.2026 10:30`**.

### Grupo 3 · Contenido — `DoradosContenidoTests` (21 dorados)
| Caso | Dorados |
|---|---|
| `D13_Html_factura_con_logo` ×4 | `html/FacturaCxc.{Carta,Ticket80}.{LogoPng,LogoWebp}.html` |
| `D16_Html_caracteres_especiales` ×2 | `html/FacturaCxc.{Carta,Ticket80}.Caracteres.html` |
| `D17_Html_150_lineas` ×2 | `html/FacturaCxc.{Carta,Ticket80}.Lineas150.html` |
| `D19_Html_documento_minimo` ×6 | `html/Cotizacion.{3}.Minima.html`, `html/Pago.{3}.Minimo.html` |
| `D23_Pdf_numero_largo_en_58_mm` | `pdf/Documento.FacturaCxc.Ticket58.NumeroLargo.pdf` |
| `D24_Html_pago_mixto` ×6 | `html/TicketPos.{3}.PagoMixto.html`, `html/Recibo.{3}.VariasFormas.html` |

En verde sin dorado (15): `D13_D14_Las_imagenes_de_prueba_son_validas_para_el_disenador`; `D13_Pdf_el_estandar_con_logo_es_igual_al_dorado_sin_logo` ×3 (compara con `pdf/Documento.FacturaCxc.{3}.pdf` existente, **nunca lo reescribe, ni en modo regenerar**); `D16_Razor_no_evalua_los_datos_como_codigo`; `D16_Pdf_caracteres_especiales_estructural` ×3; `D16_Pdf_con_emoji_o_hebreo_hoy_falla` ×3; `D17_Pdf_carta_de_150_lineas_pagina`; `D17_Pdf_rollo_de_150_lineas_crece_en_una_hoja`; `D23_El_numero_tiene_20_caracteres_y_el_eNCF_13`; `D24_Los_pagos_suman_el_total_sin_cambio`.
- Imágenes 1×1 en el código (`ModelosDorados.Png1x1/Webp1x1/Gif1x1/Jpeg1x1`): las cuatro **decodifican como 1×1 con WIC** (PowerShell, `BitmapDecoder`); el JPEG lo generó GDI+.
- PDF estructural sin librería (la de PdfPig es decisión de D-26): `/Type /Page`, `/Count` y `/MediaBox` en el PDF de Skia, que no comprime los diccionarios de página (verificado en los dorados existentes).

### Grupo 4 · Inventario — `DoradosInventarioTests` (24 dorados)
| Caso | Dorados |
|---|---|
| `D18_Html_sin_ver_costos` ×12 | `html/{Entrada,Ajuste,Conduce,ConteoFisico}.{3}.SinVerCostos.html` |
| `D18_Pdf_entrada_sin_ver_costos` ×3 | `pdf/Documento.Entrada.{3}.SinVerCostos.pdf` |
| `D20_Pdf_informe_X` ×3 | `pdf/Cierre.X.{3}.pdf` |
| `D20_Pdf_cierre_Z_sin_conteo` | `pdf/Cierre.Z.Ticket80.SinConteo.pdf` |
| `D20_Pdf_cierre_Z_anulado` | `pdf/Cierre.Z.Carta.Anulado.pdf` |
| `D21_Pdf_conduce_de_transferencia` ×4 | `pdf/Conduce.Transferencia.Carta.{Impresion1,ConLotesYSeries,Anulada,TrasladoInterno}.pdf` |

En verde sin dorado: `D21_Pdf_en_transito_es_igual_al_conduce_existente`. Estados reales leídos en `CodigosTransferencia.Estados` (`DESPACHADO`, `EN_TRANSITO`, `RECONCILIADO`, `ANULADO`…): **`FormatoConduceTransferencia` no imprime el estado**, así que «En tránsito» no tiene dorado propio (sería idéntico al existente); lo que el conduce sí ramifica es la impresión (>1 → «REIMPRESIÓN n»), la anulación («ANULADA»), el traslado interno (título), transportista/vehículo/notas nulos, lote, vencimiento y series. Por eso agregué Anulada y TrasladoInterno (no estaban en la lista).

### Grupo 5 · Diseñador — `DoradosDisenadorTests` (3 dorados)
- `D14_Html_diseno_con_imagenes_y_evento_4790` (`Trait("Transicion","v2")`) → `html/DisenoGrafico.Carta.Imagenes.html`. Antes de la guarda (pasó hoy): la principal entrega a quien imprime las 4 omitidas con su motivo (SVG y `data:` sin `;base64` → `TipoNoPermitido`, base64 inválido → `NoBase64`, imagen de 337 503 bytes → `ExcedeTope`); la API de reportes escribe 4 eventos 4790 `FormatoImagenOmitida` (Warning) con el texto exacto y sin `data:` ni el contenido; las 4 válidas salen en ambos HTML.
- `D15_Html_diseno_de_ticket_en_58_mm` → `html/DisenoGrafico.Ticket58.html`; `D15_Html_diseno_de_carta_horizontal` → `html/DisenoGrafico.Carta.H.html`. En verde: `D15_La_carta_horizontal_intercambia_ancho_y_alto`.

### Grupo 6 · Reportes — `DoradosReportesTests` (3 dorados)
- `D22_Pdf_resultado_de_reporte` ×3 → `pdf/Reporte.Resultado.Carta.pdf`, `….Carta.Vacio.pdf`, `….Carta.Multipagina.pdf` (25, 0 y 120 filas). En verde: `D22_Pdf_resultado_de_reporte_estructural` ×3 (0 y 25 filas, 1 hoja; 120, ≥ 2).
- **Oráculo en dos pasos** (ver decisiones): la principal no acepta la hora «Impreso» (lee `HoraEmpresa.Ahora`, estático del proceso). Cada caso comprueba primero principal = copia con la misma hora (como la prueba existente) y después compara con el dorado la **copia** con la hora fija 22/10/2026 11:30, generada dos veces.

## Hallazgos y decisiones pendientes (no tomadas por C)

1. **Hallazgo (Media, inferido para producción):** el PDF estándar (QuestPDF) **lanza `DocumentDrawingException`** si el documento lleva emoji o hebreo (notas, nombre del cliente, descripción): «contains 9 glyph(s) that are not available… Registered fonts: 'Cascadia Mono', 'Lato'… System fonts (Settings.UseSystemFonts): disabled», en la principal y en la API de reportes (corrido). GPOS solo fija la licencia de QuestPDF (`src/GPOS.Api/Program.cs:25`, `src/GPOS.Reportes.Api/Program.cs:20`), así que **infiero** que en producción pasa igual: un cliente con un emoji en el nombre no puede imprimir con el formato estándar. Lo fijé en `D16_Pdf_con_emoji_o_hebreo_hoy_falla` (cambia a propósito al corregir). Decide A/B: fuentes del sistema o de respaldo, sustituir el glifo o validar al guardar. El HTML (Razor) sí lo maneja y su dorado lleva emoji.
2. **Cultura (D-12, decisión chica de B/A):** `MarcarCopia` («Reimpreso el») y los pies de QuestPDF (`FechaImpresion:dd/MM/yyyy HH:mm`, «Impreso:» del reporte) usan la cultura del hilo. Los dorados nuevos la fijan en `es-DO`; **los 78 existentes no** (`RenderTrasladoTests` no la fija): en una máquina `de-DE` fallarían. Recomiendo fijar `es-DO` en los formatos (src) o, como mínimo, en `RenderTrasladoTests`.
3. **D-22, oráculo:** en el modo regenerar el dorado se escribe con la salida de la copia (verificada contra la principal en el mismo caso). La alternativa (fijar `HoraEmpresa.Usar` con un reloj fijo) cambia un estático de todo el proceso y afectaría a otras pruebas en paralelo; la descarté. B decide si basta.
4. **D-08 PDF:** el plan pedía `pdf/Documento.Pago.{3}.Retenciones`, pero `FabricaModelo.DePagoAsync` nunca pone retenciones en el pago; el documento estándar real con retenciones es la constancia: hice `pdf/Documento.ConstanciaRetencion.{3}.Retenciones`.
5. **D-18:** se fija lo de hoy (las plantillas Razor no consultan `MostrarMontos` e imprimen ceros; el PDF estándar sí oculta). La decisión de ocultar columnas sigue abierta.
6. **Desvíos menores:** D-23 usa `FPABCD00000000000001` (20 caracteres; el ejemplo del plan tenía 19). D-06 agrega la nota de débito B03. D-13 PDF compara los tres papeles (el plan, solo carta). El modelo base de `Transferencia()` usa `Estado = "Despachada"` y `Modo = "Directa"`, que no son los códigos reales (`DESPACHADO`, `E`); no se imprimen, no lo cambié.
7. **D-14:** el tope global `ImagenDiseno.TopeBytes` es estático; la imagen «sobre el tope» supera `TopeMaximo` y se omite con cualquier configuración; las válidas (42 a ~630 bytes) solo fallarían si alguien fijara un tope menor de 1 KB en el mismo proceso (ninguna prueba ni `appsettings` lo hace hoy; verificado por búsqueda).
8. `ModeloImpresion` permitió expresar todo lo de los grupos 1 a 6; no hubo dato imposible.

## Lo que NO hice / no verifiqué
- No corrí el modo `regenerar` ni `linea-base`; no comprobé la doble captura (determinismo) ni la mutación de aceptación del protocolo §2: son de la captura en LFMB.
- No corrí la suite completa ni nada con SQL; no toqué Chromium (D-26).
- No ejecuté el filtro oficial (`Transicion!=Ola5&Transicion!=Defecto`); D-14 lleva `Transicion=v2`, que ese filtro no excluye (inferido por el texto del filtro).

## Comandos para B (LFMB, PowerShell, desde la raíz del worktree de la rama, una clase por corrida)

Esperado en la corrida con `regenerar`: **fallan todos los casos de dorado** (G-1) y los demás pasan; recapturados por clase: Fiscales 41, Marcas 3, Contenido 21, Inventario 24, Diseñador 3, Reportes 3 (total 95; el manifiesto pasa de 78 a 173). `MarcarCopiaTests` no hace falta.

```powershell
dotnet build tests/GPOS.Tests
$clases = @(
  @{ C = "DoradosFiscalesTests";   M = "P152-17 grupo 1: dorados fiscales D-01..D-06 y D-08..D-10 (C, ae1b2203)" },
  @{ C = "DoradosMarcasTests";     M = "P152-17 grupo 2: vista previa D-11 (C, ae1b2203)" },
  @{ C = "DoradosContenidoTests";  M = "P152-17 grupo 3: contenido D-13, D-16, D-17, D-19, D-23, D-24 (C, ae1b2203)" },
  @{ C = "DoradosInventarioTests"; M = "P152-17 grupo 4: inventario D-18, D-20, D-21 (C, ae1b2203)" },
  @{ C = "DoradosDisenadorTests";  M = "P152-17 grupo 5: diseñador D-14 y D-15 (C, ae1b2203)" },
  @{ C = "DoradosReportesTests";   M = "P152-17 grupo 6: FormatoReporte D-22 (C, ae1b2203)" }
)
# Un grupo por vez (una entrada de CAMBIOS.md por proceso); ejemplo con el grupo 1:
$g = $clases[0]
$env:GPOS_TEST_DORADOS = "regenerar"; $env:GPOS_TEST_DORADOS_MOTIVO = $g.M
dotnet test tests/GPOS.Tests --no-build --filter "FullyQualifiedName~GPOS.Tests.Impresion.$($g.C)"
# Segunda corrida igual (determinismo): debe decir «Dorados recapturados en esta corrida (0)» en cada caso y no agregar entrada
dotnet test tests/GPOS.Tests --no-build --filter "FullyQualifiedName~GPOS.Tests.Impresion.$($g.C)"
Remove-Item Env:GPOS_TEST_DORADOS, Env:GPOS_TEST_DORADOS_MOTIVO
# Pasada limpia (la que vale): todo en verde, incluida la guarda (manifiesto y CAMBIOS.md)
dotnet test tests/GPOS.Tests --no-build --filter "FullyQualifiedName~GPOS.Tests.Impresion.$($g.C)|FullyQualifiedName~GPOS.Tests.Impresion.GuardaDoradosTests|FullyQualifiedName~GPOS.Tests.Impresion.RenderTrasladoTests"
git diff --stat -- tests/GPOS.Tests/Impresion/Dorados
```

Revisar a ojo los archivos nuevos, sobre todo: `*.Anulada.*` (marca roja/agua), `*.B16_USD.*` («tasa 58.75»), `*.Caracteres.html` (entidades y emoji como `&#x1F600;`), `DisenoGrafico.Carta.Imagenes.html` (4 `<img>`), `Cierre.Z.Carta.Anulado.pdf` y `Conduce.*.Anulada.pdf`.

### Cierre
- Estado: Completado
- Artefactos: rama `c/dorados-guarda-t4-01` @ ae1b2203 (`tests/GPOS.Tests/Impresion/`: `CasosDorados.cs`, `DoradosFiscalesTests.cs`, `DoradosMarcasTests.cs`, `DoradosContenidoTests.cs`, `DoradosInventarioTests.cs`, `DoradosDisenadorTests.cs`, `DoradosReportesTests.cs`; modificados `ModelosDorados.cs`, `GuardaDoradosTests.cs`, `RenderTrasladoTests.cs`); este informe
- Supuestos: cultura `es-DO` para los dorados nuevos; títulos del maestro fiscal; D-22 capturado desde la copia tras comprobarla contra la principal
- Decisiones candidatas a ADR: Ninguna (las de arriba son de A/B, no de arquitectura)
- Entregas a otros agentes: B → correr la captura de los 95 dorados en LFMB y devolverlos; A/B → decidir el PDF estándar con emoji/hebreo (hallazgo 1) y la cultura (hallazgo 2)
- Próximo paso recomendado: B captura el grupo 1 con el bloque de arriba y confirma la doble corrida antes de seguir con los demás
