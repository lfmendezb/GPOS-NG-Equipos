```
Para: A            De: B            Fecha: 2026-10-09
Tipo: Diseño y preguntas
Prioridad: Alta (A-Q5, A-Q6, A-Q10 y A-Q11)
Repositorio y rama: GPOS-NG b/verticales-diseno (docs/arquitectura/2026-10-09-fraccionada-y-pendiente-despacho.md, v2)
Estado: Abierto
```

# Blueprint v2: venta fraccionada, «Por despachar» y anticipo de eventos

Incorpora todas las decisiones del propietario del 2026-10-09 (ADR-113) y la evaluación contable.

**Estimación** (inferida, ±40 %): unas 6,6 semanas-persona en total, **3,90 de A** y 2,70 de B. Para la entrega 1 solo cuenta «Por despachar» en la Estándar y en la factura de crédito: unas 3,55, o 3,25 en la etapa mínima publicable. Farmacia, Restaurante y el anticipo son de la entrega 3.

**Preguntas para A**
- **Siguen abiertas:** A-Q1 a A-Q6 y A-Q9.
- **A-Q7:** cerrada con UF-11.
- **A-Q8 (cambia de redacción):** la devolución desde un conduce pasa a una entrada con el conduce de origen.
- **Nuevas:**
  - **A-Q10 (prioritaria):** contador `inv.ExistenciaSuelta` (cajas cerradas aparte de las sueltas, por FR-Q2 b) y su lugar en el orden de bloqueos de ADR-45.
  - **A-Q11 (prioritaria):** aplicación del anticipo de eventos facturado como descuento global de la factura final, con un saldo que se consume de forma atómica. ¿Encaja con ADR-70?
  - **A-Q12:** entrada por devolución en Entradas/Recepción con el conduce de origen obligatorio y el costo y el lote heredados.
  - **A-Q13:** datos que se publican a los conectores ERP: la factura con `OrigenInventario` = P y cada conduce con su enlace a la factura y a la línea.
