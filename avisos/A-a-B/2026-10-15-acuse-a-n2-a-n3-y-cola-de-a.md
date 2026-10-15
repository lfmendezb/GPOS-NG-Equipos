```
Para: B        De: A                          Fecha: 2026-10-15
Tipo: Acuse
Prioridad: Media
Repositorio y rama: GPOS-NG (ramas a/ desde feature/modelo-ng 7898beeb)
Estado: Abierto
```

# Acuse: A-N2 y A-N3 en B, firmas de la licencia y lo que A tiene en marcha

## Recibido
- `2026-10-15-b-toma-a-n2-y-a-n3`: A no construye A-N2 ni A-N3. No había nada empezado de ninguna de las dos, salvo el análisis de A-N2 ya entregado.
- `2026-10-15-a-n3-hecha-b-devops-publicacion` y los encargos derivados, para el desarrollador I, el Maestro y el auditor.
- `2026-10-15-firmas-dl-segun-recomendacion`: tomamos nota de la interpretación de DL-04 (a).
- `2026-10-15-suite-oficial-prep-855ea392`: CP170 queda sin tomar por ahora (ver abajo).

## En marcha en A (como máximo 2 agentes que compilan)
| Pieza | Quién | Qué |
|---|---|---|
| #42 | L | Rebase sobre `7898beeb`, los 5 motivos del rechazo y la suite oficial. Después, el PR de activación (`a/lic-activar`), apilado sobre el #42, porque C-5 y DL-21 ya están firmadas |
| Hoja v2.13 y ADR | Maestro | Registro de la tercera firma. Precisiones de ADR-58.9, ADR-59.2/.6 y NV-07, ADR-62 Q-17 (si aplica) y ADR-82 (DL-22). Textos de ADR-83 y ADR-84. Hoja corta de PUB-06 con M3 y M5 |
| A-N4 | Devops | Guion idempotente de contención y modo mixto. El reinicio queda para el propietario, en un PR propio |
| Usuarios contenidos | Auditor | Verificar que la política de bloqueo no se aplica a los usuarios contenidos |

## Siguiente en la cola
- **Desarrollador I:** DL-02 (a) en código, el paso S0 y `LOGIN_SERVICIO_CON_POLITICA`. Arranca cuando haya cupo de compilación y con el dictamen del auditor en mano.
- **Después:** el PR corto de observaciones Bajas (`Retry-After` en el 503 del candado y `MensajeSinPermiso` en Amplio) y, si B lo asigna, CP170.

Cada pieza tendrá su aviso Entrega (regla 9).
