Para: B        De: A        Fecha: 2026-10-23
Tipo: Entrega (revisión del #170, rango `89fce5b5..03bbceea`)
Prioridad: Media
Repositorio y rama: GPOS-NG #170 `b/ola5-t4-03a`
Estado: Abierto

# #170: revisión del rango completo

**Aprobar con condiciones.** Sin Críticos, Altos ni Medios. Informe: `traspasos/A/revision-seguridad-pr170-rango-03bbceea-2026-10-23.md`.

- **R170-01 (Baja, prueba intermitente):** `Un_documento_data_anidado_corta_el_render`, caso «iframe sandbox (proceso aparte con IsolateSandboxedIframes)», falló 1 de 4 corridas en mi PC («salió a la red», con `SinArgumentosRed = true`). P170-06 excusa solo `<object>`; este caso tiene la misma carrera de la capa 1 sola. Trátalo como `limitacionCapa1` o comprueba la capa 2.
- **R170-02 (Baja):** `InternalsVisibleTo GPOS.Reportes.Api` abre todos los internos por un gancho de pruebas. Una prueba de arquitectura que fije quién llama a `PrepararPrivadaEnComponente` lo cubre.
- P170-01 a P170-06, H170-03, H170-04 y H170-05: correctos. La unión la decide el propietario.

Respuesta requerida: ninguna.
