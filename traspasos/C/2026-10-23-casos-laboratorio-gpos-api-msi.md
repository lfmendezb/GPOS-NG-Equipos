```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (tarea 3 de B-a-C/2026-10-23-tareas-nuevas-para-c-5: casos de laboratorio del GPOS.Api.msi)
Prioridad: Media
Repositorio y rama: GPOS-NG `origin/b/t1b-api-msi` @ `c7c6c95a` (solo lectura, `git show`); base `origin/feature/modelo-ng` @ `b9efa9fb`; área común `traspasos/C/`
Estado: Abierto (casos redactados; nada ejecutado)
```

# Casos de laboratorio del `GPOS.Api.msi`: instalar, actualizar, reparar, desinstalar, privilegios, recuperación, orígenes de eventos, comprobación previa O-1 y guarda G-PR4

**Qué es.** Casos para `VM-SRV` de `LFMB` (VirtualBox; los opera B). **No se compiló ni se ejecutó nada** (ni MSI, ni servicio, ni script; OSHIN-LEGION no tiene VirtualBox y la regla del 2026-10-08 impide tocar servicios fuera de la VM). A diferencia de mi entrega del 23-oct (`2026-10-23-casos-laboratorio-t1b-y-revision-173.md`, bloque MI), que escribí contra la guía de A porque el MSI no existía, **esta se escribió leyendo el `Package.wxs`, el `.wixproj`, el `construir.ps1` y `ApiInstaladorTests.cs` de la rama `b/t1b-api-msi`**. Donde el MSI real se aparta de lo que supuse, lo digo en la sección 3 y el caso nuevo manda sobre el MI-xx.

**Marcas.** [V] verificado leyendo un archivo (ruta en la rama indicada); [I] inferido o conocimiento general de Windows, WiX o msiexec, por confirmar en la VM; [?] depende de algo que aún no existe o que B/A deben decidir.

**Estados de un caso en la VM.** `Cumple` · `No cumple` · `No se pudo` (la precondición no existía) · `Bloqueado` (no ejecutable hoy). `No se pudo` y `Bloqueado` **nunca** cuentan como `Cumple`. **Un caso sin su control no puede dar `Cumple`**: el control es la misma medición con el mecanismo apagado o alterado, y demuestra que el instrumento ve la diferencia.

## 0. Resumen para decidir

1. **50 casos** en nueve bloques más la firma (B construcción, I instalar, O comprobación previa, S arranque y reserva, R recuperación, A actualizar, P reparar, D desinstalar, N negativos, FIR-1); cuatro quedan `Bloqueado` por diseño (A5, D3, R2, FIR-1) y R4 es opcional. Cada uno con precondición, pasos, esperado, rechazo con severidad, evidencia, duración, marca y control. Tres de ellos (B1 a B3) **no son de la VM**: corren en la PC de construcción de B y fallan antes de publicar.
2. **Cuatro hallazgos de lectura del `Package.wxs` que pueden cambiar la decisión de B antes de la VM** (sección 3): **L-01** la recuperación configurada (reiniciar, reiniciar, reiniciar) reinicia **para siempre**, no tres veces; **L-02** `MajorUpgrade` con el `ServiceControl Remove="uninstall"` probablemente **borra y recrea el servicio** en cada actualización, y con él el valor `Environment` y la DACL de la clave que pongan los verbos de PR-V; **L-03** tras actualizar el servicio queda detenido aunque estuviera en marcha; **L-04** `Start="auto"` sin configuración hace que cada reinicio del equipo produzca un servicio que falla y se reinicia cada 60 s.
3. **Lo que el MSI solo no puede probar:** que el servicio llegue a `Running` (falta clave JWT, anillo, cadena `Sistema`; MI-06). Por eso el **caso de privilegios exactos (I3)** se apoya en tres evidencias indirectas: `sc qprivs`, la **ausencia de 4767** (la comprobación de identidad y privilegios corre antes que la configuración, `Program.cs:30`) y el **control** con un privilegio de más. El token del proceso vivo (evento 4770 `Privilegios del token`) solo se ve en el spike (DE-01).
4. **Correcciones a mis casos anteriores** (sección 3, tabla C-01 a C-06): los nombres de puntos de control `LAB-T1B-*` **no cumplen el patrón** de `Puntos-Control.ps1`; el "y luego detenido" de MI-06 y MI-N2 es falso con tres reinicios; P-09 (`FailureActionsWhen`) quedó resuelto; `INSTALLFOLDER` no existe; `Preparar-Vm.ps1` y `Probar-Instalador.ps1` ya están en `feature/modelo-ng`.
5. **Duración [I, ±50 %]:** ≈ 12,5 h en tres sesiones de ≈ 4 h (sección 4). Si solo cabe una ventana de 4 h: I1, I3, O1, A2, N3, D2, R1, P2, S1 (sección 4).
6. **Fecha:** B pidió estos casos antes del 13-nov; la VM de B está prevista del 16 al 27-nov [por el aviso]. Sin confirmación del propietario (pregunta Q-1).

## 1. Fuentes y estado del código

**Leído en esta entrega (todo `git show`, ningún árbol de trabajo tocado):**
- `origin/b/t1b-api-msi` @ `c7c6c95a`: `instalador/Api/Package.wxs`, `instalador/Api/GPOS.Api.Instalador.wixproj`, `instalador/Api/construir.ps1`, `tests/GPOS.Tests/Instalador/ApiInstaladorTests.cs` (nombres de las pruebas y T1-09). El commit añade solo esos cuatro archivos y una línea de `.gitignore`.
- `origin/feature/modelo-ng` @ `b9efa9fb`: `instalador/Comun/Fragmentos/ComprobacionCarpetasPrevias.wxs` y `RaizGposNg.wxs`; `instalador/Comun/GPOS.Instalador.Acciones/AccionesInstalador.cs` y `ComprobacionCarpetasPrevias.cs` (códigos `DUENO_NO_PERMITIDO`, `ESCRITOR_NO_PERMITIDO`, `PUNTO_DE_REANALISIS`, `NO_ES_CARPETA`, error 25101, eventos 4753 a 4755, origen `GPOS.Instalacion`); `instalador/Comun/Firma-Instalador.ps1` (existe: #164 está unido); `src/GPOS.Api/Program.cs:30-110` y `src/GPOS.Api/Servicio/ModoServicioApi.cs` (`PrivilegiosDeclarados` en `:20`, `ArgumentoServicio` en `:42`, los rechazos `ARRANQUE_*`, el evento 4770 en `CicloDeVidaServicio`); `tests/laboratorio-adr090/invitado/Probar-Instalador.ps1` (casos `L-1bis`, `L-2bis`, `L-2c` a `L-2f`, `P-O1-7.x`, `F-1-*`), `Preparar-Vm.ps1`, `anfitrion/Puntos-Control.ps1`, `anfitrion/herramientas/Comun-Laboratorio.ps1:56` (patrón de nombres de puntos de control) y `tests/laboratorio-adr090/revision-evidencia.md`.
- Mis entregas previas: `2026-10-23-casos-laboratorio-t1b-y-revision-173.md` (reglas, funciones de apoyo, severidades) y `2026-10-23-casos-laboratorio-l1-l4-t4-03.md` (formato con control).
- Blueprint de A: `traspasos/A/blueprint-tarea1-instalador-servicio-2026-10-22.md` (secciones 3, 4.1 y 6.2).

**Estado de la rama [V]:** `git grep FijarEscuchaPorOmision` sobre `src/` de `feature/modelo-ng` no devuelve nada (PR-4 está unido). Tampoco vi en la rama una prueba ni un guion para el `publicacion.sha256` ni para un segundo MSI de versión mayor; los pide MI-02 y A1 (pregunta Q-5).

## 2. Reglas heredadas, funciones de apoyo y puntos de control

**Reglas (sin discusión; son las de mis casos previos y las de `revision-evidencia.md`):**
1. Solo en `VM-SRV` desde `base`. Nunca en la PC del propietario, en OSHIN-LEGION ni en la PC de A. Lo opera B; yo reviso la evidencia ya redactada (`Recoger-Evidencia.ps1`).
2. Un punto de control por bloque y al terminar `Restaurar base -Apagar`. Los casos plantan carpetas, borran claves y cambian la directiva FIPS.
3. Si algo falla **no se corrige a mano para que pase**: se anota (ruta, código, SID, texto del evento) y se restaura.
4. **Cada `msiexec` con `/l*v`.** Sin `GPOS.Api.msi` instalado no existe el origen `GPOS.Instalacion` y el motivo de un rechazo queda solo en el registro del MSI (S-11).
5. **Sin secretos en la evidencia.** Prohibidos: `reg query` y `reg export` de `HKLM\SYSTEM\CurrentControlSet\Services\GPOS.Api`; `Get-ItemProperty` de esa clave sin `-Name`; `Get-Item` impreso sin `.GetValueNames()`. En todos los casos que escriben un valor `Environment` de prueba el contenido es el **centinela** `CENTINELA-LAB-NO-SECRETO=1`, nunca una clave real (ver A2).
6. Una sola corrida a la vez en `LFMB`; ninguna suite compilando durante la ventana.
7. Los datos sembrados en carpetas (`centinela.txt`) son texto inocuo.

**Puntos de control (corrección C-01).** `Puntos-Control.ps1` solo admite `base`, `T0`, `T0+Nd` y `LAB-NN[letra][-L][-sufijo]` con **dos o tres dígitos** (`Comun-Laboratorio.ps1:56`). Propongo reservar **LAB-140 a LAB-149** para este bloque (pregunta Q-2):

| Nombre | Cuándo |
|---|---|
| `LAB-140-base-ok` | VM preparada (sección 4), antes de instalar nada |
| `LAB-141-instalado` | Tras I1 en verde |
| `LAB-142-fips` | Antes de O6, tomado desde el anfitrión |
| `LAB-143-v1` | Tras instalar la versión 1 con centinelas (antes de A1) |
| `LAB-144-sinorigen` | Antes de S3 (el caso borra el origen) |

**Funciones de apoyo** (Windows PowerShell 5.1 elevado, una vez por sesión):

```powershell
$E   = 'C:\GPOS-LAB\evidencia\API'; New-Item -ItemType Directory -Force $E | Out-Null
$msi = 'C:\GPOS-LAB\msi\GPOS.Api-SINFIRMA.msi'          # versión 1
$msi2= 'C:\GPOS-LAB\msi\GPOS.Api-SINFIRMA-v2.msi'       # versión mayor (la construye B con construir.ps1 -Version)
function Msi([string[]]$a,[string]$log){ $p = Start-Process msiexec.exe -ArgumentList ($a + @('/qn','/norestart','/l*v',"`"$E\$log.log`"")) -Wait -PassThru -WindowStyle Hidden; $p.ExitCode }
function Foto([string]$id){            # estado observable del servicio, sin tocar Environment
  $d = New-Item -ItemType Directory -Force "$E\$id"
  foreach($c in 'qc','qprivs','showsid','qsidtype','qfailure','qfailureflag','sdshow','query'){ & sc.exe $c GPOS.Api 2>&1 | Out-File "$E\$id\sc-$c.txt" }
  Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\GPOS.Api' -Name ImagePath,ObjectName,Start,RequiredPrivileges -ErrorAction SilentlyContinue | Out-File "$E\$id\registro-valores.txt"
  @((Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Services\GPOS.Api' -ErrorAction SilentlyContinue).GetValueNames()) | Out-File "$E\$id\registro-nombres.txt"
}
function Eventos([datetime]$desde){ Get-WinEvent -FilterHashtable @{LogName='Application';StartTime=$desde} -ErrorAction SilentlyContinue |
  Where-Object { $_.ProviderName -in 'GPOS.Api','GPOS.Instalacion','.NET Runtime','Application Error','MsiInstaller' } | Select-Object Id,ProviderName,LevelDisplayName,TimeCreated,Message }
function ScmEventos([datetime]$desde){ Get-WinEvent -FilterHashtable @{LogName='System';ProviderName='Service Control Manager';StartTime=$desde} -ErrorAction SilentlyContinue |
  Where-Object { $_.Message -match 'GPOS' } | Select-Object Id,TimeCreated,Message }
function Dacl([string]$r){ $a = Get-Acl -LiteralPath $r; "{0}`n{1}" -f $a.Owner,$a.Sddl }
function Arbol([string]$r){ Get-ChildItem -LiteralPath $r -Force -Recurse -ErrorAction SilentlyContinue | ForEach-Object FullName | Sort-Object }
```

**Valores de referencia [V, del `Package.wxs` salvo indicación]** que los casos citan:
- `ServiceInstall`: `Name=GPOS.Api`, `DisplayName=GPOS NG: API`, `Type=ownProcess`, `Start=auto`, `ErrorControl=normal`, `Vital=yes`, `Account=NT SERVICE\GPOS.Api` (sin contraseña), `Arguments=--servicio`.
- `ServiceConfig OnInstall/OnReinstall=yes` con `RequiredPrivilege = SeChangeNotifyPrivilege` (única); sin `ServiceSid`.
- `util:ServiceConfig`: reiniciar, reiniciar, reiniciar; 60 s; contador a 1 día; `FailureActionsWhen=failedToStopOrReturnedError`; sin comando.
- `util:PermissionEx` del servicio: `D:(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLORC;;;BU)`.
- `ServiceControl`: `Stop=both Remove=uninstall Wait=yes`, sin `Start`.
- SID de la cuenta virtual escrito en la DACL de `Api\`: `S-1-5-80-546908902-3265840057-98699379-1016526221-3413751906` (la VM lo confirma con `sc showsid GPOS.Api`).
- `Api\` de datos: `O:SYG:SYD:PAI(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICI;0x1301bf;;;<SID>)`. Raíz y `config\`: `O:SYG:SYD:PAI(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICI;0x1200a9;;;AU)`, `Permanent="yes"`.
- Orígenes: `GPOS.Api` y `GPOS.Instalacion` (registro Aplicación; `EventMessageFile` bajo `%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\EventLogMessages.dll`). El agente de impresión usa `GPOS.EstacionImpresion`, otro origen (`AgenteImpresion/Package.wxs:152`).
- `Feature Api`: `Level=1 AllowAbsent=no AllowAdvertise=no`; `GposFeatureCarpetas=Api` (literal en el `.wixproj`).
- Producto: `Name=GPOS NG API`, `Manufacturer=GSF`, `UpgradeCode=873165B9-9837-4391-9656-F53AEEB5FD41`, `Scope=perMachine`, versión de `!(bind.FileVersion.ApiExe)`, `MajorUpgrade DowngradeErrorMessage="Ya está instalada una versión más reciente de la API de GPOS NG."`.

## 3. Hallazgos de lectura (L) y correcciones a mis casos anteriores (C)

**Hallazgos previos a la VM.** Severidad = efecto sobre la validez o el valor del laboratorio y sobre la operación; no es una revisión de seguridad (eso es del auditor de A).

| # | Sev. | Observación | Evidencia | Qué pido y qué caso lo mide |
|---|---|---|---|---|
| **L-01** | **Media** | La recuperación declara tres veces "reiniciar" con 60 s. El Administrador de servicios aplica la **última** acción a todos los fallos siguientes, así que un servicio que no logra arrancar se reinicia **cada 60 s sin límite** (hasta que el contador se reinicie al cabo de 1 día sin fallos, o alguien lo detenga). Con 4767 o un `InvalidOperationException` en cada intento, el Visor de eventos recibe ≈ 1 440 eventos al día [I: conducta del SCM; la VM la confirma]. Mi MI-06 y MI-N2 decían "tres reintentos y luego detenido": **era un error mío** (C-02) | `Package.wxs`, `util:ServiceConfig` [V]; Blueprint 3: "reinicio, reinicio, reinicio" [V] | B/A: ¿es lo previsto (DM-14) o la tercera acción debe ser `none`? Lo mide **R1**. Si es lo previsto, el procedimiento de operaciones debe decirlo |
| **L-02** | **Alta** (si se confirma) | `MajorUpgrade` desinstala la versión anterior antes de instalar la nueva (calendario por omisión de WiX [I]) y la anterior trae `ServiceControl Remove="uninstall"`: el servicio se **elimina y se vuelve a crear**. Todo lo que `implantar-servidor`, `red` o `tls` (PR-V) hayan escrito en `HKLM\SYSTEM\CurrentControlSet\Services\GPOS.Api` (valor `Environment` con la clave JWT y la cadena `Sistema`, la DACL de la clave) se pierde; el servicio nuevo queda sin configuración y, por L-04, falla en bucle. Sería una actualización que **rompe un servidor en producción** sin aviso | `Package.wxs`: `MajorUpgrade` sin `Schedule`; `ServiceControl Remove="uninstall"` [V]; efecto en el servicio [I] | A/B: ¿el procedimiento de actualización dice que se reconfigura con el verbo después? ¿O el MSI debe conservar la configuración? Lo mide **A2** (con valor centinela, sin secretos) |
| **L-03** | Media | `ServiceControl` no tiene `Start`: tras una actualización o una reparación el servicio queda **detenido** aunque estuviera `Running`. Aceptable si la cadena de implantación lo arranca; no lo es si el técnico actualiza solo el MSI | `Package.wxs` [V]; blueprint 3, fila `ServiceControl` [V] | B: ¿quién arranca el servicio tras actualizar? Lo anota **A1/A5** |
| **L-04** | Media | `Start="auto"` sin configuración: tras un reinicio del equipo el servicio intenta arrancar y falla. Con L-01, queda en bucle. Q-8 de A dejó `auto` hasta medir L-15 | `Package.wxs` [V] | B: ¿`demand` hasta que `implantar-servidor` lo pase a `auto`? Lo mide **R3** |
| L-05 | Baja | La guarda G-PR4 **ya no tiene objeto**: `FijarEscuchaPorOmision` no existe en `src/` (PR-4 unido). La guarda pasa con el archivo real. La prueba T1-09 sigue pidiendo el caso sintético y la mutación; no está mal, pero el §8 del documento de operaciones y el §7 de la guía de A hablan de una limitación que ya no existe | `ApiInstaladorTests.cs:307-335` ("hoy no contiene la cadena (PR-4 unido), así que la guarda pasa") [V] | A: retirar los textos. Lo ejercen **B1** y su control |
| L-06 | Baja | `GPOS.Api.exe` va en un componente propio y el resto de la publicación se recoge con `Files Include="$(var.Publicacion)\**"`. WiX 5.0.2 puede omitir o duplicar archivos si la publicación trae rutas largas o enlaces; el propio `Package.wxs` lo dice ("se confirma con el primer `wix build`") | comentario en `Package.wxs` [V] | B entrega `publicacion.sha256`; lo mide **I2** |
| L-07 | Baja | `DirApiDatos` (`Api\`) es un componente con `CreateFolder` sin `Permanent`: al desinstalar, Windows Installer quita `Api\` **solo si está vacía**. Si el servicio ya escribió `anillo\`, `Licencia\` o `registros\`, queda; es lo deseado (ADR-77), pero conviene verlo | `Package.wxs` [V] | Lo mide **D2** |

**Correcciones a mis casos anteriores (MI-xx del 23-oct):**

| # | Corrección |
|---|---|
| C-01 | Los nombres `LAB-T1B-BASE-OK`, `LAB-T1B-MI01`, `LAB-T1B-FIPS`, `LAB-SPIKE`, `LAB-SPIKE-VERDE` **no pasan el patrón** `^(base\|T0\|T0\+\d{1,3}d\|LAB-\d{2,3}[a-z]?(-L)?(-[a-z0-9]{1,20})?)$`; `Puntos-Control.ps1` se negaría. Usar los de la sección 2 (y pedir un bloque numérico al spike, Q-2) |
| C-02 | MI-06 y MI-N2: "3 reintentos separados ≈ 60 s y luego detenido" es falso con el último reinicio repetido (L-01). El esperado correcto es el que mide R1 |
| C-03 | P-09 (`FailureActionsWhen`) está resuelto: el `Package.wxs` lo declara `failedToStopOrReturnedError` |
| C-04 | MI-N5 usaba `INSTALLFOLDER`; **no existe** en este MSI. Los directorios son de Id privado (con minúsculas). El caso real es N4 |
| C-05 | `Preparar-Vm.ps1`, `Probar-Instalador.ps1` y `Probar-Spike-Amplio.ps1` ya están en `feature/modelo-ng` (#165 y #173 unidos). Ya no son dependencias |
| C-06 | MI-N3 suponía que el rechazo de un servicio ajeno vendría de `ServiceInstall`; el caso N3 de aquí mide también que el MSI no herede un `Environment` ajeno |

## 4. Orden, duración y sesiones

**Duraciones [I, ±50 %]**, sin contar la compilación de los MSI:

| Sesión | Contenido, en orden | Tiempo |
|---|---|---|
| **S-1** (mañana) | Preparación (30) → B1 a B3 (en la PC de construcción, 25, antes de la sesión) → I1 (25) → I2 (15) → I3 (15) → I4 (10) → I5 (10) → I6 (15) → I7 (25) → I8 (15) → I9 (5) → O1 (40) → O2 (20) → O3 (20) → S1 (20) → S2 (10) | ≈ 4 h 15 min |
| **S-2** (tarde) | A1 (25) → A2 (20) → A3 (10) → A4 (10) → A6 (10) → A7 (15) → P1 (20) → P2 (10) → P3 (15) → D1 (15) → D2 (5) → D4 (20) → D5 (10) → D6 (15) → R1 (25) → R2 (15) → R3 (15) → S3 (15) → S4 (15) → S5 (20) | ≈ 5 h 15 min (si no cabe, R3, S4 y S5 pasan a S-3) |
| **S-3** | N1 (15) → N2 (5) → N3 (15) → N4 (20) → N5 (10) → N6 (30) → O4 (15) → O5 (15) → R4 (25, opcional) → **O6 FIPS al final (40, dos reinicios, deja la VM sucia)** → FIR-1 (si existe el MSI firmado) | ≈ 3 h 15 min |

**Si B solo da una ventana de 4 h**, por riesgo: I1, I3, O1 (a, c, d, e, h), A2, N3, D2, R1, P2, S1, N1. Lo demás queda `No se pudo`, anotado.

**Preparación común (30 min):** restaurar `base`; crear `gpos-lab-usuario` (estándar; el técnico teclea la contraseña); copiar a `C:\GPOS-LAB`: el MSI (versión 1) y el MSI de versión mayor con su SHA-256 anotado (`Get-FileHash -Algorithm SHA256`), `publicacion.sha256` (I2), el MSI de desarrollo del agente de impresión (N6), `Probar-Instalador.ps1`; `.\Probar-Instalador.ps1 -Caso Guardas` debe imprimir `Guardas: cumplidas`. Anotar: nombre y SHA-256 de cada MSI, nombre del punto de control, `[Environment]::OSVersion.VersionString`, si FIPS está activa, y el commit de la rama (`c7c6c95a` o el que B indique). Tomar `LAB-140-base-ok`.

## 5. Bloque B: construcción (en la PC de construcción de B, no en la VM)

Estos tres casos protegen la **guarda G-PR4 y la firma** del `construir.ps1`. Fallan antes de `dotnet publish` (lo verifico en el texto: `Comprobar-GuardaPR4` se llama antes de `Resolver-Firma` y de publicar, `ApiInstaladorTests.cs:337-357`), así que no cuestan una compilación completa. **Se corren sobre una copia del repositorio en una carpeta aparte**, nunca sobre el árbol de trabajo de nadie.

### LAB-API-B1. G-PR4: la guarda se niega a firmar si `ModoServicioApi.cs` conserva `FijarEscuchaPorOmision`
- **Precondición:** copia del repositorio en `C:\Temp\copia-api\`; `signtool` instalado o no (no se usa); ninguna huella real.
- **Pasos:** (1) con el archivo real: `.\instalador\Api\construir.ps1 -Firmar -HuellaCertificado 0000000000000000000000000000000000000000`; anotar el mensaje y la salida. (2) **Control (mutación):** agregar al final de la **copia** de `src\GPOS.Api\Servicio\ModoServicioApi.cs` la línea `// FijarEscuchaPorOmision` y repetir (1). (3) Quitar la línea (restaurar la copia).
- **Esperado:** (1) **no** falla por G-PR4: falla después, al resolver el certificado ("no se encontró el certificado" o equivalente de `Resolver-Firma`), sin crear `instalador\Api\publicacion` ni ningún `.msi`; (2) falla con `G-PR4: ModoServicioApi.cs todavía contiene FijarEscuchaPorOmision (PR-4 de ADR-90 sin unir): no se firma GPOS.Api.msi...`, antes de nombrar el certificado.
- **Rechazo:** (1) falla por G-PR4 con el archivo real (guarda falsa positiva, **Baja**: bloquea una firma legítima); (2) no falla (la guarda no ve la cadena: **Alta**, un `GPOS.Api.msi` firmado con la escucha transitoria); en ambos casos, aparece un `.msi` (**Alta**: nunca debe quedar un msi cuando se pidió firmar y no se pudo).
- **Evidencia:** salida de ambos intentos; `Test-Path instalador\Api\publicacion` y `Get-ChildItem instalador\Api\bin -Filter *.msi -Recurse`. Sin huellas reales.
- **Duración:** 10 min. **Marca:** [V] el orden en el guion (`construir.ps1`, bloque `if ($Firmar)`); [I] el texto exacto del segundo fallo.
- **Control:** el paso (2) es el control del paso (1).

### LAB-API-B2. Un MSI sin firma se llama `-SINFIRMA` y la versión sale del `.exe`
- **Precondición:** la compilación que B ya hace para producir el MSI de laboratorio (no es una compilación extra).
- **Pasos:** (1) `.\construir.ps1` (sin parámetros) y `.\construir.ps1 -Version 1.0.1`; anotar los nombres y las versiones (`(Get-Item …\GPOS.Api.exe).VersionInfo.ProductVersion`, `FileVersion`). (2) `.\construir.ps1 -HuellaCertificado XXXX` (sin `-Firmar`). (3) `.\construir.ps1 -Version 1.0.1.2`.
- **Esperado:** (1) `GPOS.Api-SINFIRMA.msi`; el `.msi` y el `.exe` con la misma versión (la de `bind.FileVersion.ApiExe`); (2) falla con `Se indicó -HuellaCertificado sin -Firmar`; (3) falla por `ValidatePattern` (`\d{1,3}\.\d{1,3}\.\d{1,5}`). Mensaje final `SIN FIRMA: solo para laboratorio; no se distribuye.`
- **Rechazo (Media):** un `.msi` sin firma con el nombre `GPOS.Api.msi`; versión del `.msi` distinta de la del `.exe` (rompe el `MajorUpgrade`, A1).
- **Evidencia:** nombres de archivo, versiones y SHA-256. **Duración:** 5 min. **Marca:** [V] el guion. **Control:** (2) y (3) son negativos del propio caso.

### LAB-API-B3. Con `-Firmar` y huella inexistente no queda `.msi`
- **Precondición:** copia como en B1; el archivo real de `ModoServicioApi.cs` (la guarda pasa).
- **Pasos:** `.\construir.ps1 -Firmar -HuellaCertificado 1111111111111111111111111111111111111111`; luego `Get-ChildItem instalador\Api -Recurse -Filter *.msi`.
- **Esperado:** error del `Resolver-Firma` ("no se encontró el certificado" o similar); **cero** `.msi` bajo `bin` (el guion los borra antes de resolver la firma: `Get-ChildItem … -Filter *.msi | Remove-Item`); no hay `publicacion`.
- **Rechazo (Alta):** queda un `.msi` de una compilación anterior que parezca el resultado. **Evidencia:** salida y listado. **Duración:** 5 min. **Marca:** [V]. **Control:** sembrar antes un `bin\Release\GPOS.Api-SINFIRMA.msi` falso (archivo vacío) y comprobar que se borra; sin la siembra el caso no prueba que el guion limpie.

## 6. Bloque I: instalar

### LAB-API-I1. Instalación limpia, elevada: servicio, cuenta, argumentos, recuperación y nada más
- **Origen:** blueprint 3; MI-01; pruebas T1-05 a T1-08.
- **Precondición:** `LAB-140-base-ok`; Windows Server 2025; sin servicio `GPOS.Api`; sin `%ProgramData%\GPOS NG`; sin `HKLM\SOFTWARE\GPOS NG\Servidor`; FIPS no; sesión elevada.
- **Pasos:**
  1. `Get-FileHash $msi -Algorithm SHA256 | Out-File "$E\I1-sha256.txt"`.
  2. `$desde = Get-Date; $cod = Msi @('/i',"`"$msi`"") 'I1-instalar'; $cod`.
  3. `Foto 'I1'`; `Eventos $desde | Out-File "$E\I1\eventos.txt"`.
  4. `.\Probar-Instalador.ps1 -Caso L-1bis` (ImagePath termina en ` --servicio` y no tiene otros argumentos).
  5. `Get-Service GPOS.Api | Select-Object Name,DisplayName,Status,StartType`; `Get-NetTCPConnection -State Listen -LocalPort 5071,5073 -EA SilentlyContinue`; `Test-Path 'HKLM:\SOFTWARE\GPOS NG\Servidor'`.
  6. Tomar `LAB-141-instalado`.
- **Esperado [I salvo lo marcado]:**
  - Código `0` (no `3010`).
  - `sc qc`: `WIN32_OWN_PROCESS`, `AUTO_START`, `NORMAL`, `BINARY_PATH_NAME` = `"C:\Program Files\GPOS NG\Api\GPOS.Api.exe" --servicio`, `SERVICE_START_NAME` = `NT SERVICE\GPOS.Api`, `DISPLAY_NAME` = `GPOS NG: API`, sin dependencias.
  - `sc query`: `STOPPED` (el MSI no arranca el servicio [V, sin `Start`]).
  - `sc showsid` = el SID de la sección 2.
  - Sin valor `Environment` en `registro-nombres.txt`; sin escucha en 5071/5073; sin la clave `Servidor`.
  - Sin eventos de `GPOS.Api` (no arrancó); `MsiInstaller` 11707 (éxito).
- **Rechazo:** código ≠ 0 (**Alta**: no instala); servicio `RUNNING` (**Alta**: arrancó sin configuración); `ImagePath` con más de un argumento, con `--urls`/`--environment` o sin `--servicio` (**Alta**); cuenta distinta de la virtual o con contraseña (**Crítica**); aparece `Environment` o la clave `Servidor` (**Alta**: el MSI escribe configuración); escucha abierta (**Alta**).
- **Evidencia:** carpeta `I1\`, `I1-instalar.log`, SHA-256. **Duración:** 25 min. **Marca:** [I] hasta ejecutar; `--servicio` y cuenta [V en el `.wxs`].
- **Control:** la misma `Foto` tomada **antes** de instalar (`Foto 'I1-antes'`) debe mostrar el servicio inexistente (`sc query` 1060); sin ese "antes" el "después" no prueba que el MSI lo creó.

### LAB-API-I2. La publicación instalada es completa y es la de la compilación (L-06)
- **Precondición:** I1 en verde; B entrega `publicacion.sha256` generado fuera de la VM con el mismo formato (`HASH  ruta-relativa`).
- **Pasos:** (1) `$base='C:\Program Files\GPOS NG\Api\'; Get-ChildItem $base -Recurse -File | % { '{0}  {1}' -f (Get-FileHash $_.FullName -Algorithm SHA256).Hash, $_.FullName.Substring($base.Length) } | Sort-Object | Set-Content "$E\I2-instalado.sha256"`. (2) `Compare-Object (Get-Content C:\GPOS-LAB\msi\publicacion.sha256 | Sort-Object) (Get-Content "$E\I2-instalado.sha256")`; anotar los conteos. (3) Presencia puntual: `GPOS.Api.exe`, `GPOS.Api.dll`, `appsettings.json` y las carpetas `runtimes\win-x64\native` (o las que B liste). (4) Higiene: `*.pdb`, `*.Tests.dll`, `appsettings.Development.json` ausentes; `Select-String -Path "$base*.json" -Pattern '"Clave"\s*:\s*"[^"]+"','Password=' -List | Select-Object Filename` (solo nombres). (5) `(Get-Item "$base\GPOS.Api.exe").VersionInfo.ProductVersion` = `DisplayVersion` de I9.
- **Esperado:** sin diferencias, sin archivos de desarrollo, sin claves en los JSON, versiones iguales.
- **Rechazo:** archivo faltante (**Alta**: la API no arranca en producción por una dependencia ausente); archivo de más con `.pdb` o `Development.json` (**Media**); una `Clave` o `Password=` con valor en un JSON (**Crítica**).
- **Evidencia:** `I2-instalado.sha256`, salida de `Compare-Object`, conteos. **Duración:** 15 min. **Marca:** [I]. **Control:** borrar una DLL propia y repetir (2): debe aparecer la diferencia; se repone con P1.

### LAB-API-I3. Privilegios exactos: solo `SeChangeNotifyPrivilege`
- **Origen:** ADR-76 con PA-76-1; `ModoServicioApi.PrivilegiosDeclarados` [V `ModoServicioApi.cs:20`].
- **Precondición:** I1 en verde.
- **Pasos:**
  1. `sc.exe qprivs GPOS.Api | Out-File "$E\I3-qprivs.txt"`; extraer los nombres `Se…Privilege`.
  2. Intento de arranque: `$desde=Get-Date; sc.exe start GPOS.Api; Start-Sleep 25; sc.exe query GPOS.Api; Eventos $desde | Out-File "$E\I3-eventos.txt"; ScmEventos $desde`.
  3. **Lectura de la ausencia de 4767:** `@(Eventos $desde | ? { $_.ProviderName -eq 'GPOS.Api' -and $_.Id -eq 4767 }).Count`.
  4. Detener: `sc.exe stop GPOS.Api` (si está en recuperación, `Stop-Service -Force`).
  5. **Control (privilegio de más):** `sc.exe privs GPOS.Api SeChangeNotifyPrivilege/SeCreateGlobalPrivilege`; arrancar y esperar 25 s; leer 4767; detener; `.\Probar-Instalador.ps1 -Caso L-2e -Msi $msi` (hace lo mismo y repara).
  6. **Control (lista vacía):** `sc.exe privs GPOS.Api ""` y arrancar: anotar si el 4767 `ARRANQUE_PRIVILEGIOS` aparece (en `sc`, una lista vacía significa "todos"); reparar con `/fa` y repetir 1.
- **Esperado [I]:** (1) exactamente **un** privilegio, `SeChangeNotifyPrivilege`; (2) el servicio **no** llega a `RUNNING` (falta configuración, MI-06) y el primer fallo es de configuración o del anillo, **sin** 4767; (3) cero 4767; (5) 4767 `ARRANQUE_PRIVILEGIOS: el token tiene privilegios fuera de la lista declarada (SeCreateGlobalPrivilege)`, servicio `STOPPED`; (6) con la lista vacía el token trae los privilegios de la cuenta y la API rechaza con `ARRANQUE_PRIVILEGIOS`; tras `/fa`, un solo privilegio.
- **Rechazo:** (1) lista vacía o con más de uno (**Crítica**); (3) un 4767 `ARRANQUE_IDENTIDAD` (**Alta**: el SID escrito en el MSI y el que calcula el código no coinciden); (5) la API arranca con el privilegio de más (**Crítica**: la comprobación no funciona); (6) la reparación deja la lista vacía o ampliada (**Alta**).
- **Evidencia:** `I3-qprivs.txt`, eventos, `sc query`, texto de los 4767 (revisar que no traiga SID de usuario real ni rutas de perfiles: S-05). **Duración:** 20 min. **Marca:** [I]. **Límite honesto:** este caso no ve el token del proceso vivo; el evento 4770 solo existe con el servicio en `Running` (spike DE-01). **Control:** (5) y (6).

### LAB-API-I4. Recuperación configurada tal como se declaró
- **Precondición:** I1 en verde.
- **Pasos:** `sc.exe qfailure GPOS.Api`; `sc.exe qfailureflag GPOS.Api`.
- **Esperado [I]:** `RESET_PERIOD` = 86400 s; tres acciones `RESTART -- Delay = 60000 milliseconds`; `COMMAND_LINE` vacío; `FAILURE_ACTIONS_ON_NONCRASH_FAILURES : TRUE` (por `FailureActionsWhen=failedToStopOrReturnedError`).
- **Rechazo:** cualquier acción `RUN COMMAND` (**Crítica**: ejecución arbitraria como SYSTEM); `qfailureflag` en FALSE (**Media**: una salida con código ≠ 0 no cuenta); retraso distinto de 60 s (**Baja**).
- **Evidencia:** los dos archivos. **Duración:** 10 min. **Marca:** [V] valores del `.wxs`; [I] el formato de salida. **Control:** `sc.exe failure GPOS.Api reset= 0 actions= ""` y leer: debe cambiar; `/fa` lo restaura (P1).

### LAB-API-I5. Orígenes del Visor de eventos registrados
- **Origen:** L-2bis; blueprint 3.
- **Pasos:** `.\Probar-Instalador.ps1 -Caso L-2bis`; además `Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Application\GPOS.Api' -Name EventMessageFile` y el mismo para `GPOS.Instalacion`; `[System.Diagnostics.EventLog]::SourceExists('GPOS.Api')` y `('GPOS.Instalacion')`; `Test-Path` del archivo expandido.
- **Esperado:** los dos existen; `EventMessageFile` bajo `%WINDIR%` y el archivo presente; `GPOS.EstacionImpresion` **no** existe (es del agente).
- **Rechazo:** falta alguno (**Media**: sin origen no hay 4767/4768/4770 ni 4753 a 4755 en el Visor); `EventMessageFile` fuera de `%WINDIR%` (**Alta**: ruta modificable por un usuario); archivo ausente (**Baja**).
- **Evidencia:** `L-2bis.json` y las dos lecturas. **Duración:** 10 min. **Marca:** [I]. **Control:** en S3 se borra el origen `GPOS.Api` y `L-2bis` debe dar `No cumple`.

### LAB-API-I6. El MSI no escribe entorno, red ni secretos, y su registro no los imprime
- **Origen:** T1-07; MI-N4.
- **Pasos:** (1) `@((Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Services\GPOS.Api').GetValueNames())`. (2) `Get-ChildItem 'C:\Program Files\GPOS NG\Api','C:\ProgramData\GPOS NG' -Recurse -File -EA SilentlyContinue | Select-String -Pattern 'Jwt__Clave','Password=','Reenvio' -List | Select-Object Path`. (3) `Select-String "$E\I1-instalar.log" -Pattern 'Jwt','Password','Pwd=','ConnectionString','Clave' -List | Select-Object LineNumber` (números de línea, no el texto). (4) `Test-Path 'HKLM:\SOFTWARE\GPOS NG\Servidor'`. (5) Propiedades que el registro `/l*v` vuelca: `Select-String "$E\I1-instalar.log" -Pattern 'MsiHiddenProperties' -List`.
- **Esperado:** sin `Environment`; (2) y (3) sin coincidencias en archivos propios del MSI (puede haber coincidencias del texto "Clave" en las DLL de terceros: anotar el archivo y mirar solo si es un `.json`); (4) `False`.
- **Rechazo:** `Environment` presente o clave/cadena en cualquier archivo o en el registro del MSI (**Crítica**).
- **Evidencia:** solo nombres de archivo y números de línea. **Duración:** 15 min. **Marca:** [V] el `.wxs` (sin `RegistryValue`); [I] el resto. **Control:** escribir un archivo de prueba con `Password=centinela` bajo `config\` y comprobar que (2) lo encuentra; sin eso un "sin coincidencias" no demuestra nada. Retirarlo.

### LAB-API-I7. SDDL del objeto de servicio (Q-5) y qué puede hacer cada cuenta
- **Origen:** Q-5 (firmada el 2026-10-22); `L-2f`; MI-05.
- **Pasos:** (1) `.\Probar-Instalador.ps1 -Caso L-2f`. (2) `sc.exe sdshow GPOS.Api | Out-File "$E\I7-sdshow.txt"`; anotar si trae `S:` (P-08: `L-2f` compara todos los grupos entre paréntesis, incluida la SACL). (3) Como `gpos-lab-usuario` (`runas /user:%COMPUTERNAME%\gpos-lab-usuario "powershell.exe -NoProfile"`; solo "permitido"/"denegado"): `Get-Service GPOS.Api`, `sc.exe query GPOS.Api`, `sc.exe qc GPOS.Api` → permitidos; `sc.exe start`, `sc.exe stop`, `sc.exe config GPOS.Api DisplayName= x`, `sc.exe sdset GPOS.Api "D:(A;;GA;;;WD)"`, `sc.exe delete GPOS.Api` → denegados. (4) Administrador **sin elevar**: lo mismo; `query`/`qc` permitidos; `start`/`stop`/`config`/`delete` denegados. (5) Elevado: `sc.exe start GPOS.Api` y `stop` permitidos.
- **Esperado:** DACL igual al firmado (mismas ACE, sin importar el orden); los usuarios solo consultan; `L-2f` en `Cumple` (si sale `No cumple` por la SACL, comparar a mano solo `D:` y anotar el falso negativo).
- **Rechazo:** `BU` o `AU` con alguna de `RP`, `WP`, `DT`, `DC`, `SD`, `WD`, `WO` (**Alta**); el usuario estándar detiene o reconfigura (**Crítica**: cambiar `binPath` es ejecutar código como SYSTEM al reiniciar); `util:PermissionEx` sin aplicar (sdshow de fábrica) (**Alta**).
- **Evidencia:** `sdshow` completo y la tabla permitido/denegado. **Duración:** 25 min. **Marca:** [I] que `PermissionEx` dentro de `ServiceInstall` se aplique con WiX 5.0.2 (la prueba `El_SDDL_del_servicio_del_MSI_es_el_de_Q5` solo compara texto). **Control:** `sc.exe sdset GPOS.Api "D:(A;;GA;;;WD)"` elevado (**solo laboratorio**) y repetir (3): ahora todo permitido; `/fa` lo restaura o no (anotar; es lo que mide P1).

### LAB-API-I8. Carpetas y DACL tras instalar
- **Origen:** ADR-77; T1-08; MI-03.
- **Pasos:** `Dacl` de `%ProgramData%\GPOS NG`, `…\config`, `…\Api` y `C:\Program Files\GPOS NG\Api`; `icacls "$env:ProgramData\GPOS NG\Api" /verify`; `Arbol "$env:ProgramData\GPOS NG"`; `Get-ChildItem` de `Program Files\GPOS NG`.
- **Esperado:** raíz y `config` con `O:SY…(A;OICI;0x1200a9;;;AU)`; `Api` con el SDDL de la sección 2 y el SID de `sc showsid`; **solo** `config` y `Api` bajo la raíz (ni `anillo`, `Licencia`, `temp`, `registros`, `Reportes`); `Program Files\GPOS NG\Api` sin escritura para Usuarios ni Usuarios autenticados (herencia por omisión).
- **Rechazo:** carpeta de otro componente (**Media**: el MSI declara lo que no es suyo); `Api` con ACE para Usuarios o con un SID distinto (**Alta**); escritura de usuarios en `Program Files\GPOS NG\Api` (**Alta**: reemplazo del binario del servicio).
- **Evidencia:** las ACL (`Get-Acl` puede reordenar las ACE o mostrar `FA` como máscara: comparar ACE por ACE antes de concluir). **Duración:** 15 min. **Marca:** [I]. **Control:** `icacls "C:\Program Files\GPOS NG\Api" /grant "*S-1-5-32-545:(OI)(CI)M"` y repetir: debe verse; se restaura con `/fa` (P1) o el punto de control.

### LAB-API-I9. Entrada de Programas y versión
- **Pasos:** `Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' | ? DisplayName -like 'GPOS NG*' | Select DisplayName,DisplayVersion,Publisher,UninstallString`; `Get-AuthenticodeSignature` del `.exe`; `Get-CimInstance Win32_Product` **no** (fuerza una reconfiguración de todos los MSI); en su lugar `Get-Package -Name 'GPOS NG*'` o la entrada anterior.
- **Esperado:** una sola entrada `GPOS NG API`, `Publisher=GSF`, versión = la del `.exe` (I2); el `.exe` `NotSigned` (MSI de laboratorio).
- **Rechazo:** dos entradas (**Media**); versión distinta (**Media**). **Evidencia:** la salida. **Duración:** 5 min. **Marca:** [I]. **Control:** B2 (la versión sale de `bind.FileVersion`).

## 7. Bloque O: comprobación previa de carpetas (O-1)

La acción `GposComprobarCarpetasPrevias` es diferida, corre como SYSTEM justo después de `InstallInitialize` y antes de crear nada; se niega con `25101`/`1603` y **no modifica** una carpeta existente. La fila de `Api\` es `Servicio=GPOS.Api`, `CrearSiFalta=0`; la raíz es la única con `CrearSiFalta=1`.

### LAB-API-O1. Rechazos con el MSI de la API (nueve subcasos)
- **Origen:** P-O1-7.1 a .5 (hechos con el MSI del agente); MI-11.
- **Cómo:** cada subcaso parte de **su propio** estado (restaurar `LAB-140-base-ok`, o dejar el equipo sin instalar y limpiar lo plantado con `rmdir` sin `/s` para uniones). Para la raíz, `Probar-Instalador.ps1 -Caso P-O1-7.1 -Msi $msi` a `.5` corren con este MSI porque `ESTACION=1` es una propiedad ignorada [I; el guion pasa la propiedad y la *feature* de la API se llama `Api`]; si no, a mano con `Msi @('/i',"`"$msi`"") 'O1x'`. Para `Api\` y `config\` la raíz correcta se prepara con una instalación y desinstalación previas (la raíz y `config\` son `Permanent`).
- **Medición común de cada rechazo:** `Estado` (dueño, SDDL y lista de hijos) **antes y después** de la plantada; código y líneas `GposComprobarCarpetasPrevias:` del registro.

| ID | Se planta | Código esperado en el registro |
|---|---|---|
| O1a | Raíz con dueño `gpos-lab-usuario` (`icacls <ruta> /setowner gpos-lab-usuario`) | `DUENO_NO_PERMITIDO` |
| O1b | Raíz como unión (`cmd /c mklink /J "%ProgramData%\GPOS NG" C:\GPOS-LAB\destino-union`) | `PUNTO_DE_REANALISIS`; la unión sigue y su destino no cambió |
| O1c | `Api\` con dueño `BUILTIN\Users` | `DUENO_NO_PERMITIDO` |
| O1d | `Api\` con ACE `Users:(OI)(CI)M` (`icacls … /grant "*S-1-5-32-545:(OI)(CI)M"`) | `ESCRITOR_NO_PERMITIDO` |
| O1e | `Api\` con Modificar para el SID de `NT SERVICE\GPOS.Reportes` (`sc.exe showsid GPOS.Reportes` da el SID aunque el servicio no exista) | `ESCRITOR_NO_PERMITIDO` [I: la fila admite solo el SID de su servicio] |
| O1f | `Api\` como unión | `PUNTO_DE_REANALISIS` |
| O1g | `config\` con `Users` Modificar | `ESCRITOR_NO_PERMITIDO` [I: `config` tiene fila propia, en `GrupoConfigGposNg`] |
| O1h | **Control positivo:** `Api\` con dueño SYSTEM y la DACL exacta del contrato (`Dacl` de I8) | Instala (código `0`) |
| O1i | Un **archivo** llamado `GPOS NG` en `%ProgramData%` | `NO_ES_CARPETA` |

- **Esperado (O1a a O1g, O1i):** código `1603`; error `25101` (`GPOS NG no se instaló: la carpeta [2] no es segura ([3])…`); `GposComprobarCarpetasPrevias:` con el código del cuadro; **no** existe el servicio ni `Program Files\GPOS NG\Api`; la carpeta plantada **idéntica** (dueño, SDDL, hijos). Como el origen `GPOS.Instalacion` todavía no existe en una primera instalación, **no habrá** 4753/4754 en el Visor; el registro del MSI dice "evento 4753 no escrito: el origen GPOS.Instalacion no existe en este equipo".
- **Rechazo:** un subcaso que instala (**Crítica**: el MSI escribió el servicio y la DACL sobre una carpeta que un usuario controla); un rechazo que cambia la carpeta plantada (**Alta**); O1h rechazado (**Media**: el control positivo falla); un código distinto del esperado (**Media**: anotar cuál).
- **Evidencia:** los nueve `.log` y `Estado` antes/después (JSON de `Estado-Ruta`). **Duración:** 40 min (≈ 4 min por subcaso con limpieza). **Marca:** [V] códigos y `25101` (`ComprobacionCarpetasPrevias.cs`); [I] O1e y O1g. **Control:** O1h es el control positivo del bloque.

### LAB-API-O2. Raíz ausente: se crea con el SDDL exacto y el evento 4755 solo si el origen existe
- **Pasos:** (1) `Limpiar` (equipo sin `GPOS NG` en `%ProgramData%`); instalar: `Msi @('/i',"`"$msi`"") 'O2-sinorigen'`; `Dacl` de la raíz; buscar en el registro `4755`. (2) Desinstalar, borrar la raíz a mano (`takeown`/`icacls /reset`/`Remove-Item`), **registrar los orígenes antes**: `[System.Diagnostics.EventLog]::CreateEventSource('GPOS.Instalacion','Application')`; instalar de nuevo: `O2-conorigen`; buscar el evento 4755 en el Visor (`Get-WinEvent … ProviderName 'GPOS.Instalacion' Id 4755`).
- **Esperado:** (1) código `0`; raíz con `O:SYG:SYD:PAI(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICI;0x1200a9;;;AU)`; registro: "evento 4755 no escrito: el origen … no existe"; (2) código `0`, evento 4755 con la huella del SDDL (SHA-256 en hexadecimal minúsculas, no el SDDL).
- **Rechazo:** raíz con otra DACL o dueño (**Alta**); el evento 4755 trae el SDDL completo o un SID de usuario (**Baja**); código ≠ 0 (**Alta**).
- **Evidencia:** SDDL de la raíz, ambos registros, evento 4755. **Duración:** 20 min. **Marca:** [V] el texto; [I] el resto. **Control:** (1) es el control de (2) (mismo resultado con y sin origen salvo el evento).

### LAB-API-O3. La comprobación no corre al desinstalar ni al quitar la *feature*
- **Origen:** `ComprobacionCarpetasPrevias.wxs` (condición `NOT REMOVE ~= "ALL"` y `&Api = 2`); D-3.
- **Precondición:** I1 en verde.
- **Pasos:** (1) plantar una condición insegura **sin tocar lo instalado**: crear `C:\GPOS-LAB\x` no sirve; en su lugar, cambiar el dueño de `…\Api` a `BUILTIN\Users` (`icacls … /setowner`); (2) `Msi @('/x',"`"$msi`"") 'O3-desinstalar'` → debe desinstalar (código `0`); (3) reinstalar tras restaurar el dueño; (4) con la condición insegura de nuevo, `Msi @('/i',"`"$msi`"",'REMOVE=Api') 'O3-quitar-feature'`.
- **Esperado:** (2) código `0` y la desinstalación **no** se bloquea por `25101` (la `GposComprobar…` no aparece con `REMOVE=ALL`); (4) código `0` (o el que el instalador dé a quitar la única *feature*: anotar), sin `25101`.
- **Rechazo:** `25101` al desinstalar (**Alta**: un equipo con la carpeta alterada no se puede desinstalar ni limpiar); la desinstalación crea la raíz (**Media**).
- **Evidencia:** los dos `.log` (buscar `GposComprobarCarpetasPrevias`). **Duración:** 20 min. **Marca:** [V] la condición; [I] el resultado. **Control:** el paso (3), con la condición insegura, **sí** rechaza (instalar sobre ella da `25101`).

### LAB-API-O4. Reparar con una carpeta insegura: se rechaza y no se toca nada
- **Precondición:** I1 en verde.
- **Pasos:** cambiar el dueño de `…\Api` a `BUILTIN\Users`; `Msi @('/fa',"`"$msi`"") 'O4-reparar'`; `Dacl` antes y después.
- **Esperado [I]:** la comprobación corre al reparar (`!Api = 3 AND NOT &Api = 2`); código `1603`, `25101`, **ni el servicio ni los archivos cambiaron**. **Anotar** la consecuencia operativa: un equipo con una carpeta insegura no se puede reparar con el MSI; hay que seguir el procedimiento "Carpeta insegura" de operaciones.
- **Rechazo:** la reparación pasa y deja el dueño ajeno (**Alta**); modifica la carpeta (**Alta**).
- **Evidencia:** `.log`, ACL antes/después. **Duración:** 15 min. **Marca:** [V] la condición; [I] el resultado. **Control:** con el dueño restaurado, la misma reparación da `0` (P1).

### LAB-API-O5. `ADDSOURCE` y `ADVERTISE`
- **Origen:** P-O1-7.8; R-02 de la relectura de #124.
- **Pasos:** raíz con dueño `BUILTIN\Users` (condición insegura). (1) `Msi @('/i',"`"$msi`"",'ADDSOURCE=Api') 'O5-addsource'`. (2) Limpiar. `Msi @('/i',"`"$msi`"",'ADVERTISE=Api') 'O5-advertise'`; luego `Test-Path` de la raíz y `Get-Service GPOS.Api`.
- **Esperado:** (1) la comprobación corre (`&Api = 4`) y rechaza: `1603` con `25101`; (2) `AllowAdvertise="no"`: no crea carpetas ni deja la *feature* publicada; el servicio no existe.
- **Rechazo:** (1) instala (**Alta**); (2) deja carpetas o servicio (**Media**).
- **Evidencia:** los `.log`, `Test-Path`. **Duración:** 15 min. **Marca:** [I]. **Control:** (1) con la raíz sana (sin plantar) instala o falla por otra causa (sin archivos de origen): anotar; si falla por la fuente, el control no sirve y se anota.

### LAB-API-O6. Con la directiva FIPS activa (P-O1-7.7 con el MSI de la API)
- **Origen:** `IdentidadProceso` calcula el SID con SHA-1 (si FIPS lo impidiera, `ARRANQUE_IDENTIDAD`); la acción previa es `net472` y no debe usar `SHA256Managed` (`SHA256CryptoServiceProvider`, `ComprobacionCarpetasPrevias.cs`).
- **Pasos:** tomar `LAB-142-fips` **desde el anfitrión**; `.\Probar-Instalador.ps1 -Caso P-O1-7.7-preparar`; reiniciar; `.\Probar-Instalador.ps1 -Caso P-O1-7.7-ejecutar -Msi <MSI del agente en desarrollo> -ApiMsi $msi`; luego a mano con FIPS activa: instalar (`O6-api`), `Foto 'O6'`, `sc.exe start GPOS.Api`, `Eventos`, `Msi /fa`, `Msi /x`; `Select-String "$E\O6-api.log" -Pattern 'InvalidOperationException','FIPS' -List`. Restablecer con `-Caso P-O1-7.7-restablecer` o restaurar `base`.
- **Esperado:** instalación, reparación y desinstalación con `0`; `Foto` igual a la de I1; al arrancar, **sin 4767** (el rechazo posterior es de configuración); sin `InvalidOperationException` en ningún registro.
- **Rechazo:** `InvalidOperationException` o "algoritmo no permitido" (**Alta**: el MSI no instala en un sitio con FIPS); 4767 `ARRANQUE_IDENTIDAD` (**Alta**).
- **Evidencia:** `P-O1-7.7-*.json`, registros, `Foto`. **Duración:** 40 min (dos reinicios). **Va el último de S-3**: deja la VM sucia. **Marca:** [I]. **Control:** `Fips-Activa` (función del guion) debe ser `True` antes de medir; si es `False`, el caso es `No se pudo`.

## 8. Bloque S: arranque sin configuración y rechazos propios del servicio

### LAB-API-S1. Qué ocurre al arrancar un servicio recién instalado, sin configuración
- **Origen:** `Program.cs` en orden: `ComprobarArranque` → archivo de instalación → `ProtegerClaveJwt` → `ProteccionDatos.Configurar` → `Jwt:Clave` (< 32 caracteres lanza) → `EscuchaServidor.Preparar` [V `Program.cs:30-110`].
- **Objetivo:** fijar el comportamiento correcto solo con el MSI: **no** `Running`; rechazo claro, sin secretos y sin efectos secundarios.
- **Precondición:** I1 en verde. `Arbol "$env:ProgramData\GPOS NG" > "$E\S1-antes.txt"`.
- **Pasos:** `$desde=Get-Date; sc.exe start GPOS.Api; Start-Sleep 30; sc.exe query GPOS.Api; Eventos $desde; ScmEventos $desde`; `Get-NetTCPConnection -State Listen -LocalPort 5071,5073 -EA SilentlyContinue`; `sc.exe stop GPOS.Api` o `Stop-Service -Force` al terminar; listar de nuevo y comparar.
- **Esperado [I]:** no llega a `RUNNING` (SCM 7000/7009/7031 o 1053/1067 según cómo muera); **primer fallo** a anotar (excepción del anillo en Release o `Jwt:Clave`); **cero 4767**; texto de eventos sin cadena de conexión, sin valor de clave y sin rutas de perfiles; sin escucha; **sin carpetas nuevas** bajo `GPOS NG` (el servicio no crea `anillo`, `Licencia`, `temp` ni `registros` antes de validar).
- **Rechazo:** `Running` (**Alta**); un puerto abierto (**Alta**); carpetas nuevas (**Media**); un valor o clave en cualquier evento (**Crítica**); 4767 `ARRANQUE_IDENTIDAD` (**Alta**: SID del MSI ≠ SID del código).
- **Evidencia:** eventos, `sc query`, listados. **Duración:** 20 min. **Marca:** [I]. **Control:** L-04/R3 (la misma conducta tras reinicio).

### LAB-API-S2. Reserva en consola: `GPOS.Api.exe --servicio` fuera del Administrador de servicios
- **Origen:** L-2c; `ModoServicioApi.Decidir`: `ARRANQUE_MODO: se pidió --servicio y el proceso no corre bajo el Administrador de servicios` [V `:171`].
- **Pasos:** consola elevada: `.\Probar-Instalador.ps1 -Caso L-2c -ApiExe 'C:\Program Files\GPOS NG\Api\GPOS.Api.exe'`; confirmar `sc query` antes y después y `Get-Process GPOS.Api -EA SilentlyContinue`.
- **Esperado:** salida 1; el texto en `Console.Error`; ≥ 1 evento 4767; el servicio **no** cambió de estado; no queda proceso vivo.
- **Rechazo:** el proceso queda vivo o escucha (**Alta**); salida 0 (**Alta**).
- **Evidencia:** `L-2c.json`. **Duración:** 10 min. **Marca:** [V] el texto; [I] el resto. **Control:** `GPOS.Api.exe` **sin** `--servicio` en consola no se prueba aquí (arrancaría la API completa como administrador); su rama se cubre en el spike.

### LAB-API-S3. Origen perdido: el 4767 llega por la reserva y la reparación lo restaura
- **Origen:** L-2d. **Precondición:** `LAB-144-sinorigen` tomado.
- **Pasos:** `.\Probar-Instalador.ps1 -Caso L-2d -Msi $msi`; abrir el 4767 en el Visor (¿"no se encuentra la descripción" pero con texto?); `L-2bis` otra vez.
- **Esperado:** sin el origen, el 4767 aparece igual (por `RegistroEventosReserva`); `/fa` devuelve el origen y su `EventMessageFile`.
- **Rechazo:** el evento no aparece (**Media**: diagnóstico ciego); la reparación no restaura (**Media**).
- **Evidencia:** `L-2d.json`, captura de texto del evento (copiar el texto, no pantalla). **Duración:** 15 min. **Marca:** [I]. **Control:** I5 (el origen existe) frente a este caso (no existe).

### LAB-API-S4. Privilegio de más tras instalar
Es la parte de control de I3 (paso 5) ejecutada con `L-2e`. Se mide una sola vez en I3; en S-2 solo se repite si I3 se hizo en un equipo distinto. **Duración:** 15 min si se repite. **Marca:** [I].

### LAB-API-S5. Cuenta distinta de la virtual (L-4 de OPS-API)
- **Pasos:** `$desde=Get-Date; sc.exe config GPOS.Api obj= LocalSystem; sc.exe start GPOS.Api; Start-Sleep 30; sc.exe query GPOS.Api; Eventos $desde; Get-NetTCPConnection -State Listen -LocalPort 5071,5073 -EA SilentlyContinue`; detener; repetir con `obj= "NT AUTHORITY\LocalService"` y `obj= "NT AUTHORITY\NetworkService"`; reparar con `Msi @('/fa',"`"$msi`"")` y `sc.exe qc GPOS.Api`.
- **Esperado:** cada intento: 4767 `ARRANQUE_IDENTIDAD` con el SID real y el esperado, salida 1, sin escucha; **la configuración nunca se lee bajo la cuenta ajena** (la comprobación va primero, `Program.cs:30`); la reparación devuelve `NT SERVICE\GPOS.Api`.
- **Rechazo:** corre con la cuenta ajena (**Crítica**); abre un puerto (**Alta**); la reparación no la devuelve (**Alta**); el 4767 trae un SID de usuario real o una ruta de perfil (**Baja**, S-05).
- **Evidencia:** eventos, `sc qc` tras cada intento. **Duración:** 20 min. **Marca:** [I]. **Control:** el estado inicial `NT SERVICE\GPOS.Api` (I1) es el control; no hay 4767 en I3.

## 9. Bloque R: recuperación del servicio

### LAB-API-R1. Cuántas veces se reinicia un servicio que no logra arrancar (L-01)
- **Objetivo:** responder con medidas si la recuperación es de tres reintentos o ilimitada, y cuánto ruido hace.
- **Precondición:** I1 en verde; servicio detenido; **Registro de eventos de Aplicación con tamaño y retención normales** (anotar `Get-WinEvent -ListLog Application | Select MaximumSizeInBytes,LogMode`).
- **Pasos:** `$desde=Get-Date; sc.exe start GPOS.Api`; cada minuto durante 10 minutos: `Get-Date; sc.exe query GPOS.Api | Select-String 'STATE'; (Get-Process GPOS.Api -EA SilentlyContinue).Id` → `R1-linea.txt`; al final: `ScmEventos $desde | Group-Object Id | Select Count,Name`; `@(Eventos $desde).Count`; `sc.exe stop GPOS.Api` y `Stop-Service -Force` (si está en espera).
- **Esperado [I]:** reinicios aproximadamente a los 60 s y **más allá del tercero** (si el SCM repite la última acción); cantidad de eventos de Aplicación ≈ 1 por intento (excepción del runtime o similar); por 10 min, ≈ 8 a 10 reinicios.
- **Veredicto (no es un cumple/no cumple todavía):** anotar el hecho. Si hay más de tres reinicios: **Media** para operaciones (L-01) y se escala a B/A como decisión, no como defecto del MSI.
- **Rechazo (Alta):** los reinicios son más frecuentes que cada 60 s (un reinicio sin retraso satura el servidor); el servicio deja procesos `GPOS.Api.exe` huérfanos.
- **Evidencia:** `R1-linea.txt`, conteos, tamaño del registro. **Duración:** 25 min. **Marca:** [I]. **Control:** `sc.exe failure GPOS.Api reset= 86400 actions= restart/60000/restart/60000/none/0` y repetir 5 minutos: debe detenerse tras dos reinicios (`none` en el tercero). Sin este control no se sabe si el instrumento distingue las dos configuraciones. Restaurar con `/fa`.

### LAB-API-R2. Una parada ordenada no se reinicia
- **Precondición:** el servicio se puede dejar "iniciado": no ocurre con el MSI solo. **Fixture:** sin configuración, el servicio no llega a `Running`, así que este caso se hace con el servicio de **laboratorio** `GPOS.Api` reconfigurado a `notepad.exe`: **no se hace** (cambia el binario). El caso queda `Bloqueado` hasta que exista configuración mínima (PR-V `implantar-servidor`) o el spike (DE-01), con el servicio en `Running`.
- **Pasos cuando exista:** `Stop-Service GPOS.Api` → debe quedar `STOPPED` sin reiniciar (salida 0 no cuenta como fallo); `Stop-Process -Name GPOS.Api -Force` (fallo real) → reinicia a los ≈ 60 s.
- **Rechazo:** una parada ordenada se reinicia (**Media**); un fallo real no se reinicia (**Alta**).
- **Duración:** 15 min. **Marca:** [?]. **Control:** los dos pasos se controlan entre sí.

### LAB-API-R3. Reinicio del equipo con el servicio `auto` y sin configuración (L-04)
- **Pasos:** con I1 en verde y el servicio detenido: `Restart-Computer`; a los 3 y 8 minutos: `sc.exe query GPOS.Api`, `ScmEventos (Get-CimInstance Win32_OperatingSystem).LastBootUpTime`, `Eventos` desde el arranque.
- **Esperado [I]:** `START_TYPE AUTO_START`; el servicio intenta arrancar al iniciar, falla con el mismo primer fallo que S1 y entra en el bucle de R1; ningún 4767.
- **Veredicto:** observación Media para B (L-04): un servidor recién instalado y reiniciado antes de `implantar-servidor` queda en bucle. Si B decide `demand` hasta la configuración, este caso pasa a "no arranca solo".
- **Rechazo (Alta):** el equipo queda inestable (CPU sostenida del bucle, más de 50 % durante 5 min); el servicio abre un puerto.
- **Evidencia:** `sc query`, conteo de eventos del arranque, `Get-Counter '\Processor(_Total)\% Processor Time'` cada 30 s. **Duración:** 15 min. **Marca:** [I]. **Control:** R1.

### LAB-API-R4. Contador de reinicio de 1 día (opcional)
- **Objetivo:** que el `ResetPeriod` de 86 400 s reinicie el conteo.
- **Pasos:** [I] con `Ajustar-Reloj.ps1` (anfitrión) adelantar el reloj de la VM más de 1 día tras provocar fallos y provocar otro: anotar si se aplica la primera acción de nuevo. Depende de que el cambio de reloj no invalide otros casos; hacerlo **después** de todo lo demás y con punto de control.
- **Esperado:** sin efecto observable distinto si las tres acciones son iguales (L-01): el caso solo tiene sentido si B cambia las acciones (por ejemplo `none` en la tercera). **Duración:** 25 min. **Marca:** [?]. Pregunta Q-3.

## 10. Bloque A: actualizar

**Precondición común:** los **dos** MSI con SHA-256 anotado; el segundo de **versión mayor** construido con `construir.ps1 -Version <x.y.z+1>` (la prueba T1 del MSI de B no lo produce; lo debe entregar B, Q-5). Sembrar centinelas inocuos en la versión 1 (A3). Tomar `LAB-143-v1` con la versión 1 instalada y los centinelas.

### LAB-API-A1. Actualización mayor limpia
- **Pasos:** `Foto 'A1-v1'`; `$desde=Get-Date; Msi @('/i',"`"$msi2`"") 'A1-actualizar'`; `Foto 'A1-v2'`; entradas de Programas; hash del `.exe`.
- **Esperado:** código `0`; una sola entrada `GPOS NG API` con la versión nueva; `sc qc`, `qprivs`, `qfailure`, `sdshow` y `showsid` iguales a v1; servicio `STOPPED` (L-03; **anotar** que una actualización con el servicio en ejecución lo dejaría detenido); hash del `.exe` = el de la versión 2.
- **Rechazo:** dos entradas o dos servicios (**Media**); `sc` distinto de v1 (**Alta**); código ≠ 0 sin revertir (**Alta**: la v1 debe quedar íntegra si la actualización falla).
- **Evidencia:** `Foto` v1/v2 y comparación con `Compare-Object`. **Duración:** 25 min. **Marca:** [I]. **Control:** la `Foto` v1 contra sí misma sin cambios (la comparación no inventa diferencias).

### LAB-API-A2. La configuración del servicio sobrevive a la actualización (L-02)
- **Objetivo:** saber si el valor `Environment` (y la DACL de la clave del servicio) que ponga la implantación se conserva.
- **Precondición:** `LAB-143-v1`. **Sin secretos:** el valor es un centinela.
- **Pasos:**
  1. Fixture (elevado): `$k=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Services\GPOS.Api',$true); $k.SetValue('Environment',[string[]]@('CENTINELA-LAB-NO-SECRETO=1'),[Microsoft.Win32.RegistryValueKind]::MultiString); $k.Dispose()`.
  2. Comprobar sin imprimir el valor: `((Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Services\GPOS.Api').GetValueNames()) -contains 'Environment'` → `True`. Anotar `(Get-Acl 'HKLM:\SYSTEM\CurrentControlSet\Services\GPOS.Api').Sddl` (la DACL de la clave **no** lleva el valor).
  3. Actualizar: `Msi @('/i',"`"$msi2`"") 'A2-actualizar'`.
  4. Repetir la comprobación del paso 2 y la DACL de la clave. Buscar en `A2-actualizar.log` cuántas veces aparece `DeleteService`/`ServiceControl`/`InstallServices` (números de línea).
- **Esperado:** **a decidir con B** (Q-4). Lo que el laboratorio debe contestar: ¿el nombre `Environment` sigue presente tras (4)? ¿La clave del servicio conserva su DACL?
  - Si **no** sigue: L-02 es cierto; la actualización exige reconfigurar y el procedimiento debe decirlo. **Alta** hasta que B/A lo documenten o cambien el MSI.
  - Si sigue: L-02 era falso; **Cumple**.
- **Rechazo (Alta):** se pierde `Environment` sin aviso en el procedimiento. **(Crítica)** si, al contrario, el servicio **hereda** de la instalación anterior un valor o una DACL que el usuario estándar puede leer (la clave no debe quedar legible por Usuarios).
- **Evidencia:** solo `True`/`False`, la DACL de la clave antes y después y las líneas del registro. **Nunca el valor.** **Duración:** 20 min. **Marca:** [I] (efecto de `MajorUpgrade` en el servicio). **Control:** A6/P2 (reparación `/fa` con el mismo valor: el mismo nombre debe seguir presente); si P2 lo borra, el caso A2 no prueba nada específico de la actualización.

### LAB-API-A3. Los datos y la raíz sobreviven a la actualización
- **Precondición:** `LAB-143-v1` con `centinela.txt` en `…\Api\`, en `…\config\` y en la raíz (`Set-Content … 'no borrar'`; solo administradores pueden escribir ahí).
- **Pasos:** A1; después `Arbol` y `Dacl` de la raíz, `config\`, `Api\`.
- **Esperado:** los tres centinelas intactos; DACL de la raíz, de `config\` y de `Api\` iguales a las de I8.
- **Rechazo:** centinela borrado (**Crítica**: pérdida de datos); DACL cambiada (**Alta**). **Evidencia:** listados y ACL. **Duración:** 10 min. **Marca:** [I]. **Control:** el listado anterior a la actualización.

### LAB-API-A4. Degradar se rechaza
- **Pasos:** tras A1: `Msi @('/i',"`"$msi`"") 'A4-degradar'`; `Foto`.
- **Esperado:** código ≠ 0 (1603 o 1638 [I]); en el registro "Ya está instalada una versión más reciente de la API de GPOS NG."; el estado instalado no cambia.
- **Rechazo:** la degradación se instala (**Alta**: abre un camino de retroceso con DACL o esquema anteriores). **Evidencia:** log y `Foto`. **Duración:** 10 min. **Marca:** [V] el texto. **Control:** A1 (subir sí funciona).

### LAB-API-A5. Actualizar con el servicio en ejecución
- **Estado:** **Bloqueado.** El servicio no llega a `Running` con el MSI solo. Se ejecuta cuando exista configuración mínima (spike DE-01 o `implantar-servidor`).
- **Pasos cuando exista:** `Start-Service`, esperar `Running`, `Msi /i v2`; comprobar que `ServiceControl Stop="both" Wait="yes"` lo detuvo; si hay un `Restart Manager` que pide reinicio, el código `3010`.
- **Esperado:** actualiza sin `3010`, queda detenido (L-03). **Rechazo:** `3010` o archivo en uso (**Media**); proceso `GPOS.Api.exe` vivo tras la actualización (**Alta**). **Marca:** [?]. **Duración:** 20 min.

### LAB-API-A6. Misma versión
- **Pasos:** con la v1 instalada, `Msi @('/i',"`"$msi`"") 'A6-misma'`; `Foto`.
- **Esperado [I]:** sin cambios; código `0` o `1638`/`1603` con mensaje de "ya instalada"; el servicio y sus valores iguales.
- **Rechazo:** reinstalación parcial que cambia la cuenta o los privilegios (**Media**); pierde `Environment` (**Alta**, igual que A2). **Evidencia:** log y `Foto`. **Duración:** 10 min. **Marca:** [I]. **Control:** P1 (reparar sí cambia).

### LAB-API-A7. Actualizar con una carpeta insegura
- **Pasos:** con la v1 instalada, cambiar el dueño de `…\Api` a `BUILTIN\Users`; `Msi /i v2`; ACL antes y después.
- **Esperado [I]:** la comprobación corre en la instalación nueva; `1603` con `25101`; **no** quedó una v1 desinstalada y una v2 a medias: la v1 sigue instalada (el rechazo ocurre antes de crear nada nuevo, pero el `MajorUpgrade` puede haber quitado la v1 antes: **anotar el estado**).
- **Rechazo (Alta):** el servicio queda sin instalar (v1 quitada y v2 rechazada). **Evidencia:** `sc query`, entradas de Programas, log. **Duración:** 15 min. **Marca:** [I]. **Control:** con el dueño restaurado, la v2 instala.

## 11. Bloque P: reparar

### LAB-API-P1. `/fa` restaura lo que se alteró
- **Origen:** L-8 de OPS-API; MI-07.
- **Precondición:** `LAB-141-instalado`; `Foto 'P1-base'`.
- **Pasos:** alterar, uno por uno y anotando cada cambio: `sc.exe privs GPOS.Api SeChangeNotifyPrivilege/SeCreateGlobalPrivilege`; `sc.exe config GPOS.Api obj= LocalSystem start= demand`; `sc.exe failure GPOS.Api reset= 0 actions= ""`; `sc.exe sdset GPOS.Api "D:(A;;GA;;;WD)"` (**solo laboratorio**); borrar una `GPOS*.dll` propia de `Api\`; borrar la clave del origen `GPOS.Api`; `icacls "C:\Program Files\GPOS NG\Api" /grant "*S-1-5-32-545:(OI)(CI)M"`. Luego `Msi @('/fa',"`"$msi`"") 'P1-reparar'`; `Foto 'P1-despues'`; `Compare-Object` de `sc-qc`, `qprivs`, `qfailure`, `qfailureflag`, `qsidtype` y `sdshow` contra `P1-base`; `L-2bis`; hash de la DLL.
- **Esperado:** código `0`; restaurados (declarado por `OnReinstall="yes"`): cuenta, tipo de inicio, privilegios, DLL y origen. **Anotar uno por uno** lo que no se restaura: el SDDL del servicio (`PermissionEx` puede no reaplicarse en reparación [I]), la recuperación (`util:ServiceConfig`) y la ACL de `Program Files\GPOS NG\Api` (herencia); no restaurar algo **no** es forzosamente falla, pero cambia la recomendación de operación.
- **Rechazo:** la reparación deja `LocalSystem` o un privilegio sobrante (**Alta**); falla con `1603` sin revertir (**Alta**); cambia la DACL de `Api\` o de la raíz (**Alta**); no restaura el SDDL del servicio y B afirma en operaciones que sí (**Media**).
- **Evidencia:** `P1-base`/`P1-despues`, `Compare-Object`. **Duración:** 20 min. **Marca:** [I]. **Control:** `P1-base` contra una segunda `Foto` sin tocar nada (sin diferencias); y una **segunda** reparación idéntica no produce cambios (idempotencia).

### LAB-API-P2. La reparación no borra la configuración del servicio
- **Precondición:** `Environment` con el centinela (paso 1 de A2).
- **Pasos:** `Msi /fa`; `GetValueNames()` contiene `Environment`; DACL de la clave igual.
- **Esperado [I]:** `ServiceInstall` en reinstalación **modifica** el servicio y no lo borra: `Environment` sigue. **Rechazo (Alta):** se pierde. **Evidencia:** `True`/`False`, DACL. **Duración:** 10 min. **Marca:** [I]. **Control:** retirar `Environment` a mano y comprobar que `GetValueNames()` lo ve ausente.

### LAB-API-P3. Binario alterado: la reparación lo repone
- **Pasos:** reemplazar `GPOS.Api.exe` por una copia con un byte distinto (`Copy-Item` a un temporal, modificar el temporal con `[IO.File]::OpenWrite` solo en el temporal y reemplazar el original en el laboratorio); `Get-FileHash` antes y después; `Msi /fa`; `Get-FileHash`.
- **Esperado:** el hash vuelve al del MSI. **Rechazo (Alta):** la reparación no repone un binario alterado (el instalador no detecta que el servicio corre código modificado). **Evidencia:** los tres hashes. **Duración:** 15 min. **Marca:** [I] (`/fa` reinstala todo; `/fom` solo si falta o es más antiguo). **Control:** el hash del `.exe` alterado ≠ el de I2.

## 12. Bloque D: desinstalar

### LAB-API-D1. Desinstalación limpia
- **Pasos:** `$desde=Get-Date; Msi @('/x',"`"$msi`"") 'D1-desinstalar'`; `sc.exe query GPOS.Api; sc.exe qc GPOS.Api`; `Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Services\GPOS.Api'`; `Test-Path 'C:\Program Files\GPOS NG\Api'`, `…\GPOS NG`; `[System.Diagnostics.EventLog]::SourceExists('GPOS.Api')` y `('GPOS.Instalacion')`; entradas de Programas; `Eventos $desde`; `Get-Process GPOS.Api -EA SilentlyContinue`.
- **Esperado:** código `0`; `sc query` 1060; la clave del servicio **desaparece** (si queda marcada para eliminación, código 1072: reiniciar y anotarlo, no es falla del MSI); `Program Files\GPOS NG\Api` borrada; los dos orígenes retirados; sin entrada en Programas; sin proceso vivo.
- **Rechazo:** servicio o clave que persisten sin 1072 (**Alta**); proceso vivo (**Alta**); orígenes que persisten (**Baja**).
- **Evidencia:** las salidas. **Duración:** 15 min. **Marca:** [I]. **Control:** la `Foto 'I1'` anterior muestra todo presente.

### LAB-API-D2. La desinstalación no borra datos ni la raíz (L-07)
- **Precondición:** D1 con centinelas en la raíz, `config\` y `Api\` (A3), y una subcarpeta `Api\anillo\prueba.txt`.
- **Pasos:** `Dacl` y `Arbol` de la raíz tras D1; `Test-Path` de cada centinela.
- **Esperado:** la raíz y `config\` siguen con la misma DACL (`Permanent="yes"`); `Api\` sigue con los centinelas; si `Api\` estuviera **vacía**, Windows Installer la quitaría (anotar con una variante vacía).
- **Rechazo:** centinela borrado o `anillo\` borrado (**Crítica**: pérdida de la llave de cifrado o de la licencia); raíz o `config\` borradas o con otra DACL (**Alta**).
- **Evidencia:** listados, ACL. **Duración:** 5 min. **Marca:** [V] `Permanent`; [I] el resto. **Control:** la variante con `Api\` vacía (muestra que el MSI sí quita lo suyo).

### LAB-API-D3. Desinstalar con el servicio en ejecución
- **Estado:** **Bloqueado** (igual que A5). Se mide `ServiceControl Stop="both" Wait="yes"` con el servicio `Running`.
- **Rechazo cuando exista:** servicio en `STOP_PENDING` indefinido; `1603`; archivo en uso (**Media**). **Duración:** 15 min. **Marca:** [?].

### LAB-API-D4. Desinstalar con la consola de servicios abierta (servicio "marcado para eliminación")
- **Precondición:** I1 en verde.
- **Pasos:** abrir `services.msc` y dejar seleccionada la fila `GPOS NG: API` (o un `sc.exe` interactivo con un identificador abierto); `Msi /x`; anotar código y mensaje; `sc.exe query GPOS.Api`; cerrar la consola; reiniciar; `sc.exe query`; reinstalar (`Msi /i`).
- **Esperado [I]:** o bien desinstala bien (la consola no retiene el identificador), o código `0` con 1072 (servicio marcado para eliminación) hasta cerrar la consola; **la reinstalación inmediata** falla con "el servicio está marcado para eliminación" (1923) hasta reiniciar.
- **Rechazo:** la reinstalación deja el equipo sin servicio y sin aviso (**Media**: se debe documentar en operaciones); el desinstalador cuelga (**Alta**).
- **Evidencia:** códigos, mensaje, `sc query`. **Duración:** 20 min. **Marca:** [I]. **Control:** D1 (sin consola abierta, limpio).

### LAB-API-D5. Reinstalar tras desinstalar, con `Api\` residual (MI-10)
- **Pasos:** a continuación de D2: `Msi /i`; `Foto 'D5'`; `Dacl` de `Api\`; `Test-Path` del centinela.
- **Esperado:** código `0`; la comprobación previa acepta la carpeta residual (dueño SYSTEM, DACL del contrato con el SID de `GPOS.Api`); `sc showsid` igual que en I1 (el SID es función del nombre); centinela intacto.
- **Rechazo:** `25101` sobre una carpeta que el propio MSI dejó (**Alta**); el centinela desaparece (**Crítica**). **Evidencia:** log, `Foto`. **Duración:** 10 min. **Marca:** [I]. **Control:** O1h.

### LAB-API-D6. Desinstalar desde Programas y con una carpeta insegura plantada
- **Pasos:** (1) `Start-Process msiexec -ArgumentList "/x {ProductCode} /qn /norestart /l*v …"` con el `ProductCode` leído de la entrada de Programas (sin pasar por el archivo `.msi`). (2) Con una condición insegura plantada (dueño de `Api\` a `Users`), repetir: debe desinstalar (O3).
- **Esperado:** `0` en ambos. **Rechazo:** (1) pide el `.msi` original (**Baja**); (2) `25101` (**Alta**, ver O3). **Evidencia:** logs. **Duración:** 15 min. **Marca:** [I]. **Control:** O3.

## 13. Bloque N: negativos de seguridad

### LAB-API-N1. Instalar como usuario estándar y como administrador sin elevar
- **Pasos:** N1a: `runas /user:%COMPUTERNAME%\gpos-lab-usuario "msiexec.exe /i C:\GPOS-LAB\msi\GPOS.Api-SINFIRMA.msi /qn /norestart /l*v C:\GPOS-LAB\evidencia\API\N1a.log"` (el usuario necesita leer el MSI y escribir el registro). N1b: PowerShell **no** elevado con administrador: `Msi @('/i',"`"$msi`"") 'N1b'`.
- **Esperado:** falla por privilegios (código 1925 u otro ≠ 0 [I]); `Get-Service GPOS.Api -EA SilentlyContinue` vacío; no existen `Program Files\GPOS NG`, `ProgramData\GPOS NG` ni los orígenes.
- **Rechazo (Crítica):** algo queda instalado o creado. **Evidencia:** logs y listados. **Duración:** 15 min. **Marca:** [I]. **Control:** I1 elevado instala.

### LAB-API-N2. Instalar sin `/qn` desde la interfaz no oculta un fallo
- **Pasos:** `msiexec /i $msi` interactivo con una condición insegura plantada; leer el cuadro de diálogo.
- **Esperado:** el cuadro muestra el error 25101 en español con la ruta y el código; botón Aceptar; `1603`. **Rechazo (Baja):** mensaje sin la ruta. **Duración:** 5 min. **Marca:** [V] el texto del error. **Control:** O1.

### LAB-API-N3. Servicio `GPOS.Api` preexistente (el DEMO y el MSI son excluyentes)
- **Precondición:** `base`. Fixture que imita al DEMO: `sc.exe create GPOS.Api binPath= "C:\Windows\System32\notepad.exe" start= demand`; escribir un valor `Environment` **centinela** (como en A2).
- **Pasos:** `Msi @('/i',"`"$msi`"") 'N3'`; `Foto 'N3'`; `GetValueNames()`; hash/ruta del binario en `sc qc`.
- **Esperado [I]:** o bien el MSI **falla con un mensaje claro** y el servicio ajeno queda intacto, o bien se apropia: reconfigura `binPath`, cuenta y privilegios. Anotar **lo que ocurre de verdad**.
- **Rechazo:** el MSI se apropia del servicio **conservando** el valor `Environment` o una DACL de clave que no puso él (en el DEMO ese valor trae la clave K3): **Alta**; el MSI falla y deja la raíz o las carpetas creadas (**Media**).
- **Evidencia:** solo nombres de valores, `sc qc`, log. **Duración:** 15 min. **Marca:** [I] (blueprint de A, riesgo RT1-9). **Control:** I1 con servicio inexistente.

### LAB-API-N4. Propiedades públicas: que no se pueda redirigir lo instalado
- **Origen:** S-05 del contrato de Ids privados (con minúsculas) [V en el `Package.wxs`].
- **Pasos:** cada una por separado, desde `base` o desinstalando: `Msi @('/i',"`"$msi`"",'DirApiPrograma=C:\GPOS-LAB\fuera\') 'N4a'`; `'DIRAPIPROGRAMA=C:\GPOS-LAB\fuera\'` (N4b); `'DirApiDatos=C:\GPOS-LAB\fuera2\'` (N4c); `'TARGETDIR=D:\'` (N4d); `'INSTALLFOLDER=C:\GPOS-LAB\fuera3\'` (N4e: no existe); `'ProgramFiles64Folder=C:\GPOS-LAB\fuera4\'` (N4f); `'ALLUSERS=2'` (N4g). Después de cada una: `sc.exe qc GPOS.Api` (BINARY_PATH_NAME) y `Dacl` de `C:\GPOS-LAB\fuera*`; limpiar con `/x` o punto de control.
- **Esperado [I]:** el `BINARY_PATH_NAME` es siempre `"C:\Program Files\GPOS NG\Api\GPOS.Api.exe" --servicio`; las carpetas `fuera*` no se crean; `TARGETDIR` no cambia dónde van los archivos de `Program Files`; `ALLUSERS=2` no baja la instalación a un usuario (`Scope="perMachine"`).
- **Rechazo:** el servicio apunta a una carpeta donde un usuario estándar puede reemplazar el binario (**Crítica**: escalada a SYSTEM al reiniciar); la carpeta de datos se redirige (**Alta**).
- **Evidencia:** `sc qc` y existencia de las carpetas `fuera*`. **Duración:** 20 min. **Marca:** [I]. **Control:** N4b/N4e usan nombres que no son propiedades privadas ni existentes: sirven de control de que el instrumento muestra "sin efecto"; para el instrumento positivo, `Msi /i` sin propiedades da la ruta normal.

### LAB-API-N5. Paquete alterado
- **Pasos:** copiar el MSI, cambiar un byte en la zona del `.cab` incrustado (`MediaTemplate EmbedCab="yes"`) en la **copia**, y `Msi @('/i',"`"copia.msi`"") 'N5'`; además, el MSI de laboratorio sin firma frente al de producción firmado: `Get-AuthenticodeSignature`.
- **Esperado [I]:** falla con error de paquete dañado (1620, 1603 o similar) y **no deja nada instalado**. **Rechazo (Alta):** instala parcialmente (servicio sin archivos). **Evidencia:** log, `sc query`. **Duración:** 10 min. **Marca:** [I]. **Control:** el MSI original instala (I1).

### LAB-API-N6. Convivencia con la estación de impresión (raíz compartida, MI-13)
- **Origen:** `RaizGposNg.wxs` (GUID fijos, `Permanent`); la estación usa el origen `GPOS.EstacionImpresion`, no `GPOS.Instalacion` [V].
- **Pasos:** (1) instalar la estación de desarrollo (`Msi @('/i','"C:\GPOS-LAB\msi\GPOS.AgenteImpresion-DESARROLLO.msi"','ESTACION=1') 'N6-estacion'`); `Dacl` de la raíz. (2) Instalar la API: debe aceptar la raíz creada por la estación. (3) Desinstalar la API (D1) y comprobar que la estación sigue instalada y que la raíz y `config\` conservan la DACL. (4) Reinstalar la API, desinstalar la estación y repetir. (5) Orden inverso: API primero, luego estación.
- **Esperado:** los cuatro movimientos con `0`; la `Sddl` de la raíz idéntica en cada paso; sin carpetas de otro componente. Anotar el efecto en la estación de retirar `GPOS.Instalacion` (los eventos 4753 a 4755 de la estación dejan de verse hasta reinstalar la API, porque ese origen es de este MSI).
- **Rechazo:** cambio de DACL o de dueño de la raíz (**Alta**); el MSI de una pieza borra la raíz (**Alta**).
- **Evidencia:** `Dacl` en cada paso y los logs. **Duración:** 30 min. **Marca:** [?] (depende de que el MSI de desarrollo del agente siga siendo compatible). **Control:** el movimiento (1) es el control de los demás (misma DACL de partida).

### LAB-API-FIR-1. MSI firmado con un certificado de laboratorio (F-1)
- **Estado:** **Bloqueado.** `construir.ps1 -Firmar` exige `signtool` y el SDK de Windows, que no constan en la imagen de `VM-SRV`, y la compilación completa no corre en la VM (la VM queda sin Internet). Para que F-1 tenga sentido hay que decidir **dónde se firma** (Q-6).
- **Pasos cuando exista un `.msi` firmado:** `Probar-Instalador.ps1 -Caso F-1-certificado`; `-Caso F-1-verificar -Msi <msi firmado> -Archivos <exe y GPOS*.dll>`; instalar el MSI firmado (`I1`) y comprobar 25101/4755 como en O1/O2 (RT1-7: la firma de la `.CA.dll` exterior no cambia la carga); `-Caso F-1-retirar`.
- **Esperado:** `signtool verify /pa /tw` correcto en el `.exe`, las `GPOS*.dll`, la `.CA.dll` y el `.msi`; el MSI firmado instala. **Rechazo:** un archivo propio sin firma (**Media**); el MSI firmado no instala (**Alta**).
- **Duración:** 30 min. **Marca:** [?]. **Control:** F-1 con una huella inexistente falla (B3).

## 14. Plantilla de evidencia y criterio de recomendación

Una carpeta por sesión en `C:\GPOS-LAB\evidencia\API\` (se recoge con `Recoger-Evidencia.ps1 -Vm VM-SRV -CarpetaInvitado C:\GPOS-LAB\evidencia`) con los `.json` de `Probar-Instalador.ps1`, los `.log` de MSI, las carpetas `Foto`, las ACL, los eventos y esta tabla (misma cabecera de mis casos anteriores y de `revision-evidencia.md`):

| Campo | Valor |
|---|---|
| VM y fecha | |
| Punto de control de partida | |
| Commit de la rama (`c7c6c95a` u otro) y SHA-256 de cada MSI y script | |
| Versión de Windows (UBR); FIPS sí/no; edición de SQL | |
| Caso → resultado (`Cumple` / `No cumple` / `No se pudo` / `Bloqueado`) con el control medido | |
| Hallazgos (severidad, pasos, esperado, obtenido) | |
| Técnico | |

**Revisión de la evidencia (la hago yo con `tests/laboratorio-adr090/revision-evidencia.md`):** procedencia (cabecera, SHA-256 del MSI igual al copiado, punto de control de partida); guardas (`Guardas: cumplidas`, G-N1 a G-N4 en la sesión de preparación); **secretos** (ningún valor de `Environment`, ninguna cadena de conexión ni clave en logs de MSI, eventos o JSON; solo nombres de valores y `True`/`False`); resultado de cada caso recalculado a mano en los de severidad Crítica o Alta (I1, I3, I7, O1, A2, N1, N3, N4); un `No se pudo` o `Bloqueado` nunca cuenta como `Cumple`.

**Severidades de laboratorio.**
- **Crítica:** un secreto legible por un usuario estándar o impreso en evidencia; el servicio corre con una cuenta o un privilegio no previsto; un usuario estándar reconfigura el servicio o el binario; una instalación sobre una carpeta que controla un usuario; pérdida de datos (centinela, anillo, licencia).
- **Alta:** un rechazo modifica la carpeta plantada; el MSI deja `Environment` o se apropia de un servicio ajeno (N3); SID del MSI ≠ SID del código (S1); la actualización o la reparación rompen la configuración del servicio (A2, P2); el MSI no instala en un sitio con FIPS.
- **Media:** lo que no se autorrepara (P1); observaciones de operación de L-01, L-03 y L-04 si B las acepta tal cual; un caso `No se pudo` por entorno incompleto.
- **Baja:** textos, tiempos, avisos.

**Recomendación técnica (la decisión es de B y del propietario):** *Rechazado* si queda algún hallazgo Crítico o Alto; *Aprobado con observaciones* si solo hay Media o Baja o casos `Bloqueado`; *Aprobado* solo con todos los casos ejecutables en `Cumple` y sus controles medidos.

## 15. Preguntas (dudas)

| # | Pregunta | Para |
|---|---|---|
| Q-1 | ¿Se confirman las fechas? Pidieron estos casos antes del 13-nov y la VM de B está prevista del 16 al 27-nov; ¿hay ventana para tres sesiones de ≈ 4 h (sección 4)? ¿Quién opera cada una? | B / propietario |
| Q-2 | Los puntos de control deben cumplir `LAB-\d{2,3}[a-z]?…`. ¿Se reserva **LAB-140 a LAB-149** para este bloque? (Mis `LAB-T1B-*` y `LAB-SPIKE*` del 23-oct no pasan el patrón; el spike necesita su propio bloque.) | B |
| Q-3 | **L-01:** ¿la recuperación "reiniciar tres veces a los 60 s" debe repetirse sin límite (como el SCM hace con la última acción) o la tercera acción debe ser `none`? Si es lo previsto, ¿lo escribe operaciones? R4 solo tiene sentido si cambia | B / A |
| Q-4 | **L-02:** ¿qué debe conservar una actualización del MSI? Si `MajorUpgrade` borra y recrea el servicio, ¿el procedimiento dice "volver a ejecutar `implantar-servidor`" o el MSI debe mantener `Environment` y la DACL de la clave (por ejemplo con otro calendario del `MajorUpgrade`)? | A / B |
| Q-5 | ¿B entrega junto al MSI el `publicacion.sha256` (I2) y un segundo MSI de versión mayor construido con `construir.ps1 -Version` (A1)? Sin ellos I2 y todo el bloque A quedan `No se pudo` | B |
| Q-6 | ¿Dónde se firma para FIR-1? La imagen de `VM-SRV` no trae `signtool` ni el SDK y no tiene Internet. ¿Se firma en la PC de B con un certificado de laboratorio cuyo `.cer` se importa a la VM, o FIR-1 queda para cuando haya certificado real? | B / A |
| Q-7 | **L-04:** ¿`Start="auto"` hasta que se mida L-15, o `demand` hasta que `implantar-servidor` lo pase a `auto`? (Hoy un servidor reiniciado antes de configurarse entra en bucle.) | B |
| Q-8 | **L-03:** tras actualizar o reparar el servicio queda detenido. ¿La cadena de implantación lo arranca o el técnico? ¿Va escrito en el procedimiento? | B / A |
| Q-9 | **O4:** una carpeta insegura impide reparar y actualizar (1603), no solo instalar. ¿Es lo previsto? El procedimiento "Carpeta insegura" de operaciones, ¿cubre reparación y actualización? | A |
| Q-10 | Los casos A5, D3 y R2 necesitan el servicio en `Running`. ¿Se pueden ejecutar dentro del spike DE-01 (que sí lo deja en `Running`) en la sesión del 23-nov, para no repetir la VM? | B / A |

## 16. Qué no verifiqué

- **Nada se ejecutó:** ni MSI, ni servicio, ni `sc`, ni los guiones, ni SQL, ni VirtualBox, ni `construir.ps1`. Todo valor [I] (códigos de `msiexec` como 1925, 1638, 1620 y 1923; que el SCM repita la última acción de recuperación; que `MajorUpgrade` borre y recree el servicio; que `PermissionEx` se aplique al servicio y se reaplique en reparación; el valor de `qfailureflag`; la conducta de `ServiceInstall` ante un servicio preexistente; el SID `S-1-5-80-546908902-…`) es conocimiento general o cálculo de A, no comprobado aquí ni contra la documentación del fabricante.
- **No leí `GPOS.Instalador.Acciones` línea por línea ni los vectores `adr077-carpetas.v3.json`:** los códigos de rechazo vienen de `ComprobacionCarpetasPrevias.cs` y del procedimiento de A; que `config\` tenga fila propia lo tomo del comentario de `ComprobacionCarpetasPrevias.wxs` y de `GrupoConfigGposNg`; O1e y O1g son [I].
- **No leí `Inicializacion.cs`, `CarpetaAnillo.cs`, `AlmacenLicenciaDisco.cs` ni `ProteccionDatos.cs`:** el "primer fallo" de S1 es inferencia del orden de `Program.cs`.
- **No vi los textos de operaciones de A (OPS-API)** en el repositorio (siguen en `traspasos/A/` según el blueprint); cito los de L-1 a L-16 por el blueprint y por el guion `Probar-Instalador.ps1`.
- **No revisé las pruebas de `ApiInstaladorTests.cs` por dentro** más allá de los nombres y de T1-09. No sé si el MSI de B pasa la suite oficial ni si hay un PR abierto de `b/t1b-api-msi`.
- **Duraciones y reparto en sesiones:** mis estimaciones, sin experiencia de ejecución en esta VM.
- **No verifiqué** que el `Package.wxs` compile con WiX 5.0.2 (`Files`, `PermissionEx` en `ServiceInstall`): lo pregunta el propio comentario del archivo y lo contesta B2/I2/I7.

### Cierre
- Estado: Completado (casos redactados; ninguno ejecutado)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-23-casos-laboratorio-gpos-api-msi.md`
- Supuestos: los de la sección 16; el MSI es el de `origin/b/t1b-api-msi` @ `c7c6c95a`; si B lo cambia, los valores de la sección 2 cambian; fechas de VM sin confirmar.
- Decisiones candidatas a ADR: Ninguna (L-02 y Q-3 pueden terminar en una precisión de ADR-76 o del procedimiento de actualización; las redacta el arquitecto-maestro si B las adopta).
- Entregas a otros agentes: B → Q-1, Q-2, Q-5, Q-6, Q-7, Q-8 y operar la VM; A/B → Q-3, Q-4 y Q-9 (L-01, L-02, O4); C (yo) → revisar la evidencia redactada con `revision-evidencia.md` cuando B la entregue.
- Próximo paso recomendado: que B y A respondan Q-3 y Q-4 antes de la VM; L-02 puede cambiar el diseño del `MajorUpgrade`.
