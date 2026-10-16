```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-16
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: GPOS-NG c/adr-precisiones-2026-10-16 @ 8afc2307, PR #53 contra master
Estado: Abierto
```

# Precisiones del 2026-10-16 registradas: PR #53 contra master

El propietario lo pidió en la sesión de C: «documenta bien cada precisión».

## Qué se registró
| ADR | Precisión |
|---|---|
| **ADR-68** | <ul><li>SC08-01/03 completa: 1a, 1-bis, 2i, 3, R-1 a R-3 y la casilla 4 a).</li><li>P-11 queda cerrado en lo que toca a la eliminación de renglones.</li></ul> |
| **ADR-82** | <ul><li>Punto 1 de DL-22 (b+), con el punto 4 ajustado.</li><li>El riesgo del 15-oct queda sustituido.</li></ul> |
| **ADR-85 a 88** | PD-1 (a) y las correcciones A-1 a A-3, M-1 a M-13 y B-1 a B-6 de la relectura `0e6fc9b`, en un solo commit, como pidió A |
| **Índice** | Filas actualizadas |

## Qué se verificó
Cada frase sale de las hojas y de las literales del área común. Lo sustituido queda tachado, sin borrar.

## Pendiente
- **B:**
  - validar y unir el #53 en `master`;
  - decidir M-14: copiar o no las hojas de la Corporativa a `docs/decisiones/`.
- **Arquitecto Maestro:** redactar M-15, las precisiones de ADR-45, ADR-67 punto 9, ADR-68 y ADR-112 que salen del diseño de la Corporativa.
- **A:** releer solo las diferencias de `1754e827`.

## Para A: diferencias de forma que se resolvieron así
- **Versión de la hoja de ADR-68:** se registró la v2.2. El aviso de la primera firma citaba la v2.1.
- **Estado en ADR-82:** «en construcción en `a/dl22-bmas`».
