# Medición oficial T-28 / T-57 del 2026-10-14 (r2, tras el reinicio)

**Equipo B** (OSHIN-LEGION). Línea base para el criterio p95 ≤ +5 % de los tramos T1 de ADR-118 y ADR-119.

## Condiciones

- Código: `feature/modelo-ng` en `4d376a6`, árbol `GPOS-B-carga`, Release ya compilado (`--no-build`).
- Instancia: `.\SQLEXPRESS` (SQL Server 2025 Express), sin bases `GPOS_TEST_*` sobrantes al empezar.
- Equipo recién reiniciado (arranque 05:38), plan de energía **Equilibrado** con los ajustes de máximo rendimiento del propietario; CPU a 2.900/2.900 MHz al empezar y al terminar cada corrida; sin agentes ni compilaciones.
- Secuencia: 15 min de enfriamiento → t28-1 → 15 → t28-2 → 15 → t57-1 → 15 → t57-2. T-28 con `GPOST_B9_MINUTOS=3`, T-57 con `GPOST_B9_MUESTREO=1`.
- Horario: 05:41 a 07:25. Las cuatro corridas terminaron con código 0.
- Resultados completos y bitácora: `GPOS-B-carga/TestResults/Oficial-14oct-r2/` (solo en el equipo B).
- La primera tanda del día (`Oficial-14oct/`) queda anulada: mezcla los planes Energy Star y Equilibrado, y su t57-1 salió sin datos (la corrida terminó a las 05:36, dos minutos antes del reinicio).

## T-28 (ola 3, solo ventas)

| Medida | t28-1 | t28-2 | Meta |
|---|---|---|---|
| p95, 6 cajeros, 3 min | **31,8 ms** | **30,6 ms** | ≤ 52 ms |
| Ventas por segundo | 226,3 | 243,4 | — |
| p50 / p99 | 25,0 / 41,0 ms | 23,2 / 45,6 ms | — |
| p95, 12 cajeros | 57,7 ms | 54,6 ms | informativo |
| p95, 6 cajeros con la base crecida (~115-120 mil documentos) | 35,4 ms | 26,5 ms | informativo |
| `TR_Documento_Emision` por ejecución | 0,379 ms | 0,365 ms | < 0,55 ms |
| `TR_Documento_Credito` por ejecución | 0,064 ms | 0,061 ms | < 0,1 ms |
| Errores | ninguno | ninguno | 0 |

Frente a la línea base de 2019 Express (44,5 ms): entre −28 % y −31 %.

## T-57 (ola 4, ventas con compras, pagos y caja chica)

Metas provisionales firmadas el 2026-10-09 (`ebd121a`), vigentes hasta construir «el número al final de la transacción».

| Meta | t57-1 | t57-2 | Límite | Estado |
|---|---|---|---|---|
| (1) p95 de la venta, 6 cajeros con compras | 80,0 ms | 60,4 ms | ≤ 100 ms (alerta > 80) | cumple; t57-1 justo en el umbral de la alerta, sin pasarlo |
| p95 de la venta sin compras (diagnóstico) | 31,2 ms | 28,9 ms | — | referencia |
| Esperas de la venta en `inv.Existencia` (muestreo) | 0 | 0 | < 10 | cumple |
| (2) errores 1205, 6 y 12 cajeros (cliente y motor) | 0 | 0 | 0 | cumple |
| (3) conciliaciones (existencia, CxC, CxP, saldo a favor, bancos y demás) | 0 | 0 | 0 | cumple |
| (4) números, NCF B02/B11/B13 y cheques repetidos | 0 | 0 | 0 | cumple |
| (5a) compra de 20 líneas, p95 con 6 cajeros | 885,7 ms | 1.066,1 ms | ≤ 1.500 ms (alerta > 400) | cumple; alerta activa |
| (5a) compra de 20 líneas, p50 con 6 cajeros | 85,8 ms | 81,9 ms | ≤ 250 ms | cumple |
| compra de 20 líneas, p95 con 12 cajeros | 1.612,9 ms | 1.711,2 ms | informativo | — |
| (5b) compra con fecha anterior y 5.000 movimientos posteriores, p95 | 1.788,9 ms | 1.811,7 ms | ≤ 2.000 ms | cumple, con poco margen |
| (6) pago con 3 aplicaciones y retención, p95 (6 y 12 cajeros) | 46,0 ms | 56,5 ms | ≤ 100 ms | cumple |
| saldos de CxP negativos | 0 | 0 | 0 | cumple |

### Observaciones

- **Cuello de botella:** el muestreo de t57-1 (2.278 esperas) muestra sobre todo `LCK_M_U` en `num.Serie` (`FacturaPos` y `FacturaCxp`) y en `inv.ArticuloCosto`, con las compras como bloqueador. Es lo que debe aliviar «el número al final de la transacción».
- **Meta 5b:** queda con un margen de unos 200 ms bajo los 2 s, el más estrecho de la corrida. Se recomienda vigilarla en T1, que añade comprobaciones de lote y de existencias negativas en la misma ruta.
- **Con 12 cajeros,** `TR_Documento_Ola4` sube a 1,263 ms por ejecución (0,276 ms con 6). Es un dato informativo y no tiene meta propia.
- **Línea base para T1:** si se toma como referencia la peor de las dos corridas, el +5 % deja estos topes: T-28 p95 ≤ 33,4 ms (31,8 × 1,05) y venta de T-57 con compras p95 ≤ 84,0 ms (80,0 × 1,05). La venta de T-57 varía bastante entre corridas (60-80 ms), así que conviene comparar el promedio de dos corridas y no una sola.
