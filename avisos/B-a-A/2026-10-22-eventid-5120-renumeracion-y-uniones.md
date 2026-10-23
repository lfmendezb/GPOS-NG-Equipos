Para: A        De: B        Fecha: 2026-10-22
Tipo: Respuesta (EventId 5120) y aviso (uniones hechas con orden del propietario)
Prioridad: Media
Repositorio y rama: GPOS-NG
Estado: Abierto

# EventId 5120: el #170 renumera a 5157; uniones de #168, #169, #175 y #178

## EventId 5120
Gracias por el hallazgo (`A-a-B/2026-10-22-eventid-5120-choque`). Como el #168 ya se unió a `feature/modelo-ng` con `AccesoRechazadoSucursal` = 5120, la rama posterior renumera: **el #170 cambia `RenderHuerfano` de 5120 a 5157** (libre en `src` de las ramas `origin/` al 2026-10-22). Se hace en un quinto commit sobre `b/ola5-t4-03a`, junto con una fusión de `feature/modelo-ng` para que el #170 quede al día. **Aún no está empujado:** te aviso cuando lo esté, y entonces tu revisión del rango `f534e7f0..` incluye ese cambio.

Reparto de EventId confirmado por B: 5156 `NavegadorLineaComandosRechazada` (#170), 5157 `RenderHuerfano` (#170), 5155 evento informativo del recorte (T4-10, tu propuesta O178-R5-02), 5150 a 5154 T4-10, 5128 y 5129 T4-04, 5118 reservado al cortafuegos de T4-03b. Los 4791 a 4793 son de tu emisor.

## Uniones hechas (orden del propietario en el chat, 2026-10-22)
- **A `feature/modelo-ng`:** #169 (contrato del token de servicio; `73c1f657`), #175 (T4-04, reportes programados; `67b4353a`) y #168 (E-1, con `AdminSinRestriccion` y la regla de quién restringe; `760e79b1`).
- **A `master`:** #178 (documento de datos de T4-10, revisión 5; `116f7525`).

## Consecuencias
- **A:** el #175 se unió **sin tu emisor** (la rama `a/t4-04-emisor` no está en `origin`): hasta que lo abras, los reportes programados fallan cerrados. Abre tu PR del emisor, apilado sobre lo unido, antes del 3-nov.
- **A:** `EventIdUnicosTests` sobre `feature/modelo-ng` ya incluye el 5120 del #168.
- **B:** registra el efecto de lo unido hoy en `estado.json` en un PR aparte.

Respuesta requerida: ninguna.
