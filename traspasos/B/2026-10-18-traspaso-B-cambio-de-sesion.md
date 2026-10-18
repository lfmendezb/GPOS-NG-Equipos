# Traspaso del equipo B: cambio de sesión del 2026-10-18 (madrugada)

La sesión de B en LFMB (abierta el 2026-10-17) se cierra a pedido del propietario. **No quedan procesos ni agentes activos** (comprobado a las 03:04).

**Al abrir la sesión nueva:**
1. Ábrela en la carpeta `GPOS NG`, para que cargue la memoria.
2. Lee este traspaso, `estado.md` y los avisos abiertos (`A-a-B` y `C-a-B`).
3. **Primero:** las tareas 1 y 3 que el propietario aprobó al final de la sesión, que **no llegaron a empezar** (§3).

## 1. Puntas
| Rama | Punta | Contenido |
|---|---|---|
| `feature/modelo-ng` | `17ecc9b9` | `b/prep-27oct` (T1 de ADR-118/119, 3b tramo 1, A-N2, FORCESEEK de CA-12, R-02) + #66, unidos el 2026-10-17 (`5b47e019`, UN-01 (a), adelantada); después #59, #64 y #65 (suite 3237/4/28; las 4 pasan solas) |
| `master` | `fe42b415` | ADR al día con todas las firmas del 2026-10-17 (§2) |
| `b/ola5-auditoria-r` | `8ca70f8b` | Ola 5 (auditoría), **sin rebasar todavía** sobre la punta |
| `demo/2026-10-15` | `f1d1a650` | Rama del DEMO hasta que exista la licencia con `s1` |

**Última marca de migración de la punta:** `Uf05ForceSeek 20261015142020`. Toda migración nueva o regenerada lleva una marca posterior.

## 2. Hecho en la sesión del 2026-10-17
- **T6 en verde** (informe `2026-10-16-t6-segunda-tanda.md`, tandas quinta y sexta):
  - T-28: 1,008 con `GPOST_B9_AFINIDAD=auto`;
  - T-57: en verde;
  - compra de 20 líneas: 0,22; meta 5b: 0,32;
  - N6-02: 1,049 con afinidad y 0,945 sin ella;
  - 8.2 (6): 6 de 6 con el FORCESEEK de CA-12.
  - **Observación para el arquitecto de datos:** en N6-02 el candidato gasta un 16 % menos de CPU, pero espera un 25 % más en `LCK_M_U`. Va junto con LP-01.
- **Hoja de B firmada** (`hoja-firma-b-2026-10-17.md`): UN-01, BM-01, SE-01, SE-02, CB-01, EM-01, RS-01 y OR-01.
- **Registros en `master`:**
  - `3c41ce77`: RN-F1, RN-F2, SL-F1 y SL-F2;
  - `5cbbb12b`: SLF-01 y el acta de GSF, AG-01 a AG-07, TN-01 con 7(b) y 7(d), la nota de ADR-81 y EV-03 en ADR-62;
  - `fe42b415`: SE-01 y SE-02 (ADR-51), CB-01 (ADR-54), RS-01 y OR-01 (ADR-83).
- **Orden firmado después de la unión:**
  1. #52 + #55 (A)
  2. #51 (C)
  3. #45 (A)
  4. #48 con el #60 (A)
  5. #63 → #67 → #68 (A) → #57 (C) → #58 (A)
- **Revisiones publicadas:**
  - #61: a corregir (rebasar, aplicar SE-02 y medir la ruta E);
  - #63 y #67: aptos, con la suite de B 3217/4/24, cuyas 4 fallas pasan solas;
  - #58 y #60: aptos.
- **PA28 contenida (#60):** no corre en LFMB, porque ninguna de las dos instancias admite usuarios contenidos (PD-07). Se le pidió a C.

## 3. Lo aprobado y no empezado
El propietario dijo «procede con el 1 y el 3», y la sesión se cerró antes de empezar.
1. **Ola 5, auditoría:**
   - rebasar `b/ola5-auditoria-r` sobre `17ecc9b9`;
   - regenerar `Ola5AuditExportacion` con una marca posterior a `20261015142020` (regla de [[marcas-migraciones-orden-de-union]]);
   - guion idempotente y `has-pending-model-changes`;
   - suite oficial;
   - unir a `feature/modelo-ng`.
   - P-B1 a P-B3 siguen esperando al #48.
3. **Poner al día `CLAUDE.md`:** reflejar que T1 de ADR-118/119 y la 3b tramo 1 ya están en `feature/modelo-ng` (hoy dice «decididos, no implementados», «sin unir» y «después del rendimiento de la ola 4»). Sumar también las firmas del 2026-10-17 y la unión adelantada. Lo edita solo el coordinador.

**Siguientes en la lista (sin aprobar todavía):**
- T2 de ADR-126;
- la propuesta de calendario de DB-7;
- el análisis de los `LCK_M_U` de N6-02;
- la vigilancia del nivel de compatibilidad en `ComprobadorEsquemaEmpresas`, junto con el reintento ante el 1205 en `verificar` (lo propuso C).

## 4. Esperas
- **A:** #52 + #55, rebasados sobre `17ecc9b9` y con la renumeración 51616 → 51617; luego #45, #48 y #60, y la cadena SL → RN → #68.
- **C:**
  - rebasar el #61 y aplicar SE-02 (después, B mide la ruta E);
  - LP-01 a LP-04 (ya pueden empezar);
  - rebasar el #57 detrás del #68;
  - PA28 en OSHIN-LEGION.
- **Propietario:** EM-01 (crear el repositorio privado del emisor), PD-07 si se quiere PA28 en LFMB, la vertical Corporativa, AP-04 y lo demás del traspaso del 2026-10-17, §4.

## 5. Árboles en LFMB
- **`GPOS-B-integracion`:** en `b/une-59-64-65` (= punta `17ecc9b9`), limpio. Las ramas locales `b/ensayo-27oct` y `b/union-prep27` ya no hacen falta.
- **`GPOS-B-prep27`** (`d67f5a33`) y **`GPOS-B-carga`** (`e80f4654`): con el #66 aplicado sin confirmar; `GPOS-B-carga` tiene además `RendimientoNegativosTests.cs`. Ya están unidos: se pueden limpiar o reutilizar.
- **`GPOS-B-suite-rn`:** detached en `da474174` (#67), limpio. Sirve para repetir pruebas de SL y RN; borrable.
- **Guiones** en `Solucion GPOS NG\`: `Medicion-T6-r5.ps1` (T-28 con afinidad y muestras), `Medicion-T6-r6.ps1` (N6-02 y la suite) y `Muestras-Pagelatch.ps1`.
- **Lección:** en `git merge` no se usa `-F -`. Escribe el mensaje en un archivo.
