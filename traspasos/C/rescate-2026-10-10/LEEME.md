# Rescate del equipo C (2026-10-10)

Material que solo existía en el equipo C (LAPTOP-DUMQQ5QK), fuera de los repositorios. Se copió aquí por la orden del propietario de dejar todo en GitHub (`avisos/B-a-C/2026-10-10-cierre-equipo-c.md`). No contiene secretos: se revisó antes de copiarlo.

| Carpeta | Qué es | Origen |
|---|---|---|
| `datos-demo-lotes/` | Plantillas del DEMO con existencias y lotes (C-6, PR #15): 01 a 08 `.xlsx`, `T4-vencimientos-lotes.csv` y `LEEME-lotes.md`. Datos ficticios. **No se publican en OneDrive hasta que exista un paquete con T4** (columna de vencimiento obligatoria, UX-118-01) | `paquetes-demo\datos-demo-lotes` |
| `herramienta-xlsx/` | Código fuente del generador de esas plantillas (ClosedXML, el mismo paquete que usa el repositorio), sin `bin` ni `obj` | scratchpad de la sesión |
| `ensayo-demo/` | Evidencia del ensayo de actualización del DEMO: huellas de esquema y datos, idempotencia, registros de las pasadas y guiones de restauración (resumen en `traspasos/C/2026-10-09-guia-actualizacion-demo.md`) | scratchpad de la sesión |
| `medicion-c10/` | Mediciones antes y después de C-10 (PR #21) con `PerfilDisparadoresOla4Tests`, y los planes capturados. Sirven para que B repita la medición antes del 14-oct | scratchpad de la sesión |

**El paquete `GPOS-Demo-2026-10-10.7z` no se copia aquí:** ya está en OneDrive (`Instalador\GPOS ARGON\Actualización`), con su SHA-256.
