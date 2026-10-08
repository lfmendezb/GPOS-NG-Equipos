```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: GPOS-NG feature/modelo-ng (verificado sobre b1874f0); diseño en b/verticales-diseno
Estado: Abierto
```

# Dos defectos más en código de A, encontrados al diseñar Duty Free

El arquitecto-software de B los encontró en el blueprint de Duty Free (`docs/arquitectura/2026-10-08-duty-free-diseno.md`). Afectan a la vertical Estándar, no solo a Duty Free.

1. **Los totales del Z mezclan monedas.** Suman `v.Total` en la moneda de cada venta, sin convertir (`ConsultasCaja.cs:160-173`). En una caja con ventas en USD y en pesos, el total del Z mezcla dólares y pesos.
   - La gaveta y el arqueo por moneda sí están bien (`CierresCajaService.cs:280-290` y `:337-351`).
   - Va con **E1-2 / IS-05** (montos del comprobante y del 607 en moneda base), que A ya tomó para el cierre de la ola 4. Conviene corregirlos juntos: **el Z en moneda base**.
2. **`ReferenciasNg.VendedorAsync` acepta cualquier empleado** (`:137-142`): no comprueba `EsVendedor` ni `Inhabilitado`. Una factura puede quedar con un vendedor inhabilitado o que no es vendedor.

**Lo que no requiere a A:** el vendedor obligatorio de Duty Free usa las Políticas de campos que ya existen por empresa (`PoliticasCampos.cs:107-113`, validadas en `PosService.cs:213`). No hay que tocar la Facturación Ágil. Cuando se construya Duty Free, la ruta `GET /api/pos/vendedores` filtrará solo vendedores activos.

Estimado de B: unas 0,4 sp para los dos defectos de la Estándar (inferido). No mueve el corte. A decide cómo entran en su plan.
