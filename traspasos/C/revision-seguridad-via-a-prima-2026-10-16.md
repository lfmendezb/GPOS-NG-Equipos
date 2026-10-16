# Informe de Seguridad: revisión del diseño de la vía (a′), recuperación del SUPER con `autRecuperacionFactor` firmada por GSF

**Auditor:** auditor-seguridad (equipo C) · **Fecha:** 2026-10-16 · **Tipo:** revisión de diseño antes de construir (T-j2) · **Ubicación:** fuera de los repositorios, a propósito.
**Objeto:** hoja `GPOS-NG-Equipos/traspasos/C/hoja-firma-recuperacion-super-2026-10-16.md`, firmada el 2026-10-16 (R-COR-01 (D), R-COR-02, R-COR-03 y R-COR-04), con su sección 4 (análisis de riesgos del Arquitecto Maestro).
**Contexto del código (solo lectura):** rama `c/adr81-fase-a` (`3d64fe2b`, T-q) en `Solucion GPOS NG/GPOS-C-adr81-fase-a`. Las rutas de este informe son relativas a ese árbol, salvo que se diga otra cosa.
**Sin pasos de explotación, pruebas de concepto ni payloads (C10).** No compilé ni ejecuté pruebas: es una revisión de diseño.

---

## 1. Alcance y superficie revisada

**Qué se revisó:**
- La opción D firmada: el SUPER pega su usuario, su contraseña y una autorización JWS de GSF en la Web, y eso le abre el alta de un factor nuevo.
- Las piezas existentes que la hoja propone reutilizar:
  - el verificador JWS (`src/GPOS.Criptografia/Jws/VerificadorJws.cs`, `ContratosJws.cs`, `ConjuntoLlaves.cs`) y las llaves (`src/GPOS.Criptografia/Llaves/LlaveGsf.cs`, `LlavesGsf.json`);
  - la autorización ya existente `autNivel` (`src/GPOS.Core/Sistema/Licencia/AutorizacionRegresoNivel.cs`);
  - el inicio de sesión en dos pasos y el alta (`src/GPOS.Api/Endpoints/AuthEndpoints.cs:42-99`, `AuthEndpoints.SegundoFactor.cs:20-150`, `src/GPOS.Api/Seguridad/DesafiosFactor.cs`);
  - `FiltroFactor`, `AutenticacionReciente`, la emisión del token, `amr`, `auth_time` y `sst` (`src/GPOS.Api/Seguridad/FiltroFactor.cs`, `AutenticacionReciente.cs`, `Seguridad.cs:51-155`, `src/GPOS.Comun/Sesion/ClaimsSesion.cs`, `src/GPOS.Api/Program.cs:80-110, 325-335`);
  - el bloqueo de CS-5 (`src/GPOS.Core/Sistema/UsuariosService.cs:28-56, 449-470`);
  - el reloj protegido H-16 (`src/GPOS.Core/Infraestructura/Reloj/RelojProtegido.cs`) y el candado de restauración (`src/GPOS.Core/Sistema/Restauracion/CandadoRestauracionSistema.cs`).
- Lo firmado de referencia: ADR-81, puntos 2, 6, 7, 11 y 12 (`origin/master:docs/adr/ADR-081.md`), y el blueprint v4 (`docs/arquitectura/2026-10-16-adr81-fase-a-blueprint-v4.md`, §5.1 y §6.4), con §6.3 del blueprint v1 (`docs/arquitectura/2026-10-10-adr81-fase-a-blueprint.md:575-579`, P-81A-10).

**Superficie nueva que agrega (a′):**
- Una ruta anónima (`POST /api/auth/login/recuperacion` o equivalente), expuesta a Internet donde lo esté la API.
- Un artefacto al portador, firmado por GSF y entregado por un canal externo, que **junto con la contraseña permite reemplazar el factor de un SUPER**.
- Una tabla de `jti` consumidos en `GPOS_SYSDATA`.
- Un emisor en GSF, fuera del repositorio.

**Fuera de alcance:** el código del emisor de GSF (no está disponible; ver §8) y la vía B (no se firmó).

---

## 2. Tabla resumen de hallazgos

Las severidades siguen C3 y miden el **riesgo del diseño tal como está escrito**. Si un requisito se construye mal, varios de estos hallazgos pasan a Crítico; por eso son obligatorios (§7).

| ID | Severidad | Título |
|---|---|---|
| SEG-AP-01 | Media | El impacto real de (a′) es la toma completa de la cuenta SUPER: la «sesión restringida» no lo reduce, y R-3 está subestimado |
| SEG-AP-02 | Media | R-4: «el token restringido de P-81A-10» no existe como token sin `otp`; emitir un JWT nuevo agrega superficie innecesaria |
| SEG-AP-03 | Media | El alta de reemplazo con el factor activo no debe poder alcanzarse con el desafío normal del inicio de sesión |
| SEG-AP-04 | Media | Confusión de tipos entre autorizaciones de GSF (R-COR-04): O-2 propone `crit`, que el verificador rechaza; hay que fijar `typ` y `aud` distintos |
| SEG-AP-05 | Media | Separación de funciones de llave: hoy las autorizaciones se firman con llaves de licencias (`lic`) |
| SEG-AP-06 | Media | Repetición del `jti`: consumo atómico y restauración de `GPOS_SYSDATA` |
| SEG-AP-07 | Media | Orden de las comprobaciones: contraseña, CS-5 y enumeración |
| SEG-AP-08 | Baja | Vigencia de 24 h, reloj protegido y ausencia de revocación |
| SEG-AP-09 | Baja | Aviso, evento `A` y cancelación: sin espera, pero con efectos posteriores obligatorios |
| SEG-AP-10 | Baja | Perfil Avanzado (FIPS): algoritmos de la firma y de la custodia |
| SEG-AP-11 | Baja | Entrada en la Web y MAUI: el JWS pegado no debe persistir ni llegar a registros |
| SEG-AP-12 | Baja | Nodos (entrega 2) y la vinculación solo a `InstalacionId` |
| SEG-AP-13 | Baja | El orden de las vías (R-COR-02) no lo aplica el código |
| SEG-AP-14 | Baja (preexistente) | Oráculos de existencia de cuenta en `POST /api/auth/login` (423 y tiempo) |
| SEG-AP-15 | Informativo | El recurso de llaves de producción está vacío |

**No quedan hallazgos Críticos ni Altos abiertos en el diseño**, siempre que T-j2 cumpla los requisitos REQ-C de §7 y GSF los REQ-E de §8.

---

## 3. Checklist OWASP Top 10 (2021), aplicado a (a′)

| # | Categoría | Estado | Nota |
|---|---|---|---|
| A01 | Control de acceso roto | **Requiere REQ-C** | El aislamiento de la sesión restringida y del desafío de reemplazo (SEG-AP-02, 03); la vinculación a la instalación, al usuario y al nivel SUPER (REQ-C-05 y 06) |
| A02 | Fallas criptográficas | Cumple con observaciones | ES256 estricto ya existe; separación de llaves (SEG-AP-05); FIPS (SEG-AP-10) |
| A03 | Inyección | Cumple | El JWS se lee con `LectorJsonEstricto`, base64url canónico y un tope de 64 KB (`VerificadorJws.cs:98-137`); `kid` acotado (`LlaveGsf.cs:90-96`). La ruta nueva no arma SQL dinámico (requisito de construcción) |
| A04 | Diseño inseguro | **Requiere REQ-C** | Confusión de tipos (SEG-AP-04), repetición tras una restauración (SEG-AP-06), orden de las comprobaciones (SEG-AP-07) |
| A05 | Configuración insegura | Cumple con observaciones | Llaves de desarrollo nunca en Release (`VerificadorJws.cs:142-144`); el tope de la vigencia debe ser una constante del binario, no configuración (REQ-C-08) |
| A06 | Componentes vulnerables | No aplica | (a′) no agrega paquetes: reutiliza `System.Security.Cryptography` |
| A07 | Fallas de identificación y autenticación | **Requiere REQ-C y REQ-E** | Es el centro de la vía: la acreditación en GSF, la contraseña y CS-5, el consumo de un solo uso (SEG-AP-01, 06, 07) |
| A08 | Fallas de integridad de software y datos | Cumple con observaciones | Firma de GSF con el recurso de llaves incrustado (`ConjuntoLlaves.cs:6-14`); la tabla de `jti` está en la base, sin MAC: la cubre el consumo atómico (SEG-AP-06) |
| A09 | Registro y monitoreo | **Requiere REQ-C** | Evento `A`, aviso persistente, ningún JWS en los registros (SEG-AP-09, 11) |
| A10 | SSRF | No aplica | La ruta no hace peticiones salientes; la instalación no contacta a GSF |

---

## 4. Hallazgos

### SEG-AP-01 (Media). El impacto real es la toma completa de la cuenta SUPER; R-3 está subestimado

- **Riesgo.** La hoja presenta la sesión restringida como lo que acota la vía («solo da de alta un factor»). Pero quien completa el alta queda con un TOTP válido y, en el inicio de sesión siguiente (contraseña más ese TOTP), tiene una sesión SUPER completa. **La restricción acota la sesión, no el impacto:** quien tenga la autorización y la contraseña se apodera de la cuenta global de la plataforma (ADR-36). Por eso R-3 en D («Baja») es optimista. El impacto es Crítico (SUPER global, entra a toda empresa), y la probabilidad es baja: hace falta la contraseña, un JWS vigente y, sobre todo, engañar al protocolo de acreditación de GSF. **Residual: Media.**
- **Evidencia.**
  - Hoja, §2.2, condición 2, y §4, R-3.
  - `AuthEndpoints.SegundoFactor.cs:39-80`: al confirmar el alta, `/login/factor` emite el token completo con `MetodosSesion.ClaveYFactor`.
- **Remediación.** La defensa principal no está en la API sino **en la emisión**: REQ-E-01 a REQ-E-04 (acreditación por devolución de llamada al número registrado, doble control y prohibición de emitirse a sí mismo). En el núcleo:
  - vigencia corta por omisión en el emisor (REQ-E-06);
  - tope de contraseñas erróneas por `jti` (REQ-C-10);
  - efectos posteriores obligatorios y avisos persistentes (SEG-AP-09).
- **Corrección a la sección 4 de la hoja:** R-3 en D pasa de Baja a **Media residual, aceptable con REQ-E**. No exige una aceptación escrita aparte: es el mismo riesgo del insider de GSF ya aceptado en (b+) y en A-09, siempre que se cumplan REQ-E-02 y REQ-E-03.

### SEG-AP-02 (Media). R-4: no hay un «token restringido sin `otp`» que reutilizar; no conviene crear uno

- **Riesgo.** O-3 dice «la sesión restringida reutiliza el token restringido de P-81A-10». En el código **no existe** un token de SUPER sin `otp` para el alta:
  - el alta ocurre **antes** de que exista un token, con un desafío protegido con Data Protection, de 5 minutos y de un solo uso, en dos rutas anónimas (`DesafiosFactor.cs:25-48`; `AuthEndpoints.SegundoFactor.cs:23-80`);
  - el único «token restringido» de P-81A-10 es el que sale **después** del alta, con `amr = [pwd, otp]` y `cambiar_clave = 1`, limitado a `/clave`, `/sesion` y `/salir` por D-MVP-01 (blueprint v1, §6.3, líneas 577-579).

  Si T-j2 interpreta O-3 como «emitir un JWT de nivel SUPER sin `otp`», ese token:
  - pasa por `FiltroFactor`, que deja pasar **las rutas `PermitidaSinFactor` y todas las `IAllowAnonymous`** (`FiltroFactor.cs:26-28`): `/reautenticar`, `/salir`, `/sesion` y `GET /factor`;
  - lo tendrían que rechazar también la introspección de la API de reportes (`ProtocoloIntrospeccion.cs:48-51, 107`) y cualquier canal futuro.

  Es una lista de exclusiones repartida en varios componentes: justo lo que hace frágil a R-4.
- **Remediación (recomendada, la más barata, ≈ 0 sp adicionales y menos que un JWT nuevo).** **No emitir ningún JWT en la vía (a′).**
  - La ruta de recuperación devuelve un **desafío de recuperación** con un propósito de Data Protection propio (por ejemplo `GPOS.Auth.RecuperacionFactor.v1`), con vida de 10 minutos y un solo uso.
  - Ese desafío **solo** lo aceptan las dos rutas nuevas de la recuperación: obtener el QR y confirmar el alta de reemplazo. Ningún esquema de autenticación lo reconoce como portador, así que R-4 queda cerrado por construcción.
  - Al confirmar el alta, la respuesta entrega los 10 códigos de respaldo nuevos y **no abre sesión**. El SUPER inicia sesión de nuevo, por el camino normal, con la contraseña y el factor nuevo.
  - Alternativa aceptable: abrir la sesión normal con `ClaveYFactor`, como hace `/login/factor` hoy. El riesgo es equivalente (SEG-AP-01), pero agrega un camino de emisión de token que hay que probar.
- **Pruebas (sustituyen la de R-4 de la hoja):**
  - (a) el desafío de recuperación enviado como `Bearer` a **todas** las rutas del `EndpointDataSource` recibe 401;
  - (b) el desafío de recuperación es rechazado por `/login/alta` y `/login/factor`, y el desafío normal por las rutas de recuperación;
  - (c) una prueba de arquitectura impide que las rutas de recuperación llamen a `EmisorTokens`, si se elige la remediación recomendada.

### SEG-AP-03 (Media). El alta de reemplazo no debe poder alcanzarse con el desafío normal

- **Riesgo.** Hoy `/login/alta` responde 409 `ALTA_NO_CORRESPONDE` si el factor está activo (`AuthEndpoints.SegundoFactor.cs:31`), y `Desafio.Alta` se calcula como `!estado.Activo` (`AuthEndpoints.cs:83-84`). La recuperación necesita lo contrario: **un alta pendiente que conviva con un factor activo y lo reemplace al confirmarse**. Si se construye relajando la guarda de `/login/alta`, o reutilizando el indicador `Alta` del `Desafio`, un desafío obtenido **solo con la contraseña** podría reemplazar el factor. Eso eliminaría el segundo factor del SUPER, y en ese caso el hallazgo sería Crítico.
- **Remediación.**
  - El reemplazo solo nace del desafío de recuperación (SEG-AP-02), cuyo contenido lleva el `jti` consumido, el usuario, el sello `sst` vigente y un indicador `Reemplazo` que el desafío normal no puede tener (es otro propósito de Data Protection).
  - Las guardas de `/login/alta` y `/login/factor` **no se tocan**.
  - **El factor actual sigue valiendo hasta la confirmación** (condición 4 de la hoja, §2.2): quien abre una recuperación y no la confirma no deja fuera al SUPER.
  - Al confirmar, en **una sola transacción**: se reemplaza el secreto, se borran los códigos de respaldo anteriores, se limpia el bloqueo del factor, se renueva `SelloSeguridad` (CS-4: todas las sesiones mueren con `credenciales`), se vuelve a sellar la habilitación (ADR-83) y se registra el evento.
  - **Prueba:** con el factor activo, ningún desafío normal llega a reemplazarlo (PF nueva).

### SEG-AP-04 (Media). Confusión de tipos entre autorizaciones de GSF (R-COR-04 y O-2)

- **Riesgo.** R-COR-04 firma un formato común para (b+), el punto 11 y (a′). Los tres artefactos dan efectos distintos y muy sensibles:
  - (b+) habilita el comando en el servidor, **sin contraseña**;
  - el punto 11 deja **entrar como SUPER sin TOTP** en un nodo aislado;
  - (a′) reemplaza el factor, con la contraseña.

  Si un verificador acepta el artefacto de otra vía, una autorización filtrada de (a′) serviría donde no se emitió, o al revés.
  O-2 propone llevar «el tipo en un campo `crit`, como `autNivel`», lo que es incompatible con el verificador:
  - `crit` en el encabezado protegido **se rechaza** (`VerificadorJws.cs:252-262`);
  - `autNivel` no es una autorización independiente: es un miembro del contenido de la licencia que la licencia declara en su `crit` (`AutorizacionRegresoNivel.cs:28-31`).

  Si T-j2 «ampliara» el verificador para admitir `crit`, debilitaría la pieza más revisada del sistema.
- **Remediación (obligatoria).**
  1. **Un `typ` distinto por uso** en el encabezado protegido, registrado en `FuncionPorTypCompacto` (`VerificadorJws.cs:41-44`). Por ejemplo: `gpos-autorizacion-recuperacion+jws` (a′), `gpos-autorizacion-restablecer+jws` (b+) y `gpos-autorizacion-nodo+jws` (punto 11). El verificador ya ata la verificación al `typEsperado` (`VerificadorJws.cs:115-133, 262`).
  2. Además, un miembro **`aud` obligatorio** en el contenido, con un valor por uso (por ejemplo `gpos:recuperacion-factor`), comparado con igualdad ordinal: es la defensa en profundidad si un día dos `typ` comparten el lector.
  3. **Lectores de contenido distintos**, cada uno con un conjunto **cerrado** de miembros. Un miembro desconocido rechaza el artefacto, como hace `SoloMiembros` con el contenedor (`VerificadorJws.cs:275-284`). «Formato común» significa esquema y convenciones comunes, **no** un lector permisivo común.
  4. Vinculación distinta por uso: (a′) se liga a `instalacion` y `usuario`; el punto 11, al nodo; (b+), a la instalación, al usuario y al equipo del comando.
  5. **No** se admite `crit` en el encabezado. O-2 se precisa en el blueprint v4.1: «el tipo va en `typ` y en `aud`; `crit` no se usa en las autorizaciones independientes».
  6. **Prueba en matriz:** cada uno de los tipos {licencia, `autNivel`, manifiesto, (a′), (b+), punto 11}, firmado con una llave válida, presentado a cada verificador de los demás, se rechaza.

### SEG-AP-05 (Media). Separación de funciones de llave

- **Riesgo.** Las funciones de llave son hoy `lic` y `upd`, y «ninguna llave sirve a las dos funciones» (R-E1, `LlaveGsf.cs:18-28`). `autNivel` se firma con llaves `lic` (`VerificadorJws.cs:37-44`). Si (a′) se registra también con `lic`, cualquier llave de licencias (incluida la **básica, en el TPM del equipo emisor de licencias**) puede firmar la toma de una cuenta SUPER. El compromiso del equipo que emite licencias pasaría a dar acceso a las cuentas de la plataforma.
- **Remediación (recomendada).**
  - Una **función nueva `aut`** (kids `gsf-aut-*`) para las autorizaciones de identidad: (a′), (b+) y el punto 11. Se registra en `FuncionesLlave.EsValida` y en el recurso, y el verificador ya trata una llave de otra función como desconocida (`VerificadorJws.cs:152-157`).
  - Para (a′), exigir una firma de **nivel no inferior al perfil de la instalación**: en Avanzada, solo `avanzado` (YubiKey FIPS).
  - Costo inferido: núcleo ≈ 0,05 sp; emisor ≈ 0,1 sp más una ceremonia de llaves, compartida con (b+).
- **Alternativa descartada:** reutilizar `lic` exigiendo siempre el nivel `avanzado`. Es más barata en el emisor, pero mezcla funciones (contradice R-E1) y ata la disponibilidad de la recuperación a la del custodio de la YubiKey de licencias.
- **Decisión candidata a precisión:** es una precisión de ADR-62 (funciones de llave) que prepara el Arquitecto Maestro y firma el propietario.

### SEG-AP-06 (Media). Repetición del `jti`: consumo atómico y restauración de `GPOS_SYSDATA`

- **Riesgo.**
  1. **Carrera:** dos peticiones con el mismo JWS. Si el consumo es «leer y luego insertar», las dos pueden pasar.
  2. **Restauración:** la tabla de `jti` consumidos vive en `GPOS_SYSDATA`. Si se restaura una copia anterior al consumo, dentro de la vigencia del JWS, el `jti` vuelve a estar libre. El candado de restauración ya detecta el cambio de *fork* (`CandadoRestauracionSistema.cs:3-6`), pero la tabla no lo sabe.
  3. A diferencia de los desafíos, que usan un registro en memoria (`DesafiosFactor.cs:34, 67-73`, aceptable por ADR-24), el `jti` **debe** ser persistente: vive hasta 24 h y sobrevive a reinicios.
- **Remediación.**
  - Tabla `dbo.AutorizacionesConsumidas` (o similar) con **clave primaria** `(Tipo, Jti)`. El consumo es un `INSERT` en la **misma transacción** que crea el alta de reemplazo; una violación de la clave primaria significa «ya usada» y da 401 uniforme. Los consumidos se guardan de forma permanente: son pocas filas.
  - **Regla de restauración:** se rechaza toda autorización con `iat` anterior al **último momento de restauración detectada** de `GPOS_SYSDATA`. Ese momento debe conservarse después de liberar el candado. Si `EstadoRestauracionSistema` no lo conserva, T-j2 agrega la columna (≈ 0,05 sp).
  - Formato del `jti`: 128 bits o más del CSPRNG del emisor, base64url, con la forma validada (largo fijo y alfabeto) antes de usarlo o registrarlo, como `FormatoKid`.
  - Se comprueba que el `jti` **no esté consumido antes de verificar la contraseña** (SEG-AP-07) y se consume después.

### SEG-AP-07 (Media). Orden de las comprobaciones: contraseña, CS-5 y enumeración

- **Riesgo.** La ruta es anónima y recibe usuario y contraseña. Mal ordenada:
  - sería un **oráculo de contraseñas** paralelo a `/login`;
  - si comparte el contador de CS-5, permitiría **bloquear a un SUPER** con intentos falsos (A-12);
  - si no lo comparte, permitiría **probar contraseñas sin bloqueo**.

  La hoja (§4, V2.2.1) dice que «comparte el contador de intentos del factor»; lo correcto es el **de la contraseña** (CS-5), más un cupo propio por `jti`.
- **Evidencia.**
  - `UsuariosService.cs:28-56`: `ValidarAsync`, con el contador y el bloqueo de la contraseña.
  - `UsuariosService.cs:449-470`: `ConfirmarClaveAsync`, CS-5.
  - `DesafiosFactor.cs:30-31, 56-63`: el cupo del factor, 10 por minuto.
- **Remediación (orden obligatorio).**
  1. Tope de tamaño del cuerpo (4 KB basta; un JWS compacto de este tipo pesa menos de 1 KB) y cupo `login` por IP.
  2. Verificación del JWS: `typ`, firma, función y nivel de la llave, `aud`, `instalacion` igual al `InstalacionId` **de la licencia verificada con el anillo** (falla cerrada, como P-81A-15), vigencia según el reloj protegido y regla de restauración. **Nada de esto toca cuentas.**
  3. `jti` no consumido (lectura).
  4. El usuario escrito coincide con el `usuario` del JWS (código normalizado, comparación ordinal). Si no coincide, **401 uniforme**, igual que la contraseña incorrecta.
  5. Contraseña con `ValidarAsync`, **el mismo contador de CS-5**. Con la cuenta bloqueada, 423, como en `/login`.
  6. Cuenta habilitada y de nivel SUPER **vigente** (no basta con que el JWS lo diga).
  7. Consumo atómico del `jti` y emisión del desafío de recuperación.

  Además:
  - **Cupo por `jti`:** a las 3 contraseñas erróneas con el mismo JWS, el `jti` se consume como «quemado», con el evento `M`.
  - Los errores del paso 2 pueden ser específicos (vencida, otra instalación, formato), porque no revelan nada de las cuentas. Los de los pasos 3 a 6 son **un único 401** con el mismo texto.
- **Efecto:** sin un JWS válido de GSF para ese usuario y esa instalación, la ruta no sirve para enumerar cuentas ni para probar contraseñas. Es más estricta que `/login` (ver SEG-AP-14).

### SEG-AP-08 (Baja). Vigencia de 24 h, reloj protegido y revocación

- **Riesgo.**
  - Un JWS filtrado del canal de entrega (por ejemplo, el correo de GSF) vale hasta 24 h.
  - No hay revocación: la instalación no consulta a GSF, y retirar una llave para anular un JWS es desproporcionado.
  - Un reloj del sistema atrasado podría alargar la vigencia si se usara `DateTime.UtcNow`.
- **Remediación.**
  - Usar `IRelojProtegido.Ahora()` para la vigencia. Esa hora nunca retrocede (`RelojProtegido.cs:11-23`), así que atrasar el reloj no alarga nada y adelantarlo solo la acorta.
  - Rechazar `iat` posterior a `Ahora() + 5 min` (la tolerancia de H-16, `RelojProtegido.cs:92`) y `exp − iat` mayor de 24 h. El tope de 24 h es una **constante del binario**, no configuración.
  - El **emisor** fija por omisión una vigencia de **2 h** (REQ-E-06): el SUPER la usa minutos después de la llamada. Las 24 h firmadas quedan como tope técnico.
  - Revocación: no se construye. Ante una filtración sospechada, el procedimiento de GSF (REQ-E-09) es que el SUPER legítimo la use de inmediato (el uso la consume) o, si no puede, que otro SUPER aplique la vía (a) apenas esté disponible. Riesgo residual aceptable: hace falta además la contraseña.
- **Decisión candidata a precisión (opcional):** bajar el tope técnico de 24 h a 4 h. Costo 0. Lo prepara el Arquitecto Maestro; es una precisión de lo firmado.

### SEG-AP-09 (Baja). Aviso, evento `A` y cancelación

- **¿Debe haber una ventana de cancelación?** **No, en D.** Coincido con la hoja, por tres motivos:
  1. La espera compensaba en B que el correo no acreditara a la persona. En D, quien acredita es GSF (REQ-E-01 a REQ-E-03).
  2. La vía existe justamente para cuando **no hay otro SUPER disponible**, que sería el único capaz de cancelar.
  3. Una espera rompe el objetivo firmado, «minutos tras la llamada».

  Alternativa descartada: espera de 1 a 24 h con cancelación por otro SUPER. Costaría unos +0,4 sp y no protege en el caso para el que existe la vía.
- **Lo que sí es obligatorio (detección y respuesta):**
  - **Evento `A` `RECUPERACION_FACTOR_OK`** en `BitacoraSeguridad`, con el usuario, el `jti`, la `causa`, el `kid` firmante, la huella SHA-256 del contenido, la IP y el canal. **Nunca el JWS** (es un portador hasta consumirse).
  - **Evento `M` `RECUPERACION_FACTOR_RECHAZADA`** con el motivo de catálogo, limitado a uno por minuto y usuario como `TOKEN_SUPER_SIN_OTP` (`FiltroFactor.cs:37-40`, D81-10).
  - **Aviso persistente hasta acusar recibo**, en la entrada de **todos** los SUPER, **incluido el recuperado** («Se restableció su verificación en dos pasos con una autorización de GSF el …; si no fue usted, avise a GSF»).
  - Los efectos de SEG-AP-03 (sello renovado, sesiones cerradas, códigos anteriores invalidados), que dejan fuera a cualquier sesión anterior del atacante o de la víctima.
  - La respuesta a un abuso ya existe: otro SUPER aplica la vía (a), o GSF aplica la vía (b).

### SEG-AP-10 (Baja). Perfil Avanzado (FIPS): algoritmos

- **Verificado:**
  - El verificador admite **solo ES256**, es decir, ECDSA P-256 con SHA-256 (`VerificadorJws.cs:46, 262`), con firma IEEE P1363 de 64 bytes, verificada con `ECDsa` de .NET (`VerificadorJws.cs:177-193`). Una excepción del proveedor se trata como firma inválida.
  - ECDSA P-256 con SHA-256 está aprobado (FIPS 186-5; SP 800-57) y la YubiKey FIPS 140-3 lo genera en PIV.
  - Las llaves de desarrollo se rechazan en Release aunque la firma sea válida (`VerificadorJws.cs:142-144`).
- **Inferido, no verificado:** que el módulo criptográfico de Windows de la instalación figure como validado en CMVP para su versión. Lo exige ADR-64 y no es propio de (a′).
- **Requisitos:**
  - No admitir otros algoritmos (ni EdDSA ni RSA) «por compatibilidad del emisor».
  - La identidad de la autorización es el `jti` del contenido, **nunca** la huella de la firma: ECDSA es maleable, como ya se resolvió en SEG-L2-18 (`VerificadorJws.cs:63-71`).
  - El desafío de recuperación usa Data Protection sobre el anillo vigente (AES-256-CBC con HMAC-SHA256 por omisión: algoritmos aprobados) y no agrega criptografía nueva.
  - (a′) **sí** se admite en Avanzada; la hoja lo firmó y no hay SMTP.

### SEG-AP-11 (Baja). Entrada en la Web y MAUI

- **Riesgo.** Hasta consumirse, el JWS es un portador. Puede quedar en el historial de formularios, en el almacenamiento local, en registros de peticiones o en la telemetría.
- **Remediación.**
  - Campo con `autocomplete="off"` y sin persistencia local en la Web ni en MAUI.
  - Ningún registro del cuerpo de la petición. En los registros, solo el `jti` y la huella, **después** de verificar la firma: antes, el texto no es de confianza.
  - `Cache-Control: no-store` (ya lo aplica `SinCache` en `/api/auth/*`, `AutenticacionReciente.cs:106-125`).
  - El mismo tratamiento para el URI `otpauth` del alta de reemplazo (ADR-81, punto 5).

### SEG-AP-12 (Baja). Nodos (entrega 2) y la vinculación solo a `InstalacionId`

- **Riesgo.** Si los nodos comparten `InstalacionId` con la central, un JWS de (a′) ligado solo a la instalación sería presentable en un nodo, donde la tabla de consumidos es otra. El secreto del SUPER nunca sale de la central (ADR-81, punto 11), así que hoy no hay nada que reemplazar en un nodo, pero la ruta no debe existir allí.
- **Remediación.** Marcar la ruta como `SoloCentral` y declarar en el blueprint v4.1 que (a′) no se publica en un nodo. El punto 11 lleva su propio `typ` y su vinculación al nodo (SEG-AP-04).

### SEG-AP-13 (Baja). El orden de las vías no lo aplica el código

- **Riesgo.** R-COR-02 fija un orden (códigos → a → a′ → b), pero la API no puede saber si el SUPER tenía códigos o si había otro SUPER disponible. El orden es un **procedimiento de GSF**.
- **Remediación.** Llevarlo a REQ-E-05: el emisor registra en la emisión por qué no sirvieron los códigos ni la vía (a), dentro de la `causa` de catálogo cerrado.

### SEG-AP-14 (Baja, preexistente; no lo introduce a′)

- **Riesgo.** `POST /api/auth/login` distingue entre una cuenta existente y bloqueada (423) y una inexistente (401). Además, la inexistente responde sin calcular el hash, lo que deja una diferencia de tiempo.
- **Evidencia.** `UsuariosService.cs:30-33`; `Program.cs:401`.
- **Remediación (fuera de T-j2).** Calcular un hash ficticio para la cuenta inexistente y valorar responder 401 durante el bloqueo. Lo registro para el backlog de seguridad; en (a′) no es explotable porque la ruta exige primero un JWS válido (SEG-AP-07).

### SEG-AP-15 (Informativo)

El recurso de llaves de producción está vacío (`src/GPOS.Criptografia/Llaves/LlavesGsf.json`: `"llaves": []`). En Release, (a′) no verificará nada hasta que GSF publique las llaves `aut` (o las que se decidan en SEG-AP-05). Las pruebas con kids de desarrollo valen solo en Debug (punto 9). Este estado no es un riesgo; es una dependencia de publicación.

---

## 5. Controles que están bien implementados

- **Verificador JWS estricto** (`VerificadorJws.cs`): tope de tamaño antes de interpretar, JSON estricto, base64url canónico, encabezado solo protegido, ES256 único, `kid` y `nivel` acotados, nivel tomado del recurso y no del encabezado, función de la llave atada al `typ`, rechazo de los kids de desarrollo en Release y excepciones del proveedor tratadas como firma inválida. Es una buena base para (a′).
- **Juego de llaves inmutable** que solo se puede restringir, nunca ampliar desde la configuración o la base (`ConjuntoLlaves.cs:6-33`), y resultado de la verificación imposible de fabricar desde fuera (`ContratosJws.cs:1-60`).
- **Precedente de autorización ligada a instalaciones**, con ventana y causa de catálogo (`AutorizacionRegresoNivel.cs:56-131`).
- **Desafíos de un solo uso** con Data Protection por propósito y vencimiento (`DesafiosFactor.cs`), que permiten cerrar R-4 sin un token nuevo.
- **Sello `sst` y orden de validación por petición** (`Program.cs:80-110`; blueprint v4, §6.4): renovar el sello mata todos los tokens anteriores.
- **El SUPER sin `otp` se marca y se contiene en una lista cerrada** (`FiltroFactor.cs`), y la API de reportes lo rechaza por introspección.
- **Reloj protegido que no retrocede** (`RelojProtegido.cs`).
- **Contador y bloqueo de la contraseña compartidos** entre el inicio de sesión y la confirmación (CS-5).

---

## 6. Revisión de la sección 4 de la hoja

| Punto de la hoja | Dictamen |
|---|---|
| V2.5.6 (mecanismo seguro) | **Confirmo:** cumple |
| V2.5.7 (acreditar al nivel del alta) | **Confirmo, condicionado** a REQ-E-01 a REQ-E-04: la acreditación la hace GSF, y sin ese protocolo escrito no cumple |
| V2.5.1 / V2.3.1 | **Confirmo**, con el `jti` de 128 bits o más (REQ-E-07) |
| V2.2.1 (automatización) | **Corrijo:** el contador es el de la **contraseña** (CS-5), más un cupo por `jti` y el cupo `login` por IP. El del factor aplica a la confirmación del alta (SEG-AP-07) |
| V2.2.3 (avisos) | **Confirmo y amplío:** el aviso es persistente y también llega al SUPER recuperado (SEG-AP-09) |
| V6.2.1 / V6.2.2 | **Confirmo**, con SEG-AP-10 |
| R-3 en D (Baja) | **Corrijo a Media residual** (SEG-AP-01): el impacto es la toma completa de la cuenta |
| R-4 (Media) | **Corrijo el diseño:** sin JWT nuevo, con un desafío de recuperación (SEG-AP-02), queda cerrado por construcción |
| R-6 (Baja) | **Confirmo** |
| No citados en la hoja | SEG-AP-03 (reemplazo con el factor activo), SEG-AP-04 (confusión de tipos), SEG-AP-05 (función de llave), SEG-AP-06 (restauración) |

La numeración es de ASVS 4.0.3. No verifiqué las equivalencias con ASVS 5.0.

---

## 7. Requisitos de construcción de T-j2 (REQ-C), en orden de prioridad

Todos son obligatorios para recomendar la unión de T-j2. El arquitecto-software los lleva al blueprint v4.1.

| ID | Requisito | Hallazgo | Prueba de aceptación |
|---|---|---|---|
| REQ-C-01 | La vía (a′) **no emite ningún JWT**. Produce un desafío de recuperación con un propósito de Data Protection propio, de 10 minutos y un solo uso, que solo aceptan las rutas nuevas. Si el propietario prefiere abrir la sesión al confirmar, se hace solo con `ClaveYFactor` y por el mismo emisor de `/login/factor` | 02 | El desafío como `Bearer` en todas las rutas da 401; los desafíos normal y de recuperación no se cruzan |
| REQ-C-02 | El reemplazo de un factor activo solo nace del desafío de recuperación. Las guardas de `/login/alta` (409 con el factor activo) no cambian. El factor actual vale hasta la confirmación | 03 | Con el factor activo, ningún camino sin JWS lo reemplaza; si la recuperación se abandona, el factor anterior sigue valiendo |
| REQ-C-03 | Al confirmar, en una sola transacción: secreto nuevo, códigos anteriores borrados, bloqueo del factor limpio, `SelloSeguridad` renovado, sello de habilitación (ADR-83) renovado, `jti` consumido y evento `A` | 03, 09 | Después de confirmar, todo token anterior muere con `credenciales`, y los códigos anteriores no valen |
| REQ-C-04 | `typ` propio (`gpos-autorizacion-recuperacion+jws` o el que fije el blueprint) en `FuncionPorTypCompacto`; `aud` obligatorio en el contenido; lector con miembros cerrados; **sin `crit`** | 04 | Matriz cruzada entre licencia, `autNivel`, manifiesto, (a′), (b+) y el punto 11: todo cruce se rechaza |
| REQ-C-05 | La llave de una función propia (`aut`, según la precisión de ADR-62), de nivel no inferior al perfil de la instalación; en Avanzada, solo `avanzado` | 05, 10 | Una firma válida con una llave `lic` o `upd` se rechaza; en Avanzada, una `basico` se rechaza |
| REQ-C-06 | `instalacion` es igual al `InstalacionId` de la licencia verificada con el anillo; si el anillo no verifica, se rechaza (como P-81A-15). `usuario` es igual al usuario escrito, y la cuenta es SUPER vigente y está habilitada | 07 | Una autorización de otra instalación, de otro usuario o de un SUPER degradado se rechaza |
| REQ-C-07 | Tabla de consumidos con clave primaria `(Tipo, Jti)`, `INSERT` atómico en la transacción del alta, sin borrado; forma del `jti` validada | 06 | Dos peticiones simultáneas: solo una pasa |
| REQ-C-08 | Vigencia con `IRelojProtegido.Ahora()`; `iat` ≤ ahora + 5 min; `exp − iat` ≤ 24 h como constante del binario; `iat` posterior a la última restauración detectada de `GPOS_SYSDATA`, conservada después de liberar el candado | 06, 08 | Con el reloj del sistema atrasado, una autorización vencida sigue vencida; con una restauración detectada, una autorización anterior se rechaza |
| REQ-C-09 | El orden de comprobaciones de SEG-AP-07: el JWS antes que la cuenta; el `jti` antes de la contraseña; la contraseña con el contador de CS-5; 401 uniforme para usuario, contraseña, `jti` usado y nivel | 07 | Sin un JWS válido, la ruta no cambia `IntentosFallidos` de ninguna cuenta; las respuestas de los pasos 3 a 6 son idénticas |
| REQ-C-10 | Un cupo de 3 contraseñas erróneas por `jti` quema la autorización (evento `M`); cupo `login` por IP; tope de 4 KB en el cuerpo | 01, 07 | Al cuarto intento con el mismo JWS: rechazo aunque la contraseña sea correcta |
| REQ-C-11 | Eventos `RECUPERACION_FACTOR_OK` (`A`) y `RECUPERACION_FACTOR_RECHAZADA` (`M`, como mucho uno por minuto y usuario), con `jti`, `causa`, `kid` y huella, **nunca** el JWS; aviso persistente a todos los SUPER, incluido el recuperado | 09, 11 | Una búsqueda en los registros y en la bitácora no encuentra el JWS ni el URI `otpauth` |
| REQ-C-12 | Ruta `SoloCentral`, anónima (sin clase de licencia, como las demás anónimas), con `no-store`; en la Web y MAUI, sin persistencia ni autocompletado del campo | 11, 12 | La ruta no existe en un nodo; el campo no queda en el almacenamiento del cliente |
| REQ-C-13 | Ningún algoritmo distinto de ES256; identidad por `jti`, nunca por la huella de la firma | 10 | Una firma maleada del mismo contenido no permite un segundo uso |

**Costo adicional inferido (±30 %):** unos +0,3 sp sobre el 1,0 sp de la hoja:
- desafío en lugar de JWT: 0;
- regla de restauración: 0,05;
- cupo por `jti`: 0,05;
- matriz de tipos y prueba de rutas: 0,1;
- función `aut` en el núcleo: 0,05;
- avisos persistentes: 0,05.

T-j2 queda en unos **1,3 sp** en el núcleo.

---

## 8. Requisitos del emisor de GSF (REQ-E), fuera del repositorio

El emisor no está en el repositorio y no pude revisarlo. Estos requisitos son **condición** para que (a′) cumpla V2.5.7. Se comparten con (b+) y el punto 11.

| ID | Requisito |
|---|---|
| REQ-E-01 | **Acreditación por devolución de llamada** al número registrado en la ficha del empleado de GSF, nunca al número que da quien llama; o una videollamada con un responsable que conozca a la persona. Queda registrado el método |
| REQ-E-02 | **Doble control:** quien acredita no es quien firma, o un segundo responsable aprueba antes de firmar |
| REQ-E-03 | **Nadie se emite una autorización para sí mismo** ni para una cuenta cuya contraseña conozca |
| REQ-E-04 | Se comprueba en el registro de GSF que el `usuario` es un SUPER vigente de esa `instalacion` y que la persona sigue en GSF |
| REQ-E-05 | La `causa` es de catálogo cerrado e incluye por qué no sirvieron los códigos ni la vía (a) (R-COR-02) |
| REQ-E-06 | Vigencia por omisión de **2 h**, nunca más de 24 h; `iat` es la hora real del emisor |
| REQ-E-07 | El `jti` tiene 128 bits o más del CSPRNG, y el emisor nunca lo reutiliza |
| REQ-E-08 | Firma con llaves de la función `aut` (o la que fije la precisión de ADR-62): en el TPM, no exportables, o en una YubiKey FIPS con PIN y toque. Nunca llaves de desarrollo. Después de firmar, el emisor **verifica** el artefacto contra el recurso publicado (`ConjuntoLlaves.DesdeRecurso`, `ConjuntoLlaves.cs:35-53`) |
| REQ-E-09 | Entrega por un canal distinto de aquel por el que viaja o se recuerda la contraseña. El artefacto nunca va junto con la contraseña. Hay un procedimiento escrito ante una filtración sospechada (SEG-AP-08) |
| REQ-E-10 | **Registro de solo inserción** en GSF de cada emisión: `jti`, usuario, instalación, causa, operadores, método de acreditación, canal de entrega y huella. Alerta a seguridad de GSF en cada emisión. Tope de emisiones por usuario (por ejemplo, 3 cada 30 días) con revisión obligatoria por encima |
| REQ-E-11 | Lo emite con su `typ` y su `aud` propios (REQ-C-04). Un mismo artefacto nunca sirve para dos usos |

---

## 9. Remediaciones priorizadas

1. **Antes de escribir el blueprint v4.1:**
   - REQ-C-01 a REQ-C-04, la estructura que cierra R-4, el reemplazo y la confusión de tipos;
   - preparar la precisión de ADR-62 sobre la función `aut` (SEG-AP-05).
2. **En la construcción de T-j2:** REQ-C-05 a REQ-C-13.
3. **Antes de publicar la vía:**
   - REQ-E-01 a REQ-E-11, escritos y aplicados por GSF;
   - las llaves `aut` publicadas en el recurso de producción (SEG-AP-15).
4. **Backlog, fuera de T-j2:** SEG-AP-14.

---

## 10. Recomendación: **Aprobado con observaciones**

Recomiendo el diseño (a′) firmado (opción D) como base de T-j2. Es preferible a B: no agrega SMTP, ni direcciones, ni secretos en la instalación, y reutiliza un verificador sólido.

No quedan hallazgos Críticos ni Altos en el diseño. Las siete observaciones Medias (SEG-AP-01 a 07) son **requisitos obligatorios de construcción**: si T-j2 no las cumple, en particular REQ-C-01 a REQ-C-04, la vía puede degradarse a un bypass del segundo factor del SUPER (Crítico). Una segunda revisión del auditor sobre el código de T-j2 es condición para recomendar su unión.

Esta es una recomendación técnica. Las precisiones que propone (función `aut` en ADR-62, la redacción de O-2 y O-3 y, opcionalmente, el tope de 4 h) quedan **pendientes de firma** del propietario.

---

### Supuestos
- P-81A-15 a 17 firmadas en la opción (a), según la hoja. No lo verifiqué en `master`.
- `EstadoRestauracionSistema` puede no conservar el momento de la última restauración después de liberar el candado. Solo vi el registro en memoria (`CandadoRestauracionSistema.cs`); por eso REQ-C-08 lo pide de forma explícita.
- Los nodos podrían compartir `InstalacionId` con la central (entrega 2, sin diseño todavía).
- Que el módulo criptográfico de Windows figure como validado FIPS es inferido; corresponde a ADR-64.
- Numeración de ASVS 4.0.3; las equivalencias con 5.0 no están verificadas.
