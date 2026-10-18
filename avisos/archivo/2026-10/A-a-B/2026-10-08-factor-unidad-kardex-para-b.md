```
Para: B            De: A            Fecha: 2026-10-08
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: GPOS-NG feature/modelo-ng (2078a08; corrección en construcción, sin push)
Estado: Abierto
```

# FactorUnidad y kárdex: lo que cambia en el núcleo y afecta a tus vistas y diseños

El propietario aprobó el 2026-10-08 la corrección completa del factor de unidad (diseño del arquitecto-datos de A: `traspasos/A/diseno-factor-unidad-kardex-2026-10-08.md`). El backend la construye ahora; llega **antes del 14-oct** en la migración `Ola4FactorUnidad`. Avisaré el commit.

## Cambios de esquema que tocan tus vistas (`b/ola5`, sección 3b y otras)
- **`inv.Movimiento`:** columnas nuevas `UnidadId smallint NULL`, `FactorUnidad decimal(19,6) NULL`, `CantidadOrigen decimal(18,6) NULL` (NULL en la historia); `Linea` pasa de `smallint` a **`int`**; `CK_Movimiento_Costo` (≥ 0). `Cantidad` y `CostoUnitario` siguen en **unidad base**. Si `rpt.Kardex`/`rptc.Kardex` quieren mostrar la unidad de origen, pueden usar las columnas nuevas (con NULL histórico) — tú decides; si exponen `Linea`, ahora es `int`.
- **`inv.ConteoLinea`:** `UnidadId` (NULL en la historia) y `FactorUnidad` (1 por omisión); `Diferencia` se recrea **en unidad base** (mismo nombre). Revisa `rpt.AjusteInventario` (diferencias de CNT).
- **`inv.DocInventarioLinea.CostoUnitario` es por unidad de la línea**; el kárdex, por unidad base.
- **AJU guarda `MotivoAjusteId` y clase 5** (D-K1, regla 51382: motivo obligatorio por línea). AU-11 y HC-19 ya saldrán clasificados. **D-K2 (lote en el conteo) va en T4.**

## Reglas nuevas del motor (números reservados; no los uses)
- **51380** ventas (FAC, FPOS, DEV) y **51381** inventario (ENT, CON, AJU): el kárdex debe cuadrar línea a línea con cantidad × factor, unidad y costo. Se extiende 51344 en compras.
- **51382** motivo de ajuste; **51383** no cambiar el factor de una unidad en uso; **51384** unidad base con factor 1; **51385** no cambiar la unidad base con movimientos; **51386** unidad del conteo; **51394** comprobación previa de costos negativos.
- **51387 a 51393 reservados** para la tabla de equivalencias. Farmacia: **51410-51412**.

## Para tus diseños de verticales
- **Toda línea con artículo debe llevar una unidad del artículo**; una unidad ajena se **rechaza** (ya no se sustituye en silencio). Las devoluciones respetan la unidad de su línea de origen; si la factura tiene el artículo en dos unidades, se pide la unidad.
- **No se cambia el factor de una unidad en uso** (R7): otra equivalencia = unidad nueva.
- **Tabla de equivalencias** (alta de unidades, unidad base, compra y venta, plantilla): la construye A en la **tanda 3** (después de ADR-118/119, antes del corte; sale de la entrega 1 si no cabe). Hasta entonces todos los factores son 1: Duty Free, Farmacia y Restaurante no deben suponer equivalencias en la entrega 1.
- **Búsqueda sin tildes** adelantada a la entrega 1 (después de esto).
