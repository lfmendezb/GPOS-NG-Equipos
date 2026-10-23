# Nota de traspaso del equipo A (cambio de sesión, 2026-10-23, tarde)

Para la sesión nueva de la PC A (`DEVLAB00`, mini PC de 8 GB y 4 hilos: máximo 2 compilaciones a la vez), pegue: «Somos el equipo A. Lee `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\2026-10-23-traspaso-A-tarde.md` y retoma desde ahí». Sustituye a `2026-10-23-traspaso-A-manana.md`.

## 0. Antes de nada
- `git pull` del área común (`GPOS-NG-Equipos`) y leer los avisos `B-a-A` posteriores a `2026-10-23-orden-de-union-y-revision-173.md` (09:41). Armar `Monitor` sobre `%LOCALAPPDATA%\GPOS-NG-Equipos\novedades-A.md` (vence a los 30 min y **se pierde al cerrar la sesión**).
- **No hay agentes activos.** Todo lo de esta jornada se hizo en la sesión principal.
- **Nada se une ni se abre como PR sin orden del propietario.** Empujar ramas `a/` sí está autorizado; `push --force` no, sin preguntar.
- Trampas: un mensaje de commit que empieza con `A:` lo bloquea el filtro; en `Edit` hay que `Read` el archivo antes; **los heredocs de Bash con Python y comillas fallan**: escribir el script con `Write` en el scratchpad y ejecutarlo; para rutas de Windows en PowerShell, usar la herramienta PowerShell, no `pwsh -Command` desde Bash; compilar con `-m:1 -nr:false`; borrar `testhost.exe` tras cada prueba; **no** `dotnet build-server shutdown`; un agente por árbol.

## 1. Hecho el 23-oct (después del traspaso de la mañana)
- **Tercera revisión de seguridad de PR-V** publicada (`revision-seguridad-pr-v-red-origen-82bf648d-2026-10-23.md`): sin Críticos, Altos ni Medios; aprobar con condiciones.
- **PR-V** (`a/pr-v-verbos-servidor`, punta `a3c71ce1`, 816/816 con el filtro `(FullyQualifiedName~GPOS.Tests.Servidor|FullyQualifiedName~GPOS.Tests.Arquitectura|FullyQualifiedName~EventIdUnicos)&Transicion!=Ola5&Transicion!=Defecto`): corregidos SPX-01, 02, 04, 09; SPX-03 (firmado: ACE de `GPOS.Web` en vez de `GPOS.Reportes`; AU se queda hasta que la Web sea servicio); SPW-02 (servicios detenidos, marca `.aplicando`, `Restaurar` solo lo copiado) y SPW-03 (`VIEW ANY DEFINITION`, grupos con poder, `LoginExiste` en `esquema`); SPX-05, 06, 07, 08 en parte. SPW-04 y SPW-05 ya estaban.
- **PR-D2, borrador** (`a/pr-d2-manifiesto`, `34a80af6`, 690/691 en Instalador, Arquitectura y valores de terceros; apilada sobre PR-V `82bf648d`): modo de servicios en `Instalar-Demo` (elevación, paquete fuera de OneDrive y del perfil y protegido, servicios detenidos antes de `--fase servicios`, `-RotarJwt`), `Iniciar`, `Detener`, `Desinstalar`, `Actualizar` (rechaza el cambio de modo, sin rotar la JWT) y `Revertir` (se niega), LEEME sección 2b y rechazo de `Jwt__Clave` en el paquete de cliente.
- **Tarea 7** (`a/usuarios-razor-restriccion`, `e9d2267c`): etiqueta de `ACCESO_RECHAZADO_SUCURSAL` en Web y MAUI y prueba al día con la hoja del 188.
- **Hoja de decisión de SPV-03** (`traspasos/A/hoja-decision-spv-03-manifiesto-2026-10-23.md`): recomiendo (a) aceptarlo como residual del DEMO.
- Avisos A-a-B del día: `...tercera-revision-y-spx-01-02`, `...spx-03-firmado-aplicado`, `...spx-bajos-restantes`, `...spw-02-03`, `...usuarios-razor-etiqueta-y-pregunta-menu`, `...pr-d2-borrador-instalar-servicios`, `...pr-d2-iniciar-detener-desinstalar`, `...pr-d2-actualizar-y-revertir`, `...pr-v-spx-07-y-08`, `...spv-03-hoja-y-spx-06`.
- **Orden de unión de B** (aprobada por el propietario): #164 y #165 ya unidos; sigue el PR del emisor `a/t4-04-emisor` (se abre cuando C entregue las pruebas de P175-01 y la primera parte de P175-02); #173 sin prisa (lo revisa C, plazo 3-nov).

## 2. Ramas (todas empujadas; ninguna unida; sin PR salvo las marcadas)
| Rama | Árbol | Punta | Notas |
|---|---|---|---|
| `a/pr-v-verbos-servidor` | `GPOS-NG-prv` | `a3c71ce1` | Sin PR. Falta: ocupación de puerto y rangos excluidos (solo VM), mutaciones 1, 5 y 6 de SPX-08 (poco valor), ensayo en la VM |
| `a/pr-d2-manifiesto` | `GPOS-NG-prd2` | `34a80af6` | Sin PR. **Rebasar sobre PR-V** (`push --force-with-lease` a su propia rama, con visto bueno del propietario). Faltan fases `esquema` y `lectura`, primer arranque como servicio, `Revertir` real |
| `a/t4-04-emisor` | `GPOS-NG-t404` | `1927608d` | Sin PR; ver orden de unión |
| `a/usuarios-razor-restriccion` | `GPOS-NG-usr` | `e9d2267c` | Web compila; **MAUI nunca se compiló**. Falta ocultar opciones denegadas (espera a B) |
| `a/limpieza-clearallpools` | `GPOS-NG-pools` | `994cfda2` | C abrió su propio #196 con el mismo fin: preguntar a B cuál se queda |
| `a/spike-amplio-demo` (#173), `a/t1c-lab-instalador` (#165, unido), `a/t1a-firma-instalador` (#164, unido), `a/p124-temp-ace` (#103) | varios | — | Sin cambios |
`GPOS-NG-r170` (copia de solo lectura del #170) se puede retirar.

## 3. Pendiente y fechas
| Cuándo | Qué |
|---|---|
| Cuando B avise con el sha | Revisar el #170 desde `89fce5b5` hasta su punta (B corrige H170-03, 04 y 05) |
| Antes del 28-oct | B responde: verbo `tls`, HTTPS del DEMO con `ModoRed=UnEquipo`, `SesionInfo.RestringirSucursal` (desbloquea ocultar opciones del menú, unas 0,15 dp) |
| 3-nov | **T4-06** (blueprint `blueprint-t4-06-lista-p2-2026-10-22.md` con sección 17; no empezar sin P-1 a P-3, P-4 y Q-A4 de B; si se une antes que T4-04, Release no compila; unión antes del 11-nov) |
| Antes de D4 | Firma de SPV-03; PR-V y PR-D2 unidos |
| 16 a 27-nov | Ensayos de PR-D2 en la VM (opera B); 18-nov am: bloque instalador; 23-nov am: spike Amplio |

## 4. Decisiones que esperan
- **Propietario:** propuesta de certificados del anillo (DM-07: el servidor genera el suyo, autofirmado y no exportable, y recibe solo el `.cer` público de recuperación; la privada la guarda el propietario). **Dijo que la está revisando; no avanzar las fases `esquema` y `lectura` de PR-D2 hasta su respuesta.** SPV-03 (hoja lista). Abrir PR y orden de unión.
- **B:** `tls`; excepción de `ExcepcionesValidacion` para fijar `HuellaApi` en P4 (descartada por ahora: la regla R2-02 lo prohíbe); `SesionInfo`; canal de eventos propio con `ChannelAccess` y MSI (SPX-07).

## 5. Números vigentes
- EventId: 5120 `AccesoRechazadoSucursal`; 5134-5138 PR-V; 5139 `ServidorConfiguracionRed`; 5150-5155 T4-10; 5156-5157 #170; 4791-4793 emisor; 4794-4795 D1; 5117-5119 #170; 5121-5129 #175/T4-04.
- Los agentes que escalan a Opus firman `Co-Authored-By: Claude Opus 5.5`; el resto, Sonnet 5.5.
