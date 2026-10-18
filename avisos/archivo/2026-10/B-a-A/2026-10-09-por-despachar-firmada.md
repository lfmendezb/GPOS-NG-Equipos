```
Para: A            De: B (coordinador)            Fecha: 2026-10-09
Tipo: Decisión del propietario
Prioridad: Normal
Repositorio y rama: GPOS-NG b/verticales-diseno 2a3ace1
Estado: Abierto
```

# «Por despachar»: PF-01 a PF-06 firmadas según la recomendación

Hoja: `docs/decisiones/2026-10-09-hoja-firma-por-despachar-fecha-alcance.md` (rama `b/verticales-diseno`, `2a3ace1`). Firmada por el propietario el 2026-10-09, todo según recomendación:
- **PF-01:** entra en la entrega 1 en versión mínima, solo en la Estándar (Facturación Ágil) y en la factura de crédito del back-office.
- **PF-02:** anillo 1 (≈2,9 sp entre A y B); el anillo 2 solo si hay tiempo.
- **PF-03:** no cuenta para la meta del MVP (que se mide el 1-nov con 70 %, 7 de 10 flujos).
- **PF-04:** construye B en `b/por-despachar` después de unir la 3b; **ajustado al cambio de papeles: B une como coordinador y A revisa como apoyo**.
- **PF-05:** «Cerrar saldo sin entrega» (DP-2, OD-2) se aplaza hasta antes de que el primer saldo cumpla 90 días de uso real. Con PF-01 resuelve también OD-1.
- **PF-06:** 20-nov sin unir → sale el anillo 2; 1-dic sin el anillo 1 unido → la marca pasa a la entrega 2.
- **PF-Q1** (¿piloto con encargos desde el primer día?) sigue abierta; si es sí, PF-03 pasa a crítico.

**Para A (apoyo):** agendar el diseño del esquema de A-Q6 (≈0,2 sp, con revisión de B) y la `P` en el `CHECK` de `CK_LineaSaldo_Clase` dentro de la tanda UF-05; revisión de los archivos del núcleo cuando B abra el PR de `b/por-despachar`.
**B** registra la precisión de ADR-113 (fecha y alcance) y RPV-06 en master.
