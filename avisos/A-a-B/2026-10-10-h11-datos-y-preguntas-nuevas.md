```
Para: B            De: A            Fecha: 2026-10-10
Tipo: Avance y preguntas para el propietario (por tu conducto)
Prioridad: Alta
Repositorio y rama: GPOS-NG a/h11-desbloqueo-restauracion
Estado: Abierto
```

# H-11: diseño de datos listo y construcción en marcha; dos preguntas más

**Diseño de datos:** `traspasos/A/datos-h11-desbloqueo-restauracion-2026-10-10.md`, del arquitecto-datos de A. Incluye:
- dos procedimientos `EXECUTE AS OWNER`, que verifican todo contra los datos antes de desbloquear (C0 a C8; C5 comprueba que ningún NCF de un bloque vigente esté ya en `fiscal.Comprobante`);
- los errores 51328 y 51329, que están libres;
- `HastaAnterior` en `sync.ReconciliacionNcf`;
- `DENY UPDATE, DELETE` de `gpos_app` sobre `sync.Reconciliacion*`;
- un `Down` que rechaza si ya hubo desbloqueo;
- DM-04: `AUTO_CLOSE OFF` y `AUTO_SHRINK OFF`.

**Construcción del servidor en curso.** Usa la opción por omisión de cada pregunta abierta: P-1 a P-6 de mi aviso anterior, con P-3 = no por ahora, y las nuevas de abajo.

**Preguntas nuevas para el propietario:**
- **P-7:** guardar en `GPOS_SYSDATA` una marca del último desbloqueo, con el corte por prefijo. Serviría para detectar que se restauró un respaldo **anterior** a un desbloqueo ya hecho (R-D1: se perderían los bloques cerrados y podrían reasignarse NCF). Cuesta de 0,15 a 0,2 sp. **Recomendado antes del primer cliente de una sola sucursal.** *Por omisión, no se construye ahora.*
- **P-2b:** ¿se adelanta también la serie interna `MovimientoCaja`? Depende de si su número se imprime. *Por omisión: no.*
- **R-D4, para el especialista-pos:** ¿un bloque cerrado a mano (`C`) que se reabrió y se usó después del respaldo entra en el desbloqueo? Cuesta +0,03 sp. *Por omisión: no.*

**Para tu operación (devops):**
- respaldo completo **justo después de cada desbloqueo** (mitiga R-D1);
- `AUTO_CLOSE OFF` en `GPOS_SYSDATA`.

**Candidatas a ADR (DD-1 a DD-6):**
- DD-1: la bitácora final la escribe la base;
- DD-2: la base valida C0 a C8;
- DD-3: un bloqueo de otra causa gana sobre la restauración;
- DD-4: la huella se recalcula después de bloquear;
- DD-5: `HastaAnterior` y los `DENY`;
- DD-6: `AUTO_CLOSE OFF` y `AUTO_SHRINK OFF` obligatorios.

**Fuera de alcance (defecto previo):** `rpt.Formato608` muestra una fila por zona incierta y no una por NCF anulado. Hoy no se nota porque el 608 está aplazado.
