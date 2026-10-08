---
name: reportes-fiscales-aplazados
description: Decisión del propietario 2026-10-08: se aplazan los reportes fiscales (606, 607, 608, apoyos IT-1/IR-17); los tienen los ERP; el 606, que es el único que hoy se usa, también queda aplazado
metadata:
  type: project
---

El 2026-10-08 el propietario aplazó los **reportes fiscales** a una etapa posterior al corte de la entrega 1: archivos 606, 607 y 608, apoyos del IT-1 y del IR-17, pruebas de cuadre fiscal y, en Duty Free, el RZC-01 y el detalle a la DGII. Precisión registrada en ADR-111 (`d87040b` en `master`).

**Why:** «todos tienen su par en los sistemas ERP»; con el e-CF, el 607 y el 608 no llevan e-NCF y hoy solo se trabaja con el 606, que el ERP también genera. El propietario cree posible que en 2027 el 606 y el 607 sean inútiles. Aplica [[prioridad-ventas-inventario]].

**How to apply:**
- No invertir en formatos fiscales hasta la etapa fiscal; lo que ya existe en el código (p. ej. `rpt.Formato607` con H-R01) se conserva sin más trabajo.
- **No se aplaza** lo que es parte de la venta: emisión con NCF y e-CF, secuencias, Z y cierre de caja, montos del comprobante en moneda base (E1-2), reportes de ventas e inventario, evidencia de exportaciones y `rptexportar`. Las compras, CxP y retenciones se siguen registrando; solo el archivo 606 se aplaza (confirmado por el propietario).
- La etapa fiscal empieza por verificar con la DGII qué formatos siguen vigentes.
- Riesgo: un cliente sin ERP necesitaría los formatos de otra fuente; antes de implantarlo, reabrir la etapa fiscal.

Relacionado: [[ecf-no-se-anula]], [[contabilidad-ligera-erp-externo]].
