/* =====================================================================================================================
   GPOS NG · Ola 3b (3b-2, transferencias) · DDL v3 CORREGIDO · TRAMO 1 · migración Ola3bTransferencias
   Arquitecto de datos, equipo B · 2026-10-10 · diseño: el desarrollador lo traslada a EF (TrfConfiguracion.cs) + SqlMigracionesOla3b.cs.
   Probado dos veces seguidas (idempotente), con Down y Up de nuevo, sobre GPOS_TEST_OLA3B_DDL creada con
   database/empresa/gpos-empresa-20261010130522_BitacoraLogSoloInsercion.sql (feature/modelo-ng e7f1f96) en .\SQLEXPRESS (SQL Server 2025 Express).

   Corrige el DDL de 2026-10-07 (docs/datos/2026-10-07-ola3b-ddl.sql):
   - H-3b-10  línea del kárdex por parte: Linea = L + 10000 × k, k = 1000 × T + n (T = tipo de parte, n = consecutivo de la parte). Ver PARTE 2.0.
   - H-3b-11  errores 51440 a 51459 (firmado en ADR-100, precisión 5). Los de 3b-A ya no caben aquí: ver la pregunta P-D1.
   - H-3b-12  CK_Movimiento_Clase = «Clase BETWEEN 1 AND 9» (conserva la 9 de D-MVP-02 y CK_Movimiento_Valor).
   - H-3b-13  las 5 secuencias nuevas entran en SecuenciasNodo.Todas, en DisparadoresNg.RangoNodo y en sync.usp_AdelantarSecuencias.
   - H-3b-14  (código) Afectados bloquea ArticuloCosto en toda salida de clase 8: tramo 2; aquí solo se documenta.
   - H-3b-15  T-09: red en la base (51453) en la emisión de la TI, además de SalidaEstricta en el servicio.
   - H-3b-16  doc.TR_Documento_Transferencia sale en la segunda sentencia si el lote no tiene tipo 31.
   - H-3b-17  rpt.TransitoArticulo y rptc.TransitoArticulo (valor = cantidad × promedio de la empresa, como rptc.ExistenciaActual y la foto).
   - 3b-A (adjuntos, tipo 32 DAJ, familia SIS, AniosConservacion, MesCierreEjercicio) sale de este script: va en Ola3bAdjuntos (tramo 3).

   Errores del motor (franja 51440-51459):
   51440 PARTE_DE_OTRO_SITIO 409 · 51441 PARTE_INMUTABLE 500 · 51442 TRANSFERENCIA_CON_PARTES 409 · 51443 DESTINO_NO_VIGENTE 409
   51444 IMPUTACION_SOLO_CENTRAL 403 (T2) · 51445 MOTIVO_CON_MOVIMIENTOS 409 · 51446 REDIRECCION_NO_PERMITIDA 409 (T2)
   51447 SUCURSAL_RESPONSABLE_INVALIDA 422 (T2) · 51448 IMPUTACION_NO_PERDIDA 422 (T2) · 51449 CONFIRMACION_NO_ADMITIDA 409 (T2)
   51450 RECONSTRUCCION_SIN_SUCESION 409 (E2) · 51451 FUNCION_INCOMPATIBLE 403 · 51452 FECHA_PARTE 500 · 51453 EXISTENCIA_INSUFICIENTE 409 (T-09)
   51454 TRANSFERENCIA_INCONSISTENTE 500 · 51455 AUTORIZACION_INVALIDA 422 (anular en tránsito) · 51456 SESION_NO_PURGABLE 500
   51457 TRANSFERENCIA_NO_VIGENTE 409 · 51458 y 51459 reservados (tramos 2 y 3 de la 3b-2).
   Se reutilizan 51330 (base restaurada o emisión bloqueada), 51332 (rango del nodo) y 51333 (período cerrado, por TR_Movimiento_PeriodoCerrado).
   ===================================================================================================================== */
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
SET NOCOUNT ON;
GO

/* =====================================================================================================================
   PARTE 0 · Comprobación previa (convención 51399): no hay movimientos de clase 8 de una 3b parcial ni tipo 31 ajeno
   ===================================================================================================================== */
IF EXISTS (SELECT 1 FROM doc.TipoDocumento WHERE Id = 31 AND Codigo <> 'TI')
    THROW 51399, N'El tipo de documento 31 ya existe con otro código: no se puede aplicar Ola3bTransferencias.', 1;
GO

/* =====================================================================================================================
   PARTE 1 · LO QUE GENERA EF (modelo: TrfConfiguracion.cs, SecuenciasNodo, InvConfiguracion, DocConfiguracion, CfgConfiguracion)
   Aquí en SQL idempotente equivalente, con los MISMOS nombres de objetos que debe producir el mapeo.
   ===================================================================================================================== */

-- 1.1 Secuencias de llave por nodo (rango del nodo 1, como el resto de SecuenciasNodo; AjustarSecuenciasAsync fija otro nodo). H-3b-13
IF NOT EXISTS (SELECT 1 FROM sys.sequences WHERE object_id = OBJECT_ID(N'inv.SecTransfRecepcion'))
    CREATE SEQUENCE inv.SecTransfRecepcion AS bigint START WITH 1000000000001 INCREMENT BY 1 MINVALUE 1000000000001 MAXVALUE 1999999999999 NO CYCLE;
IF NOT EXISTS (SELECT 1 FROM sys.sequences WHERE object_id = OBJECT_ID(N'inv.SecTransfDiferencia'))
    CREATE SEQUENCE inv.SecTransfDiferencia AS bigint START WITH 1000000000001 INCREMENT BY 1 MINVALUE 1000000000001 MAXVALUE 1999999999999 NO CYCLE;
IF NOT EXISTS (SELECT 1 FROM sys.sequences WHERE object_id = OBJECT_ID(N'inv.SecTransfConfirmacion'))
    CREATE SEQUENCE inv.SecTransfConfirmacion AS bigint START WITH 1000000000001 INCREMENT BY 1 MINVALUE 1000000000001 MAXVALUE 1999999999999 NO CYCLE;
IF NOT EXISTS (SELECT 1 FROM sys.sequences WHERE object_id = OBJECT_ID(N'inv.SecTransfImputacion'))
    CREATE SEQUENCE inv.SecTransfImputacion AS bigint START WITH 1000000000001 INCREMENT BY 1 MINVALUE 1000000000001 MAXVALUE 1999999999999 NO CYCLE;
IF NOT EXISTS (SELECT 1 FROM sys.sequences WHERE object_id = OBJECT_ID(N'inv.SecTransfRedireccion'))
    CREATE SEQUENCE inv.SecTransfRedireccion AS bigint START WITH 1000000000001 INCREMENT BY 1 MINVALUE 1000000000001 MAXVALUE 1999999999999 NO CYCLE;
GO

-- 1.2 Parámetros de la 3b-2 (conf.Parametros es temporal: el ALTER propaga las columnas a conf.ParametrosHistorial).
--     AniosConservacion y MesCierreEjercicio son de 3b-A: NO van aquí.
IF COL_LENGTH(N'conf.Parametros', N'CostosSoloEnCentral') IS NULL
    ALTER TABLE conf.Parametros ADD
        CostosSoloEnCentral      bit      NOT NULL CONSTRAINT DF_Parametros_CostosSoloEnCentral      DEFAULT (CONVERT(bit, 0)),
        SucursalCentralId        smallint NOT NULL CONSTRAINT DF_Parametros_SucursalCentralId        DEFAULT (CONVERT(smallint, 1)),
        SalidaEnUnPaso           bit      NOT NULL CONSTRAINT DF_Parametros_SalidaEnUnPaso           DEFAULT (CONVERT(bit, 0)),
        ConteoCiegoRecepcion     bit      NOT NULL CONSTRAINT DF_Parametros_ConteoCiegoRecepcion     DEFAULT (CONVERT(bit, 1)),
        AutoautorizarDiferencias bit      NOT NULL CONSTRAINT DF_Parametros_AutoautorizarDiferencias DEFAULT (CONVERT(bit, 0)),
        DiasPlazoTransito        tinyint  NOT NULL CONSTRAINT DF_Parametros_DiasPlazoTransito        DEFAULT (CONVERT(tinyint, 2)),
        DiasConfirmacionOrigen   tinyint  NOT NULL CONSTRAINT DF_Parametros_DiasConfirmacionOrigen   DEFAULT (CONVERT(tinyint, 3)),
        DiasAvisoPerdida         smallint NOT NULL CONSTRAINT DF_Parametros_DiasAvisoPerdida         DEFAULT (CONVERT(smallint, 30)),
        DiasHechosPosteriores    smallint NOT NULL CONSTRAINT DF_Parametros_DiasHechosPosteriores    DEFAULT (CONVERT(smallint, 30)),
        ImputacionExigeAval      bit      NOT NULL CONSTRAINT DF_Parametros_ImputacionExigeAval      DEFAULT (CONVERT(bit, 0));
GO
IF OBJECT_ID(N'conf.FK_Parametros_SucursalCentral', N'F') IS NULL
    ALTER TABLE conf.Parametros ADD CONSTRAINT FK_Parametros_SucursalCentral FOREIGN KEY (SucursalCentralId) REFERENCES org.Sucursal (Id);
IF OBJECT_ID(N'conf.CK_Parametros_Transferencias', N'C') IS NULL
    ALTER TABLE conf.Parametros ADD CONSTRAINT CK_Parametros_Transferencias CHECK (
        DiasPlazoTransito BETWEEN 1 AND 60 AND DiasConfirmacionOrigen BETWEEN 1 AND 30
        AND DiasAvisoPerdida BETWEEN 1 AND 365 AND DiasHechosPosteriores BETWEEN 1 AND 365);
GO

-- 1.3 H-3b-12: clase 8 admitida sin perder la 9 (ClasesMovimiento.CheckClase = "Clase BETWEEN 1 AND 9"; EF hace DROP/ADD)
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Movimiento_Clase' AND parent_object_id = OBJECT_ID(N'inv.Movimiento')
                  AND definition = N'([Clase]>=(1) AND [Clase]<=(9))')
BEGIN
    IF OBJECT_ID(N'inv.CK_Movimiento_Clase', N'C') IS NOT NULL ALTER TABLE inv.Movimiento DROP CONSTRAINT CK_Movimiento_Clase;
    ALTER TABLE inv.Movimiento ADD CONSTRAINT CK_Movimiento_Clase CHECK (Clase BETWEEN 1 AND 9);
END
GO

-- 1.4 Tipos de autorización de la 3b-2 sobre la lista VIGENTE (DocConfiguracion.cs; quien una segundo la rehace completa)
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Autorizacion_Tipo' AND definition LIKE N'%ANULA_TRANSITO%')
BEGIN
    IF OBJECT_ID(N'doc.CK_Autorizacion_Tipo', N'C') IS NOT NULL ALTER TABLE doc.Autorizacion DROP CONSTRAINT CK_Autorizacion_Tipo;
    ALTER TABLE doc.Autorizacion ADD CONSTRAINT CK_Autorizacion_Tipo CHECK (Tipo IN (
        'DESCUENTO', 'LOTE_VENCIDO', 'FUERA_PLAZO', 'EXCESO_CREDITO', 'PRECIO_MANUAL', 'SIN_NCF', 'REVERSO_TARJETA', 'CREDITO_SIN_CONEXION',
        'FECHA_ANTERIOR', 'BAJA_DEVOLUCION', 'REIMPRESION', 'DIF_PRECIO_COMPRA', 'RECIBE_NO_RECIBIDO',
        'DIF_TRANSFERENCIA', 'CONF_ORIGEN', 'ANULA_TRANSITO', 'REDIRECCION', 'RECONSTRUCCION'));
END
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Autorizacion_Motivo' AND definition LIKE N'%ANULA_TRANSITO%')
BEGIN
    IF OBJECT_ID(N'doc.CK_Autorizacion_Motivo', N'C') IS NOT NULL ALTER TABLE doc.Autorizacion DROP CONSTRAINT CK_Autorizacion_Motivo;
    ALTER TABLE doc.Autorizacion ADD CONSTRAINT CK_Autorizacion_Motivo CHECK (
        Tipo NOT IN ('FECHA_ANTERIOR', 'BAJA_DEVOLUCION', 'REIMPRESION', 'ANULA_TRANSITO') OR LEN(LTRIM(RTRIM(ISNULL(Motivo, '')))) > 0);
END
GO

-- 1.5 Plazo por par de sucursales ([TRF] 7.1)
IF OBJECT_ID(N'inv.PlazoTransitoPar', N'U') IS NULL
CREATE TABLE inv.PlazoTransitoPar (
    SucursalOrigenId  smallint     NOT NULL CONSTRAINT FK_PlazoPar_Origen  REFERENCES org.Sucursal (Id),
    SucursalDestinoId smallint     NOT NULL CONSTRAINT FK_PlazoPar_Destino REFERENCES org.Sucursal (Id),
    Dias              tinyint      NOT NULL CONSTRAINT CK_PlazoPar_Dias CHECK (Dias BETWEEN 1 AND 60),
    ModificadoPor     varchar(60)  NOT NULL,
    ModificadoEn      datetime2(3) NOT NULL CONSTRAINT DF_PlazoPar_En DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_PlazoTransitoPar PRIMARY KEY (SucursalOrigenId, SucursalDestinoId),
    CONSTRAINT CK_PlazoPar_Distintas CHECK (SucursalOrigenId <> SucursalDestinoId)
);
GO

-- 1.6 Maestro de motivos (tratamientos P, V, N, S y C; dueño: central). Se siembra en la PARTE 2.
IF OBJECT_ID(N'inv.MotivoDiferencia', N'U') IS NULL
CREATE TABLE inv.MotivoDiferencia (
    Id              smallint     IDENTITY(1, 1) NOT NULL CONSTRAINT PK_MotivoDiferencia PRIMARY KEY,
    Codigo          varchar(10)  NOT NULL CONSTRAINT UQ_MotivoDiferencia_Codigo UNIQUE,
    Descripcion     varchar(80)  NOT NULL,
    Tratamiento     char(1)      NOT NULL,
    ExigirEvidencia bit          NOT NULL CONSTRAINT DF_MotivoDiferencia_Evidencia  DEFAULT (CONVERT(bit, 0)),
    PedirReferencia bit          NOT NULL CONSTRAINT DF_MotivoDiferencia_Referencia DEFAULT (CONVERT(bit, 0)),
    UsoOrigen       bit          NOT NULL CONSTRAINT DF_MotivoDiferencia_UsoOrigen  DEFAULT (CONVERT(bit, 0)),
    Inhabilitado    bit          NOT NULL CONSTRAINT DF_MotivoDiferencia_Inhab      DEFAULT (CONVERT(bit, 0)),
    ModificadoPor   varchar(60)  NOT NULL,
    ModificadoEn    datetime2(3) NOT NULL CONSTRAINT DF_MotivoDiferencia_En DEFAULT (SYSUTCDATETIME()),
    Version         rowversion   NOT NULL,
    CONSTRAINT CK_MotivoDiferencia_Tratamiento CHECK (Tratamiento IN ('P', 'V', 'N', 'S', 'C')),
    CONSTRAINT CK_MotivoDiferencia_Codigo      CHECK (LEN(Codigo) > 0 AND Codigo COLLATE Latin1_General_BIN2 NOT LIKE '%[^A-Z0-9_-]%')
);
GO

-- 1.7 Despacho: cabecera (subtipo de doc.Documento tipo 31; parte del origen)
IF OBJECT_ID(N'inv.Transferencia', N'U') IS NULL
CREATE TABLE inv.Transferencia (
    DocumentoId           bigint        NOT NULL CONSTRAINT PK_Transferencia PRIMARY KEY
                                                 CONSTRAINT FK_Transferencia_Documento REFERENCES doc.Documento (Id),
    Modo                  char(1)       NOT NULL,
    AlmacenOrigenId       smallint      NOT NULL,
    SucursalOrigenId      smallint      NOT NULL,
    AlmacenDestinoId      smallint      NOT NULL,
    SucursalDestinoId     smallint      NOT NULL,
    PlazoDias             tinyint       NOT NULL,
    TotalLineas           smallint      NOT NULL,
    TotalUnidades         decimal(18,6) NOT NULL,
    Huella                binary(32)    NOT NULL,
    Transportista         varchar(80)   NULL,
    Vehiculo              varchar(30)   NULL,
    SalidaConfirmadaEn    datetime2(3)  NULL,
    SalidaConfirmadaPorId int           NULL,     -- reservado hasta ADR-34 (H-3b-04)
    SalidaConfirmadaPor   varchar(60)   NULL,
    Version               rowversion    NOT NULL,
    CONSTRAINT FK_Transferencia_Origen  FOREIGN KEY (AlmacenOrigenId, SucursalOrigenId)   REFERENCES org.Almacen (Id, SucursalId),
    CONSTRAINT FK_Transferencia_Destino FOREIGN KEY (AlmacenDestinoId, SucursalDestinoId) REFERENCES org.Almacen (Id, SucursalId),
    CONSTRAINT CK_Transferencia_Modo CHECK ((Modo = 'S' AND SucursalOrigenId = SucursalDestinoId) OR (Modo = 'E' AND SucursalOrigenId <> SucursalDestinoId)),
    CONSTRAINT CK_Transferencia_Almacenes CHECK (AlmacenOrigenId <> AlmacenDestinoId),
    CONSTRAINT CK_Transferencia_Totales   CHECK (TotalLineas BETWEEN 1 AND 2000 AND TotalUnidades > 0 AND PlazoDias BETWEEN 1 AND 60),
    CONSTRAINT CK_Transferencia_Salida    CHECK ((SalidaConfirmadaEn IS NULL AND SalidaConfirmadaPor IS NULL AND SalidaConfirmadaPorId IS NULL)
                                              OR (SalidaConfirmadaEn IS NOT NULL AND SalidaConfirmadaPor IS NOT NULL))
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Transferencia_Destino' AND object_id = OBJECT_ID(N'inv.Transferencia'))
    CREATE INDEX IX_Transferencia_Destino ON inv.Transferencia (SucursalDestinoId, DocumentoId) INCLUDE (AlmacenDestinoId, SucursalOrigenId, SalidaConfirmadaEn);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Transferencia_Origen' AND object_id = OBJECT_ID(N'inv.Transferencia'))
    CREATE INDEX IX_Transferencia_Origen ON inv.Transferencia (SucursalOrigenId, DocumentoId) INCLUDE (AlmacenOrigenId, SucursalDestinoId, SalidaConfirmadaEn);
GO

-- 1.8 Líneas y series del despacho. Una línea = un artículo y como máximo un lote.
IF OBJECT_ID(N'inv.TransferenciaLinea', N'U') IS NULL
CREATE TABLE inv.TransferenciaLinea (
    DocumentoId        bigint        NOT NULL CONSTRAINT FK_TransfLinea_Transferencia REFERENCES inv.Transferencia (DocumentoId),
    Linea              smallint      NOT NULL,
    ArticuloId         int           NOT NULL CONSTRAINT FK_TransfLinea_Articulo REFERENCES cat.Articulo (Id),
    UnidadId           smallint      NOT NULL,
    FactorUnidad       decimal(19,6) NOT NULL,
    CantidadUnidad     decimal(18,6) NOT NULL,
    Cantidad           decimal(18,6) NOT NULL,     -- unidad base = ROUND(CantidadUnidad × FactorUnidad, 6) (ADR-78)
    LoteId             bigint        NULL CONSTRAINT FK_TransfLinea_Lote REFERENCES inv.Lote (Id),
    MotivoLoteVencido  varchar(200)  NULL,         -- D3 de [TRF]: lote vencido solo con advertencia y motivo
    CostoDespacho      decimal(19,6) NOT NULL,     -- [DatoCosto] promedio vigente en A1, congelado ([RC] T-01, R-05)
    MovimientoSalidaId bigint        NOT NULL CONSTRAINT FK_TransfLinea_Movimiento REFERENCES inv.Movimiento (Id),
    CONSTRAINT PK_TransferenciaLinea PRIMARY KEY (DocumentoId, Linea),
    CONSTRAINT FK_TransfLinea_Unidad FOREIGN KEY (ArticuloId, UnidadId) REFERENCES cat.ArticuloUnidad (ArticuloId, UnidadId),
    CONSTRAINT CK_TransfLinea_Valores CHECK (Linea BETWEEN 1 AND 2000 AND FactorUnidad > 0 AND CantidadUnidad > 0 AND Cantidad > 0 AND CostoDespacho >= 0
                                             AND Cantidad = ROUND(CantidadUnidad * FactorUnidad, 6)),
    CONSTRAINT CK_TransfLinea_MotivoLote CHECK (MotivoLoteVencido IS NULL OR (LoteId IS NOT NULL AND LEN(LTRIM(RTRIM(MotivoLoteVencido))) >= 10))
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_TransferenciaLinea_Articulo' AND object_id = OBJECT_ID(N'inv.TransferenciaLinea'))
    CREATE INDEX IX_TransferenciaLinea_Articulo ON inv.TransferenciaLinea (ArticuloId, LoteId) INCLUDE (UnidadId, Cantidad);
GO
IF OBJECT_ID(N'inv.TransferenciaSerie', N'U') IS NULL
CREATE TABLE inv.TransferenciaSerie (
    DocumentoId   bigint   NOT NULL,
    Linea         smallint NOT NULL,
    NumeroSerieId bigint   NOT NULL CONSTRAINT FK_TransfSerie_Serie REFERENCES inv.NumeroSerie (Id),
    CONSTRAINT PK_TransferenciaSerie PRIMARY KEY (DocumentoId, Linea, NumeroSerieId),
    CONSTRAINT FK_TransfSerie_Linea FOREIGN KEY (DocumentoId, Linea) REFERENCES inv.TransferenciaLinea (DocumentoId, Linea)
);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_TransferenciaSerie_Serie' AND object_id = OBJECT_ID(N'inv.TransferenciaSerie'))
    CREATE UNIQUE INDEX UX_TransferenciaSerie_Serie ON inv.TransferenciaSerie (NumeroSerieId, DocumentoId);
GO

-- 1.9 Sesión de recepción (borrador; se purga a los 30 días de cerrarse, P-3b-03 A). Sin FK desde la recepción (la purga la borra).
IF OBJECT_ID(N'inv.SesionRecepcion', N'U') IS NULL
CREATE TABLE inv.SesionRecepcion (
    Id           uniqueidentifier NOT NULL CONSTRAINT PK_SesionRecepcion PRIMARY KEY NONCLUSTERED,
    DocumentoId  bigint           NOT NULL CONSTRAINT FK_SesionRecepcion_Transf REFERENCES inv.Transferencia (DocumentoId),
    AlmacenId    smallint         NOT NULL,
    SucursalId   smallint         NOT NULL,
    Estado       char(1)          NOT NULL CONSTRAINT DF_SesionRecepcion_Estado DEFAULT ('A'),
    ConteoCiego  bit              NOT NULL,
    AbiertaPorId int              NULL,        -- reservado hasta ADR-34 (H-3b-04)
    AbiertaPor   varchar(60)      NOT NULL,
    AbiertaEn    datetime2(3)     NOT NULL CONSTRAINT DF_SesionRecepcion_En DEFAULT (SYSUTCDATETIME()),
    TerminadaEn  datetime2(3)     NULL,        -- [SW3B] 16.8: «terminar» revela lo esperado (T-12)
    CerradaEn    datetime2(3)     NULL,
    CONSTRAINT FK_SesionRecepcion_Almacen FOREIGN KEY (AlmacenId, SucursalId) REFERENCES org.Almacen (Id, SucursalId),
    CONSTRAINT CK_SesionRecepcion_Estado CHECK ((Estado = 'A' AND CerradaEn IS NULL) OR (Estado IN ('C', 'X') AND CerradaEn IS NOT NULL))
);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_SesionRecepcion_Abierta' AND object_id = OBJECT_ID(N'inv.SesionRecepcion'))
    CREATE UNIQUE INDEX UX_SesionRecepcion_Abierta ON inv.SesionRecepcion (DocumentoId) WHERE Estado = 'A';
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SesionRecepcion_Purga' AND object_id = OBJECT_ID(N'inv.SesionRecepcion'))
    CREATE INDEX IX_SesionRecepcion_Purga ON inv.SesionRecepcion (CerradaEn) WHERE Estado IN ('C', 'X');
GO
IF OBJECT_ID(N'inv.SesionRecepcionEscaneo', N'U') IS NULL
CREATE TABLE inv.SesionRecepcionEscaneo (
    SesionId   uniqueidentifier NOT NULL CONSTRAINT FK_Escaneo_Sesion REFERENCES inv.SesionRecepcion (Id),
    EscaneoId  uniqueidentifier NOT NULL,     -- lo genera el cliente por lectura: el reintento no suma dos veces (ADR-105)
    ArticuloId int              NOT NULL CONSTRAINT FK_Escaneo_Articulo REFERENCES cat.Articulo (Id),
    LoteId     bigint           NULL CONSTRAINT FK_Escaneo_Lote REFERENCES inv.Lote (Id),
    SerieTexto varchar(50)      NULL,
    Cantidad   decimal(18,6)    NOT NULL CONSTRAINT CK_Escaneo_Cantidad CHECK (Cantidad > 0),
    Origen     char(1)          NOT NULL CONSTRAINT CK_Escaneo_Origen CHECK (Origen IN ('E', 'D')),
    NoEsperado bit              NOT NULL CONSTRAINT DF_Escaneo_NoEsperado DEFAULT (CONVERT(bit, 0)),   -- [SW3B] 16.8
    UsuarioId  int              NULL,
    Usuario    varchar(60)      NOT NULL,
    En         datetime2(3)     NOT NULL CONSTRAINT DF_Escaneo_En DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_SesionRecepcionEscaneo PRIMARY KEY (SesionId, EscaneoId)
);
GO

-- 1.10 Recepción (parte del destino)
IF OBJECT_ID(N'inv.TransferenciaRecepcion', N'U') IS NULL
CREATE TABLE inv.TransferenciaRecepcion (
    Id              bigint           NOT NULL CONSTRAINT DF_TransfRecepcion_Id DEFAULT (NEXT VALUE FOR inv.SecTransfRecepcion)
                                              CONSTRAINT PK_TransferenciaRecepcion PRIMARY KEY,
    NodoOrigenId    AS (CONVERT(smallint, Id / 1000000000000)) PERSISTED,
    DocumentoId     bigint           NOT NULL CONSTRAINT FK_TransfRecepcion_Transf REFERENCES inv.Transferencia (DocumentoId),
    Consecutivo     smallint         NOT NULL,     -- R1, R2…; n de la línea del kárdex (T = 1)
    SesionId        uniqueidentifier NOT NULL CONSTRAINT UQ_Recepcion_Sesion UNIQUE,
    AlmacenId       smallint         NOT NULL,
    SucursalId      smallint         NOT NULL,
    Fecha           date             NOT NULL,     -- hoy de la empresa (T-02)
    CierraSaldo     bit              NOT NULL CONSTRAINT DF_TransfRecepcion_Cierra DEFAULT (CONVERT(bit, 0)),
    TipoCarga       char(1)          NOT NULL CONSTRAINT DF_TransfRecepcion_Carga DEFAULT ('N'),
    HuellaSolicitud binary(32)       NULL,
    RegistradoPorId int              NULL,         -- reservado hasta ADR-34 (H-3b-04)
    RegistradoPor   varchar(60)      NOT NULL,
    RegistradoEn    datetime2(3)     NOT NULL CONSTRAINT DF_TransfRecepcion_En DEFAULT (SYSUTCDATETIME()),
    Version         rowversion       NOT NULL,
    CONSTRAINT UQ_Recepcion_IdDocumento  UNIQUE (Id, DocumentoId),
    CONSTRAINT UQ_Recepcion_Consecutivo  UNIQUE (DocumentoId, Consecutivo),
    CONSTRAINT FK_TransfRecepcion_Almacen FOREIGN KEY (AlmacenId, SucursalId) REFERENCES org.Almacen (Id, SucursalId),
    CONSTRAINT CK_TransfRecepcion_Valores CHECK (Consecutivo BETWEEN 1 AND 999 AND TipoCarga IN ('N', 'Q', 'U', 'D')
                                                 AND (HuellaSolicitud IS NULL OR DATALENGTH(HuellaSolicitud) = 32))
);
GO
IF OBJECT_ID(N'inv.TransferenciaRecepcionLinea', N'U') IS NULL
CREATE TABLE inv.TransferenciaRecepcionLinea (
    RecepcionId         bigint        NOT NULL,
    DocumentoId         bigint        NOT NULL,
    Linea               smallint      NOT NULL,
    Cantidad            decimal(18,6) NOT NULL CONSTRAINT CK_TransfRecLinea_Cantidad CHECK (Cantidad > 0),
    MovimientoEntradaId bigint        NOT NULL CONSTRAINT FK_TransfRecLinea_Mov REFERENCES inv.Movimiento (Id),
    CONSTRAINT PK_TransferenciaRecepcionLinea PRIMARY KEY (RecepcionId, Linea),
    CONSTRAINT FK_TransfRecLinea_Recepcion FOREIGN KEY (RecepcionId, DocumentoId) REFERENCES inv.TransferenciaRecepcion (Id, DocumentoId),
    CONSTRAINT FK_TransfRecLinea_Linea     FOREIGN KEY (DocumentoId, Linea)       REFERENCES inv.TransferenciaLinea (DocumentoId, Linea)
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_TransfRecLinea_DocumentoLinea' AND object_id = OBJECT_ID(N'inv.TransferenciaRecepcionLinea'))
    CREATE INDEX IX_TransfRecLinea_DocumentoLinea ON inv.TransferenciaRecepcionLinea (DocumentoId, Linea) INCLUDE (Cantidad);
GO
IF OBJECT_ID(N'inv.TransferenciaRecepcionSerie', N'U') IS NULL
CREATE TABLE inv.TransferenciaRecepcionSerie (
    RecepcionId   bigint   NOT NULL,
    DocumentoId   bigint   NOT NULL,
    Linea         smallint NOT NULL,
    NumeroSerieId bigint   NOT NULL,
    CONSTRAINT PK_TransferenciaRecepcionSerie PRIMARY KEY (RecepcionId, NumeroSerieId),
    CONSTRAINT UX_TransfRecSerie_Serie UNIQUE (DocumentoId, NumeroSerieId),
    CONSTRAINT FK_TransfRecSerie_Recepcion FOREIGN KEY (RecepcionId, DocumentoId) REFERENCES inv.TransferenciaRecepcion (Id, DocumentoId),
    CONSTRAINT FK_TransfRecSerie_Despacho  FOREIGN KEY (DocumentoId, Linea, NumeroSerieId) REFERENCES inv.TransferenciaSerie (DocumentoId, Linea, NumeroSerieId)
);
GO

-- 1.11 Partes del tramo 2 y de la entrega 2: se crean YA (vacías) para no reescribir tablas; un disparador las mantiene cerradas hasta
--      que Ola3bDiferencias (tramo 2) instale sus reglas. Diferencia gana Consecutivo (n de la línea del kárdex, H-3b-10).
IF OBJECT_ID(N'inv.TransferenciaDiferencia', N'U') IS NULL
CREATE TABLE inv.TransferenciaDiferencia (
    Id                  bigint           NOT NULL CONSTRAINT DF_TransfDif_Id DEFAULT (NEXT VALUE FOR inv.SecTransfDiferencia)
                                                  CONSTRAINT PK_TransferenciaDiferencia PRIMARY KEY,
    NodoOrigenId        AS (CONVERT(smallint, Id / 1000000000000)) PERSISTED,
    DocumentoId         bigint           NOT NULL CONSTRAINT FK_TransfDif_Transf REFERENCES inv.Transferencia (DocumentoId),
    Consecutivo         smallint         NOT NULL,     -- D1, D2…; n de la línea del kárdex (T = 2 y 3; su confirmación, T = 4 y 5)
    Clase               char(1)          NOT NULL,
    Linea               smallint         NULL,
    ArticuloId          int              NOT NULL CONSTRAINT FK_TransfDif_Articulo REFERENCES cat.Articulo (Id),
    LoteId              bigint           NULL CONSTRAINT FK_TransfDif_Lote REFERENCES inv.Lote (Id),
    ArticuloRecibidoId  int              NULL CONSTRAINT FK_TransfDif_ArtRecibido REFERENCES cat.Articulo (Id),
    LoteRecibidoId      bigint           NULL CONSTRAINT FK_TransfDif_LoteRecibido REFERENCES inv.Lote (Id),
    Cantidad            decimal(18,6)    NOT NULL,
    MotivoId            smallint         NOT NULL CONSTRAINT FK_TransfDif_Motivo REFERENCES inv.MotivoDiferencia (Id),
    Tratamiento         char(1)          NOT NULL,
    ExigeEvidencia      bit              NOT NULL,
    PideReferencia      bit              NOT NULL,
    NumeroReferencia    varchar(40)      NULL,
    Observacion         varchar(200)     NULL,
    RecepcionId         bigint           NULL,
    Fecha               date             NOT NULL,
    MovimientoId        bigint           NULL CONSTRAINT FK_TransfDif_Movimiento  REFERENCES inv.Movimiento (Id),
    MovimientoEntradaId bigint           NULL CONSTRAINT FK_TransfDif_MovEntrada  REFERENCES inv.Movimiento (Id),
    CostoUnitario       decimal(19,6)    NULL,
    CostoDespacho       decimal(19,6)    NULL,
    AutorizacionId      bigint           NOT NULL CONSTRAINT FK_TransfDif_Autorizacion REFERENCES doc.Autorizacion (Id),
    Autoautorizada      bit              NOT NULL CONSTRAINT DF_TransfDif_Auto DEFAULT (CONVERT(bit, 0)),
    ClaveIdempotencia   uniqueidentifier NULL,
    HuellaSolicitud     binary(32)       NULL,
    RegistradoPorId     int              NULL,
    RegistradoPor       varchar(60)      NOT NULL,
    RegistradoEn        datetime2(3)     NOT NULL CONSTRAINT DF_TransfDif_En DEFAULT (SYSUTCDATETIME()),
    Version             rowversion       NOT NULL,
    CONSTRAINT UQ_TransfDif_IdDocumento  UNIQUE (Id, DocumentoId),
    CONSTRAINT UQ_TransfDif_Consecutivo  UNIQUE (DocumentoId, Consecutivo),
    CONSTRAINT FK_TransfDif_Linea     FOREIGN KEY (DocumentoId, Linea)       REFERENCES inv.TransferenciaLinea (DocumentoId, Linea),
    CONSTRAINT FK_TransfDif_Recepcion FOREIGN KEY (RecepcionId, DocumentoId) REFERENCES inv.TransferenciaRecepcion (Id, DocumentoId),
    CONSTRAINT CK_TransfDif_Cantidad  CHECK (Cantidad > 0 AND Consecutivo BETWEEN 1 AND 999),
    CONSTRAINT CK_TransfDif_Referencia CHECK (PideReferencia = 0 OR (NumeroReferencia IS NOT NULL AND LEN(NumeroReferencia) > 0)),
    CONSTRAINT CK_TransfDif_Clase CHECK (
           (Clase = 'F' AND Linea IS NOT NULL AND Tratamiento = 'P' AND MovimientoId IS NOT NULL AND MovimientoEntradaId IS NOT NULL AND ArticuloRecibidoId IS NULL)
        OR (Clase = 'F' AND Linea IS NOT NULL AND Tratamiento = 'V' AND MovimientoId IS NULL AND MovimientoEntradaId IS NULL AND ArticuloRecibidoId IS NULL)
        OR (Clase = 'N' AND Linea IS NOT NULL AND Tratamiento = 'N' AND MovimientoId IS NOT NULL AND MovimientoEntradaId IS NULL AND ArticuloRecibidoId IS NULL)
        OR (Clase = 'S' AND Tratamiento = 'S' AND MovimientoId IS NOT NULL AND MovimientoEntradaId IS NULL AND ArticuloRecibidoId IS NULL)
        OR (Clase = 'C' AND Linea IS NOT NULL AND Tratamiento = 'C' AND MovimientoId IS NOT NULL AND MovimientoEntradaId IS NULL AND ArticuloRecibidoId IS NOT NULL))
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_TransfDif_Documento' AND object_id = OBJECT_ID(N'inv.TransferenciaDiferencia'))
    CREATE INDEX IX_TransfDif_Documento ON inv.TransferenciaDiferencia (DocumentoId) INCLUDE (Clase, Tratamiento, Cantidad, Linea);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_TransfDif_Perdida' AND object_id = OBJECT_ID(N'inv.TransferenciaDiferencia'))
    CREATE INDEX IX_TransfDif_Perdida ON inv.TransferenciaDiferencia (Fecha) INCLUDE (DocumentoId, Cantidad) WHERE Tratamiento = 'P';
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_TransfDif_Idempotencia' AND object_id = OBJECT_ID(N'inv.TransferenciaDiferencia'))
    CREATE UNIQUE INDEX UX_TransfDif_Idempotencia ON inv.TransferenciaDiferencia (ClaveIdempotencia) WHERE ClaveIdempotencia IS NOT NULL;
GO
IF OBJECT_ID(N'inv.TransferenciaConfirmacion', N'U') IS NULL
CREATE TABLE inv.TransferenciaConfirmacion (
    Id                 bigint           NOT NULL CONSTRAINT DF_TransfConf_Id DEFAULT (NEXT VALUE FOR inv.SecTransfConfirmacion)
                                                 CONSTRAINT PK_TransferenciaConfirmacion PRIMARY KEY,
    NodoOrigenId       AS (CONVERT(smallint, Id / 1000000000000)) PERSISTED,
    DocumentoId        bigint           NOT NULL,
    DiferenciaId       bigint           NOT NULL,
    Resultado          char(1)          NOT NULL,
    Cantidad           decimal(18,6)    NOT NULL CONSTRAINT CK_TransfConf_Cantidad CHECK (Cantidad > 0),
    MotivoId           smallint         NOT NULL CONSTRAINT FK_TransfConf_Motivo REFERENCES inv.MotivoDiferencia (Id),
    Fecha              date             NOT NULL,
    MovimientoId       bigint           NULL CONSTRAINT FK_TransfConf_Mov       REFERENCES inv.Movimiento (Id),
    MovimientoSalidaId bigint           NULL CONSTRAINT FK_TransfConf_MovSalida REFERENCES inv.Movimiento (Id),
    CostoUnitario      decimal(19,6)    NULL,
    AutorizacionId     bigint           NOT NULL CONSTRAINT FK_TransfConf_Autorizacion REFERENCES doc.Autorizacion (Id),
    ClaveIdempotencia  uniqueidentifier NULL,
    HuellaSolicitud    binary(32)       NULL,
    RegistradoPorId    int              NULL,
    RegistradoPor      varchar(60)      NOT NULL,
    RegistradoEn       datetime2(3)     NOT NULL CONSTRAINT DF_TransfConf_En DEFAULT (SYSUTCDATETIME()),
    Version            rowversion       NOT NULL,
    CONSTRAINT FK_TransfConf_Diferencia FOREIGN KEY (DiferenciaId, DocumentoId) REFERENCES inv.TransferenciaDiferencia (Id, DocumentoId),
    CONSTRAINT CK_TransfConf_Resultado CHECK (
           (Resultado = 'R' AND MovimientoId IS NOT NULL AND MovimientoSalidaId IS NULL)
        OR (Resultado = 'A' AND MovimientoId IS NULL AND MovimientoSalidaId IS NOT NULL)
        OR (Resultado IN ('T', 'N') AND MovimientoId IS NOT NULL AND MovimientoSalidaId IS NOT NULL)
        OR (Resultado = 'X' AND MovimientoId IS NULL AND MovimientoSalidaId IS NULL))
);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_Confirmacion_Diferencia' AND object_id = OBJECT_ID(N'inv.TransferenciaConfirmacion'))
    CREATE UNIQUE INDEX UX_Confirmacion_Diferencia ON inv.TransferenciaConfirmacion (DiferenciaId);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_TransfConf_Idempotencia' AND object_id = OBJECT_ID(N'inv.TransferenciaConfirmacion'))
    CREATE UNIQUE INDEX UX_TransfConf_Idempotencia ON inv.TransferenciaConfirmacion (ClaveIdempotencia) WHERE ClaveIdempotencia IS NOT NULL;
GO
IF OBJECT_ID(N'inv.TransferenciaImputacion', N'U') IS NULL
CREATE TABLE inv.TransferenciaImputacion (
    Id                    bigint           NOT NULL CONSTRAINT DF_TransfImp_Id DEFAULT (NEXT VALUE FOR inv.SecTransfImputacion)
                                                    CONSTRAINT PK_TransferenciaImputacion PRIMARY KEY,
    NodoOrigenId          AS (CONVERT(smallint, Id / 1000000000000)) PERSISTED,
    DocumentoId           bigint           NOT NULL,
    DiferenciaId          bigint           NOT NULL,
    SucursalResponsableId smallint         NOT NULL CONSTRAINT FK_TransfImp_Sucursal REFERENCES org.Sucursal (Id),
    SesionSucursalId      smallint         NOT NULL CONSTRAINT FK_TransfImp_SesionSucursal REFERENCES org.Sucursal (Id),
    Motivo                varchar(200)     NOT NULL CONSTRAINT CK_TransfImp_Motivo CHECK (LEN(Motivo) >= 10),
    ReemplazaId           bigint           NULL,
    ClaveIdempotencia     uniqueidentifier NULL,
    HuellaSolicitud       binary(32)       NULL,
    ImputadoPorId         int              NULL,
    ImputadoPor           varchar(60)      NOT NULL,
    ImputadoEn            datetime2(3)     NOT NULL CONSTRAINT DF_TransfImp_En DEFAULT (SYSUTCDATETIME()),
    Version               rowversion       NOT NULL,
    CONSTRAINT UQ_TransfImp_IdDocumento  UNIQUE (Id, DocumentoId),
    CONSTRAINT UQ_TransfImp_IdDiferencia UNIQUE (Id, DiferenciaId),
    CONSTRAINT FK_TransfImp_Diferencia FOREIGN KEY (DiferenciaId, DocumentoId) REFERENCES inv.TransferenciaDiferencia (Id, DocumentoId),
    CONSTRAINT FK_TransfImp_Reemplaza  FOREIGN KEY (ReemplazaId, DiferenciaId) REFERENCES inv.TransferenciaImputacion (Id, DiferenciaId)
);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_Imputacion_Reemplaza' AND object_id = OBJECT_ID(N'inv.TransferenciaImputacion'))
    CREATE UNIQUE INDEX UX_Imputacion_Reemplaza ON inv.TransferenciaImputacion (ReemplazaId) WHERE ReemplazaId IS NOT NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_Imputacion_Raiz' AND object_id = OBJECT_ID(N'inv.TransferenciaImputacion'))
    CREATE UNIQUE INDEX UX_Imputacion_Raiz ON inv.TransferenciaImputacion (DiferenciaId) WHERE ReemplazaId IS NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_TransfImp_Idempotencia' AND object_id = OBJECT_ID(N'inv.TransferenciaImputacion'))
    CREATE UNIQUE INDEX UX_TransfImp_Idempotencia ON inv.TransferenciaImputacion (ClaveIdempotencia) WHERE ClaveIdempotencia IS NOT NULL;
GO
IF OBJECT_ID(N'inv.TransferenciaRedireccion', N'U') IS NULL
CREATE TABLE inv.TransferenciaRedireccion (
    Id                bigint           NOT NULL CONSTRAINT DF_TransfRed_Id DEFAULT (NEXT VALUE FOR inv.SecTransfRedireccion)
                                                CONSTRAINT PK_TransferenciaRedireccion PRIMARY KEY,
    NodoOrigenId      AS (CONVERT(smallint, Id / 1000000000000)) PERSISTED,
    DocumentoId       bigint           NOT NULL CONSTRAINT FK_TransfRed_Transf REFERENCES inv.Transferencia (DocumentoId),
    AlmacenDestinoId  smallint         NOT NULL,
    SucursalDestinoId smallint         NOT NULL,
    ReemplazaId       bigint           NULL,
    Motivo            varchar(200)     NOT NULL CONSTRAINT CK_TransfRed_Motivo CHECK (LEN(Motivo) >= 10),
    AutorizacionId    bigint           NOT NULL CONSTRAINT FK_TransfRed_Autorizacion REFERENCES doc.Autorizacion (Id),
    ClaveIdempotencia uniqueidentifier NULL,
    HuellaSolicitud   binary(32)       NULL,
    RegistradoPorId   int              NULL,
    RegistradoPor     varchar(60)      NOT NULL,
    RegistradoEn      datetime2(3)     NOT NULL CONSTRAINT DF_TransfRed_En DEFAULT (SYSUTCDATETIME()),
    Version           rowversion       NOT NULL,
    CONSTRAINT UQ_TransfRed_IdDocumento  UNIQUE (Id, DocumentoId),
    CONSTRAINT FK_TransfRed_Almacen  FOREIGN KEY (AlmacenDestinoId, SucursalDestinoId) REFERENCES org.Almacen (Id, SucursalId),
    CONSTRAINT FK_TransfRed_Reemplaza FOREIGN KEY (ReemplazaId, DocumentoId) REFERENCES inv.TransferenciaRedireccion (Id, DocumentoId)
);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_Redireccion_Reemplaza' AND object_id = OBJECT_ID(N'inv.TransferenciaRedireccion'))
    CREATE UNIQUE INDEX UX_Redireccion_Reemplaza ON inv.TransferenciaRedireccion (ReemplazaId) WHERE ReemplazaId IS NOT NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_Redireccion_Raiz' AND object_id = OBJECT_ID(N'inv.TransferenciaRedireccion'))
    CREATE UNIQUE INDEX UX_Redireccion_Raiz ON inv.TransferenciaRedireccion (DocumentoId) WHERE ReemplazaId IS NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_TransfRed_Idempotencia' AND object_id = OBJECT_ID(N'inv.TransferenciaRedireccion'))
    CREATE UNIQUE INDEX UX_TransfRed_Idempotencia ON inv.TransferenciaRedireccion (ClaveIdempotencia) WHERE ClaveIdempotencia IS NOT NULL;
GO
IF OBJECT_ID(N'inv.TransferenciaReconstruccion', N'U') IS NULL   -- P-T13, entrega 2; nace vacía
CREATE TABLE inv.TransferenciaReconstruccion (
    DocumentoId       bigint       NOT NULL CONSTRAINT PK_TransferenciaReconstruccion PRIMARY KEY
                                            CONSTRAINT FK_TransfRec_Transf REFERENCES inv.Transferencia (DocumentoId),
    NodoAusenteId     smallint     NOT NULL CONSTRAINT FK_TransfRec_Nodo REFERENCES sync.Nodo (Id),
    CausaSucesion     char(1)      NOT NULL CONSTRAINT CK_TransfRec_Causa  CHECK (CausaSucesion IN ('V', 'R')),
    FuenteContenido   char(1)      NOT NULL CONSTRAINT CK_TransfRec_Fuente CHECK (FuenteContenido IN ('Q', 'U', 'P')),
    HuellaConduce     binary(32)   NULL,
    FechaConduce      date         NOT NULL,
    FechaEfecto       date         NOT NULL,
    NumeroLeido       bit          NOT NULL,
    ConteoDocumentoId bigint       NOT NULL CONSTRAINT FK_TransfRec_Conteo REFERENCES inv.Conteo (DocumentoId),
    Motivo            varchar(200) NOT NULL CONSTRAINT CK_TransfRec_Motivo CHECK (LEN(Motivo) >= 10),
    RegistradoPorId   int          NULL,
    RegistradoPor     varchar(60)  NOT NULL,
    RegistradoEn      datetime2(3) NOT NULL CONSTRAINT DF_TransfRec_En DEFAULT (SYSUTCDATETIME()),
    AprobadoPorId     int          NULL,
    AprobadoPor       varchar(60)  NOT NULL,
    AprobadoEn        datetime2(3) NOT NULL,
    Version           rowversion   NOT NULL,
    CONSTRAINT CK_TransfRec_DobleControl CHECK (AprobadoPor <> RegistradoPor),
    CONSTRAINT CK_TransfRec_Fechas CHECK (FechaEfecto >= FechaConduce)
);
GO

-- 1.12 Estado local derivado, no replicado (ADR-101): tránsito por artículo y transferencias con saldo pendiente
IF OBJECT_ID(N'inv.TransitoArticulo', N'U') IS NULL
CREATE TABLE inv.TransitoArticulo (
    ArticuloId    int           NOT NULL CONSTRAINT PK_TransitoArticulo PRIMARY KEY
                                         CONSTRAINT FK_TransitoArticulo_Articulo REFERENCES cat.Articulo (Id),
    Cantidad      decimal(18,6) NOT NULL CONSTRAINT DF_TransitoArticulo_Cantidad DEFAULT (0)
                                         CONSTRAINT CK_TransitoArticulo_Cantidad CHECK (Cantidad >= 0),
    ActualizadoEn datetime2(3)  NOT NULL CONSTRAINT DF_TransitoArticulo_En DEFAULT (SYSUTCDATETIME())
);
GO
-- Nuevo en v3: «Por recibir», el cierre de sucursal (EnTransitoAsync) y el aviso del cierre de período leen solo las abiertas (O(abiertas),
-- no O(historia × líneas)). Lo mantienen los disparadores; rpt.ConciliacionTransferenciaAbierta debe dar 0 filas.
IF OBJECT_ID(N'inv.TransferenciaAbierta', N'U') IS NULL
CREATE TABLE inv.TransferenciaAbierta (
    DocumentoId       bigint       NOT NULL CONSTRAINT PK_TransferenciaAbierta PRIMARY KEY
                                            CONSTRAINT FK_TransfAbierta_Transf REFERENCES inv.Transferencia (DocumentoId),
    SucursalDestinoId smallint     NOT NULL,     -- destino VIGENTE (la redirección del tramo 2 lo cambia)
    AlmacenDestinoId  smallint     NOT NULL,
    AbiertaDesde      datetime2(3) NOT NULL CONSTRAINT DF_TransfAbierta_Desde DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_TransfAbierta_Almacen FOREIGN KEY (AlmacenDestinoId, SucursalDestinoId) REFERENCES org.Almacen (Id, SucursalId)
);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_TransfAbierta_Destino' AND object_id = OBJECT_ID(N'inv.TransferenciaAbierta'))
    CREATE INDEX IX_TransfAbierta_Destino ON inv.TransferenciaAbierta (SucursalDestinoId) INCLUDE (AlmacenDestinoId);
GO

/* =====================================================================================================================
   PARTE 2 · LO ESCRITO A MANO (SqlMigracionesOla3b.cs, migrationBuilder.Sql al final del Up)
   2.0 Convención de la línea del kárdex por parte (H-3b-10). L = línea del despacho (1 a 2000; 0 = sobrante sin línea).
       Linea = L + 10000 × k,  k = 1000 × T + n:
         T 0 despacho (salida del origen; n = 0)                     → Linea = L
         T 1 recepción R_n                                           → L + 10000 × (1000 + n)
         T 2 diferencia D_n, movimiento principal (MovimientoId)      → L + 10000 × (2000 + n)
         T 3 diferencia D_n, entrada del par de la pérdida (F-P)      → L + 10000 × (3000 + n)
         T 4 confirmación de D_n, MovimientoId (entrada en A)         → L + 10000 × (4000 + n)
         T 5 confirmación de D_n, MovimientoSalidaId (salida en A)    → L + 10000 × (5000 + n)
       n ≤ 999 → Linea ≤ 59.992.000 (int). Los reversos de la anulación conservan la Linea del original (MovimientoRevertidoId los separa).
       Cada parte la genera un solo sitio y su n es único dentro de su tipo: dos sitios nunca producen la misma llave (entrega 2).
   ===================================================================================================================== */

-- 2.1 Tipo de documento 31 TI (familia INV; fecha del servidor: ControlFecha 1). El 32 DAJ nace en Ola3bAdjuntos.
INSERT INTO doc.TipoDocumento (Id, Codigo, Descripcion, Familia, TipoNumeracion, AfectaInventario, AfectaSaldo, LlevaNcf, Editable, SoloCentral, NcfOpcional, ControlFecha)
SELECT 31, 'TI', 'Transferencia de inventario', 'INV', 'TransferenciaInventario', 0, 0, 0, 0, 0, 0, 1
 WHERE NOT EXISTS (SELECT 1 FROM doc.TipoDocumento WHERE Id = 31);
GO

-- 2.2 Siembra del maestro de motivos (no pisa cambios del cliente)
INSERT INTO inv.MotivoDiferencia (Codigo, Descripcion, Tratamiento, ExigirEvidencia, PedirReferencia, UsoOrigen, ModificadoPor)
SELECT s.Codigo, s.Descripcion, s.Tratamiento, s.Evidencia, s.Referencia, s.UsoOrigen, 'SISTEMA'
  FROM (VALUES ('FAL', 'Faltante',                 'P', 1, 1, 0), ('DAN', 'Dañado',              'P', 1, 1, 0),
               ('EXT', 'Extraviado',               'P', 1, 1, 0), ('SUS', 'Sustracción',         'P', 1, 1, 0),
               ('NSO', 'No salió del origen',      'V', 0, 0, 1), ('VEN', 'Vencido o no apto',   'N', 0, 0, 0),
               ('SOB', 'Sobrante',                 'S', 0, 0, 1), ('CAM', 'Sustitución',         'C', 0, 0, 1),
               ('ENC', 'Encontrado en el almacén', 'V', 0, 0, 1), ('NOE', 'No encontrado',       'P', 0, 0, 1)
       ) s (Codigo, Descripcion, Tratamiento, Evidencia, Referencia, UsoOrigen)
 WHERE NOT EXISTS (SELECT 1 FROM inv.MotivoDiferencia m WHERE m.Codigo = s.Codigo);
GO

-- 2.3 Sitio dueño deducido de la sucursal (ADR-100). Sin SCHEMABINDING: no ata sync.Nodo a la 3b (H-3b-02 y H-11 la cambian).
CREATE OR ALTER FUNCTION sync.fn_SitioDuenoSucursal (@SucursalId smallint)
RETURNS TABLE AS RETURN
SELECT ISNULL((SELECT TOP (1) n.Id FROM sync.Nodo n
                WHERE n.SucursalId = @SucursalId AND n.EsCentral = 0 AND n.Inhabilitado = 0
                ORDER BY n.Id DESC), CONVERT(smallint, 1)) AS NodoId;
GO
-- Guarda común de las partes: un solo lugar para el estado de restauración (sync.EstadoEmision, el mismo de 51330 y del candado CR-01) y
-- para el dueño de la sucursal. Falla cerrada: sin sync.EstadoNodo la parte queda bloqueada. @SucursalId NULL = parte de la central.
CREATE OR ALTER FUNCTION sync.fn_GuardaParte (@SucursalId smallint, @NodoOrigenId smallint)
RETURNS TABLE AS RETURN
SELECT CONVERT(bit, CASE WHEN s.Id IS NULL OR e.EmisionBloqueada = 1 OR e.Restaurada = 1 THEN 1 ELSE 0 END) AS Bloqueada,
       CONVERT(bit, CASE
           WHEN s.Id IS NULL THEN 1
           WHEN @NodoOrigenId = s.NodoLocalId AND @SucursalId IS NULL THEN CASE WHEN s.NodoLocalId = 1 THEN 0 ELSE 1 END
           WHEN @NodoOrigenId = s.NodoLocalId THEN CASE WHEN f.NodoId = s.NodoLocalId THEN 0 ELSE 1 END
           -- fila nacida en otro sitio: solo la central, incorporando un mensaje, de un nodo de esa sucursal (entrega 2)
           WHEN s.NodoLocalId = 1 AND SESSION_CONTEXT(N'gpos.incorporacion') IS NOT NULL AND n.SucursalId = @SucursalId THEN 0
           ELSE 1 END) AS FueraDeSitio,
       CONVERT(bit, CASE WHEN x.Id IS NOT NULL THEN 1 ELSE 0 END) AS Reaplicando
  FROM (VALUES (1)) z (k)
  LEFT JOIN sync.EstadoNodo s ON s.Id = 1
  LEFT JOIN sync.EstadoEmision e ON 1 = 1
  OUTER APPLY sync.fn_SitioDuenoSucursal(@SucursalId) f
  LEFT JOIN sync.Nodo n ON n.Id = @NodoOrigenId
  LEFT JOIN sync.Reconciliacion x ON x.Id = s.ReconciliacionId AND x.Estado = 'R' AND x.Id = TRY_CONVERT(int, SESSION_CONTEXT(N'gpos.reaplicacion'));
GO

-- 2.4 Vistas
CREATE OR ALTER VIEW inv.TransferenciaDestinoVigente AS
SELECT t.DocumentoId,
       ISNULL(r.AlmacenDestinoId, t.AlmacenDestinoId)   AS AlmacenDestinoId,
       ISNULL(r.SucursalDestinoId, t.SucursalDestinoId) AS SucursalDestinoId
  FROM inv.Transferencia t
  OUTER APPLY (SELECT TOP (1) x.AlmacenDestinoId, x.SucursalDestinoId FROM inv.TransferenciaRedireccion x
                WHERE x.DocumentoId = t.DocumentoId
                  AND NOT EXISTS (SELECT 1 FROM inv.TransferenciaRedireccion y WHERE y.ReemplazaId = x.Id)) r;
GO
-- CO-1 (DA-03, 1): la existencia global del promedio incluye el tránsito. Único punto que cambia el costo (ConsultasInventario.ExistenciaGlobal).
CREATE OR ALTER VIEW inv.ExistenciaGlobal AS
SELECT x.ArticuloId, SUM(x.Cantidad) AS Cantidad
  FROM (SELECT e.ArticuloId, e.Cantidad FROM inv.Existencia e
        UNION ALL
        SELECT t.ArticuloId, t.Cantidad FROM inv.TransitoArticulo t) x
 GROUP BY x.ArticuloId;
GO
IF OBJECT_ID(N'inv.EventoCostoTransferencia', N'V') IS NOT NULL DROP VIEW inv.EventoCostoTransferencia;   -- retirada (ADR-102)
GO
-- Estado derivado ([TRF] 2.1); nadie lo escribe
CREATE OR ALTER VIEW inv.TransferenciaEstado AS
SELECT t.DocumentoId,
       CASE WHEN d.Estado = 0 THEN 'BORRADOR'
            WHEN d.Estado = 2 THEN 'ANULADO'
            WHEN s.Pendiente > 0 AND s.Consumido = 0 AND t.SalidaConfirmadaEn IS NULL THEN 'DESPACHADO'
            WHEN s.Pendiente > 0 THEN 'EN_TRANSITO'
            WHEN p.PorResolver > 0 THEN 'RECIBIDO_PROVISIONAL'
            WHEN p.ConDiferencias > 0 THEN 'CON_DIFERENCIAS'
            ELSE 'RECONCILIADO' END AS Estado,
       s.Pendiente, p.PorResolver
  FROM inv.Transferencia t
  JOIN doc.Documento d ON d.Id = t.DocumentoId
  CROSS APPLY (SELECT ISNULL(SUM(ls.CantidadOrigen - ls.CantidadConsumida - ls.CantidadFaltante), 0) AS Pendiente,
                      ISNULL(SUM(ls.CantidadConsumida + ls.CantidadFaltante), 0) AS Consumido
                 FROM doc.LineaSaldo ls WHERE ls.DocumentoId = t.DocumentoId AND ls.Clase = 'R') s
  CROSS APPLY (SELECT COUNT(*) AS ConDiferencias,
                      ISNULL(SUM(CASE WHEN (f.Tratamiento IN ('V', 'S', 'C') AND c.Id IS NULL)
                                        OR ((f.Tratamiento = 'P' OR c.Resultado = 'N') AND im.Id IS NULL)
                                      THEN 1 ELSE 0 END), 0) AS PorResolver
                 FROM inv.TransferenciaDiferencia f
                 LEFT JOIN inv.TransferenciaConfirmacion c ON c.DiferenciaId = f.Id
                 LEFT JOIN inv.TransferenciaImputacion im ON im.DiferenciaId = f.Id AND im.ReemplazaId IS NULL
                WHERE f.DocumentoId = t.DocumentoId) p;
GO
-- Conciliación del tránsito contra las partes (0 filas). Deltas de [D3B] 2.9.
CREATE OR ALTER VIEW rpt.ConciliacionTransito AS
WITH d AS (
    SELECT l.ArticuloId, l.Cantidad AS Delta FROM inv.TransferenciaLinea l
      JOIN doc.Documento x ON x.Id = l.DocumentoId AND x.Estado = 1
    UNION ALL SELECT l.ArticuloId, -rl.Cantidad FROM inv.TransferenciaRecepcionLinea rl
      JOIN inv.TransferenciaLinea l ON l.DocumentoId = rl.DocumentoId AND l.Linea = rl.Linea
    UNION ALL SELECT f.ArticuloId, -f.Cantidad FROM inv.TransferenciaDiferencia f
               WHERE (f.Clase = 'F' AND f.Tratamiento = 'P') OR f.Clase = 'N'
    UNION ALL SELECT f.ArticuloId, -c.Cantidad FROM inv.TransferenciaConfirmacion c JOIN inv.TransferenciaDiferencia f ON f.Id = c.DiferenciaId
               WHERE c.Resultado IN ('R', 'N', 'T'))
SELECT ISNULL(m.ArticuloId, k.ArticuloId) AS ArticuloId, ISNULL(m.Cantidad, 0) AS Materializado, ISNULL(k.Cantidad, 0) AS Partes
  FROM inv.TransitoArticulo m
  FULL JOIN (SELECT ArticuloId, SUM(Delta) AS Cantidad FROM d GROUP BY ArticuloId) k ON k.ArticuloId = m.ArticuloId
 WHERE ISNULL(m.Cantidad, 0) <> ISNULL(k.Cantidad, 0);
GO
-- Conciliación de inv.TransferenciaAbierta (0 filas): abierta ⇔ emitida y con saldo de línea pendiente
CREATE OR ALTER VIEW rpt.ConciliacionTransferenciaAbierta AS
SELECT ISNULL(a.DocumentoId, p.DocumentoId) AS DocumentoId,
       CONVERT(bit, CASE WHEN a.DocumentoId IS NULL THEN 0 ELSE 1 END) AS Materializada,
       CONVERT(bit, CASE WHEN p.DocumentoId IS NULL THEN 0 ELSE 1 END) AS SegunSaldos
  FROM inv.TransferenciaAbierta a
  FULL JOIN (SELECT t.DocumentoId FROM inv.Transferencia t JOIN doc.Documento d ON d.Id = t.DocumentoId AND d.Estado = 1
              WHERE EXISTS (SELECT 1 FROM doc.LineaSaldo ls WHERE ls.DocumentoId = t.DocumentoId AND ls.Clase = 'R'
                              AND ls.CantidadConsumida + ls.CantidadFaltante < ls.CantidadOrigen)) p ON p.DocumentoId = a.DocumentoId
 WHERE a.DocumentoId IS NULL OR p.DocumentoId IS NULL;
GO
-- H-3b-17: tránsito para reportes. rpt (cantidad; la lee gpos_reportes); rptc (valor; solo la API, PR-ADR38). Valor = cantidad × promedio de
-- la empresa, como rptc.ExistenciaActual y la foto (T-05): Σ rptc.ExistenciaActual.Valor + Σ rptc.TransitoArticulo.Valor cuadra con la foto.
CREATE OR ALTER VIEW rpt.TransitoArticulo AS
SELECT t.ArticuloId, a.Codigo AS ArticuloCodigo, a.Descripcion, a.CategoriaId, a.MarcaId, t.Cantidad, t.ActualizadoEn, a.ControlLote,
       a.Inhabilitado AS ArticuloInhabilitado
  FROM inv.TransitoArticulo t
  JOIN cat.Articulo a ON a.Id = t.ArticuloId
 WHERE t.Cantidad <> 0;
GO
IF SCHEMA_ID(N'rptc') IS NOT NULL
    EXEC (N'CREATE OR ALTER VIEW rptc.TransitoArticulo AS
SELECT t.ArticuloId, a.Codigo AS ArticuloCodigo, a.Descripcion, a.CategoriaId, a.MarcaId, t.Cantidad, t.ActualizadoEn, a.ControlLote,
       a.Inhabilitado AS ArticuloInhabilitado, ac.CostoPromedio,
       CONVERT(decimal(19, 2), ROUND(t.Cantidad * ISNULL(ac.CostoPromedio, ISNULL(a.UltimoCostoCompra, 0)), 2)) AS Valor
  FROM inv.TransitoArticulo t
  JOIN cat.Articulo a            ON a.Id = t.ArticuloId
  LEFT JOIN inv.ArticuloCosto ac ON ac.ArticuloId = t.ArticuloId
 WHERE t.Cantidad <> 0;');
GO

-- 2.5 Rango del nodo en las 5 tablas con llave de secuencia (E1-1, K-62; DisparadoresNg.RangoNodo)
CREATE OR ALTER TRIGGER inv.TR_TransferenciaRecepcion_RangoNodo ON inv.TransferenciaRecepcion AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @local smallint = ISNULL((SELECT NodoLocalId FROM sync.EstadoNodo WHERE Id = 1), 1);
    IF EXISTS (SELECT 1 FROM inserted i WHERE CONVERT(smallint, i.Id / 1000000000000) <> @local
                  AND ISNULL(TRY_CONVERT(smallint, SESSION_CONTEXT(N'gpos.incorporacion')), -1) <> CONVERT(smallint, i.Id / 1000000000000))
        THROW 51332, N'La llave no es del rango de este nodo: solo la incorporación la admite (E1-1, K-62).', 1;
END
GO
CREATE OR ALTER TRIGGER inv.TR_TransferenciaDiferencia_RangoNodo ON inv.TransferenciaDiferencia AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @local smallint = ISNULL((SELECT NodoLocalId FROM sync.EstadoNodo WHERE Id = 1), 1);
    IF EXISTS (SELECT 1 FROM inserted i WHERE CONVERT(smallint, i.Id / 1000000000000) <> @local
                  AND ISNULL(TRY_CONVERT(smallint, SESSION_CONTEXT(N'gpos.incorporacion')), -1) <> CONVERT(smallint, i.Id / 1000000000000))
        THROW 51332, N'La llave no es del rango de este nodo: solo la incorporación la admite (E1-1, K-62).', 1;
END
GO
CREATE OR ALTER TRIGGER inv.TR_TransferenciaConfirmacion_RangoNodo ON inv.TransferenciaConfirmacion AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @local smallint = ISNULL((SELECT NodoLocalId FROM sync.EstadoNodo WHERE Id = 1), 1);
    IF EXISTS (SELECT 1 FROM inserted i WHERE CONVERT(smallint, i.Id / 1000000000000) <> @local
                  AND ISNULL(TRY_CONVERT(smallint, SESSION_CONTEXT(N'gpos.incorporacion')), -1) <> CONVERT(smallint, i.Id / 1000000000000))
        THROW 51332, N'La llave no es del rango de este nodo: solo la incorporación la admite (E1-1, K-62).', 1;
END
GO
CREATE OR ALTER TRIGGER inv.TR_TransferenciaImputacion_RangoNodo ON inv.TransferenciaImputacion AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @local smallint = ISNULL((SELECT NodoLocalId FROM sync.EstadoNodo WHERE Id = 1), 1);
    IF EXISTS (SELECT 1 FROM inserted i WHERE CONVERT(smallint, i.Id / 1000000000000) <> @local
                  AND ISNULL(TRY_CONVERT(smallint, SESSION_CONTEXT(N'gpos.incorporacion')), -1) <> CONVERT(smallint, i.Id / 1000000000000))
        THROW 51332, N'La llave no es del rango de este nodo: solo la incorporación la admite (E1-1, K-62).', 1;
END
GO
CREATE OR ALTER TRIGGER inv.TR_TransferenciaRedireccion_RangoNodo ON inv.TransferenciaRedireccion AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @local smallint = ISNULL((SELECT NodoLocalId FROM sync.EstadoNodo WHERE Id = 1), 1);
    IF EXISTS (SELECT 1 FROM inserted i WHERE CONVERT(smallint, i.Id / 1000000000000) <> @local
                  AND ISNULL(TRY_CONVERT(smallint, SESSION_CONTEXT(N'gpos.incorporacion')), -1) <> CONVERT(smallint, i.Id / 1000000000000))
        THROW 51332, N'La llave no es del rango de este nodo: solo la incorporación la admite (E1-1, K-62).', 1;
END
GO

-- 2.6 Cabecera del despacho: nace en el borrador de su TI, en la sucursal del documento; después solo la confirmación de salida, una vez
CREATE OR ALTER TRIGGER inv.TR_Transferencia_Reglas ON inv.Transferencia AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM deleted d WHERE NOT EXISTS (SELECT 1 FROM inserted i WHERE i.DocumentoId = d.DocumentoId))
        THROW 51441, N'Una parte de la transferencia es de solo inserción (DA-01).', 1;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;
    IF EXISTS (SELECT 1 FROM sync.fn_GuardaParte(NULL, NULL) WHERE Reaplicando = 1) RETURN;
    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        IF EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON d.DocumentoId = i.DocumentoId JOIN doc.Documento x ON x.Id = i.DocumentoId
                    WHERE x.Estado <> 1 OR d.SalidaConfirmadaEn IS NOT NULL OR i.SalidaConfirmadaEn IS NULL
                       OR i.Modo <> d.Modo OR i.AlmacenOrigenId <> d.AlmacenOrigenId OR i.AlmacenDestinoId <> d.AlmacenDestinoId
                       OR i.SucursalOrigenId <> d.SucursalOrigenId OR i.SucursalDestinoId <> d.SucursalDestinoId OR i.PlazoDias <> d.PlazoDias
                       OR i.TotalLineas <> d.TotalLineas OR i.TotalUnidades <> d.TotalUnidades OR i.Huella <> d.Huella)
            THROW 51441, N'Del despacho emitido solo se registra una vez la confirmación de salida.', 1;
    END
    ELSE IF EXISTS (SELECT 1 FROM inserted i LEFT JOIN doc.Documento x ON x.Id = i.DocumentoId
                     WHERE x.Id IS NULL OR x.TipoDocumentoId <> 31 OR x.Estado <> 0 OR x.SucursalId <> i.SucursalOrigenId)
        THROW 51454, N'La transferencia nace en el borrador de un documento TI de la sucursal de origen.', 1;
    IF EXISTS (SELECT 1 FROM inserted i JOIN doc.Documento x ON x.Id = i.DocumentoId
                CROSS APPLY sync.fn_GuardaParte(i.SucursalOrigenId, CASE WHEN EXISTS (SELECT 1 FROM deleted) THEN
                                                    (SELECT NodoLocalId FROM sync.EstadoNodo WHERE Id = 1) ELSE x.NodoOrigenId END) g
                WHERE g.FueraDeSitio = 1)
        THROW 51440, N'Esta parte de la transferencia la escribe el sitio dueño de la sucursal (ADR-53, cláusula 2).', 1;
END
GO
-- 2.7 Líneas y series del despacho: solo en el borrador; después, inmutables (también el costo del despacho, I-T21)
CREATE OR ALTER TRIGGER inv.TR_TransferenciaLinea_Reglas ON inv.TransferenciaLinea AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM deleted) THROW 51441, N'Una parte de la transferencia es de solo inserción (DA-01).', 1;
    IF EXISTS (SELECT 1 FROM inserted i JOIN doc.Documento x ON x.Id = i.DocumentoId WHERE x.Estado <> 0)
        THROW 51441, N'Las líneas del despacho se registran en el borrador de la transferencia.', 1;
    IF EXISTS (SELECT 1 FROM inserted i JOIN inv.Transferencia t ON t.DocumentoId = i.DocumentoId JOIN doc.Documento x ON x.Id = i.DocumentoId
                CROSS APPLY sync.fn_GuardaParte(t.SucursalOrigenId, x.NodoOrigenId) g
                WHERE g.FueraDeSitio = 1 AND g.Reaplicando = 0)
        THROW 51440, N'Esta parte de la transferencia la escribe el sitio dueño de la sucursal (ADR-53, cláusula 2).', 1;
END
GO
CREATE OR ALTER TRIGGER inv.TR_TransferenciaSerie_Reglas ON inv.TransferenciaSerie AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM deleted) THROW 51441, N'Una parte de la transferencia es de solo inserción (DA-01).', 1;
    IF EXISTS (SELECT 1 FROM inserted i JOIN doc.Documento x ON x.Id = i.DocumentoId WHERE x.Estado <> 0)
        THROW 51441, N'Las series del despacho se registran en el borrador de la transferencia.', 1;
    IF EXISTS (SELECT 1 FROM inserted i JOIN inv.TransferenciaLinea l ON l.DocumentoId = i.DocumentoId AND l.Linea = i.Linea
                JOIN inv.NumeroSerie s ON s.Id = i.NumeroSerieId WHERE s.ArticuloId <> l.ArticuloId)
        THROW 51454, N'La serie no es del artículo de la línea del despacho (MD-27).', 1;
END
GO
-- 2.8 Sesión y escaneos (borradores): solo en una TI emitida, en el destino vigente y en su sitio; purga a los 30 días de cerrarse
CREATE OR ALTER TRIGGER inv.TR_SesionRecepcion_Reglas ON inv.SesionRecepcion AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM deleted d WHERE NOT EXISTS (SELECT 1 FROM inserted i WHERE i.Id = d.Id)
                  AND (d.Estado = 'A' OR d.CerradaEn > DATEADD(DAY, -30, SYSUTCDATETIME())))
        THROW 51456, N'Solo se purgan sesiones de recepción confirmadas o descartadas hace más de 30 días (P-3b-03).', 1;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;
    IF EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON d.Id = i.Id
                WHERE d.Estado IN ('C', 'X') OR i.DocumentoId <> d.DocumentoId OR i.AlmacenId <> d.AlmacenId OR i.SucursalId <> d.SucursalId
                   OR i.AbiertaPor <> d.AbiertaPor OR (d.TerminadaEn IS NOT NULL AND (i.TerminadaEn IS NULL OR i.TerminadaEn <> d.TerminadaEn)))
        THROW 51441, N'Una sesión de recepción cerrada no cambia; de una abierta solo cambian su terminación y su cierre.', 1;
    IF EXISTS (SELECT 1 FROM inserted i JOIN doc.Documento x ON x.Id = i.DocumentoId
                WHERE NOT EXISTS (SELECT 1 FROM deleted d WHERE d.Id = i.Id) AND (x.Estado <> 1 OR x.TipoDocumentoId <> 31))
        THROW 51457, N'La transferencia no está emitida o está anulada: no admite recepciones.', 1;
    IF EXISTS (SELECT 1 FROM inserted i JOIN inv.TransferenciaDestinoVigente v ON v.DocumentoId = i.DocumentoId
                WHERE i.Estado = 'A' AND (v.AlmacenDestinoId <> i.AlmacenId OR v.SucursalDestinoId <> i.SucursalId))
        THROW 51443, N'La recepción va al almacén de destino vigente de la transferencia.', 1;
    IF EXISTS (SELECT 1 FROM inserted i CROSS APPLY sync.fn_GuardaParte(i.SucursalId, (SELECT NodoLocalId FROM sync.EstadoNodo WHERE Id = 1)) g
                WHERE i.Estado = 'A' AND g.FueraDeSitio = 1)
        THROW 51440, N'Esta parte de la transferencia la escribe el sitio dueño de la sucursal (ADR-53, cláusula 2).', 1;
END
GO
CREATE OR ALTER TRIGGER inv.TR_SesionRecepcionEscaneo_Reglas ON inv.SesionRecepcionEscaneo AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        THROW 51441, N'Un escaneo no se modifica: se quita y se vuelve a leer.', 1;
    IF EXISTS (SELECT 1 FROM inserted i JOIN inv.SesionRecepcion s ON s.Id = i.SesionId WHERE s.Estado <> 'A')
        THROW 51441, N'La sesión de recepción está cerrada: no admite escaneos.', 1;
    IF EXISTS (SELECT 1 FROM deleted d JOIN inv.SesionRecepcion s ON s.Id = d.SesionId
                WHERE NOT ((s.Estado = 'A' AND s.TerminadaEn IS NULL)
                           OR (s.Estado IN ('C', 'X') AND s.CerradaEn <= DATEADD(DAY, -30, SYSUTCDATETIME()))))
        THROW 51456, N'Un escaneo se quita solo con la sesión abierta sin terminar, o en la purga de las sesiones cerradas hace más de 30 días.', 1;
END
GO
-- 2.9 Recepción: sitio, restauración, TI vigente, destino vigente, fecha local y segregación S-02 (también para el ADMIN y el SUPER)
CREATE OR ALTER TRIGGER inv.TR_TransferenciaRecepcion_Reglas ON inv.TransferenciaRecepcion AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM deleted) THROW 51441, N'Una parte de la transferencia es de solo inserción (DA-01).', 1;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;
    IF EXISTS (SELECT 1 FROM sync.fn_GuardaParte(NULL, NULL) WHERE Reaplicando = 1) RETURN;
    IF EXISTS (SELECT 1 FROM inserted i CROSS APPLY sync.fn_GuardaParte(i.SucursalId, i.NodoOrigenId) g WHERE g.Bloqueada = 1)
        THROW 51330, N'Emisión bloqueada: la base fue restaurada o el nodo está en reconciliación (MD-59).', 1;
    IF EXISTS (SELECT 1 FROM inserted i CROSS APPLY sync.fn_GuardaParte(i.SucursalId, i.NodoOrigenId) g WHERE g.FueraDeSitio = 1)
        THROW 51440, N'Esta parte de la transferencia la escribe el sitio dueño de la sucursal (ADR-53, cláusula 2).', 1;
    IF EXISTS (SELECT 1 FROM inserted i JOIN doc.Documento x ON x.Id = i.DocumentoId WHERE x.Estado <> 1 OR x.TipoDocumentoId <> 31)
        THROW 51457, N'La transferencia no está emitida o está anulada: no admite recepciones.', 1;
    IF EXISTS (SELECT 1 FROM inserted i JOIN inv.TransferenciaDestinoVigente v ON v.DocumentoId = i.DocumentoId
                WHERE v.AlmacenDestinoId <> i.AlmacenId OR v.SucursalDestinoId <> i.SucursalId)
        THROW 51443, N'La recepción va al almacén de destino vigente de la transferencia.', 1;
    IF SESSION_CONTEXT(N'gpos.incorporacion') IS NULL
       AND EXISTS (SELECT 1 FROM inserted i
                    WHERE i.Fecha NOT BETWEEN CONVERT(date, DATEADD(MINUTE, -245, SYSUTCDATETIME())) AND CONVERT(date, DATEADD(MINUTE, -235, SYSUTCDATETIME())))
        THROW 51452, N'La fecha de una parte de la transferencia es la de hoy de la empresa (T-02).', 1;
    IF EXISTS (SELECT 1 FROM inserted i JOIN inv.Transferencia t ON t.DocumentoId = i.DocumentoId JOIN doc.Documento x ON x.Id = i.DocumentoId
                WHERE t.Modo = 'E' AND x.CreadoPor = i.RegistradoPor)
        THROW 51451, N'Quien despachó la transferencia no puede recibirla (segregación de funciones, S-02).', 1;
END
GO
-- 2.10 Líneas de la recepción: kárdex de la parte = la parte (T = 1), control local LineaSaldo, tránsito −q y cierre de la abierta.
--      El servicio actualiza doc.LineaSaldo ANTES de insertar estas filas (orden de ADR-104).
CREATE OR ALTER TRIGGER inv.TR_TransferenciaRecepcionLinea_Reglas ON inv.TransferenciaRecepcionLinea AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM deleted) THROW 51441, N'Una parte de la transferencia es de solo inserción (DA-01).', 1;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;
    IF EXISTS (SELECT 1
                 FROM inserted rl
                 JOIN inv.TransferenciaRecepcion r ON r.Id = rl.RecepcionId
                 JOIN inv.TransferenciaLinea l ON l.DocumentoId = rl.DocumentoId AND l.Linea = rl.Linea
                 JOIN cat.Articulo a ON a.Id = l.ArticuloId
                 LEFT JOIN inv.Movimiento m ON m.Id = rl.MovimientoEntradaId
                WHERE m.Id IS NULL OR m.DocumentoId <> rl.DocumentoId OR m.Linea <> CONVERT(int, rl.Linea) + 10000 * (1000 + r.Consecutivo)
                   OR m.ArticuloId <> l.ArticuloId OR m.AlmacenId <> r.AlmacenId OR ISNULL(m.LoteId, -1) <> ISNULL(l.LoteId, -1)
                   OR m.Cantidad <> rl.Cantidad OR m.Clase <> 6 OR m.CostoUnitario <> l.CostoDespacho OR m.MovimientoRevertidoId IS NOT NULL
                   OR m.Fecha <> r.Fecha OR m.UnidadId IS NULL OR m.UnidadId <> a.UnidadBaseId OR m.FactorUnidad <> 1 OR m.CantidadOrigen <> rl.Cantidad)
        THROW 51454, N'El kárdex de la recepción no coincide con la recepción (entrada de clase 6 al costo del despacho, en unidad base, línea L + 10000 × (1000 + R)).', 1;
    IF EXISTS (SELECT 1 FROM (SELECT DISTINCT DocumentoId, Linea FROM inserted) k
                 LEFT JOIN doc.LineaSaldo ls ON ls.DocumentoId = k.DocumentoId AND ls.Linea = k.Linea AND ls.Clase = 'R'
                WHERE ls.DocumentoId IS NULL
                   OR ls.CantidadConsumida <> (SELECT SUM(x.Cantidad) FROM inv.TransferenciaRecepcionLinea x WHERE x.DocumentoId = k.DocumentoId AND x.Linea = k.Linea))
        THROW 51454, N'El saldo de la línea (doc.LineaSaldo, clase R) no coincide con lo recibido: actualícelo antes de registrar la recepción.', 1;
    MERGE inv.TransitoArticulo WITH (HOLDLOCK) AS t
    USING (SELECT l.ArticuloId, -SUM(rl.Cantidad) AS Delta
             FROM inserted rl JOIN inv.TransferenciaLinea l ON l.DocumentoId = rl.DocumentoId AND l.Linea = rl.Linea
            GROUP BY l.ArticuloId) AS s
       ON t.ArticuloId = s.ArticuloId
     WHEN MATCHED THEN UPDATE SET Cantidad = t.Cantidad + s.Delta, ActualizadoEn = SYSUTCDATETIME()
     WHEN NOT MATCHED THEN INSERT (ArticuloId, Cantidad) VALUES (s.ArticuloId, s.Delta);
    DELETE a FROM inv.TransferenciaAbierta a
     WHERE a.DocumentoId IN (SELECT DocumentoId FROM inserted)
       AND NOT EXISTS (SELECT 1 FROM doc.LineaSaldo ls WHERE ls.DocumentoId = a.DocumentoId AND ls.Clase = 'R'
                         AND ls.CantidadConsumida + ls.CantidadFaltante < ls.CantidadOrigen);
END
GO
CREATE OR ALTER TRIGGER inv.TR_TransferenciaRecepcionSerie_Reglas ON inv.TransferenciaRecepcionSerie AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM deleted) THROW 51441, N'Una parte de la transferencia es de solo inserción (DA-01).', 1;
    IF EXISTS (SELECT 1 FROM inserted i JOIN inv.TransferenciaRecepcion r ON r.Id = i.RecepcionId JOIN inv.NumeroSerie s ON s.Id = i.NumeroSerieId
                WHERE s.Estado <> 'E' OR ISNULL(s.AlmacenId, -1) <> r.AlmacenId)
        THROW 51454, N'La serie recibida pasa a «en existencia» en el almacén de la recepción antes de registrarla (T → E).', 1;
END
GO
-- 2.11 Maestro de motivos: el código no cambia con diferencias o confirmaciones (ADR-08: con referencias se inhabilita; la FK impide borrar)
CREATE OR ALTER TRIGGER inv.TR_MotivoDiferencia_Codigo ON inv.MotivoDiferencia AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(Codigo) AND NOT UPDATE(Tratamiento) RETURN;
    IF EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON d.Id = i.Id
                WHERE (i.Codigo <> d.Codigo OR i.Tratamiento <> d.Tratamiento)
                  AND (EXISTS (SELECT 1 FROM inv.TransferenciaDiferencia f WHERE f.MotivoId = i.Id)
                    OR EXISTS (SELECT 1 FROM inv.TransferenciaConfirmacion c WHERE c.MotivoId = i.Id)))
        THROW 51445, N'El motivo ya se usó en diferencias de transferencias: su código y su tratamiento no cambian; inhabilítelo y cree otro.', 1;
END
GO
-- 2.12 Partes del tramo 2 y de la entrega 2: cerradas hasta Ola3bDiferencias (que sustituye estos disparadores con CREATE OR ALTER)
CREATE OR ALTER TRIGGER inv.TR_TransferenciaDiferencia_Reglas ON inv.TransferenciaDiferencia AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    THROW 51441, N'Las diferencias de transferencias se habilitan con el tramo 2 de la ola 3b (Ola3bDiferencias).', 1;
END
GO
CREATE OR ALTER TRIGGER inv.TR_TransferenciaConfirmacion_Reglas ON inv.TransferenciaConfirmacion AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    THROW 51441, N'Las confirmaciones del origen se habilitan con el tramo 2 de la ola 3b (Ola3bDiferencias).', 1;
END
GO
CREATE OR ALTER TRIGGER inv.TR_TransferenciaImputacion_Reglas ON inv.TransferenciaImputacion AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    THROW 51441, N'La imputación de pérdidas se habilita con el tramo 2 de la ola 3b (Ola3bDiferencias).', 1;
END
GO
CREATE OR ALTER TRIGGER inv.TR_TransferenciaRedireccion_Reglas ON inv.TransferenciaRedireccion AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    THROW 51441, N'La redirección se habilita con el tramo 2 de la ola 3b (Ola3bDiferencias).', 1;
END
GO
CREATE OR ALTER TRIGGER inv.TR_TransferenciaReconstruccion_Reglas ON inv.TransferenciaReconstruccion AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    THROW 51441, N'La reconstrucción del despacho es de la entrega 2 (P-T13).', 1;
END
GO

-- 2.13 Emisión y anulación de la TI (H-3b-07, H-3b-15, H-3b-16). Salida temprana: el POS y todo tipo que no sea 31 salen en la 2.ª sentencia.
CREATE OR ALTER TRIGGER doc.TR_Documento_Transferencia ON doc.Documento AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(Estado) RETURN;
    IF NOT EXISTS (SELECT 1 FROM inserted WHERE TipoDocumentoId = 31) RETURN;   -- H-3b-16
    DECLARE @inc bit = CASE WHEN SESSION_CONTEXT(N'gpos.incorporacion') IS NULL THEN 0 ELSE 1 END;
    DECLARE @hoyMin date = CONVERT(date, DATEADD(MINUTE, -245, SYSUTCDATETIME())), @hoyMax date = CONVERT(date, DATEADD(MINUTE, -235, SYSUTCDATETIME()));

    -- ---------------- Emisión 0 → 1
    IF EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON d.Id = i.Id WHERE i.TipoDocumentoId = 31 AND d.Estado = 0 AND i.Estado = 1)
    BEGIN
        IF EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON d.Id = i.Id LEFT JOIN inv.Transferencia t ON t.DocumentoId = i.Id
                    WHERE i.TipoDocumentoId = 31 AND d.Estado = 0 AND i.Estado = 1
                      AND (t.DocumentoId IS NULL OR t.SucursalOrigenId <> i.SucursalId
                           OR t.TotalLineas <> (SELECT COUNT(*) FROM inv.TransferenciaLinea l WHERE l.DocumentoId = i.Id)
                           OR t.TotalUnidades <> (SELECT ISNULL(SUM(l.Cantidad), 0) FROM inv.TransferenciaLinea l WHERE l.DocumentoId = i.Id)))
            THROW 51454, N'La TI se emite con su despacho completo: cabecera de la sucursal del documento y totales de control iguales a sus líneas.', 1;
        IF @inc = 0 AND EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON d.Id = i.Id
                                 WHERE i.TipoDocumentoId = 31 AND d.Estado = 0 AND i.Estado = 1 AND i.Origen NOT IN ('I', 'R')
                                   AND i.Fecha NOT BETWEEN @hoyMin AND @hoyMax)
            THROW 51452, N'La fecha de una parte de la transferencia es la de hoy de la empresa (T-02).', 1;
        -- Kárdex del despacho = líneas (TR_Documento_Emision no evalúa la TI), lote obligatorio y existente (ADR-119), lote vencido con motivo (D3),
        -- series una por unidad y ya en tránsito (MD-27) y saldo de línea R recién creado
        IF EXISTS (SELECT 1
                     FROM inserted i
                     JOIN deleted d ON d.Id = i.Id
                     JOIN inv.Transferencia t ON t.DocumentoId = i.Id
                     JOIN inv.TransferenciaLinea l ON l.DocumentoId = i.Id
                     JOIN cat.Articulo a ON a.Id = l.ArticuloId
                     LEFT JOIN cat.ArticuloUnidad au ON au.ArticuloId = l.ArticuloId AND au.UnidadId = l.UnidadId
                     LEFT JOIN inv.Movimiento m ON m.Id = l.MovimientoSalidaId
                     LEFT JOIN inv.Lote lo ON lo.Id = l.LoteId
                     LEFT JOIN doc.LineaSaldo ls ON ls.DocumentoId = i.Id AND ls.Linea = l.Linea AND ls.Clase = 'R'
                    WHERE i.TipoDocumentoId = 31 AND d.Estado = 0 AND i.Estado = 1
                      AND (m.Id IS NULL OR m.DocumentoId <> i.Id OR m.Linea <> l.Linea OR m.ArticuloId <> l.ArticuloId OR m.AlmacenId <> t.AlmacenOrigenId
                           OR ISNULL(m.LoteId, -1) <> ISNULL(l.LoteId, -1) OR m.Cantidad <> -l.Cantidad OR m.Clase <> 6 OR m.CostoUnitario <> l.CostoDespacho
                           OR m.MovimientoRevertidoId IS NOT NULL OR m.Fecha <> i.Fecha OR m.UnidadId IS NULL OR m.UnidadId <> l.UnidadId
                           OR m.FactorUnidad <> l.FactorUnidad OR m.CantidadOrigen <> -l.CantidadUnidad
                           OR au.Factor IS NULL OR au.Factor <> l.FactorUnidad OR a.Inventariable = 0
                           OR (a.ControlLote = 1 AND l.LoteId IS NULL) OR lo.ArticuloId <> l.ArticuloId
                           OR (lo.FechaVencimiento < i.Fecha AND l.MotivoLoteVencido IS NULL)
                           OR (a.ControlSerie = 1 AND l.Cantidad <> (SELECT COUNT(*) FROM inv.TransferenciaSerie s JOIN inv.NumeroSerie ns ON ns.Id = s.NumeroSerieId
                                                                      WHERE s.DocumentoId = i.Id AND s.Linea = l.Linea AND ns.Estado = 'T'))
                           OR (a.ControlSerie = 0 AND EXISTS (SELECT 1 FROM inv.TransferenciaSerie s WHERE s.DocumentoId = i.Id AND s.Linea = l.Linea))
                           OR ls.DocumentoId IS NULL OR ls.CantidadOrigen <> l.Cantidad OR ls.CantidadConsumida <> 0 OR ls.CantidadFaltante <> 0))
           OR EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON d.Id = i.Id
                        JOIN inv.Movimiento m ON m.DocumentoId = i.Id AND m.Linea < 10000 AND m.MovimientoRevertidoId IS NULL
                       WHERE i.TipoDocumentoId = 31 AND d.Estado = 0 AND i.Estado = 1
                         AND NOT EXISTS (SELECT 1 FROM inv.TransferenciaLinea l WHERE l.DocumentoId = i.Id AND l.MovimientoSalidaId = m.Id))
            THROW 51454, N'El kárdex del despacho no coincide con sus líneas (salida de clase 6 al costo del despacho, unidad y factor vigentes, lote obligatorio y existente, lote vencido con motivo, una serie por unidad, saldo de línea R).', 1;
        -- T-09 (P-2, firmada): un despacho nunca deja negativo el almacén de origen, aunque la política de ADR-118 lo permita (red de SalidaEstricta)
        IF @inc = 0 AND (EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN inv.Transferencia t ON t.DocumentoId = i.Id
                                    JOIN inv.TransferenciaLinea l ON l.DocumentoId = i.Id
                                    JOIN inv.Existencia e ON e.ArticuloId = l.ArticuloId AND e.AlmacenId = t.AlmacenOrigenId
                                   WHERE i.TipoDocumentoId = 31 AND d.Estado = 0 AND i.Estado = 1 AND e.Cantidad < 0)
                      OR EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN inv.Transferencia t ON t.DocumentoId = i.Id
                                    JOIN inv.TransferenciaLinea l ON l.DocumentoId = i.Id
                                    JOIN inv.ExistenciaLote el ON el.ArticuloId = l.ArticuloId AND el.AlmacenId = t.AlmacenOrigenId AND el.LoteId = l.LoteId
                                   WHERE i.TipoDocumentoId = 31 AND d.Estado = 0 AND i.Estado = 1 AND el.Cantidad < 0))
            THROW 51453, N'Existencia insuficiente: una transferencia nunca deja negativo el almacén de origen (T-09).', 1;
        INSERT INTO inv.TransferenciaAbierta (DocumentoId, SucursalDestinoId, AlmacenDestinoId)
        SELECT t.DocumentoId, v.SucursalDestinoId, v.AlmacenDestinoId
          FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN inv.Transferencia t ON t.DocumentoId = i.Id
          JOIN inv.TransferenciaDestinoVigente v ON v.DocumentoId = t.DocumentoId
         WHERE i.TipoDocumentoId = 31 AND d.Estado = 0 AND i.Estado = 1;
    END

    -- ---------------- Anulación 1 → 2 (A4)
    IF EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON d.Id = i.Id WHERE i.TipoDocumentoId = 31 AND d.Estado = 1 AND i.Estado = 2)
    BEGIN
        IF EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON d.Id = i.Id
                    WHERE i.TipoDocumentoId = 31 AND d.Estado = 1 AND i.Estado = 2
                      AND (EXISTS (SELECT 1 FROM inv.TransferenciaRecepcion r  WHERE r.DocumentoId = i.Id)
                        OR EXISTS (SELECT 1 FROM inv.TransferenciaDiferencia f WHERE f.DocumentoId = i.Id)
                        OR EXISTS (SELECT 1 FROM inv.SesionRecepcion s WHERE s.DocumentoId = i.Id AND s.Estado = 'A')))
            THROW 51442, N'Una transferencia con recepciones, diferencias o una sesión de recepción abierta no se anula: se cierra el saldo o se descarta la sesión.', 1;
        IF @inc = 0 AND EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN inv.Transferencia t ON t.DocumentoId = i.Id
                                 WHERE i.TipoDocumentoId = 31 AND d.Estado = 1 AND i.Estado = 2 AND t.SalidaConfirmadaEn IS NOT NULL
                                   AND NOT EXISTS (SELECT 1 FROM doc.Autorizacion z WHERE z.DocumentoId = i.Id AND z.Tipo = 'ANULA_TRANSITO'))
            THROW 51455, N'Anular una transferencia en tránsito exige la autorización del supervisor del origen ([TRF] 2.5).', 1;
        IF EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN inv.Transferencia t ON t.DocumentoId = i.Id
                     JOIN inv.TransferenciaSerie s ON s.DocumentoId = i.Id JOIN inv.NumeroSerie ns ON ns.Id = s.NumeroSerieId
                    WHERE i.TipoDocumentoId = 31 AND d.Estado = 1 AND i.Estado = 2 AND (ns.Estado <> 'E' OR ISNULL(ns.AlmacenId, -1) <> t.AlmacenOrigenId))
            THROW 51454, N'La anulación devuelve las series del despacho a «en existencia» en el almacén de origen (T → E).', 1;
        DELETE a FROM inv.TransferenciaAbierta a
         WHERE a.DocumentoId IN (SELECT i.Id FROM inserted i JOIN deleted d ON d.Id = i.Id WHERE i.TipoDocumentoId = 31 AND d.Estado = 1 AND i.Estado = 2);
    END

    -- ---------------- Tránsito: +q en la emisión, −q en la anulación, al final (ADR-104)
    MERGE inv.TransitoArticulo WITH (HOLDLOCK) AS t
    USING (SELECT l.ArticuloId, SUM(CASE WHEN d.Estado = 0 THEN l.Cantidad ELSE -l.Cantidad END) AS Delta
             FROM inserted i
             JOIN deleted d ON d.Id = i.Id
             JOIN inv.TransferenciaLinea l ON l.DocumentoId = i.Id
            WHERE i.TipoDocumentoId = 31 AND ((d.Estado = 0 AND i.Estado = 1) OR (d.Estado = 1 AND i.Estado = 2))
            GROUP BY l.ArticuloId) AS s
       ON t.ArticuloId = s.ArticuloId
     WHEN MATCHED THEN UPDATE SET Cantidad = t.Cantidad + s.Delta, ActualizadoEn = SYSUTCDATETIME()
     WHEN NOT MATCHED THEN INSERT (ArticuloId, Cantidad) VALUES (s.ArticuloId, s.Delta);
END
GO
IF OBJECT_ID(N'doc.TR_Documento_AnulaTransferencia', N'TR') IS NOT NULL DROP TRIGGER doc.TR_Documento_AnulaTransferencia;   -- nombre de una versión anterior
GO

-- 2.14 R7 de ADR-78: el factor de una unidad usada en una línea de transferencia tampoco cambia (texto de Ola4FactorUnidad + inv.TransferenciaLinea)
CREATE OR ALTER TRIGGER cat.TR_ArticuloUnidad_Factor ON cat.ArticuloUnidad AFTER INSERT, UPDATE AS
BEGIN
    SET NOCOUNT ON;
    -- La réplica de la central (ADR-53) trae filas ya validadas
    IF SESSION_CONTEXT(N'gpos.incorporacion') IS NOT NULL RETURN;
    IF EXISTS (SELECT 1 FROM inserted i JOIN cat.Articulo a ON a.Id = i.ArticuloId AND a.UnidadBaseId = i.UnidadId WHERE i.Factor <> 1)
        THROW 51384, N'La unidad base del artículo tiene factor 1 (R7).', 1;
    IF NOT UPDATE(Factor) RETURN;
    IF EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON d.ArticuloId = i.ArticuloId AND d.UnidadId = i.UnidadId
                WHERE i.Factor <> d.Factor
                  AND (   EXISTS (SELECT 1 FROM ventas.VentaLinea x        WHERE x.ArticuloId = i.ArticuloId AND x.UnidadId = i.UnidadId)
                       OR EXISTS (SELECT 1 FROM compras.CompraLinea x      WHERE x.ArticuloId = i.ArticuloId AND x.UnidadId = i.UnidadId)
                       OR EXISTS (SELECT 1 FROM inv.DocInventarioLinea x   WHERE x.ArticuloId = i.ArticuloId AND x.UnidadId = i.UnidadId)
                       OR EXISTS (SELECT 1 FROM inv.ConteoLinea x          WHERE x.ArticuloId = i.ArticuloId AND x.UnidadId = i.UnidadId)
                       OR EXISTS (SELECT 1 FROM inv.TransferenciaLinea x   WHERE x.ArticuloId = i.ArticuloId AND x.UnidadId = i.UnidadId)
                       -- Un nodo sin conexión puede tener documentos con esta unidad aún no replicados: la central no los ve
                       OR EXISTS (SELECT 1 FROM sync.Nodo n WHERE n.EsCentral = 0 AND n.Inhabilitado = 0)))
        THROW 51383, N'El factor de una unidad ya usada en documentos (o con sucursales sin conexión activas) no cambia: inhabilítela y cree otra unidad (R7).', 1;
END
GO

-- 2.15 H-3b-13: las secuencias nuevas se adelantan tras una restauración (texto de SqlMigracionesOla3 + 5 filas)
CREATE OR ALTER PROCEDURE sync.usp_AdelantarSecuencias
    @ReconciliacionId int,
    @Margen bigint
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF NOT EXISTS (SELECT 1 FROM sync.Reconciliacion WHERE Id = @ReconciliacionId AND Estado IN ('R', 'L'))
        THROW 51331, N'La reconciliación no está en curso.', 1;
    DECLARE @nodo bigint = (SELECT NodoLocalId FROM sync.EstadoNodo WHERE Id = 1);
    DECLARE @piso bigint = @nodo * 1000000000000;
    DECLARE @s sysname, @esq sysname, @tabla nvarchar(300), @col sysname, @max bigint, @actual bigint, @nuevo bigint, @central bigint, @sql nvarchar(max);
    DECLARE c CURSOR LOCAL FAST_FORWARD FOR
        SELECT s.name, SCHEMA_NAME(s.schema_id), t.Tabla, t.Columna
          FROM sys.sequences s
          JOIN (VALUES ('SecDocumento', 'doc.Documento', 'Id'), ('SecCliente', 'cat.Cliente', 'Id'), ('SecJornada', 'caja.Jornada', 'Id'),
                       ('SecMovimiento', NULL, 'Id'), ('SecConteo', 'caja.ConteoCiego', 'Id'), ('SecAplicacion', NULL, 'Id'),
                       ('SecLote', 'inv.Lote', 'Id'), ('SecNumeroSerie', 'inv.NumeroSerie', 'Id'), ('SecAutorizacion', 'doc.Autorizacion', 'Id'),
                       ('SecBitacora', 'audit.Bitacora', 'Id'), ('SecSalida', 'sync.Salida', 'Secuencia'),
                       -- Ola 3b (H-3b-13)
                       ('SecTransfRecepcion', 'inv.TransferenciaRecepcion', 'Id'), ('SecTransfDiferencia', 'inv.TransferenciaDiferencia', 'Id'),
                       ('SecTransfConfirmacion', 'inv.TransferenciaConfirmacion', 'Id'), ('SecTransfImputacion', 'inv.TransferenciaImputacion', 'Id'),
                       ('SecTransfRedireccion', 'inv.TransferenciaRedireccion', 'Id')) t (Nombre, Tabla, Columna)
            ON t.Nombre = s.name
         WHERE SCHEMA_NAME(s.schema_id) <> 'cxp';
    OPEN c;
    FETCH NEXT FROM c INTO @s, @esq, @tabla, @col;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @tabla = COALESCE(@tabla, CASE WHEN @s = 'SecMovimiento' THEN @esq + '.Movimiento' WHEN @s = 'SecAplicacion' THEN @esq + '.Aplicacion' END);
        SET @sql = N'SELECT @m = MAX(' + QUOTENAME(@col) + N') FROM ' + @tabla + N' WHERE ' + QUOTENAME(@col) + N' >= @p AND ' + QUOTENAME(@col) + N' < @p + 1000000000000;';
        EXEC sp_executesql @sql, N'@m bigint OUTPUT, @p bigint', @m = @max OUTPUT, @p = @piso;
        SELECT @actual = CONVERT(bigint, current_value) FROM sys.sequences WHERE name = @s AND SCHEMA_NAME(schema_id) = @esq;
        SELECT @central = MaximoCentral FROM sync.ReconciliacionSecuencia WHERE ReconciliacionId = @ReconciliacionId AND Secuencia = @esq + N'.' + @s;
        SET @nuevo = (SELECT MAX(v) FROM (VALUES (ISNULL(@max, @piso)), (@actual), (ISNULL(@central, @piso))) x (v)) + @Margen + 1;
        UPDATE sync.ReconciliacionSecuencia SET ValorNuevo = @nuevo WHERE ReconciliacionId = @ReconciliacionId AND Secuencia = @esq + N'.' + @s;
        SET @central = NULL;
        SET @sql = N'ALTER SEQUENCE ' + QUOTENAME(@esq) + N'.' + QUOTENAME(@s) + N' RESTART WITH ' + CONVERT(nvarchar(30), @nuevo) + N';';
        EXEC (@sql);
        FETCH NEXT FROM c INTO @s, @esq, @tabla, @col;
    END
    CLOSE c; DEALLOCATE c;
END
GO

-- 2.16 Caché de las secuencias nuevas (como las 13 de SecuenciasNodo; EF no la modela)
ALTER SEQUENCE inv.SecTransfRecepcion CACHE 50;
ALTER SEQUENCE inv.SecTransfDiferencia CACHE 50;
ALTER SEQUENCE inv.SecTransfConfirmacion CACHE 50;
ALTER SEQUENCE inv.SecTransfImputacion CACHE 50;
ALTER SEQUENCE inv.SecTransfRedireccion CACHE 50;
GO

-- 2.17 Privilegios de gpos_app (sobre el GRANT del esquema inv; los disparadores escriben por encadenamiento de propiedad)
DENY UPDATE, DELETE ON inv.TransferenciaLinea          TO gpos_app;
DENY UPDATE, DELETE ON inv.TransferenciaSerie          TO gpos_app;
DENY UPDATE, DELETE ON inv.TransferenciaRecepcion      TO gpos_app;
DENY UPDATE, DELETE ON inv.TransferenciaRecepcionLinea TO gpos_app;
DENY UPDATE, DELETE ON inv.TransferenciaRecepcionSerie TO gpos_app;
DENY UPDATE, DELETE ON inv.TransferenciaDiferencia     TO gpos_app;
DENY UPDATE, DELETE ON inv.TransferenciaConfirmacion   TO gpos_app;
DENY UPDATE, DELETE ON inv.TransferenciaImputacion     TO gpos_app;
DENY UPDATE, DELETE ON inv.TransferenciaRedireccion    TO gpos_app;
DENY UPDATE, DELETE ON inv.TransferenciaReconstruccion TO gpos_app;
DENY DELETE ON inv.Transferencia TO gpos_app;
DENY INSERT, UPDATE, DELETE ON inv.TransitoArticulo     TO gpos_app;
DENY INSERT, UPDATE, DELETE ON inv.TransferenciaAbierta TO gpos_app;
GO

/* =====================================================================================================================
   PARTE 3 · TRAMO 2 (NO se aplica en Ola3bTransferencias). Migración pequeña Ola3bDiferencias: CREATE OR ALTER de los cinco disparadores de
   2.12 con las reglas de [D3B] 3.1 renumeradas (51444 a 51451) y los deltas de [D3B] 2.9; la línea del kárdex con T = 2 a 5; el saldo F, N y C
   en CantidadFaltante; el cierre de inv.TransferenciaAbierta también desde la diferencia; la redirección actualiza su SucursalDestinoId.
   Sin cambios de tablas. Ver el documento, sección 1.5.
   PARTE 4 · TRAMO 3: Ola3bAdjuntos (doc.Adjunto, tipo 32 DAJ, familia SIS, AdjuntosSoporteFiscal, AniosConservacion, MesCierreEjercicio,
   doc.DesvinculacionAdjuntos, fn_AdjuntoSoporteFiscal, fn_FinConservacion) con su propia franja de errores (P-D1).
   ===================================================================================================================== */
