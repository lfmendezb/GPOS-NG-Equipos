```
Para: B        De: C        Fecha: 2026-10-24
Tipo: Entrega (tanda 8, punto 9 de B-a-C/2026-10-23-tareas-nuevas-para-c-tanda-8: plan del laboratorio del spike DE-01)
Prioridad: Alta (la VM de B está prevista del 16 al 27-nov; el spike, el 23-nov, sin confirmar por el propietario)
Repositorio y rama: GPOS-NG `origin/feature/modelo-ng` @ `1b310591` (solo lectura, `git show`) y `origin/c/guiones-gpos-api-msi` @ `9f297ad8` (PR #226); área común `traspasos/C/`
Estado: Abierto (casos redactados; nada compilado ni ejecutado)
```

# Plan del laboratorio del spike DE-01 (modo Amplio, 23-nov): casos, evidencia, sesiones y reparto VM-SRV / VM-PUESTO

**Qué es.** El plan de laboratorio del spike que decide D-2 y D-4: ¿la API principal arranca y atiende como servicio de Windows con `NT SERVICE\GPOS.Api`, en modo Amplio, con DPAPI de usuario y con el esquema migrado por `GPOS.Migracion`? Parte de lo ya unido (#173: `Probar-Spike-Amplio.ps1` y `docs/operaciones/2026-10-22-spike-demo-modo-amplio.md`), de mi revisión del #173 (P-01 a P-11, en `2026-10-23-casos-laboratorio-t1b-y-revision-173.md`), de mis casos del `GPOS.Api.msi` (`2026-10-23-casos-laboratorio-gpos-api-msi.md`, con A5, D3 y R2 «Bloqueados» y la pregunta Q-10), del guion del PR #226 y de los casos L-1 a L-4 de T4-03 (`2026-10-23-casos-laboratorio-l1-l4-t4-03.md`). **No se compiló ni se ejecutó nada** (OSHIN-LEGION no tiene VirtualBox y la regla del 2026-10-08 impide tocar servicios fuera de la VM).

**Marcas.** [V] verificado leyendo un archivo (ruta); [I] inferido o conocimiento general de Windows, SQL, Chromium o WiX, por confirmar en la VM; [?] depende de algo que aún no existe o que B/A deben decidir.

**Estados de un caso en la VM.** `Cumple` · `No cumple` · `No se pudo` (la precondición no existía) · `Bloqueado` (no ejecutable hoy). `No se pudo` y `Bloqueado` **nunca** cuentan como `Cumple`. **Un caso sin su control no puede dar `Cumple`**: el control es la misma medición con el mecanismo apagado o alterado, y demuestra que el instrumento ve la diferencia.

## 0. Resumen para decidir

1. **Respuesta a Q-10 (A5, D3 y R2 dentro del spike): sí, pero no dentro del servicio que crea el guion.** `DE-01-preparar` crea el servicio con `sc create` (caso `DE-01-preparar` de `Probar-Spike-Amplio.ps1`), no con el MSI. Sobre ese servicio, **A5 y D3 no se pueden correr** (miden `ServiceControl Stop="both"` y el `MajorUpgrade` del MSI, que no instaló ese servicio; instalar el MSI encima sería el caso N3) y **R2 mediría a `sc`, no al MSI** (el spike pone `restart/restart/restart`, el MSI de `1232d0af` pone `restart/restart/none`). Lo que sí cabe es una **segunda rama** de la misma sesión: se restaura el punto de control previo a la creación del servicio, se instala `GPOS.Api.msi` v1 y se le da la configuración del spike (entorno, SQL, anillo). Así A5, D3 y R2 corren sobre el servicio real del MSI con el servicio en `Running`. Eso exige **un cambio chico en el guion** (`-ServicioDelMsi`, ≈ 0,25 dp [I]; lo puedo escribir yo) y **no entra en el veredicto D-2**, que sale solo de la rama pura (sección 4).
2. **Treinta y un casos o subcasos** en cinco bloques: preparación (1), spike (DE-01 y DE-10 a DE-16: 8), negativos del spike (9), Chromium de la principal con lo aplicable de T4-03 (5) y MSI con el servicio vivo (8), más la lista de revisión de la evidencia. Cada uno con precondición, pasos, esperado, rechazo con severidad, evidencia sin secretos, duración, marca y control. Lo de T4-03 que **no cabe** en el spike (L-1a/b, L-1e, L-2c, L-4a/b) queda fuera, con el motivo (sección 9).
3. **Tres hallazgos de lectura previos a la VM** (sección 3): **SP-01** `DE-12` termina siempre en `No se pudo` (código de salida 3) porque `render` no existe en el spike; **SP-02** si `SetAccessControl` de la clave del servicio lanza excepción, el guion deja el valor `Environment` con la DACL por omisión (¿lectura para Usuarios?) en el registro; **SP-08** la principal lanza Chromium **sin canalización** (`ConvertidorPdf.cs:73-74`, sin `Pipe`), así que probablemente deja un **puerto de depuración local** que un usuario estándar puede alcanzar con la cuenta del servicio como dueña del navegador: es un hallazgo candidato **Alto** que el spike puede confirmar sin explotarlo (SPK-C3).
4. **Duración [I, ±50 %]:** ≈ 11 h en tres sesiones (3 h 20 + 4 h 25 + 3 h 25). Si solo cabe una ventana de 4 h, el orden por riesgo está en la sección 5.
5. **Lo que el spike no puede cerrar**, por diseño: `--fase esquema` y el veredicto del verbo de PR-V (DE-11-verbo, DE-14-verbo), 5073 (no hay API de reportes), `render` y la rotación de token (sin sonda funcional, P-10). Quedan `Bloqueado` o `No se pudo`, nunca verdes.
6. **Dudas para B/A:** 12 preguntas (sección 13); las que cambian el calendario son Q-1, Q-3, Q-6 y Q-9.

## 1. Fuentes y estado del código

**Leído en esta entrega (todo `git show`, ningún árbol de trabajo tocado):**
- `origin/feature/modelo-ng` @ `1b310591`: `tests/laboratorio-adr090/invitado/Probar-Spike-Amplio.ps1` completo (incluye P-01, P-02, P-05, P-06 y P-07 ya aplicados por A: commits `b90a1747` y `f37af1df`), `docs/operaciones/2026-10-22-spike-demo-modo-amplio.md`, `tests/laboratorio-adr090/revision-evidencia.md`, `src/GPOS.Api/Impresion/ConvertidorPdf.cs` (la principal: `RutasConocidas` en `:17-25`, perfil en `Path.GetTempPath()` en `:66`, `LaunchOptions` en `:70-75`, sin `Pipe`, sin `Dispose` de perfiles) y `src/GPOS.Api/Program.cs:341` (`AddSingleton<ConvertidorPdf>`).
- `origin/c/guiones-gpos-api-msi` @ `9f297ad8` (PR #226): `LEEME.md` del laboratorio y `invitado/Probar-GposApiMsi.ps1` (funciones `Caso-R1`, `Caso-R4`, `Caso-A1`, `Caso-A2`, `Caso-Bloqueado`, constantes), conforme al MSI de `b/t1b-api-msi` @ `1232d0af` (recuperación `restart, restart, none`, `Start="auto"`, `MajorUpgrade afterInstallExecute`).
- Mis entregas: casos del MSI, T1-b y revisión del #173, L-1 a L-4 de T4-03, revisión adversarial del #218 (`2026-10-23-revision-adversarial-msi-pr218.md`: H218-01, H218-05.4, H218-09).
- A: `plan-demo-con-api-de-reportes-2026-10-22.md` (secciones 2.2.1 a 2.2.4: cerrojos, escalera SQL, ciclo de vida de la clave, SDDL), `docs/operaciones/2026-10-21-operaciones-gpos-api-servicio.md` (L-4, L-11 y L-15).

**Estado [V] que cambia mis casos del 23-oct:**
- P-01 (entorno del anillo), P-02 (carpeta `Api\anillo`), P-05 (casos sin precondición en `No se pudo`, código de salida 3), P-06 (`-EscaleraConDbcreator`) y P-07 (texto de DE-13): **atendidos** en el guion unido.
- **Siguen sin atender** P-03 (orden entorno / DACL de la clave: `SetValue` del entorno antes de `SetAccessControl` de la clave, en el mismo caso), P-04 (no registra los orígenes de eventos), P-10 (espera fija de 20 s y `salud` como única sonda), P-11 (`config` cerrado o vector v3). Además aparecen SP-01 a SP-10 (sección 3).
- El guion crea el servicio con `start= demand`, `sc privs SeChangeNotifyPrivilege` y `sc failure … restart/60000 ×3`, **sin** `sdset`, **sin** `sidtype` y con el `ImagePath` en `app\api\GPOS.Api.exe` del paquete del DEMO. Es otro servicio que el del MSI en recuperación, SDDL y ruta.

## 2. Reglas heredadas, puntos de control y funciones de apoyo

**Reglas** (las de mis casos previos y las de `revision-evidencia.md`, sin discusión):
1. Solo en `VM-SRV` (y `VM-PUESTO` donde se diga) de `LFMB`, desde `base`. Nunca en la PC del propietario, en OSHIN-LEGION ni en la PC de A. Lo opera B; yo reviso la evidencia ya redactada.
2. Un punto de control por bloque; al terminar, `Restaurar base -Apagar`. Si algo falla **no se corrige a mano para que pase**: se anota (ruta, código, SID, texto del evento) y se restaura.
3. **Prohibido** para la cuenta virtual `sysadmin`, `CONTROL SERVER`, `securityadmin`, `serveradmin`, `ALTER ANY LOGIN` e `IMPERSONATE` «para ver si arranca»: si solo funciona con alguno es **FALLA del spike**; se anota el error y se escala (plan 2.2.2, punto 4).
4. **Sin secretos en la evidencia.** La clave JWT la genera el guion en proceso y no se ve nunca. Prohibidos: `reg query` y `reg export` de `HKLM\SYSTEM\CurrentControlSet\Services\GPOS.Api`; `Get-ItemProperty` de esa clave sin `-Name`; imprimir `Get-Item` de la clave (solo `.GetValueNames()`); capturas de la pestaña *Environment* de Process Explorer o System Informer; poner la clave en una línea de comandos. En los negativos que cambian el entorno se usa la cadena centinela `CLAVE-DE-LABORATORIO-NO-SECRETA-0000000000000000`, nunca la clave generada.
5. Una sola corrida a la vez en `LFMB` y ninguna suite compilando durante la ventana. L-4 de T4-03 se vuelve inestable con carga; aquí la regla protege además los tiempos de recuperación (60 s).
6. Cada `msiexec` con `/l*v`. Sin el MSI instalado no existe el origen `GPOS.Instalacion`.
7. **Un caso del spike no sustituye una comprobación del paquete ni un verbo de PR-V**: los verdes son del servicio que se probó (sección 4).

**Puntos de control (patrón `LAB-\d{2,3}[a-z]?(-L)?(-[a-z0-9]{1,20})?`, `Comun-Laboratorio.ps1:56`).** Reservo **LAB-150 a LAB-159** para este plan (mis LAB-140 a LAB-149 son del MSI; Q-2):

| Nombre | Cuándo | Qué sale de él |
|---|---|---|
| `LAB-150-sql-listo` | Tras SPK-P0 (paquete extraído, paso 0 hecho, orígenes, sin servicio `GPOS.Api`, sin `%ProgramData%\GPOS NG\Api`) | Rama pura (sección 4) y rama del MSI |
| `LAB-151-spike-verde` | Solo si DE-01 dio `Running` + 200 | Negativos DE-01-N*, Chromium y DE-16 |
| `LAB-152-msi-configurado` | Rama del MSI: MSI v1 instalado y configurado por el spike, **nunca arrancado** | A5, R2/R4, D3/D5, R3 (cada uno restaura este punto) |

**Funciones de apoyo** (Windows PowerShell 5.1 elevado, una vez por sesión; se suman a `Msi`, `Foto`, `Eventos` y `ScmEventos` de mis casos del MSI):

```powershell
$E = 'C:\GPOS-LAB\evidencia\SPK'; New-Item -ItemType Directory -Force $E | Out-Null
$Svc = 'GPOS.Api'
function Procesos-Api  { Get-CimInstance Win32_Process -Filter "Name='GPOS.Api.exe'" | Select-Object ProcessId,ParentProcessId,CreationDate }
function Navegadores   { Get-CimInstance Win32_Process -Filter "Name='chrome.exe' OR Name='msedge.exe'" | Select-Object ProcessId,ParentProcessId,Name,CommandLine }  # la línea no trae entorno
function Dueno($p)     { (Invoke-CimMethod -InputObject (Get-CimInstance Win32_Process -Filter "ProcessId=$p") -MethodName GetOwner) | Select-Object Domain,User }
function Escuchas      { Get-NetTCPConnection -State Listen | Select-Object LocalAddress,LocalPort,OwningProcess | Sort-Object LocalPort }
function Env-Presente  { @((Get-Item "HKLM:\SYSTEM\CurrentControlSet\Services\$Svc" -EA SilentlyContinue).GetValueNames()) -contains 'Environment' }   # nunca imprime el valor
function Sddl-Clave    { $k=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SYSTEM\CurrentControlSet\Services\$Svc"); try{$k.GetAccessControl().GetSecurityDescriptorSddlForm('All')}finally{$k.Close()} }  # solo la DACL
function Linea-Tiempo([int]$seg,[int]$cada,[string]$arch){ $fin=(Get-Date).AddSeconds($seg); while((Get-Date) -lt $fin){ '{0:HH:mm:ss}  {1}  pid={2}' -f (Get-Date),((& sc.exe query $Svc | Select-String 'STATE').ToString().Trim()),((Procesos-Api).ProcessId -join ',') | Add-Content $arch; Start-Sleep $cada } }
function Salud         { try{ (Invoke-WebRequest -UseBasicParsing 'http://127.0.0.1:5071/api/salud' -TimeoutSec 10).StatusCode }catch{ 'sin respuesta' } }
```

## 3. Estado del #173 hoy: hallazgos de lectura previos a la VM

Severidad = efecto sobre la **validez del laboratorio** (SP-08, sobre la operación, la califica el auditor de A). No corrijo nada.

| # | Sev. | Observación | Evidencia | Qué pido / qué caso lo mide |
|---|---|---|---|---|
| SP-01 | Media | `DE-12` incluye `render` entre las carpetas críticas (`-in 'render','anillo'`) y en el spike `render` no existe (lo crea la API de reportes): **siempre** devuelve `No se pudo` y el guion sale con código 3. No es un fallo de la sesión; hay que anotarlo para que nadie lo lea como regresión | `Probar-Spike-Amplio.ps1` (caso `DE-12`: `$faltan`) [V] | A: separar `render` en «no aplica sin API de reportes» o aceptar el 3 esperado. Lo anota **DE-12** |
| SP-02 | **Alta** (laboratorio) | La clave del servicio queda protegida **después** de escribir `Environment` y sin `try/catch`: si `SetAccessControl` falla (el dueño `O:SY` suele exigir `SeRestorePrivilege`, no activado [I]; ya lo anoté como P-03), el guion aborta con la clave JWT recién escrita bajo la DACL por omisión de la clave de un servicio. Si esa DACL concede lectura a Usuarios [I], la clave real quedó legible por `gpos-lab-usuario` | `Probar-Spike-Amplio.ps1`, caso `DE-01-preparar` (orden de `SetValue` y `SetAccessControl`) [V]; DACL por omisión [I] | A: crear → DACL → comprobar → escribir (plan 2.2, orden obligatorio), o al menos borrar `Environment` si la DACL falla. Lo mide **DE-10** (control de la DACL por omisión, SPK-P0 paso 7) y se anota en DE-01 paso 5 |
| SP-03 | Media | Sin los orígenes `GPOS.Api` y `GPOS.Instalacion` no hay 4767/4768/4770 en el Visor; `DE-01-probar` usa `-notcontains 4767` (vacío si el origen no existe) y la cuenta virtual no puede registrarlos. Es P-04, sigue abierto | `DE-01-probar` [V] | Registrarlos a mano en SPK-P0 (desviación declarada). En la rama del MSI los registra el instalador |
| SP-04 | Media | `DE-01-probar` arranca con `Start-Service … -ErrorAction SilentlyContinue`, espera 20 s fijos y da `Cumple` con `Running` + 200 + «sin 4767». `salud` 200 no prueba anillo, licencia ni base (P-10) | `DE-01-probar` [V] | Repetir tras 60 s antes de `No cumple`; sonda funcional (Q-5): hoy se hace a mano (inicio de sesión del DEMO) |
| SP-05 | Media | `DE-16-retirar` borra `Environment`, ejecuta `sc delete` y no distingue un servicio instalado por el MSI. En la rama del MSI hay que retirar con `msiexec /x` (D3), no con el guion: de lo contrario el MSI queda registrado sin servicio | `DE-16-retirar` [V] | No usar `DE-16-retirar` en la rama del MSI |
| SP-06 | Media | El paso 8 del procedimiento («reiniciar la VM y comprobar que el servicio **no** arranca solo, `start= demand`») es cierto solo en la rama pura: el MSI de `1232d0af` trae `Start="auto"` | `sc create … start= demand` [V]; `Start=auto` del MSI [V, LEEME #226] | La rama del MSI lo mide como R3 con servicio configurado (SPK-R3) |
| SP-07 | Baja | `DE-11` recibe `-UsuarioInstala` pero resuelve su SID con `NTAccount`; sin el prefijo del equipo puede no traducir `gpos-lab-usuario` [I]. Con el SDDL de fábrica el caso sale `No se pudo` | `Probar-Spike-Amplio.ps1` (caso `DE-11`) [V] | Pasar `-UsuarioInstala "$env:COMPUTERNAME\gpos-lab-usuario"` |
| SP-08 | **Alta** (candidata; la califica el auditor de A) | La principal lanza Chromium con PuppeteerSharp **sin `Pipe`** (`Args = --disable-gpu --no-first-run --disable-extensions --disable-dev-shm-usage`); sin canalización el protocolo de depuración va por un **puerto TCP local** [I: el valor por omisión de la biblioteca]. Reportes sí usa `Pipe = true` (`src/GPOS.Reportes.Api/Impresion/ConvertidorPdf.cs`, R-T403-04 de mi L-3a). Si el puerto existe, cualquier proceso local alcanza un navegador que corre como `NT SERVICE\GPOS.Api`. Además el perfil va a `GetTempPath()` (no se borra) y el entorno completo se hereda | `src/GPOS.Api/Impresion/ConvertidorPdf.cs:66,70-75` [V]; el puerto es [I] | **SPK-C3** (solo conexión TCP, ningún comando de depuración) y **SPK-C2**. Escalar a A (auditor-seguridad) antes de la VM si se quiere decidir si el DEMO publica con ese render |
| SP-09 | Media | La recuperación del spike (`restart ×3`) difiere de la del MSI (`restart, restart, none`): un negativo que hace fallar el arranque deja un bucle de reinicios cada 60 s que **contamina la ventana de eventos del caso siguiente** | `DE-01-preparar` (`sc failure … restart/60000 ×3`) [V] | Cada negativo termina con `Stop-Service -Force` y un `$desde` propio; ver sección 8 |
| SP-10 | Baja | Un `SDDL` de la clave comparado con `-ceq` contra `O:SYG:SYD:P(A;CI;KA;;;SY)(A;CI;KA;;;BA)`: `GetSecurityDescriptorSddlForm('All')` puede añadir `S:` o reordenar [I]; un falso `No cumple` | `Probar-Spike-Amplio.ps1` (caso `DE-10`) [V] | Si sale `No cumple`, comparar a mano solo `O:`, `G:` y `D:` antes de concluir (DE-10) |

## 4. Diseño: dos ramas con el mismo SQL, y qué decide cada una

```
base ── SPK-P0 ── LAB-150-sql-listo ─┬─ RAMA PURA (decide D-2/D-4)
                                      │    DE-01 ── LAB-151-spike-verde ── DE-10 … DE-15 ── Chromium ── negativos ── DE-16
                                      │
                                      └─ RAMA DEL MSI (no decide D-2; cierra Q-10)
                                           MSI v1 ── configurar (-ServicioDelMsi) ── LAB-152-msi-configurado
                                           ├─ M1 token vivo
                                           ├─ A5 actualizar con el servicio en Running (restaurar 152 al terminar)
                                           ├─ R2 → R4 (parada ordenada, 3 fallos) (restaurar 152)
                                           ├─ D3 → D5 (desinstalar en Running, reinstalar con anillo residual) (restaurar 152)
                                           └─ R3 reinicio con el servicio configurado
```

**Por qué dos ramas y no una.** (a) El veredicto D-2 («el DEMO pasa a dos servicios, sí o no») debe depender solo de lo que el DEMO va a hacer: `implantar-servidor` crea el servicio con la cuenta virtual, no con el MSI. Si la rama del MSI fallara por un defecto del MSI, no debe contaminar a D-2. (b) Lo que el MSI deja distinto (SDDL de Q-5, recuperación con `none`, `Start=auto`, ruta en `Program Files`) es justamente lo que A5, D3, R2 y R3 necesitan. (c) El costo de la segunda rama es poco: reaprovecha el SQL, el esquema y el paso 0 desde `LAB-150`, y el servicio solo cambia de quién lo crea.

**Respuesta a Q-10, en una tabla:**

| Caso | Dentro del servicio del guion (`sc create`) | Dentro del servicio del MSI configurado con el spike |
|---|---|---|
| A5 actualizar con el servicio `Running` | No ejecutable: el MSI no lo instaló (sería N3) | **Sí** (SPK-A5) |
| D3 desinstalar con el servicio `Running` | No ejecutable (igual) | **Sí** (SPK-D3) |
| R2 parada ordenada frente a fallo real | Se puede, pero mide a `sc` y la tercera acción es `restart`, no `none` | **Sí** (SPK-R2, con R4) |
| A2 (`Environment` sobrevive a la actualización) | No aplica | **Sí, y mejor**: con el entorno **real** el arranque posterior prueba que sobrevivió, sin centinela |
| D2/D5 (el anillo real sobrevive a la desinstalación) | No aplica | **Sí** (SPK-D3 y SPK-D5) |

**El cambio de guion que pide la rama del MSI (≈ 0,25 dp [I]; lo escribo yo si B lo confirma, Q-3):** `Probar-Spike-Amplio.ps1 -Caso DE-01-preparar -ServicioDelMsi` debe (1) exigir que el servicio exista, con `Argumentos=--servicio`, cuenta `NT SERVICE\GPOS.Api` y el `ImagePath` del MSI; (2) **no** ejecutar `sc create`, `sc privs` ni `sc failure`; (3) **no** reaplicar la DACL ni el dueño de `Api\` (la fijó el MSI con dueño SYSTEM; el guion pone dueño Administradores y cambiaría lo que A5/D5 y la comprobación O-1 deben ver); (4) crear solo `Api\anillo` si falta (hereda); (5) escribir el entorno y la DACL de la clave **en el orden correcto** (SP-02); y (6) rechazar `-ServicioDelMsi` si el servicio existe pero no coincide con el MSI (no «adopta» un servicio ajeno).

## 5. Secuencia de sesiones y reparto VM-SRV / VM-PUESTO

**Duraciones [I, ±50 %]**, sin contar la publicación del DEMO ni la compilación de los MSI:

| Sesión | Fecha propuesta (sin confirmar) | VM | Contenido, en este orden | Tiempo |
|---|---|---|---|---|
| **S-1** | 23-nov, mañana | `VM-SRV` sola | SPK-P0 (50) → `LAB-150-sql-listo` → DE-01 con escalera (75) → `LAB-151-spike-verde` → DE-10 (10) → DE-11 (20) → DE-12 (15) → DE-14 (20) → DE-15 local (10) | ≈ 3 h 20 |
| **S-2** | 23-nov, tarde (desde `LAB-151`) | `VM-SRV` + `VM-PUESTO` | DE-13 (40) → SPK-C1 (30) → SPK-C2 (20) → SPK-C3 (20) → SPK-C4 (25) → SPK-C5 (45, con `VM-PUESTO`) → DE-15 remoto (10) → negativos DE-01-N1 a N6 (60, cada uno desde `LAB-151`) → DE-16 (15, al final) | ≈ 4 h 25 |
| **S-3** | 24-nov (o el día que B tenga) | `VM-SRV` sola, desde `LAB-150` | M0: MSI v1 + configurar (40) → `LAB-152-msi-configurado` → SPK-M1 (15) → SPK-A5 (35) → SPK-R2 y SPK-R4 (30) → SPK-D3 (25) → SPK-D5 (30) → SPK-R3 (30) | ≈ 3 h 25 |

**Reparto entre las dos VM.**

| Qué necesita | `VM-SRV` (`192.168.50.10`, Server 2025) | `VM-PUESTO` (`192.168.50.20`, Windows 11) |
|---|---|---|
| Servicio, SQL Express, paquete del DEMO, Edge/Chrome, System Informer | Todo | Nada |
| Cuenta estándar `gpos-lab-usuario` | Sí (DE-10 a DE-12, SPK-C3, SPK-C5 fila 3) | No |
| Oyente TCP en el 8099 (imagen externa del render, SPK-C5) | No | **Sí** (regla de entrada en el perfil de la red interna: `Preparar-Vm.ps1` no toca el cortafuegos) |
| DE-15 «desde otro equipo»: `Test-NetConnection 192.168.50.10 -Port 5071` debe fallar | Escucha | **Sí** (sustituye a la variante con la IP propia de `VM-SRV`, que Windows puede tratar como bucle [I]) |
| `auditpol` de «Filtering Platform Connection» (evento 5157) | Sí (SPK-C5) | No |

`VM-PUESTO` solo se enciende en S-2 y en la parte final de DE-15. Pregunta de memoria de `LFMB` (Q-9): mi regla de «una VM a la vez» no aplica a SPK-C5; si no caben las dos juntas, SPK-C5 queda `No se pudo` y DE-15 remoto se hace con la IP `.11` de `VM-SRV`, **solo orientativo** (un «no sale» no concluye, un «sale» sí).

**Si B solo da una ventana de 4 h**, por riesgo: SPK-P0, DE-01, DE-10, DE-13, DE-14, DE-15, DE-01-N3, DE-01-N4a, DE-01-N5; después, si queda tiempo, M0 y A5. El resto queda `No se pudo`, anotado. Sin DE-01 en verde no se corre nada de S-2.

## 6. Bloque P: preparación

### SPK-P0. Preparación específica del spike y control de la DACL por omisión
- **Precondición:** `VM-SRV` desde `base`; `Preparar-Vm.ps1 -Comprobar` todo en `OK`; Windows Server 2025; FIPS no; red interna sin salida; sin servicio `GPOS.Api`; SQL Express arrancado.
- **Pasos:**
  1. Copiar a `C:\GPOS-LAB`: `Probar-Spike-Amplio.ps1`, `Probar-Instalador.ps1`, `Probar-GposApiMsi.ps1` y `Get-MsiTabla.ps1` (rama B), con su SHA-256. Anotar el commit del guion.
  2. Paquete del DEMO publicado con `Publicar-PaqueteDemo.ps1` desde `feature/modelo-ng` **en un commit que incluya #174 y PR-4**, extraído en `C:\GPOS-LAB\paquete\GPOS-Demo`; anotar `version.json` y su SHA-256. Sin `-ConApiReportes`.
  3. `.\Probar-Spike-Amplio.ps1 -Caso Guardas` debe imprimir `Guardas: cumplidas`; repetir con `Probar-Instalador.ps1 -Caso Guardas`.
  4. `Get-Service 'MSSQL$SQLEXPRESS'` en `Running`; Edge presente (`Get-Package`/`(Get-Item "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe").VersionInfo.ProductVersion`), System Informer copiado, y **un solo navegador** a la vez (si hay Chrome, la principal usa Chrome primero: `RutasConocidas`).
  5. Registrar los orígenes (desviación declarada, SP-03): `[System.Diagnostics.EventLog]::CreateEventSource('GPOS.Api','Application')` y `('GPOS.Instalacion','Application')`.
  6. Paso 0 de la escalera 1 (cuenta administradora): `GPOS.Migracion sistema --login-api "NT SERVICE\GPOS.Api"` y el esquema de la empresa de demostración (`actualizar`/`crear`; la fase `--fase esquema` es de PR-V, **Bloqueado**). Anotar los códigos de salida y, con `sqlcmd`, `SELECT name FROM sys.server_principals WHERE name = N'NT SERVICE\GPOS.Api'` y la pertenencia a `gpos_api` en `GPOS_SYSDATA`.
  7. **Control de la DACL por omisión (DE-10, SP-02):** `sc.exe create GPOS.LabSonda binPath= "C:\Windows\System32\cmd.exe" start= demand`; `(Get-Acl 'HKLM:\SYSTEM\CurrentControlSet\Services\GPOS.LabSonda').Sddl` → guardar; `sc.exe delete GPOS.LabSonda`. Solo la DACL, nunca valores.
  8. Crear `gpos-lab-usuario` (estándar; el técnico teclea la contraseña). Tomar `LAB-150-sql-listo`.
- **Esperado [I salvo lo marcado]:** guardas cumplidas; los dos orígenes creados; el login existe y `gpos_api` también; códigos de salida del paso 0 en `0`; la DACL por omisión de la clave de un servicio nuevo **trae una ACE de lectura para `BUILTIN\Users`** (lo que justifica el orden DACL → valor del plan 2.2).
- **Rechazo:** una guarda no se cumple (se detiene todo: **Alta**, el guion no debe correr); paso 0 con código ≠ 0 (el caso DE-01 pasa a `No se pudo` con ese error, **no** a `No cumple`); la DACL por omisión **no** concede lectura a Usuarios (informativo: SP-02 baja a Media, se anota); paquete sin `version.json` o con SHA-256 distinto del anotado (**Media**, procedencia).
- **Evidencia:** SHA-256 de guiones y paquete, `version.json`, códigos de salida, SDDL de la clave de `GPOS.LabSonda` (solo DACL), versiones de Edge/Chrome y de Windows (UBR), edición de SQL. Sin cadenas de conexión.
- **Duración:** 50 min. **Marca:** [V] guardas y comandos; [I] DACL por omisión y salida del paso 0.
- **Control:** el paso 7 es el control de DE-10 (sin él, «no hay ACE de Usuarios» no demuestra que el guion cambió algo); `Guardas` frente a G-N1 a G-N4 de mi entrega del 23-oct (ya corridos en la sesión del MSI; si esta sesión es otra VM, repetirlos, 10 min).

## 7. Bloque DE: el spike

### DE-01. La principal arranca como servicio con `NT SERVICE\GPOS.Api`, modo Amplio y DPAPI de usuario
- **Origen:** plan 2.2.2 y 2.2.3; D-2 y D-4.
- **Objetivo:** responder D-2 y D-4 midiendo el **primer** escalón de la escalera que funcione.
- **Precondición:** `LAB-150-sql-listo`; Windows PowerShell 5.1 elevado; sin servicio `GPOS.Api`; sin `%ProgramData%\GPOS NG\Api`.
- **Pasos:**
  1. `Foto 'DE-01-antes'` (servicio inexistente: `sc query` 1060). Es el control de que el guion crea lo que se ve después.
  2. `.\Probar-Spike-Amplio.ps1 -Caso DE-01-preparar -Paquete C:\GPOS-LAB\paquete\GPOS-Demo -Instancia '.\SQLEXPRESS'`. Si lanza excepción, **ver SP-02**: borrar `Environment` (`DE-16-retirar`), anotar el mensaje literal, restaurar `LAB-150` y dar `No se pudo`.
  3. A mano: `Foto 'DE-01'`; el `ImagePath` debe ser `"…\app\api\GPOS.Api.exe" --servicio` (las comillas anidadas de PowerShell 5.1 son un punto a confirmar, SPV §7.3); `sc qprivs` con solo `SeChangeNotifyPrivilege`; `sc qsidtype`; `sc sdshow`; `Env-Presente` → `True`; `Sddl-Clave`.
  4. `$desde = Get-Date; .\Probar-Spike-Amplio.ps1 -Caso DE-01-probar`. Si no sale `Running` con 200, **esperar 60 s y repetir** `Start-Service` y la sonda antes de concluir (SP-04).
  5. Eventos de Aplicación (`Eventos $desde`, con 5130, 4745, 4767, 4768 y 4770) y del Administrador de servicios (`ScmEventos $desde`: 7000, 7009, 7011, 7023, 7031, 7034).
  6. **Escalera.** Si el paso 4 falla por permisos SQL, anotar el texto exacto del error y la base/operación; solo entonces subir **un** escalón y repetir 4: escalera 2 (`db_owner` solo en `GPOS_SYSDATA` y las `GPOS_*` del DEMO), escalera 3 (`dbcreator`, solo si el DEMO crea empresas desde la interfaz; luego correr DE-14 con `-EscaleraConDbcreator`). Todo lo demás está prohibido.
  7. **Sonda funcional manual (P-10):** desde Edge en la VM, abrir la Web del DEMO, iniciar sesión y abrir la lista de empresas. Anotar sí/no.
  8. **DPAPI y perfil (D-4):** `Get-ChildItem "$env:ProgramData\GPOS NG\Api\anillo" -Filter key-*.xml | Select-Object Name,Length,LastWriteTime`; `Select-String … -Pattern 'DPAPI' -List | Select-Object Filename` (solo nombres, nunca el contenido); `Test-Path 'C:\Windows\ServiceProfiles\GPOS.Api'`.
  9. Rama pura: `Restart-Computer` y comprobar que el servicio **no** arranca solo (`start= demand`, SP-06).
  10. Tomar `LAB-151-spike-verde` solo si el servicio está `Running`, `salud` 200 y el paso 7 en sí.
- **Esperado [I]:** `Running`, 200 en `http://127.0.0.1:5071/api/salud`, sin 4767; el evento crítico 5130 (`IdentidadAmplia`) en cada arranque de Amplio es **esperado**, no falla; 4745 «sin modo» como aviso; anillo con llaves cifradas con DPAPI; escalera 1 o 2 bastan; `ImagePath`, cuenta y privilegios como se dijo.
- **Rechazo / clasificación:**
  - **FALLA del spike (escalar a B y al propietario):** solo funciona con un rol de la lista prohibida; no arranca ni con la escalera 3 (**Crítica** para la decisión: alternativa (b) de la HOJA, congelar el DEMO en `demo/2026-10-15`).
  - **FALLA de D-4:** `GPOS.Migracion` (cuenta del administrador) y la API (cuenta virtual) no se abren el anillo o la fila `Licencia.InstalacionId` (**Alta**: es lo que motivó DM-07). Anotar el mensaje.
  - **No cumple por entorno** (**Media**, no decide D-2): excepción por falta de `DpapiDemo`/anillo/orígenes. Corregir el entorno (A) y repetir.
  - Un secreto, cadena de conexión o la clave en cualquier salida (**Alta**: la carpeta no se publica).
- **Evidencia:** `DE-01-preparar.json`, `DE-01-probar.json`, `DE-01\` de `Foto`, eventos de Aplicación y del Sistema, **la tabla de la escalera** (qué escalón funcionó primero) y el error literal de cada escalón que falló. Solo nombres de valores.
- **Duración:** 75 min (hasta 90). **Marca:** [I].
- **Control:** DE-01-N3 (sin `Jwt__Clave`, el mismo `DE-01-probar` **no** da `Running` + 200); sin ese negativo, `salud` 200 no demuestra que el entorno sea la causa.

### DE-10. Un usuario estándar no lee el valor `Environment` de `GPOS.Api`
- **Origen:** DM-01. **Precondición:** `DE-01-preparar` hecho.
- **Pasos:** (1) `.\Probar-Spike-Amplio.ps1 -Caso DE-10`. (2) A mano, elevado: `Sddl-Clave` (solo la DACL). (3) Como `gpos-lab-usuario`: `try { $k=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Services\GPOS.Api'); if($k){'PERMITIDO (abre la clave)'; $k.Close()} else {'clave inexistente'} } catch { 'DENEGADO: ' + $_.Exception.GetType().Name }`; **no** `Get-ItemProperty` ni `reg query`. (4) **Control de sensibilidad** (desde `LAB-151`): dar a `BUILTIN\Users` ReadKey con `Set-Acl` sobre la clave y repetir el paso 1: debe salir `No cumple`; restaurar el punto de control. (5) Después de `DE-01-probar`: el servicio sigue `Running` con la DACL protegida.
- **Esperado:** SDDL `O:SYG:SYD:P(A;CI;KA;;;SY)(A;CI;KA;;;BA)` (marca `P`, sin Usuarios ni Todos); el usuario estándar «DENEGADO»; el control sale `No cumple`.
- **Rechazo:** una ACE de lectura para otro SID (**Crítica**: la clave JWT, legible por un usuario estándar); el estándar abre la clave (**Crítica**); la DACL protegida impide arrancar (**Alta**, hallazgo para A: el Administrador de servicios necesita SYSTEM). Si el SDDL difiere solo por `S:` o el orden (SP-10): comparar a mano `O:`, `G:`, `D:` antes de concluir.
- **Evidencia:** SDDL (solo DACL), la salida de «PERMITIDO/DENEGADO», el JSON. **Duración:** 10 min. **Marca:** [I].
- **Control:** el paso 4 y el SDDL por omisión de SPK-P0 paso 7.

### DE-11. Quien instala inicia y detiene el servicio, pero no lo reconfigura
- **Origen:** DM-09; plan 2.2.4. **Estado:** el guion no concede nada (el verbo de PR-V lo hará). El veredicto del **verbo** es DE-11-verbo, **Bloqueado** por PR-V.
- **Precondición:** `LAB-151`; `gpos-lab-usuario` creada.
- **Pasos:** (1) **Línea base negativa** con el SDDL de fábrica, como `gpos-lab-usuario` y como Administrador **sin elevar**: `sc.exe start`, `sc.exe stop` y `sc.exe config GPOS.Api DisplayName= x` → los tres denegados (error 5); anotar `sc.exe sdshow` completo. (2) **Fixture del técnico** (no sustituye la prueba del verbo): `$sid = (New-Object System.Security.Principal.NTAccount("$env:COMPUTERNAME\gpos-lab-usuario")).Translate([System.Security.Principal.SecurityIdentifier]).Value` y, elevado, `sc.exe sdset GPOS.Api "D:(A;;CCLCSWRPWPDTLOCRSDRCWDWO;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCRPWPLORC;;;$sid)"`. Como `gpos-lab-usuario`: `stop`, `start` y `query` permitidos; `config … DisplayName= x`, `config … binPath= C:\Windows\System32\cmd.exe` y `sdset … "D:(A;;GA;;;WD)"` denegados. (3) `.\Probar-Spike-Amplio.ps1 -Caso DE-11 -UsuarioInstala "$env:COMPUTERNAME\gpos-lab-usuario"` (SP-07). (4) Restaurar `LAB-151`.
- **Esperado:** (1) todo denegado; (2) iniciar, detener y consultar permitidos; los tres cambios denegados; (3) `Cumple` solo con la ACE del paso 2.
- **Rechazo:** el usuario puede `config`, `sdset` o `delete` (**Crítica**: cambiar `binPath` es ejecutar código como SYSTEM al reiniciar); el estándar sin ACE inicia con el SDDL de fábrica (**Alta**).
- **Evidencia:** `sdshow` completo (con la SACL si existe) y la tabla permitido/denegado. **Duración:** 20 min. **Marca:** [I].
- **Control:** la línea base (1) frente al fixture (2): sin el cambio de comportamiento entre ambos, el instrumento no discrimina. **No confundir** con el SDDL del MSI (Q-5), que es otro a propósito.

### DE-12. Un usuario estándar no lista ni lee `Api\anillo` (ni `render` ni `config`)
- **Origen:** DM-10 y DM-11. **Matiz de A (P-11):** `config` hereda la raíz de ADR-77 (lectura para Authenticated Users, vector v3); lo decide B.
- **Precondición:** `DE-01-preparar` hecho (la carpeta `Api\anillo` existe, P-02).
- **Pasos:** (1) `.\Probar-Spike-Amplio.ps1 -Caso DE-12`; **se espera código de salida 3 y `No se pudo`** por `render` ausente (SP-01); mirar `existe` de cada carpeta. (2) Como `gpos-lab-usuario`, para `Api\anillo`, `config` y, si existe, `Reportes\render`: `try { $null = Get-ChildItem -LiteralPath $r -Force -ErrorAction Stop; "$r : PERMITIDO" } catch [System.UnauthorizedAccessException] { "$r : DENEGADO" } catch { "$r : $($_.Exception.GetType().Name)" }`; y la lectura de un archivo dentro de `anillo` (`Get-Content -TotalCount 0`, solo «permitido/denegado»). (3) `Get-Acl` (Sddl) de las tres. (4) **Control de sensibilidad:** `icacls "$env:ProgramData\GPOS NG\Api\anillo" /grant "*S-1-5-32-545:(OI)(CI)R"`, repetir el paso 2: ahora «PERMITIDO»; deshacer o restaurar.
- **Esperado:** `anillo` denegado, sin ACE para Usuarios ni Authenticated Users, dueño SYSTEM/Administradores, escritura solo para SY, BA y la cuenta del servicio; `config`: **permitido** (vector v3) hasta que B decida otra cosa; `render`: `No se pudo` (DE-12-render, **Bloqueado**).
- **Rechazo:** `anillo` accesible a un estándar (**Crítica**: llaves de cifrado); el control de sensibilidad no lo detecta (**Alta**, el instrumento no vale).
- **Evidencia:** la tabla permitido/denegado y las SDDL. **Duración:** 15 min. **Marca:** [I]. **Control:** el paso 4.

### DE-13. El Chromium hijo de la principal no hereda `Jwt__Clave` ni `Jwt:Clave`
- **Origen:** DM-04; hoy la retirada existe (`ModoServicioApi.RetirarClaveJwtDelEntorno` y `ProtegerClaveJwt`, #174, con las dos grafías, JWT-01 [V]).
- **Precondición:** `LAB-151`; **un** navegador (Edge o Chrome); System Informer (o Process Explorer) **como administrador**; un formato personalizado que se pueda imprimir a PDF desde la API principal (Q-7).
- **Pasos:**
  1. **Control de validez de la técnica** (sin la clave): `$env:GPOS_LAB_CENTINELA='presente'; Start-Process notepad.exe` y ver la variable en la pestaña *Environment*: si no se ve, la técnica no sirve y el caso es `No se pudo`.
  2. Proceso `GPOS.Api.exe` → *Environment*: anotar **solo** si `Jwt__Clave` o `Jwt:Clave` están presentes. **Sin capturas de esa pestaña.**
  3. Generar el PDF desde la interfaz de la Web del DEMO; localizar el hijo (`Get-CimInstance Win32_Process | Where-Object { $_.Name -match 'msedge|chrome' -and $_.ParentProcessId -eq (Get-Process GPOS.Api).Id }`) y repetir la anotación presente/ausente (el hijo vive unos segundos: abrirlo rápido, o con un formato lento).
  4. `.\Probar-Spike-Amplio.ps1 -Caso DE-13` (cuenta hijos; **siempre `No se pudo`**, no decide).
  5. Variante: servicio con `Jwt:Clave` (dos puntos, centinela, DE-01-N4b con modo `Amplio`) y repetir 2 y 3.
- **Esperado:** ausente en el proceso de la API y en el hijo; control del paso 1 con el centinela presente.
- **Rechazo:** presente en cualquiera de los dos (**Alta**: la clave llega a un proceso que carga contenido controlado por el usuario). `No se pudo` si el PDF no se genera (sandbox, TEMP no escribible, navegador ausente): anotar el error y el evento; no es verde.
- **Evidencia:** solo «presente/ausente», PID, nombre y línea de comandos del hijo (sin entorno). **Duración:** 40 min. **Marca:** [I].
- **Control:** el paso 1 (la herramienta ve una variable que sí está) y la variante del paso 5.

### DE-14. `TRUSTWORTHY OFF` y sin roles de servidor
- **Origen:** DM-03. **Precondición:** `LAB-151`; cuenta de Windows administradora con `sysadmin` (solo lectura).
- **Pasos:** (1) `.\Probar-Spike-Amplio.ps1 -Caso DE-14` (con `-EscaleraConDbcreator` solo si la escalera llegó al escalón 3, P-06). (2) A mano, solo lectura: dueños y `is_trustworthy_on` de las `GPOS_*` (el dueño debe ser `sa` en las de empresa); roles de servidor de `NT SERVICE\GPOS.Api`; permisos de servidor (esperado: solo `CONNECT SQL`); roles de base en cada `GPOS_*` (según la escalera: `gpos_api` o `db_owner`); **efectivo a través de grupos (SPV-07):** `EXECUTE AS LOGIN = N'NT SERVICE\GPOS.Api'; SELECT IS_SRVROLEMEMBER('sysadmin'), HAS_PERMS_BY_NAME(NULL, NULL, 'CONTROL SERVER'); REVERT;` (esperado `0` y `0`; el guion no lo mide). (3) **Control de sensibilidad:** `ALTER DATABASE [GPOS_SYSDATA] SET TRUSTWORTHY ON;`, repetir el paso 1 → `No cumple`; volver a `OFF`. Segundo control con una cuenta **que no es la virtual**: `CREATE LOGIN [<EQUIPO>\gpos-lab-usuario] FROM WINDOWS; ALTER SERVER ROLE dbcreator ADD MEMBER …` y la consulta de roles con ese nombre debe devolver `dbcreator`; luego `DROP LOGIN`. Restaurar `LAB-151` al terminar.
- **Esperado:** `is_trustworthy_on = 0` en todas; roles de servidor de la cuenta vacíos (o solo `dbcreator` si la escalera llegó al 3); `sysadmin = 0`.
- **Rechazo:** `TRUSTWORTHY ON` (**Alta**); cualquier rol de servidor distinto de `dbcreator` o `dbcreator` sin que la escalera lo justifique (**Alta**); `IS_SRVROLEMEMBER('sysadmin') = 1` (**Crítica**).
- **Evidencia:** nombres de bases, roles y permisos (sin cadenas de conexión). **Duración:** 20 min. **Marca:** [I]. **Control:** el paso 3. **Dependencia:** DE-14-verbo (`comprobar-servidor` de PR-V) queda **Bloqueado**.

### DE-15. 5071 solo escucha en loopback (y 5073 queda sin medir)
- **Origen:** DM-12. **Precondición:** `LAB-151` con el servicio `Running`.
- **Pasos:** (1) `Escuchas | Tee-Object "$E\DE-15-oyentes.txt"`; `(Get-CimInstance Win32_Service -Filter "Name='GPOS.Api'").ProcessId` (debe ser el PID del oyente, SPV-06); `netstat -ano | findstr ":5071"`. (2) `.\Probar-Spike-Amplio.ps1 -Caso DE-15`. (3) **Desde `VM-PUESTO`**: `Test-NetConnection 192.168.50.10 -Port 5071` debe fallar. (4) **Negativo opcional** (con el servicio detenido): `$env:ASPNETCORE_URLS='http://0.0.0.0:5071'` y arrancar la API en consola con otra base descartable: debe terminar con 4746 (fuente de direcciones contenida). Si la clave y la cadena no se pueden dar sin tocar el servicio, `No se pudo`.
- **Esperado:** direcciones `127.0.0.1` y `::1`; PID igual al del servicio; desde `VM-PUESTO` la conexión falla; 5073: `No se pudo` (**Bloqueado**, DE-15-5073).
- **Rechazo:** cualquier `0.0.0.0` o `::` en 5071 (**Alta**); otro PID escuchando en 5071 con el servicio caído (**Alta**, riesgo S-01/S-02: un proceso local recibiría credenciales de la Web); conexión desde `VM-PUESTO` (**Alta**).
- **Evidencia:** `DE-15-oyentes.txt`, PID, resultado de `Test-NetConnection`. **Duración:** 10 min local + 10 min remoto. **Marca:** [I].
- **Control:** DE-01-N2 (con el puerto ocupado, el oyente ajeno aparece en `Escuchas` y el servicio no queda sirviendo): demuestra que el instrumento ve a un oyente que no es el servicio.

### DE-16. Tras retirar el servicio no quedan clave ni valor `Environment`
- **Origen:** DM-06. **Precondición:** al final de S-2, desde `LAB-151`; **rama pura** (SP-05).
- **Pasos:** (1) `.\Probar-Spike-Amplio.ps1 -Caso DE-16-retirar`. (2) `Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Services\GPOS.Api'`; `sc.exe query GPOS.Api` (1060). Si el `Test-Path` da `True`: `Restart-Computer` y repetir. (3) **Barrido de secretos en la evidencia:** `Get-ChildItem C:\GPOS-LAB\evidencia -Recurse -File | Select-String -Pattern 'Jwt__Clave=','Jwt:Clave=' -List | Select-Object Path`, más una búsqueda de cadenas Base64 de ≥ 60 caracteres (heurística, solo nombres de archivo). (4) Comprobar que el login SQL, las bases y el anillo **se conservan**.
- **Esperado:** `claveDelServicioExiste=False` (o `True` con 1072 y `False` tras reiniciar); login, bases y anillo intactos; **ningún** archivo de evidencia contiene la clave.
- **Rechazo:** la clave del servicio persiste tras reiniciar (**Alta**); la clave aparece en cualquier archivo (**Crítica**); el retiro borra datos de la empresa o el anillo (**Alta**).
- **Evidencia:** el JSON, `Test-Path`, la lista de archivos con coincidencias (vacía). **Duración:** 15 min. **Marca:** [I]. **Rotación (DM-06):** que un token anterior sea rechazado tras reinstalar queda **Bloqueado** (sin sonda funcional, P-10).
- **Control:** el barrido del paso 3 se prueba antes sembrando un archivo de prueba con `Jwt__Clave=centinela` en la carpeta: debe encontrarlo; sin eso, «sin coincidencias» no demuestra nada. Retirarlo.

## 8. Negativos del spike (cada uno desde `LAB-151`; el entorno completo se escribe con el centinela)

Variación del entorno sin leer la clave: `function Poner-Entorno([string[]]$l){ $k=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Services\GPOS.Api',$true); try{$k.SetValue('Environment',$l,[Microsoft.Win32.RegistryValueKind]::MultiString)}finally{$k.Dispose()} }`, escribiendo el entorno **completo** de P-01: `ASPNETCORE_ENVIRONMENT=Production`, `GPOS__DataProtection__Carpeta=<anillo>`, `GPOS__DataProtection__DpapiMaquina=false`, `GPOS__DataProtection__DpapiDemo=true`, `ConnectionStrings__Sistema=<cadena integrada, sin contraseña>`, `GPOS__Seguridad__ModoIdentidad=<según el caso>` y `Jwt__Clave=<centinela>` donde se pida. **SP-09:** cada negativo usa su propio `$desde`, termina con `Stop-Service GPOS.Api -Force` y comprueba `(Procesos-Api).Count = 0`; la recuperación `restart ×3` deja un bucle cada 60 s que mezclaría eventos del caso siguiente. Evidencia común: `Eventos`, `ScmEventos`, `sc query`, `Escuchas` y la nota de qué se cambió; **sin el valor del entorno**. Todos [I] hasta ejecutar.

**DE-01-N1. Sin SQL.**
- Precondición: `LAB-151`. Pasos: `Stop-Service 'MSSQL$SQLEXPRESS' -Force`; `Start-Service GPOS.Api`; esperar 3 min; `sc query` y `Eventos`; arrancar SQL; esperar la recuperación de 60 s y repetir.
- Esperado: no arranca o cae con un mensaje que **nombra** la falla de conexión, sin cadena de conexión ni credenciales; sin escucha en 5071 mientras no haya base; con SQL de vuelta llega a `Running` o queda detenido de forma limpia (anotar cuál; `Inicializacion.cs` no leído).
- Rechazo: imprime la cadena de conexión o credenciales (**Alta**); escucha antes de tener base (**Alta**); cuelga el Administrador de servicios (**Alta**).
- Evidencia: eventos, `sc query`, `Escuchas`. Duración: 10 min. Control: el mismo `Start-Service` con SQL arrancado llega a `Running` (DE-01).

**DE-01-N2. Puerto 5071 ocupado.**
- Precondición: servicio detenido. Pasos: en una consola elevada `$l=[System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback,5071); $l.Start()`; `Start-Service GPOS.Api`; `Eventos`; `$l.Stop()`.
- Esperado: el servicio **no** queda `Running` sirviendo en otro puerto; error de enlace claro; sin 4768; al liberar el puerto y arrancar, funciona.
- Rechazo: `Running` con el puerto ajeno o escucha en otro puerto o dirección (**Alta**: la Web podría hablar con quien lo ocupó).
- Evidencia: eventos, `Escuchas`. Duración: 10 min. Control: DE-15 (el PID que escucha es el del servicio solo cuando el puerto estaba libre). En PR-V, `comprobar-servidor` (R4) debe comparar el PID: **Bloqueado**.

**DE-01-N3. Clave JWT ausente.**
- Pasos: `Poner-Entorno` con modo `Amplio` y el resto, **sin** `Jwt__Clave`; arrancar.
- Esperado: no arranca («Configure Jwt:Clave con al menos 32 caracteres»), excepción sin el valor; `STOPPED`; sin escucha; sin 4767.
- Rechazo: arranca con clave vacía o por omisión (**Crítica**); el evento incluye valores (**Alta**).
- Evidencia: eventos y `sc query`. Duración: 5 min. **Control: este caso es el control de DE-01** (sin clave no hay `Running` + 200).

**DE-01-N4a. Clave en modo no Amplio (cerrojo 2).**
- Pasos: `Poner-Entorno` con `Jwt__Clave=<centinela>` y **sin** `GPOS__Seguridad__ModoIdentidad`; luego con `Estricto`, con `Ampl` y con `AmplioX`.
- Esperado: 4767 `ARRANQUE_JWT_ENTORNO: Jwt__Clave está en el entorno del servicio y el modo de identidad no es Amplio…`, salida 1, **sin el valor ni su prefijo** en el evento ni en `Console.Error`; sin escucha.
- Rechazo: arranca en alguna de las cuatro variantes (**Crítica**: la clave en un servidor que no es DEMO); el evento nombra el valor (**Alta**).
- Evidencia: los cuatro 4767. Duración: 15 min. Control: con `Amplio` exacto sí arranca (DE-01).

**DE-01-N4b. Misma clave con dos puntos (JWT-01).**
- Pasos: `Poner-Entorno` con `Jwt:Clave=<centinela>` y modo ausente; luego con `Amplio`.
- Esperado: sin Amplio, 4767 igual que N4a; con `Amplio`, arranca y, como en DE-13, `Jwt:Clave` no está en el entorno del proceso ni del hijo.
- Rechazo: la grafía de dos puntos evade el cerrojo (**Crítica**). Evidencia: eventos y presente/ausente. Duración: 10 min. Control: N4a.

**DE-01-N4c. Clave en el archivo de instalación.**
- Pasos: crear `%ProgramData%\GPOS NG\config\GPOS.Api.json` con `{"Jwt":{"Clave":"<centinela>"}}` (como administrador) y quitar la clave del entorno.
- Esperado: la clave del archivo se **ignora** y queda una advertencia que nombra la clave, no su valor (`ArchivoInstalacion.AdvertirIgnoradas`); luego falla como N3.
- Rechazo: la API acepta `Jwt:Clave` desde el archivo (**Alta**); la advertencia trae el valor (**Alta**). Evidencia: advertencia (texto sin valor). Duración: 10 min. Control: N3 (sin archivo, mismo fallo). Retirar el archivo.

**DE-01-N4d. Clave corta.**
- Pasos: `Jwt__Clave=corta` con modo `Amplio`. Esperado: excepción de longitud mínima 32, sin el valor. Rechazo: arranca (**Alta**). Evidencia: evento. Duración: 5 min. Control: la clave del centinela (49 caracteres) sí pasa la longitud.

**DE-01-N5. Cuenta distinta.**
- Pasos: con el entorno completo, `sc.exe config GPOS.Api obj= LocalSystem` (y `LocalService`, `NetworkService`), arrancar; restaurar con `sc.exe config GPOS.Api obj= "NT SERVICE\GPOS.Api"`.
- Esperado: 4767 `ARRANQUE_IDENTIDAD`, salida 1, sin escucha; **la clave nunca llega a correr bajo SYSTEM** (la comprobación de identidad va antes de leer la configuración, `Program.cs:30` [V]).
- Rechazo: la API arranca bajo la cuenta ajena con la clave en el entorno (**Crítica**); abre un puerto (**Alta**).
- Evidencia: eventos y `sc qc` tras cada intento. Duración: 10 min. Control: la cuenta virtual (DE-01) sí arranca.

**DE-01-N6. Carpeta del anillo ajena (ADR-77).**
- Pasos: con el servicio detenido, reemplazar `Api\anillo` por una carpeta con dueño `gpos-lab-usuario` o con ACE de Usuarios Modificar; arrancar.
- Esperado [?]: anotar si la API rechaza (previsto por H-17 v2 en Estricto) o arranca. Si arranca, **hallazgo para A**.
- Rechazo: arranca con llaves escritas por un estándar sin aviso (**Alta**, para A).
- Evidencia: eventos, DACL del anillo. Duración: 10 min. Control: con el anillo original, arranca.

## 9. Bloque C: el Chromium de la principal y lo aplicable de T4-03

**Por qué aquí.** Los casos L-1 a L-4 de T4-03 miden el Chromium de `GPOS.Reportes.Api` bajo `NT SERVICE\GPOS.Reportes`, que en el spike no está. Pero **la principal también lanza Chromium** como `NT SERVICE\GPOS.Api` (`GPOS.Api/Impresion/ConvertidorPdf.cs`), sin sandbox desactivado explícito, sin canalización y sin filtro de entorno. Eso permite medir con una **cuenta virtual real** las mismas incógnitas (¿el *sandbox* arranca con un solo privilegio? ¿la regla de salida por usuario alcanza al navegador y a sus hijos?) **sin** el disparador de render (PRE-5 de T4-03) ni el lector de token propio: el render lo dispara la interfaz del DEMO. El resultado no sustituye a T4-03 (otro servicio, otro código, otras capas); la reduce.

**Mapa de T4-03:**

| T4-03 | Aquí | Motivo |
|---|---|---|
| L-1a, L-1b (carpeta `render` en Release) | No aplica | Necesita `GPOS.Reportes.Api` y `PrepararCarpeta`; **Bloqueado** hasta PR-D2 o el MSI de reportes |
| L-1c sandbox | SPK-C1 | Misma pregunta, cuenta de la principal |
| L-1d huellas fuera de `render` | SPK-C2 | La principal usa `GetTempPath()` y nunca borra (L-11 de OPS-API) |
| L-1e sesión 0, 40/40 | Parcial en SPK-C1 | El servicio ya corre en sesión 0; la serie de 40 es de reportes |
| L-2a filas 1 a 3 y L-2b | SPK-C5 | La regla `-LocalUser` sobre la cuenta virtual y el programa del navegador |
| L-2c directivas del navegador | No aplica | La principal no tiene la capa 2 (`--proxy-server`) que la directiva anularía |
| L-3a, L-3b puerto de depuración | SPK-C3 | La principal no usa `Pipe`: **se espera lo contrario** que en reportes (SP-08) |
| L-3c vida del navegador | SPK-C4 | Sin Job Object en ninguno de los dos hoy |
| L-4a, L-4b rendimiento y concurrencia | No aplican | Miden la intercepción y el contexto por render de reportes; el tiempo del primer PDF de la principal se anota como dato informativo en SPK-C1 |

**Precondiciones comunes:** `LAB-151` con el servicio `Running`; un solo navegador; System Informer; formato personalizado imprimible (Q-7); `gpos-lab-usuario`; DE-13 hecho.

### SPK-C1. El sandbox del navegador de la principal está activo bajo la cuenta virtual
- **Origen:** L-1c; S170-05.
- **Pasos:**
  1. Generar un PDF desde la interfaz; mientras el navegador vive, `Navegadores | Tee-Object "$E\C1-procesos.txt"`.
  2. Para cada proceso: `Dueno <Pid>` (todos `NT SERVICE\GPOS.Api`) y, con System Informer (pestaña *Token/Security*), nivel de integridad, `IsRestricted`/AppContainer y pertenencia a un *Job* del proceso principal (`--type` ausente) y de los `--type=renderer` y `--type=gpu-process`. Solo valores de integridad y banderas; nada del *Environment*.
  3. Línea de comandos del proceso principal: sin `--no-sandbox`, `--disable-web-security` ni `--remote-debugging-pipe`; **anotar** si trae `--remote-debugging-port=0` (SP-08).
  4. Eventos de Aplicación y de la API: errores de *sandbox* («Failed to … broker», «Access is denied»), 5156 no aplica aquí.
  5. **Control obligatorio** (instrumento): como Administrador elevado, lanzar el navegador **con** `--no-sandbox --headless --user-data-dir=C:\GPOS-LAB\x --remote-debugging-port=0 about:blank` y repetir el paso 2 sobre sus procesos: hijos con **la misma** integridad que el principal.
  6. Datos informativos: tiempo del **primer** PDF tras arrancar el servicio y p50/p95 de 20 PDF en serie (sin criterio de aceptación).
- **Esperado [I]:** el PDF se genera; los procesos `--type=renderer` y `--type=gpu-process` corren con integridad **menor** que el principal y token restringido o AppContainer, dentro de un *Job*; los valores exactos se **anotan**, no se afirman. Control: sin *sandbox* no hay diferencia.
- **Rechazo:** **Crítica**: `--no-sandbox` presente; renderizadores con el mismo token e integridad que el principal en el caso real; un proceso con cuenta distinta. **Alta**: el navegador no arranca por el *sandbox* o los renderizadores se caen (entonces los formatos personalizados bajo la cuenta virtual no existen; no se «arregla» con un argumento en la VM). Si en el control del paso 5 **no** se ve diferencia, el lector no discrimina y **C1 no puede dar `Cumple`**.
- **Evidencia:** `C1-procesos.txt`, tabla de integridad por proceso (principal/hijos/control), versión del navegador. Sin entorno ni capturas con datos. **Duración:** 30 min. **Marca:** [I]. Riesgo residual (escape del *sandbox* con el token del servicio): **no se prueba**.

### SPK-C2. Huellas del navegador fuera de una carpeta comprobada, y perfiles que no se borran
- **Origen:** L-1d; L-11 de OPS-API; S152-07.
- **Pasos:** antes de C1, listar (nombre, tamaño, fecha) `C:\Windows\ServiceProfiles`, `C:\Windows\Temp`, `C:\Users`, `%ProgramData%` y `C:\Windows\ServiceProfiles\GPOS.Api\AppData\Local\Temp`. Generar 20 PDF; `Stop-Service` y `Start-Service` **tres veces**; repetir el listado y `Compare-Object`; contar las carpetas `gpos-pdf-navegador\*` y su tamaño.
- **Esperado [I]:** todo lo nuevo cuelga de `…\GPOS.Api\AppData\Local\Temp\gpos-pdf-navegador\<id>`; **una carpeta nueva por arranque y ninguna se borra** (`ConvertidorPdf.cs:66`, sin `Directory.Delete`): hallazgo ya conocido (cuatro del OPS-API).
- **Rechazo:** **Media**: perfiles que se acumulan (confirmado por hecho; se anota con cifras de crecimiento por arranque); **Alta**: volcados de *crashpad* o documentos en una carpeta legible por usuarios; carpetas nuevas del navegador fuera del `Temp` de la cuenta.
- **Evidencia:** los dos listados, el `Compare-Object`, conteo y tamaño. **Duración:** 20 min. **Marca:** [V] la ausencia de borrado en el código; [I] la ubicación. **Control:** el listado «antes» (sin carpetas) y la cuenta de 0 → 3 arranques.

### SPK-C3. ¿Hay un puerto de depuración del navegador al alcance de un usuario local?
- **Origen:** L-3a y L-3b; R-T403-04; SP-08. **Regla (C10):** se mide **solo la conexión TCP**; no se envía ningún comando de depuración ni se abre ninguna página.
- **Pasos:** (1) `Escuchas | Tee-Object "$E\C3-antes.txt"` con el servicio sano y sin PDF. (2) Generar un PDF y, mientras el navegador vive, `Escuchas | Tee-Object "$E\C3-despues.txt"`; filtrar los `LISTEN` cuyo `OwningProcess` sea `chrome.exe`/`msedge.exe` (con `Dueno`). (3) Como `gpos-lab-usuario`: `Test-NetConnection 127.0.0.1 -Port <p>` para **cada** puerto del paso 2, solo el resultado `True/False`. (4) `[System.IO.Directory]::GetFiles('\\.\pipe\')` filtrado por `chrome|msedge|mojo` (las canalizaciones internas de Chromium son normales). (5) **Control:** lanzar el navegador como Administrador con `--remote-debugging-port=0` y verificar que `Escuchas` ve el puerto (instrumento válido); y con `--remote-debugging-pipe`, que **no** aparece puerto.
- **Esperado [I]:** **para la principal se espera que aparezca un puerto** `127.0.0.1:<p>` del navegador y que el estándar pueda conectarse (TCP). Si no aparece (la biblioteca usa canalización por omisión), el caso es `Cumple` y SP-08 se retira.
- **Rechazo:** puerto de depuración alcanzable por `gpos-lab-usuario` (**Alta**, hallazgo para A: el navegador corre con la cuenta del servicio y tiene acceso al anillo y a la base; la mitigación de reportes es `Pipe = true`); puerto en una dirección que no es loopback (**Crítica**).
- **Evidencia:** `C3-antes.txt`, `C3-despues.txt`, `True/False` por puerto, líneas de comandos. **Duración:** 20 min. **Marca:** [I]. **Control:** el paso 5. Es un barrido, no una prueba de ausencia.

### SPK-C4. Vida del navegador cuando el servicio se detiene o muere
- **Origen:** L-3c; H170-09; Job Object de T4-03b.
- **Pasos:** (1) Con un PDF ya generado: `Stop-Service GPOS.Api`; contar procesos del navegador a los 5, 15 y 60 s. (2) Arrancar, generar PDF, `taskkill /f /pid <PID del servicio>`; contar a los 5, 15 y 60 s; `Start-Service`; ver si arranca bien y si crea otro perfil. (3) `Get-CimInstance Win32_Process` de los huérfanos: propietario y línea.
- **Esperado [I]:** (1) 0 procesos a los 15 s (el `DisposeAsync` cierra el navegador); (2) **sin canalización, el navegador sobrevive** al `taskkill` del servicio (sigue con la cuenta del servicio y su puerto abierto) y el nuevo arranque no recicla el perfil.
- **Rechazo:** (1) vivos tras 60 s (**Media**); (2) vivos tras 60 s (**Media**; **Alta** si, además, conservan el puerto de depuración abierto de SPK-C3 o impiden el arranque).
- **Evidencia:** conteos a los 5/15/60 s, `sc queryex` antes y después, eventos. **Duración:** 25 min. **Marca:** [I]. **Control:** (1) frente a (2): si ambos dejan el mismo número de procesos, el conteo no distingue una parada limpia de una caída.

### SPK-C5. La regla de salida por usuario y programa corta al navegador de la cuenta del servicio y a nadie más
- **Origen:** L-2a (filas 1 a 3, y 4) y L-2b; R-T403-03. **VM:** `VM-SRV` + `VM-PUESTO`.
- **Precondición:** `LAB-151`; `VM-PUESTO` con un oyente TCP en el 8099 que registra hora y origen y la entrada abierta; `auditpol /set /subcategory:"Filtering Platform Connection" /success:enable /failure:enable` en `VM-SRV`; un formato personalizado con `<img src="http://192.168.50.20:8099/s.png">` (Q-7); la ruta exacta del navegador que usa la principal (la primera de `RutasConocidas` que exista).
- **Pasos:** el SID de la cuenta: `sc.exe showsid GPOS.Api` (no es secreto). Regla (misma forma que el blueprint de T4-03): `New-NetFirewallRule -DisplayName 'GPOS lab navegador' -Group 'GPOS lab' -Direction Outbound -Action Block -Program <ruta> -Profile Any -Protocol Any -LocalUser "D:(A;;CC;;;<SID>)"`.
  - Fila 1 (control): **sin** regla, generar el PDF → el oyente recibe ≥ 1 conexión.
  - Fila 2: **con** regla, generar el PDF → 0 conexiones; evento 5157 de bloqueo con el navegador (o su proceso de red) como aplicación.
  - Fila 3: con la regla, como `gpos-lab-usuario` (`runas`), lanzar el mismo navegador `--headless --dump-dom "data:text/html,<img src=http://192.168.50.20:8099/s.png>"` → ≥ 1 conexión (la regla no toca a las personas).
  - Fila 4: con la regla, `salud` 200 y el inicio de sesión de la Web siguen funcionando (la regla no corta a la API ni a SQL).
  - Fila 5: con la regla de Edge, probar el otro navegador instalado si lo hay (la regla es por programa).
- **Esperado [I]:** filas 1 y 3 con conexión; fila 2 sin conexión y con 5157; fila 4 sin efecto. Si en la fila 2 pasan conexiones, ver qué proceso hijo (`--type=utility`) y cambiar a la condición por servicio (`-Service GPOS.Api`), repitiendo 1 a 3.
- **Rechazo:** fila 2 con conexiones (**Alta**: la capa 3 no alcanza al navegador); fila 3 sin conexiones (**Alta**: la regla toca a las personas); fila 4 sin 200 (**Alta**: corta al servicio); **fila 1 sin conexión (el montaje no discrimina: no se puede concluir, no es `Cumple`)**.
- **Evidencia:** `Get-NetFirewallRule -Group 'GPOS lab' | Get-NetFirewallSecurityFilter` y `Get-NetFirewallApplicationFilter` (muestran `LocalUser`), registro del oyente por fila, los 5157 exportados (aplicación, PID, destino), versión del navegador. Solo direcciones 192.168.50.x y 127.0.0.1.
- **Duración:** 45 min. **Marca:** [I]. **Control:** la fila 1. Si `VM-PUESTO` no cabe (Q-9), `No se pudo`.

## 10. Bloque M: el MSI con el servicio vivo (rama del MSI, no decide D-2)

**Precondiciones comunes:** `LAB-150-sql-listo` restaurado; `GPOS.Api-SINFIRMA.msi` (v1) y `…-v2.msi` de B con su SHA-256, más `publicacion.sha256` y `publicacion-v2.sha256` (B2 del #226); `Probar-GposApiMsi.ps1`; el cambio de guion `-ServicioDelMsi` (sección 4); `gpos-lab-usuario`. Con un MSI anterior a `1232d0af`, pasar `-AccionesEsperadas 'restart,restart,restart'` y no correr R4 (no hay `none`). **No se usa `DE-16-retirar`** (SP-05).

### SPK-M0. Instalar el MSI v1 y darle la configuración del spike
- **Pasos:** (1) restaurar `LAB-150`. (2) `.\Probar-GposApiMsi.ps1 -Caso I1 -PuntoControl LAB-150-sql-listo` (instala, `Foto`, comprueba servicio `STOPPED`, sin `Environment`, sin escucha). (3) `.\Probar-Spike-Amplio.ps1 -Caso DE-01-preparar -ServicioDelMsi -Paquete C:\GPOS-LAB\paquete\GPOS-Demo` (nota: el `-Paquete` solo aporta el esquema; el binario es el del MSI). (4) `Foto 'M0'`; `Env-Presente`; `Sddl-Clave`; `Sddl-Ruta` de `Api\` (debe seguir siendo la del MSI, no la del guion). (5) **Tomar `LAB-152-msi-configurado` sin haber arrancado el servicio.** (6) `Start-Service`; esperar 60 s; `Salud`; `Eventos`.
- **Esperado [I]:** `Running` + 200; sin 4767; `Foto 'M0'` igual a la de I1 salvo `Environment` (cuenta, privilegios, SDDL del servicio de Q-5, recuperación `restart, restart, none`, `Start=auto`, `ImagePath` en `Program Files`); `Api\` con dueño SYSTEM y la DACL del contrato; clave del servicio con la DACL de DE-10.
- **Rechazo:** `Running` sin que la rama pura lo haya logrado (informativo: algo del MSI aporta); no arranca por algo del MSI (ruta, SDDL, `Argumentos`) y sí en la rama pura (**Alta** para B: el MSI no deja un servicio equivalente); el guion cambia el dueño o la DACL de `Api\` (**Alta**, el cambio de guion está mal); `Foto 'M0'` con diferencias respecto de I1 salvo `Environment` (**Media**).
- **Evidencia:** `I1.json`, `Foto 'M0'`, `DE-01-preparar.json` (rama del MSI), SDDL. **Duración:** 40 min. **Marca:** [I]. **Control:** I1 de la sesión del MSI (el servicio quedó `STOPPED` y vacío antes de configurar).

### SPK-M1. El token del proceso vivo trae un solo privilegio (cierra el «límite honesto» de I3)
- **Precondición:** servicio `Running` desde `LAB-152`.
- **Pasos:** (1) `sc.exe qprivs GPOS.Api`. (2) El evento 4770 (`Privilegios del token`) del arranque: copiar el texto (lista de privilegios, sin SID de usuario). (3) `Dueno (Procesos-Api).ProcessId` → `NT SERVICE\GPOS.Api`. (4) System Informer, pestaña *Token*: privilegios habilitados/deshabilitados del proceso. (5) **Control:** misma lectura del proceso de `sqlservr.exe` o de otro servicio: debe mostrar otra lista.
- **Esperado:** exactamente `SeChangeNotifyPrivilege`; un solo 4770 por arranque; sin 4767.
- **Rechazo:** más de un privilegio en el token (**Crítica**); 4767 `ARRANQUE_PRIVILEGIOS` o `ARRANQUE_IDENTIDAD` con la configuración puesta (**Alta**: el SID escrito por el MSI no coincide con el del código); sin 4770 (**Media**, diagnóstico ciego: ¿falta el origen?).
- **Evidencia:** `sc qprivs`, texto del 4770, propietario, lista del *Token*. **Duración:** 15 min. **Marca:** [I]. **Control:** el paso 5 (y el 4767 de I3 con un privilegio de más, de la sesión del MSI).

### SPK-A5. Actualizar con el servicio en ejecución (y A2 con el entorno real)
- **Origen:** A5 (Bloqueado) y A2 de mis casos del MSI; H218-01 (`afterInstallExecute`); L-02 y L-03.
- **Precondición:** `LAB-152`; servicio `Running`; PDF generado (el navegador de la principal vivo); `Foto 'A5-antes'`; anotar PID, `StartTime`, `FileVersion` del módulo, `Env-Presente`, `Sddl-Clave`, número de `key-*.xml` y la lista de procesos del navegador.
- **Pasos:** (1) `$desde = Get-Date; $t = Measure-Command { $cod = Msi @('/i',"`"$msi2`"") 'A5-actualizar' }`; anotar código y tiempo. (2) Inmediatamente: `sc query`, procesos de la API y del navegador. (3) `Foto 'A5-despues'`, `Env-Presente`, `Sddl-Clave`, `ScmEventos $desde | Group-Object Id` (7036, 7045, 7031…). (4) `Start-Service`; esperar 30 s; `Salud`; `Eventos`; `FileVersion` del proceso; número de `key-*.xml`. (5) Comprobar a los 60 s que no queda ningún navegador de la cuenta del servicio. (6) Restaurar `LAB-152`.
- **Esperado [I]:** código `0` (no `3010`, sin «archivo en uso»); `ServiceControl Stop="both" Wait="yes"` detuvo el servicio sin llegar a `STOP_PENDING` indefinido (tiempo total < 120 s); **sin 7045** (el servicio no se recreó); `Environment` y la DACL de la clave **iguales**; el servicio queda `STOPPED` (L-03, sin `Start`); tras `Start-Service` llega a `Running` + 200 con la **versión nueva** y con el **mismo** anillo (mismo número de `key-*.xml`): eso prueba funcionalmente que el entorno sobrevivió; ningún proceso de la API ni del navegador queda tras la parada; el recuperador **no** actuó (sin 7031).
- **Rechazo:** servicio recreado o `Environment` perdido (**Alta**, L-02 sigue); la DACL de la clave cambió o ahora concede lectura a Usuarios (**Crítica**); código `3010` o archivo en uso (**Media**); proceso `GPOS.Api.exe` vivo tras la actualización (**Alta**); navegador huérfano (**Media**, ver SPK-C4); anillo recreado (otro `key-*.xml`) (**Crítica**: se pierde lo cifrado); tras actualizar queda `Running` (informativo: el MSI arranca el servicio; contradice L-03, no es defecto).
- **Evidencia:** `Foto` antes/después y `Compare-Object`, códigos y tiempos, eventos del SCM agrupados, `True/False` del entorno, SDDL de la clave, versiones y conteo de `key-*.xml`. **Nunca el valor del entorno.** **Duración:** 35 min. **Marca:** [I].
- **Control:** (a) `Foto 'A5-antes'` contra sí misma (la comparación no inventa diferencias); (b) la versión del proceso cambia de v1 a v2 (el instrumento ve el reemplazo); (c) DE-01-N3: sin `Environment` el servicio **no** arranca, así que «arranca» = «el entorno sobrevivió».

### SPK-R2. Una parada ordenada no se reinicia; un fallo real sí
- **Origen:** R2 (Bloqueado). **Precondición:** `LAB-152`; servicio `Running`; `sc.exe qfailure` y `qfailureflag` guardados (esperado `restart/60000, restart/60000, none`; `FAILURE_ACTIONS_ON_NONCRASH_FAILURES: TRUE`).
- **Pasos:** (1) `Stop-Service GPOS.Api` con cronómetro; vigilar 100 s con `Linea-Tiempo 100 5 "$E\R2-parada.txt"` y `ScmEventos`: debe quedar `STOPPED`, sin proceso nuevo. (2) `Start-Service`; esperar `Running` + 200; `Stop-Process -Id <pid> -Force`; `Linea-Tiempo 150 5 "$E\R2-fallo.txt"`; hora del nuevo `Running`; `Salud`. (3) **El fallo del paso 2 cuenta como el primero del día para SPK-R4**: continuar sin restaurar.
- **Esperado [I]:** (1) tiempo de parada < 20 s, sin reinicio; eventos 7036 únicamente; (2) reinicio a los ≈ 60 s (rango 45 a 90 s), 7031 con «acción correctiva: reiniciar el servicio en 60000 ms», 200 de nuevo.
- **Rechazo:** una parada ordenada se reinicia (**Media**); un fallo real no se reinicia (**Alta**: el servicio no se recupera); reinicio más frecuente que 50 s (**Alta**); procesos `GPOS.Api.exe` duplicados (**Alta**).
- **Evidencia:** `R2-parada.txt`, `R2-fallo.txt`, 7036/7031 (texto sin SID de usuarios), `qfailure`. **Duración:** 15 min. **Marca:** [I]. **Control:** cada paso controla al otro; además `qfailure` antes y después (no cambió).

### SPK-R4. Tres fallos y se queda detenido (`none`); un cuarto el mismo día no se reinicia
- **Origen:** R4 del #226 y L-01. **Precondición:** continuación de R2 (un fallo ya contado); si se parte de otro estado, restaurar `LAB-152`, arrancar y hacer dos fallos antes del tercero (el contador es del día).
- **Pasos:** (1) esperar el reinicio del primer fallo (R2). (2) Segundo fallo: `Stop-Process -Id <pid> -Force`; esperar el reinicio a los ≈ 60 s. (3) Tercer fallo: `Stop-Process -Id <pid> -Force`; vigilar **180 s**: debe **quedar `STOPPED`** y sin proceso. (4) Arranque a mano `Start-Service`; esperar `Running`; cuarto fallo `Stop-Process -Force`; vigilar 150 s: no debe reiniciarse. (5) Dejar anotados los tiempos; el reinicio del contador al cabo de un día queda manual con `Ajustar-Reloj.ps1` desde el anfitrión (no se mide aquí).
- **Esperado [I]:** reinicios tras el primer y el segundo fallo; tras el tercero, detenido (acción `none`); el cuarto del día no programa reinicio (el SCM sigue en la última acción).
- **Rechazo:** reinicia tras el tercero (**Media** para operaciones: el MSI no tiene `none` o no se aplicó; cruzar con `Foto`); no reinicia tras el primero o el segundo (**Alta**); reinicios cada menos de 50 s (**Alta**).
- **Evidencia:** las cuatro líneas de tiempo, 7031/7034 agrupados. **Duración:** 15 min (con R2: 30). **Marca:** [I]. **Control:** los dos primeros fallos sí reinician (el fallo cuenta para el SCM), lo que distingue «detenido por `none`» de «nunca reinició». Cruzar con R1 del #226 (arranques fallidos con la configuración vacía).

### SPK-D3. Desinstalar con el servicio en ejecución, y qué pasa con los datos reales
- **Origen:** D3 (Bloqueado) y D2; DM-06; ADR-77. **Precondición:** `LAB-152`; servicio `Running`; PDF generado; `Arbol` y `Dacl` de `%ProgramData%\GPOS NG`; SHA-256 de cada `key-*.xml` (sin abrir el contenido) y de los archivos de la licencia; `Foto 'D3-antes'`.
- **Pasos:** (1) `$t = Measure-Command { $cod = Msi @('/x',"`"$msi`"") 'D3-desinstalar' }`. (2) `sc.exe query GPOS.Api` (1060); `Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Services\GPOS.Api'`; `Test-Path 'C:\Program Files\GPOS NG\Api'`; `[System.Diagnostics.EventLog]::SourceExists('GPOS.Api')` y `('GPOS.Instalacion')`; `Get-Process GPOS.Api`; navegadores huérfanos a los 60 s. (3) `Arbol`, `Dacl` y SHA-256 de los `key-*.xml` de nuevo. (4) `Eventos $desde`, `ScmEventos`. (5) Si la clave queda marcada (1072): reiniciar y repetir (2).
- **Esperado [I]:** código `0`; el servicio se detuvo (`Stop="both" Wait="yes"`) sin colgarse; servicio inexistente; **la clave del servicio desaparece con su valor `Environment`** (DM-06 cumplido por el MSI); `Program Files\GPOS NG\Api` borrada; **raíz, `config\` y `Api\` siguen**, con la misma DACL; `Api\anillo\key-*.xml` y la licencia intactos (mismo hash); sin proceso ni navegador vivos.
- **Rechazo:** `anillo` o licencia borrados (**Crítica**: pérdida de la llave de cifrado); servicio en `STOP_PENDING` indefinido, `1603` o archivo en uso (**Alta**); clave del servicio o `Environment` que persisten sin 1072 (**Alta**: la clave JWT queda en el registro tras desinstalar); raíz o `config\` borradas o con otra DACL (**Alta**); proceso vivo (**Alta**); navegador huérfano (**Media**).
- **Evidencia:** `D3-antes`/`D3-despues`, hashes de las llaves, `Test-Path`, tiempo, eventos. Sin contenido del anillo. **Duración:** 25 min. **Marca:** [I]. **Control:** `Foto 'D3-antes'` (todo presente) y, si hay duda, D1 de la sesión del MSI (misma desinstalación con el servicio detenido): la diferencia es el servicio vivo.

### SPK-D5. Reinstalar con el anillo residual y volver a configurar
- **Origen:** D5 y DM-06 (rotación). **Precondición:** continuación de D3 (sin restaurar).
- **Pasos:** (1) `$cod = Msi @('/i',"`"$msi`"") 'D5-reinstalar'`. (2) **Control de que D3 quitó la configuración:** `Start-Service` debe **fallar** (como DE-01-N3, sin `Environment`); `sc stop`. (3) `.\Probar-Spike-Amplio.ps1 -Caso DE-01-preparar -ServicioDelMsi …` (genera una clave **nueva**). (4) `Start-Service`; `Salud`; `Eventos`. (5) Contar y comparar los `key-*.xml` y sus hashes con los de D3; `Dacl` de `Api\`; `showsid`.
- **Esperado [I]:** reinstalación `0` (O-1 acepta la carpeta residual: dueño SYSTEM, DACL del contrato); sin configuración no arranca; con la nueva configuración `Running` + 200 **reutilizando el anillo** (mismos `key-*.xml`: DPAPI de la cuenta virtual lo descifra, D-4 sobrevive a la reinstalación); `showsid` igual que antes.
- **Rechazo:** `25101` sobre una carpeta que dejó el propio MSI (**Alta**); el anillo no se descifra y la API lo recrea (otro `key-*.xml`) (**Crítica**: se pierde lo cifrado); centinelas o llaves desaparecidas (**Crítica**); el servicio arranca sin configuración (**Alta**, queda configuración de la instalación anterior).
- **Evidencia:** log de la reinstalación, `Foto`, hashes de llaves, eventos. **Duración:** 30 min. **Marca:** [I]. **Control:** el paso 2 (arranque fallido sin entorno) antes del paso 4 (arranque correcto con entorno). Un token emitido antes de reinstalar y rechazado después queda **Bloqueado** (P-10).

### SPK-R3. Reinicio del equipo con el servicio configurado y `Start=auto`
- **Origen:** R3 y L-04; L-15 (SQL lento, `auto` frente a `delayed-auto`). SP-06.
- **Precondición:** `LAB-152`; `Foto` del tipo de inicio (`sc qc`: `AUTO_START`).
- **Pasos:** (1) `Restart-Computer`. (2) Al volver, medir cada 10 s hasta 5 min: `Get-Service GPOS.Api`, `Salud`, hora de `Running`. (3) `ScmEventos (Get-CimInstance Win32_OperatingSystem).LastBootUpTime` (7000, 7009, 7031, 7036) y `Eventos`; hora de arranque de SQL (`Get-WinEvent -FilterHashtable @{LogName='Application';ProviderName='MSSQL$SQLEXPRESS'}`, mensaje de que la base está lista). (4) Si falló el primer intento, hora del reintento (a los ≈ 60 s).
- **Esperado [I]:** `AUTO_START`; el servicio llega a `Running` + 200 **sin intervención**, con el primer intento o con el reintento a los 60 s si SQL aún no estaba; sin 4767.
- **Rechazo:** no llega a `Running` en 5 min (**Alta**: un servidor reiniciado no recupera la API); necesita más de un fallo antes de arrancar (**Media**, es la medida que decide `auto` o `delayed-auto`, L-15); CPU sostenida del bucle (**Media**).
- **Evidencia:** línea de tiempo, 7000/7009/7031, hora de SQL y de la API. **Duración:** 30 min. **Marca:** [I]. **Control:** en la rama pura (`LAB-151`, `start= demand`) el mismo reinicio deja el servicio `STOPPED` (SP-06): demuestra que se ve la diferencia entre `auto` y `demand`.

## 11. Plantilla de evidencia y lista de revisión

**Una carpeta por sesión** en `C:\GPOS-LAB\evidencia\SPK\` (se recoge con `Recoger-Evidencia.ps1 -Vm VM-SRV -CarpetaInvitado C:\GPOS-LAB\evidencia` y, si se usó, también de `VM-PUESTO`) con los `.json` de los guiones, los `.log` de MSI, las carpetas `Foto`, las líneas de tiempo, los eventos y esta tabla (misma cabecera de `revision-evidencia.md`):

| Campo | Valor |
|---|---|
| VM y fecha | |
| Punto de control de partida (LAB-150, 151 o 152) y rama (pura o MSI) | |
| Commit del guion, del paquete del DEMO (`version.json`) y del MSI; SHA-256 de cada uno | |
| Windows (UBR); FIPS sí/no; edición de SQL; navegador y versión | |
| Caso → resultado (`Cumple` / `No cumple` / `No se pudo` / `Bloqueado`) con el control medido | |
| Escalera: primer escalón que funcionó (DE-01) | |
| Hallazgos (severidad, pasos, esperado, obtenido) | |
| Técnico | |

**Lista de revisión (la aplico yo a la evidencia ya redactada).** Las secciones A a E de `tests/laboratorio-adr090/revision-evidencia.md` se aplican **sin cambios**; más:

### F. Procedencia del montaje y de la rama
- [ ] Cada carpeta dice si es de la **rama pura** o de la **rama del MSI**; ningún caso de una rama usa resultados de la otra.
- [ ] El paquete del DEMO es Release, con `version.json` y SHA-256 igual al anotado, y de un commit con #174 y PR-4.
- [ ] `preparar-vm-VM-SRV-*.json` (y el de `VM-PUESTO` en S-2) con todo `cumple: true` del punto de control de la sesión.
- [ ] Existe `Foto 'DE-01-antes'` (servicio inexistente) y, en la rama del MSI, `Foto 'M0'` frente a la `I1`.
- [ ] La escalera está completa: error literal de cada escalón que falló; ningún rol de la lista prohibida concedido.
- [ ] En la rama del MSI: el guion no cambió el dueño ni la DACL de `Api\` (se comparó con `Sddl-Ruta` de I1).

### G. Controles (sin control no hay `Cumple`)
- [ ] DE-01 tiene DE-01-N3 medido (sin clave, no hay `Running` + 200).
- [ ] DE-10: el SDDL por omisión de SPK-P0 paso 7 y el control de Usuarios; DE-11: la línea base y el fixture; DE-12 y DE-14: sus controles de sensibilidad; DE-13: el centinela visible en la herramienta; DE-15: DE-01-N2; DE-16: el archivo sembrado que el barrido encuentra.
- [ ] SPK-C1: el control `--no-sandbox` **muestra** una diferencia de integridad respecto del caso real; SPK-C3: el control con `--remote-debugging-port=0` aparece en `Escuchas`; SPK-C5: la fila 1 tiene conexiones.
- [ ] SPK-A5: versión del proceso v1 → v2; SPK-R4: los dos primeros fallos sí reiniciaron; SPK-D5: el arranque sin entorno falló antes del correcto; SPK-R3: la rama pura quedó `STOPPED`.

### H. Secretos y datos propios de este plan
- [ ] Ningún archivo contiene `Jwt__Clave=`, `Jwt:Clave=`, una cadena Base64 de ≥ 60 caracteres, ni el contenido de un `key-*.xml`; el barrido de DE-16 paso 3 está en la carpeta y vacío.
- [ ] Del servicio solo constan **nombres** de valores (`GetValueNames()`) y `True/False`; no hay `Get-ItemProperty` sin `-Name` ni `reg query`.
- [ ] Los eventos (4767, 4768, 4770, 5130) no traen SID de usuario real, cadenas de conexión ni rutas de perfiles de personas.
- [ ] Ninguna captura de la pestaña *Environment* ni de `chrome://policy`; las líneas de comandos del navegador no tienen entorno.
- [ ] Los PDF de muestra son de datos de demostración; como máximo 2 por formato; el resto, cabecera y tamaño.
- [ ] Las salidas de `Escuchas`, 5157 y oyentes solo muestran 127.0.0.1 y 192.168.50.x.

### I. Horas, orden y recálculo
- [ ] Las horas de los `.json`, de las líneas de tiempo y de los 7031/5157 caen dentro de la ventana y en el orden de la sección 5.
- [ ] Los casos de severidad Crítica o Alta se **recalculan a mano** desde lo observado: DE-01, DE-10, DE-11, DE-12, DE-13, DE-14, DE-15, DE-01-N3, N4a, N4b, N5, SPK-C1, C3, C5, M1, A5, D3, D5.
- [ ] Ningún negativo mezcla eventos del anterior (SP-09: cada uno con su `$desde` y proceso en cero).
- [ ] Un `DE-12` en `No se pudo` con código 3 por `render` ausente está anotado como esperado (SP-01); `DE-13` en `No se pudo` también; ninguno cuenta como verde.

## 12. Severidades y criterio de recomendación

**Severidades de laboratorio.**
- **Crítica:** un secreto (clave JWT, anillo, cadena) legible por un usuario estándar o impreso en evidencia; el servicio o el navegador corren con una cuenta o privilegio no previsto; un estándar reconfigura el servicio; solo funciona con `sysadmin`; pérdida del anillo o de la licencia; mezcla de contenido entre peticiones.
- **Alta:** la clave llega al proceso hijo (DE-13); `TRUSTWORTHY ON`; escucha fuera de loopback; la principal no arranca por el entorno o el anillo; `Environment` o servicio perdidos por una actualización; un puerto de depuración alcanzable (SPK-C3); la regla de salida no corta al navegador del servicio, o corta a otros.
- **Media:** huérfanos y perfiles que se acumulan; lo que exige más de un reintento al arrancar; observaciones de operación (L-01, L-03, L-04 si B las acepta); un caso `No se pudo` por entorno incompleto.
- **Baja:** textos, tiempos, avisos.

**Cómo se lee el resultado (recomendación técnica; la decisión es de B y del propietario):**
- **D-2 y D-4 salen solo de la rama pura.** DE-01 en verde con la escalera 1 o 2 **y** DE-10 a DE-15 sin Críticos ni Altos → el DEMO puede seguir con PR-V y PR-D2. DE-01 en verde con DE-13 en `No cumple` → primero el PR pequeño de la API (cerrojo 2 y DM-04). Solo funciona con algo prohibido, o falla → **FALLA**, alternativa (b) de la HOJA.
- *Rechazado* si queda algún Crítico o Alto en la rama pura; *Aprobado con observaciones* si solo hay Medios, Bajos o `Bloqueado`; *Aprobado* solo con todos los ejecutables en `Cumple` y sus controles.
- **La rama del MSI** informa a B sobre el MSI (cierra A5, D3, R2 y A2 funcionales, y L-02, L-03, L-04 y L-01 con el servicio vivo); sus Críticos o Altos son del **MSI**, no del spike.
- SPK-C3 y SPK-C5 informan a A sobre el render de la principal y sobre la capa 3 de T4-03; **no** son parte del veredicto D-2, salvo que el auditor de A decida lo contrario.

## 13. Preguntas (dudas)

| # | Pregunta | Para |
|---|---|---|
| Q-1 | ¿Se confirman 23-nov (S-1 y S-2) y 24-nov (S-3)? La VM de B está prevista del 16 al 27-nov; ¿quién opera cada sesión? Si solo hay una ventana de 4 h, ver la sección 5 | B / propietario |
| Q-2 | ¿Se reservan **LAB-150 a LAB-159** (spike) además de LAB-140 a LAB-149 (MSI)? | B |
| Q-3 | **Rama del MSI:** ¿se acepta el diseño de dos ramas y el cambio de guion `-ServicioDelMsi` (≈ 0,25 dp)? ¿Lo escribo yo (el guion es de A, #173) en un PR de pruebas pequeño, o lo hace A? | B / A |
| Q-4 | **SP-02 / P-03:** ¿se reordena el guion (DACL de la clave antes del valor, o borrar `Environment` si la DACL falla) **antes** del 23-nov? Sin eso, un fallo del `SetAccessControl` deja la clave real bajo la DACL por omisión | A |
| Q-5 | **P-10:** ¿hay una sonda funcional (un extremo que pruebe base, anillo y licencia, no solo `salud`)? Hoy se sustituye por el inicio de sesión manual en la Web | A |
| Q-6 | **Edge, Chrome y System Informer:** ¿qué trae la imagen de `VM-SRV` y cómo entran sin Internet (D-2 de T4-03)? ¿Qué navegador se fija para SPK-C1 a C5? (la principal prueba Chrome primero) | B |
| Q-7 | **Formato imprimible:** ¿qué formato personalizado y qué usuario con rol SUPER hay en el DEMO para DE-13 y SPK-C5 (con una `<img>` externa)? | B |
| Q-8 | **SP-08:** ¿es conocida y aceptada para el DEMO la ausencia de `Pipe` en el render de la principal? Si T4-06 mueve el render a `GPOS.Reportes.Api` antes del 23-nov, SPK-C1 a C5 se vuelven los L-1 a L-3 de T4-03 con otro servicio | A (auditor) |
| Q-9 | **Memoria de `LFMB`:** ¿caben `VM-SRV` (3 584 MB) y `VM-PUESTO` encendidas a la vez durante S-2? | B |
| Q-10 | **P-11:** ¿`config` cerrado o vector v3 (DE-12)? Mientras tanto el criterio es el vector v3 | B |
| Q-11 | **MSI:** ¿qué commit exacto (`1232d0af` o posterior) y quién entrega `GPOS.Api-SINFIRMA-v2.msi` y los `publicacion*.sha256` para S-3? | B |
| Q-12 | **SP-01:** ¿`DE-12` debe tratar `render` como «no aplica sin API de reportes» para no salir con 3? Y SP-07 (`-UsuarioInstala` con el prefijo del equipo) | A |

## 14. Qué no verifiqué

- **Nada se ejecutó:** ni el DEMO, ni MSI, ni servicio, ni `sc`, ni los guiones, ni SQL, ni navegador, ni `auditpol`, ni VirtualBox. Todo valor [I] (el puerto de depuración de PuppeteerSharp por omisión, el comportamiento del SCM ante `none`, `Stop="both"` y `afterInstallExecute` con el servicio vivo, la DACL por omisión de las claves de servicio, los niveles de integridad y el *sandbox* con un solo privilegio, `-LocalUser` y los hijos del navegador, los códigos de `msiexec`, el contador de fallos tras un reinicio) es conocimiento general, no comprobado aquí ni contra documentación del fabricante.
- **No leí** `Inicializacion.cs`, `CarpetaAnillo.cs`, `AlmacenLicenciaDisco.cs`, `ProteccionDatos.cs` ni `ModoServicioApi.cs` completos: el «primer fallo» de cada negativo y la causa de cada evento son inferencia del orden de `Program.cs` y de los comentarios de A.
- **No leí `Preparar-Vm.ps1` por dentro** ni el estado del PR-V (`a/pr-v-verbos-servidor`): DE-11-verbo, DE-14-verbo y `--fase esquema` quedan `Bloqueado`.
- **No verifiqué** que el paquete del DEMO publicado desde un commit posterior a #174 arranque, que Edge esté en la imagen de Windows Server 2025, que System Informer corra sin Internet, ni que `Puntos-Control.ps1` tome puntos con la VM encendida (por eso `LAB-152` se toma con el servicio sin arrancar).
- **El cambio de guion `-ServicioDelMsi` no existe**: sin él, la rama del MSI no se puede correr y A5, D3, R2 y A2 funcionales siguen `Bloqueado`.
- **Duraciones y reparto en sesiones:** mis estimaciones, sin experiencia de ejecución en esta VM. Las fechas 23 y 24-nov son una propuesta, sin confirmar por el propietario.

### Cierre
- Estado: Completado (plan y casos redactados; ninguno ejecutado)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-24-plan-laboratorio-spike-de01.md`
- Supuestos: los de la sección 14; el MSI es el de `b/t1b-api-msi` @ `1232d0af` o posterior; la rama del MSI requiere el cambio de guion `-ServicioDelMsi`; las fechas de VM no están confirmadas.
- Decisiones candidatas a ADR: Ninguna (SP-08 y Q-4 pueden terminar en una precisión del plan del DEMO o del render; las redacta el arquitecto-maestro si A/B las adoptan).
- Entregas a otros agentes: B → Q-1, Q-2, Q-3, Q-6, Q-7, Q-9, Q-10, Q-11 y operar la VM; A (arquitecto-software/devops) → Q-4 (orden de la DACL de la clave), Q-5 (sonda funcional), Q-12 y SP-01, SP-07; A (auditor-seguridad) → SP-08 y Q-8 (puerto de depuración de la principal) antes del 23-nov; C (yo) → escribir `-ServicioDelMsi` si B lo confirma (Q-3) y revisar la evidencia ya redactada con la sección 11.
- Próximo paso recomendado: que B conteste Q-1, Q-3 y Q-6 y que A decida Q-4 antes del 16-nov; con Q-3 escribo el cambio de guion y el plan queda ejecutable.
