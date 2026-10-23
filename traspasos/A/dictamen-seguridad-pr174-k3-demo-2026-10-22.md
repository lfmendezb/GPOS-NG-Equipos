# Dictamen de seguridad del PR #174 (K3-DEMO cerrojo 2 y DM-04) · equipo A · 2026-10-22

Alcance: `ModoServicioApi.ComprobarClaveJwtEnEntorno`, `RetirarClaveJwtDelEntorno`, `ProtegerClaveJwt`, la llamada en `Program.cs` y `ClaveJwtEntornoTests`. Marcas: [V] verificado; [I] inferido. Es código mío; dictamen aparte de la construcción.

**Recomendación: Aprobar con una corrección ya hecha (JWT-01); unir antes del 2-nov (DB-7).**

## Correcto [V]
- Falla cerrada: servicio con la clave en el entorno y sin modo `Amplio` escrito → rechaza con `ARRANQUE_JWT_ENTORNO`; sin modo, vacío o distinto (`Ampl`, `AmplioX`) también. Consola no se comprueba (C-10).
- El motivo nombra la variable y el modo, nunca el valor (prueba con el valor y su prefijo).
- DM-04: tras retirar la variable del proceso, la configuración ya cargada conserva la clave y un hijo (`cmd.exe`) no la hereda; no toca el valor guardado en el registro del servicio.
- `Program.cs`: una sola llamada, después de construir la configuración y antes de la escucha y de leer la sección `Jwt`; la prueba fija el orden.

## Hallazgo
- **JWT-01 (Media, corregido en `a/api-jwt-entorno`, commit local):** el cerrojo y la retirada solo miraban `Jwt__Clave`. En Windows el proveedor de variables de entorno también lee **`Jwt:Clave`** con dos puntos [I; la prueba nueva lo comprueba: la configuración devuelve la clave]. Con esa grafía la clave llegaba a la configuración sin pasar por el cerrojo (en un servicio sin modo `Amplio`) y los hijos la heredaban. Ahora se comprueban y se retiran las dos grafías. Prueba: `La_grafia_de_dos_puntos_llega_a_la_configuracion_y_se_retira_del_entorno`; 17/17 en `ClaveJwtEntornoTests`.

## Observaciones
- **JWT-02 (Baja):** la clave sigue en memoria del proceso y en el valor del registro del servicio (legible para Administradores). Es la excepción K3-DEMO firmada, solo DEMO, con sus cuatro cerrojos y caducidad; el dictamen no la amplía.
- **JWT-03 (Baja) [I]:** el modo se lee con `ClaveModoIdentidad` desde la configuración. Si el modo efectivo del resto de la API se resolviera por otra vía (por ejemplo, desde `GPOS_SYSDATA`), podrían diferir. Comprobar en la integración con PR-D2 que ambos leen la misma fuente.
- **JWT-04 (Baja):** la prueba del orden en `Program.cs` es de texto (frágil ante reformateos); aceptable, pero si cambia `Program.cs` en PR-4 hay que mantenerla.

## No verificado
Arranque real como servicio en la VM (P-8); el efecto en el proceso del navegador del PDF.
