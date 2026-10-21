# Revisión de seguridad del ADR-93 (tarjetas de Artículos, foto por artículo y banco de imágenes)

- **Fecha:** 2026-10-21 · **Revisor:** auditor-seguridad (equipo A) · **Encargo:** B, `avisos/B-a-A/2026-10-21-asignaciones-s03-s07-y-revision-adr93.md`, Tarea 2
- **Modo:** solo lectura. No se modificó código ni documentos del repositorio. No se ejecutaron compilaciones ni pruebas.
- **Fuentes:** `origin/b/adr93-tarjetas-foto` (`docs/adr/ADR-093.md` y `docs/decisiones/2026-10-21-hoja-firma-tarjetas-articulos.md`) y `origin/feature/modelo-ng` `fc7f07f2` (2026-10-21 11:31) para el código existente.
- **Convención de evidencia:** [V] verificado en `archivo:línea`; [I] inferido o pendiente de comprobar. Los números de línea del ADR son los de `git show ...:docs/adr/ADR-093.md`.
- **Alcance:** es una revisión de diseño. Lo que aquí se marca como [V] es el texto del ADR o el código existente que se reutilizará. No hay código de E-2 que revisar.

## 1. Alcance y superficie revisada

| Superficie | Cláusula | Exposición |
|---|---|---|
| Configuración de la raíz del banco (ADMIN y SUPER), lista de bases permitidas (solo SUPER) | TB-03 (ADR:80-91) | administrativa, autenticada |
| Sondeo del banco y correo al ADMIN | H-1 (ADR:92-98) | trabajo de fondo y correo saliente |
| `GET /api/maestros/articulos/{id}/foto`, proxy Web y subida o quitar | TB-04, TB-05 (ADR:99-114) | autenticada; el contenido del banco no es de confianza |
| Asignación masiva, lista de ambiguos e informe CSV | TB-10 (ADR:148-154) | ADMIN y SUPER |
| Copia del banco en el nodo | TN-01 a TN-03 (ADR:170-203) | canal nodo-central (entrega 2) |
| Alcance de almacenes para el usuario restringido | TB-07, TA-P08 (ADR:122-126) | autenticada |

**Fuera de alcance:** TB-06, TB-08, TB-09 y TB-11 se leyeron, pero sin revisión profunda (ver la sección 5). La resiliencia del sondeo solo se trata en lo que afecta a la seguridad.

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título | Tema |
|---|---|---|---|
| S-01 | Media | La subcarpeta del ADMIN es texto libre y no se fija el orden «validar antes de tocar el disco»: riesgo de solape, de carpetas del sistema y de que la API autentique contra un host UNC no permitido | TB-03 |
| S-02 | Media | Adoptar una carpeta ya existente (con marca ajena, sin marca o con contenido) y volver a marcarla anula el valor de la marca HMAC | TB-03 |
| S-03 | Media | La comprobación de enlaces y uniones sigue la secuencia «comprobar y después abrir» (TOCTOU), sobre todo al escribir. En UNC su alcance es limitado | TB-03, TB-04, TB-05 |
| S-04 | Media | La guarda de carpetas del sistema solo mira «dentro de», no «contiene a», y no se aplica a las bases que agrega el SUPER | TB-03 |
| S-05 | Media | No está definido quién escribe en el banco (carga a mano, escaneo) frente a la DACL de ADR-77 | TB-03, TB-10 |
| S-06 | Media | Hoy `BitacoraSeguridad` solo la ve el SUPER, y `Detalle` (400) no alcanza para la raíz anterior y la nueva. Tampoco se registran los intentos rechazados | TB-03 |
| S-07 | Baja | El cambio de raíz no exige autenticación reciente | TB-03 |
| S-08 | Media | Correo H-1: la causa debe ser una lista cerrada, sin `ex.Message`, y la «ruta relativa» no debe salir de recortar la ruta absoluta | H-1 |
| S-09 | Baja | El SMTP de la empresa admite enviar sin TLS. Un UNC caído puede bloquear el sondeo de las demás empresas | H-1 |
| S-10 | Media | El ADR no fija la matriz de permisos de la foto, de la subida, de la asignación masiva y de la lista de ambiguos | «TN-02» del encargo |
| S-11 | Media | El CSV del informe puede llevar inyección de fórmulas y caracteres de control o bidi en los nombres rechazados | TB-10 |
| S-12 | Media | El proxy Web actual no conserva `nosniff` ni la CSP y sirve como `attachment` todo lo que no sea PDF | TB-04 |
| S-13 | Baja | El servidor no puede confiar en que el cliente quitó el EXIF ni en que el archivo no es un políglota | TB-04, TB-12 |
| S-14 | Baja | La subida puede sobrescribir en silencio un archivo puesto a mano que aún no está asignado | TB-05 |
| S-15 | Media | Entrega 2: pedir medios por huella sin acotar por la empresa del nodo daría acceso entre tenants | TN-01, TN-02 |
| S-16 | Media | TA-P08 solo filtra la tarjeta: las rutas de existencias y de kárdex entregan las de todas las sucursales al mismo usuario | TA-P08 |
| S-17 | Media | La restricción no viaja en el token: hay que leerla del servidor y fallar cerrado | TA-P08 |

No hay hallazgos Críticos ni Altos **siempre que** S-01 a S-05 se cumplan como condición de construcción de E-2. Si E-2 se construyera con la subcarpeta libre y con E/S antes de validar (S-01), el riesgo sería **Alto**.

## 3. Checklist OWASP Top 10 (2021), aplicado al diseño

| Categoría | Estado | Nota |
|---|---|---|
| A01 Control de acceso | Observaciones | S-10 (matriz de permisos), S-15 (tenant en el canal de medios), S-16 y S-17 (alcance por sucursal). La empresa sale del token (ADR:90) [V] |
| A02 Fallas criptográficas | Observaciones | Marca HMAC derivada de Data Protection: falta definir la codificación y el procedimiento de volver a marcar (S-02). SHA-256 en la huella (ADR:74) [V] |
| A03 Inyección | Observaciones | CSV (S-11). El color de la categoría se valida dos veces (ADR:145) [V]. La ruta pasa una lista blanca y un `CHECK` (ADR:75, 101) [V] |
| A04 Diseño inseguro | Observaciones | S-01, S-02, S-05 |
| A05 Configuración de seguridad | Observaciones | S-04, S-12 (encabezados en el proxy), S-09 (SMTP sin TLS) |
| A06 Componentes vulnerables | No aplica | El ADR no agrega librerías (TA-05, ADR:58) [V]. MailKit 4.18.1 ya está en la solución (según ADR:93) |
| A07 Autenticación | Observaciones | S-07 (autenticación reciente) |
| A08 Integridad de software y datos | Observaciones | S-03 (TOCTOU), S-13, S-14. El nodo verifica la huella y la firma (ADR:175) [V] |
| A09 Registro y monitoreo | Observaciones | S-06 (alcance, tamaño y rechazos), S-08 (sin detalles internos en el correo) |
| A10 SSRF | Observaciones | La variante local de SSRF es que la API acceda a un UNC que elige un usuario (S-01). A Chromium nunca se le pasa una URL (ADR:158) [V] |

## 4. Hallazgos

### S-01 · Media (condición de construcción; sería Alta sin ella) · Subcarpeta libre y orden de validación de la raíz
- **Riesgo.** La guarda 1 dice que el ADMIN «elige su carpeta **dentro** de una base permitida, siempre con una subcarpeta propia de la empresa» (ADR:84 [V]). No dice que el nombre de la subcarpeta lo fije el servidor. Si el ADMIN escribe la subruta:
  - la comparación de solape (guarda 2, ADR:85) queda expuesta a formas equivalentes de la misma ruta: nombres cortos 8.3, `\\?\`, `\\.\`, punto o espacio final, flujos alternativos con `:`, y alias del mismo host UNC (NetBIOS, FQDN, IP, `localhost\c$`) [I];
  - si alguna comprobación de existencia (`Directory.Exists`, `GetFullPath` sobre UNC, creación) corre **antes** de verificar la lista blanca, la API se autentica con la cuenta de máquina contra un host que eligió el ADMIN. Eso expone la credencial a reenvío (relay) [I]. Sería un salto del ADMIN de una empresa a la identidad del servidor que comparten todas las empresas.
- **Evidencia.** ADR:84-85 [V]. ADR-67, punto 1, limita los hosts UNC a una lista (`ADR-067.md:10` [V]). Precedente correcto de contención por cadena con separador: `src/GPOS.Reportes/Exportacion/ComprobacionCarpetas.cs:144-149` [V].
- **Remediación (unos 0,25 d [I]).**
  1. El ADMIN **elige una base de la lista** (por su identificador, no por la ruta) y el servidor arma `<base>\<IdEmpresa>`, sin texto libre. Es compatible con TA-P07: el ADMIN sigue configurando la carpeta.
  2. Toda la validación es de cadena y sin E/S hasta que la base está en la lista. Después se canonicaliza abriendo el identificador (`GetFinalPathNameByHandle`) y se vuelve a comparar.
  3. El host UNC se compara contra la lista en forma canónica, y las bases no se pueden anidar entre sí. Esto último se valida cuando el SUPER agrega una base; si no, `B1\EMP02` coincidiría con una base `B2 = B1\EMP02`.
- **Defensa en profundidad.** La marca HMAC (guarda 4) detecta una carpeta ajena, pero no evita el acceso a la red. Por eso el orden de validación es lo que cierra el riesgo.

### S-02 · Media · Adopción de una carpeta existente y nueva marca
- **Riesgo.** La marca solo sirve si el sistema **no la vuelve a escribir** al configurar una carpeta que ya tiene contenido. La guarda 2 compara solo las raíces vigentes (ADR:85 [V]). La carpeta que otra empresa dejó al cambiar de raíz no está en esa lista. Si al configurar se escribe una marca nueva, el ADMIN adopta las fotos de otra empresa. Tampoco está definido qué pasa con la marca si se pierde o se restaura el anillo de Data Protection. Volver a marcar es la puerta natural para ese caso.
- **Evidencia.** ADR:87 («si la carpeta es de otra empresa o se movió, la marca no coincide y el banco no se usa») [V]. No hay un procedimiento de nueva marca en ADR:80-98 [V].
- **Remediación (unos 0,25 d [I]).**
  - El ADMIN solo puede crear la subcarpeta nueva (vacía) o volver a una que tenga una marca válida **para su empresa**.
  - Adoptar una carpeta no vacía sin marca, con una marca ajena o con una marca inválida es exclusivo del SUPER. Exige motivo, queda en `BitacoraSeguridad` con severidad A y requiere autenticación reciente.
  - Codificación del HMAC sin ambigüedad: `IdEmpresa` y la raíz canónica con prefijo de longitud o separador fijo, más una etiqueta de propósito y una versión.
  - La clave sale de un propósito propio de Data Protection, compatible con el perfil FIPS (HMAC-SHA256).

### S-03 · Media · Enlaces y uniones con TOCTOU, y la escritura
- **Riesgo.** «Se rechaza cualquier componente ... con punto de reanálisis ... al configurar y en cada apertura» (ADR:88, 102 [V]). Si se comprueba con `File.GetAttributes` y después se abre por ruta, una unión puesta entre los dos pasos redirige la lectura. El caso grave es la **escritura** (temporal y renombrado, ADR:112): la API escribiría un archivo que controla el usuario fuera del banco, con los permisos del servicio.
  - **UNC.** Una unión del lado del servidor remoto la resuelve ese servidor y puede no verse como punto de reanálisis desde la API [I, hay que probarlo]. En UNC, la garantía real es la ACL del recurso compartido más la marca.
  - **Enlaces duros.** Un enlace duro no es un punto de reanálisis [I].
- **Evidencia.** El patrón correcto ya existe: atributos y seguridad leídos del **mismo identificador**, abierto con `FILE_FLAG_OPEN_REPARSE_POINT` y sin `FILE_SHARE_DELETE`, y conservado abierto (`src/GPOS.Reportes/Exportacion/ComprobacionCarpetas.cs:99-129` y `:207-232` [V]; también `src/GPOS.AgenteImpresion/Estacion/ComprobacionCarpetas.cs:81,97` [V]).
- **Remediación (unos 0,5 d, reutilizando [I]).**
  - Abrir la raíz por identificador y retenerlo. Crear el temporal y renombrar **relativos al identificador** de la carpeta, o volver a comprobar el identificador del archivo abierto antes de escribir y de servir.
  - Rechazar los archivos con más de un enlace (`NumberOfLinks > 1`).
  - En Linux (ADR-129), `openat` con `O_NOFOLLOW`.
  - Documentar como riesgo residual aceptado que en UNC la protección depende de la ACL del recurso compartido.

### S-04 · Media · Carpetas del sistema: «contiene a» y bases del SUPER
- **Riesgo.** La guarda 3 rechaza la raíz «dentro de» la licencia, el anillo, `Render`, la instalación, `%windir%` y `%ProgramFiles%` (ADR:86 [V]). No rechaza una raíz que **contenga** esas carpetas: `C:\`, `C:\ProgramData`, `%ProgramData%\GPOS NG` o la raíz de una unidad o de un recurso compartido. El escaneo (TB-10) recorrería entonces la licencia y el anillo, y el informe listaría sus nombres. Tampoco se dice que las bases que agrega el SUPER pasen la misma guarda.
- **Remediación (unos 0,1 d [I]).** Aplicar los dos sentidos (dentro de y contiene a) a la raíz y a cada base. Rechazar la raíz de una unidad, la de un recurso compartido y los recursos administrativos (`C$`, `ADMIN$`). Con S-01, la guarda se aplica sobre todo al dar de alta las bases.

### S-05 · Media · Quién escribe en el banco frente a ADR-77 · **PREGUNTA-1**
- **Riesgo.** TB-10 y TB-12 dan por hecho que hay archivos «dejados a mano» en el banco y un escaneo de la carpeta (ADR:149, 165 [V]). ADR-77 prohíbe dar escritura a identidades amplias sobre la raíz (`ADR-077.md:13` [V]). También admite una subcarpeta escribible por Usuarios solo justificada y «nunca para datos que otro componente lea como confiables» (`ADR-077.md:18` [V]).
  - En la base por omisión (`%ProgramData%\GPOS NG\Imagenes`), solo los administradores del servidor pueden dejar archivos.
  - Si el cliente comparte la carpeta con escritura para Usuarios, la comprobación de escritores de ADR-77 la rechaza o habrá que relajarla.
  - Además, la raíz hereda la lectura de Authenticated Users (`ADR-077.md:12` [V]): cualquier usuario autenticado del servidor lee las fotos de todas las empresas. Es Baja, porque son fotos de catálogo.
- **PREGUNTA-1 (no reabre el ADR).** ¿Quién deja archivos en el banco? ¿Solo los administradores del servidor, o un grupo local dedicado (por ejemplo «GPOS Imágenes Editores»), admitido como escritor solo en el componente `Imagenes` y documentado en operaciones? Para las bases UNC del SUPER, la comprobación de DACL de ADR-77 no aplica. Hay que decir qué se exige.
- **Remediación.** Lo que se decida va al documento de operaciones (DevOps). El contenido del banco se trata siempre como no confiable, como ya hace TB-04 (ADR:103).

### S-06 · Media · Bitácora de seguridad: quién la ve, tamaño y rechazos
- **Riesgo.**
  1. «El ADMIN de la empresa ve sus eventos» (ADR:89 [V]), pero hoy la bitácora es **solo del SUPER**, de solo lectura (`src/GPOS.Api/Endpoints/AdminEndpoints.cs:347-355`, P-81A-05 [V]). La vista del ADMIN es nueva. Sin un filtro por `Empresa` y por tipo de evento, mostraría eventos de otras empresas y eventos globales.
  2. `Motivo` y `Detalle` son `nvarchar(400)` (`src/GPOS.Core/Consultas/Sistema/Restauracion/EsquemaRestauracionSistema.cs:35-38` [V]). La raíz anterior más la nueva (hasta unos 2 × 260 caracteres, más UNC) se trunca y se pierde la traza [I].
  3. Solo se registran los cambios. Los **intentos rechazados** (base no permitida, solape, sistema, reanálisis), que son la señal de abuso, no están previstos.
- **Remediación (unos 0,5 d [I]).**
  - Una ruta del ADMIN filtrada en el servidor por la empresa del token y por los eventos `BANCO_*`, que muestre la base por su alias y la subcarpeta, nunca el host de otra base.
  - Guardar el identificador de la base, la subcarpeta y una huella de la raíz canónica, en lugar de la ruta completa en `Detalle`.
  - Registrar los rechazos con severidad M.
  - El motivo, con longitud mínima y máxima y sin caracteres de control.

### S-07 · Baja · Autenticación reciente para cambiar la raíz
- **Riesgo.** Un token robado de un ADMIN podría redirigir el banco. El ADR no exige reautenticación.
- **Evidencia.** El mecanismo existe: `RequiereAutenticacionReciente` (`src/GPOS.Api/Seguridad/AutenticacionReciente.cs:36-43` [V]), usado en acciones administrativas (`AdminEndpoints.cs:209, 258, 285` [V]).
- **Remediación (unos 0,05 d).** Aplicarlo a configurar la raíz, a agregar bases y al modo de copia (TN-02). La ruta va con `Sitio(SoloCentral)`.

### S-08 · Media · Correo H-1 sin datos internos
- **Riesgo.** El contenido está bien cerrado en el texto (ADR:96 [V]), pero hay dos fugas típicas al construirlo:
  1. Poner en la causa, o en el error de `CorreoCola` que ve el ADMIN, el `Message` de la excepción. Los mensajes de `IOException` y `UnauthorizedAccessException` traen la ruta absoluta y el host UNC [I].
  2. Armar la «ruta relativa» (`Imagenes/EMP01`) recortando la ruta absoluta. Con una base UNC del SUPER, el recorte puede dejar el recurso compartido o el host.
- **Evidencia.** ADR:94 (categorías) y ADR:96 (contenido) [V]. El catálogo de eventos donde se agrega `BANCO_IMAGENES` está en `src/GPOS.Contracts/Admin/Notificaciones.cs:43-60` [V].
- **Remediación (unos 0,1 d).**
  - La causa es un enum de cuatro valores con textos fijos.
  - La ruta que se muestra es el **alias** de la base que define el SUPER, más `IdEmpresa`.
  - El asunto lleva solo el código y el nombre de la empresa.
  - Una prueba que construya el correo con raíces UNC y locales y que verifique que no aparecen `\\`, `:\`, el nombre del host ni el nombre de la máquina.
  - Los errores de envío de SMTP no se muestran al ADMIN con su texto crudo.

### S-09 · Baja · Transporte del correo y sondeo que se bloquea
- **Riesgo.**
  1. `EnviadorMailKit` usa `SecureSocketOptions.None` cuando la empresa no marca SSL (`src/GPOS.Core/Servicios/Correo/EnviadorCorreo.cs:39` [V]). El correo H-1 no lleva secretos, así que el impacto es bajo.
  2. `Directory.Exists` o la enumeración sobre un UNC caído pueden bloquearse más de 10 s sin respetar el `CancellationToken` [I]. Si el sondeo es secuencial, el banco caído de una empresa retrasa o anula el aviso de las demás.
- **Remediación.** Mostrar un aviso en la configuración de correo cuando no hay TLS (sin bloquear). Hacer el sondeo por empresa con un tiempo de espera que abandone la tarea bloqueada. Esto último es responsabilidad de arquitecto-integraciones y de qa-automatizado.

### S-10 · Media · Matriz de permisos de la foto y de la lista de ambiguos · **PREGUNTA-2**
- **PREGUNTA-2.** En el ADR, **TN-02** es «Integridad, espacio y ancho de banda» del nodo (ADR:174-186 [V]), no «permiso y alcance de la foto». Se revisaron las dos cosas: TN-02 en S-15 y los permisos aquí. Conviene que B confirme a qué se refería.
- **Riesgo.** El ADR fija los permisos del estado de medios (`articulos` Consultar, ADR:188 [V]) y quién ve las rutas relativas del informe (ADMIN y SUPER, ADR:107 [V]). No fija los de `GET .../foto`, la subida, quitar la foto, el lote desde el navegador, el escaneo ni la descarga del CSV. Sin una matriz, lo más probable es que todo herede el `RequierePermiso(Articulos)` del grupo (`src/GPOS.Api/Endpoints/TablasEndpoints.cs:35` [V]). Entonces quien solo consulta Artículos podría subir o quitar fotos, y quien edita Artículos podría lanzar el escaneo y ver la lista de ambiguos con rutas relativas de todo el banco.
- **Remediación (unos 0,25 d, con pruebas).**

  | Acción | Permiso mínimo propuesto |
  |---|---|
  | Ver la foto (`GET`, variantes `mini` y `foto`) | `Articulos` Consultar, empresa del token |
  | Subir o quitar la foto | `Articulos` con la acción de modificar |
  | Lote desde el navegador, escaneo, lista de ambiguos y CSV | ADMIN o SUPER de la empresa (TA-P07, TA-P09), `SoloCentral` |
  | Configurar la raíz | SUPER hasta DB-7 v1; después, ADMIN de la empresa (guarda 7), con autenticación reciente (S-07) |
  | Agregar bases | SUPER |
  | Modo de copia del nodo | ADMIN o SUPER (TA-P11), con motivo |

  Una prueba por ruta que dé 403 al nivel inferior. Toda caché de la raíz por empresa con clave `empresa`, y una prueba de que dos empresas con el mismo `ArticuloId` no se cruzan.

### S-11 · Media · CSV del informe de asignación masiva
- **Riesgo.** El informe (ADR:154 [V]) incluye los **rechazados**: los nombres de archivo que no pasan `^[A-Za-z0-9]...` (ADR:101), que pueden empezar con `=`, `+`, `-` o `@`, y descripciones que escriben los usuarios. Al abrirlo en una hoja de cálculo, esas celdas se interpretan como fórmulas. Quien puede dejar archivos en el banco controla esos nombres. También pueden traer caracteres de control o bidi (U+202E) que falsean lo que ve el ADMIN en la pantalla.
- **Evidencia.** La neutralización ya existe: `src/GPOS.Api/Impresion/ExportadorReporte.cs:199-212` (SP-06, SN-16) [V].
- **Remediación (unos 0,05 d).** Reutilizarla y mostrar los nombres rechazados con los caracteres de control y bidi escapados.

### S-12 · Media · Encabezados en el proxy Web
- **Riesgo.** `nosniff` y la CSP `sandbox` (ADR:104 [V]) se pierden si la Web reutiliza `ReenviarArchivoAsync`. Esa función reconstruye la respuesta y solo pone `Content-Disposition` (`inline` solo para PDF, `attachment` para lo demás) y `Cache-Control: no-store` (`src/GPOS.Web/Program.cs:187-207` [V]). Además, el ADR cita el patrón en `Program.cs:140-145`. En `feature/modelo-ng` está en `:174-176` [V], así que la cita es de otra rama.
- **Remediación (unos 0,25 d).**
  - Una ruta propia en la Web para la foto que acepte solo `image/jpeg`, `image/png` e `image/webp`. Cualquier otro tipo da 404.
  - Que ponga `X-Content-Type-Options: nosniff`, `Content-Security-Policy: sandbox; default-src 'none'`, `Content-Disposition: inline` y `Cache-Control: private, max-age=..., immutable`, posible gracias a la `v={ficha}`. Nunca `public`.
  - Que no reenvíe el detalle del error de la API: siempre 404.

### S-13 · Baja · EXIF y políglotas
- **Riesgo.** El EXIF lo quita el navegador al volver a codificar (ADR:163 [V]). Un cliente modificado puede subir un JPEG con EXIF (incluido el GPS) o con datos agregados después de `EOI`, porque el servidor solo lee el encabezado (ADR:103). Con `nosniff`, la CSP y el `Content-Type` sacado de la firma no se ejecuta en el navegador. Queda un riesgo de privacidad y de almacenamiento.
- **Remediación (unos 0,25 d, sin librería).** Recorrer los segmentos del JPEG y rechazar `APP1/Exif` y los datos después de `EOI`, con el mismo criterio de «no decodificar». En PNG y WebP, rechazar los fragmentos `eXIf` y `EXIF`.

### S-14 · Baja · Sobrescribir un archivo no asignado
- **Riesgo.** El 409 `FOTO_NOMBRE_OCUPADO` se da si «el nombre lo usa otro artículo» (ADR:111 [V]), es decir, si hay una fila en `cat.ArticuloImagen`. Un archivo que existe en el banco y aún no está asignado (dejado a mano) se reemplaza con el renombrado atómico (ADR:112). El cliente pierde su archivo, y GPOS no respalda el banco (TA-06).
- **Remediación (unos 0,1 d).** Si el archivo existe y su huella es distinta, responder 409 `FOTO_ARCHIVO_EXISTE`, salvo que se confirme reemplazar. Esa confirmación se deja a quien tenga el permiso del lote, a criterio del arquitecto.

### S-15 · Media (entrega 2) · Tenant en el canal de medios y en TN-02
- **Riesgo.** Los archivos «se direccionan por contenido» y se piden «por huella» (ADR:170 [V]). Si la central resuelve la huella contra cualquier banco, el nodo de la empresa A que conozca una huella de B obtiene la foto de B. El manifiesto también debe salir solo del banco de la empresa de la credencial del nodo (PT-05 de ADR-90).
- **Bien diseñado [V]:** el `.part` se verifica por tamaño, SHA-256 y firma, «la central también puede tener contenido plantado» (ADR:175). Al cambiar de modo se borra solo después de verificar (ADR:185), sin rutas.
- **Remediación (en E-5).** Buscar la huella **dentro del banco de la empresa de la credencial**, con 404 uniforme. Limitar las peticiones por nodo. La carpeta local del nodo pasa por la comprobación de ADR-77. `BytesRequeridos` y `BytesLibres` solo para el ADMIN (ADR:191) [V].

### S-16 · Media · TA-P08 no es una frontera de confidencialidad · **PREGUNTA-3**
- **Riesgo.** TA-P08 dice que el usuario restringido «solo debe ver» los almacenes de su sucursal (hoja:118 [V]). El ADR lo aplica a la tarjeta (ADR:124 [V]). El mismo usuario, con el permiso `Articulos`, obtiene hoy las existencias, mínimos y reorden de **todos** los almacenes por:
  - `GET /api/inventario/existencias` (`src/GPOS.Api/Endpoints/InventarioEndpoints.cs:91-93`, `RequiereAlgunPermiso(ReportesInventario, Articulos, Conteo)` [V]), cuyo servicio no filtra por sucursal (`src/GPOS.Core/Servicios/InventarioService.cs:723-735` [V]);
  - el kárdex de cualquier almacén (`InventarioEndpoints.cs:94-96` [V]).

  No se encontró ningún filtro por sucursal en las rutas de inventario de la API principal. La búsqueda de `RestringirSucursal` solo da resultados en Auth, Usuarios y GPOS.Reportes [V].
- **PREGUNTA-3 (no reabre el ADR).** ¿La intención del propietario es de **presentación** (que la tarjeta no confunda) o de **confidencialidad** (que el restringido no conozca las existencias de otras sucursales)?
  - Si es de presentación, el diseño de TB-07 basta.
  - Si es de confidencialidad, hay que aplicar el mismo alcance a esas rutas y a la pestaña Almacenes, que TA-P05 ya toca. Son de 1 a 1,5 d [I]. Es un cambio fuera del ADR-93 que conviene decidir antes de E-1.

### S-17 · Media · De dónde sale la restricción
- **Riesgo.** El ADR toma «la sucursal de la sesión» con `RestringirSucursal = 1` (ADR:124 [V]). El token de la API principal **no lleva** `RestringirSucursal`: solo lleva el código de la sucursal, y opcional (`src/GPOS.Api/Seguridad/Seguridad.cs:127-147` [V]). Si el ADMIN restringe a un usuario o le cambia la sucursal con la sesión abierta, el token conserva la sucursal anterior o ninguna. Una implementación del tipo «sin sucursal en el token, todos los almacenes» abre el alcance global.
- **Evidencia del patrón correcto.** GPOS.Reportes (T2-03) lee la restricción y la sucursal asignada de `GPOS_SYSDATA`, con caché de 15 s, prefiere esa sucursal a la del token y falla cerrado (`src/GPOS.Reportes/Contexto/ProveedorContexto.cs:32-35` y `:90-99` [V]).
- **Remediación (unos 0,25 d).**
  - Leer `RestringirSucursal` y `SucursalDefault` en el servidor con la misma regla.
  - Restringido sin sucursal resoluble, o con un código que no corresponde a una sucursal: **conjunto vacío** (sin alerta ni rombos), nunca «todos».
  - Ignorar cualquier parámetro del cliente.
  - Pruebas: restringido con el token de otra sucursal, restringido sin sucursal, y `SucursalAlmacenPermitido` fuera del alcance (ADR:126).
  - **Bien:** `Almacen.SucursalId` no admite nulos (`src/GPOS.Core/Dominio/Configuracion/Organizacion.cs:47` [V]), así que no hay fuga por `NULL`.
- **PREGUNTA-4 (Baja; no reabre).** El propietario dijo «Solo la central puede ver el alcance global» (hoja:118 [V]). El ADR lo traduce a «sin restricción = global», aunque la sesión esté en una sucursal (ADR:123). Se registra como interpretación firmada. Que B lo confirme si tiene dudas.

## 5. Controles que están bien implementados (en el diseño)
- El navegador nunca recibe una ruta. Todo error es un 404 uniforme y el motivo va solo a la bitácora (ADR:100, 105 [V]).
- El servidor genera la ruta, con lista blanca por segmento, rechazo de nombres de dispositivo y de `\\?\`, y un `CHECK` en la base (ADR:75, 101-102 [V]).
- Validación de la firma sin decodificar, con topes de dimensiones y de tamaño. El `Content-Type` sale de la firma (ADR:103-104 [V]).
- La empresa sale del token, nunca de la petición. El ADMIN global no configura la raíz antes de DB-7 (ADR:90 [V]).
- Las guardas TB-03 de 1 a 7 cubren los vectores principales. Las observaciones de arriba son de precisión, no de ausencia.
- El contenido del correo H-1 es cerrado y explícito (ADR:96 [V]), y sin destinatarios no se envía (ADR:95).
- El nodo verifica la integridad de lo que baja, incluso frente a una central comprometida (ADR:175 [V]).
- No se pasa ninguna URL a Chromium y las fotos van con tope por documento (ADR:158-159 [V]).
- El color de la categoría se valida en el servidor y en el cliente (ADR:145 [V]).
- Una prueba de contrato garantiza que `ArticuloTarjeta` no lleva `[DatoCosto]` (ADR:120 [V]).
- Ya existen piezas reutilizables, sin tecnología nueva: comprobación por identificador (`ComprobacionCarpetas.cs`), neutralización de CSV (`ExportadorReporte.cs:199-212`), autenticación reciente (`AutenticacionReciente.cs`) y alcance por sucursal de T2-03.

## 6. Remediaciones priorizadas

| Orden | ID | Cuándo | Esfuerzo [I] |
|---|---|---|---|
| 1 | S-01, S-02, S-04 | diseño de E-2, antes de escribir la configuración de la raíz | unos 0,6 d |
| 2 | S-03 | E-2 (lectura y escritura) | unos 0,5 d |
| 3 | S-17 y PREGUNTA-3 (S-16) | antes de E-1 (TA-P08 se construye en E-1) | 0,25 d (más 1 a 1,5 d si la respuesta es «confidencialidad») |
| 4 | S-10, S-12 | E-2 | unos 0,5 d |
| 5 | S-06, S-07, S-08 | E-2 (bitácora y H-1) | unos 0,65 d |
| 6 | S-11 | E-3 | unos 0,05 d |
| 7 | S-05 (PREGUNTA-1) | DevOps, documento de operaciones, antes de la implantación | unos 0,25 d |
| 8 | S-13, S-14, S-09 | E-2, si hay holgura | unos 0,4 d |
| 9 | S-15 | E-5 (entrega 2) | dentro de E-5 |

**Total sin S-16:** unos 3,2 días-persona (±50 %). La mayor parte cabe en la partida «pruebas de seguridad» y «guardas de la raíz del ADMIN» que E-2 ya presupuesta (ADR:273). **Costo de infraestructura:** USD 0.

## 7. Recomendación

**Aprobado con observaciones** (recomendación técnica; la decisión es del propietario).
- El diseño puede pasar a construcción de E-2 si S-01 a S-04 se toman como condiciones de construcción y S-06, S-08, S-10, S-12 y S-17 se cumplen antes de unir.
- Si E-2 se construye con la subcarpeta del ADMIN como texto libre o con E/S antes de validar la lista (S-01), la recomendación pasa a **Rechazado** (riesgo Alto).
- Las preguntas PREGUNTA-1 a PREGUNTA-4 no reabren el ADR: se elevan a B para que decida si van al propietario.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\revision-seguridad-adr93-2026-10-21.md`
- Supuestos:
  - «TN-02» del encargo se refiere a los permisos de la foto y de la lista de ambiguos (PREGUNTA-2); se revisaron también los de TN-02 del ADR.
  - El código de `feature/modelo-ng` a `fc7f07f2` es la base sobre la que se construirá E-2.
  - Que una unión del lado del servidor no se detecte por UNC es [I] y no se probó.
- Decisiones candidatas a ADR: ninguna nueva. S-01 (base por lista y subcarpeta fija = `IdEmpresa`) y S-02 (adoptar o volver a marcar solo el SUPER) son precisiones técnicas de TB-03 que el Arquitecto Maestro puede registrar como precisión si B lo pide.
- Entregas a otros agentes:
  - arquitecto-software: S-01 a S-04, S-10, S-12 y S-17 en el diseño de E-2 y E-1.
  - devops: S-05 (escritores del banco, DACL y alias de las bases).
  - qa-automatizado: pruebas de S-08, S-10, S-11 y S-17.
  - B, coordinador: PREGUNTA-1 a PREGUNTA-4.
- Próximo paso recomendado: que B responda PREGUNTA-3 (TA-P08: ¿presentación o confidencialidad?) antes de iniciar E-1.
