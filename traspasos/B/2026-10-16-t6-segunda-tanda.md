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
