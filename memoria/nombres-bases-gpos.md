---
name: nombres-bases-gpos
description: "Convención de nombres de bases de GPOS NG fijada por el propietario el 2026-10-04: GPOS_SYSDATA para el sistema y prefijo GPOS_ (nunca GPOST_) para empresas, sucursales y pruebas"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 1cee00aa-ab02-439f-846e-6899ce03c1d6
  modified: 2026-10-04T14:59:38.986Z
---

El 2026-10-04, leyendo los ADR, el propietario ordenó: la base del sistema es `GPOS_SYSDATA` (no `GPOST_SISTEMA`), y las bases de empresa o sucursal se nombran `GPOS_{Data Empresa/Sucursal}`, nunca `GPOST_…`. Los nombres de BP2 (`SYSDATA`, `POS_*`) solo se mantienen al citar el modelo anterior.

**Why:** `GPOST` es el nombre del legado (proyecto VB6 GPOST2); GPOS NG tiene identidad propia.

**How to apply:**
- En documentos, código, DDL, pruebas y prompts a agentes, usar `GPOS_SYSDATA` y el prefijo `GPOS_` (también `GPOS_TEST_*`, `GPOS_EI_*`, `GPOS_EC_*`, `GPOS_B9_*`, `GPOS_PILOTO_*` para bases temporales).
- No renombrar las variables de entorno `GPOST_TEST_SERVER`, `GPOST_B9*` (no son bases) ni el propósito de Data Protection `GPost.Empresas.Conexion`.
- Ya aplicado en todo el repositorio `GPOS NG` y registrado en la sección Datos de CLAUDE.md (pendiente de confirmar en git a esa fecha).

Relacionado: [[decision-modelo-datos-propio-pendiente]].

**Excepción aprendida el 2026-10-04:** el renombrado automático convirtió el paso «Borre GPOST_SISTEMA y GPOST_DEV» del briefing histórico de PC-4 en «Borre GPOS_SYSDATA…», que es la base real del propietario. Se restauraron los nombres históricos en `docs/calidad/2026-10-02-pc4-briefing-propietario.md` y `...-pc4-lista-propietario.md` con una advertencia. **Nunca renombrar en bloque nombres de bases dentro de instrucciones destructivas o de registros históricos** (borrar, restaurar, sobrescribir): revisarlas una por una.
