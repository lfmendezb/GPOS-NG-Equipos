# Informe de Seguridad: PR #210 (T4-02a, ClienteRender y contrato del render)

- Fecha: 2026-10-23 · Revisor: auditor-seguridad (equipo A), solo lectura
- PR: lfmendezb/GPOS-NG #210, rama `b/t4-02a` (cabeza `9288b01a`), base `feature/modelo-ng`
- Referencias: ADR-110 cl. 7; ADR-109 cl. 1 y 8; blueprint `docs/arquitectura/2026-10-22-t4-02-blueprint-principal-sin-motores.md` (5.1, 5.3, 6.1, 6.2, 10.2)
- Es la revisión que B dejó pendiente: «ClienteRender, el camino del token y el evento 5122».

## 1. Alcance y superficie revisada

- `src/GPOS.Api/Impresion/ClienteRender.cs` (nuevo, 277 líneas): `IClienteRender`, `ClienteRender`, `RenderRechazadoException`.
- `src/GPOS.Contracts/Impresion/ContratoRender.cs` (movido desde `GPOS.Reportes.Api`; solo cambia el espacio de nombres y el comentario: verificado en el diff, similitud 91 %, ningún campo cambia).
- `src/GPOS.Reportes.Api/Impresion/ErroresRender.cs` (solo un `using`).
- Pruebas: `ClienteRenderTests.cs`, `ContratoRenderTests.cs`, ajustes en `MedicionRender.cs` y `RenderTrasladoTests.cs`.
- Contexto leído sin cambios en el PR (necesario para el camino del token): `src/GPOS.Api/Endpoints/ReenvioReportes.cs` (cliente con nombre `GPOS.Reportes.Canal`, `ManejadorCanal`, `DetalleParaRegla`), `src/GPOS.Reportes.Api/Endpoints/EndpointsRender.cs`, `ServiciosReportes.cs` (ACL de la canalización), `ErroresRender.cs`, `MotorRazor.cs`, `FormatoConduceTransferencia.cs`, `GPOS.Contracts/Impresion/ModeloImpresion.cs`.
- Superficie: el PR no expone endpoints nuevos (sin registro en DI ni llamadores; T4-02b los agrega). El único camino nuevo es saliente: principal → canalización con nombre → `/interno/render/{documento|cierre|conduce|resultado}` de la API de reportes, con el token de la sesión del puesto.

Ejecutado: `dotnet test tests/GPOS.Tests/GPOS.Tests.csproj --filter "FullyQualifiedName~ClienteRenderTests"` en el árbol `9288b01a`: **28 de 28 correctas** (2 s). No se corrió la suite completa ni `ContratoRenderTests` en este equipo (B informó 149/149 para los cuatro grupos).

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título | Estado |
|---|---|---|---|
| S210-01 | Baja | El 401 pasa al puesto `codigo` y `X-GPOS-Sesion` de la API de reportes sin lista blanca | Verificado |
| S210-02 | Baja | `ReintentarEn` sin tope (Retry-After con fecha lejana o delta grande) | Verificado; el efecto llega con T4-02b |
| S210-03 | Baja | `FORMATO_INVALIDO` pasa al usuario el `ex.Message` de la ejecución de la plantilla | Verificado (heredado del render en proceso) |
| S210-04 | Baja | El cliente de la canalización sigue redirecciones (`AllowAutoRedirect` por omisión) | Inferido (comportamiento de .NET); fuera del PR |
| S210-05 | Baja | Memoria: el cuerpo se serializa entero antes del tope; el PDF de 32 MB se copia dos veces | Verificado |
| S210-06 | Baja | Huecos de prueba: tope del PDF sin `Content-Length`, ausencia del token en el registro | Verificado |

No hay hallazgos Críticos, Altos ni Medios.

## 3. Checklist OWASP Top 10 (2021)

| Punto | Resultado |
|---|---|
| A01 Control de acceso | Bien. La ruta la fija el método (`ClienteRender.cs:72-81`, `BaseCanal` constante, línea 52); el cliente del puesto no puede fijar ruta, host, empresa ni usuario: la API de reportes los deriva del token por introspección (`EndpointsRender.cs:63`) y las rutas `/interno` solo existen por la canalización (`EndpointsRender.cs:32-40`, `76`). Condición para T4-02b: `EmpresaInfo`, `Formato` y el modelo se arman desde la sesión y la base, nunca desde el cuerpo del puesto (ver sección 6). |
| A02 Criptografía | No aplica (canalización local con ACL; sin cifrado propio). |
| A03 Inyección | Bien. Contrato con `JsonSerializerDefaults.Web` en ambos lados, sin tipos polimórficos ni `TypeNameHandling`; los `object` del resultado se leen como `JsonElement`. La plantilla Razor y el HTML los valida y aísla la API de reportes (T4-01, fuera del PR). |
| A04 Diseño inseguro | Bien. Falla cerrada en todos los caminos sin 2xx (503 `REPORTES_NO_DISPONIBLE`). |
| A05 Configuración | Observación S210-04 (redirecciones). |
| A06 Componentes vulnerables | No aplica (el PR no agrega paquetes). |
| A07 Autenticación | Bien. Solo viaja el `Authorization` del puesto y la marca de sondeo automático (`ClienteRender.cs:90-99`); observación S210-01 sobre el 401. |
| A08 Integridad de datos | Bien. Versión 1 verificada por la API de reportes (`EndpointsRender.cs:84`); `TextoMarca`/`TextoCopia` son propiedades calculadas, no se pueden fijar por el JSON (`ModeloImpresion.cs:58-68`). |
| A09 Registro y monitoreo | Bien. 5121 y 5122 con los mismos `EventId` que el reenvío; el token no se registra (`RedactLoggedHeaders(_ => true)`, `ReenvioReportes.cs:427`). Observación menor en S210-01 (código sin limpiar en el registro). |
| A10 SSRF | Bien. `ConnectCallback` ignora el host y siempre abre la canalización verificada (`ReenvioReportes.cs:441-457`); `UseProxy = false`. |

## 4. Hallazgos

### Verificación de los seis puntos pedidos

**(1) Fuga o reenvío del token.** El token sale solo por el cliente con nombre `GPOS.Reportes.Canal` (`ClienteRender.cs:122-123`), cuyo `ConnectCallback` ignora el `DnsEndPoint` y siempre abre `\\.\pipe\<Canalizacion>` (`ReenvioReportes.cs:443`); nunca va por TCP ni a otro host. `AutorizarDesde` copia solo `Authorization` y la marca automática (`ClienteRender.cs:90-99`), lo comprueba la prueba `La_autorizacion_de_una_ruta_copia_el_token_y_la_marca_de_sondeo_automatico` (`ClienteRenderTests.cs:109-124`). No hay línea de registro con el token; el `HttpClient` redacta todos los encabezados (`ReenvioReportes.cs:427`). Ningún encabezado de la respuesta se refleja en este PR: `MotivoSesion` y `ReintentarEn` quedan en la excepción (S210-01, S210-02). Redirecciones: S210-04. **Sin hallazgo de fuga.**

**(2) Dueño verificado antes de enviar (5122).** El `ConnectCallback` conecta, compara el dueño con `CuentaServicio` y lanza `CanalSuplantadoException` antes de devolver el flujo (`ReenvioReportes.cs:446-449`): no se escribe ni un byte. `ClienteRender` lo distingue con `ex.GetBaseException()` antes de cualquier otro `catch` (`ClienteRender.cs:128-132`), registra 5122 con nivel `Critical` y responde 503 genérico. La prueba `El_dueno_de_la_canalizacion_se_verifica_antes_de_enviar_el_modelo` (`ClienteRenderTests.cs:146-167`) usa una canalización del programador frente a SYSTEM esperado, comprueba 5122 crítico y que la impostora lee 0 bytes. El texto de 5122 lleva SID y PID del dueño: solo en el registro del servidor, sin secretos. La ACL del servidor niega `NETWORK` y admite solo el servicio y la cuenta de la principal (`ServiciosReportes.cs:121-128`). **Correcto.**

**(3) Tamaño y plazo.** 413 `REPORTE_DEMASIADO_GRANDE` antes de crear la petición (`ClienteRender.cs:110-113`); el tope coincide con `OpcionesRender.MaximoCuerpoBytes` y lo amarra una prueba (`ClienteRenderTests.cs:189-194`); el límite es inclusivo en los dos lados (`>` en `ClienteRender.cs:111` y en `EndpointsRender.cs:116,122`). Plazo de 35 s enlazado con la cancelación del puesto (`ClienteRender.cs:115-116`); el `Timeout` del `HttpClient` es 90 s (`ReenvioReportes.cs:424`), así manda el del cliente. Lectura del PDF acotada a 32 MB por `Content-Length` y por bloque (`ClienteRender.cs:154-163`); ProblemDetails acotado a 64 KB (`ClienteRender.cs:224-227`). Sin lectura sin límite. Observación de memoria en S210-05.

**(4) Deserialización del contrato.** Mismas opciones en los dos extremos (`ClienteRender.cs:66`, `EndpointsRender.cs:26`); campos desconocidos se ignoran (omisión de System.Text.Json) y la versión distinta de 1 da 400 `RENDER_VERSION` → 503 en la principal. Sin `[JsonPolymorphic]` ni tipos `object` deserializados a tipos concretos. URL o rutas en el contenido: `Empresa.Logo` y las imágenes del diseño llegan como texto y se insertan en `src` (`GeneradorRazor.cs:101`, `PlantillasRazor.cs:87`); el bloqueo de red y de `data:` anidados es de la API de reportes (`PoliticaRedNavegador`, `ConvertidorPdf.cs:215`), revisado en T4-01, no cambia aquí. La mutación a `SnakeCaseLower` rompe 29 casos según el PR (no repetida por mí). **Correcto.**

**(5) Errores y reintentos.** Los rechazos de instalación (404, 400 `RENDER_VERSION`/`PARAMETRO_INVALIDO`, 500, 503 desconocido, 413 sin código, tipo no PDF, PDF grande) dan 503 con texto fijo sin detalles internos (`ClienteRender.cs:206-215`, `253-256`); solo pasan los códigos de la tabla 5.3, con el texto limpio y acotado por `DetalleParaRegla` (300 caracteres, sin controles). Sin reintentos en `ClienteRender`. El transporte de .NET puede reintentar una petición en una conexión reutilizada que se cerró antes de la respuesta [inferido]; el render no tiene efectos (la copia la registra la principal antes), así que no duplica nada. Observaciones S210-01 y S210-03.

**(6) Pruebas.** Las 28 pruebas de `ClienteRenderTests` prueban lo que dicen, con dos matices: `Un_render_sin_respuesta_se_abandona_a_los_35_s` (`ClienteRenderTests.cs:277-292`) comprueba la constante de 35 s y el abandono con un plazo de 1 s (correcto, pero el nombre sugiere más); `Un_PDF_de_mas_de_32_MB_se_descarta_sin_leerlo` (`254-266`) solo cubre el corte por `Content-Length`, no el del bucle (S210-06).

### S210-01 (Baja): el 401 pasa `codigo` y `X-GPOS-Sesion` sin lista blanca
- Riesgo: el caso `(401, _)` copia a la excepción cualquier `codigo` del cuerpo (hasta 64 KB, sin limpiar) y el valor crudo de `X-GPOS-Sesion` (`ClienteRender.cs:193-198`). En T4-02b el manejador pondrá `MotivoSesion` en la respuesta al puesto, y la Web decide por ese encabezado el mensaje y el cierre de sesión (`GPOS.Web/Servicios/ApiClient.cs:213`). El origen es la API de reportes con dueño verificado, por eso la probabilidad es baja; es defensa en profundidad. El `codigo` del caso `default` también se registra sin limpiar (`ClienteRender.cs:213`).
- Remediación: en el 401, aceptar `MotivoSesion` solo si es uno de `ProtocoloIntrospeccion.MotivoRevocada|MotivoReemplazada|MotivoCerrada` y el `codigo` solo si es nulo o de una lista conocida; en el registro, pasar el código por `DetalleParaRegla`. Esfuerzo: menos de 0,5 día-persona (puede ir con T4-02b).

### S210-02 (Baja): `ReintentarEn` sin tope
- Riesgo: `Retry-After` con fecha lejana o delta enorme llega tal cual a `ReintentarEn` (`ClienteRender.cs:178-181`); en T4-02b se volverá encabezado al puesto y puede bloquear el botón de reintento por horas. Solo se corta el negativo.
- Remediación: acotar a `[0, SegundosMaximos]` (30 s) o a 60 s. Esfuerzo: minutos.

### S210-03 (Baja): `FORMATO_INVALIDO` lleva el mensaje de la excepción de la plantilla
- Riesgo: la API de reportes arma el 400 con `"Error al ejecutar la plantilla: " + ex.Message` (`GPOS.Reportes.Api/Impresion/MotorRazor.cs:106`) y con los diagnósticos de compilación (`MotorRazor.cs:89,102`); `ClienteRender` los pasa al puesto (`ClienteRender.cs:191-192`). Puede exponer nombres de tipos o detalles internos al cajero que imprime con un formato roto. Es el mismo comportamiento del render en proceso (no es regresión) y queda acotado a 300 caracteres.
- Remediación (en la API de reportes, no en este PR): mensaje genérico para errores de ejecución con un identificador de correlación y el detalle solo en el registro; dejar los diagnósticos de compilación para el diseñador del formato. Esfuerzo: 0,5 día-persona.

### S210-04 (Baja, inferida): redirecciones automáticas en el cliente de la canalización
- Riesgo: `ManejadorCanal` no fija `AllowAutoRedirect = false` (`ReenvioReportes.cs:437-458`). Un 3xx del servicio se seguiría; como el `ConnectCallback` siempre abre la misma canalización verificada, el token no puede salir del equipo, y .NET quita `Authorization` al redirigir [inferido de la implementación de `RedirectHandler`; no verificado en este equipo]. Un 302 convertiría el POST en GET y daría un error confuso, no una fuga.
- Remediación: `AllowAutoRedirect = false` en `ManejadorCanal` (afecta también al reenvío; pertenece a T2-04/T3-01). Esfuerzo: minutos más una prueba.

### S210-05 (Baja): picos de memoria
- Riesgo: `Serializar` arma el arreglo completo antes de comparar con 16 MB (`ClienteRender.cs:110-111`); un modelo patológico (por ejemplo un resultado con celdas enormes) consume su tamaño completo solo para rechazarlo. El PDF se acumula en `MemoryStream` y `ToArray` lo copia (`ClienteRender.cs:156-164`): hasta ~64 MB por petición. La concurrencia la limitan los cupos del render (429), así que el pico total está acotado [estimado: con el cupo por omisión, unos cientos de MB en el peor caso].
- Remediación: serializar a un flujo con contador que corte al pasar el tope, y devolver `GetBuffer()` recortado o un `Stream` en vez de `ToArray`. Opcional; esfuerzo 0,5 día-persona.

### S210-06 (Baja): huecos de prueba
- Sin prueba del corte de 32 MB dentro del bucle (respuesta sin `Content-Length` o con un `Content-Length` falso y menor): `ClienteRender.cs:161` no se ejerce.
- Sin prueba de que ninguna línea de `RegistroPrueba.Eventos` contiene el token (es barata y protege del cambio futuro de una plantilla de registro).
- El nombre «a los 35 s» de la prueba del plazo describe la constante, no el tiempo medido.
- Remediación: dos pruebas nuevas en `ClienteRenderTests` (respuesta en trozos de más de 32 MB; recorrer `Eventos` buscando el token). Esfuerzo: 1-2 horas.

## 5. Controles bien implementados

- Dueño de la canalización verificado antes del primer byte, con 5122 crítico y prueba con canalización impostora real (`ReenvioReportes.cs:446-449`, `ClienteRender.cs:128-132`, `ClienteRenderTests.cs:146-167`).
- Ruta fija por método y `BaseCanal` constante; el puesto no fija ruta, host, empresa ni usuario.
- Falla cerrada uniforme: 503 con texto fijo para todo error de instalación; la tabla 5.3 completa probada (14 filas, `ClienteRenderTests.cs:198-238`), incluido que el texto interno no pasa.
- Opciones JSON propias del canal: el convertidor de enumeraciones y el filtro de costos de la principal no se cuelan (`ContratoRenderTests.cs:96-120`); el costo que viaja no se imprime en el conduce (`FormatoConduceTransferencia.cs:92-102`).
- Cancelación del puesto propagada sin convertirla en 503 ni en evento 5121 (`ClienteRender.cs:133-137`).
- Contrato movido sin cambiar el JSON y amarrado por pruebas de nombres y de ida y vuelta (28 modelos dorados).
- P170-07 decisión (b) y condición C-1: el contrato no las contradice. La marca viaja como dato (`Copia`, entero; `VistaPreviaSinValor`), y `TextoMarca` es calculada y no deserializable (`ModeloImpresion.cs:58-68`); dónde se estampa (encabezado/pie de Chromium) y la lectura del `/MediaBox` de cada página son del render en la API de reportes.

## 6. Remediaciones priorizadas

1. S210-01 y S210-02 junto con T4-02b, antes de que `MotivoSesion` y `ReintentarEn` lleguen a la respuesta (lista blanca y tope). < 0,5 día.
2. S210-06: dos pruebas. 1-2 horas.
3. S210-04: `AllowAutoRedirect = false` en `ManejadorCanal` (dueño: quien mantiene T3-01). Minutos.
4. S210-03 en la API de reportes, en la siguiente pasada de T4-01. 0,5 día.
5. S210-05 opcional.

Condiciones para T4-02b (no son hallazgos de este PR):
- `AutorizarDesde(ctx)` solo dentro de la petición del puesto; el trabajo en segundo plano usa `TokenServicio.AplicarA`, nunca una clausura con el token del usuario.
- `EmpresaInfo`, `FormatoImpresionDto` y el modelo salen de la sesión y la base de la empresa de la sesión, nunca del cuerpo del puesto; el privilegio «Ver costos» se aplica al armar el modelo (`FabricaModelo.cs:136,165`), porque el canal ya no filtra.
- El registro de la copia (`doc.Impresion`) ocurre antes del render: un 503 tras registrar no debe dejar al usuario sin forma de reintentar sin otra copia (reintento libre F-3).

## 7. Recomendación

**Aprobado con observaciones** (recomendación técnica; la decisión de unir es del propietario). Sin hallazgos Críticos, Altos ni Medios; seis Bajos, dos de ellos para resolver con T4-02b.
