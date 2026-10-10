/* Reversión de Ola5VistasTramo4 (Down), en orden inverso: vistas → índices → CHECK → columna. Sin pérdida de datos:
   las vistas no guardan nada, la tasa sigue en ventas.Venta y el contrato vuelve a la 1.2 (las cuatro vistas modificadas
   se reponen con su texto de Ola5VistasVentasInventario; en C#: VistasReportesOla5.Vistas por nombre). */
SET NOCOUNT ON;
GO
DROP VIEW IF EXISTS rpt.CatTermino;
DROP VIEW IF EXISTS rpt.CatTipoGasto;
DROP VIEW IF EXISTS rptc.MovimientoCaja;
DROP VIEW IF EXISTS rpt.MovimientoCaja;
DROP VIEW IF EXISTS rptc.CajaChica;
DROP VIEW IF EXISTS rpt.CajaChica;
DROP VIEW IF EXISTS rpt.DocBanco;
DROP VIEW IF EXISTS rpt.Compra;
DROP VIEW IF EXISTS rpt.CxpDocumento;
DROP VIEW IF EXISTS rpt.CxcDocumento;
GO
CREATE OR ALTER VIEW rpt.CierreCajaConteo AS
SELECT k.DocumentoId,
       d.Numero,
       d.Fecha,
       d.Estado,
       z.Tipo,
       z.Anulado,
       z.JornadaId,
       j.FechaOperacion,
       j.SucursalId,
       z.CajaId,
       j.Cajero,
       k.FormaPagoId,
       f.Codigo                                            AS FormaPagoCodigo,
       f.Clase                                             AS ClaseFormaPago,
       k.MonedaId,
       mo.Codigo                                           AS MonedaCodigo,
       CONVERT(decimal(19, 2), CASE WHEN z.Tipo = 'Z' AND z.Anulado = 0 AND d.Estado = 1 THEN k.Esperado END) AS Esperado
  FROM caja.CierreConteo k
  JOIN caja.Cierre z    ON z.DocumentoId = k.DocumentoId
  JOIN doc.Documento d  ON d.Id = k.DocumentoId AND d.Estado IN (1, 2)
  JOIN caja.Jornada j   ON j.Id = z.JornadaId
  JOIN cat.FormaPago f  ON f.Id = k.FormaPagoId
  JOIN cat.Moneda mo    ON mo.Id = k.MonedaId;
GO
CREATE OR ALTER VIEW rpt.ConsultaFactura AS
SELECT d.Id                                                AS DocumentoId,
       d.Numero,
       t.Codigo                                            AS TipoCodigo,
       d.Fecha,
       d.Estado,
       d.Origen,
       d.SucursalId,
       su.Codigo                                           AS SucursalCodigo,
       d.EmitidoEn,
       CONVERT(date, DATEADD(HOUR, -4, d.EmitidoEn))       AS FechaEmisionLocal,
       d.AnuladoEn,
       CONVERT(date, DATEADD(HOUR, -4, d.AnuladoEn))       AS FechaAnulacionLocal,
       d.CreadoPor,
       d.AnuladoPor,
       d.MotivoAnulacion,
       ma.Codigo                                           AS MotivoAnulacionCodigo,
       v.MonedaId,
       mo.Codigo                                           AS MonedaCodigo,
       v.Tasa,
       v.ClienteId,
       cl.Codigo                                           AS ClienteCodigo,
       v.NombreCliente                                     AS ClienteNombre,
       CONVERT(varchar(20), CASE WHEN idc.Identificacion IS NULL THEN NULL
                                 WHEN idc.Tipo = 'R' THEN idc.Identificacion
                                 ELSE '*******' + RIGHT(idc.Identificacion, 4) END) AS IdentificacionClienteEnmascarada,
       d.NumeroInv,
       v.Total,
       v.TotalBase,
       CONVERT(decimal(19, 2), CASE WHEN d.Estado = 1 AND t.Codigo = 'FAC' THEN ISNULL(cu.SaldoPendiente, 0) ELSE 0 END) AS Balance,
       COALESCE(v.FechaVencimiento, d.Fecha)               AS FechaVence,
       CONVERT(varchar(50), COALESCE(c.Ncf, CASE WHEN d.Origen = 'I' THEN v.Referencia END)) AS Ncf,
       v.CajaId,
       ca.Codigo                                           AS CajaCodigo,
       v.JornadaId,
       j.Cajero,
       v.VendedorId,
       e.Codigo                                            AS VendedorCodigo,
       CONVERT(varchar(161), e.Nombres + ' ' + e.Apellidos) AS VendedorNombre
  FROM ventas.Venta v
  JOIN doc.Documento d       ON d.Id = v.DocumentoId AND d.Estado IN (1, 2)
  JOIN doc.TipoDocumento t   ON t.Id = d.TipoDocumentoId AND t.Codigo IN ('FAC', 'FPOS', 'DEV')
  JOIN org.Sucursal su       ON su.Id = d.SucursalId
  JOIN cat.Moneda mo         ON mo.Id = v.MonedaId
  JOIN cat.Cliente cl        ON cl.Id = v.ClienteId
  LEFT JOIN cat.MotivoAnulacion ma ON ma.Id = d.MotivoAnulacionId
  LEFT JOIN cxc.Cuenta cu          ON cu.DocumentoId = d.Id
  LEFT JOIN fiscal.Comprobante c   ON c.DocumentoId = d.Id AND c.Rol = 'O'
  LEFT JOIN org.Caja ca            ON ca.Id = v.CajaId
  LEFT JOIN caja.Jornada j         ON j.Id = v.JornadaId
  LEFT JOIN rrhh.Empleado e        ON e.Id = v.VendedorId
  CROSS APPLY (SELECT CONVERT(varchar(20), COALESCE(v.IdentificacionCliente, cl.Identificacion)) AS Identificacion,
                      CONVERT(char(1), CASE WHEN v.IdentificacionCliente IS NOT NULL THEN v.TipoIdentificacionCliente
                                            ELSE cl.TipoIdentificacion END) AS Tipo) idc;
GO
CREATE OR ALTER VIEW rptc.ConsultaFactura AS
SELECT d.Id                                                AS DocumentoId,
       d.Numero,
       t.Codigo                                            AS TipoCodigo,
       d.Fecha,
       d.Estado,
       d.Origen,
       d.SucursalId,
       su.Codigo                                           AS SucursalCodigo,
       d.EmitidoEn,
       CONVERT(date, DATEADD(HOUR, -4, d.EmitidoEn))       AS FechaEmisionLocal,
       d.AnuladoEn,
       CONVERT(date, DATEADD(HOUR, -4, d.AnuladoEn))       AS FechaAnulacionLocal,
       d.CreadoPor,
       d.AnuladoPor,
       d.MotivoAnulacion,
       ma.Codigo                                           AS MotivoAnulacionCodigo,
       v.MonedaId,
       mo.Codigo                                           AS MonedaCodigo,
       v.Tasa,
       v.ClienteId,
       cl.Codigo                                           AS ClienteCodigo,
       v.NombreCliente                                     AS ClienteNombre,
       CONVERT(varchar(20), CASE WHEN idc.Identificacion IS NULL THEN NULL
                                 WHEN idc.Tipo = 'R' THEN idc.Identificacion
                                 ELSE '*******' + RIGHT(idc.Identificacion, 4) END) AS IdentificacionClienteEnmascarada,
       d.NumeroInv,
       v.Total,
       v.TotalBase,
       CONVERT(decimal(19, 2), CASE WHEN d.Estado = 1 AND t.Codigo = 'FAC' THEN ISNULL(cu.SaldoPendiente, 0) ELSE 0 END) AS Balance,
       COALESCE(v.FechaVencimiento, d.Fecha)               AS FechaVence,
       CONVERT(varchar(50), COALESCE(c.Ncf, CASE WHEN d.Origen = 'I' THEN v.Referencia END)) AS Ncf,
       v.CajaId,
       ca.Codigo                                           AS CajaCodigo,
       v.JornadaId,
       j.Cajero,
       v.VendedorId,
       e.Codigo                                            AS VendedorCodigo,
       CONVERT(varchar(161), e.Nombres + ' ' + e.Apellidos) AS VendedorNombre,
       CONVERT(varchar(20), CASE WHEN idc.Identificacion IS NULL THEN NULL
                                 WHEN idc.Tipo IN ('R', 'C') THEN idc.Identificacion
                                 ELSE '*******' + RIGHT(idc.Identificacion, 4) END) AS IdentificacionCliente
  FROM ventas.Venta v
  JOIN doc.Documento d       ON d.Id = v.DocumentoId AND d.Estado IN (1, 2)
  JOIN doc.TipoDocumento t   ON t.Id = d.TipoDocumentoId AND t.Codigo IN ('FAC', 'FPOS', 'DEV')
  JOIN org.Sucursal su       ON su.Id = d.SucursalId
  JOIN cat.Moneda mo         ON mo.Id = v.MonedaId
  JOIN cat.Cliente cl        ON cl.Id = v.ClienteId
  LEFT JOIN cat.MotivoAnulacion ma ON ma.Id = d.MotivoAnulacionId
  LEFT JOIN cxc.Cuenta cu          ON cu.DocumentoId = d.Id
  LEFT JOIN fiscal.Comprobante c   ON c.DocumentoId = d.Id AND c.Rol = 'O'
  LEFT JOIN org.Caja ca            ON ca.Id = v.CajaId
  LEFT JOIN caja.Jornada j         ON j.Id = v.JornadaId
  LEFT JOIN rrhh.Empleado e        ON e.Id = v.VendedorId
  CROSS APPLY (SELECT CONVERT(varchar(20), COALESCE(v.IdentificacionCliente, cl.Identificacion)) AS Identificacion,
                      CONVERT(char(1), CASE WHEN v.IdentificacionCliente IS NOT NULL THEN v.TipoIdentificacionCliente
                                            ELSE cl.TipoIdentificacion END) AS Tipo) idc;
GO
CREATE OR ALTER VIEW rpt.VersionContrato AS
SELECT CONVERT(smallint, 1) AS Version,
       CONVERT(smallint, 1) AS VersionMinima,
       CONVERT(binary(32), 0x6FFDE39F89D03A7A56626D2A0681F98F04A944BDEA579B073BCEA63CE52D6B2E) AS Huella;
GO
CREATE INDEX IX_CajaMovimiento_Jornada ON caja.Movimiento (JornadaId) INCLUDE (Tipo, MonedaId, Monto) WITH (DROP_EXISTING = ON);
GO
CREATE INDEX IX_Cuenta_ClienteVencimiento ON cxc.Cuenta (ClienteId, FechaVencimiento) INCLUDE (SaldoPendiente, MonedaId)
    WHERE SaldoPendiente > 0 WITH (DROP_EXISTING = ON);
GO
ALTER TABLE cxc.Cuenta DROP CONSTRAINT IF EXISTS CK_Cuenta_Tasa;
GO
ALTER TABLE cxc.Cuenta DROP COLUMN IF EXISTS Tasa;
GO
