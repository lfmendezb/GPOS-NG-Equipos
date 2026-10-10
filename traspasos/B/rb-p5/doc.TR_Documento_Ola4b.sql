CREATE OR ALTER TRIGGER doc.TR_Documento_Ola4b ON doc.Documento AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(Estado) RETURN;
    -- K-06 y MD-59: la incorporación de un nodo y la reaplicación entran con sus fechas; las informa rpt.DocumentosPeriodoReabierto (P-7)
    IF SESSION_CONTEXT(N'gpos.incorporacion') IS NOT NULL OR SESSION_CONTEXT(N'gpos.reaplicacion') IS NOT NULL RETURN;
    -- Una sola lectura del conjunto derivado (sin variable de tabla, C-1). ControlFecha: 1 = fecha del servidor (solo F-7), 2 = F-1 y F-3 a F-7,
    -- 3 = además F-2. La emisión del POS (ControlFecha 1) sale aquí, sin leer la configuración.
    DECLARE @anula bit, @oficina bit;
    SELECT @anula = MAX(e.Anula), @oficina = MAX(CASE WHEN e.ControlFecha >= 2 AND e.Origen <> 'I' AND e.Emite = 1 THEN 1 ELSE 0 END)
      FROM (SELECT i.Id, t.Codigo, t.ControlFecha, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND t.ControlFecha > 0) e;
    IF ISNULL(@anula, 0) = 0 AND ISNULL(@oficina, 0) = 0 RETURN;

    -- Configuración: S retenido hasta el fin de la transacción (la declaración toma X y espera a los documentos en vuelo; nivel «configuración»)
    DECLARE @declarado date, @tope tinyint;
    SELECT @declarado = p.FiscalDeclaradoHasta, @tope = p.TopeDiasAnteriores FROM conf.Parametros p WITH (REPEATABLEREAD) WHERE p.Id = 1;

    -- F-6 y F-7: período fiscal declarado (sin privilegio que lo salte)
    IF @declarado IS NOT NULL
    BEGIN
        IF @oficina = 1 AND EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.ControlFecha, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND t.ControlFecha > 0) e WHERE e.Emite = 1 AND e.ControlFecha >= 2 AND e.Origen <> 'I' AND e.Fecha <= @declarado)
            THROW 51371, N'El mes del documento ya fue declarado a la DGII (PERIODO_FISCAL_DECLARADO). Use una fecha de un mes no declarado o pida al contador que reabra el período.', 1;
        IF @anula = 1 AND EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.ControlFecha, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND t.ControlFecha > 0) e WHERE e.Anula = 1 AND e.Fecha <= @declarado)
            THROW 51372, N'El documento pertenece a un mes declarado (PERIODO_FISCAL_DECLARADO_ANULAR): corríjalo con una nota fechada hoy o pida que se reabra el período.', 1;
    END

    IF @oficina = 1
    BEGIN
        -- Hoy de la empresa (UTC−4, sin horario de verano), con 5 minutos de holgura entre el reloj de la API y el del motor
        DECLARE @ahora datetime2(3) = SYSUTCDATETIME();
        DECLARE @hoyMax date = CONVERT(date, DATEADD(MINUTE, -235, @ahora)), @hoyMin date = CONVERT(date, DATEADD(MINUTE, -245, @ahora));
        -- F-1
        IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.ControlFecha, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND t.ControlFecha > 0) e WHERE e.Emite = 1 AND e.ControlFecha >= 2 AND e.Origen <> 'I' AND e.Fecha > @hoyMax)
            THROW 51367, N'La fecha del documento no puede ser posterior a hoy (FECHA_FUTURA).', 1;
        -- F-2: retrofecha dentro del tope y con su autorización (privilegio y motivo, que exige el servicio y deja en doc.Autorizacion)
        IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.ControlFecha, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND t.ControlFecha > 0) e WHERE e.Emite = 1 AND e.ControlFecha = 3 AND e.Origen <> 'I' AND e.Fecha < @hoyMin
                      AND DATEDIFF(DAY, e.Fecha, @hoyMin) > @tope)
            THROW 51368, N'La fecha del documento supera el máximo de días anteriores permitido en esta empresa (FECHA_FUERA_DE_TOPE).', 1;
        IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.ControlFecha, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND t.ControlFecha > 0) e WHERE e.Emite = 1 AND e.ControlFecha = 3 AND e.Origen <> 'I' AND e.Fecha < @hoyMin
                      AND NOT EXISTS (SELECT 1 FROM doc.Autorizacion z WHERE z.DocumentoId = e.Id AND z.Tipo = 'FECHA_ANTERIOR'))
            THROW 51368, N'No tiene autorización para registrar documentos con fecha anterior a hoy. Use la fecha de hoy o solicite la operación a un usuario autorizado (FECHA_ANTERIOR_SIN_PRIVILEGIO).', 1;
        -- F-3: la nota no es anterior a su factura (ventas y compras); en las notas del suplidor, tampoco su comprobante
        IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.ControlFecha, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND t.ControlFecha > 0) e JOIN ventas.Venta v ON v.DocumentoId = e.Id JOIN doc.Documento o ON o.Id = v.DocumentoOrigenId
                    WHERE e.Emite = 1 AND e.ControlFecha >= 2 AND e.Origen <> 'I' AND e.Codigo IN ('NC', 'ND', 'DEV') AND e.Fecha < o.Fecha)
           OR EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.ControlFecha, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND t.ControlFecha > 0) e JOIN compras.Compra c ON c.DocumentoId = e.Id JOIN doc.Documento o ON o.Id = c.DocumentoOrigenId
                       LEFT JOIN fiscal.Registro606 r ON r.DocumentoId = e.Id LEFT JOIN fiscal.Registro606 ro ON ro.DocumentoId = o.Id
                       WHERE e.Emite = 1 AND e.Origen <> 'I' AND e.Codigo IN ('DVS', 'NCP', 'NDP')
                         AND (e.Fecha < o.Fecha OR r.FechaComprobante < ro.FechaComprobante))
            THROW 51369, N'La nota no puede tener fecha anterior a la de su factura (FECHA_ANTERIOR_A_FACTURA).', 1;
        -- F-4: el recibo, el pago o la aplicación no son anteriores a lo que aplican (en compras, tampoco al comprobante)
        IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.ControlFecha, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND t.ControlFecha > 0) e JOIN cxc.Aplicacion a ON a.DocumentoAplicaId = e.Id AND a.Anulada = 0 JOIN doc.Documento f ON f.Id = a.DocumentoAfectadoId
                    WHERE e.Emite = 1 AND e.ControlFecha >= 2 AND e.Origen <> 'I' AND f.Fecha > e.Fecha)
           OR EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.ControlFecha, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND t.ControlFecha > 0) e JOIN cxp.Aplicacion a ON a.DocumentoAplicaId = e.Id AND a.Anulada = 0 JOIN doc.Documento f ON f.Id = a.DocumentoAfectadoId
                       LEFT JOIN fiscal.Registro606 r ON r.DocumentoId = f.Id
                       WHERE e.Emite = 1 AND e.ControlFecha >= 2 AND e.Origen <> 'I' AND (f.Fecha > e.Fecha OR r.FechaComprobante > e.Fecha))
            THROW 51369, N'El documento no puede tener fecha anterior a la de los documentos que aplica (FECHA_ANTERIOR_A_FACTURA).', 1;
        -- 2.5: el plazo fiscal de 30 días se mide con el hoy de la empresa: una nota fuera de plazo no se marca dentro (art. 8, Decreto 293-11)
        IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.ControlFecha, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND t.ControlFecha > 0) e JOIN ventas.Venta v ON v.DocumentoId = e.Id JOIN doc.Documento o ON o.Id = v.DocumentoOrigenId
                    WHERE e.Emite = 1 AND e.Origen <> 'I' AND e.Codigo IN ('NC', 'DEV') AND v.FueraPlazoFiscal = 0 AND DATEDIFF(DAY, o.Fecha, @hoyMin) > 30)
            THROW 51379, N'La nota se emite pasados 30 días de su factura: debe quedar marcada fuera del plazo fiscal (PLAZO_FISCAL).', 1;
        -- P-9 (A-6 en ventas): la nota de crédito lleva un concepto de ventas sin mercancía; la devolución, si lo lleva, es «DEV»
            IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.ControlFecha, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND t.ControlFecha > 0) e JOIN ventas.Venta v ON v.DocumentoId = e.Id LEFT JOIN cat.ConceptoNota k ON k.Codigo = v.ConceptoNotaCodigo
                        WHERE e.Emite = 1 AND e.Origen <> 'I'
                          AND ((e.Codigo = 'NC' AND (k.Codigo IS NULL OR k.AplicaA NOT IN ('A', 'V') OR k.ConMercancia = 1))
                               OR (e.Codigo = 'DEV' AND v.ConceptoNotaCodigo IS NOT NULL AND v.ConceptoNotaCodigo <> 'DEV')
                               OR (e.Codigo NOT IN ('NC', 'DEV') AND v.ConceptoNotaCodigo IS NOT NULL)))
                THROW 51365, N'La nota de crédito de ventas exige un concepto de ventas sin mercancía, y la devolución solo admite «Devolución de mercancía» (CONCEPTO_NOTA).', 1;
            -- HC-10: el ITBIS y el ISC llevados al costo del 606 son los de las líneas
        IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.ControlFecha, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND t.ControlFecha > 0) e JOIN fiscal.Registro606 r ON r.DocumentoId = e.Id
                    OUTER APPLY (SELECT ROUND(SUM(l.ItbisAlCosto) * MAX(c.Tasa), 2) AS Itbis, ROUND(SUM(l.IscAlCosto) * MAX(c.Tasa), 2) AS Isc FROM compras.CompraLinea l JOIN compras.Compra c ON c.DocumentoId = l.DocumentoId WHERE l.DocumentoId = e.Id) l
                    WHERE e.Emite = 1 AND e.Origen <> 'I' AND e.Codigo IN ('FCP', 'NCP', 'NDP')
                      AND (r.ItbisAlCosto <> ISNULL(l.Itbis, 0) OR r.Isc < ISNULL(l.Isc, 0)))
            THROW 51359, N'El ITBIS o el ISC llevados al costo en el 606 no coinciden con las líneas de la compra (COMPRA_606_COSTO).', 1;
        -- F-5: fecha del comprobante del suplidor ≤ fecha de registro
        IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.ControlFecha, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND t.ControlFecha > 0) e JOIN fiscal.Registro606 r ON r.DocumentoId = e.Id WHERE e.Emite = 1 AND e.Origen <> 'I' AND r.FechaComprobante > e.Fecha)
            THROW 51370, N'La fecha del comprobante no puede ser posterior a la fecha de registro (FECHA_COMPROBANTE_INVALIDA).', 1;

        -- ---------------- A-1: la devolución a suplidor
        IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.ControlFecha, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND t.ControlFecha > 0) e WHERE e.Emite = 1 AND e.Codigo = 'DVS' AND e.Origen <> 'I')
        BEGIN
            IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.ControlFecha, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND t.ControlFecha > 0) e JOIN compras.Compra c ON c.DocumentoId = e.Id
                         LEFT JOIN compras.Compra f ON f.DocumentoId = c.DocumentoOrigenId
                         LEFT JOIN doc.Documento fd ON fd.Id = f.DocumentoId
                         LEFT JOIN doc.TipoDocumento ft ON ft.Id = fd.TipoDocumentoId
                         LEFT JOIN cxp.Credito n ON n.DocumentoId = e.Id
                        WHERE e.Emite = 1 AND e.Codigo = 'DVS' AND e.Origen <> 'I'
                          AND (f.DocumentoId IS NULL OR ft.Codigo <> 'FCP' OR fd.Estado <> 1 OR f.SuplidorId <> c.SuplidorId OR f.MonedaId <> c.MonedaId
                               OR n.DocumentoId IS NULL OR n.Monto <> c.Total OR n.SuplidorId <> c.SuplidorId OR n.MonedaId <> c.MonedaId OR n.SaldoDisponible <> n.Monto))
                THROW 51361, N'La devolución a suplidor debe citar una factura de compra vigente del mismo suplidor y moneda, y crear su saldo a favor por el valor del reclamo (DEVOLUCION_INVALIDA).', 1;
            -- Cada línea cita una línea de esa factura, al mismo precio neto, y lo devuelto no supera lo comprado (R4-39)
            IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.ControlFecha, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND t.ControlFecha > 0) e JOIN compras.Compra c ON c.DocumentoId = e.Id JOIN compras.CompraLinea l ON l.DocumentoId = e.Id
                         LEFT JOIN compras.CompraLinea o ON o.DocumentoId = l.OrigenDocumentoId AND o.Linea = l.OrigenLinea
                        WHERE e.Emite = 1 AND e.Codigo = 'DVS' AND e.Origen <> 'I'
                          AND (o.DocumentoId IS NULL OR l.OrigenDocumentoId <> c.DocumentoOrigenId OR ISNULL(o.ArticuloId, -1) <> ISNULL(l.ArticuloId, -1)
                               OR ISNULL(o.UnidadId, -1) <> ISNULL(l.UnidadId, -1) OR o.CostoUnitario <> l.CostoUnitario OR o.PorcDescuento <> l.PorcDescuento
                               OR o.ImpuestoId <> l.ImpuestoId
                               OR EXISTS (SELECT 1 FROM compras.CompraLinea x WITH (READCOMMITTEDLOCK)
                                            JOIN doc.Documento xd WITH (READCOMMITTEDLOCK) ON xd.Id = x.DocumentoId AND (xd.Estado = 1 OR xd.Id = e.Id)
                                            JOIN doc.TipoDocumento xt ON xt.Id = xd.TipoDocumentoId AND xt.Codigo = 'DVS'
                                           WHERE x.OrigenDocumentoId = o.DocumentoId AND x.OrigenLinea = o.Linea
                                          HAVING SUM(x.Cantidad) > o.Cantidad OR SUM(x.Impuesto) > o.Impuesto)))
                THROW 51362, N'La línea devuelta no coincide con la de la factura (artículo, unidad, precio, descuento o impuesto) o supera lo comprado (DEVOLUCION_EXCEDE).', 1;
        END

        -- ---------------- A-2, A-3 y A-6: la nota del suplidor y la baja regularizan la devolución sin volver a acreditar
        IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.ControlFecha, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND t.ControlFecha > 0) e WHERE e.Emite = 1 AND e.Codigo IN ('NCP', 'APS'))
        BEGIN
            -- A-6: concepto obligatorio de la nota del suplidor; «DEV» si y solo si regulariza devoluciones
            IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.ControlFecha, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND t.ControlFecha > 0) e JOIN compras.Compra c ON c.DocumentoId = e.Id LEFT JOIN cat.ConceptoNota k ON k.Codigo = c.ConceptoNotaCodigo
                        WHERE e.Emite = 1 AND e.Codigo = 'NCP'
                          AND (k.Codigo IS NULL OR k.AplicaA NOT IN ('A', 'C')
                               OR (k.Codigo = 'DEV' AND NOT EXISTS (SELECT 1 FROM cxp.Regularizacion g WHERE g.DocumentoId = e.Id))
                               OR (k.Codigo <> 'DEV' AND EXISTS (SELECT 1 FROM cxp.Regularizacion g WHERE g.DocumentoId = e.Id))))
                THROW 51365, N'La nota del suplidor exige su concepto; «DEV» solo si regulariza devoluciones, y toda nota que las regulariza es «DEV» (CONCEPTO_NOTA).', 1;
            -- La nota cita la factura que modifica: del mismo suplidor y, si la factura tiene NCF recibido, con ese NCF como modificado (R4-37)
            IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.ControlFecha, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND t.ControlFecha > 0) e JOIN compras.Compra c ON c.DocumentoId = e.Id
                         LEFT JOIN compras.Compra f ON f.DocumentoId = c.DocumentoOrigenId LEFT JOIN doc.Documento fd ON fd.Id = f.DocumentoId
                         LEFT JOIN doc.TipoDocumento ft ON ft.Id = fd.TipoDocumentoId
                         LEFT JOIN fiscal.Registro606 r ON r.DocumentoId = e.Id LEFT JOIN fiscal.Registro606 rf ON rf.DocumentoId = f.DocumentoId
                        WHERE e.Emite = 1 AND e.Codigo = 'NCP' AND e.Origen <> 'I'
                          AND (f.DocumentoId IS NULL OR ft.Codigo <> 'FCP' OR fd.Estado <> 1 OR f.SuplidorId <> c.SuplidorId OR f.MonedaId <> c.MonedaId
                               OR (rf.Ncf IS NOT NULL AND ISNULL(r.NcfModificado, '') <> rf.Ncf)))
                THROW 51377, N'La nota del suplidor debe citar una factura de compra vigente del mismo suplidor y moneda, con su NCF como NCF modificado (NOTA_FACTURA_INVALIDA).', 1;
            -- A-2: cada devolución regularizada es vigente, del mismo suplidor y de la misma factura; lo regularizado no supera el reclamo
            IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.ControlFecha, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND t.ControlFecha > 0) e JOIN cxp.Regularizacion g ON g.DocumentoId = e.Id
                         JOIN compras.Compra v ON v.DocumentoId = g.DevolucionDocumentoId
                         JOIN doc.Documento vd ON vd.Id = v.DocumentoId JOIN doc.TipoDocumento vt ON vt.Id = vd.TipoDocumentoId
                         LEFT JOIN compras.Compra c ON c.DocumentoId = e.Id
                        WHERE e.Emite = 1
                          AND (vt.Codigo <> 'DVS' OR vd.Estado <> 1
                               OR (e.Codigo = 'NCP' AND (v.SuplidorId <> c.SuplidorId OR v.DocumentoOrigenId <> c.DocumentoOrigenId))
                               OR v.Total < (SELECT SUM(x.Monto) FROM cxp.Regularizacion x WITH (READCOMMITTEDLOCK)
                                               JOIN doc.Documento xd WITH (READCOMMITTEDLOCK) ON xd.Id = x.DocumentoId AND (xd.Estado = 1 OR xd.Id = e.Id)
                                              WHERE x.DevolucionDocumentoId = v.DocumentoId)))
                THROW 51363, N'Regularización inválida: devolución anulada, de otro suplidor u otra factura, o lo regularizado supera el valor del reclamo (REGULARIZACION_INVALIDA).', 1;
            -- A-2 (doble crédito): la nota mueve saldos solo por lo que no regulariza: total = aplicado + saldo a favor + regularizado
            IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.ControlFecha, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND t.ControlFecha > 0) e JOIN compras.Compra c ON c.DocumentoId = e.Id
                         OUTER APPLY (SELECT SUM(a.MontoAplica) AS Aplicado FROM cxp.Aplicacion a WHERE a.DocumentoAplicaId = e.Id AND a.Anulada = 0) a
                         OUTER APPLY (SELECT SUM(g.Monto) AS Regularizado FROM cxp.Regularizacion g WHERE g.DocumentoId = e.Id) g
                         LEFT JOIN cxp.Credito n ON n.DocumentoId = e.Id
                        WHERE e.Emite = 1 AND e.Codigo = 'NCP' AND e.Origen <> 'I'
                          AND (c.Total <> ISNULL(a.Aplicado, 0) + ISNULL(n.Monto, 0) + ISNULL(g.Regularizado, 0)
                               OR (n.DocumentoId IS NOT NULL AND (n.SuplidorId <> c.SuplidorId OR n.MonedaId <> c.MonedaId OR n.SaldoDisponible <> n.Monto))))
                THROW 51360, N'La nota del suplidor no cuadra: total = aplicado + saldo a favor + regularizado (NOTA_DESCUADRADA).', 1;
            -- A-3: la baja es una APS con su autorización, sin aplicaciones, que compensa solo saldos de las devoluciones que regulariza, por lo
            -- regularizado o hasta agotarlos
            IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.ControlFecha, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND t.ControlFecha > 0) e WHERE e.Emite = 1 AND e.Codigo = 'APS' AND EXISTS (SELECT 1 FROM cxp.Regularizacion g WHERE g.DocumentoId = e.Id)
                          AND (NOT EXISTS (SELECT 1 FROM doc.Autorizacion z WHERE z.DocumentoId = e.Id AND z.Tipo = 'BAJA_DEVOLUCION')
                               OR EXISTS (SELECT 1 FROM cxp.Aplicacion a WHERE a.DocumentoAplicaId = e.Id AND a.Anulada = 0)
                               OR EXISTS (SELECT 1 FROM cxp.Compensacion x LEFT JOIN cxp.Regularizacion g ON g.DocumentoId = e.Id AND g.DevolucionDocumentoId = x.CreditoDocumentoId
                                           WHERE x.DocumentoId = e.Id AND g.DocumentoId IS NULL)
                               OR EXISTS (SELECT 1 FROM cxp.Regularizacion g JOIN cxp.Credito n ON n.DocumentoId = g.DevolucionDocumentoId
                                            LEFT JOIN cxp.Compensacion x ON x.DocumentoId = e.Id AND x.CreditoDocumentoId = g.DevolucionDocumentoId
                                           WHERE g.DocumentoId = e.Id AND (ISNULL(x.Monto, 0) > g.Monto OR (ISNULL(x.Monto, 0) <> g.Monto AND n.SaldoDisponible <> 0)))))
                THROW 51366, N'La baja de una devolución sin nota exige su autorización, no aplica facturas y reduce el saldo a favor por lo regularizado o hasta agotarlo (BAJA_INVALIDA).', 1;
        END

        -- ---------------- HC-04: retenciones que practica el cliente, solo en el recibo, con su fecha y dentro de lo facturado
        IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.ControlFecha, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND t.ControlFecha > 0) e JOIN cxc.Aplicacion a ON a.DocumentoAplicaId = e.Id AND a.Anulada = 0
                    LEFT JOIN doc.Documento f ON f.Id = a.DocumentoAfectadoId LEFT JOIN ventas.Venta v ON v.DocumentoId = a.DocumentoAfectadoId
                    WHERE e.Emite = 1 AND a.RetencionItbis + a.RetencionIsr > 0
                      AND (e.Codigo <> 'REC' OR a.FechaRetencion > e.Fecha OR a.FechaRetencion < f.Fecha
                           OR (SELECT SUM(x.RetencionItbis) FROM cxc.Aplicacion x WITH (READCOMMITTEDLOCK)
                                 JOIN doc.Documento xd WITH (READCOMMITTEDLOCK) ON xd.Id = x.DocumentoAplicaId AND (xd.Estado = 1 OR xd.Id = e.Id)
                                WHERE x.DocumentoAfectadoId = a.DocumentoAfectadoId AND x.Anulada = 0) > ISNULL(v.Impuesto, 0)
                           OR (SELECT SUM(x.RetencionIsr) FROM cxc.Aplicacion x WITH (READCOMMITTEDLOCK)
                                 JOIN doc.Documento xd WITH (READCOMMITTEDLOCK) ON xd.Id = x.DocumentoAplicaId AND (xd.Estado = 1 OR xd.Id = e.Id)
                                WHERE x.DocumentoAfectadoId = a.DocumentoAfectadoId AND x.Anulada = 0) > ISNULL(v.SubTotal - v.Descuento, 0)))
            THROW 51374, N'Retención recibida inválida: solo en el recibo, con fecha entre la factura y el recibo, y sin superar el ITBIS ni la base de la factura (RETENCION_RECIBIDA_INVALIDA).', 1;

        -- ---------------- HC-09: monto en moneda base a la tasa de la factura en cada aplicación (el de la tasa del pago lo fija el servicio)
        IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.ControlFecha, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND t.ControlFecha > 0) e JOIN cxc.Aplicacion a ON a.DocumentoAplicaId = e.Id AND a.Anulada = 0 JOIN ventas.Venta v ON v.DocumentoId = a.DocumentoAfectadoId
                    WHERE e.Emite = 1 AND a.MontoBaseFactura <> ROUND((a.Monto + a.RetencionItbis + a.RetencionIsr) * v.Tasa, 2))
           OR EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.ControlFecha, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND t.ControlFecha > 0) e JOIN cxp.Aplicacion a ON a.DocumentoAplicaId = e.Id AND a.Anulada = 0 JOIN cxp.Cuenta p ON p.DocumentoId = a.DocumentoAfectadoId
                       WHERE e.Emite = 1 AND a.MontoBaseFactura <> ROUND((a.Monto + a.RetencionItbis + a.RetencionIsr) * p.Tasa, 2))
            THROW 51375, N'El monto en moneda base de la aplicación no coincide con la tasa de la factura (MONTO_BASE_INVALIDO).', 1;
    END

    -- ---------------- Anulación de una devolución con notas o bajas vigentes (A-2)
    IF @anula = 1 AND EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.ControlFecha, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND t.ControlFecha > 0) e JOIN cxp.Regularizacion g WITH (READCOMMITTEDLOCK) ON g.DevolucionDocumentoId = e.Id
                                JOIN doc.Documento x WITH (READCOMMITTEDLOCK) ON x.Id = g.DocumentoId AND x.Estado = 1
                               WHERE e.Anula = 1 AND e.Codigo = 'DVS')
        THROW 51364, N'La devolución tiene notas de crédito o bajas vigentes: anúlelas primero (DEVOLUCION_CON_NOTA).', 1;
END
