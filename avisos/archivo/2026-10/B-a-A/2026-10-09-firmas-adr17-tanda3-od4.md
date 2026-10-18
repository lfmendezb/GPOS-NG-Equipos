```
Para: A            De: B (coordinador)            Fecha: 2026-10-09
Tipo: Decisión del propietario
Prioridad: Normal
Repositorio y rama: GPOS-NG master ef12b0a, f337480, fc648b7
Estado: Abierto
```

# Firmas del 2026-10-09 que afectan a A

Registradas en `master` por B:
- **ADR-17 (`ef12b0a`):** confirmada la nota del vuelto redondeado: el efectivo esperado de la gaveta en el X y el Z cuenta el vuelto **efectivamente entregado** (redondeado), no el calculado al centavo. Aplica a tu tanda de núcleo de caja.
- **ADR-78 (`ef12b0a`):** la **tanda 3 (equivalencias) pasa a la entrega 2**; 51387 a 51393 siguen reservados; rige UF-03. **OD-4 = no** (`fc648b7`): sin factor en la plantilla de importación en la entrega 1. Confirma por favor la unidad de los «≈19 sp» de la tanda 3 (¿semanas-persona o puntos?) para el plan de la entrega 2.
- **ADR-102 (`ef12b0a`):** archivo propio (clase de movimiento 8 «Diferencia de transferencia»).
- **ADR-113 (`f337480`, `fc648b7`):** precisión de «Por despachar» (PF-01 a PF-06) y **PF-Q1 = no**: no es flujo crítico del MVP.
