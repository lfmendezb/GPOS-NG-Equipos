# Contención parcial bloqueada por el error 12834 en las bases de empresa NG

**Fecha:** 2026-10-15 · **Autor:** arquitecto de datos (equipo A) · **Rama analizada:** `origin/feature/modelo-ng` (7898beeb), leída con `git show` sin tocar la copia de trabajo (que está en `master`).
**Estado de la propuesta:** Pendiente de firma. La aplica el desarrollador-backend; la ejecución en los entornos le corresponde a devops.

---

## 1. Resumen

- **La causa no es `REVERSE` ni la intercalación.** Es un defecto del validador de contención de SQL Server 2019 (15.0.2200.2, RTM-GDR). El `ALTER DATABASE … SET CONTAINMENT` falla con 12834 cuando **una tabla tiene más columnas calculadas que índices filtrados, y al menos un índice filtrado**. El mensaje culpa a la *segunda* columna calculada y menciona una función interna que cambia de una ejecución a otra (`gettimestamp`, `mod`, `dayname`, `@@nestlevel`, `second`): es basura de memoria, no la función real.
- En las bases NG **solo `doc.Documento` cumple esa condición**: tiene 2 columnas calculadas (`NodoOrigenId` persistida y `NumeroInv`) y 1 índice filtrado (`IX_Documento_MotivoAnulacion`). `GPOS_SYSDATA` no tiene ningún bloqueo.
- **Las dos correcciones sugeridas no funcionan:** `REVERSE([Numero]) COLLATE <intercalación>` y la columna `PERSISTED` siguen fallando, tanto en la base real como en la mínima.
- **Corrección propuesta:** quitar el filtro de `IX_Documento_MotivoAnulacion`. Así `doc.Documento` queda con 0 índices filtrados, la base pasa a `PARTIAL` y la búsqueda por sufijo mantiene exactamente el mismo plan. Costo: unos 16 B por documento (3,2 MB por cada 200 000) y un costo de escritura que no se distinguió del ruido. Esfuerzo: unos **1,0 días-persona**.
- **SQL Server 2025 no se pudo verificar.** La instancia `.` tiene `contained database authentication = 0` y el motor se detiene antes de validar (Msg 12824). Cambiar esa opción es decisión del propietario o de devops (`CredencialesLectura.cs:143-144`).

---

## 2. Causa (verificado)

### 2.1 Reproducción con la base real

Construí `GPOS_TEST_CONT_EMP` como lo hace `crear` (`src/GPOS.Migracion/Aprovisionamiento.cs:88`): `CREATE DATABASE … COLLATE Latin1_General_100_CI_AS_SC_UTF8`, RCSI, `AUTO_CLOSE OFF`, y después `database/01_esquema_base.sql`, `database/02_actualizacion_gpos.sql` y `database/empresa/gpos-empresa-20261015003000_Rg14RespaldoTope.sql`. El error 12834 se reproduce igual que en el hallazgo.

Bisección sobre esa base, rehaciéndola cada vez (8 s por intento):

| Qué se quitó de la base | Resultado |
|---|---|
| Las vistas `rpt.ConsultaFactura` y `rptc.ConsultaFactura` (las únicas que nombran `NumeroInv`) | 12834 |
| Los 12 disparadores de `doc.Documento` (deshabilitados y luego eliminados) | 12834 |
| Las 11 restricciones CHECK de `doc.Documento` | 12834 |
| Las 36 claves foráneas (4 salientes y 32 entrantes) | 12834 |
| `IX_Documento_NumeroInv` | 12834 |
| Todos los módulos de la base (174) | 12834 |
| La columna `NumeroInv` | **pasa** |
| **Solo `IX_Documento_MotivoAnulacion` (filtrado), con `NumeroInv` intacta** | **pasa** |
| `NumeroInv` rehecha como `REVERSE([Numero]) COLLATE Latin1_General_100_CI_AS_SC_UTF8` | 12834 |

### 2.2 Regla, aislada en una base mínima

Probé en `GPOS_TEST_CONT_MIN`: una tabla `dbo.T (Id int PK, …)` sin módulos ni claves foráneas.

| Columnas calculadas | Índices filtrados | Resultado |
|---|---|---|
| 1 (cualquier `REVERSE`, `UPPER`, `LEFT`, numérica…) | 0 o 1 | pasa |
| 1 | 2 | pasa |
| 2 | 0 | pasa |
| 2 (numéricas `Id + 1`, `Id + 2`; persistidas o no) | 1 | **12834** |
| 2 | 2 o 3 | pasa |
| 3 | 1 o 2 | **12834** (o solo 12836/5069) |
| 3 | 3 | pasa |
| 4 | 1 o 2 | **12834** |
| 1 en cada una de dos tablas, el filtrado en una de ellas | — | pasa |
| 2 calculadas + 1 CHECK (sin filtrado) | 0 | pasa |

Lo que **no** influye: la función (`REVERSE`, `UPPER`, `LEFT`, `CONVERT`, concatenación o aritmética pura), `PERSISTED`, `COLLATE`, la intercalación de la base (UTF-8 o `SQL_Latin1_General_CP1_CI_AS`), el orden de las columnas (en el orden inverso, el error culpa a la otra), los disparadores, las vistas, las CHECK, las claves foráneas y el `rowversion`.

**Regla observada:** falla una tabla con `calculadas > filtrados ≥ 1`. Es una regla empírica sobre un defecto del motor, no una regla documentada (inferido). Por eso la guarda de la sección 9 se plantea de forma más estricta.

Reproducción mínima (sirve para comprobar otra versión o una CU):

```sql
CREATE DATABASE GPOS_TEST_CONT_MIN COLLATE Latin1_General_100_CI_AS_SC_UTF8;
GO
USE GPOS_TEST_CONT_MIN;
CREATE TABLE dbo.T (Id int NOT NULL PRIMARY KEY, A AS (Id + 1), B AS (Id + 2), X int NULL);
CREATE INDEX F ON dbo.T (X) WHERE X IS NOT NULL;
GO
USE master;
ALTER DATABASE GPOS_TEST_CONT_MIN SET CONTAINMENT = PARTIAL WITH ROLLBACK IMMEDIATE;
-- 2019 RTM-GDR: Msg 12834 «computed column 'B' … depends on builtin function 'gettimestamp'»
```

### 2.3 Hechos adicionales que condicionan la solución

- **`sys.dm_db_uncontained_entities` no detecta este bloqueo.** Solo lista entidades no contenidas, que `PARTIAL` sí admite. La única detección fiable es intentar el `ALTER DATABASE`.
- **Contener primero y crear el esquema después no sirve.** Una base creada como `PARTIAL` acepta la tabla, pero luego `SET CONTAINMENT = NONE` también falla con 12834: la base queda atrapada en `PARTIAL`, sin reversión. Por eso la corrección tiene que quitar la condición, no esquivarla.
- En una base contenida, el catálogo usa `Latin1_General_100_CI_AS_KS_WS_SC`. Una consulta mía que concatenaba `ORIGINAL_LOGIN()` con un dato del catálogo falló en tiempo de ejecución con Msg 451 (conflicto de intercalación). El validador no compila el SQL dinámico (ver el riesgo R-4).

---

## 3. Lista completa de lo que impide la contención

### 3.1 Bases de empresa (guion de la rama + esquema heredado 01/02)

| Objeto | Tipo | ¿Impide `PARTIAL`? | Evidencia |
|---|---|---|---|
| `doc.Documento`: 2 columnas calculadas (`NodoOrigenId`, `NumeroInv`) + 1 índice filtrado (`IX_Documento_MotivoAnulacion`) | Defecto del validador (12834) | **Sí, es el único** | guion `:2996`, `:3001`, `:5952`; `DocConfiguracion.cs:69`, `:84`, `:96`; `20261006100548_Ola3Firmas.cs:373-377` |

Sin ese índice filtrado, la base completa pasa a `PARTIAL`: es el único bloqueo. Las otras 8 columnas calculadas de la base están solas en sus tablas (`caja.Cierre`, `caja.CierreConteo`, `cxc.Aplicacion`, `cxp.Aplicacion`, `fiscal.Registro606`, `fiscal.TipoComprobante`, `inv.ConteoLinea`, `ventas.Venta`). No hay vistas indexadas ni `SCHEMABINDING`, ni seguimiento de cambios, ni CDC.

**No impiden la contención** (son entidades no contenidas que `PARTIAL` admite; las lista `sys.dm_db_uncontained_entities`):

| Entidad | Motivo |
|---|---|
| `caja.TR_Movimiento_Nodo`, `doc.TR_Documento_Candado`, `doc.TR_Documento_Emision`, `sync.EstadoEmision`, `sync.usp_AbrirReconciliacionLocal`, `sync.usp_ConfirmarReconciliacionLocal`, `sync.usp_RegistrarDeteccion` | Leen `sys.database_recovery_status` |
| `conf.usp_RespaldoCopia` | `SERVERPROPERTY`, nombres calificados por servidor o base y `BACKUP DATABASE` |
| `sync.usp_AdelantarSecuencias` | SQL dinámico (líneas 28 y 35 del módulo) |
| `doc.TR_Documento_Ola4` | Resolución diferida de nombres |
| Ruta de Service Broker `AutoCreatedLocal` | Viene en toda base |

### 3.2 `GPOS_SYSDATA`

Usé un clon solo de esquema (`DBCC CLONEDATABASE`) de `GPOS_TEST_SIS_H11B_5a8b3c41`, marca `GPOS.EsquemaSistema = 3`, igual a `EsquemaSistema.Version` de la rama (`EsquemaSistema.cs:73`): **pasa a `PARTIAL` sin cambios**. Tiene 0 columnas calculadas y 5 índices filtrados. Entidades no contenidas admitidas: `dbo.EstadoRestauracionSistema`, `dbo.LiberarCandadoRestauracion` y `dbo.ReconciliarRestauracionSistema` (`sys.database_recovery_status`), `dbo.usp_RespaldoCopia` (`SERVERPROPERTY`, nombres calificados, `BACKUP`) y la ruta de Service Broker.

### 3.3 Bases que hoy existen (consulta de catálogo, solo lectura)

| Instancia | Bases con la condición (`doc.Documento`, 2 calculadas / 1 filtrado) | Contención actual |
|---|---|---|
| `.\SQLEXPRESS` (2019) | `GPOS_DEMO` y 15 de prueba (`GPOS_TEST_0f48af75`, `_3d6b152f`, `_678338b3`, `_726881d8`, `_8decbbfe`, `_b972a1fe`, `_da7fffa5`, `GPOS_TEST_H11B_*` ×4, `GPOS_TEST_K1A_525c8e2e`, `GPOS_TEST_MOD_5724792c`, `GPOS_TEST_VAD_bc5df65f`, `GPOS_TEST_VFU_bc5df65f`) | todas `NONE` |
| `.` (2025) | `GPOS_TEST_A_H2_FULL_20261011_*` ×3 | todas `NONE` |
| ambas | `GPOS_SYSDATA`, `POS_SPORTCITY_SANDBOX` (BP2) y bases `GPOS_TEST_SIS_*`: ninguna tabla con la condición | — |

Durante la consulta, una base de `.\SQLEXPRESS` (`GPOS_TEST_c4d95148`) estaba en transición porque otra sesión ejecutaba pruebas; la omití.

---

## 4. Corrección propuesta

### 4.1 Opciones evaluadas

| Opción | Resultado | Decisión |
|---|---|---|
| `REVERSE([Numero]) COLLATE Latin1_General_100_CI_AS_SC_UTF8` | 12834 (base real y mínima) | Descartada: no corrige |
| `NumeroInv … PERSISTED` | 12834 / 12836 | Descartada: no corrige y añade 20 B por fila |
| Contener la base antes de crear el esquema | La DDL pasa, pero `NONE` queda imposible | Descartada: sin reversión |
| Convertir `NodoOrigenId` o `NumeroInv` en columna normal mantenida por disparador | Quitaría una calculada | Descartada: más código en la ruta caliente de emisión, para el mismo efecto |
| Añadir un segundo índice filtrado para igualar la cuenta | Pasaría (2 y 2) | Descartada: depende del comportamiento interno de un defecto |
| Esperar una CU de 2019 que lo corrija | Sin verificar | No bloquea: los clientes pueden tener RTM-GDR. Queda como comprobación de devops |
| **Quitar el filtro de `IX_Documento_MotivoAnulacion`** | **Pasa**; las consultas que lo usan siguen con Index Seek | **Elegida** |

### 4.2 Índice y consultas que lo justifican

`IX_Documento_MotivoAnulacion (MotivoAnulacionId)`, ahora sin filtro, atiende las mismas consultas de antes (`docs/datos/2026-10-06-diseno-datos-q3-q4-t27.md:142`):
- `EXISTS (… WHERE d.MotivoAnulacionId = @m)` al eliminar o inhabilitar un motivo (`MotivosAnulacionService.cs:47`, `:90`; regla «eliminar solo sin referencias»);
- `cat.TR_MotivoAnulacion_Inmutable` (`SqlMigracionesOla3Firmas.cs:89`);
- la validación de `FK_Documento_MotivoAnulacion` al borrar un motivo.

Todas son igualdades, que también encuentran las claves en un índice sin filtro.

### 4.3 Cambio en el modelo

`src/GPOS.Core/Datos/Empresa/Configuracion/DocConfiguracion.cs:84`:

```csharp
// RG-14 D-04 (a): sin filtro. Con 2 columnas calculadas (NodoOrigenId, NumeroInv) y un índice filtrado, SQL Server 2019
// rechaza CONTAINMENT = PARTIAL con 12834 (datos-contencion-12834-2026-10-15). No volver a filtrar índices de doc.Documento.
b.HasIndex(x => x.MotivoAnulacionId).HasDatabaseName("IX_Documento_MotivoAnulacion");
```

`HasComputedColumnSql("REVERSE([Numero])", stored: false)` (`:96`) **no cambia**, y tampoco `20261005213319_Ola3.cs:565` ni el guion `:3001`. Las migraciones vigentes no se editan.

### 4.4 Migración nueva (después de `20261015003000_Rg14RespaldoTope`)

Nombre sugerido: `<marca>_Rg14ContencionMotivoAnulacion`. EF Core 10.0.12 (`GPOS.Core.csproj`) genera `DropIndex` + `CreateIndex` al cambiar el filtro. Propongo seguir el patrón del proyecto (`migrationBuilder.Sql(SqlMigraciones.…)`) con SQL idempotente, para que el guion `--idempotent` también sirva sobre bases a medio aplicar.

**Up** (probado en la base de prueba; la segunda ejecución no hace nada):

```sql
IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[doc].[Documento]')
           AND name = N'IX_Documento_MotivoAnulacion' AND has_filter = 1)
    DROP INDEX [IX_Documento_MotivoAnulacion] ON [doc].[Documento];
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[doc].[Documento]')
               AND name = N'IX_Documento_MotivoAnulacion')
    CREATE INDEX [IX_Documento_MotivoAnulacion] ON [doc].[Documento] ([MotivoAnulacionId]);
```

**Down** (probado: con la base en `PARTIAL` se niega; con `NONE` restaura el filtro y es idempotente). El número 51616 está libre en la rama, en el rango 516xx de RG-14; lo confirma el desarrollador-backend.

```sql
IF EXISTS (SELECT 1 FROM sys.databases WHERE database_id = DB_ID() AND containment <> 0)
    THROW 51616, N'No se puede revertir con la base en CONTAINMENT = PARTIAL: el índice filtrado volvería a impedir la contención en los dos sentidos (12834). Elimine los usuarios contenidos y pase la base a CONTAINMENT = NONE antes de revertir.', 1;
IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[doc].[Documento]')
           AND name = N'IX_Documento_MotivoAnulacion' AND has_filter = 0)
    DROP INDEX [IX_Documento_MotivoAnulacion] ON [doc].[Documento];
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[doc].[Documento]')
               AND name = N'IX_Documento_MotivoAnulacion')
    CREATE INDEX [IX_Documento_MotivoAnulacion] ON [doc].[Documento] ([MotivoAnulacionId]) WHERE [MotivoAnulacionId] IS NOT NULL;
```

La guarda es necesaria. Recrear el filtro en una base ya contenida *funciona*, pero deja la base sin posibilidad de cambiar su contención en ningún sentido (sección 2.3).

Además, al unir:
- regenerar el guion `database/empresa/gpos-empresa-<nueva marca>.sql`. `VersionEsquemaNg.Esperada` (`VersionEsquemaNg.cs:27`) toma la migración nueva sola;
- actualizar el snapshot del modelo y `contrato-vistas` si este describe índices (no lo verifiqué).

### 4.5 Medido en la base de prueba (200 000 documentos sintéticos, 1 % anulados)

| Medida | Antes (`NONE`, filtrado) | Después (`PARTIAL`, sin filtro) |
|---|---|---|
| `ALTER DATABASE … SET CONTAINMENT = PARTIAL` | 12834 | **pasa** |
| Búsqueda por sufijo (la consulta de `UltimoEmitido.Busqueda.cs:274` y `:296-299`, `@inv varchar(41) = '7654%'`, tipo 4) | Index Seek `IX_Documento_NumeroInv` → Clustered Seek `PK_Documento` → Seek `PK_Sucursal`; 20 filas; 104 lecturas lógicas; sin conversiones implícitas | **idéntico**: mismo plan, 20 filas, 104 lecturas |
| `EXISTS (… MotivoAnulacionId = @m)` | Index Seek `IX_Documento_MotivoAnulacion`, 2 lecturas | Index Seek `IX_Documento_MotivoAnulacion`, 3 lecturas |
| Tamaño de `IX_Documento_MotivoAnulacion` | 80 KB (2 000 filas) | 3 200 KB (200 000 filas) ≈ 16 B por documento |
| Tras 50 000 inserciones adicionales | 10 páginas, 20 % de fragmentación | 584 páginas, 2,7 % de fragmentación, 99,4 % de ocupación (las inserciones caen al final del tramo NULL sin divisiones a la mitad) |
| Tiempo de 20 000 inserciones (dos rondas alternadas) | 13,8 s y 9,3 s | 5,4 s y 8,9 s → la diferencia queda dentro del ruido (otra sesión usaba la instancia) |
| Duración del Up | — | 543 ms con 200 000 filas (≈ 2,7 ms por cada 1 000) |
| Usuario contenido con contraseña | — | entra (`authentication_type_desc = DATABASE`) y lee `doc.Documento` por `NumeroInv` |

**Costo en disco:** unos 16 MB por millón de documentos. Una empresa con 300 documentos al día suma unos 1,8 MB al año: 0,02 % del tope de 10 GB de Express. Sin costo monetario.

### 4.6 EF Core: diferencias de modelo

**No verificado.** No compilé la rama: la PC A admite dos agentes con compilación y había otra sesión ejecutando pruebas en la instancia. Como `HasComputedColumnSql` no cambia, la comprobación pedida para la columna no aplica. Para el índice, el desarrollador-backend debe ejecutar, después de crear la migración:

```
dotnet ef migrations has-pending-model-changes --project src/GPOS.Core --context EmpresaNgDbContext
```

Lo esperado (inferido del comportamiento estándar de EF Core con `HasFilter`) es «sin cambios pendientes».

---

## 5. Efecto en las bases ya creadas y en BP2→NG

- **Bases de empresa NG existentes** (`GPOS_DEMO` y las de prueba de la sección 3.3): `actualizar` aplica la migración nueva. Ninguna está contenida, así que el Down sigue disponible. No se pierden datos: solo se rehace un índice.
- **Bloqueo durante el Up:** en Express `CREATE INDEX` es fuera de línea y mantiene un bloqueo compartido sobre `doc.Documento` mientras dura: unos 0,5 s con 200 000 filas y unos 5 a 6 s con 2 millones (extrapolación lineal, ±50 %). Hay que aplicarlo con la API detenida, como el resto de `actualizar`.
- **`GPOS_SYSDATA`:** sin efecto.
- **BP2→NG:** la base BP2 (`POS_SPORTCITY_SANDBOX`) nunca se contiene y no se toca. La conversión importa sobre una base creada por `Aprovisionamiento.CrearAsync`, que ya traerá la migración nueva. El orden previsto (crear → importar → `crear-lectura`, que contiene la base en `CredencialesLectura.cs:163`) no cambia. BP2 nunca salió a producción, así que no hay costumbres que proteger.
- **Bases que ya estuvieran en `PARTIAL` con el filtro:** no existe ninguna (todas `NONE`). Si apareciera una, el Up la corrige igual (la DDL no se valida en una base contenida).

---

## 6. Riesgos

| # | Riesgo | Severidad | Mitigación |
|---|---|---|---|
| R-1 | La regla `calculadas > filtrados ≥ 1` es empírica. Puede haber otras combinaciones del mismo defecto que no probé | Media | Guarda doble (sección 9): prohibir índices filtrados en tablas con ≥ 2 columnas calculadas y una prueba con `ALTER DATABASE` real sobre una base recién creada |
| R-2 | Una migración futura vuelve a filtrar un índice de `doc.Documento` o añade una columna calculada en otra tabla con filtros | Media | La misma guarda y el comentario en `DocConfiguracion.cs:84` |
| R-3 | Down en una base contenida | Baja | Guarda 51616 (probada) |
| R-4 | **Intercalación en tiempo de ejecución en la base contenida:** el catálogo pasa a `Latin1_General_100_CI_AS_KS_WS_SC` y el validador no compila el SQL dinámico (`sync.usp_AdelantarSecuencias` y los `EXEC(N'…')` de los disparadores). Vi un Msg 451 con una consulta propia | Media | P-B1 de ADR-54 (`COLLATE CATALOG_DEFAULT`). Ejecutar una vez la suite `ModeloNg` contra una base de empresa contenida |
| R-5 | SQL Server 2025 sin verificar | Media | Sección 7 |
| R-6 | Bloqueo de unos segundos al rehacer el índice en bases grandes | Baja | `actualizar` con la API detenida |
| R-7 | Observación fuera de alcance: `IX_Documento_NumeroInv` llega a 99 % de fragmentación y 62 % de ocupación tras 50 000 inserciones, porque el número invertido reparte las inserciones. Es inherente a N-4 y no afecta a los seeks | Baja | Incluirlo en el mantenimiento de índices (devops) |

---

## 7. SQL Server 2025 (`.`, 17.0.1145.4)

**No verificado.** Con `contained database authentication = 0`, `ALTER DATABASE … SET CONTAINMENT = PARTIAL` se detiene con Msg 12824 antes de validar los módulos, así que no se puede observar el 12834. No cambié la opción: es configuración de la instancia (decisión del propietario o de devops). El comentario «verificado en SQL Server 2025 el 2026-10-10» (`CredencialesLectura.cs:149`) se refiere al 18456 en modo «solo Windows», no a esta validación.

Para cerrarlo: con la opción en 1 (y devuelta luego a 0 si se quiere), ejecutar la reproducción mínima de la sección 2.2 en `.`. Unos 10 minutos. Pase o no, la corrección propuesta vale para las dos versiones, porque elimina la condición en lugar de depender del arreglo del motor. Tampoco verifiqué si alguna CU de 2019 lo corrige (la instancia está en RTM-GDR, 15.0.2200.2).

---

## 8. Estimación

| Tarea | Responsable | Días-persona |
|---|---|---|
| Cambio del modelo, migración con Up/Down idempotentes, guion regenerado y `has-pending-model-changes` | desarrollador-backend | 0,4 |
| Guarda de esquema (sección 9, puntos 6 y 7) | desarrollador-backend | 0,2 |
| Ejecutar las pruebas `[FactUsuariosContenidos]` y la suite oficial (`Transicion!=Ola5&Transicion!=Defecto`) en `.\SQLEXPRESS` | qa | 0,3 |
| Verificación en 2025 (sección 7) | devops o propietario | 0,1 |
| **Total** | | **≈ 1,0** (margen de 0,75 a 1,5) |

---

## 9. Pruebas que deberían pasar después

`.\SQLEXPRESS` cumple hoy las tres condiciones de `InstanciaContenidos` (`CredencialesLecturaRealesTests.cs:23-48`): modo mixto, `sa` deshabilitada y `contained database authentication = 1`. Por eso estas pruebas **se ejecutan** (no se omiten) y hoy deberían fallar con 12834 en las que contienen una base de empresa:

| # | Prueba | Por qué falla hoy | Después |
|---|---|---|---|
| 1 | `Rg14VerificarTests.PA28_un_usuario_contenido_ajeno_aparece_como_USUARIO_CONTENIDO_AJENO` (`:246-255`) | `ALTER DATABASE … SET CONTAINMENT = PARTIAL` sobre una base recién creada con `CrearAsync` | Pasa |
| 2 | `Rg14Lote2Tests.Aprovisionar_crea_la_credencial_contenida_repetido_queda_al_dia_y_credencial_app_rota` (`:388`) | Contiene la base de empresa al crear la credencial | Pasa |
| 3 | `CredencialesLecturaRealesTests.Crear_leer_rotar_negar_y_releer_ante_un_18456_real_con_los_sobres_reales` (`:324`, comprueba `PARTIAL` en `:334`) | `CredencialesLectura.ExigirContencionAsync` (`:163`) sobre la base de empresa del arnés | Pasa |
| 4 | `CredencialesLecturaRealesTests.Cada_rol_real_ve_solo_lo_permitido` (`:418`) | La misma preparación | Pasa |
| 5 | `CredencialesLecturaSaTests.La_instancia_de_pruebas_tiene_sa_deshabilitada_y_el_comando_lo_ve` (`:31`) | No contiene ninguna base: no la afecta | Sigue pasando |

No ejecuté estas pruebas (no compilé). La tabla de «falla hoy» es una inferencia a partir de su código y de la reproducción.

Pruebas nuevas que propongo (para el desarrollador-backend y qa):

6. **Esquema:** en una base creada con `CrearAsync`, ninguna tabla con 2 o más columnas calculadas tiene índices filtrados. Consulta: `sys.computed_columns` y `sys.indexes.has_filter`, agrupadas por `object_id`.
7. **Contención real:** `CrearAsync` → `SET CONTAINMENT = PARTIAL` → `SET CONTAINMENT = NONE`, las dos con éxito. Va con `[FactUsuariosContenidos]` porque necesita la opción en la instancia.
8. **Down:** con la base en `PARTIAL`, revertir la migración devuelve 51616 y deja el índice sin filtro.

---

## Entregas a otros agentes

- **desarrollador-backend:** secciones 4.3 y 4.4, guardas 6 a 8 y `has-pending-model-changes`.
- **qa:** sección 9 (pruebas 1 a 5 y la suite oficial) y una pasada de `ModeloNg` contra una base contenida (R-4).
- **devops / propietario:** verificar en 2025 (sección 7) y, si se quiere, comprobar una CU reciente de 2019. Añadir `IX_Documento_NumeroInv` al mantenimiento (R-7).
- **arquitecto-maestro:** registrar como precisión de RG-14 D-04 (a) la regla «nada de índices filtrados en tablas con 2 o más columnas calculadas».

## Supuestos

- La regla del defecto se dedujo de 25 combinaciones en una base mínima; puede no cubrir todos los casos (R-1).
- La extrapolación del tiempo de Up a 2 millones de filas es lineal (±50 %).
- `contrato-vistas.v1.json` no describe índices (no lo verifiqué).
