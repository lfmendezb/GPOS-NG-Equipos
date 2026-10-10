IF DATABASE_PRINCIPAL_ID(N'gpos_reportes') IS NULL CREATE ROLE gpos_reportes AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID(N'gpos_lectura') IS NULL CREATE ROLE gpos_lectura AUTHORIZATION dbo;
IF SCHEMA_ID(N'rpt') IS NOT NULL
BEGIN
    GRANT SELECT ON SCHEMA::rpt TO gpos_reportes;
    GRANT SELECT ON SCHEMA::rpt TO gpos_lectura;
END;
IF SCHEMA_ID(N'rptc') IS NOT NULL
BEGIN
    GRANT SELECT ON SCHEMA::rptc TO gpos_lectura;
    DENY SELECT ON SCHEMA::rptc TO gpos_reportes;
END;
IF SCHEMA_ID(N'imp') IS NOT NULL
BEGIN
    GRANT SELECT ON SCHEMA::imp TO gpos_lectura;
    DENY SELECT ON SCHEMA::imp TO gpos_reportes;
END;
DENY CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE FUNCTION, CREATE SCHEMA, CREATE TYPE, CREATE SYNONYM
    TO gpos_reportes, gpos_lectura;
DECLARE @denegar nvarchar(max) = N'';
SELECT @denegar = @denegar + N'DENY SELECT, INSERT, UPDATE, DELETE, EXECUTE, ALTER ON SCHEMA::' + QUOTENAME(s.name)
                + N' TO gpos_reportes, gpos_lectura;' + NCHAR(10)
  FROM sys.schemas s
 WHERE (s.schema_id = 1 OR s.schema_id BETWEEN 5 AND 16383)
   AND s.name NOT IN (N'rpt', N'rptc', N'imp');
SELECT @denegar = @denegar + N'DENY INSERT, UPDATE, DELETE, EXECUTE, ALTER ON SCHEMA::' + QUOTENAME(s.name)
                + N' TO gpos_reportes, gpos_lectura;' + NCHAR(10)
  FROM sys.schemas s
 WHERE s.name IN (N'rpt', N'rptc', N'imp');
EXEC sys.sp_executesql @denegar;
IF EXISTS (SELECT 1 FROM sys.database_permissions p
            WHERE p.grantee_principal_id = DATABASE_PRINCIPAL_ID(N'guest') AND p.permission_name = N'CONNECT' AND p.state IN ('G', 'W'))
    REVOKE CONNECT FROM guest;
