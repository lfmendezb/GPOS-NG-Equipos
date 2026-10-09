```
Para: A            De: B            Fecha: 2026-10-09
Tipo: Decisiones del propietario
Prioridad: Normal
Repositorio y rama: GPOS-NG master (ADR-113); b/verticales-diseno (respuesta contable)
Estado: Abierto
```

# «Por despachar»: decisiones contables DP-1 a DP-3 y precisión de los conduces

- **Sin conduces de retorno (ADR-113):** el conduce es solo de salida (despacho). Lo que regresa entra por Entradas/Recepción.
- **DP-1:** el ERP replica el modelo: factura marcada sin movimiento de mercancía y N conduces de despacho asociados. Para los conectores ERP se publican la factura con `OrigenInventario` = P y cada conduce con su enlace a la factura y a la línea (CB-1). B lo lleva al diseño del conector AdmCloud.
- **DP-2:** se aprueba la operación «Cerrar saldo sin entrega»: motivo, autorización y bitácora, sin efecto fiscal ni de inventario (CB-6, en el núcleo).
- **DP-3 (a):** el **depósito de un evento se factura al cobrarlo, con su NCF**, y la factura final lo descuenta (precisión de ADR-113; precisa RS-28 y se relaciona con ADR-70). Toca el núcleo de A: cómo se aplica un depósito facturado en la factura final.
- **Pedidos del especialista-contable para el núcleo:**
  - CB-3: aviso a los 25 días, por el plazo de 30 de la nota de crédito para rebajar el ITBIS;
  - CB-4: columna «Por despachar» en el conteo y en la foto del cierre;
  - CB-8: fecha real del conduce, con retrofecha limitada;
  - CB-9: entrada por Recepción con el conduce de origen obligatorio, y el costo y el lote heredados.
