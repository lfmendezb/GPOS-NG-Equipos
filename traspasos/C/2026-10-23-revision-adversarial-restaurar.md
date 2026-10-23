Para: B (copia a A)        De: C        Fecha: 2026-10-23
Tipo: Revisión adversarial (encargo B-a-C/2026-10-23-tareas-nuevas-para-c-5, tarea 5 (a), opcional)
Prioridad: Media
Repositorio y rama: lfmendezb/GPOS-NG `a/pr-d2-manifiesto` @ cd44043c (solo lectura)
Estado: Abierto

Convención: [V] = lo comprobé con un comando y su resultado en mi equipo; [I] = inferido del código o de la documentación. El árbol es el worktree de C en cd44043c (desacoplado). No cambié el PR, no lo comenté y no empujé nada. Las pruebas nuevas son un archivo temporal sin commit (`tests/GPOS.Tests/Servidor/RestaurarRevisionCTests.cs`, 3 casos); copia en `traspasos/C/2026-10-23-revision-adversarial-restaurar-pruebas.cs.txt`. No usé SQL: todas son `Esquema=Neutral` contra `SistemaServidorFalso`. Una sola compilación.

Punto de partida: la revisión de A (`traspasos/A/revision-seguridad-fase-restaurar-2026-10-23.md`, R-01 a R-09) se hizo sobre `f1b2374d`. cd44043c responde a R-01 (huella del manifiesto de `.anterior` anotada por `Actualizar-Demo` y exigida por `Revertir` y por la fase), a R-03 (solo `destino\api` y `destino\reportes` como punto de reanálisis) y a R-05 (comprobación previa en el guion). Esta revisión busca lo que esa revisión no cubrió y lo que el arreglo dejó abierto.

# Veredicto

**Aprobado con observaciones** (recomendación técnica; la decisión es del propietario, C2). No hay Críticos ni Altos. Hay **tres Medias**: dos agujeros en la forma en que cd44043c ata la copia previa (RA-01 y RA-02, que reproducen por otro camino el estado mezclado que R-01 quería cerrar, sin atacante y por uso normal) y el arreglo parcial de R-03 (RA-03). Recomiendo resolver RA-01 y RA-02 antes de unir: el arreglo es barato (≈0,15 dp) y es el mismo que deja de depender de `$env:ProgramFiles` (RA-04).

# 1. Alcance y superficie revisada

- `src/GPOS.Migracion/Servidor/FasesImplantacion/FaseRestaurar.cs` completo (153 líneas en cd44043c).
- `FaseServicios.cs`: `CopiarBinarios` (`:289-406`), `InterpretarManifiesto`, `ComponenteValido`, `DestinoNormalizado`, `TextoManifiesto`, `DestinoIntegro`, `CrearCarpetaProtegida`.
- `SistemaServidorWindows.cs`: `CarpetaProgramas` (`:46`), `LeerCarpeta` (`:111-140`), `BorrarCarpeta` (`:168`), `ListarArchivos` (`:170-173`), `LeerTexto`/`EscribirTexto`/`HuellaSha256` (`:175-184`), `CopiarSinReanalisis` (`:192-233`), `BorrarArchivo` (`:250`).
- `ComandoImplantarServidor.cs` (`Incoherencia`, `:58-75`) y la opción nueva `--huella-copia-previa`.
- Guiones: `Revertir-Actualizacion.ps1` completo, `Actualizar-Demo.ps1` (`:146-166`), `Iniciar-Demo.ps1` (`:67-77`), `herramientas/Comun-Demo.ps1` (`Invoke-Migracion`, `Iniciar-ServiciosDemo`).
- Pruebas del PR: `tests/GPOS.Tests/Servidor/RestaurarServidorTests.cs`.

Modelo de amenaza: el del blueprint (sección 4). El administrador local hostil queda fuera, así que lo que exige escribir en Archivos de programa se califica como defensa en profundidad (DiP). El usuario que instala **sí** está dentro: tiene derecho de inicio de los servicios (`SddlServicios.cs:36`, citado por A).

# 2. Corridas [V]

| Corrida | Filtro | Resultado |
|---|---|---|
| cd44043c + mis 3 pruebas, compilación de `tests/GPOS.Tests` en Debug (correcta, 27 advertencias previas) | `FullyQualifiedName~GPOS.Tests.Servidor.RestaurarRevisionCTests\|FullyQualifiedName~GPOS.Tests.Servidor.RestaurarServidorTests` | 26 en total: **24 superadas, 2 con error**, 275 ms. Las 23 de `RestaurarServidorTests` pasan. De las mías, RC2 pasa (fija la precondición de RA-02) y **RC1 y RC3 fallan**, cada una por un hallazgo |

Mensajes de las fallas:
- RC1: `Assert.NotEqual() Failure: Strings are equal` (`b1603c6f…` antes y después de la segunda actualización).
- RC3: `fase=restaurar resultado=ok cambios=5`, con «verificados en el destino (4 archivos)», cuando se esperaba el código 4.

No hice mutaciones: el encargo era la segunda revisión adversarial, no la suficiencia de la suite.

# 3. Hallazgos

| ID | Severidad | Título | Prueba |
|---|---|---|---|
| RA-01 | **Media** | Actualizar, revertir y volver a actualizar: la copia previa nueva tiene la misma huella, el guion no la anota y la siguiente reversión deja las bases viejas con los binarios nuevos | RC1 falla [V] |
| RA-02 | **Media** | Si `--fase servicios` falla después de renovar `.anterior`, no se anota la huella y `Revertir` salta los binarios aunque quede `.aplicando` | RC2 [V] y guion [I, con línea] |
| RA-03 | **Media (DiP)** | El arreglo de R-03 solo mira las dos carpetas raíz: una unión en una subcarpeta lleva la escritura fuera del destino y la verificación pasa | RC3 falla [V] |
| RA-04 | Baja | Los guiones calculan la ruta de `.anterior` con `$env:ProgramFiles` y la fase con la carpeta conocida: en una PowerShell de 32 bits no coinciden | [I, con línea] |
| RA-05 | Baja | Carrera: el usuario que instala puede iniciar un servicio entre la comprobación «no está en marcha» y la copia; tampoco hay exclusión entre dos fases | [I, con línea] |
| RA-06 | Baja (DiP) | Los puntos de reanálisis y las variantes de mayúsculas del subárbol son invisibles para los sobrantes y para la verificación final | [I, con línea] |
| RA-07 | Baja | Se lee el manifiesto de la copia previa dos veces: la huella atada no es la del texto que se interpreta | [I, con línea] |
| RA-08 | Baja | `--huella-copia-previa` es opcional: la atadura de R-01 vive en el guion, no en la fase | [I, con línea] |
| RA-09 | Baja | R-05 queda a medias: el guion solo comprueba la huella y el estado; las demás negativas de la fase siguen llegando después de restaurar las bases | [I, con línea] |
| RA-10 | Baja | `Iniciar-Demo` arranca los servicios antes de `comprobar-servidor`, y nadie mira `.aplicando` (complementa R-04 de A) | [V] grep e [I] |

## RA-01 (Media): la misma huella después de revertir y volver a actualizar

**Riesgo.** `Actualizar-Demo.ps1:152` y `:157-159` anotan `HuellaCopiaPrevia` solo si la huella de `.anterior\manifiesto.sha256` **cambió** durante la fase. Ese texto es determinista: la primera línea es `# estado=…` y después vienen las huellas ordenadas (`FaseServicios.cs:364-365` y `:409-410`), escritas en UTF-8 sin BOM (`SistemaServidorWindows.cs:177`). Sigamos esta secuencia:

1. Se actualiza de v1 a v2: `.anterior` guarda v1, `verificada`, y queda la huella H.
2. Se revierte: el destino vuelve a v1 y `.anterior` no se toca.
3. Se vuelve a actualizar a v2: la fase **sí** copia y **sí** renueva `.anterior` (`:343-366`), con v1 y `verificada`. El texto es el mismo byte a byte, así que la huella vuelve a ser H.
4. Como la huella no cambió, el guion avisa «Esta actualización no cambió los binarios de los servicios» (`:163`), lo cual es falso, y no anota nada.
5. Al revertir esa última marca, `Revertir-Actualizacion.ps1:75-77` toma la ausencia de huella como «no los cambió». Restaura las bases a v1, se salta el paso 3 (`:121`) y anota `revertida` (`:146-147`).

El DEMO queda con las bases de v1 y los binarios de v2, que es justo el estado que R-01 quería impedir. La propia ayuda del guion dice que «la base y los programas vuelven juntos» (`:21`). No hace falta atacante: probar una versión, volver atrás y probarla otra vez es un uso normal de un DEMO.

**Prueba.** RC1 (`RC1_Actualizar_otra_vez_tras_revertir_deja_una_copia_previa_con_huella_distinta`) falla [V]: la salida de la fase dice «Copia previa de…» y el destino pasa a «api 2», pero la huella del manifiesto antes y después es la misma.

**Remediación mínima (≈0,1 dp, junto con RA-02 y RA-04).** Que la condición sea «la fase renovó la copia previa», no «la huella cambió». La forma más barata es que `--fase servicios` imprima una línea legible por máquina cuando escribe `.anterior` (por ejemplo `copia-previa-sha256=<huella>`, junto a `FaseServicios.cs:366`) y que el guion anote esa huella. Así, si es igual a la anterior, se anota de todos modos, y es correcto: la copia es idéntica a la que hay que restaurar. Alternativa descartada: meter un nonce o una fecha en la cabecera para forzar una huella distinta. Cambia el formato que leen `FaseRestaurar.cs:67-69` y `Revertir:85` y no resuelve RA-02 ni RA-04.

## RA-02 (Media): falla de `--fase servicios` después de la copia previa

**Riesgo.** `CopiarBinarios` renueva `.anterior` en el paso 2 (`FaseServicios.cs:343-366`) y crea `.aplicando` en el paso 3 (`:377`). Si la copia al destino falla y la vuelta atrás no es completa, la marca queda (`:396-398`) y la fase sale con 4. Entonces `Actualizar-Demo.ps1:155` lanza `Detener-ConError` **antes** de las líneas `:157-161`, y la huella nunca se anota, aunque `.anterior` sí sea de esta actualización. Lo mismo pasa si la consola se cierra o se pulsa Ctrl+C entre el final de la fase y `Set-Content` (`:160`). El mensaje de `:155` remite a `Revertir`, y en `Revertir`:
- `:75-77` declara «no los cambió» y marca `$sinBinarios`;
- el paso 3 no llama a restaurar (`:121`);
- nada mira `.aplicando`: el único texto del guion que la menciona es un comentario (`:123`);
- se anota `revertida` (`:146`).

El destino queda mezclado, con la marca puesta, y la reversión dice «Reversión hecha». Además, la reversión que sí lo arreglaba existía: `--fase restaurar` con la huella de esa `.anterior` retoma y deja todo bien (lo demuestra RC2).

**Prueba.** RC2 pasa [V]:
- `--fase servicios` termina en 4;
- la huella de `.anterior` pasa de `null` a un valor;
- `.aplicando` existe;
- `Restaurar(s, despues)` termina en 0 y quita la marca.

La parte del guion es [I] con las líneas citadas: no ejecuté PowerShell.

**Remediación mínima (≈0,05 dp más sobre RA-01).**
- En `Actualizar-Demo`, anotar la huella que imprimió la fase **antes** de evaluar `$rs.Codigo`.
- En `Revertir`, con servicios: si existe `…\Demo\.aplicando`, no tomar nunca el camino `$sinBinarios`. Pedir la fase restaurar (si hay huella) o detenerse con «reinstale», sin tocar las bases.

## RA-03 (Media, DiP): R-03 solo está arreglado en la raíz

**Riesgo.** El arreglo (`FaseRestaurar.cs:49-52`) comprueba `destino\api` y `destino\reportes`, pero no sus subcarpetas, que A también pedía («y cada subcarpeta», remediación de R-03). Las publicaciones reales tienen subcarpetas (`runtimes\…`, `wwwroot\…`). Con una unión en `destino\api\runtimes`:
- `ListarArchivos` la salta (`SistemaServidorWindows.cs:172`, `AttributesToSkip = ReparsePoint`), así que no hay sobrantes allí;
- `CopiarSinReanalisis(previa\api\runtimes\x.dll, destino\api\runtimes\x.dll)` valida solo el **origen** (`:195-220`). Abre el destino con `FileMode.Create` (`:223`), lo que sigue la unión y escribe como administrador fuera de Archivos de programa [I, semántica de `CreateFile`];
- la verificación posterior (`FaseRestaurar.cs:126`) usa `HuellaSha256` con `File.OpenRead` (`:182`), que sigue la misma unión, y por eso pasa.

`Directory.CreateDirectory(Path.GetDirectoryName(destino))` (`:221`) tampoco lo detecta. `CopiarBinarios` comparte el patrón (`FaseServicios.cs:384`, `File.Copy` con sobrescritura). Crear la unión exige escribir en Archivos de programa, de ahí que sea DiP; el impacto (escritura arbitraria como administrador) es alto.

**Prueba.** RC3 falla [V]. Puse en el doble `Carpetas[destino\api\runtimes]` como punto de reanálisis y un archivo de esa subcarpeta en el manifiesto de la copia previa. La fase termina con `resultado=ok` y «verificados en el destino (4 archivos)».

**Remediación mínima (≈0,2 dp).** La de A, completa:
- antes de escribir, recorrer cada carpeta del subárbol con `LeerCarpeta` (que ya detecta la unión y la ruta final distinta, `:122-127`) sin saltar los puntos de reanálisis, y detenerse con cualquiera;
- abrir el **destino** con `FILE_FLAG_OPEN_REPARSE_POINT` y comprobar la ruta final y el número de vínculos del identificador, igual que se hace con el origen; o borrar y crear el archivo, con `CREATE_NEW`, lo que además resuelve la DACL heredada que señaló A.

## RA-04 (Baja): `$env:ProgramFiles` en los guiones frente a la carpeta conocida en la fase

**Riesgo.** La fase usa `Environment.GetFolderPath(SpecialFolder.ProgramFiles)` (`SistemaServidorWindows.cs:46`, `DisposicionServidor.cs:88`). Los guiones construyen la ruta de `.anterior` con `$env:ProgramFiles` (`Actualizar-Demo.ps1:151`, `Revertir-Actualizacion.ps1:80`). En una PowerShell de 32 bits («Windows PowerShell (x86)») la variable vale `C:\Program Files (x86)` [I, comportamiento de WOW64; no pude ejecutar la PowerShell de 32 bits porque el entorno del agente lo bloqueó]. Mientras tanto, `GPOS.Migracion.exe` de 64 bits sigue escribiendo en `C:\Program Files`. Lo que pasa entonces:
- en `Actualizar`, `$huellaAntes` y `$huellaDespues` son `$null`, no se anota nada y sale el aviso falso de RA-01;
- en `Revertir`, el resultado es el estado mezclado de RA-01;
- una variable `ProgramFiles` de usuario (`HKCU\Environment`) tendría el mismo efecto [I]. Esa vía requiere un proceso del usuario que instala, que según R-02 ya tiene caminos más fuertes.

**Remediación.** Desaparece con la de RA-01: el guion no calcula la ruta y toma la huella de la salida de la fase. Si se conserva el cálculo, usar `$env:ProgramW6432` o negarse con `-not [Environment]::Is64BitProcess`.

## RA-05 (Baja): carrera con el arranque del servicio y entre fases

**Riesgo.** La fase comprueba que los ejecutables no estén en marcha (`FaseRestaurar.cs:45-47`) y empieza a copiar mucho después (`:95-120`), tras leer y calcular las huellas de toda la copia previa. El usuario que instala puede iniciar los servicios sin elevación (`SddlServicios.cs:36`, `RPWP`), y basta con abrir `Iniciar-Demo` en otra ventana. En ese hueco, el `.exe` y las DLL ya cargadas fallan por uso compartido y las que se cargan después se sobrescriben. El servicio queda corriendo sobre un conjunto mezclado y la fase sale con 4 y el aviso «No inicie los servicios», cuando ya están iniciados. Tampoco hay exclusión entre fases (no hay `Mutex` en `src/GPOS.Migracion/Servidor`, [V] grep). Si `restaurar` encuentra la `.aplicando` que acaba de crear un `servicios` concurrente (`FaseServicios.cs:377`), la toma como «retoma» (`FaseRestaurar.cs:80`, `:91`) y copia encima. Esto último exige dos consolas de administrador: es un error de operación, no un ataque.

**Remediación (≈0,2 dp).** Durante el paso 4, poner los servicios en inicio `Disabled` (`ChangeServiceConfig`) y devolver el tipo de inicio al terminar, o quitar temporalmente `RP` del SDDL del usuario que instala. Además, un mutex con nombre `Global\GPOS.ImplantarServidor` alrededor de toda fase que escriba en el destino.

## RA-06 (Baja, DiP): lo que el subárbol esconde a sobrantes y verificación

**Riesgo.** Lo que queda en el subárbol sin listarse no es sobrante, no se borra, y la verificación final (`FaseRestaurar.cs:126-127`) no lo ve. Eso incluye un vínculo simbólico de archivo (por ejemplo `api\extra.dll`) y una carpeta de unión, por el `AttributesToSkip = ReparsePoint` de `SistemaServidorWindows.cs:172`. Lo mismo pasa con las variantes de mayúsculas en una carpeta con distinción de mayúsculas activada (`fsutil file setCaseSensitiveInfo`): las huellas usan `OrdinalIgnoreCase` (`FaseServicios.cs:151`) y `SobrantesDelDestino` compara con `ContainsKey` (`FaseRestaurar.cs:139`), así que `GPOS.API.dll`, junto a `GPOS.Api.dll`, pasa por «conocido». En `CopiarBinarios` esos archivos tampoco entran en `actuales` (`FaseServicios.cs:346`), y la copia previa puede salir `verificada` con ellos presentes. El cargador de .NET resuelve por el nombre exacto de `deps.json`, así que el impacto práctico de la variante de mayúsculas es bajo [I]. Ambos casos exigen escribir en Archivos de programa.

**Remediación.** La misma de RA-03, aplicada también al listado: no saltar los puntos de reanálisis, sino detenerse. Comparar los sobrantes con `Ordinal`, o rechazar las carpetas con la marca de distinción de mayúsculas.

## RA-07 (Baja): dos lecturas del manifiesto de la copia previa

**Riesgo.** El texto se lee en `FaseRestaurar.cs:59` (`LeerTexto`) y la huella atada se calcula volviendo a abrir el archivo en `:63` (`HuellaSha256`). La huella comprobada no es necesariamente la del texto que se interpreta en `:66-73`. A eso se suma la tercera lectura del guion (`Revertir:81`). Exige ser administrador; es un TOCTOU del mismo tipo que R-06.

**Remediación (≈0,05 dp).** Leer los bytes una vez, calcular la huella sobre esos bytes y decodificarlos desde el mismo búfer.

## RA-08 (Baja): la atadura es opcional en la fase

**Riesgo.** Sin `--huella-copia-previa`, `FaseRestaurar.cs:62` se salta la comprobación de R-01. El propio mensaje de `FaseServicios.cs:305-306` manda a ejecutar «--fase restaurar» a mano, sin la opción, y lo mismo indica la ayuda de `Program.cs`. Para retomar una `.aplicando` eso es lo correcto, pero quien siga el mensaje a mano después de una actualización «al día» devolverá binarios de N-2, que es el caso original de R-01.

**Remediación.** Exigir `--huella-copia-previa` salvo cuando exista `.aplicando` (retoma), o que el mensaje de `:305` y la ayuda la incluyan.

## RA-09 (Baja): R-05 queda a medias

**Riesgo.** La comprobación previa del guion (`Revertir:79-88`) solo mira la huella y la primera línea. Las demás negativas de la fase se siguen conociendo después de restaurar las bases (`:102-118`):
- huellas distintas en la copia previa (`FaseRestaurar.cs:74-76`);
- manifiesto que `InterpretarManifiesto` rechaza (`:72-73`, el caso R-08);
- DACL de `.anterior` (`:58`);
- R-03 (`:50-52`);
- antepasados (`:37-42`).

El mensaje de `:127` lo reconoce. Es una falla cerrada en cuanto a la integridad de los binarios.

**Remediación.** La de A: un modo `--solo-comprobar` (pasos 1 a 3 de la fase, sin escribir) que el guion llame antes de `RESTAURAR`. Con eso sobra el cálculo en PowerShell, y también RA-04.

## RA-10 (Baja): nada impide arrancar con `.aplicando`, y el orden de `Iniciar-Demo` lo empeora

**Riesgo.** Complementa R-04 de A, que sigue abierto en cd44043c. Hay dos datos nuevos:
- `Iniciar-Demo.ps1:70-73` llama a `Iniciar-ServiciosDemo` (`Start-Service`, `Comun-Demo.ps1:406`) **antes** de `comprobar-servidor`, así que una comprobación que mirara `.aplicando` llegaría tarde;
- `.aplicando` solo aparece en `FaseRestaurar.cs` y `FaseServicios.cs` dentro de `src/GPOS.Migracion` ([V] `grep -rl aplicando src/`; las otras dos coincidencias son ajenas: `SqlMigracionesOla3b.cs` y `Bandeja.cs`).

Ni el guion ni la comprobación la miran, y RA-02 deja precisamente ese estado.

**Remediación (≈0,05 dp, inmediata en el guion).** En `Iniciar-Demo`, con servicios, negarse si existe `…\Demo\.aplicando`, antes de `Iniciar-ServiciosDemo`. A más largo plazo, la (a) de R-04: que la propia API y la de reportes se nieguen a arrancar con la marca.

# 4. Lo que revisé y no es hallazgo

- **Rutas largas, UNC y de dispositivo.** `DestinoNormalizado` exige el prefijo de Archivos de programa sobre `Path.GetFullPath` (`FaseServicios.cs:205-214`): rechaza las rutas UNC, las que empiezan por `\\?\` o `\\.\`, la forma 8.3 (`PROGRA~1`), `Program Files (x86)` y los `..` que salen de la carpeta. .NET admite rutas largas sin `\\?\`. Sin hallazgo [I].
- **Flujos alternativos (ADS).** Los nombres del manifiesto no admiten `:` (`:159`), así que ninguna ruta del manifiesto apunta a un flujo. La huella y la copia cubren el flujo principal, que es el que carga el CLR. Que `FileMode.Create` conserve o no los flujos con nombre de un archivo existente no cambia lo que se ejecuta [I]. No aplica.
- **Valor de `--huella-copia-previa`.** No se valida el formato, pero un valor vacío o mal formado nunca coincide con una huella real y la fase se detiene (`:62-65`): falla cerrada. La opción se rechaza fuera de `restaurar` (`ComandoImplantarServidor.cs:61`).
- **Vínculos físicos y reanálisis en `.anterior`.** Bien: `CopiarSinReanalisis` rechaza el origen con más de un vínculo, con un punto de reanálisis o con una ruta final distinta (`SistemaServidorWindows.cs:200-220`), y `.anterior` pasa por `MotivoCarpeta` (`FaseRestaurar.cs:58`).
- **Abrir `.anterior` desde el guion.** `Get-FileHash` y `Get-Content` siguen los vínculos, pero solo son una comprobación previa: la fase vuelve a comprobar todo con sus propias llamadas.
- **Revertir sin `comprobar-servidor` (R-09 de A).** Sigue igual en cd44043c (`Revertir:120-149`). No lo cuento de nuevo.

# 5. Estado en cd44043c de los hallazgos de A

| A | Estado en cd44043c |
|---|---|
| R-01 | Atado por la huella del manifiesto, con los dos agujeros RA-01 y RA-02. La opción (a) de A (renovar `.anterior` en el camino «al día») no se hizo; con la atadura no hace falta |
| R-02 | Sin cambio (va a B y al propietario) |
| R-03 | Parcial: solo las carpetas raíz (RA-03, RA-06) |
| R-04 | Sin cambio; RA-10 lo complementa |
| R-05 | Parcial (RA-09) |
| R-06, R-07, R-08, R-09 | Sin cambio |

# 6. Remediaciones priorizadas

1. **RA-01 + RA-02 + RA-04, antes de unir (≈0,15 dp):**
   - la fase de servicios imprime `copia-previa-sha256=<huella>` cuando escribe `.anterior`;
   - `Actualizar-Demo` la anota siempre que aparezca, antes de mirar el código de salida;
   - `Revertir` no toma el camino «sin binarios» si existe `.aplicando`.
2. **RA-10 (≈0,05 dp):** `Iniciar-Demo` se niega con `.aplicando` antes de `Start-Service`.
3. **RA-03 + RA-06 (≈0,2 dp):** validar el subárbol completo y abrir el destino sin seguir puntos de reanálisis. También cubre `CopiarBinarios`.
4. **RA-09 (≈0,2 dp):** `--solo-comprobar` antes de restaurar las bases.
5. **RA-05, RA-07, RA-08:** ajustes pequeños (≈0,25 dp en total).

Casos para el laboratorio de PR-D2 (tarea 2 de esta tanda): agrego en `LAB-xx`:
- la secuencia de RA-01 (actualizar, revertir, actualizar, revertir);
- la falla de RA-02 (archivo bloqueado durante `--fase servicios`);
- el caso de RA-04 (PowerShell x86);
- la carrera de RA-05 (`Iniciar-Demo` en una segunda ventana durante `Revertir`).

### Cierre
- Estado: Aprobado con observaciones
- Artefactos:
  - `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-23-revision-adversarial-restaurar.md`
  - `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-23-revision-adversarial-restaurar-pruebas.cs.txt`
  - archivo temporal sin commit en el worktree de C: `tests\GPOS.Tests\Servidor\RestaurarRevisionCTests.cs`
- Supuestos:
  - modelo de amenaza del blueprint (sección 4);
  - son [I] y no los ejecuté: el comportamiento de WOW64 con `$env:ProgramFiles` (RA-04), la semántica de `FileMode.Create` y `File.OpenRead` sobre una unión (RA-03) y la de los ADS;
  - la parte de PowerShell de RA-01 y RA-02 es razonamiento con línea; la parte de la fase está demostrada con el doble.
- Decisiones candidatas a ADR: ninguna nueva (RA-10 refuerza la candidata R-04 (a) de A).
- Entregas a otros agentes:
  - desarrollador backend (A): RA-01 (salida de la fase), RA-03, RA-05 a RA-08;
  - devops / guiones del DEMO (B): RA-01, RA-02 y RA-04 en `Actualizar-Demo` y `Revertir`, RA-09 y RA-10;
  - qa (C, yo): incorporar los cuatro casos a los LAB de PR-D2.
- Próximo paso recomendado: corregir RA-01 y RA-02 en `a/pr-d2-manifiesto` y volver a correr RC1 y RC2 (RC1 debe pasar si el guion anota la huella impresa por la fase; la prueba habrá que adaptarla a esa salida).
