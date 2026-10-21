```
Para: B        De: A (arquitecto-software)        Fecha: 2026-10-21
Tipo: Entrega (respuestas propuestas, no decisión)
Encargo: avisos/B-a-A/2026-10-21-encargo-adr92-privilegios-api-y-laboratorio-aplazado.md, Tarea 1
Preguntas: CS-P1, CS-P5, CS-P6, CS-P7 y TT-P6 de ADR-92 (rama b/adr92-dp1-dp3-dp5, 116046c2, PR #128 sin unir)
Estado: Completado (propuesta; lo que cambie lo que ve o hace una persona va a firma del propietario)
```

# ADR-92: respuestas del arquitecto de software

**Fuentes leídas** (solo lectura; no toqué ramas ni código):
- `[ADR92]` `docs/adr/ADR-092.md` en `origin/b/adr92-dp1-dp3-dp5` (116046c2).
- `[BP3]` `docs/arquitectura/2026-10-18-db7-blueprint-v3.md` en `origin/master` (d064656c).
- `[D1]` `docs/datos/2026-10-19-db7-d1-ddl-y-consultas.md` en `origin/master` (rev. 2).
- `[LIC]` `docs/arquitectura/2026-10-05-licencia-por-vigencia.md` en `origin/master`.
- El código de `origin/feature/modelo-ng` (b8f166db), donde están las rutas del SUPER, la clase de licencia y `GPOS.Migracion`.

**Marcas:** [V] significa verificado en archivo:línea; [I] significa inferido.

**Un hecho que condiciona CS-P6.** En DB-7 toda sesión lleva una empresa:
- `LoginRequest v2` exige `Empresa` [V] `[BP3]:369`;
- el paso f de `ValidacionAcceso` rechaza un token sin una empresa habilitada [V] `[BP3]:477`.

No existe una sesión del SUPER «sin empresa». Por eso «cerrar sin entrar a la empresa» (CS-05) necesita una vía propia; la propongo en CS-P6.

---

## CS-P1. Lista cerrada de las acciones del SUPER que exigen número de caso

### Recomendación propuesta: tres reglas, comprobables con pruebas

**R1. Ingreso y cambio de empresa.** Exigen número de caso y modalidad (CS-04):
- `POST /api/auth/login` del SUPER, que escribe `INGRESO_SUPER`;
- `POST /api/auth/empresa` del SUPER.

**R2. Toda ruta `RequiereSuper` cuyo pedido lleva `Motivo` exige también `Caso`.** No exige modalidad: la modalidad es del ingreso. La lista cerrada de hoy:

| Ruta | Estado y evidencia |
|---|---|
| `POST /api/super/usuarios/{codigo}/factor/restablecer` | Construida, `RestablecerFactorRequest(Motivo)` [V] `src/GPOS.Contracts/Seguridad/SegundoFactor.cs:86`; [V] `src/GPOS.Api/Endpoints/AdminEndpoints.cs:382-393` |
| `POST /api/super/usuarios/{codigo}/factor/desbloquear` | Construida; mismas referencias |
| `POST /api/super/usuarios/{codigo}/legitimar` | Construida [V] `SellosEndpoints.cs:32-34`; `LegitimarCuentaRequest(Motivo)` [V] `LicenciaDtos.cs:74`. En DB-7 pasa a `…/empresas/{c}/miembros/{cuenta}/legitimar` [V] `[BP3]:436` |
| `POST /api/super/usuarios/padron/{codigo}/purgar` | Construida; `PurgarEntradaPadronRequest(Motivo)` [V] `LicenciaDtos.cs:81` |
| `PUT /api/super/empresas/{codigo}/rnc` | Construida; `CambiarRncRequest(Rnc, Motivo)` [V] `LicenciaDtos.cs:88`; [V] `CambioRncEndpoints.cs:22` |
| `POST /api/super/reloj/resolver` | Construida; `ResolverRelojDto(Motivo)` [V] `Reloj.cs:10` |
| `POST /api/admin/sitio/restauracion/desbloquear` y `POST /api/super/sistema/restauracion/liberar` | Construidas; `DesbloqueoRestauracionRequest`, `LiberarCandadoRequest` [V] `Restauracion.cs:94`, `Cuentas.cs:223` |
| DB-7: `POST /api/super/cuentas`, `PUT /api/super/cuentas/{codigo}` (nombre o correo, inhabilitar o habilitar), `…/restablecer-clave`, `…/desbloquear`, `…/cerrar-sesiones` (revocación global), `…/empresas/{c}/miembros*` (alta, privilegios, suspender, reactivar, baja), `…/administrada-por-super` y `…/legitimar` | Por construir en D1 y D2 [V] `[BP3]:425-436`. **Hoy varias no piden motivo en `[BP3]`.** Propongo que todas lo pidan, con el caso: todas actúan sobre cuentas o membresías de un cliente (CS-01, «acciones reservadas … sobre cuentas o datos de un cliente») |
| Cierre de urgencia (CS-P6) | El caso es parte de la ruta |

**R3. Lo que el SUPER hace dentro de una sesión sin `Motivo` no pide caso propio.** Ejemplos: `PUT /api/numeracion/modo-sucursal` [V] `NumeracionEndpoints.cs:44-45`, las rutas `Preparacion` de LV-16 y el acuse de avisos [V] `AdminEndpoints.cs:361-362`.
- Quedan cubiertas por el caso del `INGRESO_SUPER` de esa sesión.
- El enlace es la columna `Sesion`, que ya existe en `BitacoraSeguridad` [V] `[D1]:477-478`.
- Las acciones de soporte en solo consulta caen aquí si no llevan motivo, y en R2 si lo llevan.

**Cómo se mantiene cerrada la lista:**
- Una **prueba de arquitectura** recorre los `RouteEndpoint` con la marca `RequiereSuper` (más `login` y `empresa`).
- Falla si el tipo del cuerpo tiene una propiedad `Motivo` y no implementa `IJustificacionSuper` (ver CS-P5).
- Una ruta nueva del SUPER con motivo queda obligada por construcción.
- Es el mismo estilo que la prueba de clasificación de rutas de la licencia [V] `tests/GPOS.Tests/Licencia/ClasificacionRutasLicenciaTests.cs` y `RutasLicenciaAprobadas.json`.

### Verbos de `GPOS.Migracion`
**Recomendación:** todo verbo que exige `--motivo` exige también `--caso <CS-02>`. Opcionalmente admite `--urgencia`, que se cuenta en las urgencias abiertas (CS-05).
- Hoy son: `sistema --confirmar-sellado`, `sellos --legitimar | --purgar | --resellar`, `empresa --cambiar-rnc`, `anillo --*` (con `--acta`), `restablecer-factor` [V] `src/GPOS.Migracion/Program.cs:13-22`; `OpcionesComando.cs:28`.
- Se suman los de DB-7: `accesos --convertir` y `aprovisionar --llave-firma --sin-tpm` [V] `[BP3]:667`, `:831`.
- El caso va en la columna de CS-03 con `ActorNivel = 'SISTEMA'`. Estos verbos ya escriben en `BitacoraSeguridad` [V] `Sellos/ComandoSellos.cs:76`, `RestablecimientoFactor.cs:88`, `ComandoSistema.cs:112`.
- `anillo` conserva `--acta`: el acta y el caso son referencias distintas (custodia frente a solicitud del cliente).
- **Costo [I]:** de 0,05 a 0,1 sp (un validador común en `OpcionesComando` y el parámetro en cada verbo).

**Alternativas descartadas:**
- *(a) Solo los verbos que tocan cuentas o datos de un cliente* (`restablecer-factor`, `sellos`, `empresa --cambiar-rnc`, `accesos --convertir`), sin los de infraestructura (`anillo`, `aprovisionar --sin-tpm`, sellado inicial). Exige clasificar cada verbo, y la clasificación se desvía con el tiempo. Además, los verbos de infraestructura también los ejecuta un técnico de GSF en el servidor del cliente; es el mismo riesgo de la Ley 53-07 que motiva DP-5. Una regla única es la misma razón de CS-01 (a): «dos reglas son dos caminos que probar».
- *(b) Caso solo en las rutas de la API y no en `GPOS.Migracion`.* El acceso del técnico al servidor es más amplio que el del SUPER en la API, y quedaría sin enlace con el hilo del correo.

**A firma del propietario:** R2 amplía lo que el SUPER escribe en las rutas de DB-7 que hoy no piden motivo. El caso en `GPOS.Migracion` cambia lo que hace el técnico de GSF; ADR-92 habla del SUPER, así que extenderlo al técnico es una precisión del ADR.

**Contratos que toca:**
- todos los DTO de la tabla de R2 (ver CS-P5);
- `CuentasSuperDtos.cs` y `MiembrosDtos.cs` de DB-7 [V] `[BP3]:606`;
- `OpcionesComando.Admitidas` de `GPOS.Migracion`.

---

## CS-P5. Contrato del número y la modalidad en el ingreso y en el cambio de empresa

### Recomendación propuesta: campos planos, una interfaz común y el mismo error

**Los DTO de D2** (aún no construidos, así que no hay rotura):
- `LoginRequest v2 {Usuario, Preautorizacion?, Confirmacion?, Empresa, Sucursal?, Dispositivo?, Motivo?, Caso?, Modalidad?}`;
- `CambiarEmpresaRequest {Empresa, Sucursal?, Motivo?, Caso?, Modalidad?}`.
- Base: [V] `[BP3]:369`, `:371`; hoy `Cuentas.cs:8` y `:104`.

**`Modalidad`:**
- es una cadena con valores cerrados `CORREO | URGENCIA` (enum `ModalidadAccesoSuper` serializado como texto);
- es obligatoria para el SUPER en esas dos rutas, igual que `Motivo`;
- se ignora para quien no es SUPER, como hoy `Motivo`.

**Interfaz común en `GPOS.Contracts/Seguridad/Acceso`:**
```csharp
public interface IJustificacionSuper { string? Motivo { get; } string? Caso { get; } }
public interface IIngresoSuper : IJustificacionSuper { ModalidadAccesoSuper? Modalidad { get; } }
```
- La implementan los DTO de R1 (`IIngresoSuper`) y los de R2 (`IJustificacionSuper`). En los ya construidos, el cambio es **aditivo**: se agrega `string? Caso` a `RestablecerFactorRequest`, `LegitimarCuentaRequest`, `PurgarEntradaPadronRequest`, `CambiarRncRequest`, `ResolverRelojDto`, `DesbloqueoRestauracionRequest` y `LiberarCandadoRequest`.
- Web y MAUI se publican juntos con la API (rolling release). Un cliente viejo recibe el 426 de `VersionMinimaCliente` [V] `[BP3]:464`.

**Un solo validador** en `GPOS.Core` (`JustificacionSuper.Validar`), que usan la API y `GPOS.Migracion`:
- `Motivo`: de 10 a 500 caracteres, como hoy [V] `[BP3]:369`;
- `Caso`: `Trim().ToUpperInvariant()` y después `^[A-Z0-9-]{6,30}$` (CS-02). Normalizar a mayúsculas es lo mismo que se hace con los códigos de cuenta [V] `[BP3]:300`. Una «ñ» o una vocal con tilde siguen rechazadas, porque su mayúscula no está en el patrón. **No se valida la convención** `GSF-AAMMDD-NN`, solo la forma (CS-02);
- `Modalidad`: uno de los dos valores (solo en R1).

**Error:**
- Se reutiliza **400 `MOTIVO_INVALIDO`** [V] `[BP3]:326`; `Cuentas.cs:166`.
- Lleva una extensión nueva y aditiva del `ProblemDetails`: `campos: ["motivo" | "caso" | "modalidad"]`, para que la pantalla marque el campo que falla.
- **No se crea un código nuevo**, como pide CS-01.
- **Orden:** el error va **después** de validar la preautorización, como el motivo hoy [V] `[BP3]:369`. Quien no pasó la contraseña y el factor no aprende nada de la forma del caso.

**Lo que no hace la API:**
- **No compara** el caso de una acción de R2 con el del ingreso de la sesión: una acción global (por ejemplo, restablecer la clave de una cuenta) puede ser de otro caso.
- **No confía** en el valor que propone la pantalla (CS-09): valida en cada petición.

**El rol que pidió la urgencia (CS-04) va dentro del motivo, como firma el ADR:**
- la pantalla ofrece un selector (enlace de TI, contador u otra persona designada);
- antepone el texto al motivo;
- la API no lo valida aparte [I].

**Alternativas descartadas:**
- *(a) Un objeto anidado* `Justificacion {Motivo, Caso, Modalidad}` en lugar de campos planos. Obliga a renombrar `Motivo` en siete DTO ya construidos (cambio incompatible) y no gana nada en validación frente a la interfaz.
- *(b) Un código nuevo* `CASO_INVALIDO`. Contradice CS-01 («el mismo error de motivo inválido») y suma un código al catálogo sin una conducta distinta en el cliente.
- *(c) Una columna o un campo `RolSolicitante`.* El ADR lo firmó «en el motivo»; sería una columna más en D1 para un caso que el propietario califica de casi nulo.

**A firma del propietario:** los textos del error y de las etiquetas, y el selector del rol (los ve el SUPER). Van a disenador-ux-ui.

**Contratos que toca:**
- `LoginRequest v2` y `CambiarEmpresaRequest` (D2);
- los 7 DTO construidos de R2 y los DTO del SUPER de DB-7;
- `ProblemDetails` (extensión `campos`).

---

## CS-P6. Cierre de la urgencia sin entrar a una empresa, y urgencias abiertas en Web y MAUI

### Recomendación propuesta: rutas del SUPER que aceptan la preautorización o la sesión

Hay un precedente de ruta que acepta «preautorizado o autenticado»: `GET /api/auth/empresas/{codigo}/sucursales` [V] `[BP3]:368`. La preautorización:
- solo existe después de la contraseña y, en el SUPER, del factor (`amr` con `otp`) [V] `[BP3]:366-367`, `:384-388`;
- dura 5 minutos;
- no crea sesión ni empresa, así que no escribe `INGRESO_SUPER`. Es lo que pide CS-05: el cierre no es un acceso a datos del cliente.

| Método y ruta | Entrada | Salida | Validaciones y errores | Permiso | Aislamiento |
|---|---|---|---|---|---|
| `GET /api/auth/super/urgencias` | `X-GPOS-Preautorizacion` o bearer | 200 `UrgenciaAbiertaDto[] {Caso, Empresas: [{Codigo, Nombre}], AbiertaDesdeUtc, UltimoIngresoUtc, Ingresos}`, de la más antigua a la más reciente, con un tope de 100 | 401 `PREAUTORIZACION_VENCIDA`; 403 si la cuenta no es SUPER (lo decide `EstadoAcceso`, no el token) o si `amr` no trae `otp` | SUPER | Toda la instalación (el SUPER es de la plataforma: ADR-44 y ADR-53). Solo la ve el SUPER |
| `POST /api/auth/super/urgencias/{caso}/cierre` | `CerrarUrgenciaRequest {Resultado: RESPONDIDO \| RETICENCIA, Nota?}` (`Nota` de 0 a 500) | 200 `{Caso, Empresas[], CerradaUtc}` | 400 `MOTIVO_INVALIDO` con `campos: ["caso"]` si `{caso}` no cumple CS-02; 404 **`URGENCIA_NO_ABIERTA`** (nuevo; no hay urgencia abierta con ese caso, también si ya se cerró); 401 y 403 como arriba; 429 (5 por minuto, como `SellosSuper`) | SUPER con `otp` | Escribe **una fila del evento de cierre por cada empresa** con urgencia abierta de ese caso, con `Empresa` = la afectada. Así cada ADMIN la ve en su bitácora y se cumple `CK_BitacoraSeguridad_EmpresaCategoria` [V] `[D1]:921-923`. Mismo patrón que `ACCESOS_CONVERTIDOS`, «una fila por empresa» [V] `[BP3]:543` |

**Reglas comunes:**
- La preautorización **no se consume** (como en `sucursales`, [V] `[BP3]:388`). Una repetición dentro de los 5 minutos solo puede volver a cerrar, y recibe el 404.
- **Clase de licencia `Esencial`**, con su entrada en `RutasLicenciaAprobadas.json`. Con la preautorización no hay empresa que evaluar; con bearer, la licencia de la empresa de la sesión no debe impedir el cierre.
- **Sitio `SoloCentral`** [I]: la bitácora que manda es la de la central. En un nodo responde 503 `REQUIERE_CENTRAL` [V] `Sitio.cs:50-60`.
- **Concurrencia:** derivar las urgencias abiertas y escribir el cierre van en una transacción con bloqueo por caso. Si dos SUPER cierran a la vez, el segundo recibe el 404. El detalle (bloqueo, índice) es del arquitecto de datos (CS-P2 y CS-P3).
- El cierre registra `Usuario` (código del SUPER), `ActorNivel = 'SUPER'`, `Ip`, `Canal` y `Dispositivo`, con `Sesion` NULL.

**Pantallas, con un componente Razor compartido Web/MAUI (EST 5.12) [I]:**
1. **En el paso de elegir empresa del inicio de sesión** (después de `identificar` y del factor), si `EsSuper`:
   - un panel «Urgencias abiertas (N)» con caso, empresas, antigüedad en días y último ingreso;
   - por fila, un botón «Registrar cierre» con un diálogo: resultado (dos opciones) y una nota opcional;
   - es el «al iniciar sesión» de CS-06, **antes** de entrar a ninguna empresa;
   - si la consulta falla, el panel dice que no se pudo cargar y el inicio de sesión sigue: CS-06 no bloquea.
   - Va en `Login.razor` de Web y MAUI [V] `src/GPOS.Web/Components/Pages/Cuenta/Login.razor`, `GPOS.UI.MAUI/Components/Pages/Cuenta/Login.razor`.
2. **Página del área del SUPER** `/super/urgencias`, con la misma lista y el mismo diálogo, por bearer. Sirve para cerrar estando ya dentro, sin un ingreso nuevo. Va junto a `/super/bitacora-seguridad` [V] `src/GPOS.Web/Components/Pages/Super/BitacoraSeguridad.razor:1`.
3. En la ventana de ingreso (CS-04, CS-09), si el caso tecleado tiene una urgencia abierta, un aviso informativo. No bloquea.

**Lista aparte, no dentro de `IdentificacionResponse`.** Mantiene la ruta de inicio de sesión sin una consulta a la bitácora (con su p95) y aísla el fallo. Con el índice de CS-P2, la consulta es despreciable: de 2 a 5 ingresos del SUPER al mes por instalación [V] `[ADR92]:90`.

**Alternativas descartadas:**
- *(a) Una sesión del SUPER sin empresa* («solo área del Super Usuario»). Es un tipo de sesión nuevo: toca el paso f de `ValidacionAcceso` [V] `[BP3]:477`, la introspección v2 y las pruebas de aislamiento. Lo estimo en 0,3 a 0,5 sp más [I], para una operación casi nula.
- *(b) Cerrar desde una sesión en cualquier empresa, sin más.* En una instalación de una sola empresa obliga a un `INGRESO_SUPER` con caso, es decir, a un acceso a datos del cliente, contra CS-05.
- *(c) Cerrar con un verbo de `GPOS.Migracion` en el servidor.* Es un acceso más amplio (al servidor) para registrar un hecho administrativo.
- *(d) Meter la lista en `AvisosEntrada`* [V] `SegundoFactor.cs:35-36`. Solo llega después del `login` a una empresa, tarde para cerrar sin entrar.

**Costo:** dentro de los 0,2 a 0,35 sp de CS-2 [V] `[ADR92]:87`. La vía con preautorización cuesta lo mismo que una ruta con sesión, porque el validador ya existe para `sucursales` [I].

**A firma del propietario:** los textos y la ubicación del panel, el diálogo y la nota opcional, porque cambian lo que ve el SUPER. La aceptación de la preautorización para una escritura va a revisión del auditor-seguridad (ver Entregas).

**Contratos que toca:**
- dos rutas nuevas en `/api/auth/super/urgencias`;
- `UrgenciaAbiertaDto`, `CerrarUrgenciaRequest` y `ResultadoCierreUrgencia` en `GPOS.Contracts/Seguridad/Acceso`;
- el código nuevo `URGENCIA_NO_ABIERTA` (comprobé con `git grep` en todas las ramas de `origin` que no existe);
- `RutasLicenciaAprobadas.json`.

---

## CS-P7. Cómo ve el ADMIN el caso y la urgencia en la bitácora de D5

### Recomendación propuesta
**Contrato:** `GET /api/admin/bitacora` [V] `[BP3]:412` agrega a cada fila de la fuente `acceso` tres campos y un filtro:
- `Caso?`;
- `Modalidad?` (`CORREO | URGENCIA`, solo en `INGRESO_SUPER`);
- `ResultadoCierre?` (solo en el evento de cierre);
- un filtro `?caso=` de coincidencia exacta, normalizado como en CS-P5, con el índice que decida CS-P2.

**Pantalla `Admin/Bitacora.razor` de Web y MAUI** [V] `src/GPOS.Web/Components/Pages/Admin/Bitacora.razor:1`, con su par en MAUI:
- una columna «Caso» con el número;
- junto a él, una etiqueta «Urgencia» cuando la modalidad lo es;
- en la fila del cierre, «Cierre de urgencia: respondido por el cliente» o «… reticencia documentada»;
- el filtro «Caso» en la cabecera;
- en MAUI, como etiqueta de dato en la tarjeta (`DataLabel`).

**Se mantiene lo firmado:**
- el SUPER aparece como «Super Usuario», sin su código [V] `[BP3]:991-992`;
- se omite `EmpresaActua` (TRZ-06) [V] `[BP3]:559`;
- el ADMIN solo ve filas con `Empresa` = la de su token [V] `[D1]:86`;
- el número de caso no es dato personal (CS-07), así que no se enmascara.

**El estado «abierta o cerrada» no se calcula en la vista del ADMIN.** El ADMIN ve el ingreso con urgencia y, después, la fila del cierre de su empresa (CS-P6 escribe una por empresa). Con el filtro por caso ve los dos juntos.

**Aislamiento:** si un caso abarcó las empresas A y B, el ADMIN de A ve solo las filas de A. No ve que hubo un ingreso a B, porque el cierre de B es otra fila con `Empresa = B`.

**Alternativas descartadas:**
- *(a) Calcular y mostrar el estado de la urgencia por fila.* Es una consulta por fila o una vista derivada para un dato que el ADMIN deduce con el filtro; también abriría la pregunta de qué mostrar si el caso tocó otra empresa.
- *(b) Meter el caso dentro de la columna «Motivo / detalle».* No se puede filtrar y se pierde el propósito de CS-07 (cotejar con el hilo del correo).

**A firma del propietario:** las etiquetas y la columna nueva, porque cambian lo que ve el ADMIN. Van a disenador-ux-ui.

**Contratos que toca:** el DTO de fila de la bitácora del ADMIN (`GPOS.Contracts`) y el parámetro `caso` de `GET /api/admin/bitacora`.

---

## TT-P6. Ruta de TT-05 como `Esencial`, privilegio nuevo y prueba de arquitectura

### Hechos
- Hoy las tres excepciones de LV-12 quedan en `Operativa` «hasta AI-07 (R-B2)» [V] `tests/GPOS.Tests/Licencia/RutasLicenciaAprobadas.json:3`.
- `[LIC]` dejaba abierto si se edita con la ruta del maestro o con «una ruta propia de rectificación» [V] `[LIC]:882`.
- Las rutas de los maestros reciben el DTO completo (precios, crédito) [V] `src/GPOS.Api/Endpoints/TablasEndpoints.cs:13-29`.
- No encontré una ruta de empleados (`rrhh.Empleado`) en `feature/modelo-ng` [I].

### Recomendación propuesta: rutas propias, DTO cerrados por maestro, y la clase y el permiso en la ruta

**Rutas** (grupo `/api/titulares`, `{maestro}` restringido a `clientes | suplidores | empleados`):

| Método y ruta | Entrada | Salida | Errores | Clase de licencia |
|---|---|---|---|---|
| `GET /{maestro}/{codigo}` | — | `FichaTitularDto {Maestro, Codigo, Nombre, EsPersonaFisica, Bloqueado, Campos}` (solo los campos personales) | 404 `TITULAR_NO_EXISTE` | `Consulta` (por omisión) |
| `POST /{maestro}/{codigo}/rectificar` | `RectificarClienteRequest`, `RectificarSuplidorRequest` o `RectificarEmpleadoRequest`: **solo** las propiedades de la lista de TT-02, más `Motivo` (10 a 500), `FechaRecepcion` (`DateOnly`, no futura) y `Caso?` | 200 `ResultadoSolicitudTitularDto {CamposTocados[], PlazoInformativo}` (fecha de recepción más 10 días hábiles; solo informa, TT-02) | 404; 409 **`TITULAR_NO_PERSONA_FISICA`**; 409 **`TITULAR_BLOQUEADO`**; 400 **`CAMPO_NO_PERSONAL`** (propiedad desconocida); 400 `MOTIVO_INVALIDO`; 400 **`FECHA_RECEPCION_INVALIDA`** | **`Esencial`**, en la lista aprobada |
| `POST /{maestro}/{codigo}/suprimir` | `SuprimirTitularRequest {Motivo, FechaRecepcion, Confirmacion, Caso?}`. `Confirmacion` = el código del registro tecleado, porque es irreversible (TT-03) | 200 `{CamposAnonimizados[]}` | Los mismos, más 400 **`CONFIRMACION_INVALIDA`** | **`Esencial`**, en la lista aprobada |

Los cinco códigos nuevos no existen en ninguna rama de `origin` (`git grep`, 2026-10-21).

**Reglas del servidor:**
- **La persona física se decide en el servidor**, con el `TipoIdentificacion` guardado y nunca con el pedido. Una sola función de dominio, `ClasificacionTitular.EsPersonaFisica`, en `GPOS.Core`:
  - empleados, siempre;
  - `C`, `P` y `N`, física;
  - `R`, jurídica.
  - El criterio lo fija TT-P1 (arquitecto-datos con el especialista-pos); la ruta solo llama a la función.
- **`Caso`** es obligatorio si quien actúa es el SUPER (TT-05 y CS-01), con el validador de CS-P5. Al ADMIN y al USER con el privilegio no se les pide.
- **Bloqueo:** después de suprimir, `POST /api/maestros/*` y la creación de documentos rechazan el registro con 409 `TITULAR_BLOQUEADO` (TT-03 ii). Va en el servicio del maestro y del documento, no en estas rutas.
- **Sitio `SoloCentral`** [I]: el acto se hace una vez sobre la copia que manda, y la anonimización baja a los nodos por la sincronización. Cómo baja lo deciden el arquitecto de datos y el de integraciones.
- **Bitácora:** un evento con los **nombres** de los campos, sin valores (TT-06). Dónde, lo decide TT-P4.

**Privilegio nuevo:**
- clave `solicitudestitulares` en `Permisos` (`GPOS.Contracts/Seguridad/Permisos.cs`);
- etiqueta propuesta «Atender solicitudes de titulares de datos personales»;
- grupo **«Especiales»**, junto a «Ver costos» y «No generar comprobante» [V] `Permisos.cs:286-287` (preferencia del propietario por ese grupo, RG-04);
- tipo `Privilegio` (sí o no), sin estar en los perfiles de ejemplo;
- el ADMIN y el SUPER lo tienen por su nivel, como los demás [V] `Permisos.cs:43-48`;
- la ruta lleva `.RequierePermiso(Permisos.SolicitudesTitulares)` y **no** exige el permiso del maestro (TT-05 nombra solo este privilegio).

**Pruebas de arquitectura** (en `tests/GPOS.Tests/Arquitectura/` y `Licencia/`):
1. **Lista cerrada de campos.** Las propiedades de cada `Rectificar*Request`, sin `Motivo`, `FechaRecepcion` ni `Caso`, son **iguales** a la lista aprobada y versionada de TT-02 (`CamposPersonalesTitular.json`, con la regla de `RutasLicenciaAprobadas.json`: cada cambio se revisa como un cambio de seguridad). La prueba falla también si aparece un nombre prohibido: `Codigo`, `Precio*`, `Lista*`, `Credito*`, `Limite*`, `Saldo*`, `Descuento*`, `Ncf*`.
2. **Sin campos extra en el JSON.** Los tres DTO llevan `[JsonUnmappedMemberHandling(JsonUnmappedMemberHandling.Disallow)]` (System.Text.Json, disponible desde .NET 8; el proyecto está en `net10.0` [V] `GPOS.Contracts.csproj`). La prueba comprueba que un cuerpo con `"LimiteCredito"` devuelve 400 `CAMPO_NO_PERSONAL`, y no que lo ignora en silencio.
3. **Clase y lista aprobada.** Con la empresa en `SoloConsulta`: las dos rutas `POST` pasan; `POST /api/maestros/clientes` sigue bloqueada (`Operativa`). Ninguna otra ruta que escriba en `cat.Cliente`, `cat.Suplidor` o `rrhh.Empleado` es `Esencial`.
4. **Solo personas físicas.** Rectificar un registro `R` devuelve 409, en las tres clases de licencia.
5. **Prueba de servicio (no de arquitectura).** Antes y después de rectificar, todas las columnas que no son personales del registro quedan iguales, incluidos crédito, saldos y código.

**Alternativas descartadas:**
- *(a) Reutilizar `POST /api/maestros/{maestro}` con un modo «titular» que filtra los campos en el servicio.* El filtro no lo ve la prueba de arquitectura, y la ruta tendría dos clases de licencia según el cuerpo; `UseLicencia` clasifica por ruta, no por cuerpo [V] `[LIC]:610-614`.
- *(b) Un solo DTO genérico `Dictionary<string,string?>` de cambios.* La lista blanca quedaría solo en tiempo de ejecución; un error de validación pasa sin que falle ninguna prueba de compilación ni de reflexión.
- *(c) Seis rutas explícitas*, una por maestro y acción. Tres entradas más en la lista aprobada sin otra ventaja: la restricción de `{maestro}` ya cierra los valores.

**Costo:** dentro de los 0,55 a 0,95 sp de TT [V] `[ADR92]:88`. Las pruebas 1 a 4 son de 0,05 a 0,1 sp de ese total [I].

**A firma del propietario:** la etiqueta y el grupo del privilegio; la confirmación tecleada al suprimir; el aviso informativo del plazo. Todo eso cambia lo que ve o hace el ADMIN.

**Contratos que toca:**
- el grupo nuevo `/api/titulares` (3 rutas);
- los DTO `FichaTitularDto`, `Rectificar{Cliente,Suplidor,Empleado}Request`, `SuprimirTitularRequest` y `ResultadoSolicitudTitularDto`;
- `Permisos.SolicitudesTitulares`;
- cinco códigos nuevos;
- `RutasLicenciaAprobadas.json`;
- la conducta de `POST /api/maestros/*` con un registro bloqueado.

---

## Seguridad de arquitectura (resumen)
- **Autenticación:** el cierre y la lista de urgencias exigen la preautorización o una sesión del SUPER con `otp`. Si la cuenta es SUPER lo decide `EstadoAcceso` (Q1), nunca un claim [V] `[BP3]:586`.
- **Autorización:** R1 y R2 en el validador común; TT con `RequierePermiso` y la clase `Esencial` en la lista aprobada.
- **Aislamiento entre tenants:**
  - el ADMIN ve solo filas con `Empresa` = la de su token;
  - el cierre escribe una fila por empresa afectada y nunca menciona otra empresa;
  - las rutas de titulares actúan solo sobre la empresa del token.
- **Secretos:** ninguno nuevo. El número de caso no es secreto ni dato personal; en el caso no van nombres (CS-02 (c)).

## Necesidades para Datos (arquitecto-datos)
- **CS-P2:**
  - tipo y largo de `Caso` (propongo `varchar(30)` con `CHECK` sobre el patrón, ya normalizado a mayúsculas por la API) y de `Modalidad` o urgencia;
  - un **indicador «exige caso» por evento en `CatalogoEventosSeguridad`** (en lugar de una lista en el `CHECK`), para que R2 crezca sin otro `ALTER`; lo decide datos;
  - un índice por `Caso` para el filtro del ADMIN y para derivar las urgencias abiertas.
- **CS-P3:**
  - el nombre del evento de cierre;
  - que se escriba una fila por empresa;
  - la comprobación «existe un ingreso con urgencia abierto» en la misma transacción, con bloqueo por caso;
  - que la derivación cuente también los eventos de `GPOS.Migracion` con `--urgencia`.
- **TT-P4:** dónde va el evento de TT-06. Si va en `BitacoraSeguridad`, con `Caso` cuando actúa el SUPER.
- **TT-P1:** el criterio de `ClasificacionTitular.EsPersonaFisica`.

## Necesidades para Integraciones
- Cómo baja a los nodos la anonimización de TT-03 (la ruta es `SoloCentral`).
- Que los `INGRESO_SUPER` de un nodo suban a la central, para que la lista de urgencias abiertas los vea (riesgo 2).

## Riesgos
1. **Preautorización usada para una escritura** (el cierre). Es la primera vez. Mitigación: idempotente (el segundo cierre recibe 404), 5 minutos, `otp`, límite de 5 por minuto y sin datos del cliente. Pendiente de la revisión del auditor (Media).
2. **Urgencias de un nodo de sucursal sin conexión:** no se ven en la lista de la central hasta que sincronizan (Baja; el SUPER en un nodo es raro) [I].
3. **R2 amplía el motivo y el caso a rutas de DB-7 que hoy no los piden.** Suma de 0,05 a 0,1 sp a D1 y D2 [I]. Dentro del CS-1 firmado (0,35 a 0,55 sp) si B lo absorbe ahí; si no, pide decisión.
4. **La lista de campos de TT-02 aún no existe** (especialista-pos con datos). Sin ella, la prueba 1 de TT-P6 no tiene contra qué comparar. Bloquea la construcción de TT, no el diseño.

## Decisiones candidatas a ADR (precisión de ADR-92, la prepara el Maestro)
- **P-92-S1:** R1, R2 y R3 como regla de la lista cerrada, con una prueba de arquitectura. Descartada: la lista enumerada a mano.
- **P-92-S2:** caso (y `--urgencia` opcional) en los verbos de `GPOS.Migracion` que piden `--motivo`. Descartada: solo los verbos que tocan cuentas o datos.
- **P-92-S3:** cierre y lista de urgencias por `/api/auth/super/urgencias`, con preautorización o sesión. Descartada: una sesión del SUPER sin empresa.
- **P-92-S4:** rutas propias `/api/titulares` con DTO cerrados y `JsonUnmappedMemberHandling.Disallow`. Descartada: el modo dentro de la ruta del maestro.

## Supuestos
- `[BP3]` y `[D1]` de `master` son la base de DB-7 (rev. 2) y no cambiaron después del 2026-10-19.
- Las rutas de empleados aún no existen. TT-P6 las nombra por analogía con clientes y suplidores.
- Web y MAUI se publican con la API (rolling release), así que agregar campos a DTO construidos no necesita convivencia de versiones más allá del 426.

## Entregas a otros agentes
- **arquitecto-datos (A):** lo de «Necesidades para Datos».
- **auditor-seguridad:** el riesgo 1 (escritura con preautorización), R3 (cobertura por la columna `Sesion`) y la extensión `campos` del 400.
- **disenador-ux-ui:**
  - el panel y el diálogo de urgencias en `Login.razor` y en `/super/urgencias`;
  - el selector del rol en el ingreso;
  - la columna «Caso» y la etiqueta «Urgencia» en la bitácora del ADMIN;
  - las pantallas de titulares (con la confirmación tecleada);
  - los textos van a firma.
- **especialista-pos:** la lista de campos de TT-02 por maestro (`CamposPersonalesTitular.json`).
- **arquitecto-integraciones:** las dos necesidades de sincronización.
- **arquitecto-maestro:** las precisiones P-92-S1 a S4 para la firma del propietario.

---

### Resumen (8 líneas)
1. CS-P1: tres reglas. R1: ingreso y cambio de empresa con caso y modalidad. R2: toda ruta `RequiereSuper` con `Motivo` pide `Caso` (lista de hoy en la tabla). R3: el resto lo cubre el ingreso por `Sesion`. Una prueba de arquitectura la mantiene cerrada.
2. Los verbos de `GPOS.Migracion` con `--motivo` exigen `--caso` (más `--urgencia` opcional): precisión del ADR, va a firma.
3. CS-P5: campos planos `Caso?` y `Modalidad?` en `LoginRequest v2` y `CambiarEmpresaRequest`, la interfaz `IJustificacionSuper` y un validador común; el 400 `MOTIVO_INVALIDO` se reutiliza con la extensión `campos`.
4. CS-P6: `GET` y `POST /api/auth/super/urgencias[/{caso}/cierre]` con preautorización o sesión (sin `INGRESO_SUPER`). El cierre escribe una fila por empresa. Panel en el paso de elegir empresa y página `/super/urgencias`.
5. CS-P7: `Caso`, `Modalidad` y `ResultadoCierre` en `GET /api/admin/bitacora`, con filtro `?caso=`. Columna y etiqueta «Urgencia» en `Admin/Bitacora.razor`; «Super Usuario» y sin `EmpresaActua`.
6. TT-P6: rutas propias `/api/titulares/{maestro}/{codigo}/rectificar|suprimir`, `Esencial` en la lista aprobada, con el privilegio `solicitudestitulares` en «Especiales».
7. La prueba de TT-P6 compara los DTO con la lista versionada de campos, rechaza el JSON extra (`Disallow`), comprueba la clase en `SoloConsulta` y rechaza los registros `R`.
8. Riesgo principal: escritura con preautorización (al auditor). Bloqueo de construcción de TT: falta la lista de campos de TT-02 (especialista-pos). Nada se decide aquí; textos, privilegio y extensión a `GPOS.Migracion` van a firma.
