# Hoja de firma: recuperación del SUPER que perdió el teléfono, antes del comando en el servidor (precisión de ADR-81, punto 7)

**Preparada por:** Arquitecto Maestro (equipo C) · **Fecha:** 2026-10-16 · **Decide y firma:** el propietario (Leonardo Méndez)
**Estado:** Pendiente de firma
**Pedido de origen (propietario, 2026-10-16, literal):** «Sobre el reestablecimiento del SUPER por perdida del teléfono. Es posible agregar un mecanismo mas antes de utilizar el comando. La posibilidad de que el sistema pueda enviar un correo para reestablecer el acceso del SUPER temporalmente con el objetivo de volver a reestablecer el factor ?»
**Ubicación:** fuera de los repositorios, a propósito. Si se firma, el equipo de documentación la registra como precisión de ADR-81 en `master`.

---

## 0. Resumen para decidir

- **Sí es posible, sin contradecir lo firmado, si la vía nueva es de *recuperación* y no un *factor*.** El correo no puede servir para entrar como SUPER. Solo puede abrir una sesión restringida que no hace más que dar de alta un factor nuevo.
- **Antes del comando ya hay dos salidas, no una:** los **10 códigos de respaldo** (punto 6 de ADR-81) y **otro SUPER** (vía a). La vía nueva solo cubre el caso en que el SUPER perdió el teléfono **y** también los códigos **y** no hay otro SUPER disponible.
- **Recomendación: opción D.** Es una **autorización de recuperación firmada por GSF**. El SUPER la pega en la Web junto con su contraseña. Abre la sesión restringida al alta del factor. GSF se la puede entregar **por correo desde GSF**, sin que la instalación envíe correos.
  - Cumple lo que usted busca: no hace falta un técnico en el servidor.
  - No necesita SMTP en `GPOS_SYSDATA`.
  - Funciona en Básica y en Avanzada.
  - Reutiliza la verificación JWS de GSF que ya existe.
  - Costo: unos **1,0 sp en el núcleo**, más el emisor de GSF.
- **Si prefiere que sea el sistema el que envía el correo (opción B):** es aceptable **solo en Básica**, con espera de 24 h, avisos, cancelación y la dirección protegida por el sello. Costo: unos **2,4 sp**.
- **Orden de las vías que se propone:** códigos de respaldo → (a) otro SUPER → **vía nueva** → (b) comando en el servidor.
- **Momento de construirla:** en una tanda aparte, **T-j2**, después de la firma y después de T-j, T-m y T-p. No entra en T-j ni en T-m, que siguen como están.

---

## 1. El problema

**Hoy (verificado en `origin/master:docs/adr/ADR-081.md:16-19` y en el blueprint v4, `origin/c/adr81-fase-a:docs/arquitectura/2026-10-16-adr81-fase-a-blueprint-v4.md:183-184, 500`):**

- El TOTP es obligatorio para todo SUPER en todo canal (punto 2). Un token de nivel SUPER sin `otp` no vale en ninguna ruta.
- Si el SUPER pierde el teléfono, tiene tres salidas:
  1. **Un código de respaldo** (punto 6, 10 códigos). Con él entra, y P-81A-09 le ofrece una alta nueva. Con «Mi segundo factor» (5.8, cambio de teléfono) rehace el factor. **No necesita a nadie.**
  2. **Vía (a): otro SUPER.** Debe tener su factor confirmado hace menos de 5 min y escribir un motivo (ruta 5.9 del blueprint, `POST /api/super/usuarios/{codigo}/factor/restablecer`).
  3. **Vía (b): `GPOS.Migracion restablecer-factor` en el servidor.** Se ejecuta con la identidad administrativa de Windows del técnico de GSF (RG-14 y ADR-82, punto 12, citados en el blueprint v4, línea 121). Con P-81A-15 (a) se niega si el anillo no verifica `Licencia.InstalacionId`, vuelve a sellar en la misma transacción (ADR-83) y deja un evento de severidad `A` con el SID, el equipo y el motivo. En Avanzada (b+), exige además una autorización firmada por GSF.
- GSF mantiene **al menos dos SUPER por instalación** (punto 7), y P-81A-07 avisa si quedan menos de dos con factor.

**El hueco real** es este caso: el SUPER perdió el teléfono, no tiene los códigos de respaldo y el otro SUPER no está disponible (vacaciones, sin conexión, se fue de GSF). Entonces solo queda (b), que exige:
- un técnico de GSF con acceso administrativo al servidor del cliente (conexión remota o visita);
- coordinarse con el cliente, que es el dueño del equipo.

Costo operativo inferido: 1 a 3 horas de técnico por incidente, más la espera para coordinarse con el cliente. No hay datos de frecuencia: hoy no hay clientes en producción.

**A quién afecta:** solo a los agentes de GSF. **El SUPER es siempre de la plataforma** (ADR-81, contexto, línea 7; ADR-53, P-4) y nunca pertenece a la empresa del cliente. Los usuarios del cliente no ven esta vía.

---

## 2. La tensión con lo firmado

### 2.1 Qué se descartó y por qué

En las **Alternativas descartadas** de ADR-81 (`ADR-081.md:28`) figuran, entre otras:
- «**correo** (comparte equipo o contraseña; SMTP es una brecha FIPS conocida)»;
- «**restablecimiento por el ADMIN**»;
- «**recordar este equipo**».

Lo descartado es el correo **como factor**, es decir, un código por correo en cada inicio de sesión. Las dos razones siguen vigentes:
- **Comparte equipo o contraseña.** El buzón suele abrirse en el mismo equipo y a menudo con la misma contraseña. Entonces deja de ser un factor independiente.
- **Brecha FIPS.** El perfil Avanzado (ADR-64) declara módulos validados FIPS 140-3 para la criptografía del servidor. Un SMTP de terceros queda fuera de ese límite, y el punto 8 de ADR-64 ya tuvo que endurecer el SMTP de la línea base.

### 2.2 Recuperación por correo frente a correo como factor

Las dos cosas son distintas, y así lo trata la referencia del sector (OWASP ASVS 4.0.3, V2.5.6 y V2.5.7):
- **Un factor** se usa en cada inicio de sesión y da acceso completo.
- **Una vía de recuperación** se usa rara vez. Debe acreditar la identidad al menos al mismo nivel que en el alta, y su único efecto debe ser **volver a dar de alta un factor**, sin entregar una sesión útil.

Una vía de recuperación por correo es **compatible con ADR-81** si cumple las seis condiciones siguientes. Si falta cualquiera, se convierte en el factor descartado:
1. **El correo nunca da acceso solo:** exige además la contraseña.
2. **Sesión restringida:** el token resultante no lleva `otp` en `amr` y solo admite las rutas del alta (como el token restringido de P-81A-10). No entra a ninguna empresa ni a ninguna ruta `/api/super`.
3. **Espera obligatoria** (por ejemplo, 24 h) con aviso a todos los SUPER, que pueden cancelarla. La espera es lo que compensa que el correo no sea un factor independiente.
4. **El factor actual sigue valiendo durante la espera.** Si el SUPER entra con su TOTP o con un código de respaldo, la solicitud se cancela sola. Así nadie puede bloquear a un SUPER pidiendo una recuperación.
5. **Nunca en el perfil Avanzado (FIPS)**, por la razón del descarte.
6. **La dirección de correo está protegida por el sello de habilitación** (ADR-83). Si no, quien pueda escribir en `GPOS_SYSDATA` por SQL cambia la dirección y se apodera de la cuenta, que es justo lo que cerró SEG-L2-06.

### 2.3 Qué hay que precisar en lo firmado y qué rompe

| Documento | Qué se precisa | Qué rompe |
|---|---|---|
| **ADR-81, punto 7** | Se agrega una vía entre (a) y (b), con el orden de las vías | Nada en el código: es una vía nueva |
| **ADR-81, alternativas descartadas** | Nota: «el correo sigue descartado como factor; la recuperación de la precisión X es otra cosa» | Nada |
| **ADR-81, punto 12** | Nuevos eventos en `BitacoraSeguridad` | Nada (catálogo aditivo, como DL-04) |
| **ADR-83, puntos 1 y 6** (solo opciones B y C) | El sello del SUPER cubre también la huella de su dirección de recuperación | Volver a sellar a los SUPER al desplegar (lo hace `sellos --resellar` o el alta de la dirección) |
| **ADR-64** (B y C) | Avanzada desactiva la vía | Nada |
| **ADR-59, punto 6** | Clase de licencia `Esencial` para la ruta de la sesión restringida, como C-5 y P-81A-17. Las rutas anónimas no pasan por la licencia | Nada |
| **ADR-44 / I-18** (B y C) | Hay una credencial SMTP nueva por instalación en `GPOS_SYSDATA`, cifrada con Data Protection | Nada, si se cifra (es igual que la de la empresa) |

Con la opción **D**, no se tocan ni ADR-83 ni ADR-64 ni ADR-44: no hay dirección ni SMTP.

---

## 3. Opciones

### Lo que hay hoy en el código (verificado)

- **El correo es solo de empresa.**
  - `ConfigCorreo` (tabla `NotificacionesCorreo`, una fila, contraseña cifrada) y `CorreoCola` están en la base de empresa: `origin/c/adr81-fase-a:src/GPOS.Core/Data/Empresa/Notificaciones.cs:4-17, 44` y `EmpresaDbContext.cs:113-115, 331-334`. Lo mismo ocurre en `origin/feature/modelo-ng` y en `origin/master`.
  - El envío usa MailKit 4.18.1 con `EnviadorMailKit`, con TLS directo en el 465 y STARTTLS obligatorio cuando se pide cifrado: `src/GPOS.Core/Servicios/Correo/EnviadorCorreo.cs:21-38`.
- **No hay SMTP del sistema.**
  - No encontré ninguna configuración de correo en `GPOS_SYSDATA`: busqué `correo`, `email` y `smtp` en `src/GPOS.Core/Data/Sistema` y `src/GPOS.Core/Sistema` de `c/adr81-fase-a`.
- **El usuario del sistema no tiene correo.**
  - La clase `Usuario` (`SistemaDbContext.cs:115-145`) tiene código, descripción, nivel, hash, sesión y `SelloSeguridad`, pero ninguna dirección.
- **La verificación de artefactos firmados por GSF ya existe.**
  - `GPOS.Criptografia.Jws` y `GPOS.Criptografia.Llaves`, usados por `AutorizacionRegresoNivel` (`src/GPOS.Core/Sistema/Licencia/AutorizacionRegresoNivel.cs:1-60`). Esa autorización también está ligada a instalaciones y tiene ventana y causas de catálogo cerrado.
- **No se puede usar el SMTP de una empresa para el SUPER.** El SUPER es global, y el SMTP de una empresa lo configura su ADMIN. Si el enlace del SUPER viajara por un servidor que controla el ADMIN, el ADMIN podría leerlo. Eso equivale a «restablecimiento por el ADMIN», que está descartado. **Las opciones B y C necesitan un SMTP del sistema nuevo**, que configura solo el SUPER.

### Opción A. No agregar la vía; mejorar la guía de la vía (b) y la prevención

- **Qué es:**
  - Se dejan las vías tal como están.
  - Guía de una página para el agente de GSF: guardar los códigos de respaldo fuera del teléfono (gestor de contraseñas de GSF o sobre en la caja de GSF), dar de alta el TOTP en **dos** dispositivos al hacer el alta, y procedimiento de la vía (b) con lista de comprobación.
  - El aviso P-81A-07 (menos de dos SUPER con factor) pasa a la portada del SUPER.
- **Riesgos:** ninguno nuevo. Se mantiene el costo operativo de (b) en el caso extremo.
- **Costo:** unos 0,05 sp (guía) y 0 sp de código.

### Opción B. Enlace por correo enviado por el sistema, con espera y avisos (lo que usted propuso)

- **Flujo:**
  1. En la pantalla del factor, «No tengo mi teléfono ni mis códigos». El SUPER escribe su usuario y su contraseña.
  2. Si la contraseña es correcta y la cuenta tiene una dirección de recuperación verificada, se crea la solicitud. **La respuesta es siempre la misma**, exista o no la cuenta, para no revelar nada (ASVS V2.2 y V3).
  3. Se envía un aviso **inmediato** a la dirección del SUPER y a todos los demás SUPER de la instalación, con un enlace de **cancelación**. Además, aparece un aviso en la próxima entrada de cada SUPER y queda un evento `A` en la bitácora.
  4. **Espera obligatoria de 24 h.** Si en ese tiempo el SUPER entra con su TOTP o con un código de respaldo, o si alguien cancela, la solicitud se anula.
  5. Al terminar la espera se envía el **enlace de un solo uso**: token de 256 bits del CSPRNG, solo se guarda su hash, vida de 30 minutos.
  6. El enlace más la contraseña abren la **sesión restringida al alta**: QR, verificación del primer código y 10 códigos de respaldo nuevos. Al confirmar el alta:
     - se vuelve a sellar la cuenta (ADR-83, I-16);
     - se renueva `SelloSeguridad`;
     - se cierran todas las sesiones;
     - se registra un evento `A`.
- **Límites:** una solicitud activa por SUPER; 3 por cada 30 días; 10 por minuto e IP en la solicitud; solo en la central (`SoloCentral`), **nunca en un nodo**; **nunca en Avanzada**.
- **Dirección de recuperación:**
  - **Origen:** la escribe el propio SUPER en «Mi segundo factor», y debe ser una dirección de GSF (dominio configurable por GSF). No se carga desde la licencia ni la escribe un ADMIN.
  - **Cambio:** solo el propio SUPER, con autenticación reciente (`401 REAUTENTICAR`, punto 14). La nueva dirección se verifica con un código enviado a ella. Se avisa a la anterior. La nueva **no sirve para recuperar durante 72 h**, para que una sesión robada (A-06) no pueda cambiarla y usarla enseguida.
  - **Sello:** la huella SHA-256 de la dirección entra en el sello de habilitación del SUPER (precisión de ADR-83). Si se cambia por SQL, la cuenta no entra (`CamposNoCoinciden`) y la vía queda muerta.
  - **Vía (b):** el comando borra la dirección y puede fijar una nueva.
- **SMTP del sistema:**
  - Una fila nueva en `GPOS_SYSDATA` con MAC (como las filas protegidas de la licencia), contraseña cifrada con Data Protection y un propósito nuevo, y TLS obligatorio (ADR-64, punto 8).
  - La configura **solo el SUPER**, con autenticación reciente y aviso a todos los SUPER cuando cambia.
  - **No se usa** el SMTP de ninguna empresa.
  - Opción de despliegue: un relé de GSF con una credencial **por instalación**, que se pueda revocar. No conviene una credencial común en todas las instalaciones.
- **Riesgos:**
  - **Correo del SUPER comprometido junto con su contraseña** (*phishing* que captura las dos, o contraseña reutilizada): el atacante obtiene la cuenta **si nadie cancela en 24 h**. Los avisos van también a un buzón que el atacante puede vaciar, así que la defensa real son **los demás SUPER**. Riesgo residual: Medio. Se mitiga con la espera, el aviso en la entrada y el tope de 3 cada 30 días; lo demás se acepta.
  - **Inutilidad práctica:** si el buzón de GSF tenía su propio segundo factor en el teléfono perdido, el SUPER tampoco puede leer el correo. Así, la vía falla justo en el caso para el que existe, salvo que el correo de GSF tenga otra forma de recuperación.
  - **El administrador del relé SMTP lee el enlace.** Por eso el enlace nunca basta solo (contraseña más espera).
  - **Superficie nueva:** una credencial SMTP por instalación, rutas anónimas nuevas y un nuevo dato personal (la dirección) en `GPOS_SYSDATA`.
  - **Un SQL escribiendo el SMTP** podría desviar los enlaces a un servidor propio. Se mitiga con la MAC de la fila; sin ella el riesgo es Alto.
- **Costo (inferido, ±30 %):** **≈ 2,4 sp**.
  - SMTP del sistema y su pantalla: 0,35
  - Dirección, verificación, cambio y sello: 0,3
  - Solicitud, espera, cancelación, límites, avisos y eventos: 0,8
  - Sesión restringida, reutilizando el alta pendiente: 0,2
  - Web: 0,25
  - Pruebas: 0,4
  - Guía: 0,1
  - Además: el relé de GSF, si se elige ese despliegue (≈ 0 a 10 USD al mes según el proveedor; **inferido**, sin cotizar).

### Opción C. La misma opción B, con la aprobación de un segundo humano

- **Variante C1, otro SUPER aprueba:** es **redundante**. Si hay otro SUPER disponible, puede usar la vía (a) en dos minutos. La C1 no cubre el hueco del punto 1.
- **Variante C2, código de GSF:** además del enlace, el SUPER debe pegar un código firmado por GSF. Así el correo **no aporta seguridad**, porque el código de GSF ya acredita la identidad. Queda solo como un canal de aviso más. Equivale a la opción D con un SMTP de más.
- **Costo:** ≈ 2,8 sp (B más 0,4).
- **Conclusión:** se descarta. Tiene todo el costo de B y no agrega nada frente a (a) o frente a D.

### Opción D (recomendada). Autorización de recuperación firmada por GSF, ingresada en la Web

- **Flujo:**
  1. El SUPER llama a GSF. GSF lo identifica por su propio protocolo (llamada de vuelta al número de la ficha del empleado o videollamada con un responsable). Si lo acredita, **emite un JWS**:
     - tipo `autRecuperacionFactor`;
     - `instalacion` = `InstalacionId`, `usuario` = código del SUPER, `jti` aleatorio;
     - `iat` y `exp` con un máximo de 24 h;
     - `causa` de catálogo cerrado;
     - firmado con la llave de GSF del nivel que corresponda: Básico con TPM o Avanzado con YubiKey (ADR-62).
  2. GSF se lo entrega por **cualquier canal**: correo de GSF, mensaje o dictado. **El correo es de GSF, no del sistema:** la instalación no envía nada.
  3. En la pantalla del factor, «Tengo una autorización de GSF». El SUPER escribe su usuario, su contraseña y la autorización.
  4. La API comprueba la firma, la instalación, el usuario, la vigencia contra el reloj protegido y que el `jti` **no se haya usado**. Luego abre la **sesión restringida al alta**, igual que en B, paso 6.
  5. Avisos y registro: aviso inmediato en la entrada de todos los SUPER, evento `A` en la bitácora con el `jti` y la causa, y el `jti` queda consumido.
- **Por qué no hace falta la espera de 24 h:** el control humano lo hace GSF al acreditar la identidad. El artefacto no sirve sin la contraseña y vale solo para una instalación y un usuario.
- **Avanzada:** sirve igual. Es el mismo tipo de autorización que (b+) ya exige en Avanzada para el comando (punto 7) y que el punto 11 usa para el SUPER en un nodo aislado. **Conviene que (b+), el punto 11 y D compartan un mismo formato**, para construirlo una sola vez.
- **Riesgos:**
  - **Un insider de GSF con la llave** y la contraseña del SUPER podría tomar la cuenta. Ese riesgo ya está aceptado en (b+) y en la licencia (A-09 es su par en el servidor). Se mitiga con el evento `A` visible a todos los SUPER, el `jti` de un solo uso y la vigencia corta.
  - **Si el SUPER olvidó también la contraseña,** no sirve: queda la vía (b).
  - **Depende del emisor de GSF:** si nadie de GSF con la llave está disponible, queda (b), igual que hoy.
- **Costo (inferido, ±30 %):** **≈ 1,0 sp en el núcleo**.
  - Verificador del tipo nuevo, reutilizando `GPOS.Criptografia.Jws`: 0,25
  - Registro de los `jti` consumidos en `GPOS_SYSDATA`: 0,1
  - Ruta y sesión restringida: 0,25
  - Web: 0,15
  - Eventos y avisos: 0,05
  - Pruebas: 0,2
  - Además, en el emisor de GSF (fuera del núcleo): ≈ 0,3 a 0,5 sp, que **se comparten con (b+)** (0,4 sp ya presupuestados en la fase B).
  - Sin costo mensual.

### Comparación

| | A | B (correo del sistema) | C | **D (firma de GSF)** |
|---|---|---|---|---|
| Evita al técnico en el servidor | No | Sí | Sí | **Sí** |
| Compatible con el descarte del correo de ADR-81 | Sí | Con las seis condiciones de 2.2 | Igual que B | **Sí, sin condiciones** |
| SMTP nuevo en `GPOS_SYSDATA` | No | Sí | Sí | **No** |
| Avanzada (FIPS) | — | No | No | **Sí** |
| Sirve si el correo de GSF dependía del teléfono perdido | — | **No** | No | **Sí** |
| Toca ADR-83 (sello) | No | Sí | Sí | **No** |
| Tiempo hasta recuperar | Horas o días | 24 h o más | 24 h o más | **Minutos tras la llamada a GSF** |
| Costo en el núcleo | ≈ 0,05 sp | ≈ 2,4 sp | ≈ 2,8 sp | **≈ 1,0 sp** |
| Costo mensual | 0 | 0 a 10 USD (relé, inferido) | Igual | 0 |

---

## 4. Riesgos de seguridad (análisis del Arquitecto Maestro, referencia OWASP ASVS)

No pude lanzar al auditor-seguridad desde esta sesión. El análisis es mío y **conviene que el auditor lo confirme antes de construir T-j2** (ver la sección 7). Numeración de **ASVS 4.0.3**: V2 = autenticación, V6 = criptografía almacenada. En ASVS 5.0 la autenticación pasó al capítulo V6, con requisitos equivalentes sobre la recuperación (6.4.x). La numeración de 5.0 no la verifiqué en esta sesión.

| Requisito ASVS | Qué exige | B (correo) | D (firma de GSF) |
|---|---|---|---|
| **V2.5.6** | Recuperación por un mecanismo seguro (TOTP, token, mecanismo fuera de línea) | Débil: el correo no es uno de los ejemplos. La compensan la espera y los avisos | Cumple: artefacto firmado y fuera de línea |
| **V2.5.7** | Perdido el factor, acreditar la identidad **al mismo nivel que en el alta** | Discutible: el alta del SUPER exige una contraseña inicial que da GSF; el correo no acredita a la persona | Cumple: GSF acredita a su propio agente, como al crear la cuenta |
| **V2.5.1 / V2.3.1** | Secretos de recuperación aleatorios, de vida corta y nunca en texto plano | Token de 256 bits del CSPRNG, solo su hash, 30 min | JWS con `exp` ≤ 24 h y `jti` de un solo uso |
| **V2.2.1** | Defensa contra la automatización | 3 cada 30 días, 10 por minuto e IP, respuesta uniforme | Comparte el contador de intentos del factor |
| **V2.2.3** | Avisar tras los cambios de autenticación | Correo y aviso en la entrada a todos los SUPER | Aviso en la entrada a todos los SUPER y bitácora `A` |
| **V2.7.2 / V2.7.3** (fuera de banda) | Vida corta y un solo uso | Se cumple | No aplica (no es un canal fuera de banda del sistema) |
| **V6.2.1 / V6.2.2** | Algoritmos aprobados y falla segura | El SMTP queda fuera del límite FIPS: por eso se excluye Avanzada | Verificación con las llaves y algoritmos de ADR-62: cumple en los dos perfiles |
| **V6.3.1** | Aleatorios del CSPRNG | Token del CSPRNG | `jti` del emisor; la API solo lo consume |
| **V6.4.1 / V6.4.2** | Custodia de secretos y llaves | Credencial SMTP con Data Protection y fila con MAC | Sin secretos nuevos en la instalación |

**Hallazgos (severidad según C3):**
- **R-1 (Alta en B, si falta la mitigación):** dirección de recuperación fuera del sello. Un SQL con escritura la cambia y se apodera de la cuenta. Con la precisión de ADR-83 queda en Baja. No aplica en D.
- **R-2 (Alta en B, si falta la mitigación):** fila del SMTP del sistema sin MAC. Un SQL con escritura desvía los enlaces. Con la MAC queda en Baja. No aplica en D.
- **R-3 (Media en B, residual):** buzón y contraseña comprometidos, sin que nadie cancele en 24 h. Debe aceptarse por escrito si se firma B. En D, su par es la contraseña más un JWS robado del canal de entrega dentro de su vigencia: Baja, porque el JWS lleva un `jti` y una vigencia corta, y el SUPER llamó a GSF minutos antes.
- **R-4 (Media en B y D):** sesión restringida mal acotada. Si deja usar una ruta que no sea la del alta, la vía se convierte en un factor de un solo uso. Mitigación: lista blanca de rutas y una prueba que recorra todas las rutas `/api/super` y `/api/empresas/*` con ese token y espere 401.
- **R-5 (Baja en B):** bloqueo por solicitudes repetidas. Mitigado porque la solicitud no inhabilita el factor actual (condición 4).
- **R-6 (Baja en D):** pérdida de disponibilidad si GSF no tiene a nadie con la llave a mano. Queda la vía (b), igual que hoy.

Sin pasos de explotación, conforme a C10.

---

## 5. Recomendación

**Recomendación: Aprobar con observaciones la opción D.** Queda el correo de GSF como canal de entrega, y la instalación no envía correos.

| Pregunta del principio rector | Respuesta |
|---|---|
| **Qué rompe** | Nada del comportamiento actual. Se agrega una vía entre (a) y (b) y una ruta anónima nueva. Las vías firmadas no cambian, y la vía (b) sigue como último recurso con P-81A-15 (a). |
| **A quién afecta** | Solo a los agentes de GSF que tienen el nivel SUPER y al emisor de GSF, que debe saber emitir el tipo nuevo. Los clientes no lo ven. |
| **Por qué se justifica** | Cubre el caso que hoy obliga a un técnico en el servidor y deja al SUPER fuera durante horas o días. No reabre el descarte del correo. Sirve en Básica y en Avanzada. Cuesta menos de la mitad que B y no agrega SMTP, dirección ni credenciales a la instalación. Comparte el formato con (b+) y con el punto 11, que ya están firmados. |
| **Cómo se migra** | No hay datos que migrar. Una tabla nueva de `jti` consumidos, creada por `EsquemaSegundoFactor` (P-81A-03) y luego por `GPOS.Migracion sistema`, en SQL idempotente. Sin clientes en producción no hay sesiones que migrar. El emisor de GSF recibe el tipo nuevo antes de que la vía se publique. |

**Orden de las vías del SUPER que queda en ADR-81, punto 7:**
1. un **código de respaldo** propio (punto 6);
2. **(a) otro SUPER**;
3. **(a′) autorización de recuperación firmada por GSF**, ingresada con la contraseña, que solo abre el alta de un factor nuevo (opción D);
4. **(b) comando `GPOS.Migracion restablecer-factor` en el servidor**, de último recurso, que también cubre el olvido de la contraseña. En Avanzada sigue con (b+).

**Observaciones de la recomendación:**
- O-1. Se agrega la guía de la opción A (≈ 0,05 sp): dos dispositivos en el alta, códigos de respaldo guardados fuera del teléfono y aviso P-81A-07 en la portada. Es lo que más reduce la frecuencia del problema.
- O-2. (b+), el punto 11 y (a′) comparten **un solo formato** de autorización de GSF, con el tipo en un campo `crit`, como `autNivel`.
- O-3. La sesión restringida reutiliza el token restringido de P-81A-10 (alta pendiente). No se crea un tercer tipo de token.
- O-4. La nota en las alternativas descartadas de ADR-81 dice: «el correo sigue descartado como factor y como canal de la instalación; GSF puede usarlo para entregar la autorización de (a′), que sin la contraseña no da acceso».

**Si usted prefiere la opción B** (que el sistema envíe el correo), mi recomendación pasa a **«Aprobar con observaciones», con estas condiciones, que no se pueden negociar:**
- las seis condiciones de 2.2;
- R-1 y R-2 mitigadas;
- aceptación escrita de R-3;
- solo en Básica.

**Costo total:**
- **opción D:** ≈ 1,0 sp en el núcleo, más ≈ 0,3 a 0,5 sp del emisor, compartidos con (b+), más 0,05 sp de guía;
- **opción B:** ≈ 2,4 sp más el relé.

En los dos casos, ±30 %. La fase A sigue en ≈ 7,8 sp (blueprint v4, línea 520): T-j2 va aparte y no la cambia.

---

## 6. Casillas de firma

**R-COR-01. ¿Se agrega una vía de recuperación del SUPER antes del comando en el servidor?**
☐ **(D) Sí, con una autorización firmada por GSF ingresada en la Web (recomendada)**
☐ (B) Sí, con un correo que envía el sistema, solo en Básica, con espera de 24 h y las condiciones de 2.2
☐ (C) Sí, como B más la aprobación de otro SUPER o de un código de GSF
☐ (A) No; solo se mejora la guía

**R-COR-02. Orden de las vías del punto 7 de ADR-81** (solo si se marca D, B o C)
☐ Códigos de respaldo → (a) otro SUPER → (a′) vía nueva → (b) comando **(recomendado)**
☐ Otro orden: ____________

**R-COR-03. Guía y prevención (opción A como complemento)**
☐ Sí: dos dispositivos en el alta, códigos de respaldo fuera del teléfono y aviso P-81A-07 en la portada **(recomendado)**
☐ No

**R-COR-04. Formato único de las autorizaciones de GSF** para (b+), el punto 11 y (a′) (solo con D)
☐ Sí **(recomendado)** ☐ No

**R-COR-05. Solo si se marca B o C: aceptación escrita del riesgo R-3** (buzón y contraseña comprometidos sin que nadie cancele en 24 h)
☐ Acepto el riesgo residual R-3 ☐ No lo acepto (entonces no se construye B ni C)

**Número de ADR:** no hace falta uno nuevo. Es una precisión de ADR-81 (punto 7, punto 12 y las alternativas descartadas) y de ADR-59 (punto 6, clase `Esencial` de la ruta restringida). Con B o C, también de ADR-83 (puntos 1 y 6) y de ADR-64.

**Texto sugerido para firmar:**
> «Firmo R-COR-01 (D), R-COR-02, R-COR-03 y R-COR-04 según la recomendación.»

Si prefiere el correo del sistema:
> «Firmo R-COR-01 (B) solo en Básica, R-COR-02, R-COR-03 y R-COR-05: acepto el riesgo R-3.»

---

## 7. Orden de construcción

1. **Ahora, sin cambios:** T-j (vía b con P-81A-15 (a)) y T-m (clases de licencia con P-81A-17 (a)) siguen como están. La vía nueva **no** entra en esas tandas.
2. **Después de la firma: revisión del auditor-seguridad** del diseño de (a′) o de B (≈ 0,1 sp). Que confirme o corrija la sección 4, y sobre todo R-4.
3. **El arquitecto-software agrega T-j2 al blueprint de la fase A** (v4.1), con su contrato:
   - ruta anónima `POST /api/auth/login/recuperacion` (o `.../recuperacion/solicitar` con B);
   - lista blanca de la sesión restringida;
   - tabla de `jti` consumidos;
   - eventos `RECUPERACION_*` en el catálogo de `BitacoraSeguridad`;
   - códigos de error en el rango de `GPOS_SYSDATA`: los 52001 a 52019 ya están reservados para la fase A, y el arquitecto asigna los nuevos.
4. **Construcción de T-j2:** depende de T-g (inicio de sesión en dos pasos), T-j, T-m y T-p (Web del SUPER). Dos opciones:
   - como **última tanda de la fase A**, si entra en el calendario antes del corte de mediados de diciembre;
   - si no entra, **en la fase B, junto con (b+)**, porque comparten el formato. El caso extremo sigue cubierto por la vía (b).
   - No debe retrasar la unión de la fase A ni la ola 5.
5. **El emisor de GSF**, fuera del núcleo: tipo `autRecuperacionFactor` y protocolo de acreditación del agente (≈ 0,3 a 0,5 sp, compartidos con (b+)).
6. **Guía O-1:** junto con T-p.
7. **Registro:** el documentador-tecnico registra la precisión en `master` (ADR-81 y ADR-59) cuando esté firmada.

---

## Supuestos

- Según el encargo, P-81A-15 a 17 se firmaron hoy en la opción (a). No lo verifiqué en el repositorio: el documento de preguntas de la rama `c/adr81-fase-a` todavía dice «pendientes de firma», y `master` no lo registra aún.
- Costos inferidos con un margen de ±30 %. El del relé SMTP no está cotizado.
- La frecuencia del caso extremo es desconocida: no hay clientes en producción.
- Doy por hecho que el emisor de GSF puede firmar un tipo nuevo de autorización con las llaves de ADR-62. No revisé el código del emisor, que está fuera de este repositorio.
- Numeración de ASVS 4.0.3. Las equivalencias con 5.0 no están verificadas.

### Cierre
- Estado: Completado (hoja preparada; pendiente de firma del propietario)
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\GPOS-C-hoja-recuperacion-correo-super.md`
- Supuestos: los de la sección anterior
- Decisiones candidatas a ADR: precisión de ADR-81, punto 7 (vía a′), punto 12 (eventos) y alternativas descartadas (nota); precisión de ADR-59, punto 6 (clase `Esencial`); con B o C, también de ADR-83 (sello con la dirección) y de ADR-64 (vía excluida en Avanzada)
- Entregas a otros agentes: auditor-seguridad → revisar la sección 4 y R-4 antes de T-j2; arquitecto-software → T-j2 en el blueprint v4.1; documentador-tecnico → registrar la precisión firmada; GSF (emisor) → tipo `autRecuperacionFactor` con un formato común con (b+)
- Próximo paso recomendado: que el propietario firme R-COR-01 a 04 (o 05, si elige B)
