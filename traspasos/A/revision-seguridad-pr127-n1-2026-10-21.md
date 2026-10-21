# Revisión de seguridad del PR #127 (N-1: GPOS.Api como servicio de Windows)

**Para:** B (encargo del 2026-10-21, Tarea 2, punto 2) · **De:** A, auditor-seguridad · **Fecha:** 2026-10-21
**Rama y punta:** `origin/b/n1-api-modo-servicio` @ `7afa929d`, comparada con `origin/feature/modelo-ng` (`b8f166db`)
**Método:** solo lectura con `git fetch`, `git diff` y `git show`/`git grep`, sin cambiar de rama. **No se compiló ni se ejecutó nada.** **[V]** = verificado en el código (cita `archivo:línea`, siempre de la rama del #127 salvo que se diga otra). **[I]** = inferido del conocimiento del marco o de Windows; se confirma en el laboratorio (L-1 a L-16 del documento de operaciones de A).
**Recomendación técnica:** **Aprobado con observaciones.** No hay hallazgos Críticos ni Altos. Se puede unir; S-01 y S-02 son **condición antes de la primera instalación fuera del laboratorio**. La decisión es del propietario (C2).

---

## 1. Alcance y superficie revisada

| Pieza | Archivo | Qué se revisó |
|---|---|---|
| Comprobación de arranque | `src/GPOS.Api/Servicio/ModoServicioApi.cs:90-105` | `ARRANQUE_IDENTIDAD`, `ARRANQUE_PRIVILEGIOS`, fallos abiertos |
| Rechazo y salida | `ModoServicioApi.cs:111-116` | Evento 4767, `Environment.Exit(1)` |
| Detección del modo | `ModoServicioApi.cs:39`, `:44-46`, `:66-74` | Consola o servicio; ¿lo puede forzar un atacante local? |
| Escucha transitoria | `ModoServicioApi.cs:36`, `:55-60` | `UseUrls("http://localhost:5071")` |
| Registro de eventos | `ModoServicioApi.cs:24-30`, `:77-83`, `:121-141` | 4767 a 4770, filtros, datos sensibles |
| Identidad compartida | `src/GPOS.Comun/Servicios/IdentidadProceso.cs` (nuevo) y `src/GPOS.AgenteImpresion/Estacion/IdentidadServicio.cs` | Se movió el código; P/Invoke del token |
| Orden en `Program.cs` | `src/GPOS.Api/Program.cs:28-34` y `:345-462` | Respecto de la configuración, `Build`, el anillo y `ArranqueRed.Exigir` (PR-4) |
| Pruebas | `tests/GPOS.Tests/Arquitectura/ApiModoServicioArquitecturaTests.cs`, `ModoServicioApiTests.cs`, `tests/GPOS.Tests/ModeloNg/ApiModoConsolaTests.cs` | Qué fijan |
| Precedentes | Estación de impresión (`src/GPOS.AgenteImpresion/Program.cs:10`, `Estacion/ServicioEstacion.cs:22-53`; informe `docs/construccion/2026-10-08-k1-estacion-informe.md` en `feature/modelo-ng`) y `GPOS.Reportes.Api` (`Program.cs:18-31`, `:72`; `Endpoints/ServiciosReportes.cs:170-179`) | Contraste |

**Superficie expuesta nueva:** el mismo binario, ahora como servicio con la cuenta `NT SERVICE\GPOS.Api`, escuchando HTTP en *loopback* (`localhost:5071`). No hay endpoints nuevos, no hay tareas en segundo plano con datos (solo `CicloDeVidaServicio`, que registra eventos) y no cambia el acceso a datos ni la autorización.

**Nota sobre «ExigirArranque»:** no existe en la rama del #127 ni en `feature/modelo-ng` [V]. En el plano de A es `EscuchaServidor.ExigirArranque` (PR-1b/PR-4), que envuelve `ArranqueRed.Exigir` (`origin/a/adr90-rt06-filtro-origen:src/GPOS.Comun/Red/ArranqueRed.cs:185-198`) [V]. El orden se revisa contra ese contrato (sección 5).

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título | Bloquea unir | Bloquea instalar fuera del laboratorio |
|---|---|---|---|---|
| S-01 | Media | Escucha del servicio sin comprobar las direcciones efectivas (transitorio hasta PR-4) | No | **Sí**, salvo que PR-4 se una antes o se aplique el remedio interino |
| S-02 | Media | HTTP en *loopback* sin autenticar al servidor: otro proceso local puede tomar el puerto 5071 | No | **Sí**, hasta PR-2/PR-4 de ADR-90 (TLS) o con el riesgo aceptado por escrito |
| S-03 | Baja | La comprobación depende de detectar el Administrador de servicios (falla abierta ante un falso negativo o con otro alojamiento) | No | No |
| S-04 | Baja | Un error al leer el token, o un origen de eventos ausente, deja el rechazo sin el evento 4767 | No | No |
| S-05 | Baja | Nivel Información de todas las categorías `GPOS*` en el registro de Aplicación (usuarios y origen) | No | No |
| S-06 | Baja | Códigos de salida distintos entre el rechazo de N-1 y los de ADR-90 (PR-4) | No | No |
| S-07 | Baja | Dos cálculos del SID de una cuenta virtual, y el mismo tipo público en dos ensamblados | No | No |

## 3. Checklist OWASP Top 10 (2021)

| Categoría | Resultado | Referencia |
|---|---|---|
| A01 Control de acceso | **Bien.** Identidad del proceso exigida como servicio; sin cambios en la autorización de endpoints ni en el aislamiento entre empresas | Sección 5 |
| A02 Fallas criptográficas | **Observación.** HTTP sin TLS en *loopback*, transitorio (S-02). El SHA-1 del SID es el algoritmo que define Windows para el SID de servicio, no una protección; en el perfil FIPS, `SHA1.HashData` sigue disponible para hash [I] | S-02 |
| A03 Inyección | No aplica (no hay entradas externas nuevas) | — |
| A04 Diseño inseguro | **Observación.** La comprobación depende de una detección y no de una señal explícita del instalador, a diferencia de la estación | S-03 |
| A05 Configuración insegura | **Observación.** La escucha la decide la configuración sin una comprobación posterior | S-01 |
| A06 Componentes vulnerables | **Bien.** `Microsoft.Extensions.Hosting.WindowsServices` 10.0.13 en los tres proyectos (`GPOS.Api.csproj:17`; la prueba exige que coincidan). La subida la confirmó el propietario el 2026-10-21 (aviso B-a-C, P-6). No se ejecutó un análisis de vulnerabilidades (no se ejecuta nada) | — |
| A07 Autenticación | **Observación.** El servidor no se autentica ante la Web hasta que llegue el TLS de ADR-90 | S-02 |
| A08 Integridad | **Bien.** Raíz de contenido = carpeta del binario como servicio (`ModoServicioApi.cs:46`), no `System32`; el archivo de instalación no admite `urls` ni `Kestrel` (`src/GPOS.Comun/Configuracion/ArchivoInstalacion.cs:27`, `:39-40`) | Sección 5 |
| A09 Registro y monitoreo | **Observación.** Rechazo sin evento en dos casos; nivel Información amplio | S-04, S-05, S-06 |
| A10 SSRF | No aplica | — |

## 4. Hallazgos

### S-01 · Media · Escucha del servicio sin comprobar las direcciones efectivas (transitorio)
- **Riesgo.** Como servicio, la API escucha donde diga la configuración. `FijarEscuchaPorOmision` solo pone `localhost:5071` si no hay `urls` ni `Kestrel:Endpoints` (`ModoServicioApi.cs:57-59`) [V], y nada comprueba después a qué direcciones se enlazó Kestrel. Las fuentes que pueden cambiarlo son de administrador: variables de entorno de la máquina (`ASPNETCORE_URLS`, que el marco convierte en `urls`), el valor `Environment` del servicio en el registro, los argumentos de `ImagePath` y el `appsettings.json` de la carpeta del binario [I sobre las ACL]. El archivo de `%ProgramData%` no puede (lista blanca, `ArchivoInstalacion.cs:27`) [V]. Basta un descuido (una variable `ASPNETCORE_URLS=http://+:5071` que dejó una herramienta de desarrollo, o un `appsettings.json` editado) para que la API quede en HTTP en la red local, con contraseñas y tokens en claro. Probabilidad baja, impacto alto.
- **Precedente.** `GPOS.Reportes.Api` sí lo comprueba: `ServiciosReportes.ComprobarDireccionesEfectivas` (`src/GPOS.Reportes.Api/Endpoints/ServiciosReportes.cs:170-179`, llamada en `Program.cs:72`) detiene el servicio si una dirección no es del propio equipo (N-01) [V]. ADR-90 lo trae para la API con el 4746 (`ArranqueRed.DireccionesNoPermitidas`; en «sin modo», solo *loopback*), pero llega con PR-4.
- **Remedio** (elegir uno):
  - (a) **Condición de instalación:** `GPOS.Api.msi` no se instala fuera del laboratorio hasta que PR-4 esté unido. Costo cero si PR-4 llega antes de la primera instalación. **Recomendado** si la fecha lo permite.
  - (b) **Interino:** en `ModoServicioApi`, solo como servicio, registrar en `ApplicationStarted` la misma comprobación de N-01 (todas las direcciones de *loopback*; si no, evento crítico, `Environment.ExitCode = 1` y `StopApplication`). PR-4 lo retira junto con `FijarEscuchaPorOmision`. Son unas 2 a 4 horas con la prueba.
  - *Descartada:* fijar la escucha con `ListenLocalhost` en el código. Ignoraría la configuración del instalador y chocaría con RT-05, donde la escucha la arma `EscuchaServidor`.

### S-02 · Media · HTTP en *loopback* sin autenticar al servidor (ocupación del puerto 5071)
- **Riesgo.** `GPOS.Web` llama a `http://localhost:5071/` (`src/GPOS.Web/appsettings.json:14`) [V] y le envía las credenciales del inicio de sesión y los tokens. En HTTP, nada demuestra que quien atiende el puerto sea `GPOS.Api`. Cualquier proceso local sin privilegios puede escuchar en 5071 mientras la API está detenida: tras un reinicio, en las ventanas de recuperación de 60 s ×3 (documento de operaciones de A, 7.2) o tras un rechazo 4767. Después, Kestrel no puede enlazar el puerto ocupado y la API no arranca [I: `AddressInUseException` se convierte en `IOException` y aborta el inicio], así que el impostor se queda con el puerto. En «un equipo» (caja que también es servidor), los usuarios locales son cajeros. El riesgo ya existía en consola y en el DEMO; N-1 lo lleva al camino de producción.
- **Remedio.** Lo cierra ADR-90: TLS con la huella fijada (PR-2) y la escucha armada por el código (PR-4). Hasta entonces, la misma condición que S-01(a): no instalar fuera del laboratorio sin PR-2/PR-4, o que el propietario acepte el riesgo por escrito para un piloto con un solo usuario de Windows. El documento de operaciones (sección 8) debe nombrar este riesgo, no solo «sirve para la Web del mismo equipo».
- *Descartada:* reservar el puerto con `netsh http add urlacl`. Solo aplica a `http.sys`, no a Kestrel [I].

### S-03 · Baja · La comprobación depende de detectar el Administrador de servicios
- **Riesgo.** `ComprobarArranque` solo actúa si `EsServicio` es verdadero (`ModoServicioApi.cs:39`, `:92`) [V]. `WindowsServiceHelpers.IsWindowsService()` mira si el proceso padre es `services.exe` en la sesión 0 [I]. Un falso negativo, o alojar la API de otra forma (Programador de tareas, un envoltorio como NSSM, otra cuenta como `SYSTEM`), la arranca **sin** comprobar la identidad ni los privilegios: falla abierta.
- **¿Puede un atacante local forzar el modo?** **No puede forzar el modo servicio**: necesita que el padre sea `services.exe`, es decir, crear o reconfigurar un servicio, lo que exige ser administrador. **Sí puede forzar el modo consola** con solo ejecutar el binario, pero corre con su propia identidad, sin ganar privilegios. Eso vale **si** el anillo, las llaves y las carpetas tienen ACL solo para `NT SERVICE\GPOS.Api` (ADR-77; sección 5 del documento de operaciones) [I hasta L-5/L-6]. Fuera de Windows devuelve null (ADR-129: no hay servicio que comprobar) [V].
- **Precedentes.** La estación decide el modo por un **argumento explícito** que escribe el MSI en `ImagePath` (`src/GPOS.AgenteImpresion/Program.cs:10`, `--estacion`), y en ese modo **siempre** comprueba identidad, privilegios y carpetas (`ServicioEstacion.cs:24-29`, `:41-53`) [V]: falla cerrada. Reportes condiciona sus controles a «desarrollo» (entorno y compilación Debug, `Program.cs:30-31`), no a la detección [V].
- **Remedio** (unas 4 horas con pruebas): que `GPOS.Api.msi` registre el servicio con un argumento propio (por ejemplo `--servicio`). Con ese argumento, `ComprobarArranque` se ejecuta siempre y además exige `EsServicio`. Y, sin el argumento, si el SID del proceso es el de `NT SERVICE\GPOS.Api`, se rechaza por incoherencia. *Descartada:* exigir el modo servicio en Release, porque rompería el DEMO y las pruebas en consola (C-10).

### S-04 · Baja · Un rechazo puede quedar sin el evento 4767
- **Riesgo.** (1) `IdentidadProceso.PrivilegiosDelProceso` lanza `Win32Exception` si falla `OpenProcessToken`, `GetTokenInformation` o `LookupPrivilegeName` (`src/GPOS.Comun/Servicios/IdentidadProceso.cs:36`, `:43`, `:56`) [V]. Ninguna excepción se captura en `ComprobarArranque` (`ModoServicioApi.cs:93`) ni en `Program.cs:30` [V]. El proceso cae (falla cerrada), pero con el evento genérico del runtime y no con el 4767. (2) Si el origen `GPOS.Api` no está registrado, la cuenta virtual no puede crearlo. El proveedor de EventLog se desactiva y deja un aviso genérico [I], así que `Rechazar` sale con 1 sin evento propio (`ModoServicioApi.cs:113-115`).
- **Remedio** (1 a 2 horas): capturar la excepción en `ComprobarArranque` y devolver `ARRANQUE_PRIVILEGIOS: no se pudo leer el token (Win32 <código>)` por el mismo camino del 4767. En `Rechazar`, escribir además en `Console.Error`. En la prueba de instalación, comprobar que el origen `GPOS.Api` existe (añadir a L-1/L-2).

### S-05 · Baja · Nivel Información de todas las categorías `GPOS*` en el registro de Aplicación
- **Riesgo.** `ConfigurarRegistro` sube a Información todo lo que empieza por `GPOS` (`ModoServicioApi.cs:81`) [V], no solo los eventos de N-1. Así llegan al registro de Aplicación mensajes con el código del usuario y el origen de la conexión (por ejemplo `src/GPOS.Api/Endpoints/AuthEndpoints.cs:110` y `:345`) [V]. Ese registro lo pueden leer, por omisión, los usuarios interactivos del equipo [I]. Los avisos (Warning) ya llegaban antes por el proveedor por omisión del anfitrión en Windows [I]. Entre ellos está el nombre de usuario tecleado en un intento fallido (`AuthEndpoints.cs:82`), que a veces es una contraseña escrita en el campo equivocado. Son datos personales (Ley 172-13) a la vista de los cajeros. Esto corrige el punto 9 del documento de operaciones de A («Registro sin datos sensibles»), que solo miró los eventos 4767 y 4770.
- **Remedio** (menos de 1 hora): limitar Información a la categoría `GPOS.Api.Servicio` (y a `Microsoft.Hosting.Lifetime`), con Warning para el resto. Aparte, para quien corresponda: no registrar tal cual `req.Usuario` en los intentos fallidos (truncarlo o usar una huella). *Alternativa más cara:* un registro propio `GPOS` con ACL restringida (`CustomSD`) desde el MSI, unas 4 a 8 horas.

### S-06 · Baja · Códigos de salida distintos entre N-1 y ADR-90
- **Riesgo.** N-1 sale con 1 (`ModoServicioApi.cs:115`) [V]. `ArranqueRed.Exigir` (PR-4) lanza `ArranqueRedException` (`origin/a/adr90-rt06-filtro-origen:src/GPOS.Comun/Red/ArranqueRed.cs:191-193`) [V]. Sin captura, el código es el de una excepción no manejada [I]. Si el 4746 usa `StopApplication`, como N-01 en Reportes (`ServiciosReportes.cs:177`), el servicio se detiene limpio con código 0 [I]: el Administrador de servicios no aplica la recuperación y el MSI no ve el fallo. La respuesta P-3 de B dice que E-04 fija «1 en ambos casos», pero la prueba E-04 todavía no existe.
- **Remedio** (en PR-4, menos de 1 hora): capturar `ArranqueRedException` en `Program.cs` y salir por un camino como `Rechazar` (código 1). En el 4746, poner `Environment.ExitCode = 1` antes de `StopApplication`. E-04 lo fija.

### S-07 · Baja · Dos cálculos del SID de una cuenta virtual
- **Riesgo.** `IdentidadProceso.SidDeServicio` (`IdentidadProceso.cs:18-25`) y `CuentaServicioVirtual.Sid` (`src/GPOS.Comun/Introspeccion/CuentaServicioVirtual.cs:19-26`) calculan lo mismo con código distinto [V]. Hoy coinciden, porque Windows siempre es *little-endian* [I]. La segunda decide de quién es dueña la canalización de introspección (`VerificadorIntrospeccion.cs:163`). Si una cambia y la otra no, la identidad del arranque y la del dueño de la canalización divergen sin que nada avise. Además, enlazar la fuente en el agente (`GPOS.AgenteImpresion.csproj`, `Compile Include ... IdentidadProceso.cs`) crea el tipo público `GPOS.Comun.Servicios.IdentidadProceso` en dos ensamblados: si el agente llega a referenciar `GPOS.Comun`, habrá un conflicto de tipos (CS0436).
- **Remedio** (alrededor de 1 hora): que uno delegue en el otro (por ejemplo `CuentaServicioVirtual.Sid` → `IdentidadProceso.SidDeServicio`), más una prueba de igualdad con un SID conocido. Registrar el conflicto de tipos como deuda para cuando el agente referencie `GPOS.Comun`.

## 5. Controles bien implementados

- **Identidad antes que privilegios, y ambos antes de todo lo demás.** `Program.cs:30` va inmediatamente después de `CreateBuilder` y antes del registro, la escucha, el archivo de instalación, los datos, `Build` (`:345`), el anillo (`:437`) y la inicialización (`:438-443`) [V]. `ApiModoServicioArquitecturaTests` exige las cuatro líneas seguidas y antes de `Build` [V]. Matiz: `CreateBuilder` ya leyó `appsettings` y el entorno, pero no se usan antes de la comprobación. El comentario «antes de la configuración» es inexacto, sin riesgo.
- **Orden respecto de ADR-90:** identidad y privilegios (`:30`), luego `Preparar` (tras la configuración) y `ExigirArranque` tras `Build` (PR-4), luego el anillo. Coincide con P-3 de B («identidad y privilegios, luego modo de red, luego anillo, luego datos»). Un servicio con la cuenta equivocada se rechaza con 4767 antes que con 4744 [V].
- **La línea transitoria falla cerrada si se olvida:** con el modo de red presente, el `urls` que escribe `UseUrls` da 4744 y el servicio no arranca. `LineasServicio` obliga a quien una PR-4 a quitarla de forma consciente [V en el contrato de `ArranqueRed.cs:111-112`; efecto en `urls` I].
- **`SidActual()` null se rechaza** (`ModoServicioApi.cs:101`; prueba `Con_otra_cuenta_se_rechaza_por_identidad`) [V].
- **Cuentan todos los privilegios del token, habilitados o no**, comparados sin distinguir mayúsculas (`IdentidadProceso.cs:34-72`) [V]. El código es idéntico al de la estación, solo movido (diff de `IdentidadServicio.cs`) [V]. El P/Invoke es correcto: `TOKEN_QUERY` = 0x0008, `TokenPrivileges` = 3, `LUID_AND_ATTRIBUTES` de 12 bytes a partir del desplazamiento 4, y libera el búfer y el identificador [V].
- **Raíz de contenido = carpeta del binario como servicio** (`ModoServicioApi.cs:46`), no `System32` [V].
- **La escucha por omisión es *loopback* y cede ante una configuración explícita**, y el archivo de `%ProgramData%` no puede inyectar `urls` [V].
- **Los eventos 4767 a 4770 no llevan secretos:** SID, nombres de privilegios y textos fijos (`ModoServicioApi.cs:102-104`, `:114`, `:130-136`). Un solo `LogCritical` (lo fija la prueba) [V].
- **Chrome y Edge sin `--no-sandbox`** (`src/GPOS.Api/Impresion/ConvertidorPdf.cs:74`) [V].
- **ADR-109:** con N-1, la identidad de la principal queda fija (`NT SERVICE\GPOS.Api`). Eso permite a Reportes exigir que esa cuenta sea la dueña de la canalización de introspección (`VerificadorIntrospeccion.cs:87-88`, `:161-168`; identidad exclusiva fuera de desarrollo) [V]. El servidor de introspección exige además que la identidad propia sea exclusiva (`ServidorIntrospeccion.cs:107-110`) [V]: como servicio se cumple.

### ADR-76, punto 2, y ADR-109

- **ADR-76, punto 4** (autocomprobación): **cumplido** como servicio, con la salvedad de S-03.
- **ADR-76, punto 2** (justificación por escrito revisada por el auditor): el borrador de A (`traspasos/A/operaciones-gpos-api-servicio-2026-10-21.md`, secciones 3 y 4) pide solo `SeChangeNotifyPrivilege` y razona el caso del PDF. **Lo comparto:** el *sandbox* de Chromium crea sus hijos con un token restringido derivado del propio, sin `SeAssignPrimaryTokenPrivilege` [I]. La escalera de 4.3 respeta la lista prohibida del punto 2. **Queda abierto** hasta que (1) el documento pase a `docs/operaciones/` del repositorio, (2) se corrija su sección 9 según S-05 y (3) L-9 y L-10 confirmen el PDF bajo la cuenta virtual. Si L-9 pide un privilegio más, vuelve a esta revisión antes de agregarlo.
- **ADR-76, puntos 3 y 5** (`sc qprivs` exacto y cuenta virtual sin SID restringido): no aplican al #127, porque no hay MSI. Son contrato de `GPOS.Api.msi` (L-2).
- **ADR-109, cláusula 9:** la API y Reportes en el mismo equipo, sin TLS entre ellas, por canalización con ACL. N-1 no lo cambia y lo refuerza (identidad fija). Fuera de alcance: `GPOS.Api` sigue referenciando QuestPDF y PuppeteerSharp (`GPOS.Api.csproj`), algo que ya existía y que la cláusula 1 restringe. Se señala para quien lleve ADR-109; no lo introduce este PR.

### Contraste con la estación de impresión (precedente)

| Aspecto | Estación (`GPOS.AgenteImpresion`) | API (#127) | Valoración |
|---|---|---|---|
| Selección del modo | Argumento `--estacion` del MSI (`Program.cs:10`) | Detección de `services.exe` (`ModoServicioApi.cs:39`) | Más débil en la API (S-03) |
| Orden de comprobación | Identidad → privilegios → carpetas (`ServicioEstacion.cs:41-53`) | Identidad → privilegios; las carpetas quedan en el anillo y en ADR-77 tras `Build` | Aceptable: la API no tiene una carpeta propia de componente. La comprobación del anillo es de tipo I (no impide arrancar, `Program.cs:435-437`) y su ACL se prueba en L-5/L-6 |
| Momento | Dentro de `ExecuteAsync`, con el anfitrión ya construido | Antes de `Build`, con su propio `LoggerFactory` | Mejor en la API (nada se inicializa antes) |
| Salida | `Environment.Exit(1)` | `Environment.Exit(1)` | Igual |
| Evento | `LogCritical` sin `EventId` propio | 4767 con nombre | Mejor en la API |
| Puertos | Ninguno | HTTP en *loopback* (transitorio) | S-01, S-02 |

## 6. Remediaciones priorizadas

1. **Antes de la primera instalación fuera del laboratorio:** S-01 y S-02. Lo más barato es unir PR-2/PR-4 de ADR-90 antes. Si no da la fecha: el remedio interino de S-01(b) (2 a 4 horas) y la aceptación escrita del riesgo de S-02 para el piloto.
2. **En el #127 o en el siguiente PR de B, menos de un día en total:** S-05 (filtro de Información, menos de 1 hora), S-04 (captura y origen, 1 a 2 horas) y S-03 (argumento `--servicio` y SID incoherente, unas 4 horas).
3. **En PR-4 (A):** S-06 (código 1 uniforme y E-04).
4. **Deuda:** S-07 (un solo cálculo del SID y una prueba de igualdad).
5. **Documento de operaciones (A):** corregir la sección 9 (S-05), nombrar S-02 en la sección 8, añadir a L-1/L-2 la comprobación del origen de eventos y pasarlo a `docs/operaciones/` (ADR-76, punto 2).

## 7. Recomendación

**Aprobado con observaciones** (recomendación técnica; la firma es del propietario). No hay hallazgos Críticos ni Altos. El #127 puede unirse. **Mientras S-01 y S-02 sigan abiertos, la API no debe instalarse como servicio fuera del laboratorio.**

---

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\revision-seguridad-pr127-n1-2026-10-21.md`
- Supuestos: «ExigirArranque» es `EscuchaServidor.ExigirArranque`/`ArranqueRed.Exigir` de PR-1b/PR-4 (no existe en el #127). La legibilidad del registro de Aplicación, la conducta de Kestrel con el puerto ocupado, la de `IsWindowsService` y la de la recuperación del Administrador de servicios se infieren del marco y de Windows y se confirman en el laboratorio. No se ejecutó nada.
- Decisiones candidatas a ADR: Ninguna. La selección del modo por argumento explícito (S-03) es una precisión de ADR-76, punto 4, que puede registrarse como nota de aplicación si B la adopta.
- Entregas a otros agentes: desarrollador de B → S-03, S-04 y S-05 en `ModoServicioApi`; A (PR-4) → S-06 y la retirada de `FijarEscuchaPorOmision`; devops de B → origen de eventos en L-1/L-2, recuperación y la condición de instalación S-01/S-02; A (documento de operaciones) → secciones 8 y 9 y paso a `docs/operaciones/`; dueño de `AuthEndpoints` → no registrar tal cual el usuario tecleado en los intentos fallidos.
- Próximo paso recomendado: B une el #127 si lo decide y fija con el propietario que la primera instalación fuera del laboratorio espera a PR-4 (o al remedio interino de S-01 y la aceptación escrita de S-02).
