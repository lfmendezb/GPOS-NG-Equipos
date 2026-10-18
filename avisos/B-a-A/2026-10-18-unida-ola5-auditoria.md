```
Para: A y C        De: B            Fecha: 2026-10-18
Tipo: Aviso (unión)
Prioridad: Alta
Repositorio y rama: GPOS-NG feature/modelo-ng @ 1768f6a3
Estado: Abierto
```

# Unida la ola 5, auditoría (`feature/modelo-ng` = `1768f6a3`)

Tarea 1 aprobada por el propietario («procede con el 1 y el 3»; en esta sesión, «Arranca con la Ola 5»).

## Qué entró
- `b/ola5-auditoria-r` @ `af052159`: T3-11 (ADR-111, cláusula 7; P-A1 a P-A5; AE-01 a AE-10). `audit.Exportacion` y `audit.ExportacionCierre`, evidencia en toda exportación de la principal y «Verificar exportación» del ADMIN y el SUPER, en Web y MAUI.
- **Migración `20261015211406_Ola5AuditExportacion`:** conserva su marca, que ya cae entre `Uf05ForceSeek` (`20261015142020`) y la del #48 (`20261018042207`). No hubo que regenerarla.
- **Guion acumulado:** `database/empresa/gpos-empresa-20261015211406_Ola5AuditExportacion.sql`, que sustituye al de `Uf05ForceSeek`. Verificado contra `dotnet ef --idempotent` (idéntico) y `has-pending-model-changes` sin cambios.
- **Corrección en la unión (`af052159`):** el SQL de `EvidenciaExportacionesService` pasa a `Infraestructura/Motor/ComandosEvidenciaExportacion.cs`, como `ComandosCambioRnc`, con los mismos tipos y largos (ADR-50). La guarda `SqlSoloEnLugaresPermitidos` (CA-0.8) fallaba en la suite.

## Pruebas (LFMB, `.\SQLEXPRESS`, filtro oficial)
- Suite oficial: **3251 correctas, 4 fallidas y 28 omitidas; las 4 pasan solas (4/4)**: CA-P7-06 (grupo de conexiones), PA30 (la corrige DL-22, #55), `NumeracionQaDefectosPreexistentes…Anulacion_devolucion_venta_y_Z` y CP103 (carga).
- Web 699/0, Reportes 433/0 y MAUI 602/0.

## Lo que cambia para A y C
- **Toda rama se rebasa sobre `1768f6a3`.**
- **#48 (A):** conserva la marca `20261018042207`, pero el snapshot de la punta cambió (`Ola5AuditExportacion`). Hay que regenerar su Designer y el snapshot sobre `1768f6a3`, y su guion acumulado sobre el de `Ola5AuditExportacion` (el bloque del #48 al final). Comprobar `has-pending-model-changes`.
- Las ramas sin migraciones (#52, #55, #45, #63, #67, #68, #73) solo se rebasan.
- **P-B1 a P-B3** siguen esperando al #48.
- **Registrados en `master` `f86f88f8`:** el 51616, el 51617 y el 51618 en ADR-82 (siguiente libre: 51619) y el 51618 y el **EventId 4722** en ADR-83 (siguiente libre: 4723). También `CLAUDE.md` al día.

## Sigue
#52 → #55 → #51 → #45 → #48 → #60 → #63 → #67 → #68 → #57 → #58, y después #73. B une en ese orden a medida que lleguen rebasados sobre `1768f6a3`.
