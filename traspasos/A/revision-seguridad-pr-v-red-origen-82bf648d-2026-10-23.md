[Informe de Seguridad] Revisión estática del verbo `red`, del origen `GPOS.Instalacion` y de R4/P4 con el puerto del registro (PR-V) · equipo A · 2026-10-23

- **Objeto:** rama `a/pr-v-verbos-servidor`, `git diff 79bf8905..82bf648d`. Son 3 commits, 23 archivos, +890/−28:
  - `72d34088`: origen `GPOS.Instalacion` en la fase `servicios`, y R6 con los tres orígenes y el 5136;
  - `844096f6`: verbo `red --modo un-equipo`;
  - `82bf648d`: R4 y P4 leen el puerto del registro, y `lectura` ya no llama a `red`.

  El árbol `GPOS-NG-prv` estaba en `82bf648d` y limpio, así que las líneas citadas son de esa punta. No edité nada en él.
- **Contraste:**
  - ADR-90 (`origin/master:docs/adr/ADR-090.md`): RT-01, RT-05, PT-02, PT-03, PT-06 y HB-05;
  - `blueprint-pr-v-verbos-servidor-2026-10-22.md`;
  - las revisiones previas `revision-seguridad-pr-v-verbos-servidor-2026-10-22.md` y `revision-seguridad-pr-v-correcciones-b8f3487a-2026-10-23.md`;
  - `src/GPOS.Comun/Red/ValoresRegistroServidor.cs`, `FuenteConfiguracionRed.Windows.cs` e `InterpretacionRed.cs`.
- **Método:** solo lectura. No se compiló ni se ejecutaron pruebas. No se tocaron el registro, los servicios, `sc` ni `icacls`.
- **Marcas:** [V] verificado por lectura del código; [I] inferido (comportamiento de Windows o de .NET que hay que confirmar en la VM).
- **Naturaleza:** recomendación técnica. La decisión es del propietario (C2).
- **Rutas:** relativas a `src/GPOS.Migracion/Servidor/` salvo que se diga otra cosa.

## Resumen y recomendación

**No hay hallazgos Críticos, Altos ni Medios. Hay nueve Bajos (SPX-01 a SPX-09).**

Lo central del verbo `red` está bien construido:
- valida con la **misma** regla del servicio (`InterpretacionRed`, S-05) antes de tocar nada;
- crea la clave con su descriptor y lo vuelve a leer antes de escribir valores;
- escribe `ModoRed` el último;
- se detiene con 4, sin tocar nada, ante una clave ajena o con otro modo;
- todo va por la vista de 64 bits.

Lo que falta:
- **SPX-01:** las guardas de modo no se repiten si otro escritor administrador crea la clave en medio. Es un hueco de PT-06 por carrera.
- **SPX-02:** el verbo no comprueba la clave padre ni descarta que la clave sea un vínculo simbólico. Solo importa si el padre tuviera una DACL laxa, pero el impacto sería alto.
- **SPX-03:** la ACL da lectura explícita a `GPOS.Reportes`, que no lee la clave, y `GPOS.Web`, que sí la lee, depende de la ACE de Usuarios autenticados.

La recomendación es **Aprobar con condiciones**: SPX-01 y SPX-02 antes del ensayo en la VM (unos 0,15 dp [I]) y la decisión de SPX-03. El resto puede ir en la siguiente pasada.

## 1. Alcance y superficie revisada

- **Verbo `red`:**
  - `ComandoRed.cs` (nuevo);
  - el despacho en `ComandosServidor.cs:14-22` y en `src/GPOS.Migracion/Program.cs` (antes de `--login`);
  - las opciones (`OpcionesComando.cs`, `OpcionesServidor.cs:49-66`);
  - `SddlServicios.cs:50-59`;
  - la capa real `SistemaServidorWindows.cs:428-490`.
- **`GPOS.Comun`:**
  - `ClaveRegistroServidor.Windows.cs`, una fachada nueva;
  - `FuenteConfiguracionRed.Windows.cs:77`, donde `Valores` pasa de privado a interno.
- **`comprobar-servidor`:** `Comprobaciones/EscuchaApi.cs` (nuevo), `R4Escucha.cs`, `P4SaludApi.cs` y `R6Eventos.cs`.
- **Implantación:**
  - `FasesImplantacion/FaseServicios.cs:69-75` (orígenes);
  - `FaseLectura.cs:16-20` y `:59-61`;
  - `DisposicionServidor.cs:72-77`;
  - `EventosServidor.cs` (5139).
- **Pruebas:**
  - `tests/GPOS.Tests/Servidor/RedServidorTests.cs` (nuevo);
  - los cambios en `ComprobarServidorTests.cs`, `ImplantarServidorTests.cs`, `ServidorArquitecturaTests.cs:88-105` y `SistemaServidorFalso.cs`.
- **Superficie expuesta:** el verbo exige una consola elevada (`ComandoRed.cs:38-39`). Lo que puede hacer un no administrador:
  - leer la clave, porque la ACL da lectura a Usuarios autenticados;
  - escribir en el registro de Aplicación [I].

  No hay superficie de red nueva: P4 solo llama a *loopback* (`SistemaServidorWindows.cs:568`).

## 2. Cierre de lo pedido

| Punto | Estado | Evidencia | Nota |
|---|---|---|---|
| (a) ACL de la clave | **Correcta en escritura**; lectura mejorable (SPX-03) | `SddlServicios.cs:56`: dueño BA, DACL protegida, KA solo para SY y BA, KR para AU, Api y Reportes. Prueba: `RedServidorTests.cs:64-78` | KR = `0x20019`: lectura de valores, enumeración, notificación y `READ_CONTROL`. Ningún derecho de escritura de S-05 (`FuenteConfiguracionRed.Windows.cs:96-97`) [V] |
| (a) Orden de escritura | **Correcto** [V] | `ComandoRed.cs:95-118`: crea con descriptor, relee y compara. `:120-131`: escribe `PuertoApi` y después `ModoRed`. `:134-138`: relee e interpreta como el servicio. Prueba del orden: `RedServidorTests.cs:53` | Una clave a medias, sin `ModoRed`, es inválida para el servicio (`InterpretacionRed.cs:33`): nunca da «sin modo» [V] |
| (a) TOCTOU al crear | **Sin ventana explotable por un no administrador** [V lectura; I .NET] | `SistemaServidorWindows.cs:459` pasa `RegistrySecurity` a `CreateSubKey`, que se aplica en `RegCreateKeyEx` [I]. Si .NET lo ignorara, la clave heredaría de `SOFTWARE` (solo SY y BA escriben [I]). `ComandoRed.cs:107-118` lo corrige y lo comprueba antes de escribir valores | La carrera con **otro administrador** queda en SPX-01 |
| (a) Clave existente ajena | **Correcto** [V] | `ComandoRed.cs:69-70`: detención con 4 sin tocar; evento 5136 en `:52-53`. Pruebas `RedServidorTests.cs:147-162`: dueño BU, AU con KW, una persona con KA y sin DACL | El padre no se comprueba: SPX-02 |
| (a) `--puerto-api` | **Correcto en rango y reservados** [V]; sin comprobar ocupación (SPX-05) | `OpcionesServidor.cs:61` usa `NumberStyles.None`, sin signo ni espacios; el desbordamiento se rechaza. `InterpretacionRed.cs:51-56`: de 1024 a 65535, ≠ `PuertoWeb` (443 por omisión), ≠ 5073 y ≠ 17654. Pruebas `RedServidorTests.cs:120-143` y `:244-245` | El 443 nunca llega a compararse porque es < 1024. El `PuertoWeb` de la clave sí cuenta (`:137-143`) |
| (a) Reutiliza `InterpretacionRed` | **Sí, sin copia** [V] | `ComandoRed.cs:81` (antes de escribir) y `:137` (después); `EscuchaApi.cs:35`. S-05 por `ClaveRegistroServidor.MotivoSeguridad`, que delega en `FuenteConfiguracionRedWindows.MotivoSeguridad` (`ClaveRegistroServidor.Windows.cs:33-46`) | — |
| (a) Vista de 64 bits | **Sí** [V] | `SistemaServidorWindows.cs:431` (`RegistryView.Registry64`). La prueba de arquitectura exige `Hklm64()` en los cuatro métodos (`ServidorArquitecturaTests.cs:102-104`) | La prueba no mira que `Hklm64` siga usando `Registry64` (SPX-08) |
| (a) `IpNodos` y HB-05 en «un equipo» | **Seguro** [V] | `InterpretacionRed.cs:70-82`: `IpNodos` solo se lee y se exige en «servidor de sitio». En «un equipo» la API escucha solo en *loopback* (RT-05), así que no hay origen de nodo que filtrar | HB-05 sigue cerrando en falso un «servidor de sitio» sin `IpNodos`. El futuro modo `servidor-sitio` del verbo debe escribirlo. Solo hay una diferencia de redacción con «el paquete lo escribe siempre» (`ValoresRegistroServidor.cs:32-34`) |
| (a) PT-06 (cambio de modo) | **Cumplido**, salvo por carrera (SPX-01) | `ComandoRed.cs:71-73`: otro modo, o uno que no es `REG_SZ` exacto, detiene con 4 y deja el 5136. Prueba `RedServidorTests.cs:164-175`, incluido `unequipo` | — |
| (b) `ClaveRegistroServidor` y `Valores` interno | **No abre nada** [V] | El constructor de producción de la fuente sigue fijo en `HKLM` y la vista de 64 bits, y la clase sigue siendo `internal` (`FuenteConfiguracionRed.Windows.cs:24`, `:31-32`). La fachada es pública, pero solo traduce una clave **ya abierta por quien llama** y evalúa un SDDL; no abre claves ni acepta otra raíz para el servicio | S-04 y S-05 intactos. El paso por SDDL (`Sddl` → `MotivoSeguridad(string)`) falla cerrado si no se puede interpretar (`:41-44`); lo que decide es la comprobación del servicio sobre el binario |
| (c) Prueba «solo `SistemaServidorWindows` escribe» | **Útil, pero eludible** (SPX-08) | `ServidorArquitecturaTests.cs:94-105`: busca a la vez el texto `ValoresRegistroServidor.Clave` y una llamada de escritura | No detecta un literal `@"SOFTWARE\GPOS NG\Servidor"`, `using static`, una ruta armada por partes ni P/Invoke `RegSetValueEx`. Hoy no hay otro escritor en el repositorio [V: grep de `GPOS NG\\Servidor` fuera de `docs/`] |
| (d) Origen `GPOS.Instalacion` y R6 | **Correcto**; la evidencia de R6 se puede falsificar (SPX-07) | `DisposicionServidor.cs:77`; `FaseServicios.cs:70-75`; `R6Eventos.cs:26-28` (FALLA si falta uno) y `:38-44` (el 5136 da AVISO). `OrigenRegistrado` mira solo `…\EventLog\Application\` (`src/GPOS.Comun/Servicios/RegistroEventosReserva.cs:20-27`). Pruebas `ComprobarServidorTests.cs:308-335` e `ImplantarServidorTests.cs:891-910` | **Registrar** el origen exige ser administrador [I], así que no se suplanta el registro del origen. **Escribir** con ese nombre de origen sí lo puede hacer un usuario interactivo [I]: ver SPX-07 |
| (e) R4 y P4 con el puerto del registro | **Falla cerrada** [V] | `EscuchaApi.cs:19-47`: sin la clave, 5071 por HTTP; clave ajena o inválida, FALLA; ilegible, AVISO. P4 usa `HttpClientHandler` sin *callback* de validación (`SistemaServidorWindows.cs:569`), es decir, el almacén del sistema y el nombre `localhost`, y un error de TLS da `null`, que P4 informa como FALLA | No fija `HuellaApi` y el mensaje no distingue un rechazo TLS de una API caída (SPX-06) |
| (f) Pruebas | **Buenas en lo principal**, con huecos (SPX-08) | Ver §4 (f) | — |
| `FaseLectura` no llama a `red` | **Correcto** [V] | `FaseLectura.cs:59-61`; prueba `ImplantarServidorTests.cs:940-947`: ni el verbo `red` ni la clave | Evita dejar el DEMO sin API: con el modo presente, sin `HuellaApi` da 4747 |

## 3. Checklist OWASP (solo el diff)

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | Escritura limitada a SY y BA [V]. SPX-01 (carrera), SPX-02 (padre y vínculo), SPX-03 (lectores) |
| A02 Criptografía | No aplica: el verbo no maneja llaves. P4 usa TLS con el almacén del sistema (SPX-06) |
| A03 Inyección | Sin hallazgos [V]. `--modo` está en una lista cerrada (`OpcionesServidor.cs:49-55`) y `--puerto-api` es un entero estricto. La consulta XPath de `ContarEventos` usa orígenes constantes y rechaza `'` (`SistemaServidorWindows.cs:519`) |
| A04 Diseño inseguro | SPX-01 y SPX-04 (el verbo «arregla» un `PuertoApi` mal tipado) |
| A05 Configuración | SPX-05 (puerto ocupado o efímero) |
| A06 Componentes vulnerables | No aplica: no hay paquetes nuevos |
| A07 Autenticación | No aplica |
| A08 Integridad | Correcto: la validación va antes de escribir, la relectura después, y `ModoRed` es el último valor [V] |
| A09 Registro y monitoreo | SPX-07 (R6 falsificable y desbordable) y SPX-09 (`e.Message` en la salida y en el evento) |
| A10 SSRF | Sin hallazgos nuevos. P4 solo va a *loopback*. `AllowAutoRedirect` sigue con su valor por omisión, que es preexistente (SPX-06) |

## 4. Análisis

### (a) La ACL y la lectura por Usuarios autenticados

**Quién lee la clave** [V]:
- solo `EscuchaServidor.Preparar` crea la fuente (`src/GPOS.Comun.Servidor/Red/EscuchaServidor.cs:106`);
- la llaman `src/GPOS.Api/Program.cs:58` y `src/GPOS.Web/Program.cs:55`;
- `GPOS.Reportes.Api` **no** la lee;
- además, `GPOS.Migracion` (`comprobar-servidor` y el futuro `tls`), que se ejecuta como administrador.

**Lo que da la ACL:**
- tiene una ACE explícita para `GPOS.Reportes`, que no la necesita;
- no tiene ninguna para `GPOS.Web`, que lee la clave **gracias a AU**, porque el token de una cuenta virtual de servicio lleva `S-1-5-11` [I].

Si se quitara AU sin añadir la Web, la Web caería con 4743. Fallaría cerrada, sin riesgo de seguridad, pero sin servicio.

**Qué ve un usuario local** con la ACE de AU:
- `ModoRed`, `PuertoApi` y `PuertoWeb`;
- `NombresServidor` (FQDN e IP del servidor);
- `HuellaApi` y `HuellaWeb` (SHA-256 de certificados públicos);
- `IpNodos` (las IP de los servidores de nodo).

Ninguno es un secreto ni da capacidad de escribir. Casi todo lo obtiene ya un usuario local con `netstat`, el almacén de certificados (parte pública) o la configuración de red. **El riesgo es bajo:** información de reconocimiento interna, no explotable por sí sola. Aun así, la ACE no responde a ninguna necesidad declarada: el comentario de `SddlServicios.cs:50-55` justifica la **máscara** KR («la que pide la fuente al abrirla»), no el **titular** AU. Ver SPX-03.

### (b) S-05 y la fachada

- `MotivoSeguridad` sigue recorriendo la DACL en bruto (S1b-01), con lista blanca de dueños (SY, BA, TrustedInstaller) y rechazo de ACE condicionales.
- El verbo comprueba lo mismo antes de escribir (`ComandoRed.cs:69`, `:104`, `:116-117`, `:135`) y además exige `MismaDacl` con el dueño BA (`ReglasDescriptores.cs:186-192` compara el dueño si el esperado lo trae). Por eso una clave de dueño SYSTEM con la misma DACL se re-protege y no se da por buena.
- Ninguna de las dos piezas abre una clave por una ruta que elija el llamador para el servicio [V].

### (c) Prueba de arquitectura

Es una heurística de texto (`ServidorArquitecturaTests.cs:96-100`) y da falso positivo seguro, porque un comentario con la clave y un `SetValue(` también la hacen fallar. Para el fin declarado (RT-01: escritor único) conviene ampliarla (SPX-08).

### (d) R6 y el origen

- Exigir los tres orígenes evita el falso «0 eventos» [V].
- El 5136 como AVISO es razonable: la detención ya devolvió 4 al operador; R6 solo lo recuerda.
- Límite: el filtro de `ContarEventos` es solo por nombre de proveedor (`SistemaServidorWindows.cs:520-522`), y el registro de Aplicación admite escritura de usuarios interactivos, servicios y lotes con cualquier nombre de origen [I: `CustomSD` por omisión del canal]. Eso permite a un usuario local:
  - **fabricar** un 5136, que da un falso AVISO, o un 5112 a 5116, que da una falsa FALLA (esto último ya existía);
  - **desbordar** el registro (por omisión 20 MB con sobrescritura [I]) para que un evento real salga de la ventana de 15 min.

Ninguna de las dos cosas da acceso. Lo que sí se degrada es la fiabilidad de R6 como evidencia (SPX-07).

### (e) R4 y P4

- `EscuchaApi.Leer` reproduce la decisión del servicio: misma S-05, misma `InterpretacionRed` y HTTPS con el modo presente [V].
- Si la clave no existe, el comportamiento es el de antes (5071 por HTTP, `EscuchaApi.cs:28`): **no hay regresión**.
- P4 por HTTPS valida la cadena contra el almacén del sistema y el nombre `localhost` (RT-05 pone `localhost` en el SAN en «un equipo»). Un certificado no confiable da FALLA. **Falla cerrada** [V].
- Lo que no hace:
  - comparar el certificado con `HuellaApi`, la referencia que fija PT-02;
  - distinguir «TLS rechazado» de «no responde»;
  - comprobar en R4, con el modo presente, que el 5071 ya **no** escucha por HTTP (un resto de la escucha sin modo).

  Todo esto va en SPX-06.

### (f) Pruebas: lo que prueban y qué mutaciones pasarían

**Lo que prueban bien** [V]:
- el orden de las operaciones;
- la idempotencia;
- la DACL exacta, con un caso de AU KA rechazado;
- la detención con 4 en cuatro descriptores ajenos;
- otro modo con comparación ordinal;
- un valor inválido que no se arregla;
- `IgnorarProteccionRed` en los dos caminos (clave nueva y existente);
- falta de elevación, clave ilegible y opciones;
- en R4 y P4: el puerto y HTTPS del registro, FALLA con una clave rechazada y AVISO con una ilegible;
- en R6: los tres orígenes y el 5136.

**Mutaciones que no se detectarían:**

1. Quitar el paso 4 (`ComandoRed.cs:134-138`): el doble siempre escribe fielmente.
2. La rama `CrearClaveRed` = `false` y «apareció con otro descriptor» (`:97-105`): no hay prueba de carrera (SPX-01).
3. `Hklm64` con `Registry32`: la prueba solo busca el nombre del método.
4. La heurística de la prueba de arquitectura: ver (c).
5. El doble ignora la ventana en los eventos de `GPOS.Instalacion` (`SistemaServidorFalso.cs:330-337`): cambiar la ventana del 5136 no se detecta.
6. El 5139 de tipo Error cuando falla, y el contenido del evento: no hay prueba.
7. SPX-04: un `PuertoApi` de tipo `REG_SZ` se sobrescribe sin prueba que lo fije.
8. La capa real (`SistemaServidorWindows.cs:433-490`) no tiene prueba fuera de la VM. Es aceptable por la regla del 2026-10-08, y entra en §7.

## 5. Hallazgos nuevos

| ID | Severidad | Título |
|---|---|---|
| SPX-01 | Baja | Las guardas de modo y de valores no se repiten antes de escribir: un cambio de modo por carrera con otro escritor administrador escapa a PT-06 |
| SPX-02 | Baja (impacto alto si se da la precondición) | No se comprueba el padre `SOFTWARE\GPOS NG` ni se descarta un vínculo simbólico de registro |
| SPX-03 | Baja | La ACL da lectura explícita a `GPOS.Reportes`, que no lee la clave; `GPOS.Web` depende de AU |
| SPX-04 | Baja | Un `PuertoApi` existente con otro tipo se «arregla» en silencio a 5071 |
| SPX-05 | Baja | `--puerto-api` sin comprobar ocupación ni el rango efímero o excluido |
| SPX-06 | Baja | P4 sin fijar `HuellaApi`, sin distinguir el error TLS y con redirecciones; R4 no mira el 5071 residual |
| SPX-07 | Baja | La evidencia de R6 se puede fabricar o expulsar del registro de Aplicación |
| SPX-08 | Baja | Huecos de pruebas (§4 (f)) y prueba de arquitectura eludible |
| SPX-09 | Baja | `e.Message` en la salida y en los eventos 5136 y 5139 |

### SPX-01 (Baja): guardas que no se repiten antes de escribir

- **Riesgo** [V lectura]:
  - Las guardas de PT-06 y de valores inválidos se evalúan sobre la **primera** lectura (`ComandoRed.cs:69-91`).
  - Si entre esa lectura y `CrearClaveRed` otro proceso administrador crea la clave (`CrearClaveRed` devuelve `false`, `SistemaServidorWindows.cs:451-452`), la relectura (`ComandoRed.cs:102-105`) solo comprueba S-05.
  - Después, `:119-131` escribe `PuertoApi` y `ModoRed` sobre `antes` sin volver a mirar el modo. Una clave con `ModoRed=ServidorSitio` recién escrita por el paquete o por otro `red` quedaría en `UnEquipo` **sin la confirmación de PT-06**, aunque sí con el 5139.

  Exige la concurrencia de dos escritores administradores, de ahí la severidad.
- **Remediación** (unas 0,05 dp):
  - mover las guardas de `:69-91` a una función y aplicarla también a `antes`, justo antes de `:120`;
  - con `ModoRed` distinto o un valor inválido, detener con 4;
  - una prueba en la que el doble crea la clave con `ServidorSitio` dentro de `CrearClaveRed` y devuelve `false`.

### SPX-02 (Baja, impacto alto si se da la precondición): padre sin comprobar y vínculo simbólico

- **Riesgo:**
  - `CrearClaveRed` crea o abre el padre `SOFTWARE\GPOS NG` sin mirar su descriptor (`SistemaServidorWindows.cs:454`). Las cuatro operaciones abren `Servidor` siguiendo vínculos simbólicos de registro (`:438`, `:451`, `:466`, `:477`) [V].
  - Si el padre existiera **con una DACL que deja crear subclaves o vínculos a no administradores**, un usuario podría preparar `Servidor` como vínculo hacia otra clave de `HKLM` de dueño de confianza. S-05 la aceptaría (dueño SY, BA o TI, sin escritores ajenos) y `InterpretacionRed` ignora los nombres desconocidos. El verbo, elevado, le aplicaría su DACL y le escribiría `PuertoApi` y `ModoRed`.
  - Según la clave de destino, eso altera una clave del sistema (por ejemplo, una de arranque automático) con la autoridad del administrador [I: que Windows permite a un usuario de integridad media crear un vínculo de `HKLM` a `HKLM` cuando tiene `KEY_CREATE_LINK` en el padre].
- **Precondición:** el padre no lo deja así el propio verbo, porque al crearlo hereda de `SOFTWARE` [I]. Haría falta un instalador o un administrador previo que lo hubiera dejado laxo. Por eso la severidad es Baja.
- **Lado del servicio:** sin cambio. S-05 sobre la clave de destino le impide leer valores de un escritor ajeno.
- **Remediación** (unas 0,1 dp):
  - antes de cualquier cambio, aplicar `MotivoSeguridad` también al padre (dueño de confianza y ningún escritor ajeno). Si falla, detener con 4;
  - abrir `Servidor` con `REG_OPTION_OPEN_LINK` y detener con 4 si es un vínculo (tiene `SymbolicLinkValue` de tipo `REG_LINK`), o comparar el nombre real de la clave abierta (`NtQueryKey`, `KeyNameInformation`) con `\REGISTRY\MACHINE\SOFTWARE\GPOS NG\Servidor`;
  - para devops y B: el MSI que cree `SOFTWARE\GPOS NG` lo hará con la DACL heredada, nunca con una más laxa.

### SPX-03 (Baja): lectores de la clave

- **Riesgo** [V lectura; I token]:
  - `SddlServicios.cs:56` da KR a AU, a `GPOS.Api` y a `GPOS.Reportes`;
  - Reportes no lee la clave y la Web sí (§4 (a));
  - la Web funciona solo por AU, y nada lo documenta;
  - AU expone a todo usuario local datos de topología de baja sensibilidad (§4 (a)).

  No hay escritura ni secretos.
- **Remediación** (unas 0,05 dp; costo de infraestructura nulo), a elección del propietario:
  - **Opción recomendada:** sustituir la ACE de `GPOS.Reportes` por la de `NT SERVICE\GPOS.Web` y **quitar AU** cuando la Web se instale como servicio.
  - **Alternativa:** mantener AU **documentado** como lectura de los servicios del equipo (Web y futuros), y quitar la ACE de Reportes. Se descarta como opción por omisión porque amplía el alcance sin un lector identificado.
  - Con cualquiera de las dos: ajustar el comentario de `SddlServicios.cs:50-55` y la prueba `RedServidorTests.cs:64-78`.
  - En el DEMO, si la Web se ejecuta fuera de un servicio con la cuenta del usuario, AU sigue siendo necesario: confirmarlo antes de quitarlo.

### SPX-04 (Baja): `PuertoApi` mal tipado que se «arregla»

- **Riesgo** [V]:
  - Sin `--puerto-api`, si la clave tiene `PuertoApi` con otro tipo (`REG_SZ`, `REG_QWORD`), `ComandoRed.cs:74-75` toma 5071.
  - `:120-125` sobrescribe el valor y cambia el puerto en silencio. Contradice el «no lo arregla» del propio verbo (`:20-22`) y cambia la escucha sin que el operador lo pidiera.

  Es un estado que solo deja un administrador.
- **Remediación** (unas 0,02 dp): si existe `PuertoApi` y no es `int` y no se dio `--puerto-api`, detener con 4 («indique `--puerto-api`»). Añadir una prueba.

### SPX-05 (Baja): puerto ocupado, efímero o excluido

- **Riesgo:** se valida el rango y los puertos reservados del producto (§2), pero no:
  - que el puerto esté libre (`DireccionesEscucha` ya existe en `ISistemaServidor`);
  - que caiga en el rango efímero (49152 a 65535) o en los rangos excluidos de Windows (Hyper-V y WinNAT).

  Las consecuencias:
  - **Disponibilidad:** la API no enlaza.
  - **Ocupación previa por un proceso local:** en «un equipo» la mitiga el TLS, porque el impostor no tiene la llave del certificado [I].
- **Remediación** (unas 0,05 dp): AVISO, sin detener, si el puerto ya escucha o está en el rango efímero. Leer los rangos excluidos solo en la VM (consulta de solo lectura) y decidir allí si se rechazan.

### SPX-06 (Baja): P4 y R4 con HTTPS

- **Riesgo** [V]:
  - P4 acepta cualquier certificado que valide el almacén del sistema para `localhost`, sin compararlo con `HuellaApi`, que PT-02 fija como la referencia (`SistemaServidorWindows.cs:569`).
  - Un rechazo TLS se informa como «la API principal no responde» (`P4SaludApi.cs:22`).
  - `AllowAutoRedirect` queda en su valor por omisión: una respuesta 3xx se sigue sin repetir la comprobación de *loopback* (preexistente; sin credenciales, porque `UseDefaultCredentials` es `false`).
  - R4 deja de mirar el 5071 cuando hay modo (`R4Escucha.cs:28-30`), así que un resto de escucha HTTP no se ve.
- **Remediación** (unas 0,05 dp):
  - un *callback* que exija **a la vez** `sslPolicyErrors == None` y, si `HuellaApi` está presente, SHA-256 del DER igual a `HuellaApi`. Nunca debe aflojar la validación;
  - `AllowAutoRedirect = false`;
  - capturar `AuthenticationException` dentro de `HttpRequestException` para dar un mensaje propio;
  - en R4, con el modo presente, FALLA si el 5071 escucha.

### SPX-07 (Baja): evidencia de R6 falsificable

- **Riesgo:** §4 (d). Evidencia [V]: `R6Eventos.cs:31-44` y `SistemaServidorWindows.cs:517-535`. Que el canal admite escritura de usuarios interactivos y el tamaño por omisión son [I].
- **Remediación:**
  - **ahora** (unas 0,05 dp): en R6, si el registro de Aplicación rotó dentro de la ventana (el registro más antiguo es más reciente que «ahora − 15 min»), dar AVISO («la ventana no está completa»). Documentar un tamaño mínimo del registro (por ejemplo, 64 MB) en la guía del DEMO;
  - **en el MSI de B:** un canal propio con `ChannelAccess` que solo deje escribir a SY, BA y los SID de los servicios, y que R6 lea ese canal.

### SPX-08 (Baja): pruebas

**Remediación** (unas 0,1 dp):
- pruebas para las mutaciones 1, 2, 5, 6 y 7 de §4 (f). Para la 1, un modo del doble que «pierde» una escritura;
- en la prueba de arquitectura:
  - buscar también el literal `GPOS NG\Servidor` (con una o dos barras), `RegSetValueEx`, `RegCreateKeyEx` y `using static …ValoresRegistroServidor`, en `src/` y en los guiones `*.ps1` y `*.wxs`;
  - exigir que el cuerpo de `Hklm64` contenga `RegistryView.Registry64`.

### SPX-09 (Baja): mensajes de excepción en la salida y en el evento

- **Riesgo** [V]:
  - `ComandoRed.cs:49` pone `e.Message` en el motivo;
  - `:51-56` lo lleva a los eventos 5136 y 5139.

  En el registro, el mensaje trae rutas, no secretos, pero rompe la convención de PR-V de dar solo el tipo (A09 de las revisiones previas; `SistemaServidorWindows.cs:444`).
- **Remediación** (unas 0,01 dp): solo `e.GetType().Name` en el evento; el mensaje, como mucho, en la consola.

## 6. Controles que están bien implementados [V]

- Validación **antes** de escribir con la misma `InterpretacionRed` y la misma S-05 del servicio, sin duplicar reglas.
- La clave nace con su descriptor y se vuelve a leer y comparar (`MismaDacl` con el dueño) antes de escribir el primer valor.
- `ModoRed` es el último valor: una interrupción deja una clave inválida (4743), no un arranque sin modo.
- Detención con 4, sin tocar nada y con evento, ante una clave ajena, otro modo o un valor inválido; no la «arregla».
- `servidor-sitio` y la falta de elevación se rechazan antes de leer nada.
- Idempotencia: sin cambios no se escribe ni se emite el 5139.
- Todo acceso por la vista de 64 bits y detrás de `ISistemaServidor`. `ValoresRegistroServidor` es la única fuente de nombres.
- `FaseLectura` no ejecuta `red` y sigue terminando en 1, así que el DEMO no se queda sin API por falta de `tls`.
- R4 y P4 reproducen la decisión del servicio y fallan cerrados.
- R6 ya no da un OK vacío cuando falta un origen.
- `--puerto-api` con análisis estricto y `--modo` con una lista cerrada.

## 7. Lo que solo la VM puede confirmar

En `VM-SRV`, desde el punto de control `base`, con evidencia sin valores:

1. **Primera ejecución de `red --modo un-equipo`:**
   - el SDDL de la clave (`Get-Acl`) es exactamente `O:BAD:P(...)`;
   - `cambios=3`, no 4: confirma que `CreateSubKey` aplicó el descriptor;
   - no hay nada en `WOW6432Node` (`reg query … /reg:32`).
2. **`ProtegerClaveRed`** sobre una clave de dueño SYSTEM y DACL de confianza: queda con dueño BA y DACL protegida, y la segunda pasada da `cambios=0`.
3. **Usuario estándar:**
   - no puede crear `HKLM\SOFTWARE\GPOS NG\Servidor` ni subclaves del padre creado por `red`;
   - lee la clave (AU).
4. **Lectores reales:**
   - `GPOS.Api` arranca leyendo la clave;
   - `GPOS.Web` como servicio la lee solo por AU (prueba sin AU: 4743), para decidir SPX-03;
   - `whoami /groups` de una cuenta virtual muestra `S-1-5-11`.
5. **SPX-02:** con un padre de DACL laxa preparado a propósito en la VM, que el verbo corregido detiene con 4 ante un vínculo. Sin el arreglo, confirmar la precondición [I] sin ejercitar el efecto sobre claves del sistema.
6. **Registro de Aplicación:**
   - un usuario interactivo puede escribir con el origen `GPOS.Instalacion`;
   - su tamaño y su retención (SPX-07);
   - el 5136 y el 5139 aparecen después de la fase `servicios` y no antes.
7. **API con `ModoRed` y sin `HuellaApi`:**
   - da 4747;
   - `comprobar-servidor` da FALLA en P4 y la R4 que corresponda;
   - el aviso de `red` sale en la consola.
8. **P4 por HTTPS** con el certificado de `tls`, cuando exista: la cadena es confiable en el almacén del administrador, el SAN lleva `localhost` y el mensaje ante un certificado no confiable (SPX-06).
9. **`--puerto-api`** en un puerto ocupado y en un rango excluido: el comportamiento del servicio y el de R4 (SPX-05).
10. **`GPOS.Migracion` de 32 bits**, si alguna vez se publica así: escribe en la vista de 64 bits.

## 8. Remediaciones priorizadas

| Orden | Hallazgos | Cuándo | Esfuerzo [I] |
|---|---|---|---|
| 1 | SPX-01 (guardas antes de escribir) y SPX-02 (padre y vínculo) | antes del ensayo en la VM | 0,15 dp |
| 2 | SPX-03: decisión del propietario sobre AU, y la ACE de Web en lugar de la de Reportes | antes de instalar la Web como servicio | 0,05 dp |
| 3 | SPX-04, SPX-06 y SPX-09 | siguiente pasada | 0,08 dp |
| 4 | SPX-05, SPX-07 (rotación del registro) y SPX-08 | siguiente pasada | 0,2 dp |
| 5 | Canal propio de eventos con `ChannelAccess` (SPX-07) | con el MSI de B | dentro del MSI |

Total: unos 0,5 dp. No suma costo de infraestructura ni licencias.

## 9. Recomendación

**Aprobar con condiciones.**
- No hay hallazgos Críticos, Altos ni Medios.
- Antes del ensayo en la VM: SPX-01 y SPX-02.
- Antes de instalar la Web como servicio: la decisión de SPX-03.
- Lo marcado [I] se confirma con §7.

### Cierre
- Estado: Aprobado con observaciones (recomendación técnica: **Aprobar con condiciones**).
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\revision-seguridad-pr-v-red-origen-82bf648d-2026-10-23.md`.
- Supuestos (todos [I], a confirmar en la VM):
  - `CreateSubKey` con `RegistrySecurity` aplica el descriptor al crear;
  - `HKLM\SOFTWARE` no deja crear subclaves a los usuarios;
  - el token de una cuenta virtual lleva AU;
  - el registro de Aplicación admite escritura de usuarios interactivos con cualquier nombre de origen;
  - Windows permite a un usuario de integridad media crear vínculos de `HKLM` a `HKLM` donde tiene `KEY_CREATE_LINK`.
- Decisiones candidatas a ADR: ninguna nueva. SPX-03 (lectores de la clave de RT-01) es una precisión de PT-02 que firma el propietario.
- Entregas a otros agentes:
  - desarrollador o arquitecto-software de A → SPX-01 a SPX-09;
  - devops y B (MSI) → `SOFTWARE\GPOS NG` con la DACL heredada y un canal de eventos propio (SPX-02 y SPX-07);
  - qa-automatizado → las mutaciones de §4 (f) y la lista de la VM (§7).
- Próximo paso recomendado: corregir SPX-01 y SPX-02 (unos 0,15 dp) y llevar §7 al ensayo en la VM.
