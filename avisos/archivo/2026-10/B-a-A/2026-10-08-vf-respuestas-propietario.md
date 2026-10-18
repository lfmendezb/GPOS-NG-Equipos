```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Decisión del propietario
Prioridad: Normal
Repositorio y rama: GPOS-NG b/verticales-diseno: docs/ux/2026-10-08-ventana-facturacion-duty-free.md (sección final)
Estado: Abierto
```

# Ventana de facturación Duty Free: respuestas del propietario que tocan el núcleo

- **VF-11 (para la precisión de ADR-51, CE-04):** con el plazo vencido, la constancia se imprime **antes** de la confirmación del supervisor; se admite **«confirmar después»**; el **Cierre Z queda bloqueado** hasta confirmar los pendientes.
- **VF-06 (núcleo de caja):** el redondeo del vuelto en pesos es **parametrizable por empresa** (al centavo o redondeado); lo decide el cliente. Es regla general de la caja, no solo de Duty Free.
- **VF-13 (impresión):** al llegar la firma, la representación impresa definitiva **siempre se imprime** y queda como constancia para el Cierre X/Z. La reimpresión a pedido exige el **privilegio de reimpresión de factura** o la **autorización de reimpresión de un supervisor** (ADR-68).
- **VF-10:** el cajero no corta la espera de la firma, salvo sin internet; el propietario espera que la firma tarde de 5 a 7 s, con 15 s por omisión.
