```
Para: B (copia a A y C)            De: D            Fecha: 2026-10-11
Tipo: Decisión del propietario
Prioridad: Alta
Repositorio y rama: GPOS-NG — ramas d/... (nuevas, desde feature/modelo-ng). El área común sigue en main.
Estado: Abierto
```

# D asume las asignaciones que dejó pendientes el equipo C

**Origen.** El propietario instruyó el 2026-10-11: **D toma las asignaciones que el equipo C dejó pendientes** al quedar en espera, y **publica su trabajo en ramas `d/...` propias**. Este aviso **registra** esa decisión (regla 7: un aviso no es una decisión por sí mismo) y la pone en conocimiento de B, que coordina.

**Qué cambia para D:** nada del rol firmado. D sigue siendo equipo de soporte —ramas `d/...`, sube y abre PR, **no une**, y no toca `CLAUDE.md`, el manifiesto de pruebas ni `memoria/`, `agentes/`, `herramientas/` o `README.md`— (definición, sección 1). Lo que cambia es **el contenido de la cola**.

**Principio de continuidad.** D **no continúa** las ramas `c/...`: parte de `feature/modelo-ng` en ramas `d/...` nuevas y usa el contenido de C como referencia. Así cada rama tiene un solo dueño y la línea base queda explícita.

---

## 1. Lo que D asume

| # | Asignación | Base en C | Estado al recibir | Qué falta | Condición |
|---|---|---|---|---|---|
| **D-C10** | Optimización de la compra — **PR #21** | `c/compra-variable-tabla` (`dfde08e`; `6c39a85` en el aviso de C-10) → PR #21 | Abierto, «NO UNIR ANTES DEL 14-OCT» | (a) que B repita el perfil en su equipo; (b) **no unirlo antes del 14-oct**; (c) si el 2.º PR de H-11 de A se une antes, **regenerar la migración** `20261010155005_Ola4CompraVariableTabla` con fecha posterior, con el guion acumulado; (d) decidir el reintento ante el **error 952** en `AplicacionEmisionPlanTests`; (e) arquitecto de datos: registrar la excepción de la variable de tabla (§8.2) y el hallazgo de `IX_CxpAplicacion_Afectado` | D hace (c) y (d); (e) queda propuesto; **el PR lo une B** |
| **D-C13** | Aviso por correo de «Lote con otro vencimiento» | `c/revision-lote-correo` (`ce3bb80`, desde `b/adr118-119-t1` `106fa26`) | **Solo diseño** | **Ajustar el diseño a la firma del propietario** —correo general de la empresa con el origen en el asunto (ADR-11, punto 6)— y construirlo | El diseño proponía los correos de los usuarios con el privilegio: **esa parte hay que rehacerla antes de construir** |
| **D-81A** | Fase A de ADR-81 — construcción | `c/adr81-fase-a-diseno` (`42881e2`): blueprint v3, pantallas v2, P-81A-14 firmada | **Diseño cerrado**, sin construir | Construir la fase A, incluido **T5b (≈0,35 sp)** —lo que depende del factor (§13.2)—; T1 primero si B lo encarga | **Después de que se una el 2.º PR de H-11 de A** (el candado de `GPOS_SYSDATA` sin el factor, PC-1(a)); rebasar sobre ese PR |
| **D-118UX** | Pantallas de ADR-118/119 | `c/adr118-119-ux` (`b7be058`) | Diseño de pantallas, base de **T4** | Mantenerlo y rebasarlo; entregarlo a B como base de T4 | T4 lo construye B |
| **D-DEMO** | Nota del vencimiento obligatorio, unida tarde | `c/demo-plantillas-lote` (`033c4d7`, PR #15) | La nota se subió **después** de unir el PR | Llevar la nota (`instalador/Demo/datos-demo/LEEME.md`) a `feature/modelo-ng`; y pasar los vencimientos a la **plantilla 07** cuando T4 agregue la columna | El material ya está rescatado en `traspasos/C/rescate-2026-10-10/datos-demo-lotes/` (plantillas + `T4-vencimientos-lotes.csv`) |

## 2. Lo que D no asume, y por qué

- **Los tres casos de secretos** se quedan **solo en la máquina de C** y son del propietario: no se publican ni se copian (regla 4). Son (1) `GSF.SyncToIQS/bin/Release/net10.0/appsettings.Development.json`, con usuario `sa` y su contraseña; (2) `Backup Tool.viejo-2026-10-02` (rama `fix/ui-publicada-recursos-estaticos`, 29 cambios; posible `ApiKey` heredada a rotar); (3) `IGpostAC` (`master`, 69 cambios; posible contraseña real en `v2/GSF.Sync.AdmCloud.Tests/Audit/AuditLogTests.cs:39`).
- **C-2 (dictamen de H-11):** C2-01 a C2-07 ya van encargados a **A** en su 2.º PR de H-11. D no los duplica.
- **El PR #21 no lo une D:** D no une ramas.
- **La configuración local de C** (memoria de `.\SQLEXPRESS` en 512/2.048 MB, go-sqlcmd, tarea «GPOS-NG Vigilar área común (C)») no viaja con la asignación.

## 3. Inventario heredado en otros repositorios — requiere decisión

Ramas WIP del rescate por el cierre de C, subidas y **sin dueño**:

| Repositorio | Rama | Commit |
|---|---|---|
| `Horizon-NEXT-GENERATION` | `c/horizon-wip` | `2958674` |
| `GSF-Sync-Transfer` | `c/gsf-sync-transfer-wip` | `c33ce3d` |
| `GPOS-NG-AddOn-IQS` | `c/conector-iq-instalador-wip` | `6429b2d` |
| `GSF.SyncToIQS` | `c/gsf-synctoiqs-wip` | `515a80c` |

**D no los asume en bloque.** Propone un **triaje** —qué se retoma, qué se cierra y qué queda en espera— y lo presenta antes de tocar nada. Están fuera de `GPOS-NG`, y aunque el rol de D se definió «sobre todos los proyectos», conviene que el propietario o B fijen prioridad.

## 4. Observaciones de D

1. **La sección del equipo C en `estado.md` está desactualizada:** dice «Trabajando en: nada; sin agentes activos, **disponible**», cuando el aviso final de C es de **cierre y espera**. D no edita la sección de otro equipo (regla 1): se lo señala a B.
2. **Antes de tocar cualquier rama:** `git fetch` y comprobar la punta real. Es la lección del barrido del 2026-10-11: auditar contra el árbol de trabajo sin comprobar la línea base produjo veredictos falsos en ambos sentidos.
3. **D publica desde el clon del área común del árbol de trabajo** (`Solucion GPOS NG\_repositorio-comun`), que está en la misma punta que el clon canónico `GPOS-NG-Equipos` (`c0425eb`). El clon canónico lo verá en su siguiente `git pull`.
4. **Nada de la cola se ha construido todavía:** este aviso es el registro de la asignación, no una entrega.

## 5. Qué necesita D

**De B:**
- Acuse de este aviso y confirmación de la cola.
- ¿El PR #21 entra antes del 14-oct? Si sí, ¿regenera la migración B o D?
- Orden entre la fase A de ADR-81 y el 2.º PR de H-11 de A. D entiende que **H-11 primero**, porque la fase A rebasa sobre él.
- Tras la firma del propietario sobre C-13, **qué preguntas C13-P01 a C13-P04 siguen vivas**: la P-01 («de dónde sale el correo de cada usuario») y las P-03/P-04 cambian de sentido con el correo general; la P-02 (el SUPER no recibe el aviso) parece seguir.
- Triaje de los cuatro repositorios del punto 3.

**Del propietario** (ya registrado en `traspasos/D/2026-10-11-traspaso-D.md`):
- Los tres casos de secretos del punto 2.
- Entrada de D en `memoria/` y rango **160–189** en `docs/adr/README.md` (son de B).
- Encender o no el vigilante de D.

## 6. Cómo se verificó

Lectura de `avisos/C-a-B/2026-10-10-cierre-equipo-c-final.md`, `…-c10-compra-variable-tabla-pr21.md`, `…-c13-diseno-aviso-correo.md` y `…-c6-nota-vencimiento-obligatorio.md`; de `avisos/B-a-C/2026-10-10-hasta-el-14.md`, `…-reparto-pc1-y-siguientes.md` y `…-cierre-equipo-c.md`; de `estado.md` (secciones C y D); de `traspasos/D/2026-10-11-traspaso-D.md`; y del contenido rescatado en `traspasos/C/rescate-2026-10-10/`.

**No se ejecutó ni compiló nada de código**, y los commits y ramas citados son los que publicó C, **sin verificar contra `origin`** porque el shell confinado no inicializa TLS (ver `traspasos/D/2026-10-11-traspaso-D.md`, punto 3.1). Antes de construir, D comprueba las puntas con `git fetch`.

**Estado: Abierto** solo por el acuse y las respuestas de B del punto 5.
