---
name: dos-equipos-a-coordina
description: "B coordina e integra y A apoya; el equipo C fue disuelto el 2026-10-14 y sus funciones se repartieron entre A y B. ADR en master, un archivo por ADR, rangos A 68-99 y B 100-129 (130-159 congelado)"
metadata:
  node_type: memory
  type: project
  originSessionId: f2c0a692-b405-4953-8a6f-70fec2b01360
  modified: 2026-10-09T22:32:46.844Z
---

**Cambio del 2026-10-09:** como la luz se va de repente y la PC A no tiene UPS, el propietario decidió que **la actividad principal y la coordinación pasan al equipo nuevo, donde restaura al Equipo B**. **La PC A pasa a ser el equipo de soporte.** Desde entonces, el coordinador (B en el equipo nuevo) es quien une ramas a `feature/modelo-ng` y `master`, edita `CLAUDE.md` y el manifiesto de pruebas y publica `memoria/` y `agentes/` en el área común. A, como soporte, trabaja en ramas propias, sube y abre PR, nunca une (salvo que el propietario indique otra cosa). **Aprobado por el propietario el 2026-10-09:** A trabaja en ramas `a/...` y conserva su rango de ADR 68-99 (libres entonces 79, 80 y 82 en adelante).

**Why:** un apagón en la PC A a mitad de una unión o de un trabajo de agentes puede dejar el repositorio o las bases a medias; el coordinador debe estar en el equipo protegido.

**How to apply:** antes de que A deje de coordinar, todo lo que solo exista en A se sube a GitHub (el 2026-10-09 había 3 commits de «mejoras del demo, ronda 2» solo en local: ramas `feature/mejoras-demo-ronda2`, `demo/2026-10-07`, `demo/2026-10-08`; subidas a origin ese día). Aviso del traspaso en el área común: `avisos/A-a-B/2026-10-09-coordinacion-pasa-al-equipo-nuevo.md` (`b6ae08c`). En A, no empezar trabajos largos sin commit y push frecuentes.

**Historia (2026-10-06):** la PC A coordinaba; la PC B (equipo anterior al 2026-10-02) trabajaba en ramas `b/...`. **ADR:** se registran solo en `master`, un archivo por ADR (`docs/adr/ADR-NNN.md`) más índice; rangos A 68-99 y B 100-129. Plan en `C:\Users\lfmen\source\repos\Solucion GPOS NG\plan-dos-equipos.md`; paquete para B en `paquete-pc-b\`. Relacionado: [[un-solo-editor-por-repositorio]], [[agentes-con-opus]], [[cierre-numeracion-nuevo-equipo]], [[estado-equipo-b]].

**Área común (2026-10-07):** repositorio privado **`lfmendezb/GPOS-NG-Equipos`** (clon local `C:\Users\lfmen\source\repos\GPOS-NG-Equipos`): `estado.md` (cada equipo su sección), `avisos/A-a-B` y `avisos/B-a-A`, `traspasos/A|B`, `memoria/` y `agentes/` (los publica el coordinador), scripts `herramientas\Actualizar-Desde-AreaComun.ps1` y `Publicar-En-AreaComun.ps1`. **El propietario decide cuándo** cada equipo actualiza o publica, salvo la revisión cada 30 minutos y lo rutinario ([[revision-area-comun-30-min]]). Commits con prefijo `[A]`/`[B]`; nunca secretos; un aviso no es una decisión.

**Confirmación del propietario a B (2026-10-09, primera sesión en el equipo nuevo):** «a partir de este momento el equipo B será el que coordine y realice las integraciones de las ramas»; «el equipo A queda como apoyo»; «toma desde ya las actividades principales que estaba desarrollando A». B hereda la construcción de `feature/modelo-ng` (cierre de la ola 4, ADR-118/119, 3b, tandas de núcleo) además de la ola 5.

**Equipo C DISUELTO el 2026-10-14 (decisión del propietario: «Disuelve al equipo C y distribuye sus funciones entre el equipo A y B»).** Desde entonces solo hay dos equipos: B coordina (en LFMB desde el 2026-10-14) y A apoya.
- **Pasan a B:** PR #21 (C-10, rebase y SQL), C-5 (UX de ADR-118/119), C-13 (correo de lote), las revisiones y dictámenes de PR, la QA de estabilidad y fiscal, y el DEMO.
- **Pasan a A:** la construcción de la fase A de ADR-81 (con el diseño de `c/adr81-fase-a-diseno`, después de #26) y el apoyo en diseño, revisión y documentos.
- El rango de ADR 130 a 159 queda congelado.
- Las carpetas de C en el área común quedan como historial de solo lectura.
- Avisos: `B-a-C/2026-10-14-disolucion-del-equipo-c.md` y `B-a-A/2026-10-14-disolucion-c-nuevas-funciones-de-a.md`.
- No encargar nada a C ni escribirle avisos nuevos.

**Historia, equipo C (2026-10-09, decisión del propietario):** la antigua PC B (LAPTOP-DUMQQ5QK, 8 núcleos, 7,8 GB; también corre el DEMO) pasa a ser el **equipo C**, de apoyo a B como A: ramas `c/`, PR sin unir, avisos en `avisos/C-a-B/` (B le escribe en `avisos/B-a-C/`), `traspasos/C/`, commits `[C]`. Límite de agentes de la antigua PC B. Encargarle diseño, revisión, documentos o construcción mediana, no suites completas ni cargas. Los scripts del área común admiten `-Equipo C`. Rango de ADR de C: 130-159 (propietario, 2026-10-09; master `fd05bdc`). Pendiente del propietario: si C hace el ensayo del DEMO.

**Equipo C REACTIVADO el 2026-10-16 (OSHIN-LEGION)**, según `estado.md` del área común. Desde entonces vuelve a entregar PR (`c/...`), avisos `C-a-B` y firmas del propietario tomadas en su sesión. Sus avisos se leen igual que los de A. El 2026-10-17 avisó que su equipo está inestable: no corre suites largas ni mediciones.
