# T6 de ADR-118/119, segunda tanda (2026-10-15 al 2026-10-16), y suite oficial del candidato

**Equipo B, en LFMB.** Segunda medición del plan de pruebas de ADR-118/119 (secciones 6.3 y 7), después de reconstruir `b/prep-27oct` sobre la punta. Sustituye a las corridas que faltaban de la primera tanda (`2026-10-15-t6-medicion-adr118-119.md`): base y candidato cambiaron, así que no se combinan con ella.

## Condiciones
| | Valor |
|---|---|
| Base | `feature/modelo-ng` en `fb32b26b` (sin T1), más `RendimientoNegativosTests.cs` copiado sin confirmar para N6-02 |
| Candidato | `b/prep-27oct` en `3988078c`: T1 + T2 + T4 de ADR-118/119, ola 3b tramo 1, A-N2 (con `FORCESEEK`), #38 y la punta |
| Motor | `.\SQLEXPRESS`, SQL Server 2025 Express RTM 17.0.1000.7, max server memory 1410 MB |
| Ejecución | Release, `--no-build`, `GPOST_B9=1`; T-28 con `GPOST_B9_MINUTOS=3`, T-57 con `GPOST_B9_MUESTREO=1`, N6-02 con 2 min y 60 s de calentamiento |
| Secuencia | 3 rondas, cada una con T-28, T-57 y N6-02, base y candidato intercalados, 15 min de enfriamiento antes de cada corrida; después, N6-03 en el candidato y la suite oficial (Debug) |
| Horario | 19:32 a 02:57, con la máquina sola |
| Máquina | Conectada a la corriente (100 %), plan «Legion Performance Mode», CPU estable a 3.201/3.201 MHz, sin otros procesos `dotnet` |
| Guion | `Solucion GPOS NG\Medicion-T6-r2.ps1`; salidas en `GPOS-B-prep27\TestResults\T6-r2-20261015-1932\` |

## Resultados (p95, ms)
| Métrica | Base r1 / r2 / r3 | Mediana base | Candidato r1 / r2 / r3 | Mediana cand. | Razón |
|---|---|---|---|---|---|
| **T-28, 6 cajeros (principal)** | 24,8 / 24,1 / 23,1 | 24,1 | 26,2 / 25,2 / 24,4 | **25,2** | **1,046** |
| **T-57, venta sin compras (principal)** | 24,9 / 21,9 / 24,5 | 24,5 | 24,7 / 23,9 / 24,4 | **24,4** | **0,996** |
| T-57, venta con compras (secundaria) | 41,2 / 38,4 / 38,2 | 38,4 | 44,4 / 39,5 / 40,4 | 40,4 | 1,052 |
| T-57, compra de 20 líneas (informativa) | 852,9 / 1.000,1 / 850,4 | 852,9 | 939,2 / 860,6 / 819,9 | 860,6 | 1,009 |
| T-57, meta 5b (compra con fecha anterior) | 1.207,8 / 1.180,2 / 1.244,3 | 1.207,8 | 1.744,7 / 1.336,7 / 1.509,0 | 1.509,0 | 1,249 |
| **N6-02, venta de 20 renglones sin lote** | 81,3 / 84,7 / 80,3 | 81,3 | 92,4 / 79,6 / 96,0 | **92,4** | **1,137** |
| N6-03, 1 renglón con lote (informativa) | — | — | 22,6 | 22,6 | — |
| N6-03, 20 renglones con lote (informativa) | — | — | 67,9 | 67,9 | — |

Errores en todas las corridas: 0. Interbloqueos del motor: 0.

## Criterios (plan, sección 7.4)
1. **Contra la medición firmada (≤ 1,05 × oficial):** T-28 25,2 ≤ 32,8; T-57 sin compras 24,4 ≤ 31,6; con compras 40,4 ≤ 84,0. **Cumple.**
2. **Control de atribución (candidato frente a base, misma sesión, ≤ 1,05):**
   - T-28: 1,046. **Cumple**, con poco margen.
   - T-57 sin compras: 0,996. **Cumple.**
   - T-57 con compras (secundaria): 1,052, **en el límite**.
3. **N6-02 (punto 3: la mediana del candidato ≤ 1,05 × la de la base): 1,137. NO CUMPLE.**
4. **Dispersión (7.3, más del 5 % de la mediana):**
   - T-28: dentro, en los dos lados.
   - T-57 sin compras: la base sale (21,9 frente a 24,5, −10,6 %).
   - T-57 con compras: el candidato sale (+9,9 %).
   - **N6-02:** el candidato sale (79,6 frente a 92,4, −13,9 %).

   Las métricas con dispersión exigen 2 corridas más por lado antes de cerrarlas.
5. **Meta 5b:** todas las corridas quedan bajo 2.000 ms. El candidato sube un 25 % en la mediana (1.509 frente a 1.208) y llega a 1.744,7 en la corrida 1. Margen estrecho.

## Hallazgo: 8.2 (6) seguía fallando con A-N2 (corregido el 2026-10-16)
- **Síntoma:** T-28 terminó en `[FAIL]` por 8.2 (6) en las 6 corridas, base **y candidato**.
  - En el candidato, UF-05 ya hacía «solo búsquedas» (`FORCESEEK` quitó el recorrido), pero seguía pidiendo **1.024 KB**.
  - El diagnóstico nuevo de `CargaOla3Tests` no encontró Hash, Sort ni Merge.
- **Causa:** el **bucle anidado optimizado** (batch sort), que también pide memoria.
- **Corrección** (`b/prep-27oct` `3b04495f`, en la misma migración `Uf05ForceSeek`, que no está unida): UF-05 pasa a `SELECT @origenMovio = 1 WHERE EXISTS (...) OPTION (USE HINT ('DISABLE_OPTIMIZED_NESTED_LOOP'))`. El resultado no cambia.
- **Verificación:** **T-28 en el candidato, Correcto.** UF-05 con `last_grant_kb 0` y solo búsquedas; p95 26,8 ms (una corrida).
  - Guion regenerado, idéntico a una copia limpia; `has-pending-model-changes` sin cambios.
  - Emisión, migraciones, 3b, planes y Mvp: 192/0/1.
- **Nota:** `Uf05PlanTests` no reproducía este caso (su plan sale sin batch sort). El criterio que lo vigila es T-28.

## Suite oficial del candidato (`3988078c`, Debug, `.\SQLEXPRESS`)
**3147 correctas, 2 fallidas y 27 omitidas** (3176 en total, 9 min 57 s).
- `PruebasNeutralesTests.Los_archivos_BP2_estan_en_el_manifiesto`: `ConsultasVarcharSecuencialTests.cs` (CP-170, separada el 15-oct) faltaba en el manifiesto. **Corregido** en `69fc27b0`.
- `Rg14RotacionApiTests.PA30_*`: la intermitente conocida de la rotación (DL-22). Su corrección, el `KILL` diferido de 2 min, está firmada y sin construir.

## Veredicto provisional
- **T-28 y T-57 (principales): verdes** en los criterios 1 y 2. T-28 con poco margen (1,046).
- **N6-02 no cumple el criterio 3** (1,137), con dispersión alta en el candidato.
  - Es la primera medición de la venta de 20 renglones con T1.
  - La política de negativos y el lote se resuelven por línea, así que un aumento por renglón es plausible; no es ruido seguro.
- **No conviene unir el 27-oct sin cerrar N6-02.** Propuesta:
  1. 2 corridas más por lado de N6-02 y T-57 (regla 7.3), ya con `3b04495f`, con la máquina sola (unas 2,5 h).
  2. Si el exceso se confirma, que el arquitecto de datos perfile el costo por renglón de T1 en la venta POS (los comandos de existencia y `LotesDocumento`) y proponga el ajuste. En paralelo, revisar la subida de 5b.

## Tercera tanda (2026-10-16, 04:24): interrumpida por un corte de luz
- **Guion:** `Solucion GPOS NG\Medicion-T6-r3.ps1`, con 2 rondas de T-57 y N6-02 sobre la base `fb32b26b` y el candidato `3b04495f`. Salidas en `GPOS-B-prep27\TestResults\T6-r3-20261016-0424\`.
- **Corridas que llegaron a hacerse:** `t57-r1-base` y `t57-r1-cand`, las dos con código 0.
- **El corte:** a las 05:32 el equipo pasó a batería y el guion se detuvo solo, antes de N6-02. No quedaron procesos de prueba.
- **Al reanudar,** con la máquina conectada y sola: repetir la tercera tanda completa (unas 3 h). Las dos corridas de T-57 hechas se pueden sumar si los commits no cambian.

## Tercera tanda, segundo intento (2026-10-16, 08:28 a 11:25): descartada
- **Corte:** se detuvo por otro paso a batería a las 11:25, antes de `n602-r2-cand`.
- **Por qué se descarta entera:** las corridas hechas están degradadas frente a la noche, aunque las condiciones anotadas eran normales (CPU 3.201 MHz, conectada, sin otros `dotnet`):

  | Corrida | T-57 sin compras | T-57 con compras | 5b | N6-02 |
  |---|---|---|---|---|
  | r1 base | 29,8 | 71,7 | 1.469 | 102,0 |
  | r1 cand | 24,8 | 56,4 | 1.587 | 93,3 |
  | r2 base | 137,5 | 121,6 | 1.678 | 154,7 |
  | r2 cand | 81,8 | 86,0 | 2.896 | — |

  La segunda tanda (noche) dio unos 24, unos 40, unos 1.200 a 1.500 y unos 80 a 95, respectivamente.
- **Causa probable:** en horario diurno, otra carga en el equipo (uso, actualizaciones u otros procesos no `dotnet`) o inestabilidad eléctrica antes del corte.
- **Decisión:** no se usa para el criterio. **Repetir de noche**, con la máquina sola y con la luz estable.
- **Mejora pendiente del guion:** registrar la carga total de CPU y los procesos principales al empezar cada corrida, no solo los `dotnet`.

## Tercera tanda, tercer intento (2026-10-16, 12:10 a 15:08): limpia
- **Condiciones:** carga de CPU entre el 2 % y el 9 % antes de cada corrida (WMI, procesos más activos sin carga), conectada, sin cortes, sin otros `dotnet`. Salidas en `GPOS-B-prep27\TestResults\T6-r3-20261016-1210\`.
- **Commits:** base `fb32b26b`; candidato `3b04495f`. El candidato solo cambia frente a `3988078c` en el arreglo de UF-05 y en las pruebas. Se combina con la segunda tanda: 5 corridas por lado.

| Métrica (p95, ms) | Base (2.ª tanda + 3.ª) | Mediana base | Candidato (2.ª + 3.ª) | Mediana cand. | Razón |
|---|---|---|---|---|---|
| **N6-02, 20 renglones sin lote** | 81,3 / 84,7 / 80,3 + 78,7 / 101,3 | 81,3 | 92,4 / 79,6 / 96,0 + 102,3 / 95,4 | **95,4** | **1,173** |
| **T-57 sin compras (principal)** | 24,9 / 21,9 / 24,5 + 28,7 / 25,7 | 24,9 | 24,7 / 23,9 / 24,4 + 23,3 / 24,4 | 24,4 | **0,980** |
| T-57 con compras | 41,2 / 38,4 / 38,2 + 40,4 / 39,9 | 39,9 | 44,4 / 39,5 / 40,4 + 52,7 / 42,5 | 42,5 | 1,065 |
| T-57 compra de 20 líneas | 852,9 / 1.000,1 / 850,4 + 842,5 / 888,6 | 852,9 | 939,2 / 860,6 / 819,9 + 799,8 / 903,0 | 860,6 | 1,009 |
| T-57 meta 5b | 1.207,8 / 1.180,2 / 1.244,3 + 1.093,6 / 1.076,5 | 1.180,2 | 1.744,7 / 1.336,7 / 1.509,0 + 1.483,2 / 1.862,9 | 1.509,0 | 1,279 |

## Veredicto de T6 con 5 corridas por lado
- **T-28** (3 corridas, dentro de la dispersión) y **T-57 sin compras: cumplen.** T-28 queda en 1,046 y T-57 sin compras en 0,980.
- **N6-02: NO CUMPLE, confirmado (1,173).** La venta POS de 20 renglones con T1 cuesta alrededor de un 17 % más en el p95.
- **T-57 con compras: 1,065**, por encima de 1,05. Es la métrica secundaria.
- **Meta 5b:** cumple el tope de 2.000 ms, pero el candidato sube un 28 % y su peor corrida llega a 1.862,9 ms. Riesgo alto de pasar el tope.
- **Siguiente paso** (decisión del propietario del 16-oct: «Repetir y perfilar»): perfilar el costo por renglón de T1 en la venta POS (comandos de existencia, política de negativos y `LotesDocumento`) y la subida de la compra con fecha anterior (5b), y proponer la corrección antes de la unión del 27-oct.

## T6 con R-02 (2026-10-16 18:32 a 2026-10-17 01:59): base `e80f4654`, candidato `b2c1cdd7`
- **Condiciones:** carga de CPU entre el 0 % y el 16 % antes de cada corrida; conectada; sin cortes. Salidas en `GPOS-B-prep27\TestResults\T6-r2-20261016-1832\`.
- **El candidato** lleva R-02 (política leída una vez por documento), `KardexCosto` con `FORCESEEK` y `UnidadesArticulos` con `CROSS APPLY`, más T1, la 3b y A-N2 completo.

| Métrica (p95, ms) | Base r1 / r2 / r3 | Mediana base | Candidato r1 / r2 / r3 | Mediana cand. | Razón |
|---|---|---|---|---|---|
| **N6-02, 20 renglones** | 102,7 / 84,0 / 100,6 | 100,6 | 93,7 / 70,3 / 84,0 | **84,0** | **0,835** |
| **T-28, 6 cajeros** | 24,0 / 23,7 / 24,5 | 24,0 | 27,2 / 22,1 / 28,5 | **27,2** | **1,133** |
| **T-57 sin compras** | 24,6 / 24,9 / 23,7 | 24,6 | 24,6 / 25,9 / 27,7 | **25,9** | **1,053** |
| T-57 con compras | 38,2 / 43,9 / 41,5 | 41,5 | 64,8 / 40,0 / 44,1 | 44,1 | 1,063 |
| T-57 compra de 20 líneas | 946,1 / 976,0 / 783,6 | 946,1 | 260,3 / 214,0 / 227,1 | 227,1 | 0,24 |
| T-57 meta 5b | 1.650,4 / 1.218,2 / 1.483,7 | 1.483,7 | 914,0 / 336,5 / 970,8 | 914,0 | 0,62 |
| N6-03, 1 renglón / 20 renglones con lote (informativa) | — | — | 26,0 / 84,2 | — | — |

- **8.2 (6):** T-28 da **Correcto** en las 3 corridas del candidato (A-N2 completo). En la base falla, como se esperaba, porque no tiene A-N2. 8.2 (5): `TR_Documento_Emision` cuesta igual en los dos lados (0,29 a 0,32 ms por ejecución).
- **N6-02: cumple con margen** (0,835). R-02 resolvió el costo por renglón.
- **Compra de 20 líneas y 5b: mejoran mucho** (0,24 y 0,62) gracias al `FORCESEEK` de `KardexCosto`.
- **T-28: 1,133, con dispersión alta en el candidato** (22,1 a 28,5, de −19 % a +5 % de su mediana). T-57 sin compras: 1,053. Los dos piden 2 corridas más por lado (regla 7.3) antes de concluir.
  - **Hipótesis:** costo por venta de la lectura previa de la política (`PoliticasArticulos`, con `OPENJSON`, que concede 1.024 KB en SQL Server 2025 Express) en las ventas de 1 renglón. No está medida.
- **Suite oficial del candidato (Debug):** 3150 correctas, 47 fallidas y 28 omitidas.
  - Las 45 de `DispositivosK1Tests` fallaron al abrir su conexión («No hay ningún proceso en el otro extremo de la canalización»), seguramente por el `KILL` inmediato de PA30 en paralelo. **Solas: 53/53**, incluida C-10.
  - Las otras dos son PA30 (DL-22 sin unir) y C-10 (intermitente).

## Cuarta tanda (2026-10-17, 06:52 a 11:30) y veredicto con 5 corridas por lado
- **Condiciones:** carga de CPU entre el 0 % y el 11 %, conectada, sin cortes. Base `e80f4654`; candidato `c01df683` (R-02 con el ajuste de `PoliticasArticulos`). Salidas en `GPOS-B-prep27\TestResults\T6-r4-20261017-0652\`.
- **Corridas nuevas:**
  - T-28: base 25,2 (281,4/s) y 26,2 (279,3/s); candidato 29,7 (273,0/s) y 25,1 (292,3/s).
  - T-57 sin compras: base 23,7 y 23,3; candidato 23,6 y 23,7.
  - Con compras: base 40,2 y 41,2; candidato 41,9 y 40,7.
  - 5b: base 940,8 y 1.363,9; candidato 609,5 y 257,4.
  - N6-02: base 85,7 y 88,9; candidato 62,8 y 107,0.

| Métrica (p95, ms; 5 corridas por lado) | Mediana base | Mediana cand. | Razón | Veredicto |
|---|---|---|---|---|
| **N6-02, 20 renglones** | 88,9 | 84,0 | **0,945** | **Cumple** |
| **T-57 sin compras** | 23,7 | 24,6 | **1,038** | **Cumple** |
| T-57 con compras | 41,2 | 41,9 | 1,017 | Cumple |
| T-57 meta 5b | 1.363,9 | 609,5 | 0,447 | Cumple, con mejora grande |
| **T-28, 6 cajeros** | 24,5 | 27,2 | **1,110** | **NO CUMPLE** el criterio 2. Cumple frente a la oficial (≤ 32,8) |

- **T-28 sigue bimodal en el candidato:** 22,1 / 25,1 / 27,2 / 28,5 / 29,7. Esta mañana la base también cayó en el modo intermedio (25,2 y 26,2). La causa sigue sin identificar; ver el perfil del 17-oct, §6.
- **Hallazgo nuevo de 8.2 (6), Medio:** en `t28-r1-cand`, la comprobación de impuestos de `TR_Documento_Emision` (`IF EXISTS (SELECT 1 FROM ventas.VentaImpuesto vi OUTER APPLY …)`) hizo un **Clustered Index Scan de `ventas.VentaLineaImpuesto`** (0 KB). Pasó en 1 de 5 corridas.
  - Es un plan inestable, como UF-05: pide un `FORCESEEK` o una reescritura en la misma migración `Uf05ForceSeek`, que todavía no está unida.
  - Puede explicar parte de la cola de T-28 cuando aparece.
- **Para la sesión nueva de B (decisión del propietario antes del 27-oct):**
  1. Corregir el plan de la comprobación de impuestos.
  2. Diagnosticar el modo lento de T-28 (muestras de `PAGELATCH`, `dotnet-counters`).
  3. Volver a medir T-28 con 5 corridas por lado, o aceptar T-28 a 1,11 frente al control, con la oficial cumplida, por escrito.
- **Precisión del hallazgo de 8.2 (6):** en `t28-r1-cand` la sentencia solo hizo **6 ejecuciones**, y `ventas.VentaLineaImpuesto` quedó con 0 filas tras la carga. Es un plan compilado sobre la tabla vacía, así que no explica la cola de T-28. En `r2-cand` la misma sentencia hizo 9.375 ejecuciones con «solo búsquedas».
- **Decisión del propietario (2026-10-17, sesión de B):** salida 1.
  - `FORCESEEK` en la comprobación de impuestos, dentro de `Uf05ForceSeek`.
  - Tanda nocturna de T-28 con `GPOST_B9_AFINIDAD=auto` (#66 de C), en base y candidato, con muestras de `PAGELATCH`.
  - Motivo de la afinidad: C atribuye el modo lento a que los hilos del cliente comparten núcleos físicos con el Express, y con la ubicación controlada mide base y candidato iguales (0,991; `traspasos/C/2026-10-17-modo-lento-t28.md`).
  - La duplicada de esta sección, publicada en `503e93b`, se quita.

## Quinta tanda (2026-10-17, 14:33 a 20:58): T-28 con `GPOST_B9_AFINIDAD=auto` y muestras de esperas
- **Condiciones:** guion `Solucion GPOS NG\Medicion-T6-r5.ps1`. Carga de CPU entre el 0 % y el 7,3 % antes de cada corrida; conectada, sin cortes, sin otros `dotnet`. Horario de tarde. Salidas en `GPOS-B-prep27\TestResults\T6-r5-20261017-1433\`.
- **Base:** `e80f4654`. **Candidato:** `d67f5a33` (c01df683 + `FORCESEEK` de la comprobación de impuestos CA-12, por 8.2 (6)). El #66 de C está aplicado sin confirmar en los dos lados.
- **Afinidad:** `auto` fijó el cliente en `0xFF00` (CPU 8 a 15), y el Express quedó en las CPU 0 a 7.

### T-28, 6 cajeros (p95, ms)
| Corrida | Base: p95 · ventas/s · CPU de sentencias por venta | Candidato: p95 · ventas/s · CPU de sentencias por venta |
|---|---|---|
| Control, sin afinidad | 23,2 · 299,8 · 5,36 | 23,7 · 298,9 · 5,24 |
| r1 | 27,0 · 284,9 · 5,46 | 22,6 · 307,1 · 5,28 |
| r2 | 23,6 · 307,6 · 5,00 | 23,8 · 302,3 · 4,98 |
| r3 | 24,1 · 301,3 · 5,10 | 24,2 · 299,7 · 4,95 |
| r4 | 22,1 · 312,3 · 5,16 | 25,9 · 291,0 · 5,07 |
| r5 | 22,7 · 310,5 · 5,12 | 23,1 · 304,2 · 5,10 |
| **Mediana con afinidad (r1 a r5)** | **23,6** | **23,8** |

- **Razón con afinidad: 1,008. Cumple** el criterio 2 (≤ 1,05). Con el control incluido (6 por lado) da 1,015.
- **Frente a la oficial:** 23,8 ≤ 32,8. **Cumple.**
- **CPU de sentencias por venta:** el candidato queda igual o por debajo de la base en las 6 parejas (4,95 a 5,28 ms, frente a 5,00 a 5,46). No hay costo de código atribuible.
- **Dispersión:** una corrida por lado se separa de su mediana (base r1 +14 %, candidato r4 +9 %). Pasa en los dos lados y con la misma firma (menos ventas por segundo y más CPU del cliente por venta), así que es ruido simétrico, no del candidato.
- **El modo lento no apareció esta vez en ningún lado**, tampoco en el control sin afinidad. Los datos son compatibles con la explicación de C, pero no la prueban en LFMB: falta una corrida lenta sin afinidad junto a otra rápida con afinidad. Para el criterio basta con que, controlando la ubicación, base y candidato salgan iguales.
- **8.2 (6): Correcto en las 6 corridas del candidato**, con el `FORCESEEK` de CA-12. La base sigue fallando, como se esperaba, porque no tiene A-N2.

### Muestras de esperas (cada 500 ms; unas 900 muestras por corrida de T-28)
- **PAGELATCH:** entre 40 y 70 tareas en espera sumando todas las muestras de una corrida, es decir, unas 0,05 por muestra, iguales en los dos lados. Las páginas son de `doc.Documento` (índice agrupado), `sys.sysallocunits`, `ventas.Venta` y `inv.Movimiento`. **No hay un punto caliente de pestillos.**
- **LCK_M_U** domina: unas 3,7 tareas en espera por muestra. Es la serialización por serie del diseño, con la base en 3.325 a 3.444 y el candidato en 3.413 a 3.580 (unos +3 %, dentro del ruido).
- **WRITELOG:** unas 40 por corrida en los dos lados. Sin SOS ni errores de muestreo.

### T-57 y N6-02 con afinidad (una corrida por lado)
| Métrica (p95, ms) | Base | Candidato | Razón |
|---|---|---|---|
| T-57 sin compras | 23,7 | 21,8 | 0,92 |
| T-57 con compras | 39,2 | 38,8 | 0,99 |
| Compra de 20 líneas | 939,6 | 207,8 | 0,22 |
| Meta 5b | 966,6 | 305,0 | 0,32 |
| N6-02, 20 renglones | 73,9 | 84,2 | 1,139 |

- **T-57: cumple con margen.**
- **N6-02 en esta pareja: 1,139.** Sin embargo, el candidato gastó **menos** CPU de sentencias por venta (10,06 frente a 12,30 ms). Lo que subió fue la **señal**, la espera de CPU dentro del motor: 1,16 frente a 0,23 ms por venta. Es la firma de contención del planificador, no de costo de código.
- **El criterio de N6-02 sigue cerrado en verde** con las 5 corridas por lado sin afinidad (0,945). Esta pareja es informativa; con la regla 7.3, 2 corridas más por lado con afinidad la confirmarían.

## Veredicto de T6 (2026-10-17, noche)
- **T-28: VERDE.** Con la ubicación del cliente controlada, la razón es 1,008 y la CPU de sentencias no sube. 8.2 (6) pasa en 6 de 6.
- **T-57, compra de 20 líneas y 5b: verdes**, con mejoras grandes en la compra.
- **N6-02: verde** por el criterio de 5 corridas. La única pareja con afinidad sale alta por espera de CPU en el motor, no por costo. Recomendación de B: 2 corridas más por lado con afinidad, unos 75 min, antes de unir.
- **`b/prep-27oct` (`d67f5a33`) queda apto para la unión del 27-oct** según T6, sujeto a la suite oficial completa sobre el resultado de la unión.
- **Para el banco:** desde ahora T-28, T-57 y N6-02 se miden con `GPOST_B9_AFINIDAD=auto` (#66), que se une junto con la preparación.

## Sexta tanda (2026-10-17, 21:43 a 22:58): N6-02 con afinidad, regla 7.3
- **Condiciones:** guion `Solucion GPOS NG\Medicion-T6-r6.ps1`, mismos commits y el mismo #66 que en la quinta tanda. Carga de CPU entre el 2 % y el 8 %; conectada. Salidas en `GPOS-B-prep27\TestResults\T6-r6-20261017-2143\`.

| N6-02 con afinidad (p95, ms) | Base | Candidato |
|---|---|---|
| Quinta tanda | 73,9 | 84,2 |
| r1 | 98,5 | 69,7 |
| r2 | 80,3 | 107,5 |
| **Mediana (3 por lado)** | **80,3** | **84,2** |
| CPU de sentencias por venta (ms) | 12,30 / 12,90 / 12,09 | 10,06 / 10,60 / 10,29 |
| Señal, espera de CPU en el motor (ms por venta) | 0,23 / 0,42 / 0,42 | 1,16 / 0,58 / 1,05 |
| LCK_M_U, total muestreado | 554 / 512 / 512 | 677 / 656 / 635 |

- **Razón: 1,049. Cumple el criterio 3 (≤ 1,05), al límite.** Sin afinidad, con 5 corridas por lado, era 0,945. **N6-02 queda cerrado en verde.**
- **Dispersión alta en los dos lados:** la base va de 73,9 a 98,5 y el candidato de 69,7 a 107,5. El p95 de N6-02 es ruidoso con 2 min de carga.
- **Observación para el arquitecto de datos (no bloquea):** el candidato gasta un **16 % menos de CPU de sentencias** por venta, pero tiene un **25 % más de esperas `LCK_M_U`** y más señal. La venta de 20 renglones con T1 espera más bloqueos de actualización, aunque calcule menos. Es coherente con el `UPDATE` condicional de existencias por artículo de ADR-118 y con las líneas de política. Conviene revisarlo después del 27-oct, junto con LP-01 (límite de 2.100 parámetros), que toca la misma escritura.

## Veredicto final de T6 (2026-10-17)
**T6 en verde en todas las métricas:**
- T-28: 1,008 con afinidad;
- T-57: 0,92 sin compras y 0,99 con compras;
- compra de 20 líneas: 0,22; meta 5b: 0,32;
- N6-02: 1,049 con afinidad y 0,945 sin ella;
- 8.2 (6): 6 de 6 en el candidato.

**`b/prep-27oct` (`d67f5a33`) queda apto para la unión del 27-oct**, sujeto a la suite oficial completa sobre el resultado de la unión. El #66 se une con ella.
