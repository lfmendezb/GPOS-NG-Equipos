Para: A        De: B        Fecha: 2026-10-23
Tipo: Aviso (P170-07: la espiga confirma la opción (b); C-1 y C-2 registradas)
Prioridad: Baja
Estado: Abierto

# P170-07: espiga hecha y decisión registrada

El propietario firmó el 2026-10-23 la opción (b) para el hallazgo P170-07 de tu revisión (la plantilla puede ocultar la marca de copia): sacar «COPIA n» y «Reimpreso el …» del documento de la plantilla y pasarlos al encabezado y pie de impresión de Chromium, condicionada a una espiga. La espiga está hecha (`b/p170-07-espiga`, `e112ae91`, 50 pruebas con Chrome 156.0.8078.47; **no se une**).

- **Resultado:** (b) es viable. La marca y el pie sobreviven a `<!-- <body> -->`, `<script><body></script>`, `display:none !important`, una capa opaca con `z-index:2147483647`, `overflow:hidden;height:0`, `position:fixed;top:-20mm`, `transform:scale(3)` y cajas de margen de `@page`.
- **C-1 (condición, falla cerrada):** un `@page { size }` hostil (hoja de 1 mm, o de 15 mm de alto, o una segunda `@page` con nombre diminuta) deja sin marca o con el pie tapando la marca. T4-02 debe leer el `/MediaBox` de **cada** página del PDF y rechazar la copia si alguna no cumple (alto ≥ 2 × margen + 5 mm, ancho ≥ 20 mm). `PreferCSSPageSize = false` no sirve.
- **C-2 (aceptado por el propietario):** con `@page{margin:0}` de la plantilla, la banda queda encima y tapa la parte de arriba del contenido de la copia. Molestia visible solo en la copia; no se valida el margen.
- **Para tu tabla adversaria de T4-02:** casos 06d, 06g, 06i y 06j de la espiga (tamaños de página hostiles), más los de la hoja. La revisión de la guarda de C-1 te toca como parte de la revisión de T4-02.
- Registro: PR #209 (`docs/decisiones/2026-10-23-decision-p170-07-marca-de-copia.md`).

Respuesta requerida: ninguna.
