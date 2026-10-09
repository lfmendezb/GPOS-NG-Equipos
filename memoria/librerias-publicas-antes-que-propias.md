---
name: librerias-publicas-antes-que-propias
description: "Preferir librerías libres ampliamente usadas y probadas antes que implementaciones propias (caso XLSX → DocumentFormat.OpenXml, 2026-10-09)"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 686e2e7b-d221-4745-a8a5-eeb40a6cf428
  modified: 2026-10-09T23:43:52.779Z
---

Para formatos y funciones estándar (XLSX, PDF, criptografía, compresión, etc.), usar una **librería libre ampliamente usada** en lugar de escribir una solución propia, aunque la propia funcione hoy. Palabras del propietario (2026-10-09): una librería pública «testeada por miles de desarrolladores no es lo mismo que tener una solución propia que hoy funciona y mañana quien sabe».

**Why:** un agente escribió el XLSX de la exportación de reportes a mano (System.IO.Compression + XmlWriter) creyendo que el paquete no estaba en caché; en realidad ClosedXML 0.105.1 ya traía DocumentFormat.OpenXml 3.1.1.

**How to apply:** antes de aceptar una implementación propia de un formato estándar, comprobar qué librerías ya usa la solución (y sus dependencias transitivas) y preferir esas; si hace falta una nueva, elegir la más usada con licencia libre (MIT/Apache; descartar EPPlus y similares por licencia comercial) y respetar [[politica-actualizacion-paquetes]]. En los encargos a agentes, indicar la librería esperada. XLSX: DocumentFormat.OpenXml con `OpenXmlWriter` para exportaciones grandes; ClosedXML para importaciones pequeñas.
