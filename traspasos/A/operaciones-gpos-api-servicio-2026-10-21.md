# Operaciones de `GPOS.Api` como servicio de Windows (N-1, PR #127): privilegios, carpetas, eventos, arranque y laboratorio

**Fecha:** 2026-10-21 · **Agente:** devops (equipo A) · **Destino:** B lo lleva a `docs/operaciones/2026-10-21-operaciones-gpos-api-servicio.md` · **Estado del documento:** diseño para decisión (Pendiente de firma donde se indica). Es una recomendación técnica; el paso a producción lo aprueba el propietario.
**Encargo:** `avisos/B-a-A/2026-10-21-encargo-adr92-privilegios-api-y-laboratorio-aplazado.md`, Tarea 2, punto 1. Cumple lo que exige por escrito [ADR-76](../adr/ADR-076.md) punto 2 (cada privilegio se justifica en el documento de operaciones) antes de la primera instalación fuera del laboratorio.
**Forma:** sigue `docs/operaciones/2026-10-19-diseno-instalador-reportes.md` (INS) y el formato de respuesta de devops.

**Método y marcas.** Todo se leyó con `git show` y `git grep` sobre `origin/b/n1-api-modo-servicio` @ `7afa929d` (PR #127), `origin/master`, `origin/feature/modelo-ng` y `origin/a/adr90-rt01-modo-red`, sin cambiar de rama. **No se compiló ni se ejecutó nada** (ni el servicio, ni MSI, ni Chrome, ni `sc`). **[V]** = verificado con cita `archivo:línea` o `archivo` (rama indicada); **[I]** = inferido o conocimiento general de Windows/Chromium, **a confirmar en el laboratorio elevado** (sección 11). El MSI `GPOS.Api.msi` **no existe todavía**: lo que se dice de él es el contrato que debe cumplir.

---

## 0. Resumen ejecutivo

1. Con el código del #127, **`GPOS.Api` como servicio pide un solo privilegio: `SeChangeNotifyPrivilege`**, igual que la estación de impresión y `GPOS.Reportes` (ADR-76, norma por omisión; `ModoServicioApi.cs`, `PrivilegiosDeclarados`) [V].
2. **Se contrastó el plano v2 (sección 3) con el código y el resultado es «sin cambio de lista», pero con una corrección de razonamiento:** el plano dice que no hay lanzamiento de procesos en `GPOS.Api` porque `git grep` no halla `Process.Start`; es literal pero engañoso, porque **`ConvertidorPdf` lanza Chrome o Edge mediante PuppeteerSharp 25.12.0** (`src/GPOS.Api/GPOS.Api.csproj:18`; `src/GPOS.Api/Impresion/ConvertidorPdf.cs:75-79`) [V]. Por eso el PDF es el riesgo que el laboratorio debe cerrar (sección 4). Razonamiento: un navegador hijo hereda el token restringido, un usuario estándar de Windows ejecuta Chrome con el *sandbox* sin `SeAssignPrimaryTokenPrivilege` ni `SeIncreaseQuotaPrivilege`, y la API no necesita más que eso [I].
3. **Lo que sí exige atención y no es un privilegio:** el perfil del navegador y los temporales del RNC se escriben en `Path.GetTempPath()` de la cuenta virtual (`ConvertidorPdf.cs:66`, `RncDgiiEndpoints.cs:40`, `TrabajoRncDgii.cs:156`) [V]. Dónde cae ese `TEMP` y que sea escribible solo por la cuenta se comprueba en el laboratorio [I]. Además, **el perfil temporal no se borra** nunca (`ConvertidorPdf.cs:63-68`): crece una carpeta por cada arranque del navegador [V] (hallazgo Baja, sección 4.4).
4. Identidad y privilegios se comprueban **antes de cualquier otra cosa del arranque** (`Program.cs:30`), con código de salida **1** y el EventId **4767** [V]. En consola (desarrollo, DEMO, pruebas) no se comprueba nada (C-10) [V].
5. **EventId 4767 a 4770** (franja de N-1, de B), origen `GPOS.Api`, registro «Aplicación»; el origen lo declara `GPOS.Api.msi` [V el código; el MSI es contrato].
6. `FijarEscuchaPorOmision` (`http://localhost:5071`) es **transitorio**: lo retira PR-4 de ADR-90. Hasta entonces, el servicio **no puede instalarse con el verbo `red` ya ejecutado** (rechazo 4744); orden en la sección 8.
7. **Laboratorio elevado (16 pruebas, sección 11):** unos 0,5 a 1 día-persona de devops ±50 % [I], USD 0, **más** una condición: ejecutarlo en `LFMB` o donde B y el propietario fijen (la PC de A no se usa para VM, encargo de B del 2026-10-21).
8. **Estado:** documento **Listo para decisión** (para la revisión del auditor-seguridad y la firma de la lista); la instalación **No lista** (no hay `GPOS.Api.msi` y falta el laboratorio) (sección 12).

---

## 1. Entornos y estrategia de despliegue

| Entorno | Cómo corre la API | Comprobación de identidad y privilegios | Registro de eventos |
|---|---|---|---|
| Desarrollo, DEMO, pruebas | Consola (`GPOS.Api.exe`), cuenta del usuario | **No** (`ModoServicioApi.ComprobarArranque` devuelve null si `EsServicio` es falso) [V] | No (no se agrega el proveedor de eventos) [V] |
| Servidor del cliente | Servicio `GPOS.Api`, cuenta virtual `NT SERVICE\GPOS.Api`, cadena de instalación de INS 1.1 con `GPOS.Api.msi` como **primer MSI** (blueprint v2, 1.4.1) | **Sí**, antes de configuración, red, anillo y datos | Sí, origen `GPOS.Api`, registro «Aplicación» |

- **Mismo binario** en consola y como servicio: `AddWindowsService` solo se activa si `WindowsServiceHelpers.IsWindowsService()` (`ModoServicioApi.cs`, `EsServicio`, `Registrar`) [V]. No se agrega `AddSystemd` (ADR-129: Linux aún no) [V].
- **Raíz de contenido:** como servicio el directorio de trabajo es `System32`; `Opciones` fija `ContentRootPath = AppContext.BaseDirectory` [V]. Sin esto, `appsettings.json` no se lee.
- **Reversión del despliegue:** el MSI es transaccional; el *bundle* lo revierte (INS 3.3 y 5.3). El servicio no deja estado propio salvo lo que ya escriben el anillo, la licencia y la base (sección 10).

## 2. Cuenta, identidad y SID

| Aspecto | Valor | Evidencia |
|---|---|---|
| Servicio | `GPOS.Api` (nombre único en `ServiciosWindows.Api`) | `src/GPOS.Comun/Servicios/ServiciosWindows.cs:14` [V] |
| Cuenta | **Cuenta virtual `NT SERVICE\GPOS.Api`**, sin contraseña, sin SID de servicio restringido | ADR-76 punto 5; ADR-82 punto 2 [V] |
| SID esperado | `S-1-5-80-546908902-3265840057-98699379-1016526221-3413751906` (S-1-5-80 + SHA-1 de `GPOS.API` en UTF-16LE, 5 enteros de 32 bits) | Calculado con el algoritmo de `IdentidadProceso.SidDeServicio` (`src/GPOS.Comun/Servicios/IdentidadProceso.cs`); el mismo método reproduce el SID de la estación `S-1-5-80-1907694547-…-2092870145` que ya figura en `instalador/AgenteImpresion/Package.wxs` (`origin/feature/modelo-ng`) [V el método; el SID de la API es cálculo propio, se confirma con `sc showsid GPOS.Api` en el laboratorio] |
| Comprobación | `Comprobar(actual, privilegios)`: primero identidad, luego privilegios | `ModoServicioApi.cs`, `Comprobar`; `ModoServicioApiTests.La_identidad_se_comprueba_antes_que_los_privilegios` [V] |

**Consecuencia operativa:** el servicio **no arranca con otra cuenta** (por ejemplo, si alguien lo reconfigura a `LocalSystem` o a una cuenta de dominio): `ARRANQUE_IDENTIDAD`. Es intencional (ADR-75/ADR-76).

## 3. Lista de privilegios del token (la parte que exige ADR-76, punto 2)

**Lista declarada y única:** `["SeChangeNotifyPrivilege"]` (`ModoServicioApi.PrivilegiosDeclarados`) [V]. Es lo que declaran la estación (`instalador/AgenteImpresion/Package.wxs`, `RequiredPrivilege`) y `GPOS.Reportes` (ADR-76, nota de aplicación del 2026-10-08) [V].

**Por qué la lista importa:** una cuenta virtual pertenece a `SERVICE`, a la que la directiva por omisión da `SeImpersonatePrivilege` y `SeCreateGlobalPrivilege`; sin `RequiredPrivilege`, el servicio los recibe y una intrusión en la API tendría la vía conocida a SYSTEM (ADR-76, contexto) [V]. Con `RequiredPrivilege`, Windows quita del token todo lo no listado [V, comentario de la estación en `Package.wxs`].

### 3.1 Privilegio pedido

| Privilegio | Justificación | Qué pasa sin él |
|---|---|---|
| `SeChangeNotifyPrivilege` (omitir la comprobación de recorrido) | Atravesar carpetas sin permiso de lectura en cada nivel de la ruta. Los servicios leen `C:\Program Files\GPOS NG\Api\…`, `%ProgramData%\GPOS NG\Licencia`, el anillo y `config\` cuyas DACL no dan lectura a cada carpeta intermedia (la raíz da a Authenticated Users solo `0x1200a9`; el anillo y la licencia son más cerrados que la raíz, ADR-77 puntos 2 y 4). Es la norma por omisión de PA-76-1 | Fallos de acceso al abrir rutas profundas aunque la hoja sea legible. Windows lo da por omisión a todos; `RequiredPrivilege` lo conserva solo si se lista |

### 3.2 Privilegios que NO se piden, uno por uno

| Privilegio | ¿Por qué no? | Evidencia |
|---|---|---|
| `SeImpersonatePrivilege` | La única suplantación es la canalización de introspección: `RunAsClient` solo para leer el SID del cliente con `WindowsIdentity.GetCurrent(TokenAccessLevels.Query)`. En nivel de identificación no exige el privilegio (es lo que ya documenta la estación). No hay `AddNegotiate`, `RunImpersonated` ni `LogonUser` en la API. **Prohibido por ADR-76, punto 2** | `src/GPOS.Comun/Introspeccion/ServidorIntrospeccion.cs:196-209`; `src/GPOS.Api/Seguridad/ValidadorTokenPrincipal.cs:87,123` [V]; que el nivel de identificación baste es **[I]** y es la prueba L-6 |
| `SeAssignPrimaryTokenPrivilege`, `SeIncreaseQuotaPrivilege` | La API no crea procesos con otro token. **El navegador del PDF** sí es un proceso hijo, pero se crea con `CreateProcess` y el **mismo** token; el *sandbox* de Chromium crea hijos con un token **restringido derivado** del propio, que no requiere el privilegio. Un usuario estándar de Windows (que no los tiene) ejecuta Chrome y Edge con *sandbox* | `ConvertidorPdf.cs:75-79` [V]; resto **[I]**, prueba L-9. **Prohibido por ADR-76** |
| `SeCreateGlobalPrivilege` | Sin objetos `Global\` ni `MemoryMappedFile`/`Mutex`/`Semaphore` con nombre en `GPOS.Api`, `GPOS.Core`, `GPOS.Comun`, `GPOS.Criptografia`. Las canalizaciones con nombre no lo exigen. ADR-76 descarta declararlo «por si acaso». **Posible excepción: el navegador** (Chromium usa objetos con nombre en su espacio de sesión, no `Global\`) | `git grep` [V]; el navegador **[I]**, prueba L-9 |
| `SeTcbPrivilege`, `SeDebugPrivilege`, `SeBackupPrivilege`, `SeRestorePrivilege` | Nada que depurar, leer por encima de las ACL ni restaurar. Los respaldos de SQL los hace el motor, no la API. **Prohibidos por ADR-76** | ADR-76 punto 2 [V] |
| `SeTakeOwnershipPrivilege`, `SeSecurityPrivilege` | Solo fija como dueño su **propia** cuenta (canalización) y crea las carpetas del anillo y de la licencia con DACL de SYSTEM, Administradores y su identidad; no lee ni escribe SACL | `ServidorIntrospeccion.cs:120`; `CarpetaAnillo.cs:64-71`; `AlmacenLicenciaDisco.cs:113-122` [V] |
| `SeAuditPrivilege` | Escribe en «Aplicación», no en «Seguridad» | `ModoServicioApi.cs`, `ConfigurarRegistro` [V] |
| `SeIncreaseWorkingSetPrivilege`, `SeTimeZonePrivilege`, `SeSystemtimePrivilege` | Sin uso. (`SeIncreaseWorkingSetPrivilege` lo tiene un usuario estándar y es el candidato **de menor riesgo** si el laboratorio demostrara que el navegador lo exige; sección 4.3) | `git grep` [V] |

**Lo que no necesita privilegio** (para que el laboratorio no lo confunda): abrir la llave privada del certificado TLS (la da la ACL de la llave que concede el verbo `tls`); escuchar con Kestrel en un puerto (Windows no tiene puertos privilegiados y Kestrel no usa HTTP.sys ni `urlacl`) [I]; autenticación integrada a SQL Server; escribir eventos en «Aplicación» con un origen ya registrado; DPAPI de máquina [I].

## 4. El PDF: la API lanza Chrome o Edge (lo que el plano v2 no contemplaba)

### 4.1 Qué hace el código [V]

- `ConvertidorPdf.NavegadorAsync` busca el navegador en `Impresion:Navegador` (si está configurada) o en cuatro rutas de `Program Files` (Chrome y Edge, 64 y 32 bits) y tres rutas de Linux (`ConvertidorPdf.cs:13-20`, `:56-62`).
- Lanza **un navegador por proceso de la API y lo reutiliza**: `Puppeteer.LaunchAsync` con `Headless = true`, `UserDataDir` propio, `Timeout = 60 s` y los argumentos `--disable-gpu --no-first-run --disable-extensions --disable-dev-shm-usage` (`:72-77`). **No** agrega `--no-sandbox` [V].
- El perfil es `%TEMP%\gpos-pdf-navegador\<8 hex>` del proceso (`:66`), creado antes del intento y **no se borra** ni al terminar ni al fallar un candidato.
- Al detener la API, `DisposeAsync` cierra el navegador (`:105-109`); si la API muere por `Kill` o falla, los procesos hijos podrían quedar [I].
- Escritores en `TEMP` del servicio, además del PDF: la descarga del padrón RNC (`RncDgiiEndpoints.cs:40`; `TrabajoRncDgii.cs:156`) [V].
- Paquete: `PuppeteerSharp 25.12.0` (`GPOS.Api.csproj:18`) [V]. **El navegador no lo instala el MSI** (ni se descarga: `ExecutablePath` siempre se pasa) [V]; debe existir en el servidor o configurarse en `Impresion:Navegador` (clave que ADR-126 renombra a `GPOS:Impresion:Navegador`, E-02 de `docs/propuestas/2026-10-11-valores-de-terceros-configurables.md`) [V].

### 4.2 Razonamiento sobre privilegios, carpetas y ACL [I salvo lo indicado]

| Tema | Razonamiento | Riesgo | Prueba |
|---|---|---|---|
| Privilegios del hijo | El navegador hereda un token con **el mismo conjunto** de privilegios (solo `SeChangeNotifyPrivilege`); sus procesos internos (GPU, red, *renderer*) usan tokens restringidos derivados. Chrome corre sin privilegios para un usuario estándar | Bajo | L-9, L-10 |
| *Sandbox* de Chromium | Se mantiene **activo** (no se agrega `--no-sandbox`). **Regla:** si en el laboratorio el navegador no arranca por el *sandbox*, **no** se resuelve con `--no-sandbox` ni con más privilegios sin pasar por el auditor-seguridad: se documenta la causa y se decide por separado | Medio si falla | L-9 |
| Sesión 0 | Un servicio corre en la sesión 0, sin escritorio interactivo. `--headless` no necesita escritorio; no se requiere `SeCreateGlobalPrivilege` ni «interactuar con el escritorio» | Bajo | L-9 |
| Lectura del programa | `C:\Program Files\…\chrome.exe` o `msedge.exe` es legible y ejecutable por Usuarios autenticados (herencia de `Program Files`) | Bajo | L-9 |
| Carpeta de trabajo (`TEMP`) | La cuenta virtual usa el `TEMP` de su entorno de servicio. **No se sabe dónde cae** (perfil de servicio o `C:\Windows\Temp`); la API lo necesita **escribible**. **Se recomienda no depender de ese `TEMP`:** ver 4.3 | Medio (si no es escribible, el PDF falla y el resto de la API sigue) | L-11 |
| Escritura bajo `%ProgramData%\GPOS NG` | El navegador **no** debe escribir ahí: su `UserDataDir` va en `TEMP`. No hay DACL de `%ProgramData%` que ampliar | Bajo | L-12 |
| Salida de red | El HTML de las plantillas personalizadas puede referir imágenes o fuentes externas, y el navegador las pediría con la identidad del servicio. Es riesgo de salida de red, no de privilegio. **Para el auditor:** si la API no debe salir a Internet salvo a hosts concretos, la regla de salida por servicio (N-2 de INS) debe cubrir `chrome.exe`/`msedge.exe` | Medio | L-13; auditor |
| Crash y huérfanos | Si la API muere, el hijo puede quedar vivo con el perfil abierto. Mitigación posible: *Job Object* con `KILL_ON_JOB_CLOSE` (cambio de código, no de privilegios) | Bajo | L-14 |

### 4.3 Decisión recomendada y escalera si el laboratorio demuestra que falta algo

1. **Lista firmada y desplegada:** `SeChangeNotifyPrivilege` solamente. No se agrega nada «por si acaso» (ADR-76).
2. **Si L-9 o L-10 fallan por un privilegio**, y solo con evidencia (evento, `ProcMon` o código de error), se prueba **en este orden**, uno por vez, y cada uno se justifica por escrito y lo revisa el auditor: (a) `SeIncreaseWorkingSetPrivilege` (lo tiene un usuario estándar; riesgo mínimo); (b) `SeCreateGlobalPrivilege`. **No se admiten** `SeImpersonatePrivilege`, `SeAssignPrimaryTokenPrivilege`, `SeTcbPrivilege`, `SeDebugPrivilege`, `SeBackupPrivilege` ni `SeRestorePrivilege` (ADR-76, punto 2). Cada privilegio agregado se refleja en **tres sitios a la vez**: `PrivilegiosDeclarados`, `RequiredPrivilege` de `GPOS.Api.msi` y la prueba de `sc qprivs`.
3. **Alternativa estructural (si el navegador resultara incompatible con un servicio sin privilegios):** sacar el PDF a un proceso hijo propio con su identidad, o a `GPOS.Reportes` (ADR-109 le asigna «todo render de formatos»; el PDF de formatos personalizados en la API principal sería, entonces, una inconsistencia a revisar con el arquitecto). **Descartada hoy:** mover el PDF cambia el contrato de las API; no hay evidencia de que haga falta.
4. **Opción para el `TEMP`:** dar al convertidor un directorio de trabajo propio y controlado, `%ProgramData%\GPOS NG\Api\tmp\` (carpeta del componente de la API, DACL protegida con `NT SERVICE\GPOS.Api` Modificar), en lugar de `Path.GetTempPath()`. Es cambio de código (A/B), no se hace aquí; lo recomiendo si L-11 muestra un `TEMP` poco claro. Se justifica por ADR-77 (toda carpeta con DACL explícita, sin depender de un `TEMP` compartido).

### 4.4 Hallazgo de operación (Baja)

**El perfil temporal del navegador nunca se borra** (`ConvertidorPdf.cs:63-68`, sin `Directory.Delete` en ninguna rama [V]). Cada arranque del servicio (y cada reintento tras un navegador que muere) deja una carpeta con el perfil de Chromium (decenas de MB [I]). Con recuperación automática y reinicios, crece. **Recomendación (A/B, código):** borrar el perfil en `DisposeAsync` y al arrancar la API (limpiar `gpos-pdf-navegador\*` antiguos). Mientras tanto, la prueba L-11 mide el crecimiento.

## 5. Carpetas y ACL (ADR-77)

La raíz `%ProgramData%\GPOS NG` y `config\` las declara cada MSI con el fragmento compartido de O-3 (GUID canónico, `Permanent="yes"`; blueprint v2, sección 2). **`GPOS.Api.msi` es el primer MSI de la cadena y su acción previa (O-1) crea la raíz con el SDDL del vector v2 si falta** (blueprint v2, 1.4.1). Sin cambios de esa lógica aquí.

| Carpeta | La declara | DACL (SDDL protegida) | Quién escribe | Verificación |
|---|---|---|---|---|
| `%ProgramFiles%\GPOS NG\Api\` | `GPOS.Api.msi` (herencia de `Program Files`) | Solo lectura para la cuenta virtual | Nadie en tiempo de ejecución | `icacls` (L-7) |
| `%ProgramData%\GPOS NG\` (raíz) | Fragmento O-3 + acción previa O-1 | `O:SYG:SYD:PAI(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICI;0x1200a9;;;AU)` | SYSTEM y Administradores | P-O1-4 |
| `%ProgramData%\GPOS NG\config\` | Fragmento O-3 | **Mismo SDDL que la raíz**, sin escritor de servicio (`ArchivoInstalacion.cs`) | Administradores (el instalador) | `icacls` |
| `%ProgramData%\GPOS NG\Api\` (carpeta del componente, registros si los hubiera) | `GPOS.Api.msi`, con su fila en `GposCarpetaPrevia` y `Servicio = GPOS.Api` | `O:SYG:SYD:PAI(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICI;0x1301bf;;;S-1-5-80-546908902-3265840057-98699379-1016526221-3413751906)` (control total a SY y BA; Modificar a la cuenta virtual; Usuarios nada) | `NT SERVICE\GPOS.Api` | `icacls` y P-O1-5 (el SID calculado coincide con `sc showsid`) |
| `%ProgramData%\GPOS NG\Licencia\` (y `Licencia\Entrada`) | **La API en tiempo de ejecución**, no el MSI (ADR-77, punto 5); `AlmacenLicenciaDisco.cs:66-68,113-122` | SYSTEM, Administradores y la identidad del proceso | La API | Comprobación al arrancar (ADR-77, punto 4) |
| Carpeta del anillo de Data Protection | **La API en tiempo de ejecución** (`CarpetaAnillo.Crear`; contrato nuevo del blueprint v2, 1.4.2: sin padres con DACL heredada) | Escritura SY, BA y la identidad; **lectura solo SY, BA y la identidad** (no hereda la lectura de Usuarios autenticados) | La API | `N-14` de ADR-77, dentro de H-17 v2 |
| `TEMP` de la cuenta virtual | El sistema (sección 4) | Por determinar [I] | La API y el navegador | L-11 |

**Reglas que se prueban en el laboratorio:** ninguna ACL da escritura a Usuarios o Authenticated Users sobre la raíz ni sobre `Api\`; el anillo no es legible por Usuarios autenticados; la API **no** crea la raíz si falta en Estricto (blueprint 1.4.2) [I, depende de la construcción de `CarpetaAnillo.Crear` v2 por A].

## 6. Origen y EventId (franja 4767 a 4770, de N-1)

**Origen:** `GPOS.Api`, registro «Aplicación». El origen **lo declara `GPOS.Api.msi`** (`util:EventSource Name="GPOS.Api" Log="Application"`, con `EventMessageFile` de .NET, de modo que el Visor muestre el texto y no «no se encuentra la descripción») [I; contrato para devops de B]. La API **no crea el origen** al arrancar (la cuenta virtual no es administradora) [I]: **si el origen no existe, no hay eventos** (prueba L-5). Código: `registro.AddEventLog(o => { o.SourceName = ServiciosWindows.Api; o.LogName = "Application"; })` [V].

| EventId | Nombre | Nivel | Cuándo | Datos (sin secretos) |
|---|---|---|---|---|
| **4767** | `ArranqueRechazado` | Crítico | `ARRANQUE_IDENTIDAD` o `ARRANQUE_PRIVILEGIOS`; sale con código 1 | SID real, SID esperado o la lista de sobrantes |
| **4768** | `ServicioIniciado` | Información | `ApplicationStarted` | Texto fijo |
| **4769** | `ServicioDetenido` | Información | `ApplicationStopped` | Texto fijo |
| **4770** | `PrivilegiosPresentes` | Información | Al iniciar, con la lista real del token, ordenada | Nombres de privilegios (sirve de cruce con `sc qprivs`) |

[V] `ModoServicioApi.cs` (`EventoArranqueRechazado` … `EventoPrivilegiosPresentes`, `CicloDeVidaServicio`). Categoría `GPOS.Api.Servicio`; filtros del registro de Aplicación: categorías `GPOS*` y `Microsoft.Hosting.Lifetime` en Información o más. **El resto de los registros de la API en Información no llega al Visor** (solo `GPOS*` y el ciclo de vida) [V]: es adecuado para no saturar, pero significa que **errores de categorías ajenas a `GPOS*` y los de nivel Advertencia de bibliotecas no aparecen allí** [V el filtro; consecuencia I] (ver 9).
- **Coexistencia de franjas** (blueprint v2, sección 6): 4743-4752 ADR-90; 4753-4766 acción previa y actualizador; **4767-4770 N-1 (B)**; 4771-4779 `GPOS.Instalacion` de B; 4780-4789 `tls`. Antes de unir cualquier PR con EventId, `git grep` en todas las ramas de `origin` (regla 7 de B).

## 7. Arranque, recuperación, parada y código de salida

### 7.1 Orden de arranque (`Program.cs`) [V]

1. `WebApplication.CreateBuilder(ModoServicioApi.Opciones(args, EsServicio))` (línea 28).
2. **`ModoServicioApi.ComprobarArranque()` → si hay rechazo, `Rechazar(motivo)`** (líneas 29-30): identidad y privilegios, **antes** de la configuración, del modo de red, del anillo y de los datos.
3. `Registrar` (servicio, registro de eventos, tiempo de parada, `CicloDeVidaServicio`) y `FijarEscuchaPorOmision` (líneas 31-32).
4. Archivo de instalación `GPOS.Api.json`, sitio, datos, etc.

**Orden respecto de `ArranqueRed.Exigir`** (el plano de A y el encargo hablan de «ExigirArranque»; el método real es `ArranqueRed.Exigir`, `origin/a/adr90-rt01-modo-red:src/GPOS.Comun/Red/ArranqueRed.cs:146` [V]; **aún no está en la rama del #127**). Como la comprobación de identidad y privilegios va en la línea 30 y la red se evalúa después, **un servicio con identidad o privilegios equivocados se rechaza con 4767 antes que con un error de red (4744)**. Cuando PR-2/PR-4 de ADR-90 añadan `ArranqueRed.Exigir`, deben insertarse **después** de `ComprobarArranque`; la prueba de orden está en `ApiModoServicioArquitecturaTests` (nombre de la rama; lo confirma el auditor).

### 7.2 Código de salida y recuperación

| Situación | Salida | Efecto en el Administrador de servicios |
|---|---|---|
| Rechazo de identidad o privilegios | `Environment.Exit(1)` tras escribir 4767 (`Rechazar`) [V] | El proceso termina **antes de registrar el servicio** ante el Administrador de servicios (el anfitrión aún no se construyó) [V orden; efecto I]: el inicio falla (error 1053 o 7009/7034 del Administrador) y se aplican las acciones de recuperación |
| Parada normal | Código 0; 4769; `ShutdownTimeout = 30 s` (`TiempoDeParada`) [V] | `Stop` limpio |
| Excepción no controlada o caída | Código distinto de cero (el del .NET) [I] | Recuperación |

**Recuperación a declarar en `GPOS.Api.msi`** (acordada con B, RB Q-4 de 1.2, igual que la estación): reiniciar a los **60 s** en el primer, segundo y tercer fallo; contador que se reinicia a **1 día**; `FailureActionsWhen="failedToStopOrReturnedError"` (para que un código de salida distinto de cero también cuente) [recuperación de la estación: `Package.wxs`, `util:ServiceConfig ... RestartServiceDelayInSeconds="60" ResetPeriodInDays="1"` V; el atributo `FailureActionsWhen` en WiX 5 es **[I]** y se comprueba al compilar]. **Consecuencia:** un error de identidad o de privilegios es **permanente**, no transitorio: el servicio reintenta 3 veces y queda detenido; cada intento deja un 4767 (3 críticos en unos 3 minutos). No debe reiniciarse indefinidamente. Si en el laboratorio el servicio no queda reintentando, se ajusta (prueba L-4).

**Inicio automático.** `Start="auto"` como la estación; **dependencia de SQL Server**: no se declara `DependOnService` porque el nombre del servicio de SQL depende de la instancia (`MSSQLSERVER`, `MSSQL$SQLEXPRESS`). Si la API falla al conectar al arrancar, la recuperación de 60 s la levanta [I; confirmar con `Inicializacion.cs`]. Alternativa: inicio automático retrasado (`delayed-auto`), más simple y suficiente si SQL tarda [I]; se mide en L-15.

## 8. Relación con la escucha por omisión transitoria `http://localhost:5071`

| Elemento | Comportamiento [V] |
|---|---|
| `EscuchaPorOmision = "http://localhost:5071"` | Es el puerto que espera `GPOS.Web/appsettings.json` (`ModoServicioApi.cs`) |
| `FijarEscuchaPorOmision` | **Solo como servicio**, y solo si la configuración no trae `urls` (ni la variable `ASPNETCORE_URLS`, que .NET lleva a la configuración) ni `Kestrel:Endpoints`; entonces `UseUrls(EscuchaPorOmision)`. En consola no cambia nada |
| Marca de transitorio | Comentario `TRANSITORIO` en `ModoServicioApi.cs`: **lo retira PR-4 de ADR-90**, junto con su línea de `Program.cs` y la de `ApiModoServicioArquitecturaTests.LineasServicio` |
| Por qué no puede quedarse | `UseUrls` escribe `urls` en la configuración; con el **modo de red** presente en el registro (`HKLM\SOFTWARE\GPOS NG\Servidor`, que escribe el verbo `red`) `ArranqueRed.Evaluar` rechaza `urls` con el evento **4744**. Desde RT-05 la escucha la arma el código |

**Efectos operativos y orden que se debe respetar:**
1. **Hasta que PR-4 se una:** la API como servicio escucha en **loopback** (`localhost:5071`, solo HTTP, sin TLS) y **no hay regla de entrada de firewall que abrir**. Sirve para que la Web del mismo equipo funcione. **No sirve para puestos en otros equipos** ni para TLS.
2. **No debe ejecutarse el verbo `red` y arrancar el servicio** mientras el binario del servicio aún traiga `FijarEscuchaPorOmision`: el arranque se rechazaría con 4744. La cadena de INS pone `red` antes de los MSI (blueprint v2, 1.4.1), de modo que **la cadena completa de INS 1.1 no es instalable hasta PR-4** [V orden; efecto V por el código de `ArranqueRed`; confirmar en L-3]. En el laboratorio, hasta PR-4, se instala el MSI **sin** el verbo `red`.
3. **Después de PR-4:** la escucha la define el verbo `red`/`tls`; `Api:Url`/`AllowedHosts` (F-6) y el certificado TLS (`LocalMachine\My`, ACL de la llave concedida a la cuenta virtual) dejan de ser opcionales. Cualquier `urls` o `Kestrel:Endpoints` del instalador se rechaza.
4. **Instalación a la inversa:** si el instalador (o el técnico) ya definió `urls` o `Kestrel:Endpoints` en `config\GPOS.Api.json`, **`FijarEscuchaPorOmision` no actúa**; en el modo de red se rechazaría. La prueba L-3 cubre las dos combinaciones.

## 9. Monitoreo, logging y alertas

- **Alertas mínimas (Visor de eventos o la herramienta de monitoreo del cliente):** **4767** (crítico: el servicio no arranca por identidad o privilegios) y la **ausencia de 4768 en 5 minutos tras un arranque**; eventos del Administrador de servicios para `GPOS.Api` (7031, 7034, 7024) [conocimiento general de Windows]; y el estado del servicio detenido. Se alinea con las alertas mínimas de B-8.
- **Salud HTTP:** `/api/salud` [V en el plano v2 y en INS 4.2]; la verificación `comprobar-servidor` la consulta tras instalar.
- **Registro sin datos sensibles:** el filtro deja pasar solo categorías `GPOS*` y `Microsoft.Hosting.Lifetime`; 4770 imprime nombres de privilegios y 4767 los SID, **ninguno es secreto** [V]. Prueba B-6 de que no hay cadenas de conexión ni credenciales en el registro (INS 4.3).
- **Brecha a cerrar:** el Visor solo muestra `GPOS*` y el ciclo de vida; un error de Kestrel o de EF fuera de esas categorías no llega al Visor. **Para diagnosticar incidentes**, B decide si agrega un filtro de nivel Advertencia/Error global para el proveedor de eventos o un registro en archivo en `%ProgramData%\GPOS NG\Api\` (con la DACL de la sección 5). Recomiendo lo primero (cero archivos nuevos): una línea de filtro [I; B decide].
- **Costo:** USD 0 de infraestructura; el almacenamiento del registro de eventos es el del sistema (por omisión 20 MB con sobrescritura [I]).

## 10. Respaldo, migraciones y reversión

- **Esta pieza no migra ni respalda:** el esquema lo hace `GPOS.Migracion` (paso `esquema`), con respaldo previo en actualizaciones (INS 5.2). `GPOS.Api.msi` solo cambia archivos, servicio y ACL.
- **Estado propio de la API que sobrevive a una reinstalación** (no debe borrarse al desinstalar): anillo de Data Protection, `Licencia\`, `config\GPOS.Api.json`, la raíz (`Permanent="yes"`). **Desinstalar la API no borra datos** (INS 6) [V el diseño].
- **Rollback:** el MSI anterior reinstala el binario y la configuración del servicio (incluida la lista de privilegios); la comprobación `sc qprivs` se repite tras el rollback (L-8). Un rollback a una versión **sin** N-1 (sin `RequiredPrivilege`) dejaría el servicio sin lista: **no se admite** (no hay instalador de la API anterior a N-1) [I].
- **Respaldo de configuración:** `config\GPOS.Api.json` no lleva secretos (solo claves permitidas, ADR-126); se incluye en el respaldo de la raíz de datos.

## 11. Qué se prueba en el laboratorio elevado (marcado **[I]** hasta que se ejecute)

Requiere una máquina Windows aislada con elevación y el MSI de la API. **No se ejecuta en la PC del propietario ni en la de A** (incidente 2026-10-08; encargo de B del 2026-10-21). Responsable: devops de B con QA de A; el auditor revisa el resultado. Todo **[I]** hasta su ejecución.

| # | Prueba | Resultado esperado |
|---|---|---|
| L-1 | `sc qc GPOS.Api` y `sc showsid GPOS.Api` | Cuenta `NT SERVICE\GPOS.Api`; SID = el de la sección 2 |
| L-2 | `sc qprivs GPOS.Api` tras instalar | **Exactamente** `SeChangeNotifyPrivilege`. Un resultado vacío es un **fallo** (en `sc`, vacío significa «sin restricción», ADR-76) |
| L-3 | Instalar sin y con el verbo `red` (modo de red en el registro); con y sin `urls` en la configuración | Sin `red`: escucha en `localhost:5071`; con `red` y la escucha por omisión: 4744 (confirma el orden de la sección 8) |
| L-4 | Cambiar la cuenta a `LocalSystem` e iniciar; reponer; forzar un privilegio sobrante en el token | `ARRANQUE_IDENTIDAD` / `ARRANQUE_PRIVILEGIOS`, EventId 4767, salida 1; recuperación 60 s x3 y servicio detenido; sin escucha abierta |
| L-5 | Sin origen `GPOS.Api` en el registro | Qué ocurre: el servicio **no** debe caerse por no poder escribir el evento; se registra la diferencia. Con el origen: se ven 4768 y 4770 con texto legible |
| L-6 | Introspección desde `GPOS.Reportes` (`NT SERVICE\GPOS.Reportes`) hacia la API, **sin** `SeImpersonatePrivilege` | La API lee el SID del cliente con el token en nivel de identificación; si no, es la prueba que obliga a justificar por escrito el privilegio (hoy prohibido por ADR-76) |
| L-7 | `icacls` en `Api\`, raíz, `config\`, `Licencia\` y el anillo | Coincide con la sección 5; Usuarios sin escritura; el anillo no es legible por Usuarios autenticados |
| L-8 | Reparación y reversión del MSI; repetir L-2 | `sc qprivs` conserva la lista exacta |
| L-9 | **Generar un PDF** (formato personalizado) con la API como servicio, con **Chrome** y con **Edge**, y con `Impresion:Navegador` configurada | PDF válido; con `--sandbox` activo; en el registro, cero errores de privilegio; el navegador visible en `tasklist` bajo `NT SERVICE\GPOS.Api` |
| L-10 | `whoami /priv` en el proceso del navegador (con Process Explorer o `Process Hacker` solo en el laboratorio) y en la API | Mismo conjunto que el servicio; el hijo no tiene más; evento 4770 coincide con `sc qprivs` |
| L-11 | Ubicar el `TEMP` del servicio (Process Explorer, pestaña de entorno); generar 20 PDF y reiniciar el servicio 3 veces | `TEMP` escribible solo por la cuenta; **medir cuántas carpetas `gpos-pdf-navegador\*` quedan** (hallazgo 4.4) y su tamaño |
| L-12 | Con el monitor de procesos (ProcMon, filtro por el proceso) durante L-9 | El navegador **no** escribe bajo `%ProgramData%\GPOS NG`; sin accesos denegados a rutas que importen |
| L-13 | Plantilla con una imagen externa | Saber si hay salida de red y si la regla de salida por servicio la cubre (para el auditor) |
| L-14 | `Stop-Service` y `Kill` de la API con el navegador activo | Si quedan procesos del navegador vivos; tiempo de parada < 30 s |
| L-15 | Reinicio del servidor con SQL de arranque lento; inicio `auto` frente a `delayed-auto` | La API termina arriba sin intervención (por la recuperación o el retraso) |
| L-16 | Cadena completa de INS con `GPOS.Api.msi` primero, tras PR-4 | El servicio escucha lo que fija `red`/`tls`; `Api:Url`/`AllowedHosts` válidos; sin `urls` en la configuración |

**Criterio de salida del laboratorio:** L-2, L-4, L-6, L-9 y L-10 en verde **sin agregar privilegios**; si alguna falla por un privilegio, se aplica la escalera de 4.3 con aprobación del auditor.

## 12. Estado

- **Documento (diseño de operaciones y lista de privilegios): Listo para decisión.** Pendiente de firma del propietario: la **lista de privilegios** (`SeChangeNotifyPrivilege` única) y el tratamiento del PDF (sección 4.3, sin privilegios adicionales hasta demostrarse).
- **Instalación de `GPOS.Api` fuera del laboratorio: No lista.** Motivos: (1) **no existe `GPOS.Api.msi`** (ni `util:EventSource`, ni `ServiceConfig`, ni recuperación; blueprint v2 y F-1 pendientes); (2) **el laboratorio elevado no se ha ejecutado** (sección 11); (3) la cadena completa de INS no es instalable hasta PR-4 por `FijarEscuchaPorOmision` (sección 8); (4) el hallazgo del perfil temporal (4.4) y la ubicación del `TEMP` quedan abiertos.
- **No bloquea unir el #127** (no hay instalador de la API aún), como dice el encargo de B.

## 13. Correcciones al plano v2 del instalador (`traspasos/A/blueprint-instalador-o1-o3-n10-2026-10-20.md`, sección 3)

| Punto del plano | Resultado del contraste con el código | Acción |
|---|---|---|
| Lista = solo `SeChangeNotifyPrivilege` | **Se mantiene**; ni Chrome/Edge ni otra cosa del código exigen más, según el razonamiento de 4.2, **pendiente de L-9 y L-10** | Sin cambio de lista |
| Fila de `SeAssignPrimaryToken…`: «no hay `Process.Start`/`ProcessStartInfo` en esos proyectos» | Cierto literalmente, pero **la API sí lanza un proceso por PuppeteerSharp** (`ConvertidorPdf.cs`) | **Corregido** en el plano (ver su nota de v2.1): la justificación pasa a «el hijo hereda el token; no necesita el privilegio» |
| Lo que «no necesita privilegio» | Faltaba el navegador y su `TEMP` | Añadir (hecho en el plano) |
| Medición de devops (3.2) | No incluía generar un PDF | Incluir L-9 a L-14 |

---

## Resumen (8 líneas)

1. `GPOS.Api` como servicio declara **un solo privilegio, `SeChangeNotifyPrivilege`** (igual que la estación y Reportes); cada privilegio omitido se justifica en la sección 3.2 con su cita.
2. **Corrección al plano v2:** `ConvertidorPdf` sí lanza Chrome o Edge (PuppeteerSharp 25.12.0); la lista no cambia, pero el razonamiento sí: el hijo hereda el token, y se exige **prueba en laboratorio (L-9, L-10) antes de firmar**; escalera de privilegios y alternativas en 4.3.
3. Hallazgo Bajo: el perfil temporal del navegador **no se borra** y el `TEMP` de la cuenta virtual no está definido; se recomienda un directorio propio `Api\tmp\` (cambio de código, de A o B).
4. Cuenta virtual `NT SERVICE\GPOS.Api`, SID esperado `S-1-5-80-546908902-3265840057-98699379-1016526221-3413751906` (cálculo propio, se confirma con `sc showsid`); ACL de carpetas por ADR-77 en la sección 5.
5. Origen `GPOS.Api` (lo declara el MSI, que aún no existe) y EventId 4767 a 4770; alertas mínimas: 4767 y ausencia de 4768.
6. Arranque: identidad y privilegios van antes que todo (`Program.cs:30`), con salida 1; recuperación 60 s x3, y un fallo de identidad es permanente (3 intentos y detenido). El orden respecto de `ArranqueRed.Exigir` (el «ExigirArranque» del encargo) queda fijado, pero ese método aún no está en el #127.
7. `FijarEscuchaPorOmision` (`localhost:5071`) es transitoria y PR-4 la retira; **hasta entonces la cadena de INS con el verbo `red` previo no es instalable** (rechazo 4744).
8. Laboratorio elevado: 16 pruebas (sección 11), 0,5 a 1 día-persona, USD 0; estado: documento **Listo para decisión**, instalación **No lista**.

### Cierre
- Estado: Completado
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\operaciones-gpos-api-servicio-2026-10-21.md`; nota v2.1 en `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\blueprint-instalador-o1-o3-n10-2026-10-20.md` (sección 3)
- Supuestos: el SID de la API es un cálculo propio con el algoritmo de `IdentidadProceso` (reproduce el SID de la estación); que un navegador hijo no necesita privilegios adicionales, el `TEMP` de la cuenta virtual, el efecto de salir antes del registro del servicio, `FailureActionsWhen` en WiX 5 y el comportamiento sin origen de eventos son inferidos y se cierran en el laboratorio; «ExigirArranque» se interpreta como `ArranqueRed.Exigir`
- Decisiones candidatas a ADR: precisión de ADR-76 (lista de `GPOS.Api` y regla de la escalera de privilegios para procesos hijos como el navegador del PDF); precisión de ADR-77 (directorio de trabajo propio para el navegador en lugar de `TEMP`, si el laboratorio lo exige)
- Entregas a otros agentes: desarrollador de B → borrar el perfil temporal del navegador, evaluar `Api\tmp\` y el filtro de eventos globales (9); devops de B → `GPOS.Api.msi` con `RequiredPrivilege`, `util:EventSource`, recuperación y las pruebas L-1 a L-16; auditor-seguridad de A → revisar la lista, el PDF y la salida de red (L-13); arquitecto-maestro → firma de la lista y registro de la nota de ADR-76
- Próximo paso recomendado: que B lleve este documento a `docs/operaciones/` con el #127 y programe L-9/L-10 en el primer laboratorio elevado, antes de la firma de la lista.
