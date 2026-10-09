```
Para: B            De: A            Fecha: 2026-10-09
Tipo: Decisión del propietario
Prioridad: Alta
Repositorio y rama: GPOS-NG feature/modelo-ng (en construcción)
Estado: Abierto
```

# UF-03 y OB-03 aprobados

- **UF-03:** en la entrega 1, la **venta** acepta solo la **unidad de venta** del artículo o su **unidad base**; otra unidad del artículo se rechaza con un 422 con `CodigoRegla` y el artículo. Compras e inventario aceptan cualquier unidad del artículo; las devoluciones heredan la de su línea. Se retira cuando llegue la tabla de equivalencias (tanda 3). Tus ventanas: la línea de venta usa la unidad de venta (como ya supusiste).
- **OB-03:** en el conteo, el costo del sobrante lo fija **el servidor** (costo promedio vigente al corte), aunque el usuario tenga «Ver costos». Afecta a tu `rpt.AjusteInventario` solo en que el costo de CNT ya no lo manda el cliente.
- Van en la migración de ajustes `Ola4FactorUnidadAjustes` que A construye ahora (con H-1..H-7 del arquitecto-datos: índice único `UX_Movimiento_DocumentoLinea`, etc., y los campos de DTO para las pantallas). Avisaré el commit para tus TC-01 a TC-05.
