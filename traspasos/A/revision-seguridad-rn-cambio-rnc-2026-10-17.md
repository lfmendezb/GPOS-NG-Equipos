# Informe de Seguridad: pieza RN «Cambio de RNC» de la licencia

- **Fecha:** 2026-10-17
- **Autor:** auditor-seguridad (Opus 5.5)
- **Árbol:** `C:\Users\lfmen\source\repos\Solucion GPOS NG\GPOS-NG-rn`, rama `a/rn-cambio-rnc` (HEAD `ae25bde3`), solo lectura.
- **Diferencia revisada:** `git diff afc8bdb1..ae25bde3` (apilada sobre SL, PR #63). Son dos commits: `781ade1a` (código) y `ae25bde3` (pruebas). En total, 18 archivos y +1087/−10 líneas.
- **Referencias:**
  - `[BP]`: `blueprint-licencia-lote2-2026-10-14.md`, §4.1 fila RN (:345), §5.1 S-03 (:398, :403-405) y §6.1.1 regla 5, NV-07 (:530-538).
  - `[SEG]`: `revision-seguridad-blueprint-licencia-lote2-2026-10-14.md`, SEG-L2-12 (:257), SEG-L2-16 (:290) y D.2 (:539-551).
  - `[DAT]`: `datos-licencia-l1a4-2026-10-14.md`, 2.3 (:136-170).
  - `[HF]`: `GPOS-NG-Equipos\traspasos\A\hoja-firma-dl01-dl13-licencia-2026-10-14.md`, DL-03 (a) con P-3 (:165-185).
- **Estado de la decisión:** este informe es una recomendación técnica. La firma es del propietario (C2).

## 1. Alcance y superficie revisada

| Superficie | Exposición | Archivos |
|---|---|---|
| S-03 `PUT /api/super/empresas/{codigo}/rnc` | **No mapeada.** El manejador existe, pero ningún `Map*` lo publica | `src/GPOS.Api/Endpoints/CambioRncEndpoints.cs:37-44`; `src/GPOS.Api/Program.cs:264-272` (solo el registro del servicio) |
| Servicio del cambio (fila MAC, evento, segunda escritura, P-3, idempotencia) | Lo usan S-03 y el verbo | `src/GPOS.Core/Sistema/Licencia/CambioRncService.cs` |
| SQL del bloqueo, la segunda escritura y la consulta de eventos | — | `src/GPOS.Core/Infraestructura/Motor/ComandosCambioRnc.cs` |
| Configuración del ADMIN (`POST /api/admin/parametros`) | ADMIN y SUPER, autenticados | `src/GPOS.Core/Servicios/AdministracionService.cs:60-130` |
| Verbo provisional `GPOS.Migracion empresa --cambiar-rnc` | Consola del servidor, con cuenta de Windows y el anillo | `src/GPOS.Migracion/Empresas/ComandoEmpresa.cs`; `src/GPOS.Migracion/Program.cs:67, 266-269` |
| Dígito verificador | S-03 y el verbo | `src/GPOS.Core/Dominio/Configuracion/Empresa.cs:153-172` |
| Motor (contexto, sin cambios en esta pieza) | — | `src/GPOS.Core/Sistema/Licencia/MotorEstados.cs:331-375, 467-476`; `EstadoLicenciaService.cs:521-533` |

No compilé ni ejecuté pruebas. El árbol es de solo lectura y compilar escribe en `bin/obj`. Por eso las afirmaciones sobre las pruebas salen de leer su código.

### Verificación de lo que declara el desarrollador

| Declaración | Resultado | Evidencia |
|---|---|---|
| Primero la fila MAC y el evento `CAMBIO_RNC_SUPER` (sin el RNC) en `GPOS_SYSDATA`, en una transacción; después el RNC en `conf.Empresa`, `_ParametrosGenerales` y `audit.Bitacora` | **Verificado.** El evento lleva el actor, el canal, el motivo y el detalle (verbo, SID, equipo, origen y texto fijo), sin el RNC | `CambioRncService.cs:112-159`; `ComandosCambioRnc.cs:57-84` |
| Idempotente (`Completado`/`YaAplicado`) | **Verificado** | `CambioRncService.cs:120-138` |
| P-3: conserva `RncAnterior` y `CambiadoUtc` | **Verificado.** Ver RN-04 por un caso que la regla firmada no cubre | `CambioRncService.cs:140-145, 167-178` |
| 409 `LICENCIA_ILEGIBLE` si hay fila previa y la licencia no se lee | **Verificado** | `CambioRncService.cs:170-173` |
| Dígito verificador (mód. 11 / mód. 10) | **Verificado.** El algoritmo es correcto: lo comprobé a mano con dos RNC públicos de entidades. Ver RN-02 por los números reales que no lo cumplen | `Empresa.cs:153-172` |
| 409 `RNC_SOLO_SUPER` al cambiar o vaciar un RNC fijado, también para el SUPER | **Verificado.** La prueba cubre al ADMIN, al SUPER y el vaciado | `AdministracionService.cs:108-111`; `CambioRncHttpTests.cs:54-79` |
| S-03 construida y sin mapear | **Verificado.** También hay una prueba de arquitectura | `CambioRncEndpoints.cs:30-45`; `CambioRncEnLaApiTests.cs:26` |
| El verbo exige el anillo y deja un evento con cuenta, SID, equipo y `Origen=VERBO` | **Verificado.** El anillo se comprueba dos veces, y además `Licencia.InstalacionId` dentro de la transacción | `ComandoEmpresa.cs:41, 63, 76`; `ComandoSellos.cs:35-49`; `CambioRncService.cs:113-115` |
| El SUPER ve los eventos del verbo | **No verificado: falta la superficie** (RN-01) | `CambioRncService.cs:181-186` no tiene llamador en `src` |
| Bloqueo de aplicación de sesión que cubre la segunda escritura | **Verificado, con un defecto menor** (RN-03) | `CambioRncService.cs:96-106`; `ComandosCambioRnc.cs:40-51` |
| NV-07 de punta a punta | **Verificado por lectura de la prueba** | `CambioRncTests.cs:109, 142, 183, 260` |
| La primera asignación (empresa sin RNC) sigue permitida al ADMIN | **Verificado.** No permite evadir la licencia (sección 4, comprobación C-4). Hay una desviación del texto firmado (RN-06) | `AdministracionService.cs:110` |

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título |
|---|---|---|
| RN-01 | Media | Condición 1 de D.2 incompleta: ninguna superficie muestra al SUPER los eventos del verbo |
| RN-02 | Media | El dígito verificador rechaza RNC y cédulas reales emitidos sin un dígito válido, y bloquea la salida de `Invalida` |
| RN-03 | Baja | Bloqueo de sesión sobre una conexión con pool: se toma fuera del `try` y su error 51616 llega como 500 |
| RN-04 | Media | El rebote al RNC licenciado reinicia la transición: con la renovación de por medio, la empresa opera indefinidamente con un RNC no licenciado (RN-F2) |
| RN-05 | Baja | El motivo libre puede llevar una cédula al evento crítico, que se guarda 2 años |
| RN-06 | Baja | La primera asignación por el ADMIN se aparta del texto firmado de DL-03 (a), «solo lectura desde ya» |

No hay hallazgos Críticos ni Altos.

## 3. Checklist OWASP (Top 10 2021)

| Categoría | Resultado | Referencia |
|---|---|---|
| A01 Control de acceso | Cumple. S-03 no está publicada. Cuando se publique, tendrá doble control (`RequiereSuper` y `sesion.EsSuper`). La configuración del ADMIN rechaza el cambio, también para el SUPER. El verbo depende del acceso de Windows y del anillo (residual CP-4, aceptado en D.2) | §1; C-1 |
| A02 Criptografía | Cumple. La fila va con `Protect` (propósito de estado) y lleva dentro la clave, el `InstalacionId` y la empresa. Una fila de otro anillo o de otra empresa no cuenta (`CambioRncService.cs:119`; `EstadoLicenciaService.cs:528`) | — |
| A03 Inyección | Cumple. Todo va con parámetros tipados (`DbString` con largo). No hay SQL dinámico | `ComandosCambioRnc.cs:40-101` |
| A04 Diseño inseguro | Observaciones: RN-02, RN-04 y RN-06 | §4 |
| A05 Configuración | Observación: RN-03 (pool y error sin mapear) | §4 |
| A06 Componentes vulnerables | No aplica: no hay paquetes nuevos | — |
| A07 Identificación y autenticación | Cumple mientras S-03 siga sin mapear (SEG-L2-12). El filtro de autenticación reciente llega con la fase A | `CambioRncEndpoints.cs:15-28` |
| A08 Integridad de datos | Cumple. La fila MAC es la única prueba que acepta el motor. Cambiar el RNC por SQL sin la fila deja la empresa `Invalida`, sin transición | `MotorEstados.cs:342-361` |
| A09 Registro y monitoreo | Observaciones: RN-01 (visibilidad) y RN-05 (dato personal en el motivo) | §4 |
| A10 SSRF | No aplica | — |
| Aislamiento entre tenants | Cumple. S-03 y el verbo actúan sobre la empresa indicada, la clave de la fila incluye el código y el JSON lo repite | `CambioRncService.cs:88-93, 119` |

## 4. Hallazgos

### RN-01 · Media · Condición 1 de D.2 incompleta: el SUPER no ve los eventos del verbo

- **Riesgo.** D.2, condición 1 (`[SEG]` :545), y la fila de DL-03 (`[BP]` :1095, «evento crítico visible al SUPER») exigen que cada uso del verbo «se muestr[e] al SUPER en S-01 o en Diagnóstico en su siguiente inicio de sesión».
  - El objetivo es que un uso por el TI de un cliente con servidor propio quede visible para GSF.
  - El evento se escribe bien, pero solo existe el método `EventosVerbosAsync` (`CambioRncService.cs:181-186`; `ComandosCambioRnc.cs:90-101`). Ninguna ruta, pantalla ni trabajo lo llama: la búsqueda en `src` solo encuentra su definición, y el único llamador es la prueba `CambioRncHttpTests.cs:164`.
  - Hasta la fase A de ADR-81, el verbo es la **única** vía para cambiar el RNC y lo puede ejecutar cualquiera con acceso de Windows al servidor y al anillo. Sin la superficie, GSF no se entera de un cambio hecho por el cliente salvo que consulte la tabla por SQL.
  - La ganancia del cliente está acotada por el motor (transición limitada por `emitida + 7 d`, y después `Invalida`). Por eso la severidad es Media y no Alta.
- **Alcance.** Lo mismo vale para `sellos --legitimar` y `sellos --purgar`, porque la consulta filtra `Canal = 'CONSOLA'` y severidad A. Corrijo así lo que dije en mi revisión de SL (`revision-seguridad-sl-sello-padron-2026-10-17.md`:204): la condición 1 se cumplía solo en el registro, no en la visibilidad.
- **Remediación (unos 0,25 dp [I]):**
  - Un aviso en S-01 o en Diagnóstico al iniciar sesión el SUPER, con los eventos de `EventosVerbosAsync` desde una marca «visto hasta» del SUPER (fila en `GPOS_SYSDATA`), y un acuse que adelante la marca y deje su propio evento.
  - Una prueba HTTP de punta a punta: el verbo deja el evento y el SUPER lo ve en su siguiente sesión.
  - Si no entra en RN, que entre en el primer PR de L1b o de Diagnóstico **antes del corte de diciembre**, y que se anote como condición abierta de DL-03.

### RN-02 · Media · El dígito verificador rechaza números reales y bloquea la salida de `Invalida`

- **Riesgo.** `ExigirRnc` rechaza con 422 todo RNC o cédula cuyo dígito verificador no cumpla mód. 11 o mód. 10 (`CambioRncService.cs:73-77`; `Empresa.cs:153-172`). El algoritmo es el de la DGII y la JCE, y lo comprobé a mano.
  - Pero existen números **emitidos y vigentes** que no lo cumplen. La biblioteca de referencia python-stdnum mantiene listas de excepciones en `stdnum/do/rnc.py` (unos 23 RNC) y `stdnum/do/cedula.py` (varios cientos de cédulas) [I: lo recuerdo de esa biblioteca, no lo consulté en línea en esta sesión].
  - Ejemplo de persona jurídica, que es un dato público: el RNC `101581601` da 3 como dígito esperado con el algoritmo implementado, y su último dígito es 1. Lo calculé a mano.
  - Un cliente con uno de esos números no puede cambiar a él ni por S-03 ni por el verbo. Si su licencia ya viene con ese RNC, queda `Invalida` sin ninguna vía dentro del producto; la única salida sería SQL directo, que no deja fila y por tanto no da transición.
  - Probabilidad baja; impacto alto para ese cliente (pérdida de operación).
  - Además, hay incoherencia: la primera asignación del ADMIN solo exige 9 u 11 dígitos (`AdministracionService.cs:64-65`), así que el ADMIN acepta un RNC que S-03 después rechazaría.
- **Remediación (0,2 a 0,3 dp [I]):**
  1. Una lista de excepciones versionada en el código (RNC y cédulas tomadas de una fuente verificable: padrón de la DGII o la lista de python-stdnum), consultada antes del 422. Las cédulas de la lista son datos personales: van solo en el código, no en documentos ni registros.
  2. Como alternativa más barata, en el verbo, `--aceptar-digito` con una segunda confirmación y una marca en el detalle del evento («dígito verificador no válido, aceptado por el operador»). En S-03, el equivalente cuando se publique.
  3. Aplicar la misma validación (con las excepciones) a la primera asignación del ADMIN, para evitar errores de tecleo que después solo arregla GSF en el servidor.
  4. Una prueba con al menos un RNC de la lista de excepciones.

### RN-03 · Baja · Bloqueo de sesión sobre una conexión con pool

- **Riesgo.**
  - `TomarBloqueoAsync` se ejecuta **antes** del `try` (`CambioRncService.cs:98-106`). Si la cancelación llega después de que el servidor concedió el bloqueo y antes de entrar al `try`, el `finally` no corre.
  - La conexión de `GPOS_SYSDATA` usa el pool, porque la cadena va tal cual (`Program.cs:268`), sin `Pooling = false`. Al cerrarse vuelve al pool **con la sesión viva y el bloqueo tomado** hasta que la conexión se reutilice (el reinicio de la sesión se hace en el siguiente uso) o el pool la descarte por inactividad, unos 4 a 8 min [I: el comportamiento de `sp_reset_connection` con bloqueos de aplicación de sesión debe confirmarse].
  - Mientras tanto, todo cambio de esa empresa espera 10 s y falla con el error 51616. Ese error no está mapeado: en la API llega como 500, y en el verbo como «Error de SQL Server 51616».
  - La prueba de fallo inyectado no detectaría la fuga: la repetición puede tomar la misma sesión del pool, y en la misma sesión el bloqueo es reentrante.
  - El camino normal sí suelta siempre el bloqueo: el `finally` usa `CancellationToken.None` y `APPLOCK_MODE` evita el error si no lo tiene (`ComandosCambioRnc.cs:50-51`).
  - No hay agotamiento posible hoy: S-03 no está publicada, el verbo es manual, y cada cambio retiene como mucho una conexión durante unos 40 s (10 s de espera más 30 s de la segunda escritura).
- **Remediación (0,1 dp):**
  - `Pooling = false` en la conexión del bloqueo, el mismo criterio que ya usa la segunda escritura (`ComandosCambioRnc.cs:67`). Así, al cerrarse la conexión, el bloqueo se suelta siempre.
  - Mover `TomarBloqueoAsync` dentro del `try`.
  - Mapear 51616 a 409 `CAMBIO_RNC_EN_CURSO`, con un mensaje claro en el verbo.

### RN-04 · Media · El rebote al RNC licenciado reinicia la transición (dictamen sobre RN-F2 del arquitecto)

*Nota: la versión anterior de este informe clasificaba RN-04 como Baja porque solo analizaba el ciclo con la misma licencia. A pedido del coordinador, dictamino aquí la sección 7.2, RN-F2, de `validacion-rn-cambio-rnc-2026-10-17.md`. Con la renovación de por medio, la severidad sube a Media.*

**El mecanismo** (verificado en el código; los tiempos dependen de los parámetros de cada licencia):
1. La licencia L1 cubre A. El cambio A→C en t1 deja la fila (A, C, t1).
2. Al volver a A (C→A), P-3 conserva, porque `licenciado ≠ actual` y `RncAnterior = A`: la fila queda (A, A, t1) (`CambioRncService.cs:142-145, 177`).
3. Al cambiar otra vez a C (A→C), `licenciado = actual`, así que no se conserva y se escribe una fila nueva (A, C, t2).

**Precisión sobre el texto del arquitecto.** «El plazo de 30 días empieza de nuevo» no es exacto **con la misma licencia**:
- el motor ancla la transición en `mín(CambiadoUtc, emitida + 7 d)` y exige `finGracia > CambiadoUtc` (`MotorEstados.cs:350-354`);
- por eso, con L1, el rebote alarga la transición como mucho hasta `emitida + 7 d + gracia` (unos 7 días más), y nada si el primer cambio ya fue posterior a `emitida + 7 d`.

**El camino indefinido existe, pero pasa por la renovación:**
- El cliente vuelve a A antes de pedir la renovación. La solicitud lleva el RNC actual, A, así que el emisor no ve diferencia con su catálogo (`[BP]` :144, D-5 (b)) y emite L2 con A.
- Después de aceptar L2, cambia A→C con una fila nueva en t2 > `AceptadaUtc(L2)`. NV-07 da la transición contra L2, y su fin es `máx(fin de la gracia de L2, …)` (`MotorEstados.cs:353`): la empresa opera con C **durante todo el período pagado de L2**.
- Repitiéndolo en cada renovación, opera indefinidamente con un RNC que ninguna licencia cubre, y GSF nunca ve C en las solicitudes.

**Severidad: Media.**
- **Impacto:** la licencia queda transferible a otro contribuyente sin que GSF lo sepa. Se pierde el propósito de atar la licencia al RNC (ADR-59, NV-07). El cliente sigue pagando una suscripción y queda atado a una instalación, por eso no lo clasifico como Alto.
- **Probabilidad:**
  - hoy lo puede hacer el TI del cliente con el verbo (acceso al servidor y al anillo), sin fabricar ningún MAC;
  - después de la fase A, también el SUPER con segundo factor, que es GSF;
  - quien tiene el anillo ya podía rehacer el MAC (residual CP-4), pero el verbo convierte un fraude técnico en dos órdenes documentadas, y eso baja el umbral.
- **Detección:** cada rebote deja dos `CAMBIO_RNC_SUPER`, pero hoy el SUPER no los ve (RN-01). Mientras RN-01 no esté cerrado, el hueco no es detectable sin consultar la tabla.

**¿Lo cierra la recomendación (a) del arquitecto** (conservar `RncAnterior` y `CambiadoUtc` siempre que la fila vaya del RNC licenciado, quitando `licenciado != actual` de `Conservar`)? **Sí, en todas las vías de la aplicación (S-03 y el verbo):**
- El rebote deja la fila (A, C, t1) con la hora del primer cambio.
- Contra L2, aceptada después de t1, la fila no cuenta (`AceptadaUtc ≤ CambiadoUtc`, `MotorEstados.cs:351`). Termina la transición de L1 y la empresa queda `Invalida`, que es la regla firmada: «si una licencia aceptada después del cambio conserva el RNC anterior, la fila no cuenta».
- Con la misma licencia, tampoco se gana nada, porque t1 no cambia.
- El caso legítimo afectado (revertir un error y hacer meses después un cambio real con la misma licencia) falla cerrado hasta que GSF emita la licencia con el RNC nuevo. Es aceptable: con la renovación mensual, ese plazo es corto.

**Riesgo residual, dentro de CP-4.** Quien tenga escritura por SQL en `GPOS_SYSDATA` puede **borrar o corromper** la fila. `CambiarConBloqueoAsync` trata una fila ausente o que no verifica como inexistente (`CambioRncService.cs:119`) y escribe una nueva con la hora actual, lo que reabre el rebote. No hace falta el anillo para borrar, pero quien usa el verbo ya tiene ese acceso y el anillo, así que no es una capacidad nueva. El borrado no deja rastro distinguible: el detalle dice «fila nueva», igual que un primer cambio.

**Remediación:**
1. Opción (a) del arquitecto: quitar `licenciado != actual` de `Conservar` y agregar una prueba con renovación de por medio: C→A, aceptar L2 con A y luego A→C, con la empresa `Invalida` al terminar la transición de L1 (0,05 a 0,1 dp).
2. Detección del residual (0,05 dp): si no hay fila válida pero `BitacoraSeguridad` tiene un `CAMBIO_RNC_SUPER` anterior de la empresa, el evento nuevo lo marca («fila ausente o inválida con cambios previos»), y RN-01 lo muestra al SUPER.
3. Cerrar RN-01: es lo que convierte el residual en algo visible para GSF.

Mi recomendación al propietario es firmar RN-F2 en la opción (a), con los puntos 2 y 3.

### RN-05 · Baja · El motivo libre puede llevar una cédula al evento crítico

- **Riesgo.**
  - El evento no lleva el RNC (verificado, `CambioRncService.cs:151-153`). Pero el `Motivo` es texto libre de 10 a 200 caracteres, se guarda en `BitacoraSeguridad.Motivo` y se conserva 2 años (purga a partir de 2 años, `EsquemaRestauracionSistema.cs:46-50`).
  - Un motivo como «cambio a la cédula del nuevo dueño …» deja un dato personal (Ley 172-13) en una bitácora que no lo necesita.
  - En la base de la empresa, `audit.Bitacora` guarda el antes y el después del RNC (`CambioRncService.cs:157`). Es aceptable: es la identificación fiscal de la propia empresa, ya impresa en sus comprobantes, y la ve quien administra esa empresa.
  - El verbo muestra el RNC en la consola del operador (`ComandoEmpresa.cs:60`), lo que también es aceptable.
- **Remediación (0,05 dp):**
  - Enmascarar en el `Motivo` del evento las secuencias de 9 u 11 dígitos, con o sin guiones.
  - Indicar en la ayuda del verbo que el motivo no lleva el RNC ni la cédula.

### RN-06 · Baja · La primera asignación se aparta del texto firmado de DL-03 (a)

- **Hecho.** `[HF]` :178 dice: «El ADMIN ve el RNC de solo lectura **desde ya**». El código permite al ADMIN fijar el RNC de una empresa que no lo tiene (`AdministracionService.cs:110`). Las pantallas no cambian en esta diferencia (el «ajuste de pantalla» de `[HF]` :182 sigue pendiente).
- **Riesgo de seguridad: ninguno verificado** (ver C-4). La desviación es de producto: debe quedar como precisión firmada, no como hecho consumado.
- **Remediación:** el arquitecto maestro la presenta como precisión de DL-03 («la primera asignación, en una empresa sin RNC, sigue siendo del ADMIN»), con este análisis. Si el propietario prefiere el texto literal, se cierra con un 409 también para la primera asignación (0,05 dp).

### Comprobaciones pedidas expresamente

- **C-1. ¿Hay una vía para cambiar el RNC sin la fila MAC y abrir una transición indebida?** No.
  - Busqué todos los escritores de `conf.Empresa.Rnc` en `src`. Solo hay dos:
    - `AdministracionService.cs:113`, protegido por el 409 de :110 cuando hay un RNC fijado;
    - `ComandosCambioRnc.cs:72`.
  - La migración inicial inserta `conf.Empresa` sin RNC (`SqlMigracionesCfg.cs:76-78`). `PuenteCfg.cs:31` escribe el espejo heredado, que el motor no lee: el motor lee `conf.Empresa` (`ComandosLicencia.cs:243`).
  - Una restricción `CHECK` impone solo dígitos (`CfgConfiguracion.cs:51`), así que la comparación ordinal del 409 no tiene falsos cambios.
  - Un cambio por SQL directo (residual CP-4) sin la fila deja `Invalida` sin transición. La fila no se puede fabricar sin el anillo, y una fila de otro anillo, otra instalación u otra empresa no cuenta (`MotorEstados.cs:342-361`; `EstadoLicenciaService.cs:528`).
- **C-2. Carrera entre dos cambios, y entre el verbo y la API.**
  - Los dos toman el mismo recurso en `GPOS_SYSDATA` (`GPOS.Licencia.CambioRnc:<empresa>`), que cubre las dos escrituras. Verificado, y probado en `CambioRncTests.cs:260` (la segunda conserva `RncAnterior = A`).
  - La configuración del ADMIN no toma el bloqueo, pero la protege `rowversion` (`CfgConfiguracion.cs:73`): si S-03 escribe entre la lectura y el guardado del ADMIN, el guardado falla por concurrencia.
  - La caché de 15 min no abre ningún hueco. El verbo no puede invalidar la instantánea de la API (`ComandoEmpresa.cs:76`), así que la API evalúa con el RNC anterior hasta 15 min. Si estaba `Vigente`, sigue igual: es lo mismo que la transición. Si estaba `Invalida`, tarda en salir, lo que es disponibilidad y no seguridad. El 409 del ADMIN lee la base, no la caché.
- **C-3. Bloqueo de sesión.** En el camino normal se suelta siempre. Hay una fuga posible solo si la cancelación llega en un intervalo estrecho, y la agrava el pool (RN-03). Hoy no hay agotamiento posible.
- **C-4. Primera asignación por el ADMIN.** No permite evadir la licencia:
  - Sin fila no hay transición, y el motor exige `MismoRnc(entrada, empresa)` (`MotorEstados.cs:342`). Con un RNC distinto del licenciado, la empresa queda `Invalida`; con el licenciado, `Vigente`, que es lo correcto.
  - Una entrada de la licencia sin RNC válido nunca coincide (`MotorEstados.cs:467-476`).
  - Ese RNC viaja en la solicitud de licencia, y el emisor se detiene si no coincide con su catálogo (`[BP]` :144, D-5 (b)).
  - Una vez fijado, ni el ADMIN ni el SUPER lo vacían por esta vía (prueba en `CambioRncHttpTests.cs:69-71`).
- **C-5. Datos personales.** Ver RN-05. La fila va cifrada; el evento no lleva el RNC; los mensajes 409 no lo incluyen.
- **C-6. Visibilidad al SUPER.** Ver RN-01.
- **C-7. RNC reales sin dígito verificador válido.** Ver RN-02.

## 5. Controles que están bien implementados

- El orden fila → empresa, con el evento en la misma transacción que la fila. Si la segunda escritura falla, la fila no da transición y repetir la completa sin fila nueva (SEG-L2-16, probado con el fallo inyectado en `CambioRncTests.cs:142`).
- Falla cerrado ante una licencia ilegible con fila previa, ante un `InstalacionId` que no verifica (503), y ante una fila de otro anillo, que se reemplaza y lo anota en el detalle.
- S-03 queda sin mapear y lo garantiza una prueba de arquitectura. La forma futura del `Map*` ya está documentada con `Esencial` y la autenticación reciente.
- El verbo: comprueba el anillo, exige `--confirmar`, guarda la identidad de Windows (nombre, SID y equipo) en el evento y no pone usuario de GPOS en la fila.
- La segunda escritura usa una conexión sin pool, con tipos y largos de columna (ADR-50), y la condición `WHERE Id = 1`. Si falta la fila de la empresa, falla y no inserta.
- El 409 `RNC_SOLO_SUPER` vale también para el SUPER, de modo que la configuración nunca cambia el RNC sin dejar la fila.

## 6. Remediaciones priorizadas

| Orden | ID | Acción | Esfuerzo [I] | Cuándo |
|---|---|---|---|---|
| 1 | RN-02 | Lista de excepciones (o `--aceptar-digito` con confirmación y marca en el evento) y la misma validación en la primera asignación | 0,2 a 0,3 dp | Antes de unir RN |
| 2 | RN-01 | Aviso al SUPER en S-01 o Diagnóstico con marca «visto hasta», que también cubre los verbos de `sellos` | 0,25 dp | Antes del corte de diciembre; condición abierta de DL-03 |
| 3 | RN-03 | `Pooling = false`, bloqueo dentro del `try` y 409 `CAMBIO_RNC_EN_CURSO` | 0,1 dp | Con RN o con el PR que mapee S-03 |
| 2b | RN-04 | Opción (a) de RN-F2, prueba con renovación y marca de la fila ausente | 0,1 a 0,15 dp | Lo firma el propietario; se aplica antes de unir RN |
| 5 | RN-05 | Enmascarar dígitos en el motivo del evento y avisarlo en la ayuda | 0,05 dp | Con RN |
| 6 | RN-06 | Precisión de DL-03 para la firma del propietario | — | Lo decide el arquitecto maestro |

Total: entre 0,7 y 0,85 dp [I].

## 7. Recomendación

**Aprobado con observaciones.** No hay hallazgos Críticos ni Altos. El objetivo central de la pieza se cumple: no hay ninguna vía de la aplicación para cambiar el RNC fijado sin la fila MAC, y el motor falla cerrado ante cualquier otro cambio.

Condiciones recomendadas:
- RN-02 antes de unir. Es barato y evita dejar sin salida a un cliente real.
- RN-01 cerrado o anotado como condición abierta de DL-03 con fecha anterior al corte.
- RN-04: firmar RN-F2 en la opción (a) y aplicarla antes de unir, porque sin ella el verbo permite usar la licencia con otro RNC de forma indefinida.

Es una recomendación técnica; la decisión es del propietario.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\revision-seguridad-rn-cambio-rnc-2026-10-17.md`
- Supuestos:
  - No compilé ni ejecuté pruebas: el árbol es de solo lectura.
  - Las listas de excepciones de python-stdnum [I].
  - El comportamiento de `sp_reset_connection` con los bloqueos de aplicación de sesión [I].
  - Los esfuerzos en dp [I].
- Decisiones candidatas a ADR: precisión de P-3 (RN-04, igual a RN-F2 del arquitecto: recomiendo la opción (a)) y precisión de DL-03 sobre la primera asignación (RN-06), ambas como precisiones de ADR-59 / DL-03, no como ADR nuevos.
- Entregas a otros agentes:
  - desarrollador-backend → RN-02, RN-03 y RN-05, y la superficie de RN-01.
  - desarrollador-frontend → el aviso de RN-01 y el RNC de solo lectura (ajuste de pantalla de DL-03).
  - arquitecto-maestro → llevar RN-F2 a la hoja con este dictamen (Media; la opción (a) lo cierra en la aplicación; el residual es el borrado por SQL, dentro de CP-4), y RN-06.
  - qa-automatizado → prueba de RN-F2 con la renovación de por medio.
  - qa-automatizado → una prueba con un RNC de la lista de excepciones y otra de fuga del bloqueo con una conexión sin pool.
- Próximo paso recomendado: firmar RN-F2 en la opción (a); corregir RN-02, RN-04, RN-03 y RN-05 en `a/rn-cambio-rnc`, y fijar dónde y cuándo entra el aviso de RN-01.
