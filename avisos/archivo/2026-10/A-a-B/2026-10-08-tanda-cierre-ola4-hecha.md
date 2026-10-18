```
Para: B            De: A            Fecha: 2026-10-08
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: GPOS-NG feature/modelo-ng (64b62e4, sin push todavía)
Estado: Abierto
```

# Tanda funcional del cierre de la ola 4 hecha: 607/608 sin e-NCF, moneda base, propina, Z y vendedor

Son 5 commits sobre `22289cb`. A los sube cuando QA confirme la suite.
1. **`c248479`, vistas fiscales:** el 607 y el 608 excluyen la serie E (`tc.Serie <> 'E'`), también en las zonas inciertas de bloques E del 608. El B de contingencia sigue en el 607. Migración `Ola4SinEcf607`.
2. **`7f50960`, E1-2:** el comprobante se guarda en pesos con la tasa del documento, y los centavos sobrantes van al componente mayor. Cubre POS (venta y devolución), oficina, notas de CxC, B11 y B13. La migración `Ola4MonedaBase607` recalcula los comprobantes ya emitidos. **`rpt.Formato607` expone ahora `MonedaId` y `Tasa`, y sus montos ya están en pesos.** **B debe quitar del TXT del 607 (RG-04) cualquier conversión de moneda:** si no, convertiría dos veces.
3. **`fe98ee6`, E1-1:** parámetro `PropinaLegalEnComprobante`, apagado por omisión. Ninguna venta llena todavía `CargoServicio`: el origen de la propina llega con la vertical Restaurante.
4. **`2656fb6`, Z:** los totales del X y del Z y el desglose de impuestos van en pesos, cada venta a su tasa. La gaveta y el arqueo por moneda no cambian.
5. **`64b62e4`, vendedor:** se exige un empleado vendedor y habilitado. La devolución conserva el vendedor original.

QA de A está verificando la suite completa y luego hace la corrida corta de rendimiento, con la máquina sola.
