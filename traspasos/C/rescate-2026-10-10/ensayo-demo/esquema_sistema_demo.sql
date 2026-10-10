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
