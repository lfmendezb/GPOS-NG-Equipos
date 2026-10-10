CREATE OR ALTER TRIGGER doc.TR_Documento_Anulacion ON doc.Documento AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(Estado) RETURN;
    IF NOT EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON d.Id = i.Id WHERE d.Estado = 1 AND i.Estado = 2) RETURN;

    IF EXISTS (SELECT 1 FROM inserted a JOIN deleted d ON d.Id = a.Id AND d.Estado = 1 AND a.Estado = 2
                JOIN fiscal.Comprobante c ON c.DocumentoId = a.Id WHERE a.CodigoAnulacion608 IS NULL)
        THROW 51312, N'Anular un documento con NCF exige el código del 608 (CA-02).', 1;
    IF EXISTS (SELECT 1 FROM inserted a JOIN deleted d ON d.Id = a.Id AND d.Estado = 1 AND a.Estado = 2 JOIN inv.Movimiento m ON m.DocumentoId = a.Id
               WHERE m.MovimientoRevertidoId IS NULL AND NOT EXISTS (SELECT 1 FROM inv.Movimiento r WHERE r.MovimientoRevertidoId = m.Id))
        THROW 51313, N'La anulación debe revertir el kárdex del documento (CA-02).', 1;
    IF EXISTS (SELECT 1 FROM inserted a JOIN deleted d ON d.Id = a.Id AND d.Estado = 1 AND a.Estado = 2 JOIN caja.Movimiento m ON m.DocumentoId = a.Id
               WHERE m.MovimientoRevertidoId IS NULL AND NOT EXISTS (SELECT 1 FROM caja.Movimiento r WHERE r.MovimientoRevertidoId = m.Id))
        THROW 51314, N'La anulación debe revertir los movimientos de caja del documento (CA-02).', 1;
    IF EXISTS (SELECT 1 FROM inserted a JOIN deleted d ON d.Id = a.Id AND d.Estado = 1 AND a.Estado = 2 JOIN cxc.Aplicacion x ON x.DocumentoAplicaId = a.Id
                WHERE x.Anulada = 0)
        THROW 51315, N'La anulación debe dejar sin efecto las aplicaciones del documento (CA-03).', 1;
    IF EXISTS (SELECT 1 FROM inserted a JOIN deleted d ON d.Id = a.Id AND d.Estado = 1 AND a.Estado = 2 JOIN cxc.Cuenta c ON c.DocumentoId = a.Id
               WHERE c.SaldoPendiente <> 0 OR EXISTS (SELECT 1 FROM cxc.Aplicacion x WHERE x.DocumentoAfectadoId = a.Id AND x.Anulada = 0))
        THROW 51316, N'No se anula un documento con aplicaciones vigentes; use una nota de crédito (MD-17).', 1;
    IF EXISTS (SELECT 1 FROM inserted a JOIN deleted d ON d.Id = a.Id AND d.Estado = 1 AND a.Estado = 2 JOIN cxc.Credito c ON c.DocumentoId = a.Id
                WHERE c.SaldoDisponible <> 0)
        THROW 51316, N'El saldo a favor de la nota anulada debe quedar en 0 y sin uso (MD-17).', 1;
    IF EXISTS (SELECT 1 FROM inserted a JOIN deleted d ON d.Id = a.Id AND d.Estado = 1 AND a.Estado = 2 JOIN ventas.Venta v ON v.DocumentoId = a.Id
                JOIN caja.Jornada j ON j.Id = v.JornadaId WHERE j.Estado <> 'A')
       OR EXISTS (SELECT 1 FROM inserted a JOIN deleted d ON d.Id = a.Id AND d.Estado = 1 AND a.Estado = 2 JOIN cxc.Recibo r ON r.DocumentoId = a.Id
                   JOIN caja.Jornada j ON j.Id = r.JornadaId WHERE j.Estado <> 'A')
        THROW 51317, N'Solo se anula con la jornada abierta (MD-17).', 1;
    -- D-MVP-02 (Ola4OrdenRecibida, I-3): la entrada de una orden ya facturada no se anula; se anula primero la factura
    IF EXISTS (SELECT 1 FROM inserted a JOIN deleted d ON d.Id = a.Id AND d.Estado = 1 AND a.Estado = 2
                JOIN inv.DocInventario x ON x.DocumentoId = a.Id JOIN compras.Compra c ON c.DocumentoId = x.OrdenCompraId
                WHERE c.Situacion = 'FACTURADA')
        THROW 51406, N'No se anula una entrada cuya orden de compra ya fue facturada: anule primero la factura (ENTRADA_ORDEN_FACTURADA).', 1;
END
