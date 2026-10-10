/* Prueba funcional del DDL v3 (tramo 1) en GPOS_TEST_OLA3B_DDL. Emula el servicio: A1 despacho, A2 recepción en dos partes (H-3b-10),
   modo S, A4 anulación, y las redes 51440-51457. Cada caso negativo informa el error obtenido. */
SET NOCOUNT ON; SET XACT_ABORT OFF; SET QUOTED_IDENTIFIER ON; SET ANSI_NULLS ON;
DECLARE @hoy date = CONVERT(date, DATEADD(MINUTE, -240, SYSUTCDATETIME()));
DECLARE @imp tinyint = (SELECT TOP (1) Id FROM fiscal.Impuesto ORDER BY Id);

-- Maestros de prueba
SET IDENTITY_INSERT org.Sucursal ON;
IF NOT EXISTS (SELECT 1 FROM org.Sucursal WHERE Id = 2) INSERT INTO org.Sucursal (Id, Codigo, Nombre, Inhabilitado) VALUES (2, 'SUCB', 'Sucursal B', 0);
SET IDENTITY_INSERT org.Sucursal OFF; SET IDENTITY_INSERT org.Almacen ON;
IF NOT EXISTS (SELECT 1 FROM org.Almacen WHERE Id = 2) INSERT INTO org.Almacen (Id, Codigo, Nombre, SucursalId, Tipo, EnCuarentena, Inhabilitado) VALUES (2, 'ALMB', 'Almacén B', 2, 'N', 0, 0);
IF NOT EXISTS (SELECT 1 FROM org.Almacen WHERE Id = 3) INSERT INTO org.Almacen (Id, Codigo, Nombre, SucursalId, Tipo, EnCuarentena, Inhabilitado) VALUES (3, 'ALMA2', 'Almacén A2', 1, 'N', 0, 0);
SET IDENTITY_INSERT org.Almacen OFF; SET IDENTITY_INSERT cat.Articulo ON;
IF NOT EXISTS (SELECT 1 FROM cat.Articulo WHERE Id = 1)
    INSERT INTO cat.Articulo (Id, Codigo, Descripcion, Tipo, Inventariable, ImpuestoId, UnidadBaseId, UnidadVentaId, UnidadCompraId, CreadoPor, ModificadoPor, DescripcionClave)
    VALUES (1, 'ART1', 'Articulo uno', 'E', 1, @imp, 1, 1, 1, 'PRUEBA', 'PRUEBA', 'ARTICULO UNO');
SET IDENTITY_INSERT cat.Articulo OFF;
IF NOT EXISTS (SELECT 1 FROM cat.ArticuloUnidad WHERE ArticuloId = 1 AND UnidadId = 1) INSERT INTO cat.ArticuloUnidad (ArticuloId, UnidadId, Factor) VALUES (1, 1, 1);
IF NOT EXISTS (SELECT 1 FROM inv.Existencia WHERE ArticuloId = 1 AND AlmacenId = 1) INSERT INTO inv.Existencia (ArticuloId, AlmacenId, Cantidad, PermiteNegativa, ActualizadaEn) VALUES (1, 1, 10, 0, SYSUTCDATETIME());
IF NOT EXISTS (SELECT 1 FROM inv.ArticuloCosto WHERE ArticuloId = 1) INSERT INTO inv.ArticuloCosto (ArticuloId, CostoPromedio, CostoExistencia) VALUES (1, 50, 10);
IF NOT EXISTS (SELECT 1 FROM num.Serie WHERE TipoCodigo = 'TransferenciaInventario')
    INSERT INTO num.Serie (Clase, TipoCodigo, SucursalId, PrefijoBase, Prefijo, Digitos, Siguiente, CreadoPor) VALUES ('DOC', 'TransferenciaInventario', NULL, 'TI', 'TI', 8, 1, 'PRUEBA');
DECLARE @serie int = (SELECT Id FROM num.Serie WHERE TipoCodigo = 'TransferenciaInventario');
GO
-- Procedimiento auxiliar de prueba: despacho A1 completo (borrador → líneas/kárdex → saldo R → existencia → emisión)
CREATE OR ALTER PROCEDURE dbo.prueba_Despachar @n int, @cant decimal(18,6), @usuario varchar(60), @almDestino smallint, @sucDestino smallint,
    @permite bit = 0, @salida bit = 0, @doc bigint OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @hoy date = CONVERT(date, DATEADD(MINUTE, -240, SYSUTCDATETIME())), @serie int = (SELECT Id FROM num.Serie WHERE TipoCodigo = 'TransferenciaInventario');
    BEGIN TRAN;
    INSERT INTO doc.Documento (TipoDocumentoId, Origen, Numero, Fecha, SucursalId, Estado, Uid, CreadoPor) VALUES (31, 'P', '~' + LEFT(CONVERT(varchar(36), NEWID()), 19), @hoy, 1, 0, NEWID(), @usuario);
    SET @doc = SCOPE_IDENTITY();
    SET @doc = (SELECT MAX(Id) FROM doc.Documento WHERE CreadoPor = @usuario AND TipoDocumentoId = 31);
    INSERT INTO inv.Transferencia (DocumentoId, Modo, AlmacenOrigenId, SucursalOrigenId, AlmacenDestinoId, SucursalDestinoId, PlazoDias, TotalLineas, TotalUnidades, Huella,
                                   SalidaConfirmadaEn, SalidaConfirmadaPor)
    VALUES (@doc, CASE WHEN @sucDestino = 1 THEN 'S' ELSE 'E' END, 1, 1, @almDestino, @sucDestino, 2, 1, @cant, HASHBYTES('SHA2_256', 'x'),
            CASE WHEN @salida = 1 THEN SYSUTCDATETIME() END, CASE WHEN @salida = 1 THEN @usuario END);
    DECLARE @m TABLE (Id bigint);
    INSERT INTO inv.Movimiento (ArticuloId, AlmacenId, SucursalId, DocumentoId, Linea, Fecha, Cantidad, CostoUnitario, Clase, UnidadId, FactorUnidad, CantidadOrigen)
    OUTPUT inserted.Id INTO @m VALUES (1, 1, 1, @doc, 1, @hoy, -@cant, 50, 6, 1, 1, -@cant);
    INSERT INTO inv.TransferenciaLinea (DocumentoId, Linea, ArticuloId, UnidadId, FactorUnidad, CantidadUnidad, Cantidad, CostoDespacho, MovimientoSalidaId)
    SELECT @doc, 1, 1, 1, 1, @cant, @cant, 50, Id FROM @m;
    INSERT INTO doc.LineaSaldo (DocumentoId, Linea, Clase, CantidadOrigen, CantidadConsumida, CantidadFaltante) VALUES (@doc, 1, 'R', @cant, 0, 0);
    UPDATE inv.Existencia SET Cantidad = Cantidad - @cant, PermiteNegativa = CASE WHEN Cantidad - @cant < 0 THEN 1 ELSE @permite END
     WHERE ArticuloId = 1 AND AlmacenId = 1 AND (@permite = 1 OR Cantidad - @cant >= 0);
    IF @@ROWCOUNT = 0 THROW 50001, 'EXISTENCIA_INSUFICIENTE (servicio)', 1;
    UPDATE doc.Documento SET Estado = 1, Origen = 'N', SerieId = @serie, Numero = 'TI' + RIGHT('0000000' + CONVERT(varchar(10), @n), 8), EmitidoEn = SYSUTCDATETIME() WHERE Id = @doc;
    COMMIT;
END
GO
CREATE OR ALTER PROCEDURE dbo.prueba_Recibir @doc bigint, @cant decimal(18,6), @usuario varchar(60), @alm smallint, @suc smallint, @kardexMalo bit = 0
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @hoy date = CONVERT(date, DATEADD(MINUTE, -240, SYSUTCDATETIME())), @ses uniqueidentifier = NEWID(),
            @n smallint = ISNULL((SELECT MAX(Consecutivo) FROM inv.TransferenciaRecepcion WHERE DocumentoId = @doc), 0) + 1;
    INSERT INTO inv.SesionRecepcion (Id, DocumentoId, AlmacenId, SucursalId, ConteoCiego, AbiertaPor) VALUES (@ses, @doc, @alm, @suc, 1, @usuario);
    DECLARE @esc uniqueidentifier = NEWID();
    INSERT INTO inv.SesionRecepcionEscaneo (SesionId, EscaneoId, ArticuloId, Cantidad, Origen, Usuario) VALUES (@ses, @esc, 1, @cant, 'D', @usuario);
    BEGIN TRAN;
    UPDATE doc.LineaSaldo SET CantidadConsumida = CantidadConsumida + @cant
     WHERE DocumentoId = @doc AND Linea = 1 AND Clase = 'R' AND CantidadOrigen - CantidadConsumida - CantidadFaltante >= @cant;
    IF @@ROWCOUNT = 0 THROW 50002, 'SALDO_INSUFICIENTE (servicio)', 1;
    DECLARE @m TABLE (Id bigint);
    INSERT INTO inv.Movimiento (ArticuloId, AlmacenId, SucursalId, DocumentoId, Linea, Fecha, Cantidad, CostoUnitario, Clase, UnidadId, FactorUnidad, CantidadOrigen)
    OUTPUT inserted.Id INTO @m VALUES (1, @alm, @suc, @doc, CASE WHEN @kardexMalo = 1 THEN 1 ELSE 1 + 10000 * (1000 + @n) END, @hoy, @cant, 50, 6, 1, 1, @cant);
    IF EXISTS (SELECT 1 FROM inv.Existencia WHERE ArticuloId = 1 AND AlmacenId = @alm) UPDATE inv.Existencia SET Cantidad = Cantidad + @cant WHERE ArticuloId = 1 AND AlmacenId = @alm;
    ELSE INSERT INTO inv.Existencia (ArticuloId, AlmacenId, Cantidad, PermiteNegativa, ActualizadaEn) VALUES (1, @alm, @cant, 0, SYSUTCDATETIME());
    DECLARE @r TABLE (Id bigint);
    INSERT INTO inv.TransferenciaRecepcion (DocumentoId, Consecutivo, SesionId, AlmacenId, SucursalId, Fecha, RegistradoPor)
    OUTPUT inserted.Id INTO @r VALUES (@doc, @n, @ses, @alm, @suc, @hoy, @usuario);
    INSERT INTO inv.TransferenciaRecepcionLinea (RecepcionId, DocumentoId, Linea, Cantidad, MovimientoEntradaId) SELECT r.Id, @doc, 1, @cant, m.Id FROM @r r CROSS JOIN @m m;
    UPDATE inv.SesionRecepcion SET Estado = 'C', CerradaEn = SYSUTCDATETIME() WHERE Id = @ses;
    COMMIT;
END
GO
CREATE OR ALTER PROCEDURE dbo.prueba_Anular @doc bigint, @usuario varchar(60)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @hoy date = CONVERT(date, DATEADD(MINUTE, -240, SYSUTCDATETIME()));
    BEGIN TRAN;
    INSERT INTO inv.Movimiento (ArticuloId, AlmacenId, SucursalId, DocumentoId, Linea, Fecha, Cantidad, CostoUnitario, Clase, MovimientoRevertidoId, UnidadId, FactorUnidad, CantidadOrigen)
    SELECT m.ArticuloId, m.AlmacenId, m.SucursalId, m.DocumentoId, m.Linea, @hoy, -m.Cantidad, m.CostoUnitario, m.Clase, m.Id, m.UnidadId, m.FactorUnidad, -m.CantidadOrigen
      FROM inv.Movimiento m WHERE m.DocumentoId = @doc AND m.MovimientoRevertidoId IS NULL;
    UPDATE e SET Cantidad = e.Cantidad + l.Cantidad FROM inv.Existencia e JOIN inv.TransferenciaLinea l ON l.DocumentoId = @doc AND l.ArticuloId = e.ArticuloId
      JOIN inv.Transferencia t ON t.DocumentoId = @doc AND t.AlmacenOrigenId = e.AlmacenId;
    UPDATE doc.Documento SET Estado = 2, AnuladoEn = SYSUTCDATETIME(), AnuladoPor = @usuario, MotivoAnulacion = 'Prueba de anulación' WHERE Id = @doc;
    COMMIT;
END
GO
-- ============================== Casos
DECLARE @d1 bigint, @d2 bigint, @d3 bigint, @d4 bigint, @d5 bigint;
PRINT '--- 1. Despacho TI1: 6 de A (alm 1) a B (alm 2)';
EXEC dbo.prueba_Despachar 1, 6, 'DESP', 2, 2, @doc = @d1 OUTPUT;
SELECT 'tras despacho' AS paso, (SELECT Cantidad FROM inv.Existencia WHERE ArticuloId = 1 AND AlmacenId = 1) AS ExistA,
       (SELECT Cantidad FROM inv.TransitoArticulo WHERE ArticuloId = 1) AS Transito, (SELECT Cantidad FROM inv.ExistenciaGlobal WHERE ArticuloId = 1) AS Global,
       (SELECT COUNT(*) FROM inv.TransferenciaAbierta) AS Abiertas, (SELECT Estado FROM inv.TransferenciaEstado WHERE DocumentoId = @d1) AS Estado;

PRINT '--- 2. El despachador intenta recibir (espera 51451)';
BEGIN TRY EXEC dbo.prueba_Recibir @d1, 2, 'DESP', 2, 2; PRINT 'NO FALLÓ'; END TRY BEGIN CATCH PRINT CONCAT('error ', ERROR_NUMBER(), ': ', ERROR_MESSAGE()); END CATCH
IF @@TRANCOUNT > 0 ROLLBACK;
UPDATE inv.SesionRecepcion SET Estado = 'X', CerradaEn = SYSUTCDATETIME() WHERE Estado = 'A';
PRINT '--- 3. Recepción con kárdex en la línea del despacho (espera 51454)';
BEGIN TRY EXEC dbo.prueba_Recibir @d1, 2, 'RECEP', 2, 2, @kardexMalo = 1; PRINT 'NO FALLÓ'; END TRY BEGIN CATCH PRINT CONCAT('error ', ERROR_NUMBER(), ': ', ERROR_MESSAGE()); END CATCH
IF @@TRANCOUNT > 0 ROLLBACK;
DELETE FROM inv.SesionRecepcionEscaneo WHERE SesionId IN (SELECT Id FROM inv.SesionRecepcion WHERE Estado = 'A');   -- sesiones de los casos fallidos
DELETE FROM inv.SesionRecepcion WHERE Estado = 'A' AND 1 = 0;   -- (la purga de abiertas la rechaza 51456: se prueba en el caso 9)
UPDATE inv.SesionRecepcion SET Estado = 'X', CerradaEn = SYSUTCDATETIME() WHERE Estado = 'A';

PRINT '--- 4. Dos recepciones parciales de la misma línea (2 y 4): H-3b-10';
EXEC dbo.prueba_Recibir @d1, 2, 'RECEP', 2, 2;
EXEC dbo.prueba_Recibir @d1, 4, 'RECEP', 2, 2;
SELECT 'tras recepciones' AS paso, (SELECT Cantidad FROM inv.Existencia WHERE ArticuloId = 1 AND AlmacenId = 2) AS ExistB,
       (SELECT Cantidad FROM inv.TransitoArticulo WHERE ArticuloId = 1) AS Transito, (SELECT Cantidad FROM inv.ExistenciaGlobal WHERE ArticuloId = 1) AS Global,
       (SELECT COUNT(*) FROM inv.TransferenciaAbierta) AS Abiertas, (SELECT Estado FROM inv.TransferenciaEstado WHERE DocumentoId = @d1) AS Estado,
       (SELECT COUNT(*) FROM rpt.ConciliacionTransito) AS ConcTransito, (SELECT COUNT(*) FROM rpt.ConciliacionTransferenciaAbierta) AS ConcAbierta;
SELECT DocumentoId, Linea, AlmacenId, Cantidad, Clase FROM inv.Movimiento WHERE DocumentoId = @d1 ORDER BY Id;

PRINT '--- 5. Despacho de 20 con la política «permitir» (espera 51453, T-09)';
BEGIN TRY EXEC dbo.prueba_Despachar 2, 20, 'DESP', 2, 2, @permite = 1, @doc = @d2 OUTPUT; PRINT 'NO FALLÓ'; END TRY BEGIN CATCH PRINT CONCAT('error ', ERROR_NUMBER(), ': ', ERROR_MESSAGE()); END CATCH
IF @@TRANCOUNT > 0 ROLLBACK;

PRINT '--- 6. Anular TI1 con recepciones (espera 51442 o 51313)';
BEGIN TRY EXEC dbo.prueba_Anular @d1, 'DESP'; PRINT 'NO FALLÓ'; END TRY BEGIN CATCH PRINT CONCAT('error ', ERROR_NUMBER(), ': ', ERROR_MESSAGE()); END CATCH
IF @@TRANCOUNT > 0 ROLLBACK;

PRINT '--- 7. TI3 de 1 sin salida confirmada: se anula; el tránsito vuelve a 0';
EXEC dbo.prueba_Despachar 3, 1, 'DESP', 2, 2, @doc = @d3 OUTPUT;
EXEC dbo.prueba_Anular @d3, 'DESP';
SELECT 'tras anular TI3' AS paso, (SELECT Cantidad FROM inv.Existencia WHERE ArticuloId = 1 AND AlmacenId = 1) AS ExistA,
       (SELECT Cantidad FROM inv.TransitoArticulo WHERE ArticuloId = 1) AS Transito, (SELECT Estado FROM inv.TransferenciaEstado WHERE DocumentoId = @d3) AS Estado,
       (SELECT COUNT(*) FROM inv.TransferenciaAbierta) AS Abiertas, (SELECT COUNT(*) FROM rpt.ConciliacionTransito) AS ConcTransito;

PRINT '--- 8. TI4 con salida confirmada: anular sin ANULA_TRANSITO (espera 51455)';
EXEC dbo.prueba_Despachar 4, 1, 'DESP', 2, 2, @salida = 1, @doc = @d4 OUTPUT;
BEGIN TRY EXEC dbo.prueba_Anular @d4, 'DESP'; PRINT 'NO FALLÓ'; END TRY BEGIN CATCH PRINT CONCAT('error ', ERROR_NUMBER(), ': ', ERROR_MESSAGE()); END CATCH
IF @@TRANCOUNT > 0 ROLLBACK;

PRINT '--- 9. Purga de una sesión abierta (espera 51456)';
DECLARE @s uniqueidentifier = NEWID();
INSERT INTO inv.SesionRecepcion (Id, DocumentoId, AlmacenId, SucursalId, ConteoCiego, AbiertaPor) VALUES (@s, @d4, 2, 2, 1, 'RECEP');
BEGIN TRY DELETE FROM inv.SesionRecepcion WHERE Id = @s; PRINT 'NO FALLÓ'; END TRY BEGIN CATCH PRINT CONCAT('error ', ERROR_NUMBER(), ': ', ERROR_MESSAGE()); END CATCH
PRINT '--- 9b. Segunda sesión abierta para la misma TI (espera 2601, UX_SesionRecepcion_Abierta)';
BEGIN TRY INSERT INTO inv.SesionRecepcion (Id, DocumentoId, AlmacenId, SucursalId, ConteoCiego, AbiertaPor) VALUES (NEWID(), @d4, 2, 2, 1, 'OTRO'); PRINT 'NO FALLÓ'; END TRY BEGIN CATCH PRINT CONCAT('error ', ERROR_NUMBER(), ': ', ERROR_MESSAGE()); END CATCH
UPDATE inv.SesionRecepcion SET Estado = 'X', CerradaEn = SYSUTCDATETIME() WHERE Id = @s;

PRINT '--- 10. Modificar una línea del despacho (espera 51441 o 229 por el DENY)';
BEGIN TRY UPDATE inv.TransferenciaLinea SET CostoDespacho = 1 WHERE DocumentoId = @d1; PRINT 'NO FALLÓ'; END TRY BEGIN CATCH PRINT CONCAT('error ', ERROR_NUMBER(), ': ', ERROR_MESSAGE()); END CATCH

PRINT '--- 11. Modo S: traslado de 1 del alm 1 al alm 3 (misma sucursal) por el mismo usuario; nace reconciliado';
EXEC dbo.prueba_Despachar 5, 1, 'DESP', 3, 1, @salida = 1, @doc = @d5 OUTPUT;
EXEC dbo.prueba_Recibir @d5, 1, 'DESP', 3, 1;
SELECT 'tras modo S' AS paso, (SELECT Estado FROM inv.TransferenciaEstado WHERE DocumentoId = @d5) AS Estado,
       (SELECT Cantidad FROM inv.TransitoArticulo WHERE ArticuloId = 1) AS Transito, (SELECT COUNT(*) FROM rpt.ConciliacionTransito) AS ConcTransito,
       (SELECT COUNT(*) FROM rpt.ConciliacionTransferenciaAbierta) AS ConcAbierta;

PRINT '--- 12. Recibir en un almacén que no es el destino (espera 51443)';
BEGIN TRY EXEC dbo.prueba_Recibir @d4, 1, 'RECEP', 3, 1; PRINT 'NO FALLÓ'; END TRY BEGIN CATCH PRINT CONCAT('error ', ERROR_NUMBER(), ': ', ERROR_MESSAGE()); END CATCH
IF @@TRANCOUNT > 0 ROLLBACK;
UPDATE inv.SesionRecepcion SET Estado = 'X', CerradaEn = SYSUTCDATETIME() WHERE Estado = 'A';

PRINT '--- 13. Guarda de sitio: nodo 2 activo para la sucursal B; la central recibe TI4 (espera 51440)';
EXEC sp_executesql N'DISABLE TRIGGER ALL ON sync.Nodo; INSERT INTO sync.Nodo (Id, Codigo, SucursalId, EsCentral, Local, Inhabilitado) VALUES (2, ''NODOB'', 2, 0, 0, 0); ENABLE TRIGGER ALL ON sync.Nodo;';
BEGIN TRY EXEC dbo.prueba_Recibir @d4, 1, 'RECEP', 2, 2; PRINT 'NO FALLÓ'; END TRY BEGIN CATCH PRINT CONCAT('error ', ERROR_NUMBER(), ': ', ERROR_MESSAGE()); END CATCH
IF @@TRANCOUNT > 0 ROLLBACK;
UPDATE inv.SesionRecepcion SET Estado = 'X', CerradaEn = SYSUTCDATETIME() WHERE Estado = 'A';
PRINT '--- 13b. Con el nodo 2 inhabilitado (sucesión) la central sí recibe';
EXEC sp_executesql N'DISABLE TRIGGER ALL ON sync.Nodo; UPDATE sync.Nodo SET Inhabilitado = 1 WHERE Id = 2; ENABLE TRIGGER ALL ON sync.Nodo;';
BEGIN TRY EXEC dbo.prueba_Recibir @d4, 1, 'RECEP', 2, 2; PRINT 'recibida'; END TRY BEGIN CATCH PRINT CONCAT('error ', ERROR_NUMBER(), ': ', ERROR_MESSAGE()); END CATCH
IF @@TRANCOUNT > 0 ROLLBACK;
EXEC sp_executesql N'DISABLE TRIGGER ALL ON sync.Nodo; DELETE FROM sync.Nodo WHERE Id = 2; ENABLE TRIGGER ALL ON sync.Nodo;';

PRINT '--- 14. Partes del tramo 2 cerradas: el disparador existe y rechaza';
SELECT name, is_disabled FROM sys.triggers WHERE parent_id = OBJECT_ID('inv.TransferenciaDiferencia');

PRINT '--- 15. Estado final';
SELECT (SELECT COUNT(*) FROM rpt.ConciliacionTransito) AS ConcTransito, (SELECT COUNT(*) FROM rpt.ConciliacionTransferenciaAbierta) AS ConcAbierta,
       (SELECT Cantidad FROM inv.TransitoArticulo WHERE ArticuloId = 1) AS Transito, (SELECT Cantidad FROM inv.ExistenciaGlobal WHERE ArticuloId = 1) AS Global;
SELECT d.Numero, e.Estado, e.Pendiente FROM inv.TransferenciaEstado e JOIN doc.Documento d ON d.Id = e.DocumentoId ORDER BY d.Id;
