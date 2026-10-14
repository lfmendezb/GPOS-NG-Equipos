# Hoja de firma DL-01 a DL-14: licencia firmada en el lote 2 de RG-14 (v2)

**Fecha:** 2026-10-14 · **Versión:** 2 · **Preparada por:** Arquitecto Maestro (equipo A) · **Decide y firma:** el propietario (Leonardo Méndez)
**Estado: Pendiente de firma.** Esta hoja no firma nada. Cada casilla la marca el propietario.

## Registro de cambios

| Versión | Fecha | Cambios |
|---|---|---|
| 1 | 2026-10-14 | Primera versión: DL-01 a DL-13. DL-10 a DL-13 «pendientes del dictamen de seguridad» |
| **2** | 2026-10-14 | **Incorpora el dictamen del auditor-seguridad** (`revision-seguridad-blueprint-licencia-lote2-2026-10-14.md`, en adelante `[SEG]`): Rechazado en v1 por tres hallazgos Altos (SEG-L2-01, 02 y 03); pasa a Aprobado con observaciones si la hoja incorpora su sección 9.<br>- Se quitan los marcadores «pendiente del dictamen».<br>- **Agrega DL-14** (tope de vigencia de 200 días para las licencias Básicas; era la observación O-3 de la v1).<br>- **Cambian:** DL-01 (cupo desde el padrón y copia en el disco), DL-02 (condición de Release), DL-03 (rutas después de la fase A de ADR-81, idempotente), DL-05 (de opcional a **obligatoria**, con el estado del factor), DL-07 (revisión de código del emisor), DL-10 (`s1r` con la cuenta deshabilitada y fuera de un equipo de desarrollo), DL-11 (cofirma en la transición), DL-12 (revisión de la aceptación a más tardar el **2027-03-31**) y DL-13 (de recomendada a **obligatoria antes de AI-09**).<br>- **Reescribe AP-04 / FY-15-B y R-L11-B** con las mitigaciones retiradas, las sustitutas y el vector corregido.<br>- Agrega el anexo A (condiciones E-1 a E-15) y el anexo B (hallazgos que se resuelven al construir).<br>- Sección 6 nueva: dónde discrepo del auditor y qué propongo en su lugar |

**Fuentes (solo lectura)**
- `[BP]` = `Solucion GPOS NG\blueprint-licencia-lote2-2026-10-14.md` v1 (arquitecto-software).
- `[DAT]` = `Solucion GPOS NG\datos-t3-12-rg14-2026-10-14.md` v2: D-01 a D-11 y L-01 firmadas; D-04 (ii) sin firma.
- `[SEG]` = `Solucion GPOS NG\revision-seguridad-blueprint-licencia-lote2-2026-10-14.md` (auditor-seguridad), secciones 4, 6 y 9.
- `[HOJA]` = `GPOS NG\docs\decisiones\2026-10-05-hoja-firma-seguridad.md` (FY-15, CP-4, CP-5 y R-L11 / R-F11; líneas 131 y 243-247).
- ADR-38, 44, 58 a 63, 68 y 81 (`GPOS NG\docs\adr`); ADR-126 (`master`).

**Convención.** *[V]* verificado en la fuente; *[I]* inferido. **dp** = días-persona (USD 300 a 400 cada uno).

**Palabras que se repiten**
- **`s1`**: la llave con la que GSF firma hoy las licencias (nivel Básico). Vive en el chip TPM de un equipo; no se puede copiar, pero quien controle ese equipo la puede **usar**.
- **YubiKeys**: llaves físicas (nivel Avanzado). Todavía no se han comprado.
- **Sello de habilitación**: una marca cifrada que la API pone en cada cuenta habilitada. Sin sello válido, la cuenta no entra.
- **Padrón**: la lista protegida de las cuentas selladas. Con la v2, **el cupo se cuenta desde el padrón**.
- **Estricto / Amplio**: Estricto es el modo de producción, con identidades de mínimo privilegio. Amplio es el de desarrollo, pruebas y DEMO.

---

## 1. Ya firmado hoy (2026-10-14): no se vuelve a preguntar

| # | Decisión del propietario | Qué sustituye o amplía |
|---|---|---|
| **F-1** | **Dos desarrolladores en paralelo** (identidades y licencia), **sin mover el corte de mediados de diciembre** | R-RG14-10 de `[DAT]` |
| **F-2** | **Licencias de pago firmables en nivel Básico** (`s1` en el TPM) hasta que existan las YubiKeys. **Riesgo Medio-Alto aceptado como temporal** | Precisa ADR-62 y AP-05: sustituye «la primera licencia de pago se firma en Avanzado». **Amplía P-F1 / FY-15**. El texto literal está en la sección 4.4 |
| **F-3** | **Equipo emisor: el equipo principal del propietario, con una cuenta de Windows dedicada solo a firmar.** Sin mini-PC. **Ceremonia de las YubiKeys preparada y sin fecha** | Precisa ADR-61 y Q-19 (de la opción (a) a una variante de la (b)) |

`[SEG]` no discute F-2 ni F-3. Evalúa si las mitigaciones bastan y qué condiciones tienen que ser obligatorias.

**Lo que exige la primera licencia de pago, con la v2** (`[BP]` 10.3 más `[SEG]` 9):
1. Lote 2 en verde: PA-12 y QA-L01 a L17.
2. AI-08 (pruebas R-E11 sobre Release).
3. **AI-09 con DL-13 cumplida antes** y acta con E-1 a E-15 (TPM revisado, prueba negativa y PIN pedido en cada firma).
4. **DL-14 construida** (tope de vigencia).
5. **Comparación de `sec`, `lid` y SHA-256 de la licencia vigente en la solicitud** (SEG-L2-09).
6. **Emisor reproducible y revisado por el auditor** (SEG-L2-08).
7. **AP-03 y AP-04 adaptados.**
8. AP-06.

Ya **no** exige AP-01 ni AP-05.

---

## 2. Resumen

| # | En una línea | Recomendación (con `[SEG]`) | Costo | Firmar antes de |
|---|---|---|---|---|
| DL-01 | Padrón de sellos: el cupo se cuenta desde el padrón, con copia en el disco | **Aprobar con la precisión** | 1,5 dp | 2026-11-06 |
| DL-02 | La API no crea cuentas al arrancar en Estricto **ni en ninguna compilación Release** | **Aprobar con la condición** | 0,75 dp | 2026-11-06 |
| DL-03 | El RNC solo lo cambia el SUPER; la ruta sale después de la fase A de ADR-81 | **Aprobar con la condición** | 0,85 dp + pantalla | 2026-11-13 |
| DL-04 | Eventos en `BitacoraSeguridad`, con una sola DDL | **Aprobar** | 0,5 dp | 2026-10-30 |
| DL-05 | El sello cubre el hash de la contraseña y, en el SUPER, el estado del factor | **Aprobar, obligatoria** | 0,75 dp | 2026-11-06 |
| DL-07 | Reparto entre los dos desarrolladores, con revisión de código del emisor | **Aprobar** | 0 + revisión | **2026-10-16** |
| DL-08 | La licencia queda construida para el corte | **Aprobar** (registro) | 0 | 2026-10-16 |
| DL-09 | Recorte de `autNivel` si hay atraso | **Autorizar con disparador** | −1,75 dp si se usa | 2026-11-13 |
| DL-10 | Llave Básica de reserva `s1r`, con la cuenta deshabilitada | **Aprobar con condiciones**, o la alternativa de la sección 6 | 0,5 dp | 2026-11-20 |
| DL-11 | La caducidad de `s1` la fija la versión con YubiKeys; cofirma en la transición | **Aprobar** | Incluido | 2026-12-01 |
| DL-12 | Fecha de compra y **revisión de la aceptación a más tardar el 2027-03-31** | **Aprobar con la condición** | USD 352 (ya presupuestados) | 2026-10-30 |
| DL-13 | Cuenta diaria sin permisos de administrador y condiciones E-1 a E-15 | **Aprobar, obligatoria antes de AI-09** | 0,75 dp de devops | **Antes de generar `s1`** |
| **DL-14** | **Nueva:** una licencia Básica vence como máximo 200 días después de emitida | **Aprobar** | 0,35 dp | 2026-11-06 |

*DL-06 está retirada: la sustituye F-2.*

**Recomendación de conjunto: Aprobar con observaciones.** Con las condiciones de `[SEG]` 9 incorporadas, el auditor pasa de Rechazado a Aprobado con observaciones. Para cerrarlo falta además que el arquitecto-software actualice §2.3, §10.5 y §10.6 de `[BP]` y que el auditor lo confirme en una lectura de diferencias (`[SEG]` 9).

**Calendario:** las remediaciones suman unos 4 dp [`SEG` 8, I]. Mi reparto aproximado:
- Desarrollador de identidades (I): de 23,0 a unos 25 dp.
- Desarrollador de la licencia (L): de 23,4 a unos 24,5 dp.

Los dos siguen por debajo de los 34,4 dp de capacidad. En el peor caso (+35 %), I llega a unos 33,8 dp: **el margen baja a menos de 1 dp**. Ver la observación O-5.

---

## 3. Las decisiones, una por una

### DL-01 · Padrón de sellos: el cupo se cuenta desde el padrón

**Qué se decide.** El sello impide ampliar la licencia insertando usuarios por SQL. `[BP]` encontró que repetir un sello viejo duplicaba el cupo (SH-1) y propuso el padrón. `[SEG]` (SEG-L2-01, **Alta**) encontró otro camino: el cupo se seguía contando con columnas de la tabla (`Inhabilitado`, `Nivel`) que se editan por SQL. Basta con «apagar» una cuenta por SQL, dar de alta otra y volver a «encenderla». Además, restaurar un padrón viejo devolvía cuentas después de una reducción de cupo (SEG-L2-07).

**Recomendación: Aprobar con la precisión de `[SEG]`:**
- **(a)** El cupo se cuenta desde las entradas no SUPER del padrón verificado, nunca desde las columnas. Cada entrada guarda el nivel.
  - El padrón se actualiza por diferencias y solo con acciones de la API.
  - Una fila borrada o alterada sigue contando hasta que el SUPER la purgue, con motivo y segundo factor.
- **(b)** Hay una copia completa del padrón en el disco del equipo de la API (carpeta protegida de ADR-77), y vale la versión mayor que verifique.
- *Mi precisión:* mientras la fase A de ADR-81 no esté unida, la purga se hace con `GPOS.Migracion` en el servidor, igual que en DL-03.

| Opción | Consecuencia |
|---|---|
| **(a) + (b) (recomendada)** | Cierra SH-1 y sus variantes. Una fila borrada por error sigue ocupando cupo hasta que GSF la purgue. Quien solo tiene acceso a SQL no puede retroceder el padrón; un administrador de Windows sí (residual de CP-4) |
| (c) Padrón de la v1, sin la precisión | **Rechazada por el auditor:** el cupo se duplica sin tocar ningún MAC |
| (d) Sin padrón | El sello no cumple su propósito |

**Costo:** 1,0 + 0,25 + 0,25 = 1,5 dp (SL). Precisa ADR-58, punto 9. Va en ADR-83.

`[ ] Aprobar (a)+(b)`   `[ ] Otra: ____`   `[ ] Aplazar`

---

### DL-02 · La API no crea cuentas al arrancar (Estricto y Release)

**Qué se decide.** Hoy, si no hay SUPER, la API crea uno al arrancar: borrar los SUPER por SQL y reiniciar fabrica un SUPER (SH-3). La v1 lo cerraba en Estricto. `[SEG]` (SEG-L2-05) muestra que Amplio es solo una clave de configuración, así que cambiarla reabriría el hueco y además provocaría un sellado nuevo de las cuentas insertadas a mano.

**Recomendación: Aprobar con la condición de `[SEG]`:**
- en una **compilación Release ningún modo sella ni crea cuentas al arrancar**: lo hace solo `GPOS.Migracion sistema` (el DEMO también, desde su instalador);
- con una licencia vigente de anillo `Produccion` o `Beta`, la API **no arranca en Amplio**;
- la creación automática queda solo en `Debug`.

| Opción | Consecuencia |
|---|---|
| **(a) Con la condición de Release (recomendada)** | Cierra SH-3 también frente a un cambio de configuración. **El instalador del DEMO tiene que llamar a `GPOS.Migracion sistema`** (devops). Una instalación Beta tiene que estar en Estricto |
| (b) La v1: solo en Estricto | Amplio queda como un interruptor de la licencia, contra ADR-60, punto 6 |

**Costo:** 0,5 + 0,25 dp. Precisa SEC-07 y SES-16. Va en ADR-83.

`[ ] Aprobar (a)`   `[ ] Otra: ____`   `[ ] Aplazar`

---

### DL-03 · El RNC de la empresa solo lo cambia el SUPER

**Qué se decide.** La licencia está atada al RNC. La regla firmada NV-07 (ADR-59) solo da transición si el cambio lo hizo el SUPER, y hoy el ADMIN también lo edita (`AdministracionService.cs:64`, `:109` [V en `[BP]`]). Se propone una ruta solo del SUPER, con motivo y segundo factor, que deja una prueba protegida. El ADMIN recibe el aviso «solo el SUPER puede cambiar el RNC».

**Recomendación: Aprobar con la condición de `[SEG]`** (SEG-L2-12 y SEG-L2-16):
- las rutas del SUPER para cambiar el RNC (S-03) y legitimar cuentas (S-02) **no se publican hasta que esté unida la fase A de ADR-81**. Sin el segundo factor, una contraseña filtrada del SUPER bastaría;
- mientras tanto, el cambio de RNC se hace con `GPOS.Migracion` en el servidor, con motivo;
- S-03 es **idempotente**, y el cambio solo cuenta cuando el RNC de la empresa ya es el nuevo.

| Opción | Consecuencia |
|---|---|
| **(a) Solo el SUPER, rutas después de la fase A de ADR-81 (recomendada)** | El ADMIN ve el RNC de solo lectura **desde ya**. Hasta la fase A, cambiar un RNC exige al técnico de GSF en el servidor |
| (b) El ADMIN sigue editándolo | Por la regla firmada, la empresa queda `Invalida` sin gracia en cuanto cambia el RNC |
| (c) Publicar S-03 sin segundo factor | Rechazada por el auditor |

**Costo:** 0,75 + 0,1 dp, más un ajuste de pantalla. Es una precisión de ADR-59 (NV-07).

`[ ] Aprobar (a)`   `[ ] Otra: ____`   `[ ] Aplazar`

---

### DL-04 · Bitácora de la licencia y del sello

**Qué se decide.** `BitacoraSistema` (ADR-37 y ADR-60) no existe. Los eventos irían a `BitacoraSeguridad` (ADR-81: solo inserción, 2 años de retención) hasta que exista. `[SEG]` la da por correcta.

**Recomendación: Aprobar**, con mi precisión de la v1: **una sola DDL**, del arquitecto de datos, que crea `GPOS.Migracion sistema` (ADR-38, M-4), y no la del desarrollador «que llegue primero».

| Opción | Consecuencia |
|---|---|
| **(a) `BitacoraSeguridad` con una sola DDL (recomendada)** | Hay que unirla con `BitacoraSistema` cuando llegue |
| (b) Construir ya `BitacoraSistema` | Adelanta trabajo sin dueño ni calendario |
| (c) Solo el Visor de eventos | No viaja con los respaldos; quien administra el servidor lo borra |

**Costo:** 0,5 dp. Es una precisión de ADR-81 (punto 12) y de ADR-60 (punto 8).

`[ ] Aprobar (a)`   `[ ] Otra: ____`   `[ ] Aplazar`

---

### DL-05 · El sello cubre la contraseña y el factor (obligatoria)

**Qué se decide.** Un `sysadmin` puede reemplazar el hash de la contraseña de una cuenta sellada y entrar con ella (SH-5). `[SEG]` (SEG-L2-06) agrega dos cosas:
- ADR-81 no está construido;
- aun construido, si se borra por SQL la fila del factor de un SUPER, quien entre con la contraseña cambiada **da de alta su propio factor**.

**Recomendación: Aprobar como obligatoria (ya no es opcional):**
- el sello incluye la huella del hash de la contraseña;
- en los SUPER incluye además el estado «factor dado de alta: sí o no». Si un SUPER sellado con factor pierde esa fila, no entra y se restablece solo por las vías de ADR-81, punto 7.

| Opción | Consecuencia |
|---|---|
| **(a) Hash de la contraseña + estado del factor del SUPER (recomendada)** | Cierra SH-5 y la variante del factor. Se vuelve a sellar en cada cambio o restablecimiento de contraseña y en el alta o baja del factor |
| (b) Usar el `SelloSeguridad` en lugar del hash (`[SEG]` lo admite) | **Discrepo** (sección 6, D-1): no cierra SH-5 |
| (c) No | Rechazada por el auditor |

**Costo:** 0,5 + 0,25 dp. Va en ADR-83.

`[ ] Aprobar (a)`   `[ ] Otra: ____`

---

### DL-07 · Reparto entre los dos desarrolladores

**Qué se decide.** Tú firmaste dos desarrolladores (F-1). El reparto propuesto pasa al desarrollador de identidades el sello, el anillo H-17 v2, el cambio de RNC y el emisor. Si el desarrollador de la licencia lo hiciera todo, no cabría: unos 37 dp frente a 34,4.

**Recomendación: Aprobar, con dos condiciones:**
1. El desarrollador de identidades **no tiene otras tareas hasta el corte** (por ejemplo, el segundo PR de H-11).
2. Condición de `[SEG]` (SEG-L2-08): **revisión de código del auditor sobre el emisor y `GPOS.Criptografia`** antes de la primera licencia de pago.

| Opción | L | I | ¿Cabe? |
|---|---|---|---|
| **(a) Reparto propuesto (recomendada)** | ≈ 24,5 dp con la v2 | ≈ 25 dp con la v2 | Sí en el escenario central; **menos de 1 dp de margen para I con +35 %** |
| (b) Reparto literal | ≈ 38 dp | ≈ 6 dp | No |

**Costo:** 0, más unos 2 a 3 días del auditor para la revisión [I].

`[ ] Aprobar (a)`   `[ ] Otra: ____`

---

### DL-08 · Calendario: la licencia queda construida para el corte

**Qué se decide.** Registrar que el código de la licencia se completa para el 2026-12-15, en lugar de las fechas de Q-24 y Q-25 (inicio el 2026-11-02 y publicación en enero de 2027). Es consecuencia de F-1. El auditor no tiene objeción.

**Recomendación: Aprobar.** El orquestador lo registra (G-1.6).

| Opción | Consecuencia |
|---|---|
| **(a) Registrar (recomendada)** | Hitos de `[BP]` 11.3: H-1 el 10-23, H-2 el 11-06, H-3 el 11-13 y código completo el 12-04 |
| (b) Mantener Q-24 y Q-25 | Contradice F-1 |

`[ ] Aprobar (a)`   `[ ] Otra: ____`

---

### DL-09 · Recorte de `autNivel` si hay atraso (condicional)

**Qué se decide.** Si el calendario se atrasa, la «autorización de regreso temporal a Básico» sale de esta versión: ahorra 1,75 dp. Solo sirve cuando existan las YubiKeys. `[SEG]`: sin objeción, porque falla cerrado.

**Recomendación: autorizarlo ya con un disparador objetivo:** el orquestador confirma un atraso de 5 días hábiles o más respecto de H-3 (2026-11-13). Si se usa, se registra como precisión de ADR-62 (Q-17 decía «desde L1»; observación O-2).

| Opción | Consecuencia |
|---|---|
| **(a) Con el disparador (recomendada)** | Sin demoras de firma en el momento de presión |
| (b) Decidir si llega el atraso | Una firma más en el peor momento |
| (c) No recortar nunca | Se sacrifica otra cosa o el corte |

`[ ] Aprobar (a)`   `[ ] (b)`   `[ ] (c)`

---

### DL-10 · Llave Básica de reserva `s1r`

**Qué se decide.** Con F-2, toda la firma de pago depende de `s1` en un solo equipo. Si ese TPM se pierde, GSF no puede renovar hasta publicar una versión nueva y que cada cliente la instale (R-B12, Media / Alto). La reserva es una segunda llave `s1r` en el TPM de **otro** equipo, incluida en los programas del corte. `[SEG]` (SEG-L2-11): sirve contra la pérdida, pero **duplica los lugares desde donde se pueden falsificar licencias** y no acelera el retiro.

**Recomendación: Aprobar con las condiciones de `[SEG]`:**
1. el segundo equipo **no es de desarrollo** ni ejecuta agentes;
2. cumple E-1 a E-15 (anexo A);
3. la cuenta de `s1r` **queda deshabilitada** salvo en la firma de prueba trimestral y en una emergencia; el equipo puede quedar apagado;
4. el PIN de `s1r` lo custodia otra persona (el suplente de AP-02) o queda en un sobre precintado.

Además se corrige `[BP]` §10.5: «DL-10 cubre la pérdida; el compromiso lo acota DL-14».
**Alternativa que pongo a tu consideración** (sección 6, D-2): dos YubiKeys en lugar de la reserva en TPM.

| Opción | Consecuencia |
|---|---|
| **(a) `s1r` con las condiciones (recomendada si no se compran YubiKeys)** | Cubre la pérdida. Necesita un segundo equipo que no sea de desarrollo [I: hay que identificarlo] |
| (b) Sin reserva | Depende de que cada cliente instale una versión nueva dentro de su gracia (unos 10 días) |
| (c) Comprar YubiKeys para `s1` y `s1r` (D-2) | Cubre la pérdida **y** la firma silenciosa de R-B13 por unos USD 110 a 176. Cambia «en el TPM» de F-2, así que requiere tu decisión expresa |

**Costo:** 0,5 dp (desarrollo y devops). **Plazo:** generarla con acta antes del 2026-11-27.

`[ ] Aprobar (a)`   `[ ] (b)`   `[ ] (c), ver D-2`

---

### DL-11 · Cuándo deja de valer `s1`

**Qué se decide.** La caducidad del 2026-12-31 (Q-16) solo rige cuando hay una llave Avanzada en los programas (INV-1), así que hoy no tiene efecto, y si quedara fija rompería la transición en 2027. La propuesta: la fecha de fin de `s1` (y de `s1r`) **la fija la versión que trae las YubiKeys**, en su publicación más 45 días.

**Recomendación: Aprobar**, con dos precisiones:
- la mía: la fecha queda escrita en el PR de las llaves y se corrige si la publicación se retrasa más de 7 días;
- la de `[SEG]` (SEG-L2-22): **en la reemisión de transición, cofirmar cada archivo con `s1` y `a1`**. Así lo aceptan los programas viejos y los nuevos, y los 45 días dejan de ser críticos para quien actualiza tarde.

| Opción | Consecuencia |
|---|---|
| **(a) Versión con YubiKeys + 45 días, con cofirma (recomendada)** | Transición sin cortes. Cofirmar cuesta un toque más por archivo [I] |
| (b) Fecha de compilación + 90 días (Q-16, escenario B) | Más exposición de `s1` sin necesidad |
| (c) Mantener el 2026-12-31 | Rompe la transición si las YubiKeys llegan en 2027 |

**Costo:** dentro de los 0,5 dp de `[BP]` 10.3. Precisa Q-16 e INV-1. Va en ADR-84.

`[ ] Aprobar (a)`   `[ ] (b)`   `[ ] Otra: ____`

---

### DL-12 · Fecha de compra y caducidad de la aceptación del riesgo

**Qué se decide.** Firmaste la ceremonia **sin fecha** (F-3), y eso no se reabre. `[SEG]` (SEG-L2-13) pide que la **aceptación** del riesgo Medio-Alto tenga caducidad: sin ella, una medida «temporal» se vuelve permanente sin que nadie lo vuelva a decidir.

**Recomendación: Aprobar con la condición de `[SEG]`:**
- **la aceptación vence el 2027-03-31 como máximo**, o antes si ocurre lo primero de esto: el primer contrato de pago, o la sesión de cierre del corte (2026-12-15), según mi propuesta de la v1;
- al vencer sin ceremonia, **se vuelve a firmar con la estimación de ese momento**. No se detiene la emisión: solo se vuelve a decidir;
- **fecha de compra:** la fijas tú. Mi sugerencia es no más tarde que el primer contrato de pago. Comprar no fija la ceremonia, que sigue sin fecha.

| Opción | Consecuencia |
|---|---|
| **(a) Revisión con tope del 2027-03-31 y fecha de compra (recomendada)** | Cumple la condición del auditor sin tocar F-3 |
| (b) Sin fechas (como en F-3) | El auditor la rechaza (SEG-L2-13) |

`[ ] Aprobar (a)`, fecha de compra: ____ , fecha de revisión (≤ 2027-03-31): ____
`[ ] (b)`

---

### DL-13 · Cuenta diaria sin permisos de administrador (obligatoria antes de AI-09)

**Qué se decide.** `[SEG]` (SEG-L2-03, **Alta**) corrige la premisa de la v1:
- si tu cuenta diaria es administradora, un programa malicioso puede capturar el PIN **una vez** y desde entonces **usar `s1` en silencio en cualquier momento**, sin abrir la cuenta de firma y sin que veas ningún resumen [I: se confirma en el ensayo];
- el «PIN en cada firma» no protege frente a eso;
- en el equipo principal además corren compilaciones, instaladores y agentes de IA que procesan contenido externo.

**Recomendación: Aprobar como obligatoria y previa a AI-09** (la generación de `s1`). Si `s1` nace con la cuenta diaria administradora, el PIN puede quedar capturado desde el primer día. Las condiciones son **E-1 a E-15** (anexo A). E-1 es la central: tu cuenta diaria pasa a estándar y la cuenta administradora aparte se usa solo para mantenimiento, **nunca para navegar, leer correo, compilar ni ejecutar agentes**.

| Opción | Consecuencia |
|---|---|
| **(a) Obligatoria con E-1 a E-15 (recomendada)** | Con DL-14 y las condiciones de la primera licencia de pago (sección 1), el riesgo baja a **Medio** según `[SEG]`. Costo de uso: cambiar de sesión para firmar y de cuenta para administrar. **Ver O-6:** si el equipo principal es el de desarrollo, el costo de uso es alto |
| (b) Recomendada, no obligatoria | El auditor la rechaza |
| (c) Mini-PC dedicado | Descartado por ti (F-3) |

**Costo:** 0 en dinero; unos 0,75 dp de devops.

`[ ] Aprobar (a)`   `[ ] Otra: ____`

---

### DL-14 · Tope de vigencia de las licencias Básicas (nueva)

**Qué se decide.** Hoy una licencia no tiene un vencimiento máximo. Si `s1` se compromete, quien la use firma una licencia que vence dentro de muchos años, y un cliente que no instala versiones nuevas la conserva indefinidamente (SEG-L2-02, **Alta**). Dos de las mitigaciones de FY-15 ya no existen: la caducidad del 2026-12-31 y las «vigencias mensuales», que **nunca fueron una regla técnica**. La propuesta:
- un archivo **sin firma Avanzada propia** se rechaza (422) si algún `vence`, de empresa o de módulo, pasa de **`emitida` + 200 días**;
- el emisor Básico da a los clientes anuales archivos semestrales.

Coincide con mi observación O-3 de la v1.

**Recomendación: Aprobar.** Tiene que ir en los programas del corte: el problema son justamente los clientes que no actualizan.

| Opción | Consecuencia |
|---|---|
| **(a) 200 días (recomendada)** | Una licencia falsificada vale como máximo unos 7 meses. El cliente anual recibe dos archivos al año mientras dure el Básico (compatible con la reemisión semestral, ADR-61) |
| (b) 62 días | Acota a unos 2 meses, pero el cliente anual carga un archivo cada mes, sin agente |
| (c) 400 días | Solo evita el «año fijado por el falsificador» |
| (d) Sin tope | Rechazada por el auditor; bloquea la primera licencia de pago |

**Costo:** 0,25 dp (L1a-2) + 0,1 dp (emisor). Precisa ADR-62 e INV-1. Va en ADR-84.

`[ ] Aprobar (a)`   `[ ] (b)`   `[ ] (c)`

---

## 4. Pendientes que no son DL: lo que se necesita del propietario

### 4.1 CI-7 / AI-07 · Validación legal de las tres excepciones (antes del 2026-11-16)

**Qué es.** Con la licencia vencida (solo consulta), tres operaciones siguen permitidas por ley ([LIC] LV-12):
1. rectificar o suprimir datos personales (Ley 172-13);
2. anular o comunicar secuencias y rangos de NCF y e-CF no usados (incluido el ANECF);
3. restablecer contraseñas y desbloquear cuentas.

**Qué se necesita:** encargar la consulta al asesor legal **esta semana**. Quedan 33 días.
**Si no llega a tiempo:** las tres quedan bloqueadas, lo que falla del lado restrictivo, hasta la validación.

### 4.2 AP-02 · Custodio suplente

Deja de ser condición mientras no haya `b1`. **Con DL-10 (a)**, alguien distinto de ti debe custodiar el PIN de `s1r`, o este va en un sobre precintado. **Qué se necesita:** decidir si se designa ahora. El nombre va en el acta, no en los documentos.

### 4.3 AP-03 · Procedimientos adaptados al nivel Básico (antes de la primera licencia de pago)

Los redacta devops contigo y se ensayan una vez, con la llave de desarrollo:
1. compromiso de `s1` o de `s1r`: reemisión, versión que retira la llave y aviso a los clientes;
2. pérdida de `s1` o del equipo: pasar a `s1r` o emitir una versión de emergencia;
3. ausencia del titular;
4. **(nuevo, E-15)**: no aceptar nunca un «reinicio del fTPM» ni un «borrado del TPM»; protocolo antes de cada actualización del BIOS (suspender BitLocker y revisar el aviso del fabricante); **firma de prueba trimestral** con `s1` y con `s1r`, para detectar una pérdida antes de necesitar la llave.

**Qué se necesita:** unas 2 a 3 horas y un ensayo con devops [I].

### 4.4 AP-04 · Aceptaciones escritas (textos adaptados; antes de la primera licencia de pago)

- **CP-4** (modificación de los binarios) y **CP-5** (clonación deliberada): sin cambios, con el texto literal de `[HOJA]` 245-246. El residual de CP-4 incluye ahora, de forma expresa, que **el sello no protege los permisos granulares** frente a un `sysadmin` (SEG-L2-04).

- **FY-15-B: texto literal de la ampliación de P-F1.** Registra lo que firmaste en F-2. Lo reescribí con lo que exige `[SEG]` 9: las mitigaciones retiradas, las que las sustituyen y el vector corregido. Confirma que refleja tu decisión:

  > *«Amplío mi aceptación de P-F1 (FY-15). Mientras no existan las YubiKeys, GSF firmará también las licencias de pago en Seguridad Básica, con la llave `gsf-lic-s1` en el TPM de mi equipo principal, en una cuenta de Windows dedicada solo a firmar.*
  >
  > *Acepto que, si un programa con privilegios de administrador de ese equipo captura el PIN de la llave, podrá usarla (no copiarla) en cualquier momento, sin abrir la cuenta de firma y sin que yo vea ningún resumen, para firmar licencias de pago para cualquier instalación; y que un programa en la sesión de firma podría mostrarme un resumen y firmar otro contenido. Acepto también que una licencia así no se puede retirar en un cliente que no instale las versiones nuevas, que no hay corte inmediato para los clientes en Básico y que GSF solo la detectará cuando ese cliente pida una renovación.*
  >
  > *Dejan de existir dos mitigaciones de FY-15: el equipo dedicado y la caducidad técnica del 2026-12-31, que no rige mientras no haya llaves Avanzadas en los programas. Las vigencias mensuales nunca fueron una regla técnica.*
  >
  > *Las sustituyen:*
  > - *(1) la cuenta diaria sin privilegios de administrador y las condiciones E-1 a E-15, cumplidas antes de generar la llave (DL-13);*
  > - *(2) el tope técnico de 200 días de vigencia para toda licencia sin firma Avanzada (DL-14);*
  > - *(3) el emisor compilado de forma reproducible y revisado;*
  > - *(4) la comparación de la licencia vigente en cada solicitud;*
  > - *(5) la revisión del TPM y la prueba negativa en el acta;*
  > - *(6) se mantienen el PIN de la llave, la confirmación de cada firma y el registro encadenado con ancla enviada desde otro dispositivo.*
  >
  > *Riesgo residual: Medio-Alto mientras falte alguna de las sustituciones (1) a (5); Medio con todas cumplidas. Esta aceptación es temporal y **vence el [fecha de DL-12, no después del 2027-03-31]**, o antes si se reemite en Avanzado (AP-05). Al vencer, se vuelve a firmar con la estimación de ese momento.»*

- **R-L11-B: sustituye a R-L11 mientras se firme en Básico.** La parte de R-F11 sobre las YubiKeys del manifiesto no cambia.

  > **Con DL-10 (a).** *«Acepto por escrito que, mientras GSF firme las licencias en Seguridad Básica, si se pierden a la vez la llave `gsf-lic-s1` del equipo principal y la llave de reserva `gsf-lic-s1r` del segundo equipo (por falla o borrado del TPM, reinicio del fTPM, reinstalación de Windows o pérdida de los equipos), GSF no podrá emitir ni renovar licencias hasta publicar una versión de GPOS NG con una llave nueva y que cada cliente la instale; y que, si eso tarda más que la gracia de cada cliente, esos clientes pasarán a solo consulta. Se mitiga con las dos llaves en equipos y lugares distintos, la firma de prueba trimestral de cada una y el procedimiento de emergencia ensayado. Riesgo residual: Bajo.»*
  >
  > **Sin DL-10.** *«Acepto por escrito que, mientras GSF firme las licencias en Seguridad Básica, si se pierde la llave `gsf-lic-s1` (por falla o borrado del TPM, reinicio del fTPM, reinstalación de Windows o pérdida del equipo principal), GSF no podrá emitir ni renovar licencias hasta publicar una versión de GPOS NG con una llave nueva y que cada cliente la instale; y que, si eso tarda más que la gracia de cada cliente, esos clientes pasarán a solo consulta. Se mitiga con la firma de prueba trimestral y el procedimiento de emergencia ensayado. Riesgo residual: Medio.»*

`[ ] Confirmo FY-15-B`   `[ ] Corregir: ____`
`[ ] Acepto R-L11-B (con DL-10 / sin DL-10)`   `[ ] Acepto CP-4`   `[ ] Acepto CP-5`

### 4.5 AP-06 · Contrato de suscripción con el asesor legal (antes del primer cliente)

Debe cubrir:
- la cláusula del último período;
- la regla (iii) de D-04 (GSF administra la instancia; el TI del cliente no es `sysadmin`);
- que alterar la instalación es un incumplimiento (CP-4 y CP-5).

Además, por F-2 y DL-14:
- no presentar la firma Básica como «hardware validado» ni FIPS (Q-21);
- prever la reemisión al pasar a Avanzado;
- **los clientes anuales reciben dos archivos de licencia al año** mientras dure el Básico.

**Qué se necesita:** encargarlo junto con AI-07, al mismo asesor.

### 4.6 Otras acciones del propietario

| Qué | Cuándo |
|---|---|
| **DL-13 / E-1 cumplida y AI-09** (generar `s1` con devops y acta con E-1 a E-15) | AI-09 **después** de DL-13; plan S3-S4 (10-26 a 11-06) |
| Identificar el segundo equipo para `s1r` (DL-10): que no sea de desarrollo | Antes del 2026-11-20 |
| Custodia de los certificados de H-17 v2 (Q-22) | Antes del 2026-11-02 |
| `contained database authentication` en la PC A | Antes de PA-12 |
| Quién registra ADR-82 en `master` (pregunta que B ya te pasó) | Antes de unir el lote 1 |

---

## 5. Observaciones del Maestro

| # | Observación | Severidad | Cómo queda |
|---|---|---|---|
| O-1 | El texto de FY-15 se apoyaba en mitigaciones que ya no existen | Media | Resuelta con FY-15-B (4.4) |
| O-2 | Si se usa DL-09, contradice la precisión Q-17 de ADR-62 («desde L1») | Baja | Se registra como precisión si se usa |
| ~~O-3~~ | *Pasó a DL-14 (coincide con SEG-L2-02)* | — | — |
| O-4 | Ver la discrepancia D-1 (sección 6) | Baja | — |
| **O-5** | **Margen del calendario.** Con unos 4 dp de remediaciones, el desarrollador I queda con menos de 1 dp de margen en el peor caso (+35 %). Además hay unos 2 a 3 días del auditor para la revisión del emisor | Media | El orquestador vigila H-2 (11-06). Si I se atrasa, se aplican primero los recortes 1 a 3 de `[BP]` 11.4, que no necesitan firma |
| **O-6** | **El «equipo principal» puede ser el de desarrollo.** E-1 prohíbe que la cuenta administradora compile o ejecute agentes. Si en ese equipo corren los agentes, las compilaciones y los instaladores del DEMO (que piden permisos de administrador), el costo de uso de DL-13 es alto y la superficie de SEG-L2-03 es la máxima | Media | Devops hace un inventario de las tareas de desarrollo que exigen administrador antes de AI-09. Si son muchas, ver D-2 |
| O-7 | `[BP]` §10.5 y §10.6 siguen en v1 | Baja | El arquitecto-software los actualiza con `[SEG]`, y el auditor hace la lectura de diferencias |
| O-8 | ADR-126: las fuentes NTP del emisor van en su configuración; las llaves y su caducidad van en los programas (ADR-60, punto 6) | Baja | En el borrador de ADR-84 |

---

## 6. Dónde discrepo del auditor (y qué propongo en su lugar)

| # | Punto de `[SEG]` | Mi posición | Alternativa |
|---|---|---|---|
| **D-1** | DL-05: el sello cubre «el hash de la contraseña **o** el `SelloSeguridad`» | **El `SelloSeguridad` no basta** [I]. Un `sysadmin` que cambia el hash por SQL deja ese valor intacto, y el sello seguiría verificando | Solo el hash (más el estado del factor del SUPER). Pido al auditor que lo confirme en la lectura de diferencias |
| **D-2** | SEG-L2-23 (informativa): `s1` en una YubiKey **no FIPS** (unos USD 55) con toque obligatorio | **De acuerdo con el fondo, pero comprar la serie FIPS cuesta casi lo mismo.** La FIPS cuesta unos USD 88, unos USD 33 más (precios de lista sin verificar). Si se van a comprar YubiKeys, conviene comprar las FIPS: sirven ya para `s1` y `s1r` en nivel Básico, con el proveedor YubiKey y el toque obligatorio, y después para la ceremonia sin otra compra | **Opción para tu decisión, no recomendación sobre F-2:** comprar ya dos YubiKeys FIPS de licencias (unos USD 176), usarlas en Básico con toque obligatorio en lugar del TPM, y hacer la ceremonia cuando quieras. Cierra la firma silenciosa (Bajo-Medio según `[SEG]`), sustituye a DL-10 y reduce el costo de uso de DL-13 (O-6). **Toca el «TPM» de F-2, así que solo procede si tú lo eliges** |
| D-3 | DL-13 / E-1: la cuenta administradora «nunca compila ni ejecuta agentes» | De acuerdo con la regla. Discrepo solo en que sea viable sin más en un equipo de desarrollo (O-6) | Inventario previo de devops; si no es viable, D-2 o un equipo distinto para firmar |
| D-4 | DL-12: «fecha de compra» obligatoria | De acuerdo con la caducidad de la aceptación (2027-03-31). La fecha de compra la pongo como campo tuyo, no como condición, para no reabrir F-3 | Si el auditor la exige como condición, basta con una fecha cualquiera no posterior a la revisión |

En todo lo demás coincido con `[SEG]`: DL-01 (a)+(b), DL-02 con la condición de Release, DL-03 después de la fase A de ADR-81, DL-05 y DL-13 obligatorias, DL-10 con condiciones, la cofirma de DL-11, DL-14 a 200 días y las condiciones de la primera licencia de pago.

---

## 7. Registro de la firma

| Campo | Valor |
|---|---|
| Firmado por | |
| Fecha | |
| Respuesta literal | |
| Lectura de diferencias del auditor sobre `[BP]` actualizado | `[ ]` Hecha: ____ `[ ]` Pendiente |

**Si firmas según la recomendación:**
- **no se genera `s1` (AI-09) hasta cumplir DL-13 / E-1**;
- el desarrollador L arranca L1a-1 e incorpora DL-14 en L1a-2;
- el desarrollador I arranca el lote 1 con PA-47 y construye SL con DL-01 (a)+(b), DL-02 y DL-05;
- el arquitecto-software actualiza `[BP]`;
- el arquitecto de datos diseña `BitacoraSeguridad`, el padrón con nivel y `CambiosRnc`;
- devops prepara E-1 a E-15 y el inventario de O-6;
- el documentador registra ADR-82 a 84 a partir de `borradores-adr-082-084-2026-10-14.md`.

**Si rechazas alguna:**
- **DL-01, DL-05, DL-13 o DL-14:** quedan abiertos hallazgos Altos o Medios del auditor. Hace falta una aceptación escrita adicional y **la primera licencia de pago queda bloqueada** en el caso de DL-13 y DL-14;
- **DL-03:** hay que redactar otra prueba de NV-07;
- **DL-07:** el orquestador presenta otro reparto o el emisor pasa a enero;
- **DL-10:** queda R-B12 (Medio / Alto), aceptado con R-L11-B sin DL-10.

---

## Anexo A · Condiciones E-1 a E-15 del equipo y la cuenta de firma (resumen de `[SEG]` §6)

Las verifica devops contigo y quedan en el acta de AI-09 **antes de generar `s1`**.

| # | Condición |
|---|---|
| **E-1** | **Cuenta diaria estándar** y cuenta administradora aparte, solo para mantenimiento (nunca navegar, correo, compilar ni agentes); UAC en «notificar siempre». **Obligatoria (DL-13)** |
| E-2 | `gsf-firma`: cuenta local estándar, sin cuenta Microsoft, escritorio remoto, correo, navegador ni sincronización; contraseña de 16 caracteres o más, no guardada en el equipo |
| E-3 | Se entra solo para firmar y **se cierra la sesión** al terminar |
| E-4 | El firewall bloquea todo el tráfico saliente de `gsf-firma` salvo NTP hacia las dos fuentes del emisor [I] |
| E-5 | Ninguna herramienta de acceso remoto activa durante la firma (recomendado: ninguna instalada) |
| E-6 | `s1` no exportable, PIN pedido en cada firma (comprobado con dos firmas seguidas), PIN de 8 caracteres alfanuméricos o más, no guardado en el equipo |
| E-7 | TPM revisado (fabricante, modelo y firmware; no afectado por TPM-FAIL) y **prueba negativa**: intentar usar la llave desde la cuenta administradora |
| E-8 | Resumen derivado de los bytes que se firman y verificación posterior con la llave pública publicada |
| E-9 | Carpeta de la llave fuera de respaldos, instantáneas y sincronización desde la generación |
| E-10 | BitLocker con PIN de arranque; clave de recuperación fuera del equipo |
| E-11 | Emisor compilado de forma reproducible fuera del equipo emisor, con el hash comparado en otro dispositivo e instalado en `Program Files` con la cuenta administradora |
| E-12 | Registro encadenado; el ancla la envías **desde otro dispositivo** (por ejemplo, el teléfono); copia semanal fuera de Drive |
| E-13 | Arranque seguro, integridad de memoria (HVCI), Defender con protección contra alteraciones, Windows Update al día, `w32time` confiable |
| E-14 | Auditoría de los usos de la llave y comparación mensual con el registro del emisor [I] |
| E-15 | AP-03 adaptado: nunca reiniciar el fTPM ni borrar el TPM; protocolo antes de actualizar el BIOS; firma de prueba trimestral |

**Costo:** 0 en dinero, unos 0,75 dp de devops.

## Anexo B · Hallazgos de `[SEG]` que se resuelven al construir (sin firma)

| Hallazgo | Qué se hace | Dónde |
|---|---|---|
| SEG-L2-04 (Media) | SH-2 baja de Alta a Media. El sello protege el cupo, el nivel y la sucursal, no los permisos granulares (residual de CP-4). Se mantiene la verificación por petición | `[BP]` §2.2, `[DAT]` 6.2 |
| SEG-L2-08 / 09 (Media) | Emisor reproducible y revisado; `SecVigente`, `LidVigente` y SHA-256 en la solicitud, comparados por el emisor | Condiciones de la primera licencia de pago (sección 1) |
| SEG-L2-14 (Baja) | Ancla desde otro dispositivo; `gsf-firma` sin escritura en carpetas sincronizadas | E-12 |
| SEG-L2-15 (Baja) | L-08 (licencia vigente) solo para el SUPER | L1b |
| SEG-L2-16 (Baja) | S-03 idempotente | DL-03 |
| SEG-L2-17 (Baja) | El sello se comprueba **antes** que la contraseña, con hash ficticio | SL |
| SEG-L2-18 (Baja) | Rechazar firmas con `s` alto, o «ya aceptado» sobre la entrada de la firma; vector negativo | L1a-1 |
| SEG-L2-19 (Baja) | Resumen derivado de los bytes; verificación tras firmar; vectores DER con ceros | EM |
| SEG-L2-20 (Baja) | Caché global del padrón por versión | SL |
| SEG-L2-21 (Inf.) | Verificador con `ECDsa` de la plataforma; Q-21 se mantiene | L1a-1 |
