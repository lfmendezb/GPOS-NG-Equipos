[Informe de Seguridad] Revisión estática de PR-V: verbos `implantar-servidor` y `comprobar-servidor` de GPOS.Migracion · equipo A · 2026-10-22

- **Objeto:** rama `a/pr-v-verbos-servidor`, punta `1d298cf9`, 4 commits sobre `origin/feature/modelo-ng` `67b4353a` (`git diff 67b4353a..HEAD`: 38 archivos, +3824 líneas). Incluye `src/GPOS.Migracion/Servidor/**`, `Program.cs`, `OpcionesComando.cs` y `tests/GPOS.Tests/Servidor/**`.
- **Contraste:** `blueprint-pr-v-verbos-servidor-2026-10-22.md`, incluidas las decisiones del 22-oct (acta y motivo solo si falta el ancla, `config\llave-sitio.pub`, sin `--confirmar`). También `plan-demo-con-api-de-reportes-2026-10-22.md` (2.2 a 2.4, 5 y 6), `dictamen-seguridad-demo-jwt-d5-2026-10-22.md` (DM-01 a DM-16) y `contrato-servicio-msi-api-2026-10-22.md` (SDDL de Q-5).
- **Método:** solo lectura. No se compiló, no se ejecutaron pruebas, ni `sc`, `icacls` o servicios.
- **Marcas:** [V] verificado por lectura del código; [I] inferido (comportamiento de Windows o SQL Server que hay que confirmar en la VM).
- **Naturaleza:** recomendación técnica. La decisión es del propietario (C2).
- Las rutas son relativas a `src/GPOS.Migracion/` salvo que se diga otra cosa.

## Resumen y recomendación

El núcleo de lo que pide el dictamen está bien construido:
- **Secreto JWT:** la clave se genera con 48 bytes de `RandomNumberGenerator` y solo existe en la lista que va a `Registry.SetValue`. No sale por la salida, los eventos ni los argumentos de `sc.exe` o de los procesos hijos. El literal `Jwt__Clave` está en un solo método. El perfil `produccion` tiene tres barreras antes de llegar a él.
- **DACL de la clave del servicio:** se aplica, se relee y solo entonces se escribe el valor.
- **Inyección:** `--usuario-instala` se canoniza a SID, así que no inyecta SDDL. `sc.exe` y los verbos hijos reciben los argumentos con `ArgumentList` y el analizador toma literalmente el valor de `--acta` y `--motivo`, así que no hay inyección de opciones.
- **Carpetas:** se crean en una sola llamada con su descriptor. La lectura usa `FILE_FLAG_OPEN_REPARSE_POINT` y compara la ruta final, así que detecta uniones también en los antepasados.
- **`comprobar-servidor`:** falla cerrada (lo ilegible no da OK) y no expone mensajes de excepción.

**No hay hallazgos Críticos ni Altos.** Hay ocho Medios:
- dos en la copia de binarios: un binario con huella distinta se queda en el destino, y la copia sigue uniones del origen;
- uno de autenticidad del manifiesto (residual del DEMO);
- dos en la DACL y el ciclo de la clave: la comprobación solo mira derechos de lectura, y se conserva una clave que pudo estar expuesta;
- uno de `--usuario-instala`, que acepta grupos amplios distintos de IU, AU, BU y Todos;
- uno de DM-03, que no mira permisos de servidor ni pertenencia por grupos;
- uno funcional que tumba un control: R3 da FALLA siempre en Windows real, y el doble lo oculta.

**Recomendación: Aprobar con condiciones.**
- **Antes de unir:** corregir SPV-01, SPV-04, SPV-06, SPV-07 y SPV-08, con sus pruebas de mutación.
- **Antes del ensayo en la VM:** corregir SPV-02 y SPV-05.
- **SPV-03:** el propietario lo acepta como residual del DEMO, o se resuelve con un manifiesto firmado.
- **Esfuerzo estimado:** 1,0 a 1,5 dp [I, ±40 %]. No suma costo de infraestructura.

## 1. Alcance y superficie revisada

- **`implantar-servidor`** (elevado salvo `esquema`). Fases:
  - `carpetas`: `%ProgramData%\GPOS NG` y sus hijas;
  - `servicios`: copia a `%ProgramFiles%\GPOS NG\Demo`, `sc create/config/privs/sidtype/failure/sdset`, orígenes de eventos, DACL de `HKLM\…\Services\GPOS.Api`, valor `Environment` con la clave JWT;
  - `esquema`: subprocesos `sistema`, `actualizar`, `anillo --comprobar/--anclar` y lectura de DM-03 en `master`;
  - `lectura`: subprocesos `crear-lectura-sistema`, `llave-sitio` y `crear-lectura`, con comparación de huella.
- **`comprobar-servidor`:** el catálogo de R1 a R8, P1, P4, P5, P7, DM-03, DM-09 y DM-10, más las pendientes en AVISO.
- **Entradas que controla quien ejecuta:** `--origen` (normalmente en la carpeta del usuario, escribible por sus procesos sin elevar), `--destino`, `--usuario-instala`, `--acta`, `--motivo` y el contenido del paquete (`manifiesto.sha256` y los binarios).

## 2. Tabla resumen

| ID | Severidad | Título |
|---|---|---|
| SPV-01 | **Media** | Una huella distinta en el destino detiene la fase, pero el binario no verificado se queda en `Program Files` (y, al actualizar, el servicio ya apunta a él) |
| SPV-02 | **Media** | La copia desde `--origen` sigue uniones y vínculos: el proceso elevado puede leer un archivo protegido y dejarlo en una carpeta que leen los Usuarios |
| SPV-03 | **Media** (residual del DEMO; **cerrado el 2026-10-23: el propietario firmó (a)**, hoja `hoja-decision-spv-03-manifiesto-2026-10-23.md`; (b) con el *bundle*) | El manifiesto se lee, sin autenticar, de la misma carpeta del usuario que los binarios: DM-08 solo cubre el cambio posterior a esa lectura |
| SPV-04 | **Media** | `MotivoClaveServicio` solo busca derechos de lectura: no reconoce `GENERIC_EXECUTE` (que en una clave equivale a `KEY_READ`), `WRITE_DAC`, `WRITE_OWNER`, `KEY_SET_VALUE` ni `GENERIC_WRITE` de otros SID |
| SPV-05 | **Media** | Se conserva la clave JWT que ya estaba, aunque la DACL estuviera abierta al entrar (clave posiblemente expuesta) y sin validar que tenga 48 bytes |
| SPV-06 | **Media** | `--usuario-instala` rechaza solo IU, AU, BU y Todos: acepta Invitados, NETWORK, SERVICE, LOCAL, Usuarios del dominio, etc. Con WP pueden detener la API y ocupar el puerto 5071 |
| SPV-07 | **Media** | DM-03 solo mira la pertenencia directa a roles de servidor: no mira `CONTROL SERVER`, `ALTER ANY LOGIN` ni `IMPERSONATE` concedidos, ni `public`, ni los inicios de sesión de grupo |
| SPV-08 | **Media** | R3 compara un descriptor leído sin grupo con uno esperado con `G:SY`: en Windows real da FALLA siempre; el doble lo oculta |
| SPV-09 | Baja | La fase `carpetas` acepta una carpeta existente con lectores ajenos; R3 no cubre `Api\registros` ni `Api\temp` |
| SPV-10 | Baja | `SeRestorePrivilege` queda habilitado en el token el resto del proceso (y lo heredan `sc.exe` y los hijos) |
| SPV-11 | Baja | La detección del ancla busca la subcadena en cualquier línea (salida estándar y de error) e ignora el código de salida |
| SPV-12 | Baja | P7 reconoce Amplio solo con la grafía exacta `GPOS__…=Amplio` (no con `:`); R8 no reconoce `Pwd=`, `Key` ni `Token` |
| SPV-13 | Baja | `--sin-red` solo omite HTTP (DM-03 sigue conectando a SQL Server, quizá remoto); `comprobar-servidor` escribe el evento 5138 |
| SPV-14 | Baja | `--destino` es libre: los binarios de servicio pueden ir fuera de `Program Files`; solo se comprueban el destino y su padre |
| SPV-15 | Baja | Idempotencia y restos: `sdset` en cada pasada si `sdshow` trae SACL [I]; `FailureCommand` previo no se borra; quedan archivos que el manifiesto ya no trae |
| SPV-16 | Baja | Validación de rutas del manifiesto: faltan los componentes con punto o espacio final, los nombres de dispositivo y los nombres 8.3 |
| SPV-17 | Baja | Pruebas: el cerrojo 1 se prueba por texto (se elude con concatenación); faltan mutaciones para SPV-01, 04, 06 y 08; el doble no canoniza SID |

## 3. Checklist OWASP

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | SPV-04, SPV-06, SPV-09, SPV-14. Lo esencial está bien: DACL de la clave y de las carpetas, guardas de dueño ajeno y SDDL de DM-09 sin DC, WD, WO ni SD |
| A02 Criptografía | Correcta: CSPRNG de 48 bytes, SHA-256 por archivo, huella SPKI de la llave del sitio. Observación SPV-05 |
| A03 Inyección | Sin hallazgos [V]. `ArgumentList` en `sc.exe` y en los hijos; SID canonizado; XPath de eventos con constantes y rechazo de `'`; SQL con parámetros |
| A04 Diseño inseguro | SPV-01, SPV-03, SPV-11 |
| A05 Configuración | SPV-07, SPV-10, SPV-15 |
| A06 Componentes vulnerables | No aplica: no se agregan paquetes |
| A07 Autenticación | SPV-05 (ciclo de la clave JWT) |
| A08 Integridad de software | SPV-01, SPV-02, SPV-03, SPV-16 |
| A09 Registro y monitoreo | Correcto: eventos 5134 a 5138 sin la clave ni el entorno [V]. SPV-13 (menor) |
| A10 SSRF | No aplica en la práctica: `ObtenerAsync` exige una dirección del propio equipo y no usa proxy [V `SistemaServidorWindows.cs:372-373`] |

## 4. Hallazgos

### SPV-01 (Media): la huella distinta no revierte la copia
- **Riesgo:** los archivos se copian sobre el destino en el lugar (`FaseServicios.cs:190`) y la verificación es posterior (`:198-199`). Si una huella no coincide, la fase devuelve 4, pero el archivo no verificado se queda en `%ProgramFiles%\GPOS NG\Demo\api|reportes`. En una instalación nueva no se crean los servicios. En una **actualización**, el servicio ya existe y su imagen apunta a esa carpeta: el siguiente `Iniciar-Demo` ejecuta un binario no verificado como `NT SERVICE\GPOS.Api`, que lee la clave JWT de su entorno y tiene acceso a `GPOS_SYSDATA`. [V lectura; I escenario]
- **Evidencia:** [V] `FaseServicios.cs:186-199`. La prueba `tests/GPOS.Tests/Servidor/ImplantarServidorTests.cs:288-297` solo comprueba `Assert.Empty(s.Servicios)` y no que el destino quede limpio, así que una implementación que deja el archivo pasa.
- **Remediación** (unas 0,25 dp):
  - copiar a una carpeta de preparación con la DACL `CopiaPrevia`, dentro del destino, calculando la huella del flujo mientras se copia;
  - comparar, y solo entonces mover al destino (`File.Move` con sobrescritura, en el mismo volumen);
  - si alguna no coincide, borrar la preparación y no tocar el destino; si el fallo ocurre ya en el destino, restaurar desde `.anterior`.
  - Prueba de mutación: con `AlCopiar` alterando un archivo, el destino conserva las huellas anteriores.

### SPV-02 (Media): la copia sigue uniones y vínculos del origen
- **Riesgo:** `CopiarArchivo` usa `File.Copy(origen, destino)` (`SistemaServidorWindows.cs:162-166`), que sigue puntos de reanálisis. Un usuario estándar (o un proceso suyo) puede convertir `app\api` del paquete en una unión hacia una carpeta que solo leen los administradores. Puede crear uniones sin privilegios [I]. Entonces el proceso elevado lee el archivo con permisos de administrador y lo escribe en `Program Files\GPOS NG\Demo\api\…`, que hereda lectura para Usuarios. Aunque la huella no coincida, el archivo se queda (SPV-01): es una fuga de información. `ListarArchivos` sí omite los puntos de reanálisis, pero solo en el destino (`:150`).
- **Evidencia:** [V] `FaseServicios.cs:190` y `SistemaServidorWindows.cs:165`. No se comprueba el origen con `LeerCarpeta` ni con atributos.
- **Remediación** (unas 0,25 dp, junto con SPV-01): abrir cada archivo del origen con `FILE_FLAG_OPEN_REPARSE_POINT` y rechazar si es punto de reanálisis o si su ruta final (`GetFinalPathNameByHandle`) no está bajo `--origen\app`. Leer desde ese mismo identificador, sin reabrir por ruta.

### SPV-03 (Media, residual del DEMO): el manifiesto no está autenticado
- **Riesgo:** `manifiesto.sha256` se lee de `--origen` (`FaseServicios.cs:42`, `:108`), la misma carpeta, escribible por el usuario, que los binarios. La verificación en el destino (DM-08) protege contra un cambio **después** de leer el manifiesto. Quien pueda escribir en el paquete antes de la ejecución cambia binario y manifiesto a la vez y la verificación pasa.
- El mismo atacante ya puede cambiar los guiones `.ps1` que se ejecutan elevados, o `GPOS.Migracion.exe`, que se relanza a sí mismo como hijo desde `Environment.ProcessPath` (`SistemaServidorWindows.cs:433`). Por eso el manifiesto firmado solo no basta: el límite de confianza es la carpeta del paquete.
- **Evidencia:** [V] líneas citadas. [I] el paquete del DEMO se extrae en la carpeta del usuario (plan 2.2.5).
- **Remediación:**
  - (a) aceptarlo de forma explícita como residual del DEMO (sin costo), con la condición de que `Instalar-Demo` pida extraer el paquete en una carpeta solo de administradores; o
  - (b) firmar el manifiesto y comprobar la firma con una llave pública anclada, la misma pieza que el «manifiesto firmado» de la actualización automática. Cuesta unas 0,5 dp [I] y conviene que lo comparta con el *bundle*.
  - Alternativa descartada: copiar primero el paquete a una carpeta protegida. No evita una manipulación anterior a la copia.

### SPV-04 (Media): la comprobación de la DACL de la clave del servicio solo mira la lectura
- **Riesgo:** `MotivoClaveServicio` (`ReglasDescriptores.cs:95-105`) solo rechaza las ACE con `KEY_QUERY_VALUE`, `KEY_ENUMERATE_SUB_KEYS`, `GENERIC_READ` o `GENERIC_ALL` (`:44`). Se le escapan:
  - `GENERIC_EXECUTE`: en una clave del registro se traduce a `KEY_EXECUTE` = `KEY_READ` [I: tabla de derechos genéricos del registro], así que da lectura del valor `Environment` sin activar la máscara;
  - `WRITE_DAC`, `WRITE_OWNER`: quien los tiene se concede lectura a sí mismo;
  - `KEY_SET_VALUE`, `GENERIC_WRITE`: quien los tiene reescribe el entorno (su propia clave JWT, `TMP`, la cadena de conexión).
- Como la fase solo vuelve a aplicar la DACL si esta comprobación falla (`FaseServicios.cs:249-253`), una DACL protegida con dueño SYSTEM y una de esas ACE se acepta y se escribe la clave. R8 (`Comprobaciones/R8Entorno.cs:676`) da OK con la misma regla.
- **Evidencia:** [V] líneas citadas. La prueba `ComprobarServidorTests.cs:115-126` solo usa `KR` para BU.
- **Remediación** (unas 0,1 dp): con SYSTEM y administradores como únicos titulares admitidos, rechazar **cualquier** ACE de acceso concedido a otro SID, sea cual sea su máscara. Equivale a comparar con `SddlServicios.ClaveServicio` sin importar el orden ni las marcas de herencia. Añadir pruebas con `GX`, `WD`, `SV` (`KEY_SET_VALUE`) y `GW` para BU.

### SPV-05 (Media): se conserva una clave JWT que pudo estar expuesta
- **Riesgo:** sin `--rotar-jwt`, `EscribirClaveDemo` conserva cualquier `Jwt__Clave=` no vacío que ya estuviera (`FaseServicios.cs:99-101`). Si la fase tuvo que proteger la DACL (`:249-253`), la clave estuvo legible para `BUILTIN\Users` hasta ese momento: es la DACL por omisión [I, DE-10]. Además no se valida que la clave decodifique a 48 bytes. DM-06 pide una clave única **por instalación**.
- **Evidencia:** [V] líneas citadas.
- **Remediación** (unas 0,1 dp):
  - generar una clave nueva cuando la DACL no era conforme al entrar o cuando la previa no es Base64 de 48 bytes;
  - informarlo como «clave JWT nueva: la anterior pudo estar expuesta» (sin el valor) y emitir el evento 5137;
  - en PR-D2, `Instalar-Demo` pasa `--rotar-jwt`; `Actualizar` no lo pasa.

### SPV-06 (Media): `--usuario-instala` acepta grupos amplios
- **Riesgo:** el rechazo depende de `GruposAmplios`, que solo tiene IU, AU, BU y Todos (`ReglasDescriptores.cs:34-38`, `:125`). `ResolverSid` traduce cualquier cuenta o grupo (`SistemaServidorWindows.cs:71-83`), y la fase concede RP, WP, LC, LO, CC y RC a ese SID (`FaseServicios.cs:277-289`). Así, `Invitados` (S-1-5-32-546), `NT AUTHORITY\NETWORK` (S-1-5-2), `SERVICE` (S-1-5-6), `LOCAL` (S-1-2-0), `Cuenta local` (S-1-5-113), `Usuarios del dominio` (RID 513) o `Usuarios de escritorio remoto` reciben **WP**. Cualquiera de sus miembros puede detener `GPOS.Api` y abrir su propio servicio en 127.0.0.1:5071, y entonces recibe los inicios de sesión de la Web y de MAUI. Es una vía de captura de credenciales [I]. R4 no lo detecta porque no mira qué proceso escucha.
- **Evidencia:** [V] líneas citadas. La prueba `ImplantarServidorTests.cs:356-368` solo prueba «Usuarios».
- **Remediación** (unas 0,25 dp):
  - aceptar solo SID de **usuario** (`LookupAccountSid` con `SidTypeUser`; `NTAccount` no da el tipo) y rechazar los conocidos de las autoridades S-1-1, S-1-2, S-1-5-{1..20, 113, 114} y S-1-5-32-*, y los RID de grupo de dominio;
  - en R4, comprobar que el PID que escucha en 5071 y 5073 es el del servicio (`GetExtendedTcpTable` contra `QueryServiceStatusEx`).

### SPV-07 (Media): DM-03 está incompleto
- **Riesgo:** `LeerSeguridadSqlAsync` solo lee las bases `GPOS_*` con `is_trustworthy_on` y la pertenencia **directa** del inicio de sesión a roles de servidor (`SistemaServidorWindows.cs:401-422`). La lista prohibida de DM-03 (plan 2.2.2, punto 4) incluye **permisos** (`CONTROL SERVER`, `ALTER ANY LOGIN`, `IMPERSONATE`), que no son roles. Tampoco se mira lo que llega por `public`, ni lo que llega por inicios de sesión de grupo a los que pertenece la cuenta virtual (`BUILTIN\Users`, `NT AUTHORITY\SERVICE`, `NT SERVICE\ALL SERVICES`, `Authenticated Users`), que en instancias antiguas o mal configuradas pueden ser `sysadmin` [I]. La fase `esquema` (`FasesImplantacion/FaseEsquema.cs:50-53`) y `Comprobaciones/Dm03Sql.cs:141-147` dan OK en esos casos.
- **Evidencia:** [V] líneas citadas.
- **Remediación** (unas 0,25 dp):
  - leer `sys.server_permissions` (estado G o W) del inicio de sesión y de `public`; FALLA si aparece algo fuera de `CONNECT SQL` y `VIEW ANY DATABASE`;
  - leer los roles y permisos de los inicios de sesión de Windows cuyos SID estén entre los grupos del token de la cuenta virtual (lista fija de SID conocidos);
  - sin `EXECUTE AS LOGIN`, que exige `IMPERSONATE`.

### SPV-08 (Media, funcional que erosiona un control): R3 da FALLA siempre en Windows real
- **Riesgo:** `LeerCarpeta` pide solo dueño y DACL (`GetSecurityInfo` con `0x1|0x4`, y `GetSddlForm(Owner | Access)`, `SistemaServidorWindows.cs:106`, `:112`). El SDDL esperado (`SddlServicios.Raiz`, `Config` y `Componente`, `:199`, `:202`, `:208`) trae `G:SY`. `Equivalentes` compara la forma binaria y su longitud (`ReglasDescriptores.cs:135-143`), así que con el grupo de más nunca coincide. Por tanto R3 (`Comprobaciones/R3Carpetas.cs:491`) daría FALLA en la raíz, `Reportes`, `Api\anillo` y `config` de una instalación correcta [V por lectura]. A eso pueden sumarse diferencias en las marcas `AI` e `ID` [I]. El doble guarda el SDDL tal cual se escribió, con `G:SY` (`tests/GPOS.Tests/Servidor/SistemaServidorFalso.cs:320`), y oculta el defecto. Un control que siempre falla bloquea `Iniciar-Demo` o acostumbra a ignorar R3.
- **Remediación** (unas 0,1 dp): comparar solo dueño, DACL (conjunto de ACE, sin orden ni marcas de herencia) y la marca de protección. En el doble, quitar el grupo al leer, como hace Windows. Prueba: R3 da OK con el SDDL esperado sin `G:`.

### SPV-09 (Baja): carpetas existentes con lectores ajenos
`MotivoCarpeta` solo evalúa el dueño, los escritores y los puntos de reanálisis (`ReglasDescriptores.cs:52-75`). La fase `carpetas` acepta como «segura» una `Api\anillo`, `Api\registros` o `Api\temp` existente que leen los autenticados (`FasesImplantacion/FaseCarpetas.cs:337-339`). R3 cubre el anillo pero no `Api\registros` ni `Api\temp` (`R3Carpetas.cs:474-481`). Hace falta que antes un administrador la creara mal, de ahí la severidad. **Remediación:** en la fase, para las carpetas de componente, detener con 4 si `LectoresAjenosCarpeta` no está vacío, y añadir `Api\registros` y `Api\temp` a R3. [V]

### SPV-10 (Baja): `SeRestorePrivilege` queda habilitado
`HabilitarRestauracion` (`SistemaServidorWindows.cs:124`, `:453-468`) lo habilita y no lo deshabilita nunca. Lo tienen después `File.Copy`, `Directory.Delete`, `sc.exe` y los procesos hijos [I: el hijo recibe una copia del token con sus privilegios habilitados]. **Remediación:** deshabilitarlo en un `finally` tras `CreateDirectoryW` (con `AdjustTokenPrivileges` y el estado anterior). [V]

### SPV-11 (Baja): detección del ancla por subcadena
`FaseEsquema.cs:37-38` busca «Situación del ancla: Anclada» en cualquier línea, de salida estándar o de error (`SistemaServidorWindows.cs:443-444`), e ignora el código de salida de `anillo --comprobar`. Hoy el texto lo produce `Anillo/MantenimientoAnillo.cs:86`, al principio de la línea, y los avisos van con el prefijo «Aviso: ». Si un aviso o un error repitiera ese texto, la fase se saltaría el anclaje. El efecto es un DEMO sin ancla (la API no envuelve llaves nuevas: es fallo seguro), no una elevación. **Remediación:** exigir `StartsWith("Situación del ancla: Anclada;")` solo en la salida estándar o, mejor, un código o una salida estructurada propia de `anillo --comprobar`. [V]

### SPV-12 (Baja): grafías de Amplio y de credenciales
- `P7ModoIdentidad.cs:389` compara el texto exacto `GPOS__Seguridad__ModoIdentidad=Amplio`. Con `GPOS:Seguridad:ModoIdentidad=Amplio`, que .NET también lee del entorno (el mismo caso que JWT-01) [I], o con espacios, P7 diría «Estricto» con `--perfil produccion`.
- `R8Entorno.cs:638` y `:655` no reconocen `Pwd=` (válido en `SqlConnectionStringBuilder`) ni los nombres con `Key` o `Token`.
- **Remediación:** separar nombre y valor, normalizar `:` a `__` y quitar espacios antes de comparar; añadir `Pwd=`, `Key` y `Token`. [V]

### SPV-13 (Baja): alcance de `--sin-red` y lo único que escribe `comprobar-servidor`
- `--sin-red` solo afecta a P4 y R5 (`P4SaludApi.cs:325`, `R5SaludReportes.cs:573`). DM-03 abre una conexión a `ConnectionStrings:Sistema` (`Dm03Sql.cs:152`), que puede ser remota.
- El verbo no crea ni cambia configuración [V], pero escribe el evento 5138 (`ComandoComprobarServidor.cs:77-81`).
- **Remediación:** documentarlo en la ayuda o hacer que `--sin-red` también omita SQL cuando el servidor no es local.

### SPV-14 (Baja): `--destino` libre
`o.Destino ?? DestinoDemo(s)` (`FaseServicios.cs:44`) admite cualquier ruta. `PrepararDestino` solo comprueba el destino y su padre (`:142-159`), no los antepasados ni la pertenencia a `Program Files`. La comprobación de escritores atrapa casi todos los casos por herencia [V], pero no hace falta ampliar la superficie. **Remediación:** quitar `--destino` del perfil demo o exigir que esté bajo `%ProgramFiles%` y comprobar todos los antepasados.

### SPV-15 (Baja): idempotencia y restos
- `sc sdshow` suele traer la SACL (`S:(AU;FA;…;;;WD)`) [I]. Si es así, `Equivalentes(actual, sddl)` (`FaseServicios.cs:286`) no coincide nunca y `sdset` se repite en cada pasada, en contra de «repetir no cambia nada». Hay que confirmar también si `sdset` con solo `D:` borra la SACL de auditoría.
- `sc failure` sin `command=` (`SistemaServidorWindows.cs:217-218`) no borra un `FailureCommand` previo, así que `RecuperacionSoloReinicio` sigue en falso (`:181`) y se cuenta un cambio en cada pasada.
- Los archivos del destino que el manifiesto nuevo ya no trae se quedan: DLL antiguas que pueden cargarse.
- **Remediación:** comparar solo la DACL; borrar `FailureCommand` desde el registro, que ya se abre en esa clase; podar lo que no está en el manifiesto tras la copia previa.

### SPV-16 (Baja): validación de rutas del manifiesto
`FaseServicios.cs:122-123` rechaza las rutas absolutas, `..`, `.` y `:` [V]. No hay recorrido de rutas fuera de `destino\api` y `destino\reportes` [V]. Faltan los componentes con punto o espacio final (Windows los recorta, y dos entradas pueden apuntar al mismo archivo), los nombres de dispositivo (`CON`, `NUL`, `COM1`…) y los nombres 8.3. **Remediación:** lista blanca de caracteres `[A-Za-z0-9._-]`, sin punto ni espacio al final y sin nombres reservados.

### SPV-17 (Baja): pruebas que admiten mutaciones
- El cerrojo 1 se prueba por texto (`tests/GPOS.Tests/Servidor/ServidorArquitecturaTests.cs:41`). `"Jwt" + "__" + "Clave"` o una interpolación lo eluden. Hay que añadir una prueba de comportamiento: con perfil `produccion`, ninguna escritura de entorno del doble lleva un nombre con `Clave`.
- Faltan pruebas de mutación de:
  - SPV-01: el destino queda limpio tras una huella distinta;
  - SPV-04: `GX` y `WD` para BU;
  - SPV-06: Invitados y NETWORK;
  - SPV-08: R3 sin `G:`.
- El doble devuelve el SID tal como llega (`SistemaServidorFalso.cs:307`), así que ninguna prueba cubre el canonizado que impide la inyección de SDDL (en el código real está bien [V]).

## 5. Controles bien implementados [V]

- **Secreto JWT (DM-05, DM-15):**
  - generación `RandomNumberGenerator.GetBytes(48)` (`FaseServicios.cs:101`);
  - el valor solo viaja en la lista que va a `EscribirEntornoServicio` → `RegistryKey.SetValue(…, MultiString)` desde el propio proceso (`SistemaServidorWindows.cs:289-294`);
  - la salida y el evento solo dan el número de variables y «clave JWT nueva» (`FaseServicios.cs:265`, `:269-270`);
  - `sc.exe` no recibe el entorno (`SistemaServidorWindows.cs:208-220`);
  - `comprobar-servidor` nombra la variable, nunca su valor, y ante una excepción muestra el tipo y no el mensaje (`ComandoComprobarServidor.cs:56`);
  - prueba con el valor completo y fragmentos de 12 caracteres en la salida, los eventos, las operaciones y los argumentos (`ImplantarServidorTests.cs:250-272`).
- **Cerrojo 1 y perfil `produccion`:** el literal está en un solo método (prueba en `ServidorArquitecturaTests.cs:35-47`). Hay tres barreras: `ComandoImplantarServidor.cs:51-52`, `FaseServicios.cs:37` y `:95-96`. La salida de Q-5 (`SddlServicios.cs:230`) está separada de la del DEMO, con prueba que impide cruzarlas (`ServidorArquitecturaTests.cs:110-126`).
- **Orden de DM-01:** proteger, releer y solo entonces escribir (`FaseServicios.cs:249-263`), con prueba de orden y mutación «no se aplica» (`ImplantarServidorTests.cs:203-227`). La DACL `O:SYG:SYD:P(A;CI;KA;;;SY)(A;CI;KA;;;BA)` coincide con el plan.
- **Inyección:**
  - `sc.exe` con su ruta en System32, `ArgumentList` y sin consola (`SistemaServidorWindows.cs:229-241`);
  - la imagen va entre comillas (`DisposicionServidor.cs:285`), y P1 lo comprueba;
  - los hijos se lanzan con `ArgumentList` (`:434-441`), y el analizador toma literalmente el valor tras `--acta` y `--motivo`, aunque empiece por `--` (`Program.cs:480-481`), así que no se inyectan opciones;
  - `--usuario-instala` se canoniza con `SecurityIdentifier` o `NTAccount.Translate` (`SistemaServidorWindows.cs:75-77`) y el SDDL resultante se vuelve a evaluar (`FaseServicios.cs:281`).
- **Carpetas:**
  - creación con descriptor en `CreateDirectoryW` (`SistemaServidorWindows.cs:120-144`);
  - lectura sin seguir puntos de reanálisis y con comparación de ruta final, que cubre uniones en los antepasados (`:87-118`);
  - nueva comprobación tras crear (`FaseCarpetas.cs:336-338`);
  - parada con 4 ante un dueño ajeno, sin «arreglar»;
  - `%ProgramData%` no puede ser punto de reanálisis (`:316`).
  - El TOCTOU entre comprobar y crear queda cerrado por la propia DACL protegida de la raíz.
  - Las rutas con espacios (`GPOS NG`) no dan problemas en `sc`, el entorno ni DM-10.
- **Binarios:**
  - huellas leídas una vez antes de copiar y verificadas en el destino (`FaseServicios.cs:42`, `:198`);
  - `.anterior` con DACL `CopiaPrevia` y comprobación si ya existe (`:178-186`);
  - servicio existente con otra cuenta o imagen → 4 (`:218-221`);
  - privilegios, SID sin restricción, recuperación solo con reinicio e inicio manual (`:222-241`, `SistemaServidorWindows.cs:193-200`);
  - orígenes de eventos con `EventLogMessages.dll` de `%WINDIR%` (`:59-60`).
- **Llave del sitio:** la huella que imprime `llave-sitio` es el SHA-256 de la SPKI publicada (`src/GPOS.Comun/Sobres/LlaveSitio.cs:47-48`, `Lectura/ComandosLectura.cs:62-63`). La fase la recalcula sobre el archivo y para con 4 si difiere (`FaseLectura.cs:95-108`). Sin red, la fase termina con 1, lo que impide tomarla por completa (`:114`).
- **Falla cerrada de `comprobar-servidor`:** `NoComprobado` es AVISO; las pendientes son AVISO; una excepción es AVISO; sin filas es AVISO; gana el más grave (`ICatalogoComprobacion.cs`; `ComandoComprobarServidor.cs:53-61`). La lectura del entorno sin permiso devuelve null y no `[]` (`SistemaServidorWindows.cs:283-286`). Las peticiones HTTP solo van al propio equipo y sin proxy (`:372-373`).
- **El entorno no copia credenciales de `GPOS.Migracion`:** solo servidor, base y confianza en el certificado (`DisposicionServidor.cs:263-272`, `:355-370`).

## 6. Remediaciones priorizadas

| Orden | Hallazgos | Cuándo | Esfuerzo [I] |
|---|---|---|---|
| 1 | SPV-08 (R3 siempre FALLA) y SPV-04 (DACL de la clave por lista blanca) | antes de unir | 0,2 dp |
| 2 | SPV-01 + SPV-02 (preparación protegida, huella del flujo, sin seguir reanálisis, sin restos ante una huella distinta) | antes de unir (SPV-02 a más tardar antes de la VM) | 0,5 dp |
| 3 | SPV-06 (solo SID de usuario; R4 con el PID) y SPV-07 (permisos de servidor y grupos) | antes de unir | 0,5 dp |
| 4 | SPV-05 (rotar si la DACL no era conforme o la clave no tiene 48 bytes) + `--rotar-jwt` en `Instalar-Demo` (PR-D2) | antes de la VM | 0,1 dp |
| 5 | SPV-03: firma del propietario como residual del DEMO, o manifiesto firmado | antes de D4 | 0 o 0,5 dp |
| 6 | SPV-09 a SPV-17 | en PR-V si cabe; si no, en la siguiente pasada | 0,3 dp |

## 7. Lo que el doble en memoria no puede demostrar (verificar en la VM, spike P-8)

Todos estos casos se ejecutan solo en `VM-SRV`, desde el punto de control `base`, con evidencia sin valores (solo «presente/ausente» y los SDDL):

1. **Valor `Environment` de `GPOS.Api`:** `Get-Acl` de `HKLM\SYSTEM\CurrentControlSet\Services\GPOS.Api` tras la fase. Comprobar que `SetSecurityDescriptorSddlForm(…, Access)` deja la marca `P` y que la propagación con `CI` a las subclaves no rompe el servicio. El servicio debe arrancar con la DACL solo para SYSTEM y administradores (DE-10). Un usuario estándar no lee el valor.
2. **DACL por omisión** de la clave de un servicio recién creado (¿BU con `KR`?). Confirmar que la fase la detecta y la sustituye.
3. **`sc create`:** `obj= "NT SERVICE\GPOS.Api"` sin contraseña. Comprobar que el `ImagePath` guardado es exactamente `"…\GPOS.Api.exe" --servicio`. Si difiere en comillas o mayúsculas, la segunda pasada para con «otra imagen».
4. **`sc privs`, `sc sidtype`, `sc failure`:** los nombres y formatos reales de `RequiredPrivileges`, `ServiceSidType` y `FailureActions` en el registro, incluido el desplazamiento de `cActions` en 64 bits, con `SoloReinicio`. Comprobar también que `FailureCommand` queda vacío.
5. **`sc sdset` / `sc sdshow`:** si `sdshow` trae `S:`, si `sdset` con solo `D:` conserva o borra la SACL, y si la segunda pasada da `cambios=0` (SPV-15). DE-11: el usuario que instala inicia y detiene, pero `sc config` le da acceso denegado.
6. **Carpetas:** dueño `SY` con `SeRestorePrivilege`. `icacls` y `Get-Acl` de la raíz, `config`, `Api\*` y `Reportes`. Comprobar las marcas `P` y `AI` tal como quedan. Con SPV-08 corregido, R3 da OK en una instalación limpia.
7. **Uniones:** `%ProgramData%\GPOS NG` creada antes por un usuario estándar → 4 (dueño ajeno). Una unión en un antepasado → `PUNTO_DE_REANALISIS`. Una unión en `--origen\app\api` → rechazo (SPV-02 corregido).
8. **`GetFinalPathNameByHandleW` y `GetLongPathNameW`** con `C:\ProgramData` en rutas 8.3 y en un perfil con rutas largas: que no den falsos positivos de reanálisis.
9. **`EventLog.CreateEventSource`** con `EventLogMessages.dll` de `Framework64\v4.0.30319` en Windows Server: que el archivo existe y que los mensajes se ven en el Visor.
10. **Subprocesos:** con `GPOS.Migracion.exe` de archivo único y con `dotnet GPOS.Migracion.dll`, que la composición funciona, que el hijo no hereda nada sensible y que las salidas de `anillo --comprobar` y `llave-sitio` son las que se analizan.
11. **SQL (DE-14, DM-03):** `is_trustworthy_on = 0` en `GPOS_SYSDATA` y las `GPOS_*`; el inicio de sesión `NT SERVICE\GPOS.Api` sin roles ni permisos de servidor, también a través de grupos (SPV-07); la escalera de 2.2.2.
12. **Escucha (DE-15):** `GetActiveTcpListeners` muestra 5071 y 5073 solo en loopback. Con SPV-06: el PID que escucha es el del servicio. `\\.\pipe\` se enumera sin elevar.
13. **Falla cerrada:** `comprobar-servidor` en una consola sin elevar da 2 (no 0) y no crea ni cambia nada (salvo el evento 5138).
14. **Rotación:** tras `--rotar-jwt` y reiniciar el servicio, un token anterior se rechaza. La clave no aparece en `Recoger-Evidencia`, en el 4688 (auditoría de procesos activada) ni en el registro de PowerShell.

### Cierre
- Estado: Aprobado con observaciones (recomendación técnica: **Aprobar con condiciones**; sin hallazgos Críticos ni Altos; ocho Medios con condiciones antes de unir y antes de la VM).
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\revision-seguridad-pr-v-verbos-servidor-2026-10-22.md`.
- Supuestos: el paquete del DEMO se extrae en la carpeta del usuario (plan 2.2.5); un usuario estándar puede crear uniones de directorio; `GENERIC_EXECUTE` en una clave equivale a `KEY_READ`; `sc sdshow` devuelve la SACL. Lo marcado [I] se confirma en la VM.
- Decisiones candidatas a ADR: manifiesto del paquete firmado (SPV-03), compartido con la actualización automática y el *bundle*; alternativa descartada: copiar el paquete a una carpeta protegida (no evita la manipulación previa).
- Entregas a otros agentes: arquitecto-software y desarrollador de A → SPV-01, 02, 04 a 08 (y 09 a 17 si caben); devops de A (PR-D2) → `--rotar-jwt` en `Instalar-Demo` y la extracción en una carpeta protegida (SPV-03, SPV-05); B/C (spike P-8) → sección 7; arquitecto-maestro → el ADR candidato y la firma de SPV-03 como residual.
- Próximo paso recomendado: corregir SPV-08 y SPV-04 (0,2 dp) y la copia por preparación (SPV-01 y SPV-02), y repetir esta revisión solo sobre ese diff.
