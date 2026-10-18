```
Para: A        De: B (coordinador)            Fecha: 2026-10-15
Tipo: Entrega
Prioridad: Media
Repositorio y rama: GPOS-NG b/ola5-auditoria-r @ 6e472dcb (sobre b/prep-27oct @ 665f74c3); b/prep-27oct @ 665f74c3
Estado: Abierto
```

# `b/ola5-auditoria` rehecha sobre la preparación del 27-oct (`b/ola5-auditoria-r`)

## Qué trae
- T3-11 (`audit.Exportacion`, ADR-111 cl. 7, P-A1 a P-A5), «Verificar Exportación» y AE-01 a AE-04.
- **Migración `20261015211406_Ola5AuditExportacion`**, posterior a `Uf05ForceSeek` por la regla de marcas.
  - Un solo guion: `gpos-empresa-20261015211406_Ola5AuditExportacion.sql`.
  - `has-pending-model-changes` sin cambios; el `Designer` lleva el `INCLUDE` de C-10.
- **`DENY ALTER ANY USER`:** un solo dueño, RG-14. Se quitó de la ola 5, junto con el `REVOKE` de su reverso, que habría retirado el DENY de RG-14. Queda el `DENY ALTER` sobre el esquema `audit`.
- **`SecExportacion`** va en `SecuenciasNodo.Todas`, no en `Fundamentos`.
  - Nace con el rango de su nodo y `usp_AdelantarSecuencias` la adelanta tras una restauración.
  - Prueba Up → Down → Up con el nodo 2 simulado.
- **AE-09:** cierre `I` cuando el cliente corta la descarga.
- **AE-10:** la caché de Fundamentos sale de `SecuenciasNodo.Fundamentos`, sin `Take(13)`, con una prueba que lo ata.

## Lo que queda fuera
**P-B1 a P-B3 (bases contenidas, `bd30d5d3`)** espera tu corrección del **12834** (`doc.Documento.NumeroInv`). Se rehace sobre esta rama cuando la entregues.

## Verificación
- Compilación de la solución correcta.
- Migración, auditoría, secuencias, 3b, planes y Mvp: **120/0/1** en `.\SQLEXPRESS`; con el filtro del agente, 128/128 en `.`.
- Web: 698/698. `GPOS.Reportes.Tests`: 433/433.
- Las 4 pruebas `Transicion=Ola5` (`DrillDownTests`, `ReportesTests` y `SucursalOrigenTests`) fallan **igual en `b/prep-27oct`**. B lo comprobó. No son de esta rama, y el filtro oficial las excluye.

## Hallazgo (Bajo, para el arquitecto de datos de A)
Las 5 secuencias de la 3b tienen el mismo hueco que tenía `SecExportacion`: al actualizar una base registrada como otro nodo, nacen con el rango del nodo 1. Hoy no hay bases de nodo (entrega 2). Hay que corregirlo antes de que existan.

## `b/prep-27oct` (`665f74c3`)
- Trae la punta `fb32b26b`.
- Las dos pruebas de plan reintentan también el **8181** (texto del plan que ya no está en el catálogo), visto junto con Mvp.
- Mvp, planes y `PersistenciaLicencia`: 65/0/1 en las dos instancias.

## Orden de unión
27-oct: `b/prep-27oct` (T1, 3b y A-N2). Después, `b/ola5-auditoria-r`.
