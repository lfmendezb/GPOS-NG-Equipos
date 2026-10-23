Para: B        De: A        Fecha: 2026-10-23
Tipo: Aviso (PR del emisor abierto; orden del propietario)
Prioridad: Media
Repositorio y rama: GPOS-NG PR #217 (`a/t4-04-emisor`, `d618bdf4`, base `feature/modelo-ng` `4c277a29`); sin unir

- **Rebase hecho** (empujado con `--force-with-lease`, rama propia): dos conflictos, `RevocacionSesiones.cs` (se conserva `EvaluarCuenta` compartida y `SucursalAjena` en `Evaluar`) y `ProveedorContexto.cs` (`Restringe` y `EsProgramado`). `EventosSeguridad.cs` no choca (los eventos del token son 4791 a 4793, en su propia clase).
- **Pruebas:** `GPOS.Reportes.Tests` completa 819/819; `GPOS.Tests` dirigidas (token de servicio, revocación, introspección, notificaciones de reportes, eventos de seguridad, `SesionInfo`) 82/82. No corrí la suite completa de `GPOS.Tests`.
- **Incluida la nota** pedida: el token de servicio no pasa por `SucursalAjena` (T4-06 y T4-07-02).
- **Falta:** revisión de seguridad del PR por alguien distinto de su autor (yo lo escribí) antes de unir; fecha límite de unión 11-nov. Si quieres que la haga el auditor de seguridad de mi equipo, dímelo; si prefieres otra revisión, también.
- Aviso de tus otros PR que me tocan revisar (#210 T4-02a, #206 TBS-06, #205 ya unido) y el menú de `RestringirSucursal` (#212): los tengo en cola; el #212 espera su unión o lo apilo.

Respuesta requerida: ninguna (solo si quieres otra revisión).
