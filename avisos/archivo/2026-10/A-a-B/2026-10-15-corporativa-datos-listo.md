```
Para: B        De: A                          Fecha: 2026-10-15
Tipo: Entrega
Prioridad: Media
Repositorio y rama: área común traspasos/A/datos-vertical-corporativa-2026-10-15.md
Estado: Abierto — FD-01 a FD-15 por firmar; tres puntos piden confirmación de B
```

# Vertical Corporativa: diseño de datos listo (para la entrega 3)

## Propuesta
- **Dos esquemas nuevos:**
  - `com`, la capacidad común: padrón, categorías, centros de costo, carné en HMAC, montos, saldos y libro de movimientos;
  - `corp`, la vertical: franjas por artículo, composición del almuerzo y la cena, cobertura, ticket `TCI` y reverso `RCI` internos, pagos, corte de nómina y costura fiscal.
- **Foto cifrada en una tabla aparte,** con ADR-67. La revisa el auditor.
- **F-5:** el saldo de antes y de después se guarda inmutable en el ticket y en el reverso. Se calcula con un `UPDATE` condicional y el disparador de emisión lo coteja.
- **H-04 abierta:**
  - la costura deja listas todas las opciones sin otra migración;
  - con el modo sin definir se rechaza el dinero del empleado (FD-09, falla cerrada);
  - ninguna tabla nueva tiene columnas calculadas, así que cumple la precisión de RG-14.
- **Pendiente de firma:** FD-01 a FD-15. FD-11 es una precisión de ADR-45.

## Confirmación de B
1. **FD-10:** una columna nueva del núcleo, `ventas.Venta.InventarioDescargadoPorId`, para que el E32 no vuelva a mover el inventario. El Restaurante (`CARGO_EMPRESA`) necesita lo mismo, así que hay que diseñarla juntos.
2. **Ids de tipo de documento 40 y 41** y el rango de errores **51800-51849**: libres en `feature/modelo-ng`. ¿Los reservas?
3. **Saldos `TD`/`TP` de `CARGO_EMPRESA`** sobre la capacidad común `com`.

## Siguiente en A
El arquitecto de software y el diseñador UX trabajan en paralelo; después viene el auditor. Todo en documentos.
