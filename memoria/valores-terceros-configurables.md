---
name: valores-terceros-configurables
description: "Regla del propietario (2026-10-11): ningún valor de un tercero en el código; VT-01 a VT-12 firmadas; ADR-126 por registrar; T1 desde el 14-oct"
metadata:
  node_type: memory
  type: project
  originSessionId: c17693f6-c6e2-465e-ac53-6b0864717f1e
  modified: 2026-10-11T13:36:52.404Z
---

Regla del propietario (2026-10-11): **todo valor que dependa de un tercero (URL, normas DGII, CDN, dominios, tiempos de protocolo) va en appsettings.json o en tabla SQL, nunca en el código**; no debe hacer falta recompilar por un valor.

- Propuesta del arquitecto-integraciones: `docs/propuestas/2026-10-11-valores-de-terceros-configurables.md` en la rama `b/config-terceros` (árbol `GPOS-B-config-terceros`, commit f209a70). 27 hallazgos; P1: URL del padrón RNC y Google Fonts.
- Firmado el 2026-10-11 «Aprobado todo según la recomendación» (VT-01 a VT-12): capas paquete → `%ProgramData%\GPOS NG\config` → entorno → `dbo.ParametroSistema` (SUPER, motivo, temporal); `fiscal.ParametroNormativo` después del corte; zona UTC−4 y formatos estructurales se quedan en código; prueba guarda de valores de terceros.
- **2026-10-14:** ADR-126 registrado en `master` (`f5e73b0`). Quedan libres para B: 127 a 129.
- **T1 unido a `feature/modelo-ng` (`4ace678`) el 2026-10-14:**
  - la URL del RNC en `GPOS:RncDgii:Url` y las pruebas O-3 (`TrabajoRncDgiiUrlTests`);
  - Roboto local en `GPOS.Web/wwwroot/fonts/roboto` (`@fontsource/roboto` 5.1.0, con descarga autorizada por el propietario);
  - la guarda `Arquitectura/ValoresDeTercerosTests`, con una lista de excepciones que solo decrece.
- **Pendientes de T1:** fijar la tanda de G-01 a G-03 (los comentarios `go.microsoft.com` y `aka.ms` de MAUI y la ruta fija de 7-Zip) y confirmar las dos reglas extra de la guarda (correo y `Program Files`).
- Plan: T1 (2 d) al terminar la pausa; T2 (5-6 d) antes del corte; T3 (7-9 d) después; T4 por partes. Pendiente aparte: verificar la serie E en `TiposComprobante.DeCliente` antes del 15-nov ([[ecf-exclusivo-15-nov-2026]]).

**Why:** robustez ante cambios de terceros sin publicar versión.
**How to apply:** en todo código nuevo o revisado, no aceptar URLs, dominios, listas fiscales ni tiempos de terceros escritos en el código. Relacionado: [[pausa-2026-10-10]].
