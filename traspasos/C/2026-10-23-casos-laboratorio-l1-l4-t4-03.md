```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (tarea 5 de B-a-C/2026-10-23-tareas-nuevas-para-c-4: casos de laboratorio L-1 a L-4 de T4-03)
Prioridad: Media
Repositorio y rama: GPOS-NG `origin/feature/modelo-ng` @ `9a439234` (solo lectura, `git show`); área común `traspasos/C/`
Estado: Abierto (casos redactados; nada ejecutado)
```

# Casos de laboratorio L-1 a L-4 de T4-03: Chromium del render bajo `NT SERVICE\GPOS.Reportes`

**Qué es.** Casos para `VM-SRV` de `LFMB` (VirtualBox; la VM ya tiene `Preparar-Vm.ps1` aplicado y el punto de control `base`; los opera B). Cubren lo que el #170 declaró sin verificar y lo que dejaron pendiente la revisión de seguridad de A (S170-10, "no se probó Edge, el camino positivo de `PrepararCarpeta` en Release ni la cuenta `NT SERVICE\GPOS.Reportes`") y mi revisión adversarial del 2026-10-24 (H170-04, "qué no verifiqué"). **No se instaló ni se ejecutó nada** (OSHIN-LEGION no tiene VirtualBox y la regla del 2026-10-08 impide tocar servicios en las PC del propietario).

**Marcas.** [V] verificado leyendo un archivo (ruta y línea en `origin/feature/modelo-ng` @ `9a439234`); [I] inferido o conocimiento general de Windows, Chromium o PuppeteerSharp, por confirmar en la VM; [?] depende de algo que aún no existe.

**Estados de un caso en la VM.** `Cumple` · `No cumple` · `No se pudo` (la precondición no existía) · `Bloqueado` (no ejecutable hoy). `No se pudo` y `Bloqueado` **nunca** cuentan como `Cumple`. Regla nueva de este documento: **un caso sin su control no puede dar `Cumple`** (un control es la misma medición con el mecanismo apagado; demuestra que el instrumento ve la diferencia).

## 0. Resumen para decidir

1. **Cuatro casos, trece subcasos** (L-1a a L-1e, L-2a a L-2c, L-3a a L-3c, L-4a y L-4b) y sus controles. Se repiten con **Chrome y con Edge** (Edge es lo que el #170 no probó). Las dos tareas "extra" de A (directivas de grupo y la cuenta del servicio) están dentro de L-2c y L-1.
2. **El camino de `PrepararCarpeta` en Release** no tenía número L en el blueprint; lo pongo como L-1a/L-1b porque exige la misma cuenta y la misma instalación de laboratorio.
3. **Hoy no se puede ejecutar nada sin tres piezas que no existen** (sección 3): (a) un **disparador de render** (nadie llama a `/interno/render/*`: `ClienteRender` es el #210 y T4-02b se construye desde el 16-nov); (b) un **MSI o paso de instalación de `GPOS.Reportes`** (el laboratorio crea el servicio y las carpetas a mano, como lo haría el MSI, y por eso **no sustituye** las comprobaciones R1 a R10 del paquete); (c) **la regla del cortafuegos de la capa 3**, que nadie crea todavía (la crea el caso L-2 con el mismo comando que usará el script del DEMO).
4. **Hallazgo previo a la VM (D-5):** el blueprint (R-T403-04) dice que si la canalización de CDP no funciona en Windows "se acepta el puerto aleatorio"; el código **no tiene ese respaldo**: `Pipe = true` es incondicional (`ConvertidorPdf.cs:398` [V]). Si L-3a falla, no hay render personalizado, no "un riesgo aceptado".
5. **Duración [I, ±50 %]:** sesión S4 en `VM-SRV` sola, unas 6 h (preparación 1 h, L-1 2,5 h con los dos navegadores, L-3 1 h, L-4 1,5 h); sesión S5 con `VM-SRV` y `VM-PUESTO` a la vez, unas 3 h (L-2). Escribir el disparador de render (PRE-5) cuesta unos 1,0 dp [I] y es la ruta crítica.
6. **Recomendación de orden si solo cabe una ventana:** L-1c (sandbox), L-3a (canalización), L-1a (carpeta), L-2a (regla), L-1b, L-4, el resto.

## 1. Fuentes y estado del código [V]

- Blueprint `traspasos/B/2026-10-22-informes/t4-03-blueprint.md` (§4.3 la regla; §5 el perfil; §9 la lista L-1 a L-4; R-T403-03, R-T403-04, R-T403-06).
- Revisión de seguridad de A del #170 (`traspasos/A/revision-seguridad-pr170-t4-03a-2026-10-22.md`: S170-01, S170-03, S170-05, S170-08, S170-10 y la entrega "L-1 a L-4 con Edge y con directivas de grupo") y mi revisión (`traspasos/C/2026-10-24-revision-adversarial-170.md`: H170-04, H170-09, "qué no verifiqué").
- Mis casos previos de `VM-SRV` (`2026-10-22-casos-laboratorio-chromium-y-comprobaciones-paquete.md`, bloque CH; `2026-10-23-casos-laboratorio-t1b-y-revision-173.md`: reglas, funciones de apoyo, plantilla de evidencia y severidades) y `tests/laboratorio-adr090/revision-evidencia.md` (`git show origin/feature/modelo-ng:…`).
- Código en `origin/feature/modelo-ng` @ `9a439234` (T4-03a y T4-03b unidos con el #170):
  - `src/GPOS.Reportes.Api/Program.cs:60-66` (`ComprobarCarpeta = false` solo con compilación Debug y entorno de desarrollo), `:83-100` (en Release: `temporales.Preparar(RaizMaquina, propia)` y `convertidor.PrepararCarpeta(RaizMaquina, propia)`; `propia` solo si el token del proceso es el SID de `NT SERVICE\GPOS.Reportes`).
  - `src/GPOS.Reportes.Api/Impresion/ConvertidorPdf.cs:70-77` (las cuatro rutas conocidas: Chrome x64, Chrome x86, Edge x86, Edge x64, **en ese orden**; con Chrome instalado Edge no se usa salvo que se configure `GPOS:Reportes:Render:Navegador`), `:110-115` (`PrepararCarpeta` → `PrepararPrivada`), `:360-361` (candidatos), `:396-406` (`Headless`, `UserDataDir`, `Pipe = true`, argumentos y entorno filtrado), `:45` y `:49` (eventos 5119 y 5156; **5118 sigue reservado** a la comprobación de la regla del cortafuegos, no implementada).
  - `src/GPOS.Reportes.Api/Impresion/PoliticaRedNavegador.cs` (`Argumentos`, `Prohibidos`, `ProblemaLineaComandos`, `EntornoPermitido`).
  - `src/GPOS.Reportes/Exportacion/ComprobacionCarpetas.cs:33-58` (códigos de rechazo y `SddlPrivada`), `:222-262` (`PrepararPrivada`).
  - `src/GPOS.Reportes.Api/Seguridad/VerificadorIntrospeccion.cs` (Release exige `CuentaServidor` = SID `S-1-5-80-*`; la canalización de introspección debe ser de esa cuenta).
  - `tests/GPOS.Tests/Impresion/MedicionRender.cs` (la meta de L-4: el p95 por la canalización no pasa del directo en más de 50 ms; montón administrado ≤ 768 MB).

## 2. Reglas heredadas

Las de mis casos de T1-b (sección 1) y de `revision-evidencia.md`, sin cambios; en breve:
1. Solo en `VM-SRV` (y `VM-PUESTO` para L-2) de `LFMB`, desde `base`. Nunca en la PC del propietario ni en OSHIN-LEGION. Lo opera B; yo reviso la evidencia ya redactada.
2. Un punto de control por bloque (`LAB-T403-<ID>`), restaurar `base` al terminar. Si algo falla **no se corrige a mano para que pase**: se anota (ruta, código, SID, texto del evento) y se restaura.
3. Una sola corrida a la vez en `LFMB` y ninguna suite compilando durante la ventana (las mediciones de L-4 se vuelven inestables).
4. Cada instalación o prueba de MSI con `/l*v`. Ningún secreto en la evidencia: nada de `reg query`/`reg export` de `HKLM\SYSTEM\CurrentControlSet\Services\GPOS.Reportes`, ni `Get-ItemProperty` de esa clave sin `-Name`; los nombres de valores solo con `(Get-Item …).GetValueNames()`. En este laboratorio el entorno del servicio **no lleva ningún secreto** (ver PRE-4), pero la regla se mantiene para no crear el hábito.
5. Los "datos" de los renders son los de los modelos dorados (`ModelosDorados`), nunca datos de un cliente.

**Funciones de apoyo** (PowerShell 5.1 elevado; se suman a las de mi documento de T1-b):

```powershell
$E = 'C:\GPOS-LAB\evidencia\T403'; New-Item -ItemType Directory -Force $E | Out-Null
function Navegadores { Get-CimInstance Win32_Process -Filter "Name='chrome.exe' OR Name='msedge.exe'" |
  Select-Object ProcessId,ParentProcessId,Name,CommandLine }     # solo para ver; la línea no trae entorno
function Dueno($p) { (Invoke-CimMethod -InputObject (Get-CimInstance Win32_Process -Filter "ProcessId=$p") -MethodName GetOwner) | Select-Object Domain,User }
function Escuchas { Get-NetTCPConnection -State Listen | Select-Object LocalAddress,LocalPort,OwningProcess | Sort-Object LocalPort }
```

## 3. Precondiciones (no son casos; B las fija antes de la sesión)

| ID | Qué | Estado |
|---|---|---|
| PRE-1 | `VM-SRV` desde `base` con `Preparar-Vm.ps1` aplicado (`-Comprobar` todo en `OK`), Windows Server 2025, FIPS no, **sin SQL arrancado** (L-4 mide memoria); `gpos-lab-usuario` (estándar) creada como en T1-b. Para L-2, `VM-PUESTO` encendida (192.168.50.20) y la memoria libre de `LFMB` confirmada por `Preparar-Anfitrion.ps1` (mi regla de "una VM a la vez" no aplica a L-2) | Existe [V: aviso de B] |
| PRE-2 | **Publicación Release de `GPOS.Reportes.Api`** (`dotnet publish -c Release`, autocontenida o con el runtime de ASP.NET Core 10 en la VM), con su SHA-256 anotado. **Debe ser Release**: el primer paso de L-1b comprueba que lo sea (con `ComprobarCarpeta=false` el servicio se niega a arrancar; en Debug, no) | B la entrega junto a la sesión |
| PRE-3 | **Navegadores**: Chrome (MSI empresarial, copiado a `C:\GPOS-LAB\msi` junto con su SHA-256; la VM no tiene Internet tras `Cerrar-Preparacion.ps1`) y Edge (el de la imagen). Anotar `(Get-Item <exe>).VersionInfo.ProductVersion` de cada uno (B cita Chrome 156; mi equipo tiene 155.0.8059.85). **Un navegador a la vez**: para Edge se desinstala Chrome o se fija `GPOS__Reportes__Render__Navegador=<ruta de msedge.exe>` en el entorno del servicio (sin secretos). Que Server 2025 traiga Edge y qué versión: [I], pregunta Q-5 de mi entrega del 22-oct sin respuesta (D-2) | Pendiente |
| PRE-4 | **Servicio de laboratorio `GPOS.Reportes`** creado a mano como lo dejaría el MSI de reportes [V: diseño del instalador, R1/R2, según mi bloque PK]: `sc create GPOS.Reportes binPath= "\"C:\Program Files\GPOS NG\Reportes\GPOS.Reportes.Api.exe\"" obj= "NT SERVICE\GPOS.Reportes" start= demand`; `sc privs GPOS.Reportes SeChangeNotifyPrivilege`; `sc sidtype GPOS.Reportes unrestricted`. Entorno del servicio (por `Set-ItemProperty … Environment` como lista de cadenas, **solo nombres no secretos**): `GPOS__Introspeccion__CuentaServidor=NT SERVICE\GPOS.Api` (nombre, no secreto; en Release exige una identidad `S-1-5-80-*`), `GPOS__Reportes__Exportacion__ComprobarCarpeta=true`, `Urls=http://127.0.0.1:5073`. Sin SQL: el servicio arranca sin contexto de lectura (503 en las consultas) [I: por el comentario de `Program.cs:45` y `ServiciosLectura.cs`; lo confirma el primer arranque, y si no arranca es un `No se pudo` con la causa] | B lo escribe; yo reviso |
| PRE-4b | **Carpetas** como las dejaría el MSI (ADR-77, vector v2/v3) para que `PrepararCarpeta` encuentre su entorno: `%ProgramData%\GPOS NG` con `O:SYG:SYD:PAI(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICI;0x1200a9;;;AU)` (`ComprobacionCarpetas.SddlRaiz` [V]) y `%ProgramData%\GPOS NG\Reportes` **protegida**, sin la ACE de AU, con SYSTEM y Administradores en control total y el SID del servicio con `0x1301bf` (blueprint §5 [V]). El dueño de ambas debe ser Administradores o SYSTEM (`Evaluar` rechaza otro dueño [V]); crear con la sesión elevada del Administrador integrado basta [I]. **La DACL exacta de `Reportes` la fija el MSI, que no existe**: la tomo del blueprint y de la nota 5 del diseño del instalador; D-6 pide que devops la confirme | Pendiente de confirmar |
| PRE-5 | **Disparador de render** (ver D-1). Hoy **nadie llama** a `/interno/render/*`: las rutas solo existen por la canalización `GPOS.Reportes.Exportacion` (ACL de la cuenta de la principal) y exigen un token validado por introspección contra la canalización `GPOS.Api.Introspeccion`. Dos formas, a elegir por B: **R-A (real, recomendada):** una tarea programada que corre PowerShell como `NT SERVICE\GPOS.Api` [I: las cuentas virtuales de servicio se pueden usar como principal de tarea, como se hace con TrustedInstaller; confirmar] y hace de principal de mentira: crea la canalización de introspección (mensaje = entero de 4 bytes little-endian con el largo + JSON; `ProtocoloIntrospeccion.cs` [V]) y manda el POST HTTP/1.1 a mano por la canalización del render. Así el servicio corre **exactamente** el código y el arranque de producción. **R-B (arnés):** una aplicación .NET de un solo archivo (`dotnet run archivo.cs`, .NET 10 [I]) que aloja `ServicioRender` como `MedicionRender` (con verificador falso), pero **no** ejercita el `Program.cs` real ni `PrepararCarpeta` de Release salvo que la copie. R-A cuesta ≈ 1,0 dp [I]; R-B ≈ 0,5 dp [I] y L-1a/L-1b quedan fuera. Los casos están escritos con tres operaciones, `RENDER(formato, papel)`, `RENDER×N` y `ARRANCAR/DETENER`, que cualquiera de las dos formas implementa | **No existe**; ruta crítica |
| PRE-6 | **Herramientas de evidencia**: (a) `auditpol /set /subcategory:"Filtering Platform Connection" /success:enable /failure:enable` (genera el evento 5157 de conexión bloqueada, con aplicación, PID y destino; es un cambio de estado de la VM: se restaura con el punto de control); (b) un **oyente TCP** de PowerShell que registra hora y dirección remota de cada conexión (en `VM-PUESTO` y en `VM-SRV`); (c) un **lector de token** `Leer-Token.ps1 -Pid <n>` que imprima, por proceso, el SID del usuario, el nivel de integridad, `IsRestricted`, si es AppContainer y si está en un Job (por P/Invoke de `OpenProcessToken`/`GetTokenInformation`/`IsProcessInJob`). **No lo escribo aquí sin poderlo probar**; alternativa manual: Process Explorer o System Informer, pestaña Security (no consta en la imagen, D-2). Cuesta ≈ 0,2 dp | Por escribir |

## 4. Orden de sesiones y puntos de control

| Sesión | Contenido, en este orden | Tiempo [I] |
|---|---|---|
| **S4** (`VM-SRV` sola) | PRE-1 a PRE-6 (60 min) → punto de control `LAB-T403-LISTO` → L-1a, L-1b (45) → L-1c, L-1d, L-1e con Chrome (60) → `LAB-T403-CHROME` → restaurar `LAB-T403-LISTO`, cambiar a Edge → L-1c a L-1e con Edge (45) → L-3a a L-3c (60, ambos navegadores) → L-4a y L-4b (90) | ≈ 6 h |
| **S5** (`VM-SRV` + `VM-PUESTO`) | L-2a con Chrome y con Edge (90) → L-2b (30) → `LAB-T403-REGLA` → L-2c, directivas de grupo, **al final** porque deja la VM sucia (60) | ≈ 3 h |

L-1b y L-3c dejan carpetas y procesos manipulados: cada uno desde su propio punto de control (`LAB-T403-L1B`, `LAB-T403-L3C`).

## 5. L-1. El sandbox de Chromium está activo bajo la cuenta del servicio, y la carpeta de perfiles cumple ADR-77 en Release

**Origen:** blueprint §9 (L-1), ADR-110 cl. 7 y A-6 (nunca `--no-sandbox`), R-T4-07 (mi bloque CH: CH-01 a CH-06), S170-01, S170-05, H170-04. **Por qué importa:** el `NT SERVICE\GPOS.Reportes` tiene un solo privilegio (`SeChangeNotifyPrivilege`); no se sabe si el *sandbox* de Chromium arranca con tan poco [I]. El código **no** tiene una vía de escape (`--no-sandbox` está en `Prohibidos`, y se comprueba al lanzar, `ConvertidorPdf.cs:406-430`): si no arranca, los formatos personalizados quedan en 503, no con un riesgo aceptado.

### L-1a. Camino positivo de `PrepararCarpeta` en Release, con la cuenta real

- **Precondición:** PRE-1 a PRE-4b; la carpeta `Reportes` existe y **`render` no existe**; servicio detenido. `Get-Acl` de `GPOS NG` y `Reportes` guardadas.
- **Pasos:**
  1. `$desde = Get-Date; sc.exe start GPOS.Reportes` (el servicio arranca con el `Program.cs` de producción: `propia` se fija porque el token del proceso es el SID declarado, `Program.cs:90-94` [V]).
  2. Esperar 15 s. `sc.exe query GPOS.Reportes`; `Get-WinEvent` de `Application` desde `$desde` (proveedor de la API de reportes) → `eventos.txt`.
  3. `Get-Acl "$env:ProgramData\GPOS NG\Reportes\render" | Format-List Owner,Sddl` y `icacls "…\render"` → `acl-render.txt`.
  4. `(Invoke-WebRequest http://127.0.0.1:5073/api/salud -UseBasicParsing).StatusCode` y el cuerpo (sin la causa; `ServiciosLectura.cs:60` [V]) → `salud.txt`.
  5. Listar `render` y `Reportes`: sin perfiles todavía (el navegador se lanza con el primer render o con el precalentamiento: si hay `perfil-*`, anotar su ACL, que **hereda** de `render`).
- **Esperado [I hasta ejecutar]:** el servicio queda `RUNNING`; **sin** evento 5119; `render` existe; su DACL es la de `SddlPrivada(servicio)` (`D:PAI(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICI;0x1301bf;;;<SID del servicio>)(A;OICI;RC;;;OW)` [V: `ComprobacionCarpetas.cs:53-54`]), **protegida**, sin ACE para `AU`, `BU` ni `WD`; el dueño es el servicio o Administradores; `/api/salud` no dice 503 `NAVEGADOR_NO_DISPONIBLE`.
- **Qué prueba y qué no:** es el camino que la revisión (H170-04, mutación M8b) no podía ejercitar sin una raíz de SYSTEM. Si `render` aparece con la DACL **heredada** de `Reportes` (con `AU` de lectura) el código estaría llamando a `PrepararTemporales` en vez de `PrepararPrivada`: **Alta**, la misma regresión que M8b deja sin detectar.
- **Rechazo (No cumple):** evento 5119 con el servicio sano; `render` con una ACE de `AU`/`BU`/`WD` o con la DACL sin proteger; el servicio no arranca por la carpeta.
- **Marca:** [I]. **Duración:** 20 min.

### L-1b. Negativos de la carpeta en Release (cada uno desde `LAB-T403-L1B`)

| ID | Preparación (antes de arrancar el servicio) | Esperado | Rechazo |
|---|---|---|---|
| L-1b-N0 | Publicación Release con `GPOS__Reportes__Exportacion__ComprobarCarpeta=false` en el entorno | El servicio **no arranca**; excepción "solo se admite en desarrollo (ADR-77, P-77-4)" en el registro de eventos o la consola (`Program.cs:65-66` [V]). Comprueba también que PRE-2 es Release | Arranca (es una compilación Debug: **PRE-2 inválida**, repetir con la correcta) |
| L-1b-N1 | Crear `render` **antes**, por herencia (sin `SetAccessRuleProtection`), de modo que herede la lectura de `AU` de la raíz | 5119 `LECTOR_NO_PERMITIDO` con la ruta y el SID de `AU` (`S-1-5-11`); `/api/salud` y los formatos personalizados en 503 `NAVEGADOR_NO_DISPONIBLE`; los estándar (QuestPDF) siguen respondiendo; **la carpeta no se corrige sola** (S170-01) | Se habilita; o el servicio la reescribe |
| L-1b-N2 | Borrar `Reportes` | 5119 `FALTA_INSTALACION` con la ruta de `Reportes`; el servicio **no la crea** (la crea el MSI) | La crea |
| L-1b-N3 | Reemplazar `render` por una unión (`mklink /J`) hacia una carpeta fuera de `GPOS NG` | 5119 `PUNTO_DE_REANALISIS`; nada se escribe en el destino de la unión | Sigue la unión o escribe en el destino |
| L-1b-N4 | Poner a `BUILTIN\Users` permiso de escritura en `Reportes` | 5119 `ESCRITOR_NO_PERMITIDO` con el SID de `BU` | Se habilita |
| L-1b-N5 | Dueño de `Reportes` = una cuenta ajena (`gpos-lab-usuario`) | 5119 `DUENO_NO_PERMITIDO` | Se habilita |

- **Evidencia:** `eventos.txt` (código, ruta, SID), `acl-*.txt` antes y después, `salud.txt`, y un `RENDER` estándar que responde y uno personalizado que da 503. **Rechazo común:** el 5119 no sale (ADR-77 sin vigilancia), o el texto lleva datos que no sean ruta y SID (S-05).
- **Duración:** 40 min en total. **Marca:** [I]; los códigos son los de `ComprobacionCarpetas.cs:33-48` [V].

### L-1c. El sandbox está activo en cada proceso del navegador (Chrome y Edge)

- **Objetivo:** demostrar que los procesos de renderizado no corren con el token completo del servicio y que no hay `--no-sandbox`.
- **Precondición:** L-1a en verde; un solo navegador instalado o configurado (PRE-3); `LAB-T403-LISTO`. Primer `RENDER` (o el precalentamiento) hecho.
- **Pasos:**
  1. `RENDER(ticket 80 mm, Razor base)` y, mientras el navegador vive, `Navegadores | Tee-Object "$E\L1c-procesos.txt"`.
  2. Para cada proceso: `Dueno <Pid>` (todos deben ser `NT SERVICE\GPOS.Reportes`) y `Leer-Token.ps1 -Pid <Pid>` (PRE-6c) → `L1c-tokens.txt`.
  3. Línea de comandos del proceso principal (`--type` ausente): ninguno de `Prohibidos` (`--no-sandbox`, `--disable-web-security`, `--remote-debugging-port`…), sí `--remote-debugging-pipe`, `--proxy-server=http://127.0.0.1:9`, `--user-data-dir=…\render\perfil-xxxxxxxx`, `--headless…` [V: `PoliticaRedNavegador.cs`].
  4. Buscar en el registro de eventos de `Application` y en el de la API errores del tipo "sandbox", "Failed to … broker", "Access is denied" del navegador (`LaunchAsync` con `ProcessException`, `ConvertidorPdf.cs:430`).
  5. **Control (obligatorio):** con el servicio detenido, desde una tarea programada como la cuenta (o el mismo mecanismo de PRE-5) lanzar el navegador **con** `--no-sandbox --headless` y mismo perfil de prueba, y repetir pasos 1 y 2 sobre sus procesos.
  6. Repetir pasos 1 a 4 con 4 renders simultáneos y con un `RENDER` de una plantilla que incluye una imagen `data:image/png` y un `<img src="http://192.168.50.20:8099/x.png">` (la intercepción lo aborta; el oyente debe quedar con 0 conexiones y queda un 5117).
- **Esperado [I]:**
  - El render responde (200 con un `%PDF`), la línea de comandos cumple la comprobación de `ConvertidorPdf.cs` (no hay 5156).
  - Los procesos `--type=renderer` y `--type=gpu-process` corren con un **nivel de integridad menor** que el proceso principal y con un token restringido o AppContainer, dentro de un Job; el proceso principal conserva el token del servicio. Los valores exactos (Untrusted/Low, AppContainer del servicio de red) **los fija la VM**: se anotan, no se afirman.
  - **Control:** con `--no-sandbox` los procesos hijos tienen **el mismo** token e integridad que el principal. Si en el control no se ve diferencia con el caso real, **el lector de token no discrimina y L-1c no puede dar `Cumple`**.
- **Rechazo:**
  - **Crítica:** `--no-sandbox` presente en cualquier proceso; renderizadores con el mismo token e integridad que el principal en el caso real; un proceso que corra con una cuenta distinta de la prevista.
  - **Alta:** el navegador no arranca por el *sandbox* o los renderizadores se caen (503/500, 5156, `ProcessException`); entonces **B no puede ofrecer formatos personalizados bajo la cuenta virtual** y decide con el propietario y A (Q-2 de mi entrega del 22-oct; el diseño firmado dice nunca `--no-sandbox`). No se "arregla" con un argumento en la VM.
- **Evidencia:** `L1c-procesos.txt`, `L1c-tokens.txt`, `L1c-control-tokens.txt`, los eventos, versión del navegador y del sistema, SHA-256 de PRE-2.
- **Duración:** 30 min por navegador. **Marca:** [I]. Cubre S170-05 solo en lo observable: el riesgo residual de que el navegador comparte el token del servicio (escape del *sandbox*) **no se prueba** y sigue como decisión de arquitectura de A.

### L-1d. Huellas fuera de `render` (Chrome y Edge)

- **Objetivo:** que el navegador no cree perfiles ni temporales fuera de la carpeta comprobada (S152-07, S170-07; `LOCALAPPDATA`, `APPDATA` y `USERPROFILE` sí están en `EntornoPermitido` [V: `PoliticaRedNavegador.cs:140` aprox.]).
- **Pasos:** antes de L-1c, listar con `Get-ChildItem -Recurse -Force -ErrorAction SilentlyContinue` y guardar nombre, tamaño y fecha de: `C:\Windows\ServiceProfiles`, `C:\Windows\Temp`, `C:\Users`, `%ProgramData%` (todo), `C:\Windows\System32\config\systemprofile` (solo nombres). Tras 20 renders, el mismo listado y la diferencia (`Compare-Object`). Anotar los valores que ve la cuenta para `USERPROFILE`, `LOCALAPPDATA` y `TEMP` (con el lanzador de PRE-5, un `cmd /c set` filtrado a esas tres variables).
- **Esperado [I]:** todo lo nuevo cuelga de `render\perfil-*`; el `TEMP` del navegador es `perfil-*\tmp` (`ConvertidorPdf.cs:402-404` [V]).
- **Rechazo:** carpetas nuevas del navegador fuera de `render` (**Media**; **Alta** si guardan volcados de *crashpad* o documentos en una carpeta legible por usuarios); un `tmp` que no está dentro del perfil.
- **Duración:** 20 min por navegador.

### L-1e. Render de extremo a extremo en sesión 0, y limpieza

- **Pasos:** sin sesión interactiva (cerrar la sesión de consola después de arrancar el servicio): 20 `RENDER` de ticket 80 mm y 20 de factura Carta con el formato base personalizado; luego `sc stop` y reinicio.
- **Esperado [I]:** 40/40 PDF válidos (cabecera `%PDF`, ≥ 1 página, tamaño razonable, sin error); ninguna ventana en la consola de la VM (captura de pantalla de la consola, sin datos); al detener el servicio se borra el `perfil-*` en uso; al arrancar de nuevo se borran los huérfanos (`perfil-*` con ese prefijo y sin unión, `ConvertidorPdf.cs:120-132` según A [V]).
- **Rechazo:** un render en error; un `perfil-*` que persiste tras detener y volver a arrancar; el precalentamiento deja un navegador vivo sin servicio.
- **Duración:** 20 min por navegador.

## 6. L-2. La regla de salida de la capa 3 corta lo que la capa 1 y la capa 2 no verían, y no afecta a nadie más

**Origen:** blueprint §4.3 y §9 (L-2), R-T403-03, S170-03 (directivas de grupo), entrega de A "L-1 a L-4 con Edge y con directivas de grupo". **Por qué importa:** la regla es la **única** defensa si una directiva del navegador anula el proxy (capa 2) y la sugerencia de conexión escapa a la capa 0; pero Windows filtra por usuario y programa, y no se sabe si los procesos hijos del navegador (servicio de red, token restringido o AppContainer) cumplen la condición de usuario local [I].

**Montaje común.** `VM-PUESTO` (192.168.50.20) con un **oyente TCP** en el 8099 (L-2a, L-2b) y otro en el 8100 que hace de proxy de mentira (L-2c), registrando hora y dirección remota; en `VM-PUESTO` hay que **abrir la entrada** de esos puertos (`New-NetFirewallRule -Direction Inbound -LocalPort 8099,8100 -Protocol TCP -Action Allow`; `Preparar-Vm.ps1` no toca el cortafuegos [V: mi lista "fuera de este guion"]). En `VM-SRV`, `auditpol` activo (PRE-6a). La regla la crea el caso, con el comando del blueprint §4.3 [V el texto; I que los parámetros existan en `NetSecurity` de Server 2025]:

```powershell
$sid = (sc.exe showsid GPOS.Reportes | Select-String 'SID:').ToString().Split(':',2)[1].Trim()   # no es secreto
foreach($p in $rutasConocidas){   # las cuatro de ConvertidorPdf.RutasConocidas()
  New-NetFirewallRule -DisplayName "GPOS NG Reportes - Navegador sin red ($(Split-Path (Split-Path $p -Parent) -Leaf))" `
    -Group 'GPOS NG Reportes' -Direction Outbound -Action Block -Program $p -Profile Any -Protocol Any `
    -LocalUser "D:(A;;CC;;;$sid)"
}
```

### L-2a. Matriz de la regla con el navegador sin las capas 1 y 2

- **Objetivo:** con el navegador lanzado **sin proxy ni intercepción** (el navegador crudo, que es lo que quedaría si las capas 1 y 2 fallan), ¿la regla corta solo a la cuenta del servicio?
- **Cómo se lanza:** `chrome.exe`/`msedge.exe --headless --no-first-run --user-data-dir=<carpeta de prueba> --dump-dom "data:text/html,<img src=http://192.168.50.20:8099/s.png>"`, una vez con **cada cuenta**: (S) `NT SERVICE\GPOS.Reportes` mediante el lanzador de PRE-5 (tarea programada como la cuenta [I]; alternativa: servicio de un solo uso cuyo `binPath` es un `cmd /c` con un plazo menor a 30 s) y (U) `gpos-lab-usuario` con `runas`. No se usa la compilación con las capas apagadas del blueprint: el navegador crudo es equivalente para esta pregunta y no exige código nuevo [I].
- **Matriz (12 filas por navegador, 24 en total):**

| Fila | Cuenta | Regla | Programa | Esperado en el oyente de `VM-PUESTO` | Esperado en `VM-SRV` (5157) |
|---|---|---|---|---|---|
| 1 | S | sin regla | el navegador | **1 o más conexiones** (control: demuestra que el montaje llega) | ninguno |
| 2 | S | con la regla (usuario local) | el navegador | **0 conexiones** | 5157 de bloqueo con `chrome.exe`/`msedge.exe` (o el proceso del servicio de red) como aplicación |
| 3 | U | con la regla | el navegador | **1 o más conexiones** (la regla no toca al navegador de las personas) | ninguno |
| 4 | S | con la regla | `powershell.exe` hace `Test-NetConnection 192.168.50.20 -Port 8099` | **conexión** (el proceso .NET y SQL del servicio no se ven afectados; el programa no está en la regla) | ninguno |
| 5 | S | con la regla y el navegador distinto (Chrome si la regla es de Edge) | el otro navegador | **conexión** (la regla es por programa) | ninguno |
| 6 | S | con la regla, pero con el navegador en **otra ruta** (copiado a `C:\GPOS-LAB\x\chrome.exe`) | copia | **conexión**: documenta el hueco de S152-10 (ruta configurable, la regla no la cubre) | ninguno |

- **Rechazo:** fila 2 con conexiones (**Alta**: la capa 3 no cubre al navegador del servicio; pasa a L-2b); fila 3 sin conexiones (**Alta**: la regla toca a las personas); fila 4 sin conexión (**Alta**: corta al servicio); fila 1 sin conexión (el montaje no discrimina: **no se puede concluir**, no es un `Cumple`).
- **Evidencia:** `Get-NetFirewallRule -Group 'GPOS NG Reportes' | Format-List` y `Get-NetFirewallRule -Group … | Get-NetFirewallSecurityFilter` y `Get-NetFirewallApplicationFilter` (muestran `LocalUser`), el registro del oyente por fila, los 5157 exportados (`wevtutil qe Security /q:"*[System[(EventID=5157)]]"`) con aplicación, PID y destino, y la versión del navegador.
- **Duración:** 75 min con los dos navegadores. **Marca:** [I].

### L-2b. Procesos hijos con token restringido o AppContainer (R-T403-03)

- **Objetivo:** responder qué proceso del navegador abre la conexión y si la condición de usuario local lo alcanza.
- **Pasos:** repetir la fila 2 de L-2a y, durante la ejecución, correlacionar con `Get-NetTCPConnection -RemoteAddress 192.168.50.20` y con `Navegadores` el PID y el `--type` del proceso que intenta conectar (el 5157 da el PID). Si en L-2a la fila 2 **dejó pasar** conexiones: reemplazar la regla por la de condición de **servicio** (`-Service GPOS.Reportes`, alternativa del blueprint) y repetir las filas 1 a 3.
- **Esperado [I]:** la conexión la intenta el servicio de red del navegador (`--type=utility`) con el token del servicio; la regla de usuario local la alcanza. Si no, cae la alternativa por servicio.
- **Decide:** si la condición de usuario falla y la de servicio funciona, el blueprint ya dice que se cambia la regla (se anota en el informe; es de B/devops). Si **ninguna** corta, la capa 3 no sirve contra el navegador y el diseño de la defensa en profundidad queda en las capas 0 a 2 (**Media**, informar a A).
- **Duración:** 30 min. **Marca:** [I].

### L-2c. Directivas del navegador que anulan la capa 2 (S170-03)

- **Objetivo:** ver con el navegador real qué hace una directiva de proxy y si la comprobación de la línea de comandos (S170-08) la detecta. Resultado esperado de partida: **no la detecta** (A lo marcó [I]); este caso lo confirma y mide la distancia hasta la capa 3.
- **Precondición:** `LAB-T403-REGLA` (la regla ya creada). `VM-SRV` **no está en un dominio**: Chrome y Edge pueden tratar de otra forma las directivas de una máquina sin dominio ni MDM (Edge/Chrome marcan como "no administrado" y algunas directivas "sensibles" solo se aplican en equipos administrados) [I]; el caso se anota con esa salvedad y, si no hay un controlador de dominio de prueba (no lo hay en el diseño de ADR-90), la variante con GPO real queda `No se pudo`.
- **Pasos (Chrome y Edge, una directiva a la vez; la clave se borra entre pasos):**
  1. Sin directiva, navegador lanzado **con los 15 argumentos de `PoliticaRedNavegador.Argumentos`** (capa 2 sola, sin intercepción, ejecutado por el lanzador de PRE-5 como la cuenta) y la página `data:text/html,<img src=http://192.168.50.20:8099/s.png>`: **control** (0 conexiones al 8099 y al 8100).
  2. Con `HKLM\SOFTWARE\Policies\Google\Chrome` o `…\Microsoft\Edge` → `ProxyMode=fixed_servers`, `ProxyServer=192.168.50.20:8100` (cadenas), mismos argumentos y misma página, **sin la regla** (`Disable-NetFirewallRule -Group 'GPOS NG Reportes'`).
  3. Igual que el paso 2 **con la regla activa**.
  4. Con la directiva del paso 2, un `RENDER` completo con las cuatro capas (la página con una imagen externa y un `<link rel=preconnect>`): el PDF sale, el oyente del 8100 no recibe nada.
  5. Con la directiva puesta, `Get-CimInstance Win32_Process` del navegador del `RENDER` (los argumentos siguen siendo los de la capa 2) y `/api/salud`.
- **Esperado [I]:** paso 1, 0 conexiones; paso 2, **llega una conexión al proxy de mentira (8100)**: la directiva anuló `--proxy-server` (S170-03 confirmado); paso 3, 0 conexiones (la capa 3 corta la salida aunque la directiva anule la capa 2); paso 4, nada llega (la capa 0 quita las sugerencias y la capa 1 aborta la imagen); paso 5, la línea de comandos cumple y `/api/salud` dice 200: **el servicio no se entera de la directiva**.
- **Rechazo:** paso 1 con conexiones (la capa 2 sola no corta: **Alta**, contradice P-03); paso 3 con conexiones (**Alta**: sin capa 3 efectiva queda solo la 0 y la 1); paso 2 sin conexiones (la directiva no se aplicó en este equipo: `No se pudo`, **no** `Cumple`, probar `chrome://policy` o `edge://policy` con el navegador de la VM; no hay captura de pantalla con datos).
- **Hallazgo esperado, a clasificar con A:** el servicio no detecta una directiva de proxy (**Media**, S170-03; la remediación propuesta por A es el evento 5118 crítico al arrancar). Se anota con "confirmado en la VM" o "no se pudo reproducir".
- **Duración:** 60 min con los dos navegadores. **Marca:** [I]. Las directivas de extensiones forzadas (`ExtensionInstallForcelist`) **no se prueban**: necesitan una extensión alojada y un equipo administrado.

## 7. L-3. La canalización de CDP funciona como servicio, y no queda ningún puerto

**Origen:** blueprint §4.2 y §9 (L-3), R-T403-04, U-2 de la revisión de A (`Pipe = true`, `ConvertidorPdf.cs:398` [V]), H170-09 de mi revisión.

### L-3a. El navegador arranca y renderiza por `--remote-debugging-pipe` bajo el servicio

- **Precondición:** L-1a en verde; `LAB-T403-LISTO`.
- **Pasos:** (1) `Escuchas | Tee-Object "$E\L3a-antes.txt"`. (2) `RENDER(ticket 80 mm, Razor base)` y 20 más. (3) `Navegadores` (línea de comandos del proceso principal y de los hijos). (4) `Escuchas | Tee-Object "$E\L3a-despues.txt"` y `netstat -ano -p tcp` filtrado a los PID del navegador. (5) Intentar desde `gpos-lab-usuario`: `Test-NetConnection 127.0.0.1 -Port 9222` y un barrido de los puertos que aparezcan en `Escuchas` con dueño del navegador (debe haber ninguno).
- **Esperado [I]:** los 21 renders responden; la línea tiene `--remote-debugging-pipe` y **no** `--remote-debugging-port`; `Escuchas` después = antes (solo 5073 de la API de reportes y lo que ya estaba), sin ningún `LISTEN` con `OwningProcess` de `chrome.exe`/`msedge.exe`.
- **Rechazo:** **Alta**: el navegador no arranca o el render falla por la tubería (en Windows la tubería hereda descriptores 3 y 4, que es la forma POSIX [I, nota del blueprint]; si falla bajo el servicio y no bajo un usuario, es una diferencia de herencia de identificadores): **no hay respaldo** en el código (D-5), así que los personalizados quedan sin render; B decide si se agrega el puerto aleatorio como respaldo (con riesgo R-T403-04) o se investiga la causa. **Alta**: aparece un puerto de depuración.
- **Control:** el mismo navegador lanzado desde el lanzador con `--remote-debugging-port=0` muestra un `LISTEN` en `127.0.0.1` con su PID (demuestra que `Escuchas` lo vería).
- **Duración:** 25 min por navegador. **Marca:** [I].

### L-3b. Un proceso local no puede conectarse al navegador

- **Pasos:** con el navegador vivo, desde `gpos-lab-usuario` y desde Administrador: buscar un puerto de depuración (barrido de `127.0.0.1` 1-65535 con `Test-NetConnection`/`Get-NetTCPConnection -State Listen`, 5 min) y listar las canalizaciones (`[System.IO.Directory]::GetFiles('\\.\pipe\')`) que contengan `chrome`/`msedge`/`mojo` (las de Chromium para su IPC interna existen y son normales).
- **Esperado [I]:** ningún puerto; las canalizaciones sin nombre predecible del CDP (la de CDP es anónima, no por nombre).
- **Rechazo:** un puerto TCP o una canalización con nombre que atienda CDP (**Alta**). Anotar las canalizaciones de Chromium encontradas y su DACL si se pueden leer.
- **Duración:** 15 min. **Marca:** [I]; es un barrido, no una prueba de ausencia.

### L-3c. Vida del navegador cuando el servicio muere (H170-09; Job Object es T4-03b, P-13)

| ID | Pasos | Esperado [I] | Rechazo |
|---|---|---|---|
| L-3c-1 | `RENDER` terminado; `sc stop GPOS.Reportes`; contar procesos del navegador a los 5, 15 y 60 s | 0 procesos a los 15 s; `perfil-*` borrado | Procesos vivos tras 60 s (**Media**: huérfanos con el token del servicio) |
| L-3c-2 | `sc queryex` para el PID; `taskkill /f /pid <PID>` del servicio en pleno `RENDER` (con 4 renders en vuelo); contar procesos a los 5, 15 y 60 s; `sc start` | El navegador termina solo al cerrarse la tubería (EOF) [I]; al arrancar, el servicio borra los `perfil-*` huérfanos y no se bloquea por el perfil ocupado (`SingletonLock`) | El navegador queda vivo tras 60 s, o el nuevo arranque falla por el perfil: **Media** si queda huérfano (el Job Object de T4-03b lo cierra); **Alta** si además impide el arranque |
| L-3c-3 | `RENDER` que dura 25 s (formato con CSS pesado, si B tiene el de la prueba de tiempo) y corte de red de la sesión (cerrar la sesión remota) | El render termina o da 408/500 sin colgar el servicio | El servicio deja de responder `/api/salud` |

- **Evidencia:** conteo de procesos en los instantes indicados, `sc queryex` antes y después, eventos. **Duración:** 30 min por navegador (solo con uno si el tiempo no alcanza: el comportamiento es de Chromium, no del código de GPOS, pero Edge puede diferir [I]). **Marca:** [I].

## 8. L-4. Tiempo de render con la intercepción y el contexto por render

**Origen:** blueprint §9 (L-4) y R-T403-06 (estimación de 10 a 40 ms por render [I]), meta de `MedicionRender`: el p95 del camino por la canalización no pasa del directo en más de 50 ms [V]; montón administrado ≤ 768 MB.

**Límite honesto.** La **línea base oficial** de `MedicionRender` la mide B en `LFMB` con `GPOST_B9` (tarea aparte, "no es tuya"). Esta medición es **comparativa dentro de la VM** (2 CPU, 3,5 GB, sin SQL) y sirve para tres cosas: ver el costo de las capas con la cuenta del servicio, ver la memoria de **todo el árbol** (el `HeapHardLimit` solo acota al proceso .NET) y descubrir regresiones. No sustituye ni valida la meta de 50 ms.

### L-4a. Antes y después de T4-03a

- **Diseño:** dos publicaciones Release de `GPOS.Reportes.Api`, en la misma VM, restaurando el mismo punto de control entre una y otra: (A) **antes** = la anterior a la unión del #170 (la base del rango que revisé, `89fce5b5` [V: mi revisión]; B confirma la confirmación y entrega el SHA-256) y (B) **después** = `feature/modelo-ng` @ `9a439234` o la punta vigente en la sesión.
- **Pasos (por build y por navegador):** `ARRANCAR`; calentamiento de 5 `RENDER` (se descartan; el precalentamiento corre al arrancar, medir también el tiempo del **primer** render tras el arranque en frío); 50 `RENDER` en serie de cada una de estas cuatro combinaciones: ticket 80 mm personalizado (Razor base), factura Carta personalizada, ticket 80 mm estándar (QuestPDF, **control**: no pasa por Chromium) y factura Carta estándar; medir en el cliente (`Stopwatch` por petición) y guardar los 50 tiempos en CSV. Hora de inicio y fin, para reconstruir la ventana en la revisión.
- **Métricas:** p50, p95 y máximo por combinación; delta de p95 (después menos antes); memoria (`WorkingSet64` y `PrivateMemorySize64`) del proceso de la API y la **suma del árbol del navegador** al inicio, a las 25 y a las 50 pasadas, y tras 200 renders adicionales (fuga: crecimiento monótono).
- **Criterios (propuesta mía, sin firma; D-3):** delta de p95 de los personalizados **≤ 100 ms** en la VM (el doble de la meta oficial, por el ruido de 2 CPU) → `Cumple`; entre 100 y 500 ms → **Media** (informar con las cifras); > 500 ms o algún render > 30 s → **Alta**. Los estándar no deben cambiar (> 20 % de diferencia entre builds es un problema de la medición: se repite). Memoria: montón de la API < 768 MB sin `OutOfMemory`; el árbol del navegador se **informa** sin umbral (no hay meta firmada); crecimiento > 100 MB tras los 200 renders → **Media** (posible fuga de contextos, P-09).
- **Evidencia:** el CSV de cada corrida, la tabla de percentiles, las dos huellas SHA-256 y el commit, la versión del navegador, y una captura de la carga de CPU de `VirtualBox` en `LFMB` al inicio y al final (si el anfitrión estaba ocupado, la corrida no vale).
- **Duración:** 60 min (2 builds × 2 navegadores). **Marca:** [I].

### L-4b. Concurrencia hasta el cupo

- **Pasos:** 4 `RENDER` personalizados a la vez (el máximo de `MaximoSimultaneos`) × 20 rondas; luego 8 a la vez (4 deben esperar cupo; `EsperaCupoMs` = 10 s) × 5 rondas.
- **Esperado [I]:** con 4, ninguno mezcla contenido (comparar el número de documento impreso en cada PDF con el pedido) y todos responden antes de 30 s; con 8, los que pasan de la espera responden 429 `RENDER_OCUPADO`, y el servicio se recupera (`/api/salud` 200) sin reiniciar.
- **Rechazo:** un PDF con el contenido de otra petición (**Crítica**: mezcla entre empresas); un 500 o un servicio que no vuelve (**Alta**).
- **Duración:** 30 min. **Marca:** [I]. Cubre lo que mi bloque CH-11 dejaba sin la intercepción.

## 9. Severidades y recomendación

**Severidades de laboratorio** (las de mi entrega de T1-b, con lo propio de T4-03):
- **Crítica:** `--no-sandbox` presente; renderizadores sin diferencia de token con el principal; el navegador o el servicio corre con una cuenta o privilegio no previsto; un secreto impreso en la evidencia; mezcla de contenido entre peticiones.
- **Alta:** el *sandbox* o la canalización de CDP no arrancan bajo el servicio; la carpeta `render` queda legible por `AU`/`BU` o sin DACL protegida (H170-04 hecho realidad); 5119 que no sale; la regla no corta al navegador del servicio, o corta a otros; un puerto de depuración; el puerto 5073 en una interfaz que no es loopback.
- **Media:** directiva que anula la capa 2 sin aviso (S170-03 confirmado); huérfanos del navegador; huellas fuera de `render`; delta de p95 entre 100 y 500 ms; fuga de memoria; un caso `No se pudo` por entorno incompleto.
- **Baja:** textos, tiempos, avisos.

**Recomendación técnica** (la decisión es de B y del propietario): *Rechazado* si queda algún hallazgo Crítico o Alto; *Aprobado con observaciones* si solo hay Medios o Bajos o casos `Bloqueado`; *Aprobado* solo con todos los casos ejecutables en `Cumple` **y con sus controles**. Un `No se pudo` o `Bloqueado` nunca cuenta como `Cumple`.

**Qué queda `Bloqueado` por diseño y por qué:**

| Caso | Bloqueado por |
|---|---|
| Comprobación 5118 al arrancar (existencia de la regla) | No implementada (`ConvertidorPdf.cs:49` la reserva; T4-03b) |
| Job Object (P-13) y su efecto en L-3c y S170-04 | T4-03b |
| Ruta del navegador limitada en Release (S152-10, fila 6 de L-2a) | T4-03b: hoy es un hueco que se documenta, no se vigila |
| Regla del cortafuegos desde el MSI o el script del DEMO | El MSI de reportes y PR-D2 no existen: la regla se crea en el caso |
| Directivas de grupo reales (dominio) | No hay controlador de dominio en el laboratorio |
| Comprobaciones R1 a R10 del paquete, `sc qprivs` desde el MSI | Su bloque PK; el servicio de este documento se crea a mano |

## 10. Lista de revisión de la evidencia de esta sesión

Se aplican **sin cambios** las secciones A a E de `tests/laboratorio-adr090/revision-evidencia.md` (procedencia, guardas, secretos, resultado de cada caso, recomendación). Además, para T4-03:

### F. Procedencia del montaje
- [ ] Hay un `preparar-vm-VM-SRV-*.json` con todo `cumple: true` **del punto de control de la sesión**; en S5, también el de `VM-PUESTO`.
- [ ] SHA-256 de la publicación Release (PRE-2) y, en L-4a, de las **dos** publicaciones; coincide con el que B entregó. Para el lanzador de PRE-5, SHA-256 del script o de la aplicación.
- [ ] Versión de cada navegador (Chrome y Edge) con `ProductVersion`, y cuál se usó en cada caso: **ningún caso mezcla navegadores** (la salida de `Navegadores` lo muestra).
- [ ] El servicio de laboratorio: `sc qc`, `sc qprivs` (solo `SeChangeNotifyPrivilege`), `sc showsid`, `sc qsidtype` guardados **antes** del primer caso. Falta alguno → los casos L-1 son `No se pudo`.
- [ ] La DACL real de `GPOS NG` y de `Reportes` (PRE-4b) está guardada y es la que dice el documento; si B la cambió, el cambio está anotado (D-6).

### G. Controles (sin control no hay `Cumple`)
- [ ] L-1c: existe el resultado del control con `--no-sandbox` y **se ve** la diferencia de token.
- [ ] L-2a: la fila 1 (sin regla) tiene conexiones; sin esa fila, las filas 2 a 6 no concluyen.
- [ ] L-2c: el paso 1 y el paso 2 existen en pares (sin directiva y con directiva) y se aplicó la directiva (`chrome://policy` o `edge://policy`).
- [ ] L-3a: el control `--remote-debugging-port=0` muestra el puerto en `Escuchas`.
- [ ] L-4a: la columna de los estándar (control) no cambia entre builds.

### H. Secretos y datos propios de este bloque
- [ ] Los `Navegadores`/`CommandLine` no traen cadenas de conexión ni claves (no hay: el entorno del servicio no las lleva); si aparece cualquiera de las cadenas prohibidas de la sección C, la carpeta **no se publica**.
- [ ] Ninguna captura de pantalla de `chrome://policy` o del Visor con datos ajenos a la VM.
- [ ] El `Environment` del servicio no se exportó; solo `GetValueNames()`.
- [ ] Los PDF de muestra son del modelo dorado; no hay datos reales. Se guardan **como mucho 2** por combinación, y los demás solo su cabecera y tamaño.
- [ ] Los registros de los oyentes y los 5157 solo tienen direcciones del laboratorio (192.168.50.x y 127.0.0.1).
- [ ] Los volcados de *crashpad* o los listados de L-1d no se copian al repositorio; solo su nombre, tamaño y ruta.

### I. Horas y orden
- [ ] Las horas de los `.json`, de los CSV de L-4 y de los 5157 caen dentro de la ventana de la sesión y en el orden de la sección 4.
- [ ] L-4 se midió **sin** otra VM encendida ni compilaciones en `LFMB` (nota del técnico y carga de CPU).
- [ ] Los casos de severidad Crítica o Alta (L-1c, L-1a, L-1b-N1, L-2a fila 2/3/4, L-3a, L-4b) se **recalculan a mano** desde lo observado.

## 11. Preguntas abiertas (D-x)

| ID | Pregunta | A quién |
|---|---|---|
| D-1 | **Disparador de render (PRE-5): R-A (principal de mentira por tarea programada, el código real) o R-B (arnés .NET)**, y quién lo escribe. R-A deja L-1a/L-1b en verdad de producción; R-B no. Escribo el cliente PowerShell de R-A (≈ 1,0 dp) si B lo confirma. Esperar a `ClienteRender` (#210) y a T4-02b (desde el 16-nov) llega tarde para el límite del 13-nov de esta tarea y tampoco da un cliente que corra sin la principal | B |
| D-2 | ¿La imagen de `VM-SRV` trae **Edge** (Q-5 sin respuesta) y qué versión? ¿Cómo entran el MSI de Chrome y Process Explorer/System Informer sin Internet? ¿Qué versión de Chrome se fija (B cita 156)? | B |
| D-3 | Umbral de L-4a: ¿acepta B el de 100 ms de delta de p95 en la VM como criterio de `Cumple`? No hay umbral firmado por encima de la meta de 50 ms de `MedicionRender`, que mide B en `LFMB`. Y ¿qué commit exacto es el "antes" (la base del #170, `89fce5b5`)? | B |
| D-4 | L-2 pide `VM-SRV` y `VM-PUESTO` a la vez: ¿cabe en la memoria de `LFMB` junto con lo que corra B? Si no, la variante con el oyente en la segunda IP de `VM-SRV` (`192.168.50.11`) es **solo orientativa**: Windows puede tratar el tráfico a una dirección propia como bucle y no filtrarlo [I]; un "no sale" no sería concluyente, un "sale" sí | B |
| D-5 | **Sin respaldo de la canalización:** el blueprint (R-T403-04) dice "aceptarlo y volver a revisar en la v2"; el código fija `Pipe = true` sin alternativa. Si L-3a falla bajo el servicio, ¿se agrega el puerto aleatorio o se investiga la causa? | B / A |
| D-6 | DACL exacta de `Reportes` (PRE-4b): la tomo del blueprint §5 y del diseño del instalador; devops (A) debe confirmarla, porque el resultado de L-1a y L-1b depende de ella. Y si las pruebas se hacen sobre el MSI de reportes cuando exista, estas precondiciones se sustituyen por su instalación | A |
| D-7 | L-2c: ¿se acepta `No se pudo` para las directivas de un dominio real, o A quiere un controlador de dominio mínimo en el laboratorio (coste: una tercera VM de Windows Server, ≈ 2 GB; fuera del diseño de ADR-90)? | A / B |

## 12. Qué no verifiqué

- **Nada se ejecutó**: ni servicio, ni navegador, ni `sc`, ni el cortafuegos, ni PowerShell contra la VM. Todo lo marcado [I] es conocimiento general de Windows, Chromium y PuppeteerSharp, **no** comprobado aquí ni contra la documentación del fabricante: que el *sandbox* arranque con un solo privilegio; los niveles de integridad y los tokens de cada tipo de proceso; que `NT SERVICE\<servicio>` se use como principal de una tarea programada; que `New-NetFirewallRule -LocalUser` acepte ese SDDL y que la condición alcance a los hijos; que Windows filtre (o no) el tráfico a una dirección propia; el comportamiento de las directivas de Chrome y Edge sin dominio; que la tubería de CDP funcione en Windows bajo un servicio; que Chromium termine al cerrarse la tubería; los códigos de salida y la terminación del proceso por el Administrador de servicios al pasar de los 30 s.
- **No leí** `ServiciosLectura.cs` ni `EndpointsReportes.cs` completos (la forma de la canalización HTTP para R-A se deduce de `MedicionRender` y de `EndpointsRender.cs`); no leí `CuentaServicioVirtual` ni `IdentidadCanalizacion`; no verifiqué que el servicio arranque sin SQL ni sin `Sistema` (lo dice un comentario de `Program.cs`). Tampoco compilé ni publiqué `GPOS.Reportes.Api`.
- **El número de línea** `PoliticaRedNavegador.cs:140` (lista `EntornoPermitido`) es aproximado; las demás referencias de línea son de la lectura de hoy.
- **No existe** el MSI de reportes, el script del DEMO con dos servicios (PR-D2), el disparador de PRE-5 ni el lector de token de PRE-6c.
- **Duraciones y reparto en sesiones:** estimaciones mías, sin experiencia de ejecución previa en esta VM.
- **No se prueban:** el riesgo residual de S170-05 (escape del *sandbox* con el token del servicio), la compilación Razor de las plantillas, las directivas de extensiones forzadas, ni el contenido de los volcados de *crashpad*.

### Cierre
- Estado: Completado (casos redactados; ninguno ejecutado)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-23-casos-laboratorio-l1-l4-t4-03.md`
- Supuestos: los de la sección 12; la sesión usa `VM-SRV` con el punto de control `base`; el servicio de laboratorio se crea a mano (sin MSI de reportes); B decide el disparador de render (D-1)
- Decisiones candidatas a ADR: Ninguna
- Entregas a otros agentes: B → D-1 (disparador), D-2 (Edge, Chrome, herramientas), D-3 (umbral y commit "antes"), D-4 (memoria de `LFMB` para dos VM), D-5 (sin respaldo de la canalización); A (devops) → D-6 (DACL de `Reportes`), D-7 (dominio de prueba para L-2c); A (auditor-seguridad) → revisar L-1c, L-2 y L-2c antes de dar T4-03 por verificado
- Próximo paso recomendado: B responde D-1 y D-2; con D-1 escribo el cliente de render y `Leer-Token.ps1`, y se agenda S4 antes de que T4-02 llegue a revisión
