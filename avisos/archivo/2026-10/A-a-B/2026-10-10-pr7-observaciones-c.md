```
Para: B            De: A            Fecha: 2026-10-10
Tipo: Aviso (PR listo) e información
Prioridad: Normal
Repositorio y rama: GPOS-NG a/hallazgos-rv (5d21c85) sobre feature/modelo-ng 97fde26
Estado: Abierto
```

# PR #7: observaciones de C atendidas, y 7 fallas en 97fde26 vistas desde A

**PR #7** (https://github.com/lfmendezb/GPOS-NG/pull/7):
- **C7-01:** el costo de la línea de la factura es el **promedio ponderado de todas las salidas del conduce**: `ROUND(SUM(-Cantidad*CostoUnitario)/SUM(-Cantidad), 6)`, con `MovimientoRevertidoId IS NULL`. Hay una prueba que lo reproducía (40 en lugar de 57,142857).
- **También corregidos:** C7-02 y C7-04.
- **C7-03:** queda para el diseño del Restaurante, como recomienda C.
- **Pruebas en A:** filtradas 128/128. Web 462/462 y MAUI 432/432.

**Pendiente tuyo:**
- **`rptc.VentaLinea` con la misma fórmula**, convirtiendo a una escala suficiente antes de dividir, para que las cifras coincidan;
- llevar al propietario la regla del promedio ponderado como **precisión de RPV-02 y UF-05**.

**Información: 7 fallas sobre `97fde26` sin cambios de A.** Las vio una corrida casi completa de GPOS.Tests en la PC A, contra `.\SQLEXPRESS`. Puede ser el entorno, porque tu suite oficial dio 1.937/1.938:
- `F1_D_MVP_01`: es esperable, porque D-MVP-01 llega con el PR #10. Revisa si en la suite oficial se excluye por `Transicion=Defecto`.
- `BusquedaNumeroTests.C7_las_tres_listas…`: los parámetros `desde`/`hasta` van como `nvarchar` en la lista de ventas POS, contra ADR-50.
- `SucursalOrigenTests.Ventas_por_sucursal…` y `DrillDownTests`: «El almacén PRINCIPAL es de la sucursal PRINCIPAL…».
- `ReportesTests.Filtra_antes…` y `ReportesTests.Exporta_a_los_seis…`: llegan vacías o en 0.
- `EsquemaPendienteAccesoTests`: `ESQUEMA_PENDIENTE` frente a `VERSION_ESQUEMA`, ya conocida.

Con esto, los PR #6, #7 y #9 tienen atendidas las observaciones de C. A queda sin agentes activos.
