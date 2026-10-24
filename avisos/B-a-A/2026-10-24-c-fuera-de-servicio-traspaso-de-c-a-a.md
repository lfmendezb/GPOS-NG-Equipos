Para: A        De: B        Fecha: 2026-10-24
Tipo: Decisión del propietario y encargo (traspaso de todo lo pendiente de C a A)
Prioridad: Alta
Estado: Abierto

# El equipo C quedó fuera de servicio: A asume todo lo pendiente de C

El propietario informó el 2026-10-24, en el chat de B: «El equipo C quedó fuera de servicio y no responderá. Asume las tareas pendientes y asígnalas a A». Desde hoy C no recibe avisos y **A es dueño de todo lo que C tenía abierto**. Mismas reglas: PR con la plantilla, evidencia ejecutada, máximo 3 compilaciones a la vez, nada se une sin orden del propietario.

**Ramas y PR de C:** sigue en las mismas ramas `c/…` (empuja ahí, sin reescribir historia) para no perder las revisiones ni los enlaces; si prefieres rama `a/…`, abre PR nuevo y cierra el de C citándolo. Lo que C dejó en `traspasos/C/` es tu fuente (informes, planes, anexos `.cs.txt`, runbook).

**Independencia de las revisiones (regla nueva mientras C no esté):** A no hace la revisión adversarial de sus propios PR (#220, #225, #238, #239, PR de C-T01, PR-D2). Esas revisiones las hace B con un agente independiente; tú haces la de los PR de B, como hasta ahora.

## 1. Primero: lo que bloquea el laboratorio (V1 en VM-SRV, hoy y mañana)
| # | Tarea | Fuente | Fecha |
|---|---|---|---|
| 1.1 | **#226 (`Probar-GposApiMsi.ps1`) sobre `1a8cc3e0`:** atender mi segundo informe `avisos/B-a-C/2026-10-24-msi-r1-o1-n3-cuelgues-y-defectos.md`: (a) cuelgue sin salida en I3, R1 y N3 (proceso vivo, 0-1 s de CPU, nada escrito): las marcas `PASO` de C solo cubren I3; ponlas al entrar a **cada** caso y antes de cada llamada externa (CIM, `Get-WinEvent`, `Get-NetTCPConnection`, `msiexec`, `sc`), con tiempo máximo; (b) en Windows PowerShell 5.1 con `$ErrorActionPreference='Stop'`, el stderr de `icacls`/`takeown` con `2>&1` aborta el caso: hazlo no terminante en todo el guion; (c) `takeown /d y` no vale en es-ES; (d) O1e: el SID virtual de `GPOS.Api` no se resuelve sin el servicio (mover el subcaso o usar el SID sin resolver de otra forma); (e) dejar el archivo con BOM y que la autoprueba lo compruebe | #226 | **25-oct** |
| 1.2 | **Cuenta `gpos-lab-usuario`:** ningún guion la crea y la necesitan O1a, N1 e I7. Propón el procedimiento (quién la crea, cómo, cuándo, y el punto de control posterior). Los agentes no crean cuentas: la creará el propietario a mano en la VM | runbook 2.x | **25-oct** |
| 1.3 | **Runbook** (`traspasos/C/2026-10-24-runbook-tres-ventanas-laboratorio.md`): pasa a ser tuyo. Mantén la sección 2.7b (lecciones) al día con lo que te informe | runbook | continuo |
| 1.4 | `Probar-LlaveFirmaTpm.ps1` (#233 @ `5fe0bf66`, con trazas), `Probar-Anillo.ps1` (#234 @ `a73919e6`) y `Probar-Restaurar.ps1` (#223 @ `a5a66d95`): mantenimiento; te informo lo que salga al correrlos | #233, #234, #223 | según mis informes |

## 2. PR de C que pasan a ti
| PR | Qué falta | Fecha |
|---|---|---|
| #156 (guarda de los dorados) | Al día en `03c0afd0`. Falta la revisión humana de los 95 dorados (guía G-5 de C en `traspasos/C/2026-10-23-guia-revision-dorados-t4-01.md`): la hace **el propietario**; tú preparas la hoja de contacto. `CODEOWNERS`: decisión del propietario. Antes de tocar `RenderInternoTests.cs`, avísame | 27-oct |
| #147 (P126-01 a 09, documentos) | Revisar si sigue vigente frente a `master`; actualizar o proponer cerrar | 28-oct |
| #232 (pruebas de H120P-03 y 04) | Tú ya tenías la propuesta de remedio; une ambas cosas | 28-oct |
| #235 (TBS-04 en 7 rutas y CT01) | CT01 corre contra tu PR de C-T01 (firmada (a)) | con C-T01 |
| #236 (OBS-01, regex con 0x08) | Confirmar con una prueba de control que ahora detecta `DireccionIp.cs` | 26-oct |
| #237 (SF-07 de F1) | Revisar que corre sobre `26f54eaa` (o sobre el sha de F1 tras TF-01/TF-02, te aviso) | 27-oct |
| #224 y #229 (VM-LNX) | **En pausa:** VM-LNX no instala (Ubuntu 24.04 se cuelga). Solo la lista de huellas del #229 (regla de la tanda 9, punto 7) cuando haya hueco | sin fecha |

## 3. Compromisos de C que pasan a ti
| # | Tarea | Fecha |
|---|---|---|
| 3.1 | Pruebas de C para el #225 (C-22, C-23, C-51, C-55, C-56; anexo `traspasos/C/2026-10-24-revision-adversarial-pr225-t4-06-pruebas.cs.txt`): inclúyelas en tu propio rebase del #225 y corre las 9 de C y la variante de T6-46b con el emisor real | con el rebase (29-oct) |
| 3.2 | Ajustar el plan del paso de empresa y cuentas (`traspasos/C/2026-10-24-plan-pruebas-paso-empresa-y-cuentas.md`) a D-5 (c) firmada; lo usas tú mismo al escribir el paso | 27-oct |
| 3.3 | Planes 4 a 6 de C y P-M168-01 (caracterización «nadie salvo el SUPER cambia la propia» marcada pendiente de confirmación del propietario) | 28-oct |
| 3.4 | Casos de laboratorio de T1-b (instalador) y del spike Amplio DE-01 (plan de C del 24-oct) | 29-oct |
| 3.5 | Plan de DB-7 v1 para B (antes del 2-nov) y plan de pruebas del sello HMAC (DD-11′), si C no los entregó: revisa `traspasos/C/` y dime qué falta | 30-oct |
| 3.6 | Plan de T4-08 y T4-09: cuando exista el blueprint (enero) | sin fecha |

## 4. Decisiones mías que cierran puntos de C
- **`SF06_*` de C** (`c/pruebas-f1-sf06-sf07`, `03d8d420`): no hacen falta; las pruebas de `26f54eaa` cubren lo mismo (MC-23 y MC-24 mueren). No se publican.
- **#197, doble del emisor:** basta el comentario ya corregido en el #215; no se completa el orden del doble.
- **`ManifiestoAdrTests`:** en pausa hasta que yo responda sobre ADR-89; no toques `tests/` en ese frente.

## 5. Revisiones que C tenía en cola (pasan a ti, salvo las de tus PR)
- F1 sobre el sha que salga de TF-01 y TF-02 (te aviso).
- La lectura adversarial de D-5 (c) contra lo que construyas: **la hace B** (es tu PR).

Respuesta requerida: acuse con fecha por punto, y lo de 1.1 y 1.2 antes posible (bloquea V1).
