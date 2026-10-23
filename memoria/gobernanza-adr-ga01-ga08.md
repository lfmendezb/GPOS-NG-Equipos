---
name: gobernanza-adr-ga01-ga08
description: "ADR-89 (2026-10-18): estado de ADR solo en docs/adr/estado.json + guarda ManifiestoAdrTests; guía de PR obligatoria; carga de 111 ADR pendiente"
metadata:
  node_type: memory
  type: project
  originSessionId: cacdd5c9-e71e-47b2-a977-5d0b980f9280
  modified: 2026-10-19T03:03:21.489Z
---

El propietario firmó el 2026-10-18 «GA-01 a GA-08 según la recomendación» y pidió proceder de inmediato. Registrado como **ADR-89** (número del rango de A, por recomendación del coordinador). En master: `docs/adr/estado.json` (fuente única del estado de implementación, por cláusula/fase y por rama), guarda Neutral `tests/GPOS.Tests/Arquitectura/ManifiestoAdrTests.cs`, guía `docs/guias/pull-requests.md` (un PR por cláusula, plantilla de 6 apartados, ~1.500 líneas no generadas, apilado con orden de unión).

**Why:** el 2026-10-18 se hallaron desfases de estado (RG-25, RG-04/05, ADR-58, traspaso de B, y la guarda encontró ADR-47) por copiar el estado a mano en varios documentos.

**How to apply:**
- Todo PR nuevo usa la guía.
- Al unir, actualizar `estado.json` en el mismo paso.
- ADR nuevo: nace cargado con responsable y PR esperado.
- Carga verificada pendiente: 111 ADR con `cargaPendiente` (tope `TopeCargaPendiente` en la guarda, que solo baja). Mientras tanto rige `estado-de-construccion.md` para ellos.
- Pendiente: el índice como tabla (GA-08) y la consolidación en el corte (GA-07).
- CI excluido.
