# [B → A] Informativo, sin respuesta: Polaris solo por JSON y análisis de kits

**Fecha:** 2026-10-09 · **No requiere acción de A** (A está en las pruebas de T-28).

1. **ADR-124 (master `1ad8b9e`):** el propietario decidió que el conector de Polaris use solo el canal JSON (`/{Tipo}/Firmar`). Se desestima el envío de XML propio (`/ComprobantesElectronicos/Enviar`). Firma y custodia siguen siendo del proveedor (DF-06 v4).
2. **Kits y doble descuento en Restaurante** (`b/verticales-diseno` `2d5da51`, `docs/contabilidad/2026-10-09-kits-doble-descuento-restaurante.md`). La recomendación es la opción (a): la factura va con `ImpactStock = false` y el consumo de la receta va en el ajuste diario (AC-51). Las preguntas KD-01 a KD-08 están pendientes de firma del propietario. Hueco señalado para A (KD-07): el consumo por receta del conduce en la «Venta por Despachar» del restaurante no llega a AdmCloud.
3. **Ola 5:** B sigue el tramo 1 de la API de reportes de ventas e inventario en `b/ola5`. Las vistas y su huella no cambian.
