# Diseño de datos: H-11, seguimiento S-2. El respaldo posterior se identifica por reconciliación y fork

- **Fecha:** 2026-10-15. **Autor:** arquitecto-datos, equipo A. **Versión:** 1.
- **Origen:** `validacion-h11-500-pool-2026-10-15.md`, punto 3 (severidad Media) y seguimiento S-2.
- **Base leída (solo lectura):** árbol `GPOS-NG-h11c`, rama `a/h11-sysdata-candado` (incluye #24). Para la marca de esquema y los permisos de RG-14 también leí `GPOS-NG-rg14l2` (rama `a/rg14-lote2`, PR #36), que **no** contiene `a/h11-sysdata-candado` (`git merge-base --is-ancestor`). No compilé ni ejecuté nada.
- **Para quién:** el desarrollador-backend de A, que lo construye en un PR propio en cuanto B una #24, #26 y #28.

## 1. Contexto y modelo de tenencia aplicado

**El defecto [V, por lectura del código]:**
1. `sync.Reconciliacion` vive en la base de la empresa y toma su `Id` de un `IDENTITY` (`src/GPOS.Core/Datos/Empresa/Migraciones/SqlMigracionesH11.cs:73-75`). Un `RESTORE` devuelve el contador al valor que tenía el respaldo.
2. `dbo.RespaldoPosterior` vive en `GPOS_SYSDATA`, que no se restaura junto con la empresa. Su clave de idempotencia es `(EmpresaCodigo, ReconciliacionId, BaseDatos)`: índice `UX_RespaldoPosterior_Pedido` (`src/GPOS.Core/Consultas/Sistema/Restauracion/EsquemaRestauracionSistema.cs:225-226`) y `NOT EXISTS` de `EncolarRespaldo` (`ConsultasRestauracionSistema.cs:33-38`).
3. Si se restaura un respaldo anterior al desbloqueo N, el siguiente desbloqueo vuelve a recibir N. `EncolarRespaldo` no inserta nada, y `UltimosRespaldos` y `ReintentarRespaldos` (`ConsultasRestauracionSistema.cs:40-44` y `:50-54`, ambas con `MAX(ReconciliacionId)`) presentan las filas del desbloqueo anterior como si fueran las del actual.

**El discriminador ya existe [V]:**
- `sync.usp_AbrirReconciliacionLocal` lee `recovery_fork_guid`, lanza 51328 si es `NULL` y lo guarda en `sync.Reconciliacion.ForkActual` (`SqlMigracionesH11.cs:61-63`, `:73-74`).
- `usp_ConfirmarReconciliacionLocal` exige que siga siendo el mismo al confirmar (C1, `:112-118`).
- El servicio ya lo tiene en la mano después del commit: `RestauracionSitioService.cs:230` devuelve `abierta.ForkActual` y `DespuesDelCommitAsync` lo recibe como `fork` (`:237`, `:244`). Hoy no se lo pasa a `EncolarAsync` (`:256`).
- Cada `RESTORE` genera un fork nuevo, así que el par `(ReconciliacionId, ForkActual)` no se repite entre restauraciones.

**Tenencia:** base por empresa más `GPOS_SYSDATA`. `RespaldoPosterior` está en `GPOS_SYSDATA` y se aísla por `EmpresaCodigo` (FK a `dbo.Empresas`), sin cambios. Toda consulta de este diseño filtra por `EmpresaCodigo = @e`.

**Qué no cambia:**
- **La base de la empresa no cambia.** No hay migración EF de empresa, así que la regla de marcas de B no aplica en este PR.
- **El candado no cambia:** la detección por fork (ADR-53, cláusula 9) ya funcionaba. Este cambio repara la defensa de P-7 (el respaldo posterior a cada desbloqueo) y lo que ve el SUPER.

## 2. Tablas y relaciones

Una columna nueva en `dbo.RespaldoPosterior` (`GPOS_SYSDATA`):

| Columna | Tipo | Nulo | Default | Significado |
|---|---|---|---|---|
| `ForkActual` | `uniqueidentifier` | NOT NULL | `DF_RespaldoPosterior_Fork` = `'00000000-0000-0000-0000-000000000000'` | `recovery_fork_guid` de la base de la empresa al abrir la reconciliación (el mismo `sync.Reconciliacion.ForkActual`). El GUID cero es el **centinela «anterior a S-2»**: no lo produce SQL Server para una base en línea |

Sin tablas nuevas. **Volumen:** 2 filas por desbloqueo y menos de 100 al año (DD-15 del diseño P-7). La columna agrega 16 B por fila: menos de 2 KB al año. **Costo de hosting:** cero.

**Por qué el `DEFAULT` se queda (y no se borra después de rellenar):**
1. **Árboles viejos que comparten la base.** En desarrollo, varios árboles usan el mismo `GPOS_SYSDATA` (R-D14, `datos-h11-p7-candado-2026-10-10.md:418-420`). Un árbol sin S-2 inserta sin `ForkActual`; sin default fallaría con 515 y perdería su respaldo posterior.
2. **Reversión solo de código.** Con el default, el binario anterior funciona sobre el esquema nuevo (sección 7.3).
3. **Prueba existente.** `CandadoRestauracionApiTests.cs:226` inserta sin la columna.
4. **Contra el olvido en el código nuevo:** se usa una guarda en el servicio (`Guid.Empty` → error) y una prueba (sección 7.4, P-3), no la ausencia del default.

## 3. Restricciones e integridad

- **Unicidad (nueva clave de idempotencia):** `(EmpresaCodigo, ReconciliacionId, ForkActual, BaseDatos)`. Se conserva el nombre `UX_RespaldoPosterior_Pedido`. Un árbol viejo que arranque ve que el índice ya existe y no lo vuelve a crear con tres columnas, cosa que sí haría si el nombre cambiara.
- **Sin `CHECK (ForkActual <> GUID cero)`.** Si las filas antiguas quedaran fuera de la comprobación con `WITH NOCHECK`, la restricción se evaluaría igual en cada `UPDATE` de esas filas (`TomarRespaldo`, `FallarRespaldo`, `ReintentarRespaldos`) y una fila antigua en P, E o F quedaría atascada. La regla vive en `EncolarAsync`.
- No cambian la FK a `dbo.Empresas`, `CK_RespaldoPosterior_Estado`, `CK_RespaldoPosterior_Datos` ni el `DENY DELETE` a `gpos_api`.

## 4. Índices y consultas que los justifican

| Índice | Cambio | Consultas que atiende | Costo de escritura |
|---|---|---|---|
| `UX_RespaldoPosterior_Pedido (EmpresaCodigo, ReconciliacionId, ForkActual, BaseDatos)` | Se rehace con `DROP_EXISTING = ON` (la clave pasa de 3 a 4 columnas) | `EncolarRespaldo` (búsqueda por las 4 columnas, con rango `UPDLOCK, HOLDLOCK`); `RespaldosDelDesbloqueo` (búsqueda por las 3 primeras); la parte `TOP (1) … ORDER BY Id DESC` de `UltimosRespaldos` y `ReintentarRespaldos`, que recorre el tramo de la empresa: decenas de filas, cubierto porque la hoja lleva `ReconciliacionId`, `ForkActual` e `Id`, que es la clave del índice agrupado | 2 inserciones por desbloqueo |

**Índice descartado:** `(EmpresaCodigo, Id DESC)` o `(EmpresaCodigo, SolicitadoUtc DESC)` para «el último pedido». Con menos de 100 filas al año por instalación, el tramo de la empresa en el índice único basta. Se reconsidera si una empresa supera las 10 000 filas, cosa que no ocurrirá en la vida útil prevista.

**Plan esperado [I]:** búsqueda en `UX_RespaldoPosterior_Pedido` por `EmpresaCodigo` → `TOP (1)` por `Id` → búsqueda por `(e, r, fork)` → búsqueda de clave en `PK_RespaldoPosterior` para 2 filas. Unas 10 lecturas lógicas.

## 5. Auditoría y trazabilidad

- **Recomendado, sin cambio de esquema:** agregar el fork al `Detalle` JSON de `RESPALDO_POSTERIOR` en la bitácora de la empresa (`AuditarRespaldo`, `RespaldosPosteriores.cs:101-109`), como `{ reconciliacion, fork, archivo }`.
  - Para eso, `TomarRespaldo` devuelve también `inserted.ForkActual` y la clase `Fila` lo lleva.
  - Así queda claro qué copia cubre qué desbloqueo cuando el número se repite.
- **El nombre del archivo `.bak` no cambia** (`{base}_DESBLOQUEO_{n}_{fecha}_{hora}`). La hora UTC ya lo hace único, y la etiqueta de `usp_RespaldoCopia` (RG-14 lote 2) admite como máximo 20 caracteres de `[A-Z0-9_]`, así que no cabe el fork.

## 6. Persistencia de sincronización

No aplica. `sync.Reconciliacion` no cambia: se usa su `ForkActual`, que ya existe.

## 7. Script de migración y reversión

### 7.1 Dónde va

El esquema de `GPOS_SYSDATA` **no** va por migraciones EF de empresa. Va en el lote idempotente `SqlRespaldoPosterior` (`EsquemaRestauracionSistema.cs:202-227`). Lo aplican:
- el arranque de la API en Amplio (`EsquemaSistema.ActualizarAsync`);
- en Estricto, `GPOS.Migracion sistema` (RG-14 lote 2, `ComandoSistema.cs:38` en `GPOS-NG-rg14l2`).

Se reemplazan las dos últimas líneas del lote (el `IF NOT EXISTS … CREATE UNIQUE INDEX` de `:225-226`) por el bloque siguiente. El `CREATE TABLE` no se toca: las bases nuevas y las existentes siguen **un solo camino**, el `ALTER`.

### 7.2 DDL (idempotente, sin `GO` ni llaves de C#)

```sql
-- S-2 de H-11: la clave del pedido incluye el fork de la base de la empresa (un RESTORE hace retroceder el IDENTITY de sync.Reconciliacion)
IF COL_LENGTH(N'dbo.RespaldoPosterior', N'ForkActual') IS NULL
    ALTER TABLE dbo.RespaldoPosterior ADD ForkActual uniqueidentifier NOT NULL
        CONSTRAINT DF_RespaldoPosterior_Fork DEFAULT ('00000000-0000-0000-0000-000000000000') WITH VALUES;
-- El índice cita la columna nueva: va en EXEC (en una tabla que ya existe, el lote no difiere la resolución de la columna)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_RespaldoPosterior_Pedido' AND object_id = OBJECT_ID(N'dbo.RespaldoPosterior'))
    EXEC (N'CREATE UNIQUE INDEX UX_RespaldoPosterior_Pedido ON dbo.RespaldoPosterior (EmpresaCodigo, ReconciliacionId, ForkActual, BaseDatos);');
ELSE IF NOT EXISTS (SELECT 1 FROM sys.indexes i
                      JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
                     WHERE i.object_id = OBJECT_ID(N'dbo.RespaldoPosterior') AND i.name = N'UX_RespaldoPosterior_Pedido'
                       AND COL_NAME(ic.object_id, ic.column_id) = N'ForkActual')
    EXEC (N'CREATE UNIQUE INDEX UX_RespaldoPosterior_Pedido ON dbo.RespaldoPosterior (EmpresaCodigo, ReconciliacionId, ForkActual, BaseDatos)
           WITH (DROP_EXISTING = ON);');
```

**Cómo se rellenan las filas existentes:**
- `WITH VALUES` pone el GUID cero en todas, dentro del mismo `ALTER`.
- No se intenta recuperar el fork real desde `sync.Reconciliacion` de cada empresa. Exigiría abrir cada base de empresa (cadenas cifradas, otra conexión) desde un lote de `GPOS_SYSDATA`, y no aporta nada.
- Hoy todo es desarrollo: las filas existentes son de pruebas. El fork cero solo tiene que ser distinto de cualquier fork real, y lo es.
- La nueva clave de 4 columnas es más laxa que la de 3, así que `DROP_EXISTING` no puede fallar por duplicados.

**Idempotencia:** con la columna presente y el índice ya en 4 columnas, el lote no hace nada. Correrlo dos veces seguidas no cambia `sys.indexes` ni `sys.columns` (prueba P-5).

### 7.3 Reversión

**La reversión recomendada es solo de código.** El binario anterior funciona sobre el esquema nuevo:
- inserta sin `ForkActual`, que recibe el default;
- su `NOT EXISTS (e, r, b)` se comporta como antes;
- su `UltimosRespaldos` lee las columnas que siguen existiendo;
- Estricto acepta una marca mayor (`Inicializacion.cs:86` en `GPOS-NG-rg14l2` solo rechaza una marca **menor**).

Esquema inverso, solo si hay que quitar la columna. Lo ejecuta un administrador, no la API:

```sql
-- Volver a la clave de tres columnas solo si ningún número de reconciliación se repitió entre forks (no se borra historia: Devops toma de aquí los archivos)
IF COL_LENGTH(N'dbo.RespaldoPosterior', N'ForkActual') IS NOT NULL
BEGIN
    IF EXISTS (SELECT 1 FROM dbo.RespaldoPosterior GROUP BY EmpresaCodigo, ReconciliacionId, BaseDatos HAVING COUNT(*) > 1)
        THROW 52010, N'S-2: hay desbloqueos con el mismo número en forks distintos; la clave de tres columnas perdería historia. Revierta solo el código.', 1;
    EXEC (N'CREATE UNIQUE INDEX UX_RespaldoPosterior_Pedido ON dbo.RespaldoPosterior (EmpresaCodigo, ReconciliacionId, BaseDatos) WITH (DROP_EXISTING = ON);');
    ALTER TABLE dbo.RespaldoPosterior DROP CONSTRAINT DF_RespaldoPosterior_Fork;
    ALTER TABLE dbo.RespaldoPosterior DROP COLUMN ForkActual;
END;
-- La marca GPOS.EsquemaSistema no se baja (solo sube; R-D14)
```

52010 está libre en `src` de `GPOS-NG-h11c`, `GPOS-NG-rg14l2` y `GPOS-NG-lic3` [V, búsqueda de texto]. Sigue a la serie 52001-52009 de H-11 en `GPOS_SYSDATA`. Si el reverso se ejecuta con la API arriba, debe repetirse: un árbol nuevo que arranque vuelve a agregar la columna.

### 7.4 Cambios de consultas y servicio

**`ConsultasRestauracionSistema`:**

```sql
-- EncolarRespaldo: idempotente por empresa, reconciliación, fork y base
INSERT INTO dbo.RespaldoPosterior (EmpresaCodigo, ReconciliacionId, ForkActual, BaseDatos, EsSistema, SolicitadoPor)
SELECT @e, @r, @f, @b, @s, @por
 WHERE NOT EXISTS (SELECT 1 FROM dbo.RespaldoPosterior WITH (UPDLOCK, HOLDLOCK)
                    WHERE EmpresaCodigo = @e AND ReconciliacionId = @r AND ForkActual = @f AND BaseDatos = @b)

-- RespaldosDelDesbloqueo
<ColumnasRespaldo> WHERE EmpresaCodigo = @e AND ReconciliacionId = @r AND ForkActual = @f ORDER BY EsSistema

-- UltimosRespaldos: el último pedido de la empresa por orden de inserción, no por número de reconciliación
SELECT p.Id, p.BaseDatos, p.Estado, p.Archivo, p.SolicitadoUtc, p.TerminadoUtc, p.Intentos, p.Error, p.EmpresaCodigo, p.ReconciliacionId, p.EsSistema
  FROM dbo.RespaldoPosterior p
  JOIN (SELECT TOP (1) ReconciliacionId, ForkActual FROM dbo.RespaldoPosterior WHERE EmpresaCodigo = @e ORDER BY Id DESC) u
    ON u.ReconciliacionId = p.ReconciliacionId AND u.ForkActual = p.ForkActual
 WHERE p.EmpresaCodigo = @e
 ORDER BY p.EsSistema

-- ReintentarRespaldos: los fallidos del mismo último pedido
UPDATE p SET Estado = 'P', Intentos = 0, Error = NULL
  FROM dbo.RespaldoPosterior p
  JOIN (SELECT TOP (1) ReconciliacionId, ForkActual FROM dbo.RespaldoPosterior WHERE EmpresaCodigo = @e ORDER BY Id DESC) u
    ON u.ReconciliacionId = p.ReconciliacionId AND u.ForkActual = p.ForkActual
 WHERE p.EmpresaCodigo = @e AND p.Estado = 'F'
```

- `@f` es un `Guid` de Dapper, que se envía como `uniqueidentifier`. Los demás parámetros conservan sus tipos actuales (`nvarchar` en `GPOS_SYSDATA`; ADR-50 no aplica).
- `ColumnasRespaldo` puede quedarse para `RespaldoPorId` y `RespaldosDelDesbloqueo`. `UltimosRespaldos` necesita alias, así que se escribe completa.
- **Precisión del remedio de la validación (orden por `Id DESC` en lugar de `SolicitadoUtc`):**
  - Los dos dan el mismo resultado en operación normal.
  - `Id` (IDENTITY de `GPOS_SYSDATA`) crece con cada inserción y no depende del reloj del servidor. `SolicitadoUtc` es `datetime2(0)`: empata dentro del mismo segundo y retrocede si se corrige la hora.
  - Si se restaura `GPOS_SYSDATA`, sus filas posteriores desaparecen junto con su `Id`, y el orden sigue siendo correcto entre las filas que quedan.
  - Si el arquitecto prefiere la fecha, la forma equivalente es `ORDER BY SolicitadoUtc DESC, Id DESC`.

**`RespaldosPosteriores` e `IRespaldosPosteriores`:**
- `EncolarAsync(string empresa, int reconciliacion, Guid fork, string usuario, CancellationToken ct)`.
- Si `fork == Guid.Empty`, lanza `ReglaNegocioException` antes de escribir. Ya está capturada en `RestauracionSitioService.cs:257` y produce el aviso «No se pudo encolar…».
- `DelDesbloqueoAsync` recibe y filtra por `fork`.
- `RestauracionSitioService.DespuesDelCommitAsync` pasa `fork`. Si llega `null` (no ocurre: 51328 lo impide al abrir), no encola y agrega el mismo aviso.
- `RespaldosEnMemoria` (`tests/GPOS.Tests/ModeloNg/RestauracionDobles.cs:51`) adopta la firma nueva.
- **El contrato `RespaldoPosteriorDto` no cambia.**

### 7.5 Marca de esquema de `GPOS_SYSDATA`

**Sí cambia, con una condición de orden:**
- **Si #36 (RG-14 lote 2) ya está en `master` cuando se una S-2:** `EsquemaSistema.Version` sube de su valor en ese momento a ese valor + 1. Hoy es `1` (`src/GPOS.Core/Data/Sistema/EsquemaSistema.cs:72` en `GPOS-NG-rg14l2`); si L1a-4 u otro PR ya lo subió, se suma 1 a ese valor.
  - Sin la subida, una API en Estricto arrancaría contra un `GPOS_SYSDATA` sin la columna.
  - Cada `EncolarRespaldo` fallaría con 207. El servicio lo convierte en un aviso, y `UltimosRespaldos` se traga el error (`RestauracionSitioService.cs:327-328`).
  - Resultado: **pérdida silenciosa** del respaldo posterior. Con la marca subida, Estricto no arranca y pide «Ejecute GPOS.Migracion sistema».
- **Si S-2 se une antes que #36:** no hay marca que subir. La versión 1 que introduce #36 ya incluirá esta DDL, porque `ActualizarAsync` la aplica antes de `SubirMarca`.
- Las pruebas de `Rg14Lote2Tests` se parametrizan con `EsquemaSistema.Version` (`:89`, `:196`), así que siguen valiendo.

**Migración EF de empresa:** ninguna. La regla de marcas de B (marca posterior a la última unida) no se activa en este PR.

## 8. Respaldo, restauración y retención

- **Retención:** sin cambios (sin purga, DD-15 del diseño P-7).
- **Restauración:** este diseño corrige precisamente que, tras restaurar la empresa, el siguiente desbloqueo deje su propio respaldo `COPY_ONLY` de las dos bases.
- **Recomendación a Devops:** al elegir qué `.bak` restaurar, identificar el desbloqueo por `(ReconciliacionId, ForkActual)` o por `Id` de la fila, no solo por el número que aparece en el nombre del archivo.

## 9. Privilegios de base de datos

**Sin cambios [V]:**
- `gpos_api` recibe `GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo` (`PrivilegioMinimoSistema.cs:124` en `GPOS-NG-rg14l2`): cubre la columna nueva sin concesión por columna.
- `DENY DELETE ON OBJECT::dbo.RespaldoPosterior` (`:131`) se mantiene.
- La DDL la aplica la identidad administrativa de `GPOS.Migracion sistema` en Estricto, o la API en Amplio. `gpos_api` tiene `DENY` sobre la creación de objetos y no tiene `ALTER` sobre la tabla, que es lo correcto.
- No se agrega nada a `ExtensionesEsquemaSistema.Permisos`.

## 10. Pruebas que debe tener

| # | Tipo | Escenario | Resultado esperado |
|---|---|---|---|
| **P-1** (CA-S2-01, la del hallazgo) | Integración con restauraciones reales (patrón de `CandadoRestauracionApiTests`, `RestaurarAsync`) | (1) `BACKUP COPY_ONLY` B0 de la empresa; (2) restaurar B0 → R3 → desbloqueo N con fork F1; (3) restaurar **otra vez B0**, anterior al desbloqueo → R3 → desbloqueo con fork F2 | (a) El segundo desbloqueo recibe el **mismo** número N; se comprueba para demostrar la premisa y, si el motor diera otro número, la prueba lo informa y no pasa en falso. (b) La empresa tiene 4 filas: 2 con `(N, F1)` y 2 con `(N, F2)` en P. (c) `resultado.Respaldos` de R3 trae las 2 filas de F2 (sus `Id` son los nuevos). (d) R1 (`GET` del estado) muestra esas mismas 2 filas y ninguna de F1. (e) El trabajador las pasa a C, y `RESTORE VERIFYONLY … WITH CHECKSUM` valida los dos archivos |
| P-2 | Integración | Llamar a `EncolarAsync` dos veces con la misma `(e, N, F2)` | Siguen siendo 2 filas; la segunda llamada devuelve las mismas `Id` |
| P-3 | Unitaria / integración | `EncolarAsync` con `Guid.Empty` | `ReglaNegocioException`; ninguna fila |
| P-4 | Integración (R4) | Una fila F de `(N, F1)` y el último pedido `(N, F2)` sin fallidos | R4 responde 409 `SIN_RESPALDO_PENDIENTE` y la fila de F1 sigue en F. Con una F en `(N, F2)`, R4 solo la reinicia a ella |
| P-5 | Esquema | Base con la forma anterior (tabla de `:202-224` y el índice de 3 columnas, con 2 filas) → `ActualizarAsync` dos veces | Columna NOT NULL con el GUID cero en las filas antiguas; `UX_RespaldoPosterior_Pedido` con 4 columnas y el mismo nombre; la segunda pasada no cambia nada. `INSERT` de `(e, r, b)` repetida con otro fork: se acepta. Con el mismo fork: error 2601 |
| P-6 | Compatibilidad | `INSERT` sin `ForkActual` (el SQL del árbol anterior y `CandadoRestauracionApiTests.cs:226`) | Se acepta, con el GUID cero |
| P-7 | Orden | Dos pedidos en el mismo segundo (insertados a mano) | `UltimosRespaldos` devuelve el de mayor `Id` |
| P-8 | Marca (solo si #36 está unido) | Estricto con la marca en la versión anterior | La API no arranca y pide `GPOS.Migracion sistema`; después del comando, la marca vale la versión nueva |
| P-9 | Reverso | El script 7.3 sobre una base con P-1 hecho | THROW 52010 y sin cambios. Sobre una base sin repetidos, vuelve a la forma anterior |

**Ajuste a una prueba existente:** `CandadoRestauracionApiTests.cs:226` debe insertar la fila de `GPOS_TEST_NO_EXISTE` con el fork real de la reconciliación (lo trae `sync.Reconciliacion.ForkActual` de la base de prueba). Con el centinela, la prueba sigue pasando, pero R1 mostraría solo esa fila como «último pedido», y no es lo que quiere comprobar.

**Duración [I]:** P-1 añade 2 restauraciones de una base de prueba pequeña, unos 30 a 90 s en `.\SQLEXPRESS`. Va con las demás pruebas de restauración, no en paralelo con otra suite (CLAUDE.md, Calidad).

## 11. Riesgos

| # | Riesgo | Probabilidad / impacto | Mitigación |
|---|---|---|---|
| R-S2-1 | **Bloqueo durante la migración.** `ALTER … ADD … WITH VALUES` en Express/Standard reescribe la tabla (en Enterprise es solo de metadatos [I, depende de la edición]); `DROP_EXISTING` toma Sch-M | Baja / bajo: menos de 100 filas, menos de 1 s | Se aplica al arrancar (Amplio) o con `GPOS.Migracion sistema` (Estricto), sin tráfico de desbloqueo |
| R-S2-2 | Un árbol viejo comparte `GPOS_SYSDATA` y encola sin fork | Media en desarrollo / bajo | Default con centinela y mismo nombre de índice (sección 2): sigue funcionando con su semántica anterior |
| R-S2-3 | **Mismo número y mismo fork.** Una copia por *detach/attach* o una instantánea de máquina virtual revertida conservan el fork. Si el latido (PC-10) bloquea y se desbloquea dos veces sobre el mismo fork con el contador retrocedido, el par `(N, F)` se repite y vuelve el síntoma | Baja (exige dos desbloqueos por latido separados por una reversión de instantánea) / medio | **Residual aceptado en S-2.** Cobertura posible si se quiere cerrarlo: agregar a la clave `DetectadaUtc` (`sync.Reconciliacion.DetectadaEn`, que ya existe y difiere entre aperturas), leída por el servicio en la transacción de R3. Sin migración de empresa; unas 0,1 dp más |
| R-S2-4 | Pérdida de datos | Nula: no se borra ni actualiza ninguna fila; el reverso se niega si perdería historia | — |
| R-S2-5 | Estricto sin subir la marca | Media si se olvida / alto (pérdida silenciosa del respaldo posterior) | Sección 7.5 y P-8 |
| R-S2-6 | **Antes del primer desbloqueo nuevo**, R1 muestra el último pedido real, que puede pertenecer a un fork anterior (el de una base ya reemplazada) | Media / bajo: es historia verdadera y sirve para saber que existe una copia más reciente | Recomendación (Baja, fuera de S-2): que R1 marque las filas cuyo `ForkActual` difiere del fork actual de la empresa. Requiere cambiar el contrato y las dos interfaces |

**Esfuerzo:** unas 0,3 dp, en línea con la validación: DDL y marca, 0,05; consultas y servicio, 0,1; pruebas P-1 a P-9 y el ajuste, 0,15. Sin costo de infraestructura.

## Alternativas descartadas

| Alternativa | Motivo |
|---|---|
| `RESEED` o `SEQUENCE` en la empresa para que el número no retroceda | El contador vive en la base que se restaura: cualquier estado guardado allí retrocede con ella. Además exigiría una migración EF de empresa |
| Llevar el contador de reconciliaciones a `GPOS_SYSDATA` | Acopla `sync.Reconciliacion` a la disponibilidad de `GPOS_SYSDATA` dentro de la transacción de R3, y la regla es que R3 no dependa de ella (la marca P-7 y el respaldo van después del commit) |
| Columna `ForkActual` NULL para las filas antiguas | Funciona (el índice único trata los `NULL` como iguales), pero deja una clave de idempotencia anulable y una columna que el código debe tratar como opcional. El centinela NOT NULL es más simple |
| Nombre nuevo para el índice | Un árbol viejo que arranque volvería a crear el índice de 3 columnas: o falla (por duplicados) o vuelve a imponer la clave antigua, y entonces las inserciones del código nuevo fallan con 2601 |
| Borrar el default después de rellenar | Rompe R-S2-2 y la reversión solo de código (sección 2) |

### Cierre
- Estado: Completado (diseño; la construcción y la unión las decide el propietario a través de B).
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\datos-h11-s2-reconciliacion-fork-2026-10-15.md`.
- Supuestos:
  - Que `EsquemaSistema.Version` sea 1 al unir S-2 depende del orden de unión de #36 y L1a-4 (sección 7.5).
  - El comportamiento de `ADD … WITH VALUES` según la edición es inferido.
  - No compilé ni ejecuté pruebas.
- Decisiones candidatas a ADR: ninguna. Es una corrección del diseño de H-11 sin cambio de arquitectura. Para el arquitecto queda el orden por `Id` en lugar de `SolicitadoUtc` (sección 7.4).
- Entregas a otros agentes:
  - desarrollador-backend (A) → construir 7.2 y 7.4, la marca de 7.5 y las pruebas P-1 a P-9;
  - arquitecto-software → aceptar o no el orden por `Id` y el residual R-S2-3;
  - devops → la recomendación de la sección 8;
  - UX → R-S2-6, si se aborda.
- Próximo paso recomendado: que el desarrollador de A abra el PR de S-2 sobre `master` en cuanto B una #24, #26 y #28, con P-1 como prueba de regresión.
