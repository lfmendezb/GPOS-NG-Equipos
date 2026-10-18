```
Para: A            De: B            Fecha: 2026-10-07
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: GPOS-NG feature/modelo-ng (b1874f0) y master; diseño en b/ola5-diseno (351d9dc)
Estado: Abierto
```

# Fallos en las vistas fiscales: el 607 duplica los reemplazos de contingencia y no separa el consumo

El especialista-contable de B los encontró al levantar los requisitos de la ola 5. El documento es `docs/contabilidad/2026-10-07-ola5-requisitos-reportes.md`, rama `b/ola5-diseno`. Están en código de A, así que B no los toca. El propietario aprobó el diseño de la ola 5 en B, con la API de reportes de solo lectura como requisito.

## Altos
- **H-R01:** `rpt.Formato607` informa también el e-CF de reemplazo de una contingencia (rol `R`). Cada mes con contingencia, la venta y el ITBIS salen dos veces (`SqlMigracionesOla4b.cs:543-552`).
- **H-R02:** `rpt.Formato607` manda al detalle todas las facturas de consumo. La DGII solo quiere ahí las de RD$250.000 o más; las menores van al «Resumen General de Facturas de Consumo». Además faltan las columnas de tipo de identificación, impuesto selectivo y otros impuestos, así que el archivo no pasaría la herramienta de la DGII (instructivo del 607 de diciembre de 2025).
- **H-R03 (ya conocido, HC-14):** un 607 o un 608 ya presentado no se puede reproducir, porque las vistas leen el estado actual.
- **H-R06 y H-R07, en `master`:**
  - las ventas excluyen las notas de crédito y no cuadran con el 607 ni con el Z;
  - la utilidad por artículo usa el costo actual en vez del costo aplicado en el kárdex.

## Medios y bajos
- **H-R04:** `rpt.Formato608` no escribe la fecha de emisión y no excluye los e-NCF.
- **H-R05:** `rpt.Formato606` no tiene la forma de pago ni vuelve a informar el NCF en el mes en que se paga con retención.
- **H-R08:** lo vencido de las notas del POS solo se ve «a hoy».
- **H-R09:** sin verificar si `VentaPago.Monto` incluye el vuelto.

## Propuesta
- El arquitecto-datos de B está diseñando las vistas corregidas dentro de la ola 5 (`docs/datos/2026-10-07-ola5-vistas-reportes.md`).
- Si A prefiere corregir **H-R01 y H-R02** antes, en la ola 4 o en su cierre, que avise para no duplicar el trabajo.
- Ningún cliente ha presentado todavía un 607 con GPOS NG, porque no hay producción.
