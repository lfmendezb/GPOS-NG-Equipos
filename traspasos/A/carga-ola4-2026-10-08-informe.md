# [Informe QA] Carga de cierre de la ola 4: T-28 y T-57 (procedimiento C-1)

- **Fecha:** 2026-10-08 · **Agente:** qa-automatizado (equipo A), el único agente activo durante las corridas
- **Árbol y código:** `GPOS-NG-numeracion`, rama `feature/modelo-ng`, HEAD `f21b788` (incluye V1 `f5ce0c5`, A1 `7f3eaca`, A3 `06939eb`, el instrumento de T-57 `896551c` y H-R01). Árbol limpio. Sin cambios en el código de producción ni en las pruebas. Sin push.
- **Procedimiento:** C-1 (`docs/decisiones/2026-10-06-cierre-ola3.md` 3.3) y la propuesta de rendimiento de la ola 4 (`rendimiento-ola4-propuesta-2026-10-07.md` §5, «Cómo repetir T-28 y T-57»).
- **Salidas completas:** esta carpeta (`t28-1.txt`, `t28-2.txt`, `t28-2-contaminada.txt`, `t57-1.txt`, `t57-2.txt`, `frec-*.csv` con la frecuencia muestreada cada 5 s, `frecuencias.txt` con las instantáneas de inicio y fin, `bitacora.txt` y `build-release.txt`).

## 1. Alcance probado

| Corrida | Prueba | Enfriamiento previo | Inicio y fin | Resultado de la prueba |
|---|---|---|---|---|
| t28-1 | `CargaOla3Tests` (T-28), `GPOST_B9=1`, `GPOST_B9_MINUTOS=3`, calentamiento de 60 s | 07:33:31 a 07:48:37 (15 min) | 07:48:37 a 08:01:03 | FAIL: p95 66,2 > 52 |
| ~~t28-2~~ | T-28 | 08:01:07 a 08:16:14 | 08:16:14 a 08:29:56 | **Descartada (contaminada)**: a las 08:19:00 se restauró POS_EUREKAKIDS en `.\SQLEXPRESS` y hubo consultas sobre ella hasta cerca de las 08:35 (aviso del coordinador, confirmado en `msdb.restorehistory` y en el registro del motor). Se dejó como `t28-2-contaminada.txt` (0,8 ventas/s) |
| t28-2 (repetida) | T-28 | 08:36:01 a 08:51:08 (empieza después del fin de la actividad ajena) | 08:51:08 a 09:01:18 | FAIL: p95 74,9 > 52 |
| t57-1 | `CargaOla4Tests` (T-57), `GPOST_B9=1`, `GPOST_B9_MUESTREO=1`, minutos y calentamiento por omisión (3 min y 60 s) | 09:01:23 a 09:16:28 | 09:16:28 a 09:27:30 | FAIL en la meta 1 |
| t57-2 | T-57, igual | 09:33:23 a 09:48:30 | 09:48:30 a 09:59:36 | FAIL en la meta 1 |

En las dos pruebas, `GPOST_TEST_SERVER=.\SQLEXPRESS` (SQL Server 2019 Express 15.0.2190.7, 4 CPU, RCSI activado). La compilación fue Release, una sola vez antes de medir (0 errores y 5 advertencias EF100x en pruebas ya existentes), y las corridas usaron `--no-build`.

## 2. Condiciones

| Condición | Verificación | Estado |
|---|---|---|
| Plan de energía | `powercfg /getactivescheme` → «Alto rendimiento» (`8c5e7fda…`) antes de empezar y en cada instantánea | Cumple (no se cambió) |
| Máquina sola | Al empezar había 3 nodos de MSBuild y un VBCSCompiler **inactivos** (0 s de CPU en 5 s, con el padre ya terminado). Se cerraron con `dotnet build-server shutdown`. Antes de cada corrida, 0 `dotnet` y 0 `testhost` (`frecuencias.txt`, campo «dotnet/testhost previos: []») | Cumple, con esa salvedad |
| Enfriamiento de 15 min antes de cada corrida | `bitacora.txt`: 15:05 a 15:07 min en las cinco | Cumple |
| Frecuencia al inicio y al final | Instantáneas en `frecuencias.txt`; muestreo cada 5 s en `frec-*.csv` | Ver la tabla siguiente |
| Instancia `MSSQLSERVER` (2025) | En marcha. No se detuvo porque es configuración del sistema. El tiempo de CPU de `sqlservr` no se puede leer sin elevación (aparece como 0) | Riesgo residual bajo (inferido: sin carga) |
| Actividad propia durante los enfriamientos | Lecturas de archivos y consultas de metadatos de menos de 1 s (registro del motor, `msdb`) entre 08:36 y 09:33. Ninguna durante las corridas | Declarada |

| Corrida | MHz efectivos (inicio / fin) | Media / mínimo durante la corrida | Muestras con límite de rendimiento | CPU media |
|---|---|---|---|---|
| t28-1 | 3.119 / 3.254 | 3.107 / 3.092 | 0 | 80 % |
| t28-2 | 3.254 / 3.119 | 3.095 / 3.037 | 0 | 89 % |
| t57-1 | 3.119 / 3.282 | 3.098 / 3.092 | 0 | 88 % |
| t57-2 | 3.227 / 3.254 | 3.100 / 3.092 | 0 | 87 % |

Nominal: 2.712 MHz (`CurrentClockSpeed` = `MaxClockSpeed`). La frecuencia efectiva se mantuvo en unos 3,1 GHz, la misma que C-1 registró en la ola 3 (3.092 MHz), sin limitación térmica ni de potencia. **Esta vez el resultado no se puede atribuir a una CPU lenta.**

**Salvedad sobre t28-1** (inferido; se mantiene válida por indicación del coordinador): tiene tres señales que no aparecen en t28-2 ni en C-1.
- Esperas de instancia `LCK_M_X` (607 tareas, 70,6 s) y `LCK_M_SCH_M` (318 tareas).
- Estadísticas de sentencias perdidas en mitad del tramo: 32,7 ejecuciones por venta frente a 76,8, y «0 sentencias de TR_Documento_Emision en caché».
- Una máxima de 7,6 s.

Además, el registro del motor muestra que una sesión ajena abrió 14 bases `GPOS_TEST_*` huérfanas (con AUTO_CLOSE) entre las 07:43:07 y las 07:43:17, durante el enfriamiento. Nada de esto cambia el veredicto: t28-2, limpia y verificada (el registro del motor de 08:25 a 09:10 solo muestra su propia base), también incumple.

## 3. Trazabilidad y resultados, meta por meta

### T-28 (criterio de C-1 y condición de F-c)

| Criterio | t28-1 | t28-2 | Meta | Estado |
|---|---|---|---|---|
| p95 de la venta, 6 cajeros | **66,2 ms** (64,0 ventas/s; p99 2.007, máx. 7.610) | **74,9 ms** (141,5 ventas/s; p50 36,6; p90 60,5; p99 125,3; máx. 521) | ≤ 52 en las dos | **No cumple** |
| Comparación con la línea base de Express (44,5) | +48,8 % | +68,3 % | informativa | — |
| 1205 con 12 cajeros | 0 (24.611 ventas, p95 139,1) | 0 (28.049 ventas, p95 116,6) | 0 | Cumple |
| Z de 20.000 | 0,273 s | 0,263 s | ≤ 0,5 s | Cumple |
| Conciliación | 0 filas | 0 filas | 0 | Cumple |
| Números y NCF repetidos | 0 y 0 (de 11.140) | 0 y 0 (de 18.647) | 0 | Cumple |
| 8.2 (5): `TR_Documento_Emision` / `TR_Documento_Credito` por ejecución | 0,325 / 0,061 ms | 0,316 / 0,060 ms | < 0,4 / < 0,1 | Cumple |
| 8.2 (6): recorridos o concesión de memoria en la emisión | 0 sentencias en caché (sin datos: caché vaciada) | 9 sentencias, solo búsquedas | ninguna | Cumple en t28-2 |

### T-57 (blueprint de la ola 4, 14.3; F-b y F-c firmadas el 2026-10-07)

| Meta | t57-1 | t57-2 | Meta firmada | Estado |
|---|---|---|---|---|
| **1** p95 de la venta, 6 cajeros con compras | **106,0 ms** | **108,6 ms** | ≤ 52 | **No cumple** |
| 1, contingencia F-c: p95 sin compras de la misma corrida → límite | 40,2 → 46,3 | 42,3 → 48,7 | ≤ mín(1,15 × sin compras; 60) | **No cumple** (106 y 108,6 son 2,6 veces el p95 sin compras) |
| 1, condiciones de F-c: T-28 ≤ 52 en las dos corridas | No (66,2 y 74,9) | — | obligatorio | **F-c no aplica** |
| 1, condiciones de F-c: esperas en `inv.Existencia` (muestreo) | 18 | 15 | < 10 | **No cumple** (ver O-1) |
| 1, alerta: p95 > 48,2 ms | Sí | Sí | sin bloqueo | — |
| **2** 1205 con 12 cajeros (cliente y motor) | 0 (0 y 0) | 0 (0 y 0) | 0 | Cumple |
| **3** Conciliaciones (existencia, CxC, CxP, saldo a favor, bancos y otras: 11 vistas) | 0 | 0 | 0 filas | Cumple |
| **4** Números, NCF (B02, B11 y B13) y cheques repetidos | 0, 0 (de 22.465) y 0 | 0, 0 (de 22.153) y 0 | 0 | Cumple |
| **5a** p95 de la compra de 20 líneas, **solo con 6 cajeros** | **1.033,5 ms** (p50 241,9) | **992,3 ms** (p50 238,4) | ≤ 400; alerta a 250 | **No cumple**; alerta sí |
| 5a con 12 cajeros (informativo) | 1.502,3 | 1.414,2 | — | — |
| **5b** compra con fecha anterior y 5.000 movimientos posteriores | 1.101,0 ms | 1.208,2 ms | ≤ 2.000 | Cumple |
| **6** p95 del pago con 3 aplicaciones y retención (6 + 12 cajeros, como lo calcula la prueba) | **121,1 ms** | **142,2 ms** | ≤ 100 | **No cumple** |
| 6, solo el tramo de 6 cajeros (referencia) | 116,1 | 108,8 | — | Tampoco cumple |
| 6, saldos de CxP negativos | 0 | 0 | 0 | Cumple |

La aserción de la meta 1 detiene la prueba (`CargaOla4Tests.cs:491`), así que las metas 5a y 6 no llegan a evaluarse como aserción. Sus cifras salen de la línea «metas:» de la salida, que se calcula antes.

### Disparadores por tramo (diferencia; ms por ejecución; t57-1 / t57-2)

| Disparador | 6 sin compras | 6 con compras | 12 con compras | Meta 5 |
|---|---|---|---|---|
| `doc.TR_Documento_Emision` | 0,251 / 0,262 | 0,255 / 0,265 | 0,263 / 0,263 | 0,217 / 0,211 |
| `doc.TR_Documento_Credito` | 0,040 / 0,048 | 0,045 / 0,053 | 0,045 / 0,053 | 0,037 / 0,041 |
| `doc.TR_Documento_Ola4` | 0,017 / 0,017 | **0,270 / 0,372** | 0,125 / 0,123 | 0,017 / 0,016 |
| `doc.TR_Documento_Ola4b` | 0,020 / 0,021 | 0,076 / 0,079 | 0,063 / 0,061 | 0,019 / 0,018 |
| `compras.TR_CompraLinea_Inmutable` | — | 0,736 / 0,642 | 1,562 / 1,545 | 0,818 / 0,746 |
| `cxp.TR_Aplicacion_Inmutable` | — | 0,056 / 0,051 | 0,071 / 0,067 | — |

Lectura (inferida): en la venta, `TR_Documento_Ola4` cuesta 0,017 ms, lo mismo que en el tramo sin compras. La media de 0,27 a 0,37 ms del tramo con compras sale de unas 1.000 emisiones de compras y pagos: 44.434 × 0,372 ≈ 16,5 s, de los que unos 15,8 s corresponden a esos documentos, es decir, unos 15 ms por emisión que no es de POS. Ese tiempo corre dentro de la transacción de la compra.

## 4. Cobertura

No aplica: es una corrida de carga sin cambios de código. La política de cobertura no se evalúa en este encargo.

## 5. Defectos

### H-C1-01 (Alta). T-28 incumple p95 ≤ 52 ms con 6 cajeros en las dos corridas válidas

- **Reproducción:** en `f21b788`, máquina sola, plan «Alto rendimiento», 15 min de enfriamiento; `dotnet build tests/GPOS.Tests -c Release`; después `GPOST_B9=1 GPOST_TEST_SERVER='.\SQLEXPRESS' GPOST_B9_MINUTOS=3 dotnet test tests/GPOS.Tests -c Release --no-build --filter "FullyQualifiedName~CargaOla3Tests"`.
- **Esperado:** p95 ≤ 52 ms (la propuesta estimaba de 36 a 42 ms con V1).
- **Obtenido:** 66,2 y 74,9 ms (`t28-1.txt`, `t28-2.txt`; aserción en `CargaOla3Tests.cs:210`).
- **Evidencia del diagnóstico** (t28-2 frente a la corrida 1 de C-1, `corrida1.log` del 2026-10-06, con la misma frecuencia efectiva de unos 3,1 GHz):
  - **V1 hace lo que promete:** la espera de la serie en el motor baja de 6,21 a 2,32 ms por venta, y la toma completa en el cliente, de 6,82 a 3,31 ms. Las esperas `LCK_M_U` bajan de 6,17 a 2,28 ms por venta.
  - **El cuello de botella es la CPU:** la CPU del motor por venta sube de 4,64 a 5,78 ms (+25 %; 145.548 ms en 31.388 ventas frente a 147.071 ms en 25.465), con 74,2 frente a 76,8 sentencias por venta. Con el cliente y el motor en las mismas 4 CPU al 89 %, cada lectura simple previa a la transacción pasa de unos 0,46-0,51 ms a unos 0,83-0,89 ms, y el rendimiento cae de 174,4 a 141,5 ventas/s.
  - La emisión cuesta 1,06 ms de CPU por venta frente a 0,83.
  - La distribución de los +1,1 ms por sentencia y por función de la ola 4 no se aisló. Queda para el desarrollador.
- **Consecuencia:** no se cumple la condición de F-c, de modo que la meta 1 de T-57 queda sin contingencia.

### H-C1-02 (Alta). T-57, meta 1: p95 de la venta con compras de 106,0 y 108,6 ms; F-c no aplica

- **Reproducción:** las mismas condiciones; `GPOST_B9=1 GPOST_B9_MUESTREO=1 GPOST_TEST_SERVER='.\SQLEXPRESS' dotnet test tests/GPOS.Tests -c Release --no-build --filter "FullyQualifiedName~CargaOla4Tests"`.
- **Esperado:** ≤ 52 ms, o la contingencia F-c (≤ 46,3 y ≤ 48,7 en estas corridas, siempre que T-28 cumpla y haya < 10 esperas en `inv.Existencia`). La propuesta estimaba de 45 a 55 ms después de A1 + V1.
- **Obtenido:** 106,0 y 108,6 ms (`CargaOla4Tests.cs:491`), con 18 y 15 esperas en `inv.Existencia`. Sin compras, en la misma corrida, el p95 es de 40,2 y 42,3 ms.
- **Evidencia:**
  - A1 redujo el convoy de 255-297 a unos 107 ms, pero no lo eliminó.
  - En el tramo con compras, `SOS_SCHEDULER_YIELD` llega a 17,7 y 19,0 s (0,08 y 0,2 s sin compras) y `PAGELATCH_SH`/`EX` a 75 y 74 s (16 y 18 s sin compras): presión de CPU y de páginas.
  - El muestreo (t57-2) cuenta 473 esperas en `num.Serie` con el bloqueador «inactivo (cliente)», 415 detrás del lote de existencias, 250 detrás de la lectura `KardexCosto` (`SELECT m.Id, m.Fecha, … CONVERT`) y 235 + 123 en `inv.ArticuloCosto`.
  - El muestreo no distingue si la sesión que espera es una venta o una compra (ver O-1), así que no puedo atribuir con certeza la parte de la venta.

### H-C1-03 (Alta). T-57, meta 5a: p95 de la compra de 20 líneas con 6 cajeros de 1.033,5 y 992,3 ms (meta ≤ 400)

- **Reproducción:** la misma de H-C1-02. La cifra está en la línea «metas: … (5)».
- **Esperado:** ≤ 400 ms (F-b); la propuesta estimaba de 250 a 350 ms con A1 + A3.
- **Obtenido:** p50 de 242 y 238 ms (cumpliría la alerta), pero una cola larga.
- **Evidencia:** la anulación de compra tiene un p50 de 1.431 y 1.527 ms, y la compra con fecha anterior dentro de la carga, de 1.122 y 1.016 ms. El muestreo muestra esperas en `inv.ArticuloCosto` detrás de `KardexCosto` y de `UPDATE k SET UltimoCostoCompra…`. Inferido: la cola es la compra que espera a otra compradora mientras esta recalcula el costo; `TR_Documento_Ola4` suma unos 15 ms por emisión que no es de POS dentro de esa transacción.

### H-C1-04 (Media). T-57, meta 6: p95 del pago con 3 aplicaciones y retención de 121,1 y 142,2 ms (meta ≤ 100)

- **Reproducción:** la misma de H-C1-02.
- **Esperado:** ≤ 100 ms.
- **Obtenido:** 121,1 y 142,2 ms (con 6 y 12 cajeros juntos, como lo calcula la prueba). Solo con 6 cajeros: 116,1 y 108,8. El p50 es de 37 a 52 ms.
- **Severidad:** Media, porque no se percibe en una pantalla de oficina y la carga es exagerada a propósito. Aun así es una meta firmada incumplida: el criterio no se alcanza sin una decisión del propietario.

### Observaciones (Baja)

- **O-1:** `esperasExistencia` (`CargaOla4Tests.cs`, después del tramo de 6 cajeros) cuenta toda espera sobre `inv.Existencia`, sea de una venta o de una compra. F-c habla de «esperas de la venta». El conteo sobreestima, de modo que es conservador. Se corrige filtrando por la sentencia que espera; es tarea de QA, unas 0,05 sp.
- **O-2:** el comentario de `MuestrearAsync` (`CargaOla4Tests.cs:279`) dice «no en las corridas oficiales», pero el procedimiento firmado de la propuesta §5 y F-c exigen `GPOST_B9_MUESTREO=1` en la corrida 1. Hay que alinear el texto.
- **O-3 (entorno):** en `.\SQLEXPRESS` hay 14 bases `GPOS_TEST_*` huérfanas con AUTO_CLOSE (de `GPOS_TEST_1abc38fb` a `GPOS_TEST_VAC_1fb8824d`), y una sesión ajena las abrió durante el enfriamiento de t28-1. No las toqué. Recomiendo que el coordinador las limpie antes de la próxima corrida de carga. Ver también la salvedad de t28-1 en la sección 2.
- **O-4:** la cifra de 8.2 (5) en T-28 usa `dm_exec_trigger_stats`, que el motor puede desalojar. En t28-1 dio 0,29 ejecuciones por venta y en t28-2, 1,75. La métrica por ejecución es estable (0,316 a 0,325 ms), pero «por venta» no es fiable.

## 6. Riesgos no cubiertos por pruebas

- La causa del +25 % de CPU del motor por venta frente a C-1 no está aislada por sentencia ni por función. Hace falta un perfil comparativo (por ejemplo, `RendimientoOla3Tests` con contadores de CPU por sentencia entre `4007968` y `f21b788`).
- No se midió en SQL Server 2025 ni en un equipo con más de 4 CPU. Con el cliente y el motor compartiendo 4 CPU, la carga exagerada mide sobre todo competencia de CPU (es inferido; lo apuntaba la propia propuesta §5).
- t28-1 tiene la salvedad de la sección 2. Una tercera corrida de T-28 no cambiaría el veredicto, porque la corrida limpia también incumple.

## 7. Recomendación técnica

**Rechazado** (recomendación técnica; la decisión es del propietario). Quedan abiertos tres hallazgos Altos (H-C1-01 a 03) y uno Medio (H-C1-04). Las metas de corrección se cumplen en las dos corridas: 0 errores 1205, conciliaciones en 0, 0 repetidos, la meta 5b, la emisión por ejecución y el Z. **Lo que falla es el rendimiento.** Las condiciones de medición se cumplieron y la frecuencia fue estable (unos 3,1 GHz, sin limitaciones), así que el resultado no se puede atribuir a ruido del equipo.

Para el propietario, por medio del Arquitecto Maestro, las opciones son:
- (a) un perfil de CPU por venta y el remedio del backend antes de repetir;
- (b) revisar las metas para este equipo de 4 CPU, con la línea base de la ola 0 actualizada;
- (c) adelantar la serie por caja (S, de 2 a 4 sp), que la propuesta dejaba para la entrega 2.

### Cierre
- Estado: Rechazado
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\carga-ola4-2026-10-08\` (`informe.md`, `t28-1.txt`, `t28-2.txt`, `t28-2-contaminada.txt`, `t57-1.txt`, `t57-2.txt`, `frec-t28-1.csv`, `frec-t28-2.csv`, `frec-t28-2-contaminada.csv`, `frec-t57-1.csv`, `frec-t57-2.csv`, `frecuencias.txt`, `bitacora.txt`, `build-release.txt`)
- Supuestos: los nodos inactivos de MSBuild y VBCSCompiler no cuentan como «otros dotnet en ejecución» (se cerraron con `dotnet build-server shutdown`); la instancia `MSSQLSERVER` estuvo en reposo (no se pudo medir sin elevación); t28-1 es válida por indicación del coordinador, con la salvedad de la sección 2.
- Decisiones candidatas a ADR: ninguna nueva. Si el propietario elige (b) o (c), sería una precisión de las metas de 14.3 o de ADR-45.
- Entregas a otros agentes: desarrollador-backend → perfil de CPU por venta (+1,1 ms en el motor frente a C-1) y costo de `TR_Documento_Ola4` en las emisiones que no son de POS (unos 15 ms, inferido); arquitecto-software → evaluar la cola de la compra (meta 5a) y la interferencia que queda (meta 1); arquitecto-maestro → preparar la decisión (a), (b) o (c) para firma; coordinador → limpiar las 14 bases `GPOS_TEST_*` huérfanas de `.\SQLEXPRESS`; qa-automatizado → O-1, O-2 y O-4 en el instrumento.
- Próximo paso recomendado: que el Arquitecto Maestro lleve al propietario la elección entre perfilar y corregir, recalibrar las metas o adelantar la serie por caja.
