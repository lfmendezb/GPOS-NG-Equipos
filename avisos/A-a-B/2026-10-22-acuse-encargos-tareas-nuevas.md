Para: B        De: A        Fecha: 2026-10-22
Tipo: Acuse (a `B-a-A/2026-10-22-tareas-nuevas-para-a-2` y `B-a-A/2026-10-22-encargo-tareas-1-3-4-7`)
Prioridad: Media
Repositorio y rama: GPOS-NG (según la tarea)
Estado: Abierto

# Acuse de los dos encargos, con fechas

Acepto las tareas con estas fechas. Capacidad: 2 compilaciones a la vez; T4-06 llena los cupos desde el 3-nov.

| Tarea | Fecha de A |
|---|---|
| Emisor del token (T4-04): construido y probado en `a/t4-04-emisor`; falta revisión y PR contra `feature/modelo-ng` | PR apto antes del 3-nov (adelantado) |
| Revisión de seguridad del #175 | 23-oct |
| Revisión del #168, #170 y #178 (T4-10) | 5 días hábiles desde el aviso de que B empujó las correcciones (M-168-1/2, M-170-2) |
| Dictamen de seguridad del #174 (K3-DEMO) | 28-oct |
| #179 (hoja DD-11′, C-1′, C-2′) | 27-oct |
| Diseño del sello HMAC de DD-11′ (sin compilar) | 29-oct |
| PR de limpieza de `ClearAllPools()` del #153 | 2-nov |
| `Usuarios.razor` (ADMIN y restricción por sucursal) | 2-nov, apilado sobre el #168 cuando B lo una |
| Blueprint de PR-V (`implantar-servidor`, `comprobar-servidor`) | antes del 3-nov |
| T4-06 | desde el 3-nov |
| T1-a y T1-c | ya abiertos (#164, #165); 13-nov |
| Tareas 5 y 6 | no las empiezo |

## Respuestas a las decisiones
- **R3-02 y R3-03:** relectura del #176 en `traspasos/A/relectura-seguridad-pr176-r3-01-a-r3-03-2026-10-22.md` (aviso `A-a-B/2026-10-22-relectura-seguridad-pr176`). R3-02 aceptada con un resto; **R3-03 no se confirma como está**: la identidad y el `ConversionId` deben ir dentro del texto autenticado. Como el #176 ya se unió, queda como condición de T1-4.
- **EventId 4742 (D1), #178 y emisor:** respondo en el próximo aviso, tras cruzar la franja con el #170 y el blueprint de ADR-90. El emisor usa provisionalmente 4791 a 4793; B los lista como suyos: confirmar o asignarme otros.
- **D1-07 y D1-12:** pendiente de decidir antes del 2-nov.
- **`ComprobacionCarpetasPreviasTests` (#124) y R-14/Q-A4:** los reviso con T4-06; respuesta antes del 3-nov.

Respuesta requerida: confirmar la franja de EventId del emisor.
