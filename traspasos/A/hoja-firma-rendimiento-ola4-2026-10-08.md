# Hoja de firma: rendimiento de la ola 4 tras la carga de cierre (T-28 y T-57)

[Decisión preparada por el Arquitecto Maestro (equipo A)]  **Estado: Pendiente de firma**

- **Fecha:** 2026-10-08 · **Para:** el propietario · **Código evaluado:** `GPOS-NG-numeracion`, rama `feature/modelo-ng`, `f21b788` (incluye V1, A1, A3 y el instrumento de T-57)
- **Fuentes:**
  - [QA] `carga-ola4-2026-10-08/informe.md` y sus salidas `t28-1.txt`, `t28-2.txt`, `t57-1.txt` y `t57-2.txt`.
  - [PROP] `rendimiento-ola4-propuesta-2026-10-07.md` (F-a, F-b y F-c firmadas el 2026-10-07).
  - [BP4] `docs/arquitectura/2026-10-06-ola4-blueprint.md` 14.3 (metas de T-57 y D-4).
  - [CIE3] `docs/decisiones/2026-10-06-cierre-ola3.md` 3.3 (condición C-1).
  - `docs/adr/ADR-045.md` y `docs/adr/ADR-072.md`.
  - [RESP5] `respuestas-A-ola5-solicitud-2026-10-08.md` (S-3: fechas; S-14: T-28 como banco de la ola 5).
- **Alcance de este trabajo:** solo leí documentos y salidas, y consulté `git log` en modo de lectura. No compilé ni ejecuté nada. Todas las cifras de carga son de QA. **sp** significa semanas-persona (±30 %, inferido).

---

## 0. Resumen ejecutivo

1. **La ola 4 está bien en lo funcional y mal en el rendimiento.** En las dos corridas válidas de las dos pruebas hubo 0 errores 1205, las conciliaciones dieron 0, no hubo números repetidos, se cumplieron la meta 5b y el Z, y los disparadores por ejecución quedaron dentro de su meta. Lo que falla son cuatro metas firmadas: la de T-28 (66,2 y 74,9 ms, con meta de 52) y las metas 1, 5a y 6 de T-57 ([QA]:53, :66-78). QA descarta que la causa sea una CPU lenta: la frecuencia se mantuvo estable en unos 3,1 GHz ([QA]:38).
2. **Encontré una contradicción que ninguno de los dos informes resuelve, y es la pista más barata.** Con el mismo código, la misma máquina, el mismo día y 6 cajeros solo de venta, el p95 fue:
   - 74,9 ms en el tramo principal de T-28 (`t28-2.txt:21`);
   - **45,8 ms** en el último tramo de la misma corrida de T-28 (`t28-2.txt:235`);
   - **40,2 y 42,3 ms** en el tramo sin compras de T-57, que también dura 180 s (`t57-1.txt:33`, `t57-2.txt:33`).

   El camino de la venta de `f21b788` cumple los 52 ms en tres de los cinco tramos de 6 cajeros solo de venta. Los dos que fallan son el tramo principal de T-28 en sus dos corridas. Hay que saber por qué antes de recalibrar nada o de cambiar la numeración.
3. **La interferencia de las compras tiene un sospechoso concreto.** QA infiere que `TR_Documento_Ola4` cuesta unos 15 ms en cada emisión que no es de POS (compra, pago, caja chica y depósito) ([QA]:94). Con A1, la emisión de la compra ocurre en el mismo lote que aplica la existencia ([PROP] 2, A1). Por lo tanto, esos 15 ms transcurren **con la fila de existencia retenida** (inferido). Eso explica, al menos en parte, tres cosas: por qué A1 bajó el convoy de 255-297 ms a unos 107 ms sin eliminarlo, por qué siguen apareciendo de 15 a 18 esperas en `inv.Existencia`, y por qué el pago (meta 6) pasa de 100 ms.
4. **Recomendación: (a) con un tope, más un respaldo (b) firmado desde ya y acotado a T-57.** T-28 no se recalibra. La opción (c), la serie por caja, sigue en la entrega 2. La ola 4 **no** se cierra en lo funcional antes de tiempo.
   - **Costo:** de 0,8 a 1,3 sp.
   - **Calendario:** el cierre de la ola 4 pasa del 9-10 de octubre a **unos días alrededor del 15 de octubre**. La unión de la 3b pasa del 17 a **unos días alrededor del 22 de octubre**, y `b/ola5` se mueve lo mismo (todas las fechas son inferidas).

---

## 1. Contexto y pregunta a decidir

QA rechazó la carga de cierre de la ola 4 ([QA] 7). Están abiertos tres hallazgos de severidad Alta (H-C1-01 a 03) y uno Media (H-C1-04). Por la regla firmada de C-1 ([CIE3] 3.3, punto 3), «la ola no cierra sola»: el propietario tiene que decidir cómo se sigue.

**Pregunta:** ¿se sigue con (a), corregir; (b), recalibrar; (c), la serie por caja; o una combinación? ¿Y qué se hace con el calendario de la 3b y de `b/ola5`?

## 2. Entregables evaluados

| Entregable | Ruta | Uso |
|---|---|---|
| Informe de QA de la carga de cierre | `C:\Users\lfmen\source\repos\Solucion GPOS NG\carga-ola4-2026-10-08\informe.md` | Veredicto, metas y hallazgos |
| Salidas de las corridas | La misma carpeta: `t28-1.txt`, `t28-2.txt`, `t57-1.txt`, `t57-2.txt` y `bitacora.txt` | Contraste de los tramos (sección 3.2) |
| Propuesta de rendimiento | `C:\Users\lfmen\source\repos\Solucion GPOS NG\rendimiento-ola4-propuesta-2026-10-07.md` | Lo que se esperaba de V1, A1 y A3, y las firmas F-a, F-b y F-c |
| Blueprint de la ola 4, 14.3 | `GPOS-NG-numeracion\docs\arquitectura\2026-10-06-ola4-blueprint.md`:634-668 | Metas de T-57 |
| Cierre de la ola 3, C-1 | `GPOS-NG-numeracion\docs\decisiones\2026-10-06-cierre-ola3.md`:101-112 | Regla de cierre y precedente |
| ADR-45 y ADR-72 | `GPOS-NG-numeracion\docs\adr\ADR-045.md`:26 y :67; `ADR-072.md` | Límites de la opción (c) |

## 3. Diagnóstico consolidado

### 3.1 Lo que se midió (verificado en las salidas de QA)

| # | Hecho | Cifra | Evidencia |
|---|---|---|---|
| M-1 | T-28, tramo principal de 6 cajeros (3 min) | p95 de 66,2 ms (t28-1, con perturbación) y **74,9 ms** (t28-2, limpia), con 64,0 y 141,5 ventas/s | `t28-1.txt:21`, `t28-2.txt:21` |
| M-2 | T-28, último tramo de 6 cajeros (60 s, con 83.694 documentos en la base) | **p95 de 45,8 ms**, con 181 ventas/s | `t28-2.txt:235` |
| M-3 | T-57, tramo de diagnóstico de 6 cajeros sin compras (180 s) | **p95 de 40,2 y 42,3 ms**, con 196 y 191 ventas/s | `t57-1.txt:33`, `t57-2.txt:33` |
| M-4 | T-57, meta 1 (6 cajeros con compras) | p95 de 106,0 y 108,6 ms; esperas en `inv.Existencia`: 18 y 15 | [QA]:66-69 |
| M-5 | T-57, meta 5a (compra de 20 líneas con 6 cajeros) | p95 de 1.033,5 y 992,3 ms; p50 de 242 y 238 ms. La anulación tiene un p50 de 1.431 y 1.527 ms | [QA]:74, :130 |
| M-6 | T-57, meta 6 (pago) | p95 de 121,1 y 142,2 ms; p50 de 37 a 52 ms | [QA]:77, :136 |
| M-7 | CPU del motor por venta en el tramo principal de T-28, frente a C-1 | De 4,64 a 5,78 ms (+25 %), con la máquina al 89 % | [QA]:109 |
| M-8 | Efecto de V1 | La espera de la serie en el motor bajó de 6,21 a 2,32 ms por venta | [QA]:108 |
| M-9 | Presión de CPU con compras | `SOS_SCHEDULER_YIELD`: 17,7 y 19,0 s con compras, frente a 0,08 y 0,2 s sin ellas | [QA]:121 |
| M-10 | `TR_Documento_Ola4` | 0,017 ms por ejecución en el tramo sin compras; de 0,270 a 0,372 ms de media en el tramo con compras | [QA]:89 |
| M-11 | Corrección funcional | 0 errores 1205, 0 filas en las conciliaciones, 0 repetidos; 5b de 1,1 y 1,2 s; Z de 0,27 s | [QA]:55-59, :71-76 |
| M-12 | El instrumento de T-28 no cambió desde C-1 | `git diff --stat 4007968 f21b788 -- tests/GPOS.Tests/ModeloNg/CargaOla3Tests.cs` sale vacío | consulta de lectura de este trabajo |

### 3.2 Lo que se infiere, y con qué grado de confianza

| # | Inferencia | Base | Confianza |
|---|---|---|---|
| I-1 | **El camino de la venta de `f21b788` puede cumplir los 52 ms en este equipo.** El exceso de T-28 se concentra en su tramo principal y no aparece en tramos equivalentes de venta sola | M-1 frente a M-2 y M-3 | Media-alta. Hay dos explicaciones posibles que no se excluyen: (i) **el instrumento de T-28** (por ejemplo, el interceptor de comandos del cliente, que solo existe en `CargaOla3Tests.cs`, o los muestreos del motor) consume CPU compartida con el motor y pesa más en el código de la ola 4; (ii) **un transitorio del tramo principal** (estadísticas que se refrescan de forma síncrona: 171 tareas; crecimiento de archivos: `t28-2.txt:48-49`). M-12 hace menos probable (i) como causa única: si el instrumento es el mismo, en C-1 cumplía. Aun así, el +25 % de CPU de M-7 se midió **en ese tramo** |
| I-2 | **`TR_Documento_Ola4` cuesta unos 15 ms por emisión que no es de POS**, y con A1 corre con la existencia retenida | M-10 y [QA]:94; diseño de A1 ([PROP] 2) | Media. Es una cifra derivada de medias, no de una medición por clase de documento. Se confirma en minutos con una medición de un solo hilo |
| I-3 | La meta 1 (M-4) combina el convoy que queda (I-2) y la competencia de CPU a un 87-89 % de uso | M-4, M-9 | Media |
| I-4 | La cola de la meta 5a es la competencia entre compradoras (la serie `FacturaCxp` se toma al principio y queda retenida mientras la otra recalcula), más I-2 | M-5; [PROP] 1.1 y 4 | Media |
| I-5 | La meta 6 incumple sobre todo por I-2 y por la CPU. Si se quitan unos 15 ms del pago, el p95 queda cerca de 100 ms | M-6, I-2 | Baja-media |
| I-6 | La carga exagera el volumen real de compras más de 50.000 veces (de 1 a 3 usuarios y de 10 a 300 compras al mes, frente a 4,5 compras y 18,6 pagos por segundo) | [BP4]:636, [PROP] 4 | Alta en el orden de magnitud |

**Conclusión del diagnóstico.** Las dos causas candidatas son concretas y baratas de comprobar (I-1 e I-2). Ninguna exige cambiar la numeración. Por eso no recomiendo recalibrar sin diagnosticar, como hace (b) sola, ni rehacer la serie, como hace (c).

---

## 4. Cumplimiento de estándares del proyecto

| Estándar | Situación |
|---|---|
| C3: un hallazgo Alto abierto impide recomendar el avance | Hay tres Altos abiertos. **No se puede recomendar cerrar la ola 4 tal como está** |
| Precedente de C-1 ([CIE3]:110): si el p95 pasa de 52 ms, el Maestro lleva las cifras al propietario | Se cumple con esta hoja |
| ADR-45 y ADR-48 (numeración sin huecos) | No se tocan con (a) ni con (b). Con (c) requieren una precisión nueva |
| ADR-72 | V1 cumplió lo que prometía (M-8). No se reabre |
| D-5 (4), firmada: «la compra no usa el borrador sin número de ADR-72» | Tomar la serie de compras más tarde contradiría D-5. **Queda fuera del tope de (a)**. Si hiciera falta, vuelve para firma |
| Política de procesos y máquina sola | Se incumplió por agentes ajenos: la restauración de POS_EUREKAKIDS invalidó una corrida, y las 14 bases huérfanas son una sospecha en t28-1 ([QA]:13, :45). Ver la sección 9 |

---

## 5. Opciones

| | **(a) Perfilar y corregir, con tope** | **(b) Recalibrar las metas para 4 CPU** | **(c) Adelantar la serie por caja** | **(d) Cerrar ya lo funcional; el rendimiento, en una pista aparte** |
|---|---|---|---|---|
| **Qué es** | Resolver I-1 e I-2 con mediciones baratas, corregir lo que salga (sin tocar las reglas ni el orden de bloqueos) y repetir T-28 ×2 y T-57 ×2 | Fijar metas nuevas (por ejemplo, relativas al tramo sin compras), con la línea base de la ola 0 actualizada | Precisión de ADR-45 (qué ve el usuario y cómo se migra) y construcción | Unir la ola 4 ahora y abrir la 3b. El rendimiento se corrige después, en paralelo |
| **Costo** | **De 0,8 a 1,3 sp.** QA, instrumento y corrida discriminante: 0,1-0,15. Backend, perfil y corrección: 0,3-0,6. Revisión de datos: 0,05. Nueva corrida de QA: 0,3-0,4, más unas 4 h de máquina. Maestro: 0,05 | 0,1-0,2 sp (texto, instrumento y una corrida de línea base de 1 h) | **De 2 a 4 sp** ([PROP] 2, S), más la precisión de ADR-45 y la corrida | 0 sp ahora. Las mismas 0,8-1,3 sp después, más el retrabajo (ver el riesgo) |
| **Cierre de la ola 4** | Hacia el **15 de octubre** (del 14 al 16), frente al 9-10 | Del 10 al 12 de octubre | Del 26 de octubre al 6 de noviembre | Del 9 al 10 de octubre en lo funcional; el rendimiento, hacia el 15-20 |
| **Unión de la 3b** (hoy hacia el 17) | Hacia el **22 de octubre** (del 20 al 28; peor caso, 4 de noviembre) | Del 17 al 19 de octubre | Mediados de noviembre | Hacia el 17 en el papel, pero con conflictos (ver el riesgo) |
| **Inicio de `b/ola5`** (después de la 3b, según S-3) | Hacia el 22-23 de octubre. B sigue adelantando lo que solo crea archivos nuevos | Del 17 al 19 de octubre | Mediados de noviembre. Pone en riesgo el corte de mediados de diciembre | Hacia el 17 |
| **Riesgos** | Que el tope venza sin que se resuelva T-28 (lo cubren F-R2 y F-R3). Unos 5 días de calendario | **Oculta una regresión posible** (+25 % de CPU y 15 ms por emisión) que se suma ola tras ola. T-28 es el banco de la ola 5 (S-14 de [RESP5]): recalibrarlo deja a B sin una referencia limpia. Es el segundo ajuste de la meta en dos olas | **No elimina el punto de serialización:** ADR-45:26 dice que las cajas «siguen en fila por el NCF y por `MovimientoCaja`». En producción, toda venta lleva NCF o e-CF. Cambia la numeración que ve el usuario. No ayuda en las metas 5a ni 6 | Cierra con Altos abiertos, en contra de C3 y del precedente de C-1. La corrección y la 3b tocan los mismos archivos (`LibroInventario`, costo y existencia, ADR-104) y migraciones en la misma rama, lo que va contra la regla de una ola de migraciones a la vez y de un solo editor por árbol. Los cambios de la 3b contaminarían las mediciones de la máquina |
| **Evaluación** | **Recomendada**, con el respaldo (b) acotado (F-R2) | Solo como respaldo condicionado | No por ahora (se mantiene en la entrega 2) | No recomendada |

**Alternativa descartada sin fila propia: medir con el cliente de carga en otro equipo** (la topología real: cajas separadas del servidor). Quitaría la competencia por las 4 CPU, pero mete latencia de red (unos 30 viajes por venta), ocupa la PC B y cambia la base de comparación con C-1. Puede servir para validar la entrega 1 en un equipo parecido al de producción (unas 0,2 sp, inferido), pero no para cerrar esta ola.

---

## 6. Plan recomendado: (a) con tope

### 6.1 Tope

- **Esfuerzo de corrección:** como máximo 0,7 sp de backend y datos.
- **Fecha límite del código:** el **martes 13 de octubre**. Lo que se alcance primero.
- Al vencer el tope, QA repite las cuatro corridas con lo que haya, y se aplica F-R2 o F-R3.

### 6.2 Qué se busca y en qué orden

1. **Corrida discriminante de I-1** (QA, máquina sola, alrededor de 1 h con el enfriamiento). Tiene tres partes:
   - el p95 y la CPU del motor por venta **por minuto** en el tramo principal de T-28;
   - la CPU del motor por venta también en el tramo sin compras de T-57;
   - una corrida de T-28 con el interceptor del cliente desactivado, si el instrumento lo permite (si no, se agrega con un interruptor de entorno).

   Cómo se lee: si sin el interceptor el p95 baja de 52 ms, el problema es el instrumento y no la venta. Se corrige el instrumento, **sin cambiar la meta**, y se presenta la evidencia. Si no baja, el backend atribuye el +1,1 ms de CPU por venta, sentencia por sentencia, con `git diff 4007968..f21b788` sobre el camino de la venta.
2. **Medición de I-2** (backend, sin carga): el costo de `TR_Documento_Ola4` por clase de documento (compra, pago, caja chica y depósito), con un solo hilo. Si se confirma que está en el orden de los 10 ms, se reescribe para que salga temprano o use búsquedas por clave, **sin cambiar ninguna regla (51342 a 51353)**. Arquitecto-datos revisa la migración.
3. **Lo que haga falta de I-1** (backend), con el resultado del punto 1.
4. **Suite completa, Web, MAUI y G-1.5** en verde. Si el propietario firma que E1-2 y E1-1 entran en el cierre de la ola 4 ([RESP5]), deben estar en el commit que se mide, para que la medición final corresponda al código del cierre.
5. **Nueva corrida de QA** con el procedimiento de [PROP] §5: T-28 ×2 y T-57 ×2, unas 3,5 h.

**Fuera del tope** (vuelven a firma si hacen falta): tomar la serie `FacturaCxp` más tarde (contradice D-5), la serie por caja y B' (la barrera sin retener, que no requiere firma, queda en reserva para el backend si persisten las esperas de la venta en `inv.Existencia`).

### 6.3 Respaldo firmado de antemano (F-R2)

Para no volver al propietario si se cumple lo esencial, el respaldo solo se aplica a T-57 y **solo si se cumplen a la vez** todas estas condiciones:
- T-28 ≤ 52 ms en las dos corridas;
- tramo sin compras de T-57 ≤ 52 ms;
- 0 errores 1205, conciliaciones en 0 y 0 repetidos;
- menos de 10 esperas **de la venta** en `inv.Existencia`, contadas con el filtro de O-1, es decir, sin convoy.

Si se cumplen, las metas de T-57 pasan a ser estas:

| Meta | Firmada hoy | Respaldo propuesto | Por qué esa cifra |
|---|---|---|---|
| 1, venta con compras | ≤ 52 ms, o la contingencia F-c (≤ mín(1,15 × sin compras; 60)) | **≤ mín(1,6 × p95 sin compras de la misma corrida; 70 ms)** | Con la CPU al 87-89 % y 4 CPU compartidas, el tiempo de cola crece aproximadamente con 1/(1 − uso): al pasar de un 80 a un 89 % de uso, eso da un factor de unos 1,8 (inferido, modelo de colas). Un 1,15 no es alcanzable en saturación sin que la causa sea un bloqueo. Lo que tiene que probar la ola es que no hay convoy, y eso lo garantiza la condición de las esperas |
| 5a, compra de 20 líneas | ≤ 400 ms con 6 cajeros | **p95 ≤ 600 ms y p50 ≤ 250 ms con 6 cajeros**; alerta a 400 | I-6: la cola mide la competencia entre compradoras, que con 1 a 3 usuarios no existe. El p50 protege contra una regresión del costo real de la compra |
| 6, pago | ≤ 100 ms | **p95 ≤ 130 ms solo en el tramo de 6 cajeros, y p50 ≤ 60 ms** | Se mide en el tramo de 6 cajeros, igual que F-b. Pantalla de oficina; severidad Media ([QA]:137) |

Si se aplica el respaldo, queda como riesgo aceptado **R-3**: las cifras se registran y la **validación en un equipo parecido al de producción** (8 CPU o más, con el cliente separado) entra como condición previa a la puesta en marcha de la entrega 1.

### 6.4 Si T-28 sigue sin cumplir al vencer el tope (F-R3)

No hay cierre automático. El Maestro vuelve con las cifras y con dos opciones: un segundo tope acotado, con causa identificada y estimación, o (c). **T-28 no se recalibra en ningún caso sin una firma nueva.**

---

## 7. Riesgos y mitigaciones

| # | Riesgo | Prob. / impacto | Mitigación | Residual |
|---|---|---|---|---|
| R-1 | I-1 e I-2 no explican el exceso y el tope vence | Media / medio (+1 semana) | F-R2 cubre T-57; F-R3 obliga a volver con datos y no a recalibrar T-28 | Medio en el calendario |
| R-2 | Una corrida contaminada por actividad ajena, como pasó hoy dos veces | Media / alto (repetir 3,5 h) | Sección 9: ventana de máquina sola anunciada, bases huérfanas limpiadas y ninguna restauración ni consulta en `.\SQLEXPRESS` durante la ventana | Bajo |
| R-3 | El respaldo F-R2 esconde una regresión real de la compra o del pago | Baja / medio | El respaldo exige el p50, la ausencia de convoy y T-28 en meta. Validación en un equipo parecido al de producción antes de la entrega 1. La alerta sigue | **Aceptado como residual si se aplica F-R2** |
| R-4 | Retraso de unos 5 días en la 3b y en `b/ola5` | Cierta / bajo-medio | B sigue con lo que solo crea archivos nuevos (S-3). La ola 3 cerró unas cinco semanas antes del corte ([BP4] D-3); margen hasta mediados de diciembre, inferido | Bajo |
| R-5 | La reescritura de `TR_Documento_Ola4` debilita una regla de CA | Baja / alto | Mismas reglas y mismos mensajes; suite completa; revisión de arquitecto-datos; las pruebas de reglas 51342 a 51353 en verde | Bajo |
| R-6 | B mide los índices de la ola 5 con un T-28 inestable (S-14) | Media / bajo | Si I-1 resulta ser el instrumento, corregirlo beneficia también a B. Mientras tanto, B compara antes y después sobre el mismo commit | Bajo |

---

## 8. Recomendación

**Corregir**: no cerrar la ola 4 todavía. Recomiendo seguir la opción **(a) con tope** (sección 6), firmar desde ya el **respaldo (b) acotado a T-57** (F-R2), no recalibrar T-28, mantener **(c) en la entrega 2** y **no cerrar lo funcional** por adelantado (d).

**ADR propuesto:** no aplica. Nada de esto cambia una decisión de arquitectura:
- F-R2, si se aplica, es una precisión de las metas de [BP4] 14.3 (D-4), como F-b y F-c;
- si I-2 se confirma, la reescritura del disparador es un detalle técnico que se registra en el commit y en el informe de datos.

---

## 9. Quién hace qué y en qué orden

Hay un solo editor por árbol, de modo que los pasos que tocan `GPOS-NG-numeracion` van en serie. Las ventanas marcadas con **[MS]** requieren la máquina sola: ningún otro agente compila ni prueba en la PC A, nadie restaura ni consulta bases en `.\SQLEXPRESS`, y se revisan los procesos huérfanos (`dotnet`, `testhost`, bash y pwsh) antes de empezar.

| Orden | Agente | Tarea | sp / máquina | Fecha objetivo (inferida) |
|---|---|---|---|---|
| 0 | coordinador | (1) Borrar las 14 bases `GPOS_TEST_*` huérfanas de `.\SQLEXPRESS` (O-3), después de confirmar que ninguna es de una prueba en curso; son bases de prueba, no de clientes. (2) Avisar a B y al propietario de las ventanas [MS]. (3) Ninguna restauración (como la de POS_EUREKAKIDS) mientras duren | 0,02 | 9 de octubre |
| 1 | qa-automatizado | Corregir O-1 (esperas de la venta con filtro), O-2 (comentario), O-4 (disparadores por ejecución) y el desglose por minuto, más el interruptor del interceptor del cliente en T-28 | 0,1 | 9 de octubre |
| 2 | qa-automatizado **[MS]** | Corrida discriminante de I-1 (6.2, punto 1) | 0,05 · ~1 h | 9 o 10 de octubre |
| 3 | desarrollador-backend | Medir I-2 por clase de documento (sin carga) y corregir `TR_Documento_Ola4`. Después, lo que indique el paso 2 sobre la CPU de la venta | 0,3-0,6 | del 10 al 13 de octubre |
| 4 | arquitecto-datos | Revisar la migración del disparador (reglas intactas, búsquedas por clave) | 0,05 | 12-13 de octubre |
| 5 | desarrollador-backend | Suite completa, Web, MAUI y G-1.5; E1-2 y E1-1 dentro, si se firman | incluido | 13 de octubre (tope) |
| 6 | qa-automatizado **[MS]** | T-28 c1 → 15 min → T-28 c2 → 15 min → T-57 c1 (con muestreo) → 15 min → T-57 c2, con el informe meta por meta y la evaluación de F-R2 | 0,3-0,4 · ~3,5-4 h | 14 de octubre |
| 7 | arquitecto-maestro | Consolidar: cerrar con F-R2 si se cumplen sus condiciones; si no, aplicar F-R3 | 0,05 | 14-15 de octubre |
| 8 | orquestador | Registrar el esfuerzo real y abrir la 3b tras el cierre | — | 15 de octubre |
| 9 | documentador-tecnico | Registrar lo firmado (F-R1 a F-R5) como precisión de [BP4] 14.3 y la consecuencia en ADR-72 | 0,02 | tras la firma |

---

## 10. Filas de firma

| # | Decisión | Opciones | Recomendación | Firma |
|---|---|---|---|---|
| **F-R1** | **Rendimiento de la ola 4: opción (a) con tope.** Diagnosticar I-1 (contradicción entre tramos de T-28 y T-57) e I-2 (`TR_Documento_Ola4`, unos 15 ms por emisión que no es de POS), corregir sin cambiar las reglas ni el orden de bloqueos, y repetir T-28 ×2 y T-57 ×2. Tope: 0,7 sp de corrección o el 13 de octubre; total de 0,8 a 1,3 sp | A. Aprobar · B. Solo (b) · C. Adelantar (c) | **A. Aprobar** | [ ] A · [ ] B · [ ] C |
| **F-R2** | **Respaldo (b) firmado de antemano, solo para T-57.** Se aplica únicamente si T-28 ≤ 52 en las dos corridas, el tramo sin compras ≤ 52, 0 errores 1205, conciliaciones y repetidos en 0, y menos de 10 esperas de la venta en `inv.Existencia`. Metas: 1 ≤ mín(1,6 × sin compras; 70 ms); 5a p95 ≤ 600 y p50 ≤ 250 con 6 cajeros (alerta a 400); 6 p95 ≤ 130 y p50 ≤ 60 con 6 cajeros. Riesgo residual R-3 aceptado y validación en un equipo parecido al de producción antes de la entrega 1 | A. Aprobar · B. Sin respaldo (todo vuelve a firma) · C. Otras cifras | **A. Aprobar** | [ ] A · [ ] B · [ ] C |
| **F-R3** | **T-28 sigue con p95 ≤ 52 ms y sin recalibrar.** Si el diagnóstico demuestra que el exceso es del instrumento, se corrige el instrumento con evidencia y la meta no cambia. Si al vencer el tope T-28 no cumple, el Maestro vuelve con un segundo tope o con (c) | A. Aprobar · B. Recalibrar también T-28 | **A. Aprobar** | [ ] A · [ ] B |
| **F-R4** | **La ola 4 no se cierra en lo funcional antes de tiempo.** La 3b espera al cierre; B sigue adelantando en `b/ola5` solo lo que crea archivos nuevos (S-3) | A. Aprobar (no cerrar antes) · B. Cerrar lo funcional ya, con el rendimiento en una pista aparte | **A. Aprobar.** B cierra con Altos abiertos, mezcla migraciones y archivos con la 3b, y contamina las mediciones | [ ] A · [ ] B |
| **F-R5** | **La serie por caja (c) se mantiene en la entrega 2** | A. Mantener · B. Adelantarla a la entrega 1 (de 2 a 4 sp) | **A. Mantener.** No quita el NCF ni `MovimientoCaja` como puntos de serialización (ADR-45:26) | [ ] A · [ ] B |

**Sin firma** (dentro de lo decidido): la limpieza de las bases huérfanas, los ajustes del instrumento de QA (O-1, O-2 y O-4), la medición de I-2 y B' en reserva.

**Si el usuario firma:** el coordinador abre el paso 0 el 9 de octubre, y el plan de la sección 9 sigue sin más firmas hasta el paso 7.

**Si el usuario rechaza:**
- F-R1 B: QA corre la línea base para 4 CPU (1 h) y el Maestro redacta las metas nuevas, de 0,1 a 0,2 sp. El cierre queda hacia el 12 de octubre y se acepta R-3 sin condiciones.
- F-R1 C: el Maestro prepara la precisión de ADR-45 (P-06 de [CIE3]) y la ola 4 sigue abierta entre 2 y 4 semanas.
- F-R2 B: al terminar el tope, toda cifra fuera de la meta vuelve a firma, con un día más de espera.
- F-R4 B: el orquestador une la ola 4 ya y la 3b se construye sobre ella. Las mediciones esperan a que haya una ventana [MS] sin la 3b compilando.

---

### Cierre
- Estado: Completado (hoja preparada; decisión **Pendiente de firma**). Recomendación: **Corregir** con (a) con tope, el respaldo F-R2 acotado a T-57 y T-28 sin recalibrar
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\hoja-firma-rendimiento-ola4-2026-10-08.md`
- Supuestos:
  - Las fechas son inferidas y parten de que el equipo A trabaja de forma continua.
  - El factor de colas que justifica 1,6 es un modelo aproximado.
  - I-1 e I-2 son inferencias a partir de las salidas de QA.
  - E1-2 y E1-1 entran en el cierre solo si se firman aparte.
- Decisiones candidatas a ADR: ninguna. F-R2 sería una precisión de [BP4] 14.3 (D-4)
- Entregas a otros agentes:
  - coordinador → bases huérfanas y ventanas [MS].
  - qa-automatizado → O-1, O-2, O-4, el desglose por minuto, el interruptor del interceptor, la corrida discriminante y la nueva corrida de las cuatro pruebas.
  - desarrollador-backend → I-2 e I-1.
  - arquitecto-datos → revisar la migración del disparador.
  - orquestador → el esfuerzo y la apertura de la 3b.
  - documentador-tecnico → registrar lo firmado.
- Próximo paso recomendado: que el propietario firme F-R1 a F-R5 y que el coordinador limpie `.\SQLEXPRESS` antes de la corrida discriminante.
