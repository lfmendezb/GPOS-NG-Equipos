# Informe de seguridad: SL-F1 (a) y SL-F2 (b): liberación del candado CR-01 y `sellos --resellar`

- **Fecha:** 2026-10-17 · **Auditor:** auditor-seguridad (v3.1.0)
- **Árbol:** `GPOS-NG-slf`, rama `a/sl-resellar-candado`, `git diff da474174..bc67ec9d`: `d03f4c3f` (código y pruebas, 11 archivos) y `bc67ec9d` (procedimiento `docs/operaciones/2026-10-17-restauracion-gpos-sysdata-cuentas-fuera-del-padron.md`). HEAD verificado: `bc67ec9d`.
- **Referencias:** `[SL]` revision-seguridad-sl-sello-padron-2026-10-17.md (SL-01, SL-02); `[VAL]` validacion-sl-sello-padron-2026-10-17.md (§7 SL-F1 y SL-F2); `[ADR]` `origin/master:docs/adr/ADR-083.md` (punto 7 y precisiones del 2026-10-17).
- **Modo:** solo lectura. No compilé ni ejecuté pruebas. [V] = verificado por lectura del código; [I] = inferido.
- **Recomendación técnica:** **Aprobado con observaciones**. Pendiente de firma del propietario (C2).

---

## 1. Alcance y superficie revisada

| Superficie | Archivos |
|---|---|
| Liberación del candado CR-01 (solo el SUPER, ya existente) | `RestauracionSistemaService.cs` (`LiberarAsync`, `CuentasFueraDePadronAsync`, `Recuperacion`); `Cuentas.cs:156-157`; `BitacoraSeguridad.cs:26` |
| Verbo de servidor `sellos --resellar` (requiere el anillo) | `ComandoSellos.cs:105-114`, `:208-243`; `GPOS.Migracion/Program.cs` (bandera y ayuda) |
| Núcleo del resellado | `SellosService.cs:28-37` (`EstadoResellado`), `:235-321` |
| Padrón (sin cambios de lógica) | `PadronSellos.cs:53-54`, `:65-66` (constantes); comportamiento de `TomarAsync`, `Crear`, `Resolver` y `TrasConfirmar` |
| Pruebas | `SellosReselladoTests.cs` (10), `SellosRestauracionTests.cs` (2), `SellosEnLaApiTests.La_API_nunca_resella` |
| Procedimiento | `docs/operaciones/2026-10-17-restauracion-gpos-sysdata-cuentas-fuera-del-padron.md` |

Modelo de amenazas: el de `[SL]` §1. Un `sysadmin` de SQL **sin** acceso al disco del servidor ni al anillo no debe poder ampliar el cupo ni legitimar cuentas. Un administrador de Windows con el anillo es el residual aceptado R-S2 / CP-4 («no se impide: se detecta»).

### Verificación de lo que declara el desarrollador

| Declaración | Resultado | Evidencia |
|---|---|---|
| **SL-F1.** La respuesta trae `CuentasFueraDePadron` y `Recuperacion` | Verificado | `Cuentas.cs:156-157`; `RestauracionSistemaService.cs:122` |
| Evento propio `CUENTAS_FUERA_DE_PADRON` con el número (I si es 0; A si hay cuentas o si no se pudo contar) | Verificado | `BitacoraSeguridad.cs:26`; `RestauracionSistemaService.cs:119-121` |
| El conteo va después de confirmar la liberación y devuelve null si falla | Verificado, **con una salvedad**: el registro del evento que sigue al conteo no está protegido (SLF-05) | `:98-115` (liberación y `candado.Actualizar`), `:117`, `:131-141` |
| No sella nada | Verificado. Solo llama a `CuentasSinSelloAsync`, que lee. Su lectura del padrón puede reponer la base desde el disco (`PADRON_RETROCEDIDO`), que es lo que exige SEG-L2-07 | `SellosService.cs:70-92`; prueba de arquitectura `SellosEnLaApiTests` (sin `TomarAsync`, `Sellar*`, `Legitimar*` ni `Resellar*` en el servicio) |
| **SL-F2.** 409 `PADRON_VERIFICA` si verifica el padrón de la base o del disco, si el archivo existe y no se lee, o si `InstalacionId` no verifica | Verificado en el servicio (`SellosService.cs:244-253`, `:274-279`, `:303-317`). **Dos matices:** (i) en el verbo, un `InstalacionId` que no verifica se rechaza antes en `ExigirAnilloAsync` con un error sin el código 409 (`ComandoSellos.cs:108` → `:275-277`), con el mismo código de salida 1; (ii) «existe pero no se lee» no siempre falla cerrado (SLF-02) | — |
| Con `--confirmar`: transacción serializable, **solo las habilitadas**, padrón en versión 1 en la base y en el disco, `PADRON_RESELLADO` con cuenta, SID, equipo y motivo, visible en S-05 | Verificado. La versión 1 sale de `Crear()` con `Actual` nulo (`PadronSellos.cs:156`) y `GuardarAsync` (+1, `:165`). El disco se escribe después del commit (`SellosService.cs:293-294`). El actor es canal `CONSOLA` con SID y equipo (`ComandoSellos.cs:37-51`), severidad A: entra en el filtro de S-05 | `SellosService.cs:269-292`; prueba `Con_confirmar_sella_solo_las_habilitadas_y_deja_el_evento_critico` |
| Exceso de cupo: el indicador `EnExceso` ya existía y las altas se rechazan porque el consumo supera el cupo | Verificado | `LicenciaEndpoints.cs:148` (`consumidos > cupo`); `SellosService.cs:329-333` (`ExigirCupo`); prueba `Si_superan_el_cupo_...` |
| Idempotente | Verificado en efectos: repetirlo da 409 y no cambia versión, sellos ni eventos. Sale con 1 | prueba `Repetirlo_no_cambia_nada`; `GPOS.Migracion/Program.cs:142-146` |
| Igual en Debug y Release; solo `GPOS.Migracion`; la API nunca resella | Verificado: no hay `#if` en el diff y nada en `src/GPOS.Api` lo llama. La garantía descansa en una prueba de texto (SLF-07) | `SellosEnLaApiTests.cs` (nueva prueba) |
| No reescribe `Licencia.SelloInicial` y no exige `--acta` | Verificado. Ver los dictámenes (2) y (3) y SLF-03 y SLF-04 | — |

---

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título |
|---|---|---|
| SLF-01 | Media | `--resellar` no distingue la pérdida del anillo de la destrucción del padrón: con el anillo intacto, borrar el disco y dañar la fila basta para legitimar cuentas creadas por SQL y recuperar el cupo |
| SLF-02 | Baja | La comprobación del disco no falla cerrada si el archivo no se puede ver (`File.Exists`), y mira la carpeta de `GPOS.Migracion`, no la de la API |
| SLF-03 | Baja | Sin reescribir `Licencia.SelloInicial`, la API en Release registra en cada arranque un `SinSelladoInicial` (5142) falso después de un resellado legítimo, y se pierde el ancla para SLF-01 |
| SLF-04 | Baja | Falta el acta que exige el texto firmado de ADR-83, punto 7 |
| SLF-05 | Baja | SL-F1: si el registro del evento falla después de liberar, la respuesta es 500 con el candado ya liberado; el número mezcla motivos y la recuperación no menciona la purga |
| SLF-06 | Baja | El procedimiento contiene una pista de abuso, describe un camino que el verbo rechaza y omite la purga y el cambio de contraseña |
| SLF-07 | Baja | «La API nunca resella» depende de una prueba de texto: `SellosService.ResellarAsync` es público en un ensamblado que la API referencia |

No hay hallazgos Críticos ni Altos.

---

## 3. Checklist OWASP (Top 10 2021)

| Categoría | Resultado |
|---|---|
| A01 Control de acceso roto | El verbo exige el anillo (`ExigirAnilloAsync`) y la liberación es solo del SUPER (sin cambios). Observaciones: SLF-01 y SLF-07 |
| A02 Fallas criptográficas | Sin cambios de criptografía. El padrón nuevo usa el mismo propósito y la misma instalación. Sin hallazgos |
| A03 Inyección | No hay SQL nuevo con texto concatenado: EF y Dapper con parámetros. Sin hallazgos |
| A04 Diseño inseguro | SLF-01 (condición de entrada del resellado), SLF-03 |
| A05 Configuración insegura | SLF-02 (la carpeta de la licencia sale de la configuración de `GPOS.Migracion`) |
| A06 Componentes vulnerables | No aplica: no hay paquetes nuevos |
| A07 Identificación y autenticación | Sin cambios en el inicio de sesión. El procedimiento devuelve contraseñas del respaldo sin forzar el cambio (SLF-06) |
| A08 Integridad de software y datos | SLF-01 (la versión del padrón vuelve a 1), SLF-04 |
| A09 Registro y monitoreo | Eventos `CUENTAS_FUERA_DE_PADRON` y `PADRON_RESELLADO` correctos y sin secretos. Observaciones: SLF-01 (la única evidencia está en la base) y SLF-05 |
| A10 SSRF | No aplica |

---

## 4. Hallazgos

### SLF-01 · Media · `--resellar` no distingue la pérdida del anillo de la destrucción del padrón

- **Riesgo.**
  - La regla firmada es «solo si ni la base ni el disco tienen un padrón que verifique con el anillo vigente». El código la cumple al pie de la letra, pero trata igual «no verifica porque se perdió la llave» que «no existe porque alguien lo borró».
  - Con el **anillo intacto** basta con: dañar o borrar la fila `Licencia.PadronSellos` (SQL), borrar el archivo `padron` (Windows) y ejecutar `sellos --resellar --confirmar`. Resultado:
    - toda fila habilitada queda sellada, también las insertadas por SQL (SH-5);
    - las cuentas de antes de una reducción de cupo vuelven a entrar (SEG-L2-07), porque `EnExceso` solo impide **nuevas** altas y nadie pierde la sesión;
    - la licencia sigue siendo válida (el `InstalacionId` es el mismo).
  - **Un `sysadmin` de SQL solo no puede hacerlo** [V]:
    - si daña la fila de la base, el disco verifica, la API lo repone (`PadronSellos.cs:351`) y el verbo se niega (`SellosService.cs:251`, prueba `Se_niega_si_solo_el_padron_del_disco_verifica`);
    - borrar el archivo exige Windows: la DACL de la carpeta es SYSTEM, Administradores y la cuenta del servicio (`AlmacenLicenciaDisco.cs:100-108`);
    - el verbo exige además el anillo, que tiene la misma DACL (`CarpetaAnillo.cs:49-74`).
    - Excepción [I]: si el servicio de SQL Server corre como LocalSystem, `xp_cmdshell` podría borrar el archivo. Aun así, haría falta el anillo para ejecutar el verbo.
  - **Por qué no es Alta:**
    - exige un administrador de Windows con el anillo, que es el residual aceptado R-S2;
    - ese actor ya puede legitimar cuentas con unas pocas líneas que llamen a las API públicas de `GPOS.Core`, por ejemplo `LegitimarAsync` con un `IEstadoLicencia` de cupo alto;
    - el resellado no le da una capacidad nueva: le da un **comando soportado**, sin programar;
    - hoy no hay instalaciones de cliente, y la firma fija el verbo para «antes de la primera licencia de pago».
  - **Lo que sí empeora:**
    - R-S2 exige detección, y la única evidencia es `PADRON_RESELLADO` en `dbo.BitacoraSeguridad`, que el mismo actor puede borrar;
    - la versión del padrón vuelve a 1, así que no queda rastro de la continuidad;
    - además, un respaldo anterior de la base con el mismo anillo y una versión mayor volvería a ganar al padrón resellado (`Resolver`, «prevalece la mayor versión»).
  - **El caso legítimo es estrecho.** Si se pierde el anillo, `Licencia.InstalacionId` deja de verificar. `sistema` no la reemplaza (`ComandoSistema.cs:146-149`) y el verbo se niega. Para llegar al resellado hay que generar una instalación nueva, y eso invalida la licencia, que va ligada a la instalación (`LectorContenidoLicencia.cs:192`). Es decir: **en el caso legítimo GSF ya interviene**, porque emite la licencia nueva. En el caso abusivo, no.
- **Evidencia.** `SellosService.cs:244-253` (condiciones: instalación, base y disco; ninguna mira `Licencia.SelloInicial` ni las licencias aceptadas); `:306` (archivo ausente = se puede); `:280` y `PadronSellos.cs:156` (versión desde 0); `ComandoSellos.cs:239` (sin autorización externa).
- **Remediación.**
  1. **En este PR (≈0,05 dp; USD 0):** negarse si `Licencia.SelloInicial` existe y **verifica** con el anillo y la instalación vigentes. Eso prueba que el anillo con el que se selló la instalación sigue ahí, así que el padrón no se perdió por la llave: se destruyó. La salida en ese caso es `--legitimar`, o GSF. Negarse también si `SelloInicial` falta y hay alguna licencia aceptada (en la base o en `Procesados`), por la misma razón. Mensaje genérico, sin explicar qué condición faltó (C10).
  2. **Antes de la primera licencia de pago (≈0,5 dp del desarrollador y ≈0,25 dp para la herramienta de GSF; USD 0):** el «acta» de ADR-83, punto 7, como **autorización firmada por GSF** con la misma llave ECDSA de las licencias: instalación, vencimiento corto (por ejemplo, 72 h), número de serie y cupo vigente. Se verifica con la llave pública incluida en el binario y se registra su serie en el evento. Es el único control que un administrador con el anillo no puede fabricar, y cuesta poco porque GSF ya emite la licencia nueva en el caso legítimo. Coincide con (b+) de ADR-81 para el perfil Avanzada.
  3. **Detección (≈0,1 dp):** `GPOS.Migracion` escribe también un evento en el registro de eventos de Windows (`EventId` propio). El resellado (fecha y cuentas) se incluye en la solicitud o instantánea de licencia que llega a GSF (L-06/L-07), que es la única evidencia fuera del alcance del actor.
  4. Prueba: con el anillo intacto, dañar la fila y borrar el disco → 409.
- **Alternativa descartada:** distinguir por el identificador de llave del blob de Data Protection («la llave no está en el anillo» frente a «el MAC falla»). Es elegante, pero el actor que tiene el anillo puede fabricar un blob protegido con otra llave. No añade nada frente al punto 1 y complica el código.

### SLF-02 · Baja · La comprobación del disco puede no fallar cerrada y mira otra carpeta

- **Riesgo.**
  - `DiscoAsync` empieza con `File.Exists(ruta)`. En .NET, `File.Exists` devuelve `false` también cuando el proceso **no tiene permiso** sobre la carpeta, no solo cuando el archivo falta. En ese caso el verbo trata el padrón del disco como inexistente, aunque exista y verifique.
  - La regla declarada, «existe pero no se lee → se niega», solo se cumple cuando la carpeta es visible y el archivo está bloqueado. Ese es el caso que prueba `Se_niega_si_el_disco_no_se_puede_leer`, con `FileShare.None`.
  - La ruta sale de la configuración de `GPOS.Migracion` (`Carpeta(config)`), no de la de la API: es el mismo problema de SL-01. Con una carpeta distinta, el verbo «no ve» el padrón real.
  - Consecuencia [I]: no es una evasión. La API seguiría viendo su disco con una versión mayor, lo repondría (`PADRON_RETROCEDIDO`) y desharía el resellado, y las cuentas quedarían fuera. Es confusión y pérdida de servicio en un procedimiento de emergencia.
- **Evidencia.** `SellosService.cs:306`; `ComandoSellos.cs:110-111`.
- **Remediación (≈0,05 dp).**
  - Abrir el archivo directamente. Solo `FileNotFoundException` cuenta como «no existe»; `DirectoryNotFoundException`, `UnauthorizedAccessException` o cualquier otra `IOException` dan el 409.
  - Exigir que la carpeta exista y se pueda listar.
  - Mientras devops no fije la misma clave para los dos procesos (entrega de SL-01), el verbo se niega si la carpeta no es la predeterminada y no se indicó de forma explícita con `--carpeta-licencia`.

### SLF-03 · Baja · `Licencia.SelloInicial` sin reescribir: 5142 falso en cada arranque y sin ancla

- **Riesgo.**
  - En el caso legítimo (instalación nueva), la fila `SelloInicial` vieja ya no verifica. Después del resellado, `EstadoSelladoInicialAsync` da `Hecho = false` («existe y no verifica»), y la API en Release registra **en cada arranque** el evento crítico 5142 `SinSelladoInicial`. Ese evento manda a ejecutar `sistema --cuentas-iniciales --confirmar-sellado`, que después se niega.
  - Es ruido crítico permanente con una instrucción equivocada: fatiga de alertas.
  - Sin una fila que verifique con el anillo nuevo, la defensa del punto 1 de SLF-01 desaparece **después del primer resellado**: cualquier resellado posterior vuelve a estar permitido.
- **Evidencia.** `SellosService.cs:165-169`; `Inicializacion.cs:59-65`.
- **Remediación (≈0,05 dp).** Ver el dictamen (2).

### SLF-04 · Baja · Falta el acta de ADR-83, punto 7

- **Riesgo.** El texto firmado dice «`sellos --resellar --motivo`, **con acta**», y la precisión del 2026-10-17 aclara que «el texto firmado de arriba no cambia». El verbo no la pide, y el procedimiento propone anotarla dentro del motivo (`…cuentas-fuera-del-padron.md:91`). Así no se puede comprobar que esté presente, y se mezcla con el texto libre. Como texto, el acta es trazabilidad, no un control (el control es el punto 2 de SLF-01).
- **Evidencia.** `ComandoSellos.cs:105-114` (sin `--acta`); `[ADR]` punto 7.
- **Remediación (≈0,05 dp).** Ver el dictamen (3).

### SLF-05 · Baja · SL-F1: falla del evento después de liberar, número mezclado y recuperación incompleta

- **Riesgo.**
  - `bitacora.RegistrarAsync(CUENTAS_FUERA_DE_PADRON)` corre **después** de confirmar la liberación y sin `try`. Si la escritura falla (tiempo de espera o bloqueo de la bitácora), el SUPER recibe 500 aunque el candado ya quedó liberado. Si reintenta, recibe 409 `SISTEMA_NO_RESTAURADO` y no ve el número. No tiene efectos sobre la seguridad, pero contradice «el conteo no deshace ni rompe la liberación».
  - El número es el total de S-01: habilitadas sin sello, inhabilitadas que siguen en el padrón y entradas sin fila (`FilaAusente`). Se presenta como «cuentas fuera del padrón». Tras una restauración, las `FilaAusente` (cuentas creadas después del respaldo) **ocupan cupo** y se resuelven con `--purgar`, no con `--legitimar`. El texto de `Recuperacion` solo nombra la legitimación, así que el técnico puede chocar con `LICENCIA_CUPO_AGOTADO` sin saber por qué.
  - **Filtración: ninguna** [V]. La respuesta es solo para el SUPER autenticado, que ya ve S-01. El texto nombra el verbo y la ruta pública de S-01, sin rutas de disco, versiones ni secretos. La excepción del conteo se traga sin exponer su mensaje.
  - **Efectos:** solo la reposición del padrón desde el disco, que es la de SEG-L2-07 [V].
  - Si en el futuro se registra `RestauracionSistemaService` sin `SellosService`, el conteo da null sin aviso. Hoy se resuelve, porque el parámetro es opcional y el servicio está registrado (`Program.cs:185`, `:259`).
- **Evidencia.** `RestauracionSistemaService.cs:115-122`, `:144-151`; `SellosService.cs:85-90`.
- **Remediación (≈0,05 dp).**
  - Envolver el registro en `try`/`catch` con `LogError`.
  - Devolver el número desglosado (`FueraDePadron`, `InhabilitadaEnPadron` y `FilaAusente`) o, como mínimo, agregar a `Recuperacion` la purga de las `FilaAusente`.
  - Una prueba que resuelva el servicio desde el contenedor de la API.

### SLF-06 · Baja · El procedimiento: pista de abuso, camino imposible y omisiones

- **Riesgo.**
  - **Línea 98:** «borrar el archivo `padron` deja a `sellos --resellar` en condiciones de crear un padrón desde las filas». Es inexacto, porque con la base restaurada el padrón de la base verifica y el verbo se niega. Y además le indica al lector que el disco es la mitad de lo que bloquea el resellado. Un documento de operación no debe describir qué condiciones hay que romper.
  - **Líneas 72-80:** dice que el resellado es «la salida cuando se perdió el anillo», pero a la vez que se niega si `InstalacionId` no verifica, y con el anillo perdido nunca verifica. El procedimiento no dice cuál es el camino real: recuperación anclada o, si falla, instalación nueva con licencia nueva de GSF. Un técnico bajo presión podría «resolverlo» borrando por SQL la fila `Licencia.InstalacionId`, una práctica que invalida la licencia y que nadie autorizó.
  - **Falta la purga:** no hay ningún paso para las `FilaAusente` (SLF-05).
  - **Contraseñas del respaldo** (líneas 28 y 62): la cuenta legitimada entra con la contraseña del respaldo, y el procedimiento dice «si hace falta, se la restablece». Si la contraseña se cambió **porque** estaba comprometida, la restauración la revive.
  - Lo positivo: insiste en no borrar el `padron`, no editar por SQL y no usar `--resellar` tras una restauración (líneas 17 y 93-100). Es correcto.
- **Evidencia.** `docs/operaciones/2026-10-17-restauracion-gpos-sysdata-cuentas-fuera-del-padron.md:28`, `:62`, `:72-80`, `:91`, `:98`.
- **Remediación (≈0,1 dp, documentador).**
  - Línea 98: «borrarlo no recupera ninguna cuenta y queda registrado como `PADRON_DISCO_AUSENTE`», sin mencionar el resellado.
  - Sección del resellado: «solo con la autorización de GSF tras una pérdida del anillo que la recuperación anclada no resolvió; nunca se edita `Licencia.InstalacionId`». Que no enumere las condiciones de rechazo: basta «se niega si hay un padrón válido».
  - Agregar el paso de la purga de las `FilaAusente`.
  - Tras legitimar, **restablecer siempre** la contraseña de toda cuenta que la haya cambiado después del respaldo, empezando por el SUPER.

### SLF-07 · Baja · «La API nunca resella» depende de una prueba de texto

- **Riesgo.** `SellosService.ResellarAsync` es `public` en `GPOS.Core`, que la API referencia y registra (`Program.cs:259`). La única barrera es `La_API_nunca_resella`, que busca la cadena `ResellarAsync` en `src/GPOS.Api`. Una llamada por reflexión, por delegado o desde otro ensamblado intermedio no la detecta. Hoy no hay ninguna [V].
- **Evidencia.** `SellosService.cs:265`; `SellosEnLaApiTests.cs` (prueba nueva).
- **Remediación (≈0,05 dp).** Hacer `internal` a `ResellarAsync` (y a `EstadoReselladoAsync` si no lo usa nadie más), con `InternalsVisibleTo` solo para `GPOS.Migracion` y `GPOS.Tests`. El compilador lo garantiza. Se conserva la prueba de texto como respaldo.

### Comprobaciones pedidas expresamente

1. **¿Se puede usar `--resellar` para recuperar el cupo o legitimar cuentas creadas por SQL?**
   - Un `sysadmin` de SQL **solo**: **no** [V]. El disco verifica y prevalece, y el verbo exige el anillo.
   - Un `sysadmin` que **daña los dos padrones**: necesita Windows para el disco y el anillo para el verbo. Con eso, **sí** (SLF-01). Ese es el residual R-S2: el verbo no da una capacidad nueva, pero la vuelve un comando. Remediación: SLF-01, puntos 1 a 3.
   - Tras una **restauración legítima**: no. El disco verifica y el verbo se niega (prueba `Se_niega_si_solo_el_padron_del_disco_verifica`).
2. **¿Alguna vía de la API o de Release que reselle?** **No** [V]. Ningún archivo de `src/GPOS.Api` lo llama. `RestauracionSistemaService` no llama a ningún método que escriba el padrón, y no hay `#if DEBUG` en el resellado. El arranque en Debug sigue limitado al sellado inicial (`Inicializacion.cs`), que no se dispara con un `SelloInicial` presente. Refuerzo: SLF-07.
3. **Carreras.**
   - **Resellado contra resellado:** las condiciones se vuelven a comprobar con el padrón tomado (`UPDLOCK, HOLDLOCK`) en serializable (`SellosService.cs:269-279`). El segundo ve el padrón confirmado por el primero y se niega, o pierde por interbloqueo (1205) sin escribir nada. Lo cubre `Dos_resellados_a_la_vez_dejan_un_solo_padron`, con la fila presente. Con la fila **ausente**, el bloqueo es de rango sobre la clave y se espera el mismo resultado [I]. Conviene una variante de la prueba con la fila borrada (QA).
   - **Resellado contra API:** mientras no hay padrón, la API responde `PADRON_NO_DISPONIBLE` y no escribe. Sus escrituras esperan el bloqueo y, al entrar, leen el padrón nuevo. Entre el commit y la escritura del disco, la lectura de la API elige la base (v1, que verifica) y escribe en el disco el mismo texto: no se pierde nada, y con la versión 1 no salta `PADRON_DISCO_AUSENTE` (`PadronSellos.cs:290`). Si las dos escrituras del disco chocan, una falla y la otra deja el mismo contenido [I].
4. **¿El conteo de SL-F1 filtra información o tiene efectos?** No filtra nada: el destinatario es el SUPER y la información es la de S-01. Su único efecto es la reposición desde el disco de SEG-L2-07. Observaciones: SLF-05.
5. **¿El procedimiento induce a borrar el `padron` u otra práctica insegura?** No induce a borrarlo: lo prohíbe de forma explícita. Pero tiene una frase que sirve de pista, un camino imposible que puede empujar a editar `Licencia.InstalacionId` y omisiones (SLF-06).

---

## 5. Controles bien implementados

- La liberación no sella ni reconcilia nada, con prueba de punta a punta sobre un respaldo y una restauración reales (`SellosRestauracionTests`) y prueba de arquitectura.
- El resellado vuelve a comprobar todas las condiciones **dentro** de la transacción serializable, con el padrón tomado (no solo antes).
- Sella solo las habilitadas. Las inhabilitadas no se tocan y su rehabilitación pasa por la legitimación y el cupo.
- Muestra la lista, el consumo, el cupo y el exceso antes de `--confirmar`, y sin él sale con 2 sin escribir nada.
- Evento crítico con la cuenta y el SID de Windows, el equipo, el motivo y el detalle del exceso, en canal `CONSOLA` y severidad A, visible en S-05.
- Un archivo bloqueado falla cerrado. Un `InstalacionId` ajeno se rechaza.
- El exceso reutiliza el cálculo existente (`consumidos > cupo`) y `ExigirCupo`, sin un segundo camino.
- Los mensajes no llevan secretos, hashes ni contenido del sello.

---

## 6. Dictámenes sobre los puntos que dejó el desarrollador

**(2) ¿Debe `--resellar` reescribir `Licencia.SelloInicial`?** **Sí.**
- En la misma transacción, después de crear el padrón: `FilaSelloInicial` protegida con el anillo y la instalación vigentes, con `Origen = "RESELLADO"`, la fecha y el número de cuentas.
- Así se elimina el 5142 falso (SLF-03) y la fila vuelve a ser el ancla de «el anillo con que se selló sigue aquí», que impide los resellados siguientes (SLF-01, punto 1).
- No reabre el sellado inicial: SH-7 sigue exigiendo que no haya padrón.
- *Descartado:* una fila nueva `Licencia.Resellado`. Duplica las lecturas y deja la vieja `SelloInicial` sin verificar, con el mismo 5142.
- *Descartado:* no tocarla. El ruido crítico es permanente y no hay ancla.

**(3) ¿Exige `--acta` aparte?** **Sí.**
- ADR-83, punto 7, lo dice y la precisión no lo cambió.
- Ahora: `--acta <referencia>` obligatoria (de 6 a 60 caracteres, sin caracteres de control), en su propio campo del detalle del evento, aparte del motivo.
- Es trazabilidad. El control real es la **autorización firmada por GSF** (SLF-01, punto 2), que se exige antes de la primera licencia de pago y que puede sustituir al texto (`--acta <archivo firmado>`).
- *Descartado:* el acta dentro del motivo, como hoy. No se puede comprobar que esté.

**(4) ¿Repetirlo sale con 0 o con 1?** **Con 1, como ahora.**
- El 409 `PADRON_VERIFICA` es la misma respuesta para una repetición inocua y para un uso indebido con un padrón válido. Si saliera con 0, un script lo tomaría por un éxito y se perdería la señal.
- La idempotencia que importa es la de los efectos (ninguno), y está probada. El mensaje ya dice «No se cambió nada».
- *Descartado:* salir con 0 si el padrón vigente es la versión 1 y hay un `PADRON_RESELLADO` reciente. Depende de una bitácora que se puede borrar, y complica el verbo sin ganar nada.

---

## 7. Remediaciones priorizadas

| Prioridad | Acción | Hallazgo | Responsable | Esfuerzo | Momento |
|---|---|---|---|---|---|
| 1 | Negarse con `SelloInicial` que verifica, o sin él y con una licencia aceptada; reescribir `SelloInicial` con `RESELLADO` | SLF-01 (1), SLF-03 | Desarrollador I | 0,1 dp | En este PR |
| 2 | `--acta` obligatoria en su propio campo | SLF-04 | Desarrollador I | 0,05 dp | En este PR |
| 3 | Lectura del disco que falla cerrada; carpeta explícita | SLF-02 | Desarrollador I | 0,05 dp | En este PR |
| 4 | Correcciones del procedimiento | SLF-06 | Documentador técnico | 0,1 dp | En este PR |
| 5 | `try` del evento, desglose y purga en `Recuperacion`; `internal` + `InternalsVisibleTo` | SLF-05, SLF-07 | Desarrollador I | 0,1 dp | En este PR o en el siguiente |
| 6 | Autorización firmada por GSF; evento en el registro de Windows y en L-06/L-07 | SLF-01 (2) y (3) | Desarrollador I y L; GSF | ≈0,85 dp | **Antes de la primera licencia de pago** (igual que la firma SL-F2 (b)) |

Total en este PR: unos 0,4 dp y USD 0.

---

## 8. Recomendación

**Aprobado con observaciones** (recomendación técnica; pendiente de firma del propietario).
- No hay hallazgos Críticos ni Altos. SL-F1 (a) y SL-F2 (b) están implementadas como se firmaron, y lo declarado por el desarrollador es cierto, con los matices de §1.
- SLF-01 no bloquea mientras no haya instalaciones de cliente. Sus puntos 2 y 3 son **condición previa a la primera licencia de pago**, junto con el verbo. Recomiendo los puntos baratos (prioridades 1 a 4) en este PR.
- No ejecuté pruebas. La aprobación supone que la suite oficial y las 12 pruebas nuevas pasan en la validación de B o de C.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\revision-seguridad-sl-f1-f2-2026-10-17.md`
- Supuestos: no compilé ni ejecuté pruebas; el bloqueo de rango con la fila del padrón ausente, el choque de escrituras del disco, el borrado vía `xp_cmdshell` con SQL Server como LocalSystem y el efecto de una carpeta distinta (SLF-02) son [I]; «hoy todo es desarrollo» (memoria del proyecto) para graduar SLF-01.
- Decisiones candidatas a ADR: precisión de ADR-83, punto 7. (i) El resellado se niega si `Licencia.SelloInicial` verifica, o si falta y hay una licencia aceptada, y reescribe `SelloInicial` con origen `RESELLADO`. (ii) El «acta» es, antes de la primera licencia de pago, una autorización firmada por GSF ligada a la instalación. Alternativa descartada: distinguir por el identificador de llave del blob (lo puede fabricar quien tiene el anillo).
- Entregas a otros agentes: desarrollador I → SLF-01 (1), SLF-02, SLF-03, SLF-04, SLF-05 y SLF-07; documentador técnico → SLF-06; desarrollador L y GSF → autorización firmada y reporte del resellado en L-06/L-07 (SLF-01 (2) y (3)); devops → la misma `GPOS:Licencia:Carpeta` para la API y `GPOS.Migracion` (pendiente de SL-01); qa-automatizado → resellado concurrente con la fila del padrón borrada, y resellado con el anillo intacto, la fila dañada y el disco borrado (debe dar 409 tras SLF-01); Arquitecto Maestro → llevar la precisión de ADR-83, punto 7, a firma.
- Próximo paso recomendado: el desarrollador I aplica las prioridades 1 a 3 y el documentador la 4 en `a/sl-resellar-candado`, y después la validación de B.
