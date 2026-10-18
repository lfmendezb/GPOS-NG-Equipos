# Revisión de datos: migración `T2cAceptaDeSuplidor` (ADR-126, VT-08, B-01 y B-02)

- Fecha: 2026-10-18 · Revisor: arquitecto-datos · Tipo: revisión corta, solo lectura
- Worktree: `GPOS-C-intermitentes`, rama `c/t2c-acepta-de-suplidor`, cambios sin confirmar (base `322b21d6`)
- Archivos: `src/GPOS.Core/Datos/Empresa/Migraciones/20261018181156_T2cAceptaDeSuplidor.cs` (+ `.Designer.cs`), `EmpresaNgDbContextModelSnapshot.cs`, `src/GPOS.Core/Dominio/Fiscal/Catalogos.cs`, `src/GPOS.Core/Datos/Empresa/Configuracion/CfgConfiguracion.cs`

## Veredicto: **Conforme con correcciones**

Esquema y datos correctos. Una corrección obligatoria antes de confirmar: falta regenerar el guion acumulado (D-01). Sin ella falla la suite.

## Respuestas a los puntos pedidos

1. **`AddColumn` con `defaultValue: false`: seguro y rápido.** Genera `ALTER TABLE fiscal.TipoComprobante ADD AceptaDeSuplidor bit NOT NULL DEFAULT CAST(0 AS bit)`. En Enterprise es un cambio solo de metadatos. En Express y Standard puede reescribir las filas, pero la tabla es un catálogo de 21 filas (siembra en `SqlMigracionesCfg.cs:34-59`, comprobada en `MigracionesTests.cs:108`, más los tipos que agregue un ADMIN). El bloqueo Sch-M dura milisegundos. No hay riesgo de bloqueo largo ni de crecimiento.
2. **Los UPDATE son idempotentes y no pisan decisiones.** Ambos llevan `AND <col> = 0`: solo suben a 1 y no tocan otros códigos. Tampoco se pisa ninguna decisión de un ADMIN:
   - `AceptaDeSuplidor` es nueva.
   - `RequiereRnc` no la podía decidir el ADMIN en `master`: `AdministracionService` la reescribía con la lista del código al guardar (línea `t.RequiereRnc = TiposComprobante.RequiereRnc(codigo)`, quitada en el diff). Por eso un 0 en 14, 15, 44 o 45 solo puede venir del defecto de la siembra.

   No dependen de `Serie`: la columna calculada persistida depende solo de `Electronico` (`CfgConfiguracion.cs:412-413`) y ningún UPDATE la toca. En el guion idempotente, EF envuelve `migrationBuilder.Sql` en `EXEC(N'...')` dentro del `IF NOT EXISTS` de la marca, así que la columna nueva se resuelve al ejecutar, no al compilar el lote (comportamiento conocido de EF Core en modo idempotente; inferido, se confirma al regenerar el guion de D-01). No encontré disparadores sobre `fiscal.TipoComprobante` en las migraciones.
3. **Down correcto.** `DropColumn` de SQL Server quita antes la restricción DEFAULT. Dejar `RequiereRnc` corregido es correcto y compatible con la versión anterior: esa versión no lee la columna en el POS (`TiposComprobante.RequiereRnc(t.Codigo)`) y, al guardar, escribe el mismo 1 para 14, 15, 44 y 45 desde su lista. El reverso no pierde datos: la columna eliminada solo contiene valores sembrados o que el ADMIN puede volver a marcar.
4. **La marca está en orden.** `20261018181156` es posterior a `20261018153317_Sc08EliminaRenglon`, que es la última en la rama y en `origin/feature/modelo-ng`. El Designer coincide exactamente con el snapshot (comparé `BuildTargetModel` con `BuildModel`: sin diferencias; `ProductVersion` 10.0.12 en ambos).
5. **No hace falta índice ni restricción.** La columna es `bit NOT NULL` y la tabla es diminuta. La única lectura (`ConsultasFiscal.Tipos`, `ConsultasFiscal.cs:77`) recorre la tabla entera y filtra en memoria (`EmisionNcfNg.cs:214-215`). Un índice solo costaría escrituras. Tampoco hace falta un CHECK: `bit NOT NULL` ya restringe el valor.
6. **Comentario `revisado-por`: la prueba no lo exige.** `PeligrosasSinRevision` (`MigracionesTests.cs:117-145`) solo detecta `DropTable/DropColumn/RenameColumn/RenameTable` y `DROP COLUMN/DROP TABLE/sp_rename` dentro del `Sql` del **Up**. El `Down` no se revisa, y el `UPDATE` no cuenta. Aun así recomiendo agregarlo, porque el Up corrige datos fiscales en una base viva. Va como observación Baja (D-03) y no bloquea.
7. **Guion acumulado `database/empresa/*.sql`:** ver D-01.

## Hallazgos

| Id | Severidad | Hallazgo | Evidencia | Corrección |
|---|---|---|---|---|
| D-01 | Alta | El guion acumulado no está regenerado. Solo existe `gpos-empresa-20261018153317_Sc08EliminaRenglon.sql`. Con la migración nueva, `VersionEsquemaNg.Esperada` pasa a `20261018181156_T2cAceptaDeSuplidor` y `ScriptEmpresa.Texto()` lanza una excepción porque falta el recurso. `AprovisionamientoTests` falla (compara el contenido y exige un solo recurso) y también falla el aprovisionamiento con `GPOS.Migracion`. | `src/GPOS.Migracion/ScriptEmpresa.cs:20-30`; `tests/GPOS.Tests/ModeloNg/AprovisionamientoTests.cs:161-164`; `ls database/empresa` | Ejecutar `dotnet ef migrations script --idempotent -p src/GPOS.Core -s src/GPOS.Core -c EmpresaNgDbContext -o database/empresa/gpos-empresa-20261018181156_T2cAceptaDeSuplidor.sql` y borrar el anterior. Comprobar que el diff solo agrega el bloque de esta marca (ALTER más el EXEC de los dos UPDATE más el INSERT en el historial), como se hizo con el #48. |
| D-02 | Baja | Un tipo que crea el ADMIN nace con `RequiereRnc = 0` y `AceptaDeSuplidor = 0`, salvo que la pantalla los envíe. Es correcto como dato, pero conviene que la pantalla muestre las dos casillas para que el valor no quede en 0 por descuido. | `AdministracionService.cs:284-294` (diff) | Entrega a desarrollador-frontend o a UX: confirmar que el formulario de tipos envía las dos casillas. |
| D-03 | Baja | El Up modifica datos fiscales sin el comentario `// revisado-por: arquitecto-datos 2026-10-18`. La prueba no lo exige. | Migración, líneas del `migrationBuilder.Sql` | Opcional: agregar el comentario encima del `Sql(...)` como rastro de esta revisión. |

## Riesgos

- **Bloqueo:** despreciable (21 filas, solo DDL y dos UPDATE por clave primaria).
- **Pérdida de datos:** ninguna. El Down solo quita la columna nueva.
- **Compatibilidad hacia atrás:** el código nuevo contra una base sin migrar falla al leer `AceptaDeSuplidor`. Es lo esperado y lo cubre la comprobación de la versión de esquema al iniciar.
- **Nodos de sucursal:** la entidad es `ISoloCentral` y no hay réplica en el código actual. No aplica.

## Supuestos

- El envoltorio `EXEC` del SQL personalizado en el guion idempotente se da por el comportamiento conocido de EF Core 10. Se verifica al regenerar el guion (D-01).
- No ejecuté compilación ni pruebas: revisión de solo lectura.
