Para: B        De: C        Fecha: 2026-10-23
Tipo: Revisión adversarial (encargo B-a-C/2026-10-23-tareas-nuevas-para-c-4, tarea 2)
Prioridad: Media
Repositorio y rama: GPOS-NG #210 `b/t4-02a` @ 9288b01a (solo lectura), base `feature/modelo-ng`
Estado: Abierto

Convención: [V] = lo comprobé con un comando y su resultado en mi equipo; [I] = inferido del código o de la documentación. El árbol es el worktree de C en 9288b01a. No cambié el PR, no lo comenté y no empujé nada. Las pruebas nuevas son un archivo temporal sin commit (`tests/GPOS.Tests/Impresion/ClienteRenderRevisionCTests.cs`, 8 casos); copia en `traspasos/C/2026-10-23-revision-adversarial-pr210-pruebas.cs.txt`. No usé SQL: todas las pruebas de esta revisión son `Esquema=Neutral`. Compilé una sola vez a la vez.

# Veredicto

**Aprobado con observaciones** (recomendación técnica; la decisión es del propietario, C2). No hay hallazgos Críticos ni Altos. Hay uno de severidad Media (H210-01: el texto de `FORMATO_INVALIDO` se aplana y se corta a 300 caracteres, cuando la tabla 5.3 pide «el mismo texto»). Conviene resolverlo o declararlo como desviación antes de T4-02b, porque es entonces cuando lo ve el SUPER en el editor de Razor.

- Corrida propia sin mutar: las 59 pruebas nuevas de B pasan, 59/59 (`ClienteRenderTests` 28 y `ContratoRenderTests` 31) [V]. Coincide con el «59/59» del PR.
- Lo que pidió el encargo y se sostiene:
  - el dueño de la canalización se verifica antes del primer byte;
  - el 5122 sale con nivel Critical;
  - sin dirección, no se abre la canalización;
  - una solicitud de más de 16 MB responde 413 sin enviarse;
  - el plazo de 35 s funciona;
  - los 14 casos de la tabla se cumplen;
  - `AutorizarDesde` copia solo el `Authorization` y la marca de sondeo;
  - el contrato está en `GPOS.Contracts` con el mismo JSON.
- Mutaciones: hice 12 sobre `ClienteRender.cs`.
  - La suite de B detecta 5: ME, MF, MI, MQ y la de serialización que B ya declaró.
  - **No detecta 7:** MA, MB, MC, MD, MH, MJ y MK.
  - Mis pruebas R2 y R3 matan MB y MC.
- Pruebas hostiles: 5 de mis 8 casos fallan contra el código del PR y cada uno demuestra un hallazgo (R1, R4, R5, R7 y R8). Los otros 3 (R2, R3 y R6) pasan y fijan un comportamiento correcto que hoy nadie fija.

# 1. Alcance y superficie revisada

- `src/GPOS.Api/Impresion/ClienteRender.cs` completo (277 líneas), y lo que reutiliza de `src/GPOS.Api/Endpoints/ReenvioReportes.cs`: el cliente con nombre, `ManejadorCanal`, `DetalleParaRegla` y `CanalSuplantadoException`.
- `src/GPOS.Contracts/Impresion/ContratoRender.cs`, que se movió, y el `using` que se agregó en `ErroresRender.cs`.
- La contraparte del servidor, para comprobar que lo que el cliente espera sea cierto:
  - `src/GPOS.Reportes.Api/Endpoints/EndpointsRender.cs`;
  - `ErroresReportes.cs`;
  - `OpcionesRender.cs`;
  - `MotorRazor.cs`;
  - `ValidadorPlantillas.cs`;
  - `Seguridad/VerificadorIntrospeccion.cs`.
- Comparé contra el blueprint (`docs/arquitectura/2026-10-22-t4-02-blueprint-principal-sin-motores.md` en `master`, secciones 5.1, 5.3, 6.1, 6.2 y 10).
- Pruebas del PR: `ClienteRenderTests.cs` y `ContratoRenderTests.cs`.

# 2. Corridas [V]

| Corrida | Filtro | Resultado |
|---|---|---|
| Base (9288b01a + mis 8 pruebas), compilación limpia | `FullyQualifiedName~GPOS.Tests.Impresion.ContratoRenderTests\|FullyQualifiedName~GPOS.Tests.Impresion.ClienteRender` | 67 en total: **62 superadas, 5 con error**, 3 s. Las 59 de B pasan; de las mías, R2, R3 y R6 pasan y R1, R4, R5, R7 y R8 fallan (cada falla demuestra un hallazgo) |
| Cada mutación | `FullyQualifiedName~GPOS.Tests.Impresion.ClienteRender` (36 casos) | Tabla de la sección 3. Logs en el scratchpad (`mut-*.log`, `mut-*.diff`) |

Cada mutación se aplicó con `sed` sobre `ClienteRender.cs`, se compiló, se corrió y se restauró con `git checkout -- <archivo>`. Después de cada una, `git status` mostraba solo mi archivo de pruebas sin seguimiento.

Incidente que declaro: al reanudar tras el corte de sesión, el índice del worktree estaba corrupto y había 757 archivos rellenos de ceros (daño del corte, no un cambio mío ni del PR). Rehíce el índice desde HEAD y restauré los archivos con `git checkout -- .` solo en mi worktree. No afecta a ninguna rama.

# 3. Mutaciones [V]

Las líneas son de `ClienteRender.cs` en 9288b01a. «Suite de B» = los 28 casos de `ClienteRenderTests`.

| # | Mutación | Suite de B | Mis pruebas |
|---|---|---|---|
| **MA** | Quitar `:154`, la comprobación previa del `Content-Length` contra el tope de 32 MB | **No la detecta.** `Un_PDF_de_mas_de_32_MB_se_descarta_sin_leerlo` sigue pasando, pero pasa de **7 ms a 10 s**: sin la comprobación, el cliente espera un cuerpo que no llega hasta que vence el plazo de la prueba, y el resultado es el mismo 503. La prueba se llama «sin leerlo» y no lo comprueba | — (habría que afirmar el tiempo) |
| **MB** | Quitar `:161`, el tope de 32 MB en el bucle de lectura (respuesta sin `Content-Length`) | **No la detecta** | R2 la mata |
| **MC** | `:125` `PdfAsync(…, plazo.Token)` → `PdfAsync(…, ct)`: la lectura del cuerpo queda sin el plazo de 35 s | **No la detecta** | R3 la mata. Con esta mutación, un cuerpo detenido después de los encabezados cuelga la petición: `HttpClient.Timeout` no cubre el cuerpo con `ResponseHeadersRead` [I, por la documentación de .NET; R3 esperó más de 20 s sin respuesta] |
| **MD** | `:50` `MaximoProblemaBytes` de 64 KB → 64 MB | **No la detecta** | Solo cambia R4, que entonces pasa: el tope de 64 KB es lo que provoca H210-02 |
| ME | `:130` `LogCritical(5122)` → `LogError(5121)` | La detecta: `El_dueno_de_la_canalizacion_se_verifica_antes_de_enviar_el_modelo` | — |
| MF | `:122` `CreateClient(ClienteCanal)` → `CreateClient("otro")` | La detectan 17 casos | — |
| **MH** | `:111` `> MaximoSolicitudBytes` → `> MaximoSolicitudBytes + 900 KB` | **No la detecta.** La prueba usa unos 17 MiB, así que el límite exacto no está fijado | — |
| MI | `:133` el `when (ct.IsCancellationRequested)` → `when (false && …)`: el abandono del puesto se vuelve 503 | La detecta: `Si_el_puesto_abandona_se_cancela_sin_convertirlo_en_503` | — |
| **MJ** | `:233` sin `DetalleParaRegla` (el `detail` pasa crudo) | **No la detecta.** Nada fija si el texto se limpia o no | R5 pasa con esta mutación: la limpieza es la causa de H210-01 |
| **MK** | Quitar `:181`, que lleva a cero un `Retry-After` negativo | **No la detecta** | — |
| MQ | Quitar `:116` (`CancelAfter(Plazo)`) | La detecta: `Un_render_sin_respuesta_se_abandona_a_los_35_s` | R3 también |
| Mut. de B | Serialización `SnakeCaseLower` | 29 fallas (según el PR; no la repetí) | — |

No la ejecuté: la rama `|| !OperatingSystem.IsWindows()` de `:104`. En Windows es equivalente, y el arranque la cubre fuera de Windows (`ReenvioReportes.cs:399-401`) [I].

# 4. Hallazgos

| ID | Severidad | Título |
|---|---|---|
| H210-01 | **Media** | El texto de un 400 `FORMATO_INVALIDO` llega aplanado y cortado a 300 caracteres, no «con el mismo texto» |
| H210-02 | Baja | Si el ProblemDetails pasa de 64 KB, un `FORMATO_INVALIDO` llega como 503 `REPORTES_NO_DISPONIBLE` |
| H210-03 | Baja (seguridad, defensa en profundidad) | Si falta el registro del cliente con nombre, el token sale por TCP a `localhost:80` sin verificar el dueño |
| H210-04 | Baja | Un 200 `application/pdf` vacío se acepta como PDF |
| H210-05 | Baja (pruebas) | Los topes de 32 MB y el plazo sobre el cuerpo no están fijados por pruebas (MA, MB, MC) |
| H210-06 | Baja | 35 s no alcanzan para la conexión, la introspección y los 30 s del render: un 422 puede llegar como 503 |
| H210-07 | Baja | `Retry-After` con fecha no tiene límite (2.912.147 días) |
| H210-08 | Informativa (pruebas) | El tope de 16 MB no está fijado en su límite (MH), y el del servidor es configurable |

## H210-01 (Media): el texto de `FORMATO_INVALIDO` se aplana y se corta

- **Riesgo.** La tabla 5.3 del blueprint dice: «400 `FORMATO_INVALIDO` → 400 `FORMATO_INVALIDO` **con el mismo texto**».
  - `ProblemaAsync` pasa todo `detail` por `ReenvioReportes.DetalleParaRegla` (`ClienteRender.cs:233`). Esa función se escribió para el resultado de una regla de notificación (O175-04). Convierte los saltos de línea en espacios y corta en 300 caracteres (`ReenvioReportes.cs:227`, `:234-259`).
  - Los diagnósticos de Razor son varias líneas, «Línea N: …», hasta 10 errores (`src/GPOS.Reportes.Api/Impresion/MotorRazor.cs:89`, `:102`, `:116-121`).
  - Hoy la principal los da completos y con saltos de línea (`src/GPOS.Api/Impresion/MotorRazor.cs:86`, `:99`).
  - Con T4-02b, el SUPER verá en la vista previa del diseñador 2 o 3 errores en una sola línea con «…» [V para el cliente; I para cómo lo pinta la pantalla].
  - No es una de las desviaciones D-1 a D-4 que declara el PR.
- **Evidencia.**
  - R5 (`R5_El_texto_de_FORMATO_INVALIDO_llega_igual`, 10 diagnósticos con `\r\n`) falla [V]. Esperado: `…errores:\r\nLínea 3: The name '…`. Real: `…errores: Línea 3: The name 'v…`, cortado.
  - MJ: la suite de B no lo fija en ningún sentido.
- **Remediación (unas 2 horas).**
  - Para `FORMATO_INVALIDO`, conservar los saltos de línea y usar un tope propio, por ejemplo 4.000 caracteres, quitando solo los caracteres de control que no sean `\r` y `\n`. Para los demás códigos, `DetalleParaRegla` sirve.
  - Agregar R5 o una prueba equivalente.
  - Alternativa: declararlo como desviación D-5 con la firma de UX. La descarto porque el editor de Razor pierde diagnósticos.

## H210-02 (Baja): con más de 64 KB se pierde el código

- **Riesgo.** ASP.NET Core escribe las extensiones del ProblemDetails (`codigo`) **después** de `detail`. R6 lo verifica con `Results.Problem`, como hace `ErroresReportes.ManejarAsync`. Si el cuerpo pasa de 64 KB:
  - el JSON leído queda truncado y `JsonDocument.Parse` lanza;
  - `ProblemaAsync` devuelve `(null, null)` (`ClienteRender.cs:224-239`);
  - el rechazo cae en `default`: 503 `REPORTES_NO_DISPONIBLE` («avise al administrador, el documento quedó guardado») y un 5121 de nivel Error.
- **Cómo se alcanza** [I]: una plantilla cuyo error tiene un mensaje largo.
  - `MotorRazor.cs:106` concatena `ex.Message` sin límite. En .NET reciente, el mensaje de `FormatException` de `int.Parse` incluye la entrada.
  - Los diagnósticos citan identificadores de cualquier largo.
  - Solo lo escribe quien edita Razor (el SUPER). El efecto es un diagnóstico falso («el servicio no está disponible»), no una fuga.
- **Evidencia.**
  - R4: un 400 `FORMATO_INVALIDO` con `detail` de 70.000 caracteres llega como 503 (`Expected: 400, Actual: 503`) [V].
  - R6 pasa: en el JSON real, `codigo` va después de `detail` [V].
  - MD confirma que la causa es el tope.
- **Remediación (1 a 2 horas; el arreglo más barato está en el servidor).** Acotar el mensaje de `FormatoInvalidoException` en la API de reportes, por ejemplo a 4.000 caracteres, en `ErroresReportes.ManejarAsync` o en el constructor. Si no, que el cliente busque `codigo` con un `Utf8JsonReader` tolerante sobre el prefijo. Va junto con H210-01.

## H210-03 (Baja, seguridad en profundidad): sin el cliente con nombre, el token sale por TCP

- **Riesgo.**
  - `ClienteRender` confía en que `IHttpClientFactory.CreateClient("GPOS.Reportes.Canal")` tenga el manejador de la canalización.
  - Si ese nombre no está registrado, la fábrica no falla: devuelve un cliente por omisión.
  - La petición va entonces a `http://localhost` (`:52`), es decir, TCP al puerto 80, **con el token**, sin `ConnectCallback`, sin verificar el dueño y sin 5122. Solo deja un 5121 de nivel Error.
  - En Windows, cualquier proceso sin privilegios puede escuchar en el puerto 80 de loopback (no hay puertos privilegiados). Ese es justo el atacante del que protege T3-01.
- **Por qué es Baja y no Alta.** Hoy no se alcanza en producción:
  - `Program.cs:243` llama `AgregarReenvioReportes` siempre;
  - en Windows registra el canal aunque el reenvío esté apagado (`ReenvioReportes.cs:410`);
  - fuera de Windows, `ClienteRender.cs:104` corta antes [V lectura].
  - El riesgo aparece si T4-02b, otro anfitrión (un trabajador, un anfitrión de pruebas) o un cambio de nombre registra `ClienteRender` sin el canal. Es el mismo patrón que tiene ya `ReenvioReportes` (`:61`): no es nuevo de este PR.
- **Evidencia.** R7 escucha en `127.0.0.1:80` y construye `ClienteRender` con `AddHttpClient()` sin `AgregarReenvioReportes`. Recibió `POST /interno/render/documento`, `Host: localhost` y `Authorization: Bearer token-de-prueba-revision-c` [V].
- **Remediación (cerca de 1 hora; vale para los dos clientes).** Que la base de la canalización sea un nombre que no resuelve, por ejemplo `http://gpos-reportes.invalid` (RFC 6761). Así, un cliente sin `ConnectCallback` falla por DNS antes de enviar. Hay que comprobar antes que la API de reportes no filtre por `Host` (`AllowedHosts`) [I]. Alternativa: que T4-02b agregue una prueba de arranque que resuelva `IClienteRender` del contenedor real y compruebe que una canalización ajena da 5122.

## H210-04 (Baja): se acepta un PDF vacío

- **Riesgo.** Una respuesta 200 `application/pdf` con `Content-Length: 0` devuelve `byte[0]` como éxito (`ClienteRender.cs:148-164`). Con T4-02b, quien llama registraría la copia (`doc.Impresion`), adjuntaría o imprimiría un PDF vacío, y el comprobante fiscal perdería su «original» [I sobre T4-02b]. Hace falta un error en la API de reportes que devuelva 200 sin cuerpo. Un cuerpo cortado no basta: da `IOException` y 503 [I].
- **Evidencia.** R1: `Assert.Throws() Failure: No exception was thrown` [V].
- **Remediación (unos 30 minutos).** Exigir que el cuerpo empiece por `%PDF-`; si no, 503 con la causa en el registro.

## H210-05 (Baja, pruebas): los topes de 32 MB y el plazo del cuerpo no están fijados

- MA: `Un_PDF_de_mas_de_32_MB_se_descarta_sin_leerlo` pasa sin `:154`, solo que tarda 10 s. Remediación: afirmar que dura menos de 2 s, con el plazo de 10 s que ya usa.
- MB y MC no los detecta nadie. R2 (respuesta sin `Content-Length` de 40 MB → 503 con «32 MB» en el 5121) y R3 (cuerpo detenido → 503 en el plazo) los matan. Las dos pasan con el código del PR.
- Propuesta: aceptar R2 y R3 tal cual (en el anexo).

## H210-06 (Baja): 35 s no alcanzan

- **Riesgo** [I]. Los 30 s del servidor empiezan dentro del manejador, después de la autenticación (`EndpointsRender.cs:77-78`). Antes van:
  - la conexión a la canalización, hasta 5 s (`ReenvioReportes.cs:440`, `:446`);
  - la introspección, hasta 7 s sin caché (`VerificadorIntrospeccion.cs:26-27`, `:127`).
- En el peor caso, el 422 `RENDER_TIEMPO_AGOTADO` sale cerca de los 42 s, y el cliente ya cortó a los 35. El puesto recibe 503 «no disponible, avise al administrador» y un 5121 de nivel Error, en vez de 422 «superó el tiempo máximo». No hay daño a los datos; el diagnóstico es engañoso.
- Además, si alguien configura `GPOS:Reportes:Reenvio:SegundosEspera` por debajo de 35, `HttpClient.Timeout` corta antes (`ReenvioReportes.cs:424`).
- **Remediación (decisión de B).** Una de estas:
  - subir el plazo a 45 s;
  - registrar el plazo vencido del cliente como Warning con su propia causa;
  - que la API de reportes cuente los 30 s desde que llega la petición.

## H210-07 (Baja): `Retry-After` con fecha no tiene límite

`ClienteRender.cs:178-181` acepta `Retry-After` como fecha, sin tope superior. Con `Fri, 31 Dec 9999 23:59:59 GMT`, `ReintentarEn` vale 2.912.147 días (R8) [V]. Hoy no llega a la respuesta (D-4), pero T4-02b lo pondrá en el encabezado. Además, la mutación MK (quitar el piso de cero) sobrevive. Remediación: acotarlo, por ejemplo a 300 s, y probar los dos extremos.

## H210-08 (Informativa, pruebas): el tope de 16 MB

- `Una_solicitud_de_mas_de_16_MB_responde_413_sin_enviar` usa unos 17 MiB, así que mover el límite hasta 900 KB más no la rompe (MH) [V].
- `El_tope_de_la_solicitud_es_el_de_la_API_de_reportes` compara con el valor por omisión, pero `OpcionesRender.MaximoCuerpoBytes` es `{ get; set; }` y se puede enlazar desde la configuración (`OpcionesRender.cs:65`). Si alguien lo cambia en el servidor, divergen sin que falle nada. El efecto es menor: si el servidor baja su tope, responde 413 y el cliente lo pasa.
- Remediación:
  - probar justo en el límite (16 MiB y 16 MiB + 1 en el cuerpo serializado);
  - volver `MaximoCuerpoBytes` constante, o documentar que no se configura (la desviación D-2 ya apunta a eso).

# 5. Controles bien hechos [V salvo indicación]

- **Canalización con el dueño verificado y 5122.** `ClienteRender` usa el mismo cliente con nombre que `ReenvioReportes`. La prueba con la canalización impostora (otra cuenta esperada, SYSTEM) confirma: 503, un solo 5122 de nivel Critical y **0 bytes** leídos por el servidor falso. ME y MF la rompen y se detectan.
- **Sin dirección, nada sale.** La comprobación de `:104` va antes de serializar y antes de `autorizar`: el token no llega a ponerse en ninguna petición, y la prueba confirma 0 conexiones.
- **413 sin enviar.** Ocurre antes de abrir la canalización (0 conexiones).
- **Plazo de 35 s.** Está fijado en `PlazoPorOmision` y enlazado con la cancelación del puesto. El abandono del puesto se propaga como cancelación, no como 503 (MI). MQ se detecta.
- **Los 14 casos de `Los_codigos_del_render_llegan_al_puesto`.** Cubren las 8 filas de la tabla 5.3 que dependen de la respuesta, más D-3 (`PARAMETRO_INVALIDO` y 413 sin código → 503). De las 5 filas restantes, 4 tienen prueba propia (apagado, dueño, plazo, y 200 que no es PDF o pasa de 32 MB) y todas pasan. La fila «la canalización no responde (no existe, no conecta en 5 s)» no tiene prueba: por el código daría `TimeoutException` o `HttpRequestException`, que `:138` convierte en 503 y 5121 [I]. Conviene una prueba con un nombre de canalización que no exista (unos 15 min).
- **`AutorizarDesde`.** Lee los valores en el momento y no guarda el `HttpContext`, así que se puede usar después de la petición. Copia solo `Authorization` y la marca de sondeo; otros encabezados no viajan (la prueba lo confirma). Un token de dispositivo no llega a las rutas de usuario, porque la política por omisión lo rechaza (`Seguridad.cs:220-224`) [I]. El cliente con nombre redacta todos los encabezados en el registro (`ReenvioReportes.cs:427`). Los registros de `ClienteRender` no incluyen el token.
- **Sin reintentos automáticos** (`:101-143`, no hay bucle), como pide el blueprint en 6.2.
- **Contrato en `GPOS.Contracts`.** 31/31 en `ContratoRenderTests`: los 28 modelos dorados van y vuelven campo a campo, los nombres JSON son los mismos y la versión sigue en 1. Los tipos están en `GPOS.Contracts` y `GPOS.Reportes.Api` ya no los define. El filtro de costos de la principal no se cuela en el canal. No hay `JsonSerializable`, `JsonDerivedType` ni campos públicos en `GPOS.Contracts` que el movimiento pudiera alterar [V con grep]. Menor: el comentario de `ContratoRender.Version` («que esta API sabe leer») quedó del lugar anterior.

# 6. Remediaciones priorizadas

1. H210-01 (Media): texto completo de `FORMATO_INVALIDO`, con un tope propio y saltos de línea. Unas 2 h, antes de T4-02b.
2. H210-02: acotar el mensaje de `FormatoInvalidoException` en el servidor. Cerca de 1 h; se puede hacer junto con 1.
3. H210-05: aceptar R2 y R3 y afirmar el tiempo en la prueba de los 32 MB. Unos 30 min.
4. H210-04: exigir `%PDF-`. Unos 30 min.
5. H210-03: base de canalización que no resuelva, o una prueba de arranque en T4-02b. Cerca de 1 h, para los dos clientes.
6. H210-06, H210-07 y H210-08: decisión de B. Menos de 1 h cada una.

# 7. Qué no verifiqué

- La suite completa de `GPOS.Tests`, `RenderTrasladoTests` (requiere Chromium) y `MedicionRender` (B9).
- La API de reportes real detrás de la canalización: los casos usan un servidor HTTP/1.1 falso. H210-02 se apoya en que el orden de `Results.Problem` es el real (R6 [V]), pero no generé el 400 desde `MotorRazor`.
- Los tiempos de H210-06 en una instalación real (conexión y caché de la introspección): [I].
- Que la API de reportes acepte otro `Host` (condición de la remediación de H210-03): [I].
- La revisión de seguridad formal la hace A aparte, como dice el encargo.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos:
  - `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-23-revision-adversarial-pr210.md` (este informe);
  - `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-23-revision-adversarial-pr210-pruebas.cs.txt` (las 8 pruebas);
  - archivo sin seguimiento en el worktree de C: `tests/GPOS.Tests/Impresion/ClienteRenderRevisionCTests.cs`;
  - logs `mut-*.log`, `mut-*.diff` y `corrida-base.log` en el scratchpad.
- Supuestos: los comportamientos de .NET marcados [I] (`HttpClient.Timeout` con `ResponseHeadersRead`, mensaje de `FormatException`); que T4-02b registrará las copias después del render.
- Decisiones candidatas a ADR: Ninguna
- Entregas a otros agentes: B → decidir H210-01 a H210-08 y si acepta R2 y R3 (y R1, R4, R5, R7 y R8 una vez corregidos); A → tener en cuenta H210-03 en su revisión de seguridad del camino del token.
- Próximo paso recomendado: B corrige H210-01 y H210-02 y agrega R2 y R3 antes de unir el #210, o los declara como desviaciones.
