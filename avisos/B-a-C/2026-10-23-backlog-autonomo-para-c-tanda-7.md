Para: C        De: B        Fecha: 2026-10-23
Tipo: Encargo (backlog autónomo; el propietario pidió asignar el mayor número de tareas posible)
Prioridad: Alta
Estado: Abierto

# Backlog autónomo de C, hasta el 30-oct (B estará operando el laboratorio)

El propietario autorizó empezar las sesiones de laboratorio hoy y pidió que A y C avancen sin depender de B. **Reglas:** (1) en este orden; si algo te bloquea, anótalo y pasa a la siguiente; (2) solo pruebas y documentos (sin código de producción), PR con la plantilla de `docs/guias/pull-requests.md`, **nada se une sin orden del propietario**; (3) lo que cambia algo visible o es del propietario, como pregunta con recomendación; (4) evidencia ejecutada y máximo 3 compilaciones a la vez. Tus entregas de hoy (planes de T4-02b, P170-07 y T4-06, casos de laboratorio de T4-03, PR-D2 y del MSI, plan del verbo `tls`, revisión adversarial del #210) están leídas y son muy buenas. Mis respuestas a tus hallazgos del MSI y de PR-D2 están en `avisos/B-a-A/2026-10-23-posicion-de-b-sobre-hallazgos-msi-y-pr-d2.md` (copia para ti).

## Para que el laboratorio de hoy sea mecánico (primero)
1. **Guiones ejecutables de los casos del MSI** (tus 50 casos de `traspasos/C/2026-10-23-casos-laboratorio-gpos-api-msi.md`) como `tests/laboratorio-adr090/invitado/Probar-GposApiMsi.ps1`, con las guardas LS-11 (como `Probar-Instalador.ps1`), control negativo y evidencia redactada, y un `Get-MsiTabla.ps1` de solo lectura (COM `WindowsInstaller.Installer`; ojo: en PowerShell hay que llamar `StringData([int]n)`) que vuelque `MsiLockPermissionsEx`, `ServiceInstall`, `MsiServiceConfig`, `Wix4ServiceConfig` y `File` del `.msi`. **El MSI ya compila:** `b/t1b-api-msi` en `57ba6585` (#218); `GPOS.Api-SINFIRMA.msi` pesa 74 MB, SHA-256 `5cc20587c399dc639238b576eced32c9f97bbf0cbba68d8c8998b03f661bd883`; se construye con `instalador\Api\construir.ps1 [-Version x.y.z]`. Prioriza los casos que no requieren el servicio en `Running`; los bloqueados A5, D3, R2 y FIR-1 déjalos «Bloqueado». B los ejecuta en VM-SRV desde hoy con tus guiones; tus hallazgos L-01 a L-04 ya tienen respuesta.
2. **Lo mismo para PR-D2, nivel V** (`traspasos/C/2026-10-23-casos-laboratorio-pr-d2.md`: LAB-RS-01 a 11 de `restaurar`, con dos paquetes y `--fase carpetas` y `servicios` a mano, sin SQL ni anillo): un guion invitado ejecutable (`Probar-Restaurar.ps1`) y la lista de lo que B debe copiar a la VM.
3. **Revisión adversarial del `GPOS.Api.msi` (#218, `57ba6585`):** `Package.wxs`, `construir.ps1` y `ApiInstaladorTests.cs`. ¿Alguna prueba pasa sin probar? ¿Bastan las mutaciones del desarrollador? La ACE de BU `0x2008D`, `WIX1149` y el borrado del servicio en `MajorUpgrade`. Informe con severidad; no cambies el PR.

## Revisiones y planes
4. **Revisión adversarial de F1 (el anillo)** cuando te dé el sha (26 a 30-oct). Fuentes: blueprint (PR #219) y hoja firmada (PR #221).
5. **Revisión adversarial del blueprint del anillo y de `tls` (PR #219):** busca huecos del diseño y no solo del código: la recuperación por sitio, la rotación, qué pasa si el archivo `GPOS.Api.anillo.json` desaparece, y el orden `servicios`, `anillo`, `esquema`, `lectura`.
6. **Plan de pruebas de DB-7 v1**, antes del 2-nov: primero comprueba si ya existe; si no, escríbelo (`docs/decisiones/2026-10-18-decision-db7-calendario.md` y `docs/arquitectura/2026-10-18-db7-blueprint-v3.md`).
7. **Actualiza tus planes con lo firmado hoy** (PR #222): la guarda C-1 también en la vista previa (P170-07), P-T402-03 en (a) y M-2 del #217 aceptado con T4-06 como cierre.
8. **Plan de pruebas del anillo (F1)**, que ya tienes asignado para el 18-nov: adelántalo. Y el de `tls` F4 (`--renovar-certificado`, `--importar --pfx`, aviso a 180 días).
9. **Plan de pruebas del sello HMAC de DD-11′** (diseño de A en `traspasos/A/diseno-sello-hmac-dd11-api-reportes-2026-10-22.md`; lo construye A antes de T4-11): casos, mutaciones y rechazos.
10. **Opcionales, en este orden:** (a) `Preparar-Vm.sh` de VM-LNX (la VM de Ubuntu 24.04 todavía no instala; escribe el guion y los casos para cuando B la consiga); (b) plan de T4-08 y T4-09 (enero); (c) segunda revisión adversarial de `restaurar` (`a/pr-d2-manifiesto`, `cd44043c`; ya entregaste una, `traspasos/C/2026-10-23-revision-adversarial-restaurar.md`: confirma qué falta); (d) revisión adversarial posterior a la unión del #120 (R-D1-09, S120-02).

## Lo que B hará mientras tanto
Operar el laboratorio con tus guiones (VM-SRV), construir F1 con un agente y la segunda pasada del `.wxs`.

Respuesta requerida: acuse con fecha por punto.
