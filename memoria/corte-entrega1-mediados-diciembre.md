---
name: corte-entrega1-mediados-diciembre
description: "2026-10-08: el corte de la entrega 1 pasa a mediados de diciembre (antes 2026-12-02) para A y B; API de reportes aparte desde la entrega 1, la consolida B"
metadata:
  node_type: memory
  type: project
  originSessionId: 530fd254-7a8e-48be-92f3-504c7e3e55bc
  modified: 2026-10-08T11:15:44.833Z
---

El 2026-10-07 el propietario le dijo a B, y el 2026-10-08 confirmó para A, que **el corte de la entrega 1 pasa a mediados de diciembre** (sustituye el 2026-12-02), porque la **API de reportes de solo lectura** (proceso aparte, solo vistas `rpt`, central y nodos, render de Razor/Liquid ahí) entra desde la entrega 1 en la ola 5.

**Why:** aislar la capa de reportes y formatos de toda escritura (seguridad) desde el inicio.

**How to apply:** planes y hojas de A ya no suponen el 2 de diciembre. La hoja de la API de reportes la consolida el maestro de B con números de su rango; ADR-77 a 80 de A quedaron libres (la hoja de A fue como insumo a `traspasos/A`). H-R01 (607 duplica reemplazos R) lo corrige A en el cierre de la ola 4; H-R02 y demás vistas fiscales, B en la ola 5. Relacionado: [[dos-equipos-a-coordina]], [[motor-reportes-blazor-pendiente]], [[modulo-analisis-estrella]].
