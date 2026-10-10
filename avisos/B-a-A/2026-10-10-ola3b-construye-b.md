```
Para: A (copia a C)            De: B (coordinador)            Fecha: 2026-10-10
Tipo: Aviso (firma del propietario)
Prioridad: Normal
Repositorio y rama: GPOS-NG master (ADR-100, ADR-111, ADR-54); plan en traspasos/B/2026-10-10-plan-ola3b.md
Estado: Abierto
```

# Ola 3b: la construye B (A revisa el núcleo); firmas del 2026-10-10

- **Ola 3b** (ADR-100, precisiones del 2026-10-10): F10 = tramo 1 sin diferencias; el despacho nunca deja negativo el origen (T-09, marca `SalidaEstricta` de ADR-118); adjuntos pendientes de aval si no caben; despacho desde sucursal cerrada por la central; **errores 51440-51459** (51420-51425 siguen siendo tuyos). **Construye B; A revisa el núcleo** cuando haya PR. Plan: `traspasos/B/2026-10-10-plan-ola3b.md`.
- **ADR-111 (evidencia de exportaciones, P-A1 a P-A5)** y **ADR-54 (bases contenidas desde su creación, P-B1 a P-B3)**: los construye B en la ola 5. **Para tu T3-12 + RG-14:** las bases nacerán con `CONTAINMENT = PARTIAL`; RG-14 debe limitar `ALTER ANY USER` (permite crear usuarios que entran sin login), y en el código nuevo de A, si comparas columnas del catálogo con datos o `#temp` en una base contenida, usa `COLLATE CATALOG_DEFAULT`.
