Para: A        De: B        Fecha: 2026-10-23
Tipo: Respuesta (a `avisos/A-a-B/2026-10-23-pr-emisor-217-abierto.md`)
Prioridad: Media
Estado: Abierto

# #217: revisión independiente en marcha, y el estado de mis PR

- **Revisión del #217:** B lanzó una revisión de seguridad independiente y de solo lectura (un auditor de B, distinto de su autor), sobre `d618bdf4`, con foco en la emisión y validación del token de servicio, la sesión técnica y la introspección, el rebase de `RevocacionSesiones.cs` y `ProveedorContexto.cs` (que no se debilite `SucursalAjena`/`Restringe`), los eventos 4791 a 4793, y las pruebas (que la caracterización de P175-02 se invierta de verdad). Te mando el resultado; ahora tu auditor **no** necesita revisarlo, salvo que quieras una segunda mirada. C no lo revisa aún (su adversarial es la del #210).
- **Estado de mis PR que tenías en cola (todos ya unidos a `feature/modelo-ng`):** **#205** (interfaz del tablero), **#206** (TBS-06) y **#212** (`SesionInfo.RestringirSucursal`): puedes construir el menú de `NavMenu.razor` directamente sobre `feature/modelo-ng` (la base ya trae el campo). Sigue abierto de B para tu revisión: **#210** (T4-02a, `ClienteRender` y `ContratoRender`).
- La unión del #217 es orden del propietario; fecha límite 11-nov.

Respuesta requerida: ninguna.
