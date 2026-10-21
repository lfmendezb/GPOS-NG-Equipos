# Revisión de seguridad · PR-4 de ADR-90 (cableado de RT-01 y RT-06 en `GPOS.Api`)

- **Fecha:** 2026-10-21 · **Revisor:** auditor de seguridad (A)
- **Rama:** `a/adr90-pr4-cableado-api` @ `a32eb8b6` (repositorio `GPOS-NG-pr4`), comparada con `origin/a/n1-endurecimiento-servicio` (`2cd41377`)
- **Commits revisados en detalle:** `900369a3` (cableado, retiro de `FijarEscuchaPorOmision`, regla sin modo, S-06) y `a32eb8b6` (S1b-03 y S1b-04 en la API)
- **Contratos:** plano v2 (`traspasos/A/blueprint-adr90-rt01-rt05-rt06-2026-10-20.md`), aviso de B (`avisos/B-a-A/2026-10-21-revision-122-130-y-retiro-de-escucha-por-omision.md`), informes previos `revision-seguridad-pr127-n1-2026-10-21.md`, `revision-seguridad-n1-endurecimiento-2026-10-21.md` y `revision-seguridad-pr1b-adr90-2026-10-21.md`
- **Método:** solo lectura (`git show`, `git diff`, lectura de archivos). **No se compiló ni se ejecutó nada.** [V] = verificado en el código; [I] = inferido del comportamiento del marco o de Windows, por confirmar en el laboratorio.

---

## 1. Alcance y superficie revisada

| Pieza | Evidencia |
|---|---|
| `Preparar` después de `ConfigureKestrel(servidor.Aplicar)` y de `AgregarArchivoInstalacion`, antes de `Build` | `src/GPOS.Api/Program.cs:35`, `:54`, `:56`, `:348` [V] |
| `ExigirArranque` justo después de `Build`, en `try/catch (ArranqueRedException)` con `ExitCode = 1`, `DisposeAsync` y `return` | `Program.cs:350-351` [V] |
| `UseFiltroOrigenNodo(red.IpNodos)` como primer `app.Use…`, antes de `UseForwardedHeaders` | `Program.cs:363-364` [V] |
| Retiro de `FijarEscuchaPorOmision` y de `EscuchaPorOmision` | diff de `900369a3` en `Program.cs` y `src/GPOS.Api/Servicio/ModoServicioApi.cs` [V] |
| Regla sin modo: `ListenLocalhost(5071)` en código, solo la API, solo sin modo (y por tanto sin Estricto) y sin direcciones declaradas | `src/GPOS.Comun.Servidor/Red/EscuchaServidor.cs:38`, `:71`, `:99-104`, `:112-119` [V] |
| Costura `FuenteDePruebas` y fuente «sin modo» de `GPOS.Tests` | `EscuchaServidor.cs:63`, `:83`; `tests/GPOS.Tests/ConfiguracionPruebas.cs:25`, `:29-43` [V] |
| Pruebas de texto de `Program.cs` (R1, R2, S1 a S7) y de la lista de N-1 | `tests/GPOS.Tests/Arquitectura/OrdenProgramaApiTests.cs:44-47`, `:95-96`, `:135-189`; `ApiModoServicioArquitecturaTests.cs` (diff) [V] |
| Pruebas de humo y de Kestrel real sin modo | `tests/GPOS.Tests/Red/ApiSinModoHumoTests.cs`, `EscuchaSinModoApiTests.cs:43-150` [V] |

**Superficie expuesta afectada:** el punto de escucha de la API (sin modo: *loopback* 5071; con modo: lo armará PR-2), el filtro de origen de los nodos (`/api/sync/*`) y el arranque del proceso, que va antes del anillo y de los datos.

**Base y dependencia de PR-2.** [V] En los remotos no existe ninguna rama de PR-2 (RT-05, puntos de escucha por modo). `origin/a/adr90-rt05-escucha-servidor` es PR-1b. PR-4 contiene PR-1a, PR-3 y PR-1b (con `d8145335`), pero no PR-2. El mensaje de `900369a3` dice «PR-4 no se une antes de PR-2». En cambio, la tabla del plano v2, sección 8, solo pide PR-1a a PR-3, N-1 y F-5. Ver S4-01.

---

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título | Bloquea unir |
|---|---|---|---|
| S4-01 | **Media** | Nada técnico impide unir antes de PR-2. Con el modo presente, la API ejecuta el anillo, `Inicializacion` (escrituras en SQL), la licencia y los trabajos en segundo plano, y solo después se detiene con el 4746 | **Sí, hasta PR-2** (o con el remedio a) |
| S4-02 | Baja | El código 1 llega como código del proceso, pero no consta que llegue al Administrador de servicios como fallo, ni antes ni después de `Run` | No |
| S4-03 | Baja | Si `ExigirArranque` lanza una excepción distinta de `ArranqueRedException`, el proceso no se salta la falla cerrada, pero termina sin evento de ADR-90 y sin el código 1 | No |
| S4-04 | Baja | Las pruebas de texto de `Program.cs` no ven un `catch` más amplio, una llamada condicional ni la escucha armada desde otro archivo | No |
| S4-05 | Baja (heredado de S1b-05) | Sin modo, una fuente declarada desactiva el `ListenLocalhost`, y entonces la única barrera es el 4746, que actúa después del enlace | No |
| S4-06 | Baja (informativa) | `FuenteDePruebas` es un estático mutable visible por nombre de ensamblado y no está atado al entorno de pruebas | No |

No hay hallazgos Críticos ni Altos.

---

## 3. Checklist OWASP Top 10 (2021)

| Categoría | Resultado | Hallazgos |
|---|---|---|
| A01 Control de acceso | **Bien.** El filtro de nodos es el primer middleware y mira la IP de la conexión antes de `UseForwardedHeaders` (`Program.cs:363-364`). Con nodos, rechaza el reenvío del marco y el IIS fuera de proceso (`FiltroOrigenNodo.cs:44`). Con el modo presente, el 4744 ya lo negó antes (`ArranqueRed.cs:128-129`, `:161`) | — |
| A02 Criptografía | No aplica en PR-4. El TLS por modo es de PR-2. Sin modo, el HTTP en *loopback* sigue (S-02 del #127, Media, abierto hasta PR-2) | — |
| A03 Inyección | No aplica | — |
| A04 Diseño inseguro | **Observación.** La falla cerrada se cumple en todas las ramas revisadas, pero con el modo presente y sin PR-2 se detiene tarde | S4-01, S4-05 |
| A05 Configuración | **Bien.** Se retiró `UseUrls`. La escucha sin modo se arma en código y no deja `urls` en la configuración (`EscuchaSinModoApiTests.cs:121-127`). S7 se repite en la API | S4-04 |
| A06 Componentes vulnerables | No aplica (no hay paquetes nuevos; `GPOS.Comun.Servidor` no tiene `PackageReference`) | — |
| A07 Autenticación | No aplica (no cambia) | — |
| A08 Integridad | **Bien**, con la costura de pruebas acotada | S4-06 |
| A09 Registro y monitoreo | **Observación.** Hay eventos 4743, 4744, 4745 y 4746 en las salidas previstas. Las salidas imprevistas no tienen evento y no consta qué ve el SCM | S4-02, S4-03 |
| A10 SSRF | No aplica | — |

---

## 4. Hallazgos

### S4-01 · Media · Unir antes de PR-2: el arranque con modo se detiene después de los datos y nada lo impide

- **Riesgo.** [V] Con `ModoRed` en el registro:
  - `Preparar` solo vacía el cargador de `Kestrel:*` y no arma ningún punto de escucha (`EscuchaServidor.cs:92-98`).
  - `ExigirArranque` aprueba, porque la decisión es `ConModo` (`ArranqueRed.cs:206-219`).
  - `Program.cs` sigue con el anillo, `Inicializacion.EjecutarAsync`, la licencia, los sellos, la identidad SQL y las comprobaciones de esquema (`Program.cs:445-469`). `Inicializacion` escribe en `GPOS_SYSDATA` aun en Estricto: siembra los reportes y migra los permisos (`src/GPOS.Api/Servicios/Inicializacion.cs:115-130`).
  - Después, `app.Run()` (`:470`) arranca los trabajos en segundo plano (`Program.cs:228-299`), y Kestrel enlaza su dirección por omisión en HTTP (`http://localhost:5000`) [I].
  - Solo en `ApplicationStarted` actúa el 4746 (HTTP y puerto distinto del modo) y detiene con 1 (`EscuchaServidor.cs:153-170`, `:238-243`). Lo cubre `EscuchaServidorKestrelTests.cs:117`.

  No hay exposición en la red: es *loopback* durante milisegundos o segundos. El efecto es otro: en cualquier equipo con el verbo `red` aplicado (laboratorio, el equipo de C), cada arranque hace escrituras idempotentes en SQL y empieza trabajos (RNC DGII, respaldos posteriores, notificaciones) que luego se cancelan. Con la recuperación del SCM, eso entra en un ciclo de reinicios. La única guarda es un mensaje de commit. La tabla del plano (sección 8) no lista PR-2 como dependencia de PR-4, así que quien una puede seguir la tabla y no el commit.
- **Evidencia.** `Program.cs:56`, `:350-351`, `:445-470`; `EscuchaServidor.cs:43-44` (comentario: «hasta entonces Kestrel queda con su escucha por omisión, en HTTP, y el 4746 lo detiene»); mensaje de `900369a3`; plano v2, sección 8, fila PR-4 (columna «Depende de»).
- **Remediación.**
  - (b) **Obligatoria y barata, minutos.** El PR se abre como borrador con la condición «no unir antes de PR-2». Se corrige la tabla de la sección 8 del plano (PR-4 depende de PR-2) y se avisa a B en `avisos/A-a-B/`, porque cambia la ventana F-5: PR-2 va después de PR-3 (antes del 11-09). Si la ventana del 10-28 al 11-06 no alcanza, rige RC-T4-3 (después del 11-16 o del 11-20).
  - (a) **Recomendada como defensa en profundidad, unas 1 a 2 h con su prueba.** Mientras no exista PR-2, `Preparar` con `ConModo` devuelve una decisión denegada 4743 («RT-05 no disponible en esta compilación»). Así la falla cerrada ocurre en `ExigirArranque`, antes del anillo y de SQL. PR-2 retira esa rama en el mismo commit en que arma los puntos.
  - *Alternativa descartada:* que una prueba de arquitectura falle mientras `ConModo` no arme puntos. Rompería la suite de todos hasta PR-2.

### S4-02 · Baja · Código 1 y Administrador de servicios (continúa S-06 del #127 y S1b-07)

- **Riesgo.**
  - [V] El rechazo antes de `Run` deja `Environment.ExitCode = 1` y retorna de un `Main` asíncrono de nivel superior, así que el proceso sale con 1. Es coherente con N-1, que usa `Environment.Exit(1)` (`ModoServicioApi.cs:164-169`).
  - [I] Como servicio, el proceso termina **antes** de conectar el despachador del SCM (`WindowsServiceLifetime` solo lo hace dentro de `Run`). El SCM registra un error de inicio (terminación inesperada o falta de respuesta), no el código 1.
  - [I] Tras `Run`, el 4746 llama a `StopApplication`, y `WindowsServiceLifetime` informa `SERVICE_STOPPED` con el `ExitCode` de `ServiceBase`, que vale 0 salvo que alguien lo fije. Entonces el SCM ve una parada limpia y no aplica la recuperación ni el monitoreo de «fallo».
  - S-06 queda cerrado en el proceso y **abierto frente al SCM**.
- **Evidencia.** `Program.cs:350-351`; `EscuchaServidor.cs:238-243`; `ModoServicioApi.cs:168`.
- **Remediación (2 a 3 h, A y devops de B).**
  1. Prueba E-04 en el laboratorio: `sc query` y el visor de eventos tras un 4743/4744 y tras un 4746.
  2. En `Detener`, si el `IHostLifetime` es `WindowsServiceLifetime`, fijar su `ExitCode = 1` antes de `StopApplication`.
  3. El instalador activa la recuperación también ante paradas con error (`sc failureflag … 1`), con reintento acotado, según S1b-07.

### S4-03 · Baja · Excepción distinta de `ArranqueRedException` en `ExigirArranque`

- **Riesgo.** [V] El `catch` solo atrapa `ArranqueRedException` (`Program.cs:351`). Otras excepciones posibles dentro de `ExigirArranque` (`EscuchaServidor.cs:126-133`):
  - una `AggregateException` del registro, si un proveedor (el del registro de Aplicación) falla en `LogCritical`/`LogWarning`;
  - un fallo al enganchar `VigilanciaEscucha`.

  **No es una elusión de la falla cerrada:** la excepción no manejada termina el proceso antes de `:352`, así que no se ejecuta ni el anillo, ni SQL, ni `Run` [V por el flujo; I sobre el código no manejado de .NET]. Lo que se pierde es el código 1 (sale con el de excepción no manejada) y el evento de ADR-90 (S-07 solo cubre `Preparar` y la vigilancia). `Preparar` no puede desviar la decisión: todo error al leer o evaluar se vuelve `Denegado` (`EscuchaServidor.cs:81-90`).
- **Remediación (unos 30 min).** Dentro de `ExigirArranque`, envolver toda excepción que no sea `ArranqueRedException` en una `ArranqueRedException` 4743 «imprevista» (como `Imprevista`, `:135-136`) e intentar el registro sin que un segundo fallo impida lanzar. Así el `catch` de `Program.cs` cubre todas las salidas con 1.

### S4-04 · Baja · Las pruebas de texto de `Program.cs` se pueden evadir

- **Riesgo.** [V] Las reglas leen el texto limpio con expresiones regulares:
  - **S6** (`OrdenProgramaApiTests.cs:176-188`, patrón `:95-96`) exige un `catch (ArranqueRedException)` con salida 1, pero no impide un `catch (Exception) { }` adicional en el mismo `try`. Con S4-03, ese `catch` dejaría arrancar sin la vigilancia del 4746.
  - **S3** (`:135-144`) no exige que `ExigirArranque` sea incondicional (de profundidad 0): dentro de un `if` sigue pasando.
  - **S7** no ve un `Configure<KestrelServerOptions>` ni un `Listen…` hecho en un método de extensión de otro archivo.

  El control real es el 4746 en ejecución, y las pruebas sirven contra regresiones accidentales. No son una frontera contra un cambio malicioso, que debe frenar la revisión de código.
- **Remediación (alrededor de 1 h).**
  - S6: el `try` de `ExigirArranque` tiene **un solo** `catch` y es de `ArranqueRedException`.
  - S3 y S5: `Preparar` y `ExigirArranque` van con profundidad de llaves 0, fuera de `if`, `#if` y lambdas.
  - Opcional: una prueba que busque `KestrelServerOptions` y `Listen(` en `src/GPOS.Api/**` fuera de `LimitesPeticiones.cs`.

### S4-05 · Baja (heredado de S1b-05) · Regla sin modo: lo declarado manda y el 4746 llega después del enlace

- **Riesgo.** [V] Sin modo, `ListenLocalhost(5071)` solo se arma si **ninguna** fuente declara direcciones (`EscuchaServidor.cs:99-104`, `:112-119`). Las fuentes son `urls`, `http_ports`, `https_ports`, `PORT`, `Kestrel:Endpoints` y las variables `ASPNETCORE_URLS`, `DOTNET_URLS`, `*_HTTP(S)_PORTS` y `ASPNETCORE_PORT`.
  - Una fuente que declare `0.0.0.0` (variable del proceso, `--urls`, `launchSettings`, o `Kestrel:Endpoints` en `appsettings.json` con recarga) **desactiva** el armado en código. Kestrel enlaza lo declarado y el 4746 detiene en `ApplicationStarted`, o `Revisar` lo hace al recargar (`:172-206`).
  - La ventana dura lo que tarda en arrancar el anfitrión, incluido el `StartAsync` de los trabajos en segundo plano [I].
  - Fijar esas fuentes exige controlar el entorno o los archivos del proceso. Quien lo controla ya puede cargar código (S1b-06).
  - **No es una regresión.** Antes de PR-4, en consola, rigía la dirección por omisión de Kestrel o lo declarado, sin ningún 4746 en la API (S-01 del #127, que este PR **cierra** en la API).
  - **¿Otra interfaz sin fuente declarada?** No: `ListenLocalhost` enlaza solo `127.0.0.1` y `::1` [V el código; I el marco]. La prueba con Kestrel real lo comprueba (`EscuchaSinModoApiTests.cs:43-73`).
  - **¿Vale en consola?** Sí. `Preparar` no mira `EsServicio`, así que la regla rige en consola, como servicio y en el DEMO.
- **Remediación opcional (unos 0,05 dp, ya propuesta en S1b-05).** Un primer middleware que responda 503 hasta que `ComprobarEfectivas` pase una vez.

### S4-06 · Baja (informativa) · Costura `FuenteDePruebas`

- **Riesgo.** [V]
  - `FuenteDePruebas` es un estático mutable `internal` (`EscuchaServidor.cs:63`) y tiene precedencia sobre la fuente de la plataforma (`:83`).
  - `InternalsVisibleTo` es por nombre (`GPOS.Tests`, `GPOS.Web.Tests`) y sin firma fuerte (`GPOS.Comun.Servidor.csproj:23-24`).
  - En producción vale `null`, y una prueba de arquitectura impide nombrarla en `src/` (`RedPlataformaArquitecturaTests.cs`, «La_fuente_de_pruebas_…»).
  - Solo un código que ya corre dentro del proceso podría fijarla (por reflexión o con un ensamblado de ese nombre). Ese código ya puede hacer cualquier cosa, así que no es una frontera nueva.
  - Lo positivo: S1b-03 queda **cerrado en la API**. Las fábricas de `GPOS.Tests` ya no leen `HKLM` y la prueba de humo lo comprueba (`ApiSinModoHumoTests.cs:69`).
- **Remediación opcional (unos 30 min).** Honrar `FuenteDePruebas` solo si `builder.Environment` es `Pruebas` (es el que usa `ApiSinModoFactory`, `ApiSinModoHumoTests.cs:29`). Hay que confirmar antes el entorno de las fábricas de `GPOS.Web.Tests`. Si no, ignorarla y dejar un 4743.

---

## 5. Controles bien implementados

- **Orden del arranque** [V]. Identidad y privilegios (`:32`), luego la configuración completa (`:35`), `Preparar` (`:56`), `Build` (`:348`), `ExigirArranque` (`:350`), el filtro (`:363`) y por último el anillo y los datos (`:445`). Nada entre `Build` y `ExigirArranque` toca datos ni escucha (`:348-351`).
- **Falla cerrada de `Preparar`** [V]. Todo error se vuelve `Denegado`, nunca «sin modo» (`EscuchaServidor.cs:81-90`). Un rechazo no sigue: sale con 1 y libera el anfitrión, lo que vacía los registros (`Program.cs:351`).
- **Filtro de nodos** [V]. Es el primer middleware y va antes de `UseForwardedHeaders` (R1 y R2 son obligatorias: `OrdenProgramaApiTests.cs:44-47`). Sin nodos no agrega nada a la canalización (`FiltroOrigenNodo.cs:43`). El reenvío del marco y el IIS fuera de proceso se rechazan dos veces: 4744 en `Evaluar` y la excepción en `UseFiltroOrigenNodo`. El filtrado de *host* del marco que corre antes no cambia la IP.
- **Retiro limpio de `FijarEscuchaPorOmision`** [V]. Se borraron la función, la constante y la línea, y dos pruebas impiden que vuelva `UseUrls` (S5 y `ApiModoServicioArquitecturaTests`).
- **Regla sin modo armada en código** [V]. No deja `urls` en la configuración, así que no se confunde con una fuente rechazada si después aparece el modo (`EscuchaSinModoApiTests.cs:121-127`). Con Estricto y sin modo no arma nada y da 4743 (`:144-150`). La Web no cambia (`EscuchaServidor.cs:71`).
- **Cambio de 5000 a 5071 en consola** [V/I]. Ninguna referencia del repositorio usa 5000. `launchSettings` (`src/GPOS.Api/Properties/launchSettings.json:8`, `:17`), el DEMO (`instalador/Demo/scripts/herramientas/Comun-Demo.ps1:344`, `ASPNETCORE_URLS`), la Web (`src/GPOS.Web/appsettings.json:14`) y MAUI (`GPOS.UI.MAUI/Servicios/ConfiguracionApi.cs:9-11`) ya esperan 5071. Antes, el ejecutable en consola sin fuentes quedaba en `localhost:5000` [I], también en *loopback*: no aumenta la exposición.
  - Efecto lateral (disponibilidad): una segunda API en el mismo equipo choca en 5071 y no arranca. Es falla cerrada, no abierta.
  - Queda S-02 del #127: HTTP sin autenticar al servidor en 5071, que se cierra con modo en PR-2.
- **S-01 del #127 cerrado en la API.** Las direcciones efectivas se comprueban en servicio y en consola.
- **S1b-04 y S1b-03 aplicados en la API** (`a32eb8b6`), con casos por cada vía y una copia del `Program.cs` real.

---

## 6. Remediaciones priorizadas

| # | ID | Qué | Quién | Cuándo | Esfuerzo |
|---|---|---|---|---|---|
| 1 | S4-01 (b) | PR en borrador «no unir antes de PR-2», tabla del plano corregida y aviso a B por la ventana F-5 | A | Antes de abrir el PR | Minutos |
| 2 | S4-01 (a) | `ConModo` sin RT-05 → 4743 en `Preparar`, antes de los datos (PR-2 lo retira) | A | En este PR (recomendado) | 1 a 2 h |
| 3 | S4-03 | Envolver toda excepción de `ExigirArranque` en `ArranqueRedException` 4743 | A | En este PR | 30 min |
| 4 | S4-04 | S6 con un solo `catch`; S3 y S5 con profundidad 0 | A | En este PR | 1 h |
| 5 | S4-02 | E-04 en el laboratorio; `ExitCode` de `WindowsServiceLifetime`; `failureflag` en el instalador | A (código), devops de B (instalador) | Laboratorio de ADR-90 | 2 a 3 h |
| 6 | S4-05, S4-06 | 503 hasta la primera comprobación; `FuenteDePruebas` solo en `Pruebas` | A | Opcional | 0,05 dp + 30 min |

---

## 7. Recomendación

**Aprobado con observaciones** (recomendación técnica; la unión la ordena el propietario por medio de B). Condiciones:

1. **No se une antes de PR-2** (S4-01). Mientras la guarda sea solo de proceso, es una condición dura. Con el remedio (a), dejaría de bloquear la seguridad, pero seguiría siendo inútil unirlo antes.
2. Firma de F-5 y unión previa de N-1 (#127), como dice el plano.
3. La suite oficial completa (`Transicion!=Ola5&Transicion!=Defecto`) en verde. Este revisor no la ejecutó.

S4-02 a S4-06 no bloquean.

---

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\revision-seguridad-pr4-adr90-2026-10-21.md`
- Supuestos:
  - Kestrel sin puntos ni `urls` enlaza `http://localhost:5000`.
  - `WindowsServiceLifetime` no propaga `Environment.ExitCode` al SCM, y el proceso que sale antes de `Run` aparece como error de inicio.
  - La excepción no manejada termina con un código distinto de 0.

  Los tres se infieren del marco o de Windows y se confirman en el laboratorio (E-04). No se compiló ni se ejecutó nada.
- Decisiones candidatas a ADR: precisión de ADR-90, RT-01 y regla sin modo: la API arma en código `ListenLocalhost(5071)` solo sin modo, sin Estricto y sin direcciones declaradas; si hay una fuente declarada, manda ella y la contiene el 4746. Alternativa descartada: `UseUrls` de N-1, que escribía `urls` y chocaba con la regla 1. La decisión es de A y debe quedar en la descripción del PR (aviso de B, sección 2).
- Entregas a otros agentes:
  - Desarrollador de A: S4-01 (a) y (b), S4-03, S4-04 y la descripción del PR con la regla sin modo.
  - Arquitecto de A: corregir la sección 8 del plano (PR-4 depende de PR-2).
  - Devops de B: `failureflag` y la recuperación acotada (S4-02, S1b-07).
  - QA o C: prueba E-04 en el laboratorio.
- Próximo paso recomendado: aplicar S4-01 (b) y S4-03 en la rama, avisar a B del nuevo orden PR-3 → PR-2 → PR-4 y volver a revisar cuando exista PR-2.
