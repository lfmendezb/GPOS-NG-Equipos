[Informe de Seguridad] PR #168 (E-1, ADR-93 TA-P08) y PR #170 (T4-03a, Chromium aislado)

Fecha: 2026-10-22 · Auditor: auditor-seguridad (revisión independiente, previa a la de A) · Solo lectura: `git diff 1e6e96c0..HEAD` en los worktrees `GPOS-B-e1` (rama `b/e1-adr93-alcance-sucursal`, @2c394a44) y `GPOS-B-t4-03a` (rama `b/ola5-t4-03a`, @5b1f4bdc). No se compiló, no se ejecutó nada y no se modificó el repositorio.
Convención: **[V]** verificado leyendo el código; **[I]** inferido, sin ejecutar. Las rutas `e1:` y `t4:` son relativas a cada worktree.
Referencias: hoja firmada `docs/decisiones/2026-10-22-hoja-firma-s16-q-a1-a-q-a5.md` (commit 121ef0ec); lista de rutas y adenda de A (`GPOS-NG-Equipos/traspasos/A/rutas-inventario-sin-filtro-sucursal-2026-10-21.md`); blueprint T4-03 (scratchpad); revisión de A del #152.

---

## 1. Alcance y superficie revisada

**#168 (19 archivos, +1162/−45).**
- `RevocacionSesiones.Evaluar` (401 de Q-A2). Se ejecuta en cada petición autenticada desde `OnTokenValidated` (`e1:src/GPOS.Api/Program.cs:98-106`) y en la introspección de la API de reportes (`ValidadorTokenPrincipal.cs:41`).
- P-0: `IAlcanceAlmacenes`, `AlcanceResuelto` y `EstadoCuentaRevocacion`.
- R-01 (`GET /api/inventario/existencias`), R-02 (`/kardex/{articulo}`) y R-04 (`GET/POST /api/maestros/articulos`, más el puente heredado).
- Mensaje de «Requiere lote», diseñador de reportes (Q-A3) y regla del SUPER (Q-A5).
- Fuera del PR, por partición firmada (S-16b), quedan R-03 y R-05 a R-13 (sección 6).

**#170 (11 archivos, +1244/−32).**
- `ConvertidorPdf`: contexto por render, capa 1, perfil, limpieza y medición por CDP.
- `PoliticaRedNavegador` (capa 2, lista blanca y origen registrado).
- `ServicioRender.SanearLogo` y la preparación de la carpeta `render` en `Program.cs`.
- Fuera del PR, por el blueprint (T4-03b): CSP, Job Object, ruta del navegador limitada (S152-10) y capa 3 (cortafuegos).

## 2. Tabla resumen de hallazgos

| ID | Sev. | PR | Título | V/I |
|---|---|---|---|---|
| M-168-1 | Media | #168 | Q-A5 incompleta: la API de reportes y el inicio de sesión siguen restringiendo al SUPER con bandera; no existe la regla única `UsuarioAlcance.Restringe` | V |
| M-168-2 | Media | #168 (preexistente) | El ADMIN restringido puede quitarse la restricción (o crear una cuenta sin ella) desde Usuarios: D-3 y Q-A3 no son un límite para el ADMIN | V |
| B-168-3 | Baja | #168 | El alcance y el 401 comparan solo la sucursal, no la empresa (`EmpresaDefault`): un restringido que entra a otra empresa queda en la sucursal homónima | V/I |
| B-168-4 | Baja | #168 | En una misma petición, el alcance puede salir de una lectura de la cuenta más nueva que la que validó el token | I |
| B-168-5 | Baja | #168 | El puente heredado compara los códigos de almacén en C# (`OrdinalIgnoreCase`), no por llave | V |
| M-170-1 | Media | #170 | La capa 1 no ve las sugerencias de recursos (`preconnect`, `dns-prefetch`, `prefetch`) ni los WebSocket; la «independencia de capas» no se cumple para ellas y P-04 no lo prueba | I |
| M-170-2 | Media | #170 | La lista blanca admite `data:` como documento (`<iframe>`/`<object>` con `data:text/html`); no está probado que el JavaScript apagado y la intercepción alcancen al marco anidado | I |
| B-170-3 | Baja | #170 | Un `data:` no representable en un marco puede disparar una descarga fuera de `render\` (disco de la cuenta del servicio) | I |
| B-170-4 | Baja | #170 | El evento 5117 registra el anfitrión completo; una plantilla puede meter datos del documento en el nombre del anfitrión | V |
| B-170-5 | Baja | #170 | `Thread.Sleep` de hasta 2 s dentro del semáforo del navegador al relanzar | V |
| B-170-6 | Baja | #170 | En desarrollo, `%TEMP%\gpos-render` es compartida: la limpieza de un proceso puede borrar el perfil en uso de otro | V |

Ningún hallazgo Crítico ni Alto en ninguno de los dos PR.

## 3. Checklist OWASP

| Categoría | #168 | #170 |
|---|---|---|
| A01 Control de acceso | Revisado: alcance en el servidor, 401 por sucursal, IDOR por `?almacen=` cerrado en R-01 y R-02, guardado de R-04 sin canal lateral; M-168-1, M-168-2, B-168-3 | Revisado: el render conserva la autenticación de T4-01; sin cambios |
| A02 Criptografía | No aplica | No aplica |
| A03 Inyección | Revisado: SQL con parámetros tipados (ADR-50: `bit`, `smallint`, `varchar(20)`) y sin concatenación; B-168-5 | Revisado: plantilla Razor del SUPER (la inyección en Razor es T4-10); argumentos de Chromium fijos, no configurables |
| A04 Diseño inseguro | Revisado: falla cerrada (`default` = Vacío; `@global=0` con `NULL` no devuelve filas) | Revisado: M-170-1, M-170-2 |
| A05 Configuración | No aplica | Revisado: `ComprobarCarpeta=false` solo en Debug (`t4:src/GPOS.Reportes.Api/Program.cs:63-66`); `Pipe = true`; B-170-6 |
| A06 Componentes vulnerables | No revisado: no hay herramienta en esta sesión; el PR no agrega paquetes | Ídem; PuppeteerSharp 25.12.0 ya existía |
| A07 Autenticación | Revisado: 401 `credenciales` con token viejo o sin sucursal | No aplica |
| A08 Integridad | Revisado: el guardado del restringido conserva los niveles ajenos | Revisado: logo saneado al renderizar |
| A09 Registro y monitoreo | Sin registro nuevo (el 401 ya tiene encabezado) | Revisado: 5117 sin ruta ni consulta, con tope por render; B-170-4 |
| A10 SSRF | No aplica | Revisado: capas 1 y 2; M-170-1, M-170-2 |

---

## 4. Hallazgos

### PR #168

**M-168-1 · Media · Q-A5 incompleta [V]**
- **Riesgo.** No es una fuga: la API de reportes es más restrictiva, y por tanto falla cerrada. Pero la hoja firmada exige «una sola regla (`UsuarioAlcance.Restringe(nivel, bandera)` en `GPOS.Core`) para la principal y la API de reportes (`ProveedorContexto`) … dentro de E-1 (P-0)». Con dos reglas, la frontera puede derivar entre los dos caminos.
- **Evidencia.**
  - `e1:src/GPOS.Core/Sistema/UsuariosService.cs:930`: la regla está en línea (`Restringida`) y solo la usa la principal.
  - `e1:src/GPOS.Reportes/Contexto/ProveedorContexto.cs:74` y `:92` (`if (!u.RestringirSucursal) return delToken;`), y `ContextoReportes.cs:43` (`PuedeDisenar => EsAdmin && !RestringirSucursal`): siguen restringiendo al SUPER con bandera, que no puede diseñar por la API de reportes y sí por la principal.
  - `UsuariosService.ResolverSucursal` (`:766-772`): el inicio de sesión sigue obligando al SUPER con bandera a usar su `SucursalDefault` y lo rechaza en una empresa sin esa sucursal.
  - No existe `UsuarioAlcance` en `src/`.
- **Remediación** (unos 0,15 dp; USD 0).
  - Crear `UsuarioAlcance.Restringe(nivel, bandera)` en Core y usarla en `EstadoSesionUsuario.Restringida`, `ResolverSucursal`, `ProveedorContexto` (sucursal y `RestringirSucursal` del contexto) y `PuedeDisenar`.
  - Agregar una prueba de paridad: SUPER con bandera puede diseñar y ve todas las sucursales en los dos caminos.
  - Si no entra en este PR, `docs/adr/estado.json` no debe marcar Q-A5 como construida.

**M-168-2 · Media · El ADMIN restringido se libera solo (preexistente; condiciona D-3 y Q-A3) [V]**
- **Riesgo.**
  - `POST /api/admin/usuarios` deja que cualquier ADMIN modifique cualquier cuenta que no sea SUPER, **incluida la propia**. Solo prohíbe inhabilitarse y cambiarse la contraseña (`e1:src/GPOS.Api/Endpoints/AdminEndpoints.cs:167-175`).
  - `UsuariosService.GuardarAsync` asigna `RestringirSucursal` y `SucursalDefault` desde el DTO sin mirar quién guarda (`e1:src/GPOS.Core/Sistema/UsuariosService.cs:494-497`), y vuelve a sellar la cuenta por el camino legítimo.
  - Después, `RegistrarCuenta` llama a `Olvidar` (`RevocacionSesiones.cs:224`). En la petición siguiente `Restringida` es falsa, `SucursalAjena` no aplica y el alcance pasa a ser global. No hace falta volver a iniciar sesión.
  - También puede crear una cuenta sin restricción.
  - Consecuencia: la restricción del ADMIN (D-3), la paridad del diseñador (Q-A3) y R-01, R-02 y R-04 no son un control para un ADMIN. Para el USER sí lo son.
- **Remediación (barata, 0,1 a 0,15 dp).** Si el solicitante es un ADMIN con `Restringida`:
  - 403 en la gestión de cuentas (`POST /usuarios`, inhabilitar, cerrar sesiones y desbloquear); como mínimo, prohibirle cambiar `RestringirSucursal`, `SucursalDefault`, `EmpresaDefault` o `Nivel` de cualquier cuenta y crear cuentas sin restricción;
  - la misma comprobación con `IAlcanceAlmacenes.SinRestriccionAsync`, que ya existe.
  - **Alternativa:** dejar escrito (precisión de TA-P08) que `RestringirSucursal` en un ADMIN es solo orientativa. Es más barata, pero vacía Q-A3.
  - Decide B o el propietario.

**B-168-3 · Baja · Sin comparación de empresa [V código, I explotación]**
- **Evidencia.**
  - `SucursalAjena` y `AlcanceAlmacenes.ResolverAsync` usan solo `SucursalDefault`, que se resuelve por código en la base de la empresa del token (`e1:src/GPOS.Api/Seguridad/RevocacionSesiones.cs:191-194`; `e1:src/GPOS.Core/Servicios/Modulos/Inventario/AlcanceAlmacenes.cs:110-112`).
  - El inicio de sesión no obliga al restringido a usar su `EmpresaDefault` (`AuthEndpoints.cs:350-353`).
  - El sello de habilitación sí liga la restricción a la pareja empresa y sucursal (`SellosHabilitacion.cs:129`, `HuellaSucursal(EmpresaDefault, SucursalDefault)`).
- **Riesgo.** Un restringido con acceso a otra empresa entra en ella y queda en la sucursal que tenga el mismo código. Lo inferido es que tenga ese acceso antes de la v1 de DB-7.
- **Remediación.** En `SucursalAjena`, para el restringido, comparar también la empresa del token con `EmpresaDefault`, y agregar `EmpresaDefault` a `EstadoSesionUsuario`. Son 0,05 dp. Alternativa: dejarlo para DB-7, donde la membresía por empresa lo resuelve.

**B-168-4 · Baja · Lectura de la cuenta en dos tiempos [I]**
- **Evidencia.** `EstadoCuentaRevocacion` usa `revocacion.Guardada(usuario)` (`e1:src/GPOS.Api/Seguridad/EstadoCuentaSesion.cs:13-14`), que devuelve la lectura guardada en ese momento, sin vigencia (`RevocacionSesiones.cs:140`).
- **Riesgo.** Si otra petición la renueva entre `Evaluar` y el alcance, la petición valida con la sucursal S1 y lee con la S2, mientras las escrituras usan la sucursal del token. La ventana es de milisegundos y no abre datos de una tercera sucursal.
- **Remediación (opcional).** Guardar en `HttpContext.Items` la cuenta con la que se validó y que `EstadoCuentaRevocacion` lea esa.

**B-168-5 · Baja · Puente heredado por código [V]**
- **Evidencia.** `e1:src/GPOS.Core/Infraestructura/Transicion/PuenteMae.cs:217-218` compara `IdAlmacen` con `OrdinalIgnoreCase`, contra la decisión de A de comparar por llave (V-01, V-02 y V-08).
- **Riesgo.** Si la intercalación iguala dos códigos que C# no iguala, no se borra la fila y la inserción siguiente falla por duplicado. Falla cerrada, sin fuga. El puente es transitorio.
- **Remediación.** Aceptar con una nota, o resolver las llaves heredadas por SQL.

### PR #170

**M-170-1 · Media · La capa 1 no cubre las sugerencias de recursos ni los WebSocket [I]**
- **Riesgo.**
  - `Fetch.requestPaused` solo ve las peticiones de recursos. Lo inferido: `<link rel=preconnect>` y `dns-prefetch` abren un socket o resuelven un nombre sin generar una petición interceptable; `prefetch` o las reglas de especulación pueden salir del proceso de red sin pasar por el marco; y los WebSocket nunca pasan por `Fetch`.
  - La documentación del código afirma que la capa 1 aborta `ws` y que «cada capa corta sola» (`t4:src/GPOS.Reportes.Api/Impresion/PoliticaRedNavegador.cs:6-13`, `:56-59`). Para estos vectores, la protección real es la capa 2 más el JavaScript apagado.
  - P-02 incluye las sugerencias, pero con las dos capas activas (`t4:tests/GPOS.Reportes.Tests/ChromiumAisladoTests.cs:203`). P-04, la capa 1 sola, solo prueba `<img>` y `<link stylesheet>` (`:301-302`).
  - Si una versión de Chrome o Edge cambia `--host-resolver-rules` o el tratamiento de `<-loopback>` (R-T403-01), `dns-prefetch` abre un canal de salida por DNS con datos del documento puestos en el nombre del anfitrión. Requiere una plantilla Razor del SUPER.
- **Remediación** (0,1 dp).
  1. Agregar a P-03 (capa 2 sola) los vectores de `preconnect`, `dns-prefetch` y `prefetch`.
  2. Agregar a P-04 (capa 1 sola) los mismos vectores, con el resultado esperado documentado. Si llegan conexiones, se dice así.
  3. Corregir la documentación: `ws` no lo cubre la capa 1, sino el JavaScript apagado más la capa 2.
  4. Capa 0 de T4-03b: valorar quitar en el servidor `<link rel=preconnect|dns-prefetch|prefetch|prerender|modulepreload>` y `<script type=speculationrules>` del HTML antes de enviarlo.

**M-170-2 · Media · `data:` como documento anidado [I]**
- **Evidencia.** `Permitida` admite cualquier `data:` (`t4:src/GPOS.Reportes.Api/Impresion/PoliticaRedNavegador.cs:58-59`), también un documento.
- **Riesgo.**
  - Chromium no permite navegar el marco principal a `data:`, pero sí cargar `<iframe src="data:text/html,…">` y `<object data="data:text/html,…">`.
  - Ese documento tiene origen opaco y, según la versión y el aislamiento de sitios, puede ir en otro proceso (OOPIF). Que `SetJavaScriptEnabledAsync(false)` (`ConvertidorPdf.cs:205`) y la intercepción (`:209`) se apliquen a ese destino depende de que PuppeteerSharp se enganche a los destinos hijos, y eso no está probado [I].
  - Si no se aplican, el marco anidado ejecuta JavaScript y pide recursos que solo la capa 2 corta. P-02 y P-05 no prueban un `<iframe>` con `data:text/html` que contenga `<img src=http…>` y `<script>`.
- **Remediación** (0,05 a 0,1 dp; recomendada antes de unir porque es barata).
  - Permitir `data:` solo para los tipos de recurso que necesita un formato (`IRequest.ResourceType` imagen, fuente o hoja de estilo) y abortar `data:` con `Document` u `Other` en un marco que no sea el principal.
  - Agregar la prueba con `<iframe>` y `<object>` `data:text/html` que incluyan `<img src=http://127.0.0.1:{p}>` y un `<script>` que cambie el título: con la capa 2 apagada, 0 conexiones y el título sin cambio.

**B-170-3 · Baja · Descargas [I]**
- **Riesgo.** Un `<iframe src="data:application/octet-stream;base64,…">` puede convertirse en una descarga. Según la versión, el modo sin interfaz la guarda en la carpeta de descargas de la cuenta virtual, fuera de `render\`, y no se limpia. Es un DoS de disco lento, acotado por el tope de 16 MB del cuerpo y por la tasa de renders.
- **Remediación.** Enviar `Browser.setDownloadBehavior { behavior: "deny" }` por CDP en cada contexto. Con la remediación de M-170-2 casi desaparece.

**B-170-4 · Baja · Anfitrión en el evento 5117 [V]**
- **Evidencia.** `PoliticaRedNavegador.Origen` registra `esquema://autoridad`: excluye la ruta, la consulta y las credenciales, lo que es correcto (`PoliticaRedNavegador.cs:68-76`; `ConvertidorPdf.cs:429`).
- **Riesgo.** Una plantilla que construya el anfitrión con datos del modelo (por ejemplo, `http://{RNC}.x.test`) deja esos datos en el registro de eventos. Requiere una plantilla del SUPER.
- **Remediación (opcional).** Si el anfitrión no es una IP, recortarlo a 63 caracteres o registrar solo el dominio registrable.

**B-170-5 · Baja · Espera bloqueante en el semáforo [V]**
- **Evidencia.** `BorrarPerfil` hace `Thread.Sleep(200)` hasta 10 veces (`t4:src/GPOS.Reportes.Api/Impresion/ConvertidorPdf.cs:377`, `:396`) dentro de `NavegadorAsync`, que tiene `_bloqueo` tomado. Un ciclo de caídas del navegador encadena esperas de 2 s y bloquea un hilo del grupo.
- **Remediación.** `await Task.Delay(200)`, o borrar el perfil fuera del semáforo (moverlo a una cola de limpieza).

**B-170-6 · Baja · Carpeta compartida en desarrollo [V]**
- **Evidencia.** `UsarCarpetaSinComprobar(Path.Combine(Path.GetTempPath(), "gpos-render"))` (`t4:src/GPOS.Reportes.Api/Program.cs:100`) llama a `LimpiarHuerfanos`, que borra todos los `perfil-*` que no son del propio proceso (`ConvertidorPdf.cs:120-136`).
- **Riesgo.** Dos procesos (la API en desarrollo y la suite, o dos suites) se borran el perfil en uso. Solo en desarrollo; puede causar pruebas inestables.
- **Remediación.** En desarrollo, una subcarpeta por proceso, o no borrar los perfiles más recientes que el arranque del proceso.

---

## 5. Controles bien implementados

**#168**
- **Restricción leída del servidor, nunca del token.** `EstadoSesionUsuario` trae `RestringirSucursal` y `SucursalDefault` de la misma lectura de `GPOS_SYSDATA`, sin consulta extra (`UsuariosService.cs:672`, `:924`). El SUPER queda exento por el nivel de la cuenta, no por el del token (`:930`).
- **401 de Q-A2.** Va después del sello y no tapa las causas anteriores. Cubre el token viejo, el token sin sucursal y el restringido sin sucursal asignada (`RevocacionSesiones.cs:179`, `:191-194`). La comparación es la misma del inicio de sesión (`UsuariosService.cs:765-772`), así que no deja cuentas sin poder entrar. Cierra la fuga por el mensaje de faltante del guardado y las escrituras que toman la sucursal del token.
- **`AlcanceResuelto` cerrado.** Tiene constructor `internal` y su `default` es Vacío. Una cuenta inexistente, inhabilitada o sin usuario da Vacío. Un código de sucursal que no resuelve también da Vacío, nunca Global (`AlcanceAlmacenes.cs:103-115`). El patrón SQL `(@global = 1 OR al.SucursalId = @sucursalAlcance)` no devuelve filas con `NULL`.
- **Constructores públicos.** Los servicios solo tienen constructores públicos que exigen el alcance, y la inyección de dependencias no puede elegir el interno (`InventarioService.cs`, `MaestrosService.cs`, `ReportesService.cs`). La prueba `El_unico_constructor_publico_exige_el_alcance` lo fija.
- **R-01 y R-02.** Un almacén ajeno da la misma lista vacía que uno inexistente. Se corrigió la falla abierta del código desconocido que daba «todos» para cualquier usuario. `SaldoAntes` también va filtrado. La comprobación es por llave (`InventarioService.cs:748-768`; `ConsultasDocInventario.cs` Kardex, SaldoAntes y Existencias).
- **R-04.**
  - Lectura: niveles, existencias y total dentro del alcance.
  - Guardado:
    - una fila de un almacén ajeno recibe el error de uno inexistente;
    - las filas de fuera del alcance no se borran, ni en el modelo nuevo ni en el heredado;
    - el restringido Vacío no borra nada.
  - Evidencia: `MaestrosService.Articulos.cs:154-181`, `:218`, `:317-323`, `:392`, `:397`.
- **«Requiere lote».** El texto va sin cifras para quien no es global (`LotesDocumento.cs:156-170`; `MaestrosService.Articulos.cs:338`).
- **Diseñador.** Detectar, vista previa, guardar y eliminar comprueban antes de validar o ejecutar nada. Responden 403 `DISENO_NO_PERMITIDO`, con el mismo código y texto de la API de reportes (`ReportesService.cs:266-271`).
- **ADR-50.** Los parámetros van tipados: `bit`, `smallint` (`DbType.Int16`) y `varchar(20)` con `Sql.Varchar`, que coincide con `org.Sucursal.Codigo varchar(20)`.
- **Pruebas.** Hay 36, que cubren AL-10 a AL-15, R-01, R-02, R-04, R-VIEJO-1 a R-VIEJO-3, F-25 y Q-A5 en la principal.

**#170**
- **`Pipe = true`.** Sin puerto de depuración TCP; cierra R152-06 y la condición U-2. `--remote-debugging-port` está en `Prohibidos` (`ConvertidorPdf.cs:336`; `PoliticaRedNavegador.cs:49-54`).
- **Contexto incógnito por render**, cerrado en `finally`. La página se crea sin `.WaitAsync(ct)`, así que no queda huérfana (`ConvertidorPdf.cs:140-174`).
- **Capa 1.**
  - Lista blanca estricta: prefijo `data:` sensible a mayúsculas, `about:blank` exacto y sin espacios delante. Lo prueban 19 casos de la teoría.
  - El manejador falla cerrado: un error termina en un intento de abortar, nunca en continuar.
  - JavaScript apagado antes de cargar nada, en todos los modos.
- **Capa 2.** Proxy muerto con `<-loopback>` y resolvedor nulo. Hay una prueba por cada mitad, con control positivo, y el control de que la escucha detecta la salida.
- **Perfil.**
  - Está en `%ProgramData%\GPOS NG\Reportes\render`, comprobado según ADR-77, con nombre de 128 bits.
  - `TEMP` y `TMP` del navegador van dentro del perfil.
  - El perfil se borra al cerrar o relanzar el navegador, y los huérfanos al arrancar, saltando los puntos de reanálisis y el perfil en uso.
  - Sin la carpeta comprobada: 503 y evento 5119, y los formatos estándar siguen funcionando (`ConvertidorPdf.cs:82-104`, `:120-136`; `Program.cs:83-101`).
  - `Directory.Delete` recursivo en .NET quita las uniones sin seguirlas. Además, a `render\` solo escriben la cuenta del servicio y los administradores.
- **Logo.** Se revalida al renderizar, con el tope de la principal, y el evento lleva el motivo pero no el contenido (`ServicioRender.cs:617-628`).
- **Eventos.** El 5117 va sin la ruta ni la consulta, y con un tope de 5 eventos más un total por render.
- **Opciones de prueba.** Las que apagan capas son `internal` y no se pueden enlazar a la configuración.

## 6. Riesgo residual conocido (no son hallazgos de estos PR)

- **Frontera de confidencialidad incompleta hasta S-16b.** Siguen abiertas R-03 (existencia global en la lista de artículos, `MaestrosService.Articulos.cs:61`), R-05 a R-13 y el residuo 1 de transferencias. R-05 (`/api/catalogos/articulos/{codigo}/linea`) no exige ningún permiso y devuelve la suma global. **Recomendación:** mientras S-16b no se una, no presentar `RestringirSucursal` a un cliente como control de confidencialidad.
- **#170.** Quedan para T4-03b la CSP, el Job Object y la ruta del navegador configurable (S152-10: ejecutable arbitrario desde la configuración). La capa 3 del cortafuegos no existe todavía (instalador). El loopback depende de las capas 1 y 2.

## 7. Remediaciones priorizadas

1. M-170-2: `data:` solo para subrecursos, más la prueba del `iframe` `data:text/html`. Unos 0,1 dp.
2. M-168-1: regla única de Q-A5 en la principal, el inicio de sesión y la API de reportes. Unos 0,15 dp; o bien dejar Q-A5 como pendiente en `estado.json`.
3. M-168-2: bloquear la gestión de cuentas al ADMIN restringido, o una precisión escrita de que en el ADMIN la restricción es orientativa. Unos 0,1 a 0,15 dp.
4. M-170-1: vectores de sugerencias en P-03 y P-04 y corregir la documentación. Unos 0,1 dp.
5. Las Bajas: B-168-3 (0,05 dp) y B-170-3 a B-170-6 (unos 0,15 dp en total).

Costo de infraestructura: USD 0. Sin paquetes nuevos.

## 8. Recomendación (técnica; la orden de unión es del propietario)

- **PR #168: Aprobado con observaciones (Aprobar).**
  - No hay hallazgos Críticos ni Altos, y el PR cierra fugas reales: el token viejo y el código de almacén desconocido que daba «todos».
  - M-168-1 es parte firmada de E-1. Se corrige en este PR o, si se une sin ella, Q-A5 se registra como no construida.
  - M-168-2 es anterior al PR y requiere una decisión.
- **PR #170: Aprobado con observaciones (Aprobar).**
  - Se recomienda corregir M-170-2 antes de unir porque es barata y cierra la duda sobre el núcleo de la capa 1.
  - M-170-1 puede ir en este PR o en T4-03b.

### Cierre
- Estado: Aprobado con observaciones (#168 y #170)
- Artefactos: `C:\Users\lfmen\AppData\Local\Temp\claude\C--Users-lfmen-source-repos-Solucion-GPOS-NG-GPOS-NG\a8083c99-fe36-432e-bde4-46ec95e0ccbd\scratchpad\auditoria-b-168-170.md`
- Supuestos:
  - Nada compilado ni ejecutado. El comportamiento de Chromium (las sugerencias fuera de `Fetch`, los OOPIF de `data:` y las descargas) es [I] y lo deciden las pruebas propuestas.
  - Las 36 pruebas del #168 y las del #170 no se corrieron.
  - Se asume que un restringido puede tener acceso a otra empresa antes de DB-7 v1 (B-168-3).
- Decisiones candidatas a ADR:
  - precisión de TA-P08 (ADR-93) sobre si la restricción de un ADMIN es un control o solo orientativa (M-168-2);
  - precisión de ADR-110 cl. 7: `data:` solo para subrecursos (M-170-2).
- Entregas a otros agentes:
  - backend de B: M-168-1, M-170-2 y M-170-1;
  - B o el propietario: decidir M-168-2;
  - qa-automatizado (C): las pruebas nuevas de M-170-1 y M-170-2 y la paridad de Q-A5;
  - documentador: `estado.json` (Q-A5) según lo que se una.
- Próximo paso recomendado: B corrige M-170-2 y M-168-1 (o registra Q-A5 como pendiente) y pasa ambos PR a la revisión de A con este informe.
