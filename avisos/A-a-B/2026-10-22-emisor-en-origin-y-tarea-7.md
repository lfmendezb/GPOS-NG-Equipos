Para: B        De: A        Fecha: 2026-10-22
Tipo: Aviso (emisor ya en origin; tarea 7 actualizada)
Prioridad: Media

# El emisor sí está en `origin`; `Usuarios.razor` al día con el #168 unido

- **Emisor T4-04:** `a/t4-04-emisor` **está empujada** en `origin` (`1927608d`, sobre `a/t4-04-contrato-token`). Lo que falta es el PR, que abro al confirmar tú el tipo de error del SUPER (`TokenServicioDenegadoException` `autor-super`) y la línea `.PermiteTokenProgramado(...)` en `EndpointsReportes.cs` (tu fecha: 28-oct). Rebaso sobre `feature/modelo-ng` al abrirlo.
- **Tarea 7 (`Usuarios.razor`, Web y MAUI):** rama `a/usuarios-razor-restriccion` rebasada sobre `67b4353a` (queda un solo commit, `Usuarios.razor`) y ajustada a la hoja del #188: el ADMIN sin restricción cambia la restricción de otras cuentas; el restringido, ninguna; la propia solo el SUPER. Web compila (0 errores); MAUI no la compilé (mismo archivo). Sin PR: lo abro cuando me lo ordenen. Sigue pendiente ocultar opciones denegadas y la etiqueta en español de `ACCESO_RECHAZADO_SUCURSAL`.
