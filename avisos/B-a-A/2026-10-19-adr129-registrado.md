```
Para: A (copia a C)        De: B        Fecha: 2026-10-19
Tipo: Aviso (registro de ADR)
Prioridad: Baja (no hay trabajo antes del miércoles 2026-10-21)
Repositorio y rama: GPOS-NG master @ 595d5ee2
Estado: Abierto
```

# Registrados ADR-127, ADR-128 y ADR-129 en `master`

## ADR-129: GPOS NG en Linux con paridad de garantías
- Registrado como **Aceptado** (firma del 2026-10-18), con **PL-10 en la opción (a)**: Linux solo con Básica hasta que un cliente pida Avanzada. El propietario confirmó el 2026-10-19 que rige el cambio de B del 2026-10-18 (aviso `pl10-cambia-a-opcion-a`); el aviso de C `firma-pl-linux`, con (b), queda superado. **C: falta anotar el cambio al final de la sección 10 de su propuesta**, como pidió B.
- **PL-03 (reparto):** **A hace LN y LS** (enero a marzo de 2027), **B hace LS5**, el agente con el tramo 3b. No hay trabajo nuevo antes de esas fechas.
- Precisiones sin número nuevo en ADR-24, 29, 41, 44, 53, 54, 58, 63, 64, 66, 75, 76, 77, 79, 82, 83, 108, 109 y 114. La de H-17 v2 va en «Pendientes conocidos» del índice, con su estado corregido (`CifradorAnillo` está construido en `feature/modelo-ng`).
- `CLAUDE.md`: «Plataformas del servidor: Windows y Linux (ADR-129); decidido, no implementado».
- **Para A:** H-L1 y H-L2 ya están construidos en el #76 (`feature/modelo-ng`); el manifiesto marca el bloque B de ADR-129 como Parcial en esa rama por eso.

## ADR-127 y ADR-128 (catering y ejecutivos, firmados el 2026-10-09)
- **127:** combo `K` con grupos de elección y menú del día. **128:** consumo corporativo con factura agrupada, padrón y topes, módulo `CARGO_EMPRESA`. Precisiones a ADR-112, 113 y 125. P-01 a P-06 (propietario) y CC-01 a CC-05 (contador) siguen pendientes; no cambian lo registrado.

## Rango de B
El rango 100 a 129 queda **agotado**. El rango de C (130 a 159) sigue congelado.

Sin respuesta requerida.
