# [Informe de Seguridad] Revisión del blueprint «Licencia firmada en el lote 2 de RG-14» (v1, 2026-10-14) antes de la firma de DL-01 a DL-13

- **Fecha:** 2026-10-14. **Autor:** auditor-seguridad (equipo A). **Tipo:** revisión de diseño. No hay código nuevo.
- **Documento revisado:** `blueprint-licencia-lote2-2026-10-14.md` (en adelante `[BP]`, citado como `[BP] §sección:línea`).
- **Apoyo:** `datos-t3-12-rg14-2026-10-14.md` v2 (`[DAT]`); `docs/arquitectura/2026-10-05-licencia-por-vigencia.md` v3.2.5 (`[LIC]`); `docs/decisiones/2026-10-05-hoja-firma-seguridad.md` (`[HOJA]`); `docs/adr/ADR-081.md`.
- **Código contrastado (solo lectura):** el commit que cita `[BP]`, `768f0a61` (`a/h11-p7-candado`), leído con `git show` desde el repositorio `GPOS NG`. No modifiqué código, bases, el blueprint ni la configuración. No compilé ni ejecuté pruebas.
- **Etiquetas:** **[V]** verificado en el código o en el documento citado; **[I]** inferido, por confirmar en el ensayo o en la construcción.
- **Fuera de discusión:** la aceptación escrita del propietario del riesgo Medio-Alto de firmar licencias de pago en nivel Básico con `s1` en el TPM, como medida temporal hasta la ceremonia de las YubiKeys. Este informe no la discute. Evalúa si la estimación es correcta, si las mitigaciones bastan y qué condiciones tienen que ser obligatorias.

---

## 1. Alcance y superficie revisada

| Superficie | Secciones de `[BP]` | Qué se revisó |
|---|---|---|
| Emisión de licencias en nivel Básico con `s1` en el TPM | §9, §10.3, §10.5, §10.6, §13 (DL-10 a DL-13) | Estimación de R-B11 a R-B15, mitigaciones, condiciones del equipo y de la cuenta de firma, criptografía |
| Sello de habilitación y padrón | §2 (SH-1 a SH-8), §6.3, DL-01, DL-02 y DL-05 | Si cierran la repetición del sello, la sesión abierta y la creación de cuentas privilegiadas |
| Rutas nuevas (endpoints autenticados de ADMIN y SUPER) | §5.1 a §5.3 | Autorización, aislamiento entre empresas, segundo factor y atomicidad |
| Requisitos de arquitectura | §8 | Secretos, integridad, configuración y la regla «sin interruptores» |
| Criptografía compatible con FIPS | §3, §8, §9, §10.1 | Algoritmos, módulo del TPM y declaraciones (Q-21) |

**No hay superficie anónima nueva.** Todas las rutas de §5.1 exigen autenticación. Las tareas en segundo plano nuevas son la instantánea de la licencia (60 s) y el importador de la carpeta de entrada.

---

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título | ¿Bloquea la firma de algún DL? |
|---|---|---|---|
| **SEG-L2-01** | **Alta** | El padrón de sellos no cierra la repetición: el cupo se cuenta con las columnas `Inhabilitado` y `Nivel`, que se editan con SQL | **DL-01**, tal como está redactada |
| **SEG-L2-02** | **Alta** | Una licencia Básica no tiene tope de vigencia: una licencia falsificada con `s1` dura hasta un `vence` arbitrario en el cliente que no actualiza los binarios | No bloquea ningún DL. **Bloquea la primera licencia de pago** (DL-14 nueva) |
| **SEG-L2-03** | **Alta** | La premisa del riesgo de R-B13 está incompleta: con la cuenta diaria administradora, un programa malicioso puede usar `s1` fuera de la sesión de firma una vez que captura el PIN [I]. DL-13 no puede quedar como recomendación | **DL-13**, como «recomendada»: tiene que ser obligatoria y previa a AI-09 |
| SEG-L2-04 | Media | SH-2 está sobrestimado: subir el `Nivel` por SQL no eleva la sesión abierta. Los permisos granulares sí cambian por SQL y el sello no los cubre | No |
| SEG-L2-05 | Media | El modo Amplio, que es una clave de configuración, relaja la licencia (sellado automático y creación de cuentas), contra §8 y ADR-60 punto 6 | DL-02 (con condición) |
| SEG-L2-06 | Media | El residual de SH-5 no baja a Bajo con ADR-81, porque ADR-81 no está construido y el estado «factor dado de alta» se puede borrar con SQL | DL-05: tiene que ser obligatoria |
| SEG-L2-07 | Media | Volver atrás el padrón restaura estados anteriores legítimos, incluidas las habilitaciones previas a una reducción de cupo, y solo se avisa | DL-01 (con condición) |
| SEG-L2-08 | Media | La integridad del emisor se apoya en una autocomprobación, que no es un control. Falta definir dónde y cómo se compila | No (condición previa a la primera licencia de pago) |
| SEG-L2-09 | Media | En la práctica no hay detección de firmas hechas fuera del emisor | No (condición previa a la primera licencia de pago) |
| SEG-L2-10 | Media | Riesgos del TPM no tratados: TPM-FAIL, PIN guardado en caché y reinicio del fTPM al actualizar el firmware | No (condición de AI-09) |
| SEG-L2-11 | Media | DL-10 duplica la superficie de R-B11 y no acelera el retiro de `s1` | DL-10 (con condiciones) |
| SEG-L2-12 | Media | S-02 y S-03 exigen el segundo factor de ADR-81, que no está construido | DL-03 (con condición) |
| SEG-L2-13 | Media | La aceptación del riesgo no tiene caducidad ni fecha de revisión | DL-12 (con condición) |
| SEG-L2-14 | Baja | Contradicciones en §10.6: «sin correo ni Drive» frente al ancla por correo y la subida a Drive | No |
| SEG-L2-15 | Baja | L-08 entrega al ADMIN de una empresa la licencia de toda la instalación (las demás empresas, sus RNC y sus cupos) | No |
| SEG-L2-16 | Baja | S-03 escribe en dos bases sin atomicidad | No |
| SEG-L2-17 | Baja | El orden de la comprobación del sello en el inicio de sesión no está fijado; riesgo de oráculo | No |
| SEG-L2-18 | Baja | «Ya aceptado» se calcula sobre los bytes del JWS, que son maleables con ECDSA | No |
| SEG-L2-19 | Baja | La confirmación de la firma tiene que derivarse de los bytes que se firman; falta verificar después de firmar | No |
| SEG-L2-20 | Baja | Costo del padrón por petición: hace falta una caché global por versión | No |
| SEG-L2-21 | Informativa | Criptografía y FIPS: los algoritmos son conformes; el TPM no está validado y Q-21 se mantiene | No |
| SEG-L2-22 | Informativa | Transición más segura con cofirma `s1` + `a1` | No |
| SEG-L2-23 | Informativa | Alternativa barata frente a R-B13: `s1` en una YubiKey no FIPS con toque obligatorio | No |

---

## 3. Checklist OWASP Top 10 (2021), aplicado al diseño

| Categoría | Estado | Referencia |
|---|---|---|
| A01 Control de acceso roto | **Hallazgos**: cupo evadible por SQL (SEG-L2-01), Amplio (SEG-L2-05), L-08 (SEG-L2-15). La autorización por ruta (§5.1) y la clase «falla cerrado» (§5.3) están bien | §2, §5 |
| A02 Fallas criptográficas | **Hallazgos**: maleabilidad (SEG-L2-18) y TPM (SEG-L2-10). ES256, P-256, SHA-256 y Data Protection son correctos (SEG-L2-21) | §3, §9 |
| A03 Inyección | No aplica al diseño: no hay SQL dinámico nuevo. El JSON estricto (`[LIC]` 3.1.1) es correcto | — |
| A04 Diseño inseguro | **Hallazgos**: sin tope de vigencia (SEG-L2-02), premisa de R-B13 (SEG-L2-03), retroceso del padrón (SEG-L2-07), sin caducidad de la aceptación (SEG-L2-13) | §10.5, §10.6 |
| A05 Configuración insegura | **Hallazgo**: `ModoIdentidad = Amplio` es un interruptor de configuración (SEG-L2-05). Las condiciones del equipo emisor quedan incompletas (§6 de este informe) | §8, §10.6 |
| A06 Componentes vulnerables | **Hallazgo**: firmware del TPM (TPM-FAIL, SEG-L2-10). Yubico .NET SDK y `ykman`: se fijan las versiones el día del ensayo (correcto, [I]) | §9.1, §10.1 |
| A07 Fallas de identificación y autenticación | **Hallazgos**: SH-5 y el factor (SEG-L2-06), orden del sello en el inicio de sesión (SEG-L2-17), S-02 y S-03 sin segundo factor construido (SEG-L2-12) | §2, §5 |
| A08 Fallas de integridad de software y datos | **Hallazgos**: integridad del emisor (SEG-L2-08), resumen frente a bytes firmados (SEG-L2-19). Las filas con MAC y el sello son un buen diseño | §2.3, §9.2, §10.6 |
| A09 Fallas de registro y monitoreo | **Hallazgos**: sin detección de firmas fuera del emisor (SEG-L2-09). `BitacoraSeguridad` (DL-04) es correcta | §10.5, C-05 |
| A10 SSRF | No aplica: no hay solicitudes salientes nuevas desde la API. El NTP del emisor va a dos fuentes fijas | — |

**Aislamiento entre tenants (empresas):** S-03 y L-07 actúan sobre la empresa de la ruta y solo los usa el SUPER, lo cual es correcto. Hay una fuga menor en L-08 (SEG-L2-15). La licencia es de instalación, y un ADMIN de cualquier empresa puede cargar un archivo que afecta a todas (L-03). Es aceptable porque solo se aceptan archivos firmados por GSF, pero hay que documentarlo (SEG-L2-15).

**Secretos:** ningún secreto nuevo en la configuración. Las reglas sobre PIN, PUK y llave de gestión (§8, §10.1) son correctas. Hay que prohibir de forma expresa que la contraseña de `gsf-firma` y el PIN de `s1` queden en el mismo equipo (§6 de este informe).

---

## 4. Hallazgos

### SEG-L2-01 · Alta · El padrón de sellos no cierra la repetición: el cupo se cuenta con columnas editables

- **Riesgo.** `[BP]` §2.3 hace que una cuenta «cuente y entre» si el sello verifica, sus campos coinciden y el padrón la contiene. El cupo, en cambio, cuenta «habilitados no SUPER con sello válido y en el padrón» (`[BP]` §2.4:133). «Habilitado» y «no SUPER» salen de las columnas `Inhabilitado` y `Nivel` de la fila, que un `sysadmin` cambia.
  - Si un `sysadmin` marca temporalmente como inhabilitada una cuenta sellada, o le pone otro nivel, la cuenta deja de contar, pero **sigue en el padrón**, porque el padrón solo cambia por la API.
  - Con eso, un ADMIN da de alta otra cuenta por la API dentro del cupo aparente. Después se devuelve la columna a su valor original, y el sello vuelve a coincidir, porque contiene `Inhabilitado = 0` y el nivel original.
  - **Resultado: el cupo se duplica sin rehacer ningún MAC.** Es la misma consecuencia de SH-1 por otro camino.
  - Lo mismo ocurre si se borra la fila y se reinserta, cuando el padrón se mantiene de forma incremental. `[BP]` no dice si el padrón se reconstruye a partir de las filas o se actualiza por diferencias.
- **Evidencia.**
  - El cupo actual cuenta por columnas: `src/GPOS.Core/Sistema/UsuariosService.cs:154` (`otros = … !x.Inhabilitado`), `:163-172` (`consumidos = otros.CountAsync(x => x.Nivel != Super)`) y `:225` [V, `768f0a61`].
  - `[BP]` §2.3:117-120 y §2.4:133 no cambian la base del conteo [V].
- **Remediación (barata: unos 0,25 dp dentro de SL).**
  1. **El consumo se calcula desde el padrón verificado:** cada entrada no SUPER del padrón cuenta, sin importar el valor de las columnas de la fila.
  2. Cada entrada del padrón guarda también el nivel: `Codigo → (huella del sello, Nivel)`. Así la exclusión de los SUPER no depende de la columna.
  3. Solo una acción de la API retira una entrada del padrón: inhabilitar, bajar a SUPER con el SUPER como solicitante, o una purga explícita del SUPER con motivo y segundo factor para las filas que desaparecieron.
  4. Una fila borrada sigue contando mientras su entrada esté en el padrón.
  5. **El padrón se actualiza por diferencias, nunca reconstruyéndolo a partir de las filas.**
  6. Una fila cuyas columnas no coinciden con su sello sigue contando (`CamposNoCoinciden`) y no entra.
- **Prueba de QA:** extender PA-45 con los tres casos: el `UPDATE` temporal de `Inhabilitado`, el de `Nivel` y el borrado seguido de reinserción. En los tres, el alta de otra cuenta tiene que responder 409 `LICENCIA_CUPO_AGOTADO`.
- **Bloquea:** **DL-01 tal como está redactada.** Se firma con la precisión anterior.

### SEG-L2-02 · Alta · Una licencia Básica no tiene tope de vigencia

- **Riesgo.** Si `s1` se compromete (R-B11), quien la use firma una licencia con `vence` arbitrario, por ejemplo dentro de muchos años. El daño queda acotado solo por el retiro efectivo (NV-08), y ese retiro **exige que el cliente instale binarios nuevos**.
  - En el lote 2 no hay agente (L4 queda para después del corte) y la actualización es manual.
  - Un manifiesto Básico no retira llaves de licencia (`[BP]` §10.5:545). **DL-10 no cambia esto:** da disponibilidad, no un retiro más rápido.
  - Por tanto, el cliente que no actualiza conserva la licencia falsificada indefinidamente (`[BP]` §10.5:550).
  - La aceptación firmada en FY-15 se apoyaba, entre otras cosas, en «las vigencias mensuales y la caducidad técnica del 2026-12-31» (`[HOJA]`:131) [V]. Con las precisiones (b) y (c):
    - la caducidad deja de regir (`LlaveBasicaSinRelevo`);
    - las vigencias mensuales nunca fueron una regla técnica: existe la suscripción anual con `vence` igual al último día del período pagado (`[LIC]`:20 y :30) y las invariantes del agregado no ponen tope al `vence` (`[LIC]`:916) [V].
  - **Dos de las cinco mitigaciones de la aceptación firmada ya no existen.**
- **Evidencia:** `[BP]` §10.5:544-550 y :556; `[LIC]`:916 (sin tope de `vence`) y :303 (en cambio, `sec` sí está acotada por `emitida` y el techo de 48 h, así que no se puede envenenar la secuencia); `[HOJA]`:131.
- **Remediación (DL-14 nueva; unos 0,25 dp en L1a-2 más 0,1 dp en el emisor).**
  - **Invariante del verificador para los archivos sin firma Avanzada propia:** cada `vence`, de empresa y de módulo, ≤ `emitida` + **200 días**. Con eso se cubre el refresco semestral del cliente anual (PA-8) con margen [I]. Un `vence` mayor se rechaza al aceptar con 422 (código nuevo, por ejemplo `LICENCIA_VIGENCIA_BASICA`).
  - El emisor en nivel Básico emite al cliente anual archivos semestrales (`vence` = mín(fin del período pagado, `emitida` + 200 días)).
  - Con eso, una licencia falsificada con `s1` vale como máximo unos 7 meses en un cliente que no actualiza, en lugar de hasta un año fijado por el falsificador.
  - *Alternativa más estricta:* 62 días, con emisión mensual para todos mientras dure el nivel Básico. Acota mejor (unos 2 meses), pero obliga a los clientes anuales a cargar un archivo al mes sin agente. *Alternativa más laxa:* 400 días, compatible con un archivo anual. Solo acota el «año fijado por el falsificador».
  - Recomiendo 200 días.
- **Bloquea:** ningún DL concreto. **Es condición de la primera licencia de pago** y del texto adaptado de P-F1 y R-L11 (AP-04): la aceptación tiene que decir qué mitigaciones se retiraron y cuál las sustituye.

### SEG-L2-03 · Alta · La premisa de R-B13 está incompleta; DL-13 tiene que ser obligatoria

- **Riesgo.** La precisión que recibió el propietario («el vector principal es un programa malicioso en el equipo mientras se usa la cuenta de firma») es correcta para un programa malicioso **sin privilegios**. **No lo es para uno con privilegios de administrador**, que es el caso de §10.6 sin la condición 6.
  - El proveedor «Microsoft Platform Crypto Provider» guarda la llave como un *blob* envuelto por el TPM en el perfil de la cuenta (`%LOCALAPPDATA%\Microsoft\Crypto\PCPKSP`, `[BP]` §10.6:571) [I].
  - El *blob* no sirve en otro TPM, pero **en el mismo equipo** un administrador puede leerlo y cargarlo en el TPM desde cualquier sesión y en cualquier momento, si conoce el PIN (el valor de autorización de la llave) [I: comportamiento esperado del TPM 2.0 y del proveedor PCP; se confirma en el ensayo, SEG-L2-10].
  - **Basta con capturar el PIN una vez:** con un registrador de teclas, que exige privilegios o la misma sesión. Desde ese momento, el programa firma en silencio, sin abrir la sesión de `gsf-firma` y sin que el propietario vea ningún resumen.
  - El «PIN en cada firma» protege frente al robo del equipo y frente a un programa sin privilegios de otra cuenta. **No protege frente a un administrador comprometido.**
  - En el equipo principal del propietario además se ejecutan herramientas que lanzan comandos de forma autónoma: compilaciones, paquetes con *scripts* de instalación y agentes de IA que procesan contenido externo. Con la cuenta diaria administradora, todo eso corre con privilegios suficientes para llegar a la llave.
- **Estimación del auditor** (sustituye la de `[BP]` §10.5:556-558 y §10.6:581-583):

  | Escenario | R-B11 y R-B13 juntos (uso indebido de `s1`) |
  |---|---|
  | Como propone `[BP]`, con la cuenta diaria administradora | **Medio-Alto** (coincide con `[BP]`). Probabilidad Baja-Media: un ataque dirigido a la llave no es el caso común del programa malicioso genérico. Impacto Alto: licencias para cualquier instalación, sin vencimiento (SEG-L2-02) y sin detección (SEG-L2-09) |
  | Con DL-13 sola | **Medio-Alto.** Baja la probabilidad, pero el impacto sigue sin acotar |
  | Con DL-13 + DL-14 (tope de vigencia) + SEG-L2-08 + SEG-L2-09 + SEG-L2-10 | **Medio**, igual que lo aceptado en FY-15 |
  | Con `s1` en una YubiKey con toque obligatorio (SEG-L2-23) más DL-14 | Bajo-Medio |

  **La estimación de `[BP]` es correcta en el valor central, pero sobrestima el efecto de DL-13 sola:** la condición 6 baja la probabilidad, no el impacto.
- **Evidencia:** `[BP]` §10.5:558 («No puede extraer la llave del TPM»: es cierto, pero no hace falta extraerla para usarla), §10.6:573 («Recomendado») y §13.1:701.
- **Remediación (sin costo en dinero; unos 0,5 dp de devops ya previstos):**
  1. **DL-13 pasa a ser obligatoria y previa a AI-09** (la generación de `s1`), no solo previa a la primera licencia de pago. Si `s1` se genera mientras la cuenta diaria es administradora, el PIN puede quedar capturado desde el primer día.
  2. El ensayo de AI-09 incluye la prueba negativa de SEG-L2-10, punto 3: intentar usar la llave desde otra cuenta administradora con el PIN correcto. El resultado, cualquiera que sea, queda en el acta y define el texto de la aceptación.
  3. El texto adaptado de P-F1 (AP-04) cambia «mientras se usa la cuenta de firma» por «en cualquier momento, si un programa con privilegios de administrador del equipo captura el PIN».
- **Bloquea:** **DL-13**, si se firma como «recomendada». Se firma como obligatoria.

### SEG-L2-04 · Media · SH-2 está sobrestimado; el sello no cubre los permisos granulares

- **Riesgo.**
  - `[BP]` §2.2:104 afirma que un `UPDATE Nivel = 'ADMIN'` por SQL da permisos de ADMIN a la sesión abierta. **No ocurre así en el código:**
    - las políticas «admin» y «super» leen el nivel del *claim* del token, no de la base;
    - `Evaluar` solo revoca cuando el nivel del token **supera** al de la cuenta.
    - Subir el nivel por SQL no surte efecto hasta un inicio de sesión nuevo, y ahí el sello lo detiene.
  - Sí cambian por SQL, sin token nuevo y en a lo sumo 30 s, los **permisos granulares** (perfiles y excepciones), que se leen de la base en cada petición. El sello no los cubre.
  - Eso no amplía el cupo, pero contradice la lectura amplia de «subir el nivel por SQL no sirve» de `[DAT]` 6.2:949.
- **Evidencia:**
  - `src/GPOS.Api/Program.cs:91-92` («las políticas "admin" y "super" leen el nivel del claim») [V];
  - `src/GPOS.Api/Seguridad/Seguridad.cs:158`, `:177-179` [V];
  - `src/GPOS.Api/Seguridad/RevocacionSesiones.cs:86` [V];
  - `src/GPOS.Api/Seguridad/PermisosServidor.cs:10-26` (caché de 30 s, lectura de la base) [V].
- **Remediación.**
  - **Mantener la verificación del sello por petición** (`[BP]` §6.3:337). Cierra la sesión de una cuenta cuyo sello se invalidó (por ejemplo, la restaurada de SEG-L2-01) y cuesta poco.
  - **Reclasificar SH-2 de Alta a Media** en el blueprint y corregir su justificación.
  - Escribir en el modelo de amenazas (`[DAT]` 6.2) que **el sello protege el cupo, el nivel y la restricción de sucursal, no los permisos granulares**. Frente a un `sysadmin`, los permisos son el residual de CP-4.
  - *Alternativa descartada:* sellar también los permisos. Cada cambio de un perfil obligaría a volver a sellar a todos sus usuarios, y el beneficio para la licencia es nulo.
- **Bloquea:** no.

### SEG-L2-05 · Media · El modo Amplio relaja la licencia

- **Riesgo.**
  - En Amplio, la API sella al arrancar si falta la fila `Licencia.SelloInicial` (`[BP]` §2.5:145, R-S3) y sigue creando cuentas SUPER y ADMIN al arrancar (`[BP]` §2.2:105, «En Amplio sigue como hoy»). Un `sysadmin` que borra `Licencia.SelloInicial` provoca un sellado nuevo **de las cuentas insertadas a mano**.
  - `Amplio` es el valor de una clave de configuración (`GPOS:Seguridad:ModoIdentidad`, `[DAT]` 2.6:267). Que la versión del cliente «no lo lleve» es un punto de la lista PUB-06, no un control técnico (`[DAT]` 2.6:276).
  - Esto contradice dos reglas: «el modo Amplio no relaja la licencia» (`[BP]` §8:395) y «sin interruptores» (ADR-60, punto 6).
  - Explotarlo exige escribir la configuración del servicio, lo que en general requiere ser administrador del equipo de la API: el residual de CP-4. Pero baja mucho la dificultad: cambiar un valor frente a programar contra el anillo.
- **Evidencia:** `[BP]` §2.2:105, §2.5:145, §8:395; `[DAT]` 2.6:267-277.
- **Remediación (unos 0,25 dp en SL):**
  1. **Ningún modo sella ni crea cuentas en la API en una compilación Release.** El DEMO, que se compila en Release, sella con `GPOS.Migracion sistema` desde su instalador.
  2. Además, si la licencia vigente tiene `anillo` `Produccion` o `Beta`, la API no arranca en Amplio, con el evento crítico correspondiente.
  3. La creación de cuentas al arrancar solo existe en `Debug`, como ya hace T3-09.
- **Bloquea:** se firma **DL-02 con esta condición**.

### SEG-L2-06 · Media · SH-5: el residual no baja a Bajo con ADR-81

- **Riesgo.** `[BP]` §2.2:107 deja DL-05 como opcional porque «con ADR-81, el SUPER además tiene el segundo factor… el residual baja a Bajo».
  - ADR-81 está **decidido, no implementado** (`docs/adr/ADR-081.md:59`) [V]. Su fase A puede recortarse si el calendario aprieta (`ADR-081.md`, tabla de fases).
  - Aun construido, el SUPER que no tiene el factor dado de alta lo da de alta en su siguiente inicio de sesión (`ADR-081.md:30`) [V]. Si un `sysadmin` borra la fila de `UsuariosFactor` del SUPER y cambia su `PasswordHash` por uno conocido, quien entre con esa contraseña **da de alta su propio factor** [I: depende de cómo se construya la fase A; el diseño no lo impide].
  - Además, SH-3 en un equipo con una instalación existente crea `GSF` con una clave aleatoria (`src/GPOS.Api/Servicios/Inicializacion.cs:122-129`) [V]. Combinado con el cambio del hash, se obtiene un SUPER controlado sin el anillo.
- **Evidencia:** `[BP]` §2.2:107, §13.1:693; `ADR-081.md:30`, `:59`; `UsuariosService.cs:48` y `:266-279` [V].
- **Remediación (DL-05, unos 0,5 dp ya estimados más 0,25 dp):**
  1. **DL-05 pasa a ser obligatoria.** El sello cubre la huella del `PasswordHash`, o el `SelloSeguridad` de CS-1 (SH-8).
  2. Para los SUPER, el sello cubre además **«factor dado de alta: sí/no»**. Un SUPER sellado con el factor dado de alta cuya fila de factor desaparece no entra. Se restablece solo por la vía (a) o (b) de ADR-81, punto 7.
- **Bloquea:** **DL-05** tiene que firmarse como obligatoria, no como opcional.

### SEG-L2-07 · Media · Volver atrás el padrón restaura estados anteriores, y solo se avisa

- **Riesgo.** `[BP]` §2.3:121 acepta que restaurar un padrón anterior devuelve «un estado anterior legítimo» y se limita a registrar `PadronRetrocedido`.
  - Ese estado respetó el cupo **de su momento**. Si GSF reduce el cupo (un cliente que pasa de 20 a 10 usuarios) y el ADMIN inhabilita cuentas para cumplir, un `sysadmin` restaura el padrón y las filas de antes de la reducción, y las 20 cuentas vuelven a entrar.
  - El aviso no bloquea nada y, sin telemetría (Q-08), GSF no se entera.
- **Evidencia:** `[BP]` §2.3:121.
- **Remediación (unos 0,25 dp):**
  - Guardar **también el padrón completo** (unos 70 KB) en el archivo `estado` del disco (C-03, carpeta con DACL protegida).
  - **Prevalece la versión mayor que verifique**, sea la de la base o la del disco. Un `sysadmin` de SQL sin acceso al sistema de archivos del equipo de la API no puede retroceder el disco.
  - Si la versión de la base es menor, se usa la del disco, se registra `PadronRetrocedido` y se avisa al SUPER.
  - El administrador de Windows sí puede retroceder las dos: es el residual de CP-4.
- **Bloquea:** se firma **DL-01 con esta condición**.

### SEG-L2-08 · Media · La integridad del emisor se apoya en una autocomprobación

- **Riesgo.** `[BP]` §10.6:574 dice que el emisor comprueba su propio SHA-256 al arrancar contra el registro.
  - Un binario alterado omite esa comprobación, y el registro lo escribe la misma cuenta. **No es un control frente a la alteración:** solo detecta corrupción accidental.
  - Tampoco se dice **dónde se compila** el emisor. Si se compila en el equipo de desarrollo o en la cuenta diaria, el hash que queda en el acta es el de lo que se compiló, alterado o no.
  - El emisor y `GPOS.Criptografia` los escribe un desarrollador (DL-07). Hay revisión de seguridad prevista para la API (AI-08, R-E11), pero no para el emisor.
- **Evidencia:** `[BP]` §10.6:574, §4.1:186, §13.1:695.
- **Remediación (unos 0,5 dp de devops y una revisión del auditor):**
  1. **Compilación reproducible** del emisor desde una etiqueta del repositorio privado, en un entorno distinto del equipo emisor. El hash de lo publicado se compara **en un segundo dispositivo** con el del binario instalado. El resultado queda en el acta de AI-09 y se repite en cada actualización del emisor.
  2. El emisor se instala en `Program Files` con la cuenta administradora separada (DL-13). `gsf-firma` no tiene escritura ahí, como ya dice `[BP]`.
  3. **Revisión de código del auditor-seguridad sobre el emisor (EM) y `GPOS.Criptografia`** antes de la primera licencia de pago, con el mismo rango que AI-08.
  4. Quitar de §10.6 la autocomprobación como control, o dejarla escrita como «detección de corrupción accidental».
- **Bloquea:** no. Es condición previa a la primera licencia de pago.

### SEG-L2-09 · Media · En la práctica no se detectan firmas hechas fuera del emisor

- **Riesgo.** `[BP]` §10.6:584 reconoce que una firma hecha fuera del emisor «se detecta solo cuando aparece una licencia que GSF no reconoce». Sin telemetría (Q-08), **no hay ningún mecanismo que haga aparecer esa licencia**.
- **Evidencia:** `[BP]` §10.6:584; §5.2:258 (`SolicitudLicenciaDto` no lleva la licencia vigente).
- **Remediación (unos 0,5 dp):**
  1. `SolicitudLicenciaDto` agrega `SecVigente`, `LidVigente` y el `Sha256` de la licencia vigente, sin secretos.
  2. En cada emisión o renovación, **el emisor compara esos tres datos con su registro**. Una `sec` o un `lid` que no estén en el registro detienen la emisión con la alerta «licencia no emitida por GSF en esta instalación».
  3. El procedimiento de soporte de GSF incluye la misma comparación con L-04 en cada visita.
  4. Con la cuenta administradora separada: activar la auditoría de las operaciones con llaves criptográficas de Windows (eventos de la familia 5058/5061 [I: se confirma la subcategoría en el ensayo]) y comparar cada mes el número de usos de la llave con el registro del emisor. El costo es casi nulo. Un administrador comprometido puede borrar el registro de eventos, así que es una detección débil pero gratuita.
- **Bloquea:** no. Es condición previa a la primera licencia de pago.

### SEG-L2-10 · Media · Riesgos del TPM no tratados

- **Riesgo.**
  - (a) **TPM-FAIL** (CVE-2019-11090 en el fTPM de Intel y CVE-2019-16863 en los ST33 de STMicroelectronics): una filtración por tiempos en las firmas ECDSA permitía **recuperar la llave privada** del TPM observando firmas. Eso anula «no exportable». La condición 9 de `[BP]` §10.6:576 lo menciona solo de forma genérica.
  - (b) **PIN guardado en caché:** si el proveedor guarda la autorización mientras dura el *handle* de la llave, dos firmas seguidas no piden el PIN dos veces [I].
  - (c) **Pérdida silenciosa (R-B12):** en algunos equipos con fTPM de AMD, una actualización del BIOS o UEFI ofrece o provoca el reinicio del fTPM. Borrar el TPM desde la seguridad de Windows, eliminar el perfil de `gsf-firma` o reinstalar Windows destruyen `s1`.
- **Remediación (unos 0,25 dp de devops, dentro del acta de AI-09):**
  1. El acta registra el fabricante, el modelo y la versión del firmware del TPM, y su comparación con los avisos de TPM-FAIL y con los avisos posteriores del fabricante. Un TPM afectado sin firmware corregido **no se usa para `s1`**.
  2. El emisor abre y cierra el *handle* de la llave en cada firma. El ensayo comprueba que **dos firmas seguidas piden el PIN dos veces**, como el paso 10 de la ceremonia de las YubiKeys.
  3. **Prueba negativa en el ensayo:** con la cuenta administradora, intentar usar la llave de `gsf-firma` con el PIN correcto. El resultado alimenta el texto de la aceptación (SEG-L2-03).
  4. AP-03 adaptado incluye: no aceptar nunca un «reinicio del fTPM» o un «borrado del TPM»; suspender BitLocker y revisar el aviso del fabricante antes de cada actualización del BIOS; y una firma trimestral de prueba con `s1` (y con `s1r`) para detectar una pérdida antes de necesitar la llave.
  5. PIN de `s1`: al menos 8 caracteres alfanuméricos, que no se usen en ningún otro lugar y que no se guarden en el mismo equipo.
- **Bloquea:** no. Es condición de AI-09.

### SEG-L2-11 · Media · DL-10 duplica la superficie de R-B11 y no acelera el retiro

- **Riesgo.**
  - `s1r` es **activa** en los binarios. Comprometer cualquiera de las dos llaves basta para falsificar licencias, así que la probabilidad de R-B11 crece con la calidad del segundo equipo. El Supuesto 8 de `[BP]` (:733) no dice qué equipo será.
  - Si es un equipo de desarrollo que ejecuta agentes y compilaciones, empeora R-B11 más de lo que mejora R-B12.
  - Además, `[BP]` §10.5:545 dice que DL-10 «cubre» INV-3. Solo cubre la disponibilidad: retirar `s1` sigue exigiendo binarios.
- **Remediación:** se firma DL-10 con estas condiciones:
  1. El segundo equipo **no es un equipo de desarrollo** ni ejecuta agentes.
  2. Cumple las condiciones de §6 de este informe.
  3. La cuenta de `s1r` **queda deshabilitada** salvo en las firmas de prueba trimestrales y en una emergencia. El equipo puede quedar apagado.
  4. El PIN de `s1r` lo custodia una persona distinta del titular, si existe el suplente de AP-02, o un sobre precintado.
  5. En §10.5 se corrige «Lo cubre DL-10» por «DL-10 cubre la pérdida (R-B12); el compromiso lo acota DL-14».
  - *Alternativa más barata y mejor frente a las dos llaves:* SEG-L2-23.
- **Bloquea:** se firma **DL-10 con condiciones**.

### SEG-L2-12 · Media · S-02 y S-03 exigen un segundo factor que no está construido

- **Riesgo.** S-02 (legitimar cuentas) y S-03 (cambiar el RNC) piden `CodigoSegundoFactor` (`[BP]` §5.1:237-238). ADR-81 no está construido y su fase A puede recortarse. Si S-03 sale sin segundo factor, una contraseña filtrada del SUPER basta para cambiar el RNC, que es la salida de `Invalida` y el motivo de NV-07.
- **Remediación:**
  - Las rutas S-02 y S-03 **no se publican** hasta que la fase A de ADR-81 esté unida. Mientras tanto, el cambio de RNC solo se hace con `GPOS.Migracion` en el servidor, con motivo y escribiendo la fila con MAC.
  - El `CodigoSegundoFactor` nunca va a los registros de peticiones (ADR-81, punto 5).
- **Bloquea:** se firma **DL-03 con esta condición**.

### SEG-L2-13 · Media · La aceptación del riesgo no tiene caducidad

- **Riesgo.** R-B14: sin fecha para las YubiKeys, una medida «temporal» se vuelve permanente sin que nadie vuelva a decidir. DL-12 propone una fecha objetivo «sin que bloquee nada».
- **Remediación:**
  - DL-12 fija **una fecha de compra y una fecha de revisión de la aceptación**. Recomiendo como máximo 2027-03-31 para la revisión [I: se apoya en la regla de 90 días que ya se usó para el regreso temporal; Q-17 fija 60 días acumulados].
  - Llegada la fecha de revisión sin ceremonia, **la aceptación vence**: hay que firmarla de nuevo con la estimación de ese momento.
  - No se detiene la emisión: se vuelve a decidir.
  - Costo: USD 352 ya presupuestados.
- **Bloquea:** se firma **DL-12 con esta condición**.

### SEG-L2-14 · Baja · Contradicciones en §10.6

- La condición 1 prohíbe el correo y la sincronización con Drive en `gsf-firma`. La condición 8 pide un «ancla por correo al propietario tras cada lote», y §4.1:186 habla de «subida manual a Drive».
- **Remediación:**
  - El emisor **muestra** el hash del ancla, y el propietario lo envía **desde otro dispositivo**, por ejemplo el teléfono. Así el ancla queda además fuera de banda respecto del equipo emisor.
  - Los `.gposlic` salen por una carpeta de intercambio que lee la cuenta diaria. No hace falta proteger su confidencialidad (no contienen secretos y su integridad la da la firma), pero sí que `gsf-firma` no tenga escritura en ninguna carpeta que se sincronice.
  - El registro sale de la misma forma para la copia semanal.

### SEG-L2-15 · Baja · L-08 entrega al ADMIN de una empresa la licencia de toda la instalación

- `/api/admin/licencia/vigente` devuelve el JWS de la instalación a «ADMIN o SUPER» (`[BP]` §5.1:234). El JWS contiene todas las empresas de la instalación, con su RNC, su cupo, sus módulos y su vencimiento. Un ADMIN de la empresa A ve los datos comerciales de la empresa B.
- **Remediación:**
  - L-08 solo para el SUPER (0,1 dp).
  - Documentar que L-03, la carga por un ADMIN, afecta a todas las empresas de la instalación, y que el evento registra todas las empresas afectadas.

### SEG-L2-16 · Baja · S-03 escribe en dos bases sin atomicidad

- S-03 escribe primero la fila con MAC en `GPOS_SYSDATA` y después el RNC en la base de la empresa (`[BP]` §5.1:238). Si la segunda escritura falla, el motor de estados ve un `CambiosRnc` que no corresponde al RNC real.
- **Remediación:**
  - El motor considera vigente un cambio solo cuando el RNC de la empresa es igual a `RncNuevo`.
  - S-03 es idempotente: repetirla completa la segunda escritura sin una fila nueva.
  - Una prueba de QA con el fallo inyectado.

### SEG-L2-17 · Baja · Orden de la comprobación del sello en el inicio de sesión

- `[BP]` §5.1:241 fija la misma respuesta que con una contraseña incorrecta y «no cuenta el intento», pero no dice en qué orden se hacen las comprobaciones.
- **Remediación:** el sello se comprueba **antes** que la contraseña. Si el sello no verifica, se verifica un hash ficticio, como ya hace `ValidarAutorizanteAsync` (`UsuariosService.cs:83-86`) [V]. Así no hay oráculo por tiempo ni por contador.

### SEG-L2-18 · Baja · «Ya aceptado» calculado sobre los bytes del JWS

- `UX_Licencias_Aceptada` es único por el SHA-256 del archivo (`[DAT]` 6.3:983-984). ECDSA es maleable: para una misma firma (r, s), (r, n − s) también verifica. Se puede obtener otro archivo con el mismo contenido y otro SHA-256.
- El efecto depende de la regla «`sec` duplicada con otro contenido» (`[LIC]` 3.1.1, punto 7) y de si alguna marca de tiempo se ancla a la hora de aceptación (INV-7, NV-02) [I].
- **Remediación (0,1 dp):** el verificador rechaza las firmas con `s` > n/2, o la identidad de «ya aceptado» se calcula sobre la entrada de la firma (encabezado protegido más contenido). Se agrega un vector negativo a L1a-1.

### SEG-L2-19 · Baja · La confirmación tiene que derivarse de los bytes que se firman

- `IConfirmacionCustodio.Confirmar(ResumenFirma)` (`[BP]` §9.1:413) no dice de dónde sale el resumen.
- **Remediación:**
  1. El resumen y el SHA-256 se calculan **decodificando la propia entrada de la firma** (`entradaFirma`), no a partir del objeto con el que se construyó.
  2. Después de firmar, el emisor verifica la firma con la llave pública **del recurso publicado** (`LlavesGsf.json` de la versión vigente) usando `GPOS.Criptografia.VerificadorJws`, antes de escribir el archivo.
  3. Vectores con `r` o `s` que empiezan con ceros, para la conversión de DER a P1363 (cada valor con 32 bytes exactos).

### SEG-L2-20 · Baja · Costo del padrón por petición

- La verificación por petición (`[BP]` §2.4:131) incluye el padrón, de unos 70 KB con 1 000 cuentas. Si cada usuario descifra el padrón cada 15 s, el costo crece con el número de usuarios por el tamaño del padrón.
- **Remediación:** una caché global del padrón ya verificado, indexada por su `Version` y releída a lo sumo cada 15 s. El sello de cada usuario se sigue verificando con la lectura de la sesión. QA lo mide.

### SEG-L2-21 · Informativa · Criptografía y FIPS

- **Conformes con la criptografía endurecida de `[PSF]`** [V en el diseño; I en el modo aprobado de cada módulo]:
  - ES256 (ECDSA P-256 con SHA-256, FIPS 186-5);
  - Data Protection de .NET con los algoritmos por omisión (AES-256-CBC más HMAC-SHA256 y derivación SP 800-108), que en Windows usa CNG;
  - PBKDF2 para las contraseñas (SP 800-132);
  - SHA-256 truncado a 96 bits en el padrón: no es la protección criptográfica, que la da `Protect`.
- **El verificador tiene que usar `ECDsa` de la plataforma (CNG)** y ninguna biblioteca JOSE de terceros. `[BP]` §3 ya lo dice («Biblioteca base de .NET»).
- **TPM:** el fTPM de los equipos de consumo normalmente **no tiene validación FIPS 140-3** [I]. Por eso Q-21 se mantiene: nada firmado en Básico se presenta como «validado».
- **Cuando exista el perfil Avanzada (FIPS)** (AP-10, después de la versión 1 del acceso multiempresa), una instalación con ese perfil debería exigir `nivelMin: avanzado`. Queda anotado para `[PSF]`, sin efecto en el lote 2.

### SEG-L2-22 · Informativa · Transición con cofirma

- En la reemisión posterior a la ceremonia (`[BP]` §10.3:510), si el archivo se cofirma con `s1` y `a1` (serialización general de JWS):
  - lo aceptan tanto los binarios antiguos (solo con `s1`) como los nuevos;
  - los 45 días de DL-11 dejan de ser una ventana crítica para los clientes que actualizan tarde.
- El piso monótono (INV-4) sigue subiendo en los binarios nuevos con la firma Avanzada propia.

### SEG-L2-23 · Informativa · Alternativa barata frente a R-B13

- Esto no discute la aceptación; es una opción de mitigación. Una YubiKey 5 **no FIPS** cuesta unos USD 55 [I: precio de lista]. Con ella, `s1` queda en el nivel Básico (sin declaración FIPS, igual que el TPM), con PIN y **toque obligatorio** en cada firma, usando el proveedor `YubiKeyPiv` que ya se construye (§9.1).
- **Elimina la firma silenciosa de SEG-L2-03**: un programa malicioso necesitaría el toque físico. Sustituye además a DL-10 si se compran dos.
- Bajaría R-B11 y R-B13 a Bajo-Medio, contando DL-14.
- Esfuerzo: el mismo de AI-09.

---

## 5. Controles que están bien implementados en el diseño

- **El sello como `Protect` con su propio propósito**, que incluye el `InstalacionId` y el código: no se puede copiar a otra cuenta ni a otra instalación (`[BP]` §2.1).
- **El padrón con MAC y versión** como respuesta a SH-1: la idea es correcta y solo falta la base del conteo (SEG-L2-01).
- **DL-02:** en Estricto, las cuentas iniciales solo las crea `GPOS.Migracion`. Cierra SH-3 en Estricto.
- **DL-03 y C-06:** el RNC con una fila con MAC y solo por el SUPER (NV-07). Es la solución correcta frente a una fila de bitácora que se puede insertar.
- **DL-04:** una sola `BitacoraSeguridad` de solo inserción, con `DENY UPDATE, DELETE` (`[DAT]` S1:378).
- **Clase `Operativa` por omisión** (falla cerrado) y una sola lista de POST de lectura (C-09).
- **`UseLicencia` al final del *pipeline*:** solo restringe, nunca concede (C-02).
- **La abstracción `IProveedorLlaveFirma`**, con la API que verifica sin saber quién firmó y el nivel que sale del recurso por `kid`, nunca del encabezado (§9.1:422).
- **El proveedor de software limitado a `anillo: "Desarrollo"`** en el emisor y rechazado en la API Release (§9.2, §9.3 y QA-L17).
- **El guion de la ceremonia:** comprobación del firmware 5.7 o superior (EUCLEAK), atestación hasta la raíz de Yubico, PIN y PUK interactivos sin pasar por el *script*, un solo intento fallido controlado y actas de ensayo marcadas como sin validez (§10.1).
- **`sec` acotada por `emitida`** y el techo de 48 h (`[LIC]`:303): impiden envenenar la secuencia con una licencia falsificada.
- **CW-02:** sin corte inmediato en Básico. Una licencia falsificada para dañar a un cliente le da al menos 72 h de gracia (R-B15: estoy de acuerdo con Baja / Bajo).
- **Estimación de R-B12** (Media / Alto sin DL-10) y de R-B14: coincido.

---

## 6. Condiciones mínimas de la cuenta y del equipo emisor (foco 2, §10.6)

Sustituyen o completan las 9 condiciones de `[BP]` §10.6. Las verifica devops con el propietario y quedan en el acta de AI-09 **antes de generar `s1`**. Las marcadas **[N]** son nuevas.

| # | Condición | Origen |
|---|---|---|
| E-1 | **La cuenta diaria del propietario es estándar.** Hay una cuenta administradora aparte, con otra contraseña, que se usa solo para el mantenimiento y nunca para navegar, leer correo, compilar ni ejecutar agentes. UAC en «notificar siempre», con credenciales en el escritorio seguro. **Obligatoria (DL-13)** | `[BP]` 6 → obligatoria (SEG-L2-03) |
| E-2 | `gsf-firma`: cuenta **local** del grupo Usuarios, sin cuenta Microsoft, sin escritorio remoto, sin correo, navegador ni sincronización, y sin escritura en carpetas sincronizadas. Contraseña de 16 caracteres o más, que no se usa en ningún otro lugar y que no se guarda en el equipo | `[BP]` 1, ampliada |
| E-3 [N] | **Sesión solo para firmar:** se entra en `gsf-firma`, se firma y **se cierra la sesión**, no se cambia de usuario dejándola abierta. No se dejan sesiones desatendidas | SEG-L2-03 |
| E-4 [N] | **Red de `gsf-firma` restringida:** regla del Firewall de Windows por usuario (`-LocalUser`) que bloquea todo el tráfico saliente de esa cuenta salvo UDP/123 hacia las dos fuentes NTP del emisor [I: se confirma la regla en el ensayo] | SEG-L2-03 |
| E-5 [N] | **Ninguna herramienta de acceso remoto** (escritorio remoto, AnyDesk, TeamViewer o similares) activa en el equipo durante una sesión de firma. Recomendado: ninguna instalada | SEG-L2-03 |
| E-6 | Llave `s1` en el TPM, no exportable, **PIN pedido en cada firma** (comprobado con dos firmas seguidas), PIN de 8 caracteres alfanuméricos o más, que no se guarda en el equipo | `[BP]` 2 + SEG-L2-10 |
| E-7 [N] | **TPM revisado:** fabricante, modelo y firmware en el acta; no afectado por TPM-FAIL ni por avisos posteriores sin corregir. Prueba negativa de uso desde la cuenta administradora (SEG-L2-10, punto 3) | SEG-L2-10 |
| E-8 | Confirmación de cada firma con un resumen **derivado de los bytes que se firman** y verificación posterior con la llave pública del recurso | `[BP]` 3 + SEG-L2-19 |
| E-9 | Carpeta `PCPKSP` de `gsf-firma` fuera de los respaldos, de las instantáneas y de la sincronización desde la generación | `[BP]` 4 |
| E-10 | BitLocker con TPM y **PIN de arranque**, y la clave de recuperación fuera del equipo | `[BP]` 5 |
| E-11 | **Emisor reproducible**, compilado fuera del equipo emisor, con el hash comparado en un segundo dispositivo e instalado en `Program Files` con la cuenta administradora | `[BP]` 7, corregida (SEG-L2-08) |
| E-12 | Registro encadenado en una carpeta que solo escribe `gsf-firma`. **El ancla la envía el propietario desde otro dispositivo** después de cada lote. Copia semanal fuera de Drive | `[BP]` 8, corregida (SEG-L2-14) |
| E-13 | Equipo con arranque seguro, **integridad de memoria (HVCI)** activada, Defender con protección contra alteraciones, Windows Update al día y `w32time` contra una fuente confiable [I: disponibles en Windows 11 Pro; Credential Guard no es exigible en Pro] | `[BP]` 9, ampliada |
| E-14 [N] | Auditoría de los usos de la llave (eventos 5058/5061 [I]) y **comparación mensual** del número de usos con el registro del emisor | SEG-L2-09 |
| E-15 [N] | **AP-03 adaptado:** no aceptar nunca un reinicio del fTPM ni un borrado del TPM; protocolo antes de cada actualización del BIOS; firma de prueba trimestral con `s1` (y con `s1r`) | SEG-L2-10 |

**Costo:** 0 en dinero. Unos 0,75 dp de devops (0,5 ya previstos en `[BP]` §10.4, más 0,25). El costo de uso es cambiar de sesión para firmar y cambiar a la cuenta administradora para mantener el equipo.

---

## 7. Respuesta a las preguntas del encargo

**Foco 1. ¿Es correcta la estimación de §10.5?**
- Medio-Alto es correcto como valor central en el escenario propuesto.
- Hay dos errores de premisa que afectan al texto que firma el propietario:
  - el vector no se limita «a mientras se usa la cuenta de firma» cuando la cuenta diaria es administradora (SEG-L2-03);
  - la aceptación de FY-15 contaba con dos mitigaciones que ya no existen: la caducidad del 2026-12-31 y las vigencias mensuales, que nunca fueron técnicas (SEG-L2-02).
- Las mitigaciones DL-10 a DL-13 **no bastan** para volver a Medio: ninguna acota el impacto.
- **Condiciones mínimas obligatorias para volver a Medio:**
  - DL-13 obligatoria antes de AI-09;
  - DL-14 (tope de 200 días para las licencias Básicas);
  - emisor reproducible y revisado (SEG-L2-08);
  - comparación de `sec` y `lid` en la solicitud (SEG-L2-09);
  - TPM revisado y prueba negativa (SEG-L2-10);
  - caducidad de la aceptación (SEG-L2-13).
- R-B12, R-B14 y R-B15: coincido con la estimación.

**Foco 2. Condiciones mínimas de la cuenta de firma:** E-1 a E-15 de la sección 6. La única que no se puede omitir sin cambiar la estimación es **E-1 (DL-13)**.

**Foco 3. ¿La propuesta cierra SH-1, SH-2 y SH-3?**
- **SH-1: no del todo.** El padrón cierra el caso descrito, pero queda la variante de las columnas (SEG-L2-01) y el retroceso después de una reducción de cupo (SEG-L2-07). Con las dos precisiones, sí.
- **SH-2: sí.** La medida es correcta, pero el hueco era Medio, no Alto, y la justificación hay que corregirla (SEG-L2-04).
- **SH-3: sí en Estricto (DL-02).** Queda abierto en Amplio mientras Amplio sea una clave de configuración (SEG-L2-05). El caso combinado con SH-5 exige que DL-05 sea obligatoria (SEG-L2-06).

**Foco 4. §§5, 8 y 9:**
- Los contratos son correctos en autorización y clase.
- Hay correcciones menores en L-08, S-03 y el orden del sello (SEG-L2-15 a SEG-L2-17), y una dependencia del segundo factor (SEG-L2-12).
- §8 tiene que agregar que Amplio no sella ni crea cuentas en Release (SEG-L2-05).
- §9 es un buen diseño. Hay que agregar la regla de bajo `s` o el cambio de la identidad de «ya aceptado» (SEG-L2-18) y la confirmación derivada de los bytes (SEG-L2-19).
- La criptografía es compatible con FIPS (SEG-L2-21).

---

## 8. Remediaciones priorizadas

| Prioridad | Remediación | Hallazgo | Quién | Costo | Cuándo |
|---|---|---|---|---|---|
| 1 | DL-13 obligatoria y condiciones E-1 a E-15 | SEG-L2-03, SEG-L2-10 | Propietario y devops | 0,75 dp; USD 0 | **Antes de AI-09** (generar `s1`) |
| 2 | Consumo desde el padrón, padrón por diferencias, nivel en la entrada | SEG-L2-01 | Arquitecto-software (precisión de §2.3); desarrollador I | 0,25 dp | Antes de construir SL |
| 3 | DL-14: tope de vigencia de 200 días en Básico | SEG-L2-02 | Arquitecto-software → hoja; desarrollador L (L1a-2) | 0,35 dp | Antes de la primera licencia de pago |
| 4 | Padrón también en disco (SEG-L2-07); Amplio sin sellado ni cuentas en Release (SEG-L2-05); DL-05 obligatoria con el estado del factor (SEG-L2-06) | — | Desarrollador I | 1,0 dp | Con SL |
| 5 | Emisor reproducible y revisión de código del emisor y de `GPOS.Criptografia` | SEG-L2-08 | Devops y auditor-seguridad | 0,5 dp más la revisión | Antes de la primera licencia de pago |
| 6 | `sec`, `lid` y SHA-256 vigentes en la solicitud, con comparación en el emisor | SEG-L2-09 | Desarrolladores L e I | 0,5 dp | Antes de la primera licencia de pago |
| 7 | Condiciones de DL-10, DL-12 y DL-03 (S-02 y S-03 después de ADR-81 fase A) | SEG-L2-11 a SEG-L2-13 | Propietario y arquitecto-maestro | 0 | En la hoja de firma |
| 8 | SEG-L2-14 a SEG-L2-20 | — | Desarrolladores, en sus piezas | unos 0,8 dp | En la construcción |

**Total:** unos 4 dp repartidos entre los dos desarrolladores y devops [I, ±35 %]. Cabe en la holgura de unos 3 dp por desarrollador que calcula `[BP]` §11.4 sin tocar el calendario central. En el peor caso consume la mitad de esa holgura.

---

## 9. Recomendación

**Rechazado en su texto actual (v1)**, por tres hallazgos Altos sin resolver (SEG-L2-01, SEG-L2-02 y SEG-L2-03). Las tres remediaciones son baratas: unos 0,6 dp y USD 0.

**Pasa a «Aprobado con observaciones» sin una ronda completa nueva** si se cumplen dos cosas:
- la hoja de firma DL-01 a DL-13 incorpora las condiciones de abajo;
- el arquitecto-software actualiza §2.3, §10.5 y §10.6 de `[BP]` con ellas, y el auditor lo confirma en una lectura de diferencias.

Es una recomendación técnica: la decisión es del propietario.

### Condiciones para la hoja de firma DL-01 a DL-13

| DL | Recomendación del auditor | Condición que tiene que constar en la hoja |
|---|---|---|
| **DL-01** | Firmar **con precisión** | **(a)** El consumo del cupo se calcula desde las entradas no SUPER del padrón verificado, no desde las columnas. Cada entrada lleva el nivel. El padrón se actualiza por diferencias y solo con acciones de la API. Una fila borrada o alterada sigue contando hasta que el SUPER la purgue con motivo y segundo factor (SEG-L2-01). **(b)** Hay una copia completa del padrón en el disco y prevalece la mayor versión que verifique (SEG-L2-07) |
| **DL-02** | Firmar con condición | En una compilación Release, ningún modo sella ni crea cuentas al arrancar. Con una licencia vigente de `anillo` `Produccion` o `Beta`, la API no arranca en Amplio (SEG-L2-05) |
| **DL-03** | Firmar con condición | S-02 y S-03 no se publican antes de unir la fase A de ADR-81. S-03 es idempotente y el motor solo da por vigente el cambio cuando el RNC de la empresa es igual a `RncNuevo` (SEG-L2-12, SEG-L2-16) |
| DL-04 | Firmar | — |
| **DL-05** | Firmar como **obligatoria** | El sello cubre la huella del `PasswordHash` (o el `SelloSeguridad`) y, en los SUPER, el estado «factor dado de alta» (SEG-L2-06) |
| DL-07, DL-08 | Sin objeción de seguridad | En DL-07: revisión de código del auditor sobre EM y `GPOS.Criptografia` antes de la primera licencia de pago (SEG-L2-08) |
| DL-09 | Sin objeción de seguridad (`autNivel` va en `crit` y falla cerrado) | — |
| **DL-10** | Firmar con condiciones | El segundo equipo no es de desarrollo ni ejecuta agentes; cumple E-1 a E-15; la cuenta de `s1r` queda deshabilitada salvo en la prueba trimestral y en una emergencia; el PIN lo custodia otra persona o queda en un sobre precintado. §10.5 se corrige: DL-10 cubre la pérdida, no el compromiso (SEG-L2-11) |
| DL-11 | Firmar | Recomendado: cofirma `s1` + `a1` en la reemisión de transición (SEG-L2-22) |
| **DL-12** | Firmar con condición | Fecha de compra y **fecha de revisión de la aceptación** (como máximo 2027-03-31). Al llegar sin ceremonia, la aceptación vence y se vuelve a firmar con la estimación de ese momento (SEG-L2-13) |
| **DL-13** | Firmar como **obligatoria** | Previa a AI-09 (la generación de `s1`), no solo a la primera licencia de pago. Condiciones E-1 a E-15 de este informe (SEG-L2-03) |
| **DL-14 (nueva)** | Firmar | Un archivo sin firma Avanzada propia tiene cada `vence` ≤ `emitida` + 200 días (rechazo con 422). El emisor Básico emite a los clientes anuales archivos semestrales (SEG-L2-02) |

**Condiciones fuera de los DL que tienen que constar antes de la primera licencia de pago** (se suman a la tabla de `[BP]` §10.3):
- **El texto adaptado de P-F1 / FY-15 y de R-L11 / R-F11 (AP-04)** nombra las mitigaciones retiradas (equipo dedicado y caducidad del 2026-12-31), las que las sustituyen (DL-13, DL-14 y E-1 a E-15) y el vector corregido: «en cualquier momento, si un programa con privilegios de administrador captura el PIN» (SEG-L2-02, SEG-L2-03).
- Acta de AI-09 con E-7 (TPM revisado y prueba negativa) y con PIN por firma comprobado (SEG-L2-10).
- Comparación de `sec`, `lid` y SHA-256 en la solicitud, construida (SEG-L2-09).
- Emisor reproducible y revisado (SEG-L2-08).

---

## Supuestos

1. El comportamiento del proveedor PCP (uso del *blob* desde otra cuenta administradora con el PIN, caché de la autorización), los eventos de auditoría 5058/5061, la regla de firewall `-LocalUser` y la disponibilidad de HVCI en Windows 11 Pro son [I]. Se confirman en el ensayo de AI-09.
2. Leí el código en `768f0a61`, el commit que cita `[BP]`. No revisé `feature/modelo-ng` @ `59921ba0` ni `a/lic-l1a-1`.
3. Las precisiones (b) y (c) y la aceptación del riesgo Medio-Alto están firmadas, como indica el encargo. No vi el texto firmado.
4. El tope de 200 días es compatible con el refresco semestral de PA-8 [I]. Si el emisor emite hoy archivos anuales, el tope exige emitir dos veces al año a esos clientes mientras dure el nivel Básico.
5. El precio de la YubiKey no FIPS (unos USD 55) es de lista y no está verificado.

### Cierre
- Estado: Rechazado. Lo recomiendo en el texto v1 del blueprint por SEG-L2-01, SEG-L2-02 y SEG-L2-03. Pasa a «Aprobado con observaciones» si la hoja DL-01 a DL-13 (más la DL-14 nueva) incorpora las condiciones de la sección 9. Es una recomendación técnica, Pendiente de firma del propietario.
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\revision-seguridad-blueprint-licencia-lote2-2026-10-14.md`
- Supuestos: los cinco de la sección «Supuestos».
- Decisiones candidatas a ADR:
  - **DL-14 · Tope de vigencia de las licencias sin firma Avanzada** (≤ `emitida` + 200 días). Precisa ADR-62 e INV-1. *Descartadas:* 62 días (obliga a cargar un archivo al mes sin agente) y 400 días (acota poco).
  - Precisión de ADR-83 (candidato de `[BP]`): conteo del cupo desde el padrón, padrón por diferencias con copia en disco, y estado del factor en el sello.
  - Precisión de ADR-84 (candidato de `[BP]`): DL-13 obligatoria, condiciones E-1 a E-15 y caducidad de la aceptación.
- Entregas a otros agentes:
  - arquitecto-software → actualizar §2.3, §2.2 (SH-2), §8, §10.5 y §10.6 de `[BP]` con SEG-L2-01 a SEG-L2-13, y agregar DL-14.
  - arquitecto-maestro → hoja de firma con las condiciones de la sección 9; texto adaptado de P-F1 y R-L11 (AP-04) con el vector corregido; DL-14.
  - devops → E-1 a E-15 y acta de AI-09; compilación reproducible del emisor; AP-03 adaptado (fTPM y prueba trimestral).
  - qa-automatizado → variantes de PA-45 (columnas, borrado y reinserción), retroceso del padrón, Amplio en Release, `s` alto, tope de vigencia Básica, S-03 con fallo inyectado.
  - desarrollador-backend (I y L) → remediaciones en SL, L1a-1, L1a-2 y EM según la sección 8.
- Próximo paso recomendado: que el arquitecto-software incorpore las condiciones y el arquitecto-maestro prepare la hoja DL-01 a DL-14. No generar `s1` (AI-09) hasta que DL-13 esté cumplida.
