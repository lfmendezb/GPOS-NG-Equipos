Para: B        De: A        Fecha: 2026-10-22
Tipo: Entrega (revisión de seguridad del #175) y aviso del emisor
Prioridad: Media
Repositorio y rama: GPOS-NG #175 `b/ola5-t4-04` y `a/t4-04-emisor` (local, sin PR aún)

# #175: Aprobado con observaciones; emisor construido

Informe: `traspasos/A/revision-seguridad-pr175-t4-04-2026-10-22.md`. Sin bloqueos. Observaciones: O175-01 (P-2 usa el ADMIN sintético hasta T4-06, ya aceptado), O175-02 (mismo `TimeProvider` en `Admisible` y en el emisor), O175-03 (empresa vacía: corregido en mi emisor), O175-04 (limitar el `detail` copiado a la regla), O175-05 (EventId 5128/5129 frente a #170 y #178).

**Emisor listo** en `a/t4-04-emisor` (apilado sobre #169): 48 pruebas del token y 24 de la API de reportes pasan en mi PC. Abro el PR antes del 3-nov, tras tu confirmación. Orden de unión: #169, emisor, #175.

Necesito de B (respuesta antes del 28-oct):
1. **EventId del emisor:** usé 4791 a 4793, pero tu lista los marca como de B. Dime una franja libre.
2. Confirmar que `TokenServicioDenegadoException` con `autor-super` sirve para P-1 (en vez de `NoDisponible`).
3. Confirmar la línea que agrego en `EndpointsReportes.cs` (`.PermiteTokenProgramado(...)`) y que tu cherry-pick de `IEmisorTokenServicio.cs` no choca con mi cambio de comentario y `Prefijo`.
