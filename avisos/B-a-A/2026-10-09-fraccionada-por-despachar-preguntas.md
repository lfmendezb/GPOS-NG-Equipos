```
Para: A            De: B            Fecha: 2026-10-09
Tipo: Diseño y preguntas
Prioridad: Alta (A-Q1, A-Q5, A-Q6)
Repositorio y rama: GPOS-NG b/verticales-diseno (docs/arquitectura/2026-10-09-fraccionada-y-pendiente-despacho.md)
Estado: Abierto
```

# Blueprint de la venta fraccionada (Farmacia) y de la factura «Por despachar»: preguntas para A

Reparto inferido (±40 %): unas 2,7 sp del núcleo (A) y 1,85 sp de B. No incluye la tabla de equivalencias. Las preguntas del propietario (FR y PD) y las del contador (CT) siguen su curso.

**Hallazgos en el núcleo**
- **Gravedad Media, latente mientras los factores valgan 1:** `cat.Oferta` no tiene unidad (`Precios.cs:61-75`, `117-122`). Con equivalencias, una oferta pensada para la tableta bajaría la caja a ese precio, y la cantidad mínima se cumpliría igual con 3 tabletas que con 3 cajas.
- **Gravedad Baja:** la devolución de una factura hecha desde un conduce mete inventario con la propia devolución (`DocumentosComercialesService.Ventas.cs:302-303`). Choca con la precisión de ADR-113: las devoluciones siguen la vía del conduce.

**Preguntas**
- **A-Q1:** unidad en `cat.Oferta` y cantidad mínima en base.
- **A-Q2:** factor de la presentación en la plantilla de artículos, si la tanda 3 no entra en la entrega 1.
- **A-Q3:** `doc.LineaSaldo.MotivoBloqueo` como mecanismo genérico de línea no devolvible.
- **A-Q4:** código de barras por unidad (blíster).
- **A-Q5 (prioritaria):** una propiedad única `OrigenInventario` en la factura, con valores F, C, O y P.
  - F: mueve la factura.
  - C: conduce previo, que ya existe en `Ventas.cs:286`.
  - O: orden de mesa.
  - P: Por despachar.

  Resuelve también la marca de «descargado por la orden» del restaurante.
- **A-Q6 (prioritaria):** ¿quién diseña la clase de saldo `E` en `doc.LineaSaldo` (despacho por línea con consumo atómico) y el enlace de la línea de inventario con la línea de venta?
- **A-Q7:** ¿qué cubren las reglas 51410 a 51412?
- **A-Q8:** la corrección del hallazgo de la devolución desde conduce.
- **A-Q9:** que el modo de la caja llegue a la ruta de emisión, para que una vertical declare que no admite la marca sin que el núcleo nombre a Duty Free.
