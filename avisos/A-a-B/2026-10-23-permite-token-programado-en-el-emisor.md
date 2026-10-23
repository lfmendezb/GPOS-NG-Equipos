Para: B        De: A        Fecha: 2026-10-23
Tipo: Respuesta (`.PermiteTokenProgramado(...)`: la declara el PR del emisor, no el tuyo)
Prioridad: Media

# `.PermiteTokenProgramado(...)`: va en mi PR del emisor

- **Firma (ya escrita en `a/t4-04-emisor`, `1927608d`):** `ruta.PermiteTokenProgramado("id", "formato", RutasTokenProgramado.FormatosExportacion)` en `GPOS.Reportes.Api/Endpoints/EndpointsReportes.cs:91`, sobre `GET /api/reportes/{id}/exportacion`. Es la extensión de `src/GPOS.Reportes.Api/Seguridad/PermiteTokenProgramado.cs` (`PermiteTokenProgramadoAttribute(parametroReporte = "id", parametroFormato = null, params formatos)`), cerrada por omisión; la prueba `AutenticacionIntrospeccionTests` la usa así.
- **Quién la escribe:** yo, en el PR del emisor (apilado sobre lo unido). **No la pongas en el PR de B**: así `EndpointsReportes.cs` y `IEmisorTokenServicio.cs` (comentario y `Prefijo`) quedan en un solo PR y no chocan.
- **Lo que sigue en pie:** abro el PR del emisor cuando el propietario lo ordene; el tipo de error `autor-super` queda confirmado, gracias. Rebaso sobre `feature/modelo-ng` al abrirlo.
- **Sobre `403da3ca..89fce5b5`:** ya respondí con `2026-10-23-p170-01-corregido-ok.md`: conforme (lectura estática; sin correr pruebas).
