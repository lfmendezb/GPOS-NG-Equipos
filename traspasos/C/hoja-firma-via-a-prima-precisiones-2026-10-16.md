# Hoja de firma: precisiones de la vía (a′) que pide la revisión de seguridad (ADR-81, punto 7; ADR-62; ADR-59, punto 6)

**Preparada por:** Arquitecto Maestro (equipo C) · **Fecha:** 2026-10-16 · **Decide y firma:** el propietario (Leonardo Méndez)
**Estado:** **Firmada por el propietario el 2026-10-16** (sesión de C): «Firmo PA-01 (a), PA-02 (a), PA-03 (a), PA-04 (a) y PA-05 (a) según la recomendación: acepto el riesgo residual Medio R-3 con la condición de REQ-E-01 a REQ-E-11 y el procedimiento ante filtración.»
**Ubicación:** fuera de los repositorios, a propósito. Si se firma, el documentador-tecnico la registra en `master` (ver la sección 3).

**Fuentes (solo lectura):**
- Hoja firmada el 2026-10-16: `traspasos/C/hoja-firma-recuperacion-super-2026-10-16.md` (R-COR-01 (D) a R-COR-04; observaciones O-2 y O-3 en las líneas 253-254; R-3 y R-4 en las líneas 225-226).
- Informe del auditor-seguridad: `traspasos/C/revision-seguridad-via-a-prima-2026-10-16.md`, veredicto «Aprobado con observaciones» (SEG-AP-01 a 15, REQ-C-01 a 13, REQ-E-01 a 11).
- Registro en el PR #53: `origin/c/adr-precisiones-2026-10-16:docs/adr/ADR-081.md`, líneas 115-156, y `docs/adr/ADR-059.md`, línea 167.
- `docs/adr/ADR-062.md` en `master`.

---

## 0. Resumen para decidir

La revisión de seguridad aprueba el diseño de (a′), pero encontró que **dos frases de lo firmado no se pueden construir tal como están** y que hay **una precisión de llaves** pendiente. Ninguna cambia lo que usted decidió (la vía D, su orden y la ausencia de correo en la instalación). Cambian **cómo** se construye.

| Punto | Qué se firma | Recomendación | Costo |
|---|---|---|---|
| **PA-01** | Desafío de recuperación en lugar de «token restringido de P-81A-10»; el reemplazo solo nace de ese desafío | Sí, sin abrir sesión al confirmar | 0 sp (es más simple que un token) |
| **PA-02** | `typ` y `aud` por uso en lugar de «el tipo en `crit`» | Sí | ≈ 0,1 sp (prueba en matriz) |
| **PA-03** | Función de llave nueva `aut` (precisión de ADR-62) | Sí | ≈ 0,05 sp núcleo + ≈ 0,1 sp emisor + ceremonia |
| **PA-04** | Tope técnico de vigencia: 4 h (2 h por omisión en el emisor) | Sí (opcional) | 0 |
| **PA-05** | R-3 sube a Media residual: aceptación escrita condicionada a REQ-E-01 a 11 y procedimiento ante filtración | Aceptar | 0 en el núcleo |

T-j2 pasa de ≈ 1,0 sp a **≈ 1,3 sp** en el núcleo (±30 %, inferido por el auditor, informe §7). El calendario no cambia: T-j2 sigue después de T-g, T-j, T-m y T-p.

---

## 1. Puntos a firmar

### PA-01. Sesión restringida → desafío de recuperación, sin JWT (O-3; SEG-AP-02 y SEG-AP-03)

**Qué cambia frente a lo firmado.**
- Firmado (hoja, O-3; registro, ADR-81 PR #53, línea 122): «abre una sesión restringida […] que reutiliza el token restringido de P-81A-10 […]. El token no lleva `otp` en `amr`».
- **Por qué no se puede:** ese token no existe. El alta de hoy ocurre **antes** de emitir cualquier token, con un desafío de Data Protection de 5 min y un solo uso (`DesafiosFactor.cs:25-48`). El único token restringido de P-81A-10 sale **después** del alta y ya lleva `otp` (blueprint v1, §6.3). Crear un JWT de SUPER sin `otp` obliga a excluirlo en varios sitios (`FiltroFactor.cs:26-28` deja pasar las rutas `PermitidaSinFactor` y las anónimas; la introspección de la API de reportes). Esa dispersión es justo la que hace frágil a R-4.
- **Texto nuevo:**
  1. La ruta de (a′) **no emite ningún JWT**. Devuelve un **desafío de recuperación** con su propio propósito de Data Protection (por ejemplo `GPOS.Auth.RecuperacionFactor.v1`), 10 min, un solo uso. **Solo** lo aceptan las dos rutas nuevas de recuperación (QR y confirmación). Ningún esquema de autenticación lo reconoce como portador. R-4 queda cerrado por construcción.
  2. **SEG-AP-03:** el reemplazo de un factor **activo** solo nace de ese desafío. Las guardas de `/login/alta` (409 `ALTA_NO_CORRESPONDE` con el factor activo, `AuthEndpoints.SegundoFactor.cs:31`) y de `/login/factor` **no se tocan**. El desafío normal del inicio de sesión, obtenido solo con la contraseña, **nunca** alcanza el reemplazo. El factor actual vale hasta la confirmación.
  3. Al confirmar, en una sola transacción: secreto nuevo, códigos anteriores borrados, bloqueo del factor limpio, `SelloSeguridad` renovado, sello de habilitación (ADR-83) renovado, `jti` consumido y evento `A` (REQ-C-03).
  4. Al confirmar **no se abre sesión**: se entregan los 10 códigos nuevos y el SUPER inicia sesión por el camino normal (contraseña más el factor nuevo).
- **Correcciones arrastradas del registro (mismas fuentes, sin decisión nueva):**
  - ADR-81 PR #53, línea 121: «comparte el contador de intentos del factor» pasa a «usa el contador de la **contraseña** (CS-5), más un cupo de 3 intentos por `jti` y el cupo `login` por IP» (SEG-AP-07, REQ-C-09 y 10).
  - ADR-59 PR #53, línea 167 («la ruta de la sesión restringida es `Esencial`»): sin token no hay sesión que clasificar. Las rutas de (a′) son **anónimas, sin clase de licencia, como las demás anónimas** (REQ-C-12; la hoja firmada ya decía, §2.3, que «las rutas anónimas no pasan por la licencia»).

**Principio rector.**
- **Qué rompe:** nada construido (T-j2 no existe). Cambia una frase firmada de ADR-81 y la precisión de ADR-59.
- **A quién afecta:** al SUPER que se recupera: después de confirmar tiene que iniciar sesión una vez más (≈ 30 s). Al arquitecto-software (blueprint v4.1).
- **Por qué se justifica:** un token SUPER sin `otp` es el camino por el que (a′) se degradaría a un bypass del segundo factor (Crítico, informe §10). El desafío lo impide por construcción y cuesta menos.
- **Cómo se migra:** no hay datos ni sesiones que migrar.

**Opciones.**
- **(a) Desafío, sin sesión al confirmar (recomendada).** Ningún camino nuevo emite tokens; una prueba de arquitectura lo vigila. 0 sp.
- (b) Desafío, y al confirmar se abre la sesión normal con `ClaveYFactor` por el mismo emisor de `/login/factor`. Riesgo equivalente (SEG-AP-01), pero agrega un camino de emisión que hay que probar; ahorra un inicio de sesión que se hace pocas veces al año.
- (c) *Descartada:* mantener O-3 (JWT sin `otp` con lista blanca). Es la superficie que el auditor señala como frágil.

☒ **(a) Desafío de recuperación, sin JWT y sin sesión al confirmar (recomendada)**
☐ (b) Desafío de recuperación y sesión normal al confirmar
☐ (c) Mantener O-3 como está firmado (no recomendado)

---

### PA-02. Formato común: `typ` y `aud` por uso en lugar del tipo en `crit` (O-2, R-COR-04; SEG-AP-04)

**Qué cambia frente a lo firmado.**
- Firmado (hoja, O-2; registro, ADR-81 PR #53, línea 140): «un solo formato […] con el tipo en un campo `crit`, como `autNivel`».
- **Por qué no se puede:** el verificador **rechaza** `crit` en el encabezado protegido (`origin/c/adr81-fase-a:src/GPOS.Criptografia/Jws/VerificadorJws.cs:260`, verificado). Y `autNivel` no es un artefacto independiente: es un miembro del contenido de la licencia. Ampliar el verificador para admitir `crit` debilitaría la pieza más revisada del sistema.
- **Texto nuevo** (R-COR-04 se mantiene: formato común = esquema y convenciones comunes, **no** un lector permisivo común):
  1. **Un `typ` distinto por uso**, registrado en `FuncionPorTypCompacto` (`VerificadorJws.cs:41-44`): recuperación (a′), restablecimiento (b+) y nodo (punto 11). Los nombres los fija el blueprint v4.1 (el auditor propone `gpos-autorizacion-recuperacion+jws`, `…-restablecer+jws` y `…-nodo+jws`).
  2. **`aud` obligatorio** en el contenido, un valor por uso, comparado por igualdad ordinal.
  3. **Lectores con un conjunto cerrado de miembros:** un miembro desconocido rechaza el artefacto.
  4. Vinculación por uso: (a′) a instalación y usuario; punto 11 al nodo; (b+) a instalación, usuario y equipo.
  5. `crit` **no se usa** en autorizaciones independientes.
  6. **Prueba en matriz:** licencia, `autNivel`, manifiesto, (a′), (b+) y punto 11, cada uno firmado con una llave válida y presentado a cada uno de los otros verificadores, se rechaza.

**Principio rector.**
- **Qué rompe:** nada construido. Corrige una frase de O-2 y de ADR-81.
- **A quién afecta:** al emisor de GSF (emite `typ` y `aud` propios, REQ-E-11) y al arquitecto-software.
- **Por qué se justifica:** los tres artefactos tienen efectos muy distintos ((b+) actúa sin contraseña; el punto 11 deja entrar sin TOTP en un nodo). Si uno se acepta donde no se emitió, una filtración de (a′) valdría como otra cosa.
- **Cómo se migra:** no hay artefactos emitidos todavía.

**Opciones.**
- **(a) `typ` por uso + `aud` + lectores cerrados + matriz (recomendada).** ≈ 0,1 sp.
- (b) Solo `typ` por uso, sin `aud`. Ahorra ≈ 0,02 sp; pierde la defensa en profundidad si un día dos `typ` comparten lector.
- (c) *Descartada:* admitir `crit` en el verificador.

☒ **(a) `typ` y `aud` por uso, lectores cerrados y prueba en matriz (recomendada)**
☐ (b) Solo `typ` por uso
☐ (c) Admitir `crit` (no recomendado)

---

### PA-03. Función de llave propia `aut` para las autorizaciones de identidad (precisión de ADR-62, punto 2; SEG-AP-05)

**Qué cambia frente a lo firmado.**
- ADR-62, punto 2, dice que **ninguna llave se reutiliza entre funciones**; hoy las funciones son `lic` y `upd` (`LlaveGsf.cs:22-31`, verificado), y `autNivel` se firma con llaves `lic`. Lo firmado para (a′) (registro, línea 118) dice «firmado con la llave de GSF del nivel que corresponda», sin decir la función. Si se interpretara como `lic`, **la llave básica de licencias, que vive en el TPM del equipo emisor, podría firmar la toma de una cuenta SUPER**.
- **Texto nuevo (precisión de ADR-62, punto 2):**
  1. Tercera función de llave **`aut`** (kids `gsf-aut-*`), solo para las autorizaciones de identidad: (a′), (b+) y punto 11. `autNivel` sigue con `lic` (es de licencias).
  2. Custodia como en ADR-62: nivel Básico en el TPM del equipo emisor, no exportable y con PIN; Avanzado en YubiKey FIPS 140-3 con PIN y toque.
  3. **Piso por perfil:** en una instalación Avanzada solo vale una llave `aut` de nivel `avanzado` (REQ-C-05).
  4. Las llaves `aut` no tienen `aceptarHasta` (como `upd`; INV-2 lo limita a las básicas de licencias). El paso a Avanzado lo da el perfil de la instalación.
  5. Una firma válida con una llave `lic` o `upd` en una autorización de identidad se rechaza (el verificador ya trata una llave de otra función como desconocida, `VerificadorJws.cs:152-157`, según el informe).

**Principio rector.**
- **Qué rompe:** nada construido. Agrega una función al catálogo de ADR-62 sin cambiar `lic` ni `upd`.
- **A quién afecta:** a GSF: una **ceremonia de llaves** adicional (TPM y YubiKey; cabe en los espacios PIV libres de las YubiKeys de ADR-61, inferido, no verificado) y la publicación de las llaves `aut` en el recurso de producción, que hoy está vacío (SEG-AP-15).
- **Por qué se justifica:** separa el compromiso del equipo que emite licencias del acceso a las cuentas de la plataforma.
- **Cómo se migra:** las llaves se publican en los binarios antes de publicar la vía; sin ellas, en Release la vía no verifica nada (falla cerrada).
- **Costo:** ≈ 0,05 sp en el núcleo; ≈ 0,1 sp en el emisor más la ceremonia, compartidos con (b+) (inferido por el auditor).

**Opciones.**
- **(a) Función `aut` propia (recomendada).**
- (b) *Descartada por el auditor:* reutilizar `lic` exigiendo siempre `avanzado`. Más barata en el emisor, pero contradice el punto 2 de ADR-62 y ata la recuperación al custodio de la YubiKey de licencias.

☒ **(a) Función de llave `aut` propia, con piso por perfil (recomendada)**
☐ (b) Reutilizar `lic` con nivel `avanzado` (no recomendado)

---

### PA-04 (opcional). Tope técnico de vigencia de (a′): 24 h → 4 h, 2 h por omisión en el emisor (SEG-AP-08)

**Qué cambia frente a lo firmado.**
- Firmado (registro, línea 118): «`iat` y `exp` con **24 h como máximo**».
- **Texto nuevo:** `exp − iat` ≤ **4 h**, como **constante del binario** (no configuración); el emisor fija **2 h** por omisión (REQ-E-06); vigencia medida con el reloj protegido, `iat` ≤ ahora + 5 min, y `iat` posterior a la última restauración detectada de `GPOS_SYSDATA` (REQ-C-08).
- **Alcance:** solo (a′). **(b+) conserva sus 24 h firmadas** (punto 7 de ADR-81): exige coordinar un técnico en el servidor del cliente, que puede tardar más.

**Principio rector.**
- **Qué rompe:** nada. Reduce la ventana en que un JWS filtrado del canal de entrega es útil (no hay revocación, PA-05).
- **A quién afecta:** al SUPER que pide la autorización y no la usa en 4 h: debe pedir otra. La hoja firmada prevé usarla «minutos tras la llamada».
- **Por qué se justifica:** 6 veces menos ventana de exposición, costo 0.
- **Cómo se migra:** no aplica.

☒ **(a) Tope de 4 h, 2 h por omisión en el emisor (recomendada)**
☐ (b) Mantener el tope de 24 h, con 2 h por omisión en el emisor
☐ (c) Mantener 24 h sin valor por omisión en el emisor

---

### PA-05. Aceptación escrita de R-3 como Media residual, condicionada a REQ-E-01 a 11, y procedimiento ante filtración (SEG-AP-01 y SEG-AP-08)

**Qué cambia frente a lo firmado.**
- La hoja firmada calificó R-3 en D como **Baja** (línea 225). El auditor la sube a **Media residual**: la sesión restringida acota la sesión, **no el impacto**. Quien tenga la autorización y la contraseña da de alta su propio TOTP y, en el inicio de sesión siguiente, tiene una sesión **SUPER global** completa (impacto crítico, probabilidad baja: necesita la contraseña, un JWS vigente y engañar a la acreditación de GSF).
- El auditor considera que es el mismo riesgo del insider de GSF ya aceptado en (b+) y en A-09, y que no exige una aceptación aparte. **Recomiendo de todos modos aceptarlo por escrito**, porque:
  - la hoja firmada lo presentó como Bajo, y el registro no debe conservar esa calificación;
  - la condición (REQ-E-01 a 11) recae en GSF, fuera del repositorio, y nadie lo revisó todavía (informe §8).
- **No hay revocación** (la instalación no consulta a GSF; retirar una llave para anular un JWS es desproporcionado). Queda un **procedimiento escrito de GSF ante una filtración sospechada** (REQ-E-09): (1) el SUPER legítimo usa la autorización de inmediato, porque el uso la consume; (2) si no puede, otro SUPER aplica la vía (a) apenas esté disponible, o GSF aplica la vía (b); (3) se registra el incidente en el registro de emisiones de GSF (REQ-E-10).
- **Condición de publicación:** (a′) **no se publica** en Release hasta que GSF tenga REQ-E-01 a 11 escritos y aplicados y las llaves `aut` publicadas. La construcción de T-j2 no espera a esto.

**Principio rector.**
- **Qué rompe:** nada. Corrige la calificación de un riesgo y agrega una condición de publicación.
- **A quién afecta:** a GSF (procedimiento de acreditación con doble control, registro de emisiones, tope de 3 emisiones cada 30 días por usuario).
- **Por qué se justifica:** la defensa principal de (a′) está en la emisión, no en la API.
- **Cómo se migra:** no aplica. Costo en el núcleo: 0. En GSF: el procedimiento escrito (≈ 0,05 sp de redacción, inferido) más la operación de cada emisión.

**Texto de la aceptación (si se marca):**
> *«Acepto por escrito que, con la vía (a′), quien obtenga una autorización de recuperación vigente y la contraseña de un SUPER puede tomar la cuenta SUPER completa. Riesgo residual: Medio. Lo acepto con la condición de que GSF cumpla REQ-E-01 a REQ-E-11 antes de publicar la vía, y sabiendo que no hay revocación: ante una filtración sospechada rige el procedimiento escrito de GSF (uso inmediato por el SUPER legítimo, o vías (a) o (b)).»*

☒ **(a) Acepto el riesgo residual Medio R-3 con la condición de REQ-E-01 a 11 y el procedimiento ante filtración (recomendada)**
☐ (b) No lo acepto: (a′) no se publica y queda solo la vía (b) en el caso extremo (la construcción de T-j2 se detiene)

---

## 2. Riesgos y alternativas

- **Si no se firma PA-01 ni PA-02:** T-j2 no se puede construir conforme a lo firmado sin contradecir el código (`crit`) ni crear el token frágil (R-4). Por omisión, un hallazgo que puede degradarse a Crítico impide recomendar el avance (C3).
- **Si no se firma PA-03:** la custodia de licencias pasa a ser también la de las cuentas SUPER.
- **Riesgo residual de todo el paquete:** Medio (R-3, PA-05). Los demás hallazgos del auditor quedan como requisitos de construcción (REQ-C-01 a 13), sin firma: son del blueprint v4.1.
- **Alternativa global descartada:** volver a abrir R-COR-01 y renunciar a (a′). Las observaciones no tocan la decisión de fondo y el auditor la prefiere a B (informe §10).

## 3. Si usted firma / si rechaza

**Si firma:**
1. **Registro:** el PR #53 (`c/adr-precisiones-2026-10-16`) **todavía no está unido**. Lo más barato es corregir en ese mismo PR, antes de unirlo, el texto de ADR-81 (líneas 118, 121, 122 y 140) y de ADR-59 (línea 167), con la cita de esta hoja, y agregar la precisión del punto 2 de ADR-62. Si ya se hubiera unido, el documentador-tecnico agrega un párrafo de precisión en cada ADR.
2. **arquitecto-software:** blueprint v4.1 con T-j2 según REQ-C-01 a 13 y las opciones marcadas (≈ 1,3 sp).
3. **GSF (emisor):** función `aut`, `typ` y `aud` por uso, vigencia por omisión de 2 h, REQ-E-01 a 11 escritos.
4. **auditor-seguridad:** segunda revisión sobre el código de T-j2 antes de recomendar su unión (informe §10).

**Si rechaza** PA-01, PA-02 o PA-03: el arquitecto-software no puede escribir T-j2 sin una alternativa firmada; T-j2 queda **Bloqueado** y el caso extremo sigue cubierto por la vía (b), como hoy.

## 4. Texto sugerido para firmar

> «Firmo PA-01 (a), PA-02 (a), PA-03 (a), PA-04 (a) y PA-05 (a) según la recomendación: acepto el riesgo residual Medio R-3 con la condición de REQ-E-01 a REQ-E-11 y el procedimiento ante filtración.»

Si no quiere el tope de 4 h:
> «Firmo PA-01 (a), PA-02 (a), PA-03 (a), PA-04 (b) y PA-05 (a) según la recomendación.»

**Número de ADR:** no hace falta uno nuevo. Son precisiones de ADR-81 (punto 7 y la nota de R-COR-04), de ADR-62 (punto 2) y de ADR-59 (punto 6, precisión del 2026-10-16).

---

## Supuestos

- El PR #53 no está unido a `master` (según el encargo; no lo verifiqué con `gh`).
- Costos inferidos por el auditor, ±30 %; el de la redacción del procedimiento de GSF es mío.
- Que las YubiKeys de ADR-61 tienen espacio PIV para las llaves `aut` es inferido, no verificado.
- Las citas de código son de `origin/c/adr81-fase-a`. Verifiqué `VerificadorJws.cs:41-44` y `:260` y `LlaveGsf.cs:22-31`; las demás vienen del informe del auditor.

### Cierre
- Estado: Firmada el 2026-10-16: PA-01 a PA-05 en (a)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\hoja-firma-via-a-prima-precisiones-2026-10-16.md`
- Supuestos: los de la sección anterior
- Decisiones candidatas a ADR: precisiones de ADR-81 (punto 7, O-2 y O-3), ADR-62 (punto 2, función `aut`) y ADR-59 (punto 6, rutas anónimas sin clase)
- Entregas a otros agentes: documentador-tecnico → corregir el registro del PR #53 y precisar ADR-62; arquitecto-software → blueprint v4.1 con REQ-C-01 a 13; GSF (emisor) → función `aut`, `typ`/`aud` y REQ-E-01 a 11; auditor-seguridad → segunda revisión del código de T-j2
- Próximo paso recomendado: que el propietario firme PA-01 a PA-05
