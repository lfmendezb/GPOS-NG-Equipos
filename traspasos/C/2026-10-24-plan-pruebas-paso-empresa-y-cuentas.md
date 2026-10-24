```
Para: B (copia para A, que escribe el paso del 5 al 9-nov)        De: C        Fecha: 2026-10-24
Tipo: Entrega (tanda 10, punto 6 de B-a-C/2026-10-24-tareas-nuevas-para-c-tanda-10.md): plan de pruebas del paso de empresa y cuentas, D-5 (c) firmada
Prioridad: Alta (A lo necesita antes del 5-nov; la VM, del 16 al 27-nov)
Repositorio y rama: GPOS-NG, solo lectura con `git show`: origin/a/pr-d2-manifiesto @ 812d1790, origin/b/f1-anillo @ e1c6f516, origin/feature/modelo-ng @ 1b310591
Estado: Abierto (plan sin código; nada compilado ni ejecutado)
```

# Plan de pruebas del paso de empresa y cuentas (D-5 (c)): `aprovisionar`, orden de `FaseEsquema` y casos LAB

**Método.** Leí con `git show` el aviso de B de la D-5 firmada, la hoja `b/hoja-firma-d5-pr-d2` (PR #230), mi contraste (`2026-10-24-contraste-adversarial-d5.md`: C-1 a C-7, AP-01 a AP-08), mi revisión de F1 (SF-03) y los bloques EM y CU de `2026-10-23-casos-laboratorio-pr-d2.md`. Contrasté con el código: `ComandoAprovisionar.cs`, `FaseEsquema.cs`, `FaseLectura.cs`, `ComandoImplantarServidor.cs`, `Instalar-Demo.ps1:126-167`, `EmpresasSistema.BasesAsync`, `GuardasAnillo.cs` y `Program.cs` de F1, y las pruebas de A (`Rg14Lote2Tests`, `Rg14Lote2bTests`, `ImplantarServidorTests`, `SistemaServidorFalso`). **No compilé, no ejecuté, no toqué checkouts.** `[V]` = visto en código (ruta y línea) · `[I]` = inferido, por confirmar en la ejecución · `[?]` = depende de algo que aún no existe (el paso de A, el verbo de registro, la corrección de B).

**Estados de un caso en la VM** (heredados): `Cumple` · `No cumple` · `No se pudo` · `Bloqueado`. `No se pudo` y `Bloqueado` nunca cuentan como `Cumple`. **Un caso sin su control negativo no puede dar `Cumple`.**

**Niveles** (los de mis planes; agrego Q porque el comando se prueba hoy así):

| Nivel | Qué es |
|---|---|
| U | Función pura o prueba textual (TX) sobre fuentes |
| F | Fase o verbo completo contra `SistemaServidorFalso` (sin servicios, registro ni SQL reales) |
| Q | SQL real en `GPOS.Tests` (bases `GPOS_TEST_*`, `GPOST_TEST_SERVER`), sin servicios de Windows. Es el nivel de `Rg14Lote2Tests` y `Rg14AprovisionarRealTests` |
| W | Windows real elevado, sin la VM completa (almacén de la máquina, `sc`, Visor de eventos) |
| V | `VM-SRV` de LFMB, con los puntos de control de la tanda 9 |

## 0. Resumen para decidir

1. **22 casos LAB (12 PE + 6 FE + 4 PC), 13 mutaciones y 11 requisitos de testabilidad.** Sustituyen a LAB-EM-01, -02 y -07 (los absorben AP-01 a AP-03). Los demás EM quedan así: EM-03 a EM-06 son de la Web en Amplio con `dbcreator`, y D-5 (c) los deja sin objeto en el DEMO de servicios (los reemplazan PE-10 y PE-11); EM-06, la empresa nueva y la API de reportes, la cubre PE-08. CU-01 a CU-06 siguen vigentes sin cambios: este plan solo les fija el orden.
2. **Hoy el paso de empresa no existe.** `Instalar-Demo.ps1:167` termina con el error de BORRADOR y `FaseEsquema` termina en `DM-03` sin crear nada ni registrar empresas (`FaseEsquema.cs:20-72`) [V]. Lo que sí está probado hoy es `aprovisionar` como función (Q): PA-40 (sin sysadmin), PA-38/39 (crea, repite, no rota) y la empresa pendiente que exige `--servidor` y `--base`. Por eso casi todo lo de abajo es plan para lo que A escribirá. Lo marco `[?]`.
3. **Cuatro hallazgos de lectura antes de la VM** (sección 2). Dos nuevos respecto de mi contraste:
   - **O-1 (nuevo, Media):** `aprovisionar` tiene G-1 pero **no tiene G-2**. Con el anillo preparado y sin ancla, crea la base, el dueño y la credencial en SQL, y falla al cifrar la cadena (`AnilloSinAncla`) dejando la empresa a medias. Es el mismo defecto de SF-03, en otro verbo.
   - **O-2 (nuevo, Media):** en una segunda ejecución, `--servidor` y `--base` **se ignoran en silencio** si la empresa ya tiene cadena (la rama solo existe en el `catch EmpresaPendienteException`). Quien repita el comando con otra base cree que la cambió.
4. **Duración [I, ±50 %]:** bloque PE ≈ 7,5 h, FE ≈ 2,5 h, PC ≈ 1,5 h: **≈ 11,5 h de VM** (una ventana larga o dos, dentro de S8). Las pruebas F/Q/U de la sección 8 se escriben en ≈ 2 dp [I].
5. **Si solo cabe un subconjunto:** PE-01, PE-02, PE-03, PE-05, PE-06, PE-10, FE-02, FE-01 (F, sin VM).

## 1. Fuentes y estado del código [V]

| Qué | Dónde | Estado |
|---|---|---|
| `aprovisionar` | `ComandoAprovisionar.cs` (a/pr-d2-manifiesto) | Construido. Pasos: sysadmin en la instancia de la empresa y en la de `GPOS_SYSDATA` (`:73-81`) → `Verificar`/`Crear`/`Actualizar` (`:84-96`) → dueño `SUSER_SNAME(0x01)` (`:99-112`) → `CredencialApp.AplicarAsync` (`:113`) → `crear-lectura` si hay `--llave` (`:116-124`) → S4 y lectura de la cadena guardada (`:125-130`). Salidas: `APROVISIONADA`, `AL_DIA`, `ERROR <código>`; código 0, 1 o 4 (S4). Evento 5140 de `GPOS.Migracion` |
| Empresa pendiente | `ComandoAprovisionar.cs:56-66`, `EmpresasSistema.BasesAsync` (`:84-87`: con `--empresa` lanza `EmpresaPendienteException`; con `--todas` las omite) | Construido. **Solo valida el prefijo `GPOS_`**, no compara con otras bases ni con la del sistema (C-3) |
| Verbo que registra la empresa «pendiente» | — | **No existe** (confirma el hueco [I] de B; C-2) |
| `FaseEsquema` | `FaseEsquema.cs:24-72` | Hoy: `sistema --login-api` → `actualizar --todas` → `anillo --comprobar`/`--anclar` → DM-03. No lleva `rpt`, ni `--cuentas-iniciales`, ni empresa |
| Orden firmado | Hoja D-5 | `servicios` → `anillo --preparar` → `esquema` (sistema, `--anclar`, cuentas y sellado) → empresa (`aprovisionar`) → `lectura` |
| Guardas del anillo | `GuardasAnillo.cs` (b/f1-anillo) | G-1 cubre `aprovisionar` salvo con `--llave-firma` (`UsaElAnillo`). G-2 solo se invoca en `sistema` con `--cuentas-iniciales` o `--confirmar-sellado` (`Program.cs:336`) |
| Instalador | `Instalar-Demo.ps1:106-107` (solo prueba la conexión SQL), `:126-167` | Sin comprobación previa de sysadmin (C-1) |
| Pruebas existentes | `Rg14Lote2Tests.PA40…`, `Rg14AprovisionarRealTests`, `Rg14Lote2bTests.Aprovisionar_una_empresa_pendiente_exige_servidor_y_base`, `ImplantarServidorTests.La_fase_esquema_*` | Citadas como `[E]` donde cubren algo |

## 2. Observaciones de lectura que condicionan los casos

| # | Sev. | Observación | Evidencia | Casos |
|---|---|---|---|---|
| O-1 | **Media** | `aprovisionar` no exige el ancla (no hay G-2). Si el anillo con certificado está preparado y sin ancla, la base se crea y el dueño se cambia, pero `GuardarConexion` pide una llave nueva y el cifrador se niega (`AnilloSinAncla`, `AnilloDataProtection.cs:126-127`). Queda base creada, posible credencial `gpos_app_*` sin guardar y empresa aún «pendiente». Con el orden firmado no ocurre (el ancla va en `esquema`), pero el técnico puede llamar `aprovisionar` suelto, y la guía lo pide [I] | `Program.cs:336` (G-2 solo en `sistema`); `ComandoAprovisionar.cs:84-113` | PE-07 |
| O-2 | **Media** | Con la empresa ya con cadena, `--servidor` y `--base` se ignoran sin aviso | `ComandoAprovisionar.cs:56-66` (la lectura de las opciones solo está dentro del `catch`) | PE-03, PE-05 |
| O-3 | Media (confirma A3 de mi contraste) | El camino pendiente acepta cualquier `GPOS_*`, incluida la base de otra empresa, y la API sí compara (`MotivoBaseNoPermitida`, `EmpresasService.cs:300-304`) | `ComandoAprovisionar.cs:61-62` | PE-05 |
| O-4 | Baja | Si el dueño era otro, `aprovisionar` responde `APROVISIONADA` (cambios = true) incluso con la base ya al día. No es un defecto, pero la prueba de idempotencia no puede exigir `AL_DIA` en ese caso | `ComandoAprovisionar.cs:105-111` | PE-04 |
| O-5 | Media | El paso de empresa necesita la empresa registrada antes, y `FaseEsquema` termina antes de que nadie la registre. Si el registro lo hace el propio paso, debe ir **entre** `esquema` y `aprovisionar`, y `actualizar --todas` de `esquema` la omite (correcto, sin base) | `EmpresasSistema.cs:84-87`; C-2, C-4 | PE-09, FE-05 |
| O-6 | Baja | `aprovisionar` no pasa por G-2 ni por «el servicio está parado»: puede correr con `GPOS.Api` en marcha. La API releería la cadena al cabo del `LoadBalanceTimeout` [I] | `GuardasAnillo.cs` | PE-06 |

## 3. Montaje, reglas y funciones de apoyo

**Reglas.** Las de 2.1 de `2026-10-23-casos-laboratorio-pr-d2.md` sin cambios (solo `VM-SRV`, puntos de control, nada se corrige a mano, ningún secreto, una corrida a la vez). Las claves de las cuentas iniciales son centinelas visibles (`Lab-Admin-Centinela-01`, `Lab-Gsf-Centinela-0001`). La prueba de que algo no cambió se hace con booleanos o con instantáneas de hashes, nunca con valores de entorno ni de cadenas.

**Precondiciones** (las fija B; se suman a PRE-1 a PRE-6 de ese documento):

| ID | Qué | Estado |
|---|---|---|
| PRE-E1 | **Tres identidades de instalación** en `VM-SRV`, todas administradores de Windows y **no** `sa` ni `gsf`: `lab-inst-sysadmin` (login SQL con `sysadmin`), `lab-inst-dbcreator` (login SQL con `dbcreator` y `securityadmin` solo si D-5 lo pide; **sin** `sysadmin`) y `lab-inst-sinlogin` (sin login en la instancia). Puntos de control `LAB-D2-E0` (servicios, anillo preparado y `esquema` hechos; **sin empresa**) y `LAB-D2-E1` (con la empresa `LABEMP` registrada y pendiente, `[?]`) | Por construir |
| PRE-E2 | **Segunda instancia SQL** (nombrada) para los casos de dos instancias de PE-02c (la de `GPOS_SYSDATA` distinta de la de la empresa). Si no cabe en RAM, PE-02c queda `No se pudo` y se cubre con Q (el doble por instancia) | Por decidir (D-3) |
| PRE-E3 | El **paso de empresa de A** (`[?]`) y el **verbo de registro** de C-2 (`[?]`). Mientras no existan, los casos PE-01 a PE-08 se ejecutan llamando `aprovisionar` a mano con el registro hecho por el técnico mediante una fila sembrada (solo en `LAB-D2-E1`); PE-09 y PE-10 quedan `Bloqueado` | Depende de A |
| PRE-E4 | **F1** aplicada con las correcciones SF-01 a SF-04 de B (aviso de su sha pendiente) | Depende de B |

**Funciones de apoyo** (PowerShell 5.1 elevado; escritas sin probar; usan `Invoke-Sqlcmd`-equivalente con la cuenta de Windows del administrador de la VM, nunca `sa`).

```powershell
$E = 'C:\GPOS-LAB\evidencia\EMPRESA'; New-Item -ItemType Directory -Force $E | Out-Null
function Q([string]$sql,[string]$bd='master'){ # una consulta con la cuenta de Windows del administrador de la VM
  $c = New-Object Data.SqlClient.SqlConnection "Server=.;Database=$bd;Integrated Security=true;Encrypt=false"; $c.Open()
  try { $m = $c.CreateCommand(); $m.CommandText = $sql; $t = New-Object Data.DataTable; $t.Load($m.ExecuteReader()); $t } finally { $c.Dispose() } }
function SnapInstancia([string]$id){ # logins, roles de servidor, bases (dueño, fechas), permisos de servidor del login de la API, hash de la fila de la empresa
  $s = @()
  $s += Q "SELECT name,type_desc,is_disabled FROM sys.server_principals WHERE name NOT LIKE '##%' ORDER BY name" | ForEach-Object { 'L|'+($_.ItemArray -join '|') }
  $s += Q "SELECT r.name,m.name FROM sys.server_role_members x JOIN sys.server_principals r ON r.principal_id=x.role_principal_id JOIN sys.server_principals m ON m.principal_id=x.member_principal_id ORDER BY 1,2" | ForEach-Object { 'R|'+($_.ItemArray -join '|') }
  $s += Q "SELECT name,CONVERT(varchar(80),owner_sid,1),create_date,is_trustworthy_on FROM sys.databases WHERE name LIKE 'GPOS[_]%' ORDER BY name" | ForEach-Object { 'B|'+($_.ItemArray -join '|') }
  $s += Q "SELECT Codigo,Inhabilitado,CASE WHEN ConexionCifrada='' THEN 'pendiente' ELSE 'con-cadena' END,CONVERT(varchar(64),HASHBYTES('SHA2_256',ConexionCifrada),2) FROM GPOS_SYSDATA.dbo.Empresas ORDER BY 1" | ForEach-Object { 'E|'+($_.ItemArray -join '|') }
  $s | Set-Content "$E\$id.snap" }                                   # el hash de la cadena cifrada no revela la cadena
function SnapEquipo([string]$id){ # servicios (sc qc/sdshow), %ProgramData%\GPOS NG (ACL + hash de cada archivo), orígenes de eventos
  & $PSScriptRoot\FotoServicios.ps1 $id                              # la FotoServicios de 2.3 del documento de PR-D2 (sin Environment)
  Get-ChildItem "$env:ProgramData\GPOS NG" -Recurse -File -Force -EA SilentlyContinue | ForEach-Object { '{0}|{1}' -f (Get-FileHash $_.FullName).Hash,$_.FullName.Substring(24) } | Sort-Object | Set-Content "$E\$id.pd" }
function EsDuenoSa([string]$bd){ [bool](Q "SELECT 1 FROM sys.databases WHERE name=N'$bd' AND owner_sid=0x01") }
function EsContenida([string]$cadenaGuardadaUser){ $cadenaGuardadaUser -like 'gpos_app_*' }   # el usuario de la cadena guardada: se obtiene con la API de pruebas, no con el valor cifrado
function EventosE([datetime]$desde){ Get-WinEvent -FilterHashtable @{LogName='Application';ProviderName='GPOS.Migracion','GPOS.Instalacion';StartTime=$desde} -EA SilentlyContinue | Select-Object Id,LevelDisplayName,TimeCreated,Message }
```

Plantilla de evidencia: `$E\<ID>.json` con `{ id, resultado, inicio, fin, punto_de_control, observado, hallazgos[] }`, igual que en PR-D2. Para decir si la cadena guardada usa la credencial contenida sin leer la cadena, B debe ofrecer una **sonda de pruebas** (RT-6, sección 8); mientras no exista, el caso lo mide con una conexión de prueba hecha por la propia API de laboratorio (la API abre la empresa o no).

## 4. Bloque PE: `aprovisionar` en el paso de empresa

Ejecutable base: `GPOS.Migracion.exe aprovisionar --empresa LABEMP --servidor <instancia> --base GPOS_LABEMP [--llave <ruta>]`. La línea de salida es una sola (`APROVISIONADA`, `AL_DIA` o `ERROR <código>`); el detalle va al Visor, origen `GPOS.Migracion`, id 5140 [V, `:134`]. Todos parten de `LAB-D2-E1` salvo que se diga otra cosa.

### LAB-PE-01. Camino feliz con el sysadmin del instalador

- **Precondición:** `LAB-D2-E1`, sesión de `lab-inst-sysadmin`. `SnapInstancia 'PE01-antes'`, `SnapEquipo 'PE01-antes'`. La empresa `LABEMP` está pendiente; `GPOS_LABEMP` no existe (control: `Q "SELECT COUNT(*) FROM sys.databases WHERE name='GPOS_LABEMP'"` = 0).
- **Pasos:**
  1. `$desde=Get-Date`; ejecutar `aprovisionar` con `--llave config\llave-sitio.pub` (modo «en un paso», C-4) y sin `--sitio`. Anotar línea y código.
  2. `SnapInstancia 'PE01-despues'`; `EsDuenoSa 'GPOS_LABEMP'`; `IS_SRVROLEMEMBER('dbcreator', <login de la API>)`; `SELECT is_trustworthy_on, containment_desc, collation_name FROM sys.databases`.
  3. Que la API de laboratorio abra la empresa (`Start-Service GPOS.Api` y `GET` de una ruta de la empresa con el token de ADMIN; **o** `anillo --comprobar` y la sonda RT-6 si el servicio aún no arranca).
  4. `GPOS.Migracion verificar --estricto --empresa LABEMP` (S4).
  5. `EventosE $desde`; buscar en la salida y en el Visor el centinela de la clave de `lab-inst-sysadmin` y cualquier subcadena `Password=`/`Pwd=` (debe dar 0 coincidencias).
- **Esperado:**
  - Línea `APROVISIONADA`, código 0.
  - `GPOS_LABEMP` existe, **dueño `0x01`** (AP-02), nivel de compatibilidad y intercalación `SQL_Latin1_General_CP1_CI_AS`, `TRUSTWORTHY OFF`.
  - La fila de la empresa pasa de `pendiente` a `con-cadena`; el hash de la cadena cambia.
  - La cadena guardada usa el usuario `gpos_app_*` contenido, **no** integrada (AP-02); existe el usuario `gpos_rpt*` si se dio `--llave` (AP-05).
  - El login de la API sigue **sin** roles de servidor ni `CREATE ANY DATABASE` (AP-01); la API abre la empresa con el anillo del servicio (C-7).
  - `verificar --estricto` da 0 hallazgos.
  - Un evento 5140 de nivel Información, sin cadena, sin clave, sin la clave del instalador.
- **Rechazo:** **Alta:** dueño distinto de `0x01`; cadena integrada guardada; login de la API con un rol de servidor tras el paso; la API no abre la empresa; secreto en la salida o el Visor (**Crítica** si es la clave de la cadena). **Media:** `verificar` con hallazgos; falta el 5140.
- **Evidencia:** las dos instantáneas, línea y código, eventos (ids y niveles, no el texto completo si lleva rutas de usuario), resultado de `EsDuenoSa`, conteos. Sin valores de cadena.
- **Control negativo:** la misma medición sobre `GPOS_LABEMP` creada a mano con `CREATE DATABASE` por el administrador (dueño ≠ `0x01`, sin usuarios contenidos) da `EsDuenoSa = False` y `La API no abre`: el instrumento ve la diferencia.
- **Duración:** 40 min. **Marca:** [V] la lógica (`ComandoAprovisionar.cs:84-130`); [I] el resultado en Windows; `[?]` los pasos 1 con `--llave` en un solo comando (C-4).

### LAB-PE-02. Sin sysadmin: mensaje claro y sin cambios (C-1, AP-03)

Tres subcasos. En los tres, `SnapInstancia`/`SnapEquipo` antes y después deben ser **idénticas** (excepto líneas de reloj del Visor).

| ID | Quién | Esperado | Rechazo |
|---|---|---|---|
| PE-02a | `lab-inst-dbcreator`: puede crear bases pero no es sysadmin | `ERROR REGLA`, código 1, mensaje «aprovisionar lo ejecuta un técnico con un inicio de sesión sysadmin nominal … no se cambió nada»; no existe `GPOS_LABEMP`; la fila sigue `pendiente` | **Alta:** la base nace (`dbcreator` bastaría para crearla y dejarla con dueño ajeno); dos líneas de salida |
| PE-02b | `lab-inst-sinlogin`: sin login en la instancia | Fallo de conexión limpio (línea `ERROR 18456` o similar), sin texto de excepción ni cadena; sin cambios | **Media:** excepción cruda, cadena de conexión en la salida |
| PE-02c | `lab-inst-sysadmin` en la instancia de la empresa, **sin** sysadmin en la instancia de `GPOS_SYSDATA` (PRE-E2) | Se detiene antes de crear la base («en la instancia de GPOS_SYSDATA»), sin cambios en ninguna de las dos | **Alta:** crea la base y luego falla al guardar la cadena (el caso por el que el código mira ambas instancias, RG2-03) |

- **Instalador (C-1, `[?]`):** PE-02d. Repetir PE-02a con `Instalar-Demo.ps1` completo desde el punto `base`, sin ser sysadmin: **debe detenerse antes de 1b** con el mismo mensaje, sin servicios, sin `%ProgramData%\GPOS NG`, sin bases. Hoy (`Instalar-Demo.ps1:106-107`) solo prueba la conexión: el caso da `No cumple` hasta que A añada la comprobación previa. `Bloqueado` si A no la hace; es la condición C-1.
- **Control negativo:** PE-01 con `lab-inst-sysadmin` (la base nace). Sin ese par, el caso no concluye. Y el mensaje de PE-02a **no** debe aparecer con `lab-inst-sysadmin`.
- **Evidencia:** línea y código de cada subcaso, las dos instantáneas y su `Compare-Object` (vacío), el 5140 de nivel Error.
- **Duración:** 50 min. **Marca:** [V] PA-40 prueba lo mismo con el doble `[E]` (`Rg14Lote2Tests.cs:332`); [I] 02b, 02c y la parte de instalador.

### LAB-PE-03. La empresa ya existe: idempotencia

- **Precondición:** a continuación de PE-01 (`SnapInstancia 'PE03-antes'`); una **fila centinela** inventada en una tabla de la empresa (`Marca-Fila`, como en RV) con su hash.
- **Pasos:**
  1. Repetir el comando de PE-01 **idéntico** → anotar.
  2. Repetirlo con otro `--base GPOS_OTRA` (inexistente) → anotar (O-2).
  3. Repetirlo sin `--servidor` ni `--base` → anotar.
  4. Con la API **en marcha** (O-6), repetir una vez y comprobar que la API sigue sirviendo (`GET` autenticado) antes y después.
  5. `SnapInstancia 'PE03-despues'`; hash de la fila centinela; `__EFMigrationsHistory` (conteo).
- **Esperado:**
  - Pasos 1 y 3: `AL_DIA`, código 0; la cadena **no cambia** (mismo hash: no rotó, PA-39); la fila centinela igual; `GPOS_OTRA` no existe.
  - Paso 2 (**O-2**): hoy [I] `AL_DIA` ignorando `--base`. **Cumple** si rechaza («la empresa ya tiene base: `GPOS_LABEMP`, no se cambia»); **Aviso (Media)** si responde `AL_DIA` sin decir que ignoró la opción. Nunca debe crear `GPOS_OTRA`.
  - Paso 4: la API sigue respondiendo; sin 401 ni 5xx (la cadena no rotó).
  - Una sola fila en `Empresas` por código; nada se duplica.
- **Rechazo:** **Alta:** la cadena cambia (rotó); `GPOS_OTRA` creada; la fila centinela pierde datos; la API pierde la conexión. **Media:** `APROVISIONADA` en una segunda pasada sin cambios reales.
- **Control negativo:** quitar a mano el usuario contenido `gpos_app_*` (administrador) y repetir: ahora sí `APROVISIONADA` y la cadena cambia (el instrumento ve la rotación). Después, otra pasada: `AL_DIA`.
- **Evidencia:** las instantáneas, la salida de los cuatro pasos, hash de la fila, estado de la API. **Duración:** 35 min. **Marca:** [V] PA-39 en `Rg14AprovisionarRealTests` `[E]`; [I] pasos 2 a 4.

### LAB-PE-04. Dueño distinto de `sa`: lo corrige

- **Variantes** (cada una desde `LAB-D2-E1`, con la base creada a mano por el administrador y esquema actualizado salvo que se diga):

| ID | Preparación | Esperado |
|---|---|---|
| PE-04a | `GPOS_LABEMP` ya existe, **dueño = el administrador de la VM** (no `0x01`), esquema al día | Responde `APROVISIONADA` (O-4), línea «Dueño de la base: sa (D-03)», dueño `0x01` al final |
| PE-04b | Igual, pero con el esquema **atrasado** (una migración sin aplicar) | `actualizar` y dueño corregido; sin 51604 ni 51606 |
| PE-04c | **`sa` renombrado** en la VM (`ALTER LOGIN sa WITH NAME = [lab-sa]`) y dueño ajeno | El dueño queda `0x01` (el SID, no el nombre: `SUSER_SNAME(0x01)`, `ComandoAprovisionar.cs:100-101`); no se pide `sa` |
| PE-04d | Dueño = el login de la API (`ALTER AUTHORIZATION … TO [NT SERVICE\GPOS.Api]`), el caso de la deriva A2 | Dueño `0x01`, y la API sigue operando después con `gpos_sistema`, no como dbo; S4 sin hallazgo. Si falla con 51606, **se anota la línea y el código**: es información para A (D-4) |

- **Rechazo:** **Alta:** queda cualquier dueño ≠ `0x01` con respuesta `APROVISIONADA` o `AL_DIA`; el login de la API conserva ser dbo (anula los DENY). **Media:** exige `sa` por nombre en la VM con `sa` renombrado.
- **Control negativo:** PE-01 (la base nace con dueño `0x01` sin corrección: la línea «Dueño de la base: sa» **no** debe aparecer). Y sin sysadmin (PE-02a) el dueño no cambia.
- **Evidencia:** `SUSER_SNAME(owner_sid)` y `CONVERT(varchar, owner_sid, 1)` antes y después, salida, S4. **Duración:** 60 min (4 subcasos). **Marca:** [V] el código del dueño (`ComandoAprovisionar.cs:99-112`); [I] 04b a 04d.

### LAB-PE-05. Base equivocada o nombre inválido (A3, C-3, AP-04)

Cada subcaso desde `LAB-D2-E1`, con **otra empresa `LABOTRA`** ya aprovisionada (su base `GPOS_LABOTRA` con una fila centinela) y `SnapInstancia` antes y después **idénticas** donde se espera rechazo.

| ID | Comando | Esperado | Rechazo |
|---|---|---|---|
| PE-05a | `aprovisionar --empresa LABEMP --base GPOS_LABOTRA` | Rechazo: «la base de la empresa LABOTRA»; sin cambios; `LABEMP` sigue pendiente; la cadena de `LABOTRA` igual | **Alta** (fuga entre empresas): `LABEMP` recibe la base de `LABOTRA` y su credencial |
| PE-05b | `--base GPOS_SYSDATA` y, con la base del sistema renombrada a `GPOS_SYS_LAB`, `--base GPOS_SYS_LAB` | Rechazo; sin cambios | **Alta:** la empresa apunta a la base del sistema |
| PE-05c | `--base BASE_SIN_PREFIJO`, `--base 'GPOS_X; DROP DATABASE GPOS_SYSDATA'`, `--base 'GPOS_X]'`, `--base GPOS_` | Rechazo por prefijo o por nombre inválido; sin cambios; sin SQL ejecutado con el texto | **Alta:** se ejecuta o se cita mal. **Media:** acepta `GPOS_` solo |
| PE-05d | `--base gpos_labotra` (otro caso de letras) y `--servidor` con el nombre del equipo, `.` o `(local)` para la misma instancia | La comparación es insensible a mayúsculas: rechazo igual que 05a; las tres formas de la instancia no eluden la comparación | **Alta:** una forma de escribir el servidor o la base elude C-3 |
| PE-05e | `--servidor` de otra máquina inexistente | Fallo de conexión limpio dentro de un plazo razonable (≤ 30 s); sin cambios; sin `TrustServerCertificate` implícito (P39-01: solo local) | **Media:** cuelga; confía en un certificado remoto |

- **Hoy** [V]: 05a y 05b no se rechazan (`ComandoAprovisionar.cs:61-62` solo mira el prefijo): se espera `No cumple` **Alta** hasta que C-3 esté. Es el primer caso rojo del bloque y lo dice el plan de entrada.
- **Control negativo:** el control de instrumento: el hash de la fila centinela de `LABOTRA` y la cadena guardada (hash) se miden antes y después; una modificación manual de un byte se ve (la prueba detecta). PE-01 con una base nueva propia sí funciona.
- **Evidencia:** línea y código de cada subcaso; las dos instantáneas; hash de la cadena de `LABOTRA`. **Duración:** 50 min. **Marca:** [V] la falta de comparación (`Aprovisionamiento.cs:464-467`, `ComandoAprovisionar.cs:61`); [I] 05d y 05e.

### LAB-PE-06. Corte a mitad y reintento (AP-07, C-7)

- **Precondición:** `LAB-D2-E1`; Q para marcar el punto de corte: B pone un punto de pausa de laboratorio **o** se corta por el reloj (D-5: el comando tarda 5 a 15 s [I]).
- **Pasos:** tres cortes distintos (cada uno desde `LAB-D2-E1`):
  1. **Después de `CREATE DATABASE`**, antes del dueño: `VBoxManage controlvm VM-SRV poweroff` cuando `GPOS_LABEMP` aparezca.
  2. **Después de la credencial** (`gpos_app_*` creado) y antes de guardar la cadena (el hueco más delicado).
  3. **Después de guardar la cadena**, antes de S4.
  Tras arrancar la VM, sin tocar nada: `SnapInstancia`; repetir `aprovisionar` **idéntico**; `SnapInstancia`; `anillo --comprobar`; API abre la empresa.
- **Esperado:** cada reanudación termina `APROVISIONADA` o `AL_DIA`, sin rotar dos veces la credencial (PA-39): la cadena final contiene **una** credencial vigente y no quedan dos generaciones con `CONNECT` (S4 sin `GPOS_APP_SESION_*` ni credenciales huérfanas); dueño `0x01`; la API abre la empresa con el anillo del servicio; `anillo --comprobar` da 0.
- **Rechazo:** **Alta:** la segunda pasada deja la empresa ilegible para la API (anillo equivocado, C-7) o con dos credenciales activas; la base queda con un dueño ajeno y respuesta `AL_DIA`. **Media:** el paso 2 deja un usuario `gpos_app_*` huérfano que S4 no informa.
- **Control negativo:** la misma operación sin corte (PE-01) termina en una pasada.
- **Evidencia:** las tres instantáneas intermedias, S4, el estado de la API, `anillo --comprobar`. **Duración:** 60 min (3 cortes con punto de control). **Marca:** [I] todo; la lógica de reanudación es [V] por lectura (`:84-96`).

### LAB-PE-07. El anillo del servicio: el orden, el ancla y G-1 (O-1, C-7)

| ID | Preparación | Esperado | Rechazo |
|---|---|---|---|
| PE-07a | Servicio `GPOS.Api` instalado y **sin** `GPOS.Api.anillo.json` (se renombra) | G-1: salida 4, «el servicio GPOS.Api está instalado y falta el archivo del anillo … No se cambió nada»; sin base, sin cambios (instantáneas idénticas) | **Alta:** escribe una cadena con el anillo de DPAPI del técnico |
| PE-07b | Anillo **preparado**, **sin ancla** (`LAB-D2-E0` antes de `--anclar`) | Se rechaza **antes** de crear la base: «ancla no está en regla (SinAncla) … ejecute antes anillo --anclar» y sin cambios | **Media (O-1):** crea la base y falla después (`AnilloSinAncla`), dejando la empresa a medias. Hoy [I] `No cumple` |
| PE-07c | Anillo con ancla; `aprovisionar` por el administrador **elevado** y no por el usuario del servicio | La cadena la lee y descifra la API con **su** anillo; si la privada del anillo no abre para este administrador (C-7), `ERROR` **antes** de crear nada | **Alta:** `aprovisionar` lo hace todo y termina en ERROR al final, o cifra con otro anillo y la API no lo descifra |
| PE-07d | `anillo --comprobar` después de PE-01 | 0; `Licencia.InstalacionId` verifica con el anillo del servicio | **Alta:** 1 o 2 sin motivo; la fila escrita con DPAPI del técnico (SF-02) |

- **Control negativo:** PE-01 con el anillo bien (ancla en regla, archivo presente). Para 07b, `anillo --anclar` y repetir: ahora crea.
- **Evidencia:** salidas, códigos, instantáneas, `anillo --comprobar`. **Duración:** 45 min. **Marca:** [V] el código de G-1 y la ausencia de G-2 en `aprovisionar` (`Program.cs:336`); [I] el efecto; `[?]` 07c depende de cómo abra la privada el administrador (ACL de la llave de F1, W-AN-02).

### LAB-PE-08. `lectura` después de la empresa; la omisión silenciosa (AP-05, C-4)

- **Precondición:** `LAB-D2-E0` (esquema hecho) y la empresa **pendiente**.
- **Pasos:**
  1. Ejecutar `implantar-servidor --fase lectura` **antes** del paso de empresa y anotar el código y qué dice de la empresa pendiente. Contar los usuarios `gpos_rpt*` de `GPOS_SYSDATA` (el de sistema sí) y los de la empresa.
  2. Ejecutar el paso de empresa y luego `lectura`.
  3. Pedir un reporte de `LABEMP` a la API de reportes (puerto 5073) con un token de laboratorio.
  4. Variante `aprovisionar --llave`: restaurar `LAB-D2-E1` y hacerlo en un solo paso; luego `lectura` (idempotente).
- **Esperado:**
  - Paso 1: **no** puede terminar en 0 diciendo que la empresa tiene lectura: `crear-lectura --todas` omite las pendientes (`EmpresasSistema.cs:84-87`) y hoy `FaseLectura` termina de todos modos en 1 «Fase incompleta … falta red», por lo que **la omisión queda oculta tras un mensaje que ya se tolera** (el instalador acepta ese 1, `Instalar-Demo.ps1:160`). Esperado: la salida dice «empresa LABEMP pendiente: sin lectura», o la fase se detiene con 4 si hay pendientes. Hoy [I] `No cumple` **Media**.
  - Paso 2 y 4: usuario `gpos_rpt*` en la base de la empresa; reporte → 200.
  - La variante 4 y el paso 2 dejan el mismo estado final.
- **Rechazo:** **Alta:** el reporte de `LABEMP` devuelve 200 sin usuario de lectura (otra credencial); **Media:** la fase 0/1 sin mencionar las empresas omitidas.
- **Control negativo:** el paso 1 mide cuántas empresas quedaron sin lectura; el paso 2 las deja en 0.
- **Evidencia:** salida de cada paso, conteos de usuarios `gpos_rpt*`, código HTTP. **Duración:** 40 min. **Marca:** [V] la omisión; [I] el resto.

### LAB-PE-09. El registro «pendiente» (C-2) `[?]`

- **Precondición:** el verbo de registro de A. `Bloqueado` mientras no exista.
- **Pasos:** el verbo (a) registra `LABEMP` con servidor y base, (b) rechaza un código repetido, (c) rechaza una base de otra empresa o la del sistema (misma comparación que C-3), (d) deja una fila de auditoría (quién, cuándo, qué), (e) no crea ninguna base, (f) no exige sysadmin si solo escribe en `GPOS_SYSDATA`.
- **Esperado:** la fila nace `pendiente` (`ConexionCifrada = ''`); `actualizar --todas` y `crear-lectura --todas` la omiten; la API la muestra «Pendiente de aprovisionar» (D-04 i) `[E]` (`Rg14Lote2bTests.cs:99`).
- **Rechazo:** **Alta:** un `INSERT` directo desde PowerShell sin las validaciones (C-2); registra una base ajena; sin auditoría. **Media:** mensaje confuso.
- **Control negativo:** el mismo verbo con un código nuevo y base propia funciona.
- **Duración:** 30 min. **Marca:** `[?]`.

### LAB-PE-10. La API no tiene `dbcreator` y la Web lo gestiona (AP-01, AP-06, C-5)

- **Precondición:** DEMO de servicios en Amplio, todo hecho (PE-01), servicios `Running`, token de SUPER.
- **Pasos:**
  1. AP-01: `IS_SRVROLEMEMBER('dbcreator', <login>)`, roles de servidor del login, `HAS_PERMS_BY_NAME(NULL,'SERVER','CREATE ANY DATABASE')` ejecutado como el login (S5 `Servidor = 0` en el tablero).
  2. AP-06: desde la Web (o `POST /empresas`) registrar una segunda empresa `LABDOS`; luego `POST /empresas/LABDOS/esquema`.
  3. **Control negativo de AP-01:** conceder `dbcreator` (administrador), comprobar S5 = 1 y `verificar --estricto` con hallazgo (C-5); retirarlo y repetir.
- **Esperado:**
  - Paso 1: 0, 0 y 0; S5 = 0.
  - Paso 2: `LABDOS` queda «Pendiente de aprovisionar»; `/esquema` responde **409** con el texto de `aprovisionar`, no 500 ni el error 262; **no se crea** ninguna base.
  - Control: S5 pasa a 1 y `verificar --estricto` da hallazgo. Hoy S4 solo mira `sysadmin` (`VerificacionPrivilegios.cs:294-296`): el hallazgo exige C-5.
- **Rechazo:** **Alta:** la API tiene `dbcreator` o `CREATE ANY DATABASE`; se crea la base de `LABDOS`. **Media:** 500 o texto crudo (262) en el paso 2; el control no se ve en `verificar --estricto`.
- **Evidencia:** consultas de rol, código y cuerpo de la respuesta (sin token), conteo de bases, S5. **Duración:** 35 min. **Marca:** [V] `AdminEndpoints.cs:352-353` (`CREATE DATABASE` desde la API); [I] el resto; sustituye a EM-01, EM-02 y EM-07.

### LAB-PE-11. Ninguna clave en ningún lado (secretos del paso)

- **Pasos:** tras PE-01, PE-03 y PE-06: (a) buscar en el Visor (`Application`, origen `GPOS.Migracion` y `GPOS.Instalacion`) los centinelas y `Password=`, `Pwd=`, `User ID=`; (b) revisar `registros\migracion.log` y la salida; (c) auditoría de procesos con línea de comandos (como CU-05): `aprovisionar` no lleva una clave ni una cadena en la línea de comandos; (d) el 5140 de error no vuelca la excepción con la cadena.
- **Esperado:** 0 coincidencias; `--login` no se usa con `sa` ni `gsf` (O-1 de F1, `Program.cs:60-63`); si el instalador usa `--login`, la clave se pide por consola y no por argumento.
- **Rechazo:** **Crítica:** una clave o cadena completa en cualquier registro o línea de comandos. **Media:** nombre del usuario SQL o de la ruta del perfil del técnico (se anota).
- **Control negativo:** sembrar una cadena centinela (`Password=Lab-Centinela-X`) en un mensaje de prueba y comprobar que el buscador la encuentra.
- **Duración:** 25 min. **Marca:** [V] `ComandoAprovisionar.cs:24-26,129-134`; [I] el Visor real.

### LAB-PE-12. Los binarios que corren como sysadmin (A1, C-6, AP-08)

- **Pasos:** `icacls` y `Get-Acl` (dueño y SDDL) de: la carpeta del paquete extraído, `GPOS.Migracion.exe` y sus DLL, `Instalar-Demo.ps1` y sus guiones, y las rutas por las que viajan hasta la ejecución (`%TEMP%` del técnico si se usa). Probar con `gpos-lab-usuario` (estándar): intentar escribir un archivo y sustituir una DLL.
- **Esperado:** solo Administradores y SYSTEM escriben, desde el origen hasta la ejecución; la prueba de escritura del usuario estándar falla; `Instalar-Demo.ps1` ya lo exige para la carpeta del paquete (`:95`); la comprobación se repite **inmediatamente antes** de ejecutar `aprovisionar` (C-6, sin ventana TOCTOU).
- **Rechazo:** **Alta:** un usuario estándar puede sustituir un binario que el instalador ejecuta como sysadmin. **Media:** R-02 de `restaurar` sigue abierto (C-6).
- **Control negativo:** conceder escritura a `gpos-lab-usuario` en una copia del paquete y comprobar que el instalador se detiene.
- **Duración:** 25 min. **Marca:** [V] la exigencia de la carpeta; [I] el resto.

## 5. Bloque FE: el orden de `FaseEsquema` y de todo el instalador (SF-03)

El orden firmado: `servicios` → `anillo --preparar` → `esquema` (`sistema --login-api` → `actualizar --todas` → `rpt` → `anillo --anclar` → `sistema --cuentas-iniciales --confirmar-sellado`) → empresa → `lectura`. **Aviso:** ese orden de `esquema` es el del blueprint (3.3) y es el que SF-03 demostró que falla. Los casos se escriben contra la corrección que B elija (a: `InstalacionId` solo con `--cuentas-iniciales`, o b: `sistema --login-api` tolera `SinAncla` y A ordena `--anclar` antes). **No fijo cuál**: D-1.

### LAB-FE-01. El orden de los verbos (F, sin VM)

- **Nivel:** F (`SistemaServidorFalso.Verbos`). **Prueba:** ejecutar `FaseEsquema` con un anillo `SinAncla` y registrar `Verbos`.
- **Esperado (corrección a):** `sistema --login-api`, `actualizar --todas`, `anillo --comprobar`, `anillo --anclar`, y después `sistema --cuentas-iniciales --confirmar-sellado --motivo`; **`--anclar` antes de las cuentas** y **`actualizar --todas` antes de `--anclar`** (porque el verbo `sistema` crea `GPOS_SYSDATA`: `ComandoSistema.cs:50` [V]). Con la corrección (b): `sistema --login-api` → `anillo --anclar` → resto.
- **Rechazo:** **Media:** cualquier otro orden; `sistema --cuentas-iniciales` antes de un `anillo --anclar` que no salió 0.
- **Mutación que lo mata:** MU-PE-05 y MU-PE-06 (sección 7). **Control negativo:** el orden anterior (hoy) da `SF03_…` en rojo con el sha de B corregido (ya la escribí invertida).
- **Duración:** 0 en VM (≈ 0,2 dp en F). **Marca:** [V] el orden actual (`FaseEsquema.cs:26-46`); `[?]` el nuevo.

### LAB-FE-02. Instalación nueva, anillo con certificado preparado y sin llaves (reproduce SF-03 en la VM)

- **Precondición:** servicio instalado, `anillo --preparar` hecho (certificado en `LocalMachine\My`, archivo presente), carpeta `Api\anillo` **sin llaves**, `GPOS_SYSDATA` no existe, ancla ausente (`LAB-D2-E0` antes de `esquema`).
- **Pasos:** `implantar-servidor --perfil demo --fase esquema --acta <ref de prueba> --motivo "LAB FE-02"`; anotar código y salida; `SnapInstancia`; `GPOS.Migracion anillo --comprobar`; repetir la fase.
- **Esperado:** código 0 en **la primera pasada**; `GPOS_SYSDATA` creada con `Licencia.InstalacionId` verificable por el anillo del servicio; `anillo --comprobar` en `Anclada`; la segunda pasada, 0 y sin cambios (FE-04).
- **Rechazo:** **Alta (funcional):** la primera pasada sale con 1 por `AnilloSinAncla` después de crear la base y aplicar S1 (la falla de SF-03, hoy [I]); queda la base a medias. **Media:** necesita una segunda pasada para terminar.
- **Control negativo:** con el orden actual en el sha sin corregir, el caso da `No cumple`; con el sha de B, `Cumple`. Sin ese par, no concluye.
- **Duración:** 30 min. **Marca:** [V] SF-03 por prueba (`SF03_…` de C); [I] el resultado en W real (almacén de la máquina).

### LAB-FE-03. Cuentas iniciales y sellado solo con el ancla en regla (G-2) (CU-03 con el orden firmado)

- **Pasos:** desde `LAB-D2-E0` con `GPOS_SYSDATA` creada y **sin ancla**: (a) `sistema --cuentas-iniciales --confirmar-sellado --motivo …` → debe salir 4 sin crear cuentas; (b) con ancla: crea las cuentas (ADMIN y GSF con los centinelas); (c) el servicio las acepta (login con el centinela de ADMIN; CU-01).
- **Esperado:** (a) salida 4, «G-2: el ancla … no está en regla … No se crearon cuentas»; conteo de `Usuarios` = 0; (b) 2 cuentas y sello inicial; (c) login 200.
- **Rechazo:** **Alta:** cuentas creadas sin ancla. **Media:** salida 0.
- **Control negativo:** (b). **Evidencia:** conteos y códigos. **Duración:** 30 min. **Marca:** [V] G-2 (`GuardasAnillo.cs`); [I] la VM.

### LAB-FE-04. Idempotencia de la fase `esquema` y del instalador completo

- **Pasos:** repetir `esquema` (con ancla) tres veces; después `Instalar-Demo.ps1` completo desde `LAB-D2-E0` y de nuevo sobre lo ya instalado (debe negarse: «La base … ya existe», `Instalar-Demo.ps1:109-111`).
- **Esperado:** `esquema` repetida, 0 y `cambios=0` (evento 5135) en la segunda y tercera; sin pedir acta (`anillo --comprobar` dice `Anclada`); no se re-crean cuentas ni se sella dos veces. Segundo instalador completo: se detiene antes de tocar nada (C-1).
- **Rechazo:** **Alta:** una cuenta duplicada o un segundo sello; la clave inicial se vuelve a generar. **Media:** pide acta otra vez.
- **Control negativo:** la primera pasada (cambios > 0). **Duración:** 30 min. **Marca:** [V] `[E]` `La_fase_esquema_con_el_ancla_ya_fijada_no_pide_acta…`; [I] el resto.

### LAB-FE-05. El orden de todo el instalador (empresa antes del esquema, lectura antes de la empresa)

| ID | Se altera | Esperado | Rechazo |
|---|---|---|---|
| FE-05a | `aprovisionar` **antes** de `esquema` (no hay `GPOS_SYSDATA`) | Falla limpio («Configure ConnectionStrings:Sistema» o el error de SQL de la base inexistente), sin crear la base de la empresa | **Alta:** crea la base de la empresa sin sistema |
| FE-05b | `lectura` **antes** de la empresa | Ver PE-08 | — |
| FE-05c | `esquema` **antes** de `anillo --preparar` | G-1 (4) si el servicio está instalado; sin cambios | **Alta:** escribe `InstalacionId` con DPAPI |
| FE-05d | `servicios` **después** de `esquema` | Detiene el instalador con el aviso del orden o funciona sin dejar el servicio sin ancla | **Media:** deja el servicio arrancable sin ancla |

- **Control negativo:** el orden firmado completo da 0 en todos. **Duración:** 40 min. **Marca:** [V] G-1; [I] el resto.

### LAB-FE-06. Nada cambia fuera del alcance (el paso no toca servicios ni entorno)

- **Pasos:** `FotoServicios` y `MismoEntorno` de ambos servicios antes y después del paso de empresa.
- **Esperado:** `MismoEntorno` `True` en los dos; `sc` igual; `%ProgramData%\GPOS NG` sin cambios salvo la cadena cifrada y los eventos. **Rechazo:** **Alta:** `MismoEntorno` `False` (rotó la clave JWT).
- **Control negativo:** `--rotar-jwt` en otra fase da `False`. **Duración:** 20 min. **Marca:** [I].

## 6. Bloque PC: cuentas iniciales después del paso de empresa

CU-01 a CU-06 (`2026-10-23-casos-laboratorio-pr-d2.md`, sección 8) **siguen vigentes sin cambios**; este bloque añade lo que el orden firmado trae de nuevo.

### LAB-PC-01. Las cuentas iniciales y la empresa recién aprovisionada

- **Pasos:** tras el paso de empresa, iniciar sesión como ADMIN y como GSF (centinelas) y pedir la lista de empresas; elegir `LABEMP`.
- **Esperado:** `LABEMP` se ofrece, no figura «pendiente»; el ADMIN y el GSF tienen acceso a ella **según lo que decida A** (D-2: ¿se crean las membresías de las cuentas iniciales en la empresa aprovisionada? Hoy la membresía por empresa es decisión firmada, pero no implementada, CLAUDE.md).
- **Rechazo:** **Alta:** una cuenta de otra empresa entra a `LABEMP`. **Media:** el ADMIN no ve la empresa que acaba de nacer.
- **Control negativo:** una empresa aún pendiente (`LABDOS`, PE-10) no se ofrece. **Duración:** 20 min. **Marca:** [I]; `[?]`.

### LAB-PC-02. El paso de empresa no cambia las cuentas

- **Pasos:** `SELECT` del conteo y de los hash de las filas de `Usuarios` y de los sellos antes y después de `aprovisionar`.
- **Esperado:** idénticos. **Rechazo:** **Alta:** cambia una cuenta o su sello. **Control negativo:** el cambio manual de un byte se ve. **Duración:** 15 min. **Marca:** [I].

### LAB-PC-03. Orden inverso: cuentas después de la empresa (CU con empresa presente)

- **Pasos:** FE-03(b) con `LABEMP` ya aprovisionada.
- **Esperado:** las cuentas se crean; la cadena de `LABEMP` sigue legible para la API; el sello cubre ambas.
- **Rechazo:** **Alta:** crear las cuentas deja ilegible la cadena (cambio de anillo). **Control negativo:** FE-03(b) sin empresa. **Duración:** 20 min. **Marca:** [I].

### LAB-PC-04. Las claves iniciales no se imprimen en el paso nuevo

- **Pasos:** como CU-05, ampliado al paso de empresa: auditoría de procesos con línea de comandos y registro de módulos de PowerShell durante `Instalar-Demo.ps1` completo.
- **Esperado:** ninguna clave inicial ni cadena en las líneas de comandos, en el registro de módulos ni en la salida. **Rechazo:** **Crítica.** **Control negativo:** el centinela sembrado se encuentra. **Duración:** 35 min. **Marca:** [I].

## 7. Mutaciones (en el código de A, una a la vez; cada una debe matar al menos una prueba de la sección 8)

| ID | Dónde | Mutación | La mata | Hoy |
|---|---|---|---|---|
| MU-PE-01 | `ComandoAprovisionar.cs:73-81` | Quitar la comprobación de `sysadmin` (o `!= 1` → `== 1`) | PE-02a/b (Q), PA-40 `[E]` | **Muere** [E] (solo la instancia de la empresa) |
| MU-PE-02 | `:73` | `new[]{ guardada.DataSource }` (sin la instancia de `GPOS_SYSDATA`) | PE-02c | **Sobrevive** [I]: PA-40 usa una sola instancia |
| MU-PE-03 | `:99-112` | Sin `ALTER AUTHORIZATION` (dueño sin corregir) | PE-04a (Q) | **Sobrevive** [I]: ninguna prueba mira el dueño |
| MU-PE-04 | `:100` | `TO sa` literal en vez de `SUSER_SNAME(0x01)` | PE-04c (con `sa` renombrado, Q con login renombrado, solo en VM) | Sobrevive [I] |
| MU-PE-05 | `FaseEsquema` | `--anclar` antes de `sistema --login-api` | FE-01 (F) | Sobrevive: `La_fase_esquema_*` no ordena [I] |
| MU-PE-06 | `FaseEsquema` | `sistema --cuentas-iniciales` antes de `anillo --anclar` | FE-01, FE-03 | Sobrevive |
| MU-PE-07 | `Program.cs` (F1) | Quitar la llamada a G-1 o G-2 (= MC-23/MC-24 de SF-06) | PC-G (F, sección 8) | **Sobrevive** (SF-06) |
| MU-PE-08 | `:61` o su sucesor (C-3) | Comparar solo el prefijo (el estado actual) o solo el literal `GPOS_SYSDATA` | PE-05a/b (Q) | **Sobrevive** hoy: es el defecto |
| MU-PE-09 | `:113` | `rotar: true` en la segunda ejecución | PE-03 (Q) | **Muere** [E] (PA-39) |
| MU-PE-10 | `:56-66` | Aceptar la `--base` en una empresa con cadena (O-2) | PE-03 paso 2 (Q) | Sobrevive [I] |
| MU-PE-11 | `FaseLectura` | Permitir `crear-lectura --todas` con empresas pendientes sin avisar (C-4) | PE-08 (F) | Sobrevive [V] |
| MU-PE-12 | paso de empresa de A | Registrar la empresa con un `INSERT` en el guion en vez del verbo | PE-09, TX sobre `Instalar-Demo.ps1` | `[?]` |
| MU-PE-13 | `ComandoAprovisionar` | Escribir la cadena o la clave en `Informar(...)` | PE-11 (Q: buscar el centinela en `Detalle`) | **Muere** [E] (`Assert.All(r.Detalle, …)`) |

## 8. Pruebas automáticas y requisitos de testabilidad

**Pruebas a escribir (nivel y estado):**

| ID | Nivel | Prueba | Mutación |
|---|---|---|---|
| PA-E01 | Q | `aprovisionar` deja el dueño `0x01` (nace así y se corrige si era otro; con `sa` renombrado si el servidor de pruebas lo permite) | MU-PE-03/04 |
| PA-E02 | Q | Segunda instancia sin sysadmin (dobles de instancia; ver RT-3) | MU-PE-02 |
| PA-E03 | Q | `aprovisionar` rechaza la base de otra empresa, la del sistema configurada y la del literal, sin cambios | MU-PE-08 (rojo hasta C-3) |
| PA-E04 | Q | Segunda ejecución con otra `--base`: rechaza o avisa, no crea | MU-PE-10 |
| PA-E05 | Q | Corte simulado (excepción inyectada tras cada paso) y reintento: una credencial, dueño correcto | O-1, PE-06 |
| PA-E06 | F | Orden de los verbos de `FaseEsquema` (FE-01) y de todo el instalador (`TX` sobre `Instalar-Demo.ps1`: `--fase esquema` antes del paso de empresa, y este antes de `--fase lectura`) | MU-PE-05/06/12 |
| PC-G | F o TX | El cableado de G-1/G-2 y de `aprovisionar` en `Program.cs` (SF-06; sin esto MU-PE-07 vive) | MU-PE-07 |
| PA-E07 | F | `FaseLectura` con una empresa pendiente: avisa o se detiene con 4 | MU-PE-11 |
| PA-E08 | Q | `aprovisionar` sin ancla (anillo con certificado `SinAncla`): rechaza antes de crear la base (O-1) | O-1 |
| PA-E09 | Q | Ni la salida, ni `Detalle` ni el evento llevan la clave del instalador ni la cadena | MU-PE-13 |
| PA-E10 | U | El mensaje de «sin sysadmin» nombra el paso y dice que no cambió nada (texto exacto de la regla) | — |

**Requisitos de testabilidad** (para A y B; sin ellos algunas pruebas no se pueden escribir):

| ID | Requisito |
|---|---|
| RT-1 | Que la comprobación de sysadmin sea una función inyectable por instancia (hoy abre la conexión dentro del bucle, `:73-81`), para probar PE-02c sin una segunda instancia real |
| RT-2 | Que el paso de empresa reciba `ISistemaServidor`/`EjecutarVerboAsync` como las demás fases (F), no un `Process.Start` suelto en el guion |
| RT-3 | Un punto de inyección de fallo (como `AnilloPrueba`) entre los pasos de `aprovisionar` para PA-E05; solo en Debug |
| RT-4 | Que `aprovisionar` devuelva la lista de pasos (`Detalle`) con prefijo estable («dueño», «credencial», «lectura») para no probar por texto libre |
| RT-5 | Que la comprobación de sysadmin del instalador sea una función de PowerShell testeable (C-1), con una prueba TX que fije su posición **antes** de `1b` |
| RT-6 | Una sonda de pruebas que diga si la cadena guardada de una empresa usa credencial contenida y cuál es su usuario, sin devolver la cadena (para la VM y para Q) |
| RT-7 | Que el verbo de registro (C-2) comparta con la Web la validación de bases (`MotivoBaseNoPermitida`) en un solo lugar (U) |
| RT-8 | Que `aprovisionar` exija el ancla con la misma función que G-2 (O-1) y lo diga en el mensaje |
| RT-9 | Que `FaseLectura` devuelva la lista de empresas omitidas (hoy solo la `foreach` de `BasesAsync`) |
| RT-10 | Que `SistemaServidorFalso` permita ordenar y comprobar el orden de `Verbos` con la propiedad `Verbos` ya existente (`SistemaServidorFalso.cs:50`) y un `CodigoVerbo` por verbo (ya existe, `:98`) |
| RT-11 | Que `ComandoImplantarServidor` no imprima `e.Message` en la fase de empresa (H-10 de PR-V) |

## 9. Orden de ejecución propuesto (dentro de S8)

1. PRE-E1 a PRE-E4 (60 min) → `LAB-D2-E0`.
2. FE-02, FE-03 (60) → FE-06 (20) → FE-05 (40) → FE-04 (30).
3. `LAB-D2-E1` → PE-02 (50) → PE-05 (50) → PE-01 (40) → PE-03 (35) → PE-04 (60) → PE-07 (45) → PE-08 (40) → PE-06 (60; deja la VM sucia entre cortes) → PE-10 (35) → PE-11 (25) → PE-12 (25) → PE-09 (`[?]`, 30).
4. PC-01 a PC-04 (90).

Total ≈ 11,5 h [I, ±50 %].

## 10. Severidades y recomendación (para este plan)

- **Crítica:** secreto en un registro o línea de comandos (PE-01, PE-11, PC-04); escritura fuera de la empresa.
- **Alta:** dueño ≠ `0x01` con respuesta de éxito; una empresa recibe la base de otra (PE-05a); la base nace sin sysadmin (PE-02a); la API con `dbcreator` (PE-10); `InstalacionId` o cadena escritas con el anillo del técnico (PE-07a); una cuenta creada sin ancla (FE-03); un binario sustituible por un usuario estándar (PE-12).
- **Media:** O-1 y O-2 (PE-07b, PE-03 paso 2); la omisión silenciosa de `lectura` (PE-08); 500 en lugar de 409 (PE-10).
- **Baja:** mensajes confusos.

**Recomendación técnica:** A debe tener en rojo antes del 5-nov las pruebas PA-E03 (C-3), PA-E08 (O-1) y FE-01 (SF-03); PE-05a y PE-02d son los dos casos de VM que hoy darían `No cumple`. La firma de C-1 a C-7 es del propietario; este plan las trata como vigentes en su recomendación y marca `[?]` lo que depende de ellas.

## 11. Dudas abiertas (no las inventé)

| ID | Duda | A quién |
|---|---|---|
| D-1 | ¿B corrige SF-03 con (a) `InstalacionId` solo con `--cuentas-iniciales`, o (b) `sistema --login-api` tolera `SinAncla` y A ordena `--anclar` antes? Los casos FE-01 y FE-02 cambian de forma según la elección. **Mientras no se sepa, FE-01 lista los dos órdenes aceptables** | B |
| D-2 | ¿Las cuentas iniciales (ADMIN y GSF) reciben membresía en la empresa aprovisionada? El modelo de membresía por empresa está firmado, pero no implementado; PC-01 no puede fijar el esperado | Arquitecto / A |
| D-3 | ¿Se monta una segunda instancia SQL en `VM-SRV` (PRE-E2)? Si no cabe en RAM, PE-02c queda `No se pudo` y se cubre solo en Q con RT-1 | B |
| D-4 | PE-04d (dueño = login de la API): ¿`aprovisionar` debe corregir el dueño o rechazar con 51606 cuando hay otro usuario de la API en la base? El código del lote 2 no lo dice y no lo verifiqué [I] | A |
| D-5 | ¿Dónde se registra la empresa pendiente: dentro de `esquema`, en el inicio del paso de empresa o con un verbo aparte? Fija PE-09 y el orden de FE-05 | A |
| D-6 | ¿`aprovisionar` en modo DEMO usa `--servidor .`, el nombre del equipo o la instancia nombrada? `ServidorLocal.Aplicar` decide el cifrado según esto; PE-05d lo mide, pero no sé cuál será la forma que use el instalador | A |
| D-7 | Los niveles Q (SQL real sin servicios) no figuran en mi plan de PR-V; los agregué por cómo se prueba hoy `aprovisionar`. Si B prefiere reducirlos a F/V, PA-E01 a PA-E05 pasarían a la VM | B |
| D-8 | Criterio del 5140 (nivel de Información/Error): ¿la ausencia del origen `GPOS.Migracion` registrado se considera falla del instalador? Hoy el detalle «se pierde sin fallar» (`:131-133`) y PE-01/PE-11 dependen del evento | A / devops |
| D-9 | O-1: ¿se acepta como hallazgo del PR-D2 (G-2 también en `aprovisionar`) o como decisión de diseño? Lo anoto como Media | B / propietario |

## 12. Qué no verifiqué

No compilé ni ejecuté nada. No leí `Aprovisionamiento.CrearAsync` ni `CredencialApp.AplicarAsync` línea a línea: el orden interno de crear, credencial y guardar es el que muestra `ComandoAprovisionar`. No vi el paso de empresa de A (no existe en `812d1790`). El efecto de `SUSER_SNAME(0x01)` con `sa` renombrado, el comportamiento de `ALTER AUTHORIZATION` con un dueño que es el login de la API y el tiempo de `aprovisionar` son [I]. Las cifras de duración y de dp son estimaciones propias (±50 %).

### Cierre
- Estado: Completado (plan; nada ejecutado)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-24-plan-pruebas-paso-empresa-y-cuentas.md`
- Supuestos: el DEMO de servicios corre en Amplio (`Instalar-Demo.ps1:144`); `aprovisionar` conserva el orden de pasos de `ComandoAprovisionar.cs` en `812d1790`; C-1 a C-7 se tratan como vigentes en la recomendación, aunque el propietario no las ha firmado.
- Decisiones candidatas a ADR: ninguna (O-1 y O-2 son precisiones del paso de D-5).
- Entregas a otros agentes: A → O-1 (G-2 en `aprovisionar`), O-2 (`--base` ignorada), C-1 a C-4, RT-1 a RT-11, dudas D-2, D-4, D-5, D-6, D-8; B → D-1 (forma de corregir SF-03), D-3, D-7, D-9, las tres identidades de PRE-E1; propietario → firma de C-1 a C-7.
- Próximo paso recomendado: que A confirme D-1 y D-5 antes de escribir el paso (5-nov), y que yo convierta PA-E03, PA-E08 y FE-01 en pruebas rojas contra el sha de B corregido.
