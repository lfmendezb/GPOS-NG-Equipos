# Traspaso del equipo B: cambio de sesión del 2026-10-17

La sesión de B en LFMB (abierta el 2026-10-15) se cierra porque el contexto está casi lleno.

**Al abrir la sesión nueva:**
1. Ábrela en la carpeta `GPOS NG`, para que cargue la memoria.
2. Lee este traspaso, `estado.md` y los avisos abiertos.
3. **Primero:** analiza la cuarta tanda de T6, si ya terminó (ver §2).

## 1. Ramas y puntas
| Rama | Punta | Contenido |
|---|---|---|
| `feature/modelo-ng` | `e80f4654` | Hasta el #47. Unidos el 15 y el 16 de octubre: #24 a #42, #44, A-N3 (`b/devops-publicacion`), DEMO desde la punta (`b/devops-demo-sistema`), #43, #46, #47, #49 y #54 |
| `master` | `3ab799b3` | ADR al día: 82 a 88, precisiones del 16-oct (#53 de C), R-02 de ADR-118 con su nota del registro y DB-7 en `CLAUDE.md` |
| `b/prep-27oct` | `c01df683` | T1 de ADR-118/119, la 3b (con el rango por nodo), A-N2 completo (`Uf05ForceSeek`, `FORCESEEK` y `DISABLE_OPTIMIZED_NESTED_LOOP`), R-02 con su ajuste (`STRING_SPLIT` + `TOP (1)` + `NO_PERFORMANCE_SPOOL`), `KardexCosto` con `FORCESEEK`, `UnidadesArticulos` con `CROSS APPLY`, las pruebas de plan estables y la punta `e80f4654` |
| `b/ola5-auditoria-r` | `8ca70f8b` | La ola 5 (auditoría) rehecha sobre la preparación, sin P-B1 a P-B3 (esperan el 12834) |
| `demo/2026-10-15` | `f1d1a650` | Rama del DEMO hasta que exista la licencia con `s1` |

**Marcas de migraciones:**
- en la punta, la última es `Rg14RespaldoTope 20261015003000`;
- en la preparación: `NegativosTresNiveles 20261015010000`, `Ola3bTransferencias 20261015020000` y `Uf05ForceSeek 20261015142020`;
- en `ola5-auditoria-r`: `Ola5AuditExportacion 20261015211406`.

## 2. T6 de ADR-118/119
**Informes:** `traspasos/B/2026-10-16-t6-segunda-tanda.md` (todas las tandas), `2026-10-16-perfil-t1-renglon.md` (causa de N6-02) y `2026-10-17-perfil-r02-un-renglon.md` (lectura de la política y el modo lento de T-28).

**Tanda con R-02** (2026-10-16, 18:32; base `e80f4654`, candidato `b2c1cdd7`, 3 corridas por lado):

| Métrica (p95, ms) | Base | Candidato | Razón |
|---|---|---|---|
| N6-02 | 102,7 / 84,0 / 100,6 | 93,7 / 70,3 / 84,0 | 0,835 |
| T-28 | 24,0 / 23,7 / 24,5 | 27,2 / 22,1 / 28,5 | 1,133 |
| T-57 sin compras | 24,6 / 24,9 / 23,7 | 24,6 / 25,9 / 27,7 | 1,053 |
| T-57 con compras | 38,2 / 43,9 / 41,5 | 64,8 / 40,0 / 44,1 | 1,063 |
| Compra de 20 líneas | 946,1 / 976,0 / 783,6 | 260,3 / 214,0 / 227,1 | 0,24 |
| Meta 5b | 1.650,4 / 1.218,2 / 1.483,7 | 914,0 / 336,5 / 970,8 | 0,62 |

En las 3 corridas del candidato, T-28 da Correcto (8.2 (6) cumple).

**Cuarta tanda** (`Medicion-T6-r4.ps1`, lanzada el 2026-10-17 a las 06:52):
- **Comparación:** base `e80f4654` frente a candidato `c01df683`. 2 rondas de T-57, T-28 y N6-02.
- **Salidas:** `GPOS-B-prep27\TestResults\T6-r4-20261017-0652\`. La bitácora (`bitacora.txt`) registra la carga de CPU de cada corrida.
- **YA ANALIZADA (2026-10-17, 11:35): ver el final de `2026-10-16-t6-segunda-tanda.md`. N6-02, T-57 y 5b cumplen; T-28 da 1,110 y no cumple; hallazgo nuevo de 8.2 (6) en la comprobación de impuestos.** Lo que se pedía hacer:
  1. Juntar T-28 y T-57 con las 3 corridas de la tanda con R-02, para tener 5 por lado. El candidato solo cambió el ajuste de `PoliticasArticulos`, que es despreciable en T-28.
  2. Contar cuántas corridas caen en el «modo lento» de T-28 (unas 270 a 282 ventas/s y p95 de 27 a 29 ms) y cuántas en el rápido (unas 300 ventas/s y p95 de 23 a 24 ms).
  3. Confirmar que N6-02 sigue en verde con el ajuste.
  4. Publicar el veredicto en el informe de T6.
- **Criterios:** razón ≤ 1,05 con la mediana; frente a la oficial, T-28 ≤ 32,8 y T-57 ≤ 31,6. Si una corrida varía más del 5 % de su mediana, se piden 2 corridas más (regla 7.3).
- **Si T-28 sigue sobre 1,05:** el modo lento no tiene causa identificada, y el candidato cae en él aun sin la lectura de la política.
  - Propuesta del arquitecto de datos: diagnosticarlo con muestras de `PAGELATCH` (`dm_os_waiting_tasks`) y con `dotnet-counters`.
  - Esto lo decide el propietario antes del 27-oct.
- **Para extraer las métricas:** en cada `t28-*.txt`, la línea «6 cajeros, 3 min:» trae el p95. En cada `t57-*.txt`, la línea «metas:» trae «× X sin compras», «p95 venta 6 cajeros» y «fecha anterior p95». En cada `n602-*.txt`, la línea «RESUMEN N6-02».

## 3. Unión del 27-oct y PR abiertos (orden firmado por el propietario el 2026-10-16)
- **27-oct:** se une `b/prep-27oct` si T6 queda verde. Antes, la suite oficial completa sobre el resultado de la unión.
  - La suite del 16-oct dio 3150/47/28. Las 45 de `DispositivosK1Tests` fueron concurrencia con PA30: solas, 53/53.
- **Después del 27-oct**, en este orden:
  1. #52 + #55, DL-22. A tiene que renumerar el 51616 a 51617 y aplicar los tres puntos aprobados: S18, `KILL` con `--urgente` y `ComprobarAsync` limitado a `gpos_app_*`.
  2. #51, de C, rebasado sobre el #55, con las pruebas de carga.
  3. #45, activación de `UseLicencia`, cuando se firme P-81A-17.
  4. #48, 12834: A lo regenera con una marca posterior a `Uf05ForceSeek`. **El #60 (D-04, PA28) va con él.**
  5. #63 (SL) → #67 (RN) → #57 (fase A de ADR-81, de C) → #58 (SEG-FA-06). SL va antes de la fase A porque tocan los mismos cinco archivos.
  - **#59 (D-03) y #65 (EV-01):** son neutros y entran en cualquier hueco después del 27-oct.
  - *Puntos 4 (el #60) y 5, y la línea de #59 y #65: firmados por el propietario el 2026-10-17 en la sesión de B: «Firmo el orden propuesto tras el 27-oct: #60 con el #48; #63 → #67 → #57 → #58; #59 y #65 en cualquier hueco.»*
- **Cerrado:** #50 (CP170 duplicado; vale el de la preparación).
- **Después:** `b/ola5-auditoria-r` con la migración regenerada, y P-B1 a P-B3 cuando se una el #48.

## 4. Pendientes
**Del propietario (firmas y datos):**
- vertical Corporativa: FD-01 a FD-15, SW-01 a SW-18, UQ-1 a UQ-9, PM-01 a PM-10 y H-04 (espera al contador);
- AP-04 (aceptaciones escritas), la fecha de compra de DL-12, el custodio suplente (AP-02) y K-5 de Backup Tool;
- `gsf` con `CHECK_POLICY = ON` en la PC A;
- cuándo se construye DB-7 (acceso multiempresa v1, condición del primer cliente): B lo propone después del 27-oct.

**De B:**
- la salvaguarda del nivel de compatibilidad ≥ 130 (`STRING_SPLIT`) en `GPOS.Migracion verificar`;
- el riesgo Bajo del POS: más de unos 380 artículos distintos superan el límite de 2.100 parámetros (tope de renglones o respaldo, lo decide el arquitecto de software);
- T2 de ADR-126, después del 27-oct;
- registrar en ADR-82 los puntos 1 y 7 de DL-22 como implementados cuando se una el #55.

**De A y C:** la fase A de ADR-81 (C), SC08-01/03 (C, sobre el #49) y lo de los avisos abiertos.

## 5. Entorno de LFMB
- Las dos instancias son **SQL Server 2025**; `.\SQLEXPRESS` es la 17.0.1000.7 RTM. La contención está en 0, salvo que el propietario la active (M6).
- Ya no quedan bases `GPOS_TEST_*`. En `.\SQLEXPRESS` hay `SYSDATA` y `POS_GOLDCENTER` (BP2): **no se tocan**.
- **Guiones de medición** en `Solucion GPOS NG\`: `Medicion-T6-r2.ps1` (T6 completa con la suite), `-r3` (T-57 y N6-02) y `-r4` (T-57, T-28 y N6-02).
  - Usan `cmd /c` para que un `[FAIL]` no detenga el guion.
  - Se detienen si el equipo pasa a batería.
  - Registran la carga de CPU por WMI.
- **Árboles:**
  - `GPOS-B-carga`: base de T6, detached en `e80f4654`, con `RendimientoNegativosTests.cs` copiado sin confirmar;
  - `GPOS-B-prep27`: candidato;
  - `GPOS-B-integracion`: uniones;
  - `GPOS-B-ola5-auditoria`, `GPOS-B-devops`.
- **Lecciones de esta sesión:**
  - En los árboles con `autocrlf`, no escribas archivos con `git show >`. Verifica el guion contra una copia limpia con `cmp`.
  - Las pruebas de plan leen las DMV en dos pasos (tabla variable con el `plan_handle`).
  - `FORCESEEK` no evita la concesión de memoria de un bucle anidado optimizado.
