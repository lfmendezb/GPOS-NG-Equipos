# Perfil de R-02 en la venta POS de 1 renglón (T-28)

**Equipo B, arquitecto de datos, 2026-10-17 (madrugada).** Se midió y analizó en LFMB, `.\SQLEXPRESS` (SQL Server 2025 Express RTM-GDR 17.0.1145.4). No se cambió código de producción ni se confirmó nada. Los árboles quedaron igual: `GPOS-B-prep27` en `b2c1cdd7` y limpio; `GPOS-B-carga` en `e80f4654`, solo con su `RendimientoNegativosTests.cs` sin confirmar, como estaba. El banco y los prototipos se construyeron en copias hechas con `git archive`, en el directorio temporal de la sesión (sección 8). No quedan bases `GPOS_TEST_*`.

Insumos: `traspasos/B/2026-10-16-t6-segunda-tanda.md` (sección «T6 con R-02») y `traspasos/B/2026-10-16-perfil-t1-renglon.md`.

## 0. Resumen
1. **La lectura previa de R-02 no explica la diferencia de T-28.**
   - Con 1 renglón, la sentencia de la política cuesta de 68 a 87 µs de CPU por venta. La base hacía `PermiteNegativa` en un viaje aparte (26 a 28 µs). La diferencia neta en el motor es de **+40 a +60 µs por venta** y queda **antes de la serie**, fuera de la sección que se serializa.
   - En el cliente, el viaje de la preparación del candidato (un viaje, de 265 a 278 µs con un hilo) cuesta lo mismo que los dos viajes de la base (191 µs más unos 100 µs).
   - La concesión de 1.024 KB no produjo ninguna espera `RESOURCE_SEMAPHORE` (0 en todas las corridas). Su costo no se distingue del ruido: misma consulta con y sin concesión, 152 frente a 153 µs.
   - **Prueba decisiva:** un candidato con la política leída sin `OPENJSON` ni concesión (`candx`, sección 5) cae igual en el «modo lento» (p95 28,4 ms en una de sus dos corridas).
2. **La diferencia de T-28 es bimodal y no depende de la preparación.**
   - Cada corrida de 6 cajeros cae en un «modo rápido» (unas 300 ventas/s, p95 de 23,4 a 24,3 ms) o en un «modo lento» (270 a 282/s, p95 de 26,9 a 29,2 ms).
   - La base cae casi siempre en el rápido: 6 de 7 corridas (T6 y este banco). El código del candidato, con o sin la lectura de R-02, cae en el lento en 6 de 9.
   - El modo lento infla de manera uniforme todas las sentencias (de +8 a +10 % de CPU por ejecución, con el mismo plan y las mismas lecturas) y todos los viajes del cliente (de +25 a +40 %). También sube `PAGELATCH_*`.
   - Es un efecto de todo el candidato bajo concurrencia, no de una sentencia. Con un hilo, la base y el candidato son iguales. Queda **sin causa identificada** (sección 6).
3. **Hallazgo nuevo, severidad Alta: `PoliticasArticulos` recorre el catálogo entero.**
   - Con `OPTION (FORCE ORDER, LOOP JOIN)`, el plan es un `Table Spool` sobre un `Clustered Index Scan` de `cat.Articulo`, que se recorre por cada artículo pedido.
   - El costo crece con el catálogo. Por ejecución, para 1 artículo:

     | Catálogo | CPU | Lecturas |
     |---|---|---|
     | 1 artículo | 62 µs | 4 |
     | 30 artículos | 149 µs | 125 |
     | 300 artículos | 878 µs | 1.213 |
     | 3.000 artículos | **8,3 a 8,6 ms** | **12.147** |

     Con 20 artículos y un catálogo de 3.000: **13,5 a 14,0 ms**.
   - T-28 no lo ve porque vende de un catálogo de 1 artículo. La prueba propia `NegativosPoliticaPreparacionTests.R02_…` tampoco lo ve, porque no revisa recorridos en la política. Agregándole esa aserción, **falla en el candidato** (sección 4).
   - Afecta a todo documento que pasa por `LibroInventario.PrepararAsync`: ventas, compras, ajustes y transferencias.
4. **Ajuste mínimo propuesto, sin cambiar lo firmado:**
   - Se mantiene una lectura por documento, en la preparación, de la vista `inv.PoliticaNegativa`.
   - Cambia la forma: `STRING_SPLIT` más `CROSS APPLY (SELECT TOP (1) …)` con `OPTION (NO_PERFORMANCE_SPOOL)`.
   - Medido:
     - de 26 a 40 µs para 1 artículo y de 89 a 96 µs para 20;
     - 4 lecturas por artículo;
     - **0 KB de concesión**;
     - el mismo plan con catálogos de 1 a 3.000.
   - Verde en las pruebas funcionales de negativos, lotes, existencias, numeración y contratos de consultas (90 de 90), y en la prueba del plan con la aserción nueva.
   - **No corrige T-28.** Para eso, ver la sección 6.

## 1. Método
- **Banco temporal `PerfilR02Tests`**, que no se confirma. Se compiló en Release en tres copias:
  - `w2/base` (`e80f4654`);
  - `w2/cand` (`b2c1cdd7`);
  - `w2/candx` (`b2c1cdd7` con la política propuesta).
- **Pruebas del banco:**
  - **P1:** un hilo, 300 ventas de calentamiento y 3.000 medidas.
  - **P2:** 6 cajeros, 30 s de calentamiento y 120 s medidos.
  - Las dos usan la venta de T-28: 1 renglón, sin lote, efectivo, un cuarto con B02 (`PosService.VenderAsync`) y un catálogo de 1 artículo.
  - **P3:** las variantes de la lectura de la preparación, sueltas: 3.000 iteraciones con 1 hilo y 3.000 × 6 hilos.
  - **P4:** las variantes de la política con catálogos de 1, 30, 300 y 3.000 artículos, después de `UPDATE STATISTICS … FULLSCAN` y de `ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE`.
- **Motor:** `sys.dm_exec_query_stats` en dos pasos: primero los `plan_handle` de la base (`dm_exec_plan_attributes`, `dbid`) en una tabla variable, y después `dm_exec_sql_text` y `dm_exec_text_query_plan` solo de esos planes. No dio 952.
  - Se toma la diferencia antes y después del tramo, por sentencia: CPU, tiempo transcurrido, lecturas, `last_grant_kb`, `max_grant_kb`, `last_used_grant_kb` y `last_ideal_grant_kb`.
  - Esperas: `sys.dm_os_wait_stats` (`RESOURCE_SEMAPHORE*`, `LCK_M_U`, `PAGELATCH_*`, `WRITELOG`, `MEMORY_ALLOCATION_EXT`).
- **Cliente:** el `DiagnosticListener` de SqlClient, con el tiempo de cada comando por su texto, más la CPU del proceso de prueba y los bytes asignados por venta.
- **Corridas** de una en una, alternando base y candidato. Carga de CPU del equipo del 3 % al empezar.

## 2. Costo de la preparación por venta de 1 renglón
### 2.1 Un hilo (P1; base r1/r2 frente a candidato r1/r2)

| Métrica | Base `e80f4654` | Candidato `b2c1cdd7` |
|---|---|---|
| Venta: media / mediana / p95 (ms) | 12,47 / 12,09 / 13,94; 12,60 / 12,23 / 13,91 | 12,48 / 12,10 / 13,76; 12,95 / 12,68 / 14,19 |
| CPU del motor por venta (ms) | 4,44; 4,48 | 4,48; 4,66 |
| Sentencias por venta; comandos del cliente por venta | 89,5; 30,5 | 90,5; 29,5 |
| `SucursalesAlmacen` (CPU por ejecución, lecturas, concesión) | 80 µs, 4, 1.024 KB | 79 µs, 4, 1.024 KB |
| Política (`PermiteNegativa` en la base; `PoliticasArticulos` en el candidato) | 26 µs, 2 lecturas, 0 KB | **68 a 69 µs, 4 lecturas, 1.024 KB** |
| `UnidadesArticulos` | 82 µs, 1.024 KB | 81 µs, 1.024 KB |
| Viaje de la preparación en el cliente | 191 a 194 µs (almacenes) más `PermiteNegativa` en un viaje aparte (≈ 100 µs; fuera del top 24, por debajo de 128 µs) | **265 a 278 µs** (un viaje, los dos resultados) |

### 2.2 Seis cajeros (P2): la sentencia de la política en el motor
- Candidato: **77 a 87 µs** de CPU por venta, 4 lecturas, 1.024 KB.
- Base: `PermiteNegativa` 28 µs, 0 KB.
- Viaje de la preparación en el cliente:
  - candidato: 398 a 419 µs;
  - base: 287 µs más el viaje de `PermiteNegativa`.
- `RESOURCE_SEMAPHORE`, `RESOURCE_SEMAPHORE_QUERY_COMPILE` y `RESOURCE_SEMAPHORE_MUTEX`: **0 esperas en todas las corridas** (base, candidato y `candx`).

### 2.3 Variantes sueltas (P3, catálogo de 31 artículos; CPU y lecturas por ejecución)

| Variante | Cliente con 1 hilo | Motor | Concesión |
|---|---|---|---|
| B0, base: almacenes más `PermiteNegativa` (2 viajes) | 280 µs | 58 + 23 µs | 1.024 KB + 0 |
| C0, candidato: `AlmacenesYPoliticas` (1 viaje) | 305 µs | 52 + **137 µs, 129 lecturas** | 1.024 KB + 1.024 KB |
| C2, política sin `DISTINCT` | 256 µs | 152 µs, 129 lecturas | 1.024 KB |
| C3, política con `MAX_GRANT_PERCENT = 0` | 257 µs | 170 µs, 129 lecturas | 544 KB |
| C4, política con `STRING_SPLIT` | 233 µs | 153 µs, 129 lecturas | **0 KB** |
| C5, política escalar (1 artículo) | 110 µs | **25 µs, 4 lecturas** | 0 KB |
| D0, almacenes más política escalar (1 viaje) | 175 µs | 58 + 18 µs | 1.024 KB + 0 |
| D1, todo escalar (1 viaje) | 130 µs | 24 + 18 µs | 0 + 0 |

**Lectura:**
- Ni `MAX_GRANT_PERCENT` ni quitar el `DISTINCT` eliminan la concesión con `OPENJSON`: el motor reserva 1.024 KB como mínimo.
- `STRING_SPLIT` no pide concesión.
- La concesión en sí no cuesta CPU medible: C2 con 1.024 KB y C4 con 0 KB tienen las mismas lecturas y la misma CPU.
- **Lo caro de C0 es el recorrido del catálogo**, no la memoria.

## 3. ¿Explica la lectura previa los 3 ms de p95 de T-28?
**No.** Lo verificado:
- **Magnitud:** +40 a +60 µs de motor y unos ±0,03 ms de cliente por venta, antes de tomar la serie. Una cota generosa de su efecto en el p95 es de 0,1 ms, frente a los 3,2 ms observados.
- **Lugar:** la lectura ocurre en `PrepararAsync`, antes de la serie. No alarga la sección serializada, que es el cuello de botella con 6 cajeros: `LCK_M_U` es el 60 % del tiempo del motor.
- **Prueba decisiva:** `candx` (la política sin `OPENJSON`, de 36 a 40 µs y 0 KB) en P2, alternado con el candidato y la base:

| Corrida P2 (6 cajeros, 120 s) | Ventas/s | Mediana | p95 | p99 | CPU del motor por venta | CPU del cliente por venta |
|---|---|---|---|---|---|---|
| base r1 | 305,9 | 18,78 | **23,54** | 33,05 | 5,12 | — |
| candidato r1 | 282,5 | 19,26 | **28,66** | 49,45 | 4,97 | — |
| base r2 | 301,4 | 18,83 | 25,84 | 50,23 | 5,15 | — |
| candidato r2 | 269,8 | 21,29 | **29,23** | 51,66 | 5,60 | — |
| candidato r3 | 271,6 | 21,33 | **26,87** | 41,94 | 5,75 | 7,76 |
| base r3 | 306,7 | 18,83 | **23,44** | 39,34 | 5,21 | 7,15 |
| `candx` r1 | 305,7 | 18,84 | **23,44** | 40,46 | 5,24 | 7,13 |
| candidato r4 | 296,8 | 19,60 | **24,28** | 31,76 | 5,09 | 7,14 |
| `candx` r2 | 275,7 | 20,80 | **28,44** | 38,31 | 4,77 | 7,12 |
| base r4 | 303,4 | 19,03 | **23,63** | 39,83 | 5,22 | 7,21 |

- En T6 (T-28 completo): la base dio 24,0 / 23,7 / 24,5 y el candidato 27,2 / 22,1 / 28,5.
- **Juntando T6 y este banco:**
  - base: 6 de 7 corridas en el modo rápido (p95 ≤ 24,5 ms) y una intermedia (25,8);
  - código del candidato (`cand` y `candx`): 6 de 9 en el modo lento (≥ 26,9).
- `candx`, sin la lectura con `OPENJSON`, tiene una corrida en cada modo. **La diferencia no viene de la preparación.**

## 4. Hallazgo: la política recorre el catálogo (Alta)
**Evidencia (P4).** Plan de `PoliticasArticulos` tal como está, con cualquier tamaño de catálogo:
`Nested Loops > Sort (DISTINCT) > Table-valued function (OPENJSON) > Table Spool > … > Clustered Index Scan (cat.Articulo) > Clustered Index Scan / Seek (PoliticaNegativaCategoria) > Clustered Index Scan (conf.Parametros)`.

Con `FORCE ORDER`, el optimizador desarma el `CROSS APPLY`: calcula la vista entera (recorriendo `cat.Articulo`), la guarda en un spool y la filtra por cada artículo pedido.

| Catálogo | Actual, 1 art. | Actual, 20 art. | Sin pistas, 20 art. | `OPENJSON` + `TOP (1)` + `NO_PERFORMANCE_SPOOL`, 1 / 20 | **`STRING_SPLIT` + `TOP (1)`, 1 / 20** | Escalar, 1 |
|---|---|---|---|---|---|---|
| 1 | 62 µs, 4 lect. | 61 µs | 57 µs | — | 26 / 26 µs | 21 µs |
| 30 | 149 µs, 125 lect. | 256 µs, 163 lect. | 119 µs, 81 lect. | 49 / 101 µs | **26 / 90 µs, 0 KB** | 21 µs |
| 300 | 878 µs, 1.213 lect. | 1.447 µs, 1.251 lect. | 122 µs | — | **27 / 92 µs, 0 KB** | 23 µs |
| 3.000 | **8.344 a 8.597 µs, 12.147 lect.** | **13.478 a 13.999 µs, 12.337 lect.** | 123 a 125 µs | 47 / 104 µs | **27 / 95 µs, 0 KB** | 21 µs |

- **Sin pistas** (`DISTINCT` más `CROSS APPLY`): con 30 a 3.000 artículos da búsquedas con un `Sort` de 544 KB, aunque el backend ya vio un Hash Join con unos 60 artículos. **Es inestable.**
- **`OPENJSON` más `TOP (1)` sin la pista:** con 300 o más artículos pone un `Index Spool` (13 lecturas para 1 artículo y 241 para 20). Necesita `NO_PERFORMANCE_SPOOL`.
- **Verificado con la prueba del proyecto.** Agregué a `NegativosPoliticaPreparacionTests.R02_…` la aserción «la sentencia de la política no tiene un `Scan` de `[cat].[Articulo]`», solo en las copias.
  - **Falla en el candidato:** los operadores son `Sort, Table-valued function(OPENJSON_EXPLICIT), Clustered Index Scan([cat].[Articulo].[PK_Articulo]), …`.
  - **Pasa con la propuesta.**
- **Impacto (inferido):**
  - Con catálogos reales, de miles de artículos, cada documento que mueve inventario paga entre 8 y 14 ms de CPU de más. Es de 4 a 6 veces la CPU actual de toda la venta (5,2 ms), en un Express de 4 núcleos.
  - El p95 subiría al menos esos 8 a 14 ms, y más bajo carga.
  - En T-57 y N6-02 (200 artículos) suma unos 0,6 ms por venta, fuera de la serie. Puede ser parte del 1,053 de T-57 sin compras; no está medido en T-57.
  - **No estaba en `master`:** es de la rama de la preparación del 27-oct.

## 5. Ajuste propuesto (al backend; no cambia la letra firmada de R-02)
`src/GPOS.Core/Consultas/Inventario/ConsultasInventario.cs`, en `PoliticasArticulos`:
```sql
-- [ConsultaRegistrada(typeof(PoliticaArticuloFila), Parametros = "@articulos varchar(8000)")]
SELECT pn.ArticuloId, ISNULL(pn.Permite, CONVERT(bit, 0)) AS Permite, ISNULL(pn.Origen, 'E') AS Origen
  FROM STRING_SPLIT(@articulos, ',') a
 CROSS APPLY (SELECT TOP (1) p.ArticuloId, p.Permite, p.Origen
                FROM inv.PoliticaNegativa p WHERE p.ArticuloId = CONVERT(int, a.[value])) pn
 OPTION (NO_PERFORMANCE_SPOOL)
```
`src/GPOS.Core/Servicios/Modulos/Inventario/LibroInventario.cs:174`:
```csharp
var articulos = string.Join(",", movimientos.Select(m => m.ArticuloId).Distinct());
```
- El parámetro sigue siendo `Sql.Varchar(articulos, -1)`, como hoy, o `8000`. 20 renglones ocupan unos 220 caracteres y 500 renglones unos 5.500. Los `int` se formatean sin separadores de miles: `string.Join` usa `ToString()` de `int`, que no los agrega.
- `TOP (1)` impide que el motor desarme el `APPLY` en una unión. La vista tiene una fila por artículo (`cat.Articulo` por PK, con `LEFT JOIN` a la categoría y a los parámetros), así que `TOP (1)` no cambia el resultado. Los repetidos ya los quita el `Distinct()` del cliente.
- `NO_PERFORMANCE_SPOOL` es la red contra el `Index Spool` que se vio con `OPENJSON` y 300 artículos.

**Medido con `candx`:**
- **P2:** la sentencia cuesta de 36 a 40 µs de CPU, con 4 lecturas y **0 KB**, frente a 77 a 87 µs y 1.024 KB.
- **P4:** la misma forma sin la pista da 26 a 27 µs con 1 artículo y 89 a 96 µs con 20, de 1 a 3.000 artículos de catálogo, con el mismo plan (`TVF > Top > Nested Loops > Clustered Index Seek`).

**Verificación funcional en `candx`** (Release, `.\SQLEXPRESS`):
- Pasaron:
  - `NegativosNucleoTests`, `LoteDocumentosTests`, `NegativosPoliticaPreparacionTests` (con la aserción nueva y la marca cambiada a `… p.ArticuloId = CONVERT(int, a.[value])`), `NumeracionB7jExistenciasTests`, `NumeracionB7fTests`, `NumeracionBloqueosTests`, `ContratoConsultasTests` (CP-169 y CP-170), `ConsultasVarcharTests` y `ConsultasVarcharSecuencialTests`;
  - **90 correctas y 2 omitidas.**
- Las 18 de `Mvp.TransferenciasTramo1Tests` fallan **por el entorno**: «GPOS_SYSDATA no tiene cuentas de usuario … (DL-02)», al arrancar la API de prueba en 1 ms. No tienen relación con el cambio. Hay que correrlas en la suite oficial con su configuración.

**Cambios en las pruebas que acompañan al ajuste:**
- En `tests/GPOS.Tests/ModeloNg/NegativosPoliticaPreparacionTests.cs`:
  - `MarcaPolitica` pasa a `"inv.PoliticaNegativa p WHERE p.ArticuloId = CONVERT(int, a.[value])"`;
  - se agrega `Assert.DoesNotContain(<operadores de la política>, o => o.Contains("[cat].[Articulo]") && o.Contains("Scan"))`;
  - conviene que la prueba cree al menos 30 artículos antes de compilar el plan.
- `JsonPorFuera` sigue valiendo: `STRING_SPLIT` también es una `Table-valued function`, y queda por fuera.

**Alternativas:**
- **Mantener `OPENJSON` con `TOP (1)` y `NO_PERFORMANCE_SPOOL` (TNS).** Medida: de 47 a 49 µs con 1 artículo y de 101 a 104 µs con 20, estable, pero con 1.024 KB. Es la opción si el equipo prefiere no introducir `STRING_SPLIT` en el proyecto, que hoy no lo usa.
- **Texto escalar para documentos de 1 artículo (D0 o D1).** Es el más barato (de 18 a 25 µs), pero agrega un segundo texto y un segundo plan, por un ahorro de unos 15 µs fuera de la serie. **Descartado** por simplicidad.
- **Quitar la pista y dejar `DISTINCT` más `CROSS APPLY`.** Inestable: el backend vio un Hash Join con unos 60 artículos.
- **`MAX_GRANT_PERCENT`.** No baja de 544 KB y no corrige el recorrido.

**Requisito (inferido):** `STRING_SPLIT` exige nivel de compatibilidad 130 o mayor. Las bases nacen en SQL Server 2019 o 2025 (150 o 170), y el código no fija el nivel. Conviene que `GPOS.Migracion verificar` lo compruebe.

**Costo:** unas 0,1 semanas-persona del backend más una corrida de N6-02 y de T-57. Sin costo de infraestructura.

## 6. Lo que sí queda abierto en T-28 (no es de R-02)
**Firma del modo lento** (candidato r1 a r3 y `candx` r2, frente a la base):
- Todas las sentencias del motor suben de +8 a +10 % de CPU por ejecución con el mismo plan y las mismas lecturas. Ejemplos: `INSERT doc.Documento` 270 → 296 µs; emisión 1.192 → 1.293 µs.
- Todos los viajes del cliente suben de +25 a +40 %. Por ejemplo, las lecturas de EF de `cat.Articulo` pasan de 226 a 331 µs.
- `PAGELATCH_SH` y `PAGELATCH_EX` suben de unos 5 s a entre 6 y 10 s por tramo.
- `LCK_M_U` por venta sube de 3,2 a 3,4 ms.
- La CPU del cliente por venta es la misma en el modo rápido (7,13 frente a 7,21 ms). En el lento llega a 7,76 ms.
- Con un hilo (P1) no hay diferencia sistemática.

**Hipótesis (inferidas, no medidas):** contención de pestillos de página en inserciones de llave creciente, o del planificador del Express de 4 núcleos con los hilos del cliente en el mismo equipo. Las dos dependen del orden de llegada y explicarían la bimodalidad.

**Cómo atacarlo:**
1. **QA:** aplicar la regla 7.3 de T6 (5 corridas por lado), informar cuántas corridas caen en cada modo y usar la mediana de las 5. Con 3 corridas, una sola en el modo lento mueve la mediana.
2. **Backend o rendimiento, en el modo lento:** muestrear `sys.dm_os_waiting_tasks.resource_description` de los `PAGELATCH_*` para saber qué página y qué índice, y `dotnet-counters` del proceso de prueba (cola del grupo de hilos, contención y GC).
   - Comparar con la base las inserciones de llave creciente que agrega el candidato: `inv.Movimiento`, `doc.Autorizacion`, `audit.Bitacora`, `ventas.VentaLinea` (`IX_VentaLinea_LoteId`) y las secuencias.

## 7. Riesgos
- **Alto, si no se corrige el hallazgo 4:** la regresión es lineal con el catálogo y se verá en el primer cliente con un catálogo real. Corregirlo antes de unir `prep27` y antes de concluir T6.
- **Bajo, en la corrección del ajuste:**
  - misma vista, misma lectura única por documento y mismo lugar (antes de la serie);
  - no hay bloqueos nuevos y el orden único no cambia;
  - no cambia el esquema.
- El banco usa un catálogo de 1 artículo en P1 y P2, como T-28. Las cifras de P4 son de la sentencia suelta en una base con poca historia; con historia, `cat.Articulo` no cambia de tamaño por las ventas.

## 8. Artefactos temporales (no confirmados)
- **Banco:** `C:\Users\lfmen\AppData\Local\Temp\claude\C--Users-lfmen-source-repos-Solucion-GPOS-NG-GPOS-NG\f0ef3310-0500-40cc-9e4f-8b69aa2f95ef\scratchpad\PerfilR02Tests.cs`.
- **Copias compiladas:** `...\scratchpad\w2\base`, `w2\cand` (la prueba del plan con la aserción nueva) y `w2\candx` (el ajuste de la sección 5).
- **Registros:** `...\scratchpad\r02\*.log`. Los usados: `base-p1-{1,2}`, `cand-p1-{1,2}`, `base-p2-{1..4}`, `cand-p2-{1..4}`, `candx-p2-{1,2}`, `cand-p3-1`, `cand-p4-{1,2}`.
- **Bases:** no queda ninguna `GPOS_TEST_*` en `.\SQLEXPRESS`. Solo están las bases de desarrollo que ya existían, sin tocar.

## 9. Decisión candidata a ADR
Ninguna. El ajuste es de forma de la consulta: cumple la precisión R-02 de ADR-118 tal como está firmada y no cambia ninguna regla.

### Cierre
- Estado: Completado
- Artefactos: `traspasos/B/2026-10-17-perfil-r02-un-renglon.md`
- Supuestos:
  - Nivel de compatibilidad 130 o mayor en las bases de empresa (inferido; el código no lo fija).
  - Las cifras de P4 de 3.000 artículos representan un catálogo real.
  - Las 18 fallas de `Mvp.TransferenciasTramo1Tests` son del entorno, no del cambio.
- Decisiones candidatas a ADR: Ninguna
- Entregas a otros agentes:
  - desarrollador-backend → el ajuste de la sección 5 (`PoliticasArticulos` con `STRING_SPLIT`, `TOP (1)` y `NO_PERFORMANCE_SPOOL`; `LibroInventario.cs:174`; marca y aserción de `NegativosPoliticaPreparacionTests`);
  - QA → T-28 con 5 corridas por lado, informando los modos, y N6-02 y T-57 tras el ajuste;
  - backend o rendimiento → diagnóstico del modo lento (sección 6).
- Próximo paso recomendado: aplicar el ajuste de la sección 5 en `b/prep-27oct` antes de cerrar T6; después, T-28 con 5 corridas por lado.
