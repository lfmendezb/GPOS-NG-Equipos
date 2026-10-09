---
name: siguiente-paso-pc-b
description: "Traspaso del equipo B al EQUIPO NUEVO (2026-10-09): mudanza a una PC de mayor capacidad que podría pasar a ser la principal; ramas, pendientes del propietario y de A"
metadata:
  node_type: memory
  type: project
  originSessionId: 04973234-ae57-4e21-9499-3cc3a1aeef9e
  modified: 2026-10-09T23:07:12.342Z
---

**Actualización 2026-10-09 19:10 (primera sesión en el equipo nuevo, OSHIN-LEGION, 16 núcleos, 31 GB):** el propietario ya decidió que **B coordina** desde este equipo y la PC A pasa a soporte (ramas `a/`, no une); aviso `2026-10-09-coordinacion-pasa-al-equipo-nuevo` del área común. El traspaso más reciente es `GPOS-NG-Equipos\traspasos\B\2026-10-09-traspaso-B-corte-de-luz.md`: retomar la ola 5 tramo 2 en `b/ola5-tramo2-wip` (`f1d6025`), y la hoja «Por despachar» PF-01 a PF-06 está por firmar. Entorno: dos instancias SQL Server 2025, `.\SQLEXPRESS` (Express, permisos corregidos por el propietario) y `.` (Standard Developer); el propietario pide **probar en ambas** (la segunda con `GPOST_TEST_SERVER=.`). Identidad de Git global: `Leonardo <lfmendezb@live.com>`. No hay Python en este equipo. Tramo 2 retomado el 2026-10-09 ~19:30 con un agente de backend (sin commit; lo hace el coordinador).

Traspaso del equipo B del 2026-10-09. El propietario cambia la PC B por un equipo **de más capacidad que la PC A**, que **posiblemente pase a ser el principal**. Esa decisión es del propietario y no se da por hecha: hasta que la tome, A sigue coordinando ([[dos-equipos-a-coordina]]). **Sin agentes activos al cerrar.** Instrucciones de instalación: `paquete-pc-b-2026-10-09\LEEME-cambio-de-equipo-B.md`.

## Al abrir la primera sesión en el equipo nuevo
1. **Regla 8:** programar con `CronCreate` la revisión del área común cada 30 minutos, en los minutos 7 y 37, con `& "<repos>\GPOS-NG-Equipos\herramientas\Revisar-AreaComun.ps1" -Equipo B` ([[revision-area-comun-30-min]]).
2. Si el equipo nuevo tiene más memoria y núcleos, proponer al propietario un límite de agentes nuevo. Hasta su respuesta rige [[limite-agentes-pc-b]].
3. Los commits los hace el coordinador. Los agentes **no** ejecutan instaladores, servicios, programas con ventanas ni intérpretes ([[agentes-sin-ventanas-ni-instalaciones]]). Se lanzan con Opus ([[agentes-con-opus]]).
4. Nombre: «GPOS Argón» al hablar con el propietario ([[nombres-de-version-tabla-periodica]]).

## Ramas de B (todo subido a GitHub el 2026-10-09)
| Carpeta | Rama | Último trabajo |
|---|---|---|
| `Solucion GPOS NG\GPOS NG` | `master` | ADR-113 con las precisiones KD, del conduce diario y del canal JSON de Polaris en ADR-124 (`817b939`, `79590b2`, `1ad8b9e`) |
| `GPOS-B-ola5-construccion` | `b/ola5` | API de reportes, tramo 1: reportes 17, 18 y 20 (`fba132e`), 216 pruebas correctas |
| `GPOS-B-ola5` | `b/ola5-diseno` | Reportes por vertical, RPV-01 a RPV-14 (`6463f51`) |
| `GPOS-B-verticales` | `b/verticales-diseno` | Kits y doble descuento (`2d5da51`); producción de recetas y merma de cocina, PR-01 a PR-18 (`c58d34f`) |
| `GPOS-B-admcloud` | `b/conector-admcloud-diseno` | Contrato del conector con la muestra del kit PAQ0001 (`1f7d358`). **Falta** cambiar 4.9.5 de `InventoryAdjustments` a `Dispatchs`, según la cuarta precisión de ADR-113 |
| `GPOS-B-kds-k1` | `b/kds-k1-pasada2` | Unido por A (59921ba) |
| `GPOS-B-lic` | `b/lic-v32` | Unido por A |
| Otros | `b/ola3b-diseno`, `b/restaurante-kds-diseno`, `b/inventario-negativos-diseno`, `b/farmacia-principio-activo`, `b/conector-polaris-diseno` | Diseños ya entregados |
| Repositorios aparte | `GPOS-NG-AddOn-Kit` (main), `GPOS-NG-AddOn-Polaris` (main, c990f1a), `GPOS-NG-AddOn-IQS*` | Kit alfa.5 en `gsf-local` (copiado en el paquete) |

## Pendiente del propietario
- **Por firmar:** PR-01 a PR-18 (producción y merma de cocina) y RPV-01 a RPV-14 (reportes por vertical). Al firmar PR, registrar en ADR-113 la decisión (M)/(S) del 2026-10-09: el elaborado es artículo en AdmCloud; con manufactura usa `ProductionBuilds`, sin ella usa conduce más ajuste positivo.
- **Por ejecutar** (lo hace el propietario; el clasificador no deja al agente usar credenciales de la base): `herramientas\Consultar-ConduceAjusteAdmCloud.ps1`. Es de solo lectura y verifica el conduce sin factura, el pendiente de facturar y `DebitAccountID`.
- **P9 de Polaris:** detenida por PQ-25. La guía «Inicio rápido» se siguió tal cual y falla. Para destrabarla, el propietario registra una empresa de pruebas en el portal de Polaris (ambiente 1). PQ-26 a PQ-30 esperan a Polaris.
- **C-47 a C-50 para el contador:** falta saber si se agregan a la adenda (texto en el análisis de kits). Alta de kits por la API: aplazada y fuera de la v1 (KD-08).

## Esperando a A (A estaba en las pruebas de T-28)
- La tanda UF-05, SEC-KP-10, 12 y 18 de T-29, el paso previo del punto 3 de ADR-77, la cola de ADR-114, V-08 y la construcción de la ola 3b.
- Al unir `b/ola5`: agregar `src/GPOS.Reportes/Consultas/` y `Ejecucion/` a `Permitidos` de `SqlSoloEnLugaresPermitidosTests`.
- Hallazgos H-RV-01 (costo de la venta del restaurante y de «Por despachar») y H-RV-02 (propina en 0 en `fiscal.Comprobante`), avisados en `1aef73b`.

## Siguiente trabajo posible de B
- **Ola 5:** tramo 2 (contexto desde `rptsis` y rutas HTTP). Antes, el arquitecto-software define cómo se traducen los filtros y la paginación.
- **Polaris:** completar el flujo contra el simulador local hasta que se destrabe PQ-25.
- **Conector de AdmCloud:** que el arquitecto-integraciones corrija 4.9.5 (conduces) y agregue las variantes (M)/(S) de la producción.
