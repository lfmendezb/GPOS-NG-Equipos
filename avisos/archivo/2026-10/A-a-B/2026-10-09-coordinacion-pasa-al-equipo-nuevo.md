```
Para: B (y todos los equipos)      De: A (por decisión del propietario)      Fecha: 2026-10-09
Tipo: Decisión del propietario
Prioridad: Alta
Repositorio y rama: todos los proyectos
Estado: Abierto
```

# La coordinación pasa al equipo nuevo; la PC A pasa a ser el equipo de soporte

Palabras del propietario (2026-10-09):

> «En vista de que la luz se va de repente y este equipo no tiene soporte de UPS, entiendo prudente que la actividad principal se coordine a través del nuevo equipo en donde restauraré al Equipo B.»
> «Este pasa a ser el equipo de soporte.»
> «Las capacidades del nuevo equipo donde instalo al Equipo B son mucho más robustas.»

## Qué cambia
- **Coordina el equipo nuevo (Equipo B restaurado).** Desde su primera sesión, B asume lo que hacía A: une ramas a `feature/modelo-ng` y `master`, edita `CLAUDE.md` y el manifiesto de pruebas, mantiene los «Pendientes del propietario» de `estado.md` y publica `memoria/` y `agentes/` en el área común. Sustituye la nota de `2026-10-09-b-cambia-de-equipo.md` («hasta que lo decida, A sigue coordinando»): **ya está decidido**.
- **La PC A pasa a soporte.** Trabaja en ramas propias, sube y abre PR, y **no une** (salvo que el propietario indique otra cosa). Hace trabajos cortos con commit y push frecuentes, porque un apagón puede cortarla en cualquier momento. Las compilaciones completas, las suites largas y las cargas pesadas de SQL Server (T-57, carga de la ola 4) conviene que se hagan en el equipo nuevo.
- **Límite de agentes:** el de la PC B vieja (4, o 2 si varios compilan) **no se traslada** al equipo nuevo; hay que medirlo allí.
- **Aprobado por el propietario (2026-10-09):** A trabaja en ramas **`a/...`** y **conserva su rango de ADR 68-99** (libres hoy 79, 80 y 82 en adelante). B mantiene el 100-129.

## Lo que A deja en GitHub
- `feature/modelo-ng` = `59921ba` (K1 pasada 2 unida; suites 1.870/0, Web 448/448, MAUI 429/429). `master` con ADR-81 (`3a2d0bd`).
- **Subidas hoy por primera vez** (antes solo estaban en la PC A): `feature/mejoras-demo-ronda2` (`87b90f8`), `demo/2026-10-07` (`5ad4e78`) y `demo/2026-10-08` (`6f07a7f`): los 3 commits de las mejoras del demo, ronda 2 (segundo Guardar bajo los totales, datos del tablero en tabla, Enter = Buscar). No están unidos a `feature/modelo-ng` ni a `master`; el coordinador decide si se unen.
- Sin cambios locales pendientes en la PC A, salvo la carpeta `deploy/` de Backup Tool sin registrar (no se publica: puede contener claves; la revisa el propietario).

## Lo que hereda el coordinador (estaba a cargo de A)
- Acuse de la meta del MVP (60 % de los flujos de punta a punta) y llevar a firma la lista de flujos, la fecha y lo que se aplaza.
- Corridas oficiales de T-57 el 14-oct y decisión de la meta 1; cierre de la ola 4 (~15-oct); ADR-118/119 (T1, T2, T4); 3b (~22-oct) y commit de partida de `b/ola5`; integrar `rptsis` y `GPOS.Migracion`; búsqueda sin tildes; tanda de núcleo de caja (reimpresión y redondeo del vuelto); tanda 3 (equivalencias, ≈19 sp). El coordinador puede encargar a A cualquiera de ellas como trabajo de soporte.
- Avisos abiertos de A a B que siguen vigentes: `rpt-rptc-firmado` (privilegios «Ver datos personales» y «Ver cuadre de caja» antes de unir la ola 5), `uf03-ob03-aprobados`, `ux-firmado` (reimpresión y su diálogo, tanda de núcleo de caja), observaciones O-1 a O-3 de `k1-pasada2-unida`.

No requiere acuse más allá de confirmarlo en la sección de B de `estado.md` en la primera sesión del equipo nuevo.
