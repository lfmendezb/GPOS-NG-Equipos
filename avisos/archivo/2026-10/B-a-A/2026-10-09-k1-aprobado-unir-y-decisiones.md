```
Para: A            De: B            Fecha: 2026-10-09
Tipo: Decisión del propietario y solicitud
Prioridad: Alta
Repositorio y rama: GPOS-NG b/kds-k1 (cc26657, en origin); master (cd9b9fa)
Estado: Abierto
```

# El propietario aprueba unir K1; decisiones sobre el conteo, «Por despachar» y anticipos

## 1. K1: unión aprobada por el propietario (2026-10-09, «Aprobado»)
- **Pedido a A:** unir `b/kds-k1` (`cc26657`) como prefieran: primero a `feature/modelo-ng` y luego a `master` con su flujo habitual.
- **Estado de la rama:**
  - SD-01 y `Propiedad` revisados por su auditor;
  - K1-01 y K1-03 corregidos y verificados;
  - V-01 a V-07 cerrados.
- **Suite:** con el filtro oficial debería dar 0 fallos; las 6 que veíamos son las de `Transicion=Ola5|Defecto`.
- **La rama nace de `2078a08`.** Si quieren, B la rebasa sobre `472d078` antes de unir; avísennos.
- **Después de unir, sigue de A:** la acción previa de ADR-77 punto 3 (la estación solo existe en el MSI de desarrollo), la cola de ADR-114 con el filtro SD-08 y V-08.

## 2. Conteo de cajas y sueltas (precisión de su UX firmada)
- El propietario eligió la **opción (a)**: en los artículos **fraccionables** de Farmacia, el conteo físico registra **por separado las cajas cerradas y las sueltas**.
- Es una precisión de UX-1 a UX-11 («no se guarda el desglose cajas + sueltas») solo para esos artículos; para el resto rige su UX.
- Es coherente con A-Q10 (columna `Sueltas`). Está en ADR-113 (`cd9b9fa`).

## 3. Otras decisiones registradas en ADR-113
- **FR-Q6, no:** un controlado no se dispensa con otra presentación.
- **FR-Q7, sí:** contador de sueltas.
- **PD-Q11, sí:** anular un conduce de despacho, con motivo y si no tiene entradas por devolución enlazadas.
- **PD-Q12:** el anticipo facturado vale solo en el Restaurante.
- **CQ-1:** el anticipo lleva su propina proporcional.
- **CQ-4:** «Cerrar anticipo sin evento».
- **UXP-01:** «Venta por Despachar» en el Restaurante, como venta POS sin cuenta.

## 4. AdmCloud: `ImpactStock` confirmado
El sincronizador en producción (`IGpostAC`) envía `ImpactStock` en el alta de facturas, despachos y recibos. AC-39 queda respondida y el respaldo F-1 retirado. Los estados del firmado de AdmCloud, según Fortech (2024-08-19), son 1 Aceptado, 2 En espera, 5 Rechazado y 6 Error; solo se consulta con 2.
