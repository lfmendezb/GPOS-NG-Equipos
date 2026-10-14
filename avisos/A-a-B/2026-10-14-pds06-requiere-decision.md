Para: B (para el propietario)
De: A
Fecha: 2026-10-14
Tipo: Hallazgo
Prioridad: Media
Repositorio y rama: GPOS-NG a/h11-p7-candado (e3d39235), PR 24
Estado: Abierto — requiere decisión del propietario

# PDS-06 del PR 24: 8.2 (5) cumple; el candado cuesta +0,040 ms por alta (tope +0,03)

Informe: `docs/calidad/2026-10-14-h11-pds06-rendimiento.md`. Prueba: `CandadoRestauracionRendimientoTests` (solo informa).

- **8.2 (5):** mediana 0,291 ms antes y 0,289 ms después, contra el tope de 0,55 ms. **Cumple.**
- **Microprueba de 1.000 altas de borrador, con y sin el disparador del candado, 3 corridas por 3 repeticiones:** el sobrecosto va de +0,037 a +0,042 ms por alta, con mediana **+0,040 ms**, contra el tope de +0,03 ms. **No cumple** (QA-PDS06-01, Media; riesgo ya previsto como R-D11).
- **Venta POS real:** el candado corre 2,75 veces por venta y cuesta unos **0,113 ms por venta**. Es el 0,5 % de una venta de unos 21 ms.
  - La estimación de §7.1.3 no contaba la marca `MotivoSinNcf`, un `UPDATE` de borrador que DD-10 no deja salir.

## Decisión que se pide (plan de reserva de §7.1.3, sin aplicar)
1. **Paso 1:** fundir la comprobación del `INSERT` en `TR_Documento_Nace`. Según QA (inferido), ahorra solo unos 0,006 a 0,011 ms por venta.
2. **Paso 2:** el propietario acepta el costo (unos 0,11 ms por venta), porque CR-01 está firmado.

**Recomendación técnica de A:** el paso 2. El costo es medible pero marginal frente a la venta completa, y el paso 1 no alcanza el tope por sí solo. La firma es del propietario. El PR 24 sigue sin unir y **A sigue con el resto de la cola**.
