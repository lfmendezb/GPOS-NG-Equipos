```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (tarea 2 de B-a-C/2026-10-23-tareas-nuevas-para-c-5: casos de laboratorio de PR-D2 para la VM del 16 al 27-nov)
Prioridad: Media
Repositorio y rama: GPOS-NG `origin/a/pr-d2-manifiesto` @ `cd44043c` (solo lectura, `git show`); `origin/b/blueprint-tls-anillo` (anillo F1); área común `traspasos/A/` y `avisos/`
Estado: Abierto (casos redactados; nada ejecutado)
```

# Casos de laboratorio de PR-D2: fase `restaurar`, `Revertir-Actualizacion.ps1` con servicios, paso de empresa y cuentas iniciales

**Qué es.** Casos para `VM-SRV` de `LFMB` (VirtualBox; con `Preparar-Vm.ps1` aplicado y el punto de control `base`; los opera B). Cubren lo que las pruebas con el doble de `ISistemaServidor` no pueden mostrar (ACL reales, puntos de reanálisis, vínculos físicos, archivos bloqueados, procesos, servicios, Visor de eventos, corte de energía) y lo que A declaró sin ejecutar ("Nada se ejecutó contra servicios reales; lo real se ensaya en la VM", aviso de A del 2026-10-23). **No se instaló ni se ejecutó nada** (OSHIN-LEGION no tiene VirtualBox y la regla del 2026-10-08 impide tocar servicios en las PC del propietario; tampoco compilé).

**Marcas.** [V] verificado leyendo un archivo en `cd44043c` (ruta y línea); [I] inferido o conocimiento general de Windows/SQL Server, por confirmar en la VM; [?] depende de algo que aún no existe (anillo F1, paso de empresa y cuentas de A).

**Estados de un caso en la VM.** `Cumple` · `No cumple` · `No se pudo` (la precondición no existía) · `Bloqueado` (no ejecutable hoy). `No se pudo` y `Bloqueado` **nunca** cuentan como `Cumple`. Regla heredada de T4-03: **un caso sin su control negativo no puede dar `Cumple`** (el control es la misma medición con el mecanismo apagado o con el defecto presente; demuestra que el instrumento ve la diferencia).

## 0. Resumen para decidir

1. **Cuatro bloques, 31 casos** (más subcasos): `LAB-RS-01` a `-11` (fase `restaurar` llamada directamente), `LAB-RV-01` a `-07` (`Revertir-Actualizacion.ps1` con servicios), `LAB-EM-01` a `-07` (empresa creada por la interfaz como GSF con `dbcreator`) y `LAB-CU-01` a `-06` (cuentas iniciales con el anillo del servicio).
2. **Dos niveles de montaje, porque el instalador de servicios no está terminado.** `Instalar-Demo.ps1` en modo de servicios hoy **termina con un error a propósito** ("BORRADOR de PR-D2: faltan la base de la empresa y las cuentas iniciales…", `Instalar-Demo.ps1:167`) **antes** de escribir `instalacion.json`; sin ese archivo `Actualizar-Demo.ps1` y `Revertir-Actualizacion.ps1` no corren. Por eso: **Nivel V** (bloque RS): `implantar-servidor --fase carpetas` y `--fase servicios` a mano con dos paquetes; no necesita SQL, anillo ni instalador. **Nivel G** (bloque RV): instalador completo; depende de F1 (anillo, unión antes del 5-nov) y del paso de A del 5 al 9-nov. **Nivel A** (bloques EM y CU): además, el anillo funcionando y los servicios en `Running`.
3. **Hallazgo previo a la VM (P-D2-01, Media, [V] por lectura):** el ciclo **actualizar → revertir → actualizar → revertir** deja la segunda actualización **sin `HuellaCopiaPrevia`** (la copia previa nueva es byte a byte la de antes, su huella no cambia, y `Actualizar-Demo.ps1` lo interpreta como "no cambió los binarios"). Esa reversión restaura las bases pero **no** los binarios: base en la versión anterior con programas nuevos. Es exactamente lo que hará el ensayo de la VM. Detalle y caso: sección 3 y `LAB-RV-06`. Lo conviene mirar A antes del 16-nov.
4. **Otras dos observaciones [V]:** `Revertir-Actualizacion.ps1` **no** llama a `comprobar-servidor` (el blueprint de A, §5, lo pide; R-09 de la revisión de seguridad sigue abierto en `cd44043c`) y **nada impide `Start-Service` con la marca `.aplicando` presente** (R-04 (a) sigue abierto). Los casos `LAB-RS-06` y `LAB-RV-05` registran el estado real, no lo suponen cerrado.
5. **Duración [I, ±50 %]:** S6 (Nivel V, `VM-SRV` sola) ≈ 6 h; S7 (Nivel G) ≈ 5 h; S8 (Nivel A: empresa y cuentas) ≈ 6 h. Total ≈ 17 h de operación en tres ventanas del 16 al 27-nov.
6. **Si solo cabe una ventana:** `LAB-RS-01`, `-03`, `-05`, `-06`, `LAB-RV-01`, `-04`, `-06`, `LAB-CU-01`, `-02`, `LAB-EM-01`, `-07`, el resto.

## 1. Fuentes y estado del código [V]

- Aviso de B `avisos/B-a-C/2026-10-23-tareas-nuevas-para-c-5.md` (tarea 2) y los avisos de A→B del 2026-10-23: `acuse-decisiones-y-fase-restaurar-construida`, `pr-d2-actualizar-y-revertir`, `pr-d2-rebase-esquema-lectura`, `pr-d2-empresa-y-cuentas-bloqueo`; de B→A: `decisiones-pr-d2-t4-06-173-y-emisor` y `anillo-f1-firmado-y-en-construccion`.
- Blueprint `traspasos/A/blueprint-pr-d2-fase-restaurar-2026-10-23.md` y revisión de seguridad `traspasos/A/revision-seguridad-fase-restaurar-2026-10-23.md` (R-01 a R-09; hecho en `cd44043c`: R-01 y R-03 en parte y R-05 por el guion; **sin hacer** R-02, R-04, R-06, R-07, R-08, R-09).
- Plan del DEMO `traspasos/A/plan-demo-con-api-de-reportes-2026-10-22.md` (§2.2.2 escalera de privilegios SQL; DE-10 a DE-16) y blueprint de `tls` y anillo (`origin/b/blueprint-tls-anillo`, `docs/arquitectura/2026-10-23-blueprint-tls-y-anillo-del-servicio.md`: §3.3 guardas G-1 y G-2, evento 4729, archivo `GPOS.Api.anillo.json`).
- Mis documentos previos para el mismo laboratorio: `2026-10-23-casos-laboratorio-l1-l4-t4-03.md` (reglas, sesiones, controles), `2026-10-23-casos-laboratorio-t1b-y-revision-173.md` (funciones de apoyo, severidades) y `tests/laboratorio-adr090/revision-evidencia.md` (`git show origin/feature/modelo-ng:tests/laboratorio-adr090/revision-evidencia.md`; secciones A a E se aplican sin cambios).
- Código en `origin/a/pr-d2-manifiesto` @ `cd44043c`:
  - `src/GPOS.Migracion/Servidor/FasesImplantacion/FaseRestaurar.cs` completo: `:27-31` (perfil demo y carpetas de datos), `:34-42` (destino y antepasados existentes y seguros), `:45-47` (`EjecutableEnMarcha`), `:50-52` (R-03: carpeta de servicio que es punto de reanálisis), `:55-76` (copia previa: existe, segura, con manifiesto, huella atada, `# estado=verificada`, huellas), `:80-88` ("ya son los de la copia previa"), `:91-93` (retoma o crea `.aplicando`), `:99-107` (copia con `CopiarSinReanalisis`), `:109-120` (borra sobrantes), `:121-123` (fallo: marca queda, código 4), `:126-131` (verificación final, borra marca, escribe `manifiesto.instalado.sha256`), `:136-139` (sobrantes solo bajo `api\` y `reportes\`).
  - `src/GPOS.Migracion/Servidor/FasesImplantacion/FaseServicios.cs`, `CopiarBinarios`: camino "al día" (no toca `.anterior`), copia previa con `manifiesto.sha256` y `# estado=verificada|no-verificada`, `DestinoIntegro` contra `manifiesto.instalado.sha256`.
  - `SistemaServidorWindows.cs:192-246` (`CopiarSinReanalisis`: abre el origen con `FILE_FLAG_OPEN_REPARSE_POINT`, rechaza reanálisis, carpeta, vínculos físicos y ruta final distinta; **el destino se abre con `FileMode.Create`**, `:223`), `:170-173` (`ListarArchivos`), `:177` (`EscribirTexto`, UTF-8 sin BOM), `:498-513` (`EjecutableEnMarcha`: compara `MainModule.FileName` con la ruta; si no puede leer el módulo, cuenta como en marcha).
  - `ComandoImplantarServidor.cs:16-60` (códigos: `Hecho`=0, `Detenido`=4; evento 5135 `FaseCompletada` con `resultado=` y `cambios=`; el evento de guarda en "Detenido"; todo en el origen `GPOS.Instalacion`).
  - `instalador/Demo/scripts/Revertir-Actualizacion.ps1`: `:41-42` (elevación), `:63-65` (solo la última marca), `:70` (ya revertida), `:71-89` (huella de `.anterior` y `# estado=verificada` **antes** de tocar nada), `:96-97` (confirmación `RESTAURAR`), `:100` (`Detener-Demo`), `:102-118` (RESTORE de las bases), `:120-130` (fase `restaurar` con `--huella-copia-previa`; si el código ≠ 0, `Detener-ConError` y no sigue), `:131-139` (demás programas con `robocopy /MIR`), `:141-149` (estado, `revertida`, `instalacion.json`), `:151-165` (mensajes DM-01). **No hay llamada a `comprobar-servidor`.**
  - `instalador/Demo/scripts/Actualizar-Demo.ps1` (≈ `:147-165`): anota `HuellaCopiaPrevia` solo si el hash de `.anterior\manifiesto.sha256` **cambió** entre antes y después de `--fase servicios`.
  - `instalador/Demo/scripts/Instalar-Demo.ps1:126-167` (modo servicios: carpetas, servicios, esquema, lectura y el error de BORRADOR) y `:195-245` (modo consola: cuentas iniciales con `sistema --cuentas-iniciales --confirmar-sellado --motivo` y registro de la empresa por `GPOS__EmpresaInicial__*` en el primer arranque, **que el modo de servicios no usa**).
  - `src/GPOS.Core/Infraestructura/EsquemaEmpresa.cs:216` (`CREATE DATABASE` si no existe), `Motor/PrivilegioMinimoSistema.cs:109,151` (`ALTER AUTHORIZATION … TO sa`; excepción 51606 "RG-14: el inicio de sesión de la API ya es dueño de la base").
  - `tests/GPOS.Tests/Servidor/RestaurarServidorTests.cs`: 20 pruebas con el doble (nombres en la sección 2.2).

### Qué ya cubre el doble y qué solo la VM

| Aspecto | Lo cubre el doble | Solo la VM lo muestra |
|---|---|---|
| Lógica de restauración, orden de guardas, huellas, marca, reanudación | `RestaurarServidorTests` (20) | — |
| ACL, dueño y reanálisis **reales** de `.anterior` y de las carpetas del destino | Hay un caso con el doble ("inseguros", `:216`) | Que `LeerCarpeta` y `MotivoCarpeta` vean lo que Windows tiene de verdad (RS-05) |
| Archivo en uso, antivirus, vínculo físico, unión dentro del subárbol | — | RS-05, RS-06 |
| `EjecutableEnMarcha` con un servicio y con un proceso suelto | Un doble que dice "en marcha" | RS-03 |
| DACL que recibe un archivo copiado (herencia) y si la cuenta virtual lo lee | — | RS-09 |
| Corte de energía a mitad | — | RS-07 |
| `Revertir` de punta a punta con SQL real (`RESTORE`, `CHECKSUM`, H-11) | Una prueba textual del guion | Todo el bloque RV |
| `dbcreator` real, dueño de la base creada, techo de privilegios | — | EM-01, EM-07 |
| El anillo del servicio frente al del técnico | — | CU-01 a CU-05 |

## 2. Reglas, montaje y funciones de apoyo

### 2.1 Reglas heredadas (sin cambios; resumen)

1. Solo en `VM-SRV` (de `LFMB`), desde `base`; nunca en la PC del propietario ni en OSHIN-LEGION. Lo opera B; yo reviso la evidencia ya redactada.
2. Un punto de control por bloque (`.\Puntos-Control.ps1 -Vm VM-SRV -Accion Tomar -Nombre LAB-D2-<ID>`) y `Restaurar base` al terminar.
3. **Si algo falla no se corrige a mano para que pase**: se anota (ruta, código, texto del evento) y se restaura el punto de control.
4. **Ningún secreto en la evidencia.** Prohibido: `reg query`/`reg export` de `HKLM\SYSTEM\CurrentControlSet\Services\GPOS.Api` o `GPOS.Reportes`; `Get-ItemProperty` de esas claves sin `-Name`; imprimir el valor `Environment`; poner una clave en la línea de comandos. Las claves iniciales de las cuentas son **centinelas falsas y visibles** (ADMIN `Lab-Admin-Centinela-01`, GSF `Lab-Gsf-Centinela-0001`, ≥ 12 caracteres para GSF), nunca las de una persona. La prueba de que algo no cambió se hace con **booleanos** (función `MismoEntorno`), nunca con el valor.
5. Una sola corrida a la vez en `LFMB`; ninguna suite compilando durante la ventana.
6. Los datos son los del DEMO (`datos-demo`) o filas centinela inventadas; nunca datos de un cliente.
7. Sin `sysadmin` ni roles de servidor "para ver si arranca" a la cuenta virtual (condición del plan de A). Los cambios de SQL que hace el caso (quitar `dbcreator` en EM-02) los hace el administrador de la VM y son parte del caso.

### 2.2 Precondiciones (no son casos; B las fija antes de cada sesión)

| ID | Qué | Estado |
|---|---|---|
| PRE-1 | `VM-SRV` desde `base` con `Preparar-Vm.ps1` aplicado (`-Comprobar` todo en `OK`), Windows Server 2025, FIPS no; **SQL Express arrancado** (a diferencia de T4-03); `gpos-lab-usuario` (estándar). Punto de control `LAB-D2-LISTO` | Existe [V: aviso de B] |
| PRE-2 | **Cuatro paquetes del DEMO en modo servicios** (`Publicar-PaqueteDemo.ps1 -ConApiReportes`), Release, cada uno con su `manifiesto.sha256`, extraídos en una carpeta local fuera de OneDrive y del perfil, escrita solo por SYSTEM y Administradores (`Instalar-Demo.ps1` y `Actualizar-Demo.ps1` lo exigen): **PQ-A** (base); **PQ-B** (cambia ≥ 1 archivo de `app\api` y de `app\reportes`, **añade** ≥ 1 archivo nuevo en cada una y **quita** ≥ 1 archivo que PQ-A tenía en `app\api`); **PQ-C** (cambia otra vez ≥ 1 archivo respecto a PQ-B); **PQ-B2** (los mismos binarios de servicios que PQ-B, distinto solo en un guion o en `version.json`: sirve a RV-04a). Para RS-07, PQ-A y PQ-B llevan un `relleno.bin` de ≈ 400 MB **distinto** en cada uno (en el manifiesto de ambos). SHA-256 de cada carpeta de manifiesto y de `GPOS.Migracion.exe` anotados. **Restricción vigente (aviso de B del 23-oct): no se publica ningún DEMO de `feature/modelo-ng` desde la unión de T4-06 hasta la tarea 3**: los cuatro salen de `a/pr-d2-manifiesto` o de un commit anterior a T4-06 | **Por construir** (D-1) |
| PRE-3 | **Nivel V:** `GPOS.Migracion.exe` de PQ-A en PATH de la sesión elevada; `implantar-servidor --perfil demo --fase carpetas --origen <PQ-A>` y `--fase servicios --origen <PQ-A>` ya ejecutados (servicios creados, detenidos, sin arrancar). Punto de control `LAB-D2-A`. Luego `--fase servicios --origen <PQ-B>` (crea `.anterior` verificada); punto de control `LAB-D2-A2B` | Se hace al inicio de S6 |
| PRE-4 | **Nivel G:** el instalador de servicios **terminado** (A, 5 al 9-nov) sobre F1 (anillo) y `Instalar-Demo.ps1 -Paquete PQ-A` completo; `datos-demo` cargados; una fila centinela en la base de la empresa antes de cada actualización (ver `Marca-Fila` abajo). Punto de control `LAB-D2-G-A` | [?] |
| PRE-5 | **Nivel A (EM y CU):** `anillo --preparar --recuperacion <par de laboratorio desechable>` y `anillo --anclar` hechos; `GPOS.Api.anillo.json` presente; servicios en `Running`; `NT SERVICE\GPOS.Api` con el rol que A decida (D-5) | [?] F1 sin unir |
| PRE-6 | **Herramientas:** `fsutil`, `icacls`, `mklink` (de Windows); un **bloqueador de archivo** (`Bloquear-Archivo.ps1`: abre un archivo con `FileShare.None` y espera una tecla); `auditpol`; para CU-05, habilitar a mano (cambio de estado de la VM, se restaura con el punto de control) la auditoría de creación de procesos con línea de comandos y el registro de módulos de PowerShell. Las tres piezas del anfitrión son mías y pequeñas (≈ 0,2 dp) si B confirma | Por escribir |

### 2.3 Funciones de apoyo (PowerShell 5.1 elevado; **escritas sin probar**)

```powershell
$E = 'C:\GPOS-LAB\evidencia\D2'; New-Item -ItemType Directory -Force $E | Out-Null
$D = Join-Path $env:ProgramFiles 'GPOS NG\Demo'                      # destino de los binarios
function Snap([string]$id){                                         # hash + fecha de cada archivo (incluye .anterior y marcas); no imprime contenido
  Get-ChildItem -LiteralPath $D -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
    '{0}|{1}|{2}' -f (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash, $_.LastWriteTimeUtc.Ticks, $_.FullName.Substring($D.Length)
  } | Sort-Object | Set-Content "$E\$id.snap" }
function CompararManifiesto([string]$carpeta,[string]$manifiesto){   # cuenta de diferencias de app\api y app\reportes contra un manifiesto.sha256 (formato: "<hash>  app\ruta")
  $mal = 0; $bien = 0
  foreach($l in Get-Content $manifiesto){ if($l -match '^([0-9a-fA-F]{64})  app\\((api|reportes)\\.+)$'){
    $f = Join-Path $carpeta $Matches[2]; $h = if(Test-Path -LiteralPath $f){ (Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash } else { '' }
    if($h -ieq $Matches[1]){ $bien++ } else { $mal++ } } }
  [pscustomobject]@{ Coinciden=$bien; Distintos=$mal } }
function Sobrantes([string]$carpeta,[string]$manifiesto){            # archivos de api\ y reportes\ que el manifiesto no tiene
  $rel = Get-Content $manifiesto | ForEach-Object { if($_ -match '^[0-9a-fA-F]{64}  app\\(.+)$'){ $Matches[1].ToLower() } }
  foreach($c in 'api','reportes'){ Get-ChildItem -LiteralPath (Join-Path $carpeta $c) -Recurse -File -Force -ErrorAction SilentlyContinue |
    ForEach-Object { $r = $_.FullName.Substring($carpeta.Length).TrimStart('\').ToLower(); if($rel -notcontains $r){ $r } } } }
function FotoServicios([string]$id){                                 # sin Environment: solo configuración de sc, nombres de valores y SDDL de la clave
  New-Item -ItemType Directory -Force "$E\$id" | Out-Null
  foreach($s in 'GPOS.Api','GPOS.Reportes'){
    foreach($c in 'qc','qprivs','showsid','qsidtype','qfailure','sdshow','query'){ & sc.exe $c $s | Set-Content "$E\$id\$s-sc-$c.txt" }
    (Get-Item "HKLM:\SYSTEM\CurrentControlSet\Services\$s").GetValueNames() | Sort-Object | Set-Content "$E\$id\$s-valores.txt"
    (Get-Acl "HKLM:\SYSTEM\CurrentControlSet\Services\$s").Sddl | Set-Content "$E\$id\$s-sddl-clave.txt" } }
function GuardarEntorno([string]$svc){                               # guarda en MEMORIA el hash del valor Environment; nunca se imprime ni se escribe
  $k = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SYSTEM\CurrentControlSet\Services\$svc")
  try{ $v = $k.GetValue('Environment'); if($null -eq $v){ $script:ent[$svc] = 'sin-valor'; return }
       $b = [Text.Encoding]::UTF8.GetBytes(($v -join "`n")); $script:ent[$svc] = -join ([Security.Cryptography.SHA256]::Create().ComputeHash($b) | ForEach-Object { $_.ToString('x2') }) } finally { $k.Dispose() } }
$script:ent = @{}
function MismoEntorno([string]$svc){ $antes = $script:ent[$svc]; GuardarEntorno $svc; $script:ent[$svc] -eq $antes }   # solo imprime True o False
function EventosD2([datetime]$desde){ Get-WinEvent -FilterHashtable @{LogName='Application';ProviderName='GPOS.Instalacion';StartTime=$desde} -ErrorAction SilentlyContinue |
  Select-Object Id,LevelDisplayName,TimeCreated,Message }
function HuellaPrevia { (Get-FileHash -LiteralPath "$D\.anterior\manifiesto.sha256" -Algorithm SHA256).Hash.ToLowerInvariant() }
```

`GuardarEntorno` lee el valor en el proceso del técnico: es la única lectura del entorno que permite este documento, sin salida; **D-3** pregunta si el auditor la acepta o prefiere la prueba por sesión (RV-01 paso 10).

Plantilla de evidencia por caso (sin secretos), en `$E\<ID>.json`: `{ id, resultado, inicio, fin, punto_de_control, observado:{...booleanos y conteos...}, hallazgos:[{severidad,pasos,esperado,obtenido}] }`.

## 3. Observaciones previas a la VM sobre `cd44043c` (de QA; no corrijo nada)

| # | Sev. | Observación | Evidencia | Qué pido |
|---|---|---|---|---|
| **P-D2-01** | **Media** (reproducible por uso normal; sin datos de cliente) | **El ciclo revertir → actualizar de nuevo → revertir deja los binarios sin restaurar.** Tras `Revertir`, `.anterior` conserva la copia previa de la versión anterior (A) y `manifiesto.instalado.sha256` es el de A. Al volver a actualizar al mismo paquete (B), `CopiarBinarios` hace una copia previa de A: `.anterior\manifiesto.sha256` queda con **exactamente el mismo texto** que antes (`# estado=verificada` más las mismas huellas), así que su SHA-256 es el mismo. `Actualizar-Demo.ps1` solo anota `HuellaCopiaPrevia` si esa huella **cambió** (`$huellaDespues -ne $huellaAntes`), y concluye "no cambió los binarios de los servicios" aunque sí los cambió. La siguiente `Revertir` toma `$sinBinarios = $true` (`Revertir-Actualizacion.ps1:75-78`), restaura las **bases** a A y deja los **programas** en B; la API "solo trabaja con la versión exacta de esquema" (`:21`). La marca decía dos veces "no cambió", el técnico no tiene cómo saberlo | `Actualizar-Demo.ps1` (≈ `:149-163`), `Revertir-Actualizacion.ps1:73-78`, `FaseServicios.cs` `CopiarBinarios` (paso 2: la copia previa se rehace con `CrearCarpetaProtegida` y se escribe el mismo texto) | Confirmar y corregir antes del 16-nov. Remedio sugerido: no decidir por "la huella cambió", sino por si la fase dijo "Copia previa de N archivos" (o que la fase imprima un identificador único por copia y el guion lo anote). Caso: `LAB-RV-06` |
| P-D2-02 | Media | `.aplicando` no impide arrancar los servicios (R-04 (a) de A, sin hacer): el usuario que instala puede iniciar `GPOS.Api` con el destino mezclado | Revisión de A R-04; `git grep .aplicando` solo encuentra la fase, `FaseServicios` y el guion | Decidir si se hace antes de la VM; si no, RS-06 lo registra como hallazgo conocido |
| P-D2-03 | Baja | `Revertir-Actualizacion.ps1` no corre `comprobar-servidor` después de la fase (el blueprint §5 y R-09 lo piden), y no inicia los servicios ni dice que hay que correr `Iniciar-Demo.ps1` | `Revertir-Actualizacion.ps1:120-165` | Añadirlo; mientras tanto el caso RV-01 lo corre a mano |
| P-D2-04 | Media | R-03 solo se cubrió para la carpeta raíz de cada servicio (`destino\api`, `destino\reportes`): un punto de reanálisis o un vínculo físico **dentro** del subárbol sigue sin detectarse, y la copia escribe con `FileMode.Create` a través de ellos | `FaseRestaurar.cs:50-52`; `SistemaServidorWindows.cs:223` | RS-05 lo mide; la corrección es de A (R-03 completa) |
| P-D2-05 | Informativo | El instalador de servicios se detiene a propósito antes de `instalacion.json` (`Instalar-Demo.ps1:167`): hasta el 5 al 9-nov no hay Nivel G | `Instalar-Demo.ps1:167` | Confirmar fechas (D-9) |
| P-D2-06 | Baja | En modo de servicios el registro de la empresa **no** pasa por `GPOS__EmpresaInicial__*`: no hay quien cree la base de la empresa hasta que A escriba "creación por la interfaz como GSF" | `pr-d2-empresa-y-cuentas-bloqueo.md`, `acuse-decisiones-y-fase-restaurar-construida.md` | Ver EM y D-5 |

## 4. Orden de sesiones y puntos de control

| Sesión | Contenido, en este orden | Tiempo [I] |
|---|---|---|
| **S6** (Nivel V, `VM-SRV` sola) | PRE-1 y PRE-3 (60 min) → `LAB-D2-A2B` → RS-01, RS-02 (35) → RS-08 (20) → RS-09 (25) → RS-03 (20) → RS-04 (45; cada subcaso desde `LAB-D2-A2B`) → RS-05 (50; cada subcaso desde su punto) → RS-06 (40) → RS-10 (15) → RS-11 (20) → **RS-07 al final** (30; deja la VM sucia) | ≈ 6 h |
| **S7** (Nivel G) | PRE-4 (45) → `LAB-D2-G-A` → RV-02 (10) → RV-01 (60) → `LAB-D2-G-A2B` (después de actualizar) → RV-04a a d (60, cada una desde su punto) → RV-05 (35) → RV-06 (40) → RV-03 (40; necesita PQ-C) → RV-07 (10) | ≈ 5 h |
| **S8** (Nivel A) | PRE-5 (40) → `LAB-D2-ANILLO` → CU-02, CU-03 (20) → CU-01 (40) → CU-04 (15) → CU-06 (15) → EM-01 (40) → EM-07 (20) → EM-02 (25) → EM-03 (25) → EM-04 (25) → EM-06 (25) → EM-05 (30) → CU-05 (45; deja auditoría activa, al final) | ≈ 6 h |

## 5. Bloque RS: la fase `restaurar` llamada directamente (Nivel V)

Todos parten de `LAB-D2-A2B`: destino con PQ-B instalado, `.anterior` con la copia previa verificada de PQ-A, `manifiesto.instalado.sha256` de PQ-B, servicios creados y **detenidos**. Ejecutable: `GPOS.Migracion.exe implantar-servidor --perfil demo --fase restaurar [--destino …] [--huella-copia-previa <sha256>]`, en consola **elevada**. Códigos [V]: 0 hecho, 4 detenido por una guarda; fallo de opciones o de precondición ≠ 0 (1 [I]).

### LAB-RS-01. Camino feliz: los binarios vuelven a PQ-A y se verifican en el destino

- **Precondición:** `LAB-D2-A2B`. `Snap 'RS01-antes'`; `CompararManifiesto "$D" <manifiesto de PQ-B>` → 0 distintos (y contra PQ-A → ≥ 1 distinto: **control**); `Sobrantes "$D" <PQ-A>` → lista (≥ 1: los que añadió PQ-B); `FotoServicios 'RS01-antes'`; `GuardarEntorno` de ambos servicios.
- **Pasos:**
  1. `$h = HuellaPrevia` (el valor que `Actualizar-Demo.ps1` habría anotado).
  2. `$desde = Get-Date; GPOS.Migracion.exe implantar-servidor --perfil demo --fase restaurar --huella-copia-previa $h *>&1 | Tee-Object "$E\RS01-salida.txt"; $LASTEXITCODE`.
  3. `Snap 'RS01-despues'`; `CompararManifiesto "$D" <PQ-A>` y `Sobrantes "$D" <PQ-A>`; `Test-Path "$D\.aplicando"`; `Test-Path "$D\.anterior\manifiesto.sha256"` y `HuellaPrevia -eq $h`; `Compare-Object (Get-Content "$D\manifiesto.instalado.sha256") (Get-Content <manifiesto de PQ-A filtrado a api y reportes>)`.
  4. `EventosD2 $desde`; `FotoServicios 'RS01-despues'` y `Compare-Object` carpeta a carpeta; `MismoEntorno` de ambos servicios.
  5. `icacls` de tres archivos restaurados (el `.exe`, una `.dll`, un `.json`) y del archivo que PQ-B había **quitado** y la restauración recreó → `RS01-acl.txt`.
- **Esperado:**
  - Código 0 y la línea "Binarios restaurados en … y verificados en el destino (N archivos)".
  - 0 archivos distintos contra PQ-A; 0 sobrantes (lo que añadió PQ-B ya no está); el archivo que PQ-B quitó, **de vuelta**.
  - Sin `.aplicando`; `.anterior` **sigue** (no se borra) con la misma huella; `manifiesto.instalado.sha256` es el de PQ-A.
  - Evento 5135 `resultado=ok cambios=N` (N = archivos restaurados + sobrantes borrados + 1 [I]); ninguna ruta del perfil de usuario ni texto de excepción.
  - Configuración de los dos servicios **idéntica** antes y después; `MismoEntorno` `True` en los dos.
  - Los archivos restaurados heredan la DACL de la carpeta (sin ACE de `Users` ni de `Authenticated Users` con escritura).
- **Rechazo:** **Alta:** "ok" con algún archivo distinto de PQ-A, algún sobrante, o con `.aplicando` presente; `MismoEntorno` `False` o cambio en `sc` (la fase no debe tocar servicios ni entorno); `.anterior` borrada. **Media:** un archivo restaurado con una ACE de escritura para usuarios; texto con rutas de usuario o mensaje de excepción en la salida o el evento.
- **Evidencia:** `RS01-antes.snap`, `RS01-despues.snap`, la salida, los conteos, el evento 5135, las dos `FotoServicios`, las ACL. Sin valores de entorno.
- **Control negativo:** el paso previo `CompararManifiesto` contra PQ-A en el estado `LAB-D2-A2B` da ≥ 1 distinto y `Sobrantes` ≥ 1 (el instrumento ve la diferencia); y la misma prueba contra PQ-B tras el paso 2 da ≥ 1 distinto (no quedó en B).
- **Duración:** 25 min. **Marca:** [I]; la lógica es [V] en `FaseRestaurar.cs:99-131`.

### LAB-RS-02. Repetirla no cambia nada

- **Precondición:** a continuación de RS-01 (`Snap 'RS02-antes'`).
- **Pasos:** repetir el comando del paso 2 de RS-01 (con la misma huella, que sigue siendo válida); `Snap 'RS02-despues'`; `Compare-Object` de ambos; eventos.
- **Esperado:** código 0, "ya son los de la copia previa (N archivos verificados)"; las dos `.snap` **idénticas** (incluidas las fechas: nada se reescribió); evento 5135 con `cambios=0`.
- **Rechazo:** **Media:** cualquier archivo con fecha distinta (la segunda pasada reescribió); `cambios` > 0 sin motivo.
- **Control negativo:** alterar un byte de un archivo del destino con `[IO.File]::AppendAllText` (lo hace el técnico, como administrador) y repetir: ahora sí `cambios` ≥ 1 y el archivo vuelve (la prueba ve la diferencia). Después, otra pasada: `cambios=0`.
- **Evidencia:** dos `.snap` y su diferencia (vacía), eventos. **Duración:** 10 min. **Marca:** [V] por `FaseRestaurar.cs:80-88`; [I] hasta ejecutar.

### LAB-RS-03. Ni con un ejecutable en marcha

- **Precondición:** `LAB-D2-A2B`; `Snap 'RS03-antes'`.
- **Pasos:**
  1. **Con un proceso suelto (Nivel V, sin anillo):** lanzar `GPOS.Reportes.Api.exe` desde `"$D\reportes"` con `ASPNETCORE_URLS=http://127.0.0.1:5999` en el entorno del proceso (solo para este caso). Confirmar con `Get-Process GPOS.Reportes.Api` que sigue vivo a los 5 s. Si **no** sigue vivo (la API sin SQL ni configuración puede salir de inmediato), anotarlo y pasar a 3 (**D-2**).
  2. Con el proceso vivo, ejecutar `restaurar`; luego detener el proceso y repetir (control).
  3. **Con el servicio (Nivel A):** `Start-Service GPOS.Api` y, con el servicio `Running`, ejecutar `restaurar`.
  4. **Falso positivo:** copiar `GPOS.Reportes.Api.exe` y sus bibliotecas a `C:\GPOS-LAB\copia\` y ejecutarlo **desde ahí**; correr `restaurar`.
- **Esperado:** pasos 1 y 3: código 4, "`GPOS.Reportes.Api.exe` está en marcha: detenga el servicio … No se tocó …"; `Snap` idéntico al de antes; sin `.aplicando`; el evento de guarda en "Detenido". Paso 4: **no** se bloquea (la comparación es por ruta completa): `restaurar` procede y termina en 0 (el proceso de la copia no es de los servicios).
- **Rechazo:** **Alta:** `restaurar` escribe algo con el proceso del destino vivo; deja `.aplicando`. **Media:** el paso 4 se detiene sin razón (falso positivo que impediría revertir con otra cosa corriendo).
- **Control negativo:** el mismo comando con el proceso detenido restaura (RS-01); sin ese par, el caso no concluye.
- **Evidencia:** salida, código, `.snap` antes y después, `Get-Process` de cada paso (nombre, PID y ruta del módulo). **Duración:** 20 min. **Marca:** [V] por `SistemaServidorWindows.cs:498-513`; [I] el comportamiento del proceso suelto.

### LAB-RS-04. Rechazos de la copia previa: ni una escritura

Cada subcaso desde `LAB-D2-A2B` (o desde el punto que se indica). En todos: `Snap` antes y después **idénticos**, sin `.aplicando`, código 4 (o ≠ 0 donde se indica), sin texto de excepción.

| ID | Preparación | Esperado | Rechazo |
|---|---|---|---|
| RS-04a | Punto `LAB-D2-A` (solo PQ-A, nunca se actualizó): no hay `.anterior` | "No hay copia previa … nada que restaurar" | Crea carpetas o escribe |
| RS-04b | Renombrar `.anterior\manifiesto.sha256` | "La copia previa no trae manifiesto.sha256" | Restaura sin manifiesto |
| RS-04c | **Estado `no-verificada` natural:** desde `LAB-D2-A`, alterar un byte de un archivo del destino y **luego** `--fase servicios --origen PQ-B`. La fase copia igual; el encabezado queda `# estado=no-verificada` | "La copia previa no es de un paquete verificado … reinstale desde el paquete anterior" | Restaura una copia no verificada. Probar además que **no existe forma de forzarla**: `--forzar`, `--sin-verificar` y similares deben dar un error de opciones |
| RS-04d | Igual a RS-04c pero borrando `manifiesto.instalado.sha256` antes de actualizar (destino "de antes de este control") | Igual a RS-04c | Idem |
| RS-04e | Cambiar un byte de un archivo respaldado dentro de `.anterior` (administrador) | "Huella SHA-256 distinta en la copia previa: …"; destino intacto | Copia desde un respaldo alterado |
| RS-04f | Agregar a `.anterior\manifiesto.sha256` una línea con ruta `app\api\..\..\x`, otra absoluta (`C:\…`) y otra con `:` (una a la vez) | "…" del intérprete del manifiesto (ruta no válida); destino intacto | Acepta la ruta o la sigue |
| RS-04g | Quitar o duplicar la línea `# estado=…`; agregar una segunda línea que empiece por `#` | "El manifiesto de la copia previa no declara su estado" o error de manifiesto | Lo acepta |
| RS-04h | `--huella-copia-previa` con 64 caracteres hexadecimales que **no** son la de `.anterior`; luego con la correcta (control); luego con texto no hexadecimal | La falsa: "La copia previa no es la de esa actualización …", código 4, intacto. La correcta: restaura. La inválida: error de opciones | Restaura con la huella falsa |
| RS-04i | `.anterior` vacía (borrar su contenido) | Sin manifiesto: "no trae manifiesto" | Escribe |

- **Evidencia:** por subcaso, salida y código, `Snap` antes y después y su `Compare-Object` (vacío), el evento de guarda; para RS-04c y RS-04d, `Get-Content "$D\.anterior\manifiesto.sha256" -TotalCount 1`.
- **Control negativo del bloque:** RS-01 (la misma fase sobre la copia sana restaura). Un subcaso que no dé "intacto" más RS-01 en verde es lo que se informa.
- **Duración:** 45 min (9 subcasos de ≈ 5 min con puntos de control). **Marca:** [V] los textos y el orden por `FaseRestaurar.cs:55-76`; [I] el resultado en Windows.

### LAB-RS-05. Carpetas y objetos peligrosos en el destino (R-03 y las guardas de `MotivoCarpeta`)

Cada subcaso desde su punto de control propio. En cada uno se planta **un archivo centinela** fuera de `Program Files\GPOS NG` (por ejemplo `C:\GPOS-LAB\centinela\canario.txt`, con su SHA-256 anotado) para ver si la fase lo toca.

| ID | Se planta | Esperado hoy [I] (según el código de `cd44043c`) | Rechazo |
|---|---|---|---|
| RS-05a | `.anterior` con dueño `gpos-lab-usuario` (`icacls "$D\.anterior" /setowner gpos-lab-usuario`) | Código 4 con el motivo de `MotivoCarpeta` (dueño); intacto | Restaura |
| RS-05b | `.anterior` con ACE de escritura para `BUILTIN\Users` | Código 4 (escritor no permitido); intacto | Restaura |
| RS-05c | `.anterior` reemplazada por una unión (`mklink /J`) a `C:\GPOS-LAB\otra-copia-previa` con un manifiesto y archivos válidos | Código 4 (punto de reanálisis); intacto | Sigue la unión |
| RS-05d | **Antepasado**: `Program Files\GPOS NG` o `…\Demo` con dueño ajeno o escritura para `Users` | Código 4 en el primer antepasado inseguro | Restaura |
| RS-05e | **R-03, raíz del servicio:** `destino\api` reemplazada por una unión a `C:\GPOS-LAB\centinela` | Código 4 "es un punto de reanálisis"; el `canario.txt` **intacto** y ningún archivo borrado fuera del destino | Borra o escribe a través de la unión (**Crítica** si el destino de la unión pierde o gana archivos) |
| RS-05f | **R-03, subárbol (P-D2-04):** una unión `destino\api\runtimes` → `C:\GPOS-LAB\centinela`, con una entrada del manifiesto de `.anterior` bajo `api\runtimes\` | **Documentar** qué hace: [I] hoy no hay guarda del subárbol y `CopiarSinReanalisis` abre el destino con `FileMode.Create`, así que escribiría en el destino de la unión. Un rechazo (código 4) cumple; escribir fuera, no | Escribe en `C:\GPOS-LAB\centinela` (**Media**, defensa en profundidad: exige haber escrito antes en el destino; confirma P-D2-04). **Alta** si borra |
| RS-05g | **Vínculo físico** a un archivo de fuera: `fsutil hardlink create "$D\api\X.dll" C:\GPOS-LAB\centinela\x.bin`, con `api\X.dll` en el manifiesto | Igual que RS-05f: [I] la copia reescribiría el archivo de fuera por el vínculo | Cambia el SHA-256 de `x.bin` (**Media**) |
| RS-05h | Un archivo del destino con atributo de solo lectura, y otro con una DACL que niega escritura a SYSTEM | Fallo de ese archivo: lo informa por nombre; la marca queda; no hay excepción cruda (se completa en RS-06) | Excepción con texto del sistema |

- **Evidencia:** salida, código, SHA-256 del `canario.txt` y de `x.bin` antes y después (la regla: **iguales** salvo donde el caso dice lo contrario), `Get-Acl … | Format-List Owner,Sddl` de lo plantado, `dir /AL` del destino.
- **Control negativo:** el mismo escenario sin lo plantado es RS-01. En RS-05e–g, además, el control de instrumento: el `canario.txt` se modifica a mano (un byte) y se ve que el SHA-256 lo detecta.
- **Duración:** 50 min (8 subcasos). **Marca:** RS-05a–e [V] por `FaseRestaurar.cs:34-52,55-58`; RS-05f–g [V] por `SistemaServidorWindows.cs:170-173,223`, resultado [I].

### LAB-RS-06. Fallo a mitad: la marca `.aplicando`, la reanudación y lo que la marca no impide

- **Precondición:** `LAB-D2-A2B`; `Bloquear-Archivo.ps1` (PRE-6).
- **Pasos:**
  1. Abrir con `FileShare.None` un archivo de `destino\api` que `restaurar` debe reescribir (uno que cambió entre PQ-A y PQ-B) y dejarlo abierto. `Snap 'RS06-antes'`.
  2. Ejecutar `restaurar`. Anotar código y salida. `Snap 'RS06-parcial'`; `Test-Path "$D\.aplicando"`.
  3. **Con la marca presente**: (a) `--fase servicios --origen PQ-B` otra vez; (b) `Start-Service GPOS.Reportes` y, si el anillo existe, `Start-Service GPOS.Api` (Nivel A); (c) `Revertir-Actualizacion.ps1` queda para RV-05.
  4. Soltar el archivo. Ejecutar `restaurar` otra vez.
  5. Repetir 1 a 4 con un archivo **nuevo** que PQ-B añadió (borrado de sobrante bloqueado).
- **Esperado:**
  - Paso 2: código 4, "No se pudo restaurar N archivo(s) (nombre, …); la marca `.aplicando` queda: detenga lo que los use y repita --fase restaurar. No inicie los servicios"; hasta 5 nombres; **sin** texto de excepción; `.aplicando` existe; los demás archivos sí se restauraron.
  - Paso 3a: `--fase servicios` se niega con "ejecute `--fase restaurar`" (no "a mano"), sin tocar nada.
  - Paso 3b, **hallazgo conocido (P-D2-02):** hoy nada impide arrancar; se anota si el servicio arranca y con qué binarios. Un rechazo del servicio por la marca cumple con la recomendación de A; que arranque es `No cumple` Media (R-04 (a) sin hacer).
  - Paso 4: "Se retoma una copia interrumpida", código 0, destino = PQ-A, sin `.aplicando`, `manifiesto.instalado.sha256` de PQ-A. Paso 5 igual.
- **Rechazo:** **Alta:** código 0 con `.aplicando` presente o con algún archivo distinto; el paso 4 no retoma; la marca se borra sin verificar. **Media:** el servicio arranca con la marca (P-D2-02); texto de excepción en la salida.
- **Control negativo:** sin el bloqueo (RS-01) no hay marca ni "No inicie los servicios". Y la misma secuencia con `Bloquear-Archivo.ps1` sobre un archivo **ajeno al manifiesto** (que no es ni sobrante) no debe impedir `restaurar`.
- **Evidencia:** las dos `.snap`, salida y códigos de los pasos 2 y 4, eventos (el de guarda con 4 y el 5135 con `resultado=detenido` o `ok`), `Get-Service` tras el paso 3b y `(Get-Item <exe>).VersionInfo.ProductVersion`.
- **Duración:** 40 min. **Marca:** [V] por `FaseRestaurar.cs:91-123`; [I] el efecto del bloqueo y del arranque.

### LAB-RS-07. Corte de energía durante la copia (relleno de 400 MB)

- **Precondición:** PQ-A y PQ-B con `relleno.bin` distinto (PRE-2); `LAB-D2-A2B` con ese relleno. `Snap` antes.
- **Pasos:** ejecutar `restaurar`; a los 2 s, desde el anfitrión: `VBoxManage controlvm VM-SRV poweroff`. Arrancar la VM; sin tocar nada, `Test-Path "$D\.aplicando"`, `CompararManifiesto "$D" <PQ-A>`, `chkdsk C: /scan` (solo lectura); ejecutar `restaurar` otra vez.
- **Esperado [I]:** tras el corte: `.aplicando` presente y archivos mezclados (algunos de PQ-A, el `relleno.bin` truncado o completo); `chkdsk` limpio; la segunda pasada: "Se retoma …", 0 distintos contra PQ-A, sin marca, `Get-FileHash relleno.bin` = el de PQ-A. **No** se inicia ningún servicio entre medias.
- **Rechazo:** **Alta:** tras el corte no hay marca (porque se creó después del primer archivo) o la segunda pasada deja "ok" con el `relleno.bin` truncado; `chkdsk` con daños de NTFS que no sean del archivo copiado.
- **Control negativo:** la misma operación sin corte termina sin marca (RS-01).
- **Evidencia:** `.snap` antes, tras el corte y al final; salida de la segunda pasada; `chkdsk`. Ventana de tiempo: si a 2 s ya terminó, se repite con 1 s o con el relleno más grande (**D-7**).
- **Duración:** 30 min (puede repetirse). **Marca:** [I]; la lógica es [V] (la marca se crea antes del primer archivo, `FaseRestaurar.cs:91-93`).

### LAB-RS-08. Lo que `restaurar` no toca

- **Precondición:** `LAB-D2-A2B` (con SQL y, en Nivel A, con la base del sistema y las cuentas). `FotoServicios`, `GuardarEntorno` de ambos servicios, y una "foto" de lo demás: `icacls` de `%ProgramData%\GPOS NG` (recursivo), `sc` de ambos, orígenes de eventos (`[Diagnostics.EventLog]::SourceExists('GPOS.Api')`, `'GPOS.Reportes'`, `'GPOS.Instalacion'`), y, con SQL, `SELECT name, create_date, modify_date FROM sys.databases WHERE name LIKE 'GPOS[_]%'` y `SELECT COUNT(*) FROM <base empresa>.conf.__EFMigrationsHistory`.
- **Pasos:** ejecutar `restaurar` (RS-01); repetir todas las fotos y comparar. Control: ejecutar `--fase servicios --origen PQ-B --rotar-jwt` desde otro punto y comparar las mismas fotos.
- **Esperado:** todas idénticas tras `restaurar`; `MismoEntorno` `True` en los dos servicios; ninguna base cambió (`modify_date` igual).
- **Control negativo:** tras `--rotar-jwt`, `MismoEntorno` de `GPOS.Api` es `False` (el instrumento ve el cambio) y el de `GPOS.Reportes` sigue `True`.
- **Rechazo:** **Alta:** `MismoEntorno` `False` tras `restaurar` (cambió la clave JWT: cierra sesiones, el blueprint dice que no); cambio en `sc` o en las bases. **Media:** cambia un SDDL de carpeta de datos.
- **Evidencia:** las fotos y sus diferencias; solo booleanos del entorno. **Duración:** 20 min. **Marca:** [V] (la fase no llama a esas APIs: `FaseRestaurar.cs` entero); [I] el resultado.

### LAB-RS-09. Los binarios restaurados arrancan bajo la cuenta virtual

- **Precondición:** `LAB-D2-A2B`; `restaurar` hecho (RS-01). Hay una diferencia de versión visible entre PQ-A y PQ-B (B la fija: `ProductVersion` distinto en `GPOS.Api.dll` o en el ejecutable).
- **Pasos:**
  1. `(Get-Item "$D\api\GPOS.Api.exe").VersionInfo.ProductVersion` antes (B) y después (A).
  2. `icacls "$D\api\GPOS.Api.exe"` y de una DLL restaurada: debe haber lectura y ejecución para `NT SERVICE\GPOS.Api` por herencia, escritura **no**.
  3. Iniciar el servicio: `$desde = Get-Date; sc.exe start GPOS.Reportes; Start-Sleep 20; sc.exe query GPOS.Reportes; Get-WinEvent` de `Application` (proveedores `.NET Runtime`, `Application Error`, `GPOS.*`) desde `$desde`.
  4. Nivel A: `Iniciar-Demo.ps1` (arranca ambos y corre `comprobar-servidor`); `GET /api/salud` de 5071 y 5073 con la versión (R5, si el cambio aditivo existe).
- **Esperado:** versión de A tras `restaurar`; ACL con lectura y ejecución para la cuenta virtual; el servicio arranca o falla **por configuración** (sin anillo: lo que falló sea AN-05 o la cadena, no "acceso denegado" al ejecutable ni una DLL faltante o de otra versión); Nivel A: ambos `/api/salud` 200 y `comprobar-servidor` con código 0 o 2.
- **Rechazo:** **Alta:** el servicio no puede leer o ejecutar un archivo restaurado (error 5 o 1053 por acceso, `FileNotFoundException`, `BadImageFormat`); una DLL de PQ-B mezclada con una de PQ-A; la versión no es la de A. **Media:** `/api/salud` no muestra la versión.
- **Control negativo:** el mismo paso 3 antes de restaurar (con PQ-B) muestra la versión de B; sin esa diferencia no se concluye.
- **Evidencia:** versiones, ACL, eventos, `sc query`, `/api/salud` (código y versión). **Duración:** 25 min. **Marca:** [I]; el comentario del código ya lo marcaba "[I, VM]" (`FaseServicios.cs` paso 3 de `CopiarBinarios`).

### LAB-RS-10. Opciones, elevación y destino (lo que el doble no puede probar)

| ID | Se ejecuta | Esperado |
|---|---|---|
| RS-10a | `restaurar` desde una consola **no elevada** | Código ≠ 0, "exige una consola de administrador (elevada)"; sin eventos de fase |
| RS-10b | `--perfil produccion --fase restaurar` | "aún no está implementada para el perfil produccion"; ≠ 0 |
| RS-10c | `restaurar --origen <carpeta>`, `--rotar-jwt`, `--usuario-instala <x>`, `--acta`/`--motivo` | Error de opciones (≠ 0), sin tocar el destino |
| RS-10d | `--destino C:\GPOS-LAB\x`, `--destino "C:\Program Files\GPOS NG\Demo\..\..\x"`, `--destino "\\?\C:\Program Files\GPOS NG\Demo"`, la ruta corta 8.3 de `Program Files` | "tiene que ser una ruta absoluta dentro de … (Archivos de programa)" (o la guarda del antepasado); sin cambios |
| RS-10e | `--huella-copia-previa X` con otra fase (`--fase servicios`) | "--huella-copia-previa solo vale con --fase restaurar" |
| RS-10f | Dos veces la misma opción, o la opción sin valor | Error de opciones |

- **Control negativo:** RS-01 (la forma correcta funciona).
- **Rechazo:** **Alta:** escribe fuera de Archivos de programa; cualquier subcaso que cree carpetas o eventos de éxito. **Baja:** mensaje confuso.
- **Evidencia:** código y salida de cada uno; `Snap` antes y después. **Duración:** 15 min. **Marca:** [V] por `ComandoImplantarServidor.cs:16-27,58-65` y `FaseServicios.cs` `DestinoNormalizado`; [I] el resultado.

### LAB-RS-11. Dos `restaurar` a la vez, y `restaurar` durante una actualización

- **Precondición:** `LAB-D2-A2B` con el `relleno.bin` de 400 MB (alarga la ventana).
- **Pasos:** (1) lanzar dos `restaurar` casi simultáneos en dos consolas elevadas; anotar códigos y salidas; verificar el destino al final con `CompararManifiesto` y que no queda marca. (2) Desde otro punto de control: lanzar `--fase servicios --origen PQ-C` y, a los 2 s, `restaurar` en la otra consola.
- **Esperado [I]:** no hay bloqueo entre procesos documentado, así que se **anota** qué pasa. Aceptable: un proceso termina en 0 y el otro en 4 con el archivo en uso, o ambos terminan consistentes. Para (2): una de las dos se detiene o falla de forma limpia y el destino queda reanudable.
- **Rechazo:** **Alta:** destino mezclado **sin** marca (el estado inconsistente sin aviso); "ok" de un proceso mientras el destino no coincide con un manifiesto completo. **Media:** ambos terminan consistentes pero uno informa un fallo falso.
- **Control negativo:** una sola ejecución (RS-01).
- **Evidencia:** códigos, salidas, `.snap` final, `CompararManifiesto` contra los manifiestos de PQ-A y de PQ-C. **Duración:** 20 min. **Marca:** [I] (el código no declara exclusión entre procesos).

## 6. Bloque RV: `Revertir-Actualizacion.ps1` con servicios (Nivel G)

**Montaje común (PRE-4).** DEMO instalado con PQ-A en modo de servicios, `datos-demo` cargados. Antes de cada actualización, el técnico anota una **fila centinela** en la base de la empresa y otra en `GPOS_SYSDATA` (por ejemplo un registro con una descripción `LAB-RV-<n>-PRE`); después de actualizar, una segunda (`…-POST`). `Marca-Fila` es un `INSERT` mínimo que fija B con los campos obligatorios de la tabla elegida (una nota de configuración, por ejemplo): **D-1**. Las confirmaciones interactivas (`Read-Host 'Escriba RESTAURAR'`) las teclea el técnico.

Restauración del punto de control tras cada caso. Los registros (`registros\migracion.log`, `actualizacion.log`) se guardan **después** de revisar que no traen claves.

### LAB-RV-01. Ciclo completo feliz: instalar A, actualizar a B, revertir a A

- **Precondición:** `LAB-D2-G-A`; fila `LAB-RV-01-PRE`; servicios en marcha. `FotoServicios`, `GuardarEntorno`, `Snap 'RV01-A'`.
- **Pasos:**
  1. `.\Actualizar-Demo.ps1 -Paquete PQ-B` (elevado). Anotar si imprime el aviso "no cambió los binarios" (**no** debe). `Snap 'RV01-B'`; el `actualizacion.json` de la marca: **solo los nombres de los campos** y que `HuellaCopiaPrevia` existe (no se publica el valor completo) y que `Estado`.
  2. Fila `LAB-RV-01-POST`; iniciar con `Iniciar-Demo.ps1`; `/api/salud` con versión B; detener con `Detener-Demo.ps1`.
  3. `.\Revertir-Actualizacion.ps1` (sin parámetros): debe listar la marca y **no cambiar nada** (ver RV-02). Luego `.\Revertir-Actualizacion.ps1 -Marca <última> -RestaurarBases`; teclear `RESTAURAR`. Guardar la salida completa.
  4. Al terminar: `Snap 'RV01-revertido'`; `CompararManifiesto "$D" <PQ-A>` y `Sobrantes`; `Get-Service` de ambos (deben estar **detenidos**: el guion no los inicia); `actualizacion.json`: `Estado` = `revertida`; `config\instalacion.json`: `Paquete` y `Commit` los de A; `version.json` de A; la línea en `actualizacion.log`.
  5. Bases: la fila `…-PRE` **existe** y la `…-POST` **no** (las bases volvieron al respaldo).
  6. `MismoEntorno` de ambos servicios (la clave JWT no rota).
  7. `GPOS.Migracion.exe comprobar-servidor --perfil demo --sin-red` a mano (el guion no lo corre, P-D2-03): anotar el código (0 o 2 aceptable).
  8. `.\Iniciar-Demo.ps1`: arranca reportes y luego la API, espera `/api/salud` (versión A) y corre `comprobar-servidor`.
  9. **DM-01:** la base figura RESTAURADA; intentar emitir un documento con número → "Emisión bloqueada"; entrar como GSF por la Web, **Gestión de Secuencias > Restauración de la Base**, con motivo; emitir otro → funciona.
  10. **Sesión (opcional, si D-3 prefiere esta prueba a `MismoEntorno`):** una sesión de la Web abierta **antes** del paso 3 sigue válida tras el 8.
- **Esperado:** orden de pasos del guion 1 a 4 sin error; binarios = PQ-A; bases = respaldo; `revertida`; servicios detenidos al terminar el guion; `Iniciar-Demo.ps1` los levanta en la versión A; el mensaje DM-01 en amarillo; la clave JWT sin cambio; `comprobar-servidor` sin FALLA.
- **Rechazo:** **Alta:** binarios y bases de versiones distintas; `Estado` = `revertida` sin que la fase haya dado 0; el guion inicia los servicios; `MismoEntorno` `False`; la base no restaurada. **Media:** `comprobar-servidor` con FALLA tras una reversión que el guion dio por buena; el guion no avisa de que hay que correr `Iniciar-Demo.ps1`; claves o cadenas de conexión en el registro.
- **Evidencia:** las `.snap`, `actualizacion.json` (campos, sin rutas del usuario si se publican), salida de ambos guiones, `registros\migracion.log` (revisado), códigos de cada paso, versiones de `/api/salud`, resultado de `comprobar-servidor`.
- **Control negativo:** las filas centinela (el instrumento ve que las bases vuelven) y las versiones antes y después (B y A); sin esa diferencia no se concluye. La repetición de `Revertir` sobre la misma marca se rechaza (`ya está revertida`, verificado en RV-03).
- **Duración:** 60 min. **Marca:** [V] la secuencia por `Revertir-Actualizacion.ps1`; [I] el resultado en la VM.

### LAB-RV-02. Sin `-RestaurarBases`, solo explica; sin elevación, se niega

- **Pasos:** (a) `.\Revertir-Actualizacion.ps1` elevado, sin parámetros; (b) lo mismo sin elevar; (c) con `-Marca <x>` sin `-RestaurarBases`. `Snap` y huella de las bases (`RESTORE HEADERONLY` no; usar `SELECT modify_date FROM sys.databases`) antes y después.
- **Esperado:** (a) y (c): advertencia DM-01 y lista de marcas, "No se cambió nada…", salida 0, `Snap` idéntico, servicios sin cambio de estado. (b): "necesita PowerShell como administrador" **antes** de listar nada (`:42`).
- **Rechazo:** **Alta:** cualquier cambio de binarios, bases o servicios. **Media:** (b) lista o toca algo antes de negarse.
- **Control negativo:** el mismo comando con `-RestaurarBases` y la confirmación sí cambia (RV-01).
- **Evidencia:** salidas, `Snap`, `modify_date`. **Duración:** 10 min. **Marca:** [V] por `:41-61`.

### LAB-RV-03. Solo la última marca, y una marca ya revertida

- **Precondición:** `LAB-D2-G-A`; dos actualizaciones seguidas: PQ-A→PQ-B (marca M1) y PQ-B→PQ-C (marca M2), con servicios detenidos; fila centinela por cada una.
- **Pasos:** (1) `Revertir -Marca M1 -RestaurarBases` (no es la última). (2) `Revertir -Marca M2 -RestaurarBases` (RESTAURAR): correcto. (3) `Revertir -Marca M2 -RestaurarBases` otra vez. (4) `Revertir -Marca M1 -RestaurarBases` después de (2).
- **Esperado:** (1) "solo se puede revertir la última actualización (M2) … reinstale con Desinstalar-Demo.ps1 -EliminarBases e Instalar-Demo.ps1", **sin** `Detener-Demo` ni cambios; (2) restaura a PQ-B (binarios y bases); (3) "ya está revertida: los binarios de la copia previa ya son los del DEMO"; (4) rechazada igual que (1) (M1 sigue sin ser la última del listado). `Snap` sin cambios en (1), (3) y (4).
- **Rechazo:** **Alta:** (1) o (4) cambian algo; (2) restaura a PQ-A. **Media:** (3) vuelve a restaurar las bases.
- **Control negativo:** (2) funciona con la última.
- **Duración:** 40 min. **Marca:** [V] por `:62-70`; [I] el resto.

### LAB-RV-04. La copia previa tiene que ser la de esa actualización (R-01) y estar verificada (R-05)

Cada subcaso desde su punto. En los rechazos esperados: el guion termina con error **antes** de la confirmación y de `Detener-Demo`; las bases **no** se restauran (la fila `…-POST` sigue); los servicios mantienen su estado.

| ID | Cómo se llega | Esperado | Rechazo |
|---|---|---|---|
| RV-04a | **Actualización que no cambia binarios:** de PQ-B instalado, `Actualizar-Demo.ps1 -Paquete PQ-B2` (mismos binarios, otro guion). | `Actualizar` avisa "Esta actualización no cambió los binarios de los servicios: no hay copia previa nueva y Revertir no restaurará binarios"; `actualizacion.json` **sin** `HuellaCopiaPrevia`. `Revertir -Marca <última> -RestaurarBases` avisa "no anotó una copia previa …": restaura **bases y demás programas** y deja los binarios de servicios como estaban; después, base y binarios son coherentes (los de PQ-B) | Restaura binarios de PQ-A (la copia previa es de la actualización anterior): **Alta** (es R-01) |
| RV-04b | **`.anterior` cambiada por otra copia:** actualizar a PQ-B; luego, sin pasar por el guion, `--fase servicios --origen PQ-C` (otra copia previa). Revertir la marca de PQ-B. | Antes de nada: "La copia previa … no es la de la actualización …. No se cambió nada: reinstale …" | Continúa y restaura |
| RV-04c | **La fase falla antes de la copia previa:** actualizar con un PQ-B' que tiene un archivo con la huella del manifiesto alterada (la fase se detiene en la preparación, `.anterior` queda la de la actualización anterior) | `Actualizar` termina con error en el paso 4; la marca queda `respaldada`, sin `HuellaCopiaPrevia`. `Revertir` de esa marca: solo bases y demás programas; los binarios siguen siendo los de antes de la actualización fallida | Restaura binarios de otra versión: **Alta** |
| RV-04d | **Copia `no-verificada`:** como RS-04c, pero con `Actualizar-Demo.ps1` (alterar un byte del destino antes de actualizar) | `Revertir`: "La copia previa de los binarios no es de un paquete verificado … No se cambió nada" **antes** de tocar las bases | Restaura bases y luego se detiene en la fase (el caso exacto que R-05 quería evitar): **Alta** |
| RV-04e | **Primera actualización tras instalar la versión nueva de la fase** (destino instalado con una `--fase servicios` anterior a `manifiesto.instalado`): borrar `manifiesto.instalado.sha256` y actualizar | Igual que RV-04d: `no-verificada`; se rechaza sin tocar nada. Anotar el texto, que debe decir "reinstale" | Restaura |

- **Control negativo:** RV-01 (cuando todo coincide, restaura) y las filas centinela (en cada rechazo la `…-POST` **permanece**).
- **Duración:** 60 min. **Marca:** [V] por `Actualizar-Demo.ps1` (≈ `:149-163`) y `Revertir-Actualizacion.ps1:73-89`; [I] el resultado.

### LAB-RV-05. La fase se detiene a mitad: el guion no sigue ni inicia nada, y se puede repetir

- **Precondición:** `LAB-D2-G-A2B` (actualizado a PQ-B); `Bloquear-Archivo.ps1` sobre un archivo de `destino\api` que `restaurar` debe reescribir; servicios detenidos.
- **Pasos:** (1) `Revertir -Marca <última> -RestaurarBases`; RESTAURAR. (2) Anotar el final: mensaje, `Get-Service`, `actualizacion.json` (`Estado`), `instalacion.json` (`Paquete`), `Test-Path "$D\.aplicando"`, filas centinela. (3) Soltar el archivo y repetir el mismo comando con la misma marca. (4) Verificar el estado final.
- **Esperado:** (1)–(2): las bases **ya** restauradas (la fila `…-POST` ya no está); la fase termina con 4; el guion lanza "implantar-servidor --fase restaurar terminó con el código 4 … Las bases ya se restauraron pero los binarios de los servicios NO son los anteriores: no inicie el DEMO"; **no** ejecuta los pasos siguientes (ni `robocopy` de `app\*`, ni `Iniciar`); `Estado` **no** es `revertida`; `instalacion.json` sin cambiar; servicios detenidos; `.aplicando` presente. (3): vuelve a restaurar las bases (la misma copia), retoma la marca, termina 0, `Estado` = `revertida`, binarios = PQ-A, sin marca.
- **Rechazo:** **Alta:** el guion sigue tras el código 4, o marca `revertida`, o inicia los servicios; (3) no retoma o deja la marca. **Media:** la segunda vuelta pierde datos que no estaban en el respaldo y el guion no lo avisa (anotar: la segunda restauración reemplaza las bases otra vez).
- **Control negativo:** sin el bloqueo es RV-01.
- **Evidencia:** salidas de las dos vueltas, `Snap`, estado de `actualizacion.json` (solo `Estado`), códigos. **Duración:** 35 min. **Marca:** [V] por `:121-130`; [I] el comportamiento real.

### LAB-RV-06. Revertir, actualizar otra vez y revertir otra vez (P-D2-01)

- **Precondición:** `LAB-D2-G-A`; servicios detenidos.
- **Pasos:**
  1. `Actualizar-Demo.ps1 -Paquete PQ-B` (marca M1); anotar si dice "no cambió los binarios" (no debe). Fila `LAB-RV-06-POST1`.
  2. `Revertir -Marca M1 -RestaurarBases` (RV-01 paso 3). Verificar binarios = PQ-A.
  3. **`Actualizar-Demo.ps1 -Paquete PQ-B` otra vez** (marca M2). Anotar si imprime el aviso "Esta actualización no cambió los binarios de los servicios" **aunque los binarios sí cambiaron** (compararlos con `CompararManifiesto` contra PQ-B). Mirar si `actualizacion.json` de M2 trae `HuellaCopiaPrevia`. Fila `LAB-RV-06-POST2`.
  4. `Revertir -Marca M2 -RestaurarBases`.
  5. Después: `CompararManifiesto "$D" <PQ-A>`, versión de `/api/salud` tras `Iniciar-Demo.ps1`, fila `…-POST2` ausente.
- **Esperado (el correcto):** el paso 3 anota la huella y el paso 4 restaura **binarios y bases** a PQ-A; 0 distintos contra PQ-A.
- **Esperado según el código leído [V]:** el paso 3 imprime el aviso y no anota `HuellaCopiaPrevia`; el paso 4 dice "no anotó una copia previa" y restaura solo bases; los binarios quedan en PQ-B con las bases de PQ-A. Es la confirmación de P-D2-01.
- **Rechazo:** **Media** (propuesta; **Alta** si B y A consideran el ciclo uso normal del DEMO): binarios en una versión y bases en otra tras una reversión que el guion dio por buena; el aviso "no cambió" cuando sí cambió.
- **Control negativo:** el primer ciclo (pasos 1 y 2) funciona (RV-01); el fallo aparece solo en el segundo.
- **Evidencia:** la salida de `Actualizar` del paso 3 (el aviso literal), el contenido de `actualizacion.json` de M2 **sin valores** (¿está el campo?), `CompararManifiesto` antes y después del paso 4. **Duración:** 40 min. **Marca:** el defecto es [V] por lectura; el efecto, [I] hasta ejecutar.

### LAB-RV-07. Quién puede escribir lo que el guion elevado ejecuta (R-02, solo estado)

- **Pasos:** `icacls` de `app\migracion\GPOS.Migracion.exe`, de la carpeta de los guiones del DEMO y de `herramientas\Comun-Demo.ps1`; `Get-Acl … | Format-List Owner,Sddl`; y, como `gpos-lab-usuario` (sin elevar), solo comprobar con `icacls` si tiene permiso de **escritura** (sin escribir nada).
- **Esperado de partida [V según A]:** el usuario que instala tiene control total sobre esas rutas (`Comun-Demo.ps1:118-121`); el caso lo confirma o lo desmiente en el estado real de la VM y anota si `Get-EscritoresAjenos` (ya existente en `Actualizar-Demo.ps1`) las clasificaría como ajenas.
- **Rechazo:** hallazgo **Media** (R-02, abierto por A) si un usuario no elevado puede reemplazar lo que `Revertir` ejecuta como administrador. No se modifica ninguna.
- **Control negativo:** `Program Files\GPOS NG\Demo\api` (protegida) no admite escritura de ese usuario.
- **Duración:** 10 min. **Marca:** [V] por la revisión de A; [I] el estado de la VM.

## 7. Bloque EM: la empresa se crea por la interfaz como GSF con `dbcreator` (Nivel A) [?]

**Estado.** Decisión: la empresa se crea por la interfaz como GSF; la API necesita `dbcreator` (paso 3 de la escalera 2.2.2 del plan; paso 4 en los avisos), y no se toca el verbo ni el entorno del servicio (`acuse-decisiones-y-fase-restaurar-construida`). **No existe** todavía el paso del instalador (A lo escribe del 5 al 9-nov) ni el anillo (F1). Los casos están redactados contra lo que A y B han dicho y contra `EsquemaEmpresa.cs:216` y `PrivilegioMinimoSistema.cs`; todo valor es [I] hasta que exista el paso. **Hallazgo de diseño a vigilar (D-5):** una base creada con `CREATE DATABASE` por un login con `dbcreator` queda con ese login como **dueño**; `PrivilegioMinimoSistema.cs:151` lanza 51606 (RG-14) si el login de la API es dueño de la base, y el plan dice "las bases siguen con dueño `sa`".

**Precondición común.** PRE-5; cuentas ADMIN y GSF creadas (CU-01); servicios `Running`; Web iniciada; una base de empresa **no** creada aún. Punto de control `LAB-D2-ANILLO`.

### LAB-EM-01. GSF crea la empresa por la interfaz

- **Pasos:** (1) entrar a la Web como GSF (primer inicio: cambio de clave obligatorio); (2) Empresas > nueva: código `LAB1`, descripción "Empresa de laboratorio", nombre de base `GPOS_LAB1`; (3) esperar el resultado; (4) comprobar en SQL, como administrador de la VM: `SELECT name, collation_name, SUSER_SNAME(owner_sid) AS dueno, is_trustworthy_on, is_auto_close_on, state_desc FROM sys.databases WHERE name IN (N'GPOS_LAB1', N'GPOS_SYSDATA')`; `GPOS.Migracion.exe verificar` de la empresa (0 = al día); `SELECT Codigo, Descripcion, (CASE WHEN Conexion LIKE '%Server=%' OR Conexion LIKE '%Data Source=%' THEN 'TEXTO-PLANO' ELSE 'cifrada' END) FROM dbo.Empresas` en `GPOS_SYSDATA` (sin traer la conexión); (5) las tablas del esquema nuevo existen (`conf.__EFMigrationsHistory` con filas, esquemas `rpt`/`rptc`); (6) cerrar sesión y entrar como ADMIN: ve la empresa.
- **Esperado [I]:** la base existe, prefijo `GPOS_`, intercalación `SQL_Latin1_General_CP1_CI_AS`, `is_trustworthy_on = 0`, `AUTO_CLOSE OFF` (`OpcionesBase.cs`), esquema al día, la conexión **cifrada** (con el anillo del servicio); fila en `dbo.Empresas`; el **dueño** de la base: anotar (`sa` es lo previsto por el plan; el login de la API sería el hallazgo D-5); sin errores 51606 en los eventos.
- **Rechazo:** **Alta:** base creada con `is_trustworthy_on = 1`; conexión en texto plano; empresa registrada con la base inexistente o incompleta; error 51606 al operar. **Media:** dueño distinto de `sa` sin decisión (D-5); `AUTO_CLOSE` encendido.
- **Control negativo:** la misma operación con la sesión de **ADMIN** (EM-03) no crea nada; y la base `GPOS_SYSDATA` sigue sin cambios.
- **Evidencia:** captura de la fila de `sys.databases` (sin la conexión), `verificar`, códigos de la Web (de `registros\api.log`, revisado), eventos de la API. **Duración:** 40 min. **Marca:** [?]/[I].

### LAB-EM-02. Sin `dbcreator` falla cerrado y limpio (control negativo de EM-01)

- **Pasos:** el administrador de la VM quita el rol (`ALTER SERVER ROLE dbcreator DROP MEMBER [NT SERVICE\GPOS.Api]`); GSF intenta crear `LAB2` / `GPOS_LAB2`; revisar mensaje, base, fila y `registros\api-errores.log`; devolver el rol (`ADD MEMBER`) y repetir (debe funcionar).
- **Esperado:** error comprensible para la persona ("no se pudo crear la empresa …"), sin texto SQL ni cadena de conexión; **no** existe `GPOS_LAB2` ni fila en `dbo.Empresas`; los registros no contienen secretos; con el rol de vuelta, la creación funciona.
- **Rechazo:** **Alta:** una base o fila a medias; el servicio se cae. **Media:** el mensaje o el registro traen texto SQL con nombres internos de servidor, o la cadena de conexión.
- **Control:** la repetición con el rol es EM-01. Sin ese par no hay `Cumple`.
- **Duración:** 25 min. **Marca:** [?]/[I].

### LAB-EM-03. Quién puede crear empresas

- **Pasos:** intentar crear una empresa (a) sin sesión, (b) como USER y (c) como ADMIN de la empresa, por la Web (la opción debe estar oculta o rechazada) y, con `Invoke-WebRequest` y las credenciales tecleadas por el técnico en un `Get-Credential` (el token vive solo en una variable, **nunca se imprime ni se guarda**), por la API; (d) como GSF (SUPER): permitido.
- **Esperado:** (a) 401; (b) y (c) 403; (d) 200/201. Sin cambios en `sys.databases`.
- **Rechazo:** **Crítica:** ADMIN o USER crean una base (el rol `dbcreator` de la cuenta de servicio quedaría al alcance de cualquier autenticado: H-01/H-02 de la auditoría). **Alta:** respuesta 500 en vez de 403.
- **Control negativo:** (d) funciona.
- **Evidencia:** solo códigos HTTP y `sys.databases` antes y después; ningún token ni cabecera. **Duración:** 25 min. **Marca:** [I].

### LAB-EM-04. Duplicados, nombres inválidos y que no se pisa una base existente

- **Pasos:** (1) crear `LAB3`/`GPOS_LAB3` dos veces; (2) crear una empresa con código ya usado y base distinta; (3) con una base `GPOS_LAB4` creada a mano **con una tabla centinela**, crear la empresa `LAB4`/`GPOS_LAB4`; (4) nombres de base con espacios, mayúsculas, caracteres especiales, un corchete, vacío y de más de 128 caracteres; (5) un nombre sin el prefijo `GPOS_` (la convención del proyecto lo exige).
- **Esperado:** (1) y (2): rechazo claro y sin efecto; (3) rechazo y la tabla centinela **intacta** (`EsquemaEmpresa.cs:216` solo crea si no existe, pero aquí interesa qué ocurre después con las migraciones); (4) y (5): rechazados con mensaje, o aceptados solo si son válidos y entre comillas correctamente; ninguna sentencia SQL rota.
- **Rechazo:** **Alta:** la migración se aplica sobre una base ajena; un nombre inválido crea objetos con otro nombre; el servicio devuelve 500. **Media:** acepta un nombre sin prefijo `GPOS_`.
- **Control negativo:** (1) primera vez crea.
- **Duración:** 25 min. **Marca:** [I]; la creación condicional es [V] por `EsquemaEmpresa.cs:216`.

### LAB-EM-05. Atomicidad: la creación se interrumpe

- **Pasos:** crear `LAB5`/`GPOS_LAB5` y, a los 3 s, `Stop-Service GPOS.Api -Force` (repetir hasta 3 veces con otros tiempos); reiniciar el servicio y mirar: base, fila, estado al ingresar, lo que muestra la interfaz de empresas; repetir la creación.
- **Esperado [I]:** o queda **todo** (base completa y fila), o **nada** utilizable: una empresa sin fila no aparece y se puede volver a crear sobre el mismo nombre (o el sistema avisa de la base huérfana); nunca una fila que apunta a una base incompleta con un acceso engañoso.
- **Rechazo:** **Alta:** fila en `dbo.Empresas` con la base sin esquema o inexistente, accesible; la repetición falla de forma que bloquea el nombre sin explicación. **Media:** base huérfana sin aviso que impide crear la empresa.
- **Control negativo:** sin interrupción (EM-01).
- **Duración:** 30 min (mejor esfuerzo: la ventana es corta). **Marca:** [I].

### LAB-EM-06. La empresa nueva y la API de reportes

- **Pasos:** tras EM-01, pedir un reporte de la empresa nueva (reporte 1 y uno del diseñador) por la API de reportes y por la Web: ¿responde? Si no, ejecutar `implantar-servidor --perfil demo --fase lectura` (idempotente [I]) y repetir. Comprobar con SQL qué usuario de lectura tiene la base nueva (`SELECT name FROM GPOS_LAB1.sys.database_principals WHERE name LIKE 'gpos[_]%'`).
- **Esperado [I]:** la fase `lectura` corre al instalar, **antes** de que exista la empresa (`Instalar-Demo.ps1:157-166`), así que `crear-lectura --todas` no alcanzó a la empresa nueva: sin repetirla, el reporte falla **cerrado** (503/403, sin datos de otra empresa). Tras repetir `lectura`, 200 con datos.
- **Rechazo:** **Alta:** el reporte de la empresa nueva responde con datos de **otra** empresa; error 500 con la conexión del usuario de lectura. **Media:** la empresa nueva queda sin reportes y el sistema no lo dice (hay que documentar el paso de repetir `lectura` en la guía del DEMO).
- **Control negativo:** el reporte 1 de la empresa original (si existe) sigue 200 y no cambia.
- **Duración:** 25 min. **Marca:** [?]/[I] (**D-6**).

### LAB-EM-07. Techo de privilegios de la cuenta de la API tras crear empresas (DE-14 ampliado)

- **Pasos:** como administrador de la VM, sin tocar nada: `SELECT r.name FROM sys.server_role_members m JOIN sys.server_principals r ON r.principal_id = m.role_principal_id JOIN sys.server_principals p ON p.principal_id = m.member_principal_id WHERE p.name = N'NT SERVICE\GPOS.Api'`; `SELECT name, is_trustworthy_on FROM sys.databases WHERE name LIKE N'GPOS[_]%'`; y, con `EXECUTE AS LOGIN = N'NT SERVICE\GPOS.Api'` seguido de `REVERT`: `SELECT IS_SRVROLEMEMBER('sysadmin'), IS_SRVROLEMEMBER('securityadmin'), HAS_PERMS_BY_NAME(NULL, NULL, 'CONTROL SERVER'), HAS_PERMS_BY_NAME(N'GPOS_SYSDATA', 'DATABASE', 'CONTROL')`, `HAS_PERMS_BY_NAME(N'GPOS_LAB1','DATABASE','CONTROL')`. **No se ejecuta ningún `DROP`, `ALTER` ni `RESTORE`.**
- **Esperado:** roles de servidor = solo `dbcreator` (cuando el spike llegó al paso 3 de la escalera; `Probar-Spike-Amplio.ps1 -EscaleraConDbcreator`); ninguna base `GPOS_*` con `is_trustworthy_on = 1`; `sysadmin`, `securityadmin` y `CONTROL SERVER` en 0; sin `CONTROL` sobre `GPOS_SYSDATA`; el permiso sobre `GPOS_LAB1` es el que la escalera prevé (anotar si `CONTROL` por ser dueño: D-5).
- **Rechazo:** **Crítica:** `sysadmin`, `securityadmin`, `CONTROL SERVER`, `IMPERSONATE`, o `TRUSTWORTHY ON` en una base con el login como `db_owner` (escalada a `sysadmin`). **Alta:** cualquier otro rol de servidor; `CONTROL` sobre `GPOS_SYSDATA`.
- **Control negativo:** la misma consulta antes de crear la empresa (en `LAB-D2-ANILLO`): sin `dbcreator`, 0 roles (si A lo concede solo al crear empresas) o los que ya tuviera; la comparación muestra qué añade `dbcreator`.
- **Duración:** 20 min. **Marca:** [?]/[I].

## 8. Bloque CU: cuentas iniciales con el anillo del servicio (Nivel A) [?]

**Estado.** `sistema --cuentas-iniciales --confirmar-sellado` genera `Licencia.InstalacionId` y el padrón de sellos, y "deben verificar con el **mismo anillo** que usará el servicio" (A, `pr-d2-empresa-y-cuentas-bloqueo`). B firmó F1 el 2026-10-23 (`anillo --preparar --recuperacion <.cer>`, archivo `%ProgramData%\GPOS NG\config\GPOS.Api.anillo.json` que leen la API y `GPOS.Migracion` con el mismo código, guardas G-1 y G-2, evento 4729). Se construye del 26 al 30-oct; hasta entonces todo es [?]. El **plan de pruebas del anillo** (tarea 4, antes del 18-nov) cubrirá certificado, ACL, recuperación y rotación; **aquí solo** lo que toca a las cuentas iniciales. Claves iniciales: los centinelas de 2.1.

**Precondición común.** PRE-5 sin cuentas; `anillo --preparar --recuperacion <par desechable>` y `anillo --anclar --acta … --motivo …` ejecutados; servicios detenidos. Punto de control `LAB-D2-ANILLO`.

### LAB-CU-01. Crear ADMIN y GSF y que el **servicio** las acepte (mismo anillo)

- **Pasos:**
  1. Con las claves por el entorno del proceso (como `Instalar-Demo.ps1:211`), `GPOS.Migracion.exe sistema --cuentas-iniciales --confirmar-sellado --motivo "Laboratorio PR-D2"`; código y salida.
  2. SQL en `GPOS_SYSDATA`: `SELECT COUNT(*) FROM dbo.Usuarios`; `SELECT COUNT(*) FROM dbo.Usuarios WHERE SelloHabilitacion IS NULL`; que existen `ADMIN` y `GSF` (nombre y nivel, sin hashes de clave).
  3. Carpeta `%ProgramData%\GPOS NG\Licencia\padron`: existencia, nombres, tamaños y `icacls` (sin copiar el contenido).
  4. Iniciar los servicios (`Start-Service`); `GET /api/salud`; entrar por la Web como **GSF** con su clave inicial: la aplicación pide cambiarla; cambiarla y entrar. Igual con **ADMIN**.
  5. `GPOS.Migracion.exe anillo --comprobar` (código y situación) antes y después.
- **Esperado:** código 0; 2 usuarios, 0 sin sello; padrón presente y con DACL del vector de ADR-77; el servicio (cuenta virtual) **verifica** los sellos y deja entrar a las dos cuentas con cambio de clave obligatorio; ningún evento 4729 ni de falla del anillo; el anillo sigue en la situación `Anclada`.
- **Rechazo:** **Alta:** el servicio no acepta una cuenta creada por `GPOS.Migracion` (el anillo del técnico no es el del servicio: el defecto P-01); cuentas sin sello; carpeta del padrón con ACE de escritura para usuarios; evento 4729. **Media:** la clave no se obliga a cambiar.
- **Control negativo:** CU-02 y CU-03 (sin anillo o sin ancla no se crea nada); más el contraste con el anillo de DPAPI si A deja una variante provisional `DpapiDemo=true` (prohibida por decisión; si existe, se prueba **solo en un punto de control aparte** y se espera que el servicio **no** descifre).
- **Duración:** 40 min. **Marca:** [?].

### LAB-CU-02. G-1: servicio instalado y archivo del anillo ausente

- **Pasos:** renombrar `GPOS.Api.anillo.json` a otro nombre; ejecutar `sistema --cuentas-iniciales --confirmar-sellado …`; `SELECT COUNT(*) FROM dbo.Usuarios`; listar `Licencia\`; devolver el archivo.
- **Esperado:** salida 4 con el motivo; 0 cuentas; la carpeta de la licencia sin cambios; ningún `Licencia.InstalacionId` nuevo.
- **Rechazo:** **Alta:** crea cuentas o escribe la licencia sin el archivo (con el anillo equivocado, que el servicio no descifrará).
- **Control negativo:** CU-01 con el archivo.
- **Duración:** 10 min. **Marca:** [?] (blueprint §3.3, G-1).

### LAB-CU-03. G-2: sin ancla no se crea nada

- **Pasos:** desde un punto con el anillo preparado pero **sin** `anillo --anclar`; ejecutar `--cuentas-iniciales`.
- **Esperado:** salida 4, "ejecute `anillo --anclar --acta --motivo`"; 0 cuentas.
- **Rechazo:** **Alta:** crea cuentas. **Baja:** mensaje poco claro.
- **Control negativo:** con el ancla (CU-01).
- **Duración:** 10 min. **Marca:** [?].

### LAB-CU-04. Idempotencia y reglas de la clave inicial

- **Pasos:** (1) repetir `--cuentas-iniciales` con las cuentas ya creadas, pasando claves **cortas o distintas** en el entorno; (2) desde `LAB-D2-ANILLO`, claves de ADMIN de 7 caracteres y de GSF de 11 (mínimos 8 y 12).
- **Esperado:** (1) "ya existen; sin cambios", salida 0, no valida ni usa las claves, mismo número de usuarios y mismos sellos (sin re-sellado); (2) rechazo por largo, sin crear nada.
- **Rechazo:** **Alta:** (1) cambia una clave o un sello; (2) acepta una clave corta. **Media:** (2) crea una sola cuenta.
- **Control negativo:** (2) con claves válidas crea (CU-01).
- **Duración:** 15 min. **Marca:** [V] la regla (`Instalar-Demo.ps1:200-203`); [?] el resto.

### LAB-CU-05. Las claves iniciales no quedan en ningún lado

- **Precondición:** auditoría activada (PRE-6): creación de procesos con línea de comandos, registro de módulos y de bloques de script de PowerShell. Claves **centinela** únicas (cadenas buscables).
- **Pasos:** ejecutar CU-01 desde el punto limpio; después buscar cada centinela y contar coincidencias, **sin imprimirlas**: en los archivos de `C:\ProgramData\GPOS NG`, de la carpeta del DEMO (`registros`, `config`, `respaldos`), de `C:\GPOS-LAB\evidencia` y de las salidas guardadas (`Select-String -SimpleMatch -List | Measure-Object`); y en los registros de eventos `Security` (4688), `Application` y `Microsoft-Windows-PowerShell/Operational` (`Get-WinEvent | Where-Object Message -like "*$centinela*" | Measure-Object`).
- **Esperado:** 0 coincidencias en todos; la línea de comandos del proceso de `GPOS.Migracion` (4688) sin las claves.
- **Rechazo:** **Crítica:** una clave en un archivo, evento, línea de comandos o registro de PowerShell (ADR-44).
- **Control negativo (obligatorio):** poner un archivo y una línea de evento con otra cadena "canario" y comprobar que la búsqueda **los encuentra** (si no, la búsqueda no sirve y el caso no concluye).
- **Evidencia:** solo conteos por ubicación y el resultado del canario. **Duración:** 45 min. **Marca:** [I].

### LAB-CU-06. Manipulación del sello: falla cerrado

- **Pasos:** como administrador de la VM, con una copia previa de la fila: (a) cambiar `SelloHabilitacion` de `ADMIN` en la base; intentar entrar; restaurar la fila; (b) mover el archivo del padrón y reiniciar el servicio; entrar; devolverlo.
- **Esperado:** (a) la cuenta no entra; sin detalles que ayuden a adivinar; (b) falla cerrada con evento y sin que el servicio "repare" el padrón por su cuenta.
- **Rechazo:** **Alta:** entra con un sello alterado; el servicio regenera el padrón en silencio.
- **Control negativo:** sin manipulación entra (CU-01).
- **Duración:** 15 min. **Marca:** [I] (ADR-83; la validación ya está cubierta por el equipo de A, este caso es solo la comprobación en la VM).

## 9. Severidades y recomendación

**Severidades de laboratorio** (las de mis entregas de T1-b y T4-03, con lo propio de PR-D2):
- **Crítica:** una clave inicial o la clave JWT en un archivo, evento, línea de comandos o salida; un rol de servidor administrativo o `TRUSTWORTHY ON` con `db_owner` para la cuenta de la API; ADMIN o USER crean empresas; `restaurar` borra o escribe fuera de Archivos de programa a través de una unión.
- **Alta:** binarios y bases de versiones distintas tras una reversión dada por buena; "ok" con el destino mezclado o con la marca presente; el guion continúa o marca `revertida` tras un código ≠ 0 de la fase; `restaurar` actúa con un ejecutable en marcha; `MismoEntorno` falso tras `restaurar` (la clave JWT cambió); restaura una copia no verificada o con huella falsa; el servicio no puede leer lo restaurado; el servicio no acepta cuentas creadas por `GPOS.Migracion` (anillo distinto); fila de empresa con base incompleta.
- **Media:** el servicio arranca con la marca `.aplicando` (P-D2-02); el ciclo revertir→actualizar→revertir sin binarios (P-D2-01, subible a Alta); escritura a través de un vínculo dentro del subárbol (P-D2-04); mensajes con rutas o excepción; dueño de la base distinto de `sa` sin decisión; la empresa nueva sin reportes sin aviso; `Revertir` sin `comprobar-servidor` (P-D2-03, Baja); un caso `No se pudo` por entorno incompleto.
- **Baja:** textos, tiempos, avisos.

**Recomendación técnica** (la decisión es de B y del propietario): *Rechazado* si queda algún hallazgo Crítico o Alto; *Aprobado con observaciones* si solo hay Medios o Bajos o casos `Bloqueado`; *Aprobado* solo con todos los casos ejecutables en `Cumple` **y con sus controles**. Un `No se pudo` o `Bloqueado` nunca cuenta como `Cumple`.

**Qué queda `Bloqueado` o `No se pudo` por diseño y por qué:**

| Caso | Motivo |
|---|---|
| Todo el bloque RV | Instalador de servicios terminado (A, 5 al 9-nov) y F1 |
| RS-03 paso 3, RS-06 paso 3b, RS-09 paso 4 | Servicios en `Running`: necesitan el anillo (Nivel A) |
| EM-01 a EM-07 | Paso de empresa (A) y `dbcreator` concedido (D-5) |
| CU-01 a CU-06 | F1 (`anillo --preparar`, guardas G-1/G-2) |
| Edición de R-02 (solución de fondo) y R-04 (a) | No están en `cd44043c`: los casos registran el estado, no lo suponen cerrado |
| `restaurar` con `--perfil produccion` | No implementado por decisión |
| Reversión de más de una actualización | Un nivel por decisión (Q-R2) |

## 10. Lista de revisión de la evidencia de esta sesión

Se aplican **sin cambios** las secciones A a E de `tests/laboratorio-adr090/revision-evidencia.md`. Además, para PR-D2:

### F. Procedencia del montaje
- [ ] Hay un `preparar-vm-VM-SRV-*.json` con todo `cumple: true` del punto de control de la sesión.
- [ ] SHA-256 de **cada paquete** (PQ-A, PQ-B, PQ-B2, PQ-C) y de su `manifiesto.sha256`, y de `GPOS.Migracion.exe` de cada uno; coinciden con lo que B entregó. Commit de origen de los paquetes y confirmación de que no son de una rama posterior a la unión de T4-06 (restricción de B del 23-oct).
- [ ] Versiones de `GPOS.Api.exe` en PQ-A y PQ-B distintas y anotadas (RS-09, RV-01).
- [ ] Para el Nivel A: SHA-256 del `GPOS.Api.anillo.json` (no del contenido), huella del certificado del anillo y de la recuperación (las que `anillo --preparar` imprime para el acta), y de dónde sale el par desechable.
- [ ] El punto de control de cada caso es el que dice la sección 4 y, en RS-04 y RS-05, cada subcaso empieza de su propio punto.

### G. Controles (sin control no hay `Cumple`)
- [ ] RS-01: las comprobaciones previas muestran diferencias contra PQ-A; las posteriores, ninguna.
- [ ] RS-02: el control con un byte alterado muestra cambios.
- [ ] RS-03: el par "proceso vivo / proceso detenido" existe.
- [ ] RS-05: el `canario.txt` y `x.bin` tienen SHA-256 antes y después, y existe la prueba de que el SHA-256 detecta un cambio.
- [ ] RS-08: `--rotar-jwt` muestra `False` en `MismoEntorno` de la API y `True` en la de reportes.
- [ ] RV-01: las filas `…-PRE` y `…-POST` se ven en los estados esperados.
- [ ] CU-05: el canario fue encontrado por la búsqueda.
- [ ] EM-02: existe la repetición con el rol.

### H. Secretos y datos propios de este bloque
- [ ] Ninguna salida, `registros\migracion.log` ni `actualizacion.json` publicados traen una clave, una cadena de conexión (`Password=`, `User ID=`, `Server=` con credenciales) ni el valor de `HuellaCopiaPrevia` completo (basta decir "presente"). Si aparece cualquiera, la carpeta no se publica.
- [ ] `Environment` de ninguno de los dos servicios fue exportado ni impreso; solo `GetValueNames()` y los booleanos de `MismoEntorno`.
- [ ] Los token de EM-03 no están en ninguna parte; solo los códigos HTTP.
- [ ] Los `.snap` solo traen hash, fecha y ruta relativa del destino (sin contenido).
- [ ] Las claves iniciales usadas son las centinelas; la VM se restaura al terminar.
- [ ] La salida de `chkdsk` (RS-07) y los eventos no traen nombres de usuario reales.

### I. Horas y orden
- [ ] Las horas de los `.json` y de los eventos 5135 caen dentro de la ventana y en el orden de la sección 4.
- [ ] Los casos de severidad Crítica o Alta (RS-01, -03, -05e, -06, -07, -08, -09; RV-01, -04, -05, -06; EM-03, -07; CU-01, -05) se **recalculan a mano** desde lo observado.
- [ ] RS-07 está al final de S6 y CU-05 al final de S8 (dejan la VM sucia).

## 11. Dudas abiertas (D-x)

| ID | Pregunta | A quién |
|---|---|---|
| D-1 | **Paquetes PQ-A, PQ-B, PQ-B2, PQ-C (y los de 400 MB de relleno de RS-07):** ¿quién los construye y desde qué commit, dada la restricción de no publicar un DEMO de `feature/modelo-ng` desde T4-06? ¿Salen de `a/pr-d2-manifiesto`? Y la forma exacta de `Marca-Fila` (qué tabla y qué campos mínimos) | B |
| D-2 | RS-03 sin anillo: ¿`GPOS.Reportes.Api.exe` lanzado a mano se queda vivo sin SQL ni configuración? Si no, ese subcaso espera al Nivel A (con `GPOS.Api` o reportes en `Running`) | B / A |
| D-3 | La prueba de que **la clave JWT no cambió** sin leerla: ¿acepta el auditor el hash en memoria que solo imprime `True`/`False` (`GuardarEntorno`), o prefiere la prueba por sesión (RV-01 paso 10) o un tercer método? | A (auditor-seguridad) |
| D-4 | **P-D2-01** (revertir→actualizar→revertir): ¿lo confirma A y lo corrige antes del 16-nov? Propuesta: decidir por "la fase dijo que hizo copia previa" o por un identificador de copia, no por la huella del manifiesto. Y la severidad: Media o Alta | A |
| D-5 | **Empresa por la interfaz:** ¿quién concede `dbcreator` a `NT SERVICE\GPOS.Api` y cuándo (la fase `esquema` con una opción, el guion, a mano)? ¿Cómo evita el diseño que el login de la API quede **dueño** de la base nueva (RG-14, `PrivilegioMinimoSistema.cs:151`; el plan dice dueño `sa`)? Hoy el modo de servicios no usa `GPOS__EmpresaInicial__*` | A |
| D-6 | La fase `lectura` corre antes de que exista la empresa: ¿se espera repetirla tras crear la empresa por la interfaz, o la creación debe dejar la cuenta de lectura de esa empresa? (EM-06) | A / B |
| D-7 | RS-07: ¿acepta B el corte de energía con `VBoxManage controlvm poweroff` a los 2 s y el relleno de ≈ 400 MB (≈ 0,8 GB de disco extra en la VM)? Si no cabe, el caso queda con el bloqueo de archivo (RS-06) | B |
| D-8 | ¿R-04 (a) (los servicios se niegan a arrancar con `.aplicando`) y R-09 (`comprobar-servidor` en `Revertir`) se hacen antes de la VM? De eso depende el "esperado" de RS-06 paso 3b y de RV-01 paso 7 | A / B |
| D-9 | Las fechas: ¿Nivel V el 16-nov, Nivel G cuando A termine el instalador (5 al 9-nov) y Nivel A cuando F1 esté unida (antes del 5-nov)? ¿Hay tres ventanas de 5 a 6 h entre el 16 y el 27-nov, y quién teclea cada una? | B |
| D-10 | EM-03 por la API necesita credenciales y token en una variable de PowerShell. ¿Se acepta, o solo por la Web con los códigos HTTP leídos de `registros\api.log`? | A (auditor-seguridad) |
| D-11 | Las herramientas de PRE-6 (`Bloquear-Archivo.ps1`, la auditoría de CU-05, la búsqueda con canario): ¿las escribo yo (≈ 0,2 dp, sin poder probarlas aquí) o las deja B a un agente suyo? | B |

## 12. Qué no verifiqué

- **Nada se ejecutó**: ni `GPOS.Migracion`, ni los guiones, ni PowerShell contra la VM, ni SQL. Tampoco compilé. Todo lo [I] es lectura del código en `cd44043c` y conocimiento general de Windows y SQL Server, **no** comprobado: el comportamiento de `FileMode.Create` sobre un vínculo físico o una unión, que `GPOS.Reportes.Api.exe` viva como proceso suelto, la herencia de DACL de los archivos copiados, que `chkdsk` quede limpio tras un corte, que `HAS_PERMS_BY_NAME` bajo `EXECUTE AS LOGIN` funcione con una cuenta virtual, que `ALTER SERVER ROLE … DROP MEMBER` acepte `NT SERVICE\GPOS.Api`, la intercalación y las opciones de la base creada por la interfaz.
- **No leí** `Iniciar-Demo.ps1`, `Desinstalar-Demo.ps1`, `Comun-Demo.ps1` completos (solo `Detener-ServiciosDemo`, `Iniciar-ServiciosDemo`, `Invoke-Migracion*`), ni el endpoint de creación de empresas de la API (`AdminEndpoints.cs`) ni la interfaz que lo llama; los pasos de EM se deducen de `EsquemaEmpresa.cs:216`, del plan de A y de los avisos. No leí `comprobar-servidor` ni el valor exacto del evento de guarda (`DetenidoPorGuarda`).
- **El número de líneas** de `Actualizar-Demo.ps1` es aproximado (leí el diff de `cd44043c` y las líneas 40-145 del archivo).
- **No existen** todavía: el paso de empresa y cuentas de A, F1 (`anillo --preparar`, `GPOS.Api.anillo.json`, G-1, G-2), los cuatro paquetes de PRE-2 ni las herramientas de PRE-6.
- **No se prueban:** `Desinstalar-Demo.ps1` (no es de esta tarea), la rotación de la clave JWT por `Actualizar` (no existe: la actualización normal no rota), R-02 como ataque (solo el estado de las ACL; no se ejecuta ninguna sustitución), la recuperación y la rotación del anillo (tarea 4), ni el modo consola.
- **Duraciones y reparto en sesiones:** estimaciones mías, sin experiencia de ejecución en esta VM.

### Cierre
- Estado: Completado (casos redactados; ninguno ejecutado)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-23-casos-laboratorio-pr-d2.md`
- Supuestos: los de la sección 12; la sesión usa `VM-SRV` con `base`; los paquetes de PRE-2 los entrega B; el paso de empresa y cuentas se escribe como A y B lo describieron (creación por la interfaz como GSF con `dbcreator`; `sistema --cuentas-iniciales` con el anillo F1)
- Decisiones candidatas a ADR: Ninguna
- Entregas a otros agentes: A (desarrollador backend) → P-D2-01 (D-4), D-5, D-6, D-8, R-03 completa (P-D2-04); A (auditor-seguridad) → D-3, D-10, revisar RS-05 y CU-05 antes de dar `restaurar` por verificada; B → D-1, D-2, D-7, D-9, D-11 (paquetes, ventanas, herramientas)
- Próximo paso recomendado: A confirma o descarta P-D2-01 antes del 13-nov; B responde D-1 y D-9 para fijar las tres ventanas
