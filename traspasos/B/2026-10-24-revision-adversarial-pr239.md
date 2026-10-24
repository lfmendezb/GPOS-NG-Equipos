[Informe de Seguridad] Revisión adversarial independiente del PR #239 (PR-V: verbos `implantar-servidor`, `comprobar-servidor` y `red`; T1-10 y SDDL de Q-5 estrictos) · 2026-10-24

- **Revisor:** auditor de seguridad (sesión de B), solo lectura. No escribí el PR.
- **Objeto:** `lfmendezb/GPOS-NG#239`, rama `a/pr-v-verbos-servidor`, cabeza `df422dc9` (merge de `feature/modelo-ng` `1b310591` sobre `2e55e5fd`); base `feature/modelo-ng`. 43 archivos, +6.422/−2.
- **Método:** `gh pr view/diff 239`; árbol de `df422dc9` extraído con `git archive` a una carpeta temporal (sin *checkout*). Contraste con #218 (`b/t1b-api-msi`, `1232d0af`) y #228 (`b/f1-anillo`, `c0144f3b`), las hojas `docs/decisiones/2026-10-23-hoja-firma-tls-y-anillo-del-servicio.md` y `…-s217-02-h210-msi-y-tls-f2-f3.md`, el blueprint de PR-V (`traspasos/A/blueprint-pr-v-verbos-servidor-2026-10-22.md`) y las tres revisiones previas de A (SPV, SPW, SPX).
- **No ejecuté pruebas ni compilé:** había 9 procesos `dotnet` activos en el equipo y la regla del equipo de B limita a 3 los que compilan o prueban. Todo lo que sigue es lectura estática; lo que depende de Windows se marca [I] (inferido) o [I, VM].

## 1. Alcance y superficie revisada

| Superficie | Quién la alcanza | Archivos |
|---|---|---|
| `implantar-servidor` (fases carpetas, servicios, esquema, lectura) | Administrador elevado (salvo esquema) | `Servidor/ComandoImplantarServidor.cs`, `FasesImplantacion/*.cs`, `SistemaServidorWindows.cs` |
| `comprobar-servidor` (catálogo R1-R8, P1-P7, DM-03/09/10) | Administrador (lectura) | `ComandoComprobarServidor.cs`, `Comprobaciones/*.cs` |
| `red --modo un-equipo` | Administrador elevado | `ComandoRed.cs`, `SistemaServidorWindows.cs:428-555`, `GPOS.Comun/Red/ClaveRegistroServidor.Windows.cs` |
| Entradas no confiables | Usuario que prepara el paquete; quien ejecuta | `--origen` (paquete y `manifiesto.sha256`), `--destino`, `--usuario-instala`, `--acta`, `--motivo`, salida de los verbos hijos |
| Secretos | Clave JWT del DEMO en `Services\GPOS.Api\Environment`; llave pública del sitio (sella credenciales SQL de lectura) | `FaseServicios.cs:105-119`, `:454-491`; `FaseLectura.cs:27-60` |
| Pruebas de contrato | CI | `tests/GPOS.Tests/Servidor/*.cs` |

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título | Estado |
|---|---|---|---|
| R239-01 | **Media** | La fase `lectura` no comprueba `config\` y `crear-lectura` relee la llave por ruta: la llave del sitio se puede sustituir | Verificado (código); explotabilidad [I] |
| R239-02 | **Media** | La fase `esquema` llama a `anillo --anclar` sin `--huella-recuperacion`: incumple SA-01 (firmada) y se rompe al unir #228 | Verificado |
| R239-03 | **Media** | El subárbol de binarios del destino (`api\`, `reportes\`) no se comprueba nunca, y `comprobar-servidor` no lo vigila | Verificado (código); precondición [I] |
| R239-04 | **Media** | Las pruebas «estrictas» de T1-10 y Q-5 pasan sin comprobar nada en esta rama; al unir con #218 quedan dos constantes de Q-5 | Verificado |
| R239-05 | Baja | `implantar-servidor` lleva `e.Message` a la consola y al evento 5135 | Verificado |
| R239-06 | Baja | La DACL de la clave del servicio se lee normalizada (`GetAccessControl`), no en bruto como la de `red` (S1b-01) | Sospecha [I] |
| R239-07 | Baja | El descriptor del objeto de servicio (DM-09) se aplica al final: no se vuelve a comprobar la imagen ni la cuenta | Verificado (orden); impacto [I] |
| R239-08 | Baja | R2 con `--perfil produccion` exige SID sin restricción, pero el MSI de #218 no declara `ServiceSid` | Sospecha [I, VM] |

**Sin hallazgos Críticos ni Altos.** SPV-03 (manifiesto sin autenticar) es un residual que el propietario firmó con la opción (a) el 2026-10-23. Aquí no se reabre. SPV-15 (podar los archivos que el manifiesto ya no trae) sigue pendiente, como la declaró A.

## 3. Checklist OWASP

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | R239-01, R239-03 y R239-07. DM-09 (DEMO) y Q-5 (producción) son correctos en las constantes (`SddlServicios.cs:35-42`) y en la regla (`ReglasDescriptores.cs:160-177`) |
| A02 Criptografía | Correcta: la clave JWT tiene 48 bytes de `RandomNumberGenerator` (`FaseServicios.cs:118`), se sustituye si la DACL no era conforme o si no tiene 48 bytes (`:459-471`), y la llave del sitio se compara por SHA-256 (`FaseLectura.cs:52`) |
| A03 Inyección | Sin hallazgos. SQL constante con parámetros tipados (`SistemaServidorWindows.cs:686-751`). Procesos con `ArgumentList` y sin *shell* (`:363-367`, `:763-770`). XPath con orígenes constantes y comilla rechazada (`:598`). El analizador de argumentos toma el siguiente elemento como valor aunque empiece por `--` (`Program.cs:505-506`), así que `--acta`/`--motivo` no inyectan banderas en el hijo |
| A04 Diseño inseguro | R239-01, R239-02 y R239-03 |
| A05 Configuración | R239-06 y R239-08 |
| A06 Componentes vulnerables | No aplica: no hay paquetes nuevos |
| A07 Autenticación | No aplica directamente (la clave JWT se cubre en A02) |
| A08 Integridad de software y datos | SPV-03 residual firmado. R239-03 (binarios sin vigilancia después de copiarlos) |
| A09 Registro y monitoreo | R239-05. Ningún evento lleva la clave JWT: lo vigila la prueba `ImplantarServidorTests.cs:366-388` |
| A10 SSRF | Sin hallazgos: `ObtenerAsync` solo admite *loopback*, sin proxy y sin redirecciones (`SistemaServidorWindows.cs:647-649`) |

## 4. Hallazgos

### R239-01 (Media): la llave del sitio se puede sustituir en la fase `lectura`
- **Riesgo.** La llave pública que publica `llave-sitio` sella los sobres con usuario y contraseña de lectura SQL de cada empresa (`Lectura/CredencialesLectura.cs:82`). Si alguien la sustituye por la suya, abre los sobres y obtiene credenciales de lectura de **todas** las empresas (fuga entre empresas). La fase confía en que la DACL de `config\` impide la sustitución, pero no lo comprueba:
  - `FaseLectura.EjecutarAsync` no ejecuta la precondición de carpetas, a diferencia de `FaseServicios.cs:45` (`FaseCarpetas.Ejecutar(s, _ => { }, crear: false)`).
  - La huella se comprueba en el proceso padre (`FaseLectura.cs:42-53`), pero `crear-lectura` vuelve a leer el archivo **por ruta** en otro proceso (`FaseLectura.cs:56`; `Lectura/ComandosLectura.cs:87-91`). Entre las dos lecturas hay una ventana de carrera (TOCTOU).
- **Escenario [I].** En Windows, los usuarios pueden crear carpetas en `%ProgramData%` por omisión. Un usuario local crea `C:\ProgramData\GPOS NG\config` antes de la implantación y queda como dueño. La fase `carpetas` se detendría (DUENO_NO_PERMITIDO), pero la fase `lectura` es independiente y se puede ejecutar sola (en un reintento o con un guion que no mira el código de salida anterior). Con `config\` bajo su control, el usuario reemplaza `llave-sitio.pub` después de la comprobación de la huella y antes de `crear-lectura`. La probabilidad es baja y el impacto es alto.
- **Remediación (~0,1 dp).**
  1. Al entrar en `lectura`, ejecutar `FaseCarpetas.Ejecutar(s, _ => { }, crear: false)` y detenerse si no devuelve Hecho.
  2. Pasar la huella al hijo (`crear-lectura --huella-llave <sha256>`) y que `ComandosLectura.CredencialesAsync` la compare con los bytes que él mismo lee: así la comprobación y el uso son la misma lectura.
  3. Agregar una prueba que falle si `lectura` no lee primero las carpetas.

### R239-02 (Media): `anillo --anclar` sin `--huella-recuperacion` (SA-01, firmada el 2026-10-23 y ampliada el 2026-10-24)
- **Riesgo.** SA-01 hace **obligatoria** la huella SHA-256 del `.cer`, dictada por un segundo canal, en `--anclar`, `--migrar` y `--cambiar-recuperacion`. La fase compone `["anillo", "--anclar", "--acta", o.Acta, "--motivo", o.Motivo]` (`FaseEsquema.cs:46`), y `implantar-servidor` ni siquiera acepta la opción (`OpcionesComando.cs:31`). En #228 (F1, abierto contra la misma base) `anillo --anclar` exige la huella (`ComandosAnillo.cs:61`, `MantenimientoAnillo.cs:593` en `c0144f3b`).
- **Efecto.** Al unir #228, la fase `esquema` del DEMO no puede anclar y termina con 1. Falla cerrada, así que no hay exposición. Pero el flujo firmado de PR-D2 queda roto y el diseño de PR-V no refleja SA-01. Tampoco contempla `anillo --preparar --recuperacion` ni el archivo del anillo (P-1 (a), SA-03), que F1 hace necesario antes del ancla.
- **La prueba fija el comportamiento viejo.** `ImplantarServidorTests.cs:872-878` exige exactamente esa lista de argumentos, sin huella. Con el doble en memoria seguirá en verde después de unir #228.
- **Remediación (~0,25 dp).**
  1. Agregar `--huella-recuperacion` (y, si corresponde, `--recuperacion <cer>`) a `implantar-servidor --fase esquema`, obligatorias cuando falte el ancla, y pasarlas al hijo.
  2. Decidir con B si `anillo --preparar` va en la fase `esquema` o en un paso aparte de PR-D2.
  3. Ajustar las pruebas.
  4. Fijar el orden de unión con #228. Si PR-V se une antes, abrir un PR inmediato que lo corrija.

### R239-03 (Media): los binarios del destino no se vigilan por debajo de `destino`
- **Riesgo.**
  - `PrepararDestino` comprueba el destino y sus antepasados bajo Archivos de programa (`FaseServicios.cs:238-257`), pero nunca `destino\api`, `destino\reportes`, sus subcarpetas ni sus archivos.
  - La copia final usa `File.Copy`, que sigue puntos de reanálisis y hereda la DACL de la carpeta (`FaseServicios.cs:347`; `SistemaServidorWindows.cs:184-188`).
  - Si las huellas coinciden, la fase da los binarios por «al día» sin mirar nada más (`FaseServicios.cs:272-276`).
  - `comprobar-servidor` tampoco vigila la carpeta de binarios: R3 solo cubre las carpetas de datos (`R3Carpetas.cs:25-35`).
- **Escenario [I].** Si `destino\api` ya existía con una DACL propia y laxa (creada a mano, por una herramienta anterior o por un técnico que «abrió permisos» para diagnosticar), los archivos copiados heredan esa DACL. Un usuario local podría reemplazar `GPOS.Api.exe` o una DLL **después** de la verificación. En el arranque siguiente, su código correría como `NT SERVICE\GPOS.Api`, con la clave JWT en el entorno: podría firmar tokens de cualquier usuario, también del SUPER. La probabilidad es baja (hace falta un error previo de configuración), pero nada lo detecta, ni al implantar ni al comprobar.
- **Remediación (~0,3 dp).**
  1. En `PrepararDestino`, recorrer el subárbol que se va a escribir (`api\`, `reportes\` y sus subcarpetas) con `LeerCarpeta` y `MotivoCarpeta(l, null)`, y rechazar los puntos de reanálisis. Hacerlo también en la rama «al día».
  2. Agregar a `comprobar-servidor` una fila (por ejemplo, R3b) con la DACL de la carpeta de binarios y la comprobación de sus huellas contra el manifiesto aplicado.
  3. Cerrar SPV-15: podar lo que no está en el manifiesto.

### R239-04 (Media): las pruebas «estrictas» de T1-10 y Q-5 no comprueban nada en esta rama
- **Riesgo.**
  - `El_SDDL_de_produccion_es_el_del_Package_wxs_cuando_exista` y `T1_10_…_cuando_exista` hacen `if (!File.Exists(wxs)) return;` (`ServidorArquitecturaTests.cs:170` y `:181`). En `a/pr-v-verbos-servidor` no existe `instalador/Api/` (verificado en `df422dc9`), así que las dos pruebas pasan en verde **sin ejecutar ninguna comprobación**. Con xUnit 2.9.3 no hay *skip* dinámico, así que tampoco aparecen como omitidas. El título del PR («T1-10 y SDDL de Q-5 estrictos») describe una protección que hoy no existe.
  - Si `Package.wxs` cambia de nombre o de carpeta después de unir, la guarda desaparece en silencio.
  - Al unir con #218 quedan **dos** constantes de Q-5: `SddlServicios.ServicioProduccion` (`SddlServicios.cs:42`) y `ApiInstaladorTests.SddlServicioQ5` (`ApiInstaladorTests.cs:31-32` en #218), más el literal de `tests/laboratorio-adr090/invitado/Probar-Instalador.ps1:44`. Eso contradice «el SDDL de Q-5 ya vivía compartido» y deja en rojo el caso PV-Q5-01 del plan de C (`traspasos/C/2026-10-24-plan-pruebas-pr-v.md:62`).
- **Remediación (~0,1 dp).**
  1. Unir #218 antes, o quitar la guarda en el mismo PR que una ambos.
  2. Mientras tanto, hacer que la prueba **falle** si existe `instalador/Api/GPOS.Api.Instalador.wixproj` y falta `Package.wxs` (un centinela que no depende del orden).
  3. Que `ApiInstaladorTests` use `SddlServicios.ServicioProduccion` y que el `.ps1` lo lea de un solo origen o lo verifique.

### R239-05 (Baja): `e.Message` en la consola y en el Visor de eventos
- **Evidencia.** `ComandoImplantarServidor.cs:44` construye `$"{e.GetType().Name}: {e.Message}"`, que va a la consola y al evento 5135 (`:51-52`). En cambio, `ComandoRed.cs:49` y `ComandoComprobarServidor.cs:56` (línea 143 del bloque leído) solo usan el tipo, como pide el endurecimiento declarado («sin `e.Message`»).
- **Riesgo.** Hoy no vi un camino que lleve un secreto en el mensaje: los `InvalidOperationException` de `sc` traen solo la primera línea de su salida (`SistemaServidorWindows.cs:358`). Aun así, el registro de Aplicación lo leen los usuarios, y el mensaje puede traer rutas y datos del sistema.
- **Remediación.** Igualar al patrón de `red`: tipo y texto controlado.

### R239-06 (Baja, sospecha): la DACL de la clave del servicio se lee normalizada
- **Evidencia.** `LeerSddlClaveServicio` usa `GetAccessControl(...).GetSecurityDescriptorSddlForm` (`SistemaServidorWindows.cs:377-389`). La clave de `red` se lee en bruto con `RegGetKeySecurity` precisamente para evitar la normalización de `RegistrySecurity` (S1b-01, `ClaveRegistroServidor.Windows.cs:19-21`).
- **Riesgo [I].** `CommonSecurityDescriptor` puede reordenar, fusionar o descartar ACE «sin sentido» (máscara vacía, solo herencia). `MotivoClaveServicio` (`ReglasDescriptores.cs:100-110`) podría evaluar una ACL distinta de la real. Esa regla protege la clave JWT.
- **Remediación (~0,05 dp).** Leer en bruto con el mismo `DescriptorBruto` (abriendo la clave con `ReadPermissions`).

### R239-07 (Baja): DM-09 se aplica al final y no se vuelve a comprobar la imagen
- **Evidencia.**
  - La imagen y la cuenta de un servicio que ya existe se comprueban en `ConfigurarServicio` (`FaseServicios.cs:424-427`).
  - La clave JWT se escribe después (`:82`).
  - El descriptor del objeto de servicio se aplica al final (`:95`, `:521-533`).
  - Ni al entrar se evalúa con `MotivosServicio` el descriptor que ya tenía el servicio, ni al final se vuelven a leer la imagen y la cuenta.
- **Riesgo.** Si un servicio previo daba `SERVICE_CHANGE_CONFIG` a alguien que no es administrador, esa persona puede cambiar `binPath` entre la comprobación y `sdset`. La fase termina con 0 y deja una clave JWT nueva para una imagen ajena. Quien ya tiene ese derecho puede escalar a SYSTEM por otra vía, así que el riesgo adicional es bajo. El defecto es de orden y de la evidencia que se informa como OK.
- **Remediación.** Al entrar, detenerse con 4 si `MotivosServicio(l.Sddl, admiteUsuario: true)` no está vacío. Al final, volver a leer la imagen y la cuenta.

### R239-08 (Baja, sospecha [I, VM]): R2 de producción y el MSI no coinciden en el tipo de SID
- **Evidencia.** `R2CuentaEInicio.cs:18` y `:26` exigen `TipoSid == 1` en todos los perfiles. El `Package.wxs` de #218 dice «Sin ServiceSid (ADR-76, punto 5)» (comentario, línea 12), y ADR-76 punto 5 solo prohíbe el SID **restringido**.
- **Riesgo.** Si Windows no fija `ServiceSidType = 1` para una cuenta virtual instalada por `ServiceInstall`, `comprobar-servidor --perfil produccion` dará una FALLA falsa. En la operación eso empuja a ignorar las fallas.
- **Remediación.** Medirlo en el laboratorio (caso A1 o L-2f) y alinear la comprobación con el MSI, o al revés.

## 5. Controles bien implementados (verificado en el código)
- **Clave JWT (cerrojo 1).**
  - El literal está en un solo método, con una prueba de texto (`ServidorArquitecturaTests.cs:34-47`).
  - Solo se escribe con el perfil demo y el modo Amplio (`FaseServicios.cs:109-112`).
  - El orden es: proteger la DACL, volver a leerla y solo entonces escribir (`:459-471`), con una prueba de mutación (`ImplantarServidorTests.cs:271-295`).
  - Se sustituye si la DACL estaba abierta al entrar (SPV-05).
  - La prueba `:366-388` comprueba que el valor no aparece en la salida, los eventos, las operaciones ni los argumentos.
- **Copia de binarios.**
  - La preparación protegida abre cada archivo por identificador, sin seguir puntos de reanálisis, y rechaza vínculos físicos, ruta final distinta y archivos de OneDrive (`SistemaServidorWindows.cs:190-231`).
  - La huella se calcula sobre los mismos bytes que se escriben.
  - Hay copia previa protegida y la marca `.aplicando` (`FaseServicios.cs:278-367`).
  - La validación de rutas del manifiesto es estricta: rechaza «..», «:», nombres de dispositivo, nombres 8.3, punto o espacio final y repetidos (`:122-179`).
  - `--destino` solo se admite dentro de Archivos de programa (`:185-194`).
- **Servicio.**
  - La imagen va entre comillas, sin ruta sin comillas (`DisposicionServidor.cs:44`).
  - Un servicio ajeno o distinto detiene la fase sin «arreglarlo» (`FaseServicios.cs:424-427`).
  - La recuperación se lee del SCM y se borra la acción de comando (SPW-05).
  - `--usuario-instala` se resuelve por lista de permitidos: usuario concreto, RID 500 o mayor o igual que 1000, Entra ID, sin grupos ni cuentas de equipo o gMSA (`ReglasDescriptores.cs:133-153`).
- **Verbo `red`.**
  - Detecta vínculos simbólicos del registro.
  - Comprueba el padre, crea la clave con su descriptor, lo vuelve a leer y repite las guardas antes de escribir (SPX-01). `ModoRed` se escribe el último (`ComandoRed.cs:60-133`).
  - Toda la escritura pasa por la vista de 64 bits, con una prueba (`ServidorArquitecturaTests.cs:93-113`).
- **DM-03.**
  - Exige `VIEW ANY DEFINITION`, para no dar un OK parcial.
  - Usa una CTE recursiva por el login, `public` y los grupos de la cuenta virtual, sin `EXECUTE AS` (`SistemaServidorWindows.cs:697-751`).
- **`comprobar-servidor`.** Si una comprobación lanza una excepción, cuenta como AVISO y nunca como OK (`ComandoComprobarServidor.cs:56`, línea 143 del bloque leído). El detalle nunca trae valores del entorno (R8).
- **Las pruebas de T1-10 y Q-5, cuando hay `Package.wxs`, sí son estrictas.** Con el `Package.wxs` de #218, el `ServiceInstall` de `GPOS.Api` trae `Arguments="--servicio"` y `PermissionEx Sddl` idéntico a la constante (verificado en `1232d0af`, líneas 61-77).

## 6. Remediaciones priorizadas

| # | Hallazgo | Cuándo | Esfuerzo [I] |
|---|---|---|---|
| 1 | R239-02: `--huella-recuperacion` (y el paso `--preparar`) en la fase `esquema`; orden de unión con #228 | Antes de unir (o PR inmediato si #228 se une después) | 0,25 dp |
| 2 | R239-01: precondición de carpetas en `lectura` y huella verificada por el hijo | Antes de unir | 0,1 dp |
| 3 | R239-04: centinela o unión con #218 y una sola constante de Q-5 | Al unir #218 y #239 | 0,1 dp |
| 4 | R239-03: comprobar el subárbol de binarios y agregar la fila en `comprobar-servidor` | Antes del ensayo del DEMO (PR-D2) | 0,3 dp |
| 5 | R239-05, R239-06 y R239-07 | Siguiente pasada | 0,15 dp |
| 6 | R239-08: medir en el laboratorio | Con los casos A1 o L-2f | 0 dp (VM) |

Total aproximado: ~0,9 dp [I, ±30 %], unos USD 360 con el costo por día que se usa en las hojas del equipo [I].

## 7. Recomendación: **Aprobado con observaciones** (recomendación técnica; la unión la ordena el propietario, C2)

No hay hallazgos Críticos ni Altos. Condiciones para unir:
1. **R239-02** resuelto en el PR, o el orden con #228 fijado por escrito y un PR de corrección comprometido antes de que se ensaye la fase `esquema`.
2. **R239-01** corregido. Es pequeño y protege las credenciales de lectura de todas las empresas.
3. **R239-04**: la guarda «si no existe, sale» se elimina o se acompaña del centinela en el mismo momento en que se une #218, y queda una sola constante de Q-5.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\B\2026-10-24-revision-adversarial-pr239.md`
- Supuestos:
  - por omisión, los usuarios pueden crear carpetas en `%ProgramData%` [I];
  - `CommonSecurityDescriptor` puede normalizar ACE [I];
  - el tipo de SID que Windows deja con `ServiceInstall` sin `ServiceSid` [I, VM];
  - no ejecuté pruebas (límite de procesos de compilación en el equipo de B).
- Decisiones candidatas a ADR: ninguna nueva. R239-02 precisa cómo compone PR-V el flujo de F1 (`--preparar` y `--anclar` con huella), dentro de lo firmado en SA-01.
- Entregas a otros agentes:
  - A (autor de PR-V) → R239-01 a R239-07;
  - B (#218) → una sola constante de Q-5 y el orden de unión;
  - B (#228) → orden de unión con PR-V;
  - laboratorio (VM) → R239-08.
- Próximo paso recomendado: que A corrija R239-01 y R239-02 en la rama y que B fije el orden de unión de #218, #228 y #239.
