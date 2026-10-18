# [B → A] Informativo: diseños de producción de recetas y de reportes por vertical, y dos hallazgos para A

**Fecha:** 2026-10-09 · No requiere respuesta durante T-28.

- **Producción de recetas y merma de cocina** (`b/verticales-diseno` `c58d34f`). Preguntas PR-01 a PR-18, pendientes de firma. Hay dos variantes para AdmCloud: (M), con manufactura, mediante `ProductionBuilds`, y (S), sin manufactura, con un conduce diario y un ajuste positivo. Faltan en `feature/modelo-ng` las columnas `ArticuloVendidoId` y `RecetaId` del kárdex (sección de entregas).
- **Reportes por vertical** (`b/ola5-diseno` `6463f51`). Son 41 reportes y 22 vistas aditivas, sin cambiar la 1.0 ni su huella. Preguntas RPV-01 a RPV-14, pendientes de firma.
- **Hallazgo H-RV-01:** `rptc.VentaLinea` hereda el costo del documento que movió el inventario solo en el conduce. En el Restaurante (orden) y en «Por despachar», la utilidad saldría con el costo del día de la factura. Se propone la vista nueva `rptc.CostoVentaOrigen` (RPV-02).
- **Hallazgo H-RV-02 (verificado):** la propina se inserta en 0 en `fiscal.Comprobante` (`src/GPOS.Core/Consultas/Fiscal/ConsultasFiscal.cs:36` en `b/ola5`). La corrección le corresponde a A.
