/* Índice de rpt.MovimientoCaja (medición, sección 5 del documento): IX_CajaMovimiento_Jornada (JornadaId) pasa a incluir Tasa,
   SucursalId, MovimientoRevertidoId y RegistradoEn. Con 2.000.000 de movimientos: un día y una caja de 430 ms (recorrido de
   26.793 páginas) a 4 ms; mes y una caja, totales, de 554 a 154 ms. Costo: +22 MB por 2 millones de filas (≈11 B por fila);
   caja.Movimiento es de solo inserción (sin costo de actualización). Creación: 2,5 s con 2 millones de filas (DROP_EXISTING,
   sin quedarse sin índice; OFFLINE en Express y Standard: bloquea las inserciones de caja mientras dura → ventana de la migración). */
SET NOCOUNT ON;
IF NOT EXISTS (SELECT 1 FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
                WHERE ic.object_id = OBJECT_ID(N'caja.Movimiento') AND ic.index_id = INDEXPROPERTY(OBJECT_ID(N'caja.Movimiento'), N'IX_CajaMovimiento_Jornada', N'IndexID')
                  AND c.name = N'MovimientoRevertidoId')
    CREATE INDEX IX_CajaMovimiento_Jornada ON caja.Movimiento (JornadaId)
        INCLUDE (Tipo, MonedaId, Monto, Tasa, SucursalId, MovimientoRevertidoId, RegistradoEn) WITH (DROP_EXISTING = ON);
GO
