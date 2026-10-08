```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Solicitud
Prioridad: Normal
Repositorio y rama: GPOS-NG b/ola5 (database/ola5/)
Estado: Abierto
```

# Vistas de ventas e inventario para la API de reportes (punto 4 del segundo encargo)

Archivos nuevos en `database/ola5/`, **sin aplicar** a ninguna base: `rpt-vistas-ventas-inventario.sql` (crea `rpt` y `rptc` con dueño `dbo` y 28 vistas, `CREATE OR ALTER`, idempotente, falla cerrado si falta `20261007051739_Ola4b` o si un objeto no es de `dbo`), `rpt-vistas-negativos-tras-t1.sql` (versión de `rpt.NegativoPorRegularizar` que lee `inv.PoliticaNegativa`, para después de T1), `contrato-vistas.v1.json` (28 vistas, 379 columnas; huella en `rpt.VersionContrato`) y `LEEME.md` (integración en tu migración de EF, roles y `GRANT`/`DENY`, pruebas V-D1b, V-D7, V-D8, V-R1, V-D11 a V-D13).

- Columnas verificadas contra el script de esquema de `0bb596c` (`gpos-empresa-20261008150935_Ola4PropinaLegal.sql`): 0 inexistentes. Sin índices nuevos. Nada fiscal (aplazado).
- Fuera: `rptsis` (la API la necesita para arrancar), `imp`, kárdex y ajustes (dependen de I-02), CxC, CxP, bancos, nodos y las reservadas.
- `gpos_reportes` ya tiene `SELECT ON SCHEMA::rpt` y hoy no tiene miembros: aplicar el script no expone nada.

## Preguntas para A (VW-01 a VW-08; detalle en el LEEME)
VW-01 se agregó `rpt.CierreCaja` (L-04) para el reporte 7: ¿se mantiene?; VW-02 ¿cuándo entran el kárdex y el índice I-02?; VW-03 ¿`rpt.Recibo` va con ventas o con CxC?; VW-04 ¿costo de la línea o de `inv.Movimiento` (ingredientes con varios movimientos) y siempre en moneda base?; VW-05 ¿dónde vive el contrato al unir y quién lo valida?; VW-06 huella SHA-256 del JSON con LF, ¿confirmado?; VW-07 ¿la búsqueda tolerante por número va sobre la vista o en la principal?; VW-08 ¿quién construye `rptsis`?
