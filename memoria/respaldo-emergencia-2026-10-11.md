---
name: respaldo-emergencia-2026-10-11
description: "Respaldo de emergencia del equipo B (se apagaba solo): agentes, skills y memoria en OneDrive GPOS ARGON; ramas respaldo/* en GitHub"
metadata:
  node_type: memory
  type: project
  originSessionId: f504fae8-3285-40f6-a485-c1ff6c49bc94
  modified: 2026-10-11T15:16:35.443Z
---

2026-10-11: el equipo B se apagaba de repente; se respaldó todo, y el propietario confirmó que la subida a OneDrive terminó.
- OneDrive `Instalador\GPOS ARGON\Respaldo equipo B 2026-10-11\` (enlace compartido de la carpeta GPOS ARGON): agentes, skills, memoria, settings.json, `.claude` del proyecto, resultados de carga T-28/T-57 y LEEME con la forma de restaurar.
- GitHub: se subieron por primera vez `b/config-terceros` y `b/demo-revision-1`; los cambios sin commit quedaron en `respaldo/2026-10-11-b-config-terceros-wip` (URL del padrón RNC a la configuración, VT de [[valores-terceros-configurables]]) y `respaldo/2026-10-11-master-lista-pruebas-demo`.

**How to apply:** al reanudar en este u otro equipo, recuperar desde ahí; los árboles de trabajo siguen con esos cambios sin commit. Las ramas `respaldo/*` se borran cuando su contenido ya esté en commits normales.

**2026-10-14 (segundo apagado):** verificado que las 15 ramas de B, el área común, los AddOn y Backup Tool están en GitHub sin pendientes. Nuevo respaldo en OneDrive `GPOS ARGON\Respaldo equipo B 2026-10-14\` (con la memoria al día). Nota de traspaso: `GPOS-NG-Equipos\traspasos\B\2026-10-14-traspaso-B-apagados.md` (c3d7ccf), con el orden para reanudar. **Guion de restauración:** `Restaurar-EquipoB.ps1` en esa carpeta de OneDrive (probado en modo `-SoloRevisar` con PS 5 y 7; los pasos de git, probados en un clon desechable); en el equipo nuevo el propietario instala los requisitos y Claude lo ejecuta y verifica. A, por su parte, abrió los PR 26 y 27 y la hoja D-01 a D-11 (T3-12/RG-14).
