# Informe de seguridad: PR-2 de ADR-90 (RT-05, escucha TLS por modo)

- **Fecha:** 2026-10-21 · **Auditor:** auditor-seguridad (equipo A) · **Recomendación técnica; la decisión de unir es del propietario, vía B.**
- **Objeto:** commit `81edccad` de `a/adr90-rt05-tls-escucha` (repositorio `GPOS-NG-pr2`), comparado con `a32eb8b6` (PR-4 con S1b-03 y S1b-04).
- **Contratos:** plano v2 (`traspasos/A/blueprint-adr90-rt01-rt05-rt06-2026-10-20.md`, 5.2), ADR-090, hoja PT-01 a PT-10, revisión de seguridad de ADR-90 (`docs/seguridad/2026-10-20-revision-adr090-red-tls.md`, H-09 y H-15) y mis informes de PR-1a, PR-3, PR-1b y PR-4.
- **Método:** solo lectura (`git show`, `git diff`, `git grep`). No compilé ni ejecuté nada. [V] = verificado en el código; [I] = inferido (comportamiento del marco o de Schannel que no medí).

## 1. Alcance y superficie revisada

| Pieza | Archivo (en `81edccad`) |
|---|---|
| Escucha armada por modo, `TlsHandshakeCallbackOptions`, `AllowedHosts`, cookies `Secure`, regla de `Api:Url` | `src/GPOS.Comun.Servidor/Red/EscuchaServidor.cs:95-207` |
| Selector por huella SHA-256, refresco, 4747 a 4749 | `src/GPOS.Comun.Servidor/Red/SelectorCertificadoServidor.cs` |
| Almacén `LocalMachine\My` de solo lectura | `src/GPOS.Comun.Servidor/Red/AlmacenCertificadosServidor.Windows.cs`, `AlmacenCertificadosServidor.cs` |
| Cliente de la Web hacia la API (PT-01) | `src/GPOS.Comun.Servidor/Red/ClienteApiLocal.cs` |
| Web: URL de la API, S-06, H-09 | `src/GPOS.Web/Program.cs:66-72`, `:107-108`; `appsettings.json`, `appsettings.Development.json` |
| Pruebas de arquitectura y de Kestrel real | `tests/GPOS.Tests/Arquitectura/RedPlataformaArquitecturaTests.cs:89-134`, `tests/GPOS.Tests/Red/*` |

**Superficie expuesta afectada:** los puertos de la API y de la Web con el modo presente («un equipo»: *loopback*; «servidor de sitio»: todas las interfaces), el saludo TLS de ambos, el cliente HTTP de la Web hacia la API (lleva el token *Bearer* del usuario) y el arranque de los dos procesos. Sin modo no cambia la superficie (sección 5).

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título | ¿Bloquea unir? |
|---|---|---|---|
| S2-01 | Baja | El refresco no vuelve a juzgar la vigencia del certificado que ya sirve: al vencer, se sigue sirviendo sin evento del selector | No |
| S2-02 | Baja | La cookie del paso del factor (`InicioSesionWeb`) queda fuera de H-15: `Secure` depende de `Request.IsHttps`, que el reenvío de `X-Forwarded-Proto` puede cambiar | No |
| S2-03 | Baja | `AllowedHosts` derivado deja `AllowEmptyHosts = true`: una petición sin `Host` pasa el filtro | No |
| S2-04 | Baja | H-15 queda abierto en la API: `AllowedHosts` sigue en `*` (lo fija una prueba) | No (registrar decisión) |
| S2-05 | Baja | La prueba de arquitectura contra la validación propia no ve `CertificateChainPolicy`/`CustomTrustStore` ni un segundo `ConfigurePrimaryHttpMessageHandler` | No |
| S2-06 | Baja | H-09 en Production sin modo y sin `Api:Url`: la Web cae con una excepción sin manejar antes de `ExigirArranque` (sin evento de ADR-90 ni código 1) | No |
| S2-07 | Baja | Suites de TLS 1.2 a cargo de Schannel (RT-09) sin política aún; en Windows el código no puede fijarlas | No (entrega a devops) |
| S2-08 | Baja (informativa) | El selector no comprueba que el SAN cubra el nombre que usarán los clientes | No |

No hay hallazgos Críticos, Altos ni Medios.

## 3. Checklist OWASP Top 10 (2021)

| Categoría | Resultado | Ref. |
|---|---|---|
| A01 Control de acceso | Bien. `AllowedHosts` sin comodines (los nombres pasan `EtiquetaDns`, `InterpretacionRed.cs:21`, `:95-118`); Host ajeno → 400 con prueba en Kestrel real (`EscuchaTlsKestrelTests.cs:221-236`). Observaciones S2-03, S2-04 | S2-03, S2-04 |
| A02 Fallas criptográficas | Bien en lo que controla el código: TLS 1.2/1.3 explícito, sin renegociación, sin HTTP en claro, sin puerto 80, validación del sistema en el cliente. Suites de 1.2 pendientes de RT-09 | S2-07 |
| A03 Inyección | No aplica (no hay consultas ni plantillas nuevas; los nombres del registro se validan en PR-1a) | — |
| A04 Diseño inseguro | Bien: falla cerrada en el arranque (4747), selector sin lecturas en el saludo, cliente limitado a *loopback*. Observación S2-01 | S2-01 |
| A05 Configuración | Bien: `Kestrel:*` vacío y sin recarga con modo; `Api:Url` sale de Production (H-09). Observaciones S2-02, S2-06 | S2-02, S2-06 |
| A06 Componentes vulnerables | No aplica: el commit no agrega paquetes | — |
| A07 Identificación y autenticación | Bien: la cookie de sesión y la de antifalsificación con `Secure = Always` con modo. Observación S2-02 | S2-02 |
| A08 Integridad | Bien: el certificado se elige por SHA-256 (no SHA-1) del registro, de escritura solo para Administradores y SYSTEM (PR-1a) | — |
| A09 Registro y monitoreo | Bien: 4747/4748/4749 sin rutas, llaves ni contenido; solo huellas (públicas), fechas y tipo de excepción | — |
| A10 SSRF | Bien: el `ConnectCallback` rechaza cualquier destino que no sea el nombre y puerto derivados; sin proxy ni DNS | — |

## 4. Hallazgos

### S2-01 · Baja · La vigencia del certificado que se sirve no se vuelve a juzgar

- **Evidencia [V].** `SelectorCertificadoServidor.cs:148`: si la huella del registro es la misma que la vigente, `Refrescar` sale sin más. La vigencia (`NotBefore ≤ ahora < NotAfter`) solo se comprueba en `Cargar` (`:193`, `:233-234`), al arrancar o al cambiar de huella.
- **Riesgo.** Si el certificado vence con el servicio corriendo y nadie publicó una huella nueva, Kestrel sigue sirviéndolo. Los clientes lo rechazan (falla cerrada, no hay exposición), pero caen la Web, MAUI y las estaciones a la vez sin que el selector lo registre. El plano deja los avisos de vencimiento cercano a la tarea de renovación (4780 a 4789, plano 5.2, línea 247), que es de RT-03 y todavía no existe. Hasta entonces, nadie avisa. El impacto es de disponibilidad, no de confidencialidad.
- **Remediación (unos 0,05 dp, con su prueba con `FakeTimeProvider`).** Con la misma huella, `Refrescar` evalúa `MotivoNoUtilizable(vigente.Certificado, vigente.Huella, ahora)`. Si está vencido, registra el 4748 como crítico, uno por refresco, y sigue sirviendo (no hay nada mejor que servir). No hace falta un EventId nuevo. *Alternativa descartada:* detener el servicio al vencer. Cambiaría un error de cliente, que se diagnostica, por una caída sin escucha.

### S2-02 · Baja · Cookie del paso del factor fuera de H-15

- **Evidencia [V].** `src/GPOS.Web/Servicios/InicioSesionWeb.cs:82-89` fija `Secure = ctx.Request.IsHttps`. `AplicarWeb` (`EscuchaServidor.cs:187-194`) solo cubre `CookieAuthenticationOptions` y `AntiforgeryOptions`. La Web acepta `X-Forwarded-Proto` de *loopback* y de `ProxiesConfiables` (`src/GPOS.Web/Program.cs:57-62`).
- **Riesgo.** Con el modo, toda la escucha es HTTPS. Aun así, una petición con `X-Forwarded-Proto: http` desde un proxy conocido hace que `IsHttps` sea falso y que la cookie del paso salga sin `Secure`. Las cookies no distinguen puertos: el navegador podría enviarla en claro a otro servicio HTTP del mismo nombre. El alcance es pequeño (cookie con `Path` restringido, de vida corta y `HttpOnly`), pero H-15 pedía `Secure` en todas.
- **Remediación (minutos).** En `AplicarWeb`, `services.Configure<CookiePolicyOptions>(o => o.Secure = CookieSecurePolicy.Always)` con `UseCookiePolicy`, o `Secure = true` fijo en `FijarPaso` cuando hay modo. Opcional: con modo, quitar `XForwardedProto` del reenvío, porque no hay proxy HTTP admitido delante de la Web. Una prueba que compruebe el atributo en esa cookie.
- **Sobre la desviación de H-15:** H-15 pedía `Secure` «fuera de Development». El código lo pone «con modo». Lo acepto: sin modo solo se llega sin Estricto, y el 4746 limita la escucha a *loopback* (PR-1b). Conviene dejarlo escrito en el plano.

### S2-03 · Baja · `AllowEmptyHosts` sigue en `true`

- **Evidencia [V].** `EscuchaServidor.cs:191` sustituye `AllowedHosts`, pero no toca `AllowEmptyHosts`, que vale `true` por omisión en `HostFilteringOptions` [I: valor del marco].
- **Riesgo.** Una petición HTTP/1.0 sin `Host`, o HTTP/2 sin `:authority`, pasa el filtro. Lo que se construya con `Request.Host` (direcciones absolutas, redirecciones) quedaría vacío. No vi uso explotable, pero el filtro deja de ser una lista cerrada.
- **Remediación (minutos).** `o.AllowEmptyHosts = false` en el mismo `PostConfigure`, con un caso en `EscuchaTlsKestrelTests` (HTTP/1.0 sin `Host` → 400).

### S2-04 · Baja · H-15 abierto en la API

- **Evidencia [V].** `tests/GPOS.Tests/Red/EscuchaWebModoTests.cs:152-157` fija que en la API `AllowedHosts` sigue en `*`. La evidencia de H-15 citaba también `src/GPOS.Api/appsettings.json` (`AllowedHosts: "*"`). El plano (5.2, línea 267) solo pide la Web.
- **Riesgo.** Es bajo: la API no usa cookies y autentica con *bearer*. Con TLS y validación por nombre, el *DNS rebinding* falla en el saludo. Lo que queda es una diferencia sin documentar entre el hallazgo H-15 y lo construido.
- **Remediación.** Dos opciones: (a) aplicar a la API la misma derivación (`NombresServidor` más `localhost` en «un equipo»), unos 0,05 dp; o (b) registrar en el plano que H-15 se cierra solo en la Web y por qué. Recomiendo (a) por coherencia, aunque (b) basta para unir.

### S2-05 · Baja · Huecos de la prueba de arquitectura contra la validación propia

- **Evidencia [V].** `RedPlataformaArquitecturaTests.cs:119` busca solo `RemoteCertificateValidationCallback`, `DangerousAcceptAnyServerCertificateValidator` y `ServerCertificateCustomValidationCallback` en `src/GPOS.Web` y `src/GPOS.Comun.Servidor`.
- **Riesgo.** Hay dos vías que relajan la confianza y no aparecen en el patrón:
  - `SslClientAuthenticationOptions.CertificateChainPolicy` con `CustomTrustStore`/`X509ChainTrustMode.CustomRootTrust`, que sustituye la raíz sin ninguna devolución de llamada;
  - un segundo `ConfigurePrimaryHttpMessageHandler` o un `ConfigureHttpClientDefaults` en la Web, que sustituiría el manejador de `ClienteApiLocal` (gana el último) y con él el `ConnectCallback`.

  Hoy no existen [V: `git grep` en `src/GPOS.Web` y `src/GPOS.Comun.Servidor`]. La prueba no lo impediría mañana.
- **Remediación (minutos).**
  - Agregar al patrón `CertificateChainPolicy|CustomTrustStore|X509ChainTrustMode`. Solo pueden aparecer en `ClienteApiLocal.cs`, en la sobrecarga interna.
  - Una prueba de que `ConfigurePrimaryHttpMessageHandler` y `ConfigureHttpClientDefaults` aparecen solo en `ClienteApiLocal.cs`.
  - Extender la prueba a `src/GPOS.Api`, porque llama a terceros (conectores e-CF).

### S2-06 · Baja · H-09: la Web sin `Api:Url` en Production y sin modo cae sin evento

- **Evidencia [V].** `src/GPOS.Web/Program.cs:68` lanza `InvalidOperationException("Configure Api:Url.")` antes de `Build`, y por tanto antes del `try` de S-06 (`:107-108`). `Api:Url` solo queda en `appsettings.Development.json`. El DEMO lo pasa por entorno (`instalador/Demo/scripts/herramientas/Comun-Demo.ps1:375`), así que no se rompe.
- **Riesgo.** Es falla cerrada, como pide H-09: no hay URL en claro por omisión. Pero el proceso termina con una excepción sin manejar, sin evento de ADR-90 y sin el código 1 de S-06. Es diagnóstico, no exposición.
- **Remediación (minutos).** Registrar un crítico (4743, «falta `Api:Url` sin modo de red») y salir con código 1, o dejarlo así y documentarlo en la guía del DEMO y de pruebas. La parte de MAUI de H-09 (`ConfiguracionApi.cs`, HTTP por omisión en Release) sigue abierta: es de RT-10 (ver Entregas).

### S2-07 · Baja · Suites de TLS 1.2 pendientes de la política de Schannel (RT-09)

- **Evidencia [V].** `SelectorCertificadoServidor.cs:238-247` fija protocolos, ALPN y sin renegociación, pero no las suites. En Windows, `CipherSuitesPolicy` no está disponible [I: limitación de .NET en Windows], así que las suites salen de Schannel. El plano lo asigna a devops (5.2, línea 220).
- **Riesgo.** Hasta que RT-09 fije la política, TLS 1.2 puede negociar suites sin secreto perfecto hacia adelante (`TLS_RSA_*`) o CBC si el cliente las propone [I: depende de la versión de Windows y del orden por omisión, que pone ECDHE-GCM primero]. Los clientes propios (.NET, MAUI) prefieren suites fuertes y el *Finished* de TLS 1.2 protege contra la degradación, así que la probabilidad es baja.
- **Remediación (devops, 0,1 dp).** En RT-09:
  - para TLS 1.2, solo `ECDHE` con AES-GCM;
  - en Avanzada, el orden FIPS;
  - una línea en `comprobar-servidor` que liste las suites activas.

  *Alternativa descartada:* forzar solo TLS 1.3 en Básica. Dejaría fuera Windows Server 2019 y versiones anteriores, sin ganancia proporcional.

### S2-08 · Baja (informativa) · El selector no comprueba el SAN

- **Evidencia [V].** `MotivoNoUtilizable` (`SelectorCertificadoServidor.cs:212-236`) juzga la huella, la llave, el EKU y la vigencia, pero no comprueba si el SAN contiene `NombresServidor[0]` (o `localhost` en «un equipo»), ni quién es el emisor.
- **Riesgo.** No hay elusión: la huella la publica solo un administrador y los clientes validan el nombre y la cadena (falla cerrada). El efecto es de diagnóstico: una huella equivocada (por ejemplo, la del certificado de IIS) produce un 4749 «correcto» y luego errores de TLS en todos los clientes.
- **Remediación (opcional, 0,05 dp).** En `Cargar`, rechazar con motivo «el SAN no incluye el nombre del sitio» y emitir 4747 o 4748. Puede esperar a RT-02 o RT-03, que conocen el emisor.

## 5. Controles que están bien implementados

Respuesta a cada pregunta del encargo:

- **Elusión del selector: no la encontré.**
  - La búsqueda compara el SHA-256 del DER en todo el almacén (`AlmacenCertificadosServidor.Windows.cs:17-29`) y `MotivoNoUtilizable` lo vuelve a comparar (`SelectorCertificadoServidor.cs:214`).
  - Una huella del registro que no sea de 64 caracteres hexadecimales en mayúsculas se rechaza en la lectura (`InterpretacionRed.cs:18`, `:120-129`). El almacén devuelve mayúsculas (`Convert.ToHexString`), así que no hay coincidencia parcial ni por SHA-1.
  - Un certificado vencido, todavía no vigente, sin EKU `serverAuth`, sin llave o con una llave que la cuenta no abre no se carga (`:216-234`). La salvedad es la vigencia en caliente (S2-01).
- **TOCTOU: no lo hay.** El objeto que se juzga es el mismo que se sirve. `Cargar` construye el `SslStreamCertificateContext` con esa misma instancia (`:199`), y el cambio es una escritura volátil de una referencia bajo `_cambio` (`:156-166`). El saludo solo lee esa referencia (`EscuchaServidor.cs:158`). Un cambio en el almacén o en el registro después de la carga no afecta lo que se sirve hasta el siguiente refresco, que vuelve a juzgar todo. El certificado anterior se libera en el cambio siguiente (5 minutos o más después), muy por encima del saludo máximo de 10 s.
- **«offline» no implica un certificado por omisión.** `offline: true` solo evita descargar intermedios por AIA [I: semántica de .NET]. Con `TlsHandshakeCallbackOptions` no se usa el certificado de desarrollo ni `Certificates:Default`. Además, `Kestrel:*` se sustituye por una configuración vacía y sin recarga (`EscuchaServidor.cs:127`). Antes de cargar, `OpcionesVigentes` lanza y el saludo falla cerrado (`SelectorCertificadoServidor.cs:64-65`). Al arrancar sin certificado: 4747 y `ArranqueRedException` antes del anillo y de SQL (`src/GPOS.Api/Program.cs:350-351`, `src/GPOS.Web/Program.cs:107-108`).
- **Fugas: ninguna.** Los mensajes llevan el nombre del valor del registro, el motivo de la regla y el tipo de excepción (`:173`, `:206`). Nunca llevan la ruta del contenedor de la llave ni el contenido del certificado. La huella y la fecha de vencimiento son datos públicos del certificado.
- **`ConnectCallback`: no hay redirección posible.**
  - Compara nombre y puerto con los derivados y conecta solo a `127.0.0.1`, y después a `::1` (`ClienteApiLocal.cs:119-145`).
  - Sin DNS y con `UseProxy = false` (`:105`). Una redirección 3xx hacia otro anfitrión o puerto se rechaza en el propio callback, y de HTTPS a HTTP no la sigue el marco [I].
  - Un proceso local que ocupe el puerto de la API no puede suplantarla: `TargetHost` lleva el nombre (SNI) y la cadena y el nombre los valida el sistema, sin devolución de llamada propia (`:108-114`). El token *Bearer* solo sale tras un saludo válido.
  - Se cierra S-09 de PR-1a: un `Api:Url` distinto del derivado da 4743 (`EscuchaServidor.cs:170-180`).
- **Grupo de 10 minutos.** Las conexiones abiertas usan el certificado anterior, todavía válido, como mucho 10 minutos. No es un riesgo; la revocación es reemplazar la CA (RT-04).
- **Degradación de protocolo: cerrada en lo que toca al código.**
  - `SslProtocols.Tls12 | Tls13` en servidor y cliente.
  - `AllowRenegotiation = false`.
  - Solo HTTPS en el puerto del modo (`ListenLocalhost` o `ListenAnyIP`), sin puerto 80. HTTP/2 solo por ALPN sobre TLS: no hay h2c porque no hay punto en claro.
  - TLS 1.1 y HTTP en claro rechazados con prueba sobre Kestrel real (`EscuchaTlsKestrelTests.cs:135-145`).
  - Sin certificado de cliente ni revisión de revocación (correcto para el servidor).
  - El ALPN se fija en la instancia compartida para que Kestrel no la modifique (`SelectorCertificadoServidor.cs:245-246`).
- **Saludo lento.** `HandshakeTimeout = 10 s` (`EscuchaServidor.cs:159`), con `MaxConcurrentConnections` de la Web y de la API (`ProteccionWeb.cs:77-78`, `LimitesPeticiones.cs:232-233`). Un ataque de saludos lentos queda acotado a conexiones × 10 s.
- **`AllowedHosts`.** Sin comodines posibles. Las IPv6 van entre corchetes (`EscuchaServidor.cs:197-207`). Sustituye cualquier `--AllowedHosts=*` (prueba en `EscuchaWebModoTests.cs:114-128`).
- **Cookies `Secure` y proxy.** Con modo, la Web solo escucha HTTPS. Un proxy delante tendría que hablarle por TLS, así que `Secure = Always` no rompe nada ni deja huecos. Salvedad: S2-02.
- **H-09.** Sin `Api:Url` por omisión fuera de Development, con prueba (`ProgramaWebRedTests.cs`, `Api_Url_por_omision_solo_en_Development`). El DEMO lo declara por entorno.
- **Prueba de arquitectura.** La única validación propia es la sobrecarga interna para pruebas: rechaza los errores de nombre y solo sustituye la raíz. Es visible solo para `GPOS.Tests` y `GPOS.Web.Tests` (`GPOS.Comun.Servidor.csproj:23-24`), y la prueba fija que no es pública. Salvedad: S2-05.
- **Sin modo no cambia nada [V].** No hay selector ni escucha HTTPS (`EscuchaServidor.cs:117-137`). `UrlApi` devuelve `Api:Url` (`ClienteApiLocal.cs:50-59`), `UsarClienteApiLocal` no hace nada (`:62-69`) y `AllowedHosts` y las cookies quedan igual (prueba en `EscuchaWebModoTests.cs:141-150`). El único cambio sin modo es H-09 (S2-06), que es intencional.
- **S-06 en la Web y R-4.** El arranque denegado termina con código 1 y el motivo ya registrado. R-4 fija con las opciones reales de la API que solo `::ffff:127.0.0.1` se acepta como proxy (`ReenvioLoopbackMapeadoTests.cs`).
- **S-02 del #127 (HTTP sin autenticar en 5071).** Queda cerrado con modo: la API solo escucha HTTPS en el puerto del registro.

## 6. Remediaciones priorizadas

| # | ID | Acción | Responsable | Cuándo | Esfuerzo |
|---|---|---|---|---|---|
| 1 | S2-02 | `Secure` en la cookie del paso con modo (política de cookies) y prueba | A (desarrollo) | En este PR o el siguiente | Minutos |
| 2 | S2-03 | `AllowEmptyHosts = false` con modo y prueba | A | En este PR o el siguiente | Minutos |
| 3 | S2-05 | Ampliar el patrón y vigilar `ConfigurePrimaryHttpMessageHandler` | A | En este PR o el siguiente | Minutos |
| 4 | S2-01 | Volver a juzgar la vigencia del certificado vigente en el refresco (4748) | A | Antes de RT-03 | 0,05 dp |
| 5 | S2-04 | `AllowedHosts` derivado en la API o decisión escrita en el plano | A / arquitecto | Antes de cerrar F-6 (i) | 0,05 dp |
| 6 | S2-06 | 4743 y código 1 cuando falta `Api:Url` sin modo, o nota en la guía | A | Cuando convenga | Minutos |
| 7 | S2-07 | Política de suites de Schannel y comprobación en `comprobar-servidor` | devops (RT-09) | Con RT-09 | 0,1 dp |
| 8 | S2-08 | Comprobación del SAN en el selector | A | Con RT-02/RT-03 | 0,05 dp |

## 7. Recomendación

**Aprobado con observaciones** (recomendación técnica; la decisión de unir es del propietario, vía B).

No hay hallazgos Críticos, Altos ni Medios. El selector no se puede eludir por huella, por sujeto ni por certificado por omisión. El saludo no lee el registro ni el almacén. El cliente de la Web no puede salir de *loopback* ni aceptar un certificado que el sistema no valide. Sin modo, el comportamiento no cambia salvo H-09, que es intencional. Conviene aplicar S2-02, S2-03 y S2-05 (minutos) antes de unir o en el PR siguiente, y S2-01 antes de que exista la renovación de RT-03.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\revision-seguridad-pr2-adr90-2026-10-21.md`
- Supuestos: comportamiento del marco no medido: `offline` sin certificado por omisión, `AllowEmptyHosts` por omisión, `CipherSuitesPolicy` no disponible en Windows, no seguir redirecciones de HTTPS a HTTP. No se compiló ni se ejecutó nada.
- Decisiones candidatas a ADR: Ninguna. Solo una precisión en el plano: H-15 «con modo» en lugar de «fuera de Development», y el alcance en la API (S2-04).
- Entregas a otros agentes: devops → política de suites de Schannel de RT-09 y su comprobación (S2-07). Arquitecto de A → precisar H-15 en la API y en la Web (S2-04, S2-02). Responsable de RT-10 → la parte de MAUI de H-09 sigue abierta.
- Próximo paso recomendado: aplicar S2-02, S2-03 y S2-05 en la rama y avisar a B de que PR-2 queda en «Aprobado con observaciones» para el orden PR-3 → PR-2 → PR-4.
