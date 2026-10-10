CREATE OR ALTER TRIGGER doc.TR_Documento_Ola4 ON doc.Documento AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(Estado) RETURN;
    -- Salida temprana sin variable de tabla: el POS y los demás tipos de las olas 1 a 3 no pagan este disparador
    IF NOT EXISTS (SELECT 1 FROM inserted i JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC') RETURN;
    -- Sin variable de tabla (C-1, 8.2): cada consulta lee el conjunto derivado de los documentos de la ola que cambian de estado
    IF NOT EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.Familia, t.SoloCentral, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND (t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC')) e) RETURN;
    IF SESSION_CONTEXT(N'gpos.incorporacion') IS NOT NULL RETURN;

    -- Dueño por sitio (ADR-53, cláusulas 2 y 4): compras, CxP y bancos solo en la central
    IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.Familia, t.SoloCentral, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND (t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC')) e WHERE SoloCentral = 1) AND EXISTS (SELECT 1 FROM sync.Nodo WHERE Local = 1 AND EsCentral = 0)
        THROW 51341, N'Esta operación solo se hace en la central (REQUIERE_CENTRAL, ADR-53).', 1;

    -- ---------------- Emisión
    IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.Familia, t.SoloCentral, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND (t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC')) e WHERE Emite = 1)
    BEGIN
        -- CA-10 en compras: totales = suma de las líneas (salvo saldo importado)
        IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.Familia, t.SoloCentral, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND (t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC')) e JOIN compras.Compra c ON c.DocumentoId = e.Id
                    OUTER APPLY (SELECT SUM(l.Importe + l.Descuento) AS Bruto, SUM(l.Descuento) AS Desc_, SUM(l.Impuesto) AS Itbis
                                   FROM compras.CompraLinea l WHERE l.DocumentoId = e.Id) l
                    WHERE e.Emite = 1 AND e.Origen <> 'I'
                      AND (c.SubTotal <> ISNULL(l.Bruto, 0) OR c.Descuento <> ISNULL(l.Desc_, 0) OR c.Impuesto <> ISNULL(l.Itbis, 0)))
            THROW 51342, N'Los totales de la compra no cuadran con sus líneas (CA-10).', 1;
        -- La factura y la nota de débito del suplidor crean exactamente su partida por pagar, por su total
        IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.Familia, t.SoloCentral, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND (t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC')) e JOIN compras.Compra c ON c.DocumentoId = e.Id
                    LEFT JOIN cxp.Cuenta p ON p.DocumentoId = e.Id
                    WHERE e.Emite = 1 AND e.Codigo IN ('FCP', 'NDP')
                      AND (p.DocumentoId IS NULL OR (e.Origen <> 'I' AND p.Monto <> c.Total) OR (e.Origen = 'I' AND p.Monto > c.Total) OR p.SuplidorId <> c.SuplidorId
                           OR p.MonedaId <> c.MonedaId OR p.SaldoPendiente <> p.Monto))
            THROW 51343, N'La factura de compra debe crear su cuenta por pagar por el total, con el mismo suplidor y moneda.', 1;
        -- Kárdex de la compra = sus líneas de artículo (cantidad en unidad base y costo en moneda base, 6 decimales). D-MVP-02 (Ola4OrdenRecibida, 51344
            -- nueva forma): la línea mueve lo no recibido (cantidad × factor − CantidadRecibida, con su signo) y sin movimiento si da 0; con
            -- CantidadRecibida > 0 la cantidad de origen va en NULL y con 0 es obligatoria e igual a la de la línea (S-3). Solo la FCP recibe. Por
            -- artículo, la clase 9 (línea 0, almacén de la compra) suma lo capitalizado de compras.FacturaRecepcion, que existe si y solo si hay lo
            -- recibido y cuadra F y R con las líneas
            IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.Familia, t.SoloCentral, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND (t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC')) e WHERE Emite = 1 AND Codigo IN ('FCP', 'DVS') AND Origen <> 'I')
            BEGIN
                -- C-10 (Ola4CompraVariableTabla): los documentos de la ola que cambian de estado se leen UNA vez y 51344 los lee de @e, en lugar de repetir
                -- nueve veces la tabla derivada en la sentencia (su compilación, con cada cambio de las estadísticas, era el costo de la FCP)
                DECLARE @e TABLE (Id bigint NOT NULL PRIMARY KEY, Codigo varchar(10) COLLATE DATABASE_DEFAULT NOT NULL, Familia char(3) COLLATE DATABASE_DEFAULT NOT NULL,
                                  SoloCentral bit NOT NULL, Origen char(1) COLLATE DATABASE_DEFAULT NOT NULL, Fecha date NOT NULL, Emite int NOT NULL, Anula int NOT NULL);
                INSERT @e (Id, Codigo, Familia, SoloCentral, Origen, Fecha, Emite, Anula)
                SELECT i.Id, t.Codigo, t.Familia, t.SoloCentral, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND (t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC');
            IF EXISTS (SELECT 1
                         FROM (SELECT l.DocumentoId, l.Linea, l.ArticuloId,
                                      (ROUND(l.Cantidad * l.FactorUnidad, 6) - l.CantidadRecibida) * CASE WHEN e.Codigo = 'DVS' THEN -1 ELSE 1 END AS Cant,
                                      l.CostoKardex, l.UnidadId, l.FactorUnidad, l.CantidadRecibida, l.Cantidad * CASE WHEN e.Codigo = 'DVS' THEN -1 ELSE 1 END AS CantOrigen,
                                      (SELECT au.Factor FROM cat.ArticuloUnidad au WHERE au.ArticuloId = l.ArticuloId AND au.UnidadId = l.UnidadId) AS FactorVigente
                                 FROM @e e JOIN compras.CompraLinea l ON l.DocumentoId = e.Id
                                WHERE e.Emite = 1 AND e.Codigo IN ('FCP', 'DVS') AND e.Origen <> 'I' AND l.EsServicio = 0
                                  AND ROUND(l.Cantidad * l.FactorUnidad, 6) <> l.CantidadRecibida) l
                         FULL JOIN (SELECT m.DocumentoId, m.Linea, m.ArticuloId, m.Cantidad, m.CostoUnitario, m.UnidadId, m.FactorUnidad AS FactorM, m.CantidadOrigen
                                      FROM @e e JOIN inv.Movimiento m ON m.DocumentoId = e.Id
                                     WHERE e.Emite = 1 AND e.Codigo IN ('FCP', 'DVS') AND e.Origen <> 'I' AND m.MovimientoRevertidoId IS NULL AND m.Clase <> 9) m
                                ON m.DocumentoId = l.DocumentoId AND m.Linea = l.Linea
                        WHERE l.DocumentoId IS NULL OR m.DocumentoId IS NULL OR m.ArticuloId <> l.ArticuloId OR m.Cantidad <> l.Cant
                           OR (l.CostoKardex IS NULL OR m.CostoUnitario <> l.CostoKardex) OR m.UnidadId IS NULL OR m.UnidadId <> l.UnidadId OR m.FactorM <> l.FactorUnidad
                           OR (l.CantidadRecibida = 0 AND (m.CantidadOrigen IS NULL OR m.CantidadOrigen <> l.CantOrigen))
                           OR (l.CantidadRecibida > 0 AND m.CantidadOrigen IS NOT NULL)
                           OR l.FactorVigente IS NULL OR l.FactorUnidad <> l.FactorVigente)
               OR EXISTS (SELECT 1 FROM @e e JOIN compras.CompraLinea l ON l.DocumentoId = e.Id
                           WHERE e.Emite = 1 AND e.Codigo <> 'FCP' AND e.Origen <> 'I' AND l.CantidadRecibida <> 0)
               OR EXISTS (SELECT 1 FROM @e e JOIN inv.Movimiento m ON m.DocumentoId = e.Id
                            LEFT JOIN compras.Compra c ON c.DocumentoId = e.Id
                           WHERE e.Emite = 1 AND e.Origen <> 'I' AND m.Clase = 9 AND m.MovimientoRevertidoId IS NULL
                             AND (e.Codigo <> 'FCP' OR c.AlmacenId IS NULL OR m.AlmacenId <> c.AlmacenId
                                  OR NOT EXISTS (SELECT 1 FROM compras.FacturaRecepcion r WHERE r.DocumentoId = e.Id AND r.ArticuloId = m.ArticuloId)))
               OR EXISTS (SELECT 1
                            FROM (SELECT e.Id, l.ArticuloId, SUM(ROUND(l.Cantidad * l.FactorUnidad, 6)) AS F, SUM(l.CantidadRecibida) AS R
                                    FROM @e e JOIN compras.CompraLinea l ON l.DocumentoId = e.Id
                                   WHERE e.Emite = 1 AND e.Codigo = 'FCP' AND e.Origen <> 'I' AND l.EsServicio = 0
                                   GROUP BY e.Id, l.ArticuloId) a
                            FULL JOIN (SELECT r.DocumentoId, r.ArticuloId, r.CantidadFacturada, r.CantidadRecibida, r.Capitalizado
                                         FROM @e e JOIN compras.FacturaRecepcion r ON r.DocumentoId = e.Id
                                        WHERE e.Emite = 1 AND e.Codigo = 'FCP' AND e.Origen <> 'I') r
                                   ON r.DocumentoId = a.Id AND r.ArticuloId = a.ArticuloId
                            OUTER APPLY (SELECT SUM(m.Valor) AS Valor FROM inv.Movimiento m
                                          WHERE m.DocumentoId = ISNULL(a.Id, r.DocumentoId) AND m.ArticuloId = ISNULL(a.ArticuloId, r.ArticuloId)
                                            AND m.Clase = 9 AND m.MovimientoRevertidoId IS NULL) v
                           WHERE a.Id IS NULL OR (a.R > 0 AND (r.DocumentoId IS NULL OR r.CantidadFacturada <> a.F OR r.CantidadRecibida <> a.R))
                              OR (a.R = 0 AND r.DocumentoId IS NOT NULL) OR ISNULL(v.Valor, 0) <> ISNULL(r.Capitalizado, 0))
               -- S-01 (auditoría del 2026-10-10): la factura que cita una orden es del suplidor y de la moneda de la orden
               OR EXISTS (SELECT 1 FROM @e e JOIN compras.Compra c ON c.DocumentoId = e.Id JOIN compras.Compra o ON o.DocumentoId = c.DocumentoOrigenId
                           WHERE e.Emite = 1 AND e.Codigo = 'FCP' AND e.Origen <> 'I' AND (o.SuplidorId <> c.SuplidorId OR o.MonedaId <> c.MonedaId))
               -- S-05: lo recibido de cada artículo (Σ CantidadRecibida) es lo que movieron las entradas vigentes ligadas a la orden
               OR EXISTS (SELECT 1
                            FROM (SELECT e.Id, l.ArticuloId, SUM(l.CantidadRecibida) AS R
                                    FROM @e e JOIN compras.Compra c ON c.DocumentoId = e.Id AND c.DocumentoOrigenId IS NOT NULL
                                    JOIN compras.CompraLinea l ON l.DocumentoId = e.Id
                                   WHERE e.Emite = 1 AND e.Codigo = 'FCP' AND e.Origen <> 'I' AND l.EsServicio = 0
                                   GROUP BY e.Id, l.ArticuloId) a
                            FULL JOIN (SELECT e.Id, m.ArticuloId, SUM(m.Cantidad) AS R
                                         FROM @e e JOIN compras.Compra c ON c.DocumentoId = e.Id
                                         JOIN inv.DocInventario x ON x.OrdenCompraId = c.DocumentoOrigenId
                                         JOIN doc.Documento d ON d.Id = x.DocumentoId AND d.Estado = 1
                                         JOIN inv.Movimiento m ON m.DocumentoId = x.DocumentoId AND m.MovimientoRevertidoId IS NULL
                                        WHERE e.Emite = 1 AND e.Codigo = 'FCP' AND e.Origen <> 'I'
                                        GROUP BY e.Id, m.ArticuloId) b
                                   ON b.Id = a.Id AND b.ArticuloId = a.ArticuloId
                           WHERE ISNULL(a.R, 0) <> ISNULL(b.R, 0))
                THROW 51344, N'El kárdex de la compra no coincide con sus líneas (cantidad en unidad base menos lo ya recibido y costo en moneda base) o con el ajuste de valor de lo recibido (D-MVP-02).', 1;
            END
        -- 606: comprobante recibido o emitido, o la opción explícita «Sin comprobante fiscal» con su autorización (PO-04)
        IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.Familia, t.SoloCentral, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND (t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC')) e JOIN compras.Compra c ON c.DocumentoId = e.Id
                    LEFT JOIN fiscal.Registro606 r ON r.DocumentoId = e.Id
                    WHERE e.Emite = 1 AND e.Codigo = 'FCP' AND e.Origen <> 'I'
                      AND (   (c.SinComprobante = 1 AND (r.DocumentoId IS NOT NULL OR EXISTS (SELECT 1 FROM fiscal.Comprobante x WHERE x.DocumentoId = e.Id)
                                                         OR NOT EXISTS (SELECT 1 FROM doc.Autorizacion z WHERE z.DocumentoId = e.Id AND z.Tipo = 'SIN_NCF')))
                           OR (c.SinComprobante = 0 AND r.DocumentoId IS NULL)))
            THROW 51345, N'La compra lleva sus datos del 606 o la opción explícita «Sin comprobante fiscal» autorizada.', 1;
        -- NCF recibido y emitido son excluyentes; tipo del NCF recibido según el documento (R4-17)
        IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.Familia, t.SoloCentral, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND (t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC')) e JOIN fiscal.Registro606 r ON r.DocumentoId = e.Id
                    WHERE e.Emite = 1
                      AND (   (r.Ncf IS NOT NULL AND EXISTS (SELECT 1 FROM fiscal.Comprobante x WHERE x.DocumentoId = e.Id))
                           OR (r.Ncf IS NULL AND NOT EXISTS (SELECT 1 FROM fiscal.Comprobante x WHERE x.DocumentoId = e.Id AND x.Rol = 'O'))
                           OR (r.Ncf IS NOT NULL AND e.Codigo IN ('FCP', 'CC', 'DBA') AND SUBSTRING(r.Ncf, 2, 2) NOT IN ('01', '02', '14', '15', '31', '32', '44', '45'))
                           OR (r.Ncf IS NOT NULL AND e.Codigo = 'NCP' AND SUBSTRING(r.Ncf, 2, 2) NOT IN ('04', '34'))
                           OR (r.Ncf IS NOT NULL AND e.Codigo = 'NDP' AND SUBSTRING(r.Ncf, 2, 2) NOT IN ('03', '33'))
                           OR (e.Codigo IN ('NCP', 'NDP') AND r.NcfModificado IS NULL)))
            THROW 51346, N'NCF del 606 inválido: recibido o emitido (no ambos), del tipo que admite el documento, y la nota del suplidor con su NCF modificado.', 1;
        -- La clase del documento bancario es la de su tipo; la cuenta está habilitada
        IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.Familia, t.SoloCentral, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND (t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC')) e JOIN banco.DocBanco b ON b.DocumentoId = e.Id JOIN banco.CuentaBancaria cb ON cb.Id = b.CuentaBancariaId
                    WHERE e.Emite = 1 AND (b.Clase <> e.Codigo OR cb.Inhabilitado = 1 OR (b.Clase = 'SIN' AND e.Origen <> 'I')))
            THROW 51349, N'Documento bancario incoherente con su tipo, saldo inicial fuera de la implantación o cuenta inhabilitada (R4-52, R4-59).', 1;
        IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.Familia, t.SoloCentral, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND (t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC')) e WHERE e.Emite = 1 AND e.Familia = 'BAN' AND e.Codigo NOT IN ('SPG')
                      AND NOT EXISTS (SELECT 1 FROM banco.DocBanco b WHERE b.DocumentoId = e.Id))
            THROW 51349, N'Documento bancario sin su extensión.', 1;
        -- Pago: monto = aplicado (en la moneda del pago) + directo; aplicaciones del mismo suplidor; en la misma moneda, tasa 1
        IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.Familia, t.SoloCentral, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND (t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC')) e JOIN banco.DocBanco b ON b.DocumentoId = e.Id
                    OUTER APPLY (SELECT SUM(a.MontoAplica) AS Aplicado FROM cxp.Aplicacion a WHERE a.DocumentoAplicaId = e.Id AND a.Anulada = 0) a
                    WHERE e.Emite = 1 AND b.Clase IN ('CHK', 'TRB')
                      AND (   ISNULL(a.Aplicado, 0) + b.MontoDirecto <> b.Monto
                           OR EXISTS (SELECT 1 FROM cxp.Aplicacion x JOIN cxp.Cuenta p ON p.DocumentoId = x.DocumentoAfectadoId
                                       WHERE x.DocumentoAplicaId = e.Id AND x.Anulada = 0
                                         AND (p.SuplidorId <> ISNULL(b.SuplidorId, -1) OR (p.MonedaId = b.MonedaId AND (x.Tasa <> 1 OR x.MontoAplica <> x.Monto))))))
            THROW 51347, N'El pago no cuadra: aplicado + directo = monto, facturas del mismo suplidor y, en la misma moneda, sin conversión (R4-42).', 1;
        -- Anticipo (PO-09): el directo de un pago a un suplidor queda como saldo a favor por ese monto; sin suplidor, ninguno
        IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.Familia, t.SoloCentral, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND (t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC')) e JOIN banco.DocBanco b ON b.DocumentoId = e.Id LEFT JOIN cxp.Credito c ON c.DocumentoId = e.Id
                    WHERE e.Emite = 1 AND b.Clase IN ('CHK', 'TRB')
                      AND (   (b.SuplidorId IS NOT NULL AND b.MontoDirecto > 0 AND (c.DocumentoId IS NULL OR c.Monto <> b.MontoDirecto OR c.SuplidorId <> b.SuplidorId
                                                                                   OR c.MonedaId <> b.MonedaId OR c.SaldoDisponible <> c.Monto))
                           OR ((b.SuplidorId IS NULL OR b.MontoDirecto = 0) AND c.DocumentoId IS NOT NULL)))
            THROW 51348, N'El anticipo del pago al suplidor no coincide con su saldo a favor (PO-09).', 1;
        -- Aplicación de saldo a favor: lo aplicado = lo compensado; sin efectivo
        IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.Familia, t.SoloCentral, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND (t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC')) e
                    OUTER APPLY (SELECT SUM(a.MontoAplica + ROUND((a.RetencionItbis + a.RetencionIsr) * a.Tasa, 2)) AS Aplicado FROM cxp.Aplicacion a WHERE a.DocumentoAplicaId = e.Id AND a.Anulada = 0) a
                    OUTER APPLY (SELECT SUM(x.Monto) AS Compensado, MIN(k.MonedaId) AS Moneda, MAX(k.MonedaId) AS MonedaMax FROM cxp.Compensacion x JOIN cxp.Credito k ON k.DocumentoId = x.CreditoDocumentoId WHERE x.DocumentoId = e.Id) c
                    WHERE e.Emite = 1 AND e.Codigo = 'APS' AND NOT EXISTS (SELECT 1 FROM cxp.Regularizacion g WHERE g.DocumentoId = e.Id) AND (ISNULL(a.Aplicado, 0) <> ISNULL(c.Compensado, 0) OR ISNULL(c.Compensado, 0) = 0 OR c.Moneda <> c.MonedaMax
                                   OR EXISTS (SELECT 1 FROM cxp.Aplicacion y JOIN cxp.Cuenta p ON p.DocumentoId = y.DocumentoAfectadoId
                                               WHERE y.DocumentoAplicaId = e.Id AND y.Anulada = 0
                                                 AND ((p.MonedaId = c.Moneda AND (y.Tasa <> 1 OR y.MontoAplica <> y.Monto))
                                                      OR (p.MonedaId <> c.Moneda AND y.MontoAplica <> ROUND(y.Monto * y.Tasa, 2))))))
            THROW 51352, N'La aplicación de saldo a favor no cuadra: aplicado = compensado, en la moneda de los saldos y con la tasa de cada factura (R4-42).', 1;
        -- Solicitud de pago: monto = facturas sugeridas + directo
        IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.Familia, t.SoloCentral, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND (t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC')) e JOIN banco.SolicitudPago s ON s.DocumentoId = e.Id
                    OUTER APPLY (SELECT SUM(x.Monto) AS Sugerido FROM banco.SolicitudPagoDocumento x WHERE x.DocumentoId = e.Id) x
                    WHERE e.Emite = 1 AND (ISNULL(x.Sugerido, 0) + s.MontoDirecto <> s.Monto OR s.PagoDocumentoId IS NOT NULL))
            THROW 51353, N'La solicitud de pago no cuadra: facturas + directo = monto.', 1;
        -- Caja chica y depósito desde caja: jornada abierta y salida de la gaveta por el monto (CA-24)
        IF EXISTS (SELECT 1
                     FROM (SELECT e.Id, c.JornadaId, c.Monto, c.MonedaId FROM (SELECT i.Id, t.Codigo, t.Familia, t.SoloCentral, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND (t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC')) e JOIN caja.CajaChica c ON c.DocumentoId = e.Id WHERE e.Emite = 1
                           UNION ALL
                           SELECT e.Id, b.JornadaId, b.Monto, b.MonedaId FROM (SELECT i.Id, t.Codigo, t.Familia, t.SoloCentral, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND (t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC')) e JOIN banco.DocBanco b ON b.DocumentoId = e.Id WHERE e.Emite = 1 AND b.JornadaId IS NOT NULL) x
                     JOIN caja.Jornada j ON j.Id = x.JornadaId
                     OUTER APPLY (SELECT SUM(m.Monto) AS Salida FROM caja.Movimiento m WHERE m.DocumentoId = x.Id) m
                    WHERE j.Estado <> 'A' OR ISNULL(m.Salida, 0) <> -x.Monto
                       OR EXISTS (SELECT 1 FROM caja.Movimiento m2 WHERE m2.DocumentoId = x.Id AND (m2.MonedaId <> x.MonedaId OR m2.JornadaId <> x.JornadaId)))
            THROW 51351, N'El gasto o depósito de caja exige la jornada abierta y su salida de la gaveta por el monto, en su moneda (CA-24).', 1;
        -- Invariantes de saldo de las partidas y saldos a favor tocados por el documento
        IF EXISTS (SELECT 1 FROM cxp.Cuenta p
                    WHERE p.DocumentoId IN (SELECT a.DocumentoAfectadoId FROM (SELECT i.Id, t.Codigo, t.Familia, t.SoloCentral, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND (t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC')) e JOIN cxp.Aplicacion a ON a.DocumentoAplicaId = e.Id WHERE e.Emite = 1)
                      AND p.SaldoPendiente <> p.Monto - ISNULL((SELECT SUM(a.Monto + a.RetencionItbis + a.RetencionIsr) FROM cxp.Aplicacion a
                                                                 JOIN doc.Documento x ON x.Id = a.DocumentoAplicaId AND x.Estado = 1
                                                                WHERE a.DocumentoAfectadoId = p.DocumentoId AND a.Anulada = 0), 0))
            THROW 51355, N'El saldo de la cuenta por pagar no cuadra con sus aplicaciones (R4-44).', 1;
        IF EXISTS (SELECT 1 FROM cxp.Credito c
                    WHERE c.DocumentoId IN (SELECT x.CreditoDocumentoId FROM (SELECT i.Id, t.Codigo, t.Familia, t.SoloCentral, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND (t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC')) e JOIN cxp.Compensacion x ON x.DocumentoId = e.Id WHERE e.Emite = 1)
                      AND c.SaldoDisponible <> c.Monto - ISNULL((SELECT SUM(x.Monto) FROM cxp.Compensacion x JOIN doc.Documento d ON d.Id = x.DocumentoId AND d.Estado = 1
                                                                 WHERE x.CreditoDocumentoId = c.DocumentoId), 0))
            THROW 51355, N'El saldo a favor del suplidor no cuadra con sus compensaciones (R4-45).', 1;
    END

    -- ---------------- Anulación
    IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.Familia, t.SoloCentral, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND (t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC')) e WHERE Anula = 1)
    BEGIN
        -- Una solicitud u orden convertida o facturada no se anula (R4-02)
        IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.Familia, t.SoloCentral, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND (t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC')) e JOIN compras.Compra c ON c.DocumentoId = e.Id WHERE e.Anula = 1 AND c.Situacion IN ('CONVERTIDA', 'FACTURADA'))
            THROW 51358, N'La solicitud u orden ya fue convertida o facturada: anule primero el documento que la usó (R4-02).', 1;
                IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.Familia, t.SoloCentral, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND (t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC')) e JOIN inv.DocInventario x ON x.OrdenCompraId = e.Id JOIN doc.Documento d ON d.Id = x.DocumentoId AND d.Estado = 1
                            WHERE e.Anula = 1 AND e.Codigo = 'ORD')
                    THROW 51407, N'La orden de compra tiene entradas de almacén vigentes: anule primero las entradas (ORDEN_CON_ENTRADAS).', 1;
        IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.Familia, t.SoloCentral, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND (t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC')) e JOIN cxp.Aplicacion a ON a.DocumentoAplicaId = e.Id WHERE e.Anula = 1 AND a.Anulada = 0)
            THROW 51315, N'La anulación debe dejar sin efecto las aplicaciones del documento (CA-03).', 1;
        IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.Familia, t.SoloCentral, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND (t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC')) e JOIN cxp.Cuenta p ON p.DocumentoId = e.Id
                    WHERE e.Anula = 1 AND (p.SaldoPendiente <> 0 OR EXISTS (SELECT 1 FROM cxp.Aplicacion a JOIN doc.Documento x ON x.Id = a.DocumentoAplicaId AND x.Estado = 1
                                                                            WHERE a.DocumentoAfectadoId = p.DocumentoId AND a.Anulada = 0)))
            THROW 51316, N'No se anula una compra con pagos, retenciones o notas aplicadas: anúlelos primero (R4-47).', 1;
        IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.Familia, t.SoloCentral, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND (t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC')) e JOIN cxp.Credito c ON c.DocumentoId = e.Id
                    WHERE e.Anula = 1 AND (c.SaldoDisponible <> 0 OR EXISTS (SELECT 1 FROM cxp.Compensacion x JOIN doc.Documento d ON d.Id = x.DocumentoId AND d.Estado = 1
                                                                             WHERE x.CreditoDocumentoId = c.DocumentoId)))
            THROW 51316, N'El saldo a favor del suplidor está en uso: anule primero las aplicaciones que lo consumieron (MD-17).', 1;
        IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.Familia, t.SoloCentral, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND (t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC')) e JOIN fiscal.Registro606 r ON r.DocumentoId = e.Id WHERE e.Anula = 1 AND r.Anulado = 0)
            THROW 51356, N'Al anular el documento, sus datos del 606 quedan marcados como anulados.', 1;
        IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.Familia, t.SoloCentral, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND (t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC')) e JOIN banco.SolicitudPago s ON s.DocumentoId = e.Id WHERE e.Anula = 1 AND s.PagoDocumentoId IS NOT NULL)
           OR EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.Familia, t.SoloCentral, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND (t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC')) e JOIN banco.SolicitudPago s ON s.PagoDocumentoId = e.Id WHERE e.Anula = 1)
            THROW 51357, N'Una solicitud pagada no se anula; al anular el pago, la solicitud se libera (R4-48, R4-54).', 1;
        -- PO-11 (A) / MD-17: la caja chica y el depósito desde caja solo se anulan con su jornada abierta
        IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.Familia, t.SoloCentral, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND (t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC')) e JOIN caja.CajaChica c ON c.DocumentoId = e.Id JOIN caja.Jornada j ON j.Id = c.JornadaId WHERE e.Anula = 1 AND j.Estado <> 'A')
           OR EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.Familia, t.SoloCentral, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND (t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC')) e JOIN banco.DocBanco b ON b.DocumentoId = e.Id JOIN caja.Jornada j ON j.Id = b.JornadaId WHERE e.Anula = 1 AND j.Estado <> 'A')
            THROW 51317, N'Solo se anula con la jornada abierta (MD-17).', 1;
        -- El saldo inicial bancario no se anula (R4-52): se corrige con una nota de débito o de crédito bancaria
        IF EXISTS (SELECT 1 FROM (SELECT i.Id, t.Codigo, t.Familia, t.SoloCentral, i.Origen, i.Fecha, CASE WHEN d.Estado = 0 AND i.Estado = 1 THEN 1 ELSE 0 END AS Emite, CASE WHEN i.Estado = 2 AND d.Estado <> 2 THEN 1 ELSE 0 END AS Anula FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId WHERE i.Estado <> d.Estado AND (t.Familia IN ('COM', 'CXP', 'BAN') OR t.Codigo = 'CC')) e WHERE e.Anula = 1 AND e.Codigo = 'SIN')
            THROW 51354, N'El saldo inicial bancario no se anula: corríjalo con una nota de débito o de crédito bancaria (R4-52).', 1;
    END
END
