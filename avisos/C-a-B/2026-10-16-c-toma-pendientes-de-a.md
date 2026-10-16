```
Para: B y A        De: C            Fecha: 2026-10-16
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: GPOS-NG, ramas c/ desde feature/modelo-ng
Estado: Abierto — en construcción
```

# C toma los trabajos de A que no se han iniciado

**Decisión del propietario (2026-10-16, sesión de C):** «Toma las tareas que el equipo A aun no ha iniciado y procede con los trabajos».

**A, no empieces ninguna de estas tres.** Revisé `estado.md`, tus acuses y la lista de ramas `a/` en origin. Ninguna tiene rama ni commits.

| # | Trabajo | Origen | Rama de C |
|---|---|---|---|
| C-T1 | **Fase A de ADR-81**, segundo factor TOTP. Primero se pone al día el diseño de C del 10-oct (blueprint v3, pantallas v2 y P-81A-14) contra la punta de `feature/modelo-ng`: H-11, la licencia y lo que DL-01, DL-03 y DL-04 dicen de ADR-81. Después se construye por tandas | Encargo de B a A del 2026-10-14; «puedes empezar» del 2026-10-15 | `c/adr81-fase-a` |
| C-T2 | **Ajustes en cola del #41** (H-11 S-1/S-2), según el dictamen `A-a-B/2026-10-15-pr41-dictamenes`: <ul><li>prueba de que los trabajos usan su propio pool;</li><li>mensaje genérico en la Web y MAUI ante `ESTADO_CANDADO_NO_DISPONIBLE`;</li><li>fork y hora en el detalle de `AuditarRespaldo`;</li><li>guion de reverso P-9 en `database/sistema/reverso-h11-s2.sql`;</li><li>H11S-01;</li><li>normalizar las cadenas de EF y de la conexión directa</li></ul> | Cola de A desde el 15-oct | `c/h11-s2-ajustes` |
| C-T3 | **CP170 intermitente**: el aviso termina en el registro del servidor y no en el de la prueba. Es una observación Baja de pruebas | `B-a-A/2026-10-15-suite-oficial-prep-855ea392`; A lo había dejado sin tomar | `c/cp170` |

## Lo que C no toma
- **DL-22 y SEG-CORP-08 (#49):** A los tiene en curso.
- **SC08-01 y SC08-03:** esperan la decisión de B. Además, SC08-01 lleva una precisión de ADR-68 para firma.
- **El lote 2 de identidades y la licencia:** son de los desarrolladores L e I por DL-07.

## Cómo trabaja C
- Agentes con Opus, como máximo 2 compilando a la vez.
- Solo pruebas por clase; ninguna suite completa ni carga mientras otro agente pruebe.
- PR contra `feature/modelo-ng`, **sin unir**.
- Un aviso Entrega por cada pieza (regla 9).

**Posible cruce con A:** el #49 toca `AutorizacionesSupervisor`, y la fase A de ADR-81 toca el inicio de sesión y el SUPER. Si en el rediseño aparece un cruce, C lo avisa antes de construir.
