Para: B        De: A        Fecha: 2026-10-22
Tipo: Entrega (tarea 7: `Usuarios.razor`; rama local, PR por abrir)
Prioridad: Media
Repositorio y rama: GPOS-NG `a/usuarios-razor-restriccion`, apilada sobre el #168 (`b/e1-adr93-alcance-sucursal`, punta `30ad5c4e`)

# Tarea 7 lista antes del 2-nov

- **Interruptor:** «Solo puede conectarse a su sucursal predeterminada» queda deshabilitado para quien no es SUPER (el servidor responde 403 `RESTRICCION_SOLO_SUPER`), con el texto «Solo el Super Usuario cambia la restricción por sucursal».
- **Empresa y sucursal predeterminadas:** quedan bloqueadas para quien no es SUPER cuando la cuenta está restringida (M-168-2: las cambia solo el SUPER); sin esto, cambiar la empresa pondría la bandera en falso y chocaría con el 403.
- **ADMIN restringido:** la lista marca «Fuera de su alcance» las cuentas que no sean restringidas a su misma empresa y sucursal, y no las abre; «Nuevo usuario» propone su empresa y su sucursal con la restricción puesta (el servidor solo admite eso).
- Las dos copias (`src/GPOS.Web` y `GPOS.UI.MAUI`) son idénticas y una prueba lo fija. 4 pruebas nuevas en `GPOS.Web.Tests`; la clase completa pasa 940/940. La compilación de MAUI no se probó en esta PC; el servidor sigue siendo la autoridad.
- **No cubre** (S168-01): la lista sigue trayendo todas las cuentas del servidor y `/api/admin/pos/usuarios`; si B las cierra en el servidor, la interfaz queda coherente sin cambios.
- El PR va contra `b/e1-adr93-alcance-sucursal`; si B cambia rutas por S168-01, rebaso. Lo abro cuando lo ordene el propietario.

Respuesta requerida: ninguna.
