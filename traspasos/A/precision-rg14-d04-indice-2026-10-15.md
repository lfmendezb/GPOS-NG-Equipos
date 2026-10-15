# Precisión de RG-14 D-04 (a): sin índices filtrados en tablas con 2 o más columnas calculadas

**Fecha:** 2026-10-15 · **Equipo:** A (desarrollador-backend) · **Para registrar en:** ADR-82 (`docs/adr/ADR-082.md` de `master`), punto 3 (D-04 (a)), y en el diseño de datos de RG-14 v2.
**Firma del propietario (2026-10-15):** «Firmo la precisión de RG-14 D-04 (a): sin índices filtrados en tablas con 2 o más columnas calculadas; IX_Documento_MotivoAnulacion sin filtro. Construye la corrección.»
**Origen:** `traspasos/A/datos-contencion-12834-2026-10-15.md` (arquitecto de datos de A).
**Construcción:** rama `a/rg14-contencion-indice` (PR contra `feature/modelo-ng`, sin unir).

> Nota: `master` ya contiene en ADR-082 una nota con esta precisión («Precisión del 2026-10-15 del punto 3 (D-04 (a))…», que termina en «Decidido, no implementado»). Lo que sigue es el texto para que el documentador la complete con la cita literal de la firma y, al unir el PR, cambie el estado.

---

## Texto de la precisión, listo para registrar

> **Precisión del 2026-10-15 del punto 3 (D-04 (a)): sin índices filtrados en tablas con 2 o más columnas calculadas.** Firmada por Leonardo Méndez, propietario, el 2026-10-15: «Firmo la precisión de RG-14 D-04 (a): sin índices filtrados en tablas con 2 o más columnas calculadas; IX_Documento_MotivoAnulacion sin filtro. Construye la corrección.» Sin cambiar el texto firmado del punto 3:
>
> 1. **Regla.** El validador de contención de SQL Server 2019 (15.0.2200.2, RTM-GDR) rechaza `ALTER DATABASE … SET CONTAINMENT = PARTIAL` con el error 12834 cuando una tabla tiene más columnas calculadas que índices filtrados y al menos un índice filtrado (regla empírica sobre un defecto del motor). Para no depender de la versión ni de la CU del motor del cliente, **ninguna tabla de las bases de empresa con 2 o más columnas calculadas lleva índices filtrados**. Vale para toda migración futura.
> 2. **Corrección.** `IX_Documento_MotivoAnulacion (MotivoAnulacionId)` de `doc.Documento` (columnas calculadas `NodoOrigenId` y `NumeroInv`) queda **sin filtro**, con la migración `20261015030000_Rg14ContencionMotivoAnulacion`:
>    - **Up** idempotente: borra el índice si tiene filtro y lo crea sin filtro si falta;
>    - **Down** que se niega con **51616** si la base está en `CONTAINMENT = PARTIAL` (volver a filtrar dejaría la base sin poder cambiar su contención en ningún sentido); con `NONE`, repone el filtro, también idempotente.
> 3. **Efecto medido** (200 000 documentos, base de prueba): la búsqueda por sufijo conserva su plan y sus lecturas; el `EXISTS` por motivo pasa de 2 a 3 lecturas lógicas; el índice crece unos 16 B por documento (unos 16 MB por millón). Las bases de empresa existentes (todas en `NONE`) reciben la migración con `actualizar`, con la API detenida; no se pierden datos.
> 4. **Guardas** en `GPOS.Tests` (`Rg14ContencionTests`): (a) esquema: ninguna tabla con 2 o más columnas calculadas tiene índices filtrados; (b) una base recién creada pasa a `PARTIAL` y vuelve a `NONE`; (c) con la base en `PARTIAL`, el Down devuelve 51616 y deja el índice sin filtro; (d) sin contener, Down y Up se alternan y son idempotentes. (b) y (c) exigen una instancia con modo mixto y `contained database authentication = 1` (`[FactUsuariosContenidos]`).
> 5. **SQL Server 2025** (17.0.1145.4): el defecto no se observó allí según la propuesta, pero no se pudo validar en la PC A (`contained database authentication = 0` en `.`); la regla vale para las dos versiones porque elimina la condición.
>
> **Decidido; construido en el PR de `a/rg14-contencion-indice`, sin unir.**

---

## Pendiente para registrar

- Documentador técnico: completar la nota de ADR-082 en `master` con la cita literal de la firma y el número del PR; cambiar a «implementado» solo cuando B una el PR.
- Devops o propietario: la verificación en SQL Server 2025 (sección 7 de la propuesta) y, si se desea, una CU reciente de 2019.
