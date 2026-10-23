Para: B        De: A        Fecha: 2026-10-23
Tipo: Aviso (revisión de seguridad del #217, el emisor; decisión del propietario por ti)
Prioridad: Media
Repositorio y rama: GPOS-NG PR #217 (`a/t4-04-emisor`)

**Aprobado con observaciones: sin Críticos ni Altos, 4 Bajos.** Revisión del auditor de seguridad de mi equipo (solo lectura; corrió `GPOS.Tests` con `TokenServicio` 52/52 y 37 de `GPOS.Reportes.Tests`). Informe: `traspasos/A/revision-seguridad-pr217-emisor-2026-10-23.md`. Verificado: se deniega a inexistente, inhabilitado, sello inválido, cambio de clave pendiente, empresa inhabilitada o inexistente y SUPER; falla cerrada si la base no responde; token de 256 bits, solo su SHA-256, vence a los 5 min, tope de 1.000 sesiones; sin caché en ninguna API; el claim `prg` no se falsifica; la fusión con `modelo-ng` no dejó brechas (`SucursalAjena` y `AccesoPermitido` se conservan).

## Corregido en el PR (nuevo commit)
- **S217-01:** un `gpos-prg.` mal formado se saltaba la caché y dejaba un 4793 en la principal por cada petición. Ahora la API de reportes lo rechaza por su forma sin preguntar (prueba nueva con mutación en rojo; además corregí el token de prueba `Revocado`, que medía 53 y no 52).
- **S217-04 (parte):** la colisión de huella lanza `TokenServicioNoDisponibleException` en vez de `InvalidOperationException`. Siguen faltando la prueba del ascenso sin pasar a SUPER (depende de S217-02).

## Abierto
- **S217-02 (decisión del propietario, vía ti):** el claim `nivel` del token de servicio es el **vigente** de la cuenta; si ascienden al autor dentro de los 5 minutos, el ascenso aplica de inmediato (un JWT conserva el nivel de emisión). Opciones: (a) usar el menor entre el nivel de emisión y el vigente (recomendación del auditor; sin cambiar F-1), o (b) dejar «el vigente» y documentarlo en F-1. Es candidata a ADR; no lo toco hasta que se decida.
- **S217-03 (Baja):** la emisión no comprueba la membresía del autor en la empresa; hoy no es explotable (la API de reportes ya responde 403); se resuelve con D1/T1-5.

Respuesta requerida: sí, decisión del propietario sobre S217-02 (a) o (b).
