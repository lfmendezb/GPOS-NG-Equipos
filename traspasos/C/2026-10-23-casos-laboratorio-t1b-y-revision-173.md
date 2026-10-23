```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (tarea 7 de B-a-C/2026-10-22-tareas-nuevas-para-c-3: casos de laboratorio de T1-b y del spike Amplio)
Prioridad: Media
Repositorio y rama: GPOS-NG #165 y #173 (lectura); área común `traspasos/A/`
Estado: Abierto
```

# Casos de laboratorio de T1-b (MSI mínimo de la API) y del spike del modo Amplio (DE-01, DE-10 a DE-16)

**Qué es.** Casos para la VM `VM-SRV` de `LFMB` (VirtualBox). **No se ejecutó nada** (ni MSI, ni servicio, ni script; OSHIN-LEGION no tiene VirtualBox). Reutiliza el formato de mis casos previos (`2026-10-22-casos-laboratorio-chromium-y-comprobaciones-paquete.md`: ID, caso, cómo, esperado, marca) y los guiones del anfitrión de ADR-90 (#146, unido): punto de control antes de cada bloque, evidencia con `Recoger-Evidencia.ps1`, una VM a la vez. No repito lo ya escrito: P-O1-7.1 a .9, L-1bis, L-2bis, L-2c a L-2f y F-1 están en el procedimiento de A (#165); aquí se citan por ID y se agregan solo las precondiciones, las lecturas de evidencia y los casos que faltan.

**Marcas.** [V] verificado en un archivo que leí (con ruta); [I] inferido o conocimiento general de Windows/WiX/SQL, por confirmar en la VM; [?] depende de algo que aún no existe.

**Estados de un caso en la VM.** `Cumple` · `No cumple` · `No se pudo` (la precondición no existía: **nunca se anota como Cumple**) · `Bloqueado` (no ejecutable hoy; ver la sección 2).

## 0. Resumen para decidir

1. Hay **13 casos del MSI** de la API (MI-01 a MI-13) y **5 negativos** (MI-N1 a MI-N5), **8 del spike** (DE-01, DE-10 a DE-16) con **6 negativos** (DE-01-N1 a N6) y **4 de guardas** (G-N1 a N4). El MSI solo, sin PR-V, **no llega a `Running`**: sus criterios son de estructura, seguridad y ciclo de instalación, no de servicio vivo (MI-06).
2. **Antes de la VM hay 11 observaciones sobre lo que escribió A (sección 3).** Las dos que pueden arruinar el 23-nov: **P-01** el servicio del spike no recibe `GPOS__DataProtection__DpapiDemo=true` ni carpeta de anillo, y la API Release lanza excepción sin ellos (DE-01 fallaría por una causa distinta de D-2/D-4); **P-02** el spike no prepara `%ProgramData%\GPOS NG\Api` y la cuenta virtual no puede crearla (DE-12 daría verde vacío).
3. **Varios textos de A quedaron viejos** porque PR-4 (#139/#140) y #174 se unieron el 22 y 23-oct: ya no existe `FijarEscuchaPorOmision` en `ModoServicioApi.cs` [V], así que la guarda G-PR4 y el §8 del documento de operaciones describen otra cosa; el 4744 de L-3 pasa a ser 4747 sin `tls`; y DE-13 ya no es «FALLA esperada» (P-07).
4. **Pendiente mío:** `Preparar-Vm.ps1` (crea el marcador `LaboratorioTls` que exigen los dos guiones de A) **no existe en ninguna rama**; sin él ningún guion corre. Lo escribo antes del 18-nov si B lo confirma (sección 9).
5. **Duración [I, ±50 %]:** bloque instalador ≈ 6,5 h para esta parte (más las ≈ 3 h del procedimiento de A); spike ≈ 5 h. Recomiendo **3 sesiones de VM**, no 2 (sección 4). Las corre B en `LFMB`; C revisa la evidencia redactada.

## 1. Fuentes, reglas heredadas y convenciones

**Fuentes leídas.**
- `traspasos/A/guia-t1b-msi-api-2026-10-22.md` (guía T1-b) y `traspasos/A/contrato-servicio-msi-api-2026-10-22.md` (contrato y Q-5).
- #165 `a/t1c-lab-instalador`: `docs/operaciones/2026-10-21-operaciones-gpos-api-servicio.md`, `docs/operaciones/2026-10-22-procedimiento-laboratorio-instalador-p-o1-7.md`, `tests/laboratorio-adr090/invitado/Probar-Instalador.ps1` (con `git show origin/a/t1c-lab-instalador:…`).
- #173 `a/spike-amplio-demo`: `docs/operaciones/2026-10-22-spike-demo-modo-amplio.md`, `tests/laboratorio-adr090/invitado/Probar-Spike-Amplio.ps1`, `tests/GPOS.Tests/Instalador/SpikeAmplioDemoTests.cs`.
- Texto de origen de DE-01 y DE-10 a DE-16: `traspasos/A/plan-demo-con-api-de-reportes-2026-10-22.md:253-267` y `traspasos/A/dictamen-seguridad-demo-jwt-d5-2026-10-22.md:149-155`. DE-02 a DE-09 son de PR-D2 (ensayos del DEMO) y **no** son de esta tarea.
- `traspasos/A/dictamen-seguridad-pr174-k3-demo-2026-10-22.md` (JWT en el entorno solo en Amplio) y `traspasos/A/revision-seguridad-pr-v-verbos-servidor-2026-10-22.md` §7 (lo que solo la VM confirma).
- Fechas: `avisos/B-a-A/2026-10-22-propuesta-fechas-vm.md` (instalador 18-nov, spike 23-nov; **sin confirmar por el propietario**) y `avisos/A-a-B/2026-10-22-respuesta-fechas-vm.md`.
- Código en `origin/feature/modelo-ng` @ `67b4353a`: `src/GPOS.Api/Servicio/ModoServicioApi.cs`, `src/GPOS.Api/Program.cs`, `src/GPOS.Comun.Servidor/Red/EscuchaServidor.cs`, `src/GPOS.Comun/Red/ArranqueRed.cs`, `src/GPOS.Core/Infraestructura/ProteccionDatosInstalacion.cs`, `instalador/Demo/scripts/herramientas/Comun-Demo.ps1`, `instalador/Comun/Fragmentos/RaizGposNg.wxs`.
- Los dos PR no tienen comentarios (`gh pr view 165 --comments` y `173 --comments` vacíos).

**Reglas que no se discuten (heredadas de #165, #173 y del laboratorio de ADR-90).**
1. Solo en `VM-SRV` de `LFMB`, desde el punto de control `base`. Nunca en la PC del propietario, en OSHIN-LEGION ni en la PC de A. Ningún agente ejecuta esto (incidente del 2026-10-08): lo opera B (técnico o propietario).
2. Un punto de control por bloque: `.\Puntos-Control.ps1 -Vm VM-SRV -Accion Tomar -Nombre LAB-T1B-<ID>` y, al terminar, `-Accion Restaurar -Nombre base -Apagar`. Los casos plantan carpetas, borran claves y cambian la directiva FIPS: la VM no se reutiliza sin restaurar.
3. **Si algo falla no se corrige a mano para que pase**: se anota (ruta, código, SID, texto del evento) y se restaura el punto de control.
4. **Cada instalación va con `/l*v`.** En un equipo sin `GPOS.Api.msi` no existe el origen `GPOS.Instalacion` y el motivo de un rechazo queda solo en el registro del MSI (S-11).
5. **Ningún secreto en la evidencia.** Prohibido: `reg query` y `reg export` de `HKLM\SYSTEM\CurrentControlSet\Services\GPOS.Api`; `Get-ItemProperty` de esa clave **sin `-Name`** (imprime el valor `Environment`); capturas de pantalla de la pestaña Environment de Process Explorer; poner la clave en una línea de comandos. Para ver los nombres de valores: `(Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Services\GPOS.Api').GetValueNames()` (la llamada al método devuelve solo nombres; nunca imprimir el objeto `Get-Item`).
6. En los casos que cambian el entorno del servicio (DE-01-N3 a N5) se usa una **cadena centinela falsa y visible** (`CLAVE-DE-LABORATORIO-NO-SECRETA-0000000000000000`, 49 caracteres), nunca la clave generada por el guion de A.
7. Para ejecutar como usuario estándar: `runas /user:%COMPUTERNAME%\gpos-lab-usuario "powershell.exe -NoProfile"`; el técnico teclea la contraseña al crear la cuenta; los guiones no la guardan. Del lado de la cuenta estándar se anota solo «denegado» o «permitido».

**Variables y funciones de apoyo** (PowerShell 5.1 elevado, una vez por sesión):

```powershell
$E   = 'C:\GPOS-LAB\evidencia'
$msi = 'C:\GPOS-LAB\msi\GPOS.Api-SINFIRMA.msi'
function Msi([string[]]$a,[string]$log){ $p = Start-Process msiexec.exe -ArgumentList ($a + @('/qn','/norestart','/l*v',"`"$E\$log.log`"")) -Wait -PassThru -WindowStyle Hidden; $p.ExitCode }
function Foto([string]$id){            # estado observable del servicio, sin tocar Environment
  $d = New-Item -ItemType Directory -Force "$E\$id"
  foreach($c in 'qc','qprivs','showsid','qsidtype','qfailure','qfailureflag','sdshow','query'){ & sc.exe $c GPOS.Api | Tee-Object -FilePath "$E\$id\sc-$c.txt" | Out-Null }
  Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\GPOS.Api' -Name ImagePath,ObjectName,Start,RequiredPrivileges -ErrorAction SilentlyContinue | Out-File "$E\$id\registro-valores.txt"
  (Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Services\GPOS.Api' -ErrorAction SilentlyContinue).GetValueNames() | Out-File "$E\$id\registro-nombres.txt"
}
function Eventos([datetime]$desde){ Get-WinEvent -FilterHashtable @{LogName='Application';StartTime=$desde} -ErrorAction SilentlyContinue |
  Where-Object { $_.ProviderName -in 'GPOS.Api','GPOS.Instalacion','.NET Runtime','Application Error','MsiInstaller' } | Select-Object Id,ProviderName,LevelDisplayName,TimeCreated,Message }
```

## 2. Qué existe y qué no (para marcar «Bloqueado»)

| Dependencia | Estado al 2026-10-23 | Casos que bloquea |
|---|---|---|
| `GPOS.Api-SINFIRMA.msi` (T1-b, lo construye B) | **No existe.** No hay `instalador/Api/` en `origin/feature/modelo-ng` [V: `git ls-tree`] | MI-01 a MI-13, MI-N1 a MI-N5 |
| Segundo MSI de la API con versión mayor (`construir.ps1 -Version`) | No existe | MI-08 |
| `Preparar-Vm.ps1` (marcador `HKLM:\SOFTWARE\GPOS NG\LaboratorioTls\Id` y variables `GPOS_LAB_TLS_VM`, `GPOS_LAB_TLS_ID`) | **No existe en ninguna rama** [V: recorrí `origin/{a,b,c}/*`]; lo escribo yo | Todo caso con guion de #165 o #173 |
| #165 y #173 | Abiertos, sin unir ni revisar (A lo dice en `respuesta-fechas-vm.md:9`) | Los guiones no están en `feature/modelo-ng` |
| PR-V (`implantar-servidor`, `comprobar-servidor`, `red --modo un-equipo`) | Construido en `a/pr-v-verbos-servidor` @ `b43951af`; **sin PR, sin unir** | `--fase esquema` del paso 0 de DE-01; veredicto del verbo en DE-11, DE-14, DE-15 (R4 con PID); L-3; L-16 |
| Verbo `tls` | **No existe en ninguna rama** (aviso A→B del 23-oct); sin él, con `ModoRed` la API exige certificado y no arranca (4747) | Cualquier caso con `red`: L-3, L-16, HTTPS del DEMO |
| API de reportes en el DEMO (PR-D2, T4-06) | No instalada en el spike | `Reportes\render` en DE-12; puerto 5073 en DE-15 |
| #164 (T1-a, módulo de firma) | Abierto | F-1 y todo MSI firmado |
| Process Explorer (o System Informer) dentro de la VM | No consta en la imagen; la VM queda sin Internet tras `Cerrar-Preparacion.ps1` | DE-13 |
| Edge en la VM | La imagen de Windows Server 2025 puede no traerlo [I] (pregunta Q-5 de mi entrega del 22-oct, sin respuesta) | DE-13 |

**Casos que quedan «Bloqueado» y por qué** (se ejecutan cuando exista lo indicado; no los repito más abajo):

| ID | Caso | Bloqueado por |
|---|---|---|
| MI-B1 | L-3: instalar sin y con `red`; con y sin `urls` | PR-V (`red`) y `tls` |
| MI-B2 | L-15: reinicio con SQL lento, `auto` frente a `delayed-auto` | Servicio configurable (PR-V `servicios`) |
| MI-B3 | L-16: cadena completa de INS con `GPOS.Api.msi` primero | *Bundle*, PR-V, `tls` |
| MI-B4 | F-1 con el MSI de la API firmado (`construir.ps1 -Firmar`) | #164 y `signtool` en la VM |
| MI-B5 | L-6: introspección desde `GPOS.Reportes` | API de reportes instalada (PR-D2) |
| MI-B6 | L-9 a L-14 completos (PDF, `TEMP`, huérfanos, salida de red) | Servicio en `Running`; el spike cubre solo DE-13 |
| MI-B7 | Actualización mayor con el servicio en ejecución y arranque posterior a actualizar | Servicio configurable (PR-V) |
| DE-01-esquema | Paso 0 con `--fase esquema` (el texto de #173 lo escribe como si fuera de `GPOS.Migracion sistema`) | PR-V; hoy solo existen `sistema --login-api`, `actualizar` y `crear` [V: plan A 2.3] |
| DE-11-verbo | Veredicto de que el **verbo** deja el SDDL correcto para el usuario que instala | PR-V |
| DE-15-5073 | Puerto 5073 solo en loopback | API de reportes en el DEMO |
| DE-12-render | `Reportes\render` sin acceso a usuarios | API de reportes y T4-01 en el DEMO |

## 3. Observaciones previas a la VM sobre #165 y #173 (de QA; no corrijo nada)

Ordenadas por efecto en el resultado. Severidad = efecto sobre la **validez del laboratorio**, no sobre producción. Para A salvo indicación.

| # | Sev. | Observación | Evidencia | Qué pido |
|---|---|---|---|---|
| P-01 | **Alta** | El entorno que el guion pone al servicio es solo `Jwt__Clave`, `GPOS__Seguridad__ModoIdentidad=Amplio` y `ConnectionStrings__Sistema`. El DEMO Release exige además `GPOS__DataProtection__DpapiDemo=true` (si no, `ProteccionDatosInstalacion.Configurar` lanza «Una compilación Release exige el anillo con certificado…»), una carpeta del anillo accesible a la cuenta del servicio, `DpapiMaquina=false` y `ASPNETCORE_ENVIRONMENT=Production`. Sin ellos, DE-01-probar falla por una causa **distinta** de la pregunta del spike (D-2/D-4) y el resultado no decide nada. Además, `GPOS.Migracion` del paso 0 necesita el mismo entorno que la API (`Entorno-Migracion`, `Comun-Demo.ps1:358-369`) y no se dice cómo dárselo | `Probar-Spike-Amplio.ps1:106-109` frente a `instalador/Demo/scripts/herramientas/Comun-Demo.ps1:341-355` [V]; `src/GPOS.Core/Infraestructura/ProteccionDatosInstalacion.cs:76-79` [V]; que el paquete es Release: `Publicar-PaqueteDemo.ps1:8,95` [V] | Completar el entorno del guion y del paso 0, o decir que el spike usa `implantar-servidor --fase servicios` de PR-V |
| P-02 | **Alta** | El spike no prepara `%ProgramData%\GPOS NG`, `Api\` ni `Api\anillo`. La raíz da a Usuarios autenticados solo lectura (vector v3), así que la cuenta virtual **no puede crear** `Api\`; sin la carpeta el anillo y la licencia no se escriben. Y DE-12 da verde vacío (P-05). La preparación es de PR-V `--fase carpetas` o debe documentarse a mano con el SDDL del contrato | `spike-demo-modo-amplio.md` §Preparación (no la menciona); `RaizGposNg.wxs` (DACL de la raíz) [V] | Fijar cómo se crean las carpetas del spike (no la invento aquí) |
| P-03 | Media | El guion escribe `Environment` (l.112) **antes** de fijar la DACL de la clave (l.120). El plan 2.2 exige el orden contrario (crear → DACL → comprobar → escribir) para no abrir una ventana de lectura. Además la SDDL lleva dueño `O:SY`; fijar el dueño a SYSTEM desde .NET suele exigir `SeRestorePrivilege` habilitado, que el guion no activa [I; la revisión de PR-V lo anota en §7.6] | `Probar-Spike-Amplio.ps1:112` y `:120`; `plan-demo…:82` [V] | Reordenar o documentar la excepción; si `SetAccessControl` lanza, el caso es `No se pudo`, no `No cumple` |
| P-04 | Media | Ningún paso registra los orígenes de eventos `GPOS.Api` y `GPOS.Instalacion`. La cuenta virtual no puede crearlos (`ModoServicioApi.cs:218-224` en la rama de N-1) y sin origen **no hay 4767/4768/4770 en el Visor**: el diagnóstico queda ciego. DE-01-probar usa `-notcontains 4767` (l.133), que con el origen ausente nunca falla; solo se salva por la conjunción con `Running` y `200` | `Probar-Spike-Amplio.ps1:132-133` [V] | Precondición explícita (sección 7, DE-01-P0) |
| P-05 | Media | **Verdes vacíos** del guion: DE-13 escribe `Cumple` siempre (l.172, `resultado='MANUAL'`); DE-12 solo cuenta carpetas que **existen** (l.164); DE-11 pasa con el SDDL de fábrica porque solo busca `DC/WD/WO/SD` en ACE ajenas a SY/BA (l.150) y **no usa** `-UsuarioInstala` (declarado en l.29); DE-15 pasa con solo 5071 y sin comparar el PID | `Probar-Spike-Amplio.ps1:29,150,164,172,187` [V] | Regla de este documento: el JSON de esos casos **no decide**; decide la observación manual de la sección 7 |
| P-06 | Media | DE-14 exige **cero** roles de servidor (l.180), pero la escalera 2.2.2 admite `dbcreator` (paso 3), que es un rol de servidor. Si el spike llega al paso 3, DE-14 sale «No cumple» por construcción | `Probar-Spike-Amplio.ps1:180`; `plan-demo…:107-108` [V] | Decidir el criterio: «ningún rol de servidor salvo, si el paso 3 fue necesario, `dbcreator`» |
| P-07 | Media | Textos que quedaron viejos por uniones de ayer: (a) `FijarEscuchaPorOmision` ya no existe en `ModoServicioApi.cs` (#139/#140 unidos el 22-oct 21:58) [V], así que **G-PR4** de `construir.ps1` y la prueba T1-09 pierden su objeto («se retira sola» la guarda, pero el caso sintético sigue pidiéndose), y el §8 del documento de operaciones y el §7 de la guía («no debe instalarse fuera del laboratorio mientras…») describen otra cosa; (b) L-3 dice 4744 con `red` y la escucha por omisión: hoy **con `red` y sin `tls` el resultado es 4747** (`EscuchaServidor.cs`, aviso de A del 23-oct); (c) el spike dice que el cerrojo 2 y DM-04 «aún no está escrito» (`spike…md:41`) y #174 se unió el 23-oct 01:45: DE-13 espera **ausente**, no «FALLA esperada» | `ModoServicioApi.cs` en `feature/modelo-ng` [V: `git grep` sin resultados]; `gh pr view 139/140/174` [V] | Actualizar los tres textos antes del 18-nov |
| P-08 | Media | `Probar-Instalador.ps1` es del agente de impresión: `Argumentos-Estacion` agrega `ESTACION=1` y P-O1-7.8/.9 usan la *feature* `EstacionImpresion`; la del MSI de la API se llama `Api`. Con `-Msi <MSI de la API>`, P-O1-7.1 a .6 deberían funcionar por accidente (la *feature* `Api` es nivel 1 y la propiedad se ignora) [I]; .8 y .9 no. Además `L-2f` compara **todos** los grupos entre paréntesis del `sc sdshow`, incluida la SACL: el SDDL de fábrica trae `S:(AU;FA;…)` y el de Q-5 solo `D:`; si `sdshow` imprime `S:`, `mismasAce` da falso aunque la DACL sea correcta [I] | `Probar-Instalador.ps1:116-121, 242-266, 314-329` [V] | Parámetro de *feature* y propiedades; comparar solo la parte `D:` |
| P-09 | Media | La guía (esqueleto, l.60-61) y el contrato no declaran `FailureActionsWhen="failedToStopOrReturnedError"`, pero el documento de operaciones §7.2 dice que debe declararse para que una salida con código ≠ 0 cuente como fallo. Es contradicción entre documentos de A; la prueba T1-05 no lo vigila. MI-01 recoge `sc qfailureflag` para saber qué quedó | `guia-t1b…:60-61`; `operaciones…` §7.2 [V] | Decidir si va o no; L-4 (MI-N2) mide el efecto real |
| P-10 | Baja | `DE-01-probar` espera 20 s fijos y pide `/api/salud`. Con SQL Express recién arrancado y el DDL de Amplio puede tardar más [I]; y `200` en salud no prueba anillo, licencia ni base | `Probar-Spike-Amplio.ps1:125-135` [V] | Repetir tras 60 s antes de dar `No cumple`; pedir una sonda funcional (inicio de sesión del DEMO) |
| P-11 | Baja | `DE-12` y el procedimiento dejan abierto si `config` va cerrado; A eligió no tocar el vector v3 y pidió a B decidir (aviso `pr-d1-y-spike-amplio-abiertos.md:21`) | [V] | B decide antes del 23-nov; hasta entonces el criterio es el del vector v3 |

## 4. Orden de ejecución, duración y responsables

**Quién.** B, en `LFMB`, con `VM-SRV` (Windows Server 2025, 3 584 MB, 2 CPU, 60 GB, SQL Express dentro, ≈ 3,5 a 4,5 GB con SQL arrancado [I de mi diseño]). Sin agentes compilando en `LFMB` durante la ventana. Un técnico teclea; el agente de B o yo revisamos la evidencia **ya redactada** (`Recoger-Evidencia.ps1 -Vm VM-SRV -CarpetaInvitado C:\GPOS-LAB\evidencia`) en `M:\VM\evidencia`. Yo no ejecuto nada: OSHIN-LEGION no tiene VirtualBox y la regla del 2026-10-08 lo impide. Auditor-seguridad de A revisa DE-10, DE-11, DE-13 y MI-05 antes de dar el spike por cerrado.

**Duraciones [I, ±50 %]**, sin contar compilar los MSI ni publicar el DEMO:

| Sesión | Fecha propuesta (sin confirmar) | Contenido, en este orden | Tiempo |
|---|---|---|---|
| **S1** | 18-nov, mañana | Preparación (30 min) → G-N1 a G-N4 (10) → MI-N1 (10) → **MI-01** (25) → MI-02 (15) → MI-03 (10) → MI-04 (30) → MI-05 (20) → MI-06 (20) → MI-N2 (15) → MI-11 (40) | ≈ 3 h 45 min |
| **S2** | 18-nov, tarde (misma VM, desde `base`) | MI-07 (25) → MI-08 (25, necesita el segundo MSI) → MI-09 (15) → MI-10 (15) → MI-N3, MI-N4, MI-N5 (30) → MI-13 (20) → MI-12 FIPS (40, dos reinicios; **al final**, deja la VM sucia) | ≈ 2 h 50 min |
| **S3** | 23-nov, mañana | Preparación (30 min) → DE-01-P0 (20) → DE-01 con escalera (60 a 90) → DE-10 (10) → DE-11 (20) → DE-12 (15) → DE-13 (40) → DE-14 (20) → DE-15 (15) → *punto de control `LAB-SPIKE-VERDE`* → DE-01-N1 a N6 (60) → DE-16 (15) | ≈ 5 h 20 min |

Las ≈ 3 h de A para P-O1-7 (agente), F-1 y L-1 a L-2f (`propuesta-fechas-vm.md:11`) se suman a S1 y S2 si se hacen en la misma ventana; entonces la mañana del 18-nov no alcanza para S1 y recomiendo mover P-O1-7.1 a .9 del agente a S2. Si B solo puede dar **una** ventana, el orden de prioridad por riesgo es: MI-01, MI-05, MI-11, MI-N1, MI-N2, MI-09, MI-07, el resto.

**Puntos de control sugeridos** (nombres para `Puntos-Control.ps1`): `LAB-T1B-BASE-OK` (VM preparada, antes de instalar nada), `LAB-T1B-MI01` (MSI instalado y en verde), `LAB-T1B-FIPS`, `LAB-SPIKE`, `LAB-SPIKE-VERDE`.

**Preparación común** (30 min): restaurar `base`; iniciar sesión con la cuenta de laboratorio; crear `gpos-lab-usuario` (estándar); copiar a `C:\GPOS-LAB`: los dos guiones de A, `msi\GPOS.Api-SINFIRMA.msi` con su SHA-256 anotado (`Get-FileHash $msi -Algorithm SHA256`), el MSI de desarrollo del agente de impresión, el paquete del DEMO (S3) y Process Explorer; `.\Probar-Instalador.ps1 -Caso Guardas` y `.\Probar-Spike-Amplio.ps1 -Caso Guardas` deben imprimir `Guardas: cumplidas`. Anotar: nombre y SHA-256 de cada MSI/paquete, `version.json`, nombre del punto de control, versión de Windows (`[Environment]::OSVersion.VersionString`), si FIPS está activa.

## 5. Bloque G: negativos de las guardas (LS-11) de los dos guiones

Los dos guiones se niegan a correr si falta una guarda. Las pruebas de A son textuales; esto las confirma en la VM. **Origen:** `Probar-Instalador.ps1:49-61` y `Probar-Spike-Amplio.ps1:49-60` [V]. Todas dependen de `Preparar-Vm.ps1` (mío).

| ID | Caso | Cómo | Esperado | Rechazo |
|---|---|---|---|---|
| G-N1 | Sin elevación | PowerShell **no** elevado: `.\Probar-Spike-Amplio.ps1 -Caso Guardas` y `.\Probar-Instalador.ps1 -Caso Guardas` | Salida 1, «hace falta una sesión elevada (administrador). No se tocó nada.» Sin `C:\GPOS-LAB\evidencia` nuevo | Imprime `Guardas: cumplidas` o crea archivos |
| G-N2 | Sin variable | `Remove-Item Env:GPOS_LAB_TLS_VM`, repetir | «falta GPOS_LAB_TLS_VM=1» | Corre |
| G-N3 | Identificador distinto | `$env:GPOS_LAB_TLS_ID='otro'`, repetir | «el marcador … no coincide con GPOS_LAB_TLS_ID» | Corre |
| G-N4 | Sin marcador | Con punto de control previo: `Remove-Item 'HKLM:\SOFTWARE\GPOS NG\LaboratorioTls' -Recurse`, repetir | Se niega | Corre. Restaurar el punto de control |

Evidencia: código de salida (`$LASTEXITCODE`) y texto del error; después, `Get-Service GPOS.Api -ErrorAction SilentlyContinue` vacío y `Test-Path "$env:ProgramData\GPOS NG"` sin cambio. Duración total ≈ 10 min.

## 6. Bloque MI: MSI mínimo de la API (T1-b)

Todos **bloqueados por la existencia de `GPOS.Api-SINFIRMA.msi`** (sección 2). Valores esperados tomados de la guía (§3 y §6), el contrato (tabla «El MSI debe») y el documento de operaciones (§2, §5, §11). Los IDs `L-…` son de A y se citan, no se repiten.

### MI-01. Instalación limpia, elevada: servicio, cuenta, privilegios, recuperación y ausencia de entorno

- **Origen:** contrato «El MSI debe/no debe»; guía §3 y §8; operaciones L-1, L-1bis, L-2; pruebas textuales T1-05 a T1-07.
- **Objetivo:** que el MSI deje exactamente el servicio que el contrato describe y nada más: sin arrancarlo, sin entorno, sin red, sin secretos.
- **Precondiciones:** `base` restaurada; Windows Server 2025; SQL Express presente (no se usa); FIPS **no**; cuenta administradora elevada; red interna sin salida; sin servicio `GPOS.Api` ni carpeta `%ProgramData%\GPOS NG`.
- **Pasos:**
  1. `Get-FileHash $msi -Algorithm SHA256 | Tee-Object "$E\MI-01-sha256.txt"`.
  2. `$desde = Get-Date; Msi @('/i',"`"$msi`"") 'MI-01-instalar'` → anotar el código.
  3. `Foto 'MI-01'` (guarda `sc qc/qprivs/showsid/qsidtype/qfailure/qfailureflag/sdshow/query` y los valores ImagePath, ObjectName, Start, RequiredPrivileges).
  4. `Eventos $desde | Tee-Object "$E\MI-01\eventos.txt"`.
  5. Carpetas: `foreach($r in "$env:ProgramData\GPOS NG","$env:ProgramData\GPOS NG\config","$env:ProgramData\GPOS NG\Api","$env:ProgramFiles\GPOS NG\Api"){ Get-Acl -LiteralPath $r | Format-List Owner,Sddl | Tee-Object "$E\MI-01\acl-$((Split-Path $r -Leaf)).txt" }`.
  6. Entorno ausente: `(Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Services\GPOS.Api').GetValueNames() -contains 'Environment'` debe ser `False`.
  7. Sin escucha: `Get-NetTCPConnection -State Listen -LocalPort 5071,5073 -ErrorAction SilentlyContinue` vacío; `Test-Path 'HKLM:\SOFTWARE\GPOS NG\Servidor'` es `False` (el MSI no escribe `red`).
  8. Entrada de programas: `Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' | Where-Object DisplayName -like 'GPOS NG*' | Select-Object DisplayName,DisplayVersion,Publisher`.
  9. Firma: `Get-AuthenticodeSignature 'C:\Program Files\GPOS NG\Api\GPOS.Api.exe' | Select-Object Status` → `NotSigned` (es el MSI sin firma).
- **Evidencia:** los archivos de `Foto`, el `.log` de MSI, `eventos.txt`, las ACL, SHA-256 del MSI.
- **Esperado** (todo [I] hasta ejecutar; la fuente de cada valor está arriba):
  - Código `0` (no `3010`).
  - `sc qc`: `TYPE 10 WIN32_OWN_PROCESS`, `START_TYPE 2 AUTO_START` (Q-8), `ERROR_CONTROL 1 NORMAL`, `BINARY_PATH_NAME` = `"C:\Program Files\GPOS NG\Api\GPOS.Api.exe" --servicio` (un solo argumento, termina en ` --servicio`), `SERVICE_START_NAME` = `NT SERVICE\GPOS.Api`, sin dependencias.
  - `sc query`: `STOPPED` (el MSI no arranca el servicio).
  - `sc qprivs`: **exactamente** `SeChangeNotifyPrivilege`. Una lista vacía es FALLA (en `sc`, vacío significa «sin restricción»).
  - `sc showsid`: `S-1-5-80-546908902-3265840057-98699379-1016526221-3413751906` [la guía lo calcula con `IdentidadProceso.SidDeServicio`; la VM lo confirma].
  - `sc qsidtype`: cualquier valor **menos `RESTRICTED`**; anotar si sale `NONE` o `UNRESTRICTED` (la guía dice «sin `ServiceSid`»; el plan del DEMO habla de «sin restricción»: la VM aclara).
  - `sc qfailure`: reinicio, reinicio, reinicio, 60 000 ms, contador a 86 400 s, `COMMAND_LINE` vacío. `sc qfailureflag`: anotar el valor (P-09).
  - Sin valor `Environment`; sin escucha; sin `HKLM\SOFTWARE\GPOS NG\Servidor`.
  - `Sddl` de `GPOS NG` y `config` = `O:SYG:SYD:PAI(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICI;0x1200a9;;;AU)`; `Api` = `O:SYG:SYD:PAI(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICI;0x1301bf;;;S-1-5-80-546908902-3265840057-98699379-1016526221-3413751906)` (el SID de la ACE debe ser el de `sc showsid`). `Get-Acl` puede reordenar o mostrar `FA` como máscara: comparar ACE por ACE antes de concluir.
  - `Program Files\GPOS NG\Api` sin escritura para Usuarios ni Usuarios autenticados.
  - `Publisher` = `GSF` (provisional, Q-4).
- **Rechazo (No cumple):** código ≠ 0; servicio `RUNNING`; `ImagePath` con más de un argumento, con `--urls`/`--environment` o sin `--servicio`; cuenta distinta de la virtual o con contraseña; privilegios distintos; `RESTRICTED`; existe `Environment`; hay escucha o la clave `Servidor`; `Api\` con ACE para Usuarios/Authenticated Users o con un SID distinto del de `showsid`; `GPOS NG\` con DACL distinta del vector.
- **Marca:** [I]. **Duración:** 25 min.

### MI-02. Los archivos de la publicación están completos y son los de la compilación (riesgo RT1-2)

- **Origen:** guía §4 (RT1-2: publicación autocontenida en carpeta, cientos de archivos, bibliotecas nativas de PuppeteerSharp y QuestPDF [I]).
- **Objetivo:** que la recolección de archivos de WiX (`Files`/`HarvestDirectory`) no haya omitido nada que la API necesite en tiempo de ejecución.
- **Precondiciones:** MI-01 en verde. B entrega junto al MSI `C:\GPOS-LAB\msi\publicacion.sha256` generado fuera de la VM con el mismo formato (abajo) sobre la carpeta de `dotnet publish`.
- **Pasos:**
  1. En la VM: `$base='C:\Program Files\GPOS NG\Api\'; Get-ChildItem $base -Recurse -File | ForEach-Object { '{0}  {1}' -f (Get-FileHash $_.FullName -Algorithm SHA256).Hash, $_.FullName.Substring($base.Length) } | Sort-Object | Set-Content "$E\MI-02-instalado.sha256"`.
  2. Comparar: `Compare-Object (Get-Content C:\GPOS-LAB\msi\publicacion.sha256 | Sort-Object) (Get-Content "$E\MI-02-instalado.sha256" | Sort-Object)` y anotar el conteo de archivos de cada lado.
  3. Presencia puntual: `GPOS.Api.exe`, `GPOS.Api.dll`, `appsettings.json`, `web.config` o equivalente si la publicación lo trae, y las carpetas `runtimes\win-x64\native` o las que la publicación genere [I: B lista cuáles son].
  4. Higiene: `Get-ChildItem $base -Recurse -File -Include *.pdb,*.Tests.dll,appsettings.Development.json`; y `Select-String -Path "$base*.json" -Pattern '"Clave"\s*:\s*"[^"]+"','Password=' -List | Select-Object Filename` (solo nombres de archivo).
  5. Sin cambios por el instalador: la versión del archivo `(Get-Item "$base\GPOS.Api.exe").VersionInfo.ProductVersion` debe coincidir con `DisplayVersion` de MI-01 (por `!(bind.FileVersion.ApiExe)`).
- **Esperado:** `Compare-Object` sin diferencias; cero `*.pdb`/`*.Tests.dll`/`Development.json`; ningún `Clave` con valor ni `Password=`; versiones iguales. **Rechazo:** cualquier archivo faltante o de más, o diferencia de hash.
- **Marca:** [I]. **Duración:** 15 min.

### MI-03. Carpetas y DACL (L-7, P-O1-5) tras instalar

Ya cubierto por los pasos 5 y el esperado de MI-01. Se separa para anotar la **regla de no escritura**: con `icacls` de `Api\`, `config\`, la raíz y `Program Files\GPOS NG\Api`, ninguna ACE concede escritura a `BUILTIN\Users` ni a `Authenticated Users`; `icacls "$env:ProgramData\GPOS NG\Api" /verify` sin errores. Comprobar además que **el MSI no creó** `Api\anillo`, `Api\temp`, `Api\registros`, `Licencia\`, `Licencia\Entrada` ni `Reportes\`: `Get-ChildItem "$env:ProgramData\GPOS NG" -Recurse -Force | Select-Object -ExpandProperty FullName` debe listar solo `config` y `Api` (ADR-77, puntos 4 y 5; la guía §3 lo exige). **Rechazo:** cualquier carpeta de otro componente. **Duración:** 10 min.

### MI-04. Orígenes de eventos y rechazos propios del servicio (L-2bis, L-2c, L-2d, L-2e)

- **Origen:** operaciones §11; `Probar-Instalador.ps1:277-312`.
- **Pasos:** con el MSI instalado (MI-01 en verde) y `LAB-T1B-MI01` tomado: `.\Probar-Instalador.ps1 -Caso L-2bis`; `-Caso L-2c -ApiExe 'C:\Program Files\GPOS NG\Api\GPOS.Api.exe'`; **punto de control** y `-Caso L-2d -Msi $msi`; restaurar; **punto de control** y `-Caso L-2e -Msi $msi`.
- **Qué agrego a lo de A:**
  - L-2bis: además de «existe y bajo `%WINDIR%`», anotar el `EventMessageFile` literal de cada origen (`Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Application\GPOS.Api' -Name EventMessageFile`) y que el archivo tenga el mensaje legible en el Visor (abrir el 4767 de L-2c).
  - L-2c: confirmar que el servicio **no cambió de estado** (`sc query` antes y después) y que no queda escucha ni proceso `GPOS.Api.exe` vivo (`Get-Process GPOS.Api -ErrorAction SilentlyContinue`). Texto del evento esperado: `ARRANQUE_MODO: se pidió --servicio y el proceso no corre bajo el Administrador de servicios` [V: `ModoServicioApi.cs`, `Decidir`].
  - L-2d: tras borrar el origen, el 4767 debe llegar por la **reserva** (`RegistroEventosReserva`); si el Visor dice «no se encuentra la descripción» pero muestra el texto, es lo previsto [I].
  - L-2e: la reparación (`/fa`) debe dejar `sc qprivs` con un solo privilegio (`OnReinstall="yes"`).
- **Esperado/Rechazo:** los de A (`Cumple` si `salio`, código 1, texto en `Console.Error` y ≥ 1 evento 4767; en L-2e, `ARRANQUE_PRIVILEGIOS` y servicio `STOPPED`). **Rechazo extra:** un evento 4767 con SID de usuario real, cadena de conexión o ruta del perfil del usuario (S-05).
- **Dependencia:** `Preparar-Vm.ps1`. **Duración:** 30 min.

### MI-05. SDDL del objeto de servicio (Q-5, L-2f) y pruebas con cuentas reales

- **Origen:** contrato «SDDL del objeto de servicio» (firmada por el propietario el 2026-10-22); `Probar-Instalador.ps1:314-330`.
- **Pasos:**
  1. `.\Probar-Instalador.ps1 -Caso L-2f`. Si sale «No cumple», **no concluir todavía**: ver P-08; guardar `sc sdshow GPOS.Api` y comparar a mano solo la parte `D:`.
  2. A mano (elevado): `sc.exe sdshow GPOS.Api | Tee-Object "$E\MI-05-sdshow.txt"`; esperado, la DACL `D:(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLORC;;;BU)`; anotar si hay `S:`.
  3. Como `gpos-lab-usuario` (cuenta estándar): `Get-Service GPOS.Api` (debe funcionar), `sc.exe query GPOS.Api` (debe funcionar), `sc.exe qc GPOS.Api` (debe funcionar), `sc.exe start GPOS.Api` (denegado), `sc.exe stop GPOS.Api` (denegado), `sc.exe config GPOS.Api DisplayName= x` (denegado), `sc.exe sdset GPOS.Api "D:(A;;GA;;;WD)"` (denegado), `sc.exe delete GPOS.Api` (denegado).
  4. Como administrador **no elevado** (token filtrado: `BA` solo para denegar): las mismas órdenes; esperado: `query`/`qc` permitidos; `start`/`stop`/`config`/`delete` denegados. Elevado: `sc.exe start GPOS.Api` y `stop` permitidos (el inicio fallará por configuración, MI-06).
  5. Máscara de `BU` por letras: `CC`, `LC`, `SW`, `LO`, `RC` (consultar, enumerar dependientes, interrogar, leer el descriptor); ninguna de `RP` (iniciar), `WP` (detener), `DT` (pausar), `DC` (reconfigurar), `SD` (borrar), `WD`, `WO`.
- **Esperado:** SDDL = el firmado (mismas ACE); lo de los pasos 3 y 4 como se indica. **Rechazo:** `BU` o `AU` con alguna de las letras prohibidas; el usuario estándar detiene o reconfigura; `util:PermissionEx` no aplicado (SDDL de fábrica en `sdshow`).
- **Marca:** el valor es de A y está marcado «a comprobar en la VM»; que WiX 5 admita `util:PermissionEx` dentro de `ServiceInstall` también es [I] (contrato). **Duración:** 20 min.
- **No confundir con DE-11:** el SDDL del DEMO (DM-09) concede iniciar y detener al usuario que instala; el del MSI (Q-5) no. Son dos SDDL distintos a propósito.

### MI-06. Qué ocurre al arrancar un servicio recién instalado, sin configuración

- **Origen:** `Program.cs`: orden de arranque [V] (`ComprobarArranque` → archivo de instalación → `ProtegerClaveJwt` → cadena `Sistema` → `ProteccionDatos.Configurar` → `EscuchaServidor.Preparar`).
- **Objetivo:** fijar el comportamiento esperado del servicio **solo con el MSI**. El servicio es `auto`: tras el primer reinicio de la VM intentará arrancar. El resultado correcto no es `Running`, es un rechazo **claro, sin secretos y sin efectos secundarios**. Cubre «clave JWT ausente», «sin SQL» y «sin anillo» en el contexto del MSI solo.
- **Precondición:** MI-01 en verde; `Get-ChildItem "$env:ProgramData\GPOS NG" -Recurse -Force | % FullName > "$E\MI-06-antes.txt"`.
- **Pasos:** `$desde = Get-Date; sc.exe start GPOS.Api; Start-Sleep 20; sc.exe query GPOS.Api; Eventos $desde | Tee-Object "$E\MI-06-eventos.txt"`; esperar 3 min y repetir `sc.exe query` y `Eventos` (recuperación: 3 reinicios a los 60 s); `Get-NetTCPConnection -State Listen -LocalPort 5071,5073 -ErrorAction SilentlyContinue`; repetir el listado de `GPOS NG` y comparar con `MI-06-antes.txt`.
- **Esperado [I]:**
  - El servicio **no llega a `RUNNING`** (error 1053 o 1067 del Administrador de servicios) porque falta, como mínimo, la cadena `ConnectionStrings:Sistema`, la clave `Jwt:Clave` y el anillo con certificado (la API Release exige `GPOS:DataProtection:Anillo:CertificadoServidor` o `DpapiDemo`; `ProteccionDatosInstalacion.cs:62-79` [V]). Anotar **cuál es el primer fallo** (excepción del runtime, 4743, etc.); ninguno es hallazgo.
  - **Sin 4767** (la identidad y los privilegios sí pasan: el servicio corre con la cuenta virtual y un solo privilegio) y sin 4768/4770.
  - Texto de los eventos sin cadenas de conexión, sin valores de clave y sin rutas de perfiles de usuarios.
  - Recuperación: 3 reintentos separados ≈ 60 s y luego detenido.
  - Sin escucha en 5071/5073; **sin cambios** en el listado de carpetas (el servicio no creó `anillo`, `Licencia`, `temp` ni `registros` antes de validar la configuración).
- **Rechazo:** `Running`; un puerto abierto; carpetas nuevas bajo `GPOS NG`; un valor de configuración o una clave en cualquier evento; un 4767 de identidad (significaría que el SID del MSI y el calculado por el código difieren, **hallazgo Alto**).
- **Duración:** 20 min.

### MI-07. Reparación e idempotencia: lo que `/fa` restaura

- **Origen:** operaciones L-8; `ServiceConfig OnInstall/OnReinstall="yes"` [V: guía §3]; contrato.
- **Objetivo:** saber qué atributos de seguridad se **autorrepararan** al reparar y cuáles no. Que no se restaure algo no es forzosamente falla, pero cambia la recomendación de operación.
- **Precondición:** MI-01 en verde; `Foto 'MI-07-base'`.
- **Pasos:** (1) alterar: `sc.exe privs GPOS.Api SeChangeNotifyPrivilege/SeCreateGlobalPrivilege`; `sc.exe config GPOS.Api obj= LocalSystem start= demand`; `sc.exe sdset GPOS.Api "D:(A;;GA;;;WD)"` (**solo laboratorio**); borrar una DLL propia de `Api\` (`Remove-Item 'C:\Program Files\GPOS NG\Api\<una GPOS*.dll>'`); borrar la clave del origen `GPOS.Api`. (2) `Msi @('/fa',"`"$msi`"") 'MI-07-reparar'`. (3) `Foto 'MI-07-despues'` y `Compare-Object (Get-Content "$E\MI-07-base\sc-qc.txt") (Get-Content "$E\MI-07-despues\sc-qc.txt")`, y lo mismo con `qprivs`, `sdshow`, `qsidtype`. (4) Reinstalar la misma versión sin `/fa`: `Msi @('/i',"`"$msi`"") 'MI-07-misma-version'` y anotar el código (no se espera error; [I] puede salir `0` sin cambios). (5) `Msi @('/fa',"`"$msi`"")` una segunda vez: `Foto` idéntica (idempotencia).
- **Esperado:** código `0`; cuenta, tipo de inicio, privilegios, DLL y origen restaurados (declarado por A); **anotar** si el SDDL del servicio se restauró (si no, es observación para operaciones, porque `PermissionEx` puede no reaplicarse en reparación [I]); segunda pasada sin diferencias.
- **Rechazo:** la reparación deja `LocalSystem` o un privilegio sobrante; falla con 1603 sin revertir; cambia la DACL de `Api\` o de la raíz.
- **Duración:** 25 min.

### MI-08. Actualización mayor y degradación (`MajorUpgrade`)

- **Origen:** guía §3 (`MajorUpgrade` con `DowngradeErrorMessage`, `UpgradeCode` nuevo); operaciones §10.
- **Bloqueado además por** el segundo MSI (versión mayor): B lo construye con `construir.ps1 -Version <x.y.z+1>` y entrega ambos con su SHA-256.
- **Pasos:** (1) instalar v1; sembrar un centinela: `New-Item "$env:ProgramData\GPOS NG\Api\centinela.txt"` con texto «no borrar» (la carpeta es del servicio; crearlo como administrador es parte del caso). (2) `Foto 'MI-08-v1'`. (3) `Msi @('/i','"…v2.msi"') 'MI-08-actualizar'`. (4) `Foto 'MI-08-v2'`; `Get-ItemProperty …\Uninstall\*` (una sola entrada «GPOS NG API», `DisplayVersion` nueva); hash de `GPOS.Api.exe` = el de v2. (5) Degradar: `Msi @('/i','"…v1.msi"') 'MI-08-degradar'`.
- **Esperado:** (3) código `0`; una entrada de programas; `sc qc`, `qprivs`, `sdshow` y `showsid` iguales a v1; el servicio queda `STOPPED` (el contrato no tiene `Start`; **anotar** que una actualización con el servicio en ejecución lo dejaría detenido hasta que la cadena o el técnico lo arranque, MI-B7); el centinela y las DACL de `GPOS NG`, `config` y `Api\` intactos (la raíz es `Permanent="yes"`). (5) código ≠ 0 (1603 o 1638 [I]) y el texto «Ya está instalada una versión más reciente de la API de GPOS NG.» en el registro; el estado instalado no cambia.
- **Rechazo:** dos entradas de programas o dos servicios; el centinela borrado; `sc` distinto; la degradación se instala.
- **Duración:** 25 min.

### MI-09. Desinstalación y residuos

- **Origen:** operaciones §10 («desinstalar la API no borra datos»); contrato (`ServiceControl Stop="both" Remove="uninstall" Wait="yes"`); `Permanent="yes"` de la raíz y `config\` [V: `RaizGposNg.wxs`].
- **Pasos:** con MI-01 y el centinela sembrado: `$desde = Get-Date; Msi @('/x',"`"$msi`"") 'MI-09-desinstalar'`; luego `sc.exe query GPOS.Api; sc.exe qc GPOS.Api`; `Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Services\GPOS.Api'`; `Test-Path 'C:\Program Files\GPOS NG\Api'` y `Test-Path 'C:\Program Files\GPOS NG'`; `Get-Acl "$env:ProgramData\GPOS NG"` y `…\config`; `Get-ChildItem "$env:ProgramData\GPOS NG" -Recurse -Force`; `[System.Diagnostics.EventLog]::SourceExists('GPOS.Api')` y `('GPOS.Instalacion')`; `Eventos $desde`.
- **Esperado:** código `0`; servicio inexistente (`sc query` devuelve 1060); la clave del servicio **desaparece** (si queda marcada para eliminación, error 1072: reiniciar y anotarlo, no es falla del MSI); `Program Files\GPOS NG\Api` borrada; **`%ProgramData%\GPOS NG` y `config\` siguen con la misma DACL**; `Api\` con el centinela sigue (si estuviera vacía, Windows Installer la quitaría: anotar); los dos orígenes de eventos se retiran (anotar que `GPOS.Instalacion` desaparece también para la estación de impresión, MI-13); sin entrada en programas.
- **Rechazo:** datos borrados (centinela, anillo, licencia); servicio o clave del servicio que persisten sin 1072; raíz o `config` borradas o con DACL distinta; el desinstalador deja un proceso `GPOS.Api.exe` vivo.
- **Duración:** 15 min.

### MI-10. Reinstalar tras desinstalar, con la carpeta `Api\` residual

- **Pasos:** a continuación de MI-09: `Msi @('/i',"`"$msi`"") 'MI-10-reinstalar'`; `Foto 'MI-10'`; `Get-Acl "$env:ProgramData\GPOS NG\Api" | Format-List Owner,Sddl`; `Test-Path "$env:ProgramData\GPOS NG\Api\centinela.txt"`.
- **Esperado:** código `0`; la comprobación previa acepta la carpeta residual (dueño SYSTEM, DACL del contrato con el SID de `GPOS.Api`, fila `Servicio=GPOS.Api`); `showsid` igual que en MI-01 (el SID es función del nombre); centinela intacto.
- **Rechazo:** rechazo 25101 sobre una carpeta que el propio MSI dejó; el centinela desaparece.
- **Duración:** 15 min.

### MI-11. Rechazos de la comprobación previa de carpetas con el MSI de la API (ADR-77, punto 3)

- **Origen:** P-O1-7 (A) cubre la raíz con el MSI del agente. Aquí se repite con el MSI de la API y se agrega lo propio: `Api\` (fila `GposCarpetaPrevia` `Servicio=GPOS.Api`, `CrearSiFalta=0`) y `config\`.
- **Cómo:** cada sub-caso parte de punto de control propio. Para la raíz, `.\Probar-Instalador.ps1 -Caso P-O1-7.1 -Msi $msi` a `.5` y `.6` **pueden** correr con el MSI de la API (P-08; [I]); si no, a mano con `Msi @('/i',"`"$msi`"") 'MI-11x'`. Los sub-casos de `Api\` y `config\` son manuales: se prepara la raíz correcta con una instalación y desinstalación previas (MI-01 y MI-09) y se planta la carpeta antes de instalar.
- **Sub-casos y esperado.** En todos los rechazos: código `1603`, `25101` y líneas `GposComprobarCarpetasPrevias:` con el código en el registro; **no** se crea el servicio ni `Program Files\GPOS NG\Api`; y **la carpeta plantada queda exactamente como estaba** (dueño, SDDL y lista de hijos antes y después: `Get-Acl … | Format-List Owner,Sddl; Get-ChildItem -Force -Recurse`).

| ID | Se planta | Código esperado en el registro |
|---|---|---|
| MI-11a | La raíz `%ProgramData%\GPOS NG` creada por `gpos-lab-usuario` (se le cambia el dueño con `icacls <ruta> /setowner gpos-lab-usuario`) | `DUENO_NO_PERMITIDO` |
| MI-11b | La raíz como unión (`cmd /c mklink /J "%ProgramData%\GPOS NG" C:\GPOS-LAB\destino-union`) | `PUNTO_DE_REANALISIS`; la unión sigue y su destino no cambió |
| MI-11c | `Api\` con dueño `BUILTIN\Users` | `DUENO_NO_PERMITIDO` |
| MI-11d | `Api\` con ACE `Users:(OI)(CI)M` (`icacls … /grant "*S-1-5-32-545:(OI)(CI)M"`) | `ESCRITOR_NO_PERMITIDO` |
| MI-11e | `Api\` con Modificar para el SID de `NT SERVICE\GPOS.Reportes` (`sc.exe showsid GPOS.Reportes` da el SID sin tener el servicio) | `ESCRITOR_NO_PERMITIDO` [I: la fila solo admite el SID de su propio servicio] |
| MI-11f | `Api\` como unión | `PUNTO_DE_REANALISIS` |
| MI-11g | `config\` con `Users` Modificar | `ESCRITOR_NO_PERMITIDO` [I: `config` también tiene fila] |
| MI-11h | **Control positivo:** `Api\` con dueño SYSTEM y la DACL exacta del contrato | Instala (código `0`) |
| MI-11i | Un archivo llamado `GPOS NG` en `%ProgramData%` | `NO_ES_CARPETA` |

- **Rechazo:** cualquier sub-caso que instale; cualquier rechazo que modifique la carpeta plantada; MI-11h rechazado.
- **Evidencia sin evento:** en un equipo sin `GPOS.Instalacion` el rechazo solo queda en el `.log` de MSI (S-11): citar la línea, no esperar 4753/4754 en el Visor.
- **Duración:** 40 min (9 sub-casos de ≈ 4 min con puntos de control).

### MI-12. Con la directiva FIPS activa (P-O1-7.7 con el MSI de la API)

- **Origen:** P-O1-7.7 de A (`-ApiMsi`); `IdentidadProceso` calcula el SID con SHA-1; la acción previa es `net472` y no debe usar `SHA256Managed`.
- **Pasos:** punto de control `LAB-T1B-FIPS` **desde el anfitrión**; `.\Probar-Instalador.ps1 -Caso P-O1-7.7-preparar`; reiniciar; `.\Probar-Instalador.ps1 -Caso P-O1-7.7-ejecutar -Msi <MSI del agente de desarrollo> -ApiMsi $msi`; luego a mano con FIPS activa: `Msi @('/i',"`"$msi`"") 'MI-12-api'`, `Foto 'MI-12'`, `sc.exe start GPOS.Api`, `Eventos`, `Msi @('/fa',"`"$msi`"")`, `Msi @('/x',"`"$msi`"")`; `Select-String "$E\MI-12-api.log" -Pattern 'InvalidOperationException','FIPS' -List`. Restablecer con `-Caso P-O1-7.7-restablecer` o restaurar `base`.
- **Esperado:** instalación, reparación y desinstalación con código `0`; `Foto` idéntica a la de MI-01; al iniciar, **sin 4767 de identidad** (el rechazo posterior es de configuración, como MI-06); sin `InvalidOperationException` en ningún registro.
- **Rechazo:** `InvalidOperationException` o mensajes de algoritmo no permitido en el registro del MSI; 4767 `ARRANQUE_IDENTIDAD` (el cálculo del SID con SHA-1 falla con FIPS).
- **Duración:** 40 min (dos reinicios). **Va el último de S2**: deja la VM sucia.

### MI-13. Convivencia con el MSI de la estación de impresión (raíz compartida)

- **Origen:** `RaizGposNg.wxs` (GUID fijos, `Permanent="yes"`, «ningún MSI es dueño de la raíz»); `Package.wxs` del agente (solo trae la raíz).
- **Pasos:** (1) instalar la estación con `ESTACION=1` (`Msi @('/i','"C:\GPOS-LAB\msi\GPOS.AgenteImpresion-DESARROLLO.msi"','ESTACION=1') 'MI-13-estacion'`); `Get-Acl` de la raíz. (2) Instalar la API: debe aceptar la raíz creada por la acción de la estación. (3) Desinstalar la API (MI-09) y comprobar que la estación sigue instalada y que la raíz y `config\` conservan la DACL. (4) Reinstalar la API, desinstalar la estación y repetir. (5) El orden inverso: API primero, luego estación.
- **Esperado:** los cuatro movimientos con código `0`; la `Sddl` de la raíz idéntica en cada paso; sin carpetas de otro componente. Anotar el efecto en la estación del retiro del origen `GPOS.Instalacion` (los eventos 4753 a 4755 dejan de verse hasta reinstalar la API).
- **Rechazo:** cambio de DACL o de dueño de la raíz; el MSI de una pieza borra la raíz.
- **Marca:** [?] porque depende de que el MSI de desarrollo del agente siga siendo compatible con el de la API. **Duración:** 20 min.

### Negativos del MSI

| ID | Caso | Cómo (comando exacto) | Esperado | Rechazo |
|---|---|---|---|---|
| **MI-N1a** | Instalar como **usuario estándar** | `runas /user:%COMPUTERNAME%\gpos-lab-usuario "msiexec.exe /i C:\GPOS-LAB\msi\GPOS.Api-SINFIRMA.msi /qn /norestart /l*v C:\GPOS-LAB\evidencia\MI-N1a.log"` (el usuario necesita leer el MSI y escribir el registro) | Falla por privilegios (código 1925 u otro ≠ 0 en el registro [I]); `Get-Service GPOS.Api -EA SilentlyContinue` vacío; no existen `Program Files\GPOS NG`, `ProgramData\GPOS NG` ni los orígenes | Algo queda instalado o creado |
| **MI-N1b** | Instalar como administrador **sin elevar** | PowerShell no elevado: `Msi @('/i',"`"$msi`"") 'MI-N1b'` | Igual que N1a | Instala |
| **MI-N2** | Servicio con **cuenta distinta** (L-4) | Tras MI-01: `$desde=Get-Date; sc.exe config GPOS.Api obj= LocalSystem; sc.exe start GPOS.Api`; esperar 4 min; `sc.exe query GPOS.Api; Eventos $desde`; luego repetir con `obj= "NT AUTHORITY\LocalService"` y `obj= "NT AUTHORITY\NetworkService"`; reparar con `Msi @('/fa',"`"$msi`"")` y `sc.exe qc GPOS.Api` | Cada intento: 4767 `ARRANQUE_IDENTIDAD` con el SID real y el esperado, salida 1, **sin escucha** abierta (`Get-NetTCPConnection -State Listen -OwningProcess (Get-Process GPOS.Api).Id` imprime nada); recuperación 3 veces a ≈ 60 s y luego `STOPPED` (L-4); la reparación devuelve la cuenta virtual | Corre con la cuenta ajena; abre un puerto; la reparación no la devuelve; reinicios indefinidos |
| **MI-N3** | **Servicio `GPOS.Api` preexistente** (el DEMO y el MSI son excluyentes) | `sc.exe create GPOS.Api binPath= "C:\Windows\System32\notepad.exe" start= demand` y luego `Msi @('/i',"`"$msi`"") 'MI-N3'` | [I] la guía §7 espera que `ServiceInstall` falle; **anotar lo que ocurre de verdad**: rechazo con mensaje claro, o el MSI reconfigura el servicio ajeno | El MSI se apropia del servicio **conservando** un valor `Environment` o una DACL de clave que no puso él (en el DEMO ese valor trae la clave K3): hallazgo Alto. Anotar solo nombres de valores |
| **MI-N4** | **Clave JWT en el lugar equivocado:** que el MSI no escriba entorno ni secretos | Tras MI-01: `(Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Services\GPOS.Api').GetValueNames()`; `Get-ChildItem 'C:\Program Files\GPOS NG\Api','C:\ProgramData\GPOS NG' -Recurse -File | Select-String -Pattern 'Jwt__Clave','Password=' -List | Select-Object Path` | Sin valor `Environment`; sin coincidencias | Cualquier coincidencia o valor `Environment` |
| **MI-N5** | **Propiedad pública `INSTALLFOLDER`:** que no se instale el binario del servicio fuera de `Program Files` | `Msi @('/i',"`"$msi`"",'INSTALLFOLDER=C:\GPOS-LAB\fuera\') 'MI-N5'`; luego `sc.exe qc GPOS.Api` | [?] **A decide el comportamiento**: lo sano es que se ignore o se rechace. Anotar el `BINARY_PATH_NAME` resultante y los permisos de `C:\GPOS-LAB\fuera` (heredados de `C:\`: Usuarios autenticados con Modificar, [I]) | El servicio apunta a una carpeta donde un usuario estándar puede reemplazar el binario (D-5 y DM-08 de A: binarios en `Program Files`). Severidad Media si es solo administrador quien puede pasar la propiedad |

Para «sin SQL» y «puerto ocupado» el MSI solo no sirve (no llega a esos puntos, MI-06): los cubre el spike (DE-01-N1 y DE-01-N2).

## 7. Bloque DE: spike del modo Amplio (#173)

**Qué decide el spike (D-2 y D-4).** ¿La API principal arranca y atiende como servicio de Windows con la cuenta virtual `NT SERVICE\GPOS.Api` en modo Amplio, con DPAPI de usuario y con el esquema migrado por `GPOS.Migracion`? Sí → el DEMO pasa a dos servicios. No → el DEMO se congela en `demo/2026-10-15` (alternativa (b) de la HOJA) y se escala a B y al propietario antes de seguir con PR-V.

**Reglas del spike** (plan 5, condiciones; `spike…md` §Reglas): solo en la VM desde `base`; datos de demostración; la clave la genera el guion de A en proceso (nunca por línea de comandos, parámetro, salida ni evidencia); **prohibido** `sysadmin`, `CONTROL SERVER`, `securityadmin`, `serveradmin`, `ALTER ANY LOGIN` e `IMPERSONATE` para la cuenta virtual «para ver si arranca»: si solo funciona con alguno es **FALLA del spike**, se anota el error y se escala. La evidencia es solo «presente/ausente» y la SDDL.

**Regla de este documento para el JSON del guion.** Por P-05, el JSON de DE-11, DE-12, DE-13 y DE-15 **no decide**. Cada uno de esos casos se cierra con la observación manual descrita aquí y se anota `No se pudo` cuando falte la precondición.

### DE-01-P0. Preparación específica del spike (antes de DE-01)

| # | Paso | Estado |
|---|---|---|
| 1 | Paquete DEMO publicado con `Publicar-PaqueteDemo.ps1` desde `feature/modelo-ng` **en `67b4353a` o posterior** (trae PR-4 #139/#140, #171 y #174), extraído en `C:\GPOS-LAB\paquete\GPOS-Demo`. Anotar `version.json` y su SHA-256. Sin `-ConApiReportes` (basta el DEMO actual) | Disponible; no se publicó ninguno desde ese commit [I] |
| 2 | Edge instalado y Process Explorer copiado a la VM | Pregunta a B (sección 9) |
| 3 | Registrar los orígenes: `[System.Diagnostics.EventLog]::CreateEventSource('GPOS.Api','Application')` y `('GPOS.Instalacion','Application')` (en .NET Framework dejan `EventLogMessages.dll` de `Framework64\v4.0.30319` como archivo de mensajes, igual que el MSI [I]). Es una **desviación declarada** (P-04): lo hará `implantar-servidor --fase servicios` en PR-V | Manual |
| 4 | Carpetas `%ProgramData%\GPOS NG`, `Api\`, `Api\anillo` con la DACL del contrato (P-02) | **Decide A** cómo; hasta entonces `No se pudo` |
| 5 | Entorno completo del servicio y de `GPOS.Migracion` (`DpapiDemo`, carpeta del anillo, `DpapiMaquina=false`, `ASPNETCORE_ENVIRONMENT=Production`; P-01) | **Decide A** |
| 6 | SQL Express arrancado (`Get-Service 'MSSQL$SQLEXPRESS'`), cuenta de Windows administradora con `sysadmin` (para el paso 0 solamente) | Manual |

### DE-01. La principal arranca como servicio con `NT SERVICE\GPOS.Api`, modo Amplio y DPAPI de usuario

- **Texto de origen** (`plan-demo…:253`): «DE-01 spike (principal servicio en Amplio y DPAPI, D-2 y D-4)»; pregunta (`plan-demo…:278`): «¿la principal arranca como `NT SERVICE\GPOS.Api` en Amplio con DPAPI de usuario?».
- **Objetivo:** responder D-2 y D-4 con la escalera de privilegios SQL de 2.2.2, midiendo el **primer** paso que funcione.
- **Precondiciones:** DE-01-P0; punto de control `LAB-SPIKE`; Windows PowerShell 5.1 elevado (el guion usa `System.Data.SqlClient`); FIPS **no** activa; SQL local; red interna sin salida; sin servicio `GPOS.Api`.
- **Pasos:**
  1. **Paso 0 (escalera 1):** con la cuenta administradora, `GPOS.Migracion sistema --login-api "NT SERVICE\GPOS.Api"` desde `C:\GPOS-LAB\paquete\GPOS-Demo\app\migracion` y el esquema de la empresa de demostración (`actualizar`/`crear`; la fase `--fase esquema` es de PR-V, **bloqueado**, DE-01-esquema). Anotar códigos de salida. Verificar: `SELECT name FROM sys.server_principals WHERE name = N'NT SERVICE\GPOS.Api'` y, en `GPOS_SYSDATA`, la pertenencia al rol `gpos_api` (consulta de DE-14, abajo).
  2. `.\Probar-Spike-Amplio.ps1 -Caso DE-01-preparar -Paquete C:\GPOS-LAB\paquete\GPOS-Demo -Instancia '.\SQLEXPRESS'`.
  3. **Lo que el guion no mide** (hacerlo a mano): `Foto 'DE-01'` (ahí `sc qc` debe mostrar `"…\app\api\GPOS.Api.exe" --servicio`: el `ImagePath` se arma con comillas dobles anidadas en PowerShell 5.1 y la PR-V lo marca como punto a confirmar, `revision-seguridad-pr-v…` §7.3), `sc qprivs` solo `SeChangeNotifyPrivilege`, `sc qsidtype`, `sc sdshow`, y `(Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Services\GPOS.Api').GetValueNames()` con `Environment`.
  4. `$desde = Get-Date; .\Probar-Spike-Amplio.ps1 -Caso DE-01-probar`. Si no sale `Running` con `200`, **esperar 60 s y repetir solo `Start-Service`/la sonda** (P-10) antes de concluir.
  5. Registrar: `Eventos $desde`, y los eventos del Administrador de servicios: `Get-WinEvent -FilterHashtable @{LogName='System';ProviderName='Service Control Manager';StartTime=$desde} | Select-Object Id,Message` (7000, 7009, 7011, 7023, 7031, 7034).
  6. **Escalera.** Si el paso 4 falla por permisos de SQL, **anotar el texto exacto del error y la base/operación** y recién entonces subir un escalón, uno por vez, y repetir 4:
     - Escalera 2 (solo en `GPOS_SYSDATA` y las `GPOS_*` del DEMO): `USE [GPOS_SYSDATA]; CREATE USER [NT SERVICE\GPOS.Api] FOR LOGIN [NT SERVICE\GPOS.Api]` (si no existe) `; ALTER ROLE db_owner ADD MEMBER [NT SERVICE\GPOS.Api];`
     - Escalera 3 (solo si el DEMO crea empresas desde la interfaz): `ALTER SERVER ROLE dbcreator ADD MEMBER [NT SERVICE\GPOS.Api];` (**P-06**: DE-14 cambia de criterio).
     - Todo lo demás está prohibido; si solo funciona con algo de la lista: **FALLA**, no continuar.
  7. **DPAPI y perfil (D-4):** `Get-ChildItem "$env:ProgramData\GPOS NG\Api\anillo" -Filter key-*.xml | Select-Object Name,Length,LastWriteTime` y `Select-String -Path "$env:ProgramData\GPOS NG\Api\anillo\key-*.xml" -Pattern 'DPAPI' -List | Select-Object Filename` (solo nombres de archivo; nunca el contenido); `Test-Path 'C:\Windows\ServiceProfiles\GPOS.Api'` (perfil de la cuenta virtual cargado [I]).
  8. **Inicio manual:** reiniciar la VM y comprobar que el servicio **no** arranca solo (`start= demand`).
  9. Tomar `LAB-SPIKE-VERDE` solo si el servicio está `Running` y salud es 200.
- **Evidencia:** `DE-01-preparar.json`, `DE-01-probar.json`, la carpeta `DE-01\` de `Foto`, eventos de Aplicación y de Sistema, la **tabla de la escalera** (qué paso funcionó primero) y el error literal de cada paso que falló.
- **Esperado [I]:** `Running`, `200` en `http://127.0.0.1:5071/api/salud`, sin 4767; el evento crítico **5130** (`IdentidadAmplia`) en cada arranque de Amplio es **esperado** (A, `Comun-Demo.ps1`; `IdentidadSql.cs:29` [V]), no es falla; 4745 «sin modo» como aviso; anillo con llaves cifradas con DPAPI; escalera 1 o 2 bastan.
- **Rechazo / clasificación:**
  - **FALLA del spike (escalar):** solo funciona con un rol de la lista prohibida; no arranca ni con la escalera 3.
  - **FALLA de D-4:** `GPOS.Migracion` (cuenta del administrador) y la API (cuenta virtual) no pueden abrirse el anillo o la fila `Licencia.InstalacionId` (DPAPI de usuario distinto en cada uno; es lo que motivó DM-07). Anotar el mensaje.
  - **No cumple por entorno** (P-01): excepción por falta de `DpapiDemo`/anillo. **No decide D-2**: corregir el entorno (A) y repetir.
  - Un secreto, cadena de conexión o la clave en cualquier salida: **Alto**.
- **Marca:** [I]. **Duración:** 60 a 90 min.

### DE-10. Un usuario estándar no lee el valor `Environment` de `GPOS.Api`

- **Texto de origen** (`plan-demo…:259`, DM-01): «Un usuario estándar intenta leer el valor `Environment` de `GPOS.Api` → Acceso denegado; la SDDL de la clave coincide con `O:SYG:SYD:P(A;CI;KA;;;SY)(A;CI;KA;;;BA)`».
- **Precondiciones:** DE-01 al menos con `DE-01-preparar` hecho (la clave existe con su valor y su DACL).
- **Pasos:**
  1. `.\Probar-Spike-Amplio.ps1 -Caso DE-10` (SDDL de la clave y búsqueda de BU, AU, WD, IU, `S-1-5-32-545`, `S-1-1-0`).
  2. A mano, elevado, solo la DACL: `$k=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Services\GPOS.Api'); $k.GetAccessControl().GetSecurityDescriptorSddlForm('All'); $k.Close()` (no lee valores).
  3. Como `gpos-lab-usuario`: `try { $k=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Services\GPOS.Api'); if($k){'PERMITIDO (abre la clave)'; $k.Close()} else {'clave inexistente'} } catch { 'DENEGADO: ' + $_.Exception.GetType().Name }`. **No** usar `Get-ItemProperty` ni `reg query` (imprimen el valor).
  4. **Control de sensibilidad:** con `LAB-SPIKE` ya tomado, dar lectura a Usuarios en la clave (`icacls` no aplica a registro; usar `Set-Acl` con una ACE `BUILTIN\Users` ReadKey), repetir el paso 1 y comprobar que ahora sale `No cumple`; restaurar el punto de control. Sin este control, un verde de DE-10 no demuestra que la comprobación pueda fallar.
  5. Después de DE-01-probar: el servicio sigue `Running` con la DACL protegida (la propagación `CI` a subclaves no lo rompe; SPV §7.1).
- **Esperado:** SDDL = `O:SYG:SYD:P(A;CI;KA;;;SY)(A;CI;KA;;;BA)` exacta, marca `P`, sin Usuarios ni Todos; el usuario estándar «DENEGADO»; el control de sensibilidad sale «No cumple» cuando se abre a Usuarios.
- **Rechazo:** cualquier ACE de lectura para otro SID; el usuario estándar abre la clave; la DACL protegida impide que el servicio arranque (en ese caso es hallazgo para A: la clave del servicio no puede quedar sin acceso para SYSTEM).
- **Marca:** [I] (DACL por omisión de las claves de servicio con lectura para Usuarios: confirmar con `Get-Acl` **antes** de aplicarla, en una VM recién creada). **Duración:** 10 min.

### DE-11. El usuario que instala inicia y detiene el servicio, pero no lo reconfigura

- **Texto de origen** (`plan-demo…:260`, DM-09): «El usuario que instala inicia y detiene los servicios pero intenta reconfigurarlos (`sc config`) → Inicia y detiene; reconfigurar es denegado». Regla de 2.2.4: al **SID del usuario que instala** (no a `IU`, `AU`, `BU`) solo `RP`, `WP`, `LC`, `LO`, `CC`, `RC`; nunca `DC`, `WD`, `WO`, `SD`.
- **Estado:** el guion de #173 no concede nada (P-05); conceder el permiso es del verbo de PR-V. El veredicto del verbo es DE-11-verbo (**bloqueado por PR-V**). Lo ejecutable hoy son dos pasos:
- **Pasos:**
  1. **Línea base (negativa):** SDDL de fábrica. Como `gpos-lab-usuario` y como el administrador **sin elevar**: `sc.exe start GPOS.Api`, `sc.exe stop GPOS.Api`, `sc.exe config GPOS.Api DisplayName= x` → los tres denegados (error 5). Anotar `sc.exe sdshow GPOS.Api` completo (con la SACL si existe).
  2. **Fixture del técnico** (no sustituye la prueba del verbo): `$sid = (New-Object System.Security.Principal.NTAccount("$env:COMPUTERNAME\gpos-lab-usuario")).Translate([System.Security.Principal.SecurityIdentifier]).Value` y, elevado, `sc.exe sdset GPOS.Api "D:(A;;CCLCSWRPWPDTLOCRSDRCWDWO;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCRPWPLORC;;;$sid)"`. Como `gpos-lab-usuario`: `sc.exe stop GPOS.Api` (permitido), `sc.exe start GPOS.Api` (permitido), `sc.exe query GPOS.Api` (permitido), `sc.exe config GPOS.Api DisplayName= x` (**denegado**), `sc.exe config GPOS.Api binPath= C:\Windows\System32\cmd.exe` (**denegado**; es la razón de DM-09: con `DC` se cambiaría el binario), `sc.exe sdset GPOS.Api "D:(A;;GA;;;WD)"` (**denegado**).
  3. `.\Probar-Spike-Amplio.ps1 -Caso DE-11 -UsuarioInstala gpos-lab-usuario` (hoy el parámetro no se usa; solo comprueba que no hay `DC/WD/WO/SD` en ACE ajenas a SY/BA).
  4. Hexadecimal: si `sdshow` trae máscaras en hexadecimal, el técnico las traduce a mano (el guion lo reconoce, `Probar-Spike-Amplio.ps1:153`).
- **Esperado:** (1) todo denegado; (2) iniciar, detener y consultar permitidos; los tres cambios denegados. **Rechazo:** el usuario puede `config`, `sdset` o `delete`; el usuario estándar sin ACE puede iniciar con el SDDL de fábrica.
- **Marca:** [I]. **Duración:** 20 min.

### DE-12. Un usuario estándar no lista ni lee `Reportes\render`, `Api\anillo` ni `config`

- **Texto de origen** (`plan-demo…:261`, DM-10 y DM-11): «Un usuario estándar intenta listar o leer `Reportes\render`, `Api\anillo` y `config` → Denegado en los tres». Matiz de A (`pr-d1-y-spike-amplio-abiertos.md:21`): `config` hereda la raíz de ADR-77 (lectura para Usuarios autenticados, vector v3) y el «denegado» del plan lo contradice; **lo decide B**.
- **Pasos:**
  1. `.\Probar-Spike-Amplio.ps1 -Caso DE-12`. Mirar `existe` de cada carpeta: si `existe=false`, el caso es **`No se pudo`** para esa carpeta, no `Cumple` (P-05).
  2. Como `gpos-lab-usuario`: `foreach($r in "$env:ProgramData\GPOS NG\Reportes\render","$env:ProgramData\GPOS NG\Api\anillo","$env:ProgramData\GPOS NG\config"){ try { $null = Get-ChildItem -LiteralPath $r -Force -ErrorAction Stop; "$r : PERMITIDO" } catch [System.UnauthorizedAccessException] { "$r : DENEGADO" } catch { "$r : $($_.Exception.GetType().Name)" } }`.
  3. Y lectura de un archivo dentro de cada una si la carpeta tiene contenido (`Get-Content -TotalCount 0`; solo «denegado/permitido»).
  4. **Control de sensibilidad:** `icacls "$env:ProgramData\GPOS NG\Api\anillo" /grant "*S-1-5-32-545:(OI)(CI)R"`, repetir el paso 1 → debe salir `No cumple`; deshacer con `icacls … /remove "*S-1-5-32-545"` o restaurar.
  5. Recoger `Get-Acl` de las tres con `Sddl`.
- **Esperado:** `anillo` y (cuando exista) `render`: denegado, sin ACE para Usuarios/Autenticados; `config`: **permitido** (vector v3) hasta que B decida otra cosa; el anillo con dueño SYSTEM y escritura solo de SY, BA y la identidad del proceso.
- **Rechazo:** `anillo` o `render` accesibles; el control de sensibilidad no lo detecta.
- **Bloqueado en parte:** `render` por la API de reportes (DE-12-render); `anillo` por P-02.
- **Duración:** 15 min.

### DE-13. El Chromium hijo de la principal no hereda `Jwt__Clave`

- **Texto de origen** (`plan-demo…:262`, DM-04): «El proceso Chromium hijo de la principal: ¿tiene `Jwt__Clave` en su entorno? (anotar solo presente/ausente) → Ausente». Hoy la retirada existe: `ModoServicioApi.RetirarClaveJwtDelEntorno` y `ProtegerClaveJwt` (#174, unido el 2026-10-23) con las **dos grafías** `Jwt__Clave` y `Jwt:Clave` (JWT-01) [V].
- **Precondiciones:** DE-01 en verde; Edge presente; el DEMO con una factura o un formato que se pueda imprimir a PDF desde la API principal (`ConvertidorPdf`, PuppeteerSharp); Process Explorer (o System Informer) abierto **como administrador**.
- **Pasos:**
  1. **Control de validez de la técnica** (sin la clave): en una consola elevada `$env:GPOS_LAB_CENTINELA='presente'; Start-Process 'C:\Windows\System32\notepad.exe'` (o `msedge.exe --headless=new about:blank`); en Process Explorer, doble clic en ese proceso → pestaña *Environment*: debe verse `GPOS_LAB_CENTINELA`. Si no se ve, la técnica no sirve y el caso es `No se pudo`.
  2. **Proceso de la API:** en Process Explorer, proceso `GPOS.Api.exe` → *Environment*. Anotar **solo** si `Jwt__Clave` o `Jwt:Clave` están presentes o ausentes. **Sin capturas de pantalla** de esa pestaña.
  3. **Generar el PDF** desde la interfaz (o llamando al extremo que lo produce) para que la API lance `msedge.exe`/`chrome.exe`; localizar el hijo (`Get-CimInstance Win32_Process | Where-Object { $_.Name -match 'msedge|chrome' -and $_.ParentProcessId -eq (Get-Process GPOS.Api).Id } | Select-Object ProcessId,Name`), abrirlo en Process Explorer y repetir la anotación de presente/ausente. Mientras el PDF se genera, el hijo vive unos segundos: abrir el proceso rápido o dejarlo en una página que tarde.
  4. `.\Probar-Spike-Amplio.ps1 -Caso DE-13` (cuenta hijos; **siempre escribe `Cumple`**, no decide).
  5. Anotar dónde cayó `TEMP` del servicio (`C:\Windows\ServiceProfiles\GPOS.Api\AppData\Local\Temp`, [I]) y si el perfil del navegador se creó allí: `Get-ChildItem 'C:\Windows\ServiceProfiles\GPOS.Api\AppData\Local\Temp' -Filter 'gpos-pdf-navegador*'`.
- **Esperado:** ausente en el proceso de la API y en el hijo; control con el centinela presente. **Rechazo:** presente en cualquiera de los dos (**Alto**: la clave llega a un proceso con contenido controlado por el usuario).
- **`No se pudo` si:** el PDF no se genera (sandbox de Chromium bajo la cuenta virtual, `TEMP` no escribible, Edge ausente: CH-02 y CH-04 de mi entrega del 22-oct); en ese caso anotar el error y el evento. No es un verde.
- **Variante:** repetir con el servicio configurado con `Jwt:Clave` (dos puntos) en lugar de `Jwt__Clave` (cadena centinela, DE-01-N4b) y comprobar que el hijo tampoco la tiene.
- **Marca:** [I]. **Duración:** 40 min.

### DE-14. `TRUSTWORTHY OFF` y sin roles de servidor

- **Texto de origen** (`plan-demo…:263`, DM-03): «`is_trustworthy_on` en `GPOS_SYSDATA` y las `GPOS_*`; roles de servidor del login `NT SERVICE\GPOS.Api` → `is_trustworthy_on = 0`; roles de servidor vacíos».
- **Pasos:**
  1. `.\Probar-Spike-Amplio.ps1 -Caso DE-14`.
  2. Con `sqlcmd -S .\SQLEXPRESS -E -Q "<consulta>"` (o `Invoke-Sqlcmd` si está) como administrador, solo lectura:
     - `SELECT name, is_trustworthy_on, SUSER_SNAME(owner_sid) AS dueno FROM sys.databases WHERE name LIKE 'GPOS[_]%'` (el dueño debe ser `sa` en las bases de empresa; S1/D-03).
     - Roles de servidor: `SELECT r.name FROM sys.server_role_members m JOIN sys.server_principals r ON r.principal_id = m.role_principal_id JOIN sys.server_principals p ON p.principal_id = m.member_principal_id WHERE p.name = N'NT SERVICE\GPOS.Api'`.
     - Permisos de servidor: `SELECT sp.permission_name, sp.state_desc FROM sys.server_permissions sp JOIN sys.server_principals p ON p.principal_id = sp.grantee_principal_id WHERE p.name = N'NT SERVICE\GPOS.Api'` (esperado: solo `CONNECT SQL`).
     - Roles de base, en cada `GPOS_*`: `USE [GPOS_SYSDATA]; SELECT r.name FROM sys.database_role_members m JOIN sys.database_principals r ON r.principal_id = m.role_principal_id JOIN sys.database_principals u ON u.principal_id = m.member_principal_id WHERE u.name = N'NT SERVICE\GPOS.Api'` (esperado según la escalera: `gpos_api` o `db_owner`).
     - Efectivo a través de grupos (SPV-07): `EXECUTE AS LOGIN = N'NT SERVICE\GPOS.Api'; SELECT IS_SRVROLEMEMBER('sysadmin') AS sysadmin, HAS_PERMS_BY_NAME(NULL, NULL, 'CONTROL SERVER') AS controlServer; REVERT;` (esperado `0` y `0`).
  3. **Control de sensibilidad:** `ALTER DATABASE [GPOS_SYSDATA] SET TRUSTWORTHY ON;` → repetir el paso 1 → `No cumple`; volver a `OFF`. Un segundo control con otra cuenta, **no** la virtual: `CREATE LOGIN [<EQUIPO>\gpos-lab-usuario] FROM WINDOWS; ALTER SERVER ROLE dbcreator ADD MEMBER [<EQUIPO>\gpos-lab-usuario];` y la consulta de roles con ese nombre debe devolver `dbcreator`; luego `DROP LOGIN`. Prueba que la consulta ve los roles.
- **Esperado:** `is_trustworthy_on = 0` en todas; roles de servidor de la cuenta vacíos (**o solo `dbcreator` si la escalera llegó al paso 3**, P-06); `sysadmin = 0`.
- **Rechazo:** `TRUSTWORTHY ON`; cualquier rol de servidor distinto de `dbcreator` (y `dbcreator` sin que la escalera lo justifique); `IS_SRVROLEMEMBER('sysadmin') = 1`.
- **Dependencia:** `comprobar-servidor` de PR-V repetirá esta comprobación (DE-14-verbo, **bloqueado**). **Duración:** 20 min.

### DE-15. 5071 y 5073 solo escuchan en loopback

- **Texto de origen** (`plan-demo…:264`, DM-12): «Sockets de 5071 y 5073 → Solo `127.0.0.1`/`::1`».
- **Pasos:** con el servicio `Running`: `Get-NetTCPConnection -State Listen -LocalPort 5071,5073 | Select-Object LocalAddress,LocalPort,OwningProcess | Tee-Object "$E\DE-15-oyentes.txt"`; `(Get-CimInstance Win32_Service -Filter "Name='GPOS.Api'").ProcessId` (el PID debe ser el que escucha: SPV-06); `netstat -ano | findstr ":5071"`; `.\Probar-Spike-Amplio.ps1 -Caso DE-15`; desde **otro equipo** de la red interna (la VM de puesto, si existe) o desde la propia VM con la IP de la interfaz interna: `Test-NetConnection <IP-de-la-VM> -Port 5071` → debe fallar.
- **Esperado:** direcciones `127.0.0.1` y `::1` (`ListenLocalhost` en `EscuchaServidor.cs`, `PuertoApiSinModo = 5071` [V]); PID = el del servicio; sin escucha en la IP interna. 5073: `No se pudo` (API de reportes no instalada, DE-15-5073).
- **Negativo opcional (variante «fuente de direcciones»):** con el servicio detenido, en una consola elevada con otra base descartable, `$env:ASPNETCORE_URLS='http://0.0.0.0:5071'` y arrancar la API en consola: sin modo y con una fuente declarada, manda la fuente «contenida por el 4746» [V: comentario de `EscuchaServidor.Preparar`]; esperado: 4746 y la aplicación se detiene. Es una prueba de la contención, no del servicio; si la clave y la cadena no se pueden dar sin tocar el servicio, anotar `No se pudo`.
- **Rechazo:** cualquier `0.0.0.0` o `::` en 5071; otro PID escuchando en 5071 con el servicio caído (riesgo S-01/S-02: un proceso local recibiría credenciales de la Web) sin que nada lo detecte.
- **Duración:** 15 min.

### DE-16. Tras retirar el servicio no quedan clave ni valor `Environment`

- **Texto de origen** (`plan-demo…:265`, DM-06): «Tras `Desinstalar-Demo` → Sin clave de servicio ni valor `Environment` (si 1072, aviso de reinicio)».
- **Pasos:** con el servicio `Running` o `Stopped`: `.\Probar-Spike-Amplio.ps1 -Caso DE-16-retirar` (o `Desinstalar-Demo.ps1` cuando exista PR-D2); luego `Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Services\GPOS.Api'`; `sc.exe query GPOS.Api` (1060); si `Test-Path` da `True`, `Restart-Computer` y repetir; `Get-ChildItem C:\GPOS-LAB\evidencia -Recurse | Select-String -Pattern 'Jwt__Clave=' -List | Select-Object Path` (la clave **no** debe aparecer en ningún archivo de evidencia); `Select-String -Path "$env:ProgramData\GPOS NG\Api\registros\*" -Pattern 'Jwt' -List` si existe la carpeta.
- **Esperado:** `claveDelServicioExiste=False` (o `True` con 1072 y `False` tras reiniciar); el login `NT SERVICE\GPOS.Api` de SQL y las bases **se conservan** (el retiro no toca datos); el anillo se conserva; ningún archivo de evidencia contiene la clave.
- **Rechazo:** la clave del servicio persiste tras reiniciar; la clave aparece en cualquier archivo; el retiro borra datos de la empresa.
- **Reinstalación (rotación, DM-06):** `DE-01-preparar` otra vez genera una clave distinta. Que un token emitido antes sea rechazado después queda **bloqueado** por no tener sonda funcional (P-10).
- **Duración:** 15 min.

### Negativos del spike (todos desde `LAB-SPIKE-VERDE`)

Para variar el entorno sin leer la clave: `function Poner-Entorno([string[]]$l){ $k=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Services\GPOS.Api',$true); try{$k.SetValue('Environment',$l,[Microsoft.Win32.RegistryValueKind]::MultiString)}finally{$k.Dispose()} }` y se escribe el entorno **completo** (las líneas de P-01, el modo y la cadena de conexión que el técnico ya conoce) con la cadena centinela donde corresponda. Entre un negativo y el siguiente: restaurar `LAB-SPIKE-VERDE`.

| ID | Caso | Cómo | Esperado | Rechazo |
|---|---|---|---|---|
| **DE-01-N1** | **Sin SQL** | `Stop-Service 'MSSQL$SQLEXPRESS' -Force`; `$desde=Get-Date; Start-Service GPOS.Api`; esperar 3 min; `sc.exe query GPOS.Api; Eventos $desde`; arrancar SQL; esperar la recuperación (60 s) y repetir | No arranca o cae con un mensaje que nombra la falla de conexión, **sin cadena de conexión ni credenciales**; sin escucha en 5071 mientras no haya base; con SQL de vuelta y reintentos de 60 s (máx. 3) llega a `Running` o queda detenido de forma limpia [I: `Inicializacion.cs` no leído]. Anotar cuál | Cuelga el Administrador de servicios; imprime la cadena de conexión; escucha antes de tener base |
| **DE-01-N2** | **Puerto 5071 ocupado** | Servicio detenido; `$l=[System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback,5071); $l.Start()` en una consola elevada; `Start-Service GPOS.Api`; `Eventos $desde`; luego `$l.Stop()` | El servicio **no** queda `Running` sirviendo en otro puerto; error de enlace (puerto en uso) claro; sin 4768; al liberar el puerto y arrancar, funciona. En `comprobar-servidor` (PR-V) R4 debe comparar el PID que escucha con el del servicio (**bloqueado**, DE-15) | `Running` con el puerto ajeno; escucha en otro puerto o dirección; la Web podría hablar con quien ocupó el puerto |
| **DE-01-N3** | **Clave JWT ausente** | `Poner-Entorno` con el modo `Amplio` y la cadena de conexión, **sin** `Jwt__Clave` | No arranca: «Configure Jwt:Clave con al menos 32 caracteres» (`Program.cs`, excepción sin el valor); `STOPPED`; sin escucha; sin 4767 (no es identidad ni cerrojo) | Arranca con una clave vacía o por omisión; el evento incluye valores |
| **DE-01-N4a** | **Clave en modo no Amplio** (cerrojo 2) | `Poner-Entorno` con `Jwt__Clave=CLAVE-DE-LABORATORIO-NO-SECRETA-0000000000000000` y **sin** `GPOS__Seguridad__ModoIdentidad` (luego con `Estricto`, luego con `Ampl`, luego con `AmplioX`) | 4767 `ARRANQUE_JWT_ENTORNO: Jwt__Clave está en el entorno del servicio y el modo de identidad no es Amplio…`, salida 1, **sin el valor ni su prefijo** en el evento ni en `Console.Error` | Arranca; el evento nombra el valor |
| **DE-01-N4b** | **Misma clave con dos puntos** (JWT-01) | `Poner-Entorno` con `Jwt:Clave=<centinela>` y modo ausente; luego con modo `Amplio` | Sin modo Amplio: 4767 igual que N4a. Con `Amplio`: arranca y, como DE-13, la variable `Jwt:Clave` no está en el entorno del proceso ni del hijo | La grafía de dos puntos evade el cerrojo |
| **DE-01-N4c** | **Clave en el archivo de instalación** | Crear `%ProgramData%\GPOS NG\config\GPOS.Api.json` con `{"Jwt":{"Clave":"<centinela>"}}` (como administrador; la carpeta es de administradores) y quitar la clave del entorno | La clave del archivo se **ignora** y se deja una advertencia que nombra la clave, no su valor (`ArchivoInstalacion.AdvertirIgnoradas` [V]); luego falla como N3 | La API acepta `Jwt:Clave` desde el archivo; la advertencia trae el valor |
| **DE-01-N4d** | **Clave corta** | `Poner-Entorno` con `Jwt__Clave=corta` (modo Amplio) | Excepción de longitud mínima 32; sin el valor | Arranca |
| **DE-01-N5** | **Cuenta distinta** | `sc.exe config GPOS.Api obj= LocalSystem` (y `LocalService`, `NetworkService`) con la clave y el entorno completos; `Start-Service GPOS.Api`; `Eventos $desde`; restaurar con `sc.exe config GPOS.Api obj= "NT SERVICE\GPOS.Api"` | 4767 `ARRANQUE_IDENTIDAD`, salida 1, sin escucha; **la clave nunca llega a correr bajo SYSTEM** (la comprobación de identidad va antes de leer la configuración, `Program.cs:30` [V]) | La API arranca bajo la cuenta ajena con la clave en el entorno |
| **DE-01-N6** | **Carpeta del anillo ajena** (ADR-77) | Con el servicio detenido, reemplazar `Api\anillo` por una carpeta creada por `gpos-lab-usuario` (dueño ajeno) o con ACE de Usuarios Modificar | [?] el comportamiento no está especificado para Amplio con DPAPI: anotar si la API rechaza (lo previsto por H-17 v2/N-14 en Estricto) o arranca. Si arranca, **hallazgo para A** (un usuario estándar podría plantar llaves) | Arranca con llaves escritas por un usuario estándar sin ningún aviso |

Evidencia de cada negativo: `Eventos`, `sc query`, `Get-NetTCPConnection`, y la nota de qué se cambió. Sin el valor del entorno.

## 8. Plantilla de evidencia y criterio de recomendación

Una carpeta por sesión con los `.json` de los guiones, los `.log` de MSI, las carpetas `Foto`, las ACL, los eventos y la tabla siguiente (misma cabecera que el procedimiento de A, para que A y C compartan formato):

| Campo | Valor |
|---|---|
| VM y fecha | |
| Punto de control de partida | |
| SHA-256 de cada MSI, paquete y script | |
| Versión de Windows; FIPS sí/no; edición de SQL | |
| Caso → resultado (`Cumple` / `No cumple` / `No se pudo` / `Bloqueado`) | |
| Hallazgos (severidad, pasos, esperado, obtenido) | |
| Técnico | |

**Severidades de laboratorio.** *Crítica*: un secreto legible por un usuario estándar o impreso en evidencia; el servicio corre con una cuenta o privilegio no previsto; solo funciona con `sysadmin`. *Alta*: un rechazo modifica la carpeta plantada; el MSI deja `Environment` o apropiación de un servicio ajeno (MI-N3); la clave llega al proceso hijo (DE-13); `TRUSTWORTHY ON`; SID del MSI ≠ SID del código (MI-06). *Media*: lo que no se autorrepara (MI-07); `INSTALLFOLDER` aceptado (MI-N5); un caso `No se pudo` por entorno incompleto. *Baja*: textos, tiempos, avisos.

**Recomendación técnica (la decisión es de B y del propietario):** *Rechazado* si queda algún hallazgo Crítico o Alto; *Aprobado con observaciones* si solo hay Media o Baja o casos `Bloqueado`; *Aprobado* solo con todos los casos ejecutables en `Cumple`. Un `No se pudo` o `Bloqueado` **nunca** cuenta como `Cumple`.

## 9. Preguntas y entregas

- **A (arquitecto-software/devops):** (1) P-01 y P-02: ¿el spike usa `implantar-servidor` de PR-V o completa el guion de #173? (2) P-06: criterio de DE-14 si la escalera llega a `dbcreator`. (3) P-07: actualizar G-PR4, §8 de operaciones, §7 de la guía y el texto de DE-13 tras PR-4 y #174. (4) P-08: parametrizar `Probar-Instalador.ps1` para otra *feature* y comparar solo la DACL del servicio. (5) P-09: `FailureActionsWhen`.
- **B:** (1) ¿Confirma que **escribo `Preparar-Vm.ps1`** (marcador `LaboratorioTls`, variables `GPOS_LAB_TLS_VM` y `GPOS_LAB_TLS_ID`) antes del 18-nov? Sin él los dos guiones se niegan a correr. (2) ¿La imagen de `VM-SRV` trae Edge y Process Explorer? (3) DE-12: ¿`config` cerrado o vector v3? (4) ¿Tres sesiones (S1, S2, S3) en lugar de dos? (5) ¿Quién opera cada una?
- **Para el T1-b (B):** entregar junto al MSI `publicacion.sha256` (MI-02), el segundo MSI de versión mayor (MI-08) y declarar cómo trata `INSTALLFOLDER` (MI-N5).

## 10. Qué no verifiqué

- **Nada se ejecutó:** ni MSI, ni servicio, ni `sc`, ni los guiones de A, ni SQL, ni VirtualBox. Todo valor marcado [I] (códigos de salida de `msiexec` como 1925 y 1638, valores de `sc qsidtype`/`qfailureflag`, el SID de la cuenta virtual `S-1-5-80-546908902-…`, el comportamiento de `ServiceInstall` ante un servicio preexistente, la restauración de `PermissionEx` en reparación, rutas del perfil de la cuenta virtual, `CreateEventSource` con `EventLogMessages.dll`) es conocimiento general o cálculo de A, **no comprobado aquí ni contra documentación del fabricante**.
- **No existe el MSI de la API** ni `instalador/Api/` en `feature/modelo-ng` (verifiqué con `git ls-tree` sobre `origin/feature/modelo-ng` @ `67b4353a`): los casos MI se escribieron contra la guía y el contrato de A, no contra un `Package.wxs`. Si B se aparta de la guía, los valores esperados cambian.
- **No leí `Inicializacion.cs`, `CarpetaAnillo.cs` ni `AlmacenLicenciaDisco.cs`** de la API: lo que digo de qué falla primero sin configuración (MI-06), de las carpetas que la API crea (P-02) y de qué hace con SQL caído (DE-01-N1) es inferencia del orden de `Program.cs` y de los comentarios de A.
- **No ejecuté `GPOS.Migracion`** ni leí PR-V línea por línea: de PR-V uso lo que dicen sus avisos y el §7 de la revisión de seguridad (`a/pr-v-verbos-servidor` @ `b43951af`, 805/805 con filtro, sin PR). No sé si cubre la preparación de carpetas que el spike necesita.
- **No leí `Preparar-Vm.ps1`** porque no existe; deduje su contrato de las guardas de `Probar-Instalador.ps1:49-61` y `Probar-Spike-Amplio.ps1:49-60`.
- **No leí el código de `GPOS.Instalador.Acciones`** ni los vectores `adr077-carpetas.v3.json`: los códigos de rechazo (`DUENO_NO_PERMITIDO`, `ESCRITOR_NO_PERMITIDO`, `PUNTO_DE_REANALISIS`, `NO_ES_CARPETA`, `25101`) los tomo del procedimiento de A (#165). Que `config\` y `Api\` tengan fila propia en `GposCarpetaPrevia` y admitan el SID del propio servicio es lectura de la guía y de `RaizGposNg.wxs`; los sub-casos MI-11e y MI-11g son [I].
- **No verifiqué** que el paquete DEMO publicado desde `67b4353a` arranque, ni que Edge esté en la imagen de Windows Server 2025, ni que Process Explorer pueda correr dentro de la VM sin Internet.
- **No revisé los pull requests por dentro más allá de los archivos que cito:** #173 y #165 están sin revisar según A; mis observaciones P-01 a P-11 son lectura de QA, no una revisión de seguridad (eso es del auditor de A).
- **Duraciones y reparto en sesiones:** mis estimaciones, sin experiencia de ejecución previa en esta VM (ninguna se ha ejecutado en `LFMB`).
- **Las fechas 18-nov y 23-nov** son propuesta de B, aún sin confirmar por el propietario (`propuesta-fechas-vm.md:9`).

### Cierre
- Estado: Completado (casos y plan; ninguno ejecutado)
- Artefactos: `C:\Users\lfmen\AppData\Local\Temp\claude\C--Users-lfmen-source-repos-Solucion-GPOS-NG-GPOS-NG\a3bc09e2-6f31-41d0-8b7c-bb380a2e9bc6\scratchpad\casos-laboratorio-t1b-amplio.md`
- Supuestos: los de la sección 10; el MSI de la API sigue la guía de A sin desvíos; las fechas del 18 y 23-nov se mantienen.
- Decisiones candidatas a ADR: Ninguna.
- Entregas a otros agentes: A → P-01, P-02, P-06 a P-09 (sección 9); B → confirmar `Preparar-Vm.ps1`, imagen con Edge y Process Explorer, decisión de DE-12 y las tres sesiones; C (yo) → escribir `Preparar-Vm.ps1` y una lista de revisión de la evidencia antes del 18-nov.
- Próximo paso recomendado: que A corrija P-01 y P-02 del spike y B confirme las sesiones de VM; yo escribo `Preparar-Vm.ps1` en cuanto B lo confirme.
