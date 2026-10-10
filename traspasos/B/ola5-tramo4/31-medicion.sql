/* Medición (7.1, punto 11): forma del diseñador (WITH gpos_base AS (...) ... OFFSET/FETCH 500; totales aparte), parámetros tipados. */
SET NOCOUNT ON;
DECLARE @t0 datetime2(7), @ms int;
DECLARE @r TABLE (Caso varchar(80), Pasada int, Ms int);
DECLARE @p int = 1;
WHILE @p <= 3
BEGIN
  -- M1: antigüedad CxC (8), página ordenada por NombreCliente
  SET @t0 = SYSDATETIME();
  EXEC sys.sp_executesql N'WITH gpos_base AS (
SELECT x.ClienteCodigo AS Cliente, x.ClienteNombre AS NombreCliente, x.Numero AS Documento, x.TipoCodigo AS Tipo, x.Fecha, x.FechaVencimiento AS Vence, a.Dias,
       x.MonedaCodigo AS Moneda, x.Balance, x.BalanceBase,
       CASE WHEN a.Dias <= 0 THEN x.BalanceBase ELSE 0 END AS Corriente, CASE WHEN a.Dias > 90 THEN x.BalanceBase ELSE 0 END AS Mas90,
       x.SucursalCodigo AS Sucursal, su.Descripcion AS NombreSucursal
  FROM rpt.CxcDocumento x JOIN rpt.CatSucursal su ON su.Id = x.SucursalId
  CROSS APPLY (SELECT DATEDIFF(DAY, x.FechaVencimiento, CONVERT(date, DATEADD(HOUR, -4, SYSUTCDATETIME()))) AS Dias) a
 WHERE x.Estado = 1 AND x.Balance > 0)
SELECT * INTO #m1 FROM (SELECT r.* FROM gpos_base r ORDER BY r.NombreCliente, r.Documento OFFSET @s ROWS FETCH NEXT @n ROWS ONLY) q;', N'@s int, @n int', 0, 500;
  INSERT @r VALUES ('M1 CxC antigüedad, página 500 (5.000 con saldo de 200.000)', @p, DATEDIFF(MILLISECOND, @t0, SYSDATETIME()));
  -- M2: totales de la antigüedad CxC (D-05)
  SET @t0 = SYSDATETIME();
  EXEC sys.sp_executesql N'DECLARE @a decimal(38,2), @b decimal(38,2), @c bigint;
SELECT @a = SUM(x.BalanceBase), @b = SUM(CASE WHEN x.FechaVencimiento < CONVERT(date, DATEADD(HOUR, -4, SYSUTCDATETIME())) THEN x.BalanceBase ELSE 0 END), @c = COUNT_BIG(*)
  FROM rpt.CxcDocumento x WHERE x.Estado = 1 AND x.Balance > 0;';
  INSERT @r VALUES ('M2 CxC totales en moneda base = tarjeta de CxC', @p, DATEDIFF(MILLISECOND, @t0, SYSDATETIME()));
  -- M3: estado de cuenta (10), cliente obligatorio
  SET @t0 = SYSDATETIME();
  EXEC sys.sp_executesql N'SELECT * INTO #m3 FROM rpt.CxcDocumento x WHERE x.Estado = 1 AND x.Balance > 0 AND x.ClienteCodigo = @cli;', N'@cli varchar(20)', 'VC00041';
  INSERT @r VALUES ('M3 CxC estado de cuenta de un cliente', @p, DATEDIFF(MILLISECOND, @t0, SYSDATETIME()));
  -- M4: antigüedad CxP (15) totales
  SET @t0 = SYSDATETIME();
  EXEC sys.sp_executesql N'DECLARE @a decimal(38,2), @c bigint; SELECT @a = SUM(x.BalanceBase), @c = COUNT_BIG(*) FROM rpt.CxpDocumento x WHERE x.Estado = 1 AND x.Balance > 0;';
  INSERT @r VALUES ('M4 CxP totales en moneda base (5.000 con saldo de 200.000)', @p, DATEDIFF(MILLISECOND, @t0, SYSDATETIME()));
  -- M5: compras de un mes (13), página y totales
  SET @t0 = SYSDATETIME();
  EXEC sys.sp_executesql N'DECLARE @a decimal(38,2), @c bigint; SELECT @a = SUM(c.TotalBase), @c = COUNT_BIG(*) FROM rpt.Compra c WHERE c.TipoCodigo = ''FCP'' AND c.Estado = 1 AND c.Fecha >= @d AND c.Fecha < @h;',
       N'@d date, @h date', '2026-09-01', '2026-10-01';
  INSERT @r VALUES ('M5 compras FCP de un mes, totales (≈16.000 de 200.000)', @p, DATEDIFF(MILLISECOND, @t0, SYSDATETIME()));
  -- M6: movimientos de caja de un mes y una caja (23), página
  SET @t0 = SYSDATETIME();
  EXEC sys.sp_executesql N'SELECT * INTO #m6 FROM (SELECT m.* FROM rpt.MovimientoCaja m WHERE m.Fecha >= @d AND m.Fecha < @h AND m.CajaCodigo = @caja
  ORDER BY m.Fecha, m.RegistradoEn, m.MovimientoId OFFSET 0 ROWS FETCH NEXT 500 ROWS ONLY) q;', N'@d date, @h date, @caja varchar(30)', '2026-09-01', '2026-10-01', 'VCAJA07';
  INSERT @r VALUES ('M6 mov. de caja, mes y una caja, página 500 (100.000)', @p, DATEDIFF(MILLISECOND, @t0, SYSDATETIME()));
  -- M7: totales del mes y una caja
  SET @t0 = SYSDATETIME();
  EXEC sys.sp_executesql N'DECLARE @a decimal(38,2), @c bigint; SELECT @a = SUM(m.MontoBase), @c = COUNT_BIG(*) FROM rpt.MovimientoCaja m WHERE m.Fecha >= @d AND m.Fecha < @h AND m.CajaCodigo = @caja;',
       N'@d date, @h date, @caja varchar(30)', '2026-09-01', '2026-10-01', 'VCAJA07';
  INSERT @r VALUES ('M7 mov. de caja, mes y una caja, totales (100.000)', @p, DATEDIFF(MILLISECOND, @t0, SYSDATETIME()));
  -- M8: totales del mes sin caja (2.000.000)
  SET @t0 = SYSDATETIME();
  EXEC sys.sp_executesql N'DECLARE @a decimal(38,2), @c bigint; SELECT @a = SUM(m.MontoBase), @c = COUNT_BIG(*) FROM rpt.MovimientoCaja m WHERE m.Fecha >= @d AND m.Fecha < @h;',
       N'@d date, @h date', '2026-09-01', '2026-10-01';
  INSERT @r VALUES ('M8 mov. de caja, mes sin caja, totales (2.000.000)', @p, DATEDIFF(MILLISECOND, @t0, SYSDATETIME()));
  -- M9: un día y una caja (uso típico)
  SET @t0 = SYSDATETIME();
  EXEC sys.sp_executesql N'DECLARE @a decimal(38,2), @c bigint; SELECT @a = SUM(m.MontoBase), @c = COUNT_BIG(*) FROM rpt.MovimientoCaja m WHERE m.Fecha >= @d AND m.Fecha < @h AND m.CajaCodigo = @caja;',
       N'@d date, @h date, @caja varchar(30)', '2026-09-15', '2026-09-16', 'VCAJA07';
  INSERT @r VALUES ('M9 mov. de caja, un día y una caja, totales (3.334)', @p, DATEDIFF(MILLISECOND, @t0, SYSDATETIME()));
  SET @p += 1;
END;
SELECT Caso, MIN(Ms) AS MinMs, MAX(Ms) AS MaxMs, MAX(CASE WHEN Pasada = 1 THEN Ms END) AS PrimeraMs FROM @r GROUP BY Caso ORDER BY Caso;
