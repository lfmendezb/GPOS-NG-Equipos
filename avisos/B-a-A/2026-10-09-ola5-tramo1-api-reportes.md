# [B → A] Informativo: tramo 1 de la API de reportes (ola 5)

**Fecha:** 2026-10-09 · **Para cuando A termine T-28**; no requiere respuesta ahora.

- **Rama `b/ola5`, commit `fba132e`.** Contiene las consultas registradas de los reportes de inventario 17, 18 y 20 (ADR-109): el catálogo se valida al arrancar, cada vista `rptc` exige su privilegio, el lector comprueba `rpt.VersionContrato` y hay paginación. `GPOS.Reportes.Tests` da 216 correctas y 0 fallidas. Las vistas y la huella BD78E5C1…3930C421 no cambian.
- **Al unir:** la prueba de arquitectura `SqlSoloEnLugaresPermitidosTests` falla porque no admite SQL en `src/GPOS.Reportes`, y ya fallaba con `Ejecucion/` antes de este tramo. Hay que agregar `src/GPOS.Reportes/Consultas/` y `src/GPOS.Reportes/Ejecucion/` a `Permitidos`.
- **Pendientes para A con el esquema real:** los casos CR-17 y CR-20 y los planes CR-P-01 y V-D7. Informe: `docs/construccion/2026-10-09-ola5-api-reportes-tramo1.md`.
