---
name: adjuntos-en-documentos
description: "Pedido del propietario (2026-10-05): adjuntar archivos (imágenes, documentos) en mermas de transferencias y en todas las ventanas de documentos salvo Facturación Ágil y Devolución POS; nube del cliente en fase tardía"
metadata:
  node_type: memory
  type: project
  originSessionId: 1cee00aa-ab02-439f-846e-6899ce03c1d6
  modified: 2026-10-05T21:29:44.197Z
---

El 2026-10-05 el propietario pidió:
- **Mermas en tránsito:** además de motivo (faltante, dañado, extraviado, robado), autorizante, cantidad y valor, fecha y conservación 10 años, **«Adjuntar archivo»** (imágenes o documentos como aval del motivo). No hay un estándar del contador: solución integral propia.
- **Adjuntos en todas las ventanas de documentos**, excepto Facturación Ágil y Devolución POS: copia digitalizada del documento impreso con la firma de cada responsable como aval. Todo sube a la central y se resguarda en una unidad elegida por el cliente.
- **Fase tardía:** integrar la nube de la empresa (Dropbox, Google Drive u OneDrive, a elección) para guardar los archivos administrados por GPOS.

**Why:** trazabilidad y soporte documental (fiscal y de control interno) de cada registro.

**How to apply:** los archivos fuera de la base (almacén de archivos con huella SHA-256; metadatos en la base), tipos y tamaño limitados, revisión del auditor (archivos subidos), **papelera de 30 días antes del borrado físico (aprobada 2026-10-05)**; **excepción a ADR-08 decidida por el propietario (2026-10-05): un adjunto subido por error SÍ se puede eliminar** (para no llenar el almacén de basura), y la bitácora registra el borrado con quién, cuándo, motivo y los datos del archivo (nombre, tamaño, huella), incluidos en los respaldos, sincronización nodo→central en la entrega 2. La infraestructura común nace con la ola 3b (mermas); la nube reutiliza lo aprendido en la herramienta de respaldos y la actualización automática. Relacionado: [[eliminar-solo-sin-referencias]], [[actualizacion-automatica]].

**Estado (2026-10-05):** diseño v1 en `GPOS NG/docs/arquitectura/2026-10-05-adjuntos-documentos.md` (ADR-67 Propuesto); auditor: Aprobado con observaciones (ADJ-01 a ADJ-16, prioridad 1: 01, 02, 03, 05, 06, 08); P-A01 a P-A15 aceptadas por el propietario (PDF/JPEG/PNG/TIFF/HEIC sin Office, 10 MB hasta 25, SUPER elige la carpeta, «Sustracción» (antes «Robado», renombrado por el propietario para no acusar) con denuncia obligatoria, sin adjuntos en POS, compras y bancos dentro de la 3b, 20 GB, sin módulo de licencia, Defender, papelera fija 30, bloque separable 3b-A). Siguiente: v2 del arquitecto-software con auditor + arquitecto-datos y firma de ADR-67. Sustitución (esperaba X, llegó Y) aprobada en la hoja de la ola 3b.
Q-D2 aprobada (2026-10-05): la auditoría interna puede reimputar una pérdida (solo inserción, motivo e historial).

**Conservación (2026-10-05, respuesta de la contadora vía propietario):** no hay obligación de conservar los adjuntos más allá del plazo legal; el plazo obligatorio ya **no es 10 años** (es menor; cifra exacta por confirmar) y la decisión final es **de cada empresa**. Propuesta del propietario: proceso de **desvinculación** que solo ejecuta el SUPER a petición del cliente, que desvincula todos los adjuntos de los períodos indicados, y después un **corte de la data** de esos períodos. Afecta MD-61 (conservación 10 años, firmada).
**ADR-67 FIRMADO (2026-10-05)** con maestro de motivos (código, descripción, Exigir evidencia, Tratamiento de lista fija, Pedir referencia; siembra FAL, DAN, EXT, SUS, NSO, VEN) y desvinculación de adjuntos por período (SUPER, a petición escrita, períodos cerrados y más antiguos que el plazo legal mínimo parametrizado, respaldo previo, lápida). Q-D4: adjunto por gasto de caja chica opcional. **Corte de datos de períodos antiguos: decisión aparte, después de la entrega 2** (ADR propio, precisar MD-61). Pendiente: cifra exacta del plazo legal (contadora); v2.2 del diseño con estas adiciones.
