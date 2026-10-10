/* Volumen del cliente grande para la medición (SOLO base temporal GPOS_TEST_*; disparadores desactivados mientras se siembra):
   - CxC: 200.000 cuentas (FAC a crédito con ventas.Venta), 5.000 con saldo, 5.000 clientes, 10 % en US$.
   - CxP: 200.000 compras FCP con cxp.Cuenta, 5.000 con saldo, 1.000 suplidores.
   - Caja: 20 cajas × 30 días (septiembre de 2026) = 600 jornadas y 2.000.000 de movimientos (100.000 por caja en el mes). */
SET NOCOUNT ON; SET XACT_ABORT ON;
IF DB_NAME() NOT LIKE 'GPOS[_]TEST[_]%' THROW 50000, N'Solo en bases GPOS_TEST_*', 1;
DECLARE @sql nvarchar(max) = N'';
SELECT @sql += N'ALTER TABLE ' + QUOTENAME(OBJECT_SCHEMA_NAME(t.parent_id)) + N'.' + QUOTENAME(OBJECT_NAME(t.parent_id)) + N' DISABLE TRIGGER ALL;' + NCHAR(10)
  FROM (SELECT DISTINCT parent_id FROM sys.triggers WHERE parent_class = 1) t;
EXEC sys.sp_executesql @sql;
DECLARE @serie int = (SELECT MIN(Id) FROM num.Serie WHERE Clase = 'DOC');
DECLARE @fac tinyint = (SELECT Id FROM doc.TipoDocumento WHERE Codigo = 'FAC'), @fcp tinyint = (SELECT Id FROM doc.TipoDocumento WHERE Codigo = 'FCP'),
        @ap tinyint = (SELECT Id FROM doc.TipoDocumento WHERE Codigo = 'AP');

;WITH n AS (SELECT TOP (1000000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i FROM sys.all_columns a CROSS JOIN sys.all_columns b)
SELECT i INTO #n FROM n;
CREATE UNIQUE CLUSTERED INDEX cx ON #n (i);

-- Maestros
INSERT cat.Cliente (Codigo, RazonSocial, TipoIdentificacion, Identificacion, CreadoPor, ModificadoPor, Prospecto, AplicaImpuesto, Inhabilitado)
SELECT 'VC' + RIGHT('00000' + CONVERT(varchar, i), 5), 'Cliente volumen ' + CONVERT(varchar, i), 'C', RIGHT('00000000000' + CONVERT(varchar, 20000000000 + i), 11), 'P', 'P', 0, 1, 0
  FROM #n WHERE i <= 5000;
INSERT cat.Suplidor (Codigo, RazonSocial, TipoIdentificacion, Identificacion, CreadoPor, ModificadoPor, RetieneItbis, RetieneIsr, AplicaImpuesto, Inhabilitado)
SELECT 'VS' + RIGHT('0000' + CONVERT(varchar, i), 4), 'Suplidor volumen ' + CONVERT(varchar, i), 'R', CONVERT(varchar, 140000000 + i), 'P', 'P', 0, 0, 1, 0
  FROM #n WHERE i <= 1000;
INSERT org.Caja (Codigo, Nombre, SucursalId, AlmacenId, PuntoEmisionId, MonedaId, CobroMultimoneda, Inhabilitado)
SELECT 'VCAJA' + RIGHT('00' + CONVERT(varchar, i), 2), 'Caja volumen ' + CONVERT(varchar, i), c.SucursalId, c.AlmacenId, c.PuntoEmisionId, c.MonedaId, 0, 0
  FROM #n CROSS JOIN (SELECT TOP (1) * FROM org.Caja ORDER BY Id) c WHERE i <= 20;
SELECT Id, ROW_NUMBER() OVER (ORDER BY Id) AS k INTO #cli FROM cat.Cliente WHERE Codigo LIKE 'VC%';
SELECT Id, ROW_NUMBER() OVER (ORDER BY Id) AS k INTO #sup FROM cat.Suplidor WHERE Codigo LIKE 'VS%';
SELECT Id, ROW_NUMBER() OVER (ORDER BY Id) AS k INTO #caja FROM org.Caja WHERE Codigo LIKE 'VCAJA%';

-- CxC: 200.000 facturas a crédito entre 2025-10-01 y 2026-10-09
BEGIN TRANSACTION;
SELECT i, NEXT VALUE FOR doc.SecDocumento AS Id INTO #dc FROM #n WHERE i <= 200000;
INSERT doc.Documento (Id, TipoDocumentoId, Origen, SerieId, Numero, Fecha, SucursalId, Estado, Uid, CreadoPor, EmitidoEn)
SELECT x.Id, @fac, 'N', @serie, 'VF' + RIGHT('00000000' + CONVERT(varchar, x.i), 8), DATEADD(DAY, x.i % 374, '2025-10-01'), 1, 1, NEWID(), 'VOL',
       DATEADD(HOUR, 14, CONVERT(datetime2(3), DATEADD(DAY, x.i % 374, '2025-10-01')))
  FROM #dc x;
INSERT ventas.Venta (DocumentoId, ClienteId, NombreCliente, MonedaId, Tasa, SubTotal, Impuesto, Total, FechaVencimiento)
SELECT x.Id, c.Id, 'Cliente volumen', CASE WHEN x.i % 10 = 0 THEN 2 ELSE 1 END, CASE WHEN x.i % 10 = 0 THEN 59.25 ELSE 1 END,
       1000 + x.i % 5000, 0, 1000 + x.i % 5000, DATEADD(DAY, 30 + x.i % 374, '2025-10-01')
  FROM #dc x JOIN #cli c ON c.k = 1 + x.i % 5000;
INSERT cxc.Cuenta (DocumentoId, ClienteId, FechaVencimiento, MonedaId, Monto, SaldoPendiente, Tasa)
SELECT v.DocumentoId, v.ClienteId, v.FechaVencimiento, v.MonedaId, v.Total, CASE WHEN x.i % 40 = 0 THEN v.Total / 2 ELSE 0 END, v.Tasa
  FROM #dc x JOIN ventas.Venta v ON v.DocumentoId = x.Id;
COMMIT;

-- CxP: 200.000 FCP
BEGIN TRANSACTION;
SELECT i, NEXT VALUE FOR doc.SecDocumento AS Id INTO #dp FROM #n WHERE i <= 200000;
INSERT doc.Documento (Id, TipoDocumentoId, Origen, SerieId, Numero, Fecha, SucursalId, Estado, Uid, CreadoPor, EmitidoEn)
SELECT x.Id, @fcp, 'N', @serie, 'VP' + RIGHT('00000000' + CONVERT(varchar, x.i), 8), DATEADD(DAY, x.i % 374, '2025-10-01'), 1, 1, NEWID(), 'VOL',
       DATEADD(HOUR, 14, CONVERT(datetime2(3), DATEADD(DAY, x.i % 374, '2025-10-01')))
  FROM #dp x;
INSERT compras.Compra (DocumentoId, SuplidorId, AlmacenId, TerminoId, FechaVencimiento, MonedaId, Tasa, NumeroSuplidor, SubTotal, Descuento, Impuesto, Total)
SELECT x.Id, s.Id, 1, NULL, DATEADD(DAY, 30 + x.i % 374, '2025-10-01'), CASE WHEN x.i % 10 = 0 THEN 2 ELSE 1 END, CASE WHEN x.i % 10 = 0 THEN 59.25 ELSE 1 END,
       'S-' + CONVERT(varchar, x.i), 1000 + x.i % 5000, 0, 0, 1000 + x.i % 5000
  FROM #dp x JOIN #sup s ON s.k = 1 + x.i % 1000;
INSERT cxp.Cuenta (DocumentoId, SuplidorId, FechaVencimiento, MonedaId, Tasa, Monto, SaldoPendiente)
SELECT c.DocumentoId, c.SuplidorId, c.FechaVencimiento, c.MonedaId, c.Tasa, c.Total, CASE WHEN x.i % 40 = 0 THEN c.Total / 2 ELSE 0 END
  FROM #dp x JOIN compras.Compra c ON c.DocumentoId = x.Id;
COMMIT;

-- Caja: 600 jornadas de septiembre de 2026 y 2.000.000 de movimientos
BEGIN TRANSACTION;
SELECT ROW_NUMBER() OVER (ORDER BY c.k, d.i) AS j, c.Id AS CajaId, DATEADD(DAY, d.i - 1, '2026-09-01') AS Fecha, NEXT VALUE FOR doc.SecDocumento AS DocId
  INTO #jo FROM #caja c CROSS JOIN (SELECT i FROM #n WHERE i <= 30) d;
INSERT doc.Documento (Id, TipoDocumentoId, Origen, SerieId, Numero, Fecha, SucursalId, Estado, Uid, CreadoPor, EmitidoEn)
SELECT DocId, @ap, 'N', @serie, 'VAP' + RIGHT('0000000' + CONVERT(varchar, j), 7), Fecha, 1, 1, NEWID(), 'VOL', DATEADD(HOUR, 12, CONVERT(datetime2(3), Fecha)) FROM #jo;
INSERT caja.Jornada (DocumentoAperturaId, CajaId, SucursalId, Cajero, FechaOperacion, AbiertaEn, MontoApertura, Estado, CerradaEn)
SELECT DocId, CajaId, 1, 'CAJ' + CONVERT(varchar, CajaId), Fecha, DATEADD(HOUR, 12, CONVERT(datetime2(0), Fecha)), 1000, 'C', DATEADD(HOUR, 30, CONVERT(datetime2(0), Fecha)) FROM #jo;
SELECT ROW_NUMBER() OVER (ORDER BY j.Id) AS r, j.Id, j.FechaOperacion INTO #jid FROM caja.Jornada j JOIN #jo o ON o.DocId = j.DocumentoAperturaId;
INSERT caja.Movimiento (JornadaId, SucursalId, Tipo, DocumentoId, MonedaId, Tasa, Monto, Motivo, Usuario, RegistradoEn)
SELECT j.Id, 1, CASE WHEN n.i % 3334 = 0 THEN 'CIERRE' WHEN n.i % 50 = 0 THEN 'GASTO' ELSE 'VENTA' END, NULL,
       CASE WHEN n.i % 20 = 0 THEN 2 ELSE 1 END, CASE WHEN n.i % 20 = 0 THEN 59.25 ELSE 1 END,
       CASE WHEN n.i % 3334 = 0 THEN -5000 WHEN n.i % 50 = 0 THEN -150 ELSE 100 + n.i % 900 END, NULL, 'CAJERO',
       DATEADD(SECOND, 16 * 3600 + n.i % 36000, CONVERT(datetime2(0), j.FechaOperacion))
  FROM #jid j CROSS JOIN (SELECT i FROM #n WHERE i <= 3334) n
 WHERE (j.r - 1) * 3334 + n.i <= 2000000;
COMMIT;

SET @sql = REPLACE(@sql, N'DISABLE TRIGGER', N'ENABLE TRIGGER');
EXEC sys.sp_executesql @sql;
UPDATE STATISTICS cxc.Cuenta WITH FULLSCAN; UPDATE STATISTICS cxp.Cuenta WITH FULLSCAN; UPDATE STATISTICS caja.Movimiento WITH FULLSCAN;
UPDATE STATISTICS caja.Jornada WITH FULLSCAN; UPDATE STATISTICS doc.Documento WITH FULLSCAN; UPDATE STATISTICS compras.Compra WITH FULLSCAN;
SELECT (SELECT COUNT(*) FROM cxc.Cuenta) cxc, (SELECT COUNT(*) FROM cxc.Cuenta WHERE SaldoPendiente > 0) cxc_saldo, (SELECT COUNT(*) FROM cxp.Cuenta) cxp,
       (SELECT COUNT(*) FROM caja.Movimiento) mov, (SELECT COUNT(*) FROM caja.Jornada) jor;
