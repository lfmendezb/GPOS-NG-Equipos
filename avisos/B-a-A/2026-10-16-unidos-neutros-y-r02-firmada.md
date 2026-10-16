```
Para: A y C        De: B (coordinador)            Fecha: 2026-10-16
Tipo: Entrega
Prioridad: Media
Repositorio y rama: feature/modelo-ng @ e80f4654; master @ f56032de
Estado: Abierto (solo información)
```

# Unidos los PR neutros (#43, #46, #47, #49, #54) y firmada R-02 de ADR-118

## `feature/modelo-ng` → `e80f4654`
- **Unidos:** #43 (A-N4), #49 (SEG-CORP-08), #54 (H-V4-01), #46 (reimpresión por POST) y #47 (limpieza, reapuntado). GitHub los marca como unidos.
- **Verificación:**
  - compilación de la solución correcta;
  - `GPOS.Tests` en `.` (autorización, reimpresión, impresión, RG-14, restauración, arquitectura, licencia, candado y Mvp): 906/1/6. La falla, `CandadoSistemaApiTests.CA_CR_02`, pasa sola dos veces: fue concurrencia con otras pruebas en la misma máquina;
  - Web 656/656 y MAUI 565/565.
- **C:** ya puedes construir SC08-01/03 sobre el #49 unido.
- **Siguen en espera, por decisión del propietario** (no mover la base de T6): #52 + #55, #51 y #45 después del 27-oct, y el #48 regenerado.

## R-02 firmada (ADR-118, cláusulas 3 y 9; `master` `f56032de`)
- **Respuesta del propietario:** «Firmo R-02 (Recomendado)».
- **Qué decide:** la política de negativos se resuelve una vez por documento en la preparación y llega por parámetro al `UPDATE` condicional. Causa medida: el perfil `traspasos/B/2026-10-16-perfil-t1-renglon.md`.
- **B lo construye en `b/prep-27oct`** junto con dos mejoras aprobadas sin firma: `FORCESEEK` en `KardexCosto` (meta 5b) y `UnidadesArticulos` sin `IN (OPENJSON)`.
- **Después:** T6 de noche con la base y el candidato nuevos.
