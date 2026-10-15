# Validación del arquitecto: interpretaciones del PR #31 (L1a-3 «Motor de estados» de la licencia)

- **Fecha:** 2026-10-14. **Autor:** arquitecto-software, equipo A. Actúo como dueño del blueprint.
- **Objeto:** PR #31 de `lfmendezb/GPOS-NG`, rama `a/lic-l1a-3` @ `4f86390b`. Lo leí en solo lectura en el árbol `GPOS-NG-lic3`. No edité código, no hice commits y no compilé ni ejecuté pruebas.
- **Contrato:**
  - `blueprint-licencia-lote2-2026-10-14.md` v2.1 (§4.1 L1a-3, §5, §6.1, §6.2 y §7), en adelante **[BP]**;
  - `[LIC]` = `docs/arquitectura/2026-10-05-licencia-por-vigencia.md`, §3.2, §4.1, §4.1.1 a §4.1.3, §4.2, §4.6, §8.5 y §8.6;
  - `docs/adr/ADR-059.md` (puntos 2 a 5 y la precisión CW-02) y `docs/adr/ADR-061.md` (punto 5, NV-08);
  - `[DAT]` = `datos-t3-12-rg14-2026-10-14.md`, línea 1019.
- **Se incorpora la revisión del auditor:** `revision-seguridad-pr31-motor-estados-2026-10-14.md` (**[SEG-PR31]**: «Aprobado con observaciones», 2 Medios y 5 Bajos).
- **Resultado:** el blueprint pasa a la **v2.2**:
  - registro de cambios v2.2;
  - §4.1 (L1a-3);
  - §5.1 (S-03);
  - §6.1.1, nueva;
  - §7;
  - §13.1 (DL-15);
  - cierre.
- **Etiquetas:** **[V]** verificado en el código con `ruta:línea` sobre `4f86390b`; **[I]** inferido.

---

## 1. Dictamen por punto

| # | Interpretación del PR | Dictamen | Motivo y evidencia |
|---|---|---|---|
| 1 | Archivo `EstadosLicencia.cs` además de `MotorEstados.cs` | **Confirmado** (queda en [BP] §7) | Separa los tipos de [LIC] 8.5 y 8.6 de las funciones, en la carpeta de [BP] §7. `CLAUDE.md` no exige un tipo por archivo |
| 2 | `PorVencer` empieza en el corte de `vence − avisoDias + 1` | **Confirmado**, con la corrección 5 | [LIC] 4.1: la empresa sigue `Vigente` mientras «`ahora` ≤ `vence` − `avisoDias`». Con el cambio «a las 06:00 del día siguiente» (ADR-59, punto 2), `PorVencer` empieza en el corte de `vence − avisoDias + 1`: son los `avisoDias` días que terminan en `vence`, incluido (`MotorEstados.cs:76`, `:98-101` [V]). `avisoDias` va de 1 a 60 ([LIC] 3.2). Fuera de ese rango se aplica la corrección 5 (SEG-PR31-03) |
| 3 | NV-02 con el `graciaDias` y el `horaCorte` de la vigente; el fin de la gracia previa sale de la anterior; la fórmula; el corte inmediato solo con firma Avanzada propia (si no, `CorteIgnorado`) | **Confirmado** en la fórmula, en los parámetros y en CW-02. **Se corrige** cómo se obtienen el derecho previo y la gracia previa (correcciones 1, 6 y 7) | La fórmula y CW-02 coinciden con ADR-59, punto 4, y con su precisión (`MotorEstados.cs:286-292` [V]). Los parámetros son los de la vigente, que es la que firma GSF para cerrar el caso ([LIC] 4.6). El PR obtiene el derecho previo solo de la entrada de la anterior (`:276-281`), y por eso pierde una transición que ya estaba en curso (H-1) |
| 4 | Las gracias especiales no se redondean al corte; las transiciones sí | **Corregir** (corrección 4) | ADR-59, punto 2, fija un único momento para el cambio de estado: «a las 06:00, hora de RD, del día siguiente». Q-09 lo eligió para no cortar de noche. Una gracia de entorno que termina a las 20:00 corta una caja en pleno turno. Redondear alarga la gracia como máximo 24 h y nunca pasa del tope de NV-01, que ya es un corte. [LIC] 3.3.1, 3.6 y 4.1.2 solo dan la duración: es una precisión, no un cambio de decisión |
| 5 | Tope de NV-08: el fin del último día pagado | **Confirmado** | ADR-61, punto 5: «nunca más allá de su `vence`», y `vence` es el último día pagado (Q-04). Su fin es el corte de `vence + 1` (`MotorEstados.cs:316-317` [V]) |
| 6 | Código de empresa sin distinguir mayúsculas; RNC comparado solo por sus dígitos | **Código: confirmado. RNC: corregir** (corrección 9, igual que SEG-PR31-06) | La comparación del código coincide con la de SQL Server, y un duplicado falla cerrado (`:370-381` [V]). La corrección 5 cierra la salvedad de SEG-PR31-03. El RNC: `Digitos` descarta cualquier carácter que no sea un dígito (`:394` [V]) |
| 7 | NV-07 con una sola fila por empresa: (a) A→B→C sin licencia nueva deja `Invalida`; (b) la transición por cambio de RNC dura como mínimo hasta el fin de la gracia por vencimiento de la entrada | **(a) El motor está bien; se precisa S-03.** **(b) Confirmado para la licencia que regía en el cambio; se corrige para las posteriores** (corrección 2, que resuelve SEG-PR31-01) | **(a)** Con la fila (B, C), el motor no puede probar A→B, y `Invalida` es la salida que falla cerrado. El remedio está en lo que escribe S-03: la fila dice siempre «del RNC licenciado al actual» ([BP] 5.1 v2.2), y entonces A→B→C deja (A, C, t1). **(b)** Es la intención con la licencia que regía cuando se hizo el cambio: no acorta el período pagado ([LIC] 4.1) y el ancla `emitida` + 7 d impide alargarlo. El PR la aplica también a las licencias aceptadas **después** del cambio, y eso hace la transición permanente (`:239-250` [V]; SEG-PR31-01). **Decisión sobre SEG-PR31-01:** se adopta `AceptadaUtc ≤ CambiadoUtc`, la variante estricta del auditor, más el respeto del corte Avanzado. Se descarta `Emitida < CambiadoUtc`: un archivo en tránsito, emitido antes y cargado después del cambio, ya está cubierto por la corrección 1 (a), porque la empresa conserva la transición que tenía. Con una licencia posterior que trae el RNC anterior, la empresa **conserva sin alargar** la transición en curso y después queda `Invalida`; no queda `Invalida` en el acto. Esto respeta «nunca acorta una gracia que la empresa ya tenía» y «una transición por `sec`», y es la lectura de «hasta la licencia nueva» de [LIC] 2 compatible con NV-02. No hace falta una aceptación de residual |
| 8 | Forma de `Licencia.Gracias` (última verificación más un fin por empresa, `TopeGraciaUtc`) y de `CambioRncSuper` | **Confirmado, con precisión** (correcciones 3 y 4) | `Licencia.Gracias` agrega `HoraCorte`. `TopeGraciaUtc` pasa a reflejar las gracias especiales (SEG-PR31-02). Las marcas de inicio de entorno y de retiro son de la instalación, no de cada empresa como dice `[DAT]`:1019; las consume L1a-4. El JSON lo fija el arquitecto de datos. `CambioRncSuper(RncAnterior, RncNuevo, CambiadoUtc)` coincide con C-06, con una fila por empresa según S-03 v2.2 |
| 9 | Hora de evaluación = máx(hora protegida, `emitida`); aviso si el reloj está más de 24 h antes de `emitida`, sin bloquear | **Confirmado, con precisión** | Coincide con ADR-59, punto 5, y con [LIC] 4.1.3 (`:43-52` [V]). L1b pasa a `RelojAnteriorAEmitida` el **reloj del sistema** (`TimeProvider`) y registra `RelojInconsistente` |

## 2. Hallazgos propios y del auditor

| # | Sev. | Hallazgo | Corrección |
|---|---|---|---|
| **H-1** (propio) | Media | **Una licencia nueva corta la transición que la empresa ya tenía.** Ejemplo: L1 incluye la empresa, L2 la omite y abre la transición, y L3 la sigue omitiendo. Con la pareja (L2, L3), la empresa queda `NoLicenciada` en el acto. Contradice [LIC] 4.1 («nunca acorta una gracia que la empresa ya tenía») y ADR-59, punto 4 (`MotorEstados.cs:276-278`; `EstadosLicencia.cs:83-84` [V]) | 1 |
| SEG-PR31-01 (= punto 7 (b)) | Media | La fila `CambiosRnc` sirve contra cualquier licencia posterior | 2 |
| SEG-PR31-02 | Media | `TopeGraciaUtc` no refleja las gracias especiales | 3 |
| SEG-PR31-03 | Baja | Parámetros firmados sin acotar | 5 |
| SEG-PR31-04 | Baja | Instantes de referencia sin acotar | 6 |
| SEG-PR31-05 | Baja | No se comprueba el orden de las licencias anteriores | 7 |
| SEG-PR31-06 | Baja | RNC comparado por dígitos | 9 |
| SEG-PR31-07 | Baja | La guarda de pureza es una lista negra | 10 |
| **H-3** (propio) | Media | **Un archivo sin firma Avanzada propia puede cortar a una empresa en horas** con un `vence` cuya gracia termina poco después de la aceptación: en la aceptación la empresa sigue operando y no se abre la transición. **El PR cumple el texto firmado** («un `vence` cuya gracia **ya terminó**», [LIC] 4.1.1) (`:283-285` [V]) | Ninguna: es **DL-15**, Pendiente de firma ([BP] 13.1) |

---

## 3. Lista única de correcciones para el desarrollador (PR #31)

Texto exacto que debe cumplir el código; las reglas están también en [BP] 6.1.1. Cada una lleva al menos las pruebas indicadas.

**1. Derecho previo en cadena (H-1; punto 3).**
- `SituacionLicencia.Anterior` se sustituye por `IReadOnlyList<LicenciaAceptada> Anteriores`: las licencias aceptadas antes de la vigente, en orden descendente de `sec`. L1a-4 entrega al menos las 24 últimas. Más allá de la lista no hay derecho previo (falla cerrado).
- Sea `t` la hora de referencia de la vigente (corrección 6) y `E(t)` la empresa como era en `t` (`EmpresaEn`).
- Se calcula `r = Evaluar(E(t), situación con Vigente = Anteriores[0], Anteriores = el resto, Especiales = ninguna, Ilegible = false, AhoraProtegidoUtc = t)`.
- «Tenía derecho» ⇔ `r.Opera`. «Fin de la gracia previa» = `r.TopeGraciaUtc`.
- Si la vigente deja la empresa sin operar en `t`:
  - **(a)** si `r.Motivo == MotivoGracia.Transicion`, **no se abre otra transición**: la empresa sigue en `EnGracia(Transicion)` hasta `r.TopeGraciaUtc`, sin alargarlo, con la `TransicionLicencia` de `r`;
  - **(b)** si no, se abre la transición hasta `máx(r.TopeGraciaUtc, SiguienteCorte(mín(t, emitida + 7 d) + máx(graciaDias, 72 h), horaCorte))`, con la `emitida`, el `graciaDias` y el `horaCorte` de la vigente.
- Con `corte: "inmediato"` y firma Avanzada propia en la entrada de la vigente no se aplica ni (a) ni (b). Sin esa firma, se marca `CorteIgnorado` y se aplica (a) o (b).
- **Pruebas:**
  - L1 incluye, L2 omite y L3 omite dentro de la transición de (L1, L2): la empresa sigue en `EnGracia(Transicion)` hasta el mismo fin;
  - QA-L14 sigue en verde;
  - una lista truncada no da derecho.

**2. Cambio de RNC: la fila solo vale con la licencia que regía en el cambio (SEG-PR31-01; punto 7 (b)).**
- En `EvaluarBajo`, la fila `CambioRncSuper` da transición solo si se cumplen **todas** estas condiciones:
  - `RncAnterior` = RNC de la entrada;
  - `RncNuevo` = RNC actual de la empresa;
  - la gracia por vencimiento de la entrada no había terminado en `CambiadoUtc`;
  - **`licencia.AceptadaUtc <= cambio.CambiadoUtc`**;
  - **la entrada no trae `corte: "inmediato"` con firma Avanzada propia**.
- Fin = `máx(fin de la gracia por vencimiento de la entrada, SiguienteCorte(mín(CambiadoUtc, emitida + 7 d) + máx(graciaDias, 72 h), horaCorte))`.
- Con una licencia aceptada después del cambio, la fila no da transición propia: rige la corrección 1 (a) y, al terminar, `Invalida`.
- **Pruebas:**
  - L2, el cambio A→C y después L3 con A y un `vence` lejano: la empresa queda `Invalida` al fin de la transición de L2, no al fin de la gracia de L3;
  - una licencia de corte con firma Avanzada y una fila: sin transición.

**3. `TopeGraciaUtc` refleja las gracias especiales (SEG-PR31-02).**
- En `AplicarEspeciales`:
  - si el resultado es `SoloConsulta` por una gracia especial, `Tope = null`;
  - si es `EnGracia` por una gracia especial, `Tope = fin` de esa especial, que ya está limitado al tope.
- Lo mismo vale en `EvaluarIlegible`: `SoloConsulta` da `Tope = null`.
- **Pruebas:**
  - `TopeGraciaUtc` en los dos casos;
  - una fila `GraciasGuardadas` construida con ese tope no da `Ilegible`.

**4. Toda gracia termina en un corte (punto 4).**
- `GraciaEntorno`, `GraciaLlaveRetirada` y `GraciaIlegible` reciben `TimeOnly horaCorte` y devuelven `HastaUtc = SiguienteCorte(desde + duración, horaCorte)`.
- El `horaCorte` es el de la vigente en las dos primeras. En `Ilegible` es `GraciasGuardadas.HoraCorte`, un campo nuevo; si falta, 06:00.
- Después se aplican los topes, como hoy: NV-01, el fin de vigencia en NV-08 y el fin guardado.

**5. Parámetros acotados con falla restrictiva (SEG-PR31-03).**
- `EstadoPorFechas` devuelve `Vigente` solo si `ahora < mín(InicioPorVencer, FinVigencia)`.
- `Evaluar` comprueba los rangos de [LIC] 3.2 antes de calcular:
  - `graciaDias` de 0 a 30;
  - `avisoDias` de 1 a 60;
  - `horaCorte` con el formato `HH:mm`;
  - `vence` y `emitida` con un año de 2000 a 2100 [I, margen contra desbordamientos].
- Si no se cumplen, el resultado es `NoLicenciada` para esa licencia, **sin lanzar excepción**. Aplicado a una anterior, quiere decir «sin derecho previo».
- Una entrada duplicada (código igual sin distinguir mayúsculas) en la vigente **no abre transición**.
- L1b trata cualquier excepción del motor como «no opera».

**6. Instantes de referencia acotados (SEG-PR31-04).**
- `t = máx(vigente.AceptadaUtc, vigente.Contenido.Emitida)` para la condición de apertura, `EmpresaEn` y el ancla.
- En la gracia `Ilegible`, `desde = mín(GraciasGuardadas.UltimaVerificacionUtc, ahora)`.

**7. Orden de las licencias anteriores (SEG-PR31-05).**
- `Anteriores` se recorre en orden. Se descarta, junto con todo lo que le sigue, el primer elemento que no cumpla: `sec` < `sec` del elemento previo (para el primero, el de la vigente) y `AceptadaUtc` ≤ `AceptadaUtc` del elemento previo. Es falla cerrada: sin derecho previo.
- El XML de `SituacionLicencia` lo documenta.

**8. Duplicado en la fila guardada.** No cambia: ya falla cerrado (`:349-360` [V]).

**9. RNC canónico (SEG-PR31-06; punto 6).**
- `MismoRnc` quita **solo** los espacios y los guiones.
- Si el resultado no tiene exactamente 9 u 11 caracteres o alguno no es un dígito ASCII (`'0'..'9'`), **no coincide**.

**10. Guarda de pureza (SEG-PR31-07).**
- Agregar a la lista prohibida `TimeZoneInfo`, `DateTime.ToLocalTime`, `DateTime.ToUniversalTime`, `DateTimeOffset.ToLocalTime` y `CultureInfo.CurrentCulture`/`CurrentUICulture`.
- Prohibir cualquier tipo `GPOS.*` fuera de `GPOS.Contracts`, `GPOS.Core.Sistema.Licencia` y `HoraEmpresa.DesfaseUtc`.
- La lista blanca completa es recomendable, no obligatoria.

**Precisiones para otras piezas (no cambian el PR):**
- L1a-2 rechaza los códigos de empresa duplicados sin distinguir mayúsculas.
- L1a-4:
  - persiste en `Licencia.Gracias` el `TopeGraciaUtc` tal cual (null incluido) y el `HoraCorte`;
  - entrega `Anteriores` (corrección 1). Sustituye la entrega de [SEG-PR31] «solo la inmediatamente anterior»;
  - sigue pasando las gracias especiales abiertas, también con la licencia ilegible.
- L1b pasa el reloj del sistema a `RelojAnteriorAEmitida`.
- RN (S-03 y `--cambiar-rnc`) escribe la fila «del RNC licenciado al actual» ([BP] 5.1 v2.2), dentro de DL-03.

**Costo [I]:** ≈ 0,7 dp en L dentro del PR. Lo absorbe el margen de L ([BP] 11: unos 24,3 dp sobre unos 34,4).

| Corrección | Costo |
|---|---|
| 1 | 0,3 |
| 2 | 0,1 |
| 3 | 0,05 |
| 4 | 0,1 |
| 5 | 0,05 |
| 6 y 7 | 0,04 |
| 9 | 0,02 |
| 10 | 0,03 |
| L1a-4 | +0,05 |
| RN | +0,05 |

**Recomendación:** hacer las correcciones 1 a 7, 9 y 10 en este PR, antes de unirlo. Son del motor puro, y L1a-4 todavía no lo consume.

---

### Cierre
- Estado: Aprobado con observaciones.
  - De las nueve interpretaciones:
    - se confirman 1, 2, 5, 8 y 9 (2, 8 y 9 con precisión);
    - la 3 se confirma con correcciones;
    - se corrigen la 4 y el RNC de la 6;
    - la 7 (a) se resuelve en S-03 y la 7 (b) se confirma acotada (corrección 2).
  - SEG-PR31-01 se decide con `AceptadaUtc ≤ CambiadoUtc` y la conservación de la transición en curso, sin necesidad de un residual aceptado.
  - Quedan tres hallazgos Medios abiertos en el código (H-1, SEG-PR31-01 y SEG-PR31-02): conviene cerrarlos antes de unir.
  - H-3 queda como DL-15, Pendiente de firma.
- Artefactos:
  - `C:\Users\lfmen\source\repos\Solucion GPOS NG\validacion-l1a-3-motor-estados-2026-10-14.md`;
  - `C:\Users\lfmen\source\repos\Solucion GPOS NG\blueprint-licencia-lote2-2026-10-14.md` (v2.2).
- Supuestos:
  - El código leído es `4f86390b`; no lo compilé ni ejecuté las pruebas.
  - El SUPER es siempre de la plataforma.
  - El rango de años de 2000 a 2100 es mío.
- Decisiones candidatas a ADR:
  - **DL-15**, precisión de ADR-59, punto 4: acortar el `vence` sin firma Avanzada propia garantiza el mínimo de la transición. Alternativa descartada: no acortar nunca por debajo del fin previo.
  - Las reglas de 6.1.1 son precisiones de ADR-59 y ADR-61.
- Entregas a otros agentes:
  - **desarrollador-backend (L):** correcciones 1 a 7, 9 y 10; L1a-4 según las precisiones.
  - **desarrollador-backend (I):** fila de S-03 v2.2 cuando se firme DL-03.
  - **arquitecto-datos:** JSON de `Licencia.Gracias` con `HoraCorte`, `TopeGraciaUtc` admitiendo null y las marcas por instalación.
  - **arquitecto-maestro:** DL-15 y precisión de DL-03.
  - **auditor-seguridad:** lectura de diferencias de las correcciones 1 y 2.
  - **qa-automatizado:** las pruebas de las correcciones 1 a 3.
- Próximo paso recomendado: que L aplique las correcciones en `a/lic-l1a-3` y B valide de nuevo antes de unir.
