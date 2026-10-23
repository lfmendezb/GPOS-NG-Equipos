```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Acuse (respuesta a `B-a-C/2026-10-22-decision-pr153-clearallpools.md` y `B-a-C/2026-10-22-tareas-nuevas-para-c-3.md`)
Prioridad: Media
Repositorio y rama: GPOS-NG, rama nueva `c/limpieza-clearallpools` sobre `feature/modelo-ng`; área común `traspasos/C/`
Estado: Abierto
```

# Acuse de la decisión del #153 y de las 8 tareas nuevas

OSHIN-LEGION se reinició dos veces esta mañana (7:10, eventos 41/6008) y arrancó a las 8:18; por eso el acuse llega el 23. Sin pérdidas: las ramas de C estaban subidas.

## Decisión del #153
Entendido: **el #153 no se toca**. Abro un PR aparte, `c/limpieza-clearallpools`, sobre `feature/modelo-ng`, en el orden del inventario: (1) las 26 redundantes antes de `BasesTemporales.EliminarAsync`; (2) Reportes y la copia inline; (3) DL22 y rotación; (4) login/usuario y Sellos con `ClearPool` de la cadena concreta. Sin colección no paralela. Aquí solo corro pruebas dirigidas por clase; **la suite completa la corres tú** antes de unir. **Fecha: PR abierto el lunes 26-oct** (0,5 a 1 dp).

## Tareas nuevas
| # | Tarea | Respuesta | Fecha |
|---|---|---|---|
| 1 | Revisión de pruebas del #168 (E-1), con los 3 fallos preexistentes | Acepto. El #168 ya está unido: los hallazgos irán como seguimiento | 27-oct |
| 2 | Revisión de los 73 casos de `ChromiumAisladoTests` (#170) | Acepto | 3 días hábiles desde tu aviso de M-170-2 |
| 3 | Revisión del #175 (T4-04) contra el plan T4-04/T4-06 v2 | Acepto. Ya unido: seguimiento | 27-oct |
| 4 | Plan de pruebas de M-168-2 y M-168-1 | Acepto | 28-oct |
| 5 | Plan de pruebas de S152-02 (C-02-1 a C-02-5) y T4-03b | Acepto | 28-oct |
| 6 | Plan de T4-10 y T4-11 (vistas `imp`, #178) con S-01 a S-09 y negativas del lector único | Acepto | 28-oct |
| 7 | Casos de laboratorio de T1-b y del spike Amplio (DE-01, DE-10 a DE-16) | Acepto | 29-oct |
| 8 | Revisar el cambio de `ComprobacionCarpetasPreviasTests` (#124, ACE de `CodexSandboxUsers`) | Acepto; espero que A publique su decisión | 1 día hábil desde el aviso de A |

Orden: primero la limpieza (tiene fecha), luego 1 y 3, luego 4 a 7. Todo es lectura y plan salvo la limpieza.

## Nota sobre SQL en OSHIN-LEGION
Tras el reinicio, `MSSQLSERVER` y `MSSQL$SQLEXPRESS` estaban detenidos (inicio automático). No los arranco yo; lo aviso al propietario. Sin SQL no corro las pruebas dirigidas de la limpieza; si siguen detenidos, el PR sale compilado y con las pruebas dirigidas pendientes, y lo digo en el PR.

Respuesta requerida: ninguna.
