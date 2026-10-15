```
Para: B        De: A                          Fecha: 2026-10-15
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: área común traspasos/A/datos-contencion-12834-2026-10-15.md
Estado: Abierto — la corrección espera tu visto bueno o la firma del propietario (precisión de RG-14 D-04 (a))
```

# Causa del 12834: defecto del validador de contención de SQL 2019 con `IX_Documento_MotivoAnulacion` filtrado

## Causa (reproducida)
- **No es `REVERSE` ni la intercalación.** El validador de contención de SQL Server 2019 RTM-GDR (15.0.2200.2) falla si una tabla tiene más columnas calculadas que índices filtrados y al menos un índice filtrado.
- La función que nombra el mensaje cambia de una ejecución a otra: no es la real.
- La única tabla de las bases NG en esa condición es `doc.Documento`:
  - 2 columnas calculadas: `NodoOrigenId` y `NumeroInv`;
  - 1 índice filtrado: `IX_Documento_MotivoAnulacion`.
- `GPOS_SYSDATA` pasa a `PARTIAL` sin cambios.
- `sys.dm_db_uncontained_entities` no detecta este caso.
- Se descartaron: `COLLATE`, `PERSISTED`, contener la base antes de crear el esquema, columnas mantenidas por disparador y un segundo índice filtrado.

## Corrección propuesta: quitar el filtro de `IX_Documento_MotivoAnulacion`
- `DocConfiguracion.cs:84` sin `.HasFilter(...)`.
- Migración nueva `Rg14ContencionMotivoAnulacion`:
  - Up idempotente, de 543 ms;
  - Down que se niega con `THROW 51616` si la base está en `PARTIAL`.
- **Probado en una base de 200 000 documentos:**
  - `PARTIAL` pasa;
  - la búsqueda por sufijo conserva el mismo plan (Index Seek, 104 lecturas);
  - el `EXISTS` por motivo pasa de 2 a 3 lecturas;
  - el índice crece unos 16 B por documento;
  - un usuario contenido entra y lee;
  - el ciclo Up/Down/Up funciona.
- **Estimación:** unos 1,0 días-persona con 3 guardas nuevas (esquema, contención ida y vuelta, Down).

## Afectadas
- `GPOS_DEMO` y 15 bases de prueba en `.\SQLEXPRESS`, y 3 en `.`.
- Todas siguen en `NONE`, y la migración las corrige.
- BP2 no está afectada.

## Sin verificar
- **SQL Server 2025:** en `.` la contención está en 0. El documento trae la reproducción mínima, de unos 10 minutos. **Pídelo en LFMB (2025)** al activar M6.
- **EF Core:** sin `has-pending-model-changes` todavía.
- **Una CU de 2019** que lo corrija. Aunque exista, la corrección propuesta no depende de ella.

## Decisión
**Precisión de RG-14 D-04 (a), para firmar:** «sin índices filtrados en tablas con 2 o más columnas calculadas; `IX_Documento_MotivoAnulacion` sin filtro».
- **Recomendación de A:** aprobar.
- **Cuando esté firmada, A construye** la migración, las guardas y la suite.
