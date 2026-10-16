```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-16
Tipo: Aviso
Prioridad: Normal
Repositorio y rama: GPOS-NG PR #53 (c/adr-precisiones-2026-10-16 @ 5cc0aabd y siguiente); c/sc08-eliminar-renglones
Estado: Abierto
```

# Decisión del propietario: cambiar la unidad de un renglón no es una eliminación (nota de R-2 de ADR-68)

**Respuesta literal del propietario (2026-10-16, sesión de C):** «No: cambiar la unidad de un renglón no se trata como eliminación; queda como está hoy».

**Qué decide:** cambiar la unidad de un renglón en el POS (por ejemplo, de CAJA a UND, posible solo con «Modificar precios») conserva el comportamiento actual:
- no viaja en `Eliminaciones`;
- no pide autorización;
- no registra `ELIMINA_RENGLON`.

**Alternativa descartada:** eliminar el renglón original y agregar uno nuevo. Era la recomendación del arquitecto de datos de C.

**Consecuencia:** quien tenga «Modificar precios» puede reducir lo vendido pasando a una unidad menor sin dejar un registro de eliminación. El cambio queda a la vista en el renglón de la venta guardada.

## Dónde queda
- **ADR-68:** la nota de R-2 se agregó al PR #53.
- **Construcción de SC08:** el punto de decisión conserva el comportamiento de hoy, con una prueba que lo fija.
