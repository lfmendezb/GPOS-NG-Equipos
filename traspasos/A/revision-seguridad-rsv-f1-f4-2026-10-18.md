# Revisión de seguridad: RSV-F1 a RSV-F4 (rama `a/rsv-anillo-mantenimiento`)

- **Fecha:** 2026-10-18
- **Revisor:** auditor-seguridad (equipo A), con Opus por escalado (criptografía del anillo, sellos y licencia antes de la primera licencia de pago)
- **Alcance:** `git diff origin/feature/modelo-ng..HEAD` (base `886dde70`, punta `e6e47dbb`), 7 commits: `599c85bd`, `a092c0b6`, `f9401579`, `25157dbb`, `62d5a506`, `363800fa` y `e6e47dbb`.
- **Contrato:** hoja firmada `traspasos/B/2026-10-18-hoja-firma-rsv-anillo-sellos.md` (condiciones 1 a 8 de 3.1, 3.2, 3.3 y 3.4), ADR-79 y la precisión de ADR-58 del 2026-10-18 en `origin/master`, y mi revisión anterior `traspasos/A/revision-seguridad-rs01-rs03-2026-10-18.md`.
- **Veredicto: Aprobado con observaciones.** No hay hallazgos Críticos ni Altos. Recomiendo corregir **RSVB-01** antes de abrir el PR: es barato y afecta a los eventos críticos que firmó el propietario.

## 1. Alcance y superficie revisada

**Superficie:**
- los verbos del técnico `GPOS.Migracion anillo --cambiar-recuperacion`, `--revocar-heredadas` y `--reproteger-sellos` (el nuevo);
- la comprobación de los servicios;
- la lectura en memoria del estado de la licencia en cada petición de la API (`Estado`, `CodigoBloqueo`, `Detalle`, `Permite`, `ExigirOperativa`);
- el refresco de 60 s y el arranque de la API;
- el servicio de licencia de solo lectura de `sellos --legitimar` y de `empresa`.

No hay endpoints nuevos.

**Revisado (código de la rama):**
- `src/GPOS.Core/Infraestructura/Anillo/ReproteccionSellos.cs` (completo);
- `ReproteccionSecretos.cs:97-145`;
- `AnilloDataProtection.cs:64-95`, `:172-235` y `:276-293`;
- `src/GPOS.Core/Sistema/Usuarios/PadronSellos.cs:172-183`, `:337-470`;
- `SellosService.cs:244-268`;
- `src/GPOS.Migracion/Anillo/MantenimientoAnillo.cs` (completo), `EstadoServicios.cs` y `ComandosAnillo.cs:38-66`;
- `src/GPOS.Migracion/Sellos/ComandoSellos.cs:170-200` y `:288-300`;
- `src/GPOS.Core/Sistema/Licencia/EstadoLicenciaService.cs:120-141`, `:180-440`, `:470-700` y `:815-850`;
- `ImportadorCarpetaEntrada.cs:60-85`;
- `ComandosLicencia.cs:196-206`;
- `src/GPOS.Api/Program.cs:265-280` y `:420-448`;
- las pruebas nuevas o modificadas de las cinco clases.

**Contexto leído:**
- `EsquemaRestauracionSistema.cs:60-140` (vista `dbo.EstadoRestauracionSistema` y `ReconciliarRestauracionSistema`) y `:225-227`;
- `CandadoRestauracionSistema.cs`;
- `RelojProtegido.cs:73-140`;
- `EstadosLicencia.cs:112-129`;
- `MotorEstados.cs:30`, `:96-97` y `:215-226`;
- `SqlSoloEnLugaresPermitidosTests.cs` (CA-0.8);
- `instalador/Demo/scripts/Iniciar-Demo.ps1:65`.

**Ejecutado:**
- `dotnet build tests/GPOS.Tests`: 0 errores, 0 advertencias;
- `dotnet test --no-build` con `(FullyQualifiedName~MantenimientoAnillo|~Licencia|~SellosPadronIlegible|~SellosResellado)&Transicion!=Ola5&Transicion!=Defecto`: **580 correctas, 0 con error, 1 omitida** (la de siempre, `ReglaSecuenciaTests`), en 4 min 10 s;
- `testhost.exe` borrado después de compilar y después de probar;
- antes de compilar comprobé que no había otros procesos `dotnet` ni `testhost` en la PC A.

**Sin verificar:** la suite completa (no la corrí) y el comportamiento con un servicio de Windows real llamado `GPOS.Api`, que todavía no existe (ver RSVB-04).

**Estado de la rama:** no la modifiqué. El árbol queda limpio en `e6e47dbb`.

## 2. Tabla resumen

| ID | Severidad | Título | ¿Bloquea el PR? |
|---|---|---|---|
| RSVB-01 | Media | EventId 4730, 4731 y 4732 repetidos: chocan con `PurgaBitacoraSeguridad`, `CambioClave` y `SegundoFactor` de la propia base | No (Media), pero **recomiendo corregirlo antes de abrir el PR** |
| RSVB-02 | Media | El «aviso al SUPER» de la precisión de ADR-58 (puntos 2 y 3) solo existe como texto en el registro del servidor, que controla el adversario de la licencia | No; decisión de B antes de la primera licencia de pago |
| RSVB-03 | Media (ya existía; valoración del supuesto 3 de la hoja) | CR-01 no detecta una copia anterior de `GPOS_SYSDATA` con el mismo fork ni un respaldo anterior a la fila `RestauracionSistema`: el residual que informa el desarrollador se confirma | No; para el Arquitecto Maestro antes de la primera licencia de pago |
| RSVB-04 | Baja | RSV-F2 no tiene efecto hoy: `GPOS.Api` no es un servicio de Windows y su nombre es un literal que ningún instalador comparte | No |
| RSVB-05 | Baja | Diagnósticos engañosos (sin efecto en la seguridad): `catch (InvalidOperationException)` amplio en el ensayo, y un sello demasiado largo contado como «no abre» | No |
| RSVB-06 | Baja | Faltan pruebas: huella que no coincidía, disco no escrito tras confirmar y arranque con el refresco fallando | No |

## 3. Checklist OWASP (aplicado al cambio)

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | **Correcto.** Los verbos son del técnico, con acta y motivo (`Validar`). La comprobación de los servicios va antes de leer o cambiar nada (`MantenimientoAnillo.cs:161`, `:203` y `:247`). El 403 de «solo consulta» se aplica en todas las rutas que leen el estado (sección 4, punto 5). |
| A02 Criptografía | **Correcto.** El ensayo solo abre (punto 1). Se abre con las llaves en transición y se protege con la predeterminada nueva. Nada se revoca con un impedimento (punto 2). La reprotección no legitima ningún sello (punto 3). |
| A03 Inyección | **No aplica.** Una sola sentencia nueva, sin parámetros (`ComandosLicencia.cs:204-205`). El resto es LINQ. |
| A04 Diseño inseguro | **RSVB-03:** la defensa de la copia del disco depende de CR-01, que no ve todas las vueltas atrás de la base. |
| A05 Configuración | **RSVB-04:** el control depende del nombre del servicio. |
| A06 Componentes vulnerables | Una dependencia nueva: `System.ServiceProcess.ServiceController` 10.0.12, la misma versión que ya usan otros proyectos de la solución. No conozco vulnerabilidades publicadas para ella (no corrí un escáner). |
| A07 Autenticación | Indirecto: los sellos de habilitación de ADR-83. **Correcto.** |
| A08 Integridad | **Correcto** en la reprotección conjunta y en el orden transacción → confirmación → disco → 2.ª comprobación → revocación. Ver RSVB-03. |
| A09 Registro y monitoreo | **RSVB-01** (EventId repetidos) y **RSVB-02** (el aviso no llega al SUPER). Los mensajes no llevan secretos, valores protegidos, códigos de cuenta ni rutas (sección 4, punto 8). |
| A10 SSRF | **No aplica.** |

**Aislamiento entre tenants:** no aplica. `GPOS_SYSDATA`, el anillo y la carpeta de la licencia son de la instalación. La fuente de sellos recorre todas las cuentas de la instalación, que es lo que corresponde.

## 4. Respuesta a los puntos pedidos

### Punto 1 · Ensayo previo de `--cambiar-recuperacion` con `ProveedorSoloLectura`: verificado, solo abre

- `ExigirSellosReprotegiblesAsync` (`MantenimientoAnillo.cs:298-330`):
  - fija la recuperación anterior en el estado (`:309`), igual que `ComprobacionAnillo.VerificarAncla` (`ComprobacionAnillo.cs:95-111`);
  - ejecuta `ReproteccionSellos.ReprotegerAsync(..., simular: true)` con `AnilloDataProtection.ProveedorSoloLectura` (`:312`);
  - en el `finally` lo deja en `SinComprobar` sin huella (`:324`).
- El proveedor tiene `DisableAutomaticKeyGeneration()` y un cifrador que siempre lanza (`AnilloDataProtection.cs:280-292`), así que **no puede crear llaves**.
- En el modo de simulación, `ReproteccionSellos` hace solo esto:
  - `Unprotect` de cada sello (`ReproteccionSellos.cs:126-128`: con `simular`, el «nuevo» es el mismo valor);
  - `Abre` de las filas del sellado (`:148`, solo `Unprotect`);
  - la lectura del padrón.

  No llama a `Protect`. La transacción se deshace al salir (`:163`). `TomarAsync` no escribe el disco (`PadronSellos.cs:337-347`) y `ConfirmarDisco` no se alcanza.
- El estado vuelve a fijarse bien después: `FijarAnclaAsync` lo pone en `Anclada` con la huella nueva (`MantenimientoAnillo.cs:426`) antes de crear la llave. El `SinComprobar` intermedio no deja ninguna ventana con escritura.
- La prueba `RSV03_un_sello_que_no_abre_aborta_todo_sin_cambiar_nada` afirma que la carpeta del anillo queda sin cambios (`SinCambiosEnElAnilloAsync`), también en `--cambiar-recuperacion`.
- **Conclusión:** cumple. La única observación es de diagnóstico: el `catch (InvalidOperationException)` de `:317` es amplio (RSVB-05).

### Punto 2 · Impedimentos y orden de los pasos: verificado

**Alcance de los impedimentos** (`ReproteccionSellos.cs:100-163`). Cualquiera de estos hace que no se escriba nada, porque la transacción se deshace:
- un padrón (fila o archivo) que existe y no verifica;
- un archivo `padron` ilegible;
- un sello sin encabezado;
- un sello que no abre o que queda demasiado largo;
- una fila del sellado que no abre.

**Antes del ancla.** El ensayo con los mismos impedimentos impide cambiar el ancla (`MantenimientoAnillo.cs:217` antes de `:221`). En `--revocar-heredadas` impide revocar (`:166`).

**Orden** (`ReproteccionSellos.cs:165-178`):
1. `SaveChanges` de sellos y filas, y `cambio.GuardarAsync` del padrón, dentro de la transacción serializable que tomó el padrón con `UPDLOCK, HOLDLOCK` (`:103-104`; `TomarAsync` exige la transacción, `PadronSellos.cs:339-340`);
2. `Commit`;
3. `ConfirmarDisco`, con reemplazo atómico (`PadronSellos.cs:449-470`);
4. la 2.ª comprobación (`MantenimientoAnillo.cs:186` y `:228`), que relee también el archivo `padron`;
5. `RevokeKey` (`:187` y `:230`).

**Si el disco no se escribe tras confirmar.** `EscribirDisco` atrapa la E/S y devuelve `false`, sin lanzar (`PadronSellos.cs:466-470`). El archivo sigue con la llave anterior, así que la 2.ª comprobación lo encuentra y no se revoca nada. Según el verbo:
- **`--revocar-heredadas`:** «No se revocó nada». Se puede repetir, porque las heredadas siguen admitidas.
- **`--reproteger-sellos`:** no revoca. La base tiene la versión siguiente y la API reescribe el disco en su próxima lectura (`PadronSellos.cs:310-322`, SL-01).
- **`--cambiar-recuperacion`:** el ancla ya cambió y el mensaje es `TrasCambiarElAncla`. Es el residual aceptado de RSV-01 (transición solo en memoria). En este caso concreto no se pierde nada: la base ya tiene el padrón con la llave nueva y el disco se rehace desde ella. Lo único que no se puede repetir es la revocación de las llaves anteriores, que el decorador ya deja de usar al reiniciar.

**Cobertura previa.** La comprobación previa de escritura de RSV-11 (`MantenimientoAnillo.cs:385-401`) cubre la carpeta donde vive `padron`, así que la probabilidad de esta rama es baja. Falta una prueba de `DiscoEscrito = false` (RSVB-06).

**Una nota correcta.** En `--cambiar-recuperacion`, la reprotección general (`ReproteccionSecretosSistema.ReprotegerAsync`) confirma antes que la de los sellos. Si la segunda fallara después del ancla, quedaría el estado de RSV-01. El ensayo previo la cubre, salvo una divergencia entre el ensayo y la ejecución real, que no encontré.

### Punto 3 · `HuellaSello` solo se recalcula si coincidía: no legitima nada (verificado)

- La entrada del padrón se reemplaza solo si existe para esa clave **y** su huella es la del sello anterior (`ReproteccionSellos.cs:154-159`).
- Se conserva el `Nivel` de la entrada: no se puede elevar.
- Un sello manipulado puede ser:
  - uno copiado de otra cuenta, cuya huella es la de la otra cuenta;
  - uno antiguo restaurado;
  - uno sin entrada en el padrón.

  Si abre, se reprotege con bytes nuevos, pero su entrada no cambia, así que sigue sin coincidir. Si no abre, es un impedimento y se aborta todo.
- Para que la reprotección «legitime» algo habría que escribir el padrón, que lleva MAC y la versión siguiente, y eso está fuera del alcance de quien solo puede escribir en `dbo.Usuarios`.
- La consecuencia es solo de disponibilidad (un `UPDATE` de basura bloquea el verbo), ya aceptada en RSV-06.
- **Sin prueba:** que una entrada que no coincidía siga sin coincidir después de reproteger (RSVB-06).

### Punto 4 · RSV-F2: falla cerrado si no se puede consultar (verificado); no hay forma de saltarlo desde la línea de órdenes

- `GetServices()` o `Status` con `InvalidOperationException` o `Win32Exception` dan `Desconocido` (`EstadoServicios.cs:45-60`). `Desconocido` niega el verbo (`MantenimientoAnillo.cs:266-287`, `ExigirServiciosDetenidos`, en `:281-282` y `:285`). Cualquier otra excepción sale y aborta el verbo. Cualquier estado distinto de `Stopped` también niega.
- `ComandosAnillo.cs:38-39` construye `MantenimientoAnillo` sin el parámetro `servicios`, así que siempre usa `EstadoServiciosWindows`. No hay ninguna opción ni variable de entorno que lo desactive; la sustitución solo existe en las pruebas.
- **Hoy el control no tiene efecto:** `GPOS.Api` no se registra como servicio de Windows (no hay `AddWindowsService` en `src/GPOS.Api`) y el DEMO la arranca como proceso oculto (`Iniciar-Demo.ps1:65`). En todas las instalaciones actuales el verbo solo informa, como permite la hoja. Ver RSVB-04.

### Punto 5 · RSV-F3: reevaluación, racha en memoria y «solo consulta»

**Reloj.** `Ahora()` usa la hora protegida (`EstadoLicenciaService.cs:393` sobre `RelojProtegido.cs:133-139`): el máximo entre el reloj del sistema, el ancla más el contador monótono y el piso. No retrocede y se calcula en memoria, así que llamarla en cada petición no cuesta nada.

**Reevaluación.** `Actual()` (`:289-295`) se usa en `Instantanea`, `Detalle`, `Estado` y `CodigoBloqueo` (y por lo tanto en `Permite` y `ExigirOperativa`).
- Con 15 min o más de antigüedad, o con el plazo cumplido, recalcula con `MotorEstados` sobre la entrada del último refresco correcto (`:313-348`), bajo su propio bloqueo.
- Después deja `CalculadaUtc = ahora`, así que no vuelve a recalcular en cada petición.
- El trabajo de 60 s también reevalúa tras cada fallo (`ImportadorCarpetaEntrada.cs:82`).
- Toda instantánea publicada lleva `Entrada`, salvo `Vacia`, en la que no opera ninguna empresa.
- `Modulo` (`:258-268`) lee `_instantanea` directamente, pero ya recalculaba con la hora actual. Solo lo usa una ruta de presentación (`LicenciaEndpoints.cs:148`) y no autoriza operaciones.

**«Solo consulta» (`:351-355`).**
- Pasan a `SoloConsulta` con `MotivoGracia.Ilegible` solo las empresas que operan.
- `Opera` se calcula a partir del estado (`EstadosLicencia.cs:117`), así que `CodigoBloqueo` da `LICENCIA_ILEGIBLE` (`MotorEstados.cs:220-223`, `CodigosLicencia.cs:25`).
- Las demás conservan su estado y su 403.
- `ReglaClaseLicencia.Permite` recibe `SoloConsulta`, así que se siguen permitiendo las lecturas.

**Racha en memoria y reinicio: el arranque falla cerrado (verificado).**
- `ArrancarAsync` llama a `RefrescarAsync(forzar: true)` (`:422`). Si el refresco falla, `RegistrarFalloRefresco` no hace nada sin instantánea (`:365-366`) y la excepción sale.
- `Program.cs:427` la espera **sin `try`**, así que el proceso termina.
- Un reinicio solo «borra» la racha si el refresco del arranque sale bien. Un refresco correcto evalúa con la base real y la hora protegida, así que no oculta nada.
- **La racha en memoria no abre ninguna vía.** Lo más que gana quien alterna bloquear y reiniciar es retrasar hasta el plazo de 72 h (o `graciaDias`) la detección de algo que solo ve el refresco, por ejemplo un RNC cambiado, y el reinicio lo detecta. Ese es el plazo firmado.
- Una `OperationCanceledException` no abre la racha (`:577`), pero una instantánea vieja sin fallo registrado la abre al leerla (`:321`), así que no hay salida por ahí.
- **Sin prueba:** el arranque con el refresco fallando (RSVB-06).

### Punto 6 · RSV-F4 y el supuesto 3 de la hoja sobre CR-01: el residual se confirma (RSVB-03)

- La vista `dbo.EstadoRestauracionSistema` da `Restaurada = 1` en tres casos (`EsquemaRestauracionSistema.cs:71-77`):
  - sin fila;
  - con el fork nulo;
  - con el fork distinto del registrado.
- Un `RESTORE` cambia el fork, así que se detecta.
- **No cambian el fork:**
  - una copia por detach/attach o de los archivos `.mdf`/`.ldf` con el servicio detenido;
  - una instantánea de la máquina virtual.

  El propio esquema lo reconoce en `EsquemaRestauracionSistema.cs:225-227` («una copia por detach/attach o una instantánea revertida conservan el fork») y `:246-247` (PC-10).
- **Respaldo anterior a la fila.** La vista lo marca como restaurado, pero `ReconciliarRestauracionSistema` lo trata como instalación nueva: inserta la fila con el fork actual y no pone el candado (`:118-122`).
  - En el arranque, la licencia (`Program.cs:427`) corre antes que la vigilancia (`:438`), así que el primer refresco ve el candado y no reescribe.
  - Pero la vigilancia crea la fila y el refresco siguiente, 60 s después, ya no lo ve.
- **El supuesto 3 es cierto solo para `RESTORE`.** El candado CR-01 sí impide reescribir tras un `RESTORE` (pruebas `RsvF4_con_el_candado_CR01_activo...` y `RsvF4_con_la_vista_de_CR01_en_restaurada...`), y la lectura falla cerrada (`EstadoLicenciaService.cs:680-691`; vista sin respuesta → `true`, `ComandosLicencia.cs:205`).
- **RSV-F4 no empeora nada.** Antes de este PR, `GuardarMarcasAsync` reescribía el archivo `estado` siempre que escribía la fila. RSV-F4 la condiciona (`:606` y `:836`) y agrega el evento 4723. Es una mejora neta. La valoración del residual va en RSVB-03.

### Punto 7 · RSV-08 (4734) y `EscribirMarcas = false`

**RSV-08: correcto.**
- `LeerDiscoAlArrancarAsync` (`EstadoLicenciaService.cs:531-544`) convierte `IOException` y `UnauthorizedAccessException` en `LicenciaArranqueException` con el código `LICENCIA_CARPETA_ILEGIBLE`, un mensaje sin ruta y la causa adjunta.
- La ruta solo llega al registro del servidor, lo que ya acepté en RSV-08.
- Envuelve `vigente`, `Procesados` y el sello `.acept`.
- Sigue fallando cerrado (INV-7).
- El 4734 no choca con nada. El problema de numeración está en sus vecinos (RSVB-01).

**`EscribirMarcas = false`: correcto.**
- Es la única instancia fuera de la API (`ComandoSellos.cs:291-294`), y la usan `sellos --legitimar` (`:125` y `:135`) y `empresa` (`ComandoEmpresa.cs:37`).
- Con `false`, ni `GuardarMarcasAsync` (`:627`) ni `RehacerEstadoDiscoAsync` (`:660`) escriben. La herramienta sin empresas ya no puede borrar los topes por empresa (NV-01). La prueba `Un_servicio_sin_empresas_de_solo_lectura_no_borra_los_topes_de_Licencia_Gracias` lo cubre.
- *Fuera del alcance, ya existía:* `ArrancarAsync` en la herramienta sigue registrando los retiros de los binarios y puede reinsertar desde el disco. Son escrituras legítimas e idempotentes, pero la herramienta no es de «solo lectura» en sentido estricto.

### Punto 8 · Mensajes, CA-0.8 y ADR-50

**Mensajes: correctos.** Ninguno lleva valores protegidos, códigos de cuenta, cadenas de conexión ni rutas completas. En concreto:
- recuentos y nombres de fila o de archivo (`ReproteccionSellos.cs:107-150`);
- nombres de servicio (`MantenimientoAnillo.cs:266-287`);
- acta, motivo, recuentos y versión en el evento 4724 (`EventoSellos`);
- solo el número del error de SQL Server (`DescripcionSql`);
- solo el tipo del error en el 4731 (`:370-375`);
- solo el nombre del archivo en el 4723;
- solo el tipo de la excepción en `PADRON_DISCO_ILEGIBLE` (`ComandoSellos.cs:176-177`);
- un sellado inicial sin ruta (`SellosService.cs:394`).

La prueba `RSV03_un_sello_que_no_abre...` afirma que el código de la cuenta no aparece.

**CA-0.8: cumple.** La única SQL nueva está en `src/GPOS.Core/Infraestructura/Motor/ComandosLicencia.cs:203-205`, un lugar permitido (`SqlSoloEnLugaresPermitidosTests.cs:6-8`).

**ADR-50: no aplica.** La consulta va a `GPOS_SYSDATA` y no tiene parámetros. Ningún otro cambio toca las bases de empresa.

## 5. Hallazgos

### RSVB-01 (Media) — EventId repetidos en la propia rama: 4730, 4731 y 4732

**Riesgo (verificado con `git grep` en HEAD y en todas las ramas remotas tras `git fetch`).** RSV-F3 reutiliza tres EventId que ya usa la base `origin/feature/modelo-ng`:

| EventId | Ya existente | Nuevo de esta rama |
|---|---|---|
| 4730 | `PurgaBitacoraSeguridad` (`src/GPOS.Api/Servicios/TrabajoPurgaBitacoraSeguridad.cs:14`) | `LicenciaReevaluada` (`EstadoLicenciaService.cs:134`) |
| 4731 | `CambioClave` (`src/GPOS.Api/Endpoints/AuthEndpoints.cs:193`) | `LicenciaRefrescoFallido` (`:136`) |
| 4732 | `SegundoFactor` (`src/GPOS.Api/Endpoints/AuthEndpoints.SegundoFactor.cs:255`) | `LicenciaSoloConsultaSinRefresco` (`:139`) |

**Por qué importa:**
- La precisión de ADR-58 exige un evento crítico para el paso a solo consulta y aviso desde el primer fallo.
- En el Visor de eventos y en cualquier regla de alerta de devops el filtro es por EventId, y aquí el ID crítico comparte número con eventos frecuentes del inicio de sesión y del segundo factor.
- Una regla que alerte por 4732 alertaría por cada uso del segundo factor, y se acabaría silenciando junto con el evento de la licencia. Una que lo excluya ocultaría el de la licencia.

**Ya existía:** 4718 se repite entre `AnilloInactivo` (`AnilloDataProtection.cs:36`) y `FilaLicenciaInvalida` (`EstadoLicenciaService.cs:120`).

**Remediación (≈0,1-0,15 dp; recomendada antes de abrir el PR):**
1. Mover los cuatro de RSV-F3 a 4725-4728, libres en todas las ramas remotas: `LicenciaReevaluada`, `LicenciaRefrescoFallido`, `LicenciaSoloConsultaSinRefresco` y `LicenciaRefrescoRestablecido`. El 4734 puede quedarse o pasar a 4729.
2. Una prueba de arquitectura que recorra por reflexión los `static readonly EventId` de los ensamblados `GPOS.*` y exija que sean únicos. Detectaría también el 4718 heredado, que se corrige aparte o queda en la lista de excepciones, a decidir por A.

**Alternativa descartada:** dejar los ID y diferenciar por el nombre del evento. El Visor de eventos y los recolectores habituales filtran por número, no por nombre.

### RSVB-02 (Media) — El «aviso al SUPER» solo existe en el registro del servidor

**Riesgo.** La precisión de ADR-58 pide:
- «aviso al SUPER desde el primer fallo» (punto 2);
- un «aviso diario al SUPER» por la copia ausente (punto 3).

En el código, el aviso es solo la frase «Aviso al SUPER» dentro de eventos críticos del registro (`EstadoLicenciaService.cs:343`, `:374` y `:655`). Ni `SinRefrescoDesdeUtc` ni la ausencia de la copia del disco llegan a ningún DTO, endpoint ni pantalla del SUPER: busqué en `src` y solo aparecen dentro del servicio.

Hay dos efectos:
- **Frente al adversario de la licencia (el administrador del servidor del cliente),** el aviso de RSV-F4 no se ve, porque ese registro lo controla él. El tope de RSV-F3 sí funciona sin aviso.
- **En el caso legítimo** (permisos mal puestos), el SUPER no se entera hasta el paso a solo consulta.

La misma convención ya existe para `EntornoLecturaFallida` (`:924`), así que puede ser una forma aceptada (*inferido*; no encontré una decisión escrita que diga que «aviso al SUPER» significa «evento en el registro»).

**Remediación (para que B decida antes de la primera licencia de pago):**
- **(a), recomendada (≈0,2-0,3 dp):** agregar al estado de la licencia que consulta el SUPER, por ejemplo en `LicenciaEndpoints` o en el encabezado del SUPER, dos datos sin rutas:
  - `SinRefrescoDesdeUtc`, con la hora límite;
  - «copia del disco ausente» (4723).
- **(b), sin costo:** que B deje escrito que en la entrega 1 «aviso al SUPER» es el evento crítico del registro, como en `EntornoLecturaFallida`, y lo registre como riesgo aceptado hasta el agente de actualización.

### RSVB-03 (Media; ya existía; valoración del supuesto 3) — Una copia anterior de `GPOS_SYSDATA` con el mismo fork no activa CR-01

**Riesgo.** Confirmo el residual que informa el desarrollador (punto 6):
- La vista no detecta:
  - una copia anterior de los archivos de `GPOS_SYSDATA` adjuntada (detach/attach o archivos copiados con el servicio detenido);
  - una instantánea de la máquina virtual.
- Un respaldo anterior a la fila `RestauracionSistema` lo «resuelve» el reconciliador como instalación nueva.

En cualquiera de esos casos, si además falta el archivo `estado`, RSV-F4 lo reescribe desde la fila vieja y la deja legitimada.

**Vía de abuso (*inferida, no ensayada*):**
1. Copiar la instalación a un segundo servidor. La huella cambia y empieza la gracia de entorno.
2. Antes de que la gracia termine, volver a adjuntar la copia de `GPOS_SYSDATA` anterior a la detección y borrar `estado`.
3. La marca de la primera detección desaparece y la gracia vuelve a empezar.

Repetido, permitiría operar la copia sin pagar a costa de perder los cambios de `GPOS_SYSDATA`, que son pocos. Las bases de empresa no se tocan.

**Lo que no cambia este PR:**
- **No es una exposición nueva:** antes de este PR la reescritura era incondicional (punto 6). RSV-F4 la mejora.
- **Contra una instantánea de toda la máquina no hay defensa local posible:** el disco vuelve atrás junto con la base.

**Remediación (para el Arquitecto Maestro, antes de la primera licencia de pago; no bloquea el PR):**
1. **Corregir el supuesto 3 por escrito.** CR-01 cubre `RESTORE`, pero no las copias con el mismo fork ni un respaldo anterior a la fila. Registrar el resto como riesgo aceptado, con la misma forma que A-1 a A-3, o mitigarlo.
2. **Mitigación barata (≈0,2-0,3 dp + 2 pruebas).** Cuando coinciden la fila presente, el archivo `estado` ausente y la huella distinta de la `UltimaHuella` guardada, no abrir una gracia de entorno nueva desde «ahora». En su lugar, tomar como inicio la `UltimaVerificacionUtc` de la fila, o tratar la fuente como inválida **solo en esa combinación**.
   - Es la variante (b) de la hoja acotada al caso de abuso: no castiga una falla del disco aislada, que era la objeción del propietario.
3. **De fondo:** la hora confiable y la renovación por el agente de actualización (ADR-58) son la defensa real frente a un administrador que vuelve la base atrás en un solo servidor. Conviene que el registro del riesgo diga que se revisa cuando lleguen.
4. **Nota para el procedimiento de CR-01.** Cuando el SUPER libera el candado, el refresco siguiente reescribe el archivo `estado` que faltaba con las marcas de la base restaurada. El SUPER es de la plataforma y la decisión le corresponde, pero el texto de la liberación debería decirlo.

### RSVB-04 (Baja) — RSV-F2 no tiene efecto hoy y depende de un nombre que nadie comparte

**Riesgo.**
- `GPOS.Api` no se registra como servicio de Windows: no hay `AddWindowsService` en `src/GPOS.Api`.
- El DEMO la arranca como proceso oculto (`instalador/Demo/scripts/Iniciar-Demo.ps1:65`).
- En toda instalación actual el verbo dice «no está instalado» y sigue. Es conforme a la hoja («si no está instalado, solo informa»), pero el control no actúa en ninguna.
- `"GPOS.Api"` es un literal (`MantenimientoAnillo.cs:259`). En cambio, `GPOS.Reportes` sí sale de la constante `ProtocoloIntrospeccion.ServicioReportes` (`src/GPOS.Comun/Introspeccion/ProtocoloIntrospeccion.cs:24`). Si el instalador futuro registra la API con otro nombre, el verbo la tomará por «no instalada» y seguirá, en silencio.
- El supuesto 5 de la hoja (sellado antes de migrar desde DPAPI) apunta justamente al DEMO, donde la API es un proceso.

**Remediación (≈0,1 dp):**
1. Una constante compartida para el nombre del servicio de la API, que use su futuro `AddWindowsService` y este verbo, más una prueba que lo ate.
2. Cuando el servicio no esté instalado, buscar además procesos `GPOS.Api` y `GPOS.Reportes.Api` (`Process.GetProcessesByName`) y negarse si hay alguno en marcha.

**Entrega a devops:** el instalador de la API debe usar ese nombre exacto.

### RSVB-05 (Baja) — Diagnósticos engañosos (fallan cerrados)

1. **`catch (InvalidOperationException)` amplio** (`MantenimientoAnillo.cs:317`). Envuelve el ensayo entero, incluidas las operaciones de EF, que también lanzan `InvalidOperationException` (por ejemplo, la estrategia de reintento o una conexión cerrada). En ese caso el técnico lee «el anillo no tiene una llave vigente de la recuperación anclada», cuando el problema es la base.
   **Remediación:** acotar el `catch` a la creación del protector y al primer `Unprotect`, o distinguir el mensaje del anillo de Data Protection.
2. **Un sello reprotegido que pasa de `LargoMaximo`** se cuenta en `noAbren` (`ReproteccionSellos.cs:129-131`) y se informa como «no abren con el anillo».
   **Remediación:** contarlo aparte, con «excede el largo de la columna».

Costo total: ≈0,05 dp.

### RSVB-06 (Baja) — Pruebas que faltan

1. **Punto 3:** una cuenta cuya entrada del padrón no coincidía sigue sin coincidir después de `--reproteger-sellos`, y las demás siguen verificando.
2. **Punto 2:** `ConfirmarDisco` que devuelve `false` (el archivo `padron` no se puede reemplazar después de confirmar). En `--revocar-heredadas` no se revoca y el mensaje lo dice; en `--reproteger-sellos` queda el aviso.
3. **Punto 5:** `ArrancarAsync` con el refresco fallando lanza la excepción. Esto fija por prueba que el reinicio no reinicia la racha sin un refresco correcto.

Costo: ≈0,2 dp.

## 6. Controles bien implementados

**Condiciones de la hoja.** Se cumplen las ocho de 3.1:
1. API detenida (con la salvedad de RSVB-04).
2. Transacción serializable con `UPDLOCK, HOLDLOCK`.
3. `Unprotect` con las llaves en transición y `Protect` con la predeterminada.
4. Huella y versión siguiente (`CambioPadron.Reproteger`, `PadronSellos.cs:179-183`).
5. Disco después de confirmar.
6. Aborto total.
7. `SelloInicial` y `ReselladoPendiente`.
8. La prueba `RSV07_caso1...`.

También se cumplen 3.2 (alcance de los tres verbos; `--anclar` fuera), 3.3 (15 min y máx(`graciaDias`, 72 h): `PlazoSinRefresco` sobre `MotorEstados.DuracionGraciaEspecial`, `MotorEstados.cs:96-97`) y 3.4 (4723 y la reescritura condicionada).

**Otros controles:**
- **Fuente de sellos (ADR-79, punto 4):** `IFuenteSellos` aísla el recorrido. Las comprobaciones de RS-01 (a) y la reprotección usan la misma fuente (`MantenimientoAnillo.cs:228`), así que DB7-05 solo tendrá que cambiar la fuente.
- **Red de seguridad antes y después (ADR-79, punto 3):** la 2.ª comprobación relee la base **y** el archivo `padron`.
- **Candado CR-01 doble y sin caché:** el singleton de la API falla cerrado hasta su primera lectura. Además se lee la vista directamente, para no depender de la vuelta de 15 s, y un error de lectura cuenta como candado activo.
- **RSV-06, RSV-11 y RSV-12 cerrados:**
  - los sellos sin encabezado se cuentan aparte y con su remedio;
  - la escritura se comprueba antes de cambiar el ancla, y las `DbUpdateException` y `SqlException` pasan a `Fallos` con el número del error;
  - `File.Exists` ya no se usa sobre `padron` en el sellado inicial ni en `verificar`.
- **RSV-08 cerrado,** con un código y un evento propios y sin cambiar el comportamiento de falla cerrada.
- **La reevaluación no relee la base ni el disco:** un refresco detenido en la base no impide que el tiempo avance para las rutas, porque la reevaluación lleva su propio bloqueo.

## 7. Remediaciones priorizadas

**Antes de abrir el PR (recomendado):**
1. **RSVB-01:** EventId a 4725-4728 y la prueba de unicidad (≈0,1-0,15 dp).

**En el mismo PR, si cabe (no bloquea):**
2. RSVB-05 y RSVB-06 (≈0,25 dp).
3. RSVB-04, la constante compartida y la búsqueda de procesos (≈0,1 dp).

**Antes de la primera licencia de pago (decisión de B o del Maestro):**
4. **RSVB-02:** el aviso visible para el SUPER, o la constancia escrita de que el evento del registro basta.
5. **RSVB-03:** corregir el supuesto 3, más el riesgo aceptado o la mitigación de la gracia de entorno.

**Qué bloquea el PR:** formalmente nada, porque no hay Críticos ni Altos. Recomiendo no abrirlo sin RSVB-01, por el mismo criterio que apliqué con RSV-09: es Media y es una regresión que introduce esta rama.

## 8. Recomendación

**Aprobado con observaciones** (recomendación técnica; la decisión es del propietario). Si se une RSVB-01, RSV-F1 a RSV-F4, RSV-08, RSV-11 y RSV-12 quedan cerrados en lo que pidieron la hoja y ADR-79.

Con este PR unido se levanta la restricción operativa de RS-01 (a) («no cambiar la recuperación en una instalación sellada ni con la API en marcha») para las instalaciones con la API como servicio. Mientras la API corra como proceso de consola (DEMO y Debug), el procedimiento de devops tiene que seguir exigiendo detenerla a mano (RSVB-04).

## Supuestos

- `ICandadoRestauracionSistema` y la vista se leen con la misma identidad de la API que ya usa la vigilancia de CR-01. No verifiqué los permisos en una instalación real: si faltaran, se falla cerrado y el archivo nunca se reescribe.
- La vía de abuso de RSVB-03 es inferida a partir del código de `Entorno` y de la vista. No la ensayé.
- Que la convención de «aviso al SUPER = evento en el registro» esté o no aceptada en otro documento (RSVB-02) no lo pude confirmar.

## Decisiones candidatas a ADR

- **Precisión de ADR-58 (RSVB-03):** gracia de entorno con la copia del disco ausente.
  - Opción: con la fila presente, `estado` ausente y la huella cambiada, la gracia no reinicia desde «ahora».
  - Descartadas: la variante (b) general de la hoja, porque castiga una falla del disco aislada, y no hacer nada, que deja la vía de la copia con el mismo fork.
- **Unicidad de los EventId (RSVB-01):** regla con prueba de arquitectura y rangos por equipo y módulo.
  - Descartada: solo la revisión manual, que ya falló dos veces (4718 y ahora 4730-4732).

## Entregas a otros agentes

- **Desarrollador backend (A):** RSVB-01 antes del PR; RSVB-04, RSVB-05 y RSVB-06 en el mismo PR si caben.
- **Arquitecto Maestro (B):** RSVB-02 (forma del aviso al SUPER) y RSVB-03 (corregir el supuesto 3, más el riesgo aceptado o la precisión de ADR-58).
- **Devops (B):**
  - el procedimiento de mantenimiento del anillo (RSV-02 (1)) debe exigir detener a mano la API de consola en el DEMO y en Debug;
  - el instalador de la API debe registrar el servicio con el nombre que use la constante compartida (RSVB-04);
  - las reglas de alerta por EventId deben esperar a RSVB-01.
- **qa-automatizado:** un ensayo de `--cambiar-recuperacion` en una instalación sellada con la API instalada como servicio, cuando exista ese instalador.

## Relectura (PR #75 @ d60bb7d3)

- **Fecha:** 2026-10-18 · **Revisor:** auditor-seguridad (equipo A), con Opus por escalado.
- **Alcance:** los commits de corrección `a719e422` (RSVB-01), `06dbbf0f` (RSVB-04) y `d60bb7d3` (RSVB-05 y RSVB-06), y el rebase de la rama sobre `origin/feature/modelo-ng` @ `322b21d6` (#69, #56 y #72 de C). Solo lectura: no modifiqué la rama.
- **Ejecutado:**
  - `dotnet build tests/GPOS.Tests`: 0 errores y 0 advertencias (estaba al día);
  - `dotnet test --no-build` con `(FullyQualifiedName~EventIdUnicos|~MantenimientoAnillo|~Licencia|~SellosPadronIlegible|~SellosResellado|~SqlSoloEnLugaresPermitidos)&Transicion!=Ola5&Transicion!=Defecto`: **608 correctas, 0 con error, 1 omitida** (`ReglaSecuenciaTests`, la de siempre), en 3 min 38 s;
  - `testhost.exe` borrado después de compilar y después de probar.
- **Sin verificar:** la suite completa (no la corrí).

### Estado de cada hallazgo

| ID | Estado | Comentario |
|---|---|---|
| RSVB-01 | **Cerrado** | Verificado (ver abajo). |
| RSVB-02 | **Abierto** (decisión de B; no bloquea) | El #69 trae un canal reutilizable (ver abajo). |
| RSVB-03 | **Abierto** (Arquitecto Maestro; no bloquea) | No le correspondía a este PR; sin cambios. |
| RSVB-04 | **Cerrado** | Queda un residual Bajo (R-1), aceptable. |
| RSVB-05 | **Cerrado** | Una observación (R-2), sin efecto en la seguridad. |
| RSVB-06 | **Cerrado** | El punto 2 se probó en `--cambiar-recuperacion`; ver la nota. |

**RSVB-01 (cerrado).**
- `EstadoLicenciaService.cs:134-141`: los cuatro eventos pasan a 4725 a 4728.
- Busqué 4723, 4725-4728 y 4734 con `git grep` en todas las ramas de `origin`, después de `git fetch`. Solo aparecen con sus nombres de la licencia: no chocan con nada.
- Repetí el cálculo de la prueba por mi cuenta, con todas las declaraciones `new EventId(n, "…")` y `EventId X = new(n, "…")` de `src`. Hay exactamente 11 números repetidos: 4701-4703 y 4711-4718. Coinciden con `Excepciones` de `tests/GPOS.Tests/Arquitectura/EventIdUnicosTests.cs`.
- La prueba es buena por tres razones:
  - exige igualdad de conjuntos (`SetEquals`), así que un nombre nuevo en un número congelado también falla;
  - la segunda prueba obliga a sacar de la lista lo que ya no se repita, así que la lista solo decrece;
  - el umbral `> 50` protege contra un patrón que deje de encontrar declaraciones.
- No hay otras formas de declarar eventos en `src`: no aparecen `[LoggerMessage]` ni `EventId` como entero suelto.
- Pendiente de devops, sin cambio: las reglas de alerta pueden usar 4725-4728. Los once heredados siguen siendo ambiguos por número, así que una regla sobre ellos tiene que filtrar también por origen o por nombre.

**RSVB-04 (cerrado; residual R-1, Bajo).**
- `src/GPOS.Comun/Servicios/ServiciosWindows.cs` reúne en un solo lugar:
  - los servicios `GPOS.Api` y `GPOS.Reportes` (este último desde `ProtocoloIntrospeccion.ServicioReportes`, que es el mismo que usa `AddWindowsService` en `src/GPOS.Reportes.Api/Program.cs:21`);
  - sus procesos, `GPOS.Api` y `GPOS.Reportes.Api`.
- La prueba `RSVB04_los_nombres_de_servicio_y_de_proceso_salen_de_la_constante_compartida` ata el nombre del proceso al nombre del ensamblado de la API.
- El DEMO arranca `app\api\GPOS.Api.exe` (`Iniciar-Demo.ps1:65`), así que ahora el verbo se niega en el DEMO si la API está en marcha. Antes solo informaba.
- La búsqueda de procesos falla cerrada:
  - `EstadoServicios.cs:46-65`: `InvalidOperationException`, `Win32Exception` y `PlatformNotSupportedException` dan `true` (proceso en marcha), y cualquier otra excepción aborta el verbo;
  - `MantenimientoAnillo.cs:274-276`: el caso `NoInstalado` con el proceso en marcha niega el verbo;
  - `Desconocido` sigue negando (`:283-285`).
- **R-1 (Baja; residual, no bloquea).** Dos casos que el control no ve:
  - un servicio instalado y **detenido** no comprueba además el proceso (`MantenimientoAnillo.cs:271-273`), así que pasaría una API lanzada a mano como `GPOS.Api.exe` con el servicio parado;
  - una API arrancada con `dotnet GPOS.Api.dll` tampoco se ve, como reconoce el aviso.

  Remediación opcional (≈0,02 dp): comprobar el proceso también en el caso `Detenido`. La entrega a devops para el procedimiento sigue en pie.
- Todavía no hay `AddWindowsService` en `src/GPOS.Api`. Cuando se agregue, debe usar `ServiciosWindows.Api` (entrega a devops y a backend, sin cambio).

**RSVB-05 (cerrado; observación R-2).**
- `MantenimientoAnillo.cs:318-327` y `:347-358`: solo la `InvalidOperationException` de `IKeyRingProvider.GetCurrentKeyRing()` se traduce en «no tiene una llave vigente». La reprotección simulada queda fuera de ese `catch`, así que un error de la base sale con su propio mensaje. El `finally` sigue devolviendo el estado a `SinComprobar` (`:330-333`).
- `ReproteccionSellos.cs:131` y `:142`: los sellos que exceden el largo de la columna se cuentan aparte. Siguen siendo un impedimento, así que la falla sigue cerrada.
- **R-2 (sin severidad).** `IKeyRingProvider` está en el espacio `Microsoft.AspNetCore.DataProtection.KeyManagement.Internal`, una API «pública pero interna» que puede cambiar entre versiones menores. Si cambiara su firma, la compilación fallaría. Si cambiara su comportamiento (que no lance), la `InvalidOperationException` saldría sin traducir desde la reprotección y abortaría el verbo: sigue fallando cerrada. Basta con revisarla al actualizar `Microsoft.AspNetCore.DataProtection`.

**RSVB-06 (cerrado).**
1. `RSVB06_una_entrada_que_no_coincidia_sigue_sin_coincidir_tras_reproteger_los_sellos`. Comprueba que:
   - C1 conserva su resultado distinto de `Valido`;
   - SU1 sigue `Valido`;
   - solo se recalcula una entrada del padrón.
2. `RSVB06_si_el_padron_no_se_escribe_tras_confirmar_no_se_revoca_nada`. Usa una DACL que deja pasar la comprobación previa de RSV-11 y hace fallar el reemplazo. Comprueba que:
   - aparece el aviso;
   - no hay ningún `revocation-*.xml`;
   - el disco queda como estaba;
   - la base tiene la versión nueva.

   **Nota:** se probó en `--cambiar-recuperacion`, no en `--revocar-heredadas` ni en `--reproteger-sellos` como pedí. Lo acepto: los tres verbos llegan por el mismo `ReproteccionSellos` → 2.ª comprobación → revocación, y este es el caso más delicado, porque el ancla ya cambió. Una variante para `--revocar-heredadas` sería deseable, pero no es necesaria.
3. `RsvF3_el_arranque_con_el_refresco_roto_falla_y_no_publica_instantanea`. Comprueba que el arranque lanza la excepción y no publica instantánea, que el estado queda en `NoLicenciada` y que no se emite el 4726. Así queda fijado que un reinicio no reinicia la racha sin un refresco correcto.

### El rebase sobre 322b21d6 no tocó la zona revisada

- `git diff --name-only 886dde70 322b21d6 -- src`, cruzado con los archivos que cambia la rama. Solo coincide `src/GPOS.Migracion/Program.cs`.
- En ese archivo, la base agrega `ReintentoLectura` en `verificar`, y la rama agrega `--reproteger-sellos` a la ayuda y a `Banderas`. Son zonas distintas y el resultado es coherente.
- El #69 y el #56 no tocan:
  - `EstadoLicenciaService`, `ReproteccionSellos`, `PadronSellos` ni `AnilloDataProtection`;
  - `MantenimientoAnillo`, `EstadoServicios` ni `Program.cs` de la API.
- La prueba de unicidad, que recorre todo `src` después del rebase, pasa. Por lo tanto el #69 no agregó EventId en conflicto.
- Las 608 pruebas de la zona pasan sobre el árbol rebasado.

### RSVB-02: el #69 ofrece un canal reutilizable (verificado; para la decisión de B)

**Qué trae el #69.**
- `GET /api/super/eventos-servidor` (`src/GPOS.Api/Endpoints/EventosServidorEndpoints.cs:17`) responde solo al SUPER (`RequiereSuper`) y en el sitio central.
- Lee `dbo.BitacoraSeguridad` con un filtro fijo, `Severidad = 'A' AND Canal = 'CONSOLA'` (`src/GPOS.Core/Consultas/Sistema/Restauracion/ConsultasRestauracionSistema.cs:129-134`).
- Dos piezas de la interfaz lo muestran:
  - `src/GPOS.Web/Components/Layout/AvisoEventosServidor.razor`: un aviso al entrar, si hay eventos posteriores al último visto;
  - `src/GPOS.Web/Components/Compartidos/EventosServidor.razor`: la tarjeta de Diagnóstico.

**Cómo reutilizarlo.** Es justamente el «aviso al SUPER» visible que pide la opción (a) de RSVB-02. Bastaría con tres cambios:
1. Que `EstadoLicenciaService` registre también en `dbo.BitacoraSeguridad`, con severidad `A` y canal `SISTEMA`, los eventos 4726 (primer fallo y luego uno al día), 4727 (solo consulta) y 4723 (copia ausente, una vez al día).
   - Con el mismo contenido sin rutas ni secretos que ya llevan.
   - En el mejor esfuerzo: si la base es la que falla, la escritura también fallará y queda el evento del registro.
   - Es lo que ya anuncia DL-04 (a) en `EstadoLicenciaService.cs:106-109`.
2. Ampliar el filtro de S-05 a `Canal IN ('CONSOLA','SISTEMA')`, o a una lista de eventos de la licencia, y darles nombre en `VistaSelloPadron.NombreEvento`.
3. Como `BitacoraSeguridadService` es de ámbito por petición y el servicio de licencia es un singleton, la escritura tiene que pasar por una fábrica de ámbitos.

**Costo:** ≈0,15-0,25 dp con sus pruebas. Es menos que la opción (a) original, porque la interfaz y el endpoint ya existen.

**Límites.**
- Resuelve el caso legítimo (el SUPER se entera desde el primer fallo).
- Frente al adversario de la licencia mejora poco: `GPOS_SYSDATA` también la controla el administrador del servidor. La defensa de fondo sigue siendo la de ADR-58 (hora confiable y renovación por el agente).
- El «visto» se guarda en el navegador de cada SUPER. Para un aviso diario no importa.

### Veredicto actualizado

**Aprobado con observaciones** (recomendación técnica; la decisión es del propietario).

- RSVB-01, RSVB-04, RSVB-05 y RSVB-06 quedan cerrados.
- No hay hallazgos Críticos ni Altos.
- Quedan abiertos, y no bloquean el PR:
  - RSVB-02 (forma del aviso; ahora con el canal de S-05 del #69 como opción barata) y RSVB-03 (supuesto 3 de CR-01), los dos para decidir antes de la primera licencia de pago;
  - los residuales R-1 (Bajo) y R-2 (observación).
