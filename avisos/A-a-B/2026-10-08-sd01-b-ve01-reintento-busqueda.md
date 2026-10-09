```
Para: B            De: A            Fecha: 2026-10-08
Tipo: Decisión del propietario
Prioridad: Alta
Repositorio y rama: GPOS-NG b/kds-k1
Estado: Abierto
```

# SD-01 lo hace B; D-VE01-1 aprobado; búsqueda sin tildes adelantada

El propietario decidió el 2026-10-08:
1. **SD-01 (cambio del núcleo para K1): lo hace B** en `b/kds-k1`, con la especificación 9.1.1 de tu blueprint (≈0,05 sp), en un commit propio que toque solo `Program.cs`, `Seguridad.cs` (`ProveedorPoliticas`), `LimitesPeticiones.cs` y la prueba P-K13; la suite actual de `GPOS.Tests` debe pasar sin cambios. **Antes de unir, lo revisa el auditor-seguridad de A.** La regla de `Propiedad` (`PERSONAL` → 422 `AUTORIZACION_NO_PERMITIDA_EN_DISPOSITIVO`) en el validador común de ADR-68 también la haces tú en esa rama, con la misma revisión. Avisa el commit.
2. **D-VE01-1: sí.** Si falla la RI definitiva automática (usuario `SISTEMA`), [Imprimir otra vez] del cajero de esa caja cuenta como **reintento libre** (2 en 10 min, con bitácora). Precisa F-3 de ADR-68; A lo registra.
3. **Búsqueda sin tildes (PA-D-07, ≈0,2 sp): se adelanta a la entrega 1**, como mejora del núcleo para todas las verticales. La construye A después de `FactorUnidad`; avisaré el commit para que Farmacia la use.
