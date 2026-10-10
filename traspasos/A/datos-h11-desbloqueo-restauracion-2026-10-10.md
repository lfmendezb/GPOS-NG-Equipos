# [Blueprint de Datos] H-11 (RN-24): migración `H11DesbloqueoRestauracion`

- **Autor:** arquitecto-datos, equipo A · **Fecha:** 2026-10-10
- **Árbol leído:** `GPOS-NG-h11`, rama `a/h11-desbloqueo-restauracion`, `42e13b6`. No cambié el árbol.
- **Entrada:** `blueprint-h11-desbloqueo-restauracion-2026-10-10.md` (en adelante [SW]), sección 10, con el encargo B-a-A y el ensayo C-a-B del 2026-10-10.
- **Convención:**
  - **verificado** = leído en esta sesión, citado como `ruta:línea` desde la raíz del árbol;
  - **inferido** = conclusión propia, sin medir;
  - **PD-nn** = prueba de datos obligatoria (sección 11).
- **Estado del diseño:** listo para el desarrollador-backend. Las preguntas P-7 y P-2b (sección 13) son para el propietario y ninguna bloquea la construcción.

---

## 1. Contexto y modelo de tenencia aplicado

- **Tenencia:** hay una base por empresa (`CLAUDE.md`, «Datos»). Todo lo que se describe aquí vive en la base de la empresa. No hay columna discriminadora, y el aislamiento lo da la conexión que elige `IEmpresaDbFactory` ([SW] 5). Ningún objeto nuevo lee ni escribe en `GPOS_SYSDATA`, salvo lo que propone P-7.
- **Mecanismo de migración de la rama** (verificado):
  - migración de EF con su `Designer`;
  - SQL a mano en `SqlMigraciones*.cs`, envuelto en `Exec(...)` (`SqlMigracionesOla3.cs:9`) porque el guion idempotente no separa lotes dentro de una migración;
  - guion acumulado `database/empresa/gpos-empresa-<marca>_<Nombre>.sql`, regenerado con `dotnet ef migrations script --idempotent`, que **sustituye** al anterior. Lo exigen `tests/GPOS.Tests/ModeloNg/AprovisionamientoTests.cs:156-165` y `src/GPOS.Migracion/GPOS.Migracion.csproj:24`;
  - la regla de ADR-07 (`database/01` y `02`) rige `master`, no esta rama.
- **Estado actual (verificado):**

| Pieza | Evidencia |
|---|---|
| Vista de la guarda, con 2 columnas | `SqlMigracionesOla3.cs:498-500` |
| `GRANT SELECT, INSERT, UPDATE ON SCHEMA::sync` y `::fiscal`; `SELECT, INSERT ON SCHEMA::audit` | `SqlMigraciones.cs:43-45` |
| `DENY INSERT, UPDATE, DELETE` sobre `sync.EstadoNodo` y `sync.Nodo` | `SqlMigracionesMae.cs:90-91` |
| `DENY INSERT, UPDATE, DELETE ON sync.Reconciliacion` | `SqlMigracionesOla3.cs:657` |
| Disparador del bloque NCF: 51324, 51325 y 51326 | `SqlMigracionesOla3.cs:385-400` |
| 51327: no se emite desde un bloque `C` o `X` | `SqlMigracionesOla3.cs:301-303` |
| Guarda 51330 de la emisión | `SqlMigracionesOla3EmisionLigera.cs:49-55` |
| Guarda 51330 de la caja | `SqlMigracionesOla3.cs:334-342` |
| `CK_SecuenciaNcf_Rango`: `Siguiente BETWEEN Desde AND Hasta + 1` | `FisConfiguracion.cs:37` |
| `MargenMinimoSerie` entre 100 y 1.000.000 | `CfgConfiguracion.cs:92` |

- **Errores 51328 y 51329: libres (verificado).** Hice `git grep -w` en las 54 referencias locales y remotas del repositorio, y el único resultado es la nota «libres: 51328, 51329» de `docs/datos/2026-10-09-d-mvp-02-datos.md:170`. En `src` aparece «51328» solo como parte de un hash (`NumeracionService.Diagnostico.cs:35`). **Los asigno:**
  - **51328:** rechazo del negocio (no restaurada, otra causa, otros nodos o cambio del fork);
  - **51329:** confirmación incompleta o fuera de la transacción, que es un defecto del programa.

### 1.1 Precisión pedida por [SW] 10.7: base única frente a nodo

| | Nodo (entrega 2; modelo de H0, 6.3) | Base única (H-11, este diseño) |
|---|---|---|
| Bloque con diferencias | Se cierra en `X` **conservando `Hasta`**. El resto no se reasigna porque 51324 lo impide | Se cierra en `X` con **`Hasta = Corte`** y `Siguiente = Corte + 1`. La porción `Corte + 1 … HastaAnterior` se registra como **secuencia nueva**, con el mismo prefijo, rango, punto, autorización y vencimiento |
| Bloque sin diferencias | Se cierra igual (H-12) | **No se toca** (I-3 de [SW]; precisión del Maestro sobre el traslado, RN-04) |
| Lo que nunca se reasigna (H-12) | Todo el bloque `X` | Los números `Desde … Corte` del bloque `X`, que incluyen la zona incierta. 51325 impide reabrirlos y 51324 impide solaparlos. Los números mayores que `Corte` nunca se emitieron según la evidencia, y por eso se pueden usar |

Los disparadores existentes admiten el recorte (verificado contra el texto de `SqlMigracionesOla3.cs:396-398`):
- 51326 solo rechaza si `i.Hasta < d.Hasta AND i.Hasta < i.Siguiente - 1`. Con `Hasta = Corte` y `Siguiente = Corte + 1`, la segunda condición es falsa.
- 51325 solo actúa si el estado **anterior** ya era `X`.

---

## 2. Tablas y relaciones

**Ninguna tabla nueva.** Cambian una vista y tres tablas existentes.

### 2.1 `sync.ReconciliacionNcf`: tres columnas nuevas

| Columna | Tipo | Nulo | Para qué |
|---|---|---|---|
| `Evidencia` | `varchar(10)` | Sí | Fuente del último NCF probado: `PROVEEDOR`, `DIARIO` o `PAPEL`. `CENTRAL` queda para la entrega 2. Mismo dominio que `CK_NcfZonaIncierta_Evidencia` ([SW] 10.2) |
| `Referencia` | `varchar(100)` | Sí | Qué evidencia se consultó. Mismo largo que `NcfZonaIncierta.Referencia` ([SW] 10.2) |
| **`HastaAnterior`** | `bigint` | Sí | **Agregada por mí.** El `Hasta` del bloque antes del recorte. Sin ella, al recortar `Hasta = Corte` el rango original solo queda en el JSON de la bitácora, o en ninguna parte cuando la porción no se crea porque estaba vencida. La usa la regla C4 (sección 3.3) para comprobar que el bloque nuevo termina donde terminaba el original |

Las tres admiten nulo porque las filas del nodo (entrega 2) y las anteriores a esta migración no las tienen. En la base única, el servicio llena las tres en **todas** las filas, también en las que quedan «sin cambio».

**Semántica de las columnas existentes en la base única**, para que el servicio y el procedimiento hablen igual:

| Columna | Valor |
|---|---|
| `EstadoAnterior` | `A` o `R` |
| `SiguienteLocal` | `Siguiente` del bloque antes de tocarlo (número = `SiguienteLocal - 1`) |
| `UltimoConocido` | El **corte**: el último NCF probado (número). Es `NULL` solo si ni la base ni la evidencia muestran emisiones |
| `ZonaDesde` / `ZonaHasta` | `SiguienteLocal … Corte` si hubo diferencias; nulos si no |
| `BloqueNuevoId` | La secuencia nueva, si se creó |

### 2.2 `sync.EstadoEmision` (vista), ampliada ([SW] 10.1)

Se agregan columnas al final. **Las dos existentes no cambian de nombre ni de tipo**, porque `ConsultasDocumentos.EstadoEmision` y `ConciliacionService.cs:84` las leen por nombre.

| Columna | Tipo | Regla |
|---|---|---|
| `EmisionBloqueada`, `MotivoBloqueo` | Sin cambio | — |
| `Restaurada` | `bit` | 1 si el fork actual es nulo o distinto del registrado. **Falla cerrada**, con la misma condición que los disparadores 51330 |
| `ForkRegistrado` | `uniqueidentifier` | `EstadoNodo.ForkRegistrado` |
| `ForkActual` | `uniqueidentifier` | `sys.database_recovery_status.recovery_fork_guid` |
| `ReconciliacionId` | `int` | `EstadoNodo.ReconciliacionId` |
| `HayOtrosNodos` | `bit` | Existe un `sync.Nodo` distinto del local, con `Local = 0` e `Inhabilitado = 0` |

---

## 3. Restricciones e integridad

### 3.1 `CHECK` nuevos (EF, `SyncConfiguracion.cs`)

| Nombre | Tabla | Expresión |
|---|---|---|
| `CK_ReconciliacionNcf_Evidencia` | `ReconciliacionNcf` | `(Evidencia IS NULL AND Referencia IS NULL) OR (Evidencia IN ('CENTRAL', 'PROVEEDOR', 'DIARIO', 'PAPEL') AND Referencia IS NOT NULL AND LEN(Referencia) >= 5)` |
| `CK_ReconciliacionNcf_ZonaEvidencia` | `ReconciliacionNcf` | `ZonaDesde IS NULL OR Evidencia IS NOT NULL` (no hay zona incierta sin evidencia) |
| `CK_ReconciliacionNcf_Bloque` | `ReconciliacionNcf` | `(BloqueNuevoId IS NULL OR BloqueNuevoId <> SecuenciaId) AND (HastaAnterior IS NULL OR UltimoConocido IS NULL OR UltimoConocido <= HastaAnterior)` |
| `CK_ReconciliacionSerie_Margen` | `ReconciliacionSerie` | `Margen >= 100 AND SiguienteNuevo >= SiguienteLocal + Margen` (RN-12: mínimo 100. Vale también para el nodo, donde `SiguienteNuevo = máx(conocido) + margen + 1`) |
| `CK_Reconciliacion_Causa` | `Reconciliacion` | `Causa IN ('RESTAURACION', 'TRASLADO')` ([SW] 10.4, opcional: **lo incluyo**. Las causas de la entrega 2 se agregan con su migración, y cambiar un `CHECK` cuesta minutos) |

### 3.2 Índice único filtrado

`UX_ReconciliacionNcf_BloqueNuevo` sobre `(BloqueNuevoId) WHERE BloqueNuevoId IS NOT NULL` **sustituye** a `IX_ReconciliacionNcf_BloqueNuevoId`, el índice que EF creó para la llave foránea (verificado en el guion vigente, `:4566`). Un mismo bloque no puede ser «nuevo» en dos reconciliaciones (sección 4).

### 3.3 Reglas que comprueba `sync.usp_ConfirmarReconciliacionLocal` (I-7 e I-1 en la base)

[SW] D-4 deja el cálculo en el servicio. **El procedimiento no confía en el servicio:** antes de desbloquear, comprueba sobre los datos ya escritos.

| Regla | Qué comprueba | Error |
|---|---|---|
| C0 | Hay transacción abierta y es **la misma** que abrió la reconciliación: `SESSION_CONTEXT('gpos.reconciliacion.local') = '<Id>:<CURRENT_TRANSACTION_ID()>'` | 51329 |
| C1 | `EstadoNodo.ReconciliacionId = @Id`, bloqueada con `RESTAURACION`; la reconciliación está en `L` y es del nodo local | 51329 |
| — | El fork actual sigue siendo `Reconciliacion.ForkActual` | 51328 `(RESTAURACION_ESTADO_CAMBIO)` |
| C2 | `@Causa` ∈ {`RESTAURACION`, `TRASLADO`}; `@Motivo` de 15 a 200 caracteres después de recortar; `@Usuario` no vacío | 51329 |
| C3 | **Completitud del NCF:** toda secuencia `A` o `R` tiene su fila (`SecuenciaId`) o es el `BloqueNuevoId` de una fila de esta reconciliación | 51329 |
| C4 | **Coherencia de cada fila.** Si el bloque quedó en `X`: `Hasta = UltimoConocido`, `Hasta > SiguienteLocal - 1`, `Hasta ≤ HastaAnterior`, `Siguiente = Hasta + 1`, la zona es `SiguienteLocal … Hasta` y existe en `fiscal.NcfZonaIncierta` con `P` y `RESTAURACION`; el bloque nuevo, si existe, va de `Hasta + 1` a `HastaAnterior`, con `Siguiente = Desde`, el mismo prefijo, tipo, punto, dígitos, rango, vencimiento y `Estado = EstadoAnterior`; si no existe, es porque el bloque se agotó (`Hasta = HastaAnterior`) o porque estaba vencido. Si el bloque sigue `A` o `R`: no tiene bloque nuevo ni zona, y `Siguiente = SiguienteLocal`. Un bloque `C` en la lista es un error | 51329 |
| **C5** | **Ningún NCF de un bloque vigente ya está en la base:** no existe un `fiscal.Comprobante` con `Ncf` entre `fmt(Siguiente)` y `fmt(Hasta)` para ningún bloque `A` o `R`. Es I-1 contra la fuente de verdad, no contra lo que declara el servicio. Se resuelve con una búsqueda por rango en `UQ_Comprobante_Ncf` por bloque | 51329 |
| C6 | **Completitud de las series:** si `@Causa = 'RESTAURACION'` o hay alguna fila de serie, toda serie `DOC` y la `MAE` de `Clientes` tiene su fila. Es un piso: P-2 puede agregar series y la regla no rechaza las de más | 51329 |
| C7 | En cada serie: `Siguiente = SiguienteNuevo`, `Margen ≥ conf.Parametros.MargenMinimoSerie` y `SiguienteNuevo ≥ SiguienteLocal + Margen` | 51329 |
| C8 | Si `Causa = 'TRASLADO'`, ninguna fila cerró un bloque | 51329 |

El mensaje de 51329 lleva el código de la regla (C0 a C8) para el registro de errores. No lleva nombres de objetos ni datos fiscales. El servicio lo trata como 500 ([SW] 5.4).

**Lo que la base no comprueba:** el 1,5 × emisión diaria × días de RN-12. La base garantiza el **piso** (C7 y el `CHECK`), y la fórmula completa es la función pura del servicio ([SW] 6). *Alternativa descartada:* recalcularla en T-SQL. Duplica la regla en dos lenguajes, y una diferencia de redondeo rechazaría desbloqueos válidos.

---

## 4. Índices y consultas que los justifican

| Índice | Decisión | Consulta | Costo de escritura |
|---|---|---|---|
| `UX_ReconciliacionNcf_BloqueNuevo` (único, filtrado) | Nuevo; sustituye a `IX_ReconciliacionNcf_BloqueNuevoId` | C3 (`x.BloqueNuevoId = s.Id`) y la llave foránea `FK_ReconciliacionNcf_Nuevo`. Además impide que un bloque sea «nuevo» dos veces | Nulo: decenas de filas por desbloqueo, una vez al año |
| `UQ_Comprobante_Ncf` | Existente; se reutiliza | C5: búsqueda por rango del NCF (`Ncf BETWEEN …`), del mismo largo por prefijo, con orden lexicográfico igual al numérico | — |
| `IX_Bitacora_Fecha` e `IX_Documento_Version` | Existentes; se reutilizan | «Último momento conocido» (sección 6.2): `TOP (1) … ORDER BY` sobre cada índice | — |
| **Ninguno** para la emisión diaria por serie | **No se crea** | `doc.Documento` por `Fecha` y `SerieId` en una ventana de 30 días, y `cat.Cliente` por `CreadoEn` | Un índice nuevo pesaría en cada emisión (la ruta más caliente) para una consulta que corre una vez por restauración. *Inferido:* recorrer 200.000 documentos en Express toma menos de 2 s en frío. Lo mide PD-11 |

---

## 5. Auditoría y trazabilidad

- `sync.Reconciliacion*` es el registro completo: quién, cuándo, por qué, la evidencia y la referencia por bloque, el rango original (`HastaAnterior`), la zona y el bloque nuevo. `fiscal.NcfZonaIncierta` lleva la zona con su estado.
- **Decisión DD-1: las dos líneas finales de la bitácora las escribe el procedimiento de confirmación**, `NODO_RECONCILIACION_CONFIRMADA` (con `Motivo` y JSON de conteos y forks) y `NODO_EMISION_DESBLOQUEADA`, en la misma sentencia que desbloquea. Así la base garantiza que «la confirmación y el desbloqueo quedan juntos en la bitácora» (ADR-53, cláusula 9.6; modelo de H0, 6.5: «exigir la confirmación con usuario, fecha y motivo» es tarea de la base).
  - El servicio escribe las demás líneas de [SW] 4.4 (detectada, bloques cerrados, bloques asignados y series) con `RegistroBitacora`, y el espejo `_LOG` de las dos finales con `PuenteCfg`. Así no se duplican en `audit.Bitacora`.
  - *Alternativa descartada:* el paso 7 de [SW] 6.1, con las dos líneas escritas por el servicio. Funciona, pero un defecto podría desbloquear sin dejar la línea.
- **Inmutabilidad:** `DENY UPDATE, DELETE` a `gpos_app` sobre `ReconciliacionNcf`, `ReconciliacionSerie` y `ReconciliacionChequera` (sección 9). Después de confirmar, nada de la aplicación cambia ese registro.

---

## 6. Persistencia de la sincronización: el guion de la transacción

No aplica la sincronización con la central (no la hay). Lo que sigue es la **transacción única** de [SW] 6.1, con el orden firmado de bloqueos (ADR-45, `CLAUDE.md`: … → **configuración → series → NCF** → …).

### 6.1 Pasos, recursos y bloqueos

**Cambio respecto de [SW]:** la huella se recalcula **después** de bloquear las series y el NCF. En [SW] se recalculaba en el paso 3, antes de bloquearlos, y quedaba una ventana entre la comprobación y el bloqueo.

| # | Nivel | Sentencia (Dapper, `READ COMMITTED` con RCSI, `XACT_ABORT ON`) | Bloqueo |
|---|---|---|---|
| 1 | Configuración | `EXEC sync.usp_AbrirReconciliacionLocal @ReconciliacionId OUTPUT, @ForkAnterior OUTPUT, @ForkActual OUTPUT` | `U` y luego `X` en `sync.EstadoNodo` (fila 1); `S` por rango en `sync.Nodo` |
| 2 | Configuración | `SELECT VersionConfig FROM num.Configuracion WITH (UPDLOCK, HOLDLOCK) WHERE Id = 1;` | `U` en `num.Configuracion`. Serializa con los cambios de prefijo y subserie, que toman esta fila (`SqlMigracionesOla3.cs:407`) |
| 3 | Series | `SELECT Id, Clase, TipoCodigo, SucursalId, Prefijo, Digitos, Siguiente, Version FROM num.Serie WITH (UPDLOCK, HOLDLOCK) WHERE Clase = 'DOC' OR (Clase = 'MAE' AND TipoCodigo = @tipoClientes);` con `@tipoClientes varchar(30) = 'Clientes'` | `U` por rango sobre todo el índice agrupado `UQ_NumSerie_Serie`: nadie crea una serie hasta el final (C6) |
| 4 | NCF | `SELECT Id, TipoComprobanteCodigo, PuntoEmisionId, RangoAutorizadoId, Prefijo, Digitos, Desde, Hasta, Siguiente, FechaVencimiento, Estado, Version FROM fiscal.SecuenciaNcf WITH (UPDLOCK, HOLDLOCK) WHERE Estado IN ('A', 'R');` | `U` por rango sobre `PK_SecuenciaNcf`: nadie registra un bloque hasta el final (C3) |
| 5 | Lectura | Se recalcula la **huella** (fork actual + `Id`, `Siguiente` y `Version` de series y secuencias). Si difiere de la de R1: `THROW` del servicio, 409 `RESTAURACION_ESTADO_CAMBIO`, y se deshace todo | — |
| 6 | Series | Por serie: `UPDATE num.Serie SET Siguiente = @nuevo, ModificadoEn = SYSUTCDATETIME(), ModificadoPor = @usuario WHERE Id = @id AND Version = @version;` (exige 1 fila); `INSERT sync.ReconciliacionSerie (ReconciliacionId, SerieId, SiguienteLocal, UltimoCentral, Margen, SiguienteNuevo) VALUES (@rec, @id, @local, NULL, @margen, @nuevo);` | Conversión de `U` a `X` sobre filas ya tomadas |
| 7 | NCF | Por bloque con diferencias, **en este orden**: (a) `UPDATE fiscal.SecuenciaNcf SET Estado = 'X', CerradoEn = SYSUTCDATETIME(), Hasta = @corte, Siguiente = @corte + 1, ModificadoPor = @usuario WHERE Id = @id AND Version = @version;` (b) si corresponde, `INSERT fiscal.SecuenciaNcf (…) OUTPUT inserted.Id SELECT TipoComprobanteCodigo, PuntoEmisionId, RangoAutorizadoId, Prefijo, Digitos, @corte + 1, @hastaAnterior, @corte + 1, FechaAutorizacion, FechaVencimiento, NumeroAutorizacion, AvisarAlQuedar, NotificarAlAgotarse, @estadoAnterior, NULL, NULL, @usuario FROM fiscal.SecuenciaNcf WHERE Id = @id;` (c) `INSERT fiscal.NcfZonaIncierta (SecuenciaId, Desde, Hasta, Causa, Estado, Evidencia, Referencia, ReconciliacionId) VALUES (@id, @siguienteLocal, @corte, 'RESTAURACION', 'P', @evidencia, @referencia, @rec);` (d) `INSERT sync.ReconciliacionNcf (…, Evidencia, Referencia, HastaAnterior)`. En cada bloque sin cambio, solo (d) | Conversión de `U` a `X`. 51324 toma `UPDLOCK, HOLDLOCK` sobre el mismo prefijo, en el mismo nivel |
| 8 | — | Líneas de bitácora del servicio ([SW] 4.4, salvo las dos finales) | Inserciones |
| 9 | Configuración (fila ya tomada) | `EXEC sync.usp_ConfirmarReconciliacionLocal @rec, @causa, @motivo, @usuario, @usuarioId` | Conversión de `U` a `X` en `EstadoNodo`, que ya está tomada |
| 10 | — | `COMMIT` | — |

**Tipos de los parámetros (ADR-50):**

| Tipo | Parámetros |
|---|---|
| `varchar(60)` | `@usuario` |
| `varchar(30)` | `@causa`, `@tipoClientes` |
| `varchar(200)` | `@motivo` |
| `varchar(10)` | `@evidencia` |
| `varchar(100)` | `@referencia` |
| `char(1)` | `@estadoAnterior` |
| `bigint` | Números |
| `int` | Ids de serie, secuencia y reconciliación |
| `binary(8)` | `@version` (rowversion) |

**Por qué no hay interbloqueo (inferido, lo prueba PD-09):**
- La emisión lee `sync.EstadoEmision WITH (HOLDLOCK)` en el nivel «configuración», antes de tomar la serie (`ConsultasDocumentos.cs:13-21`).
- Si una emisión ya tiene `S` en `EstadoNodo`, el paso 1 espera en su `UPDATE`. La emisión sigue, falla por 51330 o por la guarda nueva, y suelta el bloqueo. El desbloqueo todavía no tomó nada que ella necesite.
- Las emisiones que llegan después esperan el `X` de `EstadoNodo` y, tras el `COMMIT`, leen el sitio desbloqueado.
- Ninguna ruta toma `EstadoNodo` después de la serie.
- **El orden dentro del nivel de series es el del índice agrupado (`TipoCodigo`, `SucursalId`), no el de `Id`.** Con `HOLDLOCK` en un recorrido, los bloqueos se toman en el orden del recorrido. La emisión toma una sola serie, así que no forma ciclo. Una pantalla de administración que bloquee varias series en otro orden podría interbloquearse: en ese caso el motor elige una víctima, la transacción se deshace entera y se reintenta. Riesgo Bajo (R-D6).

### 6.2 Consultas de lectura para RN-12 (referencia para `ConsultasRestauracion`)

```sql
-- Último momento conocido (UTC). Dos búsquedas por índice. SQL Server 2019 Express no tiene GREATEST, así que se usa VALUES.
SELECT MAX(v) FROM (VALUES
   ((SELECT TOP (1) FechaHora FROM audit.Bitacora ORDER BY FechaHora DESC)),
   ((SELECT TOP (1) (SELECT MAX(x) FROM (VALUES (d.CreadoEn), (d.EmitidoEn), (d.AnuladoEn)) t (x))
       FROM doc.Documento d ORDER BY d.Version DESC))) u (v);

-- Emisión diaria máxima por serie DOC en los 30 días que terminan en el último momento conocido (@hasta date)
SELECT x.SerieId, MAX(x.N) AS EmisionDiariaMaxima
  FROM (SELECT SerieId, Fecha, COUNT_BIG(*) AS N
          FROM doc.Documento
         WHERE Fecha BETWEEN DATEADD(day, -29, @hasta) AND @hasta AND Estado IN (1, 2) AND Origen = 'N' AND SerieId IS NOT NULL
         GROUP BY SerieId, Fecha) x
 GROUP BY x.SerieId;

-- Clientes por día (serie MAE «Clientes»). Cuenta también los creados con código manual: sobrestima, que es lo seguro.
SELECT MAX(N) FROM (SELECT CONVERT(date, CreadoEn) AS Dia, COUNT_BIG(*) AS N FROM cat.Cliente
                     WHERE CreadoEn >= DATEADD(day, -29, CONVERT(datetime2(3), @hasta)) AND CreadoEn < DATEADD(day, 1, CONVERT(datetime2(3), @hasta))
                     GROUP BY CONVERT(date, CreadoEn)) c;

-- Último emitido en la base por secuencia vigente: se toma el mayor entre Siguiente - 1 y el comprobante, que es lo conservador
SELECT s.Id, MAX(CONVERT(bigint, RIGHT(c.Ncf, s.Digitos))) AS UltimoComprobante
  FROM fiscal.SecuenciaNcf s JOIN fiscal.Comprobante c ON c.SecuenciaId = s.Id
 WHERE s.Estado IN ('A', 'R') GROUP BY s.Id;
```

**Fórmula (RN-12, en el servicio y con aritmética `long`):**
- `Margen = MAX(MargenMinimoSerie, ⌈1,5 × EmisionDiariaMaxima × DiasInciertos⌉)`;
- `DiasInciertos = MAX(1, ⌈(ahora − último momento) / 86.400 s⌉)`;
- `SiguienteNuevo = Siguiente + Margen`.

Si `Margen > int.MaxValue` (la columna es `int`), o si `SiguienteNuevo > 10^Digitos` (`CK_NumSerie_Siguiente`, `NumConfiguracion.cs:37`), el resultado es 422 `SERIE_SIN_CAPACIDAD` **antes** de escribir.

---

## 7. Script de migración y reversión

### 7.1 Archivos

| Archivo | Contenido |
|---|---|
| `src/GPOS.Core/Datos/Empresa/Migraciones/<marca>_H11DesbloqueoRestauracion.cs` y su `Designer` | Migración; marca posterior a `20261010035415` |
| `src/GPOS.Core/Datos/Empresa/Migraciones/SqlMigracionesH11.cs` | `H11Previa()`, `H11VistaProcedimientosPermisos()`, `H11DownPrevia()`, `H11DownSql()` |
| `src/GPOS.Core/Dominio/.../Bandeja.cs` (clase `ReconciliacionNcf`) | Propiedades `Evidencia`, `Referencia` y `HastaAnterior` |
| `src/GPOS.Core/Datos/Empresa/Configuracion/SyncConfiguracion.cs` | `CHECK`, largos e índice de las secciones 3.1 y 3.2 |
| `EmpresaNgDbContextModelSnapshot.cs` | Regenerado |
| `database/empresa/gpos-empresa-<marca>_H11DesbloqueoRestauracion.sql` | Regenerado con `dotnet ef migrations script --idempotent -p src/GPOS.Core -s src/GPOS.Core -c EmpresaNgDbContext -o …`. **Se borra** `gpos-empresa-20261010035415_Ola4BusquedaSinTildes.sql` |

### 7.2 Orden del `Up`

1. `migrationBuilder.Sql(SqlMigraciones.H11Previa())`, antes de tocar nada:

   ```sql
   IF EXISTS (SELECT 1 FROM sync.Reconciliacion WHERE Causa NOT IN ('RESTAURACION', 'TRASLADO'))
      OR EXISTS (SELECT 1 FROM sync.ReconciliacionSerie WHERE Margen < 100 OR SiguienteNuevo < SiguienteLocal + Margen)
       THROW 51399, N'Hay reconciliaciones que no cumplen las restricciones de H11DesbloqueoRestauracion: revíselas antes de aplicar la migración.', 1;
   ```

   *Inferido:* en las bases reales no hay filas, porque no existía ninguna vía que las creara. La comprobación protege las bases de prueba restauradas.

2. Lo de EF:
   - `DropIndex IX_ReconciliacionNcf_BloqueNuevoId`;
   - `AddColumn` de `Evidencia varchar(10) NULL`, `Referencia varchar(100) NULL` y `HastaAnterior bigint NULL`;
   - los cinco `AddCheckConstraint` de la sección 3.1;
   - `CreateIndex UX_ReconciliacionNcf_BloqueNuevo` (único, filtro `[BloqueNuevoId] IS NOT NULL`).
3. `migrationBuilder.Sql(SqlMigraciones.H11VistaProcedimientosPermisos())`: la vista (8.1), los dos procedimientos (8.2 y 8.3) y los permisos (sección 9), cada `CREATE OR ALTER` dentro de `Exec(...)`.
   - Los procedimientos citan las columnas nuevas, y el `EXEC` compila después del `ALTER TABLE` del paso 2.
   - **No debe ir antes del paso 2.** `CREATE PROCEDURE` no difiere la resolución de columnas que faltan en tablas que ya existen.

**Duración y bloqueos (inferido):**
- `ADD` de columnas que admiten nulo: solo metadatos.
- `CHECK` y el índice sobre tablas de 0 a decenas de filas.
- `CREATE OR ALTER VIEW` toma `Sch-M` sobre la vista, y la emisión espera milisegundos.
- **Total:** menos de 1 s.
- Como toda migración, se aplica con la API detenida.

### 7.3 `Down` completo

1. `H11DownPrevia()`, dentro de `Exec` porque cita las columnas nuevas. Es la convención 51399 de la rama para un `Down` que perdería datos:

   ```sql
   IF EXISTS (SELECT 1 FROM sync.ReconciliacionNcf WHERE Evidencia IS NOT NULL OR Referencia IS NOT NULL OR HastaAnterior IS NOT NULL)
      OR EXISTS (SELECT 1 FROM sync.Reconciliacion WHERE Causa = 'TRASLADO')
       THROW 51399, N'La reversión perdería la evidencia de un desbloqueo por restauración: no se puede volver a Ola4BusquedaSinTildes.', 1;
   ```

   Es coherente con R-2 de [SW]: después de un desbloqueo no se revierte a una versión anterior.

2. `H11DownSql()`:

   ```sql
   DROP PROCEDURE IF EXISTS sync.usp_ConfirmarReconciliacionLocal;
   DROP PROCEDURE IF EXISTS sync.usp_AbrirReconciliacionLocal;
   EXEC(N'CREATE OR ALTER VIEW sync.EstadoEmision AS
   SELECT e.EmisionBloqueada, e.MotivoBloqueo FROM sync.EstadoNodo e WHERE e.Id = 1');   -- texto exacto de SqlMigracionesOla3.cs:498-500
   REVOKE UPDATE, DELETE ON sync.ReconciliacionNcf FROM gpos_app;      -- quita el DENY; vuelve a regir el GRANT del esquema
   REVOKE UPDATE, DELETE ON sync.ReconciliacionSerie FROM gpos_app;
   REVOKE UPDATE, DELETE ON sync.ReconciliacionChequera FROM gpos_app;
   ```

   Al borrar los procedimientos se borra también su `GRANT EXECUTE`. El `GRANT SELECT` de la vista (`SqlMigracionesOla3.cs:646`) se conserva porque la vista no se borra.

3. EF, en orden inverso:
   - `DropIndex UX_ReconciliacionNcf_BloqueNuevo`;
   - los cinco `DropCheckConstraint`;
   - `DropColumn` de las tres columnas;
   - `CreateIndex IX_ReconciliacionNcf_BloqueNuevoId`.

**Prueba:** `Up`, `Down` y `Up` en una base temporal, como en Ola4 (PD-01).

---

## 8. Objetos en T-SQL

### 8.1 Vista

```sql
CREATE OR ALTER VIEW sync.EstadoEmision AS
SELECT e.EmisionBloqueada,
       e.MotivoBloqueo,
       CONVERT(bit, CASE WHEN r.recovery_fork_guid IS NULL OR r.recovery_fork_guid <> e.ForkRegistrado THEN 1 ELSE 0 END) AS Restaurada,
       e.ForkRegistrado,
       r.recovery_fork_guid AS ForkActual,
       e.ReconciliacionId,
       CONVERT(bit, CASE WHEN EXISTS (SELECT 1 FROM sync.Nodo n
                                       WHERE n.Id <> e.NodoLocalId AND n.Local = 0 AND n.Inhabilitado = 0)
                         THEN 1 ELSE 0 END) AS HayOtrosNodos
  FROM sync.EstadoNodo e
  LEFT JOIN sys.database_recovery_status r ON r.database_id = DB_ID()
 WHERE e.Id = 1
```

- **Permiso para leer el fork:** un usuario del rol `gpos_app` lo lee sin `VIEW DATABASE STATE`. Está medido en H0 (T95, `docs/datos/scripts/2026-10-04-h0-pruebas-entrega1.sql:498-499`), y es la misma condición que ya evalúan los disparadores.
- **Costo en la emisión:** unos 19 µs por lectura (medido en H0, 6.1). `HayOtrosNodos` no se evalúa si la consulta no lo pide: el optimizador poda las columnas que no se usan (*inferido*, PD-03).
- **Riesgo que hay que medir (PD-02):** la guarda lee la vista `WITH (HOLDLOCK)`, y la indicación se propaga a `sys.database_recovery_status`.
  - *Inferido:* el motor acepta la indicación sobre las vistas del catálogo, porque las indicaciones de bloqueo sobre `sys.*` son habituales.
  - **Plan de reserva, si PD-02 falla:** una función escalar `sync.ufn_ForkActual() WITH INLINE = OFF`, del mismo dueño, que la vista llama en lugar del `JOIN`. Las indicaciones no se propagan dentro de una función. El costo es de 1 fila por lectura.

### 8.2 `sync.usp_AbrirReconciliacionLocal`

```sql
CREATE OR ALTER PROCEDURE sync.usp_AbrirReconciliacionLocal
    @ReconciliacionId int OUTPUT,
    @ForkAnterior uniqueidentifier OUTPUT,
    @ForkActual uniqueidentifier OUTPUT
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF @@TRANCOUNT = 0
        THROW 51329, N'El desbloqueo se abre dentro de la transacción del servicio (C0).', 1;

    DECLARE @nodo smallint, @bloq bit, @motivo varchar(30), @recPrev int, @desde datetime2(3);
    SELECT @nodo = NodoLocalId, @ForkAnterior = ForkRegistrado, @bloq = EmisionBloqueada, @motivo = MotivoBloqueo,
           @recPrev = ReconciliacionId, @desde = BloqueadaDesde
      FROM sync.EstadoNodo WITH (UPDLOCK, HOLDLOCK)
     WHERE Id = 1;
    IF @nodo IS NULL
        THROW 51328, N'La base no tiene identidad de sitio (SITIO_SIN_IDENTIDAD).', 1;
    IF @bloq = 1 AND @motivo <> 'RESTAURACION'
        THROW 51328, N'La emisión está bloqueada por otra causa (BLOQUEADA_OTRA_CAUSA).', 1;
    SET @ForkActual = (SELECT recovery_fork_guid FROM sys.database_recovery_status WHERE database_id = DB_ID());
    IF @ForkActual IS NULL
        THROW 51328, N'La base no informa su fork de recuperación: no se puede desbloquear (SITIO_NO_RESTAURADO).', 1;
    IF @ForkActual = @ForkAnterior AND @bloq = 0
        THROW 51328, N'La base no se restauró (SITIO_NO_RESTAURADO).', 1;
    IF EXISTS (SELECT 1 FROM sync.Nodo WITH (HOLDLOCK) WHERE Id <> @nodo AND Local = 0 AND Inhabilitado = 0)
        THROW 51328, N'Hay otros nodos activos: se reconcilia con la central (REQUIERE_RECONCILIACION_CENTRAL).', 1;

    -- Una reconciliación local que quedó en L (un servicio defectuoso confirmó sin cerrar) se cancela: sigue bloqueada y se abre otra
    UPDATE sync.Reconciliacion SET Estado = 'X'
     WHERE Id = @recPrev AND Estado = 'L' AND Causa IN ('RESTAURACION', 'TRASLADO');

    INSERT sync.Reconciliacion (NodoId, DetectadaEn, Causa, ForkAnterior, ForkActual, Estado)
    VALUES (@nodo, SYSUTCDATETIME(), 'RESTAURACION', @ForkAnterior, @ForkActual, 'L');
    SET @ReconciliacionId = CONVERT(int, SCOPE_IDENTITY());

    UPDATE sync.EstadoNodo
       SET EmisionBloqueada = 1, MotivoBloqueo = 'RESTAURACION',
           BloqueadaDesde = CASE WHEN @bloq = 1 THEN @desde ELSE SYSUTCDATETIME() END,
           ReconciliacionId = @ReconciliacionId
     WHERE Id = 1;

    DECLARE @marca nvarchar(60) = CONCAT(@ReconciliacionId, N':', CURRENT_TRANSACTION_ID());
    EXEC sys.sp_set_session_context @key = N'gpos.reconciliacion.local', @value = @marca;
END
```

**Precedencia de los estados**, que precisa [SW] 4.1, donde las condiciones se solapaban:
- un bloqueo `MANUAL`, `HUECO_SECUENCIA` o `APROVISIONAMIENTO` **gana sobre la restauración**: este camino nunca levanta un bloqueo de otra causa. Hoy ningún código pone esas causas (verificado: solo aparecen en el `CHECK`, `SitioConfiguracion.cs:37`), así que el impacto es nulo;
- el servicio mapea los sufijos entre paréntesis según la convención de la ola 4b:
  - `SITIO_SIN_IDENTIDAD` y `BLOQUEADA_OTRA_CAUSA` → 409 con el estado de R1;
  - los demás → los códigos de [SW] 5.4.

### 8.3 `sync.usp_ConfirmarReconciliacionLocal`

```sql
CREATE OR ALTER PROCEDURE sync.usp_ConfirmarReconciliacionLocal
    @ReconciliacionId int,
    @Causa varchar(30),
    @Motivo varchar(200),
    @Usuario varchar(60),
    @UsuarioId int = NULL
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @regla varchar(4) = NULL, @msg nvarchar(200), @nodo smallint, @forkRec uniqueidentifier, @forkAct uniqueidentifier,
            @ahora datetime2(3) = SYSUTCDATETIME(), @hoy date = CONVERT(date, SYSDATETIME()), @margenMin int, @detalle varchar(4000),
            @motivoLimpio varchar(200) = LTRIM(RTRIM(@Motivo));

    -- C0: la misma transacción que abrió
    IF @@TRANCOUNT = 0
       OR ISNULL(CONVERT(nvarchar(60), SESSION_CONTEXT(N'gpos.reconciliacion.local')), N'') <> CONCAT(@ReconciliacionId, N':', CURRENT_TRANSACTION_ID())
        THROW 51329, N'Desbloqueo inconsistente: regla C0 (I-7).', 1;

    -- C1
    SELECT @nodo = NodoLocalId FROM sync.EstadoNodo WITH (UPDLOCK, HOLDLOCK)
     WHERE Id = 1 AND ReconciliacionId = @ReconciliacionId AND EmisionBloqueada = 1 AND MotivoBloqueo = 'RESTAURACION';
    SELECT @forkRec = ForkActual FROM sync.Reconciliacion WITH (UPDLOCK)
     WHERE Id = @ReconciliacionId AND Estado = 'L' AND NodoId = @nodo;
    IF @nodo IS NULL OR @forkRec IS NULL
        THROW 51329, N'Desbloqueo inconsistente: regla C1 (I-7).', 1;
    SET @forkAct = (SELECT recovery_fork_guid FROM sys.database_recovery_status WHERE database_id = DB_ID());
    IF @forkAct IS NULL OR @forkAct <> @forkRec
        THROW 51328, N'La base cambió durante el desbloqueo (RESTAURACION_ESTADO_CAMBIO).', 1;

    -- C2
    IF @Causa IS NULL OR @Causa NOT IN ('RESTAURACION', 'TRASLADO') OR ISNULL(LEN(@motivoLimpio), 0) < 15 OR ISNULL(LEN(@Usuario), 0) = 0
        SET @regla = 'C2';

    -- C3: completitud del NCF
    IF @regla IS NULL AND EXISTS (
        SELECT 1 FROM fiscal.SecuenciaNcf s WITH (READCOMMITTEDLOCK)
         WHERE s.Estado IN ('A', 'R')
           AND NOT EXISTS (SELECT 1 FROM sync.ReconciliacionNcf x
                            WHERE x.ReconciliacionId = @ReconciliacionId AND (x.SecuenciaId = s.Id OR x.BloqueNuevoId = s.Id)))
        SET @regla = 'C3';

    -- C4: coherencia de cada fila
    IF @regla IS NULL AND EXISTS (
        SELECT 1
          FROM sync.ReconciliacionNcf x
          JOIN fiscal.SecuenciaNcf s WITH (READCOMMITTEDLOCK) ON s.Id = x.SecuenciaId
          LEFT JOIN fiscal.SecuenciaNcf n WITH (READCOMMITTEDLOCK) ON n.Id = x.BloqueNuevoId
         WHERE x.ReconciliacionId = @ReconciliacionId
           AND NOT (
                x.EstadoAnterior IN ('A', 'R') AND x.Evidencia IS NOT NULL AND x.HastaAnterior IS NOT NULL
            AND (   -- sin cambio
                    (s.Estado IN ('A', 'R') AND x.BloqueNuevoId IS NULL AND x.ZonaDesde IS NULL
                     AND s.Siguiente = x.SiguienteLocal AND s.Hasta = x.HastaAnterior)
                    -- cerrado en el corte, con zona
                 OR (s.Estado = 'X' AND s.Hasta = x.UltimoConocido AND s.Hasta > x.SiguienteLocal - 1 AND s.Hasta <= x.HastaAnterior
                     AND s.Siguiente = s.Hasta + 1
                     AND x.ZonaDesde = x.SiguienteLocal AND x.ZonaHasta = s.Hasta
                     AND EXISTS (SELECT 1 FROM fiscal.NcfZonaIncierta z
                                  WHERE z.SecuenciaId = s.Id AND z.Desde = x.ZonaDesde AND z.Hasta = x.ZonaHasta AND z.Causa = 'RESTAURACION'
                                    AND z.Estado = 'P' AND z.ReconciliacionId = @ReconciliacionId AND z.Evidencia = x.Evidencia)
                     AND (   (n.Id IS NOT NULL AND n.Desde = s.Hasta + 1 AND n.Hasta = x.HastaAnterior AND n.Siguiente = n.Desde
                              AND n.Estado = x.EstadoAnterior AND n.Prefijo = s.Prefijo AND n.TipoComprobanteCodigo = s.TipoComprobanteCodigo
                              AND n.PuntoEmisionId = s.PuntoEmisionId AND n.Digitos = s.Digitos
                              AND ISNULL(n.RangoAutorizadoId, -1) = ISNULL(s.RangoAutorizadoId, -1)
                              AND ISNULL(n.FechaVencimiento, '19000101') = ISNULL(s.FechaVencimiento, '19000101'))
                          OR (x.BloqueNuevoId IS NULL AND (s.Hasta = x.HastaAnterior OR s.FechaVencimiento < @hoy))))
                )))
        SET @regla = 'C4';

    -- C5: ningún NCF de un bloque vigente ya está en la base (I-1 contra fiscal.Comprobante)
    IF @regla IS NULL AND EXISTS (
        SELECT 1 FROM fiscal.SecuenciaNcf s WITH (READCOMMITTEDLOCK)
         WHERE s.Estado IN ('A', 'R') AND s.Siguiente <= s.Hasta
           AND EXISTS (SELECT 1 FROM fiscal.Comprobante c
                        WHERE c.Ncf BETWEEN s.Prefijo + RIGHT(REPLICATE('0', s.Digitos) + CONVERT(varchar(20), s.Siguiente), s.Digitos)
                                        AND s.Prefijo + RIGHT(REPLICATE('0', s.Digitos) + CONVERT(varchar(20), s.Hasta), s.Digitos)))
        SET @regla = 'C5';

    -- C6 y C7: series (RN-12)
    SET @margenMin = ISNULL((SELECT MargenMinimoSerie FROM conf.Parametros WHERE Id = 1), 100);
    IF @regla IS NULL AND (@Causa = 'RESTAURACION' OR EXISTS (SELECT 1 FROM sync.ReconciliacionSerie WHERE ReconciliacionId = @ReconciliacionId))
       AND EXISTS (SELECT 1 FROM num.Serie s WITH (READCOMMITTEDLOCK)
                    WHERE (s.Clase = 'DOC' OR (s.Clase = 'MAE' AND s.TipoCodigo = 'Clientes'))
                      AND NOT EXISTS (SELECT 1 FROM sync.ReconciliacionSerie x WHERE x.ReconciliacionId = @ReconciliacionId AND x.SerieId = s.Id))
        SET @regla = 'C6';
    IF @regla IS NULL AND EXISTS (
        SELECT 1 FROM sync.ReconciliacionSerie x JOIN num.Serie s WITH (READCOMMITTEDLOCK) ON s.Id = x.SerieId
         WHERE x.ReconciliacionId = @ReconciliacionId
           AND (s.Siguiente <> x.SiguienteNuevo OR x.Margen < @margenMin OR x.SiguienteNuevo < x.SiguienteLocal + x.Margen))
        SET @regla = 'C7';

    -- C8: TRASLADO exige que no se haya cerrado ningún bloque (una RESTAURACION sin diferencias es válida: aviso 3 de [SW] 5.3)
    IF @regla IS NULL AND @Causa = 'TRASLADO'
       AND EXISTS (SELECT 1 FROM sync.ReconciliacionNcf WHERE ReconciliacionId = @ReconciliacionId AND ZonaDesde IS NOT NULL)
        SET @regla = 'C8';

    IF @regla IS NOT NULL
    BEGIN
        SET @msg = CONCAT(N'Desbloqueo incompleto o inconsistente: regla ', @regla, N' (I-7).');
        THROW 51329, @msg, 1;
    END

    UPDATE sync.Reconciliacion
       SET Estado = 'C', Causa = @Causa, Motivo = @motivoLimpio, ConfirmadaPor = @Usuario, ConfirmadaPorId = @UsuarioId, ConfirmadaEn = @ahora
     WHERE Id = @ReconciliacionId;
    UPDATE sync.EstadoNodo
       SET ForkRegistrado = @forkAct, EmisionBloqueada = 0, MotivoBloqueo = NULL, BloqueadaDesde = NULL, ReconciliacionId = @ReconciliacionId
     WHERE Id = 1;

    SET @detalle = (SELECT @ReconciliacionId AS reconciliacionId, @Causa AS causa,
                           (SELECT ForkAnterior FROM sync.Reconciliacion WHERE Id = @ReconciliacionId) AS forkAnterior, @forkAct AS forkActual,
                           (SELECT COUNT(*) FROM sync.ReconciliacionNcf WHERE ReconciliacionId = @ReconciliacionId) AS secuencias,
                           (SELECT COUNT(*) FROM sync.ReconciliacionNcf WHERE ReconciliacionId = @ReconciliacionId AND ZonaDesde IS NOT NULL) AS bloquesCerrados,
                           (SELECT COUNT(*) FROM sync.ReconciliacionNcf WHERE ReconciliacionId = @ReconciliacionId AND BloqueNuevoId IS NOT NULL) AS bloquesNuevos,
                           (SELECT COUNT(*) FROM sync.ReconciliacionSerie WHERE ReconciliacionId = @ReconciliacionId) AS series
                       FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
    INSERT audit.Bitacora (UsuarioId, Usuario, Accion, Entidad, EntidadId, Motivo, Detalle)
    VALUES (@UsuarioId, @Usuario, 'NODO_RECONCILIACION_CONFIRMADA', 'Reconciliacion', @ReconciliacionId, @motivoLimpio, @detalle),
           (@UsuarioId, @Usuario, 'NODO_EMISION_DESBLOQUEADA', 'Reconciliacion', @ReconciliacionId, @motivoLimpio,
            CONCAT('{"reconciliacionId":', @ReconciliacionId, '}'));

    EXEC sys.sp_set_session_context @key = N'gpos.reconciliacion.local', @value = NULL;
END
```

**Nota sobre C8.** La base solo exige `TRASLADO ⇒ ningún cierre`. El caso «restauración sin diferencias» es válido (aviso 3 de [SW] 5.3) y no se rechaza.

**Comprobaciones de la sintaxis (para el desarrollador):**
- No usar `IS DISTINCT FROM` ni `GREATEST`, que son de SQL Server 2022. Hay que confirmar la versión mínima del motor; *inferido* 2019 Express, por lo medido en H0.
- `CURRENT_TRANSACTION_ID()` existe desde 2016.
- `FOR JSON` asignado a una variable devuelve `nvarchar` con contenido ASCII, y cabe en `varchar(4000)`.

---

## 9. Privilegios de base de datos

### 9.1 Revisión del supuesto de [SW] 10.5: `gpos_app` puede insertar en `ReconciliacionNcf` y `ReconciliacionSerie`

**Confirmado por el texto (verificado):**
- `GRANT SELECT, INSERT, UPDATE ON SCHEMA::sync TO gpos_app` (`SqlMigraciones.cs:45`);
- no hay `DENY` sobre esas dos tablas. Los únicos `DENY` del esquema `sync` son a `EstadoNodo` y `Nodo` (`SqlMigracionesMae.cs:90-91`) y a `Reconciliacion` (`SqlMigracionesOla3.cs:657`);
- las llaves foráneas hacia `sync.Reconciliacion` y `fiscal.SecuenciaNcf` **no** exigen permisos sobre la tabla referenciada al insertar (*inferido*: `REFERENCES` se exige al crear la restricción, no al usarla).

Lo mismo vale para lo demás que escribe el servicio:

| Tabla | Operación | Permiso | Evidencia |
|---|---|---|---|
| `fiscal.SecuenciaNcf` | `INSERT` y `UPDATE` | Concedido. `DELETE` está denegado y no se usa | `SqlMigraciones.cs:43`; `SqlMigracionesOla3.cs:656` |
| `fiscal.NcfZonaIncierta` | `INSERT` | Concedido | `SqlMigraciones.cs:43` |
| `num.Serie` | `UPDATE` | Concedido | `SqlMigraciones.cs:34` |
| `audit.Bitacora` | `INSERT` | Concedido | `SqlMigraciones.cs:44` |

**Falta probarlo con el usuario real (PD-04):** las pruebas corren con un login con privilegios. La prueba ejecuta el desbloqueo completo con `EXECUTE AS USER = 'qa_app_h11'`, miembro de `gpos_app`, como `CierrePeriodoInventarioTests.cs:192`.

### 9.2 Cambios de permisos de la migración (mínimos)

```sql
GRANT EXECUTE ON sync.usp_AbrirReconciliacionLocal TO gpos_app;
GRANT EXECUTE ON sync.usp_ConfirmarReconciliacionLocal TO gpos_app;
DENY UPDATE, DELETE ON sync.ReconciliacionNcf TO gpos_app;        -- solo se insertan; después de confirmar son registro
DENY UPDATE, DELETE ON sync.ReconciliacionSerie TO gpos_app;
DENY UPDATE, DELETE ON sync.ReconciliacionChequera TO gpos_app;   -- P-3 solo inserta
```

- Hoy ningún código hace `UPDATE` ni `DELETE` sobre estas tablas (verificado: fuera de las migraciones, las configuraciones y el dominio no hay usos).
- **Se mantienen** los `DENY` de `EstadoNodo`, `Nodo` y `Reconciliacion`: la aplicación solo los cambia por los dos procedimientos, que validan I-7 e I-8 por su cuenta.
- `gpos_reportes`, `gpos_sync`, `gpos_mantenimiento` y `gpos_respaldo`: sin cambios.
- `EXECUTE AS OWNER` es el mismo patrón que `sync.usp_AdelantarSecuencias` (`SqlMigracionesOla3.cs:605-645`).
  - Que el dueño lea el fork en ese contexto es *inferido* por T95, que hizo la misma lectura con suplantación de usuario de base. Lo mide PD-05.
  - **Plan de reserva:** firmar los dos procedimientos con un certificado en lugar de `EXECUTE AS OWNER`. Se conserva el contexto de quien llama, que ya lee el fork. Costo: +0,05 sp.
- `SESSION_CONTEXT`: `gpos_app` puede escribir la misma clave, pero falsificarla no le da nada. La reconciliación `L` solo la crea el procedimiento de apertura, y la marca exige también el `CURRENT_TRANSACTION_ID()` de esa transacción.

---

## 10. Respaldo, restauración y retención

- **Retención:** las filas de `sync.Reconciliacion*` y de `fiscal.NcfZonaIncierta` no se purgan, porque son soporte fiscal (10 años, como la bitácora). Volumen: menos de 10 KB por desbloqueo. No afecta el tamaño ni el costo.
- **Respaldo completo inmediatamente después de cada desbloqueo** (regla para devops). Si después se restaura un respaldo **anterior** al desbloqueo, la base vuelve a tener los bloques originales en `A`, sin la marca `X` ni la zona: la base **no puede** recordar lo que el respaldo no contiene (R-D1).
- **DM-04: `AUTO_CLOSE OFF` obligatorio.**
  - **Dónde:** en `Aprovisionamiento.FijarOpcionesAsync` (`src/GPOS.Migracion/Aprovisionamiento.cs:300-328`), junto a RCSI, FULL y Query Store:
    - leer `is_auto_close_on` e `is_auto_shrink_on` de `sys.databases`;
    - si están activas: `ALTER DATABASE <base> SET AUTO_CLOSE OFF;` y `… SET AUTO_SHRINK OFF;`, informando el cambio.

    No va en la migración: `ALTER DATABASE … SET` no se permite dentro de la transacción de la migración (*inferido*: error 226).
  - **Efecto:**
    - quita los arranques en frío de 4 a 6 s que midió C;
    - una base restaurada hereda la opción de su respaldo, y `actualizar` la corrige.
  - **Costo:** USD 0. Cada base abierta retiene unos pocos MB del búfer de Express (tope de unos 1.410 MB, según C). Es despreciable con menos de 20 empresas por instancia (*inferido*).
  - **`GPOS_SYSDATA`:** la crea la API (`EsquemaSistema`). Recomiendo aplicar lo mismo allí, o en la guía de devops si la cuenta de la API no tiene `ALTER` sobre la base. Es una entrega a backend y devops.
  - **Alternativa descartada:** dejarlo en la guía. Express crea las bases con `AUTO_CLOSE` activo, y la guía se olvida.
  - **Prueba:** CA-H11-16 de [SW] y PD-12.

---

## 11. Pruebas de datos (para `tests/GPOS.Tests/ModeloNg/DesbloqueoRestauracionTests.cs`, bases `GPOS_TEST_H11_*`)

| Id | Caso | Esperado |
|---|---|---|
| PD-01 | `Up`, `Down` y `Up` en una base temporal; `Down` con una reconciliación confirmada | Sin diferencias de esquema entre los dos `Up`. Con datos, `Down` da 51399 y no cambia nada |
| PD-02 | La guarda (`ConsultasDocumentos.EstadoEmision` con `WITH (HOLDLOCK)`) sobre la vista ampliada, como `gpos_app` | Sin error de indicaciones. Si falla, se aplica el plan de reserva de 8.1 |
| PD-03 | `RendimientoOla3Tests` antes y después | La guarda no sube más de 0,05 ms por emisión |
| PD-04 | El desbloqueo completo de CA-H11-04 con `EXECUTE AS USER = 'qa_app_h11'` | Sin 229. Un `UPDATE` directo de `sync.EstadoNodo`, `sync.Reconciliacion`, `ReconciliacionNcf` y `ReconciliacionSerie` da 229 |
| PD-05 | Restauración real, y luego `usp_AbrirReconciliacionLocal` como `gpos_app` | Lee el fork actual (no nulo). Abre en `L` |
| PD-06 | Cada procedimiento llamado sin transacción, y la confirmación llamada en una transacción distinta de la que abrió | 51329 (C0) |
| PD-07 | Reglas C3 a C8, rompiendo una por vez: falta una fila; zona mal; bloque nuevo con otro `Desde`; `Siguiente` del `X` sin ajustar; un comprobante dentro de `Siguiente … Hasta` de un bloque vigente (C5); serie sin fila; margen 99; `TRASLADO` con un cierre | 51329 con la regla correcta. Todo se deshace: `EstadoNodo`, bloques, zona y bitácora quedan igual que antes |
| PD-08 | Base no restaurada; bloqueo `MANUAL`; otro nodo activo; sin fila en `EstadoNodo` | 51328 con el sufijo correcto, sin cambios |
| PD-09 | Concurrencia: una emisión con la guarda leída, contra el desbloqueo; y dos desbloqueos a la vez | Sin interbloqueo. La emisión falla con 503 o 51330. Un desbloqueo termina y el otro da 51328 (`SITIO_NO_RESTAURADO`) |
| PD-10 | H-12 después del desbloqueo | `UPDATE` del `X` (estado, `Hasta` o `Desde`): 51325. Bloque que se solapa con `Desde … Corte`: 51324. Emitir desde el `X`: 51327. La primera venta toma `Corte + 1` |
| PD-11 | Consultas de 6.2 con 200.000 documentos y 20.000 clientes, en frío | Menos de 2 s en total (cifra de referencia, inferida) |
| PD-12 | `actualizar` sobre una base con `AUTO_CLOSE ON` | La base queda en `OFF`, y la segunda pasada no informa nada |
| PD-13 | Reconciliación huérfana: se abre, se confirma la transacción sin confirmar la reconciliación (simula un defecto) y se reintenta | La base sigue bloqueada. El reintento cancela la `L` anterior (`X`) y termina bien |

---

## 12. Riesgos

### 12.1 Reasignación de NCF (lo que se pidió señalar)

| Id | Riesgo | Prob. / impacto | Mitigación |
|---|---|---|---|
| **R-D1** | **Restaurar un respaldo anterior a un desbloqueo ya hecho.** La base pierde los `X`, la zona y la reconciliación, y vuelve a mostrar los bloques en `A` con el `Siguiente` viejo. La validación I-1 solo conoce la base, así que un último probado mal declarado repite los NCF que se emitieron entre el primer desbloqueo y la segunda restauración. **La base no puede impedirlo por construcción** | Baja / **alto** | Hoy: la evidencia obligatoria (R-1 de [SW]) y el respaldo inmediato después de cada desbloqueo (sección 10). **Propuesta P-7:** una marca externa en `GPOS_SYSDATA`, que no se restaura con la empresa |
| R-D2 | Un servicio defectuoso baja `Siguiente` antes del corte, o recorta por debajo de lo emitido | Baja / alto | 51326 y **C5**, que compara contra `fiscal.Comprobante` y no contra lo que declara el servicio. **Cerrado en la base** |
| R-D3 | Un bloque nuevo que empieza en un número ya cerrado | Muy baja / alto | 51324 (solape con el `X`, que conserva `Desde … Corte`) y C4 (`n.Desde = s.Hasta + 1`) |
| R-D4 | **Bloques `C` (cerrados a mano) con números sin usar.** Si después del respaldo se reabrió un `C` y se emitió con él, la base restaurada lo muestra `C` y queda fuera del desbloqueo. Después, la pantalla podría reabrirlo y repetir esos NCF. La pantalla solo impide reabrir los `X` (`AdministracionService.cs:337-338`, citado en [SW] 1.1) | Baja / alto | Entrega al especialista-pos. Recomendación: en una restauración, listar también los `C` con `Siguiente ≤ Hasta` y cerrarlos en `X` con su último probado. La regla de la base no cambia: C3 se amplía con `OR (s.Estado = 'C' AND s.Siguiente <= s.Hasta)`, +0,03 sp |
| R-D5 | R-3 de [SW]: secuencias registradas después del respaldo, que se pierden y se vuelven a registrar desde su primer número | Baja / alto | Aviso de la tarjeta. C5 no lo detecta, porque sus comprobantes tampoco están en la base. Si se firma, P-7 lo cubre |
| R-D6 | Interbloqueo con una pantalla que bloquee varias series en otro orden (sección 6.1) | Baja / bajo | El motor elige una víctima, se deshace todo y se reintenta. PD-09 |

### 12.2 Otros riesgos

| Id | Riesgo | Mitigación |
|---|---|---|
| R-D7 | La indicación `HOLDLOCK` propagada a `sys.database_recovery_status` (PD-02), o la lectura del fork con `EXECUTE AS OWNER` (PD-05) | Planes de reserva en 8.1 y 9.2, de +0,03 y +0,05 sp |
| R-D8 | `rpt.Formato608` muestra **una fila por zona** (solo su `Desde`) y no una por NCF anulado (`SqlMigracionesOla3.cs`, vista `rpt.Formato608`). Es un defecto previo, que el 608 aplazado oculta | Entrega a backend y QA cuando se retome el 608, con P-6 de [SW] |
| R-D9 | Las secuencias de llave retroceden (R-4 de [SW]) | **No** se adelantan en H-11: en la base única los `Id` perdidos ya no están en la base. Condición: llamar a `sync.usp_AdelantarSecuencias` (que acepta una reconciliación en `L`) **antes de activar el primer conector ERP o los adjuntos** (ADR-67 y ADR-73), porque pueden guardar `Id` fuera de la base. +0,05 sp |
| R-D10 | La migración en sí | Menos de 1 s, sin pérdida de datos. La previa y el `Down` usan 51399 |

---

## 13. Preguntas para el propietario

- **P-7. Marca externa del último desbloqueo (R-D1 y R-D5).** Cada desbloqueo guardaría en `GPOS_SYSDATA`, por empresa, el fork y el corte de cada prefijo (y, si se quiere, el `Hasta` de cada bloque registrado). R1 avisaría y R3 exigiría un último probado mayor o igual a ese corte cuando la base esté por debajo, es decir, cuando se restauró un respaldo más viejo que el último desbloqueo.
  - **Costo:** 0,15 a 0,2 sp (*inferido*), USD 0.
  - **Recomendación:** sí, antes del primer cliente de una sola sucursal.
  - *Por omisión:* no se construye en H-11, y rige la regla de devops del respaldo inmediato.
- **P-2b (amplía P-2 de [SW]).** La serie interna `MovimientoCaja` (clase `INT`, `CatalogoNumeracion.cs:78`) no está en el alcance de RN-12. Si su número sale impreso en los comprobantes de retiro, se repetiría después de restaurar. ¿Se adelanta también?
  - *Por omisión:* no.
  - *Recomendación:* preguntar al especialista-pos si el número se imprime. Si se imprime, incluirla (+0 sp: es una fila más en C6).

---

## 14. Esfuerzo (inferido, ±40 %)

| Parte | sp |
|---|---|
| Migración: EF (3 columnas, 5 `CHECK`, índice), vista, 2 procedimientos, permisos, `Down` y guion regenerado | 0,20 (de 0,15 a 0,30). [SW] estimaba 0,15; la diferencia son las reglas C0 a C8, `HastaAnterior` y la bitácora en el procedimiento |
| Pruebas de datos PD-01 a PD-13 | Dentro de las 0,15 sp de pruebas de [SW]; +0,05 si PD-02 o PD-05 obligan al plan de reserva |
| DM-04 (`AUTO_CLOSE` y `AUTO_SHRINK`) | 0,02 |
| Si se firma P-7 | +0,15 a 0,2 |
| Si se acepta R-D4 (bloques `C`) | +0,03 |

---

### Cierre
- Estado: Completado
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\datos-h11-desbloqueo-restauracion-2026-10-10.md`
- Supuestos:
  - (1) el motor mínimo es SQL Server 2019 (sin `GREATEST` ni `IS DISTINCT FROM`), *inferido* de las mediciones de H0;
  - (2) `EXECUTE AS OWNER` lee el fork como T95 (por PD-05);
  - (3) `HOLDLOCK` se propaga sin error a `sys.database_recovery_status` (por PD-02);
  - (4) las bases reales no tienen filas en `sync.Reconciliacion*`;
  - (5) `ALTER DATABASE … SET` no cabe en la transacción de la migración.
- Decisiones candidatas a ADR:
  - DD-1: la confirmación escribe en la base las dos líneas finales de la bitácora;
  - DD-2: la confirmación valida I-1 e I-7 contra los datos (C0 a C8, con C5 sobre `fiscal.Comprobante`), sin confiar en el servicio;
  - DD-3: un bloqueo de otra causa gana sobre la restauración;
  - DD-4: la huella se recalcula después de bloquear configuración, series y NCF;
  - DD-5: `HastaAnterior` y la inmutabilidad de `sync.Reconciliacion*` por `DENY`;
  - DD-6: `AUTO_CLOSE OFF` y `AUTO_SHRINK OFF` como opciones obligatorias de toda base (DM-04, junto a RCSI, FULL y Query Store);
  - sin índice nuevo para RN-12.
- Entregas a otros agentes:
  - desarrollador-backend → secciones 6 a 9 y la tabla de archivos de 7.1; mapear los sufijos de 51328; el espejo `_LOG` de las dos líneas finales; DM-04 en `FijarOpcionesAsync` y en `EsquemaSistema`;
  - qa → PD-01 a PD-13;
  - especialista-pos → R-D4 (bloques `C`) y P-2b;
  - devops → respaldo completo inmediatamente después de cada desbloqueo, y `AUTO_CLOSE OFF` en `GPOS_SYSDATA` si la API no tiene `ALTER`;
  - revisor de seguridad → sección 9 y el uso de `SESSION_CONTEXT`;
  - arquitecto-maestro → P-7 y P-2b al propietario, y DD-1 a DD-6.
- Próximo paso recomendado: que el desarrollador-backend construya la migración con PD-02 y PD-05 primero, porque deciden si se usan los planes de reserva.
