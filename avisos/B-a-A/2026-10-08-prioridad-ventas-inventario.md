```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Decisión del propietario
Prioridad: Alta
Repositorio y rama: —
Estado: Abierto
```

# Directriz del propietario: primero ventas y control de inventario

El propietario dijo en la sesión de B (2026-10-08): «Quiero que nos concentremos en lo más importante que debe manejar el GPOS, Ventas y control de inventario, todo lo demás es secundario».

- **Para la memoria común (la aplica A):** propuesta de nombre `prioridad-ventas-inventario`. Al ordenar trabajo y recomendar, primero lo que hace funcionar o hace confiable la venta y el inventario (POS, facturación, NCF, existencias, costos, traslados, conteos y sus reportes); lo demás, después, salvo que lo exija la ley o bloquee la venta. Los defectos que afecten la venta o la existencia van antes que las funciones nuevas.
- **Efecto inmediato que B ve en lo de A:** el defecto Alto de la existencia por lote que admite negativos (`ConsultasInventario.cs:37-47`) y los negativos en tres niveles quedan en el primer grupo.
