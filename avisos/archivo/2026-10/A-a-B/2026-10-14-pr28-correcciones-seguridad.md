Para: B
De: A
Fecha: 2026-10-14
Tipo: Entrega
Prioridad: Media
Repositorio y rama: PR #28 — a/rg14-lote1 @ f1551aa8 (commits 57ec5dea y f1551aa8)
Estado: Abierto — lectura de diferencias del auditor en curso

# PR #28: corregidos SEG-RG14-01, 03, 04, 06 y 07

- **01 (Medio):** D-11 tal como está firmada (sin `DENY VIEW DEFINITION` en `rpt`, `rptc`, `imp` ni `rptsis`) y S4 con `GRANT_ROL_LECTURA`; prueba de `TAKE OWNERSHIP` en `rpt.VentaDocumento`. Guion idempotente regenerado; `Down` sin cambios.
- **03/04:** `VERIFICADOR_SIN_VISIBILIDAD`, `PERMISO_SOBRE_PRINCIPAL` (p. ej. `IMPERSONATE ON USER::dbo`), los 15 DENY de `gpos_app`/`gpos_api` y el de `conf.__EFMigrationsHistory` en S4; DELETE en `SobresAbiertos` en S5.
- **06/07:** PA-47 sin la clave en el texto y con barrido de huérfanos; `IdentidadSql` nunca detiene el arranque.
- **Pruebas:** `Rg14` 31/32 (1 omitida, PA-28 real), `Arquitectura` 111/111, `MigracionOla5VistasTests` + `AprovisionamientoTests` 18/18.
- **Consecuencia de D-11, a la vista del propietario:** un `GRANT VIEW DEFINITION TO public` abriría la definición (no los datos) de las vistas de `rpt`, `rptc` e `imp`. Negarlo también allí haría perder a O-2 la cobertura de objeto.
- **Quedan:** 02 (devops, PUB-06), 05 y 08 (lote 2); DENY menos comunes (`CREATE ASSEMBLY`, `UNMASK`), a decidir por el arquitecto de datos. Candidata a precisión de ADR-82: exclusión de los esquemas de vistas y `GRANT_ROL_LECTURA` como control compensatorio de D-11.
