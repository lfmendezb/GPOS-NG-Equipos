Para: B        De: C        Fecha: 2026-10-22
Tipo: Contraste de revisiones (cuatro informes de seguridad de A frente a mis siete informes de pruebas del 22-oct)
Repositorio y ramas: GPOS-NG `origin/a/adr90-rt05-tls-escucha` @ 38367542 (contiene fe8dbc9c, cf4d5f96 y la unión del #152), `origin/b/deuda-pr2-p137-p140`, `origin/b/ola5-t4-01-render`
Estado: Abierto

# Contraste de las relecturas de A con mis veredictos

Solo lectura: `git fetch origin` y `git show`/`git grep` sobre las ramas. No compilé ni ejecuté nada. **V** = verificado en el código o en git (ruta:línea); **I** = inferido, no ejecutado.

Informes de A leídos (nombro «relectura 3», «4» y «5» por el orden en que se hicieron):
- `relectura3-seguridad-pr2-adr90-2026-10-22.md` (338d899f R2-01/R2-02 y 89f03411 P139-01): relectura 3.
- `relectura4-seguridad-p140-03-2026-10-22.md` (los 9 commits de la deuda, P140-03): relectura 4.
- `relectura-seguridad-p140-03-338d899f-89f03411-2026-10-22.md` (fe8dbc9c y reglas de arquitectura): relectura 5.
- `revision-seguridad-pr152-t4-01-2026-10-22.md` (#152 @ cf6ccf98): revisión #152.

Mis informes: `revision-deuda-p137-p140`, `revision-pruebas-pr140`, `revision-pruebas-pr137`, `revision-pruebas-pr139`, `revision-cierre-p139-01`, `revision-pruebas-pr152-t4-01-y-dorados`, `revision-correcciones-pr152`.

## Resumen en cuatro líneas

- **Contradicciones reales: 2** (EventId de `RegistroFallido`; constructor `(StoreName, StoreLocation)` del almacén) y **2 matices** (variantes de ruta P152-09; límite de bucles en el validador). En las dos reales A tiene razón en lo esencial; en la segunda queda un hueco que A no cierra (sección 2).
- **A va más allá en unos 20 puntos** (sección 1; las filas marcadas A VA MÁS ALLÁ); propongo 26 pruebas nuevas, PC-01 a PC-25 con PC-22b (sección 3).
- **Yo voy más allá** en los puntos que A no menciona (P139-03, P139-10, P139b-01/02/03, P140b-05, P152-06, P152-16 a P152-20, entre otros). No es contradicción: A no se pronunció.
- Dos estados de código que cambian lo que dije: R4-02 está cerrado (V `SelectorCertificadoServidor.cs`, `venceNuevo` antes del `lock`) y R152-06 está aplicado (`Pipe = true`, commit cf4d5f96, V `ConvertidorPdf.cs:110`) **sin ninguna prueba** (V: `git grep` de `Pipe` y `remote-debugging` en `tests/` no halla nada).

## 1. Tabla de contraste

Veredicto del contraste: COINCIDE / A VA MÁS ALLÁ / YO VOY MÁS ALLÁ / CONTRADICCIÓN.

### 1.1 PR-2 de ADR-90: #140, deuda de #137 y #140, #139

| Tema | Lo que dice A | Lo que dije yo | Veredicto | Acción |
|---|---|---|---|---|
| P140-03: el bucle del refresco sobrevive a un registro que lanza; el 4749 fallido no produce un 4748 falso | Correcto en continuidad, falla cerrada, vida del bucle y no filtración (relectura 4 §2; relectura 5 §1) | CUBIERTA, arreglo mínimo y correcto, mutaciones mentales (revision-deuda (a)) | COINCIDE | Ninguna |
| `LogError` sin mensaje, ruta ni secretos | Solo `_servicio` y `e.GetType().Name` (relectura 4 §2.3) | No veo fuga; la 2.ª prueba afirma `DoesNotContain("secreta")` | COINCIDE | Ninguna |
| EventId propio para `RegistroFallido` | No hace falta; el 4752 sigue reservado; si se quiere alertar, reutilizar el 4748 (relectura 4 §2.4; relectura 5 §1) | P140b-01: recomendé un EventId propio (no el 4752) | **CONTRADICCIÓN** (§2.1) | Retiro P140b-01; ver §2.1 |
| 4748 doble si falla solo un proveedor (R4-01) | R4-01 Baja: segundo 4748 con motivo engañoso; remedio: escribir el 4748 fuera del `try` | En (a): «observación que ya existía, motivo engañoso», inferida, sin ID ni prueba | A VA MÁS ALLÁ | PC-01. R4-01 sigue abierto en la punta (V: `Refrescar`, `NoUsable` dentro del `try` y `catch` que lo repite) |
| `venceTomado` se calcula después del cambio (R4-02) | Baja informativa | No lo vi | A VA MÁS ALLÁ | Cerrado en fe8dbc9c (V). Sin prueba nueva: no es observable sin inyectar un fallo en `NotAfter`; basta la 2.ª prueba de P140-03 |
| `TargetHost` sin efecto | Mantenerlo y corregir el comentario; riesgo si la Web copiara `Headers.Host` (R4-03) | P140b-04: sin efecto; quitarlo o dejarlo con comentario; retracté mi frase de P140-04 | COINCIDE (A va un paso más: regla contra `Headers.Host`) | PC-03. Comentario ya puesto en fe8dbc9c (V). Hoy no hay usos de `Headers.Host` en `src/` (V, `git grep`) |
| Las dos afirmaciones que fijan `TargetHost` (`ClienteApiLocalTests.cs:166`, `EscuchaWebModoTests.cs:184`) | Dice que retirarlo obligaría a tocarlas; no dice que no prueban nada | Dan sensación de cobertura de un valor sin uso | YO VOY MÁS ALLÁ | Cambiar su nombre o comentario («valor de intención, no de seguridad») |
| P140-04: el manejador de producción valida nombre y SNI | Sí prueba lo que dice, sin debilitar la regla de arquitectura (relectura 4 §4) | CUBIERTA con el matiz de `TargetHost` | COINCIDE | Ninguna |
| P140-01: prueba del almacén real | Riesgo bajo de la prueba (solo lectura, sin llave privada); **no** al constructor `(StoreName, StoreLocation)`; sí un campo `Ubicacion`/`Nombre` fijo (relectura 4 §5) | Propuse el constructor interno; luego «acepto como deuda» con TL-01 | **CONTRADICCIÓN** (§2.2) | Aplicado por B (fe8dbc9c). Falta lo que A no cubre: PC-02 |
| P140-02: RSA y llave que no se abre | Correcta; la llave se crea en el KSP del usuario y se borra (relectura 4 §4) | PARCIAL, ACL real a laboratorio (TL-02) | COINCIDE | Ninguna |
| P137-01..05 (deuda de #137) | P137-01 y P137-05 revisados; P137-02/03/04 «solo por encima» (relectura 4 §4) | CUBIERTAS; pedí confirmar el quinto caso de P137-04 | YO VOY MÁS ALLÁ | Sigue pendiente la confirmación de B del quinto caso (sección 4) |
| Pruebas P137b-01..04, P140b-02, P140b-03, P140b-05 | Sin pronunciamiento | Hallazgos Bajos | YO VOY MÁS ALLÁ | Sin cambio |
| R2-01: el `catch` de `Program.cs` de la API solo escribe `ex.Message` | Cerrado: regla semántica más texto exacto fijado y 12 muestras negativas (relectura 3 §2) | No revisé 338d899f | A VA MÁS ALLÁ | PC-23 (CRLF; ver §5) |
| R2-02: validación propia del certificado (`SslStream`, `ServerCertificate…ValidationCallback`) en todo `src/` | Cerrado, con dos excepciones nombradas (relectura 3 §2) | No revisé 338d899f | A VA MÁS ALLÁ | Sin hallazgo mío |
| R5-01: `CuerpoSiExiste` cuenta llaves sin descontar cadenas ni comentarios | Baja, opcional | No lo vi | A VA MÁS ALLÁ | PC-04. V: `RedPlataformaArquitecturaTests.cs:195-206` cuenta `{` y `}` sobre el texto crudo |
| R5-02 / R3-01: excepción por nombre de archivo, no por ruta | Baja, opcional | No lo vi | A VA MÁS ALLÁ | PC-05 |
| P139-01 (`estricto` de `Preparar` en la API) y su cierre | Correcto; S5 coincide con `Program.cs:56`; una sola clase `ComprobacionAnillo` (relectura 3 §2) | Alta, luego Cerrado con cuatro Bajas (revision-cierre-p139-01) | COINCIDE | Ninguna |
| Prefijo libre `(?:\w+\s*\.\s*)*` de S5 | R3-01: admite otra clase `ComprobacionAnillo`; fijar el prefijo | P139b-03: riesgo teórico, «cubierto porque la clase vive en un solo lugar»; propuse anclar con `Argumentos` | COINCIDE (distinto remedio) | PC-06 |
| P139b-01 (patrón no anclado), P139b-02 (`#if` dentro de los argumentos), P139b-04 (Web con texto crudo) | Sin pronunciamiento | Bajas | YO VOY MÁS ALLÁ | PC-07 |
| P139-03 (`#if` distinto de `DEBUG` se lee como código vivo) y P139-10 (huecos del analizador textual) | Sin pronunciamiento; solo dice que la regla es «búsqueda de texto» y que cubre las vías conocidas (relectura 5 §2) | P139-03 Media; P139-10 Baja | YO VOY MÁS ALLÁ | Sigue abierto en la punta (V: `ProgramaApiTexto.cs:151`, cualquier condición que no sea `DEBUG` o `!DEBUG` entra como `(false,false)`). PC-07 |

### 1.2 #152 (T4-01)

| Tema | Lo que dice A | Lo que dije yo | Veredicto | Acción |
|---|---|---|---|---|
| Doble barrera `/interno/render/*` (S152-01/P152-01) | R152-01 Cerrado; sin la 1.ª barrera una petición HTTP recibe 401 en vez de 404; la prueba solo corre en Debug y la 2.ª barrera cubre Release | P152-01 Alta, luego cerrado en lo esencial; P152b-03: solo Debug | COINCIDE | Ninguna |
| 401 en las 4 rutas, validación por petición | R152-02 Cerrado; la revocación se ve en ≤15 s por la caché (diseño de la cl. 6) | P152-04, luego P152b-01 (mismo matiz) | COINCIDE | Aclarar el comentario de la prueba de revocación (A y yo lo pedimos) |
| Cuerpo no se lee antes de autenticar; 16 MB → 413 | R152-03 Cerrado; recomienda la prueba barata de C (cuerpo anunciado y no enviado con token inválido) | P152-05, P152b-02 | COINCIDE | PC-08 (la prueba de P152b-02, aún sin hacer) |
| Plantilla Razor que no termina | R152-04 Media. Añade: desborde de pila termina el proceso (.NET no lo captura) y `OutOfMemory` con `HeapHardLimit`; el validador permite bloques de código (V `ValidadorPlantillas.cs:33-38` prohíbe `@functions` pero no bloques ni funciones locales). Propone C-02-1 a C-02-5 | P152-02 Media: bucle sin fin agota el cupo (inferido). Mi opción «límite a bucles en el validador» | A VA MÁS ALLÁ (+ matiz en §2.4) | PC-09 a PC-12 |
| Dos grupos de concurrencia estándar/personalizado (C-02-1) | «Imprescindible»: estándar con 2 cupos propios | P152-07: probé que no comparte con consultas; no pedí separar estándar de personalizado | A VA MÁS ALLÁ | PC-09 |
| Contador de huérfanos con 503 y reinicio controlado; cuarentena persistida por huella; recuperación del servicio | C-02-2, C-02-3, C-02-4 | Propuse contador de hilos huérfanos con `/api/salud` (P152-02) | COINCIDE en el contador; A VA MÁS ALLÁ en reinicio, cuarentena y recuperación del SCM | PC-10, PC-11, PC-12 |
| Chromium con JS, sin intercepción; logo sin revalidar al renderizar | R152-05 Media. V: el logo se emite en `src="@Model.Empresa.Logo"` sin `Evaluar` (`GeneradorRazor.cs:101`), mientras las imágenes del diseño sí se revalidan (`:104-108`); el cortafuegos no filtra loopback (I) | P152-08: H-T4-09 abierto, T4-03 recortable; prueba con `TcpListener`; no vi el hueco del logo | A VA MÁS ALLÁ | PC-13 (logo), PC-14 (intercepción, ya en mi P152-08) |
| T4-03 como condición de T4-02 (núcleo N-1 a N-5) | Recomienda; aceptación de riesgo solo como respaldo con caducidad | Mismo (P152-08 «condicionar T4-02 a T4-03 o a aceptación firmada») | COINCIDE | Ninguna |
| Puerto de depuración TCP de Chromium (R152-06) | Media, nuevo: usar `Pipe = true` | No lo vi | A VA MÁS ALLÁ | **Aplicado** en cf4d5f96 (V). Falta la prueba: PC-15 |
| Perfil de Chromium en `TEMP`, 32 bits, nunca se borra (R152-07, DM-11) | Media; remedio con SDDL, 128 bits, borrado al cerrar | P152-11 (observación): «no borra los perfiles… fuga en disco por reinicio» | A VA MÁS ALLÁ (mismo hecho, otra gravedad y remedio) | Sigue así en la punta (V `ConvertidorPdf.cs:101`: `Guid.NewGuid().ToString("N")[..8]`). PC-16 |
| Lista negra de `ValidadorPlantillas` evadible; Razor con las credenciales del servicio (R152-08) | Media; remedio de fondo: proceso hijo (decidir el 20-nov) | P152-14 (muestras hostiles por la ruta); no evalué la evasión | A VA MÁS ALLÁ | PC-17 |
| Caché de plantillas sin tope (R152-09) | Baja; contador y evento a 500 plantillas | Mencioné «nunca se expulsa» en P152-15 (Memoria) | COINCIDE (A concreta el remedio) | PC-18 |
| `Visual` sin `Diseno` ejecuta `Plantilla` como Razor (R152-10) | Baja; V `ServicioRender.cs:39-41` | No lo vi | A VA MÁS ALLÁ | PC-19 |
| Cuerpo leído antes de tomar cupo (R152-11) | Baja; V `EndpointsRender.cs:73 < :76` | No lo vi | A VA MÁS ALLÁ | PC-20 |
| `PorCanalInterno` no mira el nombre de la canalización (R152-12) | Baja; V `EndpointsReportes.cs:129` | Lo leí y lo juzgué «coherente con la exportación» (revision-correcciones-pr152) | A VA MÁS ALLÁ (desestimo mi juicio; ver sección 4) | PC-21 |
| Chromium hereda el entorno del servicio (R152-13, DM-04) | Baja; `comprobar-servidor` debe aplicar K3 a `GPOS.Reportes` | No lo vi | A VA MÁS ALLÁ | PC-22 |
| Las rutas de render no leen `rptsis` (R152-14) | Baja documental; precisión de la cl. 6 que caduca en T4-11 | P152-04 (c) y P152b-05: «el render no cruza `token.empresa` con `modelo.Empresa`» | COINCIDE | PC-22b (ver §3) |
| D-25 (A4, Oficio y Media carta con `size: letter`) | Defecto con efecto en la integridad (totales fuera de la hoja en Media carta, I); no capturar dorados de esos papeles hasta corregir | D-25: «¿defecto o diseño? decidir antes de capturar» | COINCIDE (A resuelve la pregunta con las medidas) | PC-24 |
| D-26 (método de comparación visual) | A favor de la comparación estructural; añade «PDF sin contenido activo» | Recomendé lo mismo | COINCIDE (A añade el control de contenido activo) | PC-25 |
| Fuga de pestaña al cortar en `NewPageAsync` | Lo recoge y lo pasa a T4-03 | P152-03 (3) | COINCIDE | Ninguna nueva |
| Dorados: P152-06, P152-16 a P152-20 (JSON entre procesos, regenerar sin guarda, ramas no ejercitadas, cl. 9) | Solo menciona D-25 y D-26 | Hallazgos Medios/Bajos | YO VOY MÁS ALLÁ | Sin cambio |
| P152-09 (variantes de ruta en el listener HTTP) | Con la 2.ª barrera «las variantes dejan de importar para el render» | Baja, Theory con variantes | CONTRADICCIÓN menor (matiz, §2.3) | Bajar a informativa para el render |
| P152-13 (precalentamiento, 503 sin navegador) | Reconoce que Chromium arranca con el servicio por el precalentamiento (V `appsettings.json:41`) | Precalentamiento sin prueba | COINCIDE | Ninguna nueva |

## 2. Contradicciones: análisis del código

### 2.1 EventId de `RegistroFallido` (P140b-01 frente a la relectura 4 §2.4 y la relectura 5 §1)

- **A:** no hace falta; un registro de fallo que depende del mismo proveedor roto no es una señal fiable; el 4752 está reservado; si se quiere alertar, reutilizar el 4748.
- **Yo:** el `LogError` sale con Id 0 y ninguna regla de alerta por número lo verá; recomendé un EventId propio (no el 4752).
- **Código (V):** `RegistroFallido` (`SelectorCertificadoServidor.cs`, bloque `RefrescarPeriodicamente`) escribe `LogError` sin EventId y tiene su propio `catch (Exception)`.
- **Quién tiene razón: A.** Razonamiento, por casos:
  1. Si el registro falla del todo, ningún ID sirve (el propio evento se pierde).
  2. Si falla solo un proveedor (I: `Logger` de Microsoft.Extensions.Logging escribe en todos y al final lanza un `AggregateException`), el 4748 o el 4749 original ya llegó al Visor de eventos con su Id; el `LogError` es solo diagnóstico adicional.
  3. En ambos casos un Id nuevo no mejora la vigilancia. Mi propuesta pagaba una reserva de la franja 4743-4752 por una señal de segundo orden.
- **Lo que mantengo:** la cobertura de no filtrar el mensaje y de que el bucle sigue vivo está bien probada; no pido nada más aquí.
- **Acción:** retiro P140b-01. No hay prueba nueva.

### 2.2 Constructor interno `(StoreName, StoreLocation)` frente a campos `Ubicacion`/`Nombre` (P140-01 frente a la relectura 4 §5)

- **A:** el constructor abre la puerta a que la fábrica pase `CurrentUser` y la regla de arquitectura no lo notaría; en `CurrentUser\My` escribe cualquier proceso de la cuenta del servicio; la prueba tendría que escribir en un almacén real. Alternativa: campos fijos y una aserción.
- **Yo:** el constructor con un almacén propio en `CurrentUser` haría correr la prueba en cualquier PC y detectaría SHA-1, minúsculas, primer certificado sin comparar.
- **Código (V):**
  - La regla `RedPlataformaArquitecturaTests.cs:103-108` solo busca `new\s+AlmacenCertificadosServidorWindows\s*\(`: no fija los argumentos. A tiene razón en el riesgo.
  - fe8dbc9c ya aplica la propuesta de A: `AlmacenCertificadosServidor.Windows.cs` tiene `internal static readonly StoreLocation Ubicacion` y `StoreName Nombre`, usados por el único `new X509Store(Nombre, Ubicacion)`; la prueba `El_almacen_de_produccion_es_LocalMachine_My_y_se_abre_con_los_campos_fijos` (`AlmacenCertificadosServidorWindowsTests.cs`) comprueba los campos y que el único `new X509Store(...)` los use (por texto).
- **Quién tiene razón: A en el riesgo, yo en un hueco que sigue abierto.** La solución de A cierra la mutación `LocalMachine → CurrentUser` en cualquier PC. No cierra (V: nada nuevo las toca) las mutaciones «comparar `GetCertHashString()` (SHA-1)», «sin mayúsculas», «devolver el primer certificado sin comparar» ni «no liberar los no coincidentes» salvo en una máquina con un certificado propio en `LocalMachine\My`.
- **Alternativa que no tiene el defecto de ninguna de las dos (I, cambio de producción pequeño):** extraer la elección a una función estática pura `internal static X509Certificate2? Elegir(IEnumerable<X509Certificate2> candidatos, string huella)` que `BuscarPorSha256` llama sobre `almacen.Certificates`. La prueba la ejerce con certificados en memoria (`CertificadoPrueba`), sin abrir ni escribir ningún almacén y sin constructor nuevo. Es PC-02.
- **Acción:** retiro mi constructor; propongo PC-02. TL-01 sigue en pie para el laboratorio.

### 2.3 P152-09 (variantes de ruta): matiz

- **A (R152-01):** con la 2.ª barrera, que responde 404 fuera de la canalización antes de crear el plazo y de leer el cuerpo (V `EndpointsRender.cs:67`), las variantes que el filtro no reconozca «dejan de importar» para el render.
- **Yo:** Theory con `//interno`, `%`-codificadas, barra final y otros métodos.
- **Quién tiene razón: A** para `/interno/render/*`, porque la comprobación es del propio punto final y no depende de la normalización de la ruta (V). Para el resto de `/interno/*` (exportación) A dice que tiene su propia segunda barrera (`PorCanalInterno`); no leí esas rutas completas (I).
- **Acción:** bajo P152-09 a informativa para el render. La Theory sigue siendo barata (0,25 dp) como contrato, no como defensa.

### 2.4 «Límite a las construcciones de bucle en el validador» (P152-02 frente a R152-04 y 6.1)

- **A:** descartado: indecidible, evadible (R152-08) y rompe plantillas legítimas. La solución de fondo es el proceso hijo, no el validador.
- **Yo:** lo listé como una de tres opciones, aclarando que rompería plantillas con `for` y que no medí cuántas de las 62 base lo usan.
- **Quién tiene razón: A.** Un patrón de texto no decide la terminación y la recursión sin `while` ni `for` existe en un bloque de código o función local (V: el validador no los prohíbe, `ValidadorPlantillas.cs:33-38`). Retiro esa opción; en mi lista queda solo «aceptar con alarma» o «proceso hijo».

## 3. Hallazgos de A que mis planes de pruebas aún no cubren

ID = prueba nueva sugerida. Esfuerzo en días-persona (dp), inferido ±40 %.

| ID | Hallazgo de A | Prueba | Dónde / cómo | dp |
|---|---|---|---|---|
| PC-01 | R4-01: dos 4748 por refresco si falla un solo proveedor | `Con_un_proveedor_de_registro_que_falla_en_el_primer_4748_sale_un_solo_4748_por_refresco`: `RegistroRoto` que lanza solo en la primera escritura `Critical` y deja pasar las demás; contar los 4748 capturados por el otro proveedor tras un `Avanzar(Refresco)` con huella mala | `SelectorCertificadoServidorTests`, `RelojManualTls`. Hoy debe fallar (2 en lugar de 1); marcar `Skip` con referencia hasta que A mueva el 4748 fuera del `try` | 0,1 |
| PC-02 | R4-01 no; esto es de P140-01 (§2.2) | `Elegir_halla_por_SHA_256_en_mayusculas_y_no_por_SHA_1_ni_en_minusculas_y_libera_los_demas` | Requiere extraer `Elegir` (cambio de producción de A); certificados en memoria | 0,15 |
| PC-03 | R4-03: nadie fija `Headers.Host` | Regla de arquitectura: ningún `Headers.Host` ni `.Host =` sobre `HttpRequestMessage` en `src/` (hoy 0 usos, V) | `RedPlataformaArquitecturaTests`, con autoprueba sintética positiva y negativa | 0,1 |
| PC-04 | R5-01: llaves dentro de cadenas en `CuerpoSiExiste` | Autoprueba: cuerpo de la excepción con `"}"` y `"{"` en una cadena y un comentario; debe delimitar bien o fallar de forma explícita | `RedPlataformaArquitecturaTests` (hoy cuenta sobre texto crudo, V `:195-206`) | 0,1 |
| PC-05 | R5-02 / R3-01: excepción por nombre, no por ruta | Autoprueba: un segundo `ClienteApiLocal.cs` en otra subcarpeta de `GPOS.Comun.Servidor` con la misma firma no queda exceptuado | Misma clase; exigir ruta relativa en `ExcepcionValidacion` | 0,1 |
| PC-06 | R3-01: prefijo libre de S5 | Muestra negativa `…Api, Otro.ComprobacionAnillo.EsEstricto(builder.Configuration))` en `El_evaluador_de_S5_y_S6_detecta_el_desorden`; hoy pasa (V: `(?:\w+\s*\.\s*)*`) y debe fallar tras fijar el prefijo a `GPOS.Core.Infraestructura.Anillo.` | `OrdenProgramaApiTests` | 0,05 |
| PC-07 | (mío, relacionado con la relectura 5 §2) `#if` fuera de `DEBUG` y `#if` dentro de los argumentos de `Preparar` | Muestras con `#if false`, `#if RELEASE`, `#if DEBUG // x`, `#elif` alrededor del filtro y dentro de la sentencia de `Preparar`; `Limpiar` debe fallar con cualquier directiva no reconocida (V `ProgramaApiTexto.cs:151` hoy no lo hace) | `OrdenProgramaApiTests` | 0,15 |
| PC-08 | R152-03 matiz (de mi P152b-02, recomendado por A) | `Cuerpo_anunciado_y_no_enviado_con_token_invalido_responde_401_sin_esperarlo`: tubo crudo, `Content-Length: 16 MB + 1`, token inválido, `HTTP/1.1 401` en <10 s | `RenderInternoTests` | 0,1 |
| PC-09 | Condición C-02-1: dos grupos, estándar y personalizado | `Con_el_grupo_personalizado_lleno_un_ticket_estandar_responde_200`: `MaximoSimultaneos` personalizado = 2, dos renders retenidos por compuerta, un tercero → 429, un ticket de QuestPDF → 200 | `RenderInternoTests`, con costura de generador (compuerta, sin bucles de CPU) | 0,25 |
| PC-10 | C-02-2: cuarentena por huella, persistida, respaldo al estándar | `Un_formato_que_excede_30_s_se_imprime_despues_con_el_estandar_sin_esperar`; variante «reinicio»: el estado persiste en `%ProgramData%\GPOS NG\Reportes\render` | `RenderInternoTests` (cuando A/B construyan T4-02) | 0,5 |
| PC-11 | C-02-3: contador de huérfanos, 503 en `/api/salud` y reinicio controlado al tope | `Dos_renders_huerfanos_ponen_salud_en_503_y_piden_reinicio_controlado`, con compuerta | idem | 0,25 |
| PC-12 | C-02-4: recuperación del servicio configurada y comprobada | Caso de laboratorio TL-04: tras matar el proceso, el Administrador de servicios lo reinicia y `comprobar-servidor` lo verifica; prueba de unidad del instalador sobre las acciones de recuperación | VM-SRV; ~0,25 dp (es del instalador de B) | 0,25 |
| PC-13 | R152-05 / N-4: el logo no se revalida al renderizar | Theory sobre `Empresa.Logo`: `http://127.0.0.1:{p}/x`, `javascript:`, `data:image/svg+xml;base64,…`, `data:text/html,…` → el render responde 400 o lo omite con el evento 4790; y con navegador, ninguna conexión entrante al `TcpListener` | `RenderInternoTests` y `[FactConNavegador]` | 0,2 |
| PC-14 | R152-05 / N-1 y N-5: intercepción y JS apagado | `[FactConNavegador]` con `<img src="http://127.0.0.1:p/x">` y `<script>`; y la medición del rollo con JS de página apagado (A dice que `EvaluateExpressionAsync` sigue funcionando, I; confirmar) | `ChromiumAisladoTests` (T4-03), `Skip` con referencia hasta entonces | 0,5 |
| PC-15 | R152-06: `Pipe = true` aplicado sin prueba | (a) Sin navegador: un proxy de `LaunchOptions` o una aserción sobre los argumentos efectivos con `--remote-debugging-pipe` y sin `--remote-debugging-port`; (b) `[FactConNavegador]`: tras el primer render, el proceso de Chromium no tiene sockets TCP en escucha (`IPGlobalProperties.GetActiveTcpListeners` frente a los PID del árbol del navegador) | `RenderInternoTests` o `ConvertidorPdfTests`; la mutación «quitar `Pipe = true`» hoy no falla ninguna prueba (V) | 0,2 |
| PC-16 | R152-07 / DM-11: perfil en `TEMP`, 32 bits, sin borrado | Cuando B lo cambie: el perfil nace bajo `%ProgramData%\GPOS NG\Reportes\render`, nombre de 32 hex, y tras `DisposeAsync` no queda la carpeta; en el arranque purga restos | `ConvertidorPdfTests` | 0,25 |
| PC-17 | R152-08: lista negra evadible | Theory de plantillas hostiles por la ruta, con **una muestra por rama del patrón** (mi P152-14) más control de que el patrón no admite construcciones que el validador no ve (la lista concreta de evasiones no se escribe aquí, C10) | `RenderInternoTests`; el control de fondo es el proceso hijo, no el validador | 0,25 |
| PC-18 | R152-09: caché de plantillas sin tope | `Pasadas_N_plantillas_distintas_sale_un_evento_y_se_pide_reinicio_controlado` con N bajado por opción | `MotorRazorTests` | 0,25 |
| PC-19 | R152-10: `Visual` sin `Diseno` ejecuta `Plantilla` | `Un_formato_visual_sin_diseno_responde_400_FORMATO_INVALIDO` y `Razor_solo_con_modo_R_explicito` | `RenderInternoTests` | 0,1 |
| PC-20 | R152-11: lectura del cuerpo fuera del cupo | Medición (no puerta): 8 peticiones de 15 MB simultáneas; la memoria residente no pasa de un umbral; y prueba de que hay un semáforo de lectura | `MedicionRender` con `GPOST_B9` | 0,2 |
| PC-21 | R152-12: `PorCanalInterno` sin nombre | Con dos canalizaciones, una con otra ACL, el render por la segunda responde 404 | `RenderInternoTests` (cuando B compare con `Exportacion.Canalizacion`) | 0,15 |
| PC-22 | R152-13: entorno heredado por Chromium | Prueba del verbo `comprobar-servidor`: ningún nombre con `Clave`, `Password`, `Secret` ni `Password=` en el entorno de `GPOS.Reportes` (igual que K3 de `GPOS.Api`); y si `LaunchOptions` admite entorno propio, comprobar que el hijo no hereda | Instalador / `comprobar-servidor` | 0,2 |
| PC-22b | R152-14: el render no cruza empresa, y caduca en T4-11 | `El_render_rechaza_un_modelo_de_otra_empresa_que_la_del_token`, marcada `Skip("caduca en T4-11 / cl. 6")` con la referencia, para que el día que el render lea por `imp` la prueba exista | `RenderInternoTests` | 0,05 |
| PC-24 | D-25 confirmado como defecto por A | Prueba estructural: el `/MediaBox` de cada papel de hoja coincide con su medida en `ModeloImpresion.cs:194-197` (Carta 215,9×279,4; Media carta 215,9×139,7; A4 210×297; Oficio 215,9×355,6), tolerancia 0,5 mm. Falla hoy para A4/Oficio/Media carta (I, según A) | `[FactConNavegador]`; **no** capturar los dorados de esos papeles hasta que pase | 0,25 |
| PC-25 | D-26: PDF sin contenido activo | Con PdfPig: el PDF de salida no contiene `/JavaScript`, `/Launch`, `/EmbeddedFile` ni `/OpenAction` con script; `/URI` solo si la plantilla trae un enlace | Mismo conjunto que D-26 (estructural) | 0,1 |

Subtotal: 26 pruebas nuevas (PC-01 a PC-22, PC-22b, PC-23 de la sección 5, PC-24 y PC-25), unos 5 dp en total; las de #152 viajan con T4-02 y T4-03 y no con el #140.

## 4. Hallazgos míos que A desestimó, y si estoy de acuerdo

«Desestimó» significa que A lo valoró y concluyó que no hace falta, no que no lo mencionó (de lo no mencionado, la sección 1 lo marca «YO VOY MÁS ALLÁ»).

| Mi hallazgo | Cómo lo trató A | ¿Estoy de acuerdo? |
|---|---|---|
| P140b-01: EventId propio de `RegistroFallido` | «No hace falta», relectura 4 y 5 | **Sí.** Ver §2.1 |
| P140-01: constructor interno `(StoreName, StoreLocation)` | «No», alternativa de campos fijos | **Parcialmente.** A tiene razón en el riesgo; queda el hueco de las mutaciones de SHA-1 y de mayúsculas (§2.2, PC-02) |
| P140b-04: quitar `TargetHost` | «Mantenerlo» | **Sí.** Sin coste y con comentario; mi única objeción (las dos afirmaciones vacías) pasa a cambio de nombre |
| P152-09: variantes de ruta | «Dejan de importar para el render» | **Sí para el render** (§2.3) |
| P152-02: opción «límite a bucles en el validador» | «Descartada» | **Sí** (§2.4) |
| P152-11 (observación): perfil de Chromium sin borrar | Lo sube a Media (R152-07) | **Sí** y es más grave de lo que dije: nombre de 32 bits en una ruta de `TEMP` predecible |
| P152-04 (d): el token no sale en el registro | Lo da por verificado en los archivos del PR («Nada registra el token ni el cuerpo», A §4.2) | **Sí**, pero lo sigo sin prueba: una Theory que provoque un 500 y compruebe que el registro no contiene el token es barata (0,1 dp). La añado a PC-19 como segunda aserción |
| `PorCanalInterno` no mira el nombre: lo juzgué «coherente con la exportación» | A lo sube a Baja (R152-12) | **Rectifico.** Mi lectura «coherente» no valoró que una segunda canalización con otra ACL dejaría el render expuesto. PC-21 |
| P152b-03: la prueba del `Program` real solo corre en Debug | A lo registra y lo da por cubierto con la 2.ª barrera | **Sí**, pero con una condición: que el filtro oficial de la suite corra en Debug. Si alguien corre `-c Release`, la prueba del `Program` real falla (I) |

## 5. Observaciones a lo que A dice (no son contradicciones)

- **Dato que A marca como inferido y no pude cerrar (relectura 3, R2-01):** el texto exacto del `try`/`catch` se compara con `"\n"` (`OrdenProgramaApiTests.cs:411-415`) y `Limpiar` no normaliza `\r\n` en lo que leí (V: sin `Replace` de `\r` en `ProgramaApiTexto.cs`). Con una copia de trabajo en CRLF la prueba fallaría en rojo (falla cerrada). A informa 886 correctas, 0 con error; la suite lo confirma. **PC-23:** autoprueba que ejecute la comparación sobre el `Program.cs` convertido a CRLF y a LF; hoy depende de `* text=auto` (visto en mi revisión del #152).
- **El «sin hallazgo» de A sobre P140-01:** A anota que el atributo `Skip` abre dos almacenes reales al descubrir las pruebas, sin efectos. Coincide con mi nota de descubrimiento.
- **Relectura 4 §2.2 (3 intentos de escritura por refresco):** coincide con mi lectura de `Refrescar` + `RegistroFallido`; añade el recuento que yo no hice.
- **Estado del #152:** su rama ya está unida a `a/adr90-rt05-tls-escucha` (commit 5237e11b). Mis condiciones sobre T4-02 (P152-02, P152-03, P152-08) y las de A (C-02-1 a C-02-5, N-1 a N-5) son compatibles; las suyas son un superconjunto.

## 6. Qué no verifiqué

- No compilé ni ejecuté nada: no sé si las pruebas de fe8dbc9c, 38367542 ni cf4d5f96 pasan. Las cifras (886/0, 885/0/3, 469/0) son de A y B; no las repetí.
- No leí `EventosRed.cs` (en la rama no está en `src/GPOS.Comun.Servidor/Red/EventosRed.cs`; la ruta cambió) y por eso la reserva del 4752 y la franja 4743-4752 son lo que dice A, no verificadas por mí.
- El comportamiento de `Microsoft.Extensions.Logging` ante un proveedor que falla (`AggregateException`) y de `SocketsHttpHandler` (sobrescribe `TargetHost` con la cabecera `Host` o la URI) son inferencias de A y mías sobre el código del marco, no leídas aquí.
- El desbordamiento de pila que termina el proceso, `HeapHardLimit`, que Chromium use el puerto de depuración por omisión y que el cortafuegos de Windows no filtre loopback son los supuestos de A (I); no los probé.
- No leí `ValidadorPlantillas` más allá del patrón (líneas 28-40), ni `ServicioRender` fuera de la parte de `HtmlAsync` (líneas 30-50).
- No verifiqué qué pasa con la exportación (`/interno/exportacion`) respecto de las variantes de ruta (§2.3).
- No revisé `ProgramaApiTexto.SinDebug` completo: solo la línea 151 y los comentarios. No sé si B ha reaccionado ya a P139-03 en otra rama.
- No sé qué carpeta del propietario o de B contiene la revisión de seguridad de B con los S152-xx: A tampoco la tiene como archivo (A, Supuestos). La relación S152-xx ↔ R152-xx está en el aviso, que no leí.
- Las estimaciones de esfuerzo son mías, ±40 %.

## Recomendación a B

1. No hay nada bloqueante en este contraste. Las dos contradicciones se resuelven a favor de A (EventId) y de A con un hueco que cubre PC-02 (almacén).
2. Antes de unir el #140 con los 9 commits y fe8dbc9c: PC-01 (marcada `Skip` hasta que A mueva el 4748 fuera del `try`), PC-03 y PC-06 son baratas (≤0,25 dp en total) y cierran lo que A dejó como Bajo.
3. Antes de T4-02: PC-09, PC-13 y PC-15 (esta última porque `Pipe = true` ya está puesto y la mutación «quitar la línea» no la detecta nadie) y la condición PC-19.
4. Sigue pendiente de B la confirmación del quinto caso de P137-04 (30 s con la mutación) y si P140-01 corrió o se omitió en su PC; A tampoco lo resolvió.
