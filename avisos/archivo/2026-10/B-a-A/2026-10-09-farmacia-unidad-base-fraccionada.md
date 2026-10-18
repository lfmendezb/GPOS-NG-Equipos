```
Para: A            De: B            Fecha: 2026-10-09
Tipo: Decisión del propietario y pedido para la tanda 3
Prioridad: Alta (antes de implantar Farmacia)
Repositorio y rama: GPOS-NG b/verticales-diseno (docs/ux/2026-10-08-ventana-facturacion-farmacia.md)
Estado: Abierto
```

# Farmacia: venta fraccionada (sí) y unidad base mínima desde la entrega 1

El propietario decidió el 2026-10-09:
- **UF-08:** la receta se anota en presentaciones.
- **UF-09:** Farmacia **vende fraccionado** (unidades sueltas, distintas de la presentación).
- **Precio de la unidad suelta:** por lista de precios, con el mismo nivel y un precio por unidad de medida (literal: «es simplemente indicar el nivel de precio asociado con su unidad de venta»).
- **Reglas:**
  - lote de la caja abierta (ADR-119);
  - controlados sueltos solo con receta y con autorización del regente;
  - equivalencia anotada en presentaciones;
  - sin devolución de sueltos en controlados.

## Para A
1. **Tanda 3 (equivalencias):** la venta fraccionada depende de ella. Contemplen:
   - venta en cualquier unidad del artículo con su factor;
   - precio por unidad desde la lista;
   - lote validado en unidad base;
   - devolución en la unidad de origen.
2. **Regla de implantación, desde la entrega 1:** los medicamentos que se venden sueltos nacen con la **unidad mínima como base**, porque su regla 51385 impide cambiar la base después.
   - ¿La plantilla de importación de artículos (J-3) y el alta lo permiten ya con factor 1?
   - ¿Hace falta un aviso al crear un artículo de Farmacia?
3. **UF-03 sigue en pie:** en la entrega 1, aceptar en la venta solo la unidad de venta o la base. Si no, con factor 1, vender una «CAJA» descontaría 1 unidad base.

B prepara el diseño completo de la venta fraccionada y del despacho posterior de la «Mercancía pendiente de despacho». Se los pasaremos.
