---
name: motor-reportes-blazor-pendiente
description: Blueprint v2 (definición JSON + componentes Blazor precompilados) para sustituir Crystal; pasar al arquitecto-maestro después de la presentación
metadata:
  node_type: memory
  type: project
  originSessionId: 2d7f126f-da10-49d8-816e-0263756730c0
  modified: 2026-10-03T19:29:51.622Z
---

El 2026-10-03 el propietario presentó dos blueprints hechos con Copilot para sustituir Crystal Reports:
- `Solucion GPOS NG\blueprint-razor-jsoncanon.md` (v1): Razor editable con caja de arena. **Descartado como alternativa a Liquid**: filtrar palabras no impide ejecutar C# y contradice ADR-38 y ADR-42.
- `Solucion GPOS NG\blueprint-razor-jsoncanon-v2.md` (v2): la definición se guarda en JSON y se renderiza con componentes Blazor precompilados (`HtmlRenderer`).

El propietario aprobó **pasar la v2 al arquitecto-maestro después de su presentación al socio** (no antes; mientras tanto no lanzar agentes).

Síntesis recomendada que debe recibir el arquitecto-maestro:
1. Diseño gráfico: JSON a componentes precompilados, en lugar de `GeneradorRazor`, que hoy compila Razor en cada impresión (elimina el riesgo R-12). Podría adelantarse a la fase 3.
2. Modo código del ADMIN: Liquid con Fluid (la sintaxis `{{ }}` de la v2), no "Razor-Lite" traducido a Razor.
3. Razor solo del SUPER, como legado (ADR-38).
4. Fórmulas: evaluador propio con lista blanca, **no Dynamic LINQ** (CVE-2023-32571, por confirmar).
5. Contrato de impresión versionado con JSON Schema (de la v1): sirve a la lista blanca de Liquid, al catálogo de campos y a la IA.
6. La IA genera JSON o Liquid, nunca Razor.

Huecos de la v2 por resolver:
- paginación en Chromium (encabezado y pie por página, "Página X de Y"), con prueba de concepto;
- exportación a Excel desde los datos (ClosedXML), no desde el HTML;
- QR obligatorio para e-CF (ADR-51).

No aplica a GPOS NG: multi-tenant, marketplace (ADR-43) y el diálogo de impresión del WebView para tickets.

**Why:** cambia ADR-42 solo como precisión: el diseño gráfico se renderiza con componentes precompilados en lugar de generar Liquid. La firma el propietario.

**How to apply:** después de la presentación, encargar al arquitecto-maestro la decisión formal, con estimaciones del arquitecto-software y la revisión del auditor-seguridad del evaluador de fórmulas. Base de brechas: `docs/ux/2026-10-02-disenador-formatos-crystal-xi.md`.

Relacionado: [[firma-humana-arquitecto-maestro]].
