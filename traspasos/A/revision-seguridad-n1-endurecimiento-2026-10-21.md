# Revisión de seguridad: endurecimiento de N-1 (S-03, S-04, S-05 y S-07 del #127)

**Para:** B · **De:** A, auditor-seguridad · **Fecha:** 2026-10-21
**Rama y punta:** `a/n1-endurecimiento-servicio` @ `20f12956` (commits `91d483ab` y `20f12956`), comparada con `origin/feature/modelo-ng` (5 archivos, +460/-29). Clon `GPOS-NG-n1fix`.
**Método:** solo lectura (`git show`, `git diff`, lectura de archivos). **No se compiló ni se ejecutaron pruebas.** **[V]** = verificado en el código; **[I]** = inferido del marco o de Windows, se confirma en el laboratorio (L-1/L-2).
**Revisión de origen:** `traspasos/A/revision-seguridad-pr127-n1-2026-10-21.md`.
**Recomendación técnica:** **Aprobado con observaciones.** S-03, S-04, S-05 y S-07 quedan cerrados en el código. No hay regresiones Críticas, Altas ni Medias. La decisión es del propietario (C2).

---

## 1. Alcance y superficie revisada

| Pieza | Archivo |
|---|---|
| Argumento `--servicio`, decisión del arranque, rechazo, filtro del registro | `src/GPOS.Api/Servicio/ModoServicioApi.cs` (completo) |
| Camino de reserva del 4767 (P/Invoke) | `src/GPOS.Comun/Servicios/RegistroEventosReserva.cs` (nuevo) |
| Un solo cálculo del SID | `src/GPOS.Comun/Servicios/IdentidadProceso.cs:19-32`, `src/GPOS.Comun/Introspeccion/CuentaServicioVirtual.cs:18` |
| Pruebas | `tests/GPOS.Tests/Arquitectura/EndurecimientoServicioApiTests.cs` |
| Contexto sin cambios | `src/GPOS.Api/Program.cs:28-32`, `src/GPOS.Api/appsettings.json:8-14` y los emisores de las tres categorías en Información |

**Superficie nueva:** ninguna de red. Lo nuevo es una lectura del registro de Windows (HKLM, solo lectura) y una escritura en el registro de eventos de Aplicación por P/Invoke, ambas solo en el camino del rechazo.

## 2. Estado de los hallazgos de la revisión anterior

| ID | Estado | Evidencia |
|---|---|---|
| S-03 | **Cerrado en el código**; será efectivo cuando el MSI escriba `--servicio` (R-01) | `ModoServicioApi.cs:41`, `:56-67`, `:122`, `:143-163` |
| S-04 | **Cerrado**, con un residuo Bajo (R-02) | `ModoServicioApi.cs:148-161`, `:166`, `:184-221`, `:243-247`; `RegistroEventosReserva.cs:21-52` |
| S-05 | **Cerrado** según el remedio propuesto; quedan las tres categorías deliberadas (R-05) y falta una prueba de la precedencia (R-06) | `ModoServicioApi.cs:106-114` |
| S-07 | **Cerrado** | `CuentaServicioVirtual.cs:18` delega; `IdentidadProceso.cs:25-31` usa `BinaryPrimitives` y rechaza un nombre vacío; la prueba compara con SID conocidos (`TrustedInstaller`, entre otros) en los tres puntos de entrada (`EndurecimientoServicioApiTests.cs:208-217`) |
| S-01, S-02 | Abiertos (fuera de este cambio; condición de instalación) | — |
| S-06 | Abierto (es de PR-4) | — |

## 3. Tabla resumen de hallazgos nuevos o residuales

| ID | Severidad | Título |
|---|---|---|
| R-01 | Baja | S-03 solo es efectivo cuando `GPOS.Api.msi` registra `--servicio`; otro alojamiento sin el argumento sigue sin comprobación |
| R-02 | Baja | `EscribirRechazo` puede devolver true sin evento: el proveedor de .NET se traga la `SecurityException` y no se usa la reserva |
| R-03 | Baja | P/Invoke con el marshaling implícito y un `IntPtr` en lugar de `SafeHandle` |
| R-04 | Baja (riesgo aceptable) | En consola, si no se puede leer el SID, no se rechaza (C-10) |
| R-05 | Baja | Las tres categorías en Información llevan el código del usuario y de la empresa al registro de Aplicación, que pueden leer los usuarios interactivos |
| R-06 | Baja | La prueba de S-05 valida el predicado, no la precedencia efectiva de las reglas de filtro |

## 4. Checklist OWASP Top 10 (2021), solo sobre el cambio

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | **Bien.** La falla es cerrada con el argumento y con la detección; la incoherencia en consola se rechaza (`ModoServicioApi.cs:145-157`) [V]. Residuo en R-01 y R-04 |
| A02 Criptografía | **Bien.** El SHA-1 es el de la derivación del SID de Windows, no una protección (`IdentidadProceso.cs:19-22`) |
| A03 Inyección | **Bien.** `OrigenRegistrado` rechaza `\` en el origen (`RegistroEventosReserva.cs:23`) [V]; `ReportEvent` recibe el texto como dato de inserción y no como formato |
| A04 Diseño inseguro | **Bien.** El argumento explícito sigue el precedente de `--estacion`; no funciona como interruptor para desactivar la comprobación (`:143-163`) [V] |
| A05 Configuración | **Bien.** El argumento se quita antes del proveedor de línea de órdenes (`:56-57`, `:66-67`) [V]; `Program.cs` solo usa `args` en `:28` [V] |
| A06 Componentes | No aplica (sin paquetes nuevos) |
| A07 Autenticación | No aplica |
| A08 Integridad | **Observación.** Un evento sin `lpUserSid` con un origen no registrado no prueba quién lo escribió (R-03, nota) |
| A09 Registro y monitoreo | **Bien con observaciones.** El 4767 se garantiza salvo en el caso de R-02; el filtro está limitado (R-05, R-06) |
| A10 SSRF | No aplica |

## 5. Verificación de las preguntas del encargo

### 5.1 ¿Se puede eludir la comprobación con el argumento? [V]
- **Se quita de la configuración de forma correcta.** `Opciones` pasa `SinArgumentoServicio(args)` a `WebApplicationOptions.Args` (`ModoServicioApi.cs:57`). El filtro elimina **todas** las apariciones exactas (ordinal) en cualquier posición (`:66-67`). Así, `--servicio --urls x` ya no deja `servicio=--urls`, y repetir el argumento no tiene efecto. La prueba `S03_el_argumento_se_reconoce_exacto_y_no_llega_a_la_configuracion` lo fija (`EndurecimientoServicioApiTests.cs:32`).
- **Variantes (`--Servicio`, `--servicio=1`, `/servicio`):** no se reconocen como el argumento y llegan a la configuración como la clave `servicio`, que nadie lee. **No eluden nada.** Sin el argumento, la detección del Administrador de servicios sigue imponiendo la comprobación (`:147`, `:158-162`). La variante solo pierde la falla cerrada ante un falso negativo, que es el mismo residuo de R-01.
- **Fuentes de los argumentos:** `ComprobarArranque()` lee `Environment.GetCommandLineArgs().Skip(1)` (`:122`) y `Opciones` usa los `args` de `Main`. En .NET los dos vienen de la misma línea de órdenes (el elemento 0 es el binario) [I]. Escribir en `ImagePath` exige ser administrador.
- **Tabla de decisión (`:143-163`):** con el argumento y sin el Administrador de servicios, rechazo sin leer el proceso. Con el argumento o detectado como servicio, identidad y luego privilegios. En consola con el SID de `NT SERVICE\GPOS.Api`, rechazo. En consola con otra cuenta, no se lee el token. **Sin `--servicio` pero detectado como servicio**, la comprobación corre completa (`:147`, `:158-162`; prueba `:68`). **Es correcto.**
- **Fuera de Windows,** pedir el modo servicio se rechaza (`:127-128`) [V]: falla cerrada coherente con ADR-129.

### 5.2 `Environment.Exit(1)` y carreras [V/I]
`Rechazar` (`:184-189`) escribe primero, de forma síncrona: `Console.Error` (con vaciado automático), el proveedor de EventLog con `using` que descarta la fábrica antes de salir, y `ReportEvent`, que es síncrono. Después llama a `Exit(1)`. Se invoca en el hilo principal, antes de `Build` (`Program.cs:30`), sin servicios alojados ni Kestrel arrancados. Los únicos hilos vivos son los de segundo plano (vigilancia de `appsettings`) [I], y no hay carrera que pierda el evento. Cada camino de escritura tiene su `try/catch` (`:204-220`), así que nada impide la salida con 1. La conducta del Administrador de servicios ante una salida antes de conectar el despachador es la misma que en el #127, no es una regresión (L-1/L-2).

### 5.3 ¿El evento de reserva filtra datos? [V]
El texto es `motivo + ". El servicio no arranca."` (`:203`). Los motivos posibles son:
- textos fijos (`:128`, `:146`, `:156`);
- el SID actual y el esperado, y los **nombres** de los privilegios sobrantes (`:174`, `:176`), sin cambios respecto del #127 y ya aceptados;
- en S-04, **solo** el código Win32 o el nombre del tipo de la excepción (`:166`), sin `Message` ni traza.

No hay secretos, rutas, cadenas de conexión ni datos de clientes. El mismo texto va a `Console.Error` (`:204`): en servicio no tiene destino y en consola solo lo ve quien ejecutó el binario. **Bien.**

### 5.4 P/Invoke (`RegistroEventosReserva.cs:54-62`) [V/I]
- Las firmas coinciden con `RegisterEventSourceW`, `DeregisterEventSource` y `ReportEventW`: `WORD` = `ushort`, `DWORD` = `uint`, `PSID`/`LPVOID` = `IntPtr`, `BOOL` = `bool` (4 bytes por omisión en `DllImport`). No hay estructuras, así que no cabe una desalineación. El evento 4767 cabe en `DWORD` sin bits de severidad (`:44`).
- `string[]` con `CharSet.Unicode` se convierte en un arreglo de `LPWSTR` [I, conducta documentada del marshaling por omisión]. Ver R-03.
- El identificador se libera en un `finally` (`:46`) y se comprueba el `IntPtr.Zero` (`:41`). No hay `SafeHandle`, lo que es aceptable en un proceso que sale a continuación (R-03).
- `OrigenRegistrado` solo abre la clave para leer y nunca crea el origen [V]. `RegisterEventSource` con un origen no registrado escribe en Aplicación sin crear nada [I, documentación de Win32]. La ACL por omisión del registro de Aplicación da escritura a las cuentas de servicio (SU) [I, L-1].

### 5.5 Falla abierta en consola ante la lectura del SID (C-10) → R-04
Ver el hallazgo R-04: el riesgo es aceptable.

### 5.6 Las tres categorías en Información de `appsettings.json:10-12` → R-05
- **Precedencia [I].** La regla de `Logging:EventLog:LogLevel:<categoría>` es del mismo proveedor y tiene una categoría más específica que la regla con función de `ConfigurarRegistro` (`:109`, categoría nula), así que manda para esas tres. Es lo que dice el comentario (`:101`) y lo que se busca: son eventos de auditoría firmados (SP-01, SP-03, SN-04, H-EI-01).
- **Contenido [V]:**
  - `GPOS.Ncf.Rastro` (`src/GPOS.Core/Infraestructura/Ncf.cs:116-118`): código de empresa, **usuario**, tipo y número de documento, tipo de comprobante y motivo. Nada del cliente (Ley 172-13, dicho en `:85-87`).
  - `GPOS.Numeracion.Rastro` (`src/GPOS.Core/Servicios/NumeracionService.cs:926-928`): empresa, **usuario**, serie, campo, valor anterior y nuevo de la numeración, versión, y «sí/no» en lugar del texto del motivo.
  - `GPOS.Api.Seguridad.ModoEsquemaPendiente` (`src/GPOS.Api/Seguridad/ModoEsquemaPendiente.cs:71-72`): método, ruta (`Request.Path`, sin la cadena de consulta), **usuario** (Super Usuario) y empresa.
- **Conclusión:** no llevan secretos ni datos de clientes. Sí llevan el **código del usuario** (un empleado identificable, dato personal de bajo riesgo) y metadatos operativos (quién guardó sin NCF, quién cambió la numeración). Por eso su clasificación es Baja (R-05).

## 6. Hallazgos

### R-01 · Baja · S-03 depende de que el MSI escriba `--servicio`
- **Riesgo.** Hasta que `ServiceInstall/@Arguments` lleve `--servicio` (lo dice el commit; no está en esta rama), la protección contra un falso negativo de `IsWindowsService` no actúa. Además, alojar la API por otra vía sin el argumento y con una cuenta distinta de la virtual (Programador de tareas con `SYSTEM`, NSSM) sigue arrancando sin comprobación (`ModoServicioApi.cs:147`, `:154-157`). Hacerlo exige ser administrador.
- **Remedio.** Que el PR del instalador agregue `--servicio`. Incluir en L-2 la comprobación de que `ImagePath` lo contiene. Unir el PR del MSI antes de la primera instalación fuera del laboratorio, la misma condición que S-01/S-02. Costo: menos de 1 hora en el MSI.

### R-02 · Baja · El 4767 puede quedar sin escribir aunque `EscribirRechazo` devuelva true
- **Riesgo.** Con el origen registrado se usa el proveedor de .NET (`ModoServicioApi.cs:209-216`). El `WindowsEventLog.WriteEntry` de `Microsoft.Extensions.Logging.EventLog` **captura** la `SecurityException`, se desactiva e intenta un aviso genérico sin lanzar [I, código del marco]. Si `EventLog` no puede verificar el origen (por ejemplo, el origen se registró en otro registro distinto de Aplicación y la búsqueda llega a la clave de `Security`), no se escribe el 4767, el método devuelve true y la reserva no se usa. La probabilidad es baja con el MSI correcto.
- **Remedio (unos 30 min).** Escribir el 4767 **siempre** por `RegistroEventosReserva.EscribirError`. Con el origen registrado por .NET, cuyo archivo de mensajes es `EventLogMessages.dll` con `%1`, el texto se muestra completo [I]. Así queda un solo camino, y el proveedor de .NET se reserva para el anfitrión ya construido. *Descartada:* hacer las dos escrituras, porque duplicaría el evento en el caso normal.

### R-03 · Baja · P/Invoke: marshaling implícito e `IntPtr`
- **Riesgo.** Es correcto hoy [V/I], pero depende de valores por omisión: el arreglo de cadenas según `CharSet` y `bool` como `BOOL`. Usar `IntPtr` en lugar de `SafeHandle` no libera el identificador ante excepciones asíncronas, que no aplica en .NET 10 salvo casos extremos. No pasar `lpUserSid` (`RegistroEventosReserva.cs:44`) deja el evento sin usuario: cualquier proceso local con escritura en Aplicación puede producir un «4767 de GPOS.Api» indistinguible [I].
- **Remedio (alrededor de 1 hora).** Pasar a `LibraryImport` con `StringMarshalling.Utf16` y `[MarshalAs(UnmanagedType.LPArray, ArraySubType = UnmanagedType.LPWStr)]` o el equivalente explícito, y `[return: MarshalAs(UnmanagedType.Bool)]`. Opcionalmente, un `SafeHandle` propio con `DeregisterEventSource`. Para el diagnóstico, pasar el SID del proceso como `lpUserSid` para que el visor muestre `NT SERVICE\GPOS.Api`.

### R-04 · Baja (riesgo aceptable) · En consola no se rechaza si no se puede leer el SID
- **Evidencia.** `ModoServicioApi.cs:149-153`: en consola, una excepción de `leerSid` devuelve null. Se lee con `WindowsIdentity.GetCurrent().User` (`IdentidadProceso.cs:35-39`).
- **Evaluación.**
  1. La regla de incoherencia es **defensa en profundidad**. Su objetivo es un proceso con la cuenta `NT SERVICE\GPOS.Api` fuera del Administrador de servicios, y obtener ese token exige ser administrador o `SYSTEM`.
  2. `GetCurrent()` sobre el propio proceso falla solo en condiciones degeneradas, como falta de memoria o un token inaccesible, y un usuario sin privilegios no puede provocarlo en su propio proceso [I].
  3. En consola el proceso corre con la identidad de quien lo lanza. La frontera real son las ACL del anillo, las llaves y las carpetas (ADR-77, L-5/L-6), no esta comprobación.
  4. Rechazar en este caso protegería contra un escenario que exige ser administrador, y podría romper el DEMO en entornos raros.
- **Remedio opcional (15 min).** Escribir un aviso a `Console.Error` cuando no se pueda leer el SID en consola, para que no pase en silencio. Se acepta como está.

### R-05 · Baja · Las tres categorías en Información exponen el código del usuario a los usuarios interactivos
- **Riesgo.** El registro de Aplicación lo pueden leer los usuarios interactivos (IU) por omisión [I]. Un cajero podría ver quién guarda documentos sin NCF (`Ncf.cs:116`) o quién cambió la numeración (`NumeracionService.cs:926`). En un contexto de fraude en caja, eso le dice qué usuarios tienen el privilegio «No generar comprobante». No hay datos de clientes ni secretos. Aparte y fuera de este cambio, sigue abierta la observación de S-05 sobre `AuthEndpoints.cs:82` (Warning con el usuario tecleado en un intento fallido), que llega al registro en cualquier nivel.
- **Remedio.** (a) **Aceptar** para el piloto, porque son eventos de auditoría firmados y son datos internos del comercio; costo cero. (b) En el MSI, un registro propio `GPOS` con `CustomSD` que niegue la lectura a IU y la dé a Administradores y a la cuenta del servicio, y pasar ahí las tres categorías: 4 a 8 horas (la alternativa de S-05). **Recomendado: (a) ahora y (b) en el PR del instalador si el propietario lo prioriza.** El dueño de `AuthEndpoints` debe resolver `:82` (huella o truncado).

### R-06 · Baja · La prueba de S-05 no fija la precedencia efectiva
- **Riesgo.** `S05_solo_el_modo_servicio...` (`EndurecimientoServicioApiTests.cs:186-206`) prueba `EnInformacion`, pero no que la regla de `:109` gane a la que agrega el anfitrión por omisión en Windows (EventLog desde Warning) ni a `Logging:EventLog:LogLevel:Default`. Funciona porque es la última registrada con igual especificidad [I]. Un cambio de orden en `Program.cs` o una clave `Default` en la configuración podría reabrir S-05 sin que falle ninguna prueba.
- **Remedio (alrededor de 1 hora).** Una prueba que construya un `HostApplicationBuilder` con un `appsettings` de ejemplo, llame a `ConfigurarRegistro` y compruebe con `ILogger.IsEnabled` sobre el proveedor de EventLog:
  - `GPOS.Api.Endpoints.AuthEndpoints` en Información: **no** habilitado;
  - `GPOS.Api.Servicio`: habilitado;
  - `GPOS.Ncf.Rastro`: habilitado.

## 7. Controles bien implementados

- Falla cerrada con el argumento y sin el Administrador de servicios, sin leer el proceso (`ModoServicioApi.cs:145-146`; prueba `:47`) [V].
- El argumento no actúa como interruptor: la detección basta para comprobar (`:147`; prueba `:68`) [V].
- Rechazo por incoherencia en consola con la cuenta del servicio (`:154-156`; prueba `:76`) [V].
- Identidad antes que privilegios, y el token solo se lee si la identidad es correcta (`:158-161`) [V].
- Causa de las fallas sin el mensaje del sistema (`:166`; prueba `:96`) [V].
- `EscribirRechazo` nunca lanza (`:201-221`; prueba `:153`) [V].
- El 4770 no tumba el servicio (`:243-247`) [V].
- Filtro de Información exacto: evita el prefijo `GPOS.Api.Servicios.*` y `GPOS.Api.ServicioOtro` (`:113-114`; casos en la prueba `:193-194`) [V].
- Un solo cálculo del SID, comparado con valores conocidos de Windows (`TrustedInstaller`) en los tres puntos de entrada [V].
- El agente de impresión delega igual (`src/GPOS.AgenteImpresion/Estacion/IdentidadServicio.cs:42`) [V].

## 8. Remediaciones priorizadas

1. **Antes de la primera instalación fuera del laboratorio:** R-01 (`--servicio` en el MSI y su comprobación en L-2), junto con S-01/S-02 ya pendientes.
2. **En este PR o el siguiente, unas 2,5 horas en total:** R-02 (un solo camino por la reserva), R-06 (prueba de precedencia) y R-03 (marshaling explícito y `lpUserSid`).
3. **Decisión del propietario:** R-05, aceptar o usar un registro propio con `CustomSD` en el MSI. Además, `AuthEndpoints.cs:82`.
4. **Sin acción:** R-04 (el aviso a la salida de error es opcional).

## 9. Recomendación

**Aprobado con observaciones** (recomendación técnica; la firma es del propietario). S-03, S-04, S-05 y S-07 quedan cerrados en el código y no hay hallazgos Críticos, Altos ni Medios. Se puede unir. La condición de instalación fuera del laboratorio sigue vigente: S-01, S-02 y ahora R-01.

---

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\revision-seguridad-n1-endurecimiento-2026-10-21.md`
- Supuestos:
  - Sobre el marco: la precedencia de `LoggerFilterOptions` (la última regla de igual especificidad gana), la captura de `SecurityException` en `WindowsEventLog`, la conversión de `string[]` a `LPWSTR*` con `CharSet.Unicode` y que `GetCommandLineArgs()[1..]` coincide con `args`.
  - Sobre Windows: la ACL por omisión del registro de Aplicación (IU lee, SU escribe) y la conducta de `RegisterEventSource` con un origen no registrado.
  - Se confirman en L-1/L-2. No se compiló ni se ejecutó nada.
- Decisiones candidatas a ADR: Ninguna. El registro propio `GPOS` con `CustomSD` (R-05 b), si se adopta, es una nota de aplicación de ADR-76 para el MSI.
- Entregas a otros agentes:
  - Desarrollador de B: R-02, R-03 y R-06.
  - DevOps/instalador: R-01 (`--servicio` en `ServiceInstall/@Arguments` y en L-2) y R-05 (b) si se decide.
  - Dueño de `AuthEndpoints`: `:82`.
  - A (PR-4): S-06.
- Próximo paso recomendado: unir la rama si B lo decide y agregar `--servicio` en el PR del instalador antes de cualquier instalación fuera del laboratorio.
