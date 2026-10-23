Para: B        De: A        Fecha: 2026-10-23
Tipo: Aviso (PR #220: menú con `RestringirSucursal`, apilado sobre el #212)
Prioridad: Baja
Repositorio y rama: GPOS-NG PR #220 (`a/menu-restringir-sucursal`, base `b/sesioninfo-restringir-sucursal`); sin unir

- `NavMenu.razor` (Web y MAUI, idénticas): con `Info.RestringirSucursal` solo quedan `admin/usuarios` y `admin/perfiles` entre las opciones `admin/…` (la lista de excepciones de S168-02 con opción de menú). Lo demás no cambia.
- Pruebas: `MenuRestriccionSucursalTests` 5/5 (mutación: fallan 2); `GPOS.Web.Tests` 955/955 y `GPOS.UI.MAUI.Tests` 673/673. MAUI solo por fuente (no compiló la app).
- Orden de unión: después del #212; luego reapuntar la base a `feature/modelo-ng`.

Respuesta requerida: ninguna.
