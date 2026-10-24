```
Para: A y B        De: C        Fecha: 2026-10-23
Tipo: Entrega (material para la revisión G-5 del #156) y hallazgos
Prioridad: Normal (antes del 13-nov)
Repositorio y rama: GPOS-NG [#156](https://github.com/lfmendezb/GPOS-NG/pull/156) (`c/dorados-guarda-t4-01` @ `03c0afd0`)
Estado: Abierto
```

# Guía de revisión G-5 de los 95 dorados del #156

`traspasos/C/2026-10-23-guia-revision-dorados-t4-01.md` (347 líneas; apéndice A con las 95 filas): inventario por familia, qué debe mirar quien revisa, comprobaciones mecánicas, anomalías y cómo abrir cada formato. **No declara nada aprobado**: la revisión humana la hace el propietario o A. Son 70 HTML y 25 PDF (grupos P152-17 1 a 6 de `CAMBIOS.md`: 41+3+21+24+3+3); los otros 78 de la línea base solo sirvieron de comparación. No había visor de PDF, navegador ni validador HTML, así que **nada visual está verificado**; el texto de los PDF viene de un extractor propio (lectura aproximada); no se corrió la suite.

**Comprobaciones mecánicas (verificadas sobre los archivos):** los 95 hashes del manifiesto se recalculan igual con la normalización de `GuardaDorados`; cada dorado tiene exactamente una entrada en `CAMBIOS.md` y su hash final coincide con el manifiesto; 173 entradas = 132 HTML + 41 PDF en disco; sin rutas absolutas, nombres de máquina o usuario, URL externas ni secretos (HTML y PDF); fechas fijas; RNC y teléfonos ficticios (dígito verificador comprobado con el algoritmo estándar, no contra el código); tarjetas solo enmascaradas; etiquetas HTML balanceadas; PDF `%PDF-1.4` con fuentes incrustadas, Carta 215,9×279,4 mm y tickets de 58,0 y 80,0 mm, 1 página salvo `Cierre.X.Carta` y `Cierre.Z.Carta.Anulado` (2) y `Reporte.Resultado.Carta.Multipagina` (3). **El checkout en Windows trae los HTML con CRLF:** `sha256sum` sobre el archivo en disco no coincide con el manifiesto; hay que usar el hash normalizado. Sin defectos Críticos ni Altos; 15 puntos para decidir:

| ID | Sev. | Anomalía |
|---|---|---|
| A-01 | Media | Los HTML «SinVerCostos» (12) muestran `0.00` en precios y totales, mientras el PDF `Documento.Entrada.*.SinVerCostos.pdf` oculta las columnas: dos comportamientos para el mismo caso. |
| A-02 | Media | `DisenoGrafico.Ticket58.html` es idéntico al de 80 mm de la línea base, con elementos de 74 mm de ancho: en 58 mm se cortaría o desbordaría (inferido, no renderizado). A-02b (Baja): ese ticket no imprime la línea de descuento y las cifras no cuadran (3.586,50 + 579,60 ≠ 4.086,10). |
| A-05 | Media | `Cierre.Z.Ticket80.SinConteo` no tiene arqueo pero imprime «Efectivo esperado»; no encontré la regla firmada del cierre ciego: hay que confirmarla. |
| A-06 | Media | El único dorado con e-NCF (`...Ticket58.NumeroLargo.pdf`) no trae QR, código de seguridad ni fecha de firma; coherente con ADR-51 y con que el e-CF no esté implementado, pero no prueba la representación impresa de un e-CF firmado. |
| A-07 | Media | El rótulo «Comprobante fiscal» sin línea NCF aparece en 14 Carta HTML de documentos de inventario o pago (5 de este PR, 9 ya en la línea base). |
| A-09 | Media | El ticket de la constancia de retención pierde el desglose de ITBIS e ISR y usa vocabulario de venta («Cliente:», «Gracias por su compra»); la Carta repite la línea «Agente de retención». |
| A-03, A-04, A-08, A-10 a A-15 | Baja | Cierre en 2 páginas con la segunda casi vacía; datos del cierre que no cuadran (formas de pago 52.150 contra venta neta 50.450; base más ITBIS 50.811,13 contra 50.800 facturado: si hubiera un error real de suma, estos datos lo esconderían); `Pago.*.Minimo` con plantilla genérica («Para: CLIENTE», «Firma del Cliente» en un pago a proveedor); notas B03 y B04 con prefijo de factura `FC00001234` y `DevolucionCxc.*.B04` byte a byte igual a `NotaCxc.*.B04`; `TicketPos.Carta.PagoMixto` idéntico al dorado base y sin cobertura; imágenes embebidas de 1×1 píxel (no prueban un logo real); el dorado «Caracteres» deja pasar U+202E (inferido); `/Title` ausente en los PDF de B16; retención de ITBIS de la compra (−108,00) sin tasa evidente. |

**No son anomalías:** no hay regla firmada que exija «SIN VALOR FISCAL» en cotizaciones, conduces o inventario (solo en la vista previa, la Demostración y el vale no fiscal); los tres «Anulada» usan NCF de papel, no e-NCF, coherente con la regla del 2026-10-08.

**Qué hace falta de ustedes:** abrir un HTML y un PDF por familia con la sección 5 de la guía y resolver primero A-01, A-02 y A-05 antes de firmar. Cualquier corrección de apariencia va en un PR propio con recaptura y motivo (LEEME, regla 5); este PR no la hace. A-01, A-05 y A-07 podrían volverse decisión de apariencia del propietario.

Respuesta requerida: quién hace la revisión G-5 (propietario o A) y la decisión sobre A-01, A-02, A-05, A-06, A-07 y A-09 antes del 13-nov.
