# Nota de traspaso del equipo A (cambio de sesión, 2026-10-22 por la noche)

Para la sesión nueva de la PC A (`DEVLAB00`, mini PC de 8 GB y 4 hilos: máximo 2 compilaciones a la vez), pegue: «Somos el equipo A. Lee `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\2026-10-22-traspaso-A-noche.md` y retoma desde ahí». Sustituye al del 2026-10-21.

## 0. Antes de nada
- `git pull` del área común (`GPOS-NG-Equipos`); la copia local se queda atrás y los avisos de B no aparecen hasta traerla. Armar `Monitor` sobre `%LOCALAPPDATA%\GPOS-NG-Equipos\novedades-A.md` (vence a los 30 min) y leer los avisos `B-a-A` posteriores a este traspaso.
- **Nada se une sin orden expresa del propietario.** Las uniones las hace B.
- Los comandos con `git commit -m "A: …"` fallan por el filtro de la herramienta (`'A:` se lee como ruta protegida); poner el mensaje sin «A:».
- Python en la herramienta Bash: `\\` llega como `\`; para escribir rutas de Windows en scripts de edición usar `chr(92)`, y revisar que no queden caracteres de control (`\r`, `\b`, `\n`).

## 1. Hecho el 22-oct
- ADR-90: **#122, #130, #136, #124, #137, #139 y #140 están unidos** a `feature/modelo-ng` (con la deuda de pruebas y el merge de `modelo-ng` en #139/#140).
- Relectura de seguridad de P140-03, `338d899f` y `89f03411`: aprobada (`relectura-seguridad-p140-03-338d899f-89f03411-2026-10-22.md`).
- Entregas a B: contrato del servicio del MSI de la API, guía práctica de T1-b, adenda de S-16 y Q-A5, blueprint del token y su contrato.

## 2. PR abiertos de A (todos esperan revisión de B u orden de unión)
| PR | Rama | Qué es | Notas |
|---|---|---|---|
| #103 + emisor #1 | `a/dv07-formato-licencia` | DV-07: formato de la licencia | Se une seguido del emisor; suite oficial sobre el combinado |
| #164 | `a/t1a-firma-instalador` | T1-a: módulo de firma `Firma-Instalador.ps1`, firma latente de la `.CA.dll`, sin el Skip de S-04 | T1-b (de B) se apila encima |
| #165 | `a/t1c-lab-instalador` | T1-c: operaciones de `GPOS.Api` en `docs/`, procedimiento P-O1-7 con FIPS, guion `Probar-Instalador.ps1` | Guion sin ejecutar; necesita VM y `Preparar-Vm.ps1` de C |
| #169 | `a/t4-04-contrato-token` | T4-04: contrato del token de servicio (solo interfaz y tipos) | Emisor: construir del 3 al 6-nov |
| #171 | `a/demo-guardas-q6` | PR-D1: `Publicar-PaqueteDemo -ConApiReportes` y guarda de Q-6 | **Orden del propietario: unir antes de T4-06** (límite 10-nov) |
| #173 | `a/spike-amplio-demo` | Procedimiento y guion `Probar-Spike-Amplio.ps1` | Necesita VM (P-8) |
| #174 | `a/api-jwt-entorno` | K3-DEMO cerrojo 2 y DM-04 | Toca `Program.cs` (2 líneas): unir antes del 2-nov (DB-7) |

Árboles de trabajo: `GPOS-NG` (base), `GPOS-NG-t1a` (rama de trabajo actual `a/api-jwt-entorno`; de ahí salieron t1a, t1c, t4-04, demo-guardas-q6, spike y api-jwt), `-pr2`, `-pr4` (ramas ya unidas: se pueden retirar), `-dv07`, `-o1`, `-n1fix`, `-adr90`, `-rt06`, `-pr1b` y `GSF.EmisorLicencias-dv07`.

## 3. Pendiente y fechas
| Cuándo | Qué |
|---|---|
| Antes del 28-oct | Acuse de lo de B (ya hecho el 22-oct; ver `A-a-B/`) |
| 3 al 6-nov | **Emisor del token (T4-04)**: `IEmisorTokenServicio`, validador `gpos-prg.`, metadato `PermiteTokenProgramado` (una sola ruta: `GET /api/reportes/{id}/exportar/{pdf|xlsx|csv}`), rechazos `prg` fuera de caché, SUPER → `autor-super` (P-1 firmada). Probar que `UseRouting` corre antes de la autenticación en la API de reportes |
| 3-nov en adelante | T4-06 (lista P-2 vacía y reenvío por ruta), cupo compartido con el token (P-1 de capacidad: lo lleva B al propietario) |
| Antes del 10-nov | Token listo; T4-04 de B completo |
| 13-nov | T1-a y T1-c (ya abiertos); T1-b lo construye B |
| Antes de D4 | DEMO con la API de reportes (PR-V: verbos `implantar-servidor` y `comprobar-servidor`; PR-D2); depende del resultado del spike |
| Revisiones | Seguridad de #167 (DAT-D1 rev. 3) y #162 (datos del ADR-161): informes en `traspasos/A/` (ver `revision-seguridad-dat-d1-rev3-2026-10-22.md` si ya existe); #170 (T4-03a) cuando B la pida; vistas `imp` (T4-10) cuando se publiquen |

Esperando a B: ventana de la VM (P-8) y P-2; sha de la unión de #171; respuesta de P-4 (T4-06 conserva `CompilacionDepuracion`); Q-2, Q-5, Q-6 y Q-8 del instalador; la suite oficial sobre la punta del #140 (ya unido).

## 4. Números y decisiones vigentes
- **EventId de A:** 4742 (#103) · 4743-4752 ADR-90 (4752 reservado) · 4753-4766 acción previa y actualizador · 4780-4789 verbo `tls`. De B: 4767-4770 N-1, 4771-4779 `GPOS.Instalacion`, 4790, 4791-4799. **Errores SQL:** 51618 ya lo usa `ComandosCambioRnc.ErrorOtroCambio` (ADR-82/83); el rango 51618-51644 que B reservó para D1 lo incluye: ver el aviso a B.
- Regla **sin modo** (`ListenLocalhost(5071)` en código); **F-1** opción B (`net472` solo para la acción del instalador); **S2-04 (b)** firmada; **P-1 firmada**: sin token programado para el SUPER; **excepción K3-DEMO** firmada (clave JWT en el entorno del servicio solo en el DEMO, con los cuatro cerrojos y caducidad).
- Los agentes que escalan a Opus firman `Co-Authored-By: Claude Opus 5.5`; el resto, Sonnet 5.5.

## 5. Firmas
A no tiene firmas pendientes. Pendientes del propietario (vía B): orden de unión de los PR de A, Q-3, Q-4 y Q-7 del instalador (proveedor de firma, nombre legal, qué se firma), ADR-93 definitivo, P-92-S1 a S4 y la distribución de capacidad de A desde el 3-nov.
