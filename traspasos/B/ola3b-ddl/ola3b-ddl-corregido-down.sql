/* =====================================================================================================================
   GPOS NG · Ola 3b · Down de Ola3bTransferencias (T-3b-12). Solo antes de la primera transferencia: con datos, 51399 (convención del Down).
   En el código: el Down de EF borra tablas, columnas y secuencias; SqlMigracionesOla3bDown() hace lo de abajo ANTES (comprobación,
   disparadores, vistas, funciones, textos anteriores de TR_ArticuloUnidad_Factor y usp_AdelantarSecuencias, inv.ExistenciaGlobal original).
   Los textos anteriores se toman de sus constantes (SqlMigracionesOla4FactorUnidad, SqlMigracionesOla3), sin copiarlos.
   ===================================================================================================================== */
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET XACT_ABORT ON; SET NOCOUNT ON;
GO
IF OBJECT_ID(N'inv.Transferencia', N'U') IS NOT NULL
BEGIN
    IF EXISTS (SELECT 1 FROM inv.Transferencia) OR EXISTS (SELECT 1 FROM doc.Documento WHERE TipoDocumentoId = 31)
       OR EXISTS (SELECT 1 FROM inv.Movimiento WHERE Clase = 8)
       OR EXISTS (SELECT 1 FROM doc.Autorizacion WHERE Tipo IN ('DIF_TRANSFERENCIA', 'CONF_ORIGEN', 'ANULA_TRANSITO', 'REDIRECCION', 'RECONSTRUCCION'))
        THROW 51399, N'Hay transferencias registradas: Ola3bTransferencias no se revierte (reversión funcional, sección 7 del blueprint de datos).', 1;
END
GO
-- Disparadores y módulos de la 3b
IF OBJECT_ID(N'doc.TR_Documento_Transferencia', N'TR') IS NOT NULL DROP TRIGGER doc.TR_Documento_Transferencia;
DECLARE @sql nvarchar(max) = N'';
SELECT @sql = @sql + N'DROP TRIGGER ' + QUOTENAME(OBJECT_SCHEMA_NAME(t.object_id)) + N'.' + QUOTENAME(t.name) + N';' + NCHAR(10)
  FROM sys.triggers t
 WHERE t.parent_id IN (OBJECT_ID(N'inv.Transferencia'), OBJECT_ID(N'inv.TransferenciaLinea'), OBJECT_ID(N'inv.TransferenciaSerie'),
                       OBJECT_ID(N'inv.SesionRecepcion'), OBJECT_ID(N'inv.SesionRecepcionEscaneo'), OBJECT_ID(N'inv.TransferenciaRecepcion'),
                       OBJECT_ID(N'inv.TransferenciaRecepcionLinea'), OBJECT_ID(N'inv.TransferenciaRecepcionSerie'), OBJECT_ID(N'inv.TransferenciaDiferencia'),
                       OBJECT_ID(N'inv.TransferenciaConfirmacion'), OBJECT_ID(N'inv.TransferenciaImputacion'), OBJECT_ID(N'inv.TransferenciaRedireccion'),
                       OBJECT_ID(N'inv.TransferenciaReconstruccion'), OBJECT_ID(N'inv.MotivoDiferencia'));
EXEC sys.sp_executesql @sql;
GO
IF OBJECT_ID(N'rptc.TransitoArticulo', N'V') IS NOT NULL DROP VIEW rptc.TransitoArticulo;
IF OBJECT_ID(N'rpt.TransitoArticulo', N'V') IS NOT NULL DROP VIEW rpt.TransitoArticulo;
IF OBJECT_ID(N'rpt.ConciliacionTransferenciaAbierta', N'V') IS NOT NULL DROP VIEW rpt.ConciliacionTransferenciaAbierta;
IF OBJECT_ID(N'rpt.ConciliacionTransito', N'V') IS NOT NULL DROP VIEW rpt.ConciliacionTransito;
IF OBJECT_ID(N'inv.TransferenciaEstado', N'V') IS NOT NULL DROP VIEW inv.TransferenciaEstado;
IF OBJECT_ID(N'inv.TransferenciaDestinoVigente', N'V') IS NOT NULL DROP VIEW inv.TransferenciaDestinoVigente;
IF OBJECT_ID(N'sync.fn_GuardaParte', N'IF') IS NOT NULL DROP FUNCTION sync.fn_GuardaParte;
IF OBJECT_ID(N'sync.fn_SitioDuenoSucursal', N'IF') IS NOT NULL DROP FUNCTION sync.fn_SitioDuenoSucursal;
GO
CREATE OR ALTER VIEW inv.ExistenciaGlobal AS
    SELECT e.ArticuloId, SUM(e.Cantidad) AS Cantidad
      FROM inv.Existencia e
     GROUP BY e.ArticuloId
GO
-- cat.TR_ArticuloUnidad_Factor y sync.usp_AdelantarSecuencias: el código repone sus textos anteriores desde las constantes de
-- SqlMigracionesOla4FactorUnidad y SqlMigracionesOla3 (aquí, para la prueba, el texto anterior abreviado no es necesario: los dos siguen
-- compilando sin las tablas de la 3b solo si se reponen; se reponen en la prueba con el guion base). Ver el documento, sección 5.
-- (Lo que sigue lo hace el Down de EF.)
DECLARE @t nvarchar(max) = N'';
SELECT @t = @t + N'DROP TABLE ' + v.n + N';' + NCHAR(10)
  FROM (VALUES (1, N'inv.TransferenciaAbierta'), (2, N'inv.TransitoArticulo'), (3, N'inv.TransferenciaReconstruccion'), (4, N'inv.TransferenciaRedireccion'),
               (5, N'inv.TransferenciaImputacion'), (6, N'inv.TransferenciaConfirmacion'), (7, N'inv.TransferenciaDiferencia'),
               (8, N'inv.TransferenciaRecepcionSerie'), (9, N'inv.TransferenciaRecepcionLinea'), (10, N'inv.TransferenciaRecepcion'),
               (11, N'inv.SesionRecepcionEscaneo'), (12, N'inv.SesionRecepcion'), (13, N'inv.TransferenciaSerie'), (14, N'inv.TransferenciaLinea'),
               (15, N'inv.Transferencia'), (16, N'inv.MotivoDiferencia'), (17, N'inv.PlazoTransitoPar')) v (o, n)
 WHERE OBJECT_ID(v.n, N'U') IS NOT NULL
 ORDER BY v.o;
EXEC sys.sp_executesql @t;
GO
IF EXISTS (SELECT 1 FROM sys.sequences WHERE object_id = OBJECT_ID(N'inv.SecTransfRecepcion'))    DROP SEQUENCE inv.SecTransfRecepcion;
IF EXISTS (SELECT 1 FROM sys.sequences WHERE object_id = OBJECT_ID(N'inv.SecTransfDiferencia'))   DROP SEQUENCE inv.SecTransfDiferencia;
IF EXISTS (SELECT 1 FROM sys.sequences WHERE object_id = OBJECT_ID(N'inv.SecTransfConfirmacion')) DROP SEQUENCE inv.SecTransfConfirmacion;
IF EXISTS (SELECT 1 FROM sys.sequences WHERE object_id = OBJECT_ID(N'inv.SecTransfImputacion'))   DROP SEQUENCE inv.SecTransfImputacion;
IF EXISTS (SELECT 1 FROM sys.sequences WHERE object_id = OBJECT_ID(N'inv.SecTransfRedireccion'))  DROP SEQUENCE inv.SecTransfRedireccion;
DELETE FROM doc.TipoDocumento WHERE Id = 31 AND Codigo = 'TI';
GO
IF OBJECT_ID(N'conf.CK_Parametros_Transferencias', N'C') IS NOT NULL ALTER TABLE conf.Parametros DROP CONSTRAINT CK_Parametros_Transferencias;
IF OBJECT_ID(N'conf.FK_Parametros_SucursalCentral', N'F') IS NOT NULL ALTER TABLE conf.Parametros DROP CONSTRAINT FK_Parametros_SucursalCentral;
DECLARE @c nvarchar(max) = N'';
SELECT @c = @c + N'ALTER TABLE conf.Parametros DROP CONSTRAINT ' + QUOTENAME(dc.name) + N';' + NCHAR(10)
  FROM sys.default_constraints dc JOIN sys.columns col ON col.object_id = dc.parent_object_id AND col.column_id = dc.parent_column_id
 WHERE dc.parent_object_id = OBJECT_ID(N'conf.Parametros')
   AND col.name IN (N'CostosSoloEnCentral', N'SucursalCentralId', N'SalidaEnUnPaso', N'ConteoCiegoRecepcion', N'AutoautorizarDiferencias', N'DiasPlazoTransito',
                    N'DiasConfirmacionOrigen', N'DiasAvisoPerdida', N'DiasHechosPosteriores', N'ImputacionExigeAval');
EXEC sys.sp_executesql @c;
IF COL_LENGTH(N'conf.Parametros', N'CostosSoloEnCentral') IS NOT NULL
    ALTER TABLE conf.Parametros DROP COLUMN CostosSoloEnCentral, SucursalCentralId, SalidaEnUnPaso, ConteoCiegoRecepcion, AutoautorizarDiferencias,
        DiasPlazoTransito, DiasConfirmacionOrigen, DiasAvisoPerdida, DiasHechosPosteriores, ImputacionExigeAval;
GO
IF OBJECT_ID(N'inv.CK_Movimiento_Clase', N'C') IS NOT NULL ALTER TABLE inv.Movimiento DROP CONSTRAINT CK_Movimiento_Clase;
ALTER TABLE inv.Movimiento ADD CONSTRAINT CK_Movimiento_Clase CHECK (Clase BETWEEN 1 AND 7 OR Clase = 9);
ALTER TABLE doc.Autorizacion DROP CONSTRAINT CK_Autorizacion_Tipo;
ALTER TABLE doc.Autorizacion ADD CONSTRAINT CK_Autorizacion_Tipo CHECK (Tipo IN ('DESCUENTO', 'LOTE_VENCIDO', 'FUERA_PLAZO', 'EXCESO_CREDITO', 'PRECIO_MANUAL',
    'SIN_NCF', 'REVERSO_TARJETA', 'CREDITO_SIN_CONEXION', 'FECHA_ANTERIOR', 'BAJA_DEVOLUCION', 'REIMPRESION', 'DIF_PRECIO_COMPRA', 'RECIBE_NO_RECIBIDO'));
ALTER TABLE doc.Autorizacion DROP CONSTRAINT CK_Autorizacion_Motivo;
ALTER TABLE doc.Autorizacion ADD CONSTRAINT CK_Autorizacion_Motivo CHECK (Tipo NOT IN ('FECHA_ANTERIOR', 'BAJA_DEVOLUCION', 'REIMPRESION')
    OR LEN(LTRIM(RTRIM(ISNULL(Motivo, '')))) > 0);
GO
