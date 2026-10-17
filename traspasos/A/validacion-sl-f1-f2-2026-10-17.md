# Validación de SL-F1 (a) y SL-F2 (b): aviso de la liberación del candado y `sellos --resellar`

**Fecha:** 2026-10-17 · **Valida:** arquitecto-software (equipo A) · **Rama:** `a/sl-resellar-candado`, árbol `GPOS-NG-slf`, `git diff da474174..bc67ec9d` (commits `d03f4c3f` y `bc67ec9d`; 12 archivos, +729 / −9)
**Fuentes:**
- mi validación de SL, `validacion-sl-sello-padron-2026-10-17.md`, §4 puntos (1) y (5) y §7;
- ADR-83 en `origin/master`, precisiones del 2026-10-17 (SL-F1 (a) y SL-F2 (b), con sus reglas);
- blueprint `blueprint-licencia-lote2-2026-10-14.md`, §2.3, §2.5 R-S1 y §4.3;
- ADR-58, punto 9 (en exceso);
- la rama `origin/c/adr81-fase-a` (`4e5bc446`).

**Método:**
- Solo lectura del diff y del código que lo rodea.
- Simulación de la unión con la rama de C mediante `git merge-tree` en su forma antigua, que solo imprime y no escribe.
- **No compilé ni ejecuté pruebas.**
- *[V]* = verificado en el código; *[I]* = inferido.

---

## 1. Veredicto

**Conforme con correcciones.** Lo firmado está construido.

**SL-F1 (a).** La liberación del candado CR-01:
- cuenta las cuentas de S-01;
- las informa en la respuesta (`cuentasFueraDePadron`, `recuperacion`) y en un evento propio;
- no sella ni reconcilia nada. Lo comprueba una prueba con un respaldo y una restauración reales.

**SL-F2 (b).** `sellos --resellar`:
- solo funciona si `Licencia.InstalacionId` verifica y ningún padrón verifica, ni el de la base ni el del disco. Un disco que no se puede leer también lo impide;
- vuelve a comprobarlo con el padrón tomado, en una transacción serializable;
- muestra la lista y pide `--confirmar` y el motivo;
- sella solo las cuentas habilitadas;
- deja `PADRON_RESELLADO` con la cuenta, el SID y el equipo, y el evento se ve en S-05;
- si las cuentas superan el cupo, se sellan igual y la empresa queda en exceso;
- tiene diez pruebas, entre ellas una de concurrencia.

Hay **cuatro correcciones obligatorias antes del PR** (sección 5), todas pequeñas (≈ 0,25 dp en total). **Nada va a firma** (sección 7).

## 2. Conformidad con lo firmado

| Regla firmada | Resultado | Evidencia |
|---|---|---|
| SL-F1: restaurar no devuelve las cuentas de forma automática; la liberación no sella | Conforme | `RestauracionSistemaService.cs:117-123` solo lee (`CuentasSinSelloAsync`). La prueba de arquitectura prohíbe `SellarAsync`, `LegitimarAsync`, `TomarAsync` y otros en ese archivo (`SellosEnLaApiTests.La_API_nunca_resella`). `SellosRestauracionTests` compara los sellos y la versión del padrón antes y después |
| SL-F1: la liberación informa cuántas quedaron fuera | Conforme, con C-1 | `ResultadoLiberacionSistema` (`Cuentas.cs:153-157`), evento `CUENTAS_FUERA_DE_PADRON` (A si hay alguna, I si no hay ninguna). Si no se pueden contar, el valor es null y el candado ya quedó liberado: correcto, el conteo no deshace la liberación |
| SL-F1: legitimar cuenta por cuenta con el cupo (`--legitimar` hasta la fase A) | Conforme | `SellosService.LegitimarAsync` (`:103-128`); la prueba legitima al SUPER cambiado después del respaldo |
| SL-F2: solo si ni la base ni el disco tienen un padrón que verifique, y si `InstalacionId` verifica | Conforme | `EstadoReselladoAsync` (`SellosService.cs:235-251`). Dentro de la transacción: `cambio.Actual` y otra vez el disco (`:271-277`) |
| SL-F2: lista, `--confirmar` y motivo | Conforme | `ComandoSellos.ResellarAsync` (`:215-243`): sin `--confirmar` sale con 2 |
| SL-F2: evento crítico con la cuenta de Windows | Conforme | `PADRON_RESELLADO` con `ActorWindows`; S-05 lo lista (prueba `Con_confirmar_…`) |
| SL-F2: solo las habilitadas | Conforme | `Where(u => !u.Inhabilitado)` (`:280`). Las inhabilitadas conservan el sello que no verifica y se recuperan con `--legitimar`, que las sella fuera del padrón (`SellosCuentas.cs:75-80`) |
| SL-F2: si superan el cupo, queda en exceso | Conforme (ver la desviación (d)) | `EstadoResellado.EnExceso`. Las altas y las rehabilitaciones fallan por `ExigirCupo` |
| SL-F2: «con acta» (texto de ADR-83, punto 7) | **No conforme**: ver C-2 | — |
| DL-01: nunca se reconstruye desde las filas, salvo R-S1 | Conforme | Ningún otro llamador de `ResellarAsync` en `src` *[V, búsqueda]* |

## 3. Desviaciones declaradas

| # | Desviación | Dictamen | Motivo |
|---|---|---|---|
| (a) | El número va en el evento propio `CUENTAS_FUERA_DE_PADRON` y no en el `Detalle` de `CANDADO_RESTAURACION_LIBERADO` | **Aceptar** | Lo verifiqué: el evento de liberación lo inserta el procedimiento `dbo.LiberarCandadoRestauracion` (`EsquemaRestauracionSistema.cs:95`). Cambiarlo sería una DDL del arquitecto de datos, y la fase A de C también toca ese bloque. SL-F1 pide que la liberación «informe», y lo hace en la respuesta y en la bitácora. La tabla no restringe `Evento` (solo hay CHECK en `Severidad` y `Canal`), y el nombre cabe en `varchar(40)`. Mejora recomendada: R-4 |
| (b) | `--resellar` no reescribe `Licencia.SelloInicial` | **No aceptar: corregir (C-3)** | Ver el punto 2 de la sección 4 |
| (c) | Sin `--acta`: la referencia va en el motivo | **No aceptar: corregir (C-2)** | Ver el punto 3 de la sección 4 |
| (d) | `EnExceso` = consumo > cupo, el indicador que ya existe, y no un estado nuevo de `EstadoLicenciaService` | **Aceptar** | Es la definición de ADR-58, punto 9: «si el cupo queda por debajo del consumo, la empresa pasa a estar en exceso». No es un estado de la licencia. Es el mismo cálculo de `UsuariosLicenciaDto.EnExceso` y de `LicenciaUsuarios.razor`. Un estado nuevo tocaría el motor de L sin necesidad. Sin licencia legible, el cupo es 0: falla cerrada (no admite altas), y el verbo lo avisa |
| (e) | La regla de Release se lee «solo `GPOS.Migracion`, en toda compilación; la API nunca». La vigila una prueba de arquitectura | **Aceptar** | Coincide con DL-02 (a) y ADR-83, punto 3: lo que crea o sella sin la API es de `GPOS.Migracion`, igual en Debug y en Release, como `sistema --cuentas-iniciales`. Mejora recomendada para la prueba: R-2 |

## 4. Puntos para decidir

| # | Pregunta | Recomendación | ¿Firma? |
|---|---|---|---|
| 1 | ¿Basta el evento propio, o el número va también en `CANDADO_RESTAURACION_LIBERADO` (DDL)? | **Basta el evento propio.** La DDL no aporta información: el número ya está en la respuesta y en un evento de la misma tabla, con el mismo actor y la misma sesión. Para enlazar los dos eventos sin DDL, ver R-4 | No. Detalle técnico que se acepta |
| 2 | ¿`--resellar` reescribe `Licencia.SelloInicial` con el origen `RESELLAR`? | **Sí, pero solo si la fila falta o no verifica**, dentro de la misma transacción. Si verifica, no se toca. Motivo *[V]*: si la fila no verifica, `EstadoSelladoInicialAsync` devuelve `Hecho = false` (`SellosService.cs:165-169`), y entonces:<br>- en Release, la API registra el evento crítico `SinSelladoInicial` en **cada arranque**, aunque el padrón ya funcione (`Inicializacion.cs`, `SellarAlArrancarAsync`);<br>- el mensaje manda a usar `--resellar`, que ahora se niega.<br>La seguridad no cambia: SH-7 ya queda impedido por el padrón que verifica. Es poco probable *[I]*: si `InstalacionId` verifica, `SelloInicial` suele verificar también, salvo que se escribiera con una llave más nueva, como en las instalaciones que recibieron SL después de L1a | No. Detalle técnico (C-3). Nota para datos: `[DAT]` 6.3 suma el origen `RESELLAR` |
| 3 | ¿Se exige `--acta <ref>`, como en `anillo --recuperar`? | **Sí.** Lo dice el texto firmado: ADR-83, punto 7, «con acta», y el blueprint §2.3 y R-S1. Los verbos del anillo ya lo exigen (`MantenimientoAnillo.Validar`, `:236-240`), y `--resellar` va en el mismo incidente que `anillo --recuperar`, con la misma acta. Que la referencia vaya solo dentro del motivo no se puede comprobar | No. Ajuste al texto firmado (C-2) |
| 4 | ¿Repetir el resellado sale con 0 o con 1? | **Con 1, como hoy** (`ReglaNegocioException` → `CodigosSalida.Error`). La negativa no distingue entre «ya lo hice» y «no correspondía», por ejemplo después de una restauración, cuando lo correcto es legitimar. Un guion no debe tomarla como éxito. No hay estado a medias que completar, a diferencia de `empresa --cambiar-rnc`: el resellado es una sola transacción, y si el proceso cae después del commit, la API vuelve a escribir el disco desde la base en la siguiente lectura | No. Detalle técnico que se acepta |
| 5 | Los anfitriones de prueba comparten la carpeta de licencia por proceso (`CarpetaLicenciaPruebas.cs`, L1b-2) y todas las fábricas escriben el mismo `padron` | **Corregir, sin bloquear este PR (R-5).** Efecto *[I]*: cada anfitrión ve el `padron` de otra base, que no verifica con su `InstalacionId`. Lo reescribe y deja `PADRON_DISCO_AUSENTE` si su versión es mayor que 1 (`PadronSellos.cs:286-292`). Con clases en paralelo, los anfitriones se pisan el archivo: hay eventos falsos y posibles pruebas intermitentes, y el camino «prevalece el disco» no se ejerce a través de la API. **Arreglo:** una carpeta por anfitrión, derivada del nombre de la base `GPOS_TEST_*`, fijada en la configuración de cada fábrica (la configuración en memoria prevalece sobre la variable). **Quién:** el desarrollador I, porque el padrón es suyo, avisando a L, porque `CarpetaLicenciaPruebas.cs` es de L1b-2. Unos 0,1 dp, en un PR propio, antes de que C ejecute la suite oficial de SL | No |

## 5. Correcciones obligatorias antes del PR

| # | Corrección | Severidad | Evidencia | Esfuerzo *[I]* |
|---|---|---|---|---|
| **C-1** | **Las entradas sin fila (`FilaAusente`) se purgan; no se legitiman.**<br>El número incluye las cuentas **dadas de alta después del respaldo**: su entrada está en el padrón del disco, pero su fila ya no existe (`SellosService.cs:85-90`). El texto de recuperación y el procedimiento solo dicen «legitímelas una por una», y `--legitimar` responde 404 para ellas. Siguen ocupando cupo hasta `sellos --purgar`. Corregir:<br>(i) `RestauracionSistemaService.Recuperacion`: «legitimar las cuentas con fila; purgar con `sellos --purgar` las entradas sin fila (`FilaAusente`)»;<br>(ii) el `Detalle` del evento debe decir «cuenta(s) en S-01», no «fuera del padrón»: también cuenta las inhabilitadas que siguen en el padrón y las entradas sin fila;<br>(iii) el procedimiento, en el paso 5, con el mismo reparto por motivo: `FueraDePadron` o `CamposNoCoinciden` → `--legitimar`; inhabilitada en el padrón → `--legitimar`, que la retira (`SellosCuentas.cs:79`); `FilaAusente` → `--purgar`;<br>(iv) en `SellosRestauracionTests`, una alta posterior al respaldo: el número sube a 3 y la purga la retira | Media: el operador seguiría una instrucción que falla, con el cupo ocupado | `RestauracionSistemaService.cs:144-150`; procedimiento, paso 5 | 0,1 dp |
| **C-2** | **`--acta <ref>` obligatorio en `sellos --resellar`**, con la misma validación que los verbos del anillo (no vacío). La referencia va al `Detalle` de `PADRON_RESELLADO` (cabe en `nvarchar(400)`), separada del motivo. Ajustar la ayuda de `Program.cs`, el procedimiento y una prueba | Baja | ADR-83, punto 7; `MantenimientoAnillo.cs:236-240` | 0,05 dp |
| **C-3** | **`Licencia.SelloInicial` con el origen `RESELLAR`** si falta o no verifica, en la misma transacción del resellado. No se toca si verifica. Prueba: después del resellado, `EstadoSelladoInicialAsync().Hecho` es verdadero, y `SellarAlArrancarAsync(sellar: false)` no registra `SinSelladoInicial` | Baja | `SellosService.cs:165-169`; `Inicializacion.SellarAlArrancarAsync` | 0,05 dp |
| **C-4** | **Procedimiento, paso 1: la Backup Tool no restaura.** Su única sentencia `RESTORE` es `VERIFYONLY`, y la restauración asistida sigue pendiente (`docs/operaciones/2026-10-04-respaldos-con-backup-tool.md:57` y `:130`). Escribir:<br>- se descomprime el `.7z` de la herramienta;<br>- se ejecuta `RESTORE DATABASE … WITH REPLACE` con acceso exclusivo (`SINGLE_USER WITH ROLLBACK IMMEDIATE` y después `MULTI_USER`), como hace la prueba;<br>- la API puede seguir en marcha, pero pierde sus conexiones y las peticiones de ese lapso fallan *[I]*.<br>Quitar «No hace falta detener la API» tal como está | Baja | Procedimiento, «1. Restaurar» | 0,05 dp |

## 6. Correcciones recomendadas (no bloquean)

| # | Recomendación | Evidencia | Esfuerzo |
|---|---|---|---|
| R-1 | **La versión del padrón resellado, por encima de cualquier versión anterior.** Hoy empieza en 1 (`CambioPadron.Crear`, `Actual?.Version ?? 0`; la prueba lo afirma). Si después reaparecen las llaves perdidas y se restaura un respaldo de `GPOS_SYSDATA` anterior al resellado, su padrón (por ejemplo, la versión 57) verifica y prevalece sobre la versión 1 **sin** registrar `PadronRetrocedido`. Eso reabre SEG-L2-07 en ese caso compuesto (probabilidad muy baja). La versión vieja no se puede leer porque está cifrada. **Arreglo:** empezar en los segundos Unix del momento del resellado (`long`, ≈ 1,8 × 10⁹), que supera cualquier contador y sigue creciendo en un segundo resellado | `PadronSellos.cs:150-156`, `:351` | 0,05 dp |
| R-2 | La prueba de arquitectura debe recorrer **todo `src` salvo `GPOS.Migracion` y el archivo que define el método**. Hoy solo recorre `GPOS.Api`, así que no vería un servicio de `GPOS.Core` que llame a `ResellarAsync` y que la API invoque | `SellosEnLaApiTests.cs` (nueva prueba) | 0,02 dp |
| R-3 | **Procedimiento:** aclarar cuándo sirve `--resellar`. Sirve cuando el anillo recuperado es uno anterior: tiene la llave de `InstalacionId`, pero no las más nuevas con las que se protegió el padrón. Si el anillo se perdió del todo, `InstalacionId` no verifica y el verbo se niega. `sistema` tampoco la regenera (`ComandoSistema.cs:146-150`), y la única salida es H-17 (`anillo --recuperar`) *[V para la negativa; I para el escenario de llaves]* | — | 0,02 dp |
| R-4 | En el `Detalle` de `CUENTAS_FUERA_DE_PADRON`, incluir el fork liberado, como hace el procedimiento («Fork …»), para enlazar los dos eventos sin DDL. Además, que un fallo al escribir este evento no convierta en 500 una liberación que ya se confirmó (capturar y registrar en el log) | `RestauracionSistemaService.cs:119-121` | 0,03 dp |
| R-5 | Carpeta de licencia por anfitrión de prueba (punto 5 de la sección 4) | `CarpetaLicenciaPruebas.cs` | 0,1 dp, PR aparte |
| R-6 | Errata introducida en el diff: «`--legitimar</c>:el mismo`» (falta un espacio) | `ComandoSellos.cs`, documentación de `LicenciaVigenteAsync` | — |

## 7. Lo que va a firma

**Nada.** Los cinco puntos son detalles técnicos o ajustes al texto ya firmado. Para la hoja, solo como **nota de registro informativa** (sin firma), a cargo del Arquitecto Maestro y del documentador:

> **Nota de registro de ADR-83, puntos 7 y 8 (informativa).** La construcción de SL-F1 (a) y SL-F2 (b) agrega dos eventos a la bitácora de seguridad, sin DDL:
> - `CUENTAS_FUERA_DE_PADRON`: la liberación del candado del sistema informa cuántas cuentas lista S-01;
> - `PADRON_RESELLADO`: el evento crítico de `sellos --resellar`.
>
> Además, `sellos --resellar` exige `--acta` y escribe `Licencia.SelloInicial` con el origen `RESELLAR` cuando esa fila falta o no verifica. Recomendación: registrarla así; no cambia ninguna decisión.

## 8. Lo que se acepta

- Las desviaciones (a), (d) y (e). Las respuestas de los puntos 1 y 4 (sección 4).
- **Reparto L/I (§4.3):** se respeta *[V]*.
  - Archivos tocados: `GPOS.Contracts/Seguridad/Cuentas.cs`, `GPOS.Core/Sistema/Restauracion` (H-11, de A), `GPOS.Core/Sistema/Usuarios` (I), `GPOS.Migracion` (I), las pruebas y `docs/operaciones`.
  - No se toca ningún archivo de L: ni `Contracts/Licencia`, ni `Core/Sistema/Licencia`, ni `LicenciaEndpoints`, `ModoLicencia` o `SqlLicenciaSistema`. Solo se usan sus API públicas: `ProtectorLicencia`, `ClavesLicencia`, `IEstadoLicencia.CupoUsuarios` y `CodigosLicencia.CupoAgotado`.
  - `PADRON_VERIFICA` va en `ClavesSellos`, con el mismo criterio que la desviación (b) de la validación anterior.
- **`ResultadoLiberacionSistema` y la rama de C (`c/adr81-fase-a`, `4e5bc446`):** no se rompe.
  - C lo construye en posición, con dos argumentos (`RestauracionSistemaService.cs:114` en su rama), y los parámetros nuevos son opcionales y van al final.
  - Sus pruebas lo deserializan con `Http.PostAsync<ResultadoLiberacionSistema>`. System.Text.Json usa el valor por omisión de un parámetro opcional que falta *[I, comportamiento documentado de .NET]*.
  - `RestauracionSistemaService` gana un parámetro opcional `SellosService?`. La inyección de dependencias lo resuelve porque `SellosService` está registrado (`Program.cs:259`), y sin registro usaría null.
  - Simulación de la unión: `Cuentas.cs` y `RestauracionSistemaService.cs` se unen sin conflicto *[V]*. **Hay conflicto en `BitacoraSeguridad.cs`**: C mueve `EventosSeguridad` a `GPOS.Contracts` (DC-14), y SL le agrega `CuentasFueraDePadron` en `Core`. Se resuelve al rebasar (entrega a C, sección 9). Ese conflicto ya existía con el PR anterior de SL.
- **El procedimiento** de `docs/operaciones/2026-10-17-restauracion-gpos-sysdata-cuentas-fuera-del-padron.md` es correcto en el resto:
  - las referencias de línea coinciden con el código *[V: `PadronSellos.cs:351` y `:291`, `ComandoSellos.cs:105`, `:144`, `:181` y `:215`, `RestauracionSistemaService.cs:117` y `:144`, `SellosService.cs:116`, `:235` y `:265`, `AuthEndpoints.cs:78`, `RestauracionEndpoints.cs:68` y `SellosEndpoints.cs:34`]*;
  - el orden es el correcto: legitimar primero al SUPER si no entra, porque la liberación la hace un SUPER;
  - es correcto que la cuenta legitimada entre con la contraseña del respaldo;
  - es correcta la prohibición de borrar `padron` o de cambiar la carpeta;
  - es correcto que `--resellar` se niegue después de una restauración.
- La salida con 2 sin `--confirmar` y con 1 cuando se niega.
- Las diez pruebas de `SellosReselladoTests` y las dos de `SellosRestauracionTests`. **No las ejecuté.**

## 9. Entregas a otros agentes

| Agente | Qué necesita |
|---|---|
| Desarrollador I | C-1 a C-4 antes del PR; R-1 a R-4 y R-6 si caben (≈ 0,12 dp); R-5 en un PR propio, avisando a L |
| Desarrollador L | Saber que R-5 cambia cómo usan las fábricas `CarpetaLicenciaPruebas` (L1b-2) |
| Equipo C (fase A de ADR-81) | Al rebasar sobre SL (orden R-4 de la validación anterior):<br>- llevar `CUENTAS_FUERA_DE_PADRON` y `PADRON_RESELLADO` al catálogo `GPOS.Contracts.EventosSeguridad` y a `Todos`;<br>- alinear los literales de los eventos del sello con los que escribe SL, en mayúsculas (`CUENTA_LEGITIMADA`, `PADRON_PURGADO`, `PADRON_RETROCEDIDO`, `SELLADO_INICIAL`, `CUENTAS_INICIALES_CREADAS`, `PADRON_DISCO_AUSENTE`). Su catálogo trae `CuentaLegitimada`, `PadronPurgado` y otros en PascalCase, y el filtro de la consulta 5.11 ofrecería nombres que nunca coinciden con una fila. Ya estaba aceptado como desviación (a) de SL, con una nota pendiente en ADR-83, punto 8 |
| Arquitecto de datos | `[DAT]` 6.3: origen `RESELLAR` en `Licencia.SelloInicial` (C-3). Sin DDL |
| Arquitecto Maestro y documentador | La nota de registro de la sección 7 |
| UX y desarrollador web | Cuando exista la pantalla de liberación del candado del sistema (hoy solo hay API), mostrar `cuentasFueraDePadron` y `recuperacion`, con un enlace a S-01 |
| QA | Ejecutar `Usuarios/Sellos` y la suite oficial después de C-1 a C-4. Confirmar que `master.sys.xp_delete_files`, que usa la limpieza de `SellosRestauracionTests`, existe en el SQL Server 2019 Express de la PC A *[I: no lo verifiqué]* |

---

### Cierre
- Estado: Aprobado con observaciones (veredicto: **Conforme con correcciones**; C-1 a C-4 antes del PR)
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\validacion-sl-f1-f2-2026-10-17.md`
- Supuestos:
  - no compilé ni ejecuté pruebas;
  - son inferencias: el efecto de la carpeta compartida en las pruebas, el comportamiento de System.Text.Json, el escenario de llaves de R-3, la probabilidad baja de C-3 y la existencia de `xp_delete_files` en SQL 2019.
- Decisiones candidatas a ADR: ninguna nueva; solo la nota de registro de ADR-83, puntos 7 y 8 (sección 7).
- Entregas a otros agentes: ver la sección 9.
- Próximo paso recomendado: el desarrollador I aplica C-1 a C-4 (≈ 0,25 dp) y abre el PR de `a/sl-resellar-candado`, apilado sobre SL, antes de que C rebase la fase A.
