# Informe de seguridad: `implantar-servidor --fase restaurar` (PR-D2)

Fecha: 2026-10-23 · Revisor: auditor-seguridad (solo lectura, sin cambios de código) · Commit: `f1b2374d` en `GPOS-NG-prd2`, rama `a/pr-d2-manifiesto`
Blueprint: `traspasos/A/blueprint-pr-d2-fase-restaurar-2026-10-23.md` (el evento 5140 que propone no se usa: se reutiliza `FaseCompletada` 5135).

## 1. Alcance y superficie revisada

- `src/GPOS.Migracion/Servidor/FasesImplantacion/FaseRestaurar.cs` (nuevo, 143 líneas).
- `FaseServicios.cs`: `CopiarBinarios` (copia previa con `manifiesto.sha256` y `# estado=`), `DestinoIntegro`, `InterpretarManifiesto`, `ComponenteValido`, `DestinoNormalizado`, escritura de `manifiesto.instalado.sha256`.
- `SistemaServidorWindows.cs`: `LeerCarpeta`, `ListarArchivos`, `CopiarSinReanalisis`, `BorrarArchivo`, `BorrarCarpeta`, `EscribirTexto`, `EjecutableEnMarcha`.
- `ComandoImplantarServidor.cs` (opciones, eventos 5135 y de guarda, salida).
- `instalador/Demo/scripts/Revertir-Actualizacion.ps1` (modo Servicios), con `Actualizar-Demo.ps1`, `Detener-Demo.ps1` y `herramientas/Comun-Demo.ps1` como contexto.
- Superficie: un proceso elevado (administrador) que escribe y borra en `%ProgramFiles%\GPOS NG\Demo` binarios que luego corren como servicio con cuenta virtual; el usuario que instala puede iniciar y detener esos servicios (SDDL DM-09, `SddlServicios.cs:35-36`).

Modelo de amenaza aceptado en el blueprint (sección 4): un administrador local hostil queda fuera; los controles cubren cambio de dueño, reanálisis, error y estado mezclado. Los hallazgos que exigen derechos de administrador se califican como defensa en profundidad.

Pruebas ejecutadas: `dotnet test --no-build --filter FullyQualifiedName~RestaurarServidorTests` → 20 correctas, 0 fallidas (sobre los binarios ya compilados en `bin\Debug`; no recompilé, así que no confirmo que correspondan exactamente a `f1b2374d`).

## 2. Resumen de hallazgos

| ID | Severidad | Título | Estado |
|---|---|---|---|
| R-01 | Media | La copia previa `.anterior` no está atada a la actualización que se revierte: puede devolver binarios de dos versiones atrás | Verificado (lectura de código) |
| R-02 | Media | El guion elevado ejecuta `GPOS.Migracion.exe` y los `.ps1` de la carpeta del DEMO, en la que escribe el usuario que instala | Verificado (anterior al commit; este commit agrega un camino elevado más) |
| R-03 | Media | El subárbol del destino (`api\`, `reportes\` y sus subcarpetas, y cada archivo) no se valida: un punto de reanálisis en él hace que el borrado de sobrantes y la escritura salgan del destino | Verificado en código; el seguimiento de la unión en la raíz por `EnumerateFiles` es inferido |
| R-04 | Media | Un fallo a mitad (o una huella distinta) deja en el destino bytes no verificados, y nada impide iniciar el servicio con la marca `.aplicando` | Verificado |
| R-05 | Baja | El guion restaura las bases antes de saber si la fase aceptará la copia previa, y la primera reversión tras desplegar este cambio siempre se niega | Verificado |
| R-06 | Baja | `verificada` se decide contra `manifiesto.instalado`, pero las huellas que se guardan no se comparan con ese manifiesto (ventana TOCTOU) | Verificado |
| R-07 | Baja | `.aplicando` no se valida (dueño, reanálisis, que sea carpeta) antes de borrarla al retomar | Verificado; el comportamiento de `Directory.Delete` sobre una unión es inferido |
| R-08 | Baja | Nombres legítimos que `ComponenteValido` rechaza dejan la copia previa sin poder restaurarse (falla cerrada, solo disponibilidad) | Verificado |
| R-09 | Baja | El guion no corre `comprobar-servidor --sin-red` tras restaurar, como pide el blueprint (sección 5) | Verificado |

No hay hallazgos Críticos ni Altos.

## 3. Checklist OWASP

| Punto | Resultado |
|---|---|
| A01 Control de acceso | Fase restringida a perfil demo y a proceso elevado (`ComandoImplantarServidor.cs:23-26`); `.anterior` con DACL solo SYSTEM y administradores (`SddlServicios.cs:23`). Ver R-02 y R-04. |
| A02 Criptografía | SHA-256 en cada archivo, en origen y en destino. Correcto. Las huellas no están firmadas: protegen la integridad frente a errores, no frente a un administrador (aceptado en el blueprint). |
| A03 Inyección | No aplica: no hay SQL ni comandos compuestos en la fase. Las rutas del manifiesto se validan (`FaseServicios.cs:159-160`, `189-199`). |
| A04 Diseño inseguro | R-01, R-04, R-05. |
| A05 Configuración | R-03 (descriptores del subárbol), R-07. |
| A06 Componentes vulnerables | No aplica: el commit no agrega dependencias. |
| A07 Autenticación | No aplica. |
| A08 Integridad de software y datos | Núcleo de la revisión: R-01, R-03, R-04, R-06. Controles buenos en la sección 5. |
| A09 Registro y monitoreo | Evento 5135 en éxito o error y evento de guarda en «Detenido» (`ComandoImplantarServidor.cs:48-53`); el guion anota en `actualizacion.log` y `migracion.log`. Sin secretos. |
| A10 SSRF | No aplica. |

## 4. Hallazgos

### R-01 (Media): `.anterior` no está atada a la actualización que se revierte

**Riesgo.** El guion solo deja revertir la última marca de `respaldos\` (`Revertir-Actualizacion.ps1:63-65`), pero el contenido de `.anterior` no dice a qué marca pertenece. `.anterior` solo se renueva cuando `CopiarBinarios` copia de verdad; si el destino ya coincide con el paquete, la fase sale «al día» sin tocar `.anterior` (`FaseServicios.cs:292-300`). Lo mismo ocurre si `--fase servicios` falla antes del paso 2 (preparación con huella distinta, `FaseServicios.cs:329-333`): el registro de la actualización ya existe (`Actualizar-Demo.ps1:131`, estado `respaldada`) y `.anterior` sigue siendo la de la actualización anterior. En ambos casos, revertir la última marca devuelve las bases a la versión N-1 y los binarios a la N-2. La ayuda del propio guion dice que la API solo trabaja con la versión exacta de esquema (`Revertir-Actualizacion.ps1:21`): el resultado probable es un DEMO que no arranca o, peor, binarios viejos sobre un esquema más nuevo. No requiere atacante; es integridad y disponibilidad.

**Remediación mínima (≈0,3 dp).** (a) En el camino «al día» de `CopiarBinarios`, renovar `.anterior` con lo que hay en el destino (o borrarla), para que `.anterior` siempre sea «lo que había antes de la última pasada»; y (b) atarla a la marca: `--fase servicios` imprime la huella SHA-256 del `manifiesto.sha256` de `.anterior` que dejó, `Actualizar-Demo.ps1` la guarda en `actualizacion.json`, y `Revertir-Actualizacion.ps1` se la pasa a `--fase restaurar` (opción nueva, p. ej. `--copia-esperada <sha256>`), que se detiene si no coincide. Alternativa descartada: una línea `# marca=` dentro del manifiesto, porque obliga a pasar la marca del guion a la fase de servicios y no cubre el caso «al día» sin (a).

### R-02 (Media): ejecución elevada desde una carpeta en la que escribe el usuario que instala

**Riesgo.** Con servicios, `Revertir-Actualizacion.ps1` exige consola de administrador (`:42`) y luego ejecuta `app\migracion\GPOS.Migracion.exe` de la carpeta del DEMO (`Comun-Demo.ps1:236-243`), además de cargar con dot-sourcing `herramientas\Comun-Demo.ps1` (`Revertir-Actualizacion.ps1:37`) y llamar a `Detener-Demo.ps1` (`:81`). Esa carpeta da control total al usuario que instala (`Comun-Demo.ps1:118-121`). Cualquier proceso que corra con el token no elevado de ese usuario puede reemplazar el ejecutable o un guion y obtener ejecución como administrador la próxima vez que se revierta. Así, la cadena de integridad de la fase (DACL de `.anterior`, huellas, `CopiarSinReanalisis`) depende de un ejecutable que se puede cambiar sin elevación. El patrón ya existía en `Instalar-Demo.ps1` y `Actualizar-Demo.ps1` (`:149`); este commit agrega un camino elevado más. En el DEMO el usuario que instala suele ser el mismo administrador, así que el impacto práctico es saltarse UAC.

**Remediación mínima.** Antes de elevar o de llamar a `Invoke-Migracion` con servicios, comprobar con `Get-EscritoresAjenos` (ya existe, `Actualizar-Demo.ps1:84`) que `app\migracion` y la carpeta de los guiones solo los escriben SYSTEM y Administradores, y negarse si no. La solución de fondo (≈0,5 dp) es instalar `GPOS.Migracion` también en Archivos de programa, dentro del manifiesto, y que los guiones elevados lo ejecuten desde ahí. Va a B y al propietario: toca DM-08 y el diseño del instalador, no solo esta fase.

### R-03 (Media, defensa en profundidad): el subárbol del destino no se valida

**Riesgo.** La fase valida el destino y sus antepasados hasta Archivos de programa (`FaseRestaurar.cs:36-42`) y `.anterior` (`:53`), pero no `destino\api`, `destino\reportes`, sus subcarpetas ni los archivos:
- `ListarArchivos` (`SistemaServidorWindows.cs:170-173`) salta los puntos de reanálisis que encuentra **dentro**, pero no los que están en la carpeta raíz que recibe. Si `destino\api` fuera una unión, la enumeración recorrería su objetivo (inferido del comportamiento de `Directory.EnumerateFiles`), todo lo que no esté en el manifiesto sería «sobrante» (`FaseRestaurar.cs:126-129`) y se borraría con privilegios de administrador (`:103`) fuera de Archivos de programa.
- `CopiarSinReanalisis` abre el destino con `FileMode.Create` (`SistemaServidorWindows.cs:223`) y `HuellaSha256` con `File.OpenRead` (`:182`): las dos siguen vínculos simbólicos y escriben a través de vínculos físicos, de modo que la verificación en el destino puede pasar sobre un archivo que no es el que carga el servicio.
- Sobrescribir un archivo existente conserva su DACL: un DLL con una ACE de escritura ajena seguiría así tras restaurar.

Crear cualquiera de estos objetos exige escribir en el destino, que solo pueden SYSTEM, Administradores y TrustedInstaller. Por eso la probabilidad es baja, pero el impacto (borrado arbitrario como administrador) es alto. `CopiarBinarios` comparte el mismo patrón, que es anterior a este commit.

**Remediación mínima (≈0,3 dp).** Antes de escribir, recorrer `destino\<servicio>` y cada subcarpeta con `LeerCarpeta` + `MotivoCarpeta` (sin reanálisis y con escritores de la lista blanca), y detener la fase con cualquier hallazgo. Para cada archivo del destino que se vaya a sobrescribir o borrar, rechazar los que tengan `FILE_ATTRIBUTE_REPARSE_POINT` o más de un vínculo físico, con el mismo criterio que `CopiarSinReanalisis` aplica al origen. Preferir borrar y crear el archivo (hereda la DACL del padre) en lugar de truncarlo.

### R-04 (Media): bytes no verificados en el destino y nada impide arrancar el servicio

**Riesgo.** A diferencia de `--fase servicios`, que solo lleva al destino lo verificado en `.preparacion`, `restaurar` copia directamente de `.anterior` al destino (`FaseRestaurar.cs:89`). Si la huella de lo copiado no coincide (`:91`, por una alteración de `.anterior` entre la verificación de `:64` y la copia, o por un error de disco) o si falla a mitad, esos bytes quedan en el destino junto con la marca `.aplicando` (`:111-112`). El único freno contra arrancar es el texto «No inicie los servicios»: el usuario que instala tiene derecho de inicio sobre los servicios (`SddlServicios.cs:36`, `RPWP`) y ni la API ni reportes miran `.aplicando` al arrancar (verificado: ningún archivo fuera de la fase, sus pruebas y el guion menciona `.aplicando`). La ventana TOCTOU exige ser administrador; el estado mezclado por un fallo, no.

**Remediación mínima (≈0,3 dp).** Una de dos: (a) que la comprobación al arrancar de la API y de reportes se niegue a iniciar si existe `.aplicando` en su carpeta de binarios (evento y salida distinta de cero; cubre las dos fases); o (b) restaurar en dos pasos como la copia: `.anterior` → `.preparacion` verificada → destino. (a) es más barata y además cubre `--fase servicios`. Con (b), la ventana entre verificar y copiar queda dentro de carpetas que solo escribe un administrador, igual que en la copia.

### R-05 (Baja): las bases se restauran antes de saber si los binarios volverán

**Riesgo.** El guion restaura las bases (paso 2, `Revertir-Actualizacion.ps1:83-99`) y solo después llama a la fase (`:105`). Las negativas de la fase (copia previa `no-verificada`, sin manifiesto, huellas distintas) se conocen sin escribir nada, pero llegan tarde: el DEMO queda con bases viejas y binarios nuevos (el mensaje de `:108` lo reconoce). Hay además un caso seguro: la primera actualización hecha con este código sobre un destino instalado antes de él no tiene `manifiesto.instalado.sha256`, así que su `.anterior` queda `no-verificada` (`FaseServicios.cs:354`, `426-431`) y la primera reversión siempre deja ese estado mezclado. Falla cerrada en lo que toca a la integridad de los binarios.

**Remediación mínima (≈0,2 dp).** Agregar a la fase un modo que solo compruebe (p. ej. `--solo-comprobar`: pasos 1 a 3 sin escribir) y llamarlo en el guion antes del paso 2, junto con la confirmación `RESTAURAR`. Documentar en `LEEME.md` que la primera actualización tras PR-D2 no se puede revertir con servicios (o volver a correr `--fase servicios` con el paquete instalado, que por el camino «al día» escribe `manifiesto.instalado`).

### R-06 (Baja): `verificada` no se ata a las huellas que se guardan

**Riesgo.** `DestinoIntegro` lee el destino y lo compara con `manifiesto.instalado` (`FaseServicios.cs:354`, `426-431`). Después se copia (`:355`) y las huellas que se escriben en `.anterior` solo se comparan con una segunda lectura del destino (`:357-363`), no con `manifiesto.instalado`. Un cambio en el destino entre las dos lecturas quedaría guardado como `verificada`. Exige ser administrador. Aparte, `manifiesto.instalado` vive en la raíz del destino, con la misma confianza que los binarios: `verificada` significa «coincide con lo que instalamos», no «auténtico». Es coherente con el blueprint, pero conviene decirlo en la documentación del control.

**Remediación mínima (≈0,05 dp).** Marcar `verificada` solo si, además, `respaldadas[a] == instalado[a]` para cada `a`. Se compara en memoria y no hace falta otra lectura.

### R-07 (Baja): `.aplicando` no se valida antes de borrarla

**Riesgo.** Al retomar solo se mira `Existe` (`FaseRestaurar.cs:70`) y al terminar se borra con `Directory.Delete(recursive: true)` (`:119`, `SistemaServidorWindows.cs:168`). No se comprueba que sea una carpeta, ni su dueño, ni que no sea un punto de reanálisis. Si fuera un archivo, el borrado lanza después de restaurar y verificar, y `manifiesto.instalado` no llega a escribirse (falla cerrada en la siguiente actualización). Que .NET borre solo el vínculo y no el contenido cuando `.aplicando` es una unión es inferido, no lo verifiqué. Exige escribir en el destino.

**Remediación mínima.** Aplicar `MotivoCarpeta` a `.aplicando` antes de retomar y antes de borrarla, como ya hace `CrearCarpetaProtegida` con `.anterior` y `.preparacion` (`FaseServicios.cs:437-447`).

### R-08 (Baja): nombres que `ComponenteValido` rechaza bloquean la reversión

**Riesgo.** `.anterior\manifiesto.sha256` se escribe con todo lo que hay en el destino (`FaseServicios.cs:346`, `364-365`), sin validar los nombres. Al restaurar se interpreta con `ComponenteValido` (`FaseServicios.cs:189-199`), que rechaza, por ejemplo, un `~` seguido de cifra (`archivo~1.json`). La reversión se negaría siempre por esa copia. Falla cerrada; solo afecta a la disponibilidad. El recorte de espacios en `linea[66..].Trim()` (`:158`) tiene el mismo efecto con nombres que empiezan por espacio.

**Remediación mínima.** Validar con `ComponenteValido` al construir `actuales` en `CopiarBinarios`. Si un nombre no pasa, marcar la copia `no-verificada` y decirlo en la salida, en lugar de descubrirlo al revertir.

### R-09 (Baja): falta `comprobar-servidor` tras restaurar

**Riesgo.** El blueprint (sección 5) pide `comprobar-servidor --perfil demo --sin-red` después de la fase. El guion pasa directamente a los demás programas y a `actualizacion.json` (`Revertir-Actualizacion.ps1:110-130`). Se pierde una comprobación independiente de servicios, DACL y entorno antes de anotar `revertida`.

**Remediación mínima.** Llamarlo tras `:110` y, si no da 0, avisar sin anotar `revertida`.

## 5. Controles bien implementados

- Los puntos 1 y 2 del pedido, en lo esencial: un binario que no coincide con el manifiesto de `.anterior` no se acepta. Se verifica la huella de `.anterior` antes de escribir (`FaseRestaurar.cs:64-66`), la de lo copiado durante la copia, sobre el mismo identificador y sin escritores concurrentes (`SistemaServidorWindows.cs:195`, `FileShareRead`; `FaseRestaurar.cs:91`) y la del destino al final (`:116-118`). La marca se borra solo si todo coincide.
- Copia desde `.anterior` sin seguir puntos de reanálisis, con rechazo de vínculos físicos y de ruta final distinta (`SistemaServidorWindows.cs:200-220`).
- Rutas del manifiesto: sin rutas absolutas, sin `:`, sin `.`/`..`, sin nombres de dispositivo (incluidos `COM¹-³`/`LPT¹-³` y `CONIN$`/`CONOUT$`), sin forma 8.3 ni punto o espacio final, sin duplicados sin distinguir mayúsculas, y solo bajo `app\api\` y `app\reportes\` (`FaseServicios.cs:153-199`). `--destino` se normaliza y debe estar dentro de Archivos de programa; las rutas `\\?\` y las cortas 8.3 se rechazan porque no empiezan por el prefijo (`:205-214`).
- El encabezado `# estado=` se compara exactamente con la primera línea (`FaseRestaurar.cs:57-61`). Una segunda línea `#` invalida el manifiesto. Solo SYSTEM y Administradores pueden escribirlo. Si no hay `manifiesto.instalado`, la copia queda `no-verificada` (falla cerrada).
- Los archivos extra de `.anterior` que no están en su manifiesto se ignoran (no se copian). Los sobrantes se borran solo por nombre relativo dentro de `api\` y `reportes\`, sin `..` posible (salvo lo que señala R-03).
- `.aplicando` no da más poder: retomar sigue exigiendo una copia `verificada` con sus huellas, la fase exige elevación y una restauración solo puede volver a una versión que ya se verificó. El guion solo deja revertir la última marca y no repite una ya `revertida` (`Revertir-Actualizacion.ps1:63-70`).
- Guion: comprueba la elevación antes de tocar nada, pide la confirmación `RESTAURAR` y detiene los servicios antes de la fase. La fase vuelve a comprobar que no están en marcha y, si no puede saberlo, lo trata como en marcha (`SistemaServidorWindows.cs:498-513`). `Detener-ConError` lanza con `$ErrorActionPreference='Stop'`, así que con un código distinto de 0 el guion no sigue ni inicia servicios.
- Fuga de información: la fase no lee ni escribe el entorno ni la clave JWT. La salida y los eventos llevan rutas de Archivos de programa, hasta 5 nombres de archivo y el SID de quien ejecuta (este último ya estaba). El `e.Message` del `catch` general (`ComandoImplantarServidor.cs:43-45`) puede llevar rutas del destino, pero no secretos. Sin hallazgos.

## 6. Remediaciones priorizadas

1. R-01: renovar `.anterior` también en el camino «al día» y atarla a la marca con la huella de su manifiesto (≈0,3 dp). Antes de unir.
2. R-04 (a): que la comprobación al arrancar de la API y de reportes se niegue con `.aplicando` (≈0,2-0,3 dp).
3. R-03: validar el subárbol y los archivos del destino antes de sobrescribir o borrar (≈0,3 dp; cubre también `CopiarBinarios`).
4. R-05: `--solo-comprobar` antes de restaurar las bases, y nota en `LEEME.md` sobre la primera reversión (≈0,2 dp).
5. R-02: comprobar escritores de `app\migracion` y de los guiones antes de ejecutar elevado; la solución de fondo va al diseño del instalador.
6. R-06, R-07, R-08, R-09: ajustes pequeños (≈0,2 dp en total).

## 7. Recomendación

**Aprobado con observaciones** (recomendación técnica; la decisión es del propietario). No hay Críticos ni Altos. Recomiendo resolver R-01 antes de unir, porque es el único que lleva a un estado inconsistente sin atacante y por un uso normal (actualizar con servicios sin cambios o tras un fallo de la fase servicios).

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\revision-seguridad-fase-restaurar-2026-10-23.md
- Supuestos: los binarios de `bin\Debug` corresponden a `f1b2374d`; un administrador hostil queda fuera del modelo (blueprint, sección 4); son inferidos, no verificados, el comportamiento de `Directory.EnumerateFiles` con una unión en la raíz y el de `Directory.Delete` sobre una unión.
- Decisiones candidatas a ADR: atar la copia previa a la marca de la actualización (R-01); que la comprobación al arrancar de los servicios se niegue con `.aplicando` (R-04); `GPOS.Migracion` en Archivos de programa para los guiones elevados (R-02).
- Entregas a otros agentes: desarrollador backend (A) → R-01, R-03 a R-08; devops / instalador (B) → R-02, R-05 y R-09 en el guion; arquitecto-maestro → decidir R-02 y R-04 (a).
- Próximo paso recomendado: corregir R-01 en `a/pr-d2-manifiesto` y volver a pedir revisión solo de ese cambio.
