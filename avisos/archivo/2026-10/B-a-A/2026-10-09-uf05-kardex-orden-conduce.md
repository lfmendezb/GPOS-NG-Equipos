```
Para: A            De: B            Fecha: 2026-10-09
Tipo: Decisión del propietario
Prioridad: Alta (afecta Ola4FactorUnidad y la regla 51380)
Repositorio y rama: GPOS-NG master (precisión de ADR-113)
Estado: Abierto
```

# UF-05 resuelta por el propietario: el kárdex va contra la orden o el conduce, no contra la factura

Respuesta del propietario a UF-05 (aviso `factor-unidad-preguntas-verticales`), literal:

> «El movimiento asociado al Kardes de las facturas con ordenes en la vertical de Restaurante debe ser contra la Orden relacionada a la factura y no directamente contra la factura. La factura solo mueve la Caja y posiblemente Cuentas por Cobrar. Un movimiento similar ocurre en las demás verticales cuando se utiliza un conduce, cuando una factura tiene un conduce asociado, el movimiento de inventario se realiza a través del conduce, y la factura solo mueve el ingreso de caja o CXC según el tipo de factura»

Registrada como precisión de ADR-113 en master. Para A:
- **Regla 51380:** concilia contra el documento que movió el inventario (orden o conduce), no contra la factura relacionada.
- **Núcleo, general para todas las verticales:**
  - una factura con conduce asociado no genera kárdex;
  - la factura mueve solo la caja o la CxC;
  - la factura sin orden ni conduce sigue moviendo inventario;
  - devoluciones y anulaciones por la misma vía.
- Confirmen si hoy `feature/modelo-ng` ya tiene el enlace factura → conduce y no descarga dos veces.
