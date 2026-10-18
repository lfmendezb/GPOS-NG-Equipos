# Nota de traspaso del equipo A (cambio de sesión, 2026-10-18 por la tarde)

Para la sesión nueva de la PC A, pegue: «Somos el equipo A. Lee `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\2026-10-18-traspaso-A-tarde.md` y retoma desde ahí».

Sustituye al traspaso `2026-10-18-traspaso-A-cambio-de-sesion.md`. Al cerrar no quedaban agentes ni pruebas en marcha.

## 1. Estado
- **B unió toda la cadena de A**, del #45 al #73, más el #58 y el #74. También unió el #57, el #69, el #56 y el #72 de C. `feature/modelo-ng` estaba en `322b21d6`.
- **El único PR abierto de A es el #75**:
  - rama `a/rsv-anillo-mantenimiento` @ `d60bb7d3`, en el árbol `GPOS-NG-rsv`;
  - contenido: RSV-F1 a F4 (ADR-79 y precisión de ADR-58), RSV-06, 08, 11 y 12, el defecto de `ComandoSellos` (`EscribirMarcas`) y RSVB-01 y 04 a 06;
  - pruebas dirigidas: 863/0/1;
  - seguridad: Aprobado con observaciones, con relectura (`traspasos/A/revision-seguridad-rsv-f1-f4-2026-10-18.md`).
  - Aviso: `A-a-B/2026-10-18-pr75-rsv-f1-f4`. Falta que B lo una.
- **Respuesta a B sobre `Un_RESTORE`:** era la carrera de `SINGLE_USER` (3101), no DL-22. La corrigió el #74, ya unido. Aviso: `A-a-B/2026-10-18-hallazgo-restore-3101-pr74`.

## 2. Números
- **EventId:** usados 4723 a 4728 y 4734. Siguientes libres: **4729**, 4733 y 4735 en adelante.
- **Error SQL:** siguiente libre **51619**.
- **Migraciones:** el #75 no tiene. Toda marca nueva va después de la última unida.
- **EventId repetidos heredados** (4701-4703 y 4711-4718): congelados en `tests/GPOS.Tests/Arquitectura/EventIdUnicosTests.cs`. Si se arregla uno, hay que sacarlo de la lista.

## 3. Pendiente
- **Lo decide B (Maestro), antes de la primera licencia de pago:**
  - **RSVB-02:** canal real del aviso al SUPER. La opción barata es S-05 del #69, unos 0,15 a 0,25 dp; si B la elige, la construye A.
  - **RSVB-03:** CR-01 no detecta un detach/attach ni una instantánea de la VM de GPOS_SYSDATA. Hay una propuesta de mitigación.
  - Si se renumeran los EventId repetidos.
- **Opcional para A:** el residual R-1 de RSVB-04 (cruzar el servicio detenido con el proceso, unos 0,02 dp).
- **Lo hace devops de B:** el procedimiento RSV-02 (1), el nombre del servicio `ServiciosWindows.Api` en el instalador y las alertas por EventId.
- **DB-7:** la construye B. Pedirá la revisión del auditor de A cuando haga falta.
- **Después de las uniones:** el acta de resellado de GSF (blueprint `traspasos/C/blueprint-acta-resellado-gsf-2026-10-17.md`, unos 1,6 dp), antes de la primera licencia de pago.
- **Regla operativa:** hasta que se una el #75, no cambiar la recuperación del anillo en una instalación sellada ni con la API en marcha.

## 4. Notas de la PC A
- **Árboles nuevos de esta sesión:**
  - `GPOS-NG-r3101`: rama unida, se puede retirar.
  - `GPOS-NG-rsv`: la del #75.
  - `GPOS-NG-rsv2`: la rama `a/rsv-licencia-instantanea`, ya superada por el #75 (no se subió), se puede retirar.
- **Pruebas:** borrar `testhost.exe` después de compilar y correr con `--no-build`.
- **Área común:** las ediciones locales de `agentes/especialista-pos.md` y `orquestador.md` solo son comillas y ya venían de antes. `novedades-A.md` se vació al principio de la sesión: lo leído está en `novedades-A-leidas.md`.

## 5. Firmas
A no tiene firmas pendientes.
