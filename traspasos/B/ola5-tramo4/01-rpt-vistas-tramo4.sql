/* =====================================================================================================================
   Ola 5 · Tramo 4 · Vistas rpt/rptc de CxC, CxP, compras, banco, caja chica y movimientos de caja; contrato de vistas 1.3
   Autor: arquitecto-datos, equipo B · 2026-10-10 · PROPUESTA (probada en GPOS_TEST_T4VISTAS, no aplicada a ninguna base real)
   Base: feature/modelo-ng ec459d5 (database/empresa/gpos-empresa-20261010130522_BitacoraLogSoloInsercion.sql) + 00-cxc-cuenta-tasa.sql
   Firmas: ADR-109 (cl. 3, 4, 11; P-2; Q-1 a Q-6 del 2026-10-10), ADR-50, ADR-52 (RB-P1), RS-01 a RS-03.

   Reglas (las del script de la ola 5, sin cambios):
   - CREATE OR ALTER VIEW; dueño dbo; sin nombres de tres partes, sinónimos, SQL dinámico, pistas ni SYSDATETIME/SYSUTCDATETIME
     (la «fecha de hoy» la pone la consulta: por eso NO hay DiasVencido en las vistas de saldos; ver el documento, 2.2).
   - Texto varchar (ADR-50); literales sin N. Montos *Base = ROUND(monto × tasa del documento, 2) por fila (P-4/P-5).
   - SucursalId y SucursalCodigo en toda vista de documento (D-03).
   - rptc.X = columnas de rpt.X en el mismo orden, más las suyas al final (V-10).
   - Toda vista que lee fiscal.Comprobante filtra Rol de forma explícita (guarda de H-2). Rol H (Q-3) solo en la consulta de
     facturas y en la CxC; hasta que H-2 se una, CK_Comprobante_Rol solo admite O y R, así que 'H' no devuelve filas (el texto
     sirve antes y después de H-2).
   - Permisos: los de PermisosLecturaReportes (por esquema): gpos_reportes lee rpt; gpos_lectura lee rpt y rptc. Nada nuevo.
   ===================================================================================================================== */
SET NOCOUNT ON;
GO
-- Falla cerrada: requiere Ola5VistasVentasInventario (rpt/rptc y sus roles) y cxc.Cuenta.Tasa (00-cxc-cuenta-tasa.sql)
IF OBJECT_ID(N'rpt.VersionContrato', N'V') IS NULL OR SCHEMA_ID(N'rptc') IS NULL
   OR NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'cxc.Cuenta') AND name = N'Tasa' AND is_nullable = 0)
BEGIN
    RAISERROR(N'51399: faltan Ola5VistasVentasInventario o cxc.Cuenta.Tasa NOT NULL; no se crea ninguna vista del tramo 4.', 16, 1);
    SET NOEXEC ON;
END;
GO
-- V-R1 (H-01), igual que la ola 5: todo esquema de usuario y sus objetos son de dbo; sin sinónimos en rpt ni rptc
IF EXISTS (SELECT 1 FROM sys.schemas s WHERE (s.schema_id = 1 OR s.schema_id BETWEEN 5 AND 16383) AND s.principal_id <> USER_ID(N'dbo'))
   OR EXISTS (SELECT 1 FROM sys.objects o JOIN sys.schemas s ON s.schema_id = o.schema_id
               WHERE (s.schema_id = 1 OR s.schema_id BETWEEN 5 AND 16383) AND o.principal_id IS NOT NULL AND o.principal_id <> USER_ID(N'dbo'))
   OR EXISTS (SELECT 1 FROM sys.synonyms y WHERE SCHEMA_NAME(y.schema_id) IN (N'rpt', N'rptc'))
BEGIN
    RAISERROR(N'51399 V-R1: un esquema de usuario (o un objeto suyo) no es de dbo, o hay sinónimos en rpt o rptc.', 16, 1);
    SET NOEXEC ON;
END;
GO

/* ---------------------------------------------------------------------------------------------------------------------
   1. Cuentas por cobrar (reportes 8, 9, 10, 27 y tarjeta de CxC). Grano: cxc.Cuenta (FAC a crédito, ND, CHD, factura importada).
      Estado 1 o 2 (el anulado queda con saldo 0). Balance = SaldoPendiente sin transformar, para que «Balance > 0» use el índice
      filtrado IX_Cuenta_ClienteVencimiento. NCF: O o H (Q-3); en la factura importada sin H todavía, ventas.Venta.Referencia (CA-46).
   --------------------------------------------------------------------------------------------------------------------- */
CREATE OR ALTER VIEW rpt.CxcDocumento AS
SELECT c.DocumentoId,
       d.Numero,
       t.Codigo                                                    AS TipoCodigo,
       d.Fecha,
       d.Estado,
       d.Origen,
       d.SucursalId,
       su.Codigo                                                   AS SucursalCodigo,
       c.FechaVencimiento,
       c.ClienteId,
       cl.Codigo                                                   AS ClienteCodigo,
       cl.RazonSocial                                              AS ClienteNombre,
       cl.VendedorId,
       ve.Codigo                                                   AS VendedorCodigo,
       cl.ZonaId,
       zo.Codigo                                                   AS ZonaCodigo,
       c.MonedaId,
       mo.Codigo                                                   AS MonedaCodigo,
       c.Tasa,
       c.Monto,
       CONVERT(decimal(19, 2), c.Monto - c.SaldoPendiente)         AS Aplicado,
       c.SaldoPendiente                                            AS Balance,
       CONVERT(decimal(19, 2), ROUND(c.Monto * c.Tasa, 2))         AS MontoBase,
       CONVERT(decimal(19, 2), ROUND(c.SaldoPendiente * c.Tasa, 2)) AS BalanceBase,
       CONVERT(varchar(50), COALESCE(f.Ncf, CASE WHEN d.Origen = 'I' THEN v.Referencia END)) AS Ncf,
       CONVERT(bit, CASE WHEN f.Rol = 'H' OR (f.Ncf IS NULL AND d.Origen = 'I' AND v.Referencia IS NOT NULL) THEN 1 ELSE 0 END) AS NcfHistorico
  FROM cxc.Cuenta c
  JOIN doc.Documento d       ON d.Id = c.DocumentoId AND d.Estado IN (1, 2)
  JOIN doc.TipoDocumento t   ON t.Id = d.TipoDocumentoId
  JOIN org.Sucursal su       ON su.Id = d.SucursalId
  JOIN cat.Cliente cl        ON cl.Id = c.ClienteId
  JOIN cat.Moneda mo         ON mo.Id = c.MonedaId
  LEFT JOIN ventas.Venta v         ON v.DocumentoId = c.DocumentoId
  LEFT JOIN rrhh.Empleado ve       ON ve.Id = cl.VendedorId
  LEFT JOIN cat.Zona zo            ON zo.Id = cl.ZonaId
  LEFT JOIN fiscal.Comprobante f   ON f.DocumentoId = c.DocumentoId AND f.Rol IN ('O', 'H');
GO

/* ---------------------------------------------------------------------------------------------------------------------
   2. Cuentas por pagar (reporte 15). Grano: cxp.Cuenta (FCP, NDP, CxP importada). NCF: el recibido (fiscal.Registro606) o el que
      emitió la empresa (B11, fiscal.Comprobante rol O), igual que rpt.Compra. La CxP importada no tiene NCF (queda en las notas).
   --------------------------------------------------------------------------------------------------------------------- */
CREATE OR ALTER VIEW rpt.CxpDocumento AS
SELECT p.DocumentoId,
       d.Numero,
       t.Codigo                                                    AS TipoCodigo,
       d.Fecha,
       d.Estado,
       d.Origen,
       d.SucursalId,
       su.Codigo                                                   AS SucursalCodigo,
       p.FechaVencimiento,
       p.SuplidorId,
       s.Codigo                                                    AS SuplidorCodigo,
       s.RazonSocial                                               AS SuplidorNombre,
       co.NumeroSuplidor                                           AS FacturaSuplidor,
       p.MonedaId,
       mo.Codigo                                                   AS MonedaCodigo,
       p.Tasa,
       p.Monto,
       CONVERT(decimal(19, 2), p.Monto - p.SaldoPendiente)         AS Aplicado,
       p.SaldoPendiente                                            AS Balance,
       CONVERT(decimal(19, 2), ROUND(p.Monto * p.Tasa, 2))         AS MontoBase,
       CONVERT(decimal(19, 2), ROUND(p.SaldoPendiente * p.Tasa, 2)) AS BalanceBase,
       CONVERT(varchar(13), COALESCE(r.Ncf, f.Ncf))                AS Ncf
  FROM cxp.Cuenta p
  JOIN doc.Documento d       ON d.Id = p.DocumentoId AND d.Estado IN (1, 2)
  JOIN doc.TipoDocumento t   ON t.Id = d.TipoDocumentoId
  JOIN org.Sucursal su       ON su.Id = d.SucursalId
  JOIN cat.Suplidor s        ON s.Id = p.SuplidorId
  JOIN cat.Moneda mo         ON mo.Id = p.MonedaId
  LEFT JOIN compras.Compra co      ON co.DocumentoId = p.DocumentoId
  LEFT JOIN fiscal.Registro606 r   ON r.DocumentoId = p.DocumentoId
  LEFT JOIN fiscal.Comprobante f   ON f.DocumentoId = p.DocumentoId AND f.Rol = 'O';
GO

/* ---------------------------------------------------------------------------------------------------------------------
   3. Compras (reportes 13 y 14). Grano: documento de compras.Compra de tipo FCP, NDP, NCP o DVS emitido o anulado, con Signo
      (NCP y DVS restan). Los reportes 13 y 14 filtran TipoCodigo = 'FCP' (igual que hoy). Sin costos por artículo (RS-03 no aplica).
   --------------------------------------------------------------------------------------------------------------------- */
CREATE OR ALTER VIEW rpt.Compra AS
SELECT c.DocumentoId,
       d.Numero,
       t.Codigo                                                    AS TipoCodigo,
       d.Fecha,
       d.Estado,
       d.Origen,
       d.SucursalId,
       su.Codigo                                                   AS SucursalCodigo,
       c.SuplidorId,
       s.Codigo                                                    AS SuplidorCodigo,
       s.RazonSocial                                               AS SuplidorNombre,
       c.NumeroSuplidor                                            AS FacturaSuplidor,
       CONVERT(varchar(13), COALESCE(r.Ncf, f.Ncf))                AS Ncf,
       r.NcfModificado,
       c.TipoGastoId,
       tg.Codigo                                                   AS TipoGastoCodigo,
       c.AlmacenId,
       al.Codigo                                                   AS AlmacenCodigo,
       c.TerminoId,
       te.Codigo                                                   AS TerminoCodigo,
       c.FechaVencimiento,
       c.MonedaId,
       mo.Codigo                                                   AS MonedaCodigo,
       c.Tasa,
       CONVERT(smallint, CASE WHEN t.Codigo IN ('NCP', 'DVS') THEN -1 ELSE 1 END) AS Signo,
       c.SubTotal,
       c.Descuento,
       c.Impuesto,
       c.Total,
       CONVERT(decimal(19, 2), ROUND(c.SubTotal * c.Tasa, 2))      AS SubTotalBase,
       CONVERT(decimal(19, 2), ROUND(c.Descuento * c.Tasa, 2))     AS DescuentoBase,
       CONVERT(decimal(19, 2), ROUND(c.Impuesto * c.Tasa, 2))      AS ImpuestoBase,
       CONVERT(decimal(19, 2), ROUND(c.Total * c.Tasa, 2))         AS TotalBase,
       c.DocumentoOrigenId,
       o.Numero                                                    AS NumeroOrigen
  FROM compras.Compra c
  JOIN doc.Documento d       ON d.Id = c.DocumentoId AND d.Estado IN (1, 2)
  JOIN doc.TipoDocumento t   ON t.Id = d.TipoDocumentoId AND t.Codigo IN ('FCP', 'NDP', 'NCP', 'DVS')
  JOIN org.Sucursal su       ON su.Id = d.SucursalId
  JOIN cat.Suplidor s        ON s.Id = c.SuplidorId
  JOIN cat.Moneda mo         ON mo.Id = c.MonedaId
  LEFT JOIN cat.TipoGasto tg       ON tg.Id = c.TipoGastoId
  LEFT JOIN org.Almacen al         ON al.Id = c.AlmacenId
  LEFT JOIN cat.Termino te         ON te.Id = c.TerminoId
  LEFT JOIN fiscal.Registro606 r   ON r.DocumentoId = c.DocumentoId
  LEFT JOIN fiscal.Comprobante f   ON f.DocumentoId = c.DocumentoId AND f.Rol = 'O'
  LEFT JOIN doc.Documento o        ON o.Id = c.DocumentoOrigenId;
GO

/* ---------------------------------------------------------------------------------------------------------------------
   4. Documentos bancarios (reportes 16 y 21). Grano: banco.DocBanco emitido o anulado. Monto positivo con Signo aparte (como la
      tabla); MontoBase = ROUND(Monto × Tasa, 2) (banco.DocBanco.Tasa existe: verificado, NOT NULL, CK_DocBanco_Tasa).
   --------------------------------------------------------------------------------------------------------------------- */
CREATE OR ALTER VIEW rpt.DocBanco AS
SELECT b.DocumentoId,
       d.Numero,
       t.Codigo                                                    AS TipoCodigo,
       b.Clase,
       b.Signo,
       d.Fecha,
       d.Estado,
       d.Origen,
       d.SucursalId,
       su.Codigo                                                   AS SucursalCodigo,
       b.CuentaBancariaId,
       cb.Codigo                                                   AS CuentaCodigo,
       b.NumeroCheque,
       b.Referencia,
       b.SuplidorId,
       s.Codigo                                                    AS SuplidorCodigo,
       b.Beneficiario,
       b.Concepto,
       b.TipoGastoId,
       tg.Codigo                                                   AS TipoGastoCodigo,
       b.MonedaId,
       mo.Codigo                                                   AS MonedaCodigo,
       b.Tasa,
       b.Monto,
       b.MontoDirecto,
       CONVERT(decimal(19, 2), ROUND(b.Monto * b.Tasa, 2))         AS MontoBase,
       b.CajaId,
       ca.Codigo                                                   AS CajaCodigo,
       b.JornadaId,
       b.DocumentoOrigenId,
       o.Numero                                                    AS NumeroOrigen
  FROM banco.DocBanco b
  JOIN doc.Documento d          ON d.Id = b.DocumentoId AND d.Estado IN (1, 2)
  JOIN doc.TipoDocumento t      ON t.Id = d.TipoDocumentoId
  JOIN org.Sucursal su          ON su.Id = d.SucursalId
  JOIN banco.CuentaBancaria cb  ON cb.Id = b.CuentaBancariaId
  JOIN cat.Moneda mo            ON mo.Id = b.MonedaId
  LEFT JOIN cat.Suplidor s         ON s.Id = b.SuplidorId
  LEFT JOIN cat.TipoGasto tg       ON tg.Id = b.TipoGastoId
  LEFT JOIN org.Caja ca            ON ca.Id = b.CajaId
  LEFT JOIN doc.Documento o        ON o.Id = b.DocumentoOrigenId;
GO

/* ---------------------------------------------------------------------------------------------------------------------
   5. Caja chica (reporte 22). Grano: caja.CajaChica emitida o anulada. RS-01 / Q-2: caja.CajaChica.RncCedula no guarda el tipo;
      CK_CajaChica_Rnc garantiza 9 u 11 dígitos, así que el largo ES el tipo (9 = RNC íntegro; 11 = cédula: '*******' + últimos 4).
      rptc: identificación completa (R y C íntegros; no hay pasaporte posible). Q-2 firmada: el reporte 22 usa rpt (siempre abreviada).
   --------------------------------------------------------------------------------------------------------------------- */
CREATE OR ALTER VIEW rpt.CajaChica AS
SELECT g.DocumentoId,
       d.Numero,
       d.Fecha,
       d.Estado,
       d.SucursalId,
       su.Codigo                                                   AS SucursalCodigo,
       g.CajaId,
       ca.Codigo                                                   AS CajaCodigo,
       g.JornadaId,
       j.Cajero,
       g.Beneficiario,
       CONVERT(varchar(11), CASE WHEN g.RncCedula IS NULL THEN NULL
                                 WHEN LEN(g.RncCedula) = 9 THEN g.RncCedula
                                 ELSE '*******' + RIGHT(g.RncCedula, 4) END) AS IdentificacionEnmascarada,
       g.Concepto,
       CONVERT(varchar(13), COALESCE(r.Ncf, f.Ncf))                AS Ncf,
       g.TipoGastoId,
       tg.Codigo                                                   AS TipoGastoCodigo,
       g.MonedaId,
       mo.Codigo                                                   AS MonedaCodigo,
       g.Tasa,
       g.Monto,
       g.Itbis,
       CONVERT(decimal(19, 2), ROUND(g.Monto * g.Tasa, 2))         AS MontoBase,
       CONVERT(decimal(19, 2), ROUND(g.Itbis * g.Tasa, 2))         AS ItbisBase,
       g.PorcRetencionItbis,
       g.PorcRetencionIsr
  FROM caja.CajaChica g
  JOIN doc.Documento d       ON d.Id = g.DocumentoId AND d.Estado IN (1, 2)
  JOIN org.Sucursal su       ON su.Id = d.SucursalId
  JOIN org.Caja ca           ON ca.Id = g.CajaId
  JOIN caja.Jornada j        ON j.Id = g.JornadaId
  JOIN cat.Moneda mo         ON mo.Id = g.MonedaId
  LEFT JOIN cat.TipoGasto tg       ON tg.Id = g.TipoGastoId
  LEFT JOIN fiscal.Registro606 r   ON r.DocumentoId = g.DocumentoId
  LEFT JOIN fiscal.Comprobante f   ON f.DocumentoId = g.DocumentoId AND f.Rol = 'O';
GO
CREATE OR ALTER VIEW rptc.CajaChica AS
SELECT g.DocumentoId,
       d.Numero,
       d.Fecha,
       d.Estado,
       d.SucursalId,
       su.Codigo                                                   AS SucursalCodigo,
       g.CajaId,
       ca.Codigo                                                   AS CajaCodigo,
       g.JornadaId,
       j.Cajero,
       g.Beneficiario,
       CONVERT(varchar(11), CASE WHEN g.RncCedula IS NULL THEN NULL
                                 WHEN LEN(g.RncCedula) = 9 THEN g.RncCedula
                                 ELSE '*******' + RIGHT(g.RncCedula, 4) END) AS IdentificacionEnmascarada,
       g.Concepto,
       CONVERT(varchar(13), COALESCE(r.Ncf, f.Ncf))                AS Ncf,
       g.TipoGastoId,
       tg.Codigo                                                   AS TipoGastoCodigo,
       g.MonedaId,
       mo.Codigo                                                   AS MonedaCodigo,
       g.Tasa,
       g.Monto,
       g.Itbis,
       CONVERT(decimal(19, 2), ROUND(g.Monto * g.Tasa, 2))         AS MontoBase,
       CONVERT(decimal(19, 2), ROUND(g.Itbis * g.Tasa, 2))         AS ItbisBase,
       g.PorcRetencionItbis,
       g.PorcRetencionIsr,
       g.RncCedula                                                 AS Identificacion
  FROM caja.CajaChica g
  JOIN doc.Documento d       ON d.Id = g.DocumentoId AND d.Estado IN (1, 2)
  JOIN org.Sucursal su       ON su.Id = d.SucursalId
  JOIN org.Caja ca           ON ca.Id = g.CajaId
  JOIN caja.Jornada j        ON j.Id = g.JornadaId
  JOIN cat.Moneda mo         ON mo.Id = g.MonedaId
  LEFT JOIN cat.TipoGasto tg       ON tg.Id = g.TipoGastoId
  LEFT JOIN fiscal.Registro606 r   ON r.DocumentoId = g.DocumentoId
  LEFT JOIN fiscal.Comprobante f   ON f.DocumentoId = g.DocumentoId AND f.Rol = 'O';
GO

/* ---------------------------------------------------------------------------------------------------------------------
   6. Movimientos de caja (reporte 23). Grano: caja.Movimiento. Fecha = FechaOperacion de la jornada (sargable por caja.Jornada y
      IX_CajaMovimiento_Jornada; la del informe de caja); FechaRegistroLocal y Hora desde RegistradoEn (UTC − 4).
      Q-4 (RS-02): en rpt, el monto de las filas de cierre (CIERRE y el REVERSO de un CIERRE, que repite lo declarado) va en NULL;
      EsCierre lo explica. rptc.MovimientoCaja («Ver cuadre de caja») agrega MontoCompleto y MontoCompletoBase con todas las cifras.
      Sin marca «revertido» (como el kárdex, revisión 3): el reverso es su propia fila, con TipoRevertido.
   --------------------------------------------------------------------------------------------------------------------- */
CREATE OR ALTER VIEW rpt.MovimientoCaja AS
SELECT m.Id                                                        AS MovimientoId,
       j.FechaOperacion                                            AS Fecha,
       CONVERT(date, DATEADD(HOUR, -4, m.RegistradoEn))            AS FechaRegistroLocal,
       CONVERT(time(0), DATEADD(HOUR, -4, m.RegistradoEn))         AS Hora,
       m.RegistradoEn,
       m.SucursalId,
       su.Codigo                                                   AS SucursalCodigo,
       j.CajaId,
       ca.Codigo                                                   AS CajaCodigo,
       m.JornadaId,
       j.Cajero,
       m.Usuario,
       m.Tipo,
       r.Tipo                                                      AS TipoRevertido,
       x.EsCierre,
       m.DocumentoId,
       d.Numero                                                    AS DocumentoNumero,
       t.Codigo                                                    AS TipoDocumentoCodigo,
       m.Motivo,
       m.MonedaId,
       mo.Codigo                                                   AS MonedaCodigo,
       m.Tasa,
       CONVERT(decimal(19, 2), CASE WHEN x.EsCierre = 0 THEN m.Monto END) AS Monto,
       CONVERT(decimal(19, 2), CASE WHEN x.EsCierre = 0 THEN ROUND(m.Monto * m.Tasa, 2) END) AS MontoBase
  FROM caja.Movimiento m
  JOIN caja.Jornada j        ON j.Id = m.JornadaId
  JOIN org.Sucursal su       ON su.Id = m.SucursalId
  JOIN org.Caja ca           ON ca.Id = j.CajaId
  JOIN cat.Moneda mo         ON mo.Id = m.MonedaId
  LEFT JOIN caja.Movimiento r      ON r.Id = m.MovimientoRevertidoId
  LEFT JOIN doc.Documento d        ON d.Id = m.DocumentoId
  LEFT JOIN doc.TipoDocumento t    ON t.Id = d.TipoDocumentoId
  CROSS APPLY (SELECT CONVERT(bit, CASE WHEN m.Tipo = 'CIERRE' OR r.Tipo = 'CIERRE' THEN 1 ELSE 0 END) AS EsCierre) x;
GO
CREATE OR ALTER VIEW rptc.MovimientoCaja AS
SELECT m.Id                                                        AS MovimientoId,
       j.FechaOperacion                                            AS Fecha,
       CONVERT(date, DATEADD(HOUR, -4, m.RegistradoEn))            AS FechaRegistroLocal,
       CONVERT(time(0), DATEADD(HOUR, -4, m.RegistradoEn))         AS Hora,
       m.RegistradoEn,
       m.SucursalId,
       su.Codigo                                                   AS SucursalCodigo,
       j.CajaId,
       ca.Codigo                                                   AS CajaCodigo,
       m.JornadaId,
       j.Cajero,
       m.Usuario,
       m.Tipo,
       r.Tipo                                                      AS TipoRevertido,
       x.EsCierre,
       m.DocumentoId,
       d.Numero                                                    AS DocumentoNumero,
       t.Codigo                                                    AS TipoDocumentoCodigo,
       m.Motivo,
       m.MonedaId,
       mo.Codigo                                                   AS MonedaCodigo,
       m.Tasa,
       CONVERT(decimal(19, 2), CASE WHEN x.EsCierre = 0 THEN m.Monto END) AS Monto,
       CONVERT(decimal(19, 2), CASE WHEN x.EsCierre = 0 THEN ROUND(m.Monto * m.Tasa, 2) END) AS MontoBase,
       m.Monto                                                     AS MontoCompleto,
       CONVERT(decimal(19, 2), ROUND(m.Monto * m.Tasa, 2))         AS MontoCompletoBase
  FROM caja.Movimiento m
  JOIN caja.Jornada j        ON j.Id = m.JornadaId
  JOIN org.Sucursal su       ON su.Id = m.SucursalId
  JOIN org.Caja ca           ON ca.Id = j.CajaId
  JOIN cat.Moneda mo         ON mo.Id = m.MonedaId
  LEFT JOIN caja.Movimiento r      ON r.Id = m.MovimientoRevertidoId
  LEFT JOIN doc.Documento d        ON d.Id = m.DocumentoId
  LEFT JOIN doc.TipoDocumento t    ON t.Id = d.TipoDocumentoId
  CROSS APPLY (SELECT CONVERT(bit, CASE WHEN m.Tipo = 'CIERRE' OR r.Tipo = 'CIERRE' THEN 1 ELSE 0 END) AS EsCierre) x;
GO

/* ---------------------------------------------------------------------------------------------------------------------
   7. Catálogos (L-27 a L-37): tipo de gasto y término.
   --------------------------------------------------------------------------------------------------------------------- */
CREATE OR ALTER VIEW rpt.CatTipoGasto AS
SELECT g.Id, g.Codigo, g.Descripcion, g.Inhabilitado, g.TipoBienServicio606
  FROM cat.TipoGasto g;
GO
CREATE OR ALTER VIEW rpt.CatTermino AS
SELECT t.Id, t.Codigo, t.Descripcion, t.Inhabilitado, t.Dias
  FROM cat.Termino t;
GO

/* ---------------------------------------------------------------------------------------------------------------------
   8. Cambios en vistas existentes (contrato 1.3, sin quitar columnas):
      - rpt.CierreCajaConteo (Q-5, T3-10): Esperado en NULL en todas las filas; la cifra queda solo en rptc.CierreCajaConteo.
      - rpt.ConsultaFactura y rptc.ConsultaFactura (Q-3): fiscal.Comprobante con Rol IN ('O', 'H') y columna NcfHistorico
        (al final de rpt; en rptc, antes de IdentificacionCliente para conservar el superconjunto V-10).
   --------------------------------------------------------------------------------------------------------------------- */
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
       CONVERT(decimal(19, 2), NULL)                       AS Esperado
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
       CONVERT(varchar(161), e.Nombres + ' ' + e.Apellidos) AS VendedorNombre,
       CONVERT(bit, CASE WHEN c.Rol = 'H' OR (c.Ncf IS NULL AND d.Origen = 'I' AND v.Referencia IS NOT NULL) THEN 1 ELSE 0 END) AS NcfHistorico
  FROM ventas.Venta v
  JOIN doc.Documento d       ON d.Id = v.DocumentoId AND d.Estado IN (1, 2)
  JOIN doc.TipoDocumento t   ON t.Id = d.TipoDocumentoId AND t.Codigo IN ('FAC', 'FPOS', 'DEV')
  JOIN org.Sucursal su       ON su.Id = d.SucursalId
  JOIN cat.Moneda mo         ON mo.Id = v.MonedaId
  JOIN cat.Cliente cl        ON cl.Id = v.ClienteId
  LEFT JOIN cat.MotivoAnulacion ma ON ma.Id = d.MotivoAnulacionId
  LEFT JOIN cxc.Cuenta cu          ON cu.DocumentoId = d.Id
  LEFT JOIN fiscal.Comprobante c   ON c.DocumentoId = d.Id AND c.Rol IN ('O', 'H')
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
       CONVERT(bit, CASE WHEN c.Rol = 'H' OR (c.Ncf IS NULL AND d.Origen = 'I' AND v.Referencia IS NOT NULL) THEN 1 ELSE 0 END) AS NcfHistorico,
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
  LEFT JOIN fiscal.Comprobante c   ON c.DocumentoId = d.Id AND c.Rol IN ('O', 'H')
  LEFT JOIN org.Caja ca            ON ca.Id = v.CajaId
  LEFT JOIN caja.Jornada j         ON j.Id = v.JornadaId
  LEFT JOIN rrhh.Empleado e        ON e.Id = v.VendedorId
  CROSS APPLY (SELECT CONVERT(varchar(20), COALESCE(v.IdentificacionCliente, cl.Identificacion)) AS Identificacion,
                      CONVERT(char(1), CASE WHEN v.IdentificacionCliente IS NOT NULL THEN v.TipoIdentificacionCliente
                                            ELSE cl.TipoIdentificacion END) AS Tipo) idc;
GO

/* ---------------------------------------------------------------------------------------------------------------------
   9. Versión del contrato: sigue la versión mayor 1; huella = SHA-256 del contrato-vistas.v1.json 1.3 (UTF-8 sin BOM, LF).
   --------------------------------------------------------------------------------------------------------------------- */
CREATE OR ALTER VIEW rpt.VersionContrato AS
SELECT CONVERT(smallint, 1) AS Version,
       CONVERT(smallint, 1) AS VersionMinima,
       CONVERT(binary(32), 0x15E75340C3726390D565A166034B6E1B3A6DE1A9BC1FD3A742E237C08B8EB1CB) AS Huella;
GO

/* 10. Permisos: el lote PermisosLecturaReportes.Sql (idempotente; concede por esquema, así que las vistas nuevas quedan cubiertas).
       En la migración se agrega al final igual que en Ola5VistasVentasInventario. */
SET NOEXEC OFF;
GO
