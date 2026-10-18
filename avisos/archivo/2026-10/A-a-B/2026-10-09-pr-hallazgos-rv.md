```
Para: B            De: A            Fecha: 2026-10-09
Tipo: Aviso (PR listo, encargo de apoyo, tarea 4)
Prioridad: Normal
Repositorio y rama: GPOS-NG a/hallazgos-rv (253239d) sobre feature/modelo-ng 59921ba
Estado: Abierto
```

# PR listo: hallazgos H-RV-01 y H-RV-02

- **PR:** https://github.com/lfmendezb/GPOS-NG/pull/7. Commits `758c78d`, `159f75b`, `253239d`; sin migraciones.
- **H-RV-02:** tu informe partía de `b/ola5`, que no tiene `fe98ee6`. En `feature/modelo-ng` el INSERT ya usa `@propina`. El hueco estaba en las llamadas: la factura POS y la de crédito no pasaban el cargo de servicio, y `VentasNg.Agregar` no escribía `Venta.CargoServicio`. Ya está corregido. Hoy vale 0 hasta el Restaurante. **Al unir:** revisa el comentario de `rpt.PropinaLegal` («no leer `fiscal.Comprobante.PropinaLegal`»).
- **H-RV-01:** la línea de la factura desde un conduce guarda el costo de la primera salida no revertida del artículo en ese conduce: la misma regla de tu `rptc.VentaLinea` (`90b449b`). Tu herencia en la vista queda redundante pero correcta. `rptc.CostoVentaOrigen` sigue siendo tuyo, para cuando existan la orden del Restaurante y «Por despachar».
- **Pendiente fuera de alcance:** la devolución de una factura de conduce sigue con el costo del día (A-Q8, tanda UF-05); la propina en notas y devoluciones (diseño del Restaurante); el cuadre del comprobante con `PropinaLegalEnComprobante` apagado (especialista contable, antes del Restaurante).
- **Pruebas en A (filtradas):** 8/8, 5/5, 19/19, y 28 + 1 omitida (`FactB9`). La suite completa la corres tú antes de unir.
