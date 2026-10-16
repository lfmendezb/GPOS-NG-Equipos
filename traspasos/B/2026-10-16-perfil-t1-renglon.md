# Perfil del costo por renglón de T1 (N6-02) y de la meta 5b de T-57

**Equipo B, arquitecto de datos, 2026-10-16 (tarde).** Análisis y medición dirigida en LFMB. No se cambió código de producción. No se tocó el commit de `GPOS-B-carga` (`fb32b26b`) ni el de `GPOS-B-prep27` (`3b04495f`). Los prototipos se construyeron en copias exportadas con `git archive`, en el directorio temporal de la sesión.

Insumo: `traspasos/B/2026-10-16-t6-segunda-tanda.md`.

## 0. Resumen
- **Causa de N6-02 (cierta y medida):** el candidato lee la política por renglón, con `SELECT … FROM inv.PoliticaNegativa` en `AplicarExistencia`. Son 3 búsquedas por llave y una sentencia más por renglón, y se ejecutan **dentro de la sección serializada por la serie**: el `UPDLOCK` de `num.Serie` se mantiene hasta el `COMMIT`.
  - Cuesta **+0,40 ms de CPU por venta de 20 renglones** dentro de esa sección: 0,43 → 0,88 ms en los comandos de existencia. Es un **+11 %** de la CPU de la sección crítica (3,71 → 4,12 ms).
  - Con 6 cajeros, la serie es el cuello de botella. Ese tiempo se paga casi entero en la respuesta: la espera de la serie por venta pasa de 13,05 a 15,20 ms (+16 %).
  - El resto del candidato (ola 3b, `TR_Documento_Transferencia`, A-N2) suma ≤ 0,01 ms por venta.
- **Por qué el diseño no lo previó:** el DD estimó «neutro o favorable» (4.1). Compensaba un viaje ahorrado, que ocurría *fuera* de la sección serializada, con 10 a 20 µs por renglón que ocurren *dentro*. La medición da unos 20 µs por renglón, en el extremo alto de la estimación.
- **Corrección propuesta:** el respaldo R-02 del propio DD (4.1 y R-02), que ADR-118 ya nombra: «consulta previa de la política (queda como respaldo de rendimiento)».
  - La política de los artículos del documento se lee en `PrepararAsync`, en el mismo viaje que los almacenes y antes de la serie, y llega como parámetro al `UPDATE` condicional, como antes de T1.
  - Medido con un prototipo: la existencia vuelve al nivel de la base dentro de la sección crítica (0,43 ms por venta) y la lectura previa cuesta 0,19 ms **fuera** de ella.
  - **Requiere una precisión firmada de la cláusula 3 de ADR-118** («se resuelve dentro del `UPDATE`»).
  - La alternativa que no cambia la cláusula, plegar la vista dentro del `UPDATE`, se midió y **no alcanza**: solo ahorra entre 0,03 y 0,1 ms.
- **Meta 5b:** **no es un costo por renglón de T1.**
  - La mediana no cambió (base 842 a 873 ms, candidato 807 a 879 ms).
  - Con 10 muestras, el p95 es el máximo, es decir, una sola compra, y en el banco la primera compra «fría» (compilación y estadísticas) es la que se dispara.
  - El costo estable de 5b lo domina un plan inestable de `ConsultasInventario.KardexCosto`: un Hash Join que recorre `IX_Documento_TipoFecha` en cada artículo. Ocurre igual en la base y en el candidato.
  - Con `WITH (FORCESEEK)` en `doc.Documento`, el banco pasa de unos 180 ms a unos 64 ms por compra, estable.

## 1. Método
- **Instancia:** `.\SQLEXPRESS` (2025 Express RTM). Express usa como máximo 4 núcleos: la CPU que se gasta fuera de la sección crítica también compite con la sección.
- **Corridas:** `RendimientoNegativosTests.N6_02` en Release `--no-build`, con `GPOST_B9=medir`, una a la vez.
- **Captura:** un proceso aparte toma cada 10 s una instantánea de las DMV de la base de la prueba. Usa el patrón de dos pasos: primero los `plan_handle` con `dm_exec_plan_attributes` (`dbid`) en una tabla variable, y después `dm_exec_sql_text` solo sobre esos planes. No dio 952.
  - Para el análisis se usa la última instantánea antes del borrado de la base.
  - Las sentencias del lote se agrupan quitando el prefijo `@lN_` de `LoteComandos`.
- **Sección crítica (después de tomar la serie):** las sentencias del lote de comandos de la venta, es decir, existencias, emisión con sus disparadores, `_LOG`, caja y bitácora. «Espera de la serie» es el tiempo transcurrido de `SELECT … FROM num.Serie WITH (UPDLOCK, ROWLOCK)`.
- **Condiciones:** horario diurno, con la máquina no aislada. **El p95 de estas corridas es ruido** (base entre 72,7 y 110,7 ms), así que no lo uso para concluir. Concluyo con la CPU por venta de la sección crítica (estable entre corridas), la espera de la serie, el rendimiento (ventas/s) y la mediana.
- **Banco de 5b:** `PerfilT1Tests.P2_compra_con_fecha_anterior`, un archivo nuevo **solo en las copias temporales y sin confirmar**. Hace lo siguiente:
  - 200 artículos;
  - 90 s de carga con 6 cajeros y 1 comprador de 20 líneas;
  - 5.000 ventas de un artículo caliente;
  - 10 compras de 20 líneas con fecha de 30 días atrás, de una en una;
  - por cada compra, el tiempo, las optimizaciones (`dm_exec_query_optimizer_info`), las estadísticas actualizadas y las sentencias de esa compra (diferencia de las DMV), y al final el plan de `KardexCosto`.

## 2. Diff del candidato en el camino de la venta y de la compra
Diff de `fb32b26b` a `3b04495f` en `src/GPOS.Core`, acotado.

| Cambio | Dónde | Se ejecuta en N6-02 | Costo medido |
|---|---|---|---|
| Lectura de la política por renglón (`SELECT @permite = pn.Permite, @origen = pn.Origen FROM inv.PoliticaNegativa pn WHERE pn.ArticuloId = @articulo`) antes del `UPDATE` | `Consultas/Inventario/ConsultasInventario.cs:19-40` (`AplicarExistencia`) | 20 por venta, **después de la serie** | 0,43 a 0,54 ms de CPU por venta; 4 lecturas lógicas por renglón |
| Se quita el viaje `PermiteNegativaAsync` (antes de la serie) | `LibroInventario.cs` (`PrepararAsync`, L-2) | 1 por venta en la base | 0,034 ms de CPU por venta, fuera de la sección crítica |
| `TR_Documento_Transferencia` (nuevo; `AFTER UPDATE` en `doc.Documento`, salida temprana) | `SqlMigracionesOla3b.cs:521` | 1 por emisión | 0,009 ms por venta |
| UF-05 con `FORCESEEK` y `DISABLE_OPTIMIZED_NESTED_LOOP` | `SqlMigracionesUf05ForceSeek.cs` | No: solo FAC o FPOS con documento de origen; en N6-02, 0 ejecuciones relevantes | — |
| `LotesDocumento.ResolverSalidasAsync(..., soloConControl: true)` | `PosService.cs:284` | Sin consultas si no hay artículos con lote (verificado en `LotesDocumento.cs`) | 0 |
| `ExistenciaLote` con política (vista más `inv.Lote`) | `ConsultasInventario.cs` (`AplicarExistenciaLote`) | No (N6-02 va sin lote) | — |
| `inv.ExistenciaGlobal` con `UNION ALL` del tránsito | `SqlMigracionesOla3b.cs:106` | No (la venta de hoy no recalcula costo); en 5b, 1 por compra | 0,5 a 1,4 ms por compra, igual que la base |

## 3. Medición de N6-02 (base frente al candidato), por venta
Valores de cada corrida (r1, r2 y r3, intercaladas) y mediana.

| Métrica | Base `fb32b26b` (9 corridas) | Candidato `3b04495f` (3) | Plegado en el `UPDATE` (3) | Lectura previa R-02, prototipo (3) |
|---|---|---|---|---|
| CPU de los comandos de existencia (sección crítica), ms por venta | 0,44 a 0,50 (mediana **0,44**) | 1,09 / 0,88 / 0,89 (**0,88**) | 0,88 / 0,85 / 0,82 (**0,85**) | 0,43 / 0,44 / 0,47 (**0,44**) |
| CPU de toda la sección crítica, ms por venta | 3,58 a 3,91 (mediana **3,71**) | 4,86 / 4,06 / 4,12 (**4,12**, +11 %) | 4,20 / 4,02 / 3,93 (**4,02**, +8 %) | 3,56 / 3,62 / 3,85 (**3,62**) |
| Lectura previa de la política (fuera de la sección), ms de CPU por venta | — | — | — | 0,18 / 0,19 / 0,20 |
| Espera de la serie por venta, ms | 11,3 a 13,6 (mediana **13,05**) | 17,6 / 15,1 / 15,2 (**15,20**, +16 %) | 14,7 / 14,8 / 15,1 (**14,79**, +13 %) | 14,1 / 13,8 / 14,5 (**14,09**, +8 %) |
| Ventas por segundo | 116,8 a 133,9 (mediana **124,2**) | 100,2 / 119,8 / 120,3 (**119,8**) | 124,7 / 121,9 / 118,6 (**121,9**) | 118,2 / 119,6 / 111,4 (**118,2**) |
| Mediana de la venta, ms | 36,0 a 43,5 (mediana **39,8**) | 49,4 / 41,0 / 40,7 (**41,0**) | 39,3 / 40,2 / 42,2 (**40,2**) | 42,8 / 41,9 / 44,4 (**42,8**) |

Por sentencia (base r1 frente al candidato r1, por venta):
- `SELECT … inv.PoliticaNegativa`: 19,8 ejecuciones, 0,536 ms de CPU, 79 lecturas lógicas.
- `UPDATE inv.Existencia`: 0,499 → 0,552 ms.
- Emisión (`UPDATE doc.Documento SET Estado = 1 …`, con disparadores): 2,82 → 3,12 ms. Las lecturas lógicas son iguales (322); la diferencia es la inflación general de esa corrida, del +5 al +9 % en todas las sentencias con las mismas lecturas, que no se repitió en r2 ni en r3.

**Lectura:**
- La serie es el cuello de botella con 6 cajeros. En la base, la espera de la serie (13 ms) es un tercio de la mediana de la venta (40 ms) y LCK_M_U domina las esperas del motor: de 150 a 174 s por tramo en la base y de 193 a 195 s en el candidato.
- Lo que el candidato agrega después de la serie (0,40 ms de CPU, más su tiempo de planificador en Express de 4 núcleos) alarga la sección serializada y se multiplica en la cola. Eso da el +16 % en la espera de la serie y el p95 de 1,17 de la medición nocturna.
- El plegado ahorra solo el costo de la sentencia: las 3 búsquedas siguen dentro.
- La lectura previa devuelve la sección crítica al nivel de la base. En rendimiento y mediana queda dentro del ruido diurno de ±5 %, así que **la confirmación tiene que hacerse con el protocolo nocturno de T6**.
- El primer prototipo de la lectura previa usaba `IN (SELECT … FROM OPENJSON …)` y costaba **1,6 ms** de CPU por venta, porque relee el JSON por cada artículo del catálogo; empeoró la venta (110 a 117 ventas/s). Con `DISTINCT` más `CROSS APPLY`, el patrón de `ConsultasInventario.ExistenciaGlobal`, cuesta 0,19 ms.

## 4. Propuesta para N6-02 (backend; precisión firmada de ADR-118, cláusula 3)
**Recomendada: R-02 del DD, la política leída en `PrepararAsync` y pasada por parámetro.**

1. `src/GPOS.Core/Consultas/Inventario/ConsultasInventario.cs`:
   - Nueva consulta, en el mismo viaje que `SucursalesAlmacen` (dos resultados, con `ConsultarVariosAsync`, sin viajes nuevos):
     ```sql
     -- [ConsultaRegistrada(typeof(PoliticaArticuloFila), Parametros = "@articulos varchar(8000)")]
     SELECT pn.ArticuloId, pn.Permite, pn.Origen
       FROM (SELECT DISTINCT j.[value] AS ArticuloId FROM OPENJSON(@articulos) WITH ([value] int '$') j) a
      CROSS APPLY (SELECT p.ArticuloId, p.Permite, p.Origen FROM inv.PoliticaNegativa p WHERE p.ArticuloId = a.ArticuloId) pn
     ```
     **No** usar `IN (SELECT … FROM OPENJSON …)`: mide 1,6 ms de CPU por venta.
   - `AplicarExistencia`: `@permite` (bit) y `@origen` (`char(1)`, con `Sql.Varchar(…, 1)` por ADR-50) vuelven a ser parámetros. Se quita la lectura de la vista. Lo demás queda igual, también la búsqueda de la categoría solo cuando no se aplicó con origen G:
     ```sql
     DECLARE @ok bit = 0, @ex decimal(18, 6), @categoria varchar(20);
     UPDATE inv.Existencia WITH (ROWLOCK)
        SET @ex = Cantidad = Cantidad + @delta, PermiteNegativa = CASE WHEN Cantidad + @delta < 0 THEN 1 ELSE @permite END,
            ActualizadaEn = SYSUTCDATETIME()
      WHERE ArticuloId = @articulo AND AlmacenId = @almacen AND (@delta >= 0 OR @permite = 1 OR Cantidad + @delta >= 0);
     IF @@ROWCOUNT = 1 SET @ok = 1;
     ELSE
     BEGIN
         SELECT @ex = Cantidad FROM inv.Existencia WITH (UPDLOCK, HOLDLOCK) WHERE ArticuloId = @articulo AND AlmacenId = @almacen;
         IF @ex IS NULL AND (@delta >= 0 OR @permite = 1)
         BEGIN
             INSERT INTO inv.Existencia (ArticuloId, AlmacenId, Cantidad, PermiteNegativa, ActualizadaEn)
             VALUES (@articulo, @almacen, @delta, CASE WHEN @delta < 0 THEN 1 ELSE @permite END, SYSUTCDATETIME());
             SELECT @ok = 1, @ex = @delta;
         END
         ELSE IF @origen = 'G'
             SELECT @categoria = c.Codigo FROM cat.Articulo a JOIN cat.Categoria c ON c.Id = a.CategoriaId WHERE a.Id = @articulo;
     END
     SELECT @ok AS Aplicado, ISNULL(@ex, 0) AS Existencia, @permite AS Permite, @origen AS Origen, @categoria AS Categoria;
     ```
   - `AplicarExistenciaEstricta`: el mismo texto con, justo después del `DECLARE`, las líneas `SET @origen = CASE WHEN @permite = 1 THEN 'T' ELSE @origen END;` y `SET @permite = 0;` (los parámetros se pueden asignar). Así se conserva la aserción de texto de `NegativosNucleoTests.N1_15` («`SET @permite = 0;`»).
   - `AplicarExistenciaLote`: **sin cambio**. Solo corre en renglones con lote y necesita `inv.Lote` de todos modos (vencimiento y pertenencia, SEG-T1-04).
2. `src/GPOS.Core/Servicios/Modulos/Inventario/LibroInventario.cs`:
   - `KardexPreparado` gana `IReadOnlyDictionary<int, PoliticaArticuloFila> Politicas`.
   - `PrepararAsync` la llena en el viaje de los almacenes, para todos los caminos, también los retornos tempranos.
   - `ExistenciaDiferida` la recibe desde `AplicarSinExistenciaAsync`.
   - `ExistenciasEnLote.Comandos` pasa `permite` y `origen` por renglón. Si un artículo no está en el diccionario, `InvalidOperationException`: la vista tiene una fila por artículo.
3. Pruebas:
   - Las funcionales siguen verdes con el prototipo (sección 6).
   - La nueva consulta lleva `[ConsultaRegistrada]` (CP-169 y CP-170, `varchar`).
   - `EscrituraExistenciaTests` (P-12) no cambia: los escritores siguen siendo los dos comandos.

**Riesgo:**
- Bajo en la corrección. La política se lee antes de la serie: un cambio de política que confirme en ese intervalo (milisegundos; hasta cientos en el p99 de la cola) se aplica a la venta «como si hubiera ocurrido antes». El DD lo declara aceptable (3.2, «Cambio de política simultáneo», y 4.1).
- Las redes declarativas no cambian: `CK_Existencia_Negativa` y la marca de fila la escribe el mismo `UPDATE`.
- No hay bloqueos nuevos y el orden único no cambia.
- **Cambia la letra de la cláusula 3 de ADR-118**: hace falta la firma del propietario (sección 8).

**Alternativas medidas o descartadas:**
- **Plegar la vista dentro del `UPDATE`** (`UPDATE e … FROM inv.Existencia e WITH (ROWLOCK) JOIN inv.PoliticaNegativa pn … WHERE … (@delta >= 0 OR pn.Permite = 1 OR e.Cantidad + @delta >= 0)`, con la lectura de la vista solo en el camino de fallo):
  - Cumple la letra de la cláusula 3 mejor que el código actual, que lee la vista en una sentencia aparte.
  - **Medido: insuficiente.** La sección crítica queda en 4,02 ms frente a 3,71 de la base: las 3 búsquedas por renglón siguen dentro.
  - Funcionalmente verde (153 de 154), con un solo ajuste de la aserción de texto de N1_15.
  - Es útil solo si el propietario no firma R-02.
- **Columna «efectiva» materializada o marca de fila como fuente:** descartada por el ADR (ventana de incoherencia y recálculo masivo).
- **Contador global de versión de la política,** leído una vez por documento dentro del lote: conserva la atomicidad con una búsqueda por documento, pero exige una columna y disparadores nuevos. Es más complejo de lo que la corrección necesita.
- **Actualización de conjunto (un solo `UPDATE` para los 20 renglones):** pondría en riesgo el orden de llave de los bloqueos (el orden único de ADR-45 y ADR-72), porque el orden de acceso del plan no está garantizado. Descartada.

## 5. Meta 5b (compra con fecha anterior)
- **Verificado en los registros de T6 (r2 y r3, 5 y 5 corridas):** la mediana no cambia (base 842,5 a 873,2 ms; candidato 806,9 a 879,0 ms). Con 10 muestras, el p95 es el **máximo**: una sola compra por corrida. La subida de 1.180 a 1.509 ms está entera en esa muestra.
- **Verificado en el banco:**
  - La primera compra con fecha anterior después de la carga cuesta entre 288 y 475 ms. Hace de 18 a 39 optimizaciones (de 128 a 423 ms de compilación) y actualiza estadísticas de `doc.Documento`, `caja.Movimiento` e `inv.Movimiento`.
  - Las 9 siguientes son planas: 2 optimizaciones y entre 4 y 5 ms de compilación.
  - En 2 corridas por lado no hay una diferencia sistemática del costo frío entre la base y el candidato (base 460 y 356 ms; candidato 288 y 475 ms).
- **Verificado en el banco: el costo estable lo domina `ConsultasInventario.KardexCosto`** (20 ejecuciones por compra, una por artículo), con un plan inestable:
  - Hash Match con **Index Scan de `doc.Documento.IX_Documento_TipoFecha`** en cada ejecución: 138 ms de CPU por compra y unos 180 ms por compra.
  - Bucle anidado con búsqueda: entre 23 y 27 ms por compra y unos 60 ms por compra.
  - El plan cambia con las recompilaciones (generación de plan 46 a 66) y con el valor olfateado. **Se dio en la base (r2: 180 ms) y en el candidato (dos veces)**: no lo causa T1.
- **Inferido:** en T-57 hay unas diez veces más documentos. El recorrido explica la mediana de unos 850 ms en los dos lados y hace más caro el máximo frío, porque recorre en frío un índice grande.
- **Propuesta para 5b (backend; sin firma, no cambia ninguna regla):** `src/GPOS.Core/Consultas/Inventario/ConsultasInventario.cs`, en `KardexCosto`:
  ```sql
    FROM inv.Movimiento m
    JOIN doc.Documento d WITH (FORCESEEK) ON d.Id = m.DocumentoId
   WHERE m.ArticuloId = @articulo AND m.Clase <> 6
  ```
  Medido en el banco:
  - 10 compras de 62 a 67 ms (frente a 175 a 192 ms con el plan de recorrido);
  - `KardexCosto` con 27 ms de CPU por compra (frente a 138);
  - la primera compra en 391 ms (el costo frío de compilación sigue igual).
  - El costo pasa a crecer con los movimientos del artículo, no con el tamaño de `doc.Documento`.
  - **Inferido** para T-57: la mediana de 5b baja a 100 a 200 ms, con margen amplio frente al tope de 2.000.
- **Lo que T1 agrega a 5b:** 20 lecturas de la política por compra, ≤ 1 ms.

## 6. Verificación hecha y la que falta
- Hecho (copia temporal del candidato, Release, `.\SQLEXPRESS`):
  - Con el plegado más `FORCESEEK`: filtro de negativos, existencias, lotes, B7j, transferencias, costo y kárdex. **153 correctas y 1 fallida**: `N1_15`, solo en la aserción de texto, que el plegado cambia. La lectura previa no la cambia.
  - Con la lectura previa (prototipo): `NegativosNucleo`, `LoteDocumentos`, `B7jExistencias`, `NumeracionB7f`, `NumeracionBloqueos` y `EscrituraExistencia`: **74 de 74**.
  - N6-02 en todas las corridas: 0 errores, 0 interbloqueos, conciliación 0, sin existencias negativas.
- Falta:
  1. Que el backend implemente R-02 con la consulta en el mismo viaje que los almacenes, y `FORCESEEK` en `KardexCosto`.
  2. Corrida de la suite oficial con el filtro `Transicion!=Ola5&Transicion!=Defecto`.
  3. **T6 de noche** con el protocolo 7.3: N6-02 con 5 corridas por lado y criterio ≤ 1,05; T-28 y T-57 completos, con 5b.
  4. En la medición, comprobar con las DMV que la CPU de los comandos de existencia por venta vuelve a 0,44 ms y que la espera de la serie por venta queda a ±5 % de la base.

## 7. Hallazgos laterales (no son de T1)
- **`ConsultasCompras.UnidadesArticulos`** (`ConsultasCompras.cs:89-93`, usada en cada venta POS): `WHERE au.ArticuloId IN (SELECT … FROM OPENJSON …)`.
  - Cuesta **1,8 ms de CPU por venta** con 4 lecturas lógicas, y concede **1.024 KB** de memoria en cada ejecución (`last_grant_kb`), en la base y en el candidato.
  - Es el mismo antipatrón medido arriba: 1,6 ms frente a 0,19 ms con `DISTINCT` más `CROSS APPLY`.
  - Reescribirla con el patrón de `ExistenciaGlobal` libera unos 1,5 ms de CPU por venta en un Express de 4 núcleos. Daría margen a T-28 (1,046) y al criterio 8.2 (6) de memoria concedida.
  - Severidad Media. Al backend, con su propia medición.
- **5b como métrica:** con 10 muestras, el p95 es el máximo e incluye el costo frío de compilación y estadísticas. A QA: informar aparte la primera compra (fría) y el p95 de las otras 9, o subir a 30 muestras.

## 8. Decisión candidata a ADR
**Precisión de ADR-118, cláusula 3 (activar el respaldo R-02):**
- **Contexto:** N6-02 da 1,173 con 5 corridas por lado. La causa medida son 0,40 ms de CPU por venta dentro de la sección serializada por la serie.
- **Opción:** la política efectiva se resuelve una vez por documento en `PrepararAsync`, en el mismo viaje que los almacenes, leída de `inv.PoliticaNegativa` (que sigue siendo la única fuente), y llega como parámetro al `UPDATE` condicional. Los dos comandos siguen siendo los únicos escritores (P-12).
- **Descartadas:** plegar la vista en el `UPDATE` (medido insuficiente); columna materializada (ya descartada por el ADR); contador de versión (más complejo).
- **Costo:** unas 0,5 semanas-persona del backend, más una noche de T6.
- **Estado:** pendiente de firma del propietario. La prepara el Arquitecto Maestro.

## 9. Artefactos temporales (no confirmados)
- **Banco:** `C:\Users\lfmen\AppData\Local\Temp\claude\C--Users-lfmen-source-repos-Solucion-GPOS-NG-GPOS-NG\f0ef3310-0500-40cc-9e4f-8b69aa2f95ef\scratchpad\PerfilT1Tests.cs`.
- **Prototipos:** `...\scratchpad\w\cand` (plegado más `FORCESEEK`) y `...\scratchpad\w\fix2` (lectura previa).
- **Instantáneas de las DMV y registros:** `...\scratchpad\perf\`.
- **Bases de prueba:** no quedan bases `GPOS_TEST_*` en `.\SQLEXPRESS`.
- **Árboles:** `GPOS-B-prep27`, limpio; `GPOS-B-carga`, solo con su `RendimientoNegativosTests.cs` sin confirmar, como estaba.
