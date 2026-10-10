/* SQL del diseñador propuesto para los 11 reportes de la lista P-2 (solo rpt.*; lo ejecuta gpos_rpt en la API de reportes).
   Cada bloque N* es la consulta de la definición; el motor del diseñador le aplica columnas, agregación y filtros. */
SET NOCOUNT ON;
PRINT '== N1 SaldosCxcRpt (8 CXC-ANTIGUEDAD, 9 CXC-ANTIGUEDAD-RESUMEN, 10 CXC-ESTADO-CUENTA, 27 DASH-CXC-ANTIGUEDAD)';
SELECT x.ClienteCodigo AS Cliente, x.ClienteNombre AS NombreCliente, x.Numero AS Documento, x.TipoCodigo AS Tipo, x.Fecha,
       x.FechaVencimiento AS Vence, a.Dias, x.MonedaCodigo AS Moneda, x.Tasa, x.Monto, x.Aplicado, x.Balance, x.BalanceBase,
       CASE WHEN a.Dias <= 0 THEN x.BalanceBase ELSE 0 END AS Corriente,
       CASE WHEN a.Dias BETWEEN 1 AND 30 THEN x.BalanceBase ELSE 0 END AS De1a30,
       CASE WHEN a.Dias BETWEEN 31 AND 60 THEN x.BalanceBase ELSE 0 END AS De31a60,
       CASE WHEN a.Dias BETWEEN 61 AND 90 THEN x.BalanceBase ELSE 0 END AS De61a90,
       CASE WHEN a.Dias > 90 THEN x.BalanceBase ELSE 0 END AS Mas90,
       CASE WHEN a.Dias <= 0 THEN '1. Corriente' WHEN a.Dias <= 30 THEN '2. 1-30 días' WHEN a.Dias <= 60 THEN '3. 31-60 días'
            WHEN a.Dias <= 90 THEN '4. 61-90 días' ELSE '5. Más de 90 días' END AS Rango,
       x.SucursalCodigo AS Sucursal, su.Descripcion AS NombreSucursal, x.VendedorCodigo AS Vendedor, x.ZonaCodigo AS Zona, x.Ncf AS NCF
  FROM rpt.CxcDocumento x
  JOIN rpt.CatSucursal su ON su.Id = x.SucursalId
  CROSS APPLY (SELECT DATEDIFF(DAY, x.FechaVencimiento, CONVERT(date, DATEADD(HOUR, -4, SYSUTCDATETIME()))) AS Dias) a
 WHERE x.Estado = 1 AND x.Balance > 0
ORDER BY Documento;

PRINT '== N2 ComprasRpt (13 CXP-FACTURAS, 14 CXP-POR-SUPLIDOR)';
SELECT c.Numero AS Factura, c.Fecha, c.SuplidorCodigo AS Suplidor, c.SuplidorNombre AS NombreSuplidor, c.FacturaSuplidor, c.Ncf AS NCF,
       c.TipoGastoCodigo AS TipoGasto, c.MonedaCodigo AS Moneda, c.SubTotal, c.Descuento, c.Impuesto AS Itbis, c.Total,
       c.SubTotalBase, c.ImpuestoBase AS ItbisBase, c.TotalBase, c.SucursalCodigo AS Sucursal, su.Descripcion AS NombreSucursal,
       c.AlmacenCodigo AS Almacen, c.TerminoCodigo AS Termino, c.Tasa
  FROM rpt.Compra c
  JOIN rpt.CatSucursal su ON su.Id = c.SucursalId
 WHERE c.TipoCodigo = 'FCP' AND c.Estado = 1
ORDER BY Factura;

PRINT '== N3 SaldosCxpRpt (15 CXP-ANTIGUEDAD)';
SELECT x.SuplidorCodigo AS Suplidor, x.SuplidorNombre AS NombreSuplidor, x.Numero AS Documento, x.FacturaSuplidor, x.Ncf AS NCF, x.Fecha,
       x.FechaVencimiento AS Vence, a.Dias, x.MonedaCodigo AS Moneda, x.Tasa, x.Monto, x.Aplicado, x.Balance, x.BalanceBase,
       CASE WHEN a.Dias <= 0 THEN x.BalanceBase ELSE 0 END AS Corriente,
       CASE WHEN a.Dias BETWEEN 1 AND 30 THEN x.BalanceBase ELSE 0 END AS De1a30,
       CASE WHEN a.Dias BETWEEN 31 AND 60 THEN x.BalanceBase ELSE 0 END AS De31a60,
       CASE WHEN a.Dias BETWEEN 61 AND 90 THEN x.BalanceBase ELSE 0 END AS De61a90,
       CASE WHEN a.Dias > 90 THEN x.BalanceBase ELSE 0 END AS Mas90,
       x.SucursalCodigo AS Sucursal, su.Descripcion AS NombreSucursal
  FROM rpt.CxpDocumento x
  JOIN rpt.CatSucursal su ON su.Id = x.SucursalId
  CROSS APPLY (SELECT DATEDIFF(DAY, x.FechaVencimiento, CONVERT(date, DATEADD(HOUR, -4, SYSUTCDATETIME()))) AS Dias) a
 WHERE x.Estado = 1 AND x.Balance > 0
ORDER BY Documento;

PRINT '== N4 DocsBancariosRpt (21 EF-DOCS-BANCARIOS)';
SELECT b.Numero, b.Fecha,
       CASE b.Clase WHEN 'DEP' THEN 'Depósito' WHEN 'TRB' THEN 'Transferencia' WHEN 'CRB' THEN 'Crédito bancario'
                    WHEN 'DBA' THEN 'Débito bancario' WHEN 'SIN' THEN 'Saldo inicial' ELSE 'Cheque' END AS Tipo,
       b.CuentaCodigo AS Cuenta, COALESCE(CONVERT(varchar(20), b.NumeroCheque), b.Referencia) AS Referencia, b.SuplidorCodigo AS Suplidor,
       b.Beneficiario, b.Concepto, b.MonedaCodigo AS Moneda, b.Monto, b.MontoBase, b.SucursalCodigo AS Sucursal, su.Descripcion AS NombreSucursal
  FROM rpt.DocBanco b
  JOIN rpt.CatSucursal su ON su.Id = b.SucursalId
 WHERE b.Estado = 1
ORDER BY b.Numero;

PRINT '== N5 PagosRpt (16 CXP-PAGOS: la misma consulta con b.SuplidorId IS NOT NULL)';
SELECT b.Numero, b.Fecha,
       CASE b.Clase WHEN 'DEP' THEN 'Depósito' WHEN 'TRB' THEN 'Transferencia' WHEN 'CRB' THEN 'Crédito bancario'
                    WHEN 'DBA' THEN 'Débito bancario' WHEN 'SIN' THEN 'Saldo inicial' ELSE 'Cheque' END AS Tipo,
       b.CuentaCodigo AS Cuenta, COALESCE(CONVERT(varchar(20), b.NumeroCheque), b.Referencia) AS Referencia, b.SuplidorCodigo AS Suplidor,
       b.Beneficiario, b.Concepto, b.MonedaCodigo AS Moneda, b.Monto, b.MontoBase, b.SucursalCodigo AS Sucursal, su.Descripcion AS NombreSucursal
  FROM rpt.DocBanco b
  JOIN rpt.CatSucursal su ON su.Id = b.SucursalId
 WHERE b.SuplidorId IS NOT NULL AND b.Estado = 1
ORDER BY b.Numero;

PRINT '== N6 CajaChicaRpt (22 EF-CAJA-CHICA; Q-2: identificación abreviada)';
SELECT g.Numero, g.Fecha, g.CajaCodigo AS Caja, g.Beneficiario, g.IdentificacionEnmascarada AS RNC, g.Concepto, g.Ncf AS NCF,
       g.TipoGastoCodigo AS TipoGasto, g.MonedaCodigo AS Moneda, g.Monto, g.Itbis, g.MontoBase, g.ItbisBase,
       g.SucursalCodigo AS Sucursal, su.Descripcion AS NombreSucursal
  FROM rpt.CajaChica g
  JOIN rpt.CatSucursal su ON su.Id = g.SucursalId
 WHERE g.Estado = 1
ORDER BY g.Numero;

PRINT '== N7 MovCajaRpt (23 EF-MOV-CAJA; Q-4: sin el monto de las filas de cierre)';
SELECT m.Fecha, CONVERT(varchar(8), m.Hora) AS Hora, m.CajaCodigo AS Caja,
       CASE m.Tipo WHEN 'APERTURA' THEN 'Apertura de caja' WHEN 'VENTA' THEN 'Ventas en efectivo' WHEN 'CAMBIO' THEN 'Ventas en efectivo'
                   WHEN 'DEVOLUCION' THEN 'Devoluciones' WHEN 'COBRO' THEN 'Cobros (recibos)' WHEN 'GASTO' THEN 'Gastos de caja chica'
                   WHEN 'RETIRO' THEN 'Depósitos a banco' WHEN 'CIERRE' THEN 'Retiro por cierre Z' WHEN 'ENTRADA' THEN 'Entrada de efectivo'
                   WHEN 'SALIDA' THEN 'Salida de efectivo' WHEN 'NOVENTA' THEN 'Apertura sin venta'
                   WHEN 'REVERSO' THEN CASE m.TipoRevertido WHEN 'VENTA' THEN 'Ventas anuladas' WHEN 'CAMBIO' THEN 'Ventas anuladas'
                                                            WHEN 'COBRO' THEN 'Recibos anulados' WHEN 'GASTO' THEN 'Caja chica anulada'
                                                            WHEN 'RETIRO' THEN 'Depósitos anulados' WHEN 'CIERRE' THEN 'Cierre Z anulado'
                                                            ELSE 'Anulación' END
                   ELSE m.Tipo END AS Origen,
       COALESCE(m.DocumentoNumero, m.Motivo) AS Documento, m.Cajero, m.MonedaCodigo AS Moneda,
       CASE WHEN m.Monto > 0 THEN m.Monto WHEN m.Monto < 0 THEN 0 END AS Ingreso,
       CASE WHEN m.Monto < 0 THEN -m.Monto WHEN m.Monto > 0 THEN 0 END AS Egreso,
       CASE WHEN m.MontoBase > 0 THEN m.MontoBase WHEN m.MontoBase < 0 THEN 0 END AS IngresoBase,
       CASE WHEN m.MontoBase < 0 THEN -m.MontoBase WHEN m.MontoBase > 0 THEN 0 END AS EgresoBase,
       m.SucursalCodigo AS Sucursal, su.Descripcion AS NombreSucursal, m.Usuario
  FROM rpt.MovimientoCaja m
  JOIN rpt.CatSucursal su ON su.Id = m.SucursalId
ORDER BY m.Fecha, m.RegistradoEn;

PRINT '== N8 Tarjeta de CxC (Q-1: consulta registrada TAB-CXC@1 sobre rpt; @hoy = hoy de la empresa)';
DECLARE @hoy date = CONVERT(date, DATEADD(HOUR, -4, SYSUTCDATETIME()));
SELECT ISNULL(SUM(x.BalanceBase), 0) AS Total, ISNULL(SUM(CASE WHEN x.FechaVencimiento < @hoy THEN x.BalanceBase ELSE 0 END), 0) AS Vencido
  FROM rpt.CxcDocumento x
 WHERE x.Estado = 1 AND x.Balance > 0;
PRINT '== N9 Tarjeta de CxC actual (ConsultasTablero.CuentasPorCobrar: sin tasa, mezcla monedas)';
SELECT ISNULL(SUM(c.SaldoPendiente), 0) AS Total, ISNULL(SUM(CASE WHEN c.FechaVencimiento < @hoy THEN c.SaldoPendiente ELSE 0 END), 0) AS Vencido
  FROM cxc.Cuenta c JOIN doc.Documento d ON d.Id = c.DocumentoId AND d.Estado = 1
 WHERE c.SaldoPendiente > 0;
PRINT '== N10 Q-5: rpt.CierreCajaConteo.Esperado (debe ser NULL) frente a rptc';
SELECT 'rpt' AS v, Numero, Tipo, Esperado FROM rpt.CierreCajaConteo UNION ALL SELECT 'rptc', Numero, Tipo, Esperado FROM rptc.CierreCajaConteo;
PRINT '== N11 Q-4: rptc.MovimientoCaja de las filas de cierre';
SELECT Tipo, TipoRevertido, EsCierre, Monto, MontoCompleto, MontoCompletoBase FROM rptc.MovimientoCaja WHERE EsCierre = 1;
PRINT '== N12 rptc.CajaChica (identificación completa)';
SELECT Numero, IdentificacionEnmascarada, Identificacion FROM rptc.CajaChica;
