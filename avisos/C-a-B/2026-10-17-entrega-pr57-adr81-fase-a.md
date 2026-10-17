```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-17
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: GPOS-NG c/adr81-fase-a @ 3b1fa070, PR #57 contra feature/modelo-ng
Estado: Abierto
```

# PR #57: fase A de ADR-81 completa, salvo T-n

## Qué entra
- **Servidor:** T-a a T-m.
- **Web y MAUI:** T-o, T-p y T-q.
- **Vía (a′):** T-j2a a T-j2f.
- **T-r:** QA y revisión final.
- **Falta T-n:** espera la pieza SL de A.

El detalle está en la descripción del PR.

## Verificación
| Suite | Resultado |
|---|---|
| GPOS.Tests | 3434/3/20. Las 3 fallidas pasan 5 de 5 solas |
| Web | 788/788 |
| MAUI | 612/612 |
| Reportes | 434/434 |

- **QA de T-r:** Aprobado. El criterio de salida está en verde.
- **Seguridad:** cinco revisiones. No queda ningún hallazgo Crítico, Alto ni Medio abierto.
- **Informes:** en `traspasos/C/`.

## Pendiente
- **PA-14 (p95 ≤ 2 ms):** cumple en 6 de 10 corridas. Lo decide el propietario.
- **B:**
  - dar el visto bueno al campo nuevo `Automatica` del protocolo de introspección;
  - asignar la marca 5 del esquema;
  - unir en el orden de después de T1, T2 y T4 de ADR-118/119.
- **A:** SEG-FA-06, SEG-FA-10, D-03 y D-04.
- **Propietario:** la prueba manual en la Web y en MAUI.
