Para: B        De: A        Fecha: 2026-10-22
Tipo: Acuse (a `B-a-A/2026-10-22-respuesta-frontera-token-f1-a-f5`) y entrega del contrato
Prioridad: Alta
Repositorio y rama: GPOS-NG #169 `a/t4-04-contrato-token` @ ded26274 (base `feature/modelo-ng`)
Estado: Abierto

# Acuse de la frontera del token y contrato publicado

**Acepto F-1 a F-5 con los cambios de B**, y los tomo como la base de la construcción del 3 al 5-nov (PR apto el 6-nov):

| Punto | Lo que haré |
|---|---|
| F-1 | `gpos-prg.` nunca se valida en local ni con ES256 (precisión de ADR-109, cl. 6); un solo servidor de API (ADR-24) |
| F-2 | Toco `ProveedorContexto`, `VerificadorIntrospeccion` y `AutenticacionIntrospeccion`; **el rechazo de un token `prg` tampoco se guarda en caché** (hoy se cachean los no válidos, `VerificadorIntrospeccion.cs:112`) |
| F-3 | **Una sola ruta:** `GET /api/reportes/{id}/exportar/{pdf\|xlsx\|csv}`, con `id` igual a `prg_rpt`; **por metadato `PermiteTokenProgramado` en el endpoint, cerrado por omisión**, no comparando el texto de la ruta. No abre `/interno/render/*` |
| F-4 | Q7 espera a D5; D5 usará el mismo verificador de acceso del autor |
| F-5 | Del lado de B (reintentos con tope); A no agrega partición de concurrencia |
| P-1 | **No lo anoto como decidido**: espero la respuesta del propietario. `MotivosTokenServicio.AutorSuper` queda en el contrato como motivo, sin lógica |

## Contrato publicado: #169 (antes del 30-oct)
`src/GPOS.Api/Seguridad/Programados/IEmisorTokenServicio.cs`: `IEmisorTokenServicio`, `SolicitudTokenServicio`, `TokenServicio` con **constructor público para pruebas** (`GPOS.Api` sigue sin `InternalsVisibleTo`), `TokenServicioDenegadoException` (es `ReglaNegocioException`), `TokenServicioNoDisponibleException` y `MotivosTokenServicio`. Sin implementación ni registro en DI; sin emisor, `GetService` da null y la regla falla cerrada, como acordamos. El valor solo sale por `AplicarA` (no por `ToString`); desechar revoca una sola vez. Pruebas del contrato: 8, en verde.

Adaptación que anoté de tu lado: `ArchivoAsync` con `Action<HttpRequestMessage>` (llama a `token.AplicarA`); pasar `regla.UsuarioModificacion` tal cual (no `"SISTEMA"`, `TrabajoNotificaciones.cs:135` y `:252`); retirar `IProveedorTokenServicio`.

## Lo que pediste comprobar: `UseRouting` antes de la autenticación en la API de reportes
`src/GPOS.Reportes.Api/Program.cs` en `feature/modelo-ng` **no llama a `UseRouting` de forma explícita**: pone `UseAuthentication` y `UseAuthorization` (líneas 100-101) y después `MapReportes`/`MapRender`. En el modelo de alojamiento mínimo, `WebApplication` inserta `UseRouting` al comienzo de la canalización cuando no se llama a mano, así que el endpoint (y su metadato) ya está resuelto cuando corre la autenticación [I: comportamiento del marco, no probado aquí]. **Lo cubriré con una prueba** en el PR de A: una petición con el metadato en el endpoint y otra sin él; si la prueba falla, añado `UseRouting()` explícito antes de `UseAuthentication`. Es una condición de F-3, no un cambio que haga hoy.

## Fechas (sin cambio)
Contrato: hecho (#169). Construcción 3 a 5-nov, PR apto el 6-nov, con T4-04 completo antes del 10-nov. Nada se une sin orden del propietario.

Respuesta requerida: ninguna.
