# Guía de revisión humana (G-5) de los 95 dorados nuevos del PR #156

- Fecha: 2026-10-23 · Equipo C · Material de apoyo, **no es una aprobación**. La revisión G-5 la hace el propietario o A.
- PR: #156 «T4-01 (P152-16): guarda de los dorados G-1 a G-6 y línea base (apilado sobre #152)». Rama `origin/c/dorados-guarda-t4-01`, punta `03c0afd0`, base `feature/modelo-ng` (ancestro común `b9efa9fb`).
- Alcance: los 95 archivos nuevos de `html/` (70) y `pdf/` (25) bajo `tests/GPOS.Tests/Impresion/Dorados/`, que corresponden a las entradas P152-17 grupos 1 a 6 de `CAMBIOS.md` (41 + 3 + 21 + 24 + 3 + 3 = 95). Los otros 78 de la carpeta ya estaban en la línea base (`f8897418`, manifiesto inicial) y quedan fuera de esta guía, salvo como término de comparación.
- Marcas: [V] verificado por mí sobre los archivos; [I] inferido o no verificable con mis herramientas.
- No modifiqué ningún archivo del repositorio. Mis scripts y volcados de texto están en el directorio temporal de la sesión.

## 0. Resumen para quien tiene poco tiempo

1. Mecánicamente los 95 dorados están limpios: sin rutas absolutas, nombres de máquina, URL externas, secretos ni datos personales reales; fechas fijas; HTML con etiquetas balanceadas; los 95 hashes del manifiesto se recalculan igual y cada uno tiene exactamente una entrada en `CAMBIOS.md` cuyo hash final coincide con el manifiesto [V].
2. Hay **15 puntos (A-01 a A-15) que conviene que un humano decida** (sección 4; ninguno es Crítico ni Alto en mi escala). Los más importantes: los «sin ver costos» en HTML muestran `0.00` (el PDF correcto oculta las columnas); el «Ticket58» del diseñador gráfico es byte a byte el de 80 mm y sus elementos miden 74 mm; el Cierre X/Z en Carta deja una página 2 con solo la firma; los datos del Cierre no cuadran entre sí; el e-NCF (E31) se imprime sin QR; varios formatos Carta no fiscales llevan el rótulo «Comprobante fiscal».
3. Casi todos los puntos son **comportamiento ya existente de los formatos** que el dorado captura (la guarda congela lo que hay), no defectos introducidos por el PR. Aun así, un dorado captura «lo que sale hoy» como verdad: por eso G-5 existe.

## 1. Inventario de los 95 dorados nuevos

Cómo leer: la celda es el **SHA-256 normalizado del manifiesto, primeros 10 caracteres** (HTML con LF; PDF sin `/CreationDate` ni `/ModDate`). Para los PDF se añade el número de páginas y el tamaño de página que leí en `/MediaBox`. «-» significa que ese papel no tiene dorado en esa variante. La ruta de cada archivo es `tests/GPOS.Tests/Impresion/Dorados/html/<Documento>.<Papel>[.<Variante>].html` o `.../pdf/<Documento>.<Papel>[.<Variante>].pdf`; el listado completo con el SHA-256 de 64 caracteres está en el Apéndice A.

Agrupación por familia (tipo de documento) y por entrada de `CAMBIOS.md`:

| Familia | Grupo P152-17 | HTML | PDF |
|---|---|---|---|
| Fiscales, notas, compras y retenciones (FacturaCxc B02/B14/B15/B16/Anulada/Original, NotaCxc B03/B04, DevolucionCxc B04, FacturaCxp y ConstanciaRetencion con retenciones, TicketPos Original) | 1 | 32 | 9 |
| Vista previa «SIN VALOR FISCAL» (TicketPos) | 2 | 3 | 0 |
| Contenido (Pago/Cotización mínimos, Recibo varias formas, TicketPos pago mixto, logos, caracteres, 150 líneas, número largo) | 3 | 20 | 1 |
| Inventario (Ajuste, Conduce, ConteoFisico, Entrada «sin ver costos»; Cierre X/Z; Conduce de transferencia) | 4 | 12 | 12 |
| Diseñador gráfico | 5 | 3 | 0 |
| Reporte estándar (FormatoReporte) | 6 | 0 | 3 |

(Los totales por grupo son los de `CAMBIOS.md`; el reparto por columnas es mi conteo de las rutas.)

#### Dorados html (70 nuevos)

| Documento | Variante | Carta | Ticket 58 | Ticket 80 |
|---|---|---|---|---|
| Ajuste | SinVerCostos | 31f5b3e8d2 | 6f1d8685f8 | 75ef97cf24 |
| Conduce | SinVerCostos | fba28d3935 | ae59a705d3 | ab9bd4db21 |
| ConstanciaRetencion | DatosReales | 710f39c05b | 075ba3fec5 | e5040c599d |
| ConteoFisico | SinVerCostos | de0b5d70b7 | b3fda0f05e | b0ce9d7e21 |
| Cotizacion | Minima | cd10a946b4 | 5229fe702e | a748422872 |
| DevolucionCxc | B04 | 9b8c1d326c | 720ac1bce0 | e7c89ef117 |
| DisenoGrafico | (base) | - | d2936986b5 | - |
| DisenoGrafico | H | 995dc4479b | - | - |
| DisenoGrafico | Imagenes | b8a5708444 | - | - |
| Entrada | SinVerCostos | 975e6adfc2 | 3dc73fa0d4 | 4715ae0641 |
| FacturaCxc | Anulada | e08b613818 | 8ef6de22c7 | 4e21eb4dec |
| FacturaCxc | B02 | a657a78b86 | 540613bae1 | 124de27dd6 |
| FacturaCxc | B14 | 1072afec5e | 3f1a06235b | 5e06926c98 |
| FacturaCxc | B15 | 0a122d5072 | 3933827219 | da6ba671a3 |
| FacturaCxc | B16_USD | 4c1427f29f | 8221f23f62 | fdf7086de8 |
| FacturaCxc | Caracteres | 9b32e7c8a2 | - | a7006e6f09 |
| FacturaCxc | Lineas150 | 7d3443950f | - | 3395b329a3 |
| FacturaCxc | LogoPng | f837ccb566 | - | 791fa84f18 |
| FacturaCxc | LogoWebp | 47aca5cb16 | - | ae29432c5f |
| FacturaCxc | Original | 50193a6633 | - | - |
| FacturaCxp | Retenciones | 4bda707259 | 479a010c5d | 24e4defe6f |
| NotaCxc | B03 | 5b3137df3e | 34ff61a417 | ba44eb94bd |
| NotaCxc | B04 | 9b8c1d326c | 720ac1bce0 | e7c89ef117 |
| Pago | Minimo | 331eec7927 | 26ae8e967c | e348225daf |
| Recibo | VariasFormas | 0e32c7112e | 1a1256240a | 7c954d818e |
| TicketPos | Original | - | - | 8238ff2976 |
| TicketPos | PagoMixto | 2f69b37731 | eb63e08b64 | 270f33446a |
| TicketPos | VistaPrevia | 813cc8c9a1 | 1969692e4b | deb3d02929 |

#### Dorados pdf (25 nuevos)

| Documento | Variante | Carta | Ticket 58 | Ticket 80 |
|---|---|---|---|---|
| Cierre.X | (base) | 396e188412 (2p, 215.9 x 279.4 mm) | 5e0e7754f6 (1p, 58.0 x 206.5 mm) | 8b8e642f95 (1p, 80.0 x 224.6 mm) |
| Cierre.Z | Anulado | fa41bd48f0 (2p, 215.9 x 279.4 mm) | - | - |
| Cierre.Z | SinConteo | - | - | dc2b093ca9 (1p, 80.0 x 184.4 mm) |
| Conduce.Transferencia | Anulada | 97c53905a0 (1p, 215.9 x 279.4 mm) | - | - |
| Conduce.Transferencia | ConLotesYSeries | 0ae9a07a0e (1p, 215.9 x 279.4 mm) | - | - |
| Conduce.Transferencia | Impresion1 | 7bc973c65e (1p, 215.9 x 279.4 mm) | - | - |
| Conduce.Transferencia | TrasladoInterno | 981a52c79a (1p, 215.9 x 279.4 mm) | - | - |
| Documento.ConstanciaRetencion | Retenciones | 751488f433 (1p, 215.9 x 279.4 mm) | ae440d5cc3 (1p, 58.0 x 115.4 mm) | 27b9d61349 (1p, 80.0 x 109.0 mm) |
| Documento.Entrada | SinVerCostos | 307acd2cfb (1p, 215.9 x 279.4 mm) | 6b4f37378a (1p, 58.0 x 122.0 mm) | 9f605e9c81 (1p, 80.0 x 112.3 mm) |
| Documento.FacturaCxc | Anulada | afaaf34510 (1p, 215.9 x 279.4 mm) | 9e61e2dec6 (1p, 58.0 x 153.6 mm) | 0efb28ec01 (1p, 80.0 x 140.9 mm) |
| Documento.FacturaCxc | B16_USD | 645b98efca (1p, 215.9 x 279.4 mm) | 3e7b18a218 (1p, 58.0 x 156.2 mm) | 044580c442 (1p, 80.0 x 143.4 mm) |
| Documento.FacturaCxc | NumeroLargo | - | 7684c9a201 (1p, 58.0 x 166.6 mm) | - |
| Reporte.Resultado | (base) | 1be44ab0fc (1p, 215.9 x 279.4 mm) | - | - |
| Reporte.Resultado | Multipagina | 6bdb28dd24 (3p, 215.9 x 279.4 mm) | - | - |
| Reporte.Resultado | Vacio | 25cd210d90 (1p, 215.9 x 279.4 mm) | - | - |



## 2. Qué debe mirar quien revisa, por familia

### 2.0 Reglas de referencia (de `CLAUDE.md` y los ADR, leídas en `origin/master`)

- **Identidad de BP2 (ADR-52):** números visibles, vocabulario de pantallas y formatos se conservan. El revisor compara el vocabulario de las leyendas («Comprobante fiscal», «Firma del Cliente», «Reimpreso el…») con lo que el usuario de BP2 conoce.
- **NCF:** con tipo de comprobante elegido el documento solo se guarda si toma un NCF válido; ningún mensaje o ayuda sugiere «No generar comprobante». [V] La cadena «generar comprobante» no aparece en ninguno de los 95 dorados (HTML ni texto de PDF).
- **e-NCF:** un documento con e-NCF no se anula (regla del propietario del 2026-10-08, ADR-108). [V] Los tres dorados «Anulada» de FacturaCxc usan NCF `B0200000123` (papel), no e-NCF; es coherente. El único dorado con e-NCF es `Documento.FacturaCxc.Ticket58.NumeroLargo.pdf` (`E310000000001`, modificado `E310000000002`) y no es anulado.
- **Marca de copia (RO-54 y decisión P170-07):** toda reimpresión dice «COPIA n» y lleva «Reimpreso el …»; la primera impresión no lleva marca. En HTML la banda `gpos-marca` se inserta tras el `<body>`; en QuestPDF la dibuja el propio formato.
- **Vista previa del diseñador con comprobante real (H-2):** «VISTA PREVIA – SIN VALOR FISCAL». La leyenda «sin valor fiscal» solo está exigida en ese caso (y en empresas de Demostración, Q-06/P-L6, y en el vale no fiscal de catering, todavía sin dorado). **No hay regla firmada que exija «SIN VALOR FISCAL» en cotizaciones, pedidos, conduces ni documentos de inventario**; si el revisor considera que debe haberla, es una decisión nueva (propuesta con ADR), no un defecto del dorado.
- **Ver costos:** el privilegio «Ver costos» (grupo «Especiales») gobierna lo que muestran los dorados «SinVerCostos».
- **Papeles:** Carta 215,9 x 279,4 mm (612 x 792 pt); ticket 58 mm = 164,5 pt; ticket 80 mm = 226,75 pt [V en `/MediaBox`]. En HTML el ancho del ticket **no** está en el HTML (solo `@page { margin: 3mm }`); lo fija el convertidor a PDF [V en `FacturaCxc.Ticket58.B02.html` frente a `Ticket80.B02.html`: solo difieren tamaños de letra y de logo].

Lista de verificación común a todo documento (marcar en cada familia):
1. Encabezado: razón social, RNC del emisor, dirección, teléfono.
2. Título del documento correcto para el tipo (por ejemplo B15 = «FACTURA GUBERNAMENTAL», B16 = «FACTURA DE EXPORTACIÓN», B14 = «FACTURA PARA REGÍMENES ESPECIALES»).
3. Número del documento, NCF (y NCF modificado en notas), fecha y vencimiento.
4. Cliente/proveedor con RNC/cédula.
5. Líneas: cantidades, precios, descuento, ITBIS por línea, marca «(E)» en exentos.
6. Totales: subtotal, descuento (con signo), impuesto, total, monto en letras y moneda (RD$/US$ con tasa).
7. Marca de copia/anulado/vista previa según el caso; pie («Reimpreso el…», «Gracias por su compra», firmas).
8. Aritmética: [V] en los casos fiscales de venta el cuadro es `3.586,50 − 80,00 + 579,60 = 4.086,10` (ITBIS 18 % de 2.500 = 450 y de 720 = 129,60); en B14 y B16 el ITBIS es 0 y el total es `3.506,50`. Revisar que ningún dorado cambie estas cifras sin motivo.

### 2.1 Fiscales de venta con tipo de comprobante (FacturaCxc B02, B14, B15, B16_USD; NotaCxc B03/B04; DevolucionCxc B04; Anulada; Original)

Archivos: `html/FacturaCxc.{Carta,Ticket58,Ticket80}.{B02,B14,B15,B16_USD,Anulada}.html`, `html/FacturaCxc.Carta.Original.html`, `html/NotaCxc.*.{B03,B04}.html`, `html/DevolucionCxc.*.B04.html`, `html/TicketPos.Ticket80.Original.html`, `pdf/Documento.FacturaCxc.*.{Anulada,B16_USD}.pdf`.

Mirar:
- NCF con el prefijo del tipo: B02 `B0200000123`, B03 `B0300000001`, B04 `B0400000001`, B14 `B1400000001`, B15 `B1500000001`, B16 `B1600000001`. Notas con «NCF modificado: B0100000123».
- B15: cliente de nombre largo (se parte en renglones en Carta; en ticket ocupa varias líneas) con RNC.
- B16: «Moneda: US$ (tasa 58.75)», `Total US$`, monto en letras en **dólares** y líneas exentas; ITBIS 0.
- B14/B16: líneas marcadas «(E)» y ITBIS 0,00 en cada línea.
- Anulada: rótulo «ANULADO» (en HTML es la clase `.anulado`; en el PDF de Carta aparece al final del contenido y en ticket como «*** ANULADO ***» tras el título). Debe seguir mostrándose el NCF y no mostrar «COPIA» ni «Reimpreso» (es una primera impresión) [V]. Verificar visualmente que la marca de agua no tape cifras.
- Original (Carta y TicketPos 80): sin «COPIA» ni «Reimpreso» [V]; es el contraste de la familia con marca de copia.
- La marca de copia «COPIA 2» y «Reimpreso el 22/10/2026 10:30» están en los demás [V].
- Ticket y Carta difieren en diseño (el ticket muestra el ITBIS dentro del importe de línea, p. ej. `2 UND x 1.250,00 | 2.950,00`; la Carta muestra el extendido sin ITBIS `2.500,00` y el ITBIS aparte).
- Papel: tickets 58 y 80 solo difieren en tamaños de letra/logo (texto idéntico) [V: 0 líneas de texto distintas en los 40 pares de la carpeta].

### 2.2 Compras y retenciones (FacturaCxp «Comprobante de compras», ConstanciaRetencion)

Archivos: `html/FacturaCxp.*.Retenciones.html`, `html/ConstanciaRetencion.*.DatosReales.html`, `pdf/Documento.ConstanciaRetencion.*.Retenciones.pdf`.

Mirar:
- FacturaCxp: NCF del proveedor `B1100000001` (B11), «Retención ITBIS −108,00», «Retención ISR −100,00», «Neto a pagar 3.878,10» (= 4.086,10 − 208,00 [V]). Firma «del Proveedor» y «Autorizado por».
- Constancia: agente de retención con RNC, retenido con cédula/RNC, una fila por factura con NCF, base, % y monto de ITBIS e ISR, tipo de ISR, totales `ITBIS 1.440,00 + ISR 1.100,00 = 2.540,00` [V; filas: 30 % de 1.800 = 540; 100 % de 900 = 900; 10 % de 10.000 = 1.000; 2 % de 5.000 = 100].
- Ticket: el ticket de la constancia **no desglosa ITBIS/ISR** ni % ni tipo, solo «NCF … 1.540,00» (= 540 + 1.000); revisar si basta para el usuario (ver A-09).
- No hay marca de copia (primera impresión).

### 2.3 Vista previa (TicketPos.*.VistaPrevia)

- Debe llevar «VISTA PREVIA – SIN VALOR FISCAL» arriba [V en los tres papeles: en ticket `*** VISTA PREVIA – SIN VALOR FISCAL ***`; en Carta la leyenda está en el texto, su posición visual no la verifiqué]; no lleva «COPIA» [V].
- Muestra un NCF real de ejemplo (`B0100000123`): es lo esperado en H-2 (la vista previa de un comprobante fiscal real queda en bitácora).

### 2.4 Contenido (Pago/Cotización mínimos, Recibo varias formas, TicketPos pago mixto, logos, caracteres, 150 líneas, número largo)

- `Cotizacion.*.Minima` y `Pago.*.Minimo`: un solo artículo, sin vendedor, vencimiento ni notas. Verificar que no queden etiquetas huérfanas («Condiciones», «Términos», «Observaciones» salen vacías en Carta [V]).
- `Recibo.*.VariasFormas`: `2.000,00 + 1.468,75 (25,00 US$ x 58,75) + 617,35 = 4.086,10` [V]. La tarjeta se imprime enmascarada («VISA ****1234», autorización, lote, terminal): comprobar que **nunca** aparezca el número completo [V: no aparece].
- `TicketPos.*.PagoMixto`: igual desglose de pagos. La versión Carta es **byte a byte igual** al `TicketPos.Carta.html` de la línea base (no imprime formas de pago) [V]; ver A-11.
- `FacturaCxc.*.Caracteres`: cliente `O'Brien & Hijos <S.R.L.> "El Rápido"` y notas con comillas tipográficas, emoji, hebreo, tabulación, salto de línea y control bidi U+202E. Comprobar que `<`, `&` y `"` salen **escapados** [V en el HTML: `&lt;`, `&amp;`, `&quot;`] y que `@Model.Total @{ var x=1; }` sale como texto literal y no se evalúa como Razor [V]. Ver A-13.
- `FacturaCxc.*.Lineas150`: 150 líneas (1 de cada 10 con descripción de 120 caracteres). [V] Hay 150 filas en Carta (códigos `A-0001` a `A-0150`); `Subtotal 15.000,00 + ITBIS 2.700,00 = 17.700,00`. Comprobar visualmente en PDF/impresión que el encabezado de la tabla se repite por página y que ninguna fila se parte (CSS `page-break-inside: avoid` presente [V]). No hay archivo dorado PDF de las 150 líneas; el código de captura (`DoradosContenidoTests.cs:124-144`) solo compara entre sí la salida de la principal y la de reportes [V en el código].
- `FacturaCxc.*.LogoPng` y `LogoWebp`: imagen embebida `data:image/png|webp;base64`. Las imágenes son de 1 x 1 píxel (A-12).
- `Documento.FacturaCxc.Ticket58.NumeroLargo.pdf`: número `FPABCD00000000000001` (20 caracteres) y e-NCF `E310000000001`; comprobar que cabe en 58 mm sin cortarse [I: no puedo renderizar; el texto extraído está completo] y A-06.

### 2.5 Inventario (SinVerCostos HTML y PDF; Cierre X/Z; Conduce de transferencia)

- `*.SinVerCostos` (Ajuste, Conduce, ConteoFisico, Entrada): **HTML** muestra `0.00` en precios, ITBIS, extendidos y totales; **PDF** (`Documento.Entrada.*.SinVerCostos.pdf`) quita las columnas de importes. Ver A-01.
- `Cierre.X.*`: «INFORME X No. 1», «Informe parcial · no reinicia la caja», arqueo (cierre ciego) y pie «*** DOCUMENTO NO VÁLIDO COMO CIERRE ***» [V]. `Cierre.Z.*`: «CIERRE Z No. 12», «Cierre definitivo del día» y «*** FIN DEL CIERRE Z ***». Un solo Z por jornada (ADR-17).
- `Cierre.Z.Carta.Anulado`: «*** ANULADO ***» y todas las cifras visibles. `Cierre.Z.Ticket80.SinConteo`: sin bloque de arqueo ni «Efectivo contado» (A-05).
- Cuadre de datos: ver A-04.
- `Conduce.Transferencia.Carta.*`: «CONDUCE DE TRANSFERENCIA» (TR00000007), origen/destino con sucursal y almacén, despachado por, transportista, vehículo, lote con vencimiento y series; `Impresion1` sin marca; `Anulada` con «REIMPRESIÓN 2» y «ANULADA»; `TrasladoInterno` titula «TRASLADO ENTRE ALMACENES» y omite transportista/vehículo pero conserva el recuadro de firma «Transportista» [V]. «Huella ABCDEF0123» es un valor fijo de ejemplo.

### 2.6 Diseñador gráfico (DisenoGrafico.Carta.H, Carta.Imagenes, Ticket58)

- `Carta.H`: misma factura que la base pero con `@page { size: 279.4mm 215.9mm }` (horizontal) [V]. Revisar visualmente que el contenido use el ancho extra.
- `Carta.Imagenes`: cuatro imágenes (PNG, JPEG, GIF, WebP) de 10 x 10 mm en fila, `object-fit: contain`.
- `Ticket58`: ver A-02 (idéntico al de 80 mm) y A-02b (la suma no cuadra).

### 2.7 Reporte estándar (Reporte.Resultado.Carta, .Vacio, .Multipagina)

- «Ventas por artículo», «Desde 01/10/2026 · Hasta 22/10/2026», «Impreso: 22/10/2026 11:30», pie «Página n de m».
- [V] 25 filas: `Total (25 filas) 50,00 / 3.756,25` (25 x 150,25); vacío: «Total (0 filas) 0,00 0,00»; 120 filas en 3 páginas: `240,00 / 18.030,00` (120 x 150,25), con el encabezado de columnas repetido en las 3 páginas y «Página 3 de 3» en la última.
- D-22: el oráculo de estos tres es la propia copia de reportes (LEEME, «Oráculo de los dorados de reportes»); la revisión humana pesa más aquí que en el resto.

## 3. Comprobaciones mecánicas realizadas y su resultado

Herramientas: shell Git Bash, `perl`, `sha256sum`; no había Python, `xmllint`, lector de PDF ni navegador. Para el texto de los PDF escribí un extractor propio (inflar los flujos, aplicar el `ToUnicode` de cada fuente y ordenar por posición); sus resultados son aproximados [I], pero coherentes con el HTML de los mismos casos.

| # | Comprobación | Resultado |
|---|---|---|
| M-1 | Los 95 hashes del manifiesto se recalculan igual (HTML con LF; PDF con `/CreationDate` y `/ModDate` vaciados, misma regla que `GuardaDorados.NormalizarHtml/NormalizarPdf`) | 95 coinciden, 0 difieren [V] |
| M-2 | Cada dorado nuevo tiene exactamente 1 entrada en `CAMBIOS.md` y su hash final coincide con el manifiesto | 95 de 95 [V] |
| M-3 | Manifiesto: 173 entradas = 132 HTML + 41 PDF en disco (umbral 173 del último commit) | Coincide [V] |
| M-4 | Fines de línea en Git | El índice guarda LF; en este Windows el árbol de trabajo trae CRLF por `* text=auto`. Por eso `sha256sum` del archivo en disco **no** coincide con el manifiesto: usar el hash normalizado [V] |
| M-5 | HTML bien formado: pares `div/table/tr/td/th/span/b/h1/p/style/head/body/html` balanceados | 70 de 70 sin desbalance [V]. No es validación HTML completa (no hay validador) [I] |
| M-6 | Rutas absolutas, nombres de máquina o usuario (`C:\`, `/Users/`, `file://`, `localhost`, `DESKTOP-`, `lfmen`) en HTML | 0 [V] |
| M-7 | Rutas o usuario dentro de los 25 PDF (metadatos y flujos) | 0 [V] |
| M-8 | URL externas (`http://`, `https://`), `src`/`href` que no sean `data:` | 0; solo hay 5 HTML con imágenes `data:` (logos y diseñador) [V] |
| M-9 | Secretos (`Server=`, `Password`, `Bearer`, `eyJ…`, `api key`, `secret`), nombres de base (`GPOS_TEST`, `SQLEXPRESS`), referencias a código (`.dll`, `.cs`, `.cshtml`) | 0 [V] |
| M-10 | Correos | 0 reales. Las 2 coincidencias del patrón de correo son el texto de prueba `@Model.Total @{ var x=1; }` de `FacturaCxc.{Carta,Ticket80}.Caracteres.html` [V] |
| M-11 | Fechas | Todas fijas: `22/10/2026`, `22 octubre 2026`, vencimiento `21/11/2026`, `Reimpreso el 22/10/2026 10:30`, `Impreso 22/10/2026 10:30`, cierre `22/10/2026 18:30`, reporte `Impreso: 22/10/2026 11:30`, lote `22/10/2027` [V]. No hay fecha de la ejecución |
| M-12 | Fechas de metadatos de PDF | `/CreationDate` y `/ModDate` = `20261022…-04'00'` (día de la captura, huso -04:00) en los 41 PDF; no entran en la comparación. Producer ausente; `Creator (GPOS)` [V] |
| M-13 | RNC, cédulas, teléfonos | Emisor `131000001`; cliente `131000000`; teléfonos `809-555-01xx` y `809-555-0000` (rango 555, de ficción). Con el algoritmo habitual del dígito verificador del RNC (pesos 7-9-8-6-5-4-3-2, módulo 11) ni `131000001` ni `131000000` son válidos, de modo que no pueden ser de una empresa real [I: no revisé el algoritmo en el código]. La cédula de la constancia `00112345678` y el nombre «JUAN PÉREZ» tienen forma de dato inventado (dígitos correlativos) [I] |
| M-14 | Tarjetas | Solo máscara `****1234` / `(1234)`; no hay números completos [V] |
| M-15 | Fuentes en los PDF | Lato (Regular, Bold, SemiBold, Italic) y Cascadia Mono Bold, incrustadas por QuestPDF; ninguna depende de fuentes del sistema [V] |
| M-16 | PDF: cabecera y páginas | 41 `%PDF-1.4`; páginas: 1 salvo `Cierre.X.Carta` (2), `Cierre.Z.Carta.Anulado` (2), `Reporte.Resultado.Carta.Multipagina` (3) [V] |
| M-17 | PDF: tamaño de página | Carta 612 x 792 pt (215,9 x 279,4 mm); ticket 58: 164,5 pt de ancho (58,0 mm); ticket 80: 226,75 pt (80,0 mm). Alturas de ticket entre 109,0 y 224,6 mm, según contenido [V] |
| M-18 | Diferencias entre papeles de una misma familia (HTML) | Ticket 58 frente a Ticket 80: **texto idéntico** en los 40 pares de la carpeta (incluidos los nuevos); solo cambian tamaños de letra y de logo [V]. Carta vs ticket: distinto diseño (ver 2.1) |
| M-19 | Dorados byte a byte idénticos entre sí | 5 hashes repetidos: `NotaCxc.{Carta,Ticket58,Ticket80}.B04` = `DevolucionCxc.*.B04` (3 pares), `DisenoGrafico.Ticket58` = `Ticket80` de la línea base, `TicketPos.Carta.PagoMixto` = `TicketPos.Carta` de la línea base [V] |
| M-20 | Marca de copia por dorado (HTML) | Con «COPIA 2» + «Reimpreso…»: 35 HTML nuevos; sin marca por diseño: Original (2), Anulada (3), VistaPrevia (3, con su propia leyenda), Minima/Minimo/VariasFormas (9), SinVerCostos (12), DatosReales (3), Retenciones de compras (3) [V] |
| M-21 | Texto de los PDF | Extraído para los 25 PDF; entre otras cosas confirma «*** ANULADO ***», títulos, totales y los pies. Las anomalías A-03 a A-06 salen de ahí [V el texto; I la interpretación visual] |

Lo que **no** pude hacer: abrir los PDF en un visor ni ver el HTML en un navegador (no hay herramienta de captura aquí), de modo que **nada de lo visual** (solapes, cortes, marca de agua sobre cifras, legibilidad, orden real de las columnas) está verificado.

## 4. Anomalías y puntos a decidir

Severidad orientativa para la decisión humana; ninguna impide que la guarda funcione. «Preexistente» = el formato ya se comportaba así antes del PR y el dorado lo congela.

| Id | Sev. | Archivo(s) | Evidencia | Qué decidir |
|---|---|---|---|---|
| A-01 | Media | `html/{Ajuste,Conduce,ConteoFisico,Entrada}.{Carta,Ticket58,Ticket80}.SinVerCostos.html` (12) frente a `pdf/Documento.Entrada.*.SinVerCostos.pdf` | HTML: `Subtotal: 0.00`, `Total RD$: 0.00`, precios `0.00` en Carta; ticket `2 UND x 0.00 \| 0.00`. El PDF de la Entrada Carta imprime solo `# Código Descripción Cant. Und.` y `3 artículo(s) · 6.00 unidades` | Un cero escrito parece un valor real; el PDF oculta las columnas. ¿Se aceptan ambos comportamientos o debe unificarse (ocultar columnas o mostrar «—»)? Hay que decidir antes de congelar |
| A-02 | Media | `html/DisenoGrafico.Ticket58.html` | Hash idéntico al de `DisenoGrafico.Ticket80` de la línea base (`d2936986b5…`). Todos los elementos miden `width:74mm` (ancho útil de 80 mm menos márgenes de 3 mm); en 58 mm el ancho útil es 52 mm | ¿El diseño gráfico tiene tamaño propio y el nombre «Ticket58» solo indica el papel pedido? Si no, a 58 mm se cortaría o desbordaría [I: sin renderizar]. El dorado, tal cual, no vigila el caso de 58 mm |
| A-02b | Baja | `html/DisenoGrafico.Ticket58.html` | Subtotal `3,586.50`, ITBIS `579.60`, TOTAL `4,086.10`: falta la línea de descuento `-80.00` y 3.586,50 + 579,60 = 4.166,10. La versión Carta (`Carta.H`) sí imprime «Descuento 80.00» (sin signo menos) | Es el formato de ejemplo del diseñador; decidir si es aceptable que el ejemplo de ticket no cuadre y que el descuento se imprima sin signo |
| A-03 | Baja | `pdf/Cierre.X.Carta.pdf`, `pdf/Cierre.Z.Carta.Anulado.pdf` (también `Cierre.Z.Carta.pdf` de la línea base) | 2 páginas; la página 2 solo trae «Cajero / Supervisor» y «*** DOCUMENTO NO VÁLIDO COMO CIERRE ***» o «*** FIN DEL CIERRE Z ***» | Firma y leyenda de cierre separadas del cuerpo: ¿se acepta o se ajusta el diseño? Preexistente |
| A-04 | Baja | `pdf/Cierre.{X,Z}.*` | «Total» de formas de pago `52,150.00` = 30.000 + 20.450 + 1.700 (EFECTIVO US$ 28,00), pero VENTA NETA `50,450.00` (= 30.000 + 20.450). Base `43,060.28` + ITBIS `7,750.85` = `50,811.13` frente a Total facturado `50,800.00` | Los datos del caso no cuadran entre sí (la guarda no lo detecta). Un error de suma real quedaría escondido tras estas cifras. Pedir un caso coherente en una recaptura futura |
| A-05 | Media | `pdf/Cierre.Z.Ticket80.SinConteo.pdf` | Sin bloque de arqueo, pero imprime «Efectivo esperado 31,650.00» y «Efectivo esperado US$ 28.00» | En un cierre ciego el cajero no debería ver lo esperado antes de contar. No localicé la regla firmada que lo diga [I]; el propietario o A deben confirmar si «SinConteo» es un cierre ciego |
| A-06 | Media | `pdf/Documento.FacturaCxc.Ticket58.NumeroLargo.pdf` | e-NCF `E310000000001` y modificado `E310000000002` impresos; el texto no contiene QR, código de seguridad ni fecha de firma. ADR-51 dice que la constancia sin e-CF firmado se imprime «sin QR, sin código de seguridad» | Aceptable como línea base del estado actual (e-CF decidido, no implementado). Debe quedar claro que este dorado **no** prueba la representación impresa de un e-CF firmado; cuando se implemente, recapturar con motivo |
| A-07 | Media | `html/{Ajuste,Conduce,ConteoFisico,Entrada}.Carta.SinVerCostos.html`, `html/Pago.Carta.Minimo.html` (y 9 más en la línea base) | Aparece «Comprobante fiscal» sin línea «NCF:» en 14 Carta HTML de documentos de inventario, pagos o cobros | Rótulo fiscal en un documento sin NCF; riesgo de confusión. Preexistente. Decidir si se limpia (cambio de apariencia, PR aparte con su recaptura) |
| A-08 | Baja | `html/Pago.{Carta,Ticket58,Ticket80}.Minimo.html`, `html/Cotizacion.*.Minima.html` | «PAGO A PROVEEDOR (CHEQUE O TRANSFERENCIA)» con tabla de artículos, «Para: CLIENTE…», «Firma del Cliente»; ticket «Cliente:» y «Gracias por su compra» | Plantilla genérica reutilizada en documentos de otra naturaleza; confirmar con el vocabulario de BP2 |
| A-09 | Media | `html/ConstanciaRetencion.*.DatosReales.html`, `pdf/Documento.ConstanciaRetencion.*.pdf` | Ticket: «Cliente:», filas «NCF … 1,540.00» (ITBIS + ISR sumados), «Subtotal», «TOTAL RD$», «Gracias por su compra»; no hay % ni tipo de ISR. Carta: repite «Agente de retención» en dos líneas (`Agente de retención: … · RNC 131000001` y `Agente de retención: …, RNC 131000001`) | La constancia es un documento fiscal para el retenido; el ticket pierde el desglose y usa el vocabulario de una venta. Decidir si basta |
| A-10 | Baja | `html/NotaCxc.*.B03/B04`, `html/DevolucionCxc.*.B04` | Las notas (débito y crédito) llevan `No. FC00001234` (prefijo de factura) y `DevolucionCxc.B04` es byte a byte igual que `NotaCxc.B04` | Datos de ejemplo reutilizados; el dorado de Devolución no añade cobertura distinta. Confirmar que ambas rutas deben producir la misma salida (en ese caso es correcto) |
| A-11 | Baja | `html/TicketPos.Carta.PagoMixto.html` | Idéntico al `TicketPos.Carta.html` de la línea base (`2f69b37731…`); la Carta no imprime formas de pago | Dorado redundante; no daña. Conviene saber que no ejercita el pago mixto en Carta |
| A-12 | Baja | `html/FacturaCxc.{Carta,Ticket80}.{LogoPng,LogoWebp}.html` y `DisenoGrafico.Carta.Imagenes.html` | Imágenes `data:` de 70 bytes (PNG), 634 (JPEG) y 42 (GIF), todas de 1 x 1 píxel [V, leí la cabecera]; el WebP (34 bytes) es del mismo orden [I] | No se prueba el tamaño de un logo real (`max-height`, `max-width`); solo el formato |
| A-13 | Baja | `html/FacturaCxc.{Carta,Ticket80}.Caracteres.html` | La nota contiene `&#x202E;al revés&#x202C;`. El HTML conserva el carácter de control bidireccional; los saltos `&#xD;&#xA;` y el tabulador colapsan en un espacio al mostrarse | Un texto de usuario con U+202E puede invertir visualmente lo que sigue; decidir si el formato debe neutralizar controles bidi [I: no lo probé en navegador]. Si es solo un caso de escape, no hay acción |
| A-14 | Baja | `pdf/Documento.FacturaCxc.{Ticket58,Ticket80}.B16_USD.pdf`, `Carta.B16_USD.pdf` | Metadato `/Title` presente en los PDF Anulada («FACTURA DE CONSUMO FC00001234») y ausente en los B16 | Inconsistencia menor de metadatos; sin efecto al imprimir |
| A-15 | Baja | `html/FacturaCxp.*.Retenciones.html` | «Retención ITBIS −108,00» sobre ITBIS 579,60 y «Retención ISR −100,00»; no deduje la tasa (108 no es 30 % ni 100 % del ITBIS de la compra) | Verificar contra la regla de retención que se quiso ilustrar; la constancia sí cuadra con sus porcentajes |

Notas sobre lo que **no** es anomalía [V]: no hay «SIN VALOR FISCAL» en cotizaciones/pedidos/conduces (la regla firmada solo lo exige en la vista previa, la Demostración y el vale no fiscal); los cuatro rótulos de papel (Carta, 58, 80) están presentes donde corresponde; los B02, B14, B15 y B16 llevan su NCF y título propios.

## 5. Cómo abrir cada formato

**HTML (70 archivos).**
1. Ábralo con doble clic en Chrome o Edge (son autocontenidos: sin hojas de estilo ni imágenes externas).
2. Los de ticket no declaran su ancho en el HTML: en pantalla se estiran. Para ver el ancho real, en DevTools (F12) active la barra de dispositivos y fije 219 px (58 mm) o 302 px (80 mm) de ancho [I: equivalencia mm→px a 96 ppp]. Los de Carta usan `@page` con `size: letter` (o 279,4 x 215,9 mm en `Carta.H`); use «Imprimir / Guardar como PDF» para ver el tamaño.
3. Para mirar el diff sin abrirlo: `git diff` no aplica (son nuevos); use `git show origin/c/dorados-guarda-t4-01:tests/GPOS.Tests/Impresion/Dorados/html/<archivo>`. Para comparar papeles de una familia: `diff` de `Ticket58` contra `Ticket80` (solo difieren en CSS).

**PDF (25 archivos).**
1. Ábralos con cualquier lector (Edge, Adobe, SumatraPDF) al 100 %. Los PDF de ticket tienen la página del ancho del papel y alto variable (109 a 225 mm): en un lector se ven como una tira angosta.
2. Verificar en «Propiedades» el tamaño de página: Carta 8,5 x 11 pulgadas; ticket 2,28 x … (58 mm) o 3,15 x … (80 mm).
3. Los de varias páginas: `Cierre.X.Carta`, `Cierre.Z.Carta.Anulado` (2) y `Reporte.Resultado.Carta.Multipagina` (3).

**Hashes y bitácora.** Para confirmar que el archivo que mira es el del manifiesto, calcule el SHA-256 **después** de normalizar (HTML con LF; PDF con `/CreationDate ()` y `/ModDate ()`), o confíe en `Los_dorados_coinciden_con_el_manifiesto` (la prueba de `GuardaDoradosTests`). La bitácora de lo capturado y sus motivos está en `CAMBIOS.md` (entradas del 2026-10-22 21:14 a 21:24 UTC).

**Ejecutar las pruebas (no lo hice).** No ejecuté la suite en esta tarea (`GPOS.Tests` necesita una instancia de SQL Server de pruebas y el encargo era solo de lectura); esta guía no afirma que las pruebas pasen. Para comparar: `dotnet test tests/GPOS.Tests --filter "FullyQualifiedName~Impresion"` sin las variables `GPOS_TEST_DORADOS*` (modo comparación), con `GPOST_TEST_SERVER` apuntando a la instancia y sin otra suite en paralelo (CLAUDE.md, Calidad).

## 6. Límites de esta guía

- Es material de apoyo del equipo C; no declara aprobado ningún dorado. La revisión G-5 y su firma son del propietario o de A.
- Lo visual no está verificado (sin visor ni navegador). El texto de los PDF es una reconstrucción propia.
- La segunda mitad del PR (código de `GuardaDorados`, `CasosDorados`, `ModelosDorados`) no es objeto de esta guía.
- Entregas: si se decide corregir A-01, A-02, A-05, A-07 o A-09, son cambios de apariencia y van en un PR propio de «cambio de apariencia» con su recaptura y motivo (LEEME, regla 5); corresponden al desarrollador del render, no a C.

### Apendice A. Ruta completa y SHA-256 normalizado (manifiesto)

Prefijo común de las rutas: `tests/GPOS.Tests/Impresion/Dorados/`

| Ruta | SHA-256 (manifiesto) |
|---|---|
| `html/Ajuste.Carta.SinVerCostos.html` | `31f5b3e8d20c9707eeea41eff4c7202ada147f12ed88a60c603df04760344f9e` |
| `html/Ajuste.Ticket58.SinVerCostos.html` | `6f1d8685f8345d981e82fd43d49dc7a6e4f16e324784d2937c4f9b6ed45072b0` |
| `html/Ajuste.Ticket80.SinVerCostos.html` | `75ef97cf2465e6e9467a3408cd3ece7600c715057248f620521c11b7b202e9ec` |
| `html/Conduce.Carta.SinVerCostos.html` | `fba28d3935f397573a4174849ccdb1c0fcc243d935c8f2b87b57af938184d426` |
| `html/Conduce.Ticket58.SinVerCostos.html` | `ae59a705d36930729c92b66d99a62790988d31d1454365d2e2ff7c0268bb400c` |
| `html/Conduce.Ticket80.SinVerCostos.html` | `ab9bd4db2122104a002523ac7133052f8e4da3ff0e087012f30a47751045a9c6` |
| `html/ConstanciaRetencion.Carta.DatosReales.html` | `710f39c05b96f989354a54fbbb3e04a0b600e891e149470c71fd9ff27c330877` |
| `html/ConstanciaRetencion.Ticket58.DatosReales.html` | `075ba3fec53a6b522a03fa59bb0f4954fea9b77b32bfefad0d3b136758a29558` |
| `html/ConstanciaRetencion.Ticket80.DatosReales.html` | `e5040c599d066bfb492b3e25ee5e76b0c9c09b37ab8266822ecfb4aafd20433f` |
| `html/ConteoFisico.Carta.SinVerCostos.html` | `de0b5d70b75b6fab171c1d175102616d14cce10ea0d58d5861a726d4819a40f0` |
| `html/ConteoFisico.Ticket58.SinVerCostos.html` | `b3fda0f05ea190d101b9c10d93916f35fd951b3fc833640e01c0ac68dc70f075` |
| `html/ConteoFisico.Ticket80.SinVerCostos.html` | `b0ce9d7e219fca3749235bd57a6e244c0e9c1ecf5cf9c283b0af5280b3bcd5f1` |
| `html/Cotizacion.Carta.Minima.html` | `cd10a946b47caebd141364624901484e5d925fcbeabeed14b6b59c02e9646a4c` |
| `html/Cotizacion.Ticket58.Minima.html` | `5229fe702edffe694e4f0a4249214aabeda14101ba98c74eeaeeb67751d10164` |
| `html/Cotizacion.Ticket80.Minima.html` | `a748422872fabcf505a04917bc15b1b203701fbd926b9ed0f37b989519db3099` |
| `html/DevolucionCxc.Carta.B04.html` | `9b8c1d326ccfd1050cb1c3151093ba9bd4269b947f3203466b71fb96c5faa66d` |
| `html/DevolucionCxc.Ticket58.B04.html` | `720ac1bce06d000d579b07b87c82b8401eb18d4e653dc17a7b447b27b5e3785a` |
| `html/DevolucionCxc.Ticket80.B04.html` | `e7c89ef117076910b77c92454db286fc45f4bf5485087f98c5661ea72045819b` |
| `html/DisenoGrafico.Carta.H.html` | `995dc4479b28e46d26eb6dd43096b1cdbcd793b2189b4dcf01bcd1fedf6a62ac` |
| `html/DisenoGrafico.Carta.Imagenes.html` | `b8a570844498884b08b6ccd69ee3bd74c1839bd2127ab9139fd99935cf5c24d8` |
| `html/DisenoGrafico.Ticket58.html` | `d2936986b58de559cfa71601dea374a0c24ed8d15677441dc019a7cbf766e097` |
| `html/Entrada.Carta.SinVerCostos.html` | `975e6adfc2ff5383f6678325c0c331c0b23a0e4b83f6c7b9bdaccee55fa86738` |
| `html/Entrada.Ticket58.SinVerCostos.html` | `3dc73fa0d4673c805b03cd2577386e27219065a62d0c1e529be68059f7e6ad5b` |
| `html/Entrada.Ticket80.SinVerCostos.html` | `4715ae06418ea03d67ffd5e9a0abaa9ac9dc5f0aed75666599af77f9d2fdebc5` |
| `html/FacturaCxc.Carta.Anulada.html` | `e08b6138187028cab118b4f00120a4422b8fa79751410f0920c9a00665876de2` |
| `html/FacturaCxc.Carta.B02.html` | `a657a78b8653f9a65287a4d33d207390df12f9a5edad41883ae62b5f82943d1d` |
| `html/FacturaCxc.Carta.B14.html` | `1072afec5e5e027daa0d0ae981980be757e1a8cd7cac43c773539ff281ea3d09` |
| `html/FacturaCxc.Carta.B15.html` | `0a122d5072862849a162244cbad6752b5e18e793584bd731ecdc9169eb58d171` |
| `html/FacturaCxc.Carta.B16_USD.html` | `4c1427f29f790dcf9b39d0d3a712dbe281930901324172605c58e14e1593cde9` |
| `html/FacturaCxc.Carta.Caracteres.html` | `9b32e7c8a2ab008d7525152bacc79a5a4cf7d31ea90353de897b040e4356823e` |
| `html/FacturaCxc.Carta.Lineas150.html` | `7d3443950f167adefbbd88b2a893a9f81e1e4c07bff6e4785e6fd092087e14cd` |
| `html/FacturaCxc.Carta.LogoPng.html` | `f837ccb566c9367f809eafc5f47c7f177eb47487a4b93f7f4d1f2af9a56a1d2e` |
| `html/FacturaCxc.Carta.LogoWebp.html` | `47aca5cb16f2b16c25dd86fea5c3cd37e32a82cb46ad2f5aa26bd46d1864a75e` |
| `html/FacturaCxc.Carta.Original.html` | `50193a66334f0c1abd339cc96be943b26cbea0b1f5903eddf6711812a1cac84e` |
| `html/FacturaCxc.Ticket58.Anulada.html` | `8ef6de22c7784fd9588690d1b7f882c1f9d208107fac601bf5d51f4698a0c7a8` |
| `html/FacturaCxc.Ticket58.B02.html` | `540613bae1d3b621529034dc32e2a1a8d26d0f730dc63cf612a5f2e841a36e49` |
| `html/FacturaCxc.Ticket58.B14.html` | `3f1a06235b797b2de23c3edc53c59728fd44303247edec9702bc1e0e31f47173` |
| `html/FacturaCxc.Ticket58.B15.html` | `3933827219a0948fad0205e0badcf9e7b234048196c9fb4eac8517c34d6a51dc` |
| `html/FacturaCxc.Ticket58.B16_USD.html` | `8221f23f6214b30113b9a87cf14d94e0421c3f08696466abc4f5219b86f476b4` |
| `html/FacturaCxc.Ticket80.Anulada.html` | `4e21eb4decbab078654a36c3dcdb3a6030eb6207df9db64acf967a2bbcd64694` |
| `html/FacturaCxc.Ticket80.B02.html` | `124de27dd61c7d7cf974b14f505c2b3653349cc3d411983ce3ce1fbffdc11b7c` |
| `html/FacturaCxc.Ticket80.B14.html` | `5e06926c98d6612c330b4c9759706eee76f816c3686b6ea19b52536a5a39b4d8` |
| `html/FacturaCxc.Ticket80.B15.html` | `da6ba671a31d10f7895d12e51ad3bac336b974f606cd83bf3a5c055de54566e3` |
| `html/FacturaCxc.Ticket80.B16_USD.html` | `fdf7086de86020007bf68e7bbeffbba10b6465654df5649e526818f05c8f2a99` |
| `html/FacturaCxc.Ticket80.Caracteres.html` | `a7006e6f094a61851d551b001e6d7624eaf4df2c47e445effbb1d772988f9253` |
| `html/FacturaCxc.Ticket80.Lineas150.html` | `3395b329a361ef1928b9f4fd7e3fe5de9e6911d6aa570bcfaeb24acb0b75d24d` |
| `html/FacturaCxc.Ticket80.LogoPng.html` | `791fa84f184bc994ea54359872e1e3436caf1ed1e1fa6f36c7e067bdab15fe70` |
| `html/FacturaCxc.Ticket80.LogoWebp.html` | `ae29432c5f610ac633fd7e9c2f471e680e19dfc68716875d89404c9ad79c0821` |
| `html/FacturaCxp.Carta.Retenciones.html` | `4bda7072599033dd32ae9ae239a0bc8c585cf8f98d3c4b1603dbab0c03bfafe2` |
| `html/FacturaCxp.Ticket58.Retenciones.html` | `479a010c5d38ab980a43fbb7a2c8d9dc1e580963c8aeadb8d049e43167d8e2d4` |
| `html/FacturaCxp.Ticket80.Retenciones.html` | `24e4defe6fd0e685ae7d975ce4f471afadd9fb7b7a99daa46ac23f717c59aa53` |
| `html/NotaCxc.Carta.B03.html` | `5b3137df3e865836404447b53f81e280591194c8b5c629f230895d1283ab4c9d` |
| `html/NotaCxc.Carta.B04.html` | `9b8c1d326ccfd1050cb1c3151093ba9bd4269b947f3203466b71fb96c5faa66d` |
| `html/NotaCxc.Ticket58.B03.html` | `34ff61a417ff4208262de6047380f221af29cc63ff2647b16f951f7f6a1e0ecd` |
| `html/NotaCxc.Ticket58.B04.html` | `720ac1bce06d000d579b07b87c82b8401eb18d4e653dc17a7b447b27b5e3785a` |
| `html/NotaCxc.Ticket80.B03.html` | `ba44eb94bd0d9eefb692c906605e5c2f6b5b9ef414ce793bf93aa40c8255ff73` |
| `html/NotaCxc.Ticket80.B04.html` | `e7c89ef117076910b77c92454db286fc45f4bf5485087f98c5661ea72045819b` |
| `html/Pago.Carta.Minimo.html` | `331eec7927a393bb15e97a06e5803965218bac8204e5b8abd29053bb02e52ba5` |
| `html/Pago.Ticket58.Minimo.html` | `26ae8e967c371faafa209647e93f41ca1838c26781ccbda3ad025b086ae09944` |
| `html/Pago.Ticket80.Minimo.html` | `e348225dafa843cc48d1664da7b5d3ed465f16c47a93eaf7c3c12de0a9bac91e` |
| `html/Recibo.Carta.VariasFormas.html` | `0e32c7112e7bfa01316552baf1700d28c907e6e1c6f963506bd1e1ffc4dfc163` |
| `html/Recibo.Ticket58.VariasFormas.html` | `1a1256240a2db70a69ff6007a99aa14232ba9a787c911492cb131790c31e8c0b` |
| `html/Recibo.Ticket80.VariasFormas.html` | `7c954d818ef349c007eafada351fa81b57ab6bf128061f4ac55b6256de569462` |
| `html/TicketPos.Carta.PagoMixto.html` | `2f69b37731d991573381dc289a7a4607921012227382f00de103399e23c59bfc` |
| `html/TicketPos.Carta.VistaPrevia.html` | `813cc8c9a133481a403fd9a68601b38a424626fdfd607de9ad44c58ab7dc2eef` |
| `html/TicketPos.Ticket58.PagoMixto.html` | `eb63e08b647b5a46fd7309946e67391911222aa79f2a7772da7e94e93a64015a` |
| `html/TicketPos.Ticket58.VistaPrevia.html` | `1969692e4b97b0a33dc6315cca6c7356f47bdda590c273f9439391f94828e3b3` |
| `html/TicketPos.Ticket80.Original.html` | `8238ff2976d22bd200d75c87d7bf39a8468a42189f6fe87ae8de7b2ddc5f7ffa` |
| `html/TicketPos.Ticket80.PagoMixto.html` | `270f33446a287862e0602be6a6c74dfe140625cb82934b2ee6b02a691c858435` |
| `html/TicketPos.Ticket80.VistaPrevia.html` | `deb3d02929dfa9188ac63c4315d8731435dde7fc2fb09c0b982dcc63139db2a0` |
| `pdf/Cierre.X.Carta.pdf` | `396e188412ee6f36167c4574435bc197ff8d2954af0048c0a749cbdbe27400cd` |
| `pdf/Cierre.X.Ticket58.pdf` | `5e0e7754f61b5cd67a671d93a89d54321258e4ca8f44f77e2d8c30c0a5a03d0a` |
| `pdf/Cierre.X.Ticket80.pdf` | `8b8e642f951753626d84aa4fd592705e6e2c6ac5e2ac029aab968198cd4f3064` |
| `pdf/Cierre.Z.Carta.Anulado.pdf` | `fa41bd48f05072e6ef6c79282321176203f7d31a83dfdac5246238c69ef6e905` |
| `pdf/Cierre.Z.Ticket80.SinConteo.pdf` | `dc2b093ca9c93614fd4c3c497676e2ccdbda568f721df9cb2d03de2521f0424f` |
| `pdf/Conduce.Transferencia.Carta.Anulada.pdf` | `97c53905a08ecacd6689c48a044e637706cb6619d095f054ab3e20081f7845b4` |
| `pdf/Conduce.Transferencia.Carta.ConLotesYSeries.pdf` | `0ae9a07a0e33fe78d0d203b96e41473bc7819c2b9518262e0e5900057339022a` |
| `pdf/Conduce.Transferencia.Carta.Impresion1.pdf` | `7bc973c65e80071d91b62a2917ab72b11805c401400ee6426ac7656082b55278` |
| `pdf/Conduce.Transferencia.Carta.TrasladoInterno.pdf` | `981a52c79a124b8ed12a58fa3f3395e8fef184598f1a6beb0c8078c3cfa593d9` |
| `pdf/Documento.ConstanciaRetencion.Carta.Retenciones.pdf` | `751488f433b35d9e6d5816611a5f37fe3109c2b729651daf60aff1f5f4b59aa0` |
| `pdf/Documento.ConstanciaRetencion.Ticket58.Retenciones.pdf` | `ae440d5cc369914e766f1a5aa64e56da8f11dbc38249e5c8b7c8bd58b8535f69` |
| `pdf/Documento.ConstanciaRetencion.Ticket80.Retenciones.pdf` | `27b9d61349c59c2a2a5dd00462848251e0fc87ab425c56b1241c79265c3c7a10` |
| `pdf/Documento.Entrada.Carta.SinVerCostos.pdf` | `307acd2cfb6cd257294e297e915a61a56056c2cd6a226fe4a91de54ed824afe0` |
| `pdf/Documento.Entrada.Ticket58.SinVerCostos.pdf` | `6b4f37378a37e543dfdb1d046a56a5c4b300097ba30904a25a8c3d5789c50a75` |
| `pdf/Documento.Entrada.Ticket80.SinVerCostos.pdf` | `9f605e9c8164cf67d421d0583e87357e25536ab86b8d42277eb63f4009e5ce0a` |
| `pdf/Documento.FacturaCxc.Carta.Anulada.pdf` | `afaaf3451063f536e745c8db90064a330aa5a9876f99d6797f0d8a0d618c465e` |
| `pdf/Documento.FacturaCxc.Carta.B16_USD.pdf` | `645b98efca24afbfb59b540a89f03d3ff20eeab0b4294b1c86e94e8366cd59e3` |
| `pdf/Documento.FacturaCxc.Ticket58.Anulada.pdf` | `9e61e2dec6e4f08cef511a8cc6f6149f799b45bade9af51257ca2369c6822bfd` |
| `pdf/Documento.FacturaCxc.Ticket58.B16_USD.pdf` | `3e7b18a218279a39449029087e06939e00c0103079d766b3f5ee7c4b3a9a261e` |
| `pdf/Documento.FacturaCxc.Ticket58.NumeroLargo.pdf` | `7684c9a2012a74737244f013918ad3fae04f26feb27fdee7f049bbb3d32ec773` |
| `pdf/Documento.FacturaCxc.Ticket80.Anulada.pdf` | `0efb28ec01b4860ace385b88cf07d987fa8e6e7b5a73f43ddeccbe12323dc77f` |
| `pdf/Documento.FacturaCxc.Ticket80.B16_USD.pdf` | `044580c442c6a7c4911e3ccca6ccd3032ff90ae4acb103b90fc44ff3170c6294` |
| `pdf/Reporte.Resultado.Carta.Multipagina.pdf` | `6bdb28dd242424239c5f83ccdca7f607e549cc2c5a5d9ddb62e4089997e94b1e` |
| `pdf/Reporte.Resultado.Carta.Vacio.pdf` | `25cd210d90dfeaf3d69a655f9e85dc8fee27ab47cc4d0867083a6c94ff8539d7` |
| `pdf/Reporte.Resultado.Carta.pdf` | `1be44ab0fc3ac89c5ff21977f6c0d412701f761443a65f7dcccd15b2ae02500c` |
