```
Para: A            De: B            Fecha: 2026-10-09
Tipo: Preguntas
Prioridad: Alta (UF-03 y UF-05 antes de Ola4FactorUnidad)
Repositorio y rama: GPOS-NG b/verticales-diseno
Estado: Abierto
```

# FactorUnidad en las ventanas de las verticales: preguntas UF para A

B agregó la nota FactorUnidad a los seis diseños de ventanas (Duty Free y su detalle, Restaurante con la botonera, comandera, Farmacia y Estándar), en `docs/ux/`. Criterio común:
- cada línea toma la unidad de venta del artículo, sin selector en la entrega 1;
- una unidad ajena la rechaza el servidor, y la ventana muestra el error en la línea;
- sin equivalencias hasta su tanda 3;
- no se usan los números de regla reservados.

## Preguntas
- **UF-01:** ¿la línea de venta o de ronda manda la unidad explícita, o el servidor pone la unidad de venta cuando no viene?
- **UF-02:** ¿qué código y qué texto tiene el rechazo por unidad ajena?
- **UF-03 (prioritaria):** en la entrega 1, ¿el núcleo acepta en la venta cualquier unidad del artículo o solo la de venta (o la base)? Hoy el artículo admite precios por unidad (`Articulos.razor:174`, `ListasPrecios.razor:197`). Con factor 1, vender una «CAJA» descontaría 1 unidad base. **Recomendamos aceptar solo la de venta o la base hasta la tanda 3.**
- **UF-04:** si la merma se registra como AJU, ¿el motivo del encabezado se copia a cada línea por la regla 51382?
- **UF-05 (prioritaria):** ¿cómo se aplica la regla 51380 (kárdex de la factura línea a línea) en el restaurante? Allí la factura no mueve inventario, porque se descarga al enviar la ronda (ADR-113, punto 4, firmado). Puede chocar con lo firmado.
- **UF-06:** al anular lo comandado o al emitir una nota de crédito de un plato con receta, ¿se reversan los movimientos de ingredientes de esa ronda o se recalculan con la receta vigente?
- **UF-07 (también para el propietario):** después de la tanda 3, ¿el árbol del menú guarda artículo más unidad?
- **UF-10:** ¿la búsqueda sin tildes cubre la descripción del artículo con la misma normalización que la clave de principios activos (DC-2)? ¿PA-D-07 queda respondida con su adelanto?
- **UF-11:** ¿qué cubren las reglas 51410 a 51412 de Farmacia?
- **UF-12:** en la receta R-12, ¿la unidad del ingrediente queda fija en la base en la entrega 1?
