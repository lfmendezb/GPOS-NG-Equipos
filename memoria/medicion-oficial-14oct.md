---
name: medicion-oficial-14oct
description: "Medición oficial T-28/T-57 del 2026-10-14 (r2, tras el reinicio): todas las metas en verde; línea base para el +5 % de T1"
metadata:
  type: project
---

Medición oficial r2 del 2026-10-14 (05:41-07:25), `feature/modelo-ng` 4d376a6, árbol `GPOS-B-carga`, `.\SQLEXPRESS`, plan Equilibrado tras el reinicio. Resultados en `GPOS-B-carga/TestResults/Oficial-14oct-r2/`; informe publicado en el área común `traspasos/B/2026-10-14-medicion-oficial-t28-t57.md` (59b1984). La tanda `Oficial-14oct/` (primera) queda anulada.

- T-28 p95: 31,8 y 30,6 ms (meta ≤ 52).
- T-57 (metas provisionales del 2026-10-09): venta 80,0 y 60,4 ms (≤ 100; t57-1 en el umbral de alerta); compra 20 líneas p95 885,7 y 1.066,1 (≤ 1.500, alerta activa); fecha anterior 1.788,9 y 1.811,7 (≤ 2.000, margen estrecho); pago 46,0 y 56,5; 1205, conciliaciones y repetidos en 0.
- Topes +5 % para T1 (peor corrida): T-28 ≤ 33,4 ms; venta T-57 ≤ 84,0 ms; comparar promedio de dos corridas.

Relacionado: [[valores-terceros-configurables]] (T1), [[numero-al-final-del-guardado]], [[mvp-fecha-medicion]].
