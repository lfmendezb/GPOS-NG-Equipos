```
Para: C (conocimiento de A)        De: B        Fecha: 2026-10-20
Tipo: Encargo (el propietario pidió darle tareas a C)
Prioridad: Media
Repositorio y rama: GPOS-NG master y origin/feature/modelo-ng b8f166db; PR #119, #120 y #121 abiertos
Estado: Abierto
```

# Cola propuesta para C

El propietario pidió el 2026-10-20 darle tareas a C. Orden de B; C la contrasta con su sección de `estado.md` y confirma en `C-a-B/` qué acepta, cuándo y qué desplaza. Se mantienen las reglas de la PC de C: solo compilar y correr pruebas con filtro de clases concretas; ninguna suite completa, carga ni medición. **Regla nueva del propietario (2026-10-20): ninguna tecnología se elige o cambia sin consultarle; .NET 10 es la base. C no propone herramientas ni bibliotecas nuevas sin que B las lleve a él.**

## Sigue primero
- **Laboratorio de ADR-90 (PT-07)**, ya aceptado por C. Sin cambios. Ahora ADR-90 está completo en `master` con PT-01 a PT-10; F-1 firmada (el proyecto de la acción previa en `net472`, temporal).

## Tareas nuevas, por orden
1. **Revisión de pruebas de los PR #119 (T1-7), #120 (T2-0) y #121 (T4-05)** contra `feature/modelo-ng`. Solo lectura y diseño: ¿falta una prueba que debería existir?, ¿alguna prueba pasa por la razón equivocada?, ¿qué casos de borde faltan? Entregar en `traspasos/C/` y como comentario en cada PR (no editar sus ramas). Puntos que B ya sabe: en T4-05 la falla de `DrillDownTests` ya existía; en T2-0 la ACL con `NT SERVICE\GPOS.Api` y `PF46` no se verificaron; en T1-7 MAUI no se compiló (`NU1301`).
2. **Arreglar `DrillDownTests.El_detalle_de_una_fila_filtra_exacto_aunque_la_columna_no_tenga_filtro_visible`**, que falla en `feature/modelo-ng` limpio con «El almacén PRINCIPAL es de la sucursal PRINCIPAL; pida al administrador una regla en Almacenes permitidos por sucursal». La prueba no prepara la regla de almacenes por sucursal. Corregir la prueba, no el código; filtro de la clase. PR contra `feature/modelo-ng`.
3. **Pruebas inestables conocidas:** `NegativosPoliticaPreparacionTests.R02_…` (falla bajo carga), `EsquemaPendienteAccesoTests.Un_Super_Usuario_inhabilitado…` (conexión a la base de la empresa) y `DL22_S18_…_en_1_s`. Diagnosticar la causa de cada una (solo lectura y filtros por clase) y proponer el arreglo; si es solo prueba, PR; si toca código de producción, avisar a B.
4. **Plan de pruebas de DB-7 D1 (T1-1 a T1-4)**, sin ejecutarlas: a partir de `docs/datos/2026-10-19-db7-d1-ddl-y-consultas.md` (revisión 2) y las respuestas del arquitecto-software, listar las pruebas con nombre exacto, en rojo primero, para Q3-P (el caso que nunca daba 409 `ULTIMO_ADMIN`), Q13 (`OUTPUT … INTO`), la purga por categoría (PF25 y PF43 se rompen con la clave foránea de T1-1) y las pruebas que fijan `Version == 5`. Insumo para el desarrollador que construya T1-1 desde el 2026-11-02.

## Fuera de C
Mediciones con `GPOST_B9`, la suite completa y la compilación de MAUI (origen NuGet local `C:\Users\lfmen\source\NugetLocalFeed`): las hace B.
