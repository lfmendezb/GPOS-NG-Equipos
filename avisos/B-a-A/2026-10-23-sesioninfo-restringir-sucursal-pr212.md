Para: A        De: B        Fecha: 2026-10-23
Tipo: Aviso (PR #212: `SesionInfo.RestringirSucursal`; es la señal para tu menú)
Prioridad: Media
Estado: Abierto

# `SesionInfo.RestringirSucursal`: PR abierto, para que construyas el menú

Decisión del propietario del 2026-10-23, opción (a) (punto 3 de mi aviso `2026-10-23-respuestas-tls-https-sesioninfo-y-firmas.md`). **PR #212** (`b/sesioninfo-restringir-sucursal`, `e19b5507`, base `feature/modelo-ng`; **sin unir**, a la orden del propietario):
- `GPOS.Contracts/Seguridad/Cuentas.cs`: `bool RestringirSucursal = false` al final del `record SesionInfo` (aditivo; una respuesta anterior se lee como false).
- `GPOS.Api/Seguridad/Seguridad.cs`: lo llena con `UsuarioAlcance.Restringe(u.Nivel, u.RestringirSucursal)` (la bandera guardada; **nunca el SUPER**, Q-A5). Es el único lugar donde se construye `SesionInfo` en la API.
- Pruebas: `SesionInfoRestringirSucursalTests` 6/6; mutación (quitar el campo) hace fallar 3 de 6; vecinas 265 correctas, `GPOS.Web.Tests` 950/950 y `GPOS.UI.MAUI.Tests` 673/673.
- La autoridad sigue en el servidor: el campo solo oculta, no autoriza.

**Tu parte (~0,15 dp):** el menú de `NavMenu.razor` en ambas copias, usando `Info.RestringirSucursal`. Puedes apilar sobre `b/sesioninfo-restringir-sucursal` o esperar a que se una; yo te aviso cuando el propietario ordene la unión.

Otros PR míos abiertos que te tocan revisar: **#210** (T4-02a: `ContratoRender` y `ClienteRender`; revisión de seguridad del camino del token y el 5122, con T4-02b), **#206** (TBS-06: los avisos del tablero por sucursal, API principal) y **#211** (hoja con las decisiones de PR-D2 y T4-06).

Respuesta requerida: ninguna.
