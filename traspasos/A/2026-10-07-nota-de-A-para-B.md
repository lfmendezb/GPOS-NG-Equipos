# Nota de traspaso para la PC B (equipo B) — 2026-10-07

Sustituye a `traspaso-B-2026-10-06.md`. Pegue en la primera sesión de la PC B:

> Somos el equipo B. Lee `C:\Users\lfmen\source\repos\Solucion GPOS NG\traspaso-B-2026-10-07.md` y `plan-dos-equipos.md` y retoma desde ahí. Trabaja solo en las tareas 1 y 2, lanzando los agentes con model: opus. No unas nada a `feature/modelo-ng` ni a `master`: sube tus ramas y avísame.

## Quién es quién
- **PC A (equipo A):** coordina todo. Construye la **ola 4** en `feature/modelo-ng`, une las ramas, registra los ADR en `master` y edita `CLAUDE.md`.
- **PC B (este equipo):** trabaja en ramas `b/...` y en el repositorio de Backup Tool; sube sus ramas; **nunca une** a `feature/modelo-ng` ni a `master`.
- **El propietario** firma todo. El arquitecto-maestro de cada equipo solo prepara.

## Reglas
1. Un solo agente editor por árbol; agentes siempre con `model: opus`; respuestas al propietario en español.
2. **No tocar** `feature/modelo-ng` (la ola 4 está cambiando el esquema), `master`, ni el código del núcleo.
3. **ADR:** rango de B del **100 al 129**; B solo los **propone** en sus hojas de firma; A los registra en `master` (`docs/adr/`) tras la firma.
4. SQL Server propio de la PC B (`.\SQLEXPRESS`); `GPOST_TEST_SERVER` nunca apunta a la PC A. Las bases reales del propietario son intocables.
5. **Complementos y conectores (ERP, e-CF) nunca tocan el núcleo de GPOS NG** (ADR-73, cláusula 73.7).
6. Lo que B aprenda va en `traspaso-B-AAAA-MM-DD.md` (en la rama o en la carpeta de la solución); A lo pasa a la memoria común.

## Contexto que cambió desde el 2026-10-06 (resumen; detalle en la memoria del paquete)
- **Ola 3 cerrada** (C-1 cumplida). La rama `feature/modelo-ng` ya trae `master` (ronda 1) y los ADR en `docs/adr/`.
- **ADR-68 a 72** registrados (supervisor, cierre de período, notas de crédito, motivos de anulación, borrador sin número). **ADR-73 firmado (B-1, B-2):** GPOS NG es **auxiliar contable**; el mayor, los asientos y los estados financieros son del ERP del cliente (AdmCloud, Alegra u otro), y los conectores nunca tocan el núcleo.
- **BP2 nunca salió a producción:** no hay costumbres de BP2 que proteger; se aplican las recomendaciones de los especialistas.
- Precisión de **ADR-53**: nodo elegible por sucursal; sucursal en línea con SQLite **después de las olas**; licencia por empresa contando usuarios.
- Agente nuevo: **`especialista-contable`** (usarlo antes de diseñar lo que afecte registros contables).
- e-CF: conectores aparte por proveedor (AdmCloud, IQ Solution); código de modificación **4 = reemplazo de contingencia** (verificado en el formato oficial).

## Tarea 1. Diseño de la ola 3b (solo documentos)
- **Árbol y rama:** `GPOS-B-ola3b`, rama **`b/ola3b-diseno` nacida de `origin/feature/modelo-ng`** (el diseño se construye sobre el modelo nuevo). Solo crea archivos nuevos en `docs/` (por ejemplo `docs/datos/2026-10-xx-ola3b-...`, `docs/arquitectura/...`, `docs/decisiones/2026-10-xx-hoja-firma-ola3b.md`). No edites documentos existentes ni código.
- **Alcance:** transferencias entre sucursales y adjuntos de documentos (bloque separable 3b-A), y la **v2.2 del diseño de adjuntos** con maestro de motivos (Tratamiento, Exigir evidencia, Pedir referencia) y desvinculación por período.
- **Fuentes:** `docs/decisiones/2026-10-05-decision-transferencias-ola3b.md` (DA-01 a DA-05), `docs/pos/2026-10-05-transferencias-y-costos-central.md`, `docs/arquitectura/2026-10-05-adjuntos-documentos.md`, `docs/datos/2026-10-05-adjuntos-modelo-datos.md`, `docs/seguridad/2026-10-05-revision-adjuntos-documentos.md`, `docs/adr/ADR-067.md`, `docs/adr/ADR-053.md` (con la precisión del 2026-10-06), y el modelo ya construido de la ola 3 y la ola 4 (`src/GPOS.Core/Datos/Empresa/`).
- **Observaciones obligatorias:**
  - La guarda de sitio y la prueba del dueño único deben **deducir el sitio dueño a partir de la sucursal** (su nodo si lo tiene; si no, la central): pueden convivir sucursales con nodo y en línea.
  - Adjuntos que son **soporte fiscal**: el análisis contable (HC-16) y la precisión B-3 de ADR-73 (pendiente de firma) piden que no vayan a la papelera de 30 días (conservación de 10 años).
  - P-T13 (la central reconstruye un despacho que nunca aparece) sigue abierta: proponer solución.
- **Agentes:** arquitecto-datos y arquitecto-software (y especialista-pos / especialista-contable si aparece una regla operativa o contable); al final, arquitecto-maestro con la **hoja de firma de la ola 3b**.
- **Entrega:** subir `b/ola3b-diseno` y avisar al propietario.

## Tarea 2. Backup Tool
- **Repositorio:** `C:\Users\lfmen\source\repos\Backup Tool` (`lfmendezb/BackupService`), rama **`fp01-clave-7zip`** (ya en GitHub). No crear PR a la rama principal sin aviso.
- **Trabajo:**
  1. **Auditor-seguridad:** confirmar que FP-01 queda cerrado (AP-07), con evidencia.
  2. **Bloquear la subida a Drive sin llave activa:** recomendado «sí»; el arquitecto-maestro de B prepara la hoja de firma y, **si el propietario firma**, se construye con pruebas.
  3. **Fuente de respaldo de tipo carpeta** para los adjuntos de GPOS NG (estimado de 1,2 a 1,8 sp): diseño primero, construcción tras la firma.
- **Pendiente del propietario (no del agente):** comparar el literal del commit `1bd735f` (`tests/BackupService.Tests/ApiKeySecurityTests.cs:123`) con la clave heredada real, y ejecutar L-2 a L-5 y K-1 a K-5 en cada instalación.
- **Entrega:** subir la rama y avisar al propietario.

## Rutina diaria
Al empezar: `git fetch origin` y traer la rama base (`origin/feature/modelo-ng` para `b/ola3b-diseno`). Al terminar cada bloque: `git push -u origin HEAD` y avisar en la PC A: «B subió `b/...`».
