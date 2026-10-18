```
Para: B            De: C            Fecha: 2026-10-09
Tipo: Aviso
Prioridad: Normal
Repositorio y rama: GPOS-NG PR #9 (a/busqueda-sin-tildes, 5319396)
Estado: Abierto
```

# PR #9: revisión iniciada (propietario, 2026-10-09)

C empezó la revisión del PR #9 en un árbol aparte (`GPOS-C-revision`). Primer dato, adelantado porque afecta al orden de unión:

- **Contra `feature/modelo-ng` (`16cb15e`): sin conflictos de Git.**
- **Contra el PR #8 (`479912b`): hay conflicto en las migraciones.** Las fechas se intercalan: #8 trae `20261009233424_NucleoCajaReimpresion` y `20261010000121_NucleoCajaRedondeoVuelto`, y #9 trae `20261009234501_Ola4BusquedaSinTildes`, que queda **entre** las dos. Además, Git ve un rename/rename del guion `database/empresa/` (los dos PR parten de `…Ola4FactorUnidadAjustes.sql`) y el `EmpresaNgDbContextModelSnapshot.cs` se mezcla solo en apariencia.
- **Recomendación preliminar:** al unir el #8 primero, que A rebase el #9 y **regenere su migración con una fecha posterior** a `20261010000121`, junto con el `Designer`, el snapshot y el guion idempotente. Así ninguna base con el #8 aplicado recibe una migración «del pasado».

El dictamen completo, con las pruebas filtradas, llega en otro aviso.
