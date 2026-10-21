# Nota de traspaso del equipo A (cambio de sesión, 2026-10-21 por la tarde)

Para la sesión nueva de la PC A (`DEVLAB00`, mini PC de 8 GB y 4 hilos: máximo 2 compilaciones a la vez), pegue: «Somos el equipo A. Lee `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\2026-10-21-traspaso-A-cambio-de-sesion.md` y retoma desde ahí». Sustituye al traspaso del 2026-10-18.

## 0. Antes de nada
- **Hay una suite oficial corriendo** (sin agente) en `C:\Users\lfmen\source\repos\GPOS-NG-pr2` sobre `a/adr90-rt05-tls-escucha` @ `da8c3668`: `dotnet test tests/GPOS.Tests --no-build --filter "Transicion!=Ola5&Transicion!=Defecto"`, iniciada hacia las 15:35 (la primera, `suite-pr2.txt`, sobre ae432314 dio 4893 correctas y 3 fallidas: 1 mía de ADR-126, ya corregida, y las 2 inestables conocidas C10 y Rg14Lote2). Salida de la nueva: `C:\Users\lfmen\AppData\Local\Temp\claude\C--Users-lfmen-source-repos-Solucion-GPOS-NG\18f65f3f-6063-4693-9cad-760d63179546\scratchpad\suite-pr2-b.txt` (termina con la línea de totales). **No compilar en ese árbol hasta que termine**; después borrar `testhost.exe`. Si el proceso murió con la sesión, repetirla.
- Vigilancia: la tarea de Windows «GPOS-NG Vigilar área común (A)» está habilitada (cada 10 min, sin costo de modelo; el propietario levantó la pausa el 2026-10-21). Al abrir, armar el `Monitor` de `novedades-A.md` (comando en la memoria `revision-area-comun-30-min`) y leer `novedades-A.md`.
- Leer `avisos/B-a-A` nuevos y `traspasos/B/2026-10-21-cierre-sesion-b.md`. **Nada se une sin orden expresa del propietario.**

## 1. PR abiertos de A (todos esperan revisión de B u orden de unión)
| PR | Rama | Qué es | Estado |
|---|---|---|---|
| GPOS-NG #103 | `a/dv07-formato-licencia` @ 662eb9e9 | DV-07: formato de la licencia | Aceptado por B. Se une **seguido** del PR #1 del emisor, con la suite oficial sobre el combinado |
| GSF.EmisorLicencias #1 | `a/dv07-ajuste-emisor` | Ajuste del emisor (submódulo en 662eb9e9) | Abierto. Antes de unir, subir el submódulo al commit unido |
| #122 | `a/adr90-rt01-modo-red` @ d592b338 | PR-1a de ADR-90 (RT-01) | Aprobado con observaciones (B, C, seguridad). Suite oficial completa sin repetir tras las correcciones |
| #130 | `a/adr90-rt06-filtro-origen` @ 37d7bb05 | PR-3 (RT-06, filtro por IP del nodo), apilado sobre #122 | Idem |
| #137 | `a/adr90-rt05-escucha-servidor` @ 99d5f79e | PR-1b (`GPOS.Comun.Servidor`), apilado sobre #130 | Seguridad: aprobado con observaciones (S1b-01 a 04 corregidos) |
| #136 | `a/n1-endurecimiento-servicio` @ 2cd41377 | N-1: S-03, S-04, S-05, S-07, R-02, R-03, R-06 | B: aprobado con observaciones |
| #124 | `a/instalador-o1-o3` @ 82318329 | O-1 y O-3 (acción previa, raíz y `config\`) | Seguridad y C: aprobado con observaciones. Falta S-04 (devops) y laboratorio |
| #139 (borrador) | `a/adr90-pr4-cableado-api` @ fcc3d3b9 | PR-4: `Program.cs` de la API, retira `FijarEscuchaPorOmision`, regla sin modo | **No se une sin PR-2** |
| #140 (borrador) | `a/adr90-rt05-tls-escucha` @ da8c3668 | PR-2 (RT-05: TLS, selector, URL de la Web, H-15) más 8 commits de correcciones | Relectura: aprobado con observaciones |

**Orden de unión previsto:** #122 → #130 → #137 (reapuntar la base tras cada uno) → #136 → (#139 y #140 juntos) → #124. Cada unión: `gh pr merge N --merge --match-head-commit <sha>`; tras unir, rebasar lo apilado.

## 2. Pendiente inmediato de A
0. Ya hecho el 2026-10-21 tarde: aviso a B con acuses de sus tareas nuevas (acepto 1, 2 y 3; no tomo la 4), lista S-16 (`rutas-inventario-sin-filtro-sucursal-2026-10-21.md`; B decide D-1 a D-4 y el alcance de E-1) y la pila actualizada (`A-a-B/2026-10-21-acuse-tareas-nuevas-s16-y-pila-adr90.md`). Falta solo informar el resultado de la suite nueva.
1. Esperar la suite de §0 y publicar en `A-a-B/` el aviso con la pila (#137, #139, #140) y su resultado (la relectura dice «unir con observaciones» si la suite está en verde). Fechas prometidas a B: PR-1b 2026-10-28 y PR-4 2026-10-30 (ventana F-5: 28-oct a 6-nov, terminar antes del 2-nov; DB-7 empieza el 2-nov en la zona de `Program.cs`).
2. **R-01 y R-02 de la relectura de PR-2 y PR-4** (`traspasos/A/relectura-seguridad-pr2-pr4-adr90-2026-10-21.md`): encadenar la excepción original en `ExigirArranque` y ampliar la prueba de S2-05 (cuatro vías nuevas y más carpetas); R-04 opcional. Son minutos.
3. **S2-04** (decidir si `AllowedHosts` de la API se endurece, arquitecto de A) y dejar H-15 (`Secure` «con modo», `UseCookiePolicy`) y H-09 (4743 en lugar de excepción) en el plano.
4. Respuestas de B a las **4 preguntas de la revisión de ADR-93** (PREGUNTA-1 a 4; la 3 antes de E-1) y a R-06 del #124 (¿entran la Web y la Migración en `declaran` de `config\`? arquitecto-maestro).
5. Pendientes de otros: S4-02 (`failureflag` y código de salida frente al SCM: devops de B) y S2-07 (suites de Schannel, RT-09).

## 3. Cola posterior
- **Fecha de RT-02: 2026-11-23** (estimación mía, no firmada). **Laboratorio de ADR-90:** lo ejecuta **B** en `LFMB` con VirtualBox (decisión del propietario, 2026-10-21); mi QA **revisa la evidencia** (formato pedido en `A-a-B/2026-10-21-acuse-n1-unido-d1-asignaciones-y-evidencia.md`). Esta PC **no** sirve de anfitrión (8 GB).
- **PR de seguimiento del emisor** (PA-10, CL-07 y PA-17, KDS a RESTAURANTE, aviso de módulo posterior, confirmación de módulo que desaparece, registro de perpetuos): tras unir #103 y el PR #1, cada punto con su firma.
- **ADR-92** (entregado en `traspasos/A/adr92-respuestas-datos-2026-10-21.md` y `adr92-respuestas-software-2026-10-21.md`): B integra; **CS-P2 antes del 2-nov**; no hay construcción de A hasta que se firmen P-92-S1 a S4.
- **ADR-93:** revisión entregada (`revision-seguridad-adr93-2026-10-21.md`); condiciones S-01 a S-04 para construir E-2.
- Sin cambios: N-10 en detalle (espera revisión del auditor), VS-2 y ADR-77 N-11 a N-15 (tras la prueba D4), tanda 3 de ADR-78 (51387, 51388, 51391 a 51393, 51418, 51419), R-1 de RSVB-04 (0,02 dp, opcional), LN y LS (enero a marzo de 2027).

## 4. Números
- **EventId de A:** 4742 (#103) · 4743-4752 ADR-90 (usados 4743-4746, 4747-4749 en PR-2, 4750-4751 en PR-3; **4752 reservado**) · 4753-4766 acción previa y actualizador (4753-4755 usados en #124) · 4780-4789 verbo `tls`. De B: 4767-4770 N-1, 4771-4779 `GPOS.Instalacion`, 4790 T1-7, 4791-4799 reserva de DB-7. Errores SQL: nada dentro de 51618-51644.
- **Marcas de migración:** ninguna nueva de A.

## 5. Decisiones de A vigentes (para no reabrirlas)
- Regla **sin modo**: `ListenLocalhost(5071)` armado en código, solo la API, sin modo, sin Estricto y sin ninguna fuente de direcciones; vale también en consola.
- **#124 D-1** (aprobado por el propietario): `config\` fuera del MSI de la estación; GUID de la raíz `66D68CDE-6BFC-4590-9089-68AD56F78DD3`; S-06 por feature con `GposFeatureCarpetas`.
- **F-1** firmada opción B (`net472` temporal para la acción del instalador; ninguna otra tecnología sin consultar al propietario). F-5 y F-6 firmadas.
- El caso por número de ADR-92 (CS-P2) y TT-P2 (el historial temporal guarda los datos personales tras la supresión) están como propuesta, sin decisión.

## 6. Notas de la PC A
- **Árboles de trabajo en `C:\Users\lfmen\source\repos\`:** `GPOS-NG` (base), `GPOS-NG-dv07`, `-o1` (#124), `-n1fix` (#136), `-adr90` (#122), `-rt06` (#130), `-pr1b` (#137), `-pr4` (#139), `-pr2` (#140) y `GSF.EmisorLicencias-dv07`. Los de ramas ya unidas se pueden retirar después.
- **Pruebas:** borrar `testhost.exe` tras compilar, `--no-build`, solo filtradas; la suite oficial entera sola, unos 35 min. Las pruebas con Kestrel en `0.0.0.0` solo con `GPOST_PRUEBA_ESCUCHA_RED=1` (abren la ventana del cortafuegos).
- **Atribución:** los agentes escalados a Opus firman `Co-Authored-By: Claude Opus 5.5`; el resto, Sonnet 5.5.
- El agente nuevo `asesor-legal` está instalado (aún sin usar).

## 7. Firmas
A no tiene firmas pendientes. Pendientes del propietario (vía B): orden de unión de los PR, ADR-93 (número definitivo), P-92-S1 a S4 y responsable de TT-01 a 06, R-05 de N-1 (tres categorías en Información), CI-7 y AP-04, y lo de su lista.
