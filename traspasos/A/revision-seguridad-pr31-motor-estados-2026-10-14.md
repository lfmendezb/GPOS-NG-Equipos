# [Informe de Seguridad] PR #31: licencia L1a-3, motor de estados

**Fecha:** 2026-10-14 · **Auditor:** auditor-seguridad · **Rama:** `a/lic-l1a-3` @ `4f86390b`, base `feature/modelo-ng` · **Modo:** solo lectura (sin compilar ni ejecutar pruebas; no se publicó nada en GitHub)

**Referencias:** blueprint de la licencia del lote 2 v2.1 (§4.1 L1a-3, §6.1, §6.2, §8, §10.5); `docs/adr/ADR-059.md`; `[LIC]` = `docs/arquitectura/2026-10-05-licencia-por-vigencia.md` (4.1, 4.1.1 a 4.1.3, 3.3.1, 3.6); informes previos `revision-seguridad-blueprint-licencia-lote2-2026-10-14.md` (SEG-L2-16, CW-02) y `revision-seguridad-pr29-pr30-criptografia-2026-10-14.md`.

**Convención:** [V] verificado leyendo el código de la rama; [I] inferido (depende de piezas que aún no existen, L1a-2, L1a-4 o L1b). Las rutas son relativas a la raíz del árbol `GPOS-NG-lic3`.

## 1. Alcance y superficie revisada

| Archivo | Líneas | Contenido |
|---|---|---|
| `src/GPOS.Core/Sistema/Licencia/EstadosLicencia.cs` | 117 | Enumeraciones y tipos de entrada y salida |
| `src/GPOS.Core/Sistema/Licencia/MotorEstados.cs` | 407 | Motor puro: reloj, calendario, NV-01, NV-02, NV-07 con SEG-L2-16, NV-08, ilegible, CW-02, `CodigoBloqueo` |
| `tests/GPOS.Tests/Arquitectura/MotorEstadosLicenciaPuroTests.cs` | 136 | Guarda de pureza por lectura del IL |
| `tests/GPOS.Tests/Licencia/MotorEstadosTests.cs` | 572 | 57 pruebas del motor |

**Superficie expuesta:** ninguna directa. No hay rutas, persistencia ni `Program.cs`, y ningún código de producción referencia el motor todavía [V]. El riesgo está en el **contrato**: lo que el motor devuelve, sobre todo `TopeGraciaUtc`, que L1a-4 guardará en la fila con MAC `Licencia.Gracias`, y el estado que L1b usará para bloquear. Los datos de entrada están firmados por GSF (contenido de la licencia) o protegidos con MAC (fila `CambiosRnc`, `Gracias`, marcas). El atacante modelado es el propio cliente con `sysadmin` de SQL o administración de Windows, y su SUPER con segundo factor.

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título | Estado |
|---|---|---|---|
| SEG-PR31-01 | **Media** | La fila `CambiosRnc` sirve también para las licencias posteriores al cambio: la transición por RNC se vuelve permanente | Verificado |
| SEG-PR31-02 | **Media** | `TopeGraciaUtc` no refleja las gracias especiales ni queda en null en `SoloConsulta` por gracia especial: la gracia `Ilegible` puede reabrir 72 h | Verificado (motor); explotación inferida (depende de L1a-4) |
| SEG-PR31-03 | Baja | El motor no acota los parámetros firmados: `avisoDias` negativo prolonga `Vigente` más allá de la gracia; los desbordamientos lanzan excepción | Verificado |
| SEG-PR31-04 | Baja | Instantes de referencia no acotados: aceptación anterior a `emitida` y última verificación posterior a la hora protegida | Verificado |
| SEG-PR31-05 | Baja | Sin comprobación del orden entre `Anterior` y `Vigente` | Verificado |
| SEG-PR31-06 | Baja | Comparación del RNC por dígitos que admite cualquier otro carácter | Verificado |
| SEG-PR31-07 | Baja | La guarda de pureza es una lista negra de un solo nivel | Verificado |

## 3. Checklist OWASP (aplicado a una pieza pura)

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | **Con observaciones.** El motor decide si la empresa opera (base del 403 de L1b). SEG-PR31-01 y SEG-PR31-02 permiten operar más allá de lo firmado en escenarios concretos |
| A02 Fallos criptográficos | No aplica: el motor no verifica firmas ni MAC; recibe filas ya verificadas o null [V] (`EstadosLicencia.cs:52-58`, `:67-74`) |
| A03 Inyección | No aplica: no hay consultas, plantillas ni intérpretes |
| A04 Diseño inseguro | **Con observaciones** (SEG-PR31-01, -02, -05) |
| A05 Configuración | No aplica: sin interruptores ni configuración; los parámetros salen de la licencia firmada |
| A06 Componentes vulnerables | No aplica: no agrega paquetes |
| A07 Autenticación | No aplica |
| A08 Integridad de datos | **Con observaciones** (SEG-PR31-03, -04): el motor confía en rangos que validará L1a-2 |
| A09 Registro y monitoreo | Correcto para esta pieza: el resultado trae `Transicion`, `CorteIgnorado` y `Motivo` para los eventos `LicenciaTransicion`, `CorteIgnorado` y `EstadoLicenciaCambiado`; la escritura es de L1b |
| A10 SSRF | No aplica |

## 4. Hallazgos

### SEG-PR31-01 · Media · La fila `CambiosRnc` sirve también para las licencias posteriores al cambio

- **Riesgo.** `EvaluarBajo` acepta la fila del SUPER contra cualquier licencia cuyo RNC sea `RncAnterior`, sin relacionar la fila con la licencia que regía cuando se hizo el cambio (`MotorEstados.cs:235-251`). Si después del cambio A→B se acepta otra licencia que todavía trae el RNC A (renovación mensual del agente con el catálogo de GSF sin actualizar, o una solicitud L-06 editada), el ancla queda en la hora del cambio, ya pasada, y el fin es `máx(finGracia de la licencia nueva, …)` = **todo el período de la licencia nueva más su gracia**. Lo mismo ocurre con cada renovación siguiente: la empresa opera indefinidamente con el RNC B sobre licencias emitidas para A y **nunca llega a `Invalida`**.
- **Contraste con lo firmado.** `[LIC]` 2 (amarre 2): «Si una empresa cambia de RNC, recibe la gracia de transición (4.1.1) **hasta la licencia nueva**». `[LIC]` 4.1.1: «cada empresa recibe como máximo una gracia de transición por `sec`». Con NV-02, la licencia nueva con RNC A no abre transición, porque a la hora de aceptación la empresa ya tenía el RNC B (`MotorEstados.cs:274-278` lo calcula así para la transición por licencia, pero `EvaluarBajo` la vuelve a conceder por la vía del RNC). El PR lo reconoce como lectura literal en «Pendientes y supuestos» («dura al menos hasta el fin de la gracia por vencimiento de la entrada»), sin acotarla a una `sec`.
- **Evidencia [V].** `MotorEstados.cs:239` (la condición no mira `AceptadaUtc` ni `Emitida` frente a `CambiadoUtc`); `:244-245` (ancla = mín(cambio, `emitida` + 7 d) → con un cambio anterior el ancla es fija y el fin es `finGracia` de cada licencia nueva). Ninguna prueba cubre una licencia posterior con el RNC anterior (`MotorEstadosTests.cs:203-276`; solo existe el caso «con el RNC nuevo cierra la transición», `:266`).
- **Impacto.** Se pierde el amarre comercial del RNC (`[LIC]` 2, amarre 2) para esa empresa desde el primer cambio, sin más acción del SUPER. La transición deja de ser transitoria. El daño económico directo es bajo (el período sigue pagado), pero el control firmado NV-07 queda sin efecto a partir de la segunda licencia.
- **Remediación (unos 0,1 dp, más la decisión del arquitecto).**
  1. La fila solo da transición contra la licencia que regía cuando se hizo el cambio: exigir `licencia.AceptadaUtc ≤ CambiadoUtc` (alternativa más tolerante con un archivo en tránsito: `Contenido.Emitida < CambiadoUtc`, porque GSF no podía conocer el cambio). Para una licencia posterior con el RNC anterior rige NV-02: `Invalida` sin transición, y la salida es una licencia con el RNC nuevo (el emisor toma el RNC de la solicitud, R-L8).
  2. Respetar también en esta vía la marca `corte: "inmediato"` con firma Avanzada propia (hoy solo se mira en `TransicionPorLicencia`, `:286-287`). Así una licencia de corte con firma Avanzada no concede la transición por RNC.
  3. Agregar pruebas: licencia posterior con el RNC anterior → `Invalida`; licencia de corte con firma Avanzada y una fila previa → sin transición.
- **Residual que queda.** Un SUPER con segundo factor puede repetir el vaivén A→B→A en cada licencia nueva. Es el residual aceptado en `[LIC]` 4.1.1 («basta la regla de la ruta del SUPER», sin el límite de 90 días). Cada cambio deja un evento crítico visible.
- **Alternativa descartada:** atar la fila a la `sec` de la licencia. Es más precisa, pero obliga a cambiar el contenido de la fila con MAC de DL-03, que aún no está firmada. La comparación de horas da el mismo efecto sin tocar el formato.

### SEG-PR31-02 · Media · `TopeGraciaUtc` no refleja las gracias especiales: `Ilegible` puede reabrir 72 h

- **Riesgo.** Según el PR, L1a-4 guarda `TopeGraciaUtc` en la fila con MAC `Licencia.Gracias`, que es el único límite de la gracia `Ilegible` (NV-01, `[LIC]` 4.1.2). `AplicarEspeciales` cambia el estado y `GraciaHasta`, pero **no** toca `Tope`:
  - con una gracia especial vencida la empresa queda en `SoloConsulta` y `Tope` conserva el fin de la gracia por vencimiento (`MotorEstados.cs:323-324`). Esto contradice el contrato del propio tipo: «Null si la empresa no opera» (`EstadosLicencia.cs:95-96`);
  - durante una gracia especial `Tope` sigue siendo el fin por vencimiento, no el fin de la especial (`:325-326`).
- **Escenario [I].** En una instalación clonada (gracia `Entorno` vencida, `SoloConsulta`), la licencia sigue verificando y L1a-4 refresca cada 60 s la última verificación correcta y la fila `Gracias` con un tope no nulo. Si luego la licencia guardada deja de verificar (por ejemplo, alterada por quien controla el clon), `EvaluarIlegible` concede `EnGracia(Ilegible)` 72 h (`:336-341`). Esto ya contradice NV-01: la gracia especial mejora un estado que la última licencia verificada dejaba en `SoloConsulta`. Restaurar la licencia vuelve a refrescar la marca, así que el ciclo se puede repetir hasta el fin de la gracia por vencimiento. Lo mismo vale tras el retiro efectivo de una llave (NV-08): una licencia con `kid` retirado es «ilegible» según `[LIC]` 4.1.2. El motor solo lo impide si L1a-4 sigue pasando la gracia especial vencida en `Especiales` mientras la licencia está ilegible (`:342`). Con la licencia ilegible no hay huella vigente con la que comparar el entorno, así que esa dependencia es frágil.
- **Evidencia [V].** `MotorEstados.cs:306-328` (ninguna rama asigna `Tope`); `:365-366` (`Resultado` copia `c.Tope`); `EstadosLicencia.cs:95-96` (contrato). Ninguna prueba comprueba `TopeGraciaUtc` tras una gracia especial (`MotorEstadosTests.cs:415-470`, `:494-511`).
- **Remediación (unos 0,05 dp, en este PR).** En `AplicarEspeciales`:
  - rama `SoloConsulta`: `Tope = null`;
  - rama `EnGracia` por especial: `Tope = fin` (el mínimo ya calculado);
  - agregar pruebas de `TopeGraciaUtc` en los dos casos, y una de punta a punta: la fila construida con ese tope no da `Ilegible`.

  Así la defensa queda en el dato con MAC y no depende de que L1a-4 recuerde las gracias especiales.
- **Entrega a L1a-4:** guardar en `Gracias` exactamente `TopeGraciaUtc` (null incluido) y seguir pasando las gracias especiales abiertas, también con la licencia ilegible.

### SEG-PR31-03 · Baja · El motor no acota los parámetros firmados

- **Riesgo [V].**
  - `avisoDias` < 0: `InicioPorVencer` queda después de `vence` (`MotorEstados.cs:76`), y `EstadoPorFechas` devuelve `Vigente` mientras `ahora < porVencer` **sin compararlo con `finGracia`** (`:98-99`). Con `avisoDias` = −5 y `graciaDias` = 0, la empresa opera 5 días más allá de lo pagado. Es un fallo abierto.
  - `graciaDias` negativo se resuelve del lado restrictivo (`:85-86`, `:102-104`).
  - `graciaDias`, `avisoDias`, `vence` o `emitida` extremos (`DateOnly.MaxValue`, `DateTime.MaxValue`, `int.MaxValue`) producen `ArgumentOutOfRangeException` u `OverflowException` (`:64`, `:76-82`, `:86`, `:127`, `:244`, `:290`), igual que una hora `Local` (`:401-406`).
  - Una entrada duplicada da `NoLicenciada` (`:370-381`), pero `TransicionPorLicencia` la convierte después en una transición (`:283-292`). El fallo cerrado no se mantiene.
- **Por qué es Baja.** El contenido está firmado por GSF, y L1a-2 validará los rangos (`graciaDias` de 0 a 30, `avisoDias`, módulos ≤ empresa, techo de `emitida`). Hoy L1a-2 no existe en la base [V]. El motor es la última barrera ante un error del emisor.
- **Remediación (0,05 dp).**
  1. En `EstadoPorFechas`, `Vigente` solo si `ahora < mín(porVencer, finVigencia)`.
  2. Validar en `Evaluar` los rangos firmados y, si no se cumplen, devolver `NoLicenciada` en lugar de lanzar una excepción (o documentar que L1b trata toda excepción del motor como «no opera»).
  3. Con una entrada duplicada en la vigente, no abrir transición.

### SEG-PR31-04 · Baja · Instantes de referencia no acotados

- **Aceptación anterior a `emitida`.** `TransicionPorLicencia` evalúa la condición de apertura y `EmpresaEn` con `t = AceptadaUtc` (`MotorEstados.cs:273-283`). Si la hora protegida estaba atrasada al aceptar (`emitida` = NTP − 1 h, así que normalmente `t > emitida`), `finPrevio <= t` puede dar falso y abrir una transición cuya gracia previa ya había terminado según `emitida`. La ganancia está acotada a menos de `máx(graciaDias, 72 h)`.
  - **Remediación:** `t = máx(AceptadaUtc, Emitida)`, coherente con `HoraEvaluacion`.
- **Última verificación en el futuro.** `GraciaIlegible` cuenta 72 h desde `UltimaVerificacionUtc` sin compararla con la hora protegida (`:146-150`, `:338`). Si una marca supera la hora protegida (por ejemplo, tras recalcular la hora más alta), la gracia `Ilegible` supera las 72 h reales, aunque sigue limitada por el tope.
  - **Remediación:** usar `mín(UltimaVerificacionUtc, ahora)`, o tratar una marca futura como inválida (`SoloConsulta`).

### SEG-PR31-05 · Baja · Sin comprobación del orden entre `Anterior` y `Vigente`

- **Riesgo.** La regla «una transición por `sec`, sin encadenar» (NV-02) depende de que `Anterior` sea la aceptada justo antes de `Vigente`. El motor no lo comprueba (`MotorEstados.cs:177-195`). Si L1a-4 pasara una anterior más antigua (por ejemplo, tras descartar una intermedia que no verifica), se abriría una transición que la intermedia ya había agotado.
- **Remediación (0,02 dp).** Si `Anterior.Contenido.Sec >= Vigente.Contenido.Sec` o `Anterior.AceptadaUtc > Vigente.AceptadaUtc`, ignorar la anterior (sin transición). Documentar en `SituacionLicencia` que es la inmediatamente anterior por `sec`.

### SEG-PR31-06 · Baja · Comparación del RNC por dígitos que admite cualquier otro carácter

- **Riesgo.** `Digitos` descarta todo lo que no es un dígito ASCII (`MotorEstados.cs:386-394`). Un RNC configurado como `101123456` seguido de texto o de dígitos no ASCII (de ancho completo o arábigos) coincide con `101123456`. Con la configuración del ADMIN cerrada por DL-03 (409), solo se llega editando la base. Lo impreso seguiría conteniendo los dígitos ASCII del RNC licenciado. El efecto práctico es pequeño, pero la regla es más laxa de lo necesario.
- **SEG-L2-16 se cumple [V].** La transición exige `RncNuevo` igual al RNC de la empresa y `RncAnterior` igual al de la entrada (`:239`). Si la segunda escritura de S-03 falló, la empresa sigue con el RNC de la licencia y opera normal (prueba `MotorEstadosTests.cs:231-238`). Un RNC distinto del nuevo da `Invalida` (`:241-248`). Una fila falsa no pasa el MAC (fuera del motor). Una fila reutilizada: ver SEG-PR31-01.
- **Remediación (0,02 dp).** Normalizar solo guiones y espacios. Exigir que lo que queda tenga exactamente 9 u 11 dígitos ASCII; con cualquier otro carácter, no coincide (fallo cerrado).

### SEG-PR31-07 · Baja · La guarda de pureza es una lista negra de un solo nivel

- **Verificado.** Hoy el motor no lee el reloj ni hace E/S. Los únicos tipos externos son `DateTime`, `DateOnly`, `TimeOnly`, `TimeSpan`, `CultureInfo.InvariantCulture`, LINQ, los contratos y `HoraEmpresa.DesfaseUtc`, un campo `static readonly` (`HoraEmpresa.cs:16`). La prueba detecta lo prohibido directo (`MotorEstadosLicenciaPuroTests.cs:25-48`) y comprueba que el detector funciona (`:50-57`).
- **Límites.**
  - No sigue llamadas a otros tipos de GPOS: un ayudante nuevo que lea el reloj pasaría.
  - No prohíbe `TimeZoneInfo`, `DateTime.ToLocalTime`/`ToUniversalTime` ni `CultureInfo.CurrentCulture`, que dependen del entorno del equipo.
- **Remediación (0,03 dp).** Convertir la guarda en **lista blanca** de los tipos y ensamblados externos admitidos, o al menos agregar esos miembros y prohibir cualquier tipo de `GPOS.*` fuera de `GPOS.Contracts`, `GPOS.Core.Sistema.Licencia` y `HoraEmpresa.DesfaseUtc`.

## 5. Controles que están bien implementados

- **Reloj.** Evaluación = máx(hora protegida, `emitida`) (`MotorEstados.cs:43-47`). Atrasar el reloj no devuelve a `Vigente`, y una `emitida` futura solo endurece el estado. La alerta de 24 h no bloquea (`:51-52`). Las horas `Local` se rechazan (`:401-406`).
- **NV-02.**
  - La transición solo se abre con derecho en la anterior (incluida, RNC a la hora de aceptación, gracia sin vencer) y pérdida en la vigente (`:270-285`).
  - El ancla `mín(aceptación, emitida + 7 d)` impide alargarla retrasando la carga (prueba `:308`).
  - Dos licencias seguidas que omiten la empresa abren una sola transición (prueba `:328`).
  - La transición nunca acorta la gracia previa (`:184-186`).
- **Ida y vuelta del RNC dentro de una misma licencia.** El fin queda acotado por `máx(finGracia, emitida + 7 d + máx(graciaDias, 72 h))`, así que repetir el cambio no lo prolonga.
- **CW-02.** La marca `corte: "inmediato"` solo surte efecto con firma Avanzada propia, se compara de forma ordinal y sin firma se señala `CorteIgnorado` (`:271`, `:286-287`, `:383-384`, `:197`).
- **NV-01.**
  - Una empresa que no opera no mejora (`:308-310`).
  - El fin de cada gracia especial se limita al tope y rige la que termina antes (`:313-320`).
  - La marca más restrictiva es la más antigua (`:111-118`).
  - Solo se admiten `Entorno` y `LlaveRetirada` en la lista; `Ilegible` va por su propia vía (`:164-167`).
- **NV-08.**
  - El retiro efectivo es máx(publicación, conocimiento) + máx(72 h, `graciaDias` de la última no retirada), con 72 h si no hay ninguna (`:136-142`).
  - Nunca pasa del fin del `vence` (`:316-317`).
  - La gracia no sale del archivo firmado con la llave retirada.
- **Ilegible.** Sin fila, sin fin o con códigos duplicados (sin distinguir mayúsculas), el resultado es `SoloConsulta` (`:336-360`). La duración se limita al fin guardado (`:338`).
- **Código de empresa.** La comparación es `OrdinalIgnoreCase`, independiente de la cultura. Un duplicado falla cerrado en la entrada (`:370-381`), con la salvedad de SEG-PR31-03. Un código con espacios finales (que SQL Server iguala) da `NoLicenciada`, del lado restrictivo.
- **`CodigoBloqueo`.** Todo estado que no opera recibe un código `LICENCIA_*`, y el valor por omisión es `SoloConsulta` (`:204-215`).
- **No toca `CodigosLicencia.cs` ni adelanta DL-03** [V] (el `diff` solo agrega 4 archivos).

## 6. Remediaciones priorizadas

| # | Hallazgo | Acción | Esfuerzo | Cuándo |
|---|---|---|---|---|
| 1 | SEG-PR31-02 | `Tope` = null en `SoloConsulta` por especial y = fin de la especial en `EnGracia`; pruebas | 0,05 dp | En este PR (antes de que L1a-4 escriba `Gracias`) |
| 2 | SEG-PR31-01 | Fila válida solo si `AceptadaUtc ≤ CambiadoUtc` (o `Emitida < CambiadoUtc`); respetar el corte Avanzado en la vía del RNC; pruebas | 0,1 dp | Decisión del arquitecto (es una interpretación [I] del PR); código en este PR o antes de L1a-4 |
| 3 | SEG-PR31-03 | `Vigente` solo antes de `finVigencia`; rangos con fallo cerrado; duplicado sin transición | 0,05 dp | Antes de L1b |
| 4 | SEG-PR31-04 | `t = máx(AceptadaUtc, Emitida)`; última verificación ≤ ahora | 0,02 dp | Antes de L1a-4 |
| 5 | SEG-PR31-05 | Ignorar una `Anterior` fuera de orden | 0,02 dp | Antes de L1a-4 |
| 6 | SEG-PR31-06 | RNC canónico de 9 u 11 dígitos | 0,02 dp | Con RN (DL-03) |
| 7 | SEG-PR31-07 | Lista blanca en la guarda de pureza | 0,03 dp | Cuando convenga |

Total: unos 0,3 dp, de los que 0,15 dp corresponden a los dos Medios.

## 7. Recomendación

**Aprobado con observaciones** (recomendación técnica; la decisión de unir es del propietario). No hay hallazgos Críticos ni Altos. Los dos Medios no se pueden explotar mientras ningún código de producción use el motor, pero conviene cerrarlos antes de que L1a-4 persista `TopeGraciaUtc` (SEG-PR31-02) y antes de que el arquitecto confirme la interpretación de NV-07 (SEG-PR31-01). Si el arquitecto mantiene la lectura actual de SEG-PR31-01, el propietario debe aceptarla por escrito como residual, porque se aparta del texto «hasta la licencia nueva» de `[LIC]` 2 y de «una transición por `sec`» de `[LIC]` 4.1.1.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\revision-seguridad-pr31-motor-estados-2026-10-14.md`
- Supuestos: L1a-4 guardará `TopeGraciaUtc` como fin por empresa en `Licencia.Gracias` (lo dice el PR); L1a-2 validará los rangos firmados; una licencia que verifica en un clon cuenta como «verificación correcta» (inferido); no se compiló ni se ejecutaron pruebas (instrucción del encargo)
- Decisiones candidatas a ADR: precisión de NV-07: la fila `CambiosRnc` solo vale contra la licencia aceptada antes del cambio (alternativa descartada: atarla a la `sec`, que cambia el formato de DL-03)
- Entregas a otros agentes: arquitecto-maestro → decidir la lectura de SEG-PR31-01; desarrollador de L1a-4 → guardar `TopeGraciaUtc` tal cual (null incluido), pasar las gracias especiales también con la licencia ilegible y pasar como `Anterior` solo la inmediatamente anterior por `sec`; desarrollador de L1b → tratar toda excepción del motor como «no opera»; qa-automatizado → pruebas de SEG-PR31-01 a -04
- Próximo paso recomendado: aplicar SEG-PR31-02 en el PR #31 y llevar SEG-PR31-01 al arquitecto antes de unir
