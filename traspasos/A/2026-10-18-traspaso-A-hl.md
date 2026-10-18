# Nota de traspaso del equipo A (2026-10-18, tras entregar H-L1/H-L2)

Para la sesión nueva de la PC A, pegue: «Somos el equipo A. Lee `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\2026-10-18-traspaso-A-hl.md` y retoma desde ahí».

Sustituye al traspaso `2026-10-18-traspaso-A-tarde.md`. Al cerrar no quedaban agentes ni pruebas en marcha.

## 1. Estado
- **PR #76 (H-L1 y H-L2)** abierto: `a/hl-falla-cerrada-linux` @ `c7f3f2ba`, árbol `GPOS-NG-hl`, sobre `322b21d6`. Entrega del encargo de B (`B-a-A/2026-10-18-encargo-h-l1-h-l2.md`, PL-02 (a) de la propuesta de Linux firmada). Fuera de Windows la API, `GPOS.Migracion` y la Web no arrancan (H-L1); `CarpetaAnillo` y `AlmacenLicenciaDisco` fallan cerradas (H-L2); en Windows nada cambia. Alcance ampliado: también se niega el arranque con certificado (B puede acotarlo). GPOS.Tests 56/56 y GPOS.Web.Tests 14/14 dirigidas. Seguridad: Aprobado con observaciones (`traspasos/A/revision-seguridad-hl1-hl2-2026-10-18.md`); las dos no bloqueantes ya corregidas en el commit `c7f3f2ba`. Aviso `A-a-B/2026-10-18-pr76-hl1-hl2`. **Falta que B lo una**, después de la medición del #61/#71.
- **PR #75 (RSV-F1 a F4)** sigue abierto, sin cambios desde el traspaso anterior: `a/rsv-anillo-mantenimiento` @ `d60bb7d3`, árbol `GPOS-NG-rsv`. Seguridad: Aprobado con observaciones. Aviso `A-a-B/2026-10-18-pr75-rsv-f1-f4`. Falta que B lo una.
- **Esquema de modelo:** el propietario pidió que las sesiones trabajen con **Sonnet 5 y esfuerzo medio**, y sugieran Opus 5.5 solo por tarea (aviso `B-a-A/2026-10-18-sesiones-sonnet-medio-escalar-opus`, acuse `A-a-B/2026-10-18-acuse-sonnet-medio-escalar-opus`). Esta sesión ya trabajó así. Los agentes siguen con el modelo de su definición (2026-10-17).

## 2. Números
- **EventId:** sin EventId nuevos en el #76. Siguen libres **4729**, 4733 y 4735 en adelante (4723-4728 y 4734 usados por el #75).
- **Error SQL:** siguiente libre **51619** (sin usar).
- **Migraciones:** ni el #75 ni el #76 tienen. Toda marca nueva va después de la última unida.
- **EventId repetidos heredados** (4701-4703 y 4711-4718): congelados en `tests/GPOS.Tests/Arquitectura/EventIdUnicosTests.cs`.

## 3. Pendiente
- **Lo decide B (Maestro), antes de la primera licencia de pago:**
  - **RSVB-02:** canal real del aviso al SUPER (S-05 del #69, 0,15-0,25 dp si B la elige).
  - **RSVB-03:** CR-01 no detecta un detach/attach ni una instantánea de la VM de GPOS_SYSDATA.
  - Si B quiere acotar el #76 a «solo sin certificado» en vez de «sin certificado ni equivalente aprobado».
  - Si se renumeran los EventId repetidos.
- **Para la tanda LN (Linux), no ahora:**
  - SEG-HL-02 (`PadronSellos.EscribirDisco` ante `PlatformNotSupportedException`), SEG-HL-03 (permisos de archivos dentro de las carpetas), H-L3 (`CommonApplicationData` no portable) y H-L5 (Backup Tool, otro repositorio). Ninguno es alcanzable hoy.
- **Opcional para A:** el residual R-1 de RSVB-04 (cruzar el servicio detenido con el proceso, unos 0,02 dp).
- **Lo hace devops de B:** RSV-02 (1), el nombre del servicio en el instalador y las alertas por EventId.
- **DB-7:** la construye B.
- **Después de las uniones:** el acta de resellado de GSF, antes de la primera licencia de pago.
- **Regla operativa:** hasta que se una el #75, no cambiar la recuperación del anillo en una instalación sellada ni con la API en marcha.

## 4. Notas de la PC A
- **Árboles de esta sesión:**
  - `GPOS-NG-hl`: la del #76, sin unir.
  - `GPOS-NG-rsv`: la del #75, sin cambios, sin unir.
  - `GPOS-NG-r3101` y `GPOS-NG-rsv2`: ya superados/unidos, se pueden retirar (`git worktree remove`) cuando no estorben.
- **Pruebas:** borrar `testhost.exe` después de compilar y correr con `--no-build`; solo pruebas dirigidas mientras B mida.

## 5. Firmas
A no tiene firmas pendientes.
