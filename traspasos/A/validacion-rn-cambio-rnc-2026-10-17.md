# Validación de la pieza RN «Cambio de RNC» contra el blueprint de la licencia del lote 2

**Fecha:** 2026-10-17 · **Valida:** arquitecto-software (equipo A) · **Rama:** `a/rn-cambio-rnc`, árbol `GPOS-NG-rn`, `git diff afc8bdb1..ae25bde3` (commits `781ade1a` y `ae25bde3`; 18 archivos, +1 087 / −10), apilada sobre SL (PR #63)
**Fuentes:**
- blueprint `blueprint-licencia-lote2-2026-10-14.md`: §4.1 (fila RN), §4.3, §5.1 (S-03 y condiciones D.2), §5.2 y §6.1.1 (NV-07, regla 5);
- `[DAT]` `datos-licencia-l1a4-2026-10-14.md`, 2.3;
- hoja `GPOS-NG-Equipos/traspasos/A/hoja-firma-dl01-dl13-licencia-2026-10-14.md`, DL-03 (a) con P-3, firmada el 2026-10-15;
- ADR-83, punto 5 (`origin/master:docs/adr/ADR-083.md`: el árbol RN no lo trae porque parte de una base anterior);
- mi validación de SL `validacion-sl-sello-padron-2026-10-17.md` (C-1, C-4 y R-4).

**Método:** solo lectura del diff y del código circundante (`MotorEstados.cs`, `EstadoLicenciaService.cs`, `FuenteEmpresasLicencia.cs`, `AdministracionService.cs`, `RncDgiiService.cs` y `EmpresasSistema.cs`). **No compilé ni ejecuté pruebas.** *[V]* = verificado en el código; *[I]* = inferido.

---

## 1. Veredicto

**Conforme con correcciones.** El núcleo cumple lo firmado:
- **Orden de escritura:** primero la fila con MAC y el evento crítico, en una sola transacción de `GPOS_SYSDATA`; después el RNC en la base de la empresa (`CambioRncService.CambiarConBloqueoAsync`).
- **Idempotencia (SEG-L2-16):** `Completado` sin fila nueva. Hay una prueba con fallo inyectado.
- **P-3:** se conservan `RncAnterior` y `CambiadoUtc` (`Conservar`), y el código falla cerrado si hay fila y la licencia no se lee.
- **Fila ajena:** una fila de otro anillo no cuenta y se reemplaza.
- **Condición 2 de D.2:** el verbo exige el anillo.
- **ADMIN:** recibe 409 `RNC_SOLO_SUPER`.
- **S-03:** está construida, pero no se mapea, con su prueba de arquitectura y sin código del factor (P-81A-16 (a)).
- **NV-07:** se prueba de punta a punta con el motor.

Hay **tres correcciones obligatorias antes del PR** (sección 5): un ciclo de dependencias nuevo, la visibilidad de los eventos de los verbos (condición 1 de D.2, firmada en ADR-83, punto 5, que hoy no tiene salida) y el RNC real que no pasa el dígito verificador. Hay **dos asuntos para firma** (sección 7). Uno de ellos es un hueco de **mi** regla P-3, no del código.

## 2. Conformidad con el diseño

| Requisito | Resultado | Evidencia |
|---|---|---|
| S-03 `PUT /api/super/empresas/{codigo}/rnc`, SUPER, `Esencial`, construida y **no mapeada** hasta la fase A de ADR-81 | Conforme. El `MapCambioRnc` queda documentado para el PR posterior | `CambioRncEndpoints.cs:14-29`; prueba `S03_no_se_mapea_antes_de_la_fase_A_de_ADR_81` |
| Fila con MAC `Licencia.CambiosRnc:<empresa>` antes que el RNC de la empresa; evento en la misma transacción que la fila | Conforme | `CambioRncService.cs` (`CambiarConBloqueoAsync`: `EscribirConfiguracionAsync` → `RegistrarEventoAsync` → `CommitAsync` → `_escribirRnc`) |
| Idempotencia (SEG-L2-16): si la fila tiene `RncNuevo` y la empresa no, se completa sin fila nueva | Conforme, con prueba de fallo inyectado | `Con_la_segunda_escritura_fallida_la_fila_no_da_transicion_y_repetir_la_completa_sin_fila_nueva` |
| P-3: se conservan `RncAnterior` y `CambiadoUtc` si la fila va del RNC licenciado; si no, `RncAnterior` = el actual y la hora protegida | Conforme con el texto firmado. **Ver el punto 7.2**: el texto firmado deja un rebote | `Conservar`; `La_cadena_A_B_C_conserva_el_RNC_licenciado_y_la_hora_del_primer_cambio` |
| El motor solo da transición si `RncNuevo` = RNC de la empresa | Ya estaba en L1a-3 | `MotorEstados.cs:348` *[V]* |
| Fila 2.3: `V`, `Clave`, `InstalacionId`, forma canónica, `Usuario` null con el verbo, `SecVigenteAlCambiar`, comprobación de los 50 caracteres | Conforme | `CambioRncService.cs` (`clave.Length > 50`, `usuario = origen == OrigenVerbo ? null : …`) |
| 409 `RNC_SOLO_SUPER` en la configuración, también para el SUPER, porque por esa ruta no queda la fila | Conforme. Para la primera asignación, ver el punto 7.1 | `AdministracionService.cs:108-111` |
| Verbo `empresa --cambiar-rnc`: anillo (condición 2), evento crítico con la cuenta y el SID de Windows (primera mitad de la condición 1), `--confirmar` y mismo servicio que S-03 | Conforme | `ComandoEmpresa.cs` (`ExigirAnilloAsync` y `ActorWindows`) |
| **Condición 1 de D.2: el evento «se muestra al SUPER»** | **No conforme**: la consulta existe (`EventosVerbosAsync`), pero ninguna ruta ni pantalla la usa | C-2 |
| RNC con dígito verificador (422 `RNC_INVALIDO`) | Conforme: el algoritmo del RNC (módulo 11) y el de la cédula (Luhn) coinciden con los de referencia *[I]*. **Pero no admite los RNC reales que no lo pasan** | C-3 |
| Sin ciclos entre módulos | **No conforme**: `Sistema/Licencia` → `Sistema/Usuarios` | C-1 |

## 3. Desviaciones declaradas

| # | Desviación | Dictamen | Motivo |
|---|---|---|---|
| (a) | Bloqueo de aplicación **de sesión** (`@LockOwner = 'Session'`, 10 s), y no de transacción | **Aceptar** | Es más correcto que mi 2.3. Con un bloqueo de transacción, la segunda escritura (en otra base y otra conexión, después del commit) quedaba sin protección: un cambio de la API y otro de la consola podían dejar la fila del uno y el RNC del otro. La prueba `Dos_cambios_a_la_vez_dejan_la_fila_y_el_RNC_de_acuerdo` lo cubre. El orden queda bien: el bloqueo va antes de abrir la transacción, y la transacción ya terminó al soltarlo, en el `finally` con `CancellationToken.None`. **Observación R-1:** la conexión de `GPOS_SYSDATA` usa el pool. Si `SoltarBloqueoAsync` falla con la conexión viva, el bloqueo queda en la sesión física que vuelve al pool hasta que se reutilice o se descarte (minutos), y cada reintento falla a los 10 s con 51616 *[I]*. Conviene abrir esa conexión con `Pooling = false`, como ya se hace con las de empresa (`ComandosCambioRnc.cs:218`). La operación es rara y el costo de no usar el pool es despreciable |
| (b) | Sintaxis `empresa --cambiar-rnc <empresa> --rnc <RNC> --motivo "…" [--confirmar]` en lugar de `--cambiar-rnc <empresa> <rnc>` | **Aceptar** | `Argumentos` lee opciones con nombre. Un segundo posicional sería ambiguo y no tendría precedente. `--confirmar` y la salida 2 sin él siguen a `sellos --legitimar`. ADR-83, punto 5, solo nombra el verbo, no su sintaxis: no hace falta firma. El blueprint se corrige en la v2.10 |
| (c) | `CambiarRncRequest(Rnc, Motivo)` sin `CodigoSegundoFactor`; los DTO y los códigos `RNC_*` en `Contracts/Licencia` | **Aceptar** | Sin el código: P-81A-16 (a), firmada el 2026-10-16. S-03 llevará `RequiereAutenticacionReciente()`, que es lo mismo que pedí en la corrección C-1 de SL. En `Contracts/Licencia`: es donde los pone §5.2, y L dejó en `CodigosLicencia.cs` el marcador «se agregan con la pieza RN» (las líneas que el diff retira), es decir, delegó el bloque. Son adiciones al final, sin conflicto de edición previsible. **Condición:** avisar a L por el área común antes del PR. **No se extiende** a `CambioRncService.cs`, que está en `GPOS.Core/Sistema/Licencia`, carpeta de L, y además crea el ciclo de C-1 |
| (d) | La API ve el cambio del verbo hasta 15 min después | **Aceptar** | El verbo corre en otro proceso y no puede llamar a `Invalidar`. La API relee la fila cada 60 s, pero el RNC de la empresa solo cada `Relectura` = 15 min (`FuenteEmpresasLicencia.cs:43` *[V]*). Mientras tanto, el motor ve la fila nueva y el RNC anterior (el licenciado), así que la empresa sigue `Vigente`: no hay ninguna transición abierta ni ninguna `Invalida` falsa (`MotorEstados.cs:343` *[V]*). La demora va hacia el estado anterior, que es correcto, y no abre nada. El verbo lo informa. **Mejora R-2 (entrega a L, 0,05 dp):** si la fila `CambiosRnc` de una empresa cambia entre dos ciclos, invalidar el RNC de esa empresa en la caché. Así la demora baja a 60 s |

## 4. Puntos para decidir

| # | Punto | Dictamen |
|---|---|---|
| (1) | Ruta `GET /api/super/eventos-servidor?desde=` para la condición 1 de D.2 | **Procede, sin firma.** Es cómo se cumple una condición ya firmada (ADR-83, punto 5: «se muestra al SUPER en S-01 o en Diagnóstico en su siguiente inicio de sesión»). Se publica **ya**, sin esperar la fase A de ADR-81: es de lectura y compensa justamente los verbos que existen hoy. Contrato en la sección 6. **Es obligatoria en este PR (C-2)**, porque el verbo sale en este PR |
| (2) | RNC o cédulas reales que no pasan el dígito verificador | **Otra opción: el padrón de RNC de la DGII**, que ya está en `GPOS_SYSDATA` (`dbo.RncDgii`, `RncDgiiService.cs:26` y `:158-160` *[V]*). Regla: se acepta si el dígito verificador es correcto **o** si el RNC figura en `dbo.RncDgii`. Si no, 422 `RNC_INVALIDO`, con el aviso «actualice el padrón de la DGII si el RNC es real». **No requiere firma:** es una precisión de la validación del contrato. El dígito verificador es un control de captura, no de seguridad, y la autorización (SUPER con autenticación reciente, o el anillo) no cambia. Descarto una **lista embebida**: no hay una lista oficial publicada; las que existen (por ejemplo, la de `python-stdnum`) son comunitarias *[I]* y habría que mantenerlas con versiones. Descarto **`--forzar` con motivo**: quita la validación justo en la vía fuera de banda y no sirve en S-03. Va como C-3 |
| (3) | El ADMIN puede asignar el primer RNC (empresa sin RNC) | **Va a firma (RN-F1)**: el texto firmado de DL-03 (a) y de ADR-83, punto 5, dice «el ADMIN ve el RNC de solo lectura desde ya». **Recomiendo permitirlo** y precisarlo así: el ADMIN no gana nada. Si pone un RNC distinto del licenciado, la empresa queda `Invalida` (se perjudica a sí misma) y no hay transición sin la fila del SUPER. Si pone el licenciado, es el flujo normal de implantación. No puede vaciar un RNC fijado (el 409 también cubre vaciarlo, `AdministracionService.cs:109`). Exigir al SUPER también la primera vez, hasta la fase A, obliga a un técnico de GSF en el servidor por **cada empresa nueva** |
| (4) | Precisión de `[DAT]` 2.3 por el bloqueo de sesión | **Procede, sin firma** (precisión técnica). Texto para el arquitecto de datos en la sección 9. Además: el nombre del evento pasa a `CAMBIO_RNC_SUPER` (convención de la tabla, igual que la desviación (a) de SL), y el título de 2.3 deja de decir «pendiente de DL-03» |

## 5. Correcciones obligatorias antes del PR

| # | Corrección | Severidad | Evidencia | Esfuerzo *[I]* |
|---|---|---|---|---|
| **C-1** | **Quitar el ciclo `Sistema/Licencia` ↔ `Sistema/Usuarios`.**<br>- **El ciclo:** `CambioRncService` (espacio de nombres `GPOS.Core.Sistema.Licencia`) usa `SellosService.ExigirMotivo` y `ActorSello` de `Sistema.Usuarios`, y `Sistema/Usuarios` ya depende de `Sistema/Licencia` (`PadronSellos.cs:10` y `SellosService.cs:8` *[V]*). En SL dejé verificado «nunca al revés».<br>- **El cambio:** mover `CambioRncService.cs` a `src/GPOS.Core/Sistema/Empresas/CambioRncService.cs` (espacio `GPOS.Core.Sistema.Empresas`, dueño I). Desde ahí depende de `Licencia` (`ProtectorLicencia`, `ClavesLicencia`, `FilaCambioRnc` y `ComandosLicencia`) y de `Usuarios` sin cerrar ningún ciclo. Comprobé que `Sistema/Licencia` no usa ningún tipo de la raíz `Sistema` ni de `Usuarios` fuera de este archivo *[V]*.<br>- **Ventaja de reparto:** el archivo sale de la carpeta de L (§4.3).<br>- **Prueba de arquitectura:** ningún tipo de `GPOS.Core.Sistema.Licencia` referencia `GPOS.Core.Sistema.Usuarios` | Media | `CambioRncService.cs:293` (`using GPOS.Core.Sistema.Usuarios;`) | 0,1 dp |
| **C-2** | **Publicar la visibilidad de los eventos de los verbos (condición 1 de D.2) en este PR.**<br>- **El hueco:** el verbo sale en este PR y su condición firmada no tiene salida. `EventosVerbosAsync` no tiene llamadas fuera de las pruebas.<br>- **El cambio:** la ruta **S-05** de la sección 6, en un `EventosServidorEndpoints.cs` (I) y con el DTO en `GPOS.Contracts/Seguridad` (no es de L).<br>- **La consulta:** sale de `CambioRncService` (no es del RNC) y se pone junto a la bitácora (`Sistema/Restauracion`, en un lector de `BitacoraSeguridad`), porque cubre también `sellos --legitimar/--purgar` y el sellado inicial.<br>- **El índice:** ya existe `IX_BitacoraSeguridad_Momento` (`EsquemaRestauracionSistema.cs:41` *[V]*).<br>- **Pantalla:** el aviso en la Web va como entrega (sección 9). No bloquea el PR, pero sí la primera instalación fuera de desarrollo | Media: incumple una condición firmada | ADR-83, punto 5; blueprint §5.1, condición 1 | 0,15 dp (+0,2 dp de la Web) |
| **C-3** | **Aceptar los RNC reales que no pasan el dígito verificador, con el padrón de la DGII** (punto 2).<br>- **Dónde:** en `ExigirRnc`, o en un paso del servicio que tenga la conexión de `GPOS_SYSDATA`. Si el dígito no verifica, `SELECT 1 FROM dbo.RncDgii WHERE Rnc = @rnc` (parámetro `varchar` del largo de la columna). Así el verbo y S-03 se comportan igual.<br>- **Prueba:** un RNC con el dígito incorrecto que figura en `dbo.RncDgii` se acepta; sin padrón, 422.<br>- **Vectores:** agregar algunos RNC y cédulas **públicos** reales (por ejemplo, de instituciones del Estado tomados del padrón) a los vectores de `DigitoVerificadorRncTests`, que hoy son todos sintéticos | Media: sin esto, una empresa real con un RNC antiguo no puede recibirlo por la vía del SUPER | `CambioRncService.ExigirRnc`; `RncDgiiService.cs` | 0,1 dp |

**Total de las correcciones:** unos 0,35 dp del desarrollador I, más 0,2 dp de la Web fuera del PR.

## 6. Contrato de S-05 (punto 1)

| # | Ruta | Método | Entrada → salida | Validaciones | Errores | Permiso y clase | Aislamiento |
|---|---|---|---|---|---|---|---|
| **S-05** | `/api/super/eventos-servidor` | GET | `?desde=<ISO 8601 UTC>&hasta=<ISO 8601 UTC>&tope=<n>` → `EventoServidorDto[]`, del más reciente al más antiguo | `desde` es opcional (por omisión, ahora − 90 días); `hasta` es opcional (por omisión, ahora); `desde ≤ hasta`; rango de 2 años como máximo (igual que L-05); `tope` de 1 a 500 (100 por omisión) | 400 `RANGO_INVALIDO`, 401, 403 | **Solo SUPER**. `Consulta`. `Sitio(OperacionSitio.SoloCentral)`, como S-01. **Se publica ya**, sin esperar la fase A | Instalación: el SUPER es global y ve los eventos de todas las empresas. Filtro fijo: `Severidad = 'A' AND Canal = 'CONSOLA'` (los verbos de `GPOS.Migracion`) |

```csharp
// GPOS.Contracts/Seguridad
public sealed record EventoServidorDto(long Id, DateTime MomentoUtc, string Evento, string? Actor, string? Empresa, string? Motivo, string? Detalle);
```

- **Actor y detalle:** `Actor` es la cuenta de Windows; `Detalle` lleva el SID, el equipo y el origen. El SID no es un secreto, y solo lo ve el SUPER.
- **Datos que no van:** ni el RNC (el evento ya no lo lleva), ni `Usuario` (con el verbo es null), ni la IP.
- **Uso en la Web (entrega):**
  - al entrar un SUPER, la Web llama con `desde` = hora del último aviso que ese SUPER descartó, guardada en el servidor o, en su defecto, los 90 días por omisión;
  - si hay eventos, muestra «N usos de herramientas del servidor desde …» con la lista y un enlace a Diagnóstico;
  - Diagnóstico ofrece la misma lista con el rango a elegir.
- **Descarto** guardar el «visto» en la bitácora o en una tabla nueva: la bitácora es de solo inserción (ADR-81) y la ventana de 90 días cubre la frecuencia de entrada del SUPER de GSF *[I]*.
- **Volumen:** los verbos son raros (decenas al año por instalación *[I]*). Con el índice por `MomentoUtc`, la consulta lee unas pocas páginas.

## 7. Lo que va a firma (texto corto para la hoja)

### 7.1 RN-F1 · El ADMIN puede poner el RNC por primera vez (precisión de DL-03 (a) y de ADR-83, punto 5)

**Qué se decide.** Lo firmado dice que el ADMIN ve el RNC «de solo lectura desde ya». El código deja que el ADMIN lo escriba **solo si la empresa todavía no tiene RNC**. Una vez puesto, solo lo cambia el SUPER, y el ADMIN tampoco puede borrarlo.

| Opción | Consecuencia |
|---|---|
| **(a) Permitir la primera asignación al ADMIN, con la misma validación que S-03 (dígito verificador o padrón de la DGII), su línea en la auditoría y la invalidación inmediata del RNC en la caché de la licencia (recomendada)** | Es la implantación normal. Si el ADMIN pone un RNC distinto del licenciado, solo se perjudica: la empresa queda `Invalida` y la corrige el SUPER. No abre ninguna transición. Costo ≈ 0,05 dp (validación e invalidación) |
| (b) Solo el SUPER, también la primera vez | Hasta la fase A de ADR-81, cada empresa nueva necesita a un técnico de GSF en el servidor (`empresa --cambiar-rnc`). Más costo de operación sin reducir ningún riesgo |

### 7.2 RN-F2 · Un rebote al RNC licenciado no debe reiniciar el plazo de 30 días (precisión de P-3, DL-03 (a))

**Qué se decide.** P-3 busca que una cadena de cambios A→B→C no reinicie el plazo de transición. Pero el texto firmado solo conserva la hora del primer cambio **mientras la empresa tenga un RNC distinto del licenciado**. Si el SUPER (o quien tenga el anillo en el servidor, con el verbo) vuelve un momento al RNC licenciado (B→A) y luego cambia a otro (A→C), el plazo empieza de nuevo. Repitiéndolo cada mes, una empresa operaría indefinidamente con un RNC que la licencia no cubre. Cada rebote deja dos eventos críticos visibles para el SUPER (S-05). El código cumple el texto firmado: el hueco es de mi regla.

| Opción | Consecuencia |
|---|---|
| **(a) Conservar `RncAnterior` y `CambiadoUtc` siempre que la fila vaya del RNC licenciado de la licencia vigente, aunque la empresa haya vuelto a él (recomendada)** | Se cierra el rebote. Caso legítimo afectado: si el SUPER revierte un error y meses después, **con la misma licencia**, hace un cambio real, la empresa queda `Invalida` hasta que GSF emita la licencia con el RNC nuevo. Con la suscripción mensual, cada renovación trae el RNC actual y abre un plazo limpio. Costo ≈ 0,05 dp (quitar la condición `licenciado != actual` de `Conservar` y una prueba B→A→C) |
| (b) Dejarlo como está | Riesgo residual Bajo: exige el anillo o al SUPER con segundo factor, y deja eventos visibles. Pero contradice el propósito de P-3 |

Recomiendo pasar el punto 7.2 también al auditor-seguridad antes de la firma.

## 8. Lo que se acepta

- **Desviaciones:**
  - (a), con R-1 (conexión sin pool);
  - (b);
  - (c) para los DTO y los códigos, avisando a L;
  - (d), con R-2 como mejora para L.
- **Contrato de S-03, precisiones del blueprint v2.10 sin firma:**
  - 409 `RNC_SIN_CAMBIO` también cuando la fila y la empresa ya tienen el RNC (`YaAplicado`); la Web lo trata como «ya hecho». El verbo lo informa y sale con 0;
  - 503 `LICENCIA_SIN_INSTALACION` si `Licencia.InstalacionId` no verifica;
  - 409 `LICENCIA_ILEGIBLE` si hay fila previa y la licencia no se lee (P-3 falla cerrado);
  - 422 `MOTIVO_REQUERIDO`;
  - 404 `EMPRESA_NO_EXISTE`.
  - **Observación:** `LICENCIA_ILEGIBLE` es un código de bloqueo con 403 en §5.2. Usarlo con 409 aquí es aceptable porque la Web lo recibe en una pantalla del SUPER, no en el filtro de bloqueo. Se documenta en el XML del manejador.
- **Reparto (§4.3):**
  - `ComandoEmpresa.cs`, `ComandosCambioRnc.cs`, `AdministracionService` (RNC) y `CambioRncEndpoints.cs` son de I;
  - el bloque de `GPOS.Api/Program.cs` (+12 líneas, registro sin condición) se acepta igual que en SL, rebasando sobre SL antes del PR;
  - la extracción de `BitacoraSeguridad.Parametros` (`internal`, sin cambio de comportamiento) se acepta.
- **Validaciones:** el dígito verificador del RNC (módulo 11 con 7-9-8-6-5-4-3-2) y el de la cédula (Luhn sobre 11 dígitos) son correctos. Los comprobé a mano contra la fórmula de referencia `(10 − r) mod 9 + 1` *[I]*.
- **Orden de unión:** RN después de SL (PR #63) y antes de la fase A de ADR-81, que agrega `MapCambioRnc` con `RequiereAutenticacionReciente()` y su fila en `RutasLicenciaAprobadas.json` (`Esencial`).

**Recomendadas (no bloquean):**

| # | Recomendación | Esfuerzo |
|---|---|---|
| R-1 | Conexión de `GPOS_SYSDATA` con `Pooling = false` en `CambioRncService.CambiarAsync`, para que un `sp_releaseapplock` fallido no deje el bloqueo en una sesión del pool | 0,02 dp |
| R-2 | (L) Invalidar el RNC en la caché cuando cambia la fila `CambiosRnc` de una empresa entre dos ciclos | 0,05 dp |
| R-3 | Primera asignación del ADMIN (si se firma RN-F1 (a)): la misma validación que S-03 e invalidar el RNC en la caché de la licencia al guardar. Hoy la primera asignación solo exige 9 u 11 dígitos y la API la ve hasta 15 min después | 0,05 dp |
| R-4 | En `AdministracionService`, comparar `Rnc.Normalizar(e.Rnc)` con `rnc`, para que un RNC guardado con espacios o guiones (datos importados) no dé 409 al guardar sin cambios | 0,01 dp |

## 9. Entregas a otros agentes

| Agente | Qué necesita |
|---|---|
| Desarrollador I | C-1 a C-3; R-1, R-3 y R-4 |
| Desarrollador L | R-2. Aviso: el bloque `RNC_*` y los dos DTO de S-03 entran en `Contracts/Licencia` con este PR |
| Desarrollador Web y disenador-ux-ui | El aviso de S-05 al entrar el SUPER y la lista en Diagnóstico (≈ 0,2 dp). El RNC de solo lectura para el ADMIN cuando ya está fijado (y editable la primera vez, si se firma RN-F1 (a)). El texto de 409 `RNC_SOLO_SUPER` |
| Arquitecto de datos | `[DAT]` 2.3, «Concurrencia»: «`sp_getapplock @Resource = N'GPOS.Licencia.CambioRnc:<empresa>'`, exclusivo y **de sesión** (10 s), tomado antes de abrir la transacción de la fila y soltado después de la segunda escritura (en `finally`; si el proceso cae, al cerrarse la conexión, que no usa el pool). La transacción de la fila incluye el evento `CAMBIO_RNC_SUPER` en `BitacoraSeguridad`. La segunda escritura va en su propia transacción en la base de la empresa, dentro del bloqueo». Quitar «pendiente de DL-03» del título. Nombre del evento: `CAMBIO_RNC_SUPER` |
| Auditor-seguridad | Opinión sobre RN-F2 (rebote al RNC licenciado) antes de llevarlo a la hoja |
| Arquitecto Maestro y documentador | Llevar RN-F1 y RN-F2 a la hoja. Nota de registro en ADR-83, punto 8: `CAMBIO_RNC_SUPER`. Blueprint v2.10: la sintaxis del verbo, la ruta S-05, los errores de S-03 y la regla del padrón de la DGII |
| QA | La suite oficial con `Licencia/CambioRnc*`, `DigitoVerificadorRncTests` y la prueba de arquitectura de C-1, después de las correcciones |

---

### Cierre
- Estado: Aprobado con observaciones (veredicto de la pieza: **Conforme con correcciones**; C-1 a C-3 antes del PR)
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\validacion-rn-cambio-rnc-2026-10-17.md`
- Supuestos:
  - no se compiló ni se ejecutaron pruebas;
  - la permanencia del bloqueo de sesión en una conexión del pool (R-1) y la frecuencia de uso de los verbos son inferencias;
  - la existencia de listas comunitarias de excepciones al dígito verificador no se verificó aquí;
  - ADR-83 se leyó de `origin/master`.
- Decisiones candidatas a ADR: RN-F1 (precisión de DL-03 (a) y de ADR-83, punto 5: primera asignación del ADMIN); RN-F2 (precisión de P-3: conservar la hora del primer cambio aunque la empresa vuelva al RNC licenciado).
- Entregas a otros agentes: ver la sección 9.
- Próximo paso recomendado: el desarrollador I aplica C-1 a C-3, rebasa sobre SL y abre el PR. RN-F1 y RN-F2 van a la hoja vía B.
