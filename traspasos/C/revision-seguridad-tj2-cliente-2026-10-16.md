# Informe de Seguridad: revisión de la parte cliente de la vía (a′) de ADR-81 (T-j2e Web y T-j2f MAUI)

- **Fecha:** 2026-10-16
- **Revisor:** auditor de seguridad, equipo C
- **Commits revisados:** `58ce3166` (T-j2e, Web y copias comunes de MAUI) y `61dd46e8` (T-j2f, MAUI), leídos con `git show` sin tocar el árbol.
- **Complemento de:** `GPOS-NG-Equipos/traspasos/C/revision-seguridad-tj2-codigo-2026-10-16.md` (servidor, SEG-TJ2-01 a 09). Este informe cubre REQ-C-12 en el cliente.
- **Rutas:** las rutas `archivo:línea` se refieren al archivo completo en el commit indicado.

## 1. Alcance y superficie revisada

| Superficie | Archivos (commit) |
|---|---|
| P17 en la Web (página SSR anónima `/cuenta/recuperacion`) | `src/GPOS.Web/Components/Pages/Cuenta/Recuperacion.razor`, `Servicios/AlmacenDesafiosWeb.cs`, `Servicios/InicioSesionWeb.cs`, `Servicios/ProteccionWeb.cs`, `Servicios/RutasCuenta.cs`, `Servicios/VistaRecuperacionFactor.cs` (58ce3166) |
| Enlace en P1 y P1-B | Web: `Components/Pages/Cuenta/Factor.razor:89`; MAUI: `Components/Pages/Cuenta/Login.razor:273` |
| P17 en MAUI (estado `_recuperacion`) | `GPOS.UI.MAUI/Components/Pages/Cuenta/Login.razor`, `Servicios/InicioSesionFactor.cs` (`RecuperacionFactorMaui`), `Components/Compartidos/VistaCodigoQr.razor` (61dd46e8) |
| P5g (aviso a todos los SUPER) | `Components/Layout/AvisosSeguridad.razor` (Web y MAUI, copias idénticas, verificado con `diff`), `ApiClient.SegundoFactor.cs`, `VistaSegundoFactor.cs:265` |
| `MayusculasDeTitulo` | `tests/GPOS.Web.Tests/MayusculasDeTitulo.cs` |

También leí, para contrastar, `src/GPOS.Contracts/Seguridad/SegundoFactor.cs`, `src/GPOS.Api/Endpoints/AuthEndpoints.cs:84-91`, `src/GPOS.Core/Sistema/SegundoFactor/Recuperacion/CatalogoCausasRecuperacion.cs` y `SegundoFactorService.Recuperacion.cs:189-192`.

**No ejecuté pruebas ni compilé.** Otro agente está corrigiendo el servidor en el mismo árbol y la regla del equipo limita las compilaciones simultáneas. Las pruebas `RecuperacionFactorTests`, `AvisoRecuperacionTests` y `RecuperacionFactorMauiTests` las leí, pero no las ejecuté.

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título |
|---|---|---|
| SEG-TJ2C-01 | Baja | Si el resultado de J2-3 queda incierto, el mensaje siguiente («El tiempo terminó») contradice lo que pasó en el servidor (también ocurre con J2-1) |
| SEG-TJ2C-02 | Baja | El enlace a P17 se ofrece a cualquier cuenta con segundo factor, no solo al SUPER (el origen está en el servidor) |
| SEG-TJ2C-03 | Baja | El servidor web reenvía la autorización a la API sin comprobar su largo: `maxlength` solo actúa en el navegador |
| SEG-TJ2C-04 | Informativo | P5g muestra la causa como códigos del catálogo (`perdida/no-guardados/unico-super`), no como texto legible |
| SEG-TJ2C-05 | Informativo | Con una recuperación en curso, el aviso del límite por IP (`?limite=true`) no se muestra |
| SEG-TJ2C-06 | Informativo | Al pasar de P1 a P17, el desafío de P1 solo se descarta en el cliente; la API lo deja vencer solo (5 min) |
| SEG-TJ2C-07 | Informativo | Riesgos que ya existían y fuera del control de la aplicación: el portapapeles (la clave copiada y la autorización pegada desde el correo) y la cookie sin `Secure` cuando no hay HTTPS |

No hay hallazgos Críticos, Altos ni Medios.

## 3. Checklist OWASP (parte cliente)

| Punto | Resultado |
|---|---|
| A01 Control de acceso | Bien. P17 no abre sesión: la Web no llama a `EntrarAsync` ni a `SignInAsync` y MAUI no llama a `AbrirSesion` en la recuperación. P5g se dibuja solo con `EsSuper` (defensa en profundidad frente a SEG-TJ2-06). Observación de exposición: SEG-TJ2C-02. |
| A02 Criptografía | Bien. Identificador de 256 bits (`AlmacenDesafiosWeb.cs:196`); el QR se genera localmente como PNG en una URI `data:`. |
| A03 Inyección y XSS | Bien. Razor codifica el texto de P5g y la causa sale de un catálogo cerrado. No hay `MarkupString` en las rutas nuevas. |
| A04 Diseño inseguro | Observaciones SEG-TJ2C-01 y 03. |
| A05 Configuración | Bien. `Cache-Control: no-store` en P17 (`InicioSesionWeb.SinCache`), antiforgery global y límite por IP propio. Informativo SEG-TJ2C-07. |
| A06 Componentes vulnerables | No aplica: los commits no agregan paquetes (QRCoder ya estaba). |
| A07 Autenticación | Bien. 401 uniforme, la contraseña y la autorización se vacían, desafío en el servidor. Ver §4.1. |
| A08 Integridad | No aplica en el cliente: la firma la verifica la API. |
| A09 Registro y monitoreo | Bien. Solo se registra `ex.Message` de `HttpRequestException`, sin el cuerpo. El `HttpClient` no tiene ningún manejador que registre cuerpos (la Web solo tiene `ReenvioIpCliente`). |
| A10 SSRF | No aplica: rutas fijas hacia la API configurada. |

## 4. Comprobaciones pedidas

### 4.1 P17 en la Web y el estado `_recuperacion` en MAUI

| Comprobación | Resultado | Evidencia |
|---|---|---|
| La contraseña y la autorización no quedan en el HTML | Verificado. Se vacían antes de cualquier retorno, incluido el error de validación, así que el `InputText`/`InputTextArea` vuelve a dibujarse vacío. Cuando hay una recuperación en curso, no se dibuja el formulario del paso 1. | Web `Recuperacion.razor:184`, `:181`; MAUI `Login.razor:862` |
| Ni en `localStorage`, Preferences ni SecureStorage | Verificado. P17 en la Web es SSR sin JavaScript propio; `gpos.js` usa `localStorage` solo para el tema y el zoom. `RecuperacionFactorMaui` vive en memoria; `Login.razor` solo nombra Preferences o SecureStorage en un comentario. `RecuperacionFactorWeb` no tiene campos para la contraseña ni para la autorización. | `AlmacenDesafiosWeb.cs:62-93`; `InicioSesionFactor.cs` (clase `RecuperacionFactorMaui`) |
| Ni en los registros | Verificado. `LogWarning` solo con `ex.Message` de transporte; MAUI no registra nada. | `Recuperacion.razor` (catch de J2-1 y J2-3) |
| Desafío en el servidor con la cookie HttpOnly | Verificado. La cookie es la misma de `/cuenta`, con `HttpOnly`, `SameSite=Strict`, `Path=/cuenta` y 256 bits aleatorios; el desafío, el alta y los códigos se quedan en memoria del servidor web; `Olvidar()` los borra al eliminar o caducar. | `InicioSesionWeb.cs:85-87`; `AlmacenDesafiosWeb.cs:196` |
| Límite por IP | Verificado. 10 POST por minuto por IP, con su propia partición y aplicado a las variantes de la ruta (`RutasCuenta.Es`); un rechazo devuelve 303 a P17. Cubre los POST de los tres pasos, porque los tres van a la misma ruta. | `ProteccionWeb.cs:34`, `:50-53`, `:61` |
| Todo 401 con el mismo texto | Verificado. `(Unauthorized, _) => TextoRechazo` es la primera rama y no lee `Detalle`. Un 401 `DESAFIO_VENCIDO` solo se distingue en los pasos 2 y 3, donde ya hay un desafío válido (no es un oráculo de credenciales). El 423 muestra `r.Detalle`, que redacta el servidor y que Razor codifica. | `VistaRecuperacionFactor.cs:84`, `:93` |
| No se abre sesión | Verificado. Web: al final, `NavigateTo(Login?aviso=recuperada)` (`Recuperacion.razor:300`). MAUI: `ContinuarCodigosAsync` llama a `VolverAlFormulario` (`Login.razor:773`) y no hay ningún `AbrirSesion` en las líneas 830-1000. | — |
| Sin `otpauth` en MAUI | Verificado. `VistaSegundoFactor.Qr` crea un PNG con QRCoder; el URI no se muestra ni se abre, y `VistaCodigoQr` de MAUI no tiene enlace. En un teléfono se recomienda escanear desde otro equipo (UX-81A-03). | `Login.razor:922`; `VistaCodigoQr.razor` (MAUI) |
| Guarda del botón «Atrás» | Verificado. `EnCodigos` incluye `_recuperacion?.Codigos`; la protegen `RegisterLocationChangingHandler` y `InterceptarAtras` en Android. «Sí, los guardé» vuelve al formulario sin sesión. | `Login.razor:1004`, `:1015` |
| La autorización solo se limpia de espacios | Verificado. Solo se quitan los `char.IsWhiteSpace`: no hay más normalización, no se recortan otros caracteres ni se decodifica nada. La contraseña no se recorta; el usuario, sí (`Trim`). | `VistaRecuperacionFactor.cs:70`, `:73-78` |
| Tope de 3000 frente a 2 KB | Coherente. Con 3000 caracteres caben unos 2048 de JWS más los saltos de línea de un correo (de 27 a 54 caracteres si corta cada 76). Por encima, la API responde 413 o 422 y la interfaz muestra `TextoInvalida`. Lo que falta: SEG-TJ2C-03. | `VistaRecuperacionFactor.cs:26`, `:88` |

### 4.2 El enlace en P1

Verificado: en la Web y en MAUI aparece solo si `RecuperacionDisponible` es verdadero (`Factor.razor:89`, `Login.razor:273`). La Web lo toma del 202 en `AlmacenDesafiosWeb` y MAUI en `PasoFactor`. También aparece en P1-B (prueba `El_enlace_sigue_en_P1_B_con_el_factor_bloqueado`). Ocultar el enlace es solo una cuestión de interfaz: la página es anónima y quien decide es la API. Ver SEG-TJ2C-02.

### 4.3 P5g

| Comprobación | Resultado | Evidencia |
|---|---|---|
| No se puede ocultar sin acusarlo | Verificado. El `MudAlert` no tiene icono para cerrarlo y solo «Entendido» lo quita, después del 204. Está en `MainLayout` (Web `:79`, MAUI `:73`), así que se ve en todas las pantallas. Sin acuse, la API lo vuelve a enviar en la próxima entrada. Si se recarga la Web, el aviso sigue, porque `Franjas` vive en la sesión del servidor. | `AvisosSeguridad.razor:14-27`, `:151-174` |
| El 404 del acuse | Correcto. Solo un 404 con `AVISO_NO_EXISTE` quita el aviso; con cualquier otro error (403, 5xx, red) el aviso se queda y aparece el snackbar `TextoAcuseFallido` (texto constante, sin `MarkupString`). | `:161-167` |
| La causa sin interpretar como HTML | Verificado. `@VistaSegundoFactor.TextoRecuperacion(aviso)` va codificado por Razor, tanto en la Web como en BlazorWebView. Además, `Causa` es `causa/codigos/viaA` de un catálogo cerrado (`CatalogoCausasRecuperacion.cs:16-18`), que el lector valida antes de aceptar la autorización. El riesgo de XSS es nulo por dos controles independientes. | `VistaSegundoFactor.cs:265`; `SegundoFactorService.Recuperacion.cs:192` |

### 4.4 Riesgo residual declarado (corte después de enviar J2-3)

Lo valoro en SEG-TJ2C-01. Conclusión: **es sobre todo un problema de experiencia con un efecto secundario menor de seguridad. No engaña sobre la seguridad a nadie más.** El servidor registra la recuperación en la bitácora y todos los SUPER, incluido el recuperado, reciben el aviso P5g en su próxima entrada. Un atacante no puede aprovechar el mensaje erróneo para ocultar una recuperación. En la Web solo afecta al corte entre el servidor web y la API: si se corta entre el navegador y la Web, la Web termina la llamada, guarda los códigos en `RecuperacionFactorWeb` y se ven al recargar.

### 4.5 `MayusculasDeTitulo`

`tests/GPOS.Web.Tests/MayusculasDeTitulo.cs` es un ayudante de pruebas: no se compila en la aplicación ni cambia ningún comportamiento en ejecución. Agregar «un», «una», «unos» y «unas» a las palabras menores solo cambia lo que las pruebas exigen a los títulos. **Sin impacto de seguridad.**

## 5. Hallazgos

### SEG-TJ2C-01 (Baja). Resultado incierto de J2-3 o J2-1 seguido de un mensaje que contradice lo que pasó

**Riesgo.** La conexión con la API se corta después de enviar J2-3 (`TaskCanceledException`; en MAUI también un `HttpRequestException` por un reinicio de la conexión). La interfaz muestra «No sabemos si su código se registró. Espere el siguiente código…». Si el servidor sí confirmó, el desafío ya se consumió y el reintento recibe un 401 `DESAFIO_VENCIDO`, que lleva a «El tiempo terminó. Pida una autorización nueva a GSF.». Consecuencias:
1. El SUPER cree que la recuperación falló cuando su factor nuevo ya está activo.
2. **Nunca ve los 10 códigos de respaldo nuevos**, que el servidor ya emitió y que no vuelve a mostrar. Si no regenera los códigos, queda con un solo factor y sin respaldo, y es más probable que necesite otra recuperación.
3. Se pide a GSF una autorización innecesaria. Si GSF la emite y se usa, el secreto vuelve a cambiar y la aplicación del teléfono termina con dos entradas con la misma etiqueta, una de ellas sin valor.

J2-1 tiene el mismo caso: si el `jti` quedó reservado, el reintento con la misma autorización recibe el 401 uniforme («Compruebe su usuario, su contraseña y la autorización»), que hace pensar en una contraseña equivocada.

**Por qué es Baja y no más.** No permite eludir controles ni engaña a terceros: la bitácora registra la recuperación y P5g la anuncia a todos los SUPER. Necesita un corte de red en una ventana de milisegundos.

**Evidencia.** Web `Recuperacion.razor:269-271` (J2-3 incierto), `:282` y `:304-307` (`Vencer` con `TextoTiempoTermino`), `:198-200` (J2-1 incierto); MAUI `Login.razor:968`, `:990` (`VencerRecuperacion`), `:883`; textos en `VistaRecuperacionFactor.cs:57-59`.

**Remediación (unas 0,5 semanas-persona con pruebas, para la Web y MAUI juntas; texto común en `VistaRecuperacionFactor`).**
- Marcar en `RecuperacionFactorWeb` y `RecuperacionFactorMaui` un estado `ConfirmacionIncierta` cuando J2-3 termina sin respuesta. Si el siguiente intento recibe un 401 `DESAFIO_VENCIDO` con esa marca, mostrar un texto propio y no `TextoTiempoTermino`. Propuesta: «Es posible que la recuperación se haya completado. Inicie sesión con el código de su aplicación; si entra, genere códigos de respaldo nuevos en Mi Verificación en Dos Pasos. Si no entra, pida otra autorización a GSF.». Llevar al inicio de sesión con el usuario escrito.
- Hacer lo mismo con J2-1: si el resultado fue incierto y el reintento recibe un 401, añadir una frase que no hable de la contraseña (por ejemplo, «si la autorización ya se usó, pida otra a GSF»), sin distinguir la causa, para no romper el 401 uniforme.
- Defensa en profundidad, opcional y en el servidor: en la primera entrada después de una recuperación, P5g o P5c podrían ofrecer «Generar códigos nuevos» al SUPER recuperado.
- Alternativa descartada: reintentar J2-3 automáticamente. No sirve, porque el desafío es de un solo uso y el resultado sería el mismo 401.

### SEG-TJ2C-02 (Baja). El enlace a P17 se ofrece a cualquier cuenta con segundo factor

**Riesgo.** El 202 lleva `RecuperacionDisponible` según la instalación, no según el nivel de la cuenta. Un USER o un ADMIN con el factor optativo de ADR-81 ve en P1 «No tengo mi teléfono ni mis códigos de respaldo» y un texto pensado para el SUPER. Si lo sigue, recibe el 401 uniforme. No es un oráculo (el 202 solo llega con la contraseña correcta), pero engaña al usuario, genera llamadas a GSF por algo que no corresponde y deja en la bitácora rechazos de recuperación de cuentas que no son SUPER.

**Evidencia.** `src/GPOS.Api/Endpoints/AuthEndpoints.cs:89-91` (`RecuperacionDisponible: await recuperacion.DisponibleAsync(ct)`, sin condición de nivel); el cliente lo obedece tal cual (`Factor.razor:89`, `Login.razor:273`).

**Remediación (menos de 1 hora más una prueba).** En el servidor, `RecuperacionDisponible: u.Nivel == SUPER && await recuperacion.DisponibleAsync(ct)`. El cliente no cambia. Alternativa descartada: filtrar en el cliente, que no conoce el nivel antes de entrar.

### SEG-TJ2C-03 (Baja). El servidor web no comprueba el largo de la autorización antes de reenviarla

**Riesgo.** `maxlength="3000"` solo actúa en el navegador. Un POST hecho a mano con una autorización de varios MB (los límites por omisión de los formularios de ASP.NET Core la admiten) obliga a la Web a recorrerla, copiarla, serializarla y enviarla a la API, que la rechaza con 413. El límite de 10 por minuto por IP lo acota, así que el impacto es un consumo de memoria y de red evitable, no una denegación de servicio práctica. MAUI tiene el mismo código, pero ahí el cliente es la propia aplicación.

**Evidencia.** `VistaRecuperacionFactor.cs:73-78` (`Pedido` valida que no esté vacía, pero no el largo); `Recuperacion.razor:183-191`.

**Remediación (menos de 1 hora).** En `Pedido`: si el texto pegado tiene más de `LargoCampoAutorizacion` caracteres, o si sin espacios supera los 2048, devolver `(null, TextoInvalida)` sin llamar a la API. Como el archivo es común, la Web y MAUI se corrigen a la vez. Opcional: `[RequestFormLimits(ValueLengthLimit = 8192)]` en la página.

### SEG-TJ2C-04 (Informativo). La causa de P5g se muestra con los códigos del catálogo

`TextoRecuperacion` muestra `Causa` tal como llega: `perdida/no-guardados/unico-super`. Es seguro (catálogo cerrado y texto codificado), pero un SUPER que lee el aviso entiende peor qué pasó. Recomendación de experiencia: traducir cada miembro a texto («pérdida del teléfono; códigos no guardados; único Super Usuario»), con un valor por omisión neutro si llega un código desconocido. Evidencia: `VistaSegundoFactor.cs:265`; `SegundoFactorService.Recuperacion.cs:192`.

### SEG-TJ2C-05 (Informativo). El aviso del límite se pierde con una recuperación en curso

`OnInitialized` sale en `if (Rec is not null) return;` antes de leer `Limite`. Si el límite salta en el paso 3, el 303 a `/cuenta/recuperacion?limite=true` vuelve a mostrar el QR (paso 2) sin decir por qué. Solo afecta a la experiencia. Evidencia: `Recuperacion.razor:168-170`. Remediación: leer `Limite` antes de ese retorno.

### SEG-TJ2C-06 (Informativo). El desafío de P1 solo se descarta en el cliente

Al seguir el enlace, la Web (`Desafios.Eliminar`) y MAUI (`paso.Olvidar()`) olvidan el desafío de P1, pero la API lo conserva hasta que vence (5 min). Nadie más lo tiene, porque no salió del servidor web ni de la memoria de la aplicación. **No requiere ninguna acción.**

### SEG-TJ2C-07 (Informativo). Riesgos que ya existían

- El botón «Copiar» deja la clave del secreto en el portapapeles del sistema, igual que en P2. La autorización pegada desde el correo puede quedar en el historial del portapapeles o del teclado (Gboard). La aplicación no lo controla; la autorización caduca en horas, es de un solo uso y exige la contraseña.
- La cookie lleva `Secure = ctx.Request.IsHttps`, y la contraseña y la autorización viajan del navegador a la Web. En una instalación sin HTTPS viajan sin cifrar, igual que en el inicio de sesión. Corresponde a la política de despliegue (DevOps), no a este cambio.

## 6. Controles que están bien implementados

- Separación limpia entre el desafío y el navegador: en la Web solo viaja un identificador opaco de 256 bits en una cookie `HttpOnly`, `SameSite=Strict` y limitada a `/cuenta`. `Olvidar()` borra el desafío, el alta, el QR y los códigos al eliminar, caducar o confirmar.
- La contraseña y la autorización se vacían **antes** de evaluar el pedido, así que ningún error las devuelve a la página. Las pruebas lo comprueban (`El_401_es_uniforme_y_vacia_la_contrasena_y_la_autorizacion`).
- El 401 uniforme como primera rama del `switch`, sin leer `Detalle` (`VistaRecuperacionFactor.cs:84`), comprobado en la Web y en MAUI.
- Ningún camino de P17 abre sesión. Al terminar se vuelve al inicio de sesión normal con el aviso «recuperada» (PA-01.4).
- QR local sin URI `otpauth` a la vista ni como enlace; con un teléfono se indica escanear desde otro equipo.
- La guarda del botón «Atrás» cubre los códigos nuevos en los dos mecanismos (el del WebView y el del botón de Android).
- P5g: se ve en todas las pantallas, solo el acuse en el servidor lo quita y se trata con precisión el 404 `AVISO_NO_EXISTE`. El filtro `EsSuper` en el cliente cubre en profundidad SEG-TJ2-06 del servidor.
- Límite por IP propio de P17, que reconoce las variantes de la ruta.
- `Cache-Control: no-store` en las páginas que muestran el QR y los códigos.
- Copias comunes idénticas entre la Web y MAUI (`AvisosSeguridad.razor`, `VistaRecuperacionFactor.cs`), vigiladas por `ComponentesCompartidosTests`.
- Después de confirmar, el cliente borra el desafío y nunca vuelve a llamar a J2-2 con él, lo que también reduce en el cliente la exposición de SEG-TJ2-05.

## 7. Remediaciones priorizadas

| Orden | ID | Acción | Esfuerzo | Responsable |
|---|---|---|---|---|
| 1 | SEG-TJ2C-02 | Condicionar `RecuperacionDisponible` al nivel SUPER en el 202 | < 1 h | desarrollador del servidor |
| 2 | SEG-TJ2C-03 | Comprobar el largo en `VistaRecuperacionFactor.Pedido` (común a la Web y MAUI) | < 1 h | desarrollador del cliente |
| 3 | SEG-TJ2C-01 | Estado `ConfirmacionIncierta` y texto propio tras un 401 `DESAFIO_VENCIDO`; frase neutra para J2-1 | ~0,5 semanas-persona | desarrollador del cliente (texto: UX) |
| 4 | SEG-TJ2C-04, 05 | Causa legible en P5g; aviso del límite con la recuperación en curso | < 2 h | desarrollador del cliente |

Ninguna de estas acciones impide unir los commits. Las de orden 1 y 2 conviene hacerlas antes de cerrar la fase A.

## 8. Recomendación: **Aprobado con observaciones**

Recomendación técnica, pendiente de la firma del propietario (C2). Los nueve puntos de P17 que pedía el encargo, el enlace de P1 y los tres de P5g están verificados en el código. Hay tres hallazgos de severidad Baja y cuatro informativos, ninguno Crítico ni Alto. El riesgo residual que declaró el desarrollador es de experiencia, con un efecto secundario menor (el SUPER puede quedarse sin códigos de respaldo), y no engaña sobre la seguridad a otros SUPER.

### Supuestos
- Revisé solo el contenido de `58ce3166` y `61dd46e8`; las correcciones del servidor que están en curso no entran en esta revisión.
- No ejecuté las pruebas: lo que digo sobre ellas sale de leerlas.
- Supongo que el servidor (`AuthEndpoints`, `SegundoFactorService.Recuperacion`) sigue como en `61dd46e8`, según mi informe del servidor.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\GPOS-C-revision-seguridad-tj2-cliente.md`
- Supuestos: los de la sección anterior
- Decisiones candidatas a ADR: Ninguna
- Entregas a otros agentes: desarrollador del servidor → SEG-TJ2C-02; desarrollador del cliente → SEG-TJ2C-01, 03, 04 y 05; diseño de UX → textos de SEG-TJ2C-01 y la causa legible de SEG-TJ2C-04; DevOps → HTTPS obligatorio en la Web (SEG-TJ2C-07)
- Próximo paso recomendado: corregir SEG-TJ2C-02 y 03, que son de menos de una hora, antes de cerrar la fase A, y planificar SEG-TJ2C-01 con UX.
