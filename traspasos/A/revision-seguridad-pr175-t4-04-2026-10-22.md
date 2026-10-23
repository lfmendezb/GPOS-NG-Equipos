# Revisión de seguridad del PR #175 (T4-04, lado de B) · equipo A · 2026-10-22

Alcance: `ReenvioReportes.ArchivoAsync`, `TrabajoNotificaciones` (`EjecucionReglas`), `TokenServicioProgramado`, `EmisorTokenServicioAusente` y `EvidenciaExportacionesService.ParametrosJson`, contra mi emisor (`a/t4-04-emisor`, commits `771357a8` y el siguiente). Marcas: [V] verificado por lectura; [I] inferido. No ejecuté las 616 líneas de pruebas de B ni el extremo a extremo.

**Recomendación: Aprobado con observaciones.** Ninguna bloquea la unión; las dos Medias se cierran antes de D5/T4-06.

## Correcto [V]
- `7b849e35` (contrato): los dos archivos de `Seguridad/Programados` y `ContratoTokenServicioTests.cs` son idénticos a los del #169.
- El autor se pasa como `regla.UsuarioModificacion` tal cual; no hay `"SISTEMA"` (TokenServicioAsync).
- El token se desecha (`await using` dentro del `if`) antes de evidencia y cola de correo. Solo vale para pedir el archivo.
- `Admisible` exige vigente y ≤ 5 min; si no, revoca y falla. Mi emisor trunca `VenceUtc` al segundo, por lo que nunca excede.
- 429 (F-5): máximo 3 reintentos, 90 s, `Retry-After` con tope de 30 s y ≥ 60 s de vigencia; el mismo token, sin pedir otro.
- El token solo se aplica con `AplicarA`; `RedactLoggedHeaders(_ => true)` en el cliente de la canalización; la evidencia guarda `tec-…`, nunca el valor.
- Falla cerrada: sin emisor, `TokenServicioNoDisponibleException` y `TokenServicioDenegadoException` (que es `ReglaNegocioException`, caso SUPER incluido) dejan resultado de regla; sin API de reportes en Release no hay camino local.
- Tope del adjunto con `ContentLength` y lectura acotada; el rechazo de la API de reportes se lee con tope de 64 KB. «Ejecutar ahora» no usa el emisor.

## Observaciones
- **O175-01 (Media, ya conocida y aceptada por el propietario): reportes de la lista P-2** (`Modo` → `Principal` con el reenvío) siguen armándose en la principal con el principal sintético ADMIN, no con los permisos reales del autor [V]. Hasta T4-06 un autor sin «Ver costos» puede recibir costos por correo en esos reportes. Pido que T4-06 lo cierre con prioridad y que la ayuda de la regla lo diga mientras tanto.
- **O175-02 (Media): reloj.** `Admisible` y `ReintentoProgramado` toman `TimeProvider` de `GetService`; mi registro de sesiones usa el `TimeProvider` de DI. Si alguno se sustituye (pruebas, otro registro), un token válido se rechaza o uno vencido se acepta [I]. Hoy ambos son `TimeProvider.System`. Pedir una prueba que fije que `Admisible` usa el mismo reloj que el emisor.
- **O175-03 (Baja): empresa vacía.** `TokenServicioAsync` pasa `EmpresaCodigo ?? ""`. Mi emisor lanzaba `ArgumentException` (acababa en «Error inesperado»). **Corregido en el emisor**: ahora lanza `TokenServicioNoDisponibleException` (prueba nueva). B puede además comprobar la empresa antes de pedir el token.
- **O175-04 (Baja):** el mensaje `detail` del ProblemDetails de la API de reportes se copia al resultado de la regla [V]. La canalización está protegida contra suplantación (`CanalSuplantadoException`), pero conviene limitar el largo del `detail` (hoy hasta 64 KB leídos) antes de guardarlo.
- **O175-05 (Baja):** EventId 5128 y 5129 de B; verificar contra #170 y #178 (5117 a 5119) al reasignar.

## Para unir
- Orden: #169, luego mi PR del emisor (`a/t4-04-emisor`), luego #175 (su `7b849e35` queda sin cambios).
- Mi emisor toca una línea de `EndpointsReportes.cs` (metadato `PermiteTokenProgramado`) y `IEmisorTokenServicio.cs` (comentario y `Prefijo`): B debe confirmar que su cherry-pick no choca.
