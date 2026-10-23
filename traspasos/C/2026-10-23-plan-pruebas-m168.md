Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (tarea 4 de B-a-C/2026-10-22-tareas-nuevas-para-c-3: plan de pruebas de M-168-2 y M-168-1)
Prioridad: Media
Repositorio y rama: GPOS-NG `feature/modelo-ng` (lectura)
Estado: Abierto

# Plan de pruebas de M-168-2 (gestión de la restricción por sucursal) y M-168-1 (regla única del SUPER)

**Método:** solo lectura. `git fetch`, `git show`/`git grep` sobre `origin/feature/modelo-ng` (punta `67b4353a`, que contiene el #168 unido en `760e79b1`), `gh pr view 177`, el área común y mis dos insumos: [plan S-16 v2](../traspasos/C/2026-10-22-plan-pruebas-s16-particion-e1.md) y [revisión de pruebas del #168](../traspasos/C/2026-10-23-revision-pruebas-pr168.md). **No compilé ni ejecuté nada.** `[V]` = visto en código o aserción; `[I]` = inferido. Rutas de prueba sin prefijo: `tests/GPOS.Tests/Alcance/`. No repito lo que ya cubrí en mi revisión (P168-01 a P168-15 y la matriz S-16): aquí solo entra lo de M-168-1/M-168-2 que esa revisión dejó fuera ("leí solo nombres" de `RestriccionSoloSuper*`, `CuentaFueraDeAlcance*`, `LecturasCuentasRestringidoTests`); esta vez leí a fondo `RestriccionSoloSuperTests`, `RestriccionSoloSuperHttpTests`, `CuentaFueraDeAlcanceHttpTests`, `AdminSinRestriccionHttpTests` (rutas, bitácora) y los `QA5_*`/`S168_05_*` de `SucursalTokenRestringidoTests`, `SucursalesAccesoTests` y `ProveedorContextoTests`; de `CuentaFueraDeAlcanceTests` y `LecturasCuentasRestringidoTests` solo los nombres.

## 0. Corrección al encargo: la regla de M-168-2 ya no es "solo el SUPER"

El encargo dice "403 al ADMIN que toque la bandera; hoja del #177". **El #177 (hoja `2026-10-22-hoja-firma-m-168-2-restriccion-solo-super.md`, unido el 2026-10-22 23:09 UTC) quedó sustituido en ese punto** por la hoja `2026-10-22-hoja-firma-admin-sin-restriccion-fija-la-restriccion.md` (en `master`; nota de ADR-93 con "Sustituye a la nota de M-168-2") y por el commit `16a66c8d` del #168 [V]. Regla vigente (oráculo de este plan) [V: `src/GPOS.Core/Sistema/UsuariosService.cs:449-505`]:

| Solicitante (según su cuenta guardada en `GPOS_SYSDATA`, nunca el token) | Puede cambiar bandera / empresa / sucursal de otra cuenta | Su propia restricción | Alta de cuentas |
|---|---|---|---|
| SUPER (`sesion.EsSuper`) | Sí, todo | Sí | Todo |
| ADMIN sin restricción (ADMIN-G) | Sí (activar, quitar, cambiar empresa o sucursal de una restringida) | **No** (403) | Con o sin bandera |
| ADMIN restringido (ADMIN-R) | **No** (403 `RESTRICCION_SOLO_SUPER`) | No | Solo restringidas a su misma empresa y sucursal |
| Cuenta guardada que no es ADMIN, sin cuenta, o sin solicitante | No (403, falla cerrado) | No | No |

Más el residual firmado del mismo día: ADMIN-R solo gestiona (modificar, subir nivel, restablecer clave, inhabilitar, desbloquear, cerrar sesiones) cuentas restringidas a su misma pareja empresa y sucursal (403 `RESTRICCION_CUENTA_FUERA_DE_ALCANCE`, que **precede** a `SOLO_SUPER` en una edición). Los nombres `RestriccionSoloSuper*` y el código `RESTRICCION_SOLO_SUPER` se conservan por compatibilidad (`src/GPOS.Contracts/Seguridad/Cuentas.cs:175`). **P-M168-01** pide a B confirmar que el oráculo es este y no el texto del #177.

## 1. Estado actual en el código (`origin/feature/modelo-ng` @ `67b4353a`)

| Pieza | ¿Construida? | Evidencia |
|---|---|---|
| M-168-2: comparación con el estado guardado, falla cerrado | **Sí** [V] | `UsuariosService.cs:465-506` (`ExigirRestriccionSinCambiosAsync`); se llama desde `GuardarAsync` en `:594-595`, dentro de la transacción `Serializable` y después del padrón y de la fila de la cuenta (`:573`, `:586`) |
| M-168-2 residual: alcance de la cuenta objetivo | **Sí** [V] | `UsuariosService.cs:525-540` (`ExigirCuentaEnAlcanceAsync`), `:548-553` (`ExigirGestionableAsync`, para `/pos/usuarios`), `DesbloquearAsync :309-318`, `ForzarNuevoInicioAsync :768-` |
| Endpoints que la usan | **Sí** [V] | `AdminEndpoints.cs:183-236` (`POST /usuarios`, pasa `sesion.EsSuper` y `sesion.Usuario` en `:217`), `:274-288` cerrar-sesiones, `:293-316` inhabilitar, `:319-330` desbloquear; todas con `PermitidaAlAdminRestringido` |
| 403 en la bitácora de seguridad | **Sí, pero solo en parte** [V] | `AdminSinRestriccion.cs:91-103` (`FiltroAsync`) registra `RestriccionSoloSuper` y `RestriccionCuentaFueraDeAlcance`; el rastro lo prueba solo `AdminSinRestriccionHttpTests.cs:214-235` y **solo para la política y `/pos/usuarios`**, no para `POST /usuarios` |
| `_LOG` del éxito | Parcial [V] | `AdminEndpoints.cs:219-220`: "Modificar · nivel…; perfiles…; excepciones…". **No dice nada de la restricción** (bandera, empresa, sucursal) |
| M-168-1: regla única | **Sí** [V] | `src/GPOS.Contracts/Seguridad/UsuarioAlcance.cs:15` (`Restringe`). Consumidores: `EstadoSesionUsuario.Restringida` `UsuariosService.cs:1095` (alimenta `AlcanceAlmacenes.SinRestriccionAsync/ResolverAsync`, `RevocacionSesiones.SucursalAjena :194`, política `AdminSinRestriccion`), `ResolverSucursal :928`, `AuthEndpoints.cs:351`, `ProveedorContexto.cs:93` (restricción y `Sucursal`), `CuentasGestionablesAsync :392,:396` |
| Único escritor de la bandera | [V] | `UsuariosService.cs:651` (`u.RestringirSucursal = dto.RestringirSucursal`); ni `ImportarLegado` (`:1034`), ni `SelladoCuentaSellos`, ni `GPOS.Migracion` la asignan (búsqueda de `RestringirSucursal` en `src`: solo lecturas, el DTO, el esquema y el sello) |
| **Residuo M-168-1 (lo declara B)** | **Sin corregir** [V] | `src/GPOS.Core/Servicios/CierreSucursalService.cs:96` usa `x.RestringirSucursal` sin excluir al SUPER; `:98` lo reporta como restringido |
| **Residuo de pantalla** | [V] | `src/GPOS.Web/Components/Pages/Admin/Usuarios.razor:52` pone el candado "Solo puede conectarse a su sucursal predeterminada" a un SUPER con bandera (falso desde M-168-1); `:141` el interruptor de la bandera solo se deshabilita sin sucursal, así que un ADMIN-R ve el interruptor activo y el 403 llega al guardar. La tarea 7 (`Usuarios.razor` en #184) no está en `feature/modelo-ng` según el árbol que leí [I: no abrí #184] |
| Pruebas ya existentes | [V] | M-168-2 servicio: `RestriccionSoloSuperTests` (15 métodos, varios con `[Theory]`) y `CuentaFueraDeAlcanceTests` (6 métodos); HTTP: `RestriccionSoloSuperHttpTests` (2) y `CuentaFueraDeAlcanceHttpTests` (1, las 6 rutas). M-168-1: `QA5_regla_unica_UsuarioAlcance_Restringe` (8 filas), `QA5_el_SUPER_con_la_bandera_entra_como_sin_restriccion`, `QA5_el_SUPER_con_la_bandera_no_se_restringe…` y `…sin_sucursal_en_el_token_ve_todas` |

**Conclusión:** ambas están construidas; este plan es de **verificación de lo construido y de huecos**, no de contrato futuro. Lo nuevo a escribir está marcado `N` en las tablas; `C` = cubierto por una prueba existente que cité; `P` = parcial.

## 2. Convenciones

- Actores: **SUPER**; **ADMIN-G** (ADMIN sin restricción); **ADMIN-R** (ADMIN con bandera, restringido a (E1,S1)); **USER** (nivel USER, con o sin bandera); **SIN** (sin sesión); **OTRA-EMP** (ADMIN con token de otra empresa).
- Nivel: **S** = servicio (`UsuariosService` con `SistemaSegundoFactorFixture`, como `RestriccionSoloSuperTests`); **H** = HTTP con `ApiMvpFactory` (`AdminAsync()`, `EntrarAsync(codigo, clave, sucursal)`, `Http.RechazoAsync`, `Datos.Id`).
- Aviso para S: `Servicio(db)` construye `new UsuariosService(db, licencia: …)` **sin `sellos`** [V `RestriccionSoloSuperTests.cs:~22`], por lo que `padron` es `null` y no se ejercen el `UPDLOCK` del padrón ni el sello (`UsuariosService.cs:573`). Todo caso de sello o de concurrencia con padrón va por H o construye el servicio con `sellos` (M2-51).
- Fixture numérico y reglas anti-flaky de mi plan S-16: sin `Thread.Sleep`, cuentas con `Datos.Id`, una base por clase.
- "403" de la política = `RESTRICCION_SUCURSAL_ADMIN`; del servicio = `RESTRICCION_SOLO_SUPER` o `RESTRICCION_CUENTA_FUERA_DE_ALCANCE`; un USER recibe el 403 genérico de `RequiereAdmin` (la guarda `EsRechazo` lo separa, `AdminSinRestriccion.cs:~110`).

## 3. M-168-2: casos

### 3.1 Matriz de actores sobre `POST /api/admin/usuarios` (y servicio)

| ID | Actor | Entrada | Esperado | Nivel | Estado |
|---|---|---|---|---|---|
| M2-01 | ADMIN-R | su ficha con bandera true→false | 403 `RESTRICCION_SOLO_SUPER`; cuenta intacta | S, H | C (`RestriccionSoloSuperTests` "…quitarse_su_propia_bandera"; `…HttpTests :76`) |
| M2-02 | ADMIN-R | su ficha con `SucursalDefault` o `EmpresaDefault` distintas | 403 `SOLO_SUPER` | S, H | C (S); P (H solo sucursal) |
| M2-03 | ADMIN-R | cuenta restringida de su pareja (USER y ADMIN): quitar bandera, cambiar sucursal, cambiar empresa | 403 `SOLO_SUPER`; cuenta intacta | S, H | C |
| M2-04 | ADMIN-R | cuenta libre, o restringida de otra sucursal/empresa: restringir, modificar, subir nivel, restablecer clave | 403 `FUERA_DE_ALCANCE` (precede a `SOLO_SUPER`); clave y datos intactos | S, H (6 rutas) | C |
| M2-05 | ADMIN-R | alta: sin bandera / sin sucursal / otra sucursal / otra empresa | 403 `SOLO_SUPER`; la cuenta no existe | S (4 casos); H (2 de 4) | C (S); **P (H: faltan "otra empresa" y "sin sucursal")** |
| M2-05b | ADMIN-R | alta restringida a su pareja con grafía " s1 " / "e1" | 200 | S, H | C (S); N (H) |
| M2-06 | ADMIN-R y ADMIN-G | alta con `Nivel=SUPER`; edición que sube a SUPER una cuenta restringida de su alcance | rechazo `ReglaNegocio` "Solo un Super Usuario puede asignar el nivel…" (`:569`); sin cuenta nueva ni cambio | S, H | **N** (no hay prueba: búsqueda de "Solo un Super" en `tests`: 0 resultados) |
| M2-07 | ADMIN-G | activar, quitar, cambiar sucursal/empresa de otra cuenta (USER y ADMIN) | 200; estado guardado = pedido | S, H | C |
| M2-08 | ADMIN-G | alta con y sin bandera | 200 | S | C |
| M2-09 | ADMIN-G | su propia ficha: bandera false→true → 403 `SOLO_SUPER`; su sucursal por omisión sin bandera → 200 | S, H | C |
| M2-10 | ADMIN-G | cualquier edición de un SUPER (incluida su bandera o nivel) | rechazo "Solo un Super Usuario puede modificar…" (`:588`); el SUPER no aparece en `GET /usuarios` de un ADMIN | S, H | **N** |
| M2-11 | SUPER | todas las combinaciones, incluida su propia restricción | 200 | S (`…super_cambia_la_restriccion_en_todos_los_casos`), H (otra cuenta) | C; **N** (H: el SUPER cambia la suya) |
| M2-12 | USER (sin y con bandera) | `POST /usuarios` con bandera en una cuenta | 403 genérico de `RequiereAdmin`, **distinto** de `RESTRICCION_*`; cuenta intacta | H | **N** |
| M2-13 | SIN; cuenta inhabilitada; sesión sin autenticación reciente | `POST /usuarios` con cambio de bandera | SIN 401; inhabilitada 401; falta de autenticación reciente: el código de `RequiereAutenticacionReciente` (`AdminEndpoints.cs:236`) | H | **N** (no vi prueba por ruta del requisito de autenticación reciente [I]) |
| M2-14 | solicitante degradado (ADMIN→USER) con token vigente | cambio de bandera | **H:** 401 `credenciales` en la siguiente petición (`RevocacionSesiones.Evaluar`: rango del token > rango de la cuenta); **S:** 403 `SOLO_SUPER` con la cuenta guardada | S, H | C (S `…no_es_admin_aunque_su_token_lo_sea`); **N** (H) |
| M2-15 | ADMIN-G al que el SUPER restringe con el token ya emitido | su siguiente `POST /usuarios` que quita la restricción a otra cuenta | 401 por Q-A2 si su sucursal de token ≠ la asignada; si coincide, 403 `SOLO_SUPER`. En ningún caso 200 | H | **N** (mata "estado del solicitante tomado del token o de caché") |
| M2-16 | sin solicitante, o con código inexistente | alta o edición | 403 (falla cerrado); sin cuenta nueva | S | C |
| M2-17 | OTRA-EMP (ADMIN-G con token de E2) | cambiar la restricción de una cuenta restringida a (E1,S1) | **Hoy 200** (usuarios globales; el ADMIN "de la empresa" es ADR-34, decidido, no implementado). Prueba de caracterización marcada `Trait("Decidido","no-implementado")`; se invierte al construir ADR-34 | H | **N** (solo si B la quiere; no bloquea) |

### 3.2 Vías de cambio: pantalla, importación, API directa

| ID | Vía | Entrada | Esperado | Nivel | Estado |
|---|---|---|---|---|---|
| M2-20 | **Pantalla** `Usuarios.razor` (interruptor `:141`, sucursal y empresa `:254-261`) | ADMIN-R abre una cuenta de su alcance y mueve el interruptor / cambia la sucursal; ADMIN-G edita la propia | Con la tarea 7 (#184): controles deshabilitados para ADMIN-R y para la propia restricción; sin ella (hoy): el 403 llega y la pantalla muestra el mensaje del servidor sin perder el formulario | bUnit (`tests/GPOS.Web.Tests`; no existe prueba de `Usuarios.razor` [V]) | **N**; depende de #184 |
| M2-21 | **API directa**, cuerpo con `RestringirSucursal` **omitido** (el campo es `bool`, por omisión false) | ADMIN-R edita una cuenta restringida de su alcance enviando un JSON sin ese campo | 403 `SOLO_SUPER` (cambio implícito true→false), no una quita silenciosa. ADMIN-G: la quita (es su derecho) y la prueba documenta que un cliente que omite el campo quita la restricción | H | **N** |
| M2-22 | API directa, `EsNuevo=true` sobre un código que ya existe (de otra sucursal o libre), con otra grafía (mayúsculas/minúsculas, espacios finales, ancho completo) | ADMIN-R | rechazo "ya existe" (o formato inválido); la cuenta existente intacta; nunca una modificación disfrazada de alta | H, S | **N** (vector de la comparación contra el estado guardado) |
| M2-23 | API directa, `Codigo` de una cuenta ajena escrito con otra grafía | ADMIN-R | 403 `FUERA_DE_ALCANCE` (se resuelve por la base, N-1); para la propia ficha con otra grafía, `SOLO_SUPER` | H | **N** |
| M2-24 | API directa, bandera true con sucursal vacía; o con sucursal inexistente / inhabilitada | ADMIN-G | 400 de validación (`:566`; el endpoint valida la sucursal habilitada, `AdminEndpoints.cs:~196-200`) antes que cualquier 403; cuenta intacta | S (vacía), H (inexistente) | P (S: validación sin prueba propia) |
| M2-25 | Rutas laterales no alteran la restricción: `inhabilitar`, `cerrar-sesiones`, `desbloquear` | ADMIN-G y ADMIN-R sobre una cuenta restringida | Tras cada ruta, bandera, empresa y sucursal de la cuenta iguales a antes (`inhabilitar` arma el DTO desde la ficha guardada, `AdminEndpoints.cs:~298-306`) | H | **N** |
| M2-26 | **Importación** | (a) `UsuariosService.ImportarLegado` (`:1034`): la cuenta nace con bandera false. (b) Ninguna importación de plantillas (`/api/admin/importaciones`, `ImportacionMaestros`) toca `dbo.Usuarios` ni la bandera [V búsqueda: ninguna]. (c) Guarda de fuente: la única asignación a `.RestringirSucursal =` en `src` es `UsuariosService.cs:651` | (a) S; (c) script de CI, no prueba xUnit (mi observación P168-12 sobre pruebas que leen fuentes) | **N** |
| M2-27 | `/api/admin/pos/usuarios` sobre un SUPER (con y sin bandera, misma pareja que ADMIN-R) | ADMIN-R POST y DELETE; GET | 403 `FUERA_DE_ALCANCE`; el GET no lo lista | H, S (`ExigirGestionableAsync`) | **N** (mata MU-15) |

### 3.3 Rastro: bitácora de seguridad y `_LOG`

| ID | Esperado | Nivel | Estado |
|---|---|---|---|
| M2-30 | Los 403 `SOLO_SUPER` y `FUERA_DE_ALCANCE` de **`POST /api/admin/usuarios`** (y de inhabilitar, cerrar-sesiones, desbloquear) dejan un evento `ACCESO_RECHAZADO_SUCURSAL` con `Detalle = "POST /api/admin/usuarios · RESTRICCION_SOLO_SUPER"`, severidad `M`, canal `API`, empresa; sin el código de la cuenta destino. Un segundo 403 del mismo usuario dentro del minuto no agrega fila (D81-10, observación O168-02 de A). Cada caso con su propio ADMIN-R (patrón de `AdminSinRestriccionHttpTests.cs:214`) | H | **N** (hoy ningún test usa `POST /usuarios` en la bitácora; mata MU-08) |
| M2-31 | El éxito de ADMIN-G/SUPER deja `Auditoria` "Usuarios y permisos · Modificar" con el código que guarda la base. **El valor de la restricción hoy no se registra** (`AdminEndpoints.cs:219-220`); si B decide registrarlo (P-M168-02), la prueba afirma "restricción: sí/no; empresa/sucursal" antes/después | H | N (bloqueada en su aserción por P-M168-02) |
| M2-32 | Los mensajes del 403 solo nombran la sucursal del propio solicitante (`:485-486,:490,:536`); no incluyen la sucursal ni el nivel de la cuenta destino fuera de alcance | S | N |
| M2-33 | Caracterización S168-06: ADMIN-R sobre un código **inexistente** recibe "no existe" (400) y sobre uno existente fuera de alcance 403, en `POST /usuarios` (`:586`), `inhabilitar` y `cerrar-sesiones` (`ObtenerAsync … ?? throw` antes del servicio) y `desbloquear`; `/pos/usuarios` sí iguala ambos. Hoy distintos [V]. Esperado según P-M168-03 | H | N (bloqueada por P-M168-03) |

### 3.4 Sesión y sello

| ID | Esperado | Nivel | Estado |
|---|---|---|---|
| M2-40 | Paridad de `AlcanceSucursalHttpTests.cs:61-84` con **ADMIN-G como actor** (hoy el actor es el SUPER): tras activar, quitar o cambiar la sucursal de una cuenta, esa cuenta inicia sesión (sello válido, no 409 `USUARIO_SIN_SELLO`); su token anterior de otra sucursal recibe 401 `credenciales` desde la petición siguiente; al quitarle la restricción deja de recibir 401 | H | **N** (mata MU-16) |
| M2-41 | Restringir o quitar la restricción no cambia el consumo de cupo ni exige licencia nueva | S | N |

### 3.5 Concurrencia

| ID | Escenario | Esperado | Nivel | Estado |
|---|---|---|---|---|
| M2-50 | Dos ADMIN-G a la vez sobre la misma cuenta: uno pone bandera true, otro false (20 repeticiones, `Task.WhenAll`) | Ambas terminan 200 o una 409/reintentable; nunca 500 con traza; estado final = exactamente uno de los dos pedidos; la cuenta entra después (sello válido); empresa y sucursal coherentes con el pedido ganador | H | N |
| M2-51 | **Determinista:** el SUPER restringe a ADMIN-X mientras X envía "quitar la restricción de Y". Con `UsuariosService` construido con `sellos`, una conexión retiene el padrón (`Padron.TomarAsync` dentro de una transacción `Serializable`, patrón de `MantenimientoAnilloSellosTests.cs:62-66`), X lanza `GuardarAsync` (se bloquea en el padrón), la otra conexión restringe a X y confirma; al liberar, la llamada de X | 403 `SOLO_SUPER` (lee su cuenta dentro de la transacción) y Y intacta. Mata "solicitante leído antes del padrón o de una caché" | S (con `sellos`) | **N** |
| M2-52 | Dos ADMIN-R dan de alta el mismo código a la vez (restringida) | uno 200, otro "ya existe"; una sola fila; ninguna sin restricción | H | N |
| M2-53 | Caracterización S168-04: ADMIN-R ejecuta `cerrar-sesiones` / `desbloquear` sobre T mientras el SUPER le quita la restricción a T | hoy **sin garantía** (la lectura previa del alcance no está en la transacción, `:309-318`, `:768-`); la prueba se escribe como `Skip="S168-04"` con el orden esperado, para activarla si B mueve la lectura dentro de la transacción | S | N (opcional) |
| M2-54 | Si `Serializable` produce un interbloqueo (1205) entre M2-50/M2-52 | la respuesta es reintentable (409 o 503 según el manejador), no 500 con detalle de SQL [I: no leí el manejador de 1205 de esta ruta] | H | N (no bloquea) |

### 3.6 Regresión (lo que hoy funciona y no debe romper)

| ID | Esperado | Nivel | Estado |
|---|---|---|---|
| M2-60 | ADMIN-G y SUPER gestionan cuentas sin restricción como antes: alta, cambio de nivel, restablecer clave (fuerza nuevo inicio, R-a), inhabilitar (R-3), desbloquear, cerrar sesiones. Correr `--filter "FullyQualifiedName~Usuarios|FullyQualifiedName~Alcance"` y, solo en la PC de B, la suite oficial `Transicion!=Ola5&Transicion!=Defecto` | S, H | C (suites existentes) |
| M2-61 | ADMIN-R edita lo que no es restricción en su alcance (descripción, perfiles, excepciones, `DebeCambiarClave`, restablecer clave de otra cuenta) → 200; en su propia ficha cambia descripción (`CuentaFueraDeAlcanceTests`, "Su propia ficha") | S, H | C (S); P (H solo clave) |
| M2-62 | `GET /usuarios`: ADMIN-G y SUPER listan todas (el ADMIN sin SUPER); ADMIN-R solo las de su pareja | H | C (`AdminSinRestriccionHttpTests.cs :160`) |
| M2-63 | Inicio de sesión de USER/ADMIN con bandera: siempre su sucursal (D-3) | S, H | C |
| M2-64 | La restricción de un USER/ADMIN con bandera sigue vigente para existencias, kárdex y artículos (fixture 26 vs 8 de S-16) | H | C (`AlcanceSucursalHttpTests`) |

## 4. M-168-1: casos

La regla `UsuarioAlcance.Restringe(nivel, bandera) = bandera && nivel != "SUPER"` (comparación ordinal exacta: "super", vacío y `null` **no** eximen) es una función pura en `GPOS.Contracts`. El riesgo ya no es una segunda copia de la regla (cerrado en `2bdc5e43`), sino (a) que algún consumidor siga leyendo la bandera cruda, (b) que el cambio de comportamiento del SUPER con bandera esté probado solo a nivel de función, y (c) que el SUPER con bandera siga siendo "alcanzable" por una escalada.

| ID | Actor / escenario | Entrada y ruta | Esperado | Nivel | Estado |
|---|---|---|---|---|---|
| M1-01 | Tabla de verdad | `Restringe(nivel, bandera)` para USER/ADMIN/SUPER × true/false, "super", `null` | solo SUPER+cualquiera=false; USER/ADMIN+true=true; nivel desconocido+true=true | S (unidad) | C (`SucursalTokenRestringidoTests.cs :62-76`); agregar `""` y `" SUPER"` (N, trivial) |
| M1-02 | Paridad de los consumidores | Un solo vector (nivel × bandera × sucursal asignada) evaluado por `EstadoSesionUsuario.Restringida`, `ResolverSucursal`, `RevocacionSesiones.SucursalAjena`, `AlcanceAlmacenes.SinRestriccionAsync` y `ProveedorContexto.Restringe` | las cinco respuestas coinciden en las 8+ filas | S, en dos ensamblados | **N.** `ProveedorContexto.Restringe` es `internal` de `GPOS.Reportes`; propuesta [I]: vector JSON compartido `docs/contratos/vectores/adr093-restringe.v1.json` (precedente `adr077-carpetas.v1.json`) leído por `GPOS.Tests` y `GPOS.Reportes.Tests`. Esto es la "prueba de paridad" que pidió la auditoría de B |
| M1-03 | SUPER con bandera, **inicio de sesión real** | `POST /api/auth/login`, solicitando S2 (≠ `SucursalDefault`=S1), ambas habilitadas | entra con S2 (antes: "solo puede conectarse a su sucursal predeterminada") | H | C (S: `SucursalesAccesoTests :73-75`); **N** (H) |
| M1-04 | SUPER con bandera y `SucursalDefault` inexistente o inhabilitada en la empresa | login sin sucursal | entra **sin sucursal** (antes: error) | H | C (S :77-78); N (H) |
| M1-05 | SUPER con bandera, empresa de la sesión ≠ `EmpresaDefault` | `ResolverSucursal(super, null, disponibles, empresa:"E2")` | no lanza "solo puede conectarse a su empresa predeterminada" (S168-05 no aplica al SUPER) | S | **N** (las filas de `SucursalesAccesoTests` no pasan `empresa`) |
| M1-06 | SUPER con bandera pide una sucursal **cerrada** | login con `sucursal=<cerrada>` | 4xx `SUCURSAL_CERRADA` (la rama `cerrada` de `AuthEndpoints.cs:351` usa `Restringe`); con la regla anterior diría "no existe o está inhabilitada" | H | **N** (mata MU-11) |
| M1-07 | Token del SUPER con bandera con otra sucursal o sin sucursal | cualquier petición | nunca 401 por Q-A2 | S, H | C (S `Evaluar(super,…)` :55-59); N (H) |
| M1-08 | SUPER con bandera en `/api/admin/*` | rutas de `RutasDenegadas` (GET) y `POST /usuarios` con cambios de restricción | sin `RESTRICCION_SUCURSAL_ADMIN`; 200 en el alta y en los cambios | H | **N** (la política usa `Restringida`) |
| M1-09 | SUPER con bandera en existencias, kárdex y guardado de artículo | fixture de S-16 (A1=3, A2=5, A3=7, A4=11) | totales globales (26), no los de su sucursal (8); el guardado conserva todo | S (AL-13 parcial), H | P (S); N (H) |
| M1-10 | API de reportes con SUPER con bandera | contexto de `ProveedorContexto` | `RestringirSucursal=false`, `PuedeDisenar=true`, sucursal = la del token; sin sucursal en el token → `Lectura(null).SucursalRestringida=null` | S | C (`ProveedorContextoTests :169-200`) |
| M1-11 | **Cambios de nivel** | ADMIN con bandera promovido a SUPER por otro SUPER; SUPER con bandera degradado a ADMIN | el primero deja de restringirse en la petición siguiente; el segundo se restringe, su token de otra sucursal da 401 y su sesión se revoca (R-3 "nivel reducido") | H | **N** (el nivel es el de la cuenta guardada, no el del token) |
| M1-12 | Caché de la API de reportes (paquete 15 s) | degradar SUPER+bandera a ADMIN y consultar con el reloj simulado | restringido a lo sumo a los 15 s; el relee de T2-08 no multiplica lecturas | S (`ProveedorContextoTests`, `reloj.Advance`) | **N** |
| M1-13 | Frontera que sostiene M-168-1 | ningún ADMIN asigna o modifica SUPER (con M-168-1 un SUPER con bandera es global, así que "ADMIN→SUPER" sería una escalada total) | ver M2-06 y M2-10 | S, H | N (mismo trabajo) |
| M1-14 | **Residuo** `CierreSucursalService.UsuariosAfectados` | `UsuarioDto` SUPER con bandera, misma sucursal, empresa de la sesión o no | **no** figura como restringido (`Restringido=false` o no se lista) | S (puro) | **N. Hoy fallaría** [V `:96-98`]: el SUPER se informa como "restringido… no podrá entrar a esta". Corrección 0,02 dp: `UsuarioAlcance.Restringe(x.Nivel, x.RestringirSucursal)`. La prueba existente (`CierreSucursalOperacionTests.cs :170-182`) usa DTO sin nivel (`null`), que sigue restringiendo, así que se mantiene verde |
| M1-15 | Pantalla: candado de `Usuarios.razor:52` | SUPER con bandera | sin candado ni texto "Solo puede conectarse…" (o texto distinto) | bUnit | N; depende de #184 / decisión de B |
| M1-16 | Guarda de regla en línea | script de CI: toda lectura de `.RestringirSucursal` (no asignación) en `src` fuera de la lista permitida (`UsuarioAlcance`, `EstadoSesionUsuario`, `UsuariosService.CuentasGestionablesAsync` como prefiltro SQL con re-filtro, `ContextoReportes`/`IReporteRegistrado`/`ServicioReportes`/`EjecutorDisenador` que leen el campo del contexto, el sello, DTO y esquema) falla | CI | **N** (hoy la excepción es `CierreSucursalService.cs:96`, que el script habría detectado) |
| M1-17 | Sello del SUPER con bandera | alta del SUPER con bandera por el SUPER; cambiar su bandera | login correcto; el sello cubre la bandera cruda (`SellosHabilitacion.cs:128-129`), así que un cambio de bandera en un SUPER vuelve a sellar y el login sigue válido | H | N |
| M1-18 | Regresión USER/ADMIN con bandera | login, 401 Q-A2, existencias 8 vs 26, diseñador 403 | sin cambios | S, H | C |

**Fixture del SUPER con bandera (necesario para M1-03 a M1-17 por H):** el SUPER (nivel) puede ponerse la bandera por `POST /usuarios` (SUPER modifica SUPER, y el SUPER cambia su propia restricción). Dos caminos: (a) editar a `GSF` del `ApiMvpFactory` y restaurarlo en `finally` (la fábrica es por clase, pero otros tests de la misma clase usan a `GSF`); (b) un SUPER secundario. Con ADR-81 fase A (TOTP obligatorio para el SUPER en todo canal) un SUPER nuevo podría exigir enrolar el segundo factor al entrar [I: no leí cómo lo resuelve `ApiMvpFactory`]. Ver **P-M168-05**.

## 5. Mutaciones que el plan debe matar

`Estado hoy`: "Matada" = una prueba existente cuya aserción la detecta [V por lectura, no ejecuté]; "SOBREVIVE" = ninguna prueba actual la mata y el plan agrega el caso.

| ID | Archivo:línea | Mutación | Caso que la mata | Estado hoy |
|---|---|---|---|---|
| MU-01 | `UsuariosService.cs:~481` | `dto.RestringirSucursal != u.RestringirSucursal` → `==` (ADMIN-R) | M2-01, M2-03 | Matada |
| MU-02 | `:~484` | quitar la comparación de `EmpresaDefault` del restringido | M2-02, M2-03 (E2) | Matada |
| MU-03 | `:~489` | alta de ADMIN-R: quitar `!Igual(dto.EmpresaDefault, cuenta.EmpresaDefault)` | M2-05 (otra empresa) | Matada (S); **SOBREVIVE por H** hasta que M2-05 H se agregue |
| MU-04 | `:592-595` | `if (!solicitanteEsSuper)` → `if (!solicitanteEsSuper && !dto.EsNuevo)` | M2-05 | Matada |
| MU-05 | `:502` | quitar `!EsAdministrador(cuenta.Nivel)` (un USER guardado cambia restricciones) | M2-14 S, M2-12 | Matada (S) |
| MU-06 | `:504` | autoedición comparada con el texto recibido en vez de con la cuenta guardada (`dto.Codigo` vs `solicitante`) | M2-09, M2-23 (otra grafía) | **SOBREVIVE** (las pruebas usan el código exacto) |
| MU-07 | `:569` | quitar `&& !solicitanteEsSuper` (un ADMIN asigna SUPER) | M2-06, M2-10, M1-13 | **SOBREVIVE** (0 pruebas) |
| MU-08 | `AdminSinRestriccion.cs:98` | quitar `RestriccionSoloSuper` del filtro de la bitácora | M2-30 | **SOBREVIVE** |
| MU-09 | `AdminEndpoints.cs:~304-306` | `inhabilitar` arma el DTO con `RestringirSucursal=false` o valores por omisión | M2-25 | **SOBREVIVE** (ADMIN-G inhabilita y nadie mira la bandera) |
| MU-10 | `AdminEndpoints.cs:217` | pasar `dto.Codigo` en lugar de `sesion.Usuario` como solicitante (diputado confundido) | M2-04 H | Matada (`CuentaFueraDeAlcanceHttpTests` espera 403 en la cuenta libre) |
| MU-11 | `AuthEndpoints.cs:351` | `!UsuarioAlcance.Restringe(...)` → `!u.RestringirSucursal` | M1-06 | **SOBREVIVE** |
| MU-12 | `UsuarioAlcance.cs:15` | quitar `&& nivel != Super`, o `nivel is not null` | M1-01, M1-02 | Matada |
| MU-13 | `UsuariosService.cs:1095` | `Restringida => RestringirSucursal` | M1-01, M1-07, M1-02 | Matada (`QA5_regla_unica…` evalúa `Cuenta(nivel,bandera).Restringida`) |
| MU-14 | `ProveedorContexto.cs:93` | `Restringe(u)` → `u.RestringirSucursal` | M1-10 | Matada |
| MU-15 | `UsuariosService.cs:~532` | `ExigirCuentaEnAlcanceAsync`: `Restringe(cuenta.Nivel, cuenta.RestringirSucursal)` → `cuenta.RestringirSucursal` (SUPER con bandera "gestionable" por ADMIN-R de su pareja) | M2-27 | **SOBREVIVE** |
| MU-16 | `UsuariosService.cs:~640-655` (sellado al guardar) o `AdminEndpoints.cs:223` (`RegistrarCuenta`) | no volver a sellar / no olvidar la caché tras cambiar la restricción | M2-40 | `RegistrarCuenta`: Matada (`AlcanceSucursalHttpTests :77-84`); sello: **SOBREVIVE** (nadie inicia sesión tras el cambio) |
| MU-17 | `AdminEndpoints.cs:236` | quitar `RequiereAutenticacionReciente()` de `POST /usuarios` | M2-13 | **SOBREVIVE** [I] (no vi prueba por ruta) |
| MU-18 | `CierreSucursalService.cs:96` | (defecto vivo, no mutación) | M1-14 | Falla hoy |

Resumen: 18 mutaciones; 7 sobreviven hoy más el defecto vivo de MU-18. Corresponde ejecutarlas con el mismo guion que A pidió publicar (S168-08, P168-14): una tabla archivo:línea / mutación / prueba que falla en `GPOS-NG-Equipos/traspasos/B/`.

## 6. Hallazgos de este plan (de lectura, `[V]` salvo nota)

| ID | Sev. | Hallazgo | Evidencia |
|---|---|---|---|
| QM-01 | Baja | `CierreSucursalService.UsuariosAfectados` informa como "restringido" a un SUPER con bandera (residuo de M-168-1 declarado por B); falso positivo en el aviso de cierre, sin impacto de seguridad | `CierreSucursalService.cs:96-98` |
| QM-02 | Baja | `Usuarios.razor` muestra el candado "Solo puede conectarse a su sucursal predeterminada" a un SUPER con bandera, y deja el interruptor activo a un ADMIN-R (el 403 llega solo al guardar) | `Usuarios.razor:52,141` (tarea 7/#184 podría corregirlo) |
| QM-03 | Baja | El `_LOG` del éxito de `POST /usuarios` no registra cambios de bandera, empresa o sucursal; el cambio de una frontera de confidencialidad no deja su valor | `AdminEndpoints.cs:219-220` |
| QM-04 | Baja | Los 403 de M-168-2 en `POST /usuarios` no tienen prueba de bitácora (mutación MU-08 sobrevive) | `AdminSinRestriccionHttpTests.cs:214-235` |
| QM-05 | Baja (S168-06, ya reportada por A) | "No existe" (400) frente a 403 para ADMIN-R en `POST /usuarios`, `inhabilitar`, `cerrar-sesiones` y `desbloquear` | `UsuariosService.cs:586`; `AdminEndpoints.cs:~277,~296,~322` |
| QM-06 | Baja | Sin prueba de que un ADMIN no asigna ni modifica SUPER; con M-168-1 un SUPER con bandera es global, así que esa frontera es la que impide convertir una cuenta restringida en global | `UsuariosService.cs:569,:588`; 0 pruebas |

Ninguno es Crítico ni Alto; **sin hallazgos que impidan** dar M-168-1 y M-168-2 por cumplidos en el código. Los huecos son de prueba.

## 7. Preguntas abiertas (solo las que bloquean)

- **P-M168-01 (bloquea el oráculo de M2).** Confirmar que el oráculo es la regla de la hoja `…admin-sin-restriccion-fija-la-restriccion.md` (ADMIN-G sí cambia la restricción de otras cuentas; nadie salvo el SUPER cambia la propia), no el texto "solo el SUPER" del #177. Además, la nota de ADR-93 de M-168-2 (la de la hoja del #177) sigue enunciando "solo el SUPER puede cambiar la bandera" aunque otra nota posterior la sustituya: ¿se acepta así o B la anota como sustituida en el mismo ADR?
- **P-M168-02 (bloquea la aserción de M2-31).** ¿El cambio de bandera, empresa o sucursal debe quedar en el `_LOG` ("Usuarios y permisos") con el valor anterior y el nuevo? Hoy no. Sin respuesta, M2-31 solo comprueba que existe la línea de "Modificar".
- **P-M168-03 (bloquea la aserción de M2-33).** ¿El oráculo "no existe" (400) frente a 403 para ADMIN-R en las cuatro rutas se acepta (S168-06 queda como Baja y la prueba lo caracteriza) o se iguala al 403 como en `/pos/usuarios` (≈ 0,05 dp)?
- **P-M168-04 (bloquea el verde de M1-14).** ¿B corrige `CierreSucursalService.cs:96` en este ciclo? Si no, M1-14 se escribe `Skip="QM-01"` y M1-16 lo lleva como excepción documentada.
- **P-M168-05 (bloquea los casos H de M1).** Fixture del SUPER con bandera: ¿modificar `GSF` en `ApiMvpFactory` y restaurarlo, o crear un SUPER secundario? Depende de cómo `ApiMvpFactory` resuelve hoy el segundo factor del SUPER (ADR-81 fase A) [I: no lo leí].

No bloquean (anotadas): M2-17 (ADMIN de otra empresa, espera ADR-34) y M2-54 (respuesta ante el interbloqueo 1205).

## 8. Esfuerzo y dependencias [I]

| Bloque | Pruebas nuevas | días-persona |
|---|---|---|
| M2 servicio (M2-06, 10, 22, 23, 24, 27, 32, 41, 53) | ~9 | 0,5 |
| M2 HTTP (M2-05/05b/10/12/13/14/15/21/22/23/25/27/30/40, 50, 52) | ~14 | 0,9 |
| M2 concurrencia determinista (M2-51; requiere construir `UsuariosService` con `sellos`) | 1 | 0,25 |
| M1 (M1-02 con vector compartido en dos ensamblados, 03 a 09, 11, 12, 17) | ~11 | 0,7 |
| M1-16 y M2-26(c) (guardas de CI) | 2 | 0,2 |
| Mutaciones: aplicar y revertir las 18 y publicar el guion | — | 0,3 |
| bUnit de `Usuarios.razor` (M2-20, M1-15), condicionado a #184 | 2 | 0,25 |
| **Total** | **~40** | **≈ 3,1 dp** (rango 2,5 a 3,6) |

Lo mínimo útil si hay que recortar: M2-06/10, M2-30, M2-25, M2-27, M1-06, M1-14 y M2-51 (los que matan mutaciones que hoy sobreviven): ≈ 1,2 dp.

Dependencias: respuestas a P-M168-01 a 05; `ApiMvpFactory` con SUPER con bandera; `Usuarios.razor` de #184 en `feature/modelo-ng` para M2-20 y M1-15; vector compartido (M1-02) coordinado con A porque `docs/contratos/vectores/` es de A; correr una sola suite a la vez (no dos suites completas), en la PC de B según los límites de OSHIN-LEGION (esta PC no corre suites largas).

## 9. Qué no verifiqué

- **Nada se compiló ni ejecutó.** Todo "Matada"/"SOBREVIVE" sale de leer la aserción contra la mutación, no de correrla; puede haber pruebas que maten alguna de las que marco como supervivientes en archivos que no abrí (`CuentaFueraDeAlcanceTests`, `LecturasCuentasRestringidoTests`, `EstadoSesionRestriccionTests` y `UsuariosTests` generales: solo leí sus nombres o ni eso).
- No abrí el PR #184 ni la rama de la tarea 7; no sé si `Usuarios.razor` ya refleja la regla (el aviso de A dice que sí).
- No leí cómo `ApiMvpFactory` resuelve el segundo factor del SUPER, ni el manejador del interbloqueo 1205, ni el código exacto del 403 de `RequiereAutenticacionReciente`.
- No verifiqué la numeración exacta de líneas con `~`; son aproximadas (±3) donde las marqué así. Las demás salen de `git show origin/feature/modelo-ng:…`.
- No verifiqué que el limitador D81-10 (un evento por minuto y usuario) se comporte como indica el comentario de `AdminSinRestriccion.cs`; lo tomé del comentario y de la prueba `:214-235`.
- No leí el hilo del #168 (`gh pr view 168 --comments`) ni el guion de 9/10/14 mutaciones de B (no está publicado, P168-14).
- Los costos en días-persona son inferencia mía.
