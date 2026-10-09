# [Blueprint de Datos] Factor de unidad en el kárdex (R1, R2, R4, R5, R7, conteo, D-K1, D-K2) y equivalencias

- Fecha: 2026-10-08 · Autor: arquitecto-datos (equipo A) · Estado: **Pendiente de firma** del propietario
- Árbol leído (solo lectura): `GPOS-NG-numeracion`, rama `feature/modelo-ng`, HEAD `2078a08`. Esquema vigente tomado del guion generado `database/empresa/gpos-empresa-20261009012253_Ola4RetiroExigirVendedor.sql` (en adelante, «guion»).
- Entrega: **una migración EF** (`<marca>_Ola4FactorUnidad`) más `SqlMigracionesOla4FactorUnidad.cs` con el SQL de reglas (patrón `Parchear` y `LoteDe`, idempotente con `CREATE OR ALTER`).

---

## 0. Tabla de resumen

| # | Decisión | Objeto | DDL o regla | Error | Riesgo y costo |
|---|---|---|---|---|---|
| R1 | Columnas de auditoría del kárdex | `inv.Movimiento` | `UnidadId smallint NULL`, `FactorUnidad decimal(19,6) NULL` (*), `CantidadOrigen decimal(18,6) NULL` + `CK_Movimiento_Unidad` | CHECK | +20 B por fila; columnas que admiten NULL: cambio solo de metadatos |
| R4 | `Linea` de smallint a int | `inv.Movimiento.Linea`, `MovimientoNuevo.Linea`, `MovimientoDocumentoFila.Linea` | `ALTER COLUMN Linea int NOT NULL` | — | Ningún índice tiene `Linea` (verificado): no se borra ninguno. Reescribe la tabla (inferido) |
| R5 | Costo no negativo | `inv.Movimiento` | `CK_Movimiento_Costo CHECK (CostoUnitario >= 0)` | CHECK + previa 51394 | Falla clara si hay historia negativa |
| R2a | Kárdex de ventas = líneas | `doc.TR_Documento_Emision` (parche) | FAC, FPOS, DEV | **51380** | +1 sentencia por emisión (ver 7) |
| R2b | Kárdex de inventario = líneas | `doc.TR_Documento_Emision` (parche) | ENT, CON, AJU | **51381** | Igual |
| D-K1 | Ajuste con motivo y clase 5 | `doc.TR_Documento_Emision` (parche) | AJU: motivo en cada línea; kárdex clase 5 con ese motivo | **51382** | Necesita el campo de motivo en el contrato |
| R2c | Compras con auditoría | `doc.TR_Documento_Ola4` (parche de 51344) | FCP, DVS: unidad, factor y cantidad de la línea | 51344 (mismo) | Sin costo adicional apreciable |
| R7 | Factor inmutable con referencias | `cat.TR_ArticuloUnidad_Factor` (nuevo) | UPDATE de `Factor` con líneas que lo usan, o con nodos activos | **51383** | Solo en el mantenimiento (raro) |
| R7b | Unidad base con factor 1 | mismo disparador y `cat.TR_Articulo_UnidadBase` (nuevo) | — | **51384** | — |
| R7c | Unidad base inmutable con movimientos | `cat.TR_Articulo_UnidadBase` | — | **51385** | — |
| Conteo | Unidad por línea | `inv.ConteoLinea` | `UnidadId smallint NULL` + FK, `FactorUnidad decimal(19,6) NOT NULL DEFAULT 1`, `Diferencia` convertida a unidad base | **51386** (`TR_ConteoLinea_Corte`) | 51311 queda igual |
| Índice | Cubrir R2 sin búsquedas de clave | `IX_Movimiento_Documento` | INCLUDE + `Linea, CostoUnitario, UnidadId, FactorUnidad, CantidadOrigen` | — | +33 B por fila de índice |
| Previa | Historia compatible con R5 | — | `THROW 51394` si hay `CostoUnitario < 0` | **51394** | — |
| D-K2 | Lote en el conteo | — | **Ninguna DDL**: va a **T4** con ADR-119 (sección 6.4) | — | — |
| Equiv. | Mantenimiento de equivalencias | `cat.ArticuloUnidad` | Tanda posterior (sección 12) | 51387 a 51393 reservados | ≈19 sp (inferido) |

(*) **Ajuste de R1 propuesto:** `decimal(19,6)` en lugar de `decimal(18,6)` para `FactorUnidad`. Es el tipo de origen en `cat.ArticuloUnidad.Factor` y en el `FactorUnidad` de `VentaLinea`, `DocInventarioLinea` y `CompraLinea` (guion: 1757, 3391, 3707, 7049). Así la copia no estrecha el tipo. Ocupan lo mismo: 9 bytes con precisión de 10 a 19. Si el propietario mantiene `decimal(18,6)`, todo funciona igual con una conversión implícita.

Rango de errores: **51380 a 51394**, asignado por el coordinador. Verifiqué con `git grep "THROW 5xxxx"` sobre `src` que en HEAD están libres. Uso 51380 a 51386 y 51394. Reservo 51387 a 51393 para las equivalencias.

---

## 1. Contexto y modelo de tenencia aplicado

- La tenencia es de **base por empresa** (`GPOS_<empresa>`), con nodos de sucursal según ADR-53. Todas las tablas tocadas son de la base de la empresa y no llevan discriminador. `cat.ArticuloUnidad` es `ISoloCentral` (`Dominio/Maestros/Articulo.cs:77-86`): se edita en la central y se replica a los nodos. El kárdex y las líneas de documento nacen en el nodo que emite.
- Lo que hay hoy (verificado):
  - El único escritor del kárdex es `LibroInventario.Entidades` (`LibroInventario.cs:222-229`). `MovimientoNuevo.Linea` es `short` (`:14`).
  - El conteo trunca la línea a `short` con `(short)Math.Min(x.Linea, short.MaxValue)` (`InventarioService.cs:379`), aunque `inv.ConteoLinea.Linea` ya es `int` (guion 3344).
  - `ArmarAsync` no fija `FactorUnidad` (queda el 1 por omisión de `Inventario.cs:171`) y pasa al kárdex la cantidad de la línea sin convertirla (`InventarioService.cs:166-176`). Tampoco fija `MotivoAjusteId` ni la clase 5 en AJU (D-K1).
  - `inv.ConteoLinea` no tiene unidad. `LineasConteo` muestra la unidad de **venta** (`ConsultasDocInventario.cs:103-106`) y `PrepararConteoAsync` propone la unidad de venta (`InventarioService.cs:296`).
  - Todas las filas de `cat.ArticuloUnidad` nacen con factor 1 (`MaestrosService.Articulos.cs:337`, `ImportacionMaestros.cs:584`, `ListasPreciosService.cs:271,419`).
  - La regla tipo 51344 solo cubre FCP y DVS (`SqlMigracionesOla4.cs:229-241`).
- Semántica fijada por el propietario y aplicada aquí:
  - `DocInventarioLinea.CostoUnitario` va **por unidad de línea**. `ConsultasDocInventario.cs:41` suma `ROUND(Cantidad × CostoUnitario, 2)`: es coherente y no cambia.
  - El kárdex va **por unidad base**.
  - `VentaLinea.CostoUnitario` va por unidad base: lo fija `VentasNg.cs:72` con `CostoEfectivo`.
  - `CompraLinea.CostoKardex` ya está en unidad base.
  - **`ConteoLinea.CostoUnitario` queda por unidad base**. Es decisión mía porque la diferencia del conteo es nativa de la base. Así `BuscarConteos` (`Diferencia × CostoUnitario`) sigue correcto. Alternativa descartada: costo por unidad de línea, que obligaría a dividir por el factor en el valor del conteo y en el kárdex de clase 7.

## 2. Tablas y relaciones (DDL exacto)

### 2.1 `inv.Movimiento`

```sql
-- R4 (cambio de tipo; ningún índice ni restricción usa Linea: guion 4382-4422, 5640-5641, 10147)
ALTER TABLE inv.Movimiento ALTER COLUMN Linea int NOT NULL;

-- R1: auditoría de la unidad del documento (NULL = no registrado: historia y escritores sin unidad, p. ej. traslados)
ALTER TABLE inv.Movimiento ADD UnidadId       smallint      NULL,
                               FactorUnidad   decimal(19,6) NULL,
                               CantidadOrigen decimal(18,6) NULL;
```

- **Sin llave foránea a `cat.ArticuloUnidad`**, a propósito. EF crearía el índice `(ArticuloId, UnidadId)` sobre la tabla más escrita del sistema. La integridad la dan R2 (la unidad del movimiento = la de la línea, y la línea sí tiene FK) y R7. Alternativa descartada: FK sin índice, que con `HasForeignKey` no se puede expresar limpiamente en EF y deja un barrido del kárdex en cada borrado de una unidad.
- En EF (`InvConfiguracion.cs:71-103`): `Linea` pasa a `int`. Se agregan `UnidadId short?`, `FactorUnidad decimal?` con `HasPrecision(19,6)` y `CantidadOrigen decimal?` con `HasPrecision(18,6)`.

### 2.2 `inv.ConteoLinea`

```sql
ALTER TABLE inv.ConteoLinea ADD UnidadId     smallint      NULL,
                                FactorUnidad decimal(19,6) NOT NULL CONSTRAINT DF_ConteoLinea_Factor DEFAULT 1;
ALTER TABLE inv.ConteoLinea ADD CONSTRAINT FK_ConteoLinea_ArticuloUnidad FOREIGN KEY (ArticuloId, UnidadId)
    REFERENCES cat.ArticuloUnidad (ArticuloId, UnidadId);
ALTER TABLE inv.ConteoLinea ADD CONSTRAINT CK_ConteoLinea_Factor CHECK (FactorUnidad > 0 AND (UnidadId IS NOT NULL OR FactorUnidad = 1));
CREATE INDEX IX_ConteoLinea_ArticuloId_UnidadId ON inv.ConteoLinea (ArticuloId, UnidadId);
-- EF quita IX_ConteoLinea_ArticuloId (el compuesto cubre FK_ConteoLinea_Articulo): DropIndex, no es operación peligrosa para MigracionesTests

-- Diferencia en unidad base: se quita y se recrea (depende de FactorUnidad). Va por SQL, como en Ola3Firmas.cs:187-191
-- revisado-por: arquitecto-datos 2026-10-08
ALTER TABLE inv.ConteoLinea DROP COLUMN Diferencia;
ALTER TABLE inv.ConteoLinea ADD Diferencia AS
    CONVERT(decimal(18,6), ISNULL(ROUND(CantidadContada * FactorUnidad, 6), ExistenciaCorte) - ExistenciaCorte) PERSISTED;
```

- Semántica: `ExistenciaCorte` está en unidad base. `CantidadContada` y `ConteoCaptura.Cantidad` están en la **unidad de la línea**. `Diferencia` queda en unidad base.
- Las filas históricas quedan con `UnidadId NULL` y `FactorUnidad = 1`. Significan «contado en unidad base», que es lo que de verdad pasó: la diferencia fue directo al kárdex. Su `Diferencia` no cambia porque `ROUND(x × 1, 6) = x`.
- La unicidad `UX_ConteoLinea_Articulo (DocumentoId, ArticuloId, LoteId)` se mantiene: **una unidad por artículo y lote en cada conteo**. Alternativa descartada: varias líneas del mismo artículo en unidades distintas (cajas más sueltas). Duplicaría `ExistenciaCorte` y rompería la suma de 51311. Si hace falta mezclar unidades, se resuelve en la captura (convertir a la unidad de la línea), no en el esquema.
- En EF: `HasComputedColumnSql` de `Diferencia` con la expresión nueva. EF generará DropColumn y AddColumn, y por eso va la **marca de revisión**.

## 3. Restricciones e integridad

```sql
-- R5
ALTER TABLE inv.Movimiento WITH CHECK ADD CONSTRAINT CK_Movimiento_Costo CHECK (CostoUnitario >= 0);

-- R1: coherencia. CantidadOrigen lleva el signo del movimiento; NULL en las tres = historia o escritor sin unidad.
-- Unidad y factor sin CantidadOrigen = conteo (clase 7): la diferencia no es exacta en la unidad de la línea.
ALTER TABLE inv.Movimiento WITH CHECK ADD CONSTRAINT CK_Movimiento_Unidad CHECK (
       (UnidadId IS NULL AND FactorUnidad IS NULL AND CantidadOrigen IS NULL)
    OR (UnidadId IS NOT NULL AND FactorUnidad > 0
        AND (CantidadOrigen IS NULL OR Cantidad = ROUND(CantidadOrigen * FactorUnidad, 6))));
```

- `ROUND(CantidadOrigen × FactorUnidad, 6)` da `decimal(38,12)`, lo que basta y sobra. El signo sale solo porque `Cantidad <> 0` (`CK_Movimiento_Cantidad`).
- En C#, toda conversión usa `MidpointRounding.AwayFromZero`, igual que `ComprasNg.CantidadBase` (`ComprasNg.cs:36`), porque `ROUND` de SQL redondea alejándose del cero. Hay que agregar `ComprasNg.CostoBase(costoLinea, factor) = Math.Round(costoLinea / factor, 6, AwayFromZero)`.
- R7 y la unidad base se resuelven con disparadores (sección 5.3). Un CHECK no puede mirar otras tablas, y una FK compuesta `Articulo(Id, UnidadBaseId) → ArticuloUnidad` es circular: el artículo nace antes que sus unidades.

## 4. Índices y consultas que los justifican

| Índice | Cambio | Consulta que lo usa | Costo de escritura |
|---|---|---|---|
| `IX_Movimiento_Documento (DocumentoId)` | INCLUDE actual + `Linea, CostoUnitario, UnidadId, FactorUnidad, CantidadOrigen` | 51380, 51381 y 51344 (comparación por línea, búsqueda por `DocumentoId` sin búsquedas de clave). También `MovimientosDocumento` (`ConsultasInventario.cs:138`) en anulaciones | Una escritura por movimiento, como hoy. La fila del índice crece unos 33 B. Con 1 M de movimientos al año por empresa: ≈33 MB/año (inferido; costo de almacenamiento despreciable) |
| `IX_ConteoLinea_ArticuloId_UnidadId` | nuevo (FK); sustituye `IX_ConteoLinea_ArticuloId` | R7 (`EXISTS` por artículo y unidad), FK | Tabla de baja escritura |
| R7 en `VentaLinea`, `CompraLinea` y `DocInventarioLinea` | **ya existen** `IX_*_ArticuloId_UnidadId` (guion 4758, 7370, 4166) | R7 | — |
| `IX_Movimiento_ArticuloFecha` | sin cambio | 51385 (`EXISTS` por `ArticuloId`) | — |

Afectados por R4: **ninguno**. `Linea` no está en ninguna llave ni INCLUDE de `inv.Movimiento` (guion 4382-4422, 5640-5641 y 10147, que es el vigente de `Ola4IndiceKardex`). Lo agrego al INCLUDE de `IX_Movimiento_Documento` en la misma migración, **después** del ALTER. En EF va en `IncludeProperties` y EF genera DropIndex y CreateIndex.

## 5. Reglas del motor (SQL de `SqlMigracionesOla4FactorUnidad.cs`)

Convención: los fragmentos se escriben con comillas simples. Los lotes vivos (`Ola4AjusteCerradaDisparadores()` y `DocumentoOla4ConConversion()`) ya pasaron por `Exec`. Hay que comprobarlo en el árbol: `SqlMigracionesOla4AjusteCerrada.cs:20` parchea con `''AJU''`. Por eso el texto insertado lleva las comillas **duplicadas** (`.Replace("'", "''")`). `Parchear` falla si el ancla no aparece exactamente una vez.

### 5.1 `doc.TR_Documento_Emision`: 51380, 51381 y 51382

- Base: `Ola4AjusteCerradaDisparadores()`, que es la versión vigente (guion 9985).
- Ancla: `-- CA-22: la aplicación del conteo mueve exactamente (contado - existencia del corte), por artículo y lote`.
- El texto nuevo va **antes** del ancla, con el ancla al final.

```sql
            -- R2 (2026-10-08): kárdex de la venta = sus líneas inventariables en unidad base (cantidad × factor, 6 decimales, con signo),
            -- con la unidad, el factor vigente y la cantidad de la línea, al costo por unidad base de la línea. La factura de un conduce no mueve.
            IF @hayVenta = 1 AND @codigo IN ('FAC', 'FPOS', 'DEV') AND @origen <> 'I'
            BEGIN
                IF EXISTS (SELECT 1
                             FROM (SELECT l.Linea, l.ArticuloId, l.UnidadId, l.FactorUnidad, au.Factor AS FactorVigente, l.CostoUnitario,
                                          l.Cantidad * s.Signo AS CantOrigen, ROUND(l.Cantidad * l.FactorUnidad, 6) * s.Signo AS Cant
                                     FROM ventas.Venta v
                                     JOIN ventas.VentaLinea l ON l.DocumentoId = v.DocumentoId
                                     JOIN cat.Articulo a ON a.Id = l.ArticuloId AND a.Inventariable = 1
                                     JOIN cat.ArticuloUnidad au ON au.ArticuloId = l.ArticuloId AND au.UnidadId = l.UnidadId
                                     CROSS JOIN (SELECT CASE WHEN @codigo = 'DEV' THEN 1 ELSE -1 END AS Signo) s
                                    WHERE v.DocumentoId = @id AND v.AlmacenId IS NOT NULL
                                      AND NOT (@codigo = 'FAC' AND EXISTS (SELECT 1 FROM doc.Documento o JOIN doc.TipoDocumento t ON t.Id = o.TipoDocumentoId
                                                                            WHERE o.Id = v.DocumentoOrigenId AND t.Codigo = 'CON'))) l
                             FULL JOIN (SELECT m.Linea, m.ArticuloId, m.UnidadId, m.FactorUnidad, m.CantidadOrigen, m.Cantidad, m.CostoUnitario
                                          FROM inv.Movimiento m WHERE m.DocumentoId = @id AND m.MovimientoRevertidoId IS NULL) m ON m.Linea = l.Linea
                            WHERE l.Linea IS NULL OR m.Linea IS NULL OR m.ArticuloId <> l.ArticuloId OR m.Cantidad <> l.Cant
                               OR m.CostoUnitario <> l.CostoUnitario OR m.UnidadId IS NULL OR m.UnidadId <> l.UnidadId
                               OR m.FactorUnidad <> l.FactorUnidad OR m.CantidadOrigen <> l.CantOrigen OR l.FactorUnidad <> l.FactorVigente)
                    THROW 51380, N'El kárdex de la venta no coincide con sus líneas: cantidad × factor en unidad base, unidad y factor vigentes y costo por unidad base (R2).', 1;
            END
            -- R2 y D-K1 (2026-10-08): kárdex de entrada, conduce y ajuste = sus líneas en unidad base (cantidad × factor × signo), costo de la línea ÷ factor;
            -- el ajuste lleva motivo en cada línea y su kárdex es de clase 5 con ese motivo
            IF @codigo IN ('ENT', 'CON', 'AJU')
            BEGIN
                IF @codigo = 'AJU' AND EXISTS (SELECT 1 FROM inv.DocInventarioLinea l WHERE l.DocumentoId = @id AND l.MotivoAjusteId IS NULL)
                    THROW 51382, N'Cada línea del ajuste de inventario lleva su motivo de ajuste (D-K1).', 1;
                IF EXISTS (SELECT 1
                             FROM (SELECT l.Linea, l.ArticuloId, l.UnidadId, l.FactorUnidad, au.Factor AS FactorVigente, l.MotivoAjusteId,
                                          l.Cantidad * l.Signo AS CantOrigen, ROUND(l.Cantidad * l.FactorUnidad, 6) * l.Signo AS Cant,
                                          ROUND(l.CostoUnitario / l.FactorUnidad, 6) AS Costo,
                                          CONVERT(tinyint, CASE WHEN @codigo = 'AJU' THEN 5 ELSE 1 END) AS Clase
                                     FROM inv.DocInventarioLinea l
                                     JOIN cat.ArticuloUnidad au ON au.ArticuloId = l.ArticuloId AND au.UnidadId = l.UnidadId
                                    WHERE l.DocumentoId = @id) l
                             FULL JOIN (SELECT m.Linea, m.ArticuloId, m.UnidadId, m.FactorUnidad, m.CantidadOrigen, m.Cantidad, m.CostoUnitario,
                                               m.Clase, m.MotivoAjusteId
                                          FROM inv.Movimiento m WHERE m.DocumentoId = @id AND m.MovimientoRevertidoId IS NULL) m ON m.Linea = l.Linea
                            WHERE l.Linea IS NULL OR m.Linea IS NULL OR m.ArticuloId <> l.ArticuloId OR m.Cantidad <> l.Cant
                               OR m.CostoUnitario <> l.Costo OR m.UnidadId IS NULL OR m.UnidadId <> l.UnidadId
                               OR m.FactorUnidad <> l.FactorUnidad OR m.CantidadOrigen <> l.CantOrigen OR l.FactorUnidad <> l.FactorVigente
                               OR m.Clase <> l.Clase OR ISNULL(m.MotivoAjusteId, -1) <> ISNULL(l.MotivoAjusteId, -1))
                    THROW 51381, N'El kárdex del documento de inventario no coincide con sus líneas: cantidad × factor × signo en unidad base, unidad y factor vigentes, costo de la línea ÷ factor y, en el ajuste, clase 5 con su motivo (R2, D-K1).', 1;
            END
```

Notas:
- Con `@origen = 'I'`, la entrada de existencias iniciales (`ImportacionExistencias.cs:193-196`) **sí** entra: usa `ArmarAsync` y tiene líneas. No pasa lo mismo que con las compras importadas.
- `l.Cantidad × FactorUnidad`: `decimal(18,6) × decimal(19,6)` da `decimal(37,12)`. La división `decimal(19,6) / decimal(19,6)` da `decimal(38,19)` según las reglas de SQL Server 2016+ (inferido), así que `ROUND(…, 6)` es exacto.
- 51311 (conteo) **no se toca**: compara `SUM(Diferencia)` con `SUM(m.Cantidad)` por artículo y lote, y `Diferencia` ya sale en unidad base (2.2).
- Hay una 51382 posible para borradores de AJU existentes: hoy no hay AJU en borrador porque se emiten al crearse (`InventarioService.cs:134`).

### 5.2 `doc.TR_Documento_Ola4`: 51344 con la auditoría (FCP, DVS)

Base: `DocumentoOla4ConConversion()`, la vigente (guion 9403). Son tres `Parchear`:

1. `ROUND(l.Cantidad * l.FactorUnidad, 6) * CASE WHEN e.Codigo = 'DVS' THEN -1 ELSE 1 END AS Cant, l.CostoKardex` → se agrega `, l.UnidadId, l.FactorUnidad, l.Cantidad * CASE WHEN e.Codigo = 'DVS' THEN -1 ELSE 1 END AS CantOrigen`.
2. `SELECT m.DocumentoId, m.Linea, m.ArticuloId, m.Cantidad, m.CostoUnitario` → se agrega `, m.UnidadId, m.FactorUnidad AS FactorM, m.CantidadOrigen`.
3. `OR (l.CostoKardex IS NULL OR m.CostoUnitario <> l.CostoKardex))` → `OR (l.CostoKardex IS NULL OR m.CostoUnitario <> l.CostoKardex) OR m.UnidadId IS NULL OR m.UnidadId <> l.UnidadId OR m.FactorM <> l.FactorUnidad OR m.CantidadOrigen <> l.CantOrigen)`.

El texto de 51344 no cambia. Opcional: comprobar el factor vigente con `JOIN cat.ArticuloUnidad`, que ataja el defecto de la «unidad ajena» (`.Compras.cs:343-345`). Lo recomiendo con un cuarto parche igual al de 5.1.

### 5.3 Disparadores nuevos en `cat` (R7)

```sql
CREATE OR ALTER TRIGGER cat.TR_ArticuloUnidad_Factor ON cat.ArticuloUnidad AFTER INSERT, UPDATE AS
BEGIN
    SET NOCOUNT ON;
    -- La réplica de la central (ADR-53) trae filas ya validadas
    IF SESSION_CONTEXT(N'gpos.incorporacion') IS NOT NULL RETURN;
    IF EXISTS (SELECT 1 FROM inserted i JOIN cat.Articulo a ON a.Id = i.ArticuloId AND a.UnidadBaseId = i.UnidadId WHERE i.Factor <> 1)
        THROW 51384, N'La unidad base del artículo tiene factor 1 (R7).', 1;
    IF NOT UPDATE(Factor) RETURN;
    IF EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON d.ArticuloId = i.ArticuloId AND d.UnidadId = i.UnidadId
                WHERE i.Factor <> d.Factor
                  AND (   EXISTS (SELECT 1 FROM ventas.VentaLinea x        WHERE x.ArticuloId = i.ArticuloId AND x.UnidadId = i.UnidadId)
                       OR EXISTS (SELECT 1 FROM compras.CompraLinea x      WHERE x.ArticuloId = i.ArticuloId AND x.UnidadId = i.UnidadId)
                       OR EXISTS (SELECT 1 FROM inv.DocInventarioLinea x   WHERE x.ArticuloId = i.ArticuloId AND x.UnidadId = i.UnidadId)
                       OR EXISTS (SELECT 1 FROM inv.ConteoLinea x          WHERE x.ArticuloId = i.ArticuloId AND x.UnidadId = i.UnidadId)
                       -- Un nodo sin conexión puede tener documentos con esta unidad aún no replicados: la central no los ve
                       OR EXISTS (SELECT 1 FROM sync.Nodo n WHERE n.EsCentral = 0 AND n.Inhabilitado = 0)))
        THROW 51383, N'El factor de una unidad ya usada en documentos (o con sucursales sin conexión activas) no cambia: inhabilítela y cree otra unidad (R7).', 1;
END;

CREATE OR ALTER TRIGGER cat.TR_Articulo_UnidadBase ON cat.Articulo AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(UnidadBaseId) RETURN;
    IF SESSION_CONTEXT(N'gpos.incorporacion') IS NOT NULL RETURN;
    IF EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON d.Id = i.Id
                WHERE i.UnidadBaseId <> d.UnidadBaseId
                  AND (   EXISTS (SELECT 1 FROM inv.Movimiento m         WHERE m.ArticuloId = i.Id)
                       OR EXISTS (SELECT 1 FROM ventas.VentaLinea x      WHERE x.ArticuloId = i.Id)
                       OR EXISTS (SELECT 1 FROM compras.CompraLinea x    WHERE x.ArticuloId = i.Id)
                       OR EXISTS (SELECT 1 FROM inv.DocInventarioLinea x WHERE x.ArticuloId = i.Id)
                       OR EXISTS (SELECT 1 FROM inv.ConteoLinea x        WHERE x.ArticuloId = i.Id)))
        THROW 51385, N'La unidad base de un artículo con movimientos o documentos no cambia: cree un artículo nuevo (R7).', 1;
    IF EXISTS (SELECT 1 FROM inserted i JOIN cat.ArticuloUnidad au ON au.ArticuloId = i.Id AND au.UnidadId = i.UnidadBaseId WHERE au.Factor <> 1)
        THROW 51384, N'La unidad base del artículo tiene factor 1 (R7).', 1;
END;
```

- **Por qué un disparador y no solo una regla en el servicio:** hoy no hay pantalla de equivalencias. Las filas se crean o tocan desde cuatro servicios distintos (sección 1) y desde la importación, y en el futuro desde la réplica y desde SQL de soporte. El disparador es la única garantía que no depende de quién escriba. Sigue el precedente de 51310 (`cat.TR_Articulo_Codigo`, guion 5181-5191). El servicio de equivalencias (tanda posterior) repetirá la validación antes de escribir para dar un 422 con mensaje propio (`CodigoRegla`), como hace `LibroInventario.SoloAjuste`.
- Referencias consideradas: las líneas de los cuatro documentos, **incluidos los borradores** (COT, PED, ORD). Guardan una copia del factor, y una conversión posterior mezclaría factores. `cat.Precio` y `cat.ArticuloCodigo` **no** congelan el factor: un precio se puede rehacer. El kárdex se cubre por transitividad, porque todo movimiento con unidad nace de una línea (R2).
- El borrado ya lo impiden las FK de las líneas, de `Precio` y de `ArticuloCodigo` (error 547: el servicio lo traduce a «inhabilite la unidad»).
- Registro en EF (si no, `OUTPUT` sin `INTO` falla):
  - `DisparadoresNg.PorTabla["cat.ArticuloUnidad"] = ["TR_ArticuloUnidad_Factor"]`.
  - `t.HasTrigger("TR_Articulo_UnidadBase")` junto a `TR_Articulo_Codigo` (`MaeConfiguracion.cs:131`).

### 5.4 `inv.TR_ConteoLinea_Corte` reescrito: 51386

Es el texto vigente de `SqlMigracionesOla3.cs:317` (guion 5156) con dos bloques añadidos al final. La versión para el Down se toma con `LoteDe(Ola3Disparadores(), "CREATE OR ALTER TRIGGER inv.TR_ConteoLinea_Corte ON")`.

```sql
        -- Conteo con unidad (2026-10-08): cada línea nueva indica su unidad con el factor vigente; la unidad no cambia con capturas o tras el corte
        IF EXISTS (SELECT 1 FROM inserted i LEFT JOIN deleted d ON d.DocumentoId = i.DocumentoId AND d.Linea = i.Linea
                    LEFT JOIN cat.ArticuloUnidad au ON au.ArticuloId = i.ArticuloId AND au.UnidadId = i.UnidadId
                   WHERE d.DocumentoId IS NULL AND (i.UnidadId IS NULL OR au.Factor <> i.FactorUnidad))
            THROW 51386, N'Cada línea del conteo indica su unidad con el factor vigente del artículo.', 1;
        IF (UPDATE(UnidadId) OR UPDATE(FactorUnidad))
           AND EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON d.DocumentoId = i.DocumentoId AND d.Linea = i.Linea
                        JOIN inv.Conteo c ON c.DocumentoId = i.DocumentoId
                       WHERE (ISNULL(i.UnidadId, -1) <> ISNULL(d.UnidadId, -1) OR i.FactorUnidad <> d.FactorUnidad)
                         AND (c.CorteEn IS NOT NULL OR EXISTS (SELECT 1 FROM inv.ConteoCaptura k WHERE k.DocumentoId = i.DocumentoId AND k.Linea = i.Linea)))
            THROW 51386, N'La unidad de una línea del conteo no cambia después de capturar o del corte.', 1;
```

## 6. Conteo, D-K1 y D-K2 en el servicio (para el backend)

### 6.1 Conteo

- `LineaConteoDto` y el contrato reciben la `Unidad`. Si viene vacía, se usa la **unidad base** (factor 1), no la de venta (`InventarioService.cs:296`). Al guardar, se resuelven la unidad y el factor vigentes de `cat.ArticuloUnidad`.
- `ConteoLinea`: `UnidadId`, `FactorUnidad` y `CantidadContada` en la unidad de la línea. `ExistenciaCorte` en base. `CostoUnitario` por unidad base.
- La diferencia que va al kárdex es la calculada por el motor. El servicio la calcula igual: `Math.Round(contado × factor, 6, AwayFromZero) − corte`. Mejor aún: la relee de `inv.ConteoLinea.Diferencia` después de `SaveChanges`, lo que elimina cualquier divergencia de redondeo.
- `MovimientoNuevo` con `Linea = x.Linea` (int; se quita el `Math.Min`), `Clase = 7`, `UnidadId` y `FactorUnidad` de la línea, y `CantidadOrigen = null`.
- `LineasConteo` (`ConsultasDocInventario.cs:103-106`): `JOIN cat.Unidad un ON un.Id = ISNULL(l.UnidadId, a.UnidadBaseId)` y se devuelve también `l.FactorUnidad`.
- `ConteoAsync` muestra la existencia en unidad base y lo contado en la unidad de la línea. La pantalla rotula las dos unidades.

### 6.2 51311

Queda **igual**, sin parche: la conversión vive en la columna calculada `Diferencia`. Ventaja: no cambia el disparador de emisión en el camino del conteo y la prueba vigente de 51311 sigue valiendo.

### 6.3 D-K1 (misma tanda)

- `DocumentoInventario` recibe un `IdMotivoAjuste` en el encabezado (o uno por línea, si el contrato lo prefiere). En AJU es obligatorio y debe estar habilitado en `inv.MotivoAjuste`. `Notas` sigue siendo el texto libre exigido.
- `ArmarAsync` fija `DocInventarioLinea.MotivoAjusteId` y `MovimientoNuevo(Clase: 5, MotivoAjusteId: …)` solo en AJU.
- `CK_Movimiento_Ajuste` (`Clase <> 5 OR MotivoAjusteId IS NOT NULL`) ya existe y 51382 lo exige en la línea. Los AJU históricos de clase 1 sin motivo no se tocan, porque el kárdex es de solo inserción. AU-11 y HC-19 los mostrarán como «sin clasificar (anterior a D-K1)».
- Hace falta un motivo de ajuste sembrado o creado antes de la primera prueba de AJU. Si no, 51382 rechaza todos los ajustes.

### 6.4 D-K2 (lote del conteo): **a T4 con ADR-119**, no aquí

- En datos no falta nada. `inv.ConteoLinea.LoteId`, `UX_ConteoLinea_Articulo (DocumentoId, ArticuloId, LoteId)` y 51311 por artículo y lote ya existen (guion 3346, 4046, 10093-10101).
- El defecto es del servicio, pero arreglarlo bien exige el **corte por lote** (`ExistenciaCorte` desde `inv.ExistenciaLote`) y una hoja de conteo por lote en `PrepararConteoAsync`. Eso es justo lo que decide ADR-119.
- Poner solo `LoteId` en la línea con la existencia del artículo dejaría una `Diferencia` errónea. Es peor que el defecto actual.
- Este diseño no estorba a T4: las columnas de unidad son ortogonales al lote.

## 7. Rendimiento de la emisión (T-28 y T-57 del 14-oct)

- Costo nuevo en FAC, FPOS y DEV: **una sentencia** con:
  - búsqueda por rango en la PK de `VentaLinea` (páginas ya en memoria por la lectura unificada del mismo disparador);
  - búsquedas por PK en `cat.Articulo` y `cat.ArticuloUnidad`, una por línea;
  - una búsqueda en `ventas.Venta` y, si hay origen, dos más en `doc.Documento` y `TipoDocumento`;
  - búsqueda por rango en `IX_Movimiento_Documento`, ya cubriente con el INCLUDE nuevo, sobre páginas recién escritas en la misma transacción.
  - Sin E/S física ni bloqueos nuevos: solo lecturas de filas propias.
- Estimación (inferida, sin medir): ticket de 20 líneas ≈ 60-90 lecturas lógicas ≈ **+0,1 a 0,3 ms** de CPU por emisión. Como referencia, DQ-3 midió +0,06 ms para una salida temprana. ENT, CON y AJU pagan lo mismo y no son la ruta crítica.
- **Por qué por línea y no un total por documento:** las dos versiones leen las mismas filas, así que el costo es casi igual. La comparación por totales (COUNT, SUM de cantidades, SUM de cantidad × costo) esconde errores que se compensan (dos líneas con cantidades intercambiadas) y no dice qué línea falla.
- **Plan B** si el p95 del 14-oct supera el presupuesto: sustituir 51380 en FPOS por la versión agregada (dos `SELECT` escalares con `COUNT`, `SUM(Cantidad)` y `SUM(Cantidad × Costo)` de cada lado, sin `FULL JOIN`). Se hace con un `Parchear` adicional y deja la comparación por línea en FAC y DEV.
- **Recomendación de orden:** desplegar esta migración **antes del 14-oct**, para que la medición incluya R2 y no haya que repetirla.

## 8. Script de migración y reversión

### 8.1 Orden dentro de la migración `Ola4FactorUnidad` (Up)

1. `Sql(SqlMigraciones.Ola4FactorUnidadPrevia())`:
   ```sql
   IF EXISTS (SELECT 1 FROM inv.Movimiento WHERE CostoUnitario < 0)
       THROW 51394, N'Hay movimientos del kárdex con costo negativo: revíselos antes de aplicar Ola4FactorUnidad (R5).', 1;
   ```
2. `AlterColumn` de `inv.Movimiento.Linea` a `int`, con la marca:
   `// revisado-por: arquitecto-datos 2026-10-08 (R4: Linea smallint -> int; ningún índice ni restricción la usa)`.
   `MigracionesTests.PeligrosasSinRevision` **no** detecta `AlterColumn`: solo `DropTable`, `DropColumn`, `RenameColumn`, `RenameTable` y, en `Sql(...)`, `DROP COLUMN`, `DROP TABLE` y `sp_rename` (`MigracionesTests.cs:117-148`). La marca va por política, no porque el test la exija.
3. `AddColumn` de `UnidadId`, `FactorUnidad` y `CantidadOrigen` en `inv.Movimiento`; `AddCheckConstraint` de `CK_Movimiento_Costo` y `CK_Movimiento_Unidad`.
4. `DropIndex` y `CreateIndex` de `IX_Movimiento_Documento` con el INCLUDE nuevo.
5. `inv.ConteoLinea`: `AddColumn` de `UnidadId` y `FactorUnidad` (con DEFAULT 1); FK; CHECK; índice compuesto (y `DropIndex` de `IX_ConteoLinea_ArticuloId`). **Marca obligatoria** inmediatamente antes de quitar `Diferencia`: `// revisado-por: arquitecto-datos 2026-10-08 (Diferencia calculada en unidad base; se quita y se recrea)`. Sin ella, el test falla. Después se recrea `Diferencia`.
6. `Sql(SqlMigraciones.Ola4FactorUnidadDisparadores())` con `cat.TR_ArticuloUnidad_Factor`, `cat.TR_Articulo_UnidadBase`, `inv.TR_ConteoLinea_Corte`, `doc.TR_Documento_Ola4` (parche de 51344) y `doc.TR_Documento_Emision` (parche de 51380 a 51382). Las reglas van **al final**, cuando ya existen las columnas a las que se refieren.

Es idempotente en el patrón del árbol. El historial de EF evita repetir los pasos de DDL; el SQL de reglas es `CREATE OR ALTER`; la previa solo lee.

### 8.2 Down (en orden inverso)

1. `Sql(Ola4FactorUnidadDown())`:
   - recrea `TR_Documento_Emision` con `Ola4AjusteCerradaDisparadores()`, `TR_Documento_Ola4` con `DocumentoOla4ConConversion()` y `TR_ConteoLinea_Corte` con `LoteDe(Ola3Disparadores(), …)`;
   - `DROP TRIGGER IF EXISTS cat.TR_ArticuloUnidad_Factor, cat.TR_Articulo_UnidadBase`;
   - previa del Down: `IF EXISTS (SELECT 1 FROM inv.Movimiento WHERE Linea > 32767) THROW 51394, N'… no se puede volver a smallint'`.
2. Quitar y recrear `Diferencia` con la expresión anterior (`ISNULL(CantidadContada, ExistenciaCorte) - ExistenciaCorte`).
   - **Pérdida de datos:** los conteos en unidades no base quedarían con una diferencia distinta de la aplicada. Hoy no existen, porque todos los factores son 1.
3. Quitar el índice, la FK, el CHECK y las columnas de `ConteoLinea`. Restaurar `IX_Movimiento_Documento`. Quitar los CHECK y las columnas de `Movimiento`. `Linea` a `smallint`.

### 8.3 Despliegue (hoy todo es desarrollo)

1. Detener los procesos de desarrollo que usen las bases `GPOS_*` de prueba y revisar también los procesos huérfanos de bash y pwsh.
2. Respaldo de cada base de prueba.
3. Aplicar la migración (paquete de EF) en la central y en cada nodo de prueba.
4. Desplegar el binario.
5. Suite completa.
6. Medición del 14-oct.

**La migración y el código van en el mismo commit y despliegue.** Con las reglas activas, un binario viejo (sin `UnidadId` y los demás datos de auditoría en el kárdex) recibe 51380 en **todas** las ventas. Alternativa descartada: tolerar `m.UnidadId IS NULL` durante una transición. Permitiría desacoplar, pero deja la regla sin exigir, y aquí no hay producción que proteger.

### 8.4 Filas históricas: **dejar NULL** (recomendado)

- `inv.Movimiento` es de solo inserción (`DENY UPDATE, DELETE … TO gpos_app`, guion 5433). Rellenarlo exige un UPDATE masivo del libro inmutable.
- Para las ventas, el inventario y el conteo, el relleno inventaría un hecho que no se registró («unidad X, factor 1»), aunque el valor coincida.
- `CK_Movimiento_Unidad` acepta las tres en NULL. Los informes leen NULL como «no registrado (anterior al 2026-10-08)».
- `ConteoLinea` histórica: `UnidadId NULL` y `FactorUnidad 1` (sección 2.2), sin UPDATE. Así no hace falta desactivar `TR_ConteoLinea_Corte`, que rechaza cambios en conteos aplicados (51302).
- Alternativa descartada: relleno solo para FCP y DVS desde `CompraLinea`, donde el dato es real. Su valor de auditoría es mínimo con factor 1 y obliga a tocar el libro inmutable.

## 9. Respaldo, restauración y retención

No cambia la política. Antes de aplicar, un respaldo completo de cada base de desarrollo (sección 8.3). Crecimiento: kárdex ≈ +20 B por fila e índice ≈ +33 B por fila (≈53 MB por cada millón de movimientos; inferido). No mueve el costo de hosting de forma apreciable.

## 10. Privilegios de base de datos

- Se mantiene `DENY UPDATE, DELETE ON inv.Movimiento TO gpos_app`.
- Los disparadores nuevos se ejecutan con los permisos del dueño (cadena de propiedad `dbo`), igual que los vigentes. No hacen falta permisos nuevos.
- `gpos_app` necesita `SELECT` sobre `sync.Nodo`, que ya lee 51341.

## 11. Pruebas que deben existir

**Base de datos (integración con SQL Server, en `ModeloNg`):**

1. `CK_Movimiento_Unidad`:
   - acepta las tres columnas en NULL;
   - acepta `(12, 1.5)` con cantidad 18, `(12, −1.5)` con −18 y unidad + factor con `CantidadOrigen` NULL;
   - rechaza la incoherencia, el factor 0 y `CantidadOrigen` sin factor.
2. `CK_Movimiento_Costo` rechaza −0,000001. La previa 51394 falla sobre una base con un costo negativo sembrado.
3. R4: insertar un movimiento con `Linea = 40000`. El conteo con 33 000 líneas lleva `Linea` intacta al kárdex (hoy se trunca).
4. 51380, con un artículo de unidad `CJ` y factor 12:
   - FAC correcta pasa;
   - pasa la cantidad sin convertir → 51380;
   - falta el movimiento → 51380;
   - movimiento de más → 51380;
   - costo distinto → 51380;
   - auditoría en NULL → 51380;
   - FPOS correcta pasa;
   - DEV con signo positivo pasa;
   - FAC de un conduce sin kárdex pasa, y con kárdex → 51380;
   - línea no inventariable sin kárdex pasa;
   - el factor de la línea distinto del vigente → 51380.
5. 51381:
   - ENT de 2 cajas a 120 → kárdex +24 a 10;
   - CON → −24;
   - AJU ±;
   - redondeo en el punto medio: costo 0,000001 con factor 2 → 0,000001 en SQL (`AwayFromZero` en C#);
   - entrada de existencias iniciales (origen I) incluida.
6. 51382:
   - AJU sin motivo;
   - AJU de clase 1;
   - AJU con un motivo en la línea distinto del del movimiento → 51381.
7. 51344: FCP con unidad, factor o `CantidadOrigen` distintos de la línea.
8. 51383:
   - cambiar el factor con una `VentaLinea` (también COT) → error;
   - sin referencias ni nodos → pasa;
   - con un nodo activo `EsCentral = 0` → error;
   - con `gpos.incorporacion` → pasa.
9. 51384 y 51385: base con factor ≠ 1, y cambio de `UnidadBaseId` con movimientos.
10. Conteo:
    - línea en `CJ` (12), contado 2, corte 20 → `Diferencia` 4 → kárdex +4 y 51311 pasa;
    - insertar una línea sin unidad → 51386;
    - cambiar la unidad con capturas o tras el corte → 51386;
    - los conteos históricos conservan su `Diferencia` (instantánea antes y después de la migración).
11. Migración: Up sobre una base con datos, Down y Up otra vez. `MigracionesTests` pasa con la marca. Se comparan los tipos con `INFORMATION_SCHEMA` (prueba vigente). La lista de `DisparadoresNg` coincide con `sys.triggers`.

**Servicio** (uno por defecto de la búsqueda previa; esos defectos los listó el coordinador y no los verifiqué todos uno por uno; sí verifiqué `ArmarAsync`, conteo, `AsignarCostosAsync` y `EntradaDesdeOrdenAsync`):
- `ArmarAsync` (factor y D-K1);
- `AsignarCostosAsync` (costo × factor; el diccionario de la orden por artículo **y unidad**);
- `EntradaDesdeOrdenAsync`;
- `ImportacionExistencias` (la unidad «UND» por omisión debe existir en `ArticuloUnidad`; si no, FK);
- devoluciones POS (`PosService.cs:596-745`) y de oficina, DVS, compras con unidad ajena, factura desde conduce;
- `RevertirAsync` copia `UnidadId`, `FactorUnidad` y `−CantidadOrigen` (la anulación de una FAC de factor 12 cumple `CK_Movimiento_Unidad`).

**Rendimiento:** T-28 y T-57 antes y después del parche, con la misma semilla. Propongo como umbral un Δp95 de 0,5 ms o menos en FPOS (cifra a fijar por el propietario).

## 12. Mantenimiento de equivalencias por artículo (pedido del propietario)

### 12.1 Qué existe y qué falta en datos

| Necesidad | Hoy (verificado) | Falta |
|---|---|---|
| Equivalencia por artículo | `cat.ArticuloUnidad (ArticuloId, UnidadId, Factor)` con `CK Factor > 0` (guion 1754) | `Inhabilitado bit NOT NULL DEFAULT 0` (retirar sin borrar) y `Version rowversion` (concurrencia en la edición) |
| Unidad base | `Articulo.UnidadBaseId` | Las reglas 51384 y 51385 (**esta tanda**) |
| Unidades de compra y venta | `Articulo.UnidadVentaId`, `UnidadCompraId` y `UnidadInformeId` (unidades por omisión) | Regla: no se inhabilita una unidad que es la base o la de venta, compra o informe por omisión (51387). No propongo marcas `PermiteVenta` y `PermiteCompra`: toda unidad habilitada sirve para ambos. Si un vertical lo exige, se agregan después |
| Código de barras por unidad | `cat.ArticuloCodigo.UnidadId` con FK compuesta (guion 1805-1810) | Nada en datos. Hoy el alta pone el código de barras en la unidad de venta (`MaestrosService.Articulos.cs:339-340`); la pantalla debe dejar elegir la unidad |
| Precio por unidad y lista | `cat.Precio.UnidadId` | Regla de servicio: si una unidad no tiene precio en la lista, se usa precio base × factor (redondeo de la lista). **Defecto que hay que corregir antes de admitir factores ≠ 1:** `ListasPreciosService.cs:271,419`, `ImportacionMaestros.cs:584` y `MaestrosService.Articulos.cs:337` **crean en silencio** la unidad con factor 1. Con R7, una «CAJA» creada así y usada queda congelada en 1 para siempre. Deben exigir que la equivalencia exista (error 51388 o validación previa) |
| Importación por plantilla | No existe para equivalencias | Plantilla `Artículo; Unidad; Factor; Código de barras (opcional)` con validación previa (como `ImportacionExistencias`): factor > 0, base = 1, R7 |
| Bitácora | — | Una línea en `audit.Bitacora` por alta, cambio de factor o inhabilitación (servicio) |

### 12.2 Reglas

- Factor mayor que 0 (CHECK vigente).
- Una sola unidad base por artículo, con factor 1: la da `Articulo.UnidadBaseId` y 51384 la garantiza.
- El factor no cambia con referencias ni con nodos activos (51383). Otra equivalencia es otra unidad.
- La unidad base no cambia con movimientos (51385).
- No se borra si tiene referencias (FK, 547): se **inhabilita**. Una unidad inhabilitada no se ofrece en documentos nuevos (servicio) y sigue válida en los históricos.

### 12.3 Réplica a los nodos (ADR-53)

- `ArticuloUnidad` es `ISoloCentral`: el mantenimiento solo se ofrece en la central (equivalente a REQUIERE_CENTRAL, 51341) y los nodos la reciben por réplica con `gpos.incorporacion`, que los disparadores dejan pasar.
- La central no ve los documentos de un nodo aún no replicados. Por eso 51383 bloquea cualquier cambio de factor mientras haya nodos activos.
- La alta de unidades nuevas no tiene ese riesgo: el nodo no puede usar una unidad que todavía no recibió.

### 12.4 Estimación (inferida; no hay velocidad medida del equipo)

| Parte | sp |
|---|---|
| Datos: `Inhabilitado`, `Version`, 51387 y 51388, pruebas de base | 2 |
| Servicio: CRUD, validaciones, bitácora, precio derivado, quitar la creación silenciosa en 4 sitios | 5 |
| Pantalla Web (cuadrícula en la ficha del artículo) | 3 |
| Pantalla MAUI | 2 |
| Importación por plantilla (equivalencias y códigos por unidad) | 3 |
| Pruebas de servicio y de extremo a extremo (venta y compra en CJ, conteo, réplica) | 4 |
| **Total** | **≈19 sp (±30 %)** |

### 12.5 Tanda recomendada

1. **Tanda 1, ahora y antes del 14-oct:** esta migración más la corrección de `FactorUnidad` en los servicios y D-K1. Es lo que hace seguro que existan factores ≠ 1. Incluye 51384 y 51385 porque protegen el significado del kárdex desde ya. Es barato: dos disparadores.
2. **Tanda 2, desde el 15-oct:** ADR-118 y ADR-119, con **D-K2 dentro de T4**.
3. **Tanda 3, después de ADR-118/119 y con margen antes del corte de mediados de diciembre** (orientativo: arrancar en la primera quincena de noviembre): el mantenimiento de equivalencias completo (12.1 a 12.4). Su primer paso es eliminar la creación silenciosa con factor 1. Hasta esa tanda no se puede crear un factor ≠ 1 por ninguna vía de la aplicación. R2 y R7 ya estarán vigentes cuando aparezca el primero.
4. Si el calendario del corte aprieta, la tanda 3 puede salir de la entrega 1 sin riesgo de datos: con todo en factor 1, el sistema es correcto, solo que no ofrece equivalencias.

## 13. Riesgos

| Riesgo | Severidad | Mitigación |
|---|---|---|
| Desfase entre el binario y el esquema: el binario viejo con las reglas nuevas da 51380 en toda venta | Alta | Un solo commit y despliegue (8.3); en los nodos, la misma versión |
| Redondeo distinto entre C# y SQL en el punto medio | Media | `AwayFromZero` en toda conversión; prueba del punto medio; en el conteo, releer `Diferencia` del motor |
| `ALTER COLUMN Linea` reescribe `inv.Movimiento` y toma Sch-M durante la operación (inferido; sería solo de metadatos con compresión ROW) | Baja hoy (volumen de desarrollo) | Antes de producción, medir la duración en una copia del tamaño esperado |
| 51380 tiene costo en FPOS | Media hasta el 14-oct | INCLUDE cubriente; plan B agregado (7) |
| Futuros escritores del kárdex con otra numeración de `Linea` (recetas o kits que se explotan en componentes) | Media | Un escritor nuevo de FAC, FPOS o DEV exige revisar 51380; dejarlo como criterio del ADR de recetas |
| La réplica de `inv.Movimiento` e `inv.ConteoLinea` puede no llevar las columnas nuevas si sus listas de columnas son explícitas | Media | Verificarlo en el código de sincronización (no revisado aquí) |
| AJU sin motivos sembrados: 51382 bloquea todos los ajustes | Media | Sembrar motivos antes de las pruebas |
| La importación de existencias usa «UND» por omisión, que puede no estar en `ArticuloUnidad` | Media | Usar la unidad base del artículo |

---

### Supuestos
- `SESSION_CONTEXT(N'gpos.incorporacion')` es la marca que usa la réplica de la central al escribir `cat.ArticuloUnidad` en los nodos (inferido de los disparadores vigentes).
- `DocumentoOla4ConConversion()` y `Ola4AjusteCerradaDisparadores()` son los textos vivos (guion 9403 y 9985; no hay versiones posteriores en HEAD).
- Los códigos de venta con kárdex son FAC, FPOS y DEV. La NC sin mercancía no mueve inventario.
- `CantidadFaltante` de `DocInventarioLinea` no se usa en los servicios (`git grep` sin resultados en `Servicios`).

### Decisiones candidatas a ADR
1. **Auditoría de la unidad en el kárdex con NULL para la historia, sin FK a `ArticuloUnidad`.**
   - Contexto: R1.
   - Opción elegida: NULL más integridad por R2.
   - Alternativas descartadas: rellenar la historia (toca el libro inmutable); FK con índice en la tabla más escrita.
2. **Factor de unidad inmutable con referencias o con nodos activos (R7) por disparador.**
   - Alternativa descartada: solo regla en el servicio, porque hay cuatro escritores y la réplica.
3. **Conteo: una unidad por artículo y lote, con `Diferencia` en unidad base calculada por el motor.**
   - Alternativa descartada: varias unidades por artículo.
4. **`FactorUnidad decimal(19,6)` en el kárdex** (ajuste de R1).
