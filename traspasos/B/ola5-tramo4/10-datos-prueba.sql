/* Datos de prueba del tramo 4 (SOLO base temporal GPOS_TEST_*): disparadores desactivados para sembrar directo; se reactivan al final.
   Hoy fijo = 2026-10-10 para que los rangos de antigüedad sean deterministas. */
SET NOCOUNT ON; SET XACT_ABORT ON;
IF DB_NAME() NOT LIKE 'GPOS[_]TEST[_]%' THROW 50000, N'Solo en bases GPOS_TEST_*', 1;
DECLARE @sql nvarchar(max) = N'';
SELECT @sql += N'ALTER TABLE ' + QUOTENAME(OBJECT_SCHEMA_NAME(t.parent_id)) + N'.' + QUOTENAME(OBJECT_NAME(t.parent_id)) + N' DISABLE TRIGGER ALL;' + NCHAR(10)
  FROM (SELECT DISTINCT parent_id FROM sys.triggers WHERE parent_class = 1) t;
EXEC sys.sp_executesql @sql;

BEGIN TRANSACTION;
DECLARE @hoy date = '2026-10-10', @serie int = (SELECT MIN(Id) FROM num.Serie WHERE Clase = 'DOC');
-- Maestros
INSERT cat.Zona (Codigo, Descripcion) VALUES ('ZN', 'Zona norte');
INSERT rrhh.Empleado (Codigo, Nombres, Apellidos, EsVendedor) VALUES ('V01', 'Ana', 'Pérez', 1);
INSERT cat.Cliente (Codigo, RazonSocial, TipoIdentificacion, Identificacion, VendedorId, ZonaId, CreadoPor, ModificadoPor, Prospecto, AplicaImpuesto, Inhabilitado)
VALUES ('C01', 'Cliente Uno', 'R', '101010101', (SELECT Id FROM rrhh.Empleado WHERE Codigo = 'V01'), (SELECT Id FROM cat.Zona WHERE Codigo = 'ZN'), 'P', 'P', 0, 1, 0),
       ('C02', 'Cliente Dos', 'C', '00100000001', NULL, NULL, 'P', 'P', 0, 1, 0);
INSERT cat.Suplidor (Codigo, RazonSocial, TipoIdentificacion, Identificacion, CreadoPor, ModificadoPor, RetieneItbis, RetieneIsr, AplicaImpuesto, Inhabilitado)
VALUES ('S01', 'Suplidor Uno', 'R', '130000001', 'P', 'P', 0, 0, 1, 0), ('S02', 'Suplidor Dos', 'R', '130000002', 'P', 'P', 0, 0, 1, 0);
INSERT cat.TipoGasto (TipoBienServicio606, Codigo, Descripcion) VALUES ('02', 'TG02', 'Gastos por trabajos y servicios');
INSERT cat.Banco (Codigo, Nombre) VALUES ('BAN1', 'Banco Uno');
INSERT banco.CuentaBancaria (Codigo, Descripcion, BancoId, MonedaId, SucursalId) VALUES ('CB-DOP', 'Cuenta pesos', (SELECT Id FROM cat.Banco), 1, 1), ('CB-USD', 'Cuenta dólares', (SELECT Id FROM cat.Banco), 2, 1);
INSERT fiscal.SecuenciaNcf (TipoComprobanteCodigo, PuntoEmisionId, Prefijo, Digitos, Desde, Hasta, Siguiente, ModificadoPor, FechaVencimiento)
SELECT v.t, (SELECT MIN(Id) FROM fiscal.PuntoEmision), 'B' + v.t, 8, 1, 1000, 10, 'P', '2027-12-31' FROM (VALUES ('01'), ('11'), ('13')) v(t);

DECLARE @c1 bigint = (SELECT Id FROM cat.Cliente WHERE Codigo = 'C01'), @c2 bigint = (SELECT Id FROM cat.Cliente WHERE Codigo = 'C02'),
        @s1 int = (SELECT Id FROM cat.Suplidor WHERE Codigo = 'S01'), @s2 int = (SELECT Id FROM cat.Suplidor WHERE Codigo = 'S02'),
        @tg smallint = (SELECT Id FROM cat.TipoGasto), @cbd smallint = (SELECT Id FROM banco.CuentaBancaria WHERE Codigo = 'CB-DOP'),
        @cbu smallint = (SELECT Id FROM banco.CuentaBancaria WHERE Codigo = 'CB-USD');

-- Documentos: (tipo, número, fecha, estado, origen)
DECLARE @d TABLE (Clave varchar(10) PRIMARY KEY, Id bigint, Tipo varchar(5), Numero varchar(20), Fecha date, Estado tinyint, Origen char(1));
INSERT @d (Clave, Tipo, Numero, Fecha, Estado, Origen) VALUES
 ('FAC1','FAC','FC00000001','2026-08-01',1,'N'), ('FAC2','FAC','FC00000002','2026-09-20',1,'N'), ('ND1','ND','ND00000001','2026-06-15',1,'N'),
 ('CHD1','CHD','CD00000001','2026-09-01',1,'N'), ('FACI','FAC','HIST-0099','2026-07-01',1,'I'), ('FAC4','FAC','FC00000004','2026-09-05',2,'N'),
 ('FCP1','FCP','FP00000001','2026-08-20',1,'N'), ('FCP2','FCP','FP00000002','2026-10-01',1,'N'), ('NCP1','NCP','NP00000001','2026-10-02',1,'N'),
 ('FCP3','FCP','FP00000003','2026-10-03',2,'N'), ('FCPI','FCP','CXP-IMP-1','2026-05-01',1,'I'),
 ('CHK1','CHK','CK00000001','2026-10-04',1,'N'), ('DEP1','DEP','DP00000001','2026-10-05',1,'N'), ('TRB1','TRB','TB00000001','2026-10-06',1,'N'),
 ('CHK2','CHK','CK00000002','2026-10-06',2,'N'),
 ('AP1','AP','AP00000001','2026-10-09',1,'N'), ('AP2','AP','AP00000002','2026-10-10',1,'N'), ('FPOS1','FPOS','FP0S000001','2026-10-09',1,'N'),
 ('CC1','CC','CC00000001','2026-10-09',1,'N'), ('CC2','CC','CC00000002','2026-10-09',1,'N'), ('CU1','CU','CU00000001','2026-10-09',1,'N'),
 ('FPOS2','FPOS','FP0S000002','2026-10-10',1,'N');
UPDATE @d SET Id = NEXT VALUE FOR doc.SecDocumento;
INSERT doc.Documento (Id, TipoDocumentoId, Origen, SerieId, Numero, Fecha, SucursalId, Estado, Uid, CreadoPor, EmitidoEn, AnuladoEn, AnuladoPor, MotivoAnulacion)
SELECT x.Id, t.Id, x.Origen, CASE WHEN x.Origen = 'I' THEN NULL ELSE @serie END, x.Numero, x.Fecha, 1, x.Estado, NEWID(), 'PRUEBA',
       DATEADD(HOUR, 14, CONVERT(datetime2(3), x.Fecha)),
       CASE WHEN x.Estado = 2 THEN DATEADD(HOUR, 15, CONVERT(datetime2(3), x.Fecha)) END, CASE WHEN x.Estado = 2 THEN 'PRUEBA' END,
       CASE WHEN x.Estado = 2 THEN 'Error de digitación' END
  FROM @d x JOIN doc.TipoDocumento t ON t.Codigo = x.Tipo;

DECLARE @id TABLE (Clave varchar(10) PRIMARY KEY, Id bigint); INSERT @id SELECT Clave, Id FROM @d;
-- Ventas y CxC
INSERT ventas.Venta (DocumentoId, ClienteId, NombreCliente, IdentificacionCliente, TipoIdentificacionCliente, MonedaId, Tasa, SubTotal, Impuesto, Total, FechaVencimiento, Referencia, CajaId, JornadaId)
SELECT i.Id, v.Cli, v.Nom, v.Ide, v.Tid, v.Mon, v.Tasa, v.Sub, v.Imp, v.Tot, v.Vence, v.Ref, NULL, NULL
  FROM (VALUES ('FAC1', @c1, 'Cliente Uno', '101010101', 'R', 1, 1.0, 847.46, 152.54, 1000.00, '2026-08-26', NULL),
               ('FAC2', @c1, 'Cliente Uno', '101010101', 'R', 2, 60.0, 100.00, 0, 100.00, '2026-10-20', NULL),
               ('ND1',  @c2, 'Cliente Dos', '00100000001', 'C', 1, 1.0, 300.00, 0, 300.00, '2026-07-02', NULL),
               ('CHD1', @c2, 'Cliente Dos', '00100000001', 'C', 1, 1.0, 500.00, 0, 500.00, '2026-09-01', '000123'),
               ('FACI', @c2, 'Cliente Dos', '00100000001', 'C', 1, 1.0, 250.00, 0, 250.00, '2026-09-20', 'B0100009999'),
               ('FAC4', @c1, 'Cliente Uno', '101010101', 'R', 1, 1.0, 80.00, 0, 80.00, '2026-10-05', NULL),
               ('FPOS1', @c1, 'Cliente Uno', '101010101', 'R', 1, 1.0, 500.00, 0, 500.00, NULL, NULL),
               ('FPOS2', @c1, 'Cliente Uno', '101010101', 'R', 2, 60.0, 100.00, 0, 100.00, NULL, NULL))
       v(Clave, Cli, Nom, Ide, Tid, Mon, Tasa, Sub, Imp, Tot, Vence, Ref) JOIN @id i ON i.Clave = v.Clave;
INSERT cxc.Cuenta (DocumentoId, ClienteId, FechaVencimiento, MonedaId, Monto, SaldoPendiente)
SELECT i.Id, v.ClienteId, v.FechaVencimiento, v.MonedaId, v.Total, s.Saldo
  FROM (VALUES ('FAC1', 600.00), ('FAC2', 100.00), ('ND1', 300.00), ('CHD1', 0.00), ('FACI', 250.00), ('FAC4', 0.00)) s(Clave, Saldo)
  JOIN @id i ON i.Clave = s.Clave JOIN ventas.Venta v ON v.DocumentoId = i.Id;
INSERT fiscal.Comprobante (DocumentoId, Rol, SecuenciaId, Ncf, TipoComprobanteCodigo, FechaEmision, RncReceptor, NombreReceptor, MontoGravado, MontoExento, Itbis, MontoTotal)
SELECT i.Id, 'O', (SELECT Id FROM fiscal.SecuenciaNcf WHERE TipoComprobanteCodigo = v.T), v.Ncf, v.T, '2026-08-01', NULL, NULL, v.Tot, 0, 0, v.Tot
  FROM (VALUES ('FAC1', '01', 'B0100000001', 1000.00), ('FAC2', '01', 'B0100000002', 100.00), ('FCP2', '11', 'B1100000001', 200.00), ('CC2', '13', 'B1300000001', 10.00)) v(Clave, T, Ncf, Tot)
  JOIN @id i ON i.Clave = v.Clave;
-- Compras y CxP
INSERT compras.Compra (DocumentoId, SuplidorId, AlmacenId, TerminoId, FechaVencimiento, MonedaId, Tasa, NumeroSuplidor, TipoGastoId, SubTotal, Descuento, Impuesto, Total, DocumentoOrigenId)
SELECT i.Id, v.Sup, 1, (SELECT MIN(Id) FROM cat.Termino), v.Vence, v.Mon, v.Tasa, v.NumS, @tg, v.Sub, 0, v.Imp, v.Sub + v.Imp, o.Id
  FROM (VALUES ('FCP1', @s1, '2026-09-05', 1, 1.0, 'F-77', 1000.00, 180.00, NULL), ('FCP2', @s2, '2026-10-15', 2, 58.5, 'INV-9', 200.00, 0, NULL),
               ('NCP1', @s1, '2026-10-02', 1, 1.0, NULL, 100.00, 0, 'FCP1'), ('FCP3', @s1, '2026-10-30', 1, 1.0, 'F-80', 50.00, 0, NULL),
               ('FCPI', @s2, '2026-06-01', 1, 1.0, 'VIEJA-1', 700.00, 0, NULL)) v(Clave, Sup, Vence, Mon, Tasa, NumS, Sub, Imp, Orig)
  JOIN @id i ON i.Clave = v.Clave LEFT JOIN @id o ON o.Clave = v.Orig;
INSERT cxp.Cuenta (DocumentoId, SuplidorId, FechaVencimiento, MonedaId, Tasa, Monto, SaldoPendiente)
SELECT i.Id, c.SuplidorId, c.FechaVencimiento, c.MonedaId, c.Tasa, c.Total, s.Saldo
  FROM (VALUES ('FCP1', 1080.00), ('FCP2', 50.00), ('FCP3', 0.00), ('FCPI', 700.00)) s(Clave, Saldo) JOIN @id i ON i.Clave = s.Clave JOIN compras.Compra c ON c.DocumentoId = i.Id;
INSERT fiscal.Registro606 (DocumentoId, TipoIdentificacion, RncCedula, TipoBienServicio606, Ncf, NcfModificado, FechaComprobante, MontoServicios, ItbisFacturado)
SELECT i.Id, v.TI, v.Rnc, '02', v.Ncf, v.NcfMod, '2026-08-20', 1000, 180
  FROM (VALUES ('FCP1', '1', '130000001', 'B0100000123', NULL), ('NCP1', '1', '130000001', 'B0400000007', 'B0100000123'), ('CC1', '2', '00112345678', 'B0200000055', NULL)) v(Clave, TI, Rnc, Ncf, NcfMod)
  JOIN @id i ON i.Clave = v.Clave;
-- Banco
INSERT banco.DocBanco (DocumentoId, Clase, Signo, CuentaBancariaId, SuplidorId, Beneficiario, MonedaId, Tasa, Monto, NumeroCheque, Referencia, Concepto)
SELECT i.Id, v.Clase, v.Signo, v.Cta, v.Sup, v.Ben, v.Mon, v.Tasa, v.Monto, v.Chk, v.Ref, v.Con
  FROM (VALUES ('CHK1', 'CHK', -1, @cbd, @s1, 'Suplidor Uno', 1, 1.0, 100.00, 1, NULL, 'Pago FP00000001'),
               ('DEP1', 'DEP', 1, @cbd, NULL, NULL, 1, 1.0, 5000.00, NULL, 'DEP-55', 'Depósito'),
               ('TRB1', 'TRB', -1, @cbu, @s2, 'Suplidor Dos', 2, 60.0, 150.00, NULL, 'TRF-1', 'Pago INV-9'),
               ('CHK2', 'CHK', -1, @cbd, @s1, 'Suplidor Uno', 1, 1.0, 10.00, 2, NULL, 'Anulado')) v(Clave, Clase, Signo, Cta, Sup, Ben, Mon, Tasa, Monto, Chk, Ref, Con)
  JOIN @id i ON i.Clave = v.Clave;
-- Caja: jornada cerrada (09-oct) y abierta (10-oct)
INSERT caja.Jornada (DocumentoAperturaId, CajaId, SucursalId, Cajero, FechaOperacion, AbiertaEn, MontoApertura, Estado, CerradaEn)
SELECT (SELECT Id FROM @id WHERE Clave = 'AP1'), 1, 1, 'CAJERO1', '2026-10-09', '2026-10-09T12:00:00', 1000, 'C', '2026-10-10T01:30:00' UNION ALL
SELECT (SELECT Id FROM @id WHERE Clave = 'AP2'), 1, 1, 'CAJERO1', '2026-10-10', '2026-10-10T12:00:00', 500, 'A', NULL;
DECLARE @j1 bigint = (SELECT Id FROM caja.Jornada WHERE FechaOperacion = '2026-10-09'), @j2 bigint = (SELECT Id FROM caja.Jornada WHERE FechaOperacion = '2026-10-10');
UPDATE ventas.Venta SET CajaId = 1, JornadaId = @j1 WHERE DocumentoId = (SELECT Id FROM @id WHERE Clave = 'FPOS1');
UPDATE ventas.Venta SET CajaId = 1, JornadaId = @j2 WHERE DocumentoId = (SELECT Id FROM @id WHERE Clave = 'FPOS2');
INSERT caja.CajaChica (DocumentoId, JornadaId, CajaId, Beneficiario, RncCedula, Concepto, TipoGastoId, MonedaId, Tasa, Monto, Itbis)
SELECT (SELECT Id FROM @id WHERE Clave = 'CC1'), @j1, 1, 'Juan Plomero', '00112345678', 'Reparación', @tg, 1, 1.0, 200.00, 30.00 UNION ALL
SELECT (SELECT Id FROM @id WHERE Clave = 'CC2'), @j1, 1, 'Ferretería SRL', '130123456', 'Materiales', @tg, 2, 60.0, 10.00, 0;
INSERT caja.Movimiento (JornadaId, SucursalId, Tipo, DocumentoId, MonedaId, Tasa, Monto, Motivo, Usuario, RegistradoEn)
VALUES (@j1, 1, 'APERTURA', (SELECT Id FROM @id WHERE Clave = 'AP1'), 1, 1, 1000, NULL, 'CAJERO1', '2026-10-09T12:00:00'),
       (@j1, 1, 'VENTA', (SELECT Id FROM @id WHERE Clave = 'FPOS1'), 1, 1, 500, NULL, 'CAJERO1', '2026-10-09T15:10:00'),
       (@j1, 1, 'GASTO', (SELECT Id FROM @id WHERE Clave = 'CC1'), 1, 1, -200, NULL, 'CAJERO1', '2026-10-09T16:00:00'),
       (@j1, 1, 'GASTO', (SELECT Id FROM @id WHERE Clave = 'CC2'), 2, 60, -10, NULL, 'CAJERO1', '2026-10-09T16:05:00'),
       (@j1, 1, 'CIERRE', (SELECT Id FROM @id WHERE Clave = 'CU1'), 1, 1, -1300, NULL, 'CAJERO1', '2026-10-10T01:30:00'),
       (@j2, 1, 'APERTURA', (SELECT Id FROM @id WHERE Clave = 'AP2'), 1, 1, 500, NULL, 'CAJERO1', '2026-10-10T12:00:00'),
       (@j2, 1, 'VENTA', (SELECT Id FROM @id WHERE Clave = 'FPOS2'), 2, 60, 100, NULL, 'CAJERO1', '2026-10-10T13:00:00');
-- Reverso de un cierre (anulación de Z simulada en la jornada 1) para Q-4
INSERT caja.Movimiento (JornadaId, SucursalId, Tipo, DocumentoId, MonedaId, Tasa, Monto, Motivo, Usuario, RegistradoEn, MovimientoRevertidoId)
SELECT @j1, 1, 'REVERSO', DocumentoId, 1, 1, 1300, NULL, 'ADMIN', '2026-10-10T02:00:00', Id FROM caja.Movimiento WHERE Tipo = 'CIERRE';
INSERT caja.Cierre (DocumentoId, JornadaId, CajaId, Tipo, NumeroEnCaja, CantidadFacturas, CantidadDevoluciones, TotalVentas, TotalDevoluciones, TotalImpuestos, EfectivoEsperado, EfectivoDeclarado, RondaConteo)
SELECT (SELECT Id FROM @id WHERE Clave = 'CU1'), @j1, 1, 'Z', 1, 1, 0, 500, 0, 0, 1300, 1300, 1;
INSERT caja.CierreConteo (DocumentoId, FormaPagoId, MonedaId, Esperado, Contado)
SELECT (SELECT Id FROM @id WHERE Clave = 'CU1'), (SELECT Id FROM cat.FormaPago WHERE Codigo = 'EFECTIVO'), 1, 1300, 1300;

SET @sql = REPLACE(@sql, N'DISABLE TRIGGER', N'ENABLE TRIGGER');
EXEC sys.sp_executesql @sql;
COMMIT;
SELECT 'documentos' AS que, COUNT(*) FROM doc.Documento;
