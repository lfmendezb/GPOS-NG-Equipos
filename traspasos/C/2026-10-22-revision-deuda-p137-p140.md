Para: B        De: C        Fecha: 2026-10-22
Tipo: Revisión de pruebas (cierre de la deuda P137-01..05 y P140-01..04)
Repositorio y rama: GPOS-NG origin/b/deuda-pr2-p137-p140 @ 8e2d6ef8 (9 commits sobre origin/a/adr90-rt05-tls-escucha @ 89f03411)
Estado: Abierto

# Revisión del cierre de la deuda de #137 y #140

Leí con `git show` los 9 commits, los archivos de prueba completos que tocan y la producción que respaldan: `EscuchaServidor.cs`, `ArranqueRed.cs`, `FuenteConfiguracionRed(.Windows).cs`, `SelectorCertificadoServidor.cs` (completo, con el diff de P140-03), `ClienteApiLocal.cs`, `AlmacenCertificadosServidor(.Windows).cs`, `SoporteTls.cs` (certificados, `AlmacenPrueba`, `RelojManualTls`), `SoporteRed.cs` y `SoporteEscucha`. **No compilé ni ejecuté nada** (ni dotnet, ni SQL, ni pruebas, ni mutaciones). Criterio: mutación mental línea a línea. «Leído» = visto en el código; «inferido» = deducido; «declarado por B» = lo dice el aviso o el mensaje del commit y yo no lo repetí.

## Veredictos

| Obs. | Veredicto | Mutación mental (por qué falla la prueba nueva) |
|---|---|---|
| P137-01 | CUBIERTA | `_ => null` en la lectura del entorno (`EscuchaServidor.cs`, sobrecarga pública): sin `DOTNET_STARTUP_HOOKS` ni `GPOS_MODO_RED` vistos, la decisión pasa a `ConModo` y los dos casos exigen `Denegado` con 4744 / 4743 → fallan. Ejercida de verdad |
| P137-02 | CUBIERTA | Borrar la rama «sin modo» de `Revisar`: el servidor doble sigue informando 127.0.0.1, nada detiene, `Esperar` agota 30 s → falla. Quitar el `ComprobarEfectivas()` final: falla `Al_recargar_se_vuelven_a_comprobar...`. `Revisar` que siempre detiene: falla la recarga benigna (la cancelación es síncrona, sin carrera) |
| P137-03 | CUBIERTA | Vaciar el `catch` de `ComprobarEfectivas`: el `ApplicationStarted` se traga la excepción, nada detiene, timeout → falla. Vaciar el de `Revisar`: igual. Quitar `Detener()` o el log de `Imprevista`: falla `Single(4743)` o el timeout. El tipo y la ausencia del mensaje (`secreta`) se afirman |
| P137-04 | CUBIERTA | Quitar `Detener()` de `ComprobarEfectivas`: los 5 casos comparten esa línea y `RunAsync` no termina → los 5 deben fallar por timeout (ver «el quinto caso» abajo) |
| P137-05 | CUBIERTA | `LocalMachine`→`CurrentUser`: `k.Name`; `Registry64`→`Registry32`: `k.View`; otra subclave: `_subclave` y el literal fijado. Ejercida |
| P140-01 | PARCIAL (acepto como deuda) | Con un certificado de equipo presente: SHA-1, sin mayúsculas, `CurrentUser`, primer certificado sin comparar, otro `StoreName` → fallan. Sin certificado en `LocalMachine\My` la prueba se omite. No se ejerce: `OpenExistingOnly`, liberación de los no coincidentes |
| P140-02 | PARCIAL (acepto como deuda) | RSA: rechazar la rama `rsa` o dejar solo ECDSA falla `Un_certificado_RSA_utilizable_se_carga` y el saludo TLS 1.2/1.3. Llave que no abre: quitar el `try/catch` de `MotivoNoUtilizable` falla la prueba nueva (declarado por B; coherente con la lectura). Falta la ACL real |
| P140-03 | CUBIERTA, con el arreglo de producción correcto | Quitar el `try/catch` del bucle: muere con la 1.ª excepción → falla la 1.ª prueba. Mover el 4749 otra vez dentro del `try`: aparece un 4748 → falla la 2.ª. Quitar `RegistroFallido`: falla la 2.ª (`Entradas.Count > 0`) |
| P140-04 | CUBIERTA (con el matiz de `TargetHost`) | Callback de validación propio en `Crear`: falla `Assert.Null(...RemoteCertificateValidationCallback)`. «localhost» derivado en servidor de sitio: falla el SNI (`Assert.Equal(Nombre, sni)`) y el caso `Nombre` (aparece `NameMismatch`). Cambiar `TargetHost`: no altera nada, ver P140b-04 |

## Hallazgos nuevos

| ID | Sev. | Qué |
|---|---|---|
| P137b-01 | Baja | La prueba de P137-01 depende del entorno de quien la corre: solo aísla `ASPNETCORE_HOSTINGSTARTUPASSEMBLIES`; con `ASPNETCORE_URLS`, `DOTNET_URLS` o similares fijadas en el equipo, la «fuente» que nombra el motivo es otra y el `Assert.Contains` falla (falla visible, no en silencio) |
| P137b-02 | Baja | La recarga benigna afirma que el valor cambió en la configuración, no que `Revisar` se ejecutó; si la suscripción se rompiera, esa prueba seguiría verde (las pruebas positivas de detención sí lo detectarían) |
| P137b-03 | Baja | `ServidorDoble` sustituye a Kestrel: se prueba el cableado y las reglas, no la forma real de las direcciones que informa Kestrel (por ejemplo `http://[::]:5071` frente a `0.0.0.0`). Eso sigue solo en la prueba opcional `GPOST_PRUEBA_ESCUCHA_RED=1` y en el laboratorio |
| P140b-01 | Baja | `RegistroFallido` escribe `LogError` sin `EventId` (Id 0): ninguna regla de alerta por número lo verá. Decisión de A (B ya la pregunta). Mi recomendación: un EventId propio; el 4752 reservado no, salvo que A lo asigne |
| P140b-02 | Baja | En la 1.ª prueba del refresco, `Esperar(() => reloj.Temporizadores > 0 && fuente.Lecturas == 1)` no demuestra que el bucle volvió a esperar: `Temporizadores` cuenta el `PeriodicTimer` vivo, que existe todo el tiempo. La prueba es correcta de todos modos (el `PeriodicTimer` recuerda un tick pendiente y lo demuestra el cambio final a `b`), pero esa línea da una seguridad que no tiene. Inferido |
| P140b-03 | Baja | La «llave que no se abre» se simula borrando la llave CNG con nombre: el error es «llave inexistente», no «acceso denegado». El tipo real de la excepción con la ACL negada (`CryptographicException` esperada) es inferido; si fuera otro, la falla cerrada sigue (cae en «no se pudo cargar» → 4747) y solo cambia el motivo |
| P140b-04 | Baja | `SslOptions.TargetHost` en `ClienteApiLocal.Crear` es código sin efecto, y aun así hay dos afirmaciones que lo fijan (`ClienteApiLocalTests.cs:166`, `EscuchaWebModoTests.cs:184`) y el comentario de la clase dice que «el SNI y la validación usan el nombre» sin aclarar por qué mecanismo. Ver (d) |
| P140b-05 | Baja | La prueba de nombre espera `NameMismatch` y `ChainErrors` a la vez con un validador de Windows (Schannel). En otra plataforma el validador puede reportar solo uno de los dos; no hay `Skip`. Hoy irrelevante; relevante cuando llegue Linux (PL-01..15). Inferido |
| P137b-04 | Baja | `Una_excepcion_al_comprobar_las_direcciones_efectivas...` supone que el anfitrión no vuelve a leer `IServer.Features` después de `StartAsync` (el doble lanza desde ese momento). Es una dependencia del marco, no de este código; si una versión nueva lo hiciera, la prueba fallaría por otra causa. Inferido; B informa 885 correctas |

Ningún hallazgo Alto ni Medio. Ninguno bloquea unir #137, #139 y #140.

## (a) P140-03: el único cambio de producción

Leí el archivo completo después del cambio (`SelectorCertificadoServidor.cs`, `RefrescarPeriodicamente` y `Refrescar`).

- **El bucle sobrevive a un registro que lanza al escribir 4748/4749.** Leído. Cada `Refrescar()` va en su `try/catch (Exception)` dentro del `while`; el catch llama a `RegistroFallido`, que a su vez está protegido (si el registro sigue roto, se traga). Después el `while` vuelve a `WaitForNextTickAsync`. La 1.ª prueba lo recorre: `NoUsable` lanza dentro del `try` de `Refrescar`, el `catch` interno vuelve a llamar a `NoUsable` y lanza otra vez, la excepción sale al bucle (Fallos ≥ 2), el bucle sigue y toma `b` en el periodo siguiente.
- **El 4749 ya no produce un 4748 falso.** Leído. La variable `venceTomado` se calcula dentro del `try` y el `LogInformation` queda **después** del `try/catch`; el `catch` ahora termina en `return`. Si el 4749 lanza, la excepción no pasa por el `catch` que escribe el 4748. La 2.ª prueba exige `Empty(DeEvento(4748))` y `HuellaVigente == b`.
- **No se traga la cancelación.** Leído. `WaitForNextTickAsync(_parar.Token)` está fuera del `try` interno, así que su `OperationCanceledException` sigue llegando al `catch (OperationCanceledException)` externo y termina el bucle. Con `Dispose` pasa igual: el token ya está cancelado y el siguiente `WaitForNextTickAsync` lanza. Una `OperationCanceledException` que saliera de `Refrescar()` (solo podría venir del registro) sí se traga y el bucle sigue, lo cual es lo deseado. La prueba existente que espera `reloj.Temporizadores == 0` tras `Dispose` (línea ~304) detectaría un bucle que no termina.
- **Sin doble registro ni pérdida de eventos en el camino normal.** Leído. El 4749 se escribe una sola vez, con los mismos argumentos (`vence` es el mismo `NotAfter.ToUniversalTime()` y el formato `yyyy-MM-dd` no cambia); la rama `_liberado` sale antes de asignar `venceTomado`, igual que antes salía antes del log. Sí hay un caso que se pierde, y es inevitable: con el registro roto para ese nivel, el 4749 no se escribe; en su lugar queda el `LogError` de `RegistroFallido` (solo el tipo, sin la huella). Comportamiento observable distinto del anterior solo en el fallo.
- **Una observación que ya existía y no se empeora** (inferido): cuando `NoUsable` falla dentro del `try`, el `catch` lo vuelve a llamar con el motivo «excepción imprevista al refrescar». Con un registro intermitente (falla una vez), el 4748 que sale lleva ese motivo engañoso. No es regresión.
- **Relectura de seguridad:** `RegistroFallido` escribe `e.GetType().Name` y `_servicio`; nunca el mensaje ni la ruta. La 2.ª prueba afirma `DoesNotContain("secreta")`. No veo fuga.
- **Pruebas que llaman a `Refrescar()` directo** (11 usos en `SelectorCertificadoServidorTests`): ninguna espera que lance; el cambio solo afecta el caso del registro roto. Sin regresión.
- **Tiempo:** las dos pruebas usan `RelojManualTls` y `Esperar` con tope de 30 s solo en el fallo; no hay `Task.Delay` negativos.

Veredicto: el arreglo es mínimo, correcto en lo que leí, y las dos pruebas fallan con el código anterior (declarado por B; coincide con mi lectura) y con las tres mutaciones de la tabla.

## (b) P137-04: el quinto caso

B dice que el agente solo vio fallar 4 de los 5 casos con la mutación (quitar `Detener()` de `ComprobarEfectivas`).

- **Leído:** los 5 casos (`0.0.0.0`, `[::]`, `10.9.0.5` sin modo; `https://[::]:5072` y `http://[::]:443` en servidor de sitio) pasan por la misma línea. Sin `Detener()`, `RunAsync` no termina y `WaitAsync(30 s)` lanza; los 5 deben fallar.
- **Inferido (no consta en los documentos):** cuatro casos × 30 s de timeout = 120 s, que es el tope por omisión de una llamada de shell. El quinto es, con alta probabilidad, el último `InlineData` (`http://[::]:443`), cortado por el tiempo y no por una diferencia de lógica.
- **¿Queda sin protección?** No por lectura: ese caso es el único que protege, a nivel de cableado, «HTTP en el puerto del sitio sigue siendo mala» (la comprobación del esquema en `Permitida`), pero esa regla ya la prueba `ArranqueRedTests` como unidad, y el cableado (`Detener`, `ExitCode`) es el mismo de los otros cuatro.
- **Para cerrar la duda:** ejecutar solo ese caso con la mutación (30 s, con filtro `--filter "FullyQualifiedName~Una_direccion_efectiva_fuera_de_lo_permitido&..."` o con un tope mayor). Lo pido a B como confirmación, no como bloqueo.
- Aclaración que debe quedar anotada: el doble no es Kestrel (ver P137b-03); la prueba real con sockets sigue solo en el laboratorio.

## (c) P140-01 y P140-02: partes cubiertas y deuda para el laboratorio

**P140-01 (almacén real)**
- Cubierto, cuando hay un certificado en `LocalMachine\My` que no está en `CurrentUser\My`: la búsqueda real por SHA-256, la distinción de mayúsculas, que no halla por SHA-1 ni por una huella ajena, y que usa `LocalMachine` (el certificado elegido no existe en el almacén del usuario, así que abrir `CurrentUser` devolvería null). Es un buen diseño de oráculo y es de solo lectura.
- No cubierto: depende del equipo. Sin certificado de equipo se omite (honesto: omitida, no aprobada), de modo que en la suite oficial de una PC de desarrollo puede no correr nunca. El atributo abre dos almacenes reales **al descubrir las pruebas**; si el acceso falla, el descubrimiento falla (riesgo bajo). `OpenExistingOnly` y la liberación de los no coincidentes no se ejercen.
- **Acepto como deuda**, con una condición: el laboratorio debe demostrar que la prueba **no se omitió** en `VM-SRV` (ahí el verbo `tls` deja certificados solo en `LocalMachine\My`). Mejor remedio si A acepta tocar producción: el constructor interno `(StoreName, StoreLocation)` y un almacén con nombre propio en `CurrentUser`, como propuse en P140-01; entonces corre en toda PC.
- **Caso de laboratorio propuesto (nuevo, para mi documento de casos):**
  - **TL-01 — Almacén real tras el verbo `tls`.** Con la VM base y el verbo `tls` ejecutado: (1) correr solo `AlmacenCertificadosServidorWindowsTests` y exigir **1 aprobada, 0 omitidas**; (2) con el certificado de la API en `LocalMachine\My`, arrancar la API: sin 4747; (3) cambiar la huella publicada a otra inexistente y a una en minúsculas (o a SHA-1): arranque con 4747 o 4743 según lo que `InterpretacionRed` rechace antes, anotando cuál; (4) comprobar que el certificado no queda abierto (un reinicio del servicio y ningún error de «llave en uso»). Una VM, sin SQL, ~0,2 días-persona. Se ejecuta antes de TL-02.

**P140-02 (llave que no se abre y RSA)**
- Cubierto: la rama RSA del selector y un saludo real TLS 1.2 y 1.3 con RSA-2048 (Kestrel real en loopback, el mismo patrón de puertos que las pruebas ECDSA existentes); la rama de la llave que no se abre, con su motivo propio, distinta de «sin llave» y de «no se pudo cargar», en `MotivoNoUtilizable` y en `CargarAlArrancar`. La simulación es razonable: llave CNG con nombre en el almacén del usuario, referenciada por el certificado y borrada antes de devolverlo, sin dejar nada.
- No cubierto: la **ACL real** de la cuenta virtual del servicio sobre la llave privada de **equipo** (donde de verdad se aplica la regla de PT-02), el tipo exacto de la excepción con acceso denegado (P140b-03), y qué algoritmo emite el verbo `tls` (ECDSA o RSA) frente a Schannel.
- **Acepto como deuda** para el laboratorio. La rama es la misma; lo que falta es una propiedad del sistema operativo, no del código.
- **Caso de laboratorio propuesto (nuevo):**
  - **TL-02 — Llave sin lectura para la cuenta del servicio.** En `VM-SRV` con el servicio instalado y `tls` ejecutado: quitar a la cuenta virtual del servicio (`NT SERVICE\<servicio>`) la lectura de la llave privada del certificado (ACL del archivo de la llave en el almacén de equipo; la VM, nunca la PC del propietario); arrancar: debe salir **4747** con el motivo «la cuenta del servicio no puede abrir la llave privada»; si sale «no se pudo cargar (<tipo>)», registrar el tipo (resuelve P140b-03). Restaurar la ACL, reiniciar y comprobar que arranca. Repetir con ECDSA y con RSA (lo que emita `tls`). Variante en caliente: con el servicio corriendo y el mismo certificado, quitar la lectura y esperar ≤5 minutos: debe aparecer el 4748 por refresco (S2-01), y anotar si el saludo sigue sirviendo (no sé si Schannel conserva el contexto ya abierto; es justo lo que se averigua).
  - **TL-03 (opcional) — Renovación real.** `tls` publica una huella nueva: en ≤5 minutos aparece el 4749 sin reiniciar, y la Web toma el certificado nuevo en ≤10 minutos (`VidaConexiones`). Solo si el laboratorio ya tiene el servicio completo.
- Orden sugerido: TL-01, TL-02, TL-03 antes de CH-/PK-, ya que reutilizan la misma VM base y no necesitan SQL.

## (d) `TargetHost` en `ClienteApiLocal.Crear`

**¿Mi P140-04 («otro nombre») lo detecta?** Ni lo detecta ni debía. Y debo **retractar** una frase de mi P140-04: escribí que cambiar `TargetHost` por `"localhost"` o quitarlo haría fallar el camino feliz. Era una inferencia mía sobre el marco y B la comprobó con .NET 10 como falsa (declarado por B; coherente con lo que sé del `SocketsHttpHandler`, que toma el nombre del anfitrión de la petición).

**¿La prueba de nombre del PR realmente distingue el nombre del servidor?** Sí, y por la vía correcta (leído):
1. La prueba usa `CrearManejador(red)` de producción, sin la sobrecarga de pruebas, y solo observa los `SslPolicyErrors` del sistema con un callback que rechaza todo. Para `otro.prueba` aparece `RemoteCertificateNameMismatch`; para el nombre del sitio no. Eso prueba que el sistema juzga el nombre.
2. El servidor de prueba captura el SNI (`ClientHelloInfo.ServerName`) y se afirma `== Nombre`. El SNI es la salida observable de verdad, desde el lado que la recibe.
3. El nombre que viaja es el anfitrión de la petición (`BaseAddress = DireccionApi(...)`), y el `ConnectCallback` solo deja pasar ese anfitrión y puerto (la `Theory` de «destino no permitido» ya existe). Por tanto la garantía real es `DireccionApi` + `ConnectCallback`, ambos cubiertos.

**Qué prueba detectaría un cambio en `TargetHost`:** ninguna razonable, porque no tiene efecto; no hay comportamiento que observar. Las dos afirmaciones que lo fijan hoy (`ClienteApiLocalTests.cs:166` y `EscuchaWebModoTests.cs:184`) comprueban un valor sin uso: dan sensación de cobertura. Recomendación a A (decisión suya): quitar `TargetHost` y esas dos afirmaciones, o dejarlo con un comentario de que es redundante. Un solo hueco inferido que no probé: si una petición llevara un encabezado `Host` distinto, el marco puede usarlo para el SNI; el `ConnectCallback` mira el destino de la URL, no el encabezado. Sigue exigiendo un certificado válido para ese nombre, así que no abre un acceso, pero una prueba de caracterización con `request.Headers.Host` lo dejaría documentado. No lo pido.

## (e) Regresiones: tiempo, puertos, almacén real, estado estático y orden

- **Variables de entorno del proceso.** La prueba de P137-01 cambia `DOTNET_STARTUP_HOOKS`, `GPOS_MODO_RED` y `ASPNETCORE_HOSTINGSTARTUPASSEMBLIES` y las restaura en `finally`. Está en la colección `EscuchaRedSecuencial` (`DisableParallelization`), que corre sola; no choca con otras pruebas que arranquen procesos o lean el entorno. Riesgo residual: P137b-01.
- **`Environment.ExitCode`.** Las pruebas nuevas lo ponen en 0 y lo restauran en `finally` (`Corriendo`, `CorrerHastaDetenerse`). Están en la misma colección secuencial. Sin hallazgo.
- **Tiempo real.** Las pruebas de P137 no abren sockets; el reloj no interviene; las esperas son `Esperar` con tope de 30 s solo cuando fallan. Las de P140-03 usan `RelojManualTls` y el mismo `Esperar`. No hay esperas negativas con `Task.Delay` nuevas. Sin hallazgo.
- **Puertos.** Solo las pruebas que ya usaban Kestrel real (RSA, P140-04) piden `PuertoLibre` (el patrón existente, con su ventana de carrera conocida). Las de P137-02/03/04 no abren ninguno. Sin hallazgo nuevo.
- **Almacén real.** Solo P140-01 toca `LocalMachine\My` y `CurrentUser\My`, en solo lectura, desde el atributo `Skip` (en el descubrimiento) y desde la prueba. Resultado dependiente de la PC: ver (c). `ConLlaveQueNoSeAbre` crea una llave CNG con nombre `GPOS_TEST_<guid>` en el almacén **del usuario** y la borra en `finally`; si el proceso muriera entre medio quedaría una llave huérfana inofensiva (no toca el equipo).
- **Estado estático.** No agregan estado estático ni tocan `FuenteDePruebas`; la prueba de P137-01 pasa la fuente explícita, así que no depende del inicializador del módulo. Los apoyos nuevos (`ServidorDoble`, `ConfiguracionControlada`) son privados de la clase y por instancia.
- **Orden.** No encontré dependencia de orden. La 2.ª prueba de P140-03 usa tres certificados distintos y no reutiliza la huella entre fases.
- **Refactor de `SoporteTls`.** `Pedido` ahora llama a `Extensiones`; mismas extensiones (EKU y SAN) que antes. Sin cambio para los ~100 usuarios de `CertificadoPrueba`.
- **Asunto de plataforma.** Las pruebas nuevas dependientes de Windows llevan `FactWindows` (omitidas, no aprobadas, fuera de Windows), salvo la de nombre (P140b-05) y la de RSA con Kestrel real, que sí la necesitan solo por Schannel y no tienen `Skip`. Hoy no importa.

## Lo que está bien

- Un commit por observación, con la mutación declarada; los mensajes dicen lo que no se cubrió (ACL real, `TargetHost`) en vez de maquillarlo.
- P137-02/03/04 resuelven mi sugerencia sin sockets (servidor doble) y ejercen el cableado real (`ApplicationStarted`, `ExitCode`, `StopApplication`); la recarga se dispara en el mismo hilo, por lo que no hay carrera en las afirmaciones de «no detiene».
- P137-05 abre solo la base de HKLM, sin leer ni escribir subclaves, y fija además el literal de la clave.
- P140-01: elegir un certificado que solo esté en el equipo es lo que vuelve falsable la mutación `CurrentUser`.
- P140-03: la 2.ª prueba usa un registro que solo falla en `Information`, lo que separa el 4749 del 4748; es la prueba correcta para esa regla.
- P140-04: usa el oráculo del lado del servidor (SNI) y no depende de reimplementar la política.

## Qué no verifiqué

- Nada se compiló ni se ejecutó: no sé si las pruebas nuevas pasan, ni cuánto tardan. Las cifras «885 correctas, 0 con error, 3 omitidas» y todas las mutaciones «verificadas» son declaraciones de B que **no repetí**; mi evidencia son solo mutaciones mentales.
- No sé cuáles son las 3 omitidas ni si `FactConCertificadoDelEquipo` corrió o se omitió en la PC de B. Pido a B que lo diga.
- No leí `ArranqueRedTests` ni `EscuchaTlsKestrelTests` completos (solo las líneas del diff y las que cité); asumo que la unidad de `Permitida` con esquema HTTP está cubierta allí, como en mi revisión anterior de #137.
- No verifiqué en el código de .NET 10 que `TargetHost` carezca de efecto, ni cómo `SocketsHttpHandler` elige el SNI con un `Host` explícito; me baso en lo que B comprobó.
- No verifiqué que `GetECDsaPrivateKey` lance `CryptographicException` ante una ACL negada, ni que el certificado de `ConLlaveQueNoSeAbre` quede con la llave irrecuperable tras `cng.Delete()` (lo prueba la mutación de B, que no repetí).
- No leí `InterpretacionRed`, así que no sé si una huella en minúsculas llega al selector o muere antes con 4743 (TL-01 lo averigua).
- No revisé la documentación (ADR-90, blueprint) contra el código; me guié por los comentarios y el aviso.

## Recomendación a B

Las siete observaciones cubiertas lo están con pruebas que fallan con la mutación que corresponde; P140-03 es un cambio de producción correcto y mínimo. P140-01 y P140-02 las acepto como deuda del laboratorio de LFMB con TL-01 y TL-02 (arriba). Antes de unir, en orden de valor/costo: (1) confirmar el quinto caso de P137-04 corriéndolo solo con la mutación (30 s); (2) que A decida el EventId de `RegistroFallido` y si retira `TargetHost` (P140b-01, P140b-04); (3) que B diga si P140-01 corrió o se omitió en su PC. Ninguno bloquea.
