---
name: respuestas-propietario-modelo-datos
description: "Respuestas del propietario del 2026-10-03 a las preguntas P-1 a P-11 del modelo de datos: ITBIS 16 %, límite de crédito, códigos inmutables con movimientos, listas de precios por sucursal, sin conexión por sucursal con sincronización central, recetas y mermas en restaurante, ARS en farmacia"
metadata:
  node_type: memory
  type: project
  originSessionId: 9bf422be-17fa-4dbe-9779-4afcf2205243
  modified: 2026-10-04T03:43:03.342Z
---

Respuestas del propietario (2026-10-03) a las preguntas del especialista-pos sobre el nuevo modelo de datos:

- **ITBIS:** no existe el 10 %; se agrega el 16 % (además del 18 %, 0 % y exento).
- **Límite de crédito:** sí se usa; es parte de la gestión de cuentas por cobrar.
- **Códigos visibles:** no se cambia el código de un artículo, cliente o suplidor con movimientos. Regla de oro: producto nuevo con código nuevo para mantener el control de costos. Excepciones sui generis muy raras.
- **Precios por sucursal:** un producto tiene un solo precio por empresa; las excepciones geográficas se resuelven con listas de precios (niveles), no con precios por sucursal.
- **Plazo de devolución:** fiscalmente no debería superar 30 días; el plazo comercial lo fija cada empresa según la industria.
- **Dimensionamiento:** clientes pequeños con 3 sucursales y 1 o 2 cajas (SQL Server Express); clientes grandes previstos con 30+ sucursales y 15 a 20 cajas por sucursal (SQL Server Standard). Enterprise NO se descarta: el propietario aclaró el 2026-10-04 que nunca lo ha implantado, pero su uso depende del presupuesto de cada cliente (no escribir «nunca Enterprise»).
- **Reportes viejos:** se rehacen; no se conserva compatibilidad con reportes SQL de BP2. "Nada anterior debe romper el principio del mejor rendimiento posible".
- **Farmacia:** sí a todo: facturación a ARS desde el POS (copago y cobertura, autorización, póliza, afiliado) y medicamentos controlados con receta.
- **Restaurante:** sí: recetas que descuentan ingredientes, control de costos, producción y mermas. Es la vertical más delicada por los movimientos granulares de inventario.
- **Devolución con tarjeta:** normalmente en efectivo o como abono a una nueva factura (cambio de talla); el reverso en el pinpad debe ser posible pero es excepcional.
- **Sin conexión:** emisión de facturas y devoluciones como mínimo. **Cada sucursal debe ser autosuficiente y sincronizarse con el servidor central cuando vuelve la conexión.** República Dominicana es un entorno hostil para la conexión permanente.

**Why:** son decisiones de negocio del propietario que fijan requisitos del modelo de datos nuevo (ADR-52 propuesto).

**How to apply:** tratarlas como requisitos firmes en el diseño del modelo y en la hoja de firma; en especial, el modelo debe contemplar una base local por sucursal con identidad generada en el origen y sincronización idempotente hacia la base central de la empresa.

Relacionado: [[decision-modelo-datos-propio-pendiente]], [[devoluciones-son-notas-de-credito]].
