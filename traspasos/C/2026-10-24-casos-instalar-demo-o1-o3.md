```
Para: B (copia a A)        De: C        Fecha: 2026-10-24 (redactado el 2026-10-23)
Tipo: Entrega (tanda 9, punto 4 de B-a-C/2026-10-23-tareas-nuevas-para-c-tanda-9)
Prioridad: Alta (A corrige antes del 28-oct; la VM, después)
Repositorio y rama: GPOS-NG `origin/a/pr-d2-manifiesto` @ `812d1790` (solo lectura, `git show`)
Estado: Abierto (casos redactados; nada ejecutado, compilado ni empujado)
```

# Casos de laboratorio de `Instalar-Demo.ps1` (O-1 a O-3) y de los RA de `restaurar` que tocan a los guiones del DEMO

**Marcas.** [V] = lo leí en `812d1790` (ruta y línea); [I] = inferido, se confirma en la VM; [?] = depende de algo que aún no existe. **Estados en la VM:** `Cumple`, `No cumple`, `No se pudo`, `Bloqueado`. Reglas heredadas sin cambio (documento de PR-D2, §2.1): solo `VM-SRV` desde `base`, un punto de control por bloque, nada se corrige a mano para que pase, ningún secreto en la evidencia, claves iniciales centinela, sin `sysadmin` para la cuenta virtual. **Un caso sin control negativo concluyente no puede dar `Cumple`.**

## 0. Resumen para decidir

1. **Ya existe rama de A con la corrección? No.** `git ls-remote origin 'refs/heads/a/*'` (2026-10-23, 74 ramas) no trae ninguna con la corrección de O-1: recorrí las ramas `a/*`, `b/*` y `c/*` y la única con la línea `'--fase', 'carpetas'` es `a/pr-d2-manifiesto`, y sigue con `--origen` en `Instalar-Demo.ps1:127` [V]. **Ojo con el nombre:** `a/instalador-o1-o3` (`82318329`) **no es esta corrección**: sus O-1/O-3 son de ADR-77 (acción previa compartida, raíz y `config\`), y esa rama arrastra 344 archivos de diferencia con `pr-d2-manifiesto` (base `82318329` distinta). No la usé como fuente.
2. **Ruta real del guion:** `instalador/Demo/scripts/Instalar-Demo.ps1` (no `instalador/Demo/Instalar-Demo.ps1`; el `git show` del encargo con esa ruta falla). Hay que decirlo a B para los comandos.
3. **Hallazgo previo a la VM (no es de los O):** `Instalar-Demo.ps1` termina en modo de servicios con `Detener-ConError 'BORRADOR de PR-D2 …'` (`:167`) **a propósito** y antes de escribir `instalacion.json`. O-1 hace que ni siquiera llegue a ese punto. Por eso el criterio de "cumple" para O-1 es **llegar exactamente al BORRADOR** y no pasar de ahí (ID-02), hasta que A termine el instalador de servicios (5 al 9-nov), momento en que ID-02 se reescribe.
4. **Cuál guion: recomiendo dos piezas, la segunda nueva.**
   - **Ampliar `Probar-Restaurar.ps1` (PR #223)** con tres subcasos de la CLI, porque es el mismo montaje (Nivel V, sin SQL, `LAB-D2-LISTO` y `LAB-D2-A2B`) y el mismo caso `RS-10` ya mide la opción repetida (`f-repetida`, que hoy da **Baja** y es O-2 [V]): **RS-10g** (O-3), **RS-10h** (O-1 en la CLI) y la ampliación de **RS-10f** (O-2). ≈ 0,3 dp.
   - **`Probar-InstalarDemo.ps1` nuevo** (Nivel G, con SQL y `Instalar-Demo.ps1` de verdad) para ID-02, ID-03 y los RA de los guiones (ID-06 a ID-09, más los ajustes de RV-06, RV-08 y RV-09). Mismas guardas LS-11, mismo marcador `VM-SRV`, 64 bits y evidencia sin secretos que `Probar-Restaurar.ps1`; reutiliza sus funciones (`Snap`, `Redactar`, `Hallazgo`, `Cerrar-Caso`). ≈ 1,5 dp. **No lo escribo hasta que A fije el contrato de la corrección** (D-1): sería escribir contra una versión que cambia el 28-oct. Si se prefiere un solo guion, todo cabe en `Probar-InstalarDemo.ps1` y `Probar-Restaurar.ps1` queda como está; pierde el montaje barato sin SQL.
5. **Una prueba que evita esta clase de defecto (ID-00, sin VM):** una prueba de contrato guion↔CLI en `tests/GPOS.Tests` (Esquema=Neutral, doble `SistemaServidorFalso`) que lee los `.ps1`, extrae cada llamada `'implantar-servidor', …` y comprueba que `Incoherencia` no la rechaza. Habría atrapado O-1 el día que se escribió `:127`. Es mía y pequeña (≈ 0,4 dp); la escribo cuando A fije la corrección.
6. **Duración [I, ±50 %]:** Nivel V (RS-10f/g/h) ≈ 25 min dentro de S6; Nivel G (ID-02 a ID-09 y ajustes) ≈ 4,5 h, que **sustituye** a parte de S7 (RV-06, RV-08, RV-09 ya están en S7; los nuevos suman ≈ 2 h).
7. **Dependencias:** ID-02 necesita SQL Express arrancado y `gpos-lab-usuario`; el paso 1c (`--fase esquema`, ancla del anillo) puede no llegar a correr hasta que F1 esté unido [?]. Si 1c falla por el anillo, ID-02 queda `Bloqueado` a partir de 1c, pero el tramo 1b (lo que O-1 arregla) **sí** se puede dar por `Cumple`: está medido por separado (ID-02, subpaso 1b).

## 1. Lo que dice el código [V]

| # | Hecho | Evidencia |
|---|---|---|
| O-1 | `Instalar-Demo.ps1` llama `implantar-servidor --perfil demo --fase carpetas --origen $raiz`; `Incoherencia` rechaza `--origen` si la fase no es `servicios` (`if (o.Fase == Servicios) return null;` y luego `if (o.Origen is not null) sobran.Add("--origen")`). La fase termina con 1 y el texto "--origen solo vale(n) con --fase servicios.", y el guion lanza `Detener-ConError "… --fase carpetas terminó con el código 1 …"` | `Instalar-Demo.ps1:127-129`; `ComandoImplantarServidor.cs:58-75` |
| O-1 (alcance) | Los demás usos de `implantar-servidor` en los guiones son coherentes con la tabla de `Incoherencia`: `servicios` con `--origen` y `--rotar-jwt` (`Instalar-Demo.ps1:131-133`, `Actualizar-Demo.ps1`), `esquema` con `--acta/--motivo` (`:143-144`), `lectura` sin opciones (`:158`), `restaurar` con `--huella-copia-previa` (`Revertir-Actualizacion.ps1:124`). Solo `:127` sobra | `grep` de `'implantar-servidor'` en `instalador/Demo/scripts/` |
| O-2 | `Argumentos.Leer` guarda `_opciones[nombre] = valor` sin comprobar si la clave existe: la última gana. El diccionario ignora mayúsculas, así que `--fase` y `--FASE` son la misma opción. Las banderas repetidas son idempotentes | `Program.cs:461-486` |
| O-3 | `--huella-copia-previa` llega como texto; `FaseRestaurar` la compara con `HuellaSha256(...)` por `string.Equals(..., OrdinalIgnoreCase)`; un texto no hexadecimal nunca coincide y la fase se detiene con 4 y "La copia previa no es la de esa actualización …". No hay validación de formato en `Incoherencia` ni en `ComandosServidor` | `FaseRestaurar.cs:62-65`; `ComandosServidor.cs:27-28` |
| RA-01 | **Cerrado en `812d1790`:** la copia previa lleva `# copia=<GUID>` en la segunda línea (`FaseServicios.cs:49-58`, `:372`) y `FaseRestaurar` exige ese identificador (`:72-75`). Dos copias previas de los mismos binarios ya no tienen la misma huella | `812d1790` |
| RA-02 | **Abierto:** `Actualizar-Demo.ps1:155` sigue lanzando `Detener-ConError` antes de las líneas que anotan la huella (`:157-161`); `Revertir` sigue sin mirar `.aplicando` | `Actualizar-Demo.ps1:149-165`; `Revertir-Actualizacion.ps1:75-78` |
| RA-04 | **Abierto:** `$env:ProgramFiles` en `Actualizar-Demo.ps1:151` y `Revertir-Actualizacion.ps1:80`. `Instalar-Demo.ps1`, `Iniciar-Demo.ps1`, `Detener-Demo.ps1`, `Desinstalar-Demo.ps1` y `Comun-Demo.ps1` **no** la usan (grep vacío): RA-04 no toca a `Instalar-Demo.ps1` | `grep ProgramFiles` |
| RA-10 | **Abierto:** `Iniciar-Demo.ps1:67-77` arranca los servicios (`Iniciar-ServiciosDemo`) antes de `comprobar-servidor`; nadie mira `.aplicando` | `Iniciar-Demo.ps1:67-77` |

## 2. Qué casos cubren cada observación

| Origen | Caso | Nivel | Guion |
|---|---|---|---|
| O-1 (contrato) | LAB-ID-00 | estático (sin VM) | prueba de unidad en `GPOS.Tests` |
| O-1 (CLI) | LAB-RS-10h | V | `Probar-Restaurar.ps1` (ampliación) |
| O-1 (guion de punta a punta) | LAB-ID-02, LAB-ID-03 | G | `Probar-InstalarDemo.ps1` |
| O-2 | LAB-RS-10f (ampliada) | V | `Probar-Restaurar.ps1` |
| O-3 | LAB-RS-10g | V | `Probar-Restaurar.ps1` |
| RA-01 | LAB-RV-06 (ajustada, ID-04) | G | `Probar-InstalarDemo.ps1` |
| RA-02 | LAB-RV-08 (ajustada, ID-05) | G | `Probar-InstalarDemo.ps1` |
| RA-04 | LAB-RV-09 (sin cambio) | G | `Probar-InstalarDemo.ps1` |
| RA-05 en `Revertir` | LAB-ID-08 | G | `Probar-InstalarDemo.ps1` |
| RA-09 | LAB-ID-06 | G | `Probar-InstalarDemo.ps1` |
| RA-10 | LAB-ID-07 (más RV-08e) | G | `Probar-InstalarDemo.ps1` |
| RA-08 | LAB-RS-10i | V | `Probar-Restaurar.ps1` |
| RA-03, RA-06, RA-07 | sin guion nuevo: son de la fase | V | ya en LAB-RS-05f/g y RS-04; no tocan a los guiones |

## 3. Montaje y funciones de apoyo

**Precondiciones nuevas** (las de PR-D2, PRE-1 a PRE-6, siguen igual):

| ID | Qué |
|---|---|
| PRE-7 | Una carpeta de **paquete del DEMO completa** (con `Instalar-Demo.ps1`, `herramientas\Comun-Demo.ps1`, `version.json` con `IncluyeApiReportes`, `app\api`, `app\web`, `app\migracion`, `app\reportes`) extraída fuera de OneDrive y del perfil, escrita solo por SYSTEM y Administradores (`Get-EscritoresAjenos` vacío). [I] Los PQ-A y PQ-B que fabrica `Preparar-Paquetes` de `Probar-Restaurar.ps1` pueden no traer los guiones ni `app\web`: **D-2** pregunta a B si basta publicar con `Publicar-PaqueteDemo.ps1 -ConApiReportes` desde `a/pr-d2-manifiesto` y extraer tal cual. SHA-256 del `.7z` y de `manifiesto.sha256` anotados |
| PRE-8 | Para ID-02 a ID-09: SQL Express arrancado, la cuenta de Windows de quien instala con `dbcreator`/`sysadmin` en la instancia, puertos 5071, 5054 y 5073 libres, ≥ 2 GB libres. Claves iniciales: los centinelas `Lab-Admin-Centinela-01` y `Lab-Gsf-Centinela-0001` (SecureString, parámetros `-ClaveAdmin` y `-ClaveSuper`; nunca por teclado grabado) |
| PRE-9 | Punto de control `LAB-D2-ID-LISTO` = `LAB-D2-LISTO` + SQL arrancado + PRE-7 extraído, **sin** instalar |

**Funciones nuevas** (PowerShell 5.1 elevado de 64 bits; **escritas sin probar**; las de `Probar-Restaurar.ps1` siguen valiendo):

```powershell
$E = 'C:\GPOS-LAB\evidencia\D2'
function Migra([string[]]$a){            # GPOS.Migracion.exe del paquete; devuelve código y texto (sin entorno)
  $t = & $script:Exe @a 2>&1 | ForEach-Object { "$_" }; [pscustomobject]@{ Codigo = $LASTEXITCODE; Texto = ($t -join "`n"); Linea = ($t | Select-Object -Last 1) } }
function FaseDeSalida($r){ if($r.Texto -match '(?m)^fase=(\w+) resultado=(\w+) cambios=(\d+)'){ [pscustomobject]@{Fase=$Matches[1];Resultado=$Matches[2];Cambios=[int]$Matches[3]} } }  # la última línea imprime la fase que ganó [V: ComandoImplantarServidor.cs:81]
function EstadoServicios { foreach($s in 'GPOS.Api','GPOS.Reportes'){ $x = Get-Service $s -ErrorAction SilentlyContinue; '{0}={1}' -f $s, $(if($x){ $x.Status }else{ 'no-existe' }) } }
function RegistroSinClaves([string]$f){ Get-Content "$($script:Raiz)\registros\$f" | Select-String -Pattern 'Jwt__Clave|Password=|ClaveAdmin|ClaveSuper|Lab-(Admin|Gsf)-Centinela' -Quiet }   # debe dar False antes de archivar el registro
function Sha64([string]$t){ $t -cmatch '^[0-9a-f]{64}$' }
```

## 4. Casos del Nivel V (se añaden a `Probar-Restaurar.ps1`, partiendo de `LAB-D2-A2B`)

### LAB-RS-10h (O-1 en la CLI). `--fase carpetas` con y sin `--origen`

- **Precondición:** `LAB-D2-A2B` (las carpetas ya existen); `Snap` antes. Todo con el `GPOS.Migracion.exe` del paquete.
- **Pasos:**
  1. `implantar-servidor --perfil demo --fase carpetas --origen <PQ-A>` (la forma que usa hoy `Instalar-Demo.ps1:127`). Anotar código, texto y `FaseDeSalida`.
  2. `implantar-servidor --perfil demo --fase carpetas` (la forma que debe usar el guion). Anotar código, texto, eventos (5134 y 5135).
  3. Repetir el paso 2 (idempotencia).
  4. **Control de instrumento:** `implantar-servidor --perfil demo --fase servicios --origen <PQ-A>` (con el entorno que ya usa `Probar-Restaurar.ps1`): `--origen` **sí** vale ahí.
- **Esperado:** paso 1: código 1, "--origen solo vale(n) con --fase servicios." y `fase=carpetas resultado=error cambios=0`, **sin** eventos 5134 y 5135 y sin cambios en el destino (la guarda es la primera de la fase, antes de cualquier escritura [V: `:21-22`]). Pasos 2 y 3: código 0, `cambios=0` (las carpetas ya estaban) y `Snap` idéntico. Paso 4: código 0 u otra salida que no sea el rechazo de `--origen`.
- **Qué cumple tras la corrección de A:** depende de **D-1**. Si A quita `--origen` del guion (lo previsto), el paso 1 sigue siendo rechazo y es el **control** de ID-02; si A decide aceptar `--origen` en `carpetas` (no lo recomiendo: es una opción sin efecto), el paso 1 pasa a 0 y el caso se invierte. El caso debe fijarse a la decisión de A.
- **Rechazo:** **Alta:** el paso 1 escribe algo (cambia el `Snap`), crea el evento de éxito o devuelve 0 con una opción que la fase ignora. **Baja:** mensaje distinto del documentado.
- **Control negativo:** pasos 2 y 4 (la forma correcta funciona y `--origen` es válido donde corresponde); sin ellos el paso 1 no concluye.
- **Evidencia:** códigos, textos, `FaseDeSalida`, `Snap` antes y después, eventos. **Duración:** 8 min. **Marca:** [V] la lógica; [I] el resultado en Windows.

### LAB-RS-10f (ampliada, O-2). Una opción repetida es un error

- **Precondición:** `LAB-D2-A2B`; `Snap` antes. Solo se usan combinaciones que, si se aceptaran, **no** hacen daño: fases idempotentes sobre un estado conocido.
- **Pasos** (cada una: código, texto, `FaseDeSalida`, `Snap` después, eventos):

| Sub | Línea | Si se acepta (hoy [V]) gana la última |
|---|---|---|
| f1 | `--fase carpetas --fase servicios` (sin `--origen`) | corre `servicios`: se detiene por falta de `--origen` |
| f2 | `--fase servicios --origen <PQ-A> --origen <PQ-B>` | instala PQ-B (¡cambia el destino!): usar solo desde `LAB-D2-A` y comprobar el resultado con `CompararManifiesto` |
| f3 | `--perfil demo --perfil produccion --fase carpetas` | corre en `produccion` (solo `carpetas`) |
| f4 | `--fase carpetas --FASE servicios` (mayúsculas) | la misma opción: gana la última |
| f5 | `--rotar-jwt --rotar-jwt --fase servicios --origen <PQ-A>` | bandera repetida: idempotente |
| f6 | `--fase --origen <PQ-A>` | `--fase` consume `--origen` como valor: error de opciones («Argumento no esperado») |
| f7 | `--huella-copia-previa <h1> --huella-copia-previa <h2> --fase restaurar` | la última huella decide (R-01 depende de ella) |

- **Esperado tras la corrección:** f1 a f4 y f7: código 1 y un texto que nombra la opción repetida ("--fase se repite", o equivalente), `fase=… resultado=error cambios=0`, sin eventos 5134 y 5135, `Snap` idéntico. f5: A decide si la bandera repetida se tolera (Baja) o se rechaza (D-3). f6: ya hoy es un error. **Hoy** f1 a f4 y f7 se aceptan y gana la última: es O-2.
- **Rechazo:** **Media:** f2 o f7 aceptados (cambian qué paquete se instala o con qué huella se ata la restauración; un guion que añada una opción por su cuenta pasaría desapercibido). **Baja:** f1, f3 y f4 aceptados (O-2 en sí). f5 según D-3.
- **Control negativo:** la misma línea con la opción una sola vez (`--fase carpetas`, `--fase servicios --origen <PQ-A>`) funciona; sin ese par no hay `Cumple`.
- **Evidencia:** tabla subcaso → código, `FaseDeSalida`, `Snap` igual/distinto. **Duración:** 12 min (con `LAB-D2-A` para f2). **Marca:** [V] por lectura (`Program.cs:461-486`); [I] el resultado.

### LAB-RS-10g (O-3). `--huella-copia-previa` se valida como hexadecimal

- **Precondición:** `LAB-D2-A2B`; `$h = HuellaPrevia` (la correcta). `Snap` antes.
- **Pasos** (con `--fase restaurar --huella-copia-previa <valor>`; cada uno: código, texto, eventos, `Snap` después):

| Sub | Valor | Esperado tras la corrección | Hoy [V] |
|---|---|---|---|
| g1 | `$h` en minúscula (control) | 0, restaura (RS-01) | igual |
| g2 | `$h.ToUpper()` | 0 (la comparación ya ignora mayúsculas; que A lo conserve o lo normalice) | 0 |
| g3 | 63 caracteres hexadecimales | error de opciones, código 1, antes de leer el destino | 4 ("La copia previa no es la de esa actualización …") |
| g4 | 65 caracteres hexadecimales | ídem | 4 |
| g5 | 64 caracteres con una `g` | ídem | 4 |
| g6 | `""` (vacío) | ídem (hoy `Argumentos.Leer` lo acepta como valor vacío) | 4 |
| g7 | `$h` con un espacio al principio | ídem | 4 |
| g8 | `--huella-copia-previa --destino x` | error («Falta valor» o `--destino` consumido como valor) | consume `--destino` como valor: 4 |
| g9 | 64 hexadecimales con **otra** huella (no es la de `.anterior`) | 4 con la guarda R-01 (es una huella válida pero falsa); es el control de que la validación de formato no sustituye a la de contenido | 4 |

- **Esperado tras la corrección:** g3 a g8: código **1** (error de opciones, no 4), mensaje que dice "64 caracteres hexadecimales", **sin** eventos de fase ni de guarda, `Snap` idéntico. g9: código 4 (guarda). g1 y g2: restauran.
- **Por qué importa el código:** 1 = "opción mal escrita", 4 = "una guarda de seguridad detuvo la fase". Hoy un error de tipeo se confunde con una alarma de R-01 y el evento de guarda (`DetenidoPorGuarda`) se registra con nivel Error; un técnico que lo ve piensa en una manipulación de `.anterior`.
- **Rechazo:** **Baja:** g3 a g8 siguen dando 4 con el evento de guarda. **Media:** alguno de g3 a g8 **restaura**. **Alta:** g9 restaura.
- **Control negativo:** g1 (restaura) y g9 (la guarda sigue); sin g1 en verde no hay `Cumple`. Entre subcasos, restaurar `LAB-D2-A2B` (cada restauración exitosa cambia el estado).
- **Evidencia:** tabla subcaso → código y evento. **Duración:** 15 min (los exitosos exigen volver a `LAB-D2-A2B`). **Marca:** [V] por lectura; [I] el resultado.

### LAB-RS-10i (RA-08). `restaurar` sin huella

- **Precondición:** `LAB-D2-A2B`; sin `.aplicando`.
- **Pasos:** (1) `--fase restaurar` **sin** `--huella-copia-previa`, con `.anterior` sana y sin marca. (2) Leer el mensaje de `--fase servicios` cuando deja `.aplicando` (RS-06a) y comprobar si la orden que sugiere trae la huella.
- **Esperado (el correcto, RA-08):** (1) se rechaza ("la huella es obligatoria salvo para retomar una `.aplicando`") **o** funciona y lo dice; (2) la orden sugerida incluye la huella o aclara que la retoma no la necesita. **Hoy [V]** (1) restaura sin atadura R-01 (`FaseRestaurar.cs:62` salta la comprobación).
- **Rechazo:** **Baja** (RA-08): restaura sin huella con una `.anterior` que no es de la última actualización; verificarlo con la `.anterior` de PQ-A tras un ciclo A→B→revertir→C (copia previa distinta de la que se piensa).
- **Control negativo:** con la huella (RS-01). **Duración:** 8 min. **Marca:** [V] por lectura; [I] el resultado.

## 5. Casos del Nivel G (`Probar-InstalarDemo.ps1`)

### LAB-ID-00 (O-1, contrato guion↔CLI; sin VM)

- **Qué:** prueba de unidad en `tests/GPOS.Tests/Servidor/` (Esquema=Neutral): extrae de los `.ps1` de `instalador/Demo/scripts/` cada llamada a `Invoke-Migracion`/`Invoke-MigracionConEntorno` con `'implantar-servidor'`, la convierte en `OpcionesImplantar` y exige que `Incoherencia` devuelva `null` (hoy: una sola falla, `Instalar-Demo.ps1:127`). Control negativo en la misma clase: una llamada inventada con `--fase carpetas --origen` **debe** devolver incoherencia (el instrumento ve la diferencia).
- **Estado:** pendiente de D-1 (qué corrección hace A). **Marca:** [V] el defecto por lectura; la prueba no existe todavía. **Severidad si falla:** Media (bloquea el modo de servicios, un camino que aún es BORRADOR).

### LAB-ID-02 (O-1, punta a punta). `Instalar-Demo.ps1` supera el paso 1b en modo de servicios

- **Precondición:** `LAB-D2-ID-LISTO` (PRE-7 a PRE-9); sin `config\instalacion.json`; sin servicios `GPOS.*`; bases `GPOS_SYSDATA` y `GPOS_DEMO` inexistentes; `Snap` de `Archivos de programa\GPOS NG` y `FotoServicios` antes.
- **Pasos:**
  1. `.\Instalar-Demo.ps1 -Instancia '.\SQLEXPRESS' -ClaveAdmin $a -ClaveSuper $g -ActaAncla 'LAB-ACTA-01' -MotivoAncla 'laboratorio'` (SecureString de centinelas), en consola elevada de 64 bits. Guardar la salida (sin claves) en `ID02-salida.txt`.
  2. Anotar hasta dónde llegó cada paso: 1 (comprobaciones), **1b** (carpetas y servicios), 1c (esquema), 1d (lectura) y el error final.
  3. `EstadoServicios` (deben existir y estar **detenidos**); `Test-Path config\instalacion.json` (no debe existir); `Test-Path "$env:ProgramFiles\GPOS NG\Demo\api\GPOS.Api.exe"`.
  4. `registros\migracion.log`: primera línea de cada llamada a `implantar-servidor` con su `(código de salida N)` y `RegistroSinClaves` (debe dar `False`).
  5. `FotoServicios` y `icacls` de `%ProgramFiles%\GPOS NG` y `%ProgramData%\GPOS NG` (sin ACE de `Users` con escritura).
- **Esperado (versión corregida, BORRADOR vigente):** el paso 1b imprime la salida de `carpetas` con `fase=carpetas resultado=ok` (código 0), luego `servicios` con 0 y "Servicios implantados."; 1c y 1d hacen lo suyo [?] (1d tolera "falta red"); el guion **termina con error** en la línea del BORRADOR ("BORRADOR de PR-D2: faltan la base de la empresa y las cuentas iniciales …"), código de salida de PowerShell ≠ 0; servicios `GPOS.Api` y `GPOS.Reportes` creados y detenidos; sin `instalacion.json`; binarios en Archivos de programa con DACL solo de administradores; el registro sin claves. Cuando A termine el instalador (5 al 9-nov), este caso se **reescribe**: el final esperado es `instalacion.json` y "Instalación completa".
- **Esperado de la versión actual (`812d1790`, control):** el guion se detiene en 1b con `"implantar-servidor --fase carpetas terminó con el código 1 …"`; no hay servicios, ni carpetas de datos, ni Archivos de programa\GPOS NG\Demo nuevo. Se ejecuta **antes** de la corrección de A para fijar la línea base (si A ya la entregó, desde el commit anterior).
- **Rechazo:** **Alta:** el guion se detiene en 1b con la versión corregida; o llega al final sin pasar por el BORRADOR (el BORRADOR no puede saltarse hasta que A lo retire); o deja servicios en marcha; o escribe una clave en el registro. **Media:** la salida no distingue 1b de 1c. **Baja:** mensajes.
- **Control negativo:** la corrida con la versión sin corregir (se detiene en 1b, código 1) y `Instalar-Demo.ps1` en modo consola (ID-03): sin esa diferencia no se concluye que la corrección sea la causa.
- **Evidencia:** salida del guion (redactada), `migracion.log` (revisado), `EstadoServicios`, `FotoServicios`, ACL, `Snap`. Subpasos 1b y 1c-1d se informan **por separado** para que un fallo de F1 no oculte el `Cumple` de 1b. **Duración:** 45 min (con preparación). **Marca:** [V] el defecto y el camino; [I] el resultado en la VM; [?] 1c depende del anillo.

### LAB-ID-03 (control de O-1). El modo consola no cambia

- **Precondición:** `LAB-D2-ID-LISTO` con un paquete **sin** API de reportes (`version.json` sin `IncluyeApiReportes`) y SQL arrancado.
- **Pasos:** `.\Instalar-Demo.ps1 -ClaveAdmin $a -ClaveSuper $g`; comprobar `registros\migracion.log`.
- **Esperado:** el modo consola no llama a `implantar-servidor` (ninguna línea con esa cadena en `migracion.log`), no crea servicios ni toca Archivos de programa; termina con `instalacion.json`. Es lo que ya hacía antes de PR-D2.
- **Rechazo:** **Media:** cualquier llamada a `implantar-servidor` en modo consola o servicios creados (la corrección de O-1 contaminó el modo consola).
- **Control negativo:** ID-02 (el modo de servicios sí llama a `implantar-servidor`). **Duración:** 20 min. **Marca:** [I]. **Dependencia:** [?] si el paquete sin reportes sigue publicándose (D-2).

### LAB-ID-04 (RA-01, ajuste de RV-06 a `812d1790`). Actualizar, revertir, actualizar, revertir

- **Qué cambia respecto a RV-06:** el **control del instrumento** de RV-06 decía "si la huella de `.anterior\manifiesto.sha256` difiere entre el paso 1 y el paso 3, el escenario no reproduce RA-01". **Con `812d1790` siempre difiere** (cada copia lleva un GUID), así que ese control se invierte:
  - en `cd44043c`, huella igual y RA-01 reproducido;
  - en `812d1790`, huella distinta en M1 y en M2 (control), `actualizacion.json` de M2 **sí** trae `HuellaCopiaPrevia`, el aviso "no cambió los binarios" **no** aparece, y la segunda reversión restaura **binarios y bases** a PQ-A.
- **Pasos y esperado:** los de LAB-RV-06 con la regla de arriba. Añadir: leer la segunda línea del manifiesto (`Get-Content -TotalCount 2`) y comprobar que es `# copia=` más 32 hexadecimales y **distinta** entre M1 y M2 (se informa solo que difiere, no el valor).
- **Rechazo:** **Media** (la de RV-06): binarios y bases de versiones distintas tras una reversión que el guion dio por buena. **Baja:** la línea `# copia=` repetida entre dos copias.
- **Control negativo:** el primer ciclo (RV-01) y, si se dispone del commit `cd44043c`, la misma secuencia reproduce RA-01 (huella igual y aviso falso). **Duración:** 40 min (el de RV-06). **Marca:** [V] la corrección por lectura (`812d1790`); [I] el resultado.

### LAB-ID-05 (RA-02, ajuste de RV-08). La fase de servicios falla después de renovar `.anterior`

- **Qué cambia respecto a RV-08:** `812d1790` no toca este camino (sigue [V] abierto). El caso se mantiene como está, con dos precisiones:
  - se mide también **cuántas copias previas hay**: tras la falla de `servicios` (subcaso a) `.anterior` ya es de **esta** actualización y la huella actual es la que hay que anotar; el caso verifica con `HuellaPrevia` y `# copia=` que `restaurar --huella-copia-previa <HuellaPrevia>` retoma (RV-08d);
  - se agrega el subcaso **f** (después de la corrección de A): el guion anota la huella **aunque** el código sea 4, y `Revertir` con `.aplicando` presente **no** pasa por `$sinBinarios`.
- **Rechazo y esperado:** los de RV-08. **Control negativo:** el `Actualizar` sin bloqueo (RV-01) y RV-08d. **Duración:** 40 min. **Marca:** fase [V] (RC2); guion [I].

### LAB-ID-06 (RA-09). `Revertir` restaura las bases y después la fase se niega

- **Origen:** la comprobación previa del guion (`Revertir-Actualizacion.ps1:75-88`) solo mira la huella y la primera línea (`# estado=verificada`). Las demás negativas de la fase llegan **después** de restaurar las bases (`:102-118`, luego `:124`).
- **Precondición:** `LAB-D2-G-A2B` (PQ-A instalado y actualizado a PQ-B); fila centinela `LAB-ID-06-POST` en la base de la empresa (después de actualizar); servicios detenidos.
- **Pasos (cada subcaso desde `LAB-D2-G-A2B`):**

| Sub | Cómo se llega | Qué ve el guion antes de restaurar | Qué dice la fase después |
|---|---|---|---|
| a | alterar un byte de un archivo respaldado dentro de `.anterior` (como RS-04e); la huella del **manifiesto** no cambia | huella y estado correctos | "Huella SHA-256 distinta en la copia previa" (4) |
| b | quitar el `# copia=` de la segunda línea y recalcular nada (la huella cambia, así que el guion lo detiene antes) | huella distinta: se detiene | n/a: **control** de que la huella del manifiesto protege esta ruta |
| c | `.anterior` con dueño `gpos-lab-usuario` (RS-05a) | huella y estado correctos | `MotivoCarpeta`: dueño (4) |
| d | `destino\api` como unión (RS-05e) | huella y estado correctos | "es un punto de reanálisis" (4) |

- **Esperado hoy [V/I]:** en a, c y d el guion pide `RESTAURAR`, restaura las bases (la fila `…-POST` **desaparece**), llama a la fase y esta se niega; el guion termina con el mensaje de `:127` ("Las bases ya se restauraron pero los binarios … NO son los anteriores"). El destino de los binarios queda **intacto** (la fase falla cerrada); la pérdida es la de las bases y la actualización marcada `respaldada`, no `revertida`.
- **Esperado (el correcto):** una verificación previa (`--solo-comprobar`, la propuesta de A para R-05/RA-09) que corre los pasos 1 a 3 de la fase **antes** de `RESTAURAR` y detiene el guion sin tocar las bases.
- **Rechazo:** **Baja** (RA-09; falla cerrada para los binarios): bases restauradas y binarios no. **Media:** si además el guion marca `revertida` o inicia servicios. **Alta:** los binarios sí se restauran desde una copia que la fase debía rechazar.
- **Control negativo:** b (la huella protege) y RV-01 (todo coincide y restaura). La fila `…-POST` ausente/presente es el instrumento.
- **Evidencia:** salida del guion, fila centinela, `Snap`, `actualizacion.json` (solo `Estado`). **Duración:** 35 min. **Marca:** [V] por lectura (`:75-127`); [I] el resultado.

### LAB-ID-07 (RA-10). Arrancar el DEMO con `.aplicando` presente

- **Origen:** `Iniciar-Demo.ps1:67-77` arranca los servicios y **después** corre `comprobar-servidor`; nadie mira `.aplicando`.
- **Precondición:** estado con `.aplicando` presente: RV-08a (falla de la fase de servicios) o RS-06 (restauración interrumpida). Servicios detenidos.
- **Pasos:** (1) `.\Iniciar-Demo.ps1`; anotar si arranca, con qué versión (`/api/salud`, `ProductVersion`) y si `comprobar-servidor` da FALLA. (2) `Detener-Demo.ps1`. (3) Variante: `Start-Service GPOS.Reportes` directo (el usuario que instala puede, `SddlServicios.cs:36`).
- **Esperado (el correcto):** `Iniciar-Demo.ps1` se niega antes de `Iniciar-ServiciosDemo` ("hay una restauración o actualización a medias: ejecute `--fase restaurar` o reinstale"); la API y reportes de largo plazo se niegan a arrancar con la marca (R-04 (a) de A). **Hoy [V]:** arranca.
- **Rechazo:** **Media** (P-D2-02): el DEMO arranca sobre binarios mezclados. **Alta:** atiende peticiones con una mezcla de DLL de dos versiones.
- **Control negativo:** `Iniciar-Demo.ps1` con el destino sano (RV-01 paso 8) arranca. **Duración:** 15 min. **Marca:** [V] por lectura; [I] el resultado.

### LAB-ID-08 (RA-05, en `Revertir`). `Iniciar-Demo` en una segunda ventana durante `Revertir`

- **Precondición:** `LAB-D2-G-A2B` con `relleno.bin` de 400 MB en los paquetes (alarga la ventana); sesión del usuario que instala sin elevar (`runas /trustlevel:0x20000`); servicios detenidos.
- **Pasos:** (1) consola elevada: `.\Revertir-Actualizacion.ps1 -Marca <última> -RestaurarBases`; teclear `RESTAURAR`. (2) En cuanto el guion imprima que va a restaurar los binarios (paso de `:124`), desde la sesión sin elevar: `Start-Service GPOS.Reportes` o `Iniciar-Demo.ps1`. (3) Anotar código y texto de la fase, archivos que fallaron por uso compartido, si el servicio quedó corriendo, `.aplicando`, `CompararManifiesto` contra PQ-A y la versión del proceso. Detener lo que arrancó. Repetir 3 veces con otros tiempos.
- **Esperado (el correcto):** el servicio no puede iniciarse durante la fase (inicio `Disabled` temporal o sin el derecho `RP`), o el guion lo detecta y no dice "Reversión hecha". **Esperado según el código [I]:** el servicio arranca con un conjunto mezclado y la fase sale con 4 y "No inicie los servicios" cuando ya está iniciado.
- **Rechazo:** **Media:** servicio atendiendo con binarios mezclados; "Reversión hecha" con `.aplicando` presente. **Alta:** `revertida` anotado con el destino mezclado.
- **Control negativo:** sin lanzar el arranque, RV-01; el arranque posterior a la fase no cuenta (el control del instrumento de RS-12a).
- **Duración:** 30 min (mejor esfuerzo; si en 3 intentos no se logra la ventana, `No se pudo`, nunca `Cumple`). **Marca:** [I]; el diseño es [V] por lectura.

### LAB-ID-09 (RA-04). PowerShell de 32 bits

Es LAB-RV-09 **sin cambio** (RA-04 sigue abierto en `812d1790`: `Actualizar-Demo.ps1:151` y `Revertir-Actualizacion.ps1:80`). Control añadido: `Instalar-Demo.ps1` desde 32 bits **no** depende de `$env:ProgramFiles` (grep vacío) pero la fase `carpetas` y `servicios` corre en el `GPOS.Migracion.exe` de 64 bits; el caso anota si en 32 bits la instalación llega a 1b igual que en 64 (si no, es hallazgo nuevo). Rechazo y duración: los de RV-09.

## 6. Resumen de severidades que propongo

| ID | Hoy [V/I] | Severidad si no se corrige |
|---|---|---|
| O-1 (ID-00, ID-02, RS-10h) | el modo de servicios no pasa de 1b | **Media** hoy (BORRADOR no se entrega); **Alta** si queda así cuando A termine el instalador de servicios |
| O-2 (RS-10f) | Baja; **Media** en f2 y f7 | f2 (cambia el paquete) y f7 (cambia la huella R-01) son los que justifican exigir el error |
| O-3 (RS-10g) | Baja | sube a Media solo si un valor mal formado restaurara (no lo hace hoy) |
| RA-01 (ID-04) | cerrado en `812d1790` | Media si reaparece |
| RA-02 (ID-05), RA-04 (ID-09), RA-05 (ID-08), RA-10 (ID-07) | abiertos | Media (RA-02, RA-04, RA-05, RA-10) |
| RA-08 (RS-10i), RA-09 (ID-06) | abiertos | Baja |

## 7. Orden de ejecución propuesto

1. **Antes de la corrección de A** (línea base, desde `812d1790`): RS-10f, RS-10g, RS-10h (≈ 35 min) e ID-02 hasta 1b (≈ 20 min). Fija "hoy" para comparar.
2. **Después de la corrección de A** (rama que entregue el 28-oct): repetir las mismas; ID-00 como prueba de unidad en la integración.
3. ID-04 a ID-09 en S7 (nivel G), junto a RV-01 a RV-09. **Primero** ID-02 (el instalador debe poder instalar), después los demás.
4. Si falta tiempo: RS-10h, RS-10g, ID-02 (tramo 1b) e ID-04, en ese orden.

## 8. Dudas para B y A

- **D-1 (A).** La corrección de O-1, **¿quitar `--origen` del guion (lo previsto) o aceptar `--origen` en `carpetas`?** Los casos RS-10h e ID-02 se fijan a la decisión. Recomiendo quitarlo del guion: `carpetas` no lee el paquete y aceptar una opción sin efecto es lo que O-2 y O-3 critican.
- **D-2 (B).** ¿Los PQ-A y PQ-B de `Preparar-Paquetes` sirven para correr `Instalar-Demo.ps1`, o hay que publicar con `Publicar-PaqueteDemo.ps1 -ConApiReportes` desde `a/pr-d2-manifiesto` y extraer completo (con guiones, `herramientas\`, `app\web`)? Sin eso, ID-02 a ID-09 no tienen paquete.
- **D-3 (A).** O-2: ¿las banderas repetidas (`--rotar-jwt --rotar-jwt`) se rechazan o se toleran? La opción repetida con valor, ¿error siempre o solo cuando los valores difieren? Propongo error siempre (más simple y verificable).
- **D-4 (A, B).** O-3: ¿la huella se normaliza a minúscula en `Argumentos` o se exige ya en minúscula? Hoy `FaseRestaurar` ignora mayúsculas y `Get-FileHash …ToLowerInvariant()` del guion produce minúscula; propongo aceptar ambas y normalizar.
- **D-5 (B).** ¿`Probar-InstalarDemo.ps1` nuevo o todo en `Probar-Restaurar.ps1`? (Ver §0 punto 4.) Propongo lo primero, **escrito después** de la corrección de A.
- **D-6 (B).** La rama `a/instalador-o1-o3` no es la corrección de O-1/O-3 de esta tanda (es ADR-77); si B esperaba que lo fuera, conviene avisar a A del malentendido de nombres.

### Cierre
- Estado: Completado (casos redactados; nada ejecutado)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-24-casos-instalar-demo-o1-o3.md`
- Supuestos: la ruta de los guiones es `instalador/Demo/scripts/`; `Instalar-Demo.ps1` en `812d1790` es la versión con el BORRADOR; los textos de error de las correcciones de A son propuestas mías (los casos se ajustan a sus textos reales); [I] marcados por confirmar en VM-SRV
- Decisiones candidatas a ADR: ninguna
- Entregas a otros agentes: A → corregir O-1 (`Instalar-Demo.ps1:127`), O-2 y O-3 y decidir D-1, D-3, D-4; B → D-2 y D-5, y operar la VM; C (yo) → escribir RS-10f/g/h/i en `Probar-Restaurar.ps1`, `Probar-InstalarDemo.ps1` y ID-00 cuando A fije la corrección
- Próximo paso recomendado: B y A responden D-1 y D-2; yo escribo ID-00 y las ampliaciones de `Probar-Restaurar.ps1`
