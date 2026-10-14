# Hoja de firma DL-01 a DL-13: licencia firmada en el lote 2 de RG-14

**Fecha:** 2026-10-14 · **Preparada por:** Arquitecto Maestro (equipo A) · **Decide y firma:** el propietario (Leonardo Méndez)
**Estado: Pendiente de firma.** Esta hoja no firma nada. Cada casilla la marca el propietario.

**Fuentes (leídas hoy, solo lectura)**
- `[BP]` = `Solucion GPOS NG\blueprint-licencia-lote2-2026-10-14.md` (arquitecto-software), sobre todo la sección 13 y las que cita (2, 4, 9, 10, 11).
- `[DAT]` = `Solucion GPOS NG\datos-t3-12-rg14-2026-10-14.md` v2 (arquitecto de datos): D-01 a D-11 y L-01 firmadas el 2026-10-14; D-04 (ii) **sin firma**.
- `[HOJA]` = `GPOS NG\docs\decisiones\2026-10-05-hoja-firma-seguridad.md` (textos literales de FY-15, CP-4, CP-5 y R-L11 / R-F11, líneas 131 y 243-247).
- ADR-38, 44, 58 a 63, 68 y 81 en `GPOS NG\docs\adr`; ADR-126 en `master` (leído con `git show` desde `GPOS-NG-lic`).
- **Informe del auditor-seguridad sobre 10.5 y 10.6 de `[BP]`** (`revision-seguridad-blueprint-licencia-lote2-2026-10-14.md`): **no existía al cerrar esta hoja.** DL-10 a DL-13 llevan el marcador «pendiente del dictamen de seguridad».

**Convención.** *[V]* verificado en la fuente; *[I]* inferido por mí. **dp** = días-persona. Costo de referencia: USD 300 a 400 por dp (USD 1 500 a 2 000 por semana-persona).

**Palabras que se repiten**
- **`s1`**: la llave con la que GSF firma hoy las licencias (nivel Básico). Vive en el chip TPM de un equipo y no se puede copiar, pero quien controle ese equipo la puede **usar**.
- **YubiKeys**: llaves físicas (nivel Avanzado). Todavía no se han comprado.
- **Sello de habilitación**: una marca cifrada que la API pone en cada cuenta habilitada. Sin sello válido, la cuenta no entra ni ocupa cupo. Impide ampliar la licencia insertando usuarios por SQL.
- **Padrón de sellos**: la lista protegida de los sellos vigentes.
- **Estricto / Amplio**: Estricto es el modo de producción, con identidades de mínimo privilegio. Amplio es el de desarrollo, pruebas y DEMO.

---

## 1. Ya firmado hoy (2026-10-14): no se vuelve a preguntar

| # | Decisión del propietario | Qué sustituye o amplía | Dónde queda registrada |
|---|---|---|---|
| **F-1** | **Dos desarrolladores en paralelo** (identidades y licencia), **sin mover el corte de mediados de diciembre** | R-RG14-10 de `[DAT]` (un solo desarrollador no alcanza) | Borrador de ADR-82 (consecuencias) y DL-07 / DL-08 de esta hoja |
| **F-2** | **Las licencias de pago se pueden firmar en nivel Básico** (`s1` en el TPM) hasta que existan las YubiKeys. **Riesgo Medio-Alto aceptado como temporal.** | Precisa ADR-62 y AP-05: sustituye «la primera licencia de pago se firma en Avanzado» (ADR-62, consecuencias). **Amplía P-F1 / FY-15**, cuyo texto literal hablaba de un equipo dedicado y de la caducidad del 2026-12-31 | Borrador de ADR-84, puntos 1 y 2. Texto para el registro en la sección 3.4 |
| **F-3** | **Equipo emisor: el equipo principal del propietario, con una cuenta de Windows dedicada solo a firmar.** Sin mini-PC. **Ceremonia de las YubiKeys preparada y sin fecha** | Precisa ADR-61 y Q-19 (de la opción (a), mini-PC, a una variante de la (b)). AP-01 y AP-05 quedan sin fecha | Borrador de ADR-84, puntos 3 y 6 |

**Efecto de F-2 y F-3 sobre lo que exigía la primera licencia de pago.** La barrera de `[DAT]` 6.5 («AP-01 a AP-06») queda así: **ya no exige AP-01 ni AP-05**. Exige el código del lote 2 en verde (PA-12, QA-L01 a L17), AI-08, AI-09, **AP-03 y AP-04 adaptados** y AP-06 (`[BP]` 10.3) [V].

---

## 2. Resumen de las decisiones que piden firma

| # | En una línea | Recomendación | Costo | Firmar antes de |
|---|---|---|---|---|
| DL-01 | Padrón de sellos protegido, contra la repetición de un sello viejo | **Aprobar** | 1,0 dp | 2026-11-06 |
| DL-02 | En producción, la API no crea cuentas al arrancar | **Aprobar** | 0,5 dp | 2026-11-06 |
| DL-03 | El RNC de la empresa solo lo cambia el SUPER | **Aprobar** | 0,75 dp + pantalla | 2026-11-13 |
| DL-04 | Los eventos de la licencia y del sello van a `BitacoraSeguridad` | **Aprobar** | 0,5 dp | 2026-10-30 |
| DL-05 | El sello cubre también la contraseña guardada | **Aprobar** (opcional) | +0,5 dp | 2026-11-06 |
| DL-07 | Reparto del trabajo entre los dos desarrolladores | **Aprobar** | 0 | **2026-10-16** |
| DL-08 | Calendario: la licencia queda construida para el corte | **Aprobar** (registro) | 0 | 2026-10-16 |
| DL-09 | Recorte de la autorización de regreso, si hay atraso | **Autorizar con disparador** | −1,75 dp si se usa | 2026-11-13 |
| DL-10 | Segunda llave Básica de reserva en otro equipo | **Aprobar** · *pendiente del dictamen de seguridad* | 0,5 dp | 2026-11-20 |
| DL-11 | La caducidad de `s1` la fija la versión con YubiKeys | **Aprobar** · *pendiente del dictamen de seguridad* | Incluido | 2026-12-01 |
| DL-12 | Punto de revisión para comprar las YubiKeys | **Punto de revisión sin fecha fija** · *pendiente del dictamen de seguridad* | USD 352 (ya presupuestados) | Sin urgencia |
| DL-13 | Cuenta diaria sin permisos de administrador en el equipo emisor | **Aprobar** · *pendiente del dictamen de seguridad* | 0 | Antes de generar `s1` (AI-09) |

*DL-06 está retirada: la sustituye F-2.*

**Recomendación de conjunto: Aprobar con observaciones** (sección 5). Las observaciones no cambian ninguna recomendación. Dos de ellas conviene mirarlas antes de firmar: O-2, sobre DL-09, y O-3, una mejora barata para R-B11.

---

## 3. Las decisiones, una por una

### DL-01 · Padrón de sellos contra la repetición

**Qué se decide.** Hoy el diseño del sello tiene un hueco (`[BP]` 2.2, SH-1, severidad **Alta**). Con acceso a SQL se puede copiar el sello de la cuenta A, inhabilitar A (libera el cupo), dar de alta B y volver a pegar el sello viejo de A. Resultado: A y B habilitadas, y el cupo duplicado, tantas veces como se quiera. La corrección es guardar, protegida, la lista de los sellos vigentes (el padrón). Una cuenta solo entra y cuenta si su sello verifica **y** figura en el padrón.

**Recomendación: Aprobar.** Sin el padrón, el sello no cumple el propósito firmado («insertar filas a mano no amplía la licencia»).

| Opción | Consecuencia |
|---|---|
| **(a) Padrón protegido (recomendada)** | Cierra SH-1. Si alguien devuelve el padrón entero a un estado anterior, el sistema queda en una situación que fue legítima en su momento, y se avisa al SUPER (`PadronRetrocedido`). Unos 70 KB con 1 000 cuentas [I]; solo se escribe al administrar usuarios, nunca al vender |
| (b) En exceso de cupo, dejar entrar solo a las N cuentas más antiguas | Contradice ADR-58, punto 9 («nadie pierde la sesión») y permite turnar cuentas |
| (c) Guardar las revocaciones en la bitácora | Un `sysadmin` borra filas de la bitácora: no protege |

**Costo:** 1,0 dp (dentro de SL). Precisa ADR-58, punto 9, y `[DAT]` 6.3. Va en ADR-83.

`[ ] Aprobar (a)`   `[ ] Otra: ____`   `[ ] Aplazar`

---

### DL-02 · En producción, la API no crea cuentas al arrancar

**Qué se decide.** Hoy, si no hay ningún SUPER, la API crea uno al arrancar (`UsuariosService.cs:266-287`, `:421-433` [V en `[BP]`]). Con SQL basta borrar los SUPER y reiniciar para **fabricar un SUPER**, que además la API sellaría (SH-3, **Alta**). En modo Estricto, las cuentas iniciales las crearía solo `GPOS.Migracion sistema --cuentas-iniciales`, ejecutado por el técnico de GSF, la primera vez. En Amplio (desarrollo, pruebas y DEMO) todo sigue igual.

**Recomendación: Aprobar.**

| Opción | Consecuencia |
|---|---|
| **(a) Solo `GPOS.Migracion` crea las cuentas iniciales en Estricto (recomendada)** | Cierra SH-3. Si un cliente se queda sin SUPER, la recuperación exige al técnico en el servidor. Es raro: ADR-81 ya exige que GSF mantenga al menos dos SUPER por instalación |
| (b) Mantener la creación automática | Deja abierta la vía para fabricar un SUPER por SQL |

**Costo:** 0,5 dp. Precisa SEC-07 (claves iniciales solo interactivas) y SES-16 del estándar de acceso. Va en ADR-83.

`[ ] Aprobar (a)`   `[ ] Otra: ____`   `[ ] Aplazar`

---

### DL-03 · El RNC de la empresa solo lo cambia el SUPER

**Qué se decide.** La licencia está atada al RNC de cada empresa. La regla firmada NV-07 (ADR-59) solo da un período de transición cuando el cambio de RNC lo hizo el SUPER, y hoy **el ADMIN también edita el RNC** (`AdministracionService.cs:64`, `:109` [V en `[BP]`]). Se propone que el cambio pase a una ruta solo del SUPER, con motivo y segundo factor, que deje una prueba protegida. Si el ADMIN intenta cambiarlo, recibe el aviso «solo el SUPER puede cambiar el RNC» (409 `RNC_SOLO_SUPER`).

**Recomendación: Aprobar.** Cambiar el RNC exige de todos modos una licencia nueva de GSF (precisión de ADR-59 del 2026-10-08: 30 días como máximo). Que lo haga GSF no agrega un paso real.

| Opción | Consecuencia |
|---|---|
| **(a) Solo el SUPER, con motivo y segundo factor (recomendada)** | **Cambia lo que ve el ADMIN:** el campo RNC queda de solo lectura para él. Corregir un error de captura requiere a GSF |
| (b) El ADMIN sigue editándolo | Por la regla firmada, la empresa queda `Invalida` **sin gracia** en cuanto cambia el RNC: una trampa para el cliente |
| (c) El ADMIN lo edita solo mientras la empresa nunca tuvo licencia | Más casos que probar. Con la regla (iii) firmada (GSF hace la implantación), no aporta [I] |

**Costo:** 0,75 dp más un ajuste en la pantalla de configuración (frontend). Es una precisión de ADR-59 (NV-07), no un ADR nuevo.

`[ ] Aprobar (a)`   `[ ] Otra: ____`   `[ ] Aplazar`

---

### DL-04 · Bitácora de la licencia y del sello

**Qué se decide.** Los ADR firmados mandan los eventos de la licencia a `BitacoraSistema` (ADR-37 y ADR-60, punto 8), pero **esa bitácora no existe en el código**. Tampoco `BitacoraSeguridad` de ADR-81 (`[BP]` C-05 [V]). Se propone usar `BitacoraSeguridad` (en `GPOS_SYSDATA`, solo inserción y retención de 2 años, ya firmada con ADR-81) hasta que exista `BitacoraSistema`. En ese momento se decide si se unen.

**Recomendación: Aprobar, con una precisión mía:** la tabla la diseña **una sola vez** el arquitecto de datos y la crea `GPOS.Migracion sistema` (ADR-38, M-4). Ni el desarrollador de la licencia ni el de ADR-81 la crean por su cuenta. `[BP]` decía «la crea quien llegue primero», y eso arriesga dos versiones de la misma tabla.

| Opción | Consecuencia |
|---|---|
| **(a) `BitacoraSeguridad` con una sola DDL del arquitecto de datos (recomendada)** | Una sola bitácora de seguridad, con retención ya firmada. Hay que unirla con `BitacoraSistema` cuando llegue |
| (b) Construir ahora `BitacoraSistema` | Adelanta trabajo de la versión 1 del acceso multiempresa sin dueño ni calendario |
| (c) Solo el Visor de eventos de Windows | No viaja con los respaldos, y quien administra el servidor lo borra |

**Costo:** 0,5 dp. Es una precisión de ADR-81 (punto 12) y de ADR-60 (punto 8), no un ADR nuevo.

`[ ] Aprobar (a) con la precisión`   `[ ] Otra: ____`   `[ ] Aplazar`

---

### DL-05 · El sello cubre también la contraseña guardada (opcional)

**Qué se decide.** Hoy, un `sysadmin` puede reemplazar el hash de la contraseña de una cuenta sellada (incluso la de un SUPER o un ADMIN) por uno que conozca y entrar con ella. No amplía el cupo, pero es tomar una cuenta (SH-5, Media). Incluir en el sello la huella del hash lo impide. A cambio, hay que volver a sellar en cada cambio o restablecimiento de contraseña.

**Recomendación: Aprobar.** `[BP]` la condiciona a que el SUPER no tenga el segundo factor antes del corte. Yo la recomiendo igual, por tres motivos:
- el segundo factor obligatorio (ADR-81) cubre **solo al SUPER**, y el ADMIN queda expuesto;
- cuesta 0,5 dp y cabe en la holgura del desarrollador de identidades (pasa de 23,0 a 23,5 dp de 34,4 disponibles);
- no depende de que la fase A de ADR-81 llegue a tiempo.

| Opción | Consecuencia |
|---|---|
| **(a) Sí, con la huella del hash de la contraseña (recomendada)** | Cierra SH-5 para todas las cuentas. Cada cambio de contraseña también actualiza el padrón (raro, y sin efecto en la venta) |
| (b) No | Riesgo residual Bajo para el SUPER cuando exista ADR-81; Medio para el ADMIN |
| (c) Incluir el «sello de seguridad» aleatorio (SH-8) en lugar del hash | **No cierra SH-5** [I]: quien cambia el hash por SQL deja intacto ese valor, así que el sello seguiría verificando |

**Costo:** +0,5 dp. Va en ADR-83.

`[ ] Aprobar (a)`   `[ ] Otra: ____`   `[ ] No`

---

### DL-07 · Reparto entre los dos desarrolladores

**Qué se decide.** Tú firmaste dos desarrolladores (F-1). Falta cómo repartir el trabajo. Si el desarrollador «dedicado a la licencia» lo hace todo, incluido el programa emisor, la carga es de unos 37 dp frente a 34,4 de capacidad: **no cabe** (`[BP]` 11.4 [V, comprobé la suma]). El reparto propuesto pasa al desarrollador de identidades el sello (SL), el anillo H-17 v2 (CR), el cambio de RNC (RN) y el emisor (EM).

**Recomendación: Aprobar**, con una condición: **que el desarrollador de identidades no tenga otras tareas hasta el corte.** Si además lleva el segundo PR de H-11 u otra pieza, el reparto se rehace (supuesto 1 de `[BP]`).

| Opción | Licencia (L) | Identidades (I) | ¿Cabe? |
|---|---|---|---|
| **(a) Reparto propuesto (recomendada)** | ≈ 23,4 dp | ≈ 23,0 dp (23,5 con DL-05) | Sí: 68 % y 67 % de la capacidad; con +35 %, unos 3 dp de margen cada uno |
| (b) Reparto literal: L hace toda la licencia | ≈ 37 dp | ≈ 6 dp | **No** en el escenario central; I queda con unos 28 dp sin carga |

**Costo:** 0 (es reparto). Cada desarrollador trabaja en su propia copia y su rama (regla de un solo editor por árbol).

`[ ] Aprobar (a)`   `[ ] Otra: ____`

---

### DL-08 · Calendario: la licencia queda construida para el corte

**Qué se decide.** Registrar que el código de la licencia se completa para el corte del 2026-12-15. Sustituye las fechas firmadas en Q-24 y Q-25 (inicio el 2026-11-02 y publicación la primera semana de enero de 2027). Con F-2, la primera licencia de pago depende de las condiciones de la sección 1, no del hardware.

**Recomendación: Aprobar.** Es la consecuencia directa de F-1. El orquestador la registra (G-1.6).

| Opción | Consecuencia |
|---|---|
| **(a) Registrar (recomendada)** | Plan semanal de `[BP]` 11.3 con cuatro hitos: H-1 el 10-23, H-2 el 11-06, H-3 el 11-13 y código completo el 12-04 |
| (b) Mantener Q-24 y Q-25 | Contradice F-1 («sin mover el corte», con la licencia dentro del lote 2) |

**Riesgo real del calendario, fuera de los dos desarrolladores** (`[BP]` 11.4): la toma nueva de la ola 3 unida antes del 2026-11-16; AI-07; QA y frontend desde el 2026-11-23; certificados de H-17 v2 antes del 2026-11-02.

`[ ] Aprobar (a)`   `[ ] Otra: ____`

---

### DL-09 · Recorte de la autorización de regreso a Básico, si hay atraso (condicional)

**Qué se decide.** Si el calendario se atrasa, el recorte número 4 de `[BP]` 11.4 deja fuera de esta versión la «autorización de regreso temporal a Básico» (`autNivel`) y ahorra 1,75 dp. Esa autorización solo sirve cuando ya existen las YubiKeys, y con F-2 y F-3 no existen. Es segura de agregar después: un programa que no la entiende rechaza el archivo.

**Recomendación: autorizarla ya, pero solo con un disparador objetivo.** Así no hay que esperar una firma en medio de la urgencia. El disparador: **el orquestador confirma que L1b va con 5 días hábiles o más de atraso respecto de H-3 (2026-11-13)**. Ver la observación O-2: aplicarla también precisa ADR-62 (Q-17).

| Opción | Consecuencia |
|---|---|
| **(a) Autorizada con el disparador (recomendada)** | Sin demoras de firma si llega el atraso. Al usarla, se registra como precisión de ADR-62 (Q-17) y de Q-24 |
| (b) No firmar ahora; decidir si llega el atraso | Una firma más en el momento de mayor presión |
| (c) No recortar nunca | Si hay atraso, se sacrifica otra cosa o el corte |

`[ ] Aprobar (a)`   `[ ] (b)`   `[ ] (c)`

---

### DL-10 · Llave Básica de reserva en otro equipo

> **Pendiente del dictamen de seguridad.** El auditor-seguridad está revisando 10.5 y 10.6 de `[BP]`. Si su informe pone condiciones, se agregan aquí antes de firmar.

**Qué se decide.** Con F-2, toda la firma de pago depende de una sola llave (`s1`) en un solo equipo. Si ese TPM se borra, se reinstala Windows o el equipo falla, GSF no puede renovar a nadie hasta publicar una versión con una llave nueva **y** que cada cliente la instale. Mientras tanto, los clientes pasan a la gracia y luego a solo consulta (R-B12, Media / Alto). La propuesta es una segunda llave Básica (`gsf-lic-s1r`) en el TPM de **otro** equipo, con su propia cuenta dedicada y su acta, incluida en los programas desde el corte.

**Recomendación: Aprobar**, con dos precisiones mías:
- el segundo equipo se enciende solo para firmar o para el ensayo, porque cada equipo con una llave es otro lugar desde el que se podría falsificar (R-B11);
- conviene que lo custodie el suplente (AP-02), si se designa.

| Opción | Consecuencia |
|---|---|
| **(a) `s1r` en otro equipo con TPM (recomendada)** | Perder el equipo principal ya no corta las renovaciones. Hay dos lugares que proteger en lugar de uno. Necesita un segundo equipo con TPM 2.0 (supuesto 8 de `[BP]`, sin verificar) |
| (b) Sin reserva; solo el procedimiento de emergencia (publicar una versión con una llave nueva) | Depende de que cada cliente instale la versión nueva antes de que se le acabe la gracia (unos 10 días por omisión). Riesgo Medio / Alto |
| (c) Reserva en el mismo equipo | No protege contra la pérdida del equipo, que es el caso principal |

**Costo:** 0,25 dp de desarrollo y 0,25 de devops. Sin equipo nuevo si ya existe uno con TPM [I].
**Plazo:** la llave pública tiene que entrar en los programas del corte. Hay que generarla con acta antes del 2026-11-27 (código completo el 12-04).

`[ ] Aprobar (a) con las precisiones`   `[ ] (b)`   `[ ] Otra: ____`

---

### DL-11 · Cuándo deja de valer `s1`

> **Pendiente del dictamen de seguridad.**

**Qué se decide.** La regla firmada fijaba que `s1` dejaría de aceptarse para archivos nuevos el **2026-12-31** (Q-16). Esa fecha solo rige cuando los programas ya traen una llave Avanzada (INV-1). Con F-2 y F-3, esa llave no existe, así que la fecha **no tiene efecto**. Además, si se dejara fija y las YubiKeys llegaran en 2027, la versión con YubiKeys rechazaría desde el primer día todo archivo firmado solo con `s1`, incluidas las reemisiones de transición. La propuesta: la fecha de fin de `s1` (y de `s1r`) **la fija la versión que incorpora las YubiKeys**, en su publicación más 45 días (un ciclo mensual, la gracia y margen).

**Recomendación: Aprobar.** Mi precisión: la fecha queda **escrita en el programa** en el PR de las llaves, calculada sobre la fecha prevista de publicación. Si la publicación se retrasa más de 7 días, se corrige antes de publicar, y QA lo comprueba.

| Opción | Consecuencia |
|---|---|
| **(a) Publicación de la versión con YubiKeys + 45 días (recomendada)** | Deja 45 días para reemitir en Avanzado a todos los clientes de pago: unos 5 a 10 minutos de firma por cada 50 clientes [I, `[BP]` 10.3] |
| (b) Fecha de compilación + 90 días (Q-16, escenario B, sin cambios) | Más ventana de exposición de `s1` sin necesidad |
| (c) Mantener el 2026-12-31 | Sin efecto hoy, y rompe la transición si las YubiKeys llegan después de esa fecha |

**Límite que no resuelve ninguna opción:** un cliente que **no instala** versiones nuevas sigue aceptando `s1` hasta el `vence` de su licencia (R-B11, NV-08). Ver la observación O-3.
**Costo:** dentro de los 0,5 dp de 10.3. Precisa Q-16 e INV-1 (ADR-62, punto 3). Va en ADR-84.

`[ ] Aprobar (a) con la precisión`   `[ ] (b)`   `[ ] Otra: ____`

---

### DL-12 · Punto de revisión para comprar las YubiKeys

> **Pendiente del dictamen de seguridad.**

**Qué se decide.** Firmaste que la ceremonia queda **preparada y sin fecha** (F-3), y eso no se reabre. `[BP]` pide además una «fecha objetivo» de compra (R-B14: sin fecha, el nivel Básico de pago puede durar indefinidamente). Lo único que queda por decidir es si se fija un **punto de revisión** que no obligue a nada.

**Recomendación: un punto de revisión sin fecha fija:** «revisar la compra cuando se firme el contrato del **primer cliente de pago**, o en la sesión de cierre del corte (2026-12-15), lo que llegue antes». La compra (unos USD 352, ya presupuestados) no obliga a fijar la ceremonia. Comprarlas antes permite verificar el certificado CMVP y ensayar con el hardware real. El envío a República Dominicana puede tardar de 1 a 3 semanas [I].

| Opción | Consecuencia |
|---|---|
| (a) Nada más: queda como está firmado | El tablero del emisor muestra los clientes de pago en Básico; nadie revisa la decisión de forma periódica |
| **(b) Punto de revisión sin fecha fija (recomendada)** | Una decisión consciente cuando el riesgo deja de ser teórico (primer pago) |
| (c) Fecha objetivo de compra | Más disciplina, pero choca con el espíritu de F-3 |

`[ ] (a)`   `[ ] Aprobar (b)`   `[ ] (c), fecha: ____`

---

### DL-13 · Cuenta diaria sin permisos de administrador en el equipo emisor

> **Pendiente del dictamen de seguridad.**

**Qué se decide.** Con F-3, `s1` vive en tu equipo principal, que navega y recibe correo. Si la cuenta que usas a diario es administradora, un programa malicioso en ella puede usar la llave (no copiarla) o engañar a la pantalla del emisor para que firme otra cosa (R-B13). La condición 6 de `[BP]` 10.6 propone que la cuenta diaria pase a **estándar** y que una cuenta administradora aparte se use solo para el mantenimiento.

**Recomendación: Aprobar.** Es la medida que más baja el riesgo y no cuesta dinero: según `[BP]` 10.6, el riesgo pasa de **Medio-Alto** (el que aceptaste como temporal) a **Medio**.

| Opción | Consecuencia |
|---|---|
| **(a) Cuenta diaria estándar y cuenta administradora aparte (recomendada)** | Instalar programas pedirá la contraseña de la cuenta administradora. Es una molestia ocasional. Riesgo: Medio |
| (b) Mantener la cuenta diaria administradora | Queda el Medio-Alto aceptado en F-2 |
| (c) Mini-PC dedicado | **Descartado por ti** (F-3). Solo se menciona porque sigue siendo la mejora más barata si el auditor no acepta el riesgo |

**Costo:** 0 en dinero; unas 2 horas de devops contigo para la configuración [I].
**Plazo:** antes de generar `s1` (AI-09), para que quede en el acta.

`[ ] Aprobar (a)`   `[ ] (b)`

---

## 4. Pendientes que no son DL: lo que se necesita del propietario

### 4.1 CI-7 / AI-07 · Validación legal de las tres excepciones (antes del 2026-11-16)

**Qué es.** Con la licencia vencida (solo consulta), tres operaciones siguen permitidas por ley ([LIC] LV-12):
1. rectificar o suprimir datos personales a pedido del titular (Ley 172-13);
2. anular o comunicar secuencias y rangos de NCF y e-CF no usados (incluido el ANECF);
3. restablecer contraseñas y desbloquear cuentas.

El especialista-pos y el asesor legal deben confirmar la lista.

**Qué se necesita del propietario:** encargar la consulta al asesor legal **esta semana**. Quedan 33 días y la respuesta hace falta antes de clasificar las rutas (2026-11-16).
**Si no llega a tiempo** (R-B2): las tres operaciones quedan bloqueadas en solo consulta, lo que falla del lado restrictivo, y se habilitan cuando llegue la validación. No se viola ninguna regla firmada, pero un cliente vencido no podría, por ejemplo, atender una solicitud de la Ley 172-13 hasta entonces.

### 4.2 AP-02 · Custodio suplente

**Qué cambia con F-2.** Mientras no haya YubiKeys, el suplente deja de ser condición de la primera licencia de pago (`[BP]` 10.3). **Excepción:** si se firma DL-10, conviene designarlo ya para custodiar `s1r`.
**Qué se necesita del propietario:** decidir si se designa ahora (recomendado con DL-10). El nombre va en el acta, no en los documentos.

### 4.3 AP-03 · Procedimientos escritos y ensayados, adaptados al nivel Básico

**Antes de la primera licencia de pago.** Devops los redacta contigo. Los procedimientos son:
1. **compromiso de `s1`** (o de `s1r`): reemitir, publicar una versión que retire la llave y avisar a los clientes;
2. **pérdida de `s1` o del equipo**: pasar a `s1r` si existe; si no, emisión de emergencia por una versión nueva;
3. **ausencia del titular**;
4. con DL-10, **el uso de `s1r`**.

Se ensayan una vez con la llave de desarrollo, nunca con la real.
**Qué se necesita del propietario:** unas 2 horas para revisar y un ensayo con devops [I].

### 4.4 AP-04 · Aceptaciones escritas, con los textos adaptados

**Antes de la primera licencia de pago.**
- **CP-4** (modificación de los binarios) y **CP-5** (clonación deliberada): **sin cambios**, con el texto literal de `[HOJA]` 245-246.
- **R-L11 / R-F11:** el texto firmado habla de «las dos YubiKeys». En Básico, el riesgo es perder `s1`. Propongo este texto adaptado, que **sustituye a R-L11 mientras se firme en Básico**. El texto original vuelve a regir cuando existan las YubiKeys. Elige una variante según lo que se firme en DL-10.

  > **R-L11-B (con DL-10 firmada).** *«Acepto por escrito que, mientras GSF firme las licencias en Seguridad Básica, si se pierden a la vez la llave `gsf-lic-s1` del equipo principal y la llave de reserva `gsf-lic-s1r` del segundo equipo (por falla o borrado del TPM, reinstalación de Windows o pérdida de los equipos), GSF no podrá emitir ni renovar licencias hasta publicar una versión de GPOS NG con una llave nueva y que cada cliente la instale; y que, si eso tarda más que la gracia de cada cliente, esos clientes pasarán a solo consulta. Se mitiga con las dos llaves en equipos y lugares distintos, el procedimiento de emergencia ensayado y las vigencias mensuales. Riesgo residual: Bajo.»*
  >
  > **R-L11-B (sin DL-10).** *«Acepto por escrito que, mientras GSF firme las licencias en Seguridad Básica, si se pierde la llave `gsf-lic-s1` (por falla o borrado del TPM, reinstalación de Windows o pérdida del equipo principal), GSF no podrá emitir ni renovar licencias hasta publicar una versión de GPOS NG con una llave nueva y que cada cliente la instale; y que, si eso tarda más que la gracia de cada cliente, esos clientes pasarán a solo consulta. Se mitiga con el procedimiento de emergencia ensayado y las vigencias mensuales. Riesgo residual: Medio.»*

  La parte de R-F11 sobre las YubiKeys del manifiesto no cambia: rige cuando existan, y el agente llega después del corte.

**Texto para el registro de F-2 (no es una decisión nueva).** La ampliación de P-F1 / FY-15 ya está firmada. Para registrarla hace falta un texto literal, porque el de FY-15 ya no describe la realidad: menciona un equipo dedicado y la caducidad del 2026-12-31. Propongo este; confirma que refleja lo que firmaste:

> **FY-15-B.** *«Amplío mi aceptación de P-F1 (FY-15): mientras no existan las YubiKeys, GSF firmará también las licencias de pago en Seguridad Básica, con la llave `gsf-lic-s1` en el TPM de mi equipo principal, en una cuenta de Windows dedicada solo a firmar, y sin fecha de fin. Acepto que un programa malicioso en ese equipo podría usar la llave (no copiarla) para firmar licencias de pago para cualquier instalación, o mostrar un resumen y firmar otro contenido; que una licencia así no se puede retirar en un cliente que no instale las versiones nuevas; que no hay corte inmediato para los clientes en Básico; y que la caducidad técnica del 2026-12-31 no rige hasta que haya llaves Avanzadas en los programas. Se mitiga con la cuenta dedicada, el PIN de la llave, la confirmación de cada firma, el registro encadenado con ancla por correo y las vigencias mensuales. Riesgo residual: Medio-Alto, temporal, hasta la reemisión en Avanzado (AP-05).»*
>
> Si se firma DL-13, la última frase dice «Medio», sujeto al dictamen de seguridad.

`[ ] Confirmo FY-15-B`   `[ ] Corregir: ____`
`[ ] Acepto R-L11-B (variante: con DL-10 / sin DL-10)`   `[ ] Acepto CP-4`   `[ ] Acepto CP-5`

### 4.5 AP-06 · Contrato de suscripción revisado por el asesor legal (antes del primer cliente)

**Qué debe cubrir** (según lo firmado):
- la cláusula del último período;
- la regla (iii) de D-04: GSF administra la instancia y el TI del cliente no es `sysadmin`;
- que alterar la instalación (binarios, base, sellos) es un incumplimiento (CP-4 y CP-5).

**Agrego dos puntos que salen de F-2:**
- el contrato **no** debe presentar la firma de las licencias como «hardware validado» ni FIPS mientras se firme en Básico (Q-21);
- debe prever la reemisión de la licencia al pasar a Avanzado.

**Qué se necesita del propietario:** encargarlo junto con AI-07 (el mismo asesor) para ahorrar una ronda.

### 4.6 Otros pendientes del propietario (acciones, no decisiones)

| Qué | Cuándo |
|---|---|
| **AI-09:** generar `s1` en el TPM de la cuenta dedicada, con devops y con acta (condiciones de `[BP]` 10.6) | Se puede hacer ya; después de decidir DL-13 |
| Custodia del certificado del servidor y del de recuperación de H-17 v2 (Q-22) | Antes del 2026-11-02 |
| Activar `contained database authentication` en la PC A para la suite `Rg14` | Antes de PA-12 |
| Precisión de ADR-58: licencia por empresa contando usuarios, y cláusula de módulos | La prepara el Maestro (sin fecha) |
| **Quién registra ADR-82 en `master`** (pregunta que el coordinador B ya te pasó) | Antes de unir el lote 1 |

---

## 5. Observaciones del Maestro (contradicciones y huecos encontrados al consolidar)

| # | Observación | Evidencia | Severidad | Cómo queda |
|---|---|---|---|---|
| **O-1** | `[BP]` 0.10 y 10.3 dicen que el riesgo Medio «ya está aceptado» (P-F1, FY-15). Pero el texto literal de FY-15 se apoya en un **equipo dedicado** y en la **caducidad del 2026-12-31**, y ninguna de las dos se cumple con F-2 y F-3 | `[HOJA]`:131; ADR-62, consecuencias | Media (registro) | Lo cubre tu firma de hoy (Medio-Alto temporal). Falta el texto literal FY-15-B (4.4) |
| **O-2** | **DL-09 choca con una precisión firmada de ADR-62:** la de Q-17 dice que la autorización de regreso trae el campo `instalaciones` «desde L1» y que «el campo no se agrega después de L1». Si se recorta `autNivel`, la autorización entera llega después de L1 | ADR-62, precisión del punto 6 [V] | Baja | Técnicamente es seguro (`crit`). Si se usa el recorte, se registra como precisión de ADR-62 (Q-17). Por eso DL-09 pide el disparador |
| **O-3** | **Mejora barata para R-B11, para el auditor y el arquitecto-software.** Una licencia falsificada con `s1` puede traer un `vence` lejano y, en un cliente que no actualiza, valdría hasta esa fecha. Propuesta: que la API **rechace los archivos firmados solo en Básico cuyo `vence` supere `emitida` + 200 días** (cubre la reemisión semestral del cliente anual, ADR-61). Tiene que ir en los programas del corte, porque el problema son justamente los clientes que no actualizan | `[BP]` 10.5 (NV-08, R-B11); ADR-61, nota del 2026-10-08 | Media [I] | **Candidata a DL-14.** No la someto a firma hasta que la vean el auditor y el arquitecto-software. Unos 0,25 dp [I] |
| O-4 | `[BP]` SH-8 sugiere usar el «sello de seguridad» en lugar del hash para DL-05. No cierra SH-5 (ver DL-05 (c)) | `[BP]` 2.2 | Baja [I] | DL-05 recomienda el hash |
| O-5 | DL-07 depende de que el desarrollador de identidades no tenga otras tareas. El segundo PR de H-11 (rama `a/h11-p7-candado`) también es de backend y debe incorporar D-05 (`usp_RespaldoCopia`) | `[BP]` supuesto 1; `[DAT]` 3 | Media (calendario) | Condición de DL-07. El orquestador asigna H-11 a otra persona o la cuenta en la carga |
| O-6 | El total de la licencia es «unos 55 dp» en `[BP]` 11.2. La suma de sus propias partidas da entre 53 y 54 | `[BP]` 11.2 | Baja | No cambia ninguna conclusión. Dinero: unos USD 16 000 a 22 000 |
| O-7 | `[DAT]` 6.3 manda el evento `USUARIO_SIN_SELLO` a `BitacoraSistema`, que no existe | `[DAT]`:1029; `[BP]` C-05 | Baja | Se resuelve con DL-04 |
| O-8 | **ADR-126** (ningún valor de un tercero en el código): las fuentes NTP del emisor son valores de terceros y deben ir en su configuración. Las llaves públicas y la caducidad de `s1` **no**: van en los programas, por ADR-60, punto 6 («sin interruptores»). Es una excepción de seguridad, no un valor de tercero | ADR-126, punto 1; ADR-60, punto 6 | Baja | Anotado en el borrador de ADR-84 |
| O-9 | `[BP]` 10.6, condición 2 [I]: la política «PIN en cada uso» del proveedor TPM de Windows no está confirmada | `[BP]` supuesto 4 | Media | Se confirma en el ensayo de AI-09. Si no funciona, el auditor dictamina antes de la primera licencia de pago |

**No encontré contradicciones con ADR vigentes** fuera de las que resuelven F-2 y F-3 (ADR-61, ADR-62, Q-16, Q-19), O-2 (ADR-62, Q-17, solo si se usa DL-09) y las precisiones de ADR-82 (ADR-38 M-4, ADR-44 AC-4 y DD-13 de H-11).

---

## 6. Registro de la firma

| Campo | Valor |
|---|---|
| Firmado por | |
| Fecha | |
| Respuesta literal | |
| Dictamen de seguridad incorporado en DL-10 a DL-13 | `[ ]` Sí, informe: ____ `[ ]` Firmado sin esperarlo |

**Si firmas según la recomendación:**
- el desarrollador L arranca L1a-1 y el desarrollador I arranca el lote 1 con PA-47 (semana 1);
- el arquitecto de datos diseña `BitacoraSeguridad`, el padrón y `CambiosRnc`;
- devops prepara AI-09 con las condiciones de 10.6 (y DL-13);
- el documentador registra ADR-82, ADR-83 y ADR-84 a partir de los borradores (`borradores-adr-082-084-2026-10-14.md`) y las precisiones de ADR-59, ADR-60, ADR-61, ADR-62 y ADR-81.

**Si rechazas alguna:**
- **DL-01, DL-02 o DL-05:** el sello se construye con el diseño de `[DAT]` 6.3 y el hueco queda como riesgo aceptado por escrito;
- **DL-03:** hay que redactar otra prueba de NV-07, o aceptar que un cambio de RNC del ADMIN deja la empresa `Invalida` sin gracia;
- **DL-07:** el orquestador presenta otro reparto, o se recorta el emisor a enero;
- **DL-10 a DL-13:** se esperan las condiciones del auditor.
