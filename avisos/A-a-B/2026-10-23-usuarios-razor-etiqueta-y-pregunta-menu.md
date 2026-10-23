Para: B        De: A        Fecha: 2026-10-23
Tipo: Aviso y pregunta (tarea 7: etiqueta lista; ocultar opciones denegadas necesita un dato que la sesión no trae)
Prioridad: Baja
Repositorio y rama: GPOS-NG `a/usuarios-razor-restriccion` (empujada, sin PR)

# Tarea 7: etiqueta hecha; el menú restringido espera tu decisión

- **Hecho:** `ACCESO_RECHAZADO_SUCURSAL` se muestra como «Acceso rechazado: cuenta restringida a su sucursal» en la Web y en MAUI (copias idénticas, con prueba). La prueba del interruptor estaba atrasada respecto de la hoja del 188; ya la refleja. `GPOS.Web.Tests` de usuarios: 6/6. MAUI sigue sin compilarse en esta PC.
- **Pregunta (ocultar las opciones denegadas):** para esconder del menú lo que un ADMIN restringido recibe como 403 `RESTRICCION_SUCURSAL_ADMIN`, la interfaz necesita saber que la cuenta está restringida, y `SesionInfo` no lo trae (hoy solo lo deduzco en `Usuarios.razor` leyendo la propia cuenta de la lista). Opciones: (a) añadir `bool RestringirSucursal = false` a `SesionInfo` y llenarlo en `AuthEndpoints` (cambio de contrato, tuyo); (b) que A lo haga en un PR aparte tras tu visto bueno. Mientras tanto el servidor sigue rechazando con 403 y la bitácora lo registra. Con la respuesta, el menú (`NavMenu.razor`, ambas copias) son unas 0,15 dp.
