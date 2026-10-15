# Hoja de firma DL-01 a DL-22: licencia firmada en el lote 2 de RG-14 (v2.12)

**Fecha:** 2026-10-14 (v2.8 a v2.12: 2026-10-15) · **Versión:** 2.12 · **Preparada por:** Arquitecto Maestro (equipo A) · **Decide y firma:** el propietario (Leonardo Méndez)
**Estado: Pendiente de firma.** Esta hoja no firma nada. Cada casilla la marca el propietario.

## Registro de cambios

| Versión | Fecha | Cambios |
|---|---|---|
| 1 | 2026-10-14 | Primera versión: DL-01 a DL-13. DL-10 a DL-13 «pendientes del dictamen de seguridad» |
| 2 | 2026-10-14 | Incorpora el dictamen del auditor-seguridad (`[SEG]`, sección 9: Rechazado en v1 por SEG-L2-01, 02 y 03).<br>- Agrega DL-14 (tope de 200 días).<br>- DL-05 y DL-13 pasan a obligatorias.<br>- Condiciones nuevas en DL-01, DL-02, DL-03, DL-07, DL-10, DL-11 y DL-12.<br>- FY-15-B y R-L11-B reescritos.<br>- Anexos A y B, y sección 6 de discrepancias |
| **2.1** | 2026-10-14 | Incorpora la **lectura de diferencias del auditor** (`[SEG]`, «Lectura de diferencias v2», D.1 a D.7): **Aprobado con observaciones**.<br>- **E-1** (anexo A y DL-13) agrega **SEG-L2-25**: la cuenta diaria no es `sysadmin` de ninguna instancia SQL local ni pertenece a grupos con efecto de administrador; `dbcreator` para pruebas; un inicio de sesión nominal aparte para lo que exija `sysadmin`; `s1` no se genera hasta que devops lo verifique.<br>- **Anexo B:** SEG-L2-18 como quedó en el blueprint v2 (identidad por SHA-256 del contenido), SEG-L2-24 (Baja) y los verbos provisionales (D.2).<br>- **Fuentes:** citan el blueprint v2.<br>- **DL-10 unificada con el blueprint v2:** (a) `s1r` en TPM; (b) YubiKeys en Básico. Recoge la condición del auditor de usar dispositivos distintos para Básico y para la ceremonia.<br>- **Sección 6:** D-1 cerrada de acuerdo; D-2 con la condición del auditor; D-3 con su respuesta; D-4 aceptada.<br>- **Carga del desarrollador I** con las cifras del blueprint v2 (24,1 dp con el recorte 1 anticipado; 26,1 dp sin él); el **recorte 1 queda como recomendación explícita** |
| **2.2** | 2026-10-14 | Incorpora el blueprint v2.2 (validación del PR #31, L1a-3 «Motor de estados») y el inventario O-6.<br>- **Agrega DL-15** (H-3, Media): un archivo sin firma Avanzada respeta el mínimo de la transición al acortar un `vence`.<br>- **DL-03** recoge la precisión P-3 / SEG-PR31-01: S-03 escribe la fila «del RNC licenciado al actual», conservando `RncAnterior` y `CambiadoUtc`; la fila solo vale contra la licencia aceptada antes del cambio.<br>- **Inventario O-6:** la PC A no cumple E-1 (con SEG-L2-25), E-5, E-10 ni E-13. Recomienda DL-10 (b) y que el propietario **confirme cuál es el equipo principal**.<br>- Cargas actualizadas: L ≈ 25,05 dp; I ≈ 24,25 dp con el recorte 1 (26,25 dp sin él) |
| **2.3** | 2026-10-14 | Incorpora el blueprint v2.3 (validación del modelo de datos de L1a-4, `[VDL]`).<br>- **Agrega DL-16:** la bitácora deja de ser fuente de `UltimaVerificacionUtc`.<br>- **Sección 3.1 nueva («Confirmaciones»):** la regla 3 de la §6.1.1, que el auditor pidió confirmar con firma, y las precisiones de `[DAT]` 6.3 que `[VDL]` confirmó (información, sin decisión) |
| **2.4** | 2026-10-14 | Incorpora el blueprint v2.4 (validación del PR #32, L1a-2 «Reglas de aceptación») y la revisión del auditor `[RA]`.<br>- **Agrega DL-17** (RA-01, Media): el techo de 48 h de INV-6 se mide solo sobre el reloj protegido.<br>- **Sección 3.1:** agrega **C-3** (RA-06: fechas civiles en hora de RD para DL-14 y `aceptarHasta`) y **C-4** (RA-04: procedimiento de GSF ante una sospecha sobre el emisor) |
| **2.5** | 2026-10-14 | **Registra la firma del propietario de DL-07 (a), con el recorte 1, y DL-08 (a)** (sesión de B; aviso `GPOS-NG-Equipos/avisos/B-a-A/2026-10-14-firma-dl07-dl08.md`). Sin otros cambios |
| **2.6** | 2026-10-14 | **Registra la segunda firma del propietario:** DL-14 (a), DL-17 (a), DL-13 (a) y DL-10 (a); aprobados CI-7 / AI-07, AP-06 y AP-02 (falta el nombre del custodio); ADR-82 lo prepara B (aviso `GPOS-NG-Equipos/avisos/B-a-A/2026-10-14-firmas-dl14-dl17-dl13-dl10-y-adr82.md`). Sin otros cambios |
| **2.7** | 2026-10-14 | Agrega **DL-18** (PA-02) y **DL-19** (PA-01), que salen de la revisión de seguridad del PR #33 y de la validación de L1a-4 (persistencia), correcciones 7 y 9, con el blueprint v2.6. La validación las numeraba DL-17 y DL-18, pero DL-17 ya está firmada; el arquitecto-software las renumera. El resto de la hoja no cambia |
| **2.8** | 2026-10-15 | Agrega **DL-20** (AN-01, revisión de seguridad del PR #34, H-17 v2): firma de cada llave del anillo de Data Protection. El resto de la hoja no cambia |
| **2.9** | 2026-10-15 | Agrega **DL-21** (LB-02, revisión de seguridad del PR #35, L1b-1; validación de L1b-1 y blueprint v2.9 §6.2 y §13.1): la hora protegida solo se corrobora con la `emitida` de una licencia con firma Avanzada propia. El resto de la hoja no cambia |
| **2.10** | 2026-10-15 | Precisión de **DL-20**: la firma de las llaves cubre también el anillo de GPOS.Web (PR #37, AW-01, Baja). El costo sube de ≈ 0,4 a ≈ 0,5 dp, y devops necesita también el certificado de la Web con uso `digitalSignature`. El resto de la hoja no cambia |
| **2.11** | 2026-10-15 | Agrega la confirmación **C-5** (sección 3.1), pedida por B antes de activar `UseLicencia` (L1b-2): respaldos, cerrar sesiones, resolver el reloj y sincronizar el espejo de numeración son `Esencial` además del punto 6 de ADR-59. El resto de la hoja no cambia |
| **2.12** | 2026-10-15 | Agrega **DL-22**, que es **de RG-14, no de la licencia**: precisión de D-04 y PA-30 del diseño `datos-t3-12-rg14-2026-10-14.md` (rotación de `gpos_app` sin `KILL` inmediato), según la sección B de `validacion-rg14-lote2b-y-s1-2026-10-15.md`, integrada con la propuesta del auditor (`revision-seguridad-pr39-rg14-lote2b-2026-10-15.md`, sección 5): `KILL` diferido obligatorio de 2 a 6 min a elección del propietario, `ClearPool` en la API y aviso de S4. El resto de la hoja no cambia |

**Fuentes (solo lectura)**
- `[BP2]` = `Solucion GPOS NG\blueprint-licencia-lote2-2026-10-14.md` **v2.4** (arquitecto-software).
- `[DAT]` = `Solucion GPOS NG\datos-t3-12-rg14-2026-10-14.md` v2: D-01 a D-11 y L-01 firmadas; D-04 (ii) sin firma.
- `[SEG]` = `Solucion GPOS NG\revision-seguridad-blueprint-licencia-lote2-2026-10-14.md` (auditor-seguridad): secciones 4, 6 y 9, y «Lectura de diferencias v2» (D.1 a D.7).
- `[VAL]` = `Solucion GPOS NG\validacion-l1a-3-motor-estados-2026-10-14.md` (validación del PR #31, H-3), con la revisión del auditor `revision-seguridad-pr31-motor-estados-2026-10-14.md` (SEG-PR31-01 a 07).
- `[O6]` = `Solucion GPOS NG\inventario-o6-equipo-a-2026-10-14.md` (devops, PC A `DevLab00`).
- `[VDL]` = `Solucion GPOS NG\validacion-datos-l1a4-2026-10-14.md` (validación del modelo de datos de L1a-4).
- `[VAL2]` = `Solucion GPOS NG\validacion-l1a-2-reglas-aceptacion-2026-10-14.md` (validación del PR #32, L1a-2); `[RA]` = `Solucion GPOS NG\revision-seguridad-pr32-reglas-aceptacion-2026-10-14.md` (auditor-seguridad, RA-01 a RA-06).
- `[VAL4]` = `Solucion GPOS NG\validacion-l1a-4-persistencia-2026-10-14.md` (validación de L1a-4, correcciones 6 a 9); `[PA]` = `Solucion GPOS NG\revision-seguridad-pr33-persistencia-2026-10-14.md` (auditor-seguridad, PA-01 a PA-08).
- `[AN]` = `Solucion GPOS NG\revision-seguridad-pr34-anillo-2026-10-15.md` (auditor-seguridad, PR #34, H-17 v2: AN-01 a AN-04).
- `[LB]` = `Solucion GPOS NG\revision-seguridad-pr35-l1b-1-2026-10-15.md` (auditor-seguridad, LB-01 y LB-02); `[VALB]` = `Solucion GPOS NG\validacion-l1b-1-2026-10-15.md` (validación de L1b-1, con la adenda de la decisión del arquitecto).
- `[VR14]` = `Solucion GPOS NG\validacion-rg14-lote2b-y-s1-2026-10-15.md`, sección B (DL-22, de RG-14).
- `[HOJA]` = `GPOS NG\docs\decisiones\2026-10-05-hoja-firma-seguridad.md` (FY-15, CP-4, CP-5 y R-L11 / R-F11).
- ADR-38, 44, 58 a 63, 68 y 81 (`GPOS NG\docs\adr`); ADR-126 (`master`).

**Convención.** *[V]* verificado en la fuente; *[I]* inferido. **dp** = días-persona (USD 300 a 400 cada uno).

**Palabras que se repiten**
- **`s1`**: la llave con la que GSF firma hoy las licencias (nivel Básico). Vive en el chip TPM de un equipo; no se puede copiar, pero quien controle ese equipo la puede **usar**.
- **YubiKeys**: llaves físicas que exigen tocar el dispositivo en cada firma. Todavía no se han comprado.
- **Sello de habilitación**: una marca cifrada que la API pone en cada cuenta habilitada. Sin sello válido, la cuenta no entra.
- **Padrón**: la lista protegida de las cuentas selladas; **el cupo se cuenta desde el padrón**.
- **Estricto / Amplio**: Estricto es el modo de producción, con identidades de mínimo privilegio. Amplio es el de desarrollo, pruebas y DEMO.

---

## 1. Ya firmado hoy (2026-10-14): no se vuelve a preguntar

| # | Decisión del propietario | Qué sustituye o amplía |
|---|---|---|
| **F-1** | **Dos desarrolladores en paralelo** (identidades y licencia), **sin mover el corte de mediados de diciembre** | R-RG14-10 de `[DAT]` |
| **F-2** | **Licencias de pago firmables en nivel Básico** (`s1` en el TPM) hasta que existan las YubiKeys. **Riesgo Medio-Alto aceptado como temporal** | Precisa ADR-62 y AP-05; **amplía P-F1 / FY-15** (texto en 4.4) |
| **F-3** | **Equipo emisor: el equipo principal del propietario, con una cuenta de Windows dedicada solo a firmar.** Sin mini-PC. **Ceremonia de las YubiKeys preparada y sin fecha** | Precisa ADR-61 y Q-19 |

**Lo que exige la primera licencia de pago** (`[BP2]` 10.3 y `[SEG]` 9):
1. Lote 2 en verde: PA-12 y QA-L01 a L17.
2. AI-08.
3. **AI-09 con DL-13 cumplida antes**, incluida la verificación de E-1 por devops, y acta con E-1 a E-15.
4. **DL-14 construida.**
5. **Comparación de `sec`, `lid` y SHA-256 del contenido de la licencia vigente en la solicitud** (SEG-L2-09).
6. **Emisor reproducible y revisado por el auditor** (SEG-L2-08).
7. **AP-03 y AP-04 adaptados.**
8. AP-06.

Ya **no** exige AP-01 ni AP-05.

---

## 2. Resumen

| # | En una línea | Recomendación (con `[SEG]`) | Costo | Firmar antes de |
|---|---|---|---|---|
| DL-01 | El cupo se cuenta desde el padrón, con copia en el disco | **Aprobar con la precisión** | 1,5 dp | 2026-11-06 |
| DL-02 | La API no crea cuentas al arrancar en Estricto **ni en ninguna compilación Release** | **Aprobar con la condición** | 0,75 dp | 2026-11-06 |
| DL-03 | El RNC solo lo cambia el SUPER; la ruta sale tras la fase A de ADR-81 | **Aprobar con la condición** | 1,25 dp + pantalla | 2026-11-13 |
| DL-04 | Eventos en `BitacoraSeguridad`, con una sola DDL | **Aprobar** | 0,5 dp | 2026-10-30 |
| DL-05 | El sello cubre el hash de la contraseña y, en el SUPER, el estado del factor | **Aprobar, obligatoria** | 0,75 dp | 2026-11-06 |
| DL-07 | Reparto entre los dos desarrolladores, con revisión de código del emisor | **FIRMADA 2026-10-14: (a) con el recorte 1** | 0 + revisión | **2026-10-16** |
| DL-08 | La licencia queda construida para el corte | **FIRMADA 2026-10-14: (a)** | 0 | 2026-10-16 |
| DL-09 | Recorte de `autNivel` si hay atraso | **Autorizar con disparador** | −1,75 dp si se usa | 2026-11-13 |
| DL-10 | Respaldo de `s1` frente a la pérdida: (a) `s1r` en TPM o (b) YubiKeys en Básico | **FIRMADA 2026-10-14: (a)** `s1r` en TPM de otro equipo | (a) 0,5 dp · (b) ≈ USD 110 (no FIPS) o ≈ USD 176 (FIPS), a tu elección | 2026-11-20 |
| DL-11 | La caducidad de `s1` la fija la versión con YubiKeys; cofirma en la transición | **Aprobar** | Incluido | 2026-12-01 |
| DL-12 | Fecha de compra y **revisión de la aceptación a más tardar el 2027-03-31** | **Aprobar con la condición** | USD 352 (ya presupuestados) | 2026-10-30 |
| DL-13 | Cuenta diaria sin privilegios de administrador (tampoco `sysadmin` en SQL) y E-1 a E-15 | **FIRMADA 2026-10-14: (a)**, obligatoria antes de AI-09 | 0,75 dp de devops | **Antes de generar `s1`** |
| **DL-14** | Una licencia Básica vence como máximo 200 días después de emitida | **FIRMADA 2026-10-14: (a)** 200 días | 0,35 dp | 2026-11-06 |
| **DL-15** | Un `vence` acortado sin firma Avanzada no puede cortar a una empresa en horas | **Aprobar** | ≈ 0,1 dp | 2026-11-06 |
| **DL-16** | La bitácora deja de ser fuente de la «última verificación correcta» | **Aprobar** | 0 | 2026-11-06 |
| **DL-17** | El techo de 48 h para las fechas de una licencia nueva se mide solo con el reloj protegido | **FIRMADA 2026-10-14: (a)** | ≈ 0,05 dp | Antes de dar por cerrado DL-14 (2026-11-06) |
| **DL-18** | Nunca rige una licencia más vieja que la última atestiguada con MAC | **Aprobar** | ≈ 0,1 dp | Antes de unir la corrección 7 de L1a-4 |
| **DL-19** | Sin ninguna lectura correcta de la huella durante más de máx(`graciaDias`, 72 h), cuenta como entorno distinto | **Aprobar** | ≈ 0,1 dp | Antes de unir la corrección 9 de L1a-4 |
| **DL-20** | Cada llave del anillo de Data Protection va firmada por el servidor (API y Web) | **Aprobar** | ≈ 0,5 dp + devops | Antes del perfil Avanzado o de la primera licencia de pago |
| **DL-21** | La hora protegida solo se corrobora con la `emitida` de una licencia con firma Avanzada | **Aprobar** (conviene firmarla junto con DL-18 y DL-19) | 0 (sin costo de desarrollo; ver la consecuencia) | Antes de unir el cableado de L1b-2 |
| **DL-22** *(RG-14)* | Rotar la credencial de la API sin cortar sesiones en el acto (`KILL` diferido de 2 a 6 min, a tu elección; `ClearPool` y S4; inmediato con `--urgente`) | **Aprobar** | ≈ 0,2 dp | Antes de unir la rotación de `credencial-app` |

*DL-06 está retirada: la sustituye F-2.*

**Recomendación de conjunto: Aprobar con observaciones.** El auditor dictaminó **Aprobado con observaciones** en la lectura de diferencias (D.7). No queda ningún hallazgo Crítico ni Alto. Las observaciones abiertas (SEG-L2-25, SEG-L2-24, los verbos provisionales, la separación de dispositivos y cinco inconsistencias documentales) no bloquean la firma y están recogidas en esta hoja.

**Calendario** (cifras de `[BP2]` 11.2 y 11.4):

| Desarrollador | Centro | Peor caso (+35 %) | Capacidad |
|---|---|---|---|
| L (licencia) | ≈ 25,05 dp | ≈ 33,8 dp | 34,4 dp |
| I (identidades), **con el recorte 1 anticipado** | **≈ 24,25 dp** | ≈ 32,7 dp | 34,4 dp |
| I (identidades), sin el recorte 1 | ≈ 26,25 dp | **≈ 35,4 dp: se pasa en unos 1,0 dp** | 34,4 dp |

*(v2.2: la validación del PR #31 suma unos 0,75 dp a L y 0,05 dp a I, más 0,1 dp si se firma DL-15. Con +35 %, **L queda con solo unos 0,6 dp de margen**: el orquestador lo vigila en H-2.)*

**Recomendación explícita: adelantar desde ya el recorte 1.** El tablero, el CSV de pagos y la subida a Drive del emisor pasan a enero. No requiere firma. Su costo funcional es bajo: el tablero de reemisión solo hace falta para AP-05, que no tiene fecha, y hasta enero la lista sale de una consulta sobre el registro, que ya marca el nivel. La licencia completa suma unos 61,7 dp entre todos los roles, unos USD 18 500 a 24 700.

---

## 3. Las decisiones, una por una

### DL-01 · El cupo se cuenta desde el padrón

**Qué se decide.** El sello impide ampliar la licencia insertando usuarios por SQL. Hacía falta cerrar dos caminos que `[SEG]` encontró:
- con el padrón de la v1, el cupo se seguía contando con columnas que se editan por SQL (SEG-L2-01, Alta);
- restaurar un padrón viejo devolvía cuentas después de una reducción de cupo (SEG-L2-07).

**Recomendación: Aprobar con la precisión:**
- **(a)** El cupo se cuenta desde las entradas no SUPER del padrón verificado. Cada entrada guarda el nivel, el padrón se actualiza por diferencias y solo con acciones de la API, y una fila borrada o alterada sigue contando hasta que el SUPER la purgue.
- **(b)** Hay una copia completa del padrón en el archivo `Licencia\padron` del disco, separado de `estado`, y vale la versión mayor que verifique. El blueprint v2 agrega una mejora: el disco nunca adelanta a la base.
- Mientras no esté la fase A de ADR-81, la purga y la legitimación se hacen con los verbos provisionales de `GPOS.Migracion` (anexo B).

`[SEG]` D.1: incorporada; cierra SEG-L2-01.

| Opción | Consecuencia |
|---|---|
| **(a) + (b) (recomendada)** | Cierra SH-1 y sus variantes. Una fila borrada por error ocupa cupo hasta que GSF la purgue. Quien solo tiene acceso a SQL no puede retroceder el padrón; un administrador de Windows sí (residual de CP-4) |
| (c) Padrón de la v1 | Rechazado por el auditor |
| (d) Sin padrón | El sello no cumple su propósito |

**Costo:** 1,5 dp (SL). Precisa ADR-58, punto 9. Va en ADR-83.

`[ ] Aprobar (a)+(b)`   `[ ] Otra: ____`   `[ ] Aplazar`

---

### DL-02 · La API no crea cuentas al arrancar (Estricto y Release)

**Qué se decide.** Hoy, borrar los SUPER por SQL y reiniciar fabrica un SUPER (SH-3). Además, Amplio es solo una clave de configuración (SEG-L2-05).

**Recomendación: Aprobar con la condición:**
- en una compilación Release ningún modo sella ni crea cuentas al arrancar: lo hace solo `GPOS.Migracion sistema`, también desde el instalador del DEMO;
- con una licencia `Produccion` o `Beta`, la API no arranca en Amplio;
- la creación automática queda solo en `Debug`.

| Opción | Consecuencia |
|---|---|
| **(a) Con la condición de Release (recomendada)** | Cierra SH-3 también frente a un cambio de configuración. El instalador del DEMO llama a `GPOS.Migracion sistema`. Una instalación Beta tiene que estar en Estricto |
| (b) Solo en Estricto | Amplio queda como un interruptor de la licencia (contra ADR-60, punto 6) |

**Costo:** 0,75 dp. Va en ADR-83.

`[ ] Aprobar (a)`   `[ ] Otra: ____`   `[ ] Aplazar`

---

### DL-03 · El RNC de la empresa solo lo cambia el SUPER

**Qué se decide.** La regla firmada NV-07 (ADR-59) solo da transición si el cambio de RNC lo hizo el SUPER, y hoy el ADMIN también lo edita. Se propone una ruta solo del SUPER, con motivo y segundo factor, que deja una prueba protegida. El ADMIN recibe el aviso «solo el SUPER puede cambiar el RNC».

**Recomendación: Aprobar con la condición:**
- S-03 (cambiar el RNC) y S-02 (legitimar cuentas) **no se publican hasta que esté unida la fase A de ADR-81**;
- mientras tanto, se usan los verbos provisionales `GPOS.Migracion empresa --cambiar-rnc` y `sellos --legitimar` en el servidor, con motivo y evento crítico (anexo B; `[SEG]` D.2, aceptado);
- S-03 y el verbo son idempotentes, y el cambio solo cuenta cuando el RNC de la empresa ya es el nuevo.
- **Precisión del blueprint v2.2 (P-3, SEG-PR31-01), dentro de lo firmado:**
  - la fila `CambiosRnc` solo da transición frente a **la licencia que ya estaba aceptada cuando se hizo el cambio**, y nunca si la entrada trae un corte con firma Avanzada;
  - S-03 escribe la fila **«del RNC licenciado al actual»**: si la empresa figura en la licencia vigente con otro RNC y ya existe su fila con `RncAnterior` igual al de esa entrada, un nuevo cambio **conserva `RncAnterior` y `CambiadoUtc`** y solo reemplaza `RncNuevo` y el usuario. Así, una cadena A→B→C no deja la empresa `Invalida` ni reinicia el plazo de 30 días (precisión de ADR-59 del 2026-10-08).

| Opción | Consecuencia |
|---|---|
| **(a) Recomendada** | El ADMIN ve el RNC de solo lectura **desde ya**. Hasta la fase A, cambiar el RNC exige al técnico de GSF en el servidor |
| (b) El ADMIN sigue editándolo | La empresa queda `Invalida` sin gracia al cambiar el RNC |
| (c) S-03 sin segundo factor | Rechazada por el auditor |

**Costo:** 1,25 dp (con los verbos provisionales y la prueba de fallo inyectado) más un ajuste de pantalla. Es una precisión de ADR-59 (NV-07).

`[ ] Aprobar (a)`   `[ ] Otra: ____`   `[ ] Aplazar`

---

### DL-04 · Bitácora de la licencia y del sello

**Qué se decide.** `BitacoraSistema` no existe en el código. Los eventos van a `BitacoraSeguridad` (ADR-81: solo inserción, 2 años), con **una sola DDL** del arquitecto de datos, aplicada por `GPOS.Migracion sistema`.

**Recomendación: Aprobar.** `[SEG]` la da por correcta.

| Opción | Consecuencia |
|---|---|
| **(a) `BitacoraSeguridad` con una sola DDL (recomendada)** | Hay que unirla con `BitacoraSistema` cuando llegue |
| (b) Construir ya `BitacoraSistema` | Trabajo sin dueño ni calendario |
| (c) Solo el Visor de eventos | No viaja con los respaldos y se puede borrar |

**Costo:** 0,5 dp. Es una precisión de ADR-81 (punto 12) y de ADR-60 (punto 8).

`[ ] Aprobar (a)`   `[ ] Otra: ____`   `[ ] Aplazar`

---

### DL-05 · El sello cubre la contraseña y el factor (obligatoria)

**Qué se decide.** El sello incluye la huella del hash de la contraseña y, en los SUPER, el estado «factor dado de alta». Con eso no se puede tomar una cuenta sellada cambiando su hash, ni borrar el factor de un SUPER por SQL para dar de alta uno propio (SH-5, SEG-L2-06).

**Recomendación: Aprobar como obligatoria.** El auditor retiró su alternativa del «sello de seguridad» (D-1, de acuerdo; `[SEG]` D.4).

| Opción | Consecuencia |
|---|---|
| **(a) Hash de la contraseña + estado del factor del SUPER (recomendada)** | Se vuelve a sellar en cada cambio de contraseña, en cada hash rehecho al entrar y en el alta o baja del factor |
| (b) No | Rechazada por el auditor |

**Costo:** 0,75 dp. Va en ADR-83.

`[ ] Aprobar (a)`   `[ ] Otra: ____`

---

### DL-07 · Reparto entre los dos desarrolladores

**Qué se decide.** El desarrollador de identidades toma el sello, el anillo H-17 v2, el cambio de RNC y el emisor. Si el desarrollador de la licencia lo hiciera todo, no cabría.

**Recomendación: Aprobar, con tres condiciones:**
1. el desarrollador de identidades no tiene otras tareas hasta el corte (por ejemplo, el segundo PR de H-11);
2. revisión de código del auditor sobre `GPOS.Criptografia` (después de H-2) y sobre el emisor (S9), antes de la primera licencia de pago;
3. **el recorte 1 se adelanta desde ya** (sección 2).

| Opción | L | I | ¿Cabe? |
|---|---|---|---|
| **(a) Reparto propuesto, con el recorte 1 anticipado (recomendada)** | 24,3 dp | 24,1 dp | Sí, con unos 1,6 a 1,9 dp de margen en el peor caso |
| (a') Reparto propuesto, sin recorte | 24,3 dp | 26,1 dp | En el centro sí; en el peor caso I se pasa en unos 0,8 dp |
| (b) Reparto literal | ≈ 38 dp | ≈ 6 dp | No |

`[x] (a), con el recorte 1`, **FIRMADA por el propietario el 2026-10-14** (sección 7). Condiciones: (1) el desarrollador I no tiene otras tareas hasta el corte; (2) revisión de código del auditor-seguridad de `GPOS.Criptografia` y del emisor antes de la primera licencia de pago; (3) recorte 1 adelantado: el tablero, el CSV de pagos y la subida a Drive del emisor pasan a enero.

---

### DL-08 · Calendario: la licencia queda construida para el corte

**Qué se decide.** Registrar que el código de la licencia se completa para el 2026-12-15, en lugar de las fechas de Q-24 y Q-25. Es consecuencia de F-1.

**Recomendación: Aprobar.** El orquestador lo registra con el plan de `[BP2]` 11.3.

| Opción | Consecuencia |
|---|---|
| **(a) Registrar (recomendada)** | Hitos H-1 (10-23), H-2 (11-06), H-3 (11-13) y código completo (12-04) |
| (b) Mantener Q-24 y Q-25 | Contradice F-1 |

`[x] (a)`, **FIRMADA por el propietario el 2026-10-14** (sección 7): hitos H-1 (10-23), H-2 (11-06), H-3 (11-13), código completo (12-04) y corte (12-15).

---

### DL-09 · Recorte de `autNivel` si hay atraso (condicional)

**Qué se decide.** Si el calendario se atrasa, la «autorización de regreso temporal a Básico» sale de esta versión: ahorra 1,75 dp. `[SEG]`: sin objeción.

**Recomendación: autorizarlo ya con un disparador:** el orquestador confirma un atraso de 5 días hábiles o más respecto de H-3. Si se usa, se registra como precisión de ADR-62 (Q-17).

| Opción | Consecuencia |
|---|---|
| **(a) Con el disparador (recomendada)** | Sin demoras de firma en el momento de presión |
| (b) Decidir si llega el atraso | Una firma más en el peor momento |
| (c) No recortar nunca | Se sacrifica otra cosa o el corte |

`[ ] Aprobar (a)`   `[ ] (b)`   `[ ] (c)`

---

### DL-10 · Respaldo de `s1` frente a la pérdida

**Qué se decide.** Con F-2, toda la firma de pago depende de `s1` en un solo equipo. Si ese TPM se pierde (borrado, reinicio del fTPM, reinstalación o falla del equipo), GSF no puede renovar a nadie hasta publicar una versión nueva y que cada cliente la instale (R-B12, Media / Alto). DL-10 cubre **la pérdida**. El **compromiso** de la llave lo acota DL-14. Las opciones están alineadas con `[BP2]` 13.1.

| Opción | Qué es | Consecuencia | Costo |
|---|---|---|---|
| **(a)** `s1r` en TPM | Una segunda llave Básica activa en el TPM de **otro** equipo que **no es de desarrollo** ni ejecuta agentes y cumple E-1 a E-15. La cuenta de `s1r` queda deshabilitada salvo en la prueba trimestral y en una emergencia. El PIN lo custodia otra persona o va en un sobre precintado | Cubre la pérdida. Suma un segundo lugar desde el que se podría falsificar (SEG-L2-11). Hace falta identificar ese equipo [I] | 0,5 dp |
| **(b)** YubiKeys en Básico | `s1` y su reserva en **dos YubiKeys** con PIN y **toque obligatorio** en cada firma, con el proveedor `YubiKeyPiv` y un `kid` de nivel Básico. **Condición del auditor (`[SEG]` D.4):** estas dos nunca se usan para la ceremonia. Las llaves Avanzadas (`lic-a1`, `lic-b1`, `upd-a1`, `upd-b1`) se generan en **4 dispositivos nuevos** que nunca firmaron en Básico ni se conectaron al equipo de uso diario | Cubre la pérdida **y** elimina la firma silenciosa (R-B13): R-B11 + R-B13 bajan a **Bajo-Medio** con DL-14. Si la eliges, **DL-13 pasa de obligatoria a muy recomendada**, y siguen obligatorias E-2, E-3, E-5, E-8, E-11, E-12 y E-14, más PIN y toque «always» y la atestación real en el acta. **Cambia el «TPM» de F-2: requiere tu decisión expresa** | Serie a tu elección: no FIPS, unos **USD 110**, o FIPS, unos **USD 176**; en Básico dan la misma protección. En los dos casos se suman a los USD 352 ya presupuestados para la ceremonia [I: precios de lista] |
| (c) Sin respaldo | Solo el procedimiento de emergencia (AP-03) | Depende de que cada cliente instale una versión nueva dentro de su gracia. R-B12 Media / Alto | 0 |

**Serie de las YubiKeys de (b): la eliges tú en la casilla.** En nivel Básico, la serie no FIPS (unos USD 110) y la FIPS (unos USD 176) dan la misma protección: PIN y toque en cada firma, y atestación. Nada firmado en Básico se presenta como FIPS (Q-21). En la v2 favorecí la FIPS porque «sirve después para la ceremonia», pero con la separación de dispositivos que exige el auditor ese argumento cae: la ceremonia empieza con `piv reset`, que destruiría `s1`, y `s1` hace falta en la transición. La diferencia es de unos USD 66 en total. *Descartado por el auditor:* reutilizar después las de Básico como `upd-*` tras un `piv reset`, porque mezcla el historial de exposición con la llave del manifiesto.
*Descartado por el auditor:* reutilizar después las dos de Básico como `upd-*` tras un `piv reset`. Ahorra unos USD 176, pero mezcla el historial de exposición con la llave del manifiesto.

**Recomendación: (b)**, con la serie que elijas, si aceptas el gasto y el cambio del «TPM» de F-2: es la opción más segura y no exige un segundo equipo. **Si no, (a).**
**Plazo:** antes del 2026-11-20. En (a), `s1r` se genera con acta antes del 2026-11-27.

`[x] (a)`, **FIRMADA por el propietario el 2026-10-14** (sección 7): `s1r` en el TPM de otro equipo que no sea de desarrollo ni ejecute agentes, con la cuenta deshabilitada salvo en la prueba trimestral y en una emergencia, y el PIN custodiado por otra persona o en un sobre precintado.

---

### DL-11 · Cuándo deja de valer `s1`

**Qué se decide.** La fecha de fin de `s1` y de su reserva la fija **la versión que trae las YubiKeys**: la fecha prevista de publicación más 45 días, escrita en el PR de las llaves y corregida si la publicación se retrasa más de 7 días. La reemisión de transición se **cofirma con `s1` y `a1`**, y el archivo cofirmado también cumple DL-14.

**Recomendación: Aprobar.** Ver SEG-L2-24 en el anexo B: el piso tiene que subir aunque alguien cargue primero una copia sin la firma Avanzada.

| Opción | Consecuencia |
|---|---|
| **(a) Versión con YubiKeys + 45 días, con cofirma (recomendada)** | Transición sin cortes |
| (b) Fecha de compilación + 90 días (Q-16, escenario B) | Más exposición sin necesidad |
| (c) Mantener el 2026-12-31 | Rompe la transición si las YubiKeys llegan en 2027 |

**Costo:** dentro de los 0,5 dp de `[BP2]` 10.3. Precisa Q-16 e INV-1. Va en ADR-84.

`[ ] Aprobar (a)`   `[ ] (b)`   `[ ] Otra: ____`

---

### DL-12 · Fecha de compra y caducidad de la aceptación del riesgo

**Qué se decide.** La ceremonia sigue **sin fecha** (F-3). Lo que se fija:
- **la aceptación del riesgo vence el 2027-03-31 como máximo**, o antes, al primer contrato de pago o en la sesión de cierre del corte;
- al vencer sin ceremonia, se vuelve a firmar con la estimación de ese momento, sin detener la emisión;
- la fecha de compra la fijas tú. El auditor la acepta como campo tuyo (`[SEG]` D.1).

**Recomendación: Aprobar.**

| Opción | Consecuencia |
|---|---|
| **(a) Revisión con tope del 2027-03-31 y fecha de compra (recomendada)** | Cumple la condición del auditor sin tocar F-3 |
| (b) Sin fechas | El auditor la rechaza (SEG-L2-13) |

`[ ] Aprobar (a)`, fecha de compra: ____ , fecha de revisión (≤ 2027-03-31): ____
`[ ] (b)`

---

### DL-13 · Cuenta diaria sin privilegios de administrador (obligatoria antes de AI-09)

**Qué se decide.** Si tu cuenta diaria tiene privilegios de administrador, un programa malicioso puede capturar el PIN **una vez** y desde entonces usar `s1` en silencio en cualquier momento (SEG-L2-03). La lectura de diferencias agrega **SEG-L2-25** (Media): en un equipo de desarrollo, «cuenta estándar» no basta si la cuenta diaria:
- es `sysadmin` de una instancia local de SQL Server, desde donde se puede llegar a `SYSTEM` [I]. En la PC A, `DevLab00\lfmen` lo es [V, `[DAT]` 1.1];
- o pertenece a grupos con efecto de administrador, como «Administradores de Hyper-V» y posiblemente `docker-users` [I].

**Recomendación: Aprobar como obligatoria y previa a AI-09**, con E-1 a E-15 (anexo A) y la precisión SEG-L2-25 en E-1. **`s1` no se genera hasta que devops verifique E-1** en el inventario de O-6.

**Respuesta del auditor sobre la viabilidad en un equipo de desarrollo (D-3):** E-1 es viable.
- La cuenta diaria estándar **eleva por operación**, con las credenciales de la cuenta administradora en el escritorio seguro: instalar SQL Server, cargas de trabajo de .NET o MAUI, el instalador del DEMO, servicios y certificados.
- Lo que se prohíbe es trabajar a diario en la cuenta administradora, dejar terminales o agentes elevados y compilar o ejecutar agentes con ella. Las compilaciones con `dotnet` y los agentes no necesitan privilegios de administrador.
- Para las pruebas basta `dbcreator`. Las tareas que exigen `sysadmin` (`crear-lectura`, restauraciones) se hacen con un **inicio de sesión nominal aparte**, solo cuando hace falta.
- Si el inventario muestra que no es viable (por ejemplo, `sysadmin` o Hyper-V permanentes), **la salida es DL-10 (b) o firmar en otro equipo, no relajar E-1**: con `s1` en el TPM, el riesgo volvería a Medio-Alto.

| Opción | Consecuencia |
|---|---|
| **(a) Obligatoria con E-1 (con SEG-L2-25) a E-15 (recomendada)** | Con DL-14 y las condiciones de la sección 1: riesgo **Medio**. Tu cuenta diaria deja de ser `sysadmin` de SQL Server: cambia la forma de trabajar en desarrollo |
| (a') Muy recomendada, **solo si eliges DL-10 (b)** | El toque físico sustituye la barrera de E-1 frente a la firma silenciosa. Riesgo Bajo-Medio |
| (b) Recomendada, sin ser obligatoria, con `s1` en el TPM | El auditor la rechaza (Medio-Alto) |

**Costo:** 0 en dinero; unos 0,75 dp de devops, con el inventario.

`[x] (a)`, **FIRMADA por el propietario el 2026-10-14** (sección 7): obligatoria antes de AI-09, con E-1 a E-15 y SEG-L2-25.

---

### DL-14 · Tope de vigencia de las licencias Básicas

**Qué se decide.** Un archivo **sin firma Avanzada propia** se rechaza (422 `LICENCIA_VIGENCIA_BASICA`) si algún `vence`, de empresa o de módulo, pasa de **`emitida` + 200 días**. El emisor Básico da a los clientes anuales archivos semestrales. Va en los programas del corte (SEG-L2-02, Alta; coincide con mi O-3 de la v1).

**Recomendación: Aprobar.**

| Opción | Consecuencia |
|---|---|
| **(a) 200 días (recomendada)** | Una licencia falsificada vale como máximo unos 7 meses. El cliente anual recibe dos archivos al año mientras dure el Básico |
| (b) 62 días | Acota a unos 2 meses, pero el cliente anual carga un archivo cada mes, sin agente |
| (c) 400 días | Acota poco |
| (d) Sin tope | Rechazada por el auditor; bloquea la primera licencia de pago |

**Costo:** 0,35 dp. Precisa ADR-62 e INV-1. Va en ADR-84. **Para que el tope sea real hace falta DL-17** (RA-01): sin ella, cada carga aceptada adelanta la referencia 48 h. La fecha de `emitida` se toma en hora de RD (C-3).

`[x] (a)`, **FIRMADA por el propietario el 2026-10-14** (sección 7): tope de 200 días.

---

### DL-15 · Un `vence` acortado sin firma Avanzada no puede cortar a una empresa en horas (nueva)

**Qué se decide.** La regla firmada (CW-02) dice que, sin firma Avanzada, no hay corte inmediato: una revocación anticipada pasa por una gracia de al menos 72 h. Pero hoy el motor solo abre la transición si el `vence` nuevo trae una gracia que **ya terminó** ([LIC] 4.1.1). Hay un hueco: un archivo Básico con un `vence` cuya gracia termina **justo después** de la aceptación deja a la empresa operando en ese momento y la corta pocas horas después. Así se rodea CW-02 (H-3 de `[VAL]`, severidad Media). Importa sobre todo si `s1` se compromete o si GSF emite por error un `vence` equivocado.

La propuesta (`[BP2]` 13.1):
- cuando la empresa tenía derecho con la licencia anterior y el tope nuevo es anterior a `mín(fin de la gracia previa, SiguienteCorte(mín(t, emitida + 7 d) + máx(graciaDias, 72 h)))`, el tope efectivo pasa a ser ese mínimo;
- la empresa queda en `EnGracia(Transicion)` desde el tope nuevo.

**Recomendación: Aprobar.** Cierra el hueco a bajo costo y es coherente con lo que ya firmaste en CW-02. GSF sigue pudiendo corregir un `vence` equivocado.

| Opción | Consecuencia |
|---|---|
| **(a) Mínimo de la transición también al acortar (recomendada)** | Un archivo Básico nunca corta antes de unas 72 h y de un corte. Un acortamiento legítimo (fin de contrato) tarda lo mismo que cualquier revocación en Básico (R-B15, Baja / Bajo) |
| (b) Sin firma Avanzada, nunca acortar por debajo del fin previo | Más estricta, pero GSF no podría corregir un `vence` erróneo mientras dure el Básico. *Descartada en `[BP2]`* |
| (c) Mantener el texto literal | El motor sigue como hoy (ya construido así en el PR #31); queda el hueco H-3 |

**Costo:** ≈ 0,1 dp (L1a-3). Hasta la firma, el motor aplica el texto literal. Precisa ADR-59, punto 4.

`[ ] Aprobar (a)`   `[ ] (b)`   `[ ] (c)`

---

### DL-16 · Fuentes de la última verificación correcta de la licencia (nueva)

**Qué se decide.** La licencia guarda la hora de su **última verificación correcta** (`UltimaVerificacionUtc`). Si la licencia se vuelve ilegible, esa marca sirve para calcular la gracia: la API sigue operando hasta 72 h después de la marca. ADR-59, punto 3, y `[LIC]` 4.1.2 nombran la bitácora entre las fuentes de esa marca. El arquitecto de datos propone, y `[VDL]` confirma, quitarla:
- las fuentes pasan a ser la fila `Licencia.Gracias` (con MAC) y el archivo `estado` del disco, y vale **la más antigua**;
- la bitácora **sigue siendo fuente** de las marcas de inicio de la gracia de entorno y de la de retiro.

El motivo es doble. Adelantar la marca ya exige el anillo en las dos fuentes, así que la bitácora no agrega defensa. Y como se escribe con menos frecuencia, solo acortaría la gracia de 72 h sin que haya un ataque. Además, la bitácora todavía no existe (DL-04).

**Recomendación: Aprobar.** Se aparta de la letra del texto firmado, por eso pide firma.

| Opción | Consecuencia |
|---|---|
| **(a) Fila `Licencia.Gracias` y archivo `estado`, la más antigua (recomendada)** | Misma protección; la gracia ante una licencia ilegible no se acorta por error. L1a-4 ya se construye así hasta la firma |
| (b) Mantener la bitácora como tercera fuente, con un evento `LicenciaVerificada` cada 15 minutos | Unas 35 000 filas al año en `BitacoraSeguridad` [I], sin defensa adicional |
| (c) Mantener la bitácora con la cadencia actual | Acorta la gracia de 72 h sin que haya ataque |

**Costo:** 0. Precisa ADR-59, punto 3, y `[LIC]` 4.1.2.

`[ ] Aprobar (a)`   `[ ] (b)`   `[ ] (c)`

---

### DL-17 · El techo de 48 h se mide solo con el reloj protegido (nueva)

**Qué se decide.** Una licencia no se acepta si su fecha de emisión (`emitida`) está más de 48 h en el futuro (INV-6). Hoy ese techo se mide desde **la mayor** entre la hora protegida del equipo y la `emitida` de la licencia vigente, como dice el texto firmado (ADR-62, punto 7, INV-6; `[LIC]` 4.1.3). Eso crea un hueco (RA-01, Media, de diseño):
- cada carga aceptada sube la referencia 48 h para la siguiente;
- quien tenga `s1`, o un lote de archivos firmados con ella para una instalación, puede llevar `emitida` (y con ella el tope de 200 días de DL-14) **tan lejos como cargas haga**, en una sola sesión;
- mientras tanto, las licencias legítimas de GSF darían `ANTERIOR` hasta que la hora real alcance a las falsas.

DL-14 queda anulado en la práctica.

**Recomendación: Aprobar.**
- El techo se mide **solo** sobre la hora protegida, que ya tiene el piso de la fecha de compilación (INV-10) y es monótona.
- La `emitida` vigente se sigue usando solo para evaluar el **estado** de la licencia.
- Un archivo legítimo solo fallaría si el reloj del servidor estuviera atrasado más de 47 h, porque GSF emite con NTP − 1 h. Ese caso ya registra `RelojInconsistente`.

| Opción | Consecuencia |
|---|---|
| **(a) Techo solo sobre la hora protegida, para todos los archivos (recomendada)** | Cierra RA-01: una licencia falsificada no puede adelantarse más de 48 h sobre la hora real. Con el reloj del servidor muy atrasado, una carga legítima se rechaza (falla cerrada) hasta corregir el reloj |
| (b) Techo sobre la hora protegida solo para los archivos sin firma Avanzada propia; los Avanzados siguen con la referencia actual | Más conservadora con lo Avanzado, pero son dos reglas que mantener y probar; el riesgo que se cierra es el del nivel Básico |
| (c) Mantener el texto firmado | DL-14 no acota de verdad lo firmado con una llave Básica comprometida en un cliente que no actualiza |

**Costo:** ≈ 0,05 dp (L1a-2) y un vector de QA de cargas sucesivas con `emitida` creciente. **Cambia el texto firmado de INV-6** (precisión de ADR-62, punto 7, y de `[LIC]` 4.1.3). Según `[RA]`, hay que resolverlo antes de dar por cerrado DL-14 y antes de usar L1 en producción.

`[x] (a)`, **FIRMADA por el propietario el 2026-10-14** (sección 7): techo de 48 h solo sobre la hora protegida, para todos los archivos.

---

### DL-18 · Nunca rige una licencia más vieja que la última atestiguada (nueva)

**Qué se decide.** Hoy, con solo las credenciales de la API (que pueden insertar filas en `Licencias`, por necesidad), se puede hacer que la licencia vigente «no verifique». El sistema vuelve entonces **en silencio a la licencia anterior** y deshace un corte, una baja de empresa o una reducción de cupo (PA-02, Media). La corrección 6 de `[VAL4]` cierra la parte de la fila con la misma `sec` y no necesita firma. Esta decisión cierra el resto. Sea `S` la `sec` máxima atestiguada con MAC (fila `Licencia.SecMax` o archivo `secmax`, sin contar las de llaves todas retiradas):
- **nunca rige una licencia con `sec` menor que `S`**;
- el orden es:
  1. la fila de `Licencias` con esa `sec` que verifica;
  2. si no la hay, la copia del disco (`vigente.gposlic` o `Procesados`) cuyo SHA-256 del contenido coincide con el atestiguado, y se reinserta;
  3. si tampoco la hay, `Ilegible` (72 h, con el tope por empresa) y el evento crítico `FilaLicenciaInvalida`.

Precisa el orden de recuperación firmado en `[LIC]` 4.1.2, que decía primero el historial y después el disco, sin piso de `sec`.

**Recomendación: Aprobar.**

| Opción | Consecuencia |
|---|---|
| **(a) Piso en la `sec` atestiguada con MAC (recomendada)** | Cierra la vuelta silenciosa a una licencia anterior. Si alguien borra la fila y la copia del disco, la instalación pasa a `Ilegible` (72 h y luego solo consulta), lo que es visible y se recupera cargando el archivo |
| (b) La propuesta del auditor: `Ilegible` ante **cualquier** fila de `sec` mayor que no verifique | **Descartada por el arquitecto:** con las credenciales de la API bastaría insertar una fila basura para llevar a toda la instalación a `Ilegible` (denegación de servicio barata). Las filas no atestiguadas se ignoran con el evento |
| (c) Un `DENY INSERT` con un procedimiento de aceptación | Descartada: el procedimiento no puede verificar el JWS (eso se hace en .NET), y las credenciales de la API lo pueden llamar igual |
| (d) Mantener el texto firmado | Queda PA-02: un corte o una reducción de cupo se deshacen sin rastro visible |

**Costo:** ≈ 0,1 dp (L1a-4). Se construye detrás de la firma (corrección 7 de `[VAL4]`), con su prueba.

`[ ] Aprobar (a)`   `[ ] (b)`   `[ ] (d)`

---

### DL-19 · Una huella ilegible por mucho tiempo cuenta como cambio de entorno (nueva)

**Qué se decide.** La licencia compara una huella del servidor SQL para detectar un clon o un traslado (gracia de entorno). `[LIC]` 3.3.1 firma que **«un error no cuenta como cambio de entorno»**. El auditor (PA-01, Media) mostró que eso abre un hueco: un clon cuyo dueño le niega a la API la lectura de la huella opera **sin gracia de entorno y sin límite**. Las correcciones 8 de `[VAL4]` (persistir la huella y no borrar nunca la marca guardada) aplican lo ya firmado y no necesitan firma. Esta decisión agrega el límite:
- si con una licencia vigente **no hubo ninguna lectura correcta de la huella durante más de máx(`graciaDias`, 72 h)**, contado desde la última correcta o desde la primera falla, se trata como **entorno distinto**;
- la gracia de entorno empieza al inicio de las fallas, y se avisa al SUPER.

**Contradice la letra de `[LIC]` 3.3.1**: por eso pide firma. Hasta la firma, solo hay un aviso diario `EntornoLecturaFallida` al SUPER, sin cambio de estado.

**Recomendación: Aprobar.** Un error pasajero sigue sin contar. Solo cuenta uno que dura más que la gracia, y eso basta para cerrar el clon «sin límite» del residual K-LV-06.

| Opción | Consecuencia |
|---|---|
| **(a) Entorno distinto tras máx(`graciaDias`, 72 h) sin lecturas correctas (recomendada)** | Cierra PA-01. Una instalación con los permisos de la huella mal puestos (por ejemplo, PA-47 sin confirmar) entra en gracia de entorno y, si no se corrige, llega a solo consulta. Se ve antes por el aviso diario, y lo corrige el técnico |
| (b) Solo el aviso diario, sin cambio de estado | Respeta la letra firmada, pero el clon sin lecturas de huella opera sin límite |
| (c) Tratar como entorno distinto desde la primera falla | Demasiado estricto: un error pasajero abriría la gracia de entorno |

**Costo:** ≈ 0,1 dp (L1a-4). Se construye detrás de la firma (corrección 9 de `[VAL4]`). Precisa `[LIC]` 3.3.1 y ADR-58, punto 5 («una lectura fallida conserva la última huella y genera una alerta»).

`[ ] Aprobar (a)`   `[ ] (b)`   `[ ] (c)`

---

### DL-20 · Cada llave del anillo de Data Protection va firmada (nueva)

**Qué se decide.** El anillo de Data Protection (H-17 v2) protege todo lo que GPOS NG guarda cifrado o con MAC: el ancla, las filas con MAC de la licencia (`Gracias`, `SecMax`, `PisoNivelFirma`), el reloj protegido H-16 y los secretos. Hoy las llaves del anillo tienen **confidencialidad pero no autenticidad** (AN-01, Media, de diseño). Quien pueda escribir en la carpeta del anillo crea, con las dos llaves públicas (que son legibles por definición), una llave «conforme» que pasa a ser la predeterminada. Pueden hacerlo:
- la identidad de la API, por ejemplo por un error al escribir adjuntos o exportaciones;
- un respaldo manipulado que se restaura;
- un usuario local, si la DACL falla (AN-03).

Desde ese momento puede **falsificar cualquier valor protegido** y **descifrar los secretos nuevos**. El código cumple el texto firmado (CV-05 solo contempla llaves sin proteger o con otro descifrador): el hueco es de diseño.

**Escalón 1, sin firma, se construye ya** (no cambia nada firmado):
- descartar las llaves cuya recuperación no sea la anclada o cuyo principal no esté admitido;
- lista de llaves heredadas con MAC;
- DACL protegida de la carpeta.

**Escalón 2, esta decisión:**
- cada llave nueva lleva una **firma RSA-PSS-SHA256 con la privada del certificado del servidor**, sobre su id, sus fechas y su sobre;
- el anillo **descarta toda llave que no verifique**.

Cierra también AN-04 (reutilizar el sobre de una llave retirada con otro id).

**Alcance (v2.10): la firma cubre también el anillo de GPOS.Web** (PR #37, AW-01 de `revision-seguridad-pr37-anillo-web-2026-10-15.md`, Baja). La Web no tiene ancla con MAC, así que quien escribe en su carpeta (su identidad de servicio, un respaldo restaurado o un administrador) también puede inyectar una llave conforme. El impacto es bajo: una cookie falsificada no da una sesión, porque esta vive en memoria con un id aleatorio, y la antifalsificación ya está mitigada por `SameSite=Strict`. Pero es el mismo hueco y se cierra con el mismo decorador. Mientras tanto basta la DACL de AN-03.

**Recomendación: Aprobar**, antes del perfil Avanzado o de la primera licencia de pago, lo que llegue antes. Sin esta firma, los MAC que protegen la licencia y el reloj dependen solo de la DACL de una carpeta.

| Opción | Consecuencia |
|---|---|
| **(a) Firma RSA-PSS-SHA256 de cada llave (recomendada)** | Cierra AN-01 y AN-04 frente a la identidad de la API, un respaldo manipulado y un usuario local. **No** protege frente a un administrador ni a código que corra como la API (pueden usar la privada del servidor): eso es inevitable y es el residual de CP-4. Requiere que el **certificado del servidor admita `digitalSignature`** (devops) |
| (b) Solo la DACL de la carpeta (ADR-77) | **Descartada por el auditor:** no cubre la identidad de la API ni la restauración de un respaldo, y la DACL hoy no está garantizada (AN-03) |
| (c) Lista de ids de llaves en una tabla de solo inserción | **Descartada:** ata cada lectura de Data Protection a SQL; una caída de la base dejaría a la API sin anillo |
| (d) Un HMAC de las llaves | **Descartada:** no hay ningún secreto fuera del propio anillo, así que sería circular |

**Costo:** ≈ 0,5 dp: 0,4 dp para la API y unos 0,1 dp más para la Web [I], porque reutiliza el decorador y solo agrega su configuración y sus pruebas (desarrollador I, CR). Además, el certificado del servidor **y el de la Web** con uso `digitalSignature` (devops, dentro de la custodia de Q-22). Precisa H-17 v2 y CV-05 (`[PSF]` 4C.3).

`[ ] Aprobar (a)`   `[ ] (b)`

---

### DL-21 · La hora protegida solo se corrobora con una licencia de firma Avanzada (nueva)

**Qué se decide.** El reloj protegido (H-16 v2.1, firmado) puede **avanzar** su hora alta cuando una fuente confiable lo corrobora. H-16 nombra como fuente la `emitida` de la licencia vigente, sin distinguir el nivel de la firma. El auditor (LB-02, Media, de diseño) mostró que eso **vuelve a abrir el techo deslizante que cerró DL-17**, ahora a través del reloj: con `s1` y la administración del servidor, cargas sucesivas con una `emitida` 47 h adelantada mueven la hora protegida, y con ella el techo de INV-6 y el tope de 200 días de DL-14. La propuesta es la opción (a) del auditor y del arquitecto:
- la corroboración por `emitida` **solo vale si la licencia vigente tiene firma Avanzada propia** (la misma definición de INV-5 y CW-02);
- con una licencia solo Básica, incluida una de regreso temporal con `autNivel`, **no se corrobora por `emitida`**;
- la cabecera `Date` que obtenga el agente (L4) **sigue corroborando siempre**;
- la hora de evaluación del estado, máx(hora protegida, `emitida`), no cambia, y DL-17 tampoco.

**Recomendación: Aprobar.** Conviene firmarla **junto con DL-18 y DL-19**: las tres cierran formas de manipular la licencia por la vía de la persistencia y del reloj, y sin DL-21, DL-17 se puede rodear.

| Opción | Consecuencia |
|---|---|
| **(a) Corroborar con `emitida` solo con firma Avanzada propia (recomendada)** | Cierra LB-02 con una sola condición y sin estado nuevo en el reloj. **Costo operativo:** durante todo el corte no hay llaves Avanzadas, así que un salto del reloj de más de 48 h no se corrobora hasta que exista el agente (L4). Es la falla del lado seguro que ya describe el blueprint (6.4) y no afecta el estado de la licencia, que se evalúa con `emitida` |
| (b) Llevar una segunda hora protegida, sin avances corroborados, solo para INV-6 | **Descartada:** dos horas con su persistencia y su recálculo al arrancar; más superficie para el mismo efecto |
| (c) Una variante con reglas por nivel y por fuente | **Descartada:** más compleja de razonar y de probar |
| (d) Mantener el texto de H-16 | Queda LB-02: DL-17 y DL-14 se pueden rodear con `s1` y la administración del servidor |

**Costo:** sin desarrollo adicional (es una condición en el punto de la llamada), más la prueba de QA: tres cargas Básicas con `emitida` +47 h cada una; la tercera da `LICENCIA_FECHA_FUTURA` y la hora protegida no se mueve. Precisa H-16 v2.1. Hasta la firma, L1b-2 se construye con la restricción y se marca «PENDIENTE DE LA FIRMA DE DL-21». Si no se firma, se vuelve al texto literal.

`[ ] Aprobar (a)`   `[ ] (d)`

---

### DL-22 · Rotación de la credencial de la API sin `KILL` inmediato (nueva; **de RG-14, no de la licencia**)

**Qué se decide.** Esta decisión es de las identidades SQL (RG-14), no de la licencia: precisa **D-04 y PA-30** (y T3-03) del diseño `datos-t3-12-rg14-2026-10-14.md`.

Hoy, al rotar la credencial de la API en una base de empresa (`gpos_app_a|b`), se aplican `DENY CONNECT` y `KILL` a la generación anterior, y sus sesiones se cierran en el acto. Bajo carga, el `KILL` puede producir un **error 500** en una venta en curso: la reconexión automática entra con la credencial vieja, y el error 18456 sale en el comando, donde la reapertura automática no lo cubre [I].

Hay dos propuestas que coinciden en lo esencial y en descartar «solo `DENY CONNECT`»: la del arquitecto (`[VR14]`, sección B) y la del auditor (`revision-seguridad-pr39-rg14-lote2b-2026-10-15.md`, sección 5). Integradas:
1. **Rotación normal:** se crea la generación nueva, se escribe la cadena nueva y se aplica `DENY CONNECT` a la anterior de inmediato, **sin `KILL` en el acto**.
2. **`KILL` diferido y obligatorio:** pasado el plazo, `credencial-app` hace `KILL` de lo que quede de la generación anterior. El auditor propone unos 2 minutos y el arquitecto 6. **El plazo lo eliges tú en la casilla, entre 2 y 6 minutos.**
3. **`Connection Lifetime`** en las cadenas de la API, **igual o menor que el plazo**, para que el pool recicle sus conexiones antes del `KILL`.
4. **En la API:** al detectar el 18456 de una empresa, `SqlConnection.ClearPool` de la cadena anterior, para no reutilizar conexiones abiertas con la credencial vieja. Es la propuesta del auditor.
5. **`credencial-app --urgente`** (o `--inmediato`), ante una sospecha de compromiso: `DENY CONNECT` y `KILL` sin espera, con unos pocos 500 transitorios avisados en la salida.
6. **`GPOS.Migracion verificar` (S4)** informa toda sesión abierta de un `gpos_app_*` que no sea el vigente.
7. **Prueba PA-30:** dos rotaciones normales bajo carga sin ningún 500, y ninguna sesión de la generación anterior al vencer el plazo.

Las credenciales de lectura (`rotar-lectura`) no cambian.

**Recomendación: Aprobar** con el `KILL` diferido, `ClearPool` y S4.
- **Plazo:** con `ClearPool`, 2 minutos suelen bastar y acortan la exposición. Si en la prueba PA-30 aparecen 500, se sube hacia 6. Ninguno de los dos extremos tiene riesgo alto.
- La intención firmada (que la generación anterior pierda el acceso) se cumple igual, sin errores visibles para el cajero en una rotación de rutina, y el corte inmediato queda para un compromiso.

| Opción | Consecuencia |
|---|---|
| **(a) `DENY CONNECT` inmediato, `KILL` diferido obligatorio (2 a 6 min), `Connection Lifetime` ≤ plazo, `ClearPool`, S4 y `--urgente` (recomendada)** | Sin 500 en la rotación normal. **Riesgo:** la generación anterior conserva sesiones abiertas durante el plazo elegido (2 a 6 min); ante un compromiso se usa `--urgente` |
| (b) Mantener el `KILL` inmediato (texto firmado) | Cierre en el acto, pero un 500 posible bajo carga en cada rotación; PA-30 obligaría a reabrir en el comando, que es más complejo |
| (c) Solo `DENY CONNECT`, sin `KILL` posterior | **Descartada por el arquitecto y el auditor:** las sesiones de la generación anterior, incluidas las de un atacante, seguirían vivas sin límite, porque el pool las conserva |

**Costo:** ≈ 0,2 dp (desarrollador I): 0,15 de la rotación y unos 0,05 de `ClearPool` y S4 [I]. Hasta la firma, se construye marcado «PENDIENTE DE FIRMA». Si no se firma, se mantiene el `KILL` inmediato.

`[ ] Aprobar (a)`, plazo del `KILL` diferido: `[ ] 2 min`  `[ ] 6 min`  `[ ] otro (entre 2 y 6): ____`   `[ ] (b)`

---

### 3.1 Confirmaciones (precisiones dentro de lo firmado)

**C-1 · Regla 3 de la §6.1.1 de `[BP2]`: las gracias especiales e `Ilegible` terminan en el corte siguiente.** Toda gracia termina en la hora de corte de la empresa, también las especiales y la de licencia ilegible. Eso les suma **hasta 24 h** sobre las 72 h de ADR-59, siempre dentro del tope por empresa (NV-01). El auditor (revisión del PR #31) pidió que constara como firmada.
**Recomendación: confirmar.** Así el corte nunca cae a media jornada de ventas, y el tope por empresa sigue rigiendo. La alternativa (terminar exactamente a las 72 h) puede cortar en plena venta. Es una precisión de ADR-59, punto 2.

`[ ] Confirmo C-1`   `[ ] Prefiero que terminen exactamente a las 72 h`

**C-2 · Precisiones del modelo de datos (`[DAT]` 6.3) que `[VDL]` confirmó.** Son solo información: no requieren decisión y no cambian nada visible.

| # | Precisión | Por qué |
|---|---|---|
| a | `Licencias.AceptadaUtc` separada de `RecibidaUtc`, con la mínima por `sec` en la cadena de licencias anteriores | Una reinserción `RESTAURACION` no rompe la cadena ni la condición de NV-07 |
| b | `Kid` pasa a `Kids` | Un archivo cofirmado (DL-11) tiene dos `kid` |
| c | Índice de «ya aceptado» único sobre (`Sha256Contenido`, `NivelFirma`) con `Resultado = 'A'` | Resuelve SEG-L2-24 sin migrar el índice de una tabla de solo inserción |
| d | `Licencia.SecMax` guarda también el SHA-256 del contenido y los `Kids` | Lo exige `ReglasAceptacion`; coherente con SEG-L2-18 |
| e | `Usuarios.SelloHabilitacion` como `varbinary(512)` | Condición para SL: una prueba que selle la cuenta más larga con los dos cifradores (Data Protection y `CifradorAnillo`) y compruebe que cabe |

Además, `[VDL]` corrige la regla 12 de la §6.1.1 (NV-08 en la cadena): una licencia con todas sus llaves retiradas sigue en la cadena, pero su derecho previo queda acotado por el retiro efectivo. Es una precisión técnica, sin firma.

`[ ] Tomo conocimiento de C-2`

**C-3 · RA-06: las fechas civiles del formato se leen en hora de RD.** Ya lo aplica la validación v2.4 (`[VAL2]`, puntos 3 y 4; `[BP2]` 6.1.2, P-3).
- `aceptarHasta` rige desde las 00:00 de RD de ese día.
- El tope de DL-14 (`emitida` + 200 días) y el de `hasta` + 31 días toman la fecha de `emitida` en hora de RD, igual que `vence`, que es el último día pagado en RD.
- La diferencia con la lectura en UTC es de un día como máximo, y va del lado restrictivo. El emisor usa el mismo criterio.

`[ ] Confirmo C-3`

**C-4 · RA-04: procedimiento de GSF ante una sospecha sobre el equipo emisor (nota, sin decisión).** Una autorización de regreso que acorta la ventana solo surte efecto en la instalación que la recibe. **El cierre real de `s2` es su retiro por el manifiesto de actualización.** Ante una sospecha sobre el emisor, GSF retira `s2` por manifiesto **además** de emitir la autorización que acorta. Se agrega a los procedimientos de AP-03 (precisión de ADR-61, punto 8). Solo importa cuando existan las YubiKeys y el agente.

`[ ] Tomo conocimiento de C-4`

**C-5 · Operaciones esenciales además del punto 6 de ADR-59 (pedida por B antes de activar `UseLicencia`, L1b-2).** El PR #35 marca como `Esencial` cuatro rutas que no figuran de forma literal en ADR-59, punto 6. `Esencial` quiere decir que siguen permitidas cuando la empresa está en solo consulta. Inhabilitar una cuenta (membresías) ya está en el punto 6. Texto para confirmar:

> *«Además de lo del punto 6 de ADR-59, siempre están permitidas (`Esencial`) en solo consulta: respaldos, cerrar las sesiones de una cuenta, resolver el reloj y sincronizar el espejo de numeración.»*

| # | Ruta | Por qué es esencial | Por qué no rodea la licencia |
|---|---|---|---|
| 1 | `POST /api/admin/respaldos` | Conservar la información del cliente (ADR-59, punto 7; lo confirmó el arquitecto) | No crea ni cambia datos de negocio. Límite de 1 cada 10 min por empresa y uno a la vez |
| 2 | Forzar un nuevo inicio de sesión o cerrar las sesiones de una cuenta | Seguridad: cortar una sesión robada o de un empleado que se va | Solo quita acceso; no crea ni cambia datos de negocio |
| 3 | Resolver el reloj (H-16) | Sin resolver el reloj, la instalación puede quedar sin poder operar ni evaluar bien la licencia | Es mantenimiento técnico del reloj protegido; no crea ni cambia datos de negocio |
| 4 | Sincronizar el espejo de numeración | Mantener coherentes las secuencias fiscales | **No consume números** (confirmado); no emite comprobantes |

**Recomendación: confirmar.** Ninguna de las cuatro crea ni cambia datos de negocio ni toma números de comprobante, así que no sirve para seguir vendiendo con la licencia vencida.
**Si se rechaza:** las cuatro pasan a `Operativa` y quedan bloqueadas en solo consulta. Un cliente vencido **no podría respaldar su información**, ni resolver un problema del reloj, ni cortar sesiones. Lo primero choca con el punto 7 de ADR-59 (conservar la información).
**Fuentes:** `validacion-l1b-1-2026-10-15.md` y la validación de B del 2026-10-15 (`GPOS-NG-Equipos/avisos/B-a-A/2026-10-15-validacion-pr32-a-pr37.md`). Es una precisión de ADR-59, punto 6.

`[ ] Confirmo C-5`   `[ ] Rechazo C-5 (las cuatro quedan bloqueadas en solo consulta)`

---

## 4. Pendientes que no son DL: lo que se necesita del propietario

### 4.1 CI-7 / AI-07 · Validación legal de las tres excepciones (antes del 2026-11-16)

Las tres excepciones que la ley exige mantener en solo consulta ([LIC] LV-12):
1. datos personales (Ley 172-13);
2. anular o comunicar secuencias no usadas;
3. restablecer contraseñas y desbloquear cuentas.

**Qué se necesita:** encargar la consulta al asesor legal **esta semana** (quedan 33 días). Si no llega a tiempo, las tres quedan bloqueadas, lo que falla del lado restrictivo.

### 4.2 AP-02 · Custodio suplente

Deja de ser condición mientras no haya `b1`. Con DL-10 (a), otra persona custodia el PIN de `s1r` (o va en un sobre precintado). Con DL-10 (b), conviene que la YubiKey de reserva quede con esa persona. El nombre va en el acta.

### 4.3 AP-03 · Procedimientos adaptados al nivel Básico (antes de la primera licencia de pago)

Devops los redacta contigo y se ensayan una vez con la llave de desarrollo:
1. compromiso de la llave Básica;
2. pérdida de la llave o del equipo;
3. ausencia del titular;
4. uso de la reserva;
5. E-15: nunca reiniciar el fTPM ni borrar el TPM; protocolo antes de actualizar el BIOS; firma de prueba trimestral.

Unas 2 a 3 horas tuyas [I].

### 4.4 AP-04 · Aceptaciones escritas (antes de la primera licencia de pago)

- **CP-4** y **CP-5:** sin cambios (`[HOJA]` 245-246). El residual de CP-4 incluye que el sello no protege los permisos granulares (SEG-L2-04).

- **FY-15-B.** El auditor lo dio por **correcto y completo** (`[SEG]` D.1). Hay un ajuste mío: si eliges DL-10 (b), se reemplazan «TPM» por «YubiKey con toque obligatorio» y el vector principal pasa a requerir el toque físico.

  > *«Amplío mi aceptación de P-F1 (FY-15). Mientras no existan las YubiKeys, GSF firmará también las licencias de pago en Seguridad Básica, con la llave `gsf-lic-s1` en el TPM de mi equipo principal, en una cuenta de Windows dedicada solo a firmar.*
  >
  > *Acepto que, si un programa con privilegios de administrador de ese equipo captura el PIN de la llave, podrá usarla (no copiarla) en cualquier momento, sin abrir la cuenta de firma y sin que yo vea ningún resumen, para firmar licencias de pago para cualquier instalación; y que un programa en la sesión de firma podría mostrarme un resumen y firmar otro contenido. Acepto también que una licencia así no se puede retirar en un cliente que no instale las versiones nuevas, que no hay corte inmediato para los clientes en Básico y que GSF solo la detectará cuando ese cliente pida una renovación.*
  >
  > *Dejan de existir dos mitigaciones de FY-15: el equipo dedicado y la caducidad técnica del 2026-12-31, que no rige mientras no haya llaves Avanzadas en los programas. Las vigencias mensuales nunca fueron una regla técnica.*
  >
  > *Las sustituyen:*
  > - *(1) la cuenta diaria sin privilegios de administrador, que tampoco es `sysadmin` de ninguna instancia SQL local ni pertenece a grupos con efecto de administrador, y las condiciones E-1 a E-15, cumplidas y verificadas antes de generar la llave (DL-13);*
  > - *(2) el tope técnico de 200 días de vigencia para toda licencia sin firma Avanzada (DL-14);*
  > - *(3) el emisor compilado de forma reproducible y revisado;*
  > - *(4) la comparación de la licencia vigente en cada solicitud;*
  > - *(5) la revisión del TPM y la prueba negativa en el acta;*
  > - *(6) se mantienen el PIN de la llave, la confirmación de cada firma y el registro encadenado con ancla enviada desde otro dispositivo.*
  >
  > *Riesgo residual: Medio-Alto mientras falte alguna de las sustituciones (1) a (5); Medio con todas cumplidas. Esta aceptación es temporal y **vence el [fecha de DL-12, no después del 2027-03-31]**, o antes si se reemite en Avanzado (AP-05). Al vencer, se vuelve a firmar con la estimación de ese momento.»*

- **R-L11-B: sustituye a R-L11 mientras se firme en Básico.**

  > **Con DL-10 (a) o (b).** *«Acepto por escrito que, mientras GSF firme las licencias en Seguridad Básica, si se pierden a la vez la llave `gsf-lic-s1` y su llave de reserva (por falla o borrado del TPM, reinicio del fTPM, reinstalación de Windows, pérdida de los equipos o de las YubiKeys), GSF no podrá emitir ni renovar licencias hasta publicar una versión de GPOS NG con una llave nueva y que cada cliente la instale; y que, si eso tarda más que la gracia de cada cliente, esos clientes pasarán a solo consulta. Se mitiga con las dos llaves en lugares distintos, la firma de prueba trimestral de cada una y el procedimiento de emergencia ensayado. Riesgo residual: Bajo.»*
  >
  > **Con DL-10 (c).** *«Acepto por escrito que, mientras GSF firme las licencias en Seguridad Básica, si se pierde la llave `gsf-lic-s1` (por falla o borrado del TPM, reinicio del fTPM, reinstalación de Windows o pérdida del equipo principal), GSF no podrá emitir ni renovar licencias hasta publicar una versión de GPOS NG con una llave nueva y que cada cliente la instale; y que, si eso tarda más que la gracia de cada cliente, esos clientes pasarán a solo consulta. Se mitiga con la firma de prueba trimestral y el procedimiento de emergencia ensayado. Riesgo residual: Medio.»*

`[ ] Confirmo FY-15-B`   `[ ] Corregir: ____`
`[ ] Acepto R-L11-B (con respaldo / sin respaldo)`   `[ ] Acepto CP-4`   `[ ] Acepto CP-5`

### 4.5 AP-06 · Contrato de suscripción (antes del primer cliente)

Debe cubrir:
- el último período;
- la regla (iii);
- que alterar la instalación es un incumplimiento;
- que no se presente la firma Básica como «hardware validado» (Q-21);
- la reemisión al pasar a Avanzado;
- **los dos archivos al año del cliente anual** mientras dure el Básico (DL-14).

Encargarlo con AI-07, al mismo asesor.

### 4.6 Otras acciones del propietario

| Qué | Cuándo |
|---|---|
| **Equipo principal: confirmar cuál es.** `[O6]` revisó la PC A (`DevLab00`): **no cumple E-1** (la cuenta diaria está en `Administradores`, no hay una cuenta administradora aparte, UAC en el nivel 5 y la cuenta es `sysadmin` en `.\SQLEXPRESS`, en `.` y en LocalDB), **ni E-5** (AnyDesk activo), **ni E-10** (BitLocker sin PIN, [I]) **ni E-13** (arranque seguro deshabilitado, `w32time` sin sincronizar). Recomienda **no generar `s1` en la PC A**. Además, según la memoria del proyecto, la PC A es de soporte (sin UPS, de 2016) y el equipo que coordina es el B. **Hace falta que confirmes cuál es el equipo principal** | **Antes de AI-09** |
| **AI-09** (generar la llave Básica con acta E-1 a E-15) | Con DL-10 (b), en las YubiKeys. Con `s1` en TPM: **repetir O-6 en el equipo principal confirmado** antes de generarla |
| Elegir DL-10 (a) o (b). `[O6]` también **recomienda (b)** | Antes del 2026-11-20 |
| Endurecer la PC A de todos modos (E-1: cuenta estándar, `dbcreator`, un inicio de sesión SQL nominal aparte con permisos mínimos, quitar AnyDesk) | Recomendado por `[O6]` como buena práctica, no como paso previo a AI-09: unos 0,75 dp y de 5 a 15 min por semana |
| Custodia de los certificados de H-17 v2 (Q-22) | Antes del 2026-11-02 |
| `contained database authentication` en la PC A | Antes de PA-12 |
| Quién registra ADR-82 en `master` | Antes de unir el lote 1 |

---

## 5. Observaciones del Maestro

| # | Observación | Severidad | Cómo queda |
|---|---|---|---|
| O-1 | El texto de FY-15 se apoyaba en mitigaciones que ya no existen | Media | Resuelta con FY-15-B (el auditor lo aprueba) |
| O-2 | Si se usa DL-09, contradice la precisión Q-17 de ADR-62 | Baja | Se registra como precisión si se usa |
| ~~O-3~~ | *Pasó a DL-14* | — | — |
| **O-5** | **Calendario.** Sin el recorte 1, el desarrollador I se pasa en unos 0,8 dp en el peor caso (`[SEG]` D.6.5) | Media | **Adelantar el recorte 1** (DL-07 (a)). El orquestador vigila H-2 |
| **O-6** | **Resultado del inventario (`[O6]`):** la PC A no cumple E-1, E-5, E-10 ni E-13, y no está confirmado que sea el equipo principal. E-1 sería viable allí (no hay Hyper-V, Docker ni WSL; `dbcreator` y `dbo` cubren el desarrollo), pero aun así no es un buen emisor | Media | **Que confirmes el equipo principal y elijas DL-10 (b)**, como recomiendan `[O6]` y esta hoja. Si eliges `s1` en TPM, se repite O-6 en el equipo elegido antes de AI-09. Pendientes para el auditor: LocalDB (excepción o borrado) y validar el inicio de sesión nominal `lm_dba` con permisos mínimos |
| O-7 | `[BP2]` todavía tiene que agregar SEG-L2-24 (§5.2, §9.2), la precisión de E-1 (§10.6) y, según tu elección, unificar la serie de DL-10 (b) | Baja | Arquitecto-software (`[SEG]` D.6) |
| O-8 | ADR-126: las fuentes NTP del emisor van en su configuración; las llaves y la caducidad, en los programas | Baja | En ADR-84 |

---

## 6. Discrepancias con el auditor y su resolución

| # | Tema | Resolución tras la lectura de diferencias |
|---|---|---|
| **D-1** | DL-05: ¿el «sello de seguridad» basta en lugar del hash? | **Cerrada: de acuerdo.** El auditor retiró su alternativa: un `sysadmin` que cambia el hash por SQL deja intacto ese valor. Rige el hash más el estado del factor del SUPER |
| **D-2** | YubiKeys en Básico en lugar del TPM | **De acuerdo en el fondo, con la condición del auditor:** dispositivos distintos para Básico y para la ceremonia (4 nuevos para `lic-a1`, `lic-b1`, `upd-a1` y `upd-b1`). Lo que yo decía de que «después sirven para la ceremonia sin otra compra» **queda retirado**. La serie (no FIPS, unos USD 110, o FIPS, unos USD 176) queda como sub-elección del propietario en DL-10 (b): en Básico dan la misma protección. Si se elige, DL-13 pasa a muy recomendada. Ver DL-10 (b) |
| **D-3** | ¿Es viable E-1 en un equipo de desarrollo? | **Respuesta del auditor:** viable con elevación por operación. Agrega SEG-L2-25 (sin `sysadmin` de SQL local ni grupos con efecto de administrador). Si el inventario muestra que no es viable, la salida es DL-10 (b) u otro equipo, nunca relajar E-1. Lo acepto |
| **D-4** | La fecha de compra como campo del propietario | **Aceptada por el auditor**: la condición que importa es la caducidad de la aceptación |

---

## 7. Registro de la firma

| Campo | Valor |
|---|---|
| Firmado por | Leonardo Méndez (propietario), en la sesión de B, recibido por el aviso `GPOS-NG-Equipos/avisos/B-a-A/2026-10-14-firma-dl07-dl08.md` |
| Fecha | 2026-10-14 |
| Respuesta literal | «Firmo DL-07 y DL-08 Fijando a los dos desarrolladores en paralelo». Precisión respondida: DL-07 en la variante «(a) con recorte 1» |
| Firmadas | **DL-07 (a) con el recorte 1** (con sus tres condiciones) y **DL-08 (a)** (hitos H-1 10-23, H-2 11-06, H-3 11-13, código completo 12-04 y corte 12-15). **Las demás DL, C-1, C-3 y AP-04 siguen Pendientes de firma** |
| **Segunda firma** (2026-10-14, sesión de B; aviso `GPOS-NG-Equipos/avisos/B-a-A/2026-10-14-firmas-dl14-dl17-dl13-dl10-y-adr82.md`) | **Respuestas literales:**<br>- DL-14 y DL-17: «DL-14 junto con DL-17 (nueva) APROBADO».<br>- DL-13 y DL-10: «DL-13 (cuenta diaria sin privilegios de administrador) y DL-10 (respaldo de s1) APROBADO Según recomendacion». Al preguntarle B, el propietario eligió **DL-10 (a)**.<br>- Pendientes: «Encargar al asesor legal CI-7/AI-07 y AP-06; designar el custodio suplente (AP-02) APROBADO».<br>- ADR-82: «Equipo B, A tiene bastante según parece» |
| Firmadas en la segunda firma | - **DL-14 (a):** tope de 200 días para todo archivo sin firma Avanzada propia.<br>- **DL-17 (a):** el techo de 48 h de INV-6 se mide solo sobre la hora protegida, para todos los archivos.<br>- **DL-13 (a):** obligatoria antes de AI-09, con E-1 a E-15 y SEG-L2-25.<br>- **DL-10 (a):** `s1r` en el TPM de otro equipo que no sea de desarrollo ni ejecute agentes, con las condiciones de la opción (a) y la firma de prueba trimestral |
| Aprobados (pendientes que no son DL) | - Encargar al asesor legal **CI-7 / AI-07** (antes del 2026-11-16) y **AP-06**.<br>- Designar el custodio suplente **AP-02**: **el nombre está pendiente**; va en el acta, no en este documento |
| ADR | - **ADR-82** lo prepara el equipo B.<br>- B ya registró en `master` la precisión de ADR-62, punto 7 (`83d69aa`), y la de ADR-61 (`1e9b651`) |
| Siguen Pendientes de firma | DL-01 a DL-05, DL-09, DL-11, DL-12, DL-15, DL-16, DL-18, DL-19, DL-20, DL-21, DL-22, C-1 (regla 3), C-5, las precisiones P del blueprint y las aceptaciones de AP-04 (FY-15-B, R-L11-B, CP-4 y CP-5). C-3 y C-4, sin cambios |
| Dictamen de seguridad | **Aprobado con observaciones** (`[SEG]`, lectura de diferencias v2, D.7) |

**Si firmas según la recomendación:**
- devops hace el inventario de O-6 y verifica E-1 (con SEG-L2-25) **antes** de generar `s1` (AI-09), o prepara las YubiKeys si eliges DL-10 (b);
- el desarrollador L incorpora DL-14 y SEG-L2-24;
- el desarrollador I construye SL con DL-01 (a)+(b), DL-02 y DL-05, más los verbos provisionales, y **adelanta el recorte 1**;
- el arquitecto-software cierra las inconsistencias de `[SEG]` D.6;
- el documentador registra ADR-82 a 84 a partir de `borradores-adr-082-084-2026-10-14.md`.

**Si rechazas alguna:**
- **DL-01, DL-05, DL-13 o DL-14:** quedan abiertos hallazgos del auditor, y la primera licencia de pago queda bloqueada en el caso de DL-13 y DL-14;
- **DL-03:** hay que redactar otra prueba de NV-07;
- **DL-07:** otro reparto, o el emisor pasa a enero;
- **DL-10 (c):** R-B12 queda Media / Alto, aceptado con R-L11-B «sin respaldo».
- **DL-15:** queda el hueco H-3 (un archivo Básico puede cortar en horas), aceptado de forma expresa.
- **DL-16:** la bitácora sigue como fuente de la última verificación y hay que construir la escritura periódica (opción (b) o (c)).
- **DL-17:** queda RA-01: DL-14 no acota de verdad lo firmado con una llave Básica comprometida.
- **DL-18:** queda PA-02: con las credenciales de la API se puede volver en silencio a una licencia anterior.
- **DL-19:** queda PA-01: un clon que niega la lectura de la huella opera sin límite; solo hay aviso diario.
- **DL-20:** queda AN-01: quien escribe en la carpeta del anillo puede falsificar los valores protegidos; solo el escalón 1 y la DACL.
- **DL-21:** queda LB-02: con `s1` y la administración del servidor, la corroboración por `emitida` rodea DL-17 y DL-14; se vuelve al texto literal de H-16.
- **DL-22 (RG-14):** se mantiene el `KILL` inmediato en cada rotación, con un 500 posible bajo carga; PA-30 exige reabrir en el comando.

---

## Anexo A · Condiciones E-1 a E-15 del equipo y la cuenta de firma (resumen de `[SEG]` §6 y D.4)

Las verifica devops contigo y quedan en el acta de AI-09 **antes de generar `s1`**.

| # | Condición |
|---|---|
| **E-1** | **Cuenta diaria estándar** y cuenta administradora aparte, solo para mantenimiento: nunca para navegar, leer correo, compilar ni ejecutar agentes, y sin terminales elevados permanentes. UAC en «notificar siempre»; la cuenta diaria **eleva por operación** con las credenciales en el escritorio seguro. **SEG-L2-25:** la cuenta diaria **no es `sysadmin` de ninguna instancia SQL local** (`dbcreator` para las pruebas `GPOS_TEST_*`; un **inicio de sesión nominal aparte**, usado solo cuando hace falta, para `crear-lectura`, restauraciones y lo demás que exija `sysadmin`) y **no pertenece a grupos con efecto de administrador** (Administradores de Hyper-V y, según la versión, `docker-users` [I]). **`s1` no se genera hasta que devops lo verifique** (inventario de O-6). **Obligatoria (DL-13)**; muy recomendada si se elige DL-10 (b) |
| E-2 | `gsf-firma`: cuenta local estándar, sin cuenta Microsoft, escritorio remoto, correo, navegador ni sincronización; contraseña de 16 caracteres o más, no guardada en el equipo |
| E-3 | Se entra solo para firmar y se cierra la sesión al terminar |
| E-4 | Firewall: tráfico saliente de `gsf-firma` solo hacia NTP del emisor [I] |
| E-5 | Ninguna herramienta de acceso remoto activa durante la firma |
| E-6 | Llave no exportable; PIN pedido en cada firma (comprobado con dos firmas seguidas), de 8 caracteres alfanuméricos o más, no guardado en el equipo. Con DL-10 (b): PIN y toque «always» y atestación real hasta la raíz de Yubico |
| E-7 | TPM revisado (fabricante, modelo, firmware; TPM-FAIL) y prueba negativa desde la cuenta administradora |
| E-8 | Resumen derivado de los bytes que se firman; verificación tras firmar |
| E-9 | Carpeta de la llave fuera de respaldos, instantáneas y sincronización |
| E-10 | BitLocker con PIN de arranque; clave de recuperación fuera del equipo |
| E-11 | Emisor reproducible, compilado fuera del equipo emisor, con el hash comparado en otro dispositivo e instalado con la cuenta administradora |
| E-12 | Registro encadenado; ancla enviada desde otro dispositivo; copia semanal fuera de Drive |
| E-13 | Arranque seguro, HVCI, Defender con protección contra alteraciones, actualizaciones al día, `w32time` confiable |
| E-14 | Auditoría de los usos de la llave y comparación mensual con el registro [I] |
| E-15 | Nunca reiniciar el fTPM ni borrar el TPM; protocolo de BIOS; firma de prueba trimestral |

**Costo:** 0 en dinero, unos 0,75 dp de devops.

## Anexo B · Hallazgos que se resuelven al construir (sin firma)

| Hallazgo | Qué se hace | Dónde |
|---|---|---|
| SEG-L2-04 (Media) | SH-2 baja de Alta a Media; el sello no protege los permisos granulares (residual de CP-4) | `[BP2]` §2.2, `[DAT]` 6.2 |
| SEG-L2-08 / 09 (Media) | Emisor reproducible y revisado; `SecVigente`, `LidVigente` y `Sha256ContenidoVigente` en la solicitud, comparados por el emisor | Sección 1 |
| **Verbos provisionales** (`[SEG]` D.2, Baja) | `GPOS.Migracion empresa --cambiar-rnc`, `sellos --legitimar` y `sellos --purgar` mientras no esté la fase A de ADR-81:<br>- cada uso deja un **evento crítico** con el SID y la cuenta de Windows, el equipo y el motivo, y se muestra al SUPER en su siguiente inicio de sesión;<br>- se niegan a ejecutarse si el anillo no verifica `Licencia.InstalacionId`;<br>- después de la fase A quedan solo como **vía fuera de banda** (como la vía (b) de ADR-81, punto 7), y con el perfil Avanzada exigen la autorización firmada por GSF (b+) | SL y RN; ADR-83 |
| SEG-L2-14 (Baja) | Ancla desde otro dispositivo; sin escritura en carpetas sincronizadas | E-12 |
| SEG-L2-15 (Baja) | L-08 solo para el SUPER | L1b |
| SEG-L2-16 (Baja) | S-03 y el verbo idempotentes, con prueba de fallo inyectado | DL-03 |
| SEG-L2-17 (Baja) | El sello se comprueba antes que la contraseña, con hash ficticio | SL |
| **SEG-L2-18 (Baja), como quedó en `[BP2]`** | **Identidad de «ya aceptado» por el SHA-256 del contenido** (`Sha256Contenido`, `[BP2]` §5.2), no del archivo, porque el archivo es maleable por la firma y por la envoltura JSON. No se agrega la regla de `s` bajo. El vector de la firma maleada que devuelve el mismo contenido queda en L1a-1 | L1a-1, L1a-2 |
| **SEG-L2-24 (Baja, nuevo)** | Con la identidad por contenido, quitar la firma `a1` de un archivo cofirmado y cargar primero esa copia impediría subir el piso. Remedio: un archivo con contenido ya aceptado que trae una **firma verificada de nivel superior** no se descarta como «ya aceptado»: se procesa para recalcular el piso y se registra como carga nueva. El índice (`Sha256Contenido`, `NivelFirma`) o la regla equivalente la decide el arquitecto de datos. Prueba de QA: copia sin `a1` primero y cofirmada después, y el piso termina en `avanzado`. Antes de la versión con llaves Avanzadas; no afecta al corte. Unos 0,1 dp | L1a-2, L1a-4, datos |
| SEG-L2-19 (Baja) | Resumen desde `entradaFirma`; verificación tras firmar; vectores DER con ceros | EM |
| SEG-L2-20 (Baja) | Caché global del padrón por versión | SL |
| SEG-L2-21 (Inf.) | `ECDsa` de la plataforma; Q-21 se mantiene | L1a-1 |
