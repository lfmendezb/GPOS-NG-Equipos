```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Decisión del propietario
Prioridad: Alta
Repositorio y rama: GPOS-NG b/conector-admcloud-diseno (docs/decisiones/2026-10-08-respuestas-propietario-admcloud.md, puntos 13 y 16)
Estado: Abierto
```

# Opción por empresa: omitir el cálculo de costos cuando el ERP los lleva (capacidad del núcleo, de A)

Al diseñar el conector de AdmCloud, el propietario decidió el 2026-10-08:
1. **GPOS NG lleva su inventario de forma independiente. El ERP (AdmCloud o cualquier otro) puede llevar el suyo,** y que los dos kárdex difieran es lo esperado. Aplica a todos los ERP de terceros.
2. **Cuando el ERP lleva el costo, GPOS NG no maneja ningún costo.** Se habilita **una opción por empresa que omite el cálculo de costos** en GPOS NG, para no hacer un esfuerzo innecesario que afecta directamente el rendimiento del POS.

**Esto es del núcleo (INV), así que lo diseña y lo ubica A en su plan.** Lo que B ve, por inferencia:
- **Rendimiento:** con la opción activa no se recalcula el costo promedio, así que **no se toman las filas de `inv_Articulos` con `UPDLOCK`**, el último eslabón del orden de bloqueos de ADR-45. En la venta es una mejora directa.
- **Se siguen llevando las existencias** (cantidades). Solo se deja de valorizar.
- **Por revisar:**
  - valorización del kárdex y de las mermas;
  - costo en la línea de venta (`VenConfiguracion.cs:116`);
  - reportes de costo y utilidad (`rptc` de la ola 5) y el privilegio «Ver costos»;
  - cierre de período de inventario (ADR-69);
  - transferencias con costo solo en la central (ADR-31, DA-01 a DA-05);
  - conciliación de existencias;
  - costo de los ingredientes del restaurante (ADR-113).
- **Combinación con los modos del conector:** la opción solo cabe cuando el ERP lleva las existencias y el costo. Si el ERP no lleva existencias, el conector le manda el asiento de costo de ventas calculado desde el kárdex de GPOS NG, y eso necesita los costos.

B lo incorpora a la hoja de AdmCloud como dependencia del núcleo. A decide cuándo entra: en la entrega 1, si es barato, o después del corte.
