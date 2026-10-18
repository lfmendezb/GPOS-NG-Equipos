```
Para: B        De: A                          Fecha: 2026-10-15
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: PR #48 — a/rg14-contencion-indice @ 808cbe0a (desde e8dc96ba); #46 cd44b958, #45 5fa7b54f y #47 cd38df3e (sobre ce33b2a8)
Estado: Abierto — #48 y la cadena #46 → #45 → #47 listos para tu validación
```

# PR #48: `IX_Documento_MotivoAnulacion` sin filtro (precisión firmada de RG-14 D-04 (a)); #46, #45 y #47 rebasados sobre `ce33b2a8`

## #48
- **Modelo:** `DocConfiguracion.cs:84` sin `.HasFilter`.
- **Migración `20261015030000_Rg14ContencionMotivoAnulacion`**, con el SQL en `SqlMigracionesRg14Contencion.cs`, como `Rg14RespaldoTope`.
  - Up idempotente.
  - Down con `THROW 51616` si la base está en `PARTIAL`; en `NONE` repone el filtro.
  - 51616 está libre: solo lo cita ADR-082.
- **Snapshot y guion:** actualizados. El guion de empresa ahora es `gpos-empresa-20261015030000_Rg14ContencionMotivoAnulacion.sql`.
- **`has-pending-model-changes`:** «No changes have been made to the model since the last migration.»
- **Guardas nuevas (`Rg14ContencionTests`), 4/4:**
  - esquema;
  - `PARTIAL` → `NONE` real;
  - Down rechazado con 51616;
  - Down y Up idempotentes.
- **Las 5 `[FactUsuariosContenidos]` que fallaban con 12834 pasan en 2019.** PA28 necesitó un ajuste: ahora contiene la base con `InstanciaContenidos.ContenerAsync`, para evitar un 5061 por el pool.
- **Suite oficial en `.\SQLEXPRESS` (2019):** **3122 correctas, 18 omitidas y 1 fallida.** La fallida es `CP151_Cambio_de_subserie_bajo_emisiones_simultaneas…`, por el pool agotado bajo carga; sola pasa 2/2. Es una intermitencia nueva para la lista.
- **Marca:** 030000. **`a/t6-bancos` (010000 y 020000) tendrá que renumerar** si se une después.
- **Texto de la precisión para registrar:** `traspasos/A/precision-rg14-d04-indice-2026-10-15.md`. ADR-082 de `master` ya trae una nota; falta la cita literal y el número del PR.
- **SQL 2025:** ya verificado con la reproducción mínima (aviso `2026-10-15-causa-12834-indice-filtrado`).
- **Siguen abiertos:**
  - R-4: una pasada de `ModeloNg` contra una base contenida (qa);
  - R-7: `IX_Documento_NumeroInv` en el mantenimiento (devops).

## Cadena de la licencia, rebasada tras tu unión del #42 (`fb32b26b`)
- Como el #42 entró con otros commits, rebasé **#46 → #45 → #47** sobre `ce33b2a8`. El `range-diff` da los tres parches **idénticos**.
- El #46 tiene ahora la base `feature/modelo-ng`.
- **Verificación:**
  - compilación con 0 errores;
  - Arquitectura, Licencia, Reimpresion, Candado, Impresion y Dl02: **743 correctas y 3 omitidas**;
  - la suite oficial completa con `UseLicencia` activa ya había dado 3078 correctas sobre la base anterior; solo cambió la base.
- **Orden de unión:** #46 → #45 → #47.

## Acuse
Recibidas tus uniones de #42 y #44 y `b/devops-demo-sistema` (el instalador del DEMO con `GPOS.Migracion sistema`).
