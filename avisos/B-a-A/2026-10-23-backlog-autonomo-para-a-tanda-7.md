Para: A        De: B        Fecha: 2026-10-23
Tipo: Encargo (backlog autónomo; el propietario pidió asignar el mayor número de tareas posible)
Prioridad: Alta
Estado: Abierto

# Backlog autónomo de A, hasta el 30-oct (B estará operando el laboratorio)

El propietario autorizó empezar las sesiones de laboratorio hoy y pidió que A y C avancen sin depender de B mientras tanto. **Reglas:** (1) trabaja en este orden y pasa a la siguiente si algo te bloquea; anota el bloqueo en tu aviso, no esperes a B; (2) PR con la plantilla de `docs/guias/pull-requests.md`, **nada se une sin orden del propietario**; (3) las decisiones de diseño que ya son tuyas, tómalas y díselo a B en el acuse; las del propietario (algo que el usuario ve o hace, tecnologías nuevas, valores de terceros), déjalas como pregunta con recomendación; (4) evidencia ejecutada, máximo 3 compilaciones a la vez. Estado de la base: `feature/modelo-ng` con todo lo de hoy unido (#120, #170 a #173, #196 a #206, #212, #153, #215…); abiertos de B: #210, #216, #218, #219, #221, #222.

## Ruta crítica (primero)
1. **#217: M-1, B-1 y B-2** (revisión independiente: `avisos/B-a-A/2026-10-23-revision-independiente-217.md`). Avísame del sha; el propietario ordenará la unión (límite 11-nov). M-2 está aceptado con T4-06 como cierre: no lo corrijas aquí.
2. **T4-06 (lista P-2 vacía): empieza ya**, no esperes al 3-nov. P-1 (a), P-2 (a), P-3 (a), Q-A4 (segunda pregunta) (a) y P-4 (marcador) están **todas firmadas**; la unión debe ser antes del 11-nov. Rebasa sobre `feature/modelo-ng`, reutiliza `ReenvioReportes.NoDisponible()` y usa el plan de C (`traspasos/C/2026-10-23-plan-pruebas-t4-06.md`, versión 3, ~70 casos): quitar `enLaPrincipal` de `EjecucionReglas.Modo`, `#if DEBUG` en `ReporteEnLaPrincipalAsync`, invertir `Caracterizacion_pendiente_hoy_…`. Esto cierra M-2.
3. **PR-D2, lo que no depende del anillo:** R-04 (que la API y reportes se nieguen a arrancar con `.aplicando`, en PR aparte contra `feature/modelo-ng`), R-09 (`comprobar-servidor` al final de `Revertir`), **P-D2-01** (el ciclo actualizar, revertir, actualizar, revertir pierde `HuellaCopiaPrevia`: confírmalo y corrígelo), P-D2-04 (reanálisis y vínculos físicos en el subárbol) y la línea de la guía del DEMO sobre el tablero. **Abre ya el PR de `restaurar` y el manifiesto** (`a/pr-d2-manifiesto`, `cd44043c`) sin esperar al anillo; lo que depende del anillo (empresa y cuentas) va en otro PR después de F1 (antes del 5-nov).
4. **Decisiones del MSI de la API** (casos de C: `traspasos/C/2026-10-23-casos-laboratorio-gpos-api-msi.md`; mi posición: `avisos/B-a-A/2026-10-23-posicion-de-b-sobre-hallazgos-msi-y-pr-d2.md`): Q-3 (reinicios: ¿restart, restart, none?), Q-4 (la actualización conserva el `Environment` y la DACL de la clave: L-02), Q-7 (`demand` o `auto`), D-4 y D-5 (dueño de la base creada con `dbcreator` y orden de `lectura`). **El MSI ya compila** (#218, `57ba6585`; el SDDL de Q-5 quedó idéntico en la tabla `MsiLockPermissionsEx`). Con tus respuestas hago la segunda pasada.

## Revisiones, en este orden
5. **Blueprint del anillo y de `tls` (PR #219):** revisión de seguridad antes del 28-oct (hoja firmada: PR #221).
6. **`GPOS.Api.msi` (#218, `57ba6585`):** revisión del diff y de `construir.ps1` (G-PR4, firma, `Comprobar-BinarioEnMsi`).
7. **F1, el anillo:** cuando te dé el sha (26 a 30-oct), antes de su PR.
8. **#220 (menú):** sigue abierto; atiende mis observaciones si las hay.

## Construcción (después de lo anterior)
9. **Abre el PR de PR-V** (`a/pr-v-verbos-servidor`, `a3c71ce1`, revisado, sin PR): los verbos `red`, `lectura` y `FaseServicios`. Haz estricta T1-10 y comparte la constante del SDDL de Q-5 (hoy solo vive en `ApiInstaladorTests` y en el `.wxs`). Es la base de PR-D2 y de F2 de `tls`.
10. **Sello HMAC de DD-11′ (tu diseño, 2,2 dp ±30 %): lo construyes tú.** B está con DB-7 desde el 2-nov y con el anillo; va antes de T4-11 (enero), después de lo anterior. Antes de empezar: `Huella binary(33)` ya está en las vistas `imp` (#193/#194); falta leer `auth_time` de `ResultadoIntrospeccion.Claims` (R20) y el evento `FORMATO_RAZOR_SELLADO` en el catálogo de T1-1. La unión es del propietario; si algo cambia lo que el usuario ve, pregúntame primero.
11. **SPV-03 (b)**, el manifiesto firmado con llave anclada, con el bundle: solo prepara el diseño corto (no antes de D4).

## Lo que B hará mientras tanto
Operar el laboratorio (VM-SRV: casos del MSI y PR-D2 nivel V), construir F1 con un agente y la segunda pasada del `.wxs`.

Respuesta requerida: acuse con fecha por punto, y tus respuestas de los puntos 4 y 10 cuando las tengas.
