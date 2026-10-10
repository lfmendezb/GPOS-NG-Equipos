# Ola 3b (3b-2): DDL v3 corregido para el tramo 1 (`Ola3bTransferencias`)

[Blueprint de Datos] · Arquitecto de datos, equipo B · 2026-10-10 · Tramo 0 de la ola 3b · **Diseño: no edité repositorios ni compilé.**

- **Fuentes leídas:** el plan `GPOS-NG-Equipos/traspasos/B/2026-10-10-plan-ola3b.md` (completo). Los ADR 100 a 107, 118 y 119 (con sus precisiones del 2026-10-10), 78 y 53 (cláusula 9 y su segunda precisión, CR-01), en `master`. El modelo, el DDL y el blueprint de la 3b del 2026-10-07, en `GPOS-B-modelo-ng`, rama `feature/modelo-ng` `e7f1f96`; `origin/b/ola3b-diseno` ya está contenida en ella. El blueprint de H-11 parte 2 y el diseño de H-2 de A (`traspasos/A/`). El código de la rama: `InvConfiguracion.cs`, `LibroInventario.cs`, `ConsultasInventario.cs`, `SqlMigracionesOla3.cs`, `SqlMigracionesOla4FactorUnidad.cs`, `SecuenciasNodo.cs`, `DisparadoresNg.cs`, `ScriptEmpresa.cs` y `VersionEsquemaNg.cs`, y las definiciones reales de los disparadores de `doc.Documento`.
- **Artefactos (en el *scratchpad*):**
  - `sql/ola3b-ddl-corregido.sql`: el DDL del tramo 1;
  - `sql/ola3b-ddl-corregido-down.sql`: su reversión;
  - `sql/prueba-funcional.sql`, `sql/ciclo.sh`, `sql/inv.sql`, `sql/medir.sql` y `sql/medir2.sql`: las pruebas.
- **Convención:** *[V]* = verificado hoy (cito `ruta:línea` o el resultado de la prueba); *[I]* = inferido.

## Resumen en 12 líneas

1. **DDL v3 probado en SQL Server 2025 Express [V].** Se aplicó sobre una base `GPOS_TEST_*` nueva, creada con el guion de la rama `…130522_BitacoraLogSoloInsercion`, en este orden: Up dos veces, Down, Up dos veces más. Las cuatro aplicaciones dieron `rc=0`. Después del Down, la base quedó idéntica a la de partida: objetos, columnas, `CHECK`, módulos, permisos y tipos de documento.
2. **H-3b-10:** `Linea = L + 10000 × (1000 × T + n)`. T es el tipo de parte y n su consecutivo. Dos recepciones parciales de la misma línea pasan (`10010001` y `10020001`) [V]. La parte no necesita un contador común, así que en la entrega 2 tampoco chocan dos sitios.
3. **H-3b-11:** la 3b-2 usa los errores **51440 a 51457** y deja 51458 y 51459 de reserva. **Los adjuntos (3b-A) ya no caben en esa franja:** necesitan unos 12 códigos. Pregunta **P-D1**: recomiendo 51460 a 51479, que verifiqué libres.
4. **H-3b-12:** `CK_Movimiento_Clase` queda en `Clase BETWEEN 1 AND 9` y se conserva `CK_Movimiento_Valor` [V].
5. **H-3b-13:** las 5 secuencias nuevas entran en `SecuenciasNodo.Todas`, en `DisparadoresNg.RangoNodo` (con el error 51332) y en `sync.usp_AdelantarSecuencias`.
6. **H-3b-14:** es un cambio de código del tramo 2. `Afectados` debe incluir toda la clase 8. Agrego **H-3b-18 (Baja)**: los reversos de la clase 6 bloquean `ArticuloCosto` sin necesidad.
7. **H-3b-15 / T-09:** la base pone una red propia (51453) en la emisión, que cubre la existencia y el lote. Funciona aunque T1 de ADR-118 todavía no tenga `SalidaEstricta` [V].
8. **H-3b-16:** el disparador nuevo sale en su segunda sentencia en todo documento que no sea tipo 31. Cuesta de 0,01 a 0,1 ms por `UPDATE` [V, medición ruidosa], de un presupuesto de 35 ms.
9. **H-3b-17:** creo `rpt.TransitoArticulo` y `rptc.TransitoArticulo`. La segunda valora al **promedio de la empresa** y no al costo del despacho (corrección por T-05): así cuadra con la foto.
10. **Nuevo `inv.TransferenciaAbierta`** (estado local derivado, como el tránsito). Con él, «Por recibir», el cierre de sucursal y el aviso del cierre de período leen solo las transferencias abiertas, no toda la historia por sus líneas.
11. **Las tablas del tramo 2 nacen ya, vacías y cerradas** con un disparador (51441). El tramo 2 necesita una migración pequeña, `Ola3bDiferencias`, que solo reescribe disparadores.
12. **Choques:** con `NegativosTresNiveles`, H-2 y H-11 parte 2 solo chocan el *snapshot*, la lista `DisparadoresNg.PorTabla` y `CK_Autorizacion_Tipo`. La guarda de las partes usa `sync.EstadoEmision`, la misma fuente que el candado CR-01. Las vistas `rpt` entran en el contrato de la ola 5.

---

## 1. Contexto, modelo de tenencia y correcciones

### 1.1 Tenencia aplicada

La tenencia es una base por empresa (CLAUDE.md, ADR-52). En la entrega 1 hay una sola base por empresa y su sitio es el nodo 1. La 3b no agrega ninguna columna de empresa.

El aislamiento entre sucursales de una misma base lo da la **guarda de sitio por sucursal** de ADR-100:
- la aplica `sync.fn_GuardaParte`, que es nueva y envuelve a `sync.fn_SitioDuenoSucursal`;
- en la entrega 1 siempre devuelve el sitio local;
- se probó con un nodo ficticio (casos 13 y 13b) [V].

El tránsito (`inv.TransitoArticulo`) y las transferencias abiertas (`inv.TransferenciaAbierta`) son **estado local derivado**: no se replican y cada base los recalcula desde sus partes. Los vigilan dos conciliaciones que deben dar 0 filas.

### 1.2 Cada corrección pedida

| # | Corrección | Cómo queda | Dónde (SQL) | Prueba |
|---|---|---|---|---|
| H-3b-10 | Llave única del kárdex `UX_Movimiento_DocumentoLinea (DocumentoId, Linea, ArticuloId, AlmacenId, LoteId, MovimientoRevertidoId)` (`InvConfiguracion.cs:110-119`) | `Linea = L + 10000 × k`, con `k = 1000 × T + n`. **T:** 0 despacho; 1 recepción R_n; 2 diferencia D_n (movimiento principal); 3 entrada del par de la pérdida de D_n; 4 y 5 la confirmación de D_n (entrada y salida en A). **n:** el `Consecutivo` de la recepción o de la diferencia; la confirmación usa el de su diferencia, porque es 1:1 por `UX_Confirmacion_Diferencia`. Valores: L ≤ 2000 y n ≤ 999, así que `Linea` ≤ 59.992.000 (cabe en `int`). Los reversos de la anulación conservan la línea del original y los separa `MovimientoRevertidoId` | PARTE 2.0; `CK_TransfRecepcion_Valores`; `Consecutivo` nuevo en la diferencia; el disparador de las líneas de la recepción exige la línea exacta (51454) | Casos 3 y 4 [V] |
| H-3b-11 | Los errores 51360 a 51379 ya los usa la ola 4 | Franja 51440 a 51459 (ADR-100, precisión 5). La tabla está en la cabecera del SQL; las traducciones a HTTP, en la sección 3 | Todo el script | Busqué en `feature/modelo-ng`, `b/ola5`, `b/adr118-119-t1` y `c/adr118-119-ux`: el número usado más alto es 51412 [V] |
| H-3b-12 | El `CHECK` 1 a 8 rompía la clase 9 | `Clase BETWEEN 1 AND 9`; se reemplaza solo si la definición no es exactamente esa | PARTE 1.3 | Up y Down [V] |
| H-3b-13 | Secuencias nuevas fuera de las listas | `inv.SecTransf{Recepcion, Diferencia, Confirmacion, Imputacion, Redireccion}` entran en `usp_AdelantarSecuencias` (2.15), en `SecuenciasNodo.Todas` (código) y en `DisparadoresNg.RangoNodo` con `TR_*_RangoNodo` (2.5). Llevan `CACHE 50` como las 13 actuales | 1.1, 2.5, 2.15, 2.16 | Compila [V]; la prueba de restauración la amplía QA |
| H-3b-14 | `Afectados` no bloquea `ArticuloCosto` en las salidas de clase 8 con fecha de hoy (`LibroInventario.cs:287-293`) | Código del tramo 2: agregar `\|\| m.Clase == ClasesMovimiento.DiferenciaTransferencia` (entradas y salidas). Con eso, el `Id` sale de `inv.SecMovimiento` después del bloqueo, porque se excluye el camino «Agregados» de `PrepararAsync` (`LibroInventario.cs:131-134`). **Nuevo H-3b-18 (Baja):** `m.Revierte is not null` bloquea `ArticuloCosto` también en el reverso de la clase 6 (anulación de la TI), que no cambia el promedio porque el recálculo excluye la clase 6 (`ConsultasInventario.cs:134`; `CostoPromedioNg.cs:79`). Recomiendo excluir los reversos de clase 6 | Sin DDL | — |
| H-3b-15 | T-09 frente a la política de ADR-118 | **P-2 está firmada: rige T-09.** Hay dos capas. (1) En el servicio: hoy, `KardexPreparado` con `PermiteNegativa = false` en el despacho; después de T1, la marca `SalidaEstricta` (`@estricta` en `AplicarExistencia` y `AplicarExistenciaLote`). (2) **Red en la base:** en la emisión `0 → 1` de la TI, ninguna existencia ni existencia por lote del almacén de origen de sus líneas queda negativa (51453). La red no depende de T1 y cubre el lote, que hoy nunca rechaza (`ConsultasInventario.cs:42-47`) | 2.13 | Caso 5 [V] |
| H-3b-16 | El disparador nuevo corre en toda emisión del POS | Primera sentencia `IF NOT UPDATE(Estado) RETURN;`; segunda, `IF NOT EXISTS (… TipoDocumentoId = 31) RETURN;`. No toca `TR_Documento_Emision` | 2.13 | `medir2.sql`: de 13 a 97 µs por `UPDATE` (tres rondas) [V, ruidoso]; la medición válida es PB-3b-16 |
| Afectados / clase 8 | Bloqueo del costo en la clase 8 (ADR-104) | Orden de los tramos 2 y 3, sección 2. En la base no hay red posible: la serialización es del servicio | — | PB-3b-04 (tramo 2) |
| Salida temprana | Ver H-3b-16 | — | — | — |

**Otros defectos del DDL del 2026-10-07 que corregí:**
- `inv.TransferenciaEstado` **no compilaba**: Msg 130, `SUM` sobre un `NOT EXISTS` [V]. Ahora usa un `LEFT JOIN` a la imputación raíz y cuenta también como «por imputar» las diferencias con confirmación `N`.
- El reemplazo del `CHECK` de clase se detectaba con `NOT LIKE '%8%'`, que es frágil.
- `SCHEMABINDING` en `fn_SitioDuenoSucursal` bloqueaba los `ALTER` futuros de `sync.Nodo` (H-3b-02 y H-11): se retira.
- La fecha local se calculaba con `SYSDATETIME()`, que depende de la zona horaria del servidor. Ahora usa el «hoy de la empresa» (UTC−4 ± 5 min), como `TR_Documento_Ola4b`.
- La guarda fallaba abierta si faltaba `sync.EstadoNodo`. Ahora falla cerrada.
- `DENY DELETE` sobre `inv.MotivoDiferencia` contradecía la precisión de ADR-08 (se elimina lo que no tiene referencias). Se retira: la FK impide borrar un motivo usado.
- La cabecera admitía inserción fuera del borrador.

### 1.3 Lo que sale del DDL (pasa al tramo 3)

El tipo 32 `DAJ`, la familia `SIS`, `AdjuntosSoporteFiscal`, `AniosConservacion`, `MesCierreEjercicio`, `doc.DesvinculacionAdjuntos`, `fn_AdjuntoSoporteFiscal` y `fn_FinConservacion` pasan a la migración `Ola3bAdjuntos`, con su propia franja de errores (P-D1).

### 1.4 Tablas y relaciones del tramo 1

| Tabla | Uso en el tramo 1 | Llave y aislamiento |
|---|---|---|
| `inv.Transferencia` | Cabecera del despacho; subtipo de `doc.Documento` tipo 31 | PK `DocumentoId`. Nace solo en el borrador de una TI de su sucursal de origen (51454); después solo cambian las columnas `Salida*`, una vez (51441). Dueño: sitio de `SucursalOrigenId` |
| `inv.TransferenciaLinea`, `inv.TransferenciaSerie` | Líneas y series del despacho | Solo en el borrador. La línea exige `Cantidad = ROUND(CantidadUnidad × FactorUnidad, 6)` (ADR-78). **Columna nueva** `MotivoLoteVencido` (D3 de [TRF], 10 caracteres o más) |
| `inv.SesionRecepcion`, `inv.SesionRecepcionEscaneo` | Borradores de la recepción (ADR-105) | `TerminadaEn` y `NoEsperado` ([SW3B] 16.8). Una sola sesión abierta por TI. Se purgan a los 30 días de cerrarse (51456) |
| `inv.TransferenciaRecepcion` (+ `Linea`, `Serie`) | Recepción por partes | `Consecutivo` de 1 a 999; `UQ_Recepcion_Sesion`; secuencia por nodo; fecha de hoy (51452); destino vigente (51443); S-02 por código (51451) |
| `inv.MotivoDiferencia` | Maestro con su siembra; se usa desde el tramo 2 | El código y el tratamiento no cambian después de usarse (51445) |
| `inv.PlazoTransitoPar` | Plazo por par de sucursales (`PlazoDias` de la cabecera) | PK del par |
| `inv.TransitoArticulo` | Tránsito por artículo (ADR-101) | `CHECK >= 0`. Lo escriben solo los disparadores |
| **`inv.TransferenciaAbierta`** (nueva) | TI emitidas con saldo de línea pendiente, por destino vigente | La insertan la emisión y la borran la última recepción (o diferencia, en el tramo 2) y la anulación. Conciliación: `rpt.ConciliacionTransferenciaAbierta` |
| Diferencia, confirmación, imputación, redirección y reconstrucción | Del tramo 2 y de la entrega 2: **vacías y cerradas** (51441) | Columnas del modelo del 2026-10-07, más `Consecutivo` en la diferencia |

`conf.Parametros` gana 10 columnas de la 3b-2 (2.11 de [D3B], sin las dos de 3b-A). Como `SucursalCentralId` es `NOT NULL DEFAULT 1` con FK, la sucursal 1 debe existir: la siembra la crea (`PRINCIPAL`) [V].

### 1.5 Tramo 2: `Ola3bDiferencias` (sin cambios de tablas)

- `CREATE OR ALTER` de los cinco disparadores cerrados (2.12), con las reglas de [D3B] 3.1 renumeradas:
  - 51444 sesión del auditor en la central;
  - 51446 redirección solo sin recepciones ni diferencias;
  - 51447 y 51448 imputación (sucursal responsable y solo pérdidas);
  - 51449 una respuesta del origen por diferencia, del tipo que admite su clase;
  - 51450 reconstrucción (entrega 2);
  - 51451 segregación S-03 a S-05 y S-07.
- Los deltas del tránsito de [D3B] 2.9 y el kárdex de cada parte con T de 2 a 5. La diferencia F, N o C sube `CantidadFaltante`.
- La diferencia también puede cerrar `inv.TransferenciaAbierta`. Ojo: una F con tratamiento V **sigue en tránsito** aunque consuma saldo.
- La redirección actualiza `TransferenciaAbierta.SucursalDestinoId`.
- La sobrante y la sustitución exigen lote y vencimiento (ADR-119); un lote existente con otro vencimiento levanta la bandera de revisión (`LOTE_VENCIMIENTO_DISTINTO`) antes de abrir la transacción.
- Esfuerzo: unas 0,15 sp más la regeneración [I].

---

## 2. Orden de bloqueos por operación (ADR-45 con ADR-104)

**Orden general:**
`documentos (GPOS.Doc:TI:{n}) → configuración (guarda de emisión; conf.Parametros con REPEATABLEREAD por la fecha de cierre) → serie TI → filas: [ArticuloCosto solo con clase 8] → doc.LineaSaldo → inv.Existencia / inv.ExistenciaLote (por ArticuloId, AlmacenId) → inv.NumeroSerie (por Id) → inv.TransitoArticulo → inv.TransferenciaAbierta`

**Reglas que valen para todas las operaciones:**
- La 3b no toma `GPOS.Inventario:` ni la jornada.
- `TransferenciaAbierta` es una fila por TI que solo toca quien tiene `GPOS.Doc:TI:{n}`, o que es nueva en la emisión.
- **La fecha de cierre se lee en el nivel de configuración (`PeriodoInventario.ExigirFechaAbiertaAsync`, dentro de `PrepararAsync`) antes de tocar cualquier fila.** El disparador `TR_Movimiento_PeriodoCerrado` vuelve a leerla con `REPEATABLEREAD` al insertar el kárdex: si no se leyó antes, se invierte el orden.

| Operación | Dentro de la transacción, en este orden |
|---|---|
| **A1 Despacho (modo E)** | (1) `BorradorSinNumeroAsync`: guarda y fecha (configuración); `INSERT` del borrador: documento `P`, cabecera, kárdex de salida (clase 6, `Linea = L`), líneas, series y `LineaSaldo` R. Son filas nuevas que nadie espera. (2) Serie `TI` de la sucursal de origen. (3) Existencia del origen: descuento **estricto** en orden de llave, y existencia por lote. (4) `NumeroSerie E → T` en orden de `Id`, con `@@ROWCOUNT`. (5) Emisión `0 → 1`: el disparador valida, inserta la abierta y suma el tránsito al final. (6) Bitácora. **Sin `ArticuloCosto`**: el costo del despacho se lee con RCSI fuera de la transacción (T-01) |
| **Confirmar salida** | `GPOS.Doc:TI:{n}` → relectura (emitida, sin salida, misma `Version`, conduce impreso) → `UPDATE inv.Transferencia … WHERE Version = @v AND SalidaConfirmadaEn IS NULL` → bitácora |
| **A2 Recepción (modo E, sin diferencias)** | Fuera de la transacción: la sesión, los escaneos (una transacción corta cada uno) y «terminar». Al confirmar: (1) `GPOS.Doc:TI:{n}`. (2) Relectura: sesión `A` **con `UPDLOCK`**, para que un escaneo concurrente espere y después vea la sesión cerrada (51441); TI emitida; destino vigente; recepción ya existente con esa `SesionId` → devolverla con `Repetida`. (3) Configuración: guarda y fecha (`PrepararAsync`). (4) `UPDATE` condicional de `doc.LineaSaldo`, **antes** de las filas de la recepción: el disparador exige consumido = Σ recibido. (5) Kárdex de entrada (clase 6, `L + 10000 × (1000 + R)`, costo del despacho, unidad base). (6) Existencia del destino y por lote. (7) `NumeroSerie T → E`. (8) `INSERT` de la recepción, sus líneas (el disparador resta el tránsito y cierra la abierta) y sus series. (9) Sesión `A → C`. (10) Bitácora |
| **Modo S (traslado en la misma sucursal, un paso)** | Configuración → serie → **existencia del origen y del destino en una sola pasada por (ArticuloId, AlmacenId)**: con dos pasadas, dos traslados opuestos entre los mismos almacenes se interbloquean [I] → existencia por lote → `NumeroSerie E → T` → **emisión (+q)** → `LineaSaldo` (filas propias) → `NumeroSerie T → E` (mismas filas) → recepción R1 (−q, misma fila) → sesión → bitácora. La recepción va **después** de la emisión: antes, el −q violaría `CK_TransitoArticulo_Cantidad`. La cabecera nace con `Salida*` llena. No hay S-02 (S-3b-04). Probado en el caso 11 [V] |
| **A4 Anulación** | `GPOS.Doc:TI:{n}` → relectura: 0 recepciones, 0 diferencias, sin sesión abierta (se descarta antes; si no, 51442) → configuración (`RevertirAsync`, con la fecha del original) → con la salida confirmada, `doc.Autorizacion ANULA_TRANSITO` (fila nueva; si falta, 51455) → [`ArticuloCosto` hoy, por H-3b-18] → existencia del origen (+q) → existencia por lote → `NumeroSerie T → E` → `UPDATE` `1 → 2` (el disparador valida, borra la abierta y resta el tránsito) → bitácora. Una TI de modo S no se anula, porque nace con su recepción: se corrige con otro traslado |

**Sin ciclos [I]:**
- Ninguna operación toma una serie o un NCF después de una fila.
- La venta POS no toca `LineaSaldo` R, `TransitoArticulo` ni `TransferenciaAbierta`.
- La compra toma `ArticuloCosto → Existencia` y el despacho solo `Existencia → …`.
- Dos despachos de la misma sucursal se serializan en la serie y toman el tránsito al final, en el orden de artículo del `MERGE`.

Lo vigila PB-3b-12: 0 errores 1205.

---

## 3. Restricciones, errores y su traducción (para `ErroresNumeracion`)

| Error | Código del contrato | HTTP | Cuándo |
|---|---|---|---|
| 51440 | `PARTE_DE_OTRO_SITIO` | 409 | La parte no la escribe el dueño de su sucursal (caso 13 [V]); la central sí la escribe con el nodo inhabilitado (13b [V]) |
| 51441 | `PARTE_INMUTABLE` | 500 | Cualquier `UPDATE` o `DELETE` de partes; líneas fuera del borrador; escaneo en una sesión cerrada; tablas del tramo 2 cerradas (caso 10 [V]) |
| 51442 | `TRANSFERENCIA_CON_PARTES` | 409 | Anular con recepciones, diferencias o una sesión abierta (caso 6 [V]: salta antes que 51313) |
| 51443 | `DESTINO_NO_VIGENTE` | 409 | Sesión o recepción fuera del destino vigente (caso 12 [V]) |
| 51444, 51446 a 51450 | Ver 1.5 | — | Tramo 2 y entrega 2 |
| 51445 | `MOTIVO_CON_MOVIMIENTOS` | 409 | Cambiar el código o el tratamiento de un motivo usado |
| 51451 | `FUNCION_INCOMPATIBLE` | 403 | S-02 en modo E, por código de usuario; alcanza al ADMIN y al SUPER (caso 2 [V]) |
| 51452 | `FECHA_PARTE` | 500 | Fecha de la TI o de la recepción distinta de hoy de la empresa |
| 51453 | `EXISTENCIA_INSUFICIENTE` | 409 | T-09: la emisión deja negativo el origen o su lote (caso 5 [V]) |
| 51454 | `TRANSFERENCIA_INCONSISTENTE` | 500 | Kárdex de la parte ≠ la parte; totales; lote obligatorio y del artículo; lote vencido sin motivo; una serie por unidad; `LineaSaldo` (caso 3 [V]) |
| 51455 | `AUTORIZACION_INVALIDA` | 422 | Anular en tránsito sin `ANULA_TRANSITO` (caso 8 [V]) |
| 51456 | `SESION_NO_PURGABLE` | 500 | Borrar una sesión abierta, o cerrada hace menos de 30 días (caso 9 [V]) |
| 51457 | `TRANSFERENCIA_NO_VIGENTE` | 409 | Sesión o recepción sobre una TI no emitida o anulada |
| 51330 | `EMISION_BLOQUEADA` (existente) | 503 | Recepción en una base restaurada (`sync.EstadoEmision`) |
| 51332, 51333 | Existentes | — | Rango del nodo; período cerrado (por el kárdex) |
| 2601 / 2627 | — | 200 o 409 | `UQ_Recepcion_Sesion` (se relee y se devuelve con `Repetida`) y `UX_SesionRecepcion_Abierta` (el segundo usuario se une; caso 9b [V]) |
| 547 de `CK_LineaSaldo_Consumo` o `CK_TransitoArticulo_Cantidad` | `SALDO_INSUFICIENTE` | 409 | Red final |

**Supuesto.** `CK_Autorizacion_Tipo` agrega `DIF_TRANSFERENCIA`, `CONF_ORIGEN`, `ANULA_TRANSITO`, `REDIRECCION` y `RECONSTRUCCION`. El plan dice `ANULAR_TRANSFERENCIA`; usé `ANULA_TRANSITO`, el nombre del modelo de datos firmado ([D3B] 2.12), que además nombra lo que se autoriza: anular **en tránsito**. `ANULA_TRANSITO` también entra en `CK_Autorizacion_Motivo`, porque es la declaración del supervisor.

**Tipo 31 con `ControlFecha = 1` (fecha del servidor).** `TR_Documento_Ola4b` solo le aplica F-7: no se anula una TI de un mes declarado. Es lo mismo que pasa con la entrada y el ajuste.

---

## 4. Índices y la consulta que justifica cada uno

| Índice | Consulta | Costo de escritura [I] |
|---|---|---|
| `PK_Transferencia`, `PK_TransferenciaLinea` | Despacho, conduce y recepción por documento | 1 fila por TI y 1 por línea |
| `IX_Transferencia_Destino (SucursalDestinoId, DocumentoId) INCLUDE (AlmacenDestinoId, SucursalOrigenId, SalidaConfirmadaEn)` | Lista «Transferencias» filtrada por destino (pantalla del tramo 0) | ~20 B por TI |
| `IX_Transferencia_Origen (SucursalOrigenId, DocumentoId) INCLUDE (AlmacenOrigenId, SucursalDestinoId, SalidaConfirmadaEn)` | Lista filtrada por origen; «salida sin confirmar»; conteo con despachos en el andén (C-07) | ~20 B por TI |
| `IX_TransferenciaLinea_Articulo (ArticuloId, LoteId) INCLUDE (UnidadId, Cantidad)` | Regla R7 de `TR_ArticuloUnidad_Factor` (la unidad usada en una TI no cambia de factor); `rpt.ConciliacionTransito` por artículo; lotes en tránsito | ~25 B por línea |
| `UX_TransferenciaSerie_Serie` | «La serie la tiene la TI n» | ~16 B por serie |
| `UQ_Recepcion_Sesion`, `UQ_Recepcion_Consecutivo` | Idempotencia de A2; R1, R2… | ~30 B por recepción |
| **`IX_TransfRecLinea_DocumentoLinea (DocumentoId, Linea) INCLUDE (Cantidad)`** (nuevo) | El control Σ recibido = consumido del disparador de la recepción (búsqueda por línea) y el historial por TI | ~25 B por línea recibida |
| `UX_SesionRecepcion_Abierta` (filtrado), `IX_SesionRecepcion_Purga` (filtrado) | Una sesión abierta por TI; la purga nocturna | Mínimo |
| **`IX_TransfAbierta_Destino (SucursalDestinoId)`** (nuevo) | «Por recibir» y el contador del menú; `CierreSucursalService.EnTransitoAsync`; `AVISO_TRANSFERENCIAS_ABIERTAS`. Plan medido: *seek* en `IX_TransfAbierta_Destino` + `PK_Documento` + `PK_Transferencia` [V] | 1 fila por TI abierta |
| `PK_TransitoArticulo` | `inv.ExistenciaGlobal` en cada entrada de compra | 1 fila por artículo en tránsito |
| Los del tramo 2 (`IX_TransfDif_*`, `UX_Confirmacion_Diferencia`, `UX_Imputacion_*`, `UX_Redireccion_*`) | Los mismos de [D3B] 4.1 | Tablas vacías en el tramo 1 |

**Por qué existe `inv.TransferenciaAbierta`.** Sin ella, «Por recibir» recorre todas las TI históricas del destino y su `LineaSaldo`. Para un cliente grande (1 TI diaria de 100 líneas por sucursal) son unas 36.500 filas por consulta y por año de historia, y la cifra crece sin tope [I]. Con ella, el costo es proporcional a las abiertas, que son unas decenas.

Alternativas descartadas:
- un índice filtrado sobre `LineaSaldo`: un filtro no puede comparar dos columnas;
- una columna de estado en la cabecera: rompería «un sitio por parte» de ADR-100.

**`inv.ExistenciaGlobal` con el tránsito** (`UNION ALL` + `GROUP BY`), medido con 30.000 artículos y 90.003 existencias:
- el plan hace *seek* en `PK_Existencia` y en `PK_TransitoArticulo` [V];
- una consulta de 200 artículos tarda **0,76 ms**, frente a 0,41 ms con la vista actual: +0,35 ms por compra de 200 artículos, unos +0,002 ms por artículo [V, equipo de desarrollo, ±50 %].

Con tablas pequeñas el optimizador elige recorrido completo, lo cual es correcto. T-3b-08 debe revisar el plan con el volumen del cliente.

**Volumen [I, ±50 %]:** el de [D3B] 4.3 no cambia (cliente pequeño ~5 MB por año; grande ~350 MB por año). `TransferenciaAbierta` y `TransitoArticulo` suman menos de 1 MB. **Costo de hosting: USD 0.**

---

## 5. Migración `Ola3bTransferencias`: qué incluye y cómo se regenera el guion

**Se genera después de la última migración unida.** Hoy es `20261010130522_BitacoraLogSoloInsercion`; antes de unir, se regenera sobre lo que haya entrado: la ola 5, `NegativosTresNiveles`, `H11CandadoChequeras` y `H2ComprobanteHistorico`. **Nunca se fusiona el *snapshot* a mano.**

1. **Modelo (lo genera EF; los nombres de los objetos deben ser los del SQL, PARTE 1):**
   - `ClasesMovimiento`: `DiferenciaTransferencia = 8` y `CheckClase = "Clase BETWEEN 1 AND 9"`;
   - `TiposDocumento`: `TransferenciaInventario = 31`, código `"TI"`;
   - `TipoNumeracion.TransferenciaInventario` y su entrada en `CatalogoNumeracion` (prefijo `TI`, por sucursal). La serie nace sola con `AsegurarSeriesAsync` (`SqlMigracionesOla3.cs:65`), sin siembra;
   - las entidades y `TrfConfiguracion.cs`, con FK compuestas a `org.Almacen (Id, SucursalId)` por `HasPrincipalKey`, filtros de los índices únicos, `rowversion` y `NodoOrigenId` con `HasComputedColumnSql(..., stored: true)`;
   - las 10 propiedades de `Parametros` con `HasDefaultValue`, su FK y su `CHECK`;
   - `CK_Autorizacion_Tipo` y `CK_Autorizacion_Motivo` en `DocConfiguracion`;
   - las 5 secuencias en `SecuenciasNodo.Todas`.
2. **`DisparadoresNg`:**
   - las 5 tablas con secuencia entran en `RangoNodo`;
   - en `PorTabla` entran todas las tablas nuevas con disparador, más `"TR_Documento_Transferencia"` en `doc.Documento`.

   **Es obligatorio:** sin `HasTrigger`, EF inserta con `OUTPUT` sin `INTO` y SQL Server lo rechaza en una tabla con disparadores.
3. **`SqlMigracionesOla3b.cs`:**
   - `Ola3bTransferenciasPrevia()`: la PARTE 0 (51399), al principio del `Up`;
   - `Ola3bTransferencias()`: la PARTE 2 completa, al final del `Up`, con un `Exec(...)` por cada `CREATE OR ALTER` (patrón de `SqlMigracionesOla4FactorUnidad.cs`);
   - `Ola3bTransferenciasDown()`: el contenido de `ola3b-ddl-corregido-down.sql`, **antes** de las operaciones que genera EF. Repone `TR_ArticuloUnidad_Factor` y `usp_AdelantarSecuencias` **desde sus constantes** (`SqlMigracionesOla4FactorUnidad`, `SqlMigracionesOla3`), no con texto copiado.
4. **Comandos:**
   - `dotnet ef migrations add Ola3bTransferencias -p src/GPOS.Core -s src/GPOS.Core -c EmpresaNgDbContext -o Datos/Empresa/Migraciones`;
   - `dotnet ef migrations script --idempotent -p src/GPOS.Core -s src/GPOS.Core -c EmpresaNgDbContext -o database/empresa/gpos-empresa-<id>_Ola3bTransferencias.sql`, y borrar el guion anterior (la prueba `El_script_embebido_es_el_que_genera_EF` lo exige, `AprovisionamientoTests.cs:155-166`);
   - `dotnet ef migrations has-pending-model-changes` → 0.
5. **Al rebasar** (ola 5 el 22-23 de octubre; T1 el 27): resolver el *snapshot* y el guion tomando la versión de la rama base; borrar los tres archivos propios de la migración; volver a ejecutar `migrations add` (marca de tiempo nueva) y `migrations script`; repetir la puerta.
6. **Puerta:**
   - el guion se aplica dos veces sin error;
   - T-3b-12: Down y Up, con la comprobación de `ciclo.sh` (inventario idéntico);
   - el Down con datos falla con 51399.

   Todo lo verifiqué hoy sobre la rama [V].
7. **Bloqueos y duración:**
   - `ALTER` sobre `conf.Parametros` (1 fila, temporal: el historial recibe y pierde las columnas sin problema [V]), `inv.Movimiento` (cambio de `CHECK` con validación: recorre la tabla; segundos en desarrollo, unos 20 s por millón de filas [I]) y `doc.Autorizacion`;
   - el resto son objetos nuevos;
   - se ejecuta con la API detenida, como toda actualización del esquema.
8. **Reversión con datos:** no hay. Es funcional: se ocultan las opciones y `inv.ExistenciaGlobal` conserva el tránsito ([D3B] 7).

**Privilegios (gpos_app):**
- `DENY UPDATE, DELETE` sobre las partes; `DENY DELETE` sobre la cabecera; `DENY INSERT, UPDATE, DELETE` sobre `TransitoArticulo` y `TransferenciaAbierta`;
- se probó con un usuario del rol: el `INSERT` directo y el `UPDATE` de una recepción dan **229**, y el rol ve el *fork* (`Restaurada = 0`) [V];
- los disparadores escriben por encadenamiento de propiedad;
- las vistas `rpt` quedan al alcance de `gpos_reportes` por el `GRANT` del esquema, y `rptc` solo de `gpos_lectura` (`PermisosLecturaReportes`, `b/ola5`);
- RG-14 sigue abierto: la 3b no agrega permisos de esquema.

**Respaldo y retención:**
- las partes se conservan 10 años y no se borran (`DENY`);
- las sesiones y los escaneos se purgan a los 30 días (51456 protege las demás);
- el tránsito y las abiertas se reconstruyen desde las partes;
- tras una restauración, las dos conciliaciones deben dar 0 filas antes de desbloquear, y las secuencias nuevas entran en `usp_AdelantarSecuencias` (H-3b-13).

---

## 6. Choques

| Con | Punto | Cómo se evita |
|---|---|---|
| **`NegativosTresNiveles`** (T1 de ADR-118/119, `b/adr118-119-t1`, unión el 27-oct si está en verde) | (a) T1 quita `@permite` de `AplicarExistencia` y `AplicarExistenciaLote` (`ConsultasInventario.cs:17-47`). (b) *Snapshot* y `conf.Parametros` (cambia un valor por omisión). (c) `DisparadoresNg.PorTabla` y quizás `CK_Autorizacion_Tipo`. (d) Retira `LoteVencido = 'A'` reescribiendo `TR_Documento_Emision` | (a) T1 agrega `@estricta bit` a los dos comandos (`@permite = CASE WHEN @estricta = 1 THEN 0 ELSE <política> END`) y `SalidaEstricta` en `KardexPreparado`: unas 0,02 sp. Hasta entonces la 3b pasa `PermiteNegativa = false`, y 51453 es la red en los dos casos. (b) y (c): quien una segundo regenera su migración y rehace el `CHECK` con la lista completa. (d) Sin choque: la 3b no toca `TR_Documento_Emision`. Los disparadores de la 3b no escriben `inv.Existencia`, así que pasan la prueba P-12 de ADR-118 |
| **`H2ComprobanteHistorico`** (A; errores 51420-51425) | `conf.Parametros` (`FechaImplantacion` y `TR_Parametros_Implantacion`); dos disparadores nuevos `AFTER UPDATE` en `doc.Documento` (`TR_Documento_Historico`, `TR_Documento_SinNcf`); `DisparadoresNg.PorTabla` | Sin choque de reglas ni de números. Las listas de `PorTabla` se fusionan como texto y el *snapshot* se regenera. **Rendimiento:** son tres disparadores más por emisión del POS; PB-3b-16 los mide juntos |
| **H-11 parte 2** (`H11CandadoChequeras`, A; 51403 y 51404) | El candado CR-01 de la base de empresa es el estado `RESTAURADA` de `sync.EstadoEmision` (D-7 de A). 51403 es un disparador sobre `doc.Documento` (`INSERT`, `UPDATE`). La reconciliación cambia `usp_ConfirmarReconciliacionLocal` | La TI ya queda cubierta por 51403. Las partes que no tocan `doc.Documento` (recepción y siguientes) leen **la misma vista** a través de `sync.fn_GuardaParte` y fallan cerradas con 51330 (503, igual que 51403). Si A cambia la condición del candado, se cambia solo `fn_GuardaParte`. **Entrega a A y al arquitecto-software:** las rutas de transferencias no llevan `PermitidaConCandado`. `usp_AdelantarSecuencias`: si A lo redefine, quien una segundo conserva las 16 filas. R-D9 de A sigue vigente: adelantar las secuencias antes de activar los adjuntos o el ERP |
| **Ola 5** (`b/ola5`) | `rptc` existe solo en la ola 5; el contrato `contrato-vistas.v1.json` y `rpt.VersionContrato` llevan huella | `rptc.TransitoArticulo` se crea solo si existe el esquema; la 3b se une después de la ola 5. **Entrega a la ola 5 (o a la 3b al rebasar):** agregar `rpt.TransitoArticulo`, `rptc.TransitoArticulo`, `rpt.ConciliacionTransito` y `rpt.ConciliacionTransferenciaAbierta` al contrato, subir su versión y la huella, y poner la etiqueta «Diferencia de transferencia» a la clase 8 en `rpt.Kardex` |

---

## 7. Preguntas para el propietario

| # | Pregunta | Opciones | Recomendación | Qué rompe / cuándo |
|---|---|---|---|---|
| **P-D1** | ADR-100 asigna a la 3b los errores 51440 a 51459, pero la 3b-2 usa 18 (de 51440 a 51457) y la 3b-A necesita unos 12: los 6 del diseño de adjuntos de [DAT], que además citan 51340-51345, ya ocupados por la ola 4, y los 6 de v2.2. ¿Qué franja usan los adjuntos? | **A.** 51460 a 51479 para 3b-A, verificada libre en todas las ramas locales y en `docs` de `master`. **B.** Apretar los dos en 51440-51459 y quitar las redes de la base de alguna regla | **A.** B obligaría a quitar controles de la base. No rompe nada construido | Precisión de ADR-100 (punto 5) o de ADR-67. Hace falta antes del tramo 3 (mediados de noviembre); no bloquea el tramo 1 |

Las demás decisiones de este documento son de datos o de coordinación, dentro de lo firmado, y no requieren al propietario:
- la línea por parte;
- la tabla `TransferenciaAbierta`;
- las tablas del tramo 2 cerradas y la migración `Ola3bDiferencias`;
- `ANULA_TRANSITO`;
- `ControlFecha = 1`;
- el valor del tránsito al promedio.

---

## 8. Riesgos

| # | Riesgo | Prob. / impacto | Mitigación | Residual |
|---|---|---|---|---|
| R-1 | El servicio no sigue el orden de A2 (`LineaSaldo` antes que las partes) o de modo S (emisión antes de la recepción) | Media / bajo (falla con 51454 o 547, no corrompe) | Sección 2; mensajes de error explícitos | Bajo |
| R-2 | Dos rebases el mismo día (ola 5 y T1) con la migración regenerada | Alta / medio | Sección 5, punto 5; editor único | Medio |
| R-3 | Un `Linea` mayor que 32.767 impide el Down de `Ola4FactorUnidad` (51394, `SqlMigracionesOla4FactorUnidad.cs:31`) | Cierta / bajo | Nadie revierte a antes de la ola 4 con transferencias; H-11 ya prohíbe revertir paquetes | Bajo |
| R-4 | Un consumidor del kárdex muestra `Linea` sin decodificar (`10020001`) | Media / bajo | Pantalla y reportes: `L = Linea % 10000`, `parte = Linea / 10000`; entrega a la ola 5 y al diseñador | Bajo |
| R-5 | Tres a cinco disparadores `AFTER UPDATE` por emisión del POS (3b, H-2, CR-01) | Media / medio | Salida temprana medida; PB-3b-16 con todos unidos | Bajo |
| R-6 | Una base de prueba creada sin `sync.EstadoNodo` bloquea las recepciones (la guarda falla cerrada) | Baja / bajo | Las bases de prueba se crean con `Aprovisionamiento.CrearAsync`, que registra el sitio | Bajo |

---

### Cierre
- **Estado:** Completado.
- **Artefactos:**
  - `C:\Users\lfmen\AppData\Local\Temp\claude\C--Users-lfmen-source-repos-Solucion-GPOS-NG-GPOS-NG\2ab4d64a-60e5-4721-9bba-4b93894990d8\scratchpad\ola3b-ddl-corregido.md`;
  - `…\scratchpad\sql\ola3b-ddl-corregido.sql`;
  - `…\scratchpad\sql\ola3b-ddl-corregido-down.sql`;
  - `…\scratchpad\sql\prueba-funcional.sql`, `ciclo.sh`, `inv.sql`, `medir.sql` y `medir2.sql`.
- **Supuestos:**
  - el esquema de `feature/modelo-ng` `e7f1f96` es la base del tramo 1;
  - `ANULA_TRANSITO` en lugar de `ANULAR_TRANSFERENCIA`;
  - la recepción registra el kárdex en unidad base (factor 1);
  - `ControlFecha = 1` para la TI;
  - los tiempos son de un equipo de desarrollo (±50 %).
- **Decisiones candidatas a ADR:**
  - línea del kárdex por parte (precisión de ADR-78 y ADR-104);
  - `inv.TransferenciaAbierta` como estado local derivado (precisión de ADR-101);
  - franja 51460-51479 para 3b-A (P-D1);
  - T-09 como red en la base, 51453 (precisión de ADR-118, con P-2).
- **Entregas a otros agentes:**
  - **desarrollador-backend (3b):** sección 5, orden de la sección 2 y `PermiteNegativa = false` en el despacho;
  - **constructor de T1 (ADR-118):** `@estricta` / `SalidaEstricta`;
  - **A:** H-3b-18 en la revisión del núcleo; si cambia el candado, ajustar `fn_GuardaParte`;
  - **ola 5:** contrato de las cuatro vistas y la etiqueta de la clase 8;
  - **qa-automatizado:** convertir `prueba-funcional.sql` en pruebas de `GPOS.Tests` (T-3b-12, PB-3b-06 a 08 y 12) y PB-3b-16 con H-2 y CR-01;
  - **arquitecto-software:** rutas sin `PermitidaConCandado` y mapeo de 51440 a 51457.
- **Próximo paso recomendado:** que el coordinador confirme `Ola3bDiferencias` en el tramo 2 y lleve P-D1 al propietario; el 15-oct el desarrollador traslada el DDL a EF y regenera el guion.
