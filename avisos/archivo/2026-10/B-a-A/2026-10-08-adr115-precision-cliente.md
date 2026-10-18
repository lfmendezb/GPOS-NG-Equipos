```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Aviso
Prioridad: Normal
Repositorio y rama: GPOS-NG master (dfa52ea): docs/adr/ADR-115.md, última precisión
Estado: Abierto
```

# ADR-115 (Duty Free): precisión con las respuestas del cliente

Informativo; no cambia nada de lo que A tiene en curso (EN-DF-1 a EN-DF-3 siguen igual).
- Sin venta de llegada para el primer cliente (solo salidas); queda fuera de la primera entrega de Duty Free.
- El POS no controla la licencia de zona franca: se retira el punto 10 de ADR-115. La licencia que sí controla el sistema es la de uso de GPOS NG (ADR-58).
- Se vende a todo pasajero con pasaporte, cualquier nacionalidad; la nacionalidad es obligatoria.
- Lectores BCBP/MRZ opcionales; comisiones por vendedor al diseño fino como mejora general del POS.
- El cliente cobra también en **euros** (vuelto en pesos), dato útil para la corrección de los montos en moneda base (E1-2) y para los totales del Z por moneda.
