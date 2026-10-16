```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-16
Tipo: Entrega
Prioridad: Normal
Repositorio y rama: GPOS-NG c/h11-s2-ajustes @ 2c6251f4, PR #51 contra feature/modelo-ng
Estado: Abierto
```

# C-T2 entregado: ajustes del #41 (PR #51)

Están los seis ajustes del dictamen `A-a-B/2026-10-15-pr41-dictamenes`, en 3 commits. El detalle de cada uno está en el PR #51.

## Qué se hizo
1. Prueba de que los trabajos usan su propio pool.
2. Texto genérico ante `ESTADO_CANDADO_NO_DISPONIBLE` en la Web y en MAUI.
3. Fork y hora en `AuditarRespaldo`.
4. Guion de reverso P-9: `database/sistema/reverso-h11-s2.sql`.
5. H11S-01: solo una apertura apta pasa a 503.
6. Una sola cadena para EF y para la conexión directa, con `Application Name = GPOS.Api`.

## Verificación
Solo las clases afectadas. Sin fallas:

| Proyecto | Correctas | Omitidas |
|---|---|---|
| GPOS.Tests (primera corrida) | 36 | 0 |
| GPOS.Tests (segunda corrida) | 247 | 2, que ya existían |
| Web | 25 | 0 |
| MAUI | 34 | 0 |

La compilación no tiene advertencias nuevas. Las corridas se hicieron en OSHIN-LEGION.

## Puntos que B debe mirar al validar
- **El reverso P-9 baja la marca `GPOS.EsquemaSistema` de 3 a 2.** Sigue la condición (c) del arquitecto, aunque el diseño de datos decía que no se bajaba.
  - **Cruce con la fase A de ADR-81:** la fase A sube la marca a 4.
  - El guion se detiene si la marca es mayor que 3, así que no hay daño.
  - Cuando se una ADR-81, el reverso P-9 solo será aplicable antes de esa unión.
- **`sys.dm_exec_sessions`:** las conexiones de la API dejan de llamarse `EFCore/…` y pasan a `GPOS.Api`. Nada del código filtra por ese nombre.

## Pendiente
- **Suite oficial:** la corre B al validar.
- **Resto de H11S-01:** registrar como error el 503 repetido N veces. Queda sin dueño; propongo que lo decida el arquitecto o el auditor de A.
