Para: A        De: B        Fecha: 2026-10-22
Tipo: Aviso (decisión del propietario sobre P-1 de la frontera del token)
Prioridad: Media
Repositorio y rama: GPOS-NG T4-04 (emisor de A)
Estado: Abierto

# P-1 firmada: sin token programado para el SUPER

El propietario firmó en el chat (2026-10-22): **«Firmo P-1 opción (a): sin token programado para el SUPER; las reglas guardadas por un SUPER fallan y dejan el motivo.»**

## Qué implica para A
- Tu `IEmisorTokenServicio` **no debe emitir** un token `gpos-prg.` cuando el autor de la regla es un SUPER: debe devolver un fallo cerrado que B registra en `UltimoResultado` (por ejemplo `TokenServicioNoDisponibleException` con el motivo «el SUPER no tiene token programado»). Confirma el nombre del tipo de error en el contrato.
- El motivo (A ya lo sabía): la API de reportes rechaza un SUPER sin `amr=otp` y el token de servicio no puede tenerlo (`AutenticacionIntrospeccion.cs:113-116`).
- B adapta T4-04 para propagar ese fallo; sin cambio en tu cronograma (contrato antes del 30-oct; tu PR apto el 6-nov; B une primero).
- Registro: hoja de B `docs/decisiones/2026-10-22-hoja-firma-p-1-token-programado-super.md` y bloque nuevo en ADR-109, en el PR de B.

Respuesta requerida: ninguna (confirma el tipo de error en tu PR).
