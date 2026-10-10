        IF COL_LENGTH('dbo.Reportes', 'Codigo') IS NULL ALTER TABLE dbo.Reportes ADD Codigo nvarchar(50) NULL;
        IF COL_LENGTH('dbo.Usuarios', 'RestringirSucursal') IS NULL
            ALTER TABLE dbo.Usuarios ADD RestringirSucursal bit NOT NULL CONSTRAINT DF_Usuarios_RestringirSucursal DEFAULT (0);
        IF COL_LENGTH('dbo.Usuarios', 'SesionesRevocadas') IS NULL ALTER TABLE dbo.Usuarios ADD SesionesRevocadas datetime2 NULL;
        IF COL_LENGTH('dbo.Usuarios', 'IntentosFallidos') IS NULL
            ALTER TABLE dbo.Usuarios ADD IntentosFallidos int NOT NULL CONSTRAINT DF_Usuarios_IntentosFallidos DEFAULT (0);
        IF COL_LENGTH('dbo.Usuarios', 'BloqueadoHasta') IS NULL ALTER TABLE dbo.Usuarios ADD BloqueadoHasta datetime2 NULL;
        -- Una sola sesión abierta por usuario
        IF COL_LENGTH('dbo.Usuarios', 'SesionId') IS NULL
            ALTER TABLE dbo.Usuarios ADD SesionId varchar(32) NULL, SesionInicio datetime2 NULL, SesionExpira datetime2 NULL, SesionOrigen nvarchar(150) NULL;
        IF COL_LENGTH('dbo.Reportes', 'Grafico') IS NULL ALTER TABLE dbo.Reportes ADD Grafico nvarchar(20) NULL;
        IF COL_LENGTH('dbo.Reportes', 'HuellaSemilla') IS NULL ALTER TABLE dbo.Reportes ADD HuellaSemilla nvarchar(16) NULL;
        IF COL_LENGTH('dbo.Reportes', 'Detalle') IS NULL ALTER TABLE dbo.Reportes ADD Detalle nvarchar(60) NULL;
        IF COL_LENGTH('dbo.ReportesColumnas', 'Enlace') IS NULL ALTER TABLE dbo.ReportesColumnas ADD Enlace nvarchar(30) NULL;
        IF COL_LENGTH('dbo.ReportesColumnas', 'Tipo') IS NULL
            ALTER TABLE dbo.ReportesColumnas ADD Tipo nvarchar(10) NOT NULL CONSTRAINT DF_ReportesColumnas_Tipo DEFAULT (N'TEXTO');
        IF COL_LENGTH('dbo.ReportesColumnas', 'Agregacion') IS NULL ALTER TABLE dbo.ReportesColumnas ADD Agregacion nvarchar(10) NULL;
        IF COL_LENGTH('dbo.ReportesColumnas', 'Visible') IS NULL
            ALTER TABLE dbo.ReportesColumnas ADD Visible bit NOT NULL CONSTRAINT DF_ReportesColumnas_Visible DEFAULT (1);
        IF COL_LENGTH('dbo.ReportesColumnas', 'FiltroObligatorio') IS NULL
            ALTER TABLE dbo.ReportesColumnas ADD FiltroObligatorio bit NOT NULL CONSTRAINT DF_ReportesColumnas_FiltroObligatorio DEFAULT (0);
        IF COL_LENGTH('dbo.ReportesColumnas', 'FiltroDefecto') IS NULL ALTER TABLE dbo.ReportesColumnas ADD FiltroDefecto nvarchar(20) NULL;
        IF COL_LENGTH('dbo.ReportesColumnas', 'DatoCosto') IS NULL
            ALTER TABLE dbo.ReportesColumnas ADD DatoCosto bit NOT NULL CONSTRAINT DF_ReportesColumnas_DatoCosto DEFAULT (0);
        IF COL_LENGTH('dbo.ReportesColumnas', 'Catalogo') IS NULL ALTER TABLE dbo.ReportesColumnas ADD Catalogo nvarchar(30) NULL;
        IF COL_LENGTH('dbo.Reportes', 'OrdenarPor') IS NULL ALTER TABLE dbo.Reportes ADD OrdenarPor nvarchar(80) NULL;
        IF COL_LENGTH('dbo.Reportes', 'OrdenDescendente') IS NULL
            ALTER TABLE dbo.Reportes ADD OrdenDescendente bit NOT NULL CONSTRAINT DF_Reportes_OrdenDescendente DEFAULT (0);
        IF COL_LENGTH('dbo.Reportes', 'Limite') IS NULL ALTER TABLE dbo.Reportes ADD Limite int NULL;
        IF OBJECT_ID('dbo.Configuracion') IS NULL
            CREATE TABLE dbo.Configuracion (Clave nvarchar(50) NOT NULL CONSTRAINT PK_Configuracion PRIMARY KEY, Valor nvarchar(max) NULL,
                FechaModificacion datetime2 NULL, UsuarioModificacion nvarchar(30) NULL);
        -- Permisos granulares: nivel y acciones por opción (Nivel NULL = fila del modelo anterior, la migra PermisosService)
        IF COL_LENGTH('dbo.UsuariosPermisos', 'Nivel') IS NULL ALTER TABLE dbo.UsuariosPermisos ADD Nivel int NULL;
        IF COL_LENGTH('dbo.UsuariosPermisos', 'Acciones') IS NULL
            ALTER TABLE dbo.UsuariosPermisos ADD Acciones int NOT NULL CONSTRAINT DF_UsuariosPermisos_Acciones DEFAULT (0);
        IF OBJECT_ID('dbo.Perfiles') IS NULL
            CREATE TABLE dbo.Perfiles (Codigo nvarchar(30) NOT NULL CONSTRAINT PK_Perfiles PRIMARY KEY, Descripcion nvarchar(100) NOT NULL,
                Inhabilitado bit NOT NULL CONSTRAINT DF_Perfiles_Inhabilitado DEFAULT (0));
        IF OBJECT_ID('dbo.PerfilesPermisos') IS NULL
            CREATE TABLE dbo.PerfilesPermisos (PerfilCodigo nvarchar(30) NOT NULL, Opcion nvarchar(50) NOT NULL, Nivel int NOT NULL, Acciones int NOT NULL,
                CONSTRAINT PK_PerfilesPermisos PRIMARY KEY (PerfilCodigo, Opcion),
                CONSTRAINT FK_PerfilesPermisos_Perfiles_PerfilCodigo FOREIGN KEY (PerfilCodigo) REFERENCES dbo.Perfiles (Codigo) ON DELETE CASCADE);
        IF OBJECT_ID('dbo.UsuariosPerfiles') IS NULL
            CREATE TABLE dbo.UsuariosPerfiles (UsuarioCodigo nvarchar(30) NOT NULL, PerfilCodigo nvarchar(30) NOT NULL,
                CONSTRAINT PK_UsuariosPerfiles PRIMARY KEY (UsuarioCodigo, PerfilCodigo),
                CONSTRAINT FK_UsuariosPerfiles_Usuarios_UsuarioCodigo FOREIGN KEY (UsuarioCodigo) REFERENCES dbo.Usuarios (Codigo) ON DELETE CASCADE,
                CONSTRAINT FK_UsuariosPerfiles_Perfiles_PerfilCodigo FOREIGN KEY (PerfilCodigo) REFERENCES dbo.Perfiles (Codigo) ON DELETE CASCADE);
        -- Padrón de RNC de la DGII y su tabla de carga (el archivo se carga primero aquí y luego reemplaza el padrón en una transacción)
        IF OBJECT_ID('dbo.RncDgii') IS NULL
            CREATE TABLE dbo.RncDgii (Rnc varchar(11) NOT NULL CONSTRAINT PK_RncDgii PRIMARY KEY, Nombre nvarchar(250) NOT NULL,
                NombreComercial nvarchar(250) NULL, Estado nvarchar(50) NULL);
        IF OBJECT_ID('dbo.RncDgiiCarga') IS NULL
            CREATE TABLE dbo.RncDgiiCarga (Rnc varchar(11) NOT NULL, Nombre nvarchar(250) NOT NULL, NombreComercial nvarchar(250) NULL, Estado nvarchar(50) NULL);
        -- Registro único de dispositivos del sitio (ADR-121 con la precisión PF-1; blueprint del KDS, 11.1, punto 6; tanda K1). La seguridad es
        -- de la central (ADR-53, cláusula 2): llega al nodo con la réplica de la entrega 2. Estado P (pendiente), A (activo) o R (revocado);
        -- propiedad L (del local) o P (personal, solo comanderas). Del secreto y del código solo se guarda el hash SHA-256.
        IF OBJECT_ID('dbo.Dispositivos') IS NULL
            CREATE TABLE dbo.Dispositivos (
                Id bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_Dispositivos PRIMARY KEY,
                EmpresaCodigo nvarchar(30) NOT NULL,
                SucursalId smallint NOT NULL,
                SucursalCodigo varchar(20) NOT NULL,
                Tipo varchar(20) NOT NULL CONSTRAINT CK_Dispositivos_Tipo CHECK (Tipo IN ('ESTACION_IMPRESION', 'PANTALLA_COCINA', 'PANTALLA_DESPACHO', 'COMANDERA')),
                Nombre nvarchar(100) NOT NULL,
                Propiedad char(1) NOT NULL CONSTRAINT DF_Dispositivos_Propiedad DEFAULT ('L') CONSTRAINT CK_Dispositivos_Propiedad CHECK (Propiedad IN ('L', 'P')),
                Estado char(1) NOT NULL CONSTRAINT DF_Dispositivos_Estado DEFAULT ('P') CONSTRAINT CK_Dispositivos_Estado CHECK (Estado IN ('P', 'A', 'R')),
                SecretoHash binary(32) NULL,
                NombreEquipo nvarchar(100) NULL, Plataforma varchar(40) NULL, IpCanje varchar(45) NULL, CanjeadoEn datetime2(0) NULL,
                ConfirmadoEn datetime2(0) NULL, ConfirmadoPor nvarchar(30) NULL,
                CreadoEn datetime2(0) NOT NULL, CreadoPor nvarchar(30) NOT NULL,
                RevocadoEn datetime2(0) NULL, RevocadoPor nvarchar(30) NULL, MotivoRevocacion nvarchar(200) NULL,
                UltimoContacto datetime2(0) NULL,
                Version int NOT NULL CONSTRAINT DF_Dispositivos_Version DEFAULT (1),
                CONSTRAINT CK_Dispositivos_PropiedadTipo CHECK (Propiedad = 'L' OR Tipo = 'COMANDERA'));
        IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Dispositivos_Empresa' AND object_id = OBJECT_ID('dbo.Dispositivos'))
            CREATE INDEX IX_Dispositivos_Empresa ON dbo.Dispositivos (EmpresaCodigo, Estado);
        IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Dispositivos_Pendientes' AND object_id = OBJECT_ID('dbo.Dispositivos'))
            CREATE INDEX IX_Dispositivos_Pendientes ON dbo.Dispositivos (CreadoEn) INCLUDE (CanjeadoEn) WHERE Estado = 'P';
        IF OBJECT_ID('dbo.DispositivosAreas') IS NULL
            CREATE TABLE dbo.DispositivosAreas (DispositivoId bigint NOT NULL, AreaId int NOT NULL,
                CONSTRAINT PK_DispositivosAreas PRIMARY KEY (DispositivoId, AreaId),
                CONSTRAINT FK_DispositivosAreas_Dispositivos FOREIGN KEY (DispositivoId) REFERENCES dbo.Dispositivos (Id) ON DELETE CASCADE);
        IF OBJECT_ID('dbo.DispositivosCodigos') IS NULL
            CREATE TABLE dbo.DispositivosCodigos (CodigoHash binary(32) NOT NULL CONSTRAINT PK_DispositivosCodigos PRIMARY KEY,
                DispositivoId bigint NOT NULL CONSTRAINT FK_DispositivosCodigos_Dispositivos REFERENCES dbo.Dispositivos (Id) ON DELETE CASCADE,
                Vence datetime2(0) NOT NULL, Usado bit NOT NULL CONSTRAINT DF_DispositivosCodigos_Usado DEFAULT (0));
        -- V-05: vencimiento del último código emitido, en la fila del dispositivo (lo fijan el alta y la reemisión en su transacción). Así la
        -- anulación de los pendientes no lee dbo.DispositivosCodigos mientras bloquea filas de dbo.Dispositivos (orden inverso al del canje).
        -- Las filas anteriores toman el máximo de sus códigos.
        IF COL_LENGTH('dbo.Dispositivos', 'UltimoCodigoVence') IS NULL
        BEGIN
            ALTER TABLE dbo.Dispositivos ADD UltimoCodigoVence datetime2(0) NULL;
            EXEC (N'UPDATE d SET UltimoCodigoVence = (SELECT MAX(c.Vence) FROM dbo.DispositivosCodigos c WHERE c.DispositivoId = d.Id) FROM dbo.Dispositivos d;');
        END
        -- V-05: los códigos de un dispositivo se inutilizan por su Id (reemisión, revocación y anulación): sin índice, cada sentencia recorría la
        -- tabla con bloqueos de actualización
        IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DispositivosCodigos_Dispositivo' AND object_id = OBJECT_ID('dbo.DispositivosCodigos'))
            CREATE INDEX IX_DispositivosCodigos_Dispositivo ON dbo.DispositivosCodigos (DispositivoId) INCLUDE (Usado);
        IF OBJECT_ID('dbo.DispositivosBitacora') IS NULL
            CREATE TABLE dbo.DispositivosBitacora (Id bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_DispositivosBitacora PRIMARY KEY,
                Fecha datetime2(0) NOT NULL, EmpresaCodigo nvarchar(30) NULL, DispositivoId bigint NULL, Usuario nvarchar(30) NULL,
                Accion varchar(30) NOT NULL, Detalle nvarchar(400) NULL, Ip varchar(45) NULL);
