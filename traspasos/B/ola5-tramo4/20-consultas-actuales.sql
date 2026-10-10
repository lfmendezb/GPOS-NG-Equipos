SET NOCOUNT ON;
PRINT '== A1 SaldosCxc (reportes 8, 9, 10, 27)';
SELECT v.IdCliente AS Cliente, c.RazonSocial AS NombreCliente, v.Numero AS Documento, v.Tipo, v.FechaDoc AS Fecha,
       v.FechaVencimiento AS Vence, v.DiasVencido AS Dias, v.MontoTotal AS Monto, v.Aplicado, v.Balance,
       CASE WHEN ISNULL(v.DiasVencido, 0) <= 0 THEN v.Balance ELSE 0 END AS Corriente,
       CASE WHEN v.DiasVencido BETWEEN 1 AND 30 THEN v.Balance ELSE 0 END AS De1a30,
       CASE WHEN v.DiasVencido BETWEEN 31 AND 60 THEN v.Balance ELSE 0 END AS De31a60,
       CASE WHEN v.DiasVencido BETWEEN 61 AND 90 THEN v.Balance ELSE 0 END AS De61a90,
       CASE WHEN v.DiasVencido > 90 THEN v.Balance ELSE 0 END AS Mas90,
       CASE WHEN ISNULL(v.DiasVencido, 0) <= 0 THEN '1. Corriente' WHEN v.DiasVencido <= 30 THEN '2. 1-30 días'
            WHEN v.DiasVencido <= 60 THEN '3. 31-60 días' WHEN v.DiasVencido <= 90 THEN '4. 61-90 días' ELSE '5. Más de 90 días' END AS Rango,
       v.IdSucursal AS Sucursal, ISNULL(su.Descripcion, '(sin sucursal)') AS NombreSucursal,
       v.IdMoneda AS Moneda, c.IdVendedor AS Vendedor, c.IdZona AS Zona
  FROM vw_GPost_DocumentosCxC v
  LEFT JOIN Clientes c ON c.ID = v.IdCliente
  LEFT JOIN Sucursales su ON su.Id = v.IdSucursal
 WHERE v.Balance > 0
ORDER BY Documento;
PRINT '== A2 Compras (13, 14)';
SELECT d.Numero AS Factura, d.Fecha, s.Codigo AS Suplidor, s.RazonSocial AS NombreSuplidor, c.NumeroSuplidor AS FacturaSuplidor,
       COALESCE(r.Ncf, fc.Ncf) AS NCF, tg.Codigo AS TipoGasto, mo.Codigo AS Moneda, c.SubTotal, c.Descuento, c.Impuesto AS Itbis, c.Total,
       su.Codigo AS Sucursal, ISNULL(su.Nombre, '(sin sucursal)') AS NombreSucursal, al.Codigo AS Almacen, te.Codigo AS Termino, c.Tasa
  FROM compras.Compra c
  JOIN doc.Documento d ON d.Id = c.DocumentoId AND d.Estado = 1
  JOIN doc.TipoDocumento t ON t.Id = d.TipoDocumentoId AND t.Codigo = 'FCP'
  JOIN cat.Suplidor s ON s.Id = c.SuplidorId
  JOIN cat.Moneda mo ON mo.Id = c.MonedaId
  LEFT JOIN cat.TipoGasto tg ON tg.Id = c.TipoGastoId
  LEFT JOIN org.Almacen al ON al.Id = c.AlmacenId
  LEFT JOIN cat.Termino te ON te.Id = c.TerminoId
  LEFT JOIN fiscal.Registro606 r ON r.DocumentoId = c.DocumentoId
  LEFT JOIN org.Sucursal su ON su.Id = d.SucursalId
  OUTER APPLY (SELECT TOP (1) k.Ncf FROM fiscal.Comprobante k WHERE k.DocumentoId = c.DocumentoId) fc
ORDER BY Factura;
PRINT '== A3 SaldosCxp (15)';
SELECT s.Codigo AS Suplidor, s.RazonSocial AS NombreSuplidor, d.Numero AS Documento, c.NumeroSuplidor AS FacturaSuplidor, r.Ncf AS NCF,
       d.Fecha, p.FechaVencimiento AS Vence, x.Dias, p.Monto, p.Monto - p.SaldoPendiente AS Aplicado, p.SaldoPendiente AS Balance,
       CASE WHEN x.Dias <= 0 THEN p.SaldoPendiente ELSE 0 END AS Corriente,
       CASE WHEN x.Dias BETWEEN 1 AND 30 THEN p.SaldoPendiente ELSE 0 END AS De1a30,
       CASE WHEN x.Dias BETWEEN 31 AND 60 THEN p.SaldoPendiente ELSE 0 END AS De31a60,
       CASE WHEN x.Dias BETWEEN 61 AND 90 THEN p.SaldoPendiente ELSE 0 END AS De61a90,
       CASE WHEN x.Dias > 90 THEN p.SaldoPendiente ELSE 0 END AS Mas90,
       su.Codigo AS Sucursal, ISNULL(su.Nombre, '(sin sucursal)') AS NombreSucursal, mo.Codigo AS Moneda
  FROM cxp.Cuenta p
  JOIN doc.Documento d ON d.Id = p.DocumentoId AND d.Estado = 1
  JOIN cat.Suplidor s ON s.Id = p.SuplidorId
  JOIN cat.Moneda mo ON mo.Id = p.MonedaId
  LEFT JOIN compras.Compra c ON c.DocumentoId = p.DocumentoId
  LEFT JOIN fiscal.Registro606 r ON r.DocumentoId = p.DocumentoId
  LEFT JOIN org.Sucursal su ON su.Id = d.SucursalId
  CROSS APPLY (SELECT DATEDIFF(DAY, p.FechaVencimiento, CONVERT(date, DATEADD(HOUR, -4, SYSUTCDATETIME()))) AS Dias) x
 WHERE p.SaldoPendiente > 0
ORDER BY Documento;
PRINT '== A4 DocsBancarios (21)';
SELECT d.Numero, d.Fecha,
       CASE b.Clase WHEN 'DEP' THEN 'Depósito' WHEN 'TRB' THEN 'Transferencia' WHEN 'CRB' THEN 'Crédito bancario'
                    WHEN 'DBA' THEN 'Débito bancario' WHEN 'SIN' THEN 'Saldo inicial' ELSE 'Cheque' END AS Tipo,
       cb.Codigo AS Cuenta, COALESCE(CONVERT(varchar(20), b.NumeroCheque), b.Referencia) AS Referencia, s.Codigo AS Suplidor, b.Beneficiario,
       b.Concepto, mo.Codigo AS Moneda, b.Monto,
       su.Codigo AS Sucursal, ISNULL(su.Nombre, '(sin sucursal)') AS NombreSucursal
  FROM banco.DocBanco b
  JOIN doc.Documento d ON d.Id = b.DocumentoId
  JOIN banco.CuentaBancaria cb ON cb.Id = b.CuentaBancariaId
  JOIN cat.Moneda mo ON mo.Id = b.MonedaId
  LEFT JOIN cat.Suplidor s ON s.Id = b.SuplidorId
  LEFT JOIN org.Sucursal su ON su.Id = d.SucursalId
 WHERE d.Estado = 1
ORDER BY d.Numero;
PRINT '== A5 Pagos (16)';
SELECT d.Numero, d.Fecha,
       CASE b.Clase WHEN 'DEP' THEN 'Depósito' WHEN 'TRB' THEN 'Transferencia' WHEN 'CRB' THEN 'Crédito bancario'
                    WHEN 'DBA' THEN 'Débito bancario' WHEN 'SIN' THEN 'Saldo inicial' ELSE 'Cheque' END AS Tipo,
       cb.Codigo AS Cuenta, COALESCE(CONVERT(varchar(20), b.NumeroCheque), b.Referencia) AS Referencia, s.Codigo AS Suplidor, b.Beneficiario,
       b.Concepto, mo.Codigo AS Moneda, b.Monto,
       su.Codigo AS Sucursal, ISNULL(su.Nombre, '(sin sucursal)') AS NombreSucursal
  FROM banco.DocBanco b
  JOIN doc.Documento d ON d.Id = b.DocumentoId
  JOIN banco.CuentaBancaria cb ON cb.Id = b.CuentaBancariaId
  JOIN cat.Moneda mo ON mo.Id = b.MonedaId
  LEFT JOIN cat.Suplidor s ON s.Id = b.SuplidorId
  LEFT JOIN org.Sucursal su ON su.Id = d.SucursalId
 WHERE b.SuplidorId IS NOT NULL AND d.Estado = 1
ORDER BY d.Numero;
PRINT '== A6 CajaChica (22)';
SELECT d.Numero, d.Fecha, k.Codigo AS Caja, g.Beneficiario, g.RncCedula AS RNC, g.Concepto, COALESCE(r.Ncf, fc.Ncf) AS NCF,
       tg.Codigo AS TipoGasto, g.Monto, g.Itbis,
       su.Codigo AS Sucursal, ISNULL(su.Nombre, '(sin sucursal)') AS NombreSucursal
  FROM caja.CajaChica g
  JOIN doc.Documento d ON d.Id = g.DocumentoId AND d.Estado = 1
  JOIN org.Caja k ON k.Id = g.CajaId
  LEFT JOIN cat.TipoGasto tg ON tg.Id = g.TipoGastoId
  LEFT JOIN fiscal.Registro606 r ON r.DocumentoId = g.DocumentoId
  LEFT JOIN org.Sucursal su ON su.Id = d.SucursalId
  OUTER APPLY (SELECT TOP (1) x.Ncf FROM fiscal.Comprobante x WHERE x.DocumentoId = g.DocumentoId) fc
ORDER BY d.Numero;
PRINT '== A7 MovCaja (23)';
SELECT TRY_CAST(m.Fechamov AS date) AS Fecha, m.Hora, m.CodCaja AS Caja, m.TipoDocorigen AS Origen, m.Numdocorigen AS Documento,
       m.Turno AS Cajero, ISNULL(m.Debito, 0) AS Ingreso, ISNULL(m.Credito, 0) AS Egreso,
       m.IdSucursal AS Sucursal, ISNULL(su.Descripcion, '(sin sucursal)') AS NombreSucursal
  FROM Mov_Cajas m
  LEFT JOIN Sucursales su ON su.Id = m.IdSucursal
ORDER BY Fecha, Hora;
