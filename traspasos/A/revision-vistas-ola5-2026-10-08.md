# Revisión de las vistas de ventas e inventario de la ola 5 (entrega de B)

**Autor:** arquitecto-datos, equipo A · **Fecha:** 2026-10-08 · **Tipo:** revisión técnica (solo lectura; no se compiló, no se ejecutó SQL, no se tocó ningún árbol de trabajo)
**Objeto:** `origin/b/ola5` `b745af9`: `database/ola5/rpt-vistas-ventas-inventario.sql`, `rpt-vistas-negativos-tras-t1.sql`, `contrato-vistas.v1.json` y `LEEME.md`. Aviso `GPOS-NG-Equipos/avisos/B-a-A/2026-10-08-vistas-ventas-inventario.md`.
**Base de A:** `origin/feature/modelo-ng` `e300320`. Esquema citado como **[ESQ]** = `database/empresa/gpos-empresa-20261008220258_Ola4ExigirVendedor.sql` en `e300320`. El script **[V]** = `rpt-vistas-ventas-inventario.sql` en `b745af9`.

## Resumen

| Tema | Resultado |
|---|---|
| **Veredicto** | **Aprobado con observaciones.** No hay hallazgos Críticos ni Altos. Hay 4 Medios que se corrigen al integrar (2 en el script de B y 2 en la migración de A) y 7 Bajos |
| Esquema contra `e300320` | Correcto. Entre `0bb596c` y `e300320` solo se agrega `conf.Parametros.ExigirVendedor` ([ESQ]:10390), y ninguna vista usa `SELECT *`. Ninguna vista usa columnas posteriores a `Ola4b`: verifiqué las migraciones de `Ola4bImplantacion` a `Ola4ExigirVendedor`. Comprobé 43 columnas por muestreo y no falta ninguna. El archivo de esquema que cita B cambió de nombre (`…Ola4PropinaLegal.sql` pasó a `…Ola4ExigirVendedor.sql`) |
| Permisos | El diseño de B es correcto: dueño `dbo`, ninguna concesión en el script, `rptc` nace sin `GRANT` y `gpos_reportes` ya tiene `SELECT ON SCHEMA::rpt` ([ESQ]:446). **H-01:** la comprobación de dueño solo cubre `rpt` y `rptc`, pero ADR-109, cláusula 3, exige que todos los esquemas leídos sean de `dbo` |
| Rendimiento | Con RCSI ninguna vista bloquea al POS, pero sí compite por CPU, E/S y memoria. El riesgo está en `rpt.VentaLinea` y `rptc.VentaLinea` con períodos largos (**H-04**). Las demás vistas leen tablas pequeñas o recorren `inv.Existencia`, con unas 150.000 filas (inferido) |
| Idempotencia | Correcta: `CREATE OR ALTER`, esquemas condicionales y concesiones intactas al alterar. **H-02:** dentro del script idempotente de EF, cada vista debe ir en un `EXEC(N'…')`. La opción de «lotes separados» no funciona |
| Falla cerrada | Correcta para la ejecución manual. En la migración, `THROW 51399` reemplaza a `RAISERROR` con `NOEXEC`, y la precondición de `Ola4b` sobra |
| VW-01 a VW-08 | Ninguna requiere firma nueva (sección 4) |
| Para firma | **Nada hoy.** Hay 2 decisiones que pasarían a firma solo si una medición falla (sección 6) |

| VW | Recomendación (corta) | Quién decide |
|---|---|---|
| VW-01 | Se mantiene `rpt.CierreCaja`, **sin** la columna `Detalle` (H-05) | A, técnica |
| VW-02 | Las vistas `rpt.Kardex` y `rptc.Kardex` entran en la misma migración de la ola 5, porque una vista no cuesta escritura. El índice I-02 va en una migración aparte, después de medir T1 y en forma acumulada contra la línea base de la ola 4. Recomiendo la variante I-02b (sección 4) | A, técnica (DD-08 ya está firmado con la puerta V-D5) |
| VW-03 | `rpt.Recibo` entra ahora, junto con `rpt.ReciboPago`; el resto de CxC queda para su tanda | A, técnica; se informa al propietario |
| VW-04 | Se usa el costo de la línea. Ya es igual al del kárdex de la venta y está en moneda base. Cuando lleguen las recetas, la línea debe guardar el costo sumado de sus ingredientes; no se une con `inv.Movimiento` | A, técnica; requisito para el diseño de recetas |
| VW-05 | El contrato va en `src/GPOS.Contracts/Reportes/` como recurso incrustado. Lo validan pruebas, no la compilación. Después de unir, todo cambio va en una migración nueva | A, técnica |
| VW-06 | Se confirma: SHA-256 de los bytes UTF-8 sin BOM, con LF. Hay que agregar `eol=lf` en `.gitattributes` para el archivo | A, técnica |
| VW-07 | La búsqueda del número **dentro de la consulta de facturas** pasa a la API de reportes sobre la vista. La búsqueda E11 y la resolución por número de las pantallas operativas se quedan en la principal | B (arquitecto-software) y A |
| VW-08 | **B diseña y escribe `rptsis`** en archivos nuevos. **A lo integra** en `EsquemaSistema` y revisa las tablas de `GPOS_SYSDATA` | Distribución técnica, dentro de B10 |

## 1. Contexto y modelo de tenencia

- Cada empresa tiene su base. Las vistas van en la base de la empresa y en la del nodo, con el mismo esquema (ADR-53; ADR-109, cláusula 9). No toman datos de otra base: no usan nombres de tres partes ni sinónimos (verificado en [V]).
- La lectura usa RCSI. Lo activa `Aprovisionamiento.cs:282-297` (en `e300320`), y el diseño de negativos lo da por activo. Por eso las vistas no piden bloqueos compartidos.
- El esquema cambia por migraciones de EF con `migrationBuilder.Sql`, y `ScriptEmpresa.cs` genera el script idempotente. En [ESQ], cada vista ya va dentro de `IF NOT EXISTS (… MigrationId …) BEGIN EXEC(N'CREATE OR ALTER VIEW …') END` (por ejemplo, [ESQ]:9176-9180).

## 2. Revisión

### 2.1 Esquema real (`e300320`)

- **Diferencia con la base que usó B:** solo `ALTER TABLE conf.Parametros ADD ExigirVendedor` ([ESQ]:10390). La única vista que lee `conf.Parametros` es `rpt.NegativoPorRegularizar`, que nombra la columna `PermiteExistenciaNegativa`. No le afecta.
- **Migraciones posteriores a `Ola4b`:** solo agregan columnas a `conf.Parametros`, restricciones e índices, y cambian las vistas fiscales 607 y 608 (listado de [ESQ] desde la línea 8271). Exigir `Ola4b` como mínimo es suficiente para el script manual.
- **Columnas:** comprobé 43 columnas contra los `CREATE TABLE` y `ALTER TABLE ADD` de [ESQ], entre ellas `cxc.ReciboPago.MontoMoneda`, `inv.CierrePeriodoReemplazado.ReemplazadaEn`, `doc.TipoDocumento.Familia`, `cat.FormaPago.ClaseFiscal607`, `caja.Jornada.FechaOperacion` y `inv.Lote.FechaVencimiento`. No falta ninguna. Coincide con lo que informa B.
- **Tipos:** los montos son `decimal(19,2)`, los costos `decimal(19,6)` y no hay `nvarchar`. `ventas.VentaLinea.UnidadId` tiene FK a `cat.ArticuloUnidad` ([ESQ]:3702-3740) y no a `cat.Unidad`. Por eso el `JOIN cat.Unidad` de `rpt.VentaLinea` nunca se elimina del plan. Es barato: la tabla es pequeña.

### 2.2 Permisos

- El script no concede ni deniega nada. Es correcto: los permisos van en la migración de A, al final y después de crear las vistas ([V] y LEEME 5).
- Al crearse, las vistas `rpt` nuevas quedan legibles para `gpos_reportes` por la concesión de esquema ([ESQ]:446). Hoy el rol no tiene miembros, así que no se expone nada. `rptc` no tiene concesión: aunque falte el `DENY`, nadie fuera de `dbo` la lee.
- `ALTER VIEW` conserva las concesiones de la vista: al volver a ejecutar el script no se pierde ningún `GRANT`.
- **H-01 (Media).** [V]:61-68 solo comprueba que `rpt` y `rptc` (y sus objetos) sean de `dbo`. El encadenamiento de propiedad también se corta si **la tabla leída** está en un esquema de otro dueño. Todos los esquemas los crea EF sin `AUTHORIZATION` ([ESQ]:3-162), así que su dueño es quien ejecutó la migración, y ese es el caso HD-01. ADR-109, cláusula 3, dice: «todos los esquemas tienen dueño `dbo`, y la migración falla cerrada si no». **Corrección (en la migración de A):** comprobar todos los esquemas de usuario (`sys.schemas` con `schema_id` entre 5 y 16383) y los objetos que dependen de ellos. El síntoma sin la corrección sería un error 229 al leer, no una fuga de datos.
- **Observación para seguridad (sin severidad de datos):** con `DEFAULT_SCHEMA = rpt`, el SQL del diseñador (`gpos_rpt`) ve, de **todas** las sucursales:
  - las identificaciones de clientes (`rpt.CatCliente.Identificacion`, `rpt.ConsultaFactura.IdentificacionCliente`);
  - las diferencias de efectivo de cada cajero (`rpt.CierreCaja`, `rpt.CierreCajaConteo`).

  ADR-109 reserva `rptc` para «costos y bitácora». Decidir si estas columnas van en `rptc` es tarea del arquitecto-seguridad. Si se mueven, conviene hacerlo **antes** de publicar la versión 1.0 del contrato.

### 2.3 Rendimiento (sin índices nuevos)

| Vista | Tablas calientes del POS | Lectura probable | Riesgo frente a la meta 1 de T-57 (p95 de la venta ≤ 52 ms, al límite) |
|---|---|---|---|
| `rpt.VentaDocumento`, `rpt.ConsultaFactura` | `doc.Documento`, `ventas.Venta`, `fiscal.Comprobante` | Búsqueda en `IX_Documento_TipoFecha` ([ESQ]:4214) por tipo y rango, y después búsquedas por llave primaria. Las uniones `LEFT` a llaves únicas (`PK_Comprobante (DocumentoId, Rol)` con `Rol = 'O'`, `Jornada`, `Empleado`) se eliminan cuando la consulta no usa sus columnas | Bajo para un día o un mes de una sucursal |
| `rpt.VentaLinea`, `rptc.VentaLinea` | Las mismas, más `ventas.VentaLinea` | Las filas de `IX_Documento_TipoFecha` no salen ordenadas por `Id`. Con un período largo, el optimizador puede elegir una unión hash que **recorra `ventas.VentaLinea` completa**, la tabla más grande de la venta | **Medio (H-04).** No hay bloqueo, pero compite por E/S, búfer y CPU |
| `rpt.ExistenciaActual`, `rptc.ExistenciaActual`, `rpt.ConciliacionLoteAlmacen` | `inv.Existencia` (se escribe en cada línea vendida) | Recorrido de unas 150.000 filas (inferido); el filtro por almacén no puede buscar en `PK_Existencia (ArticuloId, AlmacenId)` | Bajo: decenas de ms (inferido) |
| `rpt.NegativoPorRegularizar`, `rpt.LoteNegativo` | `inv.Existencia`, `inv.ExistenciaLote` | Índice filtrado `IX_Existencia_Negativas` ([ESQ]:4262) y búsqueda de las demás columnas por llave, solo para las filas negativas | Bajo |
| `rpt.CierreCaja`, `rpt.CierreCajaConteo`, `rpt.ReciboPago`, `rpt.Cotizacion`, `rptc.ExistenciaCierre`, catálogos | No calientes | Recorridos de tablas pequeñas o medianas | Bajo |

**H-04 (Media): `rpt.VentaLinea` con períodos largos.**
- **Ya mitigado en el ejecutor de B:**
  - `SET QUERY_GOVERNOR_COST_LIMIT` y `SET LOCK_TIMEOUT` en cada conexión (`src/GPOS.Reportes/Ejecucion/PreparadorSesion.cs`, `b745af9`);
  - `MAXDOP 2`, `MAX_GRANT_PERCENT = 10` y 30 s por consulta (ADR-109, cláusulas 12 y 13).
- **Matiz:** hoy esos reportes ya corren en la principal sobre las mismas tablas. La vista no crea carga nueva; la cambia de proceso.
- **Conflicto de criterios:** CA-O5-10 tolera que un reporte de 25 s en paralelo suba el p95 de la venta hasta un 10 %, y la meta 1 ya está al límite. Un +10 % sobre ~50 ms deja la venta por encima de 52 ms.
- **Qué hacer:**
  1. Medir CA-O5-10 en la PC A al unir la ola 5, con T-28, el reporte 25 de un mes y el reporte 5 de un año.
  2. Si la venta pasa de 52 ms, primero bajar `QUERY_GOVERNOR_COST_LIMIT` y la concurrencia por base. Esos valores los ajusta QA sin firma (cláusula 13).

### 2.4 Idempotencia y mecanismo de A

- **H-02 (Media).** LEEME 4.1 ofrece «lotes separados» o `EXEC(N'…')`. En el script idempotente que genera EF, cada operación va dentro de `IF NOT EXISTS (…) BEGIN … END`, y `CREATE VIEW` debe ser la primera sentencia de su lote. **Solo funciona `EXEC(N'CREATE OR ALTER VIEW …')`**, el patrón de las olas 3 y 4 ([ESQ]:9180).
- **Esquema `rptc`:** se crea con `migrationBuilder.Sql("IF SCHEMA_ID(N'rptc') IS NULL EXEC(N'CREATE SCHEMA rptc AUTHORIZATION dbo')")`. No sirve `EnsureSchema`, que genera `CREATE SCHEMA` sin `AUTHORIZATION` ([ESQ]:154).
- **Contrato inmutable después de unir:** cuando la migración `Ola5VistasVentasInventario` esté en `feature/modelo-ng` y se haya aplicado en cualquier base, aunque sea de desarrollo, su texto ya no se edita. Un cambio del JSON va en una migración nueva que hace `CREATE OR ALTER VIEW rpt.VersionContrato` con la huella nueva. B dice en LEEME 9 que corregirá la huella «sin subir la versión»; eso solo vale **antes** de unir.

### 2.5 Falla cerrada

- El script manual es correcto: `RAISERROR` de severidad 16 con `SET NOEXEC ON`, y `SET NOEXEC OFF` al final.
- **H-09 (Baja):** el comentario de [V]:21 dice «error 51399», pero `RAISERROR(N'51399 …', 16, 1)` emite el 50000. En la migración se usa `THROW 51399, …` ([ESQ]:6194), que además deshace la migración.
- **Dentro de la migración, la precondición de `Ola4b` sobra:** EF garantiza el orden. Se conserva solo la comprobación de dueño ampliada (H-01).

## 3. Hallazgos

| ID | Sev. | Hallazgo | Evidencia | Corrección | Quién |
|---|---|---|---|---|---|
| H-01 | Media | La comprobación de dueño no cubre los esquemas de las tablas leídas | [V]:61-68; [ESQ]:3-162; ADR-109, cl. 3 | Ampliarla a todos los esquemas de usuario, con `THROW 51399` | A (migración) |
| H-02 | Media | La opción «lotes separados» no funciona en el script idempotente | [ESQ]:9176-9180 | `EXEC(N'…')` por vista; `CREATE SCHEMA rptc AUTHORIZATION dbo` por SQL | A (migración) |
| H-03 | Media | `rpt.VentaDocumento` incluye `CHD` (cheque devuelto, `Documentos.cs:43`) con `Signo = +1`. Los reportes 1 a 4, 24 y 26 suman el neto por documento: un cheque devuelto contaría como venta si la consulta no filtra el tipo | [V]:130; LEEME 6 | Sacar `CHD` de la vista (pasa a la tanda de CxC) o agregar la columna `CuentaComoVenta`. Recomiendo sacarlo; que lo confirme el especialista contable | B (script) |
| H-04 | Media | `rpt.VentaLinea` con períodos largos puede recorrer `ventas.VentaLinea`. CA-O5-10 (+10 %) no cabe en la meta 1 | 2.3 | Medir al unir; si falla, ajustar el límite de costo y la concurrencia | A (medición), B (valores) |
| H-05 | Baja | `rpt.CierreCaja.Detalle` es un JSON `varchar(max)`. El diseñador no puede leerlo (ADR-109, cl. 13, rechaza `OPENJSON`) y obliga a leer datos LOB | [V]:299; [ESQ]:3439 | Quitarlo de `rpt`; si la impresión del Z lo necesita, va en `imp` | B |
| H-06 | Baja | `PermiteNegativa` de `inv.Existencia` e `inv.ExistenciaLote` es una marca interna de la fila, no la política (E-4 del diseño de negativos). Expuesta en el contrato confunde | [V]:447, 494 y 606 | Quitarla antes de publicar. La política efectiva entra después de T1 como columna aditiva (versión 1.1) | B |
| H-07 | Baja | `rpt.NegativoPorRegularizar` antes de T1 usa `JOIN conf.Parametros` interno: sin la fila 1, no lista nada, y falla abierta | [V]:582 | `LEFT JOIN` con `ISNULL(…, 0)`, como `inv.PoliticaNegativa` del diseño | B |
| H-08 | Baja | La segunda rama de `rpt.ConciliacionLoteAlmacen` nunca devuelve filas mientras la FK `FK_ExistenciaLote_Existencia` sea de confianza | [V]:650; [ESQ]:2914 | Dejarla con un comentario (defensa si la FK se deshabilita) o quitarla. Recomiendo dejarla | B |
| H-09 | Baja | Número de error inexacto en el script manual | [V]:21 y 66 | `THROW 51399` en la migración | A |
| H-10 | Baja | La huella depende de los finales de línea: el repositorio tiene `* text=auto` (`.gitattributes`) y `core.autocrlf=true` en la PC A. En Windows el archivo sale con CRLF | `.gitattributes` en `e300320` | `src/GPOS.Contracts/Reportes/*.json text eol=lf` y normalizar también en el código | A |
| H-11 | Baja | `rptc.VentaLinea.Costo` y `Utilidad` están en moneda base, al lado de `Importe` en la moneda del documento. El nombre es ambiguo | [V]:188-228 | Renombrar a `CostoBase` y `UtilidadBase` antes de publicar | B |

**Observación fuera de mi alcance (inferida, por verificar):** la venta no asigna `FactorUnidad`. Se queda en 1 (`src/GPOS.Core/Dominio/Ventas/Ventas.cs:84`), aunque `UnidadId` tome la unidad que pide el documento (`VentasNg.cs:55-62`; `DocumentosComercialesService.Ventas.cs:131`). El kárdex de la venta toma la cantidad tal cual (`VentasNg.cs:109`), mientras que la compra la convierte a la unidad base (`ComprasNg.cs:62`). Si se vende en una unidad con factor distinto de 1, la existencia y el costo quedan mal, en las tablas y en las vistas. Lo verifican el desarrollador-backend y QA.

## 4. Respuestas VW-01 a VW-08

**VW-01. `rpt.CierreCaja` (L-04): se mantiene.**
- El reporte 7 necesita el encabezado: tipo X o Z, anulado, cajero, supervisor, totales y efectivo.
- Va sin `Detalle` (H-05).
- Solo el Z que no está anulado cuenta para el cuadre (índice `UX_Cierre_ZPorJornada`, [ESQ]:3926). La consulta registrada debe filtrar `Tipo = 'Z' AND Anulado = 0`.
- Decisión técnica de A.

**VW-02. Kárdex e índice I-02.**

*Recomendación:*
1. B entrega ya `rpt.Kardex` y `rptc.Kardex` (L-18), y también `rpt.AjusteInventario` y `rptc.AjusteInventario` (A-06), en archivos nuevos. Entran en la **misma** migración de la ola 5.
   - Crear una vista no escribe ni cambia el plan de la venta.
   - Mientras no exista I-02, las consultas registradas de los reportes 20 y 17 (a una fecha) **exigen artículo o categoría** y usan `IX_Movimiento_ArticuloFecha`, que se amplió en `Ola4IndiceKardex` ([ESQ]:10147).
   - Para la categoría, la consulta pasa por la lista de artículos y busca uno por uno.
   - El límite de costo rechaza el resto.
2. **I-02 va en una migración aparte (`Ola5IndiceKardexFecha`)**, con su propio `Down`, y entra después de cumplir **tres puertas en orden**:
   1. la medición del 14-oct que cierra el rendimiento de la ola 4 (F-R1);
   2. T1 de ADR-118, que tiene su propio presupuesto de +5 % (cláusula 9);
   3. la medición de I-02 **acumulada** contra la línea base de la ola 4 (`carga-ola4-2026-10-08`), no contra la de T1. Si no, los dos +5 % se suman y quedan en un +10 %.

   La toma A en la PC A al unir la ola 5 (S-14), en unos 0,05 sp de máquina.
3. **Variante I-02b (recomendada, a medir):** en lugar de agregar un séptimo índice a `inv.Movimiento`, **sustituir** `IX_Movimiento_AlmacenId_SucursalId` ([ESQ]:4382) por `(AlmacenId, SucursalId, Fecha) INCLUDE (ArticuloId, Cantidad, CostoUnitario, Clase)`.
   - Hoy ese índice solo sostiene la FK compuesta hacia `org.Almacen`. Las bajas de almacén son raras.
   - El índice nuevo sigue sirviendo a la FK porque empieza con sus columnas. EF no crea otro índice para la FK cuando uno existente empieza con sus columnas (inferido; se verifica en el *snapshot* al generar).
   - **Costo de escritura:** las mismas filas de índice por línea vendida, unos 3 bytes más por la llave y 4 columnas incluidas. Frente a I-02 tal como está diseñado, se ahorra una fila de índice por movimiento, es decir, todo el aumento de filas de índice que I-02 agregaría.
   - **Lectura:** el kárdex del período sin artículo busca por almacén (5 almacenes en la empresa grande de referencia, inferido): son 5 búsquedas por rango en lugar de un recorrido.
   - *Descartada:* I-02 `(Fecha, SucursalId)` tal como está diseñado. Agrega una fila de índice por movimiento sobre la tabla más escrita, justo cuando la meta 1 está al límite.
   - *Descartada:* el *columnstore* en todas las bases. Por DD-08 queda solo para la central grande.
   - **Firma:** no hace falta. DD-08 ya aprobó «I-02, kárdex por fecha» con la puerta V-D5, y la variante conserva su función. Si **ninguna** variante pasa la puerta y los reportes 17 y 20 quedan limitados a artículo o categoría, eso sí cambia el alcance y va al propietario.

**VW-03. `rpt.Recibo` (L-10): entra ahora, con ventas.**
- `rpt.ReciboPago` ya está en esta tanda (reporte 12). Sin su encabezado (concepto, anticipo y retenciones), el reporte 11 y el cuadre del cobro en caja quedan cojos.
- Es una vista sobre `cxc.Recibo`, una tabla que no es caliente (índices en [ESQ]:4502-4534). Cuesta unas 0,05 sp (inferido).
- Así se evita subir el contrato a 1.1 dentro de unas semanas.
- El resto de CxC (cuentas, aplicaciones, antigüedad) sigue en su tanda, como pide la prioridad del propietario.
- Es una decisión técnica de alcance. Se **informa** al propietario en el próximo aviso; no se pide firma.

**VW-04. Costo de la línea: se usa el de la línea y está siempre en moneda base.**
- **Verificado:**
  - la venta guarda `VentaLinea.CostoUnitario = round6(l.Costo)` (`src/GPOS.Core/Servicios/Nucleo/VentasNg.cs:61`);
  - el kárdex de la venta se escribe con la misma `l.Costo` y la cantidad absoluta de la línea (`VentasNg.cs:99-109`);
  - `l.Costo` es `CostoEfectivo` (`DocumentosComercialesService.Ventas.cs:134` y `:185`; `PosService.cs:501`), que sale de `CostoPromedio` o del último costo de compra (`ReferenciasNg.cs:15`);
  - el promedio está en moneda base por diseño de la ola 4 (`docs/datos/2026-10-06-ola4-modelo-datos.md:89` y `:324`).
- **Inferido:** que el último costo de compra también esté en moneda base. Lo confirma una prueba de V-D7 con una venta en US$.
- **Conclusión:** hoy el costo de la línea y el del kárdex coinciden. `Utilidad = ImporteBase − Costo` es coherente, y conviene renombrar las columnas (H-11).
- *Descartada:* unir con `inv.Movimiento` por documento y línea. `IX_Movimiento_Documento` ([ESQ]:4398) no incluye `Linea` ni `CostoUnitario`, así que la unión obligaría a buscar cada fila en la tabla más caliente o a ensanchar ese índice. Ensancharlo es costo de escritura que T-57 no tiene.
- **Recetas e ingredientes (ADR-112, punto 8; no hay nada construido en `e300320`):** queda como **requisito para el diseño de recetas**. La línea del plato guarda en `CostoUnitario` la suma del costo de sus ingredientes por unidad vendida, en la misma transacción que escribe sus movimientos. Así `rptc.VentaLinea` no cambia y el contrato tampoco.
- Decisión técnica de A, que se entrega al diseñador de recetas.

**VW-05. Dónde vive el contrato y quién lo valida.**
- **Ubicación:** `src/GPOS.Contracts/Reportes/contrato-vistas.v1.json`, como recurso incrustado, según [DIS] 8.1. `GPOS.Reportes` ya referencia `GPOS.Contracts` (`src/GPOS.Reportes/GPOS.Reportes.csproj`, `b745af9`), y las pruebas de A también lo alcanzan. `database/ola5/` desaparece al unir.
- **Validación, sin regenerarlo al compilar.** El código generado ocultaría los cambios y la migración ya es inmutable. Tres pruebas:
  1. **Sin base (A, `tests/GPOS.Tests`):** el SHA-256 del JSON incrustado es igual a la huella literal que lleva la migración vigente.
  2. **Con base (A al unir; después, B en `GPOS.Reportes.Tests`):** V-D7, `GetColumnSchema` de cada vista contra el JSON.
  3. **En ejecución (B):** al arrancar y por empresa, la API compara `rpt.VersionContrato` (`Version`, `VersionMinima` y `Huella`) con su recurso, y responde 503 si no le alcanza (ADR-109, cl. 11).
- **Dueños:** B es el autor del contrato. A es el dueño de la migración que lo materializa.

**VW-06. Huella: se confirma.**
- La huella es el SHA-256 de los bytes UTF-8 **sin BOM**, con finales LF y el salto de línea final tal como está.
- **Verificado:** el archivo de `b745af9` no tiene BOM ni CR, y su SHA-256 es `F8EEBFA3…7FD7C98`, igual al de `rpt.VersionContrato`.
- Hay que agregar `eol=lf` para el archivo (H-10).
- *Descartada:* la forma canónica JCS (RFC 8785). Exige una biblioteca de canonización que .NET no trae y no agrega nada: la huella identifica el archivo publicado, no su semántica. Reformatear el archivo cambia la huella, y eso es aceptable.

**VW-07. Búsqueda tolerante por número.**
- ADR-109, cláusula 1, lleva la **consulta de facturas** a la API de reportes, y CA-O5-8 exige que la principal no abra conexiones para ella. Por eso su búsqueda por número va en la API de reportes, como consulta registrada sobre `rpt.ConsultaFactura`:
  - número exacto con `UQ_Documento_Numero`;
  - terminación con `NumeroInv LIKE @inv + '%'` sobre `IX_Documento_NumeroInv` ([ESQ]:4222).
- Las reglas puras de normalización y variantes (`ReglasNumeracion`) pasan a `GPOS.Comun`. Para eso deben depender solo de .NET; si no, se duplican las reglas con una prueba de igualdad.
- **Se quedan en la principal:** E11 (`BusquedaNumero.BuscarAsync`, 24 tipos con permiso por tipo) y `ResolverAsync`, que usan las pantallas operativas, como la devolución POS (`src/GPOS.Core/Infraestructura/Numeracion/BusquedaNumero.cs`).
- Lo cierra el arquitecto-software de B; A revisa.

**VW-08. `rptsis`: B lo diseña y lo escribe, A lo integra.**
- B escribe `rptsis` en archivos nuevos, igual que esta entrega: tiene el diseño ([DIS] L-24 y siguientes, y la lista del LEEME 7), es su único consumidor y es la ruta crítica para que su API arranque.
- A lo integra en `EsquemaSistema.ActualizarAsync` (`src/GPOS.Core/Data/Sistema/EsquemaSistema.cs:11`) y revisa contra las tablas de `GPOS_SYSDATA`, que son de A.
- **Condiciones técnicas:**
  - `EsquemaSistema` ejecuta un solo lote, así que cada vista va en `EXEC(N'CREATE OR ALTER VIEW …')`.
  - Las tablas heredadas de `GPOS_SYSDATA` son `nvarchar` (`EsquemaSistema.cs:12-33`): el contrato de `rptsis` declara esos tipos tal cual o los convierte de forma explícita.
  - El rol `gpos_rpt_sis` y el inicio de sesión de la cuenta virtual los crea `GPOS.Migracion` (ADR-109, cl. 5).
- **Plazo:** antes de que nazca `b/ola5` desde `feature/modelo-ng`, hacia el 22 o 23 de octubre.
- **Esfuerzo (inferido, ±40 %):** B 0,3 a 0,5 sp; A 0,1 sp.

## 5. Cómo integrarlo (A, migración de la ola 5)

1. `Ola5VistasVentasInventario` va después de la última migración de `feature/modelo-ng` al unir. Dentro, en este orden:
   1. comprobación de dueño ampliada (H-01) con `THROW 51399`;
   2. creación de `rptc` con `AUTHORIZATION dbo`;
   3. las vistas `rpt` y después las `rptc`, cada una en `EXEC(N'…')` (H-02);
   4. `rpt.VersionContrato`;
   5. el rol `gpos_lectura` y las concesiones y denegaciones del LEEME 5, con el `DENY` generado desde `sys.schemas`.
2. **`rpt.NegativoPorRegularizar`:**
   - Si T1 (`NegativosTresNiveles`, comienza el 15-oct) ya está unida, se integra **solo** la versión posterior a T1. La previa nunca se crea.
   - Si no, la previa (con H-07) va en la ola 5, y la migración de T1, que también es de A, la reemplaza con `CREATE OR ALTER` después de crear `inv.PoliticaNegativa`.
   - El texto de B coincide con la vista del diseño de negativos (`docs/datos/2026-10-08-negativos-tres-niveles-y-lote.md:88-101`, `master`). La comprobación `OBJECT_ID(…, N'V')` es correcta porque `inv.PoliticaNegativa` es una vista.
3. **`Down`:** `DROP VIEW IF EXISTS` de las vistas nuevas; `DROP SCHEMA rptc` solo si quedó vacío. No toca `rpt` ni sus vistas de las olas 3 y 4. No se pierden datos: no cambia ninguna tabla.
4. **Pruebas al unir:**
   - V-D1b, V-D7, V-D8, V-R1 (ampliada a todos los esquemas) y V-D11 a V-D13;
   - la prueba de huella sin base (VW-05);
   - CA-O5-10 en la PC A (H-04).
5. **Duración:** menos de 1 s, con un bloqueo de esquema breve por vista. Se aplica con la API detenida (inferido; no hay escritura de datos).
6. **Esfuerzo de A (inferido, ±40 %):** unas 0,3 sp entre migración, permisos y pruebas, más 0,05 sp de máquina por medición. Sin costo de infraestructura ni de licencias.

## 6. Qué va a firma y qué decide A

| Asunto | Quién decide | Motivo |
|---|---|---|
| VW-01 a VW-08 y H-01 a H-11 | Técnica (A; B en lo suyo) | Construyen lo firmado en ADR-109 (cl. 3, 9, 11 y 13), DD-08, ADR-118 y ADR-119. No cambian alcance, costo ni comportamiento para el usuario |
| VW-03 (`rpt.Recibo` ahora) | Técnica, **se informa** al propietario | Es una vista de CxC dentro de la tanda de ventas. Respeta la prioridad del propietario y no agrega reportes |
| H-03 (`CHD` fuera de las ventas) | Técnica, con confirmación del especialista contable | Corrige una suma; no cambia ninguna regla |
| **Condicional 1:** si ni I-02 ni I-02b pasan la puerta V-D5 acumulada | **Propietario** | Los reportes 17 (a una fecha) y 20 quedarían limitados a artículo o categoría hasta el *columnstore*: es un cambio de alcance |
| **Condicional 2:** si CA-O5-10 sube la venta por encima de 52 ms y ajustar los valores no alcanza | **Propietario** | Habría que elegir entre restringir los reportes pesados en horario de venta y revisar la meta F-R3 (52 ms) |
| Pasar las identificaciones y las diferencias de caja a `rptc` (2.2) | Arquitecto-seguridad recomienda; el propietario firma solo si cambia lo que ve un perfil | Visibilidad de datos personales y de caja para el diseñador |

## 7. Riesgos

| Riesgo | Prob. / impacto | Mitigación |
|---|---|---|
| Vistas de ventas con períodos largos compiten con el POS (H-04) | Media / medio | Límite de costo, `MAXDOP 2`, 30 s y concurrencia por base; medición de CA-O5-10 |
| El presupuesto de p95 se consume dos veces (T1 e I-02) | Media / alto | Medición acumulada contra la línea base de la ola 4; I-02b sin filas de índice adicionales |
| Un esquema de desarrollo con dueño distinto de `dbo` | Media / bajo | La migración falla cerrada (H-01); lo corrige `GPOS.Migracion` como `db_owner` |
| Se edita el contrato después de aplicar la migración | Baja / medio | Regla de migración nueva; la prueba de huella sin base la detecta |
| `FactorUnidad` en la venta (observación) | Por verificar / alto si se confirma | Entrega al desarrollador-backend y a QA |

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\revision-vistas-ola5-2026-10-08.md`
- Supuestos:
  - RCSI activo en todas las bases de empresa y de nodo (`Aprovisionamiento.cs`; no lo comprobé en una base);
  - el último costo de compra está en moneda base;
  - unas 150.000 filas en `inv.Existencia` y 5 almacenes en la empresa grande de referencia;
  - EF no crea un índice aparte para la FK si I-02b empieza con sus columnas;
  - la meta 1 de T-57 está al límite (según la solicitud y `respuestas-A-ola5-solicitud-2026-10-08.md:231`)
- Decisiones candidatas a ADR: ninguna. I-02b es una variante técnica dentro de DD-08; se anota en el documento de datos de la ola 5 al integrar
- Entregas a otros agentes:
  - arquitecto-datos de B → H-03, H-05, H-06, H-07, H-08, H-11; vistas de kárdex y `rpt.Recibo`; `rptsis` en archivos nuevos;
  - arquitecto-software de B → VW-07 (`ReglasNumeracion` en `GPOS.Comun`) y la validación del contrato en ejecución (VW-05);
  - especialista-contable → confirmar que `CHD` sale de las ventas (H-03);
  - arquitecto-seguridad → ¿identificaciones y diferencias de caja en `rpt` o en `rptc`?;
  - desarrollador-backend de A → migración `Ola5VistasVentasInventario` según la sección 5, prueba de huella y verificación de `FactorUnidad` en la venta;
  - QA de A → CA-O5-10 y la medición acumulada de I-02 o I-02b contra la línea base de la ola 4;
  - quien diseñe las recetas → el costo de la línea igual a la suma de sus ingredientes
- Próximo paso recomendado: enviar a B un aviso con H-03, H-05 a H-08, H-11 y VW-01 a VW-08, para que corrija en `b/ola5` antes de que A integre la migración al unir la ola 5
