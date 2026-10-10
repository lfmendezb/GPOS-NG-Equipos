SET NOCOUNT ON;
SELECT 'EMP' b, MigrationId, ProductVersion FROM GPOS_DEMO.conf.__EFMigrationsHistory ORDER BY MigrationId;
SELECT 'EMP maxmod' b, CONVERT(varchar(23), MAX(modify_date),121) maxmod, COUNT(*) objs FROM GPOS_DEMO.sys.objects WHERE is_ms_shipped=0;
SELECT 'SYS maxmod' b, CONVERT(varchar(23), MAX(modify_date),121) maxmod, COUNT(*) objs FROM GPOS_SYSDATA.sys.objects WHERE is_ms_shipped=0;
SELECT 'EMP schemas' b, s.name, COUNT(*) tablas FROM GPOS_DEMO.sys.tables t JOIN GPOS_DEMO.sys.schemas s ON s.schema_id=t.schema_id GROUP BY s.name ORDER BY s.name;
SELECT 'files' b, DB_NAME(database_id) db, name, physical_name, size*8/1024 MB FROM sys.master_files WHERE DB_NAME(database_id) IN ('GPOS_DEMO','GPOS_SYSDATA');
SELECT 'collation' b, DATABASEPROPERTYEX('GPOS_DEMO','Collation') c1, DATABASEPROPERTYEX('GPOS_SYSDATA','Collation') c2;
