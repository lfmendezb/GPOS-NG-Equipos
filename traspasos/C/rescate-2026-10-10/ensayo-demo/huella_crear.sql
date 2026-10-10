-- Base auxiliar del ensayo: guarda las huellas de las copias (nunca de las bases reales)
IF DB_ID(N'GPOS_TEST_DEMO_HUELLA') IS NULL CREATE DATABASE [GPOS_TEST_DEMO_HUELLA];
GO
ALTER DATABASE [GPOS_TEST_DEMO_HUELLA] SET RECOVERY SIMPLE;
GO
USE [GPOS_TEST_DEMO_HUELLA];
GO
IF OBJECT_ID('dbo.Columnas') IS NULL
CREATE TABLE dbo.Columnas (Base sysname, Etapa varchar(40), Esquema sysname, Tabla sysname, Columna sysname, Tipo sysname, Largo int, Prec int, Escala int, Nulo bit, Ident bit, Calc bit, Intercalacion sysname NULL, Defecto nvarchar(max) NULL);
IF OBJECT_ID('dbo.Objetos') IS NULL
CREATE TABLE dbo.Objetos (Base sysname, Etapa varchar(40), Esquema sysname, Nombre sysname, Tipo varchar(4), Padre sysname NULL, Definicion varbinary(32) NULL, Modificado datetime2(3));
IF OBJECT_ID('dbo.Indices') IS NULL
CREATE TABLE dbo.Indices (Base sysname, Etapa varchar(40), Esquema sysname, Tabla sysname, Indice sysname, Tipo varchar(60), Unico bit, Columnas nvarchar(max), Filtro nvarchar(max) NULL);
IF OBJECT_ID('dbo.Datos') IS NULL
CREATE TABLE dbo.Datos (Base sysname, Etapa varchar(40), Esquema sysname, Tabla sysname, Filas bigint, ChkAgg int NULL, ChkSum bigint NULL, ColsRef int, Ms int);
IF OBJECT_ID('dbo.Propiedades') IS NULL
CREATE TABLE dbo.Propiedades (Base sysname, Etapa varchar(40), Nombre sysname, Valor nvarchar(400) NULL);
GO
CREATE OR ALTER PROCEDURE dbo.TomarHuella @base sysname, @etapa varchar(40), @etapaRef varchar(40) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @base NOT LIKE N'GPOS[_]TEST[_]DEMO[_]%' THROW 50001, N'Solo bases GPOS_TEST_DEMO_*', 1;
    DECLARE @b nvarchar(300) = QUOTENAME(@base), @sql nvarchar(max);
    DELETE dbo.Columnas WHERE Base=@base AND Etapa=@etapa; DELETE dbo.Objetos WHERE Base=@base AND Etapa=@etapa;
    DELETE dbo.Indices WHERE Base=@base AND Etapa=@etapa; DELETE dbo.Datos WHERE Base=@base AND Etapa=@etapa; DELETE dbo.Propiedades WHERE Base=@base AND Etapa=@etapa;
    SET @sql = N'INSERT dbo.Columnas SELECT @base, @etapa, s.name, t.name, c.name, ty.name, c.max_length, c.precision, c.scale, c.is_nullable, c.is_identity, c.is_computed, c.collation_name, dc.definition
      FROM ' + @b + N'.sys.columns c JOIN ' + @b + N'.sys.tables t ON t.object_id=c.object_id JOIN ' + @b + N'.sys.schemas s ON s.schema_id=t.schema_id
      JOIN ' + @b + N'.sys.types ty ON ty.user_type_id=c.user_type_id LEFT JOIN ' + @b + N'.sys.default_constraints dc ON dc.object_id=c.default_object_id WHERE t.is_ms_shipped=0';
    EXEC sp_executesql @sql, N'@base sysname, @etapa varchar(40)', @base, @etapa;
    SET @sql = N'INSERT dbo.Objetos SELECT @base, @etapa, s.name, o.name, o.type, OBJECT_NAME(o.parent_object_id, DB_ID(@base)), HASHBYTES(''SHA2_256'', CONVERT(nvarchar(max), m.definition)), o.modify_date
      FROM ' + @b + N'.sys.objects o JOIN ' + @b + N'.sys.schemas s ON s.schema_id=o.schema_id LEFT JOIN ' + @b + N'.sys.sql_modules m ON m.object_id=o.object_id
      WHERE o.is_ms_shipped=0 AND o.type NOT IN (''IT'',''S'')';
    EXEC sp_executesql @sql, N'@base sysname, @etapa varchar(40)', @base, @etapa;
    SET @sql = N'INSERT dbo.Indices SELECT @base, @etapa, s.name, t.name, i.name, i.type_desc, i.is_unique,
        STUFF((SELECT '','' + c.name + CASE WHEN ic.is_included_column=1 THEN ''(i)'' WHEN ic.is_descending_key=1 THEN '' DESC'' ELSE '''' END
               FROM ' + @b + N'.sys.index_columns ic JOIN ' + @b + N'.sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
               WHERE ic.object_id=i.object_id AND ic.index_id=i.index_id ORDER BY ic.is_included_column, ic.key_ordinal, c.name FOR XML PATH('''')),1,1,''''), i.filter_definition
      FROM ' + @b + N'.sys.indexes i JOIN ' + @b + N'.sys.tables t ON t.object_id=i.object_id JOIN ' + @b + N'.sys.schemas s ON s.schema_id=t.schema_id
      WHERE t.is_ms_shipped=0 AND i.type>0';
    EXEC sp_executesql @sql, N'@base sysname, @etapa varchar(40)', @base, @etapa;
    SET @sql = N'INSERT dbo.Propiedades SELECT @base, @etapa, N''recovery'', recovery_model_desc FROM sys.databases WHERE name=@base
      UNION ALL SELECT @base, @etapa, N''rcsi'', CONVERT(nvarchar, is_read_committed_snapshot_on) FROM sys.databases WHERE name=@base
      UNION ALL SELECT @base, @etapa, N''querystore'', CONVERT(nvarchar, is_query_store_on) FROM sys.databases WHERE name=@base
      UNION ALL SELECT @base, @etapa, N''collation'', collation_name FROM sys.databases WHERE name=@base
      UNION ALL SELECT @base, @etapa, N''fork'', CONVERT(nvarchar(40), recovery_fork_guid) FROM sys.database_recovery_status WHERE database_id=DB_ID(@base)
      UNION ALL SELECT @base, @etapa, N''sp:'' + CONVERT(nvarchar(128), name), CONVERT(nvarchar(400), value) FROM ' + @b + N'.sys.extended_properties WHERE class=0
      UNION ALL SELECT @base, @etapa, N''seq:'' + s.name + N''.'' + q.name, CONVERT(nvarchar(60), q.minimum_value) + N''..'' + CONVERT(nvarchar(60), q.maximum_value) + N'' cur='' + CONVERT(nvarchar(60), q.current_value)
         FROM ' + @b + N'.sys.sequences q JOIN ' + @b + N'.sys.schemas s ON s.schema_id=q.schema_id';
    EXEC sp_executesql @sql, N'@base sysname, @etapa varchar(40)', @base, @etapa;

    -- Datos: filas y sumas de control sobre las columnas comparables que existían en la etapa de referencia (o las actuales)
    DECLARE @esq sysname, @tab sysname, @cols nvarchar(max), @n int, @t0 datetime2 , @refBase sysname = @base;
    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT DISTINCT c.Esquema, c.Tabla FROM dbo.Columnas c WHERE c.Base=@base AND c.Etapa=@etapa;
    OPEN cur; FETCH NEXT FROM cur INTO @esq, @tab;
    WHILE @@FETCH_STATUS=0
    BEGIN
        SELECT @cols = STRING_AGG(CONVERT(nvarchar(max), QUOTENAME(a.Columna)), N',') WITHIN GROUP (ORDER BY a.Columna), @n = COUNT(*)
          FROM dbo.Columnas a
         WHERE a.Base=@base AND a.Etapa=@etapa AND a.Esquema=@esq AND a.Tabla=@tab
           AND a.Tipo NOT IN ('xml','text','ntext','image','geography','geometry','timestamp','sql_variant','hierarchyid')
           AND (@etapaRef IS NULL OR EXISTS (SELECT 1 FROM dbo.Columnas r WHERE r.Base=@base AND r.Etapa=@etapaRef AND r.Esquema=@esq AND r.Tabla=@tab AND r.Columna=a.Columna));
        SET @n = ISNULL(@n,0); SET @t0 = SYSDATETIME();
        IF @cols IS NULL
            SET @sql = N'INSERT dbo.Datos SELECT @base, @etapa, @esq, @tab, COUNT_BIG(*), NULL, NULL, 0, 0 FROM ' + @b + N'.' + QUOTENAME(@esq) + N'.' + QUOTENAME(@tab);
        ELSE
            SET @sql = N'INSERT dbo.Datos SELECT @base, @etapa, @esq, @tab, COUNT_BIG(*), CHECKSUM_AGG(BINARY_CHECKSUM(' + @cols + N')), SUM(CONVERT(bigint, BINARY_CHECKSUM(' + @cols + N'))), @n, 0 FROM '
                + @b + N'.' + QUOTENAME(@esq) + N'.' + QUOTENAME(@tab);
        EXEC sp_executesql @sql, N'@base sysname, @etapa varchar(40), @esq sysname, @tab sysname, @n int', @base, @etapa, @esq, @tab, @n;
        UPDATE dbo.Datos SET Ms = DATEDIFF(ms, @t0, SYSDATETIME()) WHERE Base=@base AND Etapa=@etapa AND Esquema=@esq AND Tabla=@tab;
        FETCH NEXT FROM cur INTO @esq, @tab;
    END
    CLOSE cur; DEALLOCATE cur;
    SELECT Etapa=@etapa, Tablas=(SELECT COUNT(*) FROM dbo.Datos WHERE Base=@base AND Etapa=@etapa),
           Filas=(SELECT SUM(Filas) FROM dbo.Datos WHERE Base=@base AND Etapa=@etapa),
           Objetos=(SELECT COUNT(*) FROM dbo.Objetos WHERE Base=@base AND Etapa=@etapa),
           Columnas=(SELECT COUNT(*) FROM dbo.Columnas WHERE Base=@base AND Etapa=@etapa),
           Indices=(SELECT COUNT(*) FROM dbo.Indices WHERE Base=@base AND Etapa=@etapa);
END
GO
-- Compara dos etapas de una base: esquema (objetos, columnas, índices, propiedades) y datos (filas y sumas)
CREATE OR ALTER PROCEDURE dbo.Comparar @base sysname, @a varchar(40), @b varchar(40)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 'objeto' Que, COALESCE(x.Esquema,y.Esquema)+'.'+COALESCE(x.Nombre,y.Nombre) Nombre, x.Tipo TipoA, y.Tipo TipoB,
           CASE WHEN x.Nombre IS NULL THEN 'nuevo' WHEN y.Nombre IS NULL THEN 'quitado' ELSE 'definicion' END Cambio
      FROM (SELECT * FROM dbo.Objetos WHERE Base=@base AND Etapa=@a) x
      FULL JOIN (SELECT * FROM dbo.Objetos WHERE Base=@base AND Etapa=@b) y ON y.Esquema=x.Esquema AND y.Nombre=x.Nombre AND y.Tipo=x.Tipo
     WHERE x.Nombre IS NULL OR y.Nombre IS NULL OR ISNULL(x.Definicion,0x)<>ISNULL(y.Definicion,0x)
     ORDER BY 2;
    SELECT 'columna' Que, COALESCE(x.Esquema,y.Esquema)+'.'+COALESCE(x.Tabla,y.Tabla)+'.'+COALESCE(x.Columna,y.Columna) Nombre,
           CASE WHEN x.Columna IS NULL THEN 'nueva' WHEN y.Columna IS NULL THEN 'quitada' ELSE 'cambiada' END Cambio,
           x.Tipo+'('+CONVERT(varchar,x.Largo)+')'+CASE x.Nulo WHEN 1 THEN ' null' ELSE '' END A, y.Tipo+'('+CONVERT(varchar,y.Largo)+')'+CASE y.Nulo WHEN 1 THEN ' null' ELSE '' END B
      FROM (SELECT * FROM dbo.Columnas WHERE Base=@base AND Etapa=@a) x
      FULL JOIN (SELECT * FROM dbo.Columnas WHERE Base=@base AND Etapa=@b) y ON y.Esquema=x.Esquema AND y.Tabla=x.Tabla AND y.Columna=x.Columna
     WHERE x.Columna IS NULL OR y.Columna IS NULL OR x.Tipo<>y.Tipo OR x.Largo<>y.Largo OR x.Nulo<>y.Nulo OR x.Prec<>y.Prec OR x.Escala<>y.Escala
        OR ISNULL(x.Defecto,'')<>ISNULL(y.Defecto,'') OR ISNULL(x.Intercalacion,'')<>ISNULL(y.Intercalacion,'')
     ORDER BY 2;
    SELECT 'indice' Que, COALESCE(x.Esquema,y.Esquema)+'.'+COALESCE(x.Tabla,y.Tabla)+'.'+COALESCE(x.Indice,y.Indice) Nombre,
           CASE WHEN x.Indice IS NULL THEN 'nuevo' WHEN y.Indice IS NULL THEN 'quitado' ELSE 'cambiado' END Cambio
      FROM (SELECT * FROM dbo.Indices WHERE Base=@base AND Etapa=@a) x
      FULL JOIN (SELECT * FROM dbo.Indices WHERE Base=@base AND Etapa=@b) y ON y.Esquema=x.Esquema AND y.Tabla=x.Tabla AND y.Indice=x.Indice
     WHERE x.Indice IS NULL OR y.Indice IS NULL OR x.Columnas<>y.Columnas OR ISNULL(x.Filtro,'')<>ISNULL(y.Filtro,'') OR x.Unico<>y.Unico
     ORDER BY 2;
    SELECT 'propiedad' Que, COALESCE(x.Nombre,y.Nombre) Nombre, x.Valor A, y.Valor B
      FROM (SELECT * FROM dbo.Propiedades WHERE Base=@base AND Etapa=@a) x
      FULL JOIN (SELECT * FROM dbo.Propiedades WHERE Base=@base AND Etapa=@b) y ON y.Nombre=x.Nombre
     WHERE ISNULL(x.Valor,'~')<>ISNULL(y.Valor,'~') ORDER BY 2;
    SELECT 'datos' Que, COALESCE(x.Esquema,y.Esquema)+'.'+COALESCE(x.Tabla,y.Tabla) Tabla, x.Filas FilasA, y.Filas FilasB,
           CASE WHEN x.Tabla IS NULL THEN 'tabla nueva' WHEN y.Tabla IS NULL THEN 'tabla quitada' WHEN x.Filas<>y.Filas THEN 'filas' ELSE 'contenido' END Cambio
      FROM (SELECT * FROM dbo.Datos WHERE Base=@base AND Etapa=@a) x
      FULL JOIN (SELECT * FROM dbo.Datos WHERE Base=@base AND Etapa=@b) y ON y.Esquema=x.Esquema AND y.Tabla=x.Tabla
     WHERE x.Tabla IS NULL OR y.Tabla IS NULL OR x.Filas<>y.Filas OR ISNULL(x.ChkAgg,0)<>ISNULL(y.ChkAgg,0) OR ISNULL(x.ChkSum,0)<>ISNULL(y.ChkSum,0)
     ORDER BY 2;
END
GO
