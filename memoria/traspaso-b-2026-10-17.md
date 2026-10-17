---
name: traspaso-b-2026-10-17
description: "LEER PRIMERO — cambio de sesión de B (2026-10-17): traspasos/B/2026-10-17-traspaso-B-cambio-de-sesion.md; T6 cuarta tanda por analizar"
metadata:
  node_type: memory
  type: project
  originSessionId: f0ef3310-0500-40cc-9e4f-8b69aa2f95ef
  modified: 2026-10-17T12:58:16.504Z
---

El 2026-10-17 la sesión de B en LFMB se cerró por contexto lleno. El traspaso completo está en el área común: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\B\2026-10-17-traspaso-B-cambio-de-sesion.md`. Sustituye a [[traspaso-b-2026-10-15]].

**Estado clave:**
- `feature/modelo-ng` en `e80f4654`, `master` en `3ab799b3` y `b/prep-27oct` en `c01df683`. La preparación lleva T1, la 3b, A-N2 completo, R-02 con su ajuste, `KardexCosto` y `UnidadesArticulos`.
- **La cuarta tanda de T6** (`Solucion GPOS NG\Medicion-T6-r4.ps1`, lanzada el 2026-10-17 a las 06:52, unas 4,5 h) deja sus salidas en `GPOS-B-prep27\TestResults\T6-r4-20261017-0652\`.
  - Lo primero de la sesión nueva es juntarla con la tanda con R-02, para tener 5 por lado en T-28 y T-57.
  - Antes: N6-02 0,835 (resuelto), T-28 1,133 y T-57 1,053, con dispersión. T-28 tiene un «modo lento» sin causa identificada.
- **El 27-oct** se une la preparación si T6 queda verde. Después, en este orden: #52+#55, #51, #45 y #48 (decisión del propietario).

**Why:** que la sesión nueva no repita trabajo ni pierda decisiones.

**How to apply:**
1. Al abrir, en la carpeta `GPOS NG`, lee el traspaso, `estado.md` y los avisos.
2. Analiza la cuarta tanda con los criterios de la §2 del traspaso.
3. Sigue la regla de marcas ([[marcas-migraciones-orden-de-union]]).

**Actualización (2026-10-17, 11:35): cuarta tanda ya analizada.** Con 5 corridas por lado:
- N6-02 0,945, T-57 sin compras 1,038, con compras 1,017 y 5b 0,447: cumplen.
- **T-28 1,110: no cumple** (bimodal; frente a la oficial sí cumple).
- Hallazgo nuevo de 8.2 (6): la comprobación de impuestos (`ventas.VentaImpuesto` con `OUTER APPLY`) recorre `VentaLineaImpuesto` en 1 de 5 corridas.

Siguiente paso: arreglar ese plan, diagnosticar el modo lento y que el propietario decida (repetir T-28 o aceptarlo por escrito) antes del 27-oct.
