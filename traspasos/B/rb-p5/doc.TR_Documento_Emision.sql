CREATE OR ALTER TRIGGER doc.TR_Documento_Emision ON doc.Documento AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    -- Salida temprana: sin Estado en el SET no hay transición 0 -> 1
    IF NOT UPDATE(Estado) RETURN;

    DECLARE @id bigint = -1, @codigo varchar(10), @llevaNcf bit, @ncfOpcional bit, @suc smallint, @fecha date, @nodo smallint, @motivo char(1), @origen char(1),
            @hayVenta bit, @subTotal decimal(19, 2), @descuento decimal(19, 2), @impuesto decimal(19, 2), @total decimal(19, 2),
            @jornadaId bigint, @jornadaEstado char(1), @bruto decimal(38, 2), @descL decimal(38, 2), @itbisL decimal(38, 2), @otros decimal(38, 2),
            @sinLote bit, @conLote bit, @pagos decimal(38, 2), @cuenta decimal(38, 2), @favor decimal(38, 2), @aplicado decimal(38, 2),
            @conComprobante bit, @conComprobanteO bit;

    -- Un documento a la vez: la emisión es de una fila; si un UPDATE emite varias, se recorren en orden de llave con las mismas reglas
    WHILE 1 = 1
    BEGIN
        SELECT TOP (1) @id = i.Id, @codigo = t.Codigo, @llevaNcf = t.LlevaNcf, @ncfOpcional = t.NcfOpcional, @suc = i.SucursalId, @fecha = i.Fecha, @nodo = i.NodoOrigenId,
                       @motivo = i.MotivoSinNcf, @origen = i.Origen
          FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId
         WHERE d.Estado = 0 AND i.Estado = 1 AND i.Id > @id
         ORDER BY i.Id;
        IF @@ROWCOUNT = 0 RETURN;

        -- MD-59: un sitio restaurado no emite hasta reconciliar (falla cerrada sin permiso para leer el fork)
        IF EXISTS (SELECT 1 FROM sync.EstadoNodo s LEFT JOIN sys.database_recovery_status r ON r.database_id = DB_ID()
                    WHERE s.NodoLocalId = @nodo
                      AND (s.EmisionBloqueada = 1 OR r.recovery_fork_guid IS NULL OR r.recovery_fork_guid <> s.ForkRegistrado)
                      AND NOT EXISTS (SELECT 1 FROM sync.Reconciliacion x WHERE x.Id = s.ReconciliacionId AND x.Estado = 'R'
                                         AND x.Id = TRY_CONVERT(int, SESSION_CONTEXT(N'gpos.reaplicacion'))))
            THROW 51330, N'Emisión bloqueada: la base fue restaurada o el nodo está en reconciliación (MD-59).', 1;

        -- Lectura unificada de la venta: extensión, jornada, sumas de las líneas, otros impuestos y pagos (una sentencia, búsquedas por llave)
        SELECT @hayVenta = 0, @bruto = NULL, @descL = NULL, @itbisL = NULL, @sinLote = NULL, @conLote = NULL, @otros = NULL, @pagos = NULL,
               @cuenta = NULL, @favor = NULL, @aplicado = NULL, @jornadaId = NULL, @jornadaEstado = NULL;
        SELECT @hayVenta = 1, @subTotal = v.SubTotal, @descuento = v.Descuento, @impuesto = v.Impuesto, @total = v.Total,
               @jornadaId = v.JornadaId, @jornadaEstado = j.Estado,
               @bruto = l.Bruto, @descL = l.Desc_, @itbisL = l.Itbis, @sinLote = l.SinLote, @conLote = l.ConLote, @otros = o.Otros,
               @pagos = p.Pagos, @cuenta = c.Cuenta, @favor = f.Favor, @aplicado = a.Aplicado
          FROM ventas.Venta v
          LEFT JOIN caja.Jornada j ON j.Id = v.JornadaId
          OUTER APPLY (SELECT SUM(vl.Importe + vl.Descuento) AS Bruto, SUM(vl.Descuento) AS Desc_, SUM(vl.Impuesto) AS Itbis,
                              MAX(CASE WHEN a.ControlLote = 1 AND vl.LoteId IS NULL THEN 1 ELSE 0 END) AS SinLote,
                              MAX(CASE WHEN vl.LoteId IS NOT NULL THEN 1 ELSE 0 END) AS ConLote
                         FROM ventas.VentaLinea vl JOIN cat.Articulo a ON a.Id = vl.ArticuloId WHERE vl.DocumentoId = @id) l
          OUTER APPLY (SELECT SUM(x.Monto) AS Otros FROM ventas.VentaLineaImpuesto x WHERE x.DocumentoId = @id) o
          OUTER APPLY (SELECT SUM(x.Monto) AS Pagos FROM ventas.VentaPago x WHERE x.DocumentoId = @id) p
          OUTER APPLY (SELECT SUM(x.Monto) AS Cuenta FROM cxc.Cuenta x WHERE x.DocumentoId = @id) c
          OUTER APPLY (SELECT SUM(x.Monto) AS Favor FROM cxc.Credito x WHERE x.DocumentoId = @id) f
          OUTER APPLY (SELECT SUM(x.Monto) AS Aplicado FROM cxc.Aplicacion x WHERE x.DocumentoAplicaId = @id AND x.Anulada = 0) a
         WHERE v.DocumentoId = @id;

        IF @hayVenta = 1
        BEGIN
            -- CA-10: totales = suma de las líneas, en los tipos con líneas
            IF @codigo IN ('FAC', 'FPOS', 'DEV', 'COT', 'PED')
               AND (@subTotal <> ISNULL(@bruto, 0) OR @descuento <> ISNULL(@descL, 0) OR @impuesto <> ISNULL(@itbisL, 0) + ISNULL(@otros, 0))
                THROW 51303, N'Los totales del documento no cuadran con sus líneas (CA-10).', 1;
        END
        -- CA-12: resumen por impuesto = suma de las líneas por impuesto, en los tipos con líneas (sin GROUP BY: agregados escalares por impuesto)
        IF @codigo IN ('FAC', 'FPOS', 'DEV')
        BEGIN
            IF EXISTS (SELECT 1
                         FROM ventas.VentaImpuesto vi
                         OUTER APPLY (SELECT COUNT(*) AS N, SUM(l.Importe) AS Base, SUM(l.Impuesto) AS Monto
                                        FROM ventas.VentaLinea l WHERE l.DocumentoId = @id AND l.ImpuestoId = vi.ImpuestoId) l
                         OUTER APPLY (SELECT COUNT(*) AS N, SUM(x.Base) AS Base, SUM(x.Monto) AS Monto
                                        FROM ventas.VentaLineaImpuesto x WHERE x.DocumentoId = @id AND x.ImpuestoId = vi.ImpuestoId) o
                        WHERE vi.DocumentoId = @id
                          AND (   (l.N = 0 AND o.N = 0)
                               OR (l.N > 0 AND (l.Base <> vi.Base OR l.Monto <> vi.Monto))
                               OR (o.N > 0 AND (o.Base <> vi.Base OR o.Monto <> vi.Monto))))
               OR EXISTS (SELECT 1 FROM ventas.VentaLinea l
                           WHERE l.DocumentoId = @id
                             AND NOT EXISTS (SELECT 1 FROM ventas.VentaImpuesto vi WHERE vi.DocumentoId = @id AND vi.ImpuestoId = l.ImpuestoId))
               OR EXISTS (SELECT 1 FROM ventas.VentaLineaImpuesto x
                           WHERE x.DocumentoId = @id
                             AND NOT EXISTS (SELECT 1 FROM ventas.VentaImpuesto vi WHERE vi.DocumentoId = @id AND vi.ImpuestoId = x.ImpuestoId))
                THROW 51304, N'El resumen por impuesto no cuadra con las líneas (CA-12).', 1;
        END
        IF @hayVenta = 1
        BEGIN
            -- CA-11: pagos (menos el cambio) + parte a crédito = total; en la nota de crédito y la devolución, reembolsos + saldo a favor + aplicaciones (CA-46: un documento importado en la implantación trae solo su saldo)
            IF @origen <> 'I'
               AND (   (@codigo IN ('FAC', 'FPOS', 'ND', 'CHD') AND ISNULL(@pagos, 0) + ISNULL(@cuenta, 0) <> @total)
                    OR (@codigo IN ('NC', 'DEV') AND -ISNULL(@pagos, 0) + ISNULL(@favor, 0) + ISNULL(@aplicado, 0) <> @total))
                THROW 51305, N'Los pagos no cuadran con el total del documento (CA-11).', 1;
            -- CA-24 / MD-17: la factura POS pertenece a una jornada abierta de su caja
            IF (@codigo = 'FPOS' AND @jornadaId IS NULL AND @origen <> 'I') OR (@jornadaId IS NOT NULL AND @jornadaEstado <> 'A')
                THROW 51306, N'La venta en caja exige una jornada abierta (CA-24).', 1;
        END
        IF EXISTS (SELECT 1 FROM cxc.Recibo r JOIN caja.Jornada j ON j.Id = r.JornadaId WHERE r.DocumentoId = @id AND j.Estado <> 'A')
            THROW 51306, N'El cobro en caja exige una jornada abierta (CA-24).', 1;
        -- CA-21: lote obligatorio si el artículo lo controla; lote vencido bloqueado o con autorización
        IF @codigo IN ('FAC', 'FPOS', 'DEV') AND @sinLote = 1
            THROW 51307, N'El artículo exige lote (CA-21).', 1;
        IF @codigo IN ('FAC', 'FPOS') AND @conLote = 1
        BEGIN
            IF EXISTS (SELECT 1 FROM ventas.VentaLinea l JOIN inv.Lote lo ON lo.Id = l.LoteId CROSS JOIN conf.Parametros p
                        WHERE l.DocumentoId = @id AND lo.FechaVencimiento < @fecha
                          AND (p.LoteVencido = 'B' OR NOT EXISTS (SELECT 1 FROM doc.Autorizacion z
                                                                   WHERE z.DocumentoId = @id AND z.Linea = l.Linea AND z.Tipo = 'LOTE_VENCIDO')))
                THROW 51308, N'Lote vencido: no se vende o exige autorización según la configuración (CA-21).', 1;
        END
        -- CA-09 / CA-45: el kárdex del documento es de almacenes de su sucursal, salvo regla explícita o el ajuste de un almacén de una sucursal cerrada (S-1)
        IF EXISTS (SELECT 1 FROM inv.Movimiento m
                    WHERE m.DocumentoId = @id AND m.SucursalId <> @suc
                      AND NOT EXISTS (SELECT 1 FROM org.SucursalAlmacenPermitido p WHERE p.SucursalId = @suc AND p.AlmacenId = m.AlmacenId) AND NOT (@codigo = 'AJU' AND EXISTS (SELECT 1 FROM org.Sucursal s WHERE s.Id = m.SucursalId AND s.Inhabilitado = 1)))
            THROW 51309, N'El documento mueve un almacén de otra sucursal sin regla explícita (CA-09).', 1;
        -- R2 (2026-10-08): kárdex de la venta = sus líneas inventariables en unidad base (cantidad × factor, 6 decimales, con signo),
        -- con la unidad, el factor vigente y la cantidad de la línea, al costo por unidad base de la línea. UF-05: no se exige a la venta cuyo inventario ya lo movió su documento de origen (la factura de un conduce;
        -- en la entrega 3, la cuenta de mesa que descarga al enviar la ronda, ADR-113), salvo la devolución, que siempre reintegra.
        -- UF-05 (ratificación del 2026-10-09, H-5a y H-7): el origen movió el kárdex si está emitido y tiene movimientos vigentes (originales sin
        -- reverso); se calcula una vez por documento. La devolución no se exime nunca: siempre reintegra. En la entrega 3 lo sustituye Venta.InventarioPor
        DECLARE @origenMovio bit;
        SET @origenMovio = 0;
        IF @hayVenta = 1 AND @codigo IN ('FAC', 'FPOS')
           AND EXISTS (SELECT 1 FROM ventas.Venta v JOIN doc.Documento o ON o.Id = v.DocumentoOrigenId AND o.Estado = 1
                        WHERE v.DocumentoId = @id
                          AND EXISTS (SELECT 1 FROM inv.Movimiento mo WITH (FORCESEEK)
                                       WHERE mo.DocumentoId = o.Id AND mo.MovimientoRevertidoId IS NULL
                                         AND NOT EXISTS (SELECT 1 FROM inv.Movimiento r
                                                          WHERE r.MovimientoRevertidoId = mo.Id AND r.MovimientoRevertidoId IS NOT NULL)))
            SET @origenMovio = 1;
        -- Plan B (7) en la factura POS: comparación agregada, sin FULL JOIN (medición del 2026-10-08)
        IF @hayVenta = 1 AND @codigo = 'FPOS' AND @origen <> 'I'
        BEGIN
            DECLARE @kLineas int, @kCant decimal(38, 12), @kOrigen decimal(38, 12), @kValor decimal(38, 12), @kUnidad bigint, @kFactor decimal(38, 6),
                    @kVigente int, @kMovs int, @kCantM decimal(38, 12), @kOrigenM decimal(38, 12), @kValorM decimal(38, 12), @kUnidadM bigint,
                    @kFactorM decimal(38, 6), @kSinUnidad int, @kArt bigint, @kArtM bigint;
            SELECT @kLineas = COUNT(*), @kCant = SUM(CONVERT(decimal(18, 6), ROUND(l.Cantidad * l.FactorUnidad, 6))), @kOrigen = SUM(l.Cantidad),
                   @kValor = SUM(CONVERT(decimal(18, 6), ROUND(l.Cantidad * l.FactorUnidad, 6)) * l.CostoUnitario),
                   @kUnidad = SUM(CONVERT(bigint, l.Linea) * l.UnidadId), @kFactor = SUM(l.Linea * l.FactorUnidad), @kArt = SUM(CONVERT(bigint, l.Linea) * l.ArticuloId),
                   @kVigente = SUM(CASE WHEN au.Factor IS NULL OR au.Factor <> l.FactorUnidad THEN 1 ELSE 0 END)
              FROM ventas.Venta v
              JOIN ventas.VentaLinea l ON l.DocumentoId = v.DocumentoId
              JOIN cat.Articulo a ON a.Id = l.ArticuloId AND a.Inventariable = 1
              LEFT JOIN cat.ArticuloUnidad au WITH (FORCESEEK) ON au.ArticuloId = l.ArticuloId AND au.UnidadId = l.UnidadId
             WHERE v.DocumentoId = @id AND v.AlmacenId IS NOT NULL
               AND @origenMovio = 0;
            SELECT @kMovs = COUNT(*), @kCantM = -SUM(m.Cantidad), @kOrigenM = -SUM(m.CantidadOrigen), @kValorM = -SUM(m.Cantidad * m.CostoUnitario),
                   @kUnidadM = SUM(CONVERT(bigint, m.Linea) * m.UnidadId), @kFactorM = SUM(m.Linea * m.FactorUnidad), @kArtM = SUM(CONVERT(bigint, m.Linea) * m.ArticuloId),
                   @kSinUnidad = SUM(CASE WHEN m.UnidadId IS NULL OR m.FactorUnidad IS NULL OR m.CantidadOrigen IS NULL THEN 1 ELSE 0 END)
              FROM inv.Movimiento m WITH (FORCESEEK) WHERE m.DocumentoId = @id AND m.MovimientoRevertidoId IS NULL;
            IF @kLineas <> @kMovs OR ISNULL(@kCant, 0) <> ISNULL(@kCantM, 0) OR ISNULL(@kOrigen, 0) <> ISNULL(@kOrigenM, 0)
               OR ISNULL(@kValor, 0) <> ISNULL(@kValorM, 0) OR ISNULL(@kUnidad, 0) <> ISNULL(@kUnidadM, 0) OR ISNULL(@kFactor, 0) <> ISNULL(@kFactorM, 0)
               OR ISNULL(@kArt, 0) <> ISNULL(@kArtM, 0) OR ISNULL(@kVigente, 0) > 0 OR ISNULL(@kSinUnidad, 0) > 0
                THROW 51380, N'El kárdex de la venta no coincide con sus líneas: cantidad × factor en unidad base, unidad y factor vigentes y costo por unidad base (R2).', 1;
        END
        -- Factura y devolución: comparación por línea (cada línea con su movimiento igual en todo; ningún movimiento sin línea)
        IF @hayVenta = 1 AND @codigo IN ('FAC', 'DEV') AND @origen <> 'I'
        BEGIN
            IF EXISTS (SELECT 1
                         FROM ventas.Venta v
                         JOIN ventas.VentaLinea l ON l.DocumentoId = v.DocumentoId
                         JOIN cat.Articulo a ON a.Id = l.ArticuloId AND a.Inventariable = 1
                         LEFT JOIN cat.ArticuloUnidad au WITH (FORCESEEK) ON au.ArticuloId = l.ArticuloId AND au.UnidadId = l.UnidadId
                        WHERE v.DocumentoId = @id AND v.AlmacenId IS NOT NULL
                          AND @origenMovio = 0
                          AND (au.Factor IS NULL OR l.FactorUnidad <> au.Factor
                               OR NOT EXISTS (SELECT 1 FROM inv.Movimiento m WITH (FORCESEEK)
                                               WHERE m.DocumentoId = @id AND m.MovimientoRevertidoId IS NULL AND m.Linea = l.Linea
                                                 AND m.ArticuloId = l.ArticuloId AND m.CostoUnitario = l.CostoUnitario
                                                 AND m.Cantidad = ROUND(l.Cantidad * l.FactorUnidad, 6) * CASE WHEN @codigo = 'DEV' THEN 1 ELSE -1 END
                                                 AND m.UnidadId = l.UnidadId AND m.FactorUnidad = l.FactorUnidad
                                                 AND m.CantidadOrigen = l.Cantidad * CASE WHEN @codigo = 'DEV' THEN 1 ELSE -1 END)))
               OR EXISTS (SELECT 1 FROM inv.Movimiento m WITH (FORCESEEK)
                           WHERE m.DocumentoId = @id AND m.MovimientoRevertidoId IS NULL
                             AND NOT EXISTS (SELECT 1
                                               FROM ventas.Venta v
                                               JOIN ventas.VentaLinea l ON l.DocumentoId = v.DocumentoId AND l.Linea = m.Linea AND l.ArticuloId = m.ArticuloId
                                               JOIN cat.Articulo a ON a.Id = l.ArticuloId AND a.Inventariable = 1
                                              WHERE v.DocumentoId = @id AND v.AlmacenId IS NOT NULL
                                                AND @origenMovio = 0))
                THROW 51380, N'El kárdex de la venta no coincide con sus líneas: cantidad × factor en unidad base, unidad y factor vigentes y costo por unidad base (R2).', 1;
        END
        -- R2 y D-K1 (2026-10-08): kárdex de entrada, conduce y ajuste = sus líneas en unidad base (cantidad × factor × signo), costo de la línea ÷ factor;
        -- el ajuste lleva motivo en cada línea y su kárdex es de clase 5 con ese motivo
        IF @codigo IN ('ENT', 'CON', 'AJU')
        BEGIN
            IF @codigo = 'AJU' AND EXISTS (SELECT 1 FROM inv.DocInventarioLinea l WHERE l.DocumentoId = @id AND l.MotivoAjusteId IS NULL)
                THROW 51382, N'Cada línea del ajuste de inventario lleva su motivo de ajuste (D-K1).', 1;
            IF EXISTS (SELECT 1
                         FROM inv.DocInventarioLinea l WITH (FORCESEEK)
                         LEFT JOIN cat.ArticuloUnidad au WITH (FORCESEEK) ON au.ArticuloId = l.ArticuloId AND au.UnidadId = l.UnidadId
                        WHERE l.DocumentoId = @id
                          AND (au.Factor IS NULL OR l.FactorUnidad <> au.Factor
                               OR NOT EXISTS (SELECT 1 FROM inv.Movimiento m WITH (FORCESEEK)
                                               WHERE m.DocumentoId = @id AND m.MovimientoRevertidoId IS NULL AND m.Linea = l.Linea
                                                 AND m.ArticuloId = l.ArticuloId AND m.CostoUnitario = ROUND(l.CostoUnitario / l.FactorUnidad, 6)
                                                 AND m.Cantidad = ROUND(l.Cantidad * l.FactorUnidad, 6) * l.Signo
                                                 AND m.UnidadId = l.UnidadId AND m.FactorUnidad = l.FactorUnidad AND m.CantidadOrigen = l.Cantidad * l.Signo
                                                 AND m.Clase = CASE WHEN @codigo = 'AJU' THEN 5 ELSE 1 END
                                                 AND ISNULL(m.MotivoAjusteId, -1) = ISNULL(l.MotivoAjusteId, -1))))
               OR EXISTS (SELECT 1 FROM inv.Movimiento m WITH (FORCESEEK)
                           WHERE m.DocumentoId = @id AND m.MovimientoRevertidoId IS NULL
                             AND NOT EXISTS (SELECT 1 FROM inv.DocInventarioLinea l WHERE l.DocumentoId = @id AND l.Linea = m.Linea AND l.ArticuloId = m.ArticuloId))
                THROW 51381, N'El kárdex del documento de inventario no coincide con sus líneas: cantidad × factor × signo en unidad base, unidad y factor vigentes, costo de la línea ÷ factor y, en el ajuste, clase 5 con su motivo (R2, D-K1).', 1;
        END
-- D-MVP-02 (Ola4OrdenRecibida, I-1): la entrada ligada a una orden de compra (por identidad) exige la orden vigente y ABIERTA, del mismo suplidor,
        -- con cada artículo de la entrada y sin pasar de lo pedido por artículo en unidad base; ningún otro documento de inventario cita una orden
        IF @hayVenta = 0 AND EXISTS (SELECT 1 FROM inv.DocInventario x WHERE x.DocumentoId = @id AND x.OrdenCompraId IS NOT NULL)
        BEGIN
            DECLARE @ordenCompra bigint, @suplidorEntrada int;
            SELECT @ordenCompra = x.OrdenCompraId, @suplidorEntrada = x.SuplidorId FROM inv.DocInventario x WHERE x.DocumentoId = @id;
            IF @codigo <> 'ENT'
                THROW 51405, N'Solo una entrada de almacén recibe una orden de compra (ORDEN_NO_RECIBIBLE).', 1;
            IF NOT EXISTS (SELECT 1 FROM compras.Compra c JOIN doc.Documento o ON o.Id = c.DocumentoId JOIN doc.TipoDocumento t ON t.Id = o.TipoDocumentoId
                            WHERE c.DocumentoId = @ordenCompra AND t.Codigo = 'ORD' AND o.Estado = 0 AND c.Situacion = 'ABIERTA')
                THROW 51405, N'La orden de compra no está abierta: no admite entradas (ORDEN_NO_RECIBIBLE).', 1;
            IF NOT EXISTS (SELECT 1 FROM compras.Compra c WHERE c.DocumentoId = @ordenCompra AND c.SuplidorId = @suplidorEntrada)
                THROW 51405, N'La entrada es de otro suplidor que la orden de compra (ORDEN_SUPLIDOR_DISTINTO).', 1;
            IF EXISTS (SELECT 1 FROM inv.DocInventarioLinea l WHERE l.DocumentoId = @id
                          AND NOT EXISTS (SELECT 1 FROM compras.CompraLinea q WHERE q.DocumentoId = @ordenCompra AND q.ArticuloId = l.ArticuloId))
                THROW 51405, N'La entrada tiene un artículo que la orden de compra no tiene (ORDEN_ARTICULO_AJENO).', 1;
            IF EXISTS (SELECT 1
                         FROM (SELECT l.ArticuloId, SUM(ROUND(l.Cantidad * l.FactorUnidad, 6)) AS R
                                 FROM inv.DocInventario x
                                 JOIN doc.Documento d ON d.Id = x.DocumentoId AND d.Estado = 1
                                 JOIN inv.DocInventarioLinea l ON l.DocumentoId = x.DocumentoId
                                WHERE x.OrdenCompraId = @ordenCompra
                                  AND l.ArticuloId IN (SELECT y.ArticuloId FROM inv.DocInventarioLinea y WHERE y.DocumentoId = @id)
                                GROUP BY l.ArticuloId) r
                         OUTER APPLY (SELECT SUM(ROUND(q.Cantidad * q.FactorUnidad, 6)) AS Q FROM compras.CompraLinea q
                                       WHERE q.DocumentoId = @ordenCompra AND q.ArticuloId = r.ArticuloId) q
                        WHERE r.R > ISNULL(q.Q, 0))
                THROW 51405, N'La entrada pasa de lo pedido en la orden de compra (RECEPCION_EXCEDE_ORDEN).', 1;
        END
        -- CA-22: la aplicación del conteo mueve exactamente (contado - existencia del corte), por artículo y lote
        IF @codigo = 'CNT'
        BEGIN
            IF EXISTS (SELECT 1
                         FROM (SELECT cl.ArticuloId, cl.LoteId, SUM(cl.Diferencia) AS Dif
                                 FROM inv.ConteoLinea cl WHERE cl.DocumentoId = @id GROUP BY cl.ArticuloId, cl.LoteId) c
                         FULL JOIN (SELECT m.ArticuloId, m.LoteId, SUM(m.Cantidad) AS Mov
                                      FROM inv.Movimiento m WHERE m.DocumentoId = @id AND m.Clase = 7 GROUP BY m.ArticuloId, m.LoteId) m
                                ON m.ArticuloId = c.ArticuloId AND ISNULL(m.LoteId, -1) = ISNULL(c.LoteId, -1)
                        WHERE ISNULL(c.Dif, 0) <> ISNULL(m.Mov, 0))
                THROW 51311, N'El ajuste del conteo no coincide con (contado - existencia del corte) (CA-22).', 1;
        END
        IF EXISTS (SELECT 1 FROM inv.Conteo c WHERE c.DocumentoId = @id AND (c.CorteEn IS NULL OR c.CapturaCerradaEn IS NULL))
            THROW 51311, N'Un conteo se aplica después del corte y del cierre de la captura (CA-22).', 1;
        -- CA-23 / CA-35: comprobante solo en tipos con NCF; sin NCF, el motivo es explícito (N exige la autorización registrada)
        SELECT @conComprobante = CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END, @conComprobanteO = MAX(CASE WHEN c.Rol = 'O' THEN 1 ELSE 0 END)
          FROM fiscal.Comprobante c WHERE c.DocumentoId = @id;
        IF @llevaNcf = 0 AND @conComprobante = 1
            THROW 51320, N'Este tipo de documento no lleva comprobante fiscal (CA-23).', 1;
        IF @llevaNcf = 1
           AND (   (ISNULL(@conComprobanteO, 0) = 0 AND @motivo IS NULL AND @ncfOpcional = 0)
                OR (@conComprobanteO = 1 AND @motivo IS NOT NULL)
                OR (@motivo = 'N' AND NOT EXISTS (SELECT 1 FROM doc.Autorizacion z WHERE z.DocumentoId = @id AND z.Tipo = 'SIN_NCF')))
            THROW 51321, N'Documento sin NCF sin motivo explícito, o "No generar comprobante" sin autorización (CA-35).', 1;
    END
END
