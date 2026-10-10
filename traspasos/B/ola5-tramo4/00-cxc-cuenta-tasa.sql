/* =====================================================================================================================
   Ola 5 · Tramo 4 (ADR-109, Q-1 a Q-6 del 2026-10-10) · cxc.Cuenta.Tasa (H-T4-02 del plan)
   Autor: arquitecto-datos, equipo B · 2026-10-10 · PROPUESTA (no aplicada a ninguna base real)

   Qué hace
   - Agrega cxc.Cuenta.Tasa decimal(19,6) NOT NULL, SIN valor por omisión, simétrica a cxp.Cuenta.Tasa.
   - Relleno: la tasa de ventas.Venta del mismo documento. Verificado en feature/modelo-ng ec459d5: los cuatro llamadores de
     Partidas.RegistrarCuentaAsync (FAC a crédito, ND, CHD e importación de facturas, CA-46) escriben antes ventas.Venta con Tasa
     (CobrosService.cs:405-418 y :540-551, DocumentosComercialesService.Ventas.cs:319, ImportacionesService.cs:452-459).
   - Falla cerrada si una cuenta no tiene ventas.Venta (no se inventa una tasa): THROW 51399 sin cambiar nada.
   - CK_Cuenta_Tasa (Tasa > 0), como CK_CxpCuenta_Tasa.
   - IX_Cuenta_ClienteVencimiento pasa a incluir Tasa (filtrado SaldoPendiente > 0): la tarjeta de CxC y los totales en moneda
     base de los reportes 8, 9, 10 y 27 leen el índice sin buscar en la tabla. Tasa no cambia después del INSERT: costo de
     escritura nulo. Medición en la sección 5 del documento.

   Idempotente: cada paso comprueba el estado (este guion es para la prueba; en la rama va como migración EF
   Ola5VistasTramo4: AddColumn nullable → Sql(relleno, en EXEC) → AlterColumn NOT NULL → AddCheckConstraint → índice).
   Reversión: al final, comentada (quita índice, CHECK y columna; sin pérdida: la tasa sigue en ventas.Venta).
   ===================================================================================================================== */
SET XACT_ABORT ON;
SET NOCOUNT ON;
GO
-- 1. Columna, nulable para poder rellenar (sin DEFAULT: un INSERT que no la mande debe fallar, no tomar 1)
IF COL_LENGTH(N'cxc.Cuenta', N'Tasa') IS NULL
    ALTER TABLE cxc.Cuenta ADD Tasa decimal(19, 6) NULL;
GO
-- 2. Relleno desde ventas.Venta; falla cerrada si alguna cuenta no tiene venta
BEGIN TRANSACTION;
IF EXISTS (SELECT 1 FROM cxc.Cuenta c WITH (UPDLOCK, HOLDLOCK)
            WHERE c.Tasa IS NULL AND NOT EXISTS (SELECT 1 FROM ventas.Venta v WHERE v.DocumentoId = c.DocumentoId))
BEGIN
    ROLLBACK;
    THROW 51399, N'cxc.Cuenta.Tasa: hay cuentas por cobrar sin ventas.Venta; no se puede deducir su tasa. Revise rpt.ConciliacionCxc antes de aplicar Ola5VistasTramo4.', 1;
END;
UPDATE c SET c.Tasa = v.Tasa
  FROM cxc.Cuenta c JOIN ventas.Venta v ON v.DocumentoId = c.DocumentoId
 WHERE c.Tasa IS NULL;
COMMIT;
GO
-- 3. NOT NULL (valida la tabla con Sch-M breve; 200.000 filas: < 1 s medido en la sección 5)
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'cxc.Cuenta') AND name = N'Tasa' AND is_nullable = 1)
    ALTER TABLE cxc.Cuenta ALTER COLUMN Tasa decimal(19, 6) NOT NULL;
GO
-- 4. Invariante (RB-P1: dato del documento, nunca 0 ni negativo)
IF OBJECT_ID(N'cxc.CK_Cuenta_Tasa', N'C') IS NULL
    ALTER TABLE cxc.Cuenta WITH CHECK ADD CONSTRAINT CK_Cuenta_Tasa CHECK (Tasa > 0);
GO
-- 5. Índice filtrado existente con Tasa incluida (mismo nombre, mismas claves y filtro; DROP_EXISTING)
IF NOT EXISTS (SELECT 1 FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
                WHERE ic.object_id = OBJECT_ID(N'cxc.Cuenta') AND ic.index_id = INDEXPROPERTY(OBJECT_ID(N'cxc.Cuenta'), N'IX_Cuenta_ClienteVencimiento', N'IndexID')
                  AND c.name = N'Tasa')
    CREATE INDEX IX_Cuenta_ClienteVencimiento ON cxc.Cuenta (ClienteId, FechaVencimiento)
        INCLUDE (SaldoPendiente, MonedaId, Tasa) WHERE SaldoPendiente > 0 WITH (DROP_EXISTING = ON);
GO
/* Reversión (Down de la migración):
CREATE INDEX IX_Cuenta_ClienteVencimiento ON cxc.Cuenta (ClienteId, FechaVencimiento) INCLUDE (SaldoPendiente, MonedaId)
    WHERE SaldoPendiente > 0 WITH (DROP_EXISTING = ON);
ALTER TABLE cxc.Cuenta DROP CONSTRAINT IF EXISTS CK_Cuenta_Tasa;
-- Las vistas rpt.CxcDocumento (y cualquier otra que lea c.Tasa) se borran ANTES (Down de las vistas va primero).
ALTER TABLE cxc.Cuenta DROP COLUMN IF EXISTS Tasa;
*/
