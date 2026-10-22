# Cuarta relectura de seguridad · PR-2 de ADR-90 (P140-03 y deuda de pruebas P137/P140)

- **Fecha:** 2026-10-22 · **Auditor:** auditor-seguridad (equipo A) · **Es una recomendación técnica. La decisión de unir la toma el propietario, por medio de B.**
- **Objeto:** rama local `a/adr90-rt05-tls-escucha` (`GPOS-NG-pr2`). Contiene los 9 commits de B (`b/deuda-pr2-p137-p140`) aplicados sobre `89f03411`, de `c74df59a` a `130db6ad`.
- **Origen:** `avisos/B-a-A/2026-10-22-deuda-p137-p140-rama-lista.md`. Continúa `relectura2` y `relectura3`.
- **Método:** solo lectura (`git log`, `git diff`, `git show`, `grep`). No compilé, no ejecuté nada y no cambié de rama. [V] = verificado en el código. [I] = inferido, no ejecutado.
- **Superficie:** el único cambio de producción está en `src/GPOS.Comun.Servidor/Red/SelectorCertificadoServidor.cs` (+38/−5). El resto son 7 archivos de `tests/GPOS.Tests/Red/` (+604/−4). No cambia ninguna regla de `tests/GPOS.Tests/Arquitectura/`. [V]

## 1. Tabla resumen

| ID | Severidad | Estado | Título |
|---|---|---|---|
| P140-03 | — | **Correcto** | El bucle del refresco sobrevive a un registro que lanza, y el 4749 fallido ya no produce un 4748 falso |
| R4-01 | Baja | Nueva (anterior a este cambio) | Si falla solo uno de los proveedores del registro, puede salir un segundo 4748 en el mismo refresco, con un motivo engañoso |
| R4-02 | Baja (informativa) | Nueva | `venceTomado` se calcula después del cambio de certificado. Si lanzara, saldría un 4748 falso (la probabilidad es casi nula) |
| R4-03 | Baja (informativa) | Nueva | `TargetHost` no tiene efecto. El nombre del saludo sale del anfitrión de la petición o de la cabecera `Host` |

No hay hallazgos Críticos, Altos ni Medios.

## 2. Verificación de los cinco puntos pedidos

### (1) Continuidad y falla cerrada: se sigue sirviendo el certificado vigente · Correcto
- **[V]** El cambio de certificado (`_vigente`) ocurre solo dentro del `lock`, en `SelectorCertificadoServidor.cs:193-203`, y únicamente después de que `Cargar` devolvió un certificado utilizable (`:187-192`). El registro no se toca antes de ese punto.
- **[V]** Todas las llamadas al registro ocurren cuando lo servido ya está decidido:
  - `NoUsable` en `:169`, `:175`, `:183` y `:190` deja `_vigente` sin tocar;
  - el 4749 se escribe en `:212-215`, después del cambio.

  Por eso una excepción del registro no puede deshacer ni impedir un cambio, ni provocar uno.
- **[V]** `OpcionesVigentes` (`:65-66`) lee `_vigente` con `Volatile.Read`. El saludo nunca pasa por el registro.
- **[V]** Si el registro lanza al escribir el 4748, el certificado anterior se sigue sirviendo. La prueba `SelectorCertificadoServidorTests.cs:378` lo cubre de forma indirecta: el vigente sigue siendo `a` hasta que entra `b`.

### (2) El bucle no muere ni queda en bucle apretado · Correcto
- **[V]** El `try/catch (Exception)` de `:122-132` envuelve cada `Refrescar()`. `RegistroFallido` (`:141-152`) no puede lanzar, porque tiene su propio `catch (Exception)`. Así, ninguna excepción del registro sale del `while`.
- **[V]** El bucle termina solo de dos maneras: con `OperationCanceledException`, cuando `Dispose` cancela `_parar` (`:135`, `:293`), o con el temporizador liberado al salir.
- **[V]** No hay reintento dentro del periodo. El ritmo lo marca `PeriodicTimer(Refresco = 5 min)` (`:31`, `:117`), así que con el registro roto hay como mucho 3 intentos de escritura por refresco (4748, 4748 del `catch` y `LogError`). No hay bucle apretado.
- **[I]** Si un tick vence mientras `Refrescar` corre, `PeriodicTimer` lo acumula como un solo tick. No hay ráfagas.
- **[V]** Antes de este cambio, la excepción del `NoUsable` del `catch` (`:208`) salía de `RefrescarPeriodicamente`. La tarea quedaba en falla, sin evento, y el certificado ya no se renovaba hasta reiniciar. El arreglo cierra ese hueco.

### (3) El `LogError` no filtra mensaje, rutas ni secretos · Correcto
- **[V]** `:145-146` registra solo `_servicio` (un enum) y `e.GetType().Name`, el nombre corto del tipo, sin espacio de nombres. No registra `e.Message`, `e.ToString()`, `InnerException`, la huella ni el objeto de la excepción como argumento `exception`, de modo que tampoco sale la traza de pila.
- **[V]** La prueba `:408` lanza `InvalidOperationException(@"C:\ruta\secreta")` y comprueba que el mensaje registrado contiene el nombre del tipo y no contiene `secreta`.

### (4) ¿Hace falta un EventId propio? · Basta sin él. No usar el 4752
Razones:
- **[I]** `Microsoft.Extensions.Logging.Logger` escribe en todos los proveedores y, al final, lanza un `AggregateException` con los fallos.
  - Si falla un solo proveedor (p. ej. la consola), el 4748 o el 4749 ya llegó al Visor de eventos con su ID. El `LogError` solo añade un diagnóstico.
  - Si falla el propio `EventLog` (`ModoServicioApi.cs:88` [V]), el `LogError` también fallará allí y el ID es irrelevante.

  En ninguno de los dos casos un ID nuevo mejora la vigilancia.
- **[V]** La franja de ADR-90 va de 4743 a 4752 y el 4752 está reservado (`EventosRed.cs:6-7`). Gastarlo en un diagnóstico de segundo orden quitaría margen a RT-06 o a lo que ADR-90 tenga previsto.
- **Si el propietario quiere poder alertar sobre este caso**, la opción más barata es reutilizar el **4748**, porque es el mismo crítico de «el refresco no pudo hacer su trabajo», con el motivo «el registro falló (Tipo)». No hace falta un ID nuevo. Coste: unos minutos. No lo exijo.

### (5) Semántica del 4748 y del 4749 · Correcta en el caso pedido, con la salvedad R4-01
- **[V]** El 4749 se escribe fuera del `try` (`:211-215`). Si lanza, la excepción va al bucle y de ahí al `LogError`. Ya no pasa por el `catch` de `:206`, así que **no aparece un 4748 falso**. La prueba `:408` lo comprueba: no hay 4748, el vigente es `b` y hay un solo `Error`.
- **[V]** El 4749 sale una vez por cambio y solo cuando hubo cambio (`venceTomado` es `null` en todos los demás caminos, `:164`, `:204`).
- **[V]** El 4748 sale uno por refresco cuando el registro funciona. Si el registro lanza en el primer 4748, el `catch` de `:206-209` intenta un segundo 4748. Ver R4-01 para el caso parcial.

## 3. Hallazgos

### R4-01 · Baja · El 4748 puede salir dos veces en un refresco si el registro falla en parte
- **Riesgo:** basta con que falle un solo proveedor, con el Visor de eventos funcionando, para que el primer 4748 llegue al Visor y luego lance (`AggregateException` [I]). El `catch` de `:206-208` escribe entonces **otro 4748**, con el motivo «excepción imprevista al refrescar (AggregateException)». Ese motivo atribuye al certificado un fallo que es del registro.
  - Rompe el «como mucho uno por refresco» de la documentación (`:21`).
  - Puede despistar a quien diagnostica. No afecta a lo que se sirve.
  - El comportamiento ya existía antes de P140-03, que no lo empeora.
- **Evidencia:** `SelectorCertificadoServidor.cs:169`, `:175`, `:183`, `:190` (`NoUsable` dentro del `try`) y `:206-208`. [V]
- **Remediación:** calcular el motivo dentro del `try` y escribir el único 4748 fuera de él, igual que ya se hace con el 4749. También sirve marcar con una bandera que el fallo vino del registro y, en ese caso, no repetir el 4748. Esfuerzo: menos de 1 hora, más una prueba con `RegistroRoto` que cuente los 4748 capturados.

### R4-02 · Baja (informativa) · Cálculo posterior al cambio dentro del `try`
- **Riesgo:** `venceTomado = nuevo.Certificado.NotAfter.ToUniversalTime()` (`:204`) se ejecuta después de `Volatile.Write(ref _vigente, nuevo)` (`:202`), todavía dentro del `try`. Si lanzara, el `catch` escribiría un 4748 («no es utilizable») con el certificado nuevo ya servido.
  - **[I]** La probabilidad es casi nula: `nuevo` está vivo y no se libera en ese camino.
- **Remediación:** calcular `vence` antes del `lock` (`nuevo` es local). Cuesta una línea.

### R4-03 · Baja (informativa) · `TargetHost` en `ClienteApiLocal.Crear`
- **[V]** `ClienteApiLocal.cs:130` fija `TargetHost = anfitrion`. B observó que no tiene efecto: la prueba `ClienteApiLocalTests.cs:119` se comporta igual si se cambia o se quita.
- **[I]** Según el código de `SocketsHttpHandler`, el nombre del saludo (SNI y validación del nombre) sale de la cabecera `Host` de la petición, si la hay, y si no, de `Uri.IdnHost`. Ese valor sobrescribe `SslOptions.TargetHost`.
- **Riesgo:** si algún día la Web copiara al cliente de la API la cabecera `Host` que recibe del navegador, el nombre validado podría ser otro. Seguiría fallando de forma cerrada, salvo que ese nombre estuviera en el SAN del certificado de la API. Hoy no hay ningún uso de `Headers.Host` en `src/GPOS.Web` [V], así que no es explotable.
- **Remediación:** ver la sección 5.

## 4. Pruebas nuevas: ¿prueban lo que dicen? ¿debilitan alguna regla?

| Prueba | ¿Prueba lo que dice? | ¿Debilita algo? |
|---|---|---|
| P140-03 (4748), `SelectorCertificadoServidorTests.cs:378` | **Sí** [V]. Sin el arreglo, la tarea del refresco moría y el `Esperar` de `HuellaVigente == b` agotaba los 30 s (`:440-447`). El tick pendiente no se pierde aunque el `Avanzar` llegue antes de que el bucle vuelva a esperar [I]. | No |
| P140-03 (4749), `:408` | **Sí** [V]. Sin el arreglo aparecía el 4748 falso (Critical no está roto en esa prueba), y `Assert.Empty(...4748)` lo detecta. También comprueba que no se filtra el mensaje y que el bucle sigue vivo. | No |
| P140-04, `ClienteApiLocalTests.cs:119` | **Sí, con matiz.** Usa el manejador de producción y comprueba que no trae una devolución propia (`Assert.Null(...RemoteCertificateValidationCallback)`). Solo después la prueba le pone una devolución que **siempre rechaza**, para ver `SslPolicyErrors`. Comprueba `NameMismatch` según el nombre y el SNI recibido en Kestrel. No prueba el camino que acepta, que ya cubre la sobrecarga con `raizPruebas`. | **No.** Es **solo prueba** (`130db6ad` toca únicamente `ClienteApiLocalTests.cs` [V]). La devolución vive en `tests/`. La regla de `RedPlataformaArquitecturaTests` sobre devoluciones de validación recorre `src/` y sigue igual [V]. El título dice «el manejador de producción valida»: es descriptivo, no un cambio de producción. |
| P140-01, `AlmacenCertificadosServidorWindowsTests.cs:57` | **Sí, si corre** [V]. Exige un certificado que esté en `LocalMachine\My` y no en `CurrentUser\My`, y distingue SHA-256 en mayúsculas de SHA-256 en minúsculas, de SHA-1 y de una huella al azar. Si no hay certificado, figura como **omitida**, no como aprobada (`:17`). | **Riesgo bajo.** Abre `LocalMachine\My` y `CurrentUser\My` en `ReadOnly` (`:39-48`). Lee solo `RawData` y las huellas, que son datos públicos. **No abre ninguna llave privada** (`BuscarPorSha256` no la toca, `AlmacenCertificadosServidor.Windows.cs:16-30`) y libera los certificados. Si falla, el mensaje puede mostrar bytes del certificado, que es público. La enumeración en el atributo ocurre al descubrir las pruebas, sin efectos. |
| P140-02, RSA y llave que no se abre (`SoporteTls.cs:69-83`) | Sí [V]. La llave se crea en el KSP de software **del usuario**, nunca en el del equipo, y se borra en `finally`. | No. Si el proceso se cayera entre la creación y el `Delete`, quedaría un archivo de llave huérfano en el perfil del usuario, sin valor. |
| P137-01, `EscuchaServidorKestrelTests.cs:337` | Sí [V]. Pone `DOTNET_STARTUP_HOOKS` o `GPOS_MODO_RED` en el entorno del proceso y los restaura en `finally`. | No. La colección es `DisableParallelization = true` (`:24`, `:51`), así que ninguna otra prueba corre a la vez. `DOTNET_STARTUP_HOOKS` solo se lee al arrancar un proceso y el valor apunta a un archivo inexistente. |
| P137-05, `FuenteConfiguracionRedWindowsTests.cs` | Sí [V]. Comprueba por reflexión `HKLM`, `Registry64` y la subclave. Solo abre la base de `HKLM` y no lee ni escribe ninguna subclave. | No |
| P137-02/03/04 | Revisadas solo por encima. Con dobles (`ServidorDoble`), no abren sockets. Los mensajes de prueba con `C:\ruta\secreta` sirven para comprobar que no se filtran. | No se ve ningún debilitamiento |

## 5. Decisiones pedidas por B

### Constructor interno `(StoreName, StoreLocation)` en `AlmacenCertificadosServidorWindows` · Recomiendo **No**
- **Riesgo que introduce:** hoy la clase solo puede leer `LocalMachine\My`, porque está escrito en el método (`AlmacenCertificadosServidor.Windows.cs:19`). La regla `RedPlataformaArquitecturaTests.cs:93-108` exige que solo la fábrica la cree, pero **no fija los argumentos**.
  - Con un constructor parametrizado, un cambio en la fábrica a `CurrentUser` pasaría esa regla.
  - En `CurrentUser\My` puede escribir cualquier proceso de la cuenta del servicio, lo que reabre la clase de riesgo que cerró S-04/P137-05 para el registro.
  - La prueba también tendría que **escribir** en `CurrentUser\My` del usuario que ejecuta la suite, con efecto lateral y limpieza obligatoria.
- **Alternativa más barata (recomendada):** un campo `internal static readonly StoreLocation Ubicacion = StoreLocation.LocalMachine` (y `Nombre = StoreName.My`) usado por `BuscarPorSha256`, más una aserción en la prueba, como hizo P137-05 con `_raiz` y `_subclave`.
  - Cierra la mutación `LocalMachine → CurrentUser` en cualquier equipo, sin escribir en ningún almacén y sin abrir un camino de inyección.
  - La prueba de solo lectura actual se mantiene para los equipos que tengan certificado (C y el laboratorio).
  - Esfuerzo: menos de 1 hora.
- Alternativa descartada: el constructor con la regla de arquitectura reforzada para exigir `new AlmacenCertificadosServidorWindows()` sin argumentos en la fábrica. Funciona, pero añade una superficie y una regla para conseguir lo mismo que la constante.

### `TargetHost` en `ClienteApiLocal.Crear` · Recomiendo **mantenerlo y corregir el comentario**
- **Por qué mantenerlo:**
  - No cuesta nada.
  - Si en el futuro el manejador se usa fuera de `SocketsHttpHandler`, o una versión de .NET lo respeta, sigue diciendo el nombre correcto (defensa en profundidad).
  - Retirarlo obligaría a tocar las aserciones de `ClienteApiLocalTests.cs:166` y `EscuchaWebModoTests.cs:184`.
- **Lo que sí conviene:** un comentario en `ClienteApiLocal.cs:130` que diga que `SocketsHttpHandler` lo sobrescribe con el anfitrión de la petición, y que la garantía real la dan `DireccionApi` y el `ConnectCallback`.
  - Opcional: una regla de arquitectura o una revisión que impida fijar `Headers.Host` en las peticiones del cliente de la API (R4-03).
  - Cambiar el nombre de la prueba de propiedad para que no sugiera que comprueba el SNI efectivo; eso ya lo hace P140-04.
- Alternativa descartada: retirarlo. Es igual de seguro hoy, pero quita la intención del código y no gana nada.

## 6. Controles bien implementados
- El cambio de certificado es atómico, bajo `lock`, y el saludo nunca lee el registro ni el almacén (`:15-16`, `:65-66`, `:193-203`).
- `RegistroFallido` es tolerante a un registro roto y no repite intentos.
- Los mensajes solo llevan el nombre del tipo de la excepción. Las pruebas usan rutas «secretas» para comprobar que no se filtran.
- Cada observación tiene su commit, con la mutación que hace fallar la prueba documentada en el aviso de B.
- La prueba del almacén real (P140-01) es de solo lectura y se marca como omitida, no como aprobada, cuando no puede correr.

## 7. Remediaciones priorizadas
1. **Opcional antes de unir:** R4-02 (una línea) y el comentario de `TargetHost`. No bloquean.
2. **Puede ir en la deuda:** R4-01 (un solo 4748 escrito fuera del `try`) y la constante de ubicación para P140-01.
3. **Laboratorio:** P140-02, la ACL real de la cuenta del servicio sobre la llave, como dice B.

## 8. Recomendación
**Aprobado con observaciones.** El cambio de producción P140-03 es correcto en continuidad, falla cerrada, vida del bucle y no filtración. Las pruebas nuevas prueban lo que dicen y no debilitan ninguna regla. No hay hallazgos Críticos ni Altos. No hace falta un EventId propio, y el 4752 sigue reservado. La incorporación al #140 y la unión las decide el propietario, por medio de B.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `GPOS-NG-Equipos/traspasos/A/relectura4-seguridad-p140-03-2026-10-22.md`
- Supuestos: la agregación de excepciones de `Microsoft.Extensions.Logging` y que `SocketsHttpHandler` sobrescribe `TargetHost` se infieren del código de .NET, no se ejecutaron [I]; la suite no se corrió en esta relectura (B informa 885/0/3 en las pruebas dirigidas).
- Decisiones candidatas a ADR: ninguna (la constante de ubicación y el comentario de `TargetHost` son de implementación).
- Entregas a otros agentes: desarrollador de A → R4-02 (calcular `vence` antes del `lock`), comentario de `TargetHost` y, si se acepta, la constante `Ubicacion`/`Nombre` con su prueba; R4-01 a la deuda. qa-automatizado / C → suite oficial sobre la rama con los 9 commits.
- Próximo paso recomendado: B confirma con el propietario y A incorpora los 9 commits al #140. R4-02 y el comentario pueden ir en el mismo PR.
