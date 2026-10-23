[Informe de Seguridad] PR #168 (E-1, ADR-93 TA-P08): alcance por sucursal de existencias, kárdex, pestaña Almacenes, diseñador de reportes y gestión de cuentas del ADMIN restringido

Fecha: 2026-10-22 · Revisor: A (auditor-seguridad, Opus) · Rama `b/e1-adr93-alcance-sucursal`, punta `30ad5c4e`, base `feature/modelo-ng`.
Método: solo lectura (`git fetch` + `git diff origin/feature/modelo-ng...origin/b/e1-adr93-alcance-sucursal` + `git show <rama>:<ruta>`). No se cambió la rama ni el árbol de trabajo; no se compiló ni se ejecutó ninguna prueba.
Convención: **[V]** verificado leyendo el código de la punta; **[I]** inferido. Las rutas son relativas a la raíz de GPOS-NG en la punta `30ad5c4e`.
Antecedente: informe independiente de B (`traspasos/B/2026-10-22-informes/auditoria-b-168-170.md`, sobre `2c394a44`). Aquí se comprueba qué quedó de él en la punta nueva.

## Resumen y recomendación

**Recomendación técnica: Aprobar con condiciones.** La decisión de unir es del propietario (C2).

- El PR cumple lo que dice. El alcance de almacenes se lee en el servidor y falla cerrado. R-01, R-02 y R-04 no se pueden eludir con `?almacen=` ni con códigos inventados. No hay SQL dinámico. El 401 de Q-A2 mantiene al restringido en su sucursal en toda la API, también en la de reportes por la introspección. M-168-1 (regla única) y M-168-2, con su residuo, están construidos tal como se firmaron.
- No encontré ningún hallazgo Alto ni Crítico **atribuible al PR**.
- Tres hallazgos Medios, todos anteriores al PR o latentes, condicionan qué se puede afirmar del "ADMIN restringido":
  - **S168-01:** lo que B declara como no cubierto es real.
  - **S168-02:** fuera de la gestión de cuentas, el ADMIN restringido sigue siendo un administrador de toda la empresa (y de todo el sistema en los perfiles). Puede descargar adjuntos de correos de cualquier sucursal, redirigir el SMTP, editar los perfiles globales y cerrar otras sucursales.
  - **S168-03:** el ADMIN restringido puede ampliarse a sí mismo el alcance `Operativo`.

**Condiciones para unir:**
1. Registrar S168-01 y S168-02 como riesgo residual de ADR-93 en `estado.json` o en la precisión de TA-P08. Hasta que se cierren, no presentar `RestringirSucursal` en un ADMIN como control de confidencialidad ante un cliente; en un USER sí lo es, dentro de R-01, R-02 y R-04.
2. S168-03 queda como requisito de entrada de S-16b, antes de que R-05 o R-06 consuman `TipoAlcance.Operativo`.
3. Que el propietario decida el modelo del ADMIN restringido: "administrador de sucursal" o "restricción solo orientativa". La remediación de S168-01 y S168-02 depende de esa decisión.

---

## 1. Alcance y superficie revisada

- **P-0:**
  - `src/GPOS.Core/Servicios/Modulos/Inventario/AlcanceAlmacenes.cs`, `src/GPOS.Core/Consultas/Inventario/ConsultasAlcance.cs`, `src/GPOS.Api/Seguridad/EstadoCuentaSesion.cs`;
  - registro en `src/GPOS.Api/Program.cs:168-170`.
- **Sesión:** `RevocacionSesiones.Evaluar` y `SucursalAjena` (`src/GPOS.Api/Seguridad/RevocacionSesiones.cs:179`, `:191-194`), `TokenSesion.Desde` (claim de sucursal) e introspección de la API de reportes (`src/GPOS.Api/Seguridad/ValidadorTokenPrincipal.cs:39-41`).
- **R-01, R-02 y R-04:**
  - `InventarioService.ExistenciasAsync` y `KardexAsync` (`src/GPOS.Core/Servicios/InventarioService.cs:734-783`);
  - consultas `Existencias`, `Kardex` y `SaldoAntes` (`src/GPOS.Core/Consultas/Inventario/ConsultasDocInventario.cs:57-110`);
  - `MaestrosService.ArticuloAsync` y `GuardarArticuloAsync` (`src/GPOS.Core/Servicios/MaestrosService.Articulos.cs:67-190`, `:214-400`), `PuenteMae.ArticuloAsync` y el texto de «Requiere lote» (`LotesDocumento.cs:156-174`).
- **Diseñador (Q-A3):**
  - `ReportesService.SoloDisenadorAsync` (`src/GPOS.Core/Servicios/ReportesService.cs:266-271`) y sus cuatro llamadas;
  - API de reportes: `ProveedorContexto.Restringe` (`src/GPOS.Reportes/Contexto/ProveedorContexto.cs:93`) y `ContextoReportes.PuedeDisenar` (`src/GPOS.Reportes/Contexto/ContextoReportes.cs:43`).
- **M-168-1 y M-168-2 con su residuo:**
  - `UsuarioAlcance.Restringe` (`src/GPOS.Contracts/Seguridad/UsuarioAlcance.cs`);
  - `UsuariosService.GuardarAsync`, `ExigirRestriccionSinCambiosAsync`, `ExigirCuentaEnAlcanceAsync`, `DesbloquearAsync`, `ForzarNuevoInicioAsync` y `ResolverSucursal` (`src/GPOS.Core/Sistema/UsuariosService.cs:309-318`, `:426-488`, `:493-631`, `:699-717`, `:850-873`);
  - las cinco rutas de `src/GPOS.Api/Endpoints/AdminEndpoints.cs:160-305`.
- **Superficie vecina del ADMIN restringido**, leída para valorar el riesgo residual que B declara:
  - todo el grupo `/api/admin` (`AdminEndpoints.cs:16-305`), `/api/admin/notificaciones` (`NotificacionesEndpoints.cs:38-80`), `PermisosService`, `AdministracionService` (POS por usuario y almacenes permitidos) y `CierreSucursalService`.
- **Pruebas:** los 10 archivos de `tests/GPOS.Tests/Alcance/*`, más `ProveedorContextoTests` y `SucursalesAccesoTests`; lectura de nombres y aserciones, sin ejecutarlas.
- **Fuera de alcance, por la partición firmada:**
  - S-16b (R-03, R-05 a R-13 y transferencias);
  - R-14, que pasa a T4-06 (ejecución y exportación de reportes de la principal sin filtro de sucursal).
  - Se citan solo cuando condicionan un hallazgo.

## 2. Tabla resumen de hallazgos

| ID | Sev. | Origen | Título | V/I |
|---|---|---|---|---|
| S168-01 | Media | Preexistente (declarado por B) | El ADMIN restringido lista todas las cuentas, cambia la configuración POS de cualquier usuario (descuento máximo, precios, caja) y consulta `politicas/efectiva` de cualquiera | V |
| S168-02 | Media | Preexistente (no declarado) | El resto de `/api/admin` no mira la restricción: adjuntos de la cola de correo de toda la empresa, SMTP, perfiles globales de `GPOS_SYSDATA`, cierre y NCF de otras sucursales, bitácora, parámetros | V código / I contenido de los adjuntos |
| S168-03 | Media (latente) | Preexistente; se activa con S-16b | El ADMIN restringido puede darse a sí mismo almacenes de otras sucursales en el alcance `Operativo` (almacenes permitidos) | V |
| S168-04 | Baja | PR | Carrera de lectura y comprobación sin bloqueo en `DesbloquearAsync` y `ForzarNuevoInicioAsync` | V código / I explotación |
| S168-05 | Baja | Sigue abierto (B-168-3) | El alcance y el 401 comparan solo el código de sucursal, no la empresa; la gestión de cuentas sí compara la empresa (incoherencia) | V |
| S168-06 | Baja | PR y preexistente | Oráculos menores: «no existe» (400) frente a 403, existencia de cuentas SUPER y existencia global del artículo | V |
| S168-07 | Baja | Sigue abierto (B-168-5) | El puente heredado compara los códigos de almacén en C# (`OrdinalIgnoreCase`), no por llave | V |
| S168-08 | Baja | PR | Huecos de las pruebas, y las 10 mutaciones no se pueden auditar porque su guion no está en el repositorio | V |

No hay hallazgos Críticos ni Altos atribuibles al PR. Ver la nota de severidad de S168-02.

## 3. Checklist OWASP

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | Revisado. R-01, R-02 y R-04 se resuelven en el servidor y se comparan por llave; IDOR por `?almacen=` cerrado; 401 Q-A2; M-168-2 completo en las cinco rutas. Quedan S168-01, S168-02, S168-03 y S168-05. |
| A02 Criptografía | No aplica (sin cambios). |
| A03 Inyección | Revisado. Constantes SQL con parámetros tipados (`bit`, `smallint` con `DbType.Int16`, `varchar(20)` con `Sql.Varchar`) y sin concatenación ni `FormattableString` en lo nuevo. El `LIKE '%' + @p1 + '%'` de `Existencias` va parametrizado: un `%` o `_` del usuario solo amplía la búsqueda dentro del alcance. Sin hallazgo. |
| A04 Diseño inseguro | Revisado. Falla cerrada: `default(AlcanceResuelto)` es Vacío; cuenta nula o inhabilitada da Vacío; sucursal irresoluble da Vacío; `@global=0` con `NULL` no da filas. Quedan S168-02 y S168-03 (modelo del ADMIN restringido). |
| A05 Configuración | Revisado. El constructor interno «global» solo lo ven `GPOS.Tests` y `GPOS.Migracion` (`GPOS.Core.csproj:49-51`); no hay `new InventarioService/MaestrosService/ReportesService(` en `src/`. Sin hallazgo. |
| A06 Componentes vulnerables | No revisado: el PR no agrega paquetes y no hay herramienta en esta sesión. |
| A07 Autenticación | Revisado. El token de otra sucursal, sin sucursal o de un restringido sin sucursal asignada da 401 «credenciales», después del sello, sin tapar las causas anteriores. Al cambiar la cuenta se llama a `Olvidar` (`RevocacionSesiones.cs:222`). Sin hallazgo. |
| A08 Integridad | Revisado. El guardado del restringido conserva los niveles ajenos (modelo nuevo y heredado); S168-07. |
| A09 Registro y monitoreo | Revisado. Los 403 de M-168-2 no se auditan como intento rechazado [V: `AdminEndpoints.cs` solo audita el éxito]; ver la remediación de S168-01. Los mensajes no incluyen datos de la cuenta destino. |
| A10 SSRF | No aplica. |

## 4. Hallazgos

### S168-01 · Media · Lo que B declara como no cubierto es real [V]

**Riesgo.** El ADMIN restringido a S1 sigue teniendo tres capacidades sobre cuentas de cualquier sucursal o empresa:
- **Configuración POS por usuario:** `POST /api/admin/pos/usuarios` y `DELETE`. Es la de más impacto. Permite fijar a un cajero de S2 `PermitirDescuento`, `PorcentajeMaximoDescuento` hasta 100 %, `ModificarPrecios`, quitar «búsqueda manual» o asignarle otra caja. Abre un fraude en caja de otra sucursal con un cómplice, o el sabotaje de su operación, sin tocar la ficha de la cuenta. Así se elude el espíritu de M-168-2: la configuración POS no es "gestionar la cuenta", pero cambia lo que esa cuenta puede hacer.
- **Lista completa de cuentas:** `GET /api/admin/usuarios` devuelve todas las cuentas que no son SUPER, con nivel, sucursal, perfiles, permisos efectivos, bloqueo y último acceso. Es inventario para elegir objetivos, por ejemplo los ADMIN sin restricción a los que dirigir ingeniería social.
- **Política efectiva:** `GET /api/admin/politicas/efectiva` de cualquier cuenta; solo lectura, impacto bajo.

**Evidencia.**
- `src/GPOS.Api/Endpoints/AdminEndpoints.cs:118-129`: POS por usuario. Solo comprueba que la cuenta exista.
- `src/GPOS.Core/Servicios/AdministracionService.cs:806-830`: `GuardarUsuarioPosAsync` no mira quién guarda ni la sucursal del destino.
- `AdminEndpoints.cs:157` con `UsuariosService.ListarAsync` (`UsuariosService.cs:347-367`): sin filtro por alcance.
- `AdminEndpoints.cs:148-153`: `politicas/efectiva`.

**Escenario de abuso.** El gerente de S1 (ADMIN restringido) sube el descuento máximo de un cajero cómplice de S2 al 100 %. Las ventas con descuento en S2 quedan "autorizadas" por configuración. La bitácora registra el cambio de configuración, pero ningún control impide que lo haga alguien de otra sucursal.

**Remediación** (unos 0,15 dp, USD 0):
- En `GuardarUsuarioPosAsync` y `EliminarUsuarioPosAsync`, si el solicitante está restringido, exigir que la cuenta destino pase la misma regla de `ExigirCuentaEnAlcanceAsync`. Conviene hacerla pública como `UsuariosService.ExigirGestionableAsync(destino, solicitante)`, para tener una sola regla.
- En `ListarAsync`, para el solicitante restringido, devolver solo las cuentas restringidas de su empresa y sucursal (las que puede gestionar).
- En `politicas/efectiva`, la misma regla.
- Auditar los 403 `RESTRICCION_*` como intento rechazado (A09), porque son señal de abuso interno.

**Alternativa descartada:** ocultar la pantalla en la interfaz. No es un control.

### S168-02 · Media · Fuera de la gestión de cuentas, el ADMIN restringido sigue siendo administrador de toda la empresa [V código, I contenido]

**Riesgo.** El grupo `/api/admin` solo exige `RequiereAdmin` (`AdminEndpoints.cs:16`, `Seguridad.cs:286-287`), y ningún servicio de los siguientes consulta la restricción. Lo verifiqué buscando `Restring` y `Alcance` en `CierreSucursalService.cs`, `AdministracionService*.cs`, `PermisosService.cs` y `NotificacionesService.cs`, sin resultados que limiten.

| Capacidad | Evidencia | Efecto sobre la confidencialidad o integridad entre sucursales |
|---|---|---|
| Descargar el adjunto de cualquier correo de la cola | `NotificacionesEndpoints.cs:75` y `NotificacionesService.cs:252-258`: por `id` secuencial, sin filtro | Lee PDF de documentos compartidos y de reportes programados de cualquier sucursal [I: el contenido depende de lo que se haya enviado] |
| Cambiar el servidor SMTP de la empresa | `NotificacionesEndpoints.cs:41` | Desvía el correo saliente de todas las sucursales a un servidor propio |
| Crear, modificar y eliminar perfiles | `AdminEndpoints.cs:215-232`; `PermisosService(SistemaDbContext)` (`PermisosService.cs:11`, `:65`) | Los perfiles son de `GPOS_SYSDATA`: cambian los privilegios de los usuarios de todas las sucursales **y de todas las empresas** |
| Evaluar, cerrar, reabrir y reasignar NCF de otra sucursal | `AdminEndpoints.cs:57-70` (`RequierePermiso(Sucursales)`; el ADMIN tiene todos los privilegios) | Deja sin operar a otra sucursal y mueve sus rangos NCF |
| Bitácora completa | `AdminEndpoints.cs:144-145` | Lee la actividad de todas las sucursales |
| Parámetros, NCF, puntos de emisión, configuración POS general, respaldos | `AdminEndpoints.cs:72-105`, `:116-117`, `:131-142` | Configuración de toda la empresa |

**Nota de severidad.**
- La califico Media para este PR porque es anterior, el PR no la empeora y el alcance firmado de M-168-2 se limita a la gestión de cuentas. Además, el actor ya es un ADMIN y hoy no hay producción.
- Si el propietario entiende la restricción del ADMIN (D-3) como frontera de confidencialidad entre sucursales, este hallazgo es **Alto** para esa promesa de producto. La cola de correo da lectura directa de documentos ajenos sin cómplice.

**Escenario de abuso.** El ADMIN de S1 recorre los `id` de la cola de correo y descarga los PDF de facturas y cotizaciones que envió S2 a sus clientes. O edita el perfil «CAJERO», que comparten todas las empresas, para quitar o añadir privilegios.

**Remediación**, según lo que decida el propietario:
- **(a) "ADMIN restringido = administrador de su sucursal"** (recomendada; unos 0,3 dp más 0,1 dp de pruebas, USD 0):
  - una política `AdminSinRestriccion`, con un requisito que use `IAlcanceAlmacenes.SinRestriccionAsync`, aplicada a `/api/admin` y `/api/admin/notificaciones`;
  - una lista explícita de excepciones: las rutas de usuarios, ya acotadas por M-168-2 y por S168-01.
  - Es una sola pieza y falla cerrada para las rutas que se agreguen después.
- **(b) "La restricción del ADMIN es orientativa"** (0,02 dp): escribirlo en la precisión de TA-P08. Es más barata, pero deja vacíos D-3 y Q-A3 para el ADMIN.
- **Descartada:** filtrar ruta por ruta en cada servicio. Cuesta más (unos 0,8 dp) y cada ruta nueva nace abierta.

### S168-03 · Media (latente) · El ADMIN restringido puede ampliar su propio alcance `Operativo` [V]

**Riesgo.**
- `ConsultasAlcance.Almacenes` agrega al alcance `Operativo` los almacenes de `org.SucursalAlmacenPermitido` para `@sucursalAlcance` (`src/GPOS.Core/Consultas/Inventario/ConsultasAlcance.cs:17-23`).
- `POST /api/admin/almacenes-permitidos` (`AdminEndpoints.cs:107-112`; `AdministracionService.AlmacenesPermitidos.cs:36-55`) deja que cualquier ADMIN, también el restringido, agregue la regla «S1 puede mover el almacén A2 de S2».
- Hoy ninguna ruta consume `TipoAlcance.Operativo`; lo verifiqué buscando `TipoAlcance.Operativo` en `src/`, y solo aparece en la propia pieza. Por eso es latente.
- En cuanto R-05 o R-06 (S-16b) lo usen, el restringido se dará a sí mismo almacenes ajenos.

**Escenario de abuso.** El ADMIN de S1 agrega la regla S1→A2. Con R-05 o R-06 construidos, sus documentos alimentan y muestran existencias y lotes de A2, de S2.

**Remediación** (unos 0,05 dp): `AgregarAlmacenPermitidoAsync` y `EliminarAlmacenPermitidoAsync` solo para un ADMIN sin restricción. Queda cubierto si se adopta (a) de S168-02. Debe ser requisito de entrada de S-16b, con una prueba propia.

### S168-04 · Baja · Lectura y comprobación sin bloqueo en `DesbloquearAsync` y `ForzarNuevoInicioAsync` [V código, I explotación]

**Evidencia.**
- `UsuariosService.cs:309-318` y `:699-717`: leen la cuenta destino con `AsTracking`, sin transacción ni `UPDLOCK`, comprueban el alcance (`:314`, `:710`) y guardan.
- En cambio, `GuardarAsync` comprueba dentro de una transacción `Serializable`, con el padrón y la fila bloqueados (`:502-527`).

**Riesgo.**
- Si el SUPER saca la cuenta del alcance justo entre la lectura y el guardado, el ADMIN restringido desbloquea o fuerza el cierre de sesión de una cuenta que ya no es de su sucursal.
- EF solo escribe las columnas modificadas (`BloqueadoHasta` e `IntentosFallidos`; o `SesionesRevocadas`, `SelloSeguridad` y la sesión), así que no revierte el cambio del SUPER.
- Efecto máximo: reiniciar el contador de intentos (que habilita otra ronda de prueba de contraseñas contra esa cuenta) o cerrar una sesión. No da acceso. La ventana es de milisegundos y depende de una acción concurrente del SUPER.

**Remediación** (unos 0,05 dp; opcional antes de unir): escritura condicional, `UPDATE … WHERE Codigo=@c AND RestringirSucursal=1 AND EmpresaDefault=@e AND SucursalDefault=@s` con 0 filas ⇒ 403; o envolver en transacción con `UPDLOCK` sobre la fila destino, como `BloquearCuentaAsync`.

### S168-05 · Baja · El alcance compara solo el código de sucursal, no la empresa (B-168-3 sigue abierto) [V]

**Evidencia.**
- `RevocacionSesiones.SucursalAjena` (`:191-194`) y `AlcanceAlmacenes.ResolverAsync` (`ConsultasAlcance.SucursalPorCodigo` en la base de la empresa de la petición) solo usan `SucursalDefault`.
- `EstadoSesionUsuario` no lleva `EmpresaDefault` (`UsuariosService.cs:1009-1012`).
- El diseño lo admite: «la restricción vale en cualquier empresa» (`src/GPOS.Contracts/Seguridad/Cuentas.cs:263`; `CierreSucursalService.cs:91`).
- `ExigirCuentaEnAlcanceAsync` sí exige la misma empresa (`UsuariosService.cs:479-480`).

**Riesgo.**
- Un restringido a (E1, S1) que entra a E2 ve los datos de la sucursal S1 de E2 y, si es ADMIN, administra E2 (S168-02).
- La incoherencia hace que la regla de cuentas y la de datos respondan distinto para la misma pareja. Antes de DB-7 v1 no hay membresía por empresa que lo limite [I].

**Remediación.** Decidir si la restricción es "por código de sucursal en cualquier empresa" (como hoy) o "por la pareja empresa y sucursal". Si es por pareja: añadir `EmpresaDefault` a `EstadoSesionUsuario` y compararlo en `SucursalAjena` (0,05 dp). Alternativa: diferirlo a DB-7.

### S168-06 · Baja · Oráculos menores [V]

- `/cerrar-sesiones` y `/desbloquear` resuelven la cuenta antes del servicio (`AdminEndpoints.cs:254`, `:297`): una cuenta inexistente da 400 «no existe» y una ajena da 403. Hoy no añade nada, porque `GET /usuarios` lista todo (S168-01). Si S168-01 acota la lista, conviene responder lo mismo (403) a lo inexistente y a lo ajeno para un restringido.
- Al restringido, «Solo un Super Usuario puede desbloquear/cerrar la sesión de un Super Usuario» (`UsuariosService.cs:313`, `:708`, `:518`) le confirma que existe una cuenta SUPER con ese código, aunque `ListarAsync` las oculta. Es preexistente.
- `GuardarArticuloAsync` responde «No puede convertir en servicio un artículo que tiene existencia» con la suma global (`MaestrosService.Articulos.cs:329-331`). Revela un booleano de existencia en otras sucursales. Es del mismo tipo que A.2.4 (aceptado para «Requiere lote»), así que basta con dejarlo anotado.
- **Remediación:** documentar o unificar respuestas cuando se acote S168-01 (0,05 dp).

### S168-07 · Baja · Puente heredado por código (B-168-5 sigue abierto) [V]

- `src/GPOS.Core/Infraestructura/Transicion/PuenteMae.cs:209-210` compara `IdAlmacen` con `OrdinalIgnoreCase`.
- Si la intercalación del servidor iguala códigos que C# distingue, una fila heredada del alcance no se borra y la inserción siguiente falla por duplicado. Falla cerrada, sin fuga; el puente es transitorio.
- Aceptable con una nota.

### S168-08 · Baja · Pruebas: lo que prueban y lo que no [V]

**Lo que prueban bien:**
- `CuentaFueraDeAlcanceTests` comprueba las seis acciones contra una cuenta sin restricción (de la misma y de ninguna sucursal), de otra sucursal y de otra empresa. Además compara la fila completa antes y después (descripción, nivel, hash, «Debe cambiar», habilitación, bloqueo, revocación y sello), así que un rechazo tardío que ya escribió se detectaría.
- Cubre el caso permitido (también con mayúsculas y espacios distintos), el ADMIN sin restricción, el SUPER con bandera y el solicitante inexistente.
- `CuentaFueraDeAlcanceHttpTests` y `RestriccionSoloSuperHttpTests` pasan por el inicio de sesión real, con lo que fijan que la API pasa `sesion.Usuario`.
- `SucursalTokenRestringidoTests` cubre R-VIEJO-1 a R-VIEJO-3, D-3, Q-A5 y el orden de causas.
- `AlcanceAlmacenesTests` cubre AL-10 a AL-15, R-01, R-02 (con saldo inicial y código desconocido) y R-04 (conserva lo ajeno, rechaza como inexistente, Vacío no borra).
- `InyeccionAlcanceTests` fija el constructor público.

**Huecos:**
1. No hay prueba de alcance con la cuenta **inhabilitada** ni de `SinRestriccionAsync` con cuenta nula en el diseñador. El código falla cerrado (`AlcanceAlmacenes.cs:101`, `:106`), pero una mutación ahí no la detectaría ninguna prueba nombrada [I].
2. No hay prueba de que un restringido no reciba un SUPER como destino por la vía de alcance; la cubre la regla anterior.
3. Ninguna prueba fija S168-01 a S168-03. Es coherente con que no estén construidos.
4. **Mutaciones:**
   - B declara 10, todas detectadas, en el aviso `B-a-A/2026-10-22-168-m168-2-residual-y-178-sello.md:11`, y 20 en la descripción del PR.
   - El guion está "en la carpeta de trabajo de B", no en el repositorio, así que no puedo confirmar qué se mutó.
   - Por la forma de las pruebas, las mutaciones razonables sí se detectarían:
     - quitar la llamada en cada uno de los tres métodos;
     - invertir `Restringe(cuenta…)`;
     - quitar la comparación de empresa o de sucursal;
     - abrir la falla de `propia is null`;
     - quitar `!dto.EsNuevo`;
     - no pasar `sesion.Usuario` en la API.
   - Una que probablemente **no** se detectaría: invertir el orden de `ExigirCuentaEnAlcanceAsync` y `ExigirRestriccionSinCambiosAsync` en `GuardarAsync:525-526`. Solo cambia el código del 403 en los casos en que fallan las dos, y las acciones de la prueba no cambian la bandera [I].

**Remediación** (0,05 dp): agregar los casos 1 y publicar el guion de mutaciones junto al PR, o en `GPOS-NG-Equipos`.

## 5. Controles bien implementados

**Alcance de almacenes (P-0):**
- La restricción y la sucursal salen de la cuenta en `GPOS_SYSDATA`, de la misma lectura que valida el token, nunca del token ni de un parámetro (`EstadoCuentaSesion.cs:13-14`; `UsuariosService.cs:758-759`).
- El SUPER queda exento por el nivel guardado, con comparación ordinal exacta: un nivel desconocido no exime (`UsuarioAlcance.cs:15`).
- `AlcanceResuelto` tiene constructor `internal` y su `default` es Vacío. Cuenta nula o inhabilitada, o sucursal irresoluble, dan Vacío, nunca Global (`AlcanceAlmacenes.cs:103-116`).
- El patrón `(@global = 1 OR al.SucursalId = @sucursalAlcance)` no da filas con `NULL` (`ConsultasDocInventario.cs:72`, `:83`, `:105`).

**R-01 y R-02:**
- Un almacén ajeno y uno inexistente dan la misma lista vacía.
- La comprobación es por llave y antes de leer (`InventarioService.cs:761-767`).
- `SaldoAntes` también va filtrado.
- Se corrigió la falla abierta anterior: el código desconocido daba todos los almacenes a cualquier usuario.

**R-04:**
- Niveles, existencias y total dentro del alcance.
- La fila ajena recibe exactamente el texto de `IdAsync` para un inexistente («Almacén: el valor X no existe.», `MaestrosService.cs:440` frente a `MaestrosService.Articulos.cs:317-321`).
- Lo ajeno se conserva en el modelo nuevo y en el heredado (`:392`, `PuenteMae.cs:210`).

**Sesión y diseñador:**
- **401 Q-A2:** el restringido no puede usar un token de otra sucursal en ninguna ruta, incluidas las escrituras que toman la sucursal del token y la API de reportes, que pasa por la misma `MotivoInvalidoAsync` (`ValidadorTokenPrincipal.cs:41`).
- **Caché de la cuenta:** `RegistrarCuenta` y `Registrar` llaman a `Olvidar` (`RevocacionSesiones.cs:209`, `:222`, `:226`), así que el cambio de restricción vale desde la petición siguiente en la misma instancia. En otra instancia, a lo sumo 15 s (CS-3, aceptado).
- **Diseñador (Q-A3):** las cuatro operaciones comprueban antes de validar o ejecutar y responden con el mismo código y texto que la API de reportes. La paridad usa la misma regla `UsuarioAlcance.Restringe` (M-168-1 cerrado, `ProveedorContexto.cs:93`).

**Gestión de cuentas (M-168-2):**
- Vive en el servicio, no solo en el endpoint.
- Compara contra el estado **guardado** y la lee dentro de la transacción `Serializable` con la fila bloqueada.
- Falla cerrada con un solicitante indicado sin cuenta.
- Cubre crear, modificar, subir de nivel, restablecer la clave, inhabilitar, desbloquear y cerrar sesiones (`UsuariosService.cs:426-488`, `:521-527`, `:314`, `:710`; las cinco rutas pasan `sesion.Usuario`).
- Los mensajes del 403 solo nombran la sucursal del propio solicitante.

**Otros:**
- **Inyección:** no hay SQL dinámico, concatenación ni `FormattableString` en el código nuevo.

## 6. Remediaciones priorizadas

1. **Decisión del propietario sobre el modelo del ADMIN restringido** (S168-02, opción a o b). Sin ella, S168-01 y S168-03 se resuelven a medias. Esfuerzo: (a) unos 0,4 dp; (b) 0,02 dp.
2. **S168-01:** POS por usuario, lista y política efectiva con la regla de cuentas, más la auditoría de los 403. Unos 0,15 dp. Puede ir en este PR o en uno pequeño apilado.
3. **S168-03:** almacenes permitidos solo para un ADMIN sin restricción, como requisito de entrada de S-16b. Unos 0,05 dp.
4. **S168-08:** pruebas de cuenta inhabilitada o nula en el alcance y en el diseñador, y publicar el guion de mutaciones. 0,05 dp.
5. **Bajas** (S168-04, S168-05, S168-06, S168-07): en total unos 0,15 dp, sin urgencia.

Costo de infraestructura: USD 0; sin paquetes nuevos.

## 7. Recomendación

**Aprobar con condiciones** (recomendación técnica; la orden de unión es del propietario):
- Registrar S168-01 y S168-02 como riesgo residual de ADR-93.
- No presentar al cliente la restricción del ADMIN como control mientras no se cierren.
- S168-03 queda como requisito de S-16b.

## 8. Lo que NO verifiqué

- No compilé ni ejecuté nada: ni las 48 o 25 pruebas que B declara, ni las mutaciones, ni la suite oficial. Tampoco las tres pruebas que B dice que fallan sin el cambio (`ReportesTests` ×2 y `SucursalOrigenTests`).
- El guion y la lista de las 10 (o 20) mutaciones, que no están en el repositorio.
- El contenido real de la cola de correo, es decir, si hoy contiene documentos de varias sucursales (S168-02 [I]).
- La renovación del token y el cambio de empresa en sesión con la restricción (`SucursalSesionRenovada`), salvo por la vía del 401 de `SucursalAjena`.
- El mapeo HTTP de `ReglaNegocioException { EstadoRegla = 403 }` y de `AccesoDenegadoException { CodigoRegla }`; me baso en que las pruebas HTTP lo afirman.
- Las pantallas Web y MAUI (`Usuarios.razor` aún deja mover el interruptor; el servidor responde 403).
- Las rutas de S-16b (R-03, R-05 a R-13), R-14 (T4-06) y las tareas en segundo plano que usen `InventarioService` sin usuario. Con alcance Vacío, esas tareas devolverían listas vacías: es un riesgo funcional, no de seguridad [I].
- El rendimiento de la consulta extra por petición.

### Cierre
- Estado: Aprobado con observaciones (recomendación: Aprobar con condiciones; decisión del propietario, Pendiente de firma)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\revision-seguridad-pr168-e1-adr93-2026-10-22.md`
- Supuestos:
  - Revisión estática de la punta `30ad5c4e`, sin ejecución.
  - El ADMIN tiene todos los privilegios (`RequierePermiso(Sucursales)` lo admite).
  - Antes de DB-7 v1 un usuario puede entrar a cualquier empresa.
- Decisiones candidatas a ADR:
  - precisión de TA-P08 (ADR-93) sobre el modelo del ADMIN restringido ("administrador de su sucursal" con política `AdminSinRestriccion` y lista de excepciones, frente a "orientativa"; alternativa descartada: filtrar servicio por servicio);
  - si la restricción es por código de sucursal o por la pareja empresa y sucursal (S168-05).
- Entregas a otros agentes:
  - B (backend): S168-01, S168-03 (entrada de S-16b), S168-04 y S168-08;
  - propietario vía B: decisión de S168-02 y S168-05;
  - C (qa-automatizado): pruebas de S168-01 a S168-03 cuando se construyan, y la de cuenta inhabilitada o nula;
  - documentador: riesgo residual en `estado.json` de ADR-93.
- Próximo paso recomendado: B lleva al propietario la decisión del modelo del ADMIN restringido (S168-02) y, mientras tanto, une el #168 con el riesgo residual registrado.
