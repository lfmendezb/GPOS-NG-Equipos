# Informe de Seguridad: PR #42, L1b-2 (registro, `UseLicencia` y rutas L-01 a L-09)

**Fecha:** 2026-10-15 · **Auditor:** auditor-seguridad (Opus 5.5) · **Tipo:** revisión de código, solo lectura

**Qué revisé:** el PR #42, rama `a/lic-l1b-2` @ `b24ffe5f`, contra la base `feature/modelo-ng` @ `30b4d5b3` (worktree `GPOS-NG-l1b`). Son 14 archivos, +783 y −78 líneas.

**Contexto:** el coordinador indica que el desarrollador está quitando ahora el interruptor `GPOS:Licencia:Aplicar`, para que `UseLicencia` sea incondicional. Reviso con ese cambio en mente; el código revisado todavía lo tiene.

**Contrato:** blueprint de la licencia v2.8 (§4.1 fila L1b, §5.1, §5.3, C-02, C-09); `[LIC]` 4.3, 4.5 y 5.5; LV-17, LV-18 y SEG-L2-15; mis informes del PR #35 (LB-01 a LB-06).

**Método:** no compilé ni ejecuté pruebas.

---

## 1. Tabla resumen de hallazgos

| ID | Severidad | Título |
|---|---|---|
| L2-01 | **Media** (condición de unión) | `UseLicencia` depende de `GPOS:Licencia:Aplicar`, que está apagado por omisión. Si queda así, la licencia no bloquea nada en producción, y QA-L06 no lo detecta |
| L2-02 | **Media** | El cupo de usuarios se sigue aplicando con la fila editable `UsuariosAutorizados` (por omisión 5), no con `IEstadoLicencia.CupoUsuarios`. LV-17 no está retirado |
| L2-03 | Baja | El 403 que recibe el USER incluye la fecha de vencimiento (LV-18) |
| L2-04 | Baja | El límite de 10 cargas por hora de L-03 depende de `limites.Habilitado` (un interruptor de configuración) |
| L2-05 | Informativa | GET con escritura aceptado (reimpresión); identidad de los dispositivos sin `Claims.Empresa`; la Web todavía llama a la ruta retirada |

No hay hallazgos Críticos ni Altos, con una condición: si L2-01 **no** se corrige antes de unir, pasa a **Alta** (la licencia quedaría desactivada por omisión).

---

## 2. Verificación del foco pedido

| Punto | Resultado | Evidencia |
|---|---|---|
| Registro en DI | `EstadoLicenciaService` (singleton) queda registrado como `IEstadoLicencia`, junto con el recurso de llaves, el protector, el almacén de disco, la huella, la fuente de empresas y el importador. El modo de la licencia sale del modo de RG-14 (Estricto por omisión). `ArrancarAsync` corre antes de servir: en Amplio con una licencia `Produccion`/`Beta`, o en Estricto sin `InstalacionId`, la API no arranca | `Program.cs` |
| Borrado de `EstadoLicenciaHeredado` | **Verificado:** el tipo ya no existe (una prueba comprueba `GetType(...) == null`) | `ClasificacionRutasLicenciaTests.cs:136` |
| Orden de `UseLicencia` | Correcto. Va después de `UseAuthentication`, `UseAuthorization`, el cambio de clave obligatorio, el esquema pendiente, la versión del esquema de la empresa, **el candado de H-11** y la guarda de sitio. Las respuestas de infraestructura (503) tienen prioridad, y la licencia solo responde 403 cuando la operación se habría permitido. Ver L2-01 | `Program.cs:298-317` |
| ¿Se escapa alguna ruta? | Solo las anónimas (`IAllowAnonymous`), las no autenticadas y las que no encuentran endpoint (404), por diseño. Las autenticadas por otro esquema (dispositivos) pasan por la licencia si `UseAuthorization` las autenticó; ver L2-05. Sin marca, `GET`/`HEAD` son `Consulta` y lo demás `Operativa` (falla cerrado) | `ModoLicencia.cs:27-69` |
| LB-04 (empresa destino) | **Cerrado.** En las rutas cuyo patrón contiene `/empresas/{codigo}` se evalúa la empresa de la ruta. El alta (`POST …/admin/empresas`, sin código) solo se permite a `Consulta`/`Esencial` o al SUPER. Sin empresa, solo `Consulta`/`Esencial` | `ModoLicencia.EmpresaDestino` |
| `X-GPOS-Licencia` | **Verificado (LV-18):** ADMIN y SUPER reciben `estado;días`; el USER, `opera|soloConsulta;franja:si|no`, sin días ni fechas. Ver L2-03 sobre el cuerpo del 403 | `ModoLicencia.ValorEncabezado` |
| L-01 | El USER recibe el `EstadoLicenciaUsuarioDto` (CR-10); ADMIN y SUPER, el completo | `LicenciaEndpoints.cs:24-37` |
| L-03 | `Esencial` (es la salida de la solo consulta), solo ADMIN, cuerpo limitado a 128 KB (`LimiteCuerpo`) más la comprobación de `Length` y `LeerConLimiteAsync` (64 KB), sin antifalsificación (JWT) y con 10 cargas por hora por cuenta. **DoS:** cada carga cuesta como mucho 64 KB de JSON estricto y 8 verificaciones ES256, bajo `sp_getapplock`, con 50 rechazos completos al día. Es acotado. **Archivo:** solo se acepta una licencia firmada por GSF para esta instalación y con una `sec` no anterior. Un ADMIN no puede retroceder la licencia ni cargar la de otra instalación. Que la carga de un ADMIN afecte a todas las empresas es SEG-L2-15 (aceptado, con su evento). Ver L2-04 | `LicenciaEndpoints.cs:49-66` |
| L-04 a L-07 | Grupo `/api/super/licencia` con `RequiereSuper`. L-04 no expone el piso de nivel (R-E10: `null`). L-05 limita el rango a 2 años. L-06 entrega un JSON sin secretos y responde 503 sin `InstalacionId` | `LicenciaEndpoints.cs:68-112` |
| L-08 | **Solo el SUPER** (el grupo `RequiereSuper`), porque devuelve el JWS con todas las empresas (SEG-L2-15) | `:114-117` |
| L-09 / retiro de la ruta heredada | `POST /api/super/licencia` responde **410** `LICENCIA_RUTA_RETIRADA` (`Esencial`, igual en solo consulta). `GET` pasa a ser L-04. Ver L2-02 (la fila sigue leyéndose) y L2-05 (la Web todavía llama a la ruta retirada) | `:119-122`; `AdminEndpoints.cs` |
| LB-05 (`GetSinEscrituraTests`) | **Cerrado.** La prueba recorre el IL de los handlers de `MapGet` buscando verbos de escritura, con una lista de excepciones revisadas: la fábrica (`CrearAsync`) y `ReimpresionService.RegistrarAsync` (ver L2-05) | `GetSinEscrituraTests.cs` |
| `TrabajoLicencia` cada 60 s | Registrado como `HostedService`: refresca la instantánea y procesa la carpeta de entrada (20 por hora). Usa el mismo servicio de carga que L-03 | `Program.cs` |

---

## 3. Hallazgos

### L2-01 · Media (condición de unión) · Interruptor `GPOS:Licencia:Aplicar`

`if (config.GetValue<bool>("GPOS:Licencia:Aplicar")) app.UseLicencia();`: apagado por omisión. Con eso, en cualquier instalación la licencia no bloquea nada (no hay primera barrera). Contradice «sin interruptores» (ADR-60, punto 6; `[LIC]` 5.5), y el propio comentario reconoce que QA-L06 no lo detecta porque no revisa `Program.cs`. Según el coordinador se está quitando. **Condición:** antes de unir, `UseLicencia` incondicional y una guarda que lo vigile, por ejemplo una prueba de integración que compruebe que el host real responde 403 a una ruta `Operativa` con la empresa en solo consulta, o una comprobación de texto de `Program.cs` que falle si la llamada va dentro de un `if` o lee la configuración. **Si se uniera tal cual, la severidad sería Alta.**

### L2-02 · Media · El cupo sigue saliendo de `UsuariosAutorizados`

`UsuariosService.GuardarAsync` aplica el límite de usuarios con `AutorizadosAsync()`, que lee la fila editable `Configuracion.UsuariosAutorizados` (5 por omisión, y se crea al arrancar). No usa `IEstadoLicencia.CupoUsuarios`. Con L-09, la fila ya no se escribe por la API, pero:
- el cupo efectivo no es el de la licencia firmada. Si GSF vende 12 usuarios, la instalación se queda en 5; si vende 3, sigue en 5 o en el valor antiguo;
- cualquiera con escritura en `Configuracion` (la identidad de la API, `db_owner`) puede subirlo sin rastro.

El blueprint asigna a L1b el «retiro de `UsuariosAutorizados` (LV-17)» y «`CupoUsuarios` hacia el sello», con una prueba de arquitectura que busca la clave. Si eso queda para otra pieza (SL o L1b-3), conviene registrarlo como condición explícita antes de la versión con licencia. **Remediación (≈ 0,1 dp):** que `GuardarAsync` use `IEstadoLicencia.CupoUsuarios(empresa)`; retirar la lectura y el alta al arrancar de `UsuariosAutorizados`; añadir la prueba de arquitectura de LV-17; y que `GET /api/admin/usuarios/licencia` lea también de la licencia (`UsuariosService.cs:160-172, 218-232, 278-286`).

### L2-03 · Baja · El 403 al USER incluye la fecha de vencimiento

`MensajesLicencia.Bloqueo(SoloConsulta, …, vence)` dice «La suscripción de X venció el dd/MM/yyyy», y `UseLicencia` lo devuelve a cualquier nivel. LV-18 limita lo que ve el USER al estado reducido y a la franja. **Remediación:** para el USER, el mismo texto sin la fecha (`vence = null`), o un mensaje propio.

### L2-04 · Baja · El límite de L-03 depende de `limites.Habilitado`

`UseRateLimiter` solo se registra si `GPOS:Limites` lo habilita, y con él caen el límite de 10 cargas por hora de L-03 y el de los respaldos (LB-06). El costo de cada carga es acotado (ver arriba), así que el impacto es bajo. **Remediación:** que las políticas de seguridad (L-03, respaldos, inicio de sesión) se apliquen siempre, y que la configuración solo ajuste los valores.

### L2-05 · Informativa

- **Reimpresión por GET:** `ReimpresionService.RegistrarAsync` escribe filas de control y bitácora desde un GET. Es aceptable (la API usa JWT en la cabecera, así que no hay CSRF por GET), pero queda pendiente de que el arquitecto decida si pasa a POST.
- **Dispositivos:** si el token de dispositivo no trae `Claims.Empresa`, sus POST quedarían limitados a `Consulta`/`Esencial` (403). Es funcional, no de seguridad; conviene verificarlo con una prueba de los endpoints de dispositivos.
- **La Web** todavía llama a `POST api/super/licencia` (ahora 410) en `LicenciaUsuarios.razor`. Hay que actualizar la pantalla.

---

## 4. Controles bien implementados

- **Primera barrera al final del *pipeline*,** después de autenticación, autorización, candado y sitio, con la clase por marca o por método (falla cerrado) y 403 con su `codigo`.
- **LB-04:** se evalúa la empresa destino, y el alta queda solo para el SUPER.
- **Encabezado reducido para el USER** y su propio DTO en L-01.
- **L-03 acotado** (cuerpo, 64 KB, límite por cuenta, `sp_getapplock`, reglas de aceptación) y **L-08 solo para el SUPER.**
- **Sustituto heredado eliminado** y `GetSinEscrituraTests` por IL.

---

## 5. Recomendación

**PR #42: Aprobado con observaciones, con condiciones.**

1. **Antes de unir:** L2-01 (interruptor quitado y guardado por una prueba). Sin eso, Rechazado.
2. **Antes de la versión con licencia:** L2-02 (LV-17), en este PR o como condición explícita de la pieza que lo cubra.

Es una recomendación técnica: la decisión es del propietario.

### Cierre
- Estado: Aprobado con observaciones (condicionado a L2-01)
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\revision-seguridad-pr42-l1b-2-2026-10-15.md`
- Supuestos: revisé `b24ffe5f`, que todavía tiene el interruptor; no verifiqué los claims del token de dispositivo.
- Decisiones candidatas a ADR: Ninguna.
- Entregas a otros agentes:
  - desarrollador L: L2-01 (y su guarda), L2-02, L2-03 y L2-04;
  - frontend: la pantalla `LicenciaUsuarios.razor` contra L-04 y L-09;
  - arquitecto: la reimpresión por GET.
- Próximo paso recomendado: hacer la lectura de diferencias cuando se quite el interruptor, y decidir dónde se cierra LV-17.
