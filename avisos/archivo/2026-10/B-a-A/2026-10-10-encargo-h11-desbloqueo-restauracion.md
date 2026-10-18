```
Para: A            De: B (coordinador)            Fecha: 2026-10-10
Tipo: Encargo (aprobado por el propietario el 2026-10-10)
Prioridad: Alta (va antes que la tanda A-2)
Repositorio y rama: GPOS-NG, rama nueva a/h11-desbloqueo-restauracion desde feature/modelo-ng 42e13b6
Estado: Abierto
```

# Encargo: H-11 (RN-24), desbloqueo de una base restaurada (resuelve DM-01)

> Nota: este aviso debía publicarse en la mañana con el retiro del DEMO de C; se perdió por la referencia rota del área común (apagón). Se publica ahora.

**Motivo:** el ensayo del DEMO de C (`C-a-B/2026-10-10-ensayo-demo-resultado`, DM-01 Alta) comprobó que restaurar un respaldo deja la base sin emitir (51330 por `recovery_fork_guid`) y no hay forma de desbloquearla. El propietario decidió construir H-11 ahora: **bloquea cualquier publicación a un cliente real.**

## Alcance (firmado: ADR-53 cláusula 9, H-11, H-12 y H-13 del cierre de H0, 2026-10-04)
1. **Desbloqueo sin central** de la empresa de una sola base (rol «ambos»): una persona con el privilegio **«Reconciliar nodo restaurado»** (grupo fiscal de Administración; **hoy solo el SUPER**, por H-13) y con **motivo obligatorio**:
   - cierra las secuencias NCF vigentes en el último NCF probado (diario electrónico, proveedor de e-CF o papel) y registra la porción siguiente del rango como secuencia nueva (H-12: los bloques cerrados nunca se reasignan);
   - adelanta las series internas con la fórmula de RN-12 (mínimo 100);
   - registra el fork actual en `sync.EstadoNodo`; confirmación y desbloqueo quedan juntos en la bitácora.
2. **Precisión del Maestro (traslado planificado):** si el último NCF de la base coincide con el del diario o del proveedor, se confirma sin cerrar secuencias (RN-04).
3. **DM-02 en la misma pasada:** `GPOS.Migracion verificar` devuelve código distinto de 0 si la base está RESTAURADA (`Program.cs:63-71`).
4. **Superficies:** endpoint en la API y pantalla mínima en Diagnóstico (Web y MAUI); el arquitecto-software decide si además conviene un subcomando de `GPOS.Migracion`.
5. Orden de bloqueos firmado (series → NCF); SQL `varchar` con el largo de la columna (ADR-50). Migraciones nuevas después de `Ola4BusquedaSinTildes`.

## Proceso
- Arquitecto-software (contrato y superficies) → arquitecto-datos (si hace falta esquema) → backend y frontend → QA → **revisión de seguridad** (toca NCF, privilegios y bitácora). C hará además una revisión independiente (C-2).
- Pruebas con una restauración real sobre `GPOS_TEST_*`, como en el ensayo de C.
- PR contra `feature/modelo-ng`; no unir. Estimado del cierre de H0: ~0,6 sp. Commits y push frecuentes.

## También (Baja, cuando quepa)
- DM-03: aviso falso de «intercalación vacía» con AUTO_CLOSE (`Aprovisionamiento.cs:108-112`).
