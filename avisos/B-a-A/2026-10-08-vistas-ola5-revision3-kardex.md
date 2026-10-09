```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Respuesta
Prioridad: Normal
Repositorio y rama: GPOS-NG b/ola5 (0a52c38)
Estado: Abierto
```

# Vistas de la ola 5, revisión 3 (VW-02): kárdex y ajustes

En `b/ola5` (`0a52c38`, sin aplicar), `database/ola5/rpt-vistas-ventas-inventario.sql`, sección 3b: `rpt.Kardex`, `rptc.Kardex`, `rpt.AjusteInventario`, `rptc.AjusteInventario` (AJU y diferencias de CNT) y `rpt.CatMotivoAjuste`. Van en la misma migración `Ola5VistasVentasInventario` (con `EXEC(N'…')`; el `Down` las borra), sin índices nuevos; ≈ +0,05 sp para A. Contrato 1.0 (sin publicar): 34 vistas, 533 columnas, huella `DC024084477628593F829FAE34A6823813AFD0BF0AA4D4F4F8E4842A26E60A22`. Costos solo en `rptc`, en moneda base; nada fiscal.

- **I-02 / I-02b** queda en su migración aparte, con sus puertas. Mientras no exista, el reporte 20 exige artículo o categoría. Sugerencia: que el `INCLUDE` de I-02b lleve también `DocumentoId` y `MovimientoRevertidoId` (≈ 16 bytes por fila); lo decide la medición.
- **D-K1 (Media):** el ajuste AJU no guarda `MotivoAjusteId` ni la clase 5 (`InventarioService.cs:120,149-176` en `e300320`): AU-11 y HC-19 salen sin clasificar.
- **D-K2 (Media):** el conteo no lleva el lote ni en `inv.ConteoLinea` ni en el movimiento de clase 7 (`:368-371,379-380`), contra ADR-119; quizá ya esté en T4.
- **D-K4:** `FactorUnidad` también afecta al ajuste (`:176`); lo detecta V-D19. **D-K5 (Baja):** `KardexCosto` usa el literal `TipoDocumentoId = 28`.
- Pruebas al unir: V-D16 a V-D21 y V-P1 (LEEME, sección 8). Dependencias en la sección 11.

No hay nada para firma.
