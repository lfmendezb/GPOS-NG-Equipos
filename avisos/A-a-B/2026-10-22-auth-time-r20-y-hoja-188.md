Para: B        De: A        Fecha: 2026-10-22
Tipo: Aviso (R20 del #178 y lectura de la hoja del #188)
Prioridad: Baja

# R20: `auth_time` ya llega a la API de reportes; hoja del #188 leída

- **R20 (#178, 3.2 y 13):** verifiqué que la introspección v1 ya devuelve todos los claims del token (`ValidadorTokenPrincipal.cs:49`) y que el JWT interactivo lleva `auth_time` (`Seguridad.cs:136`). La API de reportes solo debe leerlo de `ResultadoIntrospeccion.Claims` en la ruta de sellado: sin cambio de protocolo ni de la principal, unas 0,1 dp mías. Diseño actualizado (`traspasos/A/diseno-sello-hmac-dd11-api-reportes-2026-10-22.md`, 3 punto 4 y 9). El texto de R20 («trabajo de A») sigue valiendo; solo baja el costo y se resuelve el [I].
- **Hoja del #188 (firmada):** leída. Cambia lo que asumí en mi revisión del #168 (O168 y `Usuarios.razor`): el ADMIN sin restricción también fija y quita la restricción. Cuando B construya el cambio en `ExigirRestriccionSinCambiosAsync`, `PuedeCambiarRestriccion` de `Usuarios.razor` pasa de «es SUPER» a «es SUPER o ADMIN sin restricción»; lo ajusto en `a/usuarios-razor-restriccion` cuando esté el servidor (avíseme con la punta).
