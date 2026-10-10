# Rendimiento de la ola 4: diagnóstico y remedio de H-QA4-03 y H-QA4-04

**Autor:** arquitecto-software · **Fecha:** 2026-10-07 · **Árbol revisado (solo lectura):** `GPOS-NG-numeracion`, rama `feature/modelo-ng`, HEAD `fa6dcff` · **Estado:** propuesta, pendiente de firma del propietario en los puntos de la sección 6

**Fuentes:** salidas de QA `t57-c1.txt`, `t57-c2.txt`, `t57-diag.txt` y `t28.txt` (scratchpad de la sesión `6bc31041…`); salida detallada de la corrida 1 de C-1 de la ola 3 (`f2c0a692…/scratchpad/corrida1.log`); `docs/arquitectura/2026-10-06-ola4-blueprint.md` (R-1, 14.3, D-4, D-5); `docs/adr/ADR-072.md`; `docs/decisiones/2026-10-06-cierre-ola3.md` (C-1); `docs/calidad/2026-10-05-ola3-revision-qa.md`. No compilé ni ejecuté nada. Todas las cifras de carga son de QA. Las estimaciones van marcadas como **inferidas**.

---

## 0. Resumen

| Tema | Conclusión | Evidencia principal |
|---|---|---|
| **H-QA4-03: causa** | **Convoy.** Una venta que ya tiene la serie `FacturaPos` llega a `UPDATE inv.Existencia` y espera a una compra que retiene esa fila (X) desde que aplica su existencia hasta el `COMMIT`, unos 68 viajes al motor después: recálculo de costo, último costo, CxP, 606, emisión con disparadores. Mientras tanto los otros 5 cajeros esperan la serie. | El muestreo registra 134 esperas de la venta (`@l2_ex`/`@l3_ex`) en `inv.Existencia` bloqueadas por `KardexCosto` o por una compra inactiva, y 158 esperas en `num.Serie` cuyo bloqueador es una venta parada en ese `UPDATE` (`t57-diag.txt`). En unas 134 de las ~1.800 lecturas (≈ 7 % del tiempo), el POS entero está detenido detrás de una compra, y eso basta para fijar el p95. |
| **H-QA4-03: remedio** | **A1:** en la compra (y en todo lo que pasa por `LibroInventario.AplicarAsync`), aplicar la existencia **al final**, en un solo lote junto con la emisión, y agrupar en lotes el costo y el último costo. La fila de existencia queda retenida de 3 a 8 ms en vez de 100 a 800 ms. **V1:** reducir de 7 a 3 los viajes que la venta hace con la serie tomada. | `LibroInventario.cs`:121-132, `DocumentosComercialesService.Compras.cs`:240-266, `CostoPromedioNg.cs`:42-77, `PosService.cs`:285-318, `SeriesNumeracion.cs`:62-127, `UnidadTrabajo.cs`:116-120 |
| **H-QA4-04: causa** | **No son los disparadores de DQ-3.** En la propia T-28, `TR_Documento_Ola4` cuesta **0,018 ms** por ejecución y `TR_Documento_Ola4b` **0,022 ms** (0,07 ms por venta, lo que estimó DQ-3). Las cifras de 0,273 y 0,114 ms son el **acumulado de T-57**, que incluye las emisiones de compras y pagos. Lo que se ve es una CPU un 11 a 13 % más lenta en sentencias **sin cambios**, y T-28 empezó **39 s después** de 14 min de carga continua, sin los 15 min de enfriamiento de C-1. | `t28.txt`: tabla de disparadores del tramo. Frente a `corrida1.log` de C-1: `TR_Documento_Credito` 0,046 → 0,051 ms, CPU de `INSERT doc.Documento` +13 %, de `caja.Movimiento` +12 %. Horarios de los archivos: c2 terminó a las 17:36, el diagnóstico a las 17:40:33 y T-28 empezó a las 17:41:12. |
| **H-QA4-04: remedio** | Repetir T-28 con el procedimiento de C-1 (plan «Alto rendimiento», 15 min de enfriamiento, frecuencia registrada) y **antes** de T-57. Los disparadores no se tocan. V1 da el margen que hoy falta. | — |
| **Meta 5a (250 ms)** | Recalibrarla, **pero después del remedio**: p95 **≤ 400 ms** medido solo en el tramo de 6 cajeros, en las dos corridas, con alerta a 250 ms. Hoy la cifra mezcla el tramo de 12 cajeros (`CargaOla4Tests.cs`:439) y la espera detrás del recálculo completo de la otra compradora. | `t57-c1/c2`: con 6 cajeros, p95 de 610 y 646 ms y p50 de 174 y 186 ms; con 12 cajeros, p95 de 1.044 y 1.128 ms |
| **Recomendación única** | **A1 + V1** (con A3, el índice de `KardexCosto`, como paso separable de datos). Total: **de 1,4 a 2,0 sp** (inferido ±30 %) y unas 3 h de máquina para QA. | Sección 5 |
| **Firma del propietario** | **F-a:** reorden dentro del nivel «saldos» de la compra (precisión técnica de ADR-45, como D-5). **F-b:** meta 5a ≤ 400 ms. **F-c (contingencia):** meta 1 de T-57 relativa si T-28 cumple y el convoy desaparece. V1 y A3 no requieren firma. | Sección 6 |

---

## 1. Diagnóstico

### 1.1 H-QA4-03: la venta con compras (p95 de 255 y 297 ms frente a 52)

#### Secuencia de bloqueos de la venta (verificada en el código)

| Paso | Código | Bloqueo que retiene hasta el `COMMIT` |
|---|---|---|
| 1. Jornada | `PosService.cs`:257 | S de la jornada (applock compartido) |
| 2. Borrador sin número, líneas, pagos, `LineaSaldo`, kárdex (filas nuevas) | `PosService.cs`:262-281 | X de filas nuevas (nadie las espera) y S de configuración y fecha de cierre (`DocumentosNg.cs`:130-131) |
| 3. **Serie `FacturaPos`**: `SET LOCK_TIMEOUT`, lectura previa, `SELECT … WITH (UPDLOCK, ROWLOCK)`, comprobación de números existentes y `UPDATE num.Serie` | `PosService.cs`:285 → `DocumentosNg.cs`:97 → `SeriesNumeracion.cs`:68-127 (`:97`, `:280`, `:127`) | **U/X de la única fila de la serie, compartida por todas las cajas** |
| 4. Lote: NCF, caja, bitácora y **existencia** (`UPDATE inv.Existencia WITH (ROWLOCK)`) | `PosService.cs`:288-306; `ConsultasInventario.cs`:19 | X de `inv.Existencia (artículo, almacén)` |
| 5. Emisión (`UPDATE doc.Documento … Estado = 1`, con disparadores) | `PosService.cs`:317 → `DocumentosNg.cs`:214-227 | — |
| 6. Guardado del contexto heredado (línea de `_LOG` del puente) y `COMMIT` | `PosService.cs`:318 → `UnidadTrabajo.cs`:116-120; `BitacoraDocumentos.cs`:79 (`PuenteCfg.Bitacora` deja la línea en el contexto heredado) | — |

Con la serie tomada hay, por lo tanto, **7 viajes al motor más el `COMMIT`**: `SELECT UPDLOCK`, existentes, `UPDATE` serie, lote, emisión, `_LOG` y `COMMIT`. ADR-72 contaba «5, o 6 con NCF».

#### Secuencia de bloqueos de la factura de compra (verificada)

| Paso | Código | Bloqueo retenido |
|---|---|---|
| Serie `FacturaCxp` | `DocumentosComercialesService.Compras.cs`:174 | U/X de la fila de la serie de compras (solo entre compras) |
| Costo: `CostoBloqueado` **un viaje por artículo** (20) y existencia global sin bloqueo | `LibroInventario.cs`:121 → `CostoPromedioNg.cs`:42-53; `ConsultasInventario.cs`:95-98 | U de `inv.ArticuloCosto` |
| **Existencia: un `UPDATE` por artículo (20 viajes)** | `LibroInventario.cs`:123 → `:157-166` | **X de `inv.Existencia`: desde aquí la venta que pida ese artículo espera** |
| Lotes, guardado del kárdex | `LibroInventario.cs`:124-130 | filas nuevas |
| Costo: 20 `GuardarCosto` (incremental) o **recálculo completo** con `KardexCosto` (fecha anterior, anulación) | `CostoPromedioNg.cs`:59-90 | — (sigue reteniendo la existencia) |
| Último costo: **20 viajes más** | `Compras.cs`:241 → `ComprasNg.cs`:68-73 | — |
| Situación de la orden, CxP, 606, bitácora | `Compras.cs`:244-262 | filas nuevas o ya protegidas por el nivel «documentos» |
| Emisión (disparadores 51342 a 51346) y `COMMIT` | `Compras.cs`:265-266 | — |

**Tramo con la existencia retenida:** unos 68 viajes al motor (inferido del código). Bajo carga, cada viaje cuesta de 1 a 2 ms, así que una compra normal la retiene unos 100 a 150 ms (inferido de su p50 de 174 a 233 ms). La compra con fecha anterior y la anulación ejecutan 20 recálculos completos (`KardexCosto`) dentro de ese tramo y llegan a 600 a 1.400 ms (p50 de 766 ms y p95 de 1.430 ms en la c1).

#### Cómo se forma el convoy (verificado con el muestreo de `t57-diag.txt`)

1. La compra C retiene X sobre `inv.Existencia(A)` mientras recalcula (`KardexCosto`) o entre dos viajes («inactivo»).
2. La venta V1 tiene la serie `FacturaPos` y su lote ejecuta `UPDATE inv.Existencia` sobre A: **espera a C**. Hay 60 + 30 muestras «espera `UPDATE inv.Existencia … @l2_ex/@l3_ex` | bloqueador `SELECT m.Id … (KardexCosto)`» y 31 + 13 con bloqueador inactivo.
3. V2 a V6 esperan la serie detrás de V1: 106 + 52 muestras «espera serie | bloqueador `UPDATE inv.Existencia … @l2_ex/@l3_ex`» (es la venta V1) y 774 muestras de serie detrás de serie (la cola).
4. Cuando C confirma, el convoy se vacía. Esas son las colas de 255 a 1.370 ms de la venta.

**Cuantificación (inferida del muestreo, un sondeo cada 100 ms durante 180 s, unas 1.800 lecturas):** hay alguna venta esperando la existencia en unas 134 lecturas, ≈ 7 % del tiempo. Si el POS entero está parado más de un 5 % del tiempo, el p95 cae dentro de los episodios de convoy y lo fija su duración. El modelo da lo mismo: cada artículo está bloqueado ≈ 0,1 (probabilidad de que una compra lo lleve) × [6/s × 0,1 s + 0,4/s × 0,6 s + 0,3/s × 0,6 s] ≈ 10 % del tiempo.

**Otras esperas del mismo muestreo, que no afectan a la venta:** 56 en `num.Serie` con bloqueador `KardexCosto` y 65 en `inv.ArticuloCosto`. Son de compra contra compra: la serie `FacturaCxp` se toma al principio (`Compras.cs`:174) y queda retenida durante los recálculos de la otra compradora. Esto explica la cola de la meta 5a (sección 4).

**Lo que no es la causa (verificado):**
- **Escaneos bajo `UPDLOCK` o granularidad:** todos los accesos que bloquean son búsquedas por clave única. `num.Serie` tiene el índice agrupado único `UQ_NumSerie_Serie (TipoCodigo, SucursalId)` (`NumConfiguracion.cs`:66), `inv.Existencia` usa su PK (`ArticuloId`, `AlmacenId`) con `ROWLOCK` (`ConsultasInventario.cs`:19-21) e `inv.ArticuloCosto` su PK (`:97`). Con 20 filas por compra no hay escalada (el umbral es de unas 5.000). En el muestreo no aparece ninguna espera de página ni de tabla.
- **Interbloqueos:** 0 en todos los tramos.

**Agravante (inferido):** cliente y servidor comparten 4 CPU. Con compras, `SOS_SCHEDULER_YIELD` pasa de 225 ms a 3.221 ms y aparecen 470 muestras de «serie retenida por un cliente inactivo»: el hilo del cliente que tiene la serie espera CPU entre dos viajes. Por eso cada viaje que se quite del tramo con la serie vale más bajo carga que en reposo.

**Observación sobre la meta 1 en T-57:** incluso **sin compras**, el diagnóstico de T-57 da p95 de 55,1, 76,9 y 59,3 ms (`t57-c1`, `t57-c2`, `t57-diag`), con tramos de 60 s inmediatamente después del calentamiento con compras. Quitar el convoy no basta para garantizar 52 ms en T-57 en este equipo: hace falta también V1.

### 1.2 H-QA4-04: T-28 sin compras (p95 de 61,7 ms frente a 42,2 y 45,4)

**Comparación medida, sentencia por sentencia** (T-28 de la ola 4, `t28.txt`, frente a la corrida 1 de C-1, `corrida1.log`):

| Medida | C-1 (ola 3) | T-28 (ola 4) | Cambio | Lectura |
|---|---|---|---|---|
| Ventas/s con 6 cajeros | 174,4 | 142,6 | −18 % | La serie queda retenida 5,73 → 7,01 ms por venta (1/rendimiento) |
| Espera `LCK_M_U` en la serie por venta | 6,17 ms | 7,98 ms | +29 % | Cola más larga |
| `TR_Documento_Credito` por ejecución (**sin cambios en la ola 4**) | 0,046 ms | 0,051 ms | **+11 %** | Señal de CPU más lenta |
| CPU de `INSERT doc.Documento` por venta | 0,249 ms | 0,282 ms | **+13 %** | Ídem |
| CPU de `INSERT caja.Movimiento` por ejecución | 0,279 ms | 0,312 ms | **+12 %** | Ídem |
| `TR_Documento_Emision` por ejecución | 0,249 ms | 0,277 ms | +11 % | Ídem (el parche de 51321 no se nota) |
| CPU de la emisión (`UPDATE … Estado = 1`) por venta y lecturas | 0,83 ms; 94 | 1,01 ms; 103 | +0,17 ms; +9 | +12 % de CPU general, más unos 0,07 ms y 9 lecturas de las salidas tempranas de `Ola4` y `Ola4b` |
| **`TR_Documento_Ola4` / `Ola4b` en el tramo de T-28** | — | **0,018 / 0,022 ms por ejecución** (801 y 982 ms en 44.910 ejecuciones) | +0,07 ms por venta | **Coincide con DQ-3** (+0,06 ms) |
| Comandos por venta | 35,5 | 35,5 | igual | El camino de la venta no cambió (`git diff 4007968 fa6dcff`: solo `ConfiguracionAsync`, la caja configurada y el almacén de la caja, todo antes de la transacción) |
| Siembra del Z / Z de 20.000 | 113 s / 0,251 s | 128 s / 0,304 s | +13 % / +21 % | Ídem |
| Condiciones | «Alto rendimiento», 15 min de enfriamiento, 3.092 MHz registrados | Sin registro de frecuencia; **empezó 39 s después** de c2 (17:27-17:36) y del diagnóstico (17:36-17:40:33) | — | Contra el procedimiento de C-1 |

**Diagnóstico:** el +11 a 13 % uniforme en sentencias que la ola 4 no tocó indica una CPU efectiva más lenta (es inferido, porque falta la frecuencia; en la ola 3, QA vio el mismo patrón en V.3 y no se repitió con enfriamiento). La venta está limitada por un recurso serial y el lazo es cerrado, de modo que +22 % en el tiempo con la serie tomada se convierte en +40 a 46 % en el p95. Los disparadores de la ola 4 aportan 0,07 ms de 7 ms (1 %). **H-QA4-04, tal como está redactado (causa: disparadores de DQ-3), no se sostiene con los datos del propio tramo.** El origen de la confusión es que T-57 informa `dm_exec_trigger_stats` **acumulado de toda la corrida** («disparadores (acumulado de la corrida)»), y esa media mezcla las emisiones de compras, pagos y caja chica, que sí ejecutan las reglas 51342 a 51353.

---

## 2. Opciones para H-QA4-03

Efecto en el p95 de la venta de T-57 con 6 cajeros (hoy de 255 a 297 ms). Todas las cifras de efecto son **inferidas**, con un margen de ±30 %.

| # | Opción | Efecto esperado en el p95 | Riesgo | Costo | ¿Cambia el orden único? |
|---|---|---|---|---|---|
| **A1** | **Compra: existencia al final.** En `LibroInventario.AplicarAsync`: (1) `CostoBloqueado` de todos los artículos en **un lote**, en orden de llave, con la existencia global en el mismo viaje; (2) kárdex; (3) costo incremental o recálculo y `GuardarCosto` en lote; (4) último costo en lote; (5) situación, CxP, 606 y bitácora; (6) **un solo lote final: existencia, lotes y emisión**, con la emisión condicionada a que no falte existencia; (7) `COMMIT`. La existencia queda retenida de 3 a 8 ms en vez de 100 a 800 ms. Vale también para la anulación (`RevertirAsync`), la devolución a suplidor y las entradas y ajustes que pasan por `AplicarAsync`. | **255-297 → 55-70 ms** (desaparece el convoy y queda la competencia por CPU) | **Medio-bajo.** (a) El orden de los mensajes de error cambia: en la anulación, 422 «compra con pagos» antes que el faltante de existencia. Hay que revisar las pruebas que fijan ese orden. (b) Se amplía la ventana entre la lectura de `inv.ExistenciaGlobal` y la aplicación (ya existe hoy: `CostoPromedioNg.cs`:51 la lee sin bloqueo antes de `:123`). No es una anomalía nueva, pero las conciliaciones de T-57 deben seguir en 0. (c) Ningún recurso nuevo antes de la existencia: solo filas nuevas o filas ya protegidas por un nivel anterior, así que no puede haber ciclos. | 0,5 a 0,7 sp (backend 0,4 a 0,5 y pruebas 0,1 a 0,2) | **Sí, dentro del nivel «saldos»**: el blueprint R-1, paso 5, pone la existencia antes del último costo y la CxP. Es una precisión técnica de ADR-45 del tipo de D-5, con **firma ligera (F-a)**. Los niveles globales no cambian. |
| A2 | Recalcular el costo **fuera** de la transacción (en diferido, después del `COMMIT`) | Igual que A1 en la venta | **Alto:** el costo queda desfasado entre el `COMMIT` y el recálculo (una venta intermedia toma un costo viejo) y se rompe MD-42, que exige el costo vigente al confirmar | 0,6 sp | No | 
| A3 | **Índice para `KardexCosto`:** `IX_Movimiento_ArticuloFecha` (`InvConfiguracion.cs`:89-90) no incluye `Clase` ni `DocumentoId`, y la ola 4 agregó el `JOIN doc.Documento` (`ConsultasInventario.cs`:129, diff contra `4007968`). Cada fila hace una búsqueda de clave y otra en `doc.Documento`. Propuesta para arquitecto-datos: agregar `Clase` y `DocumentoId` al `INCLUDE`, o marcar la salida de la devolución a suplidor en el propio movimiento para no unir con `doc.Documento` | Sin A1: 255-297 → 150-200 ms (acorta las retenciones largas). **Con A1: nada en la venta**, pero baja la compra con fecha anterior y la cola de la meta 5a | Bajo: el índice crece unos 10 bytes por fila; las ventas lo pagan al insertar el kárdex, **fuera** del tramo con la serie | 0,15 a 0,25 sp (datos y backend) | No |
| B | **Venta: existencia antes de la serie** | Solo: 255-297 → 70-120 ms (un 7 a 10 % de las ventas sigue esperando a la compra, ahora sin la serie) | **Alto:** invierte «saldos» y «serie» solo para la venta. Ciclo posible: la venta retiene `Existencia(A)` y espera el NCF B02, mientras una factura de oficina retiene el NCF B02 y espera `Existencia(A)`. Para evitarlo habría que llevar la existencia antes de la serie en **todos** los documentos | 1,5 a 3 sp con la revisión de concurrencia | **Sí, el orden global**: firma. **No recomendada** |
| B' | **Barrera sin retener:** antes de la serie, `SELECT 1 FROM inv.Existencia WITH (READCOMMITTEDLOCK)` sobre los artículos de la venta, en el mismo viaje que la lectura previa. Espera a la compra y no retiene nada | Solo: 255-297 → 70-110 ms. Con A1: marginal | Bajo: no retiene, así que no crea ciclos (la compra que retiene la existencia no espera nada de lo que la venta tiene antes de la serie; hoy ya ocurre lo mismo con la serie tomada y hay 0 interbloqueos) | 0,1 a 0,15 sp | No |
| **V1** | **Reducir el tramo con la serie de 7 viajes a 3:** (1) **toma rápida** en un solo lote: el cliente formatea con `ReglasNumeracion.Formatear` los candidatos a partir del `Siguiente` de la lectura previa (por ejemplo, 32). El lote bloquea la fila, lee `Siguiente` y, si cae en la lista, no está ocupado y no está cerca del techo, actualiza y devuelve el número. Si no, devuelve «camino completo» y sigue el código de hoy con la fila **ya bloqueada**. (2) **El lote de la venta lleva también la emisión y la línea de `_LOG`** (`INSERT dbo._LOG` directo, como `SeriesNumeracion.cs`:559), con la emisión condicionada a que no falte existencia. (3) `COMMIT`. Además, el `SET LOCK_TIMEOUT` va con la lectura previa (un viaje menos fuera del tramo) | Tiempo con la serie: −2,0 a −2,7 ms (de 7,0 a unos 4,5 ms; cada viaje cuesta unos 0,5 ms de cliente y red además del motor: `UPDATE num.Serie` 0,08 ms en el motor y 0,59 ms medidos en el cliente). **p95 de T-28: −10 a −25 %**, menos que lo proporcional porque la CPU está al 89 % | **Medio:** toca la numeración (ADR-45 y ADR-48, sin huecos). Se mitiga con el camino completo como respaldo, la misma fila y el mismo modo de bloqueo, el formato solo en C# y la batería de numeración existente (B7, `NumeracionB7*`). El mensaje de error de existencia cambia de lugar si la emisión va en el lote, y se resuelve con la guarda | 0,6 a 0,9 sp | **No:** mismos recursos y mismo orden, con menos viajes. Es coherente con la decisión de ADR-72 («solo los comandos imprescindibles») |
| G | Granularidad (`ROWLOCK`, índices que eviten escaneos bajo `UPDLOCK`) | Ninguno | — | 0 | — Descartada: ya son búsquedas por clave única con `ROWLOCK` (sección 1.1) |
| S | Adelantar la **serie por caja** (decisión (b) del propietario para la entrega 2) | Elimina el convoy de raíz: la venta que espera solo detiene su propia caja | Cambia la numeración que ve el usuario y requiere la precisión de ADR-45 pendiente | 2 a 4 sp (inferido) | Firma de ADR-45. Se queda en la entrega 2, salvo que A1 + V1 no basten |

---

## 3. Remedio para H-QA4-04

1. **Repetir T-28 con el procedimiento de C-1** (ya firmado): plan «Alto rendimiento», máquina sola, 15 min de enfriamiento **antes** de cada corrida, frecuencia registrada (`frec.ps1` de C-1) y **T-28 antes de T-57**, no después. Con el código de hoy espero de 44 a 50 ms (inferido de +0,07 ms de disparadores y +0,1 ms de emisión sobre 42,2 y 45,4).
2. **Disparadores de DQ-3: no se tocan.** Cuestan 0,04 ms por venta. Fundirlos con `TR_Documento_Emision` ahorraría unos 0,02 ms (0,3 % del tramo) a cambio de mezclar las reglas del POS con las de compras, CxP y bancos, que DQ-3 separó a propósito. *Alternativa descartada:* mover sus validaciones al servicio, porque se pierde la red del motor (CA-01) y la ganancia es la misma.
3. **Corregir el instrumento:** T-57 debe informar `dm_exec_trigger_stats` **como diferencia por tramo** (como ya hace T-28) y no como acumulado. Es una tarea de QA de unas 0,05 sp.
4. **V1** da margen permanente: si T-28 vuelve a 44 a 50 ms con el equipo frío, V1 la lleva a unos 36 a 42 ms (inferido), lejos de los 52.

---

## 4. Meta 5a (compra de 20 líneas, propuesta de 250 ms; D-4)

**Lo que mide hoy:** `CargaOla4Tests.cs`:439 junta en un solo percentil el tramo de 6 cajeros y el de 12 (saturado: venta p95 ≈ 1 s). Con 6 cajeros: p50 de 174 y 186 ms, p95 de 610 y 646 ms. La cola no es el costo de la compra: es la espera de la serie `FacturaCxp` y de `inv.ArticuloCosto` detrás de la otra compradora cuando hace una compra con fecha anterior o una anulación (56 + 65 muestras). La compra B11, con el mismo trabajo y menos muestras, da p95 de 240 y 285 ms.

**Recomendación:** recalibrar, **pero no con las cifras de hoy**, porque incluyen el convoy que A1 elimina:
- **Meta 5a: p95 ≤ 400 ms** de la factura de 20 líneas, **solo en el tramo de 6 cajeros**, en las dos corridas. Alerta sin bloqueo si pasa de 250 ms. El tramo de 12 cajeros queda informativo.
- **Argumento:** (a) el volumen real es de 10 a 300 compras al mes con 1 a 3 usuarios ([POS4] 1.1, citado en el blueprint 14.3), y la carga simula unas 6 por segundo, más de 50.000 veces el pico. La cola mide la competencia entre compradoras, que en la práctica no existe. (b) Para un usuario de oficina que tarda minutos en cargar 20 líneas, 400 ms no se notan (el umbral de respuesta «inmediata» suele situarse entre 0,1 y 1 s). (c) Con A1 y A3 espero un p50 de 90 a 120 ms y un p95 de 250 a 350 ms con 6 cajeros (inferido ±30 %): 400 ms deja margen en este i5 de 35 W sin esconder una regresión real, que la alerta de 250 ms detectaría.
- La meta 5b (≤ 2 s con 5.000 movimientos posteriores) ya se cumple (1,45 y 1,47 s) y A3 la aleja más. Sin cambio.
- Si la primera corrida después de A1 da un p95 ≤ 250 ms con 6 cajeros, propongo **mantener 250** y que F-b solo cambie el tramo en que se mide.

---

## 5. Recomendación única y plan para el backend

**Recomendación: A1 + V1, con A3 como paso separable de datos.** A1 elimina la causa del rechazo; V1 da el margen que T-28 y T-57 no tienen hoy en este equipo; A3 baja la compra con fecha anterior y la cola de la meta 5a. B' queda en reserva: solo se aplica si, después de A1, el muestreo todavía muestra esperas de la venta en `inv.Existencia`. *Descartadas:* B (cambia el orden global con riesgo de 1205), A2 (rompe MD-42), G (sin efecto) y S por ahora (entrega 2).

**Costo total:** de 1,4 a 2,0 sp (inferido ±30 %): A1 de 0,5 a 0,7; V1 de 0,6 a 0,9; A3 de 0,15 a 0,25; repetición de QA de 0,3 a 0,4 sp y unas 3 h de máquina. Sin costo de infraestructura ni de licencias.

### Pasos (en este orden; un commit por paso)

1. **A1 en `LibroInventario` y `CostoPromedioNg`.**
   - `CostoPromedioNg.PrepararAsync` (`:42-53`): un `LoteComandos` con un `CostoBloqueado` (y `CrearCosto` si falta) por artículo **en orden de llave**, más `ExistenciaGlobal`. Son sentencias separadas dentro del lote para que el orden de los bloqueos lo fije el código y no el plan.
   - `AplicarAsync` (`:115-135`): orden nuevo: costo → kárdex (`SaveChanges`) → `ActualizarAsync` con los `GuardarCosto` en lote → devuelve un **`ExistenciasEnLote` pendiente** (el patrón de `AgregarExistencias`, `:186-220`) en vez de aplicar la existencia. Hay que mantener la firma actual para los llamadores que no difieren (ventas de oficina, inventario) o migrarlos todos. Recomiendo migrarlos todos: la regla queda única.
   - `ComprasNg.ActualizarUltimoCostoAsync` (`ComprasNg.cs`:68-73) y `ReponerUltimoCostoAsync` (`:76-80`): en lote.
2. **A1 en compras y anulación.** `DocumentosComercialesService.Compras.cs`:236-266 y la anulación (`:425-436`): la existencia (y `inv.ExistenciaLote`) va en el lote final con la emisión. La emisión se ejecuta solo si no falta existencia (variable de guarda en el lote) y `Exigir()` lanza el 422 con el mismo texto de hoy. Lo mismo para la devolución a suplidor.
3. **V1, toma rápida de la serie.** En `SeriesNumeracion.TomarAsync` (`:62-150`), el camino rápido descrito en la sección 2. El camino completo de hoy queda como respaldo, sin cambios, y se entra en él con la fila ya bloqueada. El cambio de subserie y el bloqueo de configuración cerca del techo se resuelven **antes**, con la lectura previa, igual que hoy (`:77-84`).
4. **V1, lote único de la venta.** En `PosService.cs`:286-318: emisión (`EmitirNumerando`) y la línea de `_LOG` dentro del lote, con la guarda de existencia. `ConfirmarAsync` queda solo para el `COMMIT`: no debe haber cambios pendientes en ninguno de los dos contextos. Hay que comprobarlo con una aserción en la prueba de comandos.
5. **A3 (arquitecto-datos lo diseña y backend lo aplica):** migración del índice de `KardexCosto`.
6. **Pruebas nuevas o ajustadas** (sin carga):
   - Contador de comandos con la serie tomada en la venta: **3** (lote de serie, lote de la venta y `COMMIT`), con una aserción sobre el interceptor de diagnóstico.
   - Numeración: toma rápida contra camino completo con números ocupados, cerca del techo, cambio de subserie, serie de sucursal y rollback (ADR-45/48: sin huecos ni repetidos). Se reutiliza la batería `NumeracionB7*`.
   - Compra: el orden de los mensajes de error (faltante, CxP con pagos, NCF repetido); la existencia y el costo iguales que antes del cambio para el mismo guion (prueba de equivalencia con recálculo completo); `ConciliacionExistencia` en 0.
   - Concurrencia: una venta y una compra sobre el mismo artículo con un retraso inyectado después del kárdex de la compra. La venta no debe esperar más que el lote final (aserción < 50 ms).
7. **Suite completa, Web, MAUI y G-1.5** en verde antes de pasar a QA.

### Cómo repetir T-28 y T-57 (procedimiento para QA)

- Equipo solo, plan «Alto rendimiento», frecuencia registrada durante cada corrida (`frec.ps1`) y procesos huérfanos revisados antes de empezar (incluidos bash y pwsh).
- **Orden:** T-28 c1 → 15 min → T-28 c2 → 15 min → T-57 c1 (`GPOST_B9_MUESTREO=1`) → 15 min → T-57 c2. Unas 3 h.
- T-28: `GPOST_B9=1 GPOST_TEST_SERVER=.\SQLEXPRESS GPOST_B9_MINUTOS=3 dotnet test --filter FullyQualifiedName~CargaOla3Tests`.
- T-57: lo mismo, con `CargaOla4Tests`, `GPOST_B9_CALENTAR=60` y `GPOST_B9_MUESTREO=1`.
- **Cambios previos en el instrumento** (QA, unas 0,05 sp): disparadores como diferencia por tramo; meta 5a solo con el tramo de 6 cajeros si se firma F-b; informe de las esperas de la venta en `inv.Existencia` como cifra propia (el criterio de éxito de A1: menos de 10 muestras en 180 s, frente a 134).
- **Criterios:** T-28 con p95 ≤ 52 en las dos corridas; T-57 con meta 1 ≤ 52 en las dos corridas, 0 errores 1205, conciliaciones en 0, 0 repetidos, meta 5a según F-b, 5b ≤ 2 s y meta 6 ≤ 100 ms.

**Resultado esperado (inferido ±25 %):** T-28 de 36 a 42 ms. T-57, meta 1, de 45 a 55 ms. **Es posible que T-57 no llegue a 52 en este equipo** aunque el convoy desaparezca, porque la carga de compras y pagos, exagerada a propósito, le quita CPU a la venta con el cliente y el motor en las mismas 4 CPU. Para ese caso está F-c.

---

## 6. Qué requiere firma del propietario

| # | Decisión | Opciones | Recomendación |
|---|---|---|---|
| **F-a** | **Precisión técnica de ADR-45 (orden dentro del nivel «saldos»):** en la compra, la anulación, la devolución a suplidor y todo documento que pase por el libro de inventario, la **existencia se aplica al final del nivel «saldos»**, en el mismo lote que la emisión, después del costo, el último costo, la situación de la orden, la CxP y el 606. Los niveles globales (documentos → configuración → serie → NCF → saldos) no cambian. | A. Aprobar · B. Rechazar (sin A1: solo V1, A3 y B'; la meta 1 de T-57 seguiría fallando con unos 150 a 200 ms) | **A. Aprobar.** Lo que se adelanta son filas nuevas o filas ya protegidas por un nivel anterior: no puede crear ciclos. Es la misma técnica que ADR-72 aplicó a la venta («lo que no depende del recurso disputado, antes»). |
| **F-b** | **Meta 5a (D-4):** p95 de la factura de compra de 20 líneas **≤ 400 ms en el tramo de 6 cajeros** (dos corridas), con alerta a 250 ms; el tramo de 12 cajeros, informativo. Se aplica en la primera corrida **después** de A1. Si esa corrida ya da ≤ 250 ms, se mantiene 250 y solo cambia el tramo. | A. Aprobar · B. Mantener 250 ms con los dos tramos juntos · C. Otra cifra | **A.** Argumento en la sección 4: la carga multiplica el volumen real por más de 50.000 y 400 ms no se notan en una pantalla de oficina. |
| **F-c** | **Contingencia de la meta 1 en T-57** (solo si, después de A1 + V1, T-28 cumple ≤ 52 en las dos corridas y el muestreo muestra menos de 10 esperas de la venta en `inv.Existencia`, pero T-57 da más de 52): en T-57, la meta 1 pasa a ser **p95 con compras ≤ 1,15 × p95 sin compras de la misma corrida** (tramo de diagnóstico ampliado a 3 min) **y ≤ 60 ms absolutos**. T-28 sigue siendo el criterio absoluto de 52 ms. | A. Aprobar la contingencia · B. Exigir 52 ms también en T-57 (si no se alcanza, adelantar la serie por caja, S, de 2 a 4 sp) | **A.** Con cliente y motor en 4 CPU, la carga de compras exagerada mide competencia de CPU, no de bloqueos. Lo que la ola 4 tiene que demostrar es que no hay convoy ni 1205, y eso lo comprueban el muestreo y la meta 2. |

**Sin firma:** V1 (mismos bloqueos y mismo orden, con menos viajes, dentro de lo decidido en ADR-72), A3 (índice), B' (lectura sin retener, en reserva) y el ajuste del instrumento de QA.

---

### Cierre
- Estado: Completado
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\rendimiento-ola4-propuesta-2026-10-07.md`
- Supuestos: las cifras de efecto son inferidas (±25 a 30 %); la CPU más lenta en T-28 es inferida (no hay registro de frecuencia); el recuento de viajes con la existencia retenida (≈ 68) se deriva del código, no de una traza; el volumen real de compras es el de [POS4] 1.1 citado en el blueprint; el sp sigue la escala de los documentos del proyecto
- Decisiones candidatas a ADR: F-a (precisión técnica de ADR-45: existencia al final del nivel «saldos»); F-b y F-c (recalibración de metas de T-57, D-4); V1 como precisión técnica de ADR-72 (toma rápida de la serie con respaldo al camino completo), sin firma
- Entregas a otros agentes: arquitecto-maestro → hoja de firma F-a, F-b y F-c; desarrollador-backend → pasos 1 a 4, 6 y 7; arquitecto-datos → A3 (índice de `KardexCosto` o marca de revaluación en el movimiento); QA → ajustes del instrumento y repetición con el procedimiento de C-1
- Próximo paso recomendado: el Maestro presenta F-a, F-b y F-c al propietario; mientras tanto, el backend puede empezar por V1, que no requiere firma
